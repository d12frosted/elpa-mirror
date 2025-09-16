A portion of the code in this file is based on blog.el posted to
http://www.mail-archive.com/gnu-emacs-sources@gnu.org/msg01576.html
copyrighted by Ashish Shukla.

This API operates against WordPress using both the
XML-RPC MetaWeblog API specification
https://codex.wordpress.org/XML-RPC_MetaWeblog_API
and the XML-RPC WordPress API
https://codex.wordpress.org/XML-RPC_WordPress_API

This API operates against a blog using its RPC endpoint URL ‘BLOG-XMLRPC',
a user name `USER-NAME', a password `PASSWORD', and a blog ID ‘BLOG-ID'.
These parameters are used for every API call. When their intention is
obvious and as expected they are excluded from documentation by
including them in line at the end of the docstring only to satisfy
the byte-compiler.
