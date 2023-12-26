This package provides a way to combine multiple Xref source
(e.g. Etags and Eglot) and have the results all at once.

To enable, toggle the `xref-union-mode' minor mode.  If you want to
exclude certain modes, take a look at the user option
`xref-union-excluded-backends'.

You can also manually make use of `xref-union' by adding an
function that returns an object of the form (union XREF-BACKEND-1
XREF-BACKEND-2 ...) to `xref-backend-functions'.