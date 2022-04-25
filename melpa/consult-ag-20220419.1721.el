;;; consult-ag.el --- The silver searcher integration using Consult -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Kanon Kakuno

;; Author: Kanon Kakuno <yadex205@outlook.jp>
;; Homepage: https://github.com/yadex205/consult-ag
;; Package-Requires: ((emacs "27.1") (consult "0.16"))
;; Package-Version: 20220419.1721
;; Package-Commit: 2460ae6829e86c9f1186a852304d919526838cb8
;; SPDX-License-Identifier: MIT
;; Version: 0.1.2

;; This file is not part of GNU Emacs.

;;; Commentary:

;; consult-ag provides interfaces for using `ag` (The Silver Searcher).
;; To use this, turn on `consult-ag` in your init-file or interactively.

;;; Code:

(eval-when-compile ; IDK but required for byte-compile
  (require 'cl-lib)
  (require 'subr-x))
(require 'consult)

(defun consult-ag--builder (input)
  "Build command line given INPUT."
  (pcase-let* ((cmd (split-string-and-unquote "ag --vimgrep"))
               (`(,arg . ,opts) (consult--command-split input)))
    `(,@cmd ,@opts ,arg ".")))

(defun consult-ag--format (line)
  "Parse LINE into candidate text."
  (when (string-match "^\\([^:]+\\):\\([0-9]+\\):\\([0-9]+\\):\\(.*\\)$" line)
    (let* ((filename (match-string 1 line))
           (row (match-string 2 line))
           (column (match-string 3 line))
           (body (match-string 4 line))
           (candidate (format "%s:%s:%s:%s"
                              (propertize filename 'face 'consult-file)
                              (propertize row 'face 'consult-line-number)
                              (propertize column 'face 'consult-line-number) body)))
      (propertize candidate 'filename filename 'row row 'column column))))

(defun consult-ag--grep-position (cand &optional find-file)
  "Return the candidate position marker for CAND.
FIND-FILE is the file open function, defaulting to `find-file`."
  (when cand
    (let ((file (get-text-property 0 'filename cand))
          (row (string-to-number (get-text-property 0 'row cand)))
          (column (- (string-to-number (get-text-property 0 'column cand)) 1)))
      (consult--position-marker (funcall (or find-file #'find-file) file) row column))))

(defun consult-ag--grep-state ()
  "Not documented."
  (let ((open (consult--temporary-files))
        (jump (consult--jump-state)))
    (lambda (action cand)
      (unless cand
        (funcall open nil))
      (funcall jump action (consult-ag--grep-position cand open)))))

;;;###autoload
(defun consult-ag (&optional target initial)
  "Consult ag for query in TARGET file(s) with INITIAL input."
  (interactive)
  (let* ((prompt-dir (consult--directory-prompt "Consult ag: " target))
         (default-directory (cdr prompt-dir)))
    (consult--read (consult--async-command #'consult-ag--builder
                     (consult--async-map #'consult-ag--format))
                   :prompt (car prompt-dir)
                   :lookup #'consult--lookup-member
                   :state (consult-ag--grep-state)
                   :initial (consult--async-split-initial initial)
                   :require-match t
                   :category 'file
                   :sort nil)))

(provide 'consult-ag)

;;; consult-ag.el ends here
