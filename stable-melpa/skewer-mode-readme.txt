Quick start (without package.el):

 1. Put this directory in your `load-path'
 2. Load skewer-mode.el
 3. M-x `run-skewer' to attach a browser to Emacs
 4. From a `js2-mode' buffer with `skewer-mode' minor mode enabled,
    send forms to the browser to evaluate

The function `skewer-setup' can be used to configure all of mode
hooks (previously this was the default). This can also be done
manually like so,

    (add-hook 'js2-mode-hook 'skewer-mode)
    (add-hook 'css-mode-hook 'skewer-css-mode)
    (add-hook 'html-mode-hook 'skewer-html-mode)

The keybindings for evaluating expressions in the browser are just
like the Lisp modes. These are provided by the minor mode
`skewer-mode'.

 * C-x C-e -- `skewer-eval-last-expression'
 * C-M-x   -- `skewer-eval-defun'
 * C-c C-k -- `skewer-load-buffer'

The result of the expression is echoed in the minibuffer.

Additionally, `css-mode' and `html-mode' get a similar set of
bindings for modifying the CSS rules and updating HTML on the
current page.

Note: `run-skewer' uses `browse-url' to launch the browser. This
may require further setup depending on your operating system and
personal preferences.

Multiple browsers and browser tabs can be attached to Emacs at
once. JavaScript forms are sent to all attached clients
simultaneously, and each will echo back the result
individually. Use `list-skewer-clients' to see a list of all
currently attached clients.

Sometimes Skewer's long polls from the browser will timeout after a
number of hours of inactivity. If you find the browser disconnected
from Emacs for any reason, use the browser's console to call
skewer() to reconnect. This avoids a page reload, which would lose
any fragile browser state you might care about.

To skewer your own document rather than the provided blank page,

 1. Load the dependencies
 2. Load skewer-mode.el
 3. Start the HTTP server (`httpd-start')
 4. Include "http://localhost:8080/skewer" as a script
    (see `example.html' and check your `httpd-port')
 5. Visit the document from your browser

Skewer fully supports CORS, so the document need not be hosted by
Emacs itself. A Greasemonkey userscript and a bookmarklet are
provided for injecting Skewer into any arbitrary page you're
visiting without needing to modify the page on the host.

With skewer-repl.el loaded, a REPL into the browser can be created
with M-x `skewer-repl', or C-c C-z. This should work like a console
within the browser. Messages can be logged to this REPL with
skewer.log() (just like console.log()).

Extending Skewer:

Skewer is flexible and open to extension. The REPL and the CSS and
HTML minor modes are a partial examples of this. You can extend
skewer.js with your own request handlers and talk to them from
Emacs using `skewer-eval' (or `skewer-eval-synchronously') with
your own custom :type. The :type string chooses the dispatch
function under the skewer.fn object. To inject your own JavaScript
into skewer.js, use `skewer-js-hook'.

You can also catch messages sent from the browser not in response
to an explicit request. Use `skewer-response-hook' to see all
incoming objects.
