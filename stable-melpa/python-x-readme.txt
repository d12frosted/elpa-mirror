python-x extends the built-in `python-mode' (F. Gallina's) with several
additional functions and behaviors inspired by `ess-mode' which are targeted
to interactive code evaluation with an inferior Python process.

Quick overview:

Use `python-x-setup' in your emacs startup:

  (python-x-setup)

In any `python-mode' buffer use [C-c C-p] to start a new interpreter,
then use [C-c C-c] to evaluate the current section. The default
section delimiter is "# ---" but can be changed via
`python-section-delimiter' to be similar to Spyder/Pyzo:

  (setq python-section-delimiter "##")

See the `python-x' customization group for additional settings.

Detailed documentation:

python-x allows to evaluate code blocks using comments as delimiters (code
"sections") or using arbitrarily nested folding marks. By default, a code
section is delimited by comments starting with "# ---"; while folds are
defined by "# {{{" and "# }}}" (see `python-shell-send-fold-or-section').

python-x installs an handler to show uncaught exceptions produced by
interactive code evaluation by default. See `python-shell-show-exceptions'
to control this behavior. The execution status of the inferior process is
tracked in the modeline, in order to know when the evaluation is complete.

The following functions are introduced:
- `python-shell-send-line': evaluate and print the current line, accounting
  for statement and line continuations.
- `python-shell-send-paragraph': evaluate the current paragraph.
- `python-shell-send-region-or-paragraph': evaluate the current region when
  active, otherwise evaluate the current paragraph.
- `python-shell-send-fold-or-section': evaluate the region defined by the
  current code fold or section.
- `python-shell-send-dwim': evaluate the region when active,
  otherwise revert to the current fold or section.
- `python-shell-print-region-or-symbol': evaluate and print the current
  region or symbol at point, displaying the inferior process output.
- `python-shell-display-shell': Display the inferior Python process output
  in another window.
- `python-shell-switch-to-shell-or-buffer': Switch between the buffer and
  the inferior (cycling command).
- `python-shell-restart-process': Restart the inferior Python process.
- `python-forward-fold-or-section': Move forward by fold/sections.
- `python-backward-fold-or-section': Move backward by fold/sections.
- `python-mark-fold-or-section': Mark current fold or section.
- `python-eldoc-for-region-or-symbol': Summary help for the active
  region or symbol at point.
- `python-help-for-region-or-symbol': Display full help for the active
  region or symbol at point.

All "python-shell-send-*" functions are also provided in a "*-and-step"
variant that moves the point after evaluation.

python-x uses `volatile-highlights', when available, for highlighting
multi-line blocks. Installation through "melpa" is recommended (you don't
actually need to enable `volatile-highlights-mode' itself). python-x also
uses `folding' to interpret and define folding marks. Again, `folding-mode'
needs to be enabled manually if code folding is also desired.
`expand-region' is equally supported, when previously loaded.

The default keyboard map definition set by (python-x-setup) is
currently tuned to the author's taste, and may change over time. You
are encouraged to look at the definition of `python-x-setup' and
derive your own.
