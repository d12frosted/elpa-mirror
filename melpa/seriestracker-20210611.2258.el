;;; seriesTracker.el --- Series tracker -*- lexical-binding: t; -*-

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
;; Version: 1.1
;; Package-Version: 20210611.2258
;; Package-Commit: 2a9203bac6f29315de865aa20dae7c492a37cd94
;; Package-Requires: ((dash "2.12.1") (transient "0.3.2") (emacs "26.1"))
;; Keywords: multimedia
;; URL: https://www.github.com/MaximeWack/seriesTracker

;;; Commentary:

;; seriesTracker implements a major mode (st) for tracking TV shows.
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

(defun st--utils-alist-select (fields alist)
  "Keep only FIELDS in ALIST.
This is done by constructing a new alist containing only these elements.

alist-select '(a c) '((a .1) (b , \"b\") (c . c)
returns '((a . 1) (c . c))"

  (->> fields
    reverse
    (--reduce-from (acons it (alist-get it alist) acc)
                   nil)))

;;;; array-select

(defun st--utils-array-select (fields array)
  "Keep only FIELDS in every alist in the ARRAY.

array-select '(a c) '(((a . 1) (b . 2) (c . c)) ((a . 3) (b . 5) (c . d)))
returns '(((a . 1) (c . c)) ((a . 3) (c . d)))"

  (--map (st--utils-alist-select fields it) array))

;;;; array-pull

(defun st--utils-array-pull (field array)
  "Keep only FIELD in every alist in the ARRAY and flatten.

array-pull 'a '(((a . 1) (b . 2)) ((a . 3) (b . 4)))
returns '(1 3)"

  (--map (alist-get field it) array))

;;;; getJSON

(defun st--getJSON (url-buffer)
  "Parse the JSON in the URL-BUFFER returned by url."

  (with-current-buffer url-buffer
    (goto-char (point-max))
    (move-beginning-of-line 1)
    (json-read-object)))

;;;; --each-when

(defmacro --each-when (list cond &rest body)
  "`--each', but apply a COND to the LIST before executing BODY."
  `(--each ,list
     (when ,cond ,@body)))

;;; episodate.com API

;;;; search

(defun st--search (name)
  "Search episodate.com db for NAME."

  (->> (let ((url-request-method "GET"))
         (url-retrieve-synchronously (concat "https://www.episodate.com/api/search?q=" name)))
    st--getJSON
    (st--utils-alist-select '(tv_shows))
    cdar
    (st--utils-array-select '(id name start_date status network permalink))))

;;;; series

(defun st--episodes (series)
  "Transform the episodes of SERIES from a vector to a list."

  (setf (alist-get 'episodes series)
        (--map it (alist-get 'episodes series)))
  series)

(defun st--series (id)
  "Get series ID info."

  (->> (let ((url-request-method "GET"))
         (url-retrieve-synchronously (concat "https://www.episodate.com/api/show-details?q=" (int-to-string id))))
    st--getJSON
    car
    (st--utils-alist-select '(id name start_date status episodes))
    st--episodes))

;;; Internal API

;;;; Data model

(defvar st--data nil
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

(defun st--add (id)
  "Add series with ID to `st--data'.
Adding an already existing series resets it."

  (setq st--data
        (--> st--data
          (--remove (= id (alist-get 'id it)) it)
          (-snoc it (st--series id)))))

;;;;; Remove series

(defun st--remove (id)
  "Remove series with ID from `st--data'."

  (setq st--data
        (--remove (= id (alist-get 'id it)) st--data)))

;;;; Watch

;;;;; Watch region

(defun st--watch-region (start-series start-season start-episode end-series end-season end-episode watch)
  "WATCH from START-EPISODE of START-SEASON of START-SERIES to END-EPISODE of END-SEASON of END-SERIES."

  (let* ((series1 (--find-index (= start-series (alist-get 'id it)) st--data))
         (series2 (if end-series
                      (--find-index (= end-series (alist-get 'id it)) st--data)
                    (1+ series1))))
    (--each
        st--data
      (setq series-index it-index)
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
             (alist-get 'episodes it))))))

;;;;; Watch season

(defun st--watch-season (id seasonN watch)
  "WATCH all episodes in SEASONN of series ID."

  (st--watch-region id seasonN 1 id (1+ seasonN) 0 watch))

;;;;; Watch series

(defun st--watch-series (id watch)
  "WATCH all episodes in series ID."

  (--each-when
   st--data
   (= id (alist-get 'id it))
   (--each
       (alist-get 'episodes it)
     (setf (alist-get 'watched it) watch))))

;;;; Query updates

(defun st--update ()
  "Update all non-finished series."

  (--each-when
   st--data
   (string-equal "Running" (alist-get 'status it))
   (st--update-series it)))

(defun st--update-series (series)
  "Update the SERIES."

  (let* ((new (st--series (alist-get 'id series)))
         (newEp (alist-get 'episodes new))
         (status (alist-get 'status new))
         (watched (--find-indices (alist-get 'watched it) (alist-get 'episodes series)))
         (newEps (--map-indexed (if (-contains? watched it-index)
                                    (progn
                                      (setf (alist-get 'watched it) t)
                                      it)
                                  it) newEp)))

    (when (string-equal status "Ended") (setf (alist-get 'status series) "Ended"))
    (setf (alist-get 'episodes series) newEps)

    series))

;;;; Load/save data

(defvar st--file (concat user-emacs-directory "st.el")
  "Location of the save file.")

(defun st--save ()
  "Save the database to `st--file'."

  (with-temp-file st--file
    (let ((print-level nil)
          (print-length nil))
      (prin1 st--data (current-buffer)))))

(defun st--load ()
  "Load the database from `st--file'."

  (with-temp-buffer
    (insert-file-contents st--file t)
    (cl-assert (eq (point) (point-min)))
    (setq st--data (read (current-buffer)))))

;;; Interface

;;;; Faces

(defface st-series
  '((t (:height 1.9 :weight bold :foreground "DeepSkyBlue")))
  "Face for series names"
  :group 'st-faces)

(defface st-finished-series
  '((t (:height 2.0 :weight bold :foreground "DimGrey")))
  "Face for finished series names"
  :group 'st-faces)

(defface st-season
  '((t (:height 1.7 :weight bold :foreground "MediumPurple")))
  "Face for seasons"
  :group 'st-faces)

(defface st-watched
  '((t (:foreground "DimGrey" :strike-through t)))
  "Face for watched episodes"
  :group 'st-faces)

;;;; Check in ST buffer

(defun st--inbuffer ()
  "Check if we are in the st buffer in st mode."

  (unless (and (string-equal (buffer-name) "st")
               (string-equal mode-name "st"))
    (error "Not in st buffer")))

;;;; Draw buffer

(defun st--refresh ()
  "Refresh the st buffer."

  (let ((linum (line-number-at-pos)))
    (st--draw-buffer)
    (goto-char (point-min))
    (forward-line (1- linum)))

  (cond ((eq st--fold-cycle 'st-all-folded)
         (st--fold-all))
        ((eq st--fold-cycle 'st-all-unfolded)
         (st--unfold-all))
        ((eq st--fold-cycle 'st-series-folded)
         (st--unfold-all-series))))

(defun st--draw-buffer ()
  "Draw the buffer.
Erase first then redraw the whole buffer."

  (let ((inhibit-read-only t))
    (erase-buffer)
    (-each st--data 'st--draw-series)))

(defun st--draw-series (series)
  "Print the SERIES id and name."

  (let* ((id (alist-get 'id series))
         (name (alist-get 'name series))
         (episodes (alist-get 'episodes series))
         (st-face (if (string-equal "Ended" (alist-get 'status series))
                      'st-finished-series
                    'st-series))
         (st-watched (if (--all? (alist-get 'watched it)
                                 episodes)
                         'st-watched
                       nil)))
    (insert (propertize (concat name "\n")
                        'st-series id
                        'st-season nil
                        'st-episode nil
                        'face st-face
                        'invisible st-watched))

    (--each episodes (st--draw-episode series it))))

(defun st--draw-episode (series episode)
  "Print EPISODE from SERIES.
Print the time stamp, then episode number, and episode name.
If first episode of a season, print the season number."

  (let* ((id (alist-get 'id series))
         (seasonN (alist-get 'season episode))
         (episodeN (alist-get 'episode episode))
         (name (alist-get 'name episode))
         (air_date (alist-get 'air_date episode))
         (watched (alist-get 'watched episode))
         (st-watched (if watched 'st-watched nil))
         (st-date-face (if (time-less-p (date-to-time air_date) (current-time))
                           '(t ((:foreground "MediumSpringGreen")))
                         '(t ((:foreground "firebrick")))))
         (start (point)))
    (when (= episodeN 1)
      (setq start (+ start 8 (length (int-to-string seasonN))))
      (let ((st-season-watched (if (--all? (alist-get 'watched it)
                                           (--filter (= seasonN (alist-get 'season it))
                                                     (alist-get 'episodes series)))
                                   'st-watched
                                 nil)))
        (insert (propertize (concat "Season " (int-to-string seasonN) "\n")
                            'face 'st-season
                            'st-series id
                            'st-season seasonN
                            'st-episode nil
                            'invisible st-season-watched))))
    (insert (propertize (concat air_date " " (format "%02d" episodeN) " - " name "\n")
                        'st-series id
                        'st-season seasonN
                        'st-episode episodeN
                        'invisible st-watched))
    (put-text-property start (+ start 19) 'face st-date-face)
    (when watched (put-text-property start (point) 'face 'st-watched))))

;;;; Movements

(defun st-prev-line ()
  "Move one visible line up."

  (interactive)

  (st--inbuffer)

  (setq disable-point-adjustment t)

  (forward-line -1)

  (while (and (invisible-p (point))
              (> (point) 1))
    (forward-line -1))

  (when (and (= 1 (point))
               (invisible-p 1))
      (st--move 'next)))

(defun st-up ()
  "Move up in the hierarchy."

  (interactive)

  (st--inbuffer)

  (let ((season (get-text-property (point) 'st-season))
        (episode (get-text-property (point) 'st-episode)))
    (cond (episode (goto-char (previous-single-property-change (point) 'st-season)))
          (season (goto-char (previous-single-property-change (point) 'st-series))))))

(defun st--move (dir &optional same any)
  "Move in direction DIR in the hierarchy.
Use SAME to navigate between same-level headers,
and ANY to go to any header even if hidden."

  (st--inbuffer)

  (setq disable-point-adjustment t)

  (let* ((season (get-text-property (point) 'st-season))
         (episode (get-text-property (point) 'st-episode))
         (level (if (and same (not (or season episode))) 'st-series 'st-season))
         (dest (if (eq dir 'prev)
                   (previous-single-property-change (point) level nil (point-min))
                 (next-single-property-change (point) level nil (point-max)))))
    (goto-char dest))

  (when (eq dir 'prev)
    (when (and (= 1 (point))
               (invisible-p 1))
      (st--move 'next)))

  (unless any
    (when (invisible-p (point)) (st--move dir same))))

(defun st-prev ()
  "Move to the previous visible node."

  (interactive)

  (st--inbuffer)

  (st--move 'prev))

(defun st-next ()
  "Move to the next visible node."

  (interactive)

  (st--inbuffer)

  (st--move 'next))

(defun st-prev-same ()
  "Move to the previous visible node of the same level."

  (interactive)

  (st--inbuffer)

  (st--move 'prev t))

(defun st-next-same ()
  "Move to the next visible node of the same level."

  (interactive)

  (st--inbuffer)

  (st--move 'next t))

;;;; Folding

(defun st-fold-at-point (&optional unfold)
  "Fold or UNFOLD the section at point."

  (interactive)

  (st--inbuffer)

  (let ((season (get-text-property (point) 'st-season))
        (episode (get-text-property (point) 'st-episode)))
    (cond (episode (st-fold-episodes unfold))
          (season (st-fold-season unfold))
          (t (st-fold-series unfold)))))

(defun st-unfold-at-point ()
  "Unfold the section at point."

  (interactive)

  (st--inbuffer)

  (st-fold-at-point t))

(defun st-fold-episodes (&optional unfold)
  "Fold or UNFOLD the episodes at point."

  (let* ((season-start (previous-single-property-change (point) 'st-season))
         (fold-start (next-single-property-change season-start 'st-episode))
         (fold-end (next-single-property-change (point) 'st-season nil (point-max))))

    (if unfold
        (remove-overlays fold-start fold-end 'invisible 'st-season)
      (overlay-put (make-overlay fold-start fold-end) 'invisible 'st-season))))

(defun st-fold-season (&optional unfold)
  "Fold or UNFOLD the season at point."

  (let* ((fold-start (next-single-property-change (point) 'st-episode))
         (fold-end (next-single-property-change (point) 'st-season nil (point-max))))

    (if unfold
        (remove-overlays fold-start fold-end 'invisible 'st-season)
      (overlay-put (make-overlay fold-start fold-end) 'invisible 'st-season))))

(defun st-fold-series (&optional unfold)
  "Fold or UNFOLD the series at point."

  (let* ((fold-start (next-single-property-change (point) 'st-season))
         (fold-end (next-single-property-change (point) 'st-series nil (point-max))))

    (if unfold
        (remove-overlays fold-start fold-end 'invisible 'st-series)
      (when (and fold-start fold-end)
        (overlay-put (make-overlay fold-start fold-end) 'invisible 'st-series)))))

;;;; Cycle folding

(defvar st--fold-cycle 'st-all-folded)

(defun st-cycle ()
  "Cycle folding."

  (interactive)

  (st--inbuffer)

  (cond ((eq st--fold-cycle 'st-all-folded)
         (st--unfold-all-series)
         (setq st--fold-cycle 'st-series-folded))
        ((eq st--fold-cycle 'st-series-folded)
         (st--unfold-all)
         (setq st--fold-cycle 'st-all-unfolded))
        ((eq st--fold-cycle 'st-all-unfolded)
         (st--fold-all)
         (setq st--fold-cycle 'st-all-folded))))

(defun st--unfold-all ()
  "Unfold everything."

  (remove-overlays (point-min) (point-max) 'invisible 'st-series)
  (remove-overlays (point-min) (point-max) 'invisible 'st-season))

(defun st--fold-all ()
  "Fold everything."

  (save-excursion
    (st--unfold-all)
    (goto-char 1)
    (while (< (point)
              (point-max))
      (st-fold-at-point)
      (st--move 'next nil t))))

(defun st--unfold-all-series ()
  "Unfold all series."

  (st--fold-all)
  (remove-overlays (point-min) (point-max) 'invisible 'st-series))

;;;; Transient

(defvar st-show-watched "hide")

(defvar st-sorting-type "next")

(transient-define-prefix st-dispatch ()
  "Command dispatch for st."

  ["Series"
   :if-mode st-mode
   [("A" "Search and add a series" st-search)
    ("D" "Delete a series" st-remove)]
   [("w" "Toggle watch at point" st-toggle-watch)
    ("u" "Watch up to point" st-watch-up)
    ] [("U" "Update and refresh the buffer" st-update)]]

  ["Display"
   :if-mode st-mode
   [("W" st-infix-watched)
    ("S" st-infix-sorting)]]

  ["Load/Save"
   :if-mode st-mode
   [("s" "Save database" st-save)
    ("l" "Load database" st-load)
    ("f" st-infix-savefile)]])

(defclass st-transient-variable (transient-variable)
  ((variable :initarg :variable)))

(defclass st-transient-variable:choice (st-transient-variable)
  ((name :initarg :name)
   (choices :initarg :choices)
   (default :initarg :default)
   (action :initarg :action)))

(cl-defmethod transient-init-value ((obj st-transient-variable))
  "Method to initialise the value of an `st-transient-variable' OBJ."

  (oset obj value (eval (oref obj variable))))

(cl-defmethod transient-infix-read ((obj st-transient-variable))
  "Method to read a new value for an `st-transient-variable' OBJ."

  (read-from-minibuffer "Save file: " (oref obj value)))

(cl-defmethod transient-infix-read ((obj st-transient-variable:choice))
  "Method to read a new value for an `st-transient-variable:choice' OBJ."

  (let ((choices (oref obj choices)))
    (if-let* ((value (oref obj value))
              (notlast (cadr (member value choices))))
        (cadr (member value choices))
      (car choices))))

(cl-defmethod transient-infix-set ((obj st-transient-variable) value)
  "Method to set VALUE for an `st-transient-variable' OBJ."

  (oset obj value value)
  (set (oref obj variable) value))

(cl-defmethod transient-infix-set ((obj st-transient-variable:choice) value)
  "Method to set VALUE for an `st-transient-variable:choice' OBJ."

  (oset obj value value)
  (set (oref obj variable) value)
  (funcall (oref obj action)))

(cl-defmethod transient-format-value ((obj st-transient-variable))
  "Method to format the value of an `st-transient-variable' OBJ."

  (let ((value (oref obj value)))
    (concat
     (propertize "(" 'face 'transient-inactive-value)
     (propertize value 'face 'transient-value)
     (propertize ")" 'face 'transient-inactive-value))))

(cl-defmethod transient-format-value ((obj st-transient-variable:choice))
  "Method to form the value of an `st-transient-variable:choice' OBJ."

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

(transient-define-infix st-infix-watched ()
  :class 'st-transient-variable:choice
  :choices '("show" "hide")
  :variable 'st-show-watched
  :description "Watched"
  :action 'st--apply-watched)

(defun st--apply-watched ()
  "Switch visibility for watched episodes."

  (if (-contains? buffer-invisibility-spec 'st-watched)
      (when (string-equal st-show-watched "show") (remove-from-invisibility-spec 'st-watched))
    (when (string-equal st-show-watched "hide")
      (add-to-invisibility-spec 'st-watched)
      (when (invisible-p (point)) (st-next)))))

(transient-define-infix st-infix-sorting ()
  :class 'st-transient-variable:choice
  :choices '("alpha" "next")
  :variable 'st-sorting-type
  :description "Sorting"
  :action 'st--apply-sort)

(defun st--apply-sort ()
  "Apply the selected sorting strategy and refresh the buffer."

  (cond ((string-equal st-sorting-type "alpha") (st-sort-alpha))
        ((string-equal st-sorting-type "next") (st-sort-next)))
  (st--refresh))

(transient-define-infix st-infix-savefile ()
  :class 'st-transient-variable
  :variable 'st--file
  :description "Save file")

;;;; Toggle displaying watched

(defun st-toggle-display-watched ()
  "Toggle displaying watched episodes."

  (interactive)

  (st--inbuffer)

  (if (string-equal st-show-watched "show")
      (progn (setq st-show-watched "hide")
             (add-to-invisibility-spec 'st-watched))
    (setq st-show-watched "show")
    (remove-from-invisibility-spec 'st-watched)))

;;;; Load/save data

(defun st-save ()
  "Save the database."

  (interactive)

  (st--inbuffer)

  (st--save))

(defun st-load ()
  "Load the database and refresh the buffer."

  (interactive)

  (st--inbuffer)

  (st--load)
  (st--refresh))

;;;; Quit

(defun st-quit ()
  "Save the db and close the buffer."

  (interactive)

  (st--inbuffer)

  (st--save)
  (setq st--data nil)

  (kill-buffer-and-window))

;;;; Add series

(defun st-search ()
  "Search for a series, and add the selected series to the database.
The searchterm is read from the minibuffer.
The selected sorting strategy is applied after adding the new series."

  (interactive)

  (st--inbuffer)

  (let* ((searchterm (read-from-minibuffer "Search: "))
         (series-list (st--search searchterm))
         (names-list (st--utils-array-pull 'permalink series-list))
         (nametoadd (completing-read "Options: " names-list))
         (toadd (alist-get 'id (--find
                                (string-equal nametoadd (alist-get 'permalink it))
                                series-list))))
    (st--add toadd)
    (st--apply-sort)))

;;;; Remove series

(defun st-remove ()
  "Remove series at point."

  (interactive)

  (st--inbuffer)

  (let ((inhibit-read-only t)
        (series (get-text-property (point) 'st-series))
        (start (previous-single-property-change (1+ (point)) 'st-series nil (point-min)))
        (end (next-single-property-change (point) 'st-series nil (point-max))))
    (when (y-or-n-p "Are you sure you want to delete this series? ")
      (st--remove series)
      (delete-region start end))))

;;;; (un)Watch episodes

;;;;; Update appearance watched region

(defun st--update-watched-region (start end &optional watch)
  "Update the buffer for change in WATCH between START and END."

  (let* ((startline (line-number-at-pos start))
         (endline (1- (line-number-at-pos end))))

    (save-excursion
      (--each
          (number-sequence startline endline)
        (st--update-watched-line it watch)))))

(defun st--update-watched-line (linum watch)
  "Update a single line LINUM for WATCH status."

  (goto-char (point-min))
  (forward-line (1- linum))

  (let ((episode (get-text-property (point) 'st-episode))
        (season (get-text-property (point) 'st-season))
        (series (get-text-property (point) 'st-series))
        (start (progn (move-beginning-of-line nil) (point)))
        (end (progn (forward-line 1) (point))))
    (cond (episode
           (if watch
               (progn
                 (put-text-property start end 'invisible 'st-watched)
                 (put-text-property start end 'face 'st-watched))
             (put-text-property start end 'invisible nil)
             (put-text-property start end 'face 'default)
             (if (time-less-p (date-to-time (buffer-substring start (+ start 19)))
                              (current-time))
                 (put-text-property start (+ start 19) 'face '(t ((:foreground "MediumSpringGreen"))))
               (put-text-property start (+ start 19) 'face '(t ((:foreground "firebrick")))))))
          (season
           (if (--all? (alist-get 'watched it)
                       (->> st--data
                         (--find (= series (alist-get 'id it)))
                         (alist-get 'episodes)
                         (--filter (= season (alist-get 'season it)))))
               (put-text-property start end 'invisible 'st-watched)
             (put-text-property start end 'invisible nil)))
          (series
           (if (--all? (alist-get 'watched it)
                       (alist-get 'episodes (--find (= series (alist-get 'id it))
                                                      st--data)))
              (put-text-property start end 'invisible 'st-watched)
             (put-text-property start end 'invisible nil))))))

;;;;; Toggle watch

(defun st-toggle-watch ()
  "Toggle watch at point.
The element under the cursor is used to decide whether to watch or unwatch."

  (interactive)

  (st--inbuffer)

  (let* ((pos (if (region-active-p) (region-beginning) (point)))
         (watched (get-char-property-and-overlay pos 'invisible))
         (watch (not (-contains? watched 'st-watched))))
    (st-watch watch)))

;;;;; Dispatch (un)watch

(defun st-watch (watch)
  "WATCH at point."

  (let ((inhibit-read-only t)
        (series (get-text-property (point) 'st-series))
        (season (get-text-property (point) 'st-season))
        (episode (get-text-property (point) 'st-episode)))
    (cond ((region-active-p) (st-watch-region (region-beginning) (region-end) watch))
          (episode (st-watch-episode watch))
          (season (st-watch-season series season watch))
          (t (st-watch-series series watch))))
  (forward-line))

;;;;; Region

(defun st-watch-region (start end &optional watch)
  "WATCH region from START to END positions in the buffer."

  (let ((start-series (get-text-property start 'st-series))
        (start-season (get-text-property start 'st-season))
        (start-episode (get-text-property start 'st-episode))
        (end-series (get-text-property end 'st-series))
        (end-season (get-text-property end 'st-season))
        (end-episode (get-text-property end 'st-episode)))

    (st--watch-region start-series start-season start-episode end-series end-season end-episode watch)
    (st--update-watched-region start end watch)))

;;;;; Episode

(defun st-watch-episode (watch)
  "WATCH the episode at point."

  (let ((start (previous-single-property-change (1+ (point)) 'st-episode))
        (end (next-single-property-change (point) 'st-episode nil (point-max))))

    (st-watch-region start end watch)))

;;;;; Season

(defun st-watch-season (id seasonN watch)
  "WATCH SEASONN of series ID."

  (let* ((start-season (previous-single-property-change (1+ (point)) 'st-season))
         (start (next-single-property-change (1+ (point)) 'st-episode nil (point-max)))
         (end (next-single-property-change start 'st-season nil (point-max))))

    (st--watch-season id seasonN watch)
    (st--update-watched-region start-season end watch)))

;;;;; Series

(defun st-watch-series (id watch)
  "WATCH all episodes in series ID."

  (let* ((start-series (previous-single-property-change (1+ (point)) 'st-series))
         (start (next-single-property-change (1+ (point)) 'st-episode nil (point-max)))
         (end (next-single-property-change start 'st-series nil (point-max))))

    (st--watch-series id watch)
    (st--update-watched-region start-series end watch)))

;;;;; Up

(defun st-watch-up ()
  "Watch up to episode at point."

  (interactive)

  (st--inbuffer)

  (let* ((inhibit-read-only t)
         (start-series (previous-single-property-change (1+ (point)) 'st-series))
         (start-season (next-single-property-change start-series 'st-season nil (point-max)))
         (start (next-single-property-change start-season 'st-episode nil (point-max)))
         (end (next-single-property-change (1+ (point)) 'st-episode nil (point-max))))

    (st-watch-region start end t)))

;;;; Sort series

(defun st-sort-next ()
  "Sort series by date of next episode to watch."

  (interactive)

  (st--inbuffer)

  (defun first-next-date (series)
    (let ((dates (->> series
                   (alist-get 'episodes)
                   (--filter (not (alist-get 'watched it))))))
      (if dates
          (->> dates
            (st--utils-array-pull 'air_date)
            (--map (car (date-to-time it)))
            -min)
        0)))

  (defun comp (a b)
    (< (first-next-date a)
       (first-next-date b)))

  (setq st--data (-sort 'comp st--data)))

(defun st-sort-alpha ()
  "Sort alphabetically."

  (interactive)

  (st--inbuffer)

  (defun comp (a b)
    (string< (alist-get 'name a)
             (alist-get 'name b)))

  (setq st--data (-sort 'comp st--data)))

;;;; Create mode

(defun st-update ()
  "Update the db and refresh the buffer."

  (interactive)

  (st--inbuffer)

  (st--update)
  (st--refresh))

(defun st ()
  "Run ST."

  (interactive)

  (switch-to-buffer "st")
  (st-mode)
  (unless st--file (setq st--file (concat user-emacs-directory "st.el")))
  (st--load)
  (st--update)
  (st--refresh)
  (st--apply-watched))

(define-derived-mode st-mode special-mode "st"
  "Series tracking with episodate.com."

  (setq-local buffer-invisibility-spec '(t st-series st-season))
  (setq-local max-lisp-eval-depth 10000)

  ;; keymap

  (local-set-key "p" 'st-prev-line)
  (local-set-key "n" 'next-line)

  (local-set-key "C-p" 'st-prev)
  (local-set-key "C-n" 'st-next)

  (local-set-key "C-u" 'st-up)
  (local-set-key "C-b" 'st-prev-same)
  (local-set-key "C-f" 'st-next-same)

  (local-set-key "C-d" 'st-fold-at-point)
  (local-set-key "C-e" 'st-unfold-at-point)

  (local-set-key "h" 'st-dispatch)
  (local-set-key "U" 'st-update)
  (local-set-key "A" 'st-search)
  (local-set-key "w" 'st-toggle-watch)
  (local-set-key "u" 'st-watch-up)
  (local-set-key "W" 'st-toggle-display-watched)
  (local-set-key "q" 'st-quit)
  (local-set-key [tab] 'st-cycle))

;;; Postamble

(provide 'seriesTracker)

;;; seriesTracker.el ends here
