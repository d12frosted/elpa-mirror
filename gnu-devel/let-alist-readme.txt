This package offers a single macro, `let-alist'.  This macro takes a
first argument (whose value must be an alist) and a body.

The macro expands to a let form containing body, where each dotted
symbol inside body is let-bound to their cdrs in the alist.  Dotted
symbol is any symbol starting with a `.'.  Only those present in
the body are let-bound and this search is done at compile time.
A number will result in a list index.

For instance, the following code

  (let-alist alist
    (if (and .title.0 .body)
        .body
      .site
      .site.contents))

essentially expands to

  (let ((.title.0 (elt (cdr (assq 'title alist)) 0))
        (.body  (cdr (assq 'body alist)))
        (.site  (cdr (assq 'site alist)))
        (.site.contents (cdr (assq 'contents (cdr (assq 'site alist))))))
    (if (and .title.0 .body)
        .body
      .site
      .site.contents))

If you nest `let-alist' invocations, the inner one can't access
the variables of the outer one.  You can, however, access alists
inside the original alist by using dots inside the symbol, as
displayed in the example above by the `.site.contents'.