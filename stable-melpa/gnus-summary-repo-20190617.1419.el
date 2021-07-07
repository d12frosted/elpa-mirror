;;; gnus-summary-repo.el --- Import and export files between IMAP and local by using GNUS -*- lexical-binding: t -*-

;; Copyright (C) 2019 Giap Tran <txgvnn@gmail.com>

;; Author: Giap Tran <txgvnn@gmail.com>
;; URL: https://github.com/TxGVNN/gnus-summary-repo
;; Package-Version: 20190617.1419
;; Package-Commit: d0cb218fea13563c1b2bfba3e72716fb860f767c
;; Version: 0.1
;; Package-Requires: ((emacs "25"))
;; Keywords: Gnus, Repository

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; You have to be at Summary mode (defined in `gnus-sum.el') before
;; call the gnus-summary-repo-* function

;;; Best practice
;; 1. Create a new group IMAP for only store your notes.
;; Example: nnimap+Gmail:Notes
;; 2. Go to your group with all of the articles (unlimited articles, you will be Summary mode)
;; 3. Use gnus-summary-repo-* function

;;; Code:

(require 'gnus-sum)

(defgroup gnus-summary-repo nil
  "GNUS repo configuration."
  :group 'gnus-summary)

(defcustom gnus-summary-repo-dir-local nil
  "Default local directory."
  :group 'gnus-summary-repo
  :type 'string)

(defcustom gnus-summary-repo-header-from nil
  "Default From header in mail."
  :group 'gnus-summary-repo
  :type 'string)

(defcustom gnus-summary-repo-import-ignore '("^\.git.*")
  "The regex list will be ignored when importing."
  :group 'gnus-summary-repo
  :type 'list)

(defvar gnus-summary-repo-file-hash-cache nil)
(setq gnus-summary-repo-file-hash-cache (make-hash-table :test 'equal))

(defun gnus-summary--check-mode ()
  "Check right mode before do anything."
  (unless (derived-mode-p 'gnus-summary-mode)
    (error "You have to go to Summary Gnus (Example: 'Inbox' on your mail))")))

(defun gnus-summary-repo-import-directory (&optional directory)
  "Import files in a folder to Group Imap.
if DIRECTORY non-nil, export to DIRECTORY
It only affects on current summary buffer."
  (interactive "p")
  (gnus-summary--check-mode)
  (setq directory
        (or (if (and (numberp directory) (eq directory 4))
                (file-name-as-directory
                 (expand-file-name
                  (read-directory-name "Select a directory to import: "))))
            (if (stringp directory) directory)
            gnus-summary-repo-dir-local
            (file-name-as-directory
             (expand-file-name
              (read-directory-name "Select a directory to import: ")))))

  (unless (file-directory-p directory)
    (error "%s is not a directory" directory))

  (let* ((directory-length (length (file-name-as-directory (expand-file-name directory))))
         subject)
    (dolist (file (directory-files-recursively directory ""))
      (setq subject (concat (substring (file-name-directory (expand-file-name file)) directory-length nil)
                            (file-name-nondirectory file)))
      (unless (or (file-directory-p file) (gnus-summary-repo--string-match-in-list-p subject gnus-summary-repo-import-ignore))
        (gnus-summary-repo-import-file file subject)))))

(defun gnus-summary-repo-export-directory (&optional directory)
  "Export files Group Imap to a folder.
if DIRECTORY non-nil, export to DIRECTORY
It only affects on current summary buffer"
  (interactive "p")
  (gnus-summary--check-mode)
  (setq directory
        (or (if (and (numberp directory) (eq directory 4))
                (file-name-as-directory
                 (expand-file-name
                  (read-directory-name "Select a directory to export: "))))
            (if (stringp directory) directory)
            gnus-summary-repo-dir-local
            (file-name-as-directory
             (expand-file-name
              (read-directory-name "Select a directory to export: ")))))

  (if (file-regular-p directory)
      (error "%s is not directory" directory))

  (dolist (article gnus-newsgroup-limit)
    (gnus-summary-repo--export-file article directory)))

(defun gnus-summary-repo-export-file (n &optional directory)
  "Export the attachment in article to DIRECTORY.
If N is a positive number, save the N next articles.
If N is a negative number, save the N previous articles.
If N is nil, export at."
  (interactive "p")
  (gnus-summary--check-mode)
  (setq directory
        (or directory
            gnus-summary-repo-dir-local
            (file-name-as-directory
             (expand-file-name
              (read-directory-name "Select a directory to export: ")))))
  (if (file-regular-p directory)
      (error "%s is not directory" directory))
  (let* ((articles (gnus-summary-work-articles n)))
    (dolist (article articles)
      (gnus-summary-repo--export-file article directory))))

(defun gnus-summary-repo--export-file (article directory)
  "Export an attachment in an ARTICLE to a DIRECTORY."
  (gnus-summary--check-mode)
  (let ((subject (gnus-summary-article-subject article))
        dir-path fullpath)
    (setq dir-path (file-name-directory (format "%s%s" (file-name-as-directory directory) subject )))
    (setq fullpath (format "%s%s" dir-path (file-name-nondirectory subject)))
    (mkdir dir-path t)

    (gnus-summary-repo--keep-connection gnus-newsgroup-name)

    (when (gnus-summary-repo--article-newer-than-file article fullpath)
      (message "Export %s" subject)
      (save-excursion
        (gnus-summary-display-article article nil)
        (gnus-summary-select-article-buffer)
        (goto-char (point-min))
        (when (search-forward "\nattachment:" nil t)
          (widget-forward 1)
          (let ((data (get-text-property (point) 'gnus-data)))
            (when data
              (if (file-exists-p fullpath)
                  (delete-file fullpath))
              (mm-save-part-to-file data fullpath))))))))

(defun gnus-summary-repo-import-file (&optional file subject)
  "Import an arbitrary FILE with SUBJECT into a mail newsgroup."
  (interactive
   (list (read-file-name "Select a file to import: ")))
  (if (not (file-name-absolute-p file))
      (error "%s is not an absolute path" file))
  (unless subject
    (setq subject (read-string "The subject: " (file-name-nondirectory file))))
  (let ((group gnus-newsgroup-name)
        (not-newer t) (saved-article nil)
        atts header-from group-art)

    (gnus-summary-repo--keep-connection group)

    (unless (gnus-check-backend-function 'request-accept-article group)
      (error "%s does not support article importing" group))
    (or (file-readable-p file)
        (not (file-regular-p file))
        (error "Can't read %s" file))

    ;; Delete the outdated files
    (let ((articles (gnus-summary-find-matching "subject" (format "^%s$" (regexp-quote subject)) 'all nil nil nil))
          (nnmail-expiry-target 'delete) not-deleted)
      (save-excursion
        (while articles
          (if (or (> (length articles) 1) (gnus-summary-repo--article-newer-than-file (car articles) file t))
              (progn()
                    (setq not-deleted (gnus-request-expire-articles
                                       (make-list 1 (car articles)) gnus-newsgroup-name 'force))
                    (gnus-summary-remove-process-mark (car articles))
                    ;; The backend might not have been able to delete the article
                    ;; after all.
                    (unless (memq (car articles) not-deleted)
                      (gnus-summary-mark-article (car articles) gnus-canceled-mark)
                      (let* ((article (car articles))
                             (ghead (gnus-data-header
                                     (assoc article (gnus-data-list nil)))))
                        (run-hook-with-args 'gnus-summary-article-delete-hook
                                            'delete ghead gnus-newsgroup-name nil nil))))
            (setq not-newer nil))
          (setq articles (cdr articles)))))

    ;; Add new one
    (while (and not-newer (not saved-article))
      (message "Import %s" file)
      (with-current-buffer (gnus-get-buffer-create " *import file*")
        (erase-buffer)
        (insert subject)
        (mml-insert-empty-tag 'part
                              'type "application/octet-stream"
                              'filename (substring-no-properties file)
                              'disposition "attachment"
                              'description subject)
        (goto-char (point-min))
        ;; This doesn't look like an article, so we fudge some headers.
        (setq atts (file-attributes file))
        (setq header-from gnus-summary-repo-header-from)
        (if (not header-from)
            (setq header-from (format-time-string "<%y-%m-%d@%H:%M>" (time-to-seconds))))
        (goto-char (point-min))
        (insert "From: " header-from "\n"
                "Subject: " subject "\n"
                "Date: " (message-make-date (nth 5 atts)) "\n"
                "Hash: " (gnus-summary-repo--md5-file file) "\n\n")
        (setq saved-article
              (ignore-errors (setq group-art (gnus-request-accept-article group nil t))))
        (kill-buffer (current-buffer)))
      (setq gnus-newsgroup-active (gnus-activate-group group))
      (forward-line 1)
      (if (cdr group-art)
          (gnus-summary-goto-article (cdr group-art) nil t)))))

(defun gnus-summary-repo-sync-deleted-files-base-directory (&optional directory)
  "Delete the file on Group, when this file was deleted on local DIRECTORY."
  (interactive)
  (gnus-summary--check-mode)
  (setq directory
        (or directory
            gnus-summary-repo-dir-local
            (file-name-as-directory
             (expand-file-name
              (read-directory-name "Select a directory to export: ")))))
  (if (file-regular-p directory)
      (error "%s is not directory" directory))
  (dolist (article gnus-newsgroup-limit)
    (message "Mark %s will be deleted" (gnus-summary-article-subject article))
    (unless (file-regular-p (expand-file-name (format "%s%s" (file-name-as-directory directory) (gnus-summary-article-subject article))))
      (gnus-summary-mark-article article gnus-canceled-mark))))


(defun gnus-summary-repo--article-newer-than-file (article file &optional reverse)
  "Compare date of ARTICLE newer than FILE.
If REVERSE is non-nil, reverse the result."
  (if (file-exists-p file)
      (let (article-modification-time file-modification-time mail-hash file-hash)
        (save-excursion
          (gnus-summary-display-article article nil)
          (gnus-summary-select-article-buffer)
          (gnus-summary-show-all-headers)
          (setq article-modification-time 0)
          (setq file-modification-time (truncate (time-to-seconds (file-attribute-modification-time (file-attributes file)))))
          ;; Get date in header
          (goto-char (point-min))
          (if (search-forward "\ndate:" nil t)
              (setq article-modification-time (truncate (time-to-seconds (mail-header-parse-date (nnheader-header-value))))))
          (setq mail-hash "")
          (setq file-hash (gnus-summary-repo--md5-file file t))
          ;; Get MD5 hash in header
          (goto-char (point-min))
          (if (search-forward "\nhash:" nil t)
              (setq mail-hash (substring-no-properties (nnheader-header-value))))
          ;; Comparing
          (if (string= mail-hash file-hash) nil
            (if reverse
                (< article-modification-time file-modification-time)
              (> article-modification-time file-modification-time)))))
    (if reverse nil t)))

(defun gnus-summary-repo-import-directory-all (&optional directory)
  "Rescan summary group before call `gnus-summary-repo-import-directory' DIRECTORY."
  (interactive
   (list (or gnus-summary-repo-dir-local
             (read-directory-name "Select a directory to import: "))))
  (gnus-summary-rescan-group 9999)
  (gnus-summary-repo-import-directory directory))

