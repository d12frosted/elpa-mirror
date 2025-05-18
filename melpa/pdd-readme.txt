
This package provides a robust and elegant library for HTTP requests and
asynchronous operations in Emacs. It featuring a single, consistent API that
works identically across different backends, maximizing code portability and
simplifying development.

 - Unified Backend:

   Seamlessly utilize either the high-performance `curl' backend or the
   built-in `url.el'. It significantly enhances `url.el', adding essential
   features like cookie-jar support, streaming support, multipart uploads,
   comprehensive proxy support (HTTP/SOCKS with auth-source integration),
   smart request/response data conversion and automatic retries.

 - Developer Friendly:

   Offers a minimalist yet flexible API that is backend-agnostic, intuitive
   and easy to use. Features like variadic callbacks and header abbreviations
   can help you achieve more with less code.

 - Powerful Async Foundation:

   Features a native, cancellable `Promise/A+' implementation and intuitive
   `async/await' syntax for clean, readable concurrent code. Includes
   integrated async helpers for timers and external processes. Also includes
   a queue mechanism for fine-grained concurrency control when making multiple
   asynchronous requests.

 - Highly Extensible:

   Easily customize request/response flows using a clean transformer pipeline
   and object-oriented (EIEIO) backend design. This makes it easy to add new
   features or event entirely new backends.

Currently, there are two backends:

   1. pdd-url-backend, which is the default one

   2. pdd-curl-backend, which is based on `plz'. You should make sure
      package `plz' and program `curl' are available on your OS to use it:

      (setq pdd-backend (pdd-curl-backend))

Usage:

   (pdd "https://httpbin.org/uuid" #'print)

   (pdd "https://httpbin.org/post"
     :headers '((bear "hello world"))
     :params '((name . "jerry") (age . 9))
     :data '((key . "value") (file1 "~/aaa.jpg"))
     :done (lambda (json) (alist-get 'file json))
     :proxy "socks5://localhost:1085"
     :cookie-jar (pdd-cookie-jar "~/xxx.mycookie"))

   (pdd-async
     (let* ((r1 (await (pdd "https://httpbin.org/ip")
                       (pdd "https://httpbin.org/uuid")))
            (r2 (await (pdd "https://httpbin.org/anything"
                         `((ip . ,(alist-get 'origin (car r1)))
                           (id . ,(alist-get 'uuid (cadr r1))))))))
       (message "> Got: %s" (alist-get 'form r2))))

See README.md of https://github.com/lorniu/pdd.el for more
