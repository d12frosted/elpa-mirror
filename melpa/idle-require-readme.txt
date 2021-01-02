
Add the following to your .emacs file:
(require 'idle-require)
(setq idle-require-symbols '(cedet nxml-mode)) ;; <- Specify packages here.
(idle-require 'cedet) ;; <- Or like this.
(idle-require-mode 1) ;; starts loading

As soon as Emacs goes idle for `idle-require-idle-delay' seconds,
`idle-require-mode' will start loading the files, symbols or functions in
`idle-require-symbols'.  If that is nil, all autoload functions will be
loaded, one at a time.

Use `idle-require-load-break' to give your CPU a break between each load.
Otherwise, you might create 100% CPU load on your system.
