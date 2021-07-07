
Add this to your .emacs:

(autoload 'actionscript-mode "actionscript-mode" "Major mode for actionscript." t)
(add-to-list 'auto-mode-alist '("\\.as\\'" . actionscript-mode))

------------------
; TODO

Imenu (imenu-generic-expression or imenu-create-index-function)

------------------

; Changes in 7.2

Updated comments.

See https://github.com/austinhaas/actionscript-mode for info on
future changes.
