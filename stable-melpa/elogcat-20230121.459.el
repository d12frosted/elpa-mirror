;;; elogcat.el --- logcat interface

;; Copyright (C) 2023 Youngjoo Lee

;; Author: Youngjoo Lee <youngker@gmail.com>
;; Version: 0.2.0
;; Package-Version: 20230121.459
;; Package-Commit: f2f19d7ab6b77b8fec55cb67524df629fe967891
;; Keywords: tools
;; Package-Requires: ((s "1.9.0") (dash "2.10.0"))

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

;; logcat interface for Emacs

;;; Code:
(require 's)
(require 'dash)

;;;; Declarations
(defvar elogcat-pending-output "")

(defgroup elogcat nil
  "Interface with elogcat."
  :group 'external)

(defface elogcat-verbose-face '((t (:inherit default)))
  "Font Lock face used to highlight VERBOSE log records."
  :group 'elogcat)

(defface elogcat-debug-face '((t (:inherit font-lock-preprocessor-face)))
  "Font Lock face used to highlight DEBUG log records."
  :group 'elogcat)

(defface elogcat-info-face '((t (:inherit success)))
  "Font Lock face used to highlight INFO log records."
  :group 'elogcat)

(defface elogcat-warning-face '((t (:inherit warning)))
  "Font Lock face used to highlight WARN log records."
  :group 'elogcat)

(defface elogcat-error-face '((t (:inherit error)))
  "Font Lock face used to highlight ERROR log records."
  :group 'elogcat)

(defface elogcat-fatal-face '((t (:inherit error)))
  "Font Lock face used to highlight ERROR log records."
  :group 'elogcat)

(defvar elogcat-face-alist
  '(("V" . elogcat-verbose-face)
    ("D" . elogcat-debug-face)
    ("I" . elogcat-info-face)
    ("W" . elogcat-warning-face)
    ("E" . elogcat-error-face)
    ("F" . elogcat-fatal-face)))

(defcustom elogcat-logcat-command
  "logcat -v threadtime -b main -b system -b radio -b events -b crash -b kernel"
  "Logcat command."
  :group 'elogcat)

(defvar elogcat-include-filter-regexp nil)
(defvar elogcat-exclude-filter-regexp nil)

(defconst elogcat-process-name "elogcat")

(defcustom elogcat-buffer "*elogcat*"
  "Name for elogcat buffer."
  :group 'elogcat)

(defcustom elogcat-mode-line '(:eval (elogcat-make-status))
  "Mode line lighter for elogcat."
  :group 'elogcat
  :type 'sexp
  :risky t
  :package-version '(elogcat . "0.2.0"))

(defun elogcat-get-log-buffer-status (buffer)
  "Get a log buffer status by BUFFER."
  (let ((end (if (string= buffer "kernel") "" "|")))
    (if (s-contains? buffer elogcat-logcat-command)
        (concat (s-word-initials buffer) end)
      (concat "-" end))))

(defun elogcat-make-status (&optional status)
  "Get a log buffer STATUS for use in the mode line."
  (format " elogcat[%s]"
          (mapconcat (lambda (args) (elogcat-get-log-buffer-status args))
                     '("main" "system" "radio" "events" "crash" "kernel") "")))

(defun elogcat-erase-buffer ()
  "Clear elogcat buffer."
  (interactive)
  (with-current-buffer elogcat-buffer
    (let ((buffer-read-only nil))
      (erase-buffer)))
  (start-process-shell-command "elogcat-clear"
                               "*elogcat-clear*"
                               (concat "adb " elogcat-logcat-command " -c"))
  (sleep-for 1)
  (elogcat-stop)
  (elogcat))

(defun elogcat-clear-filter (filter)
  "Clear the FILTER."
  (interactive)
  (let ((buffer-read-only nil))
    (goto-char (point-max))
    (insert (propertize
             (concat "--------- " (symbol-name filter) " is cleared\n")
             'font-lock-face (cdr (assoc "V" elogcat-face-alist))))
    (set filter nil)))

(defun elogcat-clear-include-filter ()
  "Clear the include filter."
  (interactive)
  (elogcat-clear-filter 'elogcat-include-filter-regexp))

(defun elogcat-clear-exclude-filter ()
  "Clear the include filter."
  (interactive)
  (elogcat-clear-filter 'elogcat-exclude-filter-regexp))

(defun elogcat-set-filter (regexp filter)
  "Set the filter to REGEXP FILTER."
  (with-current-buffer elogcat-buffer
    (let ((buffer-read-only nil)
          (info-face (cdr (assoc "V" elogcat-face-alist))))
      (goto-char (point-max))
      (insert (propertize
               (concat "--------- " (symbol-name filter) " '" regexp "'\n")
               'font-lock-face info-face))
      (set filter regexp))))

(defun elogcat-show-status ()
  "Show current status."
  (interactive)
  (let ((buffer-read-only nil))
    (goto-char (point-max))
    (insert (propertize
             (concat "--------- "
                     "Include: '" elogcat-include-filter-regexp "' , "
                     "eXclude: '" elogcat-exclude-filter-regexp "'\n")
             'font-lock-face (cdr (assoc "V" elogcat-face-alist))))))

(defun elogcat-set-include-filter (regexp)
  "Set the REGEXP for include filter."
  (interactive "MRegexp Include Filter: ")
  (elogcat-set-filter regexp 'elogcat-include-filter-regexp))

(defun elogcat-set-exclude-filter (regexp)
  "Set the REGEXP for exclude filter."
  (interactive "MRegexp Exclude Filter: ")
  (elogcat-set-filter regexp 'elogcat-exclude-filter-regexp))

(defun elogcat-include-string-p (line)
  "Matched include regexp in LINE."
  (if elogcat-include-filter-regexp
      (s-match elogcat-include-filter-regexp line)
    t))

(defun elogcat-exclude-string-p (line)
  "Matched exclude regexp in LINE."
  (if elogcat-exclude-filter-regexp
      (s-match elogcat-exclude-filter-regexp line)
    nil))

(defun elogcat-process-filter (process output)
  "Adb PROCESS make line from OUTPUT buffer."
  (when (get-buffer elogcat-buffer)
    (with-current-buffer elogcat-buffer
      (let ((following (= (point-max) (point)))
            (buffer-read-only nil)
            (pos 0)
            (output (concat elogcat-pending-output
                            (replace-regexp-in-string "\r" "" output))))
        (save-excursion
          (while (string-match "\n" output pos)
            (let ((line (substring output pos (match-beginning 0))))
              (setq pos (match-end 0))
              (goto-char (point-max))
              (when (and (elogcat-include-string-p line)
                         (not (elogcat-exclude-string-p line)))
                (if (string-match-p "^\\([0-9][0-9]\\)-\\([0-9][0-9]\\)" line)
                    (let* ((log-list (s-split-up-to "\s+" line 6))
                           (level (nth 4 log-list))
                           (level-face (cdr (or (assoc level elogcat-face-alist)
                                                (assoc "I" elogcat-face-alist)))))
                      (insert (propertize line 'font-lock-face level-face) "\n"))
                  (insert line "\n")))))
          (setq elogcat-pending-output (substring output pos)))
        (when following (goto-char (point-max)))))))

(defun elogcat-process-sentinel (process event)
  "Test PROCESS EVENT.")

(defmacro elogcat-define-toggle-function (sym ring-buffer-name)
  "Define a function with SYM and RING-BUFFER-NAME."
  (let ((fun (intern (format "elogcat-toggle-%s" sym)))
        (doc (format "Switch to %s" ring-buffer-name)))
    `(progn
       (defun ,fun () ,doc
              (interactive)
              (let ((option (concat "-b " ,ring-buffer-name)))
                (if (s-contains? option elogcat-logcat-command)
                    (setq elogcat-logcat-command
                          (mapconcat (lambda (args) (concat (s-trim args)))
                                     (s-split option elogcat-logcat-command) " "))
                  (setq elogcat-logcat-command
                        (s-concat (s-trim elogcat-logcat-command) " " option))))
              (let ((buffer-read-only nil))
                (erase-buffer))
              (elogcat-stop)
              (elogcat)))))

(elogcat-define-toggle-function main "main")
(elogcat-define-toggle-function system "system")
(elogcat-define-toggle-function radio "radio")
(elogcat-define-toggle-function events "events")
(elogcat-define-toggle-function crash "crash")
(elogcat-define-toggle-function kernel "kernel")

(defvar elogcat-mode-map nil
  "Keymap for elogcat minor mode.")

(unless elogcat-mode-map
  (setq elogcat-mode-map (make-sparse-keymap)))

(--each '(("C" . elogcat-erase-buffer)
          ("i" . elogcat-set-include-filter)
          ("x" . elogcat-set-exclude-filter)
          ("I" . elogcat-clear-include-filter)
          ("X" . elogcat-clear-exclude-filter)
          ("g" . elogcat-show-status)
          ("F" . occur)
          ("q" . elogcat-exit)
          ("m" . elogcat-toggle-main)
          ("s" . elogcat-toggle-system)
          ("r" . elogcat-toggle-radio)
          ("e" . elogcat-toggle-events)
          ("c" . elogcat-toggle-crash)
          ("k" . elogcat-toggle-kernel))
  (define-key elogcat-mode-map (read-kbd-macro (car it)) (cdr it)))

(define-minor-mode elogcat-mode
  "Minor mode for elogcat."
  :lighter elogcat-mode-line
  nil " elogcat" elogcat-mode-map)

(defun elogcat-exit ()
  "Exit elogcat."
  (interactive)
  (let* ((buf (current-buffer))
         (proc (get-buffer-process buf)))
    (when (process-live-p proc)
      (kill-process proc)
      (sleep-for 0.1))
    (kill-buffer buf)))

(defun elogcat-stop ()
  "Stop the adb logcat process."
  (-when-let (proc (get-process "elogcat"))
    (delete-process proc)))

;;;###autoload
(defun elogcat ()
  "Start the adb logcat process."
  (interactive)
  (unless (get-process "elogcat")
    (let ((proc (start-process-shell-command
                 "elogcat"
                 elogcat-buffer
                 (concat "adb shell "
                         (shell-quote-argument
                          (concat elogcat-logcat-command
                                  (unless (s-contains? "-b" elogcat-logcat-command)
                                    " -s")))))))
      (set-process-filter proc 'elogcat-process-filter)
      (set-process-sentinel proc 'elogcat-process-sentinel)
      (with-current-buffer elogcat-buffer
        (elogcat-mode t)
        (setq buffer-read-only t)
        (font-lock-mode t))
      (switch-to-buffer elogcat-buffer)
      (goto-char (point-max)))))

(provide 'elogcat)
;;; elogcat.el ends here
