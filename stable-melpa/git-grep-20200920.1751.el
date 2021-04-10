;;; git-grep.el --- Search tools using git grep

;; Author: Sam Kleinman
;; Maintainer: tychoish <garen@tychoish.com>
;; Version: 1.0
;; Package-Version: 20200920.1751
;; Package-Commit: 12ff6045e9b6aa42f98abd4ddc44d670268a0849
;; Package-Requires: ((projectile "0.10.0"))
;; Homepage: https://github.com/tychoish/git-grep.el
;; Keywords: matching files grep search using git-grep

;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Provides an alternative git-grep based project search using git
;; grep as an alternative to `vc-git-grep' and various ripgrep and
;; silver searcher alternatives.  `git grep' is noticeably faster than
;; find+grep, and comes with git, so it's always available without
;; additional dependencies.  Where `vc-git-grep' includes a number of
;; prompts for various options (including extension's and project
;; path), these commands default to searching all files in the
;; repository or directory tree and work with a single command.

;; I use the following configuration to add key bindings for these
;; grep operations:

;;   (use-package git-grep
;;     :commands (git-grep git-grep-repo)
;;     :bind (("C-c g g" . git-grep)
;;            ("C-c g r" . git-grep-repo)))

;;; Code:

(require 'grep)
(require 'projectile)

(defvar git-grep-command "git --no-pager grep --no-color --line-number <C> <R>"
  "The command to run with GIT-GREP.")

(defun git-grep (regexp)
  "Search for REGEXP using `git grep' in the current directory."
  (interactive "sRegexp: ")
  (unless (boundp 'grep-find-template) (grep-compute-defaults))
  (let ((old-command grep-find-template))
    (grep-apply-setting 'grep-find-template git-grep-command)
    (rgrep regexp "*" "")
    (grep-apply-setting 'grep-find-template old-command)))

(defun git-grep-repo ()
  "Search for the given regexp using `git grep' in the entire repository.
This operation uses projectile to determine the root of the project
and, by default, searchers for the current selection.."
  (interactive)
  (unless (boundp 'grep-find-template) (grep-compute-defaults))
  (let ((old-command grep-find-template)
	(search-text (buffer-substring-no-properties (region-beginning) (region-end))))
    (message search-text)
    (grep-apply-setting 'grep-find-template git-grep-command)
    (rgrep search-text "*" (projectile-project-root))
    (grep-apply-setting 'grep-find-template old-command)))

(defadvice grep-expand-template (around grep-expand-template-with-git-color)
  "Add compatibility for git grep in grep mode."
  (when (and (string-match "^git grep " (ad-get-arg 0))
	     (not (string-match " --color=" (ad-get-arg 0))))
    (ad-set-arg 0 (replace-regexp-in-string
		   "^git grep " "git grep --color=auto " (ad-get-arg 0))))
  ad-do-it)

(provide 'git-grep)
;;; git-grep.el ends here
