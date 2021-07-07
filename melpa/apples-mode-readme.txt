This program provides a major mode for AppleScript.

[INSTALL]

Put files in your load-path and add the following to your init file.

   (autoload 'apples-mode "apples-mode" "Happy AppleScripting!" t)
   (autoload 'apples-open-scratch "apples-mode" "Open scratch buffer for AppleScript." t)
   (add-to-list 'auto-mode-alist '("\\.\\(applescri\\|sc\\)pt\\'" . apples-mode))
or
   (require 'apples-mode)
   (add-to-list 'auto-mode-alist '("\\.\\(applescri\\|sc\\)pt\\'" . apples-mode))

After that you should byte-compile apples-mode.el.

   M-x byte-compile-file RET /path/to/apples-mode.el RET

During the byte-compilation, you may get some warnings, but you should
ignore them.

[FEATURES]

Commands for the execution have the prefix `apples-run-'. You can see
the other features via menu.

[CONFIGURATION]

You can access to the customize group via menu or using the command
`apples-customize-group'.

Here is my configuration.

(global-set-key (kbd "C-c a") 'apples-open-scratch)
(setq apples-underline-syntax-class "w")
(setq backward-delete-char-untabify-method 'all)
(setq imenu-auto-rescan t)
(defun my-apples-mode-hook ()
  (local-set-key (kbd "<S-tab>") 'apples-toggle-indent)
  (local-set-key (kbd "RET") 'newline-and-indent)
  (local-set-key (kbd "DEL") 'backward-delete-char-untabify)
  (setq imenu-case-fold-search nil)
  (imenu-add-menubar-index))
(add-hook 'apples-mode-hook 'my-apples-mode-hook)
(eval-after-load "auto-complete"
  '(progn
     (add-to-list 'ac-modes 'apples-mode)
     (add-hook 'apples-mode-hook
               (lambda ()
                 (add-to-list 'ac-sources 'ac-source-applescript t)))))
