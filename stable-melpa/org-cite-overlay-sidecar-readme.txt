
This is meant to replace `org-cite-sidecar'
(https://melpa.org/#/org-cite-sidecar), and will integrate with
`org-cite-overlay'.  Similar to the former, it will show formatted
org-cite citations in the sidecar, however, if `org-cite-overlay'
is in use, the processor it fills will be used (reducing the amount
of computation performed).  Because it is compatible with buffers
not using `org-cite-overlay-mode', it is also necessary to
configure universal-sidecar-citeproc, as shown:

(setq universal-sidecar-citeproc-locales "~/.emacs.d/csl-data/locales/"
      ;; set to your directories for locale and style data
      universal-sidecar-citeproc-styles "~/.emacs.d/csl-data/styles/")
(add-to-list 'universal-sidecar-sections 'org-cite-overlay-sidecar)

Additionally, there are two arguments to the section which are not
exposed as customization variables:

- `:style' allows you to select a prefered CSL style within
  `universal-sidecar-citeproc-styles'.  Default is
  `universal-sidecar-citeproc-default-style'.
- `:header' allows you to change the header of the section from the
  default "References".
