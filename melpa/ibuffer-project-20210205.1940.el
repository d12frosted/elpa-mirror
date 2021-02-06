;;; ibuffer-project.el --- Group ibuffer's list by project or any function -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2020 Andrii Kolomoiets

;; Author: Andrii Kolomoiets <andreyk.mad@gmail.com>
;; Keywords: tools
;; Package-Commit: 2483d2dbd715c4bd892d1fbc968a17a01888cb2d
;; URL: https://github.com/muffinmad/emacs-ibuffer-project
;; Package-Version: 20210205.1940
;; Package-X-Original-Version: 2.1
;; Package-Requires: ((emacs "25.1"))

;; This file is NOT part of GNU Emacs.

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This pacakage provides ibuffer filtering and sorting functions to group buffers
;; by function or regexp applied to `default-directory'.  By default buffers are
;; grouped by `project-current' or by `default-directory'.
;;
;; Buffer group and group type name is determined by function or regexp listed
;; in `ibuffer-project-root-functions'.  E.g. by adding `file-remote-p' like this:
;;
;;    (add-to-list 'ibuffer-project-root-functions '(file-remote-p . "Remote"))
;;
;; remote buffers will be grouped by protocol and host.
;;
;;
;; To group buffers set `ibuffer-filter-groups' to result of
;; `ibuffer-project-generate-filter-groups' function:
;;
;;    (add-hook 'ibuffer-hook
;;              (lambda ()
;;                (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups))))
;;
;; This package also provides column with filename relative to project.  If there are no
;; file in buffer then column will display `buffer-name' with `font-lock-comment-face' face.
;; Add project-file-relative to `ibuffer-formats':
;;
;;    (custom-set-variables
;;     '(ibuffer-formats
;;       '((mark modified read-only locked " "
;;               (name 18 18 :left :elide)
;;               " "
;;               (size 9 -1 :right)
;;               " "
;;               (mode 16 16 :left :elide)
;;               " " project-file-relative))))
;;
;; It's also possible to sort buffers by that column by calling `ibuffer-do-sort-by-project-file-relative'
;; or:
;;
;;    (add-hook 'ibuffer-hook
;;              (lambda ()
;;                (setq ibuffer-filter-groups (ibuffer-project-generate-filter-groups))
;;                (unless (eq ibuffer-sorting-mode 'project-file-relative)
;;                  (ibuffer-do-sort-by-project-file-relative))))
;;
;; To avoid calculating project root each time, one can set `ibuffer-project-use-cache'.
;; Root info per directory will be stored in the `ibuffer-project-roots-cache' variable.
;; Command `ibuffer-project-clear-cache' allows to clear project info cache.

;;; Code:

(require 'ibuffer)
(require 'ibuf-ext)
(require 'project)

(defgroup ibuffer-project nil
  "Group ibuffer entries by project."
  :group 'ibuffer)

(defcustom ibuffer-project-use-cache nil
  "If non-nil, cache project per directory.
To clear cache use `ibuffer-project-clear-cache' command."
  :type 'boolean)

(defvar ibuffer-project-roots-cache (make-hash-table :test 'equal)
  "Variable to store cache of project per directory.")

(defun ibuffer-project-clear-cache ()
  "Clear project data per directory cache."
  (interactive)
  (clrhash ibuffer-project-roots-cache))

(defun ibuffer-project-set-root-functions (s v)
  "Clear `ibuffer-project-roots-cache' and set S to V."
  (ibuffer-project-clear-cache)
  (set-default s v))

(defun ibuffer-project-project-root (dir)
  "Get project root in DIR."
  (let ((project (project-current nil dir)))
    (and project
         (if (functionp 'project-root)
             (project-root project)
           (car (project-roots project))))))

(defcustom ibuffer-project-root-functions '((ibuffer-project-project-root . "Project")
                                            (identity . "Directory"))
  "Functions to get root to group by.
Cons of each item can be:
- Function which will be called with abbreviated `default-directory' as only
  argument and must return project root or nil;
- Regexp whose `(match-string 1)' will be used as root.

Cell is the title of the group type.

After modifiyng this variable from Lisp code don't forget to call
`ibuffer-project-clear-cache' to clear `ibuffer-project-roots-cache' if you
use it."
  :type '(repeat (cons (choice (const :tag "Project" (lambda (dir) (cdr (project-current nil dir))))
                               (const :tag "Default directory" identity)
                               (function :tag "Function")
                               (regexp :tag "Regexp"))
                       string))
  :set #'ibuffer-project-set-root-functions)

