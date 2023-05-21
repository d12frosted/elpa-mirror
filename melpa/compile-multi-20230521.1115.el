;;; compile-multi.el --- A multi target interface to compile -*- lexical-binding: t; -*-

;; Copyright (C) 2022  mohsin kaleem

;; Author: mohsin kaleem <mohkale@kisara.moe>
;; Keywords: tools, compile, build
;; Package-Version: 20230521.1115
;; Package-Commit: fafadb6722299797a1de3de93cf7439d17b4d13b
;; Package-Requires: ((emacs "28.0"))
;; Version: 0.3
;; Homepage: https://github.com/mohkale/compile-multi

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

;; Multi target interface to `compile'.
;;
;; This package exposes facilities for generating a collection of compilation
;; commands for the current buffer or project and interactively select one to
;; run. This can be plugged into various build frameworks such as Make or CMake
;; to automatically determine the list of available targets and let you
;; interactively select one to run.

;;; Code:

(require 'seq)

(defgroup compile-multi nil
  "A multi target interface to compile."
  :group 'compilation)

(defcustom compile-multi-default-directory #'ignore
  "Assign `default-directory' of a compilation in `compile-multi'."
  :type 'function)

(defcustom compile-multi-forms
  '((file-name . (buffer-file-name))
    (file-dir . (file-name-directory (buffer-file-name)))
    (file-base . (file-name-nondirectory (buffer-file-name)))
    (file-base-no-ext . (file-name-sans-extension (file-name-nondirectory (buffer-file-name))))
    (file-ext . (file-name-extension (file-name-nondirectory (buffer-file-name)))))
  "Alist of special let-forms that'll be substituted in `compile-multi-config'."
  :type '(alist :key-type symbol :value-type (sexp :tag "Expression")))

(defcustom compile-multi-config nil
  "Alist of triggers and actions for those triggers."
  :type '(alist :key-type
                (choice (symbol :tag "Major-mode")
                        (regexp :tag "File/buffer regexp")
                        (sexp :tag "Expression"))
                :value-type
                (repeat
                 (choice (string :tag "Shell command")
                         (function :tag "Shell command generator")
                         (repeat (choice string
                                         (sexp :tag "Expression")))
                         (plist :value-type (sexp :tag "Any of the above value types"))
                         ))))

