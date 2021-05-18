;;; hnreader.el --- A hackernews reader -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Thanh Vuong

;; Author: Thanh Vuong <thanhvg@gmail.com>
;; URL: https://github.com/thanhvg/emacs-hnreader/
;; Package-Version: 20210518.428
;; Package-Commit: 0bda35e6b2063ddecca2fe2b0dd21f46a3391de3
;; Package-Requires: ((emacs "25.1") (promise "1.1") (request "0.3.0") (org "9.2"))
;; Version: 0.2

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
;; This package renders hackernews website at https://news.ycombinator.com/ in
;; an org buffer. Almost everything works. Features that are not supported are
;; account related features. You cannot add comment, downvote or upvote.

;;; Dependencies
;; `promise' and `request' are required.
;; user must have `org-mode' 9.2 or later installed also.

;;; Commands
;; hnreader-news: Load news page.
;; hnreader-past: Load past page.
;; hnreader-ask: Load ask page.
;; hnreader-show: Load show page.
;; hnreader-newest: Load new link page.
;; hnreader-more: Load more.
;; hnreader-back: Go back to previous page.
;; hnreader-comment: read an HN item url such as https://news.ycombinator.com/item?id=1

;;; Customization
;; hnreader-history-max: max number history items to remember.
;; hnreader-view-comments-in-same-window: if nil then will not create new window
;; when viewing comments

;;; Code:
(require 'promise)
(require 'request)
(require 'shr)
(require 'dom)
(require 'cl-lib)
(require 'org)

;; public variables
(defgroup hnreader nil
  "Search and read stackoverflow and sisters's sites."
  :group 'extensions
  :group 'convenience
  :version "25.1"
  :link '(emacs-commentary-link "hnreader.el"))

(defcustom hnreader-history-max 100
  "Max history to remember."
  :type 'integer
  :group 'hnreader)

(defcustom hnreader-view-comments-in-same-window t
  "Max history to remember."
  :type 'boolean
  :group 'hnreader)

;; internal stuff
(defvar hnreader--buffer "*HN*"
  "Buffer for HN pages.")

(defvar hnreader--comment-buffer "*HNComments*"
  "Comment buffer.")

(defvar hnreader--indent 40
  "Tab value which is the width of an indent.
top level commnet is 0 indent
second one is 40
third one is 80.")

(defvar hnreader--history '()
  "History list.")

(defvar hnreader--more-link nil
  "Load more link.")

;;;###autoload
(defun hnreader-back ()
  "Go back to previous location in history."
  (interactive)
  (let ((link (nth 1 hnreader--history)))
    (if link
        (progn
          (setq hnreader--history (cdr hnreader--history))
          (when (> (length hnreader--history) hnreader-history-max)
            (setq hnreader--history (seq-take hnreader--history hnreader-history-max)))
          (hnreader-read-page-back link))
      (message "Nothing to go back."))))

(defun hnreader--get-hn-buffer ()
  "Get hn buffer."
  (get-buffer-create hnreader--buffer))

(defun hnreader--get-hn-comment-buffer ()
  "Get hn commnet buffer."
  (get-buffer-create hnreader--comment-buffer))

(defun hnreader--promise-dom (url)
  "Promise (url . dom) from URL with curl."
  (promise-new
   (lambda (resolve reject)
     (request url
       :parser (lambda ()
                 (goto-char (point-min))
                 (while (re-search-forward ">\\*" nil t)
                   (replace-match ">-"))
                 (libxml-parse-html-region (point-min) (point-max)))
       :error (cl-function (lambda (&rest args &key error-thrown &allow-other-keys)
                             (funcall reject  error-thrown)))
       :success (cl-function (lambda (&key data &allow-other-keys)
                               (funcall resolve data)))))))

(defun hnreader--prepare-buffer (buf &optional msg)
  "Print MSG message and prepare window for BUF buffer."
  (when (not (equal (window-buffer) buf))
    (if hnreader-view-comments-in-same-window
        ;; (switch-to-buffer buf)
        (select-window (display-buffer buf '(display-buffer-use-some-window)))
      (switch-to-buffer-other-window buf)))
  ;; (display-buffer buf '(display-buffer-use-some-window (inhibit-same-window . t))))
  (with-current-buffer buf
    (read-only-mode -1)
    (erase-buffer)
    (insert (if msg
                msg
              "Loading...")))
  buf)

(defun hnreader--print-header ()
  "Print header links to current buffer."
  (insert "[[elisp:(hnreader-news)][News]] | ")
  (insert "[[elisp:(hnreader-newest)][New]] | ")
  (insert "[[elisp:(hnreader-past)][Past]] | ")
  (insert "[[elisp:(hnreader-ask)][Ask]] | ")
  (insert "[[elisp:(hnreader-show)][Show]] | ")
  (insert "[[elisp:(hnreader-jobs)][Jobs]]"))

(defun hnreader--print-frontpage-item (thing subtext)
  "Print THING dom and SUBTEXT dom."
  (let ((url (format "https://news.ycombinator.com/item?id=%s" (dom-attr thing 'id)))
        (story-link (dom-attr (dom-by-class thing "^storylink$") 'href)))
    (insert (format "\n* %s %s (%s) [%s]\n"
                    ;; rank
                    (dom-text (dom-by-class thing "^rank$"))
                    ;; title
                    (dom-text (dom-by-class thing "^storylink$"))
                    ;; points
                    (dom-text (dom-by-class subtext "^score$"))
                    ;; comments
                    (dom-text (last (dom-by-tag subtext 'a)))))
    ;; (setq thanh subtext)
    ;; link
    (insert (format "%s\n[[eww:%s][view story in eww]]\n" story-link story-link))
    ;; comment link
    (insert (format "[[elisp:(hnreader-comment \"%s\")][%s]]"
                    url
                    url))))

(defun hnreader--get-morelink (dom)
  "Get more link from DOM."
  (let* ((more-link (dom-by-class dom "morelink"))
         (full-more-link (concat "https://news.ycombinator.com/"
                                 (dom-attr more-link 'href))))
    (setq hnreader--more-link full-more-link)
    (format "[[elisp:(hnreader-read-page \"%s\")][More]]"
            full-more-link)))

(defun hnreader--get-time-top-link (node)
  "Get date link in route /past from NODE."
  (let ((a-link (dom-attr (dom-by-tag node 'a) 'href))
        (text (dom-texts node)))
    (format "[[elisp:(hnreader-read-page \"https://news.ycombinator.com/%s\")][%s]]"
            a-link
            text)))

(defun hnreader--past-time-top-links (node-list)
  "Get date, month and year links from NODE-LIST."
  (if (= 3 (length node-list))
      (concat (seq-reduce (lambda (acc it)
                            (concat acc (hnreader--get-time-top-link it) " "))
                          node-list
                          "- Go back to a "))
    (concat (seq-reduce (lambda (acc it)
                          (concat acc (hnreader--get-time-top-link it) " "))
                        (seq-take node-list 3)
                        "- Go back to a ")
            (seq-reduce (lambda (acc it)
                          (concat acc (hnreader--get-time-top-link it) " "))
                        (seq-drop node-list 3)
                        "- Go forward to a "))))

(defun hnreader--get-route-top-info (dom)
  "Get top info of route like title, date of hn routes such as front, past from DOM."
  (let* ((space-page (dom-by-id dom "^pagespace$"))
         (title (dom-attr space-page 'title))
         (hn-more (dom-by-class dom "^hnmore$")))
    (if hn-more
        (format "\n%s %s"
                title
                (hnreader--past-time-top-links hn-more))
      (format "\n%s" title))))

(defun hnreader--print-frontpage (dom buf url)
  "Print raw DOM and URL on BUF."
  (let ((things (dom-by-class dom "^athing$"))
        (subtexts (dom-by-class dom "^subtext$")))
    (with-current-buffer buf
      (read-only-mode -1)
      (erase-buffer)
      (insert "#+STARTUP: overview indent\n")
      (hnreader--print-header)
      (insert (hnreader--get-route-top-info dom))
      (cl-mapcar #'hnreader--print-frontpage-item things subtexts)
      ;; (setq-local org-confirm-elisp-link-function nil)
      (if hnreader--history
          (insert "\n* "(format "[[elisp:(hnreader-back)][< Back]]" ) " | ")
        (insert "\n* "))
      (insert (hnreader--get-morelink dom) " | ")
      (insert (format "[[elisp:(hnreader-read-page-back \"%s\")][Reload]]" url) )
      (org-mode)
      (goto-char (point-min))
      (forward-line 2))))

(defun hnreader--get-title (dom)
  "Get title and link from DOM comment page."
  (let ((a-link (dom-by-class dom "^storylink$")))
    (cons (dom-text a-link) (dom-attr a-link 'href))))

(defun hnreader--get-post-info (dom)
  "Get top info about the DOM comment page."
  (let* ((fat-item (dom-by-class dom "^fatitem$"))
         (user (dom-by-class fat-item "^hnuser$"))
         (score (dom-by-class fat-item "^score$"))
         (tr-tag (dom-by-tag fat-item 'tr))
         (comment-count (last (dom-by-tag (dom-by-class fat-item "^subtext$") 'a)))
         (intro (if (= (length tr-tag) 6)
                    (nth 3 tr-tag)
                  nil)))
    ;; (setq thanh tr-tag)
    ;; (setq thanh-fat fat-item)
    (cons
     (format "%s | by %s | %s\n"
             (dom-text score)
             (dom-text user)
             (dom-text comment-count))
     intro)))

(defun hnreader--print-node (node)
  "Print the NODE with extra options."
  (let ((shr-width 80)
        (shr-use-fonts nil))
    (shr-insert-document node)))

(defun hnreader--print-comments (dom url)
  "Print DOM comment and URL to buffer."
  (let ((comments (dom-by-class dom "^athing comtr$"))
        (title (hnreader--get-title dom))
        (info (hnreader--get-post-info dom))
        (more-link (dom-by-class dom "morelink")))
    (with-current-buffer (hnreader--get-hn-comment-buffer)
      (read-only-mode -1)
      (erase-buffer)
      (insert "#+STARTUP: overview indent\n")
      (insert "#+TITLE: " (car title))
      (insert (format "\n%s\n[[eww:%s][view story in eww]]\n" (cdr title) (cdr title)))
      (insert (car info))
      (when (cdr info)
        (insert "\n")
        (hnreader--print-node (cdr info)))
      (dolist (comment comments)
        ;; (setq thanh comment)
        (insert (format "%s %s\n"
                        (hnreader--get-indent
                         (hnreader--get-img-tag-width comment))
                        (hnreader--get-comment-owner comment)))
        (hnreader--print-node (hnreader--get-comment comment)))
      (when more-link
        (insert "\n* " (format "[[elisp:(hnreader-comment \"%s\")][More]]" (concat "https://news.ycombinator.com/"
                                                                                   (dom-attr more-link 'href)))))
      (insert "\n* " (format  "[[elisp:(hnreader-comment \"%s\")][Reload]]" url))
      (org-mode)
      ;; (org-shifttab 3)
      (goto-char (point-min))
      (forward-line 2))))

(defun hnreader--get-img-tag-width (comment-dom)
  "Get width attribute of img tag in COMMENT-DOM."
  (string-to-number
   (dom-attr (dom-by-tag (dom-by-class comment-dom "^ind$") 'img)
             'width)))

(defun hnreader--get-indent (width)
  "Return headline star string from WIDTH of img tag."
  (let ((stars "\n*")) (dotimes (_ (round (/ width hnreader--indent)) stars)
                         (setq stars (concat stars "*")))))

(defun hnreader--get-comment-owner (comment-dom)
  "Return user who wrote this COMMENT-DOM."
  (dom-text (dom-by-class comment-dom "^hnuser$")))

(defun hnreader--it-to-it (it)
  "Map node to node.
IT is an element in the DOM tree. Map to different IT when it is
a, img or pre. Othewise just copy"
  (if (and (listp it)
           (listp (cdr it))) ;; check for list but not cons
      (if (and (equal (car it) 'a)
               (not (dom-by-tag it 'img))) ;; bail out if img
          ;; (dom-attr it 'href)
          `(span nil ,(dom-attr it 'href))
        (mapcar #'hnreader--it-to-it it))
    it))

(defun hnreader--get-comment (comment-dom)
  "Get comment dom from COMMENT-DOM."
  ;; (dom-by-class comment-dom "^commtext"))
  (hnreader--it-to-it (dom-by-class comment-dom "^commtext")))

