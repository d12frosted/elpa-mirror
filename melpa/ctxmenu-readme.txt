
This extension provides a context menu like right-click.

For more infomation, see <https://github.com/aki2o/emacs-ctxmenu/blob/master/README.md>

; Dependencies:

- popup.el ( bundled auto-complete.el. see <https://github.com/auto-complete/auto-complete> )
- yaxception.el ( see <https://github.com/aki2o/yaxception> )
- log4e.el ( see <https://github.com/aki2o/log4e> )

; Installation:

Put this to your load-path.
And put the following lines in your .emacs or site-start.el file.

(require 'ctxmenu)

; Configuration:

;; Key Binding
(define-key global-map (kbd "M-@") 'ctxmenu:show)

;; Also, you need to define the contents of context menu into `ctxmenu:global-sources'/`ctxmenu:sources'.
;; `ctxmenu:add-source' is a helper function for it.
;; Moreover I have a basic configuration, see <https://github.com/aki2o/emacs-ctxmenu/blob/master/README.md>

; Customization:

[EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "ctxmenu:[^:]" :docstring t)
`ctxmenu:default-menu-list-function'
Function for building the menu of source.
`ctxmenu:default-sort-menu-function'
Function for the menu sort of source.
`ctxmenu:show-at-pointed'
Whether show a context menu at the point of cursol.
`ctxmenu:use-isearch'
Whether use isearch on selecting menu.
`ctxmenu:use-quick-help'
Whether use quick help.
`ctxmenu:quick-help-delay'
Delay to show quick help.
`ctxmenu:warning-menu-number-threshold'
Number as the threshold whether show the warning about the slowness of Emacs.

 *** END auto-documentation
