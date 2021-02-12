With this package, you can edit a latex fragment/environment in an edit
buffer, and you can even complete and preview LaTeX in the edit buffer.

The latest release of Org (version 9.1) provides a similar feature, i.e. edit
a latex environment in an edit buffer. But there are still some features
offered here are not in org yet. Some of them are:

1. Complete based on your latex header.

With org-edit-latex, you can complete your latex commands according to the
#+latex_header: lines in your main org buffer (powered by AucTeX). This is
not possible in vanilla org.

2. Preview in the edit buffer.

You don't have to quit your edit buffer to do the preview. You can just
preview at point! With the fantastic AucTeX working behind, you can cache
your preamble and preview really fast (faster than org-preview).

3. Edit and preview latex fragments in edit buffer.

Besides LaTeX environments, you can also edit/preview latex fragments in edit
buffer. This may not count as a feature. but in case you need it, it's there.

This package has been tested on Org 8.0 and above. Feel free to use it on
Org mode shipped with emacs.

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
