;;; pycarddavel.el --- Integrate pycarddav -*- lexical-binding: t; -*-

;; Copyright (C) 2015 Damien Cassou

;; Author: Damien Cassou <damien@cassou.me>
;; Version: 0.1
;; Package-Version: 20150831.1216
;; Package-Commit: a6d81ee4eb8309cd82f6082aeca68c5a015702a3
;; GIT: https://github.com/DamienCassou/pycarddavel
;; Package-Requires: ((helm "1.7.0") (emacs "24.0"))
;; Created: 07 Jun 2015
;; Keywords: helm pyccarddav carddav message mu4e contacts

;; This file is not part of GNU Emacs.

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

;; Write carddav contact names and email addresses as a
;; comma-separated text (call `pycarddavel-search-with-helm` to start
;; the process).
;;
;;; Code:


(require 'eieio)
(require 'helm)

(defconst pycarddavel--buffer "*pycarddavel-contacts*")

(defun pycarddavel--fill-buffer (buffer)
  "Make sure BUFFER contain all pycarddav contacts.
If BUFFER already contains something, erase it before."
  (with-current-buffer buffer
    (erase-buffer)
    (call-process
     "pc_query"
     nil                           ; input file
     (list buffer nil)             ; output to buffer, discard error
     nil                           ; don't redisplay
     "-m")                         ; 1st arg to pc_query: prints email addresses
    ;; Remove first line as it is only informative
    (goto-char (point-min))
    (delete-region (point-min) (line-end-position))))

(defun pycarddavel--get-contacts-buffer ()
  "Return a buffer with one carddav contact per line."
  (let ((buffer (get-buffer-create pycarddavel--buffer)))
    (when (with-current-buffer (get-buffer-create pycarddavel--buffer)
            (equal (point-min) (point-max)))
      (pycarddavel--fill-buffer buffer))
    buffer))

(defun pycarddavel--reset-buffer ()
  "Make sure pycarddavel buffer is empty to force update on next use."
  (with-current-buffer (get-buffer-create pycarddavel--buffer)
    (erase-buffer)))

(defun pycarddavel--get-contact-from-line (line)
  "Return a carddav contact read from LINE.

The line must start with something like:
some@email.com	Some Name

The returned contact is of the form
 (:name \"Some Name\" :mail \"some@email.com\")"
  (when (string-match "\\(.*?\\)\t\\(.*?\\)\t" line)
    (list :name (match-string 2 line) :mail (match-string 1 line))))

(defun pycarddavel-sync-from-server ()
  "Use pycardsyncer to sync local database with server."
  (interactive)
  (call-process
   "pycardsyncer"
   nil
   (get-buffer-create "*pycardsyncer*")
   nil)
  (message "pycardsyncer done"))

(defun pycarddavel--helm-source-init ()
  "Initialize helm candidate buffer."
  (helm-candidate-buffer (pycarddavel--get-contacts-buffer)))

(defun pycarddavel--helm-source-select-action (candidate)
  "Print selected contacts as comma-separated text.
CANDIDATE is ignored."
  (ignore candidate)
  (insert (mapconcat (lambda (contact)
                       (let ((contact (pycarddavel--get-contact-from-line contact)))
                         (format "\"%s\" <%s>"
                                 (plist-get contact :name)
                                 (plist-get contact :mail))))
                     (helm-marked-candidates)
                     ", ")))

(defclass pycarddavel--helm-source (helm-source-in-buffer)
  ((init :initform #'pycarddavel--helm-source-init)
   (nohighlight :initform t)
   (action :initform (helm-make-actions
                      "Select" #'pycarddavel--helm-source-select-action))
   (requires-pattern :initform 0)))

;;;###autoload
(defun pycarddavel-search-with-helm (refresh)
  "Start helm to select your contacts from a list.
If REFRESH is not-nil, make sure to ask pycarrdav to refresh the contacts
list.  Otherwise, use the contacts previously fetched from pycarddav."
  (interactive "P")
  (when (and (consp refresh) (eq 16 (car refresh)))
    (pycarddavel-sync-from-server))
  (when refresh
    (pycarddavel--reset-buffer))
  (helm
   :prompt "contacts: "
   :sources (helm-make-source "Contacts" 'pycarddavel--helm-source)))

(provide 'pycarddavel)

;;; pycarddavel.el ends here

;;  LocalWords:  pycarddav carddav pycardsyncer
