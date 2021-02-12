
`ace-isearch.el' provides a minor mode that combines `isearch',
`ace-jump-mode', `avy', `helm-swoop' and `swiper'.

The "default" behavior (`ace-isearch-jump-based-on-one-char' t) can be
summarized as:

L = 1     : `ace-jump-mode' or `avy'
1 < L < 6 : `isearch'
L >= 6    : `helm-swoop' or `swiper'

where L is the input string length during `isearch'.  When L is 1, after a
few seconds specified by `ace-isearch-jump-delay', `ace-jump-mode' or `avy'
will be invoked. Of course you can customize the above behaviour.

If (`ace-isearch-jump-based-on-one-char' nil), L=2 characters are required
to invoke `ace-jump-mode' or `avy' after `ace-isearch-jump-delay'. This has
the effect of doing regular `isearch' for L=1 and L=3 to 6, with the ability
to switch to 2-character `avy' or `ace-jump-mode' (not yet supported) once
`ace-isearch-jump-delay' has passed. Much easier to do than to write about :-)

; Installation:

To use this package, add following code to your init file.

  (require 'ace-isearch)
  (global-ace-isearch-mode +1)
