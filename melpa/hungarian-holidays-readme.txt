; This package adds Hungarian (https://en.wikipedia.org/wiki/Hungary)
; public holidays to the Emacs calendar.
;
; If you have `org-agenda-include-diary` set to `t`, these will be
; also listed in the `org-agenda` view.

; Installation

; This package is available on MELPA, just `M-x` `package-install`
; `hungarian-holidays`. If you want to install it manually, clone
; this repository somewhere, add it to `load-path`, and add
; `(require 'hungarian-holidays)` to `.emacs`.

; Configuration

; Add a call to `(hungarian-holidays-add)` somewhere in your
; `.emacs`.  Note that this must be called *before* Emacs calendar
; is loaded.

; Attribution

; This package is based on David Chkhikvadze’s `czech-holidays'
; package.
