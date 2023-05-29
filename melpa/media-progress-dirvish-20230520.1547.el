;;; media-progress-dirvish.el --- Display position where media player stopped in dirvish -*- lexical-binding:t -*-
;; Copyright (C) 2023  Dmitriy Pshonko

;; Author: Dmitriy Pshonko <http://github.com/jumper047>
;; Version: 0.1.0
;; Package-Version: 20230520.1547
;; Package-Commit: ec777d2d200ecb85795a225b482808f048c30a1c
;; Keywords: files, convenience
;; Homepage: https://github.com/jumper047/media-progress

;; Package-Requires: ((emacs "28.1") (dirvish "2.0.0") (media-progress "0.1.0"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
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
;; 
;; Package adds information about viewing progress of the media files
;; in DIRED buffer.
;; For now only mpv player supported.
;; 
;; Preparations:
;; Install mpv player. You can save position on exit manually using
;; "Shift-Q" shortcut, or add these lines to the mpv config:
;; 
;; keep-open=yes
;; save-position-on-quit=yes
;;
;; Optionally - install "mediainfo" app to display progress and "completed"
;; status.

;;; Code:

(require 'dirvish)
(require 'media-progress)

(defgroup media-progress-dirvish nil
  "Display position where media player stopped in dirvish."
  :group 'dired
  :prefix "media-progress-dirvish-")

(defface media-progress-dirvish-face
  '((t (:inherit dired-ignored :underline nil :background unspecified)))
  "Face for media progress overlays."
  :group 'media-progress-dirvish)

(defvar media-progress-dirvish-curr-dir nil)
(defvar media-progress-dirvish-cache nil)

(defun media-progress-dirvish-info-string (file)
  "Get progress string for FILE, use cache if possible."
  (unless (equal (file-name-directory file) media-progress-dirvish-curr-dir)
    (clrhash media-progress-dirvish-cache)
    (setq media-progress-dirvish-curr-dir (file-name-directory file)))
  (let ((progress-string (gethash file media-progress-dirvish-cache)))
    (unless progress-string
      (setq progress-string (media-progress-info-string file))
      (puthash file progress-string media-progress-dirvish-cache))
    progress-string))

(dirvish-define-attribute media-progress
  "Append player progress info to the media file."
  :index 1
  :when (and (not (eq (dirvish-prop :vc-backend) 'Git)) ; don't clash with VC
             (not (dirvish-prop :remote))
             (> win-width 65))
  (let* ((progress-str (media-progress-dirvish-info-string f-name))
         (face (or hl-face 'media-progress-dirvish-face))
         (str (concat "  " progress-str " ")))
    (add-face-text-property 0 (length str) face t str)
    `(left . ,str)))

(defun media-progress-dirvish-setup ()
  "Set up media-progress info segment for DIRVISH."
  (setq media-progress-dirvish-cache (make-hash-table :test 'equal))
  (push '(media-progress-dirvish media-progress) dirvish-libraries)
  (push 'media-progress dirvish-attributes))

(provide 'media-progress-dirvish)
;;; media-progress-dirvish.el ends here
