;;; meta-presenter.el --- A simple multi-file presentation tool for Emacs

;; This file is not part of Emacs

;; Author: Mohammed Ismail Ansari <team.terminal@gmail.com>
;; Version: 1.1
;; Package-Version: 20210714.1658
;; Package-Commit: 4ab48dacea245b223a0ffd2723ece746bd61c0af
;; Keywords: productivity, presentation
;; Maintainer: Mohammed Ismail Ansari <team.terminal@gmail.com>
;; Created: 2014/12/22
;; Description: A simple multi-file presentation tool for Emacs
;; URL: http://ismail.teamfluxion.com
;; Compatibility: Emacs24


;; COPYRIGHT NOTICE
;;
;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
;; for more details.
;;

;;; Install:

;; Put this file on your Emacs-Lisp load path, add following into your
;; ~/.emacs startup file
;;
;;     (require 'meta-presenter)
;;
;; Create a directory that contains slides to be presented stored as files.
;; Name the files as the slide number followed by an underscore, followed by
;; the name of the slide. Below are some examples:
;;
;;     o   1_introduction.md
;;     o   2_getting-started.md
;;     o   3_advanced-features.md
;;
;; Create a separate title slide for the presentation, start the presentation
;; mode while viewing the file. For example, if the directory containing your
;; slides contains a *title.md* file, you can run
;; `meta-presenter-start-presentation` while having the file open in the buffer
;; where you would like the presentation to start. When the presentation starts,
;; you'll be taken to a buffer named *slide-show.md*.
;;
;; In order to move to the next slide press `C-c C-v`, to move back to the
;; previous slide press `C-c C-x`.
;;
;; As the slides are not read-only, you could perform annotations on them. To
;; revert the changes press `C-c C-c`.
;;

;;; Commentary:

;;     You can use this package to present a slide-show using Emacs.
;;     Presenting is as simple as creating slides and a title slide and
;;     running `meta-presenter-start-presentation`.
;;
;;  Overview of features:
;;
;;     o   Yet another presentation tool for Emacs
;;     o   Maintain slides as separate files
;;

;;; Code:

(defvar meta-presenter--current-directory)

(defvar meta-presenter--slide-count)

(defvar meta-presenter--current-slide-number)

(defvar meta-presenter--progress-percentage)

(defvar meta-presenter--index-file)

(defvar meta-presenter-enable-animations
  nil)

(defun meta-presenter--increment (n)
  "Increments a number."
  (1+ n))

(defun meta-presenter--decrement (n)
  "Decrements a number."
  (1- n))

(defun meta-presenter--identity (n)
  "Identity function."
  n)

;;;###autoload
(defun meta-presenter-start-presentation ()
  "Starts presentation mode."
  (interactive)
  (setq meta-presenter--current-directory
        (file-name-directory buffer-file-name))
  (setq meta-presenter--slide-count
        (length (file-expand-wildcards (concat meta-presenter--current-directory
                                               "*_*.md"))))
  (setq meta-presenter--index-file
        (file-name-nondirectory buffer-file-name))
  (setq meta-presenter--current-slide-number
        0)
  (switch-to-buffer (find-file-noselect "slide-show.md"))
  (erase-buffer)
  (insert-file-contents meta-presenter--index-file
                        nil)
  (beginning-of-buffer)
  (meta-presenter-mode))

;;;###autoload
(defun meta-presenter-move-to-next-slide ()
  "Moves to the next slide."
  (interactive)
  (cond ((not (= meta-presenter--current-slide-number
                 meta-presenter--slide-count)) (meta-presenter--move-to-slide-at-delta 1))
        (t (progn (message "End of slide-show!")))))

;;;###autoload
(defun meta-presenter-move-to-previous-slide ()
  "Moves to the previous slide."
  (interactive)
  (cond ((not (= meta-presenter--current-slide-number
                 1)) (meta-presenter--move-to-slide-at-delta -1))
        (t (progn (message "Already on the first slide!")))))

;;;###autoload
(defun meta-presenter-reload-current-slide ()
  "Reloads current slide."
  (interactive)
  (meta-presenter--move-to-slide-at-delta 0))

(defun meta-presenter--move-to-slide-at-delta (delta)
  "Moves to a slide at specified delta."
  (let ((slide-name (cond ((< delta
                               0) (meta-presenter--get-previous-slide-name))
                           ((> delta
                               0) (meta-presenter--get-next-slide-name))
                           (t (meta-presenter--get-slide-name meta-presenter--current-slide-number))))
        (slide-number-processor (cond ((< delta
                                           0) 'meta-presenter--decrement)
                                       ((> delta
                                           0) 'meta-presenter--increment)
                                       (t 'meta-presenter--identity))))
    (meta-presenter--slide-down)
    (erase-buffer)
    (meta-presenter--fill-in)
    (meta-presenter--paste-progress delta)
    (meta-presenter--paste-slide-contents slide-name)
    (meta-presenter--slide-up)
    (meta-presenter--set-current-slide-number (funcall slide-number-processor
                                                       meta-presenter--current-slide-number))))

(defun meta-presenter--paste-progress (delta)
  "Pastes progress-bar on the screen."
  (setq meta-presenter--progress-percentage
        (/ (* (+ meta-presenter--current-slide-number
                 delta)
              100)
           meta-presenter--slide-count))
  (beginning-of-buffer)
  (insert (make-string (/ (* (window-width)
                             meta-presenter--progress-percentage)
                          100)
                       ?|))
  (newline 2))

(defun meta-presenter--paste-slide-contents (slide-name)
  (insert-file-contents slide-name
                        nil))

(defun meta-presenter--slide-down ()
  "Slides down the current slide."
  (cond (meta-presenter-enable-animations (dotimes (y (frame-height))
                                             (beginning-of-buffer)
                                             (insert (make-string (- (window-width)
                                                                     2)
                                                                  ?|))
                                             (newline 1)
                                             (sit-for 0.002)))))

(defun meta-presenter--fill-in ()
  "Fills the current screen with fillers."
  (cond (meta-presenter-enable-animations (dotimes (y (frame-height))
                                             (insert (make-string (- (window-width)
                                                                     2)
                                                                  ?|))
                                             (newline 1)))))

(defun meta-presenter--slide-up ()
  "Slides up the next slide."
  (cond (meta-presenter-enable-animations (dotimes (y (frame-height))
                                             (beginning-of-buffer)
                                             (kill-line)
                                             (kill-line)
                                             (sit-for 0.002)))))

(defun meta-presenter--set-current-slide-number (n)
  "Updates the current slide number."
  (setq meta-presenter--current-slide-number
        n))

(defun meta-presenter--get-next-slide-number ()
  "Gets the next slide number."
  (1+ meta-presenter--current-slide-number))

(defun meta-presenter--get-previous-slide-number ()
  "Gets the previous slide number."
  (1- meta-presenter--current-slide-number))

(defun meta-presenter--get-next-slide-name ()
  "Gets the next slide filename."
  (car (file-expand-wildcards (concat meta-presenter--current-directory
                                      (number-to-string (meta-presenter--get-next-slide-number))
                                      "_*"))))

(defun meta-presenter--get-slide-name (n)
  "Gets the slide name for a specified slide number."
  (car (file-expand-wildcards (concat meta-presenter--current-directory
                                      (number-to-string n)
                                      "_*"))))

(defun meta-presenter--get-previous-slide-name ()
  "Gets the previous slide filename."
  (car (file-expand-wildcards (concat meta-presenter--current-directory
                                      (number-to-string (meta-presenter--get-previous-slide-number))
                                      "_*"))))

;;;###autoload
(define-minor-mode meta-presenter-mode
  "Toggles meta-presenter-mode."
  :init-value nil
  :lighter " meta-presenter"
  :keymap '(("\C-c\C-v" . meta-presenter-move-to-next-slide)
            ("\C-c\C-x" . meta-presenter-move-to-previous-slide)
            ("\C-c\C-c" . meta-presenter-reload-current-slide)))

(provide 'meta-presenter)

;;; meta-presenter.el ends here
