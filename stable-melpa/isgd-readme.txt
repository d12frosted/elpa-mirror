Simple mode to shorten URLs from Emacs.

Adapted from bitly.el from Jorgen Schaefer <forcer@forcix.cx>
available here https://github.com/forcix/bitly.el

Use (isgd-shorten URL) from an Emacs Lisp program, or
M-x isgd-copy-url-at-point to copy the shortened URL at point (or the region)
to the kill ring, or M-x isgd-replace-url-at-point to replace the URL at point
(or the region) with a shortened version.

Customizations:

- `isgd-base-url' is the base URL for the is.gd shortening service API.
- `isgd-logstats' enables detailed logging of statistics for shortened URLs.
- `isgd-ask-custom-url' asks for a custom short URL when shortening URLs.
