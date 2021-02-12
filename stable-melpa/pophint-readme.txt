
This extension provides navigation like the Vimperator Hint Mode of Firefox.
The interface has the following flow.
 1. pop-up tip about the matched point for some action which user want.
 2. do some action for the user selecting.

For more infomation, see <https://github.com/aki2o/emacs-pophint/blob/master/README.md>

; Dependencies:

- yaxception.el ( see <https://github.com/aki2o/yaxception> )
- log4e.el ( see <https://github.com/aki2o/log4e> )

; Installation:

Put this to your load-path.
And put the following lines in your .emacs or site-start.el file.

(require 'pophint)

; Configuration:

;; Key Binding
(define-key global-map (kbd "C-;") 'pophint:do-flexibly)
(define-key global-map (kbd "C-+") 'pophint:do)
(define-key global-map (kbd "M-;") 'pophint:redo)
(define-key global-map (kbd "C-M-;") 'pophint:do-interactively)

For more information, see Configuration section in <https://github.com/aki2o/emacs-pophint/wiki>

; Customization:

[EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "pophint:" :docstring t)
`pophint:popup-chars'
Characters for pop-up hint.
`pophint:select-source-chars'
Characters for selecting source.
`pophint:select-source-method'
Method to select source.
`pophint:switch-source-char'
Character for switching source used to pop-up.
`pophint:switch-source-reverse-char'
Character for switching source used to pop-up in reverse.
`pophint:switch-source-delay'
Second for delay to switch source used to pop-up.
`pophint:switch-source-selectors'
List of dedicated selector for source.
`pophint:switch-direction-char'
Character for switching direction of pop-up.
`pophint:switch-direction-reverse-char'
Character for switching direction of pop-up in reverse.
`pophint:switch-window-char'
Character for switching window of pop-up.
`pophint:popup-max-tips'
Maximum counts of pop-up hint.
`pophint:default-require-length'
Default minimum length of matched text for pop-up.
`pophint:switch-direction-p'
Whether switch direction of pop-up.
`pophint:do-allwindow-p'
Whether do pop-up at all windows.
`pophint:use-pos-tip'
Whether use pos-tip.el to show prompt.

 *** END auto-documentation
