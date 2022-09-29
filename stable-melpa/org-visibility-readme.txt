
Org Visibility is an Emacs package that adds the ability to persist (save
and load) the state of the visible sections of `org-mode' files. The state
is saved when the file is saved or killed, and restored when the file is
loaded.

Hooks are used to persist and restore org tree visibility upon loading and
saving org files. Whether or not a given buffer's file will have its
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
  `org-visibility-remove'           - Remove current buffer from `org-visibility-state-file'
  `org-visibility-clean'            - Cleanup `org-visibility-state-file'
  `org-visibility-enable-hooks'     - Enable all hooks
  `org-visibility-disable-hooks'    - Disable all hooks

Installation:

Put `org-visibility.el' where you keep your elisp files and add something
like the following to your .emacs file:

  ;; optionally change the location of the state file
  ;;(setq org-visibility-state-file `,(expand-file-name "/some/path/.org-visibility"))

  ;; list of directories and files to persist and restore visibility state of
  (setq org-visibility-include-paths `(,(file-truename "~/.emacs.d/init-emacs.org")
                                       ,(file-truename "~/org"))
  ;; persist all org files regardless of location
  ;;(setq org-visibility-include-regexps '("\\.org\\'"))

  ;; list of directories and files to not persist and restore visibility state of
  ;;(setq org-visibility-exclude-paths `(,(file-truename "~/org/old")))

  ;; optionally set maximum number of files to keep track of
  ;; oldest files will be removed from the state file first
  ;;(setq org-visibility-maximum-tracked-files 100)

  ;; optionally set maximum number of days (since saved) to keep track of
  ;; files older than this number of days will be removed from the state file
  ;;(setq org-visibility-maximum-tracked-days 180)

  ;; optionally turn off visibility state change messages
  ;;(setq org-visibility-display-messages nil)

  (require 'org-visibility)

  ;; enable org-visibility-mode
  (org-visibility-mode 1)

  ;; optionally set a keybinding to force save
  (bind-keys* :map org-visibility-mode-map
                   ("C-x C-v" . org-visibility-force-save) ; defaults to `find-alternative-file'
                   ("C-x M-v" . org-visibility-remove))    ; defaults to undefined

Or, if using `use-package', add something like this instead:

  (use-package org-visibility
    :after (org)
    :demand t
    :bind* (:map org-visibility-mode-map
                 ("C-x C-v" . org-visibility-force-save) ; defaults to `find-alternative-file'
                 ("C-x M-v" . org-visibility-remove))    ; defaults to undefined
    :custom
    ;; optionally change the location of the state file
    ;;(org-visibility-state-file `,(expand-file-name "/some/path/.org-visibility"))
    ;; list of directories and files to persist and restore visibility state of
    (org-visibility-include-paths `(,(file-truename "~/.emacs.d/init-emacs.org")
                                    ,(file-truename "~/org")))
    ;; persist all org files regardless of location
    ;;(org-visibility-include-regexps '("\\.org\\'"))
    ;; list of directories and files to not persist and restore visibility state of
    ;;(org-visibility-exclude-paths `(,(file-truename "~/org/old")))
    ;; optionally set maximum number of files to keep track of
    ;; oldest files will be removed from the state file first
    ;;(org-visibility-maximum-tracked-files 100)
    ;; optionally set maximum number of days (since saved) to keep track of
    ;; files older than this number of days will be removed from the state file
    ;;(org-visibility-maximum-tracked-days 180)
    ;; optionally turn off visibility state change messages
    ;;(org-visibility-display-messages nil)
    :config
    (org-visibility-mode 1))

Usage:

As long as `org-visibility-mode' is enabled, visibility state is
automatically persisted on file save or kill, and restored when loaded. No
user intervention is needed. The user can, however, call
`org-visibility-force-save' to save the current visibility state of a
buffer before a file save or kill would automatically trigger it next.

Interactive commands:

The `org-visibility-mode' function toggles the minor mode on and off. For
normal use, turn it on when `org-mode' is enabled.

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

The `org-visibility-remove' function removes a given file (or the current
buffer's file) from `org-visibility-state-file'.

The `org-visibility-clean' function removes all missing or untracked files
from `org-visibility-state-file'.
