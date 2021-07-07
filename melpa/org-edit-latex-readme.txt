This package will let you edit a latex fragment like editing a src code
block.

Install
=======

First, download this package and include its path in your load-path. Then,
you can add following in your init file:

(require 'org-edit-latex)

And don't forget to add latex to `org-babel-load-languages' (below is for
demonstration, your languages list may differ from it.)

(org-babel-do-load-languages
 'org-babel-load-languages
 '((emacs-lisp . t)
   (latex . t)   ;; <== add latex to the list
   (python . t)
   (shell . t)
   (ruby . t)
   (perl . t)))

Usage
=====

First, turn on `org-edit-latex-mode'. Then you can edit a LaTeX fragment just
as what you'll do to edit a src block.

Use `org-edit-special' to enter a dedicated LaTeX buffer.
Use `org-edit-src-exit' to exit LaTeX buffer when you finished editing.
Use `org-edit-src-abort' to quit editing without saving changes.

Note that all above commands are built-in Org commands, so your current
keybindings to them will do the job.
