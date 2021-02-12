The second edition of the book Structure and Interpretation of
Computer Programs (SICP) in info format.

This library provides the feature `sicp' and does nothing else.
This allows making the info file available on Melpa.  The texi
file was taken from http://www.neilvandyke.org/sicp-texi.  The
html version can be found at https://mitpress.mit.edu/sicp.

If you want to recreate the info file, you can do so using

  makeinfo -–no-split sicp.texi -o sicp.info
