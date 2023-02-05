;;; consult-git-log-grep.el --- Consult integration for git log grep  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Ghosty

;; Author: Ghosty
;; Homepage: https://github.com/Ghosty141/consult-git-log-grep
;; Keywords: git convenience
;; Package-Version: 20230204.1753
;; Package-Commit: 30dfcad5745a6b9882d94fec75d38c345a1eff89
;; Version: 1.0.0
;; Package-Requires: ((emacs "27.1") (consult "0.16"))

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

;; `consult-git-log-grep' makes git log --grep accessible via consult

;;; Code:

(eval-when-compile
  (require 'subr-x))

(require 'consult)

(defcustom consult-git-log-grep-open-function #'consult-git-log-grep-show-commit
  "The function used to open the selected candidate."
  :package-version '(consult-git-log-grep . "1.0.0")
  :group 'consult-git-log-grep
  :type '(function :tag "Function"))

(defface consult-git-log-grep-sha
  '((t :inherit font-lock-keyword-face))
  "Face used to highlight the commit sha in 'consult-git-log-grep'."
  :group 'consult-git-log-grep)

(defface consult-git-log-grep-author
  '((t :inherit completions-annotations))
  "Face used to highlight the author in 'consult-git-log-grep'."
  :group 'consult-git-log-grep)

(defface consult-git-log-grep-datetime
  '((t :inherit completions-annotations))
  "Face used to highlight the datetime in 'consult-git-log-grep'."
  :group 'consult-git-log-grep)

(defvar consult-git-log-grep--history nil)

(defun consult-git-log-grep-show-commit (sha)
  "Displays the result of 'git show SHA' in a new buffer."
  (let* ((short-sha (truncate-string-to-width sha 8))
         (buf (get-buffer-create (format "consult-git-log-grep-commit-%s" short-sha))))
    (shell-command (format "git --no-pager show %s" sha) buf)))

(defun consult-git-log-grep--format (lines)
  "Format git log grep candidates from LINES."
  (let ((candidates))
    (save-match-data
      (dolist (str lines)
        (when (string-match "\\([a-z0-9].*\\)@@@\\(.*\\)@@@\\(.*\\)@@@\\(.*\\)" str)
          (let ((sha (match-string 1 str))
                (msg (match-string 2 str))
                (author (match-string 3 str))
                (datetime (match-string 4 str)))
            (put-text-property 0
                               1
                               'consult-log-grep--metadata
                               `((sha . ,sha)
                                 (author . ,author)
                                 (datetime . ,datetime))
                               msg)
            (push (list msg sha) candidates)))))
    (nreverse candidates)))

(defun consult-git-log-grep--builder (input)
  "Build the command using INPUT and supply the highlight function."
  (pcase-let ((`(,arg . ,opts) (consult--command-split input)))
    (unless (string-blank-p arg)
      (cons (append (list
                     "git"
                     "--no-pager"
                     "log"
                     ;; use git log's formattings padding/truncating for
                     ;; better performance (less lisp string processing)
                     "--pretty=format:%H@@@%<(76,mtrunc)%s@@@%aN@@@%ad"
                     "--date=format:%Y-%m-%d %H:%M:%S"
                     "-i"
                     "--grep")
                    (list arg) opts)
            (cdr (consult--default-regexp-compiler input 'ignore-case t))))))

(defun consult-git-log-grep-result-annotator (cand)
  "Annotate the current candidate CAND using its text-properties."
  (when-let (metadata (get-text-property 0 'consult-log-grep--metadata cand))
    (let ((shortsha (truncate-string-to-width (cdr (assoc 'sha metadata)) 8))
          (datetime (cdr (assoc 'datetime metadata)))
          (author (cdr (assoc 'author metadata))))
      (format " %s  %s  %s"
              (propertize shortsha 'face 'consult-git-log-grep-sha)
              (propertize datetime 'face 'consult-git-log-grep-datetime)
              (propertize author 'face 'consult-git-log-grep-author)))))


;;;###autoload
(defun consult-git-log-grep (&optional initial)
  "Search the git log using 'git log --grep' starting with INITIAL input."
  (interactive)
  (unless (locate-dominating-file default-directory ".git")
    (user-error "Not in a git repository"))
  (when-let ((result (consult--read
                      (consult--async-command #'consult-git-log-grep--builder
                        (consult--async-transform consult-git-log-grep--format)
                        (consult--async-highlight #'consult-git-log-grep--builder))
                      :prompt "Commit Subject: "
                      :require-match t
                      :sort nil
                      :lookup #'consult--lookup-cdr
                      :category 'consult-git-log-grep-result
                      :annotate 'consult-git-log-grep-result-annotator
                      :initial (consult--async-split-initial initial)
                      :add-history (consult--async-split-thingatpt 'symbol)
                      :history '(:input consult-git-log-grep--history))))
    (funcall consult-git-log-grep-open-function (car result))))

(provide 'consult-git-log-grep)
;;; consult-git-log-grep.el ends here
