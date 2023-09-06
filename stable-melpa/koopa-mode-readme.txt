
This file provides `koopa-mode', a major mode for Microsoft PowerShell

The name is derived from the Paper Mario series, a spin-off of the
Super Mario franchise, in which the Koopas have a move called "Power Shell"

Usage:


    Installing via MELPA

         To install `koopa-mode' via MELPA, use the following command:

         M-x package-install RET koopa-mode RET

         Then add the following to your init.el:

         (require 'koopa-mode)


    Installing Manually

         To install `koopa-mode' manually, add the following to your init.el:

         (add-to-list 'load-path "/path/to/koopa-mode")
         (require 'koopa-mode)


    Fila Associations

         To associate PowerShell files with `koopa-mode', add the
         following to your init.el:

         (add-to-list 'auto-mode-alist '("\\.ps1\\'" . koopa-mode))
