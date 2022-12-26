;;; digit-groups.el --- Highlight place-value positions in numbers

;; Author: Michael D. Adams <http://michaeldadams.org>
;; URL: https://github.com/adamsmd/digit-groups/
;; Package-Version: 20200506.37
;; Package-Commit: 7b81930cad19b8b7913b7eedbcb498964bfdcbdb
;; License: MIT
;; Version: 0.2
;; Package-Requires: ((dash "2.11.0"))

;; The MIT License (MIT)
;;
;; Copyright (C) 2016 Michael D. Adams
;;
;; Permission is hereby granted, free of charge, to any person obtaining a
;; copy of this software and associated documentation files (the "Software"),
;; to deal in the Software without restriction, including without limitation
;; the rights to use, copy, modify, merge, publish, distribute, sublicense,
;; and/or sell copies of the Software, and to permit persons to whom the
;; Software is furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be included in
;; all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
;; FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
;; AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
;; LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
;; FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
;; DEALINGS IN THE SOFTWARE.

;;; Commentary:
;; Highlight selected place-value positions in numbers.
;;
;; The `digit-groups` Emacs package adds the `digit-groups-mode`
;; minor mode, which makes it easier to read large numbers by
;; highlighting digits at selected place-value positions (e.g.,
;; thousands place, millions place, billions place, etc.).
;;
;; The default configuration formats in bold every other group of
;; three digits.  So, for example, in `9876543210.123456789`, the
;; digits 3, 4, 5 and 9 are highlighted both before and after the
;; decimal (`.`).  This makes it easy to find the place-value
;; positions for thousands, millions, billions, and so forth.
;;
;; To use this package, enable the `digit-groups-mode` minor mode in
;; the buffers in which you wish to use it, or to enable it for all
;; buffers, customize `digit-groups-global-mode` to `t`.
;;
;; The default configuration highlights digits by making them bold.
;; This can be changed by customizing `digit-groups-default-face`,
;; or you can highlight different positions with different faces by
;; customizing `digit-groups-groups`.
;;
;; The default configuration highlights every other group of three
;; digits between the novemdecillionths (10^-60) position and the
;; novemdecillions (10^60) position with the exception of the
;; units (10^0) position.  This can be changed by customizing
;; `digit-groups-groups`.
;;
;; Changes to the configuration take effect only when the
;; `digit-groups-mode` minor mode is being turned on.  Thus, you may
;; need to toggle the mode off and on again in affected buffers
;; before you see the effect of any configuration changes.

;;; Code:

