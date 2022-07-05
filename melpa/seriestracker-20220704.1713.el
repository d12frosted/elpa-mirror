;;; seriestracker.el --- Series tracker -*- lexical-binding: t; -*-

;; Copyright 2022 Maxime Wack

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

;; Author: Maxime Wack <contact at maximewack dot com>
;; Version: 1.3.0
;; Package-Version: 20220704.1713
;; Package-Commit: ce8b86a9eee175de513d00ce3e1aa754adbf5c8a
;; Package-Requires: ((dash "2.12.1") (transient "0.3.2") (emacs "27.1"))
;; Keywords: multimedia
;; URL: https://www.github.com/MaximeWack/seriesTracker

;;; Commentary:

;; seriestracker implements a major mode for tracking TV shows.
;; TV shows data (episode list, release dates, etc.)
;; are sourced from the free database hosted at episodate.com
;; The mode presents an outlined list of tracked shows,
;; their episodes and release dates, and enables the user
;; to see when new episodes for their favorite shows get released,
;; and track their progress in watching a series.

;;; Code:

;;; Requirements

;; Libraries that we will need

(require 'url)                                                                  ; used to fetch api data
(require 'json)                                                                 ; used to parse api response
(require 'dash)                                                                 ; threading etc.
(require 'transient)                                                            ; transient for command dispatch

;;; Helpers

;; Some helpers to manipulate lists created from JSON data
;; JSON produces collections of alists (an "array" here)

;;;; alist-select

;; We first need a function to select fields from an alist

(defun seriestracker--utils-alist-select (fields alist)
  "Keep only FIELDS in ALIST.
This is done by constructing a new alist containing only these elements.
alist-select '(a c) '((a .1) (b , \"b\") (c . c)
returns '((a . 1) (c . c))"
  (->> fields
       reverse
       (--reduce-from (cons (cons it (alist-get it alist)) acc) nil)))

;;;; array-select

;; Extended to an array

(defun seriestracker--utils-array-select (fields array)
  "Keep only FIELDS in every alist in the ARRAY.
array-select '(a c) '(((a . 1) (b . 2) (c . c)) ((a . 3) (b . 5) (c . d)))
returns '(((a . 1) (c . c)) ((a . 3) (c . d)))"
  (--map (seriestracker--utils-alist-select fields it) array))

;;;; array-pull

;; Pull ONE field from an array, as a simple list of values

(defun seriestracker--utils-array-pull (field array)
  "Keep only FIELD in every alist in the ARRAY and flatten.
array-pull 'a '(((a . 1) (b . 2)) ((a . 3) (b . 4)))
returns '(1 3)"
  (--map (alist-get field it) array))

;;;; getJSON

;; Extract and parse the JSON from the returned url buffer

(defun seriestracker--getJSON (url-buffer)
  "Parse the JSON in the URL-BUFFER returned by url."
  (with-current-buffer url-buffer
    (goto-char (point-max))
    (move-beginning-of-line 1)
    (json-read-object)))

;;;; with-episode

;; Macro to get episode, season and series from text properties at point
;; provide the series and episode objects from the data

(defmacro seriestracker--with-episode (lets &rest body)
  "Provide a let* environment with EPISODEN, SEASONN and ID (series) filled.
Populate SERIES and EPISODE themselves as well.
LETS is a list of bindings to insert in the let* form.
BODY is the body of the let* form."

  `(let* ((id (get-text-property (point) 'seriestracker-series))
          (seasonN (get-text-property (point) 'seriestracker-season))
          (episodeN (get-text-property (point) 'seriestracker-episode))
          (series (when id (--find (= id (alist-get 'id it)) seriestracker--data)))
          (episode (when episodeN (--find (and (= seasonN (alist-get 'season it))
                                               (= episodeN (alist-get 'episode it)))
                                          (alist-get 'episodes series))))
          ,@lets)
     ,@body))

;;; episodate.com API

;; The episodate.com API exposes two functions useful to us: search and show-details

;;;; search

;; Search for a term and return all matching series
;; to display for choice in the minibuffer and to fetch

(defun seriestracker--search (name &optional page acc)
  "Search episodate.com db for NAME.
Recursively get page PAGE, carrying results in ACC."
  (let* ((page (or page 1))
         (url-request-method "GET")
         (res (url-retrieve-synchronously (concat "https://www.episodate.com/api/search?q=" name "&page=" (int-to-string page))))
         (json (seriestracker--getJSON res))
         (numpages (alist-get 'pages json))
         (content (seriestracker--utils-array-select '(id permalink) (cdar (seriestracker--utils-alist-select '(tv_shows) json)))))
    (message (concat "Fetching page " (int-to-string page) "/" (int-to-string numpages)))
    (cond ((= page numpages) (append acc content))
          (t (seriestracker--search name (1+ page) (append acc content))))))

;;;; series

;; The list of episodes in a series is converted from JSON as a vector
;; This converts all vectors to lists by simply mapping identity

(defun seriestracker--episodes (series)
  "Transform the episodes of SERIES from a vector to a list."
  (setf (alist-get 'episodes series)
        (--map it (alist-get 'episodes series)))
  series)

;; Fetch a series

(defun seriestracker--series (id)
  "Get series ID info."
  (->> (let ((url-request-method "GET"))
         (url-retrieve-synchronously (concat "https://www.episodate.com/api/show-details?q=" (int-to-string id))))
       seriestracker--getJSON
       car
       (seriestracker--utils-alist-select '(id name start_date status episodes))
       seriestracker--episodes))

;;; Internal API

;; Here we define an API to expose our internal representation of data

;;;; Data model

;; The data model is an array of series, each containing an array of episodes
;; To the properties from the external API we will add a watched status and notes

(defvar seriestracker--data nil
  "Internal data containing followed series and episode.
Of the form :
'(((id . seriesId) (…) (episodes ((id . episodeId) (watched . t)  (…))
                                 ((id . episodeId) (watched)  (…)))))
  ((id . seriesId) (…) (episodes ((id . episodeId) (…))
                                 ((id . episodeId) (…)))))
series props are name and start_date.
episodes props are season, episode, name, and air_date.")

;;;; Add/remove
;;;;; Add series

;; A series is added by first removing it in case it is already is here
;; then cons-ing it to the data

(defun seriestracker--add (id)
  "Add series with ID to `seriestracker--data'.
Adding an already existing series resets it."
  (seriestracker--remove id)
  (setq seriestracker--data
        (cons (seriestracker--series id) seriestracker--data)))

;;;;; Remove series

(defun seriestracker--remove (id)
  "Remove series with ID from `seriestracker--data'."
  (setq seriestracker--data
        (--remove (= id (alist-get 'id it)) seriestracker--data)))

;;;; Watch

;; General watch-region function that will be also used to watch single episodes, whole seasons, and whole series
;; Seasons and episodes are numbered, but series are not so we use indexes to apply to a range of series

(defun seriestracker--watch-region (start-series start-season start-episode end-series end-season end-episode watch)
  "WATCH from START-EPISODE of START-SEASON of START-SERIES to END-EPISODE of END-SEASON of END-SERIES."
  (let* ((series1 (--find-index (= start-series (alist-get 'id it)) seriestracker--data))
         (series2 (if end-series
                      (--find-index (= end-series (alist-get 'id it)) seriestracker--data)
                    (1+ series1))))
    (--each
        seriestracker--data
      (let ((series-index it-index))
        (setf (alist-get 'episodes it)
              (--map-when
               (and (or (> series-index series1)
                        (and (= series-index series1)
                             (or (> (alist-get 'season it) start-season)
                                 (and (= (alist-get 'season it) start-season)
                                      (>= (alist-get 'episode it) start-episode)))))
                    (or (< series-index series2)
                        (and (= series-index series2)
                             (or (< (alist-get 'season it) (or end-season 0))
                                 (and (= (alist-get 'season it) (or end-season 0))
                                      (< (alist-get 'episode it) (or end-episode 0)))))))
               (progn
                 (when (time-less-p (date-to-time (alist-get 'air_date it)) (current-time))
                   (setf (alist-get 'watched it nil t) watch))
                 it)
               (alist-get 'episodes it)))))))

;;;; Query updates

;; Call update-series on all non-ended series

(defun seriestracker--update ()
  "Update all non-ended series."
  (--map-when
   (not (string-equal "Ended" (alist-get 'status it)))
   (seriestracker--update-series it)
   seriestracker--data))

;; To update a series, it is first reset, then the watch status and notes are propagated by indices

(defun seriestracker--update-series (series)
  "Update the SERIES."
  (let* ((new (seriestracker--series (alist-get 'id series)))
         (newEp (alist-get 'episodes new))
         (status (alist-get 'status new))
         (watched (--find-indices (alist-get 'watched it) (alist-get 'episodes series)))
         (noted (--find-indices (alist-get 'note it) (alist-get 'episodes series)))
         (notes (-zip noted
                      (seriestracker--utils-array-pull 'note (-select-by-indices noted (alist-get 'episodes series)))))
         (newEps (->> newEp
                      (--map-indexed (if (-contains? watched it-index)
                                         (progn
                                           (setf (alist-get 'watched it) t)
                                           it)
                                       it))
                      (--map-indexed (progn
                                       (setf (alist-get 'note it nil t) (alist-get it-index notes))
                                       it)))))
    (when (string-equal status "Ended") (setf (alist-get 'status series) "Ended"))
    (setf (alist-get 'episodes series) newEps)
    series))

;;;; Load/save data

;; Default location for the data is in the user emacs directory

(defvar seriestracker-file (concat user-emacs-directory "seriestracker.el")
  "Location of the save file.")

;; Save by printing a READable object to the file

(defun seriestracker--save ()
  "Save the database to `seriestracker-file'."
  (save-excursion
    (with-temp-file seriestracker-file
      (let ((print-level nil)
            (print-length nil))
        (prin1 seriestracker--data (current-buffer))
        (goto-char 1)
        (while (search-forward ")) " nil t)
          (replace-match "))\n" nil t))
        (goto-char 1)
        (while (search-forward " (episodes" nil t)
          (replace-match "\n(episodes" nil t))
        (lisp-indent-region 0 (point-max))))))

;; Load by READing from the content of the file in a temporary buffer

(defun seriestracker--load ()
  "Load the database from `seriestracker-file'."
  (with-temp-buffer
    (insert-file-contents seriestracker-file t)
    (cl-assert (bobp))
    (setq seriestracker--data (read (current-buffer)))))

;;; Interface

;; Here we will define all user facing functions and UI elements

;;;; Faces

;; Faces for series
;; inherit from two levels of outline-mode
;; shadowed for finished series
;; striked through for watched episodes

(defface seriestracker-series
  '((t (:inherit outline-1)))
  "Face for series names"
  :group 'seriestracker-faces)

(defface seriestracker-finished-series
  '((t (:inherit (shadow outline-1))))
  "Face for finished series names"
  :group 'seriestracker-faces)

(defface seriestracker-season
  '((t (:inherit outline-2)))
  "Face for seasons"
  :group 'seriestracker-faces)

(defface seriestracker-watched
  '((t (:inherit shadow :strike-through t)))
  "Face for watched episodes"
  :group 'seriestracker-faces)

;;;; Check if in seriestracker buffer

;; Helper function to check we are indeed in the correct buffer running the mode

(defun seriestracker--inbuffer ()
  "Check if we are in the seriestracker buffer in seriestracker mode."
  (unless (and (string-equal (buffer-name) "seriestracker")
               (string-equal mode-name "seriestracker"))
    (error "Not in seriestracker buffer")))

;;;; Draw buffer

;; Fold cycle status

(defvar seriestracker--fold-cycle 'seriestracker-all-folded
  "Current folding status.
Can be 'seriestracker-all-folded, 'seriestracker-series-folded, or 'seriestracker-all-unfolded")

;; Store position, redraw buffer, restore position and fold cycle

(defun seriestracker--refresh ()
  "Refresh the seriestracker buffer."
  (seriestracker--with-episode ()
                               (seriestracker--draw-buffer)
                               (seriestracker-move-to id seasonN episodeN)
                               (cond ((eq seriestracker--fold-cycle 'seriestracker-all-folded)
                                      (seriestracker--fold-all))
                                     ((eq seriestracker--fold-cycle 'seriestracker-all-unfolded)
                                      (seriestracker--unfold-all))
                                     ((eq seriestracker--fold-cycle 'seriestracker-series-folded)
                                      (seriestracker--unfold-all-series)))))

;; Erase the buffer and draw every series

(defun seriestracker--draw-buffer ()
  "Draw the buffer.
Erase first then redraw the whole buffer."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (-each seriestracker--data 'seriestracker--draw-series)))

;; Draw the series title, then all episodes
;; Text properties are used to tag series, seasons and episodes, as well as the watched status and notes
;; previous/next-single-property-change functions help navigating in the buffer

(defun seriestracker--draw-series (series)
  "Print the SERIES id and name."
  (let* ((id (alist-get 'id series))
         (name (alist-get 'name series))
         (note (alist-get 'note series))
         (episodes (alist-get 'episodes series))
         (seriestracker-face `(:inherit ,(if (string-equal "Ended" (alist-get 'status series))
                                             'seriestracker-finished-series
                                           'seriestracker-series)
                                        :weight ,(when note 'normal)))
         (seriestracker-watched (if (--all? (alist-get 'watched it)
                                            episodes)
                                    'seriestracker-watched
                                  nil)))
    (insert (propertize (concat name "\n")
                        'seriestracker-series id
                        'seriestracker-season nil
                        'seriestracker-episode nil
                        'face seriestracker-face
                        'help-echo note
                        'invisible seriestracker-watched))
    (--each episodes (seriestracker--draw-episode series it))))

;; Draw each episode, with the correct faces etc.

(defun seriestracker--draw-episode (series episode)
  "Print EPISODE from SERIES.
Print the time stamp, then episode number, and episode name.
If first episode of a season, print the season number."
  (let* ((id (alist-get 'id series))
         (seasonN (alist-get 'season episode))
         (episodeN (alist-get 'episode episode))
         (name (alist-get 'name episode))
         (air_date (alist-get 'air_date episode))
         (watched (alist-get 'watched episode))
         (note (alist-get 'note episode))
         (seriestracker-watched (if watched 'seriestracker-watched nil))
         (seriestracker-date-face `(:inherit ,(cond (watched 'seriestracker-watched)
                                                    ((time-less-p (date-to-time air_date) (current-time)) 'success)
                                                    (t 'error))
                                             :weight ,(if note
                                                          'bold
                                                        'normal)))
         (seriestracker-text-face `(:inherit ,(if watched
                                                  'seriestracker-watched
                                                'default)
                                             :weight ,(if note
                                                          'bold
                                                        'normal)))
         (start (point)))
    (when (= episodeN 1)
      (setq start (+ start 8 (length (int-to-string seasonN))))
      (let ((seriestracker-season-watched (if (--all? (alist-get 'watched it)
                                                      (--filter (= seasonN (alist-get 'season it))
                                                                (alist-get 'episodes series)))
                                              'seriestracker-watched
                                            nil)))
        (insert (propertize (concat "Season " (int-to-string seasonN) "\n")
                            'face 'seriestracker-season
                            'seriestracker-series id
                            'seriestracker-season seasonN
                            'seriestracker-episode nil
                            'invisible seriestracker-season-watched))))
    (insert (propertize (concat air_date " " (format "%02d" episodeN) " - " name "\n")
                        'face seriestracker-text-face
                        'seriestracker-series id
                        'seriestracker-season seasonN
                        'seriestracker-episode episodeN
                        'help-echo note
                        'invisible seriestracker-watched))
    (put-text-property start (+ start 19) 'face seriestracker-date-face)))

;;;; Movements

;; Move to previous line
;; Continue backwards while landing on invisible line
;; If reaching the beginning of the file, go to the next line
;; Display the note at point

(defun seriestracker-prev-line ()
  "Move one visible line up."
  (interactive)
  (seriestracker--inbuffer)
  (setq disable-point-adjustment t)
  (forward-line -1)
  (while (and (invisible-p (point))
              (> (point) 1))
    (forward-line -1))
  (when (and (bobp)
             (invisible-p 1))
    (seriestracker--move 'next))
  (seriestracker--display-note))

;; Move to next line

(defun seriestracker-next-line ()
  "Move one visible line down."
  (interactive)
  (seriestracker--inbuffer)
  (line-move 1)
  (seriestracker--display-note))

;; Move up the hierarchy
;; episode -> season
;; season -> series

(defun seriestracker-up ()
  "Move up in the hierarchy."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--with-episode ()
                               (cond (episodeN (goto-char (previous-single-property-change (point) 'seriestracker-season nil (point-min))))
                                     (seasonN (goto-char (previous-single-property-change (point) 'seriestracker-series nil (point-min)))))))

;; Generic function to move semantically in the hierarchy

(defun seriestracker--move (dir &optional same any)
  "Move in direction DIR in the hierarchy.
Use SAME to navigate between same-level headers,
and ANY to go to any header even if hidden."
  (seriestracker--inbuffer)
  (setq disable-point-adjustment t)
  (seriestracker--with-episode ((level (if (and same (not (or seasonN episodeN)))
                                           'seriestracker-series
                                         'seriestracker-season))
                                (dest (if (eq dir 'prev)
                                          (previous-single-property-change (point) level nil (point-min))
                                        (next-single-property-change (point) level nil (point-max)))))
                               (goto-char dest))
  (when (eq dir 'prev)
    (when (and (bobp)
               (invisible-p 1))
      (seriestracker--move 'next)))
  (unless any
    (when (invisible-p (point)) (seriestracker--move dir same))))

;; Move to previous node

(defun seriestracker-prev ()
  "Move to the previous visible node."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--move 'prev))

;; Move to next node

(defun seriestracker-next ()
  "Move to the next visible node."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--move 'next))

;; Move to previous node of the same level

(defun seriestracker-prev-same ()
  "Move to the previous visible node of the same level."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--move 'prev t))

;; Move to the next node of the same level

(defun seriestracker-next-same ()
  "Move to the next visible node of the same level."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--move 'next t))

;; Move to an arbitrary series ID, SEASON and EPISODE

(defun seriestracker-move-to (id &optional season episode)
  "Move point to the series ID, SEASON, EPISODE."
  (interactive)
  (goto-char (point-max))
  (text-property-search-backward 'seriestracker-series id t)
  (when season (text-property-search-forward 'seriestracker-season season t)
        (if episode
            (text-property-search-backward 'seriestracker-episode episode t t)
          (text-property-search-backward 'seriestracker-episode nil t))))

;;;; Folding

;; Folding uses the 'invisible overlay with two values:
;; - seriestracker-season for folding seasons
;; - seriestracker-series for folding series

;;;;; Dispatch folding

(defun seriestracker-fold-at-point (&optional unfold)
  "Fold or UNFOLD the section at point."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--with-episode ()
                               (cond (episodeN (seriestracker--fold-episodes unfold))
                                     (seasonN (seriestracker--fold-season unfold))
                                     (t (seriestracker--fold-series unfold)))))

(defun seriestracker-unfold-at-point ()
  "Unfold the section at point."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker-fold-at-point t))

;;;;; Fold episodes

;; Folding on an episode folds the season

(defun seriestracker--fold-episodes (&optional unfold)
  "Fold or UNFOLD the episodes at point."
  (let* ((season-start (previous-single-property-change (point) 'seriestracker-season))
         (fold-start (next-single-property-change season-start 'seriestracker-episode))
         (fold-end (next-single-property-change (point) 'seriestracker-season nil (point-max))))
    (if unfold
        (remove-overlays fold-start fold-end 'invisible 'seriestracker-season)
      (overlay-put (make-overlay fold-start fold-end) 'invisible 'seriestracker-season))))

;;;;; Fold seasons

(defun seriestracker--fold-season (&optional unfold)
  "Fold or UNFOLD the season at point."
  (let* ((fold-start (next-single-property-change (point) 'seriestracker-episode))
         (fold-end (next-single-property-change (point) 'seriestracker-season nil (point-max))))
    (if unfold
        (remove-overlays fold-start fold-end 'invisible 'seriestracker-season)
      (overlay-put (make-overlay fold-start fold-end) 'invisible 'seriestracker-season))))

;;;;; Fold series

(defun seriestracker--fold-series (&optional unfold)
  "Fold or UNFOLD the series at point."
  (let* ((fold-start (next-single-property-change (point) 'seriestracker-season))
         (fold-end (next-single-property-change (point) 'seriestracker-series nil (point-max))))
    (if unfold
        (remove-overlays fold-start fold-end 'invisible 'seriestracker-series)
      (when (and fold-start fold-end)
        (overlay-put (make-overlay fold-start fold-end) 'invisible 'seriestracker-series)))))

;;;; Cycle folding

;; Cycle between all unfolded, seasons folded, series folded

(defun seriestracker-cycle ()
  "Cycle folding."
  (interactive)
  (seriestracker--inbuffer)
  (cond ((eq seriestracker--fold-cycle 'seriestracker-all-folded)
         (seriestracker--unfold-all-series)
         (setq seriestracker--fold-cycle 'seriestracker-series-folded))
        ((eq seriestracker--fold-cycle 'seriestracker-series-folded)
         (seriestracker--unfold-all)
         (setq seriestracker--fold-cycle 'seriestracker-all-unfolded))
        ((eq seriestracker--fold-cycle 'seriestracker-all-unfolded)
         (seriestracker--fold-all)
         (setq seriestracker--fold-cycle 'seriestracker-all-folded))))

;; Unfolding all is simply removing all overlays

(defun seriestracker--unfold-all ()
  "Unfold everything."
  (remove-overlays (point-min) (point-max) 'invisible 'seriestracker-series)
  (remove-overlays (point-min) (point-max) 'invisible 'seriestracker-season))

;; Folding all is unfolding all then folding everything

(defun seriestracker--fold-all ()
  "Fold everything."
  (save-excursion
    (seriestracker--unfold-all)
    (goto-char 1)
    (while (not (eobp))
      (seriestracker-fold-at-point)
      (seriestracker--move 'next nil t))))

;; Folding only the seasons is folding all then unfolding the series

(defun seriestracker--unfold-all-series ()
  "Unfold all series."
  (seriestracker--fold-all)
  (remove-overlays (point-min) (point-max) 'invisible 'seriestracker-series))

;;;; Transient

;;;;; Settings

(defvar seriestracker-show-watched "hide"
  "Current strategy for dealing with watched episodes.")

(defvar seriestracker-sorting-type "next"
  "Current strategy for sorting series.")

;;;;; Transient dispatch

(transient-define-prefix seriestracker-dispatch ()
  "Command dispatch for seriestracker."
  ["Series"
   :if-mode seriestracker-mode
   [("A" "Search and add a series" seriestracker-search)
    ("D" "Delete a series" seriestracker-remove)]
   [("w" "Toggle watch at point" seriestracker-toggle-watch)
    ("u" "Watch up to point" seriestracker-watch-up)
    ("N" "Add/remove a note from an episode" seriestracker-add-note)]
   [("U" "Update and refresh the buffer" seriestracker-update)]]
  ["Display"
   :if-mode seriestracker-mode
   [("W" seriestracker--infix-watched)
    ("S" seriestracker--infix-sorting)]]
  ["Load/Save"
   :if-mode seriestracker-mode
   [("s" "Save database" seriestracker-save)
    ("l" "Load database" seriestracker-load)
    ("f" seriestracker--infix-savefile)]])

;;;;; Classes

;; Define classes for setable variables and multichoice variables

;;;;;; Variable

;; The object has a value (inherited from transient-variable)
;; but we also get and set the value of the linked variable

(defclass seriestracker--transient-variable (transient-variable)
  ((variable :initarg :variable)))

(cl-defmethod transient-init-value ((obj seriestracker--transient-variable))
  "Method to initialise the value of an `seriestracker--transient-variable' OBJ."
  (oset obj value (eval (oref obj variable))))

(cl-defmethod transient-infix-read ((obj seriestracker--transient-variable))
  "Method to read a new value for an `seriestracker--transient-variable' OBJ."
  (read-from-minibuffer (concat (oref obj description) ": ") (oref obj value)))

(cl-defmethod transient-infix-set ((obj seriestracker--transient-variable) value)
  "Method to set VALUE for an `seriestracker--transient-variable' OBJ."
  (oset obj value value)
  (set (oref obj variable) value))

(cl-defmethod transient-format-value ((obj seriestracker--transient-variable))
  "Method to format the value of an `seriestracker--transient-variable' OBJ."
  (let ((value (oref obj value)))
    (concat
     (propertize "(" 'face 'transient-inactive-value)
     (propertize value 'face 'transient-value)
     (propertize ")" 'face 'transient-inactive-value))))

;;;;;; Multichoice variable

;; Multi-choice inherits from simple variable and adds choices, a default value, and a triggered action
;; "reading" the value is getting the next one in the list of choices or cycling
;; setting also calls the action

(defclass seriestracker--transient-variable-choice (seriestracker--transient-variable)
  ((name :initarg :name)
   (choices :initarg :choices)
   (default :initarg :default)
   (action :initarg :action)))

(cl-defmethod transient-infix-read ((obj seriestracker--transient-variable-choice))
  "Method to read a new value for an `seriestracker--transient-variable-choice' OBJ."
  (let ((choices (oref obj choices)))
    (if-let* ((value (oref obj value))
              (notlast (cadr (member value choices))))
        (cadr (member value choices))
      (car choices))))

(cl-defmethod transient-infix-set ((obj seriestracker--transient-variable-choice) value)
  "Method to set VALUE for an `seriestracker--transient-variable-choice' OBJ."
  (oset obj value value)
  (set (oref obj variable) value)
  (funcall (oref obj action)))

(cl-defmethod transient-format-value ((obj seriestracker--transient-variable-choice))
  "Method to form the value of an `seriestracker--transient-variable-choice' OBJ."
  (let* ((choices  (oref obj choices))
         (value    (oref obj value)))
    (concat
     (propertize "[" 'face 'transient-inactive-value)
     (mapconcat (lambda (choice)
                  (propertize choice 'face (if (equal choice value)
                                               (if (member choice choices)
                                                   'transient-value
                                                 'font-lock-warning-face)
                                             'transient-inactive-value)))
                (if (and value (not (member value choices)))
                    (cons value choices)
                  choices)
                (propertize "|" 'face 'transient-inactive-value))
     (propertize "]" 'face 'transient-inactive-value))))

;;;;; Instances

;; Instances for save file (variable), display watched (show/hide), and sorting (alpha/next)

(transient-define-infix seriestracker--infix-savefile ()
  :class 'seriestracker--transient-variable
  :variable 'seriestracker-file
  :description "Save file")

(transient-define-infix seriestracker--infix-watched ()
  :class 'seriestracker--transient-variable-choice
  :choices '("show" "hide")
  :variable 'seriestracker-show-watched
  :description "Watched"
  :action 'seriestracker--apply-watched)

(defun seriestracker--apply-watched ()
  "Switch visibility for watched episodes."
  (if (-contains? buffer-invisibility-spec 'seriestracker-watched)
      (when (string-equal seriestracker-show-watched "show") (remove-from-invisibility-spec 'seriestracker-watched))
    (when (string-equal seriestracker-show-watched "hide")
      (add-to-invisibility-spec 'seriestracker-watched)
      (when (invisible-p (point)) (seriestracker-next)))))

(transient-define-infix seriestracker--infix-sorting ()
  :class 'seriestracker--transient-variable-choice
  :choices '("alpha" "next")
  :variable 'seriestracker-sorting-type
  :description "Sorting"
  :action 'seriestracker--apply-sort)

(defun seriestracker--apply-sort ()
  "Apply the selected sorting strategy and refresh the buffer."
  (cond ((string-equal seriestracker-sorting-type "alpha") (seriestracker-sort-alpha))
        ((string-equal seriestracker-sorting-type "next") (seriestracker-sort-next)))
  (seriestracker--refresh))

;;;; Toggle displaying watched

(defun seriestracker-toggle-display-watched ()
  "Toggle displaying watched episodes."
  (interactive)
  (seriestracker--inbuffer)
  (if (string-equal seriestracker-show-watched "show")
      (setq seriestracker-show-watched "hide")
    (setq seriestracker-show-watched "show"))
  (seriestracker--apply-watched))

;;;; Load/save data

;; Interactive functions to load and save, simply call the corresponding functions in the API

(defun seriestracker-save ()
  "Save the database."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--save))

(defun seriestracker-load ()
  "Load the database and refresh the buffer."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--load)
  (seriestracker--refresh))

;;;; Quit

;; Quit is saving, wiping data and killing the window

(defun seriestracker-quit ()
  "Save the db and close the buffer."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--save)
  (setq seriestracker--data nil)
  (kill-buffer-and-window))

;;;; Add series

;; To add series:
;; - prompt for a search term
;; - call the episodate API
;; - prompt with completion for a series to add
;; - add the series and sort

(defun seriestracker-search ()
  "Search for a series, and add the selected series to the database.
The searchterm is read from the minibuffer.
The selected sorting strategy is applied after adding the new series."
  (interactive)
  (seriestracker--inbuffer)
  (let* ((searchterm (read-from-minibuffer "Search: "))
         (series-list (seriestracker--search searchterm))
         (names-list (seriestracker--utils-array-pull 'permalink series-list))
         (nametoadd (completing-read "Options: " names-list))
         (toadd (alist-get 'id (--find
                                (string-equal nametoadd (alist-get 'permalink it))
                                series-list))))
    (seriestracker--add toadd)
    (seriestracker--apply-sort)
    (seriestracker-move-to toadd)))

;;;; Remove series

;; Get the series id and name at point
;; remove the series
;; delete the region in the buffer
;; move to the next series

(defun seriestracker-remove ()
  "Remove series at point."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--with-episode ((inhibit-read-only t)
                                (name (alist-get 'name series))
                                (start (previous-single-property-change (1+ (point)) 'seriestracker-series nil (point-min)))
                                (end (next-single-property-change (point) 'seriestracker-series nil (point-max))))
                               (when (y-or-n-p (concat "Are you sure you want to delete " name "? "))
                                 (seriestracker--remove id)
                                 (delete-region start end)
                                 (seriestracker--move 'next))))

;;;; (un)Watch episodes

;;;;; Update appearance watched region

;; Update all the watched lines in the updated region

(defun seriestracker--update-watched-region (start end)
  "Update the buffer for change in WATCH between START and END."
  (let* ((startline (line-number-at-pos start))
         (endline (1- (line-number-at-pos end))))
    (save-excursion
      (--each
          (number-sequence startline endline)
        (seriestracker--update-watched-line it)))))

;; Update a line:
;; - update all the faces combinations for text and date
;; - update watched face
;; - compute if series or season all watched

(defun seriestracker--update-watched-line (linum)
  "Update a single line LINUM for WATCH status."
  (goto-char (point-min))
  (forward-line (1- linum))
  (seriestracker--with-episode ((onseries (not seasonN))
                                (note (if onseries
                                          (alist-get 'note series)
                                        (alist-get 'note episode)))
                                (airdate (when episodeN (date-to-time (alist-get 'air_date episode))))
                                (watch (when episodeN (alist-get 'watched episode)))
                                (start (progn (move-beginning-of-line nil) (point)))
                                (end (progn (forward-line 1) (point)))
                                (released (when episodeN (time-less-p airdate (current-time))))
                                (seriestracker-date-face `(:inherit ,(cond (watch 'seriestracker-watched)
                                                                           (released 'success)
                                                                           (t 'error))
                                                                    :weight ,note))
                                (seriestracker-text-face `(:inherit ,(if watch
                                                                         'seriestracker-watched
                                                                       'default)
                                                                    :weight ,note)))
                               (cond ((and episodeN released)
                                      (if watch
                                          (put-text-property start end 'invisible 'seriestracker-watched)
                                        (put-text-property start end 'invisible nil))
                                      (put-text-property start end 'face seriestracker-text-face)
                                      (put-text-property start (+ start 19) 'face seriestracker-date-face))
                                     (seasonN
                                      (if (--all? (alist-get 'watched it)
                                                  (->> seriestracker--data
                                                       (--find (= id (alist-get 'id it)))
                                                       (alist-get 'episodes)
                                                       (--filter (= seasonN (alist-get 'season it)))))
                                          (put-text-property start end 'invisible 'seriestracker-watched)
                                        (put-text-property start end 'invisible nil)))
                                     (id
                                      (if (--all? (alist-get 'watched it)
                                                  (alist-get 'episodes (--find (= id (alist-get 'id it))
                                                                               seriestracker--data)))
                                          (put-text-property start end 'invisible 'seriestracker-watched)
                                        (put-text-property start end 'invisible nil))))))

;;;;; Toggle watch

;; (un)watch a region

(defun seriestracker-toggle-watch ()
  "Toggle watch at point.
The element under the cursor is used to decide whether to watch or unwatch."
  (interactive)
  (seriestracker--inbuffer)
  (let* ((pos (if (region-active-p) (region-beginning) (point)))
         (watched (get-char-property-and-overlay pos 'invisible))
         (watch (not (-contains? watched 'seriestracker-watched))))
    (seriestracker-watch watch)))

;;;;; Dispatch (un)watch

;; Dispatch (un)watch by setting start and end for watch-region

(defun seriestracker-watch (watch)
  "WATCH at point."
  (seriestracker--with-episode ((inhibit-read-only t))
                               (cond ((region-active-p) (seriestracker-watch-region (region-beginning)
                                                                                    (region-end)
                                                                                    watch))
                                     (episodeN (seriestracker-watch-region (previous-single-property-change (1+ (point)) 'seriestracker-episode nil (point-min))
                                                                           (next-single-property-change (point) 'seriestracker-episode nil (point-max))
                                                                           watch))
                                     (seasonN (let ((start (next-single-property-change (1+ (point)) 'seriestracker-episode nil (point-max))))
                                                (seriestracker-watch-region start
                                                                            (next-single-property-change start 'seriestracker-season nil (point-max))
                                                                            watch)))
                                     (t (let ((start (next-single-property-change (1+ (point)) 'seriestracker-episode nil (point-max))))
                                          (seriestracker-watch-region start
                                                                      (next-single-property-change start 'seriestracker-series nil (point-max))
                                                                      watch))))
                               (forward-line)))

;;;;; Region

;; Watch a region from start to end:
;; - watch with the API
;; - update the corresponding buffer region

(defun seriestracker-watch-region (start end &optional watch)
  "WATCH region from START to END positions in the buffer."
  (let ((start-series (get-text-property start 'seriestracker-series))
        (start-season (get-text-property start 'seriestracker-season))
        (start-episode (get-text-property start 'seriestracker-episode))
        (end-series (get-text-property end 'seriestracker-series))
        (end-season (get-text-property end 'seriestracker-season))
        (end-episode (get-text-property end 'seriestracker-episode)))
    (seriestracker--watch-region start-series start-season start-episode end-series end-season end-episode watch)
    (seriestracker--update-watched-region (previous-single-property-change (1+ start) 'seriestracker-series nil (point-min))
                                          (next-single-property-change end 'seriestracker-series nil (point-max)))))

;;;;; Up

;; Special case of watching : watch the whole series up to the episode at point

(defun seriestracker-watch-up ()
  "Watch up to episode at point."
  (interactive)
  (seriestracker--inbuffer)
  (let* ((inhibit-read-only t)
         (start-series (previous-single-property-change (1+ (point)) 'seriestracker-series nil (point-min)))
         (start-season (next-single-property-change start-series 'seriestracker-season nil (point-max)))
         (start (next-single-property-change start-season 'seriestracker-episode nil (point-max)))
         (end (next-single-property-change (1+ (point)) 'seriestracker-episode nil (point-max))))
    (seriestracker-watch-region start end t)))

;;;; Notes

;; Read a note from the minibuffer and add it to the episode at point
;; If the note is empty, remove the note
;; Update the buffer by changing the text properties of the line

(defun seriestracker-add-note ()
  "Add a note on the episode at point."
  (interactive)
  (seriestracker--inbuffer)
  (unless (or (not (get-text-property (point) 'seriestracker-season))
              (get-text-property (point) 'seriestracker-episode))
    (error "Cannot put a note on a season"))
  (seriestracker--with-episode ((onseries (not seasonN))
                                (watch (unless onseries (alist-get 'watched episode)))
                                (airdate (unless onseries (date-to-time (alist-get 'air_date episode))))
                                (start (progn (move-beginning-of-line nil) (point)))
                                (end (progn (forward-line 1) (point)))
                                (note (read-from-minibuffer "Note: " (if onseries
                                                                         (alist-get 'note series)
                                                                       (alist-get 'note episode))))
                                (note (if (string-equal "" note) nil note))
                                (seriestracker-date-face `(:inherit ,(cond (watch 'seriestracker-watched)
                                                                           ((time-less-p airdate (current-time)) 'success)
                                                                           (t 'error))
                                                                    :weight ,(if note 'bold 'normal)))
                                (seriestracker-text-face `(:inherit ,(if watch
                                                                         'seriestracker-watched
                                                                       'default)
                                                                    :weight ,(if note 'bold 'normal)))
                                (inhibit-read-only t))
                               (if onseries
                                   (progn (setf (alist-get 'note series nil t) note)
                                          (setq seriestracker--data (--map-when (= id (alist-get 'id it))
                                                                                series
                                                                                seriestracker--data))
                                          (put-text-property start end 'face `(:inherit ,(if (string-equal "Ended" (alist-get 'status series))
                                                                                             'seriestracker-finished-series
                                                                                           'seriestracker-series)
                                                                                        :weight ,(when note 'normal)))
                                          (put-text-property start end 'help-echo note))
                                 (setf (alist-get 'note episode nil t) note)
                                 (--each seriestracker--data
                                   (when (= id (alist-get 'id it))
                                     (setf (alist-get 'episodes it)
                                           (--map-when (and (= seasonN (alist-get 'season it))
                                                            (= episodeN (alist-get 'episode it)))
                                                       episode
                                                       (alist-get 'episodes it)))))
                                 (put-text-property start end 'face seriestracker-text-face)
                                 (put-text-property start (+ start 19) 'face seriestracker-date-face)
                                 (put-text-property start end 'help-echo note))))

;; Display the note at point, if existing, in the minibuffer

(defun seriestracker--display-note ()
  "Display the note at point, if existing, in the minibuffer."
  (seriestracker--with-episode ((onseries (not seasonN)))
                               (message (if onseries
                                            (alist-get 'note series)
                                          (alist-get 'note episode)))))

;;;; Sort series

;;;;; By next airing date

;; Helper to get the date of the first next episode to air in a series
;; Get all dates of unwatched episodes (if there is at all)
;; Convert to time and get the minimum value

(defun seriestracker--first-next-date (series)
  "Helper function to find the date for the next episode in SERIES."
  (let ((dates (->> series
                    (alist-get 'episodes)
                    (--filter (not (alist-get 'watched it))))))
    (if dates
        (->> dates
             (seriestracker--utils-array-pull 'air_date)
             (--map (car (date-to-time it)))
             -min)
      0)))

;; Compare two series by their first next airing date

(defun seriestracker--comp-date (a b)
  "Helper function to compare dates A and B."
  (< (seriestracker--first-next-date a)
     (seriestracker--first-next-date b)))

;; Sort series by first next airing date

(defun seriestracker-sort-next ()
  "Sort series by date of next episode to watch."
  (interactive)
  (seriestracker--inbuffer)
  (setq seriestracker--data (-sort #'seriestracker--comp-date seriestracker--data)))

;;;;; By name

;; Compare two series by their name

(defun seriestracker--comp-name (a b)
  "Helper function to compare names A and B."
  (string< (alist-get 'name a)
           (alist-get 'name b)))

;; Sort series by name

(defun seriestracker-sort-alpha ()
  "Sort alphabetically."
  (interactive)
  (seriestracker--inbuffer)
  (setq seriestracker--data (-sort #'seriestracker--comp-name seriestracker--data)))

;;;; Update

;; Update the db and refresh the buffer

(defun seriestracker-update ()
  "Update the db and refresh the buffer."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--update)
  (seriestracker--apply-sort))

;;;; Keymap

;; Define the keymap used by the mode. Use outline-like controls

(defvar seriestracker-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "p" 'seriestracker-prev-line)
    (define-key map "n" 'seriestracker-next-line)
    (define-key map "C-p" 'seriestracker-prev)
    (define-key map "C-n" 'seriestracker-next)
    (define-key map "C-u" 'seriestracker-up)
    (define-key map "C-b" 'seriestracker-prev-same)
    (define-key map "C-f" 'seriestracker-next-same)
    (define-key map "C-d" 'seriestracker-fold-at-point)
    (define-key map "C-e" 'seriestracker-unfold-at-point)
    (define-key map "h" 'seriestracker-dispatch)
    (define-key map "U" 'seriestracker-update)
    (define-key map "A" 'seriestracker-search)
    (define-key map "w" 'seriestracker-toggle-watch)
    (define-key map "u" 'seriestracker-watch-up)
    (define-key map "W" 'seriestracker-toggle-display-watched)
    (define-key map "N" 'seriestracker-add-note)
    (define-key map "q" 'seriestracker-quit)
    (define-key map [tab] 'seriestracker-cycle)
    map)
  "Keymap for series tracker mode.")

;;;; Mode

;; Define the mode as derived from special-mode

(define-derived-mode seriestracker-mode special-mode "seriestracker"
  "Series tracking with episodate.com."
  (setq-local buffer-invisibility-spec '(t seriestracker-series seriestracker-season))
  (setq-local max-lisp-eval-depth 10000)
  (use-local-map seriestracker-mode-map))

;;; Autoload

;; Autoload to expose (seriestracker), the entry point, after loading the package

;;;###autoload
(defun seriestracker ()
  "Run seriestracker."
  (interactive)
  (switch-to-buffer "seriestracker")
  (seriestracker-mode)
  (unless seriestracker-file (setq seriestracker-file (concat user-emacs-directory "seriestracker.el")))
  (seriestracker--load)
  (seriestracker--update)
  (seriestracker--refresh)
  (seriestracker--apply-watched)
  (goto-char 1)
  (seriestracker-next-line)
  (seriestracker-prev-line))

(provide 'seriestracker)

;;; seriestracker.el ends here
