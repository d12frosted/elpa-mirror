;;; decide.el --- rolling dice and other random things
;; Copyright 2016, 2017, 2019 Pelle Nilsson et al
;;
;; Author: Pelle Nilsson <perni@lysator.liu.se>
;; Version: 0.7
;; Package-Version: 20190201.2137
;; Package-Commit: 4bfcc826dd5b1c30caec455d8baa4f363159eac6
;;
;; This program is free software: you can redistribute it and/or modify
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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Use to make random decisions. Roll various types of dice, generate
;; random numbers from ranges, or generate random text from
;; tables.
;;
;; Enable decide-mode minor-mode. Pressing ? ? will insert a YES
;; or NO (possibly with a + or - modifier to be interpreted
;; any way you wish).
;;
;; If the answer is unlikely to be yes, press ? -
;; a more unlikely (difficult) query that has only a 33 % chance of being
;; yes. For a liklier/easier test press ? + (67 % chance).
;;
;; To roll generic dice, use the function decide-roll-dice. It will
;; ask for what roll to make, something like 2d6 or 3d10+2 or 2d12-1.
;; The default if nothing is input, or nothing that can be parsed
;; properly as a dice specification, 1d6 is rolled.
;; M-p and M-n can be used to navigate history to re-roll.
;; Rolling dice is bound to ? d when decide-mode is active.
;; Some common and less common die-rolls have their own key-bindings
;; enabled per default in decide-mode:
;;
;; ? 3 -> 1d3
;; ? 4 -> 1d4
;; ? 5 -> 1d5
;; ? 6 -> 1d6
;; ? 7 -> 1d7
;; ? 8 -> 1d8
;; ? 9 -> 1d9
;; ? 1 0 -> 1d10
;; ? 1 2 -> 1d12
;; ? 2 0 -> 1d20
;; ? % -> 1d100
;; ? D -> 2d6
;;
;; Custom dice can be defined in the decide-custom-dice alist. By default it
;; contains configuration for dA (average-dice, d6 numbered 2, 3, 3, 4, 4, 5)
;; and dF (Fudge/FATE dice, d6 labeled +, +, 0, 0, -, -). Custom dice names
;; are not case sensitive (avoid having dice with the same name only differing
;; in case). Each custom dice side has a string
;; label and an optional value that is used (if it exists) to calculate the sum
;; of rolling multiple dice of that type. There are some pre-defined
;; key-bindings in decide-mode for the included custom dice:
;;
;; ? f -> 4dF
;; ? a -> 1dA
;; ? A -> 2dA
;;
;; To pick a random number in any range press ? r (decide-random-range),
;; then input range to get number from, in one of the following formats:
;; 3-17
;; 3--17
;; 3---17
;; (even more dashes are allowed)
;; 3<<17
;; 3<<<17
;; 3>>17
;; 3>>>17
;; All ranges are inclusive (ie the two given numbers may be choosen).
;; The start of a range must be lower than the end of the range.
;; The end of a range can not be a negative number.
;; When having more than one dash between numbers, that means you will get
;; an average of that many random draws, meaning the result is more likely
;; to be close to the middle of the range. Adding more dashes makes it
;; increasingly unlikely to get results close to the extremes of the range.
;; Using << (or <<< etc) will instead result in the lowest of multiple
;; draws, tending towards the lower end of the range,
;; and the opposite is true when using >> (or >>> etc).
;;
;; To decide from a given list of possible choices press
;; ? c (decide-random-choice)
;; and input a comma-separated list of things to choose from.
;; There are also some pre-defined lists of choices that can be
;; accessed with the following shortcuts (and it should be obvious from
;; a quick look in decide.el how to define your own for frequently used lists!):
;;
;; ? w 4 -> decide-whereto-compass-4 (N,S,W,E)
;; ? w 6 -> decide-whereto-compass-6 (N,S,W,E,U,D)
;; ? w 8 -> decide-whereto-compass-8 (N,S,E,W,NE,NW,SE,SW)
;; ? w 1 0 -> decide-whereto-compass-10 (N,S,E,W,NE,NW,SE,SW,U,D)
;; ? W 2 -> decide-whereto-relative-2 (left,right)
;; ? W 3 -> decide-whereto-relative-3 (forward,left,right)
;; ? W 4 -> decide-whereto-relative-4 (forward,left,right,back)
;; ? W 6 -> decide-whereto-relative-6 (forward,left,right,back,up,down)
;;
;; It is also possible to pick random combinations of words taken from the
;; variable decide-tables using ? t (decide-from-table). decide-table is
;; an alist that gives lists of possible values for each 'table'. If one of
;; the strings is the name of another table in the alist a random from that
;; list will be substituted. A word that is a valid dice-spec
;; is rolled with the result inserted. A word that is a valid range (as for
;; decide-random-range) will result in a random value from that range
;; being inserted. If a word matches the name of a
;; table that table will be used to insert something at that position.
;; A tilde (~) can be used anywhere in a table string to insert nothing, to
;; prevent the parser from recognizing some word, or to glue together words
;; or dice-specifiers without a space to separate them.
;; A possible expansion for a table name can have a weight added to make
;; it more likely to be choosen like ("dragon" . 3) (making it three times
;; as likely to be choosen as an expansion that has no weight given).
;; The default-value for decide-tables contains some examples to hopefully
;; make all this a bit less confusing.
;;
;; Example of globally binding a keyboard combination to roll dice:
;; (global-set-key (kbd "C-c r") 'decide-roll-dice)
;;
;; Results of decisions or dice will be input in current buffer at point,
;; or in the minibuffer if current buffer is read-only.
;;
;; To just type a question-mark (?) press ? immediately followed by
;; space or enter. (Or quote the ? key normally, ie C-q ?).
;;
;;; Code:

(defvar decide-mode-map (make-sparse-keymap)
  "Keymap for decide minor mode.")

;;;###autoload
(define-minor-mode decide-mode
  "Minor mode for making  decisions.
\\<decide-mode-map"
  :lighter " Decide")

(defvar decide-tables
  '(("card" . ("card-rank card-suit"))
    ("card-suit" . ("Spades" "Hearts" "Diamonds" "Clubs"))
    ("card-rank" . ("Ace" "2" "3" "4" "5" "6" "7" "8" "9" "10"
                    "Jack" "Queen" "King"))

    ;; The following tables are all prefixed example- because
    ;; they are probably only useful to demonstrate how to
    ;; specify decide-tables.
    ("example-monster" . ("1d6+1 orcs"
                          "3d6+1 kobolds"
                          "2<<<20 goblins"
                          "2>>5 small goblins"
                          "level 1--10 hero"
                          "example-dragon"))
    ("example-dragon" . (("dragon" . 3)
                         "example-dragon-prefix~dragon"
                         "2-3 example-dragon-prefix~dragons"
                         "example-dragon-prefix~dragon"
                         "2d4~-headed dragon"
                         "1d3+1 dragons"))
    ("example-dragon-prefix" . ("" "ice " "undead " "epic " "old "
                                "semi-" "cute " "ugly ")))
  "Alist specifying tables used for the decide-from-table function.")

