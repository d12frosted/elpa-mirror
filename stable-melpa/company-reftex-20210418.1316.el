;;; company-reftex.el --- Company backend based on RefTeX. -*- lexical-binding: t -*-

;; Copyright (C) 2018 TheBB
;;
;; Author: Eivind Fonn <evfonn@gmail.com>
;; URL: https://github.com/TheBB/company-reftex
;; Package-Version: 20210418.1316
;; Package-Commit: 42eb98c6504e65989635d95ab81b65b9d5798e76
;; Version: 0.1.0
;; Keywords: bib tex company latex reftex references labels citations
;; Package-Requires: ((emacs "25.1") (s "1.12") (company "0.8"))

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

;; To use, add `company-reftex-labels' and `company-reftex-citations' to `company-backends' in the
;; buffers where you want it activated.  The major mode must be derived from `latex-mode', and
;; `reftex-mode' must be switched on for them to work.
;;
;; - `company-reftex-labels' will trigger inside forms like \ref{}, \eqref{}, \auroref{}, etc.
;; - `company-reftex-citations' will trigger inside cite{}.
;;
;; These backends collect data from RefTeX, which is very powerful.  Citations from external bibtex
;; files should be found automatically.  In multi-file documents, make sure `TeX-master' is set
;; appropriately.

;;; Code:


(eval-when-compile
  (require 'rx))

(require 'cl-lib)
(require 'company)
(require 'reftex)
(require 'reftex-cite)
(require 's)


;; Customization

(defgroup company-reftex nil
  "Completion backend for RefTeX."
  :prefix "company-reftex-"
  :tag "Company RefTeX"
  :group 'company)

(defcustom company-reftex-annotate-citations "%t"
  "If non-nil, a format string with which to annotate citations.
See `reftex-format-citation'."
  :type '(choice string (const nil))
  :group 'company-reftex)

(defcustom company-reftex-annotate-labels t
  "Whether to annotate labels with their contents."
  :type 'boolean
  :group 'company-reftex)

(defcustom company-reftex-max-annotation-length nil
  "Truncate annotations to this length."
  :type '(choice (const :tag "Off" nil) integer)
  :group 'company-reftex)

(defcustom company-reftex-labels-regexp
  (rx "\\"
      ;; List taken from `reftex-ref-style-alist'
      (or "autoref"
          "autopageref"
          "Cpageref"
          "cpageref"
          "Cref"
          "cref"
          "eqref"
          "Fref"
          "fref"
          "pageref"
          "Ref"
          "ref"
          "vpageref"
          "Vref"
          "vref")
      "{"
      (group (* (not (any "}"))))
      (regexp "\\="))
  "Regular expression to use when lookng for the label prefix.
Group number 1 should be the prefix itself."
  :type 'string
  :group 'company-reftex)

(defcustom company-reftex-citations-regexp
  (rx "\\"
      ;; List taken from `reftex-cite-format-builtin'
      (or "autocite"
          "autocite*"
          "bibentry"
          "cite"
          "cite*"
          "citeA"
          "citeaffixed"
          "citeasnoun"
          "citeauthor"
          "citeauthor*"
          "citeauthory"
          "citefield"
          "citeN"
          "citename"
          "cites"
          "citet"
          "citet*"
          "citetitle"
          "citetitle*"
          "citep"
          "citeyear"
          "citeyear*"
          "footcite"
          "footfullcite"
          "fullcite"
          "fullocite"
          "nocite"
          "ocite"
          "ocites"
          "parencite"
          "parencite*"
          "possessivecite"
          "shortciteA"
          "shortciteN"
          "smartcite"
          "textcite"
          "textcite*"
          "ycite"
          "ycites")
      (* (not (any "[{")))
      (* (seq "[" (* (not (any "]"))) "]"))
      "{"
      (* (seq (* (not (any "},"))) ","))
      (group (* (not (any "},")))))
  "Regular expression to use when lookng for the citation prefix.
Group number 1 should be the prefix itself."
  :type 'string
  :group 'company-reftex)



;; Auxiliary functions

(defun company-reftex-prefix (regexp)
  "Return the prefix for matching given REGEXP."
  (and (derived-mode-p 'latex-mode)
       reftex-mode
       (when (looking-back regexp nil)
         (match-string-no-properties 1))))

(defun company-reftex-annotate (key annotation)
  "Annotate KEY with ANNOTATION if the latter is not nil.
Obeys the setting of `company-reftex-max-annotation-length'."
  (cond
   ((not annotation) key)
   ((not company-reftex-max-annotation-length)
    (propertize key 'reftex-annotation annotation))
   (t (propertize key 'reftex-annotation
                  (s-truncate company-reftex-max-annotation-length annotation)))))



;; Citations

(defun company-reftex-citation-candidates (prefix)
  "Find all citation candidates matching PREFIX."
  (reftex-access-scan-info)
  ;; Reftex will ask for a regexp by using `completing-read'
  ;; Override this programatically with a regexp from the prefix
  (cl-letf (((symbol-function 'reftex--query-search-regexps)
             (lambda (_) (if (string= prefix "")
                             (list ".+")
                           (list (regexp-quote prefix))))))
    (let* ((bibtype (reftex-bib-or-thebib))
           (candidates
            (cond
             ((eq 'thebib bibtype)
              (reftex-extract-bib-entries-from-thebibliography
               (reftex-uniquify
                (mapcar 'cdr
                        (reftex-all-assq
                         'thebib (symbol-value reftex-docstruct-symbol))))))
             ((eq 'bib bibtype)
              (reftex-extract-bib-entries (reftex-get-bibfile-list)))
             (reftex-default-bibliography
              (reftex-extract-bib-entries (reftex-default-bibliography))))))
      (cl-loop
       for entry in candidates
       collect
       (let ((key (substring-no-properties (car entry))))
         (company-reftex-annotate
          key
          (when company-reftex-annotate-citations
            (reftex-format-citation entry company-reftex-annotate-citations))))))))

;;;###autoload
(defun company-reftex-citations (command &optional arg &rest _)
  "Company backend for LaTeX citations, powered by reftex.
For more information on COMMAND and ARG see `company-backends'."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-reftex-citations))
    (prefix (company-reftex-prefix company-reftex-citations-regexp))
    (candidates (company-reftex-citation-candidates arg))
    (annotation (when company-reftex-annotate-citations
                  (concat
                   (unless company-tooltip-align-annotations " -> ")
                   (get-text-property 0 'reftex-annotation arg))))))



;; Labels

(defun company-reftex-label-candidates (prefix)
  "Find all label candidates matching PREFIX."
  (reftex-access-scan-info)
  (reftex-parse-all)
  (cl-loop for entry in (symbol-value reftex-docstruct-symbol)
           if (and (stringp (car entry)) (string-prefix-p prefix (car entry)))
           collect
           (company-reftex-annotate (car entry) (cl-caddr entry))))

;;;###autoload
(defun company-reftex-labels (command &optional arg &rest _)
  "Company backend for LaTeX labels, powered by reftex.
For more information on COMMAND and ARG see `company-backends'."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-reftex-labels))
    (prefix (company-reftex-prefix company-reftex-labels-regexp))
    (candidates (company-reftex-label-candidates arg))
    (annotation (when company-reftex-annotate-labels
                  (concat
                   (unless company-tooltip-align-annotations " -> ")
                   (get-text-property 0 'reftex-annotation arg))))))

(provide 'company-reftex)

;;; company-reftex.el ends here
