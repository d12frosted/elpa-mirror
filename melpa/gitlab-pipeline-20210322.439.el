;;; gitlab-pipeline.el --- Get infomation about Gitlab pipelines -*- lexical-binding: t -*-

;; Copyright (C) 2020 Giap Tran <txgvnn@gmail.com>

;; Author: Giap Tran <txgvnn@gmail.com>
;; URL: https://github.com/TxGVNN/gitlab-pipeline
;; Package-Version: 20210322.439
;; Package-Commit: 089400ac1d411a2b58cf1a64f28911079d5c898f
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1") (ghub "3.3.0"))
;; Keywords: comm, tools, git

;; This file is NOT part of GNU Emacs.

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

;; This package gets information about Gitlab pipelines.
;; Currently it only supports repositories hosted on gitlab.com
;; It can detect sha commit in magit-log buffer by 'magit-commit-at-point
;; Usage: M-x gitlab-pipeline-show-sha

;;; Code:

(require 'glab)
(require 'ansi-color)

(defvar-local gitlab-pipeline-host "gitlab.com/api/v4"
  "Host for gitlab api calls. Set by gitlab-pipeline-show-pipeline-from-sha")

(defun gitlab-pipeline-show-pipeline-from-sha(host project-id sha)
  "Show pipeline at SHA of PROJECT-ID in new buffer."
  (with-current-buffer (get-buffer-create (format "*Gitlab-CI:%s:/projects/%s/pipelines?sha=%s" host project-id sha))
    (erase-buffer)
    (setq-local gitlab-pipeline-host host)
    (let ((pipelines) (pipeline) (pipeline_id)
          (jobs) (job) (job_id) (i 0) (j))
      (setq pipelines (glab-get (format "/projects/%s/pipelines?sha=%s" project-id sha) nil :host host))
      (while (< i (length pipelines))
        (setq pipeline (elt pipelines i))
        (setq pipeline_id (cdr (assoc 'id pipeline)))
        (insert (format "* [%s] pipeline: %s %s\n" (cdr (assoc 'status pipeline)) pipeline_id (cdr (assoc 'web_url pipeline))))
        (setq jobs (glab-get (format "/projects/%s/pipelines/%s/jobs" project-id pipeline_id) nil :host host))
        (setq j 0)
        (while (< j (length jobs))
          (setq job (elt jobs j))
          (setq job_id (cdr (assoc 'id job)))
          (insert (format "   - [%s] job: %s@%s %s:%s"  (cdr (assoc 'status job))
                          job_id
                          (cdr (assoc 'ref job))
                          (cdr (assoc 'stage job))
                          (cdr (assoc 'name job))))
          (put-text-property (line-beginning-position) (+ (line-beginning-position) 1) 'invisible (format "/projects/%s/jobs/%s" project-id job_id))
          (end-of-line)
          (insert "\n")
          (setq j (+ j 1)))
        (insert "\n")
        (setq i (+ i 1))))
    (goto-char (point-min))
    (switch-to-buffer (current-buffer))))

;;;###autoload
(defun gitlab-pipeline-show-sha ()
  "Gitlab-pipeline-show-sha-at-point (support magit buffer)."
  (interactive)
  (if-let ((origin (shell-command-to-string "git remote get-url origin"))
           (matched (string-match "\\(git@\\|https://\\)\\([^/:]+\\)[:/]?\\(.*\\)\\(\\.git\\)\\n?" origin))
           (host (match-string 2 origin))
           (repo (match-string 3 origin)))
      (let ((sha))
        (if (fboundp 'magit-commit-at-point) (setq sha (magit-commit-at-point)))
        (unless sha (setq sha (read-string "Rev: ")))
        (setq sha (replace-regexp-in-string "\n" "" (shell-command-to-string (format "git rev-parse %s" sha))))
        (gitlab-pipeline-show-pipeline-from-sha (format "%s/api/v4" host) (url-hexify-string repo) sha))
  (user-error "Cannot parse origin: %s" origin)))

;;;###autoload
(defun gitlab-pipeline-job-trace-at-point ()
  "Gitlab pipeline job trace at point."
  (interactive)
  (let* ((jobpath (get-text-property (line-beginning-position) 'invisible))
        (path (format "%s/trace" jobpath))
        (host gitlab-pipeline-host))
    (when path
      (with-current-buffer (get-buffer-create (format "*Gitlab-CI:%s:%s" host path))
        (erase-buffer)
        (insert (cdr (car (glab-get path nil :host host))))
        (goto-char (point-min))
        (while (re-search-forward "" nil t)
          (replace-match "\n" nil nil))
        (ansi-color-apply-on-region (point-min) (point-max))
        (switch-to-buffer (current-buffer))))))

;;;###autoload
(defun gitlab-pipeline-job-cancel-at-point ()
  "Gitlab pipeline job cancel at point."
  (interactive)
  (let* ((jobpath (get-text-property (line-beginning-position) 'invisible))
         (path (format "%s/cancel" jobpath))
         (host gitlab-pipeline-host))
    (when path
      (with-current-buffer (get-buffer-create (format "*Gitlab-CI:%s:%s:CANCEL" host path))
        (erase-buffer)
        (insert (cdr (car (glab-post path nil :host host))))
        (goto-char (point-min))
        (while (re-search-forward "" nil t)
          (replace-match "\n" nil nil))
        (ansi-color-apply-on-region (point-min) (point-max))
        (switch-to-buffer (current-buffer))))))

;;; gitlab-pipeline.el ends here
(provide 'gitlab-pipeline)
