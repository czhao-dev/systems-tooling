# Git Commit Report Generator

A Perl-based command-line tool for generating useful Git commit activity reports from a local repository.

This project analyzes Git history and summarizes commit activity by author, date, directory, file type, and change size. It is designed for developers who want a quick way to understand project activity, identify risky commits, review team contributions, and generate lightweight engineering reports.

## Features

* Summarize Git commits over a selected date range
* Group commits by author
* Group changes by directory or file extension
* Detect large or risky commits
* Generate daily, weekly, or monthly activity reports
* Output reports in text, Markdown, CSV, or JSON format
* Support filtering by author, branch, date range, and path
* Provide useful statistics for code reviews, project tracking, and engineering productivity analysis

## Example Use Cases

This tool can be used to answer questions such as:

* Who contributed the most commits this week?
* Which directories changed the most recently?
* What were the largest commits in the last month?
* How many bug-fix, feature, refactor, and test commits were made?
* Which files or modules are changing frequently?
* What should be included in a weekly engineering status report?

## Project Structure

```text
git-commit-report-generator/
├── bin/
│   └── git_commit_report.pl
├── lib/
│   ├── GitCommitReport/
│   │   ├── Parser.pm
│   │   ├── Analyzer.pm
│   │   ├── Formatter.pm
│   │   └── Utils.pm
├── examples/
│   ├── sample_report.md
│   └── sample_config.yml
├── t/
│   ├── parser.t
│   ├── analyzer.t
│   └── formatter.t
├── README.md
├── Makefile.PL
└── LICENSE
```

## Requirements

* Perl 5.16 or later
* Git
* A local Git repository

Recommended Perl modules:

* `Getopt::Long`
* `File::Find`
* `Time::Piece`
* `JSON::PP`
* `Text::CSV`
* `YAML::Tiny`

Some of these modules may already be included with your Perl installation.

## Installation

Clone the repository:

```bash
git clone https://github.com/your-username/git-commit-report-generator.git
cd git-commit-report-generator
```

Install dependencies:

```bash
cpan Getopt::Long File::Find Time::Piece JSON::PP Text::CSV YAML::Tiny
```

Or, if using `cpanm`:

```bash
cpanm Getopt::Long File::Find Time::Piece JSON::PP Text::CSV YAML::Tiny
```

Make the main script executable:

```bash
chmod +x bin/git_commit_report.pl
```

## Usage

Run the tool inside a Git repository:

```bash
perl bin/git_commit_report.pl
```

Generate a report for the last 7 days:

```bash
perl bin/git_commit_report.pl --since "7 days ago"
```

Generate a report for a specific date range:

```bash
perl bin/git_commit_report.pl --since "2026-01-01" --until "2026-01-31"
```

Generate a Markdown report:

```bash
perl bin/git_commit_report.pl --format markdown --output report.md
```

Generate a CSV report:

```bash
perl bin/git_commit_report.pl --format csv --output report.csv
```

Filter by author:

```bash
perl bin/git_commit_report.pl --author "Alice"
```

Analyze a specific branch:

```bash
perl bin/git_commit_report.pl --branch main
```

Analyze changes under a specific directory:

```bash
perl bin/git_commit_report.pl --path src/
```

## Command-Line Options

| Option                  | Description                                         |
| ----------------------- | --------------------------------------------------- |
| `--since <date>`        | Start date for commit analysis                      |
| `--until <date>`        | End date for commit analysis                        |
| `--author <name>`       | Filter commits by author                            |
| `--branch <branch>`     | Analyze a specific Git branch                       |
| `--path <path>`         | Analyze changes under a specific file or directory  |
| `--format <type>`       | Output format: `text`, `markdown`, `csv`, or `json` |
| `--output <file>`       | Write report to a file                              |
| `--top <N>`             | Show top N results for ranked sections              |
| `--risky-threshold <N>` | Mark commits touching more than N files as risky    |
| `--help`                | Show help message                                   |

