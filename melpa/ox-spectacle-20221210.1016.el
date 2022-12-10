;;; ox-spectacle.el --- Spectacle.js Presentation Back-End for Org Export Engine -*- lexical-binding: t -*-

;; Copyright (C) 2018-2022 lorniu <lorniu@gmail.com>

;; Author: lorniu <lorniu@gmail.com>
;; Created: 2018-11-11
;; URL: https://github.com/lorniu/ox-spectacle
;; Package-Version: 20221210.1016
;; Package-Commit: d307a7f1e84d0511d363e0819bcec77e0cfba810
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
;; First, open your Emacs.
;;
;; Then, install this and load it:
;;
;;   (require 'ox-spectacle)
;;
;; That's all.
;;
;; Create one org file, put your ideas there.
;; Then export them to a html file and open it with `C-c C-e s o`.
;;
;; The amazing presentation is in front of you. Enjoy it.
;;
;; View README.md for detail.

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
  '((:theme                  "THEME"             nil ox-spectacle-theme)
    (:template               "TEMPLATE"          nil ox-spectacle-template)
    (:transition             "TRANSITION"        nil ox-spectacle-transition)
    (:deck-opts              "DECK_OPTS"         nil ox-spectacle-deck-opts space)
    (:slide-opts             "SLIDE_OPTS"        nil ox-spectacle-slide-opts space)
    (:text-opts              "TEXT_OPTS"         nil ox-spectacle-text-opts space)
    (:export-level           "EXPORT_LEVEL"      0   ox-spectacle-export-level)
    (:extern-components      "EXTERN_COMPONENTS" nil)
    (:html-doctype           nil                 nil ox-spectacle--doctype)
    (:with-special-strings   nil                 nil))

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

