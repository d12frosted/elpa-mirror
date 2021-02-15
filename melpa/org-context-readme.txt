This package advises `org-capture' and `org-agenda' to allow
contextual capture templates and agenda commands.

See documentation on https://github.com/thisirs/org-context#org-context

; Installation:

Put the following in your .emacs:

(require 'org-context)
(org-context-mode +1)

and customize `org-context-capture-alist' and `org-context-capture'
for contextual captures and `org-context-agenda-alist'
`org-context-agenda' for custom commands.
