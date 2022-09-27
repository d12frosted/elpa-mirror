				━━━━━━━━
				 PLZ.EL
				━━━━━━━━


Table of Contents
─────────────────

1. Installation
.. 1. GNU ELPA
.. 2. Manual
2. Usage
.. 1. Examples
.. 2. Functions
.. 3. Queueing
.. 4. Tips
3. Changelog
.. 1. 0.2.1
.. 2. 0.2
.. 3. 0.1
4. Credits
5. Development
.. 1. Copyright assignment
6. License


[file:http://elpa.gnu.org/packages/plz.svg]

`plz' is an HTTP library for Emacs.  It uses `curl' as a backend, which
avoids some of the issues with using Emacs's built-in `url' library.  It
supports both synchronous and asynchronous requests.  Its API is
intended to be simple, natural, and expressive.  Its code is intended to
be simple and well-organized.  Every feature is tested against
[httpbin].


[file:http://elpa.gnu.org/packages/plz.svg]
<http://elpa.gnu.org/packages/plz.html>

[httpbin] <https://httpbin.org/>


1 Installation
══════════════

1.1 GNU ELPA
────────────

  `plz' is available in [GNU ELPA].  It may be installed in Emacs using
  the `package-install' command.


[GNU ELPA] <http://elpa.gnu.org/packages/plz.html>


1.2 Manual
──────────

  `plz' has no dependencies other than Emacs and `curl'.  It's known to
  work on Emacs 26.3 or later.  To install it manually, simply place
  `plz.el' in your `load-path' and `(require 'plz)'.


2 Usage
═══════

  The main public function is `plz', which sends an HTTP request and
  returns either the result of the specified type (for a synchronous
  request), or the `curl' process object (for asynchronous requests).
  For asynchronous requests, callback, error-handling, and finalizer
  functions may be specified, as well as various other options.


2.1 Examples
────────────

  Synchronously `GET' a URL and return the response body as a decoded
  string (here, raw JSON):

  ┌────
  │ (plz 'get "https://httpbin.org/user-agent")
  └────

  ┌────
  │ "{\n \"user-agent\": \"curl/7.35.0\"\n}\n"
  └────

  Synchronously `GET' a URL that returns a JSON object, and parse and
  return it as an alist:

  ┌────
  │ (plz 'get "https://httpbin.org/get" :as #'json-read)
  └────

  ┌────
  │ ((args)
  │  (headers
  │   (Accept . "*/*")
  │   (Accept-Encoding . "deflate, gzip")
  │   (Host . "httpbin.org")
  │   (User-Agent . "curl/7.35.0"))
  │  (url . "https://httpbin.org/get"))
  └────

  Asynchronously `POST' a JSON object in the request body, then parse a
  JSON object from the response body, and call a function with the
  result:

  ┌────
  │ (plz 'post "https://httpbin.org/post"
  │   :headers '(("Content-Type" . "application/json"))
  │   :body (json-encode '(("key" . "value")))
  │   :as #'json-read
  │   :then (lambda (alist)
  │ 	  (message "Result: %s" (alist-get 'data alist))))
  └────

  ┌────
  │ Result: {"key":"value"}
  └────


  Synchronously download a JPEG file, then create an Emacs image object
  from the data:

  ┌────
  │ (let ((jpeg-data (plz 'get "https://httpbin.org/image/jpeg" :as 'binary)))
  │   (create-image jpeg-data nil 'data))
  └────

  ┌────
  │ (image :type jpeg :data ""ÿØÿà^@^PJFIF...")
  └────


2.2 Functions
─────────────

  `plz'
        /(method url &key headers body else finally noquery (as 'string)
        (then 'sync) (body-type 'text) (decode t decode-s)
        (connect-timeout plz-connect-timeout) (timeout plz-timeout))/

        Request `METHOD' from `URL' with curl.  Return the curl process
        object or, for a synchronous request, the selected result.

        `HEADERS' may be an alist of extra headers to send with the
        request.

        `BODY-TYPE' may be `text' to send `BODY' as text, or `binary' to
        send it as binary.

        `AS' selects the kind of result to pass to the callback function
        `THEN', or the kind of result to return for synchronous
        requests.  It may be:

        • `buffer' to pass the response buffer.
        • `binary' to pass the response body as an undecoded string.
        • `string' to pass the response body as a decoded string.
        • `response' to pass a `plz-response' struct.
        • A function, to pass its return value; it is called in the
          response buffer, which is narrowed to the response body
          (suitable for, e.g. `json-read').
        • `file' to pass a temporary filename to which the response
          body has been saved without decoding.
        • `(file FILENAME)' to pass `FILENAME' after having saved the
          response body to it without decoding.  `FILENAME' must be a
          non-existent file; if it exists, it will not be overwritten,
          and an error will be signaled.

        If `DECODE' is non-nil, the response body is decoded
        automatically.  For binary content, it should be nil.  When `AS'
        is `binary', `DECODE' is automatically set to nil.

        `THEN' is a callback function, whose sole argument is selected
        above with `AS'.  Or `THEN' may be `sync' to make a synchronous
        request, in which case the result is returned directly.

        `ELSE' is an optional callback function called when the request
        fails with one argument, a `plz-error' struct.  If `ELSE' is
        nil, an error is signaled when the request fails, either
        `plz-curl-error' or `plz-http-error' as appropriate, with a
        `plz-error' struct as the error data.  For synchronous requests,
        this argument is ignored.

        `FINALLY' is an optional function called without argument after
        `THEN' or `ELSE', as appropriate.  For synchronous requests,
        this argument is ignored.

        `CONNECT-TIMEOUT' and `TIMEOUT' are a number of seconds that
        limit how long it takes to connect to a host and to receive a
        response from a host, respectively.

        `NOQUERY' is passed to `make-process', which see.


2.3 Queueing
────────────

  `plz' provides a simple system for queueing HTTP requests.  First,
  make a `plz-queue' struct by calling `make-plz-queue'.  Then call
  `plz-queue' with the struct as the first argument, and the rest of the
  arguments being the same as those passed to `plz'.  Then call
  `plz-run' to run the queued requests.

  All of the queue-related functions return the queue as their value,
  making them easy to use.  For example:

  ┌────
  │ (defvar my-queue (make-plz-queue :limit 2))
  │ 
  │ (plz-run
  │  (plz-queue my-queue
  │    'get "https://httpbin.org/get?foo=0"
  │    :then (lambda (body) (message "%s" body))))
  └────

  Or:

  ┌────
  │ (let ((queue (make-plz-queue :limit 2))
  │       (urls '("https://httpbin.org/get?foo=0"
  │ 	      "https://httpbin.org/get?foo=1")))
  │   (plz-run
  │    (dolist (url urls queue)
  │      (plz-queue queue 'get url
  │        :then (lambda (body) (message "%s" body))))))
  └────

  You may also clear a queue with `plz-clear', which cancels any active
  or queued requests and calls their `:else' functions.  And
  `plz-length' returns the number of a queue's active and queued
  requests.


2.4 Tips
────────

  ⁃ You can customize settings in the `plz' group, but this can only be
    used to adjust a few defaults.  It's not intended that changing or
    binding global variables be necessary for normal operation.


3 Changelog
═══════════

3.1 0.2.1
─────────

  *Fixes*
  ⁃ Handle when Curl process is interrupted.


3.2 0.2
───────

  *Added*
  ⁃ Simple request queueing.


3.3 0.1
───────

  Initial release.


4 Credits
═════════

  ⁃ Thanks to [Chris Wellons], author of the [Elfeed] feed reader and
    the popular blog [null program], for his invaluable advice, review,
    and encouragement.


[Chris Wellons] <https://github.com/skeeto>

[Elfeed] <https://github.com/skeeto/elfeed>

[null program] <https://nullprogram.com/>


5 Development
═════════════

  Bug reports, feature requests, suggestions — /oh my/!

  Note that `plz' is a young library, and its only client so far is
  [Ement.el].  There are a variety of HTTP and `curl' features it does
  not yet support, since they have not been needed by the author.
  Patches are welcome, as long as they include passing tests.


[Ement.el] <https://github.com/alphapapa/ement.el>

5.1 Copyright assignment
────────────────────────

  This package is part of [GNU Emacs], being distributed in [GNU ELPA].
  Contributions to this project must follow GNU guidelines, which means
  that, as with other parts of Emacs, patches of more than a few lines
  must be accompanied by having assigned copyright for the contribution
  to the FSF.  Contributors who wish to do so may contact
  [emacs-devel@gnu.org] to request the assignment form.


[GNU Emacs] <https://www.gnu.org/software/emacs/>

[GNU ELPA] <https://elpa.gnu.org/>

[emacs-devel@gnu.org] <mailto:emacs-devel@gnu.org>


6 License
═════════

  GPLv3
