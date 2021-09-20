;;; projectile-git-autofetch.el --- automatically fetch git repositories  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Andreas Müller

;; Author: Andreas Müller <code@0x7.ch>
;; Keywords: tools, vc
;; Package-Version: 20200820.2028
;; Package-Commit: 423ed5fa6508c4edc0a837bb585c7e77e99876be
;; Version: 0.1.0
;; URL: https://github.com/andrmuel/projectile-git-autofetch
;; Package-Requires: ((emacs "25.1") (projectile "0.14.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; projectile-git-autofetch can be used to periodically fetch git
;; repositories.  Depending on the value of
;; projectile-git-autofetch-projects, only the repository for the
;; current buffer, all open projects or all projects known to
;; projectile are fetched.

;;; Code:

(require 'projectile)
(require 'notifications)

(defgroup projectile-git-autofetch nil
  "Automatically fetch git repositories."
  :group 'tools)

;;;###autoload
(define-minor-mode projectile-git-autofetch-mode
  "Fetch git repositories periodically."
  :init-value nil
  :group 'projectile-git-autofetch
  :require 'projectile-git-autofetch
  :global t
  :lighter " git-af"
  (if projectile-git-autofetch-mode
      (projectile-git-autofetch-setup)
      (projectile-git-autofetch-stop)))

(defcustom projectile-git-autofetch-projects 'open
  "Which projects to auto-fetch.

Selection of projects that should be automatically fetched."
  :package-version '(projectile-git-autofetch . "0.1.0")
  :group 'projectile-git-autofetch
  :safe (lambda (val) (memq val '(current open all)))
  :type '(choice (const current :tag "Project for current buffer only.")
                 (const open    :tag "All open projects.")
                 (const all     :tag "All known projects.")
                 (const nil     :tag "Nothing.")))

(defcustom projectile-git-autofetch-notify t
  "Whether to notify in case of new commits."
  :package-version '(projectile-git-autofetch . "0.1.0")
  :group 'projectile-git-autofetch
  :type 'boolean)

(defcustom projectile-git-autofetch-initial-delay 10
  "Initial delay in seconds before fetching."
  :package-version '(projectile-git-autofetch . "0.1.0")
  :group 'projectile-git-autofetch
  :type 'integer)

(defcustom projectile-git-autofetch-interval 300
  "Auto-fetch interval in seconds."
  :package-version '(projectile-git-autofetch . "0.1.0")
  :group 'projectile-git-autofetch
  :type 'integer)

(defcustom projectile-git-autofetch-timeout nil
  "Timeout in seconds for git processes or nil to disable."
  :package-version '(projectile-git-autofetch . "0.1.1")
  :group 'projectile-git-autofetch
  :type 'integer)

(defcustom projectile-git-autofetch-ping-host nil
  "Host to ping on order to check for Internet connectivity or nil to disable."
  :package-version '(projectile-git-autofetch . "0.1.2")
  :group 'projectile-git-autofetch
  :type 'string)

(defcustom projectile-git-autofetch-fetch-args '("--no-progress")
  "Additional arguments for git fetch."
  :package-version '(projectile-git-autofetch . "0.1.2")
  :group 'projectile-git-autofetch
  :type '(repeat string))

(defcustom projectile-git-autofetch-process-filter nil
  "Optional filter for fetch process."
  :package-version '(projectile-git-autofetch . "0.1.2")
  :group 'projectile-git-autofetch
  :type '(choice function (const nil)))

(defcustom projectile-git-autofetch-after-fetch-hook nil
  "Hooks to run after fetching a repository.
Note: runs in the git fetch buffer, so you can use projectile
functions like `projectile-project-root` to determine project
parameters."
  :group 'projectile-git-autofetch
  :type 'hook)

(defcustom projectile-git-autofetch-after-successful-fetch-hook nil
  "Hooks to run after sucessfully fetching a repository.
In contrast to `projectile-git-autofetch-after-fetch-hook`, these
hooks only run when new git objects were fetched.
Note: runs in the git fetch buffer, so you can use projectile
functions like `projectile-project-root` to determine project
parameters."
  :group 'projectile-git-autofetch
  :type 'hook)

(defun projectile-git-autofetch-sentinel (process _)
  "Handle the state of PROCESS."
  (unless (process-live-p process)
    (let ((buffer (process-buffer process))
          (default-directory (process-get process 'projectile-project)))
      (with-current-buffer buffer
        (run-hooks 'projectile-git-autofetch-after-fetch-hook)
        (when (> (buffer-size) 0)
          (run-hooks 'projectile-git-autofetch-after-successful-fetch-hook)
          (when projectile-git-autofetch-notify
            (notifications-notify
             :title (format "projectile-git-autofetch: %s" (projectile-project-name))
             :body (buffer-string) ))))
      (delete-process process)
      (kill-buffer buffer))))

(defun projectile-git-autofetch-run ()
  "Fetch all repositories and notify user."
  (if projectile-git-autofetch-ping-host
      (make-process :name "projectile-git-autofetch-ping"
                    :buffer "*projectile-git-autofetch-ping"
                    :command `("ping" "-c" "1" "-W" "3" ,projectile-git-autofetch-ping-host)
                    :sentinel 'projectile-git-autofetch--ping-sentinel
                    :noquery t)
      (projectile-git-autofetch--work)))

(defun projectile-git-autofetch--ping-sentinel (process event)
  "Sentinel function for PROCESS to check ping success given EVENT."
  (when (string= "finished\n" event)
    (projectile-git-autofetch--work))
  (let ((buffer (process-buffer process)))
    (when (not (get-buffer-process buffer))
      (delete-process process)
      (kill-buffer buffer))))

(defun projectile-git-autofetch--work ()
  "Worker function to fetch all repositories."
  (let ((projects (cond
                   ((eq projectile-git-autofetch-projects 'current)
                    (list (projectile-project-root)))
                   ((eq projectile-git-autofetch-projects 'open)
                    (projectile-open-projects))
                   ((eq projectile-git-autofetch-projects 'all)
                    projectile-known-projects)
                   (t nil))))
    (dolist (project projects)
      (let ((default-directory project))
        (when (and (file-directory-p ".git")
                   (car (ignore-errors
                          (process-lines "git" "config" "--get" "remote.origin.url"))))
          (let* ((buffer (generate-new-buffer " *git-fetch"))
                 (process
                  (apply #'start-process "git-fetch" buffer "git" "fetch" projectile-git-autofetch-fetch-args)))
            (process-put process 'projectile-project project)
            (when projectile-git-autofetch-process-filter
              (set-process-filter process projectile-git-autofetch-process-filter))
            (set-process-query-on-exit-flag process nil)
            (set-process-sentinel process #'projectile-git-autofetch-sentinel)
            (when projectile-git-autofetch-timeout
              (add-timeout projectile-git-autofetch-timeout 'projectile-git-autofetch-timeout-handler process))))))))

(defun projectile-git-autofetch-timeout-handler (process)
  "Timeout handler to kill slow or blocked PROCESS."
  (delete-process process))

(defvar projectile-git-autofetch-timer nil
  "Timer object for git fetches.")

(defun projectile-git-autofetch-setup ()
  "Set up timers to periodically fetch repositories."
  (interactive)
  (unless (timerp projectile-git-autofetch-timer)
    (setq projectile-git-autofetch-timer
          (run-with-timer
           projectile-git-autofetch-initial-delay
           projectile-git-autofetch-interval
           'projectile-git-autofetch-run))))

(defun projectile-git-autofetch-stop ()
  "Stop auto fetch timers."
  (interactive)
  (cancel-timer projectile-git-autofetch-timer)
  (setq projectile-git-autofetch-timer nil))

(provide 'projectile-git-autofetch)
;;; projectile-git-autofetch.el ends here
