;;; git-wip-timemachine.el --- Walk through git-wip revisions of a file

;; Copyright (C) 2014-2015 Tim Krones

;; Author: Tim Krones <t.krones@gmx.net>
;; Version: 1.0
;; Package-Version: 20150408.1006
;; Package-Commit: ed4c7931a5f5233bf3e358b1e81647d063526460
;; Package-Requires: ((s "1.9.0"))
;; URL: https://github.com/itsjeyd/git-wip-timemachine
;; Keywords: git

;;; This file is not part of GNU Emacs

;;; License

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

;; Issue M-x git-wip-timemachine to start browsing through WIP
;; versions of a file.
;;
;; Control the time machine using the following keys:
;;
;; . -- Visit current WIP version.
;; > -- Visit current WIP version.
;; < -- Visit oldest WIP version
;;      (equivalent to merge base of current branch and associated WIP branch
;;      *if* merge base introduces changes to current file).
;; p -- Visit previous WIP version.
;; n -- Visit next WIP version.
;; g -- Visit nth WIP version.
;; w -- Copy the abbreviated hash of the current WIP version.
;; W -- Copy the full hash of the current WIP version.
;; q -- Exit the time machine.
;;
;; Finally, there's also `git-wip-timemachine-toggle` which does exactly
;; what its name suggests: If the timemachine is on, calling this command
;; will turn it off (and vice versa).

;;; Installation

;; 1. If you haven't already, set up `git-wip`:
;;
;;    - Clone the "git-wip" package to your $HOME directory:
;;
;;      $ cd
;;      $ git clone https://github.com/itsjeyd/git-wip
;;
;;      If you decide to clone to a different directory and that
;;      directory is *not* part of your `exec-path' in Emacs, you'll
;;      need to add the following code to your init-file (to make sure
;;      Emacs can find the git-wip script):
;;
;;      (add-to-list 'exec-path "/path/to/git-wip")
;;
;;    - Add the following code to your init-file:
;;
;;      (load "/path/to/git-wip/emacs/git-wip.el")
;;
;;      From now on, every time you save a file that is part of a git
;;      repository, Emacs will automatically create a WIP commit by
;;      calling out to git-wip for you.
;;
;; 2. Install `git-wip-timemachine' from MELPA via:
;;
;;    M-x package-install RET git-wip-timemachine RET

;;; Credits:

