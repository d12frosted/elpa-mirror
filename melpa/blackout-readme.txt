Blackout is a package which allows you to hide or customize the
display of major and minor modes in the mode line. It can replace
diminish.el, delight.el, and dim.el.

Hide a minor mode:

    (blackout 'auto-fill-mode)

Change the display of a minor mode (note the leading space; this is
needed if you want there to be a space between this mode lighter and
the previous one):

    (blackout 'auto-fill-mode " Auto-Fill")

Change the display of a major mode:

    (blackout 'emacs-lisp-mode "Elisp")

Operate on a mode which hasn't yet been loaded:

    (with-eval-after-load 'ivy
      (blackout 'ivy-mode))

Usage with use-package:

    (use-package foo
      :blackout t)

    (use-package foo
      :blackout " Foo")

    (use-package quux
      :blackout ((foo-mode . " Foo")
                 (bar-mode . " Bar")))

Please see https://github.com/raxod502/blackout for more information.
