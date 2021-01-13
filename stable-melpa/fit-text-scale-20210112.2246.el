;;; fit-text-scale.el --- Fit text by scaling -*- lexical-binding: t -*-

;; THIS FILE HAS BEEN GENERATED.



;; Author: Marco Wahl <marcowahlsoft@gmail.com>
;; Maintainer: Marco Wahl <marcowahlsoft@gmail.com>
;; Created: 2017
;; Version: 1.1.4
;; Package-Version: 20210112.2246
;; Package-Commit: 3f93650a8e8899114ea48048b7962210f1024862
;; Package-Requires: ((emacs "25.1"))
;; Keywords: convenience
;; URL: https://gitlab.com/marcowahl/fit-text-scale

;; Copyright (C) 2017-2021 Marco Wahl
;; 
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; 
;; You are too lazy to do the C-x C-+ + + +... - - - - ... + + - dance
;; all the time to see the FULL line in maximal font size?
;; 
;; You want a keystroke to see the whole buffer at once by changing the
;; font size?

;; 
;; ~fit-text-scale~ is an automation to set the scale so that the text
;; uses the maximal space to fit in the window.
;; 
;; Scale stands for the zoom of the font.
;; 
;; There are three functions:
;; - Choose the maximal text scale to still see the full line.
;; - Choose the maximal text scale to still see the full lines.
;; - Choose the maximal text scale to still see all lines of a buffer.

