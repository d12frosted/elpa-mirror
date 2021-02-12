Company-mode backend that provides completion using the YouCompleteMe
(https://github.com/Valloric/YouCompleteMe) code-completion engine.

Usage:
Add the following to your init file:
  ;; Enable company mode:
  (add-hook 'after-init-hook 'global-company-mode)

  ;; Enable company-ycm.
 (add-to-list 'company-backends 'company-ycm)
 (add-to-list 'company-begin-commands 'c-electric-colon)
 (add-to-list 'company-begin-commands 'c-electric-lt-gt)
