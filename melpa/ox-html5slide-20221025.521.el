;;; ox-html5slide.el --- Export org-mode to HTML5 slide.

;; Copyright (c) 2013 Yen-Chin, Lee.
;;
;; Author: coldnew <coldnew.tw@gmail.com>
;; Keywords: html presentation
;; Package-Version: 20221025.521
;; Package-Commit: 4e0d9026c96e1dde22cca7c700669f1f863a9d07
;; X-URL: http://github.com/coldnew/org-html5slide
;; URL: http://github.com/coldnew/org-html5slide
;; Package-Requires: ((org "8.0"))
;; Version: 0.1

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Commentary:

;; ox-html5slide.el is a rewrite version of org-html5presentation.el
;; and only support org-mode 8.0 or above.
;;

;;; Installation (not done yet):

;; If you have `melpa` and `emacs24` installed, simply type:
;;
;;      M-x package-install org-html5slide
;;
;; In your .emacs
;;
;;      (require 'ox-html5slide)

;;; Code:

;;; Dependencies

(require 'ox-html)
(eval-when-compile (require 'cl))


;;; User Configuration Variables
(defgroup org-export-html5slide nil
  "Options for exporting Org mode files to HTML5 slide."
  :tag "Org Export to HTML5 slide"
  :group 'org-export)

(defcustom org-html5slide-hlevel 2
  "The minimum level of headings that should be grouped into
vertical slides."
  :group 'org-export-html5slide
  :type 'integer)

(defcustom org-html5slide-title-slide-template
  "<article class='nobackground'>
<h1>%t</h1>
<p>
<br>%a<br>
<br>%e<br>
<br>%d<br>
</p>
</article>"
  "Format template to specify title page slide.
See `org-html-postamble-format' for the valid elements which
can be include."
  :group 'org-export-html5slide
  :type 'string)

;;; Define Back-End

(org-export-define-derived-backend 'html5slide 'html
  :menu-entry
  '(?S "Export to HTML5 HTML slide."
       ((?S "To file" org-html5slide-export-to-html)))

  :options-alist
  '((:html5slide-hlevel nil "HTML5SLIDE_HLEVEL" nil nil t))

  :translate-alist
  '((headline . org-html5slide-headline)
    (section  . org-html5slide-section)
    (template . org-html5slide-template)
    (center-block . org-html5slide-center-block))
  )


;;; Internal Functions

(defun org-html5presentation-get-hlevel (info)
  "Get HLevel value safely.
If option \"HTML5SLIDE_HLEVEL\" is set, retrieve integer value from it,
else get value from custom variable `org-html5slide-hlevel'."
  (let ((hlevel-str (plist-get info :html5slide-hlevel)))
    (if hlevel-str (string-to-number hlevel-str)
      org-html5slide-hlevel)))

(defun org-html5slide-if-format (fmt val)
  (let ((str (if (listp val)
                 (or (car-safe val) "")
               val)))
    (if val (format fmt str))))

(defun org-html5slide-center-block (center-block contents info)
  "Transcode a CENTER-BLOCK element from Org to HTML.
CONTENTS holds the contents of the block.  INFO is a plist
holding contextual information."
  (format "<div style=\"text-align: center\">\n%s</div>" contents))

(defun org-html5slide-stylesheets (info)
  "Return the HTML contents for declaring html5slide stylesheets."
  "<script src='http://html5slides.googlecode.com/svn/trunk/slides.js'></script>")

(defun org-html5slide-headline (headline contents info)
  "Transcode a HEADLINE element from Org to html5presentation.
CONTENTS holds the contents of the headline. INFO is a plist
holding contextual information."
  ;; First call org-html-headline to get the formatted HTML contents.
  ;; Then add enclosing <article> tags to mark slides.
  (setq contents (or contents ""))
  (let* ((numberedp (org-export-numbered-headline-p headline info))
         (level (org-export-get-relative-level headline info))
         (text (org-export-data (org-element-property :title headline) info))
         (todo (and (plist-get info :with-todo-keywords)
                    (let ((todo (org-element-property :todo-keyword headline)))
                      (and todo (org-export-data todo info)))))
         (todo-type (and todo (org-element-property :todo-type headline)))
         (tags (and (plist-get info :with-tags)
                    (org-export-get-tags headline info)))
         (priority (and (plist-get info :with-priority)
                        (org-element-property :priority headline)))
         ;; Create the headline text.
         (full-text (org-html-format-headline--wrap headline info)))
    (cond
     ;; Case 1: Ignore the footnote section.
     ((org-element-property :footnote-section-p headline) nil)

     ;; Case 2. Standard headline. Export it as a section.
     (t
      (let* ((level1 (+ level (1- org-html-toplevel-hlevel)))
             (hlevel (org-html5presentation-get-hlevel info))
             (first-content (car (org-element-contents headline))))
        (concat
         ;; Stop previous slide.
         (if (or (/= level 1)
                 (not (org-export-first-sibling-p headline info)))
             "</article>\n")
         ;; Add an extra "<article>" to group following slides
         ;; into vertical ones.
         (if (eq level hlevel)
             "<article class='smaller nobackground'>\n")
         ;; Start a new slide.
         (format "<article class='smaller nobackground' id=\"%s\" >\n"
                 (or (org-element-property :CUSTOM_ID headline)
                     (concat "sec-" (mapconcat 'number-to-string
                                               (org-export-get-headline-number headline info)
                                               "-"))))
         ;; The HTML content of this headline.
         ;; Since Google's html5slides start the headline in `h3', we
         ;; also use h3 as headline block.
         (format "\n<h3>%s</h3>\n" full-text)

         ;; Slide contents
         contents

         ;; Add an extra "</article>" to stop vertical slide grouping.
         (if (= level hlevel) "</article>\n")

         ;; Stop all slides when meets last head 1.
         (if (and (= level 1)
                  (org-export-last-sibling-p headline info))
             "</article>")))))))

(defun org-html5slide-section (section contents info)
  "Transcode a SECTION element from Org to HTML.
CONTENTS holds the contents of the section. INFO is a plist
holding contextual information."
  ;; Just return the contents. No "<div>" tags.
  contents)

(defun org-html5slide-template (contents info)
  "Return complete document string after HTML conversion.
contents is the transoded contents string.
info is a plist holding eport options."
  (concat
   (format "<?xml version=\"1.0\" encoding=\"utf-8\"?>
<!doctype html>\n<html%s>\n<head>\n"
           (org-html5slide-if-format " lang=\"%s\"" (plist-get info :language)))
   "<meta charset=\"utf-8\">"
   (org-html5slide-if-format "<title>%s</title>\n" (plist-get info :title))
   "<meta name=\"generator\" content=\"org-html5slide\"/> \n"
   (org-html5slide-if-format "<meta name=\"generated\" content=\"%s\"/> \n" (format-time-string "%Y-%m-%d %T %Z"))
   (org-html5slide-if-format "<meta name=\"author\" content=\"%s\"/>\n" (plist-get info :author))
   (org-html5slide-if-format "<meta name=\"email\" content=\"%s\"/>\n" (plist-get info :email))
   (org-html5slide-if-format "<meta name=\"description\" content=\"%s\"/>\n" (plist-get info :description))
   (org-html5slide-if-format "<meta name=\"keywords\" content=\"%s\"/>\n" (plist-get info :keywords))

   (org-html5slide-stylesheets info)
   ;;    (org-html5presentation-mathjax-scripts info)
   "</head>
    <body style='display: none'>\n"

   "<section class='slides layout-regular template-default'>"

   ;; Title Slide
   (format-spec org-html5slide-title-slide-template (org-html-format-spec info))

   ;; Slide contents
   contents

   "</section> \n"
   "</body> \n
</html>\n"
   ))


;;; End-user functions

;;;###autoload
(defun org-html5slide-export-as-html
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to an HTML buffer.

Export is done in a buffer named \"*Org HTML5 Slide Export*\", which
will be displayed when `org-export-show-temporary-export-buffer'
is non-nil."
  (interactive)
  (let ((outbuf (org-export-to-buffer
                 'html5slide "*Org HTML5 Slide Export*"
                 subtreep visible-only body-only ext-plist)))
    ;; Set major mode.
    (with-current-buffer outbuf (set-auto-mode t))
    (when org-export-show-temporary-export-buffer
      (switch-to-buffer-other-window outbuf))))

;;;###autoload
(defun org-html5slide-export-to-html
  (&optional async subtreep visible-only body-only ext-plist)
  "Export current buffer to a HTML5 slide HTML file."
  (interactive)
  (let* ((extension (concat "." org-html-extension))
         (file (org-export-output-file-name extension subtreep))
         (org-export-coding-system org-html-coding-system))
    (org-export-to-file
     'html5slide file subtreep visible-only body-only ext-plist)))

(provide 'ox-html5slide)
;;; ox-html5slide.el ends here
