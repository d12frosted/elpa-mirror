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

;; Usage:

Edit  your config  file as  usual.  Use  `TAB' for  completion of
values and variables.  Use `C-c C-t'  to toggle flags (like true to
false). Use `C-c C-=' on a region to automatically align on the `=`
character.  Use `C-c  C-/' to breakup a region with  long lines into
shorter ones  using backslash notation.  Use  `C-return' to visit
an included file  or (when not on  a link) insert a  new line below
the current one, indent and move point there.  Use `C-k' to delete
lines, including continuation lines or  whole blocks.  Use `C-c C-j'
to  jump to  a block  definition (same  as using  `imenu' with  the
mouse).

;; Customize:

You can customize the mode with:

     M-x customize-group RET config-general-mode RET

You can also use hooks to config-general  mode as a way to modify or enhance
its behavior.  The following hooks are available:

    config-general-mode-hook

For example:

    (add-hook 'config-general-mode-hook 'electric-indent-mode)
