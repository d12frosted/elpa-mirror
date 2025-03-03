# denote-search: A simple search utility for Denote

<a href="https://elpa.gnu.org/packages/denote-search.html"><img alt="GNU ELPA" src="https://elpa.gnu.org/packages/denote-search.svg"/></a>

This package provides a search utility for Denote, the simple-to-use,
focused-in-scope, and effective note-taking tool for Emacs.

The command `denote-search` is the main point of entry.  It accepts a
query, which should be a regular expression, and then searches the
contents of all the notes stored in `denote-directory` for it.  The
results are put in a buffer which allows folding and further
filtering; all standard commands offered by Xref are available as
well.

This package has the same code principles as Denote: to be
simple-to-use, focused-in-scope, and effective.  We build upon Xref to
be good Emacs citizens, and don't use any dependencies other than
Denote and built-in libraries.

See the `README.org` file for a comprehensive manual.

## Installation

denote-search is available in GNU ELPA. You can install the package by doing:

```
M-x package-refresh-contents RET
M-x package-install RET denote-search RET
```

If for whatever reason you prefer to install it from source, you can do so by evaluating the following code:

```elisp
(package-vc-install
 '(denote-search
   :url "https://github.com/lmq-10/denote-search"
   :doc "README.org"))
```

## Sample configuration

```elisp
(use-package denote-search
  :ensure t
  :bind
  ;; Customize keybindings to your liking
  (("C-c s s" . denote-search)
   ("C-c s d" . denote-search-marked-dired-files)
   ("C-c s r" . denote-search-files-referenced-in-region))
  :custom
  ;; Disable help string (set it once you learn the commands)
  ;; (denote-search-help-string "")
  ;; Display keywords in results buffer
  (denote-search-format-heading-function #'denote-search-format-heading-with-keywords))
```
