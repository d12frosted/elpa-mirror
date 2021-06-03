;;; find-dupes-dired.el --- Find dupes and handle in dired  -*- lexical-binding: t; -*-

;; Copyright (C) 2021  Shuguang Sun <shuguang79@qq.com>

;; Author: Shuguang Sun <shuguang79@qq.com>
;; Created: 2021/01/14
;; Version: 1.0
;; Package-Version: 20210426.835
;; Package-Commit: 904225a3f89bbd3b44ea097a282ec6ca7945f7f1
;; URL: https://github.com/ShuguangSun/find-dupes-dired
;; Package-Requires: ((emacs "26.1"))
;; Keywords: tools

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

;; `(require 'find-dupes-dired)` and Run `find-dupes-dired`.
;; With prefix argument, find dupes in multiple directories.

;; If needed, set `find-dupes-dired-verbose' to t for debug message.

;; It needs "jdupes" in Windows and "fdupes" in other system, or others by setting
;; `find-dupes-dired-program` and `find-dupes-dired-ls-option`.

;; Thanks [fd-dired](https://github.com/yqrashawn/fd-dired/blob/master/fd-dired.el)
;; and [rg](https://github.com/dajva/rg.el). I got some references from them.


;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'find-dired)
(require 'subr-x)

(defgroup find-dupes-dired nil
  "Run a `find-dupes-dired' command and Dired the output."
  :group 'dired
  :prefix "find-dupes-dired")

