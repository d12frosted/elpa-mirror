Instant GitHub-flavored Markdown/Org preview using a grip subprocess.

Install:
From melpa, `M-x package-install RET grip-mode RET`.
;; Make a keybinding: `C-c C-c g'
(define-key markdown-mode-command-map (kbd "g") #'grip-mode)
;; or start grip when opening a markdown file
(add-hook 'markdown-mode-hook #'grip-mode)
or
(use-package grip-mode
  :ensure t
  :bind (:map markdown-mode-command-map
         ("g" . grip-mode)))
Run `M-x grip-mode` to preview the markdown file with the default browser.
