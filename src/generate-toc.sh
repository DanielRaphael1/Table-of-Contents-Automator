  #!/usr/bin/env bash
  #
  #   ▸ NOTES
  #       - The TOC header must literally be "## Table of Contents".

  set -euo pipefail

  ROOT=${1:-.}                            # directory to scan, default = current repo root
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  TMP=$(mktemp)

  # ------------------------------------------------------------------
  # Helper ─ generate a TOC for a single file and write it to stdout
  # ------------------------------------------------------------------
  _gen_toc() {
    local md_file=$1
    local -a toc=()
    declare -A seen=()
    local in_code=0

    while IFS= read -r line; do
      [[ $line =~ ^\`\`\` ]] && { (( in_code ^= 1 )); continue; }
      (( in_code )) && continue
      [[ $line =~ ^\#{1,6}[[:space:]] ]] && toc+=("$line")
    done < <(grep -Ev '^## Table of Contents' "$md_file")

    # Check if we found any headers
    if [[ ${#toc[@]} -eq 0 ]]; then
      return 1
    fi

    printf '## Table of Contents\n\n'
    for h in "${toc[@]}"; do
      local level=${h%%[!#]*}            # "###"
      local depth=${#level}              # 3
      local indent; indent=$(printf '  %.0s' $(seq 1 $((depth-1))))
      local text=${h#"$level"}; text=${text#" "}; text=${text%%[[:space:]]*}
      local slug; slug=$(tr '[:upper:]' '[:lower:]' <<<"$text" \
                     | tr -cd '[:alnum:][:space:]-_' \
                     | tr ' ' '-' | tr -s '-')
      local n=${seen["$text"]:-0}; seen["$text"]=$((n+1))
      (( n > 0 )) && slug="${slug}-${n}"
      printf '%s- [%s](#%s)\n' "$indent" "$text" "$slug"
    done
  }

  # ------------------------------------------------------------------
  # Main loop ─ iterate over every README*.md
  # ------------------------------------------------------------------
  mapfile -d '' FILES < <(find "$ROOT" -type f -iname 'README*.md' -print0 | sort -z)
  [[ ${#FILES[@]} -eq 0 ]] && { echo "No README*.md files found in $ROOT" >&2; exit 0; }

  echo "🔍  Found ${#FILES[@]} README files. Updating TOCs…" >&2

  for f in "${FILES[@]}"; do
    echo "⚙️   $f" >&2

    # 1. generate fresh TOC
    if ! _gen_toc "$f" > "$TMP"; then
      echo "⚠️   No headers found in $f, skipping..." >&2
      continue
    fi

    # Safety check: ensure TOC was generated
    if [[ ! -s "$TMP" ]]; then
      echo "⚠️   Warning: No TOC generated for $f, skipping..." >&2
      continue
    fi

    # 2. remove old TOC (everything from the header down to the next blank line)
    awk '
      BEGIN {skip=0; in_toc=0}
      /^## Table of Contents/ {in_toc=1; next}
      in_toc && /^[[:space:]]*$/ {in_toc=0; next}
      in_toc && /^[[:space:]]*-/ {next}
      !in_toc {print}
    ' "$f" > "${TMP}.body"

    # 3. stitch new TOC + body
    cat "$TMP" "${TMP}.body" > "${TMP}.new"

    # 4. overwrite the file safely
    if command -v sponge >/dev/null 2>&1; then
      cat "${TMP}.new" | sponge "$f"
    else
      mv "${TMP}.new" "$f"
    fi
  done

  rm -f "$TMP" "${TMP}.body" "${TMP}.new"
  echo "✅  All TOCs refreshed." >&2
