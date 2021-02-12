Basic setup:

Ensure that the installation directory is in your `load-path' (it
is done for you if installing from melpa), and add the following
line to your Emacs init file:

    (require 'magma-mode)

Additionally, if you want to load the mode automatically with some
file extensions, you can add the following to your init file:

    (setq auto-mode-alist
    (append '(("\\.mgm$\\|\\.m$" . magma-mode))
            auto-mode-alist))

Some features are available in `magma-extra.el'.  They are disabled
because they are more intrusive than the others.  Feel free to
browse the customize interface to enable some of them!

Some support for `hs-minor-mode', `imenu' and `smart-parens' is
also provided.

If you are using `yasnippet', you can enable some snippets for
`magma-mode' by adding the following to your init file.

    (require 'magma-snippets)

At the moment, these snippets include basic syntactic constructs
(if, while, for, etc.) and load (with file name completion).  More
will be added in the future.

The complete documentation is available on
https://github.com/ThibautVerron/magma-mode

Bug reports and suggestions are welcome, please use the github
issue tracker.
