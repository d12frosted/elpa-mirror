This is a fuzzy Emacs completion style similar to the built-in
`flex' style, but using `flx' for scoring.  It also supports various other
fuzzy scoring systems in place of `flx'.

This package is intended to be used with packages that leverage
`completion-styles', e.g. `completing-read' and
`completion-at-point-functions'.

It is usable with `icomplete' (as well as `fido-mode'), `selectrum',
`vertico', `corfu', `helm' and `company-mode''s `company-capf'.

It is not currently usable with `ivy' or `ido' which don't yet support
`completion-styles' and have their own sorting and filtering systems.
In addition to those packages, other `company-mode' backends will not hook
into this package.

To use this style, prepend `fussy' to `completion-styles'.

For improved performance,`fussy-filter-fn' and `fussy-score-fn' for filtering
and scoring matches are good initial starting points for customization.

The various available matching algorithms in `fussy-score-fn' have varying
levels of performance and match quality.
For a faster version that implements the same matching as `flx', use
https://github.com/jcs-elpa/flx-rs which is a native module written in Rust.

For other matching algorithms, take a look at
https://github.com/jojojames/fussy#scoring-backends
