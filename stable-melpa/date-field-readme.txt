
You'll be able to use a date widget by the following code

(widget-create 'date-field)

For more infomation, see <https://github.com/aki2o/emacs-date-field/blob/master/README.md>

; Dependencies:

- dash.el ( see <https://github.com/magnars/dash.el> )
- log4e.el ( see <https://github.com/aki2o/log4e> )
- yaxception.el ( see <https://github.com/aki2o/yaxception> )

; Installation:

Put this to your load-path.
And put the following lines in your elisp file.

(require 'date-field)

; Configuration:

Nothing.

; Customization:

[EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "date-field-[^-]" :docstring t)

 *** END auto-documentation
