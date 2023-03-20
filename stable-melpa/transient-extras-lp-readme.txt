This package provides a simple transient menu with common options for `lp'.

Typical usage:

(require 'transient-extras-lp)

(with-eval-after-load 'dired
  (define-key
    dired-mode-map
    (kbd "C-c C-p") #'transient-extras-lp-menu))
(with-eval-after-load 'pdf-tools
  (define-key
    pdf-misc-minor-mode-map
    (kbd "C-c C-p") #'transient-extras-lp-menu))

Or simply call `transient-extras-lp-menu' to print the current buffer or the
selected files is selected in `dired'.
