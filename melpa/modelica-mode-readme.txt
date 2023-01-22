This package provides a fundamental Modelica mode.
It covers:
 - show / hide of annotations
     C-c C-s  show annotation of current statement
     C-c C-h  hide annotation of current statement
     C-c M-s  show all annotations
     C-c M-h  hide all annotations

 - indentation of lines, e.g.
     TAB      indent current line
     C-M-\    indent current region
     C-j      indent current line, create a new line, indent it
              (like TAB ENTER TAB)

 - automatic insertion of end statements
     C-c C-e  search backwards for the last unended begin of a code block,
              insert the according end-statement

 - move commands which know about statements and statement blocks
     M-e      move to next beginning of a statement
     M-a      move to previous beginning of a statement
     M-n      move to next beginning of a statement block
     M-p      move to previous beginning of a statement block
     C-M-a    move to beginning of current statement block
     C-M-e    move to end of current statement block

 - commands for writing comments treat documentation strings as well
     M-;      insert a comment for current statement (standard Emacs)
     M-"      insert a documentation string for current statement
     M-j      continue comment or documentation string on next line

 - syntax highlighting using font-lock-mode

Current limitations:
 - conditional expessions are only supported on right hand sides of
   equations; otherwise simple expressions are assumed

Installation:
(1) Put the file
       modelica-mode.el
    to an Emacs Lisp directory, e.g. ~/elisp

(2) Add the following lines to your ~/.emacs file

 (add-to-list 'load-path "~/elisp")
 (autoload 'modelica-mode "modelica-mode" "Modelica Editing Mode" t)
 (add-to-list 'auto-mode-alist '("\\.mo\\'" . modelica-mode))

(3) Activate the mode by loading a file with the extension ".mo"
    or by invoking
     M-x modelica-mode

(4) Optionally byte-compile the Lisp code

(5) Please send comments and suggestions to
    Ruediger Franke <rfranke@users.sourceforge.net>