;; git-wip-timemachine is a modified version of git-timemachine
;; (https://github.com/pidu/git-timemachine) by Peter Stiernström, so
;; all credit for the original idea goes to him.

;;; Code:

(require 's)
(require 'vc-git)

(defcustom git-wip-timemachine-abbreviation-length 12
  "Number of chars from the full SHA1 hash to use for abbreviation."
  :group 'git-wip-timemachine)

(defcustom git-wip-timemachine-show-minibuffer-details t
  "Non-nil means that details of the commit (its hash and date)
will be shown in the minibuffer while navigating commits."
  :group 'git-wip-timemachine)

(defvar git-wip-timemachine-branch nil)
(defvar git-wip-timemachine-directory nil)
(defvar git-wip-timemachine-file nil)
(defvar git-wip-timemachine-merge-base nil)
(defvar git-wip-timemachine-revision nil)
(defvar git-wip-timemachine-revisions nil)

(make-variable-buffer-local 'git-wip-timemachine-branch)
(make-variable-buffer-local 'git-wip-timemachine-directory)
(make-variable-buffer-local 'git-wip-timemachine-file)
(make-variable-buffer-local 'git-wip-timemachine-merge-base)
(make-variable-buffer-local 'git-wip-timemachine-revision)
(make-variable-buffer-local 'git-wip-timemachine-revisions)

;; Command (excluding hash of last commit of wip "parent branch"):
;; git log wip/<branch>...$(git merge-base wip/<branch> <branch>) --pretty=format:%h <file>

;; Command (including hash of last commit of wip "parent branch"):
;; git log wip/<branch> <branch> ^$(git merge-base wip/<branch> <branch>)~1 --pretty=format:%h <file>

(defun git-wip-timemachine--abbreviate (revision)
  "Return REVISION abbreviated to
`git-wip-timemachine-abbreviation-length' chars."
  (substring revision 0 git-wip-timemachine-abbreviation-length))

(defun git-wip-timemachine--branch ()
  "Determine current branch."
  (s-trim-right (shell-command-to-string "git symbolic-ref --short -q HEAD")))

(defun git-wip-timemachine--buffer ()
  "Return name for time machine buffer."
  (format "WIP timemachine:%s" (buffer-name)))

(defun git-wip-timemachine--directory (file-name)
  "Return root directory of current git repository."
  (expand-file-name (vc-git-root file-name)))

(defun git-wip-timemachine--merge-base (current-branch)
  "Determine merge base of current branch and corresponding WIP branch."
  (s-trim-right (shell-command-to-string
                 (format "git merge-base wip/%s %s"
                         current-branch current-branch))))

(defun git-wip-timemachine--revisions ()
  "List git-wip revisions of current buffer's file."
  (let* ((default-directory git-wip-timemachine-directory)
         (file git-wip-timemachine-file)
         (branch git-wip-timemachine-branch)
         (wip-branch (format "wip/%s" branch))
         (exclude-from (format "^%s~1" git-wip-timemachine-merge-base)))
    (with-temp-buffer
      (unless (zerop (process-file vc-git-program nil t nil
                                   "--no-pager" "log"
                                   wip-branch branch exclude-from
                                   "--pretty=format:%H--%ad--%ar" file))
        (error "Failed to obtain revisions for %s." file))
      (goto-char (point-min))
      (let ((revision-number (count-lines (point-min) (point-max)))
            revisions)
        (while (not (eobp))
          (let* ((line (buffer-substring-no-properties
                        (line-beginning-position) (line-end-position)))
                 (revision (cons revision-number (split-string line "--"))))
            (push revision revisions))
          (setq revision-number (1- revision-number))
          (forward-line 1))
        (nreverse revisions)))))

(defun git-wip-timemachine--show-revision (revision)
  "Show a REVISION (commit hash) of the current file."
  (when revision
    (let ((current-position (point))
          (revision-number (car revision))
          (commit-hash (nth 1 revision))
          (date-full (nth 2 revision))
          (date-relative (nth 3 revision)))
      (setq buffer-read-only nil)
      (erase-buffer)
      (let ((default-directory git-wip-timemachine-directory))
        (process-file vc-git-program nil t nil
                      "--no-pager" "show"
                      (format "%s:%s" commit-hash git-wip-timemachine-file)))
      (setq buffer-read-only t)
      (set-buffer-modified-p nil)
      (let* ((total-revisions (length git-wip-timemachine-revisions))
             (n-of-m (format "(%d/%d)" revision-number total-revisions)))
        (setq mode-line-format
              (list "Commit: " (git-wip-timemachine--abbreviate commit-hash)
                    " -- %b -- " n-of-m " -- [%p]")))
      (setq git-wip-timemachine-revision revision)
      (goto-char current-position)
      (when git-wip-timemachine-show-minibuffer-details
        (message "Commit: %s -- Date: %s [%s]"
                 commit-hash date-full date-relative)))))

(defun git-wip-timemachine--validate (file)
  "Validate that there is a FILE and that it belongs to a git repository.
Call with the value of command `buffer-file-name'."
  (unless file
    (error "This buffer is not visiting a file."))
  (unless (vc-git-registered file)
    (error "This file is untracked.")))

(defun git-wip-timemachine-show-current-revision ()
  "Show last (current) revision of file."
  (interactive)
  (git-wip-timemachine--show-revision (car git-wip-timemachine-revisions)))

(defun git-wip-timemachine-show-oldest-revision ()
  "Show oldest WIP revision of file."
  (interactive)
  (git-wip-timemachine--show-revision
   (car (reverse git-wip-timemachine-revisions))))

(defun git-wip-timemachine-show-previous-revision ()
  "Show previous revision of file."
  (interactive)
  (let ((revision (cadr (member git-wip-timemachine-revision
                                git-wip-timemachine-revisions))))
    (if revision
        (git-wip-timemachine--show-revision revision)
      (message "No previous WIP commit. You're looking at the oldest one."))))

(defun git-wip-timemachine-show-next-revision ()
  "Show next revision of file."
  (interactive)
  (let ((revision (cadr (member git-wip-timemachine-revision
                                (reverse git-wip-timemachine-revisions)))))
    (if revision
        (git-wip-timemachine--show-revision revision)
      (message "No next WIP commit. You're looking at the most recent one."))))

(defun git-wip-timemachine-show-nth-revision (n)
  "Show nth WIP revision."
  (interactive "nEnter revision number: ")
  (let ((revision (nth (- n 1) (reverse git-wip-timemachine-revisions)))
        (total-revisions (length git-wip-timemachine-revisions)))
    (if revision
        (git-wip-timemachine--show-revision revision)
      (message "Only %d WIP revisions exist." total-revisions))))

(defun git-wip-timemachine-quit ()
  "Exit the timemachine."
  (interactive)
  (kill-buffer))

(defun git-wip-timemachine-kill-revision ()
  "Kill the current revision's commit hash."
  (interactive)
  (let ((revision (nth 1 git-wip-timemachine-revision)))
    (message revision)
    (kill-new revision)))

(defun git-wip-timemachine-kill-abbreviated-revision ()
  "Kill the current revision's abbreviated commit hash."
  (interactive)
  (let ((revision (git-wip-timemachine--abbreviate
                   (nth 1 git-wip-timemachine-revision))))
    (message revision)
    (kill-new revision)))

(define-minor-mode git-wip-timemachine-mode
  "Git WIP Timemachine, feel the wings of (recent) history."
  :init-value nil
  :lighter " WIP Timemachine"
  :keymap
  '(("." . git-wip-timemachine-show-current-revision)
    (">" . git-wip-timemachine-show-current-revision)
    ("<" . git-wip-timemachine-show-oldest-revision)
    ("p" . git-wip-timemachine-show-previous-revision)
    ("n" . git-wip-timemachine-show-next-revision)
    ("g" . git-wip-timemachine-show-nth-revision)
    ("q" . git-wip-timemachine-quit)
    ("w" . git-wip-timemachine-kill-abbreviated-revision)
    ("W" . git-wip-timemachine-kill-revision))
  :group 'git-wip-timemachine
  :after-hook (when (fboundp 'lispy-mode) (lispy-mode -1)))

;;;###autoload
(defun git-wip-timemachine ()
  "Enable git-wip timemachine for file of current buffer."
  (interactive)
  (git-wip-timemachine--validate (buffer-file-name))
  (let* ((file-name (buffer-file-name))
         (git-directory (git-wip-timemachine--directory file-name))
         (current-branch (git-wip-timemachine--branch))
         (merge-base (git-wip-timemachine--merge-base current-branch))
         (timemachine-buffer (git-wip-timemachine--buffer))
         (current-position (point))
         (current-mode major-mode))
    (with-current-buffer (get-buffer-create timemachine-buffer)
      (setq buffer-file-name file-name)
      (funcall current-mode)
      (git-wip-timemachine-mode)
      (setq git-wip-timemachine-directory git-directory
            git-wip-timemachine-file (file-relative-name file-name
                                                         git-directory)
            git-wip-timemachine-revision nil
            git-wip-timemachine-branch current-branch
            git-wip-timemachine-merge-base merge-base
            git-wip-timemachine-revisions (git-wip-timemachine--revisions))
      (git-wip-timemachine-show-current-revision))
    (switch-to-buffer timemachine-buffer)
    (goto-char current-position)))

;;;###autoload
(defun git-wip-timemachine-toggle ()
  "Toggle `git-wip-timemachine' mode."
  (interactive)
  (if (bound-and-true-p git-wip-timemachine-mode)
      (git-wip-timemachine-quit)
    (git-wip-timemachine)))

(provide 'git-wip-timemachine)

;;; git-wip-timemachine.el ends here
