;;; ox-timeline.el --- HTML Timeline Back-End for Org Export Engine

;; Copyright (C) 2021-2022  Joel Bryan Juliano

;; Author: Joel Bryan Juliano <joelbryan dot juliano at gmail dot com>
;; URL: https://github.com/jjuliano/org-simple-timeline
;; Package-Version: 20210118.536
;; Package-Commit: 238e05b01dde37fa27a3a8943cc04dcc9b9b83b2
;; Package-Requires: ((emacs "24.4"))
;; Version: 1.0.0
;; Keywords: simple timeline, timeline, hypermedia, HTML Timeline

;; This file is not part of GNU Emacs.

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

;; This library implements the Org-mode back-end generic exporter for HTML
;; Timeline.

;; Installation
;; ------------
;; Download the timeline scripts from
;;    https://squarechip.github.io/timeline/
;; Then copy the files relative to your html file.n
;; The default (`org-timeline-source-url') is set to "modules/timeline/dist".

;; Usage
;; -----
;; To test it, run:
;;
;;   M-x org-timeline-export-as-html
;;
;; in an Org mode buffer.  See ox.el and ox-html.el for more details
;; on how this exporter works.

;;; Code:

(require 'ox-html)

(org-export-define-derived-backend 'timeline 'html
  :menu-entry
  '(?T "Export to HTML Timeline"
       ((?H "To temporary buffer" org-timeline-export-as-html)
        (?h "To file" org-timeline-export-to-html)
        (?o "To file and open"
            (lambda (a s v b)
              (if a (org-timeline-export-to-html t s v b)
                (org-open-file (org-timeline-export-to-html nil s v b)))))))
  :options-alist
  '((:html-link-home                     "HTML_LINK_HOME" nil nil)
    (:html-link-up                       "HTML_LINK_UP" nil nil)
    (:html-head-include-default-style    "HTML_INCLUDE_DEFAULT_STYLE" nil nil)
    (:html-head-include-scripts          "HTML_INCLUDE_SCRIPTS" nil nil)
    (:timeline-footer                    "TIMELINE_FOOTER" nil
                                         org-timeline-footer newline)
    (:timeline-header                    "TIMELINE_HEADER" nil
                                         org-timeline-header newline)
    (:timeline-source-url                "TIMELINE_SOURCE_URL" nil
                                         org-timeline-source-url)
    (:timeline-mode                      "TIMELINE_MODE" nil org-timeline-mode)
    (:timeline-force-vertical-mode       "TIMELINE_FORCE_VERTICAL_MODE" nil
                                         org-timeline-force-vertical-mode)
    (:timeline-horizontal-start-position "TIMELINE_HORIZONTAL_START_POSITION" nil
                                         org-timeline-horizontal-start-position)
    (:timeline-move-items                "TIMELINE_MOVE_ITEMS" nil
                                         org-timeline-move-items)
    (:timeline-rtl-mode                  "TIMELINE_RTL_MODE" nil
                                         org-timeline-rtl-mode)
    (:timeline-start-index               "TIMELINE_START_INDEX" nil
                                         org-timeline-start-index)
    (:timeline-vertical-start-position   "TIMELINE_VERTICAL_START_POSITION" nil
                                         org-timeline-vertical-start-position)
    (:timeline-vertical-trigger          "TIMELINE_VERTICAL_TRIGGER" nil
                                         org-timeline-vertical-trigger)
    (:timeline-visible-items             "TIMELINE_VISIBLE_ITEMS" nil
                                         org-timeline-visible-items))

  :translate-alist
  '((headline . org-timeline-headline)
    (inner-template . org-timeline-inner-template)
    (template . org-timeline-template)))

(defgroup org-export-timeline nil
  "All options available for exporting org-mode to HTML Timeline."
  :tag "Org Export HTML Timeline"
  :group 'org-export-html)

(defcustom org-timeline-mode 'vertical
  "Setting for timeline \"mode\"."
  :group 'org-export-timeline
  :type '(choice (const vertical) (const horizontal)))

(defcustom org-timeline-horizontal-start-position 'top
  "The vertical alignment of the first item in horizontal mode."
  :group 'org-export-timeline
  :type '(choice (const top) (const bottom)))

(defcustom org-timeline-vertical-start-position 'left
  "The horizontal alignment of the first item in vertical mode."
  :group 'org-export-timeline
  :type '(choice (const left) (const right)))

(defcustom org-timeline-force-vertical-mode 600
  "The viewport width value in which a horizontal mode will revert to vertical."
  :group 'org-export-timeline
  :type 'integer)

(defcustom org-timeline-start-index 0
  "The starting item in horizontal mode."
  :group 'org-export-timeline
  :type 'integer)

(defcustom org-timeline-visible-items 3
  "The number of items visible in the screen in horizontal mode."
  :group 'org-export-timeline
  :type 'integer)

(defcustom org-timeline-rtl-mode 'false
  "Setting to enable RTL mode."
  :group 'org-export-timeline
  :type '(choice (const true) (const false)))

(defcustom org-timeline-move-items 1
  "The number of items will be moved when in horizontal mode."
  :group 'org-export-timeline
  :type 'integer)

(defcustom org-timeline-vertical-trigger "15%"
  "The distance pixels in vertical mode on the bottom of the screen."
  :group 'org-export-timeline
  :type 'string)

(defcustom org-timeline-source-url "modules/timeline/dist"
  "The url directory which contains the HTML plugin subdirectory.

Set the TIMELINE_SOURCE_URL property to override."
  :group 'org-export-timeline
  :type 'string)

(defvar org-timeline--divs
  '((preamble  "div" "header")
    (content   "div" "content")
    (postamble "div" "footer"))
  "Upon exporting the HTML, this alist will comprise of three section elements.

The CAR for each entry is a 'preamble', 'context' or 'postamble', while the CDRs
are element type and id.")

(defcustom org-timeline-footer
"<div style=\" padding-top: 2vw; padding-bottom: 2vw; text-align: center;\"></div>"

  "Preamble inserted into the HTML Timeline layout section.
When set to a string, use this string as the postamble.

When set to a function, apply this function and insert the
returned string.  The function takes the property list of export
options as its only argument.

Setting the TIMELINE_FOOTER option -- or the :timeline-footer in publishing
projects -- will take precedence over this variable.

Note that the default css styling will break if this is set to nil
or an empty string."
  :group 'org-export-timeline
  :type '(choice (const :tag "No postamble" "&#x20;")
                 (string :tag "Custom formatting string")
                 (function :tag "Function (must return a string)")))

(defcustom org-timeline-header
"<div style=\" padding-top: 2vw; padding-bottom: 2vw; text-align: center;\"></div>"
  "Preamble inserted into the HTML Timeline layout section.

When set to a string, use this string as the preamble.

When set to a function, apply this function and insert the
returned string.  The function takes the property list of export
options as its only argument.

Setting TIMELINE_HEADER option -- or the :timeline-header in publishing
projects -- will take precedence over this variable.

Note that the default css styling will break if this is set to nil
or an empty string."
  :group 'org-export-timeline
  :type '(choice (const :tag "No preamble" "&#x20;")
                 (string :tag "Custom formatting string")
                 (function :tag "Function (must return a string)")))

(defun org-timeline--build-head (info)
  "Builds the head from INFO containing the stylesheet and scripts."
  (let* ((dir (plist-get info :timeline-source-url))
         (css (or (plist-get info :timeline-css-file) "css/timeline.min.css")))
    (mapconcat #'identity
     (list (mapconcat
       (lambda (list)
         (format "<link rel='stylesheet' href='%s/css/%s' type='text/css' />"
          dir (nth 0 list)))
       (list
        '("timeline.min.css")) "\n")
      (concat
       "<script src='" dir
       "/js/timeline.min.js' type='text/javascript'></script>")) "\n")))

(defun org-timeline--build-meta-info (info)
  "Builds the meta information from INFO when exporting to HTML."
  (concat
   (org-html--build-meta-info info)))

(defun org-timeline-headline (headline contents info)
  "Builds the outer and inner class for timeline.
HEADLINE is the outer class, CONTENTS and INFO are the contents of the inner
class."

  (let ((org-html-toplevel-hlevel 1)
        (class (or (org-element-property :HTML_CONTAINER_CLASS headline) ""))
        (level (org-export-get-relative-level headline info)))
    (org-element-put-property headline :HTML_CONTAINER_CLASS (concat class " timeline__content"))
    (format "<div class=\"timeline__item\">%s</div>" (org-html-headline headline contents info))))

(defun org-timeline-inner-template (contents info)
  "Return body of document string after HTML conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat contents "\n"))

(defun org-timeline-template (contents info)
  "Return complete document string after HTML conversion.
CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (let ((info (plist-put
               (plist-put
                (plist-put info :html-preamble (plist-get info :timeline-header))
                :html-postamble
                (plist-get info :timeline-footer))
               :html-divs
               (if (equal "li" (plist-get info :html-container))
                   (cons '(content "ol" "content") org-timeline--divs)
                 org-timeline--divs))))

    (mapconcat #'identity
     (list
      (org-html-doctype info)
      (format "<html xmlns=\"https://www.w3.org/1999/xhtml\" lang=\"%s\" xml:lang=\"%s\">"
              (plist-get info :language) (plist-get info :language))
      "<head>"
      (org-timeline--build-meta-info info)
      (org-timeline--build-head info)
      (org-html--build-head info)
      "</head>"
      "<body>"
      "<header class=\"header\">"
      (org-html--build-pre/postamble 'preamble info)
      "</header>"
      "<section class=\"section\">"
      "<div class=\"container\">"
      (format
       "<div class=\"timeline\" data-mode=\"%s\"
                                data-force-vertical-mode=\"%s\"
                                data-horizontal-start-position=\"%s\"
                                data-move-items=\"%s\"
                                data-rtl-mode=\"%s\"
                                data-start-index=\"%s\"
                                data-vertical-start-position=\"%s\"
                                data-vertical-trigger=\"%s\"
                                data-visible-items=\"%s\">"
       (plist-get info :timeline-mode)
       (plist-get info :timeline-force-vertical-mode)
       (plist-get info :timeline-horizontal-start-position)
       (plist-get info :timeline-move-items)
       (plist-get info :timeline-rtl-mode)
       (plist-get info :timeline-start-index)
       (plist-get info :timeline-vertical-start-position)
       (plist-get info :timeline-vertical-trigger)
       (plist-get info :timeline-visible-items))
      "<div class=\"timeline__wrap\">"
      "<div class=\"timeline__items\">"
      contents
      "</div>"
      "</div>"
      "</div>"
      "</div>"
      "</section>"
      "<footer class=\"footer\">"
      (org-html--build-pre/postamble 'postamble info)
      "</footer>"
      "<script>timeline(document.querySelectorAll('.timeline'));</script>"
      "</body>"
      "</html>\n") "\n")))

(defun org-timeline-export-as-html
  (&optional async subtreep visible-only body-only ext-plist)
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

Export is done in a buffer named \"*Org HTML Timeline Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (org-export-to-buffer 'timeline "*Org HTML Timeline Export*"
    async subtreep visible-only body-only ext-plist (lambda () (nxml-mode))))

(defun org-timeline-export-to-html
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a HTML Timeline HTML file.

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
  (let* ((extension (concat "." org-html-extension))
         (file (org-export-output-file-name extension subtreep))
         (org-export-coding-system org-html-coding-system))
    (org-export-to-file 'timeline file
      async subtreep visible-only body-only ext-plist)))

(defun org-timeline-publish-to-html (plist filename pub-dir)
  "Publish an org file to HTML Timeline HTML Presentation.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'timeline filename ".html" plist pub-dir))

(provide 'ox-timeline)

;;; ox-timeline.el ends here
