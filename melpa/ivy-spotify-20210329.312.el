;;; ivy-spotify.el --- Search spotify with ivy  -*- lexical-binding: t; -*-

;; Author: Jose A Ortega Ruiz <jao@gnu.org>
;; Maintainer: Jose A Ortega Ruiz
;; Keywords: multimedia
;; Package-Version: 20210329.312
;; Package-Commit: 5bf63dacc5df8a74860e80dabd16afce68a24a36
;; License: GPL-3.0-or-later
;; Version: 0.1
;; Homepage: https://codeberg.org/jao/espotify
;; Package-Requires: ((emacs "26.1") (espotify "0.1") (ivy "0.13.1"))

;; Copyright (C) 2021  Jose A Ortega Ruiz

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

;; This package provides an ivy-based completion interface to
;; spotify's search API, analogous to counsel-spotify, using the
;; smaller espotify library.  The following interactive commands
;; are defined:
;;
;;  - `ivy-spotify-album'
;;  - `ivy-spotify-artist'
;;  - `ivy-spotify-track'
;;  - `ivy-spotify-playlist'
;;
;; A completing prompt will appear upon invoking it, and when
;; the input varies significantly or you end your input with `='
;; a web search will be triggered.  Several ivy actions (play,
;; play album, show candidate info) are available.
;;
;; For espotify to work, you need to set valid values for
;; `espotify-client-id' and `espotify-client-secret'.  To get
;; valid values for them, one just needs to register a spotify
;; application at https://developer.spotify.com/my-applications

;; All .el files have been automatically generated from the literate program
;; https://codeberg.org/jao/espotify/src/branch/main/readme.org

;;; Code:

(require 'espotify)
(require 'ivy)

(defun ivy-spotify--search-by (type)
  "Perform an asynchronous spotify search, for resources of the given TYPE."
  (let ((current-term "")
        (candidates))
    (lambda (term)
      (when-let (term (espotify-check-term current-term term))
        (ivy-spotify--unwind)
        (espotify-search-all
         (lambda (its)
           (let ((cs (mapcar #'espotify-format-item its)))
             (ivy-update-candidates (setq candidates cs))))
         (setq current-term term)
         type))
      (or candidates 0))))

(defun ivy-spotify--unwind ()
  "Delete any open spotify connections."
  (dolist (name '("api.spotify.com" "accounts.spotify.com"))
    (when-let (p (get-process name))
      (delete-process p))))

(defun ivy-spotify--play-album (candidate)
  "Play album associated with selected CANDIDATE."
  (let ((item (espotify-candidate-metadata candidate)))
    (if-let (album (if (string= "album" (alist-get 'type item ""))
                       item
                     (alist-get 'album item)))
        (espotify-play-uri (alist-get 'uri album))
      (message "No album found for '%s'" (alist-get 'name item)))))

(defvar ivy-spotify-search-history nil
  "History for spotify searches.")

(defun ivy-spotify-search-by (type)
  "Search spotify resources of the given TYPE using ivy."
  (ivy-read (format "Search %s: " type)
            (ivy-spotify--search-by type)
            :dynamic-collection t
            :unwind #'ivy-spotify--unwind
            :history 'ivy-spotify-search-history
            :caller (make-symbol (format "ivy-spotify-%s" type))
            :action `(1 ("p" espotify-play-candidate ,(format "Play %s" type))
                        ("a" ivy-spotify--play-album "Play album")
                        ("i" espotify-show-candidate-info "Show info"))))

;;;###autoload
(defun ivy-spotify-album ()
  "Query spotify for an album using ivy."
  (interactive)
  (ivy-spotify-search-by 'album))

;;;###autoload
(defun ivy-spotify-artist ()
  "Query spotify for an artist using ivy."
  (interactive)
  (ivy-spotify-search-by 'artist))

;;;###autoload
(defun ivy-spotify-track ()
  "Query spotify for a track using ivy."
  (interactive)
  (ivy-spotify-search-by 'track))

;;;###autoload
(defun ivy-spotify-playlist ()
  "Query spotify for a playlist using ivy."
  (interactive)
  (ivy-spotify-search-by 'playlist))


(provide 'ivy-spotify)
;;; ivy-spotify.el ends here
