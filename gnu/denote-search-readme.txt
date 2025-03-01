# denote-search: A simple search utility for Denote

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

If you are using Emacs 29.1 onwards, you can install the package by
evaluating the following code:

```elisp
(package-vc-install
 '(denote-search
   :url "https://github.com/lmq-10/denote-search"
   :doc "README.org"))
```

Alternatively, you can use the :vc keyword from use-package, as shown
in the sample configuration:

```elisp
(use-package denote-search
  :ensure t
  ;; Installation with VC
  :vc (:url "https://github.com/lmq-10/denote-search"
       :rev :newest)
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

Of course, you can also install it manually or use an alternative
package manager such as quelpa.
