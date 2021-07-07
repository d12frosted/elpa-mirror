;;; dashboard-project-status.el --- Display a git project status in a dashboard widget.     -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Jason Duncan, all rights reserved

;; Author:  Jason Duncan <jasond496@msn.com>
;; Version: 0.0.1
;; Package-Version: 20190202.1354
;; Package-Commit: 7675c138e9df8fe2c626e7ba9bbb8b6717671a41
;; URL: https://github.com/functionreturnfunction/dashboard-project-status
;; Package-Requires: ((emacs "24") (git "0.1.1") (dashboard "1.2.5"))

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Display a git project status in a dashboard widget.

;; See README.org for installation and usage.

;;; Code:

(require 'git)
(require 'dashboard)

(defun dashboard-project-status-git-local-is-behind? ()
  "Return non-nil if current `git-repo' is behind its remote."
  (numberp
   (string-match-p
    (regexp-quote "Your branch is behind")
    (git-run "status" "-uno"))))

(defun dashboard-project-status-git-unstaged-files ()
  "Return list of unstaged files."
  (git--lines
   (git-run "diff" "--name-only")))

(defun dashboard-project-status-insert-heading ()
  "Insert a heading with project path and whether or not it is behind."
  (dashboard-insert-heading "Project ")
  (if (functionp 'magit-status)
      (widget-create 'push-button
                     :action `(lambda (&rest ignore) (magit-status ,git-repo))
                     :mouse-face 'highlight
                     :follow-link "\C-m"
                     :button-prefix ""
                     :button-suffix ""
                     :format "%[%t%]"
                     (abbreviate-file-name git-repo))
    (dashboard-insert-heading git-repo))
  (dashboard-insert-heading
   (if (dashboard-project-status-git-local-is-behind?)
       " is behind the remote. (use \"git pull\" to update)"
     " is up-to-date.")))

(defun dashboard-project-status-insert-body (limit)
  "Insert lists of untracked, unstaged, and staged files LIMIT -ed as specified."
  (let ((count 0))
    (dolist (section `(("Untracked Files:" . ,(git-untracked-files))
                       ("Unstaged Files:"  . ,(dashboard-project-status-git-unstaged-files))
                       ("Staged Files:"    . ,(git-staged-files))))
      (when (cdr section)
        (let* ((items (cdr section))
               (items (if (> (+ count (length items)) limit)
                          (dashboard-subseq items 0 (- limit count))
                        items)))
          (when items
            (setq count (+ count (length items)))
            (insert hard-newline)
            (dashboard-insert-recentf-list
             (car section)
             (reverse
              (let (ret)
                (dolist (cur items ret)
                  (setq ret (cons (expand-file-name
                                   (concat (file-name-as-directory git-repo) cur))
                                  ret))))))))))))

(defun dashboard-project-status (project-dir &optional update)
  "Return a function which will insert git status for PROJECT-DIR.
If UPDATE is non-nil, update the remote first with 'git remote update'."
  `(lambda (list-size)
     (let ((git-repo ,project-dir))
       (when ,update (git-run "remote" "update"))
       (dashboard-project-status-insert-heading)
       (dashboard-project-status-insert-body list-size))))

(provide 'dashboard-project-status)
;;; dashboard-project-status.el ends here
