
This package contains extra functions for multiple-cursors mode.

Here is a list of the interactive commands provided by mc-extras:

* mc/compare-chars
* mc/compare-chars-backward
* mc/compare-chars-forward
* mc/cua-rectangle-to-multiple-cursors
* mc/mark-next-sexps
* mc/mark-previous-sexps
* mc/move-to-column
* mc/rect-rectangle-to-multiple-cursors
* mc/remove-current-cursor
* mc/remove-cursors-at-eol
* mc/remove-duplicated-cursors

Suggested key bindings are as follows:

  (define-key mc/keymap (kbd "C-. M-C-f") 'mc/mark-next-sexps)
  (define-key mc/keymap (kbd "C-. M-C-b") 'mc/mark-previous-sexps)
  (define-key mc/keymap (kbd "C-. <") 'mc/mark-all-above)
  (define-key mc/keymap (kbd "C-. >") 'mc/mark-all-below)

  (define-key mc/keymap (kbd "C-. C-d") 'mc/remove-current-cursor)
  (define-key mc/keymap (kbd "C-. C-k") 'mc/remove-cursors-at-eol)
  (define-key mc/keymap (kbd "C-. d")   'mc/remove-duplicated-cursors)
  (define-key mc/keymap (kbd "C-. C-o") 'mc/remove-cursors-on-blank-lines)

  (define-key mc/keymap (kbd "C-. .")   'mc/move-to-column)
  (define-key mc/keymap (kbd "C-. =")   'mc/compare-chars)

  ;; Emacs 24.4+ comes with rectangle-mark-mode.
  (define-key rectangle-mark-mode-map (kbd "C-. C-,") 'mc/rect-rectangle-to-multiple-cursors)

  (define-key cua--rectangle-keymap   (kbd "C-. C-,") 'mc/cua-rectangle-to-multiple-cursors)

To enable interaction between multiple cursors and CUA rectangle
copy & paste:

  (mc/cua-rectangle-setup)