## Sample Output

```text
Git Commit Activity Report
==========================

Repository: example-project
Branch: main
Date Range: 2026-01-01 to 2026-01-31

Summary
-------
Total commits: 128
Total authors: 6
Files changed: 342
Lines added: 12,450
Lines deleted: 7,820

Commits by Author
-----------------
Alice      42 commits
Bob        31 commits
Charlie    24 commits
Diana      18 commits
Evan       13 commits

Top Changed Directories
-----------------------
src/        156 files changed
tests/       89 files changed
docs/        37 files changed
scripts/     28 files changed

Largest Commits
---------------
1. a1b2c3d  Alice    48 files changed    Refactor parser module
2. e4f5g6h  Bob      36 files changed    Add report formatter
3. i7j8k9l  Diana    29 files changed    Update unit tests

Risky Commits
-------------
a1b2c3d  Alice    48 files changed    Refactor parser module
e4f5g6h  Bob      36 files changed    Add report formatter
```

## How It Works

The tool uses Git commands such as:

```bash
git log
git show
git diff --stat
```

It parses the command output, extracts commit metadata, analyzes changed files, and generates a structured report.

The analysis pipeline is organized into three main stages:

1. **Parsing**
   Extract commit hash, author, date, subject, changed files, insertions, and deletions.

2. **Analysis**
   Group commits by author, directory, file extension, date, and change size.

3. **Formatting**
   Generate output in text, Markdown, CSV, or JSON format.

## Report Categories

The generated report may include:

* Overall commit summary
* Commits by author
* Commits by date
* Files changed by directory
* Files changed by extension
* Largest commits
* Risky commits
* Most frequently changed files
* Commit message classification

## Commit Classification

The tool can optionally classify commits based on keywords in the commit subject.

Example categories:

| Category      | Example Keywords                        |
| ------------- | --------------------------------------- |
| Feature       | `add`, `implement`, `support`, `enable` |
| Bug Fix       | `fix`, `bug`, `issue`, `correct`        |
| Refactor      | `refactor`, `cleanup`, `simplify`       |
| Test          | `test`, `coverage`, `unit test`         |
| Documentation | `doc`, `readme`, `comment`              |
| Build         | `build`, `cmake`, `makefile`, `ci`      |

Example:

```text
Commit Type Summary
-------------------
Feature        35
Bug Fix        28
Refactor       17
Test           22
Documentation   9
Build           6
Other          11
```

## Configuration File

A configuration file can be used to customize report behavior.

Example `config.yml`:

```yaml
default_format: markdown
risky_commit_file_threshold: 25
top_results: 10

classification:
  feature:
    - add
    - implement
    - support
    - enable
  bugfix:
    - fix
    - bug
    - issue
    - correct
  refactor:
    - refactor
    - cleanup
    - simplify
  test:
    - test
    - coverage
  documentation:
    - doc
    - readme
  build:
    - build
    - cmake
    - makefile
    - ci
```

Run with a config file:

```bash
perl bin/git_commit_report.pl --config examples/sample_config.yml
```

## Testing

Run unit tests:

```bash
prove -l t/
```

Run a specific test file:

```bash
prove -l t/parser.t
```

## Development Plan

Planned improvements:

* Add HTML report output
* Add charts for commit trends
* Add support for multiple repositories
* Add blame-based ownership summary
* Add module-level churn analysis
* Add GitHub Actions integration
* Add support for generating release notes
* Add interactive terminal summary

## Why This Project Is Useful

This project demonstrates practical scripting and software engineering skills, including:

* Perl command-line tool development
* Git automation
* Text parsing
* Regular expressions
* Report generation
* Modular software design
* Unit testing
* Engineering productivity tooling

It is especially useful for developers working with large codebases, frequent commits, regression workflows, and long-running software projects.

## License

This project is licensed under the MIT License.
