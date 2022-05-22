;;; sentence-navigation.el --- Commands to navigate one-spaced sentences. -*- lexical-binding: t -*-

;; Author: Fox Kiester <noct@openmailbox.org>
;; URL: https://github.com/noctuid/emacs-sentence-navigation
;; Package-Version: 20220522.1137
;; Package-Commit: ea6e94a5518643acda5b6e98e4e7f47dfc107d29
;; Keywords: sentence evil
;; Package-Requires: ((ample-regexps "0.1") (cl-lib "0.5") (emacs "24.4"))
;; Version: 0.1

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; This package gives commands for sentence navigation and manipulation
;; that ignore abbreviations. For example, in a sentence that contains
;; "Mr. MacGyver", "MacGyver" will not be considered to be the start of
;; a sentence. One-spaced sentences are the target of this plugin, but
;; it will also work properly with two-spaced sentences.

;; This package is inspired by vim-textobj-sentence and uses a modified
;; version of its default regex list. Evil is an optional dependency
;; that is used for the text objects this package provides.

;; For more information see the README in the github repo.

;;; Code:
(eval-and-compile (require 'ample-regexps))
(require 'cl-lib)

(defgroup sentence-navigation nil
  "Gives commands for navigating sentences and sentence text objects."
  :group 'editing
  :prefix "sentence-nav-")

(defcustom sentence-nav-abbreviation-list
  '("[ABCDIMPSUabcdegimpsv]"
    "l[ab]" "[eRr]d" "Ph" "[Ccp]l" "[Ll]n" "[c]o"
    "[Oe]p" "[DJMSh]r" "[MVv]s" "[CFMPScfpw]t"
    "alt" "[Ee]tc" "div" "es[pt]" "[Ll]td" "min"
    "[MD]rs" "[Aa]pt" "[Aa]ve?" "[Ss]tr?" "e\\.g"
    "[Aa]ssn" "[Bb]lvd" "[Dd]ept" "incl" "Inst" "Prof" "Univ")
  "List containing abbreviations that should be ignored."
  :group 'sentence-navigation
  :type '(repeat :tag "Abbreviations" regexp))

(defcustom sentence-nav-jump-to-syntax t
  "When non-nil, jump to quotes or other markup syntax around sentences.
Otherwise the jump commands will always jump to the capital letter or period."
  :group 'sentence-navigation
  :type 'boolean)

(defcustom sentence-nav-syntax-text-objects nil
  "When non-nil, the behavior of text objects will be based around syntax.
The inner text object will exclude any quotes or syntax while the outer text
object will include any quotes or syntax. This option is only useful for evil
users."
  :group 'sentence-navigation
  :type 'boolean)

(defcustom sentence-nav-hard-wrapping nil
  "When nil, a line that begins with a capital letter will always be considered
to be the start of a sentence. This will not cause a problem for soft-wrapped
for sentences, but for hard-wrapped sentences, the provided commands will not be
able to distinguish between a sentence that starts at the beginning of a line
and a capitalized word (such as a name) at the beginning of the line.

When non-nil, the provided commands will work correctly for both soft-wrapped
and hard-wrapped sentences provided that `sentence-nav-non-sentence-line-alist'
is properly customized for the current major mode. A capital letter at the
beginning of a line will only be considered to be the start of the sentence if
the previous line is a newline, ends with a sentence end, or matches one of the
regexps for the current major mode in `sentence-nav-non-sentence-line-alist'."
  :group 'sentence-navigation
  :type 'boolean)

(defvar sentence-nav-non-sentence-line-alist
  '((org-mode . ("^\\*+ " "^[[:blank:]]*#\\+end_src[[:blank:]]*$")))
  "An alist of `major-mode' to a list of regexps.
Each regexp describes a line that is not a sentence but can directly precede
one. For example, one of the default regexps is for an org heading. This regexp
lets this package know that if there is a capital letter on a line following an
org heading, it can be assumed that the capital letter starts a sentence. This
means checking the previous line for a sentence ending character won't be
necessary.

Note that this variable is only used when `sentence-nav-hard-wrapping' is
non-nil.")

;; TODO unfortunately \\s$ and similar don't work in org
(define-arx sentence-nav--rx
  '((left-quote (in "\"“`'«»‹›„‚"))
    (right-quote (in "\"”`'«»‹›“‘"))
    ;; characters that can be used for italic, literal, etc. in markdown and org
    (left-markup-char (in "*+/~=_["))
    (right-markup-char (in "*+/~=_]"))
    (left-bracket (in "("))
    (right-bracket (in ")"))
    (0+-sentence-before-chars (0+ (or left-quote left-markup-char left-bracket)))
    (0+-sentence-after-chars (0+ (or right-quote right-markup-char right-bracket)))
    (sentence-ending-char (in ".!?…。？"))
    (sentence-final-char (or sentence-ending-char
                             right-quote right-markup-char))
    (maybe-sentence-start (seq 0+-sentence-before-chars upper))
    (maybe-sentence-end (seq sentence-ending-char 0+-sentence-after-chars))))

;; regex for searching forward/backward
(defconst sentence-nav--sentence-search
  (sentence-nav--rx
   (or
    (and maybe-sentence-end (1+ blank))
    (and bol (0+ blank) (0+ (syntax comment-start)) (0+ blank)))
   ;; submatch so can jump directly here
   (submatch maybe-sentence-start)))

(defconst sentence-nav--sentence-end-search
  (sentence-nav--rx (submatch maybe-sentence-end)
                    (or (and " " (optional " ") maybe-sentence-start)
                        (and (0+ blank) eol))))

;; helpers
(defun sentence-nav--after-abbreviation-p ()
  "Test if after an abbreviation using `sentence-nav-abbreviation-list'.
Note that this will work at the end of a sentence (directly after the
abbreviation or after the period) or at the beginning of a sentence (after the
abbreviation followed by the period and whitespace)."
  (let ((abbr (concat
               (sentence-nav--rx (or bol blank) 0+-sentence-before-chars)
               "\\(?:"
               (mapconcat #'identity sentence-nav-abbreviation-list "\\|")
               "\\)"
               ;; optional so will work at end or beginning of sentence
               (rx (optional (and "." (0+ blank))))))
        case-fold-search)
    (looking-back abbr (line-beginning-position))))

(defun sentence-nav--maybe-at-bol-sentence-p ()
  "Return true when possibly at the start of a sentence at the start of a line.
A helper function for `sentence-nav-forward'."
  (let (case-fold-search)
    (and (looking-back (rx bol (0+ blank)) (line-beginning-position))
         (looking-at (sentence-nav--rx maybe-sentence-start)))))

(defun sentence-nav--maybe-at-sentence-end-p ()
  "Return true when possibly at the end of a sentence.
A helper function for `sentence-nav-forward-end' and for
`sentence-nav-backward-end'."
  (looking-at (sentence-nav--rx sentence-final-char (or " " eol))))

(defmacro sentence-nav--incf (var)
  "Like `cl-incf' but nil will be changed to 1."
  `(if ,var
       (cl-incf ,var)
     (setq ,var 1)))

(defun sentence-nav--at-sentence-end-line-p ()
  "Test if the current line ends with a sentence end."
  (save-excursion
    (let ((inhibit-field-text-motion t))
      (end-of-line))
    (and
     (looking-back (sentence-nav--rx maybe-sentence-end (0+ blank))
                   (line-beginning-position))
     (not (sentence-nav--after-abbreviation-p)))))

(defun sentence-nav--at-non-sentence-line-p ()
  "Test if the current line is not part of a sentence.
If the current line is not blank, this function depends on
`sentence-nav-non-sentence-line-alist' being correctly set for the current
`major-mode'."
  (save-excursion
    (let ((inhibit-field-text-motion t))
      (beginning-of-line))
    (or (looking-at (rx bol (0+ blank) eol))
        (let ((regexps
               (cdr (assoc major-mode sentence-nav-non-sentence-line-alist)))
              case-fold-search)
          (when regexps
            (looking-at (mapconcat #'identity regexps "\\|")))))))

(defun sentence-nav--not-sentence-start-p ()
  "Test if not at a valid sentence beginning position.
Return t if after an abbreviation or if at the beginning of a hard-wrapped line
in the middle of a sentence (when `sentence-nav-hard-wrapping' is non-nil)."
  (or (sentence-nav--after-abbreviation-p)
      (when (and sentence-nav-hard-wrapping
                 (looking-back (rx bol (0+ blank)) (line-beginning-position)))
        (save-excursion
          (forward-line -1)
          (not (or (sentence-nav--at-non-sentence-line-p)
                   (sentence-nav--at-sentence-end-line-p)))))))

;; actual commands
;;;###autoload
(defun sentence-nav-forward (&optional arg)
  "Move to the start of the next sentence ARG times."
  (interactive "p")
  (let ((final-pos (point))
        count
        case-fold-search)
    ;; move back so don't skip next sentence if right before it
    (when (and (not (looking-at (sentence-nav--rx maybe-sentence-start)))
               (looking-back
                (sentence-nav--rx maybe-sentence-end (0+ blank))
                (line-beginning-position)))
      (goto-char (match-beginning 0)))
    (cl-dotimes (_ arg)
      (while (progn
               ;; so won't stay on current sentence if at beginning of line
               (when (sentence-nav--maybe-at-bol-sentence-p)
                 (forward-char))
               ;; don't move at all if search fails
               (unless (re-search-forward sentence-nav--sentence-search nil t)
                 (cl-return))
               (goto-char (match-beginning 1))
               (save-match-data
                 (sentence-nav--not-sentence-start-p))))
      (sentence-nav--incf count)
      (setq final-pos (if sentence-nav-jump-to-syntax
                          (point)
                        (1- (match-end 1)))))
    (goto-char final-pos)
    count))

;;;###autoload
(defun sentence-nav-backward (&optional arg)
  "Move to the start of the previous sentence ARG times."
  (interactive "p")
  (let ((final-pos (point))
        count
        case-fold-search)
    (cl-dotimes (_ arg)
      (while (progn
               (unless (re-search-backward sentence-nav--sentence-search nil t)
                 (cl-return))
               (goto-char (match-beginning 1))
               (save-match-data
                 (sentence-nav--not-sentence-start-p))))
      (sentence-nav--incf count)
      (setq final-pos (if sentence-nav-jump-to-syntax
                          (point)
                        (1- (match-end 1)))))
    (goto-char final-pos)
    count))

;;;###autoload
(defun sentence-nav-forward-end (&optional arg)
  "Move to the start of the next sentence end ARG times."
  (interactive "p")
  (let ((final-pos (point))
        count
        case-fold-search)
    (cl-dotimes (_ arg)
      (while (progn
               ;; if already at a potential sentence end, move past it
               (when (sentence-nav--maybe-at-sentence-end-p)
                 (goto-char (match-end 0)))
               (unless (re-search-forward sentence-nav--sentence-end-search
                                          nil t)
                 (cl-return))
               (goto-char (match-beginning 1))
               (save-match-data
                 (sentence-nav--after-abbreviation-p))))
      (sentence-nav--incf count)
      (setq final-pos (if sentence-nav-jump-to-syntax
                          (1- (match-end 1))
                        (point))))
    (goto-char final-pos)
    count))

;;;###autoload
(defun sentence-nav-backward-end (&optional arg)
  "Move to the start of the previous sentence end ARG times."
  (interactive "p")
  (let ((final-pos (point))
        count
        case-fold-search)
    ;; move forward so don't skip previous sentence if right after it
    (skip-chars-forward "[[:blank:]]")
    (when (looking-back (sentence-nav--rx maybe-sentence-end (0+ blank))
                        (line-beginning-position))
      (goto-char (1+ (match-end 0))))
    (cl-dotimes (_ arg)
      (while (progn
               (unless (re-search-backward sentence-nav--sentence-end-search
                                           nil t)
                 (cl-return))
               (goto-char (match-beginning 1))
               (save-match-data
                 (sentence-nav--after-abbreviation-p))))
      (sentence-nav--incf count)
      (setq final-pos (if sentence-nav-jump-to-syntax
                          (1- (match-end 1))
                        (point))))
    (goto-char final-pos)
    count))

;; add evil motions and text-objects if/when evil loads
;; with-eval-after-load is the 24.4 dependency
(with-eval-after-load 'evil
  (evil-define-motion sentence-nav-evil-forward (count)
    "Move to the start of the COUNT-th next sentence."
    :jump t
    :type exclusive
    ;; TODO
    ;; (evil-signal-at-bob-or-eob count)
    (sentence-nav-forward (or count 1)))

  (evil-define-motion sentence-nav-evil-backward (count)
    "Move to the start of the COUNT-th previous sentence."
    :jump t
    :type exclusive
    ;; (evil-signal-at-bob-or-eob (- (or count 1)))
    (sentence-nav-backward (or count 1)))

  (evil-define-motion sentence-nav-evil-forward-end (count)
    "Move to the end of the COUNT-th next sentence."
    :jump t
    :type inclusive
    (sentence-nav-forward-end (or count 1)))

  (evil-define-motion sentence-nav-evil-backward-end (count)
    "Move to the end of the COUNT-th previous sentence."
    :jump t
    :type inclusive
    (sentence-nav-backward-end (or count 1)))

  (put 'sentence-nav-evil-inner-sentence 'beginning-op
       (lambda (&optional count)
         (let ((sentence-nav-jump-to-syntax
                (not sentence-nav-syntax-text-objects)))
           (sentence-nav-evil-backward count))))
  (put 'sentence-nav-evil-inner-sentence 'forward-op
       (lambda (&optional count)
         (let ((sentence-nav-jump-to-syntax
                (not sentence-nav-syntax-text-objects)))
           (sentence-nav-evil-forward-end count))
         (forward-char)))

  (put 'sentence-nav-evil-a-sentence 'beginning-op
       (lambda (&optional count)
         (let ((sentence-nav-jump-to-syntax t))
           (sentence-nav-evil-backward count))))
  (put 'sentence-nav-evil-a-sentence 'forward-op
       (lambda (&optional count)
         (let ((sentence-nav-jump-to-syntax t))
           (sentence-nav-evil-forward-end count)
           (forward-char)
           (skip-chars-forward "[[:blank:]]"))))

  (evil-define-text-object sentence-nav-evil-inner-sentence
    (count &optional beg end type)
    "Select a sentence excluding spaces after it."
    (evil-select-inner-object 'sentence-nav-evil-inner-sentence
                              beg end type count))

  (evil-define-text-object sentence-nav-evil-a-sentence
    (count &optional beg end type)
    "Select a sentence up to the start of the next sentence after it."
    (evil-select-inner-object 'sentence-nav-evil-a-sentence beg end type count)))

;;;###autoload
(with-eval-after-load 'evil
  (autoload 'sentence-nav-evil-forward "sentence-navigation" nil t)
  (autoload 'sentence-nav-evil-forward-end "sentence-navigation" nil t)
  (autoload 'sentence-nav-evil-backward "sentence-navigation" nil t)
  (autoload 'sentence-nav-evil-backward-end "sentence-navigation" nil t)
  (autoload 'sentence-nav-evil-a-sentence "sentence-navigation" nil t)
  (autoload 'sentence-nav-evil-inner-sentence "sentence-navigation" nil t))

(provide 'sentence-navigation)
;;; sentence-navigation.el ends here
