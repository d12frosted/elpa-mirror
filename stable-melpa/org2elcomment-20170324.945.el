;;; org2elcomment.el --- Convert Org file to Elisp comments  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Junpeng Qiu

;; Author: Junpeng Qiu <qjpchmail@gmail.com>
;; Package-Requires: ((org "8.3.4"))
;; Package-Version: 20170324.945
;; Package-Commit: c88a75d9587c484ead18f7adf08592b09c1cceb0
;; Keywords: extensions

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

;;                             _______________

;;                              ORG2ELCOMMENT

;;                               Junpeng Qiu
;;                             _______________


;; Table of Contents
;; _________________

;; 1 Overview
;; 2 Usage
;; .. 2.1 Command `org2elcomment'
;; .. 2.2 Command `org2elcomment-anywhere'
;; 3 Customization
;; .. 3.1 Org Export Backend
;; .. 3.2 Exporter Function


;; Convert `org-mode' file to Elisp comments.


;; 1 Overview
;; ==========

;;   This simple package is mainly used for Elisp package writers.  After
;;   you've written the `README.org' for your package, you can use
;;   `org2elcomment' to convert the org file to Elisp comments in the
;;   corresponding source code file.


;; 2 Usage
;; =======

;;   Make sure your source code file has `;;; Commentary:' and `;;; Code:'
;;   lines.  The generated comments will be put between these two lines.
;;   If you use `auto-insert', it will take care of generating a standard
;;   file header that contains these two lines in your source code.


;; 2.1 Command `org2elcomment'
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~

;;   In your Org file, invoke `org2elcomment', select the source code file,
;;   and done! Now take a look at your source code file, you can see your
;;   Org file has been converted to the comments in your source code file.


;; 2.2 Command `org2elcomment-anywhere'
;; ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

;;   You can invoke this command anywhere in Emacs.  It requires two
;;   parameters.  You need to select the source code file as well as the
;;   org file.  After selecting the org file, you can optionally save the
;;   org file location as the file-local variable in the source code file
;;   so that you don't need to select the org file again for the same
;;   source code file.

;;   If you want to automate the process of converting the org to the
;;   commentary section in Elisp file in your project, you can consider
;;   using this command.


;; 3 Customization
;; ===============

;; 3.1 Org Export Backend
;; ~~~~~~~~~~~~~~~~~~~~~~

;;   Behind the scenes, this package uses `org-export-as' function and the
;;   default backend is `ascii'.  You can change to whatever backend that
;;   your org-mode export engine supports, such as `md' (for markdown):

;;   ,----
;;   | (setq org2elcomment-backend 'md)
;;   `----


;; 3.2 Exporter Function
;; ~~~~~~~~~~~~~~~~~~~~~

;;   In fact, it is even possible to use your own export function instead
;;   of the exporter of org-mode.  Write a function which accepts a file
;;   name of an org file and returns the string as the export result.  Here
;;   is how the default exporter that we use in this package looks like:

;;   ,----
;;   | (defun org2elcomment-default-exporter (org-file)
;;   |   (with-temp-buffer
;;   |     (insert-file-contents org-file)
;;   |     (org-export-as org2elcomment-backend)))
;;   `----

;;   After defining your own export function, say, `my-exporter', change
;;   the value of `org2elcomment-exporter':

;;   ,----
;;   | (setq org2elcomment-exporter 'my-exporter)
;;   `----

;;; Code:

