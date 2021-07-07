;;; helm-hayoo.el --- Source and configured helm for searching hayoo

;; Copyright (C) 2014 Markus Hauck

;; Author: Markus Hauck <markus1189@gmail.com>
;; Maintainer: Markus Hauck <markus1189@gmail.com>
;; Keywords: helm
;; Package-Version: 20151014.651
;; Package-Commit: dd4c0c8c87521026edf1b808c4de01fa19b7c693
;; Version: 0.0.3
;; Package-requires: ((helm "1.6.0") (json "1.2") (haskell-mode "13.07"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package provides a helm source `helm-source-hayoo' and a
;; configured helm `helm-hayoo' to search hayoo online.
;;
;; Example queries to test (enter text displayed after '> '):
;;
;; > lens traversed
;; > simpleHttp
;; > modifySTRef

;;; Code:

(require 'helm)
(require 'helm-utils)
(require 'helm-help)
(require 'json)

(require 'haskell-navigate-imports)
(require 'haskell-sort-imports)
(require 'haskell-align-imports)

(defgroup helm-hayoo nil
  "Helm source for hayoo."
  :group 'helm)

(defcustom helm-hayoo-query-url
  "http://hayoo.fh-wedel.de/json?query=%s"
  "Url used to query hayoo, must have a `%s' placeholder."
  :group 'helm-hayoo
  :type 'string)

(defcustom helm-hayoo-sort-imports t
  "If non-nil, sort imports after adding a new one."
  :group 'helm-hayoo
  :type 'boolean)

(defcustom helm-hayoo-align-imports t
  "If non-nil, align imports after adding a new one."
  :group 'helm-hayoo
  :type 'boolean)

(defcustom helm-hayoo-browse-url 'browse-url
  "Function used to open urls from `helm-hayoo'."
  :group 'helm-hayoo
  :type '(choice
          (function-item :tag "browse-url" :value browse-url)
          (function :tag "Custom function")))

(defvar helm-hayoo--nothing-found-indicator (cons "No results found." nil))

(defun helm-hayoo-make-query (query)
  "Url encode and return a valid query for QUERY to hayoo."
  (format helm-hayoo-query-url (url-encode-url query)))

(defun helm-hayoo-search ()
  "Search hayoo for current `helm-pattern'."
  (let ((results
        (mapcar
         (lambda (result) (cons (helm-hayoo-format-result result) result))
         (append (assoc-default 'result
                                (helm-hayoo-do-search helm-pattern)) nil))))
    (if results results helm-hayoo--nothing-found-indicator)))

(defun helm-hayoo-do-search (query)
  "Retrieve json response for search QUERY from hayoo."
  (with-current-buffer (url-retrieve-synchronously (helm-hayoo-make-query query))
    (goto-char (point-min))
    (re-search-forward "^{" nil t)
    (beginning-of-line)
    (json-read-object)))

(defun helm-hayoo-format-result (result)
  "Format json parsed response RESULT for display in helm."
  (let ((package (assoc-default 'resultPackage result))
        (signature (assoc-default 'resultSignature result))
        (name (assoc-default 'resultName result))
        (module (assoc-default 'resultModules result)))
    (format "(%s) %s %s :: %s" package module name signature)))

(defun helm-hayoo-action-insert-name (item)
  "Insert name of ITEM at point."
  (insert (assoc-default 'resultName item))
  (message (helm-hayoo-format-result item)))

(defun helm-hayoo-action-browse-haddock (item)
  "Browse haddock for ITEM."
  (message (assoc-default 'resultUri item))
  (funcall helm-hayoo-browse-url (assoc-default 'resultUri item)))

(defun helm-hayoo-action-kill-name (item)
  "Kill the name of ITEM."
  (kill-new (assoc-default 'resultName item)))

(defun helm-hayoo-action-import (item)
  "Insert a haskell import statement for ITEM."
  (if (not (equal 'haskell-mode major-mode))
      (message "Can't import if not in haskell-mode buffer.")
    (save-excursion
      (goto-char (point-min))
      (haskell-navigate-imports)
      (helm-hayoo--insert-import-smart item)
      (if helm-hayoo-sort-imports (haskell-sort-imports))
      (if helm-hayoo-align-imports (haskell-align-imports)))))

(defun helm-hayoo--first-import-pos ()
  "Return point at the start of the first import line."
  (save-excursion (goto-char (point-min))
                  (re-search-forward "^import " nil t)
                  (beginning-of-line)
                  (point)))

(defun helm-hayoo--last-import-pos ()
  "Return point at end of last import line."
  (save-excursion (goto-char (point-max))
                  (re-search-backward "^import " nil t)
                  (end-of-line)
                  (point)))

(defun helm-hayoo--insert-import-smart (item)
  "Try to be smart about how to insert import for ITEM."
  (let ((module (elt (assoc-default 'resultModules item) 0))
        (name (assoc-default 'resultName item))
        (first-import-pos (helm-hayoo--first-import-pos))
        (last-import-pos (helm-hayoo--last-import-pos)))
    (goto-char first-import-pos)
    (let ((module-imported
           (re-search-forward
            (format (rx bol "import" (regex "[[:space:]]+") "%s" (or eol (group (0+ space) "("))) module)
            last-import-pos t)))
      (if module-imported
          (helm-hayoo--import-add-to-list-or-resign module name)
        (message "Not imported yet.")
        (insert (concat (helm-hayoo-format-item-for-import item) "\n"))))))

(defun helm-hayoo--import-add-to-list-or-resign (module name)
  (let ((has-paren (progn
                     (beginning-of-line)
                     (search-forward "(" (line-end-position) t))))
    (if (not has-paren)
        t
      (beginning-of-line)
      (search-forward "(" (line-end-position) t)
      (backward-char 1)
      (forward-sexp)
      (backward-char)
      (insert (format ", %s" name)))))

(defun helm-hayoo-format-item-for-import (item)
  "Format json parsed item ITEM for usage as a haskell import statement."
  (let ((module (elt (assoc-default 'resultModules item) 0))
        (name (assoc-default 'resultName item)))
    (format "import %s (%s)" module name)))

(defun helm-hayoo-matcher-name (candidate)
  "Try to match `helm-pattern' in the name of CANDIDATE."
  (string-match-p helm-pattern candidate))

(defun helm-hayoo-run-import-this ()
  "Execute import action from `helm-source-hayoo'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-hayoo-action-import)))

(defun helm-hayoo-run-browse-haddock ()
  "Execute browse haddock action from `helm-source-hayoo'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-hayoo-action-browse-haddock)))

(defvar helm-hayoo-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "C-c i") 'helm-hayoo-run-import-this)
    (define-key map (kbd "C-c b") 'helm-hayoo-run-browse-haddock)
    (define-key map (kbd "C-c ?") 'helm-hayoo-help)
    map))

(defvar helm-hayoo-help-message
  "== Helm hayoo ==\
\nSpecific commands for Helm hayoo:
\\<helm-hayoo-map>\
\\[helm-hayoo-run-import-this]\t\tImport the function and its module from this entry.
\\[helm-hayoo-run-browse-haddock]\t\tBrowse haddock for this entry.
\\[helm-hayoo-help]\t\tShow this help.
\n== Helm Map ==
\\{helm-map}")

(defun helm-hayoo-help ()
  "Display help for `helm-hayoo'."
  (interactive)
  (let ((helm-help-message helm-hayoo-help-message))
    (helm-help)))

(defvar helm-hayoo-mode-line-string '("Hayoo" "\
\\<helm-hayoo-map>\
\\[helm-hayoo-help]:Help|\
\\[helm-hayoo-run-import-this]:Import|\
\\[helm-hayoo-run-browse-haddock]:Browse haddock")
  "Help string displayed in mode-line in `helm-hayoo'.")

(defvar helm-source-hayoo
  `((name . "Hayoo")
    (volatile)
    (requires-pattern . 2)
    (match . (helm-hayoo-matcher-name (lambda (c) t)))
    (action . (("Insert name" . helm-hayoo-action-insert-name)
               ("Kill name" . helm-hayoo-action-kill-name)
               ("Browse haddock (C-c b)" . helm-hayoo-action-browse-haddock)
               ("Import this (C-c i)" . helm-hayoo-action-import)))
    (keymap . ,helm-hayoo-map)
    (candidates . helm-hayoo-search)
    (mode-line . helm-hayoo-mode-line-string))
  "Helm source for searching hayoo.")

;;;###autoload
(defun helm-hayoo ()
  "Preconfigured helm to search hayoo."
  (interactive)
  (helm :sources '(helm-source-hayoo)))

(provide 'helm-hayoo)
;;; helm-hayoo.el ends here
