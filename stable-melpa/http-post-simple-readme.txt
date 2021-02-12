Provides ways to use the url library to perform HTTP POST requests.
See the documentation to `http-post-simple' for more information.

The `url-http' library does not handle 1xx response codes.

However, as RFC 2616 puts it:
    a server MAY send a 100 (Continue)
    status in response to an HTTP/1.1 PUT or POST request that does
    not include an Expect request-header field with the "100-continue"
    expectation.

-- and some servers do, giving you annoying errors. To avoid these errors,
you can either set `url-http-version' to "1.0", in which case any compliant
server will not send the 100 (Continue) code, or call
`http-post-finesse-code-100'. Note that the latter advises
'url-http-parse-response'
