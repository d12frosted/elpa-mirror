GNU Emacs major mode for editing Salt States.

Provides syntax highlighting, indentation, and jinja templating.

Syntax highlighting: Fontification supports YAML & Jinja using mmm-mode

Tag complete: Using mmm-mode you can generate insert templates:
C-c % {
  generates {{ _ }} with cursor where the underscore is
C-c % #
C-c % %
  for {# and {% as well.

In-Emacs documentation: ElDoc and help buffers are available
if you have Salt installed.
