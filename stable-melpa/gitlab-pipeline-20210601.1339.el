;;; gitlab-pipeline.el --- Get infomation about Gitlab pipelines -*- lexical-binding: t -*-

;; Copyright (C) 2020 Giap Tran <txgvnn@gmail.com>

;; Author: Giap Tran <txgvnn@gmail.com>
;; URL: https://github.com/TxGVNN/gitlab-pipeline
;; Package-Version: 20210601.1339
;; Package-Commit: 2404f9cf0a064aabea975adada250895c385e057
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

(defun gitlab-pipeline-show-refresh ()
  (interactive)
  (if (and gitlab-pipeline-buffer-host
           gitlab-pipeline-buffer-project-id
           gitlab-pipeline-buffer-sha)
      (gitlab-pipeline-show-pipeline-from-sha gitlab-pipeline-buffer-host
                                              gitlab-pipeline-buffer-project-id
                                              gitlab-pipeline-buffer-sha)
    (user-error "Not called from a gitlab-pipeline show buffer")))

(defun gitlab-pipeline-show-pipeline-from-sha(host project-id sha)
  "Show pipeline at SHA of PROJECT-ID in new buffer."
  (with-current-buffer (get-buffer-create (format "*Gitlab-CI:%s:/projects/%s/pipelines?sha=%s" host project-id sha))
    (setq-local gitlab-pipeline-buffer-host host)
    (setq-local gitlab-pipeline-buffer-project-id project-id)
    (setq-local gitlab-pipeline-buffer-sha sha)

    (let ((inhibit-read-only t))
      (erase-buffer)
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
          (setq i (+ i 1)))))

    (goto-char (point-min))
    (switch-to-buffer (current-buffer))
    (setq-local buffer-read-only t)))

(setq gitlab-pipeline--url-regexp
      ;; This URL regular expression has been copied from forge:
      ;; https://github.com/magit/forge/blob/551e51511e25505d14e05699a1707fd57e394a9a/lisp/forge-core.el#L242
      (concat "\\`\\(?:git://\\|"
              "[^/@]+@\\|"
              "\\(?:ssh\\|ssh\\+git\\|git\\+ssh\\)://\\(?:[^/@]+@\\)?\\|"
              "https?://\\(?:[^/@]+@\\)?\\)"
              "\\([^:]*\\)"
              "\\(:[0-9]+\\)?"
              "\\(?:/\\|:/?\\)"
              "\\(.+?\\)"
              "\\(?:\\.git\\|/\\)?\n\\'"))

(defun gitlab-pipeline--split-url (url)
  "Return a list of '(host port repo) for a given path."
  (and (string-match gitlab-pipeline--url-regexp url)
       (list (match-string 1 url)
             (match-string 2 url)
             (match-string 3 url))))

;;;###autoload
(defun gitlab-pipeline-show-sha ()
  "Gitlab-pipeline-show-sha-at-point (support magit buffer)."
  (interactive)
  (if-let ((origin (shell-command-to-string "git remote get-url origin"))
           (parts (gitlab-pipeline--split-url origin))
           (host (nth 0 parts))
           (repo (nth 2 parts)))
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
         (host gitlab-pipeline-buffer-host))
    (when path
      (with-current-buffer (get-buffer-create (format "*Gitlab-CI:%s:%s" host path))
        (erase-buffer)
        (insert (cdr (car (glab-get path nil :host host))))
        (goto-char (point-min))
        (while (re-search-forward "" nil t)
          (replace-match "\n" nil nil))
        (ansi-color-apply-on-region (point-min) (point-max))
        (switch-to-buffer (current-buffer))
        (setq-local buffer-read-only t)))))

;;;###autoload
(defun gitlab-pipeline-job-retry-at-point ()
  "Gitlab pipeline job trace at point."
  (interactive)
  (let* ((jobpath (get-text-property (line-beginning-position) 'invisible))
         (path (format "%s/retry" jobpath))
         (host gitlab-pipeline-buffer-host))
    (when path
      (glab-post path nil :host host)
      (message "Done"))))

;;;###autoload
(defun gitlab-pipeline-job-cancel-at-point ()
  "Gitlab pipeline job cancel at point."
  (interactive)
  (let* ((jobpath (get-text-property (line-beginning-position) 'invisible))
         (path (format "%s/cancel" jobpath))
         (host gitlab-pipeline-buffer-host))
    (when path
      (glab-post path nil :host host)
      (message "Done"))))

;;; gitlab-pipeline.el ends here
(provide 'gitlab-pipeline)
