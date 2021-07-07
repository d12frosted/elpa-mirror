impatient-mode is a minor mode that publishes the live buffer
through the local simple-httpd server under /imp/<buffer-name>. To
unpublish a buffer, toggle impatient-mode off.

Start the simple-httpd server (`httpd-start') and visit /imp/ on
the local server. There will be a listing of all the buffers that
currently have impatient-mode enabled. This is likely to be found
here:

  http://localhost:8080/imp/

Except for html-mode buffers, buffers will be prettied up with
htmlize before being sent to clients. This can be toggled at any
time with `imp-toggle-htmlize'.

Because html-mode buffers are sent raw, you can use impatient-mode
see your edits to an HTML document live! This is perhaps the
primary motivation of this mode.

To receive updates the browser issues a long poll on the client
waiting for the buffer to change -- server push. The response
happens in an `after-change-functions' hook. Buffers that do not
run these hooks will not be displayed live to clients.
