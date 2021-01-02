peek-mode is a minor mode that publishes live Emacs buffers through
an elnode server under
http://<server>:<port>/peek/<buffer>. Turning on peek-mode in a
buffer will publish it. To unpublish a buffer, toggle peek-mode
off.

peek-mode is (very very!) largely based on Brian Taylor's
<el.wubo@gmail.com> impatient-mode
<https://github.com/netguy204/imp.el> However, impatient-mode does
not use elnode, but rather a different emacs httpd backend
<https://github.com/skeeto/emacs-http-server>. I consider peek-mode
as "impatient-mode ported to elnode".

Start the elnode server (`elnode-start') and visit
http://<server>:<port>/peek/. There will be a listing of all the
buffers that currently have peek-mode enabled. You can evaluate the
line below to start the elnode server on localhost:8008 with the
proper dispatcher, assuming the code in this file is available by
having loaded it.
(elnode-start 'peek-mode-dispatcher-handler :port 8008 :host "localhost")

Because html-mode buffers are sent raw, you can use peek-mode
see your edits to an HTML document live!

To receive updates the browser issues a long poll on the client
waiting for the buffer to change -- server push. The response
happens in an `after-change-functions' hook. Buffers that do not
run these hooks will not be displayed live to clients.
