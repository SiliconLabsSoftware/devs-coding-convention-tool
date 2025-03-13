![Silabs](https://img.shields.io/badge/CodingConventionTool-1.1-green)
![Silabs](https://img.shields.io/badge/precommit-2.17.0-green)
![Silabs](https://img.shields.io/badge/codespell-2.2.4-green)
![Silabs](https://img.shields.io/badge/uncrustify-0.72.0-green)
![Silabs](https://img.shields.io/badge/clang_tidy-14.0.0-green)
![Silabs](https://img.shields.io/badge/cppcheck-2.7-green)

# Coding Convention Tool
This is a code formatter tool that helps ensure consistent coding style and detects common issues in source code files. It integrates with [pre-commit](https://pre-commit.com/), allowing you to automate code formatting and checks as part of your development workflow.

## Features

- Automatically fixes end-of-file issues.
- Removes trailing whitespace from lines.
- Identifies and suggests fixes for common spelling errors using [codespell](https://github.com/codespell-project/codespell).
- Formats code according to specified [Uncrustify](https://github.com/uncrustify/uncrustify) rules base on [Silabs's coding standard](https://stash.silabs.com/projects/WMN_DOCS/repos/docs_misc/browse/software/standards/coding-standard.md)
- Checks for identifiers naming style mismatch of function, definition, struct, variable using [clang-tidy](https://releases.llvm.org/14.0.0/tools/clang/tools/extra/docs/clang-tidy/index.htmlextensible)
- Checks code for potential errors and style issues using [cppcheck](https://cppcheck.sourceforge.io/).

## Project Structure

The project is organized as follows:

## Installation

### Ubuntu

### Windows

### MacOS

## Quick start

### Add workflow to you project


Copy the folder ```tools```  and file ```.pre-commit-config.yaml``` to your repo.

Run pre-commit install to install pre-commit into your git hooks. pre-commit will now run on every commit:

```$ pre-commit install```

Staging files need formatting. For example:

```$ git add file.c```

Run pre-commit hooks on a repository to check coding convention.

```pre-commit run --all-files```

Or run pre-commit for a file:

```pre-commit run --file ./file.c```

### Exclude Folder

When using this tool, you may want to skip some folders. You can specify folders to exclude from formatting and checks by replacing the exclude regex pattern with the folders you want to skip.

Here's how you can exclude folders ```build``` and ```gecko_sdk_xxx```using regex patterns in [.pre-commit-config.yaml](./.pre-commit-config.yaml) file:

```yaml
exclude: .*/build/.*|.*/gecko_sdk.*/.*
```

### Exclude File, Ignore Words for Codespell

When using Codespell, you may encounter false positives or want to exclude specific files or directories from being checked. Codespell provides configuration options to handle these scenarios.

Here's an example of a codespell configuration file [.codespellrc](tools/.codespell/.codespellrc)

```
ignore-words = ./tools/.codespell/ignore-words.txt
exclude-file = ./tools/.codespell/exclude-file.txt
check-filenames =
check-hidden =
count =
skip = .git,*.a,
```

Explanation of Configuration Options

* **[ignore-words](tools/.codespell/ignore-words.txt)** : This option points to a file containing words that should be ignored by Codespell. If you encounter a false positive, add the problematic word to ignore-words.txt. Ensure each word is in lowercase and on a new line.

Example ignore-words.txt:

```
teh
foobar
```
* **[exclude-file](tools/.codespell/exclude-file.txt)** : This option points to a file containing lines that should be excluded from spell-checking. If a specific line in your code is causing a false positive, copy and paste the entire line into exclude-file.txt.

Example exclude-file.txt:
```
This is a sample line that should be excluded.
```
* **check-filenames**: Set this option to true if you want Codespell to check filenames for spelling errors. By default, this is empty (disabled).

* **check-hidden**: Set this option to true if you want Codespell to check hidden files for spelling errors. By default, this is empty (disabled).

* **count**: Set this option to true if you want Codespell to display the number of occurrences of each misspelled word. By default, this is empty (disabled).

* **skip**: This option allows you to specify files or directories that Codespell should skip. You can list multiple entries separated by commas. For example, .git,*.a, will skip the .git directory and all files with the .a extension.

### Uncrustify

Automatic source code formatting follows [Silabs's coding standard](https://stash.silabs.com/projects/WMN_DOCS/repos/docs_misc/browse/software/standards/coding-standard.md)
The Uncrustify configuration file is located at [/tools/uncrustify.cfg](./tools/uncrustify.cfg).

Base on the repo [/projects/WMN_TOOLS/repos/scripts/browse/uncrustify](https://stash.silabs.com/projects/WMN_TOOLS/repos/scripts/browse/uncrustify)


### Clang-Tidy

**Checks for identifiers naming style mismatch**

Clang-Tidy supports checking casing types (UPPER_CASE/lower_case) and prefixes of Function, Struct, Enum, Global Constant.
You can modify the prefix in the file [.clang-tidy](./tools/.clang-tidy).

For example, config function with lower_case and prefix 'sl_'
```
  - key: readability-identifier-naming.FunctionCase
    value: lower_case
  - key: readability-identifier-naming.FunctionPrefix
    value: 'sl_'
```

**Adding Extra Arguments**

You may need to provide additional paths to header files or define macros for Clang-Tidy to ensure it correctly analyzes your code. This can be done using the ```--extra-arg``` option in the hook configuration.

To add extra arguments to the clang-tidy hook, modify the args section of the hook configuration in your .pre-commit-config.yaml file. Here's an example of how to add extra arguments:

```yaml
-   repo: https://github.com/pocc/pre-commit-hooks
    rev: v1.3.5
    hooks:
    -   id: clang-tidy
        args:
            - --config-file=./tools/.clang-tidy
            - --use-color
            - --extra-arg=-I/inc/
            - --extra-arg=-DMY_MACRO=1
```
In this example, we've added two extra arguments to Clang-Tidy:

```-I/inc/```: Specifies an include directory where Clang-Tidy will look for header files.

```-DMY_MACRO=1```: Defines a macro named MY_MACRO with the value 1 for use in the code analysis.
