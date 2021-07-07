;;; flycheck-title.el --- show flycheck errors in the frame title  -*- lexical-binding: t; -*-

;; Copyright (C) 2016

;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Version: 1.1
;; Package-Version: 20210321.558
;; Package-Commit: 74e4375f372f7b9ce0fdfa34dc74a048376679ae
;; Package-Requires: ((flycheck "30") (emacs "24"))

;; This program is free software; you can redistribute it and/or modify
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

;; flycheck-title lets you view flycheck messages in the frame title,
;; keeping the minibuffer free for other things.

;; This is particularly useful if you're using your minibuffer for
;; eldoc, and using pop-ups for completion.

;; To install, simply add to your configuration:

;; (with-eval-after-load 'flycheck
;;   (flycheck-title-mode))

;; See https://github.com/Wilfred/flycheck-frame-title for full docs
;; and gratuitous screenshots.

;;; Code:

(require 'flycheck)

(defvar flycheck-title--prev-format nil)
(defvar flycheck-title--prev-error-fn nil)

(defun flycheck-title--remove-newlines (s)
  "Remove all the newlines in S, so we can show the full error in
the frame title."
  (replace-regexp-in-string "\n" ": " s t t))

(defun flycheck-title--show ()
  "If there's a flycheck error at point, show that, otherwise use the previous value
of `frame-title-format'."
  (let* ((flycheck-errs (flycheck-overlay-errors-at (point)))
         (first-err (car flycheck-errs)))
    (if first-err
        (let* ((pretty-err (flycheck-error-format-message-and-id first-err)))
          (format "FlyC: %s" (flycheck-title--remove-newlines pretty-err)))
      (format-mode-line flycheck-title--prev-format))))

;;;###autoload
(define-minor-mode flycheck-title-mode
  "Global minor mode for showing flycheck errors in the frame title."
  :global t
  (if (null flycheck-title--prev-format)
      (progn
        ;; Save the old frame title and tell Emacs to use
        ;; `flycheck-title--show` instead.
        (setq flycheck-title--prev-format
              frame-title-format)
        (setq frame-title-format
              `(:eval (flycheck-title--show)))
        ;; Ensure flycheck does not show anything in the minibuffer.
        (setq flycheck-title--prev-error-fn
              flycheck-display-errors-function)
        (setq flycheck-display-errors-function nil))
    ;; Otherwise, we're disabling the mode, so restore the previous
    ;; settings.
    (setq frame-title-format
          flycheck-title--prev-format)
    (setq flycheck-title--prev-format
          nil)
    (setq flycheck-display-errors-function 
          flycheck-title--prev-error-fn)
    (setq flycheck-title--prev-error-fn nil)))

(provide 'flycheck-title)
;;; flycheck-title.el ends here
