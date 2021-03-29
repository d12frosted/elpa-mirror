;;; thumb-through.el --- Plain text reader of HTML documents

;; Copyright (C) 2010 Andrew Gwozdziewycz <git@apgwoz.com>

;; Markdown style formatting
;; Copyright (C) 2007, 2008, 2009 Jason Blevins

;; Version: 0.3
;; Package-Version: 20120119.534
;; Package-Commit: 08d8fb720f93c6172653e035191a8fa9c3305e63
;; Keywords: html

;; This file is NOT part of GNU Emacs

;; This is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 3, or (at your option) any later
;; version.

;; This is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Installation

;; requires curl
;; requires http://www.aaronsw.com/2002/html2text/html2text.py
;; edit thumb-through-html2text-command to be the location of html2text

(require 'thingatpt)
(require 'font-lock)

(defconst thumb-through-curl-executable (executable-find "curl"))
(defconst thumb-through-service-url
  "http://textplease.appspot.com/text/extract.md?url=")

(defvar thumb-through-italic-face 'thumb-through-italic-face
  "Face name to use for italic text.")

(defvar thumb-through-bold-face 'thumb-through-bold-face
  "Face name to use for bold text.")

(defvar thumb-through-header-face 'thumb-through-header-face
  "Face name to use as a base for headers.")

(defvar thumb-through-header-face-1 'thumb-through-header-face-1
  "Face name to use for level-1 headers.")

(defvar thumb-through-header-face-2 'thumb-through-header-face-2
  "Face name to use for level-2 headers.")

(defvar thumb-through-header-face-3 'thumb-through-header-face-3
  "Face name to use for level-3 headers.")

(defvar thumb-through-header-face-4 'thumb-through-header-face-4
  "Face name to use for level-4 headers.")

(defvar thumb-through-header-face-5 'thumb-through-header-face-5
  "Face name to use for level-5 headers.")

(defvar thumb-through-header-face-6 'thumb-through-header-face-6
  "Face name to use for level-6 headers.")

(defvar thumb-through-inline-code-face 'thumb-through-inline-code-face
  "Face name to use for inline code.")

(defvar thumb-through-list-face 'thumb-through-list-face
  "Face name to use for list markers.")

(defvar thumb-through-blockquote-face 'thumb-through-blockquote-face
  "Face name to use for blockquote.")

(defvar thumb-through-pre-face 'thumb-through-pre-face
  "Face name to use for preformatted text.")

(defvar thumb-through-link-face 'thumb-through-link-face
  "Face name to use for links.")

(defvar thumb-through-reference-face 'thumb-through-reference-face
  "Face name to use for reference.")

(defvar thumb-through-url-face 'thumb-through-url-face
  "Face name to use for URLs.")

(defvar thumb-through-link-title-face 'thumb-through-link-title-face
  "Face name to use for reference link titles.")

(defvar thumb-through-comment-face 'thumb-through-comment-face
  "Face name to use for HTML comments.")

(defvar thumb-through-math-face 'thumb-through-math-face
  "Face name to use for LaTeX expressions.")

(defcustom thumb-through-uri-types
  '("acap" "cid" "data" "dav" "fax" "file" "ftp" "gopher" "http" "https"
    "imap" "ldap" "mailto" "mid" "modem" "news" "nfs" "nntp" "pop" "prospero"
    "rtsp" "service" "sip" "tel" "telnet" "tip" "urn" "vemmi" "wais")
  "Link types for syntax highlighting of URIs."
  :group 'thumb-through
  :type 'list)

(defgroup thumb-through-faces nil
  "Faces used in Thumb Through Mode"
  :group 'thumb-through
  :group 'faces)

(defface thumb-through-italic-face
  '((t :inherit font-lock-variable-name-face :italic t))
  "Face for italic text."
  :group 'thumb-through-faces)

(defface thumb-through-bold-face
  '((t :inherit font-lock-variable-name-face :bold t))
  "Face for bold text."
  :group 'thumb-through-faces)

(defface thumb-through-header-face
  '((t :inherit font-lock-function-name-face :weight bold))
  "Base face for headers."
  :group 'thumb-through-faces)

(defface thumb-through-header-face-1
  '((t :inherit thumb-through-header-face :height 1.4))
  "Face for level-1 headers."
  :group 'thumb-through-faces)

(defface thumb-through-header-face-2
  '((t :inherit thumb-through-header-face :height 1.25))
  "Face for level-2 headers."
  :group 'thumb-through-faces)

(defface thumb-through-header-face-3
  '((t :inherit thumb-through-header-face :height 1.1))
  "Face for level-3 headers."
  :group 'thumb-through-faces)

(defface thumb-through-header-face-4
  '((t :inherit thumb-through-header-face :height 1.0))
  "Face for level-4 headers."
  :group 'thumb-through-faces)

(defface thumb-through-header-face-5
  '((t :inherit thumb-through-header-face :height .9))
  "Face for level-5 headers."
  :group 'thumb-through-faces)

(defface thumb-through-header-face-6
  '((t :inherit thumb-through-header-face :height .8))
  "Face for level-6 headers."
  :group 'thumb-through-faces)

(defface thumb-through-inline-code-face
  '((t :inherit font-lock-constant-face))
  "Face for inline code."
  :group 'thumb-through-faces)

(defface thumb-through-list-face
  '((t :inherit font-lock-builtin-face))
  "Face for list item markers."
  :group 'thumb-through-faces)

(defface thumb-through-blockquote-face
  '((t :inherit font-lock-doc-face))
  "Face for blockquote sections."
  :group 'thumb-through-faces)

(defface thumb-through-pre-face
  '((t :inherit font-lock-constant-face))
  "Face for preformatted text."
  :group 'thumb-through-faces)

(defface thumb-through-link-face
  '((t :inherit font-lock-keyword-face))
  "Face for links."
  :group 'thumb-through-faces)

(defface thumb-through-reference-face
  '((t :inherit font-lock-type-face))
  "Face for link references."
  :group 'thumb-through-faces)

(defface thumb-through-url-face
  '((t :inherit font-lock-string-face))
  "Face for URLs."
  :group 'thumb-through-faces)

(defface thumb-through-link-title-face
  '((t :inherit font-lock-comment-face))
  "Face for reference link titles."
  :group 'thumb-through-faces)

(defface thumb-through-comment-face
  '((t :inherit font-lock-comment-face))
  "Face for HTML comments."
  :group 'thumb-through-faces)

(defface thumb-through-math-face
  '((t :inherit font-lock-string-face))
  "Face for LaTeX expressions."
  :group 'thumb-through-faces)

(defconst thumb-through-regex-link-inline
  "\\(!?\\[[^]]*?\\]\\)\\(([^\\)]*)\\)"
  "Regular expression for a [text](file) or an image link ![text](file).")

(defconst thumb-through-regex-link-reference
  "\\(!?\\[[^]]+?\\]\\)[ ]?\\(\\[[^]]*?\\]\\)"
  "Regular expression for a reference link [text][id].")

(defconst thumb-through-regex-reference-definition
  "^ \\{0,3\\}\\(\\[.+?\\]\\):\\s *\\(.*?\\)\\s *\\( \"[^\"]*\"$\\|$\\)"
  "Regular expression for a link definition [id]: ...")

(defconst thumb-through-regex-header-1-atx
  "^\\(# \\)\\(.*?\\)\\($\\| #+$\\)"
  "Regular expression for level 1 atx-style (hash mark) headers.")

(defconst thumb-through-regex-header-2-atx
  "^\\(## \\)\\(.*?\\)\\($\\| #+$\\)"
  "Regular expression for level 2 atx-style (hash mark) headers.")

(defconst thumb-through-regex-header-3-atx
  "^\\(### \\)\\(.*?\\)\\($\\| #+$\\)"
  "Regular expression for level 3 atx-style (hash mark) headers.")

(defconst thumb-through-regex-header-4-atx
  "^\\(#### \\)\\(.*?\\)\\($\\| #+$\\)"
  "Regular expression for level 4 atx-style (hash mark) headers.")

(defconst thumb-through-regex-header-5-atx
  "^\\(##### \\)\\(.*?\\)\\($\\| #+$\\)"
  "Regular expression for level 5 atx-style (hash mark) headers.")

(defconst thumb-through-regex-header-6-atx
  "^\\(###### \\)\\(.*?\\)\\($\\| #+$\\)"
  "Regular expression for level 6 atx-style (hash mark) headers.")

(defconst thumb-through-regex-header-1-setext
  "^\\(.*\\)\n\\(===+\\)$"
  "Regular expression for level 1 setext-style (underline) headers.")

(defconst thumb-through-regex-header-2-setext
  "^\\(.*\\)\n\\(---+\\)$"
  "Regular expression for level 2 setext-style (underline) headers.")

(defconst thumb-through-regex-hr
  "^\\(\\*[ ]?\\*[ ]?\\*[ ]?[\\* ]*\\|-[ ]?-[ ]?-[--- ]*\\)$"
  "Regular expression for matching Markdown horizontal rules.")

(defconst thumb-through-regex-code
  "\\(^\\|[^\\]\\)\\(\\(`\\{1,2\\}\\)\\([^ \\]\\|[^ ].*?[^ \\]\\)\\3\\)"
  "Regular expression for matching inline code fragments.")

(defconst thumb-through-regex-pre
  "^\\(    \\|\t\\).*$"
  "Regular expression for matching preformatted text sections.")

(defconst thumb-through-regex-list
  "^[ \t]*\\([0-9]+\\.\\|[\\*\\+-]\\) "
  "Regular expression for matching list markers.")

(defconst thumb-through-regex-bold
  "\\(^\\|[^\\]\\)\\(\\([*_]\\{2\\}\\)\\(.\\|\n\\)*?[^\\ ]\\3\\)"
  "Regular expression for matching bold text.")

(defconst thumb-through-regex-italic
  "\\(^\\|[^\\]\\)\\(\\([*_]\\)\\([^ \\]\\3\\|[^ ]\\(.\\|\n\\)*?[^\\ ]\\3\\)\\)"
  "Regular expression for matching italic text.")

(defconst thumb-through-regex-blockquote
  "^>.*$"
  "Regular expression for matching blockquote lines.")

(defconst thumb-through-regex-line-break
  "  $"
  "Regular expression for matching line breaks.")

(defconst thumb-through-regex-wiki-link
  "\\[\\[[^]]+\\]\\]"
  "Regular expression for matching wiki links.")

(defconst thumb-through-regex-uri
  (concat
   "\\(" (mapconcat 'identity thumb-through-uri-types "\\|")
   "\\):[^]\t\n\r<>,;() ]+")
  "Regular expression for matching inline URIs.")

(defvar thumb-through-mode-font-lock-keywords
  `((,thumb-through-regex-code
     (2 '(face thumb-through-inline-code-face)))
    (,thumb-through-regex-pre . 'thumb-through-pre-face)
    (,thumb-through-regex-blockquote . 'thumb-through-blockquote-face)
    (,thumb-through-regex-header-1-setext . 'thumb-through-header-face-1)
    (,thumb-through-regex-header-2-setext . 'thumb-through-header-face-2)
    (,thumb-through-regex-header-1-atx
     (1 '(face nil invisible t))
     (2 '(face thumb-through-header-face-1))
     (3 '(face nil invisible t)))
    (,thumb-through-regex-header-2-atx
     (1 '(face nil invisible t))
     (2 '(face thumb-through-header-face-2))
     (3 '(face nil invisible t)))
    (,thumb-through-regex-header-3-atx
     (1 '(face nil invisible t))
     (2 '(face thumb-through-header-face-3))
     (3 '(face nil invisible t)))
    (,thumb-through-regex-header-4-atx
     (1 '(face nil invisible t))
     (2 '(face thumb-through-header-face-4))
     (3 '(face nil invisible t)))
    (,thumb-through-regex-header-5-atx
     (1 '(face nil invisible t))
     (2 '(face thumb-through-header-face-5))
     (3 '(face nil invisible t)))
    (,thumb-through-regex-header-6-atx
     (1 '(face nil invisible t))
     (2 '(face thumb-through-header-face-6))
     (3 '(face nil invisible t)))
    (,thumb-through-regex-hr 'thumb-through-header-face)
    (,thumb-through-regex-list 'thumb-through-list-face)
    (,thumb-through-regex-link-inline
     '((1 '(face thumb-through-link-face))
       (2 '(face thumb-through-url-face))))
    (,thumb-through-regex-link-reference
     (1 '(face thumb-through-link-face) )
     (2 '(face thumb-through-reference-face)))
    (,thumb-through-regex-reference-definition
     (1 '(face thumb-through-reference-face))
     (2 '(face thumb-through-url-face) )
     (3 '(face thumb-through-link-title-face)))
    (,thumb-through-regex-wiki-link . 'thumb-through-link-face)
    (,thumb-through-regex-bold
     (2 '(face thumb-through-bold-face)))
    (,thumb-through-regex-italic
     (2 '(face thumb-through-italic-face)))))


(defvar thumb-through-mode-syntax-table
  (let ((thumb-through-mode-syntax-table (make-syntax-table)))
    (modify-syntax-entry ?\" "w" thumb-through-mode-syntax-table)
    thumb-through-mode-syntax-table))

(defun thumb-through-get-url ()
  (if current-prefix-arg
      (read-string "URL: ")
    (or (thing-at-point 'url) (read-string "URL: "))))

(defun thumb-through-get-page (url)
  "Returns an XML version of the URL or nil on any sort of failure"
  ;; need to validate this as a url
  (let ((command (concat thumb-through-curl-executable " "
                         (concat thumb-through-service-url
                                 (url-hexify-string url))
                         " 2> /dev/null")))
    (shell-command-to-string command)))

(defun thumb-through (&optional url)
  (interactive)
  (let ((url (or url (thumb-through-get-url))))
    (if url
        (with-current-buffer (get-buffer-create "*thumb-through-output*")
          (let ((contents (thumb-through-get-page url)))
            (setq buffer-read-only nil)
            (kill-region (point-min) (point-max))
            (insert contents)
            (switch-to-buffer (current-buffer))
            (thumb-through-mode)
            (goto-line 1)
            (setq buffer-read-only t)))
      (message "No url found."))))

(defun thumb-through-region (begin end)
  (interactive "r")
  (thumb-through (buffer-substring begin end)))

(define-derived-mode thumb-through-mode text-mode "thumb through"
  (set (make-local-variable 'font-lock-defaults)
       '(thumb-through-mode-font-lock-keywords))
  (set (make-local-variable 'font-lock-multiline) t))

(provide 'thumb-through)
;;; thumb-through.el ends here
