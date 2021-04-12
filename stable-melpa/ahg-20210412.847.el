;;; ahg.el --- Alberto's Emacs interface for Mercurial (Hg)

;; Copyright (C) 2008-2020 Alberto Griggio

;; Author: Alberto Griggio <agriggio@users.sourceforge.net>
;; URL: https://bitbucket.org/agriggio/ahg
;; Package-Version: 20210412.847
;; Package-Commit: 77bc2a628df006dcd2dc359ac12acdf8091a1356
;; Version: 1.0.0

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

;; A simple Emacs interface for the Mercurial (Hg) Distributed SCM.
;;
;; Quick Guide
;; -----------
;; 
;; After the installation, an ``aHg`` menu appears as a child of the standard
;; ``Tools`` menu of Emacs. The available commands are:
;; 
;; Status:
;;    Shows the status of the current working directory, much like the
;;    ``cvs-examine`` command of PCL-CVS.
;; 
;; Log Summary:
;;    Shows a table with a short change history of the current working
;;    directory.
;; 
;; Detailed Log:
;;    Shows a more detailed change history of the current working directory.
;; 
;; Commit Current File:
;;    Commits the file you are currently visiting.
;; 
;; View Changes of Current File:
;;    Displays changes of current file wrt. the tip of the repository.
;; 
;; Mercurial Queues:
;;    Support for basic commands of the mq extension.
;; 
;; Execute Hg Command:
;;    Lets you execute an arbitrary hg command. The focus goes to the
;;    minibuffer, where you can enter the command to execute. You don't have
;;    to type ``hg``, as this is implicit. For example, to execute ``hg
;;    outgoing``, simply enter ``outgoing``. Pressing ``TAB`` completes the
;;    current command or file name.
;; 
;; Help on Hg Command:
;;    Shows help on a given hg command (again, use ``TAB`` to complete partial
;;    command names).
;;    
;; 
;; aHg buffers
;; ~~~~~~~~~~~
;; 
;; The ``Status``, ``Log Summary``, ``Detailed Log`` and the ``List of MQ
;; Patches`` commands display their results on special buffers. Each of these
;; has its own menu, with further available commands.
;; 
;; 
;; Customization
;; ~~~~~~~~~~~~~
;; 
;; There are some options that you can customize (e.g. global keybindings or
;; fonts). To do so, use ``M-x customize-group RET ahg``.
 
;;; Code:

(require 'diff-mode)
(require 'easymenu)
(require 'log-edit)
(require 'ewoc)
(eval-when-compile
  (require 'cl))
(require 'grep)
(require 'dired)
(require 'vc-annotate)

;;-----------------------------------------------------------------------------
;; ahg-version
;;-----------------------------------------------------------------------------

(defvar ahg-version-string "1.0.0")

(defun ahg-version ()
  "Shows aHg version number."
  (interactive)
  (message "aHg version %s" ahg-version-string))

;;-----------------------------------------------------------------------------
;; the global aHg menu and keymap
;;-----------------------------------------------------------------------------

(easy-menu-add-item nil '("tools")
                    '("aHg"
                      ["Status" ahg-status t]
                      ["Log Summary" ahg-short-log t]
                      ["Detailed Log" ahg-log t]
                      ["Revision DAG" ahg-glog t]
                      ["Heads" ahg-heads t]
                      ["Tags" ahg-tags t]
                      ["Bookmarks" ahg-bookmarks t]
                      ["--" nil nil]
                      ["Commit Current File" ahg-commit-cur-file t]
                      ["View Changes of Current File" ahg-diff-cur-file t]
                      ["View Ediff of Current File" ahg-diff-ediff-cur-file t]
                      ["View Change Log of Current File" ahg-log-cur-file t]
                      ["Annotate Current File" ahg-annotate-cur-file t]
                      ["Revert Current File" ahg-revert-cur-file t]
                      ["Remove Current File" ahg-rm-cur-file t]
                      ["Grep the Working Directory" ahg-manifest-grep t]
                      ["--" nil nil]
                      ("Mercurial Queues"
                       ["New Patch..." ahg-qnew t]
                       ["View Qdiff" ahg-qdiff t]
                       ["Refresh Current Patch" ahg-qrefresh t]
                       ["Go to Patch..." ahg-qgoto t]
                       ["Move to Patch..." ahg-qmove t]
                       ["Switch to Patch..." ahg-qswitch t]
                       ["Apply Patch to the Working Copy..." ahg-qapply t]
                       ["Pop All Patches" ahg-qpop-all t]
                       ["Show Name of Current Patch" ahg-qtop t]
                       ["List All Patches" ahg-mq-list-patches t]
                       ["Delete Patch..." ahg-qdelete t]
                       ["Convert Current Patch to Changeset"
                        ahg-mq-convert-patch-to-changeset t]
                       ["Edit series File" ahg-mq-edit-series t])
                      ["--" nil nil]
                      ["Execute Hg Command" ahg-do-command t]
                      ["Help on Hg Command" ahg-command-help t])
                    "PCL-CVS")

(defvar ahg-global-map
  (let ((map (make-sparse-keymap)))
    (define-key map "s" 'ahg-status)
    (define-key map "l" 'ahg-short-log)
    (define-key map "L" 'ahg-log)
    (define-key map "G" 'ahg-glog)
    (define-key map "g" 'ahg-glog)
    (define-key map "H" 'ahg-heads)
    (define-key map "T" 'ahg-tags)
    (define-key map "B" 'ahg-bookmarks)
    (define-key map "!" 'ahg-do-command)
    (define-key map "h" 'ahg-command-help)
    (define-key map "c" 'ahg-commit-cur-file)
    (define-key map "=" 'ahg-diff-cur-file)
    (define-key map "e" 'ahg-diff-ediff-cur-file)
    (define-key map "a" 'ahg-annotate-cur-file)
    (define-key map "r" 'ahg-revert-cur-file)
    (define-key map "R" 'ahg-rm-cur-file)
    (define-key map "f" 'ahg-manifest-grep)
    (define-key map (kbd "C-l") 'ahg-log-cur-file)
    (define-key map "Q"
      (let ((qmap (make-sparse-keymap)))
        (define-key qmap "n" 'ahg-qnew)
        (define-key qmap "=" 'ahg-qdiff)
        (define-key qmap "r" 'ahg-qrefresh)
        (define-key qmap "g" 'ahg-qgoto)
        (define-key qmap "m" 'ahg-qmove)
        (define-key qmap "s" 'ahg-qswitch)
        (define-key qmap "a" 'ahg-qapply)
        (define-key qmap "p" 'ahg-qpop-all)
        (define-key qmap "t" 'ahg-qtop)
        (define-key qmap "d" 'ahg-qdelete)
        (define-key qmap "f" 'ahg-mq-convert-patch-to-changeset)
        (define-key qmap "l" 'ahg-mq-list-patches)
        (define-key qmap "e" 'ahg-mq-edit-series)
        qmap))
    map))


;;-----------------------------------------------------------------------------
;; Customization
;;-----------------------------------------------------------------------------

(defgroup ahg nil "aHg Mercurial Frontend" :group 'tools)

(defcustom ahg-hg-command "hg"
  "Command to use for invoking Mercurial."
  :group 'ahg :type 'string)

(defcustom ahg-global-key-prefix "hg"
  "Prefix of globally-available aHg commands."
  :group 'ahg :type 'string
  :set (function (lambda (symbol value)
                   (when (boundp symbol) (global-unset-key (eval symbol)))
                   (global-set-key (set symbol value) ahg-global-map))))

(defcustom ahg-do-command-insert-header t
  "If non-nil, `ahg-do-command' will insert a header line in the
command output." :group 'ahg :type 'boolean)

(defcustom ahg-do-command-show-buffer-immediately t
  "If non-nil, `ahg-do-command' will immediately switch to the buffer with the
command output, instead of waiting for the command to finish."
  :group 'ahg :type 'boolean)

(defcustom ahg-do-command-interactive-regexp "\\<\\(in\\|incoming\\|out\\|outgoing\\|pull\\|push\\)\\>"
  "Regexp for commands that might require a username/password
input in `ahg-do-command'."
  :group 'ahg :type 'regexp)

(defcustom ahg-auto-refresh-status-buffer t
  "If non-nil, automatically refresh the *aHg status* buffer when certain
operations (e.g. add, remove, commit) are performed."
  :group 'ahg :type 'boolean)

(defcustom ahg-restore-window-configuration-on-quit t
  "If non-nil, when `ahg-buffer-quit' will restore the window configuration."
  :group 'ahg :type 'boolean)

(defcustom ahg-diff-use-git-format t
  "If non-nil, aHg commands that output a diff will use the git format."
  :group 'ahg :type 'boolean)

(defcustom ahg-qrefresh-use-short-flag t
  "If non-nil, aHg qrefresh command will use the --short flag. See the help
for qrefresh for more information."
  :group 'ahg :type 'boolean)

(defcustom ahg-yesno-short-prompt t
  "If non-nil, use short form (y or n) when asking for confimation to the user."
  :group 'ahg :type 'boolean)

(defcustom ahg-i18n t
  "If non-nil, use i18n when calling Mercurial.
Note: disabling i18n is done by unsetting the LANG environment variable
when calling hg. This might not always work."
  :group 'ahg :type 'boolean)

(defcustom ahg-subprocess-coding-system nil
  "If non-nil, coding system used when reading output of hg commands."
  :group 'ahg :type 'symbol)

(defcustom ahg-log-revrange-size 100
  "Length of default revision range for `ahg-log',
`ahg-short-log' and `ahg-glog'."
  :group 'ahg :type 'integer)

(defcustom ahg-map-cmdline-file nil
  "Path to the file for mapping the command line.
For `nil' the default file is used."
  :group 'ahg :type 'string)

(defcustom ahg-summary-remote nil
  "If true, pass --remote to summary command used by ahg-status"
  :group 'ahg :type 'boolean)

(defcustom ahg-summary-git-svn-info nil
  "If true, include info about git and/or svn revisions in the
summary shown in ahg-status buffers"
  :group 'ahg :type 'boolean)

(defcustom ahg-manifest-grep-use-xargs-grep t
  "If true, use `xargs' and `grep' commands for implementing `ahg-manifest-grep'
 (otherwise, an elisp function is used)."
  :group 'ahg :type 'boolean)

(defcustom ahg-diff-keep-current-buffer nil
  "If true, keep the focus on the current buffer when showing diffs."
  :group 'ahg :type 'boolean)

(defface ahg-status-marked-face
  '((default (:inherit font-lock-preprocessor-face)))
  "Face for marked files in aHg status buffers." :group 'ahg)

(defface ahg-status-modified-face
  '((default (:inherit font-lock-function-name-face)))
  "Face for modified files in aHg status buffers." :group 'ahg)

(defface ahg-status-added-face
  '((default (:inherit font-lock-type-face)))
  "Face for added files in aHg status buffers." :group 'ahg)

(defface ahg-status-removed-face
  '((default (:inherit font-lock-constant-face)))
  "Face for removed files in aHg status buffers." :group 'ahg)

(defface ahg-status-clean-face
  '((default (:inherit default)))
  "Face for clean files in aHg status buffers." :group 'ahg)

(defface ahg-status-deleted-face
  '((default (:inherit font-lock-string-face)))
  "Face for deleted files in aHg status buffers." :group 'ahg)

(defface ahg-status-ignored-face
  '((default (:inherit font-lock-comment-face)))
  "Face for ignored files in aHg status buffers." :group 'ahg)

(defface ahg-status-unknown-face
  '((default (:inherit font-lock-variable-name-face)))
  "Face for unknown files in aHg status buffers." :group 'ahg)

(defface ahg-short-log-revision-face
  '((default (:inherit font-lock-function-name-face)))
  "Face for revision field in aHg short log buffers." :group 'ahg)

(defface ahg-short-log-date-face
  '((default (:inherit font-lock-string-face)))
  "Face for date field in aHg short log buffers." :group 'ahg)

(defface ahg-log-revision-face
  '((default (:inherit font-lock-variable-name-face)))
  "Face for revision field in aHg log buffers." :group 'ahg)

(defface ahg-log-field-face
  '((default (:inherit font-lock-function-name-face)))
  "Face for fields in aHg log buffers." :group 'ahg)

(defface ahg-log-branch-face
  '((default (:inherit font-lock-keyword-face)))
  "Face for tags and branches in aHg log buffers." :group 'ahg)

(defface ahg-log-phase-draft-face
  '((default (:inherit font-lock-preprocessor-face)))
  "Face for draft phase in aHg log buffers." :group 'ahg)

(defface ahg-log-phase-secret-face
  '((default (:inherit font-lock-comment-face)))
  "Face for secret phase in aHg log buffers." :group 'ahg)

(defface ahg-short-log-user-face
  '((default (:inherit font-lock-type-face)))
  "Face for user field in aHg short log buffers." :group 'ahg)

(defface ahg-header-line-face
  '((default (:inherit font-lock-comment-face)))
  "Face for header lines in aHg buffers." :group 'ahg)

(defface ahg-header-line-root-face
  '((default (:inherit font-lock-constant-face)))
  "Face for repository path in header lines of aHg buffers." :group 'ahg)

;;-----------------------------------------------------------------------------
;; Variable definitions for faces
;;-----------------------------------------------------------------------------

(defvar ahg-status-marked-face 'ahg-status-marked-face)
(defvar ahg-status-modified-face 'ahg-status-modified-face)
(defvar ahg-status-added-face 'ahg-status-added-face)
(defvar ahg-status-removed-face 'ahg-status-removed-face)
(defvar ahg-status-clean-face 'ahg-status-clean-face)
(defvar ahg-status-deleted-face 'ahg-status-deleted-face)
(defvar ahg-status-ignored-face 'ahg-status-ignored-face)
(defvar ahg-status-unknown-face 'ahg-status-unknown-face)
(defvar ahg-short-log-revision-face 'ahg-short-log-revision-face)
(defvar ahg-short-log-date-face 'ahg-short-log-date-face)
(defvar ahg-log-field-face 'ahg-log-field-face)
(defvar ahg-log-branch-face 'ahg-log-branch-face)
(defvar ahg-log-revision-face 'ahg-log-revision-face)
(defvar ahg-log-phase-draft-face 'ahg-log-phase-draft-face)
(defvar ahg-log-phase-secret-face 'ahg-log-phase-secret-face)
(defvar ahg-short-log-user-face 'ahg-short-log-user-face)
(defvar ahg-header-line-face 'ahg-header-line-face)
(defvar ahg-header-line-root-face 'ahg-header-line-root-face)
(defvar ahg-invisible-face
  (progn
    (copy-face 'default 'ahg-invisible-face)
    (set-face-foreground 'ahg-invisible-face (face-background 'default))
    'ahg-invisible-face))


;;-----------------------------------------------------------------------------
;; some dynamically-generated variables, defined here to prevent compiler
;;-----------------------------------------------------------------------------
(defvar ahg-status-extra-switches)
(defvar ahg-root)
(defvar ewoc)
(defvar ahg-window-configuration)


;;-----------------------------------------------------------------------------
;; hg root
;;-----------------------------------------------------------------------------

(defun ahg-root (&optional noerror)
  "Returns the root of the tree handled by Mercurial. If NOERROR
is nil, raises an error if the current dir is not under
hg. Otherwise, the default-directory is returned."
  (let ((f (locate-dominating-file default-directory ".hg")))
    (if f
        (file-name-as-directory (expand-file-name f))
      (if noerror default-directory
        (error "aHg: no repository found in %s" default-directory)))))

;;-----------------------------------------------------------------------------
;; hg identify
;;-----------------------------------------------------------------------------

(defun ahg-identify (&optional root)
  (interactive)
  (with-temp-buffer
    (let* ((args (list "-nibt"))
           (status
           (if root
               (let ((default-directory (file-name-as-directory root)))
                 (ahg-call-process "identify" args))
             (ahg-call-process "identify" args))))
      (if (= status 0)
        (concat
         "Id: "
         (buffer-substring-no-properties (point-min) (1- (point-max))))
        (concat "hg identify failed for " root)))))

(defun ahg-summary-info (root)
  (with-temp-buffer
    (let ((ret
           (let ((status (and (ahg-cd root)
                              (ahg-call-process 
                               "summary" 
                               (when ahg-summary-remote (list "--remote"))))))
             ;; failure could mean the summary command wasn't available; it
             ;; could also mean communication with the remote repo was
             ;; unsuccesful If we can find the word "update: " in the output,
             ;; we'll assume it failed connecting to remote repo, but rest of
             ;; summary is there.
             (if (or (= status 0) 
                     (and ahg-summary-remote
                          (re-search-backward "^update: " nil t)))
                 (replace-regexp-in-string
                  "^branch: default\n" ""
                  (buffer-substring-no-properties (point-min) (1- (point-max))))
               ;; if hg summary is not available, fall back to hg identify
               (ahg-identify root)))))
      (when ahg-summary-git-svn-info
        (goto-char (point-max))
        (let (svn git)
          (when (save-excursion
                  (= (ahg-call-process
                      "log"
                      (list "-r" "." "--template" "{svnrev}\n{gitnode}\n")) 0))
            (setq svn (buffer-substring-no-properties (point-at-bol)
                                                      (point-at-eol)))
            (forward-line 1)
            (setq git (buffer-substring-no-properties (point-at-bol)
                                                      (point-at-eol)))
            (unless (string= svn "")
              (setq ret (concat ret "\nsvn:    " svn)))
            (unless (string= git "")
              (setq ret (concat ret "\ngit:    " git)))
            )))
      ret
      )))

;;-----------------------------------------------------------------------------
;; hg status
;;-----------------------------------------------------------------------------

(defvar ahg-face-status-hash
  (let* ((test (define-hash-table-test 'ahg-str-hash 'string= 'sxhash))
         (h (make-hash-table :test 'ahg-str-hash)))
    (puthash "M" ahg-status-modified-face h)
    (puthash "A" ahg-status-added-face h)
    (puthash "R" ahg-status-removed-face h)
    (puthash "C" ahg-status-clean-face h)
    (puthash "=" ahg-status-clean-face h) ;; for Mercurial > 0.9.5
    (puthash "!" ahg-status-deleted-face h)
    (puthash "I" ahg-status-ignored-face h)
    (puthash "?" ahg-status-unknown-face h)
    h))

(defvar ahg-status-line-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-2] 'ahg-status-visit-file-other-window)
    map))

(defun ahg-face-from-status (status-code)
  (gethash status-code ahg-face-status-hash 'default))


(define-derived-mode ahg-status-mode special-mode "aHg-status"
  "Major mode for *hg status* buffers.

Commands:
\\{ahg-status-mode-map}
"
  (buffer-disable-undo) ;; undo info not needed here
  (setq buffer-read-only t)
  (font-lock-mode nil)
  (define-key ahg-status-mode-map " " 'ahg-status-toggle-mark)
  (define-key ahg-status-mode-map "m" 'ahg-status-mark)
  (define-key ahg-status-mode-map "u" 'ahg-status-unmark)
  (define-key ahg-status-mode-map (kbd "M-DEL") 'ahg-status-unmark-all)
  (define-key ahg-status-mode-map "c" 'ahg-status-commit)
  (define-key ahg-status-mode-map "a" 'ahg-status-add)
  (define-key ahg-status-mode-map "A" 'ahg-status-addremove)
  (define-key ahg-status-mode-map "=" 'ahg-status-diff)
  (define-key ahg-status-mode-map "D" 'ahg-status-diff-all)
  (define-key ahg-status-mode-map "e" 'ahg-status-diff-ediff)
  (define-key ahg-status-mode-map "r" 'ahg-status-remove)
  (define-key ahg-status-mode-map "g" 'ahg-status-refresh)
  (define-key ahg-status-mode-map "I" 'ahg-status-add-to-hgignore)
  (define-key ahg-status-mode-map "q" 'ahg-buffer-quit)
  (define-key ahg-status-mode-map "U" 'ahg-status-undo)
  (define-key ahg-status-mode-map "!" 'ahg-status-do-command)
  (define-key ahg-status-mode-map "l" 'ahg-status-short-log)
  (define-key ahg-status-mode-map "L" 'ahg-status-log)
  (define-key ahg-status-mode-map "G" 'ahg-status-glog)
  (define-key ahg-status-mode-map "H" 'ahg-heads)
  (define-key ahg-status-mode-map "T" 'ahg-tags)
  (define-key ahg-status-mode-map "B" 'ahg-bookmarks)
  (define-key ahg-status-mode-map "f" 'ahg-status-visit-file)
  (define-key ahg-status-mode-map "\r" 'ahg-status-visit-file)
  (define-key ahg-status-mode-map "o" 'ahg-status-visit-file-other-window)
  (define-key ahg-status-mode-map "h" 'ahg-command-help)
  (define-key ahg-status-mode-map "$" 'ahg-status-shell-command)
  (define-key ahg-status-mode-map "F" 'ahg-status-dired-find)
  (define-key ahg-status-mode-map "d" 'ahg-status-delete)
  (define-key ahg-status-mode-map "n" 'ahg-status-next-file)
  (define-key ahg-status-mode-map "p" 'ahg-status-prev-file)
  (let ((showmap (make-sparse-keymap)))
    (define-key showmap "s" 'ahg-status-show-default)
    (define-key showmap "A" 'ahg-status-show-all)
    (define-key showmap "t" 'ahg-status-show-tracked)
    (define-key showmap "m" 'ahg-status-show-modified)
    (define-key showmap "a" 'ahg-status-show-added)
    (define-key showmap "r" 'ahg-status-show-removed)
    (define-key showmap "d" 'ahg-status-show-deleted)
    (define-key showmap "c" 'ahg-status-show-clean)
    (define-key showmap "u" 'ahg-status-show-unknown)
    (define-key showmap "i" 'ahg-status-show-ignored)
    (define-key ahg-status-mode-map "s" showmap))
  (let ((qmap (make-sparse-keymap)))
    (define-key qmap "n" 'ahg-qnew)
    (define-key qmap "=" 'ahg-qdiff)
    (define-key qmap "r" 'ahg-qrefresh)
    (define-key qmap "g" 'ahg-qgoto)
    (define-key qmap "m" 'ahg-qmove)
    (define-key qmap "s" 'ahg-qswitch)
    (define-key qmap "a" 'ahg-qapply)
    (define-key qmap "p" 'ahg-qpop-all)
    (define-key qmap "t" 'ahg-qtop)
    (define-key qmap "d" 'ahg-qdelete)
    (define-key qmap "f" 'ahg-mq-convert-patch-to-changeset)
    (define-key qmap "l" 'ahg-mq-list-patches)
    (define-key qmap "e" 'ahg-mq-edit-series)
    (define-key ahg-status-mode-map "Q" qmap))
  (let ((imap (make-sparse-keymap)))
    (define-key imap "c" 'ahg-record)
    (let ((iqmap (make-sparse-keymap)))
      (define-key iqmap "n" 'ahg-record-qnew)
      (define-key imap "Q" iqmap))
    (define-key ahg-status-mode-map "i" imap))
  (let ((amap (make-sparse-keymap)))
    (define-key amap "a" 'ahg-status-commit-amend)
    (define-key amap "s" 'ahg-status-commit-secret)
    (define-key ahg-status-mode-map "C" amap))
  (easy-menu-add ahg-status-mode-menu ahg-status-mode-map))

(easy-menu-define ahg-status-mode-menu ahg-status-mode-map "aHg Status"
  '("aHg Status"
    ["Visit File" ahg-status-visit-file [:keys "f" :active t]]
    ["Visit File (Other Window)" ahg-status-visit-file-other-window
     [:keys "o" :active t]]
    ["--" nil nil]
    ["Commit" ahg-status-commit [:keys "c" :active t]]
    ["Interactive Commit (Record)" ahg-record [:keys "ic" :active t]]
    ["Secret Commit" ahg-status-commit-secret [:keys "Cs" :active t]]
    ["Amend" ahg-status-commit-amend [:keys "Ca" :active t]]
    ["Add" ahg-status-add [:keys "a" :active t]]
    ["Remove" ahg-status-remove [:keys "r" :active t]]
    ["Add/Remove" ahg-status-addremove [:keys "A" :active t]]
    ["Add to .hgignore" ahg-status-add-to-hgignore [:keys "I" :active t]]
    ["Undo" ahg-status-undo [:keys "U" :active t]]
    ["Delete" ahg-status-delete [:keys "d" :active t]]
    ["Hg Command" ahg-status-do-command [:keys "!" :active t]]
    ["Shell Command" ahg-status-shell-command [:keys "$" :active t]]
    ["--" nil nil]
    ["Toggle Mark" ahg-status-toggle-mark [:keys " " :active t]]
    ["Mark" ahg-status-mark [:keys "m" :active t]]
    ["Unmark" ahg-status-unmark [:keys "u" :active t]]
    ["Unmark All" ahg-status-unmark-all [:keys (kbd "M-DEL") :active t]]
    ["Show Marked in Dired" ahg-status-dired-find [:keys "F" :active t]]
    ["--" nil nil]
    ["Log Summary" ahg-short-log [:keys "l" :active t]]
    ["Detailed Log" ahg-log [:keys "L" :active t]]
    ["Revision DAG" ahg-glog [:keys "G" :active t]]
    ["Heads" ahg-heads [:keys "H" :active t]]
    ["Tags" ahg-tags [:keys "T" :active t]]
    ["Bookmarks" ahg-bookmarks [:keys "B" :active t]]
    ["--" nil nil]
    ["Diff" ahg-status-diff [:keys "=" :active t]]
    ["Diff Marked" ahg-status-diff-all [:keys "D" :active t]]
    ["Ediff" ahg-status-diff-ediff [:keys "e" :active t]]
    ["--" nil nil]
    ("Show"
     ["Default" ahg-status-show-default [:keys "ss" :active t]]
     ["All" ahg-status-show-all [:keys "sA" :active t]]
     ["Tracked" ahg-status-show-tracked [:keys "st" :active t]]
     ["Modified" ahg-status-show-modified [:keys "sm" :active t]]
     ["Added" ahg-status-show-added [:keys "sa" :active t]]
     ["Removed" ahg-status-show-removed [:keys "sr" :active t]]
     ["Deleted" ahg-status-show-deleted [:keys "sd" :active t]]
     ["Clean" ahg-status-show-clean [:keys "sc" :active t]]
     ["Unknown" ahg-status-show-unknown [:keys "su" :active t]]
     ["Ignored" ahg-status-show-ignored [:keys "si" :active t]]
     )
    ["--" nil nil]
    ("Mercurial Queues"
     ["New Patch..." ahg-qnew [:keys "Qn" :active t]]
     ["New Interactive Patch" ahg-record-qnew [:keys "iQn" :active t]]
     ["View Qdiff" ahg-qdiff [:keys "Q=" :active t]]
     ["Refresh Current Patch" ahg-qrefresh [:keys "Qr" :active t]]
     ["Go to Patch..." ahg-qgoto [:keys "Qg" :active t]]
     ["Move to Patch..." ahg-qmove [:keys "Qm" :active t]]
     ["Switch to Patch..." ahg-qswitch [:keys "Qs" :active t]]
     ["Apply Patch to the Working Copy..." ahg-qapply [:keys "Qa" :active t]]
     ["Pop All Patches" ahg-qpop-all [:keys "Qp" :active t]]
     ["Show Name of Current Patch" ahg-qtop [:keys "Qt" :active t]]
     ["List All Patches" ahg-mq-list-patches [:keys "Ql" :active t]]
     ["Delete Patch..." ahg-qdelete [:keys "Qd" :active t]]
     ["Convert Current Patch to Changeset"
      ahg-mq-convert-patch-to-changeset [:keys "Qf" :active t]]
     ["Edit series File" ahg-mq-edit-series [:keys "Qe" :active t]])
    ["--" nil nil]
    ["Help on Hg Command" ahg-command-help [:keys "h" :active t]]
    ["--" nil nil]
    ["Refresh" ahg-status-refresh [:keys "g" :active t]]
    ["Quit" ahg-buffer-quit [:keys "q" :active t]]
    ))


(defvar ahg-status-consider-extra-switches nil)

(defun ahg-status-get-root (is-interactive)
  (if is-interactive
      (condition-case nil (ahg-root)
        (error
         (with-temp-buffer
           (setq default-directory
                 (file-name-as-directory
                  (read-directory-name "Hg repository: " default-directory)))
           (ahg-root))))
    (ahg-root)))

(defun ahg-status (&rest extra-switches)
  "Run hg status. When called non-interactively, it is possible
to pass extra switches to hg status."
  (interactive)
  (let ((buf (get-buffer-create "*aHg-status*"))
        (curdir (expand-file-name (file-name-as-directory default-directory)))
        (show-message (called-interactively-p 'interactive))
        (root (ahg-status-get-root (called-interactively-p 'interactive))))
    (when ahg-status-consider-extra-switches
      (let ((sbuf (ahg-get-status-buffer root)))
        (when sbuf
          (with-current-buffer sbuf
            (setq extra-switches ahg-status-extra-switches)))))    
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer))
      (setq default-directory root)
      (set (make-local-variable 'ahg-root) root)
      (set (make-local-variable 'ahg-status-extra-switches) extra-switches)
      (ahg-push-window-configuration)
      (ahg-generic-command
       "status" extra-switches
       (lexical-let ((no-pop ahg-status-no-pop)
                     (point-pos ahg-status-point-pos))
         (lambda (process status)
           (ahg-status-sentinel process status no-pop point-pos))) buf
           nil (not show-message)))))

(defun ahg-status-pp (data)
  "Pretty-printer for data elements in a *hg status* buffer."
  ;; data is a cons cell: (marked flag (hg status . filename))
  (let ((marked (car data))
        (status-code (cadr data))
        (filename (cddr data)))
    (if marked
        (progn
          (insert (propertize "*" 'face (cons 'foreground-color "#00CC00")))
          (insert (propertize (concat status-code " " filename)
                              'face ahg-status-marked-face)))
      (insert (propertize (concat " " status-code " " filename)
                          'face (ahg-face-from-status status-code)
                          'mouse-face 'highlight
                          'keymap ahg-status-line-map)))))


(defun ahg-status-toggle-mark ()
  (interactive)
  (let* ((node (ewoc-locate ewoc))
         (data (and node (ewoc-data node)))
         (inhibit-read-only t))
    (when data
      (if (car data) (ewoc-set-data node (cons nil (cdr data)))
        (ewoc-set-data node (cons t (cdr data))))
      (ewoc-invalidate ewoc node)
      (setq node (ewoc-next ewoc node))
      (when node (goto-char (ewoc-location node))))))

(defun ahg-status-do-mark (yes)
  (let* ((node (ewoc-locate ewoc))
         (data (and node (ewoc-data node)))
         (inhibit-read-only t))
    (when data
      (if yes (ewoc-set-data node (cons t (cdr data)))
        (ewoc-set-data node (cons nil (cdr data))))
      (ewoc-invalidate ewoc node)
      (setq node (ewoc-next ewoc node))
      (when node (goto-char (ewoc-location node))))))

(defun ahg-status-mark () (interactive) (ahg-status-do-mark t))
(defun ahg-status-unmark () (interactive) (ahg-status-do-mark nil))

(defun ahg-status-unmark-all ()
  (interactive)
  (ewoc-map (lambda (d) (when (car d) (setcar d nil) t)) ewoc))

(defun ahg-status-show-default () (interactive) (ahg-status ""))
(defun ahg-status-show-all () (interactive) (ahg-status "-A"))
(defun ahg-status-show-tracked () (interactive) (ahg-status "-mardc"))
(defun ahg-status-show-modified () (interactive) (ahg-status "-m"))
(defun ahg-status-show-added () (interactive) (ahg-status "-a"))
(defun ahg-status-show-removed () (interactive) (ahg-status "-r"))
(defun ahg-status-show-deleted () (interactive) (ahg-status "-d"))
(defun ahg-status-show-clean () (interactive) (ahg-status "-c"))
(defun ahg-status-show-unknown () (interactive) (ahg-status "-u"))
(defun ahg-status-show-ignored () (interactive) (ahg-status "-i"))


(defun ahg-status-get-marked (action-if-empty &optional filter)
  "Returns the list of marked nodes. If such list is empty, behave according to
ACTION-IF-EMPTY: if nil, do nothing. If 'all, return all nodes, if 'cur return
the singleton list with the node at point."
  (let ((marked (ewoc-collect ewoc
                              (if filter (lambda (d)
                                           (and (car d) (funcall filter d)))
                                'car))))
    (if (null marked)
      (cond ((eq action-if-empty nil) nil)
            ((eq action-if-empty 'all)
             (ewoc-collect ewoc (if filter filter 'identity)))
            ((eq action-if-empty 'cur)
             (let ((n (ewoc-locate ewoc)))
               (when (and n (or (null filter) (funcall filter (ewoc-data n))))
                 (list (ewoc-data n))))))
      marked)))

(defun ahg-status-commit (&optional logmsg)
  (interactive)
  (let ((files (ahg-status-get-marked nil)))
    (ahg-commit (mapcar 'cddr files) nil logmsg)))

(defun ahg-status-commit-amend ()
  (interactive)
  (let ((files (ahg-status-get-marked nil))
        msg
        logmsg)
    (with-temp-buffer
      (when (= (ahg-call-process "log"
                                 (list "-r" "." "--template"
                                       "{node|short}\\n{desc}")) 0)
        (goto-char (point-min))
        (setq msg (format "amending changeset %s"
                          (buffer-substring-no-properties (point-min)
                                                          (point-at-eol))))
        (forward-line 1)
        (setq logmsg (buffer-substring-no-properties
                      (point-at-bol) (point-max)))))
    (ahg-commit (mapcar 'cddr files) msg logmsg (list "--amend"))))


(defun ahg-status-commit-secret ()
  (interactive)
  (let ((files (ahg-status-get-marked nil)))
    (ahg-commit (mapcar 'cddr files)
                "committing with secret phase" nil (list "--secret"))))


(defun ahg-status-add ()
  (interactive)
  (let ((files (ahg-status-get-marked
                'all (lambda (data)
                       (let ((s (cadr data)))
                         (or (string= s "?")
                             (string= s "I")))))))
    (if (ahg-y-or-n-p (format "Add %d files to hg? " (length files)))
        (ahg-generic-command
         "add" (mapcar 'cddr files)
         (lexical-let ((howmany (length files))
                       (aroot (ahg-root)))
           (lambda (process status)
             (if (string= status "finished\n")
                 (with-current-buffer
                     (process-buffer process)
                   (ahg-status-maybe-refresh aroot)
                   (kill-buffer nil)
                   (message "Added %d files" howmany))
               (ahg-show-error process)))))
      (message "hg add aborted"))))

(defun ahg-status-remove ()
  (interactive)
  (let ((files (ahg-status-get-marked
                 'all (lambda (data)
                        (let ((f (cadr data)))
                          (or (string= f "!") (string= f "C")))))))
    (if (ahg-y-or-n-p (format "Remove %d files from hg? " (length files)))
        (ahg-generic-command
         "remove" (mapcar 'cddr files)
         (lexical-let ((howmany (length files))
                       (aroot (ahg-root)))
           (lambda (process status)
             (if (string= status "finished\n")
                 (with-current-buffer (process-buffer process)
                   (ahg-status-maybe-refresh aroot)
                   (kill-buffer nil)
                   (message "Removed %d files" howmany))
               (ahg-show-error process)))))
      (message "hg remove aborted"))))

(defun ahg-status-addremove ()
  (interactive)
  (let ((files (ahg-status-get-marked
                'all (lambda (data)
                       (let ((s (cadr data)))
                         (or (string= s "?")
                             (string= s "!")
                             (string= s "I")))))))
    (if (ahg-y-or-n-p (format "Add/Remove %d files to/from hg? "
                              (length files)))
        (ahg-generic-command
         "addremove" (mapcar 'cddr files)
         (lexical-let ((howmany (length files))
                       (aroot (ahg-root)))
           (lambda (process status)
             (if (string= status "finished\n")
                 (with-current-buffer
                     (process-buffer process)
                   (ahg-status-maybe-refresh aroot)
                   (kill-buffer nil)
                   (message "Added/Removed %d files" howmany))
               (ahg-show-error process)))))
      (message "hg addremove aborted"))))


(defun ahg-status-refresh ()
  (interactive)
  (let ((ahg-status-point-pos (ahg-line-point-pos))
        ;;(ahg-status-consider-extra-switches t)
        )
    (call-interactively 'ahg-status)))


(defun ahg-status-maybe-refresh (root)
  (when ahg-auto-refresh-status-buffer
    (let ((buf (ahg-get-status-buffer root)))
      (when buf
        (let ((ahg-status-no-pop t)
              (ahg-status-point-pos
               (with-current-buffer buf (ahg-line-point-pos)))
              ;;(ahg-status-consider-extra-switches t) - not sure about this...
              )
          (ahg-status))))))


(defun ahg-status-diff (askrev &optional all)
  "Shows changes of the current revision wrt. its parent. If ALL is t,
shows changes of all marked files. Otherwise, shows changes of
the file on the current line."
  (interactive "P")
  (let ((files
         (if all (ahg-status-get-marked 'all)
           (let ((n (ewoc-locate ewoc))) (when n (list (ewoc-data n)))))))
    (if files
        (ahg-diff (ahg-rev-id
                   (if askrev
                       (read-string "revision to diff against: "
                                    nil nil ".") "."))
                  nil
                  (mapcar 'cddr files))
      (message "aHg diff: no file selected."))))


(defun ahg-status-diff-ediff (askrev)
  "Shows diff of the working directory version of the current selected file
wrt. its parent revision, using Ediff."
  (interactive "P")
  (let* ((n (ewoc-locate ewoc))
         (filename (when n (cddr (ewoc-data n)))))
    (if filename
        (let ((ahg-diff-revs
               (cons (ahg-rev-id
                      (if askrev
                          (read-string "revision to diff against: "
                                       nil nil ".") "."))
                     nil)))
          (ahg-diff-ediff filename))
      (message "aHg diff: no file selected."))))


(defun ahg-status-diff-all (askrev)
  (interactive "P")
  (ahg-status-diff askrev t))


(defun ahg-status-delete ()
  (interactive)
  (let ((files (ahg-status-get-marked 'cur)))
    (if files
	(if (ahg-y-or-n-p 
	     (if (> (length files) 1)
		 (format "Delete %d files? " (length files))
	       (format "Delete %s? " (cddar files))))
	    (progn
	      (mapc 'delete-file (mapcar 'cddr files))
	      (ahg-status-refresh))
	  (message "delete aborted!"))
      (message "0 files selected, nothing deleted"))))


(defun ahg-status-undo ()
  (interactive)
  (let ((files (ahg-status-get-marked nil)))
    (if (ahg-y-or-n-p
         (if files (format "Undo changes on %d files? " (length files))
           "Undo all changes? "))
        (ahg-generic-command
         "revert" (if files (mapcar 'cddr files) '("--all"))
         (lexical-let ((aroot (ahg-root)))
           (lambda (process status)
             (if (string= status "finished\n")
                 (with-current-buffer
                     (process-buffer process)
                   (ahg-status-maybe-refresh aroot)
                   (kill-buffer nil))
               (ahg-show-error process)))))
      (message "hg revert aborted"))))                         

(defun ahg-revert-cur-file ()
  "Reverts the current file"
  (interactive)
  (cond ((buffer-file-name)
	 (if (ahg-y-or-n-p (concat "Revert " (buffer-file-name)))
	     (ahg-generic-command 
	      "revert" (list (buffer-file-name))
              (lambda (process status)
                (if (string= status "finished\n")
                    (revert-buffer nil t))))
           (message "hg revert aborted")))))

(defun ahg-rm-cur-file ()
  "Runs hg rm on the current file, and kills the current buffer"
  (interactive)
  (when (buffer-file-name)
    (lexical-let ((buffer (current-buffer)))
      (if (ahg-y-or-n-p (concat "hg rm " (buffer-file-name)))
          (ahg-generic-command 
           "rm" (list (buffer-file-name))
           (lambda (process status)
             (if (string= status "finished\n")
                 (kill-buffer buffer))))
        (message "hg rm aborted")))))


(defun ahg-get-status-ewoc (root)
  "Returns an *hg status* buffer for ROOT. The buffer's major mode is
ahg-status, and it has an ewoc associated with it."
  (let ((buf (ahg-get-status-buffer root t))
        (inhibit-read-only t)
        (header (concat
                 (propertize "hg status for " 'face ahg-header-line-face)
                 (propertize root 'face ahg-header-line-root-face) "\n"))
        (footer (concat "\n"
                        (make-string (1- (window-width (selected-window))) ?-)
                        "\n" (ahg-summary-info root))))
    (with-current-buffer buf
      (erase-buffer)
      (let ((ew (ewoc-create 'ahg-status-pp
                             header footer)))
        (ahg-status-mode)
        (set (make-local-variable 'ewoc) ew)
        (setq default-directory (file-name-as-directory root))
        ew))))

(defun ahg-get-status-buffer (&optional root create)
  (unless root (setq root (ahg-root)))
  (let ((name (concat "*hg status: "
                      (file-name-as-directory (expand-file-name root)) "*")))
    (funcall (if create 'get-buffer-create 'get-buffer) name)))

(defvar ahg-status-no-pop nil)
(defvar ahg-status-point-pos nil)

(defun ahg-status-sentinel (process status &optional no-pop point-pos)
  (with-temp-message (or (current-message) "")
    (if (string= status "finished\n")
        ;; everything was ok, we can show the status buffer
        (let* ((buf (process-buffer process))
               (root (with-current-buffer buf ahg-root))
               (ew (ahg-get-status-ewoc root))
               (outbuf (ewoc-buffer ew))
               (cfg (with-current-buffer buf ahg-window-configuration))
               (extra-switches
                (with-current-buffer buf ahg-status-extra-switches))
               (status-line
                (concat "^\\("
                        (mapconcat 'identity
                                   '("M" "A" "R" "C" "!" "?" "I") "\\|")
                        "\\) .+$"))
               warninglines)
          (with-current-buffer buf
            (goto-char (point-min))
            (while (not (eobp))
              (if (looking-at status-line)
                  (ewoc-enter-last
                   ew
                   (cons nil
                         (cons (buffer-substring (point) (1+ (point)))
                               (buffer-substring (+ (point) 2)
                                                 (point-at-eol)))))
                (setq warninglines
                      (cons
                       (concat
                        (buffer-substring (point-at-bol) (point-at-eol))
                        "\n") warninglines)))
              (forward-line 1)))
          (kill-buffer buf)
          (unless no-pop
            (pop-to-buffer outbuf))
          (set (make-local-variable 'ahg-window-configuration) cfg)
          (with-current-buffer outbuf
            (let ((inhibit-read-only t)
                  (node (ewoc-nth ew 0)))
              (when warninglines
                (let ((warn-re (concat "\\("
                                       (mapconcat 'regexp-quote warninglines
                                                  "\\)\\|\\(")
                                       "\\)")))
                  (save-excursion
                    (while (re-search-forward warn-re nil t)
                      (replace-match ""))))
                (save-excursion
                  (re-search-forward "^-+$")
                  (goto-char (point-max))
                  (insert "\n" (match-string 0) "\nWarnings:\n")
                  (mapc 'insert (nreverse warninglines))
                  ))
                (when node (goto-char (ewoc-location node)))))
          (when point-pos
            (with-current-buffer outbuf
              (ahg-goto-line-point point-pos)))
          (with-current-buffer outbuf
            (set (make-local-variable 'ahg-status-extra-switches)
                 extra-switches)))
      ;; error, we signal it and pop to the buffer
      (ahg-show-error process))))


(defun ahg-status-visit-file (&optional other-window)
  (interactive)
  (let* ((node (ewoc-locate ewoc))
         (data (and node (ewoc-data node))))
    (when data
      (if other-window
          (find-file-other-window (cddr data))
        (find-file (cddr data))))))

(defun ahg-status-visit-file-other-window ()
  (interactive)
  (ahg-status-visit-file t))


(defun ahg-status-do-command ()
  (interactive)
  (let ((files (ahg-status-get-marked nil)))
    (if files
        (let ((ahg-do-command-prompt "Hg command on selected files: ")
              (ahg-do-command-extra-args (mapcar 'cddr files)))
          (call-interactively 'ahg-do-command))
      (call-interactively 'ahg-do-command))))

(defun ahg-status-short-log ()
  (interactive)
  (let* ((files (ahg-status-get-marked nil))
         (ahg-file-list-for-log-command (if files (mapcar 'cddr files) nil)))
    (call-interactively 'ahg-short-log)))

(defun ahg-status-log ()
  (interactive)
  (let* ((files (ahg-status-get-marked nil))
         (ahg-file-list-for-log-command (if files (mapcar 'cddr files) nil)))
    (call-interactively 'ahg-log)))


(defun ahg-status-glog ()
  (interactive)
  (let* ((files (ahg-status-get-marked nil))
         (ahg-file-list-for-log-command (if files (mapcar 'cddr files) nil)))
    (call-interactively 'ahg-glog)))


(defun ahg-status-shell-command (command files refresh)
  "Run a shell command COMMAND on the marked files.
If there are no marked files, run COMMAND on the file at point.
This function uses `dired-do-shell-command' to do the work, and
so it supports the special meaning of `*' and `?' in COMMAND.
See the help for `dired-do-shell-command' for details.
If REFRESH is non-nil, refresh the status buffer after executing COMMAND.
When called interactively, REFRESH is non-nil if a prefix argument is given."
  (interactive
   (let ((fnames (ahg-status-get-marked 'cur)))
     (list
      (let ((minibuffer-local-completion-map
             (copy-keymap minibuffer-local-map)))
        (define-key minibuffer-local-completion-map "\t"
          'minibuffer-complete)
        (completing-read
         (apply 'format "Shell command on %s file%s: "
                (if (and (= (length fnames) 1) (null (caar fnames)))
                    (list "current" (format " (%s)" (cddar fnames)))
                  '("selected" "s")))
         (ahg-dynamic-completion-table ahg-complete-shell-command)))
      (mapcar 'cddr fnames)
      (if ahg-auto-refresh-status-buffer
          (not current-prefix-arg) current-prefix-arg))))
  (dired-do-shell-command command nil files)
  (when refresh (ahg-status-refresh)))


(defun ahg-status-dired-find (files)
  "Show the highlighted files in a dired buffer.
Uses find-dired to get them into nicely."
  (interactive (list (ahg-status-get-marked 'cur)))
  (find-dired
   default-directory
   (concat
    (mapconcat
     (lambda (f)
       (concat "-path \"*/" (cddr f) "\" -or"))
     files " ")
    " -false")))


(defun ahg-status-add-to-hgignore ()
  "Adds the selected files to .hgignore for the current repository."
  (interactive)
  (let ((files (ahg-status-get-marked 'cur)))
    (when (ahg-y-or-n-p (format "Add %d files to .hgignore? " (length files)))
      (let* ((aroot (ahg-root))
             (hgignore (concat (file-name-as-directory aroot) ".hgignore")))
        (with-temp-buffer
          (when (file-exists-p hgignore)
            (insert-file-contents hgignore))
          (goto-char (point-max))
          (insert "\n# added by aHg on " (current-time-string)
                  "\nsyntax: glob\n")
          (mapc (lambda (f) (insert (cddr f) "\n")) files)
          (write-file hgignore)
          (kill-buffer))
        (ahg-status-maybe-refresh aroot)))))


(defun ahg-status-next-file ()
  "Move to the next file in an ahg-status buffer."
  (interactive)
  (let* ((cur (ewoc-locate ewoc))
         (node (and cur (ewoc-next ewoc cur))))
    (when node
      (goto-char (ewoc-location node)))))


(defun ahg-status-prev-file ()
  "Move to the previous file in an ahg-status buffer."
  (interactive)
  (let* ((cur (ewoc-locate ewoc))
         (node (and cur (ewoc-prev ewoc cur))))
    (when node
      (goto-char (ewoc-location node)))))


;;-----------------------------------------------------------------------------
;; hg commit
;;-----------------------------------------------------------------------------

(defun ahg-commit-callback (extra-args)
  (lexical-let ((extra-args extra-args))
    (lambda ()
      (interactive)
      (let ((msg (ahg-parse-commit-message)))
        (let ((args (append (list "-m" msg) extra-args
                            (log-edit-files))))
          (ahg-generic-command
           "commit" args
           (lexical-let ((aroot (ahg-root))
                         (n (length (log-edit-files))))
             (lambda (process status)
               (if (string= status "finished\n")
                   (progn
                     (ahg-status-maybe-refresh aroot)
                     (message "Successfully committed %s."
                              (if (> n 0)
                                  (format "%d file%s" n (if (> n 1) "s" ""))
                                "all modified files"))
                     (kill-buffer (process-buffer process)))
                 (ahg-show-error process)))))))
      (kill-buffer (current-buffer)))))

(defun ahg-commit (files &optional msg logmsg extra-args)
  "Run hg commit. Pops up a buffer for editing the log file."
  (let ((buf (generate-new-buffer "*aHg-log*")))
    (ahg-log-edit
     (ahg-commit-callback extra-args)
     (lexical-let ((flist files)) (lambda () flist))
     buf
     msg
     logmsg)))

(defun ahg-commit-cur-file ()
  "Run hg commit on the current file only."
  (interactive)
  (cond ((eq major-mode 'ahg-status-mode)
         (call-interactively 'ahg-status-commit))
        ((buffer-file-name)
         (when (and (buffer-modified-p)
                    (ahg-y-or-n-p "Save buffer before committing? "))
           (save-buffer))
         (ahg-commit (list (buffer-file-name))))
        (t (message "hg commit: no file found, aborting."))))

;;-----------------------------------------------------------------------------
;; hg update
;;-----------------------------------------------------------------------------

(defvar ahg-update-to-rev-get-revision-function nil)
(defvar ahg-update-to-rev-check-bookmarks nil)
(defvar ahg-update-to-rev-refresh-function nil)

(defun ahg-update-to-rev (rev force)
  "Update to the given revision. If force is non-nil, pass -C
flag to hg update."
  (interactive
   (let* ((rev (funcall ahg-update-to-rev-get-revision-function))
          (ans (and rev (ahg-y-or-n-p (format "Update to revision %s? " rev))))
          (overw (and ans (if (ahg-uncommitted-changes-p)
                              (ahg-y-or-n-p "Overwrite local changes? ")
                            t))))
     (list (and ans rev) overw)))
  (when rev
    (let ((args (if force (list "-C" "-r" rev) (list "-r" rev))))
      ;; check if there is a bookmark
      (when ahg-update-to-rev-check-bookmarks
        (let* ((bmarks (ahg-get-bookmarks rev))
               (n (length bmarks)))
          (cond ((= n 1)
                 (let ((bm (car bmarks)))
                   (message "Activating bookmark %s" bm)
                   (setq args (if force (list "-C" bm) (list bm)))))
                ((> n 1)
                 (message "Warning: more than 1 bookmark at rev %s, not making any of them active" rev)))))
      (ahg-generic-command
       "update" args
       (lexical-let ((aroot default-directory)
                     (rev rev)
                     (refresh (or ahg-update-to-rev-refresh-function
                                  (symbol-function 'ahg-status-maybe-refresh))))
         (lambda (process status)
           (if (string= status "finished\n")
               (progn
                 (funcall refresh aroot)
                 (message "Updated to revision %s" rev)
                 (kill-buffer (process-buffer process)))
             (ahg-show-error process))))))))


;;-----------------------------------------------------------------------------
;; hg log
;;-----------------------------------------------------------------------------

(defvar ahg-log-commands-map
  '(
    ("l" . ahg-short-log)
    ("L" . ahg-log)
    ("G" . ahg-glog)
    ("H" . ahg-heads)
    ("T" . ahg-tags)
    ("B" . ahg-bookmarks)
    ))

(defun ahg-add-log-commands (map)
  (mapc
   (lexical-let ((map map))
     (lambda (p)
       (define-key map (car p) (cdr p))))
   ahg-log-commands-map
   ))


(defvar ahg-short-log-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [?g] 'ahg-short-log-refresh)
    (define-key map [?s] 'ahg-status)
    (define-key map [?=] 'ahg-short-log-view-diff)
    (define-key map [?D] 'ahg-short-log-view-diff-select-rev)
    (define-key map [? ] 'ahg-short-log-view-details)
    (define-key map [?\r] 'ahg-short-log-update-to-rev)
    (define-key map [?r] 'ahg-short-log-goto-revision)
    (define-key map [?n] 'ahg-short-log-next)
    (define-key map [?p] 'ahg-short-log-previous)
    (define-key map [?q] 'ahg-buffer-quit)
    (define-key map [?!] 'ahg-do-command)
    (define-key map [?h] 'ahg-command-help)
    (let ((emap (make-sparse-keymap)))
      (define-key emap "m" 'ahg-short-log-histedit-mess)
      (define-key emap "d" 'ahg-short-log-histedit-drop)
      (define-key emap "x" 'ahg-short-log-histedit-xtract)
      (define-key emap "f" 'ahg-short-log-histedit-fold)
      (define-key emap "r" 'ahg-short-log-histedit-roll)
      (define-key map "E" emap))
    (ahg-add-log-commands map)
    map)
  "Keymap used in `ahg-short-log-mode'.")

(defvar ahg-short-log-line-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] 'ahg-short-log-view-details-mouse)
    (define-key map [mouse-2] 'ahg-short-log-view-diff-mouse)
    map))

;; (defvar ahg-short-log-revision-face font-lock-function-name-face)
;; (defvar ahg-short-log-date-face font-lock-string-face)
;; (defvar ahg-short-log-user-face font-lock-type-face)

(defconst ahg-short-log-start-regexp "^ +\\([0-9]+\\) |")

(define-derived-mode ahg-short-log-mode special-mode "ahg-short-log"
  "Major mode to display hg shortlog output.

Commands:
\\{ahg-short-log-mode-map}
"
  (buffer-disable-undo) ;; undo info not needed here
  (use-local-map ahg-short-log-mode-map)
  (font-lock-mode nil)
;;  (hl-line-mode t)
  (easy-menu-add ahg-short-log-mode-menu ahg-short-log-mode-map))

(easy-menu-define ahg-short-log-mode-menu ahg-short-log-mode-map "aHg Short Log"
  '("aHg Short Log"
    ["View Revision Diff" ahg-short-log-view-diff [:keys "=" :active t]]
    ["View Revision Diff with Other..." ahg-short-log-view-diff-select-rev
     [:keys "D" :active t]]
    ["View Revision Details" ahg-short-log-view-details [:keys " " :active t]]
    ["Update to Revision" ahg-short-log-update-to-rev [:keys "\r" :active t]]
    ["--" nil nil]
    ["Status" ahg-status [:keys "s" :active t]]
    ["Hg Command" ahg-do-command [:keys "!" :active t]]
    ["--" nil nil]
    ["Next Revision" ahg-short-log-next [:keys "n" :active t]]
    ["Previous Revision" ahg-short-log-previous [:keys "p" :active t]]
    ["Go to Revision..." ahg-short-log-goto-revision [:keys "r" :active t]]
    ["--" nil nil]
    ("History Editing"
     ["Edit Changeset Message" ahg-short-log-histedit-mess [:keys "Em" :active t]]
     ["Drop Changeset" ahg-short-log-histedit-drop [:keys "Ed" :active t]]
     ["Extract Changeset" ahg-short-log-histedit-xtract [:keys "Ex" :active t]]
     ["Fold Changeset" ahg-short-log-histedit-fold [:keys "Ef" :active t]]
     ["Roll Changeset" ahg-short-log-histedit-roll [:keys "Er" :active t]])
    ["--" nil nil]
    ["Help on Hg Command" ahg-command-help [:keys "h" :active t]]
    ["--" nil nil]
    ["Refresh" ahg-short-log-refresh [:keys "g" :active t]]
    ["Quit" ahg-buffer-quit [:keys "q" :active t]]
    ))


(defun ahg-short-log-propertize (s)
  (propertize s 'mouse-face 'highlight
              'keymap ahg-short-log-line-map))

(defun ahg-short-log-pp (data)
  "Pretty-printer for short log revisions."
  ;; data is a 4-elements list
  (let ((trim (lambda (n s) (if (> (length s) n) (substring s 0 n) s))))
    (let* ((width (window-width (selected-window)))
           (p1 (car data))
           (p2 (cadr data))
           (p3 (caddr data))
           (p4 (cadddr data))
           (s (format "%7s | %s | %8s | %s"
                      (propertize p1 'face ahg-short-log-revision-face)
                      (propertize p2 'face ahg-short-log-date-face)
                      (propertize (funcall trim 8 p3)
                                  'face ahg-short-log-user-face)
                      p4))
           (pad (if (< (length s) width)
                    (make-string (- width (length s)) ? )
                  "")))
      (insert (propertize (ahg-short-log-propertize (concat s pad))
                          'help-echo p4)))))
        
(defun ahg-short-log-insert-contents (ewoc contents)
  (let ((lines (split-string contents "\n")))
    (let ((format-line (lambda (line)
               (if (and line (> (length line) 0))
                    (let* ((p1 (string-match " " line))
                           (p2 (string-match " " line (1+ p1)))
                           (p3 (string-match " " line (1+ p2)))
                           (data (list
                                  (substring line 0 p1)
                                  (substring line (1+ p1) p2)
                                  (substring line (1+ p2) p3)
                                  (substring line (1+ p3)))))
                      (ewoc-enter-last ewoc data))))))
      (mapcar format-line lines))))


(defun ahg-short-log-next (n)
  "Move to the next changeset line"
  (interactive "p")
  (ewoc-goto-next ewoc n))

(defun ahg-short-log-previous (n)
  "Move to the previous changeset line"
  (interactive "p")
  (ewoc-goto-prev ewoc n))

(defun ahg-short-log-revision-at-point ()
  (let ((node (ewoc-locate ewoc)))
    (and node (car (ewoc-data node)))))

(defun ahg-short-log-view-diff ()
  (interactive)
  (let* ((r1 (ahg-short-log-revision-at-point))
         (r2 (ahg-first-parent-of-rev r1)))
    (ahg-diff r2 r1)))

(defun ahg-short-log-view-diff-select-rev (rev)
  (interactive "sEnter revision to compare against: ")
  (let ((r1 (ahg-short-log-revision-at-point))
        (r2 rev))
    (ahg-diff r2 r1)))

(defun ahg-short-log-view-details ()
  "View details of the given revision."
  (interactive)
  (let ((rev (ahg-short-log-revision-at-point)))
    (ahg-log rev nil)))


(defun ahg-short-log-view-details-mouse (event)
  (interactive "e")
  (save-window-excursion
    (select-window (posn-window (event-end event)) t)
    (goto-char (posn-point (event-end event)))
    (ahg-short-log-view-details)))


(defun ahg-short-log-view-diff-mouse (event)
  (interactive "e")
  (save-window-excursion
    (select-window (posn-window (event-end event)) t)
    (goto-char (posn-point (event-end event)))
    (ahg-short-log-view-diff)))


(defun ahg-short-log-goto-revision (rev)
  "Move point to the revision REV. If REV is not found in the log buffer,
do nothing."
  (interactive "P")
  (when (called-interactively-p 'interactive)
    (unless rev
      (setq rev (read-string "Goto revision: "))))
  (let ((n (ewoc-nth ewoc 0)))
    (while (and n (not (string= rev (car (ewoc-data n)))))
      (setq n (ewoc-next ewoc n)))
    (when n (ewoc-goto-node ewoc n))))


(defun ahg-short-log-update-to-rev ()
  (interactive)
  (let ((ahg-update-to-rev-get-revision-function
         'ahg-short-log-revision-at-point)
        (ahg-update-to-rev-check-bookmarks t)
        (ahg-update-to-rev-refresh-function
         (lexical-let ((buf (current-buffer)))
           (lambda (root)
             (with-current-buffer buf
               (let ((inhibit-read-only t))
                 (save-excursion
                   (let ((n (ewoc-nth ewoc 0)) done)
                     (while (and n (not done))
                       (goto-char (ewoc-location n))
                       (if (re-search-forward
                            "^ *[0-9]+\\*" (point-at-eol) t)
                           (progn
                             (setq done t)
                             (delete-char -1)
                             (insert " "))
                         (setq n (ewoc-next ewoc n))))))
                 (save-excursion
                   (beginning-of-line)
                   (forward-word 1)
                   (insert ahg-short-log-active-rev-marker)
                   (delete-char 1))))
             (ahg-status-maybe-refresh root)))))
    (call-interactively 'ahg-update-to-rev)))


(defun ahg-args-add-revs (r1 r2 &optional disjoint)
  (let (command-list)
    (when r1
      (when (numberp r1)
        (setq r1 (number-to-string r1))))
    (when r2
      (when (numberp r2)
        (setq r2 (number-to-string r2))))
    (cond ((and r1 r2 (> (length r1) 0) (> (length r2) 0))
           (setq command-list
                 (if disjoint
                     (append command-list (list "-r" r1 "-r" r2))
                   (append command-list (list "-r" (format "%s:%s" r1 r2))))))
          ((and r1 (> (length r1) 0)) (setq command-list
                                 (append command-list (list "-r" r1))))
          ((and r2 (> (length r2) 0)) (setq command-list
                                            (append command-list
                                                    (list "-r" r2)))))
    command-list))


(defun ahg-maybe-revset (rev)
  (not (null (string-match "[:()]" rev))))


;; helper function used by ahg-short-log, ahg-log and ahg-log-cur-file to
;; get arguments from the user
(defvar ahg-log-default-revisions '("tip" . "0"))
(defvar ahg-log-default-extra-flags "")
(defun ahg-log-read-args (is-on-selected-files read-extra-flags
                                               &optional reverse)
  (let* ((firstrev
          (read-string
           (concat "hg log"
                   (if is-on-selected-files " (on selected files)" "") ", R1: ")
           (car ahg-log-default-revisions)))
         (is-revset (ahg-maybe-revset firstrev))
         (firstarg-to-save firstrev)
         (retval
          (append
           (list
            (progn
              (when (not is-revset)
                (setq firstrev (format "ancestors(%s)" firstrev)))
              (let* ((deflimit (number-to-string
                                (* (if is-revset 1 -1) ahg-log-revrange-size)))
                     (slimit (read-string
                              (if is-revset
                                  (format "hg log, limit (default %s): "
                                          deflimit)
                                (concat
                                 "hg log"
                                 (if is-on-selected-files
                                     " (on selected files)" "") ", R2: "))
                              (unless is-revset deflimit) nil deflimit))
                     (limit (string-to-number slimit)))
                (cond ((and (not is-revset)
                            (= limit 0) (not (string= slimit "0")))
                       (setq firstrev
                             (format "descendants(%s) & %s" slimit firstrev)))
                      ((and (not is-revset) (> limit 0))
                       (setq firstrev
                             (format "descendants(%s) & %s" slimit firstrev)))
                      ((if is-revset (< limit 0) (> limit 0))
                       (setq firstrev
                             (format "first(%s,%s)" firstrev (abs limit))))
                      ((if is-revset (> limit 0) (< limit 0))
                       (setq firstrev
                             (format "last(%s,%s)" firstrev
                                     (abs limit)))))
                (if reverse firstrev (format "reverse(%s)" firstrev))))
            nil)
           (when read-extra-flags
             (list (read-string
                    (concat "hg log"
                            (if is-on-selected-files " (on selected files)" "")
                            ", extra switches: ")
                    ahg-log-default-extra-flags))))))
    ;; remember the values entered for the next call
    (setq ahg-log-default-revisions (cons firstarg-to-save (cadr retval)))
    (when read-extra-flags
      (setq ahg-log-default-extra-flags (caddr retval)))
    retval))

(defun ahg-log-revrange-end ()
  (with-temp-buffer
    (if (= (ahg-call-process "id" (list "-n")) 0)
        (let ((n (string-to-number (buffer-string))))
          (if (> n ahg-log-revrange-size)
              (format "-%s" ahg-log-revrange-size)
            "0"))
      "0")))


(defun ahg-short-log-create-ewoc (header-prefix last-colunm-title root)
  (let* ((width (window-width (selected-window)))
         (header (concat
                  (propertize (concat header-prefix " for ")
                              'face ahg-header-line-face)
                  (propertize root 'face ahg-header-line-root-face)
                  "\n\n" (propertize (make-string width ?-) 'face 'bold) "\n"
                  (propertize
                   (concat "    Rev |    Date    |  Author  | "
                           last-colunm-title "\n")
                   'face 'bold)
                  (propertize (make-string width ?-) 'face 'bold)))
         (footer (propertize (make-string width ?-) 'face 'bold))
         (ew (ewoc-create 'ahg-short-log-pp header footer)))
    ew))

(defvar ahg-file-list-for-log-command nil)
(defconst ahg-short-log-active-rev-marker (ahg-short-log-propertize
                                           (propertize "*" 'face 'bold)))

(defun ahg-do-short-log (root buffer-name-prefix last-colunm-title command-list)
  (let* ((buffer (get-buffer-create
                  (concat "*" buffer-name-prefix ": " root "*"))))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (ahg-cd root)
        (ahg-push-window-configuration)))
    (ahg-generic-command
     "log" command-list
     (lexical-let ((root root)
                   (buffer-name-prefix buffer-name-prefix)
                   (last-column-title last-column-title)
                   (command-list command-list))
       (lambda (process status)
         (if (string= status "finished\n")
             (with-current-buffer (process-buffer process)
               (pop-to-buffer (current-buffer))
               (ahg-short-log-mode)
               (let ((contents (buffer-substring-no-properties
                                (point-min) (point-max)))
                     (inhibit-read-only t))
                 (erase-buffer)
                 (setq truncate-lines t)
                 (set (make-local-variable 'ahg-short-log-data)
                      (list buffer-name-prefix last-column-title command-list))
                 (let* ((ew (ahg-short-log-create-ewoc
                             buffer-name-prefix last-column-title root))
                        (rev (ahg-rev-id "." "{rev}"))
                        (revre (if rev (concat "^ *" (regexp-quote rev)) ""))
                        (done (null rev)))
                   (ahg-short-log-insert-contents ew contents)
                   (ahg-goto-line 6)
                   (beginning-of-line)
                   (save-excursion
                     (while (and (not done) (not (eobp)))
                       (if (looking-at revre)
                           (progn
                             (setq done t)
                             (forward-word 1)
                             (delete-char 1)
                             (insert ahg-short-log-active-rev-marker))
                         (forward-line 1))))
                   (setq buffer-read-only t)
                   (set (make-local-variable 'ewoc) ew))))
         (ahg-show-error process))))
     buffer)))
  

(defun ahg-short-log-impl (buffer-name-prefix template-extra last-column-title
                           r1 r2 extra-flags)
  (let ((root (ahg-root))
        (command-list (ahg-args-add-revs r1 r2)))
    (setq command-list
          (append command-list
                  (list "--template"
                        (concat "{rev} {date|shortdate} {author|user} "
                                template-extra
                                "\\n"))
                  (when extra-flags (split-string extra-flags))))
    (when ahg-file-list-for-log-command
      (setq command-list (append command-list ahg-file-list-for-log-command)))
    (ahg-do-short-log root buffer-name-prefix last-column-title command-list)))


(defun ahg-short-log (r1 r2 &optional extra-flags)
  "Run hg log, in a compressed format.
This displays the log in a tabular view, one line per
changeset. The format of each line is: Revision | Date | User | Summary.
R1 and R2 specify the range of revisions to
consider. When run interactively, the user must enter their
values (which default to tip for R1 and 0 for R2). If called with
a prefix argument, prompts also for EXTRA-FLAGS."
  (interactive
   (ahg-log-read-args ahg-file-list-for-log-command current-prefix-arg))
  (ahg-short-log-impl "hg log (summary)" "{desc|firstline}" "Summary"
                      r1 r2 extra-flags))


(defun ahg-short-log-histedit-mess ()
  "Edit the commit message of the given revision."
  (interactive)
  (let ((rev (ahg-short-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Edit commit message of revision %s? " rev))
      (ahg-histedit-mess rev))))

(defun ahg-short-log-histedit-drop ()
  "Drop the given revision from history."
  (interactive)
  (let ((rev (ahg-short-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Drop revision %s? " rev))
      (ahg-histedit-drop rev))))

(defun ahg-short-log-histedit-xtract ()
  "Extract the given revision from history."
  (interactive)
  (let ((rev (ahg-short-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Extract revision %s? " rev))
      (ahg-histedit-xtract rev))))

(defun ahg-short-log-histedit-fold ()
  "Fold the given revision with its parent."
  (interactive)
  (let ((rev (ahg-short-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Fold revision %s? " rev))
      (ahg-histedit-fold rev))))

(defun ahg-short-log-histedit-roll ()
  "Fold the given revision with its parent, using the parent's commit message."
  (interactive)
  (let ((rev (ahg-short-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Roll revision %s? " rev))
      (ahg-histedit-roll rev))))

(defun ahg-short-log-refresh ()
  (interactive)
  (if (boundp 'ahg-short-log-data)
      (let ((buffer-name-prefix (nth 0 ahg-short-log-data))
            (last-column-title (nth 1 ahg-short-log-data))
            (command-list (nth 2 ahg-short-log-data)))
        (ahg-do-short-log (ahg-root)
                          buffer-name-prefix last-column-title command-list))
    (call-interactively 'ahg-short-log)))


(defvar ahg-log-font-lock-keywords
  '(("^hg \\<[a-z]+\\> for" . ahg-header-line-face)
    ("^hg \\<[a-z]+\\> for \\(.*\\)" 1 ahg-header-line-root-face)
    ("^changeset:" . ahg-log-field-face)
    ("^svn:" . ahg-log-field-face)
    ("^git:" . ahg-log-field-face)
    ("^phase:" . ahg-log-field-face)
    ("^tag:" . ahg-log-field-face)
    ("^bookmark:" . ahg-log-field-face)
    ("^user:" . ahg-log-field-face)
    ("^date:" . ahg-log-field-face)
    ("^summary:" . ahg-log-field-face)
    ("^files:" . ahg-log-field-face)
    ("^branch:" . ahg-log-field-face)
    ("^parent:" . ahg-log-field-face)
    ("^description:" . ahg-log-field-face)
    ("^\\(changeset\\|parent\\): +\\(.+\\)$" 2 ahg-log-revision-face)
    ("^\\(tag\\|branch\\|bookmark\\): +\\(.+\\)$" 2 ahg-log-branch-face)
    ("^phase: +\\(draft\\)$" 1 ahg-log-phase-draft-face)
    ("^phase: +\\(secret\\)$" 1 ahg-log-phase-secret-face)
    ("^user: +\\(.+\\)$" 1 ahg-short-log-user-face)
    ("^date: +\\(.+\\)$" 1 ahg-short-log-date-face)
    )
  "Keywords in `ahg-log-mode' mode.")

(define-derived-mode ahg-log-mode special-mode "ahg-log"
  "Major mode to display hg log output.

Commands:
\\{ahg-log-mode-map}
"
  (buffer-disable-undo) ;; undo info not needed here
  (setq buffer-read-only t)
  (define-key ahg-log-mode-map [?g] 'ahg-log)
  (define-key ahg-log-mode-map [?s] 'ahg-status)
  (define-key ahg-log-mode-map [?=] 'ahg-log-view-diff)
  (define-key ahg-log-mode-map [?D] 'ahg-log-view-diff-select-rev)
  (define-key ahg-log-mode-map [?n] 'ahg-log-next)
  (define-key ahg-log-mode-map "\t" 'ahg-log-next)
  (define-key ahg-log-mode-map [?p] 'ahg-log-previous)
  (define-key ahg-log-mode-map [S-iso-lefttab] 'ahg-log-previous)
  (define-key ahg-log-mode-map [?q] 'ahg-buffer-quit)
  (define-key ahg-log-mode-map [?!] 'ahg-do-command)
  (define-key ahg-log-mode-map [?h] 'ahg-command-help)
  (define-key ahg-log-mode-map "\r" 'ahg-log-update-to-rev)
  (let ((emap (make-sparse-keymap)))
    (define-key emap "m" 'ahg-log-histedit-mess)
    (define-key emap "d" 'ahg-log-histedit-drop)
    (define-key emap "x" 'ahg-log-histedit-xtract)
    (define-key emap "f" 'ahg-log-histedit-fold)
    (define-key emap "r" 'ahg-log-histedit-roll)
    (define-key ahg-log-mode-map "E" emap))
  (ahg-add-log-commands ahg-log-mode-map)
  (set (make-local-variable 'font-lock-defaults)
       (list 'ahg-log-font-lock-keywords t nil nil))
  (easy-menu-add ahg-log-mode-menu ahg-log-mode-map))

(easy-menu-define ahg-log-mode-menu ahg-log-mode-map "aHg Log"
  '("aHg Log"
    ["View Revision Diff" ahg-log-view-diff [:keys "=" :active t]]
    ["View Revision Diff with Other..." ahg-log-view-diff-select-rev
     [:keys "D" :active t]]
    ["Update to Revision" ahg-log-update-to-rev [:keys "\r" :active t]]
    ["--" nil nil]
    ["Status" ahg-status [:keys "s" :active t]]
    ["Hg Command" ahg-do-command [:keys "!" :active t]]
    ["--" nil nil]
    ["Next Revision" ahg-log-next [:keys "\t" :active t]]
    ["Previous Revision" ahg-log-previous [:keys "p" :active t]]
    ["--" nil nil]
    ("History Editing"
     ["Edit Changeset Message" ahg-log-histedit-mess [:keys "Em" :active t]]
     ["Drop Changeset" ahg-log-histedit-drop [:keys "Ed" :active t]]
     ["Extract Changeset" ahg-log-histedit-xtract [:keys "Ex" :active t]]
     ["Fold Changeset" ahg-log-histedit-fold [:keys "Ef" :active t]]
     ["Roll Changeset" ahg-log-histedit-roll [:keys "Er" :active t]])
    ["--" nil nil]
    ["Help on Hg Command" ahg-command-help [:keys "h" :active t]]
    ["--" nil nil]
    ["Refresh" ahg-log [:keys "g" :active t]]
    ["Quit" ahg-buffer-quit [:keys "q" :active t]]
    ))


(defconst ahg-log-start-regexp "^changeset: +\\([0-9]+:[0-9a-f]+\\)")
(defun ahg-log-next (n)
  "Move to the next changeset header of the next diff hunk"
  (interactive "p")
  (end-of-line)
  (re-search-forward ahg-log-start-regexp nil t n)
  (beginning-of-line))

(defun ahg-log-previous (n)
  "Move to the previous changeset header of the previous diff hunk"
  (interactive "p")
  (end-of-line)
  (re-search-backward ahg-log-start-regexp)
  (re-search-backward ahg-log-start-regexp nil t n))

(defun ahg-log-view-diff ()
  (interactive)
  (let* ((r1 (ahg-log-revision-at-point t))
         (r2 (ahg-first-parent-of-rev r1)))
    (ahg-diff r2 r1)))

(defun ahg-log-view-diff-select-rev (rev)
  (interactive "sEnter revision to compare against: ")
  (let ((r1 (ahg-log-revision-at-point t))
        (r2 rev))
    (ahg-diff r2 r1)))

(defun ahg-log-revision-at-point (&optional short-id)
  (save-excursion
    (end-of-line)
    (re-search-backward ahg-log-start-regexp)
    (let ((rev (match-string-no-properties 1)))
      (when rev
        (if short-id (car (split-string rev ":"))
          (cadr (split-string rev ":")))))))


(defun ahg-log-goto-revision (rev)
  "Move point to the revision REV. If REV is not found in the log
buffer, do nothing."
  (let ((rev-pos))
    (save-excursion
      (when
          (re-search-forward (concat "^changeset: +" rev) nil t)
        (setq rev-pos (point))))
    (when rev-pos
      (goto-char rev-pos))))

(defvar ahg-dir-name-for-log-command nil)

(defconst ahg-log-style-map
  "changeset = \"{rev}:{node|short}\\n{svnrev}\\n{gitnode}\\n{phase}\\n{branches}\\n{tags}\\n{bookmarks}\\n{parents}\\n{author}\\n{date|date}\\n{files}\\n\\t{desc|tabindent}\\n\"
file = \"{file}\\n\"
")

(defun ahg-log-prepare-style-map (root)
  (let ((f (concat (file-name-as-directory root) ".hg/ahg-log-style-map")))
    (with-temp-file f
      (insert ahg-log-style-map))
    (file-relative-name f root)))
  
(defun ahg-log (r1 r2 &optional extra-flags)
  "Run hg log. R1 and R2 specify the range of revisions to
consider. When run interactively, the user must enter their
values (which default to tip for R1 and 0 for R2). If called with
a prefix argument, prompts also for EXTRA-FLAGS."
  (interactive
   (ahg-log-read-args ahg-file-list-for-log-command current-prefix-arg))
  (let* ((root (ahg-root))
         (buffer (get-buffer-create
                  (concat "*hg log (details): " root "*")))
         (command-list (ahg-args-add-revs r1 r2))
         (ahgstyle (ahg-log-prepare-style-map root))
         (default-directory root))
    (setq command-list (append command-list
                               (list "--style" ahgstyle)
                               (when extra-flags (split-string extra-flags))))
    (when ahg-file-list-for-log-command
      (setq command-list (append command-list ahg-file-list-for-log-command)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (ahg-cd root)
        (ahg-push-window-configuration)))
    (ahg-generic-command
     "log" command-list
     (lexical-let ((dn (or ahg-dir-name-for-log-command
                           root))
                   (ahgstyle ahgstyle))
       (lambda (process status)
         (if (string= status "finished\n")
             (progn
               (pop-to-buffer (process-buffer process))
               (ahg-format-log-buffer)
               (ahg-log-mode)
               (goto-char (point-min))
               (let ((inhibit-read-only t))
                 (insert
                  (propertize "hg log for " 'face ahg-header-line-face)
                  (propertize dn 'face ahg-header-line-root-face)
                  "\n\n")))
           (ahg-show-error process))))
     buffer)))

(defvar ahg-log-file-line-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-2]
      (lambda (event)
        (interactive "e")
        (select-window (posn-window (event-end event)) t)
        (goto-char (posn-point (event-end event)))
        (let ((fn (ahg-log-filename-at-point (point))))
          (when (file-exists-p fn)
            (find-file-other-window fn)))))
    (define-key map [S-mouse-2]
      (lambda (event)
        (interactive "e")
        (select-window (posn-window (event-end event)) t)
        (let ((pt (posn-point (event-end event))))
          (goto-char pt)
          (let* ((r1 (ahg-log-revision-at-point t))
                 (r2 (ahg-first-parent-of-rev r1))
                 (fn (ahg-log-filename-at-point pt t)))
            (ahg-diff r2 r1 (list fn))))))
    (define-key map "f"
      (lambda ()
        (interactive)
        (let ((fn (ahg-log-filename-at-point (point))))
          (if (file-exists-p fn)
              (find-file fn)
            (message "file not found: %s" fn)))))
    (define-key map "o"
      (lambda ()
        (interactive)
        (let ((fn (ahg-log-filename-at-point (point))))
          (if (file-exists-p fn)
              (find-file-other-window fn)
            (message "file not found: %s" fn)))))
    (define-key map "="
      (lambda ()
        (interactive)
          (let* ((r1 (ahg-log-revision-at-point t))
                 (r2 (ahg-first-parent-of-rev r1))
                 (fn (ahg-log-filename-at-point (point) t)))
            (ahg-diff r2 r1 (list fn)))))
    (define-key map "D"
      (lambda (rev)
        (interactive "sEnter revision to compare against: ")
          (let* ((r1 (ahg-log-revision-at-point t))
                 (r2 rev)
                 (fn (ahg-log-filename-at-point (point) t)))
            (ahg-diff r2 r1 (list fn)))))
    (define-key map "e"
      (lambda ()
        (interactive)
          (let* ((r1 (ahg-log-revision-at-point t))
                 (r2 (ahg-first-parent-of-rev r1))
                 (fn (ahg-log-filename-at-point (point) t)))
            (let ((ahg-diff-revs (cons (ahg-rev-id r1) (ahg-rev-id r2))))
              (ahg-diff-ediff fn)))))
    map))

(defun ahg-log-filename-at-point (point &optional relative)
  (interactive "d")
  (let ((fn 
         (save-excursion
           (goto-char point)
           (buffer-substring-no-properties
            (+ 13 ;; (length "             ")
               (point-at-bol))
            (point-at-eol)))))
    (if relative
        fn
      (ahg-abspath fn))))

(defun ahg-format-log-buffer ()
  (goto-char (point-min))
  (let ((inhibit-read-only t))
    (let ((next (lambda () (beginning-of-line) (forward-line 1))))
      (while (not (eobp))
        ;; changeset
        (insert "changeset:   ")
        (funcall next)
        ;; svn rev
        (if (looking-at "^$")
            (delete-char 1)
          (insert "svn:         ")
          (funcall next))
        ;; git hash
        (if (looking-at "^$")
            (delete-char 1)
          (insert "git:         ")
          (funcall next))
        ;; phase
        (if (looking-at "^public$")
            (let ((kill-whole-line t))
              (kill-line))
          (insert "phase:       ")
          (funcall next))
        ;; branch
        (if (looking-at "^$")
            (delete-char 1)
          (insert "branch:      ")
          (funcall next))
        ;; tags
        (if (looking-at "^$")
            (delete-char 1) ;; remove empty line
          ;; otherwise, insert a "tag: " entry for each entry in the list
          (let ((tags (split-string (buffer-substring-no-properties
                                     (point-at-bol) (point-at-eol))))
                (kill-whole-line t))
            (kill-line)
            (mapc (lambda (tag) (insert "tag:         " tag "\n")) tags)))
        ;; bookmarks
        (if (looking-at "^$")
            (delete-char 1) ;; remove empty line
          ;; otherwise, insert a "bookmark: " entry for each entry in the list
          (let ((tags (split-string (buffer-substring-no-properties
                                     (point-at-bol) (point-at-eol))))
                (kill-whole-line t))
            (kill-line)
            (mapc (lambda (tag) (insert "bookmark:    " tag "\n")) tags)))
        ;; parents
        (if (looking-at "^$")
            (delete-char 1) 
          (let ((parents (split-string (buffer-substring-no-properties
                                        (point-at-bol) (point-at-eol))))
                (kill-whole-line t))
            (kill-line)
            (mapc (lambda (p) (insert "parent:      " p "\n")) parents)))
        ;; user
        (insert "user:        ")
        (funcall next)
        ;; date
        (insert "date:        ")
        (funcall next)
        ;; files, until an empty line is found
        (unless (looking-at "^$")
          (set-text-properties (point-at-bol) (point-at-eol)
                               (list 'mouse-face 'highlight
                                     'keymap ahg-log-file-line-map))
          (insert "files:       ")
          (funcall next))
        (while (not (looking-at "^$"))
          (set-text-properties (point-at-bol) (point-at-eol)
                               (list 'mouse-face 'highlight
                                     'keymap ahg-log-file-line-map))
          (insert "             ")
          (funcall next))
        (delete-char 1) ;; remove the empty line at the end of the list of files
        ;; rest is the description
        (insert "description:\n")
        ;; each line in the description starts with a '\t'
        (while (and (looking-at "^\\(\t\\|$\\)") (not (eobp)))
          (unless (looking-at "^$")
            (delete-char 1)) ;; remove the \t in front of the line
          (funcall next))
        (insert "\n\n")
        ))))

(defun ahg-log-cur-file (&optional prefix)
  "Shows changelog of the current file. When called interactively
with a prefix argument, prompt for a revision range. If the
prefix argument is the list (16) (corresponding to C-u C-u),
prompts also for extra flags."
  (interactive "P")
  (cond ((eq major-mode 'ahg-status-mode) (call-interactively 'ahg-status-log))
        ((buffer-file-name)
         (let* ((root (ahg-root))
                (filename (buffer-file-name))
                (ahg-file-list-for-log-command
                 (list (file-relative-name filename root)))
                (ahg-dir-name-for-log-command filename))
           (if prefix
               (apply 'ahg-log   
                      (ahg-log-read-args nil (equal current-prefix-arg '(16))))
             (ahg-log "tip" "0"))))
        (t (message "hg log: no file found, aborting."))))

(defun ahg-log-update-to-rev ()
  (interactive)
  (let ((ahg-update-to-rev-get-revision-function 'ahg-log-revision-at-point)
        (ahg-update-to-rev-check-bookmarks t))
    (call-interactively 'ahg-update-to-rev)))


(defun ahg-log-histedit-mess ()
  "Edit the commit message of the given revision."
  (interactive)
  (let ((rev (ahg-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Edit commit message of revision %s? " rev))
      (ahg-histedit-mess rev))))

(defun ahg-log-histedit-drop ()
  "Drop the given revision from history."
  (interactive)
  (let ((rev (ahg-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Drop revision %s? " rev))
      (ahg-histedit-drop rev))))

(defun ahg-log-histedit-xtract ()
  "Extract the given revision from history."
  (interactive)
  (let ((rev (ahg-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Extract revision %s? " rev))
      (ahg-histedit-xtract rev))))

(defun ahg-log-histedit-fold ()
  "Fold the given revision with its parent."
  (interactive)
  (let ((rev (ahg-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Fold revision %s? " rev))
      (ahg-histedit-fold rev))))

(defun ahg-log-histedit-roll ()
  "Fold the given revision with its parent, using the parent's commit message."
  (interactive)
  (let ((rev (ahg-log-revision-at-point)))
    (when (ahg-y-or-n-p (format "Roll revision %s? " rev))
      (ahg-histedit-roll rev))))

;;-----------------------------------------------------------------------------
;; graph log
;;-----------------------------------------------------------------------------

(defvar ahg-glog-font-lock-keywords
  '(("^hg revision DAG for" . ahg-header-line-face)
    ("^hg revision DAG for \\(.*\\)" 1 ahg-header-line-root-face)
    ("^\\([+|@o\\\\/ -]\\)+$" . 'bold) ;; duplicate to avoid bad fontification
    ("^\\([+|@o\\\\/ -]\\)+ " . 'bold) ;; of status messages starting with `o'
    ("^\\([+|@o\\\\/ -]\\)+\\([0-9]+\\)" 2 ahg-short-log-revision-face)
    ("^\\([+|@o\\\\/ -]\\)+[0-9]+  \\([0-9a-f]+\\)" 2 ahg-log-revision-face)
    ("^\\([+|@o\\\\/ -]\\)+[0-9]+  [0-9a-f]+  \\([^ ]+\\)"
     2 ahg-short-log-date-face)
    ("^\\([+|@o\\\\/ -]\\)+[0-9]+  [0-9a-f]+  [^ ]+  \\([^ ]+\\) " 2
     ahg-short-log-user-face)
    ("^\\([+|@o\\\\/ -]\\)+[0-9]+  [0-9a-f]+  [^ ]+  [^ ]+  \\(draft\\)"
     2 ahg-log-phase-draft-face)
    ("^\\([+|@o\\\\/ -]\\)+[0-9]+  [0-9a-f]+  [^ ]+  [^ ]+  \\(secret\\)"
     2 ahg-log-phase-secret-face)
    ("^\\([+|@o\\\\/ -]\\)+[0-9]+  [0-9a-f]+  [^ ]+  [^ ]+  \\(draft  \\|secret  \\)?\\([([{].+\\)[.]$"
     3 ahg-log-branch-face) ;; tags, bookmarks, branches
    ("^\\([+|@o\\\\/ -]\\)+[0-9]+  [0-9a-f]+  [^ ]+  [^ ]+  \\([([{].+\\)[.]$"
     2 ahg-log-branch-face) ;; tags, bookmarks, branches
    ("^\\([+|@o\\\\/ -]\\)+[0-9]+  [0-9a-f]+  .*\\([.]\\)$" 2 ahg-invisible-face))
  "Keywords in `ahg-glog-mode' mode.")

(define-derived-mode ahg-glog-mode special-mode "ahg-glog"
  "Major mode to display hg glog output.

Commands:
\\{ahg-glog-mode-map}
"
  (buffer-disable-undo) ;; undo info not needed here
  (setq truncate-lines t)
  (setq buffer-read-only t)
  (define-key ahg-glog-mode-map [?g] 'ahg-glog)
  (define-key ahg-glog-mode-map [?s] 'ahg-status)
  (define-key ahg-glog-mode-map [?=] 'ahg-glog-view-diff)
  (define-key ahg-glog-mode-map [?D] 'ahg-glog-view-diff-select-rev)
  (define-key ahg-glog-mode-map [?n] 'ahg-glog-next)
  (define-key ahg-glog-mode-map "\t" 'ahg-glog-next)
  (define-key ahg-glog-mode-map [?p] 'ahg-glog-previous)
  (define-key ahg-glog-mode-map [S-iso-lefttab] 'ahg-glog-previous)  
  (define-key ahg-glog-mode-map [?q] 'ahg-buffer-quit)
  (define-key ahg-glog-mode-map [?!] 'ahg-do-command)
  (define-key ahg-glog-mode-map [?h] 'ahg-command-help)
  (define-key ahg-glog-mode-map "\r" 'ahg-glog-update-to-rev)
  (define-key ahg-glog-mode-map [? ] 'ahg-glog-view-details)
  (let ((emap (make-sparse-keymap)))
    (define-key emap "m" 'ahg-glog-histedit-mess)
    (define-key emap "d" 'ahg-glog-histedit-drop)
    (define-key emap "x" 'ahg-glog-histedit-xtract)
    (define-key emap "f" 'ahg-glog-histedit-fold)
    (define-key emap "r" 'ahg-glog-histedit-roll)
    (define-key ahg-glog-mode-map "E" emap))
  (ahg-add-log-commands ahg-glog-mode-map)
  (set (make-local-variable 'font-lock-defaults)
       (list 'ahg-glog-font-lock-keywords t nil nil))
  (set-face-foreground 'ahg-invisible-face (face-background 'default))
  (easy-menu-add ahg-glog-mode-menu ahg-glog-mode-map))

(easy-menu-define ahg-glog-mode-menu ahg-glog-mode-map "aHg Rev DAG"
  '("aHg Rev DAG"
    ["View Revision Details" ahg-glog-view-details [:keys " " :active t]]
    ["View Revision Diff" ahg-glog-view-diff [:keys "=" :active t]]
    ["View Revision Diff with Other..." ahg-glog-view-diff-select-rev
     [:keys "D" :active t]]
    ["Update to Revision" ahg-glog-update-to-rev [:keys "\r" :active t]]
    ["--" nil nil]
    ["Status" ahg-status [:keys "s" :active t]]
    ["Hg Command" ahg-do-command [:keys "!" :active t]]
    ["--" nil nil]
    ["Next Revision" ahg-glog-next [:keys "\t" :active t]]
    ["Previous Revision" ahg-glog-previous [:keys "p" :active t]]
    ["--" nil nil]
    ("History Editing"
     ["Edit Changeset Message" ahg-glog-histedit-mess [:keys "Em" :active t]]
     ["Drop Changeset" ahg-glog-histedit-drop [:keys "Ed" :active t]]
     ["Extract Changeset" ahg-glog-histedit-xtract [:keys "Ex" :active t]]
     ["Fold Changeset" ahg-glog-histedit-fold [:keys "Ef" :active t]]
     ["Roll Changeset" ahg-glog-histedit-roll [:keys "Er" :active t]])
    ["--" nil nil]
    ["Help on Hg Command" ahg-command-help [:keys "h" :active t]]
    ["--" nil nil]
    ["Refresh" ahg-glog [:keys "g" :active t]]
    ["Quit" ahg-buffer-quit [:keys "q" :active t]]
    ))


(defconst ahg-glog-start-regexp "^\\([+|@o\\\\/ -]\\)+\\([0-9]+\\)")

(defun ahg-glog-next (n)
  (interactive "p")
  (end-of-line)
  (re-search-forward ahg-glog-start-regexp nil t n)
  (beginning-of-line))

(defun ahg-glog-previous (n)
  (interactive "p")
  (end-of-line)
  (re-search-backward ahg-glog-start-regexp)
  (re-search-backward ahg-glog-start-regexp nil t n))

(defun ahg-glog-view-diff ()
  (interactive)
  (let* ((r1 (ahg-glog-revision-at-point))
         (r2 (ahg-first-parent-of-rev r1)))
    (ahg-diff r2 r1)))

(defun ahg-glog-view-diff-select-rev (rev)
  (interactive "sEnter revision to compare against: ")
  (let ((r1 (ahg-glog-revision-at-point))
        (r2 rev))
    (ahg-diff r2 r1)))

(defun ahg-glog-revision-at-point ()
  (save-excursion
    (end-of-line)
    (re-search-backward ahg-glog-start-regexp)
    (match-string-no-properties 2)))

(defun ahg-glog-goto-revision-line ()
  (end-of-line)
  (re-search-backward ahg-glog-start-regexp)
  (beginning-of-line))

(defun ahg-glog-view-details ()
  "View details of the given revision."
  (interactive)
  (let ((rev (ahg-glog-revision-at-point)))
    (ahg-log rev nil)))
  
(defun ahg-glog (r1 r2 &optional extra-flags)
  "Run hg glog. R1 and R2 specify the range of revisions to
consider. When run interactively, the user must enter their
values (which default to tip for R1 and 0 for R2). If called with
a prefix argument, prompts also for EXTRA-FLAGS."
  (interactive
   (ahg-log-read-args ahg-file-list-for-log-command current-prefix-arg t))
  (let* ((root (ahg-root))
         (buffer (get-buffer-create
                 (concat "*hg glog: " root "*")))
        (command-list (ahg-args-add-revs r1 r2)))  
    (setq command-list
          (append command-list
                  (list "--template"
                        "{rev}  {node|short}  {date|shortdate}  {author|user}  {ifeq(phase, 'public', '', '{phase}  ')}{if(tags, '[{tags}]  ')}{if(bookmarks, '\\{{bookmarks}}  ')}{if(branches, '({branches})')}.\\n  {desc|firstline}\\n\\n")
                  (when extra-flags (split-string extra-flags))))
    (when ahg-file-list-for-log-command
      (setq command-list (append command-list ahg-file-list-for-log-command)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (ahg-cd root)
        (ahg-push-window-configuration)))
    (ahg-generic-command
     "glog" command-list
     (lexical-let ((dn (or ahg-dir-name-for-log-command root)))
       (lambda (process status)
         (if (string= status "finished\n")
             (progn
               (pop-to-buffer (process-buffer process))
               (ahg-glog-mode)
               (goto-char (point-min))
               (let ((inhibit-read-only t))
                 (insert
                  (propertize "hg revision DAG for " 'face ahg-header-line-face)
                  (propertize dn 'face ahg-header-line-root-face)
                  "\n\n")))
           (ahg-show-error process))))
     buffer
     nil ;; use-shell
     nil ;; no-show-message
     nil ;; report-untrusted
     nil ;; filterfunc
     nil ;; is-interactive
     (list "--config" "extensions.hgext.graphlog=") ;; global-opts
     )))

(defun ahg-glog-update-to-rev ()
  (interactive)
  (let ((ahg-update-to-rev-get-revision-function 'ahg-glog-revision-at-point)
        (ahg-update-to-rev-check-bookmarks t))
    (lexical-let ((refresh 'ahg-status-maybe-refresh)
                  (buf (current-buffer)))
      (letf
          (((symbol-function 'ahg-status-maybe-refresh) (lambda (root)
                (let ((inhibit-read-only t))
                   (save-excursion
                     (goto-char (point-min))
                     (let ((cont
                            (re-search-forward ahg-glog-start-regexp nil t)))
                     (while cont
                       (beginning-of-line)
                       (if (re-search-forward "@" cont t)
                           (progn
                             (setq cont nil)
                             (replace-match "o"))
                         (end-of-line)
                         (setq cont
                               (re-search-forward ahg-glog-start-regexp
                                                  nil t))))))
                   (save-excursion
                     (ahg-glog-goto-revision-line)
                     (re-search-forward "o")
                     (replace-match "@")))
                (funcall refresh root))))
        (call-interactively 'ahg-update-to-rev)))))

(defun ahg-glog-histedit-mess ()
  "Edit the commit message of the given revision."
  (interactive)
  (let ((rev (ahg-glog-revision-at-point)))
    (when (ahg-y-or-n-p (format "Edit commit message of revision %s? " rev))
      (ahg-histedit-mess rev))))

(defun ahg-glog-histedit-drop ()
  "Drop the given revision from history."
  (interactive)
  (let ((rev (ahg-glog-revision-at-point)))
    (when (ahg-y-or-n-p (format "Drop revision %s? " rev))
      (ahg-histedit-drop rev))))

(defun ahg-glog-histedit-xtract ()
  "Extract the given revision from history."
  (interactive)
  (let ((rev (ahg-glog-revision-at-point)))
    (when (ahg-y-or-n-p (format "Extract revision %s? " rev))
      (ahg-histedit-xtract rev))))

(defun ahg-glog-histedit-fold ()
  "Fold the given revision with its parent."
  (interactive)
  (let ((rev (ahg-glog-revision-at-point)))
    (when (ahg-y-or-n-p (format "Fold revision %s? " rev))
      (ahg-histedit-fold rev))))

(defun ahg-glog-histedit-roll ()
  "Fold the given revision with its parent, using the parent's commit message."
  (interactive)
  (let ((rev (ahg-glog-revision-at-point)))
    (when (ahg-y-or-n-p (format "Roll revision %s? " rev))
      (ahg-histedit-roll rev))))

;;-----------------------------------------------------------------------------
;; hg diff
;;-----------------------------------------------------------------------------

(defun ahg-remove-^M ()
  "Remove ^M at end of line in the whole buffer.  This is done in ahg-diff-mode
so that extra ^M's are not added when applying hunks with C-c C-a.  Plus it 
is a lot more readable without the ^M's getting in the way."
  (save-match-data
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward (concat (char-to-string 13) "$") 
                                (point-max) t)
        (replace-match "")))))

(define-derived-mode ahg-diff-mode diff-mode "aHg Diff"
  "Special Diff mode for aHg buffers.

Commands:
\\{ahg-diff-mode-map}
"
  (put 'ahg-diff-mode 'mode-class 'special)
  ; Remove trailing ^M's.  Without this, ^M's are inserted when applying hunks.
  (ahg-remove-^M)
  (setq buffer-read-only t)
  (save-excursion
    (goto-char (point-min))
    (while (and (not (eobp)) (not (looking-at "^---"))) (forward-line 1))
    (let ((fs (or (diff-hunk-file-names) (diff-hunk-file-names t)))
          goodpath)
      (when fs
        (dolist (p fs goodpath)
          (unless goodpath
            (when (string-match "^\\(a\\|b\\)/" p)
              (setq goodpath (substring p (match-end 0))))))
        (when goodpath
          (let ((hint (concat (ahg-root) "/" goodpath)))
            (set (make-local-variable 'diff-remembered-defdir)
                 default-directory)
            (diff-tell-file-name nil hint)))
        ))))


(defun ahg-set-diff-mode (&optional revs)
  (let ((inhibit-read-only t))
    (ahg-diff-mode)
    (easy-menu-add-item nil '("Diff") '["--" nil nil])
    (when revs
      (set (make-local-variable 'ahg-diff-revs) revs)
      (define-key ahg-diff-mode-map "e" 'ahg-diff-ediff)
      (easy-menu-add-item nil '("Diff") '["View with Ediff" ahg-diff-ediff
                                          [:keys "e" :active t]]))
    (define-key ahg-diff-mode-map "q" 'ahg-buffer-quit)
    (easy-menu-add-item nil '("Diff") '["Quit" ahg-buffer-quit
                                        [:keys "q" :active t]])))
    

(defun ahg-diff (&optional r1 r2 files)
  (interactive "P")
  (when (called-interactively-p 'interactive)
    (unless r1
      (setq r1 (read-string "hg diff, R1: " "tip"))
      (setq r2 (read-string "hg diff, R2: " ""))))
  (let ((buffer (get-buffer-create "*aHg-diff*"))
        (command-list (ahg-args-add-revs r1 r2 t))
        (curdir default-directory))
    (with-current-buffer buffer
      (setq default-directory (file-name-as-directory curdir)))
    (when ahg-diff-use-git-format
      (setq command-list (cons "--git" command-list)))
    (when files
      (setq command-list (append command-list files)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (ahg-push-window-configuration)))
    (ahg-generic-command
     "diff" command-list
     (lexical-let ((r1 r1)
                   (r2 r2)
                   (win (when ahg-diff-keep-current-buffer (selected-window))))
       (lambda (process status)
         (if (string= status "finished\n")
             (progn
               (pop-to-buffer (process-buffer process) nil win)
               (ahg-set-diff-mode
                (cond ((and r1 r2) (cons (ahg-rev-id r2) (ahg-rev-id r1)))
                      (r1 (cons nil (ahg-rev-id r1)))
                      (t (cons nil (ahg-rev-id ".")))))
               (goto-char (point-min))
               (when win (select-window win)))
           (ahg-show-error process))))
     buffer)))


(defun ahg-diff-c (r &optional files)
  "runs hg diff -c (show changes in revision)"
  (interactive)
  (let ((buffer (get-buffer-create "*aHg-diff*"))
        (command-list (list "-c" r))
        (curdir default-directory))
    (with-current-buffer buffer
      (setq default-directory (file-name-as-directory curdir)))
    (when ahg-diff-use-git-format
      (setq command-list (cons "--git" command-list)))
    (when files
      (setq command-list (append command-list files)))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (erase-buffer)
        (ahg-push-window-configuration)))
    (ahg-generic-command
     "diff" command-list
     (lexical-let ((r r))
       (lambda (process status)
         (if (string= status "finished\n")
             (progn
               (pop-to-buffer (process-buffer process))
               (ahg-set-diff-mode (cons (ahg-rev-id r)
                                        (ahg-rev-id (format "p1(%s)" r))))
               (goto-char (point-min)))
           (ahg-show-error process))))
     buffer)))


(defun ahg-diff-cur-file (ask-other-rev)
  (interactive "P")
  (cond ((eq major-mode 'ahg-status-mode) (call-interactively 'ahg-status-diff))
        ((eq major-mode 'ahg-short-log-mode)
         (call-interactively 'ahg-short-log-view-diff))
        ((eq major-mode 'ahg-log-mode) (call-interactively 'ahg-log-view-diff))
        ((buffer-file-name)
         (ahg-diff (when ask-other-rev
                     (read-string "Enter revision to compare against: "))
                   nil (list (buffer-file-name))))
        (t (message "hg diff: no file found, aborting."))))


(defun ahg-diff-ediff-cur-file (ask-other-rev)
  (interactive "P")
  (cond ((eq major-mode 'ahg-status-mode)
         (call-interactively 'ahg-status-diff-ediff))
        ((buffer-file-name)
         (let ((ahg-diff-revs
                (cons nil
                      (ahg-rev-id
                       (if ask-other-rev
                           (read-string "Enter revision to compare against: ")
                         ".")))))
           (ahg-diff-ediff (file-relative-name (buffer-file-name)
                                               (ahg-root)))))
        (t (message "hg diff: no file found, aborting."))))


(defun ahg-diff-get-ediff-buffer (root filename rev)
  (let ((buf (get-buffer-create (format "*aHg-diff-%s-%s" (or rev "*workdir*")
                                        filename))))
    (with-current-buffer buf
      (cond ((not (ahg-cd root)) (error "can't cd to %s" root))
            (rev
             (if (= (ahg-call-process "cat" (list "-r" rev filename)) 0)
                 buf
               (error "error retrieving revision %s of %s" rev filename)))
            (t (insert-file-contents filename nil nil nil t) buf)))))


(defun ahg-diff-ediff (&optional filename)
  "Examine the current aHg diff in an Ediff session."
  (interactive)
  (if (not (boundp 'ahg-diff-revs))
      (message "error: no revision diff information for current buffer")
    (condition-case err
        (let* ((root (ahg-root))
               (filename (if filename filename
                           (file-relative-name (diff-find-file-name) root)))
               (m (message "found filename %s %s" filename ahg-diff-revs))
               (buf1 (ahg-diff-get-ediff-buffer root filename
                                                (car ahg-diff-revs)))
               (buf2 (ahg-diff-get-ediff-buffer root filename
                                                (cdr ahg-diff-revs))))
          (with-current-buffer (ediff-buffers buf1 buf2)
            ;; kill the temporary buffers at the end of the ediff session
            (set (make-local-variable 'ediff-quit-hook)
                 (cons (lexical-let ((buf1 buf1) (buf2 buf2))
                         (lambda () (kill-buffer buf1) (kill-buffer buf2)))
                       ediff-quit-hook))))
    (error
     (let ((buf (generate-new-buffer "*aHg-ediff*")))
       (ahg-show-error-msg (format "aHg ediff error: %s"
                                   (error-message-string err)) buf))))))

;;-----------------------------------------------------------------------------
;; hg annotate
;;-----------------------------------------------------------------------------

(defun ahg-annotate-cur-file ()
  "Runs hg annotate on the current file."
  (interactive)
  (ahg-annotate)
)

(defun ahg-annotate (&optional file rev line)
  "Run hg annotate on the supplied file and rev.  If no file is given, use the 
current buffer.  If no rev is given, use the current rev.  Lines are colored 
according to their revision, and revision descriptions are shown as tooltips.

The line parameter specifies where to position the point in the annotated file.
If line is not specified, the current line number in the current buffer is
used.
"
  (lexical-let ((root (ahg-root))
                (file (or file (buffer-file-name)))
                (rev rev)
                (line (or line (line-number-at-pos))))
    (when file
      (lexical-let ((buffer (get-buffer-create
                             (concat "*hg annotate: " 
                                     (when rev (concat "-r " rev " ") ) 
                                     file "*" )))
                    (relfile (file-relative-name file root)))
        (with-current-buffer buffer
          (unless (equal major-mode 'fundamental-mode)
            (fundamental-mode))
          (setq buffer-read-only nil)
          (erase-buffer)
          (ahg-push-window-configuration)
          (put (make-local-variable 'ahg-annotate-cur-file) 
               'permanent-local t)
          (set 'ahg-annotate-current-file file)
          (put (make-local-variable 'ahg-annotate-max-revision) 
               'permanent-local t)
          (put (make-local-variable 'ahg-changeset-descriptions) 
               'permanent-local t))
      
        
        ;; We're actually going to run two commands.  We'll run hg log to get
        ;; the revision descriptions, and then run hg annotate.  After that, 
        ;; we'll colorize and show descriptions as tooltips
        
        (ahg-generic-command
         "log" 
         (append
          (list "--template" "{rev} {desc|firstline}\\n" relfile)
          (when rev (list "-r" (concat rev ":0" ))))
         (lambda (process status)
           (if (string= status "finished\n")
               (with-current-buffer buffer
                 (goto-char (point-min))
                 (set 'ahg-annotate-max-revision 
                      (let ((rev (word-at-point)))
                        (if rev (string-to-number (word-at-point)) 0)))
                 (goto-char (point-max))
                 (forward-line -1)
                 (set 'ahg-annotate-min-revision 
                      (let ((rev (word-at-point)))
                        (if rev (string-to-number (word-at-point)) 0)))
                 (goto-char (point-min))
                 (setq ahg-changeset-descriptions (make-hash-table))
                 (while (not (eobp))
                   (let ((rev (word-at-point)))
                     (when rev
                       (setq rev (string-to-number (word-at-point)))
                       (forward-word)
                       (puthash rev 
                                (buffer-substring-no-properties (point)
                                                                (point-at-eol))
                                ahg-changeset-descriptions))
                     (forward-line)))
                 (erase-buffer)
                 (ahg-cd root)
                 (ahg-generic-command
                  "annotate" 
                  (append 
                   (list "-undql" relfile)
                   (when rev (list "-r" rev)))
                  
                  (lambda (process status)
                    (if (string= status "finished\n")
                        (progn
                          (pop-to-buffer buffer)
                          (goto-char (point-min))
                          (while (re-search-forward
                                  (concat
                                   "^ *[^ ]+ +[0-9]+ "
                                   "[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]:"
                                   " *\\([0-9]+\\):") nil t)
                            (let ((aline (match-string 1))
                                  (beg (point-at-bol))
                                  (end (point-at-eol)))
                              (put-text-property beg end
                                                 'ahg-line-number aline)
                              (goto-char (1+ end))))
                          (ahg-goto-line line)
                          (unless (equal major-mode 'ahg-annotate-mode)
                            (ahg-annotate-mode))
                          (setq buffer-read-only t)
                          )
                      (ahg-show-error process)))
                  buffer))
             (ahg-show-error process)))
         buffer)))))

;; Adapted from vc-annotate-mode
(define-derived-mode ahg-annotate-mode special-mode "Annotate"
  "Major mode for output buffers of the `ahg-annotate-cur-file' command.
Commands:
\\{ahg-annotate-mode-map}
"
  (buffer-disable-undo) ;; Undo not needed here
  ;; Frob buffer-invisibility-spec so that if it is originally a naked t,
  ;; it will become a list, to avoid initial annotations being invisible.
  (add-to-invisibility-spec 'foo)
  (remove-from-invisibility-spec 'foo)
  (set (make-local-variable 'truncate-lines) t)
  (set (make-local-variable 'font-lock-defaults)
       '(ahg-annotate-font-lock-keywords t))
  (when (fboundp 'hack-dir-local-variables-non-file-buffer)
    (hack-dir-local-variables-non-file-buffer))

  (define-key ahg-annotate-mode-map "=" 'ahg-annotate-diff)
  (define-key ahg-annotate-mode-map "l" 'ahg-annotate-log)
  (define-key ahg-annotate-mode-map "a" 'ahg-annotate-annotate)
  (define-key ahg-annotate-mode-map "u" 'ahg-annotate-uncover)
  (define-key ahg-annotate-mode-map "q" 'ahg-buffer-quit)
  (define-key ahg-annotate-mode-map (kbd "RET") 'ahg-annotate-goto-line)
  (easy-menu-add ahg-annotate-mode-menu ahg-annotate-mode-map))

(easy-menu-define ahg-annotate-mode-menu ahg-annotate-mode-map "aHg Annotate"
  '("aHg Annotate"
    ["Diff Line's Revision" ahg-annotate-diff [:keys "=" :active t]]
    ["Log Line's Revision" ahg-annotate-log [:keys "l" :active t]]
    ["Annotate Line's Revision" ahg-annotate-annotate [:keys "a" :active t]]
    ["Uncover Line" ahg-annotate-uncover [:keys "u" :active t]]
    ["Go To Line" ahg-annotate-goto-line [:keys "\r" :active t]]
    ["Quit" ahg-buffer-quit [:keys "q" :active t]]))

;; Adapted from vc-annotate-font-lock-keywords
(defconst ahg-annotate-font-lock-keywords
  ;; The fontification is done by ahg-annotate-lines instead of font-lock.
  '((ahg-annotate-lines)))

;; Borrowed from vc-annotate-lines, optimized it
(defun ahg-annotate-lines (limit)
  "Iterates over each line.  When it hits the end or the revision changes, it
applies the group of preceding lines having the same revision."
  (let ((start (point)) lastrev rev)
    (while (< (point) limit)
      (forward-word 2) ;; go to revision column
      (let ((rev (current-word)))
        (when (and (not (equal rev lastrev)) lastrev)
          (beginning-of-line)
          (ahg-annotate-region start (setq start (point)) lastrev))
        (setq lastrev rev))
      (forward-line))
    (ahg-annotate-region start (point) lastrev))
  nil)

(defun ahg-annotate-region (start end rev)
  "Sets properties on a group of lines belonging to the same revision.
It sets a color corresponding to the revision.  It also sets a tooltip that 
displays the changeset description.

Colors range from purple for old revisions to red for recent revisions."
  (setq rev (string-to-number rev))
  (let* ((color (ahg-hsv-to-hex 
                 (* .7 ; Using .7 here omits the ambiguous pinks
                    (/ (- ahg-annotate-max-revision (float rev)) 
                       (max 1 ; avoid divide by zero with this
                            (- ahg-annotate-max-revision 
                               ahg-annotate-min-revision))))
                 .9 .9))
         ;; substring from index 1 to remove any leading `#' in the name
         (face-name (concat "ahg-annotate-face-"
                            (if (string-equal
                                 (substring color 0 1) "#")
                                (substring color 1)
                              color)))
         ;; Make the face if not done.
         (face (or (intern-soft face-name)
                   (let ((tmp-face (make-face (intern face-name))))
                     (set-face-foreground tmp-face color)
                     (when vc-annotate-background
                       (set-face-background tmp-face
                                            vc-annotate-background))
                     tmp-face))))	; Return the face
    (put-text-property start end 'face face)
    (put-text-property start end 'help-echo 
                       (gethash rev ahg-changeset-descriptions ))))

;;; Helper functions for commands in ahg-annotate-mode
(defun ahg-annotate-revision-at-line ()
  "Return the revision of the current line.  It is located in the second word in
the line"
  (save-excursion
     (beginning-of-line)
     (forward-word 2)
     (word-at-point)))

(defun ahg-annotate-line-at-line ()
  "Return the line number at the first appearance of the current line.  It is 
stored in a text property."
  (save-excursion
     (beginning-of-line)
     (string-to-number (get-text-property (point) 'ahg-line-number))))

;;; Commands that can be invoked in ahg-annotate-mode
(defun ahg-annotate-log ()
  "See the changeset log for the revision at the current line in the
annotation."
  (interactive)
  (ahg-log 
   (ahg-annotate-revision-at-line)
   nil))

(defun ahg-annotate-diff ()
  "Display a complete diff of the revision at the current line in the
annotation."
  (interactive)
  (ahg-diff-c 
   (ahg-annotate-revision-at-line)
   (list ahg-annotate-current-file)
   ))

(defun ahg-annotate-uncover ()
  "See the annotated revision just prior to the revision your cursor is on.
Lets you step back in time for that line."
  (interactive)
  (let ((prior-rev 
         (1-
          (string-to-number 
           (ahg-annotate-revision-at-line)))))
    (if (< prior-rev 0)
        (message "Already at revision zero")
      (ahg-annotate 
       ahg-annotate-current-file 
       (number-to-string prior-rev)
       (ahg-annotate-line-at-line)))))

(defun ahg-annotate-annotate ()
  "See the annotated file using the revision your cursor is on."
  (interactive)
  (ahg-annotate 
   ahg-annotate-current-file 
   (ahg-annotate-revision-at-line)
   (ahg-annotate-line-at-line)))

(defun ahg-annotate-goto-line ()
  "Go to the line corresponding to the current aHg Annotate line."
  (interactive)
  (unless (eq major-mode 'ahg-annotate-mode)
    (error "Not in a VC-Annotate buffer"))
  (let ((line (ahg-annotate-line-at-line)))
    (pop-to-buffer
     (or (and (file-exists-p ahg-annotate-current-file)
	      (find-file-noselect ahg-annotate-current-file))
	 (error "File not found: %s" ahg-annotate-current-file)))
    (save-restriction
      (widen)
      (goto-char (point-min))
      (forward-line (1- line))
      (recenter))
    ;; Issue a warning if the lines might be incorrect.
    (cond
     ((buffer-modified-p)
      (message "Buffer modified; annotated line numbers may be incorrect"))
     ((not (string= (ahg-file-status buffer-file-name) "C"))
      (message "File is not up-to-date; annotated line numbers may be incorrect")))))

;;-----------------------------------------------------------------------------
;; hg heads, bookmarks and tags
;;-----------------------------------------------------------------------------

(defun ahg-heads ()
  "Show the heads of the repository in a tabular view, similar to `ahg-short-log'."
  (interactive)
  (ahg-short-log-impl "hg heads" "{if(tags, '[{tags}]  ')}{if(bookmarks, '\\{{bookmarks}}  ')}{ifeq(branch, 'default', '', '({branch})')}" "[Tags] {Bookmarks} (Branch)"
                      "reverse(head() and tip:0)" nil nil))


(defun ahg-tags ()
  "Show the tags of the repository in a tabular view, similar to `ahg-short-log'."
  (interactive)
  (ahg-short-log-impl "hg tags" "{tags}" "Tag Name"
                      "reverse(tag(\"re:.*\") and tip:0)" nil nil))


(defun ahg-bookmarks ()
  "Show the bookmarks of the repository in a tabular view, similar to `ahg-short-log'."
  (interactive)
  (ahg-short-log-impl "hg bookmarks" "{bookmarks}" "Bookmark Name"
                      "reverse(bookmark() and tip:0)" nil nil))


;;-----------------------------------------------------------------------------
;; hg command
;;-----------------------------------------------------------------------------

(defun ahg-complete-command-name (command)
  (with-temp-buffer
    (let ((process-environment (cons "LANG=" process-environment)))
      (if (= (ahg-call-process "debugcomplete" (list command)) 0)
          ;; first, we try the built-in autocompletion of mercurial
          (let (out)
            (goto-char (point-min))
            (while (not (eobp))
              (setq out
                    (cons
                     (concat (buffer-substring-no-properties
                              (point-at-bol) (point-at-eol)) " ")
                     out))
              (forward-line 1))
            (if out (nreverse out) (list (concat command " "))))
        ;; if this fails, we return the string itself as a match
        (list (concat command " "))))))

(defvar ahg-complete-command-directory-for-filename-completion nil)

(defun ahg-complete-command (command)
  ;; we split the string, and treat the last word as a filename
  (let* ((idx (string-match "\\([^ ]+\\)$" command))
         (cmd (if idx (substring command idx) ""))
         (matches
          (cond ((string-match "^-.*$" cmd) (list cmd))
                ((and idx (= idx 0)) (ahg-complete-command-name command))
                ((and idx (= idx 5) (string= (substring command 0 idx) "help "))
                 (ahg-complete-command-name cmd))
                (t
                 (let ((default-directory
                         (or
                          ahg-complete-command-directory-for-filename-completion
                          default-directory)))
                   (mapcar
                    (lambda (n)
                      (if (file-directory-p n) (file-name-as-directory n) n))
                    (file-expand-wildcards
                     (concat (substring command idx) "*")))))))
         (prev (substring command 0 idx)))
    (mapcar (function (lambda (a) (concat prev a))) matches)))


(defvar ahg-do-command-prompt "Hg command: ")
(defvar ahg-do-command-extra-args nil)

(defun ahg-do-command (cmdstring)
  "Execute an arbitrary hg command CMDSTRING.
CMDSTRING should not include 'hg' as first argument, as this is
implicit.

When run from an *aHg-status* buffer, the selected files are
passed as extra arguments. In this case, if there is a `*' in
CMDSTRING, surrounded by whitespace, the list of files is
substituted there. Otherwise, the list of files is appended to
CMDSTRING.

With a non-nil prefix arg, upon successful completion the status
buffer is automatically refreshed. (If called from an MQ patches buffer,
that buffer is refreshed instead.)"
  (interactive (list
                (let ((minibuffer-local-completion-map
                       (copy-keymap minibuffer-local-map)))
                  (define-key minibuffer-local-completion-map "\t"
                    'minibuffer-complete)
                  (completing-read ahg-do-command-prompt
                                   (ahg-dynamic-completion-table
                                    ahg-complete-command)))))
  (let* ((args (split-string cmdstring " "))
         (cmdname (car args))
         (cmdargs (mapconcat 'identity (cdr args) " "))
         (interpolate (member "*" (cdr args)))
         (buffer (get-buffer-create (concat "*hg command: "
                                            (ahg-root t) "*")))
         (curdir default-directory)
         (should-refresh current-prefix-arg)
         (is-interactive
          (ahg-string-match-p ahg-do-command-interactive-regexp cmdname))
         (ahg-i18n (if is-interactive nil ahg-i18n)))
    (when ahg-do-command-extra-args
      (let ((extra (mapconcat 'identity ahg-do-command-extra-args " ")))
        (setq cmdargs
              (if interpolate
                  (replace-regexp-in-string
                   "\\([*]\\).*\\'" extra cmdargs nil nil 1)
                (concat cmdargs " " extra)))))
    (with-current-buffer buffer
      (let ((inhibit-read-only t))
        (ahg-command-mode)
        (erase-buffer)
        (setq default-directory (file-name-as-directory curdir))
        (ahg-push-window-configuration)))
    (when ahg-do-command-show-buffer-immediately
      (pop-to-buffer buffer))
    (when ahg-do-command-insert-header
      (with-current-buffer buffer
        (let ((inhibit-read-only t))
          (goto-char (point-min))
          (insert
           (propertize
            (concat "output of 'hg " cmdname " " cmdargs "' on ")
            'face ahg-header-line-face)
           (propertize default-directory 'face ahg-header-line-root-face)
           "\n" (make-string (1- (window-width (selected-window))) ?-)
           "\n\n"))))
    (ahg-generic-command
     cmdname (list cmdargs)
     (lexical-let ((should-refresh should-refresh)
                   (aroot (ahg-root t))
                   (is-mq (eq major-mode 'ahg-mq-patches-mode)))
       (lambda (process status)
         (if (string= status "finished\n")
             (progn
               (when should-refresh
                 (if is-mq
                     (ahg-mq-patches-maybe-refresh aroot)
                   (ahg-status-maybe-refresh aroot)))
               (pop-to-buffer (current-buffer))
               (goto-char (point-min)))
           (ahg-show-error process))))
     buffer
     t ;; use-shell
     nil ;; no-show-message
     t ;; report-untrusted
     (ahg-do-command-filter is-interactive) ;; filterfunc
     is-interactive ;; is-interactive
     (list "--config" "progress.assume-tty=True"
           "--config" "progress.clear-complete=False") ;; global-opts
     t ;; no-hgplain
     )))


(defun ahg-do-command-filter (interactive)
  (lexical-let ((interactive interactive))
    (lambda (process string)
      (when (buffer-name (process-buffer process))
        ;; insert output into the buffer
        (with-current-buffer (process-buffer process)
          (let ((moving (= (point) (process-mark process)))
                (inhibit-read-only t))
            (save-excursion
              ;; Insert the text, advancing the process marker.
              (goto-char (process-mark process))
              (let* ((cr (regexp-quote (regexp-quote "")))
                     (m (string-match cr string)))
                (while m
                  (forward-line 0)
                  (delete-char
                   (- (min (1+ (point-at-eol)) (point-max)) (point)))
                  (setq string (substring string (1+ m)))
                  (setq m (string-match cr string))
                  )
                (insert string))
              (set-marker (process-mark process) (point))
              ;; check if we are expecting a user name or a password
              (when interactive
                (let (user pass data)
                  (save-excursion
                    (backward-word)
                    (cond ((looking-at "\\<user: $") (setq user t))
                          ((looking-at "\\<password: $") (setq pass t))))
                  (cond (user (setq data (concat (read-string "user: ") "\n"))
                              (process-send-string process data))
                        (pass (setq data
                                    (concat (read-passwd "password: ") "\n"))
                              (process-send-string process data)
                              (setq data "***\n")
                              ))
                  (when data
                    (insert data)
                    (set-marker (process-mark process) (point))))
                )
              )
            (if moving (goto-char (process-mark process)))))))))
  

;;-----------------------------------------------------------------------------
;; hg help
;;-----------------------------------------------------------------------------

(defun ahg-command-help (command)
  (interactive
   (list (completing-read "Help on hg command: "
                          (ahg-dynamic-completion-table
                           ahg-complete-command-name))))
  (let ((buffer (get-buffer-create "*hg help*"))
        (oldcols (getenv "COLUMNS"))
        (ahg-i18n t))
    (with-current-buffer buffer (let ((inhibit-read-only t)) (erase-buffer)))
    (setenv "COLUMNS" (format "%s" (window-width (selected-window))))
    (ahg-generic-command
     "help" (split-string command)
     (lambda (process status)
       (if (string= status "finished\n")
           (progn
             (pop-to-buffer (process-buffer process))
             (help-mode)
             (view-mode)
             (local-set-key "!" 'ahg-do-command)
             (let ((mymap (copy-keymap
                           (cdr (assq 'view-mode minor-mode-map-alist)))))
               (define-key mymap "h" 'ahg-command-help)
               (add-to-list 'minor-mode-overriding-map-alist
                            (cons 'view-mode mymap)))
             (goto-char (point-min)))
         (ahg-show-error process)))
     buffer)
    (setenv "COLUMNS" oldcols)))

;;-----------------------------------------------------------------------------
;; manifest grep
;;-----------------------------------------------------------------------------

(defvar ahg-manifest-grep-pattern-history nil
  "History for patterns of `ahg-manifest-grep'.")

(defun ahg-grep-regexp-quote (s)
  (replace-regexp-in-string "[()]" (lambda (m) (concat "\\\\" m))
                            (regexp-quote s)))


(defun ahg-grep-filename-setup (filename)
  (buffer-disable-undo)
  (let ((b 0)
        (ok t)
        r)
    (while
        (progn
          (setq r (insert-file-contents-literally filename nil b (+ b 1048576)))
          (and ok r (> (cadr r) 0)))
      (if (save-excursion (goto-char b) (search-forward "\000" nil t))
          ;; exclude binary files. here, we use the same approach as Mercurial
          ;; for detecting binaries: we simply check for a 0 byte
          (setq ok nil)
        (setq b (+ b (cadr r)))))
    (goto-char (point-min))
    ok))

(defun ahg-grep-filename (filename regexp)
  (let ((buf (current-buffer))
        (nmatches 0))
    (with-temp-buffer
      (when (ahg-grep-filename-setup filename)
        (while (not (eobp))
          (let (found)
            (while (search-forward-regexp regexp (point-at-eol) t)
              (setq found t)
              (setq nmatches (1+ nmatches))
              (add-text-properties (match-beginning 0) (match-end 0)
                                   (list 'font-lock-face grep-match-face)))
            (when found
              (let ((line (buffer-substring (point-at-bol) (point-at-eol)))
                    (pos (line-number-at-pos)))
                (with-current-buffer buf
                  (save-excursion
                    (goto-char (point-max))
                    (insert filename (format ":%d:" pos) line "\n")))))
            (goto-char (1+ (point-at-eol)))))))
    nmatches))


(defun ahg-grep-filename-grep (filename regexp)
  (let ((buf (current-buffer))
        (gbuf (get-buffer-create "*ahg-grep*")))
    (let ((process (start-file-process "*ahg-grep*" gbuf
                                       "grep" "--color=always" "-I" "-nHE"
                                       regexp filename)))
      (set-process-sentinel
       process
       (lexical-let ((buf buf))
         (lambda (process status)
           (when (string= status "finished\n")
             (with-current-buffer buf
               (insert-buffer-substring (process-buffer process)))
             (kill-buffer (process-buffer process)))))))))


(defun ahg-manifest-grep-read (root)
  (let ((glob (read-string "Files to search: ")))
    (when (ahg-string-match-p "^\\./" glob)
      (setq glob (concat (file-name-as-directory
                          (file-relative-name default-directory root))
                         (substring glob 2))))
    glob))

(defun ahg-manifest-grep (pattern glob)
  "Search for grep-like pattern in the working directory, considering only
the files under version control."
  (interactive
   (list
    (let* ((default
             (cond ((and mark-active transient-mark-mode)
                    (ahg-grep-regexp-quote (buffer-substring (region-beginning)
                                                             (region-end))))
                   ((symbol-at-point)
                    (ahg-grep-regexp-quote (format "%s" (symbol-at-point))))
                   (t (car ahg-manifest-grep-pattern-history))))
           (input (read-string
                   (if default
                       (format "Search for pattern (default %s): "
                               (query-replace-descr default))
                     "Search for pattern: "))))
      (if (and input (> (length input) 0)) input default))
    (if current-prefix-arg (ahg-manifest-grep-read (ahg-root)) nil)))
  (let* ((root (ahg-root))
         (header
          (concat (propertize "searching for pattern "
                              'font-lock-face ahg-header-line-face)
                  (propertize pattern
                              'font-lock-face font-lock-string-face)
                  (propertize " in "
                              'font-lock-face ahg-header-line-face)
                  (propertize root
                              'font-lock-face
                              ahg-header-line-root-face)
                  (propertize
                   (if glob (format " (on `%s' files)" glob) "")
                   'font-lock-face ahg-header-line-face)
                  "\n\n"))
         (do-refresh
          (lexical-let ((glob glob)
                        (pattern pattern))
            (lambda ()
              (interactive)
              (ahg-manifest-grep pattern glob))))
         (insert-footer
          (lambda ()
            (save-excursion
              (goto-char (point-max))
              (insert
               (make-string
                (1- (window-width
                     (selected-window))) ?-)
               "\naHg grep finished at "
               (substring
                (current-time-string) 0 19)
               "\n")
              (forward-line -1)
              (let ((overlay (make-overlay (point-at-bol) (point-at-eol)))
                    (map (make-sparse-keymap))
                    (nop (lambda () (interactive) nil)))
                (define-key map [mouse-1] nop)
                (define-key map [mouse-2] nop)
                (define-key map "\r" nop)
                (overlay-put overlay 'face 'default)
                (overlay-put overlay 'mouse-face 'default)
                (overlay-put overlay 'help-echo (lambda (&rest args) nil))
                (overlay-put overlay 'keymap map)
                (overlay-put overlay 'local-map map)
                )
              ))))
    (if ahg-manifest-grep-use-xargs-grep
        (let* ((grep-setup-hook
                (cons
                 (lexical-let ((root root)
                               (header header)
                               (insert-footer insert-footer))
                   (lambda ()
                     (let ((inhibit-read-only t))
                       (ahg-cd root)
                       (erase-buffer)
                       (insert header)
                       (goto-char (point-min))
                       (forward-line 1))
                     (set (make-local-variable
                           'compilation-exit-message-function)
                          (lexical-let ((buf (current-buffer)))
                            (lambda (status code msg)
                              (when (eq status 'exit)
                                (set (make-local-variable 'ahg-grep-ok)
                                     (or (zerop code) (= code 123))))
                              (cons msg code))))
                     (set (make-local-variable 'compilation-finish-functions)
                          (cons
                           (lexical-let ((insert-footer insert-footer))
                             (lambda (buf msg)
                               (with-current-buffer buf
                                 (when (and (boundp 'ahg-grep-ok)
                                            ahg-grep-ok)
                                   (let ((inhibit-read-only t))
                                     (save-excursion
                                       (goto-char (point-max))
                                       (forward-line -1)
                                       (beginning-of-line)
                                       (kill-line)
                                       (funcall insert-footer)
                                       (message "aHg grep finished")
                                       (setq mode-line-process nil)
                                       (force-mode-line-update))
                                     (goto-char (point-min))
                                     (forward-line 1)
                                     (redisplay)
                                     )))))
                           compilation-finish-functions))))
                 grep-setup-hook))
               (buf (grep
                     (format "%s files -0 %s | xargs -0 grep -I -nHE -e %s"
                             (ahg-hg-command)
                             (if glob (concat "'glob:" glob "'") "")
                             (shell-quote-argument pattern))))
               (prevbuf (get-buffer "*ahg-grep*"))
               (inhibit-read-only t))
          (when (and prevbuf (not (eq prevbuf buf))) (kill-buffer prevbuf))
          (with-current-buffer buf
            (ahg-cd root)
            (rename-buffer "*ahg-grep*")
            (local-set-key "g" do-refresh)))              
      (let ((buf (get-buffer-create "*ahg-grep*")))
        (with-current-buffer buf
          (pop-to-buffer buf)
          (let ((inhibit-read-only t))
            (erase-buffer)
            (insert header)
            (grep-mode)
            (local-set-key "g" do-refresh)
            (setq mode-line-process
                  (list (concat ":" (propertize "running" 'face
                                                '(:foreground "#DD0000"))))))
          (if (ahg-cd root)
              (ahg-generic-command
               "files" (list (concat "set:" (when glob (list glob " & "))
                                     "grep(" pattern ") & ! binary()"))
               (lexical-let ((buf buf)
                             (root root)
                             (glob glob)
                             (pattern pattern)
                             (insert-footer insert-footer))
                 (lambda (process status)
                   (if (string= status "finished\n")
                       (let ((inhibit-read-only t)
                             files)
                         (with-current-buffer (process-buffer process)
                           (goto-char (point-min))
                           (while (not (eobp))
                             (add-to-list
                              'files
                              (buffer-substring-no-properties (point-at-bol)
                                                              (point-at-eol)))
                             (goto-char (1+ (point-at-eol)))))
                         (pop-to-buffer buf)
                         (redisplay)
                         (mapc
                          (lambda (f) (ahg-grep-filename f pattern))
                          (nreverse files))
                         (save-excursion
                           (goto-char (point-max))
                           (insert "\n"))
                         (funcall insert-footer)
                         (message "aHg grep finished")
                         (setq mode-line-process nil)
                         (force-mode-line-update))
                     (ahg-show-error process))))
               nil nil t)
            (ahg-show-error-msg (format "can't cd to %s" root) buf)))))))

;;-----------------------------------------------------------------------------
;; MQ support
;;-----------------------------------------------------------------------------

(defun ahg-mq-log-callback (cmdname &optional extraargs)
  "Callback function to edit log messages for mq commands."
  (interactive)
  (let ((msg (ahg-parse-commit-message)))
    (let ((args (append (list "-m" msg)
                        extraargs
                        (log-edit-files))))
      (ahg-generic-command
       cmdname args
       (lexical-let ((aroot (ahg-root))
                     (n (length (log-edit-files)))
                     (cmdn cmdname))
         (lambda (process status)
           (if (string= status "finished\n")
               (progn
                 (ahg-status-maybe-refresh aroot)
                 (message "mq command %s successful." cmdn)
                 (kill-buffer (process-buffer process)))
             (ahg-show-error process)))))))
  (kill-buffer (current-buffer)))

(defun ahg-complete-mq-patch-name (patchname)
  "Function to complete patch names, according to the result of the
hg qseries command."
  (with-temp-buffer
    (let ((process-environment (cons "LANG=" process-environment))) 
      (if (= (ahg-call-process "qseries") 0)
          (let (out)
            (goto-char (point-min))
            (while (not (or (looking-at "^$") (eobp)))
              (let* ((curname (buffer-substring-no-properties
                               (point-at-bol) (point-at-eol)))
                     (ok (compare-strings patchname 0 nil curname 0 nil)))
                (when (or (eq ok t) (= (- ok) (1+ (length patchname))))
                  (setq out (cons curname out)))
                (beginning-of-line)
                (forward-line 1)))
            (nreverse out))
        ;; here, we silently ignore errors, and return an empty completion
        nil))))

(defun ahg-qnew (patchname force edit-log-message)
  "Create a new mq patch PATCHNAME. If FORCE is nil, abort if
there are outstanding changes in the working directory. If
EDIT-LOG-MESSAGE is non-nil, pop a buffer to enter a commit
message to use instead of the default one. When called
interactively, the name of the patch and the FORCE flag are read
from the minibuffer, and EDIT-LOG-MESSAGE is non-nil only if
called with a prefix argument. If FORCE is true and the function
is called interactively from a aHg status buffer, only the
selected files will be incorporated into the patch."
  (interactive
   (list (read-string "Patch name: ")
         (and (ahg-uncommitted-changes-p)
              (ahg-y-or-n-p "Import outstanding changes into patch? "))
         current-prefix-arg))
  (if (and (not force) (ahg-uncommitted-changes-p))
      (message "mq command qnew aborted.")
    (let ((files (when (eq major-mode 'ahg-status-mode)
                   (mapcar 'cddr (ahg-status-get-marked nil))))
          (qnew-args (append (when ahg-diff-use-git-format (list "--git"))
                             (list "--force"))))
      (if edit-log-message
          (ahg-log-edit
           (lexical-let ((qnew-args qnew-args))
             (lambda () (interactive)
               (ahg-mq-log-callback "qnew" qnew-args)))
           (lexical-let ((flist (cons patchname files))) (lambda () flist))
           (generate-new-buffer "*aHg-log*"))
        ;; else
        (ahg-generic-command
         "qnew" (append qnew-args (list patchname) files)
         (lexical-let ((aroot (ahg-root)))
           (lambda (process status)
             (if (string= status "finished\n")
                 (progn
                   (ahg-status-maybe-refresh aroot)
                   (ahg-mq-patches-maybe-refresh aroot)
                   (message "mq command qnew successful.")
                   (kill-buffer (process-buffer process)))
               (ahg-show-error process)))))
        ))))

(defun ahg-qrefresh (get-log-message)
  "Refreshes the current mq patch. If GET-LOG-MESSAGE is non-nil,
a buffer will pop up to enter the commit message. When called
interactively, GET-LOG-MESSAGE is non-nil only if called with a
prefix arg. If called interactively from a aHg status buffer,
only the selected files will be refreshed."
  (interactive "P")
  (let ((buf (when get-log-message (generate-new-buffer "*aHg-log*")))
        (files (when (eq major-mode 'ahg-status-mode)
                 (mapcar 'cddr (ahg-status-get-marked nil)))))
    (if get-log-message
        (let* ((patchname
                (with-temp-buffer
                  (when (= (ahg-call-process "qtop") 0)
                    (buffer-substring-no-properties
                     (point-min) (1- (point-max))))))
               (msg (when patchname
                      (concat "Refreshing mq patch: " patchname)))
               (content
                (with-temp-buffer
                  (when
                      (= (if patchname
                             (ahg-call-process "qheader" (list patchname))
                           (ahg-call-process "qheader")) 0)
                    (buffer-substring-no-properties
                     (point-min) (1- (point-max)))))))
          (ahg-log-edit
           (lexical-let ((args (when ahg-diff-use-git-format (list "--git"))))
             (lambda () (interactive) (ahg-mq-log-callback "qrefresh" args)))
           (lexical-let ((flist files)) (lambda () flist))
           buf msg content))
      (ahg-generic-command
       "qrefresh" (append (when (and files ahg-qrefresh-use-short-flag)
                            (list "--short"))
                          (when ahg-diff-use-git-format (list "--git")) files)
       (lexical-let ((aroot (ahg-root)))
         (lambda (process status)
           (if (string= status "finished\n")
               (progn
                 (ahg-status-maybe-refresh aroot)
;;                 (ahg-mq-patches-maybe-refresh aroot)
                 (message "mq command qrefresh successful.")
                 (kill-buffer (process-buffer process)))
             (ahg-show-error process))))))))

(defun ahg-qgoto (patchname force)
  "Puts the given mq patch PATCHNAME on the top of the stack. If
FORCE is non-nil, discard local changes (passing -f to hg). When
called interactively, PATCHNAME and FORCE are read from the minibuffer.
"
  (interactive
   (list (completing-read
          "Go to patch: "
          (ahg-dynamic-completion-table ahg-complete-mq-patch-name))
         (and (ahg-uncommitted-changes-p)
              (ahg-y-or-n-p "Overwrite local changes? "))))
  (let ((args (if force (list "-f" patchname) (list patchname))))
    (ahg-generic-command
     "qgoto" args
     (lexical-let ((aroot (ahg-root)))
       (lambda (process status)
         (if (string= status "finished\n")
             (progn
               (ahg-status-maybe-refresh aroot)
               (ahg-mq-patches-maybe-refresh aroot)
               (let ((msg
                      (with-current-buffer (process-buffer process)
                        (goto-char (point-max))
                        (forward-char -1)
                        (beginning-of-line)
                        (buffer-substring-no-properties
                         (point-at-bol) (point-at-eol)))))
                 (message msg)
                 (if (ahg-string-match-p "^errors " msg)
                     (ahg-show-error process)
                   (kill-buffer (process-buffer process)))))
           (ahg-show-error process)))))))


(defun ahg-qmove (patchname force)
  "Like `ahg-qgoto', but reorder patch series and apply only the given patch."
  (interactive
   (list (completing-read
          "Move to patch: "
          (ahg-dynamic-completion-table ahg-complete-mq-patch-name))
         (and (ahg-uncommitted-changes-p)
              (ahg-y-or-n-p "Overwrite local changes? "))))
  (let ((args (append (list "--move")
                      (if force (list "-f" patchname) (list patchname))))
        (finishfunc
         (lexical-let ((aroot (ahg-root)))
           (lambda (process status)
             (if (string= status "finished\n")
                 (progn
                   (ahg-status-maybe-refresh aroot)
                   (ahg-mq-patches-maybe-refresh aroot)
                   (let ((msg
                          (with-current-buffer (process-buffer process)
                            (goto-char (point-max))
                            (forward-char -1)
                            (beginning-of-line)
                            (buffer-substring-no-properties
                             (point-at-bol) (point-at-eol)))))
                     (message msg)
                     (if (ahg-string-match-p "^errors " msg)
                         (ahg-show-error process)
                       (kill-buffer (process-buffer process)))))
               (ahg-show-error process))))))
    (ahg-generic-command "qpush" args finishfunc)))


(defun ahg-qswitch (patchname force)
  "Like `ahg-qmove', but pop the currently applied patches before moving."
  (interactive
   (list (completing-read
          "Move to patch: "
          (ahg-dynamic-completion-table ahg-complete-mq-patch-name))
         (and (ahg-uncommitted-changes-p)
              (ahg-y-or-n-p "Overwrite local changes? "))))
  (let ((args (append (list "--move")
                      (if force (list "-f" patchname) (list patchname))))
        (finishfunc
         (lexical-let ((aroot (ahg-root)))
           (lambda (process status)
             (if (string= status "finished\n")
                 (progn
                   (ahg-status-maybe-refresh aroot)
                   (ahg-mq-patches-maybe-refresh aroot)
                   (let ((msg
                          (with-current-buffer (process-buffer process)
                            (goto-char (point-max))
                            (forward-char -1)
                            (beginning-of-line)
                            (buffer-substring-no-properties
                             (point-at-bol) (point-at-eol)))))
                     (message msg)
                     (if (ahg-string-match-p "^errors " msg)
                         (ahg-show-error process)
                       (kill-buffer (process-buffer process)))))
               (ahg-show-error process))))))
    (if (ahg-mq-applied-patches-p)
        (ahg-generic-command
         "qpop" (if force (list "-f" "-a") (list "-a"))
         (lexical-let ((aroot (ahg-root))
                       (finishfunc finishfunc)
                       (args args))
           (lambda (process status)
             (if (string= status "finished\n")
                 (ahg-generic-command "qpush" args finishfunc)
               (ahg-show-error process)))))
      (ahg-generic-command "qpush" args finishfunc))))


(defun ahg-qapply (patchname force)
  "Apply the patch PATCHNAME to the working copy, without
actually modifying the status of the repo and of the patch
queue. If there are local changes, proceed only if FORCE is
non-nil. When called interactively, FORCE is read from the
minibuffer."
  (interactive
   (list (completing-read
          "Apply patch (to the working copy): "
          (ahg-dynamic-completion-table ahg-complete-mq-patch-name))
         (and (ahg-uncommitted-changes-p)
              (ahg-y-or-n-p
               "Working copy contains local changes, proceed anyway? "))))
  (let ((aroot (file-name-as-directory (ahg-root)))
        (curwc (current-window-configuration))
        (buffer (generate-new-buffer "*ahg-command*")))
    (with-current-buffer buffer
      (let* ((default-directory aroot)
             (patchfile (concat aroot ".hg/patches/" patchname))
             (args (list "-p" "1" "--no-commit" patchfile)))
        (when force
          (setq args (cons "--force" args)))
        (if (= (ahg-call-process "patch" args) 0)
            (progn
              (kill-buffer)
              (set-window-configuration curwc)
              (message "Applied patch %s to the working copy" patchname))
          (pop-to-buffer buffer)
          (message "Error applying patch %s to the working copy" patchname))))
    (ahg-status-maybe-refresh aroot)))


(defun ahg-qpop-all (force)
  "Pops all patches off the mq stack. If FORCE is non-nil,
discards any local changes. When called interactively, FORCE is
read from the minibuffer.
"
  (interactive
   (list (and (ahg-uncommitted-changes-p)
              (ahg-y-or-n-p "Forget local changes? "))))
  (let ((args (if force (list "-f" "-a") (list "-a"))))
    (ahg-generic-command
     "qpop" args
     (lexical-let ((aroot (ahg-root)))
       (lambda (process status)
         (if (string= status "finished\n")
             (progn
               (ahg-status-maybe-refresh aroot)
               (ahg-mq-patches-maybe-refresh aroot)
               (let ((msg
                      (with-current-buffer (process-buffer process)
                        (goto-char (point-max))
                        (forward-char -1)
                        (beginning-of-line)
                        (buffer-substring-no-properties
                         (point-at-bol) (point-at-eol)))))
                 (message msg))
               (kill-buffer (process-buffer process)))
           (ahg-show-error process)))))))

(defun ahg-qtop ()
  "Shows the name of the mq patch currently at the top of the stack."
  (interactive)
  (ahg-generic-command
   "qtop" nil
   (lambda (process status)
     (if (string= status "finished\n")
         (progn
           (let ((msg
                  (with-current-buffer (process-buffer process)
                    (goto-char (point-max))
                    (forward-char -1)
                    (beginning-of-line)
                    (buffer-substring-no-properties
                     (point-at-bol) (point-at-eol)))))
             (message msg))
           (kill-buffer (process-buffer process)))
       (ahg-show-error process)))))

(defun ahg-qdelete (patchname)
  "Deletes the given patch PATCHNAME. When called interactively,
read the name from the minibuffer."
  (interactive
   (list
    (completing-read
     "Delete patch: "
     (ahg-dynamic-completion-table ahg-complete-mq-patch-name))))
  (ahg-generic-command
   "qdelete" (list patchname)
   (lexical-let ((patchname patchname)
                 (aroot (ahg-root)))
     (lambda (process status)
       (if (string= status "finished\n")
           (progn
             (ahg-mq-patches-maybe-refresh aroot)
             (message "Deleted mq patch %s" patchname)
             (kill-buffer (process-buffer process)))
         (ahg-show-error process))))))


(defun ahg-mq-convert-patch-to-changeset-callback ()
  (interactive)
  (ahg-generic-command ;; first, we refresh the patch with the new log message
   "qrefresh" (list "-m" (ahg-parse-commit-message))
   (lexical-let ((log-buffer (current-buffer)))
     (lambda (process status)
       (kill-buffer log-buffer)
       (if (string= status "finished\n")
           (progn 
             (ahg-generic-command ;; if successful, we then try to convert it to
                                  ;; a regular changeset.
              "qdelete" (list "--rev" "tip")
              (lexical-let ((aroot (ahg-root)))
                (lambda (process status)
                  (if (string= status "finished\n")
                      (progn
                        (ahg-status-maybe-refresh aroot)
                        (ahg-mq-patches-maybe-refresh aroot)
                        (kill-buffer (process-buffer process)))
                    ;; note that if this second command fails, we still have
                    ;; changed the log message... This is not nice, but at the
                    ;; moment I don't know how to fix it
                    (ahg-show-error process)))))
             (kill-buffer (process-buffer process)))
         (ahg-show-error process))))))

(defun ahg-mq-convert-patch-to-changeset ()
  "Tell mq to stop managing the current patch and convert it to a regular
mercurial changeset. The patch must be applied and at the base of the stack.
Pops a buffer for entering the commit message."
  (interactive)
  (let* ((buf (generate-new-buffer "*aHg-log*"))
         (patchname
          (with-temp-buffer
            (when (= (ahg-call-process "qtop") 0)
              (buffer-substring-no-properties
               (point-min) (1- (point-max))))))
         (msg (when patchname
                (concat "Converting mq patch: " patchname
                        " to regular changeset")))
         (content
          (with-temp-buffer
            (when (= (if patchname
                         (ahg-call-process "qheader" (list patchname))
                       (ahg-call-process "qheader")) 0)
              (buffer-substring-no-properties (point-min) (1- (point-max)))))))
    (ahg-log-edit
     'ahg-mq-convert-patch-to-changeset-callback
     (lambda () nil)
     buf
     msg content)))


(defun ahg-qdiff (files)
  "Shows a diff which includes the current mq patch as well as any
changes which have been made in the working directory since the
last refresh."
  (interactive (list (when (eq major-mode 'ahg-status-mode) 
                       (mapcar 'cddr (ahg-status-get-marked nil)))))
  (let ((buf (get-buffer-create "*aHg diff*")))
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (ahg-push-window-configuration)))
    (ahg-generic-command
     "qdiff" (if ahg-diff-use-git-format (append (list "--git") files) files)
     (lexical-let ((aroot (file-name-as-directory (ahg-root))))
       (lambda (process status)
         (if (string= status "finished\n")
             (progn
               (pop-to-buffer (process-buffer process))
               (setq default-directory aroot)
               (ahg-set-diff-mode)
               (goto-char (point-min)))
           (ahg-show-error process))))
     buf)))


(define-generic-mode ahg-mq-series-mode
  '("#") ;; comments
  '() ;; keywords
  '() ;; extra font locks
  '() ;; auto mode list
  '() ;; functions for setup
  "Major mode for editing MQ patch series files.")


(defun ahg-mq-edit-series ()
  (interactive)
  ;; first, check whether there is any patch applied. If so, ask the user
  ;; whethe (s)he wants to pop all patches before editing series
  (let* ((some-patches-applied
         (with-temp-buffer
           (when (= (ahg-call-process "tip" (list "--template" "{tags}")) 0)
             (let ((tags (split-string (buffer-string))))
               (member "qtip" tags)))))
         (pop (and some-patches-applied
                   (ahg-y-or-n-p "Pop all patches before editing series? ")))
         (edit-series (lambda (root)
                        (find-file-other-window
                         (concat (file-name-as-directory root)
                                 ".hg/patches/series"))
                        (ahg-mq-series-mode))))
      (if pop
          (ahg-generic-command
           "qpop" (list "--all")
           (lexical-let ((aroot (ahg-root))
                         (edit-series edit-series))
             (lambda (process status)
               (if (string= status "finished\n")
                   (progn
                     (ahg-status-maybe-refresh aroot)
                     (ahg-mq-patches-maybe-refresh aroot)
                     (funcall edit-series aroot)
                     (kill-buffer (process-buffer process)))
                 (ahg-show-error process)))))
        (funcall edit-series (ahg-root)))))


(defvar ahg-mq-patches-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [?q] 'ahg-buffer-quit)
    (define-key map [?g] 'ahg-mq-patch-list-refresh)
    (define-key map [?D] 'ahg-mq-patches-delete-patch)
    (define-key map [?!] 'ahg-mq-do-command)
    (define-key map [?h] 'ahg-command-help)
    (define-key map [?=] 'ahg-mq-patches-view-patch)
    (define-key map [?\r] 'ahg-mq-patches-goto-patch)
    (define-key map [?m] 'ahg-mq-patches-moveto-patch)
    (define-key map [?s] 'ahg-mq-patches-switchto-patch)
    (define-key map [?a] 'ahg-mq-patches-apply-patch)
    (define-key map [?p] 'ahg-qpop-all)
    (define-key map [?n] 'ahg-qnew)
    (define-key map [?e] 'ahg-mq-edit-series)
    (define-key map [?f] 'ahg-mq-patches-convert-patch-to-changeset)
    (define-key map [?r] 'ahg-mq-patches-qrefresh)
    map)
  "Keymap used in `ahg-mq-patches-mode'.")

(defvar ahg-mq-patches-line-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mouse-1] 'ahg-mq-patches-view-patch-mouse)
    (define-key map [mouse-2] 'ahg-mq-patches-goto-patch-mouse)
    map))

(easy-menu-define ahg-mq-patches-mode-menu ahg-mq-patches-mode-map
  "aHg MQ Patches"
  '("aHg MQ Patches"
    ["View Patch" ahg-mq-patches-view-patch [:keys "=" :active t]]
    ["Go to Patch" ahg-mq-patches-goto-patch [:keys "\r" :active t]]
    ["Move to Patch" ahg-mq-patches-moveto-patch [:keys "m" :active t]]
    ["Switch to Patch" ahg-mq-patches-switchto-patch [:keys "s" :active t]]
    ["Apply Patch to the Working Copy" ahg-mq-patches-apply-patch
     [:keys "a" :active t]]
    ["New Patch..." ahg-qnew [:keys "n" :active t]]
    ["Delete Patch" ahg-mq-patches-delete-patch [:keys "D" :active t]]
    ["Pop All Patches" ahg-qpop-all [:keys "p" :active t]]
    ["Edit series File" ahg-mq-edit-series [:keys "e" :active t]]
    ["--" nil nil]
    ["Refresh Current Patch" ahg-mq-patches-qrefresh [:keys "r" :active t]]
    ["Convert Current Patch to Changeset"
     ahg-mq-patches-convert-patch-to-changeset [:keys "f" :active t]]
    ["--" nil nil]
    ["Hg Command" ahg-mq-do-command [:keys "!" :active t]]
    ["Help on Hg Command" ahg-command-help [:keys "h" :active t]]
    ["--" nil nil]
    ["Refresh" ahg-mq-patch-list-refresh [:keys "g" :active t]]
    ["Quit" ahg-buffer-quit [:keys "q" :active t]]
    ))

(define-derived-mode ahg-mq-patches-mode special-mode "ahg-mq-patches"
  "Major mode to display mq patch queues.

Commands:
\\{ahg-mq-patches-mode-map}
"
  (buffer-disable-undo) ;; undo info not needed here
  (use-local-map ahg-mq-patches-mode-map)
  (font-lock-mode nil)
  ;;(hl-line-mode t)
  (setq truncate-lines t)
  (setq buffer-read-only t)
  (easy-menu-add ahg-mq-patches-mode-menu ahg-mq-patches-mode-map)
  )

(defun ahg-mq-patch-pp (data)
  "Pretty-printer for mq patches patch list."
  ;; data is a 4-elements list: index, applied, patch name, guards
  (let* ((s (format "% 6d |  %s  | %s %s" (car data)
                   (if (cadr data) "*" " ") (caddr data)
                   (if (not (string= (car (cadddr data)) "unguarded"))
                       (cadddr data) "")))
         (width (window-width (selected-window)))
         (pad (if (< (length s) width)
                  (make-string (- width (length s)) ? ) "")))
    (insert (propertize (concat s pad)
                        'mouse-face 'highlight
                        'keymap ahg-mq-patches-line-map))))

(defun ahg-mq-patches-insert-contents (ewoc patches applied guards)
  (let ((idx 0))
    (mapcar
     (lambda (patch)
       (when (not (string-match patch "[ \t]+"))
         (let ((data (list idx
                           (member patch applied)
                           patch
                           (cdr (assoc patch guards)))))
           (setq idx (1+ idx))
           (ewoc-enter-last ewoc data))))
     patches)))

(defun ahg-mq-patches-create-ewoc ()
  (let* ((width (window-width (selected-window)))
         (r (propertize (make-string width ?-) 'face 'bold))
         (header (concat
                  (propertize "mq patch queue for " 'face ahg-header-line-face)
                  (propertize default-directory 'face ahg-header-line-root-face)
                  "\n\n" r "\n"
                  (propertize " Index | App | Patch (Guards)\n" 'face 'bold) r))
         (footer r)
         (ew (ewoc-create 'ahg-mq-patch-pp header footer)))
    ew))

(defun ahg-mq-show-patches-buffer (buf patches applied guards curdir no-pop
                                       point-pos)
  (with-current-buffer buf
    (ahg-mq-patches-mode)    
    (let ((inhibit-read-only t))
      (erase-buffer)
      (setq default-directory (file-name-as-directory curdir))
      (ahg-push-window-configuration)
      (goto-char (point-min))
      (let ((ew (ahg-mq-patches-create-ewoc)))
        (ahg-mq-patches-insert-contents ew patches applied guards)
        (set (make-local-variable 'ewoc) ew)))
      (setq buffer-read-only t)
      (if point-pos
          (ahg-goto-line-point point-pos)
        (goto-char (point-min))
        (forward-line 1))
      (set-buffer-modified-p nil)
      (message " "))
  (unless no-pop
    (pop-to-buffer buf)))


(defun ahg-mq-get-patches-buffer (root &optional dont-create)
  (let* ((name (format "*aHg mq patches for: %s*" root))
         (buf (if dont-create (get-buffer name) (get-buffer-create name))))
    (when buf
      (with-current-buffer buf
        (setq default-directory (file-name-as-directory root))))
    buf))


(defvar ahg-mq-list-patches-no-pop nil)
(defvar ahg-mq-patches-buffer-point nil)

(defun ahg-mq-list-patches (&optional root)
  "List all mq patches in the queue, showing also information
about which are currently applied."
  (interactive)
  (unless root (setq root (ahg-root)))
  (let ((buf (ahg-mq-get-patches-buffer root))
        (msg (when (called-interactively-p 'interactive)
               (format "aHg: getting patch queue for %s..." root)))
        (oldcolumns (getenv "COLUMNS")))
    (when msg (message msg))
    (setenv "COLUMNS" "100000")
    (ahg-generic-command
     "qseries" nil
     (lexical-let ((buf buf)
                   (curdir default-directory)
                   (aroot root)
                   (no-pop ahg-mq-list-patches-no-pop)
                   (point-pos ahg-mq-patches-buffer-point)
                   (msg msg))
       (lambda (process status) ;; parse output of hg qseries
         (if (string= status "finished\n")
             (let ((patches
                    (with-current-buffer (process-buffer process)
                      (split-string (buffer-string) "\n"))))
               (kill-buffer (process-buffer process))
               (setenv "COLUMNS" "100000")
               (ahg-generic-command
                "qapplied" nil
                (lexical-let ((buf buf)
                              (patches patches)
                              (curdir curdir)
                              (no-pop no-pop)
                              (point-pos point-pos)
                              (msg msg))
                  (lambda (process status) ;; parse output of hg qapplied
                    (if (string= status "finished\n")
                        (let ((applied
                               (with-current-buffer (process-buffer process)
                                 (split-string (buffer-string) "\n"))))
                          (kill-buffer (process-buffer process))
                          ;; now, list guards as well
                          (ahg-generic-command
                           "qguard" (list "-l")
                           (lexical-let ((buf buf)
                                         (patches patches)
                                         (applied applied)
                                         (curdir curdir)
                                         (no-pop no-pop)
                                         (point-pos point-pos)
                                         (msg msg))
                             (lambda (process status)
                               (if (string= status "finished\n")
                                   (let
                                       ((guards
                                         (with-current-buffer
                                             (process-buffer process)
                                           (mapcar
                                            (lambda (s) (split-string s ": "))
                                            (split-string
                                             (buffer-string) "\n")))))
                                     (kill-buffer (process-buffer process))
                                     ;; and show the buffer
                                     (ahg-mq-show-patches-buffer
                                      buf patches applied guards curdir
                                      no-pop point-pos)
                                     (when msg (message "%sdone" msg)))
                                 ;; error in hg qguard
                                 (kill-buffer buf)
                                 (ahg-show-error process)))) nil nil t))
                      ;; error in hg qapplied
                      (kill-buffer buf)
                      (ahg-show-error process)))) nil nil t))
           ;; error in hg qseries
           (kill-buffer buf)
           (ahg-show-error process))))
     nil nil t)
    ;; restore the COLUMNS env var
    (setenv "COLUMNS" oldcolumns)
    ))


(defun ahg-mq-patch-list-refresh ()
  (interactive)
  (let ((ahg-mq-patches-buffer-point (ahg-line-point-pos)))
    (call-interactively 'ahg-mq-list-patches)))


(defun ahg-mq-patches-maybe-refresh (root)
  (when ahg-auto-refresh-status-buffer
    (let ((buf (ahg-mq-get-patches-buffer root t))
          (default-directory (file-name-as-directory root)))
      (when buf
        (let ((ahg-mq-list-patches-no-pop t)
              (ahg-mq-patches-buffer-point
               (with-current-buffer buf (ahg-line-point-pos))))
          (ahg-mq-list-patches root))))))


(defun ahg-mq-patches-view-patch ()
  "Display the patch at point in the patch list buffer."
  (interactive)
  (let ((patch (ahg-mq-patches-patch-at-point))
        (root (ahg-root)))
    (when patch
      (find-file-other-window
       (concat (file-name-as-directory root) ".hg/patches/" patch))
      (ahg-set-diff-mode))))

(defun ahg-mq-patches-patch-at-point ()
  (let ((node (ewoc-locate ewoc)))
    (and node (caddr (ewoc-data node)))))


(defun ahg-mq-patches-goto-patch ()
  "Puts the patch at point in the patch list buffer on top of the
stack of applied patches."
  (interactive)
  (let* ((patch (ahg-mq-patches-patch-at-point))
         (ok (and patch (ahg-y-or-n-p (format "Go to patch %s? " patch))))
         (force (and ok (ahg-uncommitted-changes-p)
                     (ahg-y-or-n-p "Overwrite local changes? "))))
    (when ok
      (ahg-qgoto patch force))))


(defun ahg-mq-patches-moveto-patch ()
  "Like `ahg-mq-patches-goto-patch', but reorder patch series and
apply only the given patch."
  (interactive)
  (let* ((patch (ahg-mq-patches-patch-at-point))
         (ok (and patch (ahg-y-or-n-p (format "Move to patch %s? " patch))))
         (force (and ok (ahg-uncommitted-changes-p)
                     (ahg-y-or-n-p "Overwrite local changes? "))))
    (when ok
      (ahg-qmove patch force))))


(defun ahg-mq-patches-switchto-patch ()
  "Pop all applied patches and move to the given patch."
  (interactive)
  (let* ((patch (ahg-mq-patches-patch-at-point))
         (ok (and patch (ahg-y-or-n-p (format "Switch to patch %s? " patch))))
         (force (and ok (ahg-uncommitted-changes-p)
                     (ahg-y-or-n-p "Overwrite local changes? "))))
    (when ok
      (ahg-qswitch patch force))))


(defun ahg-mq-patches-apply-patch ()
  "Apply the given patch to the working copy, without modifying the repository."
  (interactive)
  (let* ((patch (ahg-mq-patches-patch-at-point))
         (ok (and patch
                  (ahg-y-or-n-p
                   (format "Apply patch %s to the working copy? " patch))))
         (force (and
                 ok (ahg-uncommitted-changes-p)
                 (ahg-y-or-n-p
                  "Working copy contains local changes, proceed anyway? "))))
    (when ok
      (ahg-qapply patch force))))


(defun ahg-mq-patches-view-patch-mouse (event)
  (interactive "e")
  (save-window-excursion
    (select-window (posn-window (event-end event)) t)
    (goto-char (posn-point (event-end event)))
    (ahg-mq-patches-view-patch)))


(defun ahg-mq-patches-goto-patch-mouse (event)
  (interactive "e")
  (save-window-excursion
    (select-window (posn-window (event-end event)) t)
    (goto-char (posn-point (event-end event)))
    (ahg-mq-patches-goto-patch)))


(defun ahg-mq-patches-delete-patch ()
  "Deletes the patch at point in the patch list buffer."
  (interactive)
  (let* ((patch (ahg-mq-patches-patch-at-point))
         (ok (and patch (ahg-y-or-n-p (format "Delete patch %s? " patch)))))
    (when ok
      (ahg-qdelete patch))))


(defun ahg-mq-get-current-patch ()
  (with-temp-buffer
    (when (= (ahg-call-process "qtop") 0)
      (buffer-substring-no-properties (point-min) (1- (point-max))))))

(defun ahg-mq-patches-qrefresh (get-log-message)
  (interactive "P")
  (let ((curpatch (ahg-mq-get-current-patch)))
    (if curpatch
        (and (ahg-y-or-n-p (format "Refresh current patch (%s)? " curpatch))
             (ahg-qrefresh get-log-message))
      (message "aHg Error: unable to determine current patch!"))))


(defun ahg-mq-patches-convert-patch-to-changeset ()
  (interactive)
  (let ((curpatch (ahg-mq-get-current-patch)))
    (if curpatch
        (and (ahg-y-or-n-p (format "Convert current patch (%s) to changeset? "
                                   curpatch))
             (ahg-mq-convert-patch-to-changeset))
      (message "aHg Error: unable to determine current patch!"))))


(defun ahg-mq-do-command ()
  "Call `ahg-do-command', but set `default-directory' to the MQ patches dir,
so that filename completion works on patch names."
  (interactive)
  (let ((ahg-complete-command-directory-for-filename-completion
         (concat (file-name-as-directory (ahg-root)) ".hg/patches/")))
    (call-interactively 'ahg-do-command)))


;;-----------------------------------------------------------------------------
;; ahg-record and related functions
;;-----------------------------------------------------------------------------

(defun ahg-record-setup (root selected-files)
  (setq root (file-name-as-directory root))
  ;;(message "ROOT IS: %s" root)
  (let* ((backup (concat root ".hg/ahg-record-backup"))
         (curpatch (concat root ".hg/ahg-record-patch"))
         (isthere (or (file-exists-p backup) (file-symlink-p backup)))
         (parents (with-temp-buffer
                    (when (and (ahg-cd root)
                               (= (ahg-call-process
                                   "parents"
                                   (list "--template" "{node} ")) 0))
                      (split-string (buffer-string)))))
         (addremove (with-temp-buffer
                      (or (not (and (ahg-cd root)
                                    (= (ahg-call-process
                                        "status"
                                        (list "-a" "-d" "-r")) 0)))
                          (> (buffer-size) 0)))))
    (cond (isthere
           ;; we don't want to overwrite old backups
           (error
            (format "stale ahg-record backup file detected in `%s', aborting"
                    backup)))
          ((not (= (length parents) 1))
           ;; this is either an uncommitted merge, or we failed to get the
           ;; parents
           (error
            (if (null parents)
                "could not in determine parents of working dir, aborting"
              "uncommitted merge detected, aborting")))
          (addremove
           ;; pending additions/deletions are not supported
           (error "pending additions and/or deletions detected, aborting"))
          (t
           ;; create the patch
           (let ((patchbuf (generate-new-buffer "*aHg-record*")))
             (with-current-buffer patchbuf
               (if (and (ahg-cd root)
                        (= (ahg-call-process "diff" (list "--git")) 0))
                   (progn
                     ;; write the backup
                     (goto-char (point-min))
                     (insert "# aHg record parent: "
                             (car parents) "\n")
                     (write-file backup)
                     ;; now, generate the patch to edit
                     (kill-buffer)
                     (setq patchbuf (generate-new-buffer "*aHg-record*"))
                     (with-current-buffer patchbuf
                       (ahg-push-window-configuration)
                       (if (null selected-files)
                           ;; if there are no selected files, we can simply
                           ;; copy the backup file, thus saving an hg call
                           (progn
                             (insert-file-contents backup)
                             (goto-char (point-min))
                             (when (looking-at "^# aHg record parent: ")
                               (let ((kill-whole-line t))
                                 (kill-line))))
                         ;; otherwise, let's call hg diff again
                         (unless (and (ahg-cd root)
                                      (= (ahg-call-process
                                          "diff"
                                          (append (list "--git")
                                                  selected-files)) 0))
                           (kill-buffer)
                           (error "impossible to generate diff")))
                       (goto-char (point-min))
                       ;; if there are binary files, abort
                       (save-excursion
                         (while (not (eobp))
                           (re-search-forward "^diff --git [^\n]*$" nil 1)
                           (forward-line 2)
                           (beginning-of-line)
                           (if (looking-at "^GIT binary patch$")
                               (error "binary files in patch, aborting"))))
                       ;; insert header
                       (insert "# aHg record interactive buffer\n"
                               "# edit this patch file, and press C-c C-c when done to commit the changes\n"
                               "# if something goes wrong, there's a backup file in\n"
                               "# " backup "\n\n")
                       ;; now, let's return all the needed data
                       (list backup curpatch (car parents) patchbuf)))
                 ;; error occurred, delete the buffer and raise exception
                 (kill-buffer)
                 (error "impossible to generate diff"))))))))


(defun ahg-do-record (selected-files commit-func &rest commit-func-args)
  (condition-case err
      (let* ((root (ahg-root))
             (data (ahg-record-setup root selected-files))
             (backup (car data))
             (curpatch (cadr data))
             (parent (caddr data))
             (patchbuf (cadddr data)))
        (switch-to-buffer patchbuf)
        (ahg-cd root)
        (ahg-set-diff-mode)
        (setq buffer-read-only nil)
        (local-set-key
         (kbd "C-c C-c")
         (lexical-let ((root root)
                       (backup backup)
                       (curpatch curpatch)
                       (parent parent)
                       (commit-func commit-func)
                       (commit-func-args commit-func-args))
           (lambda ()
             (interactive)
             (apply commit-func
                    root backup curpatch parent commit-func-args)))))
    (error
     (let ((buf (generate-new-buffer "*aHg-record*")))
       (ahg-show-error-msg (format "aHg record error: %s"
                                   (error-message-string err)) buf)))))


(defun ahg-record (selected-files)
  "Interactively select which changes to commit. Similar in
spirit to the crecord hg extension, but using the patch editing
functionalities provided by Emacs."
  (interactive
   (list (when (eq major-mode 'ahg-status-mode) 
           (mapcar 'cddr
                   (ahg-status-get-marked
                    nil (lambda (d) (not (string= (cadr d) "?"))))))))
  (ahg-do-record selected-files 'ahg-record-commit))


(defun ahg-record-commit (root backup curpatch parent)
  (let ((buf (generate-new-buffer "*aHg-log*")))
    ;; save the contents of the patch
    (write-file curpatch)
    (ahg-log-edit
     (lexical-let ((root root)
                   (backup backup)
                   (curpatch curpatch)
                   (parent parent)
                   (patchbuf (current-buffer))
                   (buf buf))
       (lambda ()
         (interactive)
         (with-current-buffer patchbuf
           (set-buffer-modified-p nil))
         (let ((msg (ahg-parse-commit-message)))
           (kill-buffer buf)
           (ahg-record-commit-callback
            "commit" (list "-m" msg)
            root backup curpatch parent patchbuf))))
     (lambda () nil)
     buf)))


(defun ahg-record-commit-callback (commit-cmd commit-args root backup
                                              curpatch parent patchbuf)
  (let ((args (list "-r" parent "--all" "--no-backup"))
        (buf (generate-new-buffer "*aHg-record*")))
    (lexical-let ((root root)
                  (backup backup)
                  (curpatch curpatch)
                  (parent parent)
                  (commit-cmd commit-cmd)
                  (commit-args commit-args)
                  (buf buf)
                  (patchbuf patchbuf))
      (let* ((phase5
              (lambda (process status)
                (switch-to-buffer buf)
                (if (string= status "finished\n")
                    ;; 5. apply the backup patch
                    (if (and (ahg-cd root)
                             (= (ahg-call-process
                                 "import" (list "--force" "--no-commit" backup))
                                0))
                        ;; 6. delete the backup files
                        (let ((sbuf (ahg-get-status-buffer root))
                              (cfg (with-current-buffer patchbuf
                                     ahg-window-configuration)))
                          (delete-file curpatch)
                          (delete-file backup)
                          (kill-buffer buf)
                          (kill-buffer patchbuf)
                          (ahg-status-maybe-refresh root)
                          (ahg-mq-patches-maybe-refresh root)
                          (set-window-configuration cfg)
                          (when sbuf (pop-to-buffer sbuf))
                          (message "changeset recorded successfully."))
                      ;; error
                      (ahg-show-error-msg
                       (format "error in applying patch `%s'" backup)))
                  ;; error
                  (ahg-show-error process))))
             (phase4
              (lexical-let ((phase5 phase5))
                (lambda (process status)
                  (switch-to-buffer buf)
                  (if (string= status "finished\n")
                      (let ((args (list "--force" "--no-commit" curpatch)))
                        ;; 2. apply the patch
                        (if (and (ahg-cd root)
                                 (= (ahg-call-process "import" args) 0))
                            (ahg-generic-command
                             commit-cmd commit-args
                             (lexical-let ((phase5 phase5))
                               (lambda (process status)
                                 (switch-to-buffer buf)
                                 (if (string= status "finished\n")
                                     ;; 4. update to the parent rev again
                                     (ahg-generic-command
                                      "revert"
                                      (list "-r" parent "--all" "--no-backup")
                                      phase5
                                      buf)
                                   ;; error
                                   (ahg-show-error process))))
                             buf)
                          ;; error
                          (ahg-show-error-msg
                           (format "error in applying patch `%s'" curpatch))))
                    ;; error
                    (ahg-show-error process))))))
    ;; 1. update to parent rev
    (with-current-buffer buf
      (if (ahg-cd root)
          (ahg-generic-command
           "revert"
           args
           (lexical-let ((phase4 phase4))
             phase4)
           buf)
        (ahg-show-error-msg (format "can't cd to %s" root) buf)))))))


(defun ahg-record-mq-commit (root backup curpatch parent mq-command mq-args)
  ;; save the contents of the patch
  (write-file curpatch)
  (set-buffer-modified-p nil)
  (ahg-record-commit-callback mq-command mq-args root backup curpatch parent
                              (current-buffer)))


(defun ahg-record-qnew (patchname selected-files)
  "Interactively select which changes to include in the new mq patch PATCHNAME.
Similar in spirit to the crecord hg extension, but using the
patch editing functionalities provided by Emacs."
  (interactive
   (list (read-string "Patch name: ")
         (when (eq major-mode 'ahg-status-mode)
           (mapcar 'cddr (ahg-status-get-marked nil)))))
  (ahg-do-record selected-files 'ahg-record-mq-commit
                 "qnew" (append (when ahg-diff-use-git-format (list "--git"))
                                (list "--force" patchname))))

                                          
;;-----------------------------------------------------------------------------
;; History editing
;;-----------------------------------------------------------------------------

(defun ahg-histedit-check-ok (root rev)
  (with-temp-buffer
    (let ((args (list "--template" "{node|short}\\n"
                      "-r" (format "descendants(%s) & (branchpoint() + merge() + public())" rev))))
      (if (and (ahg-cd root) (= (ahg-call-process "log" args) 0))
          (= (point-min) (point-max))
        nil))))


(defun ahg-histedit-backup (root op rev)
  (let* ((backupdir (concat (file-name-as-directory root)
                            ".hg/ahg-histedit-backup/"))
         (backupname (concat backupdir (format "%s-%s-bundle.hg" op rev)))
         (args (list "--base" (format "not descendants(parents(%s))" rev)
                     backupname)))
    (make-directory backupdir t)
    (with-temp-buffer
      (when (= (ahg-call-process "bundle" args) 0)
        backupname))))


(defun ahg-histedit-setup (root op rev)
  ;; check that there are no uncommitted changes
  (cond ((ahg-uncommitted-changes-p root)
         (error "the working directory contains uncommited changes, aborting"))
        ((not (ahg-histedit-check-ok root rev))
         (error "unsupported history layout (non-linear and/or public changesets detected), aborting"))
        (t
         (let ((backupname (ahg-histedit-backup root op rev)))
           (if backupname backupname
             (error "history backup failed, aborting"))))))


(defun ahg-histedit-rev-id (rev)
  (let ((r (ahg-rev-id rev)))
    (if (or (null r) (string= r "") (string-match "^.* .*$" r))
        (error "bad revision number %s" rev)
      r)))

(defun ahg-histedit-rollback (op root rev backupfile &optional process)
  (when process
    (ahg-show-error process))
  (message "ahg histedit %s on rev %s failed, rolling back" op rev)
  (ahg-generic-command
   "strip" (list "--no-backup" "-r" rev)
   (lexical-let ((root root)
                 (backupfile backupfile))
     (lambda (process status)
       (if (string= status "finished\n")
           (progn
             (kill-buffer (process-buffer process))
             (ahg-generic-command
              "pull" (list backupfile)
              (lambda (process status)
                (if (string= status "finished\n")
                    (message "ahg histedit rollback completed"))
                (ahg-show-error process))))
         (ahg-show-error process))))
   nil
   nil
   nil
   nil
   nil
   nil
   nil
   (list "--config" "extension.hgext.strip=") ;; global-opts
   ))
                                 

(defun ahg-histedit-goto (rev parent)
  (with-temp-buffer
    (unless (= (ahg-call-process
                "update"
                (list "-r" (if parent (format "p1(%s)" rev) rev))) 0)
      (error "failed to update to %s%s" (if parent "parent of " "") rev))))


(defun ahg-histedit-do-drop (rev keep)
  (condition-case err
      (let* ((root (ahg-root))
             (rev (ahg-histedit-rev-id rev))
             (op (if keep "xtract" "drop"))
             (backupfile (ahg-histedit-setup root op rev))
             (head (ahg-histedit-is-head rev))
             (doit (lexical-let ((root root)
                                 (backupfile backupfile)
                                 (rev rev)
                                 (keep keep))
                     (lambda (process status)
                       (let ((op (if keep "xtract" "drop")))
                         (if (string= status "finished\n")
                             (progn
                               (kill-buffer (process-buffer process))
                               (if keep
                                   (with-temp-buffer
                                     (if (= (ahg-call-process
                                              "update"
                                              (list "-r" rev)) 0)
                                         (message "extracted changeset %s" rev)
                                       (ahg-histedit-rollback op root rev
                                                              backupfile)))
                                 (message "dropped changeset %s" rev)))
                           (ahg-histedit-rollback op root rev
                                                  backupfile process)))))))
        ;; to drop a changeset, we simply graft the descendants onto the parent
        (if head
            (if keep
                (message "nothing to do")
              (ahg-generic-command
               "strip" (list "--no-backup" "-r" rev)
               doit
               nil
               nil
               nil
               nil
               nil
               nil
               nil
               (list "--config" "extension.hgext.strip=") ;; global-opts
               ))
          (ahg-histedit-goto rev t)
          (ahg-generic-command
           "rebase"
           (list "-r" (format "descendants(%s) & not %s" rev rev) "-d" ".")
           (if keep
               doit
             (lexical-let ((root root)
                           (backupfile backupfile)
                           (rev rev)
                           (keep keep)
                           (doit doit))
               (lambda (process status)
                 (if (string= status "finished\n")
                     (progn
                       (kill-buffer (process-buffer process))
                       ;; strip the dropped changeset and descendants
                       (ahg-generic-command
                        "strip" (list "--no-backup" "-r" rev)
                        doit))
                   (ahg-histedit-rollback (if keep "xtract" "drop")
                                          root rev backupfile process)))))
           nil
           nil
           nil
           nil
           nil
           nil
           nil
           (list "--config" "extension.hgext.rebase=") ;; global-opts
           )))
    (error (let ((buf (generate-new-buffer "*aHg-histedit*")))
             (ahg-show-error-msg (format "aHg histedit error: %s"
                                         (error-message-string err)) buf)))))


(defun ahg-histedit-drop (rev)
  (interactive "sEnter revision to drop: ")
  (ahg-histedit-do-drop rev nil))


(defun ahg-histedit-xtract (rev)
  (interactive "sEnter revision to extract: ")
  (ahg-histedit-do-drop rev t))


(defun ahg-histedit-edit-phase2-helper (op msg root rev backupfile
                                           head strip-parent)
  (lexical-let ((op op)
                (msg msg)
                (root root)
                (rev rev)
                (backupfile backupfile)
                (head head)
                (strip-parent strip-parent))
    (lambda (process status)
      (if (and (ahg-cd root) (string= status "finished\n"))
          (if head
              (message "%s changeset %s (now become %s)" msg rev
                       (ahg-histedit-rev-id "."))
            ;; restore the bundle and rebase it
            (kill-buffer (process-buffer process))
            (ahg-generic-command
             "pull" (list backupfile)
             (lexical-let ((op op)
                           (msg msg)
                           (root root)
                           (rev rev)
                           (backupfile backupfile)
                           (strip-parent strip-parent))
               (lambda (process status)
                 (if (and (ahg-cd root) (string= status "finished\n"))
                     (progn
                       (kill-buffer (process-buffer process))
                       (ahg-generic-command
                        "rebase" (list "-d" "." "-r"
                                       (format "descendants(%s) & not %s"
                                               rev rev))
                        (lexical-let ((op op)
                                      (msg msg)
                                      (root root)
                                      (rev rev)
                                      (backupfile backupfile)
                                      (strip-parent strip-parent))
                          (lambda (process status)
                            (if (and (ahg-cd root)
                                     (string= status "finished\n"))
                                ;; strip the old changeset
                                (with-temp-buffer
                                  (kill-buffer (process-buffer process))
                                  (if (= (ahg-call-process
                                          "strip"
                                          (list "--no-backup" "-r"
                                                (if strip-parent
                                                    (format "p1(%s)" rev)
                                                  rev))
                                          (list "--config"
                                                "extension.hgext.strip=")) 0)
                                      (message "%s changeset %s (now become %s)"
                                               msg rev
                                               (ahg-histedit-rev-id "."))
                                    (ahg-histedit-rollback
                                     op root rev backupfile)))
                              (ahg-histedit-rollback op root rev backupfile
                                                     process))))
                        nil
                        nil
                        nil
                        nil
                        nil
                        nil
                        nil
                        (list "--config" "extension.hgext.rebase=")))
                   (ahg-histedit-rollback op root rev backupfile process))))))
        (ahg-histedit-rollback op root rev backupfile process)))))


(defun ahg-histedit-is-head (rev)
  (with-temp-buffer
    (if (= (ahg-call-process "log" (list "-r" (concat rev " & head()")
                                         "--template" "{node|short}")) 0)
        (> (point-max) (point-min))
      (error "error checking if %s is a head" rev) nil)))


(defun ahg-histedit-mess-callback (root rev)
  (condition-case err
      (let ((msg (ahg-parse-commit-message))
            (backupfile (ahg-histedit-setup root "mess" rev))
            (ahg-restore-window-configuration-on-quit t)
            (head (ahg-histedit-is-head rev)))
        (ahg-pop-window-configuration)
        (kill-buffer (current-buffer))
        (unless (ahg-cd root)
          (error "can't cd to %s" root))
        (ahg-histedit-goto rev nil)
        (if head
            (ahg-generic-command
             "commit" (list "--amend" "-m" msg)
             (ahg-histedit-edit-phase2-helper
              "mess" "edited commit message of" root rev backupfile head nil))
          (ahg-generic-command
           "strip" (list "--no-backup" "-r" (format "children(%s)" rev))
           (lexical-let ((root root)
                         (rev rev)
                         (backupfile backupfile)
                         (msg msg)
                         (head head))
             (lambda (process status)
               (if (and (ahg-cd root) (string= status "finished\n"))
                   (progn
                     (kill-buffer (process-buffer process))
                     (ahg-generic-command
                      "commit" (list "--amend" "-m" msg)
                      (ahg-histedit-edit-phase2-helper
                       "mess" "edited commit message of" root rev backupfile
                       head nil)))
                 (ahg-histedit-rollback "mess" root rev backupfile
                                        process))))
           nil
           nil
           nil
           nil
           nil
           nil
           nil
           (list "--config" "extension.hgext.strip=") ;; global-opts
           )))
    (error (let ((buf (generate-new-buffer "*aHg-histedit*")))
             (ahg-show-error-msg (format "aHg histedit error: %s"
                                         (error-message-string err)) buf)))))


(defun ahg-histedit-get-message (rev)
  (with-temp-buffer
    (if (= (ahg-call-process "log" (list "-r" rev "--template" "{desc}")) 0)
        (buffer-string)
      (error "error retrieving commit message of %s" rev) "")))
  

(defun ahg-histedit-mess (rev)
  (interactive "sEnter revision of message to edit: ")
  (let (buf root msg content noedit)
    (condition-case err
        (progn
          (setq buf (generate-new-buffer "*aHg-log*"))
          (setq root (ahg-root))
          (setq rev (ahg-histedit-rev-id rev))
          (setq msg (concat "Editing commit message of revision " rev))
          (setq content (ahg-histedit-get-message rev)))
      (error (let ((buf (generate-new-buffer "*aHg-histedit*")))
               (setq noedit t)
               (ahg-show-error-msg (format "aHg histedit error: %s"
                                           (error-message-string err)) buf))))
    (unless noedit
      (with-current-buffer buf
        (ahg-push-window-configuration))
      (ahg-log-edit
       (lexical-let ((root root)
                     (rev rev))
         (lambda () (interactive) (ahg-histedit-mess-callback root rev)))
       (lambda () nil)
       buf
       msg content))))


(defun ahg-histedit-do-fold (op msg backupfile root rev)
  (ahg-histedit-goto (format "p1(p1(%s))" rev) nil)
  (let* ((head (ahg-histedit-is-head rev))
         (doit (lexical-let ((op op)
                             (root root)
                             (rev rev)
                             (backupfile backupfile)
                             (head head))
                 (lambda (process status)
                   (if (and (ahg-cd root) (string= status "finished\n"))
                       ;; update to the new tip
                       (progn
                         (kill-buffer (process-buffer process))
                         (ahg-generic-command
                          "update" (list "-r" "tip")
                          (ahg-histedit-edit-phase2-helper
                           op "folded" root rev backupfile head t)))
                     (ahg-histedit-rollback
                      op root rev backupfile process))))))
    (if head
        (ahg-generic-command
         "rebase" (list "-r" rev "-r" (format "p1(%s)" rev) "-d" "."
                        "--collapse" "-m" msg)
         doit
         nil
         nil
         nil
         nil
         nil
         nil
         nil
         (list "--config" "extension.hgext.rebase=") ;; global-opts
         )
      (ahg-generic-command
       "strip" (list "--no-backup" "-r" (format "children(%s)" rev))
       (lexical-let ((op op)
                     (root root)
                     (rev rev)
                     (backupfile backupfile)
                     (msg msg)
                     (doit doit))
         (lambda (process status)
           (if (and (ahg-cd root) (string= status "finished\n"))
               (progn
                 (kill-buffer (process-buffer process))
                 (ahg-generic-command
                  "rebase" (list "-r" rev "-r" (format "p1(%s)" rev) "-d" "."
                                 "--collapse" "-m" msg)
                  doit))
             (ahg-histedit-rollback op root rev backupfile process))))
       nil
       nil
       nil
       nil
       nil
       nil
       nil
       (list "--config" "extension.hgext.strip=") ;; global-opts       
       ))))


(defun ahg-histedit-fold-callback (root rev)
  (condition-case err
      (let ((msg (ahg-parse-commit-message))
            (backupfile (ahg-histedit-setup root "fold" rev))
            (ahg-restore-window-configuration-on-quit t))
        (ahg-pop-window-configuration)
        (kill-buffer (current-buffer))
        (ahg-histedit-do-fold "fold" msg backupfile root rev))
    (error (let ((buf (generate-new-buffer "*aHg-histedit*")))
             (ahg-show-error-msg (format "aHg histedit error: %s"
                                         (error-message-string err)) buf)))))


(defun ahg-histedit-fold (rev)
  (interactive "sEnter revision to fold: ")
  (let (buf root msg args content noedit)
    (condition-case err
        (progn
          (setq buf (generate-new-buffer "*aHg-log*"))
          (setq root (ahg-root))
          (setq rev (ahg-histedit-rev-id rev))
          (setq msg (concat "Folding revision " rev " into parent"))
          (setq args (list "-r" rev "--template" "{desc}"))
          (setq content
                (concat (ahg-histedit-get-message (format "p1(%s)" rev))
                        "\n\n***\n\n"
                        (ahg-histedit-get-message rev))))
      (error (let ((buf (generate-new-buffer "*aHg-histedit*")))
               (setq noedit t)
               (ahg-show-error-msg (format "aHg histedit error: %s"
                                           (error-message-string err)) buf))))
    (unless noedit
      (with-current-buffer buf
        (ahg-push-window-configuration))
      (ahg-log-edit
       (lexical-let ((root root)
                     (rev rev))
         (lambda () (interactive) (ahg-histedit-fold-callback root rev)))
       (lambda () nil)
       buf
       msg content))))


(defun ahg-histedit-roll (rev)
  (interactive (list (read-string "Enter revision to roll: " ".")))
  (condition-case err
      (let* ((root (ahg-root))
             (rev (ahg-histedit-rev-id rev))
             (backupfile (ahg-histedit-setup root "roll" rev))
             (msg (ahg-histedit-get-message (format "p1(%s)" rev))))
        (with-temp-buffer
          (ahg-histedit-do-fold "roll" msg backupfile root rev)))
    (error (let ((buf (generate-new-buffer "*aHg-histedit*")))
             (ahg-show-error-msg (format "aHg histedit error: %s"
                                         (error-message-string err)) buf)))))

;;-----------------------------------------------------------------------------
;; Various helper functions
;;-----------------------------------------------------------------------------

(defun ahg-rev-id (rev &optional which)
  (unless which (setq which "{node|short}"))
  (with-temp-buffer
    (if (= (ahg-call-process "log"
                             (list "-r" rev "--template" (concat which " "))) 0)
        (let ((node (buffer-substring-no-properties (point-min)
                                                    (1- (point-max)))))
          node))))

(defun ahg-first-parent-of-rev (rev)
  (concat "p1(" rev ")"))

(defun ahg-buffer-quit ()
  (interactive)
  (let ((buf (current-buffer)))
    (ahg-pop-window-configuration)
    (kill-buffer buf)))

(defun ahg-generic-command (command args sentinel
                                    &optional buffer
                                              use-shell
                                              no-show-message
                                              report-untrusted
                                              filterfunc
                                              is-interactive
                                              global-opts
                                              no-hgplain)
  "Executes the given hg command, with the given
arguments. SENTINEL is a sentinel function. BUFFER is the
destination buffer. If nil, a new buffer will be used.
"
  (unless buffer (setq buffer (generate-new-buffer "*ahg-command*")))
  (with-current-buffer buffer
    (setq mode-line-process
          (list (concat ":" (propertize "%s" 'face '(:foreground "#DD0000"))))))
  (unless no-show-message (message "aHg: executing hg '%s' command..." command))
  (let ((lang (getenv "LANG"))
        retprocess
        (process-connection-type use-shell)
        (process-adaptive-read-buffering nil))
    (unless no-hgplain (setenv "HGPLAINEXCEPT" "alias,revsetalias"))
    (unless ahg-i18n
      (if (string= ahg-subprocess-coding-system "utf-8")
          (setenv "LANG" "C.UTF-8") (setenv "LANG")))
    ;; (when (and (not use-shell) use-temp-file)
    ;;   (setq args (mapcar 'shell-quote-argument args)))
    (let ((process
           (apply (if use-shell
                      'start-file-process-shell-command 
                    'start-file-process)
                  (concat "*ahg-command-" command "*") buffer
                  (ahg-hg-command)
                  (append
                   (unless report-untrusted
                     (list "--config" "ui.report_untrusted=0"))
                   (when is-interactive
                     (list "--config" "ui.interactive=1"))
                   global-opts
                   (list command) args 
                   ))))
      (when ahg-subprocess-coding-system
        (set-process-coding-system process ahg-subprocess-coding-system))
      (set-process-sentinel
       process
       (lexical-let ((sf sentinel)
                     (cmd command)
                     (no-show-message no-show-message))
         (lambda (p s)
           (unless no-show-message
             (message "aHg: executing hg '%s' command...done"
                      cmd))
           (setq mode-line-process nil)
           (funcall sf p s))))
      (set-process-filter process filterfunc)
      (setq retprocess process)
      )
    (setenv "HGPLAIN")
    (setenv "LANG" lang)
    retprocess
    )
  )

(defun ahg-show-error (process)
  "Displays an error message for the given process."
  (let ((buf (process-buffer process)))
    (when (buffer-live-p buf)
      (pop-to-buffer buf)
      (goto-char (point-min))
      (ahg-command-mode))
    (message "aHg command exited with non-zero status: %s"
             (mapconcat 'identity (process-command process) " "))))

(defun ahg-show-error-msg (msg &optional buf)
  "Displays an error message for the given process."
  (when buf
    (pop-to-buffer buf))
  (goto-char (point-max))
  (ahg-command-mode)
  (let ((inhibit-read-only t))
    (insert msg "\n")))


(defun ahg-command-prompt ()
  "Prompts for data from the minibuffer and sends it to the
current hg command."
  (interactive)
  (goto-char (point-max))
  (let* ((process (get-buffer-process (current-buffer)))
         (msg (buffer-substring-no-properties
               (point-at-bol) (point-at-eol)))
         (is-passwd (string-match "\\<pass\\(word\\|phrase\\)\\>" msg))
         data)
    (setq data
          (concat
           (funcall (if is-passwd 'read-passwd 'read-string) msg) "\n"))
    (process-send-string process data)
    (let ((inhibit-read-only t))
      (insert (if is-passwd "***" data)))
    (set-marker (process-mark process) (point))
    ))

(define-derived-mode ahg-command-mode special-mode "aHg command"
  "Major mode for aHg commands.

Commands:
\\{ahg-command-mode-map}
"
  (buffer-disable-undo) ;; undo info not needed here
  (setq buffer-read-only t)
  (font-lock-mode nil)
  (define-key ahg-command-mode-map "h" 'ahg-command-help)
  (define-key ahg-command-mode-map "q" 'ahg-buffer-quit)
  (define-key ahg-command-mode-map "!" 'ahg-do-command)
  (define-key ahg-command-mode-map (kbd "C-i") 'ahg-command-prompt)
  (easy-menu-add ahg-command-mode-menu ahg-command-mode-map))

(easy-menu-define ahg-command-mode-menu ahg-command-mode-map "aHg Command"
  '("aHg Command"
    ["Execute Hg Command" ahg-do-command [:keys "!" :active t]]
    ["Get data from prompt" ahg-command-prompt [:keys (kbd "C-i") :active t]]
    ["Help on Hg Command" ahg-command-help [:keys "h" :active t]]
    ["Quit" ahg-buffer-quit [:keys "q" :active t]]))


(defun ahg-push-window-configuration ()
  (set (make-local-variable 'ahg-window-configuration)
       (current-window-configuration))
  (put 'ahg-window-configuration 'permanent-local t))

(defun ahg-pop-window-configuration ()
  (when (and ahg-restore-window-configuration-on-quit
             (boundp 'ahg-window-configuration))
    (set-window-configuration ahg-window-configuration)))

(defun ahg-y-or-n-p (prompt)
  (if ahg-yesno-short-prompt
      (y-or-n-p prompt)
    (yes-or-no-p prompt)))

(defun ahg-uncommitted-changes-p (&optional root)
  (with-temp-buffer
    (when (and (or (not root) (ahg-cd root))
               (= (ahg-call-process "id" (list "-n")) 0))
      (= (char-before (1- (point-max))) ?+))))

(defun ahg-file-status (filename)
  (let ((dir (file-name-directory filename))
        (name (file-name-nondirectory filename)))
    (with-temp-buffer
      (if (and (ahg-cd dir)
               (= (ahg-call-process "status" (list "-A" name)) 0)
               (goto-char (point-min))
               (search-forward name nil t))
          (buffer-substring-no-properties (point-at-bol) (1+ (point-at-bol)))
        (error "Impossible to obtain hg status for file: %s" filename)))))

(defun ahg-line-point-pos ()
  (cons (line-number-at-pos) (- (point) (point-at-bol))))

(defun ahg-goto-line (line)
  (goto-char (point-min))
  (forward-line (1- line)))

(defun ahg-goto-line-point (lp)
  (ahg-goto-line (car lp))
  (forward-char (min (cdr lp) (- (point-at-eol) (point-at-bol)))))

(defun ahg-cd (dir)
  (condition-case err
      (cd dir)
    (error nil)))

(defun ahg-hg-command ()
  "Returns the command to use for invoking Mercurial.
Defined as a function to make it easier for the user to customize
for advanced settings (e.g. by defining an advice)."
  ahg-hg-command)

(defun ahg-call-process (cmd &optional args global-opts)
  (let ((callargs (append (list (ahg-hg-command) nil t nil
                                "--config" "ui.report_untrusted=0")
                          global-opts (list cmd) args)))
    ;;(message "callargs: %s" callargs)
    (apply 'process-file callargs)))

(defmacro ahg-dynamic-completion-table (fun)
  (if (fboundp 'completion-table-dynamic)
      `(completion-table-dynamic (quote ,fun))
    `(dynamic-completion-table ,fun)))


(defun ahg-complete-shell-command (command)
  ;; we split the string, and treat the last word as a filename
  (let* ((idx (string-match "\\([^ ]+\\)$" command))
         (matches (file-expand-wildcards (concat (substring command idx) "*")))
         (prev (substring command 0 idx)))
    (mapcar (function (lambda (a) (concat prev a))) matches)))

(defun ahg-string-match-p (&rest args)
  (if (fboundp 'string-match-p)
      (apply 'string-match-p args)
    (save-match-data
      (apply 'string-match args))))

(defun ahg-mq-applied-patches-p (&optional root)
  (with-temp-buffer
    (when (and (or (not root) (ahg-cd root))
               (= (ahg-call-process "qapplied") 0))
      (> (buffer-size) 0))))

(defun ahg-abspath (pth &optional root)
  (unless root
    (setq root (ahg-root)))
  (expand-file-name pth (file-name-as-directory root)))

;; adapted from hexrgb-hsv-to-hex in hexrgb.el
;; Copyright (C) 2004-2014, Drew Adams, all rights reserved.
;; licensed under the GPL
(defun ahg-hsv-to-hex (hue saturation value)
  (let (red green blue int-hue fract pp qq tt ww)
    (if (< saturation 1.0e-8)
        (setq red    value
              green  value
              blue   value)             ; Gray
      (setq hue      (* hue 6.0)        ; Sectors: 0 to 5
            int-hue  (floor hue)
            fract    (- hue int-hue)
            pp       (* value (- 1 saturation))
            qq       (* value (- 1 (* saturation fract)))
            ww       (* value (- 1 (* saturation (- 1 (- hue int-hue))))))
      (case int-hue
        ((0 6) (setq red    value
                     green  ww
                     blue   pp))
        (1 (setq red    qq
                 green  value
                 blue   pp))
        (2 (setq red    pp
                 green  value
                 blue   ww))
        (3 (setq red    pp
                 green  qq
                 blue   value))
        (4 (setq red    ww
                 green  pp
                 blue   value))
        (otherwise (setq red    value
                         green  pp
                         blue   qq))))
    (let ((int-to-hex (lambda (int) (substring (format "%04X" int) (- 4))))
          (scale (lambda (x) (floor (* x 65535.0)))))
      (concat "#"
              (funcall int-to-hex (funcall scale red))
              (funcall int-to-hex (funcall scale green))
              (funcall int-to-hex (funcall scale blue))))))

(defun ahg-get-bookmarks (rev)
  (with-temp-buffer
    (let ((process-environment (cons "LANG=" process-environment)))
      (if (= (ahg-call-process "log"
                               (list "-r" rev "--template" "{bookmarks}")) 0)
          (split-string (buffer-string))
        nil))))

;;-----------------------------------------------------------------------------
;; log-edit related functions
;;-----------------------------------------------------------------------------

(defun ahg-log-edit-hook (&optional extra-message content)
  (erase-buffer)
  (font-lock-mode 0)
  (let ((user
         (with-temp-buffer
           (if (and
                (= (ahg-call-process "showconfig" (list "ui.username")) 0)
                (> (point-max) (point-min)))
               (buffer-substring-no-properties (point-min) (1- (point-max)))
             "")))
        (branch
         (with-temp-buffer
           (if (and
                (= (ahg-call-process "branch") 0)
                (> (point-max) (point-min)))
               (buffer-substring-no-properties (point-min) (1- (point-max)))
             "")))
        (changed (log-edit-files))
        (root-regexp (concat "^" (regexp-quote default-directory))))
    (insert
     (or content "") "\n\n"
     (propertize
      (format
       "HG: Enter commit message.  Lines beginning with 'HG:' are removed.
%sHG: --
HG: user: %s
HG: root: %s
HG: branch: %s
HG: committing %s
HG: Press C-c C-c when you are done editing."
             (if extra-message
                 (concat
                  (mapconcat (lambda (s) (concat "HG: " s))
                             (split-string extra-message "\n") "\n") "\n")
               "")
             user
             default-directory
             branch
             (if changed
                 (mapconcat
                  (lambda (s) (replace-regexp-in-string root-regexp "" s))
                  changed " ")
               "ALL CHANGES (run 'ahg-status' for the details)"))
      'face font-lock-comment-face))
  (goto-char (point-min))))

(defun ahg-log-edit (callback file-list-function buffer &optional msg content)
  "Sets up a log-edit buffer for committing hg changesets."
  (let ((log-edit-hook
         (list (if (or msg content)
                   (lexical-let ((msg msg)
                                 (content content))
                         (lambda () (ahg-log-edit-hook msg content)))
                 'ahg-log-edit-hook))))
    (log-edit
     callback
     t
     (if (version< emacs-version "23.0") file-list-function
       (list (cons 'log-edit-listfun file-list-function)))
     buffer)))

(defun ahg-parse-commit-message ()
  "Returns the contents of the current buffer, discarding lines
starting with 'HG:'."
  (let ((out))
    (goto-char (point-min))
    (while (not (eobp))
      (unless (looking-at "^HG:")
        (setq out
              (cons
               (buffer-substring-no-properties (point-at-bol) (point-at-eol))
               out)))
      (forward-line 1))
    (mapconcat 'identity (nreverse out) "\n")))


(provide 'ahg)

;;; ahg.el ends here
