Provides quick access to Scheme Requests for Implementation (SRFI)
documents from within Emacs:

* `M-x srfi-list` brings up a *SRFI* buffer listing all SRFIs.

* `M-x srfi` does the same, but lets you live-narrow the list by
  typing numbers or words into the minibuffer.

* The *SRFI* buffer provides one-key commands to visit the SRFI
  document, its discussion (mailing list) archive, and its version
  control repository. These commands open the right web pages in
  your web browser using `browse-url'. The standard variable
  `browse-url-browser-function' can be used to control which web
  browser is used to open what pages.
