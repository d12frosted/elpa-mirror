; Initialize
(require 'plenv)
(plenv-global "perl-5.16.2") ;; initialize perl version to use

; Customizable Options:

Below are customizable option list:

`plenv-dir'
your plenv directory
default = ~/.plenv

; Utility
(guess-plenv-perl-path)    ;; return current plenv perl path. (like "plenv which perl". but, implemented by elisp.)
(guess-plenv-perl-version) ;; return current plenv perl version. (like "plenv version". but, implemented by elisp.)
