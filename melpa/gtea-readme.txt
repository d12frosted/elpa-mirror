This package provides convenience wrappers, specialized for Gitea,
around functions provided by the `ghub' package (which, unless told
otherwise, assumes it is talking to a Github host).

Instead of   (ghub-get ... :forge 'gitea)
you can use  (gtea-get ...)

This package is semi-deprecated.  You might learn that in your own
package you have to further wrap `gtea-VERB' functions, and if you
do that, you might as well wrap `ghub-VERB' or even `ghub-request'
directly.
