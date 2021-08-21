;;; lms.el --- Squeezebox / Logitech Media Server frontend    -*- lexical-binding: t -*-

;; Copyright (C) 2017-21 Free Software Foundation, Inc.
;; Time-stamp: <2021-08-20 23:52:36 inigo>

;; Author: Iñigo Serna <inigoserna@gmx.com>
;; URL: https://hg.serna.eu/emacs/lms
;; Package-Version: 20210820.2200
;; Package-Commit: 05c8fd16ff94590393b6b0a9cb193ec9572a9c97
;; Version: 1.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: multimedia

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; `lms.el' is a frontend for Squeezebox / Logitech Media Server.
;;
;; More information on what a "squeezebox controller" is at
;; https://inigo.katxi.org/blog/2017/07/31/lms_el.html
;;
;; Quick instructions: customize some basic parameters `lms-url'
;; and run it with `lms' or `lms-ui'.
;; Then, you could read complete documentation after pressing 'h' key.
;; You can also run 'emacsclient -e "(lms-float)"' to display an independent
;; small frame.

;;; Major updates:

;; 2017/07/29 Initial version.
;; 2018/12/09 Added library browsing features from current track.
;; 2018/12/10 Added library browsing features.
;; 2018/12/16 Colorize lists, prev/next in TrackInfo, clean code, bugs fixed.
;; 2020/06/14 Complete rewrite to use HTTP requests to LMS instead of telnet.

;;; TODO:
;; . search
;; . random mix by (song, album, artist, year, genre)
;; . virtual library: library_id


