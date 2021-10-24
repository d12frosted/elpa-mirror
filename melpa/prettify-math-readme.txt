Prettify math is a EMACS minor mode to prettify math formulas.

It's base on mathjax, refer mathjax for math formula related
stuffs.  Default math formula delimiters: $$ -> tex math, ` ->
asciimath.

Prerequisite
  nodejs - used to run mathjax, simple installation refer:
    https://nodejs.dev/download/package-manager

Installation
  install `prettify-math` from melpa

Usage
  enable prettify-math-mode in your buffer, or globally via
  global-prettify-math-mode.

Customization
  You can customize delimiter before this module loaded.
  Code example in init.el:
  (setq prettify-math-delimiters-alist '(("$" tex)
   (("\\(" . "\\)") tex block)
   ("`" asciimath)
   ("``" asciimath block)))
  (require 'prettify-math)
