Eglotx presents one instance of the `eglot-lsp-server' class to Eglot
while routing directly
to multiple `jsonrpc-process-connection' backends.  The facade never
serializes JSON: only real language-server process boundaries do.

The normal entry point is `eglotx-contact'.  See the README for setup.
