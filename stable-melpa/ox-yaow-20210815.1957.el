;;; ox-yaow.el --- Generate html pages from org files -*- lexical-binding: t -*-

;; Copyright (C) 2020 Laurence Warne

;; Author: Laurence Warne
;; Maintainer: Laurence Warne
;; Version: 1.0
;; Package-Version: 20210815.1957
;; Package-Commit: e20e52ef2968323d26a2e6cd0843c9b36195a1ff
;; Keywords: outlines, hypermedia
;; URL: https://github.com/LaurenceWarne/ox-yaow.el
;; Package-Requires: ((emacs "27") (f "0.2.0") (s "1.12.0") (dash "2.17.0"))

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

;; This package adds another org html export option which aims to provide a
;; lightweight wiki.

;; Example usage:

;; Assuming you have some org files in ~/org, first register a new project
;; using `org-publish-project-alist':

;; (setq rto-css '("https://fniessen.github.io/org-html-themes/src/readtheorg_theme/css/htmlize.css"
;;                   "https://fniessen.github.io/org-html-themes/src/readtheorg_theme/css/readtheorg.css")
;;         rto-js '("https://fniessen.github.io/org-html-themes/src/lib/js/jquery.stickytableheaders.min.js"
;;                  "https://fniessen.github.io/org-html-themes/src/readtheorg_theme/js/readtheorg.js")
;;         extra-js '("https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js"
;;                    "https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js" )
;;         ox-yaow-html-head (concat (mapconcat (lambda (url) (concat "<link rel=\"stylesheet\" type=\"text/css\" href=\"" url "\"/>\n")) rto-css "")
;;                                   (mapconcat (lambda (url) (concat "<script src=\"" url "\"></script>\n")) (append rto-js extra-js) ""))
;;         org-publish-project-alist (cons
;;                                    `("wiki"
;;                                      ;;-------------------------------
;;                                      ;; Standard org publish options
;;                                      ;;-------------------------------
;;                                      :base-directory "~/org/"
;;                                      :base-extension "org"
;;                                      :publishing-directory "~/wiki/"
;;                                      :html-head ,ox-yaow-html-head
;;                                      :html-preamble t
;;                                      :recursive t
;;                                      :publishing-function ox-yaow-publish-to-html
;;                                      ;; Auto generates indexing files
;;                                      :preparation-function ox-yaow-preparation-fn
;;                                      ;; Removes auto-generated files
;;                                      :completion-function ox-yaow-completion-fn
;;                                      ;;------------------------------
;;                                      ;; Options specific to ox-yaow
;;                                      ;;------------------------------
;; 				     ;; Page to be regarded as the "homepage"
;; 				     :ox-yaow-wiki-home-file "~/org/wiki.org"
;;                                      ;; Don't generate links for these files
;;                                      :ox-yaow-file-blacklist ("~/org/maths/answers.org")
;;                                      ;; Max depths of sub links on indexing files
;;                                      :ox-yaow-depth 2)
;;                                    org-publish-project-alist))

