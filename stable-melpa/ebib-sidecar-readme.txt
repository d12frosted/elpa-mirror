
This package can be used to show a formatted reference to the bib
entry at point in `ebib'.  This is done using the `citeproc'
library and can be flexibly configured.  Handling of locale and
style management is performed using `universal-sidecar-citeproc',
and its variables (`universal-sidecar-citeproc-styles' and
`universal-sidecar-citeproc-locales') must be configured.

A minimum configuration is shown as follows:

    ;; set to your directories for locale and style data
    (setopt universal-sidecar-citeproc-locales "~/.emacs.d/csl-data/locales/"
            universal-sidecar-citeproc-styles "~/.emacs.d/csl-data/styles/")
    (add-to-list 'universal-sidecar-sections 'ebib-sidecar)

Additionally, there are two arguments to the section which are not
exposed as customization variables:

- `:style' allows you to select a prefered CSL style to override
  `universal-sidecar-citeproc-default-style'.
- `:header' allows you to change the header of the section from the
  default "References".
