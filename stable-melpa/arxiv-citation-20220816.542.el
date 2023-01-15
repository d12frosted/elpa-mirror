;;; arxiv-citation.el --- Utility functions for dealing with arXiv papers -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Tony Zorman
;;
;; Author: Tony Zorman <soliditsallgood@mailbox.org>
;; Keywords: convenience
;; Version: 0.1
;; Package-Requires: ((emacs "25.1") (dash "2.19.1") (s "1.12.0"))
;; Homepage: https://gitlab.com/slotThe/arXiv-citation

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Generate citation data for PDF files from the arXiv.
;; Additionally, download preprints to a specified directory and open
;; them.  Includes elfeed[1] support.
;;
;; The high-level overview is:
;;
;;  + `arxiv-citation-gui': Slurp an arXiv link from the primary
;;    selection or the clipboard and insert the corresponding citation
;;    into every file specified in `arxiv-citation-bibtex-files' (NOTE:
;;    this is `nil' by default!).  This uses `gui-get-selection' and is
;;    thus dependent on X11.
;;
;;  + `arxiv-citation-download-and-open': Invoking this function with an
;;    arXiv url downloads it to `arxiv-citation-library' with name
;;    "author1-author2-...authorn_title-sep-by-dashes.pdf" and opens it
;;    with `arxiv-citation-open-pdf-function'.
;;
;;  + `arxiv-citation-elfeed': Elfeed integration.  This works much like
;;    `arxiv-citation-download-and-open', but uses the currently viewed
;;    elfeed item instead of any X selections.
;;
;; Refer to the README on the homepage for more information and visual
;; demonstrations.
;;
;; An example configuration, using use-package[2], may look like
;;
;;     (use-package arxiv-citation
;;       :commands (arxiv-citation-elfeed arxiv-citation-gui)
;;       :custom
;;       (arxiv-citation-library "~/library")
;;       (arxiv-citation-bibtex-files
;;        '("~/.tex/bibliography.bib"
;;          "~/projects/super-secret-project/main.bib")))
;;
;; [1]: https://github.com/skeeto/elfeed
;; [2]: https://github.com/jwiegley/use-package

;;; Code:

(require 'bibtex)
(require 'dash)
(require 's)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Custom Variables

(defgroup arxiv-citation nil
  "Utility functions for dealing with arXiv papers."
  :group 'applications)

(defcustom arxiv-citation-bibtex-files nil
  "List of files to insert bibtex information into."
  :type '(repeat string)
  :group 'arxiv-citation)

(defcustom arxiv-citation-library user-emacs-directory
  "Path to the library.
I.e., the place where all files should be downloaded to."
  :type 'string
  :group 'arxiv-citation)

(defcustom arxiv-citation-open-pdf-function #'browse-url-xdg-open
  "Function with which to open PDF files."
  :type 'function
  :group 'arxiv-citation)

(defcustom arxiv-citation-max-authors nil
  "Maximum number of authors to show in the PDF title.
If this is nil, show all authors instead."
  :type '(choice (natnum :tag "Only show this many authors")
                 (const :tag "Show all authors" nil))
  :group 'arxiv-citation)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Helpers

(defun arxiv-citation-arXiv-id (url)
  "Get the arXiv id of URL."
  (->> (if-let (old-id (s-match "arxiv.org/\\(pdf\\|abs\\)/\\([a-z\-]+/[0-9.]*\\)" url))
           old-id
         (s-match "arxiv.org/\\(pdf\\|abs\\)/\\([0-9.]*\\)" url)) ; New ID: YYYY.<number>
       caddr
       (s-chop-suffix ".")))

(defun arxiv-citation-pdf-link (url)
  "Construct the PDF URL from an ordinary arXiv one."
  (if (s-contains? ".pdf" url)
      url
    (concat (s-replace "/abs/" "/pdf/" url) ".pdf")))

(defun arxiv-citation-parse (method)
  "Parse the current buffer as either html or xml.
METHOD is a keyword; either `:html' or `:xml'."
  (pcase-let ((`(,parse-fun . ,start)
               (pcase method
                 (:html (cons #'libxml-parse-html-region "<html "))
                 (:xml  (cons #'libxml-parse-xml-region  "<?xml ")))))
    (funcall parse-fun
             (progn (goto-char 0)
                    (search-forward start)
                    (match-beginning 0))
             (point-max))))

(defun arxiv-citation-pdf-name (info)
  "Produce a standardised PDF name.
INFO is information as given by `arxiv-citation-get-details'.
The output name is of the following form:

    author₁-author₂-...authorₙ_title-separated-by-dashes.pdf."
  (cl-flet ((take-lastnames (names)
              (seq-take-while (lambda (c) (not (equal c ?,))) names)))
    (let* ((auths (mapconcat (-compose #'downcase #'take-lastnames)
                             (-take (or arxiv-citation-max-authors
                                        most-positive-fixnum)
                                    (plist-get info :authors))
                             "-"))
           (title (->> (plist-get info :title)
                       downcase
                       (s-replace-regexp "[]$(),[\\{}']" "") ; just kill these
                       (s-replace-all '(("_" . "-") (" " . "-")))
                       ;; At least citar treats these chars special:
                       ;; https://github.com/bdarcus/citar/issues/599
                       (s-split "\\(:\\|?\\|;\\)")
                       car
                       s-trim)))
      (format "%s/%s%s.pdf"
              arxiv-citation-library
              (if (s-blank? auths) "" (concat auths "_"))
              title))))

(defun arxiv-citation-generate-autokey ()
  "Generate a key for a bibtex entry in the current buffer.
Defers to `bibtex-generate-autokey' for the actual generation
work—thankfully other people have already solved this much better
than I ever could."
  (bibtex-mode)
  (setq-local bibtex-autokey-year-title-separator ":"
              bibtex-autokey-titleword-separator "-")
  (bibtex-generate-autokey))

(defun arxiv-citation-get-details (link)
  "Get some important details of an arXiv PDF.
LINK is a normal arXiv link of the form

    [https://]arxiv.org/{abs,pdf}/<arXiv-id>[.pdf]

Returns a plist of with keywords `:id', `:authors', `:title',
`:year', and `:categories'."
  (let* ((arXiv-id (arxiv-citation-arXiv-id link))
         (url (format "http://export.arxiv.org/api/query?id_list=%s" arXiv-id)))
    (with-current-buffer (url-retrieve-synchronously url t t)
      (setq case-fold-search nil)       ; Regexps should be case sensitive.
      (let* ((xml (arxiv-citation-parse :xml))
             (entry (alist-get 'entry xml))
             (title (->> (cadr (alist-get 'title entry))
                         (s-replace "\n" "")
                         (s-replace-regexp "\\([A-Z]\\)" "{\\&}")))
             (authors_ (->> entry
                            (--filter (string= (car it) 'author))
                            (-map (-compose #'caddr #'caddr))
                            (--map (s-split " " it))
                            (--map (apply #'concat (-last-item it) ", " (-butlast it)))))
             (year (seq-take (cadr (alist-get 'published entry)) 4))
             (categories (->> entry
                              (--filter (string= (car it) 'category))
                              (--map (alist-get 'term (cadr it))))))
        (unless (string= title "Error")
          (list :id arXiv-id
                :authors authors_
                :title title
                :year year
                :categories categories))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Citations

(defun arxiv-citation-get-citation (url)
  "Return the citation corresponding to URL.
URL can be either an arXiv or a zbmath url.  Try zbmath first; if
the paper is not published yet, generate a citation from arXiv
data if applicable (i.e., an arXiv url)."
  (let* ((zbmath "https://zbmath.org")
         (zbmath-url
          (cond ((arxiv-citation-arXiv-id url)
                 (format "%s/?q=arXiv:%s" zbmath
                         (arxiv-citation-arXiv-id (arxiv-citation-pdf-link url))))
                ((s-prefix? zbmath url)
                 url))))
    (with-current-buffer (url-retrieve-synchronously zbmath-url t t)
      (let* ((html (arxiv-citation-parse :html))
             (id (cadr (s-match "Document Zbl \\([0-9.]*\\)"
                                ;; Hahahahahahahahaha
                                (caddr (cadddr (caddr html)))))))
        (if id
            (arxiv-citation-get-zbmath-citation (concat zbmath "/bibtex/" id ".bib"))
          (arxiv-citation-get-arxiv-citation url))))))

(defun arxiv-citation-get-zbmath-citation (url)
  "Obtain a zbmath citation from URL."
  (with-current-buffer (url-retrieve-synchronously url t t)
    (goto-char 0)
    (search-forward "\n\n")             ; skip header
    ;; Format citation
    (let ((citation (buffer-substring (point) (point-max))))
      (erase-buffer)
      (insert citation)
      ;; Insert readable name
      (goto-char 0)
      (search-forward "{")
      (zap-up-to-char 1 ?,)                      ; @Article{,
      (insert (arxiv-citation-generate-autokey)) ; @Article{name,
      ;; Align
      (setq-local indent-tabs-mode      nil
                  align-default-spacing 5)
      (align-regexp (point-min) (point-max) "\\(\\s-*\\) =")
      (buffer-string))))

(defun arxiv-citation-get-arxiv-citation (url)
  "Extract an arXiv citation from URL."
  (let* ((info     (arxiv-citation-get-details url))
         (authors_ (mapconcat #'identity (plist-get info :authors) " and "))
         (year     (plist-get info :year))
         (id       (plist-get info :id))
         (title    (plist-get info :title))
         (cats     (plist-get info :categories)))
    (cl-flet ((mk-citation (key)
                (concat "@Article{" (or key "") ",\n"
                        " author        = {" authors_ "},\n"
                        " journal       = {arXiv e-prints},\n"
                        " title         = {" title "},\n"
                        " year          = {" year "},\n"
                        " eprint        = {" id "},\n"
                        " eprintclass   = {" (car cats) "},\n"
                        " eprinttype    = {arXiv},\n"
                        " keywords      = {" (mapconcat #'identity cats ", ") "},\n"
                        "}")))
      (mk-citation (with-temp-buffer
                     (insert (mk-citation nil))
                     (arxiv-citation-generate-autokey))))))

;;;###autoload
(defun arxiv-citation (url)
  "Create a citation from the given arXiv or zbmath URL.
Insert the new entry into all files listed in the variable
`arxiv-citation-bibtex-files'."
  (interactive)
  (let ((citation (arxiv-citation-get-citation url)))
    (dolist (file arxiv-citation-bibtex-files)
      (append-to-file (concat "\n" citation "\n") nil file))))

;;;###autoload
(defun arxiv-citation-gui ()
  "Create a citation from the current arXiv or zbmath link.
\"Current\" means \"in the primary selection or the clipboard\"
\(in that order\).  First, try to pull down citation information
from zbmath—in case the paper is already published. If not,
gather the necessary details from the arXiv API if applicable.

Insert the new entry into all files listed in the variable
`arxiv-citation-bibtex-files'."
  (interactive)
  (let ((primary (gui-get-primary-selection))
        (clipboard (gui-get-selection 'CLIPBOARD)))
    (cond ((s-prefix? "http" primary)   (arxiv-citation primary))
          ((s-prefix? "http" clipboard) (arxiv-citation clipboard)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Downloading papers

;;;###autoload
(defun arxiv-citation-download-and-open (url)
  "Download and open an arXiv PDF from URL."
  (let* ((link (arxiv-citation-pdf-link url))
         (file (arxiv-citation-pdf-name (arxiv-citation-get-details link))))
    (when (not (and noninteractive      ; batch-mode
                    (file-exists-p file)))
      ;; Integer as third arg: ask for confirmation before overwriting; lol.
      (url-copy-file link file 42))
    (funcall arxiv-citation-open-pdf-function (expand-file-name file))))

;; Make the byte compiler happy.
(defvar elfeed-show-entry)
(declare-function elfeed-entry-link "elfeed" (cl-x))

;;;###autoload
(defun arxiv-citation-elfeed ()
  "When viewing a paper in elfeed, fetch and open it.
Fetch a paper from the arXiv and open it in zathura."
  (interactive)
  (require 'elfeed)
  (arxiv-citation-download-and-open (elfeed-entry-link elfeed-show-entry)))

(provide 'arxiv-citation)
;;; arxiv-citation.el ends here
