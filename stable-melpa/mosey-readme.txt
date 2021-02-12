Howdy.  Why don't ya mosey on in here.  Have yourself a sit-down.

`mosey' makes it easy to mosey back and forth in your buffers.
Just pass `mosey' a list of functions that move the point to
certain places, and it'll mosey the point between those places.
Tell it `:backward t' if you want to mosey on back, otherwise it'll
mosey on ahead.  Tell it to `:bounce t' if you want it to bounce
back a notch when it hits the end, and tell it to `:cycle t' if you
want it to loop around when it gets to one end or the other.

To make it easier for ya, just pass a list of point-moving
functions to `defmosey', and it'll cook up six functions:
`mosey-forward', `mosey-backward', `mosey-forward-bounce',
`mosey-backward-bounce', `mosey-forward-cycle', and
`mosey-backward-cycle'.  Then you can pick your fav-o-rite ones and
forget about the rest!

; Installation

Best thing to do is just mosey on over to http://melpa.org/ and
install the package called `mosey'.

But if you like gettin' your hands dirty, all you need to do is put
mosey.el in your `load-path' and then put this in your init file:

(require 'mosey)

...and then you can start moseying around.

; Usage

You can use these commands right off the bat to move within the
current line:

+ mosey-forward
+ mosey-backward
+ mosey-forward-bounce
+ mosey-backward-bounce
+ mosey-forward-cycle
+ mosey-backward-cycle

You might even want to rebind your keys to 'em, maybe like this:

(global-set-key (kbd "C-a") 'mosey-backward)
(global-set-key (kbd "C-e") 'mosey-forward)

...but that'd be even easier with `use-package' and its handy-dandy
`:bind*' form:

(use-package mosey
  :bind* (
          ;; My personal favorites
          ("C-a" . mosey-backward-bounce)
          ("C-e" . mosey-forward-bounce)
          ))

;; Make your own moseys

It's easy to make your own moseys with defmosey, somethin' like
this (this example uses functions from smartparens):

(defmosey '(beginning-of-line
            back-to-indentation
            sp-backward-sexp  ; Moves across lines
            sp-forward-sexp   ; Moves across lines
            mosey-goto-end-of-code
            mosey-goto-beginning-of-comment-text)
  :prefix "lisp")

That'll cook up six functions for ya:

+ mosey-lisp-forward
+ mosey-lisp-backward
+ mosey-lisp-forward-bounce
+ mosey-lisp-backward-bounce
+ mosey-lisp-forward-cycle
+ mosey-lisp-backward-cycle

Then maybe you'd want to use 'em in your `emacs-lisp-mode',
somethin' like this:

(bind-keys :map emacs-lisp-mode-map
           ("C-a" . mosey-lisp-backward-cycle)
           ("C-e" . mosey-lisp-forward-cycle))

; Credits

This package was inspired by Alex Kost's fantastic `mwim' package.
It has even more features, so check it out!
https://github.com/alezost/mwim.el
