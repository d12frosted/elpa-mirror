;;; activity-watch-mode.el --- Automatic time tracking extension. -*- lexical-binding: t; -*-

;; Copyright (C) 2013  Gabor Torok <gabor@20y.hu>

;; Author: Gabor Torok <gabor@20y.hu>, Alan Hamlett <alan@wakatime.com>
;; Maintainer: Paul d'Hubert <paul.dhubert@ya.ru>
;; Website: https://activitywatch.net
;; Homepage: https://github.com/pauldub/activity-watch-mode
;; Keywords: calendar, comm
;; Package-Version: 20220111.1121
;; Package-Commit: 789ec3425623e43a29755e8daaa02305df8da8ed
;; Package-Requires: ((emacs "25") (request "0") (json "0") (cl-lib "0"))
;; Version: 1.0.2

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

;; ActivityWatch mode based on https://github.com/wakatime/wakatime-mode
;;
;; Enable Activity-Watch for the current buffer by invoking
;; `activity-watch-mode'.  If you wish to activate it globally, use
;; `global-activity-watch-mode'.
;;
;; Requires request.el (https://tkf.github.io/emacs-request/)
;;

;;; Dependencies: request, json, cl-lib

;;; Code:

(require 'ert)
(require 'request)
(require 'json)
(require 'cl-lib)
(require 'subr-x)

(defconst activity-watch-version "1.0.0")
(defconst activity-watch-user-agent "emacs-activity-watch")
(defvar activity-watch-noprompt nil)
(defvar activity-watch-timer nil)
(defvar activity-watch-idle-timer nil)
(defvar activity-watch-init-started nil)
(defvar activity-watch-init-finished nil)
(defvar activity-watch-bucket-created nil)
(defvar activity-watch-last-file-path nil)
(defvar activity-watch-pulse-time 30)
(defvar activity-watch-max-heartbeat-per-sec 1)
(defvar activity-watch-last-heartbeat-time nil)

(defvar-local activity-watch-project-name nil
  "Cached value of the project this file belongs to")

(defgroup activity-watch nil
  "Customizations for Activity-Watch"
  :group 'convenience
  :prefix "activity-watch-")

(defcustom activity-watch-api-host "http://localhost:5600"
  "API host for Activity-Watch."
  :type 'string
  :group 'activity-watch)

(defcustom activity-watch-project-name-default "unknown"
  "Default name for a non-identifiable project."
  :type 'string
  :group 'activity-watch)

(defcustom activity-watch-project-name-resolvers '(projectile magit-dir-force magit-origin)
  "List of resolvers used to find the project name.

When determining the name of a project, the watcher will go down the list
and for each name tries to call the function \
`activity-watch-project-name-<symbol>' with no parameters.
If the function returns a non-emtpy string, it will be used as the project name.
Otherwise, the following resolver in the list will be queried.

If no resolver is able to identify the project, \
`activity-watch-project-name-default' is assumed.

Methods provided by default are listed below.
Every resolver that depends on an external package has a -force version.
The default resolver checks if the package is loaded, and fails early if not.
The forced resolver tries to `require' the package.

projectile:
projectile-force:
  Return the project name from `projectile-project-name'.

magit-dir:
magit-dir-force:
  Return the name of the directory where the repository is located.

magit-origin:
magit-origin-force:
  Return the name of the repository extracted from the 'origin' remote.

cwd:
  Return the name of the current working directory."
  :type '(list symbol)
  :group 'activity-watch)

(defmacro activity-watch--gen-feature-resolver (feature name &rest body)
  "Generate a pair of functions: `activity-watch-project-name-<NAME>' \
and `activity-watch-project-name-<NAME>-force'. The forced version will try \
to `require' FEATURE first."
  (declare (indent 2))
  (let ((func (intern (concat
                       "activity-watch-project-name-"
                       (symbol-name name))))
        (forced (intern (concat
                         "activity-watch-project-name-"
                         (symbol-name name)
                         "-force")))
        (feature-name (cond
                       ((symbolp feature)
                        (symbol-name feature))
                       ((and (listp feature) (eq (car feature) 'quote))
                        (symbol-name (cadr feature)))
                       (t "<feature>")))
        (docstring (when (and (stringp (car body))
                              (cdr body))
                     (prog1
                         (concat "\n\n" (car body))
                       (setq body (cdr body))))))
    `(progn
       (defun ,func ()
         ,(concat "Check if feature `" feature-name "' is provided, \
and when it is, use it to find the project's name." docstring)
         (when (featurep ,feature)
           ,@body))
       (defun ,forced ()
         ,(concat "Try to require feature `" feature-name "', and on success \
use it to find the project's name." docstring)
         (when (require ,feature nil t)
           ,@body)))))

(activity-watch--gen-feature-resolver 'projectile projectile
  (when (projectile-project-p)
       (projectile-project-name)))

(activity-watch--gen-feature-resolver 'magit magit-dir
  "This implementation returns the directory name where the repository is saved localy."
  (when-let ((toplevel (magit-toplevel)))
      (file-name-nondirectory (directory-file-name toplevel))))

(activity-watch--gen-feature-resolver 'magit magit-origin
  "This implementation tries to parse the URL of the remote 'origin'."
  (when-let ((remote (magit-git-string "remote" "get-url" "origin"))
             (proj (string-trim (car (last (split-string-and-unquote remote "/")))
                                nil
                                ".git")))
    proj))

(defun activity-watch-project-name-cwd ()
  "Return the name of the `default-directory'."
  (when default-directory
    (file-name-nondirectory (directory-file-name (expand-file-name default-directory)))))

(defun activity-watch--get-project (&optional refresh)
  "Return the name of the project. If REFRESH is non-nil, disable cache.
How the name is discoved depends on which resolvers are \
specified in `activity-watch-project-name-resolvers'."
       (setq-local activity-watch-project-name
                   (or (and (not refresh)
                            activity-watch-project-name)
                       (cl-dolist (res activity-watch-project-name-resolvers)
                         (if-let ((fun (intern (concat "activity-watch-project-name-"
                                                       (symbol-name res))))
                                  ((fboundp fun))
                                  (proj (funcall fun))
                                  ((not (activity-watch--s-blank proj))))
                             (cl-return proj)))
                       activity-watch-project-name-default)))

(defun activity-watch--s-blank (string)
  "Return non-nil if the STRING is empty or nil.  Expects string."
  (or (null string)
      (zerop (length string))))

(defun activity-watch--init ()
  "Initialize symbol ‘activity-watch-mode’."
  (unless activity-watch-init-started
    (setq activity-watch-init-started t)
    (setq activity-watch-init-finished t)))

(defun activity-watch--bucket-id ()
  "Return the bucket-id to be used when submitting heartbeats."
  (concat "aw-watcher-emacs_" (system-name)))

(defun activity-watch--create-bucket ()
  "Create the editor bucket."
  (when (not activity-watch-bucket-created)
    (request (concat activity-watch-api-host "/api/0/buckets/" (activity-watch--bucket-id))
             :type "POST"
             :data (json-encode `((hostname . ,(system-name))
                                  (client . ,activity-watch-user-agent)
                                  (type . "app.editor.activity")))
             :headers '(("Content-Type" . "application/json"))
             :success (cl-function
                       (lambda (&rest _ &allow-other-keys)
                         (setq activity-watch-bucket-created t))))))

(defun activity-watch--create-heartbeat (time)
  "Create heartbeart to sent to the activity watch server.
Argument TIME time at which the heartbeat was computed."
  (let ((project-name (activity-watch--get-project))
        (file-name (buffer-file-name (current-buffer)))
        (git-branch (when (fboundp 'magit-get-current-branch) (magit-get-current-branch))))
    `((timestamp . ,(ert--format-time-iso8601 time))
      (duration . 0)
      (data . ((language . ,(if (activity-watch--s-blank (symbol-name major-mode)) "unknown" major-mode))
               (project . ,project-name)
               (file . ,(if (activity-watch--s-blank file-name) "unknown" file-name))
               (branch . ,(or git-branch "unknown")))))))

(defun activity-watch--send-heartbeat (heartbeat)
  "Send HEARTBEAT to activity watch server."
  (request (concat activity-watch-api-host "/api/0/buckets/" (activity-watch--bucket-id) "/heartbeat")
           :type "POST"
           :params `(("pulsetime" . ,activity-watch-pulse-time))
           :data (json-encode heartbeat)
           :headers '(("Content-Type" . "application/json"))
           :error (cl-function
                   (lambda (&key data &allow-other-keys)
                     (message data) (global-activity-watch-mode 0) (activity-watch-mode 0)))))

(defun activity-watch--call ()
  "Conditionally submit heartbeat to activity watch."
  (activity-watch--create-bucket)
  (let ((now (float-time))
        (current-file-path (buffer-file-name (current-buffer)))
        (time-delta (+ (or activity-watch-last-heartbeat-time 0) activity-watch-max-heartbeat-per-sec)))
    (if (or (not (string= (or activity-watch-last-file-path "") current-file-path))
            (< time-delta now))
        (progn
          (setq activity-watch-last-file-path current-file-path)
          (setq activity-watch-last-heartbeat-time now)
          (activity-watch--send-heartbeat (activity-watch--create-heartbeat (current-time)))))))

(defun activity-watch--save ()
  "Send save notice to Activity-Watch."
  (save-match-data
    (when (and (buffer-file-name (current-buffer))
               (not (auto-save-file-name-p (buffer-file-name (current-buffer)))))
      (activity-watch--call))))

(defun activity-watch--start-timer ()
  "Start timers for heartbeat submission and idling."
  (unless activity-watch-timer
      (setq activity-watch-timer (run-at-time t 2 #'activity-watch--save)))
  (unless activity-watch-idle-timer
      ;; stop the timer after 30s inactivity
      (setq activity-watch-idle-timer (run-with-idle-timer 30 t #'activity-watch--stop-timer))))

(defun activity-watch--stop-timer ()
  "Stop heartbeat submission timer."
  (when activity-watch-timer
    (cancel-timer activity-watch-timer)
    (setq activity-watch-timer nil)))

(defun activity-watch--stop-idle-timer ()
  "Stop idling timer."
  (when activity-watch-idle-timer
    (cancel-timer activity-watch-idle-timer)
    (setq activity-watch-idle-timer nil)))

(defun activity-watch--bind-hooks ()
  "Watch for activity in buffers."
  (add-hook 'pre-command-hook #'activity-watch--start-timer nil t)
  (add-hook 'after-save-hook #'activity-watch--save nil t)
  (add-hook 'auto-save-hook #'activity-watch--save nil t)
  (add-hook 'first-change-hook #'activity-watch--save nil t))

(defun activity-watch--unbind-hooks ()
  "Stop watching for activity in buffers."
  (remove-hook 'pre-command-hook #'activity-watch--start-timer t)
  (remove-hook 'after-save-hook #'activity-watch--save t)
  (remove-hook 'auto-save-hook #'activity-watch--save t)
  (remove-hook 'first-change-hook #'activity-watch--save t))

(defun activity-watch-turn-on (defer)
  "Turn on Activity-Watch.
Argument DEFER Wether initialization should be deferred."
  (if defer
      (run-at-time "1 sec" nil #'activity-watch-turn-on nil)
    (progn
      (activity-watch--init)
      (if activity-watch-init-finished
          (progn (activity-watch--bind-hooks) (activity-watch--start-timer))
        (run-at-time "1 sec" nil #'activity-watch-turn-on nil)))))

(defun activity-watch-turn-off ()
  "Turn off Activity-Watch."
  (activity-watch--unbind-hooks)
  (activity-watch--stop-timer)
  (activity-watch--stop-idle-timer))

;;;###autoload
(defun activity-watch-refresh-project-name ()
  "Recompute the name of the project for the current file."
  (interactive)
  (activity-watch--get-project t))

;;;###autoload
(define-minor-mode activity-watch-mode
  "Toggle Activity-Watch (Activity-Watch mode)."
  :lighter    " activity-watch"
  :init-value nil
  :global     nil
  :group      'activity-watch
  (cond
   (noninteractive (setq activity-watch-mode nil))
   (activity-watch-mode (activity-watch-turn-on t))
   (t (activity-watch-turn-off))))

;;;###autoload
(define-globalized-minor-mode global-activity-watch-mode
  activity-watch-mode
  (lambda () (activity-watch-mode 1))
  :require 'activity-watch-mode)

(provide 'activity-watch-mode)
;;; activity-watch-mode.el ends here
