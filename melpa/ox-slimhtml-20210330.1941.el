;;; ox-slimhtml.el --- a minimal HTML org export backend -*- lexical-binding: t; -*-
;; Copyright (C) 2021 Free Software Foundation Inc.

;; Author: Elo Laszlo <hello at bald dot cat>
;; Created: August 2016
;; Package-Version: 20210330.1941
;; Package-X-Original-Version: 0.5.0
;; Keywords: files
;; Package-Commit: 72cffc4292c82d5f3a24717ed386a953862485d8
;; Package-Requires: ((emacs "24") (cl-lib "0.6"))

;; This file is part of GNU Emacs

;;; License:
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; slimhtml is an Emacs org mode export backend.  It is a set of
;; transcoders for common org elements which outputs minimal
;; HTML.  The aim is not to re-invent the wheel over the default
;; org-mode HTML exporter - as it tackles a much bigger, and
;; different problem - but to provide a small set of components for
;; easier customization of HTML output from org.

;;; Code:
(require 'ox-html)
(require 'cl-lib)

;; formatting
;; #+BEGIN_EXAMPLE
;;   ,*bold*                                     # <strong>bold</strong>
;;   /italic/                                   # <em>italic</em>
;;   =verbatim=                                 # <kbd>verbatim</kbd>
;; #+END_EXAMPLE

(defun ox-slimhtml-bold (bold contents info)
  "Transcode BOLD from Org to HTML.

CONTENTS is the text with bold markup.
INFO is a plist holding contextual information."
  (when contents (format "<strong>%s</strong>" contents)))

(defun ox-slimhtml-italic (italic contents info)
  "Transcode ITALIC from Org to HTML.

CONTENTS is the text with italic markup.
INFO is a plist holding contextual information."
  (when contents (format "<em>%s</em>" contents)))

(defun ox-slimhtml-verbatim (verbatim contents info)
  "Transcode VERBATIM string from Org to HTML.

CONTENTS is nil.
INFO is a plist holding contextual information."
  (let ((contents (org-html-encode-plain-text
                   (org-element-property :value verbatim))))
    (when contents (format "<kbd>%s</kbd>" contents))))

;; headlines
;; #+BEGIN_EXAMPLE
;;   ,* headline text                            # <section class="container">
;;     :PROPERTIES:                             # <h1 class="headline">headline text</h1>
;;     :attr_html: :class headline              # </section>
;;     :html_container: section
;;     :html_container_class: container
;;     :END:

;;   ,#+OPTIONS: H:[headline level]
;;   ,#+HTML_CONTAINER: [default container]
;; #+END_EXAMPLE

(defun ox-slimhtml-headline (headline contents info)
  "Transcode HEADLINE from Org to HTML.

CONTENTS is the section as defined under the HEADLINE.
INFO is a plist holding contextual information."
  (let* ((text (org-export-data (org-element-property :title headline) info))
         (level (org-export-get-relative-level headline info))
         (attributes (org-element-property :ATTR_HTML headline))
         (container (org-element-property :HTML_CONTAINER headline))
         (container-class (and container (org-element-property :HTML_CONTAINER_CLASS headline))))
    (when attributes
      (setq attributes
            (format " %s" (org-html--make-attribute-string
                           (org-export-read-attribute 'attr_html `(nil
                                                                   (attr_html ,(split-string attributes))))))))
    (concat
     (when (and container (not (string= "" container)))
       (format "<%s%s>" container (if container-class (format " class=\"%s\"" container-class) "")))
     (if (not (org-export-low-level-p headline info))
         (format "<h%d%s>%s</h%d>%s" level (or attributes "") text level (or contents ""))
       (concat
        (when (org-export-first-sibling-p headline info) "<ul>")
        (format "<li>%s%s</li>" text (or contents ""))
        (when (org-export-last-sibling-p headline info) "</ul>")))
     (when (and container (not (string= "" container)))
       (format "</%s>" (cl-subseq container 0 (cl-search " " container)))))))

;; sections

(defun ox-slimhtml-section (section contents info)
  "Transcode a SECTION element from Org to HTML.

CONTENTS is the contents of the section.
INFO is a plist holding contextual information.

Sections are child elements of org headlines;
'container' settings are found in slim-headlines."
  contents)

;; links
;; #+BEGIN_EXAMPLE
;;   ,#+attr_html: :class link                   # <a href="link" class="link">content</a>
;;   [[link][content]]

;;   ,#+OPTIONS: html-link-org-files-as-html:[t/nil] || org-html-link-org-files-as-html
;;   ,#+HTML_EXTENSION: [html] || org-html-extension

;;   ,#+OPTIONS: html-link-use-abs-url:[t/nil] || org-html-link-use-abs-url
;; #+END_EXAMPLE

(defun ox-slimhtml-link (link contents info)
  "Transcode LINK from Org to HTML.

CONTENTS is the text of the link.
INFO is a plist holding contextual information."
  (if (ox-slimhtml--immediate-child-of-p link 'link) (org-element-property :raw-link link)
    (if (not contents) (format "<em>%s</em>" (org-element-property :path link))
      (let ((link-type (org-element-property :type link))
            (href (org-element-property :raw-link link))
            (attributes (if (ox-slimhtml--immediate-child-of-p link 'paragraph)
                            (ox-slimhtml--attr (org-export-get-parent link))
                          ""))
            (element "<a href=\"%s\"%s>%s</a>"))
        (cond ((string= "file" link-type)
               (let ((html-extension (or (plist-get info :html-extension) ""))
                     (use-abs-url (plist-get info :html-link-use-abs-url))
                     (link-org-files-as-html (plist-get info :html-link-org-as-html))
                     (path (or (org-element-property :path link) "")))
                 (format element
                         (concat (if (and use-abs-url (file-name-absolute-p path)) "file:" "")
                                 (if (and link-org-files-as-html (string= "org" (downcase (or (file-name-extension path) ""))))
                                     (if (and html-extension (not (string= "" html-extension)))
                                         (concat (file-name-sans-extension path) "." html-extension)
                                       (file-name-sans-extension path))
                                   path))
                         attributes contents)))
              (t
               (format element href attributes contents)))))))

;; plain lists
;; #+BEGIN_EXAMPLE
;;   ,#+attr_html: :class this                   # <ul class="this">
;;   - item 1                                   # <li>item 1</li>
;;   - item 2                                   # <li>item 2</li>
;;                                              # </ul>

;;   + item 1                                   # <ol><li>item 1</li></ol>
;;   - definition :: list                       # <dl><dt>definition</dt><dd>list</dd></dl>
;; #+END_EXAMPLE

(defun ox-slimhtml-plain-list (plain-list contents info)
  "Transcode a PLAIN-LIST string from Org to HTML.

CONTENTS is the contents of the list element.
INFO is a plist holding contextual information."
  (when contents
    (let ((type (cl-case (org-element-property :type plain-list)
                  (ordered "ol")
                  (unordered "ul")
                  (descriptive "dl"))))
      (format "<%s%s>%s</%s>" type (ox-slimhtml--attr plain-list) contents type))))

;; paragraphs
;; #+BEGIN_EXAMPLE
;;   ,#+attr_html: :class this                   # <p class="this">content</p>
;;   content
;; #+END_EXAMPLE

(defun ox-slimhtml-paragraph (paragraph contents info)
  "Transcode a PARAGRAPH element from Org to HTML.

CONTENTS is the contents of the paragraph.
INFO is a plist holding contextual information."
  (when contents
    (if (or (ox-slimhtml--immediate-child-of-p paragraph 'item)
            (ox-slimhtml--immediate-child-of-p paragraph 'special-block))
        contents
      (if (ox-slimhtml--has-immediate-child-of-p paragraph 'link)
          (format "<p>%s</p>" contents)
        (format "<p%s>%s</p>" (ox-slimhtml--attr paragraph) contents)))))

;; examples
;; #+BEGIN_EXAMPLE
;;   ,#+BEGIN_EXAMPLE                            # content
;;   content
;;   ,#+END_EXAMPLE
;; #+END_EXAMPLE

(defun ox-slimhtml-example-block (example-block contents info)
  "Transcode an EXAMPLE-BLOCK element from Org to HTML.

CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((code (org-html-format-code example-block info)))
    (when code
      (format "<pre><code class=\"%s\">%s</code></pre>"
              (or (org-element-property :language example-block) "example")
              code))))

;; raw html
;; #+BEGIN_EXAMPLE
;;   ,#+BEGIN_EXPORT html                        # <span>export block</span>
;;     <span>export block</span>
;;   ,#+END_EXPORT

;;   ,#+BEGIN_EXPORT javascript                  # <script>console.log()</script>
;;     console.log()
;;   ,#+END_EXPORT

;;   ,#+BEGIN_EXPORT css                         # <style type="text/css">span{}</style>
;;     span {}
;;   ,#+END_EXPORT
;; #+END_EXAMPLE

(defun ox-slimhtml-export-block (export-block contents info)
  "Transcode an EXPORT-BLOCK element from Org to HTML.

CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((contents (org-element-property :value export-block))
        (language (org-element-property :type export-block)))
    (when contents
      (cond ((string= "JAVASCRIPT" language)
             (format "<script>%s</script>" contents))
            ((string= "CSS" language)
             (format "<style type=\"text/css\">%s</style>" contents))
            (t
             (org-remove-indentation contents))))))

;; snippet
;; #+BEGIN_EXAMPLE
;;   @@html:<span>snippet</span>@@              # <span>snippet</span>
;; #+END_EXAMPLE

(defun ox-slimhtml-export-snippet (export-snippet contents info)
  "Transcode a EXPORT-SNIPPET object from Org to HTML.

CONTENTS is nil.  INFO is a plist holding contextual information."
  (let ((contents (org-element-property :value export-snippet)))
    (when contents contents)))

;; special block
;; #+BEGIN_EXAMPLE
;;   ,#+attr_html: :type text/css                # <style type="text/css">
;;   ,#+BEGIN_STYLE                              # p { font-weight:500; }
;;     p { font-weight:500; }                   # </style>
;;   ,#+END_STYLE
;; #+END_EXAMPLE

(defun ox-slimhtml-special-block (special-block contents info)
  "Transcode SPECIAL-BLOCK from Org to HTML.

CONTENTS is the text within the #+BEGIN_ and #+END_ markers.
INFO is a plist holding contextual information."
  (when contents
    (let ((block-type (downcase (org-element-property :type special-block))))
      (format "<%s%s>%s</%s>" block-type (ox-slimhtml--attr special-block) contents block-type))))

;; source code
;; #+BEGIN_EXAMPLE
;;   ,#+BEGIN_SRC javascript                     # <pre>
;;     code                                     # <code class="javascript">code</code>
;;   ,#+END_SRC                                  # </pre>
;; #+END_EXAMPLE

(defun ox-slimhtml-src-block (src-block contents info)
  "Transcode SRC-BLOCK from Org to HTML.

CONTENTS is the text of a #+BEGIN_SRC...#+END_SRC block.
INFO is a plist holding contextual information."
  (let ((code (org-html-format-code src-block info))
        (language (org-element-property :language src-block)))
    (when code
      (format "<pre><code class=\"%s\"%s>%s</code></pre>"
              language (ox-slimhtml--attr src-block) code))))

;; body
;; #+BEGIN_EXAMPLE
;;   ,#+HTML_PREAMBLE: preamble {{{macro}}}      # preamble
;;   content                                    # content
;;   ,#+HTML_POSTAMBLE: postamble {{{macro}}}    # postamble
;; #+END_EXAMPLE

(defun ox-slimhtml-inner-template (contents info)
  "Return body of document string after HTML conversion.

CONTENTS is the transcoded contents string.
INFO is a plist holding export options."
  (when (and contents (not (string= "" contents)))
    (let ((container (plist-get info :html-container)))
      (concat
       (when (and container (not (string= "" container))) (format "<%s>" container))
       (or (ox-slimhtml--expand-macros (plist-get info :html-preamble) info) "")
       contents
       (or (ox-slimhtml--expand-macros (plist-get info :html-postamble) info) "")
       (when (and container (not (string= "" container)))
         (format "</%s>" (cl-subseq container 0 (cl-search " " container))))))))

;; html page
;; #+BEGIN_EXAMPLE
;;   ,#+HTML_DOCTYPE: || org-html-doctype        # <!DOCTYPE html>   ; html5
;;   ,#+HTML_HEAD: || org-html-head              # <html lang="en">  ; when language is set
;;   ,#+HTML_TITLE: %t                           #   <head>
;;   ,#+HTML_HEAD_EXTRA: || org-html-head-extra  #     head
;;   ,#+HTML_BODY_ATTR: id="test"                #     <title>document title</title>
;;   ,#+HTML_HEADER: {{{macro}}}                 #     head-extra
;;   ,#+HTML_FOOTER: {{{macro}}}                 #   </head>
;;                                              #   <body id="test">
;;                                              #     header
;;                                              #     content
;;                                              #     footer
;;                                              #   </body>
;;                                              # </html>

;;   {{{macro}}} tokens can also be set in INFO;
;;   :html-head, :html-head-extra and :html-header.

;;   :html-title is a string with optional tokens;
;;   %t is the document's #+TITLE: property.
;; #+END_EXAMPLE

(defun ox-slimhtml-template (contents info)
  "Return full document string after HTML conversion.

CONTENTS is the transcoded contents string.
INFO is a plist holding export options."
  (let ((doctype (assoc (plist-get info :html-doctype) org-html-doctype-alist))
        (language (plist-get info :language))
        (head (ox-slimhtml--expand-macros (plist-get info :html-head) info))
        (head-extra (ox-slimhtml--expand-macros (plist-get info :html-head-extra) info))
        (title (plist-get info :title))
        (title-format (plist-get info :html-title))
        (body-attr (plist-get info :html-body-attr))
        (header (plist-get info :html-header))
        (newline "\n"))
    (when (listp title)
      (setq title (car title)))
    (concat
     (when doctype (concat (cdr doctype) newline))
     "<html" (when language (concat " lang=\"" language "\"")) ">" newline
     "<head>" newline
     (when (not (string= "" head)) (concat head newline))
     (when (and title (not (string= "" title)))
       (if title-format
           (format-spec (concat "<title>" title-format "</title>\n")
                        (format-spec-make ?t title))
         (concat "<title>" title "</title>" newline)))
     (when (not (string= "" head-extra)) (concat head-extra newline))
     "</head>" newline
     "<body" (and body-attr (not (string= "" body-attr)) (format " %s" body-attr)) ">"
     (when (and header (not (string= "" header)))
       (or (ox-slimhtml--expand-macros header info) ""))
     contents
     (or (ox-slimhtml--expand-macros (plist-get info :html-footer) info) "")
     "</body>" newline
     "</html>")))

;; plain text

(defun ox-slimhtml-plain-text (plain-text info)
  "Transcode a PLAIN-TEXT string from Org to HTML.

PLAIN-TEXT is the string to transcode.
INFO is a plist holding contextual information."
  (org-html-encode-plain-text plain-text))

;; attributes

(defun ox-slimhtml--attr (element &optional property)
  "Return ELEMENT's html attribute properties as a string.

When optional argument PROPERTY is non-nil, return the value of
that property within attributes."
  (let ((attributes (org-export-read-attribute :attr_html element property)))
    (if attributes (concat " " (org-html--make-attribute-string attributes)) "")))

;; is an immediate child of [element]?

(defun ox-slimhtml--immediate-child-of-p (element container-type)
  "Is ELEMENT an immediate child of an org CONTAINER-TYPE element?"
  (let ((container (org-export-get-parent element)))
    (and (eq (org-element-type container) container-type)
         (= (org-element-property :begin element)
            (org-element-property :contents-begin container)))))

;; has an immediate child of [element-type]?

(defun ox-slimhtml--has-immediate-child-of-p (element element-type)
  "Does ELEMENT have an immediate ELEMENT-TYPE child?"
  (org-element-map element element-type
    (lambda (link) (= (org-element-property :begin link)
                      (org-element-property :contents-begin element)))
    nil t))

;; expand macros
;; Macro expansion takes place in a separate buffer - as such buffer local variables
;; are not directly available, which might be important when using self-evaluating
;; macros such as =,#+MACRO: x (eval (fn $1))=. To help with this, the original
;; =buffer-file-name= is shadowed.

(defun ox-slimhtml--expand-macros (contents info)
  "Return CONTENTS string, with macros expanded.

CONTENTS is a string, optionally with {{{macro}}}
tokens.  INFO is a plist holding export options."
  (if (cl-search "{{{" contents)
      (let* ((author (org-element-interpret-data (plist-get info :author)))
             (date (org-element-interpret-data (plist-get info :date)))
             (email (or (plist-get info :email) ""))
             (title (org-element-interpret-data (plist-get info :title)))
             (export-specific-templates
              (list (cons "author" author)
                    (cons "date"
                          (format "(eval (format-time-string \"$1\" '%s))"
                                  (org-read-date nil t date nil)))
                    (cons "email" email)
                    (cons "title" title)))
             (templates (org-combine-plists export-specific-templates
                                            org-macro-templates))
             (buffer-name buffer-file-name))
        (with-temp-buffer (insert contents)
                          (let ((buffer-file-name buffer-name))
                            (org-macro-replace-all templates))
                          (buffer-string)))
    contents))

;; org-mode publishing function
;; #+BEGIN_EXAMPLE
;;   (setq org-publish-project-alist
;;         '(("project-name"
;;            :base-directory "~/src"
;;            :publishing-directory "~/public"
;;            :publishing-function ox-slimhtml-publish-to-html)))
;; #+END_EXAMPLE

;;;###autoload
(defun ox-slimhtml-publish-to-html (plist filename pub-dir)
  "Publish an org file to html.

PLIST is the property list for the given project.  FILENAME
is the filename of the Org file to be published.  PUB-DIR is
the publishing directory.

Return output file name."
  (let ((html-extension (or (plist-get plist :html-extension) org-html-extension)))
    (org-publish-org-to 'slimhtml
                        filename
                        (if (and html-extension (not (string= "" html-extension)))
                            (concat "." html-extension) "")
                        plist
                        pub-dir)))

;; org-export backend definition
(org-export-define-backend
 'slimhtml
 '((bold . ox-slimhtml-bold)
   (example-block . ox-slimhtml-example-block)
   (export-block . ox-slimhtml-export-block)
   (export-snippet . ox-slimhtml-export-snippet)
   (headline . ox-slimhtml-headline)
   (inner-template . ox-slimhtml-inner-template)
   (italic . ox-slimhtml-italic)
   (item . org-html-item)
   (link . ox-slimhtml-link)
   (paragraph . ox-slimhtml-paragraph)
   (plain-list . ox-slimhtml-plain-list)
   (plain-text . ox-slimhtml-plain-text)
   (section . ox-slimhtml-section)
   (special-block . ox-slimhtml-special-block)
   (src-block . ox-slimhtml-src-block)
   (template . ox-slimhtml-template)
   (verbatim . ox-slimhtml-verbatim))
 :menu-entry
 '(?s "Export to slimhtml"
      ((?H "As slimhtml buffer" ox-slimhtml-export-as-html)
       (?h "As slimhtml file" ox-slimhtml-export-to-html)))
 :options-alist
 '((:html-extension "HTML_EXTENSION" nil org-html-extension)
   (:html-link-org-as-html nil "html-link-org-files-as-html" org-html-link-org-files-as-html)
   (:html-doctype "HTML_DOCTYPE" nil org-html-doctype)
   (:html-container "HTML_CONTAINER" nil org-html-container-element t)
   (:html-link-use-abs-url nil "html-link-use-abs-url" org-html-link-use-abs-url)
   (:html-link-home "HTML_LINK_HOME" nil org-html-link-home)
   (:html-preamble "HTML_PREAMBLE" nil "" newline)
   (:html-postamble "HTML_POSTAMBLE" nil "" newline)
   (:html-head "HTML_HEAD" nil org-html-head newline)
   (:html-head-extra "HTML_HEAD_EXTRA" nil org-html-head-extra newline)
   (:html-header "HTML_HEADER" nil "" newline)
   (:html-footer "HTML_FOOTER" nil "" newline)
   (:html-title "HTML_TITLE" nil "%t" t)
   (:html-body-attr "HTML_BODY_ATTR" nil "" t)))

;;;###autoload
(defun ox-slimhtml-export-as-html
    (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a SLIMHTML buffer.

Export as `org-html-export-as-html' does, with slimhtml
org-export-backend.

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

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Export is done in a buffer named \"*Org SLIMHTML export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'slimhtml "*Org SLIMHTML Export*"
    async subtreep visible-only body-only ext-plist
    (lambda () (set-auto-mode t))))

;;;###autoload
(defun ox-slimhtml-export-to-html (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to an HTML file.

Export as `org-html-export-as-html' does, with slimhtml
org-export-backend.

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

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return output file's name."
  (interactive)
  (let* ((extension (concat "." (or (plist-get ext-plist :html-extension)
                                    org-html-extension
                                    "html")))
         (file (org-export-output-file-name extension subtreep))
         (org-export-coding-system org-html-coding-system))
    (org-export-to-file 'slimhtml file
      async subtreep visible-only body-only ext-plist)))

(provide 'ox-slimhtml)
;;; ox-slimhtml.el ends here
