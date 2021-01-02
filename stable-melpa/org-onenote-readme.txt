; Summary
this package provides org-mode buffer to onenote exporting, images and code
highlighting are supported.

; Usage
before post your document to onenote, you need grant access to org-onenote for
accessing your onenote by invoke `org-onenote-start-authenticate`.

to specify which section your org document will post to, you need add custom org
keyword "ONENOTE-SECTION" to it.  eg.

#+ONENOTE-SECTION: Frei's Notebook/Tech Notes/Common

org-onenote will look up section id from `org-onenote-section-map` by your
specified section, which can be generate by `onenote-insert-section-map-at-pt`
eg.

(setq org-onenote-section-map '(("Frei's Notebook/Programming Language/C++"
. "THE-ID")))

to post your document by invoke `org-onenote-submit-page`, server side note id
will be recorded after a successful post.  You can delete it by invoke
`org-onenote-delete-page`

; TODO: patch
