Idea taken from http://www.columbia.edu/~jr2075/sudoku.el

Totally rewritten.

Features:

  * Custom puzzle editor
  * Printing puzzles (TeX source generator)
  * Puzzle Solver (simple heuristics + trial and error)
  * Auto-insert assistance (S1, H1, CC i.e. Constrained Cell)
  * Step-by-step puzzle deduce (using S1, H1 and CC heuristics)
  * Nifty pencils (assist for Nishio, Cycles, Loops)
  * Undo/Redo operations
  * Optimal (single solution) puzzles generator (very
    straightforward, but usable)
  * Board downloader (from websudoku.com and menneske.no)
  * Save/Load puzzles
  * Collection of built-in puzzles

Usage
~~~~~
To start using sudoku, add one of:

  (require 'sudoku)

or, more preferable way:

  (autoload 'sudoku "sudoku" "Start playing sudoku." t)

to your init.el file.

Start playing with M-x sudoku RET

Customization
~~~~~~~~~~~~~
You might want to customize next variables:

  * `sudoku-level'     - Level for puzzles
  * `sudoku-download'  - Non-nil to download puzzles
  * `sudoku-download-source' - Source to download puzzles from
  * `sudoku-modeline-show-values' - Show possible values in modeline

To create custom puzzle (snatched from newspaper or magazine) do:
M-x sudoku-custom RET and follow instructions.

If you use `desktop.el' you might want next code in your init.el:

  (push 'sudoku-custom-puzzles desktop-globals-to-save)
  (push 'sudoku-solved-puzzles desktop-globals-to-save)

Deduce/Auto-insert
~~~~~~~~~~~~~~~~~~
This file includes simple board deducing heuristics, that might
help not to get bored with filling simple values.  Deduce method
`sudoku-insert-hidden-single' is pretty smart, it can solve almost
every `medium' sudoku puzzle in conjunction with
`sudoku-insert-single'.  To enable auto-insert feature, use:

  (sudoku-turn-on-autoinsert)

or use method suitable for autoloading:

  (setq sudoku-autoinsert-mode t)
  (add-hook 'sudoku-after-change-hook 'sudoku-autoinsert)

You might also want to customize `sudoku-deduce-methods' variable.

Auto-insert is useful for sudoku hackers, who dislikes to insert
pretty trivial values into `evil' puzzles, but want to focus on
real problems.  You can toggle auto-insert mode while solving
puzzle with `a' key.

To deduce next step using auto-inserters use `d' key.

Pencils
~~~~~~~
Sometimes, especially when solving complex puzzle, you might want to try
out some values with pencil to find a contradiction and then return
to pen.  You can do it with `p' command.  Use `p' to enable pencil,
and `C-u p' to return back to pen.  There are only two pencils
available.  Current pencil is displayed on screen.

Printing
~~~~~~~~
To print puzzle you will need sudoku TeX package (available at
http://ctan.math.utah.edu/tex-archive/macros/latex/contrib/sudoku/)

press `P' while solving puzzle and it will generate TeX file.

Saving/Loading Puzzles
~~~~~~~~~~~~~~~~~~~~~~
You can save/load puzzles to/from sdk files (SadMan Sudoku file
format, http://www.sadmansoftware.com/sudoku/faq19.htm) with
`sudoku-save-puzzle' (C-x C-s) and `sudoku-load-puzzle' commands.

To make Emacs load puzzle with `C-x C-f' add next to init.el

  (add-to-list 'auto-mode-alist '("\\.sdk\\'" . sudoku-mode))
