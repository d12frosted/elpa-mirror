hyperdrive.el integrates with `hyper-gateway' for sharing files on the
https://hypercore-protocol.org network.

;; Installation:

;;; Dependencies

;;;; hyper-gateway

hyperdrive.el relies on
[hyper-gateway](https://github.com/RangerMauve/hyper-gateway/) for
talking to the hypercore network.

Download or compile the hyper-gateway
(https://github.com/RangerMauve/hyper-gateway/releases) binary and
ensure that it is executable and in your $PATH.

Ensure that `hyperdrive-hyper-gateway-command' is set to the name
you gave to the `hyper-gateway` binary.  One way to do this is by
renaming the binary to `hyper-gateway`, the default value for
`hyperdrive-hyper-gateway-command'.

;;;; plz.el

hyperdrive.el uses [plz.el](https://github.com/alphapapa/plz.el) for sending HTTP requests to hyper-gateway.

;;;; compat.el

hyperdrive.el relies on [compat.el](https://github.com/emacs-compat/compat) to support Emacs versions prior to Emacs 29.

;;; Manual

Clone this repository:

git clone https://git.sr.ht/~ushin/hyperdrive.el/ ~/.local/src/hyperdrive.el/

Add the following lines to your init.el file:

(add-to-list 'load-path "~/.local/src/hyperdrive.el")
(require 'hyperdrive)
