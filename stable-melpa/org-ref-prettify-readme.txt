This file provides a minor mode, `org-ref-prettify-mode', that is
supposed to be used with `org-ref' package.  After enabling this mode
(with "M-x org-ref-prettify-mode" command), you will see that the
citation org-ref links in the current buffer are shown in a more
readable format, e.g.:

  [[cite:CoxeterPG2ed][53]]          ->  Coxeter, 1987, p. 53
  [[citetitle:CoxeterPG2ed]]         ->  Projective Geometry
  citeauthor:CoxeterPG2ed            ->  Coxeter
  [[parencite:CoxeterPG2ed][36-44]]  ->  (Coxeter, 1987, pp. 36-44)

The citation links themselves are not changed, they are just
displayed differently.  You can disable the mode by running "M-x
org-ref-prettify-mode" again, and you see the original links.

Also, this file provides 2 more commands:
- `org-ref-prettify-edit-link-at-point',
- `org-ref-prettify-edit-link-at-mouse'.

They allow you to edit the current link in the minibuffer.  By
default, they are bound to C-RET and the right mouse click
respectively.  But you can disable these bindings with:

  (setq org-ref-prettify-bind-edit-keys nil)

To install this package manually, add the following to your Emacs init file:

  (add-to-list 'load-path "/path/to/org-ref-prettify")
  (autoload 'org-ref-prettify-mode "org-ref-prettify" nil t)
