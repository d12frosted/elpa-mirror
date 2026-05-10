A major mode for viewing HTTP Archive (HAR) files.  Provides a
tabulated list of all captured requests and responses with commands
to inspect headers, request/response bodies, and copy entries as
cURL commands.

Usage:
Enable `har-viewer-global-minor-mode' so that visiting any .har file
automatically binds C-c C-v to `har-viewer-view'.  Alternatively, call
`har-viewer-view' directly from a buffer containing HAR JSON.

Keybindings in `har-viewer-mode':

  RET        Display request and response headers
  C-c C-r    Display response body
  C-c C-p    Display request body
  C-c C-c    Copy entry as a cURL command (also: yc in evil normal state)
  C-c C-n    Narrow list by URL regex

Optional integrations:

  restclient  -- header buffers use restclient-mode when available
  web-beautify -- body buffers are auto-formatted when available
  evil         -- adds RET and yc normal-state bindings when available
