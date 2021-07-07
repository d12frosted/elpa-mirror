This program provides a major mode for AppleScript.

[INSTALL]

Put files in your load-path and add the following to your init file.

   (autoload 'apples-mode "apples-mode" "Happy AppleScripting!" t)
   (autoload 'apples-open-scratch "apples-mode" "Open scratch buffer for AppleScript." t)
   (add-to-list 'auto-mode-alist '("\\.\\(applescri\\|sc\\)pt\\'" . apples-mode))
or
   (require 'apples-mode)
   (add-to-list 'auto-mode-alist '("\\.\\(applescri\\|sc\\)pt\\'" . apples-mode))

After that you should byte-compile apples-mode.el.

   M-x byte-compile-file RET /path/to/apples-mode.el RET

During the byte-compilation, you may get some warnings, but you should
ignore them.

[FEATURES]

Commands for the execution have the prefix `apples-run-'. You can see
the other features via menu.

[CONFIGURATION]

You can access to the customize group via menu or using the command
`apples-customize-group'.
