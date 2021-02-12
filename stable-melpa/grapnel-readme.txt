grapnel is an HTTP request library that uses a curl subprocess and
offers flexible callback dispatch.  Not only can you pass in an
alist of request outcomes to callback functions (see below) but you
can also override the dispatch function itself if the default one
doesn't suit your needs.  Further, grapnel will build the query
string, request data (i.e., POST body), and headers from alists
that are passed in.

An example:
(grapnel-retrieve-url
 "www.google.com"
 '((success . (lambda (res hdrs) (message "%s" res)))
   (failure . (lambda (res hdrs) (message "Fail: %s" res)))
   (error   . (lambda (res err)  (message "Err: %s" err))))
 "GET"
 '((q . "ASIN B001EN71CW")))

History

0.5.1 - Initial release.

0.5.2 - Fix some quoting issues on Windows

0.5.3 - Handle HTTP 100 responses, fix a hanging curl request
