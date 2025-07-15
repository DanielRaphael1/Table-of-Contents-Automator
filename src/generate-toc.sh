  #!/usr/bin/env bash

  set -euo pipefail

  # Process a single file
  process_file() {
      local file="$1"

      # Read the entire file into a variable
      local content
      content=$(cat "$file")

      # Skip if file is empty
      if [[ -z "$content" ]]; then
          echo "Skipping empty file: $file" >&2
          return
      fi

      # Generate TOC content
      local toc="## Table of Contents\n\n"
      local has_headers=false

      # Process each line
      while IFS= read -r line; do
          if [[ "$line" =~ ^#{1,6}[[:space:]] ]] && [[ "$line" != "## Table of Contents" ]]; 
  then
              has_headers=true
              # Count the number of # characters
              local hashes="${line%%[^#]*}"
              local level=${#hashes}

              # Get the text after the hashes and space
              local text="${line#*# }"

              # Create the slug (link)
              local slug=$(echo "$text" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd
  '[:alnum:]-')

              # Add indentation
              local indent=""
              for ((i=1; i<level; i++)); do
                  indent="${indent}  "
              done

              # Add to TOC
              toc="${toc}${indent}- [${text}](#${slug})\n"
          fi
      done <<< "$content"

      # Skip if no headers found
      if [[ "$has_headers" == "false" ]]; then
          echo "No headers found in: $file" >&2
          return
      fi

      # Remove existing TOC if present
      local new_content
      if echo "$content" | grep -q '^## Table of Contents'; then
          # Remove from "## Table of Contents" until the next ## header or two consecutive 
  newlines
          new_content=$(echo "$content" | awk '
              BEGIN { in_toc = 0 }
              /^## Table of Contents/ { in_toc = 1; next }
              in_toc && /^## / && !/^## Table of Contents/ { in_toc = 0 }
              in_toc && /^$/ { 
                  getline
                  if (/^$/ || /^## /) {
                      in_toc = 0
                      if (/^## /) print
                  }
                  next
              }
              !in_toc { print }
          ')
      else
          new_content="$content"
      fi

      # Find where to insert TOC
      local final_content
      if echo "$new_content" | grep -q '^# '; then
          # Insert after main title
          final_content=$(echo "$new_content" | awk -v toc="$(echo -e "$toc")" '
              /^# / { print; print ""; print toc; found=1; next }
              { print }
          ')
      else
          # Insert at beginning
          final_content=$(echo -e "${toc}\n${new_content}")
      fi

      # Write to file ONLY if we have content
      if [[ -n "$final_content" ]] && [[ ${#final_content} -gt 10 ]]; then
          echo "$final_content" > "$file"
          echo "✓ Updated: $file" >&2
      else
          echo "✗ ERROR: Would create empty file, skipping: $file" >&2
      fi
  }

  # Main execution
  echo "🔍 Starting TOC generation..." >&2

  # Find and process all README files
  find "${1:-.}" -type f -iname 'README*.md' | while IFS= read -r file; do
      echo "📄 Processing: $file" >&2
      process_file "$file"
  done

  echo "✅ TOC generation complete!" >&2
