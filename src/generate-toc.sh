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
    echo "⚙️   Processing $f" >&2

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

    # 2. Remove old TOC if it exists, otherwise keep entire file
    if grep -q '^## Table of Contents' "$f"; then
      echo "   Found existing TOC, removing it..." >&2
      # Remove old TOC section only
      awk '
        BEGIN {in_toc=0; printed=0}
        /^## Table of Contents/ {in_toc=1; next}
        in_toc && /^[[:space:]]*$/ {
          # Found blank line after TOC, check if we should end TOC section
          getline nextline
          if (nextline ~ /^[[:space:]]*-/) {
            # Still in TOC (next line is a list item)
            next
          } else {
            # End of TOC
            in_toc=0
            if (nextline != "") print nextline
          }
          next
        }
        in_toc && /^[[:space:]]*-/ {next}
        !in_toc {print}
      ' "$f" > "${TMP}.body"
    else
      echo "   No existing TOC found, keeping entire file..." >&2
      # No TOC exists, just copy the entire file
      cp "$f" "${TMP}.body"
    fi

    # Critical safety check: ensure body file is not empty
    if [[ ! -s "${TMP}.body" ]]; then
      echo "❌   ERROR: File body is empty after processing $f" >&2
      echo "     This would delete all content! Skipping to prevent data loss." >&2
      continue
    fi

    # Additional check: ensure we didn't lose too much content
    original_lines=$(wc -l < "$f")
    body_lines=$(wc -l < "${TMP}.body")
    if [[ $body_lines -lt $((original_lines / 2)) ]]; then
      echo "⚠️   WARNING: Body has less than half the original lines ($body_lines vs 
  $original_lines)" >&2
      echo "     This might indicate an error. Proceeding with caution..." >&2
    fi

    # 3. Find where to insert the TOC
    # If there's a main header (single #), insert TOC after it
    # Otherwise, insert at the beginning
    if grep -q '^#[[:space:]][^#]' "${TMP}.body"; then
      echo "   Inserting TOC after main header..." >&2
      awk -v toc_file="$TMP" '
        BEGIN {printed_toc=0}
        /^#[[:space:]][^#]/ && !printed_toc {
          print
          print ""
          while ((getline line < toc_file) > 0) print line
          print ""
          printed_toc=1
          next
        }
        {print}
      ' "${TMP}.body" > "${TMP}.new"
    else
      echo "   Inserting TOC at beginning of file..." >&2
      # No main header, prepend TOC at the beginning
      cat "$TMP" > "${TMP}.new"
      echo "" >> "${TMP}.new"
      cat "${TMP}.body" >> "${TMP}.new"
    fi

    # Final safety check before overwriting
    if [[ ! -s "${TMP}.new" ]]; then
      echo "❌   ERROR: Result file is empty for $f, skipping!" >&2
      continue
    fi

    new_lines=$(wc -l < "${TMP}.new")
    if [[ $new_lines -lt 3 ]]; then
      echo "❌   ERROR: Result file has too few lines ($new_lines) for $f, skipping!" >&2
      continue
    fi

    # 4. overwrite the file safely
    echo "   Writing updated file..." >&2
    if command -v sponge >/dev/null 2>&1; then
      cat "${TMP}.new" | sponge "$f"
    else
      mv "${TMP}.new" "$f"
    fi

    echo "✅   Successfully updated $f" >&2
  done

  # Cleanup
  rm -f "$TMP" "${TMP}.body" "${TMP}.new"
  echo "✅  All TOCs refreshed." >&2