(defun hnreader-readpage-promise (url)
  "Promise HN URL."
  (hnreader--prepare-buffer (hnreader--get-hn-buffer))
  (promise-chain (hnreader--promise-dom url)
    (then (lambda (result)
            (hnreader--print-frontpage result (hnreader--get-hn-buffer) url)))
    (promise-catch (lambda (reason)
                     (message "catch error in promise prontpage: %s" reason)))))

(defun hnreader-read-page-back (url)
  "Print HN URL page and won't change the history."
  (interactive "sLink: ")
  (hnreader-readpage-promise url)
  nil)

(defun hnreader-read-page (url)
  "Print HN URL page.
Also upate `hnreader--history'."
  (interactive "sLink: ")
  (setq hnreader--history (cons url hnreader--history))
  (hnreader-readpage-promise url)
  nil)

;;;###autoload
(defun hnreader-news()
  "Read front page."
  (interactive)
  (hnreader-read-page "https://news.ycombinator.com/news"))

;;;###autoload
(defun hnreader-past()
  "Read past page."
  (interactive)
  (hnreader-read-page "https://news.ycombinator.com/front"))

;;;###autoload
(defun hnreader-newest()
  "Read past page."
  (interactive)
  (hnreader-read-page "https://news.ycombinator.com/newest"))

;;;###autoload
(defun hnreader-ask ()
  "Read ask page."
  (interactive)
  (hnreader-read-page "https://news.ycombinator.com/ask"))

;;;###autoload
(defun hnreader-show ()
  "Read show page."
  (interactive)
  (hnreader-read-page "https://news.ycombinator.com/show"))

;;;###autoload
(defun hnreader-jobs ()
  "Read jobs page."
  (interactive)
  (hnreader-read-page "https://news.ycombinator.com/jobs"))

;;;###autoload
(defun hnreader-more()
  "Load more."
  (interactive)
  (if hnreader--more-link
      (hnreader-read-page hnreader--more-link)
    (message "no more link.")))

(defun hnreader-promise-comment (url)
  "Promise to print hn URL page to buffer."
  (hnreader--prepare-buffer (hnreader--get-hn-comment-buffer))
  (promise-chain (hnreader--promise-dom url)
    (then (lambda (dom)
            (hnreader--print-comments dom url)))
    (promise-catch (lambda (reason)
                     (message "catch error in promise comments: %s" reason)))))

;;;###autoload
(defun hnreader-comment (url)
  "Print hn URL page to buffer."
  (interactive "sLink: ")
  (hnreader-promise-comment url)
  nil)

;;;###autoload
(defun hnreader-org-insert-hn-link (url)
  "Insert link in org buffer to open a hn item link"
  (interactive "sUrl: ")
  (with-current-buffer (current-buffer)
    (insert (format "[[elisp:(hnreader-comment \"%s\")][%s]]"
                    url
                    url))))

(provide 'hnreader)
;;; hnreader.el ends here
