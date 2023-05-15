;;; org-emms.el --- Play multimedia files from org-mode -*- lexical-binding: t; -*-

;; Copyright (C) 2016-2018 Jonathan Gregory

;; Author: Jonathan Gregory <jgrg at autistici dot org>
;; Version: 0.1
;; Package-Version: 20230514.1710
;; Package-Commit: 0fd7688d226ec098b47f5e4dab0f040e541e6b65
;; URL: https://gitlab.com/jagrg/org-emms
;; Keywords: multimedia
;; Package-Requires: ((emacs "24.1") (org "9.3") (emms "0.0"))

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

;; This package provides a new org link type for playing back
;; multimedia files from org-mode using EMMS, The Emacs Multimedia
;; System. If the link contains a track position, playback will start
;; at the specified position. For example:

;; [[emms:/path/to/audio.mp3::2:43]]     Starts playback at 2 min 43 sec.
;; [[emms:/path/to/audio.mp3::1:10:45]]  Starts playback at 1 hr 10 min 45 sec.
;; [[emms:/path/to/audio.mp3::49]]       Starts playback at 0 min 49 sec.

;; The two main commands are `org-emms-insert-track' and
;; `org-emms-insert-track-position'. The latter is especially useful
;; for aligning text with audio when transcribing spoken language.

;; It is also possible to make a usual org link (with `org-store-link'
;; command) from EMMS playlist and browser buffers, and then insert it
;; into an org-mode buffer (with `org-insert-link' command).

;; See also: http://orgmode.org/worg/code/elisp/org-player.el

;;; Code:

(require 'org)
(require 'emms)
(require 'emms-playing-time)

(defgroup org-emms nil
  "Connection between EMMS and `org-mode'."
  :prefix "org-emms-"
  :group 'multimedia)

(defcustom org-emms-default-directory nil
  "A directory where multimedia files are stored."
  :type 'directory
  :group 'org-emms)

(defcustom org-emms-delay 0
  "Time in seconds between starting playing and seeking to time.
If your org link has a track position, but the EMMS player does
not start playing at that position, most likely the problem is
that it starts seeking before the player starts playing.  If this
is your case, set this variable to 1 or 2 seconds."
  :type 'integer
  :group 'org-emms)

(defcustom org-emms-time-format "%.2h:%.2m:%.2s"
  "Format string for a track position in org links.
This string is passed to `format-seconds' function."
  :type 'string
  :group 'org-emms)

(defun org-emms-time-string-to-seconds (s)
  "Convert timestring S (\"HH:MM:SS\") to a number of seconds.
Hours, minutes and leading zeros are optional."
  (save-match-data
    (if (stringp s)
	(if (string-match "\\([0-9]+:\\)?\\([0-9]+\\):\\([0-9]+\\)" s)
	    (let ((hh (if (match-beginning 1) (string-to-number (match-string 1 s)) 0))
		  (mm (string-to-number (match-string 2 s)))
		  (ss (string-to-number (match-string 3 s))))
	      (+ (* hh 3600) (* mm 60) ss))
	  (string-to-number s))
      s)))

(defun org-emms-play (file)
  "Play multimedia FILE from `org-mode'.
If link contains a track position, start there.  Otherwise, playback
from the start."
  (let* ((path (split-string file "::"))
	 (file (expand-file-name (car path)))
	 (time (org-emms-time-string-to-seconds (cadr path))))
    ;; Do not start a track again (just seek to time) if we want to open
    ;; a link with the currently playing track.
    (unless (and emms-player-playing-p
                 (string= file
                          (emms-track-name
                           (emms-playlist-current-selected-track))))
      (emms-play-file file)
      (and time
           (> org-emms-delay 0)
           (sleep-for org-emms-delay)))
    (when time
      (emms-seek-to time))))

(org-link-set-parameters
 "emms"
 :follow #'org-emms-play
 :store #'org-emms-store-link)

(defun org-emms-make-link ()
  "Return org link for the the current EMMS track.
The return value is a cons cell (link . description)."
  (let ((track (emms-playlist-current-selected-track)))
    (cons (concat "emms:" (emms-track-name track)
                  (and (/= 0 emms-playing-time)
                       (concat "::"
                               (format-seconds org-emms-time-format
                                               emms-playing-time))))
          (emms-info-track-description track))))

(defun org-emms-store-link ()
  "Store org link for the current playing file in EMMS."
  (when (derived-mode-p 'emms-playlist-mode
                        'emms-browser-mode)
    (let ((link (org-emms-make-link)))
      (org-link-store-props
       :type        "emms"
       :link        (car link)
       :description (cdr link)))))

;;;###autoload
(defun org-emms-insert-link (arg)
  "Insert org link using completion.
Prompt for a file name and link description.  With a prefix ARG, prompt
for a track position."
  (interactive "P")
  (let ((file (read-file-name "File: " org-emms-default-directory)))
    (if arg
	(let ((tp (read-string "Track position (hh:mm:ss): ")))
	  (insert (format "[[emms:%s::%s][%s]]" (file-relative-name file) tp tp)))
      (let ((desc (read-string "Description: ")))
	(insert
	 (if (equal desc "")
	     (format "[[emms:%s]]" (file-relative-name file))
	   (format "[[emms:%s][%s]]" (file-relative-name file) desc)))))))

;;;###autoload
(defun org-emms-insert-track ()
  "Insert current selected track as an org link."
  (interactive)
  (let* ((track (emms-playlist-current-selected-track))
	 (file (emms-track-name track))
	 (title (emms-track-get track 'info-title)))
    (when (derived-mode-p 'org-mode)
      (insert
       (format "[[emms:%s][%s]]" file title)))))

;;;###autoload
(defun org-emms-insert-track-position ()
  "Insert current track position as an org link."
  (interactive)
  (let* ((track (emms-playlist-current-selected-track))
	 (file (emms-track-name track))
	 (tp (format-seconds org-emms-time-format emms-playing-time)))
    (insert
     (if (derived-mode-p 'org-mode)
	 (format "[[emms:%s::%s][%s]]" file tp tp)
       (format "[%s]" tp)))))

(provide 'org-emms)
;;; org-emms.el ends here
