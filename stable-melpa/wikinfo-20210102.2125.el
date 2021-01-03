;;; wikinfo.el --- Scrape Wikipedia Infoboxes -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Nicholas Vollmer

;; Author: Nicholas Vollmer <progfolio@protonmail.com>
;; URL: https://github.com/progfolio/wikinfo
;; Package-Version: 20210102.2125
;; Package-Commit: e59b0d90155c1b38178f71f42a1b8797d4fcc8f1
;; Created: September 14, 2020
;; Keywords: org, convenience
;; Package-Requires: ((emacs "27.1"))
;; Version: 0.0.0

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; Wikinfo scrapes Wikipedia's infoboxes into a plist for use with other programs.

;;; Code:
(require 'url)
(require 'dom)
(eval-when-compile (require 'subr-x))

;;; Custom Options
(defgroup wikinfo nil
  "Wikipedia infobox to Elisp bridge"
  :group 'development
  :prefix "wikinfo-")

(defcustom wikinfo-base-url "https://en.wikipedia.org"
  "Base URL used for API URLS."
  :type 'string)

(defcustom wikinfo-api-endpoint "/w/api.php?"
  "API endpoint for queries and searches."
  :type 'string)

;;@TODO: grab page urls in this query?
(defcustom wikinfo-search-params '("&action=query"
                                   "&generator=search"
                                   "&gsrsearch=%s hastemplate:\"infobox\""
                                   "&gsrlimit=20"
                                   "&gsrinfo=suggestion"
                                   "&gsrnamespace=0"
                                   "&gsrwhat=text"
                                   "&prop=extracts"
                                   "&exintro"
                                   "&explaintext"
                                   "&exlimit=max"
                                   "&exsentences=3"
                                   "&format=json")
  "Search query parameters."
  :type 'string)

(defcustom wikinfo-parse-params '("&action=parse"
                                  "&pageid="
                                  "%s"
                                  "&prop=text"
                                  "&section=0"
                                  "&format=json")
  "Page parsing query parameters."
  :type 'string)

(defcustom wikinfo-ignored-targets '(style
                                     br
                                     hr
                                     "reference"
                                     "plainlinks"
                                     "NavHead")
  "List of targets for `wikinfo--remove-targets'."
  :type 'list)

(defface wikinfo-search-title '((t (:weight bold :height 1.05)))
  "Face for search result extracts.")

;;; Functions
(defun wikinfo--plist-path (plist &rest path)
  "Recusrively retrive PATH from PLIST."
  (unless (listp plist)
    (user-error "Plist is not a list"))
  (while path
    (setq plist (plist-get plist (pop path))))
  plist)

(defun wikinfo--url-params (param-list query)
  "Replace query symbol in PARAM-LIST with QUERY string."
  (format (string-join param-list) query))

(defun wikinfo--url ()
  "RETURN base URL for QUERY."
  (concat wikinfo-base-url wikinfo-api-endpoint))

(defun wikinfo--json (url)
  "Get JSON from URL. Return a JSON object."
  (message "API URL: %s" url)
  (with-current-buffer (url-retrieve-synchronously url)
    (kill-region (point-min)
                 (save-match-data
                   (re-search-forward "^\n" nil t)
                   (point)))
    (json-parse-string (buffer-string)
                       :object-type 'plist)))

(defun wikinfo-search (&optional query filter)
  "Search wikipedia for QUERY. Return plist with page metadata.
FILTER must be a unary function which accepts the QUERY result list.
It must return a single result. If nil, the user is prompted."
  (if-let* ((query (or query (read-string "Query: ")))
            (url (concat (wikinfo--url)
                         (wikinfo--url-params wikinfo-search-params query)))
            (JSON (wikinfo--json url))
            (pages (cdr (wikinfo--plist-path JSON :query :pages)))
            (candidates
             (mapcar (lambda (page)
                       (when-let ((extract (plist-get page :extract))
                                  (id      (plist-get page :pageid))
                                  (title   (plist-get page :title))
                                  (index   (plist-get page :index)))
                         (setq extract (wikinfo--sanitize-data extract))
                         (cons (concat (propertize title
                                                   'face 'wikinfo-search-title)
                                       "\n" extract)
                               `( :extract ,extract
                                  :index   ,index
                                  :title   ,title
                                  :id      ,id))))
                     pages))
            (sorted (sort (delq nil candidates)
                          (lambda (a b)
                            (< (plist-get (cdr a) :index)
                               (plist-get (cdr b) :index))))))
      (if filter
          (funcall filter (mapcar #'cdr sorted))
        (alist-get (completing-read "wikinfo: "
                                    (mapcar #'car sorted)
                                    nil 'require-match)
                   sorted nil nil #'string=))
    ;;@TODO: Fix this. Needs to be more robust.
    (user-error "Query %S failed" query)))

(defun wikinfo--santize-header-text (string)
  "Return santizied th STRING."
  (thread-last
      (downcase string)
    (replace-regexp-in-string "\\(?:[[:space:]]\\| \\)" "-")
    (replace-regexp-in-string "[^[:alnum:]-]" "")
    (replace-regexp-in-string "--" "-")
    (replace-regexp-in-string "-$" "")
    (replace-regexp-in-string "^-" "")))

(defun wikinfo--sanitize-data (string)
  "Return sanitized STRING."
  (thread-last
      string
    ;;embedded newline characters
    (replace-regexp-in-string "\\(?:[[:space:]]+\n[[:space:]]+\\)" ",")
    (replace-regexp-in-string "\\(?:\n\\)" " ")
    ;;non breaking spaces
    (replace-regexp-in-string " " " ")
    ;;double spaces
    (replace-regexp-in-string "[[:space:]]\\{2,\\}" " ")
    ;;extra space around open paren type delimiters
    (replace-regexp-in-string "\\(?:\\([(<[{\"]\\) \\)" "\\1")
    ;;extra space around closing paren type delimiters
    (replace-regexp-in-string "\\(?: \\([])>}]\\)\\)" "\\1")
    (replace-regexp-in-string "\\(?:\\([[:digit:]]+\\)[[:space:]]*\\(:\\)[[:space:]]*\\([[:digit:]]+\\)\\)"
                              "\\1\\2\\3")
    ;;multiple commas
    (replace-regexp-in-string ",\\{2,\\}" ",")
    ;;space before ", ; : ."
    (replace-regexp-in-string "\\(?: \\([,:;.]\\)\\)" "\\1")
    ;;extra space around "/"
    (replace-regexp-in-string "\\(?:[[:space:]]+\\(/[[:alpha:]]*\\)[[:space:]]*\\)" "\\1")
    ;;trailing comma
    (replace-regexp-in-string "\\(?:,[[:space:]]*$\\)" "")
    ;;leading comma
    (replace-regexp-in-string "\\(?:^[[:space:]]*,[[:space:]]*\\)" "")
    ;;comma without spaces e.g. x,x
    (replace-regexp-in-string "\\(?:\\(,\\)\\([^[:space:]]+\\)\\)" "\\1 \\2")
    (string-trim)))

;;@TODO: make non-destructive if we use it more than once in the future.
(defun wikinfo--remove-targets (dom targets)
  "Remove list of TARGETS from DOM.
TARGETS must one of the following:
  - a symbol representing a tag (e.g. `style`)
  - a regexp matching a class name
 Returns altered DOM."
  (let ((nodelist
         (thread-last
             targets
           (mapcar (lambda (target)
                     (let* ((classp (stringp target))
                            (nodes
                             (funcall (if classp #'dom-by-class #'dom-by-tag)
                                      dom target)))
                       nodes)))
           (delq nil)
           (apply #'append)
           (delete-dups))))
    (dolist (tag nodelist dom)
      (dom-remove-node dom tag))))

(defun wikinfo-infobox (id)
  "Return wikipedia infobox as plist for page with ID."
  (let* ((url (concat (wikinfo--url)
                      (wikinfo--url-params wikinfo-parse-params id)))
         (JSON (wikinfo--json url))
         (wikitext-html (wikinfo--plist-path JSON :parse :text :*))
         (html (with-temp-buffer
                 (insert wikitext-html)
                 (libxml-parse-html-region (point-min) (point-max))))
         (table (or (wikinfo--remove-targets
                     (dom-by-class html "infobox.*") wikinfo-ignored-targets)
                    (error "Infobox not found")))
         (rows (dom-by-tag table 'tr))
         result)
    (dolist (row rows result)
      (when-let* ((header (dom-by-tag row 'th))
                  (header-texts (wikinfo--santize-header-text (dom-texts header)))
                  (data (dom-texts (dom-by-tag row 'td))))
        (unless (or (string-empty-p header-texts)
                    (string-empty-p data))
          (setq result
                (plist-put result
                           (intern (concat ":" header-texts))
                           (wikinfo--sanitize-data data))))))
    result))

(defun wikinfo (&optional search filter)
  "Return infobox plist for SEARCH.
FILTER and SEARCH are passed to `wikinfo-search'."
  (let* ((query (wikinfo-search search filter))
         (infobox (wikinfo-infobox (plist-get query :id))))
    (plist-put infobox :wikinfo query)))

(provide 'wikinfo)

;;; wikinfo.el ends here
