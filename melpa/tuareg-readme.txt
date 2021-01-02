Description:
Tuareg helps editing OCaml code, to highlight important parts of
the code, to run an OCaml REPL, and to run the OCaml debugger
within Emacs.

Installation:
If you have permissions to the local `site-lisp' directory, you
only have to copy `tuareg.el', `ocamldebug.el'
and `tuareg-site-file.el'.  Otherwise, copy the previous files
to a local directory and add the following line to your `.emacs':

(add-to-list 'load-path "DIR")
