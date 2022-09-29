;;; github-linguist.el --- Run GitHub Linguist on projects to collect information -*- lexical-binding: t -*-

;; Copyright (C) 2022 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.1.2
;; Package-Version: 20220928.2013
;; Package-Commit: 73f9f52e1f626e866d8becc7a3671630449764c2
;; Package-Requires: ((emacs "27.1") (project "0.8") (async "1.9") (map "3"))
;; Keywords: processes
;; URL: https://github.com/akirak/github-linguist.el

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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; GitHub

;; You can update information on projects from `project-known-project-roots'
;; using `github-linguist-update-projects'. You can call the function
;; periodically using `run-with-idle-timer' or run it interactively.

;; Then you can use `github-linguist-lookup' to retrieve information on a
;; project. It would be possible to use it inside an annotation function for
;; completion, but it is not part of this package yet.

;;; Code:

(require 'map)
(require 'cl-lib)
(require 'subr-x)
(require 'project)
(require 'async)

(defgroup github-linguist nil
  "Analyse projects using GitHub Linguist."
  :group 'project)

(defconst github-linguist-error-buffer "*github-linguist errors*")

(defconst github-linguist-git-dir ".git"
  "Name of the git directory.")

(defcustom github-linguist-git-executable "git"
  "Executable of Git."
  :type 'file)

(defcustom github-linguist-executable "linguist"
  "Executable of the GitHub Linguist."
  :type 'file)

(defcustom github-linguist-file (locate-user-emacs-file "github-linguist")
  "File in which to save the data of projects.

When you set this variable to nil, the result won't be saved."
  :type '(choice (const :tag "Don't save" nil)
                 file))

(defcustom github-linguist-update nil
  "Whether to force updating of existing entries."
  :type 'boolean)

(defvar github-linguist-results nil)

;;;; File operations

(defun github-linguist--load ()
  "Load the data from the file."
  (when (and github-linguist-file
             (file-readable-p github-linguist-file))
    (with-temp-buffer
      (insert-file-contents github-linguist-file)
      (goto-char (point-min))
      (map-into (read (current-buffer))
                '(hash-table :test equal)))))

(defun github-linguist--save (&optional silent)
  "Write the data to the file."
  (when github-linguist-file
    (with-temp-buffer
      (setq buffer-file-name github-linguist-file)
      (let ((print-length nil)
            (print-level nil)
            (print-symbols-bare t))
        (prin1 (map-into github-linguist-results 'alist)
               (current-buffer)))
      ;; TODO: There may be a better way to write to a file
      (let ((inhibit-message silent))
        (save-buffer)))))

;;;; Table operations

(defun github-linguist--normalize (directory)
  "Normalize the path to DIRECTORY."
  (file-name-as-directory (if (file-remote-p directory)
                              directory
                            (file-truename directory))))

(defun github-linguist--ensure-table ()
  "Initialize the hash table."
  (unless github-linguist-results
    (setq github-linguist-results (or (github-linguist--load)
                                      (make-hash-table :test #'equal)))))

(defun github-linguist--lookup (directory)
  "Return the statistics on DIRECTORY, if any."
  (github-linguist--ensure-table)
  (gethash (github-linguist--normalize directory)
           github-linguist-results))

;;;###autoload (autoload 'github-linguist-lookup "github-linguist")
(defalias 'github-linguist-lookup #'github-linguist--lookup)

(defun github-linguist--update (directory result)
  "Update the statistics on DIRECTORY to RESULT."
  (unless github-linguist-results
    (github-linguist--ensure-table))
  (puthash (github-linguist--normalize directory)
           result
           github-linguist-results)
  result)

;;;; Process interactions

;;;###autoload
(defun github-linguist-update-projects (&optional arg)
  "Update linguist information on the known projects.

If ARG is non-nil, existing projects are updated as well."
  (interactive "P")
  (if-let (projects (thread-last
                      (if (not (or arg github-linguist-update))
                          (cl-remove-if #'github-linguist--lookup
                                        (project-known-project-roots))
                        (project-known-project-roots))
                      (cl-remove-if #'file-remote-p)
                      (cl-remove-if-not #'github-linguist--git-head-p)
                      (github-linguist--unique-directories)))
      (github-linguist--run-many projects)
    (message "No project to update")))

(defun github-linguist--unique-directories (directories)
  "Remove duplicates in DIRECTORIES."
  ;; A thorough solution would be to remove duplicates according to
  ;; `file-truename'. However, it would make the problem complex, as there would
  ;; be missing entries (of different paths pointing to the same real location)
  ;; in the result.
  (cl-remove-duplicates directories :test #'equal))

(defun github-linguist--git-head-p (root)
  "Return non-nil if ROOT contains a git directory."
  (let ((git-dir (expand-file-name github-linguist-git-dir root)))
    (and (file-directory-p git-dir)
         (zerop (call-process github-linguist-git-executable
                              nil nil nil
                              (concat "--work-tree=" (expand-file-name root))
                              (concat "--git-dir=" git-dir)
                              "rev-parse" "HEAD")))))

(defvar github-linguist-library (or load-file-name (buffer-file-name))
  "Path to this library.")

(defvar github-linguist-start-time nil)

(defun github-linguist--run-many (directories)
  "Run linguist on many DIRECTORIES and update the cache."
  (message "Started scanning %d linguist projects..." (length directories))
  (setq github-linguist-start-time (float-time))
  (async-start
   `(lambda ()
      (load ,github-linguist-library nil t)
      (let ((queue ',directories)
            (error-file (make-temp-file "emacs-gh-linguist-errors" nil ".txt"))
            (error-buffer (generate-new-buffer "*github-linguist errors*"))
            (num-success 0)
            process-errors
            parse-errors
            directory)
        (unwind-protect
            (while (setq directory (pop queue))
              (let ((args (list (thread-last
                                  (expand-file-name directory)
                                  (string-remove-suffix "/")
                                  (convert-standard-filename))
                                "--json")))
                (with-temp-buffer
                  (if (zerop (apply #'call-process
                                    ,github-linguist-executable
                                    nil
                                    (list (current-buffer) error-file)
                                    nil
                                    args))
                      (condition-case nil
                          (progn
                            (thread-last (github-linguist--parse-buffer)
                                         (github-linguist--update directory))
                            (cl-incf num-success))
                        (error (push directory parse-errors)))
                    (with-current-buffer error-buffer
                      (insert (format "[%s] Error while running (%s):\n"
                                      (format-time-string "%F %R")
                                      (cons github-linguist-executable args)))
                      (insert-file-contents error-file))
                    (push directory process-errors)))))
          (delete-file error-file))
        (list github-linguist-results
              :success num-success
              :error-string (when process-errors
                              (with-current-buffer error-buffer
                                (buffer-string)))
              :parse-errors parse-errors)))
   (pcase-lambda (`(,hashtable . ,plist))
     (github-linguist--ensure-table)
     (map-do (lambda (key value)
               (puthash key value github-linguist-results))
             hashtable)
     (github-linguist--save)
     (let* ((has-error (with-current-buffer (get-buffer-create github-linguist-error-buffer)
                         (insert (or (plist-get plist :error-string) ""))
                         (not (zerop (buffer-size)))))
            (parse-errors (plist-get plist :parse-errors)))
       (when parse-errors
         (error "Failed to parse output of GitHub Linguist on some projects"))
       (message "Updated %d linguist projects (in %.1f sec%s)"
                (plist-get plist :success)
                (- (float-time) github-linguist-start-time)
                (if has-error
                    (format ", see %s on errors" github-linguist-error-buffer)
                  "")))
     (setq github-linguist-start-time nil))))

;;;###autoload
(defun github-linguist-run (directory &optional callback)
  "Run linguist on a project DIRECTORY with an optional CALLBACK.

When called interactively, this function prints statistics on the
current project."
  (interactive (list (locate-dominating-file default-directory
                                             github-linguist-git-dir)
                     #'princ))
  (let ((name (file-name-base (string-remove-suffix "/" directory))))
    (async-start-process (format "linguist-%s" name)
                         github-linguist-executable
                         (apply-partially #'github-linguist--handle-finish
                                          directory
                                          callback)
                         (thread-last
                           (expand-file-name directory)
                           (string-remove-suffix "/")
                           (convert-standard-filename))
                         "--json")))

(defun github-linguist--parse-buffer ()
  "Parse the output of Linguist and return its transformed result."
  (goto-char (point-min))
  (thread-last (json-parse-buffer :object-type 'alist)
               (mapcar (pcase-lambda (`(,language . ,statistics))
                         (cons (symbol-name language)
                               (read (cdr (assq 'percentage statistics))))))
               (seq-sort-by #'cdr #'>)))

(defun github-linguist--handle-finish (directory callback process)
  "Register the result of linguist.

This function saves the result of Linguist on DIRECTORY.

If CALLBACK is a function, it also pass the result to the function.

PROCESS is a process object. See `async-start-process' for details."
  (let ((exit (process-exit-status process))
        (buffer (process-buffer process)))
    (if (zerop exit)
        (with-current-buffer buffer
          (prog1 (thread-last
                   (github-linguist--parse-buffer)
                   (github-linguist--update directory)
                   (funcall (or callback #'identity)))
            (github-linguist--save 'silent)))
      (message "GitHub Linguist failed on %s" directory))))

(provide 'github-linguist)
;;; github-linguist.el ends here
