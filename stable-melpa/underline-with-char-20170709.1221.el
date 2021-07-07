;;; underline-with-char.el --- Underline with a char  -*- lexical-binding: t ; eval: (view-mode 1) -*-

;; THIS FILE HAS BEEN GENERATED.

;; Program
;; :PROPERTIES:
;; :ID:       17c5897e-3413-4576-aa83-3869e0cb1053
;; :END:


;; [[file:~/p/elisp/mw/underline-with-char/underline-with-char.org::*Program][Program:1]]
;; THIS FILE HAS BEEN GENERATED.


;;; Commentary:

;; Version: 3.0.0
;; Package-Version: 20170709.1221
;; Package-Commit: c2f4870aff70efe70a8d1b089e56d3a2d6d048b9
;; Package-Requires: ((emacs "24"))
;; Keywords: convenience

;; When point is in an empty line then fill the line with a character
;; making it as long as the line above.

;; This program provides just command =underline-with-char=.

;; Examples
;; ========

;; Notation: <!> means point.
;;
;; Full underlining
;; ................
;;
;; Input:
;; ^^^^^^

;; #+begin_src text
;; lala
;; <!>
;; #+end_src
;;
;; Action:
;; ^^^^^^^

;; #+begin_src text
;; M-x underline-with-char
;; #+end_src
;;
;; Output:
;; ^^^^^^^

;; #+begin_src text
;; lala
;; ----<!>
;; #+end_src
;;
;; Partial underlining
;; ...................

;; Input:
;; ^^^^^^

;; #+begin_src text
;; ;; lolo
;; ;; <!>
;; #+end_src
;;
;; Action:
;; ^^^^^^^

;; #+begin_src text
;; M-x underline-with-char
;; #+end_src
;;
;; Output:
;; ^^^^^^^

;; #+begin_src text
;; ;; lolo
;; ;; ----<!>
;; #+end_src
;;
;; Use a certain char for current and subsequent underlinings
;; ..........................................................
;;
;; Input:
;; ^^^^^^

;; #+begin_src text
;; lala
;; <!>
;; #+end_src
;;
;; Action:
;; ^^^^^^^

;; #+begin_src text
;; C-u M-x underline-with-char X
;; #+end_src
;;
;; Output:
;; ^^^^^^^

;; #+begin_src text
;; lala
;; XXXX<!>
;; #+end_src
;;
;; Change the buffer.  Example:
;; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;; #+begin_src text
;; lala
;; XXXX
;;
;; ;; Worthy to be underlined
;; ;; <!>
;; #+end_src
;;
;; Go on without prefix argument (C-u):
;; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

;; #+begin_src text
;; M-x underline-with-char X
;; #+end_src
;;
;; Output:
;; ^^^^^^^

;; #+begin_src text
;; lala
;; XXXX
;;
;; ;; Worthy to be underlined
;; ;; XXXXXXXXXXXXXXXXXXXXXXX<!>
;; #+end_src


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
symbolized as <!> and starting with

;; Commentary:
;; <!>

get

;; Commentary:
;; -----------"
  (interactive "P")
  (when (equal '(4) arg)
    (setq underline-with-char-fill-char (read-char "char: ")))
  (insert
   (make-string
    (save-excursion
      (let ((col (current-column)))
        (forward-line -1)
        (end-of-line)
        (when (< col (current-column))
          (beginning-of-line)
          (forward-char col)))
      (let ((old-point (point)))
        (- (progn (end-of-line) (point)) old-point)))
        underline-with-char-fill-char)))


(provide 'underline-with-char)
;; Program:1 ends here


;;; underline-with-char.el ends here
