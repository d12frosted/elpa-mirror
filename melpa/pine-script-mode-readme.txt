
Provides a major-mode for editing Trading View Pine script files.

Add the following to your .emacs to install:

Pine script mode automatically loads for ".pine" files

(require 'pine-script-mode)

or:

(use-package pine-script-mode
  :ensure t)

or:

(straight-use-package
  '(pine-script-mode :type git :host github :repo "EricCrosson/pine-script-mode"))
