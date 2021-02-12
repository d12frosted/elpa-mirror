
Correct the misspelled word with `flyspell' in popup menu.

Usage:

Call `flyspell-popup-correct' to correct misspelled word at point with a
Popup Menu. You might want to bind it to a key, for example:

  (define-key flyspell-mode-map (kbd "C-;") #'flyspell-popup-correct)

You can also enable `flyspell-popup-auto-correct-mode' to display that Popup
Menu automatically with a delay (default 1.6 seconds):

  (add-hook 'flyspell-mode-hook #'flyspell-popup-auto-correct-mode)
