This minor-mode highlights leading spaces with a face and replaces them
with a special character so they can easily be counted (this can be
disabled).

The whitespace.el package that is built-in to Emacs
(http://www.emacswiki.org/emacs/WhiteSpace) can be used to accomplish the
same effect, but for *all* spaces, including non-leading spaces between
words.  This minor-mode only highlights leading spaces that are part of the
indentation.

The face to highlight leading spaces with can be customised by changing the
highlight-leading-spaces face.  The character to replace leading spaces
with can be customised by changing `highlight-leading-spaces-char'.  If you
do not wish to them to be replaced with a special character, set it to a
space.

Suggested usage:

    (add-hook 'prog-mode-hook 'highlight-leading-spaces-mode)

This minor-mode is quite efficient because it doesn't use overlays but text
properties for the leading spaces.  Furthermore, the highlights are
correctly and efficiently kept up-to-date by plugging in to font-lock, not
by adding various hooks.
