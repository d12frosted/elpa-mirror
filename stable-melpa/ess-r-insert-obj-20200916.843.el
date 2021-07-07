;;; ess-r-insert-obj.el --- Insert objects in ESS-R  -*- lexical-binding: t; -*-

;; Copyright (C) 2019-2020  Shuguang Sun <shuguang79@qq.com>

;; Author: Shuguang Sun <shuguang79@qq.com>
;; Created: 2019/04/06
;; Version: 1.0
;; Package-Version: 20200916.843
;; Package-Commit: f6731eb26dc0fc5b7ca1fa881a5f9100f8fcf494
;; URL: https://github.com/ShuguangSun/ess-r-insert-obj
;; Package-Requires: ((emacs "26.1") (ess "18.10.1"))
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

;; This package contains utilities to help insert variable (column) names or
;; values in ESS-R. The listing is as follows.

;; ## Utils:
;; To help insert Data.frame-like object:
;; - M-x ess-r-insert-obj-dt-name

;; To help insert Variable (Column) name: with `C-u C-u`, it prompts for the dt
;; name to search in.
;; - M-x ess-r-insert-obj-col-name
;; - M-x ess-r-insert-obj-col-name-all

;; To help insert values: with `C-u C-u`, it prompts for the dt name to search
;; in, or with `C-u`, it prompts for column/variable name to search in.
;; - M-x ess-r-insert-obj-value
;; - M-x ess-r-insert-obj-value-all

;; ## Customization
;; ### ess-r-insert-obj-complete-backend-list
;; - jsonlite
;; ### ess-r-insert-obj-read-string
;; - ess-completing-read (default)
;; - completing-read
;; - ido-completing-read
;; - ivy-completing-read


;;; Code:

