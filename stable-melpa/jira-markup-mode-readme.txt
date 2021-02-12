Jira-markup-mode provides a major mode for editing JIRA wiki markup
files. Unlike jira.el it does not interact with JIRA.

The code is based on markdown-mode.el, a major for mode for editing
markdown files.
https://confluence.atlassian.com/display/DOC/Confluence+Wiki+Markup

; Dependencies:

jira-markup-mode requires easymenu, a standard package since GNU Emacs
19 and XEmacs 19, which provides a uniform interface for creating
menus in GNU Emacs and XEmacs.

; Installation:

Make sure to place `jira-markup-mode.el` somewhere in the load-path and add
the following lines to your `.emacs` file to associate jira-markup-mode
with `.text` files:

    (autoload 'jira-markup-mode "jira-markup-mode"
       "Major mode for editing JIRA markup files" t)
    (setq auto-mode-alist
       (cons '("\\.text" . jira-markup-mode) auto-mode-alist))


; Acknowledgments:

Jira-markup-mode has benefited greatly from the efforts of the
developers of markdown-mode.  Markdown-mode was developed and is
maintained by Jason R. Blevins <jrblevin@sdf.org>.  For details
please refer to http://jblevins.org/projects/markdown-mode/