(defun ibuffer-project--root (dir)
  "Run functions from `ibuffer-project-root-functions' for DIR."
  (catch 'match
    (dolist (entry ibuffer-project-root-functions)
      (let* ((f (car entry))
             (root (cond
                    ((functionp f) (funcall f dir))
                    ((stringp f) (when (string-match f dir)
                                   (match-string 1 dir))))))
        (when root
          (throw 'match (cons root (cdr entry))))))))

(defun ibuffer-project-root (buf)
  "Return a cons cell (project-root . root-type) for BUF."
  (unless (string-match-p "^ " (buffer-name buf))
    (let* ((dir (abbreviate-file-name (buffer-local-value 'default-directory buf))))
      (when dir
        (if ibuffer-project-use-cache
            (let ((cached (gethash dir ibuffer-project-roots-cache 'no-cached)))
              (if (eq cached 'no-cached)
                  (let ((root (ibuffer-project--root dir)))
                    (puthash dir root ibuffer-project-roots-cache)
                    root)
                cached))
          (ibuffer-project--root dir))))))

(defun ibuffer-project-group-name (root type)
  "Return group name for project ROOT and TYPE."
  (if (and (stringp type) (> (length type) 0))
      (format "%s: %s" type root)
    (format "%s" root)))

(define-ibuffer-filter project-root
    "Toggle current view to buffers with project root dir QUALIFIER."
  (:description "project root dir"
                :reader (read-regexp "Filter by project root dir (regexp): "))
  (ibuffer-awhen (ibuffer-project-root buf)
    (if (stringp qualifier)
        (string-match-p qualifier (car it))
      (equal qualifier it))))

;;;###autoload (autoload 'ibuffer-do-sort-by-project-file-relative "ibuffer-project")
(define-ibuffer-sorter project-file-relative
  "Sort by filename relative to project"
  (:description "project filename relative")
  (let* ((bufa (car a))
         (bufb (car b))
         (projecta (car (ibuffer-project-root bufa)))
         (projectb (car (ibuffer-project-root bufb))))
    (if (equal projecta projectb)
        (let ((filea (buffer-local-value 'buffer-file-name bufa))
              (fileb (buffer-local-value 'buffer-file-name bufb)))
          (cond
           ((and filea fileb) (string-lessp filea fileb))
           ((or filea fileb) (null fileb))
           (t (let* ((namea (buffer-name bufa))
                     (nameb (buffer-name bufb))
                     (asteriska (string-match-p "^*" namea))
                     (asteriskb (string-match-p "^*" nameb)))
                ;; This is xor :) Just to not autoload xor from
                ;; "array" on Emacs pre 27 where xor is added to subr.el
                (if (if asteriska (not asteriskb) asteriskb)
                    (null asteriska)
                  (string-lessp namea nameb))))))
      (string-lessp projecta projectb))))

(defvar ibuffer-project-file-relative-header-map
  (let ((map (make-sparse-keymap)))
    (define-key map [(mouse-1)] 'ibuffer-do-sort-by-project-file-relative)
    map)
  "Mouse keymap for filename relative to project column.")

;;;###autoload (autoload 'ibuffer-make-column-project-file-relative "ibuffer-project")
(define-ibuffer-column project-file-relative
  (:name "Filename"
         :header-mouse-map ibuffer-project-file-relative-header-map)
  (if buffer-file-name
      (let ((root (car (ibuffer-project-root buffer))))
        (if root
            (file-relative-name buffer-file-name root)
          (abbreviate-file-name buffer-file-name)))
    (propertize (buffer-name) 'font-lock-face 'font-lock-comment-face)))

;;;###autoload
(defun ibuffer-project-generate-filter-groups ()
  "Create ibuffer filters based on project root of buffers."
  (let ((roots (sort (ibuffer-remove-duplicates
                      (delq nil (mapcar 'ibuffer-project-root (buffer-list))))
                     (lambda (a b) (string-lessp (car a) (car b))))))
    (mapcar (lambda (root)
              (cons (ibuffer-project-group-name (car root) (cdr root))
                    `((project-root . ,root))))
            roots)))

(provide 'ibuffer-project)
;;; ibuffer-project.el ends here
