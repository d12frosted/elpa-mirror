;;; toc-mode.el --- Manage outlines/table of contents of pdf and djvu documents  -*- lexical-binding: t; -*-
;; Copyright (C) 2020  Daniel Laurens Nicolai

;; Author: Daniel Laurens Nicolai <dalanicolai@gmail.com>
;; Version: 0
;; Package-Version: 20210714.725
;; Package-Commit: 977bec00d8d448ad2a5e2e4c17b9c9ba3e194ec2
;; Keywords: tools, outlines, convenience
;; Package-Requires: ((emacs "26.1"))
;; URL: https://github.com/dalanicolai/toc-mode


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

;; toc-mode.el is a package to create and add a Table of Contents to pdf and
;; djvu documents. It implements features to extract a Table of Contents from
;; the textlayer of a document or via OCR if that last option is necessary or
;; prefered. For 'software generated' PDFs it provides the option to use
;; pdf.tocgen (see URL `https://krasjet.com/voice/pdf.tocgen/'). Subsequently
;; this package implements various features to assist in tidy up the extracted
;; Table of Contents, adjust the pagenumbers and finally parsing the Table of
;; Contents into syntax that is understood by the `pdfoutline' and `djvused'
;; commands that are used to add the table of contents to pdf- and djvu-files
;; respectively.

;; Requirements: To use the pdf.tocgen functionality that software has to be
;; installed (see URL `https://krasjet.com/voice/pdf.tocgen/'). For the
;; remaining functions the package requires the `pdftotext' (part of
;; poppler-utils), `pdfoutline' (part of fntsample) and `djvused' (part of
;; http://djvu.sourceforge.net/) command line utilities to be available.
;; Extraction with OCR requires the tesseract command line utility to be
;; available.

;; Usage:


;; In each step below, check out available shortcuts using C-h m. Additionally
;; you can find available functions by typing the M-x mode-name (e.g. M-x
;; toc-cleanup), or with two dashes in the mode name (e.g. M-x toc--cleanup). Of
;; course if you use packages like Ivy or Helm you just use the fuzzy search
;; functionality.

;; Extraction and adding contents to a document is done in 4 steps:
;; 1 extraction
;; 2 cleanup
;; 3 adjust/correct pagenumbers
;; 4 add TOC to document

;; 1. Extraction For PDFs without TOC pages, with a very complicated TOC (i.e.
;; that require much cleanup work) or with headlines well fitted for automatic
;; extraction (you will have to decide for yourself by trying it) consider to
;; use the pdf.tocgen (URL `https://krasjet.com/voice/pdf.tocgen/')
;; functionality described below. Otherwise, start with opening some pdf or djvu
;; file in Emacs (pdf-tools and djvu package recommended). Find the pagenumbers
;; for the TOC. Then type M-x `toc-extract-pages', or M-x
;; `toc-extract-pages-ocr' if doc has no text layer or text layer is bad, and
;; answer the subsequent prompts by entering the pagenumbers for the first and
;; the last page each followed by RET. For PDF extraction with OCR, currently it
;; is required to view all contents pages once before extraction (toc-mode uses
;; the cached file data). Also the languages used for tesseract OCR can be
;; customized via the `toc-ocr-languages' variable. A buffer with the, somewhat
;; cleaned up, extracted text will open in TOC-cleanup mode. Prefix command with
;; the universal argument (C-u) to omit clean and get the raw text. If the
;; extracted text is of too low quality you either can hack/extend the
;; `toc-extract-pages-ocr' definition, or alternatively you can try to extract
;; the text with the python document-contents-extractor script (see URL
;; `https://pypi.org/project/document-contents-extractor/'), which is more
;; configurable (you are also welcome to hack and improve that script).

;; The documentation at URL
;; `https://tesseract-ocr.github.io/tessdoc/Command-Line-Usage.html' might be
;; useful.

;; For TOC's that are formatted as two columns per page, prepend the
;; `toc-extract-pages-ocr' command with two universal arguments. Then after you
;; are asked for the start and finish pagenumbers, a third question asks you to
;; set the tesseract psm code. For the double column layout it is best (as far
;; as I know) to use psm code '1'.

;; Software-generated PDF's with pdf.tocgen
;; For 'software-generated' (i.e. PDF's not created from scans) PDF-files it is
;; sometimes easier to use `toc-extract-with-pdf-tocgen'. To use this function
;; you first have to provide the font properties for the different headline
;; levels. For that select the word in a headline of a certain level and then
;; type M-x `toc-gen-set-level'. This function will ask which level you are
;; setting, the highest level should be level 1. After you have set the various
;; levels (1,2, etc.) then it is time to run M-x `toc-extract-with-pdf-tocgen'.
;; If a TOC is extracted succesfully, then in the pdftocgen-mode buffer simply
;; press C-c C-c to add the contents to the PDF. The contents will be added to a
;; copy of the original PDF with the filename output.pdf and this copy will be
;; opened in a new buffer. If the pdf-tocgen option does not work well then
;; continue with the steps below.

;; If you merely want to extract text without further processing then you can
;; use the command `toc-extract-only'.

;; 2. TOC-Cleanup In this mode you can further cleanup the contents to create a
;; list where each line has the structure:

;; TITLE (SOME) PAGENUMBER

;; (If the initial TOC looks bad/unusable then try to use then universal
;; argument C-u before extraction in the previous step and/or try the ocr option
;; with or without the universal argument)
;; There can be any number of spaces between TITLE and PAGE. The correct
;; pagenumbers can be edited in the next step. A document outline supports
;; different levels and levels are automatically assigned in order of increasing
;; number of preceding spaces, i.e. the lines with the least amount of preceding
;; spaces are assigned level 0 etc., and lines with equal number of spaces get
;; assigned the same levels.

;; Contents   1
;; Chapter 1      2
;; Section 1 3
;; Section 1.1     4
;; Chapter 2      5

;; There are some handy functions to assist in the cleanup. C-c C-j jumps
;; automatically to the next line not ending with a number and joins it with the
;; next line. If the indentation structure of the different lines does not
;; correspond with the levels, then the levels can be set automatically from the
;; number of separatorss in the indices with M-x toc-cleanup-set-level-by-index.
;; The default separators is a . but a different separators can be entered by
;; preceding the function invocation with the universal argument (C-u). Some
;; documents contain a structure like

;; 1 Chapter 1    1
;; Section 1      2

;; Here the indentation can be set with M-x replace-regexp ^[^0-9] -> \& (where
;; there is a space character before the \&).

;; Type C-c C-c when finished

;; 3. TOC-tabular (adjust pagenumbers) This mode provides the functionality for
;; easy adjustment of pagenmumbers. The buffer can be navigated with the arrow
;; up/down keys. The left and right arrow keys will shift down/up all the page
;; numbers from the current line and below (combine with SHIFT for setting
;; individual pagenumbers).

;; The TAB key jumps to the pagenumber of the current line, while C-right/C-left
;; will shift all remaining page numbers up/down while jumping/scrolling to the
;; line its page in the document window. to the S-up/S-donw in the tablist
;; window will just scroll page up/down in the document window and, only for
;; pdf, C-up/C-down will scroll smoothly in that window.

;; Type C-c C-c when done.

;; 4. TOC-mode (add outline to document) The text of this buffer should have the
;; right structure for adding the contents to (for pdf’s a copy of) the original
;; document. Final adjusments can be done but should not be necessary. Type C-c
;; C-c for adding the contents to the document.

;; By default, the TOC is simply added to the original file. ONLY FOR PDF’s, if
;; the (customizable) variable toc-replace-original-file is nil, then the TOC is
;; added to a copy of the original pdf file with the path as defined by the
;; variable toc-destination-file-name. Either a relative path to the original
;; file directory or an absolute path can be given.

;; Sometimes the `pdfoutline/djvused' application is not able to add the TOC to
;; the document. In that case you can either debug the problem by copying the
;; used terminal command from the `*messages*' buffer and run it manually in the
;; document's folder, or you can delete the outline source buffer and run
;; `toc--tablist-to-handyoutliner' from the tablist buffer to get an outline
;; source file that can be used with HandyOutliner (see URL
;; `http://handyoutlinerfo.sourceforge.net/') Unfortunately the handyoutliner
;; command does not take arguments, but if you customize the
;; `toc-handyoutliner-path' and `toc-file-browser-command' variables, then Emacs
;; will try to open HandyOutliner and the file browser so that you can drag the
;; files directly into HandyOutliner).

;; Finally, if you just want to extract some text

;; Keybindings
;; all-modes (i.e. all steps)
;;  Key Binding       Description
;;  C-c C-c           dispatch (next step)

;; toc-cleanup-mode
;; C-c C-j            toc--join-next-unnumbered-lines
;; C-c C-s            toc--roman-to-arabic

;; toc-mode (tablist)
;; TAB~               preview/jump-to-page
;; right/left         toc-in/decrease-remaining
;; C-right/C-left     toc-in/decrease-remaining and view page
;; S-right/S-left     in/decrease pagenumber current entry
;; C-down/C-up        scroll document other window (if document buffer shown)
;; S-down/S-up        full page scroll document other window ( idem )
;; C-j                toc--jump-to-next-entry-by-level

;;; Code:
(require 'pdf-tools nil t)
(require 'djvu nil t)
(require 'evil nil t)
(require 'seq)
(require 'rst)

;; List of declarations to eliminate byte-compile errors
(defvar djvu-doc-image)
(defvar doc-buffer)
(defvar pdf-filename)

(declare-function pdf-cache-get-image "pdf-cache")
(declare-function pdf-view-goto-page "pdf-view")
(declare-function pdf-view-next-page "pdf-view")
(declare-function pdf-view-previous-page "pdf-view")
(declare-function pdf-view-scroll-up-or-next-page "pdf-view")
(declare-function pdf-view-scroll-down-or-previous-page "pdf-view")
(declare-function djvu-goto-page "djvu")
(declare-function djvu-next-page "djvu")
(declare-function djvu-prev-page "djvu")
(declare-function djvu-scroll-up-or-next-page "djvu")
(declare-function djvu-scroll-down-or-previous-page "djvu")
(declare-function evil-scroll-page-down "evil-commands")
(declare-function evil-scroll-page-up "evil-commands")

;;;; Customize definitions
(defgroup toc nil
  "Setting for the toc-mode package"
  :group 'data)

(defcustom toc-replace-original-file t
  "For PDF include TOC and replace old PDF file.
For DJVU the old DJVU file is replaced by default"
  :type 'boolean
  :group 'toc)

(defcustom toc-destination-file-name "pdfwithtoc.pdf"
  "Filename for new PDF if `toc-replace-original-file' is nil."
  :type 'file
  :group 'toc)

(defcustom toc-ocr-languages nil
  "Languages used for extraction with ocr.
Should be one or multiple language codes as recognized
by tesseract -l flag, e.g. eng or eng+nld. Use
\\[execute-extended-command] `toc-list-languages' to list the
available languages."
  :type 'string
  :group 'toc)

(defcustom toc-handyoutliner-path nil
  "Path to handyoutliner executable.
String (i.e. surround with double quotes). See
URL`http://handyoutlinerfo.sourceforge.net/'."
  :type 'file
  :group 'toc)

(defcustom toc-file-browser-command nil
  "Command to open file browser.
String (i.e. surround with double quotes)."
  :type 'file
  :group 'toc)

;;;; pdf.tocgen
;;;###autoload
(defun toc-gen-set-level (level)
  "Define the text properties of the heading level.
In a pdf-view buffer select a single word in the headline of a
certain level. Then run `toc-gen-set-level' to write the text
properties to the recipe.toml file that is created in the
document's directory. You will be prompted to enter the LEVEL
number. The highest level should have number 1, the next leve
number 2 etc."
  (interactive "nWhich level you are setting (number): ")
  (let* ((page (eval (pdf-view-current-page)))
         (filename (url-filename (url-generic-parse-url buffer-file-name)))
         (pdfxmeta-result (shell-command
                           (format "pdfxmeta --auto %s --page %s '%s' \"%s\" >> recipe.toml"
                                   level
                                   page
                                   filename
                                   (car (pdf-view-active-region-text))))))
    (when (eq pdfxmeta-result 1)
      (let ((page-text (shell-command-to-string
                        (format "mutool draw -F text '%s' %s"
                                filename
                                page
                                ))))
        (pop-to-buffer "page-text")
        (insert
         "COULD NOT SET HEADING LEVEL. MUPDF EXTRACTED FOLLOWING PAGE TEXT FROM PAGE:\n")
        (add-text-properties 1 (point) '(face font-lock-warning-face))
        (let ((beg (point)))
          (insert "(try to select partial word)\n\n")
          (add-text-properties beg (point) '(face font-lock-warning-face)))
        (insert page-text)
        (goto-char (point-min))))))


(defun toc-extract-with-pdf-tocgen ()
  "Extract Table of Contents with `pdf-tocgen'.
Inserts the extracted TOC to a newly created buffer. This
function requires `pdf.tocgen' to be installed (see URL
`https://krasjet.com/voice/pdf.tocgen/'). The function can only
be used after the headline text properties have been defined with
the function `toc-gen-set-level'"
  (interactive)
  (let ((filename buffer-file-name)
        (toc (shell-command-to-string
              (format "pdftocgen %s < recipe.toml" (shell-quote-argument buffer-file-name)))))
    (switch-to-buffer "toc")
    (toc-pdftocgen-mode) ;; required before setting local variable
    (when (fboundp 'flyspell-mode)
      flyspell-mode)
    (setq-local pdf-filename filename)
    (insert toc)))

(defun toc--pdftocgen-add-to-pdf ()
  "Add content extracted with `pdf.tocgen' to copy of original PDF.
The newly created PDF that includes the TOC is written to a file
named output.pdf and opened in a new buffer. Don't forget to
rename this new file."
  (interactive)
  (write-file default-directory)
  (let* ((message (shell-command-to-string (format "pdftocio '%s' < toc" pdf-filename))))
    (kill-buffer-if-not-modified (find-file pdf-filename))
    (when (file-exists-p (concat (file-name-base pdf-filename) "_out.pdf"))
      (delete-file pdf-filename)
      (rename-file (concat (file-name-base pdf-filename) "_out.pdf") pdf-filename))
    (find-file pdf-filename)
    (unless (string= message "")
      (message (concat "The pdftocio command returned the following message: \n\n" message)))))


(defvar toc-pdftocgen-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-c" #'toc--pdftocgen-add-to-pdf)
    map))

(define-derived-mode toc-pdftocgen-mode
  fundamental-mode "TOC-cleanup"
  "Major mode for cleaning up Table Of Contents
\\{toc-pdftocgen-mode-map}")

;;;; toc-extract and cleanup

;;; toc-cleanup
(defun toc--cleanup-dots ()
  "Remove dots between heading its title and page number."
  (interactive)
  (goto-char (point-min))
  (while (not (eobp))
    (re-search-forward "\\([\\. ]*\\)\\([0-9ivx]*\\) *$")
    (replace-match " \\2")
    (forward-line 1)))

(defun toc--cleanup-dots-ocr ()
  (interactive)
  "Remove dots between heading its title and page number.
Like `toc--cleanup-dots' but more suited for use after OCR"
  (goto-char (point-min))
  (while (re-search-forward "\\([0-9\\. \\-]*\\)\\( [0-9]* *\\)$" nil t)
    (replace-match " \\2")))

(defun toc--cleanup-lines-contents-string ()
  "Delete all lines containing the string \"contents\"."
  (interactive)
  (flush-lines "contents"))

(defun toc--cleanup-lines-roman-string ()
  "Delete all lines that contain only linefeeds and/or blanks and/or roman numerals."
  (interactive)
  (goto-char (point-min))
  (while (not (eobp))
    (re-search-forward "^[\f ]*[ivx0-9\\.]* *$")
    (replace-match "")
    (forward-line 1)))

(defun toc-cleanup-blank-lines ()
  "Delete all empty lines."
  (interactive)
  (goto-char (point-min))
  (flush-lines "^ *$"))

(defun toc--roman-to-arabic (arg)
  "Transform roman pagenumbers to hindu-arabic numberals.
This function only works for lines that end with roman numerals.
Prefix with numeric ARG prefix to apply to the next ARG lines."
  (interactive "p")
  (dotimes (_x arg)
    (move-end-of-line 1)
    (let ((latin (number-to-string
                  (rst-roman-to-arabic
                   (thing-at-point 'word t)))))
      (backward-word)
      (kill-word 1)
      (insert latin)
      (forward-line))))

(defun toc--join-next-unnumbered-lines ()
  "Search from point for first occurence of line not ending with Western numerals."
  (interactive)
  (re-search-forward "[^0-9]\\s-*$" nil t)
  (join-line 1))

(defun toc--jump-next-overindexed-index ()
  "Jump to next line with unwanted dot behind its index."
  (interactive)
  (re-search-forward "^[0-9\\.]*\\. " nil t))

(defun toc--cleanup (contents-page &optional arg)
  "Cleanup extracted Table Of Contents by running a series of cleanup functions.
It executes the following steps:
1. insert a Contents entry with pagenumber CONTENTS-PAGE
2. delete subsequent lines containing the string 'contents'
3. tries to delete redundant dots
4. deletes lines that containi only roman numerals and linefeed characters
5. deletes
When ARG is non-nil it skips the last three steps"
  (interactive)
  (goto-char (point-min))
  (when (search-forward "contents" nil t)
    (replace-match (format "Contents %s" contents-page)))
  (toc--cleanup-lines-contents-string)
  (if arg
      (toc--cleanup-dots-ocr)
    (toc--cleanup-dots))
  (toc--cleanup-lines-roman-string)
  (toc-cleanup-blank-lines))

(defun toc--get-section-inidices (separators)
  "Determine index part of current line. Counting the number of SEPARATORS."
  (let* ((string (thing-at-point 'line t))
         (sep (cond (separators)
                    ("\\."))))
    (string-match (format "^\\([[:alnum:]]+%s\\)*" sep) string)
    (match-string 0 string)))

(defun toc--count-level-by-index (separators)
  "Determine level of current line in TOC tree by counting SEPARATORS."
  (let* ((index (toc--get-section-inidices separators))
         (sep (cond (separators)
                    ("\\.")))
         (string-list (split-string index sep t)))
    (length string-list)))

(defun toc-cleanup-set-level-by-index (&optional arg)
  "Automatic set indentation by number of separatorss in index.
By default uses dots as separators. Prepend with universal
ARG (\\[universal-argument]) to enter different separators."
  (interactive "P")
  (let ((separators (if arg
                        (read-string
                         "Enter index separators as regexp (escape with \\ if required): ")
                      nil)))
    (goto-char (point-min))
    (while (re-search-forward "^\\s-+" nil t)
      (replace-match ""))
    (goto-char (point-min))
    (while (not (eobp))
      (let* ((level (toc--count-level-by-index separators)))
        (dotimes (_x level) (insert " "))
        (forward-line 1)))))

;;; toc extract
(defun toc--document-extract-pages-text (startpage endpage)
  "Extract text from text layer of current document from STARTPAGE to ENDPAGE."
  (let* ((source-buffer (current-buffer))
         (ext (url-file-extension (buffer-file-name (current-buffer))))
         (default-process-coding-system
           (cond ((string= ".pdf" ext)'(windows-1252-unix . utf-8-unix))
                 ((string= ".djvu" ext) '(utf-8-unix . utf-8-unix))))
         (shell-command (cond ((string= ".pdf" ext) "pdftotext -f %s -l %s -layout %s -")
                              ((string= ".djvu" ext) "djvutxt --page=%s-%s %s")
                              (t (error "Buffer-filename does not have pdf or djvu extension"))))
         (text (shell-command-to-string
                (format shell-command
                        startpage
                        endpage
                        (shell-quote-argument buffer-file-name))))
         (buffer (get-buffer-create (file-name-sans-extension (buffer-name)))))
    (switch-to-buffer buffer)
    (toc-cleanup-mode) ;; required before setting local variable
    (when (fboundp 'flyspell-mode)
      flyspell-mode)
    (setq-local doc-buffer source-buffer)
    (insert text)))

;;;###autoload
(defun toc-extract-pages (arg)
  "Extract text from text layer of current document and cleanup.
Extract from STARTPAGE to ENDPAGE. Use with the universal
ARG (\\[universal-argument]) omits cleanup to get the unprocessed
text."
  (interactive "P")
  (let ((mode (derived-mode-p 'pdf-view-mode 'djvu-read-mode)))
    (if mode
        (let* ((startpage (read-string "Enter start-pagenumber for extraction: "))
               (endpage (read-string "Enter end-pagenumber for extraction: ")))
          (toc--document-extract-pages-text startpage endpage)
          (unless arg
            (toc--cleanup startpage)))
      (message "Buffer not in pdf-view- or djvu-read-mode"))))

(defun toc-list-languages ()
  "List languages available for ocr.
For use in `toc-ocr-languages'."
  (interactive)
  (let ((print-length nil))
    (message (format "%s" (seq-subseq
                         (split-string
                          (shell-command-to-string "tesseract --list-langs"))
                         5)))))

;;;###autoload
(defun toc-extract-pages-ocr (arg)
  "Extract via OCR text of current document and cleanup.
Extract from STARTPAGE to ENDPAGE. Use with the universal
ARG (\\[universal-argument]) omits cleanup to get the
unprocessed text."
  (interactive "p")
  (let ((mode (derived-mode-p 'pdf-view-mode 'djvu-read-mode)))
    (if mode
        (let* ((startpage (string-to-number
                           (read-string "Enter start-pagenumber for extraction: ")))
               (endpage (string-to-number
                         (read-string "Enter end-pagenumber for extraction: ")))
               (page startpage)
               (source-buffer (current-buffer))
               (ext (url-file-extension (buffer-file-name (current-buffer))))
               (buffer (file-name-sans-extension (buffer-name)))
               (psm (if (= arg 16)
                        (read-string "Enter code (interger) for tesseract psm: ")
                      "6"))
               (args (list "stdout" "--psm" psm)))
          (when toc-ocr-languages
            (setq args (append args (list "-l" toc-ocr-languages))))
          (while (<= page (+ endpage))
            (let ((file (cond ((string= ".pdf" ext)
                               (make-temp-file "pageimage"
                                               nil
                                               (number-to-string page)
                                               (pdf-cache-get-image page 600)))
                              ((string= ".djvu" ext)
                               (djvu-goto-page page)
                               (make-temp-file "pageimage"
                                               nil
                                               (number-to-string page)
                                               (image-property djvu-doc-image :data))))))
              (apply 'call-process
                     (append (list "tesseract" nil (list buffer nil) nil file)
                             args))
              (setq page (1+ page))))
          (switch-to-buffer buffer)
          (toc-cleanup-mode) ;; required before setting local variable
          (when (fboundp 'flyspell-mode)
            (flyspell-mode))
          (setq-local doc-buffer source-buffer)
          (unless (or (= arg 4) (= arg 16))
            (toc--cleanup startpage t)))
      (message "Buffer not in pdf-view- or djvu-read-mode"))))

;;;###autoload
(defun toc-extract-outline ()
  "Extract Table of Contents attached to current document."
  (interactive)
  (let* ((source-buffer (current-buffer))
         (ext (url-file-extension (buffer-file-name (current-buffer))))
         (shell-command (cond ((string= ".pdf" ext) (if (executable-find "mutool")
                                                        "mutool show %s outline"
                                                      "mutool command is not found"))
                              ((string= ".djvu" ext) "djvused -e 'print-outline' %s")
                              (t (error "Buffer-filename does not have pdf or djvu extension"))))
         (text (shell-command-to-string
                (format shell-command
                        (shell-quote-argument buffer-file-name))))
         (buffer (get-buffer-create (concat (file-name-sans-extension (buffer-name)) ".txt"))))
    (switch-to-buffer buffer)
    (setq-local doc-buffer source-buffer)
    (insert text)))

;;;###autoload
(defun toc-extract-only ()
  "Just extract text via OCR without further processing.
Prompt for startpage and endpage and print OCR output to new buffer."
  (interactive)
  (let ((mode (derived-mode-p 'pdf-view-mode 'djvu-read-mode)))
    (if mode
        (let* ((page (string-to-number
                      (read-string "Enter start-pagenumber for extraction: ")))
               (endpage (string-to-number
                         (read-string "Enter end-pagenumber for extraction: ")))
               (ext (url-file-extension (buffer-file-name (current-buffer))))
               (buffer (concat (file-name-sans-extension (buffer-name)) ".txt"))
               (args (list "stdout" "--psm" "6")))
          (when toc-ocr-languages
            (setq args (append args (list "-l" toc-ocr-languages))))
          (while (<= page (+ endpage))
            (let ((file (cond ((string= ".pdf" ext)
                               (make-temp-file "pageimage"
                                               nil
                                               (number-to-string page)
                                               (pdf-cache-get-image page 600)))
                              ((string= ".djvu" ext)
                               (djvu-goto-page page)
                               (make-temp-file "pageimage"
                                               nil
                                               (number-to-string page)
                                               (image-property djvu-doc-image :data))))))
              (apply 'call-process
                     (append (list "tesseract" nil (list buffer nil) nil file)
                             args))
              (setq page (1+ page))))
          (switch-to-buffer buffer)))))

(defun toc--create-tablist-buffer ()
  "Create tablist buffer, from cleaned up Table of Contents buffer, for easy page number adjustment."
  (interactive)
  (toc--list doc-buffer))

;;;; toc major modes

(when (require 'pdf-tools nil t)
  (define-key pdf-view-mode-map (kbd "C-c C-e") 'toc-extract-pages)
  (define-key pdf-view-mode-map (kbd "C-c e") 'toc-extract-pages-ocr))

(when (require 'djvu nil t)
  (define-key djvu-read-mode-map (kbd "C-c C-e") 'toc-extract-pages)
  (define-key djvu-read-mode-map (kbd "C-c e") 'toc-extract-pages-ocr))

(defvar toc-cleanup-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-c" #'toc--create-tablist-buffer)
    (define-key map "\C-c\C-j" #'toc--join-next-unnumbered-lines)
    (define-key map "\C-c\C-s" #'toc--roman-to-arabic)
    map))

(define-derived-mode toc-cleanup-mode
  fundamental-mode "TOC-cleanup"
  "Major mode for cleaning up Table Of Contents
\\{toc-cleanup-mode-map}")

;;; toc tablist

(defun toc-count-leading-spaces ()
  "Count number of leading spaces on current line."
  (interactive)
  (let ((start (string-match "^ *" (thing-at-point 'line)))
        (end (match-end 0)))
    (- end start)))

(defun toc--convert-to-tabulated-list ()
  "Parse and prepare content of current buffer for `toc-tabular-mode'."
  (interactive)
  (goto-char (point-min))
  (let (lines
        levels)
    (while (not (eobp))
      (let ((line-list (split-string (buffer-substring (line-beginning-position) (line-end-position))))
            (spaces (toc-count-leading-spaces)))
        (unless (member spaces levels)
          (setq levels (append levels (list spaces))))
        (setq lines
              (append
               lines
               (list (list nil
                           (vector
                            (number-to-string (seq-position levels spaces))
                            (mapconcat #'identity (butlast line-list) " ")
                            (mapconcat #'identity (last line-list) " "))))))
        (forward-line)))
    lines))

(defun toc--increase ()
  "Increase pagenumber of current entry."
  (interactive)
  (tabulated-list-set-col
   "page"
   (number-to-string (+ (string-to-number (aref (tabulated-list-get-entry) 2)) 1))
   t))

(defun toc--decrease ()
  "Decrease pagenumber of current entry."
  (interactive)
  (tabulated-list-set-col
   "page"
   (number-to-string (- (string-to-number (aref (tabulated-list-get-entry) 2)) 1))
   t))

(defun toc--increase-remaining ()
  "Increase pagenumber of current entry and all entries below."
  (interactive)
  (save-excursion
    (while (not (eobp))
      (tabulated-list-set-col
       "page"
       (number-to-string (+ (string-to-number (aref (tabulated-list-get-entry) 2)) 1))
       t)
      (forward-line 1))))

(defun toc--decrease-remaining ()
  "Decrease pagenumber of current entry and all entries below."
  (interactive)
  (save-excursion
    (while (not (eobp))
      (tabulated-list-set-col
       "page"
       (number-to-string (- (string-to-number (aref (tabulated-list-get-entry) 2)) 1))
       t)
      (forward-line 1))))

(defun toc--replace-input ()
  (interactive)
  (let* ((column (cond ((< (current-column) 5)
                       0)
                      ((and (> (current-column) 5) (< (current-column) 90))
                       1)
                      ((> (current-column) 90)
                       2)))
         (old-input (aref (tabulated-list-get-entry) column))
         (new-input (read-string "Replace column input with: " old-input)))
    (tabulated-list-set-col column new-input t)))

(defun toc--tablist-follow ()
  "Preview pagenumber of current line in separate document buffer."
  (interactive)
  (let ((ext (url-file-extension (buffer-file-name doc-buffer)))
        (page (string-to-number (aref (tabulated-list-get-entry) 2))))
    (pop-to-buffer doc-buffer)
    (cond ((string= ".pdf" ext) (pdf-view-goto-page page))
          ((string= ".djvu" ext) (djvu-goto-page page)))
    (other-window 1)))

(defun toc--increase-remaining-and-follow ()
  "Increase pagenumber of current entry and all entries below and preview page in separate document buffer."
  (interactive)
  (toc--increase-remaining)
  (toc--tablist-follow))

(defun toc--decrease-remaining-and-follow ()
  "Decrease pagenumber of current entry and all entries below and preview page in separate document buffer."
  (interactive)
  (toc--decrease-remaining)
  (toc--tablist-follow))

(defun toc--scroll-other-window-page-up ()
  "Scroll page up in document buffer from current buffer."
  (interactive)
  (other-window 1)
  (let ((ext (url-file-extension (buffer-file-name (current-buffer)))))
    (cond ((string= ".pdf" ext) (pdf-view-next-page 1))
          ((string= ".djvu" ext) (djvu-next-page 1))))
  (other-window 1))

(defun toc--scroll-other-window-page-down ()
  "Scroll page down in document buffer from current buffer."
  (interactive)
  (other-window 1)
  (let ((ext (url-file-extension (buffer-file-name (current-buffer)))))
    (cond ((string= ".pdf" ext) (pdf-view-previous-page 1))
          ((string= ".djvu" ext) (djvu-prev-page 1))))
  (other-window 1))

(defun toc--scroll-pdf-other-window-down ()
  "Scroll down in document buffer from current buffer."
  (interactive)
  (other-window 1)
  (let ((ext (url-file-extension (buffer-file-name (current-buffer)))))
    (cond ((string= ".pdf" ext) (pdf-view-scroll-up-or-next-page 1))
          ((string= ".djvu" ext) (djvu-scroll-up-or-next-page))))
  (other-window 1))

(defun toc--scroll-pdf-other-window-up ()
  "Scroll up in document buffer from current buffer."
  (interactive)
  (other-window 1)
  (let ((ext (url-file-extension (buffer-file-name (current-buffer)))))
    (cond ((string= ".pdf" ext) (pdf-view-scroll-down-or-previous-page 1))
          ((string= ".djvu" ext) (djvu-scroll-down-or-previous-page))))
  (other-window 1))

(defun toc--jump-to-next-entry-by-level (char)
  "Jump to the next entry of level CHAR."
  (interactive "cJump to next entry of level: ")
  (forward-line)
  (let ((level (char-to-string char)))
    (while (not (or (string= (aref (tabulated-list-get-entry) 0) level) (eobp)))
                (forward-line)))
  (toc--tablist-follow))

(defvar toc-tabular-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [right] #'toc--increase-remaining)
    (define-key map [left] #'toc--decrease-remaining)
    (define-key map [S-right] #'toc--increase)
    (define-key map [S-left] #'toc--decrease)
    (define-key map [C-right] #'toc--increase-remaining-and-follow)
    (define-key map [C-left] #'toc--decrease-remaining-and-follow)
    (define-key map "\C-r" #'toc--replace-input)
    (define-key map [tab] #'toc--tablist-follow)
    (define-key map [S-down] #'toc--scroll-other-window-page-up)
    (define-key map [S-up] #'toc--scroll-other-window-page-down)
    (define-key map [C-down] #'toc--scroll-pdf-other-window-down)
    (define-key map [C-up] #'toc--scroll-pdf-other-window-up)
    (define-key map "\C-j" #'toc--jump-to-next-entry-by-level)
    (define-key map "\C-c\C-c" #'toc--tablist-to-toc-source)
    (define-key map "\C-c\C-c" #'toc--tablist-to-toc-source)
    (when (featurep 'evil-commands)
      (define-key map "\S-j" #'evil-scroll-page-down)
      (define-key map "\S-k" #'evil-scroll-page-up))
    map))

(define-derived-mode toc-tabular-mode
  tabulated-list-mode "TOC-tabular"
  "Major mode for Table Of Contents.
\\{toc-tabular-mode-map}"
  (setq-local tabulated-list-format [("level" 5 nil) ("name" 84 nil) ("page" 4 nil)])
  (tabulated-list-init-header))

(defun toc--list (buffer)
  "Create, BUFFER, new tabular-mode-buffer for easy pagenumber adjusment."
  (interactive)
  (let ((source-buffer buffer)
        (toc-tablist (toc--convert-to-tabulated-list)))
    (switch-to-buffer (concat (buffer-name) ".list"))
    (when (fboundp 'golden-ratio-mode)
      (golden-ratio-mode))
    (toc-tabular-mode)
    (setq-local doc-buffer source-buffer)
    (setq-local tabulated-list-entries toc-tablist)
    (tabulated-list-print)))

;;;; parse tablist to outline

(defvar toc-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c\C-c" #'toc--add-to-doc)
    map))

(define-derived-mode toc-mode
  fundamental-mode "TOC"
  "Major mode for editing pdf or djvu Table Of Contents source files
\\{toc-mode-map}")


;;; pdf parse tablist to
(defun toc--tablist-to-pdfoutline ()
  "Parse and prepare tablist-mode-buffer to source input.
Displays results in a newlycreated buffer for use as source input
to `pdfoutline' shell command."
  (interactive)
  (goto-char (point-min))
  (let ((source-buffer doc-buffer)
        text)
    (while (not (eobp))
      (let ((v (tabulated-list-get-entry)))
        (setq text (concat text (format "%s %s %s\n" (aref v 0) (aref v 2) (aref v 1) )))
        (forward-line 1)))
    (switch-to-buffer (find-file (concat (file-name-sans-extension (buffer-name)) ".txt")))
    (erase-buffer)
    (toc-mode)
    (setq-local doc-buffer source-buffer)
    (insert text)))

;;; djvu parse tablist to outline
(defun toc--tablist-to-djvused ()
  "Parse and prepare djvused outline source form tablist."
  (interactive)
  (let ((source-buffer doc-buffer)
        (buff (get-buffer-create
               (concat
                (file-name-sans-extension (buffer-name))
                ".txt"))))
    (with-current-buffer buff
      (insert "(bookmarks "))
    (goto-char (point-min))
    (while (not (eobp))
      (let* ((v (tabulated-list-get-entry))
             (level-current (string-to-number (aref v 0)))
             (sexp (list (aref v 1) (format "#%s" (aref v 2))))
             (v-next (progn (forward-line) (tabulated-list-get-entry)))
             (level-next (when v-next (string-to-number (aref v-next 0)))))
        (if level-next
            (with-current-buffer buff
              (cond ((= level-next level-current)
                     (insert (format "(%s \"%s\") " (prin1-to-string (car sexp)) (nth 1 sexp))))
                    ((> level-next level-current)
                     (insert (format "(%s \"%s\" " (prin1-to-string (car sexp)) (nth 1 sexp))))
                    ((< level-next level-current)
                     (insert (format "(%s \"%s\")" (prin1-to-string (car sexp)) (nth 1 sexp)))
                     (let ((level-diff (- level-current level-next)))
                       (while (> level-diff 0)
                         (insert ") ")
                         (setq level-diff (1- level-diff)))))))
          (forward-line))))
    (forward-line -1)
    (let ((v (tabulated-list-get-entry)))
          (switch-to-buffer buff)
          (insert (format " (\"%s\" \"#%s\"))" (aref v 1) (aref v 2)))
          (toc-mode)
          (setq-local doc-buffer source-buffer))))

(defun toc--tablist-to-toc-source ()
  "Parse and prepare source file.
From tablist-mode-buffer, parse code and create source in new
buffer to use as input for `pdfoutline' or `djvused' shell
command."
  (interactive)
  (let ((ext (url-file-extension (buffer-file-name doc-buffer))))
    (cond ((string= ".pdf" ext) (toc--tablist-to-pdfoutline))
          ((string= ".djvu" ext) (toc--tablist-to-djvused))
          (t (error "Buffer-source-file does not have pdf or djvu extension")))))

(defun toc--open-handy-outliner ()
  "Open handyoutliner to add TOC to document.
Prepare TOC using `toc--tablist-to-handyoutliner'. Requires the
variabele `toc-handyoutliner-path' to be set to the correct
path."
  (interactive)
  (start-process ""
                 nil
                 toc-handyoutliner-path))

(defun toc--open-filepath-in-file-browser ()
  "Open the buffer file directory in the file browser.
When the variable `toc-file-browser-command' is set, this
function is used by the `toc--tablist-to-handyoutliner' function
so that the generated TOC can be easily added to the document
with the handyoutliner software."
  (interactive)
  (let ((process-connection-type nil))
    (start-process ""
                   nil
                   toc-file-browser-command
                   (url-file-directory (buffer-file-name)))))

;;; pdf parse tablist to
(defun toc--tablist-to-handyoutliner ()
  "Parse and prepare tablist-mode-buffer to source input.
Displays results in a newlycreated buffer for use as source input
to `pdfoutline' shell command."
  (interactive)
  (goto-char (point-min))
  (let ((source-buffer (when (boundp 'doc-buffer) doc-buffer))
        text)
    (while (not (eobp))
      (let* ((v (tabulated-list-get-entry))
             (tabs (make-string (string-to-number (aref v 0)) ?\t)))
        (setq text (concat text (format "%s%s %s\n" tabs (aref v 1) (aref v 2))))
        (forward-line 1)))
    (switch-to-buffer (find-file "contents.txt"))
    (erase-buffer)
    (toc-mode)
    (when source-buffer
      (setq-local doc-buffer source-buffer))
    (insert text))
  (save-buffer)
  (if (not (and toc-handyoutliner-path toc-file-browser-command))
      (message "Path to handyoutliner or file browser command not defined")
    (toc--open-handy-outliner)
    (toc--open-filepath-in-file-browser)))


;;;; add outline to document
(defun toc--add-to-pdf ()
  "Use buffer contents as source for adding TOC to PDF using the shell program `pdfoutline'."
  (interactive)
  (save-buffer)
  (call-process "pdfoutline" nil "*pdfoutline*" nil
                (concat (file-name-sans-extension (buffer-name)) ".pdf")
                (buffer-name)
                (if toc-replace-original-file
                    (concat (file-name-sans-extension (buffer-name)) ".pdf")
                  toc-destination-file-name)))

(defun toc--add-to-djvu ()
  "Use buffer contents as source for adding TOC to DJVU using the shell program `djvused'."
  (interactive)
  (write-file default-directory)
  (print (format
          "djvused -s -e \"set-outline '%s'\" %s"
          (buffer-name)
          (shell-quote-argument
           (concat (file-name-sans-extension (buffer-name)) ".djvu"))))
  (shell-command-to-string
                  (format
                   "djvused -s -e \"set-outline '%s'\" %s"
                   (buffer-name)
                   (shell-quote-argument
                    (concat (file-name-sans-extension (buffer-name)) ".djvu")))))


(defun toc--add-to-doc ()
  "Add Table Of Contents to original document.
The text of the current buffer is passed as source input to either the
`pdfoutline' or `djvused' shell command."
  (interactive)
  (let ((ext (url-file-extension (buffer-file-name doc-buffer))))
    (cond ((string= ".pdf" ext) (toc--add-to-pdf))
          ((string= ".djvu" ext) (toc--add-to-djvu)))))

(defun toc--source-to-handyoutliner ()
  " "
  (interactive)
  (goto-char (point-min))
  (while (not (eobp))
    (let ((num (thing-at-point 'number)))
      (delete-char 2)
      (dotimes (_x num) (insert "\t"))
      (re-search-forward "[0-9]+")
      (let ((page (match-string 0)))
        (replace-match "")
        (delete-char 1)
        (move-end-of-line 1)
        (insert " ")
        (insert page)
      (forward-line)))
    ))
  ;; (goto-char (point-min))
  ;; (while (not (eobp))
  ;;   (re-search-forward "[0-9]+")
  ;;   (let ((page (match-string 0)))
  ;;     (replace-match "")
  ;;     (delete-char 1)
  ;;     (move-end-of-line 1)
  ;;     (insert " ")
  ;;     (insert page)
  ;;     (forward-line))))

(provide 'toc-mode)

;;; toc-mode.el ends here
