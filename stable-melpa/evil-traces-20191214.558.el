;;; evil-traces.el --- Visual hints for `evil-ex' -*- lexical-binding: t -*-

;; Copyright (C) 2019 Daniel Phan

;; Author: Daniel Phan <daniel.phan36@gmail.com>
;; Version: 0.2.0
;; Package-Version: 20191214.558
;; Package-Commit: 290b5323542c46af364ec485c8ec9000040acf90
;; Package-Requires: ((emacs "25.1") (evil "1.2.13"))
;; Homepage: https://github.com/mamapanda/evil-traces
;; Keywords: emulations, evil, visual

;; This file is NOT part of GNU Emacs.

;;; License:
;;
;; This program is free software: you can redistribute it and/or modify
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
;;
;; evil-traces is a port of traces.vim (https://github.com/markonm/traces.vim).
;; It adds visual hints to certain `evil-ex' commands.  To enable the hints,
;; turn on `evil-traces-mode'.

;;; Code:

;; * Some Notes
;; - If a highlight needs to be cleared during a regular update, then
;;   use (evil-traces--set-hl hl-name nil) instead of
;;   (evil-traces--delete-hl hl-name).  The former will create an
;;   entry in `evil-traces--highlights' and make things more
;;   predictable for testing.  If clearing due to a suspension or
;;   stop, then just use `evil-traces--delete-hl'.
;; - After calling a runner with 'start, `evil-ex-update' will
;;   immediately call it with 'update, so there's no need to set
;;   highlights in the 'start case like evil's :substitute runner
;;   does.