(require 'org)
(require 'pulse nil t)

(defvar org2elcomment-backend 'ascii
  "Org export backend used by the default exporter of `org2elcomment'.")
(defvar org2elcomment-exporter 'org2elcomment-default-exporter
  "Export function used by `org2elcomment'.")

(defvar org2elcomment-last-source nil)
(make-variable-buffer-local 'org2elcomment-last-source)

(defvar org2elcomment-anywhere-last-source nil)

(defvar org2elcomment-anywhere-org-file nil)

(defun org2elcomment--find-bounds (buffer)
  (let (beg end)
    (with-current-buffer buffer
      (save-excursion
        (goto-char (point-min))
        (when (re-search-forward "^;;;[[:blank:]]+Commentary:[[:blank:]]*$" nil t)
          (setq beg (line-beginning-position 2))
          (when (re-search-forward "^;;;[[:blank:]]+Code:[[:blank:]]*$")
            (setq end (line-beginning-position))
            (if (and beg end)
                (cons beg end)
              (message "org2elcomment: No \";;; Commentary:\" or \";;; Code:\" found.")
              nil)))))))

(defun org2elcomment--get-prompt (initial default-value)
  (if default-value
      (format "%s (default \"%s\"): " initial default-value)
    (format "%s: " initial)))

(defmacro org2elcomment--interactive-form (name)
  `(list (let ((prompt (org2elcomment--get-prompt "Elisp file" ,name)))
           (setq ,name (read-file-name prompt nil ,name t)))))

(defun org2elcomment-default-exporter (org-file)
  (with-temp-buffer
    (insert-file-contents org-file)
    (goto-char (point-min))
    (while (search-forward ". " nil t)
      (replace-match ".  "))
    (let ((sentence-end-double-space t))
      (org-export-as org2elcomment-backend))))

(defun org2elcomment--save-org-to-el (buffer value)
  "Set current file's local variable `org2elcomment-anywhere-org-file'."
  (when (yes-or-no-p "Save org file location to Elisp file? ")
    (with-current-buffer buffer
      (add-file-local-variable
       'org2elcomment-anywhere-org-file value))))

(defun org2elcomment--read-org-from-el (buffer el-file-dir)
  "Get org file location from current buffer's context.

`org2elcomment-anywhere-org-file' only save the relative path of
the org file. We need to return its abosolute path based
directory EL-FILE-DIR."
  (with-current-buffer buffer
    (hack-local-variables)
    (when (assoc 'org2elcomment-anywhere-org-file
                 file-local-variables-alist)
      (let ((org-file
             (concat (file-name-as-directory el-file-dir)
                     org2elcomment-anywhere-org-file)))
        (and org-file (file-exists-p org-file) org-file)))))

(defun org2elcomment--update-comment (el-file org-file &optional pre-handler
                                              post-handler)
  (if (file-locked-p el-file)
      (message "org2elcomment: File %S has been locked. Operation denied. " el-file)
    (with-temp-buffer
      (insert-file-contents el-file)

      (emacs-lisp-mode)

      ;; change `org-file' if necessary
      (when pre-handler
        (setq org-file (funcall pre-handler el-file org-file)))

      ;; now it's good to update `org2elcomment-anywhere-org-file'
      (setq org2elcomment-anywhere-org-file org-file)

      (let ((bounds (org2elcomment--find-bounds (current-buffer)))
            output beg end)
        (when (and bounds (setq output (funcall org2elcomment-exporter org-file)))
          (kill-region (car bounds) (cdr bounds))
          (goto-char (car bounds))
          (insert "\n")
          (setq beg (point))
          (insert output)
          (comment-region beg (point))
          (insert "\n")
          (setq end (point))
          (setq output (buffer-string))
          (let ((buffer (get-file-buffer el-file)))
            (if buffer
                (with-current-buffer buffer
                  (let ((point (point)))
                    (erase-buffer)
                    (insert output)
                    (goto-char point))
                  (message "org2elcomment: The commentary in buffer %S has been updated."
                           (buffer-name buffer)))
              (write-region (point-min)
                            (point-max) el-file)
              (message "org2elcomment: The commentary of file %S has been updated." el-file))
            ;; some visual effect if necessary
            (when post-handler
              (funcall post-handler (find-file-noselect el-file) beg end))))))))

(defun org2elcomment--pre-handler (el-file org-file)
  (goto-char (point-min))
  (let ((el-file-dir (file-name-directory el-file)))
    (setq org-file
          (or (if (and org-file (file-exists-p org-file))
                  org-file)
              (org2elcomment--read-org-from-el (current-buffer) el-file-dir)
              (read-file-name
               (org2elcomment--get-prompt "Org file" org2elcomment-anywhere-org-file)
               el-file-dir
               org2elcomment-anywhere-org-file
               t)))

    (unless (org2elcomment--read-org-from-el (current-buffer) el-file-dir)
      (org2elcomment--save-org-to-el
       (current-buffer) (file-relative-name org-file el-file-dir)))
    org-file))

(defun org2elcomment--post-handler (el-buf beg end)
  (switch-to-buffer el-buf)
  (push-mark)
  (goto-char beg)
  (recenter 0)
  (when (featurep 'pulse)
    (pulse-momentary-highlight-region beg end)))

;;;###autoload
(defun org2elcomment-anywhere (el-file &optional org-file)
  "Convert ORG-FILE to the commentary section in EL-FILE.
This command can be invoked anywhere inside Emacs."
  (interactive (org2elcomment--interactive-form org2elcomment-anywhere-last-source))
  (org2elcomment--update-comment el-file org-file #'org2elcomment--pre-handler))

;;;###autoload
(defun org2elcomment (el-file)
  "Conver the current org file to the commentary section in EL-FILE.
This command must be invoked when the current buffer is in `org-mode'."
  (interactive (org2elcomment--interactive-form org2elcomment-last-source))
  (org2elcomment--update-comment el-file (buffer-file-name) nil #'org2elcomment--post-handler))

(provide 'org2elcomment)
;;; org2elcomment.el ends here
