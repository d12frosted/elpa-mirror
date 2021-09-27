;;; flymake-languagetool.el --- Flymake support for LanguageTool  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shen, Jen-Chieh
;; Created date 2021-04-02 23:22:37

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Flymake support for LanguageTool
;; Keyword: grammar check
;; Version: 0.2.0
;; Package-Version: 20210627.434
;; Package-Commit: cd6e5602e58bd9c03ec1c6a3b01c337d17ebf0fe
;; Package-Requires: ((emacs "27.1") (s "1.9.0"))
;; URL: https://github.com/emacs-languagetool/flymake-languagetool

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
;; Flymake support for LanguageTool.
;;

;;; Code:

(require 's)
(require 'json)
(require 'flymake)

(defgroup flymake-languagetool nil
  "Flymake support for LanguageTool."
  :prefix "flymake-languagetool-"
  :group 'flymake
  :link '(url-link :tag "Github" "https://github.com/emacs-languagetool/flymake-languagetool"))

(defcustom flymake-languagetool-active-modes
  '(text-mode latex-mode org-mode markdown-mode message-mode)
  "List of major mode that work with LanguageTool."
  :type 'list
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-commandline-jar ""
  "The path of languagetool-commandline.jar."
  :type '(file :must-match t)
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-args ""
  "Extra argument pass in to command line tool."
  :type 'string
  :group 'flymake-languagetool)

(defcustom flymake-languagetool-language "en-US"
  "The language code of the text to check."
  :type '(string :tag "Language")
  :safe #'stringp
  :group 'flymake-languagetool)
(make-variable-buffer-local 'flymake-languagetool-language)

(defcustom flymake-languagetool-check-time 0.8
  "How long do we call process after we done typing."
  :type 'float
  :group 'flymake-languagetool)

(defvar-local flymake-languagetool--done-checking t
  "If non-nil then we are currently in the checking process.")

(defvar-local flymake-languagetool--timer nil
  "Timer that will tell to do the request.")

(defvar-local flymake-languagetool--output nil
  "Copy of the JSON output.")

(defvar-local flymake-languagetool--source-buffer nil
  "Current buffer we are currently using for grammar check.")

;;; Util

(defconst flymake-languagetool--json-parser
  (if (and (functionp 'json-parse-buffer)
           ;; json-parse-buffer only supports keyword arguments in Emacs 27+
           (>= emacs-major-version 27))
      (lambda ()
        (json-parse-buffer
         :object-type 'alist :array-type 'list
         :null-object nil :false-object nil))
    #'json-read)
  "Function to use to parse JSON strings.")

(defun flymake-languagetool--parse-json (output)
  "Return parsed JSON data from OUTPUT.

OUTPUT is a string that contains JSON data.  Each line of OUTPUT
may be either plain text, a JSON array (starting with `['), or a
JSON object (starting with `{').

This function ignores the plain text lines, parses the JSON
lines, and returns the parsed JSON lines in a list."
  (let ((objects nil)
        (json-array-type 'list)
        (json-false nil))
    (with-temp-buffer
      (insert output)
      (goto-char (point-min))
      (while (not (eobp))
        (when (memq (char-after) '(?\{ ?\[))
          (push (funcall flymake-languagetool--json-parser) objects))
        (forward-line)))
    (nreverse objects)))

(defmacro flymake-languagetool--with-source-buffer (&rest body)
  "Execute BODY inside currnet source buffer."
  (declare (indent 0) (debug t))
  `(if flymake-languagetool--source-buffer
       (with-current-buffer flymake-languagetool--source-buffer (progn ,@body))
     (user-error "Invalid source buffer: %s" flymake-languagetool--source-buffer)))

(defun flymake-languagetool--async-shell-command-to-string (callback cmd &rest args)
  "Asnyc version of function `shell-command-to-string'.

Argument CALLBACK is called after command is done executing.
Argument CMD is the name of the command executable.
Rest argument ARGS is the rest of the argument for CMD."
  (let ((output-buffer (generate-new-buffer " *temp*"))
        (callback-fun callback))
    (set-process-sentinel
     (start-process "Shell" output-buffer shell-file-name shell-command-switch
                    (concat cmd " " (mapconcat #'shell-quote-argument args " ")))
     (lambda (process _signal)
       (when (memq (process-status process) '(exit signal))
         (with-current-buffer output-buffer
           (let ((output-string (buffer-substring-no-properties (point-min) (point-max))))
             (funcall callback-fun output-string)))
         (kill-buffer output-buffer))))
    output-buffer))

;;; Core

(defun flymake-languagetool--check-all (source-buffer)
  "Check grammar for SOURCE-BUFFER document."
  (let ((matches (cdr (assoc 'matches flymake-languagetool--output)))
        check-list)
    (dolist (match matches)
      (let* ((pt-beg (cdr (assoc 'offset match)))
             (len (cdr (assoc 'length match)))
             (pt-end (+ pt-beg len))
             (type 'warning)
             (desc (cdr (assoc 'message match))))
        (push (flymake-make-diagnostic source-buffer (1+ pt-beg) (1+ pt-end) type desc) check-list)))
    (progn  ; Remove fitst and last element to avoid quote warningsk
      (pop check-list)
      (setq check-list (butlast check-list)))
    check-list))

(defun flymake-languagetool--cache-parse-result (output)
  "Refresh cache buffer from OUTPUT."
  (setq flymake-languagetool--output (car (flymake-languagetool--parse-json output))
        flymake-languagetool--done-checking t)
  (flymake-mode 1))

(defun flymake-languagetool--send-process ()
  "Send process to LanguageTool commandline-jar."
  (if (not (file-exists-p flymake-languagetool-commandline-jar))
      (user-error "Invalid commandline path: %s" flymake-languagetool-commandline-jar)
    (when flymake-languagetool--done-checking
      (setq flymake-languagetool--done-checking nil)  ; start flag
      (flymake-languagetool--with-source-buffer
       (let ((source (current-buffer)))
         (flymake-languagetool--async-shell-command-to-string
          (lambda (output)
            (when (buffer-live-p source)
              (with-current-buffer source (flymake-languagetool--cache-parse-result output))))
          (format "echo %s | java -jar %s %s --json -b %s"
                  (shell-quote-argument (s-replace "\n" " " (buffer-string)))
                  flymake-languagetool-commandline-jar
                  (if (stringp flymake-languagetool-language)
                      (concat "-l " flymake-languagetool-language)
                    "-adl")
                  (if (stringp flymake-languagetool-args) flymake-languagetool-args ""))))))))

(defun flymake-languagetool--start-timer ()
  "Start the timer for grammar check."
  (setq flymake-languagetool--source-buffer (current-buffer))
  (when (timerp flymake-languagetool--timer) (cancel-timer flymake-languagetool--timer))
  (setq flymake-languagetool--timer
        (run-with-idle-timer flymake-languagetool-check-time nil
                             #'flymake-languagetool--send-process)))

;;; Flymake

(defvar flymake-languagetool--report-fnc nil
  "Record report function/execution.")

(defvar flymake-languagetool--source-buffer nil
  "Record source check buffer.")

(defun flymake-languagetool--report-once ()
  "Report with flymake after done requesting."
  (when (functionp flymake-languagetool--report-fnc)
    (flymake-languagetool--start-timer)
    (funcall flymake-languagetool--report-fnc
             (flymake-languagetool--check-all flymake-languagetool--source-buffer))))

(defun flymake-languagetool--checker (report-fn &rest _args)
  "Diagnostic checker function with REPORT-FN."
  (setq flymake-languagetool--report-fnc report-fn
        flymake-languagetool--source-buffer (current-buffer))
  (flymake-languagetool--report-once))

;;; Entry

;;;###autoload
(defun flymake-languagetool-load ()
  "Configure flymake mode to check the current buffer's grammar."
  (interactive)
  (flymake-languagetool--start-timer)
  (add-hook 'flymake-diagnostic-functions #'flymake-languagetool--checker nil t))

;;;###autoload
(defun flymake-languagetool-maybe-load ()
  "Call `flymake-languagetool-load' if this file appears to be check for grammar."
  (interactive)
  (when (memq major-mode flymake-languagetool-active-modes)
    (flymake-languagetool-load)))

(provide 'flymake-languagetool)
;;; flymake-languagetool.el ends here
