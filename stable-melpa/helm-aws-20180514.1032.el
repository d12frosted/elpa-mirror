;;; helm-aws.el --- Manage AWS EC2 server instances directly from Emacs

;; Copyright (C) 2014 istib

;; Author: istib
;; URL: https://github.com/istib/helm-aws
;; Package-Version: 20180514.1032
;; Package-Commit: b36c744b3f00f458635a91d1f5158fccbb5baef6
;; Version: 20141205.1
;; X-Original-Version: 0.2
;; Package-Requires: ((helm "1.5.3")(cl-lib "0.5")(s "1.9.0"))
;; Keywords:

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Manage AWS EC2 server instances directly from Emacs

;; A call to `helm-aws' will show a list of running instances on your configured
;; AWS account.  Helm actions to launch a terminal, dired, or ping are accessible.
;; 
;; Requires a configured installation of AWS command-line interface (http://aws.amazon.com/cli/)


;;; Code:
(require 'json)
(require 'cl-lib)
(require 's)

(defgroup helm-aws-faces nil
  "Customize the appearance of helm-aws."
  :prefix "helm-"
  :group 'helm-aws
  :group 'helm-faces)

(defface helm-aws-instance-state-running
  '((t :inherit font-lock-builtin-face))
  "Face used for running instances in `helm-aws'."
  :group 'helm-aws-faces)

(defface helm-aws-instance-state-stopped
  '((t :inherit font-lock-comment-face
       :slant italic
       :foreground "red"))
  "Face used for stopped instances in `helm-aws'."
  :group 'helm-aws-faces)

(defface helm-aws-instance-state-terminated
  '((t :inherit font-lock-comment-face
       :strike-through t))
  "Face used for terminated instances in `helm-aws'."
  :group 'helm-aws-faces)

(defvar aws-user-account
  "ubuntu"
  "User account name for AWS servers.  Assuming that your PEM keys are placed on each instance.")

(defvar aws-ec2-command
  "aws ec2 describe-instances"
  "Command to list instances.  Run `aws configure` to set up AWS cli.")

(defun aws-run-ec2-command ()
  "Return the full json from running describe-instances."
  (let ((aws-result-buffer (generate-new-buffer-name "*aws-ec2*")))
    (with-temp-buffer
      (shell-command aws-ec2-command (current-buffer) nil)
      (buffer-substring-no-properties (point-min) (point-max)))))

