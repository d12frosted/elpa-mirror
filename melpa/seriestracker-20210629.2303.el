;;; seriestracker.el --- Series tracker -*- lexical-binding: t; -*-

;; Copyright 2021 Maxime Wack

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
;; Version: 1.2.0
;; Package-Version: 20210629.2303
;; Package-Commit: a5ce1bfd06ed90bba9947a9045659d13f3362a96
;; Package-Requires: ((dash "2.12.1") (transient "0.3.2") (emacs "26.1"))
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

(require 'url)                                                                  ; used to fetch api data
(require 'json)                                                                 ; used to parse api response
(require 'dash)                                                                 ; threading etc.
(require 'transient)                                                            ; transient for command dispatch

;;; Helpers

;;;; alist-select

(defun seriestracker--utils-alist-select (fields alist)
  "Keep only FIELDS in ALIST.
This is done by constructing a new alist containing only these elements.
alist-select '(a c) '((a .1) (b , \"b\") (c . c)
returns '((a . 1) (c . c))"
  (->> fields
    reverse
    (--reduce-from (cons (cons it (alist-get it alist)) acc) nil)))

;;;; array-select

(defun seriestracker--utils-array-select (fields array)
  "Keep only FIELDS in every alist in the ARRAY.
array-select '(a c) '(((a . 1) (b . 2) (c . c)) ((a . 3) (b . 5) (c . d)))
returns '(((a . 1) (c . c)) ((a . 3) (c . d)))"
  (--map (seriestracker--utils-alist-select fields it) array))

;;;; array-pull

(defun seriestracker--utils-array-pull (field array)
  "Keep only FIELD in every alist in the ARRAY and flatten.
array-pull 'a '(((a . 1) (b . 2)) ((a . 3) (b . 4)))
returns '(1 3)"
  (--map (alist-get field it) array))

;;;; getJSON

(defun seriestracker--getJSON (url-buffer)
  "Parse the JSON in the URL-BUFFER returned by url."
  (with-current-buffer url-buffer
    (goto-char (point-max))
    (move-beginning-of-line 1)
    (json-read-object)))

;;;; seriestracker--each-when

(defmacro seriestracker--each-when (list cond &rest body)
  "`--each', but apply a COND to the LIST before executing BODY."
  `(--each ,list
     (when ,cond ,@body)))

;;; episodate.com API

;;;; search

(defun seriestracker--search (name)
  "Search episodate.com db for NAME."
  (->> (let ((url-request-method "GET"))
         (url-retrieve-synchronously (concat "https://www.episodate.com/api/search?q=" name)))
    seriestracker--getJSON
    (seriestracker--utils-alist-select '(tv_shows))
    cdar
    (seriestracker--utils-array-select '(id name start_date status network permalink))))

;;;; series

(defun seriestracker--episodes (series)
  "Transform the episodes of SERIES from a vector to a list."
  (setf (alist-get 'episodes series)
        (--map it (alist-get 'episodes series)))
  series)

(defun seriestracker--series (id)
  "Get series ID info."
  (->> (let ((url-request-method "GET"))
         (url-retrieve-synchronously (concat "https://www.episodate.com/api/show-details?q=" (int-to-string id))))
    seriestracker--getJSON
    car
    (seriestracker--utils-alist-select '(id name start_date status episodes))
    seriestracker--episodes))

;;; Internal API

;;;; Data model

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

(defun seriestracker--add (id)
  "Add series with ID to `seriestracker--data'.
Adding an already existing series resets it."
  (setq seriestracker--data
        (--> seriestracker--data
          (--remove (= id (alist-get 'id it)) it)
          (-snoc it (seriestracker--series id)))))

;;;;; Remove series

(defun seriestracker--remove (id)
  "Remove series with ID from `seriestracker--data'."
  (setq seriestracker--data
        (--remove (= id (alist-get 'id it)) seriestracker--data)))

;;;; Watch

;;;;; Watch region

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
                    (setf (alist-get 'watched it) watch)
                    it)
                  (alist-get 'episodes it)))))))

;;;;; Watch season

(defun seriestracker--watch-season (id seasonN watch)
  "WATCH all episodes in SEASONN of series ID."
  (seriestracker--watch-region id seasonN 1 id (1+ seasonN) 0 watch))

;;;;; Watch series

(defun seriestracker--watch-series (id watch)
  "WATCH all episodes in series ID."
  (seriestracker--each-when
   seriestracker--data
   (= id (alist-get 'id it))
   (--each
       (alist-get 'episodes it)
     (setf (alist-get 'watched it) watch))))

;;;; Notes

;;;;; Add note

(defun seriestracker--add-note (id seasonN episodeN note)
  "Add a NOTE to EPISODEN of SEASONN in series ID."
  (when episodeN
    (->> seriestracker--data
      (--map-when (= id (alist-get 'id it))
                  (setf (alist-get 'episodes it)
                        (--map-when (and (= seasonN (alist-get 'season it))
                                         (= episodeN (alist-get 'episode it)))
                                    (progn (setf (alist-get 'note it) note)
                                           it)
                                    (alist-get 'episodes it)))))))

;;;; Query updates

(defun seriestracker--update ()
  "Update all non-finished series."
  (seriestracker--each-when
   seriestracker--data
   (string-equal "Running" (alist-get 'status it))
   (seriestracker--update-series it)))

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
                                    (setf (alist-get 'note it) (alist-get it-index notes))
                                    it)))))
    (when (string-equal status "Ended") (setf (alist-get 'status series) "Ended"))
    (setf (alist-get 'episodes series) newEps)
    series))

;;;; Load/save data

(defvar seriestracker-file (concat user-emacs-directory "seriestracker.el")
  "Location of the save file.")

(defun seriestracker--save ()
  "Save the database to `seriestracker-file'."
  (with-temp-file seriestracker-file
    (let ((print-level nil)
          (print-length nil))
      (prin1 seriestracker--data (current-buffer)))))

(defun seriestracker--load ()
  "Load the database from `seriestracker-file'."
  (with-temp-buffer
    (insert-file-contents seriestracker-file t)
    (cl-assert (bobp))
    (setq seriestracker--data (read (current-buffer)))))

;;; Interface

;;;; Faces

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

(defun seriestracker--inbuffer ()
  "Check if we are in the seriestracker buffer in seriestracker mode."
  (unless (and (string-equal (buffer-name) "seriestracker")
               (string-equal mode-name "seriestracker"))
    (error "Not in seriestracker buffer")))

;;;; Draw buffer

(defvar seriestracker--fold-cycle 'seriestracker-all-folded
  "Current folding status.
Can be 'seriestracker-all-folded, 'seriestracker-series-folded, or 'seriestracker-all-unfolded")

(defun seriestracker--refresh ()
  "Refresh the seriestracker buffer."
  (let ((linum (line-number-at-pos)))
    (seriestracker--draw-buffer)
    (goto-char (point-min))
    (forward-line (1- linum)))
  (cond ((eq seriestracker--fold-cycle 'seriestracker-all-folded)
         (seriestracker--fold-all))
        ((eq seriestracker--fold-cycle 'seriestracker-all-unfolded)
         (seriestracker--unfold-all))
        ((eq seriestracker--fold-cycle 'seriestracker-series-folded)
         (seriestracker--unfold-all-series))))

(defun seriestracker--draw-buffer ()
  "Draw the buffer.
Erase first then redraw the whole buffer."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (-each seriestracker--data 'seriestracker--draw-series)))

(defun seriestracker--draw-series (series)
  "Print the SERIES id and name."
  (let* ((id (alist-get 'id series))
         (name (alist-get 'name series))
         (episodes (alist-get 'episodes series))
         (seriestracker-face (if (string-equal "Ended" (alist-get 'status series))
                                 'seriestracker-finished-series
                               'seriestracker-series))
         (seriestracker-watched (if (--all? (alist-get 'watched it)
                                            episodes)
                                    'seriestracker-watched
                                  nil)))
    (insert (propertize (concat name "\n")
                        'seriestracker-series id
                        'seriestracker-season nil
                        'seriestracker-episode nil
                        'face seriestracker-face
                        'invisible seriestracker-watched))
    (--each episodes (seriestracker--draw-episode series it))))

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
         (seriestracker-date-face `(:inherit ,(if watched
                                                  'seriestracker-watched
                                                (if (time-less-p (date-to-time air_date) (current-time))
                                                    'success
                                                  'error))
                                             :weight ,(if note 'bold 'normal)))
         (seriestracker-text-face `(:inherit ,(if watched
                                                  'seriestracker-watched
                                                'default)
                                             :weight ,(if note 'bold 'normal)))
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

(defun seriestracker-prev-line ()
  "Move one visible line up."
  (interactive)
  (seriestracker--inbuffer)
  (setq disable-point-adjustment t)
  (forward-line -1)
  (while (and (invisible-p (point))
              (> (point) 1))
    (forward-line -1))
  (when (and (= 1 (point))
             (invisible-p 1))
    (seriestracker--move 'next))
  (seriestracker--display-note))

(defun seriestracker-next-line ()
  "Move one visible line down."
  (interactive)
  (seriestracker--inbuffer)
  (line-move 1)
  (seriestracker--display-note))

(defun seriestracker-up ()
  "Move up in the hierarchy."
  (interactive)
  (seriestracker--inbuffer)
  (let ((season (get-text-property (point) 'seriestracker-season))
        (episode (get-text-property (point) 'seriestracker-episode)))
    (cond (episode (goto-char (previous-single-property-change (point) 'seriestracker-season)))
          (season (goto-char (previous-single-property-change (point) 'seriestracker-series))))))

(defun seriestracker--move (dir &optional same any)
  "Move in direction DIR in the hierarchy.
Use SAME to navigate between same-level headers,
and ANY to go to any header even if hidden."
  (seriestracker--inbuffer)
  (setq disable-point-adjustment t)
  (let* ((season (get-text-property (point) 'seriestracker-season))
         (episode (get-text-property (point) 'seriestracker-episode))
         (level (if (and same (not (or season episode))) 'seriestracker-series 'seriestracker-season))
         (dest (if (eq dir 'prev)
                   (previous-single-property-change (point) level nil (point-min))
                 (next-single-property-change (point) level nil (point-max)))))
    (goto-char dest))
  (when (eq dir 'prev)
    (when (and (= 1 (point))
               (invisible-p 1))
      (seriestracker--move 'next)))
  (unless any
    (when (invisible-p (point)) (seriestracker--move dir same))))

(defun seriestracker-prev ()
  "Move to the previous visible node."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--move 'prev))

(defun seriestracker-next ()
  "Move to the next visible node."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--move 'next))

(defun seriestracker-prev-same ()
  "Move to the previous visible node of the same level."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--move 'prev t))

(defun seriestracker-next-same ()
  "Move to the next visible node of the same level."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--move 'next t))

;;;; Folding

(defun seriestracker-fold-at-point (&optional unfold)
  "Fold or UNFOLD the section at point."
  (interactive)
  (seriestracker--inbuffer)
  (let ((season (get-text-property (point) 'seriestracker-season))
        (episode (get-text-property (point) 'seriestracker-episode)))
    (cond (episode (seriestracker--fold-episodes unfold))
          (season (seriestracker--fold-season unfold))
          (t (seriestracker--fold-series unfold)))))

(defun seriestracker-unfold-at-point ()
  "Unfold the section at point."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker-fold-at-point t))

(defun seriestracker--fold-episodes (&optional unfold)
  "Fold or UNFOLD the episodes at point."
  (let* ((season-start (previous-single-property-change (point) 'seriestracker-season))
         (fold-start (next-single-property-change season-start 'seriestracker-episode))
         (fold-end (next-single-property-change (point) 'seriestracker-season nil (point-max))))
    (if unfold
        (remove-overlays fold-start fold-end 'invisible 'seriestracker-season)
      (overlay-put (make-overlay fold-start fold-end) 'invisible 'seriestracker-season))))

(defun seriestracker--fold-season (&optional unfold)
  "Fold or UNFOLD the season at point."
  (let* ((fold-start (next-single-property-change (point) 'seriestracker-episode))
         (fold-end (next-single-property-change (point) 'seriestracker-season nil (point-max))))
    (if unfold
        (remove-overlays fold-start fold-end 'invisible 'seriestracker-season)
      (overlay-put (make-overlay fold-start fold-end) 'invisible 'seriestracker-season))))

(defun seriestracker--fold-series (&optional unfold)
  "Fold or UNFOLD the series at point."
  (let* ((fold-start (next-single-property-change (point) 'seriestracker-season))
         (fold-end (next-single-property-change (point) 'seriestracker-series nil (point-max))))
    (if unfold
        (remove-overlays fold-start fold-end 'invisible 'seriestracker-series)
      (when (and fold-start fold-end)
        (overlay-put (make-overlay fold-start fold-end) 'invisible 'seriestracker-series)))))

;;;; Cycle folding

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

(defun seriestracker--unfold-all ()
  "Unfold everything."
  (remove-overlays (point-min) (point-max) 'invisible 'seriestracker-series)
  (remove-overlays (point-min) (point-max) 'invisible 'seriestracker-season))

(defun seriestracker--fold-all ()
  "Fold everything."
  (save-excursion
    (seriestracker--unfold-all)
    (goto-char 1)
    (while (not (eobp))
      (seriestracker-fold-at-point)
      (seriestracker--move 'next nil t))))

(defun seriestracker--unfold-all-series ()
  "Unfold all series."
  (seriestracker--fold-all)
  (remove-overlays (point-min) (point-max) 'invisible 'seriestracker-series))

;;;; Transient

(defvar seriestracker-show-watched "hide"
  "Current strategy for dealing with watched episodes.")

(defvar seriestracker-sorting-type "next"
  "Current strategy for sorting series.")

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

(defclass seriestracker--transient-variable (transient-variable)
  ((variable :initarg :variable)))

(defclass seriestracker--transient-variable-choice (seriestracker--transient-variable)
  ((name :initarg :name)
   (choices :initarg :choices)
   (default :initarg :default)
   (action :initarg :action)))

(cl-defmethod transient-init-value ((obj seriestracker--transient-variable))
  "Method to initialise the value of an `seriestracker--transient-variable' OBJ."
  (oset obj value (eval (oref obj variable))))

(cl-defmethod transient-infix-read ((obj seriestracker--transient-variable))
  "Method to read a new value for an `seriestracker--transient-variable' OBJ."
  (read-from-minibuffer "Save file: " (oref obj value)))

(cl-defmethod transient-infix-read ((obj seriestracker--transient-variable-choice))
  "Method to read a new value for an `seriestracker--transient-variable-choice' OBJ."
  (let ((choices (oref obj choices)))
    (if-let* ((value (oref obj value))
              (notlast (cadr (member value choices))))
        (cadr (member value choices))
      (car choices))))

(cl-defmethod transient-infix-set ((obj seriestracker--transient-variable) value)
  "Method to set VALUE for an `seriestracker--transient-variable' OBJ."
  (oset obj value value)
  (set (oref obj variable) value))

(cl-defmethod transient-infix-set ((obj seriestracker--transient-variable-choice) value)
  "Method to set VALUE for an `seriestracker--transient-variable-choice' OBJ."
  (oset obj value value)
  (set (oref obj variable) value)
  (funcall (oref obj action)))

(cl-defmethod transient-format-value ((obj seriestracker--transient-variable))
  "Method to format the value of an `seriestracker--transient-variable' OBJ."
  (let ((value (oref obj value)))
    (concat
     (propertize "(" 'face 'transient-inactive-value)
     (propertize value 'face 'transient-value)
     (propertize ")" 'face 'transient-inactive-value))))

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

(transient-define-infix seriestracker--infix-savefile ()
  :class 'seriestracker--transient-variable
  :variable 'seriestracker-file
  :description "Save file")

;;;; Toggle displaying watched

(defun seriestracker-toggle-display-watched ()
  "Toggle displaying watched episodes."
  (interactive)
  (seriestracker--inbuffer)
  (if (string-equal seriestracker-show-watched "show")
      (progn (setq seriestracker-show-watched "hide")
             (add-to-invisibility-spec 'seriestracker-watched))
    (setq seriestracker-show-watched "show")
    (remove-from-invisibility-spec 'seriestracker-watched)))

;;;; Load/save data

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

(defun seriestracker-quit ()
  "Save the db and close the buffer."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--save)
  (setq seriestracker--data nil)
  (kill-buffer-and-window))

;;;; Add series

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
    (seriestracker--apply-sort)))

;;;; Remove series

(defun seriestracker-remove ()
  "Remove series at point."
  (interactive)
  (seriestracker--inbuffer)
  (let ((inhibit-read-only t)
        (series (get-text-property (point) 'seriestracker-series))
        (start (previous-single-property-change (1+ (point)) 'seriestracker-series nil (point-min)))
        (end (next-single-property-change (point) 'seriestracker-series nil (point-max))))
    (when (y-or-n-p "Are you sure you want to delete this series? ")
      (seriestracker--remove series)
      (delete-region start end))))

;;;; (un)Watch episodes

;;;;; Update appearance watched region

(defun seriestracker--update-watched-region (start end &optional watch)
  "Update the buffer for change in WATCH between START and END."
  (let* ((startline (line-number-at-pos start))
         (endline (1- (line-number-at-pos end))))
    (save-excursion
      (--each
          (number-sequence startline endline)
        (seriestracker--update-watched-line it watch)))))

(defun seriestracker--update-watched-line (linum watch)
  "Update a single line LINUM for WATCH status."
  (goto-char (point-min))
  (forward-line (1- linum))
  (let* ((episode (get-text-property (point) 'seriestracker-episode))
         (season (get-text-property (point) 'seriestracker-season))
         (series (get-text-property (point) 'seriestracker-series))
         (note (plist-get
                (get-text-property (point) 'face)
                :weight))
         (start (progn (move-beginning-of-line nil) (point)))
         (end (progn (forward-line 1) (point)))
         (seriestracker-date-face (when episode
                                    `(:inherit ,(if watch
                                                    'seriestracker-watched
                                                  (if (time-less-p (date-to-time (buffer-substring start (+ start 19))) (current-time))
                                                      'success
                                                    'error))
                                               :weight ,note)))
         (seriestracker-text-face `(:inherit ,(if watch
                                                  'seriestracker-watched
                                                'default)
                                             :weight ,note)))
    (cond (episode
           (if watch
               (put-text-property start end 'invisible 'seriestracker-watched)
             (put-text-property start end 'invisible nil))
           (put-text-property start end 'face seriestracker-text-face)
           (put-text-property start (+ start 19) 'face seriestracker-date-face))
          (season
           (if (--all? (alist-get 'watched it)
                       (->> seriestracker--data
                         (--find (= series (alist-get 'id it)))
                         (alist-get 'episodes)
                         (--filter (= season (alist-get 'season it)))))
               (put-text-property start end 'invisible 'seriestracker-watched)
             (put-text-property start end 'invisible nil)))
          (series
           (if (--all? (alist-get 'watched it)
                       (alist-get 'episodes (--find (= series (alist-get 'id it))
                                                    seriestracker--data)))
               (put-text-property start end 'invisible 'seriestracker-watched)
             (put-text-property start end 'invisible nil))))))

;;;;; Toggle watch

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

(defun seriestracker-watch (watch)
  "WATCH at point."
  (let ((inhibit-read-only t)
        (series (get-text-property (point) 'seriestracker-series))
        (season (get-text-property (point) 'seriestracker-season))
        (episode (get-text-property (point) 'seriestracker-episode)))
    (cond ((region-active-p) (seriestracker-watch-region (region-beginning) (region-end) watch))
          (episode (seriestracker-watch-episode watch))
          (season (seriestracker-watch-season series season watch))
          (t (seriestracker-watch-series series watch))))
  (forward-line))

;;;;; Region

(defun seriestracker-watch-region (start end &optional watch)
  "WATCH region from START to END positions in the buffer."
  (let ((start-series (get-text-property start 'seriestracker-series))
        (start-season (get-text-property start 'seriestracker-season))
        (start-episode (get-text-property start 'seriestracker-episode))
        (end-series (get-text-property end 'seriestracker-series))
        (end-season (get-text-property end 'seriestracker-season))
        (end-episode (get-text-property end 'seriestracker-episode)))
    (seriestracker--watch-region start-series start-season start-episode end-series end-season end-episode watch)
    (seriestracker--update-watched-region start end watch)))

;;;;; Episode

(defun seriestracker-watch-episode (watch)
  "WATCH the episode at point."
  (let ((start (previous-single-property-change (1+ (point)) 'seriestracker-episode))
        (end (next-single-property-change (point) 'seriestracker-episode nil (point-max))))
    (seriestracker-watch-region start end watch)))

;;;;; Season

(defun seriestracker-watch-season (id seasonN watch)
  "WATCH SEASONN of series ID."
  (let* ((start-season (previous-single-property-change (1+ (point)) 'seriestracker-season))
         (start (next-single-property-change (1+ (point)) 'seriestracker-episode nil (point-max)))
         (end (next-single-property-change start 'seriestracker-season nil (point-max))))
    (seriestracker--watch-season id seasonN watch)
    (seriestracker--update-watched-region start-season end watch)))

;;;;; Series

(defun seriestracker-watch-series (id watch)
  "WATCH all episodes in series ID."
  (let* ((start-series (previous-single-property-change (1+ (point)) 'seriestracker-series))
         (start (next-single-property-change (1+ (point)) 'seriestracker-episode nil (point-max)))
         (end (next-single-property-change start 'seriestracker-series nil (point-max))))
    (seriestracker--watch-series id watch)
    (seriestracker--update-watched-region start-series end watch)))

;;;;; Up

(defun seriestracker-watch-up ()
  "Watch up to episode at point."
  (interactive)
  (seriestracker--inbuffer)
  (let* ((inhibit-read-only t)
         (start-series (previous-single-property-change (1+ (point)) 'seriestracker-series))
         (start-season (next-single-property-change start-series 'seriestracker-season nil (point-max)))
         (start (next-single-property-change start-season 'seriestracker-episode nil (point-max)))
         (end (next-single-property-change (1+ (point)) 'seriestracker-episode nil (point-max))))
    (seriestracker-watch-region start end t)))

;;;; Notes

(defun seriestracker-add-note ()
  "Add a note on the episode at point."
  (interactive)
  (seriestracker--inbuffer)
  (unless (get-text-property (point) 'seriestracker-episode)
    (error "Cannot put a note on a series or season!"))
  (let* ((series (get-text-property (point) 'seriestracker-series))
         (season (get-text-property (point) 'seriestracker-season))
         (episode (get-text-property (point) 'seriestracker-episode))
         (watch (get-text-property (point) 'invisible))
         (start (progn (move-beginning-of-line nil) (point)))
         (end (progn (forward-line 1) (point)))
         (note (read-from-minibuffer "Note: "))
         (note (if (string-equal "" note) nil note))
         (seriestracker-date-face `(:inherit ,(if watch
                                                  'seriestracker-watched
                                                (if (time-less-p (date-to-time (buffer-substring start (+ start 19))) (current-time))
                                                    'success
                                                  'error))
                                             :weight ,(if note 'bold 'normal)))
         (seriestracker-text-face `(:inherit ,(if watch
                                                  'seriestracker-watched
                                                'default)
                                             :weight ,(if note 'bold 'normal)))
         (inhibit-read-only t))
    (seriestracker--add-note series season episode note)
    (put-text-property start end 'face seriestracker-text-face)
    (put-text-property start (+ start 19) 'face seriestracker-date-face)
    (put-text-property start end 'help-echo note)))

(defun seriestracker--display-note ()
  "Display the note at point, if existing, in the minibuffer."
  (let* ((series (get-text-property (point) 'seriestracker-series))
         (season (get-text-property (point) 'seriestracker-season))
         (episode (get-text-property (point) 'seriestracker-episode))
         (note (when episode
                 (->> seriestracker--data
                   (--find (= series (alist-get 'id it)))
                   (alist-get 'episodes)
                   (--find (and (= season (alist-get 'season it))
                                (= episode (alist-get 'episode it))))
                   (alist-get 'note)))))
    (and note (message note))))

;;;; Sort series

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

(defun seriestracker--comp-date (a b)
  "Helper function to compare dates A and B."
    (< (seriestracker--first-next-date a)
       (seriestracker--first-next-date b)))

(defun seriestracker-sort-next ()
  "Sort series by date of next episode to watch."
  (interactive)
  (seriestracker--inbuffer)
  (setq seriestracker--data (-sort #'seriestracker--comp-date seriestracker--data)))

(defun seriestracker--comp-name (a b)
  "Helper function to compare names A and B."
    (string< (alist-get 'name a)
             (alist-get 'name b)))

(defun seriestracker-sort-alpha ()
  "Sort alphabetically."
  (interactive)
  (seriestracker--inbuffer)
  (setq seriestracker--data (-sort #'seriestracker--comp-name seriestracker--data)))

;;;; Update

(defun seriestracker-update ()
  "Update the db and refresh the buffer."
  (interactive)
  (seriestracker--inbuffer)
  (seriestracker--update)
  (seriestracker--refresh))

;;;; Keymap

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

(define-derived-mode seriestracker-mode special-mode "seriestracker"
  "Series tracking with episodate.com."
  (setq-local buffer-invisibility-spec '(t seriestracker-series seriestracker-season))
  (setq-local max-lisp-eval-depth 10000)
  (use-local-map seriestracker-mode-map))

;;; Autoload

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
  (seriestracker--apply-watched))

(provide 'seriestracker)

;;; seriestracker.el ends here
