;;; python-view-data.el --- View data in python      -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Shuguang Sun

;; Author: Shuguang Sun <shuguang79@qq.com>
;; Created: 2023/05/03
;; Version: 0.1
;; Package-Version: 20230508.543
;; Package-Commit: 1dd5f99679db9767530cfc20642a40a48bd479be
;; URL: https://github.com/ShuguangSun/python-view-data
;; Package-Requires: ((emacs "28.1") (python "0.2") (csv-mode "1.12"))
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

;; View data in python

;; Call `python-view-data-print`, select a pandas dataframe, and then a buffer
;; will pop up with data listed/printed. Further verbs can be done, like filter
;; (query), select/unselect, mutate, group/ungroup, count, unique, describe, and
;; etc. It can be reset (`python-view-data-reset`) any time.

;;; Code:

(eval-when-compile (require 'cl-lib))
(eval-when-compile (require 'cl-generic))

(require 'python)
(require 'csv-mode)

(defgroup python-view-data ()
  "Python view data."
  :group 'python
  :prefix "python-view-data-")


(defcustom python-view-data-buffer-name-format "*Python Data View: %1$s (%2$s)*"
  "Buffer name for Python data view, with two parameter: variable name, proc-name."
  :type 'string
  :group 'python-view-data)

(defcustom python-view-data-source-buffer-name-format "*Python Data View Edit: %s*"
  "Buffer for R data."
  :type 'string
  :group 'python-view-data)

(defcustom python-view-data-verbose t
  "Write to dribble buffer."
  :type 'booleanp
  :group 'python-view-data)


(defcustom python-view-data-write-to-dribble t
  "Write to dribble buffer."
  :type 'booleanp
  :group 'python-view-data)


(defvar python-view-data-backend-list
  (list 'pandas.to_csv)
  "List of backends.")

(defcustom python-view-data-current-backend 'pandas.to_csv
  "The python-view-data backend in using."
  :type `(choice ,@(mapcar (lambda (x)
                             `(const :tag ,(symbol-name x) ,x))
                           python-view-data-backend-list)
                 (symbol :tag "Other"))
  :group 'python-view-data)


(defvar python-view-data-print-backend-list
  (list 'pandas.to_csv 'markdown)
  "List of backends.")


(defcustom python-view-data-current-update-print-backend 'pandas.to_csv
  "The python-view-data backend in using."
  :type `(choice ,@(mapcar (lambda (x)
                             `(const :tag ,(symbol-name x) ,x))
                           python-view-data-print-backend-list)
                 (symbol :tag "Other"))
  :group 'python-view-data)

(defcustom python-view-data-current-summarize-print-backend 'pandas.to_csv
  "The python-view-data backend in using."
  :type `(choice ,@(mapcar (lambda (x)
                             `(const :tag ,(symbol-name x) ,x))
                           python-view-data-print-backend-list)
                 (symbol :tag "Other"))
  :group 'python-view-data)

(defcustom python-view-data-rows-per-page 200
  "Rows per page."
  :type 'integer
  :group 'python-view-data)



(defvar python-view-data-save-backend-list
  (list 'pandas.to_csv 'pandas.to_excel)
  "List of backends for write data to csv.")

(defcustom python-view-data-current-save-backend 'pandas.to_csv
  "The backend to save data."
  :type `(choice ,@(mapcar (lambda (x)
                             `(const :tag ,(symbol-name x) ,x))
                           python-view-data-save-backend-list)
                 (symbol :tag "Other"))
  :group 'python-view-data)

(defvar python-view-data-dribble-buffer "*Python View Data*"
  "Buffer or name of buffer for printing debugging information.")


(defvar python-view-data-verb-update-list
  (list "select" "unselect" "sort" "loc")
  "List of verbs which can change the data.")

(defvar python-view-data-verb-update-indirect-list
  (list "filter" "mutate" "query")
  "List of verbs which can change the data.")

(defvar python-view-data-verb-summarise-list
  (list "count" "unique" "describe" "describe-all")
  "List of verbs which do summarise.")

(defvar python-view-data-verb-summarise-indirect-list
  (list "count" "unique")
  "List of verbs which do summarise.")


(defvar-local python-view-data-object nil
  "Object name viewing.")

(defvar-local python-view-data-object-list nil
  ;; This is a list of the currently known object names.  It is
  ;; current only for one command entry; it exists under the
  ;; assumption that the list of objects doesn't change while entering
  ;; a command.
  "Cache of object names.")

(defvar-local python-view-data-local-process-name nil
  "The name of the Python process associated with the current buffer.")


(defvar-local python-view-data-temp-object nil
  "Temporary object.")

(defvar-local python-view-data-history nil
  "The history of operations.")

(defvar-local python-view-data--local-mode-line-process-indicator '("")
  "List of local process indicators.")

(defvar-local python-view-data--group nil
  "Group variables.")

(defvar-local python-view-data--parent-buffer nil
  "The parent buffer related to the indirect buffer.")
(defvar-local python-view-data--reset-buffer-p nil
  "Is this indirect buffer is to reset the view buffer?")
(defvar-local python-view-data--action nil
  "The action related to the indirect buffer.")


(defvar python-view-data-temp-object-list '()
  "List of temporary variable for python-view-data.")

(defvar-local python-view-data-maxprint-p nil
  "Whether to print all data in one page.")


(defvar-local python-view-data-page-number 0
  "Current page number.")

(defvar-local python-view-data-total-page 1
  "Total page number.")



(defvar python-view-data-get-object-command
  "[var for var in dir() if isinstance(eval(var), pandas.core.frame.DataFrame)]"
  "Python script to get objects.")

(defvar python-view-data-split-dict-string "@$,$@"
  "String to split the Python dictionary.")

(defvar python-view-data-df-command
  "%s.to_csv()"
  "Python script to print dataframe.")

(defvar python-view-data-df-command
  "%s.to_markdown()"
  "Python script to print dataframe.")


(defvar python-view-data-backend-setting
  '((pandas.to_csv . (:desc t)))
  "List of backends.")

(defun python-view-data-write-to-dribble-buffer (text)
  "Write TEXT to `python-view-data-dribble-buffer'."
  (when python-view-data-write-to-dribble
    (with-current-buffer (get-buffer-create python-view-data-dribble-buffer)
      (goto-char (point-max))
      (insert-before-markers text))))

(defun python-view-data-toggle-maxprint ()
  "Python view data do select."
  (interactive)
  (setq python-view-data-page-number 0)
  (setq python-view-data-maxprint-p (not python-view-data-maxprint-p)))



(defvar python-view-data-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "C-c C-p") #'python-view-data-print-ex)
    (define-key keymap (kbd "C-c C-t") #'python-view-data-toggle-maxprint)
    (define-key keymap (kbd "C-c C-s") #'python-view-data-select)
    (define-key keymap (kbd "C-c C-u") #'python-view-data-unselect)
    (define-key keymap (kbd "C-c C-f") #'python-view-data-filter)
    (define-key keymap (kbd "C-c C-o") #'python-view-data-sort)
    (define-key keymap (kbd "C-c C-l") #'python-view-data-count)
    (define-key keymap (kbd "C-c C-v") #'python-view-data-describe)
    (define-key keymap (kbd "C-c C-r") #'python-view-data-reset)
    (define-key keymap (kbd "C-c C-w") #'python-view-data-save)
    (define-key keymap (kbd "M-g p") #'python-view-data-goto-previous-page)
    (define-key keymap (kbd "M-g n") #'python-view-data-goto-next-page)
    (define-key keymap (kbd "M-g f") #'python-view-data-goto-first-page)
    (define-key keymap (kbd "M-g l") #'python-view-data-goto-last-page)
    keymap)
  "Keymap for function `python-view-data-mode'.")

;;; Indirect Buffers Minor Mode
(defvar python-view-data-edit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c'" #'python-view-data-do-commit)
    (define-key map "\C-c\C-k" #'python-view-data-commit-abort)
    map)
  "Keymap for `python-view-data-edit-mode', a minor mode.")




(define-minor-mode python-view-data-mode
  "Python view data."
  :global nil
  :group 'python-view-data
  :keymap python-view-data-mode-map
  :lighter " PY-V"
  (if python-view-data-mode
      (progn
        ;; (require 'ansi-color)
        ;; (ansi-color-apply-on-region (point-min) (point-max))
        (if python-view-data-verbose
            (python-view-data-write-to-dribble-buffer "Mode.\n"))

        (goto-char (point-min))
        (csv-align-mode +1)
        (csv-header-line)
        (setq buffer-read-only t)

        (setq mode-line-process
              '(" ["
                (:eval (format "%d/%d" python-view-data-page-number python-view-data-total-page))
                "]"))

        (add-hook 'kill-buffer-hook #'python-view-data-kill-buffer-hook nil t))))

(defvar python-view-data-edit-mode-hook nil
  "Hook for the `python-view-data-edit-mode' minor mode.")

(define-minor-mode python-view-data-edit-mode
  "Minor mode for special key bindings in a python-view-data-edit buffer.

Turning on this mode runs the normal hook `python-view-data-edit-mode-hook'."
  :lighter " Py-vd"
  (setq-local
   header-line-format
   (substitute-command-keys
    "Edit, then exit with `\\[python-view-data-do-commit] '' or abort with `\\[python-view-data-commit-abort]'")))




(defun python-view-data-get-object-list (&optional proc-name)
  "Return a list of current Python object names associated with process NAME.
Optional argument PROC-NAME process name."
  (let* (;;(buf (get-buffer-create (format python-view-data-buffer-name-format obj proc-name)))
         ;; (proc-name-buf (buffer-local-value 'python-view-data-local-process-name buf))
         (proc (get-process (or proc-name (python-shell-get-process-or-error))))
         command)
    (if python-view-data-verbose
        (python-view-data-write-to-dribble-buffer "Get Object list.\n"))

    (setq command (format "print(\"%s\".join(%s))\n"
                          python-view-data-split-dict-string
                          python-view-data-get-object-command))

    (when (and proc (not (process-get proc 'busy)))
      (python-shell-send-string "import pandas" proc)
      (sleep-for 0.1)
      (setq python-view-data-object-list
            (delete-dups (split-string
                          (python-shell-send-string-no-output command proc)
                          "@$,$@")))
      ;; (print python-view-data-object-list)
      ;; (prin1 python-view-data-object-list)
      )))

(defun python-view-data-get-object-cols (&optional proc-name)
  "Return a list of current Python object names associated with process NAME.
Optional argument PROC-NAME process name."
  (let* (;;(buf (get-buffer-create (format python-view-data-buffer-name-format obj proc-name)))
         ;; (proc-name-buf (buffer-local-value 'python-view-data-local-process-name buf))
         (proc (get-process (or proc-name (python-shell-get-process-or-error))))
         command)
    (if python-view-data-verbose
        (python-view-data-write-to-dribble-buffer "Get Object columns.\n"))

    (setq command (format "print(\"%s\".join(list(%s.columns)))\n"
                          python-view-data-split-dict-string
                          python-view-data-temp-object))

    (when (and proc (not (process-get proc 'busy)))
      (delete-dups (split-string
                    (python-shell-send-string-no-output command proc)
                    "@$,$@")))))


(defun python-view-data-read-object-name (p-string)
  "Read an object name from the minibuffer with completion, and return it.
P-STRING is the prompt string."
  (let* (;; (default (ess-read-object-name-dump))
         (object-list (python-view-data-get-object-list
                       (or python-view-data-local-process-name
                           (python-shell-get-process-or-error))))
         (spec (completing-read p-string object-list nil nil nil nil ;;default
                                )))

    (if python-view-data-verbose
        (python-view-data-write-to-dribble-buffer (format "object name: %s\n" spec)))

    (cond
     ((string= spec "") )
     (t spec))))


;;; Utils

;;; Backend Access API

(cl-defgeneric python-view-data--do-print (backend str)
  "Benchmark function to do print.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-update-print-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data--do-update (backend str)
  "Do Update.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data--do-summarise (backend str)
  "Do summarising.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data--create-indirect-buffer (backend str)
  "Create indirect-buffer for editing.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data--do-reset (backend str)
  "Reset print buffer.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data-do-save (backend str)
  "Save.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data-do-complete-data (backend str)
  "Completing input.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-complete-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data-get-total-page (backend str)
  "Total number of pages.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data--header-line (backend str)
  "Head-line.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data--initialize-backend (_backend)
  "Initialization."
  nil)

(cl-defgeneric python-view-data-do-kill-buffer-hook (backend str)
  "Functions to run after `kill-buffer' on '*R Data View' buffer.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data-do-group (backend str)
  "Groupby.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")

(cl-defgeneric python-view-data-do-ungroup (backend str)
  "Ungroup.

Argument BACKEND Backend to dispatch, i.e.,
the `python-view-data-current-backend'.
Argument STR Python script to run.")


;;; * print-backend: print
(defvar python-view-data--print-format
  "%s.to_csv()"
  "Format string for print.")

(cl-defmethod python-view-data--do-print ((_backend (eql pandas.to_csv)))
  "Do print using print."
  python-view-data--print-format)


;;; * backend: pandas.to_csv

;;; ** Initialization
(cl-defmethod python-view-data--initialize-backend ((_backend (eql pandas.to_csv)) proc-name proc)
  "Initialization.

Initializing the history of operations, make temp object.

Optional argument PROC-NAME The name of associated Python process,
usually `python-view-data-local-process-name'.
Optional argument PROC The associated Python process."
  (when python-view-data-verbose
    (python-view-data-write-to-dribble-buffer
     (format "Initializing: %s\n" python-view-data-object))
    (python-view-data-write-to-dribble-buffer
     (format "Current Buffer: %s\n" (buffer-name)))
    (python-view-data-write-to-dribble-buffer
     (format "Temp object: %s\n" python-view-data-temp-object)))

  ;; Initializing the temporary object, for stepwise
  (unless python-view-data-temp-object
    (setq python-view-data-temp-object
          (format "%s" (make-temp-name python-view-data-object)))
    (if python-view-data-verbose
        (python-view-data-write-to-dribble-buffer
         (format "Temp object: %s\n" python-view-data-temp-object)))

    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (when python-view-data-verbose
        (python-view-data-write-to-dribble-buffer
         (format "Initializing Temp object: %s\n" python-view-data-temp-object)))
      ;; (python-shell-send-string
      (python-shell-send-string
       (format "import pandas\n\n%s=%s\n" python-view-data-temp-object python-view-data-object)
       proc)
      ;; (python-shell-send-string
      ;;  (format "%s.info()\n" python-view-data-temp-object)
      ;;  proc)
      )

    (unless python-view-data-history
      (setq python-view-data-history
            (concat python-view-data-temp-object "=" python-view-data-object)))
    (cl-pushnew python-view-data-temp-object python-view-data-temp-object-list))
  (delete-dups python-view-data-temp-object-list))


(cl-defmethod python-view-data-get-total-page ((_backend (eql pandas.to_csv)) proc-name proc)
  "Get total number of pages of the current object (data.frame/tibble/data.table).

If `python-view-data-maxprint-p' is nil, it will show 100 rows/lines
per page for csv+print/kable.

Optional argument PROC-NAME The name of associated Python process,
usually `python-view-data-local-process-name'.
Optional argument PROC The associated Python process."
  (when (and proc-name proc
             (not (process-get proc 'busy)))
    ;; (python-shell-send-string-no-output "b.__len__()")
    ;; (python-shell-send-string-no-output "b.axes[0]")
    ;; (python-shell-send-string-no-output "b.shape[0]")
    ;; (python-shell-send-string-no-output "len(b)")
    (when python-view-data-verbose
      (python-view-data-write-to-dribble-buffer
       (format "Current Buffer: %s.\n" (buffer-name)))
      (python-view-data-write-to-dribble-buffer
       (format "Get page numbers of %s.\n"
               python-view-data-temp-object)))

    ;; (setq temp-obj python-view-data-temp-object)
    (setq python-view-data-total-page
          (python-shell-send-string-no-output
           (format "%s.__len__()\n" python-view-data-temp-object) proc))

    (if python-view-data-verbose
        (python-view-data-write-to-dribble-buffer
         (format "Get page numbers: %s.\n"
                 python-view-data-total-page)))

    (setq python-view-data-total-page
          (1+ (floor (/ (string-to-number python-view-data-total-page)
                        python-view-data-rows-per-page))))))




(cl-defmethod python-view-data-do-kill-buffer-hook ((_backend (eql pandas.to_csv)) proc-name proc)
  "Functions to run after `kill-buffer' on '*R Data View' buffer.

The default is to rm the temporary object.

Optional argument PROC-NAME The name of associated Python process,
usually `python-view-data-local-process-name'.
Optional argument PROC The associated Python process."
  (when (and proc-name proc
             (not (process-get proc 'busy)))
    (if python-view-data-verbose
        (python-view-data-write-to-dribble-buffer "Remove temp object.\n"))
    (python-shell-send-string (format "del %s\n" python-view-data-temp-object))
    (python-view-data-write-to-dribble-buffer
     (format "del %s\n" python-view-data-temp-object))))


;;; ** Utilities
(cl-defmethod python-view-data--do-update ((_backend (eql pandas.to_csv)) fun action)
  "Update the data frame by csv stepwisely.

Optional argument FUN What to do with the data, e.g.,
verb like select, filter, and etc..
Optional argument ACTION Parameter (Python script) for FUN, e.g.,
columns for select."
  (let (cmdhist cmd result)
    (setq cmdhist
          (pcase fun
            ('select
             ;; (format ".filter(items=[%s])"
             (format ".loc(:,[%s])"
                     (mapconcat (lambda (x) (format "'%s'" x))
                                (nreverse (delete-dups (nreverse action))) ",")))
            ((or 'filter 'query)
             (format ".query('%s')" action))
            ('mutate
             (format ".assign(%s)" action))
            ('sort
             (let ((x-list (mapcar (lambda (x) (split-string x ": "))
                                   (nreverse (delete-dups (nreverse action))))))
               (format ".sort_values(by=[%s],ascending=(%s))"
                       (concat (if python-view-data--group
                                   (concat
                                    (mapconcat (lambda (x) (format "'%s'" x))
                                               python-view-data--group ", ")
                                    ", ")
                                 "")
                               (mapconcat (lambda (x) (format "'%s'" (car x)))
                                          x-list ","))
                       (concat (if python-view-data--group
                                   (concat
                                    (mapconcat (lambda (_x) "True")
                                               python-view-data--group ", ")
                                    ", ")
                                 "")
                               (mapconcat (lambda (x)
                                            (if (string= "ascending" (cadr x))
                                                "True" "False"))
                                          x-list ",")))))
            ;; ('group
            ;;  (format ".groupby(by=[%s])"
            ;;          (mapconcat (lambda (x) (format "'%s'" x))
            ;;                     (nreverse (delete-dups (nreverse action))) ",")))
            ('unselect
             (format ".drop(columns=[%s])"
                     (mapconcat (lambda (x) (format "'%s'" x))
                                (nreverse (delete-dups (nreverse action))) ",")))
            (_
             (format ".%s" action))))

    (setq python-view-data-page-number 0)
    (setq cmd (concat
               python-view-data-temp-object " = " python-view-data-temp-object cmdhist "\n\n"
               ""
               (format (python-view-data--do-print python-view-data-current-update-print-backend)
                       (concat python-view-data-temp-object
                               (unless python-view-data-maxprint-p
                                 (format "[(%1$d*%2$d) : min((%1$d + 1)*%2$d, %s.__len__())]"
                                         python-view-data-page-number
                                         python-view-data-rows-per-page
                                         python-view-data-temp-object)))
                       python-view-data-temp-object)
               "\n"))

    (when python-view-data-verbose
      (python-view-data-write-to-dribble-buffer (format "Command: %s\n" cmd)))

    (setq result (cons cmdhist cmd))
    result))


(cl-defmethod python-view-data--do-summarise ((_backend (eql pandas.to_csv)) fun action)
  "Do summarising by csv stepwisely, without modify the data frame.

Optional argument FUN What to do with the data, e.g.,
verb like count, unique, and etc..
Optional argument ACTION Parameter (Python script) for FUN, e.g.,
columns for count."
  (let (cmdhist cmd result)
    (setq cmdhist
          (pcase fun
            ('count
             ;; (format ".filter(items=[%s]).value_counts()"
             (if python-view-data--group
                 (format ".loc[:,[%1$s,%2$s]].groupby([%1$s]).value_counts()"
                         (mapconcat (lambda (x) (format "'%s'" x))
                                    python-view-data--group ", ")
                         (mapconcat (lambda (x) (format "'%s'" x))
                                    (nreverse (delete-dups (nreverse action))) ","))
               (format ".loc[:,[%s]].value_counts()"
                       (mapconcat (lambda (x) (format "'%s'" x))
                                  (nreverse (delete-dups (nreverse action))) ","))))
            ('unique
             ;; (format ".filter(items=[%s]).drop_duplicates()"
             (if python-view-data--group
                 (format ".loc[:,[%1$s,%2$s]].groupby([%1$s]).drop_duplicates()"
                         (mapconcat (lambda (x) (format "'%s'" x))
                                    python-view-data--group ", ")
                         (mapconcat (lambda (x) (format "'%s'" x))
                                    (nreverse (delete-dups (nreverse action))) ","))
               (format ".loc[:,[%s]].drop_duplicates()"
                       (mapconcat (lambda (x) (format "'%s'" x))
                                  (nreverse (delete-dups (nreverse action))) ","))))
            ('describe
             ;; (format ".filter(items=[%s]).describe(include='all')"
             (if python-view-data--group
                 (format ".loc[:,[%1$s,%2$s]].groupby([%1$s]).describe(include='all')"
                         (mapconcat (lambda (x) (format "'%s'" x))
                                    python-view-data--group ", ")
                         (mapconcat (lambda (x) (format "'%s'" x))
                                    (nreverse (delete-dups (nreverse action))) ","))
               (format ".loc[:,[%s]].describe(include='all')"
                       (mapconcat (lambda (x) (format "'%s'" x))
                                  (nreverse (delete-dups (nreverse action))) ","))))
            ('describe-all
             ".describe(include='all')")
            ;; ('summarise
            ;;  (format " .aggregate(%s)" action))
            (_
             (format ".%s" action))))

    (setq cmd (concat
               ""
               (format (python-view-data--do-print python-view-data-current-summarize-print-backend)
                       (concat python-view-data-temp-object cmdhist)
                       python-view-data-temp-object)
               "\n"))
    (setq result (cons cmdhist cmd))
    result))

(cl-defmethod python-view-data--do-reset ((_backend (eql pandas.to_csv)) action)
  "Update the data frame by csv stepwisely.

Optional argument ACTION Python script to reset the view process,
which will become the cmd history."
  (let (cmdhist cmd result)
    (setq cmdhist action)
    (setq python-view-data-page-number 0)
    (setq cmd (concat
               python-view-data-temp-object " = " cmdhist "\n\n"
               ""
               (format (python-view-data--do-print python-view-data-current-update-print-backend)
                       (concat python-view-data-temp-object
                               (unless python-view-data-maxprint-p
                                 (format "[(%1$d*%2$d) : min((%1$d + 1)*%2$d, %s.__len__())]"
                                         python-view-data-page-number
                                         python-view-data-rows-per-page
                                         python-view-data-temp-object))))
               "\n"))
    (setq result (cons cmdhist cmd))
    result))

(cl-defmethod python-view-data-do-goto-page ((_backend (eql pandas.to_csv)) page &optional pnumber)
  "Goto PAGE.

Optional argument PNUMBER The page number to go to."
  (let (cmd result)
    (setq python-view-data-page-number
          (pcase page
            ('first 0)
            ('last (1- python-view-data-total-page))
            ('previous (max 0 (1- python-view-data-page-number)))
            ('next (min (1+ python-view-data-page-number) python-view-data-total-page))
            ('page (max (min pnumber python-view-data-total-page) 0))
            (_ python-view-data-page-number)))

    (setq cmd (concat
               (format (python-view-data--do-print python-view-data-current-update-print-backend)
                       (concat python-view-data-temp-object
                               (unless python-view-data-maxprint-p
                                 (format "[(%1$d*%2$d) : min((%1$d+1)*%2$d, %s.__len__())]"
                                         python-view-data-page-number
                                         python-view-data-rows-per-page
                                         python-view-data-temp-object))))
               "\n"))
    (setq result (cons nil cmd))
    result))


(cl-defmethod python-view-data-do-group ((_backend (eql pandas.to_csv)))
  "Groupby."
  (setq python-view-data--group
        (completing-read-multiple
         "Group By: "
         (python-view-data-get-object-cols) nil t)))

(cl-defmethod python-view-data-do-ungroup ((_backend (eql pandas.to_csv)))
  "Ungroup."
  (setq python-view-data--group nil))


(cl-defmethod python-view-data--create-indirect-buffer
  ((_backend (eql pandas.to_csv))
   type fun obj-list temp-object parent-buf proc-name)
  "Create an edit-indirect buffer and return it.

Optional argument TYPE Action type, e.g., update, reset, summarise.
Optional argument FUN Action function to do with data, e.g.,
select, count, and etc..
Optional argument OBJ-LIST Columns/variables to do with.
Optional argument TEMP-OBJECT Temporary data in the view process.
Optional argument PARENT-BUF The associated parent buffer for the view process.
Optional argument PROC-NAME The name of associated Python process,
usually `python-view-data-local-process-name'."
  (let ((buf (get-buffer-create (format python-view-data-source-buffer-name-format temp-object)))
        pts)
    (with-current-buffer buf
      (python-mode)
      (set-buffer-modified-p nil)
      (setq python-view-data--parent-buffer parent-buf)
      (setq python-view-data--reset-buffer-p t)
      (setq python-view-data--action `((:type . ,type) (:function . ,fun)))
      ;; (print (alist-get :function python-view-data--action))
      ;; (print (alist-get ':type python-view-data--action))
      (insert ";; Insert [all] variable name[s] (C-c C-i[a]), [all] Values (C-c C-l[v])\n")
      (insert ";; Line started with `;' will be omitted\n")
      (insert ";; Don't comment code as all code will be wrapped in one line\n")
      (pcase fun
        ((or 'filter 'query)
         ;; (setq python-view-data-completion-object (car obj-list))
         (insert ";; .query(...)\n")
         (setq pts (point))
         (insert (mapconcat (lambda (x) (propertize x 'evd-object x))
                            (delete-dups (nreverse obj-list)) ","))
         (goto-char pts))
        ('mutate
         (insert ";; .assign(...)\n")
         (setq pts (point))
         (insert (mapconcat (lambda (x) (format " = %s" (propertize x 'evd-object x)))
                            (delete-dups (nreverse obj-list)) ","))
         (goto-char pts))
        ('reset
         (insert ";; reset\n")
         (insert obj-list))
        (_
         (insert ";; ... \n")
         (setq pts (point))
         (insert (mapconcat #'identity (delete-dups (nreverse obj-list)) ","))
         (goto-char pts)))
      (setq python-view-data-local-process-name proc-name)
      (setq python-view-data-temp-object
            (buffer-local-value 'python-view-data-temp-object parent-buf))
      (python-view-data-edit-mode))
    (select-window (display-buffer buf))))



(defun python-view-data-do-commit ()
  "Commit the modifications done in an edit-indirect buffer.

Can be called only when the current buffer is an edit-indirect buffer."
  (interactive)
  (let* ((parent-buffer python-view-data--parent-buffer)
         (proc-name (buffer-local-value 'python-view-data-local-process-name parent-buffer))
         (proc (get-process proc-name))
         (fill-column most-positive-fixnum)
         (fun (alist-get :function python-view-data--action))
         (type (alist-get :type python-view-data--action))
         command)
    (with-current-buffer (current-buffer)
      (when python-view-data--reset-buffer-p
        (save-excursion
          (save-match-data
            (goto-char (point-min))
            (flush-lines "^;")
            (fill-region (point-min) (point-max))
            (setq command (buffer-substring-no-properties (point-min) (point-max)))
            ;; make command in one line to avoid the print of ` + ' in the output buffer
            (setq command (replace-regexp-in-string "\n+" " " command))))
        (kill-buffer)))

    (pop-to-buffer parent-buffer)

    (when (and proc-name proc command
               (not (process-get proc 'busy)))
      (setq command
            (pcase type
              ('update
               (python-view-data--do-update python-view-data-current-backend fun command))
              ('summarise
               (python-view-data--do-summarise python-view-data-current-backend fun command))
              ('reset
               (python-view-data--do-reset python-view-data-current-backend command))))
      (with-current-buffer parent-buffer
        (setq buffer-read-only nil)
        (erase-buffer)
        (setq-local scroll-preserve-screen-position t)
        (insert (string-replace "\\r\\n" "\n"
                                (replace-regexp-in-string
                                 (rx (or (: bos "'") (: "'" eos))) ""
                                 (python-shell-send-string-no-output
                                  (cdr command)
                                  proc))))
        (python-view-data-write-to-dribble-buffer (format "%s\n" (cdr command)))
        (when (memq type '(update reset))
          (if (eql type 'reset)
              (setq python-view-data-history (car command))
            (setq python-view-data-history (concat python-view-data-history (car command))))
          (setq python-view-data-page-number 0)
          (python-view-data-get-total-page python-view-data-current-backend proc-name proc))
        (python-view-data-write-to-dribble-buffer (format "# Trace: %s\n" python-view-data-history))
        (python-view-data-write-to-dribble-buffer (format "# Last: %s\n" (car command)))
        (goto-char (point-min))
        (python-view-data-mode 1)
        (goto-char (point-min))
        ;; (python-view-data--header-line python-view-data-current-backend)
        ))))


(defun python-view-data-do-apply (type fun indirect &optional desc prompt)
  "Update data frame.

Argument TYPE Action type, e.g., update, reset, summarise.
Argument FUN Action function to do with data, e.g., select, count, etc..
Argument INDIRECT Indirect buffer to edit the parameters or verbs.
Optional argument DESC if non-nil, then descending.
Optional argument PROMPT prompt for `read-string'."
  (unless (and
           python-view-data-local-process-name)
    (error "Not in an Python buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'python-view-data-local-process-name buf))
         (proc (get-process proc-name))
         obj-list
         command)
    ;; Initializing backed
    (python-view-data--initialize-backend python-view-data-current-backend proc-name proc)
    ;; variables
    (if (eql 'reset fun)
        ;; reset
        (python-view-data--create-indirect-buffer
         python-view-data-current-backend
         type fun
         python-view-data-history
         python-view-data-temp-object buf proc-name)
      ;; other actions
      (when (and proc-name proc
                 (not (process-get proc 'busy)))
        ;; FIXME: it is possible names with space
        (if prompt
            ;; general read-string
            (setq obj-list (read-string prompt))
          ;; read column names
          (if desc
              (progn
                (setq obj-list (python-view-data-get-object-cols))
                (setq obj-list
                      (append
                       (mapcar (lambda (x) (format "%s: ascending" x)) obj-list)
                       (mapcar (lambda (x) (format "%s: descending" x)) obj-list)))
                (setq obj-list (completing-read-multiple
                                "Select Variables: "
                                obj-list nil t)))
            (setq obj-list (completing-read-multiple
                            "Select Variables: "
                            (python-view-data-get-object-cols) nil t))))
        (if indirect
            (when obj-list
              (python-view-data--create-indirect-buffer python-view-data-current-backend
                                                        type fun obj-list
                                                        python-view-data-temp-object
                                                        buf proc-name))
          (when obj-list
            (setq command
                  (pcase type
                    ('update
                     (python-view-data--do-update python-view-data-current-backend fun obj-list))
                    ('summarise
                     (python-view-data--do-summarise python-view-data-current-backend fun obj-list)))))
          (when (and proc-name proc command
                     (not (process-get proc 'busy)))
            (with-current-buffer buf
              (setq buffer-read-only nil)
              (erase-buffer)
              (setq-local scroll-preserve-screen-position t)
              (insert (string-replace "\\r\\n" "\n"
                                      (replace-regexp-in-string
                                       (rx (or (: bos "'") (: "'" eos))) ""
                                       (python-shell-send-string-no-output
                                        (cdr command)
                                        proc))))
              (python-view-data-write-to-dribble-buffer (format "%s\n" (cdr command)))
              (when (eql type 'update)
                (setq python-view-data-history (concat python-view-data-history (car command)))
                (setq python-view-data-page-number 0)
                (python-view-data-get-total-page python-view-data-current-backend proc-name proc))
              (python-view-data-write-to-dribble-buffer (format "# Trace: %s\n" python-view-data-history))
              (python-view-data-write-to-dribble-buffer (format "# Last: %s\n" (car command)))
              (goto-char (point-min))
              (python-view-data-mode 1)
              (goto-char (point-min))
              ;; (python-view-data--header-line python-view-data-current-backend)
              )))))))




(defun python-view-data-select ()
  "Select columns/variables."
  (interactive)
  (python-view-data-do-apply 'update 'select nil nil))

(defun python-view-data-unselect ()
  "Select columns/variables."
  (interactive)
  (python-view-data-do-apply 'update 'unselect nil nil))

(defun python-view-data-sort ()
  "Sort columns/variables."
  (interactive)
  (python-view-data-do-apply
   'update 'sort nil
   (plist-get (alist-get python-view-data-current-backend python-view-data-backend-setting) :desc)))


(defun python-view-data-group ()
  "Group columns/variables."
  (interactive)
  (python-view-data-do-group python-view-data-current-backend))

(defun python-view-data-ungroup ()
  "Ungroup columns/variables."
  (interactive)
  (python-view-data-do-ungroup python-view-data-current-backend))


;; filter
(defun python-view-data-filter ()
  "Do filter."
  (interactive)
  (python-view-data-do-apply 'update 'filter t nil))

(defun python-view-data-query ()
  "Do query."
  (interactive)
  (python-view-data-do-apply 'update 'query t nil))


;; mutate
(defun python-view-data-mutate ()
  "Do mutate."
  (interactive)
  (python-view-data-do-apply 'update 'mutate t nil))


;; update
(defun python-view-data-update ()
  "Do update."
  (interactive)
  (python-view-data-do-apply 'update 'update t nil))

;;; ** reset
(defun python-view-data-reset ()
  "Do filter."
  (interactive)
  (python-view-data-do-apply 'reset 'reset t nil))


;;; ** summarise
(defun python-view-data-unique ()
  "Unique."
  (interactive)
  (python-view-data-do-apply 'summarise 'unique nil nil))


(defun python-view-data-count ()
  "Count."
  (interactive)
  (python-view-data-do-apply 'summarise 'count nil nil))

(defun python-view-data-describe ()
  "Count."
  (interactive)
  (python-view-data-do-apply 'summarise 'describe nil nil))

(defun python-view-data-summarise ()
  "Python view data do summarise."
  (interactive)
  (python-view-data-do-apply 'summarise 'summarise t nil))

(defun python-view-data-overview ()
  "Python view data do summarise."
  (interactive)
  (python-view-data-do-apply 'summarise 'overview t nil))


(defun python-view-data-verbs (verb)
  "Select the VERB to do."
  (interactive (list (completing-read
                      "verb: "
                      (append python-view-data-verb-update-list
                              python-view-data-verb-update-indirect-list
                              python-view-data-verb-summarise-list
                              python-view-data-verb-summarise-indirect-list
                              '("reset"))
                      nil t)))
  (cond
   ((member verb python-view-data-verb-update-list)
    (python-view-data-do-apply 'update (intern verb) nil nil))
   ((member verb python-view-data-verb-update-indirect-list)
    (python-view-data-do-apply 'update (intern verb) t nil))
   ((member verb python-view-data-verb-summarise-list)
    (python-view-data-do-apply 'summarise (intern verb) nil nil))
   ((member verb python-view-data-verb-summarise-indirect-list)
    (python-view-data-do-apply 'summarise (intern verb) t nil))
   ((string= verb "reset")
    (python-view-data-do-apply 'reset 'reset t nil))))



(defun python-view-data-commit-abort ()
  "Kill the edit-indirect buffer."
  (interactive)
  (kill-buffer))



;; scroll data

;;; ** goto page
(defun python-view-data-goto-page (page &optional pnumber)
  "Goto PAGE.
Optional argument PNUMBER page number to go."
  (unless (and
           python-view-data-local-process-name)
    (error "Not in an Python buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'python-view-data-local-process-name buf))
         (proc (get-process proc-name))
         command)
    (if python-view-data-verbose
        (python-view-data-write-to-dribble-buffer "Goto Page.\n"))

    ;; Initializing backed
    (python-view-data--initialize-backend python-view-data-current-backend proc-name proc)

    (setq command
          (python-view-data-do-goto-page python-view-data-current-backend
                                         page pnumber))

    (when python-view-data-verbose
      (python-view-data-write-to-dribble-buffer (format "buffer: %s\n" buf))
      (python-view-data-write-to-dribble-buffer (format "Command: %s\n" command)))

    (when (and proc-name proc command
               (not (process-get proc 'busy)))
      (with-current-buffer buf
        (setq buffer-read-only nil)
        (erase-buffer)
        (setq-local scroll-preserve-screen-position t)
        (insert (string-replace "\\r\\n" "\n"
                                (replace-regexp-in-string
                                 (rx (or (: bos "'") (: "'" eos))) ""
                                 (python-shell-send-string-no-output
                                  (cdr command)
                                  proc))))
        (python-view-data-write-to-dribble-buffer (format "%s\n" (cdr command)))
        (python-view-data-mode 1)
        (goto-char (point-min))
        (if python-view-data-verbose
            (python-view-data-write-to-dribble-buffer
             (format "Goto page: %s:%d\n" page pnumber)))))))


(defun python-view-data-goto-next-page ()
  "Python view data do select."
  (interactive)
  (python-view-data-goto-page 'next))

(defun python-view-data-goto-previous-page ()
  "Python view data do select."
  (interactive)
  (python-view-data-goto-page 'previous))

(defun python-view-data-goto-first-page ()
  "Python view data do select."
  (interactive)
  (python-view-data-goto-page 'first))

(defun python-view-data-goto-last-page ()
  "Python view data do select."
  (interactive)
  (python-view-data-goto-page 'last))


(defun python-view-data-goto-page-number (&optional pnumber)
  "Python view data do select.

Optional argument PNUMBER The page number to go to."
  (interactive "NGoto page:")
  ;; (unless pnumber )
  (python-view-data-goto-page 'page (1- pnumber)))


;;; * save data

(cl-defmethod python-view-data-do-save ((_backend (eql pandas.to_csv)) file-name)
  "Python view data doing select by write.csv stepwise.

Optional argument FILE-NAME file name."
  (let (cmd result)
    (setq cmd (concat
               python-view-data-temp-object ".to_csv(\""
               file-name
               "\")\n"))
    (setq result (cons nil cmd))
    result))

(cl-defmethod python-view-data-do-save ((_backend (eql pandas.to_excel)) file-name)
  "Python view data doing select by write.excel stepwise.

Optional argument FILE-NAME file name."
  (let (cmd result)
    (setq cmd (concat
               python-view-data-temp-object ".to_excel(\""
               file-name
               "\")\n"))
    (setq result (cons nil cmd))
    result))


(defun python-view-data-save ()
  "Python view data do save."
  (interactive)
  (unless (and
           python-view-data-local-process-name)
    (error "Not in an Python buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'python-view-data-local-process-name buf))
         (proc (get-process proc-name))
         file-name
         command)
    ;; Initializing backed
    (python-view-data--initialize-backend python-view-data-current-backend proc-name proc)
    ;; slice variables
    (setq file-name (find-file-read-args "Find file: "
                                         (confirm-nonexistent-file-or-buffer)))
    (if file-name
        (setq command
              (python-view-data-do-save python-view-data-current-save-backend (car file-name))))
    (when (and proc-name proc command
               (not (process-get proc 'busy)))
      (python-shell-send-string (cdr command) proc)
      (python-view-data-write-to-dribble-buffer "Saved.\n")
      (python-view-data-write-to-dribble-buffer (format "# Trace: %s\n" python-view-data-history))
      (python-view-data-write-to-dribble-buffer (format "# Last: %s\n" (car command)))
      (with-current-buffer buf
        (goto-char (point-min))))))



;; utilities
(defun python-view-data-quit ()
  "Quit from python-view-data."
  (interactive)
  (kill-buffer))

(defun python-view-data-kill-buffer-hook ()
  "Hook for `kill-buffer' to clean environment."
  (let* ((proc-name (buffer-local-value 'python-view-data-local-process-name (current-buffer)))
         (proc (get-process proc-name)))
    (python-view-data-do-kill-buffer-hook python-view-data-current-backend proc-name proc)))

(defun python-view-data-print-ex (&optional obj proc-name maxprint)
  "Do print.

Optional argument OBJ the object (data.frame/tibble etc.) to print and view.
Optional argument PROC-NAME the name of associated Python process.
Optional argument MAXPRINT if non-nil, 100 rows/lines per page; if t, show all."
  (interactive "P")
  (let* ((obj (or obj python-view-data-object))
         (proc-name (or proc-name
                        (buffer-local-value 'python-view-data-local-process-name
                                            (current-buffer))
                        (python-shell-get-process-or-error)))
         (buf (get-buffer-create (format python-view-data-buffer-name-format
                                         obj proc-name)))
         ;; (proc-name-buf (buffer-local-value 'python-view-data-local-process-name buf))
         (proc (get-process proc-name))
         command)
    ;; (if (or (not proc-name-buf) (equal proc-name proc-name-buf))
    ;; A new view or from the same process
    (when python-view-data-verbose
      (python-view-data-write-to-dribble-buffer (format "Print %s.\n" obj))
      (python-view-data-write-to-dribble-buffer (format "Buffer: %s.\n" buf)))

    (with-current-buffer buf
      (csv-mode)
      (if maxprint
          (setq python-view-data-maxprint-p (not python-view-data-maxprint-p)))
      (unless python-view-data-object
        (setq python-view-data-object obj)
        (setq python-view-data-local-process-name proc-name))
      (python-view-data--initialize-backend python-view-data-current-backend
                                            proc-name proc)
      (when python-view-data-verbose
        (python-view-data-write-to-dribble-buffer
         (format "Temp-object: %s\n"
                 python-view-data-temp-object)))

      (sleep-for 0.1)

      (python-view-data-get-total-page python-view-data-current-backend
                                       proc-name proc)
      (setq command
            (python-view-data--do-reset
             python-view-data-current-backend
             (format "%s" python-view-data-object))))

    (when python-view-data-verbose
      (python-view-data-write-to-dribble-buffer (format "Command: %s\n" command)))

    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (with-current-buffer buf
        (setq buffer-read-only nil)
        (erase-buffer)
        (setq-local scroll-preserve-screen-position t)
        (insert (string-replace "\\r\\n" "\n"
                                (replace-regexp-in-string
                                 (rx (or (: bos "'") (: "'" eos))) ""
                                 (python-shell-send-string-no-output
                                  (cdr command)
                                  proc))))
        (python-view-data-write-to-dribble-buffer (format "%s\n" (cdr command)))
        (python-view-data-mode 1)
        (goto-char (point-min)))
      buf)))



;;;###autoload
(defun python-view-data-print (&optional maxprint)
  "Ess R dv using pprint.
Optional argument MAXPRINT maxprint."
  (interactive "P")
  (unless (or python-view-data-local-process-name
              (memq major-mode
                    '(python-ts-mode python-mode inferior-python-mode)))
    (warn "Not in an Python buffer with attached process"))
  (if python-view-data-verbose
      (python-view-data-write-to-dribble-buffer "\n\n"))
  (let* ((obj (or python-view-data-object
                  (tabulated-list-get-id)
                  (python-view-data-read-object-name "Pandas Dataframe: "))))
    (if python-view-data-verbose
        (python-view-data-write-to-dribble-buffer (format "Print %s.\n" obj)))

    (pop-to-buffer (python-view-data-print-ex obj maxprint))))


(provide 'python-view-data)
;;; python-view-data.el ends here
