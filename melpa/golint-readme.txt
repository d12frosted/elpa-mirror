To install golint, add the following lines to your .emacs file:
  (add-to-list 'load-path "PATH CONTAINING golint.el" t)
  (require 'golint)

After this, type M-x golint on Go source code.

Usage:
  C-x `
    Jump directly to the line in your code which caused the first message.

  For more usage, see Compilation-Mode:
    http://www.gnu.org/software/emacs/manual/html_node/emacs/Compilation-Mode.html
