;;; php-scratch.el --- A scratch buffer to interactively evaluate php code -*- lexical-binding: t -*-

;; Copyright © 2016 Tijs Mallaerts
;;
;; Author: Tijs Mallaerts <tijs.mallaerts@gmail.com>

;; Package-Requires: ((emacs "24.3") (s "1.11.0") (php-mode "1.17.0"))
;; Package-Version: 20210706.459
;; Package-Commit: b6bfd279da8a8ac7fc30459485956f3fd5d02573
;; Homepage: https://github.com/mallt/php-scratch

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

;; This file is not part of GNU Emacs.

;;; Commentary:

;; A scratch buffer to interactively evaluate php code.
;; C-c C-e will evaluate the active region or current line.
;; C-c C-c will clear the state of the php scratch repl process.

;;; Code:

(require 'php-mode)
(require 's)
(require 'comint)

(defgroup php-scratch nil
  "Php scratch buffer customizations."
  :group 'processes)

(defcustom php-scratch-boris-command "boris"
  "Path to the boris repl command."
  :type 'string
  :group 'php-scratch)

(defcustom php-scratch-use-overlays nil
  "Controls whether overlays should be used to show results."
  :type 'boolean
  :group 'php-scratch)

(defun php-scratch--font-lock-string (string)
  "Apply php font lock to STRING."
  (with-temp-buffer
    (php-mode)
    (erase-buffer)
    (insert string)
    (font-lock-fontify-region (point-min) (point-max))
    (buffer-string)))

(defun php-scratch--startup-process-filter (proc str)
  "The filter for the startup of the php scratch repl PROC.
STR is the output string of the startup PROC."
  (set-process-filter proc 'php-scratch--process-filter))

(defun php-scratch--show-result (str)
  "Show the result STR."
  (if php-scratch-use-overlays
      (momentary-string-display (concat " => " str)
                                (if (region-active-p)
                                    (region-end)
                                  (line-end-position))
                                nil "")
    (message "%s" str)))

(defun php-scratch--process-filter (proc str)
  "The filter for the php scratch repl PROC.
STR is the output string of the PROC."
  ;; input command is returned by default, do not show this in minibuffer
  (when (not (string= (replace-regexp-in-string "\r+$" "" str)
                      (process-get proc 'input-command)))
    (let* ((split-str (split-string str "→"))
           (output-str (if (or (string-match-p "error" str)
                               (equal 1 (length split-str)))
                           str
                         (nth 1 split-str)))
           (res (mapconcat 'identity
                           (butlast (split-string output-str "\r"))
                           ""))
           (res2 (if (string= "" res)
                     (mapconcat 'identity
                                (butlast (split-string output-str "\n"))
                                "")
                   res))
           (replace-arrow (replace-regexp-in-string "→" "" res2))
           (trim (s-trim replace-arrow))
           (font-lock (php-scratch--font-lock-string trim)))
      (php-scratch--show-result font-lock))))

(defun php-scratch--process-sentinel (proc e)
  "The sentinel of the php scratch repl PROC.
The sentinel is used to handle the clear state action.  When the
value of E is killed, the php scratch buffer will be killed and
the php scratch repl process will be restarted."
  (when (string= "killed\n" e)
    (kill-buffer "*php-scratch-repl*")
    (php-scratch--start-repl-process)))

(defun php-scratch--start-repl-process ()
  "Start the php repl process."
  (when (not (get-process "php-scratch-repl"))
    (make-comint "php-scratch-repl" php-scratch-boris-command)
    (let ((proc (get-process "php-scratch-repl")))
      (set-process-query-on-exit-flag proc nil)
      (set-process-filter proc 'php-scratch--startup-process-filter)
      (process-send-string proc
                           "$this->setInspector(new \\Boris\\ExportInspector());\n"))))

(defun php-scratch-clear-state ()
  "Clear the state of the php scratch repl process.
The repl process will be restarted in the background."
  (interactive)
  (let ((proc (get-process "php-scratch-repl")))
    (set-process-sentinel proc 'php-scratch--process-sentinel)
    (delete-process proc)))

(defun php-scratch-eval ()
  "Evaluate the active region or current line."
  (interactive)
  (let* ((proc (get-process "php-scratch-repl"))
         (reg-beg (if (region-active-p)
                      (region-beginning)
                    (line-beginning-position)))
         (reg-end (if (region-active-p)
                      (region-end)
                    (line-end-position)))
         (region (buffer-substring-no-properties reg-beg reg-end))
         (command (concat (s-trim region) ";\n")))
    (process-put proc 'input-command command)
    (process-send-string proc command)))

(defun php-scratch-minibuffer-eval ()
  "Read the php code in the minibuffer and evaluate it."
  (interactive)
  (let ((code (read-from-minibuffer "PHP eval: ")))
    (with-temp-buffer
      (insert code)
      (set-mark (point-min))
      (goto-char (point-max))
      (exchange-point-and-mark)
      (php-scratch-eval))))

(define-derived-mode php-scratch-mode
  php-mode "php-scratch"
  "Major mode for the php scratch buffer.")

(define-key php-scratch-mode-map (kbd "C-c C-e") 'php-scratch-eval)
(define-key php-scratch-mode-map (kbd "C-c C-c") 'php-scratch-clear-state)
(define-key php-scratch-mode-map (kbd "C-c M-:") 'php-scratch-minibuffer-eval)

;;;###autoload
(defun php-scratch ()
  "Open the php scratch buffer and start the php scratch repl process."
  (interactive)
  (if (get-buffer "*php-scratch*")
      (switch-to-buffer "*php-scratch*")
    (when (not php-scratch-boris-command)
      (user-error "%s" "Error: the variable php-scratch-boris-command is not set."))
    (php-scratch--start-repl-process)
    (get-buffer-create "*php-scratch*")
    (switch-to-buffer "*php-scratch*")
    (php-scratch-mode)
    (insert "/* php scratch buffer */\n")))

(provide 'php-scratch)

;;; php-scratch.el ends here
