;;; wikinforg.el --- Org-mode wikinfo integration  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Nicholas Vollmer

;; Author: Nicholas Vollmer <progfolio@protonmail.com>
;; URL: https://github.com/progfolio/wikinforg
;; Package-Version: 20210711.302
;; Package-Commit: 31cf4a52990caa3f928b847ec25a5412836552bd
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
                 (const :tag "plain text" plain)))

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

(defvar wikinforg-mode-map (make-sparse-keymap) "Keymap for wikinforg mode.")
(define-key wikinforg-mode-map (kbd "q") 'bury-buffer)

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
    (switch-to-buffer (current-buffer))))

;;;; Commands
;;;###autoload
(defun wikinforg (&optional arg query predicate)
  "Return Org entry from `wikinfo'.
QUERY and PREDICATE are passed to `wikinfo'.
If ARG is equivalent to `\\[universal-argument]', display the entry in a buffer."
  (interactive "P")
  (let* ((query (string-trim
                 (wikinforg--format-query (or query (read-string "Wikinforg: ")))))
         (wikinfo-base-url (format "https://%s.wikipedia.org"
                                   wikinforg-wikipedia-edition-code))
         (info (wikinfo query predicate))
         (filtered (seq-filter (lambda (el)
                                 (and (keywordp el) (not (member el '(:wikinfo)))))
                               info))
         (id (wikinfo--plist-path info :wikinfo :id))
         (url (format "%s?curid=%d" wikinfo-base-url id))
         (title (or (wikinfo--plist-path info :wikinfo :title) query))
         (property-drawer
          `( property-drawer nil
             ,@(mapcar (lambda (keyword)
                         (list 'node-property
                               (list :key (substring (symbol-name keyword) 1)
                                     :value (format "%s" (plist-get info keyword)))))
                       filtered)
             ,(list 'node-property (list :key "wikinfo-id" :value id))
             ,(list 'node-property (list :key "URL" :value url))))
         (thumbnail (when wikinforg-include-thumbnail
                      (when-let ((url (plist-get info :thumbnail))
                                 (dir (file-truename
                                       (if (equal arg '(4))
                                           (let ((d (expand-file-name "wikinforg/" (temporary-file-directory))))
                                             (unless (file-exists-p d) (make-directory d 'parents))
                                             d)
                                         (or wikinforg-thumbnail-directory "./wikinforg/thumbnails"))))
                                 (name (concat (replace-regexp-in-string ".*/" "" url)))
                                 (path (expand-file-name name dir)))
                        (unless (file-exists-p dir) (make-directory dir 'parents))
                        (with-temp-buffer (url-insert-file-contents url) (write-file path))
                        `(link (:type "file" :path ,path :format bracket :raw-link ,path)))))
         (paragraph `(paragraph nil
                                ,(when wikinforg-include-thumbnail
                                   (list "\n" thumbnail "\n\n"))
                                ,(when wikinforg-include-extract
                                   (funcall (or wikinforg-extract-format-function
                                                #'identity)
                                            (wikinfo--plist-path info :wikinfo :extract)))))
         (headline `(headline ( :level 1 :title ,title) ,property-drawer ,paragraph))
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
          ('(4) (wikinforg--display title result))
          (_ result))
      ;;save-excursion doesn't work here?
      (let ((p (point)))
        (if (derived-mode-p 'org-mode)
            (org-paste-subtree nil result)
          (insert (with-temp-buffer
                    (org-mode)
                    (org-paste-subtree nil result)
                    (buffer-string))))
        (goto-char p)
        (run-hooks 'wikinforg-post-insert-hook)))))

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
If the command is aborted, an empty string is returned so the capture will not error."
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
              (wikinforg nil (string-trim (concat query " " suffix)))
            ((error quit) (concat prefix query)))))))

(provide 'wikinforg)

;;; wikinforg.el ends here
