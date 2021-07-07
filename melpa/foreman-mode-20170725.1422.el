;;; foreman-mode.el --- View and manage Procfile-based applications

;; Copyright (C) 2015 ZHOU Feng

;; Author: ZHOU Feng <zf.pascal@gmail.com>
;; URL: http://github.com/zweifisch/foreman-mode
;; Package-Version: 20170725.1422
;; Package-Commit: 22b3bb13134b617870ed1e888af739f4818be929
;; Keywords: foreman
;; Version: 0.0.1
;; Created: 17th Apr 2015
;; Package-Requires: ((s "1.9.0") (dash "2.10.0") (dash-functional "1.2.0") (f "0.17.2") (emacs "24"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Manage Procfile-based applications
;;

;;; Code:
(require 's)
(require 'f)
(require 'dash)
(require 'tabulated-list)
(require 'ansi-color)


(defcustom foreman-procfile-name "Procfile"
  "Procfile name"
  :group 'foreman
  :type 'string)

(defvar foreman-tasks '())

(defvar foreman-current-id nil)

(defvar foreman-local-task-id nil)

(defvar foreman-mode-map nil "Keymap for foreman mode.")

(setq foreman-mode-map (make-sparse-keymap))
(define-key foreman-mode-map "q" 'quit-window)
(define-key foreman-mode-map "s" 'foreman-start-proc)
(define-key foreman-mode-map "r" 'foreman-restart-proc)
(define-key foreman-mode-map (kbd "RET") 'foreman-view-buffer)
(define-key foreman-mode-map "k" 'foreman-kill-proc)
(define-key foreman-mode-map "d" 'foreman-kill-buffer)
(define-key foreman-mode-map "e" 'foreman-edit-env)
(define-key foreman-mode-map "n" 'foreman-next-line)
(define-key foreman-mode-map "p" 'foreman-previous-line)

(define-derived-mode foreman-mode tabulated-list-mode "Foreman"
  "foreman-mode to manage procfile-based applications"
  (setq tabulated-list-format [("name" 12 t)
                               ("status" 12 t)
                               ("command" 12 nil)])
  (setq tabulated-list-padding 2)
  (setq tabulated-list-sort-key (cons "name" nil))
  (tabulated-list-init-header)
  (hl-line-mode)
  (add-hook 'tabulated-list-revert-hook 'foreman nil t))

(defvar foreman-env-mode-map nil "Keymap for foreman-env mode.")
(setq foreman-env-mode-map (make-sparse-keymap))
(define-key foreman-env-mode-map (kbd "C-c C-c") 'foreman-env-save)
(define-key foreman-env-mode-map (kbd "C-c C-k") 'foreman-env-abort)

(defvar foreman-env-font-lock-defaults nil)
(setq foreman-env-font-lock-defaults
  `(("^\\([^#=]+\\)=\\(.*\\)$" (1 font-lock-variable-name-face) (2 font-lock-string-face))
    ("^\\(#.*\\)$" (1 font-lock-comment-face))))

(define-derived-mode foreman-env-mode fundamental-mode "Foreman ENV"
  "mode for editing process enviroment variables"
  (setq font-lock-defaults '(foreman-env-font-lock-defaults)))

;;;###autoload
(defun foreman ()
  (interactive)
  (let ((procfile (foreman-find-procfile)))
    (when procfile
      (let ((procs (foreman-load-procfile procfile)))
        (switch-to-buffer
         (foreman-fill-buffer procs))))))

;;;###autoload
(defun foreman-start ()
  (interactive)
  (let ((procfile (foreman-find-procfile)))
    (when procfile
      (let ((procs (foreman-load-procfile (foreman-find-procfile))))
        (-each procs 'foreman--start-proc)
        (switch-to-buffer
         (foreman-fill-buffer procs))))))

(defun foreman-stop ()
  (interactive)
  (let ((procfile (foreman-find-procfile)))
    (when procfile
      (-each (foreman-load-procfile procfile)
        (lambda (task-id)
          (when (assoc task-id foreman-tasks)
            (let ((buffer (foreman-get-in foreman-tasks task-id 'buffer)))
              (if buffer (kill-buffer buffer)))
            (setq foreman-tasks (delq (assoc task-id foreman-tasks) foreman-tasks)))))
      (message "All process killed"))))

(defun foreman-clear ()
  (interactive)
  (setq foreman-tasks nil))

(defun foreman-restart ()
  (interactive)
  (foreman-stop)
  (foreman-start))

(defun foreman-next-line ()
  (interactive)
  (when (> (count-lines (point) (point-max)) 1)
      (forward-line 1)
      (setq foreman-current-id (get-text-property (point) 'tabulated-list-id))
      (foreman-view-buffer)))

(defun foreman-previous-line ()
  (interactive)
  (forward-line -1)
  (setq foreman-current-id (get-text-property (point) 'tabulated-list-id))
  (foreman-view-buffer))

(defun foreman-load-procfile (path)
  (let ((directory (f-parent path)))
    (with-temp-buffer
      (if (f-readable? path)
          (insert-file-contents path))
      (->> (s-lines (buffer-string))
           (-remove 's-blank?)
           (-remove (-partial 's-starts-with? "#"))
           (-map (-partial 's-split ":"))
           (-map (lambda (task)
                   (let ((key (format "%s:%s" directory (car task))))
                     (if (not (assoc key foreman-tasks))
                         (setq foreman-tasks
                               (cons `(,key . ((name . ,(s-trim (car task)))
                                               (directory . ,directory)
                                               (command . ,(s-trim (cadr task)))))
                                     foreman-tasks)))
                     key)))))))

(defun foreman-find-procfile ()
  (let ((dir (f-traverse-upwards
              (lambda (path)
                (f-exists? (f-expand foreman-procfile-name path)))
              ".")))
    (if dir (f-expand foreman-procfile-name dir)
      (message "Procfile not found"))))

(defun foreman-process-output-filter (proc string)
  (when (buffer-live-p (process-buffer proc))
    (with-current-buffer (process-buffer proc)
      (let* ((mark (process-mark proc))
             (moving (= (point) mark)))
        (save-excursion
          (goto-char mark)
          (insert string)
          (ansi-color-apply-on-region mark (point-max))
          (set-marker mark (point-max)))
        (if moving (goto-char (process-mark proc)))))))

(defun foreman-make-task-buffer (task-name working-directory)
  (let ((buffer (generate-new-buffer task-name)))
    (with-current-buffer buffer
      (buffer-disable-undo)
      (setq default-directory (f-slash working-directory))
      (set (make-local-variable 'window-point-insertion-type) t))
    buffer))

(defun foreman-ensure-task-buffer (task-name working-directory buffer)
  (if (buffer-live-p buffer) buffer
    (foreman-make-task-buffer task-name working-directory)))

(defun foreman-env-save ()
  (interactive)
  (let ((lines (->> (buffer-string)
                    s-lines
                    (-remove 's-blank?)
                    (-remove (-partial 's-starts-with? "#"))))
        (task (cdr (assoc foreman-local-task-id foreman-tasks))))
    (if (assoc 'env task)
        (setf (cdr (assoc 'env task)) lines)
      (setq task (cons `(env . ,lines) task)))
    (setf (cdr (assoc foreman-local-task-id foreman-tasks)) task))
  (set-buffer-modified-p nil)
  (kill-buffer))

(defun foreman-env-abort ()
  (interactive)
  (kill-buffer))

(defun foreman-edit-env ()
  (interactive)
  (let ((task-id (get-text-property (point) 'tabulated-list-id))
        (buffer (get-buffer-create "*foreman-env*")))
    (with-current-buffer buffer
      (erase-buffer)
      (foreman-env-mode)
      (set (make-local-variable 'foreman-local-task-id) task-id)
      (insert "# Environment variables will be passed when start/restart process
# C-c C-c to save, C-c C-k to abort
# Example:
#
#   http_proxy=http://localhost:8080
#\n")
      (-each (foreman-get-in foreman-tasks task-id 'env)
        (lambda (variable) (insert (format "%s\n" variable))))
      (goto-line 7))
    (switch-to-buffer buffer)))

(defun foreman-start-proc ()
  (interactive)
  (let ((task-id (get-text-property (point) 'tabulated-list-id)))
    (foreman--start-proc task-id)
    (revert-buffer)
    (display-buffer (foreman-get-in foreman-tasks task-id 'buffer) t)))

(defun foreman--start-proc (task-id)
  (if (not (process-live-p (foreman-get-in foreman-tasks task-id 'process)))
      (let* ((task (cdr (assoc task-id foreman-tasks)))
             (command (cdr (assoc 'command task)))
             (directory (cdr (assoc 'directory task)))
             (name (format "*%s:%s*" (-last-item (f-split directory)) (cdr (assoc 'name task))))
             (buffer (foreman-ensure-task-buffer name directory (cdr (assoc 'buffer task))))
             (env (cdr (assoc 'env task)))
             (process (with-current-buffer buffer
                        (erase-buffer)
                        (let ((process-environment (append env process-environment)))
                          (apply 'start-process-shell-command name buffer (s-split " +" command))))))
        (set-process-filter process 'foreman-process-output-filter)
        (if (assoc 'buffer task)
            (setf (cdr (assoc 'buffer task)) buffer)
          (setq task (cons `(buffer . ,buffer) task)))
        (if (assoc 'process task)
            (setf (cdr (assoc 'process task)) process)
          (setq task (cons `(process . ,process) task)))
        (setf (cdr (assoc task-id foreman-tasks)) task))))

(defun foreman-kill-proc ()
  (interactive)
  (let* ((task-id (get-text-property (point) 'tabulated-list-id))
         (task (cdr (assoc task-id foreman-tasks)))
         (process (cdr (assoc 'process task))))
    (when (and (process-live-p process)
               (y-or-n-p (format "kill process %s? " (process-name process))))
      (foreman-kill-process-timeout process 2)
      (revert-buffer))))

(defun foreman-kill-buffer ()
  (interactive)
  (let* ((task-id (get-text-property (point) 'tabulated-list-id))
         (buffer (foreman-get-in foreman-tasks task-id 'buffer)))
    (when (and (buffer-live-p buffer)
               (y-or-n-p (format "kill buffer %s? " (buffer-name buffer))))
      (kill-buffer buffer)
      (revert-buffer))))

(defun foreman-error-buffer (msg)
  (let ((buffer (get-buffer-create "*foreman-error*")))
    (with-current-buffer buffer
      (erase-buffer)
      (insert msg))
    buffer))

(defun foreman-view-buffer ()
  (interactive)
  (let* ((task-id (get-text-property (point) 'tabulated-list-id))
         (buffer (foreman-get-in foreman-tasks task-id 'buffer)))
    (display-buffer (if (buffer-live-p buffer) buffer
                     (foreman-error-buffer "application not running\n")) t)))

(defun foreman-get-in (alist &rest keys)
  (if keys
      (apply 'foreman-get-in (cdr (assoc (car keys) alist)) (cdr keys))
    alist))

(defun foreman-kill-process-timeout (process timeout)
  (kill-process process)
  (with-timeout (timeout nil)
    (while (process-live-p process)
      (sit-for .05))
    t))

(defun foreman-restart-proc ()
  (interactive)
  (let* ((task-id (get-text-property (point) 'tabulated-list-id))
         (process (foreman-get-in foreman-tasks task-id 'process )))
    (if (y-or-n-p (format "restart process %s? " (process-name process)))
        (progn
          (if (foreman-kill-process-timeout process 2)
              (foreman--start-proc task-id)
            (message "process still alive"))
          (revert-buffer)))))

(defun foreman-fill-buffer (task-ids)
  (let ((directory default-directory)
        (buffer (get-buffer-create "*foreman*")))
    (with-current-buffer buffer
      (setq default-directory directory)
      (setq buffer-read-only nil)
      (erase-buffer)
      (foreman-mode)
      (setq tabulated-list-entries
            (-filter (lambda (task)
                       (-contains? task-ids (car task)))
                     (foreman-task-tabulate)))
      (tabulated-list-print t)
      (setq buffer-read-only t)
      (foreman-restore-cursor))
    buffer))

(defun foreman-task-tabulate ()
  (-map (lambda (task)
          (let* ((detail (cdr task))
                 (process (cdr (assoc 'process detail))))
            (list (car task)
                  (vconcat
                   (list (cdr (assoc 'name detail))
                         (if process (symbol-name (process-status process)) "")
                         (cdr (assoc 'command detail)))))))
        foreman-tasks))

(defun foreman-restore-cursor ()
  (when foreman-current-id
      (while (and (> (count-lines (point) (point-max)) 1)
                  (not (string= foreman-current-id
                                (get-text-property (point) 'tabulated-list-id))))
        (next-line))
      (beginning-of-line)))

(provide 'foreman-mode)
;;; foreman-mode.el ends here
