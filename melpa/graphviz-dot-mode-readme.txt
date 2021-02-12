Use this mode for editing files in the dot-language, see
https://www.graphviz.org.

To use graphviz-dot-mode, add
(use-package graphviz-dot-mode
  :ensure t)
to your ~/.emacs.el file.

The graphviz-dot-mode will do font locking, indentation, preview of
graphs and eases compilation/error location.  Font locking is
automatic, indentation uses the same commands as other modes, tab,
M-j and C-M-q.  Insertion of comments uses the same commands as
other modes, M-; .  You can compile a file using M-x compile or C-c
c, after that M-x next-error will also work.  There is support for
viewing an generated image with C-c p.
