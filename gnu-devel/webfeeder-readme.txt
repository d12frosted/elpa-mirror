Webfeeder is an Emacs library to generate RSS
(https://en.wikipedia.org/wiki/RSS) and Atom
(https://en.wikipedia.org/wiki/Atom_(Web_standard)) feeds from HTML files.

Other webfeed generators have been written for Emacs, but either they are
tied to other projects like blog generators, or they only work on Org files
like `ox-rss'.  Since Webfeeder generates webfeeds from HTML files, it is
more general.

The various elements of the HTML input are parsed with customizable
functions.  For instance, Webfeeder offers two functions to parse the title:
`webfeeder-title-libxml' (using libxml if your Emacs is linked against it)
and the less reliable `webfeeder-title-default'.  Feel free to write you own
function and bind `webfeeder-title-function' before generating the feeds.

The generated feeds should be valid on https://validator.w3.org/feed/.  If not,
it's a bug, please report.

The full list of customizable functions is documented in
`webfeeder-html-files-to-items'.

The entry point is `webfeeder-build': consult its documentation for more
information.

Example:

(webfeeder-build
  "atom.xml"
  "./public"
  "https://example.org/"
  '("post1.html" "post2.html" "post3.html")
  :title "My homepage"
  :description "A collection of articles in Atom")