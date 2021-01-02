Perform an interactive reverse variable lookups for Emacs Lisp using Helm.
Once the helm entry is selected, the variable is opened in
either `describe-variable', or `helpful-variable', if it's installed.

; Commands

`helm-atoms' Open the helm interface

; Customization

`helm-atoms-search-sequences'
Search atoms bound to sequences (lists, vectors) if non-nil.
More thorough search, but worse performance.
