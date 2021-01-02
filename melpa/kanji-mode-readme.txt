You can add a text-mode hook to enable kanji-mode automatically
every time you enter text-mode. To do so add the following to
your .emacs file:
(add-hook 'text-mode-hook 'kanji-mode)
