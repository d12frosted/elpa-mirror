;;; dired-git.el --- Git integration for dired  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 0.0.1
;; Keywords: tools
;; Package-Requires: ((emacs "26.1") (async-await "1.0") (async "1.9.4") (all-the-icons "2.2.0") (ppp "1.0.0"))
;; URL: https://github.com/conao3/dired-git.el

;; This program is free software: you can redistribute it and/or modify
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

;; Git integration for dired.

;; To use this package, simply add this to your init.el:
;;   (add-hook 'dired-mode-hook 'dired-git-mode)


;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'subr-x)
(require 'dired)
(require 'async-await)
(require 'all-the-icons)
(require 'ppp)

(defgroup dired-git nil
  "Git integration for dired."
  :prefix "dired-git-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/dired-git.el"))

(defcustom dired-git-disable-dirs '("~/")
  "List of directory that disables `dired-git' even if it is enabled."
  :group 'dired-git
  :type 'sexp)

(defcustom dired-git-parallel 4
  "Number of parallel processes."
  :group 'dired-git
  :type 'integer)

(defface dired-git-branch-master
  '((t (:foreground "SpringGreen" :weight bold)))
  "Face of showing branch master.")

(defface dired-git-branch-else
  '((t (:foreground "cyan" :weight bold)))
  "Face of showing branch else.")


;;; Manage Overlays

(defun dired-git--add-overlay (pos string)
  "Add overlay to display STRING at POS."
  (let ((ov (make-overlay (1- pos) pos)))
    (overlay-put ov 'dired-git-overlay t)
    (overlay-put ov 'after-string string)))

(defun dired-git--overlays-in (beg end)
  "Get all dired-git overlays between BEG to END."
  (cl-remove-if-not
   (lambda (ov)
     (overlay-get ov 'dired-git-overlay))
   (overlays-in beg end)))

(defun dired-git--overlays-at (pos)
  "Get dired-git overlays at POS."
  (apply #'dired-git--overlays-in `(,pos ,pos)))

(defun dired-git--remove-all-overlays ()
  "Remove all `dired-git' overlays."
  (save-restriction
    (widen)
    (mapc #'delete-overlay (dired-git--overlays-in (point-min) (point-max)))))


;;; Function

(defvar dired-git-mode)

(defvar dired-git-width-header "**dired-git/width**"
  "String used as key to save width meta information.
Must contain a slash(/).  This ensures that it does not conflict
with file names.  Because slashes are never included in file names.")

(defvar-local dired-git-working nil
  "If non-nil, now working dired-git process.")

(defvar-local dired-git-hashtable nil
  "Hashtable stored git information.
Key is file absolute path, value is alist of information.")

(defun dired-git--create-overlay-string (table file &optional width)
  "Create overlay string from data for FILE from TABLE.
WIDTH stored maxlength to align column."
  (let* ((data (gethash file table))
         (width* (or width (gethash dired-git-width-header table)))
         (w-branch  (alist-get 'branch width*))
         (w-forward (alist-get 'forward width*))
         (w-behind  (alist-get 'behind width*)))
    (if (not data)
        (concat
         ;; all-the-icons width equals 2 spaces
         (format (format "%%s %%-%ds\t" w-branch) "  " "")
         (format (format "%%s\t%%%ds\t" w-forward) "  " "")
         (format (format "%%s\t%%%ds\t" w-behind) "  " ""))
      (let-alist data
        ;; branch, remote, ff, forward, behind
        (concat
         (format (format "%%s %%-%ds\t" w-branch)
                 (all-the-icons-octicon "git-branch")
                 (propertize .branch
                             'face (if (string= "master" .branch)
                                       'dired-git-branch-master
                                     'dired-git-branch-else)))
         (format (format "%%s\t%%-%ds\t" w-forward)
                 (pcase .forward
                   ("0" "  ")
                   ("-" (all-the-icons-octicon "stop" :v-adjust 0.0 :height 0.9))
                   (_   (all-the-icons-octicon "diff-added" :v-adjust 0.0 :height 0.8)))
                 (pcase .forward
                   ("0" "")
                   ("-" "-")
                   (_   .forward)))
         (format (format "%%s\t%%-%ds\t" w-behind)
                 (pcase .behind
                   ("0" "  ")
                   ("-" (all-the-icons-octicon "stop" :v-adjust 0.0 :height 0.9))
                   (_   (all-the-icons-octicon "diff-removed" :v-adjust 0.0 :height 0.8)))
                 (pcase .behind
                   ("0" "")
                   ("-" "-")
                   (_   .behind))))))))

(defun dired-git--promise-git-info (buf)
  "Return promise to get branch name for dired BUF."
  (promise-then
   (let ((default-directory (with-current-buffer buf
                              dired-directory)))
     (promise:make-process
      (list
       shell-file-name
       shell-command-switch
       "find . -mindepth 1 -maxdepth 1 -type d | sort | tr \\\\n \\\\0 | \
xargs -0 -I^ sh -c \"
cd '^'
git rev-parse --is-inside-work-dir >/dev/null 2>&1 || exit 0
if [ \\\"true\\\" = \\\"\\$(git rev-parse --is-inside-git-dir)\\\" ]; then exit 0; fi
if [ \\\"\\$PWD\\\" != \\\"\\$(git rev-parse --show-toplevel)\\\" ]; then exit 0; fi
branch=\\\"\\$(git symbolic-ref --short HEAD)\\\"
remote=\\\"\\$(git config --get branch.\\${branch}.remote)\\\"

git rev-parse \\${remote}/\\${branch} >/dev/null 2>&1
if [ 0 -ne \\$? ]; then
  forward=\\\"-\\\"
  behind=\\\"-\\\"
else
  forward=\\\"\\$(git log \\${remote}/\\${branch}..\\${branch} --oneline | wc -l)\\\"
  behind=\\\"\\$(git log \\${branch}..\\${remote}/\\${branch} --oneline | wc -l)\\\"
fi

echo \\\"(\
 file \\\\\\\"\\$PWD\\\\\\\"\
 branch \\\\\\\"\\${branch}\\\\\\\"\
 remote \\\\\\\"\\${remote}\\\\\\\"\
 forward \\\\\\\"\\${forward}\\\\\\\"\
 behind \\\\\\\"\\${behind}\\\\\\\"\
)\\\"
\"
")))
   (lambda (res)
     (seq-let (stdout stderr) res
       (if (not (string-empty-p stderr))
           (promise-reject `(fail-git-info-invalid-output ,stdout ,stderr))
         (promise-resolve stdout))))
   (lambda (reason)
     (promise-reject `(fail-git-info-command ,reason)))))

(defun dired-git--promise-create-hash-table (_buf stdout)
  "Return promise to create hash table from STDOUT.
STDOUT is return value form `dired-git--promise-git-info'."
  (promise-then
   (promise:async-start
    `(lambda ()
       (require 'subr-x)
       (let ((stdout (read (format "(%s)" ,stdout)))
             (table (make-hash-table :test 'equal))
             width-alist)
         (dolist (elm stdout)
           (puthash (plist-get elm 'file)
                    `((branch  . ,(plist-get elm 'branch))
                      (remote  . ,(plist-get elm 'remote))
                      (forward . ,(plist-get elm 'forward))
                      (behind  . ,(plist-get elm 'behind)))
                    table)
           (dolist (key '(branch remote forward behind))
             (when-let ((width (string-width (plist-get elm key))))
               (when (< (or (alist-get key width-alist) 0) width)
                 (setf (alist-get key width-alist) width)))))
         (puthash ,dired-git-width-header width-alist table)
         (prin1-to-string table))))
   (lambda (res)
     (promise-resolve (read res)))
   (lambda (reason)
     (promise-reject `(fail-create-hash-table ,stdout ,reason)))))

(defun dired-git--promise-add-annotation (buf table)
  "Add git annotation for BUF.
TABLE is hash table returned value by `dired-git--promise-git-info'."
  (promise-new
   (lambda (resolve reject)
     (condition-case err
         (with-current-buffer buf
           (when-let* ((width (gethash dired-git-width-header table)))
             (save-excursion
               (goto-char (point-min))
               (while (not (eobp))
                 (when-let ((file (dired-get-filename nil 'noerror)))
                   (dired-git--add-overlay
                    (point)
                    (dired-git--create-overlay-string table file width)))
                 (dired-next-line 1))
               (funcall resolve t))))
       (error
        (funcall reject `(fail-add-annotation ,table ,err)))))))


;;; Interactive functions

(async-defun dired-git-refresh (&optional buf cachep)
  "Refresh git overlays for BUF or `current-buffer'.
IF CACHEP is non-nil and cache is avairable, use it and omit invoke shell commands"
  (interactive (list (prog1 (current-buffer)
                       (setq-local dired-git-working nil))))
  (let* ((buf* (or buf (current-buffer)))
         (cachep* (and cachep
                       (with-current-buffer buf* dired-git-hashtable)))
         stdout hash ov)
    (condition-case err
        (when (with-current-buffer buf*
                (and dired-git-mode
                     (not dired-git-working)
                     (not (member
                           (expand-file-name dired-directory)
                           (mapcar 'expand-file-name dired-git-disable-dirs)))))
          (with-current-buffer buf*
            (setq-local tab-width 1)
            (setq-local dired-git-working t)
            (if cachep*
                (setq hash dired-git-hashtable)
              (setq-local dired-git-hashtable nil))
            (dired-git--remove-all-overlays))
          (unless cachep*
            (setq stdout (await (dired-git--promise-git-info buf*)))
            (setq hash   (await (dired-git--promise-create-hash-table buf* stdout))))
          (setq ov (await (dired-git--promise-add-annotation buf* hash)))
          (unless ov
            (error "Nil is returned from `dired-git--promise-add-annotation'"))
          (with-current-buffer buf*
            (setq-local dired-git-working nil)
            (setq-local dired-git-hashtable hash)))
      (error
       (pcase err
         (`(error (fail-git-info-command ,reason))
          (warn "Fail invoke git command
  buffer: %s\n  reason:%s"
                (prin1-to-string buf*) reason))
         (`(error (fail-git-info-invalid-output ,stdout ,stderr))
          (warn "Fail invoke git command.  Include stderr output
  buffer: %s\n  stdout: %s\n  stderr: %s"
                (prin1-to-string buf*) stdout stderr))
         (`(error (fail-create-hash-table ,stdout ,reason))
          (warn "Fail create hash table
  buffer: %s\n  stdout: %s\n  reason: %s"
                (prin1-to-string buf*) stdout reason))
         (`(error (fail-add-annotation ,table ,reason))
          (warn "Fail add annotation
  buffer: %s\n  table: %s\n  reason: %s"
                (prin1-to-string buf*) table  reason))
         (_
          (warn "Fail dired-git-refresh
  buffer: %s\n  reason: %s"
                (prin1-to-string buf*) err)))))))

;;;###autoload
(defun dired-git-refresh-using-cache ()
  "Refresh git overlays using cache."
  (interactive)
  (dired-git-refresh nil 'cache))

(defun dired-git--promise-shell-command (command dir)
  "Return promise to do COMMAND in DIR."
  (let ((default-directory dir))
    (promise:make-process (list shell-file-name shell-command-switch command))))

(async-defun dired-git--shell-command-in-dirs (command dirs)
  "Do COMMAND in DIRS.
COMMAND is invoked in parallel number of `dired-git-parallel'."
  (let ((files (cl-remove-if     #'file-directory-p dirs))
        (dirs* (cl-remove-if-not #'file-directory-p dirs)))
    (when files
      (user-error "Directory is needed, filtered: %s" (string-join files ", ")))
    (while dirs*
      (let (pick)
        (dotimes (_ dired-git-parallel)
          (push (pop dirs*) pick))
        (ppp-debug 'dired-git
          "Invoke command for dirs\n%s"
          (ppp-plist-to-string
           (list :command command :dirs pick)))
        (let ((info
               (mapcar
                (lambda (elm)
                  (when elm
                    `(,elm ,(dired-git--promise-shell-command command elm))))
                pick)))
          (dolist (elm info)
            (when elm
              (seq-let (dir promise) elm
                (condition-case _err
                    (seq-let (stdout stderr) (await promise)
                      (if (not (string-empty-p stderr))
                          (ppp-debug :level :error 'dired-git
                            "stderr is non-nil:\n%s"
                            (ppp-plist-to-string
                             (list :dir dir :command command :stdout stdout :stderr stderr)))
                        (ppp-debug 'dired-git
                          "Command exit normally\n%s"
                          (ppp-plist-to-string
                           (list :dir dir :command command :stdout stdout)))))
                  (error
                   (ppp-debug :level :error 'dired-git
                     "Unknown error:\n%s"
                     (ppp-plist-to-string
                      (list :dir dir :command command)))))))))))))

(defun dired-git--shell-command-in-marked-dirs (command)
  "Do COMMAND in directories marked dired buffer."
  (dired-git--shell-command-in-dirs command (dired-get-marked-files)))

;;;###autoload
(defun dired-git-status ()
  "Status with for marked directories in dired buffer."
  (interactive)
  (dired-git--shell-command-in-marked-dirs "git status"))

;;;###autoload
(defun dired-git-commit (msg)
  "Commit with MSG for marked directories in dired buffer."
  (interactive (read-string "Commit message: "))
  (dired-git--shell-command-in-marked-dirs
   (format "git commit -am \"%s\"" (shell-quote-argument msg))))

;;;###autoload
(defun dired-git-stage ()
  "Stage all for marked directories in dired buffer."
  (interactive)
  (dired-git--shell-command-in-marked-dirs "git add -A"))

;;;###autoload
(defun dired-git-unstage ()
  "Unstage all for marked directories in dired buffer."
  (interactive)
  (dired-git--shell-command-in-marked-dirs "git reset --mixed"))

;;;###autoload
(defun dired-git-stash ()
  "Stash all for marked directories in dired buffer."
  (interactive)
  (dired-git--shell-command-in-marked-dirs "git stash"))

;;;###autoload
(defun dired-git-stash-pop ()
  "Stash pop all for marked directories in dired buffer."
  (interactive)
  (dired-git--shell-command-in-marked-dirs "git stash pop"))

;;;###autoload
(defun dired-git-reset-hard ()
  "Reset --hard all for marked directories in dired buffer."
  (interactive)
  (dired-git--shell-command-in-marked-dirs "git reset --hard"))

;;;###autoload
(defun dired-git-branch (branch)
  "Checkout to BRANCH all for marked directories in dired buffer."
  (interactive (read-string "Branch name: "))
  (dired-git--shell-command-in-marked-dirs
   (format "git checkout %s" (shell-quote-argument branch))))

;;;###autoload
(defun dired-git-tag (tag)
  "Tag current HEAD to TAG all for marked directories in dired buffer."
  (interactive (read-string "Branch name: "))
  (dired-git--shell-command-in-marked-dirs
   (format "git tag %s" (shell-quote-argument tag))))

;;;###autoload
(defun dired-git-fetch ()
  "Fetch all for marked directories in dired buffer."
  (interactive)
  (dired-git--shell-command-in-marked-dirs "git fetch --all"))

;;;###autoload
(defun dired-git-pull ()
  "Pull for marked directories in dired buffer."
  (interactive)
  (dired-git--shell-command-in-marked-dirs "git pull"))

;;;###autoload
(defun dired-git-merge (branch)
  "Merge BRANCH for marked directories in dired buffer."
  (interactive (read-string "Branch name: "))
  (dired-git--shell-command-in-marked-dirs
   (format "git merge %s" branch)))

;;;###autoload
(defun dired-git-push ()
  "Push for marked directories in dired buffer."
  (interactive)
  (dired-git--shell-command-in-marked-dirs "git push"))

;;;###autoload
(defun dired-git-run (command)
  "Invoke COMMAND for marked directories in dired buffer."
  (interactive (read-string "Command: " "git "))
  (dired-git--shell-command-in-marked-dirs
   (mapconcat #'shell-quote-argument (split-string command " ") " ")))


;;; Minor mode management

(defun dired-git--advice-refresh (fn &rest args)
  "Advice function for FN with ARGS."
  (apply fn args)
  (when dired-git-mode
    (dired-git-refresh)))

(defun dired-git--advice-refresh-using-cache (fn &rest args)
  "Advice function for FN with ARGS."
  (apply fn args)
  (when dired-git-mode
    (dired-git-refresh-using-cache)))

(defvar dired-git-advice-alist
  '((dired-readin                . dired-git--advice-refresh)
    (dired-revert                . dired-git--advice-refresh)
    (dired-internal-do-deletions . dired-git--advice-refresh-using-cache)
    (dired-narrow--internal      . dired-git--advice-refresh-using-cache))
  "Alist defined advice functions.")

(defun dired-git--setup ()
  "Setup dired-git minor-mode."
  (pcase-dolist (`(,sym . ,fn) dired-git-advice-alist)
    (advice-add sym :around fn))
  (dired-git-refresh (current-buffer)))

(defun dired-git--teardown ()
  "Teardown all overlays added by dired-git."
  (setq-local dired-git-hashtable nil)
  (setq-local dired-git-working nil)
  (dired-git--remove-all-overlays))

;;;###autoload
(define-minor-mode dired-git-mode
  "Minor mode to add git information for dired."
  :lighter " Dired-git"
  :require 'dired-git
  :group 'dired-git
  :keymap `((,(kbd "=") . dired-git-dispatch))
  (if (not (derived-mode-p 'dired-mode))
      (error "`dired-git-mode' is only compatible with `dired-mode'")
    (if dired-git-mode
        (dired-git--setup)
      (dired-git--teardown))))

(provide 'dired-git)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; dired-git.el ends here
