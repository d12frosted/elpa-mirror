
A minor mode that remembers where the last paste occurred and provides the
command `mark-yank' to select it at any time later.

Use `mark-yank-global-mode' to enable this is in all buffers.

Immediately after yanking, you can press C-x C-x to activate the mark, but
this mode is useful for setting the same region even after you've moved
around and even made changes.

This mode does not bind any keys.  I recommend C-M-y which is unused, similar
to C-y used for yank, and similar to other C-M mark keys like C-M-SPC for
mark sexp.

IMPORTANT: Do not defer loading until you want to mark since the mode must be
enabled when the yank occurred so it can remember it.  For example, if you
are using use-package, `:bind' will defer loading the package until you press
the bound key.  Use `:demand' to load immediately.

   (use-package mark-yank
     :ensure t
     :demand t
     :bind ("C-M-y" . 'mark-yank)
     :config (mark-yank-global-mode 1))
