This package extends `org-re-reveal' with support for a
bibliography slide based on package `org-ref'.  Thus, `cite'
commands of `org-ref' are translated into hyperlinks to the
bibliography slide upon export by `org-re-reveal'.  Also, export to
PDF via LaTeX and export to HTML with Org's usual export
functionality work.

* Install
0. Install reveal.js: https://revealjs.com/
1. Install org-re-reveal and org-re-reveal-ref, either from MELPA
   or GitLab:
   - https://gitlab.com/oer/org-re-reveal/
   - https://gitlab.com/oer/org-re-reveal-ref/
   (a) Place their directories into your load path or install from MELPA
       (https://melpa.org/#/getting-started).
   (b) Load package manually ("M-x load-library" followed by
       "org-re-reveal-ref") or place "(require 'org-re-reveal-ref)" into
       your ~/.emacs and restart.
2. Load an Org file and export it to HTML.
   (a) Make sure that reveal.js is available in your current directory
       (e.g., as sub-directory or symbolic link).
   (b) Load "README.org" (coming with org-re-reveal-ref).
   (c) Export to HTML: Key bindings depend upon version of org-re-reveal.
       Starting with version 1.0.0, press "C-c C-e v v" (write HTML file)
       or "C-c C-e v b" (write HTML file and open in browser)

* Customizable options
Customizable variables are `org-re-reveal-ref-bib' and
`org-re-reveal-ref-class'.
The value of `org-re-reveal-ref-bib' is used to generate hyperlinks
to the bibliography.  You must use its value as CUSTOM_ID on your
bibliography slide.
The value of `org-re-reveal-ref-class' is assigned as class
attribute of hyperlinks to the bibliography slide.
Furthermore, the following variables of `org-ref' are changed by
this package:
- `org-ref-bib-html' is set to the empty string
- `org-ref-bib-html-sorted' is set to t
- `org-ref-printbibliography-cmd' is configured not to produce a
  heading (as the bibliography slide has a heading already)
- `org-ref-ref-html' is configured to link to the bibliography
