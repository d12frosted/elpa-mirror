
Org Visibility is an Emacs package that adds the ability to persist (save
and load) the state of the visible sections of `org-mode' files.  The state
is saved when the file is saved or killed, and restored when the file is
loaded.

Hooks are used to persist and restore org tree visibility upon loading and
saving org files.  Whether or not a given buffer's file will have its
visibility persisted is determined by the following logic:

Qualification Rules:

Files are only considered if their buffer is an `org-mode' buffer and they
meet one of the following requirements:

  - File has buffer local variable `org-visibility' set to t

  - File is contained within one of the directories listed in
    `org-visibility-include-paths'

  - File path matches one of the regular expressions listed in
    `org-visibility-include-regexps'

Files are removed from consideration if they meet one of the following
requirements (overriding the above include logic):

  - File has buffer local variable `org-visibility' set to 'never

  - File is contained within one of the directories listed in
    `org-visibility-exclude-paths'

  - File matches one of the regular expressions listed in
    `org-visibility-exclude-regexps'.

Provides the following interactive functions:

  `org-visibility-save'             - Save visibility state for current buffer
  `org-visibility-force-save'       - Save even if buffer has not been modified
  `org-visibility-save-all-buffers' - Save all buffers that qualify
  `org-visibility-load'             - Load a file and restore its visibility state
  `org-visibility-clean'            - Cleanup `org-visibility-state-file'
  `org-visibility-enable-hooks'     - Enable all hooks
  `org-visibility-disable-hooks'    - Disable all hooks

Installation:

Put `org-visibility.el' where you keep your elisp files and add something
like the following to your .emacs file:

  ;; optionally change the location of the state file (not recommended)
  ;;(setq org-visibility-state-file `,(expand-file-name "/some/path/.org-visibility"))

  ;; list of directories and files to persist and restore visibility state of
  (setq org-visibility-include-paths `(,(file-truename "~/.emacs.d/init-emacs.org")
                                       ,(file-truename "~/org"))
  ;; persist all org files regardless of location
  ;;(setq org-visibility-include-regexps '("\\.org\\'"))

  ;; list of directories and files to not persist and restore visibility state of
  ;;(setq org-visibility-exclude-paths `(,(file-truename "~/org/old")))

  ;; optional maximum number of files to keep track of
  ;; oldest files will be removed from the sate file first
  ;;(setq org-visibility-maximum-tracked-files 100)

  ;; optional maximum number of days (since saved) to keep track of
  ;; files older than this number of days will be removed from the state file
  ;;(setq org-visibility-maximum-tracked-days 180)

  (require 'org-visibility)

  ;; enable all hooks (recommended)
  (org-visibility-enable-hooks)

  ;; optionally set a keybinding to force save
  (bind-keys :map org-mode-map
                  ("C-x C-v" . org-visibility-force-save)) ; defaults to `find-alternative-file'

Or, if using `use-package', add something like this instead:

  (use-package org-visibility
    :bind (:map org-mode-map
                ("C-x C-v" . org-visibility-force-save)) ; defaults to `find-alternative-file'
    :custom
    ;; list of directories and files to persist and restore visibility state of
    (org-visibility-include-paths `(,(file-truename "~/.emacs.d/init-emacs.org")
                                    ,(file-truename "~/org"))))
    ;; persist all org files regardless of location
    ;;(org-visibility-include-regexps '("\\.org\\'"))
    ;; list of directories and files to not persist and restore visibility state of
    ;;(org-visibility-exclude-paths `(,(file-truename "~/org/old")))
    ;; optional maximum number of files to keep track of
    ;; oldest files will be removed from the sate file first
    ;;(org-visibility-maximum-tracked-files 100)
    ;; optional maximum number of days (since saved) to keep track of
    ;; files older than this number of days will be removed from the state file
    ;;(org-visibility-maximum-tracked-days 180)
    :config
    ;; enable all hooks (recommended)
    (org-visibility-enable-hooks))

Usage:

As long as `org-visibility-enable-hooks' has been called, visibility state
is automatically persisted on file save or kill, and restored when loaded.
No user intervention is needed.  The user can, however, call
`org-visibility-force-save' to save the current visibility state of a
buffer before a file save or kill would automatically trigger it next.

Interactive commands:

The `org-visibility-save' function saves the current buffer's file
visibility state if it has been modified or had an `org-cycle' change, and
matches the above Qualification Rules.

The `org-visibility-force-save' function saves the current buffer's file
visibility state if it matches the above Qualification Rules, regardless of
whether the file has been modified.

The `org-visibility-save-all-buffers' function saves the visibility state
for any modified buffer files that match the above Qualification Rules.

The `org-visibility-load' function loads a file and restores its visibility
state if it matches the above Qualification Rules.

The `org-visibility-clean' function removes all missing or untracked files
from `org-visibility-state-file'.

The `org-visibility-enable-hooks' function enables all `org-visibility'
hooks so that it works automatically.

The `org-visibility-disable-hooks' function disables all `org-visibility'
hooks so that it is effectively turned off unless functions are manually
called.
