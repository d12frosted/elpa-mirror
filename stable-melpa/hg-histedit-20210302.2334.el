;;; hg-histedit.el --- Edit HG histedit files  -*- lexical-binding: t -*-

;; Copyright (C) 2019 James Nguyen

;; Author: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/hg-histedit
;; Package-Commit: a05149483b9c5f7848ece0ba6028c900595a6a25
;; Package-Requires: ((emacs "25.1") (with-editor "2.8.3"))
;; Package-Version: 20210302.2334
;; Package-X-Original-Version: 20190609
;; Keywords: mercurial, hg, emacs, tools

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package assists the user in editing the list of commits to be
;; rewritten during an interactive histedit.

;; When the user initiates histedit, this mode is used to let the user
;; edit, mess, pick, base, drop, fold, and roll commits.

;; This package provides the major-mode `hg-histedit-mode' which adds
;; some additional keybindings.
;;
;;   C-c C-c  Tell Hg to make it happen.
;;   C-c C-k  Tell Hg that you changed your mind, i.e. abort.
;;
;; as well as shortkey commands to modify the changeset.

;; Example:
;; ----------------------------------------------------------------------------
;; # Edit history between 567c7a9b5d19 and 105332c82b1a
;; #
;; # Commits are listed from least to most recent
;; #
;; # You can reorder changesets by reordering the lines
;; #
;; # Commands:
;; #
;; #  e, edit = use commit, but stop for amending
;; #  m, mess = edit commit message without changing commit content
;; #  p, pick = use commit
;; #  b, base = checkout changeset and apply further changesets from there
;; #  d, drop = remove commit from history
;; #  f, fold = use commit, but combine it with the one above
;; #  r, roll = like fold, but discard this commit's description and date
;; #
;; ----------------------------------------------------------------------------

;; Many thanks for the original `git-rebase' written and maintained by Phil
;; Jackson and Jonas Bernoulli.

