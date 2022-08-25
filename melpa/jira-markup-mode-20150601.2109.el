;;; jira-markup-mode.el --- Emacs Major mode for JIRA-markup-formatted text files

;; Copyright (C) 2012-2015 Matthias Nuessler <m.nuessler@web.de>

;; Author: Matthias Nuessler <m.nuessler@web.de>>
;; Created: July 15, 2012
;; Version: 0.0.1
;; Package-Version: 20150601.2109
;; Package-Commit: 53bf083fdbece483f1351f32085b424b38c4c1f2
;; Keywords: jira, markup
;; URL: https://github.com/mnuessler/jira-markup-mode

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;; Jira-markup-mode provides a major mode for editing JIRA wiki markup
;; files. Unlike jira.el it does not interact with JIRA.
;;
;; The code is based on markdown-mode.el, a major for mode for editing
;; markdown files.
;; https://confluence.atlassian.com/display/DOC/Confluence+Wiki+Markup

;;; Dependencies:

;; jira-markup-mode requires easymenu, a standard package since GNU Emacs
;; 19 and XEmacs 19, which provides a uniform interface for creating
;; menus in GNU Emacs and XEmacs.

;;; Installation:

;; Make sure to place `jira-markup-mode.el` somewhere in the load-path and add
;; the following lines to your `.emacs` file to associate jira-markup-mode
;; with `.text` files:
;;
;;     (autoload 'jira-markup-mode "jira-markup-mode"
;;        "Major mode for editing JIRA markup files" t)
;;     (setq auto-mode-alist
;;        (cons '("\\.text" . jira-markup-mode) auto-mode-alist))
;;

;;; Acknowledgments:

;; Jira-markup-mode has benefited greatly from the efforts of the
;; developers of markdown-mode.  Markdown-mode was developed and is
;; maintained by Jason R. Blevins <jrblevin@sdf.org>.  For details
;; please refer to http://jblevins.org/projects/markdown-mode/

;;; History:

;; jira-markup-mode was written and is maintained by Matthias Nuessler.  The
;; first version was released on TODO, 2012.
;;
;;   * 2012-07-TODO: Version 0.1.0

;;; Code:

(require 'easymenu)
(require 'outline)
(eval-when-compile (require 'cl))

;;; Constants =================================================================

(defconst jira-markup-mode-version "0.1.0"
  "Jira markup mode version number.")

;;; Customizable variables ====================================================

(defvar jira-markup-mode-hook nil
  "Hook run when entering jira markup mode.")

(defgroup jira-markup nil
  "Major mode for editing text files in Jira markup format."
  :prefix "jira-markup"
  :group 'wp
  :link '(url-link "https://github.com/mnuessler/jira-markup-mode"))

(defcustom jira-markup-hr-string "----"
  "String to use for horizonal rules."
  :group 'jira-markup
  :type 'string)

(defcustom jira-markup-indent-function 'jira-markup-indent-line
  "Function to use to indent."
  :group 'jira-markup
  :type 'function)

(defcustom jira-markup-indent-on-enter t
  "Automatically indent new lines when enter key is pressed."
  :group 'jira-markup
  :type 'boolean)

(defcustom jira-markup-follow-wiki-link-on-enter t
  "Follow wiki link at point (if any) when the enter key is pressed."
  :group 'jira-markup
  :type 'boolean)

(defcustom jira-markup-wiki-link-alias-first t
  "When non-nil, treat aliased wiki links like [[alias text|PageName]].
Otherwise, they will be treated as [[PageName|alias text]]."
  :group 'jira-markup
  :type 'boolean)

(defcustom jira-markup-uri-types
  '("acap" "cid" "data" "dav" "fax" "file" "ftp" "gopher" "http" "https"
    "imap" "ldap" "mailto" "mid" "modem" "news" "nfs" "nntp" "pop" "prospero"
    "rtsp" "service" "sip" "tel" "telnet" "tip" "urn" "vemmi" "wais")
  "Link types for syntax highlighting of URIs."
  :group 'jira-markup
  :type 'list)

(defcustom jira-markup-link-space-sub-char
  "_"
  "Character to use instead of spaces when mapping wiki links to filenames."
  :group 'jira-markup
  :type 'string)


;;; Font lock =================================================================

(require 'font-lock)

(defvar jira-markup-italic-face 'jira-markup-italic-face
  "Face name to use for italic text.")

(defvar jira-markup-bold-face 'jira-markup-bold-face
  "Face name to use for bold text.")

(defvar jira-markup-header-face 'jira-markup-header-face
  "Face name to use as a base for headers.")

(defvar jira-markup-header-face-1 'jira-markup-header-face-1
  "Face name to use for level-1 headers.")

(defvar jira-markup-header-face-2 'jira-markup-header-face-2
  "Face name to use for level-2 headers.")

(defvar jira-markup-header-face-3 'jira-markup-header-face-3
  "Face name to use for level-3 headers.")

(defvar jira-markup-header-face-4 'jira-markup-header-face-4
  "Face name to use for level-4 headers.")

(defvar jira-markup-header-face-5 'jira-markup-header-face-5
  "Face name to use for level-5 headers.")

(defvar jira-markup-header-face-6 'jira-markup-header-face-6
  "Face name to use for level-6 headers.")

(defvar jira-markup-inline-code-face 'jira-markup-inline-code-face
  "Face name to use for inline code.")

(defvar jira-markup-list-face 'jira-markup-list-face
  "Face name to use for list markers.")

(defvar jira-markup-blockquote-face 'jira-markup-blockquote-face
  "Face name to use for blockquote.")

(defvar jira-markup-pre-face 'jira-markup-pre-face
  "Face name to use for preformatted text.")

(defvar jira-markup-link-face 'jira-markup-link-face
  "Face name to use for links.")

(defvar jira-markup-missing-link-face 'jira-markup-missing-link-face
  "Face name to use for links where the linked file does not exist.")

(defvar jira-markup-reference-face 'jira-markup-reference-face
  "Face name to use for reference.")

(defvar jira-markup-url-face 'jira-markup-url-face
  "Face name to use for URLs.")

(defvar jira-markup-link-title-face 'jira-markup-link-title-face
  "Face name to use for reference link titles.")

(defgroup jira-markup-faces nil
  "Faces used in Jira-Markup Mode"
  :group 'jira-markup
  :group 'faces)

(defface jira-markup-italic-face
  '((t (:inherit font-lock-variable-name-face :slant italic)))
  "Face for italic text."
  :group 'jira-markup-faces)

(defface jira-markup-bold-face
  '((t (:inherit font-lock-variable-name-face :weight bold)))
  "Face for bold text."
  :group 'jira-markup-faces)

(defface jira-markup-header-face
  '((t (:inherit font-lock-function-name-face :weight bold)))
  "Base face for headers."
  :group 'jira-markup-faces)

(defface jira-markup-header-face-1
  '((t (:inherit jira-markup-header-face)))
  "Face for level-1 headers."
  :group 'jira-markup-faces)

(defface jira-markup-header-face-2
  '((t (:inherit jira-markup-header-face)))
  "Face for level-2 headers."
  :group 'jira-markup-faces)

(defface jira-markup-header-face-3
  '((t (:inherit jira-markup-header-face)))
  "Face for level-3 headers."
  :group 'jira-markup-faces)

(defface jira-markup-header-face-4
  '((t (:inherit jira-markup-header-face)))
  "Face for level-4 headers."
  :group 'jira-markup-faces)

(defface jira-markup-header-face-5
  '((t (:inherit jira-markup-header-face)))
  "Face for level-5 headers."
  :group 'jira-markup-faces)

(defface jira-markup-header-face-6
  '((t (:inherit jira-markup-header-face)))
  "Face for level-6 headers."
  :group 'jira-markup-faces)

(defface jira-markup-inline-code-face
  '((t (:inherit font-lock-constant-face)))
  "Face for inline code."
  :group 'jira-markup-faces)

(defface jira-markup-list-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for list item markers."
  :group 'jira-markup-faces)

(defface jira-markup-blockquote-face
  '((t (:inherit font-lock-doc-face)))
  "Face for blockquote sections."
  :group 'jira-markup-faces)

(defface jira-markup-pre-face
  '((t (:inherit font-lock-constant-face)))
  "Face for preformatted text."
  :group 'jira-markup-faces)

(defface jira-markup-link-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for links."
  :group 'jira-markup-faces)

(defface jira-markup-missing-link-face
  '((t (:inherit font-lock-warning-face)))
  "Face for missing links."
  :group 'jira-markup-faces)

(defface jira-markup-reference-face
  '((t (:inherit font-lock-type-face)))
  "Face for link references."
  :group 'jira-markup-faces)

(defface jira-markup-url-face
  '((t (:inherit font-lock-string-face)))
  "Face for URLs."
  :group 'jira-markup-faces)

(defface jira-markup-link-title-face
  '((t (:inherit font-lock-comment-face)))
  "Face for reference link titles."
  :group 'jira-markup-faces)

;; regular expressions
;; TODO
(defconst jira-markup-regex-link-inline
  "\\(!?\\[[^]]*?\\]\\)\\(([^\\)]*)\\)"
  "Regular expression for a [text](file) or an image link ![text](file).")

;; TODO
(defconst jira-markup-regex-link-reference
  "\\(!?\\[[^]]+?\\]\\)[ ]?\\(\\[[^]]*?\\]\\)"
  "Regular expression for a reference link [text][id].")

;; TODO
(defconst jira-markup-regex-reference-definition
  "^ \\{0,3\\}\\(\\[.*\\]\\):\\s *\\(.*?\\)\\s *\\( \"[^\"]*\"$\\|$\\)"
  "Regular expression for a link id [definition]: ...")

;; TODO
(defconst jira-markup-regex-header
  "#+\\|\\S-.*\n\\(?:\\(===+\\)\\|\\(---+\\)\\)$"
  "Regexp identifying Jira-Markup headers.")

; headings
(defconst jira-markup-regex-header-1
  "^\\s-*h1\\.\\s-+.*$"
  "Regular expression for level 1 headers.")

(defconst jira-markup-regex-header-2
  "^\\s-*h2\\.\\s-+.*$"
  "Regular expression for level 2 headers.")

(defconst jira-markup-regex-header-3
  "^\\s-*h3\\.\\s-+.*$"
  "Regular expression for level 3 headers.")

(defconst jira-markup-regex-header-4
  "^\\s-*h4\\.\\s-+.*$"
  "Regular expression for level 4 headers.")

(defconst jira-markup-regex-header-5
  "^\\s-*h5\\.\\s-+.*$"
  "Regular expression for level 5 headers.")

(defconst jira-markup-regex-header-6
  "^\\s-*h6\\.\\s-+.*$"
  "Regular expression for level 6 headers.")

(defconst jira-markup-regex-hr
  "^\\s-*----$"
  "Regular expression for matching Jira-Markup horizontal rules.")

;; TODO
(defconst jira-markup-regex-code
  "\\(^\\|[^\\]\\)\\(\\(`\\{1,2\\}\\)\\([^ \\]\\|[^ ]\\(.\\|\n[^\n]\\)*?[^ \\]\\)\\3\\)"
  "Regular expression for matching inline code fragments.")

;; TODO
(defconst jira-markup-regex-pre
  "^\\(    \\|\t\\).*$"
  "Regular expression for matching preformatted text sections.")

;; TODO
(defconst jira-markup-regex-list
  "^[ \t]*\\([0-9]+\\.\\|[\\*\\+-]\\) "
  "Regular expression for matching list markers.")

; text effects
(defconst jira-markup-regex-strong
  "\\s-+\\*.*\\*\\s-+"
  "Regular expression for matching *strong* text.")

(defconst jira-markup-regex-emphasis
  "\\s-+_.*_\\s-+"
  "Regular expression for matching _emphasized_ text.")

; new
(defconst jira-markup-regex-citation
  "\\s-+\\?\\?.*\\s-+"
  "Regular expression for matching ??cited?? text.")

; new
(defconst jira-markup-regex-deleted
  "\\s-+-.*-\\s-"
  "Regular expression for matching -deleted- text.")

; new
(defconst jira-markup-regex-inserted
  "\\s-+\\+.*\\+\\s-+"
  "Regular expression for matching +inserted+ text.")

; new
(defconst jira-markup-regex-superscript
  "\\s-+^.*^\\s-+"
  "Regular expression for matching ^superscript^ text.")

; new
(defconst jira-markup-regex-subscript
  "\\s-+~.*~\\s-+"
  "Regular expression for matching ~subscript~ text.")

; new
(defconst jira-markup-regex-monospaced
  "\\s-+{{.*}}\\s-+"
  "Regular expression for matching {{monospaced}} text.")

(defconst jira-markup-regex-blockquote
  "^[ \t]*bq\\."
  "Regular expression for matching blockquote lines.")

;; TODO
(defconst jira-markup-regex-line-break
  "  $"
  "Regular expression for matching line breaks.")

;; TODO
(defconst jira-markup-regex-wiki-link
  "\\[\\[\\([^]|]+\\)\\(|\\([^]]+\\)\\)?\\]\\]"
  "Regular expression for matching wiki links.
This matches typical bracketed [[WikiLinks]] as well as 'aliased'
wiki links of the form [[PageName|link text]].  In this regular
expression, #1 matches the page name and #3 matches the link
text.")

(defconst jira-markup-regex-uri
  (concat
   "\\(" (mapconcat 'identity jira-markup-uri-types "\\|")
   "\\):[^]\t\n\r<>,;() ]+")
  "Regular expression for matching inline URIs.")

(defconst jira-markup-regex-angle-uri
  (concat
   "\\(<\\)\\("
   (mapconcat 'identity jira-markup-uri-types "\\|")
   "\\):[^]\t\n\r<>,;()]+\\(>\\)")
  "Regular expression for matching inline URIs in angle brackets.")

(defconst jira-markup-regex-email
  "<\\(\\sw\\|\\s_\\|\\s.\\)+@\\(\\sw\\|\\s_\\|\\s.\\)+>"
  "Regular expression for matching inline email addresses.")

(defconst jira-markup-regex-list-indent
  "^\\(\\s *\\)\\([0-9]+\\.\\|[\\*\\+-]\\)\\(\\s +\\)"
  "Regular expression for matching indentation of list items.")

(defvar jira-markup-mode-font-lock-keywords-basic
  (list
   '(jira-markup-match-pre-blocks 0 jira-markup-pre-face t t)
   '(jira-markup-match-fenced-code-blocks 0 jira-markup-pre-face t t)
   (cons jira-markup-regex-blockquote 'jira-markup-blockquote-face)
   (cons jira-markup-regex-header-1 'jira-markup-header-face-1)
   (cons jira-markup-regex-header-2 'jira-markup-header-face-2)
   (cons jira-markup-regex-header-3 'jira-markup-header-face-3)
   (cons jira-markup-regex-header-4 'jira-markup-header-face-4)
   (cons jira-markup-regex-header-5 'jira-markup-header-face-5)
   (cons jira-markup-regex-header-6 'jira-markup-header-face-6)
   (cons jira-markup-regex-hr 'jira-markup-header-face)
   (cons jira-markup-regex-code '(2 jira-markup-inline-code-face))
   (cons jira-markup-regex-angle-uri 'jira-markup-link-face)
   (cons jira-markup-regex-uri 'jira-markup-link-face)
   (cons jira-markup-regex-email 'jira-markup-link-face)
   (cons jira-markup-regex-list 'jira-markup-list-face)
   (cons jira-markup-regex-link-inline
         '((1 jira-markup-link-face t)
           (2 jira-markup-url-face t)))
   (cons jira-markup-regex-link-reference
         '((1 jira-markup-link-face t)
           (2 jira-markup-reference-face t)))
   (cons jira-markup-regex-reference-definition
         '((1 jira-markup-reference-face t)
           (2 jira-markup-url-face t)
           (3 jira-markup-link-title-face t)))
   (cons jira-markup-regex-strong '(2 jira-markup-bold-face))
   (cons jira-markup-regex-emphasis '(2 jira-markup-italic-face))
   )
  "Syntax highlighting for Jira-Markup files.")

(defvar jira-markup-mode-font-lock-keywords
  (append
   jira-markup-mode-font-lock-keywords-basic)
  "Default highlighting expressions for Jira-Markup mode.")

;;; Jira-Markup parsing functions ================================================

(defun jira-markup-cur-line-blank-p ()
  "Return t if the current line is blank and nil otherwise."
  (save-excursion
    (beginning-of-line)
    (re-search-forward "^\\s *$" (point-at-eol) t)))

(defun jira-markup-prev-line-blank-p ()
  "Return t if the previous line is blank and nil otherwise.
If we are at the first line, then consider the previous line to be blank."
  (save-excursion
    (if (= (point-at-bol) (point-min))
        t
      (forward-line -1)
      (jira-markup-cur-line-blank-p))))

(defun jira-markup-next-line-blank-p ()
  "Return t if the next line is blank and nil otherwise.
If we are at the last line, then consider the next line to be blank."
  (save-excursion
    (if (= (point-at-bol) (point-max))
        t
      (forward-line 1)
      (jira-markup-cur-line-blank-p))))

(defun jira-markup-prev-line-indent-p ()
  "Return t if the previous line is indented and nil otherwise."
  (save-excursion
    (forward-line -1)
    (goto-char (point-at-bol))
    (if (re-search-forward "^\\s " (point-at-eol) t) t)))

(defun jira-markup-cur-line-indent ()
  "Return the number of leading whitespace characters in the current line."
  (save-excursion
    (goto-char (point-at-bol))
    (re-search-forward "^\\s +" (point-at-eol) t)
    (current-column)))

(defun jira-markup-prev-line-indent ()
  "Return the number of leading whitespace characters in the previous line."
  (save-excursion
    (forward-line -1)
    (jira-markup-cur-line-indent)))

(defun jira-markup-next-line-indent ()
  "Return the number of leading whitespace characters in the next line."
  (save-excursion
    (forward-line 1)
    (jira-markup-cur-line-indent)))

(defun jira-markup-cur-non-list-indent ()
  "Return the number of leading whitespace characters in the current line."
  (save-excursion
    (beginning-of-line)
    (when (re-search-forward jira-markup-regex-list-indent (point-at-eol) t)
      (current-column))))

(defun jira-markup-prev-non-list-indent ()
  "Return position of the first non-list-marker on the previous line."
  (save-excursion
    (forward-line -1)
    (jira-markup-cur-non-list-indent)))

(defun jira-markup--next-block ()
  "Move the point to the start of the next text block."
  (forward-line)
  (while (and (or (not (jira-markup-prev-line-blank-p))
                  (jira-markup-cur-line-blank-p))
              (not (eobp)))
    (forward-line)))

(defun jira-markup--end-of-level (level)
  "Move the point to the end of region with indentation at least LEVEL."
  (let (indent)
    (while (and (not (< (setq indent (jira-markup-cur-line-indent)) level))
                (not (>= indent (+ level 4)))
                (not (eobp)))
      (jira-markup--next-block))
    (unless (eobp)
      ;; Move back before any trailing blank lines
      (while (and (jira-markup-prev-line-blank-p)
                  (not (bobp)))
        (forward-line -1))
      (forward-line -1)
      (end-of-line))))

(defun jira-markup-match-pre-blocks (last)
  "Match Jira-Markup pre blocks from point to LAST.
A region matches as if it is indented at least four spaces
relative to the nearest previous block of lesser non-list-marker
indentation."

  (let (cur-begin cur-end cur-indent prev-indent prev-list stop match found)
    ;; Don't start in the middle of a block
    (unless (and (bolp)
                 (jira-markup-prev-line-blank-p)
                 (not (jira-markup-cur-line-blank-p)))
      (jira-markup--next-block))

    ;; Move to the first full block in the region with indent 4 or more
    (while (and (not (>= (setq cur-indent (jira-markup-cur-line-indent)) 4))
                (not (>= (point) last)))
      (jira-markup--next-block))
    (setq cur-begin (point))
    (jira-markup--end-of-level cur-indent)
    (setq cur-end (point))
    (setq match nil)
    (setq stop (> cur-begin cur-end))

    (while (and (<= cur-end last) (not stop) (not match))
      ;; Move to the nearest preceding block of lesser (non-marker) indentation
      (setq prev-indent (+ cur-indent 1))
      (goto-char cur-begin)
      (setq found nil)
      (while (and (>= prev-indent cur-indent)
                  (not (and prev-list
                            (eq prev-indent cur-indent)))
                  (not (bobp)))

        ;; Move point to the last line of the previous block.
        (forward-line -1)
        (while (and (jira-markup-cur-line-blank-p)
                    (not (bobp)))
          (forward-line -1))

        ;; Update the indentation level using either the
        ;; non-list-marker indentation, if the previous line is the
        ;; start of a list, or the actual indentation.
        (setq prev-list (jira-markup-cur-non-list-indent))
        (setq prev-indent (or prev-list
                              (jira-markup-cur-line-indent)))
        (setq found t))

      ;; If the loop didn't execute
      (unless found
        (setq prev-indent 0))

      ;; Compare with prev-indent minus its remainder mod 4
      (setq prev-indent (- prev-indent (mod prev-indent 4)))

      ;; Set match data and return t if we have a match
      (if (>= cur-indent (+ prev-indent 4))
          ;; Match
          (progn
            (setq match t)
            (set-match-data (list cur-begin cur-end))
            ;; Leave point at end of block
            (goto-char cur-end)
            (forward-line))

        ;; Move to the next block (if possible)
        (goto-char cur-end)
        (jira-markup--next-block)
        (setq cur-begin (point))
        (setq cur-indent (jira-markup-cur-line-indent))
        (jira-markup--end-of-level cur-indent)
        (setq cur-end (point))
        (setq stop (equal cur-begin cur-end))))
    match))

(defun jira-markup-match-fenced-code-blocks (last)
  "Match fenced code blocks from the point to LAST."
  (cond ((search-forward-regexp "^\\([~]\\{3,\\}\\)" last t)
         (beginning-of-line)
         (let ((beg (point)))
           (forward-line)
           (cond ((search-forward-regexp
                   (concat "^" (match-string 1) "~*") last t)
                  (set-match-data (list beg (point)))
                  t)
                 (t nil))))
        (t nil)))

(defun jira-markup-font-lock-extend-region ()
  "Extend the search region to include an entire block of text.
This helps improve font locking for block constructs such as pre blocks."
  ;; Avoid compiler warnings about these global variables from font-lock.el.
  ;; See the documentation for variable `font-lock-extend-region-functions'.
  (eval-when-compile (defvar font-lock-beg) (defvar font-lock-end))
  (save-excursion
    (goto-char font-lock-beg)
    (let ((found (re-search-backward "\n\n" nil t)))
      (when found
        (goto-char font-lock-end)
        (when (re-search-forward "\n\n" nil t)
          (beginning-of-line)
          (setq font-lock-end (point)))
        (setq font-lock-beg found)))))


;;; Syntax Table ==============================================================

(defvar jira-markup-mode-syntax-table
  (let ((jira-markup-mode-syntax-table (make-syntax-table)))
    (modify-syntax-entry ?\" "w" jira-markup-mode-syntax-table)
    jira-markup-mode-syntax-table)
  "Syntax table for `jira-markup-mode'.")



;;; Element Insertion =========================================================

(defun jira-markup-wrap-or-insert (s1 s2)
 "Insert the strings S1 and S2.
If Transient Mark mode is on and a region is active, wrap the strings S1
and S2 around the region."
 (if (and transient-mark-mode mark-active)
     (let ((a (region-beginning)) (b (region-end)))
       (goto-char a)
       (insert s1)
       (goto-char (+ b (length s1)))
       (insert s2))
   (insert s1 s2)))

(defun jira-markup-insert-hr ()
  "Insert a horizonal rule using `jira-markup-hr-string'."
  (interactive)
  ;; Leading blank line
  (when (and (>= (point) (+ (point-min) 2))
             (not (looking-back "\n\n" 2)))
    (insert "\n"))
  ;; Insert custom HR string
  (insert (concat jira-markup-hr-string "\n"))
  ;; Following blank line
  (backward-char)
  (unless (looking-at "\n\n")
          (insert "\n")))

(defun jira-markup-insert-bold ()
  "Insert markup for a bold word or phrase.
If Transient Mark mode is on and a region is active, it is made bold."
  (interactive)
  (jira-markup-wrap-or-insert "*" "*")
  (backward-char 1))

(defun jira-markup-insert-italic ()
  "Insert markup for an italic word or phrase.
If Transient Mark mode is on and a region is active, it is made italic."
  (interactive)
  (jira-markup-wrap-or-insert "_" "_")
  (backward-char 1))

(defun jira-markup-insert-code ()
  "Insert markup for an inline code fragment.
If Transient Mark mode is on and a region is active, it is marked
as inline code."
  (interactive)
  (jira-markup-wrap-or-insert "{{" "}}")
  (backward-char 2))

(defun jira-markup-insert-link ()
  "Insert an inline link of the form []().
If Transient Mark mode is on and a region is active, it is used
as the link text."
  (interactive)
  (jira-markup-wrap-or-insert "[" "|")
  (insert "]")
  (backward-char 1))

(defun jira-markup-insert-reference-link-region (url label title)
  "Insert a reference link at point using the region as the link text."
  (interactive "sLink URL: \nsLink Label (optional): \nsLink Title (optional): ")
  (let ((text (buffer-substring (region-beginning) (region-end))))
    (delete-region (region-beginning) (region-end))
    (jira-markup-insert-reference-link text url label title)))

(defun jira-markup-insert-reference-link (text url label title)
  "Insert a reference link at point.
The link label definition is placed at the end of the current
paragraph."
  (interactive "sLink Text: \nsLink URL: \nsLink Label (optional): \nsLink Title (optional): ")
  (let (end)
    (insert (concat "[" text "][" label "]"))
    (setq end (point))
    (forward-paragraph)
    (insert "\n[")
    (if (> (length label) 0)
        (insert label)
      (insert text))
    (insert (concat "]: " url))
    (unless (> (length url) 0)
        (setq end (point)))
    (when (> (length title) 0)
      (insert (concat " \"" title "\"")))
    (insert "\n")
    (unless (looking-at "\n")
      (insert "\n"))
    (goto-char end)))

(defun jira-markup-insert-wiki-link ()
  "Insert a wiki link of the form [[WikiLink]].
If Transient Mark mode is on and a region is active, it is used
as the link text."
  (interactive)
  (jira-markup-wrap-or-insert "[[" "]]")
  (backward-char 2))

(defun jira-markup-insert-image ()
  "Insert an inline image tag of the form ![]().
If Transient Mark mode is on and a region is active, it is used
as the alt text of the image."
  (interactive)
  (jira-markup-wrap-or-insert "![" "]")
  (insert "()")
  (backward-char 1))

(defun jira-markup-insert-header-1 ()
  "Insert a first level atx-style (hash mark) header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (jira-markup-insert-header 1))

(defun jira-markup-insert-header-2 ()
  "Insert a second level atx-style (hash mark) header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (jira-markup-insert-header 2))

(defun jira-markup-insert-header-3 ()
  "Insert a third level atx-style (hash mark) header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (jira-markup-insert-header 3))

(defun jira-markup-insert-header-4 ()
  "Insert a fourth level atx-style (hash mark) header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (jira-markup-insert-header 4))

(defun jira-markup-insert-header-5 ()
  "Insert a fifth level atx-style (hash mark) header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (jira-markup-insert-header 5))

(defun jira-markup-insert-header-6 ()
  "Insert a sixth level atx-style (hash mark) header.
If Transient Mark mode is on and a region is active, it is used
as the header text."
  (interactive)
  (jira-markup-insert-header 6))

(defun jira-markup-insert-header (n)
  "Insert a header.
With no prefix argument, insert a level-1 header.  With prefix N,
insert a level-N header.  If Transient Mark mode is on and the
region is active, it is used as the header text."
  (interactive "p")
  (unless n                             ; Test to see if n is defined
    (setq n 1))                         ; Default to level 1 header
  (jira-markup-wrap-or-insert (concat "h" (int-to-string n) ". ") ""))

(defun jira-markup-insert-blockquote ()
  "Start a blockquote section (or blockquote the region).
If Transient Mark mode is on and a region is active, it is used as
the blockquote text."
  (interactive)
  (if (and (boundp 'transient-mark-mode) transient-mark-mode mark-active)
      (jira-markup-blockquote-region (region-beginning) (region-end))
    (insert "bq. ")))

(defun jira-markup-block-region (beg end prefix)
  "Format the region using a block prefix.
Arguments BEG and END specify the beginning and end of the
region.  The characters PREFIX will appear at the beginning
of each line."
  (if mark-active
      (save-excursion
        ;; Ensure that there is a leading blank line
        (goto-char beg)
        (when (and (>= (point) (+ (point-min) 2))
                   (not (looking-back "\n\n" 2)))
          (insert "\n")
          (setq beg (1+ beg))
          (setq end (1+ end)))
        ;; Move back before any blank lines at the end
        (goto-char end)
        (while (and (looking-back "\n" 1)
                    (not (equal (point) (point-min))))
          (backward-char)
          (setq end (1- end)))
        ;; Ensure that there is a trailing blank line
        (goto-char end)
        (if (not (or (looking-at "\n\n")
                     (and (equal (1+ end) (point-max)) (looking-at "\n"))))
          (insert "\n"))
        ;; Insert PREFIX
        (goto-char beg)
        (beginning-of-line)
        (while (< (point-at-bol) end)
          (insert prefix)
          (setq end (+ (length prefix) end))
          (forward-line)))))

(defun jira-markup-blockquote-region (beg end)
  "Blockquote the region.
Arguments BEG and END specify the beginning and end of the region."
  (interactive "*r")
  (jira-markup-block-region beg end "> "))

(defun jira-markup-insert-pre ()
  "Start a preformatted section (or apply to the region).
If Transient Mark mode is on and a region is active, it is marked
as preformatted text."
  (interactive)
  (if (and (boundp 'transient-mark-mode) transient-mark-mode mark-active)
      (jira-markup-pre-region (region-beginning) (region-end))
    (insert "    ")))

(defun jira-markup-pre-region (beg end)
  "Format the region as preformatted text.
Arguments BEG and END specify the beginning and end of the region."
  (interactive "*r")
  (jira-markup-block-region beg end "    "))


;;; Indentation ====================================================================

(defun jira-markup-indent-find-next-position (cur-pos positions)
  "Return the position after the index of CUR-POS in POSITIONS."
  (while (and positions
              (not (equal cur-pos (car positions))))
    (setq positions (cdr positions)))
  (or (cadr positions) 0))

(defun jira-markup-indent-line ()
  "Indent the current line using some heuristics.
If the _previous_ command was either `jira-markup-enter-key' or
`jira-markup-cycle', then we should cycle to the next
reasonable indentation position.  Otherwise, we could have been
called directly by `jira-markup-enter-key', by an initial call of
`jira-markup-cycle', or indirectly by `auto-fill-mode'.  In
these cases, indent to the default position."
  (interactive)
  (let ((positions (jira-markup-calc-indents))
        (cur-pos (current-column)))
    (if (not (equal this-command 'jira-markup-cycle))
        (indent-line-to (car positions))
      (setq positions (sort (delete-dups positions) '<))
      (indent-line-to
       (jira-markup-indent-find-next-position cur-pos positions)))))

(defun jira-markup-calc-indents ()
  "Return a list of indentation columns to cycle through.
The first element in the returned list should be considered the
default indentation level."
  (let (pos prev-line-pos positions)

    ;; Previous line indent
    (setq prev-line-pos (jira-markup-prev-line-indent))
    (setq positions (cons prev-line-pos positions))

    ;; Previous non-list-marker indent
    (setq pos (jira-markup-prev-non-list-indent))
    (when pos
        (setq positions (cons pos positions))
        (setq positions (cons (+ pos tab-width) positions)))

    ;; Indentation of the previous line + tab-width
    (cond
     (prev-line-pos
      (setq positions (cons (+ prev-line-pos tab-width) positions)))
     (t
      (setq positions (cons tab-width positions))))

    ;; Indentation of the previous line - tab-width
    (if (and prev-line-pos
             (> prev-line-pos tab-width))
        (setq positions (cons (- prev-line-pos tab-width) positions)))

    ;; Indentation of preceeding list item
    (setq pos
          (save-excursion
            (forward-line -1)
            (catch 'break
              (while (not (equal (point) (point-min)))
                (forward-line -1)
                (goto-char (point-at-bol))
                (when (re-search-forward jira-markup-regex-list-indent (point-at-eol) t)
                  (throw 'break (length (match-string 1)))))
              nil)))
    (if (and pos (not (eq pos prev-line-pos)))
        (setq positions (cons pos positions)))

    ;; First column
    (setq positions (cons 0 positions))

    (reverse positions)))

(defun jira-markup-do-normal-return ()
  "Insert a newline and optionally indent the next line."
  (newline)
  (if jira-markup-indent-on-enter
      (funcall indent-line-function)))

(defun jira-markup-enter-key ()
  "Handle RET according to context.
If there is a wiki link at the point, follow it unless
`jira-markup-follow-wiki-link-on-enter' is nil.  Otherwise, process
it in the usual way."
  (interactive)
  (if (and jira-markup-follow-wiki-link-on-enter (jira-markup-wiki-link-p))
      (jira-markup-follow-wiki-link-at-point)
    (jira-markup-do-normal-return)))


;;; Keymap ====================================================================

(defvar jira-markup-mode-map
  (let ((map (make-keymap)))
    ;; Element insertion
    (define-key map "\C-c\C-al" 'jira-markup-insert-link)
    (define-key map "\C-c\C-ar" 'jira-markup-insert-reference-link-dwim)
    (define-key map "\C-c\C-aw" 'jira-markup-insert-wiki-link)
    (define-key map "\C-c\C-ii" 'jira-markup-insert-image)
    (define-key map "\C-c\C-t1" 'jira-markup-insert-header-1)
    (define-key map "\C-c\C-t2" 'jira-markup-insert-header-2)
    (define-key map "\C-c\C-t3" 'jira-markup-insert-header-3)
    (define-key map "\C-c\C-t4" 'jira-markup-insert-header-4)
    (define-key map "\C-c\C-t5" 'jira-markup-insert-header-5)
    (define-key map "\C-c\C-t6" 'jira-markup-insert-header-6)
    (define-key map "\C-c\C-pb" 'jira-markup-insert-bold)
    (define-key map "\C-c\C-ss" 'jira-markup-insert-bold)
    (define-key map "\C-c\C-pi" 'jira-markup-insert-italic)
    (define-key map "\C-c\C-se" 'jira-markup-insert-italic)
    (define-key map "\C-c\C-pf" 'jira-markup-insert-code)
    (define-key map "\C-c\C-sc" 'jira-markup-insert-code)
    (define-key map "\C-c\C-sb" 'jira-markup-insert-blockquote)
    (define-key map "\C-c\C-s\C-b" 'jira-markup-blockquote-region)
    (define-key map "\C-c\C-sp" 'jira-markup-insert-pre)
    (define-key map "\C-c\C-s\C-p" 'jira-markup-pre-region)
    (define-key map "\C-c-" 'jira-markup-insert-hr)
    (define-key map "\C-c\C-tt" 'jira-markup-insert-title)
    (define-key map "\C-c\C-ts" 'jira-markup-insert-section)
    ;; WikiLink Following
    (define-key map "\C-c\C-w" 'jira-markup-follow-wiki-link-at-point)
    (define-key map "\M-n" 'jira-markup-next-wiki-link)
    (define-key map "\M-p" 'jira-markup-previous-wiki-link)
    ;; Indentation
    (define-key map "\C-m" 'jira-markup-enter-key)
    ;; Header navigation
    (define-key map (kbd "C-M-n") 'outline-next-visible-heading)
    (define-key map (kbd "C-M-p") 'outline-previous-visible-heading)
    (define-key map (kbd "C-M-f") 'outline-forward-same-level)
    (define-key map (kbd "C-M-b") 'outline-backward-same-level)
    (define-key map (kbd "C-M-u") 'outline-up-heading)
    ;; Jira-Markup functions
    (define-key map "\C-c\C-cm" 'jira-markup)
    (define-key map "\C-c\C-cp" 'jira-markup-preview)
    (define-key map "\C-c\C-ce" 'jira-markup-export)
    (define-key map "\C-c\C-cv" 'jira-markup-export-and-view)
    ;; References
    (define-key map "\C-c\C-cc" 'jira-markup-check-refs)
    map)
  "Keymap for Jira-Markup major mode.")

;;; Menu ==================================================================

(easy-menu-define jira-markup-mode-menu jira-markup-mode-map
  "Menu for Jira-Markup mode"
  '("Jira"
    ("Headers"
     ["First level" jira-markup-insert-header-1]
     ["Second level" jira-markup-insert-header-2]
     ["Third level" jira-markup-insert-header-3]
     ["Fourth level" jira-markup-insert-header-4]
     ["Fifth level" jira-markup-insert-header-5]
     ["Sixth level" jira-markup-insert-header-6])
    "---"
    ["Bold" jira-markup-insert-bold]
    ["Italic" jira-markup-insert-italic]
    ["Blockquote" jira-markup-insert-blockquote]
    ["Preformatted" jira-markup-insert-pre]
    ["Code" jira-markup-insert-code]
    "---"
    ["Insert inline link" jira-markup-insert-link]
    ["Insert reference link" jira-markup-insert-reference-link-dwim]
    ["Insert image" jira-markup-insert-image]
    ["Insert horizontal rule" jira-markup-insert-hr]
    ["Check references" jira-markup-check-refs]
    "---"
    ["Version" jira-markup-show-version]
    ))


;;; WikiLink Following/Markup =================================================

(require 'thingatpt)

(defun jira-markup-wiki-link-p ()
  "Return non-nil when `point' is at a true wiki link.
A true wiki link name matches `jira-markup-regex-wiki-link' but does not
match the current file name after conversion.  This modifies the data
returned by `match-data'.  Note that the potential wiki link name must
be available via `match-string'."
  (let ((case-fold-search nil))
    (and (thing-at-point-looking-at jira-markup-regex-wiki-link)
	 (or (not buffer-file-name)
	     (not (string-equal (buffer-file-name)
				(jira-markup-convert-wiki-link-to-filename
                                 (jira-markup-wiki-link-link)))))
	 (not (save-match-data
		(save-excursion))))))

(defun jira-markup-wiki-link-link ()
  "Return the link part of the wiki link using current match data.
The location of the link component depends on the value of
`jira-markup-wiki-link-alias-first'."
  (if jira-markup-wiki-link-alias-first
      (or (match-string 3) (match-string 1))
    (match-string 1)))

(defun jira-markup-convert-wiki-link-to-filename (name)
  "Generate a filename from the wiki link NAME.
Spaces in NAME are replaced with `jira-markup-link-space-sub-char'.
When in `gfm-mode', follow GitHub's conventions where [[Test Test]]
and [[test test]] both map to Test-test.ext."
  (let ((basename (replace-regexp-in-string
                   "[[:space:]\n]" jira-markup-link-space-sub-char name)))
    (when (eq major-mode 'gfm-mode)
      (setq basename (concat (upcase (substring basename 0 1))
                             (downcase (substring basename 1 nil)))))
    (concat basename
            (if (buffer-file-name)
                (concat "."
                        (file-name-extension (buffer-file-name)))))))

(defun jira-markup-follow-wiki-link (name)
  "Follow the wiki link NAME.
Convert the name to a file name and call `find-file'.  Ensure that
the new buffer remains in `jira-markup-mode'."
  (let ((filename (jira-markup-convert-wiki-link-to-filename name)))
    (find-file filename))
  (jira-markup-mode))

(defun jira-markup-follow-wiki-link-at-point ()
  "Find Wiki Link at point.
See `jira-markup-wiki-link-p' and `jira-markup-follow-wiki-link'."
  (interactive)
  (if (jira-markup-wiki-link-p)
      (jira-markup-follow-wiki-link (jira-markup-wiki-link-link))
    (error "Point is not at a Wiki Link")))

(defun jira-markup-next-wiki-link ()
  "Jump to next wiki link.
See `jira-markup-wiki-link-p'."
  (interactive)
  (if (jira-markup-wiki-link-p)
      ; At a wiki link already, move past it.
      (goto-char (+ 1 (match-end 0))))
  (save-match-data
    ; Search for the next wiki link and move to the beginning.
    (re-search-forward jira-markup-regex-wiki-link nil t)
    (goto-char (match-beginning 0))))

(defun jira-markup-previous-wiki-link ()
  "Jump to previous wiki link.
See `jira-markup-wiki-link-p'."
  (interactive)
  (re-search-backward jira-markup-regex-wiki-link nil t))

(defun jira-markup-highlight-wiki-link (from to face)
  "Highlight the wiki link in the region between FROM and TO using FACE."
  (put-text-property from to 'font-lock-face face))

(defun jira-markup-unfontify-region-wiki-links (from to)
  "Remove wiki link faces from the region specified by FROM and TO."
  (interactive "nfrom: \nnto: ")
  (remove-text-properties from to '(font-lock-face jira-markup-link-face))
  (remove-text-properties from to '(font-lock-face jira-markup-missing-link-face)))

(defun jira-markup-fontify-region-wiki-links (from to)
  "Search region given by FROM and TO for wiki links and fontify them.
If a wiki link is found check to see if the backing file exists
and highlight accordingly."
  (goto-char from)
  (while (re-search-forward jira-markup-regex-wiki-link to t)
    (let ((highlight-beginning (match-beginning 0))
	  (highlight-end (match-end 0))
	  (file-name
	   (jira-markup-convert-wiki-link-to-filename
            (jira-markup-wiki-link-link))))
      (if (file-exists-p file-name)
	  (jira-markup-highlight-wiki-link
	   highlight-beginning highlight-end jira-markup-link-face)
	(jira-markup-highlight-wiki-link
	 highlight-beginning highlight-end jira-markup-missing-link-face)))))

(defun jira-markup-extend-changed-region (from to)
  "Extend region given by FROM and TO so that we can fontify all links.
The region is extended to the first newline before and the first
newline after."
  ;; start looking for the first new line before 'from
  (goto-char from)
  (re-search-backward "\n" nil t)
  (let ((new-from (point-min))
	(new-to (point-max)))
    (if (not (= (point) from))
	(setq new-from (point)))
    ;; do the same thing for the first new line after 'to
    (goto-char to)
    (re-search-forward "\n" nil t)
    (if (not (= (point) to))
	(setq new-to (point)))
    (list new-from new-to)))

(defun jira-markup-check-change-for-wiki-link (from to change)
  "Check region between FROM and TO for wiki links and re-fontfy as needed.
Designed to be used with the `after-change-functions' hook.
CHANGE is the number of bytes of pre-change text replaced by the
given range."
  (interactive "nfrom: \nnto: \nnchange: ")
  (let* ((inhibit-quit t)
	 (modified (buffer-modified-p))
	 (buffer-undo-list t)
	 (inhibit-read-only t)
	 (inhibit-point-motion-hooks t)
	 (inhibit-modification-hooks t)
	 (current-point (point))
	 deactivate-mark)
    (unwind-protect
        (save-match-data
          (save-restriction
            ;; Extend the region to fontify so that it starts
            ;; and ends at safe places.
            (multiple-value-bind (new-from new-to)
                (jira-markup-extend-changed-region from to)
              ;; Unfontify existing fontification (start from scratch)
              (jira-markup-unfontify-region-wiki-links new-from new-to)
              ;; Now do the fontification.
              (jira-markup-fontify-region-wiki-links new-from new-to)))
          (unless modified
            (if (fboundp 'restore-buffer-modified-p)
                (restore-buffer-modified-p nil)
              (set-buffer-modified-p nil))))
      (goto-char current-point))))

(defun jira-markup-fontify-buffer-wiki-links ()
  "Refontify all wiki links in the buffer."
  (interactive)
  (jira-markup-check-change-for-wiki-link (point-min) (point-max) 0))

;;; Miscellaneous =============================================================

(defun jira-markup-line-number-at-pos (&optional pos)
  "Return (narrowed) buffer line number at position POS.
If POS is nil, use current buffer location.
This is an exact copy of `line-number-at-pos' for use in emacs21."
  (let ((opoint (or pos (point))) start)
    (save-excursion
      (goto-char (point-min))
      (setq start (point))
      (goto-char opoint)
      (forward-line 0)
      (1+ (count-lines start (point))))))

(defun jira-markup-nobreak-p ()
  "Return nil if it is acceptable to break the current line at the point."
  ;; inside in square brackets (e.g., link anchor text)
  (looking-back "\\[[^]]*"))



;;; Mode definition  ==========================================================

(defun jira-markup-show-version ()
  "Show the version number in the minibuffer."
  (interactive)
  (message "jira-markup-mode, version %s" jira-markup-mode-version))

;;;###autoload
(define-derived-mode jira-markup-mode text-mode "Jira-Markup"
  "Major mode for editing Jira-Markup files."
  ;; Natural Jira-Markup tab width
  (setq tab-width 4)
  ;; Comments
  (set (make-local-variable 'comment-start) "<!-- ")
  (set (make-local-variable 'comment-end) " -->")
  (set (make-local-variable 'comment-start-skip) "<!--[ \t]*")
  (set (make-local-variable 'comment-column) 0)
  ;; Font lock.
  (set (make-local-variable 'font-lock-defaults)
       '(jira-markup-mode-font-lock-keywords))
  (set (make-local-variable 'font-lock-multiline) t)
  ;; For menu support in XEmacs
  (easy-menu-add jira-markup-mode-menu jira-markup-mode-map)
  ;; Make filling work with lists (unordered, ordered, and definition)
  (set (make-local-variable 'paragraph-start)
       "\f\\|[ \t]*$\\|^[ \t]*[*+-] \\|^[ \t]*[0-9]+\\.\\|^[ \t]*: ")
  ;; Outline mode
  (set (make-local-variable 'outline-regexp) jira-markup-regex-header)
  (set (make-local-variable 'outline-level) 'jira-markup-outline-level)
  ;; Cause use of ellipses for invisible text.
  (add-to-invisibility-spec '(outline . t))
  ;; Indentation and filling
  (make-local-variable 'fill-nobreak-predicate)
  (add-hook 'fill-nobreak-predicate 'jira-markup-nobreak-p)
  (setq indent-line-function jira-markup-indent-function)

  ;; Prepare hooks for XEmacs compatibility
  (when (featurep 'xemacs)
      (make-local-hook 'after-change-functions)
      (make-local-hook 'font-lock-extend-region-functions)
      (make-local-hook 'window-configuration-change-hook))

  ;; Multiline font lock
  (add-hook 'font-lock-extend-region-functions
            'jira-markup-font-lock-extend-region)

  ;; Anytime text changes make sure it gets fontified correctly
  (add-hook 'after-change-functions 'jira-markup-check-change-for-wiki-link t t)

  ;; If we left the buffer there is a really good chance we were
  ;; creating one of the wiki link documents. Make sure we get
  ;; refontified when we come back.
  (add-hook 'window-configuration-change-hook
	    'jira-markup-fontify-buffer-wiki-links t t)

  ;; do the initial link fontification
  (jira-markup-fontify-buffer-wiki-links))

;; (add-to-list 'auto-mode-alist '("\\.confluence$" . jira-markup-mode))
;; (add-to-list 'auto-mode-alist '("/itsalltext/.*jira.*\\.txt$" . jira-markup-mode))

(provide 'jira-markup-mode)

;;; jira-markup-mode.el ends here
