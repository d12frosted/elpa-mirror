
 The `universal-sidecar-citeproc' library simplifies the use of
`citeproc.el' to format citation data.  To this end, the
`universal-cidecar-citeproc' customization group allows
citeproc-related paths to be set once and easily reused (in
particular, it is important to remind users to set the
`universal-sidecar-citeproc-locales' and
`universal-sidecar-citeproc-styles' variables).  Additionally, it
provides a single place for users to set their default preferred
citation style (as an absolute path, or relative to
`universal-sidecar-citeproc-styles').

Users are encouraged to customize in the following pattern.

   (setopt universal-sidecar-citeproc-locales "~/citeproc/locales/"
           universal-sidecar-citeproc-styles "~/citeproc/styles/"
           universal-sidecar-citeproc-default-style "ieee.csl")

For developers, there are two main functions,
`universal-sidecar-citeproc-get-processor' and
`universal-sidecar-citeproc-org-output'.  The former will create a
citation processor (see `citeproc' library documentation) from a
list of data sources, and style/locale information.  The latter
will take a processor and generate an `org-mode' formatted (and
fontified) string for insertion into a sidecar.  These may be used
as follows:

    (defun demo-citeproc-formatter (keys bibliography)
      (let ((processor (universal-sidecar-citeproc-get-processor bibliography)))
        (citeproc-add-uncited keys processor)
        (universal-sidecar-citeproc-org-output processor)))
