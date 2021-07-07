;;; highlight-context-line.el --- Improve orientation when scrolling

;; Copyright (C) 2002-2017 by Stefan Kamphausen

;; Author: Stefan Kamphausen <www.skamphausen.de>
;; Homepage: https://github.com/ska2342/highlight-context-line/
;; Created: 2002
;; Version: 2.0
;; Package-Version: 20181122.2203
;; Package-Commit: 6b334e8207c780835a05b6909b4d826898c33d26
;; Keywords: faces, services, user

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This minor mode highlights the last visible line when scrolling
;; full windows.  It was inspired by the postscript viewer gv which
;; does a similar thing using a line across the screen.  It honours the
;; variable next-screen-context-lines.
;;
;; Enable it for the current session with
;;     M-x highlight-context-line-mode
;; or permanently by putting
;;     (highlight-context-line-mode 1)
;; in your init file.

;;; ChangeLog

;; 2.0   March 2017
;;       - Total rewrite
;;       - No more XEmacs support, I am afraid
;; 1.5   January  2003
;;       - GNU Emacs compatibility due to request of
;;         Sami Salkosuo (http://members.fortunecity.com/salkosuo)
;;       - untabify file
;; 1.3   December 2002
;;       CVS, "official" webpage
;;
;; Written in 2002, the year I finally started writing some serious
;; elisp

;;; Code:

(defvar highlight-context-line-version "2.0beta3"
  "Version number of highlight-context-line.")

(defgroup highlight-context-line nil
  "Highlight last visible line when scrolling."
  :tag "Highlight Context"
  :link '(url-link
          :tag "Home Page"
          "https://www.github.com/ska2342/highlight-context-line/")
  :link '(emacs-commentary-link
          :tag "Commentary in highlight-context-line.el"
          "highlight-context-line.el")
  :prefix "highlight-context-line-"
  :group 'convenience)

;; I wanted :underline t, but for some reason that does not underline
;; to the window edge, while background changes do.
(defface highlight-context-line-face
  '((t (:inherit highlight)))
    "Face used to highlight the context line."
    :group 'highlight-context-line)

(defvar highlight-context-line-overlay
  ;; init somewhere, will be moved later
  (make-overlay 1 1)
  "Overlay to use for highlighting.")

(overlay-put highlight-context-line-overlay
             'face 'highlight-context-line-face)

;;;###autoload
(define-minor-mode highlight-context-line-mode
  "Toggle highlighting of context line when scrolling.
With a prefix argument ARG, enable the mode if ARG is positive,
and disable it otherwise.  If called from Lisp, enable the mode
if ARG is omitted or nil.

When scrolling a buffer up this minor mode highlights the line
that was at the top of the window before scrolling. When
scrolling down, the bottommost line of the window at start of
scrolling is highlighted. The respective line is considered
the context line."
  :group 'highlight-context-line
  (if highlight-context-line-mode
      (progn
        (add-hook 'post-command-hook
                  #'highlight-context-line-highlight)
        (add-hook 'pre-command-hook
                  #'highlight-context-line-unhighlight))
    (remove-hook 'post-command-hook
              #'highlight-context-line-highlight)
    (remove-hook 'pre-command-hook
              #'highlight-context-line-unhighlight)))


(defun highlight-context-line-get-scroll-direction ()
  "Detects scrolling and direction.
Returns 1 for scroll up, -1 for scroll down and nil if not
scrolling at all."
  (cond
   ((eq this-command 'scroll-up-command) 1)
   ((eq this-command 'scroll-down-command) -1)))

(defun highlight-context-line-highlight* (direction)
  "Find the line to highlight in DIRECTION and move the overlay."
  (save-excursion
    ;; Jump to the line we want to highlight
    (move-to-window-line (* direction
                            next-screen-context-lines))
    ;; Overlay this line
    (let ((beg (line-beginning-position))
          ;; why 2 for the next line is beyond me
          (end (line-beginning-position 2)))
      (move-overlay highlight-context-line-overlay beg end))))

(defun highlight-context-line-unhighlight ()
  "Delete the overlay again."
  (ignore-errors
    (when highlight-context-line-overlay
      (delete-overlay highlight-context-line-overlay))))

(defun highlight-context-line-highlight ()
  "Highlight the context line after scrolling.
Context line is the last line that was visible before starting to
scroll in the respective direction."
  (ignore-errors
      (let ((scroll-direction
             (highlight-context-line-get-scroll-direction)))
        (when scroll-direction
          ;; it was a scrolling
          (highlight-context-line-highlight* scroll-direction)))))


(provide 'highlight-context-line)
;;; highlight-context-line.el ends here
