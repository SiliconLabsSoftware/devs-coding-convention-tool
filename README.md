# Code Convention Tool

Docker-based code formatting and static analysis. Identical checks in CI and locally.

## Features
- **Uncrustify v0.64** - Formatting ([Silabs Style](https://github.com/SiliconLabsSoftware/agreements-and-guidelines/blob/main/coding_standard.md))
- **Clang-Tidy** - Naming conventions & common errors
- **Codespell** - Spell checking
- **Patch** - Generates patch for automated corrections

## How It Works

This composite action uses Docker to isolate tool dependencies from your repository:

1. **Your workflow** checks out your code to `${{ github.workspace }}`
2. **Action downloads** config files automatically from this repo
3. **Docker image built** with pre-commit, uncrustify, clang-tidy, codespell
4. **Container mounts** your repo as `/src` (read-write volume)
5. **Pre-commit runs** checks against your code, modifying files in-place
6. **Results saved** to your workspace: `CodingConventionTool.txt`, `code-fix.patch`

**Security for Internal Repos:**
- Use `runs-on: [self-hosted, ...]` to keep proprietary code on-premises
- All processing is local; no code transmitted externally
- Only action config files (public tools) are downloaded

## Usage

### GitHub Actions
```yaml
- name: Checkout
  uses: actions/checkout@v4

- name: Code Convention Check
  uses: SiliconLabsSoftware/devs-coding-convention-tool@main
  with:
    custom-ignore-words: ""       # Optional
    custom-exclude-file: ""       # Optional
    custom-pre-commit-config: ""  # Optional
```

**Outputs:** `CodingConventionTool.txt` (report), `code-fix.patch` (diff)

### Local Docker

**Quick Start** (from your repo root):
```bash
# Build image
git clone https://github.com/SiliconLabsSoftware/devs-coding-convention-tool.git /tmp/convention-tool
docker build -t convention-tool /tmp/convention-tool

# Run checks
docker run --rm --user $(id -u):$(id -g) -v "$(pwd):/src" convention-tool
```

**With Custom Config:**
```bash
docker run --rm \
    --user $(id -u):$(id -g) \
    -v "$(pwd):/src" \
    -e CUSTOM_IGNORE_WORDS=".github/formatting_config/ignore-words.txt" \
    -e CUSTOM_EXCLUDE_FILE=".github/formatting_config/exclude-file.txt" \
    -e CUSTOM_PRE_COMMIT_CONFIG=".github/formatting_config/.pre-commit-config.yaml" \
    convention-tool
```

Files modified in-place. Review: `git diff`

## Configuration

Default rules embedded at build time:

| Tool           | Config Path                       | Customization                              |
| -------------- | --------------------------------- | ------------------------------------------ |
| **Uncrustify** | `tools/uncrustify/uncrustify.cfg` | Override via `custom-pre-commit-config`    |
| **Clang-Tidy** | `tools/.clang-tidy`               | Override via `custom-pre-commit-config`    |
| **Codespell**  | `tools/.codespell/`               | Override via `custom-ignore-words/exclude` |

Use `custom-pre-commit-config` to provide your own `.pre-commit-config.yaml` for full control.
