;;; highlight-thing.el --- Minimalistic minor mode to highlight current thing under point.

;; Copyright (c) 2014-2017 Felix Geller

;; Author: Felix Geller <fgeller@gmail.com>
;; Keywords: highlight thing symbol
;; Package-Version: 20221126.2305
;; Package-Commit: b9bb6e49fc20d2e1f688c2645f6f6653208145de
;; URL: https://github.com/fgeller/highlight-thing.el

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Global minor mode to highlight the current thing under point. Uses built-in
;; thingatpt and hi-lock functionality to identify the thing under point and
;; highlight it. Does not require font-lock to be enabled as hi-lock falls back
;; to overlays.

;; More information: https://github.com/fgeller/highlight-thing.el

(require 'thingatpt)

(defcustom highlight-thing-what-thing 'symbol
  "What kind of thing to highlight. (cf. `thing-at-point')
`region` to highlight other occurrences of the currently active
region is available in addition to the regular `thing-at-point`
functionality."
  :type '(choice (const :tag "Symbol" symbol)
                 (const :tag "Word" word)
                 (const :tag "Sexp" sexp)
                 (const :tag "Sentence" sentence)
                 (const :tag "List" list)
                 (const :tag "Line" line)
                 (const :tag "Number" number)
                 (const :tag "Page" page)
                 (const :tag "Whitespace" whitespace)
                 (const :tag "defun" defun)
                 (const :tag "File name" filename)
                 (const :tag "URL" url)
                 (const :tag "Email" email)
                 (const :tag "Region" region))
  :group 'highlight-thing)

(defcustom highlight-thing-limit-to-defun nil
  "Limit highlighting to occurrences in current defun. Relies on `beginning-of-defun` and `end-of-defun`."
  :type 'boolean
  :group 'highlight-thing)

(defcustom highlight-thing-limit-to-region-in-large-buffers-p nil
  "Limit highlighting to occurrences in surrounding lines in large buffers to reduce load of highlighting. Consider `highlight-thing-narrow-region-lines' for customizing the size of the region to narrow to and `highlight-thing-large-buffer-limit' for when to start narrowing."
  :type 'boolean
  :group 'highlight-thing)

(defcustom highlight-thing-narrow-region-lines 15
  "Line count to narrow region to. More specifically, the region will be double the given count, extending `highlight-thing-narrow-region-lines' above and below point by the given line count. cf. `highlight-thing-limit-to-region-in-large-buffers-p'."
  :type 'integer
  :group 'highlight-thing)

(defcustom highlight-thing-large-buffer-limit 5000
  "If `buffer-size' exceeds this character count a buffer is considered large enough to narrow the a region surrounding point before highlighting. cf. `highlight-thing-limit-to-region-in-large-buffers-p'."
  :type 'integer
  :group 'highlight-thing)

(defcustom highlight-thing-case-sensitive-p nil
  "Matching occurrences should be case sensitive if non-nil. Falls back to `case-fold-search` when nil."
  :type 'boolean
  :group 'highlight-thing)

(defcustom highlight-thing-exclude-thing-under-point nil
  "Highlight occurrences of thing under point but thing under point."
  :type 'boolean
  :group 'highlight-thing)

(defcustom highlight-thing-delay-seconds 0.5
  "Seconds to wait before highlighting thing at point."
  :type 'float
  :group 'highlight-thing)

(defcustom highlight-thing-excluded-major-modes nil
  "List of major modes to exclude from highlighting."
  :type '(repeat symbol)
  :group 'highlight-thing)

(defcustom highlight-thing-prefer-active-region nil
  "Highlights active region when active otherwise `highlight-thing-what-thing'."
  :type 'boolean
  :group 'highlight-thing)

(defcustom highlight-thing-ignore-list nil
  "List of strings that should not be highlighted."
  :type '(repeat string)
  :group 'highlight-thing)

(defcustom highlight-thing-all-visible-buffers-p nil
  "Highlights thing in visible buffers in all visible frames rather than only the selected one."
  :type 'boolean
  :group 'highlight-thing)

(defface highlight-thing
  '((t (:inherit 'hi-yellow)))
  "Face that is used to highlight things."
  :group 'highlight-thing)

(defvar highlight-thing-last-regex nil
  "Last highlighted thing.")

(defvar highlight-thing-last-buffer nil
  "Buffer where last thing was highlighted.")

(defvar highlight-thing-last-all-visible-buffers-p nil
  "Whether all visible buffers were highlighted last time.")

(defvar highlight-thing-timer nil
  "Timer that triggers highlighting.")

(defun highlight-thing-timer-delay-changed-p ()
  (not (time-equal-p (timer--time highlight-thing-timer)
					 (time-convert highlight-thing-delay-seconds))))

(defun highlight-thing-loop ()
  (when highlight-thing-mode
	(when (and highlight-thing-timer
			   (highlight-thing-timer-delay-changed-p))
		(timer-set-idle-time highlight-thing-timer highlight-thing-delay-seconds t))
    (highlight-thing-do)))

(defun highlight-thing-regexp (thing)
  (cond
   ((highlight-thing-should-highlight-region-p) (regexp-quote thing))
   ((get highlight-thing-what-thing 'highlight-thing-regex-fn)
    (funcall (get highlight-thing-what-thing 'highlight-thing-regex-fn) thing))
   ((eq highlight-thing-what-thing 'symbol) (concat "\\_<" (regexp-quote thing) "\\_>"))
   ((eq highlight-thing-what-thing 'word) (concat "\\<" (regexp-quote thing) "\\>"))
   (t (regexp-quote thing))))

(defun highlight-thing-remove-last ()
  (when highlight-thing-last-regex
    (when (or highlight-thing-all-visible-buffers-p
	      highlight-thing-last-all-visible-buffers-p)
      (mapc 'highlight-thing-remove-last-buffer-do (highlight-thing-list-visible-buffers)))
    (when (and highlight-thing-last-buffer
	       (buffer-live-p highlight-thing-last-buffer))
      (highlight-thing-remove-last-buffer-do highlight-thing-last-buffer))))

(defun highlight-thing-remove-last-buffer-do (buf)
  (with-current-buffer buf (hi-lock-unface-buffer highlight-thing-last-regex)))

(defun highlight-thing-should-highlight-p ()
  (and (not (minibufferp))
       (not (member major-mode highlight-thing-excluded-major-modes))))

(defun highlight-thing-should-narrow-to-defun-p ()
  (and highlight-thing-limit-to-defun
       (bounds-of-thing-at-point 'defun)))

(defun highlight-thing-should-narrow-to-region-p ()
  (and highlight-thing-limit-to-region-in-large-buffers-p
       (> (buffer-size) highlight-thing-large-buffer-limit)))

(defun highlight-thing-narrow-bounds ()
  (let (start end)
    (save-excursion
      (beginning-of-line)
      (line-move (* -1 highlight-thing-narrow-region-lines) 'no-error)
      (setq start (point)))
    (save-excursion
      (beginning-of-line)
      (line-move highlight-thing-narrow-region-lines 'no-error)
      (end-of-line)
      (setq end (point)))
    (cons start end)))

(defun highlight-thing-get-active-region ()
  (when (region-active-p)
    (buffer-substring (point) (mark))))

(defun highlight-thing-should-highlight-region-p ()
  (or (eq highlight-thing-what-thing 'region)
      (and highlight-thing-prefer-active-region
           (use-region-p))))

(defun highlight-thing-get-thing-at-point ()
  (let ((thing (if (highlight-thing-should-highlight-region-p) (highlight-thing-get-active-region)
                 (thing-at-point highlight-thing-what-thing))))
    (unless (member thing highlight-thing-ignore-list)
      thing)))

(defun highlight-thing-remove-overlays-at-point (regex)
  (let* ((bounds (if (region-active-p) (cons (region-beginning) (region-end))
		               (bounds-of-thing-at-point highlight-thing-what-thing)))
	       (start (car bounds))
	       (end (cdr bounds)))
    (remove-overlays start end 'hi-lock-overlay-regexp regex)
    (remove-overlays start end 'hi-lock-overlay t)
    (remove-overlays start end 'face 'highlight-thing)))

(defun highlight-thing-do ()
  (interactive)
  (let ((thing (highlight-thing-get-thing-at-point))
        (font-lock-mode nil))
    (highlight-thing-remove-last)
    (when (and (highlight-thing-should-highlight-p)
	       thing
	       (not (string= "" thing)))
      (let ((regex (highlight-thing-regexp thing))
	    (bufs (if highlight-thing-all-visible-buffers-p (highlight-thing-list-visible-buffers) (list (current-buffer)))))
	(mapc (lambda (buf) (highlight-thing-buffer-do buf regex)) bufs)
	(setq highlight-thing-last-all-visible-buffers-p highlight-thing-all-visible-buffers-p)
        (setq highlight-thing-last-buffer (current-buffer))
        (setq highlight-thing-last-regex regex)))))

(defun highlight-thing-buffer-do (buf regex)
  (with-current-buffer buf
    (save-restriction
      (widen)
      (cond ((highlight-thing-should-narrow-to-defun-p)
	     (narrow-to-defun))
	    ((highlight-thing-should-narrow-to-region-p)
	     (let ((bounds (highlight-thing-narrow-bounds)))
	       (narrow-to-region (car bounds) (cdr bounds)))))
      (highlight-thing-call-highlight-regexp regex)
      (when highlight-thing-exclude-thing-under-point (highlight-thing-remove-overlays-at-point regex)))))

(defun highlight-thing-call-highlight-regexp (regex)
  (unless (string= "" regex)
	(let ((case-fold-search (if highlight-thing-case-sensitive-p nil case-fold-search)))
	  (highlight-regexp regex 'highlight-thing))))

(defun highlight-thing-mode-maybe-activate ()
  (when (highlight-thing-should-highlight-p)
    (highlight-thing-mode 1)))

(defun highlight-thing-schedule-timer ()
  (if highlight-thing-timer
	  (when (highlight-thing-timer-delay-changed-p)
		(timer-set-idle-time highlight-thing-timer highlight-thing-delay-seconds t))
    (setq highlight-thing-timer
          (run-with-idle-timer highlight-thing-delay-seconds t 'highlight-thing-loop))))

(defun highlight-thing-list-visible-buffers ()
  (mapcan (lambda (f)
	    (mapcar (lambda (w) (window-buffer w)) (window-list f)))
	  (visible-frame-list)))

;;;###autoload
(define-minor-mode highlight-thing-mode
  "Minor mode that highlights things at point"
  :lighter " hlt"
  :group 'highlight-thing
  (if highlight-thing-mode
      (highlight-thing-schedule-timer)
    (highlight-thing-remove-last)))

;;;###autoload
(define-globalized-minor-mode global-highlight-thing-mode
  highlight-thing-mode
  highlight-thing-mode-maybe-activate
  :group 'highlight-thing)

(provide 'highlight-thing)

;;; highlight-thing.el ends here
