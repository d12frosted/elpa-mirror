Add this package to your load path and add an autoload for `emr-show-refactor-menu`.
Bind the `emr-show-refactor-menu` command to something convenient.

(autoload 'emr-show-refactor-menu "emr")
(define-key prog-mode-map (kbd "M-RET") 'emr-show-refactor-menu)
(eval-after-load "emr" '(emr-initialize))

See README.md for more information.
