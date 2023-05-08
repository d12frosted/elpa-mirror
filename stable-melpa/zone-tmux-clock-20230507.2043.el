;;; zone-tmux-clock.el --- Zone out with a tmux style clock  -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Vasilij Schneidermann <mail@vasilij.de>
;; SPDX-License-Identifier: GPL-3.0-or-later

;; Author: Vasilij Schneidermann <mail@vasilij.de>
;; URL: https://depp.brause.cc/zone-tmux-clock
;; Package-Version: 20230507.2043
;; Package-Commit: f8158aad57730e1611a3994cf921037770753d72
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.3"))
;; Keywords: games

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; A zone program displaying a textual clock similar to the
;; `clock-mode` command in tmux.

;; See the README for more info: https://depp.brause.cc/zone-tmux-clock

;;; Code:

(require 'zone)

(defgroup zone-tmux-clock nil
  "Zone out with a tmux style clock."
  :group 'zone
  :prefix "zone-tmux-clock-")

(defconst zone-tmux-clock-empty-block ?\s
  "Character used for an empty block.")

(defconst zone-tmux-clock-text-block ?\#
  "Character used for a block filled with text.")

(defface zone-tmux-clock-solid-face
  '((t :inherit cursor))
  "Face for `zone-tmux-clock-solid-block'.")

(defconst zone-tmux-clock-solid-block
  (propertize " " 'face 'zone-tmux-clock-solid-face)
  "String used for a block filled with solid color.
Customize `zone-tmux-clock-solid-face' to change it.")

(defcustom zone-tmux-clock-filled-block zone-tmux-clock-solid-block
  "String or character to insert for a filled block.
See `zone-tmux-clock-text-block' and `zone-tmux-clock-solid-block' for
example choices."
  :type '(choice string character)
  :group 'zone-tmux-clock)

(defvar zone-tmux-clock-digits (make-char-table 'zone-tmux-clock-digits)
  "Char table holding a 6x6 bitmap for each supported clock digit.
Empty space is represented by ?\\s, filled space by ?\\#.")

(aset zone-tmux-clock-digits ?\s [[?\s?\s?\s?\s?\s]
                                  [?\s?\s?\s?\s?\s]
                                  [?\s?\s?\s?\s?\s]
                                  [?\s?\s?\s?\s?\s]
                                  [?\s?\s?\s?\s?\s]])
(aset zone-tmux-clock-digits ?1 [[?\s?\s?\s?\s?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\s?\s?\s?\s?\#]])
(aset zone-tmux-clock-digits ?2 [[?\#?\#?\#?\#?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\s]
                                 [?\#?\#?\#?\#?\#]])
(aset zone-tmux-clock-digits ?3 [[?\#?\#?\#?\#?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]])
(aset zone-tmux-clock-digits ?4 [[?\#?\s?\s?\s?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\s?\s?\s?\s?\#]])
(aset zone-tmux-clock-digits ?5 [[?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\s]
                                 [?\#?\#?\#?\#?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]])
(aset zone-tmux-clock-digits ?6 [[?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\s]
                                 [?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]])
(aset zone-tmux-clock-digits ?7 [[?\#?\#?\#?\#?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\s?\s?\s?\s?\#]])
(aset zone-tmux-clock-digits ?8 [[?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]])
(aset zone-tmux-clock-digits ?9 [[?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]
                                 [?\s?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]])
(aset zone-tmux-clock-digits ?0 [[?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]])
(aset zone-tmux-clock-digits ?: [[?\s?\s?\s?\s?\s]
                                 [?\s?\s?\#?\s?\s]
                                 [?\s?\s?\s?\s?\s]
                                 [?\s?\s?\#?\s?\s]
                                 [?\s?\s?\s?\s?\s]])
(aset zone-tmux-clock-digits ?A [[?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\s?\s?\s?\#]])
(aset zone-tmux-clock-digits ?P [[?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\s]
                                 [?\#?\s?\s?\s?\s]])
(aset zone-tmux-clock-digits ?M [[?\#?\s?\s?\s?\#]
                                 [?\#?\#?\s?\#?\#]
                                 [?\#?\s?\#?\s?\#]
                                 [?\#?\s?\s?\s?\#]
                                 [?\#?\s?\s?\s?\#]])
(aset zone-tmux-clock-digits ?E [[?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\s]
                                 [?\#?\#?\#?\#?\#]
                                 [?\#?\s?\s?\s?\s]
                                 [?\#?\#?\#?\#?\#]])

(defconst zone-tmux-clock-digit-width 6
  "Width of a clock digit in characters.")

(defconst zone-tmux-clock-digit-height 6
  "Height of a clock digit in characters.")

(defvar zone-tmux-clock-progress-timer nil
  "Timer for updating the zone buffer contents.
It fires every second.")

(defconst zone-tmux-clock-time-format-24 "%H:%M"
  "Time format string for 24 hour display.")

(defconst zone-tmux-clock-time-format-12 "%l:%M %p"
  "Time format string for 12 hour display.")

(defcustom zone-tmux-clock-time-format-style 24
  "Whether to use the 24 or 12 hour format."
  :type '(choice (const :tag "24" 24)
                 (const :tag "12" 12))
  :group 'zone-tmux-clock)

(defvar-local zone-tmux-clock-last-time-string nil)

(defun zone-tmux-clock-render (time-string)
  "Insert a textual representation of TIME-STRING.
Rendering is performed by looking up each character in
`zone-tmux-clock-digits' and inserting either
`zone-tmux-clock-filled-block' or `zone-tmux-clock-empty-block'."
  (let ((width (window-body-width))
        (height (window-body-height))
        (min-width (* (length time-string) zone-tmux-clock-digit-width))
        (min-height zone-tmux-clock-digit-height))
    (if (or (< width min-width) (< height min-height))
        (insert (format "zone-tmux-clock requires a %dx%d canvas\n"
                        min-width min-height))
      (let ((padding-cols (truncate (/ (- width min-width) 2)))
            (padding-rows (truncate (/ (- height min-height) 2))))
        (dotimes (_ padding-rows)
          (insert "\n"))
        (dotimes (row 5)
          (dotimes (_ padding-cols)
            (insert zone-tmux-clock-empty-block))
          (dotimes (i (length time-string))
            (let* ((char (aref time-string i))
                   (bitmap (or (aref zone-tmux-clock-digits char)
                               (aref zone-tmux-clock-digits ?E)))
                   (line (aref bitmap row)))
              (dotimes (j 5)
                (insert (if (char-equal (aref line j) ?\s)
                            zone-tmux-clock-empty-block
                          zone-tmux-clock-filled-block)))
              (insert zone-tmux-clock-empty-block)))
          (insert "\n"))))))

(defun zone-tmux-clock-progress (buf)
  "Timer function invoked on the zone buffer BUF.
Re-renders the buffer whenever the time to be displayed changes."
  (with-current-buffer buf
    (let* ((now (float-time))
           (format-string (if (= zone-tmux-clock-time-format-style 12)
                              zone-tmux-clock-time-format-12
                            zone-tmux-clock-time-format-24))
           (time-string (format-time-string format-string now)))
      (when (not (equal time-string zone-tmux-clock-last-time-string))
        (erase-buffer)
        (zone-tmux-clock-render time-string))
      (setq zone-tmux-clock-last-time-string time-string))))

;;;###autoload
(defun zone-tmux-clock ()
  "Zone program displaying a tmux style clock."
  (delete-other-windows)
  (internal-show-cursor nil nil)
  (let (;; HACK: zone aborts on read-only buffers
        (inhibit-read-only t))
    (unwind-protect
        (progn
          (setq zone-tmux-clock-progress-timer
                (run-at-time 0 1 #'zone-tmux-clock-progress (current-buffer)))
          (while (not (input-pending-p))
            (sit-for 60))
          (discard-input))
      (internal-show-cursor nil t)
      (when zone-tmux-clock-progress-timer
        (cancel-timer zone-tmux-clock-progress-timer)))))

;;;###autoload
(defun zone-tmux-clock-preview ()
  "Preview the `zone-tmux-clock' zone program."
  (interactive)
  (let ((zone-programs [zone-tmux-clock]))
    (zone)))

(provide 'zone-tmux-clock)

;;; zone-tmux-clock.el ends here