(eval-when-compile (require 'cl-lib))
(eval-when-compile (require 'cl-generic))

(require 'ess-inf)
(require 'ess-rdired)
(require 'ess-r-mode)
(require 'ess-r-completion)
(require 'subr-x)
(require 'json)

(defvar ess-r-insert-obj-complete-backend-list
  (list 'jsonlite)
  "List of backends to read completion list.")

(defcustom ess-r-insert-obj-current-complete-backend 'jsonlite
  "The backend to complete data.

From R data to Emacs list."
  :type `(choice ,@(mapcar (lambda (x)
			                 `(const :tag ,(symbol-name x) ,x))
			               ess-r-insert-obj-complete-backend-list)
                 (symbol :tag "Other"))
  :group 'ess-r-insert-obj)


(defcustom ess-r-insert-obj-read-string 'ess-completing-read
  "The function used to completing read."
  :type `(choice (const :tag "ESS" ess-completing-read)
                 (const :tag "basic" completing-read)
                 (const :tag "ido" ido-completing-read)
                 (const :tag "ivy" :require 'ivy ivy-completing-read)
                 (function :tag "Other"))
  :group 'ess-r-insert-obj)



(defvar-local ess-r-insert-obj-object nil
  "The candidate for completion.")

(defvar-local ess-r-insert-obj-dt-candidate nil
  "The candidate for completion from which dt.")

(defvar-local ess-r-insert-obj-col-candidate nil
  "The candidate for completion from which column (variable).")

(defvar-local ess-r-insert-obj-candidate nil
  "The candidate for completion.")


(cl-defgeneric ess-r-insert-obj-do-complete-data (backend str)
  "Completing input.

Argument BACKEND Backend to dispatch, i.e.,
the `ess-r-insert-obj-current-complete-backend'.
Argument STR R script to run.")

;;; jsonlite
(cl-defmethod ess-r-insert-obj-do-complete-data ((_backend (eql jsonlite)) &optional dataframe)
  "To get the list for completing in data frame.

Optional argument DATAFRAME name of data.frame-like object."
  (let ((cmd
         (concat
           "jsonlite::toJSON("
           (format "c(list(%1$s = names(%1$s)), lapply(%1$s, function(x) as.character(unique(x))))"
                   (or dataframe ess-r-insert-obj-object))
           ")\n")))
    (json-read-from-string (ess-string-command cmd))))


;;; Utility
(defun ess-r-insert-obj-get-objects ()
  "Get the list of data.frame-like objects (is.list) for completion."
  (let* ((call1 "ls()[c(sapply(ls(), function(x) {is.list(eval(parse(text = x)))}))]")
         (cmd (concat  call1 "\n")))
    (setq ess-r-insert-obj-dt-candidate (ess-get-words-from-vector cmd))
    ess-r-insert-obj-dt-candidate))

(defun ess-r-insert-obj-set-object ()
  "Set the object for completion."
  (interactive "P")
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (user-error "Not in an R buffer with attached process"))
  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         (objs (ess-r-insert-obj-get-objects)))
    (when objs
      ;; (ess-read-object-name "obj" )
      (setq ess-r-insert-obj-object
            (funcall ess-r-insert-obj-read-string "Object:" objs nil t))

      (when (and proc-name proc
                 (not (process-get proc 'busy)))
        (setq ess-r-insert-obj-candidate
              (ess-r-insert-obj-do-complete-data ess-r-insert-obj-current-complete-backend))))))


(defun ess-r-insert-obj--previous-complete-object (prop)
  "Search for the object.

Argument PROP text property, i.e., dt-insert, col-insert."
  (let (prop-value)
    (while (progn
             (goto-char (previous-single-char-property-change (point) prop))
             (not (or (setq prop-value (get-text-property (point) prop))
                      (eobp)
                      (bobp)))))
    prop-value))


;;;###autoload
(defun ess-r-insert-obj-dt-name ()
  "Insert name of data.frame-like object."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (user-error "Not in an R buffer with attached process"))

  (let* ((possible-completions (ess-r-get-rcompletions))
         (token-string (or (car possible-completions) ""))
         (start (- (point) (length token-string)))
         (end (point))
         (buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         (objs (ess-r-insert-obj-get-objects))
         dt-insert)
    (setq ess-r-insert-obj-object
          (funcall ess-r-insert-obj-read-string
                   "data.frame: " objs
                   nil t token-string))
    (when (and proc-name proc
               (not (process-get proc 'busy)))
      (setq ess-r-insert-obj-candidate
            (ess-r-insert-obj-do-complete-data ess-r-insert-obj-current-complete-backend)))
    (setq dt-insert ess-r-insert-obj-object)
    (delete-region start end)
    ;; propertize
    (insert (propertize dt-insert 'dt-insert dt-insert))))


;;;###autoload
(defun ess-r-insert-obj-col-name ()
  "Insert column/variable name.

If called with a prefix, prompt for a data.frame-like object to search in.

With two \\[universal-argument] prefixes (i.e., when `current-prefix-arg' is (16)),
prompt for a data.frame-like object to search in."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (user-error "Not in an R buffer with attached process"))

  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         dt-insert)

    (when (or (equal current-prefix-arg '(16))
              (null (save-excursion
                      (save-restriction
                        (setq dt-insert (ess-r-insert-obj--previous-complete-object 'dt-insert))))))
      ;; force refresh
      (let ((objs (ess-r-insert-obj-get-objects)))
        (setq ess-r-insert-obj-object
              (funcall ess-r-insert-obj-read-string
                       "data.frame: " objs
                       nil t))
        (when (and proc-name proc
                   (not (process-get proc 'busy)))
          (setq ess-r-insert-obj-candidate
                (ess-r-insert-obj-do-complete-data ess-r-insert-obj-current-complete-backend))))
      (setq dt-insert ess-r-insert-obj-object))

    (when dt-insert
      (let ((objs (append
                   (if (assq (intern dt-insert)
                             ess-r-insert-obj-candidate)
                       (alist-get (intern dt-insert)
                                  ess-r-insert-obj-candidate)
                     (alist-get (intern (replace-regexp-in-string
                                         "`" "" dt-insert))
                                ess-r-insert-obj-candidate))
                   nil))
            (obj " ")
            objs2
            obj-list)
        (if current-prefix-arg
            (progn
              (while (not (equal obj ""))
                (setq obj (funcall ess-r-insert-obj-read-string
                                   (format "Column (%s), C-j to finish"
                                           (mapconcat 'identity
                                                      (setq objs2 (nreverse objs2))
                                                      ","))
                                   objs))
                (unless (equal obj "")
                  (setq objs (delete obj objs))
                  (cl-pushnew obj obj-list)
                  (cl-pushnew obj objs2)))
              (unless (null obj-list)
                (insert (propertize (mapconcat 'identity (delete-dups (nreverse obj-list)) ",")
                                    'dt-insert dt-insert))))
          (let* ((possible-completions (ess-r-get-rcompletions))
                 (token-string (or (car possible-completions) ""))
                 (start (- (point) (length token-string)))
                 (end (point))
                 com)
            (setq com
                  (funcall ess-r-insert-obj-read-string
                           "Column: " objs
                           nil t token-string))
            (delete-region start end)
            (insert (propertize com 'dt-insert dt-insert))))))))


;;;###autoload
(defun ess-r-insert-obj-col-name-all ()
  "Insert names of all column/variable name.

If called with a prefix, prompt for a data.frame-like object to search in.

With two \\[universal-argument] prefixes (i.e., when `current-prefix-arg' is (16)),
prompt for a data.frame-like object to search in."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (user-error "Not in an R buffer with attached process"))

  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         dt-insert)

    (when (or (equal current-prefix-arg '(16))
            (null (save-excursion
                    (save-restriction
                      (setq dt-insert (ess-r-insert-obj--previous-complete-object 'dt-insert))))))
      ;; force refresh
      (let ((objs (ess-r-insert-obj-get-objects)))
            (setq ess-r-insert-obj-object
                  (funcall ess-r-insert-obj-read-string
                           "data.frame: " objs
                           nil t))
            (when (and proc-name proc
                       (not (process-get proc 'busy)))
              (setq ess-r-insert-obj-candidate
                    (ess-r-insert-obj-do-complete-data ess-r-insert-obj-current-complete-backend))))
      (setq dt-insert ess-r-insert-obj-object))

    (when dt-insert
        (let* ((obj-list (append
                          (if (assq (intern ess-r-insert-obj-object)
                                    ess-r-insert-obj-candidate)
                              (alist-get (intern ess-r-insert-obj-object)
                                         ess-r-insert-obj-candidate)
                            (alist-get (intern (replace-regexp-in-string
                                                "`" "" ess-r-insert-obj-object))
                                       ess-r-insert-obj-candidate))
                          nil)))
          (insert (propertize (mapconcat 'identity
                                          (delete-dups obj-list) ",")
                               'dt-insert dt-insert))))))

;;;###autoload
(defun ess-r-insert-obj-value ()
  "Insert variable value.

If called with a prefix, prompt for a data.frame-like object or
column/variable to search in.

With a \\[universal-argument] prefix (i.e., when `current-prefix-arg' is (4)),
prompt for a column/variable object to search in.
With two \\[universal-argument] prefixes (i.e., when `current-prefix-arg' is (16)),
prompt for a data.frame-like object to search in."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (user-error "Not in an R buffer with attached process"))

  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         dt-insert
         col-insert)

    (when (or (equal current-prefix-arg '(16))
              (null (save-excursion
                     (save-restriction
                       (setq dt-insert (ess-r-insert-obj--previous-complete-object 'dt-insert))))))
      (let* ((objs (ess-r-insert-obj-get-objects)))
        (setq ess-r-insert-obj-object
              (funcall ess-r-insert-obj-read-string
                       "data.frame: " objs
                       nil t))
        (when (and proc-name proc
                   (not (process-get proc 'busy)))
          (setq ess-r-insert-obj-candidate
                (ess-r-insert-obj-do-complete-data ess-r-insert-obj-current-complete-backend))))
      (setq dt-insert ess-r-insert-obj-object))

    (when (or current-prefix-arg
              (and dt-insert
                   (null (save-excursion
                           (save-restriction
                             (setq col-insert (ess-r-insert-obj--previous-complete-object 'col-insert)))))))
      (setq col-insert
            (funcall ess-r-insert-obj-read-string
                     "Column: "
                     (append
                      (if (assq (intern dt-insert)
                                ess-r-insert-obj-candidate)
                          (alist-get (intern dt-insert)
                                     ess-r-insert-obj-candidate)
                        (alist-get (intern (replace-regexp-in-string
                                            "`" "" dt-insert))
                                   ess-r-insert-obj-candidate))
                      nil)
                     nil t)))

    (when (and dt-insert col-insert)
          (let* ((possible-completions (ess-r-get-rcompletions))
                 (token-string (or (car possible-completions) ""))
                 (start (- (point) (length token-string)))
                 (end (point))
                 com)
            (setq com
                  (funcall ess-r-insert-obj-read-string
                           "Value: "
                           (delq nil (delete-dups (append
                            (if (assq (intern col-insert)
                                      ess-r-insert-obj-candidate)
                                (alist-get (intern col-insert)
                                           ess-r-insert-obj-candidate)
                              (alist-get (intern (replace-regexp-in-string
                                                  "`" "" col-insert))
                                         ess-r-insert-obj-candidate))
                            nil)))
                           nil t token-string))
            (delete-region start end)
            (insert (propertize (format "\"%s\"" com)
                                'dt-insert dt-insert
                                'col-insert col-insert))))))

;;;###autoload
(defun ess-r-insert-obj-value-all ()
  "Insert all variable values.

If called with a prefix, prompt for a data.frame-like object or
column/variable to search in.

With a \\[universal-argument] prefix (i.e., when `current-prefix-arg' is (4)),
prompt for a column/variable object to search in.
With two \\[universal-argument] prefixes (i.e., when `current-prefix-arg' is (16)),
prompt for a data.frame-like object to search in."
  (interactive)
  (unless (and ;; (string= "R" ess-dialect)
           ess-local-process-name)
    (user-error "Not in an R buffer with attached process"))

  (let* ((buf (current-buffer))
         (proc-name (buffer-local-value 'ess-local-process-name buf))
         (proc (get-process proc-name))
         dt-insert
         col-insert)

    (when (or (equal current-prefix-arg '(16))
              (null (save-excursion
                     (save-restriction
                       (setq dt-insert (ess-r-insert-obj--previous-complete-object 'dt-insert))))))
      (let* ((objs (ess-r-insert-obj-get-objects)))
        (setq ess-r-insert-obj-object
              (funcall ess-r-insert-obj-read-string
                       "data.frame: " objs
                       nil t))
        (when (and proc-name proc
                   (not (process-get proc 'busy)))
          (setq ess-r-insert-obj-candidate
                (ess-r-insert-obj-do-complete-data ess-r-insert-obj-current-complete-backend))))
      (setq dt-insert ess-r-insert-obj-object))

    (when (or current-prefix-arg
              (and dt-insert
                   (null (save-excursion
                           (save-restriction
                             (setq col-insert (ess-r-insert-obj--previous-complete-object 'col-insert)))))))
      (setq col-insert
            (funcall ess-r-insert-obj-read-string
                     "Column: "
                     (append
                      (if (assq (intern dt-insert)
                                ess-r-insert-obj-candidate)
                          (alist-get (intern dt-insert)
                                     ess-r-insert-obj-candidate)
                        (alist-get (intern (replace-regexp-in-string
                                            "`" "" dt-insert))
                                   ess-r-insert-obj-candidate))
                      nil)
                     nil t)))

    (when (and dt-insert col-insert)
      (let* ((obj-list (append
                        (if (assq (intern col-insert)
                                  ess-r-insert-obj-candidate)
                            (alist-get (intern col-insert)
                                       ess-r-insert-obj-candidate)
                          (alist-get (intern (replace-regexp-in-string
                                              "`" "" col-insert))
                                     ess-r-insert-obj-candidate))
                        nil)))
        (insert (propertize (mapconcat 'identity
                                       (delete-dups obj-list) ",")
                            'dt-insert dt-insert
                            'col-insert col-insert))))))


(provide 'ess-r-insert-obj)
;;; ess-r-insert-obj.el ends here
