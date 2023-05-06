;;; zk-luhmann.el --- Support for Luhmann-style IDs in zk  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Grant Rosson

;; Author: Grant Rosson <https://github.com/localauthor>
;; Created: January 25, 2022
;; License: GPL-3.0-or-later
;; Version: 0.3
;; Package-Version: 20230505.2107
;; Package-Commit: be0d6aa9fb856736406a43e3908fc4a01e073b99
;; Homepage: https://github.com/localauthor/zk-luhmann
;; Package-Requires: ((emacs "25.1")(zk "0.4")(zk-index "0.9"))

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

;; Adds support for files with Luhmann-style IDs in zk and zk-index.

;; Luhmann-style IDs are alphanumeric sequences that immediately follow the
;; zk-id in a note's filename. By default, the Luhmann-ID is surrounded by
;; parentheses, with each character in the ID delimited by a comma. A note
;; with such a Luhmann-ID will have a file name that looks something like:

;;       "202012101215 (1,1,a,3,c) The origin of species.md"

;; Because all files with Luhmann-IDs have normal zk-ids, they are normal
;; zk-files. As a result, the naming and ID scheme supported by this package
;; simply offers a different organizing scheme within a zk. It is both fully
;; integrated with zk while being, nevertheless, completely distinct --- a
;; system within a system.

;;; Code:

