;;; blackjack.el --- The game of Blackjack -*- lexical-binding: t; -*-

;; Copyright (C) 2022, 2023 Greg Donald
;; SPDX-License-Identifier: GPL-3.0-only
;; Author: Greg Donald <gdonald@gmail.com>
;; Version: 1.0.3
;; Package-Version: 20230506.1330
;; Package-Commit: 2b340ad93a733ec3b2c83af367434c740d62eecf
;; Package-Requires: ((emacs "26.2"))
;; Keywords: card game games blackjack 21
;; URL: https://github.com/gdonald/blackjack-el

;;; Commentary:
;; This package lets you play Blackjack in Emacs.

;;; Code:

(require 'cl-lib)
(require 'eieio)

(defvar blackjack--game nil
  "The game state.")

(defconst blackjack--buffer-name "blackjack"
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

(defclass blackjack-card ()
  ((id :initarg :id :initform 0 :type integer)
   (value :initarg :value :initform 0 :type integer)
   (suit :initarg :suit :initform 0 :type integer)))

(cl-defmethod cl-print-object ((obj blackjack-card) stream)
  "Print OBJ to STREAM."
  (princ
   (format "#<%s id: %d value: %s suit: %s>"
           (eieio-class-name (eieio-object-class obj))
           (slot-value obj 'id)
           (slot-value obj 'value)
           (slot-value obj 'suit))
   stream))

(defclass blackjack-hand ()
  ((cards :initarg :cards :initform '() :type list)
   (played :initarg :played :initform nil :type boolean)))

(defclass blackjack-player-hand (blackjack-hand)
  ((id :initarg :id :initform 0 :type integer)
   (bet :initarg :bet :initform 0 :type integer)
   (status :initarg :status :initform 'unknown :type symbol)
   (payed :initarg :payed :initform nil :type boolean)
   (stood :intiarg :stood :initform nil :type boolean)))

(cl-defmethod cl-print-object ((obj blackjack-player-hand) stream)
  "Print OBJ to STREAM."
  (princ
   (format "#<%s id: %d cards: %s played: %s status: %s payed: %s stood: %s bet: %s>"
           (eieio-class-name (eieio-object-class obj))
           (slot-value obj 'id)
           (slot-value obj 'cards)
           (slot-value obj 'played)
           (slot-value obj 'status)
           (slot-value obj 'payed)
           (slot-value obj 'stood)
           (slot-value obj 'bet))
   stream))

(defclass blackjack-dealer-hand (blackjack-hand)
  ((hide-down-card :initarg :hide-down-card :initform t :type boolean)))

(cl-defmethod cl-print-object ((obj blackjack-dealer-hand) stream)
  "Print OBJ to STREAM."
  (princ
   (format "#<%s cards: %s played: %s hide-down-card: %s>"
           (eieio-class-name (eieio-object-class obj))
           (slot-value obj 'cards)
           (slot-value obj 'played)
           (slot-value obj 'hide-down-card))
   stream))

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
   (max-player-hands :initarg :max-player-hands :initform 7 :type integer)))

(defun blackjack--deal-new-hand ()
  "Deal new hands."
  (interactive)
  (if (blackjack--valid-menu-action-p 'game)
      (progn
        (if (blackjack--need-to-shuffle-p)
            (blackjack--shuffle))
        (let (player-hand dealer-hand)
          (setf (slot-value blackjack--game 'player-hands) '())
          (setq player-hand (blackjack-player-hand :id (blackjack--next-id) :bet (slot-value blackjack--game 'current-bet)))
          (setq dealer-hand (blackjack-dealer-hand))
          (dotimes (_x 2)
            (blackjack--deal-card player-hand)
            (blackjack--deal-card dealer-hand))
          (push player-hand (slot-value blackjack--game 'player-hands))
          (setf (slot-value blackjack--game 'current-player-hand) 0)
          (setf (slot-value blackjack--game 'dealer-hand) dealer-hand)
          (if (and
               (blackjack--dealer-upcard-is-ace-p dealer-hand)
               (not (blackjack--hand-is-blackjack-p (slot-value player-hand 'cards))))
              (progn
                (setf (slot-value blackjack--game 'current-menu) 'insurance)
                (blackjack--draw-hands))
            (if (blackjack--player-hand-done-p player-hand)
                (progn
                  (setf (slot-value dealer-hand 'hide-down-card) nil)
                  (blackjack--pay-hands)
                  (setf (slot-value blackjack--game 'current-menu) 'game)
                  (blackjack--draw-hands))
              (setf (slot-value blackjack--game 'current-menu) 'hand)
              (blackjack--draw-hands)
              (blackjack--save)))))))

(defun blackjack--deal-card (hand)
  "Deal a card into HAND from shoe."
  (interactive)
  (let ((shoe (slot-value blackjack--game 'shoe))
        (cards (slot-value hand 'cards))
        (card))
    (setq card (car shoe))
    (setq cards (reverse cards))
    (push card cards)
    (setq cards (reverse cards))
    (setq shoe (cl-remove card shoe :count 1))
    (setf (slot-value hand 'cards) cards)
    (setf (slot-value blackjack--game 'shoe) shoe)))

(defun blackjack--next-id ()
  "Return next object id."
  (let ((id (slot-value blackjack--game 'id)))
    (setf (slot-value blackjack--game 'id) (1+ id))))

(defun blackjack--pay-hands ()
  "Pay player hands."
  (let* ((dealer-hand (slot-value blackjack--game 'dealer-hand))
         (dealer-hand-value (blackjack--dealer-hand-value dealer-hand 'soft))
         (dealer-busted (blackjack--dealer-hand-is-busted-p dealer-hand))
         (player-hands (slot-value blackjack--game 'player-hands)))
    (dotimes (x (length player-hands))
      (blackjack--pay-player-hand (nth x player-hands) dealer-hand-value dealer-busted))
    (blackjack--normalize-current-bet)
    (blackjack--save)))

(defun blackjack--pay-player-hand (player-hand dealer-hand-value dealer-hand-busted)
  "Pay PLAYER-HAND based on DEALER-HAND-VALUE and DEALER-HAND-BUSTED."
  (if (not (slot-value player-hand 'payed))
      (progn
        (setf (slot-value player-hand 'payed) t)
        (let (player-hand-value)
          (setq player-hand-value (blackjack--player-hand-value (slot-value player-hand 'cards) 'soft))
          (if (blackjack--player-hand-won player-hand-value dealer-hand-value dealer-hand-busted)
              (blackjack--pay-won-hand player-hand)
            (if (blackjack--player-hand-lost-p player-hand-value dealer-hand-value)
                (blackjack--collect-lost-hand player-hand)
              (setf (slot-value player-hand 'status) 'push)))))))

(defun blackjack--collect-lost-hand (player-hand)
  "Collect bet from losing PLAYER-HAND."
  (setf (slot-value blackjack--game 'money) (- (slot-value blackjack--game 'money) (slot-value player-hand 'bet))
        (slot-value player-hand 'status) 'lost))

(defun blackjack--pay-won-hand (player-hand)
  "Pay winning PLAYER-HAND bet."
  (let ((bet (slot-value player-hand 'bet)))
    (if (blackjack--hand-is-blackjack-p (slot-value player-hand 'cards))
        (setf bet (truncate (* 1.5 bet))))
    (setf (slot-value blackjack--game 'money) (+ (slot-value blackjack--game 'money) bet)
          (slot-value player-hand 'status) 'won
          (slot-value player-hand 'bet) bet)))

(defun blackjack--player-hand-lost-p (player-hand-value dealer-hand-value)
  "Return non-nil if PLAYER-HAND-VALUE < DEALER-HAND-VALUE."
  (if (< player-hand-value dealer-hand-value)
      t))

(defun blackjack--player-hand-won (player-hand-value dealer-hand-value dealer-hand-busted)
  "Return non-nil if PLAYER-HAND-VALUE > DEALER-HAND-VALUE && !DEALER-HAND-BUSTED."
  (if (or
       dealer-hand-busted
       (> player-hand-value dealer-hand-value))
      t))

(defun blackjack--player-hand-done-p (player-hand)
  "Return non-nil when PLAYER-HAND is done."
  (if (not (blackjack--no-more-actions-p player-hand))
      nil
    (setf (slot-value player-hand 'played) t)
    (if (and
         (not (slot-value player-hand 'payed))
         (blackjack--player-hand-is-busted-p (slot-value player-hand 'cards)))
        (blackjack--collect-busted-hand player-hand))
    t))

(defun blackjack--collect-busted-hand (player-hand)
  "Collect bet from PLAYER-HAND."
  (setf (slot-value player-hand 'payed) t
        (slot-value player-hand 'status) 'lost
        (slot-value blackjack--game 'money) (- (slot-value blackjack--game 'money)
                                               (slot-value player-hand 'bet))))

(defun blackjack--no-more-actions-p (player-hand)
  "Return non-nil when PLAYER-HAND has no more actions."
  (let ((cards (slot-value player-hand 'cards)))
    (or
     (slot-value player-hand 'played)
     (slot-value player-hand 'stood)
     (blackjack--hand-is-blackjack-p cards)
     (blackjack--player-hand-is-busted-p cards)
     (= 21 (blackjack--player-hand-value cards 'soft))
     (= 21 (blackjack--player-hand-value cards 'hard)))))

(defun blackjack--need-to-shuffle-p ()
  "Return non-nil when shoe is exhausted."
  (let* ((shoe (slot-value blackjack--game 'shoe))
         (cards-count (length shoe)))
    (if (> cards-count 0)
        (progn
          (let ((used (- (blackjack--total-cards) cards-count))
                (spec (aref (slot-value blackjack--game 'shuffle-specs) (1- (slot-value blackjack--game 'num-decks)))))
            (> (* 100 (/ (float used) cards-count)) spec)))
      t)))

(defun blackjack--total-cards ()
  "Return total number of cards per shoe."
  (* (slot-value blackjack--game 'cards-per-deck) (slot-value blackjack--game 'num-decks)))

(defun blackjack--shuffle ()
  "Fill a new shoe with cards."
  (let ((total-cards (blackjack--total-cards))
        (shoe '())
        (values '()))
    (setq values
          (pcase (slot-value blackjack--game 'deck-type)
            ('regular (number-sequence 0 12))
            ('aces '(0))
            ('jacks '(10))
            ('aces-jacks '(0 10))
            ('sevens '(6))
            ('eights '(7))))
    (while (< (length shoe) total-cards)
      (dotimes (suit 4)
        (dolist (value values)
          (if (< (length shoe) total-cards)
              (setq shoe (cons (blackjack-card :id (blackjack--next-id) :value value :suit suit) shoe))))))
    (setf (slot-value blackjack--game 'shoe) (blackjack--shuffle-loop shoe))))

(defun blackjack--shuffle-loop (shoe)
  "Shuffle SHOE."
  (dotimes (_x (* 7 (length shoe)))
    (setq shoe (blackjack--move-rand-card shoe)))
  shoe)

(defun blackjack--move-rand-card (shoe)
  "Move a random card to the top of the SHOE."
  (let* ((rand (random (length shoe)))
         (card (nth rand shoe)))
    (setq shoe (cl-remove card shoe :count 1))
    (setq shoe (cons card shoe))
    shoe))

(defun blackjack--draw-hands ()
  "Draw dealer hand and player hands."
  (let ((inhibit-read-only t))
    (erase-buffer)
    (blackjack--update-header)
    (insert "\n  Dealer:\n")
    (blackjack--draw-dealer-hand)
    (insert "\n\n  Player:\n")
    (blackjack--draw-player-hands)))

(defun blackjack--format-money (money)
  "Format MONEY."
  (format "%.2f" money))

(defun blackjack--more-hands-to-play-p ()
  "Return non-nil when there are more split hands to play."
  (let ((current-player-hand (slot-value blackjack--game 'current-player-hand))
        (player-hands (slot-value blackjack--game 'player-hands)))
    (< current-player-hand (1- (length player-hands)))))

(defun blackjack--play-more-hands ()
  "Advance to next split player hand."
  (let (player-hand)
    (setf (slot-value blackjack--game 'current-player-hand) (1+ (slot-value blackjack--game 'current-player-hand)))
    (setq player-hand (blackjack--current-player-hand))
    (blackjack--deal-card player-hand)
    (if (blackjack--player-hand-done-p player-hand)
        (blackjack--process)
      (setf (slot-value blackjack--game 'current-menu) 'hand)
      (blackjack--draw-hands))))

(defun blackjack--need-to-play-dealer-hand-p ()
  "Return non-nil when playing the dealer hand is required."
  (let ((player-hands (slot-value blackjack--game 'player-hands)))
    (cl-dolist (player-hand player-hands)
      (when (not (or
                  (blackjack--player-hand-is-busted-p (slot-value player-hand 'cards))
                  (blackjack--hand-is-blackjack-p (slot-value player-hand 'cards))))
        (cl-return t)))))

(defun blackjack--dealer-hand-counts (dealer-hand)
  "Return soft and hard counts for DEALER-HAND."
  (let ((soft-count (blackjack--dealer-hand-value dealer-hand 'soft))
        (hard-count (blackjack--dealer-hand-value dealer-hand 'hard))
        (counts '()))
    (setq counts (cons hard-count counts))
    (setq counts (cons soft-count counts))
    counts))

(defun blackjack--deal-required-cards ()
  "Deal dealer-hand required cards."
  (let* ((dealer-hand (slot-value blackjack--game 'dealer-hand))
         (counts (blackjack--dealer-hand-counts dealer-hand)))
    (while
        (and
         (< (nth 0 counts) 18)
         (< (nth 1 counts) 17))
      (blackjack--deal-card dealer-hand)
      (setq counts (blackjack--dealer-hand-counts dealer-hand)))))

(defun blackjack--play-dealer-hand ()
  "Player dealer hand."
  (let* ((playing (blackjack--need-to-play-dealer-hand-p))
         (dealer-hand (slot-value blackjack--game 'dealer-hand))
         (cards (slot-value dealer-hand 'cards)))
    (if
        (or
         playing
         (blackjack--hand-is-blackjack-p cards))
        (setf (slot-value dealer-hand 'hide-down-card) nil))
    (if playing
        (blackjack--deal-required-cards))
    (setf (slot-value dealer-hand 'played) t)
    (blackjack--pay-hands)
    (setf (slot-value blackjack--game 'current-menu) 'game)
    (blackjack--draw-hands)))

(defun blackjack--process ()
  "Handle more split hands to play."
  (if (blackjack--more-hands-to-play-p)
      (blackjack--play-more-hands)
    (blackjack--play-dealer-hand)))

(defun blackjack--hit ()
  "Deal a new card to the current player hand."
  (interactive)
  (if (blackjack--valid-hand-action-p 'hit)
      (let ((player-hand (blackjack--current-player-hand)))
        (blackjack--deal-card player-hand)
        (if (blackjack--player-hand-done-p player-hand)
            (blackjack--process)
          (setf (slot-value blackjack--game 'current-menu) 'hand)
          (blackjack--draw-hands)))))

(defun blackjack--double ()
  "Double the current player hand bet and deal a single card."
  (interactive)
  (if (blackjack--valid-hand-action-p 'double)
      (let ((player-hand (blackjack--current-player-hand)))
        (blackjack--deal-card player-hand)
        (setf (slot-value player-hand 'played) t
              (slot-value player-hand 'bet) (* 2 (slot-value player-hand 'bet)))
        (if (blackjack--player-hand-done-p player-hand)
            (blackjack--process)))))

(defun blackjack--stand ()
  "End the current player hand."
  (interactive)
  (if (blackjack--valid-hand-action-p 'stand)
      (let ((player-hand (blackjack--current-player-hand)))
        (setf (slot-value player-hand 'stood) t
              (slot-value player-hand 'played) t)
        (blackjack--process))))

(defun blackjack--split ()
  "Split the current player hand."
  (interactive)
  (if (blackjack--valid-hand-action-p 'split)
      (let ((player-hands (slot-value blackjack--game 'player-hands))
            (player-hand) (card) (hand) (x 0))
        (setq hand (blackjack-player-hand :id (blackjack--next-id) :bet (slot-value blackjack--game 'current-bet)))
        (setq player-hands (reverse player-hands))
        (push hand player-hands)
        (setq player-hands (reverse player-hands))
        (setf (slot-value blackjack--game 'player-hands) player-hands)
        (setq x (1- (length player-hands)))
        (while (> x (slot-value blackjack--game 'current-player-hand))
          (setq player-hand (nth (1- x) player-hands))
          (setq hand (nth x player-hands))
          (setf (slot-value hand 'cards) (slot-value player-hand 'cards))
          (setq x (1- x)))
        (setq player-hand (nth (slot-value blackjack--game 'current-player-hand) player-hands))
        (setq hand (nth (1+ (slot-value blackjack--game 'current-player-hand)) player-hands))
        (setf (slot-value hand 'cards) '())
        (setq card (nth 1 (slot-value player-hand 'cards)))
        (push card (slot-value hand 'cards))
        (setf (slot-value player-hand 'cards) (cl-remove card (slot-value player-hand 'cards) :count 1))
        (blackjack--deal-card player-hand)
        (if (blackjack--player-hand-done-p player-hand)
            (blackjack--process)
          (setf (slot-value blackjack--game 'current-menu) 'hand)
          (blackjack--draw-hands)))))

(defun blackjack--valid-menu-action-p (action)
  "Return non-nil if the menu ACTION can be performed."
  (eq (slot-value blackjack--game 'current-menu) action))

(defun blackjack--valid-hand-action-p (action)
  "Return non-nil if the hand ACTION can be performed."
  (let* ((player-hand (blackjack--current-player-hand))
         (cards (slot-value player-hand 'cards))
         (card-0 (nth 0 cards))
         (card-1 (nth 1 cards)))
    (if (blackjack--valid-menu-action-p 'hand)
        (pcase action
          ('hit
           (not
            (or
             (slot-value player-hand 'played)
             (slot-value player-hand 'stood)
             (= 21 (blackjack--player-hand-value cards 'hard))
             (blackjack--hand-is-blackjack-p cards)
             (blackjack--player-hand-is-busted-p cards))))
          ('stand
           (not
            (or
             (slot-value player-hand 'stood)
             (blackjack--player-hand-is-busted-p cards)
             (blackjack--hand-is-blackjack-p cards))))
          ('split
           (and
            (not (slot-value player-hand 'stood))
            (< (length (slot-value blackjack--game 'player-hands)) 7)
            (>= (slot-value blackjack--game 'money) (+ (blackjack--all-bets) (slot-value player-hand 'bet)))
            (eq (length cards) 2)
            (eq (slot-value card-0 'value) (slot-value card-1 'value))))
          ('double
           (and
            (>= (slot-value blackjack--game 'money) (+ (blackjack--all-bets) (slot-value player-hand 'bet)))
            (not (or (slot-value player-hand 'stood) (not (eq 2 (length cards)))
                     (blackjack--hand-is-blackjack-p cards)))))))))

(defun blackjack--current-player-hand ()
  "Return current player hand."
  (nth (slot-value blackjack--game 'current-player-hand) (slot-value blackjack--game 'player-hands)))

(defun blackjack--all-bets ()
  "Return the sum of all player hand bets."
  (let ((player-hands (slot-value blackjack--game 'player-hands))
        (total 0))
    (dotimes (x (length player-hands))
      (setq total (+ total (slot-value (nth x player-hands) 'bet))))
    total))

(defun blackjack--insure-hand ()
  "Insure the current player hand."
  (interactive)
  (let* ((player-hand (blackjack--current-player-hand))
         (bet (slot-value player-hand 'bet))
         (new-bet (/ bet 2))
         (money (slot-value blackjack--game 'money)))
    (if (blackjack--valid-menu-action-p 'insurance)
        (progn
          (setf (slot-value player-hand 'bet) new-bet
                (slot-value player-hand 'played) t
                (slot-value player-hand 'payed) t
                (slot-value player-hand 'status) 'lost
                (slot-value blackjack--game 'money) (- money new-bet))
          (setf (slot-value blackjack--game 'current-menu) 'game)
          (blackjack--draw-hands)))))

(defun blackjack--no-insurance ()
  "Decline player hand insurance."
  (interactive)
  (let* ((dealer-hand (slot-value blackjack--game 'dealer-hand))
         (dealer-hand-cards (slot-value dealer-hand 'cards)))
    (if (blackjack--valid-menu-action-p 'insurance)
        (if (blackjack--hand-is-blackjack-p dealer-hand-cards)
            (progn
              (setf (slot-value dealer-hand 'hide-down-card) nil)
              (blackjack--pay-hands)
              (setf (slot-value blackjack--game 'current-menu) 'game)
              (blackjack--draw-hands))
          (let ((player-hand (blackjack--current-player-hand)))
            (if (blackjack--player-hand-done-p player-hand)
                (blackjack--play-dealer-hand)
              (setf (slot-value blackjack--game 'current-menu) 'hand)
              (blackjack--draw-hands)))))))

(defun blackjack--ask-new-bet ()
  "Update the current player bet."
  (interactive)
  (if (blackjack--valid-menu-action-p 'game)
      (let ((answer (blackjack--new-bet-menu))
            (bet 0))
        (progn
          (setq bet (* 100 (string-to-number answer)))
          (setf (slot-value blackjack--game 'current-bet) bet)
          (blackjack--normalize-current-bet)
          (blackjack--save)
          (setf (slot-value blackjack--game 'current-menu) 'game)
          (blackjack--deal-new-hand)))))

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
  (if (eq 2 (length cards))
      (let ((card-0 (nth 0 cards))
            (card-1 (nth 1 cards)))
        (or
         (and
          (blackjack--is-ace-p card-0)
          (blackjack--is-ten-p card-1))
         (and
          (blackjack--is-ace-p card-1)
          (blackjack--is-ten-p card-0))))))

(defun blackjack--dealer-upcard-is-ace-p (dealer-hand)
  "Return non-nil if DEALER-HAND up-card is an ace."
  (blackjack--is-ace-p (nth 1 (slot-value dealer-hand 'cards))))

(defun blackjack--draw-dealer-hand ()
  "Draw the dealer-hand."
  (let* ((dealer-hand (slot-value blackjack--game 'dealer-hand))
         (cards (slot-value dealer-hand 'cards))
         (hide-down-card (slot-value dealer-hand 'hide-down-card))
         (card) (suit) (value))
    (insert "  ")
    (dotimes (x (length cards))
      (setq card (nth x cards))
      (if (and hide-down-card (= x 0))
          (progn
            (setq value 13)
            (setq suit 0))
        (setq value (slot-value card 'value))
        (setq suit (slot-value card 'suit)))
      (insert (blackjack--card-face value suit))
      (insert " "))
    (insert " ⇒  ")
    (insert (number-to-string (blackjack--dealer-hand-value dealer-hand 'soft)))))

(defun blackjack--dealer-hand-value (dealer-hand count-method)
  "Calculates DEALER-HAND cards total value based on COUNT-METHOD."
  (let ((cards (slot-value dealer-hand 'cards))
        (hide-down-card (slot-value dealer-hand 'hide-down-card))
        (total 0) (card))
    (dotimes (x (length cards))
      (if (not (and hide-down-card (= x 0)))
          (progn
            (setq card (nth x cards))
            (setq total (+ total (blackjack--card-val card count-method total))))))
    (if (and (eq count-method 'soft) (> total 21))
        (setq total (blackjack--dealer-hand-value dealer-hand 'hard)))
    total))

(defun blackjack--draw-player-hands ()
  "Draw players hands."
  (let ((player-hands (slot-value blackjack--game 'player-hands))
        (player-hand))
    (dotimes (x (length player-hands))
      (setq player-hand (nth x player-hands))
      (blackjack--draw-player-hand player-hand x))))

(defun blackjack--draw-player-hand (player-hand index)
  "Draw the PLAYER-HAND using an INDEX."
  (insert (blackjack--player-hand-cards player-hand))
  (insert (blackjack--player-hand-money player-hand index))
  (insert (blackjack--player-hand-status player-hand))
  (insert "\n\n"))

(defun blackjack--player-hand-cards (player-hand)
  "Draw PLAYER-HAND cards."
  (let ((cards (slot-value player-hand 'cards))
        (card) (suit) (value) (out "  "))
    (dotimes (x (length cards))
      (setq card (nth x cards))
      (setq value (slot-value card 'value))
      (setq suit (slot-value card 'suit))
      (setq out (concat out (blackjack--card-face value suit)))
      (setq out (concat out " ")))
    (setq out (concat out " ⇒  "))
    (setq out (concat out (number-to-string (blackjack--player-hand-value cards 'soft)) "  "))
    out))

(defun blackjack--player-hand-status (player-hand)
  "Return PLAYER-HAND status."
  (let ((cards (slot-value player-hand 'cards))
        (status (slot-value player-hand 'status)))
    (pcase status
      ('lost (if (blackjack--player-hand-is-busted-p cards)
                 "Busted!"
               "Lost!"))
      ('won (if (blackjack--hand-is-blackjack-p cards)
                "Blackjack!"
              "Won!"))
      ('push "Push")
      ('unknown ""))))

(defun blackjack--player-hand-money (player-hand index)
  "Return PLAYER-HAND money using an INDEX."
  (let ((current-hand (slot-value blackjack--game 'current-player-hand))
        (played (slot-value player-hand 'played))
        (status (slot-value player-hand 'status))
        (bet (slot-value player-hand 'bet))
        (out ""))
    (if (equal status 'lost)
        (setq out (concat out "-")))
    (if (equal status 'won)
        (setq out (concat out "+")))
    (setq out (concat out "$" (blackjack--format-money (/ bet 100.0))))
    (if (and
         (not played)
         (= index current-hand))
        (setq out (concat out " ⇐")))
    (setq out (concat out "  "))
    out))

(defun blackjack--player-hand-value (cards count-method)
  "Calculates CARDS total value based on COUNT-METHOD."
  (let ((total 0) (card))
    (dotimes (x (length cards))
      (setq card (nth x cards))
      (setq total (+ total (blackjack--card-val card count-method total))))
    (if (and (eq count-method 'soft) (> total 21))
        (setq total (blackjack--player-hand-value cards 'hard)))
    total))

(defun blackjack--card-val (card count-method total)
  "Calculates CARD value based on COUNT-METHOD and running hand TOTAL."
  (let ((value (1+ (slot-value card 'value))))
    (if (> value 9)
        (setq value 10))
    (if (and (eq count-method 'soft) (eq value 1) (< total 11))
        (setq value 11))
    value))

(defun blackjack--card-face (value suit)
  "Return card face based on VALUE and SUIT."
  (let (face)
    (if (eq (slot-value blackjack--game 'face-type) 'alternate)
        (setq face (slot-value blackjack--game 'faces-alternate))
      (setq face (slot-value blackjack--game 'faces-regular)))
    (aref (aref face value) suit)))

(defun blackjack--is-ace-p (card)
  "Return non-nil if CARD is an ace."
  (= 0 (slot-value card 'value)))

(defun blackjack--is-ten-p (card)
  "Return non-nil if CARD has a value of 10."
  (> (slot-value card 'value) 8))

(defun blackjack--normalize-current-bet ()
  "Normalize current player bet."
  (let ((min-bet (slot-value blackjack--game 'min-bet))
        (max-bet (slot-value blackjack--game 'max-bet))
        (current-bet (slot-value blackjack--game 'current-bet))
        (money (slot-value blackjack--game 'money)))
    (if (< current-bet min-bet)
        (setq current-bet min-bet))
    (if (> current-bet max-bet)
        (setq current-bet max-bet))
    (if (> current-bet money)
        (setq current-bet money))
    (setf (slot-value blackjack--game 'current-bet) current-bet)))

(defun blackjack--persist-file-name ()
  "Resolve the persist file including all abbreviations and symlinks."
  (file-truename (expand-file-name blackjack-persist-file)))

(defun blackjack--load-saved-game ()
  "Load persisted state."
  (let (content parts)
    (ignore-errors
      (with-temp-buffer
        (insert-file-contents-literally (blackjack--persist-file-name))
        (setq content (buffer-string))))
    (if content
        (setq parts (split-string content "|")))
    (if (= (length parts) 5)
        (setf (slot-value blackjack--game 'num-decks) (string-to-number (nth 0 parts))
              (slot-value blackjack--game 'deck-type) (intern (nth 1 parts))
              (slot-value blackjack--game 'face-type) (intern (nth 2 parts))
              (slot-value blackjack--game 'money) (string-to-number (nth 3 parts))
              (slot-value blackjack--game 'current-bet) (string-to-number (nth 4 parts))))))

(defun blackjack--save ()
  "Persist state."
  (ignore-errors
    (with-temp-file (blackjack--persist-file-name)
      (insert (format "%s|%s|%s|%s|%s"
                      (slot-value blackjack--game 'num-decks)
                      (slot-value blackjack--game 'deck-type)
                      (slot-value blackjack--game 'face-type)
                      (slot-value blackjack--game 'money)
                      (slot-value blackjack--game 'current-bet))))))

(defun blackjack--quit ()
  "Quit Blackjack."
  (interactive)
  (if (blackjack--valid-menu-action-p 'game)
      (quit-window)))

(defun blackjack--header ()
  "Return header."
  (let ((money (slot-value blackjack--game 'money))
        (menu (slot-value blackjack--game 'current-menu))
        (out ""))
    (setq out (format "  Blackjack $%s  " (blackjack--format-money (/ money 100.0))))
    (setq out (concat out
                      (pcase menu
                        ('game (blackjack--game-menu))
                        ('hand (blackjack--hand-menu))
                        ('options (blackjack--options-menu))
                        ('deck-type (blackjack--deck-type-menu))
                        ('face-type (blackjack--face-type-menu))
                        ('num-decks (blackjack--num-decks-menu))
                        ('bet (blackjack--bet-menu))
                        ('insurance (blackjack--insurance-menu)))))
    out))

(defun blackjack--update-header ()
  "Update header."
  (let ((header (blackjack--header)))
    (setq header-line-format header)))

(defun blackjack--game-menu ()
  "Return game menu string."
  (format "(%s) deal new hand  (%s) change bet  (%s) options  (%s) quit"
          blackjack-deal-double-key
          blackjack-bet-back-key
          blackjack-options-key
          blackjack-quit-key))

(defun blackjack--options-menu ()
  "Return option menu string."
  (format "(%s) number of decks  (%s) deck type  (%s) face type  (%s) go back"
          blackjack-num-decks-no-insurance-key
          blackjack-deck-type-key
          blackjack-face-type-key
          blackjack-bet-back-key))

(defun blackjack--deck-type-menu ()
  "Return deck type menu string."
  (format "(%s) regular  (%s) aces  (%s) jacks  (%s) aces & jacks  (%s) sevens  (%s) eights"
          blackjack-deck-regular-key
          blackjack-deck-aces-key
          blackjack-deck-jacks-key
          blackjack-deck-aces-jacks-key
          blackjack-deck-sevens-key
          blackjack-deck-eights-key))

(defun blackjack--face-type-menu ()
  "Return face type menu string."
  (format "(%s) A♠ regular  (%s) 🂡 alternate"
          blackjack-face-type-regular-key
          blackjack-face-type-alternate-key))

(defun blackjack--insurance-menu ()
  "Return insurance menu string."
  (format "(%s) insure hand  (%s) no insurance"
          blackjack-insurance-key
          blackjack-num-decks-no-insurance-key))

(defun blackjack--num-decks-menu ()
  "Return number of decks menu string."
  "Number of decks (1-8)")

(defun blackjack--bet-menu ()
  "Return bet menu string."
  "New bet")

(defun blackjack--new-number-decks-prompt ()
  "Get new number of decks value."
  (read-string "Enter number of decks: "))

(defun blackjack--hand-menu ()
  "Return hand menu string."
  (let ((options '()))
    (if (blackjack--valid-hand-action-p 'double)
        (push (format "(%s) double" blackjack-deal-double-key) options))
    (if (blackjack--valid-hand-action-p 'split)
        (push (format "(%s) split" blackjack-split-key) options))
    (if (blackjack--valid-hand-action-p 'stand)
        (push (format "(%s) stand" blackjack-stand-key) options))
    (if (blackjack--valid-hand-action-p 'hit)
        (push (format "(%s) hit" blackjack-hit-key) options))
    (mapconcat #'identity options "  ")))

(defun blackjack--show-options-menu ()
  "Switch to options menu."
  (interactive)
  (if (blackjack--valid-menu-action-p 'game)
      (progn
        (setf (slot-value blackjack--game 'current-menu) 'options)
        (blackjack--update-header))))

(defun blackjack--show-num-decks-menu ()
  "Switch to number of decks menu."
  (setf (slot-value blackjack--game 'current-menu) 'num-decks)
  (blackjack--update-header)
  (blackjack--ask-new-number-decks))

(defun blackjack--ask-new-number-decks ()
  "Get new number of decks."
  (let ((answer (blackjack--new-number-decks-prompt))
        (num-decks 1))
    (setq num-decks (string-to-number answer))
    (if (< num-decks 1)
        (setq num-decks 1))
    (if (> num-decks 8)
        (setq num-decks 8))
    (setf (slot-value blackjack--game 'num-decks) num-decks)
    (blackjack--save)
    (blackjack--shuffle)
    (setf (slot-value blackjack--game 'current-menu) 'game)
    (blackjack--deal-new-hand)))

(defun blackjack--show-game-menu ()
  "Switch to game menu."
  (interactive)
  (setf (slot-value blackjack--game 'current-menu) 'game)
  (blackjack--update-header))

(defun blackjack--handle-input-n ()
  "Handle N key input."
  (interactive)
  (if (blackjack--valid-menu-action-p 'options)
      (blackjack--show-num-decks-menu)
    (if (blackjack--valid-menu-action-p 'insurance)
        (blackjack--no-insurance))))

(defun blackjack--handle-input-d ()
  "Handle D key input."
  (interactive)
  (if (blackjack--valid-menu-action-p 'game)
      (blackjack--deal-new-hand)
    (if (blackjack--valid-menu-action-p 'hand)
        (blackjack--double))))

(defun blackjack--handle-input-b ()
  "Handle B key input."
  (interactive)
  (if (blackjack--valid-menu-action-p 'game)
      (blackjack--ask-new-bet)
    (if (blackjack--valid-menu-action-p 'options)
        (blackjack--show-game-menu))))

(dolist (deck-type '(regular aces jacks aces-jacks sevens eights))
  (let ((func-name (intern (format "blackjack--deck-type-%s" deck-type))))
    (fset func-name
          (lambda ()
            (interactive)
            (if (blackjack--valid-menu-action-p 'deck-type)
                (progn
                  (setf (slot-value blackjack--game 'deck-type) deck-type)
                  (blackjack--shuffle-save-deal-new-hand)))))))

(dolist (face-type '(alternate regular))
  (let ((func-name (intern (format "blackjack--face-type-%s" face-type))))
    (fset func-name
          (lambda ()
            (interactive)
            (if (blackjack--valid-menu-action-p 'face-type)
                (progn
                  (setf (slot-value blackjack--game 'face-type) face-type)
                  (blackjack--save-deal-new-hand)))))))

(dolist (menu '(deck-type face-type))
  (let ((func-name (intern (format "blackjack--show-%s-menu" menu))))
    (fset func-name
          (lambda ()
            (interactive)
            (if (blackjack--valid-menu-action-p 'options)
                (progn
                  (setf (slot-value blackjack--game 'current-menu) menu)
                  (blackjack--update-header)))))))

(defun blackjack--save-deal-new-hand ()
  "Save game and deal new hand."
  (blackjack--save)
  (setf (slot-value blackjack--game 'current-menu) 'game)
  (blackjack--deal-new-hand))

(defun blackjack--shuffle-save-deal-new-hand ()
  "Shuffle, save, and deal new hand."
  (blackjack--shuffle)
  (blackjack--save-deal-new-hand))

(defvar blackjack-minor-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd blackjack-stand-key) 'blackjack--stand)
    (define-key map (kbd blackjack-deal-double-key) 'blackjack--handle-input-d)
    (define-key map (kbd blackjack-bet-back-key) 'blackjack--handle-input-b)
    (define-key map (kbd blackjack-quit-key) 'blackjack--quit)
    (define-key map (kbd blackjack-options-key) 'blackjack--show-options-menu)
    (define-key map (kbd blackjack-num-decks-no-insurance-key) 'blackjack--handle-input-n)
    (define-key map (kbd blackjack-deck-type-key) 'blackjack--show-deck-type-menu)
    (define-key map (kbd blackjack-face-type-key) 'blackjack--show-face-type-menu)
    (define-key map (kbd blackjack-hit-key) 'blackjack--hit)
    (define-key map (kbd blackjack-split-key) 'blackjack--split)
    (define-key map (kbd blackjack-deck-regular-key) 'blackjack--deck-type-regular)
    (define-key map (kbd blackjack-deck-aces-key) 'blackjack--deck-type-aces)
    (define-key map (kbd blackjack-deck-jacks-key) 'blackjack--deck-type-jacks)
    (define-key map (kbd blackjack-deck-aces-jacks-key) 'blackjack--deck-type-aces-jacks)
    (define-key map (kbd blackjack-deck-sevens-key) 'blackjack--deck-type-sevens)
    (define-key map (kbd blackjack-deck-eights-key) 'blackjack--deck-type-eights)
    (define-key map (kbd blackjack-insurance-key) 'blackjack--insure-hand)
    (define-key map (kbd blackjack-face-type-regular-key) 'blackjack--face-type-regular)
    (define-key map (kbd blackjack-face-type-alternate-key) 'blackjack--face-type-alternate)
    map)
  "Blackjack minor mode keymap.")

(define-minor-mode blackjack-minor-mode
  "Blackjack minor mode.

\\{blackjack-mode-map}"
  :group 'blackjack
  :lighter " blackjack")

(define-derived-mode blackjack-mode fundamental-mode "Blackjack"
  "Blackjack game mode."
  (read-only-mode))

(defun blackjack--init ()
  "Initialize game state."
  (setq blackjack--game (blackjack-game))
  (blackjack--load-saved-game)
  (blackjack--deal-new-hand))

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
