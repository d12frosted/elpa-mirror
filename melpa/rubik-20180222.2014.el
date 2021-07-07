;;; rubik.el --- Rubik's Cube  -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Ivan Truskov
;; Author: Ivan 'Kurvivor' Truskov <trus19@gmail.com>
;; Version: 1.1
;; Package-Version: 20180222.2014
;; Package-Commit: c8dab1726463dbc9042a0b00186e4a8df02eb868
;; Created: 12 December 2017
;; Keywords: games
;; Homepage: https://github.com/Kurvivor19/rubik-mode
;; Package-Requires: ((cl-lib "1.0") (emacs "25.3"))

;; This file is not part of GNU Emacs.

;;; License: BEER-WARE

;; If the following license is retained, anybody may change or use the
;; code in any way.  If this have been helpful, you may thank the
;; author by buying him a beer or shavarma when met.

;;; Commentary:

;; This package emulates a Rubik's Cube in Emacs.  The cube is shown
;; in 2 projections; this way all its sides are visible.  The cube can
;; be manipulated by commands similar to rotational language notation,
;; and they can be prefixed with 2 or i to denote double or inverse
;; rotation, respectively.

;; Undo and redo queues are maintained.

;;; TODO:

;; * Randomization of the cube state
;; * Automatic solving

;;; Code:

;;; Requirements

(require 'cl-lib)
(require 'calc)

;;; Cube layout

(defconst rubik-cube-front-default '("             / \\             "
                                     "           /     \\           "
                                     "         / \\     / \\         "
                                     "       /     \\_/     \\       "
                                     "     / \\     / \\     / \\     "
                                     "   /     \\_/     \\_/     \\   "
                                     "  |\\_    / \\     / \\     /|  "
                                     "  |  \\ /     \\_/     \\_/  |  "
                                     "  |   |\\_    / \\     /|   |  "
                                     "  |\\_ |  \\ /     \\_/  | _/|  "
                                     "  |  \\|   |\\_   _/|   |/  |  "
                                     "  |   |\\_ |  \\ /  | _/|   |  "
                                     "  |\\_ |  \\|   |   |/  | _/|  "
                                     "  |  \\|   |\\  |  /|   |/  |  "
                                     "  |   |\\_ |  \\|/  | _/|   |  "
                                     "   \\_ |  \\|   |   |/  | _/   "
                                     "     \\|   |\\_ | _/|   |/     "
                                     "       \\_ |  \\|/  | _/       "
                                     "         \\|   |   |/         "
                                     "           \\_ | _/           "
                                     "             \\|/             "))
(defconst rubik-cube-back-default '("            _/|\\_            "
                                    "           /  |  \\           "
                                    "        _/|   |   |\\_        "
                                    "       /  | _/|\\_ |  \\       "
                                    "    _/|   |/  |  \\|   |\\_    "
                                    "   /  | _/|   |   |\\_ |  \\   "
                                    "  |   |/  | _/|\\_ |  \\|   |  "
                                    "  | _/|   |/  |  \\|   |\\_ |  "
                                    "  |/  | _/|   |   |\\_ |  \\|  "
                                    "  |   |/  | _/ \\_ |  \\|   |  "
                                    "  | _/|   |/     \\|   |\\_ |  "
                                    "  |/  | _/ \\_   _/ \\_ |  \\|  "
                                    "  |   |/     \\_/     \\|   |  "
                                    "  | _/ \\_    / \\_   _/ \\_ |  "
                                    "  |/     \\_/     \\_/     \\|  "
                                    "   \\_   _/ \\_   _/ \\_   _/   "
                                    "     \\ /     \\_/     \\_/     "
                                    "       \\_   _/ \\_   _/       "
                                    "         \\ /     \\_/         "
                                    "           \\_   _/           "
                                    "             \\_/             "))

(defvar-local rubik-cube-back ()
  "Canvas for front of Rubik's Cube.")

(defvar-local rubik-cube-front ()
  "Canvas for back of Rubik's Cube.")

(defconst rubik-side-coord [(0 14) (7 3) (11 17) (5 5) (1 15) (9 14)]
  "Coordinates of starting points of the cube sides.")

;;; Faces

