;;; helm-pass.el --- helm interface of pass, the standard Unix password manager -*- lexical-binding: t; -*-

;; Copyright (C) 2016--2018 J. Alexander Branham
;; Copyright (C) 2019 Pierre Neidhardt

;; Author: J. Alexander Branham <branham@utexas.edu>
;; Maintainer: Pierre Neidhardt <mail@ambrevar.xyz>
;; URL: https://github.com/emacs-helm/helm-pass
;; Package-Version: 20210221.1655
;; Package-Commit: 4ce46f1801f2e76e53482c65aa0619d427a3fbf9
;; Version: 0.4
;; Package-Requires: ((emacs "25") (helm "0") (password-store "0") (auth-source-pass "4.0.0"))

;; This file is not part of GNU Emacs.

;;; License:
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>

;;; Commentary:
;;
;; Emacs Helm interface for pass, the standard Unix password manager
;;
;; Users of helm-pass may also be interested in functionality provided by other
;; Emacs packages dealing with pass:
;;
;; - password-store.el (which helm-pass relies on):
;;   https://git.zx2c4.com/password-store/tree/contrib/emacs/password-store.el
;;
;; - pass.el (a major mode for pass): https://github.com/NicolasPetton/pass
;;
;; - auth-source-pass.el (integration of Emacs' auth-source with pass, included
;;   in Emacs 26+): https://github.com/DamienCassou/auth-password-store

;; Usage:
;;
;; (require 'helm-pass)
;; M-x helm-pass

;;; Code:

(require 'helm)
(require 'password-store)
(require 'auth-source-pass)
(require 'thingatpt)
(require 'seq)

(defvar exwm-title)
(declare-function eww-current-url "eww")

(defgroup helm-pass nil
  "Emacs helm interface for helm-pass"
  :group 'helm)

(defun helm-pass-get-fields (entry)
  (mapcar 'car (auth-source-pass-parse-entry entry)))

(defun helm-pass-get-field (key entry)
  "Get the value associated with KEY for ENTRY.

Does not clear it from clipboard."
  (if (string-equal key "secret")
      (setq key 'secret))
  (let ((field (auth-source-pass-get key entry)))
    (if field
        (progn (password-store-clear)
               (kill-new field))
      (message (format "%s has no field: %s" entry field)))))

(defcustom helm-pass-actions
  '(("Copy password to clipboard" . password-store-copy)
    ("Copy field to clipboard" . helm-pass-fields)
    ("Edit entry" . password-store-edit)
    ("Browse url of entry" . password-store-url))
  "List of actions for `helm-pass'."
  :group 'helm-pass
  :type '(alist :key-type string :value-type function))

(defvar helm-pass-source-pass
  (helm-build-sync-source "Password File"
    :candidates #'password-store-list
    :action helm-pass-actions))

(defun helm-pass-source-pass-fields (entry)
  (helm-build-sync-source "Password Fields"
    :candidates (helm-pass-get-fields entry)
    :action (lambda (x) (helm-pass-get-field x entry))))

(defun helm-pass-find-url-in-string (string)
  "Return URL from STRING."
  (with-temp-buffer
    (insert string)
    (goto-char (point-min))
    (while (and (not (eobp))
                (not (thing-at-point-url-at-point)))
      (forward-word))
    (thing-at-point-url-at-point)))

(defvar helm-pass-domain-regexp
  (rx "//"
      (group
       (* (not (any "/")))
       "."
       (* (not (any "." "/"))))
      "/"))

(defun helm-pass-get-domain (url)
  "Return the various domain elements or URL as a list of strings."
  (when url
    (string-match helm-pass-domain-regexp url)
    (split-string (match-string 1 url) "\\.")))

(defun helm-pass-get-subdomain (domain &optional count)
  "Return the last COUNT elements of DOMAIN as a dot-separated string.
COUNT defaults to 2.
For instance, (\"foo\" \"example\" \"org\") results in \"example.org\".
If domain does not have enough elements, return nil."
  (setq count (or count 2))
  (when (>= (length domain) count)
    (mapconcat #'identity (seq-drop domain (- (length domain) count)) ".")))

(defun helm-pass-get-input-from-eww ()
  "Get default prompt from EWW."
  (let* ((domain (helm-pass-get-domain (eww-current-url))))
    (helm-pass-get-subdomain domain)))

(defun helm-pass-get-input-from-exwm ()
  "Get default prompt from the current EXWM window."
  (when exwm-title
    (let* ((url (helm-pass-find-url-in-string exwm-title))
           (domain (helm-pass-get-domain url)))
      (helm-pass-get-subdomain domain))))

(defun helm-pass-get-input ()
  "Get default prompt from the current mode."
  (cond
   ((derived-mode-p 'eww-mode)
    (helm-pass-get-input-from-eww))
   ((derived-mode-p 'exwm-mode)
    (helm-pass-get-input-from-exwm))))

;;;###autoload
(defun helm-pass ()
  "Helm interface for pass."
  (interactive)
  (helm :sources 'helm-pass-source-pass
        :input (helm-pass-get-input)
        :buffer "*helm-pass*"))

(defun helm-pass-fields (arg)
  (helm :sources (helm-pass-source-pass-fields arg)
        :buffer "*helm-pass-fields*"))

(provide 'helm-pass)
;;; helm-pass.el ends here
