'zlc.el' provides zsh like completion system to Emacs. That is, zlc
allows you to select candidates one-by-one by pressing `TAB'
repeatedly in minibuffer, shell-mode, and so forth. In addition,
with arrow keys, you can move around the candidates.

To enable zlc, just put the following lines in your Emacs config.

(require 'zlc)
(zlc-mode t)
