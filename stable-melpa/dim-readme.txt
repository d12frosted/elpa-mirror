The purpose of this package is to "customize" the mode-line names of
major and minor modes.  An example of using:

(when (require 'dim nil t)
  (dim-major-names
   '((emacs-lisp-mode    "EL")
     (lisp-mode          "CL")
     (Info-mode          "I")
     (help-mode          "H")))
  (dim-minor-names
   '((auto-fill-function " ↵")
     (isearch-mode       " 🔎")
     (whitespace-mode    " _"  whitespace)
     (paredit-mode       " ()" paredit)
     (eldoc-mode         ""    eldoc))))

Along with `dim-major-names' and `dim-minor-names', you can use
`dim-major-name' and `dim-minor-name' to change the names by one.

Many thanks to the author of
<http://www.emacswiki.org/emacs/delight.el> package, as the code of
this file is heavily based on it.

For more verbose description, see README at
<https://github.com/alezost/dim.el>.
