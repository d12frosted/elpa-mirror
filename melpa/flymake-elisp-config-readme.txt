; flymake-elisp-config: Setup `load-path' for flymake on Emacs Lisp mode
Default `load-path' for flymake on Emacs Lisp mode can be set through
`elisp-flymake-byte-compile-load-path', but it is just a global variable.
When you are editing init.el, flymake should use all the `load-path'.
When you are editing your package, flymake should use paths provided by cask
or keg.

This package provides three features:
- Customizable variable `flymake-elisp-config-load-path-getter',
  which is a FUNCTION return `load-path' for flymake.
- Automatic setting of `load-path' for flymake by
  `flymake-elisp-config-auto-mode'.
- Manual setting of it by `flymake-elisp-config-as-*'.

; How to Use?
Just write in init.el:

  ;; Make `load-path' for flymake customizable through
  ;; `flymake-elisp-config-load-path-getter'.
  (flymake-elisp-config-global-mode)
  ;; Automatically set `load-path' for flymake.
  (flymake-elisp-config-auto-mode)

If automatical setting is wrong, you can use `flymake-elisp-config-as-*'
commands to change `load-path' for flymake manually.
- `flymake-elisp-config-as-config' : Emacs configuration file such as init.el
- `flymake-elisp-config-as-keg' : Emacs Lisp project managed by `keg'.
- `flymake-elisp-config-as-cask' : Emacs Lisp project managed by `cask'.
- `flymake-elisp-config-as-default' : Default Emacs Lisp file.
  It uses same `load-path' as default flymake.
