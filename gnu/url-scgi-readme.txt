			     ━━━━━━━━━━━━━
			      URL-SCGI.EL
			     ━━━━━━━━━━━━━


			       2023-01-30


[https://elpa.gnu.org/packages/url-scgi.svg]

This library adds support for Simple Common Gateway Interface (SCGI)
URLs to the built-in Emacs `url' library.

The SCGI protocol is intended as a replacement for the older CGI
protocol, and is comparable to FastCGI or WAI, but much simpler.  Thus,
the SCGI protocol is most often used by web servers to communicate with
a program that serves dynamically generated pages and files (instead of
just static ones).  SCGI is supported in web servers such as Apache,
lighttpd, and nginx.

This library effectively makes Emacs take the place of a web server.
This can be useful for testing, but not only that.  It was originally
developed for [Mentor], an Emacs front-end for the BitTorrent client
`rtorrent', where it is used for remote procedure calls (RPC).

SCGI is described in more detail on [Wikipedia].  As far as I know,
there is no RFC describing SCGI, nor is there any formal specification.
On the other hand, the protocol is very simple; it is described in
detail [here].

SCGI URLs look like this: `scgi://<host>:<port>'.  See below for an
example.


[https://elpa.gnu.org/packages/url-scgi.svg]
<https://elpa.gnu.org/packages/url-scgi.html>

[Mentor] <https://www.github.com/skangas/mentor>

[Wikipedia]
<https://en.wikipedia.org/wiki/Simple_Common_Gateway_Interface>

[here] <https://python.ca/scgi/protocol.txt>


1 Installation
══════════════

  url-scgi.el can be installed from [GNU ELPA], an Emacs Lisp package
  archive that is enabled by default in Emacs.

  Find and install url-sgi.el using this command:

  ┌────
  │ M-x list-packages
  └────


[GNU ELPA] <https://elpa.gnu.org/>

1.1 Usage
─────────

  First, require `url-scgi':

  ┌────
  │ (require 'url-scgi)
  └────


  Now, to make an SCGI request with `url-scgi', simply call
  `url-retrieve' or `url-retrieve-synchronously' with a URL starting
  with `scgi://'.

  For example, let's assume you have some program listening for SCGI
  requests on `localhost' port `5000'.  You can then issue a request
  containing the string `some-data' with:

  ┌────
  │ (url-retrieve-synchronously "scgi://localhost:5000/some-data")
  └────


  You will want to replace `some-data' with something relevant to the
  program you are talking to.  Please refer to its documentation for
  details.

  If your application supports XML-RPC (remote procedure calls) over
  SCGI, you can make such calls using `url-scgi' with the `xml-rpc'
  package.  For example, if your program supports an XML-RPC method
  named `foo', you would call it like so:

  ┌────
  │ (require 'url-scgi)
  │ (require 'xml-rpc)
  │ (xml-rpc-method-call "scgi://localhost:5000" "foo")
  └────


  For more, see the documentation of the `xml-rpc' package.


1.2 Contribute
──────────────

  This library is part of [GNU ELPA] and therefore requires a [copyright
  assignment] to the [Free Software Foundation] for any non-trivial
  contributions.

  Please email me a patch, or open a pull request on GitHub, according
  to your preferences.


[GNU ELPA] <https://elpa.gnu.org/packages/url-scgi.html>

[copyright assignment]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/Copyright-Assignment.html>

[Free Software Foundation] <https://www.fsf.org/>


1.3 Contact
───────────

  You can find the latest version of url-scgi.el here:

  <https://www.github.com/skangas/url-scgi>

  Bug reports, comments, and suggestions are welcome!  Email them to
  Stefan Kangas <stefankangas@gmail.com> or report them on GitHub.
