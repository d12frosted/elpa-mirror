;;; evil-textobj-syntax.el --- Provides syntax text objects. -*- lexical-binding: t; -*-

;; URL: https://github.com/laishulu/evil-textobj-syntax
;; Package-Version: 20181210.1213
;; Package-Commit: 2d9ba8c75c754b409aea7469f46a5cfa52a872f3
;; Created: November 1, 2018
;; Keywords: evil, syntax, highlight, text-object
;; Package-Requires: ((names "0.5") (emacs "24") (evil "0"))
;; Version: 0.1

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This package is a port of the vim-textobj-syntax plugin. It provides a
;; a means to create text objects for acting on consecutive items with same
;; syntax highlight.
;; For more information see the README in the github repo.

;;; Code:
(require 'evil)

;; `define-namespace' is autoloaded, so there's no need to require
;; `names'. However, requiring it here means it will also work for
;; people who don't install through package.el.
(eval-when-compile (require 'names))

(define-namespace evil-textobj-syntax-
:package evil-textobj-syntax
:group evil

(defun -what-face (&optional pos)
  "Shows all faces at point"
  (let* ((pos (or pos (point)))
         (face (get-text-property pos 'face)))
    (unless (keywordp (car-safe face)) (list face))))

(defun -whitespacep (c)
  "This function returns t if c is white spaces, nil otherwise."
  (= 32 (char-syntax c)))

(defun -create-range (&optional inclusive)
  (let ((point-face (-what-face))
        (backward-point (point)) ; last char when stop, including white space
        (backward-none-space-point (point)) ; last none white space char
        (forward-point (point)) ; last char when stop, including white space
        (forward-none-space-point (point)) ; last none white space char
        (start (point))
        (end (point)))

    ;; check chars backward,
    ;; stop when char is not white space and has different face
    (save-excursion
      (let ((continue t))
        (while (and continue (>= (- (point) 1) (point-min)))
          (backward-char)
          (let ((backward-point-face (-what-face)))
            (if (-whitespacep (char-after))
                (setq backward-point (point))
              (if (equal point-face backward-point-face)
                  (progn (setq backward-point (point))
                         (setq backward-none-space-point (point)))
                (setq continue nil)))))))

    ;; check chars forward,
    ;; stop when char is not white space and has different face
    (save-excursion
      (let ((continue t))
        (while (and continue (< (+ (point) 1) (point-max)))
          (forward-char)
          (let ((forward-point-face (-what-face)))
            (if (-whitespacep (char-after))
                (setq forward-point (point))
              (if (equal point-face forward-point-face)
                  (progn (setq forward-point (point))
                         (setq forward-none-space-point (point)))
                (setq continue nil)))))))

    (if inclusive
        ;; for outer object,
        ;; if both leading and trailing white spaces exist,
        ;; only trailing whitespaces are included.
        ;; otherwise, leading/trailing/none white spaces are included.
        (progn
          (if (and (/= backward-none-space-point backward-point)
                   (/= forward-none-space-point forward-point))
              (setq start backward-none-space-point)
            (setq start backward-point))
          (setq end forward-point))
      ;; for inner object,
      ;; no leading and trailing white spaces are included
      (setq start backward-none-space-point)
      (setq end forward-none-space-point))

    (evil-range start (+ end 1))))

;; end of namespace
)

(defgroup evil-textobj-syntax nil
  "Syntax text object for Evil"
  :group 'evil)

(defcustom evil-textobj-syntax-i-key "h"
  "Keys for evil-i-syntax"
  :type 'string
  :group 'evil-textobj-syntax)

(defcustom evil-textobj-syntax-a-key "h"
  "Keys for evil-a-syntax"
  :type 'string
  :group 'evil-textobj-syntax)

;;;###autoload (autoload 'evil-a-syntax "evil-textobj-syntax" nil t)
(evil-define-text-object evil-a-syntax (count &optional beg end type)
  "Select range between a character by which the command is followed."
  (evil-textobj-syntax--create-range t))

;;;###autoload (autoload 'evil-i-syntax "evil-textobj-syntax" nil t)
(evil-define-text-object evil-i-syntax (count &optional beg end type)
  "Select inner range between a character by which the command is followed."
  (evil-textobj-syntax--create-range))

(define-key evil-outer-text-objects-map
  evil-textobj-syntax-a-key 'evil-a-syntax)
(define-key evil-inner-text-objects-map
  evil-textobj-syntax-i-key 'evil-i-syntax)

(provide 'evil-textobj-syntax)
;;; evil-textobj-syntax.el ends here
