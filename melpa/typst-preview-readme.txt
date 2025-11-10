This package implements live typst preview using
https://github.com/Myriad-Dreamin/tinymist

;; Installation

;;; MELPA

Currently not on Melpa

;;; Manual

Install the tinymist binary from
https://github.com/Myriad-Dreamin/tinymist/releases
and make sure it's in your $PATH. To test this, create test.typ and run
typst-preview test.typ


Include typst-preview.el in your load-path, and put this in your init
file:

(require 'typst-preview)

;; Usage

Run typst-preview-mode and typst-preview-start in a typst buffer.

;; Tips

+ You can customize settings in the typst-preview group.
