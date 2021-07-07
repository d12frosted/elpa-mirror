;;; ox-epub.el --- Export org mode projects to EPUB -*- lexical-binding: t; -*-

;; Copyright (c) 2017-2018 - Mark Meyer

;; Author: Mark Meyer <mark@ofosos.org>
;; Maintainer: Mark Meyer <mark@ofosos.org>

;; URL: http://github.com/ofosos/org-epub
;; Package-Version: 20181101.1854
;; Package-Commit: c9629ef4b4bc40d51afefd8c0bb2c683931e6409
;; Keywords: hypermedia

;; Version: 0.1.0

;; Package-Requires: ((emacs "24.3") (org "9"))

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

;; This is an addition to the standard org-mode exporters.  The package
;; extends the (X)HTML exporter to produce EPUB files.  It eliminates
;; all inline CSS and JavaScript to accomplish this.  This exporter
;; will also tie the XHTML DTD to XHTML 1.1, a concrete DTD specifier
;; that was not supported by ox-html previously.

;; The main part is the generation of the table of contents in machine
;; readable form, as well as the spine, which defines the order in
;; which files are presented.  A lesser part is the inclusion of
;; various metadata properties, among them authorship and rights.

;;; Code:

(require 'cl-lib)
(require 'ox-publish)
(require 'ox-html)
(require 'org-element)

(org-export-define-derived-backend 'epub 'html
  :options-alist
  '((:epub-uid "UID" nil nil t)
    (:epub-subject "Subject" nil nil t)
    (:epub-description "Description" nil nil t)
    (:epub-publisher "Publisher" nil nil t)
    (:epub-rights "License" nil nil t)
    (:epub-style "EPUBSTYLE" nil nil t)
    (:epub-cover "EPUBCOVER" nil nil t)
    (:html-doctype "HTML_DOCTYPE" nil "xhtml" t))
    
  :translate-alist
  '((template . org-epub-template)
    (link . org-epub-link)
    (latex-environment . org-epub--latex-environment)
    (latex-fragment . org-epub--latex-fragment))
  :menu-entry
  '(?E "Export to Epub"
       ((?e "As Epub file" org-epub-export-to-epub)
	(?O "As Epub file and open"
	    (lambda (a s v b)
	      (if a (org-epub-export-to-epub t s v)
		(org-open-file (org-epub-export-to-epub nil s v) 'system)))))))

(defvar org-epub-zip-dir nil
  "The temporary directory to export to")

(defvar org-epub-style-default "
  .title  { text-align: center;
             margin-bottom: .2em; }
  .subtitle { text-align: center;
              font-size: medium;
              font-weight: bold;
              margin-top:0; }
  .todo   { font-family: monospace; color: red; }
  .done   { font-family: monospace; color: green; }
  .priority { font-family: monospace; color: orange; }
  .tag    { background-color: #eee; font-family: monospace;
            padding: 2px; font-size: 80%; font-weight: normal; }
  .timestamp { color: #bebebe; }
  .timestamp-kwd { color: #5f9ea0; }
  .org-right  { margin-left: auto; margin-right: 0px;  text-align: right; }
  .org-left   { margin-left: 0px;  margin-right: auto; text-align: left; }
  .org-center { margin-left: auto; margin-right: auto; text-align: center; }
  .underline { text-decoration: underline; }
  #postamble p, #preamble p { font-size: 90%; margin: .2em; }
  p.verse { margin-left: 3%; }
  pre {
    border: 1px solid #ccc;
    box-shadow: 3px 3px 3px #eee;
    padding: 8pt;
    font-family: monospace;
    overflow: auto;
    margin: 1.2em;
  }
  pre.src {
    position: relative;
    overflow: visible;
    padding-top: 1.2em;
  }

  table { border-collapse:collapse; }
  caption.t-above { caption-side: top; }
  caption.t-bottom { caption-side: bottom; }
  td, th { vertical-align:top;  }
  th.org-right  { text-align: center;  }
  th.org-left   { text-align: center;   }
  th.org-center { text-align: center; }
  td.org-right  { text-align: right;  }
  td.org-left   { text-align: left;   }
  td.org-center { text-align: center; }
  dt { font-weight: bold; }
  .footpara { display: inline; }
  .footdef  { margin-bottom: 1em; }
  .figure { padding: 1em; }
  .figure p { text-align: center; }
  .inlinetask {
    padding: 10px;
    border: 2px solid gray;
    margin: 10px;
    background: #ffffcc;
  }
  #org-div-home-and-up
   { text-align: right; font-size: 70%; white-space: nowrap; }
  textarea { overflow-x: auto; }
  .linenr { font-size: smaller }
  .code-highlighted { background-color: #ffff00; }
  .org-info-js_info-navigation { border-style: none; }
  #org-info-js_console-label
    { font-size: 10px; font-weight: bold; white-space: nowrap; }
  .org-info-js_search-highlight
    { background-color: #ffff00; color: #000000; font-weight: bold; }
  .org-svg { width: 90%; }

"
  "Default style declarations for org epub")

(defvar org-epub-zip-command "zip"
  "Command to call to create zip files.")

(defvar org-epub-zip-no-compress (list "-Xu0")
  "Zip command option list to pass for no compression.")

(defvar org-epub-zip-compress (list "-Xu9")
  "Zip command option list to pass for compression.")

(defvar org-epub-metadata nil
  "EPUB export metadata")

(defvar org-epub-headlines nil
  "EPUB headlines")

(defvar org-epub-style-counter 0
  "EPUB style counter")

;; manifest mechanism

(defvar org-epub-manifest nil
  "EPUB export manifest")

(defun org-epub-manifest-entry (id filename type mimetype &optional source)
  "Create a manifest entry with the given ID, FILENAME, TYPE, MIMETYPE and optional SOUCE.

FILENAME should be the new name in the epub container. TYPE
should be one of `'html', `'stylesheet', `'coverimg', `'cover' or
`'img'. If SOURCE is given the file name by SOUCE will be copied
to FILENAME at the end of the export process.  "
  (list :id id :filename filename :type type :mimetype mimetype :source source))

(defun org-epub-cover-p (manifest-entry)
  "Determine if MANIFEST-ENTRY is of type cover."
  (eq (plist-get manifest-entry :type) 'cover))

(defun org-epub-coverimg-p (manifest-entry)
  "Determine if MANIFEST-ENTRY is of type cover image."
  (eq (plist-get manifest-entry :type) 'coverimg))

(defun org-epub-style-p (manifest-entry)
  "Determine if MANIFEST-ENTRY is of type stylesheet."
  (eq (plist-get manifest-entry :type) 'stylesheet))

(defun org-epub-manifest-needcopy (manifest-entry)
  "Determine if MANIFEST-ENTRY needs to be copied.

If it needs to be copied return a pair (sourcefile . targetfile)."
  (if (plist-get manifest-entry :source)
      (cons (plist-get manifest-entry :source)
	    (plist-get manifest-entry :filename))
    nil))

(defun org-epub-manifest-all (pred)
  "Return all manifest entries for which PRED is true."
  (cl-remove-if-not pred org-epub-manifest))

(cl-defun org-epub-manifest-first (pred)
  "Return the first manifest entry for which PRED is true."
  (let ((val))
    (dolist (el org-epub-manifest val)
      (when (funcall pred el)
	(cl-return-from org-epub-manifest-first el)))))

;; core

;;; Latex Environment - stolen from ox-html

(defun org-epub--latex-environment (latex-environment _contents info)
  "Transcode a LATEX-ENVIRONMENT element from Org to HTML.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((processing-type (plist-get info :with-latex))
	(latex-frag (org-remove-indentation
		     (org-element-property :value latex-environment)))
	(attributes (org-export-read-attribute :attr_html latex-environment)))
    (cond
     ((assq processing-type org-preview-latex-process-alist)
      (let ((formula-link
	     (org-html-format-latex latex-frag processing-type info)))
	(when (and formula-link (string-match "file:\\([^]]*\\)" formula-link))
	  ;; Do not provide a caption or a name to be consistent with
	  ;; `mathjax' handling.
	  (org-html--wrap-image
	   (org-html--format-image
	    (let* ((path (match-string 1 formula-link))
		   (ref (org-export-get-reference latex-environment info))
		   (mime (file-name-extension path))
		   (name (concat "img-" ref "." mime)))
	      (message "Formatting Latex environment: %s" name)
	      (push (org-epub-manifest-entry ref name 'img (concat "image/" mime) path) org-epub-manifest)
	      name) attributes info) info))))
     (t latex-frag))))

;;;; Latex Fragment - stolen from ox-html

(defun org-epub--latex-fragment (latex-fragment _contents info)
  "Transcode a LATEX-FRAGMENT object from Org to HTML.
CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((latex-frag (org-element-property :value latex-fragment))
	(processing-type (plist-get info :with-latex)))
    (cond
     ((assq processing-type org-preview-latex-process-alist)
      (let ((formula-link
	     (org-html-format-latex latex-frag processing-type info)))
	(when (and formula-link (string-match "file:\\([^]]*\\)" formula-link))
	  (let* ((path (match-string 1 formula-link))
		 (ref (org-export-get-reference latex-fragment info))
		 (mime (file-name-extension path))
		 (name (concat "img-" ref "." mime)))
	    (message "Formatting Latex fragement: %s" name)
	    (push (org-epub-manifest-entry ref name 'img (concat "image/" mime) path) org-epub-manifest)
	    (org-html--format-image name nil info)))))
     (t latex-frag))))


(defun org-epub-link (link desc info)
  "Return the HTML required for a link descriped by LINK, DESC, and INFO.

See org-html-link for more info."
  (when (org-export-inline-image-p link (plist-get info :html-inline-image-rules))
    (let* ((path (org-link-unescape (org-element-property :path link)))
	   (ref (org-export-get-reference link info))
	   (mime (file-name-extension path))
	   (name (concat "img-" ref "." mime)))
      (push (org-epub-manifest-entry ref name 'img (concat "image/" mime) path) org-epub-manifest)
      (org-element-put-property link :path name)))
  (org-html-link link desc info))

(defun org-epub-meta-put (symbols info)
  "Put SYMBOLS taken from INFO into the org-epub metadata cache."
  (mapc
   #'(lambda (sym)
       (let ((data (plist-get info sym)))
	 (setq org-epub-metadata
	       (plist-put org-epub-metadata sym
			  (if (listp data)
			      (org-export-data data info)
			    data)))))
   symbols))

(defun org-epub-template (contents info)
  "Return complete document string after HTML conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (org-epub-meta-put '(:epub-uid :title :language :epub-subject :epub-description :author
				 :epub-publisher :date :epub-rights :html-head-include-default-style :epub-cover :epub-style) info)
  (setq org-epub-metadata (plist-put org-epub-metadata :epub-toc-depth 2))
  ;; maybe set toc-depth "2" to some dynamic value
  (setq org-epub-headlines
	(mapcar (lambda (headline)
		  (list
		   (org-element-property :raw-value headline)
		   (org-element-property :level headline)
		   (org-export-get-reference headline info)))
		(org-export-collect-headlines info 2)))
  (let ((styles (split-string (or (plist-get org-epub-metadata :epub-style) " "))))
    (mapc #'(lambda (style)
	      (let* ((stylenum (cl-incf org-epub-style-counter))
		     (stylename (concat "style-" (format "%d" stylenum)))
		     (stylefile (concat stylename ".css")))
		(push (org-epub-manifest-entry stylename stylefile 'stylesheet "text/css" style) org-epub-manifest)))
	  styles))
  (concat
   (when (and (not (org-html-html5-p info)) (org-html-xhtml-p info))
     (let* ((xml-declaration (plist-get info :html-xml-declaration))
	    (decl (or (and (stringp xml-declaration) xml-declaration)
		      (cdr (assoc (plist-get info :html-extension)
				  xml-declaration))
		      (cdr (assoc "html" xml-declaration))
		      "")))
       (when (not (or (not decl) (string= "" decl)))
	 (format "%s\n"
		 (format decl
			 (or (and org-html-coding-system
				  (fboundp 'coding-system-get)
				  (coding-system-get org-html-coding-system 'mime-charset))
			     "iso-8859-1"))))))
   "<!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">"
   "\n"
   (concat "<html"
	   (format
	    " xmlns=\"http://www.w3.org/1999/xhtml\" lang=\"%s\" xml:lang=\"%s\""
	    (plist-get info :language) (plist-get info :language))
	   ">\n")
   
   "<head>\n"
   (org-html--build-meta-info info)
   (when (plist-get info :html-head-include-default-style)
     "<link rel=\"stylesheet\" type=\"text/css\" href=\"style.css\"/>\n")
   (when (plist-get info :epub-style)
     (mapconcat
      #'(lambda (entry)
	  (concat "<link rel=\"stylesheet\" type=\"text/css\" href=\"" (plist-get entry :filename) "\"/>\n"))
      (org-epub-manifest-all #'org-epub-style-p) "\n"))
   "</head>\n"
   "<body>\n"
   ;; Preamble.
   (org-html--build-pre/postamble 'preamble info)
   ;; Document contents.
					;   (let ((div (assq 'content (plist-get info :html-divs))))
					;     (format "<%s id=\"%s\">\n" (nth 1 div) (nth 2 div)))
   "<div id=\"content\">"
   ;; Document title.
   (when (plist-get info :with-title)
     (let ((ftitle (plist-get info :title))
	   (subtitle (plist-get info :subtitle)))
       (when ftitle
	 (message (org-export-data ftitle info))
	 (format
	  "<h1 class=\"title\">%s</h1>%s\n"
	  (org-export-data ftitle info)
	  (if subtitle
	      (format
	       "<p class=\"subtitle\">%s</p>\n"
	       (org-export-data subtitle info))
	    "")))))
     contents
     "</div>"
     ;   (format "</%s>\n" (nth 1 (assq 'content (plist-get info :html-divs))))
     ;; Postamble.
     (org-html--build-pre/postamble 'postamble info)
     ;; Closing document.
     "</body>\n</html>"))

;; see ox-odt

(defmacro org-epub--export-wrapper (outfile &rest body)
  "Export an Epub with BODY generating the main html file and OUTFILE as target file."
  `(let* ((outfile ,outfile)
	      (org-epub-manifest nil)
	      (org-epub-metadata nil)
	      (org-epub-style-counter 0)
	      (out-file-type (file-name-extension outfile))
	      (org-epub-zip-dir (file-name-as-directory
				 (make-temp-file (format "%s-" out-file-type) t)))
	      (body ,@body))
     (condition-case err
	 (progn
	   (when (plist-get org-epub-metadata :html-head-include-default-style)
	     (with-current-buffer (find-file (concat org-epub-zip-dir "style.css"))
	       (insert org-epub-style-default)
	       (save-buffer 0)
	       (kill-buffer)
	       (push (org-epub-manifest-entry "default-style" "style.css" 'stylesheet "text/css") org-epub-manifest)))
	   (when (org-string-nw-p (plist-get org-epub-metadata :epub-cover))
	     (let* ((cover-path (plist-get org-epub-metadata :epub-cover))
		    (cover-type (file-name-extension cover-path))
		    (cover-img (create-image (expand-file-name cover-path)))
		    (cover-width (car (image-size cover-img t)))
		    (cover-height (cdr (image-size cover-img t)))
		    (cover-name (concat "cover." cover-type)))
	       (with-current-buffer (find-file (concat org-epub-zip-dir "cover.html"))
		 (erase-buffer)
		 (insert
		  (org-epub-template-cover cover-name cover-width cover-height))
		 (save-buffer 0)
		 (kill-buffer)
		 (let ((men (org-epub-manifest-entry "cover" "cover.html" 'cover "application/xhtml+xml")))
		   (push men org-epub-manifest))
		 (let ((men (org-epub-manifest-entry "cover-image" cover-name 'coverimg (concat "image/" cover-type) cover-path)))
		   (push men org-epub-manifest)))))
           (unless (file-directory-p (expand-file-name "META-INF" org-epub-zip-dir))
             (make-directory (file-name-as-directory (expand-file-name "META-INF" org-epub-zip-dir))))
	   (with-current-buffer (find-file (expand-file-name "META-INF/container.xml" org-epub-zip-dir))
	     (erase-buffer)
	     (insert (org-epub-template-container))
	     (save-buffer 0)
	     (kill-buffer))
	   (with-current-buffer (find-file (concat org-epub-zip-dir "mimetype"))
	     (erase-buffer)
	     (insert (org-epub-template-mimetype))
	     (save-buffer 0)
	     (kill-buffer))
	   (with-current-buffer (find-file (concat org-epub-zip-dir "body.html"))
	     (erase-buffer)
	     (insert body)
	     (save-buffer 0)
	     (kill-buffer)
	     (nconc org-epub-manifest (list (org-epub-manifest-entry "body-html" "body.html" 'html "application/xhtml+xml"))))
	   (with-current-buffer (find-file (concat org-epub-zip-dir "toc.ncx"))
	     (erase-buffer)
	     (insert
	      (org-epub-template-toc-ncx
	       (plist-get org-epub-metadata :epub-uid)
	       (plist-get org-epub-metadata :epub-toc-depth)
	       (plist-get org-epub-metadata :title)
	       (org-epub-generate-toc-single org-epub-headlines "body.html")))
	     (save-buffer 0)
	     (kill-buffer))
	   (with-current-buffer (find-file (concat org-epub-zip-dir "content.opf"))
	     (erase-buffer)
	     (insert (org-epub-template-content-opf
		      org-epub-metadata
		      (org-epub-gen-manifest org-epub-manifest)
		      (org-epub-gen-spine '(("body-html" . "body.html")))))
	     (save-buffer 0)
	     (kill-buffer))
	   (org-epub-zip-it-up outfile org-epub-manifest org-epub-zip-dir)
	   (delete-directory org-epub-zip-dir t)
	   (message (with-output-to-string (print org-epub-manifest)))
	   (message "Generated %s" outfile)
	   (expand-file-name outfile))
       (error (delete-directory org-epub-zip-dir t)
	      (message "ox-epub eport error: %s" err)))))

;;compare org-export-options-alist
;;;###autoload
(defun org-epub-export-to-epub (&optional async subtreep visible-only ext-plist)
  "Export the current buffer to an EPUB file.

ASYNC defines wether this process should run in the background,
SUBTREEP supports narrowing of the document, VISIBLE-ONLY allows
you to export only visible parts of the document, EXT-PLIST is
the property list for the export process."
  (interactive)
  (let* ((outfile (org-export-output-file-name ".epub" subtreep)))
    (message "Output to:")
    (message outfile)
    (if async
	(org-export-async-start (lambda (f) (org-export-add-to-stack f 'odt))
	  (org-epub--export-wrapper
	   outfile
	   (org-export-as 'epub subtreep visible-only nil ext-plist)))
      (org-epub--export-wrapper
       outfile
       (org-export-as 'epub subtreep visible-only nil ext-plist)))))

(defun org-epub-template-toc-ncx (uid toc-depth title toc-nav)
  "Create the toc.ncx file.

UID is the uid/url of the file.  TOC-DEPTH is the depth of the toc
that should be shown to the readers.  TITLE is the title of the
ebook and TOC-NAV being the raw contents enclosed in navMap."
  (concat
   "<?xml version=\"1.0\"?>
<!DOCTYPE ncx PUBLIC \"-//NISO//DTD ncx 2005-1//EN\"
   \"http://www.daisy.org/z3986/2005/ncx-2005-1.dtd\">

<ncx xmlns=\"http://www.daisy.org/z3986/2005/ncx/\" version=\"2005-1\">

   <head>
      <meta name=\"dtb:uid\" content=\""
   uid
   "\"/>
      <meta name=\"dtb:depth\" content=\""
   (format "%d" toc-depth)
   "\"/>
      <meta name=\"dtb:totalPageCount\" content=\"0\"/>
      <meta name=\"dtb:maxPageNumber\" content=\"0\"/>
   </head>

   <docTitle>
      <text>"
   title
   "</text>
   </docTitle>

   <navMap>"
   toc-nav
   "</navMap>
</ncx>"))

(defun org-epub-template-content-opf (meta manifest spine)
  "Create the content.opf file.

META is a metadata PLIST.

The following arguments are XML strings: MANIFEST is the content
inside the manifest tags, this should include all user generated
html files but not things like the cover page, SPINE is an XML
string with the list of html files in reading order."
  (concat
   "<?xml version=\"1.0\"?>

<package xmlns=\"http://www.idpf.org/2007/opf\" unique-identifier=\"dcidid\"
   version=\"2.0\">

   <metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\"
      xmlns:dcterms=\"http://purl.org/dc/terms/\"
      xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
      xmlns:opf=\"http://www.idpf.org/2007/opf\">
      <dc:title>" (plist-get meta :title) "</dc:title>
      <dc:language xsi:type=\"dcterms:RFC3066\">" (plist-get meta :language) "</dc:language>
      <dc:identifier id=\"dcidid\" opf:scheme=\"URI\">"
      (plist-get meta :epub-uid)
         "</dc:identifier>
      <dc:subject>" (plist-get meta :epub-subject)
         "</dc:subject>
      <dc:description>" (plist-get meta :epub-description)

         "</dc:description>
      <dc:creator>" (plist-get meta :author) "</dc:creator>
      <dc:publisher>" (plist-get meta :epub-publisher) "</dc:publisher>
      <dc:date xsi:type=\"dcterms:W3CDTF\">" (plist-get meta :date) "</dc:date>
      <dc:rights>" (plist-get meta :epub-rights) "</dc:rights>"
      (let ((cimg (org-epub-manifest-first #'org-epub-coverimg-p)))
	(when cimg
	  (concat "<meta name=\"cover\" content=\"" (plist-get cimg :id) "\"/>")))
      "
   </metadata>

   <manifest>\n
      <item id=\"ncx\"      href=\"toc.ncx\"
         media-type=\"application/x-dtbncx+xml\" />"
      
      manifest
      
   "</manifest>

   <spine toc=\"ncx\">"
   (let ((chtml (org-epub-manifest-first #'org-epub-cover-p)))
     (when chtml
       (concat "<itemref idref=\"" (plist-get chtml :id) "\" linear=\"no\" />")))
   
   spine

   "</spine>

 <guide>"
   (let ((chtml (org-epub-manifest-first #'org-epub-cover-p)))
     (when chtml
       (concat " <reference type=\"cover\" href=\"" (plist-get chtml :filename) "\" />")))
   "
 </guide>

</package>"))

(defun org-epub-gen-manifest (files)
  "Generate the manifest XML string.

FILES is the list of files to be included in the manifest xml string."
  (mapconcat
   (lambda (file)
     (concat "<item id=\"" (plist-get file :id) "\"      href=\"" (plist-get file :filename) "\"
            media-type=\"" (plist-get file :mimetype) "\" />\n"))
   files ""))

(defun org-epub-gen-spine (files)
  "Generate the spine XML string.

FILES is the list of files to be included in the spine, these
must be in reading order."
  (mapconcat
   (lambda (file)
     (concat "<itemref idref=\"" (car file) "\" />\n"))
   files ""))

(defun org-epub-template-container ()
  "Generate the container.xml file, the root of any EPUB."
  "<?xml version=\"1.0\"?>
<container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">
   <rootfiles>
      <rootfile full-path=\"content.opf\"
      media-type=\"application/oebps-package+xml\"/>
   </rootfiles>
</container>")

(defun org-epub-template-cover (cover-file width height)
  "Generate a HTML template for the cover page.

COVER-FILE is the filename of a jpeg file, while WIDTH and HEIGHT are
properties of the image."
   (concat "<?xml version=\"1.0\" encoding=\"utf-8\"?>
 <!DOCTYPE html PUBLIC \"-//W3C//DTD XHTML 1.1//EN\" \"http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd\">
 
 <html xmlns=\"http://www.w3.org/1999/xhtml\">
 <head>
 <title></title>
 </head>
 
 <body>
 <svg version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\"
  width=\"100%\" height=\"100%\" viewBox=\"0 0 573 800\" preserveAspectRatio=\"xMidYMid meet\">
 <image xlink:href=\"" cover-file "\" height=\"" (format "%d" height) "\" width=\"" (format "%d" width) "\" />
 </svg>
 </body>
 </html>"))

(defun org-epub-template-mimetype ()
  "Generate the mimetype file for the epub."
  "application/epub+zip")

(defun org-epub-zip-it-up (epub-file files target-dir)
  "Create the .epub file by zipping up the contents.

EPUB-FILE is the target filename, FILES is the list of source
files to process, while TARGET-DIR is the directory where
exported HTML files live. This function will copy any files into
their proper place."
  (mapc #'(lambda (entry)
	    (let ((copy (org-epub-manifest-needcopy entry)))
	      (when copy
		(copy-file (car copy) (concat target-dir (cdr copy)) t))))
	files)
  (let ((default-directory target-dir)
	(meta-files '("META-INF/container.xml" "content.opf" "toc.ncx")))
    (apply 'call-process
	   (append (list org-epub-zip-command nil '(:file "zip.log") nil)
		   org-epub-zip-no-compress
		   (list epub-file
			 "mimetype")))
    (apply 'call-process org-epub-zip-command nil '(:file "zip.log") nil
	   (append org-epub-zip-compress
		   (list epub-file)
		   (append meta-files (mapcar #'(lambda (el) (plist-get el :filename)) files)))))
  (copy-file (concat target-dir epub-file) default-directory t))

(defun org-epub-generate-toc-single (headlines filename)
  "Generate a single file TOC.

HEADLINES is a list containing the abbreviated headline
information. The name of the target file is given by FILENAME."
  (let ((toc-id 0)
	(current-level 0))
    (with-output-to-string
      (mapc
       (lambda (headline)
	 (let* ((title (nth 0 headline))
		(level (nth 1 headline))
		(ref (nth 2 headline)))
	   (cl-incf toc-id)
	   (cond
	    ((< current-level level)
	     (cl-incf current-level))
	    ((> current-level level)
	     (princ "</navPoint>")
	     (while (> current-level level)
	       (cl-decf current-level)
	       (princ "</navPoint>")))
	    ((eq current-level level)
	     (princ "</navPoint>")))
	   (princ
	    (concat (format "<navPoint class=\"h%d\" id=\"%s-%d\">\n" current-level filename toc-id)
		    (format "<navLabel><text>%s</text></navLabel>\n" (org-html-encode-plain-text title))
		    (format "<content src=\"%s#%s\"/>" filename ref)))))
       headlines)
      (while (> current-level 0)
	(princ "</navPoint>")
	(cl-decf current-level)))))

(provide 'ox-epub)

;;; ox-epub.el ends here
