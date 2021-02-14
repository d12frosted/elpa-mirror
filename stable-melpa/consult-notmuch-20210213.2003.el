;;; consult-notmuch.el --- Notmuch search using consult  -*- lexical-binding: t; -*-

;; Author: Jose A Ortega Ruiz <jao@gnu.org>
;; Maintainer: Jose A Ortega Ruiz
;; Keywords: mail
;; Package-Version: 20210213.2003
;; Package-Commit: 0bcdad24c8cc4ac530fcafd90ab728ed5dfbf0ed
;; License: GPL-3.0-or-later
;; Version: 0.1
;; Package-Requires: ((emacs "26.1") (consult "0.5") (notmuch "0.21"))
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

;; This elisp file is automatically generated from its literate
;; counterpart at
;; https://codeberg.org/jao/consult-notmuch/src/branch/main/readme.org

;;; Code:

(require 'consult)
(require 'notmuch)

(defgroup consult-notmuch nil
  "Options for consult-notmuch."
  :group 'notmuch)

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
(defcustom consult-notmuch-command "notmuch search *ARG*"
  "Command to perform notmuch search."
  :type 'string)

(defun consult-notmuch--search (&optional initial)
  "Perform an asynchronous notmuch search via `consult--read'.
If given, use INITIAL as the starting point of the query."
  (consult--read (consult--async-command consult-notmuch-command
                   (consult--async-map #'consult-notmuch--transformer))
                 :prompt "Notmuch search: "
                 :require-match t
                 :initial (concat consult-async-default-split initial)
                 :history 'consult-notmuch-history
                 :state #'consult-notmuch--preview
                 :category 'notmuch-result))

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
                   (string-trim (nth 1 (split-string mid "[];]"))) 20))
           (subject (truncate-string-to-width
                     (string-trim (nth 1 (split-string mid "[;]")))
                     (- (frame-width) 32))))
      (format "%s %s\t%10s\t%20s\t%s"
              (propertize thread-id 'invisible t)
              (propertize date 'face 'consult-notmuch-date-face)
              (propertize count 'face 'consult-notmuch-count-face)
              (propertize auths 'face 'consult-notmuch-authors-face)
              (propertize subject 'face 'consult-notmuch-subject-face)))))

(defvar consult-notmuch--buffer-name "*consult-notmuch-show*"
  "Name of preview and result buffers.")

(defun consult-notmuch--close-preview ()
  "Name says it all (and checkdoc is a bit silly, insisting on this)."
  (when (get-buffer consult-notmuch--buffer-name)
    (kill-buffer consult-notmuch--buffer-name)))


(defun consult-notmuch--preview (thread _restore)
  "Open resulting THREAD in ‘notmuch-show’ view, in a preview buffer."
  (consult-notmuch--close-preview)
  (let ((thread-id (car (split-string thread "\\ +"))))
    (notmuch-show thread-id nil nil nil consult-notmuch--buffer-name)))


(defun consult-notmuch--show (thread)
  "Open resulting THREAD in ‘notmuch-show’ view."
  (consult-notmuch--close-preview)
  (let ((title (concat consult-notmuch--buffer-name (substring thread 24)))
        (thread-id (car (split-string thread "\\ +"))))
    (notmuch-show thread-id nil nil nil title)))


(defun consult-notmuch--tree (thread)
  "Open resulting THREAD in ‘notmuch-tree’."
  (consult-notmuch--close-preview)
  (let ((thread-id (car (split-string thread "\\ +"))))
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

(provide 'consult-notmuch)
;;; consult-notmuch.el ends here
