;;; run-stuff.el --- context based command execution -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-run-stuff
;; Package-Version: 20201109.351
;; Package-Commit: 80661d33cf705c1128975ab371b3ed4139e4e0f8
;; Version: 0.0.1
;; Keywords: files lisp files convenience hypermedia
;; Package-Requires: ((emacs "24.4"))

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

;; Run commands from the region or current line,
;; with some simple specifiers to control behavior.

;;; Usage

;; (run-stuff-command-on-region-or-line)
;;
;; A command to execute the current selection or the current line.
;;
;; - '$ ' Run in terminal.
;; - '@ ' Open in an Emacs buffer.
;; - '~ ' Open with default mime type (works for paths too).
;; - 'http://' or 'https://' opens in a web-browser.
;; - Open in terminal if its a directory.
;; - Default to running the command without a terminal
;;   when none of the conditions above succeed.
;;
;; Note that there is support for line splitting,
;; so long commands may be split over multiple lines.
;; This is done using the '\' character, when executing the current line
;; all surrounding lines which end with '\' will be included.
;;
;; So you can for define a shell command as follows:
;;
;; $ make \
;;   -C /my/project \
;;   --no-print-directory \
;;   --keep-going
;;
;; The entire block will be detected so you can run the command
;; with your cursor over any of these lines, without needing to move to the first.

;;; Code:

(defcustom run-stuff-open-command "xdg-open"
  "Used to run open files with their default mime type."
  :group 'run-stuff
  :safe #'stringp
  :type 'string)

(defcustom run-stuff-terminal-command "xterm"
  "Used to run commands in a terminal, the following text is to be executed."
  :group 'run-stuff
  :safe #'stringp
  :type 'string)

(defcustom run-stuff-terminal-execute-arg "-e"
  "Passed to the terminal to execute a command."
  :group 'run-stuff
  :safe #'stringp
  :type 'string)


(require 'subr-x)

(defun run-stuff--extract-split-lines (line-terminate-char)
  "Extract line(s) at point.
Multiple lines (below the current) are extracted
if they end with LINE-TERMINATE-CHAR.
Returns the line(s) as a string with no properties."
  (interactive)
  (save-excursion
    (let
      (
        (start (line-beginning-position))
        (iterate t)
        ;; Use later.
        (end nil)
        (new-end nil)
        (new-end-ws nil)
        (end-ws nil))
      (setq end start)
      (while iterate
        (setq new-end (line-end-position))
        ;; could be more efficient?
        (setq new-end-ws
          (save-excursion
            (end-of-line)
            (skip-syntax-backward "-")
            (point)))
        (if (> new-end end)
          (progn
            (setq end new-end)
            (setq end-ws new-end-ws)
            (let ((end-ws-before (char-before end-ws)))
              (if (and end-ws-before (char-equal end-ws-before line-terminate-char))
                (forward-line)
                (setq iterate nil))))
          (setq iterate nil)))
      (buffer-substring-no-properties start end))))

(defun run-stuff--extract-split-lines-search-up (line-terminate-char)
  "Wrapper for run-stuff--extract-split-lines that detects previous lines.
Argument LINE-TERMINATE-CHAR is used to wrap lines."
  (interactive)
  (save-excursion
    (let
      (
        (prev (line-beginning-position))
        (iterate t)
        ;; Use later.
        (end-ws nil)
        (above-new-end-ws nil))
      (while iterate
        ;; could be more efficient?
        (setq above-new-end-ws
          (save-excursion
            (forward-line -1)
            (end-of-line)
            (skip-syntax-backward "-")
            (point)))
        (if (< above-new-end-ws prev)
          (progn
            (setq prev above-new-end-ws)
            (setq end-ws above-new-end-ws)
            (let ((end-ws-before (char-before end-ws)))
              (if (and end-ws-before (char-equal end-ws-before line-terminate-char))
                (forward-line -1)
                (setq iterate nil))))
          (setq iterate nil)))
      (run-stuff--extract-split-lines line-terminate-char))))


(defun run-stuff--extract-split-lines-search-up-joined (line-terminate-char)
  "Wrapper for run-stuff--extract-split-lines-search-up that joins the string.
Argument LINE-TERMINATE-CHAR is used to wrap lines."
  (let ((line-terminate-str (char-to-string line-terminate-char)))
    (mapconcat
      (function
        (lambda (s) (string-trim-right (string-remove-suffix line-terminate-str (string-trim s)))))
      (split-string (run-stuff--extract-split-lines-search-up line-terminate-char) "\n") " ")))


;;;###autoload
(defun run-stuff-command-on-region-or-line ()
  "Run selected text in a terminal or use the current line."
  (interactive)
  (let
    (
      (command
        (if (use-region-p)
          (buffer-substring (region-beginning) (region-end)) ;; current selection
          ;; (thing-at-point 'line t) ;; current line
          ;; a version that can extract multiple lines!
          (run-stuff--extract-split-lines-search-up-joined ?\\)))
      ;; Run from the current buffers directory.
      (default-directory
        (if (buffer-file-name)
          (file-name-directory (buffer-file-name))
          ;; Use existing value as fallback.
          default-directory)))
    (cond
      ;; Run as command in terminal.
      ((string-prefix-p "$ " command)
        (call-process
          run-stuff-terminal-command
          nil
          0
          nil
          run-stuff-terminal-execute-arg
          (string-trim-left (string-remove-prefix "$ " command))))
      ((string-prefix-p "@ " command)
        (switch-to-buffer
          (find-file-noselect
            (expand-file-name (string-trim-left (string-remove-prefix "@ " command))))))
      ;; Open the file with the default mime type.
      ((string-prefix-p "~ " command)
        (call-process
          run-stuff-open-command
          nil
          0
          nil
          (string-trim-left (string-remove-prefix "~ " command))))
      ;; Open the URL (web browser)
      ((or (string-prefix-p "http://" command) (string-prefix-p "https://" command))
        ;; Would use 'browse-url', but emacs doesn't disown the process.
        (call-process run-stuff-open-command nil 0 nil command))
      ;; Open terminal at path.
      ((file-directory-p command)
        ;; Expand since it may be relative to the current file.
        (let ((default-directory (expand-file-name command)))
          (call-process run-stuff-terminal-command nil 0 nil)))
      ;; Default, run directly without a terminal.
      (t
        (call-process-shell-command command nil 0)))))

(provide 'run-stuff)
;;; run-stuff.el ends here
