Sayid is a debugger for Clojure.  This package, sayid.el, is a client
for the sayid nREPL middleware.

To enable, use something like this:

(with-eval-after-load 'clojure-mode
  (sayid-setup-package))
