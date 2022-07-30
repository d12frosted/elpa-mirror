;;; consult-recoll.el --- Recoll queries using consult  -*- lexical-binding: t; -*-

;; Author: Jose A Ortega Ruiz <jao@gnu.org>
;; Maintainer: Jose A Ortega Ruiz
;; Keywords: docs, convenience
;; Package-Version: 20220729.2332
;; Package-Commit: 204a936c5b29334a3b40042ff5047f5790a7c136
;; License: GPL-3.0-or-later
;; Version: 0.5
;; Package-Requires: ((emacs "26.1") (consult "0.18"))
;; Homepage: https://codeberg.org/jao/consult-recoll

;; Copyright (C) 2021, 2022  Jose A Ortega Ruiz

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

;; A `consult-recoll' command to perform interactive queries (including life
;; previews of documment snippets) over your Recoll
;; (https://www.lesbonscomptes.com/recoll/) index, using consult. Use
;;
;;     M-x consult-recoll
;;
;; to get started, and the corresponding customization group for ways to tweak
;; its behaviour to your needs.

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

(defcustom consult-recoll-search-flags '("-a")
  "List of flags used to perform queries via recollq."
  :type '(choice (const :tag "Query language" nil)
                 (const :tag "All terms" ("-a"))
                 (list string)))

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

(defface consult-recoll-url-face '((t :inherit link))
  "Face used to display URLs of candidates.")

(defface consult-recoll-title-face '((t :inherit italic))
  "Face used to display titles of candidates.")

(defface consult-recoll-mime-face '((t :inherit font-lock-comment-face))
  "Face used to display MIME type of candidates.")

(defvar consult-recoll-history nil "History for `consult-recoll'.")
(defvar consult-recoll--current "")

(defun consult-recoll--command (text)
  "Command used to perform queries for TEXT."
  (setq consult-recoll--current text)
  `("recollq" ,@consult-recoll-search-flags ,text))

(defconst consult-recoll--line-rx "^\\(.*?\\)\t\\[\\(.*?\\)\\]\t\\[\\(.*\\)\\]"
  "Regular expression decomposing result lines returned by recollq")

(defun consult-recoll--transformer (str)
  "Decode STR, as returned by recollq."
  (when (string-match consult-recoll--line-rx str)
    (let* ((mime (match-string 1 str))
           (url (match-string 2 str))
           (title (match-string 3 str))
           (urln (if (string-prefix-p "file://" url) (substring url 7) url))
           (cand (if consult-recoll-format-candidate
                     (funcall consult-recoll-format-candidate title urln mime)
                   (format "%s (%s)"
                           (propertize title 'face 'consult-recoll-title-face)
                           (propertize urln 'face 'consult-recoll-url-face)))))
      (propertize cand 'mime-type mime 'url urln 'title title))))

(defsubst consult-recoll--candidate-title (candidate)
  (get-text-property 0 'title candidate))

(defsubst consult-recoll--candidate-mime (candidate)
  (get-text-property 0 'mime-type candidate))

(defun consult-recoll--candidate-url (candidate)
  (get-text-property 0 'url candidate))

(defun consult-recoll--open (candidate)
  "Open file of corresponding completion CANDIDATE."
  (when candidate
    (let ((url (consult-recoll--candidate-url candidate))
          (opener (alist-get (consult-recoll--candidate-mime candidate)
                             consult-recoll-open-fns
                             (or consult-recoll-open-fn #'find-file)
                             nil 'string=)))
      (funcall opener url))))

(defvar consult-recoll--preview-buffer "*consult-recoll preview*")

(defun consult-recoll--preview (action candidate)
  "Preview search result CANDIDATE when ACTION is \\='preview."
  (cond ((or (eq action 'setup) (null candidate))
         (with-current-buffer (get-buffer-create consult-recoll--preview-buffer)
           (delete-region (point-min) (point-max))))
        ((and (eq action 'preview) candidate)
         (when-let* ((url (consult-recoll--candidate-url candidate))
                     (q (format "recollq -A -p 5 filename:%s AND %s"
                                (replace-regexp-in-string "^.+://" "" url)
                                consult-recoll--current))
                     (buff (get-buffer consult-recoll--preview-buffer)))
           (with-current-buffer buff
             (delete-region (point-min) (point-max))
             (insert (shell-command-to-string q))
             (goto-char (point-min))
             (when (re-search-forward (regexp-quote (format "[%s]" url)) nil t)
               (delete-region (point-min) (point)))
             (unless (re-search-forward "^SNIPPETS$" nil t)
               (goto-char (point-max)))
             (delete-region (point-min) (point))
             (when-let (title (consult-recoll--candidate-title candidate))
               (insert (propertize title 'face 'consult-recoll-title-face) "\n"))
             (insert (propertize url 'face 'consult-recoll-url-face) "\n")
             (insert (propertize (consult-recoll--candidate-mime candidate)
                                 'face 'consult-recoll-mime-face)
                     "\n")
             (when (re-search-forward "^/SNIPPETS$" nil t)
               (replace-match ""))
             (delete-region (point) (point-max)))
           (pop-to-buffer buff)))
        ((eq action 'exit)
         (when (get-buffer consult-recoll--preview-buffer)
           (kill-buffer consult-recoll--preview-buffer)))))

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
                 :sort nil
                 :state #'consult-recoll--preview
                 :initial (consult--async-split-initial initial)
                 :history '(:input consult-recoll-history)
                 :category 'recoll-result))

;;;###autoload
(defun consult-recoll (ask)
  "Consult recoll's local index.
With prefix argument ASK, the user is prompted for an initial query string."
  (interactive "P")
  (let ((initial (when ask
                   (if (stringp ask) ask (read-string "Initial query: ")))))
    (consult-recoll--open (consult-recoll--search initial))))

(provide 'consult-recoll)
;;; consult-recoll.el ends here
