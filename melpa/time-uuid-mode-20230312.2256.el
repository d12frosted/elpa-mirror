;;; time-uuid-mode.el --- Minor mode for previewing time uuids as an overlay -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2023 Robert Plant
;;
;; Author: Robert Plant <rob@robertplant.io>
;; Maintainer: Robert Plant <rob@robertplant.io>
;; Created: March 10, 2023
;; Modified: March 10, 2023
;; Version: 0.0.1
;; Package-Version: 20230312.2256
;; Package-Commit: 6f0768edb7588add3713952e5b20e9df8ee51f89
;; Keywords: extensions, convenience, data, tools
;; Homepage: https://github.com/RobertPlant/time-uuid-mode
;; Package-Requires: ((emacs "24.3"))
;; SPDX-License-Identifier: GPL-3.0-only
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; This is a convenience tool to search for time UUIDs (v1) and preview the
;; corresponding date stored within it. This can be useful when loading data
;; that uses a v1 UUID to find the latest record.
;;
;; A single function is also provided to preview a single time UUID under the
;; cursor, this will clean itself up afterr 5 seconds.
;;
;; Get the development version from git:
;;
;;    git clone git://github.com:RobertPlant/time-uuid-mode.git

;;; TODO:
;;
;; * Persist the preview overlays when they are not the focused buffer

;;; Code:

;; Define a regular expression to match time-based UUIDs
(defconst time-uuid-mode-regexp
  "\\b[0-9a-f]\\{8\\}-[0-9a-f]\\{4\\}-1[0-9a-f]\\{3\\}-[89ab][0-9a-f]\\{3\\}-[0-9a-f]\\{12\\}\\b")

;; Store the time stamp overlays
(defvar time-uuid-mode-stamp-overlays nil)

(defun time-uuid-mode-remove-all-overlays ()
  "Remove time uuids overlays."
  (dolist (overlay time-uuid-mode-stamp-overlays)
    (when (overlay-buffer overlay)
      (delete-overlay overlay)))
  (setq time-uuid-mode-stamp-overlays nil))

(defun time-uuid-mode-overlay-all-uuid-v1s ()
  "Overlay time-based UUIDs with their corresponding date and time."
  (time-uuid-mode-remove-all-overlays)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward time-uuid-mode-regexp nil t)
      (let* ((uuid (match-string 0))
             (formatted-time (time-uuid-mode-uuid-to-iso8601 uuid)))
        (when formatted-time
          (let* ((time-stamp-overlay (make-overlay (1- (line-end-position)) (line-end-position)))
                 (text-block (propertize formatted-time 'face '(:background "yellow" :foreground "black")))
                 (formatted-block (concat " " text-block)))
            (overlay-put time-stamp-overlay 'after-string formatted-block)
            (push time-stamp-overlay time-uuid-mode-stamp-overlays)))))))

;; Extract the chunks of time from the UUID
;; Convert the hex into a number and delete
(defun time-uuid-mode-uuid-to-iso8601 (uuid)
  "Convert a time-based UUID to ISO-8601 format."
  (let* ((hex (replace-regexp-in-string "-" "" uuid))
         (time-low (substring hex 0 8))
         (time-mid (substring hex 8 12))
         (time-high (substring hex 13 16))
         (hex-time-stamp (concat time-high time-mid time-low))
         (int-time (- (string-to-number hex-time-stamp 16) 122192928000000000))
         (int-millisec (/ int-time 10000000)))
    (format-time-string "%FT%T" (seconds-to-time int-millisec))))

;;;###autoload
(define-minor-mode time-uuid-mode
  "Overlay time-based UUIDs with the corresponding date and time."
  :lighter " UUID"
  (if time-uuid-mode
      (progn
        (add-hook 'post-command-hook #'time-uuid-mode-overlay-all-uuid-v1s nil t)
        (add-hook 'kill-buffer-hook #'time-uuid-mode-remove-all-overlays nil t))
    (time-uuid-mode-remove-all-overlays)
    (remove-hook 'post-command-hook #'time-uuid-mode-overlay-all-uuid-v1s t)
    (remove-hook 'kill-buffer-hook #'time-uuid-mode-remove-all-overlays t)))

;;;###autoload
(defun time-uuid-mode-preview-formatted-time ()
  "Preview the date time for the selected UUID. The UUID is deleted on a timer."
  (interactive)
  (let* ((uuid (if (region-active-p)
                   (buffer-substring-no-properties (region-beginning) (region-end))
                 (thing-at-point 'symbol)))
         (formatted-time (time-uuid-mode-uuid-to-iso8601 uuid)))
    (when formatted-time
      (let* ((time-stamp-overlay (make-overlay (1- (line-end-position)) (line-end-position)))
             (text-block (propertize formatted-time 'face '(:background "yellow" :foreground "black")))
             (formatted-block (concat " " text-block)))
        (run-with-timer 5 nil #'delete-overlay time-stamp-overlay)
        (overlay-put time-stamp-overlay 'after-string formatted-block)
        (push time-stamp-overlay time-uuid-mode-stamp-overlays)))))

(provide 'time-uuid-mode)

;;; time-uuid-mode.el ends here
