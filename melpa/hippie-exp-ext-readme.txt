
Extension of hippie-expand.

I created this program to let `hippie-expand' expand only unibyte
chars and expand long symbols.

M-x try-expand-dabbrev-limited-chars
  - expand dabbrev substring when input begins from `-' or `_'.
  - otherwise expand dabbrev
  - symbols expanded this command only contain 0-9a-zA-Z\?!_-,
    which is controlled to set `he-dabbrev-chars'

M-x hippie-expand-file-name
  - complete file name at point


Example:

-ex [M-x hippie-expand-dabbrev-limited-chars] -> hippie-expand

; Installation:

Put hippie-exp-ext.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name "~/elisp"))

And the following to your ~/.emacs startup file.

(require 'hippie-exp-ext)
(global-set-key (kbd "C-@") 'hippie-expand-dabbrev-limited-chars)
(global-set-key (kbd "M-/") 'hippie-expand-file-name)

No need more.
