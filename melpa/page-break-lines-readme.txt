This library provides a global mode which displays form feed
characters as horizontal rules.

Install from Melpa or Marmalade, or add to `load-path' and use
(require 'page-break-lines).

Use `page-break-lines-mode' to enable the mode in specific buffers,
or customize `page-break-lines-modes' and enable the mode globally with
`global-page-break-lines-mode'.

Issues and limitations:

If `page-break-lines-char' is displayed at a different width to
regular characters, the rule may be either too short or too long:
rules may then wrap if `truncate-lines' is nil.  On some systems,
Emacs may erroneously choose a different font for the page break
symbol, which choice can be overridden using code such as:

(set-fontset-font "fontset-default"
(cons page-break-lines-char page-break-lines-char)
(face-attribute 'default :family))

Use `describe-char' on a page break char to determine whether this
is the case.

Additionally, the use of `text-scale-increase' or
`text-scale-decrease' will cause the rule width to be incorrect,
because the reported window width (in characters) will continue to
be the width in the frame's default font, not the scaled font used to
display the rule.

Adapted from code http://www.emacswiki.org/emacs/PageBreaks
