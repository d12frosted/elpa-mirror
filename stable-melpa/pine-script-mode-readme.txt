
Provides a comprehensive major mode for editing TradingView Pine Script v6 and older files.
It correctly highlights variables, constants, functions, methods, types,
keywords, and annotations based on the v6 syntax.

Add the following to your .emacs to install:

Pine script mode automatically loads for ".pine", ".pinescript" files

(require 'pine-script-mode)

or:

(use-package pine-script-mode :ensure t)

or:

(straight-use-package '(pine-script-mode :type git :host github :repo "EricCrosson/pine-script-mode"))
