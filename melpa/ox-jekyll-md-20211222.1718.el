;;; ox-jekyll-md.el --- Export Jekyll on Markdown articles using org-mode. -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Elsa Gonsiorowski

;; Author: Elsa Gonsiorowski <gonsie@me.com>
;; Author: Yoshinari Nomura <nom@quickhack.net>
;; Author: Justin Gordon <justin.gordon@gmail.com>
;; Keywords: org, jekyll
;; Package-Version: 20211222.1718
;; Package-Commit: 26edb3f4575bcb0f1a2aed56237cd89694284449
;; Version: 0.1

;; This is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library implements a Jekyll-style md backend for
;; Org exporter, based on `md' back-end.
;;
;; It provides two commands for export, depending on the desired
;; output: `org-jekyll-md-export-as-md' (temporary buffer) and
;; `org-jekyll-md-export-to-md' ("md" file with YAML front matter).
;;
;; For publishing, `org-jekyll-md-publish-to-md' is available.
;; For composing, `org-jekyll-md-insert-export-options-template' is available.

;;; Code:

;;; Dependencies

(require 'ox-md)

;;; User Configurable Variables

(defgroup org-export-jekyll-md nil
  "Options for exporting Org mode files to jekyll MD."
  :tag "Org Jekyll MD"
  :group 'org-export
  :version "24.2")

(defcustom org-jekyll-md-include-yaml-front-matter t
  "If true, then include yaml-front-matter when exporting to md.

If false, then you should include the yaml front matter like this at the top of
the file:

#+BEGIN_EXPORT HTML
---
layout: post
title: \"Upgrading Octopress\"
date: 2013-09-15 22:08
categories: [octopress, rubymine]
tags: tech news
keywords: Octopress
description: Instructions on Upgrading Octopress
---
#+END_EXPORT HTML"
  :group 'org-export-jekyll
  :type 'boolean)


(defcustom org-jekyll-md-layout "post"
  "Default layout used in Jekyll article."
  :group 'org-export-jekyll
  :type 'string)

(defcustom org-jekyll-md-categories ""
  "Default space-separated categories in Jekyll article."
  :group 'org-export-jekyll
  :type 'string)

(defcustom org-jekyll-md-tags ""
  "Default space-separated tags in Jekyll article."
  :group 'org-export-jekyll
  :type 'string)

(defcustom org-jekyll-md-use-src-plugin t
   "If t, org-jekyll-md exporter eagerly uses plugins instead of
original markdown stuff. For example:

   #+BEGIN_SRC ruby
     puts \"Hello world\"
   #+END_SRC

makes:

  {% highlight ruby %}
  puts \"Hello world\"
  {% endhighlight %}"
  :group 'org-export-jekyll-use-src-plugin
  :type 'boolean)

(defcustom org-jekyll-md-use-todays-date t
  "If t, org-jekyll-md exporter will prepend the filename with today's date."
  :group 'org-export-jekyll
  :type 'boolean)

;;; Define Back-End

(org-export-define-derived-backend 'jekyll 'md
  :filters-alist '((:filter-parse-tree . org-jekyll-md-separate-elements))
  :menu-entry
  '(?j "Jekyll: export to Markdown with YAML front matter."
       ((?M "As Jekyll buffer" (lambda (a s v b) (org-jekyll-md-export-as-md a s v)))
        (?m "As Jekyll file" (lambda (a s v b) (org-jekyll-md-export-to-md a s v)))))
  :translate-alist
  '((headline . org-jekyll-md-headline-offset)
    (inner-template . org-jekyll-md-inner-template) ;; force body-only
    (src-block . org-jekyll-md-src-block)
    (table . org-jekyll-md-table)
    (table-cell . org-jekyll-md-table-cell)
    (table-row . org-jekyll-md-table-row)
    (template . org-jekyll-md-template)) ;; add YAML front matter.
  :options-alist
  '((:jekyll-layout "JEKYLL_LAYOUT" nil org-jekyll-md-layout)
    (:jekyll-categories "JEKYLL_CATEGORIES" nil org-jekyll-md-categories)
    (:jekyll-tags "JEKYLL_TAGS" nil org-jekyll-md-tags)))


;;; Headline
;;; Keep the level as defined in original content
;;; ** subtree => ## heading

(defun org-jekyll-md-headline-offset (headline contents info)
  "proper headline offset"
  (let* ((info (plist-put info :headline-offset 0)))
    (org-md-headline headline contents info)))


;;; Internal Filters

(defun org-jekyll-md-separate-elements (tree _backend info)
  "Fix blank lines between elements.

TREE is the parse tree being exported.  BACKEND is the export
back-end used.  INFO is a plist used as a communication channel.

Enforce a blank line between elements.  There are three exceptions
to this rule:

  1. Preserve blank lines between sibling items in a plain list.

  2. In an item, remove any blank line before the very first
     paragraph and the next sub-list when the latter ends the
     current item.

  3. Do not insert blank lines between table rows.

Assume BACKEND is `jekyll'."
  (org-element-map tree (remq 'item org-element-all-elements)
    (lambda (e)
      (org-element-put-property
       e :post-blank
       (if (and (eq (org-element-type e) 'paragraph)
		(eq (org-element-type (org-element-property :parent e)) 'item)
		(org-export-first-sibling-p e info)
		(let ((next (org-export-get-next-element e info)))
		  (and (eq (org-element-type next) 'plain-list)
		       (not (org-export-get-next-element next info)))))
	   0
	 (if (eq (org-element-type e) 'table-row)
             0
           1)))))
  ;; Return updated tree.
  tree)

(defun org-jekyll-md-src-block (src-block contents info)
  "Optionally transcode SRC-BLOCK element into jekyll code template format.

Use `highlight` / `endhighlight` if `org-jekyll-md-use-src-plugin` is t. Otherwise,
perform `org-md-src-block`. CONTENTS holds the contents of the item. INFO is a
plist used as a communication channel."
  (if org-jekyll-md-use-src-plugin
      (let ((language (org-element-property :language src-block))
            (value (org-remove-indentation
                    (org-element-property :value src-block))))
        (format "{%% highlight %s %%}\n%s{%% endhighlight %%}"
                language value))
    (org-export-with-backend 'md src-block contents info)))

(defun org-jekyll-md-table (table contents info)
  "Empty transformation. Org tables should be valid kramdown syntax."
  contents)

(defun org-jekyll-md-table-cell (table-cell contents info)
  "Empty transformation. Org tables should be valid kramdown syntax."
  (if contents
      (format "| %s " contents)
    "| "))

(defun org-jekyll-md-table-row (table-row contents info)
  "Empty transformation. Org tables should be valid kramdown syntax."
  (if contents
      (format "%s|" contents)
    (let* ((table (org-export-get-parent table-row))
           (rc (org-export-table-dimensions table info)))
      (concat (apply 'concat (make-list (cdr rc) "|---"))
              (identity "|")))))

;;; Template

(defun org-jekyll-md-template (contents info)
  "Return complete document string after MD conversion.

CONTENTS is the transcoded contents string. INFO is a plist
holding export options."
  (if org-jekyll-md-include-yaml-front-matter
      (concat
       (org-jekyll-md--yaml-front-matter info)
       contents)
    contents
    ))

(defun org-jekyll-md-inner-template (contents info)
  "Return body of document string after MD conversion.

CONTENTS is the transcoded contents string.  INFO is a plist
holding export options."
  (concat
   ;; Table of contents.
   (let ((depth (plist-get info :with-toc)))
     (when depth (org-md--build-toc info (and (wholenump depth) depth))))
   ;; Document contents.
   contents
   ;; Footnotes section.
   (org-md--footnote-section info)))


;;; YAML Front Matter

(defun org-jekyll-md--get-option (info property-name &optional default)
  "Get org export options."
  (let ((property (org-export-data (plist-get info property-name) info)))
    (format "%s" (or property default ""))))

(defun org-jekyll-md--yaml-front-matter (info)
  "Creat YAML frontmatter content."
  (let ((convert-to-yaml-list
         (lambda (arg)
           (mapconcat #'(lambda (text)(concat "\n- " text))
                      (split-string arg) " "))))
    (let ((title
           (concat "\ntitle: \""
                   (org-jekyll-md--get-option info
                                           :title) "\""))
          (layout
           (concat "\nlayout: "
                   (org-jekyll-md--get-option info
                                           :jekyll-layout org-jekyll-md-layout)))
          (categories
           (concat "\ncategories: "
                   (funcall convert-to-yaml-list
                            (org-jekyll-md--get-option
                             info
                             :jekyll-categories org-jekyll-md-categories))))
          (tags
           (concat "\ntags: "
                   (funcall convert-to-yaml-list
                            (org-jekyll-md--get-option
                             info
                             :jekyll-tags org-jekyll-md-tags))))
          (date
           (and (plist-get info :with-date)
                (concat "\ndate: "
                        (org-jekyll-md--get-option info :date)))))
      (concat
       "---"
       title
       date
       layout
       categories
       tags
       "\n---\n\n"))))


;;; Filename and Date Helper
;;; optionally prepend filename with today's date

(defun org-jekyll-md-filename-date ()
  "Optionally include date in exported filename."
  (if org-jekyll-md-use-todays-date
      (format-time-string "%F-")
    ""))


;;; End-User functions

;;;###autoload
(defun org-jekyll-md-export-as-md (&optional async subtreep visible-only)
  "Export current buffer as a Markdown buffer adding some YAML front matter."
  (interactive)
  (org-export-to-buffer 'jekyll "*Org Jekyll-Markdown Export*"
    async subtreep visible-only nil nil (lambda () (text-mode))))

;;;###autoload
(defun org-jekyll-md-export-to-md (&optional async subtreep visible-only)
  "Export current buffer to a Markdown file adding some YAML front matter."
  (interactive)
  (let ((outfile (concat (org-jekyll-md-filename-date)
                         (org-export-output-file-name ".md" subtreep))))
    (org-export-to-file 'jekyll outfile async subtreep visible-only)))

;;;###autoload
(defun org-jekyll-md-publish-to-md (plist filename pub-dir)
  "Publish an org file to Markdown with YAML front matter.

FILENAME is the filename of the Org file to be published.  PLIST
is the property list for the given project.  PUB-DIR is the
publishing directory.

Return output file name."
  (org-publish-org-to 'jekyll filename ".md" plist pub-dir))

;;;###autoload
(defun org-jekyll-md-insert-export-options-template
  (&optional title date setupfile categories tags layout)
  "Insert a settings template for Jekyll exporter."
  (interactive)
  (let ((layout     (or layout org-jekyll-md-layout))
        (tags       (or tags org-jekyll-md-tags))
        (categories (or categories org-jekyll-md-categories)))
    (save-excursion
      (insert (format (concat
                       "#+TITLE: "             title
                       "\n#+DATE: "              date
                       "\n#+SETUPFILE: "         setupfile
                       "\n#+JEKYLL_LAYOUT: "     layout
                       "\n#+JEKYLL_CATEGORIES: " categories
                       "\n#+JEKYLL_TAGS: "       tags
                       "\n\n* \n\n{{{more}}}"))))))

;;; provide

(provide 'ox-jekyll-md)

;;; ox-jekyll-md.el ends here
