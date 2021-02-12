
Add the following to your .emacs file:

    ;; defines shortcut for loccur of the current word
    (define-key global-map [(control o)] 'loccur-current)
    ;; defines shortcut for the interactive loccur command
    (define-key global-map [(control meta o)] 'loccur)
    ;; defines shortcut for the loccur of the previously found word
    (define-key global-map [(control shift o)] 'loccur-previous-match)
