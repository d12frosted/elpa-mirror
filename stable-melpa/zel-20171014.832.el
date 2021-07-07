;;; zel.el --- Access frecent files easily  -*- lexical-binding: t; -*-

;; Copyright (C) 2017 Free Software Foundation, Inc.

;; Author: Sebastian Christ <rudolfo.christ@gmail.com>
;; URL: https://github.com/rudolfochrist/zel
;; Package-Version: 20171014.832
;; Package-Commit: 9dae2d212224d1deae1f62561fa8e4d689fd09f2
;; Version: 0.1.3-pre
;; Package-Requires: ((emacs "25") (frecency "0.1"))
;; Keywords: convenience, files, matching

;;; Commentary:

;; zel tracks the most used files, based on 'frecency'.  Zel is
;; basically a port of z[1] in Emacs Lisp.

;; The list of 'frecent' files underlies two concepts:

;; 1. The files are not only ranked on how recent they have been
;; visited, but also how frequent they have been visited.  A file that
;; has been visited multiple times last week gets a higher score as
;; file visited once yesterday.  Outliers should not compromise the
;; 'frecent' list.

;; 2. Entries in the 'frecent' list undergo aging.  If the age of a
;; entry falls under a threshold it gets removed from the 'frecent'
;; list.

;; [1] https://github.com/rupa/z

;;;; Installation

;;;;; MELPA

;; If you installed from MELPA, you're done.

;;;;; use-package

;; (use-package zel
;;   :ensure t
;;   :demand t
;;   :bind (("C-x C-r" . zel-find-file-frecent))
;;   :config (zel-install))

;;;;; Manual

;; Install these required packages:

;; - frecency

;; Then put this file in your load-path, and put this in your init
;; file:

