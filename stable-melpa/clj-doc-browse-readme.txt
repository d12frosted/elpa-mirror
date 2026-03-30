Browse Markdown API documentation embedded in Clojure library JARs.

Clojure libraries built with codox-md embed Markdown documentation as
classpath resources under docs/<group>/<artifact>/.  This package provides
Emacs commands to browse that documentation via CIDER's nREPL connection.

Prerequisites:
  - A running nREPL with cider-nrepl middleware
  - The clj-doc-browse Clojure library on the REPL classpath
  - Libraries built with codox-md on the classpath

Usage:
  M-x clj-doc-browse     - browse a namespace's docs (rendered Markdown)
  M-x clj-doc-browse-libraries  - list all documented libraries on the classpath
  M-x clj-doc-browse-search     - full-text search across all embedded docs

In the *clj-docs* buffer:
  C-c C-o  - follow source link at point (opens in Emacs, even from JARs)
  RET      - same as C-c C-o
  n/p      - next/previous heading (markdown-view-mode)
  q        - close the buffer