(defun aws-parse-server-list (input)
  "Extract instances from describe-instances.
Argument INPUT json input in string form."
  (let* ((json-object-type 'plist)
         (aws-json         (json-read-from-string input))
         (reservations     (plist-get aws-json :Reservations))
         (instances        (mapcar (lambda (el) (plist-get el :Instances)) reservations))
         (instance-vector  (cdr instances)) ;; drop first, as it's metadata
         (instance-list    (mapcar (lambda (x) (elt x 0)) instance-vector)))
    instance-list))

(defun aws-is-instance-active-p (instance)
  "Predicate that determines whether the given INSTANCE is running."
  (let* ((state (plist-get instance :State))
         (code (plist-get state :Code)))
    (eq code 16)))

(defun aws-format-instance-helm-row (instance)
  "Constructs a human-friendly string of a server instance.
show: <name>, <IP> and <launch date>.
Argument INSTANCE is the aws json in plist form"
  (let* ((ip (plist-get instance :PrivateIpAddress))
         (instance-id (plist-get instance :InstanceId))
         (instance-state (plist-get (plist-get instance :State) :Name))
         (tags (plist-get instance :Tags))
         (nameTag (cl-remove-if-not #'(lambda (tag) (string= (plist-get tag :Key) "Name")) tags))
         (name (if (= (length nameTag) 1) (plist-get (elt nameTag 0) :Value) instance-id))
         (launch-time (plist-get instance :LaunchTime))
         (launch-date (car (split-string launch-time "T")))
         (formatted-string
          (concat
           (propertize (format "%-30s" (s-truncate 30 name))
                       'face (cond ((string= instance-state "stopped")
                                    'helm-aws-instance-state-stopped)
                                   ((string= instance-state "terminated")
                                    'helm-aws-instance-state-terminated)
                                   (t 'helm-aws-instance-state-running)))
           " | " (format "%15s" (or ip ""))
           " | " launch-date)))
    (cons formatted-string instance)))

(defun aws-get-ip-from-instance (instance-json)
  "Extracts IP address from INSTANCE-JSON."
  (plist-get instance-json :PrivateIpAddress))

(defun aws-sort-helm-rows (a b)
  "Compare results from `aws-format-instance-helm-row' A and B."
  (string< (downcase (car a)) (downcase (car b))))

(defun aws-get-active-instances ()
  "Used to populate data for `helm-aws'."
  (let* ((aws-result       (aws-run-ec2-command))
         (instance-list    (aws-parse-server-list aws-result))
         (instance-list (mapcar 'aws-format-instance-helm-row instance-list))
         (instance-list (sort instance-list 'aws-sort-helm-rows))
         )
    instance-list))

(defun aws-ssh-into-instance (ip-address)
  "Use SSH to connect to remote instance.
Argument IP-ADDRESS is the ip address for the instance you want ssh to."
  (let ((switches (list ip-address "-l" aws-user-account)))
    (set-buffer (apply 'make-term "ssh" "ssh" nil switches))
    (term-mode)
    (term-char-mode)
    (switch-to-buffer "*ssh*")))

(defun aws-find-file-on-instance (ip-address)
  "Use dired to access directory structure of remote instance.
Argument IP-ADDRESS is the ip address for the instance you want to run `find-file' on."
  (let ((path (concat "/ssh:" aws-user-account "@" ip-address ":")))
    (find-file path)))

(defun aws-instance-details (instance-json)
  "Dump the instance json into a buffer *aws-details*.
Argument INSTANCE-JSON is the json behind the row of helm data."
  (interactive)
  (let* ((json-encoding-pretty-print t)
         (json (json-encode instance-json)))
    (switch-to-buffer (get-buffer-create "*aws-details*"))
    (let ((inhibit-read-only t))
      (erase-buffer)
      (delete-other-windows)
      (insert json)
      (goto-char (point-min))
      (set-buffer-modified-p nil)
      (view-mode)
      (message "Press q to quit."))))

(defun aws-compile (command &optional comint)
  "Invoke the compile function without saving buffers."
  (let ((compilation-save-buffers-predicate '(lambda () nil)))
    (compile command comint)))

(defun aws-instance-toggle-stop-start (instance-json)
  "Toggle the instance state for INSTANCE-JSON.
If it is stopped, start it.  If it is running, stop it."
  (let* ((instance-id (plist-get instance-json :InstanceId))
         (instance-state (plist-get (plist-get instance-json :State) :Name))
         (toggle-action (if (string= instance-state "running") "stop-instances" "start-instances"))
         (command (format "aws ec2 %s --instance-ids %s" toggle-action instance-id)))
    (aws-compile command)))

;;;###autoload
(defun helm-aws ()
  "Show helm with a table of aws information."
  (interactive)
  (let ((choices (aws-get-active-instances)))
    (helm
     :buffer "*helm-aws*"
     :sources `((name . "EC2 Instances")
                (candidates . ,choices)
                (action . (("SSH" .
                            (lambda (instance-json)
                              (aws-ssh-into-instance (aws-get-ip-from-instance instance-json))))
                           ("Dired" .
                            (lambda (instance-json)
                              (aws-find-file-on-instance (aws-get-ip-from-instance instance-json))))
                           ("Ping" .
                            (lambda (instance-json)
                              (ping (aws-get-ip-from-instance instance-json))))
                           ("Insert IP into buffer" .
                            (lambda (instance-json)
                              (insert (aws-get-ip-from-instance instance-json))))
                           ("Save instance json to buffer" . aws-instance-details)
                           ("Toggle Stop/Start instance" . aws-instance-toggle-stop-start)))))))

(provide 'helm-aws)

;;; helm-aws.el ends here
