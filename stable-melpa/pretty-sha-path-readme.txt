This package provides minor-mode for prettifying Guix/Nix store
paths, i.e. after enabling `pretty-sha-path-mode',
'/gnu/store/72f54nfp6g1hz873w8z3gfcah0h4nl9p-foo-0.1' paths will be
replaced with '/gnu/store/…-foo-0.1' paths in the current buffer.
There is also `global-pretty-sha-path-mode' for global prettifying.

To install, add the following to your emacs init file:

  (add-to-list 'load-path "/path/to/pretty-sha-path")
  (autoload 'pretty-sha-path-mode "pretty-sha-path" nil t)
  (autoload 'global-pretty-sha-path-mode "pretty-sha-path" nil t)

If you want to enable/disable composition after "M-x font-lock-mode",
use the following setting:

  (setq font-lock-extra-managed-props
        (cons 'composition font-lock-extra-managed-props))

Credits:

Thanks to Ludovic Courtès for the idea of this package.

Thanks to the authors of `prettify-symbols-mode' (part of Emacs 24.4)
and "pretty-symbols.el" <http://github.com/drothlis/pretty-symbols>
for the code.  It helped to write this package.
