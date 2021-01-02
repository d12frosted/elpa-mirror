A suite of extensions for scheme-mode that grew out of necessity.

Chicken Scheme does play well with SLIME (See also: chicken-slime.el), but
I often find myself working on software that is slow-level and unstable
enough to make such dependence on REPL reliability rather frustrating.

Thus chicken-scheme.el was born. It does not rely on a running Scheme to
provide auto-complete support for your application. A suite of customization
variables are available to configure from which modules symbols should be
loaded and what sort of package prefixes can be expected.

Auto-complete is configured to support prefixed symbols, to allow for
full recognition of symbols in modules that may have been imported with a
prefix modifier. The `chicken-prefix` variable may be customized to declare
what characters can be used as prefix delimiters.

Calling documentation for the symbol at the current point is possible with:
chicken-show-help

Further customization is available in the chicken-scheme customization group.

Loading of the first scheme file may take some time as the Chicken Modules
are parsed for symbols on first-load. All subsequent scheme files do not
incur this load hitch. Consider running an Emacs daemon.

Installation:
Place in your load path. Add the following to your .emacs:

(require 'chicken-scheme)
(add-hook 'scheme-mode-hook 'setup-chicken-scheme)
(define-key scheme-mode-map (kbd "C-?") 'chicken-show-help)

If you don't like auto-complete, or don't want to have both R7RS and R5RS
symbols loaded, then don't add the setup-chicken-scheme hook. Instead,
the following utilities are available:

ac-source-chicken-symbols
ac-source-r5rs-symbols
ac-source-r7rs-symbols
ac-source-chicken-symbols-prefixed
chicken-show-help
chicken-fix-font-lock

Prefixed symbols are those which have been mutated after importing a library.
See the chicken-prefix custom variable for customization options.

I recommend you also add the following:

(add-hook 'scheme-mode-hook 'enable-paredit-mode)
(add-hook 'scheme-mode-hook 'rainbow-delimiters-mode-enable)

This packages plays very well with the chicken-slime package.

; Contributors:
Dan Leslie
Mao Junhua - Disk Caching
