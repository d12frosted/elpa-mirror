;;; hugsql-ghosts.el --- Display hugsql defqueries in clojure code as an overlay

;; Copyright (C) 2017 Roland Kaercher <roland.kaercher@gmail.com>, heavily based on yesql ghosts by Magnar Sveen <magnars@gmail.com>

;; Author: Roland Kaercher <roland.kaercher@gmail.com>
;; URL: https://github.com/rkaercher/hugsql-ghosts
;; Package-Commit: 7cd242cc2e70ac48959c42be725c81d7fe00b314
;; Package-Version: 20211124.1646
;; Package-X-Original-Version: 20211124.0613
;; Version: 0.1.4
;; Package-Requires: ((s "1.9.0") (dash "2.10.0") (cider "0.14.0"))

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Display ghostly hugsql defqueries inline.

;; The ghostly displays are inserted when cider-mode is entered, and
;; updated every time you save.

;;; Code:

(require 's)
(require 'dash)
(require 'cider)
(require 'nrepl-dict)
(require 'thingatpt)

(defgroup hugsql-ghosts nil
  "Display hugsql defqueries as overlay in clojure code."
  :group 'tools)

(defcustom hugsql-ghosts-show-docstrings 't
  "A non-nil value if you want to show query docstrings."
  :group 'hugsql-ghosts
  :type 'boolean)

(defcustom hugsql-ghosts-newline-before-docstrings nil
  "A non-nil value if you want to print a newline before query docstrings."
  :group 'hugsql-ghosts
  :type 'boolean)

(defface hugsql-ghosts-defn
  '((t :foreground "#686868" :background "#181818"))
  "Face for hugsql defns overlayed when in cider-mode."
  :group 'hugsql-ghosts)

(defface hugsql-ghosts-docstring
  '((t :foreground "#989898" :background "#181818"))
  "Face for hugsql docstrings overlayed when in cider-mode."
  :group 'hugsql-ghosts)

;;;###autoload
(defun hugsql-ghosts-remove-overlays ()
  "Remove all hugsql ghost overlays from the current buffer."
  (interactive)
  (--each (overlays-in (point-min) (point-max))
    (when (eq (overlay-get it 'type) 'hugsql-ghosts)
      (delete-overlay it))))

(defun hugsql-ghosts--fontify-ghost (string ghost-face)
  "Add font attributes for the face GHOST-FACE to the provided STRING."
  (set-text-properties 0 (length string) (list 'face ghost-face) string)
  string)

(defun hugsql-ghosts--insert-overlay (content)
  "Insert the overlay with the provided CONTENT at point."
  (let ((o (make-overlay (point) (point) nil nil t)))
    (overlay-put o 'type 'hugsql-ghosts)
    ;;    (overlay-put o 'before-string (hugsql-ghosts--fontify-ghost (concat content "\n") 'hugsql-ghosts-defn))))
    (overlay-put o 'before-string  (concat content "\n"))))

(defun hugsql-ghosts--format-query (query-metadata)
  "Format a single query fn for display using the provided QUERY-METADATA."
  (-let* (((name (&plist :doc doc)) query-metadata)
	  (has-doc? (and hugsql-ghosts-show-docstrings doc (not (s-blank? doc)))))
    (if has-doc?
	(format (hugsql-ghosts--fontify-ghost "(defn %s [db ...]%s%s)" 'hugsql-ghosts-defn)
		name
		(if hugsql-ghosts-newline-before-docstrings "\n" " ")
		(hugsql-ghosts--fontify-ghost (concat "\"" doc "\"") 'hugsql-ghosts-docstring))
      (hugsql-ghosts--fontify-ghost (format "(defn %s [db ...])" name) 'hugsql-ghosts-defn))))

(defun hugsql-ghosts--format-query-fns (query-fns)
  "Make a single string divided by newlines from the provided QUERY-FNS metadata."
  (s-join "\n" (-map 'hugsql-ghosts--format-query query-fns)))

(defconst hugsql-ghosts--clojure-eval-code-template "(map
(fn [[fname {:keys [meta]}]]
    (list (name fname) (mapcat (fn [[kw value]] [kw value]) meta)))
(hugsql.core/%s \"%s\"))")

(defconst hugsql-ghosts--clojure-db-fn-name "map-of-db-fns")
(defconst hugsql-ghosts--clojure-sqlvec-fn-name "map-of-sqlvec-fns")

(defun hugsql-ghosts--find-next-occurrence ()
  "Move to the next occurrence of a sql file import and return its type or nil if none is found."
  (if (search-forward "(hugsql/def-db-fns \"" nil t)
      :hugsql-db-fn
    (if (search-forward "(hugsql/def-sqlvec-fns \"" nil t)
	:hugsql-sqlvec-fn
      (when (re-search-forward "\(conman\/bind-connection\s[^\s]*\s\"" nil t)
	:hugsql-db-fn))))

(defun hugsql-ghosts--display-next-queries ()
  "Search and display the queries of the next sql file include from point."
  (-when-let (def-fns-found (hugsql-ghosts--find-next-occurrence))
    (let* ((path (thing-at-point 'filename))
	   (clojure-fn-name (if (eq :hugsql-db-fn def-fns-found)
				hugsql-ghosts--clojure-db-fn-name
			      hugsql-ghosts--clojure-sqlvec-fn-name))
	   (clojure-cmd (format hugsql-ghosts--clojure-eval-code-template clojure-fn-name path))
	   (cider-result (cider-nrepl-sync-request:eval clojure-cmd))
           (db-fns (read (nrepl-dict-get cider-result "value"))))
      (when db-fns
        (end-of-line)
        (forward-char 1)
	(hugsql-ghosts--insert-overlay (hugsql-ghosts--format-query-fns db-fns))))))

;;;###autoload
(defun hugsql-ghosts-display-query-ghosts ()
  "Displays an overlay after (hugsql/def-db-fns ...) or (hugsql/def-sqlvec-fns ...) or (conman/bind-connection ...) showing the names and docstrings of the generated functions from that file."
  (interactive)
  (hugsql-ghosts-remove-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (hugsql-ghosts--display-next-queries))))

;;;###autoload
(defun hugsql-ghosts-install-hook ()
  "Add a buffer local hook that refreshes the ghosts whenever the cider buffer is reloaded."
  (hugsql-ghosts-display-query-ghosts)
  (add-hook 'cider-file-loaded-hook 'hugsql-ghosts-display-query-ghosts nil 't))

;;;###autoload
(defun hugsql-ghosts-jump-sql-file ()
  "Jumps to the references SQL file, provides a choice when there are multiple references."
  (interactive)
  (goto-char (point-min))
  (let* ((path nil))
    (while (hugsql-ghosts--find-next-occurrence)
      (push (thing-at-point 'filename) path))
    (if (> (length path) 1)
	(cider-find-resource (completing-read "Jump to SQL file:" path))
      (cider-find-resource (car path)))))

(provide 'hugsql-ghosts)
;;; hugsql-ghosts.el ends here
