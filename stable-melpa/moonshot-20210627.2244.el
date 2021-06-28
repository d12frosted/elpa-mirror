;;; moonshot.el --- Run executable file, debug and build commands on project  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Jong-Hyouk Yun

;; Author: Jong-Hyouk Yun <ageldama@gmail.com>
;; URL: https://github.com/ageldama/moonshot
;; Package-Commit: ec37a12825888047a90d9ee8131aa4bea348edf7
;; Package-Version: 20210627.2244
;; Package-X-Original-Version: 1.0.0
;; Version: 1.0.0
;; Package-Requires: ((emacs "25.1") (cl-lib "0.5") (f "0.18") (s "1.11.0") (projectile "2.0.0") (counsel "0.11.0") (realgud "1.5.1") (seq "2.20") (levenshtein "1.0"))
;; Keywords: convenience, files, processes, tools, unix

;;; License:

;; This program is free software; you can redistribute it and/or modify
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
;; This package locates a project build directory for the current
;; buffer, and makes it easier to run common debug and execution
;; commands from that directory.
;;
;; << Determining the Project Build Directory >>
;;
;; 1) If file local variable `moonshot-project-build-dir' is set:
;;   a) if it starts with "/", use it as-is
;;   b) if it does not start with "/":
;;      - Append it to project root directory or the directory of current buffer.
;;      - If the directory of current buffer is not available, it's nil.
;;   c) if it is a sexp, run `eval' on it and return the value
;;   d) Implemented in `moonshot-project-build-dir-by-value' function.
;; 2) Otherwise, check projectile
;; 3) Otherwise, use the directory of current buffer

;; << Launching an Executable >>
;;
;;  This is accomplished using `moonshot-run-executable':
;;  1) It will search executable files under `moonshot-project-build-dir'.
;;  2) It will suggest executable files based on the buffer filename.

;; << Launching a Debugger with Executable >>
;;
;;  This is accomplished using `moonshot-run-debugger':
;;  - Similar to `moonshot-run-executable', choose an executable to debug.
;;  - The supported debuggers are listed in `moonshot-debuggers'.

;; << Running a Shell Command in Compilation-Mode >>
;;
;;  This is accomplished using `moonshot-run-runner':
;;  - Global shell command presets are `moonshot-runners-preset'.
;;  - Per project commands can be added to `moonshot-runners', by specifying variable in `.dir-locals.el' etc.
;;
;;  <<< Command String Expansion >>>
;;    - The following format specifiers are will expanded in command string:
;;      %a  absolute pathname            ( /usr/local/bin/netscape.bin )
;;      %f  file name without directory  ( netscape.bin )
;;      %n  file name without extension  ( netscape )
;;      %e  extension of file name       ( bin )
;;      %d  directory                    ( /usr/local/bin/ )
;;      %p  project root directory       ( /home/who/blah/ ), using Projectile
;;      %b  project build directory      ( /home/who/blah/build/ ), using `moonshot-project-build-dir'"

;;; Code:
(require 'cl-lib)
(require 'f)
(require 's)
(require 'realgud)
(require 'seq)
(require 'levenshtein)
(require 'projectile)

;;; --- Variables

(defvar-local moonshot-project-build-dir nil
  "Project build directory. Can be a string or a form.")
(put 'moonshot-project-build-dir 'safe-local-variable #'stringp)

(defvar-local moonshot-debuggers
  '(;; `COMMAND' . `DEBUGGER-FN'
    ("gdb #realgud" . realgud:gdb)
    ("gdb #gud" . gud-gdb)
    ("lldb #realgud" . realgud:lldb)
    ("python -mpdb #realgud" . realgud:pdb)
    ("perldb #realgud" . realgud:perldb)
    ("pydb #realgud" . realgud:pydb)
    ("gub #realgud" . realgud:gub)
    ("jdb #realgud" . realgud:jdb)
    ("bashdb #realgud" . realgud:bashdb)
    ("remake #realgud" . realgud:remake)
    ("zshdb #realgud" . realgud:zshdb)
    ("kshdb #realgud" . realgud:kshdb)
    ("dgawk #realgud" . realgud:dgawk))
  "Supported debuggers.")

