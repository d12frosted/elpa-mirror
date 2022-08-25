;;; flappymacs.el --- flappybird clone for emacs

;; Copyright (C) 2014-2017 Takayuki Sato

;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the "Software"), to deal
;; in the Software without restriction, including without limitation the rights
;; to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
;; copies of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
;; OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;; Author: Takayuki Sato
;; Created: 10 July 2014
;; Keywords: games
;; Package-Version: 20171023.1004
;; Package-Commit: fac0011983251d5c44f4ed1eacac03f5de3caac4
;; Version: 0.1.0
;; URL: https://github.com/taksatou/flappymacs

;;; Commentary:
;;
;; This is a clone of FlappyBird for emacs inspired by flappyvird-vim (https://github.com/mattn/flappyvird-vim).
;; Most codes are derived from pong.el.
;;
;;; Usage
;; 
;; Put flappymacs.el to load path, and then type `M-x flappymacs`.
;; Default keybinds are as follows.
;; 
;; * space: jump
;; * p: pause/resume
;; * q: quit
;; * r: retry


;;; Code:
(require 'cl)
(require 'gamegrid)

;;; Customization

(defgroup flappymacs nil
  "Emacs-Lisp implementation of the classical game flappymacs."
  :tag "Flappymacs"
  :group 'games)

(defcustom flappymacs-buffer-name "*Flappymacs*"
  "Name of the buffer used to play."
  :group 'flappymacs
  :type '(string))

(defcustom flappymacs-timer-delay 0.05
  "Time to wait between every cycle."
  :group 'flappymacs
  :type 'number)

(defcustom flappymacs-gravity 0.3
  "World gravity."
  :group 'flappymacs
  :type 'number)

(defcustom flappymacs-flap-power -1.5
  "Flap power."
  :group 'flappymacs
  :type 'number)

(defcustom flappymacs-bird-x-position 10
  "Bird position from the left end."
  :group 'flappymacs
  :type 'number)

(defcustom flappymacs-wall-interval 12
  "Wall width and interval."
  :group 'flappymacs
  :type 'number)

(defcustom flappymacs-slit-height 8
  "Wall slit height."
  :group 'flappymacs
  :type 'number)

(defcustom flappymacs-blank-color "black"
  "Color used for background."
  :group 'flappymacs
  :type 'color)

(defcustom flappymacs-wall-color "yellow"
  "Color used for wall."
  :group 'flappymacs
  :type 'color)

(defcustom flappymacs-bird-color "red"
  "Color used for the bird."
  :group 'flappymacs
  :type 'color)

(defcustom flappymacs-border-color "white"
  "Color used for flappymacs borders."
  :group 'flappymacs
  :type 'color)

(defcustom flappymacs-width 70
  "Width of the playfield."
  :group  'flappymacs
  :type '(integer))

(defcustom flappymacs-height 30
  "Height of the playfield."
  :group  'flappymacs
  :type '(integer))

(defcustom flappymacs-quit-key "q"
  "Key to press to quit flappymacs."
  :group 'flappymacs
  :type '(restricted-sexp :match-alternatives (stringp vectorp)))

(defcustom flappymacs-pause-key "p"
  "Key to press to pause flappymacs."
  :group 'flappymacs
  :type '(restricted-sexp :match-alternatives (stringp vectorp)))

(defcustom flappymacs-resume-key "p"
  "Key to press to resume flappymacs."
  :group 'flappymacs
  :type '(restricted-sexp :match-alternatives (stringp vectorp)))

(defcustom flappymacs-restart-key "r"
  "Key to press to restart flappymacs."
  :group 'flappymacs
  :type '(restricted-sexp :match-alternatives (stringp vectorp)))

(defcustom flappymacs-flap-key (kbd "SPC")
  "Key to press to flap."
  :group 'flappymacs
  :type '(restricted-sexp :match-alternatives (stringp vectorp)))

(defvar flappymacs-mode-map
  (let ((map (make-sparse-keymap 'flappymacs-mode-map)))
    (define-key map flappymacs-flap-key 'flappymacs-flap)
    (define-key map flappymacs-quit-key 'flappymacs-quit)
    (define-key map flappymacs-pause-key 'flappymacs-pause)
    (define-key map flappymacs-restart-key 'flappymacs-restart)
    map)
  "Modemap for flappymacs-mode.")

;; coloes

(defvar flappymacs-blank-options
  '(((glyph colorize)
     (t ?\040))
    ((color-x color-x)
     (mono-x grid-x)
     (color-tty color-tty))
    (((glyph color-x) [0 0 0])
     (color-tty flappymacs-blank-color))))

(defvar flappymacs-wall-options
  '(((glyph colorize)
     (emacs-tty ?O)
     (t ?\040))
    ((color-x color-x)
     (mono-x mono-x)
     (color-tty color-tty)
     (mono-tty mono-tty))
    (((glyph color-x) [1 1 0])
     (color-tty flappymacs-wall-color))))

(defvar flappymacs-bird-options
  '(((glyph colorize)
     (t ?\*))
    ((color-x color-x)
     (mono-x grid-x)
     (color-tty color-tty))
    (((glyph color-x) [1 0 0])
     (color-tty flappymacs-bird-color))))

(defvar flappymacs-border-options
  '(((glyph colorize)
     (t ?\+))
    ((color-x color-x)
     (mono-x grid-x)
     (color-tty color-tty))
    (((glyph color-x) [0.5 0.5 0.5])
     (color-tty flappymacs-border-color))))

(defconst flappymacs-blank 0)
(defconst flappymacs-wall 1)
(defconst flappymacs-bird 2)
(defconst flappymacs-border 3)

(defun flappymacs-display-options ()
  "Computes display options (required by gamegrid for colors)."
  (let ((options (make-vector 256 nil)))
    (dotimes (c 256)
      (aset options c
            (cond ((= c flappymacs-blank)
                   flappymacs-blank-options)
                  ((= c flappymacs-wall)
                   flappymacs-wall-options)
                  ((= c flappymacs-bird)
                   flappymacs-bird-options)
                  ((= c flappymacs-border)
                   flappymacs-border-options)
                  (t
                   '(nil nil nil)))))
    options))

;;; game variables

(defvar flappymacs-next-open? nil "comming field state.")
(defvar flappymacs-counter 0 "state counter.")
(defvar flappymacs-next-field nil "next field.")
(defvar flappymacs-bird-height 0 "bird height.")
(defvar flappymacs-bird-vector 0 "bird vector.")
(defvar flappymacs-max-score 0 "max score.")
(defvar flappymacs-score 0 "score.")

;;; game logic

(defun flappymacs-init-buffer ()
  "Initialize flappymacs buffer and draw stuff thanks to gamegrid library."
  (interactive)
  (get-buffer-create flappymacs-buffer-name)
  (switch-to-buffer flappymacs-buffer-name)
  (use-local-map flappymacs-mode-map)

  (setq gamegrid-use-glyphs t)
  (setq gamegrid-use-color t)
  (gamegrid-init (flappymacs-display-options))


  (gamegrid-init-buffer flappymacs-width
                        (+ 2 flappymacs-height)
                        ?\s)

  (let ((buffer-read-only nil))
    (dotimes (y flappymacs-height)
      (dotimes (x flappymacs-width)
        (gamegrid-set-cell x y flappymacs-border)))
    
    (loop for y from 1 to (- flappymacs-height 2) do
          (loop for x from 1 to (- flappymacs-width 2) do
                (gamegrid-set-cell x y flappymacs-blank)))))


(defun flappymacs-update-game (flappymacs-buffer)
  "\"Main\" function for flappymacs.
It is called every flappymacs-cycle-delay seconds and updates
wall and bird positions.  It is responsible of collision
detection."
  (if (not (eq (current-buffer) flappymacs-buffer)) (flappymacs-pause)
    (progn
      ;; (message (format "update bird(%f, %f) %d, %s"
      ;;                  flappymacs-bird-height flappymacs-bird-vector
      ;;                  flappymacs-counter flappymacs-next-field))

      ;; update params
      (cond ((<= flappymacs-counter 0)
             (setq flappymacs-counter flappymacs-wall-interval)
             (setq flappymacs-next-open? (not flappymacs-next-open?))
             (if (not flappymacs-next-open?)
                 (let ((pos (random (- flappymacs-height 4 flappymacs-slit-height))))
                   (setq flappymacs-score (1+ flappymacs-score))
                   (flappymacs-update-score)
                   (loop for y from 0 to pos do (aset flappymacs-next-field y flappymacs-wall))
                   (loop for y from (+ pos 1) to (+ pos flappymacs-slit-height)
                         do (aset flappymacs-next-field y flappymacs-blank))
                   (loop for y from (+ pos flappymacs-slit-height 1) to (- flappymacs-height 3)
                         do (aset flappymacs-next-field y flappymacs-wall)))))
            (t (setq flappymacs-counter (1- flappymacs-counter))))

      ;; update the bird
      (gamegrid-set-cell flappymacs-bird-x-position (floor flappymacs-bird-height) flappymacs-blank)
      (setq flappymacs-bird-height (max (+ flappymacs-bird-height flappymacs-bird-vector) 1))
      (setq flappymacs-bird-vector (+ flappymacs-bird-vector flappymacs-gravity))

      (cond ((or (< flappymacs-bird-height 1)
                 (> flappymacs-bird-height (- flappymacs-height 1))
                 (eq (gamegrid-get-cell flappymacs-bird-x-position (floor flappymacs-bird-height)) flappymacs-wall))
             ;; detect collision
             (gamegrid-set-cell flappymacs-bird-x-position (floor flappymacs-bird-height) flappymacs-bird)
             (message "Gameover!")
             (if (> flappymacs-score flappymacs-max-score)
                 (setq flappymacs-max-score flappymacs-score))
             (cancel-function-timers 'flappymacs-update-game))
            (t
             ;; redraw the bird
             (gamegrid-set-cell flappymacs-bird-x-position (floor flappymacs-bird-height) flappymacs-bird)

             ;; update wall
             (loop
              for y from 1 to (- flappymacs-height 2) do
              (loop
               for x from 1 to (- flappymacs-width 3) do
               (let ((cell (gamegrid-get-cell x y))
                     (rcell (gamegrid-get-cell (+ x 1) y)))
                 (cond
                  ((and (eq cell flappymacs-blank) (eq rcell flappymacs-wall))
                   (gamegrid-set-cell x y flappymacs-wall))
                  ((and (eq cell flappymacs-wall) (not (eq rcell flappymacs-wall)))
                   (gamegrid-set-cell x y flappymacs-blank)))
                 )))

             ;; insert next field
             (let ((x (- flappymacs-width 2)))
               (loop for y from 1 to (- flappymacs-height 2) do
                     (if flappymacs-next-open?
                         (gamegrid-set-cell x y flappymacs-blank)
                       (gamegrid-set-cell x y (aref flappymacs-next-field (- y 1))))))))

      )))

(defun flappymacs-update-score ()
  "Update score and print it on bottom of the game grid."
  (let* ((string (format "Score: %d (Best: %d)" flappymacs-score flappymacs-max-score))
         (len (length string)))
    (dotimes (x len)
      (if (string-equal (buffer-name (current-buffer)) flappymacs-buffer-name)
          (gamegrid-set-cell x flappymacs-height (aref string x))))))

(defun flappymacs-pause ()
  "Pause the game."
  (interactive)
  (gamegrid-kill-timer)
  ;; Oooohhh ugly.  I don't know why, gamegrid-kill-timer don't do the
  ;; jobs it is made for.  So I have to do it "by hand".  Anyway, next
  ;; line is harmless.
  (cancel-function-timers 'flappymacs-update-game)
  (define-key flappymacs-mode-map flappymacs-resume-key 'flappymacs-resume))

(defun flappymacs-resume ()
  "Resume a paused game."
  (interactive)
  (define-key flappymacs-mode-map flappymacs-pause-key 'flappymacs-pause)
  (gamegrid-start-timer flappymacs-timer-delay 'flappymacs-update-game))

(defun flappymacs-restart ()
  "Retry the game."
  (interactive)
  (flappymacs-init))

(defun flappymacs-quit ()
  "Quit the game and kill the flappymacs buffer."
  (interactive)
  (gamegrid-kill-timer)
  ;; Be sure not to draw things in another buffer and wait for some time.
  (run-with-timer flappymacs-timer-delay nil 'kill-buffer flappymacs-buffer-name))

(defun flappymacs-flap ()
  "Flap the bird."
  (interactive)
  (setq flappymacs-bird-vector flappymacs-flap-power))

(defun flappymacs-init ()
  "Initialize a game"

  (add-hook 'kill-buffer-hook 'flappymacs-quit nil t)

  (setq flappymacs-next-open? nil)
  (setq flappymacs-score 0)
  (setq flappymacs-counter 0)
  (setq flappymacs-next-field (make-vector (- flappymacs-height 2) flappymacs-blank))
  (setq flappymacs-bird-height (/ flappymacs-height 2.0))
  (setq flappymacs-bird-vector 0.0)

  (flappymacs-init-buffer)
  (gamegrid-kill-timer)
  (gamegrid-start-timer flappymacs-timer-delay 'flappymacs-update-game)
  (flappymacs-update-score))

;;;###autoload
(defun flappymacs ()
  "Play flappybird and waste time.

flappymacs-mode keybindings:\\<flappymacs-mode-map>

\\{flappymacs-mode-map}"
  (interactive)

  (setq flappymacs-max-score 0)
  (flappymacs-init))

(provide 'flappymacs)

;;; flappymacs.el ends here