;; The project can then be published via `org-export-dispatch'
;;; Code:

(require 'ox)
(require 'ox-html)
(require 's)
(require 'f)
(require 'dash)

(defgroup ox-yaow nil
  "A lightweight wiki export option."
  :group 'ox)

(defcustom ox-yaow-headline-point-to-file-p
  (lambda (hl) (= 2 (org-element-property :level hl)))
  "Predicate used to determine whether a headline points to a file."
  :group 'ox-yaow
  :type 'function)

(defcustom ox-yaow-indexing-file-p
  #'ox-yaow--indexing-file-p
  "Predicate used to determine whether a file is an indexing file."
  :group 'ox-yaow
  :type 'function)

(defcustom ox-yaow-get-default-indexing-file
  #'ox-yaow--get-default-indexing-file
  "The function used to get the indexing file from a directory.

The function should take the file path of a directory (which is known to have
 no indexing file) as an argument and return the path of an indexing file which
should be created for this directory."
  :group 'ox-yaow
  :type 'function)

(defcustom ox-yaow-html-link-stitching-fn
  #'ox-yaow--html-link-stitching-fn
  "The function used to create html links at the top of files.

The function should take three strings (file-paths) as arguments, denoting
the \"previous file\", \"next file\" and \"parent file\" respectively (any of
which may be nil), and returns valid html corresponding to linking to these
files."
  :group 'ox-yaow
  ;; TODO can I put function of three args here?
  :type 'function)

(defvar ox-yaow-html-head "<link rel=\"stylesheet\" type=\"text/css\" href=\"https://fniessen.github.io/org-html-themes/styles/readtheorg/css/htmlize.css\"/><link rel=\"stylesheet\" type=\"text/css\" href=\"https://fniessen.github.io/org-html-themes/styles/readtheorg/css/readtheorg.css\"/><script src=\"https://ajax.googleapis.com/ajax/libs/jquery/2.1.3/jquery.min.js\"></script><script src=\"https://maxcdn.bootstrapcdn.com/bootstrap/3.3.4/js/bootstrap.min.js\"></script><script type=\"text/javascript\" src=\"https://fniessen.github.io/org-html-themes/styles/lib/js/jquery.stickytableheaders.min.js\"></script><script type=\"text/javascript\" src=\"https://fniessen.github.io/org-html-themes/styles/readtheorg/js/readtheorg.js\"></script>")

(defvar ox-yaow--generated-files nil)

(defun ox-yaow--org-assoc-file-p (path)
  "Return t if PATH is associated with an org file.

Return t if PATH points to an org file, or is a directory which is an ancestor
of one, else return nil."
  (or (s-ends-with-p ".org" path)
      (and (f-directory? path)
           (-any #'ox-yaow--org-assoc-file-p (f-entries path)))))

(defun ox-yaow--org-entries (path &optional ignore-indexing-files file-blacklist)
  "Return a list of files associated with org files in PATH.

Return a list of org files and directories containing org files resident in
PATH, if IGNORE-INDEXING-FILES is non-nil, skip indexing files, skip files
present in FILE-BLACKLIST."
  (-filter (lambda (path) (and (or (not ignore-indexing-files)
			           (not (funcall ox-yaow-indexing-file-p path)))
                               (not (member path file-blacklist))))
	   (-filter #'ox-yaow--org-assoc-file-p (f-entries path))))

(cl-defun ox-yaow--indexing-file-p (file-path &key (strings (list "index")))
  "Return t if FILE-PATH corresponds to an ox-yaow indexing file.

A file is classed as an indexing if and only if the filename of FILE-PATH is in
the list STRINGS (defaults to \"index\"), or if the filename (without its file
extension) is equal to the directory name, else return nil."
  (let ((base (f-base file-path)))
    (or (let ((-compare-fn #'string=)) (-contains? strings base))
	(string= (cadr (reverse (f-split file-path))) base))))

(defun ox-yaow--get-default-indexing-file (path)
  "Return the default indexing file name for PATH.

Return PATH (a directory path) concatenated with 'filename.org' where filename
is the name of the directory pointed to by PATH."
  (f-join path (f-swap-ext (f-base path) "org")))

(defun ox-yaow--html-link-stitching-fn (orig-file prev-file next-file up-file)
  "Return html content linking the specified files.

The html will contain links to PREV-FILE, NEXT-FILE and UP-FILE if they are
non-nil, where the links are relative to ORIG-FILE."
    (let ((attributes (when (or prev-file next-file) "style='float: right;'")))
      (concat (ox-yaow--get-nav-links prev-file next-file)
	      (when up-file (concat "<span " (when attributes attributes) ">Up: "))
	      (ox-yaow--get-html-relative-link
	       up-file
	       (capitalize (s-replace "-" " " (f-base up-file)))
	       :reference-path orig-file)
	      (when up-file "</span>")
	      "<hr>")))

(cl-defun ox-yaow--get-file-ordering-from-index-tree
    (tree &key (headline-fn ox-yaow-headline-point-to-file-p))
  "Return the ordering of files suggested by TREE.

Get the ordering of files without extensions suggested by headlines collected
from TREE, using HEADLINE-FN to determine whether a given headline should be
considered a file."
  (let ((snd-level-headlines (org-element-map tree 'headline
			       (lambda (hl)
				 (and (funcall headline-fn hl) hl)))))
    ;; Get raw headline and convert to "emacs case"
    (--map (downcase (s-replace " " "-" it))
	   ;; Bit of a hack to remove links
	   (--map (replace-regexp-in-string
		   ".*\\[\\[.+\\]\\[\\(.+\\)\\]\\].*" "\\1"
		   (org-element-property :raw-value it))
		  snd-level-headlines))))

(defun ox-yaow--get-file-ordering-from-index (indexing-file-path)
  "Get the ordering of files described by INDEXING-FILE-PATH.

INDEXING-FILE-PATH should be an indexing file."
  (with-temp-buffer
    (insert-file-contents indexing-file-path)
    (-map
     (lambda (directory)
       (if (f-directory? (f-expand directory (f-dirname indexing-file-path)))
           directory
         ;; `f-swap-ext' will add the extension if none exists
         (f-swap-ext directory "org")))
     (ox-yaow--get-file-ordering-from-index-tree (org-element-parse-buffer)))))

