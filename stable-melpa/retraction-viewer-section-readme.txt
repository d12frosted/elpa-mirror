
Retraction data from `retraction-viewer' may be shown in the
`universal-sidecar'
(https://git.sr.ht/~swflint/emacs-universal-sidecar) as follows.

    (require 'retraction-viewer-section)
    (add-to-list 'universal-sidecar-sections 'retraction-viewer-section)

There are three main options for configuration.  First is the
customizable variable, `retraction-viewer-section-modes', which
specifies the modes in which the sidecar is applicable (its default
is bibtex mode and ebib-related modes).  Second is the notice
format string keyword argument, `:format-string', which is a format
string as described above.  Finally, the bullet character can be
modified with the `:prepend-bullet' argument, which should be a
valid org-mode bullet (useful for users of `org-bullets' or
`org-superstar').
