
Provides a major-mode for editing Trading View Pine script files.

Add the following to your .emacs to install:

(require 'pine-script-mode)
(add-to-list 'auto-mode-alist '("\\.pine$" . pine-script-mode))

or:

(use-package pine-script-mode
  :ensure t
  :mode ("\\.pine\\'"))
