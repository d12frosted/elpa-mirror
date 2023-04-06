;;; org-mpv-notes.el --- Take notes in org mode while watching videos in mpv -*- lexical-binding: t -*-

;; Copyright (C) 2021-2022 Bibek Panthi

;; Author: Bibek Panthi <bpanthi977@gmail.com>
;; Maintainer: Bibek Panthi <bpanthi977@gmail.com>
;; URL: https://github.com/bpanthi977/org-mpv-notes
;; Package-Version: 20230406.359
;; Package-Commit: c437a51aef646839437d6eb699ba86bc530b52b7
;; Version: 0.0.1
;; Package-Requires: ((emacs "27.1") (mpv "0.2.0"))
;; Kewords: mpv, org

;; This file in not part of GNU Emacs

;;; SPDX-License-Identifier: MIT

;;; Commentary:

;; org-mpv-notes allows you to control mpv and take notes from videos
;; playing in mpv.  You can control mpv (play, pause, seek, ...) while
;; in org buffer and insert heading or notes with timestamps to the
;; current playing position.  Later you can revist the notes and seek
;; to the inserted timestamp with a few keystrokes.  Also, it can
;; insert screenshots as org link, run ocr (if ocr program is
;; installed) and insert the ocr-ed text to the org buffer.

;;; Code:
(require 'cl-lib)
(require 'mpv)
(require 'org-attach)
(require 'org-element)


;; from https://github.com/kljohann/mpv.el/wiki
;;  To create a mpv: link type that is completely analogous to file: links but opens using mpv-play instead,
(defun org-mpv-notes-complete-link (&optional arg)
  "Provide completion to mpv: link in `org-mode'.
ARG is passed to `org-link-complete-file'."
  (replace-regexp-in-string
   "file:" "mpv:"
   (org-link-complete-file arg)
   t t))
(org-link-set-parameters "mpv" :complete #'org-mpv-notes-complete-link :follow #'org-mpv-notes-play)
(add-hook 'org-open-at-point-functions #'mpv-seek-to-position-at-point)

(defun org-mpv-notes-save-as-attach (file)
  "Save image FILE to org file using `org-attach'."
  ;; attach it
  (let ((org-attach-method 'mv))
    (org-attach-attach file))
  ;; insert the link
  (insert "[[attachment:" (file-name-base file) "." (file-name-extension file) "]]"))

(defcustom org-mpv-notes-save-image-function
  #'org-mpv-notes-save-as-attach
  "Function to run to save image file to org buffer.
Filename is passed as first argument.  The function has to copy
the file to proper location and insert a link to that file."
  :type '(function)
  :group 'org-mpv-notes)

;; save screenshot as attachment
(defun org-mpv-notes-save-screenshot ()
  "Save screenshot of current frame as attachment."
  (interactive)
  (let ((filename (format "%s.png" (make-temp-file "mpv-screenshot"))))
    ;; take screenshot
    (mpv-run-command "screenshot-to-file"
                     filename
                     "video")
    (funcall org-mpv-notes-save-image-function filename)
    (org-display-inline-images)))

(defcustom org-mpv-notes-ocr-command "tesseract"
  "OCR program to extract text from mpv screenshot."
  :type '(string)
  :group 'org-mpv-notes)

(defcustom org-mpv-notes-ocr-command-args "-"
  "Extra arguments to pass to ocr-command after the input image file."
  :type '(string)
  :group 'org-mpv-notes)

(defun org-mpv-notes-ocr-on-file (file)
  "Run tesseract OCR on the screenshot FILE."
  (unless (executable-find org-mpv-notes-ocr-command) ;; a defcustom
    (user-error "OCR program %S not found" org-mpv-notes-ocr-command))
  (with-temp-buffer
    (if (zerop (call-process org-mpv-notes-ocr-command nil t nil
                             (file-truename file) org-mpv-notes-ocr-command-args))
        (remove ? (buffer-string))
      (error "OCR command failed: %S" (buffer-string)))))

(defun org-mpv-notes-screenshot-ocr ()
  "Take screenshot, run OCR on it and insert the text to org buffer."
  (interactive)
  (let ((filename (format "%s.png" (make-temp-file "mpv-screenshot"))))
    ;; take screenshot
    (mpv-run-command "screenshot-to-file"
                     filename
                     "video")
    (let ((string (org-mpv-notes-ocr-on-file filename)))
      (insert "\n"
              string
              "\n"))))

(defvar org-mpv-notes-timestamp-regex "[0-9]+:[0-9]+:[0-9]+")

(defun org-mpv-notes-next-timestamp ()
  "Seek to next timestamp in the notes file."
  (interactive)
  (when (re-search-forward org-mpv-notes-timestamp-regex nil t)
    (mpv-seek-to-position-at-point)
    (org-show-entry)
    (recenter)))

(defun org-mpv-notes-previous-timestamp ()
  "Seek to previous timestamp in the notes file."
  (interactive)
  (when (re-search-backward org-mpv-notes-timestamp-regex nil t)
    (mpv-seek-to-position-at-point)
    (org-show-entry)
    (recenter)))

(defun org-mpv-notes-this-timestamp ()
  "Seeks to the timestamp stored in the property drawer of the heading."
  (interactive)
  (let ((timestamp (org-entry-get (point) "time" t)))
    (when timestamp
      (let ((time (org-timer-hms-to-secs timestamp)))
        (when (> time 0)
          (mpv-seek time)
          (org-show-entry)
          (recenter))))))

(defun org-mpv-notes-seek-double-step ()
  "Increase seek step size."
  (interactive)
  (setf mpv-seek-step (* 2 mpv-seek-step))
  (message "%f" mpv-seek-step))

(defun org-mpv-notes-seek-halve-step ()
  "Decrease seek step size."
  (interactive)
  (setf mpv-seek-step (/ mpv-seek-step 2.0))
  (message "%f" mpv-seek-step))

(defun org-mpv-speed-up ()
  (interactive)
  (mpv-set-property "speed" (* 1.1 (mpv-get-property "speed"))))

(defun org-mpv-speed-down ()
  (interactive)
  (mpv-set-property "speed" (/ (mpv-get-property "speed") 1.1)))

(defun org-mpv-notes-toggle-fullscreen ()
  "Ask mpv to toggle fullscreen."
  (interactive)
  ;; https://github.com/mpv-player/mpv/blob/master/DOCS/man/inpute.rst
  ;; https://github.com/mpv-player/mpv/blob/master/etc/input.conf
  (mpv--enqueue '("cycle" "fullscreen") #'ignore))

(defun org-mpv-notes--video-arg (path)
  "Video arg corresponding to PATH in [[mpv:...]] link."
  (if (string-match-p "^https?:" path)
      path
    (expand-file-name path
                      (file-name-directory (file-truename (buffer-file-name))))))

(defun org-mpv-notes--org-link-description (element)
  "Get description from a org link ELEMENT."
  (if-let ((begin (org-element-property :contents-begin element))
           (end (org-element-property :contents-end element)))
      (buffer-substring-no-properties begin end)
    ""))

(defun org-mpv-notes-play (path &optional arg)
  ;; see example
  (let (search-option)
    (when (string-match "::\\(.*\\)\\'" path)
      (setq search-option (match-string 1 path))
      (setq path (replace-match "" nil nil path)))
    (cond ((not (mpv-live-p))
           (mpv-start path))
          ((not (string-equal (mpv-get-property "path") path))
           (mpv-kill)
           (sleep-for 0.05)
           (mpv-start path)))
    (cond ((string-match (concat "^" org-mpv-notes-timestamp-regex) search-option)
           (let ((secs (org-timer-hms-to-secs search-option)))
             (when (>= secs 0)
               (mpv-seek secs))))
          ((string-match "^\\([0-9]+\\)$" search-option)
           (let ((secs (string-to-number search-option)))
             (mpv-seek 0))))))

(defun org-mpv-notes-open ()
  "Find and open mpv: link."
  (interactive)
  (save-excursion
    ;; move to next heading
    (unless (re-search-forward "^\\*+" nil t)
      ;; if no heading goto end
      (goto-char (point-max)))
    ;; then search backwards for links
    (let ((pos (re-search-backward "\\[\\[mpv:[^\n]*\\]\\]")))
      (when pos
        ;; when link is found play it
        (forward-char)
        (org-mpv-notes-play (org-element-context))))))

(defun org-mpv-notes-insert-note ()
  "Insert a heading with timestamp."
  (interactive)
  (org-insert-heading)
  (save-excursion
    (org-insert-property-drawer)
    (org-set-property "time" (org-timer-secs-to-hms (round (mpv-get-playback-position))))
    (org-set-property "mpv_path" (org-timer-secs-to-hms (round (mpv-get-property "path"))))))

(defun org-mpv-notes-insert-link ()
  (interactive)
  (let* ((path (mpv-get-property "path"))
         (time (mpv-get-playback-position))

         (h (floor (/ time 3600)))
         (m (floor (/ (mod time 3600) 60)))
         (s (floor (mod time 60)))
         (timestamp (format "%s:%s:%s" h m s)))
    (insert "[[" path "::" timestamp "][" timestamp "]]")))

(defun org-mpv-notes-replace-timestamp-with-link (link)
  (interactive "sLink:")
  (save-excursion
    (while (re-search-forward org-mpv-notes-timestamp-regex nil t)
      (skip-chars-backward ":[:digit:]" (point-at-bol))
      (looking-at org-mpv-notes-timestamp-regex)
      (let ((timestamp (match-string 0)))
        (delete-region (match-beginning 0) (match-end 0))
        (insert "[[" link "::" timestamp "][" timestamp "]]")))))

;;;###autoload
(define-minor-mode org-mpv-notes
  "Org minor mode for Note taking alongside audio and video.
Uses mpv.el to control mpv process"
  :keymap `((,(kbd "M-n i") . org-mpv-notes-insert-link)
            (,(kbd "M-n M-i") . org-mpv-notes-insert-note)
            (,(kbd "M-n u") . mpv-revert-seek)
            (,(kbd "M-n s") . org-mpv-notes-save-screenshot)
            (,(kbd "M-n o") . org-mpv-notes-open)
            (,(kbd "M-n k") . mpv-kill)
            (,(kbd "M-n M-s") . org-mpv-notes-screenshot-ocr))
  (if org-mpv-notes
      (org-mpv-notes-open)
    (mpv-kill)))

(provide 'org-mpv-notes)

;;; org-mpv-notes.el ends here
