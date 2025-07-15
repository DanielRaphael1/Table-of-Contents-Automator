  #!/usr/bin/env bash
  #
  #   ▸ NOTES
  #       - The TOC header must literally be "## Table of Contents".

  set -euo pipefail

  ROOT=${1:-.}                            # directory to scan, default = current repo root

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

    # CRITICAL: First, read the ENTIRE file into memory
    ORIGINAL_CONTENT=$(<"$f")

    # If file is empty, skip it
    if [[ -z "$ORIGINAL_CONTENT" ]]; then
      echo "⚠️   File $f is empty, skipping..." >&2
      continue
    fi

    # Generate TOC
    TMP_TOC=$(mktemp)
    if ! _gen_toc "$f" > "$TMP_TOC"; then
      echo "⚠️   No headers found in $f, skipping..." >&2
      rm -f "$TMP_TOC"
      continue
    fi

    # Read the generated TOC
    NEW_TOC=$(<"$TMP_TOC")
    rm -f "$TMP_TOC"

    # Now process the content
    # First, remove any existing TOC section
    # This uses sed to remove from "## Table of Contents" to the next "##" header or end of 
  TOC
    CONTENT_WITHOUT_TOC=$(echo "$ORIGINAL_CONTENT" | sed '/^## Table of 
  Contents$/,/^##[[:space:]]/{ /^## Table of Contents$/d; /^##[[:space:]]/!d; }')

    # If sed somehow emptied the content, use original
    if [[ -z "$CONTENT_WITHOUT_TOC" ]] || [[ "${#CONTENT_WITHOUT_TOC}" -lt 10 ]]; then
      CONTENT_WITHOUT_TOC="$ORIGINAL_CONTENT"
    fi

    # Find if there's a main header (single #)
    if echo "$CONTENT_WITHOUT_TOC" | grep -q '^#[[:space:]][^#]'; then
      # Insert TOC after the main header
      NEW_CONTENT=$(echo "$CONTENT_WITHOUT_TOC" | awk -v toc="$NEW_TOC" '
        /^#[[:space:]][^#]/ && !done {
          print
          print ""
          print toc
          print ""
          done=1
          next
        }
        {print}
      ')
    else
      # No main header, prepend TOC
      NEW_CONTENT="$NEW_TOC"$'\n\n'"$CONTENT_WITHOUT_TOC"
    fi

    # CRITICAL SAFETY CHECK: Ensure we didn't lose content
    ORIGINAL_LENGTH=${#ORIGINAL_CONTENT}
    NEW_LENGTH=${#NEW_CONTENT}

    if [[ $NEW_LENGTH -lt $((ORIGINAL_LENGTH / 2)) ]]; then
      echo "❌   ERROR: New content is suspiciously small!" >&2
      echo "     Original: $ORIGINAL_LENGTH chars, New: $NEW_LENGTH chars" >&2
      echo "     Skipping file to prevent data loss!" >&2
      continue
    fi

    # Only write if we have substantial content
    if [[ $NEW_LENGTH -gt 50 ]]; then
      echo "$NEW_CONTENT" > "$f"
      echo "✅   Successfully updated $f" >&2
    else
      echo "❌   ERROR: Resulting file would be too small, skipping!" >&2
    fi
  done

  echo "✅  All TOCs refreshed." >&2
