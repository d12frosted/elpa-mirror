
A major mode for editing nsis files

* Installation

Put nsis-mode on your load-path, then add the following to your Emacs:

 (autoload 'nsis-mode "nsis-mode" "NSIS mode" t)

 (setq auto-mode-alist (append '(("\\.[Nn][Ss][HhIi]\\'" .
                                  nsis-mode)) auto-mode-alist))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
