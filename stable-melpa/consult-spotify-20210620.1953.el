;;; consult-spotify.el --- Spotify queries using consult  -*- lexical-binding: t; -*-

;; Author: Jose A Ortega Ruiz <jao@gnu.org>
;; Maintainer: Jose A Ortega Ruiz
;; Keywords: multimedia
;; Package-Version: 20210620.1953
;; Package-Commit: 5bf63dacc5df8a74860e80dabd16afce68a24a36
;; License: GPL-3.0-or-later
;; Version: 0.1
;; Homepage: https://codeberg.org/jao/espotify
;; Package-Requires: ((emacs "26.1") (consult "0.8") (espotify "0.1"))

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

;; This package provides functions to interactively query
;; Spotify using consult.  Its main entry points are the
;; commands `consult-spotify-album', `consult-spotify-artist',
;; `consult-spotify-playlist' and `consult-spotify-track'.
;;
;; This package is implemeted using the espotify library.
;; For espotify to work, you need to set valid values for
;; `espotify-client-id' and `espotify-client-secret'.  To get
;; valid values for them, one just needs to register a spotify
;; application at https://developer.spotify.com/my-applications

;; All .el files have been automatically generated from the literate program
;; https://codeberg.org/jao/espotify/src/branch/main/readme.org

;;; Code:

(require 'seq)
(require 'subr-x)
(require 'espotify)
(require 'consult)

(defvar consult-spotify-history nil)

(defun consult-spotify-by (type &optional filter)
  "Consult spotify by TYPE with FILTER."
  (consult--read (consult-spotify--search-generator type filter)
                 :prompt (format "Search %ss: " type)
                 :lookup #'consult--lookup-member
                 :category 'spotify-search-item
                 :history 'consult-spotify-history
                 :initial (consult--async-split-initial "")
                 :require-match t))


(defun consult-spotify--search-generator (type filter)
  "Generate an async search closure for TYPE and FILTER."
  (thread-first (consult--async-sink)
    (consult--async-refresh-immediate)
    (consult--async-map #'espotify-format-item)
    (consult-spotify--async-search type filter)
    (consult--async-throttle)
    (consult--async-split)))

(defun consult-spotify--async-search (next type filter)
  "Async search with NEXT, TYPE and FILTER."
  (let ((current ""))
    (lambda (action)
      (pcase action
        ((pred stringp)
         (when-let (term (espotify-check-term current action))
           (setq current term)
           (espotify-search-all
            (lambda (x)
              (funcall next 'flush)
              (funcall next x))
            current
            type
            filter)))
        (_ (funcall next action))))))

;;;###autoload
(defun consult-spotify-album ()
  "Query spotify for an album using consult."
  (interactive)
  (espotify-play-candidate (consult-spotify-by 'album)))

;;;###autoload
(defun consult-spotify-artist ()
  "Query spotify for an artist using consult."
  (interactive)
  (espotify-play-candidate (consult-spotify-by 'artist)))

;;;###autoload
(defun consult-spotify-track ()
  "Query spotify for a track using consult."
  (interactive)
  (espotify-play-candidate (consult-spotify-by 'track)))

;;;###autoload
(defun consult-spotify-playlist ()
  "Query spotify for a track using consult."
  (interactive)
  (espotify-play-candidate (consult-spotify-by 'playlist)))


(with-eval-after-load "marginalia"
  (defun consult-spotify--annotate (cand)
    "Compute marginalia fields for candidate CAND."
    (when-let (x (espotify-candidate-metadata cand))
      (marginalia--fields
       ((alist-get 'type x "") :face 'marginalia-mode :width 10)
       ((if-let (d (alist-get 'duration_ms x))
            (let ((secs (/ d 1000)))
              (format "%02d:%02d" (/ secs 60) (mod secs 60)))
          ""))
       ((if-let (d (alist-get 'total_tracks x)) (format "%s tracks" d) "")
        :face 'marginalia-size :width 12)
       ((if-let (d (alist-get 'release_date (alist-get 'album x x)))
            (format "%s" d)
          "")
        :face 'marginalia-date :width 10))))

  (add-to-list 'marginalia-annotator-registry
               '(spotify-search-item consult-spotify--annotate)))


(provide 'consult-spotify)
;;; consult-spotify.el ends here
