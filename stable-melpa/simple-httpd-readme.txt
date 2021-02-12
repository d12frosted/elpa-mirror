Use `httpd-start' to start the web server. Files are served from
`httpd-root' on port `httpd-port' using `httpd-ip-family' at host
`httpd-host'. While the root can be changed at any time, the server
needs to be restarted in order for a port change to take effect.

Everything is performed by servlets, including serving
files. Servlets are enabled by setting `httpd-servlets' to true
(default). Servlets are four-parameter functions that begin with
"httpd/" where the trailing component specifies the initial path on
the server. For example, the function `httpd/hello-world' will be
called for the request "/hello-world" and "/hello-world/foo".

The default servlet `httpd/' is the one that serves files from
`httpd-root' and can be turned off through redefinition or setting
`httpd-serve-files' to nil. It is used even when `httpd-servlets'
is nil.

The four parameters for a servlet are process, URI path, GET/POST
arguments (alist), and the full request object (header
alist). These are ordered by general importance so that some can be
ignored. Two macros are provided to help with writing servlets.

 * `with-httpd-buffer' -- Creates a temporary buffer that is
   automatically served to the client at the end of the body.
   Additionally, `standard-output' is set to this output
   buffer. For example, this servlet says hello,

    (defun httpd/hello-world (proc path &rest args)
      (with-httpd-buffer proc "text/plain"
        (insert "hello, " (file-name-nondirectory path))))

This servlet be viewed at http://localhost:8080/hello-world/Emacs

* `defservlet' -- Similar to the above macro but totally hides the
  process object from the servlet itself. The above servlet can be
  re-written identically like so,

    (defservlet hello-world text/plain (path)
      (insert "hello, " (file-name-nondirectory path)))

Note that `defservlet' automatically sets `httpd-current-proc'. See
below.

The "function parameters" part can be left empty or contain up to
three parameters corresponding to the final three servlet
parameters. For example, a servlet that shows *scratch* and doesn't
need parameters,

    (defservlet scratch text/plain ()
      (insert-buffer-substring (get-buffer-create "*scratch*")))

A higher level macro `defservlet*' wraps this lower-level
`defservlet' macro, automatically binding variables to components
of the request. For example, this binds parts of the request path
and one query parameter. Request components not provided by the
client are bound to nil.

    (defservlet* packages/:package/:version text/plain (verbose)
      (insert (format "%s\n%s\n" package version))
      (princ (get-description package version))
      (when verbose
        (insert (format "%S" (get-dependencies package version)))))

It would be accessed like so,

    http://example.com/packages/foobar/1.0?verbose=1

Some support functions are available for servlets for more
customized responses.

  * `httpd-send-file'   -- serve a file with proper caching
  * `httpd-redirect'    -- redirect the browser to another url
  * `httpd-send-header' -- send custom headers
  * `httpd-error'       -- report an error to the client
  * `httpd-log'         -- log an object to *httpd*

Some of these functions require a process object, which isn't
passed to `defservlet' servlets. Use t in place of the process
argument to use `httpd-current-proc' (like `standard-output').

If you just need to serve static from some location under some
route on the server, use `httpd-def-file-servlet'. It expands into
a `defservlet' that serves files.
