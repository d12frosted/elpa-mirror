;;; org-d20.el --- minor mode for d20 tabletop roleplaying games -*- lexical-binding: t; -*-

;; Copyright (C) 2017-2019  Sean Whitton

;; Author: Sean Whitton <spwhitton@spwhitton.name>
;; URL: https://spwhitton.name/tech/code/org-d20/
;; Package-Version: 20210212.139
;; Package-Commit: e6149dcfbb6302d10109dd792fd0ffae7bfe2595
;; Version: 0.5
;; Package-Requires: ((s "1.11.0") (seq "2.19") (dash "2.12.0") (emacs "24"))
;; Keywords: outlines games

;; This file is NOT part of GNU Emacs.

;;; License:

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; A minor mode intended for use in an Org-mode file in which you are
;;; keeping your GM notes for a tabletop roleplaying game that uses a
;;; d20.

;;; Example file footer:
;;;
;;;     # Local Variables:
;;;     # eval: (org-d20-mode 1)
;;;     # org-d20-party: (("Zahrat" . 2) ("Ennon" . 4) ("Artemis" . 5))
;;;     # End:
;;;
;;; Alternatively, example first line of file:
;;;
;;;     # -*- mode: org; mode: org-d20; org-d20-party: (("Zahrat" . 0) ("Anca" . 1)) -*-

;;; Code:

