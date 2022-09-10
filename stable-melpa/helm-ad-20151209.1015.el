;;; helm-ad.el --- helm source for Active Directory

;; Copyright (C) 2014  Takahiro Noda

;; Author: Takahiro Noda <takahiro.noda+github@gmail.com>
;; Created: Jul 31, 2014
;; Version: 0.0.1
;; Package-Version: 20151209.1015
;; Package-Commit: 8ac044705d8620ee354a9cfa8cc1b865e83c0d55
;; Keywords: comm
;; Package-Requires: ((dash "2.8.0") (helm "1.6.2"))

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

;; helm-ad provides helm source and commands for Active Directory's
;; command line utilities, such as gsquery and gsget.

;;; Code:
(require 'cl-lib)
(require 'dash)
(require 'helm)

(eval-when-compile
  (require 'cl))

(defvar helm-ad-action-function 'insert)
(defvar helm-source-ad-action-alist nil)
(defvar helm-source-ad-params-contact nil)
(defvar helm-source-ad-params-user nil)

(unless helm-source-ad-params-contact
  (setq helm-source-ad-params-contact '("dn"
                                        "display"
                                        "desc"
                                        "office"
                                        "tel"
                                        "email"
                                        "hometel"
                                        "pager"
                                        "mobile"
                                        "fax"
                                        "iptel"
                                        "title"
                                        "dept"
                                        "company")))
(unless helm-source-ad-params-user
  (setq helm-source-ad-params-user helm-source-ad-params-contact))
(unless helm-source-ad-action-alist
  (setq helm-source-ad-action-alist
        `(("contact" . ,helm-source-ad-params-contact)
          ("user". ,helm-source-ad-params-user))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Helper functions for meta-programming
;;; 
(defun helm-ad-dsget-function (cmd prop)
  (lexical-let ((cmd cmd)
                (prop prop))
    (lambda (dn)
      (with-current-buffer (get-buffer-create "*dsget*")
        (erase-buffer)
        (call-process "dsget" nil t nil
                      cmd
                      (substring dn 1 (1- (length dn)))
                      "-l"
                      (concat "-" prop))
        (goto-char (point-min))
        (if (re-search-forward ".*: *\\(.*\\)" nil t)
            (kill-new (match-string-no-properties 1))
          (error "dsget did not return any objects")))
      (funcall helm-ad-action-function (car kill-ring)))))

(defun helm-source-ad-command-action (cmd)
  (-map (lambda (prop)
          `(,prop . ,(helm-ad-dsget-function cmd prop)))
        (assoc-default cmd helm-source-ad-action-alist)))

(defun helm-source-ad-command-candidates-function (cmd)
  (lexical-let ((cmd cmd))
    (lambda ()
      (with-temp-buffer
        (call-process "dsquery" nil t nil cmd "-name"
                      (concat helm-pattern "*"))
        (split-string (buffer-string) "\n")))))

(defun helm-source-ad-command (cmd)
  (lexical-let ((cmd cmd))
    `((name . ,(format "Active Directory %s" cmd))
      (candidates . ,(helm-source-ad-command-candidates-function cmd))
      (volatile)
      (requires-pattern . 2)
      (action . ,(helm-source-ad-command-action cmd)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; helm-ad-user
;;;
(defvar helm-source-ad-user (helm-source-ad-command "user"))

(defun helm-ad-user ()
  (interactive)
  (helm-other-buffer '(helm-source-ad-user) "*helm ad user*"))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; helm-ad-contact
;;; 
(defvar helm-source-ad-contact (helm-source-ad-command "contact"))

(defun helm-ad-contact ()
  (interactive)
  (helm-other-buffer '(helm-source-ad-contact) "*helm ad contact*"))


;;;###autoload
(defun helm-ad ()
  "Query the directory by using the `dsquery` command,
and display the selected property of a specific object.
The property can be selected as a helm action,
and will be displayed by using the `dsget` command."
  (interactive)
  (helm-other-buffer '(helm-source-ad-user helm-source-ad-contact)
                     "*helm ad*"))


(provide 'helm-ad)
;;; helm-ad.el ends here
