Avandu is an Emacs mode that connects to a Tiny Tiny RSS
(http://tt-rss.org) instance and allows you to read the feeds it
has gathered.

The simplest way to install it is to use package.el:

    (package-install-file "/path/to/avandu.el")

For further information I would like to refer you to the avandu
info file.

Once installation is out of the way, it should get a value for
`avandu-tt-rss-api-url' (for example: http://tt-rss.org/demo/api/)
and then run `avandu-overview'.

Once in avandu:overview mode some key bindings will be:

- `r' :: Mark article at point as read.
- `o' :: Open article at point in a browser.  Uses `browse-url'.
- `n' :: Next article.
- `p' :: Previous article.
