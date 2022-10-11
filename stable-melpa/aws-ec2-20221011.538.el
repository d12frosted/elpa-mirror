;;; aws-ec2.el --- Manage AWS EC2 instances -*- lexical-binding: t -*-

;; Copyright (C) 2016 Yuki Inoue

;; Author: Yuki Inoue <inouetakahiroki _at_ gmail.com>
;; URL: https://github.com/Yuki-Inoue/aws.el
;; Package-Version: 20221011.538
;; Package-Commit: 7b500097ac3c2addbe1644f78595dc2ea4eb87c4
;; Version: 0.0.3
;; Package-Requires: ((emacs "24.4") (dash "2.12.1") (tblui "0.1.0"))

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; Manipulate AWS ec2 from emacs.

;;; Code:

(require 'json)
(require 'dash)
(require 'tblui)

;;;###autoload
(defcustom aws-command (executable-find "aws")
  "The command for \\[aws-instances] and other aws-ec2 commands."
  :type 'string
  :group 'aws-ec2)

(defun aws--shell-command-to-string (&rest args)
  (with-temp-buffer
    (let* ((aws-cmd-args (append (aws-profile-args) (aws-endpoint-args) args))
           (not-used (message (combine-and-quote-strings (cons (aws-bin) aws-cmd-args))))
           (retval (apply #'call-process (aws-bin) nil (current-buffer) nil aws-cmd-args))
           (output (buffer-string)))
      (unless (= 0 retval)
        (with-current-buffer (get-buffer-create "*aws-errors*") (insert output))
        (error "The aws command failed. Check *aws-errors* for output"))
      output)))

(defun aws-endpoint-args ()
  (if aws-current-endpoint
      `("--endpoint" ,aws-current-endpoint)
    nil))

(defun aws-profile-args ()
  (if aws-current-profile
      `("--profile" ,aws-current-profile)
    nil))

(defun aws-bin ()
  (or aws-command
      (error "aws-command must be set to the path of the aws executable")))

(defun aws-ec2-all-raw-instances ()
  (interactive)
  (json-read-from-string
   (aws--shell-command-to-string "ec2" "describe-instances")))

(defun aws-ec2-normalize-raw-instances (raw-instances)
  (->>
   raw-instances
   (assoc-default 'Reservations)
   ((lambda (v) (append v nil)))
   (mapcar (apply-partially #'assoc-default 'Instances))
   (mapcar (lambda (v) (append v nil)))
   (apply #'append)
   (mapcar #'aws-instance-fix-tag)))

(defun aws-instance-fix-tag (instance)
  (->> instance
       (mapcar
        (lambda (entry)
          (if (not (equal (car entry) 'Tags))
              entry
            (cons 'Tags
                  (mapcar (lambda (kvassoc)
                            (cons (assoc-default 'Key kvassoc)
                                  (assoc-default 'Value kvassoc)))
                          (cdr entry))))))))

(defun aws-instances-get-tabulated-list-entries ()
  (->>
   (aws-ec2-normalize-raw-instances
    (aws-ec2-all-raw-instances))
   (mapcar (lambda (instance)
             (list (assoc-default 'InstanceId instance)
                   (vector (assoc-default 'InstanceId instance)
                           (assoc-default 'InstanceType instance)
                           (or (assoc-default "Name" (assoc-default 'Tags instance)) "")
                           (assoc-default 'Name (assoc-default 'State instance))
                           (prin1-to-string (assoc-default 'PrivateIpAddress instance) t)
                           (or  "..." (prin1-to-string instance))
                           ))))
   )
  )

(defun aws-instances-reboot-instances (ids)
  (apply #'aws--shell-command-to-string "ec2" "reboot-instances" "--instance-ids" ids))

(defun aws-instances-stop-instances (ids)
  (apply #'aws--shell-command-to-string "ec2" "stop-instances" "--instance-ids" ids))

(defun aws-instances-terminate-instances (ids)
  (if (yes-or-no-p (format "Really Terminate the %d instances?"
                           (length ids)))
      (apply #'aws--shell-command-to-string "ec2" "terminate-instances" "--instance-ids" ids)))

(defun aws-instances-start-instances (ids)
  (apply #'aws--shell-command-to-string "ec2" "start-instances" "--instance-ids" ids))

(defun aws-instances-inspect-instances (ids)
  (apply #'aws--shell-command-to-result-buffer "ec2" "describe-instances" "--instance-ids" ids))

(defun aws--shell-command-to-result-buffer (&rest args)
  (let ((result (apply #'aws--shell-command-to-string args))
        (buffer (get-buffer-create "*aws result*")))

    (with-current-buffer buffer
      (erase-buffer)
      (goto-char (point-max))
      (insert result))
    (display-buffer buffer)))

(defun aws-instances-rename-instance (ids)
  (if (/= 1 (length ids))
      (error "Multiple instances cannot be selected.")
    (let ((new-name (read-string "New Name: "))
          (id (nth 0 ids)))
      (aws--shell-command-to-string
       "ec2" "create-tags"
       "--resources" id "--tags" (format "Key=Name,Value=%s" new-name)))))

(defconst aws-instances-ssh-config-entry-template
  "
Host %s
  HostName %s
  User %s
  IdentityFile %s
%s
")

(defcustom aws-ec2-key-alist '()
  "The Key String to KeyPath alist"
  :type '(alist :key-type (string :tag "Key Name")
                :value-type (string :tag "KeyPath")))

(defcustom aws-instances-ssh-config-user-name "admin"
  "The ssh user name for ssh-config."
  :type 'string)

(defcustom aws-instances-ssh-config-option-entries '()
  "The ssh config entry"
  :type '(repeat string)
  )

(defun aws-instances-configure-ssh-config (ids)
  (interactive)
  (let ((aws-instances
         (->>
          ids
          (apply #'aws--shell-command-to-string
                 "ec2" "describe-instances"
                 "--instance-ids")
          (json-read-from-string)
          (aws-ec2-normalize-raw-instances))))

    (-each aws-instances
      (lambda (aws-instance)
        (let* ((host-name (->>
                          aws-instance
                          (assoc-default 'Tags)
                          (assoc-default "Name")))
               (host-ip (assoc-default 'PrivateIpAddress aws-instance))
               (key-name (assoc-default 'KeyName aws-instance))
               (key-path (assoc-default key-name aws-ec2-key-alist))
               (snippet (format
                         aws-instances-ssh-config-entry-template
                         host-name host-ip
                         aws-instances-ssh-config-user-name
                         key-path
                         (->>
                          aws-instances-ssh-config-option-entries
                          (mapcar (lambda (str) (concat "  " str)))
                          (s-join "\n")))))
          (write-region snippet nil "~/.ssh/config" 'append)
          )))))

(tblui-define
 aws-instances
 aws-instances-get-tabulated-list-entries
 [("Repository" 10 nil)
  ("InstType" 10 nil)
  ("Name" 30 nil)
  ("Status" 10 nil)
  ("IP" 15 nil)
  ("Settings" 20 nil)]
 ((:key "I"
   :name aws-instances-inspect-popup
   :funcs ((?I "Inspect" aws-instances-inspect-instances)))

  (:key "S"
   :name aws-instances-state-popup
   :funcs ((?O "Stop" aws-instances-stop-instances)
           (?R "Reboot" aws-instances-reboot-instances)
           (?T "Terminate" aws-instances-terminate-instances)
           (?S "Start" aws-instances-start-instances)))

  (:key "A"
   :name aws-instances-action-popup
   :funcs ((?R "Rename Instance" aws-instances-rename-instance)))

  (:key "C"
   :name aws-instances-configure-popup
   :funcs ((?C "Append ssh configs to ~/.ssh/config" aws-instances-configure-ssh-config)))
  ))


(defvar aws-current-endpoint nil
  "The currently used aws endpoint")

(defun aws-set-endpoint (endpoint)
  "Configures which endpoint to be used."
  (interactive "sEndpoint: ")
  (if (string= "" endpoint)
      (setq endpoint nil))
  (setq aws-current-endpoint endpoint))

(defvar aws-current-profile nil
  "The currently used aws profile")

(defun aws-set-profile (profile)
  "Configures which profile to be used."
  (interactive "sProfile: ")
  (if (string= "" profile)
      (setq profile nil))
  (setq aws-current-profile profile))

(define-key aws-instances-mode-map "P" #'aws-set-profile)

;;;###autoload
(defun aws-instances ()
  "List aws instances using aws-cli. (The `aws` command)."
  (interactive)
  (aws-instances-goto-ui))

(defvar aws-global-keymap
  (let ((map (make-sparse-keymap)))
    (define-key map "c" #'aws-instances)
    map))

(provide 'aws-ec2)

;;; aws-ec2.el ends here
