;;; esqlite.el --- Manipulate sqlite file from Emacs

;; Author: Masahiro Hayashi <mhayashi1120@gmail.com>
;; Keywords: data
;; Package-Version: 20151206.1206
;; Package-Commit: fae9826cbc255b0f0686a801288f1441bda5f631
;; URL: https://github.com/mhayashi1120/Emacs-esqlite
;; Emacs: GNU Emacs 24 or later
;; Package-Requires: ((pcsv "1.3.3"))
;; Version: 0.3.1

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 3, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; esqlite.el is a implementation to handle sqlite database.
;;  (version 3 or later)

;; Following functions are provided:
;; * Read sqlite row as list of string.
;; * Async read sqlite row as list of string.
;; * sqlite process with being stationed
;; * Construct sqlite SQL.
;; * Escape SQL value to construct SQL
;; * Some of basic utilities.
;; * NULL handling (denote as :null keyword)

;; Following environments are tested:
;; * Windows7 cygwin64 with fakecygpty (sqlite 3.8.2)
;; * Windows7 native binary (Not enough works)
;; * Debian Linux (sqlite 3.7.13)

;; ## Install:

;; Please install sqlite command. (http://www.sqlite.org/)
;; Please install this package from MELPA. (http://melpa.org/)

;; ## Usage:

;; See the online document:
;; https://github.com/mhayashi1120/Emacs-esqlite

;;; TODO:

;;; Code:

(require 'cl-lib)
(require 'pcsv)

(defgroup esqlite ()
  "Manipulate sqlite database."
  :prefix "esqlite-"
  :group 'applications)

(defcustom esqlite-sqlite-program "sqlite3"
  "Command name or path to command.
Default is the latest release of sqlite."
  :group 'esqlite
  :type '(choice file string))

;;;
;;; Basic utilities
;;;

(put 'esqlite-error 'error-conditions
     '(error esqlite-error))
(put 'esqlite-error 'error-message "esqlite")

(put 'esqlite-unterminate-query 'error-conditions
     '(error esqlite-error esqlite-unterminate-query))
(put 'esqlite-unterminate-query 'error-message "esqlite fatal")

(defun esqlite--error (fmt &rest args)
  (let ((msg (apply 'format fmt args)))
    (signal 'esqlite-error (list msg))))

(defun esqlite--fatal (symbol fmt &rest args)
  (let ((msg (apply 'format fmt args)))
    (signal symbol (list msg))))

(defun esqlite-parse-replace (string replace-table)
  (cl-loop with table = replace-table
           with prev
           with constructor =
           (if (multibyte-string-p string)
               'concat
             (lambda (lis)
               (apply 'unibyte-string lis)))
           for c across string
           concat (let ((pair (assq c table)))
                    (cond
                     ((not pair)
                      (setq table replace-table)
                      (prog1
                          (funcall constructor (nreverse (cons c prev)))
                        (setq prev nil)))
                     ((stringp (cdr pair))
                      (when (multibyte-string-p (cdr pair))
                        (esqlite--error "Assert (must be a unibyte)"))
                      (setq table replace-table)
                      (setq prev nil)
                      (cdr pair))
                     ((consp (cdr pair))
                      (setq prev (cons c prev))
                      (setq table (cdr pair))
                      nil)
                     (t
                      (esqlite--error "Assert (Not supported type)"))))))

(defun esqlite-object= (s1 s2)
  "Return t if object name is equals in database."
  (and (stringp s1)
       (stringp s2)
       (eq (compare-strings s1 nil nil s2 nil nil t) t)))

(defun esqlite-object-assoc (key alist)
  "`assoc' with ignore case"
  (assoc-string key alist t))

(defun esqlite-object-member (elt list)
  "`member' with ignore case"
  (member-ignore-case elt list))

(defun esqlite-object-rassoc (key alist)
  "`rassoc' with ignore case"
  (cl-loop for cell in alist
           if (esqlite-object= key (cdr-safe cell))
           return cell))

(defun esqlite-trim (text)
  "Remove head/tail whitespaces from TEXT.
Do not use this function to huge TEXT."
  ;; sql query may be not a huge text.
  ;; so non-greedy match to text.
  (if (string-match "\\`[\s\t\n]*\\(.*?\\)[\s\t\n]*\\'" text)
      (match-string 1 text)
    ;; never reach here
    text))

(defun esqlite-value= (value1 value2)
  "Trinary logic to compare equality."
  (cond
   ((or (eq value1 :null) (eq value2 :null))
    :null)
   ((equal value1 value2))))


;;;
;;; URI filenames
;;;

;;;###autoload
(defun esqlite-filename-to-uri (file &optional queries)
  "Construct URI filenames from FILE.

\(esqlite-filename-to-uri \"/path/to/sqlite.db\" '((\"mode\" \"ro\") (\"cache\" \"shared\")))

http://www.sqlite.org/uri.html

"
  (when (memq system-type '(windows-nt))
    (setq file (replace-regexp-in-string "\\\\" "/" file)))
  (concat
   "file:"
   (and (file-name-absolute-p file) "/")
   (mapconcat
    'identity
    (mapcar
     (lambda (x)
       (setq x (replace-regexp-in-string "[?]" "%3f" x))
       (setq x (replace-regexp-in-string "#" "%23" x))
       x)
     (split-string file "/" t))
    "/")
   (and queries "?")
   (and queries (url-build-query-string queries))))

(defun esqlite-uri-to-filename (uri)
  "Extract filename from URI."
  (cl-destructuring-bind (file _)
      (esqlite-uri-parse uri)
    file))

(defun esqlite-uri-parse (uri)
  "Parse URI to filename and query parameters."
  (unless (string-match "\\`file:\\(.*\\)" uri)
    (error "Unable match file prefix %s" uri))
  (let ((body (match-string 1 uri)))
    (unless (string-match "\\`\\(.*?\\)\\(?:\\?\\(.*\\)\\)?\\'" body)
      (error "Fatal parse error"))
    (let* ((path (match-string 1 body))
           (qs (match-string 2 body))
           (file (url-unhex-string path))
           (queries
            (and qs
                 (url-parse-query-string qs))))
      ;; handle windows path
      (when (string-match "\\`/\\([a-zA-Z]:/.*\\)" file)
        (setq file (match-string 1 file)))
      (list file queries))))

;;;
;;; System deps
;;;

(defcustom esqlite-mswin-fakecygpty-program "fakecygpty.exe"
  "sqlite command on cygwin cannot work since no pty.
Please download and install fakecygpty (Google it!!)"
  :group 'esqlite
  :type '(choice file string))

(defun esqlite-mswin-native-p ()
  (and (memq system-type '(windows-nt))
       (not (esqlite-mswin-cygwin-p))))

(defun esqlite-mswin-cygwin-p ()
  (and (memq system-type '(windows-nt))
       (executable-find "cygpath")
       (let ((program (executable-find esqlite-sqlite-program)))
         (and program
              ;; check program is under the cygwin installed directory.
              (let* ((rootdir
                      (let* ((line (esqlite-mswin-cygpath "/" "windows"))
                             (root (expand-file-name line)))
                        (file-name-as-directory root)))
                     (regexp (concat "\\`" (regexp-quote rootdir))))
                (string-match regexp program))))
       t))

(defun esqlite-mswin-cygpath (file type)
  (with-temp-buffer
    (let ((code (call-process "cygpath" nil t nil "-t" type file)))
      (unless (= code 0)
        (esqlite--error "cygpath failed with %d" code))
      (goto-char (point-min))
      (buffer-substring
       (point-min) (point-at-eol)))))

;;;
;;; Basic utilities to handle esqlite i/o.
;;;

;;
;; Generate temporary name
;;

(defun esqlite--temp-null (query)
  ;; esqlite command nullvalue assigned to 20 chars (19 + null).
  (esqlite--random-text query 19))

;; * random char restrict to `a-zA-Z0-9+/' (except last `=')
;; * md5 have 16 bytes
;; * base64 encode 16 bytes -> 44 chars
;; * to trim last `=', only use md5 first 15 bytes make (* 4 (/ 15 3)) 20 bytes
(defun esqlite--random-text (seed length)
  (cl-loop for i from 0 to (/ (1- length) 20)
           concat (md5 (format "%d:%s:%s" i (current-time) seed))
           into hash
           finally return
           ;; only first 15 bytes
           (cl-loop for i from 0 below (- (length hash) 2) by 2
                    ;; make random unibyte string
                    collect (let ((hex (substring hash i (+ i 2))))
                              (string-to-number hex 16))
                    into res
                    finally return
                    ;; md5 hex fold to base64 area
                    (let* ((unibytes (apply 'unibyte-string res))
                           (b64 (base64-encode-string unibytes t)))
                      (substring b64 0 length)))))

(defun esqlite-unique-name (stream prefix &optional seed)
  (cl-loop with objects = (esqlite-read-all-objects stream)
           with full-name
           while (let ((random-text (esqlite--random-text
                                     (or seed "") 40)))
                   (setq full-name (format "%s_%s" prefix random-text))
                   (member full-name objects))
           finally return full-name))

(defconst esqlite-control-code-regexp
  "[\x00-\x08\x0b\x0c\x0e-\x1f\x7f]")

(defun esqlite--check-control-code (command)
   ;; except TAB, CR, LF
  (when (string-match esqlite-control-code-regexp command)
    (error "Invalid sql statement (May cause stall the process)")))

(defun esqlite--terminate-command (command)
  (esqlite--check-control-code command)
  (cond
   ((not (string-match "\n\\'" command))
    (concat command "\n"))
   (t
    command)))

(defun esqlite--terminate-statement (sql)
  (esqlite--check-control-code sql)
  (cond
   ((not (string-match ";[\s\t\n]*\\'" sql))
    (concat sql ";\n"))
   ((not (string-match "\n\\'" sql))
    (concat sql "\n"))
   (t sql)))

;;
;; constant / system dependent
;;

(defconst esqlite-rowid-columns
  '("_ROWID_" "ROWID" "OID"))

;;;###autoload
(defconst esqlite-file-header-regexp "\\`SQLite format 3\x00"
  "Now support only Sqlite3.")

;;;###autoload
(defun esqlite-file-guessed-database-p (file)
  "Guess the FILE is a Sqlite database or not."
  (and (file-regular-p file)
       (with-temp-buffer
         (insert-file-contents file nil 0 256)
         (looking-at esqlite-file-header-regexp))))

;;;###autoload
(defun esqlite-sqlite-installed-p ()
  "Return non-nil if `esqlite-sqlite-program' is installed."
  (and (stringp esqlite-sqlite-program)
       (executable-find esqlite-sqlite-program)))

(defun esqlite-check-sqlite-program ()
  (unless (stringp esqlite-sqlite-program)
    (esqlite--error "No valid sqlite program"))
  (unless (executable-find esqlite-sqlite-program)
    (esqlite--error "%s not found" esqlite-sqlite-program)))

(defun esqlite-sqlite-version ()
  "Get sqlite command version as string."
  (with-temp-buffer
    (call-process esqlite-sqlite-program nil t nil "--version")
    (goto-char (point-min))
    (unless (looking-at "\\([0-9.]+\\)")
      (error "Version not found"))
    (match-string 1)))

;;FIXME try to fix async process in Mac OS
(defun esqlite--check-async-interface ()
  (when (memq system-type '(darwin))
    (esqlite--error
     "Currently this system cannot handle async family.")))

;;
;; process
;;

(defvar esqlite-process-coding-system
  (let* ((syseol (let ((type (coding-system-eol-type
                              ;; guess esqlite command environment
                              default-terminal-coding-system)))
                   (cond
                    ((or (symbolp type)
                         (numberp type))
                     type)
                    ((vectorp type)
                     (coding-system-eol-type (aref type 0))))))
         ;; utf-8 as the default coding-system of Sqlite database.
         (basecs 'utf-8)
         (cs
          (coding-system-change-eol-conversion basecs syseol)))
    (cons cs cs))
  "Temporarily change coding system by this hiding parameter.
Normally, no need to use this parameter.")

(defun esqlite--process-coding-system ()
  (cond
   ((consp esqlite-process-coding-system)
    esqlite-process-coding-system)
   ((coding-system-p esqlite-process-coding-system)
    (cons esqlite-process-coding-system
          esqlite-process-coding-system))
   (t default-process-coding-system)))

(eval-and-compile
  (defconst esqlite--prompt "sqlite> "))

;; continue prompt is empty.
;; otherwise, first row of SELECT contains the continue prompt.
(eval-and-compile
  (defconst esqlite--prompt-continue "   ...> "))

(defconst esqlite--prompt-re-any-continue
  (eval-when-compile
    (concat
     "\\("
     (regexp-opt (list esqlite--prompt esqlite--prompt-continue))
     "*"
     (regexp-quote esqlite--prompt-continue)
     "\\)")))

(defconst esqlite--prompt-re-any-proceeding
  (eval-when-compile
    (concat
     "\\("
     (regexp-opt (list esqlite--prompt esqlite--prompt-continue))
     "+\\)"
     ;; there is some char after continue/prompt
     ".")))

(defconst esqlite--prompt-re-next
  (eval-when-compile
    (concat
     "\\("
     (regexp-opt (list esqlite--prompt esqlite--prompt-continue))
     "*\\)"
     (regexp-quote esqlite--prompt)
     "\\'")))

(defun esqlite--prompt-eob (regexp)
  (save-excursion
    (goto-char (point-max))
    (forward-line 0)
    (looking-at regexp)))

(defun esqlite--prompt-p ()
  ;; when executed sql contains newline, continue prompt displayed
  ;; before last prompt "sqlite> "
  (esqlite--prompt-eob esqlite--prompt-re-next))

(defvar esqlite--default-init-file nil)

;; To avoid user initialization file ~/.sqliterc
(defun esqlite--default-init-file (&optional refresh)
  (or (and (not refresh)
           (stringp esqlite--default-init-file)
           (file-exists-p esqlite--default-init-file)
           esqlite--default-init-file)
      (setq esqlite--default-init-file
            (let ((file (make-temp-file "emacs-esqlite-")))
              (with-temp-buffer
                (insert (format ".prompt \"%s\" \"%s\"\n"
                                esqlite--prompt
                                esqlite--prompt-continue))
                ;; Later 3.8.6 "-csv" output contains CR (\r) before LF (\n)
                (when (version<= "3.8.6" (esqlite-sqlite-version))
                  ;; FIXME: This is working for "-csv" option
                  ;;  However, `.separator' first argument "," seems no effect for csv
                  ;;  I think that sqlite3 may be confusing specification.
                  ;;  `-newline' argument doesn't have such confusion.
                  ;;  I probably should use this option.
                  (insert ".separator \",\" \"\\n\"\n"))
                (write-region (point-min) (point-max) file nil 'no-msg))
              file))))

(defmacro esqlite--with-env (&rest form)
  `(let ((process-environment (copy-sequence process-environment))
         ;; non pty resulting in echoing query.
         (process-connection-type t)
         (default-process-coding-system
           (esqlite--process-coding-system)))
     ;; currently no meanings of this
     ;; in the future release may support i18n.
     (setenv "LANG" "C")
     ;; execute process safety set the value.
     (setenv "TERM" "dumb")
     ;; FIXME TODO:
     ;; suppress to save .sqlite_history to your home
     ;; curretly sqlite3 shell.c use low level api read from
     ;; /etc/passwd on Unix system
     ;; (setenv "HOME" esqlite--temp-homedir)
     ;; for windows
     ;; (setenv "USERPROFILE" esqlite--temp-homedir)
     ,@form))

(defmacro esqlite--with-process (proc &rest form)
  (declare (indent 1) (debug t))
  `(let ((buf (process-buffer ,proc)))
     (when (buffer-live-p buf)
       (with-current-buffer buf
         ,@form))))

(defmacro esqlite--with-parse (proc event &rest form)
  "Execute FORM in PROC buffer with appended EVENT.
This form check syntax error report from esqlite command."
  (declare (indent 2) (debug t))
  `(esqlite--with-process proc
     (save-excursion
       (goto-char (point-max))
       (insert event)
       (goto-char (point-min))
       ,@form)))

(defun esqlite--start-process (buffer &rest args)
  (esqlite--with-env
   (let ((cmdline (cons esqlite-sqlite-program args))
         (cygwinp (esqlite-mswin-cygwin-p)))
     (when cygwinp
       (unless esqlite-mswin-fakecygpty-program
         (error "%s %s"
                "esqlite on cygwin cannot work unless `fakecygpty'"
                "see `esqlite-mswin-fakecygpty-program' settings"))
       (setq cmdline
             (cons esqlite-mswin-fakecygpty-program cmdline)))
     (apply 'start-process "Esqlite" buffer cmdline))))

(defun esqlite--call-process-region (buffer start end &rest args)
  (esqlite--with-env
   (apply 'call-process-region
          start end esqlite-sqlite-program nil buffer nil args)))

(defun esqlite--safe-expand-file (file-or-uri)
  (cond
   ((string-match "\\`file:" file-or-uri)
    ;; URI Filenames:
    ;; http://www.sqlite.org/uri.html
    file-or-uri)
   (t
    (expand-file-name file-or-uri))))

(defun esqlite--expand-db-name (file-or-uri)
  (cond
   ((string-match "\\`file:" file-or-uri)
    ;; URI Filenames:
    ;; http://www.sqlite.org/uri.html
    file-or-uri)
   ((esqlite-mswin-cygwin-p)
    ;; esqlite on cygwin cannot accept c:/hoge like path.
    ;; must convert /cygdrive/c/hoge
    ;; But seems accept such path in -init option.
    (esqlite-mswin-cygpath file-or-uri "unix"))
   (t
    (expand-file-name file-or-uri))))

(defun esqlite--create-process-buffer ()
  (generate-new-buffer " *esqlite work* "))

(defun esqlite-start-csv-process (file-or-key &optional query nullvalue &rest args)
  "[Low level API] Start async sqlite process.
If QUERY is specified, exit immediately after execute the QUERY.

Cygwin: FILE name contains multibyte char, may fail to open FILE as database."
  (let* ((init (esqlite--default-init-file))
         (file (and (stringp file-or-key) file-or-key))
         (key (and (symbolp file-or-key) file-or-key))
         (db (and file (list (esqlite--expand-db-name file))))
         (filename (and file (esqlite--safe-expand-file file)))
         (null (or nullvalue (esqlite--temp-null query)))
         (query (and query (esqlite--terminate-statement query)))
         (args `(
                 "-interactive"
                 "-init" ,init
                 "-csv"
                 "-nullvalue" ,null
                 ;; prior than preceeding args
                 ,@args
                 ,@db))
         (buf (esqlite--create-process-buffer))
         (proc (apply 'esqlite--start-process buf args)))
    (process-put proc 'esqlite-init-file init)
    (process-put proc 'esqlite-filename filename)
    (process-put proc 'esqlite-null-value null)
    (process-put proc 'esqlite-memory-key key)
    (when query
      ;; to clear initializing message and first prompt
      (esqlite--with-process proc
        (esqlite--until-prompt proc)
        (erase-buffer))
      (process-send-string proc query)
      ;; imitate calling command
      ;; e.g. esqlite db.esqlite "select some,of,query from table"
      (process-send-string proc ".exit\n"))
    proc))

(defun esqlite-call-csv-process (file query &optional nullvalue &rest args)
  "[Low level API] Call sqlite process.

Cygwin: FILE contains multibyte char, may fail to open FILE as database."
  (let* ((init (esqlite--default-init-file))
         (db (esqlite--expand-db-name file))
         (null (or nullvalue (esqlite--temp-null query)))
         (args `(
                 "-batch"
                 "-init" ,init
                 "-csv"
                 "-nullvalue" ,null
                 ;; prior than preceeding args
                 ,@args
                 ,db)))
    ;; Do not use `call-process' this case.  On windows if argument is
    ;; a multibyte string, command argument may be destroyed.
    ;; Although `call-process-region' may have same problem, but
    ;; decrease the risk of this.
    ;; For example, DB file might have a multibyte char.
    (apply
     'esqlite--call-process-region
     (current-buffer)
     ;; `call-process-region' start argument accept string
     (esqlite--terminate-statement query) nil
     args)))

;;
;; Sqlite text -> Emacs data
;;

;; http://www.sqlite.org/syntaxdiagrams.html#numeric-literal
(defconst esqlite-numeric-literal-regexp
  (eval-when-compile
    (concat
     "\\`"
     "[+-]?"
     "\\([0-9]+\\(\\.\\([0-9]*\\)\\)?\\|\\.[0-9]+\\)"
     "\\(E[+-]?[0-9]+\\)?"
     "\\'")))

(defun esqlite-numeric-text-p (text)
  "Utility function to check TEXT is numeric."
  (and (string-match esqlite-numeric-literal-regexp text)
       t))

(defun esqlite-hex-to-bytes (hex)
  "To get the hex blob data as a unibyte string.

NOTE: If BLOB data contains non text byte (null-byte), this
  case `esqlite-*-read' function family may return truncated bytes.
  This case you should use HEX Sqlite function in SQL and decode it
  with this function.
This function is not checking hex is valid."
  (apply 'unibyte-string
         (cl-loop for start from 0 below (length hex) by 2
                  for end from (if (eq (logand (length hex) 1) 1) 1 2) by 2
                  collect (string-to-number (substring hex start end) 16))))

;;
;; sleep in process filter
;;

(defvar esqlite-sleep-second
  ;;FIXME
  ;; This check calculate response of external command which does not accept
  ;; from process output.
  (apply 'min (cl-loop for _ in '(1 2 3 4 5)
                       collect
                       (let ((start (float-time)))
                         ;; probablly every system have "echo" ...
                         (call-process "echo" nil nil nil "1")
                         (let ((end (float-time)))
                           (- end start))))))

(defun esqlite-sleep (proc)
  ;; Other code affect to buffer while `sleep-for'.
  ;; TODO why need save-excursion? timer? filter? I can't get clue.
  (save-excursion
    ;; Achieve like a asynchronous behavior (ex: draw mode line)
    (redisplay)
    (accept-process-output proc esqlite-sleep-second)))

;;
;; handling sqlite prompt
;;

(defun esqlite--try-to-delete-halfway-prompt ()
  (when (and
         (or (looking-at esqlite--prompt-re-any-continue)
             (looking-at esqlite--prompt-re-next)
             (looking-at esqlite--prompt-re-any-proceeding))
         (match-beginning 1))
    (replace-match "" nil nil nil 1)))

;; delete continue prompt and return its count
(defun esqlite--try-to-delete-continue ()
  (let ((i 0))
    (catch 'done
      (while t
        (cond
         ((looking-at (concat (regexp-quote esqlite--prompt) "\\'"))
          (throw 'done t))
         ((looking-at (concat (regexp-quote esqlite--prompt)))
          (replace-match "" nil nil nil 0)
          (setq i (1+ i)))
         ((looking-at (concat (regexp-quote esqlite--prompt-continue)))
          (replace-match "" nil nil nil 0)
          (setq i (1+ i)))
         (t
          (throw 'done t)))))
    i))

;; read "Error:" sqlite message from current buffer
;; may delete some prompts if any.
(defun esqlite--read-syntax-error-at-point ()
  (let* ((prompt-count (esqlite--try-to-delete-continue))
         (errmsg (esqlite--read-syntax-error)))
    (list prompt-count errmsg)))

(defun esqlite--read-syntax-error ()
  (and (looking-at "^Error: \\(.*\\)")
       (match-string 1)))

(defun esqlite--until-prompt (proc)
  (while (and (not (process-get proc 'esqlite-stream-continue-prompt))
              (eq (process-status proc) 'run)
              (not (esqlite--prompt-p)))
    (esqlite-sleep proc)))

;;
;; read csv from esqlite
;;

(defun esqlite--read-csv-line (&optional null)
  (esqlite--try-to-delete-halfway-prompt)
  (let ((errmsg (esqlite--read-syntax-error)))
    (when errmsg
      (esqlite--error "%s" errmsg)))
  (let ((first (point))
        (line (pcsv-read-line)))
    ;; end of line is not a newline.
    ;; means ouput is progressing, otherwise prompt.
    (unless (bolp)
      (goto-char first)
      (signal 'invalid-read-syntax nil))
    (cl-loop for datum in line
             collect
             ;; handling `esqlite--temp-null'
             (if (equal datum null)
                 :null
               datum))))

(defun esqlite--read-csv-line-with-deletion (null)
  (when (memq system-type '(
                            windows-nt
                            ;; FIXME: more investigate
                            ;; darwin may have \r in process buffer.
                            ;; cleanup the CR just in case.
                            ;; https://github.com/mhayashi1120/Emacs-esqlite/issues/2
                            darwin
                            ))
    ;; wash unquoted carriage return
    (save-excursion
      (while (re-search-forward "\r$" nil t)
        (replace-match ""))))
  (let ((start (point))
        (row (esqlite--read-csv-line null)))
    (delete-region start (point))
    row))

;; Call with one arg which is parsed row.
;; This variable is intended to use in local dynamic binding.
(defvar esqlite-read-callback nil)

;; See `esqlite--read-csv-with-deletion-0'
(defun esqlite--read-csv-with-deletion/callback (null callback)
  (let (res)
    (condition-case nil
        (while (not (eobp))
          (let ((start (point))
                (row (esqlite--read-csv-line-with-deletion null)))
            (setq res (cons row res))
            (funcall callback row)))
      ;; output is proceeding from process
      ;; finish the reading
      (invalid-read-syntax nil))
    (nreverse res)))

;; See `esqlite--read-csv-with-deletion/callback'
(defun esqlite--read-csv-with-deletion-0 (null)
  (let (res)
    (condition-case nil
        (while (not (eobp))
          (let ((start (point))
                (row (esqlite--read-csv-line-with-deletion null)))
            (setq res (cons row res))))
      ;; output is proceeding from process
      ;; finish the reading
      (invalid-read-syntax nil))
    (nreverse res)))

(defun esqlite--read-csv-with-deletion (null)
  "Read csv data from current point.
Delete csv data if reading was succeeded."
  (if esqlite-read-callback
      (esqlite--read-csv-with-deletion/callback
       null esqlite-read-callback)
    (esqlite--read-csv-with-deletion-0 null)))

;;
;; Escape text (Emacs data -> Sqlite text)
;;

(defun esqlite-escape--like-table (escape-char &optional override)
  (let ((escape (or escape-char ?\\)))
    (append
     override
     `((?\% . ,(format "%c%%" escape))
       (?\_ . ,(format "%c_"  escape))
       (,escape . ,(format "%c%c"  escape escape))))))

;;;###autoload
(defun esqlite-escape-string (string &optional quote-char)
  "Escape STRING as a sqlite string object context.
Optional QUOTE-CHAR arg indicate quote-char

e.g.
\(let ((user-input \"a\\\"'b\"))
  (format \"SELECT * FROM T WHERE a = '%s'\" \
\(esqlite-escape-string user-input ?\\')))
  => \"SELECT * FROM T WHERE a = 'a\\\"''b'\"

\(let ((user-input \"a\\\"'b\"))
  (format \"SELECT * FROM T WHERE a = \\\"%s\\\"\" \
\(esqlite-escape-string user-input ?\\\")))
  => \"SELECT * FROM T WHERE a = \\\"a\\\"\\\"'b\\\"\"
"
  (setq quote-char (or quote-char ?\'))
  (esqlite-parse-replace
   string
   `((,quote-char . ,(format "%c%c" quote-char quote-char)))))

;;;###autoload
(defun esqlite-escape-like (query &optional escape-char)
  "Escape QUERY as a sql LIKE context.
This function is not quote single-quote (') you should use with
`esqlite-escape-string' or `esqlite-format-text'.

ESCAPE-CHAR is optional char (default '\\') for escape sequence expressed
following esqlite syntax.

e.g. fuzzy search of \"100%\" text in `value' column in `hoge' table.
   SELECT * FROM hoge WHERE value LIKE '%100\\%%' ESCAPE '\\'

To create the like pattern:
   => (concat \"%\" (esqlite-escape-like \"100%\" ?\\\\) \"%\")
   => \"%100\\%%\""
  (unless (or (null escape-char)
              (and (<= 0 escape-char)
                   (<= escape-char 127)))
    (esqlite--error "escape-char must be a ascii"))
  (esqlite-parse-replace
   query
   (esqlite-escape--like-table escape-char)))

;;;###autoload
(defun esqlite-format-text (string &optional quote-char)
  "Convenience function to provide make quoted STRING in sql."
  (setq quote-char (or quote-char ?\'))
  (format "%c%s%c"
          quote-char
          (esqlite-escape-string string quote-char)
          quote-char))

(defun esqlite-format-object (object)
  (esqlite-format-text object ?\"))

(defun esqlite-format-value (object)
  (cond
   ((stringp object)
    (cond
     (
      ;; unsafe ascii as a blob data.
      ;; some of exception, control chars must be escaped
      ;; as a blob
      (string-match esqlite-control-code-regexp object)
      (esqlite-format-blob object))
     (
      ;; only ascii (printable chars) or empty string.
      (or (string-match "\\`[\t\n\r\x20-\x7e]*\\'" object)
          (multibyte-string-p object))
      (esqlite-format-text object))
     (t
      ;; unibyte string
      (esqlite-format-blob object))))
   ((numberp object)
    (prin1-to-string object))
   ((eq object :null) "null")
   ((listp object)
    (mapconcat 'esqlite-format-value object ", "))
   (t
    (esqlite--error "Not a supported type"))))

(defun esqlite-format-blob (text)
  (let ((unibyte
         (cond
          ((not (stringp text))
           (esqlite--error "Not a string"))
          ((multibyte-string-p text)
           (encode-coding-string text 'utf-8))
          (t text))))
    (format "x'%s'" (mapconcat (lambda (x) (format "%02x" x))
                               unibyte ""))))

(eval-and-compile
  (defvar esqlite-format--table
    (eval-when-compile
      '(
        ("s" . (lambda (x)
                 (cond
                  ((stringp x) x)
                  ((numberp x) (number-to-string x))
                  (t (prin1-to-string x)))))
        ("t" . esqlite-escape-string)
        ("T" . esqlite-format-text)
        ("l" . esqlite-escape-like)
        ("L" . (lambda (x)
                 (concat
                  (esqlite-format-text (esqlite-escape-like x))
                  " ESCAPE '\\' ")))
        ;; some database object
        ("o" . esqlite-format-object)
        ;; column list
        ("O" . (lambda (l)
                 (mapconcat (lambda (x) (esqlite-format-object x))
                            l ", ")))
        ;; some value list (string, number, list) with properly quoted
        ("V" . esqlite-format-value)
        ;; format byte string to x'ffee0011' like literal
        ("X" . esqlite-format-blob)
        ))))

;;;###autoload
(defun esqlite-prepare (fmt &rest keywords)
  "Prepare SQL with FMT like `format'.
Prepared SQL statement may contain a text-property `esqlite-prepared'
 which should not be removed by programmer.

FMT is a string or list of string.
 each list item join with newline.

Following each directive accept arg which contains keyword name.
  Undefined keyword is simply ignored.
e.g.
\(esqlite-prepare \"SELECT * FROM %o{some-table} WHERE id = %s{some-value}\"\
 :some-table \"tbl\")
 => \"SELECT * FROM \"tbl\" WHERE id = %s{some-value}\"

%s: raw text (With no escape)
%t: escape text
%T: same as %t but with quote
%l: escape LIKE pattern escape char is '\\'
%L: similar to %l except that with quoting/escaping and ESCAPE statement
%o: escape db object with quote
%O: escape db objects with quote (joined by \", \")
%V: escape sql value(s) with quote if need
  (if list, joined by \", \" without paren)
%X: escape text as hex notation.
    multibyte string is encoded as utf-8 byte array."
  (with-temp-buffer
    (when (listp fmt)
      (setq fmt (mapconcat 'identity fmt "\n")))
    (insert fmt)
    (goto-char (point-min))
    (let ((fmt-regexp
           (eval-when-compile
             (concat
              (regexp-opt (mapcar 'car esqlite-format--table) t)
              ;; keyword name
              "\\(?:{\\(.+?\\)}\\)")))
          (case-fold-search nil))
      (while (search-forward "%" nil t)
        (cond
         ((get-text-property (point) 'esqlite-prepared))
         ((eq (char-after) ?%)
          (delete-char 1)
          (put-text-property (1- (point)) (point) 'esqlite-prepared t))
         ((looking-at fmt-regexp)
          (let* ((spec (match-string 1))
                 (varname (match-string 2))
                 (keysym (and varname (intern-soft (concat ":" varname))))
                 (fn (assoc-default spec esqlite-format--table))
                 (begin (1- (point)))
                 (end (match-end 0))
                 obj)
            (unless fn
              (esqlite--error "Invalid format character: `%%%s'" spec))
            (unless (functionp fn)
              (esqlite--error "Assert"))
            (cond
             ((and keysym (plist-member keywords keysym))
              ;; Delete formatter directive
              (delete-region begin end)
              (setq obj (plist-get keywords keysym))
              (let ((text (funcall fn obj)))
                (insert text))
              (put-text-property begin (point) 'esqlite-prepared t)))))
         (t
          (esqlite--error "No valid format")))))
    (buffer-string)))

;;;###autoload
(defun esqlite-format (esqlite-fmt &rest esqlite-objects)
  "This function is obsoleted should change to `esqlite-prepare'.
This function is not working under `lexical-binding' is t.

Prepare sql with FMT like `format'.

FMT is a string or list of string.
 each list item join with newline.

Each directive accept arg which contains variable name.
  This variable name must not contain `esqlite-' prefix.
e.g.
\(let ((some-var \"FOO\")) (esqlite-format \"%s %s{some-var}\" \"HOGE\"))
 => \"HOGE FOO\"

Format directive is same as `esqlite-prepare'

\(fn fmt &rest objects)"
  (let (prepared keywords)
    (with-temp-buffer
      (when (listp esqlite-fmt)
        (setq esqlite-fmt (mapconcat 'identity esqlite-fmt "\n")))
      (insert esqlite-fmt)
      (goto-char (point-min))
      (let ((esqlite-fmt-regexp
             (eval-when-compile
               (concat
                (regexp-opt (mapcar 'car esqlite-format--table) t)
                ;; Optional varname
                "\\(?:{\\(.+?\\)}\\)?")))
            (case-fold-search nil)
            (i 0))
        (while (search-forward "%" nil t)
          (cond
           ((eq (char-after) ?%)
            (delete-char 1))
           ((looking-at esqlite-fmt-regexp)
            (let* ((spec (match-string 1))
                   (varname (match-string 2))
                   (end (match-end 0))
                   (varsym (intern-soft varname))
                   (keysym (and varname (intern (concat ":" varname))))
                   (fn (assoc-default spec esqlite-format--table))
                   obj)
              (when (and varname (string-match "\\`esqlite-" varname))
                (esqlite--error "Unable to use esqlite- prefix variable %s"
                                varname))
              (goto-char end)
              (cond
               (varsym
                ;; raise error asis if varname is not defined.
                (setq obj (symbol-value varsym)))
               (esqlite-objects
                ;; replace text match to `esqlite-prepare'
                (setq obj (car esqlite-objects))
                (setq esqlite-objects (cdr esqlite-objects))
                (setq varname (format "esqlite-keyword-%s" i))
                (insert "{" varname "}")
                (setq keysym (intern (format ":%s" varname)))
                (setq i (1+ i)))
               (t
                (esqlite--error "No value assigned to `%%%s'" spec)))
              (unless fn
                (esqlite--error "Invalid format character: `%%%s'" spec))
              (unless keysym
                (esqlite--error "No valid keyword"))
              (setq keywords (append keywords (list keysym obj)))))))
        (when esqlite-objects
          (esqlite--error "args out of range %s" esqlite-objects))
        (setq prepared (buffer-string))))
    (let ((query (apply 'esqlite-prepare prepared keywords)))
      (remove-text-properties 0 (length query) '(esqlite-prepared t) query)
      query)))

(make-obsolete 'esqlite-format 'esqlite-prepare "0.2.0")

;;;
;;; Esqlite stream
;;;

;;
;; private
;;

(defmacro esqlite-stream--with-buffer (stream &rest form)
  (declare (indent 1) (debug t))
  `(let ((buf (process-buffer stream)))
     (unless (buffer-live-p buf)
       (esqlite--error "Stream buffer has been deleted"))
     (with-current-buffer buf
       ,@form)))

(defun esqlite-stream--reuse-memory (key)
  (cl-loop for p in (process-list)
           if (and (esqlite-stream-alive-p p)
                   (eq (esqlite-stream-memory-key p) key))
           return p))

(defun esqlite-stream--reuse-file (file)
  (cl-loop with filename = (esqlite--safe-expand-file file)
           for p in (process-list)
           if (and (esqlite-stream-alive-p p)
                   (string= (esqlite-stream-filename p) filename))
           return p))

(defun esqlite-stream--open (file-or-key)
  (esqlite--check-async-interface)
  (let* ((stream (esqlite-start-csv-process file-or-key)))
    (process-put stream 'esqlite-stream-process-p t)
    ;; Do not show confirm prompt when exiting.
    ;; `esqlite-killing-emacs' close all stream.
    (set-process-query-on-exit-flag stream nil)
    (set-process-filter stream 'esqlite-stream--filter)
    (set-process-sentinel stream 'esqlite-stream--sentinel)
    (esqlite-stream--wait-first-prompt stream)
    stream))

(defvar esqlite-stream--check-hang-count 3
  "Threshold to check error message several time to call `accept-process-output'.")

(defun esqlite-stream--maybe-error (proc query)
  (let ((done 0)
        ;; Every newline get a prompt/continue.
        ;; Why -2 ?
        ;; 1. Ignore last prompt. Last one is next new prompt.
        ;; 2. And QUERY must have last newline "SELECT 1;\n"
        ;;  `split-string' generate empty string at last. Ignore this one.
        (expected (- (length (split-string query "\n")) 2))
        (stall-point)
        (count-hang 0)
        promptp)
    (catch 'done
      (while (eq (process-status proc) 'run)
        (esqlite-sleep proc)
        (process-put proc 'esqlite-stream-continue-prompt nil)
        (cl-destructuring-bind (prompt-count errmsg)
            (esqlite--read-syntax-error-at-point)
          (setq done (+ done prompt-count))
          (when (stringp errmsg)
            (esqlite--error "%s" errmsg))
          (setq promptp (esqlite--prompt-p))
          (when (and (< expected done)
                     (not promptp))
            (process-put proc 'esqlite-stream-continue-prompt t)
            (esqlite--fatal 'esqlite-unterminate-query
                            "Unterminated query")))
        (when (and promptp
                   (= expected done))
          (throw 'done t))
        ;; check compound statements prompt just in case.
        ;; compound statements is not supported. but should never hang the stream process.
        ;; check `esqlite-stream--check-hang-count' time stream is freezing or not.
        ;; e.g. QUERY: "select\n 1;\nselect\n2\n;\nselect 3;\n"
        ;;    This should be read as '(("1") ("2") ("3"))
        ;;    But each of statement generate `esqlite--prompt'before next statement.
        ;;    And don't forget that continue prompt `esqlite--prompt-continue' after send newline.
        ;;    This simple example seems working well, but if 1st statement is too complex, so
        ;;    spend too many seconds, this completely freezing before next 2nd statement.
        ;;    In this case, may not read 2nd, 3rd statement "Error:" message from PROC
        (if (and stall-point
                 (= stall-point (point-max-marker)))
            (setq count-hang (1+ count-hang))
          ;; reset count
          (setq count-hang 0))
        (setq stall-point (point-max-marker))
        (when (<= esqlite-stream--check-hang-count count-hang)
          (throw 'done t))))))

(defun esqlite-stream--filter (proc event)
  (esqlite--with-parse proc event
    (let ((filter (process-get proc 'esqlite-stream-filter)))
      (when (functionp filter)
        (funcall filter proc)))))

(defun esqlite-stream--sentinel (proc event)
  (esqlite--with-process proc
    (when (memq (process-status proc) '(exit signal))
      ;; delay several seconds to get buffer contents
      (run-with-timer
       5 nil
       (lambda (buffer)
         (when (buffer-live-p buffer)
           (kill-buffer buffer)))
       (current-buffer)))))

(defun esqlite-stream--send-string (stream string)
  (esqlite-stream--with-buffer stream
    ;; wait until previous sql was finished.
    (esqlite--until-prompt stream)
    ;; clear all text contains prompt.
    (erase-buffer)
    (process-send-string stream string)
    ;; only check syntax error.
    ;; This check maybe promptly return from esqlite process.
    (esqlite-stream--maybe-error stream string)
    ;; sync
    (esqlite--until-prompt stream)
    t))

(defun esqlite-stream--async-send-string (stream string)
  (esqlite-stream--with-buffer stream
    ;; wait until previous sql was finished.
    (esqlite--until-prompt stream)
    ;; clear all text contains prompt.
    (erase-buffer)
    (process-send-string stream string)
    ;; only check syntax error.
    ;; This check maybe promptly return from esqlite process.
    (esqlite-stream--maybe-error stream string)))

(defun esqlite-stream--send-command-0 (stream command &optional async)
  "Send a meta command to esqlite STREAM.
This function return after checking syntax error of COMMAND.

COMMAND is a command line that may ommit newline."
  (let ((query (esqlite--terminate-command command))
        (sender (if async
                    'esqlite-stream--async-send-string
                  'esqlite-stream--send-string)))
    (funcall sender stream query)
    (unless async
      (esqlite-stream--with-buffer stream
        (buffer-substring (point-min) (point-at-eol 0))))))

(defun esqlite-stream--send-sql-0 (stream sql &optional async)
  "Send SQL to esqlite STREAM.
This function return after checking syntax error of SQL.

SQL is a sql statement that may ommit statement end `;'.
 Do Not send multiple statements (compound statements).
 This may cause STREAM stalling.

Examples:
Good: SELECT * FROM table1;
Good: SELECT * FROM table1
Good: SELECT * FROM table1\n
 Bad: SELECT * FROM table1; SELECT * FROM table2;
Very Bad: SELECT 'Non terminated quote
"
  (let ((query (esqlite--terminate-statement sql))
        (sender (if async
                    'esqlite-stream--async-send-string
                  'esqlite-stream--send-string)))
    (funcall sender stream query)))

;; wait until prompt to buffer
(defun esqlite-stream--wait-first-prompt (stream)
  (let ((inhibit-redisplay t))
    (esqlite-stream--with-buffer stream
      (esqlite--until-prompt stream)
      ;; No header information when exited immediately after exec
      (let ((errmsg (esqlite--read-syntax-error)))
        (when errmsg
          (esqlite--error "%s" errmsg)))
      ;; sometimes exited process with no error message. I can't figure out it..
      ;; forcibly exited stream with raising error.
      (unless (memq (process-status stream) '(run))
        (esqlite--error "Process was exited unknown reason")))))

;;
;; public
;;

(defun esqlite-stream-status (stream)
  "Valid statuses are:
`exit', `prompt', `continue', `querying'"
  (cond
   ((not (esqlite-stream-alive-p stream))
    'exit)
   ((esqlite-stream-prompt-p stream)
    'prompt)
   ((process-get stream 'esqlite-stream-continue-prompt)
    'continue)
   (t
    'querying)))

(defun esqlite-stream-p (obj)
  (and (processp obj)
       (process-get obj 'esqlite-stream-process-p)))

(defun esqlite-stream-alive-p (stream)
  (and (eq (process-status stream) 'run)
       ;; check buffer either.
       ;; process-status still `run' after killing buffer
       (buffer-live-p (process-buffer stream))))

(defun esqlite-stream-filename (stream)
  (process-get stream 'esqlite-filename))

(defun esqlite-stream-memory-key (stream)
  (process-get stream 'esqlite-memory-key))

(defun esqlite-stream-check-alive (stream)
  (unless (esqlite-stream-alive-p stream)
    (esqlite--error "Stream has been closed")))

(defun esqlite-stream-put (stream propname value)
  "Put stream a user defined property."
  (let ((plist (process-get stream 'esqlite-properties)))
    (unless plist
      (setq plist (list propname nil))
      (process-put stream 'esqlite-properties plist))
    (plist-put plist propname value)))

(defun esqlite-stream-get (stream propname)
  "Get a user defined property from stream."
  (let ((plist (process-get stream 'esqlite-properties)))
    (plist-get plist propname)))

;;;###autoload
(defun esqlite-stream-open (file &optional reuse)
  "Open FILE stream as sqlite database.
Optional REUSE indicate get having been opened stream.

WARNING: This function return process as `esqlite-stream' object,
 but do not use this as a process object. This object style
 may be changed in future release."
  (cl-check-type file string)
  (esqlite-check-sqlite-program)
  (or (and reuse
           (esqlite-stream--reuse-file file))
      (esqlite-stream--open file)))

;;;###autoload
(defun esqlite-stream-memory (&optional key)
  "Open volatile sqlite database in memory.
KEY should be a non-nil symbol which identify the stream.
If KEY stream has already been opend, that stream is reused.

To save the stream to file, you can use `backup' command.
e.g.
\(esqlite-stream-send-command stream \"backup\" \"filename.sqlite\")

See other information at `esqlite-stream-open'."
  (and key (cl-check-type key symbol))
  (esqlite-check-sqlite-program)
  (cond
   ((null key)
    (esqlite-stream--open (make-symbol "unique")))
   ((esqlite-stream--reuse-memory key))
   (t (esqlite-stream--open key))))

(defun esqlite-stream-close (stream &optional timeout)
  (let ((proc stream))
    (when (eq (process-status proc) 'run)
      (with-timeout ((or timeout 5) (kill-process proc))
        ;; DO NOT use `esqlite-stream-send-command'
        ;; No need to wait prompt.
        (process-send-string proc ".quit\n")
        (let ((inhibit-redisplay t))
          (while (eq (process-status proc) 'run)
            (esqlite-sleep proc)))))
    ;;FIXME:
    ;; sometime process sentinel is not invoked.
    (kill-buffer (process-buffer proc))
    ;; delete process forcibly
    (delete-process proc)))

(defun esqlite-stream-send-command (stream command &rest args)
  "Send COMMAND and ARGS to STREAM without checking COMMAND error.
You can call this function as a API. Not need to publish user.
 Use `esqlite-stream-execute' as a high level API."
  (esqlite-stream-check-alive stream)
  (unless (string-match "\\`\\." command)
    (setq command (concat "." command)))
  (let ((line (format "%s %s" command (mapconcat 'esqlite-format-text args " "))))
    (esqlite-stream--send-command-0 stream line)))

(defun esqlite-stream-execute (stream query)
  "High level api to send QUERY to STREAM.
If QUERY is a meta-command just send the command to STREAM.
If QUERY is a sql statement, wait until prompt return just `t'."
  (esqlite-stream-check-alive stream)
  (cond
   ((string-match "\\`[\s\t\n]*\\." query)
    (esqlite-stream--send-command-0 stream query))
   (t
    (esqlite-stream--send-sql-0 stream query))))

(defun esqlite-stream-async-execute (stream query)
  "Execute QUERY in STREAM."
  (esqlite-stream-check-alive stream)
  (cond
   ((string-match "\\`[\s\t\n]*\\." query)
    (esqlite-stream--send-command-0 stream query t))
   (t
    (esqlite-stream--send-sql-0 stream query t))))

(defun esqlite-stream-read (stream query)
  "Read QUERY result from STREAM.

WARNINGS: See `esqlite-hex-to-bytes'."
  (esqlite-stream-check-alive stream)
  ;; Everytime change the NULL text to handle NULL.
  ;; Use different null text every time when executing query.
  (let (nullvalue)
    (cond
     ((process-get stream 'esqlite-stream-continue-prompt)
      (setq nullvalue (process-get stream 'esqlite-null-value)))
     (t
      (setq nullvalue (esqlite--temp-null query))
      (process-put stream 'esqlite-null-value nullvalue)
      (esqlite-stream--send-command-0
       stream (format ".nullvalue %s" nullvalue))))
    (esqlite-stream--send-sql-0 stream query)
    ;; wait until prompt is displayed.
    ;; filter function handling csv data.
    (esqlite-stream--with-buffer stream
      (esqlite--read-csv-with-deletion nullvalue))))

(defun esqlite-stream-read-top (stream query)
  "Convenience function with wrapping `esqlite-stream-read' to get a first row
of the results.

No performance advantage. You need to choose LIMIT statement by your own."
  (car-safe (esqlite-stream-read stream query)))

(defun esqlite-stream-read-atom (stream query)
  "Convenience function with wrapping `esqlite-stream-read-top'
to get a first item of the results."
  (car-safe (esqlite-stream-read-top stream query)))

(defun esqlite-stream-read-list (stream query)
  "Convenience function with wrapping `esqlite-stream-read'
to get all items as flatten list.

e.g.
SELECT item FROM hoge
 => (\"item1\" \"item2\")"
  (mapcar 'car-safe (esqlite-stream-read stream query)))

(defun esqlite-stream-prompt-p (stream)
  (esqlite-stream--with-buffer stream
    (esqlite--prompt-p)))

(defun esqlite-stream-buffer-string (stream)
  (esqlite-stream--with-buffer stream
    (buffer-string)))

(defun esqlite-stream-reset-coding-system (stream)
  (let ((dec/enc (esqlite--process-coding-system)))
    (esqlite-stream-set-coding-system
     stream (car dec/enc) (cdr dec/enc))))

(defun esqlite-stream-set-coding-system (stream &optional decoding encoding)
  "Set STREAM coding system.
Both DECODING/ENCODING are ommited, revert to default encoding/decoding."
  (esqlite-stream-check-alive stream)
  (let* ((default (process-coding-system stream))
         (new-dec (or decoding (car default)))
         (new-enc (or encoding (cdr default)))
         (multibytep (not (memq 'binary (coding-system-aliases new-dec)))))
    (esqlite-stream--with-buffer stream
      (esqlite--until-prompt stream)
      (set-buffer-multibyte multibytep))
    (set-process-coding-system stream new-dec new-enc)))

(defmacro esqlite-stream-with-transaction (stream &rest forms)
  "Execute FORMS wrapped with transaction."
  (declare (indent 1))
  (let ((stream-var (make-symbol "stream")))
    `(let ((,stream-var ,stream))
       (esqlite-stream-execute ,stream-var "BEGIN")
       (condition-case err
           (prog1
               (progn ,@forms)
             (esqlite-stream-execute ,stream-var "COMMIT"))
         (error
          ;; stream close automatically same as doing ROLLBACK.
          ;; but explicitly call this.
          (esqlite-stream-execute ,stream-var "ROLLBACK")
          (signal (car err) (cdr err)))))))

;;;
;;; Esqlite asynchronous read/execute
;;;

(defun esqlite-async-read--filter (proc event)
  (esqlite--with-parse proc event
    (let ((filter (process-get proc 'esqlite-async-filter))
          (errmsg (process-get proc 'esqlite-syntax-error)))
      (unless errmsg
        (cl-destructuring-bind (prompt-count err)
            (esqlite--read-syntax-error-at-point)
          (setq errmsg (or err t))
          (process-put proc 'esqlite-syntax-error errmsg)
          (process-put proc 'esqlite-continue-prompt prompt-count)))
      (cond
       ;; ignore if error
       ((stringp errmsg))
       ((functionp filter)
        (let* ((null (process-get proc 'esqlite-null-value))
               (data (esqlite--read-csv-with-deletion null)))
          (dolist (row data)
            (funcall filter row))))))))

(defun esqlite-async-read--sentinel (proc event)
  (esqlite--with-process proc
    (when (memq (process-status proc) '(exit))
      (let ((filter (process-get proc 'esqlite-async-filter))
            (errmsg (process-get proc 'esqlite-syntax-error)))
        (cond
         ;; ignore if error
         ((stringp errmsg))
         ((functionp filter)
          ;; If QUERY contains some error, `esqlite-async-read--maybe-error'
          ;; should report error before sentinel.
          (funcall filter :EOF)))))
    (unless (memq (process-status proc) '(run))
      (kill-buffer (current-buffer)))))

(defun esqlite-async-read--maybe-error (proc)
  (esqlite--with-process proc
    (while (not (process-get proc 'esqlite-syntax-error))
      (esqlite-sleep proc)
      (let ((cont-count (process-get proc 'esqlite-continue-prompt)))
        (when (and (numberp cont-count)
                   (> cont-count 0))
          (esqlite--fatal 'esqlite-unterminate-query
                          "Unterminated query")))
      (let ((errmsg (process-get proc 'esqlite-syntax-error)))
        (when (stringp errmsg)
          (esqlite--error "%s" errmsg))))))

;;;###autoload
(defun esqlite-async-read (file query filter &rest args)
  "Execute QUERY in esqlite FILE and immediately exit the esqlite process.
FILTER called with one arg that is parsed csv line or `:EOF'.
  Please use `:EOF' argument finish this async process.
  This FILTER is invoked in process buffer.

If QUERY contains syntax error, raise the error result before return from
this function.
ARGS accept esqlite command arguments. (e.g. -header)

WARNINGS: See `esqlite-hex-to-bytes'."
  (esqlite--check-async-interface)
  (esqlite-check-sqlite-program)
  (unless (stringp query)
    (esqlite--error "No query is provided"))
  (let* ((proc (apply 'esqlite-start-csv-process file query nil args)))
    (process-put proc 'esqlite-async-filter filter)
    (set-process-filter proc 'esqlite-async-read--filter)
    (set-process-sentinel proc 'esqlite-async-read--sentinel)
    (esqlite-async-read--maybe-error proc)
    nil))

;;;###autoload
(defun esqlite-async-execute (file query &optional finalize &rest args)
  "Utility function to wrap `esqlite-async-read'
This function expect non result set QUERY.
FINALIZE is function which call with no argument.
ARGS are passed to `esqlite-async-read'."
  (let ((filter (if finalize
                    `(lambda (xs)
                       (when (eq xs :EOF)
                         (funcall ,finalize)))
                  `(lambda (xs)))))
    (apply 'esqlite-async-read file query filter args))
  nil)

;;;
;;; Synchronous utilities
;;;

;;;###autoload
(defmacro esqlite-call/stream (file func)
  "Open FILE as esqlite database.
FUNC accept just one arg created stream object from `esqlite-stream-open'."
  (declare (indent 1))
  (let ((stream (make-symbol "stream")))
    `(let* ((,stream (esqlite-stream-open ,file))
            ;; like a synchronously function
            (inhibit-redisplay t))
       (unwind-protect
           (funcall ,func ,stream)
         (esqlite-stream-close ,stream)))))

;;;###autoload
(defmacro esqlite-call/transaction (file func)
  "Open FILE as esqlite database and begin/commit/rollback transaction.
FUNC accept just one arg created stream object from `esqlite-stream-open'."
  (declare (indent 1))
  (let ((stream (make-symbol "stream")))
    `(esqlite-call/stream ,file
       (lambda (,stream)
         (esqlite-stream-with-transaction ,stream
           (,func ,stream))))))

;;
;; Esqlite synchronous read/execute
;;

;;;###autoload
(defun esqlite-read (file query &rest args)
  "Read QUERY result from sqlite FILE.
This function designed with SELECT QUERY, but works fine another
 sql query (UPDATE/INSERT/DELETE).

ARGS accept some of sqlite command arguments but do not use it
 unless you understand what you are doing.

WARNINGS: See `esqlite-hex-to-bytes'."
  (esqlite-check-sqlite-program)
  (with-temp-buffer
    (let* ((nullvalue (esqlite--temp-null query))
           (exit-code (apply 'esqlite-call-csv-process
                             file query nullvalue args)))
      (goto-char (point-min))
      (cl-destructuring-bind (prompt-count errmsg)
          (esqlite--read-syntax-error-at-point)
        (cond
         ((not (stringp errmsg)))
         ((string-match "incomplete SQL" errmsg)
          ;; special handling
          (esqlite--fatal 'esqlite-unterminate-query
                          "Unterminated query"))
         (t
          (esqlite--error "%s" errmsg))))
      ;; I couldn't check exit code is non-zero
      ;; but check it
      (unless (eq exit-code 0)
        ;; raise error anyway
        (esqlite--error "%s" (buffer-string)))
      (esqlite--read-csv-with-deletion nullvalue))))

;;;###autoload
(defun esqlite-read-top (file query &rest args)
  "Convenience function with wrapping `esqlite-read' to get a first row
of the results.

No performance advantage. You need to choose LIMIT statement by your own."
  (car-safe (apply 'esqlite-read file query args)))

;;;###autoload
(defun esqlite-read-atom (file query &rest args)
  "Convenience function with wrapping `esqlite-read-top' to get a first item
of the results."
  (car-safe (apply 'esqlite-read-top file query args)))

;;;###autoload
(defun esqlite-read-list (file query &rest args)
  "Convenience function with wrapping `esqlite-stream-read'
to get all first column as list.

e.g.
SELECT item FROM hoge
 => (\"item1\" \"item2\")"
  (mapcar 'car-safe (apply 'esqlite-read file query args)))

;;;###autoload
(defun esqlite-execute (file sql)
  "Same as `esqlite-read' but intentional to use non SELECT statement."
  (esqlite-read file sql)
  nil)

;;
;; Read object from esqlite database (Generic functions)
;;

(defun esqlite-read--objects (stream-or-file &optional type)
  (let* ((query
          (esqlite-prepare
           `(
             "SELECT name "
             " FROM sqlite_master "
             " WHERE 1 = 1 "
             ,@(and type
                    `(" AND type = %T{type}"))
             " ORDER BY name ASC")
           :type type))
         (reader (if (esqlite-stream-p stream-or-file)
                     'esqlite-stream-read-list
                   'esqlite-read-list)))
    (funcall reader stream-or-file query)))

;;;###autoload
(defun esqlite-read-all-objects (stream-or-file)
  (esqlite-read--objects stream-or-file))

;;;###autoload
(defun esqlite-read-views (stream-or-file)
  (esqlite-read--objects stream-or-file "view"))

;;;###autoload
(defun esqlite-read-tables (stream-or-file)
  (esqlite-read--objects stream-or-file "table"))

;;;###autoload
(defun esqlite-read-indexes (stream-or-file)
  (esqlite-read--objects stream-or-file "index"))

;;;###autoload
(defun esqlite-read-triggers (stream-or-file)
  (esqlite-read--objects stream-or-file "trigger"))

;;;###autoload
(defun esqlite-read-table-columns (stream-or-file table)
  (cl-loop for (_r1 col . _ignore) in (esqlite-read-table-schema stream-or-file table)
           collect col))

;;;###autoload
(defun esqlite-read-table-schema (stream-or-file table)
  "Get TABLE information in STREAM-OR-FILE.
Elements of the item list are:
0. cid
1. name with lowcase
2. type with UPCASE
3. not null (boolean)
4. default_value
5. primary key order start from 1 (integer)"
  (cl-loop with reader = (if (esqlite-stream-p stream-or-file)
                             'esqlite-stream-read
                           'esqlite-read)
           for row in (funcall
                       reader stream-or-file
                       (esqlite-prepare
                        "PRAGMA table_info(%o{table})"
                        :table table))
           collect (list
                    (string-to-number (nth 0 row))
                    (downcase (nth 1 row))
                    (upcase (nth 2 row))
                    (equal (nth 3 row) "1")
                    (nth 4 row)
                    (let ((n (string-to-number (nth 5 row))))
                      (and (> n 0) n)))))

(defun esqlite-file-tables (file)
  "Sqlite FILE tables"
  (esqlite-read-tables file))

(defun esqlite-file-table-columns (file table)
  "Sqlite FILE TABLE columns"
  (esqlite-read-table-columns file table))

(defun esqlite-file-table-schema (file table)
  "See `esqlite-read-table-schema'"
  (esqlite-read-table-schema file table))

(make-obsolete 'esqlite-file-tables 'esqlite-read-tables "0.1.4")
(make-obsolete 'esqlite-file-table-columns 'esqlite-read-table-columns "0.1.4")
(make-obsolete 'esqlite-file-table-schema 'esqlite-read-table-schema "0.1.4")

;;;
;;; Package load/unload
;;;

(defun esqlite-killing-emacs ()
  (dolist (proc (process-list))
    (when (process-get proc 'esqlite-stream-process-p)
      (condition-case err
          (esqlite-stream-close proc)
        (error (message "esqlite: %s" err)))))
  (when (and (stringp esqlite--default-init-file)
             (file-exists-p esqlite--default-init-file))
    (delete-file esqlite--default-init-file)))

(defun esqlite-unload-function ()
  (remove-hook 'kill-emacs-hook 'esqlite-killing-emacs))

(add-hook 'kill-emacs-hook 'esqlite-killing-emacs)

(provide 'esqlite)

;;; esqlite.el ends here
