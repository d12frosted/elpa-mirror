
`http.el' provides an easy way to interact with the HTTP protocol.

Usage:

Create a file with the following contents, and set `http-mode' as major mode.

    # -*- http -*-

    POST https://httpbin.org/post?val=key
    User-Agent: Emacs24
    Content-Type: application/json

    {
      "foo": "bar"
    }

Move the cursor somewhere within the description of the http request and
execute `M-x http-process` or press <kbd>C-c C-c</kbd>, if everything is went
well should show an buffer when the response of the http request:

![http.el screenshot](misc/screenshot.png)

More examples are included in file [misc/example.txt](misc/example.http)

Customization:

Fontify response:

If you want to use a custom mode for the fontification of the response buffer
with content-type equal to `http-content-type-mode-alist'.  For example, to
use [json-mode][] for responses with content-type "application/json":

    (add-to-list 'http-content-type-mode-alist
                 '("application/json" . json-mode))

Prettify response:

If you want to use a custom function to prettify the response body you need
to add it to `http-pretty-callback-alist', the function is called without
arguments.  Examples:

+ To use [json-reformat][] in responses with content-type "application/json":

    (require 'json-reformat)

    (defun my/pretty-json-buffer ()
      (json-reformat-region (point-min) (point-max)))

    (add-to-list 'http-pretty-callback-alist
                 '("application/json" . my/pretty-json-buffer))

+ To display the rendered html in responses with content-type "text/html":

    (require 'shr)

    (defun my/http-display-html ()
      (shr-render-region (point-min) (point-max)))

    (add-to-list 'http-pretty-callback-alist
                 '("text/html" . my/http-display-html))

Related projects:

+ [httprepl.el][]: An HTTP REPL for Emacs.

+ [restclient.el][]: HTTP REST client tool for Emacs.  You can use both
  projects indistinctly, the main differences between both are:

  |            | `restclient.el'   | `http.el'     |
  | ---------- | ----------------- | ------------- |
  | backend    | `url.el'          | `request.el'  |
  | variables  | yes               | no            |

[httprepl.el]: https://github.com/gregsexton/httprepl.el "An HTTP REPL for Emacs"
[restclient.el]: https://github.com/pashky/restclient.el "HTTP REST client tool for Emacs"
[json-mode]: https://github.com/joshwnj/json-mode "Major mode for editing JSON files with Emacs"
[json-reformat]: https://github.com/gongo/json-reformat "Reformat tool for JSON"
