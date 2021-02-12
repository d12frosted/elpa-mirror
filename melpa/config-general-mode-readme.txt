;; Introduction:

[Config::General](http://search.cpan.org/dist/Config-General/) is a
Perl   module  for   parsing  config   files  with   some  enhanced
features.  `config-general-mode' makes it easier to edit such config
files with Emacs.

It is based on `conf-mode' with the following features:

- good syntax highlighting for config files
- imenu support for <blocks>
- automatic indenting
- jump to include file with `C-return'

;; Installation:

To use, save config-general-mode.el to a directory in your load-path.

Add something like this to your config:

    (require 'config-general-mode)
    (add-to-list 'auto-mode-alist '("\\.conf$" . config-general-mode))

or load it manually, when needed:

    M-x config-general-mode

You can also enable it with  a buffer-local variable by adding this as
the first line of a config file:

    # -*-config-general-*-
