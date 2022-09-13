Client for the Scheme LSP server.
Currently this client only supports CHICKEN 5, Gambit 4.9.4+ and Guile 3.

;; Installation

Make sure your chosen Scheme implementation is installed and on your
load-path.  Implementation support depends on availability of a corresponding
LSP server, as mentioned, for now only CHICKEN, Gambit and Guile are
supported.

On first run you should be prompted to install an lsp server.  The
extension will install it to its cache directory.
In case something goes wrong, manually install the server available at
https://codeberg.org/rgherdt/scheme-lsp-server (and make sure to create
an issue at our repository).

In order to achieve better results, follow these instructions to update
CHICKEN's documentation:

- install needed eggs: chicken-install -s r7rs apropos chicken-doc srfi-18 srfi-130
- update documentation database:
  $ cd `csi -R chicken.platform -p '(chicken-home)'`
  $ curl https://3e8.org/pub/chicken-doc/chicken-doc-repo-5.tgz | sudo tar zx


;; Setup

Add the following lines to your Emacs configuration file:

  (require lsp-scheme)
  (add-hook 'scheme-mode-hook #'lsp-scheme)
  (setq lsp-scheme-implementation "guile") ;;; customizable

Alternatively you can add the specific command as hook, for example:
  (add-hook 'scheme-mode-hook #'lsp-scheme-guile)
In this case lsp-scheme-implementation is ignored.



;; Usage
This LSP client tries to implement an workflow similar to other Lisp-related
Emacs modes.  For instance, it relies on the interaction between the user and
the REPL to load information needed.  The interaction is currently based on
Emacs built-in Scheme inferior-mode.  So, for instance, in order to load the
current buffer you can just issue C-c C-l.  Since the REPL is connected to the
LSP server, this will allow it to fetch symbols defined in the buffer, as well
as libraries imported by it.
