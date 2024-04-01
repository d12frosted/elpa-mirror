This package provides Emacs commands to format and lint Python code using
the external 'ruff' tool.  It offers functions to format the entire buffer,
specific regions, or Org mode source blocks.

Prerequisites:
- The 'ruff' command-line tool must be installed and available in your
  system's PATH.

Installation of 'ruff':
- Please refer to the 'ruff' documentation at:
  https://docs.astral.sh/ruff/installation/

Configuring lazy-ruff:
The global variables defined in the part before the ruff-lint-format-block
function can be freely changed with setq in your init.el (or other
personalization files) for configuring lazy-ruff.