;; (require 'zel)

;;;; Usage

;; 1. Run (zel-install)
;; 2. Bind `zel-find-file-frecent' to a key,
;;    e.g. (global-set-key (kbd "C-x C-r") #'zel-find-file-frecent)
;; 3. Visit some files to build up the database
;; 4. Profit.

;; As default the 'frecent' history is saved to `zel-history-file'.
;; Run 'M-x customize-group RET zel' for more customization options.

;; Besides `zel-find-file-frecent', that lets you select a file with
;; `completing-read' and switches to it, there is also the command
;; `zel-diplay-rankings' that shows all entries of the 'frecent' list
;; along with their score.

;; If you'd like to stop building up the 'frecent' list then run
;; `zel-uninstall' to deregister `zel' from all hooks.

;;;; Credits

;; - https://github.com/rupa/z
;; - https://github.com/alphapapa/frecency.el

;;; License

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

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'subr-x)
(require 'frecency)

;;;; Variables

(defgroup zel ()
  "Access frecent files easily."
  :group 'convenience
  :group 'files
  :group 'matching)


(defcustom zel-history-file (expand-file-name "zel-history" user-emacs-directory)
  "File where the history is saved."
  :type 'file)


(defcustom zel-exclude-patterns '(".*/\.#.*" "\.git/COMMIT_EDITMSG" "\.git/MERGE_MSG")
  "List of regexps to exclude files.

Each file-name that matches one of this patterns is not added to
the frecent list."
  :type '(repeat regexp))


(defvar zel--aging-threshold 9000
  "Threshold used to clean out old items.

When the sum of all entries reach this threshold older items are
removed.")


(defvar zel--aging-multiplier 0.99
  "Multiplier used on each item do determine the age of it.

If the age of an item after applying the multiplier is less than
1 it's determined to be too old and gets removed.")


(defvar zel--frecent-list nil
  "The list with the frecent items.")


(defvar zel--completing-read-history '()
  "History used for `completing-read'.")


(defvar zel--installed-p nil
  "Indicates if `zel' has been installed.")


;;;; Functions

(defun zel--file-excluded-p (filename)
  "Evaluate to t if the file with FILENAME should be excluded.

FILENAME has to be absolute."
  (cl-some (lambda (pattern)
             (string-match-p pattern filename))
           zel-exclude-patterns))

(defun zel--entry-score (entry)
  "Return score for ENTRY."
  (frecency-score (cadr entry)))


(defun zel--add-entry ()
  "Add a new entry to the frecent list."
  (zel--update-frecent-list t))


(defun zel--update-frecent-list (&optional create-entry-p)
  "Update the frecent list.

When CREATE-ENTRY-P is non-nil create new entries."
  ;; ignore buffers without file
  (when-let ((file-name (buffer-file-name)))
    (unless (zel--file-excluded-p file-name)
      (if-let ((entry (assoc file-name zel--frecent-list)))
          (setf (cadr entry)
                (frecency-update (cadr entry)))
        (when create-entry-p
          (push (list file-name (frecency-update '()))
                zel--frecent-list)))
      ;; sort frecent files
      (setq zel--frecent-list
            (cl-sort zel--frecent-list #'> :key #'zel--entry-score)))))


(defun zel--frecent-sum ()
  "Calculates the sum of items in the frecent list."
  (cl-reduce #'+ zel--frecent-list :key #'zel--entry-score))


(defun zel--cleanup-history ()
  "Remove too old items from history."
  (when (> (zel--frecent-sum) zel--aging-threshold)
    (setq zel--frecent-list
          (cl-sort (cl-remove-if (lambda (entry)
                                   (< (* (zel--entry-score entry) zel--aging-multiplier)
                                      1))
                                 zel--frecent-list)
                   #'>
                   :key #'zel--entry-score))))

;;;;; Public

(defun zel-frecent-file-paths ()
  "List frecent file paths in descending order by their rank."
  (mapcar #'car zel--frecent-list))


(defun zel-frecent-file-paths-with-score ()
  "List all frecent file paths with their scrore."
  (mapcar (lambda (entry)
            (cons (car entry)
                  (zel--entry-score entry)))
          zel--frecent-list))

;;;;; Commands

(cl-defmacro zel--with-history-buffer (&body body)
  (declare (indent defun))
  (let ((buffer (cl-gensym "buffer")))
    `(let ((,buffer (find-file-noselect (expand-file-name zel-history-file) t)))
       (with-current-buffer ,buffer
         ,@body))))


(defun zel-write-history ()
  "Writes the current frecent list to the `zel-history-file'."
  (interactive)
  (zel--cleanup-history)
  (zel--with-history-buffer
    (erase-buffer)
    (goto-char (point-min))
    (print zel--frecent-list (current-buffer))
    (save-buffer)))


(defun zel-load-history ()
  "Load the history file found under `zel-history-file'."
  (interactive)
  (zel--with-history-buffer
    (goto-char (point-min))
    (setq zel--frecent-list (read (current-buffer)))))



(defun zel-diplay-rankings ()
  "Show the current ranking of files."
  (interactive)
  (let ((items (zel-frecent-file-paths-with-score)))
    (with-output-to-temp-buffer "*zel-frecent-rankings*"
      (set-buffer "*zel-frecent-rankings*")
      (erase-buffer)
      (dolist (item items)
        (insert (format "\n% 4d -- %s"
                        (cdr item)
                        (car item)))))))


(defun zel-reset-frecent-list (&optional write-history-p)
  "Empties the frecent list.

If WRITE-HISTORY-P is non-nil (or `zel-reset-frecent-list' is
called with a prefix argument) the history files is saved as
well."
  (interactive "P")
  (setq zel--frecent-list nil)
  (when write-history-p
    (zel-write-history)))


(defun zel-find-file-frecent (file-name &optional open-directory-p)
  "Visit frecent file with FILE-NAME.

When OPEN-DIRECTORY-P is non-nil (or by calling it with a prefix
argument) the files directory will be opened i `dired'."
  (interactive
   (list (completing-read "Frecent: "
                          (zel-frecent-file-paths)
                          nil
                          t
                          zel--completing-read-history)
         current-prefix-arg))
  (if (file-exists-p file-name)
      (if open-directory-p
          (dired (file-name-directory file-name))
        (find-file file-name))
    (when (yes-or-no-p (format "File %s doesn't exist. Do you want to remove it from the list?" file-name))
      (setq zel--frecent-list
            (cl-remove file-name zel--frecent-list
                       :test #'string=
                       :key #'car)))))


;;;###autoload
(defun zel-install ()
  "Install `zel'.

Registers `zel' on the following hooks:

- `find-file-hook': to add new items to the frecent list .
- `focus-in-hook': updates this files score when revisiting its buffer.
- `kill-emacs-hook': write the frecent list to the `zel-history-file'."
  (interactive)
  (unless zel--installed-p
    (setq zel--installed-p t)
    (unless (file-exists-p (expand-file-name zel-history-file))
      (zel-write-history))
    (zel-load-history)
    (add-hook 'find-file-hook #'zel--add-entry)
    (add-hook 'focus-in-hook #'zel--update-frecent-list)
    (add-hook 'kill-emacs-hook #'zel-write-history)))


;;;###autoload
(defun zel-uninstall ()
  "Deregisters hooks."
  (interactive)
  (when zel--installed-p
    (setq zel--installed-p nil)
    (zel-write-history)
    (setq zel--frecent-list nil)
    (remove-hook 'find-file-hook #'zel--add-entry)
    (remove-hook 'focus-in-hook #'zel--update-frecent-list)
    (remove-hook 'kill-emacs-hook #'zel-write-history)))


(defun zel-version ()
  "Current installed version of `zel'."
  (interactive)
  (message "zel %s on %s"
           "0.1.3-pre"
           (emacs-version)))

;;;; Footer

(provide 'zel)

;;; zel.el ends here
