; The currently released version of snoopy-mode is available at
;   <https://raw.githubusercontent.com/anmonteiro/snoopy-mode/v0.2.0/snoopy.el>
;
; The latest version of snoopy-mode is available at
;   <https://raw.githubusercontent.com/anmonteiro/snoopy-mode/master/snoopy.el>
;
; The Git repository for snoopy-mode is available at
;   <https://github.com/anmonteiro/snoopy-mode>
;
; Release notes are available at
;   <https://github.com/anmonteiro/snoopy-mode/blob/master/CHANGELOG.md>

; Install snoopy-mode by placing `snoopy.el' in `/path/to/elisp', a
; directory of your choice, and adding to your .emacs file:
;
;   (add-to-list 'load-path "/path/to/elisp")
;   (autoload 'snoopy-mode "snoopy"
;     "Turn on unshifted mode for characters in the keyboard number row."
;     t)
;
; Start Snoopy Mode on the fly with `M-x snoopy-mode RET',
; or always enable it in a major mode `M' (e.g., `lisp') with:
;
;   (add-hook 'M-mode-hook 'snoopy-mode)
;
; Customize snoopy-mode using `eval-after-load':
;
;   (eval-after-load 'snoopy
;     '(progn
;        (define-key snoopy-mode-map (kbd "1")
;          (lambda () (insert-char \! 1)))))
;
; Send questions, bug reports, comments, feature suggestions, &c.,
; via email to the author.
;

; The snoopy minor mode, Snoopy Mode, binds keys in the keyboard's number
; row, such as `1', `2', `3', etc, to commands that insert their shifted
; versions, e.g. `!', `@' and `#', respectively.
;
