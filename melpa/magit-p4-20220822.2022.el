;;; magit-p4.el --- git-p4 plug-in for Magit

;; Copyright (C) 2014 Damian T. Dobroczyński
;;
;; Author: Damian T. Dobroczyński <qoocku@gmail.com>
;; Maintainer: Aleksey Fedotov <lexa@cfotr.com>
;; Package-Requires: ((emacs "25.1") (magit "2.1") (magit-popup "2.1") (p4 "12.0") (cl-lib "0.5"))
;; Package-Version: 20220822.2022
;; Package-Commit: 0fd0f882eb14510714393c15c2ccb8d2c259f01e
;; Keywords: vc tools
;; URL: https://github.com/qoocku/magit-p4
;; Package: magit-p4

;; Magit-p4 is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; Magit-p4 is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Magit-p4.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This plug-in provides git-p4 functionality as a separate component
;; of Magit.

;;; Code:

(require 'magit)

(eval-when-compile
  (require 'cl-lib)
  (require 'find-lisp)
  (require 'p4)
  (require 'subr-x))

(declare-function find-lisp-find-files-internal 'find-lisp)

;;; Options

(defgroup magit-p4 nil
  "Git-p4 support for Magit."
  :group 'magit-extensions)

;;; Commands

;;;###autoload
(defun magit-p4-clone (depot-path &optional target-dir)
  "Clone given DEPOT-PATH.

The first argument is P4 depot path to clone.  The TARGET-DIR
argument is directory which will hold the Git repository."
  (interactive
   (append (list (p4-read-arg-string "Depot path: " "//" 'filespec))
           (if (and (not (cl-some (lambda (arg)
                                    (string-match-p "--destination=" arg))
                                  (magit-p4-clone-arguments)))
                    current-prefix-arg)
             (read-directory-name "Target directory: ")
             nil)))
  (magit-run-git-async "p4" "clone"
                       (cons depot-path (magit-p4-clone-arguments))))


;;;###autoload
(defun magit-p4-sync (&optional depot-path)
  "Synchronize with default and/or given DEPOT-PATH.

The optional argument is P4 depot path which will be synchronized
with.  If not present, git-p4 will try to synchronize with default
depot path which has been cloned to before."
  (interactive
   (when current-prefix-arg
     (list (p4-read-arg-string "With (another) depot path: " "//" 'filespec))))
  (magit-run-git-async "p4" "sync"
                       (cond (depot-path
                              (cons depot-path (magit-p4-sync-arguments)))
                             (t (magit-p4-sync-arguments)))))

;;;###autoload
(defun magit-p4-rebase ()
  "Run git-p4 rebase."
  (interactive)
  (magit-run-git-async "p4" "rebase"))

;;;###autoload
(defun magit-p4-submit ()
  "Run git-p4 submit."
  (interactive)
  (magit-p4-run-git-with-editor "p4" "submit" (magit-p4-submit-arguments)))

(defcustom magit-p4-process-yes-or-no-prompt-regexp
  "\\[\\(y\\)\\]es, \\[\\(n\\)\\]o"
  "Regexp matching yes-or-no prompt for git-p4."
  :group 'magit-p4
  :type 'regexp)

(defun magit-p4-process-yes-or-no-prompt (process string)
  (let ((max-mini-window-height 30)
        (beg (string-match magit-p4-process-yes-or-no-prompt-regexp string)))
    (when beg
      (process-send-string
       process
       (downcase
        (concat
         (match-string
          (if (save-match-data
                (magit-process-kill-on-abort process
                  (yes-or-no-p (substring string 0 beg)))) 1 2)
          string)
         "\n"))))))

(defcustom magit-p4-process-skip-or-quit-regexps
  '("\\[s\\]kip this commit but apply the rest, or \\[q\\]uit")
  "List of regexp matching skip-or-quit prompts from git-p4."
  :group 'magit-p4
  :type '(repeat (regexp)))

(defun magit-p4-process-skip-or-quit (process string)
  (when-let ((prompt (magit-process-match-prompt
                      magit-p4-process-skip-or-quit-regexps
                      string)))
    (process-send-string
     process
     (concat
      (substring
       (magit-process-kill-on-abort process
         (magit-completing-read prompt '("skip" "quit") nil t))
       0 1)
      "\n"))))

(defun magit-p4-process-filter (process string)
  "Filter used by `magit-p4-run-git-with-editor'."
  (with-current-buffer (process-buffer process)
    (magit-p4-process-yes-or-no-prompt process string)
    (magit-p4-process-skip-or-quit process string)))

;;;###autoload
(defun magit-p4-run-git-with-editor (&rest args)
  "Run git with P4EDITOR set and `magit-p4-process-filter'.
This is similar to `magit-run-git-with-editor', but also export
P4EDITOR and use custom process filter `magit-p4-process-filter'."
  (let* ((process (with-editor "P4EDITOR"
                   (apply #'magit-run-git-with-editor args)))
         (old-filter (process-filter process)))
    (set-process-filter
     process
     `(lambda (process str)
        (magit-p4-process-filter process str)
        (funcall ,old-filter process str)))
    process))

;; Menu
(easy-menu-define magit-p4-extension-menu
  nil
  "Git P4 extension menu"
  '("Git P4"
    :visible magit-p4-mode
    ["Clone" magit-p4-clone t]
    ["Sync" magit-p4-sync t]
    ["Rebase" magit-p4-rebase t]
    ["Submit" magit-p4-submit t]))

(easy-menu-add-item 'magit-mode-menu
                    '("Extensions")
                    magit-p4-extension-menu)

;;; Keymaps

;;;###autoload (autoload 'magit-p4-popup "magit-p4" nil t)
(magit-define-popup magit-p4-popup
  "Show popup buffer featuring git p4 commands."
  'magit-commands
  :man-page "git-p4"
  :actions '((?c "Clone" magit-p4-clone-popup)
             (?s "Sync" magit-p4-sync-popup)
             (?r "Rebase" magit-p4-rebase)
             (?S "Submit" magit-p4-submit-popup)))

(defvar magit-p4-sync-clone-shared-options
  '((?b "Branch" "--branch=")
    (?c "Changes files" "--changesfile=" read-file-name)
    (?m "Limit the number of imported changes" "--max-changes=")
    (?s "Internal block size to use when iteratively calling p4 changes"
        "--changes-block-size=")
    (?/ "Exclude depot path" "-/")))

(defvar magit-p4-sync-clone-shared-switches
  '((?d "Detect branches" "--detect-branches")
    (?l "Query p4 for labels" "--detect-labels")
    (?b "Import labels" "--import-labels")
    (?i "Import into refs/heads/ , not refs/remotes" "--import-local")
    (?p "Keep entire BRANCH/DIR/SUBDIR prefix during import" "--keep-path")
    (?s "Only sync files that are included in the p4 Client Spec"
        "--use-client-spec")))

(magit-define-popup magit-p4-sync-popup
  "Pull changes from p4"
  'magit-commands
  :options magit-p4-sync-clone-shared-options
  :switches magit-p4-sync-clone-shared-switches
  :actions '((?s "Sync" magit-p4-sync)))

(magit-define-popup magit-p4-submit-popup
  "Submit changes from git to p4"
  :switches '((?M "Detect renames" "-M")
              (?v "Be more verbose" "--verbose")
              (?u "Preserve user" "--preserve-user")
              (?l "Export labels" "--export-labels")
              (?n "Dry run" "--dry-run")
              (?p "Prepare P4 only" "--prepare-p4-only"))
  :options '((?o "Origin" "--origin=" magit-read-branch-or-commit)
             (?b "Sync with branch after submission"
                 "--branch=" magit-read-branch)
             (?N "Name of git branch to submit"
                 " " magit-read-branch-or-commit)
             (?c "Conflict resolution (ask|skip|quit)" "--conflict="
                 (lambda (prompt &optional default)
                   (magit-completing-read prompt '("ask" "skip" "quit")
                                          nil nil nil nil default))))
  :actions '((?s "Submit all" magit-p4-submit)))

(magit-define-popup magit-p4-clone-popup
  "Clone repository from p4"
  :switches (append '((?b "Bare clone" "--bare"))
                      magit-p4-sync-clone-shared-switches)
  :options (append '((?d "Destination directory"
                         "--destination=" read-directory-name))
                   magit-p4-sync-clone-shared-options)
  :actions '((?c "Clone" magit-p4-clone)))

(magit-define-popup-action 'magit-dispatch-popup ?4 "Git P4" 'magit-p4-popup ?!)

(defun magit-p4/insert-job (&optional job)
  "Insert JOB reference in a buffer.

The insertion assumes that it should be 'Jobs:' entry in the
buffer.  If not - it inserts such at the current point of the
buffer.  Then it asks (if applied interactively) for a job id
using `p4` completion function.  Finally it inserts the id under
`Jobs:' entry."
  (interactive
   (list (p4-read-arg-string "Job: " "" 'job)))
  (when job
    (let ((jobs-entry (or (save-excursion
                            (re-search-backward "^Jobs:" nil t))
                          (re-search-forward "^Jobs:" nil t))))
      (if (not jobs-entry)
          ;; it inserts "Jobs:" entry in the CURRENT point!
          (insert "\nJobs:\n\t")
        ;; move to past the end of `Jobs:` entry
        (progn
          (goto-char jobs-entry)
          (end-of-line)
          (insert "\n\t")))
      (insert job))))

(defvar magit-p4-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x j") 'magit-p4/insert-job)
    map)
  "Minor P4 mode key map.
So far used in submit log edit buffer.")

;;; Mode

;;;###autoload
(define-minor-mode magit-p4-mode
  "P4 support for Magit."
  :lighter " P4"
  :require 'magit-p4
  :keymap 'magit-p4-mode-map
  (unless (derived-mode-p 'magit-mode)
    (user-error "This mode only makes sense with magit"))
  (when (called-interactively-p 'any)
    (magit-refresh)))

(provide 'magit-p4)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; magit-p4.el ends here
