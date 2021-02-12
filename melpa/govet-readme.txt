To install govet.el, add the following lines to your .emacs file:
  (add-to-list 'load-path "PATH CONTAINING govet.el" t)
  (require 'govet)

After this, type M-x govet on Go source code.

Usage:
  C-x `
    Jump directly to the line in your code which caused the first message.

  For more usage, see Compilation-Mode:
    http://www.gnu.org/software/emacs/manual/html_node/emacs/Compilation-Mode.html

;; THIS IS BASICALLY ENTIRELY COPIED AND SLIGHTLY MODIFIED FROM THE GOLINT EMACS MODE
;; https://github.com/golang/lint/tree/master/misc/emacs
