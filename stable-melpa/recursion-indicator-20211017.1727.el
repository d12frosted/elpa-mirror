;;; recursion-indicator.el --- Recursion indicator -*- lexical-binding: t -*-

;; Author: Daniel Mendler
;; Created: 2020
;; License: GPL-3.0-or-later
;; Version: 0.2
;; Package-Version: 20211017.1727
;; Package-Commit: 5d98022dee5a5ba3343f1c26e28febc2f095912c
;; Package-Requires: ((emacs "26"))
;; Homepage: https://github.com/minad/recursion-indicator

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Recursion indicator for the mode line

;;; Code:

(defgroup recursion-indicator nil
  "Recursion indicator for the mode line."
  :group 'convenience)

(defface recursion-indicator-minibuffer
  '((t :inherit 'font-lock-keyword-face :weight normal :height 0.9))
  "Face used for the arrow indicating minibuffer recursion.")

(defface recursion-indicator-general
  '((t :inherit 'font-lock-constant-face :weight normal :height 0.9))
  "Face used for the arrow indicating general recursion.")

(defcustom recursion-indicator-general "⟲"
  "Arrow indicating general recursion."
  :type 'string)

(defcustom recursion-indicator-minibuffer "↲"
  "Arrow indicating minibuffer recursion."
  :type 'string)

(defvar recursion-indicator--minibuffer-depths nil
  "Minibuffer depths.")

(defvar recursion-indicator--cache nil
  "Cached recursion indicator.")

(defun recursion-indicator--string ()
  "Recursion indicator string."
  (let* ((str nil)
         (depth (recursion-depth)))
    (if (eq (car recursion-indicator--cache) depth)
        (cdr recursion-indicator--cache)
      (dotimes (i depth)
        (setq str (concat
                   (if (memq (1+ i) recursion-indicator--minibuffer-depths)
                       (propertize recursion-indicator-minibuffer 'face 'recursion-indicator-minibuffer)
                     (propertize recursion-indicator-general 'face 'recursion-indicator-general))
                   str)))
      (when str
        (setq str (propertize (concat "[" str "] ") 'help-echo "Recursive edit, type C-M-c to get out")))
      (setq recursion-indicator--cache (cons depth str))
      str)))

(defun recursion-indicator--minibuffer-setup ()
  "Minibuffer setup hook."
  (push (recursion-depth) recursion-indicator--minibuffer-depths)
  (setq recursion-indicator--cache nil))

(defun recursion-indicator--minibuffer-exit ()
  "Minibuffer exit hook."
  (pop recursion-indicator--minibuffer-depths)
  (setq recursion-indicator--cache nil))

;;;###autoload
(define-minor-mode recursion-indicator-mode
  "Show the recursion level in the mode-line."
  :global t
  (setq mode-line-misc-info (assq-delete-all 'recursion-indicator-mode mode-line-misc-info))
  (remove-hook 'minibuffer-setup-hook #'recursion-indicator--minibuffer-setup)
  (remove-hook 'minibuffer-exit-hook #'recursion-indicator--minibuffer-exit)
  (when recursion-indicator-mode
    (add-hook 'minibuffer-setup-hook #'recursion-indicator--minibuffer-setup)
    (add-hook 'minibuffer-exit-hook #'recursion-indicator--minibuffer-exit)
    (push '(recursion-indicator-mode (:eval (recursion-indicator--string))) mode-line-misc-info)
    (setq recursion-indicator--cache nil)))

(provide 'recursion-indicator)
;;; recursion-indicator.el ends here
