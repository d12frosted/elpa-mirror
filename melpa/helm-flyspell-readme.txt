
To use, just put your cursor on or after the misspelled word and
run helm-flyspell-correct. You can of course bind it to a key as
well by adding this to your `~/.emacs` file:
(define-key flyspell-mode-map (kbd "C-;") 'helm-flyspell-correct)

When invoked, it will show the list of corrections suggested by
Flyspell and options to save the word in your personal dictionary
or accept it in the buffer or the session. If a pattern is typed,
it will be used to filter the corrections. It can also be directly
saved to the dictionary, even if it is different from the initial
word. The new typed word will also replace the word typed in the
buffer.