(defvar-local moonshot-runners-preset
  '("cmake -S\"%p\" -B\"%b\" -GNinja -DCMAKE_BUILD_TYPE=Debug -DCMAKE_EXPORT_COMPILE_COMMANDS=on"
    "cd \"%p\"; ninja -v"
    "cd \"%p\"; VERBOSE=1 make"
    "cd \"%b\"; ninja"
    "source \"${VIRTUAL_ENV}/bin/activate\"; cd \"%d\"; \"%a\"  # Run with Virtualenv"
    "source \"${VIRTUAL_ENV}/bin/activate\"; cd \"%d\"; pip install -r requirements.txt  # Run with Virtualenv"
    "source \"%b/bin/activate\"; cd \"%p\"; \"%a\"  # Run with Virtualenv"
    "cd \"%p\"; \"%a\"  # Run script"
    "clang-format -i \"%a\""
    "clang-tidy -p \"%b\" \"%a\" #--fix")
  "Available shell command presets.")

(defvar-local moonshot-runners
  nil
  "Shell commands for file variables / `.dir-locals.el'.")

(defvar-local moonshot-file-name-distance-function
  #'levenshtein-distance
  "A function to calculate distance between filenames.")



;;; --- Project Build Directory
(defun moonshot-project-build-dir-by-value (val)
  "Composes the build directory path string by VAL."
  (let ((path (cl-typecase val
                (string (if (s-starts-with? "/" val)
                            val ; absolute-path
                          ;; relative-path
                          (s-concat (or (projectile-project-root)
                                        default-directory) val)))
                (t (eval val)))))
    (when-let ((it path))
      (unless (f-exists? it)
        (error "Invalid path or File/directory not found: %s" it)))
    (expand-file-name path)))

(defun moonshot-project-build-dir ()
  "Find the build directory by one of following methods sequentially:

1) File local variable `moonshot-project-build-dir', and if it is:
  1) a string starts with '/, use it,
  2) a string and does not starts with '/',
     - Append it to project root directory or the directory of current buffer.
     - If the directory of current buffer is not available, it's nil.
  3) a list, returns the value of `eval'-ed on it.
  4) Implemented in `moonshot-project-build-dir-by-value' function.

2) Ask to Projectile

3) Just the directory of current buffer

Thus, can be evaluated as nil on some special buffers.
For example, '*scratch*'-buffer"
  (or (when-let ((it moonshot-project-build-dir)) ; file local variable
        (moonshot-project-build-dir-by-value it))
      (projectile-project-root)
      default-directory))


;;; --- Run/Debug
(defun moonshot-list-executable-files (dir)
  "Find every executable files under DIR.
Evaluates as nil when DIR is nil."
  (if dir
      (seq-filter 'file-executable-p
                  (directory-files-recursively
                   dir ".*"))
    ;; `dir'=nil => empty
    nil))

(defun moonshot-file-list->distance-alist (fn file-names)
  "Calculate string difference distances from FN of given FILE-NAMES.
By using `moonshot-file-name-distance-function'.
Evaluates as nil when FN or FILE-NAMES is nil."
  (cl-block file-list->dist-alist
    (unless (and fn file-names)
      (cl-return-from file-list->dist-alist nil))
    (let ((fn* (f-filename fn)))
      (mapcar (lambda (i)
                (cons (funcall moonshot-file-name-distance-function
                               fn* (f-filename i))
                      i))
              file-names))))

(defun moonshot-list-executable-files-and-sort-by (dir file-name)
  "Find every executable file names under DIR.
The list is sorted by `file-list->distance-alist' with FILE-NAME."
  (message "Searching in '%s' for '%s' ..." dir file-name)
  (if file-name
      (mapcar #'cdr
              (sort
               (moonshot-file-list->distance-alist
                file-name
                (moonshot-list-executable-files dir))
               (lambda (x y) (< (car x) (car y)))))
    ;; else, no sorting
    (moonshot-list-executable-files dir)))
;; Try: (list-executable-files-and-sort-by "/bin" "sh")

(defun moonshot-run-command-with (cmd mkcmd-fun run-fun)
  "Read and Run with RUN-FUN and pass CMD filtered by MKCMD-FUN as parameter."
  (let* ((cmd*
          (read-from-minibuffer "Cmd: " (funcall mkcmd-fun cmd))))
    (funcall run-fun cmd*)))

(defun moonshot-%make-simple-completing-read-collection (coll)
  "Prepare simplest form of a collection for `completing-read' from COLL."
  (mapcar (lambda (i) (list i i)) coll))

