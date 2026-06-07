
This is an Emacs port of the classic "desert" colorscheme from Vim.
It tries to preserve:
- dark warm gray background
- golden/yellow comments
- soft greens for strings
- sandy/orange accents for variables and constants
- gentle blue for function names / types

To use:
  (load-theme 'desert t)

Or with straight.el + use-package:
  (use-package desert-theme
    :straight (desert-theme
               :type git
               :host github
               :repo "bkc39/desert-theme")
    :config
    (load-theme 'desert t))
