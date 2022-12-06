;;; ox-spectacle.el --- Spectacle.js Presentation Back-End for Org Export Engine -*- lexical-binding: t -*-

;; Copyright (C) 2018-2022 lorniu <lorniu@gmail.com>

;; Author: lorniu <lorniu@gmail.com>
;; Created: 2018-11-11
;; URL: https://github.com/lorniu/ox-spectacle
;; Package-Version: 20221206.1604
;; Package-Commit: 84999eb88ae1a1855a03b4d24d8fa72e22ad82a3
;; Package-Requires: ((emacs "28.1") (org "8.3"))
;; Keywords: convenience
;; Version: 2.0

;; This file is not part of GNU Emacs.

;;; Copyright Notice:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Spectacle.js is the best tool to create slides with html5, and
;; this ox-spectacle.el is the best way to create slides with Spectacle.js.
;;
;; Org-Mode + React, powerful! Have a try, you will like it :)
;;
;; First, make sure your emacs and org-mode is ok.
;;
;; Second, you should learn some html and react.
;;
;; Then, install this, and add to your config file:
;;
;;   (require 'ox-spectacle)
;;
;; All ready.
;;
;; Create one org file, put your ideas there.
;; Then export them to a html file and open it with `C-c C-e s o`.
;;
;; The amazing presentation is in front of you. Enjoy it.
;;
;; View README.org for detail.

;;; Code:

(require 'cl-lib)
(require 'ox-html)


;;; Backend

(org-export-define-derived-backend 'spectacle 'html
  :menu-entry
  '(?s "Export to Spectacle.js Presentation"
       ((?S "As buffer" ox-spectacle-export-to-buffer)
	    (?s "As html file" ox-spectacle-export-to-file)
        (?o "As html file and open" ox-spectacle-export-to-file-and-browser)))

  :options-alist
  '((:html-doctype           nil              nil ox-spectacle--doctype)
    (:theme                  "THEME"          nil ox-spectacle-theme)
    (:template               "TEMPLATE"       nil ox-spectacle-template)
    (:transition             "TRANSITION"     nil ox-spectacle-transition)
    (:text-type              "TEXT_TYPE"      nil ox-spectacle-text-type)
    (:deck-props             "DECK_PROPS"     nil ox-spectacle-deck-props space)
    (:export-level           "EXPORT_LEVEL"   1   ox-spectacle-export-level))

  :translate-alist
  '((template        . ox-spectacle--template)
    (inner-template  . ox-spectacle--inner-template)
    (headline        . ox-spectacle--headline)
    (section         . ox-spectacle--section)
    (src-block       . ox-spectacle--src-block)
    (quote-block     . ox-spectacle--quote-block)
    (center-block    . ox-spectacle--center-block)
    (code            . ox-spectacle--code)
    (verbatim        . ox-spectacle--verbatim)
    (plain-list      . ox-spectacle--plain-list)
    (item            . ox-spectacle--item)
    (table           . ox-spectacle--table)
    (table-row       . ox-spectacle--table-row)
    (table-cell      . ox-spectacle--table-cell)
    (link            . ox-spectacle--link)
    (paragraph       . ox-spectacle--paragraph)
    (plain-text      . ox-spectacle--plain-text)
    (latex-fragment  . ox-spectacle--latex-fragment))

  :filters-alist
  '((:filter-options . ox-spectacle--init-filter)
    (:filter-parse-tree . ox-spectacle--parse-tree-filter)
    (:filter-final-output . org-html-final-function)))


;;; Variables

