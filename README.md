# Code Convention Tool

Docker-based code formatting and static analysis. Identical checks in CI and locally.

Enforces [Silicon Labs coding standard](https://github.com/SiliconLabsSoftware/agreements-and-guidelines/blob/main/coding_standard.md) using:
- **Formatting** - Uncrustify, trailing whitespace, EOF newlines
- **Linting** - Clang-tidy naming conventions
- **Spelling** - Codespell

Outputs: `CodingConventionTool.txt` (report), `code-fix.patch` (auto-fix diff)

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
    exclude-regex: ""           # Optional: regex pattern to exclude paths from all checks
    codespell-ignore-words: ""  # Optional: comma-separated words for codespell to ignore
    codespell-skip-paths: ""    # Optional: comma-separated glob patterns for codespell to skip
```

### Local Docker

**Quick Start** (from your repo root):
```bash
# Build image
mkdir -p ./tmp
git clone https://github.com/SiliconLabsSoftware/devs-coding-convention-tool.git ./tmp/devs-coding-convention-tool
docker build -t devs-coding-convention-tool ./tmp/devs-coding-convention-tool

# Run checks
docker run --rm -v "$(pwd):/src" devs-coding-convention-tool
```

**With Custom Config:**
```bash
docker run --rm \
    -v "$(pwd):/src" \
    -e EXCLUDE_REGEX=".*\/generated\/.*|.*\.pb\.c" \
    -e CODESPELL_IGNORE_WORDS="hsi,aci,pullrequest" \
    -e CODESPELL_SKIP_PATHS="docs/*,third_party/*" \
    devs-coding-convention-tool
```

Files modified in-place. Review: `git diff`

## Configuration

Default rules embedded at build time:

| Tool           | Config Path                       | Notes              |
| -------------- | --------------------------------- | ------------------ |
| **Uncrustify** | `tools/uncrustify/uncrustify.cfg` | Company standard   |
| **Clang-Tidy** | `tools/.clang-tidy`               | Naming conventions |
| **Codespell**  | `tools/.codespell/`               | Spell checking     |

### Inputs

| Input                    | Description                      | Format                 | Example                        |
| ------------------------ | -------------------------------- | ---------------------- | ------------------------------ |
| `exclude-regex`          | Paths to exclude from all checks | Regex (pipe-separated) | `.*\/generated\/.*\|.*\.pb\.c` |
| `codespell-ignore-words` | Words codespell should ignore    | Comma-separated        | `hsi,aci,pullrequest`          |
| `codespell-skip-paths`   | Files codespell should skip      | Comma-separated globs (fnmatch-style), avoid `**` | `docs/*,third_party/*` |

Custom inputs are applied at runtime inside the container by `handle_custom_inputs.py`.

## Reference

### Container Filesystem

Config files use absolute `/action/` paths because they resolve inside the Docker container:

```
Container
├── /action/                        # Config files (baked into image at build)
│   ├── .pre-commit-config.yaml
│   └── tools/
│       ├── .clang-tidy
│       ├── .codespell/
│       └── uncrustify/
│
└── /src/                           # Your repository (mounted at runtime)
    ├── (your source files)
    ├── CodingConventionTool.txt    # Generated report
    └── code-fix.patch              # Generated patch
```