(defvar compile-multi-history nil)
(defcustom compile-multi-annotate-cmds t
  "Affixate `compile-multi' to show the command being compiled."
  :type 'boolean)

(defcustom compile-multi-annotate-string-cmds t
  "Auto annotate string based commands in `compile-multi-config'.
When true if a command in `compile-multi-config' is a string or produces a
string then generate an annotation for it automatically. This option only
has significance when `compile-multi-annotate-cmds' is true."
  :type 'boolean)

(defcustom compile-multi-annotate-limit 48
  "Truncate any annotations longer than this limit.
Set to nil to disable truncation."
  :type '(optional integer))

(defun compile-multi--tasks ()
  "Select the tasks from `compile-multi-config' whose triggers are fired."
  (apply #'append
         (mapcar #'cdr
                 (seq-filter
                  (lambda (it)
                    (let ((trigger (car it)))
                      (cond
                       ((eq trigger t) t)
                       ((symbolp trigger)
                        (derived-mode-p trigger))
                       ((listp trigger)
                        (eval trigger))
                       ((stringp trigger)
                        (string-match-p trigger (buffer-name)))
                       ((functionp trigger)
                        (funcall trigger))
                       (t (error "Unknown trigger type: %s" trigger)))))
                  compile-multi-config))))

(defun compile-multi--fill-tasks (tasks)
  "Convert TASKS values into shell commands.
Returns an alist with key-type task-name and value-type shell-command."
  (let (res)
    (dolist (task tasks)
      (cond
       ;; Generate one-or more tasks to replace this task.
       ((functionp task)
        (setq res (append (nreverse
                           (compile-multi--fill-tasks (funcall task)))
                          res)))
       ;; A full command to be called as a standalone task.
       ((stringp (cdr task))
        (push `(,(car task)
                :command ,(cdr task)
                ,@(when compile-multi-annotate-string-cmds
                    (list :annotation (cdr task))))
              res))
       ;; Defer to a lisp-command to compile, not a shell command.
       ;; KLUDGE: I'm not sure about this, it might be a little too hacky.
       ((functionp (cdr task))
        (push `(,(car task)
                :command ,(cdr task)
                :annotation ,(if (eq (car-safe (cdr task)) 'lambda)
                                 "lambda"
                               (format "%s" (cdr task))))
              res))
       ;; Command is a preformatted plist, nothing to be done.
       ((and (listp (cdr task))
             (keywordp (cadr task)))
        ;; (cl-assert (plist-get (cdr task) :command) nil
        ;;            "Task %S has a missing command value" task)
        (when-let ((annotation (plist-get (cdr task) :annotation)))
          (plist-put (cdr task) :annotation
                     (when compile-multi-annotate-cmds
                       annotation)))
        (push `(,(car task) ,@(cdr task)) res))
       ;; It's a list that we need to format into a shell-command to run.
       ((listp (cdr task))
        (let ((cmd
               (mapconcat (lambda (it)
                            (or
                             (and (symbolp it)
                                  (let* ((val (or (alist-get it compile-multi-forms)
                                                  it))
                                         (evaluated-value (eval val)))
                                    (unless (stringp evaluated-value)
                                      (error "Failed to stringify task argument %s" val))
                                    evaluated-value))
                             (let ((evaluated-value (eval it)))
                               (unless (stringp evaluated-value)
                                 (error "Failed to stringify task argument %s" it))
                               evaluated-value)))
                          (cdr task) " ")))
          (push `(,(car task)
                  :command ,cmd
                  ,@(when compile-multi-annotate-string-cmds
                      (list :annotation cmd)))
                res)))
       (t (error "Unknown task type: %s" task))))
    (nreverse res)))

(defun compile-multi--annotation-function (tasks)
  "Annotation function for `compile-multi' using TASKS."
  (lambda (it)
    (when compile-multi-annotate-cmds
      (when-let ((cmd (plist-get (cdr (assoc it tasks)) :annotation)))
        (when (and compile-multi-annotate-limit
                   (>= (length cmd) compile-multi-annotate-limit))
          (setq cmd
                (concat
                 (string-remove-suffix
                  " "
                  (substring cmd 0 compile-multi-annotate-limit))
                 "…")))
        (concat " "
                (propertize " " 'display `(space :align-to (- right ,(+ 1 (length cmd)))))
                (propertize cmd 'face 'completions-annotations))))))

;;;###autoload
(defun compile-multi (&optional query)
  "Multi-target interface to compile.
With optional argument QUERY allow user to modify compilation command before
running."
  (interactive "P")
  (let* ((default-directory (or (and compile-multi-default-directory
                                     (funcall compile-multi-default-directory))
                                default-directory))
         (tasks (compile-multi--tasks))
         (tasks (compile-multi--fill-tasks tasks))
         (compile-cmd (if tasks
                          (plist-get
                           (cdr
                            (assoc (completing-read
                                    "Compile: "
                                    (lambda (string predicate action)
                                      (if (eq action 'metadata)
                                          `(metadata
                                            (annotation-function . ,(compile-multi--annotation-function tasks))
                                            (category . compile))
                                        (complete-with-action action tasks string predicate)))
                                    nil t nil 'compile-multi-history)
                                   tasks))
                           :command)
                        (read-shell-command "Compile command: "))))
    (cond
     ((stringp compile-cmd)
      (when query
        (setq compile-cmd
              (read-shell-command "Compile command: " compile-cmd)))
      (compile compile-cmd))
     ((functionp compile-cmd)
      (if query
          (eval-expression
           (read--expression "Eval: " (format "(%s)" compile-command)))
        (funcall compile-cmd)))
     (t (error "Don't know how to run the command %s" compile-cmd)))))

(provide 'compile-multi)
;;; compile-multi.el ends here
