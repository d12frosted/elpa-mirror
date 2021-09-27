;;; manage-minor-mode-table.el --- Manage minor-modes in table  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Shen, Jen-Chieh
;; Created date 2020-02-02 22:50:10

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Manage minor-modes in table
;; Keyword: tools minor-mode manage
;; Version: 0.1.3
;; Package-Version: 20200717.809
;; Package-Commit: 22a00d919d56ae7b3c3bf3090cafacffaeb50d7e
;; Package-Requires: ((emacs "25.1") (manage-minor-mode "1.1"))
;; URL: https://github.com/jcs-elpa/manage-minor-mode-table

;; This file is NOT part of GNU Emacs.

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
;;
;; Manage minor-modes in table.
;;

;;; Code:

(require 'manage-minor-mode)

(defconst manage-minor-mode-table--format
  (vector (list "CD" 3 t)  ; Changed
          (list "Status" 7 t)
          (list "Name" 40 t))
  "Format to assign to `tabulated-list-format' variable.")

(defface manage-minor-mode-table-hl-face
  '((t :inherit manage-minor-mode-face-active :background "#333333"))
  "Face for highlighting the keyword `buffer-name' and `major-mode'."
  :group 'manage-minor-mode)

(defface manage-minor-mode-table-edit-face
  '((t :foreground "green"))
  "Face for edited face."
  :group 'manage-minor-mode)

(defvar manage-minor-mode-table--record-buffer-name ""
  "Record down the buffer name.")

(defvar manage-minor-mode-table--record-major-mode ""
  "Record down the `major-mode'.")

(defvar manage-minor-mode-table--on-word
  (propertize "On" 'face 'manage-minor-mode-face-active)
  "On word with text properties.")

(defvar manage-minor-mode-table--off-word
  (propertize "Off" 'face 'manage-minor-mode-face-inactive)
  "Off word with text properties.")

(defvar manage-minor-mode-table-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") 'manage-minor-mode-table--toggle)
    (define-key map (kbd "<mouse-1>") 'manage-minor-mode-table--toggle)
    map)
  "Keymap for `manage-minor-mode-table-mode'.")

;;; Core

(defun manage-minor-mode-table--toggle ()
  "Toggle minor mode on line."
  (interactive)
  (let* ((id (tabulated-list-get-id)) (entry (tabulated-list-get-entry))
         (status (aref entry 1)) (is-on (string= "On" status))
         (turn-flag (if is-on -1 1))
         (turn-word (if is-on manage-minor-mode-table--off-word manage-minor-mode-table--on-word))
         (mm (aref entry 2)) (mm-name (intern mm)))
    (if (not (arrayp entry))
        (user-error "[ERROR] Can't toggle minor mode when no entry on current line")
      (if (not (get-buffer manage-minor-mode-table--record-buffer-name))
          (progn
            (kill-this-buffer)
            (user-error "[WARNING] Managing minor-mode buffer doesn't exists, kill this buffer"))
        (with-current-buffer manage-minor-mode-table--record-buffer-name
          (funcall-interactively mm-name turn-flag))
        (tabulated-list-delete-entry)
        (tabulated-list-print-entry id
                                    (vector (propertize
                                             "*"
                                             'face 'manage-minor-mode-table-edit-face)
                                            turn-word
                                            mm))
        (forward-line -1)))))

(defun manage-minor-mode-table--get-entries ()
  "Get all the entries for table."
  (let ((entries '()) (id-count 0)
        (active-list (manage-minor-mode--active-list))
        (inactive-list (manage-minor-mode--inactive-list)))
    ;; For ACTIVE minor-mode.
    (dolist (mm active-list)
      (let ((new-entry '()) (new-entry-value '()))
        (push (symbol-name mm) new-entry-value)    ; Name
        (push manage-minor-mode-table--on-word new-entry-value)  ; Status
        (push "" new-entry-value)  ; CD
        (push (vconcat new-entry-value) new-entry)  ; Turn into vector.
        (push (number-to-string id-count) new-entry)  ; ID
        (push new-entry entries)
        (setq id-count (1+ id-count))))
    ;; For INACTIVE minor-mode.
    (dolist (mm inactive-list)
      (let ((new-entry '()) (new-entry-value '()))
        (push (symbol-name mm) new-entry-value)    ; Name
        (push manage-minor-mode-table--off-word new-entry-value)  ; Status
        (push "" new-entry-value)  ; CD
        (push (vconcat new-entry-value) new-entry)  ; Turn into vector.
        (push (number-to-string id-count) new-entry)  ; ID
        (push new-entry entries)
        (setq id-count (1+ id-count))))
    entries))

(define-derived-mode manage-minor-mode-table-mode tabulated-list-mode
  "manage-minor-mode-table-mode"
  "Major mode for managing minor mode."
  :group 'manage-minor-mode
  (setq tabulated-list-format manage-minor-mode-table--format)
  (setq tabulated-list-padding 1)
  (setq tabulated-list--header-string
        (format "buffer: %s, major-mode: %s"
                (propertize
                 (format "%s" manage-minor-mode-table--record-buffer-name)
                 'face 'manage-minor-mode-table-hl-face)
                (propertize
                 (format "%s" manage-minor-mode-table--record-major-mode)
                 'face 'manage-minor-mode-table-hl-face)))
  (setq tabulated-list-sort-key (cons "Name" nil))
  (tabulated-list-init-header)
  (setq tabulated-list-entries (manage-minor-mode-table--get-entries))
  (tabulated-list-print t)
  (tabulated-list-print-fake-header))

;;;###autoload
(defun manage-minor-mode-table ()
  "Active manage minor mode buffer."
  (interactive)
  (setq manage-minor-mode-table--record-buffer-name (buffer-name))
  (setq manage-minor-mode-table--record-major-mode major-mode)
  (pop-to-buffer "*manage-minor-mode-table*" nil)
  (manage-minor-mode-table-mode))

(provide 'manage-minor-mode-table)
;;; manage-minor-mode-table.el ends here
