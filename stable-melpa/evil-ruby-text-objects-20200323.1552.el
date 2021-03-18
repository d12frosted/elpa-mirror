;;; evil-ruby-text-objects.el --- Evil text objects for Ruby code -*- lexical-binding: t -*-

;; Copyright (C) 2019 Sergio Gil

;; Author: Sergio Gil <sgilperez@gmail.com>
;; Version: 0.1
;; Package-Version: 20200323.1552
;; Package-Commit: 32983d91be83ed903b6ef9655e00f69beed2572c
;; Keywords: languages
;; URL: https://github.com/porras/evil-ruby-text-objects
;; Package-Requires: ((emacs "25.1") (evil "1.2.0"))

;; This program is free software; you can redistribute it and/or modify
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
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Adds text objects and keybindings to work with Ruby code with Evil.
;;
;; See documentation at https://github.com/porras/evil-ruby-text-objects

;;; Code:

(require 'evil)
(require 'eieio)
(require 'cl-lib)

;; these are the external functions, from the bundled ruby-mode, and from
;; enh-ruby-mode (only in case it's installed) which are used from this package.
(declare-function ruby-beginning-of-block "ruby-mode.el")
(declare-function ruby-end-of-block "ruby-mode.el")
(declare-function enh-ruby-beginning-of-block "ext:enh-ruby-mode.el")
(declare-function enh-ruby-end-of-block "ext:enh-ruby-mode.el")
(declare-function enh-ruby-up-sexp "ext:enh-ruby-mode.el")

;; These classes abstract away the differences between ruby-mode and
;; enh-ruby-mode. They implement four methods: up, beginning, end, and
;; mark-special (to handle specific cases without resorting to the mode tools).
;; The enh-ruby-mode variant just delegate to enh-ruby-mode's
;; enh-ruby-beginning-of-block, enh-ruby-end-of-block and enh-ruby-up-sexp, and
;; returns nil from mark-special to signal that no special case needs to be
;; handled. The ruby-mode variants delegates to ruby-mode's
;; ruby-beginning-of-block, ruby-end-of-block, and backward-up-list, but
;; performing additional movements so that they behave exactly like the
;; enh-ruby-mode's counterparts. In mark-special, it checks if we're currently
;; in a oneline method/class/etc (a case that ruby-mode doesn't handle), and in
;; that case it selects the line and return t to signal that the special case
;; was handled.
(defclass evil-ruby-text-objects--enh-ruby-mode-navigator () ())
(defclass evil-ruby-text-objects--ruby-mode-navigator () ())

(cl-defmethod evil-ruby-text-objects--beginning ((_ evil-ruby-text-objects--ruby-mode-navigator))
  "Emulate `enh-ruby-beginning-of-block' using `ruby-beginning-of-block'.
`ruby-beginning-of-block' moves us to the beginning of the line
where the block begins, we need to move forward to the `do'
keyword to complete the emulation."
  (ruby-beginning-of-block)
  (re-search-forward "do" (line-end-position) t))

(cl-defmethod evil-ruby-text-objects--end ((_ evil-ruby-text-objects--ruby-mode-navigator))
  "Emulate `enh-ruby-end-of-block' using `ruby-end-of-block'.
We move to the end of the block, and then move one word forward
if we are at the `end' keyword."
  (ruby-end-of-block)
  (when (looking-at "end") (evil-forward-word-begin)))

(cl-defmethod evil-ruby-text-objects--up ((_ evil-ruby-text-objects--ruby-mode-navigator))
  "Delegate directly to `ruby-mode'."
  (backward-up-list))

(cl-defmethod evil-ruby-text-objects--mark-special ((_ evil-ruby-text-objects--ruby-mode-navigator) keyword)
  "Manage oneline definition.
Searches for a oneline KEYWORD (def or class) with a regular
expression (`enh-ruby-mode' manages this correctly but
`ruby-mode' doesn't)."
  (when (string-match-p (concat "^\s*" keyword ".*;\s*end\s*$") (thing-at-point 'line))
    (beginning-of-line-text)
    (set-mark (point))
    (end-of-line)
    t))

(cl-defmethod evil-ruby-text-objects--beginning ((_ evil-ruby-text-objects--enh-ruby-mode-navigator))
  "Delegate directly to `enh-ruby-mode'."
  (enh-ruby-beginning-of-block))

(cl-defmethod evil-ruby-text-objects--end ((_ evil-ruby-text-objects--enh-ruby-mode-navigator))
  "Delegate directly to `enh-ruby-mode'."
  (enh-ruby-end-of-block))

(cl-defmethod evil-ruby-text-objects--up ((_ evil-ruby-text-objects--enh-ruby-mode-navigator))
  "Delegate directly to `enh-ruby-mode'."
  (enh-ruby-up-sexp))

(cl-defmethod evil-ruby-text-objects--mark-special ((_ evil-ruby-text-objects--enh-ruby-mode-navigator) _keyword)
  "Do nothing.
\(we don't need to manage any special case in `enh-ruby-mode')."
  nil)

(defun evil-ruby-text-objects--make-navigator ()
  "It instantiates a navigator object suitable for the current ruby mode.
It defaults to the builtin `ruby-mode', so that this mode can be used with
languages similar to Ruby, such as Crystal."
  (cond ((eq major-mode 'enh-ruby-mode) (evil-ruby-text-objects--enh-ruby-mode-navigator))
        (t (evil-ruby-text-objects--ruby-mode-navigator))))

;; the rest of the functions are used always, and use a navigator instance,
;; which implements the two supported ruby modes.
(defun evil-ruby-text-objects--evil-range (count type keyword &optional inner)
  "Defines a linewise ‘evil-range’ selecting the specified Ruby expression.
COUNT: number of times it should go up the tree searching for the target
expression (for nested expressions)
TYPE: managed by ‘evil-range’ and passed as is
KEYWORD: string or regexp with the keyword that marks the beginning of the
target expression
INNER: When t, then only the content of the expression is selected but not its
opening or closing"
  (save-excursion
    (let ((navigator (evil-ruby-text-objects--make-navigator)))
      (unless (evil-ruby-text-objects--mark-special navigator keyword)
        (skip-syntax-forward " ")
        (unless (looking-at keyword)
          (evil-ruby-text-objects--beginning navigator))
        (dotimes (i count)
          (while (not (looking-at keyword))
            (when (bobp) (user-error "Can't find current %s opening" keyword))
            (evil-ruby-text-objects--up navigator))
          (unless (= i (1- count)) ; if it's not the last one
            (evil-ruby-text-objects--up navigator)))
        (set-mark (point))
        (evil-ruby-text-objects--end navigator)))
    (when inner
      (search-backward "end")
      (exchange-point-and-mark)
      (skip-chars-forward "^;\n")
      (forward-char)
      (skip-syntax-forward " "))
    (evil-text-object-make-linewise (evil-range (region-beginning) (region-end) type :expanded t))))

(defmacro evil-ruby-text-objects--define-object (object &optional keyword)
  "Defines an inner and an outer object.
Accepted parameters are the OBJECT name (a string) and optionally a KEYWORD
\(string or regexp, defaults to the object name). It defines two evil text
objects, evil-a-ruby-<OBJECT> (outer), and evil-inner-ruby-<OBJECT> (inner)."
  (let ((keyword (or keyword object))
        (outer-object (intern (concat "evil-a-ruby-" object)))
        (inner-object (intern (concat "evil-inner-ruby-" object))))
    `(progn
       (evil-define-text-object ,outer-object (count &rest unused)
                                        ; giving a name to it because of a compiler warning `argument _ not left unused`
         ,(format "Select a Ruby %s." object)
         (evil-ruby-text-objects--evil-range count type ,keyword))
       (evil-define-text-object ,inner-object (count &rest unused)
                                        ; giving a name to it because of a compiler warning `argument _ not left unused`
         ,(format "Select the inner content of a Ruby %s." object)
         (evil-ruby-text-objects--evil-range count type ,keyword t)))))

(evil-ruby-text-objects--define-object "method" "def")
(evil-ruby-text-objects--define-object "class")
(evil-ruby-text-objects--define-object "module")
(evil-ruby-text-objects--define-object "namespace" (regexp-opt '("class" "module")))
(evil-ruby-text-objects--define-object "block" "do")
(evil-ruby-text-objects--define-object "conditional" (regexp-opt '("if" "unless" "case")))
(evil-ruby-text-objects--define-object "begin")

;;;###autoload
(define-minor-mode evil-ruby-text-objects-mode
  "Enables Evil keybindings for ruby text objects"
  :keymap (make-sparse-keymap)
  (evil-define-key '(operator visual) evil-ruby-text-objects-mode-map
    "am" 'evil-a-ruby-method
    "am" 'evil-a-ruby-method
    "arm" 'evil-a-ruby-method
    "arc" 'evil-a-ruby-class
    "arM" 'evil-a-ruby-module
    "arn" 'evil-a-ruby-namespace
    "arb" 'evil-a-ruby-block
    "ari" 'evil-a-ruby-conditional
    "arg" 'evil-a-ruby-begin
    "im" 'evil-inner-ruby-method
    "irm" 'evil-inner-ruby-method
    "irc" 'evil-inner-ruby-class
    "irM" 'evil-inner-ruby-module
    "irn" 'evil-inner-ruby-namespace
    "irb" 'evil-inner-ruby-block
    "iri" 'evil-inner-ruby-conditional
    "irg" 'evil-inner-ruby-begin))

(provide 'evil-ruby-text-objects)

;;; evil-ruby-text-objects.el ends here
