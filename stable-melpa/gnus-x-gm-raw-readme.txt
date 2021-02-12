
This extension searches mail of Gmail using X-GM-RAW as web interface.
You can use this function naturally in the search by `gnus-group-make-nnir-group'.

For more infomation, see <https://github.com/aki2o/gnus-x-gm-raw/blob/master/README.md>

; Dependencies:

- yaxception.el ( see <https://github.com/aki2o/yaxception> )
- log4e.el ( see <https://github.com/aki2o/log4e> )

; Installation:

Put this to your load-path.
And put the following lines in your .emacs or site-start.el file.

(require 'gnus-x-gm-raw)

; Configuration:

Nothing.

; Customization:

[EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "gnus-x-gm-raw:" :docstring t)
`gnus-x-gm-raw:imap-server'
IMAP server of Gmail

 *** END auto-documentation
