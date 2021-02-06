;;; ido-complete-space-or-hyphen.el --- Allow spaces to also match hyphens in ido

;; Author: Ryan C. Thompson <rct@thompsonclan.org>
;;         Ian Yang <me (at) iany.me>
;; Maintainer: Ryan C. Thompson <rct@thompsonclan.org>
;; Keywords: ido, completion, convenience
;; Package-Version: 20210206.1505
;; Package-Commit: d1244243e042b8d5b6b991db752a17a44ea169bc
;; Filename: ido-complete-space-or-hyphen.el
;; Version: 1.3
;; URL: https://github.com/DarwinAwardWinner/ido-complete-space-or-hyphen
;; Created: 2012-11-07 13:58
;; Last-Updated: Sat Feb  6 10:05:06 2021 (-0500)

;;; Licence:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; The default behavior of ido SPACE key will try to insert SPACE if it makes
;; sense (a.k.a, the common part of all matches contains SPACE). However,
;; when ido is used to complete lisp functions or variables, like what smex
;; does, HYPHEN is used as separator. This extension for ido inserts SPACE or
;; HYPHEN whenever either one makes sense, just like what built-in M-x does.
;;
;; Example:
;;
;; (ido-completing-read "test: " '("ido-foo-bar" "ido-space" "ido-test"))
;;
;;     | Key Sequence | Result |
;;     |--------------+--------|
;;     | i            | "i"    |
;;     | SPACE        | "ido-" |
;;
;; (ido-completing-read "test: " '("ido foo-bar" "ido space" "ido test"))
;;
;;     | Key Sequence | Result |
;;     |--------------+--------|
;;     | i            | "i"    |
;;     | SPACE        | "ido " |
;;
;; (ido-completing-read "test: " '("ido-foo-bar" "ido-space" "idotest"))
;;
;;     | Key Sequence | Result |
;;     |--------------+--------|
;;     | i            | "i"    |
;;     | SPACE        | "ido"  |
;;     | SPACE        | "ido-" |
;;
;; When HYPHEN can be inserted and SPACE cannot, insert HYPHEN when user enter SPACE.
;;
;; (ido-completing-read "test: " '("ido-foo-bar" "ido-space" "ido test"))
;;
;;     | Key Sequence | Result                           |
;;     |--------------+----------------------------------+
;;     | i            | "i"                              |
;;     | SPACE        | "ido"                            |
;;     | SPACE        | "ido"  Completion popup is shown |
;;     | SPACE        | "ido "                           |
;;
;; If both HYPHEN and SPACE can be inserted, SPACE first brings the completion
;; popup window, if user types SPACE again, then SPACE itself is inserted.

;;; Usage:

;;     (require 'ido-complete-space-or-hyphen)
;;     (ido-mode 1)
;;     (ido-complete-space-or-hyphen-mode 1)
;;
;; Recommended packages that can be used together:
;;
;; -   [ido-completing-read+](https://github.com/DarwinAwardWinner/ido-completing-read-plus) Use ido completion wherever possible
;; -   [smex](https://github.com/nonsequitur/smex) a M-x enhancement
;; -   [amx](https://github.com/DarwinAwardWinner/amx) another ido-based M-x
;;

;;; Changes

;; -   1.1 (2013-02-27)
;;
;;     -  Add `ido-complete-space-or-hyphen--insert-space' to allow user type
;;        SPACE twice to insert SPACE.
;;
;; -   1.2
;;
;;     -  Convert to a full-fledged minor mode

;;; Code:

(eval-when-compile
  (require 'ido))

;;;###autoload
(define-minor-mode ido-complete-space-or-hyphen-mode
  "Toggle ido-complete-space-or-hyphen mode.

The default behavior of ido SPACE key will try to insert SPACE if it makes
sense (a.k.a, the common part of all matches contains SPACE). Howerver,
when ido is used to complete lisp functions or variables, like what smex
does, HYPHEN is used as separator. This extension for ido inserts SPACE or
HYPHEN whenever which one makes sense, just like what built-in M-x does.

You can also temporarily disable ido-complete-space-or-hyphen-mode
within a function by let-binding this to nil:

    (let ((ido-complete-space-or-hyphen-mode nil))
      (ido-completing-read ...))"
  nil
  :global t
  :group 'ido
  (when ido-complete-space-or-hyphen-mode
    (ad-enable-advice 'ido-complete-space 'around 'ido-complete-space-or-hyphen)
    (ad-activate 'ido-complete-space)))
(define-obsolete-variable-alias
  'ido-complete-space-or-hyphen
  'ido-complete-space-or-hyphen-mode
  "ido-complete-space-or-hyphen 1.2")

(defvar ido-complete-space-or-hyphen--insert-space nil
  "Internal variable to indicate whether SPACE should be inserted
when both SPACE and HYPHEN make sense.

It allows user press SPACE twice to insert real SPACE.
")

(defun ido-complete-space-or-hyphen ()
  "Try completion unless inserting the SPACE or HYPHEN makes sense."
  (interactive)
  (let ((space-or-hyphen
         (and (stringp ido-common-match-string)
              (stringp ido-text)
              (cond
               ;; test whether next char is SPACE or HYPHEN
               ((> (length ido-common-match-string) (length ido-text))
                (car-safe (member (aref ido-common-match-string (length ido-text)) '(?  ?-))))
               (ido-matches
                (let ((re (concat (regexp-quote ido-text) "\\([- ]\\)"))
                      (comp ido-matches)
                      space-or-hyphen name)
                  (while comp
                    (setq name (ido-name (car comp)))
                    (if (string-match re name)
                        ;; If both SPACE and HYPHEN matches
                        (if (and space-or-hyphen (not (= space-or-hyphen (aref (match-string 1 name) 0))))
                            (if ido-complete-space-or-hyphen--insert-space
                                ;; insert SPACE if user has typed SPACE twice
                                (setq ido-complete-space-or-hyphen--insert-space nil
                                      space-or-hyphen 32
                                      comp nil)
                              ;; do not insert any the first time, but mark the flag
                              (setq ido-complete-space-or-hyphen--insert-space t
                                    space-or-hyphen nil
                                    comp nil))
                          (setq space-or-hyphen (aref (match-string 1 name) 0))))
                    (setq comp (cdr comp)))
                  space-or-hyphen))
               (t nil)))))
    (if space-or-hyphen
        (insert (char-to-string space-or-hyphen))
      (ido-complete))))

;; replace ido-complete-space with ido-complete-space-or-hyphen
(defadvice ido-complete-space (around ido-complete-space-or-hyphen () activate compile)
  (if ido-complete-space-or-hyphen-mode
      (call-interactively 'ido-complete-space-or-hyphen)
    ad-do-it))


;;;###autoload
(defun ido-complete-space-or-hyphen-enable ()
  "Enable ido-complete-space-or-hyphen"
  (interactive)
  (ido-complete-space-or-hyphen-mode 1))
(make-obsolete
 'ido-complete-space-or-hyphen-enable
 "use `(ido-complete-space-or-hyphen-mode 1)' instead."
 "ido-complete-space-or-hyphen 1.2")

;;;###autoload
(defun ido-complete-space-or-hyphen-disable ()
  "Disable ido-complete-space-or-hyphen"
  (interactive)
  (ido-complete-space-or-hyphen-mode 1))
(make-obsolete
 'ido-complete-space-or-hyphen-disable
 "use `(ido-complete-space-or-hyphen-mode 0)' instead."
 "ido-complete-space-or-hyphen 1.2")

(provide 'ido-complete-space-or-hyphen)

;;; ido-complete-space-or-hyphen.el ends here