;;;###autoload
(defun moonshot-run-executable ()
  "Select an executable file in command `moonshot-project-build-dir', similar to buffer filename."
  (interactive)
  (let* ((fn (buffer-file-name))
         (coll (moonshot-%make-simple-completing-read-collection
                (moonshot-list-executable-files-and-sort-by (moonshot-project-build-dir) fn)))
         (cmd (completing-read "Select an executable to run: " coll)))
    (moonshot-run-command-with cmd
                               (lambda (cmd)
                                 (format "cd '%s'; '%s'" (f-dirname cmd) cmd))
                               #'compile)))
 
(defun moonshot-alist-keys (l)
  "CARs of an Alist L."
  (cl-loop for i in l collect (car i)))



(defun moonshot-%remove-sharp-comment (s)
  "Remove shell comment section from string S."
  (s-trim (replace-regexp-in-string  "\\#.*$" "" s)))


;;;###autoload
(defun moonshot-run-debugger ()
  "Launch debugger, one of `moonshot-debuggers', with an executable selection."
  (interactive)
  (let* ((selected-debugger (completing-read "Select debugger: "
                                             (moonshot-%make-simple-completing-read-collection
                                              (moonshot-alist-keys moonshot-debuggers))))
         (fn (buffer-file-name))
         (debugger-cmd (moonshot-%remove-sharp-comment selected-debugger))
         (debugger-func (cdr (assoc selected-debugger moonshot-debuggers)))
         (cmd (completing-read "Select an executable to debug: "
                               (moonshot-%make-simple-completing-read-collection
                                (moonshot-list-executable-files-and-sort-by
                                 (moonshot-project-build-dir) fn)))))
    (moonshot-run-command-with cmd
                               (lambda (cmd)
                                 (format "%s \"%s\""
                                         debugger-cmd cmd))
                               debugger-func)))


;;; Runner
(defun moonshot-all-runners ()
  "Collect available runners."
  (append moonshot-runners moonshot-runners-preset))

(defun moonshot-expand-path-vars (path-str)
  "Expand PATH-STR with following format specifiers.

%a  absolute pathname            ( /usr/local/bin/netscape.bin )
%f  file name without directory  ( netscape.bin )
%n  file name without extension  ( netscape )
%e  extension of file name       ( bin )
%d  directory                    ( /usr/local/bin/ )
%p  project root directory       ( /home/who/blah/ ), using Projectile
%b  project build directory      ( /home/who/blah/build/ ), using variable `moonshot-project-build-dir'"
  (let* ((s path-str)
         (abs-path (or (buffer-file-name) ""))
         (file-name "")
         (file-name-without-ext "")
         (file-ext "")
         (dir (or default-directory ""))
         (project-root-dir (projectile-project-root))
         (project-build-dir (moonshot-project-build-dir)))
    ;; fill in
    (unless (s-blank-str? abs-path)
      (setq file-name (or (f-filename abs-path) "")
            file-ext (or (f-ext file-name) ""))
      (unless (or (s-blank-str? dir)
                  (s-suffix? "/" dir))
        (setq dir (s-concat dir "/")))
      (setq file-name-without-ext (s-chop-suffix (if (not (s-blank-str? file-ext))
                                                     (s-concat "." file-ext)
                                                   file-ext)
                                                 file-name)))
    ;; pattern -> replacement
    (dolist (pattern->replacement `(("%a" . ,abs-path)
                                    ("%f" . ,file-name)
                                    ("%n" . ,file-name-without-ext)
                                    ("%e" . ,file-ext)
                                    ("%d" . ,dir)
                                    ("%p" . ,project-root-dir)
                                    ("%b" . ,project-build-dir)))
      (let ((case-fold-search nil)
            (pattern (car pattern->replacement))
            (replacement (cdr pattern->replacement)))
        (setq s (replace-regexp-in-string pattern replacement s t t))))
    ;;
    s))




;;;###autoload
(defun moonshot-run-runner ()
  "Run runner."
  (interactive)
  (let ((cmd (completing-read "Command: "
                              (moonshot-%make-simple-completing-read-collection
                               (moonshot-all-runners)))))
    (moonshot-run-command-with cmd #'moonshot-expand-path-vars #'compile)))




(provide 'moonshot)
;;; moonshot.el ends here
