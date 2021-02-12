Provides a Clojure interactive development environment for Emacs, built on
top of nREPL.  See https://docs.cider.mx for more details.

; Installation:

CIDER is available as a package in melpa.org and stable.melpa.org.  First, make sure you've
enabled one of the repositories in your Emacs config:

(add-to-list 'package-archives
             '("melpa" . "https://melpa.org/packages/"))

or

(add-to-list 'package-archives
             '("melpa-stable" . "https://stable.melpa.org/packages/") t)

Afterwards, installing CIDER is as easy as:

M-x package-install cider
