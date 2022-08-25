;;; asx.el --- Ask StackExchange/StackOverflow -*- lexical-binding: t; -*-

;; Author: Alex Ragone <ragonedk@gmail.com>
;; Created: 24 August 2019
;; Homepage: https://github.com/ragone/asx
;; Keywords: convenience
;; Package-Version: 20191024.1100
;; Package-Commit: 5ca12cc51bb02b5926adf9a7976ba9ca08a1ea21
;; Version: 0.1.1
;; Package-Requires: ((emacs "26.1"))

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
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package allows you to search any StackExchange site specified in
;; `asx-sites' and insert the top post in an Org-mode buffer. For better searching,
;; this uses Google and DuckDuckGo as it is superior to StackExchange's searching
;; capabilities. More search engines can be defined using `asx-search-engine-alist'.
;;
;; # Usage
;; Run ~M-x asx~ and enter query when prompted.

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'dom)
(require 'org)
(require 'request)
(require 'seq)
(require 'shr)
(require 'subr-x)

;;;; Customization

(defgroup asx nil
  "Ask StackExchange."
  :group 'convenience
  :version "25.1"
  :link '(emacs-commentary-link "asx.el"))

(defcustom asx-number-of-answers 3
  "Answers to include."
  :type 'number
  :group 'asx)

(defcustom asx-prompt-post-p nil
  "If non-nil, prompt for post to show.
Otherwise show the first post."
  :type 'boolean
  :group 'asx)

(defcustom asx-sites '("stackoverflow.com"
                       "stackexchange.com"
                       "superuser.com"
                       "serverfault.com"
                       "askubuntu.com")
  "Sites to search."
  :type 'list
  :group 'asx)

(defcustom asx-search-engine 'google
  "Search engine to use."
  :type 'symbol
  :group 'asx)

(defcustom asx-search-engine-alist '((google
                                      :format "https://www.google.com/search?q=%s"
                                      :extract-fn #'asx--extract-links-google)
                                     (duckduckgo
                                      :format "https://www.duckduckgo.com/?q=%s"
                                      :extract-fn #'asx--extract-links-duckduckgo))
  "Alist of search engine configurations."
  :type '(alist :key-type symbol :value-type plist)
  :group 'asx)

(defcustom asx-skip-unanswered t
  "If non-nil, skip posts which have no answers."
  :type 'boolean
  :group 'asx)

(defcustom asx-buffer-name "*AskStackExchange*"
  "Name of buffer to insert post."
  :type 'string
  :group 'asx)

;;;; Variables

(defvar asx--current-post-index 0
  "Current post index.")

(defvar asx--posts nil
  "List of posts.")

(defvar asx--query-history nil
  "History of queries.")

(defvar asx--user-agents
  '("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.7; rv:11.0) Gecko/20100101 Firefox/11.0"
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:22.0) Gecko/20100 101 Firefox/22.0"
    "Mozilla/5.0 (Windows NT 6.1; rv:11.0) Gecko/20100101 Firefox/11.0"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_7_4) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5"
    "Mozilla/5.0 (Windows; Windows NT 6.1) AppleWebKit/536.5 (KHTML, like Gecko) Chrome/19.0.1084.46 Safari/536.5")
  "List of user agent.")

;;;; Functions

;;;;; Commands

;;;###autoload
(defun asx (query)
  "Search for QUERY.
If a prefix argument is provided, the initial input will be the symbol at point."
  (interactive (list (asx--read-query)))
  (when (string-empty-p query)
    (user-error "No query specified"))
  (setq asx--query-history (append (list query) asx--query-history))
  (message "Loading: %s" query)
  (asx--request (asx--query-construct query)
                #'asx--handle-search))

(defun asx-jump ()
  "Jump to post."
  (interactive)
  (asx--select-post asx--posts)
  (asx--request-post (asx--get-current-post)))

(defun asx-next-post ()
  "Go to next post."
  (interactive)
  (asx-n-post 1))

(defun asx-previous-post ()
  "Go to previous post."
  (interactive)
  (asx-n-post -1))

(defun asx-reload-post ()
  "Reload current post."
  (interactive)
  (asx-n-post 0))

(defun asx-first-post ()
  "Go to first post."
  (interactive)
  (asx-n-post (- asx--current-post-index)))

;;;;; Support

(defun asx--read-query ()
  "Read query from user."
  (cond ((and (require 'ivy nil t) (fboundp 'counsel-google))
         (asx--ivy-search))
        ((and (require 'helm-net nil t) (fboundp 'helm-google-suggest))
         (asx--helm-search))
        (t
         (read-string
          "Query: "
          (asx--initial-input)
          'asx--query-history))))

(defun asx--helm-search ()
  "Query search engine with Helm."
  (helm-other-buffer
   (helm-build-sync-source "Query"
     :candidates (lambda ()
                   (funcall helm-google-suggest-default-function))
     :history 'asx--query-history
     :volatile t
     :requires-pattern 3)
   "*Helm Google*"))


(defun asx--ivy-search ()
  "Query search engine with Ivy."
  (require 'json)
  (ivy-read "Query: " #'counsel-search-function
            :dynamic-collection t
            :history 'asx--query-history
            :initial-input (asx--initial-input)
            :caller 'counsel-search))

(defun asx--initial-input ()
  "Get initial input for query."
  (and current-prefix-arg (asx--symbol-or-region)))

(defun asx--request (url callback &optional error-callback)
  "Request URL with CALLBACK.
Optionally specify ERROR-CALLBACK."
  (let ((request-curl-options (list (format "-A %s" (asx--get-user-agent)))))
    (request url
             :parser (lambda () (libxml-parse-html-region (point-min) (point-max)))
             :error (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
                                   (if error-callback
                                       (funcall error-callback url)
                                     (error "%s" error-thrown))))
             :success (cl-function (lambda (&key data &allow-other-keys)
                                     (funcall callback data))))))

(defun asx--request-post (post)
  "Request POST."
  (message "Loading: %s" (car post))
  (asx--request (cdr post)
                #'asx--insert-post-dom
                #'asx--remove-and-next))

(defun asx--remove-and-next (url)
  "Delete the URL from `asx--posts'.
Try to insert the next post instead."
  (setq asx--posts (seq-remove
                    (lambda (post)
                      (string= (cdr post) url))
                    asx--posts))
  (unless asx--posts
    (user-error "No posts found"))
  (asx-n-post 1))

(defun asx--get-user-agent ()
  "Return random user-agent from `asx--user-agents'."
  (seq-random-elt asx--user-agents))

(defun asx--get-buffer ()
  "Get or create `asx-buffer-name' buffer."
  (get-buffer-create asx-buffer-name))

(defun asx--handle-search (dom)
  "Handle search for DOM."
  (setq asx--posts (asx--filter-posts
                    (asx--extract-links dom)))
  (unless asx--posts
    (user-error "No posts found"))
  (if asx-prompt-post-p
      (asx--select-post asx--posts)
    (setq asx--current-post-index 0))
  (asx--request-post (asx--get-current-post)))

(defun asx--select-post (posts)
  "Prompt user to select from POSTS."
  (setq asx--current-post-index
        (let ((posts-with-selection (asx--get-posts-with-prefix posts)))
          (cl-position (completing-read "Post: " posts-with-selection)
                       posts-with-selection
                       :test #'equal
                       :key #'car))))

(defun asx--get-posts-with-prefix (posts)
  "Return POSTS including the title prefix."
  (mapcar (lambda (post)
            (cons (concat (asx--get-prefix post) (car post))
                  (cdr post)))
          posts))

(defun asx--get-prefix (post)
  "Return the prefix for POST."
  (cond ((equal (car post) (car (asx--get-current-post)))
         "=> ")
        (t "   ")))

(defun asx--symbol-or-region ()
  "Grab the symbol at point or selected region."
  (cond ((use-region-p)
         (buffer-substring-no-properties (region-beginning)
                                         (region-end)))
        ((require 'xref nil t)
         ;; A little smarter than using `symbol-at-point', though in most cases,
         ;; xref ends up using `symbol-at-point' anyway.
         (xref-backend-identifier-at-point (xref-find-backend)))))

(defun asx--extract-links (dom)
  "Extract links from DOM."
  (funcall (cadr (plist-get (asx--get-search-engine) :extract-fn))
           dom))

(defun asx--extract-links-google (dom)
  "Extract links from Google DOM."
  (mapcar (lambda (node)
            (cons
             (dom-text (car (dom-by-tag node 'h3)))
             (dom-attr (dom-child-by-tag node 'a) 'href)))
          (dom-by-class dom "^r$")))

(defun asx--extract-links-duckduckgo (dom)
  "Extract links from DuckDuckGo DOM."
  (mapcar (lambda (node)
            (cons
             (dom-texts (car (dom-by-class node "result__a")))
             (string-trim (dom-text (car (dom-by-class node "result__url"))))))
          (dom-by-class dom "result ")))

(defun asx--filter-posts (links)
  "Filter LINKS for questions."
  (seq-filter (lambda (link)
                (string-match "questions/[0-9]+" (cdr link)))
              links))

(defun asx--get-current-post ()
  "Return current post."
  (nth asx--current-post-index asx--posts))

(defun asx--insert-post-dom (dom)
  "Insert post DOM."
  (let ((post (asx--normalize-post dom)))
    (if (and asx-skip-unanswered
             (not (plist-get post :answers)))
        (asx--remove-and-next (plist-get post :url))
      (asx--insert-post post))))

(defun asx--query-construct (query)
  "Return URI for QUERY."
  (concat (format (plist-get (asx--get-search-engine) :format)
                  (url-hexify-string (asx--query-string query)))))

(defun asx--get-search-engine ()
  "Return the search engine from `asx-search-engine-list'."
  (alist-get asx-search-engine asx-search-engine-alist))

(defun asx--query-string (query)
  "Return the query string for QUERY."
  (concat query " " (asx--query-string-sites)))

(defun asx--query-string-sites ()
  "Return query string for sites to search."
  (mapconcat (lambda (site)
               (concat "site:" site))
             asx-sites
             " OR "))

(defun asx--normalize-post (dom)
  "Return plist of DOM representing the post."
  (list :url (cdr (asx--get-current-post))
        :title (dom-text (car (dom-by-class dom "question-hyperlink")))
        :body (dom-by-class (car (dom-by-id dom "^question$")) "post-text")
        :score (dom-text (dom-by-class (car (dom-by-id dom "^question$")) "js-vote-count"))
        :answers (asx--get-answers dom)
        :tags (asx--get-tags dom)))

(defun asx--get-tags (dom)
  "Return tags from DOM node."
  (let ((tag-doms (dom-by-class (dom-by-class dom "^post-taglist")
                                "^post-tag$")))
    (mapcar #'dom-text tag-doms)))

(defun asx--get-answers (dom)
  "Return answers from DOM node."
  (mapcar (lambda (node)
            (let ((parent (dom-parent dom node)))
              (list :body (dom-by-class parent "post-text")
                    :score (dom-text (dom-by-class parent "js-vote-count")))))
          (dom-by-class dom "answercell")))

(defun asx--prepare-buffer ()
  "Prepare buffer to insert content."
  (let ((asx-buffer (asx--get-buffer)))
    (unless (equal (current-buffer) asx-buffer)
      (switch-to-buffer-other-window asx-buffer))
    (read-only-mode -1)
    (erase-buffer)
    (insert "#+STARTUP: overview indent\n")))

(defun asx--finalize-buffer ()
  "Finalize buffer."
  (delete-trailing-whitespace)
  (org-mode)
  (visual-line-mode)
  (read-only-mode)
  (goto-char (point-min)))

(defun asx--insert-post (post)
  "Insert POST into `asx-buffer-name'."
  (asx--prepare-buffer)
  (asx--insert-question post)
  (asx--insert-answers
   (seq-take (plist-get post :answers) asx-number-of-answers))
  (asx--finalize-buffer))

(defun asx--insert-question (question)
  "Insert QUESTION."
  (insert
   (concat "#+TITLE: " (plist-get question :title)
           "\n"
           (plist-get question :url)
           "\n"
           (format "* Question (%s)" (plist-get question :score))))
  (asx--insert-node (plist-get question :body))
  (asx--insert-tags (plist-get question :tags)))

(defun asx--insert-tags (tags)
  "Insert TAGS."
  (insert "\nTags: ")
  (mapc (lambda (tag)
          (insert tag)
          (insert " "))
        tags))

(defun asx--insert-answers (answers)
  "Insert ANSWERS."
  (let ((first-answer t))
    (mapcar (lambda (answer)
              (insert (format "\n* Answer (%s)\n" (plist-get answer :score)))
              (when first-answer
                (insert ":PROPERTIES:\n:VISIBILITY: all\n:END:\n")
                (setq first-answer nil))
              (asx--insert-node (plist-get answer :body)))
            answers)))

(defun asx--map-node (node)
  "Map NODE to Org compatible DOM node."
  (if (and (listp node)
           (listp (cdr node)))
      (cond
       ((and (equal (car node) 'a)
             (not (dom-by-tag node 'img)))
        (org-link-make-string (dom-attr node 'href) (dom-texts node)))
       ((equal (car node) 'pre)
        (dom-node 'pre
                  '()
                  "#+BEGIN_EXAMPLE "
                  (or (asx--get-language-maybe node) "prog")
                  "\n"
                  (nthcdr 2 node)
                  (if (dom-attr node 'class)
                      "\n")
                  "#+END_EXAMPLE"))
       (t (mapcar #'asx--map-node node)))
    node))

(defun asx--get-language-maybe (node)
  "Return language from NODE, if any."
  (if-let ((class (dom-attr node 'class)))
      (asx--get-language-string class)))

(defun asx--get-language-string (class)
  "Return language string from CLASS."
  (when (string-match "lang-\\b\\(.+?\\)\\b" class)
    (match-string 1 class)))

(defun asx--insert-node (node)
  "Map NODE and insert."
  (let ((shr-bullet "- ")
        (shr-width 0)
        (shr-use-fonts nil))
    (shr-insert-document (mapcar #'asx--map-node node))))

(defun asx-n-post (n)
  "Jump N steps in `asx--posts' and insert the post."
  (setq asx--current-post-index
        (mod (+ n asx--current-post-index) (length asx--posts)))
  (asx--request-post (asx--get-current-post)))

;;;; Footer

(provide 'asx)

;;; asx.el ends here
