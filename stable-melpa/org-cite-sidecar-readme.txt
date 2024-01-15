
This package can be used to show an Org-Mode document's citations
in `universal-sidecar'.  This is done through the use of `citeproc'
and can be shown quite flexibly.  A minimum configuration is as
follows:

(setq org-cite-sidecar-locales "~/.emacs.d/csl-data/locales/"
      ;; set to your directories for locale and style data
      org-cite-sidecar-styles "~/.emacs.d/csl-data/styles/")
(add-to-list 'universal-sidecar-sections 'org-cite-sidecar)

It is important to set the `org-cite-sidecar-locales' and
`org-cite-sidecar-styles' variables to the directories where you
have cloned the CSL locale and style data repositories (see
docstrings for links).

Additionally, there are two arguments to the section which are not
exposed as customization variables:

- `:style' allows you to select a prefered CSL style within
  `org-cite-sidecar-styles'.  Default is `ieee.csl'.
- `:header' allows you to change the header of the section from the
  default "References".
