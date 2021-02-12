Provide font-lock for minizinc(http://www.minizinc.org/) code

Note: pretty-rendering is shamelessly stolen from haskell-mode.

Here are some example of configuration:

; Installation:

You can either manually install minizinc-mode or automatically
install from melpa. Add the following line into your ~/.emacs
file or any your emacs start file to install it from the melpa.

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))
(unless package-archive-contents (package-refresh-contents))
(package-initialize)

install minizinc-mode

M-x package-install
minizinc-mode

Add the following lines to your emacs after installation.
(require 'minizinc-mode)
(add-to-list 'auto-mode-alist '("\\.mzn\\'" . minizinc-mode))
