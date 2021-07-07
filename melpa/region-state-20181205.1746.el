;;; region-state.el --- Show the number of chars/lines or rows/columns in the region  -*- lexical-binding: t; -*-

;; Copyright (C) 2015, 2018  Chunyang Xu

;; Author: Chunyang Xu <mail@xuchunyang.me>
;; URL: https://github.com/xuchunyang/region-state.el
;; Package-Version: 20181205.1746
;; Package-Commit: 8c636b655eef45e0015684699737d31e15450000
;; Keywords: convenience
;; Version: 0.1

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

;; This is a global minor-mode. Turn it on everywhere with:
;; ┌────
;; │ (region-state-mode 1)
;; └────
;;
;; That’s it.
;;
;; See the accompanying README.org for configuration details.

;;; Code:

(eval-when-compile (require 'rect))
(declare-function apply-on-rectangle 'rect)


;;; Compatibility
(eval-and-compile
  (unless (fboundp 'defvar-local)
    ;; `defvar-local' for Emacs 24.2 and below
    (defmacro defvar-local (var val &optional docstring)
      "Define VAR as a buffer-local variable with default value VAL.
Like `defvar' but additionally marks the variable as being automatically
buffer-local wherever it is set."
      (declare (debug defvar) (doc-string 3))
      ;; Can't use backquote here, it's too early in the bootstrap.
      (list 'progn (list 'defvar var val docstring)
            (list 'make-variable-buffer-local (list 'quote var))))))


;;; Customization
(defgroup region-state nil
  "Show the region (aka. selection) state"
  :prefix "region-state-"
  :group 'convenience)


;;; Variables
(defvar-local region-state-string nil
  "Description of the region.")
(put 'region-state-string 'risky-local-variable t)

(defvar-local region-state-lines 0
  "The number of lines in the region.")
(defvar-local region-state-chars 0
  "The number of characters in the region.")

(defvar-local region-state-rows 0
  "The number of rows in the rectangle.")
(defvar-local region-state-cols 0
  "The number of colums in the rectangle.")

(defvar-local region-state-last-beginning 0
  "Beginning position of the last region.")
(defvar-local region-state-last-ending 0
  "Ending position of the last region.")

(defvar region-state-after-update-hook nil
  "Run by `region-state--update', after `region-state-string' is updated.")


;;; Function

(defun region-state--format ()
  "Build `region-state-string'."
  (setq region-state-string
        (if (bound-and-true-p rectangle-mark-mode)
            (format "%d rows, %d columns rectangle selected"
                    region-state-rows
                    region-state-cols)
          (concat
           (when (> region-state-lines 1)
             (format "%d lines, " region-state-lines))
           (when (> region-state-chars 0)
             (format "%d characters selected" region-state-chars))))))

(defun region-state--update-1 (beg end)
  (if (not (bound-and-true-p rectangle-mark-mode))
      (let ((chars (- end beg))
            (lines (count-lines beg end)))
        (setq region-state-chars chars
              region-state-lines lines))
    (let ((rows 0)
          (cols 0))
      (apply-on-rectangle (lambda (startcol endcol)
                            (setq rows (1+ rows))
                            (setq cols (- endcol startcol)))
                          beg end)
      (setq region-state-rows rows
            region-state-cols cols))))

(defun region-state--update ()
  (let ((beg (region-beginning))
        (end (region-end)))
    (when (or (eq this-command 'rectangle-mark-mode)
              ;; For side effect only
              (eq this-command 'exchange-point-and-mark)
              (eq this-command 'rectangle-exchange-point-and-mark)
              (not (and (= beg region-state-last-beginning)
                        (= end region-state-last-ending))))
      (region-state--update-1 beg end)
      (region-state--format)
      (run-hooks 'region-state-after-update-hook)
      (setq region-state-last-beginning beg
            region-state-last-ending end))))

(defun region-state--activate ()
  (add-hook 'post-command-hook #'region-state--update t t))

(defun region-state--deactivate ()
  (remove-hook 'post-command-hook #'region-state--update t)
  (setq region-state-string nil)
  (setq region-state-last-beginning 0
        region-state-last-ending 0))

(defun region-state--display-in-echo-area ()
  ;; TODO: (low priority) Use mode-line to display if in minibuffer like el-doc
  (unless (minibuffer-window-active-p (selected-window))
    (when (and region-state-string
               (> (length region-state-string) 0))
      (let (message-log-max)
        (message "%s" region-state-string)))))


;;; Minor mode
;;;###autoload
(define-minor-mode region-state-mode
  "Toggle show the region (aka. selection) state.
Interactively with no argument, this command toggles the mode.
A positive prefix argument enables the mode, any other prefix
argument disables it.  From Lisp, argument omitted or nil enables
the mode, `toggle' toggles the state."
  :global t
  (if region-state-mode
      (progn
        (add-hook 'activate-mark-hook #'region-state--activate)
        (add-hook 'deactivate-mark-hook #'region-state--deactivate)
        (add-hook 'region-state-after-update-hook #'region-state--display-in-echo-area))
    (remove-hook 'activate-mark-hook #'region-state--activate)
    (remove-hook 'deactivate-mark-hook #'region-state--deactivate)
    (remove-hook 'region-state-after-update-hook #'region-state--display-in-echo-area)))

(provide 'region-state)
;;; region-state.el ends here
