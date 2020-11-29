;;; ytel.el --- Query YouTube via Invidious -*- lexical-binding: t; -*-

;; This file is NOT part of Emacs.

;; This  program is  free  software; you  can  redistribute it  and/or
;; modify it  under the  terms of  the GNU  General Public  License as
;; published by the Free Software  Foundation; either version 2 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT  ANY  WARRANTY;  without   even  the  implied  warranty  of
;; MERCHANTABILITY or FITNESS  FOR A PARTICULAR PURPOSE.   See the GNU
;; General Public License for more details.

;; You should have  received a copy of the GNU  General Public License
;; along  with  this program;  if  not,  write  to the  Free  Software
;; Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
;; USA

;; Author: Gabriele Rastello
;; Version: 0.1.0
;; Package-Version: 20200725.1056
;; Package-Commit: d40bc7ead8d4d7e4d16b03b66a93d63bef51cc5f
;; Keywords: youtube matching multimedia
;; URL: https://github.com/grastello/ytel
;; License: GNU General Public License >= 3
;; Package-Requires: ((emacs "25.3"))

;;; Commentary:

;; This package provide a major mode to search YouTube videos via an elfeed-like
;; buffer.  Information about videos displayed in this buffer can be extracted
;; and manipulated by user-defined functions to do various things such as:
;; - playing them in some video player
;; - download them
;; The limit is the sky.
;;
;; ytel works by querying YouTube via the Invidious apis (learn more on that here:
;; https://github.com/omarroth/invidious).

;;; Code:

(require 'cl-lib)
(require 'json)
(require 'seq)

(defgroup ytel ()
  "An Emacs Youtube \"front-end\"."
  :group 'comm)

(defcustom ytel-sort-criterion 'relevance
  "Criterion to sort the results of the search query."
  :type 'symbol
  :options '(relevance rating upload_date view_count)
  :group 'ytel)

(defvar ytel-invidious-api-url "https://invidio.us"
  "Url to an Invidious instance.")

(defvar ytel-invidious-default-query-fields "author,lengthSeconds,title,videoId,authorId,viewCount,published"
  "Default fields of interest for video search.")

(defvar ytel-videos '()
  "List of videos currently on display.")

(defvar ytel-published-date-time-string "%Y-%m-%d"
  "Time-string used to render the published date of the video.
See `format-time-string' for information on how to edit this variable.")

(defvar-local ytel-current-page 1
  "Current page of the current `ytel-search-term'")

(defvar-local ytel-search-term ""
  "Current search string as used by `ytel-search'")

(defvar ytel-author-name-reserved-space 20
  "Number of characters reserved for the channel's name in the *ytel* buffer.
Note that there will always 3 extra spaces for eventual dots (for names that are
too long).")

(defvar ytel-title-video-reserved-space 100
  "Number of characters reserved for the video title in the *ytel* buffer.
Note that there will always 3 extra spaces for eventual dots (for names that are
too long).")

(defface ytel-video-published-face
  '((((class color) (background light)) (:foreground "#a0a"))
    (((class color) (background dark))  (:foreground "#7a7")))
  "Face used for the video published date.")

(defface ytel-channel-name-face
  '((((class color) (background light)) (:foreground "#aa0"))
    (((class color) (background dark))  (:foreground "#ff0")))
  "Face used for channel names.")

(defface ytel-video-length-face
  '((((class color) (background light)) (:foreground "#aaa"))
    (((class color) (background dark))  (:foreground "#77a")))
  "Face used for the video length.")

(defface ytel-video-view-face
  '((((class color) (background light)) (:foreground "#00a"))
    (((class color) (background dark))  (:foreground "#aa7")))
  "Face used for the video views.")

(defvar ytel-mode-map
  (let ((map (make-sparse-keymap)))
    (suppress-keymap map)
    (define-key map "q" #'ytel-quit)
    (define-key map "h" #'describe-mode)
    (define-key map "n" #'next-line)
    (define-key map "p" #'previous-line)
    (define-key map "s" #'ytel-search)
    (define-key map ">" #'ytel-search-next-page)
    (define-key map "<" #'ytel-search-previous-page)
    map)
  "Keymap for `ytel-mode'.")

(define-derived-mode ytel-mode text-mode
  "ytel-mode"
  (setq buffer-read-only t)
  (buffer-disable-undo)
  (make-local-variable 'ytel-videos))

(defun ytel-quit ()
  "Quit ytel buffer."
  (interactive)
  (quit-window))

(defun ytel--format-author (name)
  "Format a channel NAME to be inserted in the *ytel* buffer."
  (let* ((n (string-width name))
	 (extra-chars (- n ytel-author-name-reserved-space))
	 (formatted-string (if (<= extra-chars 0)
			       (concat name
				       (make-string (abs extra-chars) ?\ )
				       "   ")
			     (concat (seq-subseq name 0 ytel-author-name-reserved-space)
				     "..."))))
    (propertize formatted-string 'face 'ytel-channel-name-face)))

(defun ytel--format-title (title)
  "Format a video TITLE to be inserted in the *ytel* buffer."
  (let* ((n (string-width title))
	 (extra-chars (- n ytel-title-video-reserved-space))
	 (formatted-string (if (<= extra-chars 0)
			       (concat title
				       (make-string (abs extra-chars) ?\ )
				       "   ")
			     (concat (seq-subseq title 0 ytel-title-video-reserved-space)
				     "..."))))
    formatted-string))

(defun ytel--format-video-length (seconds)
  "Given an amount of SECONDS, format it nicely to be inserted in the *ytel* buffer."
  (let ((formatted-string (concat (format-seconds "%.2h" seconds)
				  ":"
				  (format-seconds "%.2m" (mod seconds 3600))
				  ":"
				  (format-seconds "%.2s" (mod seconds 60)))))
    (propertize formatted-string 'face 'ytel-video-length-face)))

(defun ytel--format-video-views (views)
  "Format video VIEWS to be inserted in the *ytel* buffer."
  (propertize (concat "[views:" (number-to-string views) "]") 'face 'ytel-video-view-face))

(defun ytel--format-video-published (published)
  "Format video PUBLISHED date to be inserted in the *ytel* buffer."
  (propertize (format-time-string ytel-published-date-time-string (seconds-to-time published))
	      'face 'ytel-video-published-face))

(defun ytel--insert-video (video)
  "Insert `VIDEO' in the current buffer."
  (insert (ytel--format-video-published (ytel-video-published video))
	  " "
	  (ytel--format-author (ytel-video-author video))
	  " "
	  (ytel--format-video-length (ytel-video-length video))
	  " "
	  (ytel--format-title (ytel-video-title video))
	  " "
	  (ytel--format-video-views (ytel-video-views video))))

(defun ytel--draw-buffer ()
  "Draws the ytel buffer i.e. clear everything and write down all videos in `ytel-videos'."
  (let ((inhibit-read-only t)
	(current-line      (line-number-at-pos)))
    (erase-buffer)
    (setf header-line-format (concat "Search results for "
				     (propertize ytel-search-term 'face 'ytel-video-published-face)
				     ", page "
				     (number-to-string ytel-current-page)))
    (seq-do (lambda (v)
	      (ytel--insert-video v)
	      (insert "\n"))
	    ytel-videos)
    (goto-char (point-min))))

(defun ytel-search (query)
  "Search youtube for `QUERY', and redraw the buffer."
  (interactive "sSearch terms: ")
  (setf ytel-current-page 1)
  (setf ytel-search-term query)
  (setf ytel-videos (ytel--query query ytel-current-page))
  (ytel--draw-buffer))

(defun ytel-search-next-page ()
  "Switch to the next page of the current search.  Redraw the buffer."
  (interactive)
  (setf ytel-videos (ytel--query ytel-search-term
				 (1+ ytel-current-page)))
  (setf ytel-current-page (1+ ytel-current-page))
  (ytel--draw-buffer))

(defun ytel-search-previous-page ()
  "Switch to the previous page of the current search.  Redraw the buffer."
  (interactive)
  (when (> ytel-current-page 1)
    (setf ytel-videos (ytel--query ytel-search-term
				   (1- ytel-current-page)))
    (setf ytel-current-page (1- ytel-current-page))
    (ytel--draw-buffer)))

(defun ytel-get-current-video ()
  "Get the currently selected video."
  (aref ytel-videos (1- (line-number-at-pos))))

(defun ytel-buffer ()
  "Name for the main ytel buffer."
  (get-buffer-create "*ytel*"))

;;;###autoload
(defun ytel ()
  "Enter ytel."
  (interactive)
  (switch-to-buffer (ytel-buffer))
  (unless (eq major-mode 'ytel-mode)
    (ytel-mode))
  (when (seq-empty-p ytel-search-term)
    (call-interactively #'ytel-search)))

;; Youtube interface stuff below.
(cl-defstruct (ytel-video (:constructor ytel-video--create)
			  (:copier nil))
  "Information about a Youtube video."
  (title     "" :read-only t)
  (id        0  :read-only t)
  (author    "" :read-only t)
  (authorId  "" :read-only t)
  (length    0  :read-only t)
  (views     0  :read-only t)
  (published 0 :read-only t))

(defun ytel--API-call (method args)
  "Perform a call to the invidious API method METHOD passing ARGS.

Curl is used to perform the request.  An error is thrown if it exits with a non
zero exit code otherwise the request body is parsed by `json-read' and returned."
  (with-temp-buffer
    (let ((exit-code (call-process "curl" nil t nil
				   "--silent"
				   "-X" "GET"
				   (concat ytel-invidious-api-url
					   "/api/v1/" method
					   "?" (url-build-query-string args)))))
      (unless (= exit-code 0)
	(error "Curl had problems connecting to Invidious"))
      (goto-char (point-min))
      (json-read))))

(defun ytel--query (string n)
  "Query youtube for STRING, return the Nth page of results."
  (let ((videos (ytel--API-call "search" `(("q" ,string)
                                           ("sort_by" ,(symbol-name ytel-sort-criterion))
					   ("page" ,n)
					   ("fields" ,ytel-invidious-default-query-fields)))))
    (dotimes (i (length videos))
      (let ((v (aref videos i)))
	(aset videos i
	      (ytel-video--create :title     (assoc-default 'title v)
				  :author    (assoc-default 'author v)
				  :authorId  (assoc-default 'authorId v)
				  :length    (assoc-default 'lengthSeconds v)
				  :id        (assoc-default 'videoId v)
				  :views     (assoc-default 'viewCount v)
				  :published (assoc-default 'published v)))))
    videos))

(provide 'ytel)

;;; ytel.el ends here
