;;; insert-char-preview.el --- Insert Unicode char -*- lexical-binding: t -*-

;; Author: Matsievskiy S.V.
;; Maintainer: Matsievskiy S.V.
;; Version: 0.1
;; Package-Version: 20201023.2108
;; Package-Commit: 8f13262ebcb3f271f1d188584d04ca6d87214111
;; Package-Requires: ((emacs "24.1"))
;; Homepage: https://gitlab.com/matsievskiysv/insert-char-preview
;; Keywords: convenience


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; Insert Unicode char similar to `insert-char` command, but with
;; character preview in completion prompt.

;;; Code:

(defgroup insert-char-preview nil
  "Insert Unicode char interactively with preview"
  :group  'i18n
  :tag    "Insert Char Preview"
  :prefix "insert-char-preview-"
  :link   '(url-link :tag "GitLab" "https://gitlab.com/matsievskiysv/insert-char-preview"))

(defcustom insert-char-preview-format "%x(%s) %s"
  "Format string.  Arguments are: number, char, name."
  :tag  "Preview format"
  :type 'string)

(defvar insert-char-preview--table
  (let* ((orig-names (ucs-names))
         (h (make-hash-table :test 'equal :size (hash-table-size orig-names))))
    (maphash (lambda (k v)
               (puthash (format insert-char-preview-format
                                v (string v) k)
                        v h))
             orig-names)
    h)
  "Character hash table.")

;;;###autoload
(defun insert-char-preview (COUNT CHARACTER)
  "Insert COUNT copies of CHARACTER.
Similar to `insert-char` in interactive mode, but with char preview."
  (interactive (list current-prefix-arg
                     (completing-read "Insert character: "
                                      insert-char-preview--table)))
  (insert-char (gethash CHARACTER insert-char-preview--table ??) COUNT))

(provide 'insert-char-preview)

;;; insert-char-preview.el ends here
