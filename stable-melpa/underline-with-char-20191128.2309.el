;;; underline-with-char.el --- Underline with a char  -*- lexical-binding: t -*-

;; THIS FILE HAS BEEN GENERATED.

;; Copyright (C) 2017, 2019 Marco Wahl
;;
;; Version: 3.0.1
;; Package-Version: 20191128.2309
;; Package-Commit: 36577e72aa4fbfa7f1abad01842359209f543751
;; Package-Requires: ((emacs "24"))
;; Keywords: convenience
;; Maintainer: marcowahlsoft@gmail.com
;; URL: https://gitlab.com/marcowahl/underline-with-char

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>.

;; THIS FILE HAS BEEN GENERATED.


;;; Commentary:
;;
;; This program supports underlining with a certain character.
;;
;; When point is in an empty line then fill the line with a character
;; making it as long as the line above.
;;
;; This program provides just command `underline-with-char' and
;; variable `underline-with-char-fill-char'.

;; You can change the default underline character via
;;
;; M-x customize-variable underline-with-char-fill-char

;;

;; Examples
;; ========
;;
;; Notation:
;; - | means the cursor.
;; - RET means the return key.
;;

;; Full underlining
;; ................
;;
;; Input
;; _____
;;
;; lala
;; |
;;
;; Action
;; ______
;;
;; M-x underline-with-char RET
;;
;; Output
;; ______
;;
;; lala
;; ----|
;;

;; Partial underlining
;; ...................
;;
;; Input
;; _____
;;
;; lolololo
;; //|
;;
;; Action
;; ______
;;
;; M-x underline-with-char RET
;;
;; Output
;; ______
;;
;; lolololo
;; //------|
;;

;; Use a certain char for current and subsequent underlinings (1)
;; ..............................................................
;;
;; Input
;; _____
;;
;; lala
;; |
;;
;; Action
;; ______
;;
;; C-u M-x underline-with-char X RET
;;
;; Output
;; ______
;;
;; lala
;; XXXX|
;;

;; Use a certain char for current and subsequent underlinings (2)
;; ..............................................................
;;
;; Input
;; _____
;;
;; lala
;; |
;;
;; Action
;; ______
;;
;; C-u M-x underline-with-char X RET RET M-x underline-with-char RET
;;
;; Output
;; ______
;;
;; lala
;; XXXX
;; XXXX|


;;; Code:


(defcustom underline-with-char-fill-char ?-
  "The character for the underline."
  :group 'underline-with-char
  :type 'character)


;;;###autoload
(defun underline-with-char (arg)
  "Underline the line above with a certain character.

Fill what's remaining if not at the first position.

The default character is `underline-with-char-fill-char'.

With prefix ARG use the next entered character for this and
subsequent underlining.

Example with `underline-with-char-fill-char' set to '-' and point
symbolized as |.

;; Commentary:
;; |

    M-x underline-with-char RET

yields

;; Commentary:
;; -----------|"
  (interactive "P")
  (when (equal '(4) arg)
    (setq underline-with-char-fill-char (read-char "char: ")))
  (insert
   (make-string
    (save-excursion
      (let ((col (current-column)))
        (forward-line -1)
        (end-of-line)
        (max 0 (- (current-column) col))))
    underline-with-char-fill-char)))


(provide 'underline-with-char)


;;; underline-with-char.el ends here
