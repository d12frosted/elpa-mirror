Evaluate expressions in a separate Emacs process:

,---
| ;;; `with-emacs'
|
| ;; Evaluate expressions in a separate Emacs.
| (with-emacs ...)
|
| ;; Specify the version of Emacs and enable lexical binding
| (with-emacs :path "/path/to/{version}/emacs" :lexical t ...)
|
|
| ;;; `with-emacs-server'
|
| ;; Evaluate expressions in server "name" or signal an error if no such server.
| (with-emacs-server "name" ...)
|
| ;; Evaluate expressions in server "name" and start a server if necessary.
| (with-emacs-server "name" :ensure t ...)
| (with-emacs-server "name" :ensure "/path/to/{version}/emacs" ...)
|
| ;; Kill server after 100 minutes of idle
| (with-emacs-server "name" :ensure t :timeout 100 ...)
|
| ;; Set default timeout for every new server:
| (setq with-emacs-server-timeout 100)
| (with-emacs-server "name" :ensure t ...)
|
| ;; Disable default timeout temporary:
| (with-emacs-server "name" :ensure t :timeout nil ...)
|
|
| ;;; `with-emacs-define-partially-applied'
|
| ;; Generate functions with partial parameters applied
| (with-emacs-define-partially-applied
|  (t      nil t)
|  (24.3   "/path/to/emacs-24.3")
|  (24.4-t "/path/to/emacs-24.4" t))
| ;; =>
| ;; with-emacs-t       ;; applied `:lexical t`
| ;; with-emacs-24.3    ;; applied `:path "/path/to/emacs-24.3"'
| ;; with-emacs-24.4-t  ;; applied `:path "/path/to/emacs-24.3" :lexical t'
`---

See README for more information.
