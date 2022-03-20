;;; git-msg-prefix.el --- Insert commit message prefix (issue number)  -*- lexical-binding: t; -*-

;; Copyright (C) 2017, 2018 Raimon Grau

;; Author: Raimon Grau <raimonster@gmail.com>
;; Keywords: vc, tools
;; Package-Version: 20191031.1304
;; Package-Commit: 43f6b31c1090371260a2f15b2117a7666920bee7

;; URL: http://github.com/kidd/git-msg-prefix.el
;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (s "1.10.0") (dash "2.9.0"))

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

;;; Commentary:

;; Package to help adding information on commits by checking older
;; commits and extracting a particular substring from each of them.

;; Useful to follow organisation policies on how to write commits.

;; The default command presents a searchable list of the previous
;; commits (more recent first), and lets you select the one you want.
;; This list of candidates is configurable via
;; `git-msg-prefix-log-command`.  Once selected, the relevant part
;; of the commit line will be extracted from the choosen candidate
;; via the regex in `git-msg-prefix-regex', and the matched text
;; will be inserted in the current buffer.

;; example configurations with use-package:

;; (use-package git-msg-prefix
;;   :ensure t
;;   :config
;;   (setq git-msg-prefix-log-flags " --since='1 week ago' "
;;         git-msg-prefix-input-method 'helm-comp-read)
;;   (add-hook 'git-commit-mode-hook 'git-msg-prefix))

;; bare configuration:
;;
;; (add-hook 'git-commit-mode-hook 'git-msg-prefix)
;; (setq git-msg-prefix-input-method 'helm-comp-read)

;; Otherwise, add a keybinding to that function or run it manually
;; from the minibuffer.
;;   (local-set-key
;;    (kbd "C-c i")
;;    'git-msg-prefix)

;; Configure

;; There are 3 variables to configure:

;; - ~git-msg-prefix-log-command~: defaults to "git log
;;   --pretty=format:\"%s\""
;; - ~git-msg-prefix-log-flags~: defaults to ""

;; - ~git-msg-prefix-regex~: defaults to  "^\\([^ ]*\\) "

;;  - ~git-msg-prefix-input-method~: defaults to
;;    ido-completing-read. Change it to your favourite input
;;    method. ('completing-read 'ido-completing-read
;;    'helm-comp-read 'ivy-read)

;;; Code:

(require 's)
(require 'dash)

(defgroup git-msg-prefix nil
  "Pick a past commit message to build a new commit message."
  :prefix "git-msg-prefix-"
  :group 'applications)

(defcustom git-msg-prefix-log-command "git log --pretty=format:\"%s\""
  "Main vcs command to run to populate the candidates list."
  :group 'git-msg-prefix
  :type 'string)

(defcustom git-msg-prefix-log-flags ""
  "Extra flags for `git-msg-prefix-log-command'.
To narrow/extend the candidates listing.  For example:
\"--author=rgrau --since=1.week.ago --no-merges\""
  :group 'git-msg-prefix
  :type 'string)

(defcustom git-msg-prefix-regex "^\\([^ ]*\\)"
  "Regex to match against the populated list. The first match
will be inserted on the current buffer"
  :group 'git-msg-prefix
  :type 'string)

(defcustom git-msg-prefix-input-method 'completing-read
  "Input method for ‘git-msg-prefix’."
  :group 'git-msg-prefix
  :type '(choice ('completing-read
                  'ido-completing-read
                  'helm-comp-read
                  'ivy-read)))

(defvar git-msg-prefix-prompt "pick commit:")

(defun git-msg-prefix-input-fun ()
  "Show picker with candidates."
  (let ((ivy-sort-functions-alist nil))
    (funcall git-msg-prefix-input-method
             git-msg-prefix-prompt
             (git-msg-prefix-1))))

(defun git-msg-prefix-1 ()
  "Internal function to fetch all candidates."
  (let ((vc-command (format "%s %s"
                            git-msg-prefix-log-command
                            git-msg-prefix-log-flags)))
    (cons
     (s-prepend (car (vc-git-branches))
                " - *current branch*")
     (s-lines (shell-command-to-string vc-command)))))

;;;###autoload
(defun git-msg-prefix ()
  "Insert the relevant part of the chosen commit.
Relevant meaning the result of `git-msg-prefix-regex'
substitution."
  (interactive)
  (insert
   (second
    (s-match git-msg-prefix-regex
             (git-msg-prefix-input-fun)))))

(provide 'git-msg-prefix)
;;; git-msg-prefix.el ends here
