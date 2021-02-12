This minor mode displays page delimiters which usually appear as ^L
glyphs on a single line as horizontal lines spanning the entire
window.  It is suitable for inclusion into mode hooks and is
intended to be used that way.  The following snippet would enable
it for Emacs Lisp files for instance:

    (add-hook 'emacs-lisp-mode-hook 'form-feed-mode)

See the README for more info: https://depp.brause.cc/form-feed
