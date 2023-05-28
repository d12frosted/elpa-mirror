;;; blackjack.el --- The game of Blackjack -*- lexical-binding: t; -*-

;; Copyright (C) 2022, 2023 Greg Donald
;; SPDX-License-Identifier: GPL-3.0-only
;; Author: Greg Donald <gdonald@gmail.com>
;; Version: 1.0.3
;; Package-Version: 20230528.1152
;; Package-Commit: b58e0fab096314177a21275f64143199b628d429
;; Package-Requires: ((emacs "26.2"))
;; Keywords: card game games blackjack 21
;; URL: https://github.com/gdonald/blackjack-el

;;; Commentary:
;; This package lets you play Blackjack in Emacs.

;;; Code:

(require 'cl-lib)
(require 'eieio)

(defconst blackjack--buffer-name "* Blackjack *"
  "The buffer name.")

(defgroup blackjack nil
  "Customization group for Blackjack."
  :group 'games)

(defcustom blackjack-stand-key "s"
  "Key to press to stand on current hand."
  :type '(string) :group 'blackjack)

(defcustom blackjack-deal-double-key "d"
  "Key to press to deal or double a hand."
  :type '(string) :group 'blackjack)

(defcustom blackjack-bet-back-key "b"
  "Key to press to change bet or go back."
  :type '(string) :group 'blackjack)

(defcustom blackjack-quit-key "q"
  "Key to press to quit."
  :type '(string) :group 'blackjack)

(defcustom blackjack-options-key "o"
  "Key to press to view options menus."
  :type '(string) :group 'blackjack)

(defcustom blackjack-num-decks-no-insurance-key "n"
  "Key to press to decline insurance or change number of decks."
  :type '(string) :group 'blackjack)

(defcustom blackjack-deck-type-key "t"
  "Key to press to change deck type."
  :type '(string) :group 'blackjack)

(defcustom blackjack-face-type-key "f"
  "Key to press to change face type."
  :type '(string) :group 'blackjack)

(defcustom blackjack-hit-key "h"
  "Key to press to hit a hand."
  :type '(string) :group 'blackjack)

(defcustom blackjack-split-key "p"
  "Key to press to split a hand."
  :type '(string) :group 'blackjack)

(defcustom blackjack-deck-regular-key "1"
  "Key to press to switch to a regular deck."
  :type '(string) :group 'blackjack)

(defcustom blackjack-deck-aces-key "2"
  "Key to press to switch to a deck of aces."
  :type '(string) :group 'blackjack)

(defcustom blackjack-deck-jacks-key "3"
  "Key to press to switch to a deck of jacks."
  :type '(string) :group 'blackjack)

(defcustom blackjack-deck-aces-jacks-key "4"
  "Key to press to switch to a deck of aces and jacks."
  :type '(string) :group 'blackjack)

(defcustom blackjack-deck-sevens-key "5"
  "Key to press to switch to a deck of sevens."
  :type '(string) :group 'blackjack)

(defcustom blackjack-deck-eights-key "6"
  "Key to press to switch to a deck of eights."
  :type '(string) :group 'blackjack)

(defcustom blackjack-insurance-key "y"
  "Key to press to insure hand."
  :type '(string) :group 'blackjack)

(defcustom blackjack-face-type-regular-key "r"
  "Key to press to to choose regular face type."
  :type '(string) :group 'blackjack)

(defcustom blackjack-face-type-alternate-key "a"
  "Key to press to choose alternate face type."
  :type '(string) :group 'blackjack)

(defcustom blackjack-persist-file
  (file-name-concat user-emacs-directory "blackjack.txt")
  "File to persist blackjack game state to."
  :type '(file) :group 'blackjack)

(defcustom blackjack-currency "$"
  "Currency to display.

Can be a single-character currency symbol such as \"$\", \"€\" or \"£\", or a
3-character currency code as per ISO 4217."
  :type '(string)
  :group 'blackjack)

(defclass blackjack-card ()
  ((id :initarg :id :initform 0 :type integer)
   (value :initarg :value :initform 0 :type integer)
   (suit :initarg :suit :initform 0 :type integer)))

(defclass blackjack-hand ()
  ((cards :initarg :cards :initform '() :type list)
   (played :initarg :played :initform nil :type boolean)))

(defclass blackjack-player-hand (blackjack-hand)
  ((id :initarg :id :initform 0 :type integer)
   (bet :initarg :bet :initform 0 :type integer)
   (status :initarg :status :initform 'unknown :type symbol)
   (payed :initarg :payed :initform nil :type boolean)
   (stood :intiarg :stood :initform nil :type boolean)))

(defclass blackjack-dealer-hand (blackjack-hand)
  ((hide-down-card :initarg :hide-down-card :initform t :type boolean)))

(defclass blackjack-game ()
  ((id :initarg :id :initform 0 :type integer)
   (shoe :initarg :shoe :initform '() :type list)
   (dealer-hand :initarg :dealer-hand :initform nil :type atom)
   (player-hands :initarg :player-hands :initform '() :type list)
   (num-decks :initarg :num-decks :initform 1 :type integer)
   (deck-type :initarg :deck-type :initform 'regular :type symbol)
   (face-type :initarg :face-type :initform 'regular :type symbol)
   (money :initarg :money :initform 10000 :type integer)
   (current-bet :initarg :current-bet :initform 500 :type integer)
   (current-player-hand :initarg :current-player-hand :initform 0 :type integer)
   (current-menu :initarg :current-menu :initform 'game :type symbol)
   (faces-regular :initarg :faces :initform '[["A♠" "A♥" "A♣" "A♦"]
                                              ["2♠" "2♥" "2♣" "2♦"]
                                              ["3♠" "3♥" "3♣" "3♦"]
                                              ["4♠" "4♥" "4♣" "4♦"]
                                              ["5♠" "5♥" "5♣" "5♦"]
                                              ["6♠" "6♥" "6♣" "6♦"]
                                              ["7♠" "7♥" "7♣" "7♦"]
                                              ["8♠" "8♥" "8♣" "8♦"]
                                              ["9♠" "9♥" "9♣" "9♦"]
                                              ["T♠" "T♥" "T♣" "T♦"]
                                              ["J♠" "J♥" "J♣" "J♦"]
                                              ["Q♠" "Q♥" "Q♣" "Q♦"]
                                              ["K♠" "K♥" "K♣" "K♦"]
                                              ["??"]] :type array)
   (faces-alternate :initarg :faces2 :initform '[["🂡" "🂱" "🃁" "🃑"]
                                                 ["🂢" "🂲" "🃂" "🃒"]
                                                 ["🂣" "🂳" "🃃" "🃓"]
                                                 ["🂤" "🂴" "🃄" "🃔"]
                                                 ["🂥" "🂵" "🃅" "🃕"]
                                                 ["🂦" "🂶" "🃆" "🃖"]
                                                 ["🂧" "🂷" "🃇" "🃗"]
                                                 ["🂨" "🂸" "🃈" "🃘"]
                                                 ["🂩" "🂹" "🃉" "🃙"]
                                                 ["🂪" "🂺" "🃊" "🃚"]
                                                 ["🂫" "🂻" "🃋" "🃛"]
                                                 ["🂭" "🂽" "🃍" "🃝"]
                                                 ["🂮" "🂾" "🃎" "🃞"]
                                                 ["🂠"]] :type array)
   (shuffle-specs :initarg :shuffle-specs :initform '[80 81 82 84 86 89 92 95] :type array)
   (cards-per-deck :initarg :cards-per-deck :initform 52 :type integer)
   (min-bet :initarg :min-bet :initform 500 :type integer)
   (max-bet :initarg :max-bet :initform 100000000 :type integer)
   (max-player-hands :initarg :max-player-hands :initform 7 :type integer)
   (quitting :initarg :quitting :initform nil :type boolean)))

;; (cl-defmethod cl-print-object ((obj blackjack-card) stream)
;;   "Print OBJ to STREAM."
;;   (princ
;;    (format "#<%s id: %d value: %s suit: %s>"
;;            (eieio-class-name (eieio-object-class obj))
;;            (slot-value obj 'id)
;;            (slot-value obj 'value)
;;            (slot-value obj 'suit))
;;    stream))

;; (cl-defmethod cl-print-object ((obj blackjack-player-hand) stream)
;;   "Print OBJ to STREAM."
;;   (princ
;;    (format "#<%s id: %d cards: %s played: %s status: %s payed: %s stood: %s bet: %s>"
;;            (eieio-class-name (eieio-object-class obj))
;;            (slot-value obj 'id)
;;            (slot-value obj 'cards)
;;            (slot-value obj 'played)
;;            (slot-value obj 'status)
;;            (slot-value obj 'payed)
;;            (slot-value obj 'stood)
;;            (slot-value obj 'bet))
;;    stream))

;; (cl-defmethod cl-print-object ((obj blackjack-dealer-hand) stream)
;;   "Print OBJ to STREAM."
;;   (princ
;;    (format "#<%s cards: %s played: %s hide-down-card: %s>"
;;            (eieio-class-name (eieio-object-class obj))
;;            (slot-value obj 'cards)
;;            (slot-value obj 'played)
;;            (slot-value obj 'hide-down-card))
;;    stream))

(defun blackjack--deal-new-hand (game)
  "Deal new GAME hands."
  (interactive)
  (when (blackjack--valid-menu-action-p game 'game)
    (with-slots (current-bet player-hands current-player-hand current-menu) game
      (when (blackjack--need-to-shuffle-p game)
        (blackjack--shuffle game))
      (let (player-hand dealer-hand)
        (setf player-hands '())
        (setq player-hand (blackjack-player-hand :id (blackjack--next-id game) :bet current-bet))
        (setq dealer-hand (blackjack-dealer-hand))
        (dotimes (_x 2)
          (blackjack--deal-card game player-hand)
          (blackjack--deal-card game dealer-hand))
        (push player-hand player-hands)
        (setf current-player-hand 0)
        (setf (slot-value game 'dealer-hand) dealer-hand)
        (if (and
             (blackjack--dealer-upcard-is-ace-p dealer-hand)
             (not (blackjack--hand-is-blackjack-p (slot-value player-hand 'cards))))
            (progn
              (setf current-menu 'insurance)
              (blackjack--draw-hands game)
              (blackjack--ask-insurance-action game))
          (if (blackjack--player-hand-done-p game player-hand)
              (progn
                (setf (slot-value dealer-hand 'hide-down-card) nil)
                (blackjack--pay-hands game)
                (setf current-menu 'game)
                (blackjack--draw-hands game)
                (blackjack--ask-game-action game))
            (setf current-menu 'hand)
            (blackjack--draw-hands game)
            (blackjack--save game)
            (blackjack--ask-hand-action game)))))))

(defun blackjack--deal-card (game hand)
  "Deal a card into HAND from GAME shoe."
  (interactive)
  (with-slots (shoe) game
    (with-slots (cards) hand
      (cl-callf append cards `(,(pop shoe))))))

(defun blackjack--next-id (game)
  "Return next GAME object id."
  (cl-incf (slot-value game 'id)))

(defun blackjack--pay-hands (game)
  "Pay player GAME hands."
  (with-slots (dealer-hand player-hands) game
    (let ((dealer-hand-value (blackjack--dealer-hand-value dealer-hand 'soft))
          (dealer-busted (blackjack--dealer-hand-is-busted-p dealer-hand)))
      (dolist (player-hand player-hands)
        (blackjack--pay-player-hand game player-hand dealer-hand-value dealer-busted))
      (blackjack--normalize-current-bet game)
      (blackjack--save game))))

(defun blackjack--pay-player-hand (game player-hand dealer-hand-value dealer-hand-busted)
  "Pay GAME PLAYER-HAND based on DEALER-HAND-VALUE and DEALER-HAND-BUSTED."
  (with-slots (payed cards status) player-hand
    (unless payed
      (setf payed t)
      (let ((player-hand-value (blackjack--player-hand-value cards 'soft)))
        (if (blackjack--player-hand-won player-hand-value dealer-hand-value dealer-hand-busted)
            (blackjack--pay-won-hand game player-hand)
          (if (blackjack--player-hand-lost-p player-hand-value dealer-hand-value)
              (blackjack--collect-lost-hand game player-hand)
            (setf status 'push)))))))

(defun blackjack--collect-lost-hand (game player-hand)
  "Collect bet from losing GAME PLAYER-HAND."
  (with-slots (money) game
    (with-slots (bet status) player-hand
      (cl-decf money bet)
      (setf status 'lost))))

(defun blackjack--pay-won-hand (game player-hand)
  "Pay winning GAME PLAYER-HAND bet."
  (with-slots (bet cards status) player-hand
    (when (blackjack--hand-is-blackjack-p cards)
      (setf bet (truncate (* 1.5 bet))))
    (with-slots (money) game
      (cl-incf money bet)
      (setf status 'won))))

(defun blackjack--player-hand-lost-p (player-hand-value dealer-hand-value)
  "Return non-nil if PLAYER-HAND-VALUE < DEALER-HAND-VALUE."
  (< player-hand-value dealer-hand-value))

(defun blackjack--player-hand-won (player-hand-value dealer-hand-value dealer-hand-busted)
  "Return non-nil if PLAYER-HAND-VALUE > DEALER-HAND-VALUE && !DEALER-HAND-BUSTED."
  (or dealer-hand-busted
      (> player-hand-value dealer-hand-value)))

(defun blackjack--player-hand-done-p (game player-hand)
  "Return non-nil when GAME PLAYER-HAND is done."
  (when (blackjack--no-more-actions-p player-hand)
    (with-slots (played payed cards) player-hand
      (setf played t)
      (when (and (not payed)
                 (blackjack--player-hand-is-busted-p cards))
        (blackjack--collect-busted-hand game player-hand)))
    t))

(defun blackjack--collect-busted-hand (game player-hand)
  "Collect bet from GAME PLAYER-HAND."
  (with-slots (money) game
    (with-slots (payed status bet) player-hand
      (setf payed t
            status 'lost)
      (cl-decf money bet))))

(defun blackjack--no-more-actions-p (player-hand)
  "Return non-nil when PLAYER-HAND has no more actions."
  (with-slots (cards played stood) player-hand
    (or
     played
     stood
     (blackjack--hand-is-blackjack-p cards)
     (blackjack--player-hand-is-busted-p cards)
     (= 21 (blackjack--player-hand-value cards 'soft))
     (= 21 (blackjack--player-hand-value cards 'hard)))))

(defun blackjack--need-to-shuffle-p (game)
  "Return non-nil when GAME shoe is exhausted."
  (with-slots (shoe shuffle-specs num-decks) game
    (let ((cards-count (length shoe)))
      (if (> cards-count 0)
          (let ((used (- (blackjack--total-cards game) cards-count))
                (spec (aref shuffle-specs (1- num-decks))))
            (> (* 100 (/ (float used) cards-count)) spec))
        t))))

(defun blackjack--total-cards (game)
  "Return total number of cards per GAME shoe."
  (with-slots (cards-per-deck num-decks) game
    (* cards-per-deck num-decks)))

(defun blackjack--shuffle (game &optional card-values skip-shuffle)
  "Build a GAME shoe using CARD-VALUES if provided and shuffle unless SKIP-SHUFFLE."
  (let ((values (or card-values (blackjack--card-values game))))
    (with-slots (shoe) game
      (setf shoe (blackjack--build-cards game values))
      (unless skip-shuffle
        (setf shoe (blackjack--shuffle-loop shoe))))))

(defun blackjack--card-values (game)
  "Return card values from GAME deck-type."
  (pcase (slot-value game 'deck-type)
    ('regular (number-sequence 0 12))
    ('aces '(0))
    ('jacks '(10))
    ('aces-jacks '(0 10))
    ('sevens '(6))
    ('eights '(7))))

(defun blackjack--build-cards (game values)
  "Populate GAME shoe with card VALUES."
  (let ((total-cards (blackjack--total-cards game))
        (shoe '()))
    (while (< (length shoe) total-cards)
      (dotimes (suit 4)
        (dolist (value (reverse values))
          (when (< (length shoe) total-cards)
            (push
             (blackjack-card :id (blackjack--next-id game) :value value :suit suit)
             shoe)))))
    (setf (slot-value game 'shoe) (blackjack--shuffle-loop shoe))
    shoe))

(defun blackjack--shuffle-loop (shoe)
  "Shuffle SHOE."
  (dotimes (_x (* 7 (length shoe)))
    (setq shoe (blackjack--move-rand-card shoe)))
  shoe)

(defun blackjack--move-rand-card (shoe)
  "Move a random card to the top of the SHOE."
  (let ((card (seq-random-elt shoe)))
    (setq shoe (cl-remove card shoe :count 1))
    (push card shoe)
    shoe))

(defun blackjack--draw-hands (game)
  "Draw GAME dealer hand and player hands."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (blackjack--update-header game)
    (insert "\n  Dealer:\n")
    (blackjack--draw-dealer-hand game)
    (insert "\n\n  Player:\n")
    (blackjack--draw-player-hands game)))

(defun blackjack--format-money (money)
  "Format MONEY."
  (format "%.2f" (/ money 100.0)))

(defun blackjack--more-hands-to-play-p (game)
  "Return non-nil when there are more split GAME hands to play."
  (with-slots (current-player-hand player-hands) game
    (< current-player-hand (1- (length player-hands)))))

(defun blackjack--play-more-hands (game)
  "Advance to next split GAME player hand."
  (with-slots (current-player-hand current-menu) game
    (let (player-hand)
      (cl-incf current-player-hand)
      (setq player-hand (blackjack--current-player-hand game))
      (blackjack--deal-card game player-hand)
      (if (blackjack--player-hand-done-p game player-hand)
          (blackjack--process game)
        (setf current-menu 'hand)
        (blackjack--draw-hands game)
        (blackjack--ask-hand-action game)))))

(defun blackjack--need-to-play-dealer-hand-p (game)
  "Return non-nil when playing the GAME dealer hand is required."
  (with-slots (player-hands) game
    (cl-dolist (player-hand player-hands)
      (with-slots (cards) player-hand
        (unless (or
                 (blackjack--player-hand-is-busted-p cards)
                 (blackjack--hand-is-blackjack-p cards))
          (cl-return t))))))

(defun blackjack--dealer-hand-counts (dealer-hand)
  "Return soft and hard counts for DEALER-HAND."
  (mapcar
   (apply-partially #'blackjack--dealer-hand-value dealer-hand) '(soft hard)))

(defun blackjack--deal-required-cards (game)
  "Deal GAME dealer-hand required cards."
  (with-slots (dealer-hand) game
    (while
        (let ((counts (blackjack--dealer-hand-counts dealer-hand)))
          (and
           (< (nth 0 counts) 18)
           (< (nth 1 counts) 17)))
      (blackjack--deal-card game dealer-hand))))

(defun blackjack--play-dealer-hand (game)
  "Player GAME dealer hand."
  (let ((playing (blackjack--need-to-play-dealer-hand-p game)))
    (with-slots (dealer-hand current-menu) game
      (with-slots (cards hide-down-card played) dealer-hand
        (when (or playing
                  (blackjack--hand-is-blackjack-p cards))
          (setf hide-down-card nil))
        (when playing
          (blackjack--deal-required-cards game))
        (setf played t)
        (blackjack--pay-hands game)
        (setf current-menu 'game)
        (blackjack--draw-hands game)
        (blackjack--ask-game-action game)))))

(defun blackjack--process (game)
  "Handle more split GAME hands to play."
  (if (blackjack--more-hands-to-play-p game)
      (blackjack--play-more-hands game)
    (blackjack--play-dealer-hand game)))

(defun blackjack--hit (game)
  "Deal a new card to the current GAME player hand."
  (let ((player-hand (blackjack--current-player-hand game)))
    (blackjack--deal-card game player-hand)
    (if (blackjack--player-hand-done-p game player-hand)
        (blackjack--process game)
      (setf (slot-value game 'current-menu) 'hand)
      (blackjack--draw-hands game)
      (blackjack--ask-hand-action game))))

(defun blackjack--double (game)
  "Double the current GAME player hand bet and deal a single card."
  (let ((player-hand (blackjack--current-player-hand game)))
    (blackjack--deal-card game player-hand)
    (with-slots (played bet) player-hand
      (setf played t)
      (cl-callf * bet 2))
    (if (blackjack--player-hand-done-p game player-hand)
        (blackjack--process game)
      (blackjack--ask-hand-action game))))

(defun blackjack--stand (game)
  "End the current GAME player hand."
  (with-slots (stood played) (blackjack--current-player-hand game)
    (setf stood t
          played t))
  (blackjack--process game))

(defun blackjack--split (game)
  "Split the current GAME player hand."
  (with-slots (player-hands current-bet current-player-hand current-menu) game
    (let ((player-hand)
          (card)
          (hand
           (blackjack-player-hand :id (blackjack--next-id game) :bet current-bet))
          (x))
      (cl-callf append player-hands `(,hand))
      (setq x (1- (length player-hands)))
      (while (> x current-player-hand)
        (setq player-hand (nth (1- x) player-hands))
        (setq hand (nth x player-hands))
        (setf (slot-value hand 'cards) (slot-value player-hand 'cards))
        (cl-decf x))
      (setq player-hand (nth current-player-hand player-hands))
      (setq hand (nth (1+ current-player-hand) player-hands))
      (with-slots ((hand-cards cards)) hand
        (with-slots ((player-hand-cards cards)) player-hand
          (setq card (nth 1 player-hand-cards))
          (setf hand-cards `(,card))
          (setf player-hand-cards (cl-remove card player-hand-cards :count 1))
          (blackjack--deal-card game player-hand)
          (if (blackjack--player-hand-done-p game player-hand)
              (blackjack--process game)
            (setf current-menu 'hand)
            (blackjack--draw-hands game)
            (blackjack--ask-hand-action game)))))))

(defun blackjack--valid-menu-action-p (game action)
  "Return non-nil if the GAME menu ACTION can be performed."
  (eq (slot-value game 'current-menu) action))

(defun blackjack--hand-can-hit-p (game)
  "Return non-nil if the GAME current hand can hit."
  (when (blackjack--valid-menu-action-p game 'hand)
    (let* ((player-hand (blackjack--current-player-hand game))
           (cards (slot-value player-hand 'cards)))
      (not
       (or
        (slot-value player-hand 'played)
        (slot-value player-hand 'stood)
        (= 21 (blackjack--player-hand-value cards 'hard))
        (blackjack--hand-is-blackjack-p cards)
        (blackjack--player-hand-is-busted-p cards))))))

(defun blackjack--hand-can-stand-p (game)
  "Return non-nil if the GAME current hand can stand."
  (when (blackjack--valid-menu-action-p game 'hand)
    (let* ((player-hand (blackjack--current-player-hand game))
           (cards (slot-value player-hand 'cards)))
      (not
       (or
        (slot-value player-hand 'stood)
        (blackjack--player-hand-is-busted-p cards)
        (blackjack--hand-is-blackjack-p cards))))))

(defun blackjack--hand-can-split-p (game)
  "Return non-nil if the GAME current hand can split."
  (when (blackjack--valid-menu-action-p game 'hand)
    (let* ((player-hand (blackjack--current-player-hand game))
           (cards (slot-value player-hand 'cards))
           (card-0 (nth 0 cards))
           (card-1 (nth 1 cards)))
      (and
       (not (slot-value player-hand 'stood))
       (< (length (slot-value game 'player-hands)) 7)
       (>= (slot-value game 'money) (+ (blackjack--all-bets game) (slot-value player-hand 'bet)))
       (eq (length cards) 2)
       (eq (slot-value card-0 'value) (slot-value card-1 'value))))))

(defun blackjack--hand-can-double-p (game)
  "Return non-nil if the GAME current hand can double."
  (when (blackjack--valid-menu-action-p game 'hand)
    (let* ((player-hand (blackjack--current-player-hand game))
           (cards (slot-value player-hand 'cards)))
      (and
       (>= (slot-value game 'money) (+ (blackjack--all-bets game) (slot-value player-hand 'bet)))
       (not
        (or
         (slot-value player-hand 'stood)
         (not (eq 2 (length cards)))
         (blackjack--hand-is-blackjack-p cards)))))))

(defun blackjack--current-player-hand (game)
  "Return current GAME player hand."
  (with-slots (current-player-hand player-hands) game
    (nth current-player-hand player-hands)))

(defun blackjack--all-bets (game)
  "Return the sum of all GAME player hand bets."
  (cl-reduce #'+
             (slot-value game 'player-hands)
             :key (lambda (player-hand) (slot-value player-hand 'bet))))

(defun blackjack--insure-hand (game)
  "Insure the current GAME player hand."
  (interactive)
  (when (blackjack--valid-menu-action-p game 'insurance)
    (with-slots (money current-menu) game
      (with-slots (bet played payed status) (blackjack--current-player-hand game)
        (cl-callf / bet 2)
        (setf played t
              payed t
              status 'lost)
        (cl-decf money bet))
      (setf current-menu 'game)
      (blackjack--draw-hands game)
      (blackjack--ask-game-action game))))

(defun blackjack--no-insurance (game)
  "Decline GAME player hand insurance."
  (interactive)
  (with-slots (dealer-hand current-menu) game
    (with-slots ((dealer-hand-cards cards) hide-down-card) dealer-hand
      (when (blackjack--valid-menu-action-p game 'insurance)
        (if (blackjack--hand-is-blackjack-p dealer-hand-cards)
            (progn
              (setf hide-down-card nil)
              (blackjack--pay-hands game)
              (setf current-menu 'game)
              (blackjack--draw-hands game)
              (blackjack--ask-game-action game))
          (let ((player-hand (blackjack--current-player-hand game)))
            (if (blackjack--player-hand-done-p game player-hand)
                (blackjack--play-dealer-hand game)
              (setf current-menu 'hand)
              (blackjack--draw-hands game)
              (blackjack--ask-hand-action game))))))))

(defun blackjack--ask-new-bet (game)
  "Update the current GAME player bet."
  (interactive)
  (when (blackjack--valid-menu-action-p game 'game)
    (let* ((answer (blackjack--new-bet-menu))
           (bet (* 100 (string-to-number answer))))
      (with-slots (current-bet current-menu) game
        (setf current-bet bet)
        (blackjack--normalize-current-bet game)
        (blackjack--save game)
        (setf current-menu 'game)
        (blackjack--deal-new-hand game)))))

(defun blackjack--new-bet-menu ()
  "Get new bet."
  (read-string "Bet amount: "))

(defun blackjack--player-hand-is-busted-p (cards)
  "Return non-nil if CARDS value is more than 21."
  (> (blackjack--player-hand-value cards 'soft) 21))

(defun blackjack--dealer-hand-is-busted-p (dealer-hand)
  "Return non-nil if DEALER-HAND cards value is more than 21."
  (> (blackjack--dealer-hand-value dealer-hand 'soft) 21))

(defun blackjack--hand-is-blackjack-p (cards)
  "Return non-nil if hand CARDS is blackjack."
  (and (= 2 (length cards))
       (seq-some #'blackjack--is-ace-p cards)
       (seq-some #'blackjack--is-ten-p cards)))

(defun blackjack--dealer-upcard-is-ace-p (dealer-hand)
  "Return non-nil if DEALER-HAND up-card is an ace."
  (blackjack--is-ace-p (nth 1 (slot-value dealer-hand 'cards))))

(defconst blackjack--down-card '(13 0)
  "Hidden card location in faces array.")

(defun blackjack--dealer-hand-to-str (game)
  "Return GAME dealer-hand as a string."
  (let ((str "  "))
    (with-slots (dealer-hand) game
      (with-slots (hide-down-card cards) dealer-hand
        (seq-map-indexed
         (lambda (card index)
           (setq str (concat str
                             (apply #'blackjack--card-face game
                                    (if (and (= index 0) hide-down-card)
                                        blackjack--down-card
                                      (with-slots (value suit) card
                                        `(,value ,suit))))))
           (setq str (concat str " ")))
         cards))
      (setq str (concat str " ⇒  "))
      (setq str (concat str (number-to-string (blackjack--dealer-hand-value dealer-hand 'soft)))))
    str))

(defun blackjack--draw-dealer-hand (game)
  "Draw the GAME dealer-hand."
  (insert (blackjack--dealer-hand-to-str game)))

(defun blackjack--dealer-hand-value (dealer-hand count-method)
  "Calculates DEALER-HAND cards total value based on COUNT-METHOD."
  (let ((total 0))
    (with-slots (hide-down-card cards) dealer-hand
      (seq-map-indexed
       (lambda (card index)
         "Value one of the cards in the dealer's hand."
         (unless (and (= index 0) hide-down-card)
           (cl-incf total (blackjack--card-val card count-method total))))
       cards))
    (when (and (eq count-method 'soft) (> total 21))
      (setq total (blackjack--dealer-hand-value dealer-hand 'hard)))
    total))

(defun blackjack--draw-player-hands (game)
  "Draws GAME player hands."
  (seq-map-indexed
   (apply-partially #'blackjack--draw-player-hand game)
   (slot-value game 'player-hands)))

(defun blackjack--draw-player-hand (game player-hand index)
  "Draws a single GAME PLAYER-HAND using an INDEX."
  (insert (blackjack--player-hand-to-str game player-hand index)))

(defun blackjack--player-hand-to-str (game player-hand index)
  "Draw the GAME PLAYER-HAND using an INDEX."
  (concat (blackjack--player-hand-cards game player-hand)
          (blackjack--player-hand-money game player-hand index)
          (blackjack--player-hand-status player-hand)
          "\n\n"))

(defun blackjack--player-hand-cards (game player-hand)
  "Draw GAME PLAYER-HAND cards."
  (with-slots (cards) player-hand
    (format "  %s  ⇒  %s  "
            (mapconcat
             (lambda (card)
               "Present how CARD is to be drawn."
               (with-slots (value suit) card
                 (blackjack--card-face game value suit)))
             cards
             " ")
            (number-to-string (blackjack--player-hand-value cards 'soft)))))

(defun blackjack--player-hand-status (player-hand)
  "Return PLAYER-HAND status."
  (with-slots (cards status) player-hand
    (pcase status
      ('lost (if (blackjack--player-hand-is-busted-p cards)
                 "Busted!"
               "Lost!"))
      ('won (if (blackjack--hand-is-blackjack-p cards)
                "Blackjack!"
              "Won!"))
      ('push "Push")
      ('unknown ""))))

(defun blackjack--player-hand-money (game player-hand index)
  "Return GAME PLAYER-HAND money using an INDEX."
  (with-slots (current-player-hand) game
    (with-slots (played status bet) player-hand
      (concat
       (when (eq status 'lost) "-")
       (when (eq status 'won) "+")
       blackjack-currency
       (blackjack--format-money bet)
       (when (and
              (not played)
              (= index current-player-hand))
         " ⇐")
       "  "))))

(defun blackjack--player-hand-value (cards count-method)
  "Calculates CARDS total value based on COUNT-METHOD."
  (let ((total 0))
    (dolist (card cards)
      (cl-incf total (blackjack--card-val card count-method total)))
    (when (and (eq count-method 'soft) (> total 21))
      (setq total (blackjack--player-hand-value cards 'hard)))
    total))

(defun blackjack--card-val (card count-method total)
  "Calculates CARD value based on COUNT-METHOD and running hand TOTAL."
  (let ((value (1+ (slot-value card 'value))))
    (when (> value 9)
      (setq value 10))
    (when (and (eq count-method 'soft) (= value 1) (< total 11))
      (setq value 11))
    value))

(defun blackjack--card-face (game value suit)
  "Return GAME card face based on VALUE and SUIT."
  (let ((face
         (with-slots (face-type faces-alternate faces-regular) game
           (if (eq face-type 'alternate)
               faces-alternate
             faces-regular))))
    (aref (aref face value) suit)))

(defun blackjack--is-ace-p (card)
  "Return non-nil if CARD is an ace."
  (= 0 (slot-value card 'value)))

(defun blackjack--is-ten-p (card)
  "Return non-nil if CARD has a value of 10."
  (> (slot-value card 'value) 8))

(defun blackjack--normalize-current-bet (game)
  "Normalize current GAME player bet."
  (let ((min-bet (slot-value game 'min-bet))
        (max-bet (slot-value game 'max-bet))
        (current-bet (slot-value game 'current-bet))
        (money (slot-value game 'money)))
    (when (< current-bet min-bet)
      (setq current-bet min-bet))
    (when (> current-bet max-bet)
      (setq current-bet max-bet))
    (when (> current-bet money)
      (setq current-bet money))
    (setf (slot-value game 'current-bet) current-bet)))

(defun blackjack--persist-file-name ()
  "Resolve the persist file including all abbreviations and symlinks."
  (file-truename (expand-file-name blackjack-persist-file)))

;; (defun blackjack--load-saved-game (game)
;;   "Load persisted GAME state."
;;   (when-let ((content
;;               (ignore-errors
;;                 (with-temp-buffer
;;                   (insert-file-contents-literally (blackjack--persist-file-name))
;;                   (buffer-string))))
;;              (parts (split-string content "|"))
;;              ((= (length parts) 5)))
;;     (with-slots (num-decks deck-type face-type money current-bet) game
;;       (setf num-decks (string-to-number (nth 0 parts))
;;             deck-type (intern (nth 1 parts))
;;             face-type (intern (nth 2 parts))
;;             money (string-to-number (nth 3 parts))
;;             current-bet (string-to-number (nth 4 parts))))))

(defun blackjack--load-saved-game (game)
  "Load persisted GAME state."
  (let (content parts)
    (ignore-errors
      (with-temp-buffer
        (insert-file-contents-literally (blackjack--persist-file-name))
        (setq content (buffer-string))))
    (when content
      (setq parts (split-string content "|")))
    (when (= (length parts) 5)
      (setf (slot-value game 'num-decks) (string-to-number (nth 0 parts))
            (slot-value game 'deck-type) (intern (nth 1 parts))
            (slot-value game 'face-type) (intern (nth 2 parts))
            (slot-value game 'money) (string-to-number (nth 3 parts))
            (slot-value game 'current-bet) (string-to-number (nth 4 parts))))))

(defun blackjack--save (game)
  "Persist GAME state."
  (ignore-errors
    (with-temp-file (blackjack--persist-file-name)
      (insert
       (with-slots (num-decks deck-type face-type money current-bet) game
         (format "%s|%s|%s|%s|%s" num-decks deck-type face-type money current-bet))))))

(defun blackjack--quit (game)
  "Quit Blackjack GAME."
  (interactive)
  (when (blackjack--valid-menu-action-p game 'game)
    (setf (slot-value game 'quitting) t)
    (quit-window)))

(defun blackjack--header (game)
  "Return GAME header."
  (with-slots (money current-menu) game
    (format "  Blackjack %s%s  %s"
            blackjack-currency
            (blackjack--format-money money)
            (pcase current-menu
              ('game (blackjack--game-header-menu))
              ('hand (blackjack--hand-menu game))
              ('options (blackjack--options-header-menu))
              ('deck-type (blackjack--deck-type-header-menu))
              ('face-type (blackjack--face-type-header-menu))
              ('num-decks (blackjack--num-decks-header-menu))
              ('bet (blackjack--bet-menu))
              ('insurance (blackjack--insurance-header-menu))))))

(defun blackjack--update-header (game)
  "Update GAME header."
  (setq header-line-format (blackjack--header game)))

(defun blackjack--game-header-menu ()
  "Return game menu string."
  (format "(%s) deal new hand  (%s) change bet  (%s) options  (%s) quit"
          blackjack-deal-double-key
          blackjack-bet-back-key
          blackjack-options-key
          blackjack-quit-key))

(defun blackjack--ask-game-action (game)
  "Ask about next GAME action."
  (setf (slot-value game 'current-menu) 'game)
  (blackjack--update-header game)
  (pcase (blackjack-game-actions-menu)
    ("deal" nil)
    ("bet" (blackjack--ask-new-bet game))
    ("options" (blackjack--ask-game-options game))
    ("quit" (blackjack--quit game))))

(defun blackjack-game-actions-menu ()
  "Bet actions menu for GAME."
  (let ((read-answer-short t))
    (read-answer "Game Actions: "
                 `(("deal" ,blackjack-deal-double-key "deal new hand")
                   ("bet" ,blackjack-bet-back-key "change current bet")
                   ("options" ,blackjack-options-key "change game options")
                   ("quit" ,blackjack-quit-key "quit blackjack")
                   ("help" ?? "show help")))))

(defun blackjack--options-header-menu ()
  "Return option menu string."
  (format "(%s) number of decks  (%s) deck type  (%s) face type  (%s) go back"
          blackjack-num-decks-no-insurance-key
          blackjack-deck-type-key
          blackjack-face-type-key
          blackjack-bet-back-key))

(defun blackjack--ask-game-options (game)
  "Ask about which GAME option to update."
  (setf (slot-value game 'current-menu) 'options)
  (blackjack--update-header game)
  (let ((answer (blackjack--game-options-menu)))
    (pcase answer
      ("number-decks" (blackjack--ask-new-number-decks game))
      ("deck-type" (blackjack--ask-new-deck-type game))
      ("face-type" (blackjack--ask-new-face-type game))
      ("back" (blackjack--ask-game-action game)))))

(defun blackjack--game-options-menu ()
  "GAME options menu."
  (let ((read-answer-short t))
    (read-answer
     "Options: "
     `(("number-decks" ,blackjack-num-decks-no-insurance-key "change number of decks")
       ("deck-type" ,blackjack-deck-type-key "change the deck type")
       ("face-type" ,blackjack-face-type-key "change the card face type")
       ("back" ,blackjack-bet-back-key "go back to previous menu")
       ("help" ?? "show help")))))

(defun blackjack--deck-type-header-menu ()
  "Return deck type menu string."
  (format
   "(%s) regular  (%s) aces  (%s) jacks  (%s) aces & jacks  (%s) sevens  (%s) eights"
   blackjack-deck-regular-key
   blackjack-deck-aces-key
   blackjack-deck-jacks-key
   blackjack-deck-aces-jacks-key
   blackjack-deck-sevens-key
   blackjack-deck-eights-key))

(defun blackjack--ask-new-deck-type (game)
  "Ask for new GAME deck type."
  (with-slots (current-menu deck-type) game
    (setf current-menu 'deck-type)
    (blackjack--update-header game)
    (setf deck-type (intern (blackjack-deck-type-menu)))
    (blackjack--normalize-num-decks game)
    (blackjack--shuffle-save-deal-new-hand game)))

(defun blackjack--normalize-num-decks (game)
  "Normalize GAME num-decks."
  (with-slots (num-decks deck-type) game
    (when (and (< num-decks 2)
               (eq deck-type 'aces))
      (setf num-decks 2))
    (cl-callf max num-decks 1)
    (cl-callf min num-decks 8)))

(defun blackjack-deck-type-menu ()
  "New GAME deck type menu."
  (let ((read-answer-short t))
    (read-answer
     "Deck Type: "
     `(("regular" ,blackjack-deck-regular-key "regular deck")
       ("aces" ,blackjack-deck-aces-key "deck of aces")
       ("jacks" ,blackjack-deck-jacks-key "deck of jacks")
       ("aces-jacks" ,blackjack-deck-aces-jacks-key "deck of aces and jacks")
       ("sevens" ,blackjack-deck-sevens-key "deck of sevens")
       ("eights" ,blackjack-deck-eights-key "deck of eights")
       ("help" ?? "show help")))))

(defun blackjack--face-type-header-menu ()
  "Return face type menu string."
  (format "(%s) A♠ regular  (%s) 🂡 alternate"
          blackjack-face-type-regular-key
          blackjack-face-type-alternate-key))

(defun blackjack--ask-new-face-type (game)
  "Ask for new GAME face type."
  (with-slots (current-menu face-type) game
    (setf current-menu 'face-type)
    (blackjack--update-header game)
    (setf face-type (intern (blackjack--face-type-menu)))
    (blackjack--save-deal-new-hand game)))

(defun blackjack--face-type-menu ()
  "New GAME face type menu."
  (let* ((read-answer-short t))
    (read-answer "Card Face Type: "
                 `(("regular" ,blackjack-face-type-regular-key "use regular face type")
		   ("alternate" ,blackjack-face-type-alternate-key "use alternate face type")
                   ("help" ?? "show help")))))

(defun blackjack--insurance-header-menu ()
  "Return insurance menu string."
  (format "(%s) insure hand  (%s) refuse insurance"
          blackjack-insurance-key
          blackjack-num-decks-no-insurance-key))

(defun blackjack--ask-insurance-action (game)
  "Ask about insuring GAME hand."
  (pcase (blackjack--ask-insurance-menu)
    ("yes" (blackjack--insure-hand game))
    ("no" (blackjack--no-insurance game))
    ("help" ?? "show help")))

(defun blackjack--ask-insurance-menu ()
  "Ask about insuring GAME hand."
  (let ((read-answer-short t))
    (read-answer
     "Hand Insurance: "
     `(("yes" ,blackjack-insurance-key "insure hand")
       ("no" ,blackjack-num-decks-no-insurance-key "refuse insurance")
       ("help" ?? "show help")))))

(defun blackjack--num-decks-header-menu ()
  "Return number of decks menu string."
  "Number of decks (1-8)")

(defun blackjack--bet-menu ()
  "Return bet menu string."
  "New bet")

(defun blackjack--new-number-decks-prompt ()
  "Get new number of decks value."
  (read-string "Enter number of decks: "))

(defun blackjack--hand-menu (game)
  "Return GAME hand menu string."
  (let ((options '()))
    (when (blackjack--hand-can-double-p game)
      (push (format "(%s) double" blackjack-deal-double-key) options))
    (when (blackjack--hand-can-split-p game)
      (push (format "(%s) split" blackjack-split-key) options))
    (when (blackjack--hand-can-stand-p game)
      (push (format "(%s) stand" blackjack-stand-key) options))
    (when (blackjack--hand-can-hit-p game)
      (push (format "(%s) hit" blackjack-hit-key) options))
    (mapconcat #'identity options "  ")))

(defun blackjack--ask-hand-action (game)
  "Ask hand action for GAME."
  (let ((answer (blackjack--hand-actions-menu game)))
    (pcase answer
      ("stand" (if (blackjack--hand-can-stand-p game)
		   (blackjack--stand game)
		 (blackjack--ask-hand-action game)))
      ("hit" (if (blackjack--hand-can-hit-p game)
		 (blackjack--hit game)
	       (blackjack--ask-hand-action game)))
      ("split" (if (blackjack--hand-can-split-p game)
		   (blackjack--split game)
		 (blackjack--ask-hand-action game)))
      ("double" (if (blackjack--hand-can-double-p game)
		    (blackjack--double game)
		  (blackjack--ask-hand-action game))))))

(defun blackjack--hand-actions-menu (game)
  "Hand actions menu for GAME."
  (let ((read-answer-short t)
	(actions '(("help" ?? "show help"))))
    (when (blackjack--hand-can-double-p game)
      (push `("double" ,blackjack-deal-double-key "double bet, deal a new card, and end hand") actions))
    (when (blackjack--hand-can-split-p game)
      (push `("split" ,blackjack-split-key "split hand into two hands") actions))
    (when (blackjack--hand-can-stand-p game)
      (push `("stand" ,blackjack-stand-key "end current hand with no further actions") actions))
    (when (blackjack--hand-can-hit-p game)
      (push `("hit" ,blackjack-hit-key "deal a new card") actions))
    (read-answer "Hand Action " actions)))

(defun blackjack--show-options-menu (game)
  "Switch to GAME options menu."
  (interactive)
  (when (blackjack--valid-menu-action-p game 'game)
    (setf (slot-value game 'current-menu) 'options)
    (blackjack--update-header game)
    (blackjack--ask-game-options game)))

(defun blackjack--show-num-decks-menu (game)
  "Switch to GAME number of decks menu."
  (setf (slot-value game 'current-menu) 'num-decks)
  (blackjack--update-header game)
  (blackjack--ask-new-number-decks game))

(defun blackjack--ask-new-number-decks (game)
  "Get new number of GAME decks."
  (with-slots (current-menu num-decks) game
    (setf current-menu 'num-decks)
    (blackjack--update-header game)
    (setf num-decks (string-to-number (blackjack--new-number-decks-prompt)))
    (blackjack--normalize-num-decks game)
    (blackjack--save game)
    (blackjack--shuffle game)
    (setf current-menu 'game)
    (blackjack--deal-new-hand game)))

(defun blackjack--show-game-menu (game)
  "Switch to GAME menu."
  (interactive)
  (setf (slot-value game 'current-menu) 'game)
  (blackjack--update-header game))

(dolist (menu '(deck-type face-type))
  (let ((func-name (intern (format "blackjack--show-%s-menu" menu))))
    (fset func-name
          (lambda (game)
            (interactive)
            (when (blackjack--valid-menu-action-p game 'options)
              (setf (slot-value game 'current-menu) menu)
              (blackjack--update-header game)
              (funcall (intern (format "blackjack--ask-%s-action" menu))))))))

(defun blackjack--save-deal-new-hand (game)
  "Save GAME and deal new hand."
  (blackjack--save game)
  (setf (slot-value game 'current-menu) 'game)
  (blackjack--deal-new-hand game))

(defun blackjack--shuffle-save-deal-new-hand (game)
  "Shuffle, save, and deal new GAME hand."
  (blackjack--shuffle game)
  (blackjack--save-deal-new-hand game))

(defvar blackjack-minor-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Blackjack minor mode keymap.")

(define-minor-mode blackjack-minor-mode
  "Blackjack minor mode.

\\{blackjack-minor-mode-map}"
  :group 'blackjack
  :lighter " blackjack")

(define-derived-mode blackjack-mode special-mode "Blackjack"
  "Blackjack game mode."
  :group 'blackjack)

(defun blackjack--init ()
  "Initialize game state."
  (let ((game (blackjack-game)))
    (blackjack--load-saved-game game)
    (blackjack--normalize-num-decks game)
    (while (not (slot-value game 'quitting))
      (blackjack--deal-new-hand game))))

;;;###autoload
(defun blackjack ()
  "Run Blackjack."
  (interactive)
  (let ((debug-on-error t))
    (get-buffer-create blackjack--buffer-name)
    (switch-to-buffer blackjack--buffer-name)
    (with-current-buffer blackjack--buffer-name
      (add-hook 'blackjack-mode-hook #'blackjack-minor-mode)
      (blackjack-mode)
      (blackjack--init))))

(provide 'blackjack)
;;; blackjack.el ends here
