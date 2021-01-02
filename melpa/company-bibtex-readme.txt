; `company-bibtex' provides a backend for the
; company-mode framework, enabling completion of bibtex keys in
; modes used for prose writing.  This backend activates for citation
; styles used by `pandoc-mode' (@), `latex-mode' (\cite{}), and
; `org-mode' (ebib:).
;
; Load the package and add it to the company-backends:
;
;  (require 'company-bibtex)
;  (add-to-list 'company-backends 'company-bibtex)
;
; `company-bibtex' reads from a bibliography file or files
; specified in `company-bibtex-bibliography'.  For example:
;
;   (setq company-bibtex-bibliography
;    '("/home/cooluser/thesis/thesis1.bib"
;      "/home/cooluser/thesis/thesi2.bib"))
;
; The regular expression matching key names alphanumeric characters,
; dashes (-), and underscores (_).  This is customizable via
; `company-bibtex-key-regex'.  For example:
;
;  (setq company-bibtex-key-regex "[[:alnum:]+_]*")
;
