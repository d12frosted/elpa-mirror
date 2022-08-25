;;; babel-repl.el --- Run babel REPL

;; Copyright (C) 2015-2015 Hung Phan

;; Author: Hung Phan
;; Version: See `babel-repl-version'
;; Package-Version: 20160504.2201
;; Package-Commit: 0faa2f6518a2b46236f116ca1736a314f7d9c034
;; URL: https://github.com/hung-phan/babel-repl/
;; Package-Requires: ((emacs "24"))
;; Keywords: babel, javascript, es6

;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.

;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.

;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This program is derived from comint-mode and provides the following features.
;;
;;  * TAB completion same as Babel.js REPL
;;  * file name completion in string
;;  * incremental history search
;;
;;
;; Put this file in your Emacs lisp path (e.g. ~/.emacs.d/site-lisp)
;; and add the following line to your .emacs:
;;
;;    (require 'babel-repl)
;;
;; Type M-x babel-repl to run Babel.js REPL.
;; See also `comint-mode' to check key bindings.
;;

(require 'comint)

;;; Code:

(defconst babel-repl-version "0.1.0"
  "Babel.js mode Version.")

(defvar babel-repl-cli-program "babel-node"
  "Start babel-node repl for compile es6 syntax.")

(defvar babel-repl-cli-arguments '()
  "List of command line arguments to pass to babel shell cli program.")

(defvar babel-repl-pop-to-buffer nil
  "Whether to pop up the babel shell buffer after sending command to execute.")

(defvar babel-repl-pop-to-buffer-function 'pop-to-buffer
  "The function to pop up the babel shell buffer.")

(define-derived-mode babel-shell-mode comint-mode "Babel Shell"
  "Major mode for `babel-node'."
  ;; not allow the prompt to be deleted
  (setq comint-prompt-read-only t))

(defun babel-repl-pop-to-buffer ()
  "Pop the babel shell buffer to the current window."
  (apply babel-repl-pop-to-buffer-function '("*babel-shell*")))

;;; Taken from masteringemacs with some changes
;;; https://www.masteringemacs.org/article/comint-writing-command-interpreter
;;;###autoload
(defun babel-repl ()
  "Start babel shell comint mode."
  (interactive)
  (let ((buffer (comint-check-proc "*babel-shell*")))
    ;; pop to the "*babel-shell*" buffer if the process is dead, the
    ;; buffer is missing or it's got the wrong mode.
    (pop-to-buffer
     (if (or buffer (not (derived-mode-p 'babel-shell-mode))
             (comint-check-proc (current-buffer)))
         (get-buffer-create "*babel-shell*")
       (current-buffer)))
    ;; create the comint process if there is no buffer.
    (unless buffer
      (apply 'make-comint-in-buffer "babel-shell" nil babel-repl-cli-program nil
             babel-repl-cli-arguments)
      (babel-shell-mode))))

;;; Send the query string to babel shell to execute
(defun babel-repl-send-string (string)
  "Send the input string to babel shell process.
string (as STRING)."
  (if (not (comint-check-proc "*babel-shell*"))
      (message "No babel shell process started")
    (progn
      (process-send-string "*babel-shell*" (concat string "\n"))
      (when babel-repl-pop-to-buffer
        (babel-repl-pop-to-buffer)))))

(defun babel-repl-send-region (beg end)
  "Send the region from beg to end to babel process.
beg (as BEG)
end (as END)."
  (let ((comment (replace-regexp-in-string
                  "//\\([^\n\r]*\\)" "/*\\1 */"
                  (buffer-substring-no-properties beg end))))
    (let ((string (replace-regexp-in-string "[\n|\r]+" " " comment)))
      (babel-repl-send-string string))))

(defun babel-repl-send-current-region ()
  "Send the selected region to babel shell process."
  (interactive)
  (let* ((beg (region-beginning))
         (end (region-end)))
    (babel-repl-send-region beg end)))

(defun babel-repl-send-buffer ()
  "Send the current buffer to babel shell process."
  (interactive)
  (let* ((beg (point-min))
         (end (point-max)))
    (babel-repl-send-region beg end)))

(defun babel-repl-send-paragraph ()
  "Send the current paragraph to babel shell process."
  (interactive)
  (let ((beg (save-excursion
               (backward-paragraph)
               (point)))
        (end (save-excursion
               (forward-paragraph)
               (point))))
    (babel-repl-send-region beg end)))

(defun babel-repl-send-region-or-buffer ()
  "Send the selected region if presented, otherwise, send the whole buffer."
  (interactive)
  (if (use-region-p)
      (babel-repl-send-current-region)
    (babel-repl-send-buffer)))

(defun babel-repl-send-dwim ()
  "Send the selected region presented, otherwise, send the current paragraph."
  (interactive)
  (if (use-region-p)
      (babel-repl-send-current-region)
    (babel-repl-send-paragraph)))

;;;###autoload
(defun babel-repl-switch-to-buffer ()
  "Switch to babel shell buffer."
  (interactive)
  (if (comint-check-proc "*babel-shell*")
      (switch-to-buffer "*babel-shell*")
    (babel-repl)))

(provide 'babel-repl)

;;; babel-repl.el ends here
