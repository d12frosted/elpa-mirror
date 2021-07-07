
*insert-esv is an Emacs package for inserting ESV Bible passages.*

** Installation
insert-esv is available on [[https://melpa.org/#/getting-started][MELPA]].
To install it, run ~M-x package-install RET insert-esv RET~.

Alternatively, clone this repo and run
~M-x package-install-file RET </path/to/insert-esv.el> RET~.

** Usage
1. Grab an API key from [[https://api.esv.org/docs/][Crossway]].
2. Add the API key to your init file:
  ~(setq insert-esv-crossway-api-key "<token>")~.
3. Set a keybind in your init file:
  ~(global-set-key (kbd "C-x C-e") #'insert-esv-passage)~.
4. Once invoked, enter a Bible reference and hit ~RET~ to insert it at point.

*** Example configuration
You can include this [[https://github.com/jwiegley/use-package][use-package]]
config in place of Steps 2 and 3. In addition, it contains
suggested preferences for attribution, headings, and line length.

#+BEGIN_SRC elisp
(use-package
  insert-esv
  :init
  (setq insert-esv-crossway-api-key "<token>")
  (setq insert-esv-include-short-copyright 'true)
  (setq insert-esv-include-headings 'true)
  (setq insert-esv-include-passage-horizontal-lines 'false)
  (setq insert-esv-line-length '50)
  :bind ("C-x C-e" . insert-esv-passage))
#+END_SRC

** Options
- This package contains support for the optional parameters in Crossway's
  [[https://api.esv.org/docs/passage-text/][Passage Text API]].
- You can customise these parameters in your init file.
- Make sure to prefix each parameter with the package name:
  ~(setq insert-esv-include-headings 'true)~.

** Disclaimer
- insert-esv is licensed under
  [[https://github.com/sam030820/insert-esv/blob/master/COPYING][GPLv3]]
  and copyright sam030820 and
  [[https://github.com/sam030820/insert-esv/contributors][contributors]].
- Scripture quotations are from the ESV® Bible, copyright © 2001 by
  Crossway, a publishing ministry of Good News Publishers.