;; The following code in an init file binds the
;; functionality to keys. Of course you don't need
;; to use these bindings. Your can choose your own.
;; 
;; #+begin_src emacs-lisp
;; (global-set-key
;;  (kbd "C-x C-&")
;;  (lambda (&optional arg)
;;    (interactive "P")
;;    (cond
;;     ((equal arg '(4)) (fit-text-scale-max-font-size-fit-line))
;;     ((equal arg '(16)) (fit-text-scale-max-font-size-fit-line-up-to-cursor))
;;     ((and (region-active-p) (< (region-beginning) (region-end)))
;;      (save-restriction
;;        (narrow-to-region (region-beginning) (region-end))
;;        (fit-text-scale-max-font-size-fit-lines)))
;;     (t (fit-text-scale-max-font-size-fit-lines)))))
;; 
;; (global-set-key
;;  (kbd "C-x C-*")
;;  (lambda (&optional arg)
;;    (interactive "P")
;;    (if (and (region-active-p) (< (region-beginning) (region-end)))
;;        (save-restriction
;;          (narrow-to-region (region-beginning) (region-end))
;;          (fit-text-scale-max-font-size-fit-buffer))
;;      (fit-text-scale-max-font-size-fit-buffer))))
;; #+end_src
;; 
;; With these settings there is
;; 
;; - ~C-u C-x C-&~
;;   - Choose maximal text scale so that the current line still
;;     fits in the window.
;; - ~C-u C-u C-x C-&~
;;   - Choose maximal text scale so that the current line up to the cursor
;;     still fits in the window. This can be useful with visual-line-mode.
;; - ~C-x C-&~
;;   - Choose maximal text scale so that the longest line visible still
;;     fits in current window.
;;   - If region is active then only consider lines in the region.
;; - ~C-x C-*
;;   - Choose maximal text scale so that the vertical buffer content
;;     still fits into current window.
;;   - If region is active then only consider lines in the region.
;; - ~C-x C-0~ (Already given with standard Emacs.  This is good old
;;   ~text-scale-adjust~.)
;;   - Switch back to the default size when control about the sizes has
;;     been lost.
;; - Use e.g. ~C-x C-+ ====~ + - and ~C-x C-- -----~ - + for fine tuning.  (Also given.)
;; - ~C-g C-g C-g~... (hit the keyboard hard!) if something, hrm, hangs.

;; There are some parameters to fine tune the functionality.  Check it out with
;; 
;;     M-x customize-group fit-text-scale
;; 

;; ~fit-text-scale~ is available on melpa.
;; 
;; 
;; Or use the good old style:
;; 
;; - Download fit-text-scale.el.
;; 
;; - Add the lines (with YOUR path to fit-text-scale.el)
;; to your init file.
;; 
;; #+begin_src emacs-lisp
;; (push "/PATH/TO/fit-text-scale" load-path)
;; (require 'fit-text-scale)
;; #+end_src

;;; Code:


(require 'cl-lib) ; cl-incf, cl-assert


;; customizables

(defcustom fit-text-scale-hesitation 0.01
  "Duration to wait til next text scale change.
Smallest sane value is 0 which should result in the fastest
animation.  Only effective when `fit-text-scale-graphic-sugar' is on."
  :type 'number
  :group 'fit-text-scale)

(define-obsolete-variable-alias 'fit-text-scale-graphic-suger 'fit-text-scale-graphic-sugar "2020-02-13")

(defcustom fit-text-scale-graphic-sugar t
  "Animate the zoom.  `fit-text-scale-hesitation' controls the animation speed."
  :type 'boolean
  :group 'fit-text-scale)

(defcustom fit-text-scale-max-amount 23
  "Maximum achievable text scale with this program."
  :type 'number
  :group 'fit-text-scale)

(defcustom fit-text-scale-min-amount -12
  "Minimum achievable text scale with this program."
  :type 'number
  :group 'fit-text-scale)

(defcustom fit-text-scale-consider-max-number-lines 42
"Maximum number of lines to consider to choose the longest."
  :type 'integer
  :group 'fit-text-scale )


;; text scale wrapper

(require 'face-remap)  ; text-scale- functions

(defun fit-text-scale--increase (arg)
  "Increase text scale.  Possibly redisplay.
ARG stands for the amount.  1 is increase the smallest possible.
-1 is decrease."
  (text-scale-increase arg)
  (when fit-text-scale-graphic-sugar
    (sit-for fit-text-scale-hesitation)))


;; measurement

(defun fit-text-scale--line-length ()
  "Calculate line width containing point in chars."
  (save-excursion (end-of-line) (current-column)))

(defun fit-text-scale--buffer-height-fits-in-window-p ()
  "Return if buffer fits completely into the window."
  (save-excursion
    (goto-char (point-min))
    (sit-for 0)
    (posn-at-point (point-max))))


;; find longest line

;;;###autoload
(defun fit-text-scale-goto-visible-line-of-max-length-down ()
  "Set point into longest visible line looking downwards.
Take at most `fit-text-scale-consider-max-number-lines' lines into account."
  (interactive)
  (let (truncate-lines)
    (let* ((point-in-bottom-window-line
            (save-excursion (move-to-window-line -1) (point)))
           (n 0)
           (max-length (fit-text-scale--line-length))
           (target (point)))
      (while (and (< n fit-text-scale-consider-max-number-lines)
                  (< (point) point-in-bottom-window-line)
                  (not (eobp)))
        (let ((length-candidate (fit-text-scale--line-length)))
          (when (< max-length length-candidate)
            (setq max-length length-candidate)
            (setq target (point))))
        (forward-visible-line 1)
        (cl-incf n))
      target)))


;;;###autoload
(defun fit-text-scale-max-font-size-fit-line ()
  "Use the maximal text scale to fit the line in the window."
  (interactive)
  (text-scale-mode)
  (beginning-of-line)
  (let ((eol (progn (save-excursion (end-of-visible-line)
                                    (point)))))
    (cl-assert
     (<= (progn (save-excursion (end-of-visual-line) (point)))
         eol)
     (concat
      "programming logic error.  "
      "this shouldn't happen.  "
      "please report the issue."))
    (while (and (< text-scale-mode-amount fit-text-scale-max-amount)
                (= (progn (save-excursion (end-of-visual-line) (point))) eol))
      (fit-text-scale--increase 1))
    (while  (and (< fit-text-scale-min-amount text-scale-mode-amount)
                 (< (progn (save-excursion (end-of-visual-line) (point))) eol))
      (fit-text-scale--increase -1))))

;;;###autoload
(defun fit-text-scale-max-font-size-fit-lines ()
  "Use the maximal text scale to fit the lines in the window.
Actually only the first `fit-text-scale-consider-max-number-lines' are
considered."
  (interactive)
  (save-excursion
    (move-to-window-line 0)
    (goto-char (fit-text-scale-goto-visible-line-of-max-length-down))
    (fit-text-scale-max-font-size-fit-line)))

;;;###autoload
(defun fit-text-scale-max-font-size-fit-line-up-to-cursor ()
  "Use the maximal text scale to fit line up to cursor in the window.
Note: This can be helpful when in visual-line-mode and the lines are long."
  (interactive)
  (unless (bolp)
    (save-excursion
      (save-restriction
        (narrow-to-region
         (line-beginning-position)
         ;; the possible extension by one has been found to do the
         ;; right thing in visual-line-mode.
         (+ (point) (if (< (point) (line-end-position)) 1 0)))
        (fit-text-scale-max-font-size-fit-line)))))


;;;###autoload
(defun fit-text-scale-max-font-size-fit-buffer ()
  "Use the maximal text scale to fit the buffer in the window.
When at minimal text scale stay there and inform."
  (interactive)
  (save-excursion
    (while (and (fit-text-scale--buffer-height-fits-in-window-p)
                (< (or text-scale-mode-amount 0)
                   (text-scale-max-amount)))
      (fit-text-scale--increase 1))
    (while (and
            (not (fit-text-scale--buffer-height-fits-in-window-p))
            (< (1+ (text-scale-min-amount))
               (or text-scale-mode-amount 0)))
      (fit-text-scale--increase -1))
    (when (= (floor (text-scale-max-amount))
             (or text-scale-mode-amount 0))
      (message "At maximal text scale."))
    (when (= (floor (text-scale-min-amount))
             (or text-scale-mode-amount 0))
      (message "At minimal text scale."))))


(provide 'fit-text-scale)


;;; fit-text-scale.el ends here