(cl-defun ox-yaow--get-html-relative-link
    (file-path link-text &key (reference-path file-path))
  "Return a HTML link element with text LINK-TEXT.

The link element will have its href attribute equal to the path of FILE-PATH
relative to REFERENCE-PATH, but with a .html extension."
  (let* ((relative-path (f-relative file-path (f-dirname reference-path)))
	 (html-path (concat (f-no-ext relative-path) ".html")))
    (concat "<a href='"
	    (unless (char-equal ?. (elt html-path 0)) "./")
	    html-path "'>" link-text "</a>")))

(cl-defun ox-yaow--get-adjacent-strings (target-string strings &key (sort t))
  "Return a plist of strings \"adjacent\" to TARGET-STRING.

The plist will have the property :preceding as the string preceding
TARGET-STRING in STRINGS, and :succeeding as the string succeeding
TARGET-STRING in STRINGS.  nil is used in either case if no such string exists.
If SORT is t, then sort STRINGS first.  nil is used in place of strings if such
a string does not exist.  nil is returned if TARGET-STRING is not in STRINGS."
  (let* ((sorted-strings (if sort (sort strings #'string-lessp) strings))
	 (position (cl-position target-string strings :test #'string=)))
    (if position
	(let ((prev-idx (1- position))
	      (nxt-idx (1+ position)))
	  `(:preceding  ,(if (>= prev-idx 0) (nth prev-idx sorted-strings) nil)
	    :succeeding ,(if (< nxt-idx (length strings)) (nth nxt-idx sorted-strings) nil)))
      nil)))

(defun ox-yaow--get-nav-links (prev-file next-file)
  "Return a html string consisting of links to PREV-FILE and NEXT-FILE.

If one is nil it is ignored."
  (concat
   (when prev-file
     (concat "Previous: " (ox-yaow--get-html-relative-link
			   prev-file
			   (capitalize (s-replace "-" " " (f-base prev-file))))))
   (when (and prev-file next-file) ", ")
   (when next-file
     (concat "Next: " (ox-yaow--get-html-relative-link
		       next-file
		       (capitalize (s-replace "-" " " (f-base next-file))))))))

(cl-defun ox-yaow--get-up-file
    (target-file-path
     &key
     (indexing-file-p ox-yaow-indexing-file-p)
     (get-default-indexing-file ox-yaow-get-default-indexing-file))
  "Return the \"up file\" of the file pointed to by TARGET-FILE-PATH.

If TARGET-FILE-PATH points to an indexing file (determined by INDEXING-FILE-P),
return the path to the indexing file in the parent directory of
TARGET-FILE-PATH (or return the result of GET-DEFAULT-INDEXING-FILE if no such
file exists).  Else return the file path of the indexing file in the same
directory as TARGET-FILE-PATH."
  (let* ((directory (if (funcall indexing-file-p target-file-path)
		       (f-parent (f-parent target-file-path))
		     (f-parent target-file-path)))
	 (indexing-file (-first indexing-file-p (f-files directory))))
    (or indexing-file (funcall get-default-indexing-file directory))))

(defun ox-yaow--get-file-ordering-from-directory
    (directory-path &optional show-indexing-files file-blacklist)
  "Get the ordering of files in DIRECTORY-PATH and not in FILE-BLACKLIST.

When SHOW-INDEXING-FILES is non-nil, also include indexing files."
  (let ((indexing-file
         (funcall ox-yaow-get-default-indexing-file directory-path)))
    (if (f-exists-p indexing-file)
        (--map (f-join directory-path it)
               (ox-yaow--get-file-ordering-from-index indexing-file))
      (ox-yaow--org-entries directory-path (not show-indexing-files) file-blacklist))))

(cl-defun ox-yaow--get-adjacent-files
    (target-file file-list &optional file-blacklist &key (indexing-file-p ox-yaow-indexing-file-p))
  "Get files before and after TARGET-FILE in FILE-LIST.

Files in FILE-BLACKLIST are ignored.  These should all be full file paths.
INDEXING-FILE-P is a predicate used to determine whether a given file should be
treated as an indexing file."
  (let* ((indexing-file (-first indexing-file-p file-list))
	 (base-files (--map (f-base it) file-list))
	 (file-ordering
	  (if indexing-file
	      ;; Ensure links found in indexing file point to files in same dir
	      (--filter (member (f-base it) base-files)
			(--map (f-base it)
			       (ox-yaow--get-file-ordering-from-index indexing-file)))
	    base-files)))
    (ox-yaow--get-adjacent-strings (f-base target-file)
				   (--remove (member it file-blacklist)
                                             file-ordering)
                                   ;; TODO sort outside the function
				   :sort (unless indexing-file))))

(defun ox-yaow-template (contents info)
  "Transcode CONTENTS into yaow html format.

INFO is a plist used as a communication channel."
  (let* ((file-path (plist-get info :input-file))
         (wiki-home-path (f-expand (plist-get info :ox-yaow-wiki-home-file)))
         (filename (f-base file-path))
	 (directory (f-dirname filename))
	 (org-paths-same-level (f-files directory (lambda (file) (s-suffix? "org" file))))
	 (adj-files (ox-yaow--get-adjacent-files filename org-paths-same-level))
	 (next-file (plist-get adj-files :succeeding))
	 (prev-file (plist-get adj-files :preceding))
         (indexing-file-fn
          (lambda (f) (or (string= wiki-home-path f)
                          (ox-yaow--indexing-file-p f))))
	 (up-file (ox-yaow--get-up-file
                   file-path
                   :indexing-file-p
                   indexing-file-fn))
	 (base-html (org-html-template contents info)))
    (if (string= file-path wiki-home-path) base-html
      (replace-regexp-in-string
       "<h1" (concat (funcall ox-yaow-html-link-stitching-fn
			      file-path
			      prev-file next-file up-file)
		     "<h1")
       base-html))))

(cl-defun ox-yaow--get-index-file-str
    (file-path file-path-list &optional file-blacklist &key (depth 2))
  "Return the contents of the indexing file FILE-PATH as a string.

The indexing file will contain links to files in FILE-PATH-LIST, but not in
FILE-BLACKLIST, recursing down DEPTH directories."
  (cl-labels
      ((to-title (path) (capitalize (s-replace "-" " " (f-base path))))
       (index-file-str-rec
        (file-path-list depth base-path)
        (mapconcat
	 (lambda (path)
	   (concat
	    (format "** [[./%s][%s]]\n"
		    (f-swap-ext
                     (f-relative
                      (if (f-directory? path)
			  (funcall ox-yaow-get-default-indexing-file path)
			path)
                      (f-dirname base-path))
                     "html")
                    (to-title path))
	    (when-let* (((and (< 0 depth) (f-directory? path)))
                        (files (ox-yaow--get-file-ordering-from-directory
                                path nil file-blacklist))
                        (lower-str
		         (index-file-str-rec files (1- depth) base-path)))
              (s-replace "* " "** " lower-str))))
	 file-path-list "")))
    (concat
     "#+TITLE: " (to-title file-path) "\n"
     (index-file-str-rec file-path-list depth file-path))))

(defun ox-yaow--prep-directory
    (directory-path &optional file-blacklist depth no-log force)
  "Create an indexing file at DIRECTORY-PATH if appropriate.

Check if the (full) path described by DIRECTORY-PATH has an indexing file,
if it does not, create one.

If FORCE is non-nil then overwrite the existing indexing file.
The created indexing file will show subdirectories up to DEPTH.
Files present in FILE-BLACKLIST will not have links generated for them.
If NO-LOG is non-nil then this file will not be removed."
  (let* ((files (f-files directory-path (lambda (f) (s-ends-with-p ".org" f))))
	 (indexing-file (-first ox-yaow-indexing-file-p files)))
    (when (or force (not indexing-file))
      ;; Create file
      (let ((indexing-file-name
	      (funcall ox-yaow-get-default-indexing-file directory-path)))
	(with-temp-buffer
	  (insert (ox-yaow--get-index-file-str
		   indexing-file-name
		   (ox-yaow--org-entries directory-path nil file-blacklist)
                   file-blacklist
		   :depth (or depth 1)))
	  (write-region (point-min) (point-max) indexing-file-name)
          (unless no-log
            (setq ox-yaow--generated-files (cons indexing-file-name
                                                 ox-yaow--generated-files))))))))

(defun ox-yaow-preparation-fn (project-alist)
  "Create temporary indexing files for the project described in PROJECT-ALIST."
  (let* ((src-dir (plist-get project-alist :base-directory))
	 (depth (plist-get project-alist :ox-yaow-depth))
         (file-blacklist (plist-get project-alist :ox-yaow-file-blacklist))
         (file-blacklist-exp (-map #'f-expand file-blacklist)))
    (cl-loop for directory in (-filter #'ox-yaow--org-assoc-file-p
				       (f-directories src-dir nil t))
	     do
	     (ox-yaow--prep-directory directory file-blacklist-exp depth nil nil))))

(defun ox-yaow-completion-fn (_)
  "Remove temporary indexing files for the project described in PROJECT-ALIST."
  (cl-loop for generated-file in ox-yaow--generated-files do
	   ;; Just to be extra careful
	   (when (f-exists-p generated-file) (f-delete generated-file))
	   (message (concat "Deleted generated file: " generated-file)))
  (setq ox-yaow--generated-files nil))


;; Export options

(org-export-define-derived-backend 'ox-yaow-html 'html
  :options-alist `((:html-head "HTML_HEAD" nil ,ox-yaow-html-head newline))
  :menu-entry
  '(?h "Export to HTML"
       ((?w "As yaow wiki file" ox-yaow-org-export-to-html)))
  :translate-alist
  '((template . ox-yaow-template)))

(defun ox-yaow-org-export-to-html
    (&optional async subtreep visible-only body-only ext-plist)
  "Call `org-export-to-file' with the specified arguments.

A non-nil optional argument ASYNC means the process should happen
asynchronously.  The resulting buffer will then be accessible
through the `org-export-stack' interface.

Optional arguments SUBTREEP, VISIBLE-ONLY, BODY-ONLY and
EXT-PLIST are similar to those used in `org-export-as', which
see."
  (let* ((extension ".html")
	 (file (org-export-output-file-name extension subtreep))
	 (org-export-coding-system 'utf-8))
    (org-export-to-file 'ox-yaow-html file
      async subtreep visible-only body-only ext-plist)))

(defun ox-yaow-publish-to-html (plist filename pub-dir)
  "Publish an Org file to a the ox-yaow backend.

BACKEND is a symbol representing the back-end used for
transcoding.  FILENAME is the filename of the Org file to be
published.  EXTENSION is the extension used for the output
string, with the leading dot.  PLIST is the property list for the
given project.

Optional argument PUB-DIR, when non-nil is the publishing
directory.

Return output file name."
  (org-publish-org-to 'ox-yaow-html filename ".html" plist pub-dir))


;; Interactive functions

;;;###autoload
(defun ox-yaow-generate-indexing-file (depth)
  "Generate an indexing with for the directory which the current file resides.

The indexing file will have depth DEPTH."
  (interactive "nPlease input the indexing file depth: ")
  (if buffer-file-name
      (let* ((parent-dir (f-parent (buffer-file-name)))
             (indexing-file (funcall ox-yaow-get-default-indexing-file parent-dir)))
        (ox-yaow--prep-directory parent-dir nil depth t t)
        (find-file-other-window indexing-file))
    (message "Not visiting a file!")))

(provide 'ox-yaow)

;;; ox-yaow.el ends here