;;; Code:
(require 'with-editor)
(require 'subr-x)

(defgroup hg-histedit nil
  "A major mode for hg histedit."
  :group 'tools)

(defgroup hg-histedit-faces nil
  "Faces uesd by `hg-histedit-mode'."
  :group 'faces
  :group 'hg-histedit)

(defcustom hg-histedit-executable "hg"
  "Executable for hg."
  :type 'string
  :group 'hg-histedit)

(defmacro hg-histedit-create-change-action (&rest actions)
  "Create `hg-histedit' change functions.

ACTIONS is the the list of change actions to create a function."
  `(progn
     ,@(cl-loop
        for action in actions
        collect
        (let ((function-name
               (intern (format "hg-histedit-modify-commit-with-%S" action))))
          `(defun ,function-name ()
             ,(format "Modify commit with %S." action)
             (interactive)
             (hg-histedit-set-action (symbol-name ',action)))))))

(hg-histedit-create-change-action edit mess pick base drop fold roll)

;; Faces

(defface hg-histedit-hash '((t (:inherit font-lock-constant-face)))
  "Face for the sha1 part of the log output."
  :group 'hg-histedit-faces)

(defface hg-histedit-description nil
  "Face for commit descriptions."
  :group 'hg-histedit-faces)

;; Interactive

;;;###autoload
(defun hg-histedit-edit-at-point ()
  "Run hg histedit with the changeset at point."
  (interactive)
  (let ((changeset (hg-histedit-changeset-at-point)))
    (hg-histedit changeset)))

;;;###autoload
(defun hg-histedit-abort ()
  "Abort current hg histedit session."
  (interactive)
  (shell-command
   (format "%s histedit --abort" hg-histedit-executable)))

;;;###autoload
(defun hg-histedit (&optional changeset)
  "Run hg histedit in a separate process.

If CHANGESET, run histedit starting with CHANGESET."
  (interactive)
  (with-editor
    (let ((output-buffer (generate-new-buffer " *hg-histedit*"))
          (commands (if changeset
                        `(,hg-histedit-executable "histedit" "--rev" ,changeset)
                      `(,hg-histedit-executable "histedit"))))
      (make-process
       :name "hg-histedit"
       :buffer output-buffer
       :command commands
       :connection-type 'pipe
       :sentinel
       (lambda (proc _event)
         (when (eq (process-status proc) 'exit)
           (when (derived-mode-p 'vc-mode)
             (when (fboundp 'vc-dir-refresh)
               (vc-dir-refresh)))
           (when (derived-mode-p 'log-view-mode)
             (revert-buffer))
           (with-current-buffer output-buffer
             (if (string-match-p
                  "history edit already in progress, try --continue or --abort"
                  (buffer-string))
                 (message
                  "Histedit is already in progress.\
 Run `hg-histedit-abort' to abort current session.")
               (message "Histedit finished.")))))))))

(defvar hg-histedit-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map (kbd "M-j") 'hg-histedit-move-commit-down)
    (define-key map (kbd "M-k") 'hg-histedit-move-commit-up)
    (define-key map "e" 'hg-histedit-modify-commit-with-edit)
    (define-key map "m" 'hg-histedit-modify-commit-with-mess)
    (define-key map "p" 'hg-histedit-modify-commit-with-pick)
    (define-key map "b" 'hg-histedit-modify-commit-with-base)
    (define-key map "d" 'hg-histedit-modify-commit-with-drop)
    (define-key map "f" 'hg-histedit-modify-commit-with-fold)
    (define-key map "r" 'hg-histedit-modify-commit-with-roll)
    (define-key map "u" 'hg-histedit-undo)
    map))

(define-derived-mode hg-histedit-mode special-mode "HG Histedit"
  "Major mode for editing Mercurial Histedit file.

Histedit files are generated when you run 'hg histedit'."
  :group 'hg-histedit
  :keymap hg-histedit-mode-map
  (setq font-lock-defaults (list (hg-histedit-mode-font-lock-keywords) t t))
  (unless with-editor-mode
    ;; Maybe already enabled when using `shell-command' or an Emacs shell.
    (with-editor-mode 1)))

(define-derived-mode hg-histedit-commit-mode text-mode "HG Histedit Commit"
  "Major mode for editing Mercurial Histedit commit file.

Histedit commit files can be generated when you specify 'mess' in an
'hg histedit'."
  :group 'hg-histedit
  (unless with-editor-mode
    ;; Maybe already enabled when using `shell-command' or an Emacs shell.
    (with-editor-mode 1)))

;; Additional Short Key functions.

(defun hg-histedit-move-commit-up ()
  "Move current commit up."
  (interactive)
  (when (hg-histedit-current-line-empty-p)
    (user-error "There is no commit on this line"))
  (when (bobp)
    (user-error "This is already the first commit"))
  (let ((inhibit-read-only t))
    (transpose-lines 1)
    (forward-line -2)))

(defun hg-histedit-move-commit-down ()
  "Move current commit down."
  (interactive)
  (when (hg-histedit-current-line-empty-p)
    (user-error "There is no commit on this line"))
  (save-mark-and-excursion
    (forward-line 1)
    (when (hg-histedit-current-line-empty-p)
      (user-error "This is already the last commit")))
  (let ((inhibit-read-only t))
    (forward-line 1)
    (transpose-lines 1)
    (forward-line -1)))

(defun hg-histedit-undo ()
  "Undo last change."
  (interactive)
  (let ((inhibit-read-only t))
    (undo)))

;;; Utility

(defun hg-histedit-changeset-at-point ()
  "Return changeset at point."
  (unless (derived-mode-p 'log-view-mode)
    (user-error
     "Only call hg-histedit-changeset-at-point in `log-view-mode' buffers"))
  (save-mark-and-excursion
    (beginning-of-defun)
    (string-trim
     (car (reverse (split-string (thing-at-point 'line t) "changeset:"))))))

(defun hg-histedit-set-action (action)
  "Replace histedit action with new ACTION."
  (let ((inhibit-read-only t)
        (tokens (split-string (thing-at-point 'line t) " ")))
    (hg-histedit-delete-line)
    (insert (concat action " " (mapconcat (lambda (x) x) (cdr tokens) " ")))))

(defun hg-histedit-current-line-empty-p ()
  "Determine if current line is empty."
  (save-excursion
    (beginning-of-line)
    (looking-at "[[:space:]]*$")))

(defun hg-histedit-delete-line ()
  "Delete the rest of the current line."
  (beginning-of-line)
  (delete-region (point) (1+ (line-end-position))))

;; Theme

(defvar hg-histedit-line-regexps
  `((commit . ,(concat
                (regexp-opt '("e" "edit"
                              "m" "mess"
                              "p" "pick"
                              "b" "base"
                              "d" "drop"
                              "f" "fold"
                              "r" "roll")
                            "\\(?1:")
                " \\(?3:[^ \n]+\\) \\(?4:.*\\)"))))

(defun hg-histedit-mode-font-lock-keywords ()
  "Font lock keywords for `hg-histedit-mode'."
  `((,(concat "^" (cdr (assq 'commit hg-histedit-line-regexps)))
     (1 'font-lock-keyword-face)
     (3 'hg-histedit-hash)
     (4 'hg-histedit-description))))

;;; Autoloads

;;;###autoload
;; e.g. hg-histedit-mO1yg5.histedit.hg.txt
(defconst hg-histedit-filename-regexp "hg-histedit-")
;; e.g. hg-editor-IaDdJB.commit.hg.txt
(defconst hg-histedit-commit-regexp "hg-editor-")
;; Used for `borg' integration.
(defconst hg-histedit-autoloads-file-regexp "hg-histedit-autoloads.el")

;;;###autoload
(add-to-list 'auto-mode-alist
             (cons hg-histedit-filename-regexp 'hg-histedit-mode))

(add-to-list 'auto-mode-alist
             (cons hg-histedit-commit-regexp 'hg-histedit-commit-mode))

;; This is for when `borg' generated autoloads file for `hg-histedit'.
;; Without this, the autoloads file will be readonly since it's set to
;; `hg-histedit-mode' (because of the other `auto-mode-alist' entry).
;; This needs to be last in the list of autoloads because we want it to take
;; priority before the other autoloads.
(add-to-list 'auto-mode-alist
             (cons hg-histedit-autoloads-file-regexp 'fundamental-mode))

(defvar vc-dir-mode-map)
(defvar vc-hgcmd-log-view-mode-map)

;;;###autoload
(defun hg-histedit-setup ()
  "Bind `hg-histedit' entrypoints into modes that may use them."
  (with-eval-after-load 'vc-dir
    (define-key vc-dir-mode-map "r" 'hg-histedit))
  (with-eval-after-load 'vc-hgcmd
    (define-key vc-hgcmd-log-view-mode-map "r" 'hg-histedit-edit-at-point)))

(provide 'hg-histedit)
;;; hg-histedit.el ends here