(defcustom find-dupes-dired-program
  (cond
   ((eq system-type 'windows-nt) (or (executable-find "jdupes")
                                     (purecopy "jdupes")))
   (t (or (executable-find "fdupes") (purecopy "fdupes"))))
  "The default `find-dupes-dired' program."
  :type 'string
  :group 'find-dupes-dired)

(defcustom find-dupes-dired-ls-option
  (cond
   ((eq system-type 'windows-nt) '("-0 | xargs -0 ls -lUd 2>stderr" . "-lUd"))
   ((eq system-type 'darwin) '("-q | xargs -d \"\\n\" ls -lsU 2>/dev/null" . "-dilsbU"))
   (t '("-q | xargs -d \"\\n\" ls -dilsbU 2>/dev/null" . "-dilsbU")))
  "A pair of options to produce and parse an `ls -l'-type list from `find-dupes-dired-program'.
This is a cons of two strings (FIND-OPTION . LS-SWITCHES).
FIND-OPTION is the option (or options) passed to `find-dupes-dired-program'
to produce a file listing in the desired format.
LS-SWITCHES is a set of `ls' switches that tell
dired how to parse the output of `find-dupes-dired-program'.

For more information: `find-ls-option'."
  :type '(cons :tag "`find-dupes-dired' arguments pair"
               (string :tag "`find-dupes-dired-program' Option")
               (string :tag "Ls Switches"))
  :group 'find-dupes-dired)

(defcustom find-dupes-dired-toggle-command-line-flags '("-r")
  "List of command line default flags."
  :type '(repeat string)
  :group 'find-dupes-dired)

(defcustom find-dupes-dired-size ""
  "Size."
  :type 'string
  :group 'find-dupes-dired)

(defvar find-dupes-dired-args nil
  "Last arguments given to `find-dupes-dired-program' by \\[find-dupes-dired].")

(defvar find-dupes-dired-verbose nil
  "Print some message for debug.")

;; History of find-dupes-dired-args values entered in the minibuffer.
(defvar find-dupes-dired-args-history nil)

;;; * open subdirectory
(defun find-dupes-dired-goto-subdir (dir)
  "Go to end of header line of DIR in this dired buffer.
Return value of point on success, otherwise return nil.
The next char is \\n."
  (interactive
   (prog1               ; let push-mark display its message
       (let ((marked-files-directories
              (delete-dups (mapcar #'file-name-directory
                                   (dired-get-marked-files)))))
         (list (expand-file-name
                (completing-read "Goto in situ directory: " ; prompt
                                 marked-files-directories ; table
                                 nil    ; predicate
                                 t  ; require-match
                                 (car marked-files-directories)))))))
  ;; (setq dir (file-name-as-directory dir))
  (find-file (file-name-as-directory dir)))


;;; * find-dupes functions
(defvar find-dupes-dired-ls-subdir-switches find-ls-subdir-switches)

(defun find-dupes-dired-filter (proc string)
  "Filter for \\[find-dupes-dired] processes.
This is analogous to `find-dired-filter'."
  (let ((buf (process-buffer proc))
        (inhibit-read-only t))
    (if (buffer-name buf)
        (with-current-buffer buf
          (save-excursion
            (save-restriction
              (widen)
              (let ((buffer-read-only nil)
                    (beg (point-max))
                    (l-opt (and (consp find-dupes-dired-ls-option)
                                (string-match "l" (cdr find-dupes-dired-ls-option))))
                    (ls-regexp (concat "^ +[^ \t\r\n]+\\( +[^ \t\r\n]+\\) +"
                                       "[^ \t\r\n]+ +[^ \t\r\n]+\\( +[^[:space:]]+\\)")))
                (goto-char beg)
                (insert string)
                (goto-char (point-min))
                (or (looking-at "^")
                    (forward-line 1))
                (while (looking-at "^")
                  (insert "  ")
                  (forward-line 1))
                ;; Convert ` ./FILE' to ` FILE'
                ;; This would lose if the current chunk of output
                ;; starts or ends within the ` ./', so back up a bit:
                (goto-char (- beg 3))   ; no error if < 0
                (while (search-forward " ./" nil t)
                  (delete-region (point) (- (point) 2)))
                ;; Pad the number of links and file size.  This is a
                ;; quick and dirty way of getting the columns to line up
                ;; most of the time, but it's not foolproof.
                (when l-opt
                  (goto-char beg)
                  (goto-char (line-beginning-position))
                  (while (re-search-forward ls-regexp nil t)
                    (replace-match (format "%4s" (match-string 1)) nil nil nil 1)
                    (replace-match (format "%9s" (match-string 2)) nil nil nil 2)
                    (forward-line 1)))
                ;; all the complete lines in the unprocessed
                ;; output and process it to add text properties.
                (goto-char (point-max))
                (if (search-backward "\n" (process-mark proc) t)
                    (progn
                      (dired-insert-set-properties (process-mark proc)
                                                   (1+ (point)))
                      (move-marker (process-mark proc) (1+ (point)))))))))
      ;; The buffer has been killed.
      (delete-process proc))))

(defun find-dupes-dired-sentinel (proc state)
  "Sentinel for \\[find-dupes-dired] processes.
This is analogous to `find-dired-sentinel'."
  (let ((buf (process-buffer proc))
        (inhibit-read-only t))
    (if (buffer-name buf)
        (with-current-buffer buf
          (let ((buffer-read-only nil))
            (save-excursion
              (goto-char (point-max))
              (let ((point (point)))
                (insert "\n  " find-dupes-dired-program " " state)
                (forward-char -1)       ;Back up before \n at end of STATE.
                (insert " at " (substring (current-time-string) 0 19))
                (dired-insert-set-properties point (point)))
              (setq mode-line-process
                    (concat ":" (symbol-name (process-status proc))))
              ;; Since the buffer and mode line will show that the
              ;; process is dead, we can delete it now.  Otherwise it
              ;; will stay around until M-x list-processes.
              (delete-process proc)
              (force-mode-line-update)
              (find-dupes-dired-maybe-show-header)))
          (message "find-dupes-dired %s finished." (current-buffer))))))


(cl-defstruct (find-dupes-dired-search-list
               (:constructor find-dupes-dired-search-list-create)
               (:constructor find-dupes-dired-search-list-new (dir args))
               (:copier find-dupes-dired-search-list-copy))
  dir                    ; directory list
  args                   ; default argument
  size                   ; size
  toggle-flags           ; toggle command line flags
  )


(defvar-local find-dupes-dired-cur-search nil
  "Stores parameters of last search.
Becomes buffer local in `find-dupes-dired' buffers.")
(put 'find-dupes-dired-cur-search 'permanent-local t)

(defun find-dupes-dired-build-command ()
  "Create the command line.
RECURSE determines if search will be recurse and FLAGS are command line flags."
  (let* ((size (find-dupes-dired-search-list-size find-dupes-dired-cur-search))
         (toggle-flags (find-dupes-dired-search-list-toggle-flags
                        find-dupes-dired-cur-search))
         (command-line (append toggle-flags (unless (string-blank-p size)
                                              (list "--size" size)))))
    (mapconcat #'identity (delete-dups command-line) " ")))


(defface find-dupes-dired-toggle-on-face
  '((t :inherit font-lock-constant-face))
  "face for toggle 'on' text in header."
  :group 'find-dupes-dired-face)

(defface find-dupes-dired-toggle-off-face
  '((t :inherit font-lock-comment-face))
  "face for toggle 'off' text in header."
  :group 'find-dupes-dired-face)

(defun find-dupes-dired-header-render-label (labelform)
  "Return a fontified header label.
LABELFORM is either a string to render or a form where the `car' is a
conditional and the two following items are then and else specs.
Specs are lists where the the `car' is the labels string and the
`cadr' is font to use for that string."
  (list '(:propertize "[" font-lock-face (header-line bold))
        (cond
         ((stringp labelform)
          `(:propertize ,labelform font-lock-face (header-line bold)))
         ((listp labelform)
          (let* ((condition (nth 0 labelform))
                 (then (nth 1 labelform))
                 (else (nth 2 labelform)))
            `(:eval (if ,condition
                        (propertize ,(nth 0 then) 'font-lock-face '(,(nth 1 then) header-line bold))
                      (propertize ,(nth 0 else) 'font-lock-face '(,(nth 1 else) header-line bold))))))
         (t (error "Not a string or list")))
        '(:propertize "]" font-lock-face (header-line bold))
        '(": ")))

(defun find-dupes-dired-header-render-toggle (on)
  "Return a fontified toggle symbol.
If ON is non nil, render \"on\" string, otherwise render \"off\"
string."
  `(:eval (let* ((on ,on)
                 (value (if on "on " "off"))
                 (face (if on 'find-dupes-dired-toggle-on-face
                         'find-dupes-dired-toggle-off-face)))
            (propertize value 'font-lock-face `(bold ,face)))))


;; Use full-command here to avoid dependency on find-dupes-dired-search
;; struct. Should be properly fixed.
(defun find-dupes-dired-create-header-line (search)
  "Create the header line for SEARCH.
If FULL-COMMAND specifies if the full command line search was done."
  (let ((itemspace "  "))
    (setq header-line-format
          (list
           (find-dupes-dired-header-render-label "recurse")
           (find-dupes-dired-header-render-toggle
            `(member "-r" (find-dupes-dired-search-list-toggle-flags ,search)))
           itemspace
           (find-dupes-dired-header-render-label "size")
           `(:eval (format "%s" (find-dupes-dired-search-list-size ,search)))))))


(defcustom find-dupes-dired-show-header t
  "Show header in results buffer if non nil."
  :type 'boolean
  :group 'find-dupes-dired)

(defun find-dupes-dired-maybe-show-header ()
  "Recreate header if enabled."
  (when find-dupes-dired-show-header
    (find-dupes-dired-create-header-line 'find-dupes-dired-cur-search)))


(defun find-dupes-dired--run (dir args &optional search)
  "Run `find-dupes' and go into Dired mode on a buffer of the output.
With prefix argument, find dupes in multiple directories.

The command run (after changing into `car' DIR) is essentially

    find-dupes ARGS DIR -ls

except that the car of the variable `find-dupes-dired-ls-option' specifies
what to use in place of \"-ls\" as the final argument.
Optional argument SEARCH an existing `find-dupes-dired-search-list'."
  (let ((dired-buffers dired-buffers)
        dir-string)

    (unless (listp dir) (setq dir (list dir)))
    (setq dir (mapcar (lambda (x)
                        ;; Check that it's really a directory.
                        (or (file-directory-p x)
                            (error "`find-dupes-dired' needs a directory: %s" x))
                        (file-name-as-directory (expand-file-name x)))
                      dir))

    (setq dir-string (mapconcat (lambda (x) (shell-quote-argument x)) dir " "))

    (if find-dupes-dired-verbose
        (progn
          (message "dir: %s" dir-string)
          (message "args: %s" (if args args " "))))

    (switch-to-buffer (get-buffer-create "*Dired: Dupes*"))

    ;; See if there's still a `find-dupes' running, and offer to kill
    ;; it first, if it is.
    (let ((find-dupes (get-buffer-process (current-buffer))))
      (when find-dupes
        (if (or (not (eq (process-status find-dupes) 'run))
                (yes-or-no-p
                 (format-message "A `find-dupes' process is running; kill it? ")))
            (condition-case nil
                (progn
                  (interrupt-process find-dupes)
                  (sit-for 1)
                  (delete-process find-dupes))
              (error nil))
          (error "Cannot have two processes in `%s' at once" (buffer-name)))))

    (widen)
    (setq buffer-read-only nil)
    (erase-buffer)

    (if search (setq find-dupes-dired-cur-search search))
    (unless find-dupes-dired-cur-search
      (setq find-dupes-dired-cur-search
            (find-dupes-dired-search-list-create
             :dir dir
             :args args
             :size find-dupes-dired-size
             :toggle-flags find-dupes-dired-toggle-command-line-flags)))
    (setq default-directory (car dir)
          find-dupes-dired-args args          ; save for next interactive call
          args (concat (shell-quote-argument find-dupes-dired-program)
                       " "
                       args
                       " "
                       (find-dupes-dired-build-command)
                       " "
                       dir-string
                       " "
                       (if (string-match "\\`\\(.*\\) {} \\(\\\\;\\|+\\)\\'"
                                         (car find-dupes-dired-ls-option))
                           (format "%s %s %s"
                                   (match-string 1 (car find-dupes-dired-ls-option))
                                   (shell-quote-argument "{}")
                                   find-exec-terminator)
                         (car find-dupes-dired-ls-option))))
    (if find-dupes-dired-verbose (message "command line: %s" args))

    ;; Start the find-dupes process.
    (shell-command (concat args "&") (current-buffer))
    ;; The next statement will bomb in classic dired (no optional arg allowed)
    (dired-mode (car dir) (cdr find-dupes-dired-ls-option))
    (let ((map (make-sparse-keymap)))
      (set-keymap-parent map (current-local-map))
      (define-key map "\C-c\C-k" #'kill-find)
      (define-key map "\C-c\C-j" #'find-dupes-dired-goto-subdir)
      (define-key map "g" (lambda () (interactive) (find-dupes-dired--rerun)))
      (define-key map "r" #'find-dupes-dired-rerun-toggle-recurse)
      (define-key map "s" #'find-dupes-dired-rerun-change-size)
      (use-local-map map))
    (make-local-variable 'dired-sort-inhibit)
    (setq dired-sort-inhibit t)
    (set (make-local-variable 'revert-buffer-function)
         `(lambda (ignore-auto noconfirm)
            (find-dupes-dired--run ,dir ,find-dupes-dired-args)))
    ;; Set subdir-alist so that Tree Dired will work:
    (if (fboundp 'dired-simple-subdir-alist)
        ;; will work even with nested dired format (dired-nstd.el,v 1.15
        ;; and later)
        (dired-simple-subdir-alist)
      ;; else we have an ancient tree dired (or classic dired, where
      ;; this does no harm)
      (set (make-local-variable 'dired-subdir-alist)
           (list (cons default-directory (point-min-marker)))))
    (set (make-local-variable 'dired-subdir-switches)
         find-dupes-dired-ls-subdir-switches)
    (setq buffer-read-only nil)
    ;; Subdir headlerline must come first because the first marker in
    ;; subdir-alist points there.
    (insert "  " dir-string ":\n")
    ;; Make second line a ``find-dupes'' line in analogy to the ``total'' or
    ;; ``wildcard'' line.
    (let ((point (point)))
      (insert "  " args "\n")
      (dired-insert-set-properties point (point)))
    (setq buffer-read-only t)
    (let ((proc (get-buffer-process (current-buffer))))
      (set-process-filter proc (function find-dupes-dired-filter))
      (set-process-sentinel proc (function find-dupes-dired-sentinel))
      ;; Initialize the process marker; it is used by the filter.
      (move-marker (process-mark proc) (point) (current-buffer)))
    (setq mode-line-process '(":%s"))))

;;;###autoload
(defun find-dupes-dired ()
  "Run `find-dupes' and go into Dired mode on a buffer of the output.
The command run (after changing into DIR) is essentially

    find-dupes . \\( ARGS \\) -ls

except that the car of the variable `find-dupes-dired-ls-option' specifies
what to use in place of \"-ls\" as the final argument."
  (interactive)
  (if (not (executable-find find-dupes-dired-program))
      (error (format "%s is not in the path!" find-dupes-dired-program)))

  (let ((prefix current-prefix-arg)
        (ndir 1)
        dir
        args)
    (if prefix (progn (setq ndir (read-number "How many root dirs: " 1))))
    (setq dir (cl-loop for i from 1 to ndir by 1
                       collect (read-directory-name "Run find-dupes in directory: " nil "" t)))

    (setq args (read-string "Run find-dupes (with args, Enter for empty): "
                            find-dupes-dired-args
                            '(find-dupes-dired-args-history . 1)))
    (if (and find-dupes-dired-verbose
             (executable-find find-dupes-dired-program))
        (message "find-dupes-dired-program: %s" find-dupes-dired-program))

    (find-dupes-dired--run dir args)))

(defun find-dupes-dired--rerun ()
  "Rerun `find-dupes-dired' with updated args.
If NO-HISTORY is non nil skip adding the search to the search history."
  (let ((dir (find-dupes-dired-search-list-dir find-dupes-dired-cur-search))
        (args (find-dupes-dired-search-list-args find-dupes-dired-cur-search)))
    (find-dupes-dired--run dir args)))

(defun find-dupes-dired-list-toggle (elem list)
  "Remove ELEM from LIST if present or add it if not present.
Returns the new list."
  (if (member elem list)
      (delete elem list)
    (push elem list)))


(defun find-dupes-dired-rerun-toggle-flag (flag)
  "Toggle FLAG in `find-dupes-dired-cur-search`."
  (setf (find-dupes-dired-search-list-toggle-flags find-dupes-dired-cur-search)
        (find-dupes-dired-list-toggle flag (find-dupes-dired-search-list-toggle-flags
                                            find-dupes-dired-cur-search)))
  (find-dupes-dired--rerun))

(defun find-dupes-dired-rerun-toggle-recurse ()
  "Rerun last search with toggled recurse setting."
  (interactive)
  (find-dupes-dired-rerun-toggle-flag "-r"))

(defun find-dupes-dired-rerun-change-size ()
  "Rerun last search with toggled '--size' flag."
  (interactive)
  (let ((size (find-dupes-dired-search-list-size find-dupes-dired-cur-search))
        (read-from-minibuffer-orig (symbol-function 'read-from-minibuffer)))
    ;; Override read-from-minibuffer in order to insert the original
    ;; pattern in the input area.
    (cl-letf (((symbol-function #'read-from-minibuffer)
               (lambda (prompt &optional _ &rest args)
                 (apply read-from-minibuffer-orig prompt size args))))
      (setf (find-dupes-dired-search-list-size find-dupes-dired-cur-search)
            (read-string "Size: " size)))
    (find-dupes-dired--rerun)))



(provide 'find-dupes-dired)
;;; find-dupes-dired.el ends here
