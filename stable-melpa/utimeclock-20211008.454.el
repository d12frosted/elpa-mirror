;;; utimeclock.el --- Simple utility for manual time tracking -*- lexical-binding: t -*-

;; Copyright (C) 2020  Campbell Barton

;; Author: Campbell Barton <ideasman42@gmail.com>

;; URL: https://gitlab.com/ideasman42/emacs-utimeclock
;; Package-Version: 20211008.454
;; Package-Commit: e6e3dd50fb7e3b20e38db555950b2f417a12c993
;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))

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

;; This is a simple time tracking utility to clock on/off and report time spent.

;;; Usage:

;; ;; Bind Ctrl-Alt-t to clock on/off.
;; (global-set-key (kbd "<f5>") 'utimeclock-toggle)
;; (global-set-key (kbd "<f6>") 'utimeclock-show-summary)

;;; Code:

(eval-when-compile (require 'subr-x))


;; ---------------------------------------------------------------------------
;; Custom Variables

(defgroup utimeclock nil "Configure time-tracking defaults." :group 'tools)

(defcustom utimeclock-time-prefix "time:"
  "The prefix of a line used to store time.

Note that space before this line is ignored."
  :type 'string)

(defcustom utimeclock-time-pair "-"
  "The string used to pair up time ranges (must not contain spaces)."
  :type 'string)

(defcustom utimeclock-split-at-fill-column t
  "Split lines with `utimeclock-line-separator' when they exceed `fill-column'."
  :type 'boolean)

(defcustom utimeclock-line-separator "\\"
  "The character used for line continuations."
  :type 'string)

(defcustom utimeclock-12-hour-clock nil
  "Use 12 hour clock instead of a 24 hour clock.

This controls the values entered as well as behavior wrapping time values."
  :type 'boolean)

(defcustom utimeclock-time-precision 'minutes
  "The precision of report time in."
  :type
  '
  (choice
    (const :tag "Hours" hours)
    (const :tag "Minutes" minutes)
    (const :tag "Seconds" seconds)))


;; ---------------------------------------------------------------------------
;; Internal Functions/Macros

(defun utimeclock-as-sec-total (str)
  "Convert STR in the format '4:30:59' to the number of seconds as an int."
  (let ((v (split-string str ":")))
    (+
      (* 3600 (string-to-number (pop v))) ;; Hours.
      (cond
        (v
          (* 60 (string-to-number (pop v)))) ;; Minutes.
        (t
          0))
      (cond
        (v
          (string-to-number (pop v))) ;; Seconds.
        (t
          0)))))


(defun utimeclock-from-sec-total (sec-total)
  "Convert SEC-TOTAL to time format '4:30:59'."
  (let*
    (
      (h (/ sec-total 3600))
      (m (- (/ sec-total 60) (* h 60)))
      (s (- sec-total (+ (* m 60) (* h 3600)))))
    (cond
      ((eq utimeclock-time-precision 'seconds)
        (format "%d:%02d:%02d" h m s))
      ((eq utimeclock-time-precision 'minutes)
        (format "%d:%02d" h m))
      (t
        (format "%d" h)))))


(defun utimeclock-current-time-as-string ()
  "Return the current time as a string."
  (string-trim-left
    (format-time-string
      (cond
        ((eq utimeclock-time-precision 'seconds)
          (cond
            (utimeclock-12-hour-clock
              "%l:%M:%S")
            (t
              "%k:%M:%S")))
        ((eq utimeclock-time-precision 'minutes)
          (cond
            (utimeclock-12-hour-clock
              "%l:%M")
            (t
              "%k:%M")))
        (t
          (cond
            (utimeclock-12-hour-clock
              "%l")
            (t
              "%k")))))))


(defun utimeclock-accumulate-line (line allow-incomplete)
  "Accumulate time ranges in LINE into '(time-as-seconds . time-was-incomplete).

When ALLOW-INCOMPLETE is not nil, allow a start time without a matching end.
In this case the current time is used as the end time."
  (let
    (
      (time-pair-sep (regexp-quote utimeclock-time-pair))
      (time-was-incomplete nil)
      (time-as-seconds 0))
    (dolist (time-pair (split-string line))
      (when time-was-incomplete
        (message "Incomplete time string '%s'" line))
      (pcase-let ((`(,time-start ,time-end) (split-string time-pair time-pair-sep)))
        (setq time-was-incomplete nil)
        ;; `time-end' will be null when there was no dash in the string.
        ;; allow this for the end-string.
        (when (or (null time-end) (string-equal time-end ""))
          ;; We could make this optional.
          (unless allow-incomplete
            (message "Incomplete time not allowed '%s'" line))
          (setq time-end (utimeclock-current-time-as-string))
          (setq time-was-incomplete t))

        (let
          (
            (time-span
              (- (utimeclock-as-sec-total time-end) (utimeclock-as-sec-total time-start))))
          ;; Wrap
          (when (< time-span 0)
            (setq time-span
              (+
                time-span
                (cond
                  (utimeclock-12-hour-clock
                    (* 12 60 60))
                  (t
                    (* 24 60 60))))))
          (setq time-as-seconds (+ time-as-seconds time-span)))))
    (cons time-as-seconds time-was-incomplete)))


(defun utimeclock-time-point-previous-no-eol ()
  "Return the starting point of `utimeclock-time-prefix' or nil."
  (save-excursion
    (cond
      ((search-backward utimeclock-time-prefix nil t 1)
        (point))
      (t
        nil))))


(defun utimeclock-time-point-previous ()
  "Return the starting point of `utimeclock-time-prefix' or nil.

This first moves to the line end."
  (save-excursion
    (end-of-line)
    (cond
      ((search-backward utimeclock-time-prefix nil t 1)
        (point))
      (t
        nil))))


(defun utimeclock-time-point-previous-prefix (time-pos)
  "Return text at the line beginning, before `utimeclock-time-prefix'.

This could be a comment for example, or a blank string if nothing is found.
TIME-POS should be the result of `utimeclock-time-point-previous'."
  (save-excursion
    (goto-char time-pos)
    (concat
      ;; Text before time-prefix.
      (buffer-substring-no-properties (line-beginning-position) time-pos)
      ;; Indent the size of time-prefix as spaces.
      (utimeclock-buffer-range-to-spaces time-pos (+ time-pos (length utimeclock-time-prefix))))))


(defun utimeclock-line-end-position-nonblank ()
  "Return the line end position (excluding white-space)."
  (save-excursion
    (goto-char (line-end-position))
    (skip-chars-backward "[:blank:]")
    (point)))


(defun utimeclock-current-line-empty-p ()
  "Return t when the current line is empty."
  (save-excursion
    (beginning-of-line)
    (looking-at-p "[[:blank:]]*$")))


(defun utimeclock-current-line-ends-with (str)
  "Return t when the current line ends with STR."
  (let
    ( ;; Line range.
      (bol (line-beginning-position))
      (eol (line-end-position)))
    (let ((eol-text (buffer-substring-no-properties (max bol (- eol (length str))) eol)))
      (string-equal str eol-text))))


(defun utimeclock-buffer-range-to-spaces (beg end)
  "Return a string of spaces the length of two ranges in the buffer.

Note that this is often simply BEG subtracted from END,
however when tabs are used the results will be different."
  (save-excursion
    (let
      (
        (beg-col
          (progn
            (goto-char beg)
            (current-column)))
        (end-col
          (progn
            (goto-char end)
            (current-column))))
      (make-string (- end-col beg-col) ?\s))))


(defun utimeclock-extract-line-multi (pos prefix)
  "Extract the line at POS until the line end.

Lines that end with `utimeclock-line-separator' are considered part of the line,
therefore we can extract multiple lines into a single logical line of text.

Strip PREFIX from each line (when not nil or an empty string)."
  (save-excursion
    (goto-char pos)
    (let ((line (string-trim-right (buffer-substring-no-properties pos (line-end-position)))))
      (unless (or (null prefix) (zerop (length prefix)))
        (setq line (string-trim-left (string-remove-prefix prefix line))))
      (when (string-suffix-p utimeclock-line-separator line)
        (setq line (string-trim-right (string-remove-suffix utimeclock-line-separator line)))
        (when (zerop (forward-line 1))
          (setq line
            (concat line " " (utimeclock-extract-line-multi (line-beginning-position) prefix)))))
      line)))


(defun utimeclock-end-of-line-multi (pos)
  "Return the end of line position of POS.

This takes `utimeclock-extract-line-multi' into account."
  (save-excursion
    (goto-char pos)
    (let ((eol (utimeclock-line-end-position-nonblank)))
      (let ((line (string-trim-right (buffer-substring-no-properties pos eol))))
        (when (string-suffix-p utimeclock-line-separator line)
          (when (zerop (forward-line 1))
            (setq eol (utimeclock-end-of-line-multi (line-beginning-position))))))
      eol)))


(defun utimeclock-split-at-point (prefix)
  "Split the last time-range onto the next line if it exceeds the `fill-column'.

PREFIX will be added to the beginning of the new line."
  (save-excursion
    (move-to-column fill-column)
    (when (save-match-data (search-backward " " (line-beginning-position) t 1))
      (forward-char 1)
      (insert utimeclock-line-separator "\n" prefix " "))))


(defun utimeclock-last-clock-off-duration (time-pos)
  "Time spent (working).

Return the time immediately after clocking off for time starting at TIME-POS."
  (or
    (with-demoted-errors "utimeclock: %S"
      (let*
        (
          (prefix (utimeclock-time-point-previous-prefix time-pos))
          (time-pos-next (+ time-pos (length utimeclock-time-prefix)))
          (line (utimeclock-extract-line-multi time-pos-next prefix))
          (time-pair (car (last (split-string line)))))
        (utimeclock-from-sec-total (car (utimeclock-accumulate-line time-pair nil)))))
    "unknown"))


(defun utimeclock-last-clock-on-duration (time-pos)
  "Time spent (having a break).

Return the time immediately after clocking on for time starting at TIME-POS."
  (or
    (with-demoted-errors "utimeclock: %S"
      (let*
        (
          (prefix (utimeclock-time-point-previous-prefix time-pos))
          (time-pos-next (+ time-pos (length utimeclock-time-prefix)))
          (line (utimeclock-extract-line-multi time-pos-next prefix))
          (last-pair (last (split-string line) 2)))
        (cond
          ((eq (length last-pair) 2)
            (pcase-let ((`(,t1 ,t2) last-pair))
              (let ((t1-half (car (last (split-string t1 utimeclock-time-pair)))))
                (let ((time-pair (concat t1-half utimeclock-time-pair t2)))
                  (utimeclock-from-sec-total (car (utimeclock-accumulate-line time-pair nil)))))))
          (t
            "started"))))
    "unknown"))


;; ---------------------------------------------------------------------------
;; Public Functions

;;;###autoload
(defun utimeclock-from-context (combine-all-times)
  "Search for STR, accumulate all times after it, return the accumulated time.

Argument COMBINE-ALL-TIMES keeps searching backwards,
accumulating all times in the buffer."
  (save-excursion
    (end-of-line)
    (save-match-data
      (let
        ( ;; Only allow incomplete time last, otherwise show error.
          (time-was-incomplete-all nil)
          (time-as-seconds-all 0)
          (first-time t)
          (time-pos nil))

        ;; Find start of comment.
        (while
          (and
            ;; Once, or find all.
            (or combine-all-times first-time)
            ;; Find the time prefix, no end-of-line so
            ;; calling a second time doesn't find the same time.
            (setq time-pos (utimeclock-time-point-previous-no-eol)))

          (setq first-time nil)

          (let*
            (
              (prefix (utimeclock-time-point-previous-prefix time-pos))
              (time-pos-next (+ time-pos (length utimeclock-time-prefix)))
              (line (utimeclock-extract-line-multi time-pos-next prefix)))

            (pcase-let
              (
                (`(,time-as-seconds . ,is-incomplete)
                  (utimeclock-accumulate-line line (not time-was-incomplete-all))))
              (when is-incomplete
                (setq time-was-incomplete-all t))
              (setq time-as-seconds-all (+ time-as-seconds-all time-as-seconds))))

          (goto-char time-pos))

        (unless (zerop time-as-seconds-all)
          (concat
            (utimeclock-from-sec-total time-as-seconds-all)
            (cond
              (time-was-incomplete-all
                "..") ;; Show that time is ongoing.
              (t
                ""))))))))


;;;###autoload
(defun utimeclock-from-context-summary ()
  "Return the time before the cursor or contained within the selection.

When available, otherwise return nil."
  (cond
    ;; Use time from the active-region when set.
    ((use-region-p)
      (save-restriction
        (narrow-to-region (region-beginning) (region-end))
        (save-excursion
          (goto-char (point-max))
          (format "(selected %s)" (utimeclock-from-context t)))))
    ;; Search back from the cursor.
    (t
      (let
        (
          (time-accumulate (utimeclock-from-context nil))
          (time-accumulate-all (utimeclock-from-context t)))
        (when time-accumulate
          (format "%s (all %s)" time-accumulate time-accumulate-all))))))


;;;###autoload
(defun utimeclock-toggle ()
  "Clock on/off, declare time ranges from the current time.

Add time to the end of the current lines time or search backwards to find one.
Otherwise add `utimeclock-time-prefix' and the time after it."
  (interactive)
  (let
    (
      (time-string (utimeclock-current-time-as-string))
      (time-pos (utimeclock-time-point-previous))
      (init-bol (line-beginning-position))
      (next-pos nil))

    ;; No time prefix, add one.
    (unless time-pos
      (setq time-pos (point))
      (insert utimeclock-time-prefix " "))

    (save-excursion
      (goto-char (utimeclock-end-of-line-multi time-pos))
      (let ((eol (line-end-position)))
        ;; Trim blank-space.
        (unless (eq (point) eol)
          (delete-region (point) eol)))

      (cond
        ;; End the current time-span?
        ((utimeclock-current-line-ends-with utimeclock-time-pair)
          (insert time-string)
          (message "Clocked off! [%s]" (utimeclock-last-clock-off-duration time-pos)))

        ;; Begin a new time-span?
        (t
          ;; Start new line, add comment if needed (based on previous line).
          (when (utimeclock-current-line-empty-p)
            (let ((prefix (utimeclock-time-point-previous-prefix time-pos)))
              (insert prefix)))

          (insert " " time-string utimeclock-time-pair)

          ;; Clock on message.
          (message "Clocked on! [%s]" (utimeclock-last-clock-on-duration time-pos))))

      ;; Set this before breaking the line.
      (let ((is-matching-line (eq init-bol (line-beginning-position))))

        (when utimeclock-split-at-fill-column
          (when (>= (current-column) fill-column)
            (let ((prefix (utimeclock-time-point-previous-prefix time-pos)))
              (utimeclock-split-at-point prefix))))

        ;; Move the cursor if it is on the same line.
        (when is-matching-line
          (setq next-pos (point)))))

    (when next-pos
      (goto-char next-pos))))


;;;###autoload
(defun utimeclock-insert ()
  "Insert the current time at the cursor.

Unlike `utimeclock-toggle' this doesn't pair time ranges or
ensure `utimeclock-time-prefix' text."
  (interactive)

  (let ((time-string (utimeclock-current-time-as-string)))
    (insert time-string)

    (when utimeclock-split-at-fill-column
      (when (>= (current-column) fill-column)
        (let ((time-pos (utimeclock-time-point-previous)))
          (cond
            (time-pos
              (let ((prefix (utimeclock-time-point-previous-prefix time-pos)))
                (utimeclock-split-at-point prefix)))
            (t
              (message "Can not split the line %S not found!" utimeclock-time-prefix))))))))


;;;###autoload
(defun utimeclock-show-summary ()
  "Show a summary of the last time and all times combined in the message buffer."
  (interactive)
  (message "Time %S" (utimeclock-from-context-summary)))

(provide 'utimeclock)

;;; utimeclock.el ends here
