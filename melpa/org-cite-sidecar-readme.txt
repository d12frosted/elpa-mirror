
This package can be used to show an Org-Mode document's citations
in `universal-sidecar'.  This is done through the use of `citeproc'
and can be shown quite flexibly.  A minimum configuration is as
follows:

(setq universal-sidecar-citeproc-locales "~/.emacs.d/csl-data/locales/"
      ;; set to your directories for locale and style data
      universal-sidecar-citeproc-styles "~/.emacs.d/csl-data/styles/")
(add-to-list 'universal-sidecar-sections 'org-cite-sidecar)

It is important to set the `universal-sidecar-citeproc-locales' and
`universal-sidecar-citeproc-styles' variables to the directories
where you have cloned the CSL locale and style data repositories
(see docstrings for links).

Additionally, there are two arguments to the section which are not
exposed as customization variables:

- `:style' allows you to select a prefered CSL style within
  `universal-sidecar-citeproc-styles'.  Default is
  `universal-sidecar-citeproc-default-style'.
- `:header' allows you to change the header of the section from the
  default "References".
