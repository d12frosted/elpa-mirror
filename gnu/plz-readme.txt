                                ━━━━━━━━
                                 PLZ.EL
                                ━━━━━━━━


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

        `BODY' may be a string, a buffer, or a list like `(file
        FILENAME)' to upload a file from disk.

        `BODY-TYPE' may be `text' to send `BODY' as text, or `binary' to
        send it as binary.

        `AS' selects the kind of result to pass to the callback function
        `THEN', or the kind of result to return for synchronous
        requests.  It may be:

        • `buffer' to pass the response buffer, which will be narrowed
          to the response body and decoded according to `DECODE'.
        • `binary' to pass the response body as an un-decoded string.
        • `string' to pass the response body as a decoded string.
        • `response' to pass a `plz-response' structure.
        • `file' to pass a temporary filename to which the response body
          has been saved without decoding.
        • `(file ~FILENAME)' to pass `FILENAME' after having saved the
          response body to it without decoding.  `FILENAME' must be a
          non-existent file; if it exists, it will not be overwritten,
          and an error will be signaled.
        • A function, which is called in the response buffer with it
          narrowed to the response body (suitable for,
          e.g. `json-read').

        If `DECODE' is non-nil, the response body is decoded
        automatically.  For binary content, it should be nil.  When `AS'
        is `binary', `DECODE' is automatically set to nil.

        `THEN' is a callback function, whose sole argument is selected
        above with `AS'; if the request fails and no `ELSE' function is
        given (see below), the argument will be a `plz-error' structure
        describing the error.  Or `THEN' may be `sync' to make a
        synchronous request, in which case the result is returned
        directly from this function.

        `ELSE' is an optional callback function called when the request
        fails (i.e. if curl fails, or if the `HTTP' response has a
        non-2xx status code).  It is called with one argument, a
        `plz-error' structure.  If `ELSE' is nil, a `plz-curl-error' or
        `plz-http-error' is signaled when the request fails, with a
        `plz-error' structure as the error data.  For synchronous
        requests, this argument is ignored.

        `NOTE': In v0.8 of `plz', only one error will be signaled:
        `plz-error'.  The existing errors, `plz-curl-error' and
        `plz-http-error', inherit from `plz-error' to allow applications
        to update their code while using v0.7 (i.e. any `condition-case'
        forms should now handle only `plz-error', not the other two).

        `FINALLY' is an optional function called without argument after
        `THEN' or `ELSE', as appropriate.  For synchronous requests,
        this argument is ignored.

        `CONNECT-TIMEOUT' and `TIMEOUT' are a number of seconds that
        limit how long it takes to connect to a host and to receive a
        response from a host, respectively.

        `NOQUERY' is passed to `make-process', which see.

        `FILTER' is an optional function to be used as the process
        filter for the curl process.  It can be used to handle HTTP
        responses in a streaming way.  The function must accept 2
        arguments, the process object running curl, and a string which
        is output received from the process.  The default process filter
        inserts the output of the process into the process buffer.  The
        provided `FILTER' function should at least insert output up to
        the HTTP body into the process buffer.


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
  │ (let ((queue (make-plz-queue :limit 2
  │ 			     :finally (lambda ()
  │ 					(message "Queue empty."))))
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

3.1 0.9
───────

  *Compatibility*

  ⁃ The minimum supported Emacs version is now 27.1.  (It is no longer
    practical to test `plz' with Emacs versions older than 27.1.  For
    Emacs 26.3, an earlier version of `plz' may be used, or this version
    might be compatible, with or without minor changes, which the
    maintainer cannot offer support for.)

  *Changes*

  ⁃ Option `plz-timeout' is removed.  (It was the default value for
    `plz''s `:timeout' argument, which is passed to Curl as its
    `--max-time' argument, limiting the total duration of a request
    operation.  This argument should be unset by default, because larger
    or slower downloads might not finish within a certain duration, and
    it is surprising to the user to have this option set by default,
    potentially causing requests to timeout unnecessarily.)
  ⁃ Using arguments `:as 'file' or `:as '(file FILENAME)' now passes the
    filename to Curl, allowing it to write the data to the file itself
    (rather than receiving the data into an Emacs buffer and then
    writing it to a file.  This improves performance when downloading
    large files, significantly reducing Emacs's CPU and memory usage).

  *Fixes*

  ⁃ Improve workaround for Emacs's process sentinel-related issues.
    (Don't try to process response a second time if Emacs calls the
    sentinel after `plz' has returned for a synchronous request.  See
    [#53].  Thanks to [Joseph Turner] for extensive help debugging, and
    to [USHIN] for sponsoring some of this work.)
  ⁃ Inhibit buffer hooks when calling `generate-new-buffer' (as extra
    protection against "kill buffer?" prompts in case of errors).  (See
    [#52].  Thanks to [Michał Krzywkowski].)
    • Avoid "kill buffer?" prompts in case of errors on Emacs versions
      before 28.  (See [#52] and [#57].  Thanks to [Michał
      Krzywkowski].)

  *Development*

  ⁃ `plz' is now automatically tested against Emacs versions 27.1, 27.2,
    28.1, 28.2, 29.1, 29.2, 29.3, and a recent snapshot of the `master'
    branch (adding 29.2 and 29.3).


[#53] <https://github.com/alphapapa/plz.el/issues/53>

[Joseph Turner] <https://github.com/josephmturner>

[USHIN] <https://ushin.org/>

[#52] <https://github.com/alphapapa/plz.el/pull/52>

[Michał Krzywkowski] <https://github.com/mkcms>

[#57] <https://github.com/alphapapa/plz.el/issues/57>


3.2 0.8
───────

  *Additions*

  ⁃ Function `plz' now accepts a `:filter' argument which can be used to
    override the default process filter (e.g. for streaming responses).
    ([#43], [#50].  Thanks to [Roman Scherer].)


[#43] <https://github.com/alphapapa/plz.el/pull/43>

[#50] <https://github.com/alphapapa/plz.el/pull/50>

[Roman Scherer] <https://github.com/r0man>


3.3 0.7.3
─────────

  *Fixes*
  ⁃ Info manual generation on GNU ELPA.  (Also, the Info manual is no
    longer committed to Git.)


3.4 0.7.2
─────────

  *Fixes*
  ⁃ Don't delete preexisting files when downloading to a file.
    ([#41]. Thanks to [Joseph Turner].)


[#41] <https://github.com/alphapapa/plz.el/pull/41>

[Joseph Turner] <https://github.com/josephmturner>


3.5 0.7.1
─────────

  *Fixes*
  ⁃ Handle HTTP 303 redirects.  (Thanks to [Daniel Hubmann] for
    reporting.)


[Daniel Hubmann] <https://github.com/hubisan>


3.6 0.7
───────

  *Changes*
  ⁃ A new error signal, `plz-error', is defined.  The existing signals,
    `plz-curl-error' and `plz-http-error', inherit from it, so handling
    `plz-error' catches both.

    *NOTE:* The existing signals, `plz-curl-error' and `plz-http-error',
     are hereby deprecated, and they will be removed in v0.8.
     Applications should be updated while using v0.7 to only expect
     `plz-error'.

  *Fixes*
  ⁃ Significant improvement in reliability by implementing failsafes and
    workarounds for Emacs's process-handling code.  (See [#3].)
  ⁃ STDERR output from curl processes is not included in response bodies
    (which sometimes happened, depending on Emacs's internal race
    conditions).  (Fixes [#23].)
  ⁃ Use `with-local-quit' for synchronous requests (preventing Emacs
    from complaining sometimes).  (Fixes [#26].)
  ⁃ Various fixes for `:as 'buffer' result type: decode body when
    appropriate; unset multibyte for binary; narrow to body; don't kill
    buffer prematurely.
  ⁃ When clearing a queue, don't try to kill finished processes.

  *Internal*
  ⁃ Response processing now happens outside the process sentinel, so any
    errors (e.g. in user callbacks) are not signaled from inside the
    sentinel.  (This avoids the 2-second pause Emacs imposes in such
    cases.)
  ⁃ Tests run against a local instance of [httpbin] (since the
    `httpbin.org' server is often overloaded).
  ⁃ No buffer-local variables are defined anymore; process properties
    are used instead.


[#3] <https://github.com/alphapapa/plz.el/issues/3>

[#23] <https://github.com/alphapapa/plz.el/issues/23>

[#26] <https://github.com/alphapapa/plz.el/issues/26>

[httpbin] <https://github.com/postmanlabs/httpbin>


3.7 0.6
───────

  *Additions*
  ⁃ Function `plz''s `:body' argument now accepts a list like `(file
    FILENAME)' to upload a file from disk (by passing the filename to
    curl, rather than reading its content into Emacs and sending it to
    curl through the pipe).

  *Fixes*
  ⁃ Function `plz''s docstring now mentions that the `:body' argument
    may also be a buffer (an intentional feature that was accidentally
    undocumented).
  ⁃ Handle HTTP 3xx redirects when using `:as 'response'.


3.8 0.5.4
─────────

  *Fixes*
  ⁃ Only run queue's `finally' function after queue is empty.  (New
    features should not be designed and released on a Friday.)


3.9 0.5.3
─────────

  *Fixes*
  ⁃ Move new slot in `plz-queue' struct to end to prevent invalid
    byte-compiler expansions for already-compiled applications (which
    would require them to be recompiled after upgrading `plz').


3.10 0.5.2
──────────

  *Fixes*
  ⁃ When clearing a queue, only call `plz-queue''s `finally' function
    when specified.


3.11 0.5.1
──────────

  *Fixes*
  ⁃ Only call `plz-queue''s `finally' function when specified.  (Thanks
    to [Dan Oriani] for reporting.)


[Dan Oriani] <https://github.com/redchops>


3.12 0.5
────────

  *Additions*
  ⁃ Struct `plz-queue''s `finally' slot, a function called when the
    queue is finished.


3.13 0.4
────────

  *Additions*
  ⁃ Support for HTTP `HEAD' requests.  (Thanks to [USHIN] for
    sponsoring.)

  *Changes*
  ⁃ Allow sending `POST' and `PUT' requests without bodies.  ([#16].
    Thanks to [Joseph Turner] for reporting.  Thanks to [USHIN] for
    sponsoring.)

  *Fixes*
  ⁃ All 2xx HTTP status codes are considered successful.  ([#17].
    Thanks to [Joseph Turner] for reporting.  Thanks to [USHIN] for
    sponsoring.)
  ⁃ Errors are signaled with error data correctly.

  *Internal*
  ⁃ Test suite explicitly tests with both HTTP/1.1 and HTTP/2.
  ⁃ Test suite also tests with Emacs versions 27.2, 28.1, and 28.2.


[USHIN] <https://ushin.org/>

[#16] <https://github.com/alphapapa/plz.el/issues/16>

[Joseph Turner] <https://github.com/josephmturner>

[#17] <https://github.com/alphapapa/plz.el/issues/17>


3.14 0.3
────────

  *Additions*
  ⁃ Handle HTTP proxy headers from Curl. ([#2].  Thanks to [Alan Third]
    and [Sawyer Zheng] for reporting.)

  *Fixes*
  ⁃ Replaced words not in Ispell's default dictionaries (so `checkdoc'
    linting succeeds).


[#2] <https://github.com/alphapapa/plz.el/issues/2>

[Alan Third] <https://github.com/alanthird>

[Sawyer Zheng] <https://github.com/sawyerzheng>


3.15 0.2.1
──────────

  *Fixes*
  ⁃ Handle when Curl process is interrupted.


3.16 0.2
────────

  *Added*
  ⁃ Simple request queueing.


3.17 0.1
────────

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
