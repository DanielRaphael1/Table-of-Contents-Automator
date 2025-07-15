  #!/usr/bin/env bash
  #
  #   ▸ NOTES
  #       - The TOC header must literally be "## Table of Contents".

  set -euo pipefail

  ROOT=${1:-.}                            # directory to scan, default = current repo root
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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
      # Skip the TOC header itself
      [[ $line == "## Table of Contents" ]] && continue
      # Capture headers
      [[ $line =~ ^\#{1,6}[[:space:]] ]] && toc+=("$line")
    done < "$md_file"

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

    # Create backup
    cp "$f" "${f}.backup"

    # 1. generate fresh TOC
    TMP_TOC=$(mktemp)
    if ! _gen_toc "$f" > "$TMP_TOC"; then
      echo "⚠️   No headers found in $f, skipping..." >&2
      rm -f "${f}.backup" "$TMP_TOC"
      continue
    fi

    # 2. Create new file content
    TMP_NEW=$(mktemp)

    # Read the original file and process it
    local found_main_header=0
    local skip_old_toc=0

    while IFS= read -r line; do
      # If we find "## Table of Contents", start skipping
      if [[ "$line" == "## Table of Contents" ]]; then
        skip_old_toc=1
        continue
      fi

      # If we're skipping TOC and find a new section (## header) or after blank line + 
  non-list line
      if [[ $skip_old_toc -eq 1 ]]; then
        if [[ "$line" =~ ^##[[:space:]] ]] || ([[ -z "$line" ]] && ! [[ "${next_line:-}" =~ 
  ^[[:space:]]*- ]]); then
          skip_old_toc=0
        else
          # Skip TOC content (list items)
          [[ "$line" =~ ^[[:space:]]*- ]] && continue
          [[ -z "$line" ]] && continue
        fi
      fi

      # If this is the main header and we haven't inserted TOC yet
      if [[ "$line" =~ ^#[[:space:]][^#] ]] && [[ $found_main_header -eq 0 ]]; then
        echo "$line" >> "$TMP_NEW"
        echo "" >> "$TMP_NEW"
        cat "$TMP_TOC" >> "$TMP_NEW"
        echo "" >> "$TMP_NEW"
        found_main_header=1
      elif [[ $skip_old_toc -eq 0 ]]; then
        echo "$line" >> "$TMP_NEW"
      fi
    done < "$f"

    # If no main header was found, prepend TOC at beginning
    if [[ $found_main_header -eq 0 ]]; then
      cat "$TMP_TOC" > "${TMP_NEW}.final"
      echo "" >> "${TMP_NEW}.final"
      cat "$TMP_NEW" >> "${TMP_NEW}.final"
      mv "${TMP_NEW}.final" "$TMP_NEW"
    fi

    # Safety checks
    if [[ ! -s "$TMP_NEW" ]]; then
      echo "❌   ERROR: Result file is empty for $f" >&2
      echo "     Restoring from backup..." >&2
      mv "${f}.backup" "$f"
      rm -f "$TMP_TOC" "$TMP_NEW"
      continue
    fi

    # Check we didn't lose too much content
    original_size=$(wc -c < "${f}.backup")
    new_size=$(wc -c < "$TMP_NEW")
    if [[ $new_size -lt $((original_size / 2)) ]]; then
      echo "❌   ERROR: New file is less than half the size of original" >&2
      echo "     Restoring from backup..." >&2
      mv "${f}.backup" "$f"
      rm -f "$TMP_TOC" "$TMP_NEW"
      continue
    fi

    # All checks passed, update the file
    mv "$TMP_NEW" "$f"
    rm -f "${f}.backup" "$TMP_TOC"
    echo "✅   Successfully updated $f" >&2
  done

  echo "✅  All TOCs refreshed." >&2
