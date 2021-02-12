
This is an HTTP client using lexical scope.  This makes coding with
callbacks easier than with `url'.  This package also provides a
streaming mode where the callback is continually called whenever
data arrives. This is particularly useful for chunked encoding
scenarios.

Examples:

GET-ing an HTTP page

(web-http-get
 (lambda (con header data)
   (message "the page returned is: %s" data))
 :url "http://emacswiki.org/wiki/NicFerrier")

POST-ing to an HTTP app

(web-http-post
 (lambda (con header data)
   (message "the data is: %S" data))
 :url "http://example.org/postplace/"
 :data '(("parameter1" . "data")
         ("parameter2" . "more data")))
