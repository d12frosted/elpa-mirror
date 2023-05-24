Client for the Scheme LSP server.
Currently this client only supports CHICKEN 5, Gambit 4.9.4+ and Guile 3.

;; Installation

Make sure your chosen Scheme implementation is installed and on your
load-path.  Implementation support depends on availability of a corresponding
LSP server, as mentioned, for now only CHICKEN, Gambit and Guile are
supported.

For Gambit and Guile, the extension will prompt you for auto-installing the
LSP server.  In case something goes wrong (or you are using CHICKEN),
manually install the correposnding server following the instructions at
https://codeberg.org/rgherdt/scheme-lsp-server.


;; Setup

Add the following lines to your Emacs configuration file:

```
(require 'lsp-scheme)
(add-hook 'scheme-mode-hook #'lsp-scheme)

(setq lsp-scheme-implementation "guile") ;;; also customizable
```

Alternatively you can add the specific command as hook, for example:
```
   (add-hook 'scheme-mode-hook #'lsp-scheme-guile)
```
In this case, `lsp-scheme-implementation` is ignored.


This should in the first run automatically install the corresponding LSP server
and start the client.  In case you have trouble, you can manually install the
server following the corresponding instructions.



;; Usage
Starting with version 0.1.0, this LSP client works on the background and does
not rely on interaction with the user to keep LSP-related information on sync.
It also does not provide a custom REPL (as in the first version) anymore, you
can use Emacs' built-in Scheme support instead (`run-scheme`).  You may customize
`scheme-program-name` to run the interpreter of your Scheme of choice.

The LSP server works best if your code is packed inside a library definition
(either R6RS, R7RS or implementation specific).  Depending on the implementation,
you can improve the experience by adding your library to a path where your
implementation can find it (see note regarding Guile below).
