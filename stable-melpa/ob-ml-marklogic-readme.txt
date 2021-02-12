This package provides org-mode support for evaluating code blocks
by sending them off to MarkLogic server.

XQuery, JavaScript and SPARQL are supported.  I've only tested on
MarkLogic 8.x or later.  YMMV on earlier releases.

There's nothing terribly fancy going on under the covers, this code
marshals the arguments to curl so you need to have a working
install of curl.  I've only tested this on Linux, but I expect it'll
work on Mac.  Not so sure about Windows.

Most of the configuration is done with header arguments.  These can
be specified at any level.  The following header arguments are
supported:

:ml-curl        The curl executable (/usr/bin/curl)
:ml-host        The MarkLogic hostname (localhost)
:ml-scheme      The URI scheme for requests (http)
:ml-port        The port for requests (8000)
:ml-auth        Type of auth (--digest)
:ml-username    Username (admin)
:ml-password    Password (admin)
:ml-output      Output buffer (*ob-ml-marklogic output*)
:ml-save-output Keep output buffer? (nil)
:ml-eval-path   The eval path (/v1/eval)
:ml-graphs-path The SPARQL eval path (/v1/graphs/sparql)

You'll probably need to change some of these settings.  The request
URI is constructed by concatenation:

    :ml-scheme "://" :ml-host ":" :ml-port :ml-*-path

If you don't specify :ml-auth, then the requests will be made without
authentication.  Setting :ml-save-output will prevent the temporary
buffer that's used to hold results from being deleted.  That can be
useful if something goes wrong.

You can also specify variables to the query, using the standard :var
header argument.  Variable names that start with "&" are passed
*to the eval endpoint*.  All other variable names are passed through
to the underlying query.

For example:

   #+begin_src ml-xquery :var startDate="2017-04-19T12:34:57"

This passes the variable "startDate" to the query (where it can
be accessed by declaring it external). Alternatively:

   #+begin_src ml-xquery :var &database="Documents"

This sets the "database" query parameter to the eval endpoint.
(We're careful to set "database" and "txid" parameters on the
URI so that they're accessible to the declarative rewriter; if
you don't know what that means, just ignore this parenthetical
comment.)

You can specify as many variables as you wish.  You'll no doubt get
errors if you pass things that the endpoint or query aren't expecting.
I have no idea how well my code plays with advanced org-mode features
like reference to other named code blocks.  If you see something
weird, please open an issue.

The results are very dependent on the "-v" output from curl.  Here's
what I expect:

   *   Trying 172.17.0.2...
     ...
   * upload completely sent off: 192 out of 192 bytes
   < HTTP/1.1 200 OK
   < Content-type: application/sparql-results+json; charset=UTF-8
   < Server: MarkLogic
   < Content-Length: 123
   < Connection: Keep-Alive
   < Keep-Alive: timeout=5
   <
   { [123 bytes data]
   * Connection #0 to host f23-builder left intact

   ACTUAL RESULTS GO HERE

In brief: ignore all of the results up to the line that contains
"upload completely sent off".  Then skip the HTTP/1.1 and parse
the headers.  Then skip to the results.

If the response is multipart *and* there's only one part, the
multipart scaffolding is stripped away, taking care to parse the
part headers to get the actual content type.

Because...

If there's only one part:

  * If it's JSON and 'json-reformat-region is available, the
    result is reformatted before returning it.
  * If it's XML and nxml-mode is available, the result
    is reformatted before returning it.

If there's more than one part, you just get the whole thing as
it appeared on the wire.

This module simply requires all of the others.  If you don't need
or want support for some of the languages, you can require them
individually.

TODO:

* Consider reformatting the individual parts of a multipart
  response
* Consider using some Emacs HTTP library instead of calling curl.
