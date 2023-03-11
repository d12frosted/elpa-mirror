A major mode for the Chaos programming language.

;; Installation

You can use built-in package manager (package.el) or do everything by your hands.

;;; Using package manager

Add the following to your Emacs config file

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

Then use `M-x package-install RET chaos-mode RET` to install the mode.
Use `M-x chaos-mode` to change your current mode.

;;; Manual

Download the mode to your local directory.  You can do it through `git clone` command:

git clone git://github.com/thechampagne/chaos-mode.git

Then add path to chaos-mode to load-path list — add the following to your Emacs config file

(add-to-list 'load-path
	     "/path/to/chaos-mode/")
(require 'chaos-mode)

Use `M-x chaos-mode` to change your current mode.
