;;; autotetris-mode.el --- automatically play tetris

;; This is free and unencumbered software released into the public domain.

;; Author: Christopher Wellons <wellons@nullprogram.com>
;; URL: https://github.com/skeeto/autotetris-mode
;; Package-Version: 20141114.1646
;; Package-Commit: 7d348d33829bc89ddbd2b4d5cfe5073c3b0cbaaa
;; Package-Requires: ((cl-lib "0.5"))

;;; Commentary:

;; This package provides two commands:

;;  * `autotetris' starts `tetris' with autotetris-mode enabled. This
;;    is the command you probably want to run.

;;  * `autotetris-mode' a minor mode for tetris-mode that
;;    automatically plays the game. Can be turned on or off at any
;;    time to allow a human to step in or out of control.

;; The AI is straightforward. It has a game state evaluator that
;; computes a single metric for a game state based on the following:

;; * Number of holes
;; * Maximum block height
;; * Mean block height
;; * Largest block height disparity
;; * Surface roughness

;; Lower is better. When a new piece is to be placed it virtually
;; attempts to place it in every possible position and rotation,
;; choosing the lowest evaluation score. It's all loosely based on
;; this algorithm:

;; http://www.cs.cornell.edu/boom/1999sp/projects/tetris/

;; Current shortcomings:

;; The weights could using some tweaking because the priorities are
;; obviously wrong at times. It does not account for the next piece,
;; which sometimes has tragic consequences. It does not attempt to
;; "slide" pieces into place. It does not try to maximize score (the
;; score is not part of the evaluation algorithm). The evaluation
;; function is kind of slow, so you should byte-compile this file.

;;; Code:

(require 'cl-lib)
(require 'tetris)

;; Set up some hooks:

(defvar autotetris-new-shape-hook ()
  "Hooks that run after tetris sets a new shape.")

(defvar autotetris-start-game-hook ()
  "Hooks that run immediately after a game starts.")

(defadvice tetris-new-shape (after autotetris-new-shape-hook activate)
  (run-hooks 'autotetris-new-shape-hook))

(defadvice tetris-start-game (after autotetris-start-game-hook activate)
  (run-hooks 'autotetris-start-game-hook))

;; Define autotetris minor mode:

(defvar-local autotetris-timer nil
  "Stores the local timer value.")

(defvar autotetris-period 0.2
  "How often autotetris should make a move.")

(defvar autotetris-mode-map
  (let ((keymap (make-sparse-keymap)))
    (prog1 keymap
      ;; One key for debugging:
      (define-key keymap "a" #'autotetris-move)))
  "Keymap for autotetris-mode.")

(defun autotetris-kill-timer ()
  "Stop running the autotetris timer."
  (when autotetris-timer
    (cancel-timer autotetris-timer)
    (setf autotetris-timer nil)))

;;;###autoload
(define-minor-mode autotetris-mode
  "Automatically play tetris in the current buffer."
  :lighter " autotetris"
  :keymap autotetris-mode-map
  (unless (eq major-mode 'tetris-mode)
    (setf autotetris-mode nil)
    (error "autotetris-mode can only be used with tetris-mode!"))
  (if autotetris-mode
      (progn
        (add-hook 'kill-buffer-hook #'autotetris-kill-timer nil t)
        (unless autotetris-timer
          (setf autotetris-timer
                (run-at-time t autotetris-period #'autotetris-move))))
    (cancel-timer autotetris-timer)))

;;;###autoload
(defun autotetris ()
  "Automatically play a game of tetris."
  (interactive)
  (tetris)
  (unless autotetris-mode
    (autotetris-mode)))

;; The AI:

(defun autotetris-get (x y)
  "Get the tetris block at X, Y."
  (gamegrid-get-cell (+ tetris-top-left-x x) (+ tetris-top-left-y y)))

(defmacro autotetris-visit (x-y-cell &rest body)
  "Visit each cell in the game with BODY, binding X-Y-CELL."
  (declare (indent defun))
  (cl-destructuring-bind (x y cell) x-y-cell
    `(catch 'done
       (dotimes (,y tetris-height)
         (dotimes (,x tetris-width)
           (let ((,cell (autotetris-get x y)))
             ,@body))))))

(defun autotetris--holes ()
  "Count the number of holes in the gamegrid."
  (let ((n 0)
        (columns (make-vector tetris-width nil)))
    (autotetris-visit (x y cell)
      (if (eql cell tetris-blank)
          (when (aref columns x) (cl-incf n))
        (setf (aref columns x) t)))
    n))

