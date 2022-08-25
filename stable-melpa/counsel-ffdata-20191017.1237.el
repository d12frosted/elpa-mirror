;;; counsel-ffdata.el --- Use ivy to access firefox data  -*- lexical-binding: t -*-

;; Copyright (C) 2019 Zhu Zihao

;; Author: Zhu Zihao <all_but_last@163.com>
;; URL: https://github.com/cireu/counsel-ffdata
;; Package-Version: 20191017.1237
;; Package-Commit: 913cb1b8cd5e4ca2ba6613eab56d52040e08a0a5
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1") (counsel "0.11.0") (emacsql "3.0.0"))
;; Keywords: convenience, tools, matching

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

;; Call one of interactive function in this file to complete
;; the corresponding thing using `ivy'.
;;
;; Current available:
;; - Firefox Bookmarks.
;; - Firefox History visits.

;;; Code:

(require 'cl-lib)
(require 'ivy)
(require 'counsel)
(require 'emacsql-compiler)
(require 'org-faces)                    ;For face `org-date'

(eval-when-compile
  (require 'pcase))                     ;`pcase-let*' and `pcase-lambda'

;;; Customize

(defgroup counsel-ffdata ()
  "Access Firefox bookmarks/history with ivy interface."
  :prefix "counsel-ffdata-"
  :group 'counsel)

(defcustom counsel-ffdata-database-path
  (cl-case system-type
    ((gnu gnu/linux gnu/kfreebsd)
     (expand-file-name
      (car (file-expand-wildcards
            "~/.mozilla/firefox/*.default/places.sqlite"))))
    (windows-nt
     (car (file-expand-wildcards
           (expand-file-name "Mozilla/Firefox/Profiles/*/places.sqlite"
                             (getenv "APPDATA"))))))

  "The path to Firefox's user database.

We try to detect it on *nix system. If you're using Windows/Mac or
auto-detection don't work for you, you need to specify it manually."
  :type '(choice (const :tag "Unset" nil)
          string))

;;; Database Access

(defvar counsel-ffdata--temp-db-path
  (expand-file-name (make-temp-name "ffdb") temporary-file-directory))

(defvar counsel-ffdata--cache (make-hash-table :test #'equal))

(defun counsel-ffdata--ensure-db! (&optional force-update?)
  "Ensure database by copying it to system temp file directory with a temp name.

If FORCE-UPDATE? is non-nil and database was copied, delete it first."
  (cl-flet ((update-db! ()
              ;; The copy is necessary because our SQL query action
              ;; may conflicts with running Firefox.
              (copy-file counsel-ffdata-database-path
                         counsel-ffdata--temp-db-path)
              (clrhash counsel-ffdata--cache)))
    (let* ((path counsel-ffdata--temp-db-path))
      (if (file-exists-p path)
          (when force-update?
            (delete-file path)
            (update-db!))
        (update-db!))
      nil)))

(defun counsel-ffdata--parse-sql-result ()
  "Parse the output from `sqlite3' in ascii mode.

Return a list like ((COL1 COL2 ...) ...)"
  (goto-char (point-min))
  (let (result)
    (while (re-search-forward (rx (group (+? any)) (eval (kbd "C-^"))) nil t)
      (push (match-string 1) result))
    (nreverse (mapcar (lambda (it) (split-string it (kbd "C-_")))
                      result))))

(defsubst counsel-ffdata--prepare-sql-stmt (sql &rest args)
  "Format S-exp SQL DSL to a real SQL query statement with ARGS."
  (concat (apply #'emacsql-format (emacsql-prepare sql) args) ";"))

;;; Candidates

(cl-defun counsel-ffdata--prepare-candidates! (&key
                                                 (caller this-command)
                                                 query-stmt
                                                 force-update?
                                                 transformer)
  "Prepare candidates from `counsel-ffdata-*' completions.

Return a list like ((COL1 COL2 ...) ...), by parsing the result queried by
QUERY-STMT.

If TRANSFORMER is supplied, it will be mapped over the parsed result.

CALLER is a symbol to uniquely identify the caller, to determined the key in
hash cache.

When FORCE-UPDATE? is non-nil, force update database and cache before preparing
candidates.
"
  (counsel-require-program "sqlite3")
  (counsel-ffdata--ensure-db! force-update?)
  (or
   (if force-update? nil (gethash caller counsel-ffdata--cache nil))
   (let ((buf (generate-new-buffer "*counsel-ffdata sqlite*")))
     (with-current-buffer buf
       (let ((coding-system-for-read 'utf-8-auto)
             (coding-system-for-write 'utf-8-auto))
         (let* ((db-path counsel-ffdata--temp-db-path)
                (query-cmd (counsel-ffdata--prepare-sql-stmt query-stmt))
                (errno (call-process "sqlite3" nil (current-buffer) nil
                                     "--ascii" db-path query-cmd))
                result)
           (if (= errno 0)
               (unwind-protect
                    (setq result (counsel-ffdata--parse-sql-result))
                 (kill-buffer buf))
             (pop-to-buffer buf)
             (error "SQLite exited with error code %d" errno))
           (when (functionp transformer)
             (cl-callf2 mapcar transformer result))
           (setf (gethash caller counsel-ffdata--cache) result)))))))

(defun counsel-ffdata--history-cands-transformer (cands)
  "Transform raw CANDS to ivy compatible candidates."
  (pcase-let* (((and whole (let `(,title ,url ,date-in-ms) whole))
                cands)
               (date (/ (string-to-number date-in-ms) 1000000))
               (readable-date (format-time-string "%Y-%m-%d %H:%M %a" date)))
    ;; HACK: Use text property to carry original source
    ;; Useful for display transformer.
    (cons (propertize (format "%s %s %s"
                              title
                              (propertize url 'face 'link)
                              (propertize readable-date 'face 'org-date))
                      'counsel-ffdata-orig-source (list title url readable-date))
          whole)))

;;; Display transformer

(defun counsel-ffdata--history-display-transformer (text)
  "Transform TEXT to real displayed text."
  (pcase-let ((`(,title ,url ,readable-date)
               (get-text-property 0 'counsel-ffdata-orig-source text)))
    (format "%s %s %s"
            title
            (propertize (truncate-string-to-width url 25 nil nil "...")
                        'face 'link)
            (propertize readable-date 'face 'org-date))))

(defun counsel-ffdata--bookmarks-display-transformer (text)
  "Transform TEXT to real displayed text."
  (pcase-let ((`(,title ,url)
               (get-text-property 0 'counsel-ffdata-orig-source text)))
    (format "%s %s"
            title
            (propertize (truncate-string-to-width url 25 nil nil "...")
                        'face 'link))))

;;; Interactive functions

;;;###autoload
(defun counsel-ffdata-firefox-bookmarks (&optional force-update?)
  "Search your Firefox bookmarks.

If FORCE-UPDATE? is non-nil, force update database and cache before searching."
  (interactive "P")
  (ivy-read "Firefox Bookmarks: "
            (counsel-ffdata--prepare-candidates!
             :query-stmt [:select [bm:title p:url]
                          :from (as moz_bookmarks bm)
                          :inner-join (as moz_places p)
                          :where (= bm:fk p:id)]
             :force-update? force-update?
             :caller 'counsel-ffdata-firefox-bookmarks
             :transformer (pcase-lambda ((and whole (let `(,title ,url) whole)))
                            ;; HACK: Use text property to carry original source
                            ;; Useful for display transformer.
                            (cons (propertize (format "%s %s" title url)
                                              'counsel-ffdata-orig-source whole)
                                  whole)))
            :history 'counsel-ffdata-firefox-bookmarks
            :action (lambda (it) (browse-url (cl-third it)))
            :caller 'counsel-ffdata-firefox-bookmarks
            :require-match t))

;;;###autoload
(defun counsel-ffdata-firefox-history (&optional force-update?)
  "Search your Firefox history.

If FORCE-UPDATE? is non-nil, force update database and cache before searching."
  (interactive "P")
  (ivy-read "Firefox History: "
            (counsel-ffdata--prepare-candidates!
             :query-stmt [:select [p:title p:url h:visit_date]
                          :from (as moz_historyvisits h)
                          :inner-join (as moz_places p)
                          :where (= h:place_id p:id)
                          :order-by (desc h:visit_date)]
             :force-update? force-update?
             :caller 'counsel-ffdata-firefox-history
             :transformer #'counsel-ffdata--history-cands-transformer)
            :history 'counsel-ffdata-firefox-history
            :action (lambda (cand) (browse-url (cl-third cand)))
            :caller 'counsel-ffdata-firefox-history
            :require-match t))

(provide 'counsel-ffdata)

(ivy-set-display-transformer #'counsel-ffdata-firefox-history
                             #'counsel-ffdata--history-display-transformer)

(ivy-set-display-transformer #'counsel-ffdata-firefox-bookmarks
                             #'counsel-ffdata--bookmarks-display-transformer)

(dolist (it '(counsel-ffdata-firefox-history
              counsel-ffdata-firefox-bookmarks))
  (ivy-set-actions it
                   '(("E" (lambda (it) (eww (cl-third it))) "Open with EWW"))))

;;; counsel-ffdata.el ends here
