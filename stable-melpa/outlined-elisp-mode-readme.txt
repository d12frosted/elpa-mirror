This is an outline-minor-mode settings for emacs lisp. For example,
"outlined" emacs lisp code look like this.

  ;; * general settings
  ;; ** show-paren-mode

  (show-paren-mode 1)
  (setq show-paren-delay 0)

  ;; ** cua-mode

  (cua-mode t)
  (setq cua-enable-cua-keys nil)

  ;; * emacs-lisp-mode settings

  (add-hook 'emacs-lisp-mode-hook 'outlined-elisp-find-file-hook)

To install, put code like

  (require 'outlined-elisp-mode)

in your .emacs file. You can activate outlined-elisp-mode with
"M-x outlined-elisp-mode" command. Or, if you put code like

  (add-hook 'emacs-lisp-mode-hook 'outlined-elisp-find-file-hook)

in your .emacs file, outlined-elisp-mode is automatically activated
when one of the first 300 lines seem to be heading of outlined-elisp.
You can also change the trigger, and the range of search.

  (setq outlined-elisp-trigger-pattern ";; \\+\\+ outlined-elisp \\+\\+")
  (setq outlined-elisp-trigger-limit 3)
