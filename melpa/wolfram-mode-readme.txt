This provides basic editing features for Wolfram Language
(http://reference.wolfram.com/language/), based on `math++.el'
(http://chasen.org/~daiti-m/dist/math++.el).

You should add the followings to `~/.emacs.d/init.el'.

 (autoload 'wolfram-mode "wolfram-mode" nil t)
 (autoload 'run-wolfram "wolfram-mode" nil t)
 (setq wolfram-program "/Applications/Mathematica.app/Contents/MacOS/MathKernel")
 (add-to-list 'auto-mode-alist '("\\.m$" . wolfram-mode))
 (setq wolfram-path "directory-in-Mathematica-$Path") ;; e.g. on Linux ~/.Mathematica/Applications

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

Mathematica is (C) Copyright 1988-2013 Wolfram Research, Inc.

Protected by copyright law and international treaties.

Unauthorized reproduction or distribution subject to severe civil
and criminal penalties.

Mathematica is a registered trademark of Wolfram Research.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TODO
- wolfram-imenu-generic-expression
- sending useful commands to comint buffer.
- support for parsing string
- support for top level "\n" parsing
