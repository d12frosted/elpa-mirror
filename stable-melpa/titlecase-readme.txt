This library strives to be the most accurate possible with title-casing
sentences, lines, and regions of text in English prose according to a number
of styles guides' capitalization rules.  It is necessarily a best-effort; due
to the vaguaries of written English it's impossible to completely correctly
capitalize aribtrary titles.  So be sure to proofread and copy-edit your
titles before sending them off to be published, and never trust a computer.

INSTALLATION and USE:

Make sure both titlecase.el and titlecase-data.el are in your `load-path',
and `require' titlecase.  You should then be able to call the interactive
functions defined in this file.

; CUSTOMIZATION:

Only two customization options are probably going to be of any interest:
`titlecase-style' (the style to use for capitalizing titles), and
`titlecase-dwim-non-region-function', which determines what to do when
`titlecase-dwim' isn't acting on a region.

If you want to use your own title-casing code, or a third party, you can
customize `titlecase-command' to something other than its default.  One
possibility is titlecase.pl, written John Gruber and Aristotle Pagaltzis:
https://github.com/ap/titlecase.
