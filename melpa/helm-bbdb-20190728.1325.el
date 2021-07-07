;;; helm-bbdb.el --- Helm interface for bbdb -*- lexical-binding: t -*-

;; Copyright (C) 2012 ~ 2019 Thierry Volpiatto <thierry.volpiatto@gmail.com>

;; Version: 1.0
;; Package-Version: 20190728.1325
;; Package-Commit: db69114ff1af8bf48b5a222242e3a8dd6e101e67
;; Package-Requires: ((emacs "24.3") (helm "1.5") (bbdb "3.1.2"))
;; URL: https://github.com/emacs-helm/helm-bbdb

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

;; This is a Helm interface for BBDB, the Insidious Big Brother
;; Database for GNU Emacs.

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'helm-utils)
(require 'helm-mode)

(defvar bbdb-records)
(defvar bbdb-buffer-name)
(defvar bbdb-phone-label-list)
(defvar bbdb-address-label-list)
(defvar bbdb-default-xfield)

(declare-function bbdb "ext:bbdb-com")
(declare-function bbdb-current-record "ext:bbdb-com")
(declare-function bbdb-redisplay-record "ext:bbdb-com")
(declare-function bbdb-record-mail "ext:bbdb-com" (record) t)
(declare-function bbdb-mail-address "ext:bbdb-com")
(declare-function bbdb-records "ext:bbdb-com")
(declare-function bbdb-create-internal "ext:bbdb-com")
(declare-function bbdb-read-organization "ext:bbdb-com")
(declare-function bbdb-read-xfield "ext:bbdb-com")
(declare-function bbdb-display-records "ext:bbdb")
(declare-function bbdb-current-field "ext:bbdb")
(declare-function bbdb-delete-field-or-record "ext:bbdb-com")
(declare-function bbdb-record-organization "ext:bbdb")
(declare-function bbdb-record-name "ext:bbdb")

(defvar helm-bbdb--cache nil)

(defgroup helm-bbdb nil
  "Commands and functions for bbdb."
  :group 'helm)

(defcustom helm-bbdb-actions
  (helm-make-actions
   "View contact's data" 'helm-bbdb-view-person-action
   "Delete contact" 'helm-bbdb-delete-contact
   "Send an email" 'helm-bbdb-compose-mail)
  "Default actions alist for `helm-source-bbdb'."
  :type '(alist :key-type string :value-type function))

(defun helm-bbdb-candidates ()
  "Return a list of all names in the bbdb database."
  (cl-loop for bbdb-record in (bbdb-records)
	   for name = (bbdb-record-name bbdb-record)
	   collect (cons name bbdb-record)))

(defun helm-bbdb-read-phone ()
  "Return a list of vector address objects.
See docstring of `bbdb-create-internal' for more info on address entries."
  (cl-loop with loc-list = (cons "[Exit when no more]" bbdb-phone-label-list)
           with loc ; Defer count
           do (setq loc (helm-comp-read (format "Phone location[%s]: " count)
                                        loc-list
                                        :must-match 'confirm
                                        :default ""))
           while (not (string= loc "[Exit when no more]"))
           for count from 1
           for phone-number = (helm-read-string (format "Phone number (%s): " loc))
           collect (vector loc phone-number) into phone-list
           do (setq loc-list (remove loc loc-list))
           finally return phone-list))

(defun helm-bbdb-read-address ()
  "Return a list of vector address objects.
See docstring of `bbdb-create-internal' for more info on address entries."
  (cl-loop with loc-list = (cons "[Exit when no more]" bbdb-address-label-list)
           with loc ; Defer count
           do (setq loc (helm-comp-read
                         (format "Address description[%s]: "
                                 (int-to-string count))
                         loc-list
                         :must-match 'confirm
                         :default ""))
           while (not (string= loc "[Exit when no more]"))
           for count from 1
           ;; Create vector
           for lines = (helm-read-repeat-string "Street, line" t)
           for city = (helm-read-string "City: ")
           for state = (helm-read-string "State: ")
           for zip = (helm-read-string "ZipCode: ")
           for country = (helm-read-string "Country: ")
           collect (vector loc lines city state zip country) into address-list
           do (setq loc-list (remove loc loc-list))
           finally return address-list))

(defun helm-bbdb-create-contact (actions candidate)
  "Action transformer for `helm-source-bbdb'.
Returns only an entry to add the current `helm-pattern' as new contact.
All other actions are removed."
  (require 'bbdb-com)
  (if (and (stringp candidate)
           (string= candidate "*Add new contact*"))
      (helm-make-actions
       "Add to contacts"
       (lambda (_actions)
         (bbdb-create-internal
          :name (read-from-minibuffer "Name: " helm-pattern)
          :organization (bbdb-read-organization)
          :mail (helm-read-repeat-string "Email " t)
          :phone (helm-bbdb-read-phone)
          :address (helm-bbdb-read-address)
          :xfields (let ((xfield (bbdb-read-xfield bbdb-default-xfield)))
		     (unless (string= xfield "")
		       (list (cons bbdb-default-xfield xfield)))))))
    actions))

(defun helm-bbdb-get-record (candidate)
  "Return record that match CANDIDATE."
  (cl-letf (((symbol-function 'message) #'ignore))
    (bbdb candidate nil)
    (set-buffer bbdb-buffer-name)
    (bbdb-current-record)))

(defun helm-bbdb-match-mail (candidate)
  "Additional match function for matching the CANDIDATE's email address."
  (string-match helm-pattern
                (mapconcat
                 'identity
                 (bbdb-record-mail
                  (assoc-default candidate helm-bbdb--cache))
                 ",")))

(defun helm-bbdb-match-org (candidate)
  "Additional match function for matching the CANDIDATE's organization."
  (string-match helm-pattern
                (mapconcat
                 'identity
                 (bbdb-record-organization
                  (assoc-default candidate helm-bbdb--cache))
                 ",")))

(defvar helm-source-bbdb
  (helm-build-sync-source "BBDB"
    :init (lambda ()
            (require 'bbdb)
            (setq helm-bbdb--cache (helm-bbdb-candidates)))
    :candidates 'helm-bbdb--cache
    :match '(helm-bbdb-match-mail helm-bbdb-match-org)
    :action 'helm-bbdb-actions
    :persistent-action 'helm-bbdb-persistent-action
    :persistent-help "View data"
    :filtered-candidate-transformer (lambda (candidates _source)
                                      (if (not candidates)
                                          (list "*Add new contact*")
                                        candidates))
    :action-transformer (lambda (actions candidate)
                          (helm-bbdb-create-contact actions candidate)))
  "Source for BBDB.")

(defun helm-bbdb--view-person-action-1 (candidates)
  (bbdb-display-records
   (mapcar 'helm-bbdb-get-record candidates) nil t))

(defun helm-bbdb--marked-contacts ()
  (cl-loop for record in (helm-marked-candidates)
	   for name = (bbdb-record-name record)
           collect
	   name))

(defun helm-bbdb-view-person-action (_candidate)
  "View BBDB data of single CANDIDATE or marked candidates."
  (helm-bbdb--view-person-action-1 (helm-bbdb--marked-contacts)))

(defun helm-bbdb-persistent-action (candidate)
  "Persistent action to view CANDIDATE's data."
  (let ((bbdb-silent t))
    (helm-bbdb-view-person-action candidate)))

(defun helm-bbdb-collect-mail-addresses ()
  "Return a list of the mail addresses of candidates.
If record has more than one address, prompt for an address."
  (cl-loop for record in (helm-marked-candidates)
	   for mail = (bbdb-record-mail record)
	   when mail collect
	   (if (cdr mail)
	       (helm-comp-read "Choose mail: "
			       (mapcar (lambda (mail)
					 (bbdb-dwim-mail record mail))
				       mail)
			       :allow-nest t
			       :initial-input helm-pattern)
	     (bbdb-dwim-mail record (car mail)))))

(defun helm-bbdb-collect-all-mail-addresses ()
  "Return a list of strings to use as the mail address of record.
This may include multiple addresses of the same record. The name in
the mail address is formatted obeying `bbdb-mail-name-format' and
`bbdb-mail-name'."
  (let (mails)
    (dolist (record (bbdb-records))
      (let ((mail (bbdb-record-mail record)))
	(when mail
	  (if (> (length mail) 1)
	      ;; The idea here is to keep adding to the list however
	      ;; many addresses are found in the record.
	      (let ((addresses mail))
		(mapc (lambda (mail)
                        (push (bbdb-dwim-mail record mail) mails))
                      addresses))
	    (let ((mail (bbdb-dwim-mail record (car mail))))
	      (push mail mails))))))
    (mapc #'identity mails)))

(defun helm-bbdb-compose-mail (_candidate)
  "Compose a new mail to one or multiple CANDIDATEs."
  (let* ((address-list (helm-bbdb-collect-mail-addresses))
         (address-str  (mapconcat 'identity address-list ",\n    ")))
    (compose-mail address-str nil nil nil 'switch-to-buffer)))

(defun helm-bbdb-delete-contact (_candidate)
  "Delete CANDIDATE from the bbdb buffer and database.
Prompt user to confirm deletion."
  (let ((cands (helm-bbdb--marked-contacts)))
    (with-helm-display-marked-candidates
      "*bbdb candidates*" cands
      (when (y-or-n-p "Delete contacts")
        (helm-bbdb-view-person-action 'ignore)
        (delete-window)
        (with-current-buffer bbdb-buffer-name
          (helm-awhile (let ((field  (ignore-errors (bbdb-current-field)))
                             (record (ignore-errors (bbdb-current-record))))
                         (and field record (list record field t)))
            (apply 'bbdb-delete-field-or-record it))
          (message "%s contacts deleted: \n- %s"
                   (length cands)
                   (mapconcat 'identity cands "\n- ")))))))

(defun helm-bbdb-insert-mail (_candidate &optional comma)
  "Insert CANDIDATE's email address.
If optional argument COMMA is non-nil, insert comma separator as well,
which is needed when executing persistent action."
  (let* ((address-list (cl-loop for candidate in (helm-marked-candidates)
				collect candidate))
	 (address-str  (mapconcat 'identity address-list ",\n    ")))
    (end-of-line)
    (while (not (looking-back ": \\|, \\| [ \t]" (point-at-bol)))
      (delete-char -1))
    (insert (concat address-str (when comma ", ")))
    (end-of-line)))

(defun helm-bbdb-expand-name ()
  "Expand name under point when there is one.
Otherwise, open a helm buffer displaying a list of addresses. If
`bbdb-complete-mail-allow-cycling' is non-nil and point is at the end
of the address line, cycle mail addresses of record.

To use this feature, make sure `helm-bbdb-expand-name' is added to the
`message-completion-alist' variable."
  (if (and (looking-back "\\(<.+\\)\\(@\\)\\(.+>$\\)" nil)
	   bbdb-complete-mail-allow-cycling)
      (bbdb-complete-mail)
    (let (mails
	  (abbrev (thing-at-point 'symbol t)))
      (with-temp-buffer (mapc (lambda (mail)
                                (insert (concat mail "\n")))
                              (helm-bbdb-collect-all-mail-addresses))
			(goto-char (point-min))
			(while (re-search-forward (concat "\\(^.+\\)" "\\(" abbrev "\\)" "\\(.+$\\)") nil t)
			  (push (concat (match-string 1) (match-string 2) (match-string 3)) mails)
			  (setq mails mails)))
      ;; If there's one address, insert it automatically
      (if (= (length mails) 1)
	  (progn (end-of-line)
		 (while (not (looking-back ": \\|, \\| [ \t]" (point-at-bol)))
		   (delete-char -1))
		 (insert (car mails))
		 (end-of-line))
	;; If there's more than one, start helm
	(helm :sources (helm-build-sync-source "BBDB"
			 :candidates 'helm-bbdb-collect-all-mail-addresses
			 :persistent-action (lambda (candidate)
					      (helm-bbdb-insert-mail candidate t))
			 :action 'helm-bbdb-insert-mail)
	      :input (thing-at-point 'symbol t))))))

;;;###autoload
(defun helm-bbdb ()
  "Preconfigured `helm' for BBDB.

Needs BBDB.

URL `http://bbdb.sourceforge.net/'"
  (interactive)
  (helm-other-buffer 'helm-source-bbdb "*helm bbdb*"))

(provide 'helm-bbdb)

;; Local Variables:
;; byte-compile-warnings: (not obsolete)
;; coding: utf-8
;; indent-tabs-mode: nil
;; End:

;;; helm-bbdb.el ends here
