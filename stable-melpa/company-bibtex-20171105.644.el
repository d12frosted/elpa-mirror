;;; company-bibtex.el --- Company completion for bibtex keys

;; Copyright (C) 2016 GB Gardner

;; Author: GB Gardner <gbgar@users.noreply.github.com>
;; Version: 1.0
;; Package-Version: 20171105.644
;; Package-Commit: 225c6f5c0c070c94c8cdbbd452ea548cd94d76f4
;; Package-Requires: ((company "0.9.0") (cl-lib "0.5") (parsebib "1.0"))
;; Keywords: company-mode, bibtex
;; URL: https://github.com/gbgar/company-bibtex

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;; 1. Redistributions of source code must retain the above copyright
;;    notice, this list of conditions and the following disclaimer.
;; 2. Redistributions in binary form must reproduce the above copyright
;;    notice, this list of conditions and the following disclaimer in the
;;    documentation and/or other materials provided with the distribution.
;; 3. The name of the author may not be used to endorse or promote products
;;    derived from this software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
;; IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES
;; OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
;; IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT, INDIRECT,
;; INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT
;; NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES ; LOSS OF USE,
;; DATA, OR PROFITS ; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
;; THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
;; THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:
;;; `company-bibtex' provides a backend for the
;;; company-mode framework, enabling completion of bibtex keys in
;;; modes used for prose writing.  This backend activates for citation
;;; styles used by `pandoc-mode' (@), `latex-mode' (\cite{}), and
;;; `org-mode' (ebib:).
;;;
;;; Load the package and add it to the company-backends:
;;;
;;;  (require 'company-bibtex)
;;;  (add-to-list 'company-backends 'company-bibtex)
;;;
;;; `company-bibtex' reads from a bibliography file or files
;;; specified in `company-bibtex-bibliography'.  For example:
;;;
;;;   (setq company-bibtex-bibliography
;;;    '("/home/cooluser/thesis/thesis1.bib"
;;;      "/home/cooluser/thesis/thesi2.bib"))
;;;
;;; The regular expression matching key names alphanumeric characters,
;;; dashes (-), and underscores (_).  This is customizable via
;;; `company-bibtex-key-regex'.  For example:
;;;
;;;  (setq company-bibtex-key-regex "[[:alnum:]+_]*")
;;;

;;; Code:

(require 'company)
(require 'cl-lib)
(require 'parsebib)
(require 'regexp-opt)

(defgroup company-bibtex nil
  "Company backend for BibTeX bibliography keys."
  :group 'company)

(defcustom company-bibtex-bibliography nil
  "List of bibtex files used for gathering completions."
  :group 'company-bibtex
  :type '(choice (file :must-match t)
                 (repeat (file :must-match t))))

(defcustom company-bibtex-key-regex "[[:alnum:]_-]*"
  "Regex matching bibtex key names, excluding mode-specific prefixes."
  :group 'company-bibtex
  :type 'regexp)

(defconst company-bibtex-pandoc-citation-regex "-?@"
  "Regex for pandoc citation prefix.")

(defconst company-bibtex-latex-citation-regex
  (regexp-opt '("\cite{" "\citet{" "\citep{" "\citet*{" "\citep*{"))
  "Regex for latex citation prefix.")

(defconst company-bibtex-org-citation-regex "ebib:"
  "Regex for org citation prefix.")

(defun company-bibtex-candidates (prefix)
  "Parse .bib file for candidates and return list of keys.
Prepend the appropriate part of PREFIX to each item."
  (let ((bib-paths (if (listp company-bibtex-bibliography)
                      company-bibtex-bibliography
                    (list company-bibtex-bibliography))))
    (with-temp-buffer
      (mapc #'insert-file-contents bib-paths)
      (mapcar (function (lambda (x) (company-bibtex-build-candidate x)))
              (company-bibtex-parse-bibliography)))))

;; (defun company-bibtex-get-candidate-citation-style (candidate)
;;   "Get prefix for CANDIDATE."
;;   (string-match (format "\\(%s\\|%s\\|%s\\)%s"
;;                           company-bibtex-org-citation-regex
;;                           company-bibtex-latex-citation-regex
;;                           company-bibtex-pandoc-citation-regex
;;                           company-bibtex-key-regex)
;; 		candidate)
;;   (match-string 1 candidate))

(defun company-bibtex-build-candidate (bibentry)
"Build a string---the bibtex key---with author and title properties attached.
This is drawn from BIBENTRY, an element in the list produced
by `company-bibtex-parse-bibliography'."
  (let ((bibkey (cdr (assoc "=key=" bibentry)))
	(author (cdr (assoc "author" bibentry)))
	(title (cdr (assoc "title" bibentry))))
    (propertize bibkey :author author :title title)))

(defun company-bibtex-parse-bibliography ()
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

(defun company-bibtex-get-annotation (candidate)
  "Get annotation from CANDIDATE."
  (let ((prefix-length 0))
    (replace-regexp-in-string "{\\|}" ""
			      (format " | %s"
				      (get-text-property prefix-length :author candidate)))))

(defun company-bibtex-get-metadata (candidate)
  "Get metadata from CANDIDATE."
  (let ((prefix-length 0))
    (replace-regexp-in-string "{\\|}" ""
			      (format "%s"
				      (get-text-property prefix-length :title candidate)))))

;;;###autoload
(defun company-bibtex (command &optional arg &rest ignored)
  "`company-mode' completion backend for bibtex key completion.

This backend activates for citation styles used by `pandoc-mode' (@),
`latex-mode' (\cite{}), and `org-mode' (ebib:), and reads from a
bibliography file or files specified in `company-bibtex-bibliography'.
COMMAND, ARG, and IGNORED are used by `company-mode'."

  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-bibtex))
    (prefix (cond ((derived-mode-p 'latex-mode)
		   (company-grab (format "%s\\(%s,\\)*\\(%s\\)"
					 company-bibtex-latex-citation-regex
					 company-bibtex-key-regex
					 company-bibtex-key-regex)
				 2))
		  ((derived-mode-p 'org-mode)
		   (company-grab (format "%s\\(%s,\\)*\\(%s\\)"
					 company-bibtex-org-citation-regex
					 company-bibtex-key-regex
					 company-bibtex-key-regex)
				 2))
		  ((derived-mode-p 'markdown-mode)
		   (company-grab (format "%s\\(%s\\)"
					 company-bibtex-pandoc-citation-regex
					 company-bibtex-key-regex)
				 1))
		  ))
    (candidates
     (cl-remove-if-not
      (lambda (c) (string-prefix-p arg c))
      (company-bibtex-candidates arg)))
    (annotation (company-bibtex-get-annotation arg))
    (meta (company-bibtex-get-metadata arg))
    (duplicates t)))

(provide 'company-bibtex)

;;; company-bibtex.el ends here