(defvar decide-custom-dice
  '(("F" . ((0 "0")
            (-1 "-")
            (1 "+")))
    ("A" . ((2 "2")
            (3 "3")
            (3 "3")
            (4 "4")
            (4 "4")
            (5 "5"))))
  "Alist specifying custom dice for decide-roll-dice. Keys are
  the names used when rolling dice. They are case insensitive, so
  avoid using names that only differ in case (e.g. Hi and HI).")
(setq decide-for-me-dice
      (let ((ya "YES+")
            (y "YES")
            (yb "YES-")
            (nb "NO-")
            (n "NO")
            (na "NO+")
            )
        (list (cons :likely(list ya ya y yb nb n))
              (cons :normal (list ya y yb nb n na))
              (cons :unlikely (list y yb nb n na na)
                    ))))

(defun decide-for-me-get (difficulty)
  "Get random decision for difficulty :likely, :normal, or :unlikely."
  (let ((die (cdr (assoc difficulty decide-for-me-dice))))
    (nth (random (length die)) die)))

(defun decide-for-me-result (name result)
  (concat (if name
            (concat "[" name "] ")
            "")
          "-> "
          result
          "\n"))

(defun decide-insert (&rest ARGS)
  (if buffer-read-only
      (minibuffer-message (apply 'concat ARGS))
    (apply 'insert ARGS)))

(defun decide-for-me-likely ()
  (interactive)
  (decide-insert
   "? "
   (decide-for-me-result
    "likely"
    (decide-for-me-get :likely))))

(defun decide-for-me-normal ()
  (interactive)
  (decide-insert
   "? "
   (decide-for-me-result
    nil
    (decide-for-me-get :normal))))

(defun decide-for-me-unlikely ()
  (interactive)
  (decide-insert
   "? "
   (decide-for-me-result
    "unlikely"
    (decide-for-me-get :unlikely))))

(defun decide-range-average (&rest results)
  (floor (+ 0.5 (/ (apply '+ (mapcar 'float results))
                   (length results)))))

(defun decide-parse-range (s)
  (cond
   ((string-match "^\\(-?[1-9][0-9]*\\)\\(-+\\)\\([1-9][0-9]*\\)$" s)
    (list (string-to-number (match-string 1 s))
          (string-to-number (match-string 3 s))
          'decide-range-average
          (length (match-string 2 s))))
   ((string-match "^\\(-?[1-9][0-9]*\\)\\(<<+\\)\\([1-9][0-9]*\\)$" s)
    (list (string-to-number (match-string 1 s))
          (string-to-number (match-string 3 s))
          'min
          (length (match-string 2 s))))
   ((string-match "^\\(-?[1-9][0-9]*\\)\\(>>+\\)\\([1-9][0-9]*\\)$" s)
    (list (string-to-number (match-string 1 s))
          (string-to-number (match-string 3 s))
          'max
          (length (match-string 2 s))))
   (t nil)))

(defun decide-describe-range (from to fn draws)
  (format "[%d-%d%s] -> "
          from
          to
          (if (> draws 1)
              (format " (%s of %d)"
                      (cond
                       ((eq fn 'decide-range-average) "average")
                       ((eq fn 'min) "lowest")
                       ((eq fn 'max) "highest"))
                      draws)
            "")))

(defun decide-from-range-draw (from-to-pair)
  (let ((from (car from-to-pair))
        (to (cdr from-to-pair)))
    (+ from (random (- to from -1)))))

(defun decide-from-range-get (from to fn draws)
  (apply fn
         (mapcar 'decide-from-range-draw
              (make-list draws (cons from to)))))

(defun decide-from-range (from to fn draws)
  (format "%d\n" (decide-from-range-get from to fn draws)))

(defun decide-random-range (range-string)
  (interactive "sRange: ")
  (let ((range-spec (decide-parse-range range-string)))
    (decide-insert
     (apply 'decide-describe-range range-spec)
     (apply 'decide-from-range range-spec))))

(defun decide-random-choice (choices-string)
  (interactive "sRandom choice from (comma-separated choices): ")
  (let ((choices (split-string choices-string ",")))
    (decide-insert
     (decide-for-me-result (format "(%s)" choices-string)
                           (nth (random (length choices)) choices)))))

(defun decide-choose-from-table-list-part (part)
  (let ((parts (split-string part " ")))
    (mapconcat 'identity
               (mapcar 'decide-choose-from-table parts) " ")))

(defun decide-choose-from-table-list (choice)
  (mapconcat 'identity
             (mapcar 'decide-choose-from-table-list-part
                  (split-string choice "~")) ""))

(defun decide-weight-for-choice (choice)
  (if (listp choice) (cdr choice) 1))

(defun decide-entry-for-choice (choice)
  (if (listp choice) (car choice) choice))

(defun decide-table-sum (choices)
  (seq-reduce
   (lambda (s v) (+ s (decide-weight-for-choice v)))
   choices 0))

;; (decide-table-sum '("a" "b" ("c" . 10) "d"))

(defun decide-choose-from-table-choices (choices)
  (let* ((max (decide-table-sum choices))
         (roll (decide-from-range-draw (cons 0 max)))
         (sum 0))
    (cl-loop for c in choices
             for e = (decide-entry-for-choice c)
             for w = (decide-weight-for-choice c)
             sum w into sum
             until (< roll sum)
             finally return e)))

(defun decide-choose-from-table (table-name)
  (let ((choices (cdr (assoc table-name decide-tables))))
    (if choices (decide-choose-from-table-list
                 (decide-choose-from-table-choices choices))
      (let ((table-name-as-dice-spec (decide-make-dice-spec table-name))
            (table-name-as-range-spec (decide-parse-range table-name)))
        (cond (table-name-as-dice-spec
               (format "%d" (decide-sum-dice-rolled
                             (decide-roll-dice-result
                              (nth 0 table-name-as-dice-spec)
                              (nth 1 table-name-as-dice-spec))
                             (nth 2 table-name-as-dice-spec))))
              (table-name-as-range-spec
               (format "%d" (apply 'decide-from-range-get
                                   table-name-as-range-spec)))
              (t table-name))))))


(defun decide-from-table (table-name)
  (interactive (list (completing-read "Table name: "
                                      decide-tables
                                      nil
                                      1)))
  (decide-insert
   (decide-for-me-result (format "<%s>" table-name)
                         (decide-choose-from-table table-name))))

(defun decide-whereto-compass-4 ()
  (interactive)
  (decide-random-choice "N,S,E,W"))

(defun decide-whereto-compass-6 ()
  (interactive)
  (decide-random-choice "N,S,E,W,U,D"))

(defun decide-whereto-compass-8 ()
  (interactive)
  (decide-random-choice "N,S,E,W,NE,NW,SE,SW"))

(defun decide-whereto-compass-10 ()
  (interactive)
  (decide-random-choice "N,S,E,W,NE,NW,SE,SW,U,D"))

(defun decide-whereto-relative-2 ()
  (interactive)
  (decide-random-choice "left,right"))

(defun decide-whereto-relative-3 ()
  (interactive)
  (decide-random-choice "forward,left,right"))

(defun decide-whereto-relative-4 ()
  (interactive)
  (decide-random-choice "forward,left,right,back"))

(defun decide-whereto-relative-6 ()
  (interactive)
  (decide-random-choice "forward,left,right,back,up,down"))

(defun decide-strings-to-numbers (numbers)
  (mapcar (lambda (s)
            (cond ((null s) 0)
                  ((string-match "[0-9]+" s) (string-to-number s))
                  ((equal "+" s) 0)
                  ((equal "-" s) 0)
                  (t s))) numbers))

(defun decide-roll-custom-die (sides)
  (nth (random (length sides)) sides))

(defun decide-roll-number-die (faces)
  (let ((res (+ 1 (random faces))))
    (list res (format "%d" res))))

(defun decide-roll-die (faces)
  (cond ((stringp faces)
         (let ((sides (cdr (assoc-string faces decide-custom-dice t))))
           (if sides
               (decide-roll-custom-die sides)
             '(0 "?"))))
        ((numberp faces)
         (decide-roll-number-die faces))))

(defun decide-roll-dice-result (nr faces)
  (if (= 0 nr)
      '()
    (cons (decide-roll-die faces)
          (decide-roll-dice-result (- nr 1) faces))))

(defun decide-describe-roll (rolled)
  (let ((first-described (format "%s" (cadr (car rolled)))))
    (if (= 1 (length rolled))
        first-described
      (format "%s %s"
              first-described
              (decide-describe-roll (cdr rolled))))))

(defun decide-sum-dice-rolled (rolled mod)
  (apply '+ (cons mod (mapcar 'car rolled))))

(defun decide-roll-dice-spec (nr faces mod)
  (let* ((rolled (decide-roll-dice-result nr faces))
         (rolled-description (decide-describe-roll rolled))
         (sum (decide-sum-dice-rolled rolled mod)))
    (if (= 0 mod)
        (if (> (length rolled) 1)
            (format "(%s) = %d" rolled-description sum)
          (format "= %d" sum))
      (format "(%s) %+d = %d" rolled-description mod sum))))

(defun decide-make-dice-spec (s)
  "eg \"1d6\" -> (1 6 0) or \"2d10+2\" -> (2 10 2) or \"4dF\" -> (4 \"f\" 0)"
  (when (string-match
         "^\\([1-9][0-9]*\\)d\\([0-9a-zA-Z]*\\)\\([+-][0-9]*\\)?"
         s)
    (decide-strings-to-numbers (list (match-string 1 s)
                                     (match-string 2 s)
                                     (match-string 3 s)))))

(defun decide-describe-dice-spec (spec)
  (let* ((mod (car (last spec)))
         (faces (nth 1 spec))
         (facesname (if (stringp faces) (upcase faces) (format "%d" faces))))
    (if (= mod 0)
        (format "%dd%s" (nth 0 spec) facesname)
      (format "%dd%s%+d" (nth 0 spec) facesname (nth 2 spec)))))

(defun decide-roll-dice (spec-string)
  "Roll some dice. Insert result in buffer, or in minibuffer if read-only."
  (interactive "sRoll: ")
  (let ((spec (decide-make-dice-spec spec-string)))
    (decide-roll-dice-insert (if spec spec '(1 6 0)))))

(defun decide-roll-dice-insert (spec)
  (decide-insert
   "["
   (decide-describe-dice-spec spec)
   "] -> "
   (apply 'decide-roll-dice-spec spec)
   "\n"))

(defun decide-roll-fate ()
  "Roll four Fate/Fudge dice."
  (interactive)
  (decide-roll-dice "4df"))

(defun decide-roll-1dA ()
  (interactive)
  (decide-roll-dice "1dA"))

(defun decide-roll-2dA ()
  (interactive)
  (decide-roll-dice "2dA"))

(defun decide-roll-1d6 ()
  (interactive)
  (decide-roll-dice "1d6"))

(defun decide-roll-2d6 ()
  (interactive)
  (decide-roll-dice "2d6"))

(defun decide-roll-1d3 ()
  (interactive)
  (decide-roll-dice "1d3"))

(defun decide-roll-1d4 ()
  (interactive)
  (decide-roll-dice "1d4"))

(defun decide-roll-1d5 ()
  (interactive)
  (decide-roll-dice "1d5"))

(defun decide-roll-1d7 ()
  (interactive)
  (decide-roll-dice "1d7"))

(defun decide-roll-1d8 ()
  (interactive)
  (decide-roll-dice "1d8"))

(defun decide-roll-1d9 ()
  (interactive)
  (decide-roll-dice "1d9"))

(defun decide-roll-1d10 ()
  (interactive)
  (decide-roll-dice "1d10"))

(defun decide-roll-1d12 ()
  (interactive)
  (decide-roll-dice "1d12"))

(defun decide-roll-1d20 ()
  (interactive)
  (decide-roll-dice "1d20"))

(defun decide-roll-1d100 ()
  (interactive)
  (decide-roll-dice "1d100"))

(defun decide-find-last-ws ()
  (save-excursion
    (let ((p (search-backward-regexp "[\s\n(]")))
      (if p (+ p 1) (point-min)))
    )
  )

(defun decide-get-from-last-ws ()
  (buffer-substring-no-properties (decide-find-last-ws) (point))
)

(defun decide-dwim-insert ()
  "Do what I mean with last word."
  (interactive)
  (let* ((s (decide-get-from-last-ws))
         (dice-spec (decide-make-dice-spec s))
         (range-spec (decide-parse-range s))
         )
    (cond (dice-spec (progn
                       (delete-backward-char (length s))
                       (decide-roll-dice-insert dice-spec)))
          (range-spec (progn
                        (delete-backward-char (length s))
                        (decide-random-range s)))
          (t (decide-for-me-normal)))))

(defun decide-question-return ()
  (interactive)
  (insert "?\n"))

(defun decide-question-space ()
  (interactive)
  (insert "? "))

(define-prefix-command 'decide-prefix-map)

(define-key decide-mode-map (kbd "?") 'decide-prefix-map)

(define-key decide-mode-map (kbd "? ?") 'decide-dwim-insert)
(define-key decide-mode-map (kbd "? +") 'decide-for-me-likely)
(define-key decide-mode-map (kbd "? -") 'decide-for-me-unlikely)

(define-key decide-mode-map (kbd "? d") 'decide-roll-dice)
(define-key decide-mode-map (kbd "? D") 'decide-roll-2d6)
(define-key decide-mode-map (kbd "? 3") 'decide-roll-1d3)
(define-key decide-mode-map (kbd "? 4") 'decide-roll-1d4)
(define-key decide-mode-map (kbd "? 5") 'decide-roll-1d5)
(define-key decide-mode-map (kbd "? 6") 'decide-roll-1d6)
(define-key decide-mode-map (kbd "? 7") 'decide-roll-1d7)
(define-key decide-mode-map (kbd "? 8") 'decide-roll-1d8)
(define-key decide-mode-map (kbd "? 9") 'decide-roll-1d9)
(define-key decide-mode-map (kbd "? 1 0") 'decide-roll-1d10)
(define-key decide-mode-map (kbd "? 1 2") 'decide-roll-1d12)
(define-key decide-mode-map (kbd "? 2 0") 'decide-roll-1d20)
(define-key decide-mode-map (kbd "? %") 'decide-roll-1d100)
(define-key decide-mode-map (kbd "? f") 'decide-roll-fate)
(define-key decide-mode-map (kbd "? a") 'decide-roll-1dA)
(define-key decide-mode-map (kbd "? A") 'decide-roll-2dA)

(define-key decide-mode-map (kbd "? r") 'decide-random-range)

(define-key decide-mode-map (kbd "? c") 'decide-random-choice)
(define-key decide-mode-map (kbd "? t") 'decide-from-table)
(define-key decide-mode-map (kbd "? w 4") 'decide-whereto-compass-4)
(define-key decide-mode-map (kbd "? w 6") 'decide-whereto-compass-6)
(define-key decide-mode-map (kbd "? w 8") 'decide-whereto-compass-8)
(define-key decide-mode-map (kbd "? w 1 0") 'decide-whereto-compass-10)
(define-key decide-mode-map (kbd "? W 2") 'decide-whereto-relative-2)
(define-key decide-mode-map (kbd "? W 3") 'decide-whereto-relative-3)
(define-key decide-mode-map (kbd "? W 4") 'decide-whereto-relative-4)
(define-key decide-mode-map (kbd "? W 6") 'decide-whereto-relative-6)

(define-key decide-mode-map (kbd "? RET") 'decide-question-return)
(define-key decide-mode-map (kbd "? SPC") 'decide-question-space)

(provide 'decide)
;;; decide.el ends here
