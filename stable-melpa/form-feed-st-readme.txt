This minor mode displays page delimiters which usually appear as ^L
glyphs on a single line as horizontal lines spanning the entire
window.  It is suitable for inclusion into mode hooks and is
intended to be used that way.  The following snippet would enable
it for Emacs Lisp files for instance:

    (add-hook 'emacs-lisp-mode-hook 'form-feed-st-mode)

Forked from Vasilij Schneidermann's form-feed:
https://depp.brause.cc/form-feed/
https://github.com/wasamasa/form-feed (archived)

In comparison to it, this fork does not have configurable line
width; however it always displays correctly, even if you have
multiple windows showing the same buffer, and will never cause side
scrolling since the form feed only occupies two spaces.  It will
also only affect form feeds in the beginning of the line, which to
me is a feature since it does not hide any undesired characters
after the form feed, making them easy to notice and remove.
