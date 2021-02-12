
This extension features are
- Easily and quickly edit ticket of various bug tracking systems using a unified widget interface
- List up ticket summaries with the combination of multiple conditions at one time
- Edit the listed multiple tickets at one time

You are able to create/update the tickets of a bug tracking system by the following steps.
1. create projects for the system
2. create queries belongs to the project
3. List up the summaries of the fetched tickets from the queries
4. Open details of the tickets, change the properties, and submit them.

* Project means a access configuration for the system stores target tickets data
* Query means a configuration detects the fetched tickets in the tickets belongs to the project
* For handling project, there are `bts:project-new'/`bts:project-update'
* For handling query, there are `bts:query-new'/`bts:query-update'
* For handling ticket, there are `bts:ticket-new'/`bts:summary-open'
* For key binding in widget buffer, see `bts:widget-common-keymap'
* For checking other functions, see API section below
* For use of this extension, it needs to install the system package (eg. bts-github is for GitHub).

For more infomation, see <https://github.com/aki2o/emacs-bts/blob/master/README.md>

; Dependencies:

- widget-mvc.el ( see <https://github.com/kiwanami/emacs-widget-mvc> )
- log4e.el ( see <https://github.com/aki2o/log4e> )
- yaxception.el ( see <https://github.com/aki2o/yaxception> )
- dash.el ( see <https://github.com/magnars/dash.el> )
- s.el ( see <https://github.com/magnars/s.el> )
- pos-tip.el

; Installation:

Put this to your load-path.
And put the following lines in your .emacs or site-start.el file.

(require 'bts)

; Configuration:

;; Key Binding
(global-unset-key (kbd "M-b"))
(global-set-key (kbd "M-b n")   'bts:ticket-new)
(global-set-key (kbd "M-b s")   'bts:summary-open)
(global-set-key (kbd "M-b p n") 'bts:project-new)
(global-set-key (kbd "M-b p u") 'bts:project-update)
(global-set-key (kbd "M-b p d") 'bts:project-remove)
(global-set-key (kbd "M-b p D") 'bts:project-remove-all)
(global-set-key (kbd "M-b q n") 'bts:query-new)
(global-set-key (kbd "M-b q u") 'bts:query-update)
(global-set-key (kbd "M-b q d") 'bts:query-remove)
(global-set-key (kbd "M-b q D") 'bts:query-remove-all)

;; About other config item, see Customization or eval the following sexp.
;; (customize-group "bts")

; Customization:

[EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "bts:[^:]" :docstring t)
`bts:project-cache-file'
Filepath stores user project configurations.
`bts:query-cache-file'
Filepath stores user query configurations.
`bts:preferred-selection-method'
Symbol for a preferred feature used for various selection flow.
`bts:widget-menu-minibuffer-flag'
Value for `widget-menu-minibuffer-flag' in BTS widget buffer.
`bts:widget-label-format'
Format of label part in BTS widget buffer.
`bts:widget-label-prefix'
Prefix of label part in BTS widget buffer.
`bts:widget-label-suffix'
Suffix of label part in BTS widget buffer.
`bts:widget-require-mark'
String as a mark of requirement in BTS widget buffer.
`bts:ticket-fetch-check-interval'
Seconds as interval to check the finish of fetching ticket.
`bts:ticket-multi-view-preferred'
Whether to open a multi view if marked entry is multiple in summary buffer.

 *** END auto-documentation