(require 'dash)

;;; BEGIN CUSTOM VARIABLES

(defgroup digit-groups nil
  "Highlight selected place-value positions in numbers.

The `digit-groups` Emacs package adds the `digit-groups-mode`
minor mode, which makes it easier to read large numbers by
highlighting digits at selected place-value positions (e.g.,
thousands place, millions place, billions place, etc.).

The default configuration formats in bold every other group of
three digits.  So, for example, in `9876543210.123456789`, the
digits 3, 4, 5 and 9 are highlighted both before and after the
decimal (`.`).  This makes it easy to find the place-value
positions for thousands, millions, billions, and so forth.

To use this package, enable the `digit-groups-mode` minor mode in
the buffers in which you wish to use it, or to enable it for all
buffers, customize `digit-groups-global-mode` to `t`.

The default configuration highlights digits by making them bold.
This can be changed by customizing `digit-groups-default-face`,
or you can highlight different positions with different faces by
customizing `digit-groups-groups`.

The default configuration highlights every other group of three
digits between the novemdecillionths (10^-60) position and the
novemdecillions (10^60) position with the exception of the
units (10^0) position.  This can be changed by customizing
`digit-groups-groups`.

Changes to the configuration take effect only when the
`digit-groups-mode` minor mode is being turned on.  Thus, you may
need to toggle the mode off and on again in affected buffers
before you see the effect of any configuration changes."
  :group 'font-lock
  :package-version '(digit-groups . "0.2"))

(defface digit-groups-default-face '((t (:weight bold)))
  "Default face for highlighting digit groups."
  :group 'digit-groups)

(defcustom digit-groups-groups
  (--map (cons it 'digit-groups-default-face)
         (apply 'append
                (append
                 (--map (list (+ 5 (* 6 it)) (+ 4 (* 6 it)) (+ 3 (* 6 it)))
                        '(9 8 7 6 5 4 3 2 1 0))
                 (--map (list (+ 2 (* -6 it)) (+ 1 (* -6 it)) (+ 0 (* -6 it)))
                        '(1 2 3 4 5 6 7 8 9 10)))))
  "Positions of digits to highlight and the face with which to highlight them.
Use 0 for the one's digit, 1 for the ten's digit, 2 for the
hundred's digit, etc.  Use -1 for the tenth's digit, -2 for the
hundredth's digit, -3 for the thousandth's digit, etc."
  :type '(alist :key-type integer :value-type face)
  :group 'digit-groups)

(defcustom digit-groups-decimal-separator "\\."
  "Separator between integral and factional parts of a number.
Common values include `\\\\.`, `,`, and `\\\\.\\|,`."
  :type '(regexp)
  :group 'digit-groups)

(defcustom digit-groups-digits "[:digit:]"
  "What characters count as a digit.
Will be placed inside character-class brackets.  Must not start with `^`."
  :type '(string)
  :group 'digit-groups)

;;;###autoload
(define-global-minor-mode digit-groups-global-mode
  digit-groups-mode
  (lambda () (digit-groups-mode 1))
  :group 'digit-groups)

;;; END CUSTOM VARIABLES

;;;###autoload
(define-minor-mode digit-groups-mode
  "Minor mode that highlights selected place-value positions in numbers.
See the `digit-groups` customization group for more information."
  :group 'digit-groups
  (if digit-groups-mode
      (digit-groups--add-keywords)
    (digit-groups--remove-keywords))
  ;; As of Emacs 24.4, `font-lock-fontify-buffer' is not legal to
  ;; call, instead `font-lock-flush' should be used.
  (if (fboundp 'font-lock-flush)
      (font-lock-flush)
    (when font-lock-mode
      (with-no-warnings
        (font-lock-fontify-buffer)))))

(defun digit-groups--repeat-string (n s)
  "Concatenate N copies of S."
  (cond
   ((= 0 n) "")
   (t (concat s (digit-groups--repeat-string (- n 1) s)))))

(defun digit-groups--add-digits (n old)
  "Add a group of size N to OLD.
If N is non-negative, add a pre-decimal group.  Otherwise, add a post-decimal group."
  (let ((highlighted (concat "\\(" "[" digit-groups-digits "]" "\\)"))
        (non-highlighted (digit-groups--repeat-string
                          (- (abs n) 1) (concat "[" digit-groups-digits "]"))))
    (let ((group (if (>= n 0)
                     (concat highlighted non-highlighted)
                   (concat non-highlighted highlighted))))
      (if (string-equal "" old)
          group
        (if (>= n 0)
            (concat "\\(?:" old "\\)?" group)
          (concat group "\\(?:" old "\\)?"))))))

(defun digit-groups--make-group-regexp (positions)
  "Make a regexp to highlight characters at POSITIONS."
  (cond
   ((null positions)
    (error "Internal error in digit-groups: null argument to digit-groups--make-group-regexp"))
   ((null (cdr positions)) "")
   (t
    (digit-groups--add-digits
     (- (car (cdr positions)) (car positions))
     (digit-groups--make-group-regexp (cdr positions))))))

(defun digit-groups--make-keywords ()
  "Build the font-lock keywords for highlighting based on current customizations."
  (let* ((positions (mapcar 'car digit-groups-groups))
         (pos-positions (cons -1 (-sort '< (--filter (>= it 0) positions))))
         (neg-positions (cons  0 (-sort '> (--filter (<  it 0) positions)))))
    (let* ((pos-regexp (digit-groups--make-group-regexp pos-positions))
           (neg-regexp (digit-groups--make-group-regexp neg-positions))
           (decimal (concat "\\(?:" digit-groups-decimal-separator "\\)" ))
           (neg-regexp* (concat decimal neg-regexp "[" digit-groups-digits "]*")))
      (let ((regexp
             (concat
              "\\(?:" neg-regexp*
              "\\|" pos-regexp "\\(?:" neg-regexp* "\\)?"
              "\\)"
              "\\(?:" "[^" digit-groups-digits "]" "\\|" "\\'" "\\)")))
        (let* ((neg-groups (--filter (< 0 (car it)) digit-groups-groups))
               (faces
                (--map-indexed
                 (list (+ 1 it-index) (list 'quote (cdr it)) 'prepend t)
                 (append
                  (--sort (> (car it) (car other)) neg-groups)
                  (--sort (> (car it) (car other)) digit-groups-groups)))))
          (list (cons regexp faces)))))))

(defvar digit-groups--installed-keywords nil
  "If non-nil, the keywords added to `font-lock-keywords` by `digit-groups--add-keywords`.")
(make-variable-buffer-local 'digit-groups--installed-keywords)

(defun digit-groups--add-keywords ()
  "Add to `font-lock-keywords` to highlight digit groups in the current buffer."
  (unless (null digit-groups--installed-keywords)
    (digit-groups--remove-keywords))
  (let ((keywords (digit-groups--make-keywords)))
    (setq digit-groups--installed-keywords keywords)
    (font-lock-add-keywords nil keywords)))

(defun digit-groups--remove-keywords ()
  "Remove `font-lock-keywords` added by `digit-groups--add-keywords`."
  (interactive)
  (font-lock-remove-keywords nil digit-groups--installed-keywords)
  (setq digit-groups--installed-keywords nil))

(provide 'digit-groups)
;;; digit-groups.el ends here
