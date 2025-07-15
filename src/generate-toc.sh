
  #!/usr/bin/env bash

  set -euo pipefail

  # Find all README files
  find "${1:-.}" -type f -iname 'README*.md' -print0 | while IFS= read -r -d '' file; do
      echo "Processing: $file"

      # Create a temporary file
      tmpfile=$(mktemp)

      # Generate TOC by finding all headers
      echo "## Table of Contents" > "$tmpfile"
      echo "" >> "$tmpfile"

      # Extract headers (excluding the TOC header itself)
      grep -E '^#{1,6} ' "$file" | grep -v '^## Table of Contents' | while IFS= read -r
  header; do
          # Get the header level
          level=$(echo "$header" | sed 's/[^#].*$//' | wc -c)
          level=$((level - 1))

          # Get the header text
          text=$(echo "$header" | sed 's/^#* *//')

          # Create the link
          link=$(echo "$text" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | tr ' '
  '-')

          # Add appropriate indentation
          indent=""
          for ((i=1; i<level; i++)); do
              indent="  $indent"
          done

          # Write the TOC entry
          echo "${indent}- [$text](#$link)" >> "$tmpfile"
      done

      # Remove old TOC if it exists
      if grep -q '^## Table of Contents' "$file"; then
          # Create a new file without the old TOC
          sed '/^## Table of Contents/,/^$/d' "$file" > "${tmpfile}.body"
      else
          # No existing TOC, just copy the file
          cp "$file" "${tmpfile}.body"
      fi

      # Combine new TOC with body
      echo "" >> "$tmpfile"
      cat "${tmpfile}.body" >> "$tmpfile"

      # Safety check - make sure the new file isn't empty
      if [ -s "$tmpfile" ]; then
          mv "$tmpfile" "$file"
          echo "Updated: $file"
      else
          echo "ERROR: Generated file is empty, skipping $file"
          rm -f "$tmpfile" "${tmpfile}.body"
      fi
  done

  echo "Done!"
