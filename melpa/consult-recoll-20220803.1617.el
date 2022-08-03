;;; consult-recoll.el --- Recoll queries using consult  -*- lexical-binding: t; -*-

;; Author: Jose A Ortega Ruiz <jao@gnu.org>
;; Maintainer: Jose A Ortega Ruiz
;; Keywords: docs, convenience
;; Package-Version: 20220803.1617
;; Package-Commit: 2e70eebee41065866cb3f024f2b86ef2caa6d831
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
  "Default function used to open candidate URLs.
It receives a single argument, the full path to the file to open.
See also `consult-recoll-open-fns'"
  :type 'function)

(defcustom consult-recoll-open-fns ()
  "Alist mapping mime types to functions to open a selected candidate."
  :type '(alist :key-type string :value-type function))

(defcustom consult-recoll-group-by-mime t
  "When set, list search results grouped by mime type."
  :type 'boolean)

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
(defvar consult-recoll--current nil)

(defun consult-recoll--command (text)
  "Command used to perform queries for TEXT."
  `("recollq" "-A" "-p" "5" ,@consult-recoll-search-flags ,text))

(defconst consult-recoll--line-rx "^\\(.*?\\)\t\\[\\(.*?\\)\\]\t\\[\\(.*\\)\\]"
  "Regular expression decomposing result lines returned by recollq")

(defun consult-recoll--format (title urln mime)
  (if consult-recoll-format-candidate
      (funcall consult-recoll-format-candidate title urln mime)
    (format "%s (%s)"
            (propertize title 'face 'consult-recoll-title-face)
            (propertize urln 'face 'consult-recoll-url-face))))

(defsubst consult-recoll--candidate-title (candidate)
  (get-text-property 0 'title candidate))

(defsubst consult-recoll--candidate-mime (candidate)
  (get-text-property 0 'mime-type candidate))

(defun consult-recoll--candidate-url (candidate)
  (get-text-property 0 'url candidate))

(defun consult-recoll--snippets (&optional candidate)
  (get-text-property 0 'snippets (or candidate consult-recoll--current)))

(defun consult-recoll--open (candidate)
  "Open file of corresponding completion CANDIDATE."
  (when candidate
    (let ((url (consult-recoll--candidate-url candidate))
          (opener (alist-get (consult-recoll--candidate-mime candidate)
                             consult-recoll-open-fns
                             (or consult-recoll-open-fn #'find-file)
                             nil 'string=)))
      (funcall opener url))))

(defun consult-recoll--transformer (str)
  "Decode STR, as returned by recollq."
  (cond ((string-match consult-recoll--line-rx str)
         (let* ((mime (match-string 1 str))
                (url (match-string 2 str))
                (title (match-string 3 str))
                (urln (if (string-prefix-p "file://" url) (substring url 7) url))
                (cand (consult-recoll--format title url mime))
                (cand (propertize cand 'mime-type mime 'url urln 'title title)))
           (setq consult-recoll--current cand)
           nil))
        ((string= "/SNIPPETS" str) consult-recoll--current)
        ((string= "SNIPPETS" str) nil)
        (consult-recoll--current
         (let ((snippets (concat (consult-recoll--snippets) "\n" str)))
           (setq consult-recoll--current
                 (propertize consult-recoll--current 'snippets snippets)))
         nil)))

(defvar consult-recoll--preview-buffer "*consult-recoll preview*")

(defun consult-recoll--preview (action candidate)
  "Preview search result CANDIDATE when ACTION is \\='preview."
  (cond ((or (eq action 'setup) (null candidate))
         (with-current-buffer (get-buffer-create consult-recoll--preview-buffer)
           (setq-local cursor-in-non-selected-windows nil)
           (delete-region (point-min) (point-max))))
        ((and (eq action 'preview) candidate)
         (when-let* ((url (consult-recoll--candidate-url candidate))
                     (buff (get-buffer consult-recoll--preview-buffer)))
           (with-current-buffer buff
             (delete-region (point-min) (point-max))
             (when-let (title (consult-recoll--candidate-title candidate))
               (insert (propertize title 'face 'consult-recoll-title-face) "\n"))
             (insert (propertize url 'face 'consult-recoll-url-face) "\n")
             (insert (propertize (consult-recoll--candidate-mime candidate)
                                 'face 'consult-recoll-mime-face))
             (when-let (s (consult-recoll--snippets candidate)) (insert "\n" s))
             (goto-char (point-min)))
           (pop-to-buffer buff)))
        ((eq action 'exit)
         (when (get-buffer consult-recoll--preview-buffer)
           (kill-buffer consult-recoll--preview-buffer)))))

(defun consult-recoll--group (candidate transform)
  "If TRANSFORM return candidate, othewise extract mime-type."
  (if transform candidate (consult-recoll--candidate-mime candidate)))

(defun consult-recoll--search (&optional initial)
  "Perform an asynchronous recoll search via `consult--read'.
If given, use INITIAL as the starting point of the query."
  (setq consult-recoll--current nil)
  (consult--read (consult--async-command
                     #'consult-recoll--command
                   (consult--async-filter #'identity)
                   (consult--async-map #'consult-recoll--transformer))
                 :prompt consult-recoll-prompt
                 :require-match t
                 :lookup #'consult--lookup-member
                 :sort nil
                 :state #'consult-recoll--preview
                 :group (and consult-recoll-group-by-mime
                             #'consult-recoll--group)
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
