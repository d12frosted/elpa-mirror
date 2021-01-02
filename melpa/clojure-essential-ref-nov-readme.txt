
Provides command `clojure-essential-ref-nov' to browse offline the
documentation for symbol in ebook version of book "Clojure, The
Essential Reference".

Works similarly to `cider-clojuredocs-web'.

This package is a child package of `clojure-essential-ref'.

You can make command `clojure-essential-ref' browse to the EPUB version (instead of the online "liveBook") by putting this in your Emacs init:

(setq clojure-essential-ref-default-browse-fn #'clojure-essential-ref-nov-browse)
