;;; electric-ospl.el --- Electric OSPL Mode -*- lexical-binding: t -*-

;; Author: Samuel W. Flint <swflint@flintfam.org>
;; Version: 2.1.0
;; Package-Version: 20230325.1518
;; Package-Commit: 55fa59592d0d3e929bd8646ea691a592965a167a
;; Package-Requires: ((emacs "26.1"))
;; Keywords: convenience, text
;; URL: https://git.sr.ht/~swflint/electric-ospl-mode
;; SPDX-License-Identifier: GPL-3.0-or-later
;; SPDX-FileCopyrightText: 2023 Samuel W. Flint <swflint@flintfam.org>

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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
;;
;; A simple minor-mode to automatically enforce a "one-sentence per
;; line" style in text files.
;;
;;;; Installation
;;
;; Place the file `electric-ospl.el' somewhere on your `load-path',
;; and `require` it (note, autoloading is also supported).  Enable
;; `electric-ospl-mode' anywhere where you want to follow a
;; "one-sentence per line" style, for instance, by adding to various
;; mode hooks (I use `text-mode-hook' personally).
;;
;; Additionally, a globalized minor mode, `global-electric-ospl-mode'
;; is available, which will activate the mode based on the value of
;; `electric-ospl-global-modes' (see below).
;;
;;;; Configuration
;;
;; There are a couple of options which can be used to modify behavior
;; (and speed) of the mode.
;;
;; - The first is `electric-ospl-regexps', which sets the list of
;;   regular expressions defining how a sentence ends.
;;
;; - The next is `electric-ospl-ignored-abbreviations', which is a
;;   (case-sensitive) list of abbrevations ending in a period that are
;;   not necessarily considered the end of a sentence.
;;
;; - Next, efficiency may be modified by changing
;;   `electric-ospl-maximum-lookback-chars', which determines how far
;;   to look back to find the end of a sentence.
;;
;;  - Additionally, the `electric-ospl-sentence-end-functions' hook
;;    determines if point is currently at the end of a sentence.  It
;;    defaults to using the regexp returned by `sentence-end' but may
;;    be extended to use sentence-end determination logic provided by
;;    other packages.
;;
;;  - Finally, you can configure ignoring of OSPL in certain
;;    circumstances using the
;;    `electric-ospl-ignore-electric-functions' hook.  This variable
;;    defaults to ignoring when the last thing was in the ignored
;;    abbreviations list.  It is used by checking, one-by-one for a
;;    function which returns non-nil.  An example use is below.
;;
;; (add-hook 'LaTeX-mode-hook (defun my/latex-ospl-config ()
;;                              (add-hook 'electric-ospl-ignore-electric-functions
;;                                        (defun my/ignore-ospl-in-some-latex-envs ()
;;                                          (cl-member (LaTeX-current-environment)
;;                                                     '("tabular" "tabularx" "tikzpicture")))
;;                                        -100 t)))
;;
;; Additionally, where the globalized mode is enabled is configured
;; using `electric-ospl-global-modes', which has the following
;; semantics.
;;
;; - If t, it will be enabled in all modes (except for special modes,
;;   ephemeral buffers, or the minibuffer).
;;
;; - If nil, it will not be enabled in any modes.
;;
;; - If the first symbol is `not', `electric-ospl-mode' will not be
;;   enabled in buffers with the listed major modes or descending from
;;   the listed major modes.
;;
;; - Otherwise, it will be enabled only in the listed modes.
;;
;; It may also be configured using the
;; `electric-ospl-allowed-override-commands' variable, which defines
;; which bindings for SPC may be overridden.  If the current binding
;; for SPC is not in `electric-ospl-allowed-override-commands', then
;; the mode will not be activated locally.  This defaults to
;; `self-insert-command' and `org-self-insert-command'.
;;
;;;; Acknowledgments
;;
;; This code is based significantly on Jan Seeger's `twauctex'
;; (https://github.com/jeeger/twauctex).  I've made effort to simplify
;; the logic and make it so that it's usable in modes other than
;; `LaTeX-mode'.
;;
;;;; Errors and Patches
;;
;; If you find an error or have a patch to improve this package, please
;; send an email to `~swflint/public-inbox@lists.sr.ht`.



;;; Code:

;;; Customization

(defgroup electric-ospl nil
  "Customization for electric-ospl.

electric-ospl is an electric SPC that helps to make
one-sentence-per-line editing slightly easier."
  :group 'text)

(defcustom electric-ospl-regexps (list (sentence-end))
  "Definitions of the end of a sentence.

This defaults to what the function `sentence-end' returns at load
time."
  :group 'electric-ospl
  :type '(repeat regexp))

(defcustom electric-ospl-ignored-abbreviations (list "et al."
                                                     "etc."
                                                     "i.e."
                                                     "e.g."
                                                     "vs."
                                                     "viz.")
  "A list of (case-sensitive) abbrevations which may not end sentences.

It is generally a good idea to customize this based on your
writing and those which you frequently use."
  :group 'electric-ospl
  :type '(repeat (string :tag "Abbreviation")))

(defcustom electric-ospl-maximum-lookback-chars 1
  "How far is lookback performed to find a sentence ending.

This should be calculated from the longest possible match to
`electric-ospl-regexps'."
  :group 'electric-ospl
  :type 'integer)

(defcustom electric-ospl-ignore-electric-functions
  (list #'electric-ospl-at-indented-newline-p #'electric-ospl-at-abbrev-p)
  "Functions which are used to prevent insertion of an electric OSPL space.

A function in this hook should return t if an electric space
should not be inserted.  They are run one at a time, until one of
these functions return non-nil.  Additionally, these should not
modify match data or point/mark.

It may be useful to set this as a buffer-local hook in some
modes (`LaTeX-mode' for instance, to not do OSPL in certain
environments).

For information about the defaults, see
`electric-ospl-at-indentend-newline-p' and
`electric-ospl-at-abbrev-p'."
  :group 'electric-ospl
  :type 'hook)

(defcustom electric-ospl-sentence-end-functions
  (list #'electric-ospl-at-sentence-end-p)
  "Functions which decide if point is currently at sentence end.

A function in this hook should return t if point is currently at
the end of a sentence.  They are run one at a time, until one
returns non-nil.  Additionally, these should not modify match
data or point/mark.

It may be useful to set this as a buffer-local hook in some modes
where sentence end detection is not clear.

See `electric-ospl-at-sentence-end-p' for information about
defaults."
  :group 'electric-ospl
  :type 'hook)

(defcustom electric-ospl-global-modes t
  "Modes in which `global-electric-ospl-mode' should enable the local mode.

If t, `electric-ospl-mode' is turned on for all major modes.  If
a list, it is turned on for all `major-mode' symbols; however, if
the `car' is `not', the mode is turned on for all modes not in
that list (or not descending from that list).  If nil,
`electric-ospl-mode' is never turned on automatically.

The mode is never turned on for modes which are considered
special or are ephemeral (have a space as prefix of the name)."
  :group 'electric-ospl
  :type '(choice (const t :tag "All modes")
                 (const nil :tag "No modes")
                 (set :menu-tag "certain modes" :tag "modes"
                      :value (not)
                      (const :tag "Forbid" not)
                      (repeat :inline t (symbol :tag "mode")))))

(defcustom electric-ospl-allowed-override-commands
  (list #'self-insert-command
        'org-self-insert-command)
  "List of bindings which `electric-ospl' is allowed to override.

By default this will include only `org-self-insert-command' and
`self-insert-command', but depending on your configuration,
others may be appropriate as well."
  :group 'electric-ospl
  :type 'hook)


;;; Cached Regular Expressions

(defvar electric-ospl--ignored-abbrevs-regexp
  (regexp-opt electric-ospl-ignored-abbreviations)
  "Regular-expression for of `electric-ospl-ignored-abbreviations'.

This variable is generated automatically, and upon change to the
original variable.  Do not modify it directly.")

(defun electric-ospl--update-ignored-abbrevs-regexp (_symbol new-value op _where)
  "Update `electric-ospl--ignored-abbrevs-regexp' using NEW-VALUE when OP is `set'."
  (when (eq op 'set)
    (setf electric-ospl--ignored-abbrevs-regexp (regexp-opt new-value))))

(add-variable-watcher 'electric-ospl-ignored-abbreviations
                      #'electric-ospl--update-ignored-abbrevs-regexp)

(defvar electric-ospl--abbrev-lookback
  (+ 2 (apply #'max (mapcar #'length electric-ospl-ignored-abbreviations)))
  "How far should look-back be performed for ignored abbreviations?

This variable is generated automatically from
`electric-ospl-ignored-abbreviations', and upon change to the
original variable.  Do not modify it directly.")

(defun electric-ospl--update-abbrev-lookback (_symbol new-value op _where)
  "Update `electric-ospl--abbrev-lookback' using NEW-VALUE when OP is `set'."
  (when (eq op 'set)
    (setf electric-ospl--abbrev-lookback
          (+ 2 (apply #'max
                      (mapcar #'length
                              new-value))))))

(add-variable-watcher 'electric-ospl-ignored-abbreviations
                      #'electric-ospl--update-abbrev-lookback)

(defvar electric-ospl--single-sentence-end-regexp
  (concat "\\(?:" (mapconcat  (lambda (regexp)
                                (concat "\\(?:" regexp "\\)"))
                              electric-ospl-regexps
                              "\\|")
          "\\)")
  "Single sentence-ending regular expression.

This variable is automatically generated from
`electric-ospl-regexps' and upon its change.  Do not modify it
directly.")

(defun electric-ospl--update-sse-regexp (_symbol new-val op _where)
  "Change `electric-ospl--single-sentence-end-regexp' to NEW-VAL when OP is `set'."
  (when (eq op 'set)
    (setf electric-ospl--single-sentence-end-regexp
          (concat "\\(?:" (mapconcat (lambda (regexp)
                                       (concat "\\(?:" regexp "\\)"))
                                     new-val
                                     "\\|")
                  "\\)"))))

(add-variable-watcher 'electric-ospl-regexps
                      #'electric-ospl--update-sse-regexp)


;;; At Abbreviation?

(defun electric-ospl-at-abbrev-p ()
  "Are we currently at a non-sentence-ending abbreviation?

This is configured using `electric-ospl-ignored-abbreviations', a
list of abbreviations which end in a sentence-ending character."
  (save-excursion
    (save-match-data
      (looking-back (concat "\\<" electric-ospl--ignored-abbrevs-regexp "\s?")
                    (- (point) electric-ospl--abbrev-lookback)))))


;;; At indented newline?

(defun electric-ospl-at-indented-newline-p ()
  "Are we currently at an (indented) newline?

While `bolp' exists to determine if point is currently at the
beginning of a line, it does not consider if the line is
indented (as may be seen in a number of markup languages).  This
checks for both."
  (save-excursion
    (save-match-data
      (looking-back (rx bol (* blank)) nil))))


;;; At sentence end?

(defun electric-ospl-at-sentence-end-p ()
  "Are we currently at the end of a sentence?

This is determined by checking if the point comes after a member
of `electric-ospl-regexps' (when combined as
`electric-ospl--single-sentence-end-regexp'), using the maximum
lookback of `electric-ospl-maximum-lookback-chars'."
  (save-excursion
    (save-match-data
      (looking-back electric-ospl--single-sentence-end-regexp
                    electric-ospl-maximum-lookback-chars))))


;;; Electric Space

(defvar-local electric-ospl-original-binding #'self-insert-command
  "What was SPC originally bound to?

This is called by `electric-ospl-electric-space' so that if a
major mode does things a bit cleverly, it should work.")

(defun electric-ospl-electric-space (arg)
  "Insert a space character, or an OSPL line break as appropriate.

If ARG is given, insert a space, do not break line.  If the
command is repeated, delete the line-break."
  (interactive "p")
  (if (run-hook-with-args-until-success 'electric-ospl-ignore-electric-functions)
      (funcall electric-ospl-original-binding 1)
    (self-insert-command 1)               ; Fool the sentence-end regular expressions...
    (let* ((case-fold-search nil)
           (repeated-p (or (> arg 1)
                           (eq last-command 'electric-ospl-electric-space)))
           (at-electric-p (run-hook-with-args-until-success 'electric-ospl-sentence-end-functions)))
      (delete-char -1)                    ; Character is probably no longer needed
      (cond
       ((and repeated-p (bolp))
        (delete-char -1)
        (funcall electric-ospl-original-binding 1))
       (at-electric-p
        (newline)
        (indent-according-to-mode))
       (t (funcall electric-ospl-original-binding 1))))))


;;; Refill as OSPL

(defun electric-ospl-fill-ospl (&optional arg)
  "Fill paragraph into one-sentence-per-line format.

If ARG is passed, call the regular `fill-paragraph' instead."
  (interactive "P")
  (unless (and (bolp) (eolp))
    (if (not arg)
        (progn
          (save-mark-and-excursion
            (save-match-data
              (let ((fill-column most-positive-fixnum)
                    (sentence-end electric-ospl--single-sentence-end-regexp))
                (fill-paragraph)
                (let ((end-boundary (save-excursion (forward-paragraph 1)
                                                    (backward-sentence)
                                                    (point-marker))))
                  (beginning-of-line)
                  (while (progn (forward-sentence)
                                (<= (point) (marker-position end-boundary)))
                    (unless (electric-ospl-at-abbrev-p)
                      (just-one-space)
                      (delete-char -1)
                      (newline)
                      (indent-according-to-mode))))))))
      (fill-paragraph arg))))


;;; Global Minor Mode Safety

(defun electric-ospl-allowed-mode-p ()
  "Should `global-electric-ospl-mode' enable the local mode in the current buffer?

The mode will not be enabled in the following cases:

 - In the minibuffer
 - `special' modes
 - `fundamental-mode'
 - Ephemeral Buffers
 - Major modes excluded by `electric-ospl-global-modes'
 - The binding of SPC is not in `electric-ospl-allowed-override-commands'."
  (and (cl-member (key-binding (kbd "SPC")) electric-ospl-allowed-override-commands)
       (pcase electric-ospl-global-modes
         (`t t)
         (`(not . ,modes) (and (not (memq major-mode modes))
                               (not (apply #'derived-mode-p modes))))
         (modes (memq major-mode modes)))
       (not (or (minibufferp)
                (eq major-mode 'fundamental-mode)
                (string-prefix-p " " (buffer-name))))))

(defun electric-ospl-enable-mode ()
  "Conditionally enable `electric-ospl-mode' in the current buffer.

`electric-ospl-mode' will only be enabled when
`electric-ospl-allowed-mode-p' is non-nil."
  (when (electric-ospl-allowed-mode-p)
    (electric-ospl-mode)))


;;; Minor Mode Definition

(defvar electric-ospl-mode-map
  (let ((keymap (make-keymap)))
    (define-key keymap (kbd "SPC") #'electric-ospl-electric-space)
    (define-key keymap (kbd "M-q") #'electric-ospl-fill-ospl)
    keymap)
  "Keymap for `electric-ospl-mode'.")

;;;###autoload
(define-minor-mode electric-ospl-mode
  "A basic One-Sentence-Per-Line mode which defines an electric SPC key."
  :lighter " OSPL" :keymap electric-ospl-mode-map
  (if electric-ospl-mode
      (progn
        (setq-local electric-ospl-original-binding (let ((electric-ospl-mode nil))
                                                     (key-binding (kbd "SPC"))))
        (message "Enabled `electric-ospl-mode'."))
    (message "Disabled `electric-ospl-mode'.")))

;;;###autoload
(define-globalized-minor-mode global-electric-ospl-mode electric-ospl-mode
  electric-ospl-enable-mode
  :init-value nil)


(provide 'electric-ospl)

;;; electric-ospl.el ends here