(require 's)
(require 'seq)
(require 'dash)
(require 'cl-lib)
(require 'subr-x)
(require 'org-table)

(defgroup org-d20 nil
  "Customisation of `org-d20-mode'."
  :group 'org)

(defcustom org-d20-party nil
  "Party initiative modifiers.

A list of cons cells, where the car of each cell is a character's
name, and the cdr of each cell is that character's initiative
modifier as an integer."
  :type '(alist :key-type string :value-type integer)
  :group 'org-d20)

(defcustom org-d20-dice-sound nil
  "Path to a sound file that `play-sound-file' can play."
  :type 'string
  :group 'org-d20)

(defcustom org-d20-letter-monsters nil
  "Non-nil means individuate up to 26 monsters/NPCs with letters.

Rather than with digits."
  :type 'boolean
  :group 'org-d20)

(defcustom org-d20-continue-monster-numbering nil
  "Non-nil means continue the numbering/lettering of monsters between types.

Rather than starting again for each type."
  :type 'boolean
  :group 'org-d20)

(defcustom org-d20-display-rolls-buffer nil
  "Non-nil means split the window and display history of dice rolls."
  :type 'boolean
  :group 'org-d20)

(defvar org-d20-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c , i") #'org-d20-initiative-dwim)
    (define-key map (kbd "C-c , a") #'org-d20-initiative-add)
    (define-key map (kbd "C-c , d") #'org-d20-damage)
    (define-key map (kbd "C-c , r") #'org-d20-roll)
    (define-key map (kbd "<f10>") #'org-d20-roll-at-point)
    (define-key map (kbd "<f11>") #'org-d20-roll-last)
    (define-key map (kbd "<f12>") #'org-d20-d20)
    (define-key map (kbd "S-<f12>") #'org-d20-d%)
    map)
  "Keymap for function `org-d20-mode'.")

(defvar org-d20-roll--last)

;;;###autoload
(define-minor-mode org-d20-mode
  "Bind convenience functions for running a d20-like game in an
Org-mode document."
  :lighter " d20")


;;; Dice rolling

;; TODO: Also support '2d20kl1' to drop all but the lowest roll'
;;       (spw 2020-04-16)

(defun org-d20--roll (exp)
  "Evaluate dice roll expression EXP.

Returns a cons cell, whose car is a string expressing the results
on each dice rolled, and whose cdr is the final result.

Accepts roll20's extension for rolling multiple dice and keeping
the best N of them, e.g., 4d6k3."
  (let ((exps (seq-map (lambda (s) (s-chop-prefix "+" s))
                       (s-slice-at "[+-]" exp))))
    (seq-reduce #'org-d20--roll-inner exps '("" . 0))))

(defun org-d20--roll-inner (accum exp)
  (-let* (((rolls . total) accum)
          (sign (if (s-prefix-p "-" exp) -1 1))
          (ours (let ((chopped (s-chop-prefix "-" exp)))
                  (if (string= (substring chopped 0 1) "d")
                      (concat "1" chopped) chopped)))
          (split (seq-map #'string-to-number (s-split "[dk]" ours)))
          (times (seq-elt split 0))
          (sides (when (> (seq-length split) 1)
                   (seq-elt split 1)))
          (keep (when (> (seq-length split) 2)
                  (seq-elt split 2)))
          (new-rolls '()))
    (if (not sides)
        (let ((rolls*
               (org-d20--rolls-concat sign rolls (int-to-string times))))
          (cons rolls* (+ total (* sign times))))
      (cl-loop repeat times
               do (let ((new-roll (1+ (random sides))))
                    (push new-roll new-rolls)))
      (when keep
        ;; TODO: This should drop the items without reordering the
        ;;       list (spw 2019-01-05)
        (setq new-rolls (seq-drop (sort new-rolls #'<) (- times keep))))
      (dolist (new-roll new-rolls)
        (setq rolls
              (org-d20--rolls-concat sign rolls
                                     (org-d20--rolls-bracket sides new-roll)))
        (setq total (+ total (* sign new-roll))))
      (cons rolls total))))

;;;###autoload
(defun org-d20-d% ()
  "Roll a percentile dice."
  (interactive)
  (org-d20-roll "1d100"))

;;;###autoload
(defun org-d20-roll-at-point ()
  "Roll the dice expression at point and display result in minibuffer."
  (interactive)
  (let ((exp (thing-at-point 'sexp t)))
    (org-d20-roll exp)))

;;;###autoload
(defun org-d20-roll (exp)
  "Prompt, evaluate and display dice roll expression EXP.

Accepts roll20's extension for rolling multiple dice and keeping
the best N of them, e.g., 4d6k3."
  (interactive "sRoll: ")
  (setq org-d20-roll--last exp)
  (-let* (((rolls . result) (org-d20--roll exp))
          (result* (int-to-string result)))
    ;; If `rolls' contains no spaces then we just rolled a single
    ;; dice, so don't show the intermediate calculation
    (if (s-contains? " " rolls)
        ;; If the frame is not wide enough to show the full result,
        ;; strip out the spaces in the hope that it will fit
        (let ((rolls-display
               (if (>
                    (+ (length exp) 3 (length rolls) 3 (length result*))
                    (frame-width))
                   (s-replace " " "" rolls)
                 rolls)))
          (org-d20--record-roll "%s = %s = %s" exp rolls-display result*))
      (org-d20--record-roll "%s = %s" exp (int-to-string result))))
  (when org-d20-dice-sound
    (play-sound-file org-d20-dice-sound)))

;;;###autoload
(defun org-d20-roll-last ()
  "Roll the last user dice roll expression again."
  (interactive)
  (if (boundp 'org-d20-roll--last)
      (org-d20-roll org-d20-roll--last)
    (call-interactively #'org-d20-roll)))

;;;###autoload
(defun org-d20-d20 ()
  "Roll two d20, showing result with advantage and disadvantage, and neither."
  (interactive)
  (let* ((fst (cdr (org-d20--roll "1d20")))
         (snd (cdr (org-d20--roll "1d20")))
	 (bls (cdr (org-d20--roll "1d4")))
         (fst* (int-to-string fst))
         (snd* (int-to-string snd))
	 (bls* (int-to-string bls))
         (adv (if (>= fst snd)
                  (concat (propertize fst* 'face 'bold) "  " snd*)
                (concat fst* "  " (propertize snd* 'face 'bold))))
         (disadv (if (<= fst snd)
                     (concat (propertize fst* 'face 'bold) "  " snd*)
                   (concat fst* "  " (propertize snd* 'face 'bold)))))
    (org-d20--record-roll
     "No adv./disadv.:  %s%sAdv.:  %s%sDisadv.:  %s%sBless:  %s"
     fst*
     (make-string (- 4 (length fst*)) ?\ )
     adv
     (make-string (- 8 (length adv)) ?\ )
     disadv
     (make-string (- 10 (length disadv)) ?\ )
     bls*))
  (when org-d20-dice-sound
    (play-sound-file org-d20-dice-sound)))


;;; Combat tracking

(defun org-d20-initiative ()
  "Generate an Org-mode table with initiative order and monster/NPC HP."
  (interactive "*")
  (let ((rows))
    (let (name-input init-input hd-input num-input (monster 1))
      (cl-loop
       do (setq name-input (read-string "Monster/NPC name (blank when done): "))
       (when (> (length name-input) 0)
         (setq init-input (read-string (concat name-input "'s init modifier: "))
               hd-input (read-string (concat name-input "'s hit points: "))
               num-input
               (cdr (org-d20--roll
                     (read-string (concat "How many " name-input "? ")))))
         ;; In 5e, all monsters of the same kind have the same
         ;; initiative
         (let ((init (int-to-string
                      (org-d20--d20-plus (string-to-number init-input))))
               (monsters-left num-input))
           (while (>= monsters-left 1)
             (let ((hp (int-to-string (cdr (org-d20--roll hd-input)))))
               (push (list
                      "" (concat name-input
                                 " "
                                 (org-d20--monster-number monster))
                      (org-d20--num-to-term init-input) init hp "0")
                     rows))
             (setq monsters-left (1- monsters-left)
                   monster (1+ monster)))))
       (unless org-d20-continue-monster-numbering (setq monster 1))
       while (-all? (lambda (x) (> (length x) 0))
                    (list name-input init-input hd-input))))
    (dolist (pc org-d20-party)
      (let ((init (read-string (concat (car pc) "'s initiative roll: "))))
        (push (list "" (car pc) (org-d20--num-to-term (cdr pc)) init "-" "-")
              rows)))
    ;; We prepended each new item to the list, so reverse before
    ;; printing.  This ensures that the numbering/lettering of
    ;; monsters on the same initiative count is ascending
    (setq rows (seq-reverse rows))
    (insert
     "Round of combat: 1\n|Turn|Creature|Mod|Init|HP|Damage|Status|\n|-\n")
    (dolist (row rows)
      (dolist (cell row)
        (insert "|" cell))
      (insert "|\n"))
    (delete-char -1)
    (org-table-goto-column 4)
    (org-table-sort-lines nil ?N)
    (org-table-goto-line 2)
    (org-table-goto-column 1)
    (insert ">>>>")                     ; four chars in 'Turn'
    (org-table-align)))

(defun org-d20-initiative-advance ()
  "Advance the turn tracker in an initiative table."
  (interactive "*")
  (when (org-at-table-p)
    (cl-loop
     do (let* ((back (search-backward ">>>>" (org-table-begin) t))
               (forward (search-forward ">>>>" (org-table-end) t))
               (cur (if back back forward)))
          (goto-char cur)
          (skip-chars-backward ">")
          (delete-char 4)
          (if (save-excursion
                (org-table-goto-line (1+ (org-table-current-line))))
              (progn
                (forward-line 1)
                (org-table-next-field)
                (insert ">>>>"))
            (save-excursion
              (search-backward "Round of combat:")
              (search-forward-regexp "[0-9]+")
              (skip-chars-backward "0-9")
              (replace-match
               (int-to-string (1+ (string-to-number (match-string 0))))))
            (org-table-goto-line 2)
            (insert ">>>>")))
     while (save-excursion
             (org-table-goto-column 2)
             (looking-at "~"))))
  (org-table-align))

(defun org-d20-damage (dmg)
  "Apply DMG poitns of damage to the monster/NPC in the table row at point."
  (interactive "*nDamage dealt: ")
  (when (org-at-table-p)
    (org-table-goto-column 6)
    (skip-chars-forward " ")
    (when (looking-at "[0-9]+")
      (let ((total-damage (+ dmg (string-to-number (match-string 0)))))
        (replace-match (int-to-string total-damage))
        (save-excursion
          (org-table-goto-column 5)
          (skip-chars-forward " ")
          (when (looking-at "[0-9]+")
            (let ((max-hp (string-to-number (match-string 0))))
              (if (>= total-damage max-hp)
                  (progn
                    (org-table-goto-column 2)
                    (insert "~")
                    (org-d20--org-table-end-of-current-cell-content)
                    (insert "~"))
                (when (>= total-damage (/ max-hp 2))
                  (org-table-goto-column 7)
                  (org-d20--org-table-end-of-current-cell-content)
                  (unless (looking-back "bloodied" nil)
                    (unless (looking-back "|" nil)
                      (insert "; "))
                    (insert "bloodied")))))))))
    (org-table-align)))

(defun org-d20-initiative-dwim ()
  "Start a new combat or advance the turn tracker, based on point."
  (interactive "*")
  (if (org-at-table-p)
      (org-d20-initiative-advance)
    (org-d20-initiative)))

(defun org-d20-initiative-add ()
  "Add a monster to an existing combat."
  (interactive "*")
  (if (org-at-table-p)
      (let* ((name-input (read-string "Monster/NPC name: "))
             (init-input (read-string (concat name-input "'s init modifier: ")))
             (hd-input (read-string (concat name-input "'s hit points: ")))
             (num-input
              (cdr (org-d20--roll
                    (read-string (concat "How many " name-input "? ")))))
             (monster 1))
        ;; First, if we need to, try to count the number of monsters.
        ;; We can only use a crude heuristic here because we don't
        ;; know what kind of things the user might have added to the
        ;; table
        (when org-d20-continue-monster-numbering
          (save-excursion
            (org-table-goto-line 1)
            (while (org-table-goto-line (1+ (org-table-current-line)))
              (org-table-goto-column 2)
              (when (looking-at "[^|]+ \\([A-Z]\\|[0-9]+\\)~? *|")
                (setq monster (1+ monster))))))
        (save-excursion
          ;; Ensure we're not on header row (following won't go past end
          ;; of table)
          (org-table-goto-line (1+ (org-table-current-line)))
          (org-table-goto-line (1+ (org-table-current-line)))
          (let ((init (int-to-string
                       (org-d20--d20-plus (string-to-number init-input))))
                (monsters-left num-input))
            (while (>= monsters-left 1)
              ;; Open a new row and then immediately move it downwards
              ;; to ensure that the monsters on the same initiative
              ;; count are numbered/lettered in ascending order
              (org-table-insert-row)
              (org-table-move-row)
              (org-table-next-field)
              (insert name-input)
              (insert " ")
              (insert (org-d20--monster-number monster))
              (org-table-next-field)
              (insert (org-d20--num-to-term init-input))
              (org-table-next-field)
              (insert init)
              (org-table-next-field)
              (insert (int-to-string (cdr (org-d20--roll hd-input))))
              (org-table-next-field)
              (insert "0")
              (setq monsters-left (1- monsters-left)
                    monster (1+ monster))))
          (org-table-goto-column 4)
          (org-table-sort-lines nil ?N)
          (org-table-align)))
    (org-d20-initiative)))


;;; helper functions

;; Convert a signed integer to a string term
(defun org-d20--num-to-term (n)
  (let ((k (if (stringp n) (string-to-number n) n)))
    (if (>= k 0)
        (concat "+" (int-to-string k))
      (int-to-string k))))

;; Return the number or letter with which a monster name should be suffixed
(defun org-d20--monster-number (n)
  (if (and org-d20-letter-monsters (>= 26 n))
      (nth (1- n) '("A" "B" "C" "D" "E" "F" "G" "H" "I" "J" "K" "L" "M"
		    "N" "O" "P" "Q" "R" "S" "T" "U" "V" "W" "X" "Y" "Z"))
    (int-to-string n)))

;; Concat b onto a as a signed term, where a is possibly empty
(defun org-d20--rolls-concat (sign a b)
  (let (strings)
    (if (or (null a) (string= "" a))
	(unless (>= sign 0)
	  (push " - " strings))
      (push a strings)
      (push (if (>= sign 0)
		" + "
	      " - ")
	    strings))
    (push b strings)
    (apply #'concat (nreverse strings))))

;; Bracket a number so it looks a bit like a dice roll result
(defun org-d20--rolls-bracket (sides roll)
  (let ((brackets (or (assoc sides '((4 "‹" "›")
				     (6 "|" "|")
				     (8 "/" "/")
				     (10 "{" "}")
				     (12 "⟨" "⟩")
				     (20 "(" ")")
				     (100 "«" "»")))
		      '(nil "[" "]"))))
    (concat (cadr brackets) (int-to-string roll) (caddr brackets))))

(defun org-d20--org-table-end-of-current-cell-content ()
  "Move point to the end of the content of the current Org table cell."
  (search-forward "|" (save-excursion (end-of-line) (point)))
  (forward-char -2)
  (skip-chars-backward " "))

;; Roll a d20, adding or subtracting a modifier
(defun org-d20--d20-plus (&optional mod)
  (+ 1 mod (random 20)))

;; Record and display a new dice roll result
(defun org-d20--record-roll (&rest args)
  (let ((roll (apply #'format args)))
    (with-current-buffer (get-buffer-create "*Dice Trail*")
      (setq-local require-final-newline nil)
      (goto-char (point-max))
      (unless (bolp)
	(insert "\n"))
      (insert "  " roll))
    (cl-flet ((scroll (window)
		(with-selected-window window
		  (goto-char (point-max))
		  (beginning-of-line)
		  (recenter -1)
		  ;; without the following line, the dice roll doesn't show up
		  ;; until `play-sound-file' has finished
		  (redisplay)
		  ;; and without this line, the split window appears selected
		  ;; even when it isn't
		  (redraw-frame))))
      (if-let ((window (get-buffer-window "*Dice Trail*")))
	  (when (window-parameter window 'org-d20--dice-trail-split)
	    (scroll window))
	(if (and org-d20-mode org-d20-display-rolls-buffer)
	    (let ((window (split-window nil -8 'below)))
	      (set-window-buffer window "*Dice Trail*")
	      (set-window-parameter window 'org-d20--dice-trail-split t)
	      (scroll window))
	  (message roll))))))

(provide 'org-d20)
;;; org-d20.el ends here
