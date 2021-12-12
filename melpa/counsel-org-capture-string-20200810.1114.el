;;; counsel-org-capture-string.el --- Counsel for org-capture-string -*- lexical-binding: t -*-

;; Copyright (C) 2018 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 1.0-pre
;; Package-Requires: ((emacs "25.1") (ivy "0.13"))
;; Keywords: outlines
;; URL: https://github.com/akirak/counsel-org-capture-string

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides `counsel-org-capture-string' command, which is
;; supplies input to `org-capture-string' from Counsel/Ivy.

;; Because the command is based on Ivy, it supports extra actions.
;; You can insert/copy a candidate, and you can add custom actions.

;;; Code:

(require 'ivy)
(require 'org-capture)
(require 'map)
(require 'imenu)
(require 'cl-lib)
(require 'subr-x)

(defcustom counsel-org-capture-string-sources
  '(counsel-org-capture-string--org-clock-candidates
    counsel-org-capture-string--buffer-name-candidates
    counsel-org-capture-string--projectile-candidates
    counsel-org-capture-string--imenu-candidates)
  "List of candidate generators for `counsel-org-capture-string'.

Each item in this list should be a function that takes no argument and returns
an alist.  Each item in the resulting list should be a cons cell of a content
string and a help string."
  :type '(repeat function)
  :group 'counsel-org-capture-string)

(defcustom counsel-org-capture-string-height 6
  "`ivy-height' for `counsel-org-capture-string'.

When nil, the default value is used."
  :type '(choice integer (const nil))
  :group 'counsel-org-capture-string
  :set (lambda (key value)
         (set key value)
         (setf (map-elt ivy-height-alist 'counsel-org-capture-string) value)))

(defcustom counsel-org-capture-string-filter-templates t
  "Exclude templates only that contain \"%i\" in the body.

This affects the descriptive list of templates (which is bound on
\"c\" by default).  As `org-capture-string' sets the initial text
of `org-capture' to its argument, it doesn't make sense if the
template doesn't contain a place holder for the initial text.

When this option is turned on, the template list function checks
the template strings and eliminate that don't contain a place holder.
Note that non-string templates, i.e. a file or a function, are also
excluded if this option is turned on."
  :group 'counsel-org-capture-string
  :type 'boolean)

(defcustom counsel-org-capture-string-use-ivy-selector nil
  "Use an Ivy template selector as the default action.

When this option is non-nil, `counsel-org-capture-string' uses
an Ivy-based template selector as the default action.
Otherwise, it uses the built-in template selector of `org-capture'."
  :group 'counsel-org-capture-string
  :type 'boolean)

(defvar counsel-org-capture-string--candidates nil)
(defvar counsel-org-capture-string-history nil)

;;;; Faces
(defface counsel-org-capture-string-template-body-face
  '((t :inherit font-lock-builtin-face))
  "Face for template bodies."
  :group 'counsel-org-capture-string)

;;;###autoload
(defun counsel-org-capture-string ()
  "Supply input to `org-capture-string' from counsel."
  (interactive)
  (ivy-read "Initial text: "
            #'counsel-org-capture-string--candidates
            :caller 'counsel-org-capture-string
            :history 'counsel-org-capture-string-history
            :action
            (if counsel-org-capture-string-use-ivy-selector
                #'counsel-org-capture-string--select
              #'org-capture-string)))

(defun counsel-org-capture-string--candidates (&optional _string
                                                         _collection
                                                         _predicate)
  "Generate completion candidates."
  (mapcar #'car
          (setq counsel-org-capture-string--candidates
                (apply #'append
                       (mapcar #'funcall counsel-org-capture-string-sources)))))

(defun counsel-org-capture-string--transformer (str)
  "Format input STR."
  (if-let ((help (cdr (assoc str counsel-org-capture-string--candidates))))
      (format "%s %s" (propertize help 'face 'ivy-action) str)
    str))

(ivy-configure 'counsel-org-capture-string
  :display-transformer-fn 'counsel-org-capture-string--transformer)

(defun counsel-org-capture-string--template-list (_string _candidates _)
  "Generate a descriptive list of `org-capture-templates'."
  (let* ((table (cl-loop for (key desc type target body) in org-capture-templates
                         when type
                         when (or (not counsel-org-capture-string-filter-templates)
                                  (and (stringp body)
                                       (string-match-p "%i" body)))
                         collect (list key
                                       desc
                                       (symbol-name type)
                                       (pcase target
                                         (`(id ,id) (format "id:%s" id))
                                         (`(clock) "(clock)")
                                         (`(function ,func) (if (symbolp func)
                                                                (symbol-name func)
                                                              "(lambda)"))
                                         (`(,_ ,filename . ,_) (if (= 0 (length filename))
                                                                   "default"
                                                                 (file-name-nondirectory filename)))
                                         (_ (prin1-to-string target))))))
         (w1 (apply #'max (mapcar (lambda (cells) (length (nth 0 cells)))
                                  table)))
         (w2 (apply #'max (mapcar (lambda (cells) (length (nth 1 cells)))
                                  table)))
         (w3 (apply #'max (mapcar (lambda (cells) (length (nth 2 cells)))
                                  table)))
         (w4 (apply #'max (mapcar (lambda (cells) (length (nth 3 cells)))
                                  table)))
         (fmt (format "%%-%ds  %%-%ds  %%-%ds  %%-%ds  " w1 w2 w3 w4)))
    (mapcar (lambda (cell) (apply #'format fmt cell))
            table)))

(defun counsel-org-capture-string--template-list-transformer (str)
  "Add a suffix to denote the type of the CANDIDATE in STR."
  (let* ((name (car (split-string str)))
         (template (assoc name org-capture-templates))
         (body (nth 4 template)))
    (concat str
            (propertize (pcase body
                          ((pred stringp)
                           (string-join (split-string body "\n") "\\n"))
                          (`(file ,filename)
                           (format "(file %s)" filename))
                          (`(function ,function)
                           (if (symbolp function)
                               (format "(function %s)" function)
                             "(function lambda)")))
                        'face 'counsel-org-capture-string-template-body-face))))

(defun counsel-org-capture-string--select (string)
  "Capture something with STRING as an initial input."
  (require 'org-capture)
  (ivy-read (format "Capture template to pass \"%s\": " string)
            #'counsel-org-capture-string--template-list
            :require-match t
            :action (lambda (x)
                      (org-capture-string string (car (split-string x))))
            :caller 'counsel-org-capture-string--select))

(ivy-add-actions 'counsel-org-capture-string
                 '(("c" counsel-org-capture-string--select
                    "Select a template via Ivy")))

(ivy-configure 'counsel-org-capture-string--select
  :display-transformer-fn #'counsel-org-capture-string--template-list-transformer)

;;;; Example candidate functions

(defun counsel-org-capture-string--org-clock-candidates ()
  "Generate candidates from the current status of org-clock."
  (when (and (fboundp 'org-clocking-p)
             (org-clocking-p))
    `((,(with-current-buffer (marker-buffer org-clock-marker)
          (goto-char org-clock-marker)
          (substring-no-properties (org-get-heading t t)))
       . "current org clock task"))))

(defun counsel-org-capture-string--buffer-name-candidates ()
  "Generate candidates from the buffer name and possibly its file name."
  (cons `(,(buffer-name) . "buffer name")
        (when buffer-file-name
          `((,buffer-file-name . "buffer file")
            (,(file-name-nondirectory buffer-file-name) . "buffer file (w/o dir)")))))

(defun counsel-org-capture-string--projectile-candidates ()
  "Generate candidates related to the current projectile project."
  (when-let ((project (and (featurep 'projectile)
                           (bound-and-true-p projectile-cached-project-name))))
    `((,project . "projectile project name"))))

(defun counsel-org-capture-string--imenu-candidates ()
  "Generate candidates from imenu entries."
  (let ((items (condition-case nil
                   (imenu--make-index-alist t)
                 (error nil)))
        (bufname (if-let ((filename (buffer-file-name)))
                     (file-name-nondirectory filename)
                   (buffer-name)))
        result)
    (letrec ((imenu-flatten (lambda (alist)
                              (dolist (cell alist)
                                (if (imenu--subalist-p cell)
                                    (progn (push (cons (car cell) nil) result)
                                           (funcall imenu-flatten (cdr cell)))
                                  (push cell result))))))
      (funcall imenu-flatten (cdr (delete (assoc "*Rescan*" items) items))))
    (mapcar (lambda (cell)
              (cons (car cell)
                    (format "imenu: %s %s"
                            bufname
                            (if-let ((x (cdr cell))
                                     (marker (pcase x
                                               ((pred markerp) x)
                                               ((and `(,marker . ,_)
                                                     (guard (markerp marker)))
                                                marker))))
                                (format "(%d)" (marker-position marker))
                              ""))))
            (nreverse result))))

(provide 'counsel-org-capture-string)
;;; counsel-org-capture-string.el ends here
