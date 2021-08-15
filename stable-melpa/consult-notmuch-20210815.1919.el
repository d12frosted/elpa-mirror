;;; consult-notmuch.el --- Notmuch search using consult  -*- lexical-binding: t; -*-

;; Author: Jose A Ortega Ruiz <jao@gnu.org>
;; Maintainer: Jose A Ortega Ruiz
;; Keywords: mail
;; Package-Version: 20210815.1919
;; Package-Commit: 5e5f42faaae3e0d372f103b9de276d1f7f1c18e0
;; License: GPL-3.0-or-later
;; Version: 0.4
;; Package-Requires: ((emacs "26.1") (consult "0.9") (notmuch "0.31"))
;; Homepage: https://codeberg.org/jao/consult-notmuch


;; Copyright (C) 2021  Jose A Ortega Ruiz

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides two commands using consult to query notmuch
;; emails and present results either as single emails
;; (`consult-notmuch') or full trees (`consult-notmuch-tree').
;;
;; The package also defines a narrowing source for `consult-buffer',
;; which can be activated with
;;
;;   (add-to-list 'consult-buffer-sources 'consult-notmuch-buffer-source)

;; This elisp file is automatically generated from its literate
;; counterpart at
;; https://codeberg.org/jao/consult-notmuch/src/branch/main/readme.org

;;; Code:

(require 'consult)
(require 'notmuch)

(defgroup consult-notmuch nil
  "Options for consult-notmuch."
  :group 'consult)

(defface consult-notmuch-date-face
  '((t :inherit notmuch-search-date))
  "Face used in matching messages for the date field.")

(defface consult-notmuch-count-face
  '((t :inherit notmuch-search-count))
  "Face used in matching messages for the mail count field.")

(defface consult-notmuch-authors-face
  '((t :inherit notmuch-search-matching-authors))
  "Face used in matching messages for the authors field.")

(defface consult-notmuch-subject-face
  '((t :inherit notmuch-search-subject))
  "Face used in matching messages for the subject field.")


(defcustom consult-notmuch-authors-width 20
  "Maximum width of the authors column in search results."
  :type 'integer)

(defcustom consult-notmuch-counts-width 10
  "Minimum width of the counts column in search results."
  :type 'integer)

(defcustom consult-notmuch-show-single-message t
  "Show only the matching message or the whole thread in (pre)views."
  :type 'boolean)

(defun consult-notmuch--command (input)
  "Construct a search command for emails containing INPUT."
  `("notmuch" "search" ,input))

(defun consult-notmuch--search (&optional initial)
  "Perform an asynchronous notmuch search via `consult--read'.
If given, use INITIAL as the starting point of the query."
  (consult--read (consult--async-command
                     #'consult-notmuch--command
                   (consult--async-map #'consult-notmuch--transformer))
                 :prompt "Notmuch search: "
                 :require-match t
                 :initial (consult--async-split-initial initial)
                 :history '(:input consult-notmuch-history)
                 :state #'consult-notmuch--preview
                 :lookup #'consult--lookup-member
                 :category 'notmuch-result
                 :sort nil))

(defvar consult-notmuch-history nil
  "History for `consult-notmuch'.")

(defun consult-notmuch--transformer (str)
  "Transform STR to notmuch display style."
  (when (string-match "thread:" str)
    (let* ((thread-id (car (split-string str "\\ +")))
           (date (substring str 24 37))
           (mid (substring str 24))
           (c0 (string-match "[[]" mid))
           (c1 (string-match "[]]" mid))
           (count (substring mid c0 (1+ c1)))
           (auths (truncate-string-to-width
                   (string-trim (nth 1 (split-string mid "[];]")))
                   consult-notmuch-authors-width))
           (subject (truncate-string-to-width
                     (string-trim (nth 1 (split-string mid "[;]")))
                     (- (frame-width)
                        2
                        consult-notmuch-counts-width
                        consult-notmuch-authors-width)))
           (fmt (format "%%s\t%%%ds\t%%%ds\t%%s"
                        consult-notmuch-counts-width
                        consult-notmuch-authors-width)))
      (propertize
       (format fmt
               (propertize date 'face 'consult-notmuch-date-face)
               (propertize count 'face 'consult-notmuch-count-face)
               (propertize auths 'face 'consult-notmuch-authors-face)
               (propertize subject 'face 'consult-notmuch-subject-face))
       'thread-id thread-id))))

(defun consult-notmuch--thread-id (candidate)
  "Recover the thread id for the given CANDIDATE string."
  (when candidate (get-text-property 0 'thread-id candidate)))


(defvar consult-notmuch--buffer-name "*consult-notmuch*"
  "Name of preview and result buffers.")

(defun consult-notmuch--close-preview ()
  "Name says it all (and checkdoc is a bit silly, insisting on this)."
  (when (get-buffer consult-notmuch--buffer-name)
    (kill-buffer consult-notmuch--buffer-name)))


(defun consult-notmuch--preview (candidate _restore)
  "Open resulting CANDIDATE in ‘notmuch-show’ view, in a preview buffer."
  (consult-notmuch--close-preview)
  (when-let ((thread-id (consult-notmuch--thread-id candidate)))
    (let ((notmuch-show-only-matching-messages
           consult-notmuch-show-single-message))
      (notmuch-show thread-id nil nil nil consult-notmuch--buffer-name))))


(defun consult-notmuch--show (candidate)
  "Open resulting CANDIDATE in ‘notmuch-show’ view."
  (consult-notmuch--close-preview)
  (when-let ((thread-id (consult-notmuch--thread-id candidate)))
    (let* ((notmuch-show-only-matching-messages
            consult-notmuch-show-single-message)
           (subject (car (last (split-string candidate "\t"))))
           (title (concat consult-notmuch--buffer-name " " subject)))
      (notmuch-show thread-id nil nil nil title))))


(defun consult-notmuch--tree (candidate)
  "Open resulting CANDIDATE in ‘notmuch-tree’."
  (consult-notmuch--close-preview)
  (when-let ((thread-id (consult-notmuch--thread-id candidate)))
    (notmuch-tree thread-id nil nil)))


;;;###autoload
(defun consult-notmuch (&optional initial)
  "Search for your email in notmuch, showing single messages.
If given, use INITIAL as the starting point of the query."
  (interactive)
  (consult-notmuch--show (consult-notmuch--search initial)))

;;;###autoload
(defun consult-notmuch-tree (&optional initial)
  "Search for your email in notmuch, showing full candidate tree.
If given, use INITIAL as the starting point of the query."
  (interactive)
  (consult-notmuch--tree (consult-notmuch--search initial)))

(defun consult-notmuch--interesting-buffers ()
  "Returns a list of names of buffers with interesting notmuch data."
  (consult--buffer-query
   :as (lambda (buf)
         (when (notmuch-interesting-buffer buf)
           (buffer-name buf)))))

;;;###autoload
(defvar consult-notmuch-buffer-source
  '(:name "Notmuch Buffer"
    :narrow (?n . "Notmuch")
    :hidden t
    :category buffer
    :face consult-buffer
    :history buffer-name-history
    :state consult--buffer-state
    :items consult-notmuch--interesting-buffers)
  "Notmuch buffer candidate source for `consult-buffer'.")

(provide 'consult-notmuch)
;;; consult-notmuch.el ends here
