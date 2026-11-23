This package bridges the gap between YASnippet and autoinsert.  By
populating `auto-insert-alist' with YASnippet templates and automatically
expanding their content after insertion using `auto-insert-mode'.  It's an
easy way to create dynamic file templates.  Simply turn on
`yas-autoinsert-mode' global minor mode and call
`yas-autoinsert-register-all' somewhere in your Emacs initialization file to
populate `auto-insert-alist' with templates from YASnippet directories.

Of course, you will need to enable `auto-insert-mode' to have the snippet
inserted and expanded into new files.

Each template with `autoinsert' in its `group' property will be turned into a
new element to `push' onto `auto-insert-alist'.  Its `condition' property
will become the conditions for insertion and expansion of the template and
must conform to the syntax alowed by autoinsert for the `car' of
`auto-insert-alist' ie :

condition            <- "'" ? (single-conditon / condition-list)
condition-list       <- "(" single-conditon * ")"
single-condition     <- "'" ? (simple-condition / documented-condition)
documented-condition <- "(" simple-condition . description ")"
simple-condition     <- string-regexp / major-mode-symbol
description          <- string

The autoinsert `action' will be a vector of actions that first inserts the
content of the template and then expands the content of the buffer
with `yas-expand-snippet', so you can use everything YASnippet offers in the
template.

If a condition list is given, each condition will be inserted in order along
with the same action.
If you do not specify a condition, it will be determined by the snippet's
major mode.

To guarantee a particular order, snippets are grouped by mode and then
inserted onto `auto-insert-alist' in lexicographic order (according to
`string-lessp') taking their `name' property as key for the sort.  The order
of insertion for snippets of different modes is random.

This means that a snippet directory looking like this:

snippets
├── emacs-lisp-mode
│   ├── `all' <`name: ALL' and `condition: "*.el"'>
│   └── `init' <`name: init' and `condition: "init.el"'>
└── python-mode
    ├── `all' <`name: ALL' and `condition: "*.py"'>
    └── `init' <`name: init' and `condition: "__init__.py"'>

will results to situations where init templates will be inserted before ALL
ones for example :

         (("init.el" . ACTION)
          ("*.el" . ACTION)
          ("__init__.py" . ACTION)
          ("*.py" . ACTION))

since upper case names will have higher numerical value than lower case ones.

Finally, whenever you save your snippet using the usual YASnippet mechanisms,
your `autoinsert' templates will load into `auto-insert-alist'.

TL;DR:

  Basic steps to setup (assuming yasnippet is enabled):

   (require 'yasnippet)
   (auto-insert-mode +1)
   (require 'yas-autoinsert)
   (yas-autoinsert +1)
   (yas-autoinsert-register-all)

  Snippet examples:

    Simple regexp condition

      # -*- mode: snippet -*-
      # name: README
      # key: readme
      # group: autoinsert
      # condition: "\\`README\\(\\.org\\)?\\'"
      # --
      #+title:  README
      #+date:   ${1:`(format-time-string \"%Y-%m-%d\")`}

      * $2
      ** Getting started

      $0

    Major-mode condition:

      # -*- mode: snippet -*-
      # name: ORG
      # key: org
      # group: autoinsert
      # condition: 'org-mode
      # --
      #+title:  ${1:Example Org File}
      #+date:   ${2:`(format-time-string "%Y-%m-%d")`}

      * $0

    Documented condition:

      # -*- mode: snippet -*-
      # name: guix-channel
      # key: .gc
      # group: autoinsert
      # condition: ("\\.guix-channel\\'" ."Guix channel definition template")
      # --
      ;; -*- mode: scheme; coding: utf-8 -*-
      ;; SPDX-License-Identifier: GPL-3.0-or-later

      (channel
       (version 0)
       (keyring-reference "${1:keyring}")
       (url "https://gitlab.com/rchastel1/${2:
            `(file-name-base
               (directory-file-name
                 (file-name-directory buffer-file-name)))`}.git")
       $0)

    Condition list:

      # -*- mode: snippet -*-
      # name: R6RS
      # key: r6
      # group: autoinsert
      # condition: (("\\.sls\\'" . "R6RS scheme template") scheme-mode)
      # --
      ;; -*- mode: scheme; coding: utf-8 -*-
      ;; SPDX-License-Identifier: GPL-3.0-or-later

      #!r6rs

      (library ($1)
        (export )
        (import
          (rnrs (6))
          $2)

        $0
        )
