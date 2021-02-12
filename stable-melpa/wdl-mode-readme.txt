This package provides a major mode for WDL (Workflow Definition Language).
It supports basic font-lock highlights and indentation.

Installation instructions:

  Use MELPA (easier)

    1. Install MELPA (https://melpa.org/#/getting-started)
    2. In Emacs, M-x package-list-package,
       select `wdl-mode`,
;         press `i` to mark it for installation,
       then press `x` to perform installation.

  Manual installation

  $ cd YOUR_GIT_DIRECTORY
  $ git clone https://github.com/zhanxw/wdl-mode.git

and add EITHER the following line to your .emacs file
    (require 'wdl-mode "YOUR_GIT_DIRECTORY/wdl-mode/wdl-mode.el" t)

to always load the mode, OR make it autoload by adding the following:

    (add-to-list 'auto-mode-alist '("\\.wdl\\'" . wdl-mode))
    (autoload 'wdl-mode YOUR_GIT_DIRECTORY/wdl-mode/wdl-mode.el" nil t)

and execute it (or restart emacs).

Customization:
    to customize indentaiton, add something like this to your .emacs:

    (setq wdl-indent-level 4)
