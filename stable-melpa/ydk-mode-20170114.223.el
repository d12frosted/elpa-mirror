;;; ydk-mode.el --- Language support for Yu-Gi-Oh! deck files

;; Copyright (C) 2017 Jackson Ray Hamilton

;; Author: Jackson Ray Hamilton <jackson@jacksonrayhamilton.com>
;; Version: 1.0.0
;; Package-Version: 20170114.223
;; Package-Commit: f3f125b29408e0b0a34fec27dcb7c02c5dbfd04e
;; Keywords: faces games languages ydk yugioh yu-gi-oh
;; URL: https://github.com/jacksonrayhamilton/ydk-mode

;; This program is free software: you can redistribute it and/or modify
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

;; Provides language support for Yu-Gi-Oh! deck files.  These typically have a
;; ".ydk" extension.  They are used in YGOPro and other dueling simulators.

;; YDK files consist of lists of newline-delimited integers.  These integers
;; correspond to the 8-digit "passcodes" unique to each card. (See
;; http://yugioh.wikia.com/wiki/Passcode for details.)  Each newline-delimited
;; integer represents one copy of a corresponding card in a deck.

;; Comments may appear anywhere in a file, starting with "#" or "!", followed by
;; (usually) arbitrary characters, ending with a newline.

;; There are three "magic" comments which typically denote the beginning of a
;; new deck (that is, the Main Deck, Extra Deck or Side Deck).  Conventionally,
;; these magic comments are of the forms:

;;     #main
;;     #extra
;;     !side

;; The magic comments are highlighted specially in this mode to make them more
;; distinguishable.

;; Putting it all together, a YDK file specifying a deck,

;; - created by someone named Jackson
;; - with the following cards in his Main Deck:
;;   - 3x Blue-Eyes White Dragon
;;   - 1x Lord of D.
;;   - 1x The Flute of Summoning Dragon
;; - and this card in his Extra Deck:
;;   - 1x Blue-Eyes Ultimate Dragon
;; - and this card in his Side Deck:
;;   - 1x Cipher Soldier

;; would look something like this:

;;     #created by Jackson
;;     #main
;;     89631139
;;     89631139
;;     89631139
;;     17985575
;;     43973174
;;     #extra
;;     23995346
;;     !side
;;     79853073

;; Also, YDK mode will calculate the total number of cards in the Main, Extra
;; and Side Decks (in that order), and display those totals in the modeline.
;; The above deck would have a modeline display of:

;;     (YDK[5/1/1])

;;; Code:

(defvar ydk-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?! "<" table)
    (modify-syntax-entry ?\n ">" table)
    table)
  "Syntax table to use in YDK mode.")

(defvar ydk-magic-comment-regexp
  "^\\(?:#\\|!\\)\\(main\\|extra\\|side\\)$"
  "Regexp for \"magic\" comments denoting the start of a deck.")

(defvar ydk-mode-font-lock-keywords
  `((,ydk-magic-comment-regexp 1 font-lock-warning-face prepend))
  "Highlighting keywords for YDK mode.")

(defvar ydk-passcode-regexp
  "[[:digit:]]+"
  "Regexp for a line with a passcode on it.")

(defun ydk-make-stats ()
  "Make a new stats alist."
  (list (cons 'main 0) (cons 'extra 0) (cons 'side 0)))

(defun ydk-stats ()
  "Get the number of cards in each deck in the current YDK buffer."
  (let ((stats (ydk-make-stats)) current)
    (save-excursion
      (goto-char (point-min))
      (while (> (point-max) (point))
        (when (looking-at ydk-magic-comment-regexp)
          ;; Set the deck whose total will be incremented.
          (setq current (intern (match-string 1))))
        (skip-syntax-forward " ")
        (when (and current (looking-at ydk-passcode-regexp))
          ;; Increment the total by one.
          (setcdr (assq current stats) (1+ (cdr (assq current stats)))))
        (forward-line 1)))
    stats))

(defun ydk-mode-update-mode-name ()
  "Update the modeline with the buffer's decks' totals."
  (let ((stats (ydk-stats)))
    (setq mode-name (format "YDK[%s/%s/%s]"
                            (cdr (assq 'main stats))
                            (cdr (assq 'extra stats))
                            (cdr (assq 'side stats))))))

(defun ydk-mode-change-function (_start _end _length)
  "Work for YDK mode whenever the buffer changes."
  (ydk-mode-update-mode-name))

;;;###autoload
(define-derived-mode ydk-mode text-mode "YDK"
  "Major mode for editing Yu-Gi-Oh! deck files."
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'font-lock-defaults) '(ydk-mode-font-lock-keywords))
  (add-hook 'after-change-functions #'ydk-mode-change-function nil t)
  (ydk-mode-update-mode-name))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.ydk\\'" . ydk-mode))

(provide 'ydk-mode)

;;; ydk-mode.el ends here
