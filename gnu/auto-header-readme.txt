This script parses man-pages to guess what C header files a function
might need.

Bind `auto-header-at-point' to a convenient key if you want to
invoke the functionality manually, or add `auto-header-buffer' to
`before-save-hook' (in most cases you want to only add it locally),
so that headers are updated just before saving the contents of a
buffer.  This can also be done by enabling `auto-header-mode', or
by adding it to a major mode hook (e.g. `c-mode-hook').