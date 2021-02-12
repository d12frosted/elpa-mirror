
To install, add the following to your .emacs file:
(autoload 'kill-ring-search "kill-ring-search"
 "Search the kill ring in the minibuffer."
 (interactive))
(global-set-key "\M-\C-y" 'kill-ring-search)

Just call kill-ring-search and enter your search.
M-y and C-y work as usual.  You can also use C-r like in a shell.
C-v, M-v, C-n and C-p will scroll the view.
