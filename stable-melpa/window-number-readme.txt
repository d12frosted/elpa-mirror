
Window number mode allows you to select windows by numbers.

`window-number-switch' same as `other-window' (C-x o) when windows less than three.
If have three windows (or more) showing, `window-number-switch' will
highlight window number at mode-line then prompt you input window number.

I binding `window-number-switch' on 'C-x o' to instead `other-window'.


; Installation:

Put window-number.el to your load-path.
The load-path is usually ~/elisp/.
It's set in your ~/.emacs like this:
(add-to-list 'load-path (expand-file-name "~/elisp"))

And the following to your ~/.emacs startup file.

(require 'window-number)
(window-number-mode 1)

No need more.
