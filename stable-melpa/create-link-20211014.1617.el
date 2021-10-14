;;; create-link.el --- Smart format link generator

;; Copyright (C) 2021 Kijima Daigo
;; Created date 2021-05-07 00:30 +0900

;; Author: Kijima Daigo <norimaking777@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20211014.1617
;; Package-Commit: e765b1067ced891a90ba0478af7fe675cff9b713
;; Package-Requires: ((emacs "25.1"))
;; Keywords: link format browser convenience
;; URL: https://github.com/kijimaD/create-link

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; Create formatted url depending on the context.
;; M-x create-link
;; M-x create-link-manual

;;; Code:

(require 'cl-lib)
(require 'eww)
(require 'thingatpt)

(defvar w3m-current-url)
(declare-function w3m-current-title "ext:w3m-util")
(declare-function forge-current-issue "ext:forge-issue")
(declare-function forge-current-pullreq "ext:forge-pullreq")
(declare-function forge-get-url "ext:forge-repo")
(eval-when-compile (cl-pushnew 'title eieio--known-slot-names))

(defgroup create-link nil
  "Generate a formatted current page link."
  :group 'convenience
  :prefix "create-link-")

(defcustom create-link-default-format 'create-link-format-html
  "Default link format."
  :group 'create-link
  :type '(choice (const :tag "HTML" create-link-format-html)
                 (const :tag "Markdown" create-link-format-markdown)
                 (const :tag "Org"  create-link-format-org)
                 (const :tag "DokuWiki" create-link-format-doku-wiki)
                 (const :tag "MediaWiki" create-link-format-media-wiki)
                 (const :tag "LaTeX" create-link-format-latex)))

;; Format keywords:
;; %url% - (e.g. https://www.google.com/)
;; %title% - (e.g. Google)
(defcustom create-link-format-html "<a href='%url%'>%title%</a>"
  "HTML link format."
  :group 'create-link
  :type 'string)

(defcustom create-link-format-markdown "[%title%](%url%)"
  "Markdown link format."
  :group 'create-link
  :type 'string)

(defcustom create-link-format-org "[[%url%][%title%]]"
  "Org-mode link format."
  :group 'create-link
  :type 'string)

(defcustom create-link-format-doku-wiki "[[%url%|%title%]]"
  "DokuWiki link format."
  :group 'create-link
  :type 'string)

(defcustom create-link-format-media-wiki "[%url% %title%]"
  "MediaWiki link format."
  :group 'create-link
  :type 'string)

(defcustom create-link-format-latex "\\href{%url%}{%title%}"
  "Latex link format."
  :group 'create-link
  :type 'string)

(defconst create-link-formats
  '((create-link-format-html)
    (create-link-format-markdown)
    (create-link-format-org)
    (create-link-format-doku-wiki)
    (create-link-format-media-wiki)
    (create-link-format-latex))
  "All format list.  Use for completion.")

(defconst create-link-html-title-regexp
  "<title>\\(.*\\)</title>"
  "Regular expression to scrape a page title.")

(defconst create-link-html-regexp
  "<a.*?href=[\\'\\\"]\\(?1:.+\\)[\\'\\\"].*?>\\(?2:.+\\)</a>"
  "Regular expression for HTML link.
Group 1 matches the link.
Group 2 matches the title.")

(defconst create-link-markdown-regexp
  "\\[\\(?1:.*\\)\\](\\(?2:.*\\))"
  "Regular expression for Markdown link.
Group 1 matches the title.
Group 2 matches the link.")

(defconst create-link-org-regexp
  "\\[\\[\\(?1:.*?\\)\\]\\[\\(?2:.*?\\)\\]"
  "Regular expression for Org link.
Group 1 matches the link.
Group 2 matches the title.")

(defconst create-link-doku-wiki-regexp
  "\\[\\[\\(?1:.*?\\)\s?|\s?\\(?2:.*?\\)\\]\\]"
  "Regular expression for DokuWiki external link.
Group 1 matches the link.
Group 2 matches the title.")

(defconst create-link-media-wiki-regexp
  "\\[\\(?1:.*?\\)\s\s?\\(?2:.*?\\)\\]"
  "Regular expression for MediaWiki external link.
Group 1 matches the link.
Group 2 matches the title.
It is problematic.")

(defconst create-link-latex-regexp
  "\\\\href{\\(run:\\)?\\(?1:.*?\\)}{\\(?2:.*?\\)}"
  "Regular expression for LaTeX link.
Group 1 matches the link.
Group 2 matches the title.")

(defun create-link-absolute-linkp (url)
  "Return t if URL is absolute url."
  (string-match-p "^http[s]?://" url))

(defun create-link-relative-linkp (url)
  "Return t if URL is relative url."
  (not (create-link-absolute-linkp url)))

(defun create-link-format-html-rule (dict)
  "HTML specific rule (Unimplemented).
DICT is alist with url and title."
  dict)

(defun create-link-format-markdown-rule (dict)
  "Markdown specific rule (Unimplemented).
DICT is alist with url and title."
  dict)

(defun create-link-format-org-rule (dict)
  "Org specific rule (Unimplemented).
DICT is alist with url and title."
  dict)

(defun create-link-format-doku-wiki-rule (dict)
  "DokuWiki specific rule (Unimplemented).
DICT is alist with url and title."
  dict)

(defun create-link-format-media-wiki-rule (dict)
  "MediaWiki specific rule (Unimplemented).
DICT is alist with url and title."
  dict)

(defun create-link-format-latex-rule (dict)
  "LaTeX specific rule.
DICT is alist with url and title."
  (cond ((create-link-relative-linkp (cdr (assoc 'url dict)))
         `((url . ,(concat "run:" (cdr (assoc 'url dict))))
           (title . ,(cdr (assoc 'title dict)))))
        (t
         dict)))

(defun create-link-replace-dictionary ()
  "Convert format keyword to corresponding one.
If there is a selected region, fill title with the region.
If point is on URL, fill title with scraped one."
  (cond ((region-active-p)
         (deactivate-mark t)
         `((url . ,(cdr (assoc 'url (create-link-get-from-buffer))))
           (title . ,(buffer-substring (region-beginning) (region-end)))))
        ((thing-at-point-looking-at create-link-html-regexp)
         `((url . ,(match-string 1))
           (title . ,(match-string 2))))
        ((thing-at-point-looking-at create-link-markdown-regexp)
         `((url . ,(match-string 2))
           (title . ,(match-string 1))))
        ((thing-at-point-looking-at create-link-org-regexp)
         `((url . ,(match-string 1))
           (title . ,(match-string 2))))
        ((thing-at-point-looking-at create-link-doku-wiki-regexp)
         `((url . ,(match-string 1))
           (title . ,(match-string 2))))
        ((thing-at-point-looking-at create-link-media-wiki-regexp)
         `((url . ,(match-string 1))
           (title . ,(match-string 2))))
        ((thing-at-point-looking-at create-link-latex-regexp)
         `((url . ,(match-string 1))
           (title . ,(match-string 2))))
        ((thing-at-point-url-at-point)
         `((url . ,(thing-at-point-url-at-point))
           (title . ,(create-link-scrape-title (thing-at-point-url-at-point)))))
        (t
         (create-link-get-from-buffer))))

(defun create-link-get-from-buffer ()
  "Get keyword information on each buffer."
  (cond ((eq major-mode 'eww-mode)
         `((title . ,(plist-get eww-data :title))
           (url . ,(eww-current-url))))
        ((eq major-mode 'w3m-mode)
         `((title . ,(w3m-current-title))
           (url . ,w3m-current-url)))
        ((and (eq major-mode 'magit-status-mode) (forge-current-issue))
         `((url . ,(forge-get-url (forge-current-issue)))
           (title . ,(concat (oref (forge-current-issue) title)))))
        ((and (eq major-mode 'magit-status-mode) (forge-current-pullreq))
         `((url . ,(forge-get-url (forge-current-pullreq)))
           (title . ,(concat (oref (forge-current-pullreq) title)))))
        ((buffer-file-name)
         `((title . ,(buffer-name))
           (url . ,(buffer-file-name))))
        (t
         (error "Can't create link!"))))

(defun create-link-scrape-title (url)
  "Scraping page title from URL."
  (let* ((buffer (url-retrieve-synchronously url))
         (contents (with-current-buffer buffer
                     (buffer-substring (point-min) (point-max))))
         (title))
    (string-match create-link-html-title-regexp contents)
    (setq title (match-string 1 contents))
    (kill-buffer buffer)
    title))

(defun create-link-format-rule (format)
  "Get the symbol for an format rule function for a FORMAT."
  (intern (concat (symbol-name format) "-rule")))

(defun create-link-exec-replace (dict format)
  "Fill FORMAT string with DICT elements."
  (seq-reduce
   (lambda (string regexp-replacement-pair)
     (replace-regexp-in-string
      (concat "%" (symbol-name (car regexp-replacement-pair)) "%")
      (cdr regexp-replacement-pair)
      string))
   dict
   (symbol-value format)))

(defun create-link-make-format (&optional format)
  "Make format link with FORMAT(optional).
If FORMAT is not specified, use `create-link-default-format'"
  (let ((format (if format format create-link-default-format)))
    (create-link-exec-replace (funcall (create-link-format-rule format)
                                       (create-link-replace-dictionary))
                              format)))

;;;###autoload
(defun create-link-manual ()
  "Manually select a format and generate a link.
Selecting format version of function `create-link'."
  (interactive)
  (create-link
   (intern
    (completing-read "Format: " create-link-formats nil t nil))))

;;;###autoload
(defun create-link (&optional format)
  "Create format link.
If an optional FORMAT is specified,
it will be generated in that format."
  (interactive)
  (message "Copied! %s" (create-link-make-format format))
  (kill-new (create-link-make-format format)))

(provide 'create-link)

;;; create-link.el ends here
