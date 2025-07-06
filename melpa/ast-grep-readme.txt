This package provides an Emacs interface to ast-grep, a CLI tool for
code structural search, lint and rewriting.  It integrates with the
completing-read interface (Vertico, etc.) to provide fast
and interactive code searching based on Abstract Syntax Tree patterns.

Features:
- Search code using ast-grep patterns
- Project-wide search
- Integration with completing-read (Vertico, etc.)
- Streaming JSON parsing for efficient processing
- Async search with live results (when consult is available)
