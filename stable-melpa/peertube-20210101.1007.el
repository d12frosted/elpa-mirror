;;; peertube.el --- Query and download PeerTube videos -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 yoctocell

;; Author: yoctocell <public@yoctocell.xyz>
;; URL: https://git.sr.ht/~yoctocell/peertube
;; Package-Version: 20210101.1007
;; Package-Commit: bb529db154596e86327829edbd7144b67cf72255
;; Version: 0.3.1
;; Package-Requires: ((emacs "25.1") (transmission "0.12.1"))
;; Keywords: peertube multimedia
;; License: GNU General Public License >= 3

;; This program is free software: you can redistribute it and/or modify
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

;; This package provides an interface to search for PeerTube videos
;; and lists the results in a buffer as a tabulated list.
;;
;; peertube.el queries https://sepiasearch.org/, the official search
;; engine for PeerTube.  Learn more at https://joinpeertube.org/.

;;; Code:

(require 'json)
(require 'cl-lib)
(require 'transmission)
(require 'image-mode)

(defvar peertube-videos '()
  "List of videos displayed in the *peertube* buffer.")

(defvar peertube-search-term ""
  "Current peertube search term.")

(defvar peertube-sort-methods '(relevance most-recent least-recent)
  "Sorting methods for that PeerTube accepts.")

(defgroup peertube nil
  "Query PeerTube videos in Emacs."
  :group 'convenience)

(defcustom peertube-disable-nsfw t
  "Whether to disable NSFW content."
  :type 'boolean
  :group 'peertube)

(defcustom peertube-video-resolutions '(720 1080 480 360)
  "List of available resolutions for videos in `peertube'.

The order matters, the first one will be the default choice.
Note: Not all resolutions are available for all videos."
  :type 'list
  :group 'peertube)

(defcustom peertube-channel-length 15
  "Length of the creator of the video."
  :type 'integer
  :group 'peertube)

(defcustom peertube-title-length 50
  "Length of the title of the video."
  :type 'integer
  :group 'peertube)

(defcustom peertube-sort-method 'relevance
  "How to sort search results."
  :type 'symbol
  :options peertube-sort-methods
  :group 'peertube)

(defface peertube-channel-face
  '((t :inherit font-lock-variable-name-face))
  "Face used for the channel.")

(defface peertube-date-face
  '((t :inherit font-lock-string-face))
  "Face used for the date of upload.")

(defface peertube-duration-face
  '((t :inherit error))
  "Face used for the duration.")

(defface peertube-tags-face
  '((t :inherit font-lock-constant-face))
  "Face used for the tags.")

(defface peertube-title-face
  '((t :inherit font-lock-type-face))
  "Face used for the video title.")

(defface peertube-views-face
  '((t :inherit font-lock-builtin-face))
  "Face used for the view count.")

(define-derived-mode peertube-mode tabulated-list-mode "peertube-mode"
  "Major mode for peertube.")

(defvar peertube-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "o" #'peertube-open-video)
    (define-key map "s" #'peertube-search)
    (define-key map "d" #'peertube-download-video)
    (define-key map "g" #'peertube-draw-buffer)
    (define-key map "i" #'peertube-show-video-info)
    (define-key map "t" #'peertube-preview-thumbnail)
    (define-key map "n" #'next-line)
    (define-key map "p" #'previous-line)
    map)
  "Keymap for `peertube-mode'.")

(defun peertube-quit ()
  "Close peertube buffer."
  (interactive)
  (quit-window))

(defun peertube--remove-nsfw (video)
  "Remove VIDEO if marked as NSFW."
  (let ((nsfw (peertube-video-nsfw video)))
    (if (eq nsfw t)
	nil
      video)))

(defun peertube--format-channel (channel)
  "Format the CHANNEL name in the *peertube* buffer."
  (propertize channel 'face `(:inherit peertube-channel-face)))

(defun peertube--format-date (date)
  "Format the DATE in the *peertube* buffer."
  (propertize (seq-take date 10) 'face `(:inherit peertube-date-face)))

(defun peertube--format-duration (duration)
  "Format the DURATION from seconds to hh:mm:ss in the *peertube* buffer."
  (let ((formatted-string (concat (format-seconds "%.2h" duration)
				  ":"
				  (format-seconds "%.2m" (mod duration 3600))
				  ":"
				  (format-seconds "%.2s" (mod duration 60))
				  "  ")))
    (propertize formatted-string 'face `(:inherit peertube-duration-face))))

(defun peertube--format-tags (tags)
  "Format the TAGS in the *peertube* buffer."
  (let ((formatted-string (if (eq (length tags) 0)
			      (format "")
			    (format "%s" tags))))
    (propertize formatted-string 'face `(:inherit peertube-tags-face))))

(defun peertube--format-title (title)
  "Format the video TITLE int the *peertube* buffer."
  (propertize title 'face `(:inherit peertube-title-face)))

(defun peertube--format-views (views)
  "Format the VIEWS in the *peertube* buffer.

Format to thousands (K) or millions (M) if necessary."
  (let ((formatted-string
	 (cond ((< 1000000 views)
		(format "%5sM" (/ (round views 100000) (float 10))))
	       ((< 1000 views)
		(format "%5sK" (/ (round views 100) (float 10))))
	       (t (format "%6s" views)))))
    (propertize formatted-string 'face `(:inherit peertube-views-face))))

(defun peertube--insert-entry (video)
  "Insert VIDEO into the current buffer."
  (list (peertube-video-url video)
	(vector (peertube--format-duration (peertube-video-duration video))
		(peertube--format-title (peertube-video-title video))
		(peertube--format-channel (peertube-video-channel video))
		(peertube--format-date (peertube-video-date video))
		(peertube--format-views (peertube-video-views video))
		(peertube--format-tags (peertube-video-tags video)))))

(defun peertube-draw-buffer ()
  "Draw buffer with video entries."
  (interactive)
  (read-only-mode -1)
  (erase-buffer)
  (read-only-mode 1)
  (setq tabulated-list-format `[("Duration" 10 t)
				("Title" ,peertube-title-length t)
				("Channel" ,peertube-channel-length t)
				("Date" 10 t)
				("Views" 6 t)
				("Tags" 10 nil)])
  (setq tabulated-list-entries (mapcar #'peertube--insert-entry
				       peertube-videos))
  (tabulated-list-init-header)
  (tabulated-list-print))

(defun peertube--get-current-video ()
  "Get the currently selected video."
  (nth (1- (line-number-at-pos)) peertube-videos))

(defun peertube-download-video ()
  "Download the video under the cursor using `transmission-add'."
  (interactive)
  (let* ((url (peertube-video-url (peertube--get-current-video)))
	 (res (completing-read "Resolution of video: "
			       (mapcar #'number-to-string peertube-video-resolutions)))
	 (torrent-link (replace-regexp-in-string
			"https://\\(.*\\)/videos/watch/\\(.*$\\)"
			(concat "https://\\1/download/torrents/\\2-"
				res
				".torrent")
			url)))
    (message torrent-link)
    (transmission-add torrent-link))
  (message "Downloading video..."))

(defun peertube-open-video ()
  "Open the video under the cursor using `browse-url'."
  (interactive)
  (let ((url (peertube-video-url (peertube--get-current-video))))
    (browse-url url)))

(defun peertube-goto-channel ()
  "Go to the channel page of the current video."
  (interactive)
  (let ((url (peertube-video-channelUrl (peertube--get-current-video))))
    (browse-url url)))

(defun peertube-preview-thumbnail ()
  "View the thumbnail of the current video."
  (interactive)
  (let ((url (peertube-video-thumbnailUrl (peertube--get-current-video)))
	(temp-file (make-temp-file "thumbnail")))
      (call-process "curl" nil nil nil url "-o" temp-file)
      (find-file temp-file)
      (image-transform-set-scale 4)))

(defun peertube-show-video-info ()
  "Show more information about video under point."
  (interactive)
  (let ((title (concat "Title: " (peertube-video-title (peertube--get-current-video)) "\n"))
	(channel (concat "Channel: " (peertube-video-channel (peertube--get-current-video)) "\n"))
	(date (concat "Published: " (peertube-video-date (peertube--get-current-video)) "\n"))
	(views (concat "Views: " (number-to-string (peertube-video-views (peertube--get-current-video))) "\n"))
	(duration (concat "Duration: " (number-to-string (peertube-video-duration (peertube--get-current-video))) "\n"))
	(likes (concat "Likes: " (number-to-string (peertube-video-likes (peertube--get-current-video))) "\n"))
	(dislikes (concat "Dislikes: " (number-to-string (peertube-video-dislikes (peertube--get-current-video))) "\n"))
	(description (concat "Description\n" (peertube-video-description (peertube--get-current-video)))))
    (switch-to-buffer "*peertube-info*")
    (with-current-buffer "*peertube-info*"
      (erase-buffer)
      (insert
       (concat title channel date views duration likes dislikes description))))
  (read-only-mode 1))

(defun peertube-change-sort-method ()
  "Change sorting method used for `peertube' and update the results buffer."
  (interactive)
  (let ((method (intern (completing-read "PeerTube sorting method: "
					 peertube-sort-methods))))
    (setq peertube-sort-method method))
  (peertube-search peertube-search-term))

(defun peertube-search (query)
  "Search PeerTube for QUERY."
  (interactive "sSearch PeerTube: ")
  (let ((videos (if peertube-disable-nsfw
		    (cl-remove-if #'null (mapcar #'peertube--remove-nsfw (peertube-query query)))
		  (peertube-query query))))
    (setq peertube-videos videos))
  (setq peertube-search-term query)
  (peertube-draw-buffer))

;; Store metadata for PeerTube videos
(cl-defstruct (peertube-video (:constructor peertube--create-video)
			      (:copier nil))
  "Metadata for a PeerTube video."
  (title "" :read-only t)
  (account "" :read-only t)
  (accountUrl "" :read-only t)
  (channel "" :read-only t)
  (channelUrl "" :read-only t)
  (date "" :read-only t)
  (category "" :read-only t)
  (language "" :read-only t)
  (duration 0 :read-only t)
  (tags [] :read-only t)
  (url "" :read-only t)
  (views 0 :read-only t)
  (likes 0 :read-only t)
  (dislikes 0 :read-only t)
  (nsfw nil :read-only t)
  (thumbnailUrl "" :read-only t)
  (description "" :read-only t)
  (host "" :read-only t))

(defun peertube--get-sort-method ()
  "Given a sorting method SORT, return the 'real' name of the method."
  (cond ((eq peertube-sort-method 'least-recent) "publishedAt")
	((eq peertube-sort-method 'most-recent) "-publishedAt")
	(t "-match")))

(defun peertube--pre-process-query (query)
  "Remove spaces in QUERY to make them api friendly."
  (replace-regexp-in-string "\\s-" "%20" query))

(defun peertube--call-api (query)
  "Call the PeerTube search API with QUERY as the search term.

Curl is used to call 'search.joinpeertube.org', the result gets
parsed by `json-read'."
  (let ((sort (peertube--get-sort-method))
	(query (peertube--pre-process-query query)))
    (with-temp-buffer
      (call-process "curl" nil t nil "--silent" "-X" "GET"
		    (concat
		     "https://sepiasearch.org/api/v1/search/videos?search="
		     query "&sort=" sort "&page=1"))
      (goto-char (point-min))
      ;; ((total . [0-9]{4}) (data . [(... ... ...) (... ... ...) ...]))
      ;;                             └───────────────────────────────┘
      ;;                                   extract useful data
      (cdr (car (cdr (json-read)))))))

(defun peertube-query (query)
  "Query PeerTube for QUERY and parse the results."
  (interactive)
  (let ((videos (peertube--call-api query)))
    (dotimes (i (length videos))
      (let ((v (aref videos i)))
	(aset videos i
	      (peertube--create-video
	       :title (assoc-default 'name v)
	       :account (assoc-default 'name (assoc-default 'account v))
	       :accountUrl (assoc-default 'url (assoc-default 'account v))
	       :channel (assoc-default 'name (assoc-default 'channel v))
	       :channelUrl (assoc-default 'url (assoc-default 'channel v))
	       :date (assoc-default 'publishedAt v)
	       :category (assoc-default 'label (assoc-default 'category v))
	       :language (assoc-default 'label (assoc-default 'language v))
	       :duration (assoc-default 'duration v)
	       :tags (assoc-default 'tags v)
	       :url (assoc-default 'url v)
	       :views (assoc-default 'views v)
	       :likes (assoc-default 'likes v)
	       :dislikes (assoc-default 'dislikes v)
	       :nsfw (assoc-default 'nsfw v)
	       :thumbnailUrl (assoc-default 'thumbnailUrl v)
	       :description (assoc-default 'description v)
	       :host (assoc-default 'host (assoc-default 'channel v))))))
    videos))


;;;###autoload
(defun peertube ()
  "Open the '*peertube*' buffer."
  (interactive)
  (switch-to-buffer "*peertube*")
  (unless (eq major-mode 'peertube-mode)
    (peertube-mode)
    (call-interactively #'peertube-search)))

(provide 'peertube)

;;; peertube.el ends here
