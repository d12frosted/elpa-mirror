Emacs Mode for Egison

Please put it in your load-path of Emacs. Then, add the following
lines in your .emacs.

  (autoload 'egison-mode "egison-mode" "Major mode for editing Egison code." t)
  (setq auto-mode-alist (cons `("\\.egi$" . egison-mode) auto-mode-alist))
