;;; blackjack.el --- The game of Blackjack -*- lexical-binding: t; -*-

;; Copyright (C) 2022, 2023 Greg Donald
;; SPDX-License-Identifier: GPL-3.0-only
;; Author: Greg Donald <gdonald@gmail.com>
;; Version: 1.0.3
;; Package-Version: 20230507.2321
;; Package-Commit: 81fb684c10f614a0662a207edb845640bf5c0e7c
;; Package-Requires: ((emacs "26.2"))
;; Keywords: card game games blackjack 21
;; URL: https://github.com/gdonald/blackjack-el

;;; Commentary:
;; This package lets you play Blackjack in Emacs.

;;; Code:

(require 'cl-lib)
(require 'eieio)

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
   (max-player-hands :initarg :max-player-hands :initform 7 :type integer)
   (quitting :initarg :quitting :initform nil :type boolean)))

(defun blackjack--deal-new-hand (game)
  "Deal new GAME hands."
  (interactive)
  (if (blackjack--valid-menu-action-p game 'game)
      (progn
        (if (blackjack--need-to-shuffle-p game)
            (blackjack--shuffle game))
        (let (player-hand dealer-hand)
          (setf (slot-value game 'player-hands) '())
          (setq player-hand (blackjack-player-hand :id (blackjack--next-id game) :bet (slot-value game 'current-bet)))
          (setq dealer-hand (blackjack-dealer-hand))
          (dotimes (_x 2)
            (blackjack--deal-card game player-hand)
            (blackjack--deal-card game dealer-hand))
          (push player-hand (slot-value game 'player-hands))
          (setf (slot-value game 'current-player-hand) 0)
          (setf (slot-value game 'dealer-hand) dealer-hand)
          (if (and
               (blackjack--dealer-upcard-is-ace-p dealer-hand)
               (not (blackjack--hand-is-blackjack-p (slot-value player-hand 'cards))))
              (progn
                (setf (slot-value game 'current-menu) 'insurance)
                (blackjack--draw-hands game)
                (blackjack--ask-insurance-action game))
            (if (blackjack--player-hand-done-p game player-hand)
                (progn
                  (setf (slot-value dealer-hand 'hide-down-card) nil)
                  (blackjack--pay-hands game)
                  (setf (slot-value game 'current-menu) 'game)
                  (blackjack--draw-hands game)
                  (blackjack--ask-game-action game))
              (setf (slot-value game 'current-menu) 'hand)
              (blackjack--draw-hands game)
              (blackjack--save game)
              (blackjack--ask-hand-action game)))))))

(defun blackjack--deal-card (game hand)
  "Deal a card into HAND from GAME shoe."
  (interactive)
  (let ((shoe (slot-value game 'shoe))
        (cards (slot-value hand 'cards))
        (card))
    (setq card (car shoe))
    (setq cards (reverse cards))
    (push card cards)
    (setq cards (reverse cards))
    (setq shoe (cl-remove card shoe :count 1))
    (setf (slot-value hand 'cards) cards)
    (setf (slot-value game 'shoe) shoe)))

(defun blackjack--next-id (game)
  "Return next GAME object id."
  (let ((id (slot-value game 'id)))
    (setf (slot-value game 'id) (1+ id))))

(defun blackjack--pay-hands (game)
  "Pay player GAME hands."
  (let* ((dealer-hand (slot-value game 'dealer-hand))
         (dealer-hand-value (blackjack--dealer-hand-value dealer-hand 'soft))
         (dealer-busted (blackjack--dealer-hand-is-busted-p dealer-hand))
         (player-hands (slot-value game 'player-hands)))
    (dotimes (x (length player-hands))
      (blackjack--pay-player-hand game (nth x player-hands) dealer-hand-value dealer-busted))
    (blackjack--normalize-current-bet game)
    (blackjack--save game)))

(defun blackjack--pay-player-hand (game player-hand dealer-hand-value dealer-hand-busted)
  "Pay GAME PLAYER-HAND based on DEALER-HAND-VALUE and DEALER-HAND-BUSTED."
  (if (not (slot-value player-hand 'payed))
      (progn
        (setf (slot-value player-hand 'payed) t)
        (let (player-hand-value)
          (setq player-hand-value (blackjack--player-hand-value (slot-value player-hand 'cards) 'soft))
          (if (blackjack--player-hand-won player-hand-value dealer-hand-value dealer-hand-busted)
              (blackjack--pay-won-hand game player-hand)
            (if (blackjack--player-hand-lost-p player-hand-value dealer-hand-value)
                (blackjack--collect-lost-hand game player-hand)
              (setf (slot-value player-hand 'status) 'push)))))))

(defun blackjack--collect-lost-hand (game player-hand)
  "Collect bet from losing GAME PLAYER-HAND."
  (setf (slot-value game 'money) (- (slot-value game 'money) (slot-value player-hand 'bet))
        (slot-value player-hand 'status) 'lost))

(defun blackjack--pay-won-hand (game player-hand)
  "Pay winning GAME PLAYER-HAND bet."
  (let ((bet (slot-value player-hand 'bet)))
    (if (blackjack--hand-is-blackjack-p (slot-value player-hand 'cards))
        (setf bet (truncate (* 1.5 bet))))
    (setf (slot-value game 'money) (+ (slot-value game 'money) bet)
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

(defun blackjack--player-hand-done-p (game player-hand)
  "Return non-nil when GAME PLAYER-HAND is done."
  (if (not (blackjack--no-more-actions-p player-hand))
      nil
    (setf (slot-value player-hand 'played) t)
    (if (and
         (not (slot-value player-hand 'payed))
         (blackjack--player-hand-is-busted-p (slot-value player-hand 'cards)))
        (blackjack--collect-busted-hand game player-hand))
    t))

(defun blackjack--collect-busted-hand (game player-hand)
  "Collect bet from GAME PLAYER-HAND."
  (setf (slot-value player-hand 'payed) t
        (slot-value player-hand 'status) 'lost
        (slot-value game 'money) (- (slot-value game 'money)
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

(defun blackjack--need-to-shuffle-p (game)
  "Return non-nil when GAME shoe is exhausted."
  (let* ((shoe (slot-value game 'shoe))
         (cards-count (length shoe)))
    (if (> cards-count 0)
        (progn
          (let ((used (- (blackjack--total-cards game) cards-count))
                (spec (aref (slot-value game 'shuffle-specs) (1- (slot-value game 'num-decks)))))
            (> (* 100 (/ (float used) cards-count)) spec)))
      t)))

(defun blackjack--total-cards (game)
  "Return total number of cards per GAME shoe."
  (* (slot-value game 'cards-per-deck) (slot-value game 'num-decks)))

(defun blackjack--shuffle (game)
  "Fill a new GAME shoe with cards."
  (let ((total-cards (blackjack--total-cards game))
        (shoe '())
        (values '()))
    (setq values
          (pcase (slot-value game 'deck-type)
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
              (setq shoe (cons (blackjack-card :id (blackjack--next-id game) :value value :suit suit) shoe))))))
    (setf (slot-value game 'shoe) (blackjack--shuffle-loop shoe))))

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
  (format "%.2f" money))

(defun blackjack--more-hands-to-play-p (game)
  "Return non-nil when there are more split GAME hands to play."
  (let ((current-player-hand (slot-value game 'current-player-hand))
        (player-hands (slot-value game 'player-hands)))
    (< current-player-hand (1- (length player-hands)))))

(defun blackjack--play-more-hands (game)
  "Advance to next split GAME player hand."
  (let (player-hand)
    (setf (slot-value game 'current-player-hand) (1+ (slot-value game 'current-player-hand)))
    (setq player-hand (blackjack--current-player-hand game))
    (blackjack--deal-card game player-hand)
    (if (blackjack--player-hand-done-p game player-hand)
        (blackjack--process game)
      (setf (slot-value game 'current-menu) 'hand)
      (blackjack--draw-hands game)
      (blackjack--ask-hand-action game))))

(defun blackjack--need-to-play-dealer-hand-p (game)
  "Return non-nil when playing the GAME dealer hand is required."
  (let ((player-hands (slot-value game 'player-hands)))
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

(defun blackjack--deal-required-cards (game)
  "Deal GAME dealer-hand required cards."
  (let* ((dealer-hand (slot-value game 'dealer-hand))
         (counts (blackjack--dealer-hand-counts dealer-hand)))
    (while
        (and
         (< (nth 0 counts) 18)
         (< (nth 1 counts) 17))
      (blackjack--deal-card game dealer-hand)
      (setq counts (blackjack--dealer-hand-counts dealer-hand)))))

(defun blackjack--play-dealer-hand (game)
  "Player GAME dealer hand."
  (let* ((playing (blackjack--need-to-play-dealer-hand-p game))
         (dealer-hand (slot-value game 'dealer-hand))
         (cards (slot-value dealer-hand 'cards)))
    (if
        (or
         playing
         (blackjack--hand-is-blackjack-p cards))
        (setf (slot-value dealer-hand 'hide-down-card) nil))
    (if playing
        (blackjack--deal-required-cards game))
    (setf (slot-value dealer-hand 'played) t)
    (blackjack--pay-hands game)
    (setf (slot-value game 'current-menu) 'game)
    (blackjack--draw-hands game)
    (blackjack--ask-game-action game)))

(defun blackjack--process (game)
  "Handle more split GAME hands to play."
  (if (blackjack--more-hands-to-play-p game)
      (blackjack--play-more-hands game)
    (blackjack--play-dealer-hand game)))

(defun blackjack--hit (game)
  "Deal a new card to the current GAME player hand."
  (interactive)
  (if (blackjack--valid-hand-action-p game 'hit)
      (let ((player-hand (blackjack--current-player-hand game)))
        (blackjack--deal-card game player-hand)
        (if (blackjack--player-hand-done-p game player-hand)
            (blackjack--process game)
          (setf (slot-value game 'current-menu) 'hand)
          (blackjack--draw-hands game)
          (blackjack--ask-hand-action game)))))

(defun blackjack--double (game)
  "Double the current GAME player hand bet and deal a single card."
  (interactive)
  (if (blackjack--valid-hand-action-p game 'double)
      (let ((player-hand (blackjack--current-player-hand game)))
        (blackjack--deal-card game player-hand)
        (setf (slot-value player-hand 'played) t
              (slot-value player-hand 'bet) (* 2 (slot-value player-hand 'bet)))
        (if (blackjack--player-hand-done-p game player-hand)
            (blackjack--process game)
          (blackjack--ask-hand-action game)))))

(defun blackjack--stand (game)
  "End the current GAME player hand."
  (interactive)
  (if (blackjack--valid-hand-action-p game 'stand)
      (let ((player-hand (blackjack--current-player-hand game)))
        (setf (slot-value player-hand 'stood) t
              (slot-value player-hand 'played) t)
        (blackjack--process game))))

(defun blackjack--split (game)
  "Split the current GAME player hand."
  (interactive)
  (if (blackjack--valid-hand-action-p game 'split)
      (let ((player-hands (slot-value game 'player-hands))
            (player-hand) (card) (hand) (x 0))
        (setq hand (blackjack-player-hand :id (blackjack--next-id game) :bet (slot-value game 'current-bet)))
        (setq player-hands (reverse player-hands))
        (push hand player-hands)
        (setq player-hands (reverse player-hands))
        (setf (slot-value game 'player-hands) player-hands)
        (setq x (1- (length player-hands)))
        (while (> x (slot-value game 'current-player-hand))
          (setq player-hand (nth (1- x) player-hands))
          (setq hand (nth x player-hands))
          (setf (slot-value hand 'cards) (slot-value player-hand 'cards))
          (setq x (1- x)))
        (setq player-hand (nth (slot-value game 'current-player-hand) player-hands))
        (setq hand (nth (1+ (slot-value game 'current-player-hand)) player-hands))
        (setf (slot-value hand 'cards) '())
        (setq card (nth 1 (slot-value player-hand 'cards)))
        (push card (slot-value hand 'cards))
        (setf (slot-value player-hand 'cards) (cl-remove card (slot-value player-hand 'cards) :count 1))
        (blackjack--deal-card game player-hand)
        (if (blackjack--player-hand-done-p game player-hand)
            (blackjack--process game)
          (setf (slot-value game 'current-menu) 'hand)
          (blackjack--draw-hands game)
          (blackjack--ask-hand-action game)))))

(defun blackjack--valid-menu-action-p (game action)
  "Return non-nil if the GAME menu ACTION can be performed."
  (eq (slot-value game 'current-menu) action))

(defun blackjack--valid-hand-action-p (game action)
  "Return non-nil if the GAME hand ACTION can be performed."
  (let* ((player-hand (blackjack--current-player-hand game))
         (cards (slot-value player-hand 'cards))
         (card-0 (nth 0 cards))
         (card-1 (nth 1 cards)))
    (if (blackjack--valid-menu-action-p game 'hand)
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
            (< (length (slot-value game 'player-hands)) 7)
            (>= (slot-value game 'money) (+ (blackjack--all-bets game) (slot-value player-hand 'bet)))
            (eq (length cards) 2)
            (eq (slot-value card-0 'value) (slot-value card-1 'value))))
          ('double
           (and
            (>= (slot-value game 'money) (+ (blackjack--all-bets game) (slot-value player-hand 'bet)))
            (not (or (slot-value player-hand 'stood) (not (eq 2 (length cards)))
                     (blackjack--hand-is-blackjack-p cards)))))))))

(defun blackjack--current-player-hand (game)
  "Return current GAME player hand."
  (nth (slot-value game 'current-player-hand) (slot-value game 'player-hands)))

(defun blackjack--all-bets (game)
  "Return the sum of all GAME player hand bets."
  (let ((player-hands (slot-value game 'player-hands))
        (total 0))
    (dotimes (x (length player-hands))
      (setq total (+ total (slot-value (nth x player-hands) 'bet))))
    total))

(defun blackjack--insure-hand (game)
  "Insure the current GAME player hand."
  (interactive)
  (let* ((player-hand (blackjack--current-player-hand game))
         (bet (slot-value player-hand 'bet))
         (new-bet (/ bet 2))
         (money (slot-value game 'money)))
    (if (blackjack--valid-menu-action-p game 'insurance)
        (progn
          (setf (slot-value player-hand 'bet) new-bet
                (slot-value player-hand 'played) t
                (slot-value player-hand 'payed) t
                (slot-value player-hand 'status) 'lost
                (slot-value game 'money) (- money new-bet))
          (setf (slot-value game 'current-menu) 'game)
          (blackjack--draw-hands game)
          (blackjack--ask-game-action game)))))

(defun blackjack--no-insurance (game)
  "Decline GAME player hand insurance."
  (interactive)
  (let* ((dealer-hand (slot-value game 'dealer-hand))
         (dealer-hand-cards (slot-value dealer-hand 'cards)))
    (if (blackjack--valid-menu-action-p game 'insurance)
        (if (blackjack--hand-is-blackjack-p dealer-hand-cards)
            (progn
              (setf (slot-value dealer-hand 'hide-down-card) nil)
              (blackjack--pay-hands game)
              (setf (slot-value game 'current-menu) 'game)
              (blackjack--draw-hands game))
          (let ((player-hand (blackjack--current-player-hand game)))
            (if (blackjack--player-hand-done-p game player-hand)
                (blackjack--play-dealer-hand game)
              (setf (slot-value game 'current-menu) 'hand)
              (blackjack--draw-hands game)
              (blackjack--ask-hand-action game)))))))

(defun blackjack--ask-new-bet (game)
  "Update the current GAME player bet."
  (interactive)
  (if (blackjack--valid-menu-action-p game 'game)
      (let ((answer (blackjack--new-bet-menu))
            (bet 0))
        (progn
          (setq bet (* 100 (string-to-number answer)))
          (setf (slot-value game 'current-bet) bet)
          (blackjack--normalize-current-bet game)
          (blackjack--save game)
          (setf (slot-value game 'current-menu) 'game)
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

(defun blackjack--draw-dealer-hand (game)
  "Draw the GAME dealer-hand."
  (let* ((dealer-hand (slot-value game 'dealer-hand))
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
      (insert (blackjack--card-face game value suit))
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

(defun blackjack--draw-player-hands (game)
  "Draw GAME players hands."
  (let ((player-hands (slot-value game 'player-hands))
        (player-hand))
    (dotimes (x (length player-hands))
      (setq player-hand (nth x player-hands))
      (blackjack--draw-player-hand game player-hand x))))

(defun blackjack--draw-player-hand (game player-hand index)
  "Draw the GAME PLAYER-HAND using an INDEX."
  (insert (blackjack--player-hand-cards game player-hand))
  (insert (blackjack--player-hand-money game player-hand index))
  (insert (blackjack--player-hand-status player-hand))
  (insert "\n\n"))

(defun blackjack--player-hand-cards (game player-hand)
  "Draw GAME PLAYER-HAND cards."
  (let ((cards (slot-value player-hand 'cards))
        (card) (suit) (value) (out "  "))
    (dotimes (x (length cards))
      (setq card (nth x cards))
      (setq value (slot-value card 'value))
      (setq suit (slot-value card 'suit))
      (setq out (concat out (blackjack--card-face game value suit)))
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

(defun blackjack--player-hand-money (game player-hand index)
  "Return GAME PLAYER-HAND money using an INDEX."
  (let ((current-hand (slot-value game 'current-player-hand))
        (played (slot-value player-hand 'played))
        (status (slot-value player-hand 'status))
        (bet (slot-value player-hand 'bet))
        (out ""))
    (if (equal status 'lost)
        (setq out (concat out "-")))
    (if (equal status 'won)
        (setq out (concat out "+")))
    (setq out
          (concat out blackjack-currency (blackjack--format-money (/ bet 100.0))))
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

(defun blackjack--card-face (game value suit)
  "Return GAME card face based on VALUE and SUIT."
  (let (face)
    (if (eq (slot-value game 'face-type) 'alternate)
        (setq face (slot-value game 'faces-alternate))
      (setq face (slot-value game 'faces-regular)))
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
    (if (< current-bet min-bet)
        (setq current-bet min-bet))
    (if (> current-bet max-bet)
        (setq current-bet max-bet))
    (if (> current-bet money)
        (setq current-bet money))
    (setf (slot-value game 'current-bet) current-bet)))

(defun blackjack--persist-file-name ()
  "Resolve the persist file including all abbreviations and symlinks."
  (file-truename (expand-file-name blackjack-persist-file)))

(defun blackjack--load-saved-game (game)
  "Load persisted GAME state."
  (let (content parts)
    (ignore-errors
      (with-temp-buffer
        (insert-file-contents-literally (blackjack--persist-file-name))
        (setq content (buffer-string))))
    (if content
        (setq parts (split-string content "|")))
    (if (= (length parts) 5)
        (setf (slot-value game 'num-decks) (string-to-number (nth 0 parts))
              (slot-value game 'deck-type) (intern (nth 1 parts))
              (slot-value game 'face-type) (intern (nth 2 parts))
              (slot-value game 'money) (string-to-number (nth 3 parts))
              (slot-value game 'current-bet) (string-to-number (nth 4 parts))))))

(defun blackjack--save (game)
  "Persist GAME state."
  (ignore-errors
    (with-temp-file (blackjack--persist-file-name)
      (insert (format "%s|%s|%s|%s|%s"
                      (slot-value game 'num-decks)
                      (slot-value game 'deck-type)
                      (slot-value game 'face-type)
                      (slot-value game 'money)
                      (slot-value game 'current-bet))))))

(defun blackjack--quit (game)
  "Quit Blackjack GAME."
  (interactive)
  (if (blackjack--valid-menu-action-p game 'game)
      (progn
        (setf (slot-value game 'quitting) t)
        (quit-window))))

(defun blackjack--header (game)
  "Return GAME header."
  (let ((money (slot-value game 'money))
        (menu (slot-value game 'current-menu))
        (out ""))
    (setq out
          (format "  Blackjack %s%s  "
                  blackjack-currency
                  (blackjack--format-money (/ money 100.0))))
    (setq out (concat out
                      (pcase menu
                        ('game (blackjack--game-header-menu))
                        ('hand (blackjack--hand-menu game))
                        ('options (blackjack--options-header-menu))
                        ('deck-type (blackjack--deck-type-header-menu))
                        ('face-type (blackjack--face-type-header-menu))
                        ('num-decks (blackjack--num-decks-header-menu))
                        ('bet (blackjack--bet-menu))
                        ('insurance (blackjack--insurance-header-menu)))))
    out))

(defun blackjack--update-header (game)
  "Update GAME header."
  (let ((header (blackjack--header game)))
    (setq header-line-format header)))

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
  (let* ((answer (blackjack-game-actions-menu)))
    (pcase answer
      ("deal" nil)
      ("bet" (blackjack--ask-new-bet game))
      ("options" (blackjack--ask-game-options game))
      ("quit" (blackjack--quit game)))))

(defun blackjack-game-actions-menu ()
  "Bet actions menu for GAME."
  (let* ((read-answer-short t))
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
    (read-answer "Options: "
                 `(("number-decks" ,blackjack-num-decks-no-insurance-key "change number of decks")
                   ("deck-type" ,blackjack-deck-type-key "change the deck type")
                   ("face-type" ,blackjack-face-type-key "change the card face type")
                   ("back" ,blackjack-bet-back-key "go back to previous menu")
                   ("help" ?? "show help")))))

(defun blackjack--deck-type-header-menu ()
  "Return deck type menu string."
  (format "(%s) regular  (%s) aces  (%s) jacks  (%s) aces & jacks  (%s) sevens  (%s) eights"
          blackjack-deck-regular-key
          blackjack-deck-aces-key
          blackjack-deck-jacks-key
          blackjack-deck-aces-jacks-key
          blackjack-deck-sevens-key
          blackjack-deck-eights-key))

(defun blackjack--ask-new-deck-type (game)
  "Ask for new GAME deck type."
  (setf (slot-value game 'current-menu) 'deck-type)
  (blackjack--update-header game)
  (let* ((answer (blackjack-deck-type-menu))
	 (deck-type (intern answer)))
    (setf (slot-value game 'deck-type) deck-type)
    (blackjack--shuffle-save-deal-new-hand game)))

(defun blackjack-deck-type-menu ()
  "New GAME deck type menu."
  (let* ((read-answer-short t))
    (read-answer "Deck Type: "
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
  (setf (slot-value game 'current-menu) 'face-type)
  (blackjack--update-header game)
  (let* ((answer (blackjack--face-type-menu))
	 (face-type (intern answer)))
    (setf (slot-value game 'face-type) face-type)
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
  (let* ((answer (blackjack--ask-insurance-menu)))
    (pcase answer
      ("yes" (blackjack--insure-hand game))
      ("no" (blackjack--no-insurance game))
      ("help" ?? "show help"))))

(defun blackjack--ask-insurance-menu ()
  "Ask about insuring GAME hand."
  (let ((read-answer-short t))
    (read-answer "Hand Insurance: "
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
    (if (blackjack--valid-hand-action-p game 'double)
        (push (format "(%s) double" blackjack-deal-double-key) options))
    (if (blackjack--valid-hand-action-p game 'split)
        (push (format "(%s) split" blackjack-split-key) options))
    (if (blackjack--valid-hand-action-p game 'stand)
        (push (format "(%s) stand" blackjack-stand-key) options))
    (if (blackjack--valid-hand-action-p game 'hit)
        (push (format "(%s) hit" blackjack-hit-key) options))
    (mapconcat #'identity options "  ")))

(defun blackjack--ask-hand-action (game)
  "Ask hand action for GAME."
  (let* ((answer (blackjack--hand-actions-menu game)))
    (pcase answer
      ("stand" (if (blackjack--valid-hand-action-p game 'stand)
		   (blackjack--stand game)
		 (blackjack--ask-hand-action game)))
      ("hit" (if (blackjack--valid-hand-action-p game 'hit)
		 (blackjack--hit game)
	       (blackjack--ask-hand-action game)))
      ("split" (if (blackjack--valid-hand-action-p game 'split)
		   (blackjack--split game)
		 (blackjack--ask-hand-action game)))
      ("double" (if (blackjack--valid-hand-action-p game 'double)
		    (blackjack--double game)
		  (blackjack--ask-hand-action game))))))

(defun blackjack--hand-actions-menu (game)
  "Hand actions menu for GAME."
  (let ((read-answer-short t)
	(actions '(("help" ?? "show help"))))
    (if (blackjack--valid-hand-action-p game 'double)
        (setf actions (cons `("double" ,blackjack-deal-double-key "double bet, deal a new card, and end hand") actions)))
    (if (blackjack--valid-hand-action-p game 'split)
        (setf actions (cons `("split" ,blackjack-split-key "split hand into two hands") actions)))
    (if (blackjack--valid-hand-action-p game 'stand)
        (setf actions (cons `("stand" ,blackjack-stand-key "end current hand with no further actions") actions)))
    (if (blackjack--valid-hand-action-p game 'hit)
        (setf actions (cons `("hit" ,blackjack-hit-key "deal a new card") actions)))
    (read-answer "Hand Action " actions)))

(defun blackjack--show-options-menu (game)
  "Switch to GAME options menu."
  (interactive)
  (if (blackjack--valid-menu-action-p game 'game)
      (progn
        (setf (slot-value game 'current-menu) 'options)
        (blackjack--update-header game)
        (blackjack--ask-game-options game))))

(defun blackjack--show-num-decks-menu (game)
  "Switch to GAME number of decks menu."
  (setf (slot-value game 'current-menu) 'num-decks)
  (blackjack--update-header game)
  (blackjack--ask-new-number-decks game))

(defun blackjack--ask-new-number-decks (game)
  "Get new number of GAME decks."
  (setf (slot-value game 'current-menu) 'num-decks)
  (blackjack--update-header game)
  (let ((answer (blackjack--new-number-decks-prompt))
        (num-decks 1))
    (setq num-decks (string-to-number answer))
    (if (< num-decks 1)
        (setq num-decks 1))
    (if (> num-decks 8)
        (setq num-decks 8))
    (setf (slot-value game 'num-decks) num-decks)
    (blackjack--save game)
    (blackjack--shuffle game)
    (setf (slot-value game 'current-menu) 'game)
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
            (if (blackjack--valid-menu-action-p game 'options)
                (progn
                  (setf (slot-value game 'current-menu) menu)
                  (blackjack--update-header game)
                  (funcall (intern (format "blackjack--ask-%s-action" menu)))))))))

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