(defun gnus-summary-repo-export-directory-all (&optional directory)
  "Rescan summary group before call `gnus-summary-repo-export-directory' DIRECTORY."
  (interactive
   (list (or gnus-summary-repo-dir-local
             (read-directory-name "Select a directory to export: "))))
  (gnus-summary-rescan-group 9999)
  (gnus-summary-repo-export-directory directory))

(defun gnus-summary-repo--string-match-in-list-p (str list-of-string)
  "Match STR in LIST-OF-STRING."
  (catch 'tag
    (mapc
     (lambda (x)
       (when (string-match x str) (throw 'tag t)))
     list-of-string) nil))

(defun gnus-summary-repo--md5-file (file &optional force)
  "Get md5 hash of FILE.
Recalculate if FORCE is not nil."
  (if (or force (not (gethash file gnus-summary-repo-file-hash-cache)))
      (puthash file (with-temp-buffer (insert-file-contents-literally file)
                                      (md5 (buffer-string))) gnus-summary-repo-file-hash-cache)
    (gethash file gnus-summary-repo-file-hash-cache)))

(defun gnus-summary-repo--keep-connection (group)
  "Check and reconnect GROUP if disconnected."
  (unless (gnus-server-opened (gnus-find-method-for-group group))
    (gnus-remove-denial (gnus-find-method-for-group group))
    (gnus-open-server (gnus-find-method-for-group group))))

(provide 'gnus-summary-repo)

;;; gnus-summary-repo.el ends here
