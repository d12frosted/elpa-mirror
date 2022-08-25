;;; elogcat.el --- logcat interface

;; Copyright (C) 2015 Youngjoo Lee

;; Author: Youngjoo Lee <youngker@gmail.com>
;; Version: 0.1.0
;; Package-Version: 20151121.41
;; Package-Commit: cafe9bd5c0d6561d72066c70a55c246453693efd
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

;; logcat interface for emacs

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

(defface elogcat-debug-face '((t (:inherit font-lock-comment-face)))
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

(defvar elogcat-face-alist
  '(("V" . elogcat-verbose-face)
    ("D" . elogcat-debug-face)
    ("I" . elogcat-info-face)
    ("W" . elogcat-warning-face)
    ("E" . elogcat-error-face)))

(defcustom elogcat-logcat-command
  "logcat -v threadtime -b main -b events -b system -b radio"
  "DOC."
  :group 'elogcat)

(defcustom elogcat-klog-command
  "cat /proc/kmsg"
  "DOC."
  :group 'elogcat)

(defvar elogcat-include-filter-regexp nil)
(defvar elogcat-exclude-filter-regexp nil)

(defvar elogcat-enable-klog t)

(defconst elogcat-process-name "elogcat")

(defcustom elogcat-buffer "*elogcat*"
  "Name for elogcat buffer."
  :group 'elogcat)

(defcustom elogcat-mode-line '(:eval (elogcat-make-status))
  "Mode line lighter for elogcat."
  :group 'elogcat
  :type 'sexp
  :risky t
  :package-version '(elogcat . "0.1.0"))

(defun elogcat-get-log-buffer-status (buffer-name)
  "Get a log buffer status by BUFFER-NAME."
  (if (s-contains? buffer-name elogcat-logcat-command)
      (concat (s-word-initials buffer-name) "|")
    "-|"))

(defun elogcat-make-status (&optional status)
  "Get a log buffer STATUS for use in the mode line."
  (concat " elogcat["
          (mapconcat (lambda (args) (elogcat-get-log-buffer-status args))
                     '("main" "system" "events" "radio") "")
          (if elogcat-enable-klog "k" "-") "]"))

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
  (let ((buffer-read-only nil)
        msg)
    (goto-char (point-max))
    (setq msg (concat "======== " (symbol-name filter) " is cleared ========\n"))
    (insert
     (propertize msg 'font-lock-face (cdr (assoc "I" elogcat-face-alist))))
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
          (info-face (cdr (assoc "I" elogcat-face-alist)))
          msg)
      (goto-char (point-max))
      (setq msg (concat "======== " (symbol-name filter)
                        " '" regexp "' ========\n"))
      (insert (propertize msg 'font-lock-face info-face))
      (set filter regexp))))

(defun elogcat-show-status ()
  "Show current status."
  (interactive)
  (let ((buffer-read-only nil)
        msg)
    (goto-char (point-max))
    (setq msg (concat (symbol-name 'elogcat-include-filter-regexp)
                      ": '" elogcat-include-filter-regexp "' ,"
                      (symbol-name 'elogcat-exclude-filter-regexp)
                      ": '" elogcat-exclude-filter-regexp "'\n"))
    (insert (propertize msg 'font-lock-face (cdr (assoc "I" elogcat-face-alist))))))

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
  "Test PROCESS EVENT."
)

(defun elogcat-toggle-kernel ()
  "Toggle kernel log."
  (interactive)
  (setq elogcat-enable-klog (not elogcat-enable-klog))
  (elogcat-stop)
  (elogcat))

(defmacro elogcat-define-toggle-function (sym buffer-name)
  "Define a function with SYM and BUFFER-NAME."
  (let ((fun (intern (format "elogcat-toggle-%s" sym)))
        (doc (format "Switch to %s" buffer-name)))
    `(progn
       (defun ,fun () ,doc
              (interactive)
              (let ((option (concat "-b " ,buffer-name)))
                (if (s-contains? option elogcat-logcat-command)
                    (setq elogcat-logcat-command
                          (mapconcat (lambda (args) (concat (s-trim args)))
                                     (s-split option elogcat-logcat-command) " "))
                  (setq elogcat-logcat-command
                        (s-concat (s-trim elogcat-logcat-command) " " option))))
              (elogcat-stop)
              (elogcat)))))

(elogcat-define-toggle-function events "events")
(elogcat-define-toggle-function system "system")
(elogcat-define-toggle-function main "main")
(elogcat-define-toggle-function radio "radio")

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
          ("q" . elogcat-delete-window)
          ("m" . elogcat-toggle-main)
          ("s" . elogcat-toggle-system)
          ("e" . elogcat-toggle-events)
          ("r" . elogcat-toggle-radio)
          ("k" . elogcat-toggle-kernel))
  (define-key elogcat-mode-map (read-kbd-macro (car it)) (cdr it)))

(define-minor-mode elogcat-mode
  "Minor mode for elogcat"
  :lighter elogcat-mode-line
  nil " elogcat" elogcat-mode-map)

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
                                               (when elogcat-enable-klog
                                                 (concat
                                                  " & " elogcat-klog-command))))))))
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
