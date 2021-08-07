;;; consult-recoll.el --- Recoll queries using consult  -*- lexical-binding: t; -*-

;; Author: Jose A Ortega Ruiz <jao@gnu.org>
;; Maintainer: Jose A Ortega Ruiz
;; Keywords: docs, convenience
;; Package-Version: 20210807.1613
;; Package-Commit: fe7a09b99d1497a30e11a2f86b6415adde00788a
;; License: GPL-3.0-or-later
;; Version: 0.2
;; Package-Requires: ((emacs "26.1") (consult "0.9"))
;; Homepage: https://codeberg.org/jao/consult-recoll

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

;; A `consult-recoll' command to perform simple interactive queries
;; over your Recoll (https://www.lesbonscomptes.com/recoll/) index.
;; See the corresponding customization group for ways to tweak its
;; behaviour to your needs.

;;; Code:

(require 'seq)
(require 'subr-x)
(require 'consult)

(defgroup consult-recoll nil
  "Options for consult recoll."
  :group 'consult)

(defcustom consult-recoll-prompt "Recoll search: "
  "Prompt used by `consult-recoll'."
  :type 'string)

(defcustom consult-recoll-open-fn #'find-file
  "Default function used to open candidate URL.
It receives a single argument, the full path to the file to open.
See also `consult-recoll-open-fns'"
  :type 'function)

(defcustom consult-recoll-open-fns ()
  "Alist mapping mime types to functions to open a selected candidate."
  :type '(alist :key-type string :value-type function))

(defcustom consult-recoll-format-candidate nil
  "A function taking title, path and mime type, and formatting them for display.
Set to nil to use the default 'title (path)' format."
  :type '(choice (const nil) function))

(defface consult-recoll-url-face '((t :inherit default))
  "Face used to display URLs of candidates.")

(defface consult-recoll-title-face '((t :inherit italic))
  "Face used to display titles of candidates.")

(defvar consult-recoll-history nil "History for `consult-recoll'.")

(defun consult-recoll--command (text)
  "Command used to perform queries for TEXT."
  `("recollq" "-a" "-F" "url title mtype" ,text))

(defun consult-recoll--transformer (str)
  "Decode STR, as returned by recollq."
  (unless (string-match-p "^\\(Recoll query:\\|[0-9]+ results\\| *$\\)" str)
    (let* ((cmps (split-string str " "))
           (fields (seq-map #'base64-decode-string cmps))
           (url (car fields))
           (title (cadr fields))
           (title (if (string= "" title) (file-name-base url) title))
           (urln (if (string-prefix-p "file://" url) (substring url 7) url))
           (mime (nth 2 fields))
           (cand (if consult-recoll-format-candidate
                     (funcall consult-recoll-format-candidate title urln mime)
                   (format "%s (%s)"
                           (propertize title 'face 'consult-recoll-title-face)
                           (propertize urln 'face 'consult-recoll-url-face)))))
      (propertize cand 'mime-type mime 'url urln))))

(defun consult-recoll--open (candidate)
  "Open file of corresponding completion CANDIDATE."
  (when candidate
    (let ((url (get-text-property 0 'url candidate))
          (opener (alist-get (get-text-property 0 'mime-type candidate)
                             consult-recoll-open-fns
                             (or consult-recoll-open-fn #'find-file)
                             nil 'string=)))
      (funcall opener url))))

(defun consult-recoll--search (&optional initial)
  "Perform an asynchronous recoll search via `consult--read'.
If given, use INITIAL as the starting point of the query."
  (consult--read (consult--async-command
                     #'consult-recoll--command
                   (consult--async-filter #'identity)
                   (consult--async-map #'consult-recoll--transformer))
                 :prompt consult-recoll-prompt
                 :require-match t
                 :lookup #'consult--lookup-member
                 :initial (consult--async-split-initial initial)
                 :history 'consult-recoll-history
                 :category 'recoll-result))

;;;###autoload
(defun consult-recoll ()
  "Consult recoll's local index."
  (interactive)
  (consult-recoll--open (consult-recoll--search)))

(provide 'consult-recoll)
;;; consult-recoll.el ends here