(defgroup rubik nil
  "Customization for Rubik's Cube display."
  :group 'games)

(defcustom rubik-shuffle 5
  "Number of random changes to the initial state."
  :type 'integer
  :group 'rubik)

(defface rubik-red
  '((t . (:background "red")))
  "Red colored cube side."
  :group 'rubik)
(defface rubik-orange
  '((t . (:background "orange")))
  "Orange colored cube side."
  :group 'rubik)
(defface rubik-white
  '((t . (:background "antique white")))
  "White colored cube side."
  :group 'rubik)
(defface rubik-blue
  '((t . (:background "blue")))
  "Blue colored cube side."
  :group 'rubik)
(defface rubik-yellow
  '((t . (:background "yellow")))
  "Yellow colored cube side."
  :group 'rubik)
(defface rubik-green
  '((t . (:background "green")))
  "Green colored cube side."
  :group 'rubik)

(defconst rubik-faces [rubik-red
                       rubik-white
                       rubik-green
                       rubik-yellow
                       rubik-blue
                       rubik-orange])

;;; Painter functions

(defun rubik-color-painter (face)
  "Return function that will apply color from FACE to string."
  (lambda (str beg end _prn)
    (add-face-text-property beg end face t str)))

(defun rubik-paint-diamond (cube-screen coord painter)
  "Paint diamond shape with provided PAINTER function."
  (let ((l (cl-first coord))
        (c (cl-second coord)))
    (funcall painter (nth l cube-screen) c (1+ c) nil)
    (funcall painter (nth (cl-incf l) cube-screen) (- c 2) (+ c 3) t)
    (funcall painter (nth (cl-incf l) cube-screen) (- c 2) (+ c 3) nil)
    (funcall painter (nth (cl-incf l) cube-screen) c (1+ c) nil)))

(defun rubik-paint-slope-down (cube-screen coord painter)
  "Paint downward slope with provided PAINTER function."
    (let ((l (cl-first coord))
          (c (cl-second coord)))
      (funcall painter (nth l cube-screen) c (+ c 2) nil)
      (funcall painter (nth (cl-incf l) cube-screen) c (+ c 3) t)
      (funcall painter (nth (cl-incf l) cube-screen) (1+ c) (+ c 3) nil)))

(defun rubik-paint-slope-up (cube-screen coord painter)
  "Paint upward slope with provided PAINTER function."
    (let ((l (cl-first coord))
          (c (cl-second coord)))
      (funcall painter (nth l cube-screen) (1- c) (1+ c) nil)
      (funcall painter (nth (cl-incf l) cube-screen) (- c 2) (1+ c) t)
      (funcall painter (nth (cl-incf l) cube-screen) (- c 2) c nil)))

(defun rubik-make-initial-cube ()
  "Construct vector describing initial state of the cube."
  (apply #'vconcat (mapcar (lambda (row) (make-vector 9 row))
                           (number-sequence 0 5))))

(defun rubik-displace-diamond (coord local-number)
  "Calculate displacement of the cell of top and bottom sides.  COORD is location of the side, LOCAL-NUMBER is coordinates of cell on that side."
  (let ((l (cl-first coord))
        (c (cl-second coord))
        (row (/ local-number 3))
        (col (mod local-number 3)))
    (setq l (+ l (* 2 row)))
    (setq c (- c (* 4 row)))
    (setq l (+ l (* 2 col)))
    (setq c (+ c (* 4 col)))
    (list l c)))

(defun rubik-displace-downslope (coord local-number)
  "Calculate displacements of the cell of front and left sides.  COORD is location of the side, LOCAL-NUMBER is coordinates of cell on that side."
  (let ((l (cl-first coord))
        (c (cl-second coord))
        (row (/ local-number 3))
        (col (mod local-number 3)))
    (setq l (+ l (* 3 row)))
    (setq l (+ l (* 2 col)))
    (setq c (+ c (* 4 col)))
    (list l c)))

(defun rubik-displace-upslope (coord local-number)
  "Calculate displacements of the cell of back and right sides.  COORD is location of the side, LOCAL-NUMBER is coordinates of cell on that side."
  (let ((l (cl-first coord))
        (c (cl-second coord))
        (row (/ local-number 3))
        (col (mod local-number 3)))
    (setq l (+ l (* 3 row)))
    (setq l (- l (* 2 col)))
    (setq c (+ c (* 4 col)))
    (list l c)))

(defun rubik-get-local-number (cell-number)
  "Transform CELL-NUMBER from index in the vector to (ROW COL) list."
  (list (/ cell-number 9) (mod cell-number 9)))

(defun rubik-paint-cell (front back number color)
  "On either FRONT or BACK color cell with given NUMBER as a given COLOR."
  (cl-destructuring-bind (side local-number) (rubik-get-local-number number)
    (let ((canvas (if (< side 3) front back))
          (painter (rubik-color-painter (aref rubik-faces color)))
          (filler (cl-case side
                    ((0 5) #'rubik-paint-diamond)
                    ((1 4) #'rubik-paint-slope-down)
                    ((2 3) #'rubik-paint-slope-up)))
          (translator (cl-case side
                        ((0 5) #'rubik-displace-diamond)
                        ((1 4) #'rubik-displace-downslope)
                        ((2 3) #'rubik-displace-upslope))))
      (funcall filler canvas (funcall translator (aref rubik-side-coord side) local-number) painter))))

(defun rubik-paint-cube (state)
  "Regenerate display variables and show cube STATE on them."
  (setq rubik-cube-front (mapcar #'copy-sequence rubik-cube-front-default))
  (setq rubik-cube-back (mapcar #'copy-sequence rubik-cube-back-default))
  (dotimes (i (* 6 9))
    (rubik-paint-cell rubik-cube-front rubik-cube-back i (aref state i))))

;;; Definitions for rotational notation

(defconst rubik-i '(cplx 0 1))
(defconst rubik-neg-i '(cplx 0 -1))

(defconst rubik-desc-rot-identity
  '((0 1) (1 1) (2 1) (3 1) (4 1) (5 1)))

(defconst rubik-desc-rot-1-2
  `((1 1) (5 ,rubik-i) (2 ,rubik-neg-i) (0 -1) (4 ,rubik-i) (3 ,rubik-i)))

(defconst rubik-desc-rot-1-3
  `((2 ,rubik-i) (1 ,rubik-i) (5 -1) (3 ,rubik-neg-i) (0 ,rubik-i) (4 1)))

(defconst rubik-desc-rot-2-3
  `((0 ,rubik-neg-i) (2 1) (3 1) (4 1) (1 1) (5 ,rubik-i)))

(defun rubik-compose-rot (rot-1 rot-2)
  "Make new rotation by composing ROT-1 and ROT-2."
  (cl-loop for (n1 r1) in rot-1
           for (n2 r2) = (nth n1 rot-2)
           collect (list n2 (math-mul r1 r2))))

(defun rubik-rotate (&rest turns)
  "Compose as many rotations in list TURNS as needed."
  (cl-reduce #'rubik-compose-rot turns))

(defconst rubik-side-renumbering-clockwise
  '(6 3 0 7 4 1 8 5 2))

(defun rubik-compose-subst (sub-1 sub-2)
  "Compose SUB-1 and SUB-2 into new substitution."
  (mapcar (lambda (i1) (nth i1 sub-2)) sub-1))

(defun rubik-substitute (&rest subs)
  "Compose all substitutions in SUBS."
  (cl-reduce #'rubik-compose-subst subs))

(defconst rubik-side-rotations
  (list (cons rubik-i rubik-side-renumbering-clockwise)
        (cons -1 (rubik-substitute rubik-side-renumbering-clockwise
                                   rubik-side-renumbering-clockwise))
        (cons rubik-neg-i (rubik-substitute rubik-side-renumbering-clockwise
                                            rubik-side-renumbering-clockwise
                                            rubik-side-renumbering-clockwise))
        ;; We could call with 4 rotations or define a constant for identity.
        ;; But there is no need, really.
        (cons 1 (number-sequence 0 8))))

(defun rubik-expand-substitution (sub)
  "Get substitution for entire cube state from short form of SUB."
  (cl-loop with res = (make-vector (* 9 6) 0)
           for i from 0 to 5
           for (side-number rot) = (nth i sub)
           for side-reorder = (cdr (assoc rot rubik-side-rotations))
           for base-offset = (* i 9)
           for target-offset = (* side-number 9)
           do (dotimes (j 9)
                (aset res (+ j target-offset)
                      (+ base-offset (nth j side-reorder))))
           finally return (append res ())))

(defconst rubik-turn-top-substitution
  (let ((temp (vconcat (number-sequence 0 (1- (* 9 6)))))
        (side-offsets '((9 36) (18 9) (27 18) (36 27)))
        (rotation (rubik-substitute rubik-side-renumbering-clockwise
                                    rubik-side-renumbering-clockwise
                                    rubik-side-renumbering-clockwise)))
    (dotimes (i 9)
      (aset temp i (nth i rotation)))
    (cl-loop for (loc num) in side-offsets do
             (dotimes (i 3)
               (aset temp (+ loc i) (+ num i))))
    (append temp ()))
  "Complete cube substitution for clockwise rotation on top.")

(defun rubik-apply-transformation (state transform)
  "Change STATE of the cube by applying TRANSFORM."
  (let ((second (copy-sequence state)))
    (dotimes (i (length second))
      (aset state (nth i transform) (aref second i)))))

;;; Definitions of common transformations

(defconst rubik-U
  rubik-turn-top-substitution)

(defconst rubik-U2
  (rubik-substitute rubik-turn-top-substitution
                    rubik-turn-top-substitution))

(defconst rubik-Ui
  (rubik-substitute rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution))

(defconst rubik-F
  (rubik-substitute (rubik-expand-substitution rubik-desc-rot-1-2)
                    rubik-turn-top-substitution
                    (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))))

(defconst rubik-F2
  (rubik-substitute (rubik-expand-substitution rubik-desc-rot-1-2)
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))))

(defconst rubik-Fi
  (rubik-substitute (rubik-expand-substitution rubik-desc-rot-1-2)
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))))

(defconst rubik-R
  (rubik-substitute (rubik-expand-substitution rubik-desc-rot-1-3)
                    rubik-turn-top-substitution
                    (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3))))

(defconst rubik-R2
  (rubik-substitute (rubik-expand-substitution rubik-desc-rot-1-3)
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3))))

(defconst rubik-Ri
  (rubik-substitute (rubik-expand-substitution rubik-desc-rot-1-3)
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3))))

(defconst rubik-L
  (rubik-substitute (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3))
                    rubik-turn-top-substitution
                    (rubik-expand-substitution rubik-desc-rot-1-3)))

(defconst rubik-L2
  (rubik-substitute (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3))
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution rubik-desc-rot-1-3)))

(defconst rubik-Li
  (rubik-substitute (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3
                                   rubik-desc-rot-1-3))
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution rubik-desc-rot-1-3)))

(defconst rubik-B
  (rubik-substitute (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))
                    rubik-turn-top-substitution
                    (rubik-expand-substitution rubik-desc-rot-1-2)))

(defconst rubik-B2
  (rubik-substitute (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution rubik-desc-rot-1-2)))

(defconst rubik-Bi
  (rubik-substitute (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution rubik-desc-rot-1-2)))

(defconst rubik-D
  (rubik-substitute (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))
                    rubik-turn-top-substitution
                    (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))))

(defconst rubik-D2
  (rubik-substitute (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))))

(defconst rubik-Di
  (rubik-substitute (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    rubik-turn-top-substitution
                    (rubik-expand-substitution
                     (rubik-rotate rubik-desc-rot-1-2
                                   rubik-desc-rot-1-2))))

(defconst rubik-x
  (rubik-expand-substitution rubik-desc-rot-1-2))

(defconst rubik-x2
  (rubik-expand-substitution
   (rubik-rotate rubik-desc-rot-1-2
                 rubik-desc-rot-1-2)))

(defconst rubik-xi
  (rubik-expand-substitution
   (rubik-rotate rubik-desc-rot-1-2
                 rubik-desc-rot-1-2
                 rubik-desc-rot-1-2)))

(defconst rubik-y
  (rubik-expand-substitution rubik-desc-rot-2-3))

(defconst rubik-y2
  (rubik-expand-substitution
   (rubik-rotate rubik-desc-rot-2-3
                 rubik-desc-rot-2-3)))

(defconst rubik-yi
  (rubik-expand-substitution
   (rubik-rotate rubik-desc-rot-2-3
                 rubik-desc-rot-2-3
                 rubik-desc-rot-2-3)))

(defconst rubik-zi
  (rubik-expand-substitution rubik-desc-rot-1-3))

(defconst rubik-z2
  (rubik-expand-substitution
   (rubik-rotate rubik-desc-rot-1-3
                 rubik-desc-rot-1-3)))

(defconst rubik-z
  (rubik-expand-substitution
   (rubik-rotate rubik-desc-rot-1-3
                 rubik-desc-rot-1-3
                 rubik-desc-rot-1-3)))

;;; Mode definitions

(defvar-local rubik-cube-state []
  "State of the cube that is being processed.")

(defvar-local rubik-cube-undo (list 'undo)
  "List of previously executed commands.")

(defvar-local rubik-cube-redo (list 'redo)
  "List of previously undone commands.")

(defvar-local rubik-cube-undo-hidden (list 'undo)
  "Hidden undo sequence")

(defun rubik-center-string (str l)
  "Add spaces to STR from both sides until it has length L."
  (if (> (length str) l)
      (substring str l)
    (let* ((sl (length str))
           (pad (/ (- l sl) 2))
           (rem (- l pad)))
      (concat (format (format "%%%ds" rem) str) (make-string pad ?\s)))))

(defun rubik-display-cube ()
  "Draw current cube state, assuming empty buffer."
  ;; First, update canvasses according to the cube state
  (rubik-paint-cube rubik-cube-state)
  (let ((w (length (cl-first rubik-cube-front-default)))
        (h (length rubik-cube-front-default)))
    (insert (format "%s%s\n"
                    (rubik-center-string "*FRONT*" w)
                    (rubik-center-string "*BACK*" w)))
    (insert-rectangle rubik-cube-front)
    (forward-line (- (cl-decf h)))
    (move-end-of-line nil)
    (insert-rectangle rubik-cube-back)))

(defun rubik-display-undo ()
  "Insert undo information at point."
  (cl-loop with line-str = "\nUndo: "
           for cmd in (reverse (cdr rubik-cube-undo))
           for i = 1 then (1+ i)
           do (progn
                (setq line-str (concat line-str (format "%d. %s " i (get cmd 'name))))
                (when (> (length line-str) fill-column)
                  (insert line-str)
                  (setq line-str (concat "\n" (make-string 6 ?\s)))))
           finally (insert line-str)))

(defun rubik-display-redo ()
  "Insert redo information at point."
  (cl-loop with line-str = "\nRedo: "
           for cmd in (cdr rubik-cube-redo)
           for i = 1 then (1+ i)
           do (progn
                (setq line-str (concat line-str (format "%d. %s " i (get cmd 'name))))
                (when (> (length line-str) fill-column)
                  (insert line-str)
                  (setq line-str (concat "\n" (make-string 6 ?\s)))))
           finally (insert line-str)))

(defun rubik-draw-all ()
  "Display current state of the cube in current buffer."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (rubik-display-cube)
    (rubik-display-undo)
    (rubik-display-redo)))

(defmacro rubik-define-command (transformation desc)
  "Generalized declaration of command for applying TRANSFORMATION to the cube state.  Command has DESC in its plist as `command-name'."
  (let ((command-name (intern (concat (symbol-name transformation) "-command"))))
    `(progn
       (put ',command-name 'name ,desc)
       (defun ,command-name (&optional arg)
         (interactive)
         (rubik-apply-transformation rubik-cube-state ,transformation)
         (unless arg
           (setcdr rubik-cube-redo ())
           (setcdr rubik-cube-undo (cons ',command-name (cdr rubik-cube-undo)))
           (rubik-draw-all))))))

(defmacro rubik-define-commands (&rest transformations)
  "Bulk definition of commands that wrap items in TRANSFORMATIONS."
  (declare (indent 0))
  (let (head name cmds)
    (while (and (setq head (pop transformations))
                (setq name (pop transformations))
                (push `(rubik-define-command ,head ,name) cmds)))
    (macroexp-progn (nreverse cmds))))

(rubik-define-commands
  rubik-U "Upper" rubik-U2 "Upper twice" rubik-Ui "Upper inverted"
  rubik-F "Front" rubik-F2 "Front twice" rubik-Fi "Front inverted"
  rubik-R "Right" rubik-R2 "Right twice" rubik-Ri "Right inverted"
  rubik-L "Left" rubik-L2 "Left twice" rubik-Li "Left inverted"
  rubik-B "Back" rubik-B2 "Back twice" rubik-Bi "Back inverted"
  rubik-D "Down" rubik-D2 "Down twice" rubik-Di "Down inverted"
  rubik-x "X rotation" rubik-x2 "X overturn" rubik-xi "X rotation inverted"
  rubik-y "Y rotation" rubik-y2 "Y overturn" rubik-yi "Y rotation inverted"
  rubik-z "Z rotation" rubik-z2 "Z overturn" rubik-zi "Z rotation inverted")

(defconst rubik-reverse-commands
  '((rubik-U-command . rubik-Ui-command)
    (rubik-U2-command . rubik-U2-command)
    (rubik-F-command . rubik-Fi-command)
    (rubik-F2-command . rubik-F2-command)
    (rubik-R-command . rubik-Ri-command)
    (rubik-R2-command . rubik-R2-command)
    (rubik-L-command . rubik-Li-command)
    (rubik-L2-command . rubik-L2-command)
    (rubik-B-command . rubik-Bi-command)
    (rubik-B2-command . rubik-B2-command)
    (rubik-D-command . rubik-Di-command)
    (rubik-D2-command . rubik-D2-command)
    (rubik-x-command . rubik-xi-command)
    (rubik-x2-command . rubik-x2-command)
    (rubik-y-command . rubik-yi-command)
    (rubik-y2-command . rubik-y2-command)
    (rubik-z-command . rubik-zi-command)
    (rubik-z2-command . rubik-z2-command))
  "Alist with commands and their opposites, allowing to undo earlier commands.")

(defun rubik-reset ()
  "Set cube to initial state."
  (interactive)
  (setq rubik-cube-state (rubik-make-initial-cube))
  (setq rubik-cube-undo (list 'undo))
  (setq rubik-cube-redo (list 'redo))
  (setq rubik-cube-undo-hidden (list 'undo))
  (rubik-draw-all))

(defun rubik-undo (&optional arg)
  "Undo up to ARG commands from undo list."
  (interactive "p")
  (dotimes (_ (or arg 1))
    (let ((lastcmd (cadr rubik-cube-undo)))
      (when lastcmd
        (let ((revcmd (or (cdr (assoc lastcmd rubik-reverse-commands))
                          (car (rassoc lastcmd rubik-reverse-commands)))))
          (setcdr rubik-cube-redo (cons lastcmd (cdr rubik-cube-redo)))
          (setcdr rubik-cube-undo (cddr rubik-cube-undo))
          (funcall revcmd t)))))
  (rubik-draw-all))

(defun rubik-redo (&optional arg)
  "Redo up to ARG commands."
  (interactive "p")
  (dotimes (_ (or arg 1))
    (let ((lastcmd (cadr rubik-cube-redo)))
      (when lastcmd
        (setcdr rubik-cube-undo (cons lastcmd (cdr rubik-cube-undo)))
        (setcdr rubik-cube-redo (cddr rubik-cube-redo))
        (funcall lastcmd t))))
  (rubik-draw-all))

(defun rubik-hide-queues ()
  "Hide undo queue."
  (interactive)
  (setcdr rubik-cube-undo-hidden
          (append (cdr rubik-cube-undo) (cdr rubik-cube-undo-hidden)))
  (setcdr rubik-cube-undo ())
  (setcar rubik-cube-redo ())
  (rubik-draw-all))

(defun rubik-rollback ()
  "Undo all not hidden changes."
  (interactive)
  (rubik-undo (length (cdr rubik-cube-undo))))

(defun rubik-unhide-queues ()
  "Restore saved undo queue."
  (interactive)
  (setcdr (last rubik-cube-undo) (cdr rubik-cube-undo-hidden))
  (setcdr rubik-cube-undo-hidden ())
  (rubik-draw-all))

(defconst rubik-command-groups
  (let ((temp '([rubik-U-command rubik-U2-command rubik-Ui-command]
                [rubik-F-command rubik-F2-command rubik-Fi-command]
                [rubik-R-command rubik-R2-command rubik-Ri-command]
                [rubik-L-command rubik-L2-command rubik-Li-command]
                [rubik-B-command rubik-B2-command rubik-Bi-command]
                [rubik-D-command rubik-D2-command rubik-Di-command]
                [rubik-x-command rubik-x2-command rubik-xi-command
                 rubik-y-command rubik-y2-command rubik-yi-command
                 rubik-z-command rubik-z2-command rubik-zi-command])))
    (setcdr (last temp) temp)
    temp)
  "Cyclic list of commands that transform the cube.")

(defun rubik-random-from-group (group)
  "Randomply select one element from vector GROUP."
  (aref group (random (length group))))

(defun rubik-shuffle (&optional arg)
  "Randomly apply ARG or variable `rubik-shuffle' random transformations to cube."
  (interactive "P")
  (let ((n (or (and arg (prefix-numeric-value arg))
               rubik-shuffle))
        (iter rubik-command-groups))
    (dotimes (_ n)
      ;; something like a poisson distribution
      ;; magic number chosen based on aestethic value
      (while (< 0 (random 19))
        (setq iter (cdr iter)))
      ;; undo information is not supressed
      (funcall (rubik-random-from-group (car iter)))))
  ;; hide steps made
  (rubik-hide-queues))

(defvar rubik-mode-map
  (let ((map (make-sparse-keymap))
        (map-i (make-sparse-keymap))
        (map-2 (make-sparse-keymap)))
    (define-key map "u" 'rubik-U-command)
    (define-key map-2 "u" 'rubik-U2-command)
    (define-key map-i "u" 'rubik-Ui-command)
    (define-key map "f" 'rubik-F-command)
    (define-key map-2 "f" 'rubik-F2-command)
    (define-key map-i "f" 'rubik-Fi-command)
    (define-key map "r" 'rubik-R-command)
    (define-key map-2 "r" 'rubik-R2-command)
    (define-key map-i "r" 'rubik-Ri-command)
    (define-key map "l" 'rubik-L-command)
    (define-key map-2 "l" 'rubik-L2-command)
    (define-key map-i "l" 'rubik-Li-command)
    (define-key map "b" 'rubik-B-command)
    (define-key map-2 "b" 'rubik-B2-command)
    (define-key map-i "b" 'rubik-Bi-command)
    (define-key map "d" 'rubik-D-command)
    (define-key map-2 "d" 'rubik-D2-command)
    (define-key map-i "d" 'rubik-Di-command)
    (define-key map "x" 'rubik-x-command)
    (define-key map-2 "x" 'rubik-x2-command)
    (define-key map-i "x" 'rubik-xi-command)
    (define-key map "y" 'rubik-y-command)
    (define-key map-2 "y" 'rubik-y2-command)
    (define-key map-i "y" 'rubik-yi-command)
    (define-key map "z" 'rubik-z-command)
    (define-key map-2 "z" 'rubik-z2-command)
    (define-key map-i "z" 'rubik-zi-command)
    (define-key map "g" 'rubik-reset)
    (define-key map "2" map-2)
    (define-key map "i" map-i)
    (define-key map (kbd "M-u") 'rubik-undo)
    (define-key map (kbd "M-r") 'rubik-redo)
    (define-key map (kbd "M-h") 'rubik-hide-queues)
    (define-key map (kbd "M-s") 'rubik-unhide-queues)
    (define-key map (kbd "M-f") 'rubik-shuffle)
    map))

(define-derived-mode rubik-mode special-mode
  "Mode for solving Rubik's Cube.")

;;;###autoload
(defun rubik ()
  "Start solving Rubik's Cube."
  (interactive)
  (pop-to-buffer "*Rubik*")
  (rubik-mode)
  (rubik-reset))

(provide 'rubik)

;;; rubik.el ends here