(defcustom ox-spectacle-theme nil
  "Default theme."
  :type 'string)

(defcustom ox-spectacle-template "template"
  "Default template."
  :type 'string)

(defcustom ox-spectacle-transition nil
  "Default transition ."
  :type 'string)

(defcustom ox-spectacle-deck-opts nil
  "Deck tag or extra props."
  :type 'string)

(defcustom ox-spectacle-slide-opts nil
  "Slide tag or extra props."
  :type 'string)

(defcustom ox-spectacle-text-opts nil
  "Text tag or extra props, used for plain paragraph."
  :type 'string)

(defcustom ox-spectacle-export-level 0
  "Export policy.
0 for normal, 1 for embed scripts, 2 for embed images,
3 for embed scripts and images."
  :type 'integer)

(defcustom ox-spectacle-scripts
  (list "https://unpkg.com/react@18.1.0/umd/react.production.min.js"
        "https://unpkg.com/react-dom@18.1.0/umd/react-dom.production.min.js"
        "https://unpkg.com/react-is@18.1.0/umd/react-is.production.min.js"
        "https://unpkg.com/prop-types@15.7.2/prop-types.min.js"
        "https://unpkg.com/spectacle@^9/dist/spectacle.min.js"
        "https://unpkg.com/htm")
  "Core scripts.
All the react, react-dom, react-js, spectacle and htm are required!
You can replace them with your CDN version or local version."
  :type '(repeat string))

(defcustom ox-spectacle-extra-scripts nil
  "Optional scripts you maybe used in the slides.
You can config your-own/third-party scripts used by the slides here."
  :type '(repeat string))

(defcustom ox-spectacle-default-template
  "({ slideNumber, numberOfSlides }) => html`
      <${FlexBox} position='absolute' bottom=${0} right=${0} opacity=${0.3}>
        <${Progress} size=${8} />
        <${Text} fontSize=${15}>${slideNumber}/${numberOfSlides}</${Text}>
      </${FlexBox}>`"
  "Template definition named as `template', as the default template of the slides."
  :type 'string)

(defvar ox-spectacle-cache-file-tpl (locate-user-emacs-file "ox-spectacle-scripts-%s.js")
  "Location of the cache file.")

(defvar ox-spectacle--doctype "xhtml")

(defvar-local ox-spectacle--extra-css nil)

(defvar-local ox-spectacle--extra-javascript nil)

(defvar-local ox-spectacle--extra-header nil)

(defvar-local ox-spectacle--user-templates nil)

(defconst ox-spectacle--html-tags
  '("h1" "h2" "h3" "h4" "h5" "div" "section" "p" "span"
    "small" "ul" "ol" "li" "hr" "a" "img" "button"))

(defconst ox-spectacle--components
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

(defconst ox-spectacle--utils
  '("defaultTheme" "fadeTransition" "slideTransition" "defaultTransition"
    "useSteps" "useMousetrap"
    "mdxComponentMap" "indentNormalizer"
    "removeNotes" "isolateNotes"))

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
    (if (or (= lv 1) (>= lv 3))
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

(defun ox-spectacle--extract-options (opts info &optional normed)
  "OPTS is keyword like :deck-opts.
Extract the value of it from INFO. The first part of the value maybe the
tag, others are props. Split and return them as cons. Assume the component
name is capitalized and html tags are all lower case. If NORMED non-nil
then filter the props."
  (setq opts (org-export-data (plist-get info opts) info))
  (when (> (length opts) 0)
    (let (tag props (case-fold-search nil))
      (let ((tg (car (string-split opts))))
        (when (and tg (string-match-p "^\\([A-Z][^=]+\\|[a-z][a-z0-9]*\\)$" tg))
          (setq tag tg)))
      (setq props (string-trim (cl-subseq opts (length tag))))
      (when normed
        (setq props
              (ox-spectacle--wa
               (ox-spectacle--filter-image
                (ox-spectacle--compat-props-react-htm props)
                info))))
      (cons tag (if (> (length props) 0) props)))))

(defun ox-spectacle--extern-components ()
  "Return all components declared with #+EXTERN_COMPONENTS.
It should be the components defined in buffer scripts or external."
  (save-excursion
    (goto-char (point-min))
    (let ((case-fold-search nil))
      (when (and (re-search-forward "^\\(?:\\(#\\)\\+EXTERN_COMPONENTS:[ \t]*\\(.*\\)\\|\\(\\*\\)\\)" nil t)
                 (string= (match-string 1) "#"))
        (split-string (string-trim (match-string 2)) " " t)))))

(defun ox-spectacle--available-components ()
  "All components available."
  (append ox-spectacle--components (ox-spectacle--extern-components)))

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

(defun ox-spectacle--filter-image (props info)
  "Replace all url in PROPS to inline data.
If url is remote, download it! INFO is a plist holding
contextual information."
  (if (and (>= (ox-spectacle--export-level info) 2) (> (length props) 10))
      (replace-regexp-in-string
       "url(\\([^)]+\\))"
       (lambda (old) (save-match-data (ox-spectacle--data-uri (match-string 1 old))))
       props nil nil 1)
    props))

(defun ox-spectacle--compat-props-react-htm (props)
  "Update PROPS to make the final code complat with react-htm."
  (replace-regexp-in-string "\\(=\\|\\.\\.\\.\\){" "\\1${" props))

(defun ox-spectacle--maybe-appear (contents flags)
  "Try to wrap CONTENTS with Appear according to FLAGS.
FLAGS should be `A, 1, A props' style."
  (if (and flags (string-match "^\\([A0-9]\\)[ \t]*\\(.*\\)$" flags))
      (let ((priority (when-let ((s (match-string 1 flags)))
                        (if (string-equal s "A") nil s)))
            (props (when-let ((s (ox-spectacle--wa (match-string 2 flags))))
                     (ox-spectacle--compat-props-react-htm s))))
        (concat "<${Appear}"
                (ox-spectacle--wa props)
                (if priority (format " priority=${%s}" priority)) ">\n"
                contents
                "\n</${Appear}>"))
    contents))

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
  (let* ((deck-opts (ox-spectacle--extract-options :deck-opts info t))
         (deck-tag (car deck-opts))
         (deck-props (cdr deck-opts))
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
            (or deck-tag "Deck")
            (ox-spectacle--wa deck-props)
            (funcall mkattr 'theme)
            (funcall mkattr 'template)
            (funcall mkattr 'transition)
            (string-trim body)
            (or deck-tag "Deck"))))

(defun ox-spectacle--inner-template (contents _info)
  "Return body of document string after HTML conversion.
CONTENTS is the transcoded contents string. INFO is a plist
holding export options."
  contents)

(defun ox-spectacle--headline (headline contents info)
  "Transcode a HEADLINE element from Org to HTML.
CONTENTS holds the contents of the headline.  INFO is a plist
holding contextual information."
  (let ((title (org-export-data (org-element-property :title headline) info))
        (level (org-element-property :level headline))
        (headlines (ox-spectacle--get-headlines headline t)))
    ;; the special <config> section
    (if (string-equal-ignore-case (org-element-property :raw-value (car headlines)) "<config>")
        (let ((tpl-regexp "^<t\\(?:emplate\\|\\)>[ \t]*\\([a-zA-Z][a-zA-Z0-9]+\\)"))
          (cond
           ;; take <template> section as a template definition
           ((and (= level 2) (string-match tpl-regexp title))
            (if-let ((name (match-string 1 title)))
                (setq ox-spectacle--user-templates
                      (concat ox-spectacle--user-templates
                              "\n    let " name " = ({ slideNumber, numberOfSlides }) => html`\n"
                              contents "`;\n"))
              (user-error "No name found on <Config/Template>")))
           ;; sections under <template>, return directly
           ((and (> level 2) (string-match-p tpl-regexp (org-element-property :raw-value (cadr headlines)))) contents)
           ;; others, ignore. Catch src-blocks only in `ox-spectacle--src-block'
           (t "")))
      (let* ((props (ox-spectacle--wa (org-element-property :PROPS headline)))
             (type (org-element-property :TYPE headline))
             (layout (org-element-property :LAYOUT headline))
             (tag type)
             (id (mapconcat #'number-to-string (org-export-get-headline-number headline info) "_"))
             (regexp (format "\\(%s\\)" (mapconcat #'identity (ox-spectacle--available-components) "\\|")))
             prefix inline-tag inline-props inline-prefix inline-suffix)
        ;; headline with <Component props> declaration has the highest priority
        (when (string-match (format "<\\${\\(?:%s\\|SlideLayout\\.[a-zA-Z0-9]+\\)}\\( [^>]*\\|\\)>\\(\\(?:<.*>\\)?\\)$" regexp) title)
          (setq inline-tag (match-string 1 title)
                inline-props (ox-spectacle--wa (match-string 2 title))
                inline-prefix (match-string 3 title)) ; deal multiple Components on headline
          (with-temp-buffer
            (insert inline-prefix)
            (goto-char (point-min))
            (while (re-search-forward "<${\\([A-Z][a-zA-Z0-9]+}\\)" nil t)
              (setq inline-suffix (concat " </${" (match-string 1) "}>" inline-suffix)))))
        ;; top-most headline, should be a Slide or SlideLayout
        (when (= level 1)
          (let* ((slide-opts (ox-spectacle--extract-options :slide-opts info))
                 (slide-tag (car slide-opts))
                 (slide-props (ox-spectacle--wa (cdr slide-opts))))
            (cond (inline-tag (setq tag inline-tag
                                    props (concat inline-props props)))
                  (layout (setq tag (format "SlideLayout.%s" layout)))
                  (type (setq tag type)))
            (unless tag (setq tag (or slide-tag "Slide")))
            (if (= (length props) 0) (setq props slide-props)))
          (setq prefix (format "\n<!------ slide (%s) begin ------>\n\n" id)))
        ;; default Component used by headline
        (unless tag
          (if inline-tag
              (setq tag inline-tag props (concat inline-props props))
            (setq tag "Box")))
        ;; normalize
        (if (string-match-p regexp tag) (setq tag (format "${%s}" tag)))
        (setq props (ox-spectacle--filter-image (ox-spectacle--compat-props-react-htm props) info))
        ;; final output
        (concat prefix "<" tag props ">" inline-prefix contents inline-suffix "</" tag ">")))))

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
         (props (org-export-read-attribute :attr_html element))
         (code-props (ox-spectacle--pop-from-plist props :showLineNumbers :highlightRanges :stepIndex :theme))
         (flags (cadr (ox-spectacle--pop-from-plist props :type)))
         (props (ox-spectacle--wa (org-html--make-attribute-string props)))
         (code-props (ox-spectacle--wa (org-html--make-attribute-string code-props)))
         (root (car (ox-spectacle--get-headlines element))))
    ;; catch config scripts and others under <config> section and :type with config
    (if (or (and flags (string-equal-ignore-case flags "config"))
            (string-equal-ignore-case (org-element-property :raw-value root) "<config>"))
        (progn
          (pcase lang
            ("html" (setq ox-spectacle--extra-header
                          (concat ox-spectacle--extra-header "\n\n" code)))
            ("css" (setq ox-spectacle--extra-css
                         (concat ox-spectacle--extra-css "\n" code)))
            ((or "js" "javascript") (setq ox-spectacle--extra-javascript
                                          (concat ox-spectacle--extra-javascript "\n" code))))
          "")
      ;; return a CodePane normally
      (let ((contents
             (format "<${Box}%s>\n<${CodePane}%s%s%s>\n${`\n%s\n`}\n</${CodePane}>\n</${Box}>"
                     props
                     (if lang (concat " language='" lang "'") "")
                     (if linum "" (concat " showLineNumbers=${false}"))
                     code-props code)))
        (ox-spectacle--maybe-appear contents flags)))))

(defun ox-spectacle--quote-block (quote-block contents _info)
  "Transcode a QUOTE-BLOCK element from Org to HTML.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (let* ((props (org-export-read-attribute :attr_html quote-block))
         (appear-flags (cadr (ox-spectacle--pop-from-plist props :type)))
         (sprops (ox-spectacle--wa (org-html--make-attribute-string props))))
    (ox-spectacle--maybe-appear
     (format "<${Quote}%s>%s</${Quote}>" sprops contents)
     appear-flags)))

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
         (props (ox-spectacle--wa
                 (org-html--make-attribute-string
                  (org-export-read-attribute :attr_html plain-list))))
         (tag (if ordered "OrderedList" "UnorderedList")))
    (format "<${%s}%s>\n%s</${%s}>\n" tag props contents tag)))

(defun ox-spectacle--item (_item contents _info)
  "Transcode an _ITEM element from Org to HTML.
CONTENTS holds the contents of the item."
  (let (len flags props (contents (or contents "")))
    ;; <A>, <NUM>: make it Appear; pass proper props to ListItem or Appear
    (when (string-match "^<\\([^>$][^>]*\\)>" (car (split-string contents "\n")))
      (setq props (string-trim (match-string 1 contents)))
      (setq len (+ (length props) 2))
      (when (string-match "^\\([A-Z0-9]\\)\\([ \t]\\|$\\)+" props)
        (setq flags (match-string 1 props))
        (setq props (string-trim (cl-subseq props 1)))
        (setq props
              (with-temp-buffer
                (insert props)
                (goto-char (point-min))
                ;; seperate props, some pass to Appear, others to ListItem
                (while (re-search-forward
                        (format "[ \t]+\\(%s\\)\\(=\\|[ \t]\\)"
                                (mapconcat #'identity
                                           '("priority" "alwaysVisible" "activeStyle" "inactiveStyle")
                                           "\\|"))
                        nil t)
                  (when (string-equal (match-string 2) "=")
                    (save-match-data
                      (if (re-search-forward "[ \t][a-z][a-zA-Z0-9]+\\(?:=\\|[ \t]\\)" nil t)
                          (goto-char (match-beginning 0))
                        (goto-char (point-max)))))
                  (setq flags (concat flags
                                      (ox-spectacle--wa
                                       (buffer-substring-no-properties
                                        (match-beginning 0) (point)))))
                  (delete-region (match-beginning 0) (point)))
                (ox-spectacle--wa (buffer-string)))))
      (setq contents (cl-subseq contents len)))
    (setq contents (concat "<${ListItem}"
                           (if props (ox-spectacle--wa (ox-spectacle--compat-props-react-htm props))) ">"
                           (string-trim contents)
                           "</${ListItem}>"))
    (ox-spectacle--maybe-appear contents flags)))

(defun ox-spectacle--table (table contents _info)
  "Transcode a TABLE element from Org to HTML.
CONTENTS is the contents of the table."
  (let* ((props (org-export-read-attribute :attr_html table))
         (appear-flags (cadr (ox-spectacle--pop-from-plist props :type)))
         (sprops (ox-spectacle--wa (org-html--make-attribute-string props)))
         (result (format "<${Table}%s>\n%s</${Table}>" sprops contents)))
    (ox-spectacle--maybe-appear result appear-flags)))

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

(defun ox-spectacle--format-image (path props info)
  "Parse image link.
PATH maybe a remote url or local file. PROPS and INFO is list."
  (let* ((lv (ox-spectacle--export-level info))
         (src (if (>= lv 2) (ox-spectacle--data-uri path) path))
         (type (cadr (ox-spectacle--pop-from-plist props :type)))
         (contents (org-html-close-tag
                    "${Image}"
                    (concat
                     (org-html--make-attribute-string props)
                     (format " src=\"%s\" alt=\"%s\"" src (file-name-nondirectory path)))
                    info)))
    (ox-spectacle--maybe-appear contents type)))

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
	     (props (let* ((parent (org-export-get-parent-element link))
		               (link (let ((container (org-export-get-parent link)))
			                   (if (and (eq (org-element-type container) 'link)
                                        (org-html-inline-image-p link info))
			                       container
			                     link))))
	              (and (eq (org-element-map parent 'link 'identity info t) link)
		               (org-export-read-attribute :attr_html parent))))
	     (sprops (ox-spectacle--wa (org-html--make-attribute-string props))))
    (cond
     ;; Link type is handled by a special function.
     ((org-export-custom-protocol-maybe link desc 'html))
     ;; Image file.
     ((and (plist-get info :html-inline-images)
	       (org-export-inline-image-p link (plist-get info :html-inline-image-rules)))
      (ox-spectacle--format-image path props info))
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
	      (format "<${link} href=\"#%s\"%s>%s</${Link}>" (or id path) sprops (or desc raw-link)))))
     ;; External link.
     (t (format "<${Link} href=\"%s\"%s>%s</${Link}>"
                (if path (org-html-encode-plain-text path) "#") sprops
                (or desc (org-link-unescape path)))))))

(defun ox-spectacle--paragraph (paragraph contents info)
  "Transcode a PARAGRAPH element from Org to HTML.
CONTENTS is the contents of the paragraph, as a string.  INFO is
the plist used as a communication channel."
  (let* ((case-fold-search nil)
         (headline (org-element-lineage paragraph '(headline)))
         (props (org-export-read-attribute :attr_html paragraph))
         (type (cadr (ox-spectacle--pop-from-plist props :type)))
         (props (ox-spectacle--wa (org-html--make-attribute-string props)))
         (regexp-html (format "\\(%s\\)" (mapconcat #'identity ox-spectacle--html-tags "\\|")))
         (regexp-comp (format "\\(%s\\)" (mapconcat #'identity (ox-spectacle--available-components) "\\|")))
         (parentype (org-element-type (org-export-get-parent paragraph)))
         (hd-raw (or (org-element-property :raw-value headline) ""))
         (notep (string-match-p "<notes.*>" hd-raw))
         (stepperp (string-match-p "<Stepper.*>" hd-raw))
         tag)
    (if (or stepperp
            (or (string-equal type "no") (string-equal type "raw"))
            (eq parentype 'item)
            (eq parentype 'quote-block)
            (org-html-standalone-image-p paragraph info))
        contents
      ;; if <Element> style, insert props into proper place directly, same as plain html paragraph
      (let ((firstline (car (split-string contents "\n")))
            (reg (format "^[ \t]*</?\\(\\${%s}\\|%s\\)\\([ \t]\\|$\\)" regexp-comp regexp-html)))
        (when (string-match-p reg firstline)
          (setq contents (with-temp-buffer
                           (insert contents)
                           (goto-char (point-min))
                           (search-forward ">")
                           (backward-char)
                           (insert (ox-spectacle--wa props))
                           (concat (ox-spectacle--filter-image (buffer-substring (point-min) (point)) info)
                                   (buffer-substring (point) (point-max))))
                tag t)))
      ;; fallback to :text-opts if nessesary or Text by default
      (let* ((text-opts (ox-spectacle--extract-options :text-opts info t))
             (text-tag (car text-opts))
             (text-props (ox-spectacle--wa (cdr text-opts))))
        (setq tag (if (eq tag t) nil (or type (if notep "p" (or text-tag "Text")))))
        (if (= (length props) 0) (setq props text-props)))
      ;; add ${} for component tag
      (if (string-match-p regexp-comp (or tag "")) (setq tag (format "${%s}" tag)))
      (if tag (format "<%s%s>%s</%s>" tag props (string-trim contents) tag) contents))))

(defun ox-spectacle--plain-text (text info)
  "Transcode a TEXT string from Org to HTML.
TEXT is the string to transcode.  INFO is a plist holding
contextual information."
  (let ((case-fold-search nil))
    ;; wrap Component with ${}, and add nessessary $ to its props
    ;; don't forget SlideLayout.Xxx
    (setq text (replace-regexp-in-string
                (format "<\\(/?%s\\|SlideLayout\\.[a-zA-Z0-9]+\\)\\(\\(?: \\|$\\)[^>]*\\|\\)>"
                        (mapconcat #'identity (ox-spectacle--available-components) "\\|"))
                (lambda (old)
                  (save-match-data
                    (let ((tag (match-string 1 old))
                          (props (or (match-string 2 old) "")))
                      (if (string-prefix-p "/" tag)
                          (format "</${%s}>" (cl-subseq tag 1))
                        (format "<${%s}%s>" tag (ox-spectacle--compat-props-react-htm props))))))
                text t t))
    ;; add $ for props of plain html tag, make it compat with react syntax
    (when (string-match-p (format "<\\(%s\\)[ \t]" (mapconcat #'identity ox-spectacle--html-tags "\\|")) text)
      (setq text (ox-spectacle--compat-props-react-htm text)))
    (let ((org-html-protect-char-alist nil))
      (setq text (org-html-plain-text text info)))))

(defun ox-spectacle--latex-fragment (latex-fragment _contents info)
  "Transcode a LATEX-FRAGMENT object from Org to HTML.
CONTENTS is nil. INFO is a plist holding contextual information."
  (let* ((latex-frag (org-element-property :value latex-fragment))
         (result (org-html-format-latex latex-frag 'mathjax info)))
    (string-replace "\\" "\\\\" result)))


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
                      (1 font-lock-function-name-face t))
                     ("\\(?:^\\|[ \t]\\)\\([_[:alpha:]][-_.[:alnum:]]*\\)=[\"'{]"
                      1 font-lock-variable-name-face t)))
             (act   (lambda () ; use closure to avoid changement
                      (font-lock-add-keywords nil kws t)
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
