
This file provides `koopa-mode', a major mode for Microsoft PowerShell

The name is derived from the Paper Mario series, a spin-off of the
Super Mario franchise, in which the Koopas have the move "Power Shell".

Usage:

    To manually install `koopa-mode', add the following to your init.el:

    (add-to-list 'load-path "/path/to/koopa-mode")
    (require 'koopa-mode)


    To associate PowerShell files with `koopa-mode', add the following
    to your init.el:

    (add-to-list 'auto-mode-alist '("\\.ps1\\'" . koopa-mode))
