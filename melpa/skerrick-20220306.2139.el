;;; skerrick.el --- REPL-driven development for NodeJS -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2022 Rafael Nicdao
;;
;; Author: Rafael Nicdao <https://github.com/anonimitoraf>
;; Maintainer: Rafael Nicdao <nicdaoraf@gmail.com>
;; Created: January 01, 2022
;; Modified: January 01, 2022
;; Version: 0.0.1
;; Package-Version: 20220306.2139
;; Package-Commit: fc88e82aa4b0a71b1fbe0217df4020538ebd8cd5
;; Keywords: languages javascript js repl repl-driven
;; Homepage: https://github.com/anonimitoraf/skerrick
;; Package-Requires: ((emacs "27.1") (request "0.3.2"))
;;
;; This file is not part of GNU Emacs.
;;
;; skerrick is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; skerrick is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with skerrick. If not, see <https://www.gnu.org/licenses/>.
;;
;;; Commentary:
;; REPL-driven development for NodeJS. See https://github.com/anonimitoraf/skerrick for more info.
;;
;;; Code:

(require 'cl-lib)
(require 'request)

(defface skerrick-result-overlay-face
  '((((class color) (background light))
     :background "grey90"
     :foreground "black"
     :box (:line-width -1 :color "#ECBE7B"))
    (((class color) (background dark))
     :background "grey10"
     :foreground "#ECBE7B"
     :box (:line-width -1 :color "#ECBE7B")))
  "Face used to display evaluation results at the end of line."
  :group 'skerrick)

(defvar skerrick-server-port 4321)
(defvar skerrick-result-overlay-char-count-trunc 120
  "If the evaluation result is longer than this, then it's truncated.")
(defvar skerrick-pop-result-buffer-for-stdout t
  "Show the result buffer if stderr is non-empty.")
(defvar skerrick-pop-result-buffer-for-stderr t
  "Show the result buffer if stderr is non-empty.")

(defvar skerrick--result-buffer "*skerrick-result*")
(defvar skerrick--eval-overlay nil)
(defvar skerrick--remove-eval-overlay-on-next-cmd? nil)
(defvar skerrick--hooks-setup? nil)

(defun skerrick--propertize-error (error)
  "Style ERROR msg."
  (propertize error 'face '(:foreground "red")))

(defun skerrick--display-overlay (value face)
  "Show an overlay containing VALUE customized by FACE."
  (overlay-put skerrick--eval-overlay 'before-string
               (propertize value 'face face)))

(defun skerrick--append-to-process-buffer (value &optional show-buffer?)
  "Append VALUE to designated buffer. Optionally, SHOW-BUFFER."
  (save-excursion
    (with-current-buffer (get-buffer-create skerrick--result-buffer)
      (read-only-mode -1)
      (goto-char (point-max))           ; Append to buffer
      (insert value ?\n)
      (read-only-mode +1))
    (when show-buffer?
      (display-buffer-in-side-window (get-buffer-create skerrick--result-buffer) '((side . right)))
      ;; TODO Scroll down the result buffer/window to the bottom
      )))

(defun skerrick--process-server-response (response)
  "Process RESPONSE from skerrick server."
  (let* ((stdout (string-trim (alist-get 'stdout response)))
         (stderr (string-trim (alist-get 'stderr response)))
         (result (alist-get 'result response))
         (result-str (if result (json-encode result) "undefined")))
    (skerrick--append-to-process-buffer (format "[RESULT] %s" result-str))
    (unless (zerop (length stdout))
      (skerrick--append-to-process-buffer (format "[STDOUT] %s" stdout)
        skerrick-pop-result-buffer-for-stdout))
    (unless (zerop (length stderr))
      (skerrick--append-to-process-buffer (format "[STDERR] %s" (skerrick--propertize-error stderr))
        skerrick-pop-result-buffer-for-stderr))
    (skerrick--display-overlay (format " => %s " (if (> (length result-str) skerrick-result-overlay-char-count-trunc)
                                                   (format "%s (result truncated, see buffer %s)"
                                                     (truncate-string-to-width result-str skerrick-result-overlay-char-count-trunc nil nil t)
                                                     skerrick--result-buffer)
                                                   result-str))
      'skerrick-result-overlay-face)
    (setq skerrick--remove-eval-overlay-on-next-cmd? t)))

(defun skerrick--send-eval-req (code module-path)
  "Send CODE and MODULE-PATH to sever."
  (request
    (concat "http://localhost:" (prin1-to-string skerrick-server-port) "/eval")
    :type "POST"
    :data (json-encode `(("code" . ,code)
                          ("modulePath" . ,module-path)))
    :parser 'json-read
    :encoding 'utf-8
    :headers '(("Content-Type" . "application/json"))
    :success (cl-function (lambda (&key data &allow-other-keys)
                            (skerrick--process-server-response data)))))

(defun skerrick-remove-eval-overlay ()
  "Remove eval overlay."
  (interactive)
  (when (overlayp skerrick--eval-overlay)
    (delete-overlay skerrick--eval-overlay)
    (setq skerrick--remove-eval-overlay-on-next-cmd? nil)))

;;;###autoload
(defun skerrick-eval-region ()
  "Evaluate the selected JS code."
  (interactive)
  (unless skerrick--hooks-setup?
    (add-hook 'post-command-hook (lambda () (when skerrick--remove-eval-overlay-on-next-cmd?
                                         (skerrick-remove-eval-overlay))))
    (setq skerrick--hooks-setup? t))
  (let* ((beg (region-beginning))
          (end (region-end))
          (selected-code (format "%s" (buffer-substring-no-properties beg end)))
          (file-path (buffer-file-name)))
    ;; Clean up previous eval overlay
    (skerrick-remove-eval-overlay)
    (save-excursion
      (goto-char end)
      ;; Make sure the overlay is actually at the end of the evaluated region, not on a newline
      (skip-chars-backward "\r\n[:blank:]")
      ;; Seems like the END arg of make-overlay is useless. Just use the same value as BEGIN
      (setq skerrick--eval-overlay (make-overlay (point) (point) (current-buffer))))
    (skerrick--append-to-process-buffer (format "\n[EVAL - %s]\n%s" file-path selected-code))
    (skerrick--send-eval-req selected-code file-path)))

;;;###autoload
(defun skerrick-install-or-upgrade-server-binary ()
  "Install or upgrade skerrick from NPM."
  (interactive)
  (async-shell-command "npm install -g skerrick"))

(defvar skerrick-process nil)

;;;###autoload
(defun skerrick-start-server ()
  "Start skerrick server."
  (interactive)
  (if (and skerrick-process (process-live-p skerrick-process))
    (message "Skerrick server already running")
    (progn
      (setq skerrick-process (start-process "skerrick-server" "*skerrick-server*"
                              "skerrick" (prin1-to-string skerrick-server-port) (buffer-file-name)))
      (message "Started skerrick server on %s" skerrick-server-port))))

;;;###autoload
(defun skerrick-stop-server ()
  "Stop skerrick server."
  (interactive)
  (if (and skerrick-process (process-live-p skerrick-process))
    (progn
      (stop-process skerrick-process)
      (setq skerrick-process nil)
      (message "Stopped skerrick server"))
    (message "No running skerrick server")))

(provide 'skerrick)
;;; skerrick.el ends here
