
  #!/usr/bin/env bash

  # Simple TOC Generator for README files
  # This script generates a Table of Contents for all README*.md files
  # Compatible with GitHub Actions and different repository structures

  set -e

  # Configuration - can be overridden by environment variables or parameters
  CONTENT_DIR="${1:-${INPUT_TARGET_DIR:-Content}}"
  TOC_HEADER="${TOC_HEADER:-## Table of Contents}"
  WORKSPACE_DIR="${GITHUB_WORKSPACE:-$(pwd)}"

  # Ensure we're working in the correct directory
  cd "$WORKSPACE_DIR"

  # Function to generate slug from header text
  make_slug() {
      echo "$1" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9 -]//g' | tr ' ' '-' | sed
  's/-\+/-/g' | sed 's/^-//;s/-$//'
  }

  # Function to process a single README file
  process_readme() {
      local file="$1"
      echo "Processing: $file" >&2

      # Create backup
      cp "$file" "$file.bak"

      # Read file content
      local content
      if ! content=$(cat "$file" 2>/dev/null); then
          echo "  Error: Cannot read file, skipping" >&2
          rm -f "$file.bak"
          return
      fi

      # Check if file has content
      if [[ -z "$content" ]]; then
          echo "  Warning: File is empty, skipping" >&2
          rm -f "$file.bak"
          return
      fi

      # Extract all headers except TOC header
      local headers
      headers=$(echo "$content" | grep -E '^#{1,6} ' | grep -v "^$TOC_HEADER$" || true)

      # Check if there are any headers
      if [[ -z "$headers" ]]; then
          echo "  No headers found, skipping" >&2
          rm -f "$file.bak"
          return
      fi

      # Generate TOC
      local toc="$TOC_HEADER"$'\n\n'

      while IFS= read -r header; do
          # Skip empty lines
          [[ -z "$header" ]] && continue

          # Count # symbols for level
          local level
          level=$(echo "$header" | sed 's/[^#].*//' | wc -c)
          level=$((level - 1))

          # Extract header text (remove all # symbols and spaces)
          local text
          text=$(echo "$header" | sed 's/^#\+ *//')

          # Generate slug
          local slug
          slug=$(make_slug "$text")

          # Add indentation (2 spaces per level, starting from level 2)
          local indent=""
          for ((i=2; i<=level; i++)); do
              indent="  $indent"
          done

          # Add to TOC
          toc="$toc$indent- [$text](#$slug)"$'\n'
      done <<< "$headers"

      # Remove existing TOC section if present
      local content_without_toc="$content"
      if echo "$content" | grep -q "^$TOC_HEADER$"; then
          # Remove everything from TOC header to the next header or double newline
          content_without_toc=$(echo "$content" | awk -v toc_header="$TOC_HEADER" '
              BEGIN { skip = 0; blank_count = 0 }
              $0 == toc_header { skip = 1; next }
              skip && /^#{1,6} / { skip = 0 }
              skip && /^$/ { 
                  blank_count++
                  if (blank_count >= 2) skip = 0
                  next 
              }
              skip && /^- / { next }
              !skip { print; blank_count = 0 }
          ')
      fi

      # Find position to insert TOC
      local new_content=""
      local inserted=0

      # Try to insert after main title (single #)
      while IFS= read -r line; do
          new_content="$new_content$line"$'\n'

          if [[ $inserted -eq 0 ]] && [[ "$line" =~ ^#[[:space:]] ]]; then
              new_content="$new_content"$'\n'"$toc"$'\n'
              inserted=1
          fi
      done <<< "$content_without_toc"

      # If no main title found, prepend TOC
      if [[ $inserted -eq 0 ]]; then
          new_content="$toc"$'\n\n'"$content_without_toc"
      fi

      # Safety check: ensure new content is not too small
      local orig_size new_size
      orig_size=$(echo "$content" | wc -c)
      new_size=$(echo "$new_content" | wc -c)

      if [[ $new_size -lt $((orig_size / 3)) ]]; then
          echo "  ERROR: New content is too small (${new_size} vs ${orig_size} bytes)" >&2
          echo "  Restoring from backup" >&2
          mv "$file.bak" "$file"
          return 1
      fi

      # Write new content
      if ! echo "$new_content" > "$file"; then
          echo "  ERROR: Failed to write file" >&2
          mv "$file.bak" "$file"
          return 1
      fi

      # Remove backup
      rm -f "$file.bak"

      echo "  ✓ Updated successfully" >&2
  }

  # Main execution
  echo "TOC Generator - Starting" >&2
  echo "Workspace: $WORKSPACE_DIR" >&2
  echo "Content directory: $CONTENT_DIR" >&2

  # Check if content directory exists
  if [[ ! -d "$CONTENT_DIR" ]]; then
      echo "Warning: Content directory '$CONTENT_DIR' does not exist" >&2
      echo "Looking for README files in current directory instead" >&2
      CONTENT_DIR="."
  fi

  # Find all README files
  readme_files=$(find "$CONTENT_DIR" -name "README*.md" -type f 2>/dev/null | sort || true)

  if [[ -z "$readme_files" ]]; then
      echo "No README files found in $CONTENT_DIR" >&2
      exit 0
  fi

  echo "Found $(echo "$readme_files" | wc -l) README files" >&2

  # Process each file
  success_count=0
  error_count=0

  while IFS= read -r file; do
      if process_readme "$file"; then
          ((success_count++))
      else
          ((error_count++))
      fi
  done <<< "$readme_files"

  echo "TOC Generator - Complete" >&2
  echo "Successfully processed: $success_count files" >&2
  echo "Errors encountered: $error_count files" >&2

  # Exit with error if any files failed
  if [[ $error_count -gt 0 ]]; then
      exit 1
  fi
