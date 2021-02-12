
Another stab at making braces and quotes pair like in
TextMate:

* Opening braces/quotes are autopaired;
* Closing braces/quotes are autoskipped;
* Backspacing an opening brace/quote autodeletes its adjacent pair.
* Newline between newly-opened brace pairs open an extra indented line.

Autopair deduces from the current syntax table which characters to
pair, skip or delete.

; Installation:

  (require 'autopair)
  (autopair-global-mode) ;; to enable in all buffers

To enable autopair in just some types of buffers, comment out the
`autopair-global-mode' and put autopair-mode in some major-mode
hook, like:

(add-hook 'c-mode-common-hook #'(lambda () (autopair-mode)))

Alternatively, do use `autopair-global-mode' and create
*exceptions* using the `autopair-dont-activate' local variable (for
emacs < 24), or just using (autopair-mode -1) (for emacs >= 24)
like:

(add-hook 'c-mode-common-hook
          #'(lambda ()
            (setq autopair-dont-activate t)
            (autopair-mode -1)))

