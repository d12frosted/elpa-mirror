;;; org-protocol-jekyll.el --- Jekyll's handler for org-protocol

;; Copyright (C) 2013 Vladimir S. Ivanov

;; Author: Vladimir S. Ivanov <ivvl82@gmail.com>
;; Version: 0.1
;; Package-Version: 20170328.1639
;; Package-Commit: dec064a42d6dfe81dfde7ba59ece5ca103ac6334
;; Package-Requires: ((cl-lib "0.5"))

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
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

;; `org-protocol-jekyll' realizes the \"jekyll\" sub-protocol to open
;; sources of a site built with Jekyll (URL `http://jekyllrb.com') in
;; Emacs for editing. `org-protocol-jekyll' uses the sub-protocol
;; \"jekyll\" and maps URLs to local filenames defined in
;; `org-protocol-jekyll-alist'.

;; For further information, see README.md found here:
;; URL `https://github.com/vonavi/org-protocol-jekyll'.

;;; Code:

(require 'org-protocol)
(require 'cl-lib)

(defcustom org-protocol-jekyll-alist nil
  "Map URLs to local filenames for `org-protocol-jekyll' (jekyll).

Each element of this list must be of the form:

  (module-name :property value property: value ...)

where module-name is an arbitrary name.  All the values are strings.

Possible properties are:

  :base-url          - the base URL, e.g. http://www.example.com/project
  :permalink         - the permalink to generate URLs for the site
  :working-directory - the local working directory. This is, what
                       base-url will be replaced with.
  :working-suffix    - acceptable suffixes for the file converted to
                       HTML. Can be one suffix or a list of suffixes.

