;;; wikinforg.el --- Org-mode wikinfo integration  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2022 Nicholas Vollmer

;; Author: Nicholas Vollmer <progfolio@protonmail.com>
;; URL: https://github.com/progfolio/wikinforg
;; Package-Version: 20230317.2050
;; Package-Commit: fe16cbecc73a41110f2bad95c1f63a97a9da88ca
;; Created: September 14, 2020
;; Keywords: org, convenience
;; Package-Requires: ((emacs "27.1") (wikinfo "0.0.0") (org "9.3"))
;; Version: 0.1.0

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
;; Wikinforg provides Org mode integration for wikinfo (https://github.com/progfolio/wikinfo)
;; See the `wikinforg` command and the `wikinforg-capture` function.

;;; Code:
;;;; Dependencies
(require 'wikinfo)
(require 'org-element)
(require 'org)
(require 'cl-lib)

;;;; Declarations
(declare-function org-toggle-checkbox "org-list")

;;;; Customizations
(defgroup wikinforg nil
  "Org wikinfo integration."
  :group 'wikinforg
  :prefix "wikinforg-")

(defcustom wikinforg-wikipedia-edition-code "en"
  "Wikipedia edition to use for queries.
See:
https://en.wikipedia.org/wiki/List_of_Wikipedias#Wikipedia_edition_codes
for a complete list of codes."
  :type 'string)

(defcustom wikinforg-include-extract t
  "Whether or not to include a summary in the resultant entry's body."
  :type 'boolean)

(defcustom wikinforg-thumbnail-directory nil
  "Path to directory for storing wikinforg thumbnails."
  :type 'string)

(defcustom wikinforg-include-thumbnail nil
  "Whether or not to include thumbnail with resultant entry.
Thumbnails are downloaded to `wikinforg-thumbnail-directory'."
  :type 'boolean)

(defcustom wikinforg-query-format "%s"
  "Format string for queries."
  :type 'string)

(defcustom wikinforg-data-type 'entry
  "Type of data returned by wikinforg.
May be lexically bound to change for a single call"
  :type '(choice (const :tag "Regular entry" entry)
                 (const :tag "plain list item" item)
                 (const :tag "checklist item" checkitem)
                 (const :tag "plain text (excluding properties)" plain)
                 (const :tag "top-level #+title, properties" buffer)))

(defcustom wikinforg-extract-format-function nil
  "Function responsible for formatting/transforming the extract text.
It must be a unary function which accepts the extract text as a string
and returns a string.
If nil, it is ignored."
  :type '(or function nil))

(defcustom wikinforg-post-insert-hook nil
  "Hook run after an entry is inserted when `wikinforg' is called interactively."
  :type 'hook)

;;;; Functions
(defun wikinforg--format-query (query)
  "Return formatted QUERY using `wikinforg-query-format' string."
  (format wikinforg-query-format query))

(defvar wikinforg-mode-map (let ((map (make-sparse-keymap)))
                             (define-key map (kbd "q") 'quit-window)
                             map)
  "Keymap for wikinforg mode.")

(define-derived-mode wikinforg-mode org-mode "wikinforg"
  "Major mode for viewing wikinforg entries.
\\{wikinforg-mode-map}"
  (read-only-mode 1))

(defun wikinforg--display (title entry)
  "Display a wikinforg buffer for TITLE with ENTRY."
  (with-current-buffer (get-buffer-create (format "*%S wikinforg*" title))
    (read-only-mode -1)
    (erase-buffer)
    (insert entry)
    (run-hooks 'wikinforg-post-insert-hook)
    (wikinforg-mode)
    (pop-to-buffer (current-buffer))))

(defun wikinforg--property-drawer (info)
  "Return Org property list data from `wikinfo' query INFO."
  (let* ((id (wikinfo--plist-path info :wikinfo :id))
         (url (format "%s?curid=%d" wikinfo-base-url id)))
    `( property-drawer nil
       ,@(cl-loop for el in info
                  when (and (keywordp el) (not (eq el :wikinfo)))
                  collect `(node-property
                            ( :key ,(substring (symbol-name el) 1)
                              :value ,(format "%s" (plist-get info el)))))

       (node-property (:key "wikinfo-id" :value ,id))
       (node-property (:key "URL" :value ,url)))))

(defun wikinforg--thumbnail (info &optional temp)
  "Save local thumbnail. Return thumbnail Org data from `wikinfo' INFO.
If TEMP is non-nil the thumbnail is saved to a temporary directory.
Otherwse `wikinforg-thumbnail-directory' is used."
  (when-let ((wikinforg-include-thumbnail)
             (url (plist-get info :thumbnail))
             (dir (file-truename
                   (if temp
                       (let ((d (expand-file-name "wikinforg/" (temporary-file-directory))))
                         (unless (file-exists-p d) (make-directory d 'parents))
                         d)
                     (or wikinforg-thumbnail-directory "./wikinforg/thumbnails"))))
             (name (concat (replace-regexp-in-string ".*/" "" url)))
             (path (expand-file-name name dir)))
    (unless (file-exists-p dir) (make-directory dir 'parents))
    (with-temp-buffer (url-insert-file-contents url) (write-file path))
    `(link (:type "file" :path ,path :format bracket :raw-link ,path))))

(defun wikinforg--body (&optional thumbnail extract)
  "Return Org data for paragraph including THUMBNAIL and EXTRACT."
  `(paragraph nil ,(when thumbnail (list "\n" thumbnail "\n\n")) ,extract))

;;;; Commands
;;;###autoload
(defun wikinforg (query &optional predicate temp)
  "Insert formatted `wikinfo' QUERY at point.
PREDICATE is passed to `wikinfo'.
When TEMP is non-nil, or called interactively with a prefix arg,
show the result in a buffer instead of inserting."
  (interactive (list (read-string "Wikinforg: ") nil current-prefix-arg))
  (let* ((query (string-trim (wikinforg--format-query query)))
         (wikinfo-base-url (format "https://%s.wikipedia.org" wikinforg-wikipedia-edition-code))
         (info (wikinfo query predicate))
         (title (or (wikinfo--plist-path info :wikinfo :title) query))
         (property-drawer (wikinforg--property-drawer info))
         (body (wikinforg--body (wikinforg--thumbnail info temp)
                                (and wikinforg-include-extract
                                     (funcall (or wikinforg-extract-format-function #'identity)
                                              (wikinfo--plist-path info :wikinfo :extract)))))
         (data (pcase wikinforg-data-type
                 ('entry `(headline (:level 1 :title ,title) ,property-drawer ,body))
                 ((or 'item 'checkitem)
                  `(item ( :bullet "- " :pre-blank 0
                           ,@(when (eq wikinforg-data-type 'checkitem)
                               (list :checkbox 'off)))
                         (paragraph nil ,title)
                         (paragraph nil ,body)))
                 ('plain `((paragraph nil ,title) (paragraph nil ,body)))
                 ('buffer `(,property-drawer
                            (keyword (:key "TITLE" :value ,title))
                            ,body))
                 (_ (signal 'wrong-type-argument
                            (list '(entry item checkitem plain buffer)
                                  wikinforg-data-type)))))
         (result (org-element-interpret-data `(org-data nil ,data))))
    (if temp
        (wikinforg--display title result)
      (save-excursion
        (if (derived-mode-p 'org-mode)
            (org-paste-subtree nil result)
          (insert result)))
      (run-hooks 'wikinforg-post-insert-hook))))

(defun wikinforg-capture-run-hook ()
  "Run `wikinforg-post-insert-hook' in context of capture buffer."
  (run-hooks 'wikinforg-post-insert-hook)
  (remove-hook 'org-capture-mode-hook #'wikinforg-capture-run-hook))

(declare-function org-capture-get "org-capture")
;;;###autoload
(defun wikinforg-capture (&optional suffix)
  "Wikinforg wrapper for use in capture templates.
Call `wikinforg' command with search SUFFIX.
If the wikinforg call fails, the user's query is returned.
If the command is aborted, return an empty string to prevent capture error."
  (require 'org-capture)
  (add-hook 'org-capture-mode-hook #'wikinforg-capture-run-hook)
  (let ((prefix (pcase (org-capture-get :type)
                  ((or `nil `entry) "* ")
                  ('table-line (user-error "Wikinforg does not support table-line templates"))
                  ('plain "")
                  ('item "- ")
                  ('check-item "- [ ] ")
                  (`,unrecognized (user-error "Unrecognized template type %s" unrecognized)))))
    (condition-case nil
        (let ((query (or (read-string (format "Wikinforg (%s): " suffix))
                         "")))
          (condition-case nil
              (wikinforg (string-trim (concat query " " suffix)))
            ((error quit) (concat prefix query)))))))

(provide 'wikinforg)

;;; wikinforg.el ends here