;; * Setup
(require 'cl-lib)
(require 'evil)
(eval-when-compile
  (require 'subr-x))

(defgroup evil-traces nil
  "Visual feedback for `evil-ex' commands."
  :prefix "evil-traces-"
  :group 'evil)

;; * User Options
;; ** Faces
(defface evil-traces-default '((t (:inherit region)))
  "The default face for evil-traces overlays.")

(defface evil-traces-change '((t (:inherit evil-traces-default)))
  "Face for :change commands.")

(defface evil-traces-delete '((t (:inherit evil-traces-default)))
  "Face for :delete commands.")

(defface evil-traces-normal '((t (:inherit evil-traces-default)))
  "Face for :normal commands.")

(defface evil-traces-shell-command '((t (:inherit evil-traces-default)))
  "Face for :! commands.")

(defface evil-traces-yank '((t (:inherit evil-traces-default)))
  "Face for :yank commands.")

(defface evil-traces-move-range '((t (:inherit evil-traces-default)))
  "Face for :move's range.")

(defface evil-traces-move-preview '((t (:inherit evil-traces-default)))
  "Face for :move's preview.")

(defface evil-traces-copy-range '((t (:inherit evil-traces-default)))
  "Face for :copy's range.")

(defface evil-traces-copy-preview '((t (:inherit evil-traces-default)))
  "Face for :copy's preview.")

(defface evil-traces-global-range '((t (:inherit evil-traces-default)))
  "The face for :global's range.")

(defface evil-traces-global-match '((t (:inherit isearch)))
  "The face for matched :global terms.")

(defface evil-traces-join-range '((t (:inherit evil-traces-default)))
  "The face for :join's range.")

(defface evil-traces-join-indicator nil
  "The face for :join's indicator.")

(defface evil-traces-sort '((t (:inherit evil-traces-default)))
  "The face for :sort.")

(defface evil-traces-substitute-range '((t (:inherit evil-traces-default)))
  "The face for :substitute's range.")

;; ** Variables
(defcustom evil-traces-argument-type-alist
  '((evil-change             . evil-traces-change)
    (evil-copy               . evil-traces-copy)
    (evil-ex-delete          . evil-traces-delete)
    (evil-ex-global          . evil-traces-global)
    (evil-ex-global-inverted . evil-traces-global)
    (evil-ex-join            . evil-traces-join)
    (evil-ex-normal          . evil-traces-normal)
    (evil-ex-sort            . evil-traces-sort)
    (evil-ex-substitute      . evil-traces-substitute)
    (evil-ex-yank            . evil-traces-yank)
    (evil-move               . evil-traces-move)
    (evil-shell-command      . evil-traces-shell-command))
  "An alist mapping `evil-ex' functions to their argument types."
  :type '(alist :key function :value symbol))

(defcustom evil-traces-lighter " traces"
  "Lighter for evil-traces."
  :type 'string)

(defcustom evil-traces-idle-delay 0.05
  "The idle delay, in seconds, before evil-traces should update."
  :type 'float)

(defcustom evil-traces-suspend-function #'ignore
  "A zero-argument function that returns if highlighting should be suspended."
  :type 'function)

(defcustom evil-traces-enable-echo t
  "Whether to echo warnings and information."
  :type 'boolean)

(defcustom evil-traces-join-indicator "<<<"
  "The indicator for :join.
This will be placed at the end of each line that will be joined with
the next."
  :type 'string)

(defcustom evil-traces-join-indicator-padding 2
  "The number of spaces to add before :join's indicator."
  :type 'integer)

;; * General Functions
;; ** Changing Faces
(defun evil-traces-use-diff-faces ()
  "Use `diff-mode' faces for evil-traces."
  (require 'diff-mode)
  ;; Setting :sort's face can be kind of distracting.
  (custom-set-faces
   '(evil-traces-change           ((t (:inherit diff-removed))))
   '(evil-traces-copy-preview     ((t (:inherit diff-added))))
   '(evil-traces-copy-range       ((t (:inherit diff-changed))))
   '(evil-traces-delete           ((t (:inherit diff-removed))))
   '(evil-traces-global-match     ((t (:inherit diff-added))))
   '(evil-traces-global-range     ((t (:inherit diff-changed))))
   '(evil-traces-join-indicator   ((t (:inherit diff-added))))
   '(evil-traces-join-range       ((t (:inherit diff-changed))))
   '(evil-traces-move-preview     ((t (:inherit diff-added))))
   '(evil-traces-move-range       ((t (:inherit diff-removed))))
   '(evil-traces-normal           ((t (:inherit diff-changed))))
   '(evil-traces-shell-command    ((t (:inherit diff-changed))))
   '(evil-traces-substitute-range ((t (:inherit diff-changed))))
   '(evil-traces-yank             ((t (:inherit diff-changed)))))
  (custom-set-faces
   '(evil-ex-substitute-matches
     ((t (:inherit diff-removed :foreground unspecified :background unspecified))))
   '(evil-ex-substitute-replacement
     ((t (:inherit diff-added :foreground unspecified :background unspecified))))))

(defun evil-traces-use-diff-refine-faces ()
  "Use `diff-mode' refine faces for evil-traces."
  (require 'diff-mode)
  (custom-set-faces
   '(evil-traces-change           ((t (:inherit diff-refine-removed))))
   '(evil-traces-copy-preview     ((t (:inherit diff-refine-added))))
   '(evil-traces-copy-range       ((t (:inherit diff-refine-changed))))
   '(evil-traces-delete           ((t (:inherit diff-refine-removed))))
   '(evil-traces-global-match     ((t (:inherit diff-refine-added))))
   '(evil-traces-global-range     ((t (:inherit diff-refine-changed))))
   '(evil-traces-join-indicator   ((t (:inherit diff-refine-added))))
   '(evil-traces-join-range       ((t (:inherit diff-refine-changed))))
   '(evil-traces-move-preview     ((t (:inherit diff-refine-added))))
   '(evil-traces-move-range       ((t (:inherit diff-refine-removed))))
   '(evil-traces-normal           ((t (:inherit diff-refine-changed))))
   '(evil-traces-shell-command    ((t (:inherit diff-refine-changed))))
   '(evil-traces-substitute-range ((t (:inherit diff-refine-changed))))
   '(evil-traces-yank             ((t (:inherit diff-refine-changed)))))
  (custom-set-faces
   '(evil-ex-substitute-matches
     ((t (:inherit diff-refine-removed :foreground unspecified :background unspecified))))
   '(evil-ex-substitute-replacement
     ((t (:inherit diff-refine-added :foreground unspecified :background unspecified))))))

;; ** Echo
(defun evil-traces--echo (string &rest args)
  "Echo STRING formatted with ARGS if `evil-traces-enable-echo' is non-nil."
  (when evil-traces-enable-echo
    (apply #'evil-ex-echo string args)))

;; ** Overlays
(defvar evil-traces--highlights (make-hash-table)
  "A table where the keys are names and values are lists of overlays.")

(defun evil-traces--set-hl (name range &rest props)
  "Set the highlight named NAME onto RANGE.
RANGE may be a (beg . end) pair or a list of such pairs.
PROPS is an overlay property list."
  (let ((ranges (if (numberp (cl-first range)) (list range) range))
        (overlays (gethash name evil-traces--highlights))
        new-overlays)
    (dolist (range ranges)
      (let ((ov (or (pop overlays) (make-overlay 0 0)))
            (props props))
        (move-overlay ov (car range) (cdr range))
        (while props
          (overlay-put ov (pop props) (pop props)))
        (push ov new-overlays)))
    (mapc #'delete-overlay overlays)
    (puthash name new-overlays evil-traces--highlights)
    new-overlays))

(defun evil-traces--delete-hl (name)
  "Delete the highlight named NAME."
  (mapc #'delete-overlay (gethash name evil-traces--highlights))
  (remhash name evil-traces--highlights))

;; ** Suspension
(defvar evil-traces--suspended nil
  "Whether highlighting is currently suspended.")

(defun evil-traces--reset-state ()
  "Reset any basic evil-traces state."
  (setq evil-traces--suspended nil))

(defmacro evil-traces--with-possible-suspend (body-form &optional suspend-form resume-form)
  "Execute BODY-FORM with a possible suspend.

A suspend happens while `evil-traces-suspend-function' returns
non-nil, and during one, BODY-FORM will not be executed.

SUSPEND-FORM will be executed every time a suspend starts, and
RESUME-FORM will be executed every time a suspend ends."
  (declare (indent 1))
  `(if (funcall evil-traces-suspend-function)
       (unless evil-traces--suspended
         ,suspend-form
         (setq evil-traces--suspended t))
     (when evil-traces--suspended
       ,resume-form
       (setq evil-traces--suspended nil))
     ,body-form))

;; ** Timer
(defvar evil-traces--timer nil
  "The timer for evil-traces updates.")

(defun evil-traces--run-with-ex-values (range cmd bang arg buffer fn &rest args)
  "Run a function with certain `evil-ex' variables set to specified values.
RANGE, CMD, BANG, ARG, and BUFFER will be the values of the
corresponding `evil-ex' variables.  FN is the function to run, and
ARGS is its argument list."
  (let ((evil-ex-range range)
        (evil-ex-cmd cmd)
        (evil-ex-bang bang)
        (evil-ex-argument arg)
        (evil-ex-current-buffer buffer))
    (apply fn args)))

(defun evil-traces--run-timer (fn &rest args)
  "Use evil-traces' timer to run FN with ARGS.
If the timer is currently running, then it is canceled first.  The
variables `evil-ex-range', `evil-ex-cmd', `evil-ex-bang',
`evil-ex-argument', and `evil-ex-current-buffer' will be preserved
automatically."
  (when evil-traces--timer
    (cancel-timer evil-traces--timer))
  (setq evil-traces--timer
        (apply #'run-at-time
               evil-traces-idle-delay
               nil
               #'evil-traces--run-with-ex-values
               evil-ex-range
               evil-ex-cmd
               evil-ex-bang
               evil-ex-argument
               evil-ex-current-buffer
               fn
               args)))

(defun evil-traces--cancel-timer ()
  "Cancel evil-traces' timer if it is currently running."
  (when evil-traces--timer
    (cancel-timer evil-traces--timer)
    (setq evil-traces--timer nil)))

;; ** Windows
(defun evil-traces--window-ranges (buffer)
  "Calculate the ranges covered by BUFFER's active windows."
  (let ((ranges (cl-loop for window in (get-buffer-window-list buffer nil t)
                         collect (cons (window-start window)
                                       (window-end window))))
        combined-ranges)
    (setq ranges (cl-sort ranges #'< :key #'car))
    (while (>= (length ranges) 2)
      (let ((range-1 (pop ranges))
            (range-2 (pop ranges)))
        (if (>= (cdr range-1) (car range-2))
            (push (cons (car range-1) (max (cdr range-1) (cdr range-2))) ranges)
          (push range-1 combined-ranges)
          (push range-2 ranges))))
    (when ranges
      (push (pop ranges) combined-ranges)) ; only one range is left
    (nreverse combined-ranges)))

(defun evil-traces--points-at-visible-bol (beg end)
  "Find the positions of the beginnings of each line between BEG and END."
  (let (positions)
    (dolist (win-range (evil-traces--window-ranges (current-buffer)))
      (let ((subrange-beg (max beg (car win-range)))
            (subrange-end (min end (cdr win-range))))
        (save-excursion
          (goto-char subrange-beg)
          (while (< (point) subrange-end)
            (push (point) positions)
            (forward-line)))))
    (nreverse positions)))

;; * Argument Types
;; ** Definition
(defun evil-traces--update-or-suspend (runner arg)
  "Either update highlighting using RUNNER and ARG, or suspend highlighting.
Highlight suspension is determined by `evil-traces-suspend-function'."
  (evil-traces--with-possible-suspend
      (funcall runner 'update arg)
    (funcall runner 'stop arg)
    (funcall runner 'start arg)))

(defmacro evil-traces-deftype (name runner)
  "Define `evil-ex' argument type NAME with runner function RUNNER.
RUNNER should be a function as described by `evil-ex-define-argument-type'.
evil-traces will automatically create a wrapper around RUNNER that handles
highlight delays and suspension."
  (declare (indent 2))
  (cl-assert (symbolp name))
  (let ((runner-var (cl-gensym "evil-traces--runner-"))
        (flag (cl-gensym "flag-"))
        (arg (cl-gensym "arg-")))
    `(progn
       (evil-ex-define-argument-type ,name
         :runner
         (lambda (,flag &optional ,arg)
           ,(format "Run `%s' with highlight delays and possible suspensions." runner)
           ;; If runner happens to be a lambda, using `let' makes the output
           ;; code nicer, as we don't have to splice runner into multiple
           ;; places.
           (let ((,runner-var #',runner))
             (cl-case ,flag
               (start
                (evil-traces--reset-state)
                (funcall ,runner-var 'start ,arg))
               (update
                (evil-traces--run-timer #'evil-traces--update-or-suspend ,runner-var ,arg))
               (stop
                (evil-traces--cancel-timer)
                (funcall ,runner-var 'stop ,arg)))))))))

;; ** Simple
(defun evil-traces--hl-simple (flag hl-name hl-face &optional default-range)
  "Handle highlighting the range of the current ex command.
FLAG is the typical `evil-ex' argument runner flag.
The highlight will be named HL-NAME and use HL-FACE.
DEFAULT-RANGE may be either 'line or 'buffer."
  (cl-case flag
    (update
     (with-current-buffer evil-ex-current-buffer
       (if-let ((range (or evil-ex-range
                           (cl-case default-range
                             (line (evil-ex-range (evil-ex-current-line)))
                             (buffer (evil-ex-full-range))))))
           (evil-traces--set-hl hl-name
                                (cons (evil-range-beginning range)
                                      (evil-range-end range))
                                'face
                                hl-face)
         (evil-traces--set-hl hl-name nil))))
    (stop
     (evil-traces--delete-hl hl-name))))

(evil-traces-deftype evil-traces-change
    (lambda (flag &optional _arg)
      (evil-traces--hl-simple flag 'evil-traces-change 'evil-traces-change 'line)))

(evil-traces-deftype evil-traces-delete
    (lambda (flag &optional _arg)
      (evil-traces--hl-simple flag 'evil-traces-delete 'evil-traces-delete 'line)))

(evil-traces-deftype evil-traces-normal
    (lambda (flag &optional _arg)
      (evil-traces--hl-simple flag 'evil-traces-normal 'evil-traces-normal 'line)))

(evil-traces-deftype evil-traces-shell-command
    (lambda (flag &optional _arg)
      (evil-traces--hl-simple flag 'evil-traces-shell-command 'evil-traces-shell-command)))

(evil-traces-deftype evil-traces-yank
    (lambda (flag &optional _arg)
      (evil-traces--hl-simple flag 'evil-traces-yank 'evil-traces-yank 'line)))

;; ** Move / Copy
(defun evil-traces--parse-move (arg)
  "Parse ARG into the position where :move will place its text."
  (let ((parsed-arg (evil-ex-parse arg)))
    (when (eq (cl-first parsed-arg) 'evil-goto-line)
      (let* ((address (eval (cl-second parsed-arg))))
        (save-excursion
          (goto-char (point-min))
          (point-at-bol (1+ address)))))))

(defun evil-traces--get-move-text (beg end insert-pos)
  "Obtain the text between BEG and END, adding newlines as necessary for :move.
INSERT-POS is where the text will be inserted."
  (let ((text (buffer-substring beg end)))
    (unless (string-suffix-p "\n" text)
      (setq text (concat text "\n")))
    (save-excursion
      (goto-char insert-pos)
      (when (and (eolp) (not (bolp)))
        (setq text (concat "\n" text))))
    text))

(defun evil-traces--hl-mover (flag
                              arg
                              range-hl-name
                              range-hl-face
                              preview-hl-name
                              preview-hl-face)
  "Highlight a :move type command's range and preview its result.

FLAG ('start, 'update, or 'stop) signals what to do.
ARG is the command's ex argument.

RANGE-HL-NAME, RANGE-HL-FACE, PREVIEW-HL-NAME, PREVIEW-HL-FACE are the
names and faces to use for the command's range and preview
highlights."
  (cl-case flag
    (update
     (with-current-buffer evil-ex-current-buffer
       (let* ((range (or evil-ex-range (evil-ex-range (evil-ex-current-line))))
              (beg (evil-range-beginning range))
              (end (evil-range-end range)))
         (evil-traces--set-hl range-hl-name (cons beg end) 'face range-hl-face)
         (if-let ((insert-pos (evil-traces--parse-move arg)))
             (let ((move-text (evil-traces--get-move-text beg end insert-pos)))
               (evil-traces--set-hl preview-hl-name
                                    (cons insert-pos insert-pos)
                                    'before-string
                                    (propertize move-text 'face preview-hl-face)))
           (evil-traces--echo "Invalid address")))))
    (stop
     (evil-traces--delete-hl range-hl-name)
     (evil-traces--delete-hl preview-hl-name))))

(evil-traces-deftype evil-traces-move
    (lambda (flag &optional arg)
      (evil-traces--hl-mover flag
                             arg
                             'evil-traces-move-range
                             'evil-traces-move-range
                             'evil-traces-move-preview
                             'evil-traces-move-preview)))

(evil-traces-deftype evil-traces-copy
    (lambda (flag &optional arg)
      (evil-traces--hl-mover flag
                             arg
                             'evil-traces-copy-range
                             'evil-traces-copy-range
                             'evil-traces-copy-preview
                             'evil-traces-copy-preview)))

;; ** Global
(defvar evil-traces--last-global-params nil
  "The last parameters passed to :global.")

(defun evil-traces--global-matches (pattern beg end)
  "Return the bounds of each match of PATTERN between BEG and END."
  (when pattern
    (let ((case-fold-search (eq (evil-ex-regex-case pattern evil-ex-search-case)
                                'insensitive)))
      (save-excursion
        (save-match-data
          (cl-loop for pos in (evil-traces--points-at-visible-bol beg end)
                   when (progn
                          (goto-char pos)
                          (re-search-forward pattern (point-at-eol) t))
                   collect (cons (match-beginning 0) (match-end 0))))))))

(defun evil-traces--hl-global (flag &optional arg)
  "Highlight :global's range and every visible match of its pattern.
FLAG is one of 'start, 'update, or 'stop and signals what to do.
ARG is :global's ex argument."
  (cl-case flag
    (start
     (setq evil-traces--last-global-params nil))
    (update
     (condition-case error-info
         (with-current-buffer evil-ex-current-buffer
           (let* ((range (or evil-ex-range (evil-ex-full-range)))
                  (beg (evil-range-beginning range))
                  (end (evil-range-end range))
                  ;; don't use last pattern if argument is nil or "/"
                  (pattern (and (> (length arg) 1)
                                (cl-first (evil-ex-parse-global arg))))
                  (params (list pattern range)))
             (unless (equal evil-traces--last-global-params params)
               (evil-traces--set-hl 'evil-traces-global-range
                                    (cons beg end)
                                    'face
                                    'evil-traces-global-range)
               (evil-traces--set-hl 'evil-traces-global-matches
                                    (evil-traces--global-matches pattern beg end)
                                    'face
                                    'evil-traces-global-match)
               (setq evil-traces--last-global-params params))))
       (user-error
        (evil-traces--echo (cl-second error-info)))
       (invalid-regexp
        (evil-traces--echo (cl-second error-info)))))
    (stop
     (evil-traces--delete-hl 'evil-traces-global-range)
     (evil-traces--delete-hl 'evil-traces-global-matches))))

(evil-traces-deftype evil-traces-global evil-traces--hl-global)

;; ** Join
(defun evil-traces--join-indicator-positions (beg end)
  "Find where to place :join's indicators.
BEG and END define the range of the lines to join."
  (or (save-excursion
        (cl-loop for pos in (evil-traces--points-at-visible-bol beg end)
                 do (goto-char pos)
                 when (/= (point-at-bol 2) end)
                 collect (point-at-eol)))
      (list (save-excursion
              (goto-char beg)
              (point-at-eol)))))

;; We need to differentiate between indicators inside and outside
;; `evil-ex-range' so that the background color isn't messed up.
(defun evil-traces--place-join-indicators (in-positions &optional out-positions)
  "Place :join's line indicators.
IN-POSITIONS are positions within the current ex range.
OUT-POSITIONS are positions outside the current ex range."
  (let ((padding (make-string evil-traces-join-indicator-padding ?\s)))
    (dolist (settings (list (list in-positions
                                  'evil-traces-join-in-indicators
                                  'evil-traces-join-range)
                            (list out-positions
                                  'evil-traces-join-out-indicators
                                  'default)))
      (cl-destructuring-bind (positions hl-name padding-face) settings
        (evil-traces--set-hl hl-name
                             (cl-loop for pos in positions
                                      collect (cons pos pos))
                             'after-string
                             (concat
                              (propertize padding 'face padding-face)
                              (propertize evil-traces-join-indicator
                                          'face
                                          'evil-traces-join-indicator)))))))

(defun evil-traces--hl-join (flag &optional arg)
  "Highlight the range covered by a :join command.
FLAG is one of 'start, 'update, or 'stop and signals what to do.
ARG is :join's ex argument."
  (cl-case flag
    (update
     (with-current-buffer evil-ex-current-buffer
       (let* ((range (or evil-ex-range (evil-ex-range (evil-ex-current-line))))
              (beg (evil-range-beginning range))
              (end (evil-range-end range)))
         (evil-traces--set-hl
          'evil-traces-join-range (cons beg end) 'face 'evil-traces-join-range)
         (cond
          ((not arg)
           (evil-traces--place-join-indicators
            (evil-traces--join-indicator-positions beg end)))
          ((string-match-p "^[1-9][0-9]*$" arg)
           (let ((indicator-positions
                  (save-excursion
                    (goto-char end)
                    (evil-traces--join-indicator-positions
                     (point-at-bol 0)
                     (point-at-bol (string-to-number arg))))))
             (evil-traces--place-join-indicators (list (pop indicator-positions))
                                                 indicator-positions)))
          (t
           (evil-traces--echo "Invalid count"))))))
    (stop
     (evil-traces--delete-hl 'evil-traces-join-range)
     (evil-traces--delete-hl 'evil-traces-join-in-indicators)
     (evil-traces--delete-hl 'evil-traces-join-out-indicators))))

(evil-traces-deftype evil-traces-join evil-traces--hl-join)

;; ** Sort
(defun evil-traces--sort-option-p (option)
  "Check if OPTION is a valid :sort option."
  (memq option '(?i ?u)))

(defun evil-traces--hl-sort (flag &optional arg)
  "Preview the results of :sort.
FLAG is one of 'start, 'update, or 'stop and signals what to do, while ARG is
:sort's ex argument.  If the variable `evil-ex-range' is nil, no preview is
shown."
  (cl-case flag
    (update
     (with-current-buffer evil-ex-current-buffer
       (cond
        ((and arg
              (cl-notevery #'evil-traces--sort-option-p
                           (string-to-list arg)))
         (evil-traces--echo "Invalid option"))
        ((not evil-ex-range)
         (evil-traces--set-hl 'evil-traces-sort nil))
        (t
         (let* ((beg (evil-range-beginning evil-ex-range))
                (end (evil-range-end evil-ex-range))
                (lines (buffer-substring beg end))
                (sorted-lines (with-temp-buffer
                                (insert lines)
                                ;; hide "Reordering buffer... Done"
                                (let ((inhibit-message t))
                                  (evil-ex-sort (point-min)
                                                (point-max)
                                                arg
                                                evil-ex-bang))
                                (buffer-string))))
           (evil-traces--set-hl 'evil-traces-sort
                                (cons beg end)
                                'face
                                'evil-traces-sort
                                'display
                                sorted-lines))))))
    (stop
     (evil-traces--delete-hl 'evil-traces-sort))))

(evil-traces-deftype evil-traces-sort evil-traces--hl-sort)

;; ** Substitute
(defun evil-traces--evil-substitute-runner (flag &optional arg)
  "Call evil's :substitute runner with FLAG and ARG."
  (when-let ((runner (evil-ex-argument-handler-runner
                      (alist-get 'substitution evil-ex-argument-types))))
    (funcall runner flag arg)))

(defun evil-traces--hl-substitute (flag &optional arg)
  "Preview the :substitute command.
FLAG is one of 'start, 'update, or 'stop and signals what to do.
ARG is :substitute's ex argument."
  (cl-case flag
    (start
     (evil-traces--evil-substitute-runner 'start arg))
    (update
     (with-current-buffer evil-ex-current-buffer
       (let ((range (or evil-ex-range (evil-ex-range (evil-ex-current-line)))))
         (evil-traces--set-hl 'evil-traces-substitute-range
                              (cons (evil-range-beginning range)
                                    (evil-range-end range))
                              'face
                              'evil-traces-substitute-range))
       (let ((evil-ex-hl-update-delay 0))
         (evil-traces--evil-substitute-runner 'update arg))))
    (stop
     (evil-traces--evil-substitute-runner 'stop arg)
     (evil-traces--delete-hl 'evil-traces-substitute-range))))

(evil-traces-deftype evil-traces-substitute evil-traces--hl-substitute)

;; * Minor Mode
(defvar evil-traces--old-argument-types-alist nil
  "An alist mapping `evil-ex' function to their old argument types.
This is used to restore the appropriate argument types when
evil-traces is turned off.")

(defun evil-traces--register-argument-types ()
  "Register evil-traces' argument types with `evil-ex'."
  ;; `add-to-list' adds elements to the front of the list by default.
  ;; We iterate in reverse order so those first elements take precedence.
  (dolist (type-desc (reverse evil-traces-argument-type-alist))
    (cl-destructuring-bind (fn . type) type-desc
      (when-let ((old-type (evil-get-command-property fn :ex-arg)))
        (add-to-list 'evil-traces--old-argument-types-alist (cons fn old-type)))
      (evil-set-command-property fn :ex-arg type))))

(defun evil-traces--unregister-argument-types ()
  "Unregister evil-traces' argument types from `evil-ex'."
  (dolist (type-desc evil-traces-argument-type-alist)
    (evil-remove-command-properties (car type-desc) :ex-arg))
  (dolist (old-type-desc evil-traces--old-argument-types-alist)
    (evil-set-command-property (car old-type-desc) :ex-arg (cdr old-type-desc)))
  (setq evil-traces--old-argument-types-alist nil))

;;;###autoload
(define-minor-mode evil-traces-mode
  "Global minor mode for evil-traces."
  :global t
  :lighter evil-traces-lighter
  (if evil-traces-mode
      (evil-traces--register-argument-types)
    (evil-traces--unregister-argument-types)))

;; * End
(provide 'evil-traces)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; evil-traces.el ends here
