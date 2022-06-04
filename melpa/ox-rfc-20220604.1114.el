;;; ox-rfc.el --- RFC Back-End for Org Export Engine -*- lexical-binding: t -*-

;; Copyright (C) 2019 Christian E. Hopps

;; Author: Christian Hopps <chopps@devhopps.com>
;; URL: https://github.com/choppsv1/org-rfc-export
;; Package-Commit: f0fe3503f8732ea5e95a4016c6b7ce5b47cf6295
;; Package-Version: 20220604.1114
;; Package-X-Original-Version: 1
;; Package-Requires: ((emacs "24.3") (org "8.3"))
;; Keywords: org, rfc, wp, xml

;;; License

:; This program is free software: you can redistribute it and/or modify
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

;; This library implements an RFC (xml2rfc) export back-end for Org. It
;; exports into XML as defined in RFC7749 (v2) and RFC7991 (v3), and can
;; also use `xml2rfc` directly to further convert to HTML, PDF and TXT.
;; See Org manual for more information. See README.org
;; (https://github.com/choppsv1/org-rfc-export/blob/master/README.org)
;; for basic documentation on use.

;;;; Credits:

;; Started with ox-md.el by Nicolas Goaziou as a template also used code from
;; ox-html.el by Carsten Dominik and Jambunathan K.

;;; Code:

(require 'ox)
(require 'url-parse)
(require 'ox-ascii)
(require 'subr-x)


;;; User-Configurable Variables

(defgroup org-export-rfc nil
  "Options specific to RFC export back-end."
  :tag "Org Export RFC"
  :group 'org-export)

(defcustom ox-rfc-file-name-version nil
  "If non-nil generated files include the I-D version number suffix"
  :type 'boolean
  :group 'org-export-rfc)

(defcustom ox-rfc-ref-cache-directory (expand-file-name (concat temporary-file-directory ".ox-rfc-ref-cache/"))
  "Local directory to store downloaded IETF references. Created if necessary."
  :type 'directory
  :group 'org-export-rfc)

(defcustom ox-rfc-ref-draft-url-directory "http://xml2rfc.ietf.org/public/rfc/bibxml-ids/"
  "The base URL to fetch IETF drafts references from."
  :type 'string
  :group 'org-export-rfc)

(defcustom ox-rfc-ref-3gpp-url-directory "http://xml2rfc.ietf.org/public/rfc/bibxml-3gpp/"
  "The base URL to fetch IEEE references from."
  :type 'string
  :group 'org-export-rfc)

(defcustom ox-rfc-ref-ieee-url-directory "http://xml2rfc.ietf.org/public/rfc/bibxml-ieee/"
  "The base URL to fetch IEEE references from."
  :type 'string
  :group 'org-export-rfc)

(defcustom ox-rfc-ref-misc-url-directory "http://xml2rfc.ietf.org/public/rfc/bibxml-misc/"
  "The base URL to fetch IEEE references from."
  :type 'string
  :group 'org-export-rfc)

(defcustom ox-rfc-ref-rfc-url-directory  "http://www.rfc-editor.org/refs/bibxml/"
  "The base URL to fetch IETF RFCs references from."
  :type 'string
  :group 'org-export-rfc)

(defcustom ox-rfc-ref-w3c-url-directory "http://xml2rfc.ietf.org/public/rfc/bibxml-w3c/"
  "The base URL to fetch IEEE references from."
  :type 'string
  :group 'org-export-rfc)

(defcustom ox-rfc-ref-xsf-url-directory "http://www.xmpp.org/extensions/refs/"
  "The base URL to fetch IEEE references from."
  :type 'string
  :group 'org-export-rfc)

(defcustom ox-rfc-tidy-args "-q -wrap 0 -indent -xml"
  "The default arguments to pass to tidy for cleaning up XML"
  :type 'string
  :group 'org-export-rfc)

(defcustom ox-rfc-tidy-cmd "tidy"
  "The name of the tidy binary if nil will lookup"
  :type 'string
  :group 'org-export-rfc)

(defcustom ox-rfc-try-tidy nil
  "If non-nil try and use tidy to cleanup generated XML"
  :type 'boolean
  :group 'org-export-rfc)

(defcustom ox-rfc-xml-version 3
  "If non-nil try and use tidy to cleanup generated XML"
  :type 'int
  :group 'org-export-rfc)

(defconst ox-rfc-revision-regex "\\<revision[ \t]+\\([0-9]\\{4\\}-[0-9]\\{2\\}-[0-9]\\{2\\}\\)[\n\t ]*")


;;; Define Back-End

(org-export-define-backend 'rfc
  '((bold . ox-rfc-bold)
    (code . ox-rfc-verbatim)
    (center-block . ox-rfc-center-block)
    ;; (entity . ox-rfc-entity) ; What's this.
    (dynamic-block . ox-rfc-dynamic-block)
    (example-block . ox-rfc-example-block)
    (export-block . ox-rfc-export-block)
    (fixed-width . ox-rfc-example-block)
    (headline . ox-rfc-headline)
    (inline-src-block . ox-rfc-verbatim)
    (inner-template . ox-rfc-inner-template)
    (italic . ox-rfc-italic)
    (item . ox-rfc-item)
    (line-break . ox-rfc-line-break)
    (link . ox-rfc-link)
    (node-property . ox-rfc-node-property) ; What's this.
    (paragraph . ox-rfc-paragraph)
    (plain-list . ox-rfc-plain-list)
    (plain-text . ox-rfc-plain-text)
    (quote-block . ox-rfc-quote-block)
    (section . ox-rfc-section)
    (special-block . ox-rfc-special-block)
    (src-block . ox-rfc-src-block)
    (subscript . ox-rfc-subscript)
    (superscript . ox-rfc-superscript)
    (table . ox-rfc-table)
    (table-cell . ox-rfc-table-cell)
    (table-row . ox-rfc-table-row)
    (template . ox-rfc-template)
    ;; (underline . ox-rfc-underline) ; Not supported by xml2rfc.
    (verbatim . ox-rfc-verbatim)
    )
  :menu-entry
  '(?r "Export to RFC"
       ((?X "To XML temporary buffer"
	    (lambda (a s v b) (ox-rfc-export-as-xml a s v)))
	(?x "To XML file" (lambda (a s v b) (ox-rfc-export-to-xml a s v)))
        (?H "To HTML file and open."
            (lambda (a s v b) (if a
                                  (ox-rfc-export-to-html t s v)
                                (org-open-file (ox-rfc-export-to-html nil s v)))))
        ;; (?H "To HTML file" (lambda (a s v b) (ox-rfc-export-to-html a s v)))
        (?P "To PDF file and open."
            (lambda (a s v b) (if a
                                  (ox-rfc-export-to-pdf t s v)
                                (org-open-file (ox-rfc-export-to-pdf nil s v)))))
        ;; (?p "To PDF file" (lambda (a s v b) (ox-rfc-export-to-pdf a s v)))
        (?T "To TEXT temporary buffer" (lambda (a s v b) (ox-rfc-export-as-text a s v)))
        ;; (?t "To TEXT file" (lambda (a s v b) (ox-rfc-export-to-text a s v)))
	(?o "To TEXT file and open"
            (lambda (a s v b)
	      (if a
                  (ox-rfc-export-to-text t s v)
                (org-open-file (ox-rfc-export-to-text nil s v)))))))
  :options-alist
  '((:affiliation "AFFILIATION" nil nil t)
    (:author "AUTHOR" nil nil t)
    (:editor "EDITOR" nil nil t)
    (:email "EMAIL" nil nil t)
    (:rfc-file-name-version nil "fnv" ox-rfc-file-name-version t)
    (:rfc-add-author "RFC_ADD_AUTHOR" nil nil newline)
    (:rfc-ascii-table "RFC_ASCII_TABLE" nil nil t)
    (:rfc-category "RFC_CATEGORY" nil "std" t)
    (:rfc-consensus "RFC_CONSENSUS" nil "true" t)
    (:rfc-ipr "RFC_IPR" nil "trust200902" t)
    (:rfc-name "RFC_NAME" nil nil t)
    (:rfc-obsoletes "RFC_OBSOLETES" nil nil space)
    (:rfc-short-title "RFC_SHORT_TITLE" nil nil t)
    (:rfc-stream "RFC_STREAM" nil "IETF" t)
    (:rfc-updates "RFC_UPDATES" nil nil space)
    (:rfc-version "RFC_VERSION" nil "00" t)
    (:rfc-xml-version "RFC_XML_VERSION" nil nil t)
    ;; We define these to allow us to use org-ascii-table
    ;; for XML version 2 multi-header-row 2 formatting.
    (:ascii-global-margin nil nil org-ascii-global-margin)
    (:ascii-quote-margin nil nil org-ascii-quote-margin)
    (:ascii-inner-margin nil nil org-ascii-inner-margin)
    (:ascii-list-margin nil nil org-ascii-list-margin)
    (:ascii-table-keep-all-vertical-lines
     nil nil org-ascii-table-keep-all-vertical-lines)
    (:ascii-table-use-ascii-art nil nil org-ascii-table-use-ascii-art)
    (:ascii-table-widen-columns nil nil org-ascii-table-widen-columns)
    (:ascii-text-width nil nil org-ascii-text-width)
    ))


;;; Utility Functions

;; Babel helpers so we can inject non-programming "code" blocks
;; into other blocks as variable input.

(defun org-babel-execute:json (body _params)
  "Run a block with YANG XML through pyang.
This function is called by `org-babel-execute-src-block'."
  body)

(defun org-babel-execute:xml (body _params)
  "Run a block with YANG XML through pyang.
This function is called by `org-babel-execute-src-block'."
  body)

(defun ox-rfc--get-justification (element)
  "Return expected justification for ELEMENT's contents.
Return value is a symbol among `left', `center', `right' and
`full'."
  (org-ascii--current-justification element))

(defun ox-rfc--headline-to-anchor (headline)
  "Given HEADLINE return value suitable for an anchor"
  (concat "sec-" (replace-regexp-in-string "[^[:alnum:]]+" "-" (downcase headline))))

(defun ox-rfc--replace-yang-module-revision (body)
  "Get yang module name from body"
  (if (not body)
      body
    (save-match-data
      (replace-regexp-in-string ox-rfc-revision-regex
                                (format-time-string "%Y-%m-%d") body nil nil 1))))

(defun ox-rfc--get-yang-module-file-name (body)
  "Get yang module name from body"
  (save-match-data
    (if (not (string-match "\\<module[ \t]+\\([^{]*\\)[\n\t ]*{" body))
        nil
      (org-trim (match-string 1 body)))))

(defun ox-rfc--get-yang-module-revision (body)
  "Get yang module name from body"
  (save-match-data
    (if (not (string-match ox-rfc-revision-regex body))
        nil
      (org-trim (match-string 1 body)))))

(defun org-babel-execute:yang (body params)
  "Run a block with YANG XML through pyang.
This function is called by `org-babel-execute-src-block'."
  (let ((cmd (or (cdr (assoc :cmd params)) "pyang"))
        (cmdline (or (cdr (assoc :cmdline params)) "--keep-comments -Werror -f yang"))
        content)
    (setq content (org-babel-eval (concat cmd " " cmdline) body))
    (if (not content)
        (let ((err-str "*no stderr output from pyang*")
              (err-buf (get-buffer org-babel-error-buffer-name)))
          (when err-buf
            (with-current-buffer err-buf
              (setq err-str (buffer-string))))
          (error "Error: from pyang: %s" err-str))
      (ox-rfc--replace-yang-module-revision (org-babel-eval (concat cmd " " cmdline) body)))))

(defun ox-rfc-url-ref-fetch-to-cache (url &optional reload)
  (let* ((fname (file-name-nondirectory (url-filename (url-generic-parse-url url))))
         (pathname (concat (file-name-as-directory ox-rfc-ref-cache-directory) fname)))
    (unless (and (file-exists-p pathname) (not reload))
      (make-directory ox-rfc-ref-cache-directory t)
      (url-copy-file url pathname t))
    pathname))

(defun ox-rfc-std--root (ref)
  "Return the root of the filename for REF."
  (cond
   ((and (string-prefix-p "RFC" ref) (not (string-prefix-p "RFC." ref)))
    (concat "RFC." (substring ref 3)))
   ((and (string-prefix-p "IEEE" ref) (not (string-prefix-p "IEEE." ref)))
    (concat "IEEE." (substring ref 4)))
   ((and (string-prefix-p "SDO-3GPP" ref) (not (string-prefix-p "SDO-3GPP." ref)))
    (concat "3GPP." (substring ref 8)))
   ((string-prefix-p "SDO-3GPP." ref)
    (concat "3GPP." (substring ref 9)))
   ((and (string-prefix-p "3GPP" ref) (not (string-prefix-p "3GPP." ref)))
    (concat "3GPP." (substring ref 4)))
   ((and (string-prefix-p "XSF.XEP" ref) (not (string-prefix-p "XSF.XEP-" ref)))
    (concat "XSF.XEP-" (substring ref 7)))
   ((string-prefix-p "XSF-XEP-" ref)
    (concat "XSF.XEP-" (substring ref 8)))
   ((string-prefix-p "XSF-XEP" ref)
    (concat "XSF.XEP-" (substring ref 7)))
   ((string-prefix-p "XEP-" ref)
    (concat "XSF.XEP-" (substring ref 4)))
   ((string-prefix-p "XEP" ref)
    (concat "XSF.XEP-" (substring ref 3)))
   (t ref)))

(defun ox-rfc-std--basename (ref)
  "Return the basename of the filename for REF."
  (concat "reference." (ox-rfc-std--root ref) ".xml"))

(defun ox-rfc-std--url-dir (ref)
  "Return the base filename for a URL to fetch REF."
  (let* ((prefix (substring ref 0 3))
         (x '(("RFC" . ox-rfc-ref-rfc-url-directory)
              ("I-D" . ox-rfc-ref-draft-url-directory)
              ("IEE" . ox-rfc-ref-ieee-url-directory)
              ("W3C" . ox-rfc-ref-w3c-url-directory)
              ("SDO" . ox-rfc-ref-3gpp-url-directory)
              ("3GP" . ox-rfc-ref-3gpp-url-directory)
              ("XEP" . ox-rfc-ref-xsf-url-directory)
              ("XSF" . ox-rfc-ref-xsf-url-directory)
              ))
         (dirsym (or (cdr (assoc-string prefix x)) 'ox-rfc-ref-misc-url-directory)))
    (file-name-as-directory (symbol-value dirsym))))

(defun ox-rfc-std--url (ref)
  (concat (ox-rfc-std--url-dir ref) (ox-rfc-std--basename ref)))

(defun ox-rfc-std--cache-name (ref)
  (concat (file-name-as-directory ox-rfc-ref-cache-directory) (ox-rfc-std--basename ref)))

(defun ox-rfc-std-ref-fetch-to-cache (ref &optional reload)
  "Fetch the bibliography xml.
The document is identified by BASENAME. If RELOAD is specified
then the cache is overwritten."
  (let* ((pathname (ox-rfc-std--cache-name ref)))
    (unless (and (file-exists-p pathname) (not reload))
      (make-directory ox-rfc-ref-cache-directory t)
      (url-copy-file (ox-rfc-std--url ref) pathname t))
    pathname))

(defun ox-rfc-get-tidy ()
  "Return tidy command if we should use else nil."
  (if (not ox-rfc-try-tidy)
      nil
    (executable-find ox-rfc-tidy-cmd)))

(defun ox-rfc-load-file-as-string (pathname &optional tidy)
  "Return a string containing file PATHNAME.
If TIDY is non-nil then run the file through tidy first."
  (if tidy (ox-rfc-load-file-as-string pathname)
    (with-temp-buffer
      (insert-file-contents pathname)
      (buffer-string))))

(defun ox-rfc-load-ref-file-as-string (pathname)
  "Return a string containing file PATHNAME for use as a reference."
  (replace-regexp-in-string "<\\?xml [^>]+>" ""
                            (ox-rfc-load-file-as-string pathname)))

(defun ox-rfc-docname-from-buffer ()
  "Get the internet draft name using the buffer's filename."
  (file-name-sans-extension (file-name-nondirectory (buffer-file-name (buffer-base-buffer)))))

(defun ox-rfc-export-output-file-name (extension &optional incver)
  "Get the I-D document name adding the given EXTENSION.
If INCVER is t then override the options export environment setting."
  (let ((docname (plist-get (org-export-get-environment 'rfc) :rfc-name))
        (verstr (plist-get (org-export-get-environment 'rfc) :rfc-version))
        (usever (or incver (plist-get (org-export-get-environment 'rfc) :rfc-file-name-version))))
    (if usever
        (setq extension (concat "-" verstr extension)))
    (if (not docname)
        (org-export-output-file-name extension)
      (concat docname extension))))


(defun ox-rfc-author-attrib (fullname)
  "Return the initials of the author's FULLNAME."
  (let* ((elts (split-string fullname)))
    (format "initials='%s' surname='%s' fullname='%s'"
            (concat (mapconcat (lambda (x) (substring x 0 1)) (butlast elts) ".") ".")
            (car (last elts))
            fullname)))

(defun ox-rfc-author-list (info)
  "Return the XML for author or list of authors."
  (let* ((author (plist-get info :author))
         (editor (plist-get info :editor))
         (add-authors-prop (plist-get info :rfc-add-author))
         (add-authors (mapcar (lambda (e) (if (string-prefix-p "(" e)
                                             (read e)
                                           (list e)))
                             (if add-authors-prop (split-string add-authors-prop "\n+") '())))
         (sfmt (if editor "<author role='editor' %s/>" "<author %s/>"))
         (etag "</author>")
         (ofmt "<organization>%s</organization>")
         (efmt "<address><email>%s</email></address>")
         (afmt (if editor "<author role=\"editor\" %s>" "<author %s>")))
    (setq author (if (or editor author)
                     (let ((author (list (or editor author)))
                           (affiliation (plist-get info :affiliation))
                           (email (plist-get info :email)))
                       (if email (setq author (append author (list email))))
                       (if affiliation (setq author (append author (list affiliation))))
                       (list author))
                   '()))
    (mapconcat (lambda (x) (if (not (listp x))
                               (format sfmt (ox-rfc-author-attrib x))
                             (let ((a (car x))
                                   (e (cadr x))
                                   (o (cadr (cdr x))))
                               (concat (format afmt (ox-rfc-author-attrib a))
                                       (if o (format ofmt o) "")
                                       (if e (format efmt e) "")
                                       etag))))
               (append author add-authors)
               "\n")))

(defun ox-rfc-ref-author-list-from-prop (item)
  "Return the XML for and author or list of authors.
The author list is looked for in ITEM using property named PNAME."
  (let* ((editor (org-element-property :REF_EDITOR item))
         (author (or editor (org-element-property :REF_AUTHOR item)))
         (organization (org-element-property :REF_ORG item))
         (fmt (if editor "<author role='editor' %s>%s</author>"
                "<author %s>%s</author>")))
    (if organization
        (setq organization (format "<organization>%s</organization>" organization))
      (setq organization "<organization/>"))
    (if author (progn
                 (if (string-prefix-p "(" author)
                     (setq author (read author))
                   (setq author (list author)))
                 (mapconcat (lambda (x) (format fmt (ox-rfc-author-attrib x) organization)) author "\n"))
      (format "<author>%s</author>" organization))))


(defun ox-rfc-render-v3 ()
  "Return t if rendering in xml2rfc version 3 format."
  (let ((v (or (plist-get (org-export-get-environment 'rfc) :rfc-xml-version)
               (number-to-string ox-rfc-xml-version))))
    (not (or (not v) (< (string-to-number v) 3)))))


;;; Transcode Functions

;;;; Bold

(defun ox-rfc-bold (_bold contents _info)
  "Transcode BOLD object into XML format.
CONTENTS is the text within bold markup.  INFO is a plist used as
a communication channel."
  (if (ox-rfc-render-v3)
      (format "<strong>%s</strong>" contents)
    (format "<spanx style='strong'>%s</spanx>" contents)))


(defun ox-rfc-center-block (_center-block contents _info)
  "Transcode a CENTER-BLOCK object into XML format.
CONTENTS is the text to center.  INFO is a plist used as
a communication channel."
  ;; Done if we handle it already.
  contents)

;;;; Example Block, Src Block and Export Block

(defun ox-rfc--artwork (a-block contents _info &optional is-src)
  "Transcode EXAMPLE-BLOCK element into RFC format.
CONTENTS is nil.  _INFO is a plist used as a communication
channel."

  (let* ((caption (car (org-export-get-caption a-block)))
         (capstr (string-join (org-export-get-caption a-block)))
         (v3 (ox-rfc-render-v3))
         (v2 (not v3))
         (titleattr (if (and v2 caption) (format " title=\"%s\" anchor=\"%s\"" capstr (ox-rfc--headline-to-anchor capstr)) ""))
         (nameattr (if (and v3 caption) (format "<name>%s</name>" capstr) ""))
         (figopen (if (or v2 caption) (format "<figure%s>%s" titleattr nameattr) ""))
         (figclose (if (or v2 caption) "</figure>" ""))
         (codetag (if (and is-src (ox-rfc-render-v3)) "sourcecode" "artwork"))
         ;; Check for yang to special handle
         (language (or (org-element-property :language a-block) "unknown"))
         (codestart "")
         (codeend ""))

    (if (string= language "yang")
        (let ((module-name (ox-rfc--get-yang-module-file-name contents))
              revision)
          (if module-name
              (setq contents (ox-rfc--replace-yang-module-revision contents)
                    revision (ox-rfc--get-yang-module-revision contents)))
          (if (and revision module-name (not (string-prefix-p "example-" module-name)))
              (setq codeend "<CODE ENDS>\n"
                    codestart (format "<CODE BEGINS> file \"%s@%s.yang\"\n" module-name revision)))))
    (concat figopen
            (format "<%s>" codetag)
            "<![CDATA[\n"
            codestart
            contents
            codeend
            "]]>"
            (format "</%s>" codetag)
            figclose)))

(defun ox-rfc-dynamic-block (dynamic-block contents _info)
  "Transcode a DYNAMIC-BLOCK element from Org to RFC.
CONTENTS holds the contents of the block.  _INFO is a plist
holding contextual information."
  (let ((block-type (org-element-property :type dynamic-block))
        (value (org-element-property :value dynamic-block)))
    ;; (message "XXX DVALUE: \"%s\" DBLOCK: \"%s\" DCONTENTS: \"%s\"" value dynamic-block contents)
    (cond
     ((string= (downcase block-type) "xml")
      (org-trim value))
     (t (org-trim contents)))))

(defun ox-rfc-example-block (example-block _contents info)
  "Transcode EXAMPLE-BLOCK element into RFC format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (ox-rfc--artwork example-block
                   (let ((org-src-preserve-indentation t))
                     (org-export-format-code-default example-block info))
                   info
                   nil))

(defun ox-rfc-export-block (export-block contents info)
  "Transcode a EXPORT-BLOCK element from Org to RFC.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (if (member (org-element-property :type export-block) '("RFC" "RFC"))
      (org-remove-indentation (org-element-property :value export-block))
    ;; Also include HTML export blocks.
    (org-export-with-backend 'rfc export-block contents info)))


(defun ox-rfc-special-block (special-block contents info)
  "Transcode a SPECIAL-BLOCK element from Org to RFC.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (let ((block-type (org-element-property :type special-block)))
    (cond
     ((string= (downcase block-type) "abstract")
      (plist-put info :abstract (format "<abstract>%s</abstract>" (org-trim contents)))
      "")
     ((string= (downcase block-type) "noexport") "")
     ((string= (downcase block-type) "xml")
      (message "XXX S-XML-BLOCK: \"%s\" S-XML-CONTENTS: \"%s\"" special-block contents)
      (org-remove-indentation (org-export-data special-block info)))
     (t contents))))

(defun ox-rfc-src-block (src-block _contents info)
  "Transcode SRC-BLOCK element into RFC format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (ox-rfc--artwork src-block
                   (let ((org-src-preserve-indentation t))
                     (org-export-format-code-default src-block info))
                   info
                   t))

;;;; Headline

(defun ox-rfc-headline (headline contents info)
  "Transcode HEADLINE element into RFC format.
CONTENTS is the headline contents.  INFO is a plist used as
a communication channel."
  (unless (org-element-property :footnote-section-p headline)
    (let* ((ptitle (org-export-data (org-element-property :title (org-export-get-parent headline)) info))
           (title (org-trim (org-export-data (org-element-property :title headline) info))))
      (let ((anchor (or (and (ox-rfc--headline-referred-p headline info)
		             (format " anchor=\"%s\""
			             (or (org-element-property :CUSTOM_ID headline)
                                         (ox-rfc--headline-to-anchor title)
                                         ;; (org-export-get-reference headline info)
                                         )))
                        ""))
            (backtext ""))
        (cond
         ((member title '("Normative References" "Informative References"))
          (unless (plist-get info :in-back)
            (setq backtext "</middle>\n<back>\n")
            (plist-put info :in-back t))
          (format "%s<references%s title=\"%s\">\n%s</references>\n"
                  backtext anchor title contents))
         ((member ptitle '("Normative References" "Informative References"))
          (ox-rfc-reference headline contents info))
         (t (format "<section title=\"%s\"%s>\n%s\n</section>\n" title anchor
                 contents)))))))

(defun ox-rfc--headline-referred-p (headline info)
  "Non-nil when HEADLINE is being referred to.
INFO is a plist used as a communication channel.  Links and table
of contents can refer to headlines."
  (unless (org-element-property :footnote-section-p headline)
    ;; A link refers internally to HEADLINE.
    (org-element-map (plist-get info :parse-tree) 'link
      (lambda (link)
	(eq headline
	    (pcase (org-element-property :type link)
	      ((or "custom-id" "id") (org-export-resolve-id-link link info))
	      ("fuzzy" (org-export-resolve-fuzzy-link link info))
	      (_ nil))))
      info t)))

;;;; Italic

(defun ox-rfc-italic (_italic contents _info)
  "Transcode ITALIC object into RFC format.
CONTENTS is the text within italic markup.  INFO is a plist used
as a communication channel."
  (if (ox-rfc-render-v3)
      (format "<em>%s</em>" contents)
    (format "<spanx style='emph'>%s</spanx>" contents)))

;;;; Item


(defun ox-rfc-item (item contents info)
  "Transcode ITEM element into RFC format.
CONTENTS is the item contents.  INFO is a plist used as
a communication channel."
  (progn
  (let* ((type (org-element-property :type (org-export-get-parent item)))
	 (struct (org-element-property :structure item))
	 (_bullet (if (not (eq type 'ordered)) "-"
		    (concat (number-to-string
			     (car (last (org-list-get-item-number
					 (org-element-property :begin item)
					 struct
					 (org-list-prevs-alist struct)
					 (org-list-parents-alist struct)))))
			    "."))))
    (let ((tag (org-element-property :tag item))
          (contents (org-trim contents)))
      (if (not (ox-rfc-render-v3))
          (cond
           (tag
            (replace-regexp-in-string "<t>" (format "<t hangText=\"%s:\"><vspace/>"
                                                    (org-export-data tag info)) contents))
           (t (org-trim contents)))
        (cond
         (tag
          (format "<dt>%s</dt><dd>%s</dd>" (org-export-data tag info) contents))
         (t
          (format "<li>%s</li>" contents))))))))

;;;; Line Break

(defun ox-rfc-line-break (_line-break _contents _info)
  "Transcode LINE-BREAK object into RFC format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (if (ox-rfc-render-v3) "<br>" "<vspace/>"))


;;;; Link

;;;; XXX Not done testing this conversion from org-md yet.

(defun ox-rfc-link (link contents info)
  "Transcode LINK object into RFC format.
CONTENTS is the link's description.  INFO is a plist used as
a communication channel."
  (let ((link-org-files-as-rfc
	 (lambda (raw-path)
	   ;; Treat links to `file.org' as links to `file.xml'.
	   (if (string= ".org" (downcase (file-name-extension raw-path ".")))
	       (concat (file-name-sans-extension raw-path) ".xml")
	     raw-path)))
	(type (org-element-property :type link)))
    (cond
     ;; Link type is handled by a special function.
     ((and (fboundp 'org-export-custom-protocol-maybe) (org-export-custom-protocol-maybe link contents 'rfc)))
     ((member type '("custom-id" "id" "fuzzy"))
      (let ((destination (if (string= type "fuzzy")
			     (org-export-resolve-fuzzy-link link info)
			   (org-export-resolve-id-link link info))))
	(pcase (org-element-type destination)
	  (`headline
	   (let* ((dtitle (org-export-data (org-element-property :title destination) info))
                  (dparent (org-export-get-parent-element destination))
                  (pname (org-element-property :raw-value dparent)))
             (cond
              ;; XXX there's actually no anchor for this.
              ((member pname '("Informative References" "Normative References"))
               ;; A reference to one of the reference sections
               (format "<xref target=\"%s\"/>" dtitle))
              (t
               ;; Need to normalize references to allow for non leading zeros
               (format
                "<xref%s target=\"%s\">%s</xref>"
                ;; using counter as a work-around until "none" is available.
	        (if (org-string-nw-p contents) " format=\"counter\"" "")
	        ;; Reference.
	        (or (org-element-property :CUSTOM_ID destination)
                    (ox-rfc--headline-to-anchor dtitle))
                    ;; (org-export-get-reference destination info))
                ;; Description.
	        (cond ((org-string-nw-p contents))
		      (t "")))))))
	  (_
	   (let ((description
		  (or (org-string-nw-p contents)
		      (let ((number (org-export-get-ordinal destination info)))
			(cond
			 ((not number) nil)
			 ((atom number) (number-to-string number))
			 (t (mapconcat #'number-to-string number ".")))))))
	     (when description
	       (format "<xref target=\"%s\">%s</xref>"
		       (org-export-get-reference destination info)
                       contents)))))))
     ;; Need to test this case.
     (t (let* ((raw-path (org-element-property :path link))
	       (path
		(cond
		 ((member type '("http" "https" "ftp" "mailto"))
		  (concat type ":" raw-path))
		 ((string= type "file")
		  (org-export-file-uri (funcall link-org-files-as-rfc raw-path)))
		 (t raw-path))))
	  (if (not contents) (format "<eref target=\"%s\"/>" path)
	    (format "<eref target=\"%s\">%s</eref>" path contents)))))))

;;;; Node Property (XXX what's this used for?)

(defun ox-rfc-node-property (node-property _contents _info)
  "Transcode a NODE-PROPERTY element into RFC syntax.
CONTENTS is nil.  INFO is a plist holding contextual
information."
  (format "%s:%s"
          (org-element-property :key node-property)
          (let ((value (org-element-property :value node-property)))
            (if value (concat " " value) ""))))

;;;; Paragraph

(defun ox-rfc-paragraph (_paragraph contents _info)
  "Transcode PARAGRAPH element into RFC format.
CONTENTS is the paragraph contents.  INFO is a plist used as
a communication channel."
  (format "<t>%s</t>" (org-trim contents)))


;;;; Plain List

(defun ox-rfc-plain-list (plain-list contents _info)
  "Transcode PLAIN-LIST element into RFC format.
CONTENTS is the plain-list contents.  INFO is a plist used as
a communication channel."
  (let ((ltype (org-element-property :type plain-list)))
    (if (ox-rfc-render-v3)
        (let* ((type (pcase ltype
	               (`ordered "ol")
	               (`unordered "ul")
	               (`descriptive "dl")
	               (other (error "Unknown HTML list type: %s" other)))))
          (if (eq ltype `descriptive)
              ;; (format "<dl hanging=\"false\">\n%s</dl>" contents)
              (format "<dl>\n%s</dl>" contents)
            (format "<%s>\n%s</%s>" type contents type)))
      (let* ((style (pcase ltype
	              (`ordered "numbers")
	              (`unordered "symbols")
	              (`descriptive "hanging")
	              (other (error "Unknown HTML list type: %s" other)))))
        (format "<t><list style=\"%s\">\n%s</list></t>" style contents)))))


;;;; Plain Text

(defun ox-rfc-plain-text (text _info)
  "Convert plain text characters from TEXT to HTML equivalent.
INFO is a plist used as a communication channel."
  (let ((protect-alist '(("&" . "&amp;")
                         ("<" . "&lt;")
                         (">" . "&gt;"))))
    (dolist (pair protect-alist text)
      (setq text (replace-regexp-in-string (car pair) (cdr pair) text t t)))))


;;;; Quote Block

(defun ox-rfc-quote-block (quote-block contents info)
  "Transcode QUOTE-BLOCK element into RFC format.
CONTENTS is the quote-block contents.  INFO is a plist used as
a communication channel."
  (if (ox-rfc-render-v3)
      (format "<blockquote>%s</blockquote>" (org-trim contents))

    (ox-rfc--artwork quote-block
                     (org-export-format-code-default quote-block info)
                     info
                     nil)))

;;;; Reference (headline)

(defun ox-rfc-reference (headline _contents info)
  "Transcode reference to HEADLINE into RFC format.
INFO is a plist used as a communication channel."
  (let ((title (org-export-data (org-element-property :title headline) info))
        (reftitle (org-element-property :REF_TITLE headline))
        (reftarget (org-element-property :REF_TARGET headline))
        (refstd (org-element-property :REF_STDXML headline))
        (refxml (org-element-property :REF_URLXML headline)))
    (setq reftarget (if reftarget (format " target='%s'" reftarget) ""))
    (cond
     (refstd
      (replace-regexp-in-string "anchor=['\"]\\([^'\"]+\\)['\"]"
                                (format "anchor=\"%s\"" title)
                                (ox-rfc-load-ref-file-as-string (ox-rfc-std-ref-fetch-to-cache refstd))))
     (refxml
      (replace-regexp-in-string "anchor=['\"]\\([^'\"]+\\)['\"]"
                                (format "anchor=\"%s\"" title)
                                (ox-rfc-load-ref-file-as-string (ox-rfc-url-ref-fetch-to-cache refxml))))
     ((not reftitle)
      (ox-rfc-load-ref-file-as-string (ox-rfc-std-ref-fetch-to-cache title)))
     (t
      ;; (message "PROP: %s %s" title (org-element-context headline))
      (let ((refann (org-string-nw-p (org-export-data (org-element-property :REF_ANNOTATION headline) info)))
            (author (ox-rfc-ref-author-list-from-prop headline))
            (refcontent (org-string-nw-p (org-export-data (org-element-property :REF_CONTENT headline) info)))
            (reftitle (org-string-nw-p (org-export-data reftitle info)))
            (refdate (org-export-data (org-element-property :REF_DATE headline) info)))
        (if (not reftitle)
            (setq reftitle title))
        (if (not refdate)
            (setq refdate "")
          (let* ((date (nthcdr 3 (parse-time-string refdate)))
                 (day (and (car date)))
                 (month (cadr date))
                 (year (cadr (cdr date))))
            (setq day (or (and day (format " day=\"%s\"" day)) ""))
            (setq month (or (and month (format " month=\"%s\"" month)) ""))
            (setq year (or (and year (format " year=\"%s\"" year)) ""))
            (setq refdate (format "<date%s%s%s/>" day month year))))
        (if (not refcontent)
            (setq refcontent "")
          (setq refcontent (format "<refcontent>%s</refcontent>" (org-trim refcontent))))
        (if (not refann)
            (setq refann "")
          (setq refann (format "<annotation>%s</annotation>" refann)))
        (if (ox-rfc-render-v3)
            (format "<reference anchor=\"%s\"%s>\n<front>\n<title>%s</title>\n%s\n%s\n</front>%s%s\n</reference>"
                    title reftarget reftitle author refdate refcontent refann)
          (format "<reference anchor=\"%s\"%s>\n<front>\n<title>%s</title>\n%s\n%s\n</front>%s\n</reference>"
                  title reftarget reftitle author refdate refann)))))))

;;;; Section

(defun ox-rfc-section (_section contents _info)
  "Transcode SECTION element into RFC format.
CONTENTS is the section contents.  INFO is a plist used as
a communication channel."
  (if (not contents)
      ""
    contents))

;;;; Subscript

(defun ox-rfc-subscript (_subscript contents _info)
  "Transcode a SUBSCRIPT object from Org to HTML.
CONTENTS is the contents of the object.  INFO is a plist holding
contextual information."
  (if (ox-rfc-render-v3)
      (format "<sub>%s</sub>" contents)
    contents))

;;;; Superscript

(defun ox-rfc-superscript (_superscript contents _info)
  "Transcode a SUPERSCRIPT object from Org to HTML.
CONTENTS is the contents of the object.  INFO is a plist holding
contextual information."
  (if (ox-rfc-render-v3)
      (format "<sup>%s</sup>" contents)
    contents))


;;;; Template

(defun ox-rfc-inner-template (contents info)
  "Return body of document after converting it to RFC syntax.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  ;; Make sure CONTENTS is separated from table of contents and
  ;; footnotes with at least a blank line.
  ;; Table of contents.
  (progn
  (let ((category (or (plist-get info :rfc-category) "std"))
        (consensus (or (plist-get info :rfc-consensus) "yes"))
        (docname (ox-rfc-export-output-file-name "" t))
        (ipr (or (plist-get info :rfc-ipr) "trust200902"))
        (obsoletes (plist-get info :rfc-obsoletes))
        (stream (or (plist-get info :rfc-stream) "IETF"))
        (title (org-export-data (plist-get info :title) info))
        (short-title (or (plist-get info :rfc-short-title)
                         (org-export-data (plist-get info :title) info)))
        (updates (plist-get info :rfc-updates))
        (with-toc (if (plist-get info :with-toc) "yes" "no"))
        (toc-inc (if (plist-get info :with-toc) "true" "false"))
        )
    (concat
     ;; Replace this with actual code.
     ;; <?rfc toc=\"" with-toc "\" ?>
     "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n"

     (if (not (ox-rfc-render-v3))
         "<!DOCTYPE rfc SYSTEM \"rfc2629.dtd\" []>\n"
       "")
"<?xml-stylesheet type=\"text/xsl\" href=\"rfc2629.xslt\"?>
<?rfc toc=\"" with-toc "\"?>
<?rfc compact=\"no\"?>
<?rfc subcompact=\"no\"?>
<?rfc symrefs=\"yes\" ?>
<?rfc sortrefs=\"yes\"?>
<?rfc iprnotified=\"no\"?>
<?rfc strict=\"yes\"?>
<rfc ipr=\"" ipr "\"
     category=\"" category "\"
     docName=\"" docname "\""
     (if obsoletes (concat "    obsoletes=\"" obsoletes "\"\n"))
     (if updates (concat "    updates=\"" updates "\"\n"))
"     submissionType=\"" stream "\""
     (if (ox-rfc-render-v3)
         (concat
          "\n    consensus=\"" consensus "\""
          "    tocInclude=\"" toc-inc "\""
          "    version=\"3\""))
     ">
  <front>
    <title abbrev=\"" short-title "\">" title "</title>\n"
  (ox-rfc-author-list info)
  "  <date/>"
  (or (plist-get info :abstract) "")
  "  </front>"
  "  <middle>\n"
  ;; Document contents.
  contents
  (unless (plist-get info :in-back)
    "</middle><back>")
  "  </back>
</rfc>"))))

(defun ox-rfc-template (contents _info)
  "Return complete document string after RFC conversion.
CONTENTS is the transcoded contents string.  INFO is a plist used
as a communication channel."
  contents)


;;;; Table

(defun ox-rfc-table (table contents info)
  "Transcode a TABLE element from Org to RFC format.
CONTENTS is the contents of the table.  INFO is a plist holding
contextual information."
  (cond
   ((eq (org-element-property :type table) 'table.el)
    ;; "table.el" table.  Convert it using appropriate tools.
    (ox-rfc--artwork table (ox-rfc-table--table.el-table table info) info))
   ((plist-get (org-export-get-environment 'rfc) :rfc-ascii-table)
    (ox-rfc--artwork table
                     (cl-letf (((symbol-function 'org-export-get-caption) (lambda (_x &optional _y))))
                       (org-ascii-table table contents info))
                     info))
   (t
    (let* ((caption (org-export-get-caption table))
             ;; May want to support in future.
             ;; (number (org-export-get-ordinal
             ;;          table info nil #'org-html--has-caption-p))
             ;; (alignspec
             ;;  (if (bound-and-true-p org-html-format-table-no-css)
             ;;      "align=\"%s\""
             ;;    "class=\"org-%s\""))
             )
      (if (ox-rfc-render-v3)
          (format "<table>\n%s\n%s</table>"
	          (if (not caption) ""
		    (format "<name>%s</name>" (org-export-data caption info)))
	          contents)
        (format "<texttable%s>\n%s</texttable>"
	        (if (not caption) ""
		  (format " title=\"%s\"" (org-export-data caption info)))
	        contents))
        ))))

(defun ox-rfc-table-first-row-data-cells (table info)
  "Transcode the first row of TABLE.
INFO is a plist used as a communication channel."
  (let ((table-row
	 (org-element-map table 'table-row
	   (lambda (row)
	     (unless (eq (org-element-property :type row) 'rule) row))
	   info 'first-match))
	(special-column-p (org-export-table-has-special-column-p table)))
    (if (not special-column-p) (org-element-contents table-row)
      (cdr (org-element-contents table-row)))))

(defun ox-rfc-table--table.el-table (table _info)
  "Format table.el TABLE into HTML.
INFO is a plist used as a communication channel."
  (when (eq (org-element-property :type table) 'table.el)
    (require 'table)
    (let ((outbuf (with-current-buffer
		      (get-buffer-create "*org-export-table*")
		    (erase-buffer) (current-buffer))))
      (with-temp-buffer
	(insert (org-element-property :value table))
	(goto-char 1)
	(re-search-forward "^[ \t]*|[^|]" nil t)
	(table-generate-source 'html outbuf))
      (with-current-buffer outbuf
	(prog1 (org-trim (buffer-string))
	  (kill-buffer))))))

(defun ox-rfc-table-row (table-row contents info)
  "Transcode a TABLE-ROW element from Org to RFC format.
CONTENTS is the contents of the table.  INFO is a plist holding
contextual information."
  (let ((v3 (ox-rfc-render-v3)))

    (if (plist-get (org-export-get-environment 'rfc) :rfc-ascii-table)
        (org-ascii-table-row table-row contents info)
      (when (eq (org-element-property :type table-row) 'standard)
        (let* ((group (org-export-table-row-group table-row info))
	       ;; (number (org-export-table-row-number table-row info))
	       (start-group-p
	        (org-export-table-row-starts-rowgroup-p table-row info))
	       (end-group-p
	        (org-export-table-row-ends-rowgroup-p table-row info))
	       ;; (topp (and (equal start-group-p '(top))
	       ;;            (equal end-group-p '(below top))))
	       ;; (bottomp (and (equal start-group-p '(above))
	       ;;    	   (equal end-group-p '(bottom above))))
               (row-open-tag (if v3 "<tr>" ""))
               (row-close-tag (if v3 "</tr>" ""))
	       (group-tags
	        (cond
	         ;; Row belongs to second or subsequent groups.
	         ((not (= 1 group)) (if v3 '("<tbody>" . "\n</tbody>") '("" . "")))
	         ;; Row is from first group.  Table has >=1 groups.
	         ((org-export-table-has-header-p
	           (org-export-get-parent-table table-row) info)
	          (if v3 '("<thead>" . "\n</thead>") '("" . "")))
	         ;; Row is from first and only group.
	         (t (if v3 '("<tbody>" . "\n</tbody>") '("" . ""))))))
          (concat (and start-group-p (car group-tags))
	          (concat row-open-tag contents row-close-tag)
	          (and end-group-p (cdr group-tags))))))))

(defun ox-rfc-table-cell (table-cell contents info)
  "Transcode a TABLE-CELL element from Org to RFC format.
CONTENTS is the contents of the table.  INFO is a plist holding
contextual information."
  (if (plist-get (org-export-get-environment 'rfc) :rfc-ascii-table)
      (org-ascii-table-cell table-cell contents info)
    (let* ((v3 (ox-rfc-render-v3))
           (table-row (org-export-get-parent table-cell))
	   (table (org-export-get-parent-table table-cell))
	   (cell-attrs ""))
      (when (or (not contents) (string= "" (org-trim contents)))
        (setq contents "&#xa0;"))
      (cond
       ((and (org-export-table-has-header-p table info)
	     (= 1 (org-export-table-row-group table-row info)))
        (if v3
            (let ((header-tags '("<th%s>" . "</th>")))
	      (concat (format (car header-tags) cell-attrs)
		      contents
		      (cdr header-tags)))
          (let ((header-tags '("<ttcol%s>" . "</ttcol>")))
	    (concat (format (car header-tags) cell-attrs)
		    contents
		    (cdr header-tags)))))
       (t (if v3
              (let ((data-tags '("<td%s>" . "</td>")))
	        (concat (format (car data-tags) cell-attrs)
		        contents
		        (cdr data-tags)))
            (let ((data-tags '("<c%s>" . "</c>")))
              (concat (format (car data-tags) cell-attrs)
	              contents
	              (cdr data-tags)))))))))

;;;; Verbatim

(defun ox-rfc-verbatim (verbatim _contents _info)
  "Transcode VERBATIM object into RFC format.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (let ((value (org-element-property :value verbatim)))
    (if (ox-rfc-render-v3)
        (format "'<tt>%s</tt>'" value)
      (format "<spanx style='verb'>%s</spanx>" value))))


;;; Interactive function

;;;###autoload
(defun ox-rfc-run-test-blocks (&optional fail-fast)
  "Run all code-blocks with names that start with 'test-' return
true only if all code-blocks succeeded. If FAIL-FAST is true then
return nil immediately when a code-block fails.

This function searches for the string 'FAIL' to determine if the
test succeeded or not.
"
  (interactive "P")
  (save-excursion
    (let ((test-block-names (cl-remove-if-not (lambda (x) (string-prefix-p "test-" x)) (org-babel-src-block-names)))
          (success t))
      (dolist (test-name test-block-names)
        (when (not (and fail-fast (not success)))
          (princ (format "EXECUTE: %s" test-name))
          (org-babel-goto-named-src-block test-name)
          (let ((results (org-babel-execute-src-block)))
            (if (string-match-p "FAIL" (format "%s" results))
                (setq success nil))
            (princ (format "RESULT %s: %s\n" test-name results)))))
      success)))

;;;###autoload
(defun ox-rfc-export-as-xml (&optional async subtreep visible-only)
  "Export current buffer to a XML buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Export is done in a buffer named \"*Org RFC Export*\", which will
be displayed when `org-export-show-temporary-export-buffer' is
non-nil."
  (interactive)
  (let ((setmode (lambda ()
                   (let ((mode (or (assoc-default "whatmode.xml" auto-mode-alist 'string-match)
                                         'text-mode)))
                     (set-auto-mode-0 mode t))))
        (tidycmd (ox-rfc-get-tidy)))
    (if (not tidycmd)
        (org-export-to-buffer 'rfc "*Org RFC Export*" async subtreep visible-only nil nil setmode)
      (org-export-to-buffer 'rfc "*Org RFC Export*"
        async subtreep visible-only nil nil
        (lambda ()
          (shell-command-on-region (point-min) (point-max)
                                   (format "%s %s" tidycmd ox-rfc-tidy-args)
                                   (current-buffer) t "*Org RFC Error*" t)
          (deactivate-mark)
          (funcall setmode))))))

(defun ox-rfc-export-as-text (&optional async subtreep visible-only buffer outfile)
  "Export current buffer to a XML buffer.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer should be accessible
through the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

If BUFFER is not given, export is done in a buffer named \"*Org
RFC Export*\", which will be displayed when
`org-export-show-temporary-export-buffer' is non-nil.

If OUTFILE is non-nil the results are stored in that file."
  (interactive)
  (if (not buffer) (setq buffer "*Org RFC TEXT Export*"))
  (if (not outfile) (setq outfile "/dev/stdout"))
  (org-export-to-buffer 'rfc buffer
    async subtreep visible-only nil nil
    (lambda ()
      (let ((exitcode (shell-command-on-region
                       (point-min)
                       (point-max)
                       (format "xml2rfc --quiet -o %s --text /dev/stdin" outfile)
                       (current-buffer) t "*Org RFC Error*" t)))
        (deactivate-mark)
        (if exitcode
            (pop-to-buffer "*Org RFC Error*"))))))

;;;###autoload
(defun ox-rfc-export-to-xml (&optional async subtreep visible-only)
  "Export current buffer to a XML file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file's name."
  (interactive)
  (let ((outfile (ox-rfc-export-output-file-name ".xml"))
        (tidycmd (ox-rfc-get-tidy)))
    (if (not tidycmd)
        (org-export-to-file 'rfc outfile async subtreep visible-only)
      (let ((tmpfile (make-temp-file (file-name-sans-extension (file-name-base outfile)) nil ".xml")))
        (org-export-to-file 'rfc tmpfile async subtreep visible-only nil nil
                            (lambda (file)
                              (shell-command (format "%s %s -o %s %s" tidycmd ox-rfc-tidy-args outfile file))
                              (message "Tidied into %s" outfile)
                              outfile))))))



(defun ox-rfc-export-to-x (ext cli-arg &optional async subtreep visible-only)
  "Export the current buffer to a file with the extension EXT.
CLI-ARG is passed to xml2rfc to specify the file type.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file's name."
  (let ((xmlfile (ox-rfc-export-output-file-name ".xml"))
        (outfile (ox-rfc-export-output-file-name ext)))
    (org-export-to-file
        'rfc xmlfile async subtreep visible-only nil nil
        (lambda (_file)
          (shell-command
           (format "xml2rfc --quiet %s -o %s %s" cli-arg outfile xmlfile))))
    outfile))


;;;###autoload
(defun ox-rfc-export-to-html (&optional async subtreep visible-only)
  "Export current buffer to a HTML file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file's name."
  (interactive)
  (ox-rfc-export-to-x ".html" "--html" async subtreep visible-only))


;;;###autoload
(defun ox-rfc-export-to-pdf (&optional async subtreep visible-only)
  "Export current buffer to a PDF file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file's name."
  (interactive)
  (ox-rfc-export-to-x ".pdf" "--pdf" async subtreep visible-only))


;;;###autoload
(defun ox-rfc-export-to-text (&optional async subtreep visible-only)
  "Export current buffer to a TEXT file.

If narrowing is active in the current buffer, only export its
narrowed part.

If a region is active, export that region.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting file should be accessible through
the `org-export-stack' interface.

When optional argument SUBTREEP is non-nil, export the sub-tree
at point, extracting information from the headline properties
first.

When optional argument VISIBLE-ONLY is non-nil, don't export
contents of hidden elements.

Return output file's name."
  (interactive)
  (ox-rfc-export-to-x ".txt" "--text" async subtreep visible-only))


;; For now let's leave out the publish stuff.
;; ;;;###autoload
;; (defun ox-rfc-publish-to-xml (plist filename pub-dir)
;;   "Publish an org file to RFC.

;; FILENAME is the filename of the Org file to be published.  PLIST
;; is the property list for the given project.  PUB-DIR is the
;; publishing directory.

;; Return output file name."
;;   (org-publish-org-to 'rfc filename ".xml" plist pub-dir))

(provide 'ox-rfc)

;;; ox-rfc.el ends here
