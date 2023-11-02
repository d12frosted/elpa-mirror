                              ━━━━━━━━━━━━
                               PLZ-SEE.EL
                              ━━━━━━━━━━━━


`plz-see' is an interactive HTTP client for Emacs based on the [plz]
library.  It is interactive in the sense that request responses are
pretty-printed in a pop-up buffer.  It can be used to explore and test
web APIs or to debug packages that use `plz'.

The main function provided by the package is unsurprisingly named
`plz-see', which has the essentially the same API as `plz'.  See the
docstring for details on the differences.

Additionally, the following variables (which become buffer-local when
set) are provided for convenience:

• `plz-see-base-url': Prefix added to the all “relative” URLs passed to
  `plz-see'.  Paradoxically, a URL in considered relative if it starts
  with `/'
• `plz-see-base-headers': Alist of headers added to all requests.
  Entries of this list can be overridden using the `HEADERS' argument of
  `plz-see'.

For further customization options, see `M-x customize-group plz-see
RET'.


[plz] <https://github.com/alphapapa/plz.el>


1 Examples
══════════

  Make a GET request:

  ┌────
  │ (plz-see 'get "https://httpbin.org/get?hello=world")
  └────

  Send some data through a POST request:

  ┌────
  │ (plz-see 'post "https://httpbin.org/post" :body "Hello World!")
  │ (plz-see 'post "https://httpbin.org/post" :body (current-buffer))
  │ (plz-see 'post "https://httpbin.org/post" :body '(file "./README.org"))
  └────

  Set a base URL to shorten `plz-see' calls in a given buffer:

  ┌────
  │ (setq-local plz-see-base-url "https://httpbin.org")
  │ (plz-see 'get "/image/jpeg")
  │ (plz-see 'get "/status/404")
  └────

  Authenticate with username and password, read a bearer token from the
  server response, and store it in the default headers for future use.

  ┌────
  │ (progn
  │   (setq-local plz-see-base-url "http://localhost:8080")
  │   (setq-local user "user@example.com" pass "1234"))
  │ 
  │ (plz-see 'post "/login"
  │ 	 :headers '(("Content-Type" . "application/x-www-form-urlencoded"))
  │ 	 :body (format "username=%s&password=%s"
  │ 		       (url-hexify-string user)
  │ 		       (url-hexify-string pass))
  │ 	 :as 'json-read
  │ 	 :then (let ((buffer (current-buffer)))
  │ 		 (lambda (r)
  │ 		   (with-current-buffer buffer
  │ 		     (let ((token (alist-get 'access_token r)))
  │ 		       (setq-local plz-see-base-headers
  │ 				   `(("Authorization" . ,(concat "Bearer " token)))))))))
  │ 
  │ (plz-see 'get "/authenticated")  ; Yay!
  └────


2 Alternatives
══════════════

  There are several alternatives to this package, such as [restclient]
  and [verb].  They are certainly more fully featured than `plz-see' and
  arguably have a more user-friendly notation.

  `plz-see' is geared towards those who prefer writing Elisp.  It can
  also be called from Eshell or IELM.


[restclient] <https://github.com/pashky/restclient.el>

[verb] <https://github.com/federicotdn/verb>
