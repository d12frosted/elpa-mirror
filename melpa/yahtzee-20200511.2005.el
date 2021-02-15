;;; yahtzee.el --- The yahtzee game

;; Copyright (C) 2017 Dimitar Dimitrov

;; Author: Dimitar Dimitrov <mail.mitko@gmail.com>
;; URL: https://github.com/drdv/yahtzee
;; Package-Commit: 96068216a4f0c4894bf780cd36164fe840cf81d5
;; Package-Version: 20200511.2005
;; Package-X-Original-Version: 20170616.1
;; Package-Requires: ((emacs "24.3"))
;; Keywords: games

;; This file is not part of GNU Emacs.

;;; License:

;; Licensed under the same terms as Emacs.

;;; Commentary:

;; Package tested on:
;; GNU Emacs 25.2.1 (x86_64-apple-darwin16.5.0)

;; A simple implementation of the yahtzee game.

;; Quick start:
;;
;; add (require 'yahtzee) in your .emacs
;; M-x yahtzee  start a game (in a new buffer)
;; C-c n        start a new game (in the same buffer)
;; C-c p        add players
;; C-c P        reset players
;; SPC          throw dice
;; {1,2,3,4,5}  hold outcome of {1,2,3,4,5}-th dice
;; UP/DOWN      select score to register
;; ENTER        register selected score
;; w            save the game (in json format)
;;
;; The score of a saved game can be loaded using `M-x yahtzee-load-game-score`.
;;
;; Configuration variables:
;;
;; The user might want to set the following variables
;; (see associated docstrings)
;;   - `yahtzee-output-file-base'
;;   - `yahtzee-fields-alist'      for adding extra fields
;;   - `yahtzee-players-names'     set names of players
;;                                 use (setq-default yahtzee-players-names ...)
;;
;; Note:
;;    personally I don't enjoy playing with "Yahtzee bonuses" and "Joker rules"
;;    so they are not implemented (even thought they are simple to include).
;;    Only the "63 bonus" is available (see `yahtzee-compute-bonus').
;;    Furthermore, some scores differ from the official ones.  Changing all
;;    this can be done by simply modifying the corresponding functions in the
;;    definition of `yahtzee-fields-alist'.

;;; Code:

(require 'json)

(defvar-local yahtzee-players-names '("unknown")
  "List with names of players.")

(defvar yahtzee-number-of-dice-to-throw 5
  "Number of dice to throw.
This variable is used in the definition of `yahtzee-mode-map' so changing it
after \"(require 'yahtzee)\" in ~/.emacs leads to \"dead\" key bindings.
One could simply change it before \"(require 'yahtzee)\".")

(defvar yahtzee-dice-max-attempt 3
  "Number of allowed dice throws per turn.")

(defvar yahtzee-output-file-base nil
  "Wild card pattern used to generate files for saving games automatically.
If set to nil, game is saved interactively (i.e., user specifies filename).
For example \"/path/to/scores/game-*.json\" would generate a file
\"/path/to/scores/game-0004.json\" if there are already three saved files.")

(defvar yahtzee-fields-alist nil
  "Association list with yahtzee fields.
The format should be ((field-name . field-function)...).
The field-names are e.g., \"1\", \"2\", \"full\", \"care\", \"straight\" etc.
The field-function is called without arguments and should return score given
`yahtzee-dice-outcomes'.")

;; =============================================================================
;; the variables below are not meant to be set by the user
;; =============================================================================

(defvar-local yahtzee-number-of-players 1
  "Number of players (greater or equal to 1).
The user is not meant to set this directly (but through setting
`yahtzee-players-names').")

(defvar yahtzee-players-labels (mapcar 'string "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
  "Short labels associated with names of players.")

(defvar-local yahtzee-active-player nil
  "Currently active player (integer from 0 to `yahtzee-number-of-players'-1).")

(defvar-local yahtzee-moves-left nil
  "Number of moves left in the game.
Initially set to the number of fields in `yahtzee-fields-alist'.")

(defvar-local yahtzee-dice-thrown-number nil
  "Number of throws performed.")

(defconst yahtzee-dice-possible-outcomes (number-sequence 1 6)
  "Possible outcomes of each dice roll.")

(defvar-local yahtzee-dice-outcomes
  (make-vector yahtzee-number-of-dice-to-throw nil)
  "Vector of outcomes of dice throws.")

(defvar-local yahtzee-dice-outcomes-counts
  (make-vector (length yahtzee-dice-possible-outcomes) 0)
  "Number of occurrences of a dice throw outcome.
Number of occurrences of `yahtzee-dice-possible-outcomes'[k] is stored
in `yahtzee-dice-outcomes-counts'[k].")

(defvar-local yahtzee-dice-outcomes-fixed nil
  "A list of indexes of elements of `yahtzee-dice-outcomes' with fixed outcomes.
That is, outcomes that cannot change during a throw.")

(defvar-local yahtzee-selected-field nil
  "Name of field whose score is currently selected by the active player.")

(defvar-local yahtzee-scores (make-vector yahtzee-number-of-players nil)
  "Vector of alists of user scores.
The format should be [((field-name . score)...)...], i.e.,
`yahtzee-scores'[k] is the alist associated with the k-th user.")

(defvar-local yahtzee-loaded-game nil
  "Non-nil value indicates that the game was loaded.")

(defvar-local yahtzee-game-over nil
  "Non-nil indicates that the game has ended.")

(defvar-local yahtzee-game-start-time nil
  "Records the time when the game started.")

(defvar-local yahtzee-player-time nil
  "Vector [(player-move-start-time . player-game-time), ...].")

(defconst yahtzee-buffer-name-start "*yahtzee*"
  "Initial part of buffer name where to display the yahtzee game.
`generate-new-buffer-name' is used to generate unique buffer names.")



(defgroup yahtzee nil
  "The yahtzee game."
  :group 'games)

(defgroup yahtzee-faces nil
  "The yahtzee game related phases."
  :group 'yahtzee
  :group 'faces)

(defface yahtzee-face '((t . (:inherit highlight
				       :background "khaki"
				       :foreground "black")))
  "Generic face."
  :group 'yahtzee-faces)

(defface yahtzee-face-fixed '((t . (:inherit highlight
					     :background "color-94"
					     :foreground "black")))
  "Face for fixed stuff."
  :group 'yahtzee-faces)

(defface yahtzee-face-selected '((t . (:inherit highlight
						:background "gold"
						:foreground "black")))
  "Face for selected stuff."
  :group 'yahtzee-faces)

