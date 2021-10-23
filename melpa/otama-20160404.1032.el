;;; otama.el --- Org-table Manipulator

;; Copyright (C) 2016 Yoshinari Nomura. All rights reserved.

;; Description: Lookup and insert org-table as database.
;; Author:  Yoshinari Nomura <nom@quickhack.net>
;; Created: 2016-02-03
;; Version: 1.0.0
;; Package-Version: 20160404.1032
;; Package-Commit: c114fd8006762f891bc120a7c0ea213872e7ab31
;; Keywords: database, org-mode
;; URL:
;; Package-Requires:

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. Neither the name of the team nor the names of its contributors
;;    may be used to endorse or promote products derived from this software
;;    without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE TEAM AND CONTRIBUTORS ``AS IS''
;; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
;; FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL
;; THE TEAM OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
;; INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
;; (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
;; HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
;; STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
;; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
;; OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; Otama is a simple org-table based database.
;; It is intended to be a light version of BBDB and helm-friendly.

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Org-element scanner
;;   http://orgmode.org/worg/dev/org-element-api.html

(require 'org-element)
(require 'org-table)

(defun otama--element-all-tables (&optional tree)
  "Find all tables in org element TREE.
If TREE is omitted, create it by parsing current buffer."
  (org-element-map (or tree (org-element-parse-buffer)) 'table
    #'identity))

(defun otama--element-find-table (title &optional tree)
  "Find table by TITLE in org element TREE.
If TREE is omitted, create it by parsing current buffer.
See also `otama--element-table-title'."
  (catch 'found
    (org-element-map (or tree (org-element-parse-buffer)) 'table
      (lambda (table)
        (if (string= title (otama--element-table-title table))
            (throw 'found table))))))

(defun otama--element-table-at-point ()
  "Return org table element at point.
Returned table element has parents as a part of AST."
  (when (org-at-table-p)
    (catch 'found
      (org-element-map (org-element-parse-buffer) 'table
        (lambda (table)
          (if (<= (org-element-property :begin table)
                  (point)
                  (org-element-property :end table))
              (throw 'found table)))))))

(defun otama--element-table-title (table)
  "Return title of org TABLE element.
Title is taken from the parent org headline element."
  (let* ((headline (org-element-lineage table '(headline))))
    (substring-no-properties
     (org-element-interpret-data
      (org-element-property
       :title headline)))))

(defun otama--element-table-name (table)
  "Return name of org TABLE element.
Name is taken from #+name: property."
  (org-element-property :name table))

(defun otama--element-table-to-alists (table)
  "Return all rows in org TABLE element as a list of alists."
  (let ((colnames (otama--element-table-headers table))
        (rows (otama--element-table-rows table)))
    (mapcar (lambda (row)
              (otama--element-table-row-to-alist
               colnames row))
            rows)))

(defun otama--element-table-headers (table)
  "Return the first row of TABLE element as a symbol list."
  (let ((first-row (org-element-map table 'table-row #'identity nil t)))
    (mapcar #'intern (otama--element-table-row-to-strings first-row))))

(defun otama--element-table-rows (table)
  "Return a list of table-row elements from TABLE ignoring first header."
  (delq nil (nthcdr 1
    (org-element-map table 'table-row
      (lambda (row)
        (and (eq (org-element-property :type row) 'standard)
             row))))))

(defun otama--element-table-row-to-strings (table-row)
  "Convert an org TABLE-ROW element to a list of strings."
  (if (eq (org-element-property :type table-row) 'standard)
      (org-element-map table-row 'table-cell
        (lambda (cell) (otama--element-content-string cell)))))

(defun otama--element-table-row-to-alist (colnames table-row)
  "Create alist by zipping up COLNAMES with org TABLE-ROW element."
  (otama--element-zip
   colnames
   (otama--element-table-row-to-strings table-row)))

(defun otama--element-zip (keys values)
  "Make alist from KEYS and VALUES."
  (if (or (null keys) (null values))
      ()
    (cons (cons (car keys) (car values))
          (otama--element-zip (cdr keys) (cdr values)))))

(defun otama--element-content-string (element)
  "Return content of org ELEMENT as string."
  (buffer-substring-no-properties
   (org-element-property :contents-begin element)
   (org-element-property :contents-end element)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Database and Records

(defmacro otama--with-database (database &rest body)
  "With DATABASE, execute the forms in BODY."
  (declare (indent 1))
  `(with-current-buffer (find-file-noselect (otama-file-name ,database))
     (save-excursion
       (save-restriction
         (widen)
         (goto-char (point-min))
         ,@body))))

(defun otama--add-record-to-table (record table)
  "Add RECORD to TABLE."
  (let ((end (org-element-property :contents-end table))
        (names (otama--element-table-headers table)))
    (goto-char end)
    (insert
     (concat "| "
             (mapconcat (lambda (name)
                          (otama-attribute record name)) names " | ")
             " |\n"))
    (org-table-align)
    ))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; User interface to otama DB

;;;###autoload
(defun otama-open (file-name)
  "Open org file specified by FILE-NAME as database."
  (list file-name))

(defun otama-file-name (database)
  "Return file-name of DATABASE."
  (expand-file-name
   (if (stringp database) database (car database))))

(defun otama-records (database &optional table-name)
  "Return all records in DATABASE.
If TABLE-NAME is non-nil, return records in the table."
  (otama--with-database database
    (if table-name
        (otama--element-table-to-alists
         (otama--element-find-table table-name))
      (apply 'append
             (mapcar
              (lambda (table)
                (otama--element-table-to-alists table))
              (otama--element-all-tables))))))

(defun otama-select (database function &optional table-name)
  "Return records from DATABASE where FUNCTION is true.
If TABLE-NAME is non-nil, return records in the table."
  (delq nil (mapcar (lambda (record)
                      (and (funcall function record) record))
                    (otama-records database table-name))))

(defun otama-find (database key value &optional table-name)
  "Return records from DATABASE where KEY == VALUE.
If TABLE-NAME is non-nil, return records in the table."
  (otama-select database
    (lambda (record) (string= (otama-attribute record key) value))
    table-name))

(defun otama-insert (record table-name database)
  "Insert RECORD to the table specified by TABLE-NAME in DATABASE."
  (otama--with-database database
    (let ((table (otama--element-find-table table-name)))
      (otama--add-record-to-table record table)
      (save-buffer))))

(defun otama-attribute (record key)
  "Return attribute of RECORD specified by KEY.
Retun nil if KEY is not a member of the RECORD."
  (cdr (assoc key record)))

(defun otama-stringify-attribute (record key &optional format-string)
  "Return stringified attribute of RECORD specified by KEY.
If FORMAT-STRING is omitted, \"%s\" is assumed."
  (let ((value (otama-attribute record key)))
    (if (and value (not (string= value "")))
        (format (or format-string "%s") value)
      "")))

(defun otama-format-record (record format-string &rest keys)
  "Format RECORD by FORMAT-STRING applying KEYS."
  (apply 'format format-string
         (mapcar (lambda (key)
                   (otama-attribute record key))
                 keys)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helm interface to otama DB

(declare-function helm-other-buffer "helm")
(declare-function helm-build-sync-source "helm-source")

(defvar otama-database-file-name "~/address-book.org"
  "File name of org-table style address book.
See address-book-sample.org for details.")

(defun otama-helm-real-to-display (real)
  "Convert REAL otama record to string."
  (format "%s %s %s %s"
          (otama-stringify-attribute real 'name)
          (otama-stringify-attribute real 'mail "<%s>")
          (otama-stringify-attribute real 'organization "(%s)")
          (otama-stringify-attribute real 'title "- %s")))

(defun otama-helm-records ()
  "Return records from otama DB."
  (let ((db (otama-open otama-database-file-name)))
    (mapcar (lambda (record)
              (cons (otama-helm-real-to-display record) record))
            (otama-records db))))

;; http://wikemacs.org/wiki/How_to_write_helm_extensions#Handling_multiple_selections
(defvar otama-helm-source-entries
  (helm-build-sync-source "OTAMA entries"
    :candidates 'otama-helm-records
    :migemo t
    :action '(("Insert mail address" .
               (lambda (candidate)
                 (insert
                  (mapconcat (lambda (c) (otama-attribute c 'mail))
                             (helm-marked-candidates) ", "))))
              ("Insert org list item" .
               (lambda (candidate)
                 (mapc
                  (lambda (c)
                    (insert (format "+ %s\n" (otama-helm-real-to-display c))))
                  (helm-marked-candidates)))))))

;;;###autoload
(defun otama-helm ()
  "Insert address book entries in Otama using Helm.
Otama is an org-table file specified by `otama-database-file-name'."
  (interactive)
  (helm-other-buffer
   'otama-helm-source-entries
   "*Helm OTAMA Entries*"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Otama mail

(require 'mailheader) ;; mail-header-extract-no-properties, mail-header
(require 'rfc822) ;; rfc822-addresses

(defvar otama-mail-header-separators
  `("" "----" ,(if (boundp 'mail-header-separator) mail-header-separator ""))
  "Word list to separate mail headers from body.")

(defvar otama-mail-post-titles
  '("皆様" "の皆様" "皆さん" "の皆さん" "各位"
    "先生" "様" "殿" "さん" "君" "くん" "ちゃん"
    "教授" "学科長" "学部長" "副学部長" "研究科長" "理事" "学長"
    "会長" "社長" "専務" "常務" "本部長" "局長"
    "部長" "課長" "係長" "所長" "主幹" "主任"
    "支部長" "主査" "幹事" "委員長" "委長" "運営委長")
  "Word list of Japanese post-titles (san, sama...).")

(defun otama-mail-goto-beginning-of-body ()
  "Goto beginning of mail body."
  (otama-mail-goto-end-of-header)
  (forward-line))

(defun otama-mail-goto-end-of-header ()
  "Goto end of mail headers."
  (goto-char (point-min))
  (if (re-search-forward
       (concat "^" (regexp-opt otama-mail-header-separators) "$") nil t)
      (beginning-of-line)
    (goto-char (point-max))
    (if (eolp) (insert "\n"))))

(defun otama-mail-header-to-alist ()
  "Extract headers as alist from current buffer.
Each element is a cons cell (name . value),
where NAME is a symbol, and VALUE is corresponding string."
  (save-excursion
    (save-restriction
      (otama-mail-goto-end-of-header)
      (narrow-to-region (point-min) (point))
      (goto-char (point-min))
      (mail-header-extract-no-properties))))

(defun otama-mail-header-addresses (&rest headers)
  "Return mail addresses listed in HEADERS.
For example, in the buffer:
  To: foo@example.com, bar@example.net
  Cc: baz@example.org

and call:
  (otama-mail-header-addresses 'to 'cc)

Returns:
  (\"foo@example.com\" \"bar@example.net\" \"baz@example.org\")"
  (let ((header-alist (otama-mail-header-to-alist))
        (value))
    (apply #'append
           (mapcar
            (lambda (header)
              (if (setq value (mail-header header header-alist))
                  (rfc822-addresses value)))
            headers))))

(defun otama-mail-snippet-string ()
  "Return first consecutive non-blank lines of mail body as a string."
  (save-excursion
    (save-restriction
      (otama-mail-goto-beginning-of-body)
      (let ((top (point))
            (btm (or (re-search-forward "^$" nil t) (point-max))))
        (buffer-substring-no-properties top btm)))))

(defun otama-mail-parse-snippet-string (snippet)
  "Extract Japanese greeting strings in SNIPPET.

For example, SNIPPET is a string:
  (otama-mail-parse-snippet-string \"A電気  田中さん，B商事  鈴木さん，
    (Cc: X大学  山本さん，Z大学  川崎さん)
    乃村です．\")

Returns:
  (\"A電気  田中さん\" \"B商事  鈴木さん\"
   \"X大学  山本さん\" \"Z大学  川崎さん\" \"乃村です．\")"
  (split-string
   (replace-regexp-in-string "(Cc: *\\([^)]+\\))" "\\1" snippet)
   "[\n，、,]+" t "[　 ]+"))

(defun otama-mail-greeting-to-record (greeting)
  "Create Otama record from Japanese GREETING string.
GREETING is assumed to be:
  ({organization} SPC SPC)? {name} {pn-title}"
  (if (and (stringp greeting)
           (string-match
            (concat "^\\(?:\\(.+\\)  \\)?\\(.*\\)"
                    "\\(" (regexp-opt otama-mail-post-titles) "\\)")
            greeting))
      (list
       (cons 'organization (match-string 1 greeting))
       (cons 'name         (match-string 2 greeting))
       (cons 'pn-title     (match-string 3 greeting)))))

;;;###autoload
(defun otama-mail-to-address-records ()
  "Get otama address records from mail draft buffer.
Each record has these attributes:
 organization, name, pn-title, mail, snippet"
  (let ((mails (otama-mail-header-addresses 'to 'cc))
        (greetings (otama-mail-parse-snippet-string
                    (otama-mail-snippet-string)))
        (records ()))
    (while mails
      (setq records
            (cons
             (append
              (otama-mail-greeting-to-record (car greetings))
              (list
               (cons 'mail (car mails))
               (cons 'snippet (car (last greetings)))
               (cons 'timestamp (format-time-string "%Y-%m-%d %H:%M:%S"))))
             records))
      (setq mails (cdr mails)
            greetings (cdr greetings)))
    (nreverse records)))

(provide 'otama)

;;; otama.el ends here
