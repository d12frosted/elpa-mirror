;;; helm-aws.el --- Manage AWS EC2 server instances directly from Emacs

;; Copyright (C) 2014 istib

;; Author: istib
;; URL: https://github.com/istib/helm-aws
;; Package-Version: 20141206.2008
;; Package-Commit: 172a4a3427d31c999e27e9ee06aa8e3822364a8c
;; Version: 20141205.1
;; X-Original-Version: 0.2
;; Package-Requires: ((helm "1.5.3"))
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
;; AWS account. Helm actions to launch a terminal, dired, or ping are accessible.
;; 
;; Requires a configured installation of AWS command-line interface (http://aws.amazon.com/cli/)


;;; Code:
(require 'json)

(defvar aws-user-account
  "ubuntu"
  "User account name for AWS servers. Assuming that your PEM keys are placed on each instance")

(defvar aws-ec2-command
  "aws ec2 describe-instances"
  "Command to list instances. Run `aws configure` to set up AWS cli")

(defun aws-run-ec2-command ()
  "returns json"
  (let ((aws-result-buffer (generate-new-buffer-name "*aws-ec2*")))
    (with-temp-buffer
      (shell-command aws-ec2-command (current-buffer) nil)
      (buffer-substring-no-properties (point-min) (point-max)))))

(defun aws-parse-server-list (input)
  ""
  (let* ((json-object-type 'plist)
         (aws-json         (json-read-from-string input))
         (reservations     (plist-get aws-json :Reservations))
         (instances        (mapcar (lambda (el) (plist-get el :Instances)) reservations))
         (instance-vector  (cdr instances)) ;; drop first, as it's metadata
         (instance-list    (mapcar (lambda (x) (elt x 0)) instance-vector)))
    instance-list))

(defun aws-is-instance-active-p (instance)
  "predicate that determines whether the given instance is running"
  (let* ((state (plist-get instance :State))
         (code (plist-get state :Code)))
    (eq code 16)))

(defun aws-format-instance-string (instance)
  "Constructs a human-friendly string of a server instance - showing name, IP and launch date"
  (let* ((ip (plist-get instance :PrivateIpAddress))
         (tags (elt (plist-get instance :Tags) 0))
         (name (plist-get tags :Value))
         (launch-time (plist-get instance :LaunchTime))
         (launch-date (car (split-string launch-time "T"))))
    (concat name " - " ip " - " launch-date)))

(defun aws-get-ip-from-instance-string (instance-str)
  "extracts IP address back from constructed string"
  (let* ((components (split-string instance-str " - ")))
    (cadr components)))

(defun aws-get-active-instances ()
  "used to populate list in helm-aws"
  (let* ((aws-result       (aws-run-ec2-command))
         (instance-list    (aws-parse-server-list aws-result))
         (active-instances (-filter 'aws-is-instance-active-p instance-list)))
    (mapcar 'aws-format-instance-string active-instances)))

(defun aws-ssh-into-instance (ip-address)
  "Use SSH to connect to remote instance"
  (let ((switches (list ip-address "-l" aws-user-account)))
    (set-buffer (apply 'make-term "ssh" "ssh" nil switches))
    (term-mode)
    (term-char-mode)
    (switch-to-buffer "*ssh*")))

(defun aws-find-file-on-instance (ip-address)
  "Use dired to access directory structure of remote instance"
  (let ((path (concat "/ssh:" aws-user-account "@" ip-address ":")))
    (find-file path)))


;;;###autoload
(defun helm-aws ()
  (interactive)
  (let ((choices (aws-get-active-instances)))
    (helm
     :sources '((name . "EC2 Instances")
                (candidates . choices)
                (action . (("SSH"                   . (lambda (instance-str)
                                                        (aws-ssh-into-instance (aws-get-ip-from-instance-string instance-str))))
                           ("Dired"                 . (lambda (instance-str)
                                                        (aws-find-file-on-instance (aws-get-ip-from-instance-string instance-str))))
                           ("Ping"                  . (lambda (instance-str)
                                                        (ping (aws-get-ip-from-instance-string instance-str))))
                           ("Insert IP into buffer" . (lambda (instance-str)
                                                        (insert (aws-get-ip-from-instance-string instance-str))))))))))

(provide 'helm-aws)

;;; helm-aws.el ends here
