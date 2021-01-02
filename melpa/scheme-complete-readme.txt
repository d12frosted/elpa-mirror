; This file provides a single function, `scheme-smart-complete',
; which you can use for intelligent, context-sensitive completion
; for any Scheme implementation.  To use it just load this file and
; bind that function to a key in your preferred mode:
;
; (autoload 'scheme-smart-complete "scheme-complete" nil t)
; (eval-after-load 'scheme
;   '(define-key scheme-mode-map "\e\t" 'scheme-smart-complete))
;
; Alternately, you may want to just bind TAB to the
; `scheme-complete-or-indent' function, which indents at the start
; of a line and otherwise performs the smart completion:
;
; (eval-after-load 'scheme
;   '(define-key scheme-mode-map "\t" 'scheme-complete-or-indent))
;
;   Note: the completion uses a somewhat less common style than
;   typically found in other modes.  The first tab will complete the
;   longest prefix common to all possible completions.  The second
;   tab will show a list of those completions.  Subsequent tabs will
;   scroll that list.  You can't use the mouse to select from the
;   list - when you see what you want, just type the next one or
;   more characters in the symbol you want and hit tab again to
;   continue completing it.  Any key typed will bury the completion
;   list.  This ensures you can achieve a completion with the
;   minimal number of keystrokes without the completions window
;   lingering and taking up space.
;
; If you use eldoc-mode (included in Emacs), you can also get live
; scheme documentation with:
;
; (autoload 'scheme-get-current-symbol-info "scheme-complete" nil t)
; (add-hook 'scheme-mode-hook
;   (lambda ()
;     (make-local-variable 'eldoc-documentation-function)
;     (setq eldoc-documentation-function 'scheme-get-current-symbol-info)
;     (eldoc-mode)))
;
; You can enable slightly smarter indentation with
;
; (setq lisp-indent-function 'scheme-smart-indent-function)
;
; which basically ignores the scheme-indent-function property for
; locally overridden symbols (e.g. if you use the (let loop () ...)
; idiom it won't use the special loop indentation inside).
;
; There's a single custom variable, `scheme-default-implementation',
; which you can use to specify your preferred implementation when we
; can't infer it from the source code.
;
; That's all there is to it.
