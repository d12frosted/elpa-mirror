;;; cov.el --- Show coverage stats in the fringe. -*- lexical-binding: t -*-

;; Copyright (C) 2016-2017 Adam Niederer

;; Author: Adam Niederer
;; Maintainer: Adam Niederer
;; Created: 12 Aug 2016

;; Keywords: coverage gcov c
;; Package-Version: 20210330.44
;; Package-Commit: 62a4650f97eddebf6cd04b662a69b15ba72472c1
;; Homepage: https://github.com/AdamNiederer/cov
;; Version: 0.1.0
;; Package-Requires: ((emacs "24.4") (f "0.18.2") (s "1.11.0") (elquery))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This mode locates and parses multiple coverage formats and display
;; coverage using fringe overlays.

;;; Code:

(require 'f)
(require 'cl-lib)
(require 'json)
(require 'seq)
(require 'subr-x)
(require 'filenotify)
(require 'elquery)

(defgroup cov nil
  "The group for everything in cov.el"
  :group 'tools)

(defgroup cov-faces nil
  "Faces for cov."
  :group 'cov)

(defcustom cov-high-threshold .85
  "The threshold at which a line will be painted with `cov-heavy-face'.

This is a ratio of the run count of the most-run line;
any line exceeding this fraction of the highest line run count
will be painted with `cov-heavy-face'."
  :tag "Cov heavy-use threshold"
  :group 'cov
  :type 'float)

(defcustom cov-med-threshold .45
  "The threshold at which a line will be painted with `cov-med-face'.

This is a ratio of the run count of the most-run line;
any line exceeding this fraction of the highest line run count
will be painted with `cov-med-face'."
  :tag "Cov medium-use threshold"
  :group 'cov
  :type 'float)

(defcustom cov-coverage-mode nil
  "Whether to only show whether lines are covered or uncovered.

If t, covered lines are decorated with `cov-coverage-run-face',
and uncovered lines are decorated with `cov-coverage-not-run-face'.

If nil, covered lines are decorated with `cov-light-face',
`cov-med-face', or `cov-heavy-face', depending on how often it
was run."
  :tag "Cov coverage mode"
  :group 'cov
  :type 'boolean)

(defcustom cov-fringe-symbol 'empty-line
  "The symbol to display on each line while in coverage-mode.
See `fringe-bitmaps' for a full list of options"
  :tag "Cov fringe symbol"
  :group 'cov
  :type 'symbol)

(defface cov-heavy-face
  '((((class color)) :foreground "red"))
  "Fringe indicator face used for heavily-run lines See `cov-high-threshold'."
  :tag "Cov heavy-use face"
  :group 'cov-faces)

(defface cov-med-face
  '((((class color)) :foreground "yellow"))
  "Fringe indicator face used for commonly-run lines See `cov-med-threshold'."
  :tag "Cov medium-use face"
  :group 'cov-faces)

(defface cov-light-face
  '((((class color)) :foreground "green"))
  "Fringe indicator face used for rarely-run lines.

This face is applied if no other face is applied."
  :tag "Cov light-use face"
  :group 'cov-faces)

(defface cov-none-face
  '((((class color)) :foreground "blue"))
  "Fringe indicator face used for lines which were not run."
  :tag "Cov never-used face"
  :group 'cov-faces)

(defface cov-coverage-run-face
  '((((class color)) :foreground "green"))
  "Fringe indicator face used in coverage mode for lines which were run.

See `cov-coverage-mode'"
  :tag "Cov coverage mode run face"
  :group 'cov-faces)

(defface cov-coverage-not-run-face
  '((((class color)) :foreground "red"))
  "Fringe indicator face used in coverage mode for lines which were not run. See
`cov-coverage-mode'"
  :tag "Cov coverage mode not-run face"
  :group 'cov-faces)

(defvar cov-coverage-alist '((".gcov" . gcov))
  "Alist of coverage tool and file postfix.

Each element looks like (FILE-POSTIX . COVERAGE-TOOL).  If a file
with FILE-POSTIX appended to the current value of variable
`buffer-file-name' is found, it is assumed that the specified
COVERAGE-TOOL has created the data.

Currently the only supported COVERAGE-TOOL is gcov.")

(defvar cov-coverage-file-paths
  '("." cov--locate-coveralls cov--locate-clover cov--locate-coveragepy)
  "List of paths or functions returning file paths containing coverage files.

Relative paths:
 .      search in current directory
 cov    search in subdirectory cov
 ..     search in parent directory
 ../cov search in subdirectory cov of parent directory

Function:

A function or lambda that should get the buffer file dir and name
as arguments and return either nil or the truename path to the
coverage file and the corresponding coverage tool in a cons cell
of the form (COV-FILE-PATH . COVERAGE-TOOL).  The following
example sets a lambda that searches the coverage file in the
current directory:

  (setq cov-coverage-file-paths
   (list #'(lambda (file-dir file-name)
             (let ((try (format \"%s/%s%s\"
                                file-dir file-name
                                cov-coverage-file-extension)))
               (and (file-exists-p try)
                    (cons (file-truename try) 'gcov))))))")

(defvar-local cov-coverage-file nil
  "Last located coverage file and tool.")

(defvar cov-coverages (make-hash-table :test 'equal)
  "Storage of coverage data.")

(defsubst cov--message (format-string &rest args)
  "Call (`message' FORMAT-STRING ARGS) unless `noninteractive' is non-nil."
  (unless noninteractive (apply #'message format-string args)))

(defun cov--locate-coverage-postfix (file-dir file-name path extension)
  "Return full path of coverage file, if found.

Look in FILE-DIR for FILE-NAME, under PATH, with extension EXTENSION."
  (let ((try (format "%s/%s/%s%s" file-dir path file-name extension)))
    (and (file-exists-p try) (file-truename try))))

(defun cov--locate-coverage-path (file-dir file-name path)
  "Locate coverage file.

Look in FILE-DIR for coverage for FILE-NAME in PATH."
  (cl-some (lambda (extension-tool)
             (let* ((extension (car extension-tool))
                    (tool (cdr extension-tool))
                    (file (cov--locate-coverage-postfix file-dir file-name path extension)))
               (and file (cons file tool))))
           cov-coverage-alist))

(defun cov--locate-coverage (file-path)
  "Locate coverage file of given source file FILE-PATH.

The function iterates over `cov-coverage-file-path' for path
candidates or locate functions. The first found file will be
returned as a cons cell of the form (COV-FILE-PATH .
COVERAGE-TOOL). If no file is found nil is returned."
  (let ((file-dir (f-dirname file-path))
        (file-name (f-filename file-path)))
    (cl-some (lambda (path-or-fun)
               (if (stringp path-or-fun)
                   (cov--locate-coverage-path file-dir file-name path-or-fun)
                 (funcall path-or-fun file-dir file-name)))
             cov-coverage-file-paths)))

(defun cov--locate-coveralls (file-dir _file-name)
  "Locate coveralls coverage from FILE-DIR for FILE-NAME.

Looks for a `coverage-final.json' file. Return nil it not found."
  (let ((dir (locate-dominating-file file-dir "coverage-final.json")))
    (when dir
      (cons (file-truename (f-join dir "coverage-final.json")) 'coveralls))))

(defun cov--locate-clover (file-dir _file-name)
  "Locate clover coverage from FILE-DIR for FILE-NAME.

Looks for a `clover.xml' file. Return nil it not found."
  (let ((dir (locate-dominating-file file-dir "clover.xml")))
    (when dir
      (cons (file-truename (f-join dir "clover.xml")) 'clover))))

(defun cov--locate-coveragepy (file-dir _file-name)
  "Locate file \"coverage.json\" starting at FILE-DIR."
  (let ((dir (locate-dominating-file file-dir "coverage.json")))
    (when dir
      (cons (file-truename (f-join dir "coverage.json")) 'coveragepy))))

(defun cov--coverage ()
  "Return coverage file and tool.

Returns a cons cell of the form (COV-FILE-PATH . COVERAGE-TOOL)
for current buffer.

If `cov-coverage-file' is non nil, the value of that variable is
returned. Otherwise `cov--locate-coverage' is called."
  (or cov-coverage-file
      ;; In case we're enabled in a buffer without a file.
      (when (buffer-file-name)
        (setq cov-coverage-file (cov--locate-coverage (buffer-file-name))))))

(defun cov--gcov-parse (&optional buffer)
  "Parse gcov coverage from gcov file in BUFFER.

Read from `current-buffer' if BUFFER is nil. Return a list
`((FILE . ((LINE-NUM TIMES-RAN) ...)))'. Unused lines (TIMES-RAN
'-') are filtered out."
  (with-current-buffer (or buffer (current-buffer))
	;; The buffer is _not_ automatically widened. It is possible to
	;; read just a portion of the buffer by narrowing it first.
	(let ((line-re (rx line-start
					   ;; note the group numbers are in reverse order
					   ;; in the first alternative
					   (or (seq (* blank) (group-n 2 (+ (in digit ?#))) ?:
								(* blank) (group-n 1 (+ digit)) ?:)
						   (seq "lcount:" (group-n 1 (+ digit)) ?, (group-n 2 (+ digit))))))
		  ;; Derive the name of the covered file from the filename of
		  ;; the coverage file.
		  (filename (file-name-sans-extension (f-filename cov-coverage-file))))
	  (save-excursion
		(save-match-data
		  (goto-char (point-min))
		  (list (cons filename
					  (cl-loop
					   while (re-search-forward line-re nil t)
					   collect (list (string-to-number (match-string 1))
									 (string-to-number (match-string 2)))))))))))

(defun cov--coveralls-parse ()
  "Parse coveralls coverage.

Parse coveralls data in `(current-buffer)' and return a list
of (FILE . (LINE-NUM TIMES-RAN))."
  (let*
      ((json-object-type 'hash-table)
       (json-array-type 'list)
       (coverage (json-read))
       (matches (list)))
    (dolist (source (gethash "source_files" coverage))
      (let ((file-coverage (list))
            (linenum 1))
        (dolist (count (gethash "coverage" source))
          (when count
            (push (list linenum count) file-coverage))
          (setq linenum (+ linenum 1)))
        (push (cons (gethash "name" source) file-coverage) matches)))
    matches))

(defun cov--clover-parse ()
  "Parse clover coverage.

Parse clover data in `(current-buffer)' and return a list
of (FILE . (LINE-NUM TIMES-RAN))."
  (let ((xml (elquery-read-string (buffer-string)))
        (matches (list)))
    (when xml
      (dolist (file (elquery-$ "coverage project package file" xml))
        ;; Seems there's some disagreement between tools as to where
        ;; to put the file path. PHPUnit puts it in `name', while Jest
        ;; puts the basename in `name' and the full path and filename
        ;; in `path'.
        (let* ((file-name (or (elquery-prop file "path") (elquery-prop file "name")))
               (common (f-common-parent (list file-name cov-coverage-file)))
               (file-coverage (list)))
          (dolist (line (elquery-$ "line" file))
            (let ((line-num (string-to-number (elquery-prop line "num")))
                  (line-count (string-to-number (elquery-prop line "count"))))
              (unless (equal line-num 0)
                (push (list line-num line-count) file-coverage))))
          ;; Clover uses absolute filenames, so we remove the common prefix.
          (push (cons (string-remove-prefix common file-name) file-coverage) matches))))
    matches))

(defun cov--coveragepy-parse ()
  "Parse JSON coverage file from project coveragepy.

This function parses a JSON file created by coveragepy. Note that
by default coveragepy creates a binary coverage file named \".coverage\"
by running

   coverage3 run myfile.py

from the command line. This file must be converted to JSON afterwards
by running

   coverage3 json

which will create a JSON file \"coverage.json\". This function only parses
the JSON file, it does not create the file.

Coveragepy just reports whether or not a certain line of code was executed.
But it does not report how many times a certain line was executed.

Project coveragepy is released at <https://github.com/nedbat/coveragepy/>.
"
  (let*
      ((json-object-type 'hash-table)
       (json-array-type 'list)
       (coverage (json-read))
       (matches (list)))
    (maphash (lambda (filename file-value)
               (push (cons filename
                           (append
                            (mapcar (lambda (line) (list line 1))
                                    (gethash "executed_lines" file-value))
                            (mapcar (lambda (line) (list line 0))
                                    (gethash "missing_lines" file-value))))
                     matches))
             (gethash "files" coverage))
    matches))

(defun cov--read-and-parse (file-path format)
  "Read coverage file FILE-PATH in FORMAT into temp buffer and parse it using `cov--FORMAT-parse'."
  (with-temp-buffer
    (insert-file-contents file-path)
    (setq-local cov-coverage-file file-path)
    (funcall (intern (concat "cov--"  (symbol-name format) "-parse")))))

(defun cov--make-overlay (line fringe help)
  "Create an overlay for the LINE.

Uses the FRINGE and sets HELP as `help-echo'."
  (let ((ol (save-excursion
              (goto-char (point-min))
              (forward-line (1- line))
              (make-overlay (point) (line-end-position)))))
    (overlay-put ol 'before-string fringe)
    (overlay-put ol 'help-echo help)
    (overlay-put ol 'cov t)
    ol))

(defun cov--get-face (percentage)
  "Get the appropriate face for the PERCENTAGE coverage.

Selects the face depending on user preferences and the code's
execution frequency"
  (cond
   ((and cov-coverage-mode (> percentage 0))
    'cov-coverage-run-face)
   ((and cov-coverage-mode (= percentage 0))
    'cov-coverage-not-run-face)
   ((< cov-high-threshold percentage)
    'cov-heavy-face)
   ((< cov-med-threshold percentage)
    'cov-med-face)
   ((> percentage 0)
    'cov-light-face)
   (t 'cov-none-face)))

(defun cov--get-fringe (percentage)
  "Return the fringe with the correct face for PERCENTAGE."
  (propertize "f" 'display `(left-fringe ,cov-fringe-symbol ,(cov--get-face percentage))))

(defun cov--help (n percentage)
  "Return help text for the given N count and PERCENTAGE."
  (format "cov: executed %d times (~%.2f%% of highest)" n (* percentage 100)))

(defun cov--set-overlay (line max)
  "Set the overlay for LINE.

MAX is the maximum coverage count for any line in the file."
  (let* ((times-executed (nth 1 line))
         (percentage (/ times-executed (float max))))
    (cov--make-overlay
     (car line)
     (cov--get-fringe percentage)
     (cov--help times-executed percentage))))

(defsubst cov--file-mtime (file)
  "Return the last modification time of FILE."
  (nth 5 (file-attributes file)))

;; Structure for coverage data.
(cl-defstruct cov-data
  "Holds data about a coverage data file, which can hold coverage
data for several source code files."
  (type nil :type symbol :documentation "The coverage type, such as `gcov'.")
  (mtime nil :type time :documentation "The mtime for the coverage file last time it was read.")
  (buffers nil :type list :documentation "List of `cov-mode' buffers referring to this coverage data.")
  (watcher nil :type watcher :documentation "The file notification watcher.")
  (coverage nil :type alist :documentation "An alist of (FILE . ((LINE-NUM TIMES-RAN) ...)).")
  )

(defsubst cov-data--add-buffer (coverage buffer)
  "Add BUFFER to COVERAGE if it not already there."
  (cl-pushnew buffer (cov-data-buffers coverage)))

(defsubst cov-data--remove-buffer (coverage buffer)
  "Remove BUFFER from COVERAGE.
Return the list of remaining buffers."
  (setf (cov-data-buffers coverage) (cl-delete buffer (cov-data-buffers coverage))))

(defsubst cov-data--unregister-watcher (coverage)
  "Unregister and remove any file watcher from COVERAGE."
  (when (cov-data-watcher coverage)
    (file-notify-rm-watch (cov-data-watcher coverage))
    (setf (cov-data-watcher coverage) nil)))

(defun cov--stored-data (file type)
  "Get the `cov-data' object for FILE from `cov-coverages'.
If no object exist, create one with TYPE."
  (or (gethash file cov-coverages)
      (puthash file (make-cov-data :type type) cov-coverages)))

(defun cov--get-buffer-coverage ()
  "Return coverage for current buffer.

Finds the coverage data for the file in `cov-coverages', loading
it if necessary, or reloading if the file has changed."
  (let ((cov (cov--coverage)))
    (when cov
      (let* ((file (car cov))
             (stored-data (cov--stored-data file (cdr cov))))
        ;; Register current buffer as user of this coverage.
        (cov-data--add-buffer stored-data (current-buffer))
        ;; Start file watching...
        (when (and file-notify--library                    ; if available
                   (null (cov-data-watcher stored-data)))  ; not already watched
          ;; We're watching the directory of the file rather than
          ;; the file itself in order to catch deletion and
          ;; re-creation of the file.
          (setf (cov-data-watcher stored-data)
                (file-notify-add-watch
                 (f-dirname file)
                 '(change)
                 (lambda (event)
                   (cov-watch-callback file event)))))
        ;; Load coverage if needed.
        (cov--load-coverage stored-data file t)

        (add-hook 'kill-buffer-hook 'cov-kill-buffer-hook nil t)
        ;; Find file coverage.
        (let ((common (f-common-parent (list file (buffer-file-name)))))
          (cdr (assoc (string-remove-prefix common (buffer-file-name))
                      (cov-data-coverage stored-data))))))))

(defun cov--load-coverage (coverage file &rest ignore-current)
  "Load coverage data into COVERAGE from FILE.

Won't update `(current-buffer)' if IGNORE-CURRENT is non-nil."
  ;; File mtime changed or never set, reload.
  (unless (and (equal (cov-data-mtime coverage)
                      (cov--file-mtime file)))
    (cov--message "Reloading coverage file %s." file)
    (setf (cov-data-coverage coverage) nil))
  (unless (cov-data-coverage coverage)
    (setf (cov-data-coverage coverage) (cov--read-and-parse file (cov-data-type coverage)))
    (setf (cov-data-mtime coverage) (cov--file-mtime file))
    ;; Update buffers using this coverage.
    (let ((buffers (cov-data-buffers coverage)))
      (when ignore-current
        (setq buffers (remove (current-buffer) buffers)))
      (dolist (buffer buffers)
        (with-current-buffer buffer
          (cov--message "Updating coverage for \"%s\"" (buffer-name buffer))
          (cov-update))))))

(defun cov-kill-buffer-hook ()
  "Unregister buffer with coverage data and clean out unused coverage."
  ;; Only clean up when buffer have a file name. Buffers without a file
  ;; cannot have coverage.
  (when (buffer-file-name)
    (dolist (file (hash-table-keys cov-coverages))
      (let* ((coverage (gethash file cov-coverages)))
        (unless (cov-data--remove-buffer coverage (current-buffer))
          (cov-data--unregister-watcher coverage)
          (remhash file cov-coverages))))))

(defun cov-watch-callback (file event)
  "Trigger reload of coverage data on FILE change.

EVENT is of the form:

  (DESCRIPTOR ACTION FILE [FILE1])"
  (let ((event-type (nth 1 event))
        (event-file (nth 2 event)))
    (when (and (equal file event-file) (member event-type '(created changed)))
      (let ((coverage (gethash file cov-coverages)))
        (when coverage
          (setf (cov-data-coverage coverage) nil)
          (cov--load-coverage coverage file))))))

(defun cov-set-overlays ()
  "Add cov overlays.
Only add overlays to lines with at least one visible character in
a narrowed buffer. Overlays will always cover the full line
even if part of the line is outside any narrrowing."
  (interactive)
  (let* ((lines (cov--get-buffer-coverage))
         ;; The limits of any narrowing of the buffer, excluding
         ;; leading and ending single newline
         (begin (save-excursion (goto-char (point-min)) (if (eolp) (1+ (point)) (point))))
         (end (save-excursion (goto-char (point-max)) (if (bolp) (1- (point)) (point))))
         ;; The highest execution count of any line
         (max (cl-reduce 'max lines :initial-value 0 :key #'cl-second)))
    (if lines
        (save-restriction
          (widen)
          (setq begin (line-number-at-pos begin)
                end (line-number-at-pos end))
          (cl-loop for line-data in lines
                   for line-number = (car line-data)
                   if (and (<= begin line-number)
                           (<= line-number end))
                   do (cov--set-overlay line-data max)))
      (when (buffer-file-name)
        (message "No coverage data found for %s." (buffer-file-name))))))

(defun cov-clear-overlays ()
  "Remove all cov overlays."
  (interactive)
  (remove-overlays (point-min) (point-max) 'cov t))

(defun cov--overlays ()
  "Return a list of all cov overlays."
  (seq-filter (lambda (ov) (overlay-get ov 'cov))
              (overlays-in (point-min) (point-max))))

(defun cov-visit-coverage-file ()
  "Visit coverage file."
  (interactive)
  (let ((cov (cov--coverage)))
    (if cov
        (find-file (car cov))
      (message "No coverage data found."))))

(defun cov-update ()
  "Turn on cov-mode."
  (interactive)
  (cov-clear-overlays)
  (cov-set-overlays))

(defun cov-turn-on ()
  "Turn on cov-mode."
  (cov-clear-overlays)
  (cov-set-overlays))

(defun cov-turn-off ()
  "Turn off cov-mode."
  (cov-clear-overlays))

;;;###autoload
(define-minor-mode cov-mode
  "Minor mode for cov."
  :lighter " cov"
  (progn
    (if cov-mode
        (cov-turn-on)
      (cov-turn-off))))

(provide 'cov)
;;; cov.el ends here

;; Local Variables:
;; indent-tabs-mode: nil
;; sentence-end-double-space: nil
;; End:
