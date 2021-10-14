;;; emacsql-sqlite3.el --- Yet another EmacSQL backend for SQLite -*- lexical-binding: t -*-

;; Copyright (C) 2019 Zhu Zihao

;; Author: Zhu Zihao <all_but_last@163.com>
;; URL: https://github.com/cireu/emacsql-sqlite3
;; Package-Version: 20200914.508
;; Package-Commit: 209fd0c2649db0c7532e543ec12e7ba881a3325c
;; Version: 1.0.2
;; Package-Requires: ((emacs "26.1") (emacsql "3.0.0"))
;; Keywords: extensions

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; [[https://melpa.org/#/emacsql-sqlite3][file:https://melpa.org/packages/emacsql-sqlite3-badge.svg]]
;; [[https://travis-ci.org/cireu/emacsql-sqlite3][file:https://travis-ci.org/cireu/emacsql-sqlite3.svg?branch=master]]

;; * Introduction

;; This is yet another [[https://github.com/skeeto/emacsql][EmacSQL]] backend for SQLite, which use official =sqlite3=
;; executable to access SQL database.

;; * Installation

;; =emacsql-sqlite3= is available on melpa.

;; * Usage

;; For Emacs users, please notice that this package won't provide any feature for
;; convenience. *If you don't sure you need this, you probably don't need this.*

;; For package developers, this package can be a replacement of [[https://github.com/skeeto/emacsql][emacsql-sqlite]] and
;; it doesn't require user to have a C compiler, but please read following
;; precautions.

;; - You need to install =sqlite3= official CLI tool, 3.8.2 version or above were
;;   tested, =emacsql-sqlite3= may won't work if you using lower version.

;; - =sqlite3= CLI tool will load =~/.sqliterc= if presented, =emacsql-sqlite3=
;;   will get undefined behaviour if any error occurred during the load progress.
;;   It's better to keep this file empty.

;; - This package should be compatible with =emacsql-sqlite3= for most cases. But
;;   foreign key support was disabled by default. To enable this feature, use
;;   ~(emacsql <db> [:pragma (= foreign_keys ON)])~

;; The only entry point to a EmacSQL interface is =emacsql-sqlite3=, for more
;; information, please check [[https://github.com/skeeto/emacsql/blob/master/README.md][EmacSQL's README]].

;; * About Closql

;; [[https://github.com/emacscollective/closql][closql]] is using =emacsql-sqlite= as backend, you can use following code to force
;; closql use =emacsql-sqlite3=.

;; #+BEGIN_SRC emacs-lisp :results none
;; (with-eval-after-load 'closql
;;   (defclass closql-database (emacsql-sqlite3-connection)
;;     ((object-class :allocation :class))))
;; #+END_SRC

;; * Known issue

;; The tests don't pass under Emacs 25.1 for unknown reason, so we don't support
;; Emacs 25.1 currently like [[https://github.com/skeeto/emacsql][emacsql-sqlite]]. But any PR to improve this are
;; welcomed.

;;; Code:

(require 'cl-lib)
(require 'eieio)
(require 'emacsql)

(defconst emacsql-sqlite3--cmd-end-mark "#"
  "The string should be printed when a command was executed.")

(defconst emacsql-sqlite3-reserved
  (emacsql-register-reserved
   '(ABORT ACTION ADD AFTER ALL ALTER ANALYZE AND AS ASC ATTACH
     AUTOINCREMENT BEFORE BEGIN BETWEEN BY CASCADE CASE CAST CHECK
     COLLATE COLUMN COMMIT CONFLICT CONSTRAINT CREATE CROSS
     CURRENT_DATE CURRENT_TIME CURRENT_TIMESTAMP DATABASE DEFAULT
     DEFERRABLE DEFERRED DELETE DESC DETACH DISTINCT DROP EACH ELSE END
     ESCAPE EXCEPT EXCLUSIVE EXISTS EXPLAIN FAIL FOR FOREIGN FROM FULL
     GLOB GROUP HAVING IF IGNORE IMMEDIATE IN INDEX INDEXED INITIALLY
     INNER INSERT INSTEAD INTERSECT INTO IS ISNULL JOIN KEY LEFT LIKE
     LIMIT MATCH NATURAL NO NOT NOTNULL NULL OF OFFSET ON OR ORDER
     OUTER PLAN PRAGMA PRIMARY QUERY RAISE RECURSIVE REFERENCES REGEXP
     REINDEX RELEASE RENAME REPLACE RESTRICT RIGHT ROLLBACK ROW
     SAVEPOINT SELECT SET TABLE TEMP TEMPORARY THEN TO TRANSACTION
     TRIGGER UNION UNIQUE UPDATE USING VACUUM VALUES VIEW VIRTUAL WHEN
     WHERE WITH WITHOUT))
  "List of all of SQLite's reserved words.
https://www.sqlite.org/lang_keywords.html")

(defgroup emacsql-sqlite3 ()
  "EmacsSQL, sqlite3 backend."
  :group 'comm)

(defcustom emacsql-sqlite3-executable (executable-find "sqlite3")
  "The path to sqlite3 executable should be used."
  :group 'emacsql-sqlite3
  :type 'file)

(defcustom emacsql-sqlite3-init-file null-device
  "The path to the init file.
The init file can contain a mix of SQL statements and meta-commands.
When non-nil, it is passed to the init flag when starting the sqlite3 process."
  :group 'emacsql-sqlite3
  :type 'file)

(defclass emacsql-sqlite3-connection (emacsql-connection)
  ((file :initarg :file
         :type (or null string)
         :documentation "Database file name.")
   (types :allocation :class
          :reader emacsql-types
          :initform '((integer "INTEGER")
                      (float "REAL")
                      (object "TEXT")
                      (nil nil))))
  "A connection to a SQLite database, using official `sqlite3' executable.")

(defun emacsql-sqlite3--proc-sentinel (proc _change)
  "Called each time when PROC status changed."
  (unless (process-live-p proc)
    (let ((buf (process-buffer proc)))
      (when (buffer-live-p buf)
        (kill-buffer buf)))))

(defun emacsql-sqlite3-run-dot-command (conn command &rest args)
  "Format a dot-command with COMMAND and ARGS, then send it to CONN.

Sign: (-> `emacsql-sqlite3-connection' (U Sym Str) &rest (Listof Str) Nil)

COMMAND can be a symbol/keyword/string, which will be converted to string
if a keyword was presented, heading colon will be removed.

ARGS is list of strings which will be appended to command sequentially,
each arg will be quoted first."
  (let* ((proc (emacsql-process conn))
         (cmd-name (format ".%s" (if (keywordp command)
                                     (substring (symbol-name command) 1)
                                   command))))
    (process-send-string proc (concat cmd-name " "
                                      (mapconcat #'prin1-to-string args " ")
                                      "\n"))
    nil))

;;; Mandatory API

;; Some class don't call superclass's constructor!
(cl-defmethod initialize-instance :after
    ((conn emacsql-sqlite3-connection) _slots)
  (cl-assert emacsql-sqlite3-executable nil
             "Cannot find executable \"sqlite3\"!")
  (let* ((file (oref conn file))
         (fullfile (if file (list (expand-file-name file))))
         (proc (make-process
                :name "emacsql-sqlite3"
                :command `(,emacsql-sqlite3-executable
                           "--batch"
                           ;; Use space as separator,
                           ;; which is convenient for `read'.
                           "--list" "--separator" " "
                           ;; Obviously
                           "--nullvalue" "nil"
                           ;; Don't return column headings
                           "--noheader"
                           ;; pass init file if set
                           ,@(when emacsql-sqlite3-init-file
                               `("--init" ,emacsql-sqlite3-init-file))
                           ,@fullfile)
                :buffer (generate-new-buffer " *emacsql sqlite*")
                :noquery t
                :connection-type 'pipe
                :coding 'utf-8-auto
                :sentinel #'emacsql-sqlite3--proc-sentinel)))
    (setf (emacsql-process conn) proc)
    (emacsql conn [:pragma (= busy-timeout $s1)]
             (/ (* emacsql-global-timeout 1000) 2))
    (emacsql-register conn)))

(cl-defmethod emacsql-waiting-p ((conn emacsql-sqlite3-connection))
  (with-current-buffer (emacsql-buffer conn)
    (save-excursion
      (goto-char (point-max))
      (re-search-backward (rx-to-string `(and ,emacsql-sqlite3--cmd-end-mark
                                              "\n"
                                              point)) nil t))))

(cl-defmethod emacsql-send-message ((conn emacsql-sqlite3-connection) message)
  (let ((proc (emacsql-process conn)))
    (process-send-string proc message)
    (process-send-string proc "\n")
    ;; HACK: Print a fake prompt "#" after each command.
    ;; this is because some command don't echo when success.
    ;; We need a prompt to refer a command was executed or not.
    (emacsql-sqlite3-run-dot-command conn :print "#")
    nil))

(cl-defmethod emacsql-parse ((conn emacsql-sqlite3-connection))
  (with-current-buffer (emacsql-buffer conn)
    (goto-char (point-min))
    (if (looking-at (rx "Error: " (group (1+ any)) eol))
        (signal 'emacsql-error (list (match-string 1)))
      (cl-macrolet ((sexps-in-line! ()
                      `(cl-loop until (looking-at "\n")
                                collect (read (current-buffer)))))
        (cl-loop
          until (looking-at
                 (concat (regexp-quote emacsql-sqlite3--cmd-end-mark) "\n"))
          collect (sexps-in-line!)
          do (forward-char))))))

(cl-defmethod emacsql-close ((conn emacsql-sqlite3-connection))
  (let ((process (emacsql-process conn)))
    (when (process-live-p process)
      (process-send-eof process))))

;;; Main entry

(cl-defun emacsql-sqlite3 (file &key debug)
  "Open a connected to database stored in FILE.
If FILE is nil use an in-memory database.

If DEBUG is non-nil, log all SQLite commands to a log
buffer. This is for debugging purposes."
  (let ((connection (make-instance 'emacsql-sqlite3-connection :file file)))
    (when debug
      (emacsql-enable-debugging connection))
    connection))

(provide 'emacsql-sqlite3)

;; Local Variables:
;; coding: utf-8
;; End:

;;; emacsql-sqlite3.el ends here
