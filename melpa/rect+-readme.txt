rect+.el provides extensions to rect.el

## Install:

Put this file into load-path'ed directory, and byte compile it if
desired. And put the following expression into your ~/.emacs.

    (require 'rect+)
    (define-key ctl-x-r-map "C" 'rectplus-copy-rectangle)
    (define-key ctl-x-r-map "N" 'rectplus-insert-number-rectangle)
    (define-key ctl-x-r-map "\M-c" 'rectplus-create-rectangle-by-regexp)
    (define-key ctl-x-r-map "A" 'rectplus-append-rectangle-to-eol)
    (define-key ctl-x-r-map "R" 'rectplus-kill-ring-to-rectangle)
    (define-key ctl-x-r-map "K" 'rectplus-rectangle-to-kill-ring)
    (define-key ctl-x-r-map "\M-l" 'rectplus-downcase-rectangle)
    (define-key ctl-x-r-map "\M-u" 'rectplus-upcase-rectangle)

```********** Emacs 22 or earlier **********```

    (require 'rect+)
    (global-set-key "\C-xrC" 'rectplus-copy-rectangle)
    (global-set-key "\C-xrN" 'rectplus-insert-number-rectangle)
    (global-set-key "\C-xr\M-c" 'rectplus-create-rectangle-by-regexp)
    (global-set-key "\C-xrA" 'rectplus-append-rectangle-to-eol)
    (global-set-key "\C-xrR" 'rectplus-kill-ring-to-rectangle)
    (global-set-key "\C-xrK" 'rectplus-rectangle-to-kill-ring)
    (global-set-key "\C-xr\M-l" 'rectplus-downcase-rectangle)
    (global-set-key "\C-xr\M-u" 'rectplus-upcase-rectangle)
