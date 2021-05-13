;;; jammer.el --- Punish yourself for using Emacs inefficiently

;; Copyright (C) 2015 Vasilij Schneidermann <mail@vasilij.de>

;; Author: Vasilij Schneidermann <mail@vasilij.de>
;; URL: https://depp.brause.cc/jammer
;; Package-Version: 20210508.1633
;; Package-Commit: a780e4c2adb2e85a4daadcefd1a2b189d761872f
;; Version: 0.1.2
;; Package-Requires: ((emacs "24.1"))
;; Keywords: games

;; This file is NOT part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This global minor mode allows you to slow down command execution
;; globally in Emacs.

;; See the README for more info: https://depp.brause.cc/jammer

;;; Code:


;;; variables

(defgroup jammer nil
  "Punish yourself for using Emacs inefficiently"
  :group 'games
  :prefix "jammer-")

(defcustom jammer-block-type 'whitelist
  "Block list type for `jammer-block-list'.
When set to 'blacklist, only affect the items of
`jammer-block-list'.  When set to 'whitelist, affect everything
except the items of `jammer-block-list'."
  :type '(choice (const :tag "Blacklist" blacklist)
                 (const :tag "Whitelist" whitelist))
  :group 'jammer)

(defcustom jammer-block-list '()
  "List of exclusively affected or exempt commands.
The behaviour is set by `jammer-block-type'."
  :type '(repeat symbol)
  :group 'jammer)

(defcustom jammer-type 'repeat
  "Type of blocking.

'repeat: Block repeated key strokes.

'constant: Slow everything down.

'random: Slow down or misfire randomly."
  :type '(choice (const :tag "Repeat" repeat)
                 (const :tag "Constant" constant)
                 (const :tag "Random" random))
  :group 'jammer)

(defcustom jammer-repeat-type 'constant
  "Type of slowdown.

'constant:  Constant delay.

'linear:    Delay increases by repetition count.

'quadratic: Delay increases by repetition count squared."
  :type '(choice (const :tag "Constant" constant)
                 (const :tag "Linear" linear)
                 (const :tag "Quadratic" quadratic))
  :group 'jammer)

(defcustom jammer-repeat-delay 0.05
  "Base delay value in seconds.
Applies to a value of 'repeat for `jammer-repeat-type'."
  :type 'float
  :group 'jammer)

(defcustom jammer-repeat-window 0.1
  "Repetition window in seconds.
An event happening in less seconds than this value will be
counted as repetition."
  :type 'float
  :group 'jammer)

(defcustom jammer-repeat-allowed-repetitions 1
  "Maximum value of allowed repetitions.
Events detected as repetitions are not taken into account if the
repetition count is smaller or equal to this value."
  :type 'integer
  :group 'jammer)

(defvar jammer-repeat-state [[] 0 0.0]
  "Internal state of last repeated event.
The first element is the last event as returned by
`this-command-keys-vector', the second is its repetition count,
the third its floating point timestamp as returned by
`float-time'.")

(defcustom jammer-constant-delay 0.04
  "Base delay value in seconds.
Applies to a value of 'constant for `jammer-repeat-type'."
  :type 'float
  :group 'jammer)

(defcustom jammer-random-delay 0.01
  "Base delay value in seconds.
Applies to a value of 'random for `jammer-repeat-type'."
  :type 'float
  :group 'jammer)

(defcustom jammer-random-probability 0.05
  "Probability for a random action to happen.
It has to be a floating point number between 0 and 1."
  :type 'float
  :group 'jammer)

(defcustom jammer-random-slowdown-probability 0.5
  "Probability for the random action to be a slowdown.
It has to be a floating point number between 0 and 1.  The other
allowed action is misfiring, this simply repeats the events
making up the current command.")

(defvar jammer-random-minimum-probability 0.01
  "Minimum allowed probability for a random action.")

(defvar jammer-random-maximum-probability 1.0
  "Maximum allowed probability for a random action.")

(defcustom jammer-random-amplification 10
  "Amplification span of the random delay.
The base delay can be amplified with a random factor up to this
value."
  :type 'integer
  :group 'jammer)


;;; helpers

(defun jammer-toss (p)
  "Given probability P, do a toss.
If the toss is successful, return t, otherwise nil.  P must be a
floating point number between 0 and 1, values outside this
range are clamped to 0 or 1."
  (cond
   ((>= p 1) t)
   ((<= p 0) nil)
   (t (if (= (random (round (/ 1 p))) 0)
          t
        nil))))

(defun jammer-delay (time)
  "Sleep for TIME, discard any input made in that time.
Returns a truthy value after sleep."
  (sleep-for time)
  (discard-input)
  t)

(defun jammer-misfire ()
  "Repeat events used to invoke the current command."
  (setq unread-command-events
        (append (listify-key-sequence (this-command-keys-vector))
                unread-command-events)))


;;; frontend

(defun jammer ()
  "Slow down command execution.
The general behaviour is determined by `jammer-type'."
  (when (or (and (eq jammer-block-type 'whitelist)
                 (not (memq this-command jammer-block-list)))
            (and (eq jammer-block-type 'blacklist)
                 (memq this-command jammer-block-list)))
    (cond
     ((eq jammer-type 'repeat)
      (jammer-repeat))
     ((eq jammer-type 'constant)
      (jammer-constant))
     ((eq jammer-type 'random)
      (jammer-random)))))

(defun jammer-repeat ()
  "Jam after repeated key strokes."
  (let ((window (- (float-time) (aref jammer-repeat-state 2))))
    ;; did a different key event happen or enough time pass?
    (if (or (not (equal (this-command-keys-vector)
                        (aref jammer-repeat-state 0)))
            (> window jammer-repeat-window))
        ;; if yes, reset the counter
        (aset jammer-repeat-state 1 0)
      ;; otherwise increment it
      (aset jammer-repeat-state 1 (1+ (aref jammer-repeat-state 1))))
    ;; if too little time passed, sleep for the delay calculated
    ;; earlier
    (when (and (>= (aref jammer-repeat-state 1)
                   jammer-repeat-allowed-repetitions)
               (< window jammer-repeat-window))
      (jammer-delay (jammer-repeat-delay jammer-repeat-type))))
  ;; do book keeping for the next command
  (aset jammer-repeat-state 0 (this-command-keys-vector))
  (aset jammer-repeat-state 2 (float-time)))

(defun jammer-repeat-delay (type)
  "Calculate the delay depending on TYPE.
See `jammer-repeat-type' for valid values of TYPE.  Any other
value is interpreted as a delay of zero."
  (cond
   ((eq type 'constant)
    jammer-repeat-delay)
   ((eq type 'linear)
    (* (- (aref jammer-repeat-state 1)
          jammer-repeat-allowed-repetitions)
       jammer-repeat-delay))
   ((eq type 'quadratic)
    (* (expt (- (aref jammer-repeat-state 1)
                jammer-repeat-allowed-repetitions)
             2)
       jammer-repeat-delay))
   (t 0)))

(defun jammer-constant ()
  "Jam a constant time.
See `jammer-constant-delay' for the tunable."
  (jammer-delay jammer-constant-delay))

(defun jammer-random ()
  "Jam for a random time or misfire.
See `jammer-random-probability',
`jammer-random-slowdown-probability',
`jammer-random-amplification' and `jammer-random-delay' for
tunables."
  ;; this function simulates a rare event, then amplifies it randomly
  (when (jammer-toss jammer-random-probability)
    (if (jammer-toss jammer-random-slowdown-probability)
        (jammer-delay (* (1+ (random jammer-random-amplification))
                         jammer-random-delay))
      (jammer-misfire))))

;;;###autoload
(define-minor-mode jammer-mode
  "Toggle `jammer-mode'.
This global minor mode allows you to slow down command execution
globally in Emacs."
  :global t
  (if jammer-mode
      ;; TODO: is this correct? wouldn't `pre-command-hook' be better?
      (add-hook 'post-command-hook 'jammer)
    (remove-hook 'post-command-hook 'jammer)))

(provide 'jammer)
;;; jammer.el ends here
