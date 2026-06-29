               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                MATHJAX.EL — EMACS INTERFACE TO MATHJAX
               ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This package provides a method to display mathematical formulas in
Emacs.  It is mainly intended as a helper library to be used by other
packages, but also provides integration with some built-in Emacs
features.

[MathJax] is used as rendering engine.  The [Node] JavaScript runtime is
required (package `node' in many package managers), but all other
dependencies are bundled with mathjax.el.


[MathJax] <https://www.mathjax.org/>

[Node] <https://nodejs.org/en>


1 For users
═══════════

  As the end user, you can set up math rendering in EWW buffers with

  ┌────
  │ (add-hook 'eww-mode-hook #'mathjax-shr-setup)
  └────

  This is how your typical webpage might then look like:

  A possible future development could be the inclusion of a live preview
  mode for TeX, Org, etc.


2 For package authors
═════════════════════

  If you would like to use this library in your package, you first need
  to communicate to your users that Node is required to make math
  rendering work.

  The API is asynchronous, non-blocking and well oiled.  The basic entry
  point is `mathjax-render', which takes as input a callback function
  and a mathematical formula, which can be in either TeX, MathML or
  AsciiMath format.  MathJax runs in a subprocess and when it finishes,
  the callback is called with an SVG image as argument.

  The function `mathjax-display' provides a more high-level interface.
  It takes as argument a formula and a buffer region (which typically
  contains a plain-text rendition of the formula).  When rendering
  completes, an overlay is created in the indicated region to display
  the formula.

  Lastly, `mathjax-typeset-region' can be used when you have several
  formulas in a buffer region, delimited by the patterns stipulated in
  the `mathjax-delimiters' variable.

  In all cases, see the docstrings for complete details.
