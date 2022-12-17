;;; org-visibility.el --- Persistent org tree visibility -*- lexical-binding: t; -*-
;;
;;; Copyright (C) 2021-2022 Kyle W T Sherman
;;
;; Author: Kyle W T Sherman <kylewsherman@gmail.com>
;; URL: https://github.com/nullman/emacs-org-visibility
;; Package-Version: 20220929.1415
;; Package-Commit: afa4b6f8ff274df87eb11f1afd0321084a45a2ab
;; Created: 2021-07-17
;; Version: 1.1.11
;; Keywords: outlines convenience
;; Package-Requires: ((emacs "27.1"))
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation; either version 2 of the License, or (at your option) any later
;; version.
;;
;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along with
;; this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
;; Street, Fifth Floor, Boston, MA 02110-1301 USA.
;;
;;; Commentary:
;;
;; Org Visibility is an Emacs package that adds the ability to persist (save
;; and load) the state of the visible sections of `org-mode' files. The state
;; is saved when the file is saved or killed, and restored when the file is
;; loaded.
;;
;; Hooks are used to persist and restore org tree visibility upon loading and
;; saving org files. Whether or not a given buffer's file will have its
;; visibility persisted is determined by the following logic:
;;
;; Qualification Rules:
;;
;; Files are only considered if their buffer is an `org-mode' buffer and they
;; meet one of the following requirements:
;;
;;   - File has buffer local variable `org-visibility' set to t
;;
;;   - File is contained within one of the directories listed in
;;     `org-visibility-include-paths'
;;
;;   - File path matches one of the regular expressions listed in
;;     `org-visibility-include-regexps'
;;
;; Files are removed from consideration if they meet one of the following
;; requirements (overriding the above include logic):
;;
;;   - File has buffer local variable `org-visibility' set to 'never
;;
;;   - File is contained within one of the directories listed in
;;     `org-visibility-exclude-paths'
;;
;;   - File matches one of the regular expressions listed in
;;     `org-visibility-exclude-regexps'.
;;
;; Provides the following interactive functions:
;;
;;   `org-visibility-save'             - Save visibility state for current buffer
;;   `org-visibility-force-save'       - Save even if buffer has not been modified
;;   `org-visibility-save-all-buffers' - Save all buffers that qualify
;;   `org-visibility-load'             - Load a file and restore its visibility state
;;   `org-visibility-remove'           - Remove current buffer from `org-visibility-state-file'
;;   `org-visibility-clean'            - Cleanup `org-visibility-state-file'
;;   `org-visibility-enable-hooks'     - Enable all hooks
;;   `org-visibility-disable-hooks'    - Disable all hooks
;;
;; Installation:
;;
;; Put `org-visibility.el' where you keep your elisp files and add something
;; like the following to your .emacs file:
;;
;;   ;; optionally change the location of the state file
;;   ;;(setq org-visibility-state-file `,(expand-file-name "/some/path/.org-visibility"))
;;
;;   ;; list of directories and files to persist and restore visibility state of
;;   (setq org-visibility-include-paths `(,(file-truename "~/.emacs.d/init-emacs.org")
;;                                        ,(file-truename "~/org"))
;;   ;; persist all org files regardless of location
;;   ;;(setq org-visibility-include-regexps '("\\.org\\'"))
;;
;;   ;; list of directories and files to not persist and restore visibility state of
;;   ;;(setq org-visibility-exclude-paths `(,(file-truename "~/org/old")))
;;
;;   ;; optionally set maximum number of files to keep track of
;;   ;; oldest files will be removed from the state file first
;;   ;;(setq org-visibility-maximum-tracked-files 100)
;;
;;   ;; optionally set maximum number of days (since saved) to keep track of
;;   ;; files older than this number of days will be removed from the state file
;;   ;;(setq org-visibility-maximum-tracked-days 180)
;;
;;   ;; optionally turn off visibility state change messages
;;   ;;(setq org-visibility-display-messages nil)
;;
;;   (require 'org-visibility)
;;
;;   ;; enable org-visibility-mode
;;   (org-visibility-mode 1)
;;
;;   ;; optionally set a keybinding to force save
;;   (bind-keys* :map org-visibility-mode-map
;;                    ("C-x C-v" . org-visibility-force-save) ; defaults to `find-alternative-file'
;;                    ("C-x M-v" . org-visibility-remove))    ; defaults to undefined
;;
;; Or, if using `use-package', add something like this instead:
;;
;;   (use-package org-visibility
;;     :after (org)
;;     :demand t
;;     :bind* (:map org-visibility-mode-map
;;                  ("C-x C-v" . org-visibility-force-save) ; defaults to `find-alternative-file'
;;                  ("C-x M-v" . org-visibility-remove))    ; defaults to undefined
;;     :custom
;;     ;; optionally change the location of the state file
;;     ;;(org-visibility-state-file `,(expand-file-name "/some/path/.org-visibility"))
;;     ;; list of directories and files to persist and restore visibility state of
;;     (org-visibility-include-paths `(,(file-truename "~/.emacs.d/init-emacs.org")
;;                                     ,(file-truename "~/org")))
;;     ;; persist all org files regardless of location
;;     ;;(org-visibility-include-regexps '("\\.org\\'"))
;;     ;; list of directories and files to not persist and restore visibility state of
;;     ;;(org-visibility-exclude-paths `(,(file-truename "~/org/old")))
;;     ;; optionally set maximum number of files to keep track of
;;     ;; oldest files will be removed from the state file first
;;     ;;(org-visibility-maximum-tracked-files 100)
;;     ;; optionally set maximum number of days (since saved) to keep track of
;;     ;; files older than this number of days will be removed from the state file
;;     ;;(org-visibility-maximum-tracked-days 180)
;;     ;; optionally turn off visibility state change messages
;;     ;;(org-visibility-display-messages nil)
;;     :config
;;     (org-visibility-mode 1))
;;
;; Usage:
;;
;; As long as `org-visibility-mode' is enabled, visibility state is
;; automatically persisted on file save or kill, and restored when loaded. No
;; user intervention is needed. The user can, however, call
;; `org-visibility-force-save' to save the current visibility state of a
;; buffer before a file save or kill would automatically trigger it next.
;;
;; Interactive commands:
;;
;; The `org-visibility-mode' function toggles the minor mode on and off. For
;; normal use, turn it on when `org-mode' is enabled.
;;
;; The `org-visibility-save' function saves the current buffer's file
;; visibility state if it has been modified or had an `org-cycle' change, and
;; matches the above Qualification Rules.
;;
;; The `org-visibility-force-save' function saves the current buffer's file
;; visibility state if it matches the above Qualification Rules, regardless of
;; whether the file has been modified.
;;
;; The `org-visibility-save-all-buffers' function saves the visibility state
;; for any modified buffer files that match the above Qualification Rules.
;;
;; The `org-visibility-load' function loads a file and restores its visibility
;; state if it matches the above Qualification Rules.
;;
;; The `org-visibility-remove' function removes a given file (or the current
;; buffer's file) from `org-visibility-state-file'.
;;
;; The `org-visibility-clean' function removes all missing or untracked files
;; from `org-visibility-state-file'.

;;; Code:

(require 'cl-lib)
(require 'outline)
(require 'org)
(require 'org-macs)

(defgroup org-visibility nil
  "Persistent org tree visibility."
  :group 'org
  :prefix "org-visibility-")

(defcustom org-visibility-display-messages t
  "Whether or not to display messages when visibility states are changed."
  :type 'boolean
  :group 'org-visibility)

(defcustom org-visibility-state-file
  `,(expand-file-name ".org-visibility" user-emacs-directory)
  "File used to store org visibility state."
  :type 'string
  :group 'org-visibility)

(defcustom org-visibility-include-paths '()
  "List of directories and files that will persist visibility.

These directories and files will persist their visibility state
when saved and loaded."
  :type '(repeat (choice string))
  :group 'org-visibility)

(defcustom org-visibility-exclude-paths '()
  "List of directories and files that will not persist visibility.

These directories and files will not persist their visibility
state.

Overrides `org-visibility-include-paths' and
`org-visibility-include-regexps'."
  :type '(repeat (choice string))
  :group 'org-visibility)

(defcustom org-visibility-include-regexps '()
  "List of regular expressions that will persist visibility.

The directories and files that match these regular expressions
will persist their visibility state when saved and loaded."
  :type '(repeat (choice regexp))
  :group 'org-visibility)

(defcustom org-visibility-exclude-regexps '()
  "List of regular expressions that will not persist visibility.

The directories and files that match these regular expressions
will not persist their visibility state.

Overrides `org-visibility-include-paths' and
`org-visibility-include-regexps'."
  :type '(repeat (choice regexp))
  :group 'org-visibility)

(defcustom org-visibility-maximum-tracked-files nil
  "Maximum number of files to track the visibility state of.

When non-nil and persisting the state of a new org file causes
this number to be exceeded, the oldest tracked file will be
removed from the state file."
  :type 'number
  :group 'org-visibility)

(defcustom org-visibility-maximum-tracked-days nil
  "Maximum number of days to track file visibility state.

When non-nil, file states in the state file that have not been
modified for this number of days will have their state
information removed."
  :type 'number
  :group 'org-visibility)

(defvar-local org-visibility
  nil
  "File local variable to determine visibility persistence.

If nil, this setting has no effect on determining buffer file
visibility state persistence.

If t, buffer file should have its visibility state persisted and
restored.

If 'never, buffer file should never have its visibility state
persisted and restored.

Overrides `org-visibility-include-paths',
`org-visibility-exclude-paths', `org-visibility-include-regexps',
and `org-visibility-exclude-regexps'.)")

(defvar-local org-visibility-dirty
  nil
  "Non-nil if buffer has been modified since last visibility save.")

(defun org-visibility-version (&optional insert)
  "Display the version of Org Visibility that is running in this session.

If INSERT is non-nil, insert the Emacs version string at point
instead of displaying it."
  (interactive)
  (let ((version-string "Org Visibility 1.1.11"))
    (if insert
        (insert version-string)
      (if (called-interactively-p 'interactive)
          (message "%s" version-string)
        version-string))))

(defun org-visibility--timestamp ()
  "Return timestamp in ISO 8601 format (YYYY-mm-ddTHH:MM:SSZ)."
  (format-time-string "%FT%T%Z"))

(defun org-visibility--timestamp-to-epoch (timestamp)
  "Return epoch (seconds since 1970-01-01) from TIMESTAMP."
  (truncate (float-time (date-to-time timestamp))))

(defun org-visibility--buffer-checksum (&optional buffer)
  "Return checksum for BUFFER."
  (secure-hash 'md5 (or buffer (current-buffer))))

(defun org-visibility--remove-over-maximum-tracked-files (data)
  "Remove oldest files over maximum file count from DATA.

Does nothing unless `org-visibility-maximum-tracked-files' is
non-nil and exceeded."
  (when (and org-visibility-maximum-tracked-files
             (cl-plusp org-visibility-maximum-tracked-files))
    (while (> (length data) org-visibility-maximum-tracked-files)
      (setq data (nreverse (cdr (nreverse data))))))
  data)

(defun org-visibility--remove-over-maximum-tracked-days (data)
  "Remove all files over maximum day count from DATA.

Does notthing unless `org-visibility-maximum-tracked-days' is
non-nil and exceeded."
  (if (and org-visibility-maximum-tracked-days
           (cl-plusp org-visibility-maximum-tracked-days))
      (cl-do ((day (- (time-to-days (current-time)) org-visibility-maximum-tracked-days))
              (d data (cdr d))
              (n 0 (1+ n)))
          ((< (time-to-days (date-to-time (cadar d))) day)
           (cl-subseq data 0 n)))
    data))

(defun org-visibility--set (buffer visible)
  "Set visibility state.

Set visibility state record for BUFFER to VISIBLE and update
`org-visibility-state-file' with new state."
  (let ((print-length nil)
        (data (and (file-exists-p org-visibility-state-file)
                   (ignore-errors
                     (with-temp-buffer
                       (insert-file-contents org-visibility-state-file)
                       (read (buffer-substring-no-properties (point-min) (point-max)))))))
        (file-name (buffer-file-name buffer))
        (date (org-visibility--timestamp))
        (checksum (org-visibility--buffer-checksum buffer)))
    (when file-name
      (setq data (delq (assoc file-name data) data)) ; remove previous value
      (setq data (append (list (list file-name date checksum visible)) data)) ; add new value
      (setq data (org-visibility--remove-over-maximum-tracked-files data)) ; remove old files over maximum count
      (setq data (org-visibility--remove-over-maximum-tracked-days data)) ; remove old files over maximum days
      (with-temp-file org-visibility-state-file
        (insert (format "%S\n" data)))
      (when org-visibility-display-messages
        (message "Set visibility state for %s" file-name)))))

(defun org-visibility--get (buffer)
  "Get visibility state.

Return visibility state for BUFFER if found in
`org-visibility-state-file'."
  (let ((data (and (file-exists-p org-visibility-state-file)
                   (ignore-errors
                     (with-temp-buffer
                       (insert-file-contents org-visibility-state-file)
                       (read (buffer-substring-no-properties (point-min) (point-max)))))))
        (file-name (buffer-file-name buffer))
        (checksum (org-visibility--buffer-checksum buffer)))
    (when file-name
      (let ((state (assoc file-name data)))
        (when (string= (caddr state) checksum)
          (cadddr state))))))

(defun org-visibility--save-internal (&optional buffer noerror force)
  "Save visibility snapshot of org BUFFER.

If NOERROR is non-nil, do not throw errors.

If FORCE is non-nil, save even if file is not marked as dirty."
  (let ((buffer (or buffer (current-buffer)))
        (file-name (buffer-file-name buffer))
        (visible '()))
    (with-current-buffer buffer
      (if (not (derived-mode-p 'org-mode))
          (unless noerror
            (user-error "Not an Org buffer"))
        (if (not file-name)
            (unless noerror
              (user-error "No file associated with this buffer: %S" buffer))
          (when (or force org-visibility-dirty)
            (save-mark-and-excursion
              (goto-char (point-min))
              (while (not (eobp))
                (when (not (invisible-p (point)))
                  (push (point) visible))
                (forward-visible-line 1)))
            (org-visibility--set buffer (nreverse visible))
            (setq org-visibility-dirty nil)))))))

(defun org-visibility--load-internal (&optional buffer noerror)
  "Load visibility snapshot of org BUFFER.

If NOERROR is non-nil, do not throw errors."
  (let ((buffer (or buffer (current-buffer)))
        (file-name (buffer-file-name buffer)))
    (with-current-buffer buffer
      (if (not (derived-mode-p 'org-mode))
          (unless noerror
            (user-error "Not an Org buffer"))
        (if (not (buffer-file-name buffer))
            (unless noerror
              (user-error "No file associated with this buffer: %S" buffer))
          (let ((visible (org-visibility--get buffer)))
            (when visible
              (save-mark-and-excursion
                (outline-hide-sublevels 1)
                (dolist (x visible)
                  (ignore-errors
                    (when (> x 1)
                      (goto-char x)
                      (when (invisible-p (1- (point)))
                        (org-flag-region (1- (point-at-bol)) (point-at-eol) nil 'outline))))))
              (when org-visibility-display-messages
                (message "Restored visibility state for %s" file-name)))
            (setq org-visibility-dirty nil)))))))

(defun org-visibility--check-file-path (file-name paths)
  "Return whether FILE-NAME is in one of the PATHS."
  (let ((file-name (file-truename file-name)))
    (cl-do ((paths paths (cdr paths))
            (match nil))
        ((or (null paths) match) match)
      (let ((path (car paths)))
        (when (>= (length file-name) (length path))
          (let ((part (substring file-name 0 (length path))))
            (when (string= part path)
              (setq match t))))))))

(defun org-visibility--check-file-regexp (file-name regexps)
  "Return whether FILE-NAME is a match for one of the REGEXPS."
  (let ((file-name (file-truename file-name)))
    (cl-do ((regexps regexps (cdr regexps))
            (match nil))
        ((or (null regexps) match) match)
      (let ((regexp (car regexps)))
        (when (string-match regexp file-name)
          (setq match t))))))

(defun org-visibility--check-file-include-exclude-paths-and-regexps (file-name)
  "Return whether FILE-NAME should have its visibility state persisted.

Return whether FILE-NAME is in one of the paths listed in
`org-visibility-include-paths' or matches a regular expression
listed in `org-visibility-include-regexps', and FILE-NAME is not
in one of the paths listed in `org-visibility-exclude-paths' or
matches a regular expression listed in
`org-visibility-exclude-regexps'."
  (and (or (org-visibility--check-file-path file-name org-visibility-include-paths)
           (org-visibility--check-file-regexp file-name org-visibility-include-regexps))
       (not (or (org-visibility--check-file-path file-name org-visibility-exclude-paths)
                (org-visibility--check-file-regexp file-name org-visibility-exclude-regexps)))))

(defun org-visibility--check-buffer-file-persistence (buffer)
  "Return whether BUFFER should have its visibility state persisted.

Return whether BUFFER's file is in one of the paths listed in
`org-visibility-include-paths' or matches a regular expression
listed in `org-visibility-include-regexps', and BUFFER's file is
not in one of the paths listed in `org-visibility-exclude-paths'
or matches a regular expression listed in
`org-visibility-exclude-regexps'."
  (with-current-buffer buffer
    (cl-case (if (boundp 'org-visibility) org-visibility nil)
      ('nil (let ((file-name (buffer-file-name buffer)))
              (if file-name
                  (org-visibility--check-file-include-exclude-paths-and-regexps file-name)
                nil)))
      ('never nil)
      (t t))))

;;;###autoload
(defun org-visibility-remove (&optional file-name)
  "Remove visibility state of FILE-NAME or `current-buffer'."
  (interactive)
  (let ((print-length nil)
        (file-name (or file-name (buffer-file-name (current-buffer)))))
    (when file-name
      (let ((data
             (cl-remove-if
              (lambda (x) (string-equal (car x) file-name))
              (and (file-exists-p org-visibility-state-file)
                   (with-temp-buffer
                     (insert-file-contents org-visibility-state-file)
                     (read (buffer-substring-no-properties (point-min) (point-max))))))))
        (with-temp-file org-visibility-state-file
          (insert (format "%S\n" data)))
        (when org-visibility-display-messages
          (message "Removed visibility state of %s" file-name))))))

;;;###autoload
(defun org-visibility-clean ()
  "Remove any missing files from `org-visibility-state-file'."
  (interactive)
  (let ((print-length nil)
        (data
         (cl-remove-if-not
          (lambda (x)
            (let ((file-name (car x)))
              (and (file-exists-p file-name)
                   (org-visibility--check-file-include-exclude-paths-and-regexps file-name))))
          (and (file-exists-p org-visibility-state-file)
               (with-temp-buffer
                 (insert-file-contents org-visibility-state-file)
                 (read (buffer-substring-no-properties (point-min) (point-max))))))))
    (with-temp-file org-visibility-state-file
      (insert (format "%S\n" data)))
    (when org-visibility-display-messages
      (message "Visibility state file has been cleaned"))))

;;;###autoload
(defun org-visibility-save (&optional noerror force)
  "Save visibility state if buffer has been modified.

If NOERROR is non-nil, do not throw errors.

If FORCE is non-nil, save even if file is not marked as dirty."
  (interactive)
  (when (org-visibility--check-buffer-file-persistence (current-buffer))
    (org-visibility--save-internal (current-buffer) noerror force)))

(defun org-visibility-save-noerror ()
  "Save visibility state if buffer has been modified, ignoring errors."
  (org-visibility-save :noerror))

;;;###autoload
(defun org-visibility-force-save ()
  "Save visibility state even if buffer has not been modified."
  (interactive)
  (org-visibility-save nil :force))

;;;###autoload
(defun org-visibility-save-all-buffers (&optional force)
  "Save visibility state for any modified buffers, ignoring errors.

If FORCE is non-nil, save even if files are not marked as dirty."
  (interactive)
  (dolist (buffer (buffer-list))
    (when (org-visibility--check-buffer-file-persistence buffer)
      (org-visibility--save-internal buffer :noerror force))))

;;;###autoload
(defun org-visibility-load (&optional file)
  "Load FILE or `current-buffer' and restore its visibility state, ignoring errors."
  (interactive)
  (let ((buffer (if file (get-file-buffer file) (current-buffer))))
    (when (and buffer (org-visibility--check-buffer-file-persistence buffer))
      (org-visibility--load-internal buffer :noerror))))

(defun org-visibility-dirty ()
  "Set visibility dirty flag."
  (when (and (eq major-mode 'org-mode)
             (not org-visibility-dirty)
             (org-visibility--check-buffer-file-persistence (current-buffer)))
    (setq org-visibility-dirty t)))

(defun org-visibility-dirty-org-cycle (state)
  "Set visibility dirty flag when `org-cycle' is called.

Unless STATE is 'INVALID-STATE."
  ;; dummy check to prevent compiler warning
  (when (not (eq state 'INVALID-STATE))
    (org-visibility-dirty)))

(defun org-visibility-enable-hooks ()
  "Helper function to enable all `org-visibility' hooks."
  (add-hook 'after-save-hook #'org-visibility-save-noerror :append)
  (add-hook 'kill-buffer-hook #'org-visibility-save-noerror :append)
  (add-hook 'kill-emacs-hook #'org-visibility-save-all-buffers :append)
  (add-hook 'find-file-hook #'org-visibility-load :append)
  (add-hook 'first-change-hook #'org-visibility-dirty :append)
  (add-hook 'org-cycle-hook #'org-visibility-dirty-org-cycle :append))

(defun org-visibility-disable-hooks ()
  "Helper function to disable all `org-visibility' hooks."
  (remove-hook 'after-save-hook #'org-visibility-save-noerror)
  (remove-hook 'kill-buffer-hook #'org-visibility-save-noerror)
  (remove-hook 'kill-emacs-hook #'org-visibility-save-all-buffers)
  (remove-hook 'find-file-hook #'org-visibility-load)
  (remove-hook 'first-change-hook #'org-visibility-dirty)
  (remove-hook 'org-cycle-hook #'org-visibility-dirty-org-cycle))

;;;###autoload
(define-minor-mode org-visibility-mode
  "Minor mode for toggling `org-visibility' hooks on and off.

This minor mode will persist (save and load) the state of the
visible sections of `org-mode' files. The state is saved when the
file is saved or killed, and restored when the file is loaded.

\\{org-visibility-mode-map}"
  :lighter " vis"
  :keymap (make-sparse-keymap)
  :global t
  (if org-visibility-mode
      (org-visibility-enable-hooks)
    (org-visibility-disable-hooks)))

(provide 'org-visibility)

;;; org-visibility.el ends here
