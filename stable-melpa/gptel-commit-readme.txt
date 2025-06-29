This package provides functions to generate Git commit messages using GPTel.
It analyzes staged changes and generates appropriate commit messages following
conventional Git commit formats.

Main functions:
- `gptel-commit': Generate commit message directly
- `gptel-commit-rationale': Generate with optional context/rationale

The package supports streaming responses and excludes specified file patterns
from diff analysis to focus on relevant changes.
