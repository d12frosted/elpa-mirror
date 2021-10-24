This package extends `org-re-reveal' with support for a
bibliography slide based on package `citeproc' with citation
support of Org mode 9.5.  Thus, Org `cite' links are translated
into hyperlinks to the bibliography slide upon export by
`org-re-reveal'.  Also, export to PDF via LaTeX and export to
HTML with Org's usual export functionality work.

This package is an alternative to `org-re-reveal-ref'.
While the latter which relies on `org-ref', `org-re-reveal-citeproc'
supports the new Org mode syntax introduced in in Org mode 9.5.

* Install
0. Install prerequisites
   - reveal.js: https://revealjs.com/
   - *Recent* Org mode: https://orgmode.org/
   - citeproc-org: MELPA or https://github.com/andras-simonyi/citeproc-el
1. Install org-re-reveal and org-re-reveal-citeproc, either from MELPA
   or GitLab:
   - https://gitlab.com/oer/org-re-reveal/
   - https://gitlab.com/oer/org-re-reveal-citeproc/
   (a) Place their directories into your load path or install from MELPA
       (https://melpa.org/#/getting-started).
   (b) Load and configure org-re-reveal-citeproc.  E.g. place the following
       into your ~/.emacs and restart:
       (require 'org-re-reveal-citeproc)
       (add-to-list 'org-export-filter-paragraph-functions
               #'org-re-reveal-citeproc-filter-cite)
2. Load an Org file and export it to HTML.
   (a) Make sure that reveal.js is available in your current directory
       (e.g., as sub-directory or symbolic link).
   (b) Load "README.org", coming with org-re-reveal-citeproc:
       https://gitlab.com/oer/org-re-reveal-citeproc/-/blob/master/README.org
   (c) Export to HTML: Key bindings depend upon version of org-re-reveal.
       Starting with version 1.0.0, press "C-c C-e v v" (write HTML file)
       or "C-c C-e v b" (write HTML file and open in browser)

* Customizable options
The value of `org-re-reveal-citeproc-bib' is used to generate hyperlinks
to the bibliography.  You must use its value as CUSTOM_ID on your
bibliography slide.

Function org-re-reveal-citeproc-filter-cite makes sure that Org citations
point to the bibiography slide.  You should add
it to org-export-filter-paragraph-functions as shown above.
