;;; run-stuff.el --- Context based command execution -*- lexical-binding: t; -*-

;; Copyright (C) 2017  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-run-stuff
;; Package-Version: 20211007.304
;; Package-Commit: db66c1ca0f6a090f8c9ae17f80f99c878047778e
;; Version: 0.0.2
;; Keywords: files lisp files convenience hypermedia
;; Package-Requires: ((emacs "25.1"))

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
;; A command to execute the current selection or the current line
;; using the default `run-stuff-handlers' variable.
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

;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup run-stuff nil "Context based command execution." :group 'tools)

(defcustom run-stuff-open-command "xdg-open"
  "Used to run open files with their default mime type."
  :safe #'stringp
  :type 'string)

(defcustom run-stuff-terminal-command "xterm"
  "Used to run commands in a terminal, the following text is to be executed."
  :safe #'stringp
  :type 'string)

(defcustom run-stuff-terminal-execute-arg "-e"
  "Passed to the terminal to execute a command."
  :safe #'stringp
  :type 'string)

(defcustom run-stuff-handlers
  (list
    (list ;; Open the file in Emacs: "@ " prefix.
      'run-stuff-extract-multi-line
      #'
      (lambda (command)
        (let ((command-test (run-stuff-test-prefix-strip command "^@[[:blank:]]+")))
          (when command-test
            (run-stuff-handle-file-open-in-buffer command-test)))))
    (list ;; Open the file with the default mime type: "~ " prefix.
      'run-stuff-extract-multi-line
      #'
      (lambda (command)
        (let ((command-test (run-stuff-test-prefix-strip command "^~[[:blank:]]+")))
          (when command-test
            (run-stuff-handle-file-default-mime command-test)))))

    (list ;; Open in a shell: "$ " prefix.
      'run-stuff-extract-multi-line
      #'
      (lambda (command)
        (let ((command-test (run-stuff-test-prefix-strip command "^\\$[[:blank:]]+")))
          (when command-test
            (run-stuff-handle-shell command-test)))))
    (list ;; Open the URL (web browser).
      'run-stuff-extract-multi-line
      #'
      (lambda (command)
        (let ((command-test (run-stuff-test-prefix-match command "^http[s]*://[^[:blank:]\n]+")))
          (when command-test
            (run-stuff-handle-url command-test)))))
    (list ;; Open the terminal at a directory.
      'run-stuff-extract-multi-line
      #'
      (lambda (command)
        (let ((command-test (and (file-directory-p command) command)))
          (when command-test
            (run-stuff-handle-directory-in-terminal command-test))))))

  "A list of lists, each defining a handler.

First (extract function)
  Return a string from the current context (typically the current line).
Second (handle function)
  Take the result of the extract function and run the function
  if it matches or return nil.

The handlers are handled in order, first to last.
On success, no other handlers are tested.

This can be made a buffer local variable to customize this for each mode."
  :type 'list)


;; ---------------------------------------------------------------------------
;; Internal Functions/Macros

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
        (cond
          ((> new-end end)
            (setq end new-end)
            (setq end-ws new-end-ws)
            (let ((end-ws-before (char-before end-ws)))
              (cond
                ((and end-ws-before (char-equal end-ws-before line-terminate-char))
                  (forward-line))
                (t
                  (setq iterate nil)))))
          (t
            (setq iterate nil))))
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
        (cond
          ((< above-new-end-ws prev)
            (setq prev above-new-end-ws)
            (setq end-ws above-new-end-ws)
            (let ((end-ws-before (char-before end-ws)))
              (cond
                ((and end-ws-before (char-equal end-ws-before line-terminate-char))
                  (forward-line -1))
                (t
                  (setq iterate nil)))))
          (t
            (setq iterate nil))))
      (run-stuff--extract-split-lines line-terminate-char))))


(defun run-stuff--extract-split-lines-search-up-joined (line-terminate-char)
  "Wrapper for run-stuff--extract-split-lines-search-up that joins the string.
Argument LINE-TERMINATE-CHAR is used to wrap lines."
  (let ((line-terminate-str (char-to-string line-terminate-char)))
    (mapconcat
      (function
        (lambda (s) (string-trim-right (string-remove-suffix line-terminate-str (string-trim s)))))
      (split-string (run-stuff--extract-split-lines-search-up line-terminate-char) "\n") " ")))


;; ---------------------------------------------------------------------------
;; Public Utilities

;;;###autoload
(defmacro run-stuff-with-buffer-default-directory (&rest body)
  "Use the buffer directory as the default directory, executing BODY."
  (declare (indent 1))
  `
  (let
    (
      (default-directory
        (let ((filename (buffer-file-name)))
          (cond
            (filename
              (file-name-directory filename))
            (t
              default-directory)))))
    ,@body))


