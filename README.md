# Table of Contents Generator

A simple and safe Table of Contents generator for Markdown files that can be used as a standalone script or GitHub Action.
Don't forget to leave a ⭐ if you found this helpful 

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Usage](#usage)
  - [As a Standalone Script](#as-a-standalone-script)
  - [As a GitHub Action](#as-a-github-action)
- [How It Works](#how-it-works)
- [Safety Features](#safety-features)
- [Configuration](#configuration)
- [Examples](#examples)
- [Contributing](#contributing)

## Overview

TocScript automatically generates and updates Table of Contents for all `README*.md` files in your project. It's designed to be safe, reliable, and easy to use both locally and in CI/CD pipelines.

## Features

- 🔍 **Automatic Detection** - Finds all README files in specified directories
- 📋 **Header Extraction** - Supports H1-H6 headers with proper nesting
- 🔗 **GitHub-Compatible Links** - Generates proper anchor links
- 🛡️ **Safety First** - Multiple validation checks prevent data loss
- 💾 **Backup Creation** - Creates backups before modifying files
- 🎯 **Flexible Usage** - Works as script or GitHub Action
- 📝 **Smart Insertion** - Places TOC after main title or at beginning

## Usage

### As a Standalone Script

```bash
# Download the script
curl -o generate-toc.sh https://raw.githubusercontent.com/DanielRaphael1/TocScript/main/src/generate-toc.sh
chmod +x generate-toc.sh

# Generate TOCs for current directory
./generate-toc.sh

# Generate TOCs for specific folder
./generate-toc.sh docs

# Generate TOCs for multiple folders
./generate-toc.sh src/docs
```

### As a GitHub Action

Add to your `.github/workflows/toc.yml`:

```yaml
name: Update TOCs

on:
  push:
    paths:
      - '**/*.md'
  pull_request:
    paths:
      - '**/*.md'

jobs:
  update-toc:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
      
      - uses: DanielRaphael1/TocScript@main
        with:
          target-dir: docs  # Optional, defaults to current directory
      
      - name: Commit changes
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add "**/*.md"
          git diff --cached --quiet || git commit -m "chore: update TOCs"
          git push
```

## How It Works

1. **Scans Directory** - Recursively finds all `README*.md` files
2. **Extracts Headers** - Parses markdown headers (H1-H6)
3. **Generates Links** - Creates GitHub-compatible anchor links
4. **Removes Old TOC** - Safely removes existing TOC sections
5. **Inserts New TOC** - Places TOC after main title or at beginning
6. **Validates Output** - Ensures file integrity before saving

## Safety Features

- ✅ **File Backups** - Creates `.bak` files before modification
- ✅ **Content Validation** - Checks file size and content integrity
- ✅ **Error Recovery** - Restores from backup if generation fails
- ✅ **Skip Empty Files** - Ignores files without headers
- ✅ **Duplicate Detection** - Handles duplicate header names
- ✅ **Code Block Awareness** - Ignores headers inside code blocks

## Configuration

### Environment Variables

- `INPUT_TARGET_DIR` - Target directory (for GitHub Actions)
- `TOC_HEADER` - Custom TOC header (default: "## Table of Contents")
- `GITHUB_WORKSPACE` - Workspace directory (automatically set in Actions)

### Script Parameters

```bash
./generate-toc.sh [directory]
```

- `directory` - Target directory (optional, defaults to current directory)

## Examples

### Basic Usage

```bash
# Generate TOCs for all README files in current directory
./generate-toc.sh

# Output:
# TOC Generator - Starting
# Content directory: .
# Processing: ./README.md
#   ✓ Updated successfully
# TOC Generator - Complete
# Successfully processed: 1 files
# Errors encountered: 0 files
```

### Generated TOC Format

```markdown
## Table of Contents

- [Introduction](#introduction)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Advanced Usage](#advanced-usage)
  - [Configuration](#configuration)
  - [Customization](#customization)
```

### Before and After

**Before:**
```markdown
# My Project

This is my awesome project.

## Installation

Install with npm...

## Usage

Use it like this...
```

**After:**
```markdown
# My Project

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)

This is my awesome project.

## Installation

Install with npm...

## Usage

Use it like this...
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

### Development

```bash
# Clone the repository
git clone https://github.com/DanielRaphael1/TocScript.git
cd TocScript

# Test the script
./src/generate-toc.sh test/

# Run tests (if available)
./test/run-tests.sh
```

---


## Support

- 🐛 [Report Issues](https://github.com/DanielRaphael1/TocScript/issues)
- 💬 [Discussions](https://github.com/DanielRaphael1/TocScript/discussions)
---

**Made with ❤️ for the developer community**
