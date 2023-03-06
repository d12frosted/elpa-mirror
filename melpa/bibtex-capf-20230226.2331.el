;;; bibtex-capf.el --- Completion at point for bibtex --- *- lexical-binding: t -*-

;; Author: Colin McLear
;; Maintainer: Colin McLear
;; Version: 1.0
;; Package-Version: 20230226.2331
;; Package-Commit: 7635fec3bc565acafbb6e1bff1cc711844f869ce
;; Package-Requires: ((emacs "27.1") (parsebib "3.0") (org "9.5"))
;; Homepage: https://github.com/mclear-tools/bibtex-capf
;; Keywords: bibtex, convenience


;; This file is not part of GNU Emacs

;; This program is free software: you can redistribute it and/or modify
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

;; Completion at point functions for latex, markdown, and org.

;;; Code:
;;;; Requirements
(require 'cl-lib)
(require 'parsebib)

;; Declare org-related vars & functions
(defvar org-element-citation-key-re)
(defvar org-element-citation-prefix-re)
(declare-function org-element-at-point "ext:org-element")
(declare-function org-element-property "ext:org-element")
(declare-function org-element-type "ext:org-element")
(declare-function org-element-context "ext:org-element")

;;;; Variables
(defgroup bibtex-capf nil
  "Company backend for BibTeX bibliography keys."
  :group 'bibtex-capf)

(defcustom bibtex-capf-bibliography nil
  "List of bibtex files used for gathering completions."
  :group 'bibtex-capf
  :type '(choice (file :must-match t)
                 (repeat (file :must-match t))))

(defcustom bibtex-capf-title-author-seperator "|"
  "Separator between title and author entries."
  :group 'bibtex-capf
  :type 'string)

(defvar bibtex-capf-old-capf)

;;;; Functions

(defun bibtex-capf-candidates ()
  "Parse .bib file for candidates and return list of keys."
  (let ((bib-paths (if (listp bibtex-capf-bibliography)
                       bibtex-capf-bibliography
                     (list bibtex-capf-bibliography))))
    (with-temp-buffer
      (mapc #'insert-file-contents bib-paths)
      (mapcar (function (lambda (x) (bibtex-capf-build-candidate x)))
              (bibtex-capf-parse-bibliography)))))

(defun bibtex-capf-build-candidate (bibentry)
  "Build a string---the bibtex key---with author and title properties attached.
This is drawn from BIBENTRY, an element in the list produced
  by `bibtex-capf-parse-bibliography'."
  (let ((bibkey (cdr (assoc "=key=" bibentry)))
	    (author (cdr (assoc "author" bibentry)))
        (editor (cdr (assoc "editor" bibentry)))
	    (title  (cdr (assoc "title" bibentry)))
        (shorttitle  (cdr (assoc "shorttitle" bibentry))))
    (propertize bibkey :author (or author editor) :title (or shorttitle title))))

(defun bibtex-capf-parse-bibliography ()
  "Parse BibTeX entries listed in the current buffer.

  Return a list of entry keys in the order in which the entries
  appeared in the BibTeX files."
  (goto-char (point-min))
  (cl-loop
   for entry-type = (parsebib-find-next-item)
   while entry-type
   unless (member-ignore-case entry-type '("preamble" "string" "comment"))
   collect (mapcar (lambda (it)
                     (cons (downcase (car it)) (cdr it)))
                   (parsebib-read-entry entry-type))))

(defun bibtex-capf-get-title (candidate)
  "Get data from CANDIDATE for annotations."
  (replace-regexp-in-string "{\\|}" ""
			                (format " %s"
				                    (get-text-property 0 :title candidate))))

(defun bibtex-capf-get-author (candidate)
  "Get data from CANDIDATE for annotations."
  (replace-regexp-in-string "{\\|}" ""
			                (format " %s"
				                    (get-text-property 0 :author candidate))))

(defun bibtex-capf-get-annotations (candidate)
  "Get data from CANDIDATE for annotations."
  (concat
   "  "
   (truncate-string-to-width
    (bibtex-capf-get-title candidate)
    55 nil 32 t)
   "  "
   bibtex-capf-title-author-seperator
   (truncate-string-to-width
    (or (bibtex-capf-get-author candidate)
        "")
    20 nil 32)
   " "))

;;;###autoload
(defun bibtex-capf ()
  "Complete citation key at point for org, markdown, or latex."
  (let ((bibtex-capf-latex-regex "\\(?:cite\\(?:\\(?:[pt]\\*\\|[pt]\\)?{\\)\\)\\([[:alnum:]_-]*,\\)*\\([[:alnum:]_-]*\\)")
        (bibtex-capf-markdown-regexp (concat "-?@"                         ; @ preceded by optional -
                                             "\\(?:"
                                             "{\\(?1:.*?\\)}"              ; brace-delimited key
                                             "\\|"
                                             "\\(?1:[[:alnum:]_][[:alnum:]]*\\(?:[:.#$%&+?<>~/-][[:alnum:]]+\\)*\\)"
                                             "\\)")))
    (when
        (cond
         ;; org-mode
         ((and (derived-mode-p 'org-mode)
               (let ((element (org-element-at-point)))
                 (or (eq 'citation (org-element-type (org-element-context element)))
                     (and (or (eq ?@ (char-before))
                              (looking-back org-element-citation-key-re
                                            (line-beginning-position)))
                          (let ((origin (point)))
                            (save-excursion
                              (and (re-search-backward org-element-citation-prefix-re
                                                       (org-element-property
                                                        :begin element)
                                                       t)
                                   (not (search-forward "]" origin t))))))))))
         ;; markdown-mode
         ((and (derived-mode-p 'markdown-mode)
               (or (eq ?@ (char-before))
                   (looking-back bibtex-capf-markdown-regexp
                                 (line-beginning-position)))))

         ;; latex-mode
         ((derived-mode-p 'latex-mode)
          (looking-back bibtex-capf-latex-regex 2)))

      (let ((candidates
             (bibtex-capf-candidates))
            (bounds (bounds-of-thing-at-point 'word)))

        (when bounds
          (list (car bounds)
                (cdr bounds)
                candidates
                :annotation-function
                (lambda (str)
                  (bibtex-capf-get-annotations str))
                :exit-function
                (lambda (str _status)
                  ;; take completion str and replace with key
                  (insert))))))))

;;;; Define Minor Mode
;;;###autoload
(define-minor-mode bibtex-capf-mode
  "Create a global minor mode for `bibtex-capf'.
This adds hooks and the `bibtex-capf' function to the relevant modes."
  :lighter ""
  :global t
  (cond (bibtex-capf-mode
         ;; add to completion framework
         (setq bibtex-capf-old-capf completion-at-point-functions)
         (add-hook 'completion-at-point-functions #'bibtex-capf -90)
         (add-to-list 'completion-at-point-functions #'bibtex-capf))
        (t
         (remove-hook 'completion-at-point-functions #'bibtex-capf)
         (setq completion-at-point-functions bibtex-capf-old-capf))))

(provide 'bibtex-capf)
;;; bibtex-capf.el ends here
