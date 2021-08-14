;;; snow.el --- Let it snow in Emacs!         -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2020  Adam Porter

;; Author: Adam Porter <adam@alphapapa.net>
;; URL: https://github.com/alphapapa/snow.el
;; Package-Version: 20210813.1902
;; Package-Commit: 4cd41a703b730a6b59827853f06b98d91405df5a
;; Version: 0.1-pre
;; Package-Requires: ((emacs "26.3"))
;; Keywords: games

;;;; License:

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

;;; Notes:

;; TODO: Add a fireplace and window panes looking out on the snowy
;; scene.  See <https://github.com/johanvts/emacs-fireplace>.

;; FIXME: If the pixel-display-width of " " and "❄" are not the same,
;; the columns in the buffer will dance around.  This is annoying and
;; was hard to track down, because it doesn't make any sense for it to
;; be the case when using a monospaced font, but apparently it can
;; happen (e.g. with "Fantasque Sans Mono").

;; FIXME: Change buffer height/width back to use the full window
;; (changed it to use 1- while debugging).

;; NOTE: Be sure to preserve whitespace in the `snow-background'
;; string, otherwise the text-properties will become corrupted and
;; cause an error on load.

;;; Commentary:

;; Let it snow in Emacs!  Command `snow' displays a buffer in which it
;; snows.  The storm varies in intensity, a gentle breeze blows at
;; times, and snow accumulates on the terrain in the scene.

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'color)
(require 'subr-x)

;;;; Variables

(defvar snow-flakes nil)

(defvar snow-amount 5)
(defvar snow-rate 0.09)
(defvar snow-timer nil)
(defvar snow-window-width nil)
(defvar snow-window-height nil)

(defvar snow-storm-frames nil)
(defvar snow-storm-reset-frame nil)
(defvar snow-storm-factor 1)
(defvar snow-storm-wind 0)

(cl-defstruct snow-flake
  x y mass string overlay)

;;;; Customization

(defgroup snow nil
  "Let it snow!"
  :group 'games
  :link '(url-link "https://github.com/alphapapa/snow.el"))

(defcustom snow-debug nil
  "Show debug info in mode line."
  :type 'boolean)

(defcustom snow-pile-factor 100
  "Snow is reduced in mass by this factor when it hits the ground.
The lower the number, the faster snow will accumulate."
  :type 'number)

(defcustom snow-show-background t
  "Show the `snow-backgrounds' scene."
  :type 'boolean)

(defcustom snow-backgrounds
  (list
   (cons 0 
	 #("                                       __                                                                                             
                                     _|__|_             __                                                                            
        /\\       /\\                   ('')            _|__|_                                                                          
       /  \\     /  \\                <( . )>            ('')                                                                           
       /  \\     /  \\               _(__.__)_  _   ,--<(  . )>                                                                         
      /    \\   /    \\              |       |  )),`   (   .  )                                                                         
       `||`     `||`               ==========='`       '--`-`                                                                         
" 39 41 (face (:foreground "black")) 172 178 (face (:foreground "black")) 190 193 (face (:foreground "black")) 278 280 (face (:foreground "green")) 287 289 (face (:foreground "green")) 308 309 (face (:foreground "white")) 309 311 (face (:foreground "black")) 311 312 (face (:foreground "white")) 324 330 (face (:foreground "black")) 412 413 (face (:foreground "green")) 413 416 (face (:foreground "green")) 421 425 (face (:foreground "green")) 441 442 (face (:foreground "brown")) 442 443 (face (:foreground "white")) 444 445 (face (:foreground "black")) 446 447 (face (:foreground "white")) 447 448 (face (:foreground "brown")) 460 461 (face (:foreground "white")) 461 463 (face (:foreground "black")) 463 464 (face (:foreground "white")) 547 560 (face (:foreground "green")) 576 579 (face (:foreground "white")) 579 580 (face (:foreground "black")) 580 583 (face (:foreground "white")) 586 587 (face (:foreground "black")) 590 593 (face (:foreground "brown")) 593 594 (face (:foreground "brown")) 594 595 (face (:foreground "white")) 597 598 (face (:foreground "black")) 599 600 (face (:foreground "white")) 600 601 (face (:foreground "brown")) 681 696 (face (:foreground "green")) 721 723 (face (:foreground "black")) 723 724 (face (:foreground "brown")) 724 725 (face (:foreground "brown")) 728 729 (face (:foreground "white")) 732 733 (face (:foreground "black")) 735 736 (face (:foreground "white")) 818 820 (face (:foreground "brown")) 827 829 (face (:foreground "brown")) 845 856 (face (:foreground "black")) 856 858 (face (:foreground "brown")) 865 871 (face (:foreground "gray"))))
   (cons 130
         #("         v         
        >X<        
         A         
        d$b        
      .d\\$$b.      
    .d$i$$\\$$b.    
       d$$@b       
      d\\$$$ib      
    .d$$$\\$$$b     
  .d$$@$$$$\\$$ib.  
      d$$i$$b      
     d\\$$$$@$b     
  .d$@$$\\$$$$$@b.  
.d$$$$i$$$\\$$$$$$b.
        ###        
        ###        
        ###        
" 0 9 (fontified t face (:foreground "gold")) 9 10 (fontified t face (:foreground "gold")) 19 20 (fontified t face (:foreground "gold")) 20 28 (fontified t face (:foreground "gold")) 28 30 (fontified t face (:foreground "gold")) 30 31 (fontified t face (:foreground "gold")) 39 40 (fontified t) 40 49 (fontified t face (:foreground "forest green")) 49 50 (fontified t face (:foreground "forest green")) 59 60 (fontified t face (:foreground "forest green")) 60 68 (fontified t face (:foreground "forest green")) 68 71 (fontified t face (:foreground "forest green")) 79 80 (fontified t face (:foreground "forest green")) 80 86 (fontified t face (:foreground "forest green")) 86 93 (fontified t face (:foreground "forest green")) 99 100 (fontified t face (:foreground "forest green")) 100 104 (fontified t face (:foreground "forest green")) 104 115 (fontified t face (:foreground "forest green")) 119 120 (fontified t face (:foreground "forest green")) 120 127 (fontified t face (:foreground "forest green")) 127 132 (fontified t face (:foreground "forest green")) 139 140 (fontified t face (:foreground "forest green")) 140 146 (fontified t face (:foreground "forest green")) 146 153 (fontified t face (:foreground "forest green")) 159 160 (fontified t face (:foreground "forest green")) 160 164 (fontified t face (:foreground "forest green")) 164 174 (fontified t face (:foreground "forest green")) 179 180 (fontified t face (:foreground "forest green")) 180 182 (fontified t face (:foreground "forest green")) 182 197 (fontified t face (:foreground "forest green")) 199 200 (fontified t face (:foreground "forest green")) 200 206 (fontified t face (:foreground "forest green")) 206 213 (fontified t face (:foreground "forest green")) 219 220 (fontified t face (:foreground "forest green")) 220 225 (fontified t face (:foreground "forest green")) 225 234 (fontified t face (:foreground "forest green")) 239 240 (fontified t face (:foreground "forest green")) 240 242 (fontified t face (:foreground "forest green")) 242 257 (fontified t face (:foreground "forest green")) 259 260 (fontified t face (:foreground "forest green")) 260 279 (fontified t face (:foreground "forest green")) 279 280 (fontified t) 280 288 (fontified t) 288 291 (fontified t face (:foreground "brown")) 299 300 (fontified t face (:foreground "brown")) 300 308 (fontified t face (:foreground "brown")) 308 311 (fontified t face (:foreground "brown")) 319 320 (fontified t face (:foreground "brown")) 320 328 (fontified t face (:foreground "brown")) 328 331 (fontified t face (:foreground "brown"))))
   (cons 80
         #("                              
                 _            
        ________|_|________   
       /\\        ______    \\  
      //_\\       \\    /\\    \\ 
     //___\\       \\__/  \\    \\
    //_____\\       \\ |[]|     \\
   //_______\\       \\|__|      \\
  /XXXXXXXXXX\\                  \\
 /_I_II  I__I_\\__________________\\
   I_I|  I__I_____[]_|_[]_____I
   I_II  I__I_____[]_|_[]_____I
   I II__I  I     XXXXXXX     I
~~~~~\"   \"~~~~~~~~~~~~~~~~~~~~~~~~
" 132 133 (face (:foreground "brown")) 162 165 (face (:foreground "brown")) 192 197 (face (:foreground "brown")) 208 210 (face (:foreground "cornflower blue")) 223 230 (face (:foreground "brown")) 254 264 (face (:foreground "saddle brown")) 288 289 (face (:foreground "saddle brown")) 289 290 (face (:foreground "brown")) 290 292 (face (:foreground "saddle brown")) 294 295 (face (:foreground "saddle brown")) 295 297 (face (:foreground "brown")) 297 298 (face (:foreground "saddle brown")) 300 318 (face (:foreground "gray50")) 323 324 (face (:foreground "saddle brown")) 324 325 (face (:foreground "brown")) 325 327 (face (:foreground "saddle brown")) 329 330 (face (:foreground "saddle brown")) 330 332 (face (:foreground "brown")) 332 333 (face (:foreground "saddle brown")) 333 338 (face (:foreground "brown")) 338 340 (face (:foreground "cornflower blue")) 343 345 (face (:foreground "cornflower blue")) 345 350 (face (:foreground "brown")) 350 351 (face (:foreground "saddle brown")) 355 356 (face (:foreground "saddle brown")) 356 357 (face (:foreground "brown")) 357 359 (face (:foreground "saddle brown")) 361 362 (face (:foreground "saddle brown")) 362 364 (face (:foreground "brown")) 364 365 (face (:foreground "saddle brown")) 365 370 (face (:foreground "brown")) 370 372 (face (:foreground "cornflower blue")) 375 377 (face (:foreground "cornflower blue")) 377 382 (face (:foreground "brown")) 382 383 (face (:foreground "saddle brown")) 387 388 (face (:foreground "saddle brown")) 388 389 (face (:foreground "brown")) 389 391 (face (:foreground "saddle brown")) 393 394 (face (:foreground "saddle brown")) 394 396 (face (:foreground "brown")) 396 397 (face (:foreground "saddle brown")) 397 402 (face (:foreground "brown")) 402 409 (face (:foreground "saddle brown")) 409 414 (face (:foreground "brown")) 414 415 (face (:foreground "saddle brown")) 416 421 (face (:foreground "DarkOliveGreen4")) 426 450 (face (:foreground "DarkOliveGreen4")))))
  "Background strings."
  :type '(repeat (alist :key-type (integer :tag "Offset from left window edge")
                        :value-type (string :tag "String"))))

(defcustom snow-pile-strings
  '((0.0 . " ")
    (0.03125 . ".")
    (0.0625 . "_")
    (0.125 . "▁")
    (0.25 . "▂")
    (0.375 . "▃")
    (0.5 . "▄")
    (0.625 . "▅")
    (0.75 . "▆")
    (0.875 . "▇")
    (1.0 . "█"))
  "Alist mapping snow pile percentages to characters.
Each position in the buffer may have an accumulated amount of
snow, displayed with these characters."
  :type '(alist :key-type float
                :value-type string))

(defcustom snow-storm-interval
  (lambda ()
    (max 1 (random 100)))
  "Ebb or flow the storm every this many frames."
  :type '(choice integer function))

(defcustom snow-storm-initial-factor
  (lambda ()
    (cl-random 1.0))
  "Begin snowing at this intensity."
  :type '(choice number function))

(defcustom snow-storm-wind-max 0.3
  "Maximum wind velocity."
  :type 'float)

;;;; Commands

;;;###autoload
(defun snow (&optional manual)
  "Let it snow!
If already snowing, stop.  If MANUAL (interactively, with
prefix), advance snow frames manually by pressing \"SPC\"."
  (interactive "P")
  (with-current-buffer (get-buffer-create "*snow*")
    (if snow-timer
        (progn
          (cancel-timer snow-timer)
          (setq snow-timer nil))
      ;; Start snowing.
      (switch-to-buffer (current-buffer))
      (buffer-disable-undo)
      (erase-buffer)
      (remove-overlays)
      (toggle-truncate-lines 1)
      (use-local-map (make-sparse-keymap))
      (local-set-key (kbd "SPC") (lambda ()
                                   (interactive)
                                   (snow--update-buffer (current-buffer))))
      (setq-local cursor-type nil)
      (setf snow-window-width (if snow-show-background
                                  (max (window-text-width (get-buffer-window (current-buffer) t))
                                       (cl-loop for (offset . background) in snow-backgrounds
                                                maximizing (+ (cl-loop for line in (split-string background "\n")
                                                                       maximizing (string-width line))
                                                              offset)))
                                (window-text-width (get-buffer-window (current-buffer) t)))
            ;; FIXME: Assumes that the backgrounds are less than the window height.
            snow-window-height (window-text-height (get-buffer-window (current-buffer) t))
            snow-flakes nil
            snow-storm-factor (cl-etypecase snow-storm-initial-factor
                                (function (funcall snow-storm-initial-factor))
                                (number snow-storm-initial-factor))
            snow-storm-frames 0
            snow-storm-wind 0
            snow-storm-reset-frame (cl-etypecase snow-storm-interval
                                     (function (funcall snow-storm-interval))
                                     (number snow-storm-interval))
            ;; Not sure how many of these are absolutely necessary,
            ;; but it seems to be working now.
            indicate-buffer-boundaries nil
	    fringe-indicator-alist '((truncation . nil)
				     (continuation . nil))
	    left-fringe-width 0
	    right-fringe-width 0)
      (goto-char (point-min))
      (save-excursion
        (dotimes (_i snow-window-height)
          ;; Fill buffer with spaces up to window size.
          (insert (make-string snow-window-width ? )
                  "\n"))
        (when snow-show-background
          (pcase-dolist (`(,col . ,string) snow-backgrounds)
	    (snow-insert-background :start-line -1 :start-col col :string string))))
      (unless manual
        (setq snow-timer
              (run-at-time nil snow-rate (apply-partially #'snow--update-buffer (get-buffer-create "*snow*"))))
        (setq-local kill-buffer-hook (lambda ()
                                       (when snow-timer
					 (cancel-timer snow-timer)
					 (setq snow-timer nil))))))))

;;;; Functions

(defsubst snow-clamp (min number max)
  "Return NUMBER clamped to between MIN and MAX, inclusive."
  (max min (min max number)))

(defsubst snow-flake-color (mass)
  "Return color name for a flake having MASS."
  (setf mass (snow-clamp 0 mass 100))
  (let ((raw (/ (+ mass 155) 255)))
    (color-rgb-to-hex raw raw raw 2)))

(defsubst snow-flake-mass-string (mass)
  "Return string for flake having MASS."
  (propertize (pcase mass
                ((pred (< 90)) "❄")
                ((pred (< 50)) "*")
                ((pred (< 10)) ".")
                (_ "."))
              'face (list :foreground (snow-flake-color mass))))

(defsubst snow-flake-within-sides-p (flake)
  "Return non-nil if FLAKE is within window's sides."
  (and (<= 0 (snow-flake-x flake))
       ;; FIXME: Eventually go up to the width rather than 2 less.
       (< (snow-flake-x flake) (- snow-window-width 2))))

(defsubst snow-flake-pos (flake)
  "Return buffer position of FLAKE."
  (save-excursion
    (goto-char (point-min))
    (forward-line (snow-flake-y flake))
    (forward-char (snow-flake-x flake))
    (point)))

(defsubst snow-flake-pos-below (flake)
  "Return buffer position below FLAKE, or nil."
  (save-excursion
    (goto-char (snow-flake-pos flake))
    (ignore-errors
      (let ((col (current-column)))
        (forward-line 1)
        (forward-char col)
        (point)))))

(defsubst snow-flake-landed-at (flake)
  "Return buffer position FLAKE landed at, or t if outside buffer."
  ;; FIXME: Eventually use full height rather than one less.
  (or (when (>= (snow-flake-y flake) (1- snow-window-height))
        ;; Flake hit bottom of buffer.
        (if (snow-flake-within-sides-p flake)
            ;; Flake within horizontal limit of buffer: return buffer position.
            (snow-flake-pos flake)
          ;; Flake outside horizontal limit of buffer: return t.
          t))
      (when-let ((pos-below (when (snow-flake-within-sides-p flake)
                              (snow-flake-pos-below flake))))
        ;; A position exists below the flake and within the buffer.
        (when (not (equal ?  (char-after pos-below)))
          ;; That position is not empty (i.e. not a space): return that position.
          pos-below))))

(defun snow--update-buffer (buffer)
  "Update snow in BUFFER."
  (with-current-buffer buffer
    (when (>= (cl-incf snow-storm-frames) snow-storm-reset-frame)
      (setf snow-storm-reset-frame (cl-etypecase snow-storm-interval
                                     (function (funcall snow-storm-interval))
                                     (number snow-storm-interval))
            snow-storm-factor (snow-clamp 0.1
                                          (+ snow-storm-factor
                                             (if (zerop (random 2))
                                                 -0.1 0.1))
                                          2)
            snow-storm-wind (snow-clamp (- snow-storm-wind-max)
                                        (+ snow-storm-wind
                                           (if (zerop (random 2))
                                               -0.05 0.05))
                                        snow-storm-wind-max)
            snow-storm-frames 0))
    (let ((num-new-flakes (if (< (cl-random 1.0) snow-storm-factor)
                              1 0)))
      (unless (zerop num-new-flakes)
        ;; FIXME: This can only produce one flake per frame, which isn't quite what I want.
        (setf snow-flakes (append snow-flakes (snow-new-flakes num-new-flakes (1- snow-window-width)))))
      (setq snow-flakes
            (cl-loop for flake in snow-flakes
                     for new-flake = (snow-flake-update flake)
                     when new-flake
                     collect new-flake)))
    (when snow-debug
      (setq mode-line-format (format "Flakes:%s  Frames:%s  Factor:%s  Wind:%s"
                                     (length snow-flakes) snow-storm-frames snow-storm-factor snow-storm-wind)))))

(defun snow-new-flakes (num cols)
  "Return NUM new flakes across COLS.
Also draws each flake."
  (cl-loop for i from 0 to num
           for x = (random cols)
           for mass = (float (* snow-storm-factor (random 100)))
           for flake = (make-snow-flake :x x :y 0 :mass mass :string (snow-flake-mass-string mass))
           do (snow-flake-draw flake)
           collect flake))

(defun snow-flake-update (flake)
  "Return updated FLAKE, or nil if it landed.
Piles flake if it lands within the buffer."
  (unless (zerop snow-storm-wind)
    ;; Wind.
    (when (<= (cl-random snow-storm-wind-max) (abs snow-storm-wind))
      (cl-incf (snow-flake-x flake) (round (copysign 1.0 snow-storm-wind)))))
  (when (and (> (random 100) (snow-flake-mass flake))
             ;; Easiest way to just reduce the chance of X movement is to add another condition.
             (> (random 3) 0))
    ;; Random floatiness.
    (cl-incf (snow-flake-x flake) (pcase (random 2)
                                    (0 -1)
                                    (1 1))))
  (when (> (random 100) (/ (- 100 (snow-flake-mass flake)) 3))
    ;; Gravity.
    (cl-incf (snow-flake-y flake)))
  (if-let ((landed-at (snow-flake-landed-at flake)))
      (progn
        ;; Flake hit bottom of window.
        (when (numberp landed-at)
          ;; Landed at position within window: add to pile.
          (snow-pile flake landed-at))
        (when (snow-flake-overlay flake)
          (delete-overlay (snow-flake-overlay flake)))
        ;; No more flake.
        nil)
    ;; Redraw flake
    (snow-flake-draw flake)
    ;; Return moved flake
    flake))

(defun snow-pile (flake pos-below)
  "Pile FLAKE having landed at POS-BELOW."
  (cl-labels ((landed-at (flake pos-below)
                         (let* ((mass-at-pos (or (get-text-property pos-below 'snow (current-buffer)) 0)))
                           (pcase mass-at-pos
                             ((pred (< 100))
                              ;; Position has more than 100 mass: land
                              ;; above it and return 0 mass.
                              (cons (snow-flake-pos flake) 0))
                             (_ (cons pos-below mass-at-pos))))))
    (pcase-let* ((`(,pos . ,ground-snow-mass) (landed-at flake pos-below))
		 (ground-snow-mass (+ ground-snow-mass (/ (snow-flake-mass flake) snow-pile-factor)))
		 (char (or (alist-get (/ ground-snow-mass 100) snow-pile-strings nil nil #'>)
                           (alist-get 1.0 snow-pile-strings nil nil #'eql)))
		 (color (pcase ground-snow-mass
			  ((pred (<= 100)) (snow-flake-color 100))
			  (_ (snow-flake-color ground-snow-mass))))
		 (ground-snow-string (propertize char 'face (list :foreground color))))
      (when ground-snow-string
        (setf (buffer-substring pos (1+ pos)) ground-snow-string))
      (add-text-properties pos (1+ pos) (list 'snow ground-snow-mass) (current-buffer)))))

(defun snow-flake-draw (flake)
  "Draw FLAKE when it's within the buffer.
If not, delete its overlay."
  (if-let ((pos (when (snow-flake-within-sides-p flake)
                  (snow-flake-pos flake))))
      ;; Flake within window: draw it.
      (if (snow-flake-overlay flake)
          (move-overlay (snow-flake-overlay flake) pos (1+ pos))
        (setf (snow-flake-overlay flake) (make-overlay pos (1+ pos)))
        (overlay-put (snow-flake-overlay flake) 'display (snow-flake-string flake)))
    ;; Flake outside window: delete its overlay.
    (when (snow-flake-overlay flake)
      (delete-overlay (snow-flake-overlay flake)))))

(cl-defun snow-insert-background (&key string (start-line 0) (start-col 0))
  "Insert STRING at START-LINE and START-COL."
  (let* ((lines (split-string string "\n"))
         (height (length lines))
         (start-line (pcase start-line
                       (-1 (- (line-number-at-pos (point-max)) height))
                       (_ start-line))))
    (cl-assert (>= (line-number-at-pos (point-max)) height))
    (when (string-empty-p (car (last lines)))
      ;; Remove final line break.
      (setf lines (butlast lines)))
    (save-excursion
      (goto-char (point-min))
      (forward-line start-line)
      (cl-loop for line in lines
	       for pos = (+ start-col (point))
               do (progn
                    (setf (buffer-substring pos (+ pos (length line))) line)
                    (forward-line 1))))))

;;;; Footer

(provide 'snow)

;; Ensure that the before-save-hook doesn't, e.g. delete-trailing-whitespace,
;; which breaks the background string.

;; Local Variables:
;; before-save-hook: nil
;; End:

;;; snow.el ends here
