;;; key-quiz.el --- Emacs Keys Quiz  -*- lexical-binding: t -*-

;; Copyright (c) 2020 Federico Tedin

;; Author: Federico Tedin <federicotedin@gmail.com>
;; Homepage: https://github.com/federicotdn/key-quiz
;; Keywords: games
;; Package-Commit: 6d31fcf78a1ab1841f735dfb5cbd2bf6b2ed25db
;; Package-Version: 20200226.2129
;; Package-X-Original-Version: 0.1
;; Package-Requires: ((emacs "26"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Key Quiz is a game where the player must type in key sequences
;; corresponding to different Emacs commands, chosen at random.

;; The game includes a variant, called "reverse mode", where the
;; player is given a key sequence and then must answer with the
;; corresponding command.

;;; Code:

(require 'subr-x)
(require 'seq)
(require 'cl-lib)
(require 'gamegrid)

(defgroup key-quiz nil
  "Play an Emacs Key Quiz."
  :prefix "key-quiz-"
  :group 'games)

(defcustom key-quiz-reverse-hints-count 6
  "Number of hints to show when playing in 'reverse mode'."
  :type 'integer)

(defcustom key-quiz-partial-answer-score 5
  "Number of points awarded for each correct part of a key answered."
  :type 'integer)

(defcustom key-quiz-wrong-answer-score -10
  "Penalty for answering a question incorrectly."
  :type 'integer)

(defcustom key-quiz-game-length 20
  "Number of questions per game."
  :type 'integer)

(defcustom key-quiz-matching-regexp "^<?[MC]"
  "Regexp used to match valid mappings in the quiz.
The regexp should start with ^ and be valid for
`delete-non-matching-lines'.  The regexp is not used when playing a
custom game."
  :type 'string)

(defcustom key-quiz-use-mode 'fundamental-mode
  "Mode to use when fetching key-command list.
This variable is ignored when playing a custom game."
  :type 'function)

(defvar-local key-quiz--keys nil
  "Currently loaded keys and commands.")

(defvar-local key-quiz--score 0
  "Current score.")

(defvar-local key-quiz--game-reverse nil
  "Non-nil if currently playing in 'reverse mode'.")

(defvar-local key-quiz--custom-keys nil
  "Custom key-command alist specified by the player.")

(defvar-local key-quiz--round 0
  "Current round number.")

(defvar-local key-quiz--last-state nil
  "Last game state. Used for resuming.")

(defvar-local key-quiz--prompt-pos nil
  "Buffer position of last prompt. Used when deleting Pause text.")

(defvar-local key-quiz--score-file "key-quiz-scores"
  "File for holding Key Quiz high scores.")

(defface key-quiz-question '((t :inherit bold))
  "Face for Key Quiz questions.")

(defface key-quiz-correct '((t :inherit success
			       :weight bold))
  "Face for Key Quiz correct answers.")

(defface key-quiz-partial '((t :inherit warning
			       :weight bold))
  "Face for Key Quiz partially correct answers.")

(defface key-quiz-wrong '((t :inherit error
			     :weight normal))
  "Face for Key Quiz wrong answers.")

(defface key-quiz-answer '((t :inherit minibuffer-prompt
			      :weight bold))
  "Face for Key Quiz provided answers.")

(defvar key-quiz-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "r") 'key-quiz--restart)
    (define-key map (kbd "c") 'key-quiz--resume)
    (define-key map (kbd "q") 'key-quiz--quit)
    (define-key map (kbd "RET") 'ignore)
    map))

(define-derived-mode key-quiz-mode special-mode "Key Quiz"
  "Key Quiz mode.
Shows current score and more information on the header line."
  (setq header-line-format
	'((:eval (propertize (format "Score: %s"
				     (int-to-string key-quiz--score))
			     'font-lock-face 'bold))
	  " - Use 'C-g r' to restart the game, 'p RET' to pause")))

(defun key-quiz--get-keys ()
  "Return an alist of (KEY . COMMAND), representing active keybindings.
Many keys and commands are filtered out to only include those which
the player is likely to remember or guess correctly.  The initial key
list is generated using `describe-buffer-bindings' on
`key-quiz-use-mode'."
  (let (keys)
    (with-temp-buffer
      (funcall key-quiz-use-mode)
      (describe-buffer-bindings (current-buffer))
      (goto-char (point-min))
      (delete-non-matching-lines key-quiz-matching-regexp)
      (delete-matching-lines
       "Prefix Command\\|Keyboard Macro\\|mouse\\|C-g\\|\\.\\.")
      (while (not (eobp))
	(let ((line (buffer-substring (line-beginning-position)
				      (line-end-position))))
	  (string-match "\\(.+\\)[[:blank:]]+\\([^[:blank:]]+\\)" line)
	  (let ((key (match-string 1 line))
		(command (match-string 2 line)))
	    ;; Do not include C-g in keys list
	    (when (and (not (string= command "keyboard-quit"))
		       (commandp (intern-soft command)))
	      (push (cons (string-trim key) command) keys))))
	(forward-line 1)))
    keys))

(defun key-quiz--shuffle-list (list)
  "Shuffles LIST randomly, modifying it in-place.
Returns LIST."
  (dolist (i (reverse (number-sequence 1 (1- (length list)))))
    (let ((j (random (1+ i)))
	  (tmp (elt list i)))
      (setf (elt list i) (elt list j))
      (setf (elt list j) tmp)))
  list)

(defun key-quiz--insert-separator ()
  "Insert a horizontal separator in the current buffer."
  (newline)
  (insert (propertize (make-string (window-width) ? )
		      'font-lock-face 'underline
		      'rear-nonsticky t))
  (newline))

(defun key-quiz--keys-distance (k1 k2)
  "Return (NUMBER . EQUALS).
NUMBER is the amount of inputs K1 and K2
share, and EQUALS is (string= K1 K2)."
  (if (not (string= k1 k2))
      (let ((l1 (split-string k1))
	    (l2 (split-string k2))
	    (matches 0))
	(dotimes (i (length l1))
	  (when (and (< i (length k2))
		     (string= (nth i l1)
			      (nth i l2)))
	    (setq matches (1+ matches))))
	(cons matches nil))
    (cons (length (split-string k1)) t)))

(defun key-quiz--command-description (cmd)
  "Get a short description of command CMD.
Returns nil if no description was found."
  (let ((cmd-sym (intern-soft cmd)))
    (when (commandp cmd-sym)
      (let ((doc (documentation cmd-sym)))
	(progn
	  (when (and doc (string-match "^\\(.+?\\.\\)$" doc))
	    (match-string 1 doc)))))))

(defun key-quiz--ask ()
  "Prompt the player for a key corresponding to a command.
A random element from `key-quiz--keys' is chosen, and the player is
shown the chosen command.  The player must then guess one of the keys
corresponding to the command (as there may be more than one).
Finally, return (SCORE . CORRECT-ANSWER), where SCORE is a number
\(positive or negative) which should be added to `key-quiz--score',
and CORRECT-ANSWER is the correct answer in case the player did not
answer correctly, or nil otherwise."
  (let* ((pair (if key-quiz--last-state
		   (car key-quiz--last-state)
		 (seq-random-elt key-quiz--keys)))
	 (command (cdr pair))
	 (keys (if key-quiz--last-state
		   (cdr key-quiz--last-state)
		 ;; One command may be bound to multiple keys, fetch them all.
		 (mapcar 'car (seq-filter (lambda (p)
					    (string= (cdr p) command))
					  key-quiz--keys))))
	 (all-keys (mapconcat 'identity keys " or "))
	 (best-matches nil)
	 result
	 entered-key)
    (if key-quiz--last-state
	;; We are resuming, do not modify key list again.
	(setq key-quiz--last-state nil)
      ;; First time using this key-command pair.
      (dolist (key keys)
	;; Delete all key-command pairs that map to the same command
	;; from global key-command list. This way we don't ask for the
	;; same command more than once.
	(setf key-quiz--keys (cl-delete key key-quiz--keys
					:key #'car :test #'equal))))
    (setq key-quiz--prompt-pos (point))
    (insert "Enter key for command:")
    (newline 2)
    (insert "    " (propertize command 'font-lock-face 'key-quiz-question))
    (let ((description (key-quiz--command-description command)))
      (when description
	(newline)
	(insert "    " (propertize description 'font-lock-face 'italic))))
    (newline 2)
    (when (> (length keys) 1)
      (insert (format "There are %s possible answers." (length keys)))
      (newline))
    (insert "Your answer: ")
    (setq entered-key (key-description (read-key-sequence-vector
					"Key (RET to give up): ")))
    (cond
     ((string= entered-key "C-g") (throw 'end t))
     ((string= entered-key "p")
      ;; Save game state for resume.
      (setq key-quiz--last-state (cons pair keys))
      (throw 'end 'pause))
     ((string= entered-key "RET") (setq entered-key "")))
    (insert entered-key)
    (dolist (key keys)
      (let* ((matches-total (key-quiz--keys-distance entered-key key))
	     (matches (car matches-total))
	     (is-total (cdr matches-total)))
	(if (or (not best-matches)
		(< best-matches matches)
		is-total)
	    (setq result (cons (* matches key-quiz-partial-answer-score)
			       (unless is-total all-keys))
		  best-matches matches))))
    result))

(defun key-quiz--ask-reverse ()
  "Prompt the player for a command corresponding to a key.
A random element from `key-quiz--keys' is chosen, and the player is
shown the chosen key.  The player must then guess the command
corresponding to the key.  Finally, return (SCORE . CORRECT-ANSWER),
where SCORE is a number (positive or negative) which should be added
to `key-quiz--score', and CORRECT-ANSWER is the correct answer in case
the player did not answer correctly, or nil otherwise."
  (let* ((pair (if key-quiz--last-state
		   (car key-quiz--last-state)
		 (seq-random-elt key-quiz--keys)))
	 (key (car pair))
	 (command (cdr pair))
	 entered-command
	 hints)
    (if key-quiz--last-state
	;; We are resuming, do not modify key list again.
	(setq key-quiz--last-state nil)
      ;; Delete corresponding key-command pair in global list.
      (setf key-quiz--keys (cl-delete key key-quiz--keys :key #'car :test #'equal)))
    ;; Randomly select hints.
    (setq hints (mapcar 'cdr (cl-subseq (key-quiz--shuffle-list (copy-sequence
								 key-quiz--keys))
					0 (min (length key-quiz--keys)
					       (1- key-quiz-reverse-hints-count)))))
    (when hints
      (push command hints)
      (key-quiz--shuffle-list hints))
    (setq key-quiz--prompt-pos (point))
    (insert (format "Enter command for key: %s "
		    (propertize key 'font-lock-face 'key-quiz-question)))
    (newline)
    (insert "Your answer: ")
    ;; TODO: Handle C-g correctly
    (setq entered-command (completing-read "Command (TAB to view hints): "
					   hints))
    (when (string= entered-command "p")
      ;; Save game state for resume.
      (setq key-quiz--last-state (cons pair nil))
      (throw 'end 'pause))
    (insert entered-command)
    (if (string= entered-command command)
	(cons (* (length (split-string key)) key-quiz-partial-answer-score)
	      nil)
      (cons key-quiz-wrong-answer-score command))))

(defun key-quiz--game-loop (ask-fn)
  "Iterate until `key-quiz-game-length' rounds have passed.
Ask the player questions using ASK-FN, which should be a function
returing (SCORE . CORRECT-ANSWER).  Return t if the game was
cancelled, nil if it ended normally, and `pause' if the game was
paused."
  (catch 'end
    (while t
      (when (or (= 0 (length key-quiz--keys))
		(= key-quiz--round key-quiz-game-length))
	(throw 'end nil))
      (let* ((results (funcall ask-fn))
	     (score (car results))
	     (correct-answer (cdr results)))
	(newline)
	(if correct-answer
	    (progn
	      (insert (propertize (if (< 0 score) "Almost correct!" "Wrong!")
				  'font-lock-face
				  (if (< 0 score)
				      'key-quiz-partial
				    'key-quiz-wrong)))
	      (newline)
	      (insert (format "Correct answer was: %s"
			      (propertize correct-answer
					  'font-lock-face 'key-quiz-answer))))
	  (insert (propertize "Correct!"
			      'font-lock-face 'key-quiz-correct)))
	(setq key-quiz--score (max 0 (+ key-quiz--score score))
	      key-quiz--round (1+ key-quiz--round)))
      (key-quiz--insert-separator)
      (newline))))

(defun key-quiz--run (ask-fn)
  "Run the game.
Ask the player questions using ASK-FN, which should be a function
returning (SCORE . CORRECT-ANSWER)."
  (let (exit-code)
    (setq exit-code (key-quiz--game-loop ask-fn))
    (newline 2)
    (if (eq exit-code 'pause)
	(progn
	  (insert (propertize "Game paused." 'font-lock-face 'bold))
	  (newline)
	  (insert "Press 'c' to resume the game, 'r' to restart it.")
	  (message nil)) ; Clear minibuffer
      (unless exit-code
	;; If game loop exited normally, update high scores.
	(gamegrid-add-score key-quiz--score-file key-quiz--score))
      (insert (propertize (format "Game ended. Score: %s" key-quiz--score)
			  'font-lock-face 'bold))
      (newline)
      (insert "Press 'r' to start a new game, 'q' to exit."))))

(defun key-quiz--resume ()
  "Resume a paused game."
  (interactive)
  (unless key-quiz--last-state
    (error "Can't resume game: no current game"))
  (let ((inhibit-read-only t))
    (delete-region key-quiz--prompt-pos (point-max))
    (setq key-quiz--prompt-pos nil)
    (key-quiz--run (if key-quiz--game-reverse
		       'key-quiz--ask-reverse
		     'key-quiz--ask))))

(defun key-quiz--restart ()
  "Restart the current game."
  (interactive)
  (setq key-quiz--keys (or (copy-sequence key-quiz--custom-keys)
			   (key-quiz--get-keys))
	key-quiz--score 0
	key-quiz--round 0
	key-quiz--last-state nil
	key-quiz--prompt-pos nil)
  ;; Bind all keys not currently bound to a command to `ignore'. Use a
  ;; copy of key-quiz-mode-map so that we can freely modify it. We do
  ;; this to allow playing with keys not bound to anything.
  (use-local-map (copy-keymap key-quiz-mode-map))
  (dolist (key-command key-quiz--keys)
    (message "%s" key-command)
    (let ((key (car key-command)))
      (when (integerp (lookup-key (current-local-map) (kbd key)))
	(local-set-key (kbd key) 'ignore))))
  ;; Prepare buffer and start the game.
  (let ((inhibit-read-only t))
    (erase-buffer)
    (insert (format "%s keys/commands loaded." (length key-quiz--keys)))
    (newline 2)
    (key-quiz--run (if key-quiz--game-reverse
		       'key-quiz--ask-reverse
		     'key-quiz--ask))))

(defun key-quiz--quit ()
  "Ask the player if they want to quit the game and kill the buffer."
  (interactive)
  (when (yes-or-no-p "Exit game and kill buffer? ")
    (kill-this-buffer)))

;;;###autoload
(defun key-quiz (&optional reverse keys)
  "Play a game of Key Quiz.

Key Quiz is a game where the player must type in key sequences
corresponding to different Emacs commands, chosen at random.

The game includes a variant, called 'reverse mode', where the player
is given a key sequence and then must answer with the corresponding
command.  This mode is activated when called interactively with a
prefix argument, or when REVERSE is non-nil.

To KEYS argument can be used to specify a custom key-command list.
The value of the argument must be an alist with each item having the
form (KEY . COMMAND), where KEY should be a string in the format
returned by commands such as `C-h k' (`describe-key'), and COMMAND
should be a string representing the command bound to that key.  It is
not necessary for the commands to exist, or for the keys to be
actually bound to those commands.  If KEYS is omitted or nil, a
key-command list will be generated from the output of running
`describe-buffer-bindings' on a new buffer, set to mode
`key-quiz-use-mode'.

Instructions:
- Answer the questions as they are prompted.
- Points are awarded for correct (or partially correct) answers.
- Points are substracted for incorrect answers.
  The minimum possible score is 0.
- By default, 20 questions are asked per game.
- Use 'p RET' to pause the game and 'c' to resume it.
- Use \\[keyboard-quit] to cancel the question prompt.  Then, use 'r' to start a
  new game or 'q' to kill the buffer."
  (interactive "P")
  (let* ((buffer (get-buffer-create "*Key Quiz*")))
    (with-current-buffer buffer
      (unless (derived-mode-p 'key-quiz-mode)
	(key-quiz-mode))
      ;; These two variables shouldn't be modified when restarting the
      ;; game.
      (setq key-quiz--game-reverse reverse
	    key-quiz--custom-keys keys)
      (switch-to-buffer buffer)
      (key-quiz--restart))))

(provide 'key-quiz)
;;; key-quiz.el ends here
