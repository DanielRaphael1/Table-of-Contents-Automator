# DevOps Zero to Hero

A comprehensive DevOps learning repository with automated Table of Contents generation for all documentation.

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [TOC Generator](#toc-generator)
  - [How It Works](#how-it-works)
  - [Manual Usage](#manual-usage)
  - [Automated Workflow](#automated-workflow)
- [Content Organization](#content-organization)
- [Contributing](#contributing)
- [Getting Started](#getting-started)

## Overview

This repository contains comprehensive DevOps tutorials, guides, and examples covering various technologies and practices. All documentation includes automatically generated Table of Contents for better navigation.

## Repository Structure

```
DevOps-Zero2Hero/
├── Content/                    # All learning materials
│   ├── Linux/                 # Linux tutorials
│   ├── Docker/                # Docker guides
│   ├── Kubernetes/            # K8s resources
│   ├── Terraform/             # Infrastructure as Code
│   ├── CI-CD/                 # Pipeline tutorials
│   └── ...                    # More topics
├── generate-toc.sh            # TOC generator script
├── .github/workflows/         # GitHub Actions
│   └── toc-generator.yaml    # Automated TOC updates
└── README.md                  # This file
```

## TOC Generator

This repository includes a powerful Table of Contents generator that automatically creates navigation links for all README files.

### How It Works

The TOC generator:
- 🔍 Scans all `README*.md` files in the specified directory
- 📋 Extracts headers (H1-H6) and creates navigation links
- 🔗 Generates GitHub-compatible anchor links
- 📝 Inserts TOC after the main title or at the beginning
- 🛡️ Includes safety checks to prevent data loss
- 💾 Creates backups before modifying files

### Manual Usage

Run the TOC generator locally:

```bash
# Make script executable (first time only)
chmod +x generate-toc.sh

# Generate TOCs for Content folder
./generate-toc.sh Content

# Generate TOCs for specific subfolder
./generate-toc.sh Content/Linux

# Generate TOCs for current directory
./generate-toc.sh .
```

**Example Output:**
```
TOC Generator - Starting
Content directory: Content
Processing: Content/Linux/README.md
  ✓ Updated successfully
Processing: Content/Docker/README.md
  ✓ Updated successfully
TOC Generator - Complete
Successfully processed: 2 files
Errors encountered: 0 files
```

### Automated Workflow

The repository includes a GitHub Actions workflow that automatically updates TOCs:

**Triggers:**
- 📝 When README files in `Content/` are modified
- 🔄 On pull requests affecting `Content/` READMEs  
- 🎯 Manual trigger via GitHub Actions tab

**What it does:**
1. Checks out the repository
2. Runs the TOC generator on the `Content/` folder
3. Commits and pushes changes automatically
4. Uses `github-actions[bot]` as the commit author

**Workflow file:** `.github/workflows/toc-generator.yaml`

## Content Organization

Each topic in the `Content/` directory follows this structure:

```
Content/TopicName/
├── README.md              # Main topic overview with TOC
├── subtopic1.md          # Detailed guides
├── subtopic2.md          # Examples and tutorials
├── examples/             # Code examples
└── exercises/            # Hands-on exercises
```

**TOC Example:**
```markdown
## Table of Contents

- [Introduction](#introduction)
- [Getting Started](#getting-started)
  - [Prerequisites](#prerequisites)
  - [Installation](#installation)
- [Advanced Topics](#advanced-topics)
  - [Configuration](#configuration)
  - [Best Practices](#best-practices)
```

## Contributing

We welcome contributions! Here's how to add content:

### Adding New Content

1. **Fork the repository**
2. **Create your content** in the appropriate `Content/` subfolder
3. **Add headers** to your README files (the TOC will be generated automatically)
4. **Submit a pull request**

### Content Guidelines

- 📖 Use clear, descriptive headers
- 🏗️ Follow the established folder structure
- 📝 Include practical examples and exercises
- 🎯 Focus on hands-on learning
- 🔗 Link to external resources when helpful

### TOC Guidelines

- ✅ Headers are automatically detected (H1-H6: `#` to `######`)
- ✅ TOC header must be exactly `## Table of Contents`
- ✅ Existing TOCs are automatically updated
- ✅ No manual TOC maintenance required

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/DanielRaphael1/DevOps-Zero2Hero.git
   cd DevOps-Zero2Hero
   ```

2. **Explore the content:**
   ```bash
   ls Content/
   ```

3. **Start with a topic:**
   ```bash
   cd Content/Linux
   cat README.md
   ```

4. **Generate TOCs locally (optional):**
   ```bash
   ./generate-toc.sh Content
   ```

---

## Features

- 🤖 **Automated TOC generation** for all documentation
- 📚 **Comprehensive DevOps coverage** from basics to advanced
- 🛡️ **Safe script execution** with backup and validation
- 🔄 **GitHub Actions integration** for automatic updates
- 📖 **Structured learning path** with clear navigation
- 🎯 **Hands-on examples** and practical exercises

---

**Happy Learning!** 🚀

For questions or suggestions, please open an issue or submit a pull request.
