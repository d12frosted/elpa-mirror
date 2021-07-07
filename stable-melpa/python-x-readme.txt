python-x extends the built-in `python-mode' (F. Gallina's) with several
additional functions and behaviors inspired by `ess-mode' which are targeted
to interactive code evaluation with an inferior Python process.

python-x allows to evaluate code blocks using comments as delimiters (code
"sections") or using arbitrarily nested folding marks. By default, a code
section is delimited by comments starting with "# ---"; while folds are
defined by "# {{{" and "# }}}" (see `python-shell-send-fold-or-section').

python-x installs an handler to show uncaught exceptions produced by
interactive code evaluation by default. See `python-shell-show-exceptions'
to control this behavior.

The following functions are introduced:
- `python-shell-send-line': evaluate and print the current line, accounting
  for statement and line continuations.
- `python-shell-send-line-and-step': evaluate and current line as above,
  then move the point to the next automatically.
- `python-shell-send-paragraph': evaluate the current paragraph.
- `python-shell-send-paragraph-and-step': evaluate the current paragraph,
  then move the point to the next automatically.
- `python-shell-send-region-or-paragraph': evaluate the current region when
  active, otherwise evaluate the current paragraph.
- `python-shell-send-fold-or-section': evaluate the region defined by the
  current code fold or section.
- `python-shell-send-dwim': evaluate the region when active,
  otherwise revert to the current fold or section.
- `python-shell-print-region-or-symbol': evaluate and print the current
  region or symbol at point, displaying the inferior process output.

python-x uses `volatile-highlights', when available, for highlighting
multi-line blocks. Installation through "melpa" is recommended (you don't
actually need to enable `volatile-highlights-mode' itself). python-x also
uses `folding' to interpret and define folding marks. `folding-mode' needs
to be enabled manually if code folding is also desired.

Read through the Usage section in the source file for usage instructions and
recommended keybindings.
