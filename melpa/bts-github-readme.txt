
Nothing.

; Dependencies:

- bts.el ( see <https://github.com/aki2o/emacs-bts> )
- gh.el ( see <https://github.com/sigma/gh.el> )

; Installation:

Put this to your load-path.
And put the following lines in your .emacs or site-start.el file.

(require 'bts-github)

; Configuration:

;; About config item, see Customization or eval the following sexp.
;; (customize-group "bts-github")

; Customization:

[EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "bts-github:[^:]" :docstring t)
`bts-github:ignore-labels'
List of label name applied `bts:summary-ignored-ticket-face'.
`bts-github:max-specpdl-size'
Number for `max-specpdl-size' changed for fetching big data temporarily.
`bts-github:max-lisp-eval-depth'
Number for `max-lisp-eval-depth' changed for fetching big data temporarily.
`bts-github:summary-id-width'
Width of issue ID column in summary buffer.
`bts-github:summary-label-width'
Width of issue labels column in summary buffer.
`bts-github:summary-label-decorating'
Whether to decorate issue labels column.

 *** END auto-documentation
