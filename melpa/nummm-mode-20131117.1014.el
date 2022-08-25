;;; nummm-mode.el --- Display the number of minor modes instead of their names

;; This file is not part of Emacs

;; Copyright (C) 2013 Andreu Gil Pàmies

;; Filename: nummm-mode.el
;; Version: 0.1
;; Package-Version: 20131117.1014
;; Package-Commit: 73b1aa8643d86197c82cd28acdaefcb48a1e0abe
;; Author: Andreu Gil <agpchil@gmail.com>
;; Created: 02-06-2013
;; Description: Display the number of minor modes instead of their names in Emacs mode-line.
;; URL: http://github.com/agpchil/nummm-mode

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Usage:
;; (require 'nummm-mode)
;; (nummm-mode t)

;;; Commentary:
;; This mode replaces the =minor-mode-alist= in =mode-line-modes= with
;; a custom one. =minor-mode-alist= is NOT modified. Also, a backup of
;; =mode-line-modes= is done when enabling =nummm-mode= and is
;; restored when is turned off.
;; The face can be changed customizing =nummm-face=.

;;; Code:
(defgroup nummm-mode nil
  "Display the number of minor modes instead of their names in Emacs mode-line."
  :prefix "nummm-mode"
  :group 'help
  :link '(url-link "http://github.com/agpchil/nummm-mode"))

(defcustom nummm-format "+%d"
  "Format of nummm to show in mode line."
  :type 'string
  :group 'nummm-mode
  :safe 'stringp)

(defvar nummm-mode-line-modes-backup nil)

(defvar nummm-minor-modes-names nil)

(defvar nummm-mode-string '(" " (:eval (nummm-counter))))

(defconst nummm-pattern '("" minor-mode-alist))

(defface nummm-face
  '((t :inherit font-lock-warning-face :bold t))
  "Face used in mode-line."
  :group 'nummm-mode)

(defun nummm-find-minor-modes-alist (current-list)
  "Find `minor-modes-alist` pattern in CURRENT-LIST.
Return a parent list that contains the pattern."
  (let ((found nil)
        (items current-list)
        (item nil))
    (while (and (not found) items)
      (setq item (car items))
      (if (and (listp item) (equal (cadr item) nummm-pattern))
          (setq found items)
        (setq items (cdr items))))
    found))

(defun nummm-backup ()
  "Backup current `mode-line-modes`."
  (setq nummm-mode-line-modes-backup (copy-tree mode-line-modes)))

(defun nummm-restore ()
  "Restore previous `mode-line-modes` value."
  (setq mode-line-modes (copy-tree nummm-mode-line-modes-backup)))

(defun nummm-get-minor-modes-names ()
  "Get the names of the enabled minor modes."
  (delq nil (mapcar #'(lambda (m)
                        (when (symbol-value (car m))
                          (nth 1 m)))
                    minor-mode-alist)))

(defun nummm-count-minor-modes ()
  "Count number of modes in `minor-mode-alist`."
  (setq nummm-minor-modes-names (nummm-get-minor-modes-names))
  (length nummm-minor-modes-names))

(defun nummm-counter ()
  "Build the string to be displayed in `mode-line-modes`."
  (propertize (format nummm-format (nummm-count-minor-modes))
              'face 'nummm-face
              'help-echo (format "%s" nummm-minor-modes-names)))

(defun nummm-turn-on ()
  "Turn on nummm mode."
  (unless nummm-mode-line-modes-backup
    (nummm-backup))
  (let ((modes nil))
    (setq modes (nummm-find-minor-modes-alist mode-line-modes))
    (when modes
      (setf (car modes) nummm-mode-string))))

(defun nummm-turn-off ()
  "Turn off nummm mode."
  (nummm-restore))

(defvar nummm-mode-map (make-keymap)
  "Keymap for nummm-mode.")

;;;###autoload
(define-minor-mode nummm-mode
  "Display the number of minor modes instead of their names in Emacs mode-line."
  :global t
  :group 'nummm-mode
  :init-value t
  :lighter " nummm"
  (progn
    (if nummm-mode
        (nummm-turn-on)
      (nummm-turn-off))))

(provide 'nummm-mode)
;;; nummm-mode.el ends here
