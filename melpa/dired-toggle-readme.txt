
Description:

`dired-toggle' command could toggle to show dired buffer as a
sidebar for current directory(similar to `dired-sidebar', but more
lightweight). The sidebar buffer also enabled a minor mode named
`dired-toggle-mode', and it only contains one buffer instance,
change directories in it will not create news buffers.

Usage:

(use-package dired-toggle
  :defer t
  :bind (("<f3>" . #'dired-toggle)
         :map dired-mode-map
         ("q" . #'dired-toggle-quit)
         ([remap dired-find-file] . #'dired-toggle-find-file)
         ([remap dired-up-directory] . #'dired-toggle-up-directory)
         ("C-c C-u" . #'dired-toggle-up-directory))
  :config
  (setq dired-toggle-window-size 32)
  (setq dired-toggle-window-side 'left)

  ;; Optional, enable =visual-line-mode= for our narrow dired buffer:
  (add-hook 'dired-toggle-mode-hook
            (lambda () (interactive)
              (visual-line-mode 1)
              (setq-local visual-line-fringe-indicators '(nil right-curly-arrow))
              (setq-local word-wrap nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
