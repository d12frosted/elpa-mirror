Provides functions that make it easy to work with the Kibit
Leiningen plugin for detecting and improving non-idiomatic
Clojure source code, from within GNU Emacs. See
<https://github.com/jonase/kibit> for more information about
Kibit.

This package does not require Cider, although if you are working
with Clojure in Emacs, you should almost certaily be using it.
<http://www.github.com/clojure-emacs/cider>

; Installation:

Available as a package in melpa.org

(add-to-list 'package-archives
             '("melpa" . "http://melpa.org/packages/") t)

M-x package-install kibit-helper
