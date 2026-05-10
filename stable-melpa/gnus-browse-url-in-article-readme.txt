Provides `gnus-browse-url-in-article', an extensible command for
browsing the "best" URL in a Gnus article. Built-in handlers cover
GitHub PR notifications and LinkedIn job alerts. Additional
per-sender handlers can be registered via
`gnus-browse-url-in-article-handlers'.

Handler protocol (EIEIO):

  Subclass `gnus-browse-url-in-article-handler' and implement two methods:
    * `gnus-browse-url-in-article-handler-matches-p' — return
      non-nil if this handler applies to the current article;
      called in `gnus-summary-mode' context.
    * `gnus-browse-url-in-article-handler-get-urls' — return a (display . url) alist,
      or nil to fall through to the next handler.

  For simple cases, use `gnus-browse-url-in-article-make-handler'
  to create a `gnus-browse-url-in-article-function-handler' from a
  predicate and handler function.
