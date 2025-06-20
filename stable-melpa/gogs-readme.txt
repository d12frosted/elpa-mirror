This package provides convenience wrappers, specialized for Gogs,
around functions provided by the `ghub' package (which, unless told
otherwise, assumes it is talking to a Github host).

Instead of   (ghub-get ... :forge 'gogs)
you can use  (gogs-get ...)

This package is semi-deprecated.  You might learn that in your own
package you have to further wrap `gogs-VERB' functions, and if you
do that, you might as well wrap `ghub-VERB' or even `ghub-request'
directly.
