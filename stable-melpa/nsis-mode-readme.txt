
A major mode for editing nsis files

* Installation

Put this `nsis-mode' the load path, then add the following to your Emacs:

 (autoload 'nsis-mode "nsis-mode" "NSIS mode" t)

 (setq auto-mode-alist (append '(("\\.\\([Nn][Ss][Ii]\\)$" .
                                  nsis-mode)) auto-mode-alist))

 (setq auto-mode-alist (append '(("\\.\\([Nn][Ss][Hh]\\)$" .
                                  nsis-mode)) auto-mode-alist))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
