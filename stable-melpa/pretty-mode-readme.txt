
Minor mode for redisplaying parts of the buffer as pretty symbols
originally modified from Trent Buck's version at http://paste.lisp.org/display/42335,2/raw
Also includes code from `sml-mode'
See also http://www.emacswiki.org/cgi-bin/wiki/PrettyLambda

to install:

(require 'pretty-mode)
and
(global-pretty-mode 1)
or
(add-hook 'my-pretty-language-hook 'turn-on-pretty-mode)
