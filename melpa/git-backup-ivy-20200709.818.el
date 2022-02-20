;;; git-backup-ivy.el --- An ivy interface to git-backup -*- lexical-binding: t -*-

;; Author: Sebastian Wålinder <s.walinder@gmail.com>
;; URL: https://github.com/walseb/git-backup-ivy
;; Package-Version: 20200709.818
;; Package-Commit: 0a5c52e64d0062f77ffefc9213e75690c6d7b111
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

(defcustom git-backup-ivy-preview "*git-backup-ivy-diff*"
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

(defvar git-backup-ivy-preview-backup-list-cache nil
  "A cache containing the all candidates in current search.
Used in `git-backup-ivy-update-fn'.")

(defun git-backup-ivy-update-fn ()
  "Provides a diff preview for `git-backup-ivy'."
  (when (and git-backup-ivy-preview (> ivy--length 0))
    (let* ((curr-buffer (ivy-state-buffer ivy-last))
           (curr-file (buffer-file-name curr-buffer))

           (candidate (ivy-state-current ivy-last))
           (candidate-hash (cdr (seq-find (lambda (list-candidate)
                                            (if (string= (car list-candidate) candidate)
                                                t
                                              nil))
                                          git-backup-ivy-preview-backup-list-cache)))
           (old-backup-str (git-backup--fetch-backup-file git-backup-ivy-git-path git-backup-ivy-backup-path candidate-hash curr-file))
           (old-backup-temp-file (make-temp-file "git-backup-ivy-preview-temp-"))

           (diff-buffer (get-buffer-create git-backup-ivy-preview)))

      ;; Write old backup to temp buffer
      (write-region old-backup-str nil old-backup-temp-file nil 'nomessage)

      ;; Create diff. This has to be run on two files.
      (diff-no-select curr-file old-backup-temp-file nil 'noasync diff-buffer)
      ;; Don't litter /tmp
      (delete-file old-backup-temp-file)

      ;; Taken from undo-tree. Removes unnecessary git diff text
      (when git-backup-ivy-preview-remove-header
	(with-current-buffer diff-buffer
	  (let ((inhibit-read-only t))
	    (goto-char (point-min))
	    (delete-region (point) (1+ (line-end-position 3)))
	    (goto-char (point-max))
	    (forward-line -2)
	    (delete-region (point) (point-max))
	    (setq cursor-type nil)
	    (setq buffer-read-only t))))

      (with-ivy-window
	;; Show diff buffer to user
        (switch-to-buffer diff-buffer)
        ;; Sometimes the cursor is not returned to the minibuffer.
	;; This fixes that
        (select-window (active-minibuffer-window))))))

;;;###autoload
(defun git-backup-ivy ()
  "Main function to bring up interface for interacting with git-backup."
  (interactive)
  (let ((candidates (git-backup-list-file-change-time git-backup-ivy-git-path git-backup-ivy-backup-path git-backup-ivy-list-format (buffer-file-name))))
    (when git-backup-ivy-preview
      (setq git-backup-ivy-preview-backup-list-cache candidates))
    (if candidates
	(ivy-read
	 (format "Backup for %s: " (buffer-file-name))
	 candidates
	 :require-match t
	 :update-fn #'git-backup-ivy-update-fn
	 :action (lambda (candidate)
		   (git-backup-replace-current-buffer git-backup-ivy-git-path git-backup-ivy-backup-path (cdr candidate) (buffer-file-name))))
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