(require 'zk)
(require 'zk-index)

;;; Variables

(defgroup zk-luhmann nil
  "Luhmann-ID support of zk."
  :group 'text
  :group 'files
  :prefix "zk-luhmann")

(defcustom zk-luhmann-id-prefix "("
  "Character denoting the start of a Luhmann ID."
  :type 'string)

(defcustom zk-luhmann-id-postfix ")"
  "Character denoting the end of a Luhmann ID."
  :type 'string)

(defcustom zk-luhmann-id-delimiter ","
  "Character delimiting a Luhmann ID."
  :type 'string)

(defcustom zk-luhmann-indent-index t
  "Enable indented view in ZK-Index."
  :type 'boolean)

(defcustom zk-luhmann-count-format "- [%s]"
  "If non-nil, format for displaying number of subfiles in index.
Set to nil to disable display of count."
  :type 'string)

(defmacro zk-luhmann-id-regexp ()
  "Make regexp to match Luhmann-IDs.
Based on defcustoms `zk-luhmann-id-prefix', `zk-luhmann-id-postfix',
and `zk-luhmann-id-delimiter'."
  '(concat zk-luhmann-id-prefix
           "\\([0-9a-zA-Z"
           zk-luhmann-id-delimiter
           "]*\\)"
           zk-luhmann-id-postfix))


;;; Luhmann ID Support

;;;###autoload
(defun zk-luhmann ()
  "Find note with Luhmann-IDs."
  (interactive)
  (let* ((list (zk-luhmann-files))
         (file
          (completing-read
           "Select File: "
           (lambda (string predicate action)
             (if (eq action 'metadata)
                 `(metadata
                   (category . zk-file)
                   (group-function . zk-luhmann-group-function)
                   (display-sort-function . zk-luhmann-sort))
               (complete-with-action action list string predicate))))))
    (find-file file)))

(defun zk-luhmann-group-function (file transform)
  "TRANSFORM each FILE for `zk-luhmann'."
  (if transform
      (progn
        (string-match (concat "\\(?1:"
                              zk-id-regexp
                              "\\).\\(?2:.*?\\)\\."
                              zk-file-extension
                              ".*")
                      file)
        (match-string 2 file))
    "Luhmann Notes"))

(defun zk-luhmann-sort (list)
  "Sort LIST of `zk-luhmann' candidates or files."
  (sort list
        (lambda (a b)
          (let* ((a-list
                  (when (string-match (zk-luhmann-id-regexp) a)
                    (split-string (match-string 1 a)
                                  zk-luhmann-id-delimiter)))
                 (b-list
                  (when (string-match (zk-luhmann-id-regexp) b)
                    (split-string (match-string 1 b)
                                  zk-luhmann-id-delimiter)))
                 (count 0)
                 (exit)
                 (return))
            (while (and (not exit)
                        (nth count a-list)
                        (nth count b-list))
              (let* ((alpha (nth count a-list))
                     (beta (nth count b-list))
                     (one (if (string-match "\\`[-+]?[0-9]+\\'" alpha)
                              (string-to-number alpha)
                            alpha))
                     (two (if (string-match "\\`[-+]?[0-9]+\\'" beta)
                              (string-to-number beta)
                            beta)))
                (cond ((and (integerp one)
                            (integerp two)
                            (not (eq one two)))
                       (setq exit t)
                       (if (< one two)
                           (setq return t)
                         (setq return nil)))
                      ((and (stringp one)
                            (stringp two)
                            (not (string= one two)))
                       (setq exit t)
                       (if (string< one two)
                           (setq return t)
                         (setq return nil)))
                      ((and (integerp one)
                            (stringp two))
                       (setq exit t)
                       (setq return t))
                      ((and (stringp one)
                            (integerp two))
                       (setq exit t)
                       (setq return nil))
                      (t (setq count (+ 1 count))))))
            (cond ((not a-list)
                   nil)
                  ((not b-list)
                   t)
                  ((and (not (nth count a-list))
                        (nth count b-list))
                   t)
                  ((and (not (nth count b-list))
                        (nth count a-list))
                   nil)
                  (t return))))))

(defun zk-luhmann-completion-at-point ()
  "Completion at point function for notes with Luhmann-IDs."
  (let ((case-fold-search t)
        (origin (point)))
    (save-excursion
      (when (and (re-search-backward zk-luhmann-id-prefix nil t)
                 (save-excursion
                   (not (search-forward zk-luhmann-id-postfix
                                        origin
                                        t))))
        (let ((start (match-end 0))
              (candidates (zk-luhmann-format-candidates)))
          (list start
                origin
                (lambda (string predicate action)
                  (if (eq action 'metadata)
                      `(metadata
                        (display-sort-function . zk-luhmann-sort))
                    (complete-with-action action candidates string predicate)))
                :exit-function
                (lambda (str _status)
                  (delete-char (- -1 (length str)))
                  (insert str)
                  (when zk-enable-link-buttons
                    (zk-make-button-before-point)))))))))

(defun zk-luhmann-files ()
  "List notes with Luhmann-IDs."
  (zk--directory-files t (concat zk-id-regexp " " zk-luhmann-id-prefix)))

(defun zk-luhmann-format-candidates (&optional files)
  "Format completions candidates for FILES with Luhmann-IDs."
  (let ((files (or files
                   (zk-luhmann-files))))
    (zk--format-candidates files "%t [[%i]]")))

;;; Luhmann Index

(defun zk-luhmann--index (&rest args)
  "Wrapper around `zk-index' to implement `zk-luhmann-indent-index'.
Passes ARGS to `zk-index'."
  (if zk-luhmann-indent-index
      (let ((zk-index-prefix ""))
        (advice-add 'zk-index--insert :override #'zk-luhmann-index--insert)
        (apply #'zk-index args)
        (advice-remove 'zk-index--insert #'zk-luhmann-index--insert))
    (apply #'zk-index args)))

(defun zk-luhmann-index--insert (candidates)
  "Insert CANDIDATES into ZK-Index."
  (let (lid-index
        (zk-alist (zk--alist)))
    (dolist (file candidates)
      (set-match-data nil)
      (let* ((lid (progn
                    (string-match (zk-luhmann-id-regexp) file)
                    (or (match-string 0 file) "")))
             (drawer-count (if (and lid
                                    zk-luhmann-count-format
                                    (> 100 (length candidates)))
                               (format zk-luhmann-count-format (zk-luhmann--count zk-alist lid))
                             nil))
             (reg (concat "[^"
                          (regexp-quote zk-luhmann-id-delimiter)
                          "]"))
             (lid-length (* 2 (length (replace-regexp-in-string
                                       reg
                                       ""
                                       lid))))
             (spaces (progn
                       (unless lid-index
                         (setq lid-index lid-length))
                       (- lid-length lid-index)))
             (line (concat (make-string spaces ? )
                           file drawer-count "\n")))
        (insert line)))
    (zk-index--make-buttons)
    (zk-index--set-mode-name (format " [%s]" (length candidates)))))

;;;###autoload
(defun zk-luhmann-index ()
  "Open index for Luhmann-ID notes."
  (interactive)
  (let ((zk-luhmann-count-format nil)) ; for efficiency
    (when (eq major-mode 'zk-index-mode)
      (zk-index--reset-mode-line)
      (zk-index--reset-mode-name)
      (zk-luhmann--index (zk-luhmann-files) nil 'zk-luhmann-sort (buffer-name)))))

(defun zk-luhmann-index-sort ()
  "Sort index according to Luhmann-IDs."
  (interactive)
  (when (eq major-mode 'zk-index-mode)
    (let ((file-list (zk-index--current-file-list)))
      (when (listp file-list)
        (zk-index-refresh file-list
                          zk-index-last-format-function
                          #'zk-luhmann-sort
                          (buffer-name))))))

(defun zk-luhmann-index-top ()
  "Focus on top level Luhmann-ID notes."
  (interactive)
  (when (eq major-mode 'zk-index-mode)
    (zk-index--reset-mode-line)
    (zk-index--reset-mode-name)
    (let ((buffer-string (buffer-string)))
      (zk-luhmann--index (zk--directory-files
                          t
                          (concat zk-luhmann-id-prefix
                                  "[^"
                                  zk-luhmann-id-delimiter
                                  "]*"
                                  zk-luhmann-id-postfix))
	                 zk-index-last-format-function
	                 #'zk-luhmann-sort
                         (buffer-name))
      (when (string= buffer-string (buffer-string))
        (zk-luhmann-index)))))

(defun zk-luhmann-index-forward ()
  "Narrow focus to Luhmann notes below note at point."
  (interactive)
  (when (eq major-mode 'zk-index-mode)
    (zk-index--reset-mode-line)
    (zk-index--reset-mode-name)
    (let* ((buffer-string (buffer-string))
	   (regexp (concat zk-luhmann-id-prefix
                           ".[^"
                           zk-luhmann-id-postfix
                           "]*" ))
	   (line (buffer-substring
		  (line-beginning-position)
		  (line-end-position)))
	   (id (unless (string= "" line)
	         (unless (string-match regexp line)
                   (user-error "Not a Luhmann note"))
	         (match-string-no-properties 0 line)))
	   (str
	    (cond ((eq this-command 'zk-luhmann-index-forward)
		   (concat
                    id zk-luhmann-id-postfix "\\|"
                    id zk-luhmann-id-delimiter "..?" zk-luhmann-id-postfix))
		  ((eq this-command 'zk-luhmann-index-unfold)
                   (concat
                    id zk-luhmann-id-postfix "\\|"
                    id zk-luhmann-id-delimiter)))))
      (when id
        (progn
	  (zk-luhmann--index (zk--directory-files t str)
		             zk-index-last-format-function
		             #'zk-luhmann-sort
                             (buffer-name))
	  (goto-char (point-min))
	  (re-search-forward id nil t)
	  (beginning-of-line)))
      (cond ((and (eq this-command 'zk-luhmann-index-unfold)
		  (string= buffer-string (buffer-string)))
             (pulse-momentary-highlight-one-line nil 'highlight))
	    ((and (eq this-command 'zk-luhmann-index-forward)
		  (string= buffer-string (buffer-string)))
	     (progn
	       (setq this-command 'zk-luhmann-index-unfold)
	       (zk-luhmann-index-unfold)))))))

(defun zk-luhmann-index-back ()
  "Expand focus to Luhmann notes above note at point."
  (interactive)
  (when (eq major-mode 'zk-index-mode)
    (beginning-of-line)
    (unless (re-search-forward (zk-luhmann-id-regexp)
                               (line-end-position) t)
      (error "Not a Luhmann note"))
    (zk-index--reset-mode-line)
    (unless (eq zk-index-last-sort-function
                'zk-luhmann-sort)
      (zk-luhmann-index-sort))
    (let* ((buffer-string (buffer-string))
	   (backward-rx (concat zk-luhmann-id-prefix
                                ".*"
                                zk-luhmann-id-postfix))
	   (line (buffer-substring (goto-char (point-min))
				   (line-end-position)))
	   (id (progn
	         (string-match backward-rx line)
	         (match-string 0 line)))
	   (sub-id (string-trim-right id (concat zk-luhmann-id-delimiter
                                                 ".[^"
                                                 zk-luhmann-id-delimiter
                                                 "]*"
                                                 zk-luhmann-id-postfix))))
      (zk-index--reset-mode-name)
      (cond ((eq 2 (length id))
	     (zk-luhmann--index (zk--directory-files t id)
		                zk-index-last-format-function
		                #'zk-luhmann-sort
                                (buffer-name)))
	    (t (progn (zk-luhmann--index (zk--directory-files
                                          t
                                          (concat sub-id zk-luhmann-id-postfix
                                                  "\\|"
                                                  sub-id zk-luhmann-id-delimiter
                                                  "..?" zk-luhmann-id-postfix))
		                         zk-index-last-format-function
		                         #'zk-luhmann-sort
                                         (buffer-name))
                      (re-search-forward id nil t)
                      (beginning-of-line))))
      (when (string= buffer-string (buffer-string))
        (zk-luhmann-index-top)))))

(defun zk-luhmann-index-unfold ()
  "Expand focus to all Luhmann notes, with point on current note."
  (interactive)
  (when (eq major-mode 'zk-index-mode)
    (zk-luhmann-index-forward)
    (recenter-top-bottom)))

(defun zk-luhmann-index-level ()
  "Set number of sub-branch levels to view."
  (interactive)
  (when (eq major-mode 'zk-index-mode)
    (zk-index--reset-mode-line)
    (let* ((char (if (integerp last-command-event)
                     last-command-event
                   (get last-command-event 'ascii-character)))
           (reps (- (- (logand char ?\177) ?0) 1))
           (base-rx (concat zk-luhmann-id-prefix "[0-9]*"))
           (slug (concat zk-luhmann-id-delimiter "."))
           (new-slug "")
           (regexp
            (progn
              (when reps
                (dotimes (_ reps)
                  (setq new-slug (concat new-slug slug))))
              (concat base-rx new-slug zk-luhmann-id-postfix)))
           (current-files (zk--parse-id 'file-path (zk-index--current-id-list (buffer-name))))
           (files (remq nil
                        (mapcar
                         (lambda (x)
                           (when (member x (zk--directory-files t regexp))
                             x))
                         current-files))))
      (zk-index files
                zk-index-last-format-function
                #'zk-luhmann-sort
                (buffer-name)))))

;;;###autoload
(defun zk-luhmann-index-goto (&optional arg)
  "Open index to selected note.
For details of ARG, see `zk--processor'."
  (interactive (list (or (zk--id-at-point)
                         (zk-index--button-at-point-p)
                         (zk--select-file))))
  (let* ((zk-luhmann-count-format nil) ; for efficiency
         (file (car (zk--processor arg)))
         (id (zk--parse-file 'id file))
         (luhmann-files (zk-luhmann-files)))
    (if (member file luhmann-files)
        (progn
          (zk-luhmann--index luhmann-files
                             zk-index-last-format-function
                             #'zk-luhmann-sort
                             nil)
          (re-search-forward id nil t)
          (beginning-of-line)
          (zk-index--reset-mode-line)
          (zk-index))
      (user-error "Not a Luhmann note"))))
;; BUG: Doesn't highlight line when called from embark-act on zk-file;
;; seems to be waiting for input;
;; known issue in embark: https://github.com/oantolin/embark/issues/470

(defun zk-luhmann--count (zk-alist lid)
  "Return number of files under Luhmann ID LID.
Takes ZK-ALIST for efficiency when called in a loop."
  (if (string-empty-p lid) "0"
    (let ((count -1))
      (dolist (item zk-alist)
        (when (string-match (substring lid 0 -1) (cadr item))
          (setq count (1+ count))))
      count)))

(provide 'zk-luhmann)
;;; zk-luhmann.el ends here
