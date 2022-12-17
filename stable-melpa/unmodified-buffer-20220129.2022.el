;;; unmodified-buffer.el --- Auto revert modified buffer state -*- lexical-binding: t -*-

;; Copyright (C) 2020  Arthur Colombini Gusmao

;; Author: Arthur Colombini Gusmao
;; Maintainer: Arthur Colombini Gusmao

;; URL: https://github.com/arthurcgusmao/unmodified-buffer
;; Package-Version: 20220129.2022
;; Package-Commit: 9095a3f870aa570804a11d75aba0952294199715
;; Version: 1.0.0
;; Package-Requires: ((emacs "24.1"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides an Emacs hook to automatically revert a buffer's
;; modified state, in case the buffer has been changed back to match the
;; original content of the file it concerns.

;;; Code:

;;;###autoload
(defgroup unmodified-buffer nil
  "Automatically restore a buffer's modified state."
  :group 'tools)

(defcustom unmodified-buffer-ignore-remote t
  "If non-nil, ignore remote files, for better performance.

WARNING: currently setting this variable to nil has no effect, as
the implemented solution doesn't work with remote file names (as
used by Tramp). It has to be further investigated; it might have
to do with the way we call `diff' in
`unmodified-buffer-update-flag'."
  :group 'unmodified-buffer
  :type 'boolean)

(defcustom unmodified-buffer-size-limit 50000
  "Size limit (in bytes) for checking buffer modification.

Applies to both the saved file and the buffer: if either is
larger than the specified amount, no check (if the buffer differs
from the file) will be performed."
  :group 'unmodified-buffer
  :type 'integer)

(defcustom unmodified-buffer-check-period "0.5 sec"
  "The period of time in which every new modified check happens.

Values must be a string accepted by the `run-at-time' function.
The default value usually works well across machines."
  :group 'unmodified-buffer
  :type 'string)

(defvar unmodified-buffer-timer nil
  "Latest scheduled timer for the next modification check.")
(make-variable-buffer-local 'unmodified-buffer-timer)

;;;###autoload
(defvar unmodified-buffer-hook nil
  "List of functions to be called when a buffer is set to unmodified.")

;; ;; Useful for debugging, uncomment if necessary
;; (defvar count-run-times 0 "")
;; (setq count-run-times 0)
;; (message (concat "Times run: " (number-to-string count-run-times)))

(defun unmodified-buffer-update-flag (buffer)
  "Check if BUFFER is unmodified and update its modified flag.

Requires diff to be installed on your system. Adapted from
https://stackoverflow.com/a/11452885/5103881"
  (if (and (buffer-live-p buffer)       ; check that buffer has not been killed
           (buffer-modified-p buffer))  ; check that buffer has been modified after last save
      (let ((basefile (buffer-file-name buffer)))
        (when basefile                  ; buffer must be associated to a file
          (let ((b-size (buffer-size buffer))
                (f-size (nth 7 (file-attributes basefile)))) ; 7th attribute of a file is its size, in bytes
            ;; (setq count-run-times (+ count-run-times 1)) ;; Debugging purposes -- Uncomment if necessary
            (unless (or (not f-size) ; sometimes the buffer can be associated to a file but the file does not exist on disk. This line covers this case.
                        (/= b-size f-size) ; buffer size should be equal to file size (much faster comparison than diffing)
                        (> b-size unmodified-buffer-size-limit) ; buffer size must be smaller than limit
                        (> f-size unmodified-buffer-size-limit)) ; file size must be smaller than limit
              (let ((tempfile (make-temp-file "buffer-content-")))
                (with-current-buffer buffer
                  (save-restriction
                    (widen)
                    (write-region (point-min) (point-max) tempfile nil 'silent))
                  (when (unmodified-buffer-files-have-same-content-p
                         basefile tempfile)
                    (set-buffer-modified-p nil) ; set unmodified state (important emacs native flag)
                    (run-hooks 'unmodified-buffer-hook)))
                (delete-file tempfile))))))))

(defun unmodified-buffer-files-have-same-content-p
    (file1 file2)
  "Return non-nil if FILE1 and FILE2 have the same content."
  (cond
   ((string-equal system-type "windows-nt")
    (= (call-process
        "FC" nil nil nil "/B"
        (replace-regexp-in-string "/" "\\" file1 t t)
        (replace-regexp-in-string "/" "\\" file2 t t)) 0))
   ((or (string-equal system-type "darwin")
        (string-equal system-type "gnu/linux"))
    (= (call-process "diff" nil nil nil "-q" file1 file2) 0)) ; returns 0 if files are equal, 1 if different, and 2 if invalid file paths
   (t
    (unmodified-buffer-mode -1)
    (message "OS not supported; UNMODIFIED-BUFFER-MODE deactivated. \
Please file a bug report or pull request."))))

(defun unmodified-buffer-schedule-update (_beg _end _len)
  "Schedule a check of the actual buffer modified state.

Arguments are not used but must comply with
`after-change-functions' call."
  (save-match-data ; necessary; otherwise running `replace-string' was raising error "Match data clobbered by buffer modification hooks."
    (with-current-buffer (current-buffer)
      (unmodified-buffer-cancel-scheduled-update) ; delete previously scheduled timer
      (setq unmodified-buffer-timer ; schedule new timer and save requested action to variable
            (run-at-time
             unmodified-buffer-check-period nil
             #'unmodified-buffer-update-flag (current-buffer))))))

(defun unmodified-buffer-cancel-scheduled-update ()
  "Cancel the next scheduled buffer modified check."
  (if (bound-and-true-p unmodified-buffer-timer)
      (cancel-timer unmodified-buffer-timer)))

(defun unmodified-buffer-add-after-change-hook (&optional buffer)
  "Add `unmodified-buffer-schedule-update' to after change hook.

The `unmodified-buffer-schedule-update' function is added to the
`after-change-functions' hook of BUFFER if it visits a file."
  (let* ((buffer (or buffer (current-buffer)))
         (filename (buffer-file-name buffer)))
    (when filename ; Ensure buffer visits file
      (unless (and unmodified-buffer-ignore-remote ; Ensure not ignoring remote or
                   (file-remote-p filename))       ; file is not remote
        (with-current-buffer buffer
          (add-hook 'after-change-functions
                    #'unmodified-buffer-schedule-update t t))))))

(defun unmodified-buffer-remove-after-change-hook (&optional buffer)
  "Revert `unmodified-buffer-add-after-change-hook' in BUFFER."
  (with-current-buffer (or buffer (current-buffer))
    (remove-hook 'after-change-functions
                 #'unmodified-buffer-schedule-update t)))

(defun unmodified-buffer-add-hooks (&optional buffer)
  "Add hooks for enabling unmodified-buffer in BUFFER."
  (let ((buffer (or buffer (current-buffer))))
    (with-current-buffer buffer
      (add-hook 'after-save-hook
                #'unmodified-buffer-cancel-scheduled-update nil t) ;; No need to check status when file has been saved
      (add-hook 'after-save-hook
                #'unmodified-buffer-add-after-change-hook nil t) ;; Add hook to buffer after it was saved to a file (in case of new buffer)
      (unmodified-buffer-add-after-change-hook buffer)))) ;; Add hook to buffer if it visits a file

(defun unmodified-buffer-remove-hooks (&optional buffer)
  "Remove unmodified-buffer-related hooks from BUFFER."
  (let ((buffer (or buffer (current-buffer))))
    (with-current-buffer buffer
      (remove-hook 'after-save-hook
                   #'unmodified-buffer-cancel-scheduled-update t)
      (remove-hook 'after-save-hook
                   #'unmodified-buffer-add-after-change-hook t)
      (unmodified-buffer-remove-after-change-hook buffer))))


;;;###autoload
(define-minor-mode unmodified-buffer-mode
  "Automatically update a buffer's modified state.

Minor mode for automatically restoring a buffer state to
unmodified if its current content matches that of the file it
visits."
  :global nil
  (if unmodified-buffer-mode
      (unmodified-buffer-add-hooks)
    (unmodified-buffer-remove-hooks)))


;;;###autoload
(define-globalized-minor-mode unmodified-buffer-global-mode
  unmodified-buffer-mode (lambda () (unmodified-buffer-mode 1)))


(defun unmodified-buffer-mode-disable-all ()
  "Disable unmodified-buffer in all existing buffers.

This is a utility function due to the way in which
`define-globalized-minor-mode' operates -- it doesn't turn the
mode off of existing buffers when deactivated."
  (interactive)
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (unmodified-buffer-mode -1))))


(provide 'unmodified-buffer)
;;; unmodified-buffer.el ends here
