;;; sqlite.el --- Use sqlite via ELisp  -*- lexical-binding: t; -*-
;;

;; Copyright 2020 cnngimenez
;;
;; Author: cnngimenez
;; Maintainer: cnngimenez
;; Contributors: mariotomo, cnngimenez, kidd
;; Description: SQLite interface for ELisp
;; Version: 1.0
;; Package-Version: 20201227.1822
;; Package-Commit: f3da716302c929b9df4ba0c281968f72a9d1d188
;; Keywords: extensions, lisp, sqlite
;; URL: https://gitlab.com/cnngimenez/sqlite.el
;; Package-Requires: ((emacs "24.5"))

;; This program is free software: you can redistribute it and/or modify
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
;; For usage and explanations see https://www.emacswiki.org/emacs/SQLite-el.
;;
;; 1 sqlite.el
;; ═══════════
;;
;;   SQLite Interface through Elisp programming.
;;
;;
;; 2 From EmacsWiki
;; ════════════════
;;
;;   This code was retrieved from the EmacsWiki at december 26, 2013.
;;
;;   Contributors:
;;
;;   ⁃ @mariotomo (Mario Frasca)
;;   ⁃ @cnngimenez
;;   ⁃ @kidd (Raimon Grau)
;;
;;
;; 3 Features
;; ══════════
;;
;;   This interface has the following features:
;;
;;   • Can connect to several database files.
;;   • No output buffer shown. The output buffer is hidden when using the
;;     interface.
;;   • SQLite errors match.
;;   • Files does not need to be in absolute path. It is expanded using
;;     `expand-file-name' command.
;;   • Timeout sub-process output retrieving for each result row. See
;;     `sqlite-response-timeout' variable.
;;
;;
;; 4 Usage
;; ═══════
;;
;;   See usage and more information at the [SQLite EmacsWiki page].
;;
;;   Here is an example to query the database:
;;
;;   ┌────
;;   │ (require 'sqlite)
;;   │
;;   │ typical usage involves three functions
;;   │ (let ((db (sqlite-init "~/mydb.sqlite")))  open connection
;;   │   (unwind-protect  perform body, return value, then clean up
;;   │       (let ((res (sqlite-query db "SELECT * FROM my_table")))
;;   │ 	Make more queries...  more calculations ...
;;   │ 	...
;;   │ 	res)  the return value
;;   │     (sqlite-bye db)))  close connection
;;   └────
;;
;;
;; [SQLite EmacsWiki page] <https://www.emacswiki.org/emacs/SQLite-el>
;;
;;
;; 5 Licence
;; ═════════
;;
;;   This work is under the GNU GPLv3 licence.
;;
;;
;; 6 Happy Coding!
;; ═══════════════

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'shell)

;; Adapted from:
;; https://web.archive.org/web/*/http://mysite.verizon.net/mbcladwell/sqlite.html#connect

(defvar sqlite-program "sqlite3"
  "Name the SQLite3 executable.  If not in $PATH, please specify full path.")

(defvar sqlite-output-buffer "*sqlite-output*"
  "Name of the SQLite output buffer.")

(defvar sqlite-include-headers nil
  "If non-nil, include headers in query results.")

(defvar sqlite-response-timeout 0.4
  "Timeout for the next result line.")

;; Process list storing and manipulation
;; ----------------------------------------

(defvar sqlite-process-plist nil
  "Contains each descriptor with their buffers.
A plist that associates descriptor to buffer process and databse file.
process and the file opened.
Example:
'(1 (\"*sqlite-process1*\" \"~/mydb1.sqlite\")
  2 (\"*sqlite-process2*\" \"~/databases/mydb2.sqlite\"))")

(defvar sqlite-descriptor-counter 0
  "This is a counter that adds 1 for each sqlite process opened.
Used for referencing each sqlite process uniquely.")

(defun sqlite-register-descriptor (descriptor buffer file)
  "Register DESCRIPTOR with the buffer BUFFER and FILE.
Registering is adding the proper association into `sqlite-process-plist'."
  (setq sqlite-process-plist (plist-put sqlite-process-plist descriptor `(,buffer ,file))))

(defun sqlite-descriptor-buffer (descriptor)
  "Return the buffer associated to the DESCRIPTOR."
  (car (plist-get sqlite-process-plist descriptor)))

(defun sqlite-descriptor-database (descriptor)
  "Return the database file associated to the DESCRIPTOR."
  (cadr (plist-get sqlite-process-plist descriptor)))

(defun sqlite-unregister-descriptor (descriptor)
  "Remove DESCRIPTOR from the list of process buffers `sqlite-process-plist'."
  (setq sqlite-process-plist (plist-put sqlite-process-plist descriptor nil)))

;; ----------------------------------------

(defun sqlite-init (db-file)
  "Initialize sqlite interface opening the DB-FILE sqlite file.
This starts the process given by `sqlite-program' and prepares it
for queries.  Return the sqlite process descriptor, a unique id
that you can use to retrieve the process or send a query."
  (let* ((db-file (expand-file-name db-file))
         (comint-use-prompt-regexp t)
         (comint-prompt-regexp "^\\(sqlite\\)?>")
         (process-buffer (make-comint
                          (format "sqlite-process-%04d" sqlite-descriptor-counter)
                          sqlite-program nil db-file))
         (process (get-buffer-process process-buffer)))
    (unless process
      (error "Can't create new process"))
    (save-excursion
      (condition-case nil
          (set-buffer process-buffer)
        (error))
      (shell-mode))
    (sqlite-register-descriptor sqlite-descriptor-counter process-buffer db-file)
    (cl-incf sqlite-descriptor-counter)
    (while (accept-process-output process sqlite-response-timeout))
    (comint-redirect-send-command-to-process ".mode list" sqlite-output-buffer process nil t)
    (comint-redirect-send-command-to-process ".separator |" sqlite-output-buffer process nil t)
    ;; configure whether headers are desired or not
    (comint-redirect-send-command-to-process
     (if sqlite-include-headers ".headers on" ".headers off")
     sqlite-output-buffer process nil t)
    (comint-redirect-send-command-to-process ".prompt \"> \"\"...> \"" sqlite-output-buffer process nil t)
    (while (accept-process-output process sqlite-response-timeout))
    (get-buffer-create sqlite-output-buffer))
  (1- sqlite-descriptor-counter))

(defun sqlite-bye (descriptor &optional noerror)
  "Finish the sqlite process sending the \".quit\" command.
Returns t if everything is fine.
nil if the DESCRIPTOR points to a non-existent process buffer.
If NOERROR is t, then will not signal an error when the DESCRIPTOR is not registered."
  (let* ((comint-use-prompt-regexp t)
         (comint-prompt-regexp "^\\(sqlite\\)?>")
         (process-buffer (sqlite-descriptor-buffer descriptor))
         (process (get-buffer-process process-buffer)))
    (if (get-buffer-process process-buffer)
        (progn ;; Process buffer exists... unregister it
          (set-process-query-on-exit-flag (get-process process) nil)
          (comint-redirect-send-command-to-process ".quit" sqlite-output-buffer process nil t)
          (while (accept-process-output process sqlite-response-timeout))
          (sqlite-unregister-descriptor descriptor)
          (kill-buffer process-buffer)
          t)
      (progn
        (sqlite-unregister-descriptor descriptor) ;; We unregister the descriptor nevertheless
        (unless noerror
          (error "Process buffer doesn't exists for that descriptor"))
        nil))))

(defun sqlite-parse-line ()
  "Parse result line at point, returning the list column values.
Empty is replaced with nil."
  (let* ((line (string-trim (thing-at-point 'line))))
    (mapcar (lambda (item)
              (and (not (equal item ""))
                   item))
            (mapcar #'string-trim (split-string line "|")))))

(defun sqlite-parse-result ()
  "Parse the lines in the current buffer into a list of lists.
This is intended to be called with *sqlite-output* being the
current buffer, but it's up to the caller to make sure, this
function will not enforce it.  The first line can be a header
line, depending on the value of sqlite-include-headers.  The
result looks like this: (header-list row1-list row2-list
row3-list)"
  (let ((num-lines (count-lines (goto-char (point-min)) (point-max)))
        (results-rows nil))
    (if (sqlite-error-line) ;; Check if it is an error line
        (error (concat "SQLite process error:" (string-trim (buffer-string)))))
    (dotimes (_counter num-lines)
      (push (sqlite-parse-line) results-rows)
      (forward-line))
    (nreverse results-rows)))

(defconst sqlite-regexp-error "Error:\\(.*\\)$"
  "Regexp used to match the error returned by SQLite process.
There must be a parenthesis surrounding the error message for matching it with:
    `match-string' 1
This is used for `sqlite-check-errors' for raising errors with messages.")

(defun sqlite-error-line ()
  "Return t if the current line match the `sqlite-regexp-error'.
Else, return nil."
  ;; (with-current-buffer sqlite-output-buffer
    (let ((line (thing-at-point 'line)))
      (cond ((null line) nil)
	    ((string-match sqlite-regexp-error (string-trim line)) t)
	    (t nil))))

(defvar sqlite-regexp-sqlite-command "^\\..*"
  "Regexp that match an SQLite command.
This is used for identifying which is an SQL command and which is a proper
SQLite command.")

(defun sqlite-prepare-query (sql-command)
  "Add a query terminator to SQL-COMMAND if necessary.
SQLite commands start with \".\" and don't need terminator."
  (cond ((string-match "^\\." sql-command)
         sql-command)
        ((string-match ";$" sql-command)
         sql-command)
        (t (concat sql-command ";"))))

(defun sqlite-query (descriptor sql-command)
  "Send a query to the SQLite process and return the result.
DESCRIPTOR is the Sqlite instance descriptor given by `sqlite-init'.
SQL-COMMAND is a string with the the SQL command.
Return list of lists, as
    (header-list row1-list row2-list row3-list)"
  (let* ((comint-use-prompt-regexp t)
         (comint-prompt-regexp "^\\(sqlite\\)?>")
         (process-buffer (sqlite-descriptor-buffer descriptor))
         (process (get-buffer-process process-buffer)))
    (unless process
      (error "SQLite process buffer doesn't exist!"))
    (with-current-buffer sqlite-output-buffer
      (erase-buffer)
      (comint-redirect-send-command-to-process
       (sqlite-prepare-query sql-command)
       sqlite-output-buffer process nil t)
      (while (accept-process-output process sqlite-response-timeout))
      (sqlite-parse-result))))

(provide 'sqlite)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; sqlite.el ends here

