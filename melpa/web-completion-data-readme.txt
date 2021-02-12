This is just dependency for ac-html, company-web

`web-completion-data-sources' is pair list of framework-name and directory of completion data

This package provide default "html" completion data.

Completion data directory structure:

html-attributes-complete - attribute completion
html-attributes-list - attributes of tags-add-tables
html-attributes-short-docs - attributes documantation
html-tag-short-docs  - tags documantation

If you decide extend with own completion data, let say "Bootstrap" data:

(unless (assoc "Bootstrap" web-completion-data-sources)
  (setq web-completion-data-sources
        (cons (cons "Bootstrap" "/path/to/complete/data")
              web-completion-data-sources)))