(defun autotetris--height (x)
  "Return the current block height for column X."
  (cl-loop for y below tetris-height
           unless (eql tetris-blank (autotetris-get x y))
           return (- tetris-height y)
           finally (cl-return 0)))

(defun autotetris--min-max-mean-rms ()
  "Return the min, max, mean, and rms height."
  (cl-flet ((sum (vs) (apply #'+ vs)))
    (let* ((heights (cl-loop for x below tetris-width
                             collect (autotetris--height x)))
           (min (apply #'min heights))
           (max (apply #'max heights))
           (mean (/ (sum heights) 1.0 (length heights)))
           (rms (sqrt (sum (mapcar (lambda (v) (expt (- mean v) 2)) heights)))))
      (cl-values min max mean rms))))

(defun autotetris-eval ()
  "Evaluate the gamegrid in the current buffer; lower is better."
  (let ((hole-weight 8.0)
        (mean-weight 4.0)
        (max-weight 3.0)
        (disparity-weight 3.0)
        (roughness-weight 2.0))
    (cl-multiple-value-bind (min max mean rms) (autotetris--min-max-mean-rms)
      (+ (* hole-weight (autotetris--holes))
         (* mean-weight mean)
         (* max-weight max)
         (* disparity-weight (- max min))
         (* roughness-weight rms)))))

(defmacro autotetris-save-excursion (&rest body)
  "Restore tetris game state after BODY completes."
  (declare (indent defun))
  `(with-current-buffer tetris-buffer-name
     (let ((autotetris-saved (clone-buffer "*Tetris-saved*")))
       (unwind-protect
           (with-current-buffer autotetris-saved
             (kill-local-variable 'kill-buffer-hook)
             ,@body)
         (kill-buffer autotetris-saved)))))

(defvar autotetris-target nil
  "The current block target position and orientation.")

(defun autotetris-game-running-p ()
  "Return t if tetris is currently running."
  (ignore-errors
    (with-current-buffer tetris-buffer-name
      (not (eq (current-local-map) tetris-null-map)))))

(defun autotetris--more-middle-p (x1 x2)
  "Return t if X1 is closer to the middle than X2."
  (cond
   ((null x1) nil)
   ((null x2) t)
   (:else
    (let* ((half (/ tetris-width 2.0))
           (d1 (abs (- x1 half)))
           (d2 (abs (- x2 half))))
      (< d1 d2)))))

(defun autotetris-compute-target ()
  "Compute the target X position and rotation."
  (let ((best-x nil)
        (best-r nil)
        (best-score 1.0e+INF))
    (dotimes (r (tetris-shape-rotations) (list best-x best-r best-score))
      (dotimes (xx (+ 2 tetris-width))
        (let ((x (1- xx)))
          (autotetris-save-excursion
            (tetris-erase-shape)
            (setf tetris-pos-y 1)
            (setf tetris-pos-x x)
            (setf tetris-rot r)
            (unless (tetris-test-shape)
              (tetris-draw-shape)
              (tetris-move-bottom)
              (tetris-erase-shape)
              (let ((score (autotetris-eval)))
                (when (or (< score best-score)
                          (and (= score best-score)
                               (autotetris--more-middle-p x best-x)))
                  (setf best-x x
                        best-r r
                        best-score score))))))))))

(defun autotetris-clear-target ()
  "Clear the current target x-position and rotation."
  (setf autotetris-target nil))

(defun autotetris-move ()
  "Make exactly one action (move, rotate, drop) in the game."
  (interactive)
  (when (and autotetris-mode
             (not tetris-paused)
             (autotetris-game-running-p))
    (when (null autotetris-target)
      (setf autotetris-target (autotetris-compute-target)))
    (cl-destructuring-bind (x r score) autotetris-target
      (cond
       ((/= tetris-rot r)  (tetris-rotate-next))
       ((< tetris-pos-x x) (tetris-move-right))
       ((> tetris-pos-x x) (tetris-move-left))
       (:else (progn
                (tetris-move-bottom)
                (autotetris-clear-target)))))))

(add-hook 'autotetris-new-shape-hook #'autotetris-clear-target)
(add-hook 'autotetris-start-game-hook #'autotetris-clear-target)

(provide 'autotetris-mode)

;;; autotetris-mode.el ends here
