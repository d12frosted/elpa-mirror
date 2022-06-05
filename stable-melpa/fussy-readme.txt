This is a fuzzy Emacs completion style similar to the built-in
`flex' style, but using `flx' for scoring.  It also supports various other
fuzzy scoring systems in place of `flx'.

This package is intended to be used with packages that leverage
`completion-styles', e.g. `completing-read' and
`completion-at-point-functions'.

It is usable with `icomplete' (as well as `fido-mode'), `selectrum',
`vertico', `corfu', `helm' and `company-mode''s `company-capf'.

It is not currently usable with `ido' which doesn't support
`completion-styles' and has its own sorting and filtering system.  In
addition to those packages, other `company-mode' backends will not hook into
this package.  `ivy' support can be somewhat baked in following
https://github.com/jojojames/fussy#ivy-integration but the
performance gains may not be as high as the other `completion-read' APIs.

To use this style, prepend `fussy' to `completion-styles'.

For improved performance,`fussy-filter-fn' and `fussy-score-fn' for filtering
and scoring matches are good initial starting points for customization.

The various available scoring backends in `fussy-score-fn' have varying
levels of performance and match quality.
For a faster version that implements the same matching as `flx', use
https://github.com/jcs-elpa/flx-rs which is a native module written in Rust.

Other notable scoring backends supported by this package:
flx: https://github.com/lewang/flx
fzf: https://github.com/junegunn/fzf
skim: https://github.com/lotabout/fuzzy-matcher

For an exhaustive list of scoring backends, take a look at
https://github.com/jojojames/fussy#scoring-backends