;; ---------------------------------------------------------------------------
;; Extractor Functions

(defun run-stuff-extract-multi-line ()
  "Extract lines from the current buffer, optionally multiple wrapped lines."
  (cond
    ((use-region-p)
      ;; Current selection.
      (buffer-substring (region-beginning) (region-end)))
    (t
      ;; (thing-at-point 'line t) ;; current line
      ;; a version that can extract multiple lines!
      (run-stuff--extract-split-lines-search-up-joined ?\\))))


;; ---------------------------------------------------------------------------
;; Test Functions

(defun run-stuff-test-prefix-strip (command prefix-regex)
  "Strip PREFIX-REGEX from COMMAND if it exists, otherwise nil."
  (save-match-data
    (cond
      ((string-match prefix-regex command)
        (substring command (match-end 0)))
      (t
        nil))))

(defun run-stuff-test-prefix-match (command prefix-regex)
  "Strip PREFIX-REGEX from COMMAND if it exists, otherwise nil."
  (save-match-data
    (when (string-match prefix-regex command)
      (match-string-no-properties 0 command))))


;; ---------------------------------------------------------------------------
;; Handler Functions

(defun run-stuff-handle-file-open-in-buffer (command)
  "Open COMMAND as a buffer."
  (run-stuff-with-buffer-default-directory
    (switch-to-buffer (find-file-noselect (expand-file-name command)))
    t))

(defun run-stuff-handle-file-default-mime (command)
  "Open COMMAND using the default mime handler."
  (run-stuff-with-buffer-default-directory
    (call-process run-stuff-open-command nil 0 nil command)))

(defun run-stuff-handle-shell (command)
  "Open COMMAND in a terminal."
  (run-stuff-with-buffer-default-directory
    (call-process run-stuff-terminal-command nil 0 nil run-stuff-terminal-execute-arg command)
    t))

(defun run-stuff-handle-url (command)
  "Open COMMAND as a URL."
  ;; Would use 'browse-url', but emacs doesn't disown the process.
  (run-stuff-with-buffer-default-directory
    (call-process run-stuff-open-command nil 0 nil command)
    t))

(defun run-stuff-handle-directory-in-terminal (command)
  "Open COMMAND as a directory in a terminal."
  ;; Expand since it may be relative to the current file.
  (let ((default-directory (expand-file-name command)))
    (call-process run-stuff-terminal-command nil 0 nil)
    t))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun run-stuff-command-on-region-or-line ()
  "Run selected text in a terminal or use the current line."
  (interactive)
  (let
    ( ;; Store function results.
      (extract-fn-cache (list))
      (handlers run-stuff-handlers))
    (while handlers
      (pcase-let ((`(,extract-fn ,handle-fn) (pop handlers)))
        (let ((command (alist-get extract-fn extract-fn-cache)))
          (unless command
            (setq command (funcall extract-fn))
            (push (cons extract-fn command) extract-fn-cache))

          (when (funcall handle-fn command)
            ;; Success, finished.
            (setq handlers nil)))))))

(provide 'run-stuff)
;;; run-stuff.el ends here