(defface yahtzee-face-user-arrow '((t . (:inherit default
						  :foreground "red")))
  "Face for the arrow indicating which user is active."
  :group 'yahtzee-faces)



(defun yahtzee-reset-players ()
  "Reset back to the default player."
  (interactive)
  ;; protect against unintended modification of players
  (if (< yahtzee-moves-left (length yahtzee-fields-alist))
      (message "Each player has already made a move! \
To reset players, start a new game.")
    (setq yahtzee-number-of-players 1)
    (setq yahtzee-players-names '("unknown"))
    (yahtzee-reset)
    (yahtzee-display-board)))

(defun yahtzee-set-player-name (player-name)
  "Add a new player and set its name.
PLAYER-NAME is set in the mini-buffer by the user."
  (interactive
   (list
    (read-string "Player name: ")))
  ;; protect against unintended modification of players
  (if (< yahtzee-moves-left (length yahtzee-fields-alist))
      (message "Each player has already made a move! \
To rename players, start a new game.")
    ;; check whether:
    ;; player-name already exists in yahtzee-players-names
    ;; or player-name is an empty string
    (cond
     ((member player-name yahtzee-players-names)
      (message "Player %s already exists!" player-name))
     ((= (length player-name) 0)
      (message "Player name cannot be an empty string!"))
     ;; when there is only an "unknown" player replace it
     (t
      (when (equal yahtzee-players-names '("unknown"))
	(setq yahtzee-players-names nil))
      (setq yahtzee-players-names (append yahtzee-players-names
					  `(,player-name)))
      (setq yahtzee-number-of-players (length yahtzee-players-names))
      (yahtzee-reset)
      (yahtzee-display-board)))))

(defun yahtzee-select-next-field ()
  "Select the next field without a fixed score."
  (interactive)
  (unless (= yahtzee-dice-thrown-number 0)
    (if (not yahtzee-selected-field)
	(setq yahtzee-selected-field (caar yahtzee-fields-alist))
      ;; get index in yahtzee-fields-alist of a cons cell with key
      ;; yahtzee-selected-field
      ;; https://emacs.stackexchange.com/questions/10492/how-to-get-element-number-in-a-list
      ;; probably not the best way to implement it but should do for the moment
      (let ((index (cl-position (assoc yahtzee-selected-field
				       yahtzee-fields-alist)
				yahtzee-fields-alist
				:test 'equal)))
	;; below I rely on the fact that e.g., (nth 5 '(1 2 3)) returns nil
	;; when `yahtzee-selected-field' is nil, no score is selected
	(setq yahtzee-selected-field
	      (car (nth (1+ index) yahtzee-fields-alist)))))

    ;; make sure that we don't land on a field with already fixed score
    (when (and (yahtzee-get-score yahtzee-selected-field yahtzee-active-player)
	       (> yahtzee-moves-left 0))
      (yahtzee-select-next-field))
    (yahtzee-display-board)))

(defun yahtzee-select-previous-field ()
  "Select the previous field without a fixed score.
Note: see the comments in `yahtzee-select-next-field'."
  (interactive)
  (unless (= yahtzee-dice-thrown-number 0)
    (if (not yahtzee-selected-field)
	(setq yahtzee-selected-field (caar (last yahtzee-fields-alist)))
      (let ((index (cl-position
		    (assoc yahtzee-selected-field yahtzee-fields-alist)
		    yahtzee-fields-alist
		    :test 'equal)))
	(if (= index 0)
	    (setq yahtzee-selected-field nil)
	  (setq yahtzee-selected-field (car (nth (1- index)
						 yahtzee-fields-alist))))))

    (when (and (yahtzee-get-score yahtzee-selected-field yahtzee-active-player)
	       (> yahtzee-moves-left 0))
      (yahtzee-select-previous-field))
    (yahtzee-display-board)))

(defun yahtzee-assign-score-to-field ()
  "Assigns a score to the selected field for the active user.
Display a warning if the selected field already has been assigned a score."
  (interactive)
  (if (or (not yahtzee-selected-field)
	  (yahtzee-get-score yahtzee-selected-field yahtzee-active-player))
      ;; THEN
      (message "This score cannot be changed.")
    ;; ELSE
    (yahtzee-set-score yahtzee-selected-field yahtzee-active-player)
    (setq yahtzee-selected-field nil)
    (when (= yahtzee-active-player (1- yahtzee-number-of-players))
      (setq yahtzee-moves-left (1- yahtzee-moves-left)))

    ;; measure time for current player move
    (let* ((time-cell (elt yahtzee-player-time yahtzee-active-player))
	   (player-game-time (cdr time-cell))
	   (player-move-start-time (car time-cell))
	   (elapsed (float-time (time-subtract (current-time)
					       player-move-start-time))))
      (setcdr time-cell (+ player-game-time elapsed)))

    (yahtzee-goto-next-player)))

(defun yahtzee-dice-toggle-fix-free ()
  "Select/deselect the outcome of dice."
  (interactive)
  ;; "1" -> 0, "2" -> 1, ..., "5" -> 4
  (let ((index (1- (string-to-number (this-command-keys)))))
    (when (elt yahtzee-dice-outcomes index)
      (if (yahtzee-dice-check-if-fixed index)
	  (yahtzee-dice-free index)
	(yahtzee-dice-fix index))
      (yahtzee-display-board))))

(defun yahtzee-dice-throw ()
  "Update the outcomes of unfixed dice."
  (interactive)
  (when (and (< yahtzee-dice-thrown-number yahtzee-dice-max-attempt)
	     ;; not all dice are fixed
	     (not (= (length yahtzee-dice-outcomes-fixed)
		     yahtzee-number-of-dice-to-throw)))

    ;; start measuring time after first throw of player
    ;; see `yahtzee-assign-score-to-field' for the time measurement
    (when (= yahtzee-dice-thrown-number 0)
      (setcar (elt yahtzee-player-time yahtzee-active-player) (current-time)))

    (dotimes (k yahtzee-number-of-dice-to-throw)
      (unless (member k yahtzee-dice-outcomes-fixed)
	(aset yahtzee-dice-outcomes
	      k
	      (elt yahtzee-dice-possible-outcomes
		   (random (length yahtzee-dice-possible-outcomes))))))
    (setq yahtzee-dice-thrown-number (1+ yahtzee-dice-thrown-number))
    (yahtzee-display-board)))

(defun yahtzee-auto-play ()
  "Finish a game automatically (for debugging purposes)."
  (interactive)
  (setq yahtzee-number-of-players 3)
  (setq yahtzee-players-names '("Mitko" "Elena" "Marina"))
  (yahtzee)
  (while (> yahtzee-moves-left 0)
    (yahtzee-dice-throw)
    (yahtzee-select-next-field)
    (yahtzee-assign-score-to-field)))



(defun yahtzee-goto-next-player ()
  "Goto the next player (after the current player fixes a score)."
  (yahtzee-set-next-player-as-active)
  (setq yahtzee-dice-thrown-number 0)
  (setq yahtzee-dice-outcomes (make-vector yahtzee-number-of-dice-to-throw nil))
  (setq yahtzee-dice-outcomes-fixed nil)
  (yahtzee-display-board))

(defun yahtzee-set-next-player-as-active ()
  "Select the next player as active."
  (setq yahtzee-active-player
	;; implement rollover
	(mod (1+ yahtzee-active-player)
	     yahtzee-number-of-players)))

(defun yahtzee-dice-fix (dice-number)
  "Fix outcome of dice with number DICE-NUMBER.
This score would not be modified untill freed."
  (push dice-number yahtzee-dice-outcomes-fixed))

(defun yahtzee-dice-free (dice-number)
  "Free outcome of dice with number DICE-NUMBER.
This score would be modified untill fixed."
  (setq yahtzee-dice-outcomes-fixed
	(delq dice-number yahtzee-dice-outcomes-fixed)))

(defun yahtzee-dice-check-if-fixed (dice-number)
  "Check whether a dice number DICE-NUMBER has been fixed."
  (member dice-number yahtzee-dice-outcomes-fixed))

(defun yahtzee-dice-get-face (dice-number)
  "Return face to use for DICE-NUMBER."
  (if (yahtzee-dice-check-if-fixed dice-number)
      'yahtzee-face-fixed
    'yahtzee-face))

(defun yahtzee-dice-count ()
  "Count the number of occurrences of all possible dice outputs.
The possible outputs are specified in `yahtzee-dice-possible-outcomes'.
`yahtzee-dice-outcomes-counts'[k] stores the number of occurrences of
`yahtzee-dice-possible-outcomes'[k]."
  (let ((i 0))
    (dolist (j yahtzee-dice-possible-outcomes)
      (aset yahtzee-dice-outcomes-counts i (cl-count j yahtzee-dice-outcomes))
      (setq i (1+ i)))))



(defun yahtzee-full-compute-score ()
  "Compute score for a full (e.g., [2 2 2 4 4]).
I assume that e.g., [3 3 3 3 3] cannot be used as a full."
  (yahtzee-dice-count)
  (let ((counts (sort (copy-sequence yahtzee-dice-outcomes-counts) '>)))
    (if (and (= (elt counts 0) 3)
	     (= (elt counts 1) 2))
	30
      0)))

(defun yahtzee-petite-suite-compute-score ()
  "Compute score for a small straight (e.g., [1 3 4 5 6])."
  (yahtzee-dice-count)
  (let ((counts (copy-sequence yahtzee-dice-outcomes-counts)))
    ;; note that one of the counts could be equal to 2
    (if (or (and (<= 1 (elt counts 0) 2)
		 (<= 1 (elt counts 1) 2)
		 (<= 1 (elt counts 2) 2)
		 (<= 1 (elt counts 3) 2))
	    (and (<= 1 (elt counts 1) 2)
		 (<= 1 (elt counts 2) 2)
		 (<= 1 (elt counts 3) 2)
		 (<= 1 (elt counts 4) 2))
	    (and (<= 1 (elt counts 2) 2)
		 (<= 1 (elt counts 3) 2)
		 (<= 1 (elt counts 4) 2)
		 (<= 1 (elt counts 5) 2)))
	25
      0)))

(defun yahtzee-grande-suite-compute-score ()
  "Compute score for a large straight (e.g., [1 2 3 4 5])."
  (yahtzee-dice-count)
  (let ((counts (copy-sequence yahtzee-dice-outcomes-counts)))
    (if (or (and (= (elt counts 0) 1)
		 (= (elt counts 1) 1)
		 (= (elt counts 2) 1)
		 (= (elt counts 3) 1)
		 (= (elt counts 4) 1))
	    (and (= (elt counts 1) 1)
		 (= (elt counts 2) 1)
		 (= (elt counts 3) 1)
		 (= (elt counts 4) 1)
		 (= (elt counts 5) 1)))
	35
      0)))

(defun yahtzee-carre-compute-score ()
  "Compute score for a carre (e.g., [3 3 3 3 1]).
Here I use a fixed score instead of the official sum of all dice."
  (yahtzee-dice-count)
  (let ((counts (sort (copy-sequence yahtzee-dice-outcomes-counts) '>)))
    (if (<= 4 (elt counts 0) 5)
	40
      0)))

(defun yahtzee-rigole-compute-score ()
  "Compute score for a rigole (e.g., [6 6 6 6 1])."
  (yahtzee-dice-count)
  (let ((counts (sort (copy-sequence yahtzee-dice-outcomes-counts) '>))
	;; 1. convert the vector yahtzee-dice-outcomes to a list
	;; 2. delete duplicates from the list
	;; 3. sort the list and assign in to the variable unique
	(unique (sort
		 (delete-dups (mapcar (lambda (x) x) yahtzee-dice-outcomes))
		 '<)))
    (if (and (= 4 (elt counts 0))
	     (or (equal unique '(1 6))
		 (equal unique '(2 5))
		 (equal unique '(3 4))))
	50
      0)))

(defun yahtzee-yams-compute-score ()
  "Compute score for a yams (e.g., [2 2 2 2 2])."
  (yahtzee-dice-count)
  (let ((counts (sort (copy-sequence yahtzee-dice-outcomes-counts) '>)))
    (if (= (elt counts 0) 5)
	50
      0)))

;; This is a more general way of implementing the yahtzee-k-compute-score
;; function below. It doesn't care about the order of numbers in
;; `yahtzee-dice-possible-outcomes' but it takes an input argument and
;; in `yahtzee-fields-alist' I want each function associated with a field
;; to be without input arguments (i.e., a function dedicated to the particular
;; field). So, I would have to live with the manual implementation below.
(defun yahtzee-number-compute-score (index)
  "Compute score for number at INDEX in `yahtzee-dice-possible-outcomes'."
  (yahtzee-dice-count)
  (let ((counts (copy-sequence yahtzee-dice-outcomes-counts))
	(number (nth index yahtzee-dice-possible-outcomes)))
    (* number (elt counts index))))

(defun yahtzee-1-compute-score ()
  "Compute score for 1's."
  (yahtzee-dice-count)
  (let ((counts (copy-sequence yahtzee-dice-outcomes-counts)))
    (elt counts 0)))

(defun yahtzee-2-compute-score ()
  "Compute score for 2's."
  (yahtzee-dice-count)
  (let ((counts (copy-sequence yahtzee-dice-outcomes-counts)))
    (* 2 (elt counts 1))))

(defun yahtzee-3-compute-score ()
  "Compute score for 3's."
  (yahtzee-dice-count)
  (let ((counts (copy-sequence yahtzee-dice-outcomes-counts)))
    (* 3 (elt counts 2))))

(defun yahtzee-4-compute-score ()
  "Compute score for 4's."
  (yahtzee-dice-count)
  (let ((counts (copy-sequence yahtzee-dice-outcomes-counts)))
    (* 4 (elt counts 3))))

(defun yahtzee-5-compute-score ()
  "Compute score for 5's."
  (yahtzee-dice-count)
  (let ((counts (copy-sequence yahtzee-dice-outcomes-counts)))
    (* 5 (elt counts 4))))

(defun yahtzee-6-compute-score ()
  "Compute score for 6's."
  (yahtzee-dice-count)
  (let ((counts (copy-sequence yahtzee-dice-outcomes-counts)))
    (* 6 (elt counts 5))))

(defun yahtzee-chance-compute-score ()
  "Compute score for chance."
  (apply '+ (mapcar (lambda (x) x) yahtzee-dice-outcomes)))

(defun yahtzee-brelan-compute-score ()
  "Compute score for brelan (e.g., [5 5 5 3 1])."
  (yahtzee-dice-count)
  (let ((counts (sort (copy-sequence yahtzee-dice-outcomes-counts) '>)))
    (if (<= 3 (elt counts 0) 5)
	(apply '+ (mapcar (lambda (x) x) yahtzee-dice-outcomes))
      0)))

(defun yahtzee-two-pair-compute-score ()
  "Compute score for two-pair (e.g., [5 5 1 3 3])."
  (yahtzee-dice-count)
  (let ((counts (sort (copy-sequence yahtzee-dice-outcomes-counts) '>)))
    (if (or (and (= (elt counts 0) 2)
		 (= (elt counts 1) 2))
	    ;; full is two-pair as well
	    (and (= (elt counts 0) 3)
		 (= (elt counts 1) 2))
	    ;; carre and yams are two-pair as well
	    (<= 4 (elt counts 0) 5))
	(apply '+ (mapcar (lambda (x) x) yahtzee-dice-outcomes))
      0)))

(defun yahtzee-plus-compute-score ()
  "Compute score for plus."
  (let ((score-plus (apply '+ (mapcar (lambda (x) x) yahtzee-dice-outcomes)))
	(score-minus (yahtzee-get-score "minus" yahtzee-active-player)))
    (if score-minus
	(if (> score-plus score-minus)
	    score-plus
	  0)
      score-plus)))

(defun yahtzee-minus-compute-score ()
  "Compute score for minus."
  (let ((score-minus (apply '+ (mapcar (lambda (x) x) yahtzee-dice-outcomes)))
	(score-plus (yahtzee-get-score "plus" yahtzee-active-player)))
    (if score-plus
	(if (< score-minus score-plus)
	    score-minus
	  0)
      score-minus)))



(defun yahtzee-initialize-fields-alist ()
  "Initialize `yahtzee-fields-alist'."
  (setq yahtzee-fields-alist nil)
  (push '("chance" . yahtzee-chance-compute-score) yahtzee-fields-alist)
  (push '("minus" . yahtzee-minus-compute-score) yahtzee-fields-alist)
  (push '("plus" . yahtzee-plus-compute-score) yahtzee-fields-alist)
  (push '("rigole" . yahtzee-rigole-compute-score) yahtzee-fields-alist)
  (push '("yams" . yahtzee-yams-compute-score) yahtzee-fields-alist)
  (push '("carré" . yahtzee-carre-compute-score) yahtzee-fields-alist)
  (push '("grande-suite" . yahtzee-grande-suite-compute-score)
	yahtzee-fields-alist)
  (push '("petite-suite" . yahtzee-petite-suite-compute-score)
	yahtzee-fields-alist)
  (push '("brelan" . yahtzee-brelan-compute-score) yahtzee-fields-alist)
  ;; (push '("two-pair" . yahtzee-two-pair-compute-score) yahtzee-fields-alist)
  (push '("full" . yahtzee-full-compute-score) yahtzee-fields-alist)
  (push '("6" . yahtzee-6-compute-score) yahtzee-fields-alist)
  (push '("5" . yahtzee-5-compute-score) yahtzee-fields-alist)
  (push '("4" . yahtzee-4-compute-score) yahtzee-fields-alist)
  (push '("3" . yahtzee-3-compute-score) yahtzee-fields-alist)
  (push '("2" . yahtzee-2-compute-score) yahtzee-fields-alist)
  (push '("1" . yahtzee-1-compute-score) yahtzee-fields-alist))



(defun yahtzee-field-compute-score (field-name)
  "Compute the score for field with name FIELD-NAME.
This computation is based on `yahtzee-dice-outcomes' and is not
automatically recorded in `yahtzee-scores'."
  (let ((field-function (cdr (assoc field-name yahtzee-fields-alist))))
    (funcall field-function)))

(defun yahtzee-set-score (field-name player &optional score)
  "Set the score for FIELD-NAME for PLAYER.
This records the score in `yahtzee-scores'.
The optional argument SCORE can be used to disregard the outcomes in
`yahtzee-dice-outcomes' (e.g., it is used in `yahtzee-load-game-score')."
  (setcdr (assoc field-name
		 (elt yahtzee-scores player))
	  (if score
	      score
	    (yahtzee-field-compute-score field-name))))

(defun yahtzee-get-score (field-name player)
  "Return the score for FIELD-NAME for PLAYER.
This reads the score from `yahtzee-scores'."
  (cdr (assoc field-name (elt yahtzee-scores player))))

(defun yahtzee-compute-current-score (player)
  "Return the current score for PLAYER (including bonus)."
  (let ((total-score 0)
	field-name
	field-score)
    (dolist (field-pair yahtzee-fields-alist)
      (setq field-name (car field-pair))
      (setq field-score (yahtzee-get-score field-name player))
      (when field-score
	(setq total-score (+ total-score field-score))))
    total-score))

(defun yahtzee-compute-bonus (player)
  "Return the bonus for PLAYER.
A bonus is awarded when the player scores at least
3*(1+2+3+4+5+6) = 63 in total for the categories 1,2,3,4,5,6."
  (let ((bonus-threshold 0)
	(field-names '("1" "2" "3" "4" "5" "6"))
	field-score)
    (dolist (field-name field-names)
      (setq field-score (yahtzee-get-score (pop field-names) player))
      (when field-score
	(setq bonus-threshold (+ bonus-threshold field-score))))
    (if (>= bonus-threshold 63)
	30
      0)))



(defvar yahtzee-mode-map
  (let ((map (make-sparse-keymap)))
    (dotimes (k yahtzee-number-of-dice-to-throw)
      (define-key
	map
	(kbd  (number-to-string (1+ k)))
	'yahtzee-dice-toggle-fix-free))
    (define-key map (kbd     "<SPC>") 'yahtzee-dice-throw)
    (define-key map (kbd    "<down>") 'yahtzee-select-next-field)
    (define-key map (kbd      "<up>") 'yahtzee-select-previous-field)
    (define-key map (kbd       "RET") 'yahtzee-assign-score-to-field)
    (define-key map (kbd         ",") 'beginning-of-buffer)
    (define-key map (kbd         ".") 'end-of-buffer)
    (define-key map (kbd     "C-c p") 'yahtzee-set-player-name)
    (define-key map (kbd     "C-c P") 'yahtzee-reset-players)
    (define-key map (kbd     "C-c n") 'yahtzee-new-game)
    (define-key map (kbd         "w") 'yahtzee-save-game-score)
    ;; ignore some keybindings
    (define-key map (kbd    "<left>") 'ignore)
    (define-key map (kbd   "<right>") 'ignore)
    (define-key map (kbd         "0") 'ignore)
    ;; disable the remaining keys to 9
    (dolist (k (number-sequence yahtzee-number-of-dice-to-throw 8))
      (define-key map (kbd  (number-to-string (1+ k))) 'ignore))
    map)
  "Keymap for yahtzee major mode.")

(define-derived-mode yahtzee-mode special-mode "yahtzee"
  (toggle-truncate-lines))

(defun yahtzee-initialize-scores ()
  "Initialize all scores for all players to nil."
  ;; initialize each alist to nil
  (setq yahtzee-scores (make-vector yahtzee-number-of-players nil))
  (dotimes (player yahtzee-number-of-players)
    ;; initialize scores-alist with each field set to nil
    (let (field-name
	  scores-alist)
      (dolist (field-pair yahtzee-fields-alist)
	(setq field-name (car field-pair))
	(push `(,field-name . nil) scores-alist))
      (aset yahtzee-scores player scores-alist))))

(defun yahtzee-initialize-time ()
  "Initialize player time for all players to nil."
  ;; initialize each alist to nil
  (setq yahtzee-player-time (make-vector yahtzee-number-of-players nil))
  (dotimes (player yahtzee-number-of-players)
    ;; (player-move-start-time . player-game-time)
    (aset yahtzee-player-time player (cons nil 0))))

(defun yahtzee-reset ()
  "Reset/initialize a new game."

  ;; ====================================================================
  ;; handle players
  ;; ====================================================================
  ;; when yahtzee-number-of-players != (length yahtzee-players-names)
  ;; set yahtzee-number-of-players = (length yahtzee-players-names)
  (unless (= (length yahtzee-players-names) yahtzee-number-of-players)
    (setq yahtzee-number-of-players (length yahtzee-players-names)))
  ;; ====================================================================

  (yahtzee-initialize-fields-alist)
  (yahtzee-initialize-scores)
  (yahtzee-initialize-time)
  (setq yahtzee-loaded-game nil)
  (setq yahtzee-game-over nil)
  (setq yahtzee-active-player 0)
  (setq yahtzee-dice-thrown-number 0)
  (setq yahtzee-moves-left (length yahtzee-fields-alist))
  (setq yahtzee-game-start-time (current-time))
  (setq yahtzee-dice-outcomes-fixed nil)
  (setq yahtzee-selected-field nil)

  (setq yahtzee-dice-outcomes
	(make-vector yahtzee-number-of-dice-to-throw nil))
  (setq yahtzee-dice-outcomes-counts
	(make-vector (length yahtzee-dice-possible-outcomes) 0)))

(defun yahtzee ()
  "Start a new game."
  (interactive)
  (switch-to-buffer (generate-new-buffer-name yahtzee-buffer-name-start))
  (buffer-disable-undo)
  (yahtzee-mode)
  (yahtzee-reset)
  (yahtzee-display-board))

(defun yahtzee-new-game ()
  "Start a new game."
  (interactive)
  (if (or yahtzee-game-over
	  ;; before all players have finished their
	  ;; first move we don't ask for verification
	  (= yahtzee-moves-left (length yahtzee-fields-alist)))
      ;;THEN
      (progn
	(yahtzee-rotate-players)
	(yahtzee-reset)
	(yahtzee-display-board))
    ;; ELSE
    ;; ask for confirmation only if the game has not been finished
    (when (y-or-n-p "Press y to start a new game.  Start a new game? ")
      (yahtzee-rotate-players)
      (yahtzee-reset)
      (yahtzee-display-board))))

(defun yahtzee-rotate-players ()
  "Rotate names of players.
The last player in a given game plays first in the next game."
  (when (> (length yahtzee-players-names) 1)
    (let ((last-player (car (last yahtzee-players-names))))
      (delete last-player yahtzee-players-names)
      (push last-player yahtzee-players-names))))



(defun yahtzee-display-score-player (field-name player)
  "Display cell with score for FIELD-NAME for PLAYER."
  (let ((score (yahtzee-get-score field-name player)))
    ;; IF (if score has been recorded)
    (if score
	;; THEN
	(let ((point (point)))
	  (insert (format "|  %2d   " score))
	  (put-text-property (+ point 1)
			     (+ point 8)
			     'font-lock-face
			     'yahtzee-face-fixed))
      ;; ELSE
      ;; first handle the case when `yahtzee-active-player' is nil
      ;; (this happens when we load games that were saved before they ended)
      (if (and yahtzee-active-player
	       (= player yahtzee-active-player))
	  ;; THEN (active player)
	  (if (= yahtzee-dice-thrown-number 0)
	      (insert (format "|       "))
	    (let ((point (point)))
	      (insert (format "|  %2d   "
			      (yahtzee-field-compute-score field-name)))
	      (when (and yahtzee-selected-field
			 (equal yahtzee-selected-field field-name))
		(put-text-property (+ point 1) (+ point 8)
		 'font-lock-face 'yahtzee-face-selected))))
	;; ELSE (other players)
	(insert "|       ")))))

(defun yahtzee-display-board (&optional only-scores)
  "Display the yahtzee board.
When ONLY-SCORES is non-nil display only scores (no dice)."
  (unless (string-prefix-p yahtzee-buffer-name-start (buffer-name))
    (error (format "We are not in a %s buffer." yahtzee-buffer-name-start)))
  (let ((inhibit-read-only t)
	(fields-dice-separation "     "))
    (erase-buffer)

    ;; ================================================================
    ;; yahtzee fields
    ;; ================================================================

    ;; labels of players
    (dotimes (player yahtzee-number-of-players)
      (insert "+-------"))
    (insert "+----------------+\n")
    (dotimes (player yahtzee-number-of-players)
      ;; (insert (format "|  %2d   " (1+ player)))
      (insert (format "|  (%s)  " (nth player yahtzee-players-labels))))
    (insert "|   field names  |\n")

    (dolist (field yahtzee-fields-alist)
      (let ((field-name (car field)))
	;; opening line
    	(dotimes (player yahtzee-number-of-players)
    	  (insert "+-------"))
    	(insert "+----------------+\n")

    	(dotimes (player yahtzee-number-of-players)
	  (yahtzee-display-score-player field-name player))
    	(insert (format "|  %12s  |\n" field-name))))
    ;; closing line
    (dotimes (player yahtzee-number-of-players)
      (insert "+-------"))
    (insert "+----------------+\n")

    ;; ================================================================
    ;; dice
    ;; ================================================================

    (unless only-scores
      (goto-char (point-min))
      (end-of-line)
      (insert fields-dice-separation)
      (dotimes (k yahtzee-number-of-dice-to-throw)
	(insert "+-------"))
      (insert "+")

      ;; insert empty line above the number
      (forward-line)
      (end-of-line)
      (insert fields-dice-separation)
      (dotimes (k yahtzee-number-of-dice-to-throw)
	(let ((point (point)))
	  (insert "|       ")
	  (put-text-property (+ point 1) (+ point 8)
			     'font-lock-face (yahtzee-dice-get-face k))))
      (insert "|")

      ;; insert the number
      (forward-line)
      (end-of-line)
      (insert fields-dice-separation)
      (dotimes (k yahtzee-number-of-dice-to-throw)
	(let ((point (point)))
	  (insert (format "|   %1d   " (if (elt yahtzee-dice-outcomes k)
					   (elt yahtzee-dice-outcomes k)
					 0)))
	  (put-text-property (+ point 1) (+ point 8)
			     'font-lock-face (yahtzee-dice-get-face k))))
      (insert "|")

      ;; insert empty line below the number
      (forward-line)
      (end-of-line)
      (insert fields-dice-separation)
      (dotimes (k yahtzee-number-of-dice-to-throw)
	(let ((point (point)))
	  (insert "|       ")
	  (put-text-property (+ point 1) (+ point 8) 'font-lock-face
			     (yahtzee-dice-get-face k))))
      (insert "|")

      ;; insert the bottom line
      (forward-line)
      (end-of-line)
      (insert fields-dice-separation)
      (dotimes (k yahtzee-number-of-dice-to-throw)
	(insert "+-------"))
      (insert "+")

      ;; assign a number to each dice for convenience
      (forward-line)
      (end-of-line)
      (insert fields-dice-separation)
      (dotimes (k yahtzee-number-of-dice-to-throw)
	(insert (format "    %d   " (1+ k))))


      ;; number of throws
      (goto-char (point-min))
      (end-of-line)
      (insert "   +-------+")
      (forward-line)
      (end-of-line)
      (let ((point (point)))
	(insert "   |       |")
	(when (= yahtzee-dice-thrown-number yahtzee-dice-max-attempt)
       	  (put-text-property (+ point 4) (+ point 11)
			     'font-lock-face 'yahtzee-face-fixed)))
      (forward-line)
      (end-of-line)
      (let ((point (point)))
	(insert (format "   |   %d   |" yahtzee-dice-thrown-number))
	(when (= yahtzee-dice-thrown-number yahtzee-dice-max-attempt)
       	  (put-text-property (+ point 4) (+ point 11)
			     'font-lock-face 'yahtzee-face-fixed)))
      (forward-line)
      (end-of-line)
      (let ((point (point)))
	(insert "   |       |")
	(when (= yahtzee-dice-thrown-number yahtzee-dice-max-attempt)
       	  (put-text-property (+ point 4) (+ point 11)
			     'font-lock-face 'yahtzee-face-fixed)))
      (forward-line)
      (end-of-line)
      (insert "   +-------+")
      (forward-line)
      (end-of-line)
      (insert "     #throws"))

    ;; ================================================================
    ;; - number of moves left
    ;; - names of players
    ;; ================================================================

    (unless only-scores
      (forward-line 3)
      (end-of-line)
      (insert fields-dice-separation)
      (insert "+-----------------+")
      (forward-line)
      (end-of-line)
      (insert fields-dice-separation)
      (insert (format "| fields left: %2d |" yahtzee-moves-left))
      (forward-line)
      (end-of-line)
      (insert fields-dice-separation)
      (insert "+-----------------+"))

    (when only-scores
      (goto-char (point-min)))

    (forward-line 3)
    (end-of-line)
    (insert fields-dice-separation)
    (dotimes (player yahtzee-number-of-players)
      (insert (format "(%s) %-8s: %3d (includes BONUS: %d)"
		      (nth player yahtzee-players-labels)
		      (nth player yahtzee-players-names)
		      (+ (yahtzee-compute-current-score player)
			 (yahtzee-compute-bonus player))
		      (yahtzee-compute-bonus player)))
      (when (and (not only-scores)
		 (= player yahtzee-active-player))
	(insert "  «")
	(put-text-property (- (point) 1) (point)
			   'font-lock-face 'yahtzee-face-user-arrow))
      (forward-line 2)
      (end-of-line)
      (insert fields-dice-separation))

    ;; ================================================================
    ;; - announce the winner when the game is over
    ;; - include game duration
    ;; ================================================================

    (when (and (= yahtzee-moves-left 0)
	       ;; the above condition alone is not sufficient because
	       ;; when there are zero moves left, we can still perform
	       ;; an action that calls `yahtzee-display-board', and we
	       ;; are constantly asked whether we want to save the game.
	       (not yahtzee-game-over))
      (setq yahtzee-game-over t)
      (forward-line 2)
      (end-of-line)
      (insert fields-dice-separation)
      (let ((top-score 0)
	    score
	    player-index
	    winner
	    ;; string to separate the shared first place winners
	    separation-string)
	;; first find the top-score
	(dotimes (player yahtzee-number-of-players)
	  (setq score (+ (yahtzee-compute-current-score player)
			 (yahtzee-compute-bonus player)))
	  (when (> score top-score)
	    (setq top-score score)))

	;; find shared first place winners
	(dotimes (player yahtzee-number-of-players)
	  ;; I do it for the second time but it is very cheap anyway
	  (setq score (+ (yahtzee-compute-current-score player)
			 (yahtzee-compute-bonus player)))
	  (when (= score top-score)
	    (if (not winner)
		(setq separation-string "")
	      (setq separation-string "/"))
	    (setq winner
		  (append winner `(,(concat separation-string
					    (nth player
						 yahtzee-players-names)))))))

	(let ((point (point)))
	  (insert (format "WINNER(S): %s" (apply 'concat winner)))
	  (put-text-property point (+ point 10) 'font-lock-face 'yahtzee-face)))

      ;; game duration
      (unless yahtzee-loaded-game
	(let ((elapsed (float-time (time-subtract (current-time)
						  yahtzee-game-start-time))))
	  (forward-line 2)
	  (end-of-line)
	  (insert fields-dice-separation)
	  (insert (format "total game time      : %.2f min." (/ elapsed 60))))

	(forward-line)
	(end-of-line)
	(insert fields-dice-separation)
	(insert (format "average time per move: "))
	(dotimes (player yahtzee-number-of-players)
	  (let ((player-time (cdr (elt yahtzee-player-time player))))
	    (forward-line)
	    (end-of-line)
	    (insert (concat fields-dice-separation "  - "))
	    (insert (format "%-8s: %f sec."
			    (nth player yahtzee-players-names)
			    (/ player-time (length yahtzee-fields-alist)))))))

      (when (and (not yahtzee-loaded-game)
		 (y-or-n-p "Press y to save the game.  Save the game? "))
	(if (not yahtzee-output-file-base)
	    (call-interactively 'yahtzee-save-game-score)
	  ;; current-number: the number of already saved files
	  ;; filename      : the newly generated name
	  (let* ((current-number
		  (string-to-number
		   (substring ;; "remove \n"
		    (shell-command-to-string
		     ;; count number of files
		     (concat "find "
			     (file-name-directory yahtzee-output-file-base)
			     " -name \""
			     (file-name-nondirectory yahtzee-output-file-base)
			     "\" | wc -l"))
		    0 -1)))
		 (filename
		  (replace-regexp-in-string "\*"
					    (format "%04d" (1+ current-number))
					    yahtzee-output-file-base)))
	    (yahtzee-save-game-score filename)))))))



(defun yahtzee-save-game-score (filename)
  "Store the game data in FILENAME (in json format)."
  (interactive "FFilename: ")
  (let ((json-encoding-pretty-print t)
	score
	name-score-pair)

    (dotimes (player yahtzee-number-of-players)
      (setq score (+ (yahtzee-compute-current-score player)
		     (yahtzee-compute-bonus player)))
      (push `(,(nth player yahtzee-players-names) . ,score) name-score-pair))

    (write-region (json-encode `(("players"     . ,yahtzee-players-names)
				 ("total-score" . ,(reverse name-score-pair))
				 ("scores"      . ,yahtzee-scores)))
		  nil filename)))

(defun yahtzee-load-game-score (filename)
  "Load the game data from FILENAME (in json format) and show the result.
`yahtzee-fields-alist' is initialized with the fields appearing in FILENAME."
  (interactive "fFilename: ")
  (let* ((a (json-read-file filename))
	 (players (cdr (assoc 'players a)))
	 (scores  (cdr (assoc 'scores  a)))
	 ;; all players have the same fields
	 (numb-fields  (length (elt scores 0))))

    ;; switch to new buffer before initializing local variables
    (switch-to-buffer (generate-new-buffer-name
		       (concat yahtzee-buffer-name-start "-load")))
    (buffer-disable-undo)
    (yahtzee-mode)

    ;; -------------------------------------------------------------------
    ;; initialize variables
    ;; -------------------------------------------------------------------
    (setq yahtzee-loaded-game t)

    (setq yahtzee-number-of-players (length players))
    (setq yahtzee-players-names (mapcar (lambda (x) x) players))
    (setq yahtzee-moves-left 0)

    (setq yahtzee-fields-alist nil)
    (dolist (name-score-pair (elt scores 0))
      ;; here I don't need the functions for computing scores
      ;; (and anyway, it is not stored in the json file)
      (push `(,(symbol-name (car name-score-pair)) . nil) yahtzee-fields-alist))

    (yahtzee-initialize-scores)
    ;; -------------------------------------------------------------------

    ;; set scores
    (dotimes (player yahtzee-number-of-players)
      (dotimes (i numb-fields)
	(let* ((cons-cell (nth i (elt scores player)))
	       (field-name  (symbol-name (car cons-cell)))
	       (field-score (cdr cons-cell)))
	  (when field-score
	    (yahtzee-set-score field-name player field-score)))))

    ;; display game results
    (yahtzee-display-board t)))



(provide 'yahtzee)

;;; yahtzee.el ends here