(defgroup ox-spectacle nil
  "Options for exporting Orgmode files to spectacle HTML pressentations."
  :tag "Org Export Spectacle"
  :prefix 'ox-spectacle-
  :group 'org-export)

(defvar ox-spectacle-debug nil)

(defcustom ox-spectacle-theme nil
  "Default theme."
  :type 'string)

(defcustom ox-spectacle-template "template"
  "Default template."
  :type 'string)

(defcustom ox-spectacle-transition nil
  "Default transition."
  :type 'string)

(defcustom ox-spectacle-text-type "Text"
  "Component used for plain text.
It should be a spectacle element as `Text' or a html tag as `p'."
  :type 'string)

(defcustom ox-spectacle-export-level 1
  "How to embed link."
  :type 'integer)

(defcustom ox-spectacle-scripts
  (let ((react-env (if ox-spectacle-debug "development" "production.min")))
    (list (format "https://unpkg.com/react@18.1.0/umd/react.%s.js" react-env)
          (format "https://unpkg.com/react-dom@18.1.0/umd/react-dom.%s.js" react-env)
          (format "https://unpkg.com/react-is@18.1.0/umd/react-is.%s.js" react-env)
          "https://unpkg.com/prop-types@15.7.2/prop-types.min.js"
          "https://unpkg.com/spectacle@^9/dist/spectacle.min.js"
          "https://unpkg.com/htm"))
  "Core scripts."
  :type '(repeat string))

(defcustom ox-spectacle-extra-scripts nil
  "Script not core."
  :type '(repeat string))

(defcustom ox-spectacle-deck-props nil
  "Deck tag or extra props."
  :type '(repeat string))

(defcustom ox-spectacle-default-template
  "({ slideNumber, numberOfSlides }) => html`
<${FlexBox} justifyContent='space-between' position='absolute' bottom=${0} width=${1}>
  <${Box} padding='0 1em' />
  <${FlexBox} padding='0.5em'>
    <${Progress} size=${8} />
    <${Text} fontSize=${15}>${slideNumber}/${numberOfSlides}</${Text}>
  </${FlexBox}>
</${FlexBox}>`"
  "Template definition named as `template'."
  :type 'string)

(defvar ox-spectacle-cache-file-tpl
  (locate-user-emacs-file "ox-spectacle-scripts-%s.js"))

(defvar ox-spectacle--components
  '("Deck" "Slide" "SlideContext" "SlideLayout"
    "Box" "FlexBox" "Grid"
    "Heading" "Text" "Link" "Image" "FullSizeImage" "SpectacleLogo"
    "UnorderedList"  "OrderedList" "ListItem"
    "Table" "TableCell" "TableRow" "TableHeader" "TableBody"
    "CodePane" "CodeSpan" "Quote"
    "Markdown" "MarkdownSlideSet" "MarkdownSlide" "MarkdownPreHelper"
    "Appear" "Stepper"
    "SpectacleTheme" "SpectacleThemeOverrides"
    "CommandBar" "FullScreen" "Progress" "AnimatedProgress" "Notes"))

(defvar ox-spectacle--utils
  '("defaultTheme" "fadeTransition" "slideTransition" "defaultTransition"
    "useSteps" "useMousetrap"
    "mdxComponentMap" "indentNormalizer"
    "removeNotes" "isolateNotes"))

(defvar ox-spectacle--doctype "xhtml")

(defvar ox-spectacle--extra-css nil)
(defvar ox-spectacle--extra-javascript nil)
(defvar ox-spectacle--extra-header nil)
(defvar ox-spectacle--user-templates nil)

(defconst ox-spectacle--page-html
  "<html>
<head>
  <meta charset='UTF-8' />
  <meta name='viewport' content='width=device-width, initial-scale=1' />
  <meta http-equiv='X-UA-Compatible' content='IE=edge,chrome=1' />
  <title>%s</title>
%s%s%s%s
</head>

<body>
  <div id='root'></div>
  <script type='module'>

    /* imports */

    const { %s } = Spectacle;
    const { %s } = Spectacle;
    const html = htm.bind(React.createElement);

    /* other components */

    const MyLink = React.forwardRef((props, ref) => {
       // TODO: location not refresh... why?
       const id = props.id;
       if (/\\d+/.test(id)) {
           const { skipTo } = React.useContext(Spectacle.DeckContext);
           return html`<${Link} ref=${ref} onClick=${() => {event.preventDefault();skipTo({slideIndex: id})}} ...${props}></${Link}>`;
       }
       return html`<${Link} ...${props} ref=${ref}></${Link}>`;
    });

    /* default template */

    let template = %s;
%s%s

    /* presentation definition begin */

    const Presentation = () => html`<${%s}%s%s%s%s>\n
%s\n
</${%s}>`;

    /* presentation definition finished */

    ReactDOM.createRoot(document.getElementById('root')).render(html`<${Presentation}/>`);

    /* presentation rendered, all finished */

  </script>
</body>
</html>")


;;; Utils

(defun ox-spectacle--export-level (info)
  "Get the export level from INFO."
  (let ((lv (plist-get info :export-level)))
    (if (stringp lv) (string-to-number lv) lv)))

(defun ox-spectacle--fetch-content (path)
  "Return content of PATH, that is a file or url."
  (let ((urlp (string-match-p "^\\(http\\|ftp\\)" path)))
    (condition-case err
        (with-temp-buffer
          (if urlp
              (url-insert-file-contents-literally path)
            (insert-file-contents-literally path))
          (buffer-string))
      (error (user-error "Get content failed for %s %s" path (cdr err))))))

(defun ox-spectacle--make-scripts (info &optional forcenew)
  "Generate the scripts content.
INFO is a plist holding export options.
When FORCENEW is t then try to refresh the cache."
  (let ((lv (ox-spectacle--export-level info))
        (scripts (append ox-spectacle-scripts ox-spectacle-extra-scripts)))
    (if (>= lv 2)
        (let* ((name (md5 (mapconcat #'identity scripts)))
               (file (format ox-spectacle-cache-file-tpl name)))
          (when (or forcenew (not (file-exists-p file)))
            (condition-case nil
                (with-temp-file file
                  (dolist (path scripts)
                    (insert (ox-spectacle--fetch-content path))
                    (goto-char (point-max))
                    (insert "\n"))
                  (message "Caching scripts to %s" file))
              (error (delete-file file)
                     (user-error "Fetch scripts failed"))))
          (with-temp-buffer
            (insert-file-contents file)
            (format "  <script>\n%s\n</script>" (string-trim (buffer-string)))))
      (cl-loop for s in scripts
               concat (format "\n<script src='%s'></script>" s)))))

(defun ox-spectacle--data-uri (path)
  "Generate the inline data used in html for PATH.
If PATH is remote, download it."
  (let* ((ext (car (split-string (file-name-extension path) "?")))
         (content (ox-spectacle--fetch-content path))
         (svgp (string-equal "svg" ext))
         (type (if svgp "svg+xml;charset=utf-8" (concat ext ";base64")))
         (data (if svgp (string-replace "#" "%23" (string-replace "\"" "'" content))
                 (base64-encode-string content 'no-line-break))))
    (format "data:image/%s,%s" type data)))

(defun ox-spectacle--declare-components ()
  "Return all components declared with #+DECLARE_COMPONENTS.
It should be the components defined in buffer scripts or external."
  (save-excursion
    (goto-char (point-min))
    (let ((case-fold-search nil))
      (when (and (re-search-forward "^\\(?:\\(#\\)\\+DECLARE_COMPONENTS:[ \t]*\\(.*\\)\\|\\(\\*\\)\\)" nil t)
                 (string= (match-string 1) "#"))
        (split-string (string-trim (match-string 2)) " " t)))))

(defun ox-spectacle--available-components ()
  "All components available."
  (append ox-spectacle--components (ox-spectacle--declare-components)))

(defun ox-spectacle--get-headlines (element &optional with-self)
  "Collect all ancestor headlines of ELEMENT.
When ELEMENT is headline and WITH-SELF is t, then add itself to the result."
  (let (hls (p (org-element-lineage element '(headline) with-self)))
    (while p
      (push p hls)
      (setq p (org-element-lineage p '(headline))))
    hls))

(defmacro ox-spectacle--pop-from-plist (plist &rest properties)
  "Pop the values with key of PROPERTIES in PLIST."
  (cl-with-gensyms (ps rs pps)
    `(let (,ps ,rs (,pps ',properties))
       (while ,plist
         (if (memq (car ,plist) ,pps)
             (setq ,rs (plist-put ,rs (car ,plist) (cadr ,plist)))
	       (setq ,ps (plist-put ,ps (car ,plist) (cadr ,plist))))
         (setq ,plist (cddr ,plist)))
       (setq ,plist ,ps)
       ,rs)))

(defun ox-spectacle--wa (s &optional prefix suffix)
  "Try to trim S, and add nessesary PREFIX and SUFFIX."
  (if s
      (let ((a (org-trim s)))
        (if (org-string-nw-p a) (concat (or prefix " ") a suffix) ""))
    ""))

(defun ox-spectacle--make-attribute-string (attributes)
  "Override ‘org-html--make-attribute-string’, make ATTRIBUTES a string."
  (let (output)
    (dolist (item attributes (mapconcat 'identity (nreverse output) " "))
      (cond ((null item) (pop output))
            ((symbolp item) (push (substring (symbol-name item) 1) output))
            (t (let ((key (car output))
                     (value (org-html-encode-plain-text item)))
                 (cond ((string-match-p "^{.*}$" value)
                        (setq value (concat "$" value)))
                       ((string-match "^['\"]\\(.*\\)['\"]$" value)
                        (setq value (match-string 1 value)))
                       (t (setq value (replace-regexp-in-string "\"" "&quot;" value t))))
                 (setcar output (format (if (string-match-p "^\\${.*}$" value) "%s=%s" "%s=\"%s\"")
                                        key value))))))))

(defmacro ox-spectacle-advice (&rest body)
  "Add advices to BODY."
  `(cl-letf (((symbol-function 'string-trim) 'org-trim)
             ((symbol-function 'org-html--make-attribute-string) 'ox-spectacle--make-attribute-string))
     ,@body))


;;; Filters and Transcoders

(defun ox-spectacle--init-filter (exp-plist backend)
  "Do the extra inital things.
EXP-PLIST is a plist containing export options.  BACKEND is the
export back-end currently used."
  (setq ox-spectacle--extra-css nil
        ox-spectacle--extra-javascript nil
        ox-spectacle--extra-header nil
        ox-spectacle--user-templates nil)
  (org-html-infojs-install-script exp-plist backend))

(defun ox-spectacle--parse-tree-filter (data _backend info)
  "Filter the buffer tree before export.
DATA is a parse tree. INFO is a plist."
  (org-export-insert-image-links data info org-html-inline-image-rules))

(defun ox-spectacle--template (body info)
  "Return complete document string after HTML conversion.
BODY is the transcoded contents string. INFO is a plist
holding export options."
  (let* ((deckprops (string-trim
                     (ox-spectacle--filter-image (org-export-data (plist-get info :deck-props) info) info)))
         (decktag (when (string-match "^<\\([a-zA-Z0-9]+\\)>" (or (car (string-split deckprops)) ""))
                    (match-string 1 deckprops)))
         (deckattr (string-replace "={" "=${" (if decktag (cl-subseq deckprops (+ 2 (length decktag))) deckprops)))
         (mkattr (lambda (key)
                   (let ((r (org-export-data (plist-get info (intern (format ":%s" key))) info)))
                     (if (> (length r) 0) (ox-spectacle--wa (format "%s=${%s}" key r)) "")))))
    (format ox-spectacle--page-html
            (org-export-data (plist-get info :title) info)
            (ox-spectacle--wa (org-html--build-mathjax-config info) "\n<!-- MathJax Setup -->\n\n" "\n")
            (ox-spectacle--wa (ox-spectacle--make-scripts info) "\n<!-- core scripts -->\n\n" "\n")
            (ox-spectacle--wa ox-spectacle--extra-header "\n<!-- extra head catch from the org file -->\n\n" "\n")
            (ox-spectacle--wa ox-spectacle--extra-css "\n<!-- extra css catch from the org file -->\n\n<style>\n" "\n</style>\n")
            (mapconcat #'identity ox-spectacle--components ", ")
            (mapconcat #'identity ox-spectacle--utils ", ")
            ox-spectacle-default-template
            (ox-spectacle--wa ox-spectacle--user-templates "\n    /* user templates defined in org file */\n\n" "\n")
            (ox-spectacle--wa ox-spectacle--extra-javascript "\n    /* user scripts defined in org file */\n\n" "\n")
            (or decktag "Deck")
            (ox-spectacle--wa deckattr)
            (funcall mkattr 'theme)
            (funcall mkattr 'template)
            (funcall mkattr 'transition)
            (string-trim body)
            (or decktag "Deck"))))

(defun ox-spectacle--inner-template (contents _info)
  "Return body of document string after HTML conversion.
CONTENTS is the transcoded contents string. INFO is a plist
holding export options."
  contents)

(defun ox-spectacle--headline (headline contents info)
  "Transcode a HEADLINE element from Org to HTML.
CONTENTS holds the contents of the headline.  INFO is a plist
holding contextual information."
  (let* ((case-fold-search nil)
         (title (org-export-data (org-element-property :title headline) info))
         (level (org-element-property :level headline))
         (type (org-element-property :TYPE headline))
         (layout (org-element-property :LAYOUT headline))
         (regexp (format "\\(%s\\)" (mapconcat #'identity (ox-spectacle--available-components) "\\|")))
         (attrs (when-let ((s (ox-spectacle--wa (org-element-property :PROPS headline))))
                  (string-replace "={" "=${" s)))
         (transition (when-let ((ts (org-element-property :TRANSITION headline)))
                       (concat " transition=" (if (string-prefix-p "{" ts) "$") ts)))
         (tag type)
         (id-suffix (mapconcat #'number-to-string (org-export-get-headline-number headline info) "_"))
         id prefix)
    (let* ((headlines (ox-spectacle--get-headlines headline t))
           (rtitle (org-element-property :raw-value (car headlines))))
      ;; the special <config> section
      (if (string-equal-ignore-case rtitle "<config>")
          (let ((tpl-regexp "^<t\\(?:emplate\\|\\)>[ \t]*\\(.+\\)"))
            (cond
             ;; take <template> section as a template definition
             ((and (= level 2) (string-match tpl-regexp title)) ; Template setting
              (if-let ((name (match-string 1 title)))
                  (setq ox-spectacle--user-templates
                        (concat ox-spectacle--user-templates
                                "\n    let " name " = ({ slideNumber, numberOfSlides }) => html`\n"
                                contents "`;\n"))
                (user-error "No name found on <Config/Template>")))
             ;; when under <template> section, return contents directly
             ((and (> level 2) (string-match-p tpl-regexp (org-element-property :raw-value (cadr headlines))))
              contents)
             ;; others, ignore, just catch the contents in src-block parsing
             (t "")))
        ;; normal headline
        (when (and (null tag) (string-match (format "^<\\${\\(?:%s\\|SlideLayout\\.[a-zA-Z0-9]+\\)}\\( .*\\|\\)>$" regexp) title))
          (setq tag (match-string 1 title)
                attrs (concat attrs (ox-spectacle--wa (match-string 2 title)))))
        (setq attrs (ox-spectacle--filter-image attrs info))
        (when (= level 1)
          (setq tag (if layout (format "SlideLayout.%s" layout) "Slide")))
        (unless tag (setq tag "Box"))
        (when (string-match-p "Slide\\|FlexBox\\|Grid\\|SlideLayout" tag) ; only add id to these tags
          (setq id (concat " id='" (downcase tag) "-" id-suffix "'")))
        (when (string-match-p "Slide" tag) ; add comment as delimiter line for every slide/slidelayout
          (setq prefix (format "\n<!------ slide (id: slide-%s) begin ------>\n\n" id-suffix)))
        (if (string-match-p regexp tag) (setq tag (format "${%s}" tag)))
        (concat prefix "<" tag id attrs transition ">\n" contents "</" tag ">")))))

(defun ox-spectacle--section (_section contents _info)
  "Transcode a SECTION element from Org to HTML.
CONTENTS holds the contents of the section.  INFO is a plist
holding contextual information."
  contents)

(defun ox-spectacle--src-block (element _content _info)
  "Transcode a src-block ELEMENT from Org to HTML.
CONTENTS holds the contents of the item.  INFO is a plist holding
contextual information."
  (let* ((lang (org-element-property :language element))
         (code (org-element-property :value element))
         (linum (org-element-property :number-lines element))
         (attrs (org-export-read-attribute :attr_html element))
         (code-attrs (ox-spectacle--pop-from-plist attrs :showLineNumbers :highlightRanges :stepIndex :theme))
         (attrs (ox-spectacle--wa (org-html--make-attribute-string attrs)))
         (code-attrs (ox-spectacle--wa (org-html--make-attribute-string code-attrs)))
         (root (car (ox-spectacle--get-headlines element))))
    (if (string-equal-ignore-case (org-element-property :raw-value root) "<config>")
        (pcase lang
          ("html" (setq ox-spectacle--extra-header
                        (concat ox-spectacle--extra-header "\n\n" code)))
          ("css" (setq ox-spectacle--extra-css
                       (concat ox-spectacle--extra-css "\n" code)))
          ((or "js" "javascript") (setq ox-spectacle--extra-javascript
                                        (concat ox-spectacle--extra-javascript "\n" code))))
      (format "<${Box}%s><${CodePane}%s%s%s>\n${`\n%s\n`}\n</${CodePane}></${Box}>"
              attrs
              (if lang (concat " language='" lang "'") "")
              (if linum "" (concat " showLineNumbers=${false}"))
              code-attrs code))))

(defun ox-spectacle--quote-block (quote-block contents _info)
  "Transcode a QUOTE-BLOCK element from Org to HTML.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (let* ((attrs (org-export-read-attribute :attr_html quote-block))
         (sattrs (ox-spectacle--wa (org-html--make-attribute-string attrs))))
    (format "<${Quote}%s>%s</${Quote}>" sattrs contents)))

(defun ox-spectacle--center-block (_center-block contents _info)
  "Transcode a CENTER-BLOCK element from Org to HTML.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (format "<${FlexBox} alignItems=\"center\"><div>\n%s\n</div></${FlexBox}>" contents))

(defun ox-spectacle--code (code _contents _info)
  "Transcode CODE from Org to HTML."
  (format "<${CodeSpan}>${`%s`}</${CodeSpan}>"
          (org-element-property :value code)))

(defun ox-spectacle--verbatim (verbatim contents info)
  "Transcode VERBATIM from Org to HTML.
CONTENTS is the contents, INFO is a plist
holding export options."
  (ox-spectacle--code verbatim contents info))

(defun ox-spectacle--plain-list (plain-list contents _info)
  "Transcode a PLAIN-LIST element from Org to HTML.
CONTENTS is the contents of the list."
  (let* ((ordered (eq (org-element-property :type plain-list) 'ordered))
         (attrs (ox-spectacle--wa
                 (org-html--make-attribute-string
                  (org-export-read-attribute :attr_html plain-list))))
         (tag (if ordered "OrderedList" "UnorderedList")))
    (format "<${%s}%s>\n%s</${%s}>\n" tag attrs contents tag)))

(defun ox-spectacle--item (_item contents _info)
  "Transcode an _ITEM element from Org to HTML.
CONTENTS holds the contents of the item."
  (let (appearp priority attrs)
    ;; <A>, <N>: Make it appear
    (when (string-match "^<\\([A0-9]\\)\\([^>]*\\|$\\)>" contents)
      (setq appearp t
            priority (when-let ((s (match-string 1 contents)))
                       (if (string-equal s "A") nil s))
            attrs (when-let ((s (ox-spectacle--wa (match-string 2 contents))))
                    (string-replace "={" "=${" s))
            contents (cl-subseq contents (length (match-string 0 contents)))))
    (if appearp
        (concat "<${Appear}" (if priority (format " priority=${%s}" priority)) (ox-spectacle--wa attrs) ">"
                "<${ListItem}>" (ox-spectacle--wa contents) "</${ListItem}>"
                "</${Appear}>")
      (concat "  <${ListItem}>" (ox-spectacle--wa contents) "</${ListItem}>"))))

(defun ox-spectacle--table (table contents _info)
  "Transcode a TABLE element from Org to HTML.
CONTENTS is the contents of the table."
  (let ((attrs (ox-spectacle--wa
                (org-html--make-attribute-string
                 (org-export-read-attribute :attr_html table)))))
    (format "<${Table}%s>\n%s</${Table}>" attrs contents)))

(defun ox-spectacle--table-row (table-row contents info)
  "Transcode a TABLE-ROW element from Org to HTML.
CONTENTS is the contents of the row.  INFO is a plist used as a
communication channel."
  (when (eq (org-element-property :type table-row) 'standard)
    (let* ((group (org-export-table-row-group table-row info))
	       (start-group-p (org-export-table-row-starts-rowgroup-p table-row info))
	       (end-group-p (org-export-table-row-ends-rowgroup-p table-row info))
           (row-open-tag "<${TableRow}>")
           (row-close-tag "</${TableRow}>")
	       (group-tags (cond ((not (= 1 group))
                              '("\n<${TableBody}>" . "\n</${TableBody}>"))
	                         ((org-export-table-has-header-p (org-export-get-parent-table table-row) info)
	                          '("<${TableHeader}>" . "\n</${TableHeader}>"))
	                         (t
                              '("\n<${TableBody}>" . "\n</${TableBody}>")))))
      (concat (and start-group-p (car group-tags))
	          (concat "\n" row-open-tag contents "\n" row-close-tag)
	          (and end-group-p (cdr group-tags))))))

(defun ox-spectacle--table-cell (_table-cell contents info)
  "Transcode a TABLE-CELL element from Org to HTML.
CONTENTS is nil.  INFO is a plist used as a communication
channel."
  (setq contents (org-html-plain-text (or contents "") info))
  (format "  \n<${TableCell}>%s</${TableCell}>" contents))

(defun ox-spectacle--format-image (path attrs info)
  "Parse image link.
PATH maybe a remote url or local file. ATTRS and INFO is list."
  (let* ((lv (ox-spectacle--export-level info))
         (src (if (< lv 3) path (ox-spectacle--data-uri path))))
    (org-html-close-tag
     "${Image}"
     (concat
      (org-html--make-attribute-string attrs)
      (format " src=\"%s\" alt=\"%s\"" src (file-name-nondirectory path)))
     info)))

(defun ox-spectacle--link (link desc info)
  "Transcode a LINK object from Org to HTML.
DESC is the description part of the link, or the empty string.
INFO is a plist holding contextual information.  See
`org-export-data'."
  (let* ((type (org-element-property :type link))
	     (raw-path (org-element-property :path link))
         (raw-link (org-element-property :raw-link link))
	     (desc (org-string-nw-p desc))
	     (path (cond ((string= type "file")
	                  (org-export-file-uri raw-path))
	                 ((member type '("http" "https" "ftp" "mailto" "news"))
	                  (url-encode-url (org-link-unescape (concat type ":" raw-path))))
	                 (t raw-path)))
	     (attrs (let* ((parent (org-export-get-parent-element link))
		               (link (let ((container (org-export-get-parent link)))
			                   (if (and (eq (org-element-type container) 'link)
                                        (org-html-inline-image-p link info))
			                       container
			                     link))))
	              (and (eq (org-element-map parent 'link 'identity info t) link)
		               (org-export-read-attribute :attr_html parent))))
	     (sattrs (ox-spectacle--wa (org-html--make-attribute-string attrs))))
    (cond
     ;; Link type is handled by a special function.
     ((org-export-custom-protocol-maybe link desc 'html))
     ;; Image file.
     ((and (plist-get info :html-inline-images)
	       (org-export-inline-image-p link (plist-get info :html-inline-image-rules)))
      (ox-spectacle--format-image path attrs info))
     ;; Links pointing to a headline
     ((member type '("custom-id" "id"))
      (let* ((loc (org-export-resolve-id-link link info))
             (loctype (org-element-type loc))
             (destination loc)
             (id (org-element-property :CUSTOM_ID loc)))
        (when-let ((hd (and loctype
                            (not (member loctype '(headline plain-text)))
                            (car (last (org-element-lineage loc 'headline))))))
          (setq destination hd))
	    (if (equal (org-element-type destination) 'headline)
	        (let* ((headlines (cl-remove-if
                               ;; make sure ignore <config> section
                               (lambda (hl) (string-equal-ignore-case (org-element-property :raw-value hl) "<config>"))
                               (org-export-collect-headlines info 1)))
                   (idx (cl-position destination headlines :test #'equal))
		           (desc (if (and (org-export-numbered-headline-p loc info) (not desc))
		                     (mapconcat #'number-to-string (org-export-get-headline-number loc info) ".")
		                   (or desc (org-export-data (org-element-property :title loc) info)))))
              (format "<${MyLink} id=\"%s\">%s</${MyLink}>" idx desc))
	      (format "<${link} href=\"#%s\"%s>%s</${Link}>" (or id path) sattrs (or desc raw-link)))))
     ;; External link.
     (t (format "<${Link} href=\"%s\"%s>%s</${Link}>"
                (if path (org-html-encode-plain-text path) "#") sattrs
                (or desc (org-link-unescape path)))))))

(defun ox-spectacle--paragraph (paragraph contents info)
  "Transcode a PARAGRAPH element from Org to HTML.
CONTENTS is the contents of the paragraph, as a string.  INFO is
the plist used as a communication channel."
  (let* ((headline (org-element-lineage paragraph '(headline)))
         (attrs (org-export-read-attribute :attr_html paragraph))
         (type (plist-get (ox-spectacle--pop-from-plist attrs :type) :type))
         (attrs (ox-spectacle--wa (org-html--make-attribute-string attrs)))
         (regexp (format "\\(%s\\)" (mapconcat #'identity (ox-spectacle--available-components) "\\|")))
         (parentype (org-element-type (org-export-get-parent paragraph)))
         (notep (string-match-p "<notes.*>" (or (org-element-property :raw-value headline) "")))
         tag)
    (if (or (eq parentype 'item)
            (eq parentype 'quote-block)
            (org-html-standalone-image-p paragraph info))
        contents
      ;; if <Element> style, insert props into proper place directly,
      ;; same as html paragraph under <Notes> section
      (when (or (string-match-p (format "^[ \t]*</?${%s}" regexp) contents)
                (and notep (string-match-p "^[ \t]*<[a-zA-Z0-9]+.*>" contents)))
        (setq contents (with-temp-buffer
                         (insert contents)
                         (goto-char (point-min))
                         (search-forward ">")
                         (backward-char)
                         (insert (ox-spectacle--wa attrs))
                         (concat (ox-spectacle--filter-image (buffer-substring (point-min) (point)) info)
                                 (buffer-substring (point) (point-max))))
              tag t))
      (setq tag (or type (if tag nil (if notep "p" (plist-get info :text-type)))))
      ;; add ${} for component tag
      (when (and tag (string-match-p regexp tag))
        (setq tag (format "${%s}" tag)))
      (concat (if tag (format "<%s%s>%s</%s>" tag attrs (string-trim contents) tag) contents)))))

(defun ox-spectacle--plain-text (text info)
  "Transcode a TEXT string from Org to HTML.
TEXT is the string to transcode.  INFO is a plist holding
contextual information."
  ;; wrap Component with ${}, and add nessessary $ to its attrs
  ;; don't forget SlideLayout.Xxx
  (setq text (replace-regexp-in-string
              (format "<\\(/?%s\\|SlideLayout\\.[a-zA-Z0-9]+\\)\\(\\(?: \\|$\\)[^>]*\\|\\)>"
                      (mapconcat #'identity (ox-spectacle--available-components) "\\|"))
              (lambda (old)
                (save-match-data
                  (let ((tag (match-string 1 old))
                        (attrs (or (match-string 2 old) "")))
                    (if (string-prefix-p "/" tag)
                        (format "</${%s}>" (cl-subseq tag 1))
                      (format "<${%s}%s>" tag (string-replace "={" "=${" attrs))))))
              text t t))
  ;; add $ for plain html tag, make it can use react syntax
  (when (string-match-p (format "<\\(%s\\)[ \t]"
                                (mapconcat #'identity
                                           '("h1" "h2" "h3" "h4" "h5" "div" "section" "p" "span"
                                             "small" "ul" "ol" "li" "hr" "a" "img" "button")
                                           "\\|"))
                        text)
    (setq text (string-replace "={" "=${" text)))
  (let ((org-html-protect-char-alist nil))
    (setq text (org-html-plain-text text info))))

(defun ox-spectacle--latex-fragment (latex-fragment _contents info)
  "Transcode a LATEX-FRAGMENT object from Org to HTML.
CONTENTS is nil. INFO is a plist holding contextual information."
  (let* ((latex-frag (org-element-property :value latex-fragment))
         (r (org-html-format-latex latex-frag 'mathjax info)))
    (string-replace "\\" "\\\\" r)))

(defun ox-spectacle--filter-image (attrs info)
  "Replace all url in ATTRS to inline data.
If url is remote, download it! INFO is a plist holding
contextual information."
  (if (and (> (length attrs) 10)
           (>= (ox-spectacle--export-level info) 3))
      (replace-regexp-in-string
       "url(\\([^)]+\\))"
       (lambda (old) (save-match-data (ox-spectacle--data-uri (match-string 1 old))))
       attrs nil nil 1)
    attrs))


;;; Mode

(defvar ox-spectacle-minor-mode-map nil)

(defun ox-spectacle-completion-at-point ()
  "Complete component name with capf as possible."
  (let* ((bds (bounds-of-thing-at-point 'symbol))
         (start (let ((p (car bds)))
                  (cond ((equal (char-after p) ?<) (+ p 1))
                        ((equal (char-before p) ?/) p))))
         (end (cdr bds))
         (cands (append '("config" "template") (ox-spectacle--available-components))))
    (when (and start (> end start))
      (list start end (completion-table-case-fold cands) ::exclusive 'no))))

(define-minor-mode ox-spectacle-minor-mode
  "Add some features to current org buffer for better Spectacle Slides writing."
  :group 'ox-spectacle
  :lighter " Spectable"
  :keymap ox-spectacle-minor-mode-map
  (if (derived-mode-p 'org-mode)
      (let* ((kws  `((,(format "</?\\(%s\\)\\(?:>\\|[ \t\n]\\)"
                               (mapconcat #'identity
                                          (append '("template") (ox-spectacle--available-components))
                                          "\\|"))
                      (1 font-lock-function-name-face))
                     ("\\(?:^\\|[ \t]\\)\\([_[:alpha:]][-_.[:alnum:]]*\\)=[\"'{]"
                      1 font-lock-variable-name-face)))
             (act   (lambda () ; use closure to avoid changement
                      (font-lock-add-keywords nil kws)
                      (font-lock-flush)
                      (add-hook 'completion-at-point-functions 'ox-spectacle-completion-at-point nil 'local)))
             (inact (lambda ()
                      (font-lock-remove-keywords nil kws)
                      (font-lock-flush)
                      (remove-hook 'completion-at-point-functions 'ox-spectacle-completion-at-point 'local))))
        (funcall (if ox-spectacle-minor-mode act inact)))
    (setq ox-spectacle-minor-mode nil)
    (user-error "Please run this under org-mode")))


;;; End-user functions

(defun ox-spectacle-export-to-buffer (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to an HTML buffer.

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

Export is done in a buffer named \"*Org HTML Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (ox-spectacle-advice
   (org-export-to-buffer 'spectacle "*Org Spectacle Export*"
     async subtreep visible-only body-only ext-plist (lambda () (set-auto-mode t)))))

(defun ox-spectacle-export-to-file (&optional async subtreep visible-only body-only ext-plist)
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

When optional argument BODY-ONLY is non-nil, only write code
between \"<body>\" and \"</body>\" tags.

EXT-PLIST, when provided, is a property list with external
parameters overriding Org default settings, but still inferior to
file-local settings.

Return output file's name."
  (interactive)
  (let* ((extension (concat "." (or (plist-get ext-plist :html-extension) org-html-extension "html")))
         (file (org-export-output-file-name extension subtreep))
         (org-export-coding-system 'utf-8))
    (ox-spectacle-advice (org-export-to-file 'spectacle file async subtreep visible-only body-only ext-plist))))

(defun ox-spectacle-export-to-file-and-browser (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to file and then browser the HTML file.
Optional ASYNC, SUBTREEP, VISIBLE-ONLY, BODY-ONLY, EXT-PLIST are passed
to `ox-spectacle-export-to-file'."
  (interactive)
  (browse-url-of-file
   (expand-file-name
    (ox-spectacle-export-to-file async subtreep visible-only body-only ext-plist))))

(defun ox-spectacle-publish-to-html (plist filename pub-dir)
  "Publish an org file to HTML.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (ox-spectacle-advice
   (org-publish-org-to 'spectacle filename
                       (concat "." (or (plist-get plist :html-extension) org-html-extension "html"))
                       plist pub-dir)))


(provide 'ox-spectacle)

;;; ox-spectacle.el ends here
