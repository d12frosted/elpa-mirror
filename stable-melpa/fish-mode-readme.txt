A very basic version of major mode for fish shell scripts.
Current features:

 - keyword highlight
 - basic indent
 - comment detection
 - run fish_indent for indention

 To run fish_indent before save, add the following to init script:
 (add-hook 'fish-mode-hook (lambda ()
                             (add-hook 'before-save-hook 'fish_indent-before-save)))

 Configuration:
 fish-indent-offset: customize the indentation
