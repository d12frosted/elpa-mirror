;;; wikinforg.el --- Org-mode wikinfo integration  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Nicholas Vollmer

;; Author: Nicholas Vollmer <progfolio@protonmail.com>
;; URL: https://github.com/progfolio/wikinforg
;; Package-Version: 20201227.1454
;; Package-Commit: 8a418b9482c12b089ebca9a17d84b3c093f721c0
;; Created: September 14, 2020
;; Keywords: org, convenience
;; Package-Requires: ((emacs "27.1") (wikinfo "0.0.0") (org "9.3"))
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
;; Wikinforg provides Org mode integration for wikinfo (https://github.com/progfolio/wikinfo)
;; See the `wikinforg` command and the `wikinforg-capture` function.

;;; Code:
;;;; Dependencies
(require 'wikinfo)
(require 'org-element)
(require 'org)

;;;; Declarations
(declare-function org-toggle-checkbox "org-list")

;;;; Customizations
(defgroup wikinforg nil
  "Org wikinfo integration"
  :group 'wikinforg
  :prefix "wikinforg-")

(defcustom wikinforg-include-extract t
  "Whether or not to include a summary in the resultant entry's body."
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
                 (const :tag "plain text" plain)))

(defcustom wikinforg-extract-format-function nil
  "Function responsible for formatting/transforming the extract text.
It must be a unary function which accepts the extract text as a string
and returns a string.
If nil, it is ignored."
  :type '(or function nil))

;;;; Functions
(defun wikinforg--format-query (query)
  "Return formatted QUERY using `wikinforg-query-format' string."
  (format wikinforg-query-format query))

;;;; Commands
;;;###autoload
(defun wikinforg (&optional arg query predicate)
  "Return Org entry from `wikinfo'.
QUERY and PREDICATE are passed to `wikinfo'.
If ARG is equivalent to `\\[universal-argument]', message the entry instead of inserting."
  (interactive "P")
  (let* ((query (string-trim
                 (wikinforg--format-query (or query (read-string "Wikinforg: ")))))
         (info (wikinfo query predicate))
         (filtered (seq-filter (lambda (el)
                                 (and (keywordp el) (not (member el '(:wikinfo)))))
                               info))
         (id (wikinfo--plist-path info :wikinfo :id))
         (url (format "%s?curid=%d" wikinfo-base-url id))
         (property-drawer
          `( property-drawer nil
             ,@(mapcar (lambda (keyword)
                         (list 'node-property
                               (list :key (substring (symbol-name keyword) 1)
                                     :value (format "%s" (plist-get info keyword)))))
                       filtered)
             ,(list 'node-property (list :key "wikinfo-id" :value id))
             ,(list 'node-property (list :key "URL" :value url))))
         (paragraph `(paragraph nil ,(when wikinforg-include-extract
                                       (funcall (or wikinforg-extract-format-function
                                                  #'identity)
                                       (wikinfo--plist-path info :wikinfo :extract)))))
         (headline `(headline
                     ( :level 1
                       :title ,(or (wikinfo--plist-path info :wikinfo :title) query))
                     ,property-drawer
                     ,paragraph))
         (result (org-element-interpret-data `(org-data nil ,headline))))
    (unless (eq wikinforg-data-type 'entry)
      (setq result (with-temp-buffer
                     (let (org-mode-hook) (org-mode))
                     (insert result)
                     (if (eq wikinforg-data-type 'plain)
                         ;; drop leading star
                         (buffer-substring 2 (point-max))
                       (goto-char (point-min))
                       (call-interactively #'org-toggle-item)
                       ;;add check box
                       (when (eq wikinforg-data-type 'checkitem)
                         (org-toggle-checkbox '(4)))
                       (buffer-string)))))
    (if (or arg (not (called-interactively-p 'interactive)))
        (pcase arg
          ('(4) (message result))
          (_ result))
      ;;save-excursion doesn't work here?
      (let ((p (point)))
        (if (derived-mode-p 'org-mode)
            (org-paste-subtree nil result)
          (insert (with-temp-buffer
                    (org-mode)
                    (org-paste-subtree nil result)
                    (buffer-string))))
        (goto-char p)))))

(declare-function org-capture-get "org-capture")
;;;###autoload
(defun wikinforg-capture (&optional suffix)
  "Wikinforg wrapper for use in capture templates.
Call `wikinforg' command with search SUFFIX.
If the wikinforg call fails, the user's query is returned.
If the command is aborted, an empty string is returned so the capture will not error."
  (require 'org-capture)
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
              (wikinforg nil (string-trim (concat query " " suffix)))
            ((error quit) (concat prefix query))))
      (quit prefix))))

(provide 'wikinforg)

;;; wikinforg.el ends here
