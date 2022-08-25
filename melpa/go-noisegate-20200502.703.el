;;; go-noisegate.el --- Run Golang tests with Noise Gate -*- lexical-binding: t; -*-

;; Author: The Noise Gate Authors
;; Version: 0.1.0
;; Package-Version: 20200502.703
;; Package-Commit: 825d1fb05ec329f938c4c5bed23592f54d326f80
;; Package-Requires: ((emacs "24.4"))
;; Keywords: languages, go, test
;; URL: https://github.com/go-noisegate/go-noisegate.el

;; Copyright 2020 The Noise Gate Authors
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;; http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;;; Commentary:

;; Run Golang tests with Noise Gate.
;;
;; Noise Gate is the Golang test runner to get faster test results.
;; It selects the tests affected by your recent edits and run them using `go test`.
;;
;; Check https://github.com/go-noisegate/go-noisegate.el for details.

;;; Code:

(require 'compile)

;;; group, vars and mode

(defgroup go-noisegate nil
  "Noise Gate utility"
  :group 'go)

(defvar go-noisegate-history (list "-v ")
  "History list for args.")

(defvar-local go-noisegate-changes nil
  "Change list [(begin, end)]")

(defvar go-noisegate-gate-cmd ""
  "The path to the gate command.")

(define-derived-mode go-noisegate-mode compilation-mode "Noise Gate"
  "Major mode for Noise Gate")

;;; internal funcs

(defun go-noisegate--clear-buffer (buffer)
  "Kill the BUFFER process and clear the BUFFER."
  (when (get-buffer buffer)
    (when (get-buffer-process (get-buffer buffer))
      (delete-process buffer))
    (with-current-buffer buffer
      (setq buffer-read-only nil)
      (erase-buffer))))

(defun go-noisegate--buffer-name (_mode-name)
  "Return the buffer name."
  "*Noise Gate*")

(defun go-noisegate--get-args (history)
  "Get the go test options.
When the prefix arg is not given, the first element of HISTORY is used.
When the single prefix arg is given, a user is prompted."
  (pcase current-prefix-arg
    (`nil (car (symbol-value history)))
    (`(4) (read-shell-command "go test args: " (car (symbol-value history)) history))))

(defun go-noisegate--get-offset (ch)
  "Make the string representation of CH which the noise gate server can parse."
  (format "#%d-%d" (- (car ch) 1) (- (nth 1 ch) 1)))  ;; emacs offset is 1-based

(defun go-noisegate--get-offsets ()
  "Make the string representation of changes."
  (mapconcat #'go-noisegate--get-offset go-noisegate-changes ","))

(defun go-noisegate--record-change (begin end length)
  "Record the change.  Assumes [BEGIN, END] (both inclusive).
LENGTH is not used."
  (if (> begin end)
    (go-noisegate--record-change end begin length)
    (let ((last-change (car go-noisegate-changes)))
      (if (and last-change
               (<= (car last-change) (+ end 1))
               (<= (- begin 1) (nth 1 last-change)))
          (setcar go-noisegate-changes (list (min (car last-change) begin) (max (nth 1 last-change) end)))
        (add-to-list 'go-noisegate-changes (list begin end))))))

(defun go-noisegate--reset-changes ()
  "Reset the changes so far."
  (setq go-noisegate-changes nil))

(defun go-noisegate--find-gopath ()
  "Find GOPATH."
  (with-temp-buffer
    (call-process "go" nil (current-buffer) nil "env" "GOPATH")
    ;; trim right
    (car (split-string (buffer-string)))))

(defun go-noisegate--find-gate-command ()
  "Find the gate command."
  (let ((cmd-in-gopath (concat (go-noisegate--find-gopath) "/bin/gate")))
    (if (file-exists-p cmd-in-gopath) cmd-in-gopath "gate")))

(defun go-noisegate--get-gate-command ()
  "Get the gate command."
  (if (string= "" go-noisegate-gate-cmd)
      (setq go-noisegate-gate-cmd (go-noisegate--find-gate-command))
    go-noisegate-gate-cmd))

;;; API

;;;###autoload
(defun go-noisegate-record-change (begin end length)
  "Record the change (BEGIN and END).  LENGTH is not used."
  (interactive)
  (when (string-suffix-p ".go" buffer-file-name)
    (go-noisegate--record-change begin (- end 1) length)))

;;;###autoload
(defun go-noisegate-hint ()
  "Send the list of changes to the server."
  (interactive)
  (when (and (string-suffix-p ".go" buffer-file-name) go-noisegate-changes)
    (let ((offsets (go-noisegate--get-offsets)))
      (go-noisegate--reset-changes)
      (start-process "go-noisegate-hint" "*Messages*" (go-noisegate--get-gate-command) "hint" (concat buffer-file-name ":" offsets)))))

;;;###autoload
(defun go-noisegate-test ()
  "Run the tests affected by the recent changes."
  (interactive)
  (when (string-suffix-p ".go" buffer-file-name)
    (let ((buffer "*Noise Gate*")
          (offset (go-noisegate--get-offset (list (point) (point)))))
      (go-noisegate--clear-buffer buffer)
      (call-process (go-noisegate--get-gate-command) nil nil nil "hint" (concat buffer-file-name ":" offset))
      (compilation-start (concat (go-noisegate--get-gate-command) " test "  (file-name-directory buffer-file-name) " -- " (go-noisegate--get-args 'go-noisegate-history))
                         'go-noisegate-mode
                         'go-noisegate--buffer-name)
      (with-current-buffer "*Noise Gate*"
        (rename-buffer buffer)))))

;;;###autoload
(defun go-noisegate-test-all ()
  "Run all the tests in the current package regardless of the recent changes."
  (interactive)
  (when (string-suffix-p ".go" buffer-file-name)
    (let ((buffer "*Noise Gate*"))
      (go-noisegate--clear-buffer buffer)
      (compilation-start (concat (go-noisegate--get-gate-command) " test -bypass " (file-name-directory buffer-file-name) " -- " (go-noisegate--get-args 'go-noisegate-history))
                         'go-noisegate-mode
                         'go-noisegate--buffer-name)
      (with-current-buffer "*Noise Gate*"
        (rename-buffer buffer)))))

(provide 'go-noisegate)
;;; go-noisegate.el ends here