Example:

  (setq org-protocol-jekyll-alist
        '((\"Jekyll's awesome website.\"
           :base-url \"http://jekyllrb.com\"
           :permalink \"pretty\"
           :working-directory \"/home/user/jekyll\"
           :working-suffix (\".md\", \".markdown\"))
          (\"Local Jekyll's site.\"
           :base-url \"http://localhost:4000\"
           :permalink \"pretty\"
           :working-directory \"/home/user/jekyll\"
           :working-suffix (\".md\", \".markdown\"))))"
  :group 'org-protocol
  :type 'alist)

;; Register Jekyll's handler for org-protocol
(add-to-list 'org-protocol-protocol-alist
             '("org-jekyll"
               :protocol "jekyll"
               :function org-protocol-jekyll))

(defun org-protocol-jekyll (fname)
  "Process an org-protocol://jekyll style url.

Parameter: url

Old-style links such as org-protocol://jekyll://URL are
also recognized.

The location for a browser's bookmark should look like this:

  javascript:location.href = \\
      \\='org-protocol://jekyll?url=\\='+ \\
      encodeURIComponent(location.href);

FNAME should be a property list.  If not, an old-style link of the
form URL can also be used."
  ;; As we enter this function for a match on our protocol, the return
  ;; value defaults to nil.
  (let* ((splitparts (org-protocol-parse-parameters fname nil '(:url)))
         (url (org-protocol-sanitize-uri
               ;; Strip "[?#].*\'" if `url' is a redirect with another
               ;; ending than strip-suffix here:
               (replace-regexp-in-string "[?#].*\\'" ""
                                         (plist-get splitparts :url)))))

    ;; Note: url may still contain `%C3' et al here because browsers
    ;; tend to encode `&auml;' in URLs to `%25C3' - `%25' being `%'.
    ;; So the results may vary.

    (catch 'result
      (dolist (blog org-protocol-jekyll-alist)
        (let* ((base-url (plist-get (cdr blog) :base-url))
               (base-re (concat "\\`" (regexp-quote base-url) "/?")))

          (when (string-match base-re url)
            (let* ((site-url (replace-match "/" t t url))
                   (wdir (expand-file-name
                          (plist-get (cdr blog) :working-directory)))
                   (suf (plist-get (cdr blog) :working-suffix))
                   (suf-list (if (listp suf) suf (list suf))))

              ;; If the file wasn't converted
              (add-to-list 'suf-list ".html" t 'string=)

              ;; Remove trailing slash from the working directory
              (setq wdir (replace-regexp-in-string "/\\'" "" wdir))

              (mapc (lambda (file)
                      (dolist (add-suffix suf-list)
                        (let ((path (concat wdir file add-suffix)))
                          (cond ((file-readable-p path)
                                 (throw 'result path))
                                ((file-exists-p path)
                                 (message "%s: permission denied!" path)
                                 (throw 'result nil))))))
                    (append (org-protocol-jekyll-posts blog site-url)
                            (org-protocol-jekyll-pages blog site-url)))))))

      (message "No corresponding source file.")
      nil)))

(defun org-protocol-jekyll-pages (blog page-url)
  "Build a list of candidates for the source file of the ordinary
page with PAGE-URL (for post URL's, see
`org-protocol-jekyll-posts'). The working directory and file
extension are avoided."
  (let ((permalink (plist-get (cdr blog) :permalink))
        (end-pos (string-match "\\.html\\'" page-url)))
    (if end-pos
        (list (substring page-url 0 end-pos))
      (when (and (string= permalink "pretty")
                 (string-match "/\\'" page-url))
        (list (substring page-url 0 -1)
              (concat page-url "index"))))))

(defun org-protocol-jekyll-posts (blog post-url)
  "Build a list of candidates for the source file of the post
with POST-URL (for ordinary-page URL's, see
`org-protocol-jekyll-pages'). The working directory and file
extension are avoided."
  (let ((permalink (or (plist-get (cdr blog) :permalink) "date"))
        props file-list)

    (setq post-url
          (replace-regexp-in-string "/\\'" "/index.html" post-url t)

          permalink
          (cond ((string= permalink "date")
                 "/:categories/:year/:month/:day/:title.html")
                ((string= permalink "none")
                 "/:categories/:title.html")
                ((string= permalink "ordinal")
                 "/:categories/:year/:y_day/:title.html")
                ((string= permalink "pretty")
                 "/:categories/:year/:month/:day/:title/index.html")
                ((string-match "/\\'" permalink)
                 (concat permalink "index.html"))
                (t permalink)))

    (setq props
          (or
           ;; Match POST-URL with categories
           (org-protocol-jekyll-match post-url permalink)
           ;; Match POST-URL with categories excluded
           (org-protocol-jekyll-match
            post-url (replace-regexp-in-string
                      "//" "/" (replace-regexp-in-string
                                ":categories" "" permalink)))))

    (when props
      (let ((categories (nth 0 props))
            (date (nth 1 props))
            (title (nth 2 props)))
        (push (concat "/_drafts/" title) file-list)
        (push (concat "/_posts/" date "-" title) file-list)
        (when categories
          (push (concat "/" categories "/_drafts/" title) file-list)
          (push (concat "/" categories "/_posts/" date "-" title) file-list)))
      file-list)))

(defun org-protocol-jekyll-match (post-url permalink)
  "Match POST-URL to PERMALINK. Return a list containing the categories,
the date and the title for POST-URL, or nil otherwise."
  (let* (
         ;; Template variables for the permalink of post URL
         (template
          '(("year"        . "[0-9]\\{4\\}")
            ("month"       . "[0-9]\\{2\\}")
            ("day"         . "[0-9]\\{2\\}")
            ("title"       . "[^/]+")
            ("i_day"       . "[0-9]\\{1,2\\}")
            ("i_month"     . "[0-9]\\{1,2\\}")
            ("categories"  . "\\(?:[^/]+/\\)*[^/]+")
            ("short_month" . "[a-zA-Z]\\{3,4\\}")
            ("y_day"       . "[0-9]\\{3\\}")
            ("output_ext"  . "\\.[a-zA-Z]+")))

         ;; Build regexp LINK-RE matching PERMALINK
         (token-re (concat ":\\(" (mapconcat 'car template "\\|") "\\)"))
         (slices (mapcar 'regexp-quote (split-string permalink token-re)))
         (len (1- (cl-list-length slices)))
         (link-re (concat "\\`" (mapconcat 'identity slices token-re) "\\'"))

         tokens re-list url-re values tok-alist val-list)

    ;; Build regexp LINK-RE matching POST-URL
    (string-match link-re permalink)
    (dotimes (i len)
      (let* ((n (- len i))
             (tok (match-string n permalink))
             (re (cdr (assoc tok template)))
             (str (nth n slices)))
        (push tok tokens)
        (push str re-list)
        (push (concat "\\(" re "\\)") re-list)))
    (push (nth 0 slices) re-list)
    (setq url-re (apply 'concat `("\\`" ,@re-list "\\'")))

    ;; TOK-ALIST associates the template values in PERMALINK with the
    ;; corresponding values in POST-URL
    (when (string-match url-re post-url)
      (dotimes (i len)
        (push (match-string (- len i) post-url) values))
      (setq tok-alist (cl-pairlis tokens values))

      ;; Assign each variable corresponding to a template value in
      ;; PERMALINK to its value in POST-URL
      (let (year month day title i_day i_month categories
                 short_month y_day output_ext)
        (mapc (lambda (c)
                (set (intern (car c)) (cdr c)))
              tok-alist)

        ;; Build the resulting list
        (list categories
              (format "%04d-%02d-%02d"
                      (string-to-number year)
                      (cond (month (string-to-number month))
                            (i_month (string-to-number i_month))
                            (short_month
                             (1+ (cl-position
                                  (capitalize short_month)
                                  '("Jan" "Feb" "Mar" "Apr"
                                    "May" "June" "July" "Aug"
                                    "Sept" "Oct" "Nov" "Dec")
                                  :test 'string=))))
                      (cond (day (string-to-number day))
                            (i_day (string-to-number i_day))))
              title)))))

(provide 'org-protocol-jekyll)
;;; org-protocol-jekyll.el ends here