;;; Code:
(require 'json)
(require 'org)
(require 'url)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Customization
;;;;; Main variables
(defgroup lms nil
  "Logitech Media Server Controller for emacs."
  :group 'multimedia)

(defcustom lms-url "http://lms_server:9000"
  "Logitech Media Server hostname or ip and port."
  :type 'string
  :group 'lms)

(defcustom lms-default-player nil
  "Name of default player.  F.e. Squeezebox."
  :type 'string
  :group 'lms)

(defcustom lms-ui-cover-width 500
  "Cover image width."
  :type 'integer
  :group 'lms)

(defcustom lms-ui-update-interval 1
  "Time in seconds between UI updates.  Default 1.  Set to nil to disable.
Note that small values could freeze your Emacs use while refreshing window."
  :type 'integer
  :group 'lms)

(defcustom lms-number-recent-albums 25
  "Number of recent albums to show."
  :type 'integer
  :group 'lms)

(defcustom lms-number-random-albums 25
  "Number of random albums to show."
  :type 'integer
  :group 'lms)

(defcustom lms-number-random-songs 50
  "Number of random songs to show."
  :type 'integer
  :group 'lms)

(defcustom lms-set-rating-function 'lms--set-rating-with-trackstat
  "Function to use to set rating."
  :type '(choice (const :tag "Use TrackStat plugin" lms--set-rating-with-trackstat)
                 (const :tag "use RatingsLight plugin" lms--set-rating-with-ratingslight))
  :group 'lms)


;;;;; Faces
(defface lms-playing-face
  '((t (:weight bold :foreground "DarkTurquoise")))
  "Face used for the playing symbol."
  :group 'lms-faces)

(defface lms-title-face
  '((t (:slant italic :foreground "SlateGray")))
  "Face used for the song title."
  :group 'lms-faces)

(defface lms-artist-face
  '((t (:weight bold :foreground "RosyBrown")))
  "Face used for the artist."
  :group 'lms-faces)

(defface lms-year-face
  '((t (:foreground "SteelBlue")))
  "Face used for the year of song."
  :group 'lms-faces)

(defface lms-album-face
  '((t (:foreground "CadetBlue")))
  "Face used for the album."
  :group 'lms-faces)

(defface lms-tracknum-face
  '((t (:foreground "gray40")))
  "Face used for song track number."
  :group 'lms-faces)

(defface lms-duration-face
  '((t (:foreground "gray60")))
  "Face used for the duration of the song."
  :group 'lms-faces)

(defface lms-players-selected-face
  '((t (:foreground "SteelBlue")))
  "Face used for selected icon in players list."
  :group 'lms-faces)

(defface lms-players-isplaying-face
  '((t (:foreground "RosyBrown")))
  "Face used for isplaying in players list."
  :group 'lms-faces)

(defface lms-players-name-face
  '((t (:foreground "CadetBlue")))
  "Face used for player name in players list."
  :group 'lms-faces)

(defface lms-players-model-face
  '((t (:foreground "SlateGray")))
  "Face used for player model in players list."
  :group 'lms-faces)

(defface lms-players-playerid-face
  '((t (:foreground "gray60")))
  "Face used for player id in players list."
  :group 'lms-faces)

(defface lms-players-ip-face
  '((t (:foreground "gray40")))
  "Face used for player ip in players list."
  :group 'lms-faces)

(defface lms-players-power-face
  '((t (:foreground "Maroon")))
  "Face used for ispower in players list."
  :group 'lms-faces)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; Module internal variables
;;;;; Documentation
(defvar lms-ui-docs "#+TITLE: lms.el Documentation
#+AUTHOR: Iñigo Serna
#+DATE: 2020/06/14

* Introduction
This is an *emacs* frontend to interact with Squeezebox Server / Logitech Media Server.
Released under GPL version 3 license or later.

It requires emacs version 25 or higher.

More information on what a *squeezebox controller* is at https://inigo.katxi.org/blog/2017/07/31/lms_el.html.

Quick instructions: customize some basic parameters such as 'lms-url' and run it with *lms* or *lms-ui*.
From there, you could read complete documentation after pressing *h* key.
You can also run 'emacsclient -e \"(lms-float)\"' to display an independent small frame.

Package should appear in [[https://melpa.org][MELPA repository]], and the code is in [[https://hg.serna.eu/emacs/lms][the code repository]] as well.

* Features
This is Squeezebox controller, i.e. a program which can handle your local music library.

Some of the features:
- Display song: title, artist, album, year, cover…
- Play, pause, stop, select next / previous song
- Control players: select player, power on/off, volume, repeat and shuffle modes
- Playlist control: list, select song, delete track, clear
- Show track information and change rating

It is not aimed to be a complete controller, as it can't - and won't - manage external sources such us BBC, Deezer, Pandora, Spotify, or TuneIn Radio.

* Configuration
There are some parameters you could customize:
|--------------------------+-----------------------------------------------+------------------------------------|
| Parameter                | Description                                   | Default                            |
|--------------------------+-----------------------------------------------+------------------------------------|
| lms-url                  | Logitech Media Server hostname or ip and port | http://lms_server:9000             |
| lms-default-player       | Name of default player                        | nil  (1)                           |
| lms-ui-cover-width       | Cover image width                             | 500  (2)                           |
| lms-ui-update-interval   | Time in seconds between UI updates            | 1    (3)                           |
| lms-number-recent-albums | Number of recent albums to show               | 25                                 |
| lms-number-random-albums | Number of random albums to show               | 25                                 |
| lms-number-random-songs  | Number of random songs to show                | 50                                 |
| lms-set-rating-function  | Function to use to set song rating            | lms--set-rating-with-trackstat (4) |
|--------------------------+-----------------------------------------------+------------------------------------|
Notes:
(1) If *lms-default-player* is not defined or a player with that name does not exist, it will ask for one at start.
(2) It's recomendable not to change *lms-ui-cover-width*.
(3) Note that small values in *lms-ui-update-interval* could freeze your Emacs use while refreshing window.
(4) LMS does not have any means to set the rating of a song by itself, so it depends on an external plugin.
    TrackStat (function *lms--set-rating-with-trackstat*) is a popular one, and RatingsLight (function *lms--set-rating-with-ratingslight*) is another option.
** Faces
The colors and font attributes of text can be customized in some views:
|----------------------------+-------------------------------+---------------------|
| Face name                  | Description                   | Default             |
|----------------------------+-------------------------------+---------------------|
| lms-playing-face           | Playing symbol                | DarkTurquoise, bold |
| lms-title-face             | Song title                    | SlateGray, italic   |
| lms-artist-face            | Artist                        | RosyBrown, bold     |
| lms-year-face              | Song year                     | SteelBlue           |
| lms-album-face             | Album                         | CadetBlue           |
| lms-tracknum-face          | Track number                  | gray40              |
| lms-duration-face          | Song duration                 | gray60              |
| lms-players-selected-face  | Selected icon in players list | SteelBlue           |
| lms-players-isplaying-face | Isplaying in players list     | RosyBrown           |
| lms-players-name-face      | Player name in players list   | CadetBlue           |
| lms-players-model-face     | Player model in players list  | SlateGray           |
| lms-players-playerid-face  | Player id in players list     | gray60              |
| lms-players-ip-face        | Player IP in players list     | gray40              |
| lms-players-power-face     | Ispower in players list       | Maroon              |
|----------------------------+-------------------------------+---------------------|

* Playing now
Main window showing information about current track and player status.
The actions triggered by pressing keys refer to the current track.
** Key bindings
|------------+--------------------------------|
| Ctrl-p     | select player                  |
| Ctrl-w     | change player power state      |
| Ctrl-r     | change track rating            |
| Ctrl-v     | set volume                     |
| <space>    | toggle play/pause              |
| P          | play                           |
| S          | stop playing                   |
| p, <left>  | play previous song in playlist |
| n, <right> | play next song in playlist     |
| m          | toggle mute volume             |
| +, =       | volume up +5                   |
| -          | volume down -5                 |
| r          | cycle repeat mode              |
| s          | cycle shuffle mode             |
| g          | update window contents         |
| i          | display track information      |
| l          | display playlist               |
| A          | show all albums by artist      |
| L          | show all tracks of album       |
| Y          | show all albums of this year   |
| M          | browse music libray            |
| h, ?       | show this documentation        |
| q          | quit LMS                       |
|------------+--------------------------------|

* Track information
Display track information.
Previous/next track only works when *Track information* window was called from a list, but not from *Playing now*.
** Key bindings
|------------+-------------------------|
| C-r        | change track rating     |
| p, <left>  | show previous track     |
| n, <right> | show next track         |
| h, ?       | show this documentation |
| q          | close window            |
|------------+-------------------------|

* Players list
Players list.
** Key bindings
|--------------+------------------------------------|
| <up>, <down> | move cursor                        |
| <enter>      | select player and close window     |
| <space>      | toggle player play/pause           |
| Ctrl-w       | toggle player power state          |
| h, ?         | show this documentation            |
| q            | close window                       |
|--------------+------------------------------------|

* Playlist
Playlist view.
The actions triggered by pressing keys refer to the track under cursor.
** Key bindings
|--------------+------------------------------------|
| <up>, <down> | move cursor                        |
| <enter>      | play track                         |
| i            | show track information             |
| j            | jump to current track              |
| d, <delete>  | remove track from playlist         |
| c c          | clear playlist                     |
| c u          | remove tracks from start to cursor |
| c f          | remove tracks from cursor to end   |
| g            | update window contents             |
| A            | show all albums by artist          |
| L            | show all tracks of album           |
| Y            | show all albums of this year       |
| h, ?         | show this documentation            |
| q            | close window                       |
|--------------+------------------------------------|

* Year - Album - Artist list
View all albums of an artist, sorted by date/year.
The actions triggered by pressing keys refer to the album under cursor.
** Key bindings
|--------------+------------------------------|
| <up>, <down> | move cursor                  |
| <enter>, T   | show all tracks of album     |
| A            | show all albums by artist    |
| Y            | show all albums of this year |
| p            | add album to playlist        |
| h, ?         | show this documentation      |
| q            | close window                 |
|--------------+------------------------------|

* Tracks list
View list of tracks.
The actions triggered by pressing keys refer to the track under cursor.
** Key bindings
|--------------+------------------------------|
| <up>, <down> | move cursor                  |
| <enter>, i   | display track information    |
| A            | show all albums by artist    |
| Y            | show all albums of this year |
| p            | add song to playlist         |
| P            | add all songs to playlist    |
| h, ?         | show this documentation      |
| q            | close window                 |
|--------------+------------------------------|
"
  "LMS documentation.")


;;;;; Variables
(defvar lms--players nil
  "List of cached players.")

(defvar lms--default-playerid nil
  "Internal default player playerid.")

(defvar lms--ui-timer nil
  "LMS UI display refresh timer.")

(defvar lms--ui-current-trackid nil
  "LMS UI last track id shown in Playing Now.")

(defvar lms--ui-editing-p nil
  "A flag to indicate buffer is been edited right now.")

(defvar lms--ui-track-info-trackid nil
  "Temporal variable to save in 'track info' view.")

(defvar lms--ui-track-info-tracksids nil
  "Temporal variable to save tracks ids in 'track info' view.")

(defvar lms--ui-pl-tracks nil
  "Temporal tracks list variable in 'playlist' view.")

(defvar lms--ui-tracks-lst nil
  "Temporal list variable in 'tracks' view.")

(defvar lms--ui-yaal-lst nil
  "Temporal list variable in 'year-album-artist' view.")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; API
;;;;; Initialization
(defun lms--init ()
  "LMS initialization."
  (lms--get-players)
  (setq lms--default-playerid
        (lms--get-playerid-from-name
         (or lms-default-player (completing-read "Select player: " (lms--get-players-name)))))
  (unless lms--default-playerid
    (error "LMS: can't run without player")))

(defun lms-quit ()
  "Quit LMS connection and close buffer."
  (interactive)
  (when lms--ui-timer
    (cancel-timer lms--ui-timer))
  (setq lms-default-player (lms--get-playername-from-id lms--default-playerid)
        lms--default-playerid nil
        lms--players nil
        lms--ui-current-trackid nil
        lms--ui-timer nil))


;;;;; LMS server querying
(defun lms--split-string (txt)
  "Split string TXT respecting parts inside quotes."
  (let (lst acc in-substring)
    (dolist (c (string-to-list txt))
      (if in-substring
          (if (= c in-substring)
              (progn
                (setq in-substring nil)
                (push c acc))
            (push c acc))
        (if (or (= c ?') (= c ?\"))
            (progn
              (setq in-substring c)
              (push c acc))
          (if (= c 32)  ; space
              (progn
                (push (string-join (mapcar 'char-to-string (nreverse acc))) lst)
                (setq acc nil))
            (push c acc)))))
    (when acc
      (push (string-join (mapcar 'char-to-string (nreverse acc))) lst))
    (nreverse lst)))

(defun lms--cmd (query &optional playerid)
  "Sync HTTP request QUERY to LMS server.  PLAYERID is optional.
QUERY is a string."
  (setq playerid (or playerid lms--default-playerid ""))
  (let* ((json-array-type 'list)
         (url-request-method "POST")
         (url-request-extra-headers '(("Content-Type" . "application/json")))
         (url-request-data (encode-coding-string
                            (json-encode-alist `((method . "slim.request") (params . [,playerid ,(lms--split-string query)])))
                            'utf-8))
         (buf (url-retrieve-synchronously (concat lms-url "/jsonrpc.js") t t 10))
         (response (with-current-buffer buf
                     (goto-char (point-min))
                     (re-search-forward "^$")
                     (delete-region (point) (point-min))
                     (decode-coding-string (buffer-string) 'utf-8))))
    (kill-buffer buf)
    (unless (string= "" response)
      (alist-get 'result (json-read-from-string response)))))


;;;;; Players
(defun lms--get-players ()
  "Get players and store to a variable as cache."
  (setq lms--players (alist-get 'players_loop (lms--cmd "serverstatus -"))))

(defun lms--get-players-name ()
  "Get a list of players name."
  (unless lms--players
    (lms--get-players))
  (mapcar #'(lambda (p) (alist-get 'name p)) lms--players))

(defun lms--get-playerid-from-name (playername)
  "Get playerid from player PLAYERNAME."
  (unless lms--players
    (lms--get-players))
  (let (playerid)
    (dolist (p lms--players)
      (when (string= playername (alist-get 'name p))
        (setq playerid (alist-get 'playerid p))))
    playerid))

(defun lms--get-playername-from-id (playerid)
  "Get playername from player PLAYERID."
  (unless lms--players
    (lms--get-players))
  (let (playername)
    (dolist (p lms--players)
      (when (string= playerid (alist-get 'playerid p))
        (setq playername (alist-get 'name p))))
    playername))


;;;;; Playing control
(defun lms-playing-toggle-pause ()
  "Toggle play/pause."
  (interactive)
  (lms--cmd "pause"))

(defun lms-playing-play ()
  "Play player."
  (interactive)
  (lms--cmd "play"))

(defun lms-playing-pause ()
  "Pause player."
  (interactive)
  (lms--cmd "pause 1"))

(defun lms-playing-stop ()
  "Stop player."
  (interactive)
  (lms--cmd "stop"))


;;;;; Volume
(defun lms-player-toggle-mute ()
  "Toggle mute for player."
  (interactive)
  (lms--cmd "mixer muting toggle"))

(defun lms-player-get-volume ()
  "Get VOLUME as string (0..100) for player."
  (interactive)
  (string-to-number (alist-get '_volume (lms--cmd "mixer volume ?"))))

(defun lms-player-set-volume (volume)
  "Set VOLUME for player.
VOLUME is a string which can be a relative (ex +5 or -7) or absolute value."
  (interactive "sVolume: ")
  (lms--cmd (format "mixer volume %s" volume)))


;;;;; Power
(defun lms-player-toggle-power ()
  "Toggle power for player."
  (interactive)
  (lms--cmd "power"))

(defun lms-player-power-on ()
  "Power on player."
  (interactive)
  (lms--cmd "power 1"))

(defun lms-player-power-off ()
  "Power off player."
  (interactive)
  (lms--cmd "power 0"))


;;;;; PlayList
(defun lms-playlist-play-track (index)
  "Play track INDEX from playlist.
Must be a string.  Can be a relative number such as \"-1\"."
  (interactive "sTrack index: ")
  (lms--cmd (format "playlist index %s" index)))

(defun lms-playlist-delete-track (index)
  "Remove track INDEX from playlist."
  (interactive)
  (lms--cmd (format "playlist delete %s" index)))

(defun lms-playlist-clear ()
  "Clear playlist."
  (interactive)
  (lms--cmd "playlist clear"))

(defun lms-playlist-get-repeat ()
  "Get playlist repeat mode of player.  Return a string."
  (alist-get '_repeat (lms--cmd "playlist repeat ?")))

(defun lms-playlist-set-repeat (repeat)
  "Set playlist REPEAT mode (as int) of player."
  (lms--cmd (format "playlist repeat %d" repeat)))

(defun lms-playlist-get-shuffle ()
  "Get playlist shuffle mode of player.  Return a string."
  (alist-get '_shuffle (lms--cmd "playlist shuffle ?")))

(defun lms-playlist-set-shuffle (shuffle)
  "Set playlist SHUFFLE mode (as int) of player."
  (lms--cmd (format "playlist shuffle %d" shuffle)))

(defun lms-playlistcontrol-action (object &optional question)
  "Ask QUESTION about how to add/insert/replace OBJECT tracks to playlist."
  (let ((act (car (read-multiple-choice (or question "Add to playlist?")
                                        '((?a "add to end")
                                          (?p "play next")
                                          (?r "replace")))))
        action)
    (pcase act
      (?a (setq action "add"))
      (?p (setq action "insert"))
      (?r (setq action "load")))
    (lms--cmd (format "playlistcontrol cmd:%s %s" action object))))


;;;;; Library
;;;;;; Tracks
(defun lms--set-rating-with-trackstat (trackid rating)
  "Set RATING (percent) to TRACKID using TrackStat plugin."
  (lms--cmd (format "trackstat setratingpercent %d %s" trackid rating)))

(defun lms--set-rating-with-ratingslight (trackid rating)
  "Set RATING (percent) to TRACKID using RatingsLight plugin."
  (let ((rating_as5 (/ (string-to-number rating) 20.0)))
    (lms--cmd (format "ratingslight setrating track_id:%d rating:%1.1f" trackid rating_as5))))

(defun lms-track-set-rating (trackid rating)
  "Set RATING (percent) to TRACKID using plugin defined in settings."
  (funcall lms-set-rating-function trackid rating))

(defun lms-get-current-track-albumid ()
  "Get current track albumid."
  (lms--ensure-number (alist-get 'album_id (cadr (assq 'playlist_loop (lms--cmd "status - 1 tags:e"))))))

(defun lms-get-current-track-artistid ()
  "Get current track artistid."
  (lms--ensure-number (alist-get 'artist_id (cadr (assq 'playlist_loop (lms--cmd "status - 1 tags:s"))))))

(defun lms-get-current-track-year ()
  "Get current track year."
  (alist-get 'year (cadr (assq 'playlist_loop (lms--cmd "status - 1 tags:y")))))

(defun lms-get-tracks-from-albumid (albumid)
  "Get a list of tracks from ALBUMID.  Sorted by discnum, then by tracknum."
  (seq-sort #'(lambda (x y) (let ((xdn (lms--ensure-number (alist-get 'disc x)))
                                  (xtn (lms--ensure-number (alist-get 'tracknum x)))
                                  (ydn (lms--ensure-number (alist-get 'disc y)))
                                  (ytn (lms--ensure-number (alist-get 'tracknum y))))
                              (if (= xdn ydn)
                                  (< xtn ytn)
                                (< xdn ydn))))
            (alist-get 'titles_loop (lms--cmd (format "tracks 0 1000 album_id:%d tags:altydi" albumid)))))

;;;;;; Artists
(defun lms-get-artist-name-from-id (artistid)
  "Get album name from ARTISTID."
  (alist-get 'artist (cadr (assq 'artists_loop (lms--cmd (format "artists 0 1 artist_id:%d" artistid))))))

(defun lms-get-artist-id-from-name (artistname)
  "Get artist id from ARTISTNAME."
  (lms--ensure-number (alist-get 'id (cadr (assq 'artists_loop (lms--cmd (format "artists 0 100 search:'%s'" artistname)))))))

(defun lms-get-artists (&optional max vlibid)
  "Get a list of 5000 or MAX artists.
If VLIBID is specified use only that virtual library."
  (setq max (or max 5000))
  (let ((vlib (if vlibid (format " library_id:%s" vlibid) "")))
    (mapcar #'(lambda (a) (alist-get 'artist a))
            (alist-get 'artists_loop (lms--cmd (format "artists 0 %d%s" max vlib))))))

;;;;;; Albums
(defun lms-get-album-name-from-id (albumid)
  "Get album name from ALBUMID."
  (alist-get 'album (cadr (assq 'albums_loop (lms--cmd (format "albums 0 1 album_id:%d" albumid))))))

(defun lms-get-album-id-from-name (albumname &optional artistname)
  "Get albumid name from ALBUMNAME and optional ARTISTNAME."
  (let ((lst (alist-get 'albums_loop (lms--cmd (format "albums 0 100 search:'%s' tags:al" albumname)))))
    (alist-get 'id (if artistname
                       (seq-find #'(lambda (x) (string= (alist-get 'artist x) artistname)) lst)
                     (car lst)))))

(defun lms-get-albums-from-artistid (artistid)
  "Get a list with albums from ARTISTID."
  (alist-get 'albums_loop (lms--cmd (format "albums 0 1000 artist_id:%d sort:yearartistalbum tags:aly" artistid))))

(defun lms-get-albums-from-year (year)
  "Get a list with albums from YEAR."
  (alist-get 'albums_loop (lms--cmd (format "albums 0 1000 year:%d sort:yearartistalbum tags:aly" year))))

(defun lms-get-albums-from-genreid (genreid)
  "Get a list with albums from GENREID."
  (alist-get 'albums_loop (lms--cmd (format "albums 0 10000 genre_id:%s sort:yearartistalbum tags:aly" genreid))))

(defun lms-get-albums (&optional max vlibid)
  "Get a list of 5000 or MAX albums.
If VLIBID is specified use only that virtual library."
  (setq max (or max 5000))
  (let ((vlib (if vlibid (format " library_id:%s" vlibid) "")))
    (mapcar #'(lambda (l) (alist-get 'album l))
            (alist-get 'albums_loop (lms--cmd (format "albums 0 %d tags:lay sort:yearartistalbum%s" max vlib))))))

(defun lms-get-recent-albums (n)
  "Get most recent N albums."
  (alist-get 'albums_loop  (lms--cmd (format "albums 0 %d sort:new tags:aly" n))))

;;;;;; Years
(defun lms-get-years (&optional max vlibid)
  "Get a list of 1000 or MAX years.
If VLIBID is specified use only that virtual library."
  (setq max (or max 1000))
  (let ((vlib (if vlibid (format " library_id:%s" vlibid) "")))
    (seq-sort #'<
              (mapcar #'(lambda (y) (cdar y))
                      (alist-get 'years_loop (lms--cmd (format "years 0 %d hasAlbums:1%s" max vlib)))))))

;;;;;; Genres
(defun lms-get-genres (&optional max vlibid)
  "Get a list of 1000 or MAX genres.
If VLIBID is specified use only that virtual library."
  (setq max (or max 1000))
  (let ((vlib (if vlibid (format " library_id:%s" vlibid) "")))
    (seq-sort #'string< (mapcar #'(lambda (g) (alist-get 'genre g))
                                (alist-get 'genres_loop (lms--cmd (format "genres 0 %d%s" max vlib)))))))

(defun lms-get-genreid-from-name (genre)
  "Get genreid from GENRE name."
  (alist-get 'id (seq-find #'(lambda (g) (when (string= genre (alist-get 'genre g)) (alist-get 'id g)))
                           (alist-get 'genres_loop (lms--cmd "genres 0 1000")))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; UI helpers
(defun lms--retrieve-url (url)
  "Retrieve data file from URL."
  (with-current-buffer (url-retrieve-synchronously url)
    (prog1
        (progn
          (goto-char (point-min))
          (re-search-forward "^$")
          (forward-char)
          (delete-region (point) (point-min))
          (buffer-string))
      (kill-buffer))))

(defun lms--format-time (secs)
  "Format SECS to human readable form."
  (if (>= secs 86400)
      (format-seconds "%d days %hh %mm %ss" secs)
    (format-seconds (if (> secs 3599 ) "%h:%.2m:%.2s" "%m:%.2s") secs)))

(defun lms--format-rating (rating)
  "Format RATING to human readable form."
  (let ((r (/ rating 10)))
    (concat (string-join (make-vector r "★")) (string-join (make-vector (- 10 r) "☆")))))

(defun lms--format-volume (volume)
  "Format VOLUME to human readable form."
  (if (> volume 0) (format " 🔈 %s " volume) " 🔇 00 "))

(defun lms--format-filesize (filesize)
  "Format FILESIZE to human readable form."
  (if (> filesize 1048576)
      (format "%.2f MB" (/ filesize 1048576.0))
    (if (> filesize 1024)
        (format "%.2f KB" (/ filesize 1024.0))
      (format "%d Bytes" filesize))))

(defun lms--format-mode (powerp mode)
  "Format POWERP & MODE to human readable form."
  (if powerp
      (pcase mode
        ("stop" "■")
        ("play" "▶")
        ("pause" "‖"))  ; "▍▍ ‖ ❘❘ "
    "off"))

(defun lms--format-repeat-mode (repeat)
  "Format REPEAT mode to human readable form."
  (pcase repeat
    (0 "No repeat")
    (1 "Repeat song")
    (2 "Repeat playlist")))

(defun lms--format-shuffle-mode (shuffle)
  "Format SHUFFLE mode to human readable form."
  (pcase shuffle
    (0 "No shuffle")
    (1 "Shuffle by song")
    (2 "Shuffle by album")))

(defun lms--ensure-string (anumber)
  "Return a string from ANUMBER."
  (if (stringp anumber)
      anumber
    (number-to-string (or anumber 0))))

(defun lms--ensure-number (anumber)
  "Return ANUMBER."
  (if (numberp anumber)
      anumber
    (string-to-number (or anumber "0"))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;; UI
;;;###autoload
(defun lms-ui ()
  "LMS UI entry point."
  (interactive)
  (if (get-buffer "*LMS: Playing Now*")
      (switch-to-buffer "*LMS: Playing Now*")
    (lms--init)
    (lms-ui-playing-now)
    (switch-to-buffer "*LMS: Playing Now*")
    (when (and lms-ui-update-interval (not (timerp lms--ui-timer)))
      (setq lms--ui-timer (run-at-time nil lms-ui-update-interval 'lms--ui-playing-now-update)))))

;;;###autoload
(defalias 'lms 'lms-ui)

;;;###autoload
(defun lms-float ()
  "Show a frame with Playing Now."
  (interactive)
  (make-frame '((title . "LMS")
                ;; (undecorated . t)
                (menu-bar-lines . 0)
                (tool-bar-lines . 0)
                (minibuffer . nil)
                (unsplittable . t)
                (left-fringe . 5)
                (right-fringe . 0)
                (height .  (text-pixels . 725))
                (width .  (text-pixels . 540))
                (background-color . "#242430")))
  (lms)
  (setq mode-line-format nil)
  (local-set-key "q" #'(lambda() (interactive)
                         (local-set-key "q" #'lms-ui-playing-now-quit)
                         (lms-ui-playing-now-quit)
                         (delete-frame))))


;;;;; Playing now
(defvar lms-ui-playing-now-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map nil)
    (define-key map (kbd "C-w")       'lms-ui-playing-now-change-player-power-state)
    (define-key map (kbd "C-p")       'lms-ui-playing-now-players-list)
    (define-key map (kbd "C-r")       'lms-ui-playing-now-change-rating)
    (define-key map (kbd "C-v")       'lms-ui-playing-now-set-volume)
    (define-key map (kbd "<SPC>")     'lms-ui-playing-now-play-pause)
    (define-key map (kbd "RET")       'lms-ui-playing-now-play-pause)
    (define-key map (kbd "P")         'lms-ui-playing-now-play)
    (define-key map (kbd "S")         'lms-ui-playing-now-stop)
    (define-key map (kbd "n")         'lms-ui-playing-now-next)
    (define-key map (kbd "<right>")   'lms-ui-playing-now-next)
    (define-key map (kbd "p")         'lms-ui-playing-now-prev)
    (define-key map (kbd "<left>")    'lms-ui-playing-now-prev)
    (define-key map (kbd "+")         'lms-ui-playing-now-volume-up)
    (define-key map (kbd "=")         'lms-ui-playing-now-volume-up)
    (define-key map (kbd "-")         'lms-ui-playing-now-volume-down)
    (define-key map (kbd "m")         'lms-ui-playing-now-volume-mute)
    (define-key map (kbd "r")         'lms-ui-playing-now-cycle-repeat)
    (define-key map (kbd "s")         'lms-ui-playing-now-cycle-shuffle)
    (define-key map (kbd "g")         'lms-ui-playing-now-refresh)
    (define-key map (kbd "i")         'lms-ui-playing-now-show-track-info)
    (define-key map (kbd "l")         'lms-ui-playing-now-show-playlist)
    (define-key map (kbd "L")         'lms-ui-playing-now-album-tracks-list)
    (define-key map (kbd "A")         'lms-ui-playing-now-artist-albums-list)
    (define-key map (kbd "Y")         'lms-ui-playing-now-year-albums-list)
    (define-key map (kbd "M")         'lms-ui-playing-now-browse-music-library)
    (define-key map (kbd "h")         'lms-ui-playing-now-help)
    (define-key map (kbd "?")         'lms-ui-playing-now-help)
    (define-key map (kbd "q")         'lms-ui-playing-now-quit)
    map)
  "Local keymap for `lms-ui-playing-now-mode' buffers.")

(define-derived-mode lms-ui-playing-now-mode fundamental-mode "LMS Playing Now"
  "Major mode for LMS Playing now buffer.
Press 'h' or '?' keys for complete documentation")


(defun lms--ui-playing-now-update ()
  "Update Playing Now screen, only when buffer is visible."
  (when (and (get-buffer-window "*LMS: Playing Now*") (not lms--ui-editing-p))
    (let* ((res (lms--cmd "status - 1"))
           (mode (alist-get 'mode res))
           (id (alist-get 'id (cadr (assq 'playlist_loop res))))
           (time (alist-get 'time res)))
      (when (string= mode "play")
        (set-buffer (get-buffer-create "*LMS: Playing Now*"))  ; we need to change buffer here to reach local vars
        (if (and lms--ui-current-trackid (= id lms--ui-current-trackid))
            (progn
              (goto-char (point-min))
              (forward-line 6)
              (let ((inhibit-read-only t))
                (while (not (looking-at-p "/"))
                  (delete-char 1))
                (insert (propertize (lms--format-time time) 'face '(:foreground "Maroon")))))
          (lms-ui-playing-now))))))


(defun lms-ui-playing-now ()
  "Playing now."
  (interactive)
  (setq lms--ui-editing-p t)
  ; check for player
  (unless lms--default-playerid
    (error "LMS: can't run without player"))
  ; fetch information
  (let* ((res (lms--cmd "status - 1 tags:adlRytK" lms--default-playerid))
         (playername (alist-get 'player_name res))
         (powerp (alist-get 'power res))
         (mode (alist-get 'mode res))
         (volume (alist-get (intern "mixer volume") res))
         (repeat (alist-get (intern "playlist repeat") res))
         (shuffle (alist-get (intern "playlist shuffle") res))
         (time (let ((ti (alist-get 'time res)))
                 (if (stringp ti) (string-to-number ti) ti)))
         (pl_cur_index (1+ (let ((idx (or (alist-get 'playlist_cur_index res) 0)))
                             (if (stringp idx)  ; bug in lms?
                                 (string-to-number idx)
                               idx))))
         (pl_total (alist-get 'playlist_tracks res))
         (pl (alist-get 'playlist_loop res))
         id)
    (set-buffer (get-buffer-create "*LMS: Playing Now*"))
    (lms-ui-playing-now-mode)
    (setq-local buffer-read-only nil)
    (erase-buffer)
    (let-alist (car pl)
      (setq id .id)
      (unless pl
        (setq .title "No title"
              .artist "No artist"
              .album "No album"
              .year "0000"
              .tracknum "0"
              .duration 0
              .rating 0))
      ; track info
      (insert (propertize (or .title "No title") 'face '(variable-pitch (:height 1.5 :weight bold :slant italic :foreground "SlateGray")))
              (propertize "\n\n" 'face '(:height 0.1))
              (propertize (or .artist "No artist") 'face '(variable-pitch (:height 1.2 :weight bold :foreground "RosyBrown")))
              (propertize "\n\n" 'face '(:height 0.1))
              (propertize (or .album "No album") 'face '(variable-pitch  (:height 1.2 :foreground "CadetBlue")))
              (propertize (when .year (format "  [%s]" .year)) 'face '(variable-pitch (:height 1.2 :foreground "SteelBlue")))
              (propertize (when .tracknum (format "  (%s)" .tracknum)) 'face '(variable-pitch (:height 1.2 :foreground "gray40")))
              (propertize "\n\n" 'face '(:height 0.1))
              (format "%s  -  %s  -  %s"
                      (propertize (format "%s/%s" (lms--format-time (or time 0)) (lms--format-time (or .duration 0))) 'face '(:foreground "Maroon"))
                      (propertize (format "%d/%d" (or pl_cur_index 0) (or pl_total 0)) 'face '(:foreground "Gray40"))
                      (propertize (lms--format-rating (lms--ensure-number .rating)) 'face '(:foreground "Orange")))
              (propertize "\n\n" 'face '(:height 0.5))))
    ; cover image
    (when window-system
      (let* ((imgdata (string-as-unibyte (lms--retrieve-url (format "%s/music/%s/cover.jpg" lms-url id))))
             (img (create-image imgdata (if id 'jpeg 'png) t :width lms-ui-cover-width))
	         (image-width (and img (car (image-size img))))
	         (window-width (window-width)))
        (when img
          (when (> window-width image-width)
	        ;; Center the image in the window.
	        ;; (insert (propertize " " 'display
		    ;;                     `(space :align-to (+ center (-0.5 . ,img)))))
	   	    (insert-image img)
            (insert (propertize "\n\n" 'face '(:height 0.5)))))))
    ; player
    (insert (propertize (format " %s " playername)
                        'face '(:box '(:style pressed-button) :foreground "RosyBrown4"))
            "  "
            (propertize (format " %s " (lms--format-mode powerp mode))
                        'face '(:box '(:style pressed-button) :foreground "RosyBrown4"))
            "  "
            (propertize (lms--format-volume volume)
                        'face '(:box '(:style released-button) :foreground "RosyBrown4"))
            "  "
            (propertize (format " %s " (lms--format-repeat-mode repeat))
                        'face '(:height 0.8 :box '(:style released-button) :foreground "RosyBrown4"))
            "  "
            (propertize (format " %s " (lms--format-shuffle-mode shuffle))
                        'face '(:height 0.8 :box '(:style released-button) :foreground "RosyBrown4"))
            (propertize "\n\n" 'face '(:height 0.5)))
    ; library numbers and help
    (let* ((res2 (lms--cmd "serverstatus"))
           (lastscan (string-to-number (alist-get 'lastscan res2)))
           (version (alist-get 'version res2))
           (numplayers (alist-get (intern "player count") res2))
           (totalsongs (alist-get (intern "info total songs") res2))
           (totalartists (alist-get (intern "info total artists") res2))
           (totalalbums (alist-get (intern "info total albums") res2))
           (totalgenres (alist-get (intern "info total genres") res2))
           (totalduration (alist-get (intern "info total duration") res2)))
      (insert (propertize (format "%d songs  %d artists  %d albums  %d genres  -  %s\n" totalsongs totalartists totalalbums totalgenres (lms--format-time totalduration))
                          'face '(variable-pitch (:height 0.85 :slant italic :foreground "gray40"))))
      (insert (propertize (format "Version: %s  -  %d players  -  Last scan: %s\n" version numplayers  (format-time-string "%c" lastscan))
                          'face '(variable-pitch (:height 0.85 :slant italic :foreground "gray40"))))
      (insert (propertize "Press 'h' for help, 'q' to close." 'face '(variable-pitch (:height 0.85 :slant italic :foreground "gray40")))))
    ; end
    (hl-line-mode -1)
    (setq-local cursor-type nil)
    (setq-local buffer-read-only t)
    (setq-local lms--ui-current-trackid id)
    (goto-char (point-min)))
  (setq lms--ui-editing-p nil))


(defun lms-ui-playing-now-quit ()
  "Quit LMS interface ans close connection."
  (interactive)
  (kill-buffer "*LMS: Playing Now*")
  (lms-quit))

(defun lms-ui-playing-now-help ()
  "Show LMS help."
  (interactive)
  (switch-to-buffer "*LMS: Help*")
  (erase-buffer)
  (insert lms-ui-docs)
  (goto-char (point-min))
  (org-mode)
  (org-content 3)
  (search-forward "* Introduction")
  (beginning-of-line)
  (org-show-entry)
  (view-mode 1))

(defun lms-ui-playing-now-refresh ()
  "Reload LMS interface."
  (interactive)
  (lms-ui-playing-now))


(defun lms-ui-playing-now-play-pause ()
  "Toggle play/pause."
  (interactive)
  (when lms--ui-current-trackid
    (lms-playing-toggle-pause)
    (sleep-for .2)
    (lms-ui-playing-now-refresh)))

(defun lms-ui-playing-now-play ()
  "Play."
  (interactive)
  (when lms--ui-current-trackid
    (lms-playing-play)
    (sleep-for .2)
    (lms-ui-playing-now-refresh)))

(defun lms-ui-playing-now-stop ()
  "Stop."
  (interactive)
  (when lms--ui-current-trackid
    (lms-playing-stop)
    (sleep-for .2)
    (lms-ui-playing-now-refresh)))


(defun lms-ui-playing-now-prev ()
  "Jump to previous song."
  (interactive)
  (when lms--ui-current-trackid
    (lms-playlist-play-track "-1")
    (sleep-for .2)
    (lms-ui-playing-now-refresh)))

(defun lms-ui-playing-now-next ()
  "Jump to next song."
  (interactive)
  (when lms--ui-current-trackid
    (lms-playlist-play-track "+1")
    (sleep-for .2)
    (lms-ui-playing-now-refresh)))


(defun lms-ui-playing-now-volume-mute ()
  "Toggle volume un/mute."
  (interactive)
  (lms-player-toggle-mute)
  (sleep-for .5)
  (lms-ui-playing-now-refresh))

(defun lms-ui-playing-now-set-volume ()
  "Set volume."
  (interactive)
  (call-interactively 'lms-player-set-volume)
  (sleep-for .5)
  (lms-ui-playing-now-refresh))

(defun lms-ui-playing-now-volume-up ()
  "Volume up."
  (interactive)
  (lms-player-set-volume "+5")
  (sleep-for .5)
  (lms-ui-playing-now-refresh))

(defun lms-ui-playing-now-volume-down ()
  "Volume down."
  (interactive)
  (lms-player-set-volume "-5")
  (sleep-for .5)
  (lms-ui-playing-now-refresh))


(defun lms-ui-playing-now-change-player-power-state ()
  "Change power state of player."
  (interactive)
  (let ((state (car (read-multiple-choice "Change player power state"
                                          '((?t "toggle")
                                            (?o "on")
                                            (?f "off"))))))
    (pcase state
      (?t (lms-player-toggle-power))
      (?o (lms-player-power-on))
      (?f (lms-player-power-off)))
    (sleep-for .2)
    (lms-ui-playing-now-refresh)))

(defun lms-ui-playing-now-change-rating ()
  "Change rating of current track."
  (interactive)
  (when lms--ui-current-trackid
    (let ((rating (cadr (read-multiple-choice "Rating"
                                              '((?z "0") (?1 "10") (?2 "20") (?3 "30") (?4 "40") (?5 "50") (?6 "60") (?7 "70") (?8 "80") (?9 "90") (?0 "100"))))))
      (when rating
        (lms-track-set-rating lms--ui-current-trackid rating)
        (sleep-for .2)
        (lms-ui-playing-now-refresh)))))


(defun lms-ui-playing-now-cycle-repeat ()
  "Cycle repeat modes."
  (interactive)
  (let ((repeat (string-to-number (lms-playlist-get-repeat))))
    (setq repeat (if (= repeat 2) 0 (1+ repeat)))
    (lms-playlist-set-repeat repeat))
  (sleep-for .2)
  (lms-ui-playing-now-refresh))

(defun lms-ui-playing-now-cycle-shuffle ()
  "Cycle shuffle modes."
  (interactive)
  (let ((shuffle (string-to-number (lms-playlist-get-shuffle))))
    (setq shuffle (if (= shuffle 2) 0 (1+ shuffle)))
    (lms-playlist-set-shuffle shuffle))
  (sleep-for .2)
  (lms-ui-playing-now-refresh))


(defun lms-ui-playing-now-players-list ()
  "Open players list."
  (interactive)
  (lms-ui-players))

(defun lms-ui-playing-now-show-track-info ()
  "Open track information buffer."
  (interactive)
  (when lms--ui-current-trackid
    (lms-ui-track-info lms--ui-current-trackid)))

(defun lms-ui-playing-now-show-playlist ()
  "Open playlits buffer."
  (interactive)
  (lms-ui-playlist))

(defun lms-ui-playing-now-album-tracks-list ()
  "Show list of tracks in album of current track."
  (interactive)
  (let* ((albumid (lms-get-current-track-albumid))
         (buftitle (format "*LMS: Tracks in album '%s'*" (lms-get-album-name-from-id albumid)))
         (lst (lms-get-tracks-from-albumid albumid)))
    (lms-ui-tracks-list buftitle lst)))

(defun lms-ui-playing-now-artist-albums-list ()
  "Show list of albums by the artist of current track."
  (interactive)
  (let* ((artistid (lms-get-current-track-artistid))
         (buftitle (format "*LMS: Albums by %s*" (lms-get-artist-name-from-id artistid)))
         (lst (lms-get-albums-from-artistid artistid)))
    (lms-ui-year-album-artist-list buftitle lst)))

(defun lms-ui-playing-now-year-albums-list ()
  "Show list of albums by year of current track."
  (interactive)
  (let* ((year (lms-get-current-track-year))
         (buftitle (format "*LMS: Albums in year %d*" year))
         (lst (lms-get-albums-from-year year)))
    (lms-ui-year-album-artist-list buftitle lst)))

(defun lms-ui-playing-now-browse-music-library ()
  "Browse music library."
  (interactive)
  (let ((action (car (read-multiple-choice "Browse music library by"
                                           '((?a "artist")
                                             (?l "album")
                                             (?g "genre")
                                             (?y "year")
                                             (?r "recent albums"))))))
    (pcase action
      (?a
       (let ((artist (completing-read "Artist? " (lms-get-artists))))
         (lms-ui-year-album-artist-list (format "*LMS: Albums by %s*" artist)
                                         (lms-get-albums-from-artistid (lms-get-artist-id-from-name artist)))))
      (?l
       (let ((album (completing-read "Album? " (lms-get-albums))))
         (lms-ui-tracks-list (format "*LMS: Album '%s'*" album)
                              (lms-get-tracks-from-albumid (lms-get-album-id-from-name album)))))
      (?g
       (let ((genre (completing-read "Genre? " (lms-get-genres))))
         (lms-ui-year-album-artist-list (format "*LMS: Albums in genre %s*" genre)
                                         (lms-get-albums-from-genreid (lms-get-genreid-from-name genre)))))
      (?y
       (let ((year (completing-read "Year? " (mapcar #'int-to-string (lms-get-years)))))
         (lms-ui-year-album-artist-list (format "*LMS: Albums in year %s*" year)
                                         (lms-get-albums-from-year (string-to-number year)))))
      (?r
       (lms-ui-year-album-artist-list "*LMS: recent albums*"
                                       (lms-get-recent-albums lms-number-recent-albums))))))


;;;;; Track info
(defvar lms-ui-track-info-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-r")     'lms-ui-track-info-change-rating)
    (define-key map (kbd "p")       'lms-ui-track-info-prev)
    (define-key map (kbd "<left>")  'lms-ui-track-info-prev)
    (define-key map (kbd "n")       'lms-ui-track-info-next)
    (define-key map (kbd "<right>") 'lms-ui-track-info-next)
    (define-key map (kbd "h")       'lms-ui-playing-now-help)
    (define-key map (kbd "?")       'lms-ui-playing-now-help)
    (define-key map (kbd "q")       '(lambda () (interactive)
                                       (kill-buffer "*LMS: Track Information*")
                                       (lms-ui-playing-now-refresh)))
    map)
  "Local keymap for `lms-ui-track-info-mode' buffers.")

(define-derived-mode lms-ui-track-info-mode fundamental-mode "LMS Track Information"
  "Major mode for LMS Track Information buffer.")

(defun lms-ui-track-info (trackid &optional tracks-ids)
  "Track information for TRACKID.
Optional TRACKS-IDS variable is used to identify prev/next song."
  (interactive)
  (let* ((trackinfo (alist-get 'songinfo_loop (lms--cmd (format "songinfo 0 100 track_id:%d tags:alytgiqdROfuovrTImnDU"  trackid))))
         id)
    (switch-to-buffer "*LMS: Track Information*")
    (lms-ui-track-info-mode)
    (setq-local buffer-read-only nil)
    (erase-buffer)
    (insert (propertize "Track information" 'face '(variable-pitch (:height 1.5 :weight bold :underline t :foreground "SlateGray"))))
    (insert "\n\n")
    (dolist (elm trackinfo)
      (let ((k (caar elm))
            (v (cdar elm)))
        (pcase k
          ('id (setq id v))
          ('duration (setq v (lms--format-time v)))
          ('rating (setq v (lms--format-rating (lms--ensure-number v))))
          ('filesize (setq v (lms--format-filesize (lms--ensure-number v))))
          ('url (setq v (url-unhex-string v))))
        (insert (propertize (format "%s: " (capitalize (symbol-name k))) 'face '(:weight bold)))
        (insert (format "%s\n" v))))
    (insert "\n")
    (insert (propertize "Press 'q' to close this window." 'face '(variable-pitch (:height 0.85 :slant italic :foreground "gray40"))))
    (hl-line-mode -1)
    (setq-local buffer-read-only t)
    (setq-local cursor-type nil)
    (setq-local lms--ui-track-info-trackid id)
    (setq-local lms--ui-track-info-tracksids tracks-ids)
    (goto-char (point-min))))

(defun lms-ui-track-info-change-rating ()
  "Change track rating."
  (interactive)
  (let ((rating (cadr (read-multiple-choice "Rating"
                                            '((?z "0") (?1 "10") (?2 "20") (?3 "30") (?4 "40") (?5 "50") (?6 "60") (?7 "70") (?8 "80") (?9 "90") (?0 "100"))))))
    (when rating
      (lms-track-set-rating lms--ui-track-info-trackid rating)
      (goto-char (point-min))
      (when (search-forward "Rating: " nil t)
        (let ((inhibit-read-only t))
          (kill-line)
          (insert (lms--format-rating (lms--ensure-number rating))))))))

(defun lms-ui-track-info-prev ()
  "Show previous track information."
  (interactive)
  (when lms--ui-track-info-tracksids
    (let ((idx (seq-position lms--ui-track-info-tracksids lms--ui-track-info-trackid)))
      (when (and idx (> idx 0))
        (lms-ui-track-info (nth (1- idx) lms--ui-track-info-tracksids) lms--ui-track-info-tracksids)))))

(defun lms-ui-track-info-next ()
  "Show next track information."
  (interactive)
  (when lms--ui-track-info-tracksids
    (let ((idx (seq-position lms--ui-track-info-tracksids lms--ui-track-info-trackid)))
      (when (and idx (< (1+ idx) (length lms--ui-track-info-tracksids)))
        (lms-ui-track-info (nth (1+ idx) lms--ui-track-info-tracksids) lms--ui-track-info-tracksids)))))


;;;;; Players list
(defvar lms-ui-players-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map [remap end-of-buffer]     '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap end-of-defun]      '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap forward-paragraph] '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap next-line]         '(lambda () (interactive) (forward-line 1) (when (eobp) (forward-line -1))))
    (define-key map (kbd "RET")               'lms-ui-players-select)
    (define-key map (kbd "<SPC>")             'lms-ui-players-playpause)
    (define-key map (kbd "C-w")               'lms-ui-players-toggle-power)
    (define-key map (kbd "h")                 'lms-ui-playing-now-help)
    (define-key map (kbd "?")                 'lms-ui-playing-now-help)
    (define-key map (kbd "q")                 '(lambda () (interactive)
                                                 (kill-buffer (format "*LMS: Players*"))
                                                 (lms-ui-playing-now-refresh)))
    map)
  "Local keymap for `lms-ui-players-mode' buffers.")

(define-derived-mode lms-ui-players-mode tabulated-list-mode "LMS Players"
  "Major mode for LMS Players buffer.
Press 'h' or '?' keys for complete documentation."
  (setq tabulated-list-format [(" "         1 t :right-align nil)
                               (" "         1 t :right-align t)
                               ("Name"     25 t :right-align nil)
                               ("Model"    18 t :right-align nil)
                               ("Id"       18 t :right-align nil)
                               ("IP"       20 t :right-align nil)
                               ("Power?"    0 t :right-align nil)])
  (setq tabulated-list-padding 0)
  (tabulated-list-init-header))

(defun lms-ui-players ()
  "Players."
  (interactive)
  (switch-to-buffer "*LMS: Players*" nil)
  (setq-local buffer-read-only nil)
  (erase-buffer)
  (lms-ui-players-mode)
  (lms--get-players)  ; bypass players cache
  (let* ((res (lms--cmd "serverstatus -"))
         (players (alist-get 'players_loop res)))
    (setq tabulated-list-entries
          (mapcar #'(lambda (p)
                      (let-alist p
                        (list .playerid
                              (vector
                               (propertize (if (string= .playerid lms--default-playerid) "➤" " ") 'face 'lms-players-selected-face)
                               (propertize (if (zerop .isplaying) " " "♫")'face 'lms-players-isplaying-face)
                               (propertize .name 'face 'lms-players-name-face)
                               (propertize .modelname 'face 'lms-players-model-face)
                               (propertize .playerid 'face 'lms-players-playerid-face)
                               (propertize .ip 'face 'lms-players-ip-face)
                               (propertize (if (zerop .power) "  ✘" "  ✔") 'face 'lms-players-power-face)))))
                  players)))
  (tabulated-list-print t)
  (goto-char (point-min))
  (hl-line-mode 1)
  (setq-local cursor-type nil)
  (search-forward "♫" nil t)
  (move-beginning-of-line nil))

(defun lms-ui-players-select ()
  "Select active player and close view."
  (interactive)
  (when (tabulated-list-get-id)
    (setq lms--default-playerid (tabulated-list-get-id))
    (kill-buffer (format "*LMS: Players*"))
    (lms-ui-playing-now-refresh)))

(defun lms-ui-players-playpause ()
  "Toggle play/pause."
  (interactive)
  (when (tabulated-list-get-id)
    (let ((ln (1- (line-number-at-pos))))
      (lms--cmd '("pause") (tabulated-list-get-id))
      (sleep-for .2)
      (lms-ui-players)
      (goto-char (point-min))
      (forward-line ln))))

(defun lms-ui-players-toggle-power ()
  "Toggle power state."
  (interactive)
  (when (tabulated-list-get-id)
    (let ((ln (1- (line-number-at-pos))))
      (lms--cmd "power" (tabulated-list-get-id))
      (sleep-for .2)
      (lms-ui-players)
      (goto-char (point-min))
      (forward-line ln))))


;;;;; Playing list
(defvar lms-ui-playlist-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map [remap end-of-buffer]     '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap end-of-defun]      '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap forward-paragraph] '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap next-line]         '(lambda () (interactive) (forward-line 1) (when (eobp) (forward-line -1))))
    (define-key map (kbd "RET")               'lms-ui-playlist-play)
    (define-key map (kbd "i")                 'lms-ui-playlist-track-info)
    (define-key map (kbd "j")                 'lms-ui-playlist-jump-to-current)
    (define-key map (kbd "d")                 'lms-ui-playlist-delete-track)
    (define-key map (kbd "<delete>")          'lms-ui-playlist-delete-track)
    (define-key map (kbd "c c")               'lms-ui-playlist-clear)
    (define-key map (kbd "c u")               'lms-ui-playlist-clear-until-track)
    (define-key map (kbd "c f")               'lms-ui-playlist-clear-from-track)
    (define-key map (kbd "g")                 'lms-ui-playlist)
    (define-key map (kbd "A")                 'lms-ui-playlist-artist-albums-list)
    (define-key map (kbd "L")                 'lms-ui-playlist-album-tracks-list)
    (define-key map (kbd "Y")                 'lms-ui-playlist-year-albums-list)
    (define-key map (kbd "h")                 'lms-ui-playing-now-help)
    (define-key map (kbd "?")                 'lms-ui-playing-now-help)
    (define-key map (kbd "q")                 '(lambda () (interactive)
                                                 (kill-buffer (format "*LMS: Playlist [%d tracks]*" (length lms--ui-pl-tracks)))
                                                 (lms-ui-playing-now-refresh)))
    map)
  "Local keymap for `lms-ui-playlist-mode' buffers.")

(define-derived-mode lms-ui-playlist-mode tabulated-list-mode "LMS Playlist"
  "Major mode for LMS Playlist buffer.
Press 'h' or '?' keys for complete documentation."
  (setq tabulated-list-format [(" "        1  nil :right-align nil)
                               ("Title"   28    t :right-align nil)
                               ("Artist"  21    t :right-align nil)
                               ("Year"     4    t :right-align nil)
                               ("Album"   22    t :right-align nil)
                               ("Tr#"      3    t :right-align t)
                               ("Time"     0    t :right-align nil)])
  (setq tabulated-list-padding 0)
  (tabulated-list-init-header))

(defun lms-ui-playlist ()
  "Playlist."
  (interactive)
  (mapc #'(lambda (b) (when (string-prefix-p "*LMS: Playlist" (buffer-name b))
                        (kill-buffer b)))
            (buffer-list))
  (switch-to-buffer "*LMS: Playlist*" nil)
  (setq-local buffer-read-only nil)
  (erase-buffer)
  (lms-ui-playlist-mode)
  (let* ((res (lms--cmd "status 0 1000 tags:alydt"))
         (idx (let ((idx (alist-get 'playlist_cur_index res)))
                (if (stringp idx) (string-to-number idx) (or idx 0))))
         (tracks (alist-get 'playlist_loop res)))
    (setq tabulated-list-entries
          (mapcar #'(lambda (tr)
                      (list (alist-get (intern "playlist index") tr)
                            (vector
                             (propertize (if (= (alist-get (intern "playlist index") tr) idx) "♫" " ") 'face 'lms-playing-face)
                             (propertize (or (alist-get 'title tr) "No title") 'face 'lms-title-face)
                             (propertize (or (alist-get 'artist tr) "No artist") 'face 'lms-artist-face)
                             (propertize (lms--ensure-string  (alist-get 'year tr)) 'face 'lms-year-face)
                             (propertize (or (alist-get 'album tr) "No album") 'face 'lms-album-face)
                             (propertize (lms--ensure-string (alist-get 'tracknum tr)) 'face 'lms-tracknum-face)
                             (propertize (lms--format-time (or (alist-get 'duration tr) 0)) 'face 'lms-duration-face))))
                  tracks))
      (setq-local lms--ui-pl-tracks tracks))
  (rename-buffer (format "*LMS: Playlist [%d tracks]*" (length lms--ui-pl-tracks)))
  (tabulated-list-print t)
  (goto-char (point-min))
  (hl-line-mode 1)
  (setq-local cursor-type nil)
  (search-forward "♫" nil t)
  (move-beginning-of-line nil))

(defun lms-ui-playlist-play ()
  "Play selected track."
  (interactive)
  (when (tabulated-list-get-id)
    (lms-playlist-play-track (tabulated-list-get-id))
    (sleep-for 0.5)
    (lms-ui-playlist)))

(defun lms-ui-playlist-jump-to-current ()
  "Jump to current track."
  (interactive)
  (goto-char (point-min))
  (search-forward "♫" nil t))

(defun lms-ui-playlist-delete-track ()
  "Remove selected track from playlist."
  (interactive)
  (when (tabulated-list-get-id)
    (let ((ln (1- (line-number-at-pos))))
      (lms-playlist-delete-track (tabulated-list-get-id))
      (lms-ui-playlist)
      (goto-char (point-min))
      (forward-line ln))))

(defun lms-ui-playlist-clear-until-track ()
  "Remove tracks from playlist, from start to cursor."
  (interactive)
  (when (and (tabulated-list-get-id) (y-or-n-p "Clear tracks from start to cursor? "))
    (let ((current (1- (tabulated-list-get-id))))
      (while (>= current 0)
        (lms-playlist-delete-track current)
        (setq current (1- current)))
      (lms-ui-playlist))))

(defun lms-ui-playlist-clear-from-track ()
  "Remove tracks from playlist, from cursor to end."
  (interactive)
  (when (and (tabulated-list-get-id) (y-or-n-p "Clear tracks from cursor to end? "))
    (let ((current (tabulated-list-get-id))
          (max (1- (length lms--ui-pl-tracks))))
      (while (>= max current)
        (lms-playlist-delete-track max)
        (setq max (1- max)))
      (lms-ui-playlist))))

(defun lms-ui-playlist-clear ()
  "Clear playlist."
  (interactive)
  (when (and (tabulated-list-get-id) (y-or-n-p "Clear playlist? "))
    (lms-playlist-clear)
    (lms-ui-playlist)))

(defun lms-ui-playlist-track-info ()
  "Open track information buffer for selected track."
  (interactive)
  (when (tabulated-list-get-id)
    (let ((trackid (alist-get 'id (nth (tabulated-list-get-id) lms--ui-pl-tracks)))
          (tracks-ids (mapcar #'(lambda (s) (alist-get 'id s)) lms--ui-pl-tracks)))
      (lms-ui-track-info trackid tracks-ids))))

(defun lms-ui-playlist-artist-albums-list ()
  "Show list of albums by the artist of current track."
  (interactive)
  (when (tabulated-list-get-id)
    (let* ((artist (alist-get 'artist (nth (tabulated-list-get-id) lms--ui-pl-tracks)))
           (artistid (lms-get-artist-id-from-name artist))
           (buftitle (format "*LMS: Albums by %s*" artist))
           (lst (lms-get-albums-from-artistid artistid)))
      (lms-ui-year-album-artist-list buftitle lst))))

(defun lms-ui-playlist-year-albums-list ()
  "Show list of albums by year of current track."
  (interactive)
    (when (tabulated-list-get-id)
      (let* ((year (alist-get 'year (nth (tabulated-list-get-id) lms--ui-pl-tracks)))
             (buftitle (format "*LMS: Albums in year %d*" year))
             (lst (lms-get-albums-from-year year)))
        (lms-ui-year-album-artist-list buftitle lst))))

(defun lms-ui-playlist-album-tracks-list ()
  "Show list of tracks in album of current track."
  (interactive)
    (when (tabulated-list-get-id)
      (let* ((album (alist-get 'album (nth (tabulated-list-get-id) lms--ui-pl-tracks)))
             (artist (alist-get 'artist (nth (tabulated-list-get-id) lms--ui-pl-tracks)))
             (albumid (lms-get-album-id-from-name album artist))
             (buftitle (format "*LMS: Tracks in album '%s'*" album))
             (lst (lms-get-tracks-from-albumid albumid)))
        (lms-ui-tracks-list buftitle lst))))


;;;;; Tracklist
(defvar lms-ui-tracks-list-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map [remap end-of-buffer]     '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap end-of-defun]      '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap forward-paragraph] '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap next-line]         '(lambda () (interactive) (forward-line 1) (when (eobp) (forward-line -1))))
    (define-key map (kbd "i")                 'lms-ui-tl-track-info)
    (define-key map (kbd "RET")               'lms-ui-tl-track-info)
    (define-key map (kbd "p")                 'lms-ui-tl-to-playlist)
    (define-key map (kbd "P")                 'lms-ui-tl-all-to-playlist)
    (define-key map (kbd "Y")                 'lms-ui-tl-by-year)
    (define-key map (kbd "A")                 'lms-ui-tl-by-artist)
    (define-key map (kbd "h")                 'lms-ui-playing-now-help)
    (define-key map (kbd "?")                 'lms-ui-playing-now-help)
    (define-key map (kbd "q")                 '(lambda () (interactive)
                                                 (kill-buffer)
                                                 (lms-ui-playing-now-refresh)))
    map)
  "Local keymap for `lms-ui-tracks-list-mode' buffers.")

(define-derived-mode lms-ui-tracks-list-mode tabulated-list-mode "LMS Tracks"
  "Major mode for LMS Tracks buffer.
Press 'h' or '?' keys for complete documentation."
  (setq tabulated-list-format [("Tr#"      3    t :right-align t)
                               ("Title"   32    t :right-align nil)
                               ("Artist"  24    t :right-align nil)
                               ("Year"     4    t :right-align nil)
                               ("Album"   25    t :right-align nil)
                               ("Time"     0    t :right-align nil)])
  (setq tabulated-list-padding 0)
  (tabulated-list-init-header))

(defun lms-ui-tracks-list (buftitle lst)
  "Tracks list with BUFTITLE and LST entries."
  (interactive)
  (switch-to-buffer buftitle nil)
  (setq-local buffer-read-only nil)
  (erase-buffer)
  (lms-ui-tracks-list-mode)
  (setq tabulated-list-entries
        (mapcar #'(lambda (x)
                    (list (alist-get 'id x)
                          (vector
                           (propertize (lms--ensure-string (alist-get 'tracknum x)) 'face 'lms-tracknum-face)
                           (propertize (or (alist-get 'title x) "No title") 'face 'lms-title-face)
                           (propertize (or (alist-get 'artist x) "No artist") 'face 'lms-artist-face)
                           (propertize (lms--ensure-string (alist-get 'year x)) 'face 'lms-year-face)
                           (propertize (or (alist-get 'album x) "No album") 'face 'lms-album-face)
                           (propertize (lms--format-time (alist-get 'duration x)) 'face 'lms-duration-face))))
                lst))
  (setq-local lms--ui-tracks-lst lst)
  (tabulated-list-print t)
  (goto-char (point-min))
  (hl-line-mode 1)
  (setq-local cursor-type nil))

(defun lms-ui-tl-track-info ()
  "Open track information buffer for track under cursor."
  (interactive)
  (when (tabulated-list-get-id)
    (let ((trackid (tabulated-list-get-id))
          (tracks-ids (mapcar #'(lambda (s) (alist-get 'id s)) lms--ui-tracks-lst)))
      (lms-ui-track-info trackid tracks-ids))))

(defun lms-ui-tl-to-playlist ()
  "Add song to track list."
  (interactive)
  (when (tabulated-list-get-id)
    (lms-playlistcontrol-action (format "track_id:%s" (tabulated-list-get-id)))
    (kill-buffer)))

(defun lms-ui-tl-all-to-playlist ()
  "Add all songs to track list."
  (interactive)
  (when (tabulated-list-get-id)
    (let ((tracks (string-join (mapcar #'(lambda (x) (number-to-string (alist-get 'id x))) lms--ui-tracks-lst) ",")))
      (lms-playlistcontrol-action (format "track_id:%s" tracks) "Add all tracks to playlist?")
      (kill-buffer))))

(defun lms-ui-tl-by-artist ()
  "Browse list of albums by artist of track under cursor."
  (interactive)
  (when (tabulated-list-get-id)
    (let* ((artist (alist-get 'artist (seq-find #'(lambda (x) (= (alist-get 'id x) (tabulated-list-get-id))) lms--ui-tracks-lst)))
           (artistid (lms-get-artist-id-from-name artist))
           (buftitle (format "*LMS: Albums by artist %s*" artist))
           (lst (lms-get-albums-from-artistid artistid)))
      (kill-buffer)
      (lms-ui-year-album-artist-list buftitle lst))))

(defun lms-ui-tl-by-year ()
  "Browse list of albums by year of track under cursor."
  (interactive)
  (when (tabulated-list-get-id)
    (let* ((year (alist-get 'year (seq-find #'(lambda (x) (= (alist-get 'id x) (tabulated-list-get-id))) lms--ui-tracks-lst)))
           (buftitle (format "*LMS: Albums in year %d*" year))
           (lst (lms-get-albums-from-year year)))
      (kill-buffer)
      (lms-ui-year-album-artist-list buftitle lst))))


;;;;; Year - Album - Artist list
(defvar lms-ui-year-album-artist-list-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map tabulated-list-mode-map)
    (define-key map [remap end-of-buffer]     '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap end-of-defun]      '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap forward-paragraph] '(lambda () (interactive) (goto-char (max-char)) (forward-line -1)))
    (define-key map [remap next-line]         '(lambda () (interactive) (forward-line 1) (when (eobp) (forward-line -1))))
    (define-key map (kbd "Y")                 'lms-ui-yaal-by-year)
    (define-key map (kbd "A")                 'lms-ui-yaal-by-artist)
    (define-key map (kbd "L")                 'lms-ui-yaal-by-album)
    (define-key map (kbd "RET")               'lms-ui-yaal-by-album)
    (define-key map (kbd "p")                 'lms-ui-yaal-to-playlist)
    ;; TODO: Add all entries to playlist?
    ;; (define-key map (kbd "P")                 'lms-ui-yaal-all-to-playlist)
    (define-key map (kbd "h")                 'lms-ui-playing-now-help)
    (define-key map (kbd "?")                 'lms-ui-playing-now-help)
    (define-key map (kbd "q")                 '(lambda () (interactive)
                                                 (kill-buffer)
                                                 (lms-ui-playing-now-refresh)))
    map)
  "Local keymap for `lms-ui-year-album-artist-list-mode' buffers.")

(define-derived-mode lms-ui-year-album-artist-list-mode tabulated-list-mode "LMS Year-Artist-Album"
  "Major mode for LMS Year-Album-Artist buffer.
 Press 'h' or '?' keys for complete documentation."
  (setq tabulated-list-format [("Year"     6   t :right-align nil)
                               ("Album"    40  t :right-align nil)
                               ("Artist"   0   t :right-align nil)])
  (setq tabulated-list-padding 1)
  (tabulated-list-init-header))

(defun lms-ui-year-album-artist-list (buftitle lst)
  "Year-Album-Artist list with BUFTITLE and LST entries."
  (interactive)
  (switch-to-buffer buftitle nil)
  (setq-local buffer-read-only nil)
  (erase-buffer)
  (lms-ui-year-album-artist-list-mode)
  (setq tabulated-list-entries
        (mapcar #'(lambda (x)
                    (list (alist-get 'id x)
                          (vector
                           (propertize (lms--ensure-string (alist-get 'year x)) 'face 'lms-year-face)
                           (propertize (or (alist-get 'album x) "No album") 'face 'lms-album-face)
                           (propertize (or (alist-get 'artist x) "No artist") 'face 'lms-artist-face))))
                lst))
  (setq-local lms--ui-yaal-lst lst)
  (tabulated-list-print t)
  (goto-char (point-min))
  (hl-line-mode 1)
  (setq-local cursor-type nil))

(defun lms-ui-yaal-to-playlist ()
  "Select and execute action for artist album list."
  (interactive)
  (when (tabulated-list-get-id)
    (lms-playlistcontrol-action (format "album_id:%s" (tabulated-list-get-id)))
    (kill-buffer)))

(defun lms-ui-yaal-by-artist ()
  "Browse list of albums by artist of album under cursor."
  (interactive)
  (when (tabulated-list-get-id)
    (let* ((artist (alist-get 'artist (seq-find #'(lambda (x) (= (alist-get 'id x) (tabulated-list-get-id))) lms--ui-yaal-lst)))
           (artistid (lms-get-artist-id-from-name artist))
           (buftitle (format "*LMS: Albums by artist %s*" artist))
           (lst (lms-get-albums-from-artistid artistid)))
      (kill-buffer)
      (lms-ui-year-album-artist-list buftitle lst))))

(defun lms-ui-yaal-by-year ()
  "Browse list of albums by year of album under cursor."
  (interactive)
  (when (tabulated-list-get-id)
    (let* ((year (alist-get 'year (seq-find #'(lambda (x) (= (alist-get 'id x) (tabulated-list-get-id))) lms--ui-yaal-lst)))
           (buftitle (format "*LMS: Albums in year %d*" year))
           (lst (lms-get-albums-from-year year)))
      (kill-buffer)
      (lms-ui-year-album-artist-list buftitle lst))))

(defun lms-ui-yaal-by-album ()
  "Browse list of tracks of album under cursor."
  (interactive)
  (when (tabulated-list-get-id)
    (let* ((album (alist-get 'album (seq-find #'(lambda (x) (= (alist-get 'id x) (tabulated-list-get-id))) lms--ui-yaal-lst)))
           (artist (alist-get 'artist (seq-find #'(lambda (x) (= (alist-get 'id x) (tabulated-list-get-id))) lms--ui-yaal-lst)))
           (albumid (lms-get-album-id-from-name album artist))
           (buftitle (format "*LMS: Tracks in album '%s'*" (lms-get-album-name-from-id albumid)))
           (lst (lms-get-tracks-from-albumid albumid)))
      (kill-buffer)
      (lms-ui-tracks-list buftitle lst))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(provide 'lms)
;;; lms.el ends here
