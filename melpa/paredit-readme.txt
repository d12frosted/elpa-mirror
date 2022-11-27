Paredit keeps your parentheses balanced while editing.  Paredit Mode
binds keys like `(', `)', and `"' to insert or delete parentheses
and string quotes in balanced pairs as you're editing without
getting in your way, augments editing keys like `C-k' to handle
balanced expressions, and provides advanced commands for editing
balanced expressions like splicing and joining while judiciously
keeping the code you're working on indented.

; Install paredit by placing `paredit.el' in `/path/to/elisp', a
; directory of your choice, and adding to your .emacs file:
;
;   (add-to-list 'load-path "/path/to/elisp")
;   (autoload 'enable-paredit-mode "paredit"
;     "Turn on pseudo-structural editing of Lisp code."
;     t)
;
; Start Paredit Mode on the fly with `M-x enable-paredit-mode RET',
; or always enable it in a major mode `M' (e.g., `lisp') with:
;
;   (add-hook 'M-mode-hook 'enable-paredit-mode)
;
; Customize paredit using `eval-after-load':
;
;   (eval-after-load 'paredit
;     '(progn
;        (define-key paredit-mode-map (kbd "ESC M-A-C-s-)")
;          'paredit-dwim)))
;
; Send questions, bug reports, comments, feature suggestions, &c.,
; via email to the author's surname at paredit.org.
;
; Paredit should run in GNU Emacs 21 or later and XEmacs 21.5.28 or
; later.

; The paredit minor mode, Paredit Mode, binds common character keys,
; such as `(', `)', `"', and `\', to commands that carefully insert
; S-expression structures in the buffer:
;
;   ( inserts `()', leaving the point in the middle;
;   ) moves the point over the next closing delimiter;
;   " inserts `""' if outside a string, or inserts an escaped
;      double-quote if in the middle of a string, or moves over the
;      closing double-quote if at the end of a string; and
;   \ prompts for the character to escape, to avoid inserting lone
;      backslashes that may break structure.
;
; In comments, these keys insert themselves.  If necessary, you can
; insert these characters literally outside comments by pressing
; `C-q' before these keys, in case a mistake has broken the
; structure.
;
; These key bindings are designed so that when typing new code in
; Paredit Mode, you can generally type exactly the same sequence of
; keys you would have typed without Paredit Mode.
;
; Paredit Mode also binds common editing keys, such as `DEL', `C-d',
; and `C-k', to commands that respect S-expression structures in the
