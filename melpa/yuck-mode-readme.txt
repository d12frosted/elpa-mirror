A simple major mode for editing files in the yuck configuration language, used for
configuring ElKowar's Wacky Widgets (eww), usually ending in `.yuck'.

This package provides the following features:
     * Syntax hilighting
     * Indentation
     * Commenting

; Installation:

This mode requires Emacs-25.1 or higher.
Put this file into `load-path' and the following into ~/.emacs
     (autoload 'yuck-mode "yuck-mode" nil t)
