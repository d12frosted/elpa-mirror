Find JavaScript variable definitions using tree-sitter.

This package provides `js-ts-defs-jump-to-definition' which jumps to the
definition of the JavaScript identifier at point.  It uses tree-sitter to
parse JavaScript code and build a scope structure to accurately resolve
variable definitions.

These functions are designed to be used inside `js-ts-mode'.

Prerequisites:

1. Install JavaScript tree-sitter grammar:
   (add-to-list
    'treesit-language-source-alist
    '(javascript "https://github.com/tree-sitter/tree-sitter-javascript" "v0.20.1"))
   M-x treesit-install-language-grammar RET javascript RET

2. Enable `js-ts-mode' for JavaScript files:
   (add-to-list 'major-mode-remap-alist '(javascript-mode . js-ts-mode))

Usage:

  (add-hook 'js-ts-mode-hook
            (lambda ()
              (local-set-key (kbd "M-.") #'js-ts-defs-jump-to-definition)))

This gives you:
  M-.   Jump to definition
  M-,   Jump back
