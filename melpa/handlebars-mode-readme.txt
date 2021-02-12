1) Copy this file somewhere in your Emacs `load-path'.  To see what
   your `load-path' is, run inside emacs: C-h v load-path<RET>

2) Add the following to your .emacs file:

   (require 'handlebars-mode)

The indentation still has minor bugs due to the fact that
templates do not require valid HTML.

It would be nice to be able to highlight attributes of HTML tags,
however this is difficult due to the presence of CTemplate symbols
embedded within attributes.
