;;; git-backup-ivy.el --- An ivy interface to git-backup -*- lexical-binding: t -*-

;; Author: Sebastian Wålinder <s.walinder@gmail.com>
;; URL: https://github.com/walseb/git-backup-ivy
;; Package-Version: 20221014.2018
;; Package-Commit: 8e6a384fb7656123b06521a49479ebf9e11fcc94
;; Version: 1.1
;; Package-Requires: ((ivy "0.12.0") (git-backup "0.0.1") (emacs "25.1"))
;; Keywords: backup, convenience, files, tools, vc

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This package is a interface to git-backup

;; For options like ediff or open in new buffer, run `ivy-dispatching-done'
;; while the interface is open. By default this is bound to C-o

;;; Code:
(require 'ivy)
(require 'git-backup)
(require 'seq)
(require 'diff)

(defgroup git-backup-ivy nil
  "Interface to backup system git-backup using ivy."
  :group 'ivy)

(defcustom git-backup-ivy-git-path (executable-find "git")
  "Path to a git binary."
  :group 'git-backup-ivy
  :type 'string)

(defcustom git-backup-ivy-backup-path (expand-file-name (concat user-emacs-directory ".git-backup"))
  "The path where backups are stored."
  :group 'git-backup-ivy
  :type 'string)

(defcustom git-backup-ivy-list-format "%cd, %ar"
  "Format use to display entries in ivy buffer, follow git log format."
  :group 'git-backup-ivy
  :type 'string)

(defcustom git-backup-ivy-preview " *git-backup-ivy-diff*"
  "If nil don't show a preview buffer when running `git-backup-ivy'.
If nil then don't show a preview buffer at all. Otherwise enter a string,which
will be used  as the name for the temporary buffer that displays the preview."
  :group 'git-backup-ivy
  :type 'string)

(defcustom git-backup-ivy-preview-remove-header t
  "If non-nil, remove the header of the git diff.
This only contains a timestamp and not much else since the diff is done on
a temporary file."
  :group 'git-backup-ivy
  :type 'boolean)

(defcustom git-backup-ivy-preview-async t
  "If t, generate preview diff asynchronously.
This makes it possible to quickly change commit in long files."
  :group 'git-backup-ivy
  :type 'boolean)

(defcustom git-backup-ivy-hide-current t
  "If t, hide the current version of the file from selection."
  :group 'git-backup-ivy
  :type 'boolean)

(defcustom git-backup-ivy-preview-diff-switches nil
  "Flags to send diff when previewing commit.
If nil `diff-switches` are used."
  :group 'git-backup-ivy
  :type 'string)

(defvar git-backup-ivy-preview-backup-list-cache nil
  "A cache containing the all candidates in current search.
Used in `git-backup-ivy-update-fn'.")

(defvar git-backup-ivy-preview-buffers-list nil
  "Stores previous git backup preview buffers.
This is so that they can be killed in the future when they aren't needed
anymore. The reason the buffers and associated processes aren't killed right
away is because the process needs a while to turn off fully during which the
associated buffer needs to still be live.")

(defun git-backup-ivy-update-fn ()
  "Provides a diff preview for `git-backup-ivy'."
  (when (and git-backup-ivy-preview (> ivy--length 0))
    (with-temp-buffer
      (let* ((curr-buffer (ivy-state-buffer ivy-last))
             (curr-file (buffer-file-name curr-buffer))
             (candidate (ivy-state-current ivy-last))
             (candidate-hash
              (cdr (seq-find (lambda (list-candidate)
                               (if (string= (car list-candidate) candidate)
                                   t
                                 nil))
                             git-backup-ivy-preview-backup-list-cache)))
             (_
              ;; Remember that in the current scope is the temp buffer that contains the older version of the file selected.
              (insert
               ;; Selected file
               (git-backup--fetch-backup-file git-backup-ivy-git-path git-backup-ivy-backup-path candidate-hash curr-file)))

             (diff-buffer
              (diff-no-select curr-file (current-buffer) git-backup-ivy-preview-diff-switches (not git-backup-ivy-preview-async)
                              (generate-new-buffer (generate-new-buffer-name git-backup-ivy-preview)))))

        ;; Taken from undo-tree. Removes unnecessary git diff text
        ;; Doesn't work when running diff in async as the diff startup time isn't instant
        (when (and git-backup-ivy-preview-remove-header (not git-backup-ivy-preview-async))
          (with-current-buffer diff-buffer
            (let ((inhibit-read-only t))
              (goto-char (point-min))
              (delete-region (point) (1+ (line-end-position 3)))
              (goto-char (point-max))
              (forward-line -2)
              (delete-region (point) (point-max))
              (setq cursor-type nil)
              (setq buffer-read-only t))))

        ;; Kill old git backup ivy buffers as we know they aren't needed anymore
        (git-backup-ivy-preview-kill-preview-buffers)

        (push diff-buffer git-backup-ivy-preview-buffers-list)

        (with-ivy-window
          ;; Show diff buffer to user
          (display-buffer diff-buffer))))))

(defun git-backup-ivy-preview-kill-preview-buffers ()
  "Kill all git preview buffers."
  (seq-filter (lambda (a)
                (and (buffer-live-p a)
                     (let ((proc (get-buffer-process a)))
                       (if proc
                           (progn (kill-process proc) t)
                         (kill-buffer a)
                         nil))))
              git-backup-ivy-preview-buffers-list))

;;;###autoload
(defun git-backup-ivy ()
  "Main function to bring up interface for interacting with git-backup."
  (interactive)
  (let* ((pt (point))
         (candidates-all
          ;; Do cdr as the first one will always be identical to the current buffer
          (git-backup-list-file-change-time git-backup-ivy-git-path git-backup-ivy-backup-path git-backup-ivy-list-format (buffer-file-name)))
         (candidates
          (if git-backup-ivy-hide-current
              (cdr candidates-all)
            candidates-all)))
    (when git-backup-ivy-preview
      (setq git-backup-ivy-preview-backup-list-cache candidates))
    (if candidates
        (unwind-protect
            (ivy-read
             (format "Backup for %s: " (buffer-file-name))
             candidates
             :require-match t
             :update-fn #'git-backup-ivy-update-fn
             :action (lambda (candidate)
                       (git-backup-replace-current-buffer git-backup-ivy-git-path git-backup-ivy-backup-path (cdr candidate) (buffer-file-name))
                       (goto-char pt)))
          (when git-backup-ivy-preview
            ;; Do this in unwind-protect as it allows C-g to be used to exit
            (git-backup-ivy-preview-kill-preview-buffers)))
      (error "No filename associated with buffer, file has no backup yet or filename is blacklisted"))))

(ivy-set-actions
 'git-backup-ivy
 '(("e" (lambda (candidate)
          (git-backup-create-ediff git-backup-ivy-git-path git-backup-ivy-backup-path (cdr candidate) (current-buffer))) "Ediff file with backup")
   ("f" (lambda (candidate)
          (git-backup-open-in-new-buffer git-backup-ivy-git-path git-backup-ivy-backup-path (cdr candidate) (buffer-file-name))) "Open in new buffer")
   ("D" (lambda (candidate)
          (when (yes-or-no-p "Really delete all backups of this file?")
            (git-backup-remove-file-backups git-backup-ivy-git-path git-backup-ivy-backup-path (buffer-file-name)))) "Delete all backups of file")))

(provide 'git-backup-ivy)

;;; git-backup-ivy.el ends here
