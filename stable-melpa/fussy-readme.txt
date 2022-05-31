This is a fuzzy Emacs completion style similar to the built-in
`flex' style, but using `flx' for scoring.  It also supports various other
fuzzy scoring systems in place of `flx'.

This package is intended to be used with packages that leverage
`completion-styles', e.g. `completing-read' and
`completion-at-point-functions'.
It is usable with `icomplete' (as well as `fido-mode'), `selectrum',
`vertico', `corfu', and `company-mode''s `company-capf'.
It is not intended to be used in `ivy', `ido', or `helm' which have their
own sorting and filtering systems.

To use this style, prepend `fussy' to `completion-styles'.
To speed up `flx' matching, use https://github.com/jcs-elpa/flx-rs which is
native module designed to speed up scoring matches that scores based off the
original `flx' algorithm.
For other matching algorithms, take a look at
https://github.com/jojojames/fussy#scoring-backends
