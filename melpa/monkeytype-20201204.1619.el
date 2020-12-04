;;; monkeytype.el --- Mode for speed/touch typing -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Pablo Barrantes

;; Author: Pablo Barrantes <xjpablobrx@gmail.com>
;; Maintainer: Pablo Barrantes <xjpablobrx@gmail.com>
;; Version: 0.1.3
;; Package-Version: 20201204.1619
;; Package-Commit: 3c6be78a1dfe87b430d860c23978ac0d31b44ea9
;; Keywords: games
;; URL: https://github.com/jpablobr/emacs-monkeytype
;; Package-Requires: ((emacs "25.1"))

;;; Commentary:

;; Emacs Monkeytype is a typing game/tutor inspired by monkeytype.com but for
;; Emacs.

;; Features:

;; - Type any text you want.

;; - Mode-line live WPM (`monkeytype-mode-line-interval-update' adjust the
;; update frequency).

;; - Visual representation of typed text including errors and
;; retries/corrections.

;; - Auto stop after 5 seconds of no input (`C-c C-c r` [`monkeytype-resume']
;; resumes).

;; - Optionally randomise practice words/transitions (see:
;; `monkeytype-randomize').

;; - Optionally downcase practice words/transitions (see:
;; `monkeytype-downcase').

;; - Optionally treat newlines as whitespace (see:
;; `monkeytype-treat-newline-as-space').

;; - Optionally auto-fill text to the defaults `fill-column' value (see:
;; `monkeytype-auto-fill').

;; - Select a region of text and treat it as words for practice (e.i.,
;; optionally downcased, randomised, etc... see: `monkeytype-region-as-words').

;; - After a test, practice troubling/hard key combinations/transitions (useful
;; when practising with different keyboard layouts).

;; - Mistyped words or hard transitions can be saved to `~/.monkeytype/{words or
;; transitions}` (see: `monkeytype-directory' `monkeytype-save-mistyped-words'
;; `monkeytype-save-hard-transitions').

;; - Saved mistyped/transitions files (or any file but defaults to
;; `~/.monkeytype/` dir) can be loaded with `monkeytyped-load-words-from-file'.

;; - `monkeytype-excluded-chars-regexp' customises the regexp used for removing
;; characters from words (defaults to: "[^[:alnum:]']").

;; - Ability to type most (saved) mistyped words (the amount of words is
;; configurable with `monkeytype-most-mistyped-amount' [defaults to 100]) see:
;; `monkeytype-most-mistyped-words'

;;; License:

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free Software
;; Foundation, either version 2 of the License, or (at your option) any later
;; version.

;; This program is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
;; FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
;; details.

;; You should have received a copy of the GNU General Public License along with
;; this program. If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'subr-x)

;;;; Customization

(defgroup monkeytype nil
  "Speed/touch typing."
  :group 'games
  :tag "Monkeytype"
  :link '(
          url-link
          :tag
          "GitHub" "https://github.com/jpablobr/emacs-monkeytype"))

(defgroup monkeytype-faces nil
  "Faces used by Monkeytype."
  :group 'monkeytype
  :group 'faces)

(defface monkeytype-default
  '((t :inherit default))
  "Face for text area."
  :group 'monkeytype-faces)

(defface monkeytype-correct
  '((t :inherit font-lock-comment-face))
  "Face for correctly typed char."
  :group 'monkeytype-faces)

(defface monkeytype-error
  '((t (
        :foreground "#cc6666"
        :underline (:color "#cc6666" :style wave))))
  "Face for wrongly typed char."
  :group 'monkeytype-faces)

(defface monkeytype-correction-error
  '((t (
        :inherit region
        :foreground "#ff6c6b"
        :underline (:color "#ff6c6b" :style wave))))
  "Face for wrongly typed correction."
  :group 'monkeytype-faces)

(defface monkeytype-correction-correct
  '((t (:inherit region :foreground "#b9ca4a")))
  "Face for correctly typed correction."
  :group 'monkeytype-faces)

(defface monkeytype-title
  '((t :inherit default))
  "Face for results titles."
  :group 'monkeytype-faces)

(defface monkeytype-legend-1
  '((t :inherit font-lock-warning-face))
  "Face for results legend 1."
  :group 'monkeytype-faces)

(defface monkeytype-legend-2
  '((t :inherit font-lock-doc-face :height 0.9))
  "Face for results legend 2."
  :group 'monkeytype-faces)

(defface monkeytype-results-success
  '((t (:foreground "#98be65" :height 0.9)))
  "Face for results success text."
  :group 'monkeytype-faces)

(defface monkeytype-results-error
  '((t (:foreground "#cc6666" :height 0.9)))
  "Face for results error text."
  :group 'monkeytype-faces)

(defface monkeytype-mode-line-success
  '((t (:foreground "#98be65")))
  "Face for mode-line success text."
  :group 'monkeytype-faces)

(defface monkeytype-mode-line-error
  '((t (:foreground "#ff6c6b")))
  "Face for mode-line error text."
  :group 'monkeytype-faces)

(defface monkeytype-mode-line-normal
  '((t :inherit mode-line-buffer-id))
  "Face for mode-line normal text."
  :group 'monkeytype-faces)

(defface monkeytype-mode-line-info
  '((t (:foreground "#B7950B")))
  "Face for mode-line info text."
  :group 'monkeytype-faces)

;;;; Configurable Settings:

(defcustom monkeytype-treat-newline-as-space t
  "Allow continuing to the next line by pressing space."
  :type 'boolean
  :group 'monkeytype)

(defcustom monkeytype-insert-log nil
  "Show log in results section."
  :type 'boolean
  :group 'monkeytype)

(defcustom monkeytype-minimum-transitions 50
  "Minimum amount of transitions to practice."
  :type 'integer
  :group 'monkeytype)

(defcustom monkeytype-mode-line '(:eval (monkeytype--mode-line-text))
  "Monkeytype mode line."
  :group 'monkeytype
  :type 'sexp
  :risky t)

(defcustom monkeytype-mode-line-interval-update 1
  "Number of keystrokes after each mode-line update.

Reducing the frequency of the updates helps reduce lagging on longer text or
when typing too fast."
  :type 'integer
  :group 'monkeytype)

(defcustom monkeytype-word-divisor 5.0
  "5 is the most common number for these calculations.

Proper word count doesn't work as well since words have different number
of characters. This also makes calculations easier and more accurate."
  :type 'integer
  :group 'monkeytype)

(defcustom monkeytype-auto-fill nil
  "Toggle auto fill for typing text.

Defaults `fill-column' setting
See also: `monkeytype-words-auto-fill'"
  :type 'boolean
  :group 'monkeytype)

(defcustom monkeytype-words-auto-fill t
  "Toggle auto fill for words/transitions.

It defaults `fill-column' setting. See: `monkeytype-auto-fill'"
  :type 'boolean
  :group 'monkeytype)

(defcustom monkeytype-delete-trailing-whitespace t
  "Toggle delete trailing whitespace."
  :type 'boolean
  :group 'monkeytype)

(defcustom monkeytype-downcase t
  "Toggle downcasing of mistyped words."
  :type 'boolean
  :group 'monkeytype)

(defcustom monkeytype-directory "~/.monkeytype/"
  "Monkeytype directory."
  :type 'string
  :group 'monkeytype)

(defcustom monkeytype-randomize t
  "Toggle randomizing of words."
  :type 'boolean
  :group 'monkeytype)

(defcustom monkeytype-excluded-chars-regexp "[^[:alnum:]']"
  "Regexp used for getting valid words."
  :type 'string
  :group 'monkeytype)

(defcustom monkeytype-most-mistyped-amount 100
  "Amount of words in most mistyped words test."
  :type 'boolean
  :group 'monkeytype)

;;;; Init:

(defvar-local monkeytype--buffer-name "*Monkeytype*")
(defvar-local monkeytype--run-list '())
(defvar-local monkeytype--start-time nil)
(defvar monkeytype--typing-buffer nil)
(defvar monkeytype--source-text "")

;; Status
(defvar-local monkeytype--status-finished nil)
(defvar-local monkeytype--status-paused nil)

;; Counters
(defvar-local monkeytype--counter-entries 0)
(defvar-local monkeytype--counter-input 0)
(defvar-local monkeytype--counter-error 0)
(defvar-local monkeytype--counter-correction 0)
(defvar-local monkeytype--counter-remaining 0)
(defvar-local monkeytype--counter-ignored-change 0)

;; Run
(defvar-local monkeytype--progress-tracker "")
(defvar-local monkeytype--current-run-list '())
(defvar-local monkeytype--current-entry '())
(defvar-local monkeytype--current-run-start-datetime nil)

;; Results
(defvar-local monkeytype--previous-last-entry-index nil)
(defvar-local monkeytype--previous-run-last-entry nil)
(defvar-local monkeytype--previous-run '())

(defun monkeytype--init (text)
  "Set up a new buffer for the typing exercise on TEXT."
  (setq monkeytype--typing-buffer
        (generate-new-buffer monkeytype--buffer-name))
  (set-buffer monkeytype--typing-buffer)
  (setq monkeytype--source-text text)
  (setq monkeytype--counter-remaining (length text))
  (setq monkeytype--progress-tracker (make-string (length text) 0))
  (erase-buffer)
  (insert monkeytype--source-text)
  (set-buffer-modified-p nil)
  (switch-to-buffer monkeytype--typing-buffer)
  (goto-char 0)
  (monkeytype-mode)
  (message "Monkeytype: Timer will start when you type the first character."))

;;;; Utils:

(defvar-local monkeytype--chars-list '())
(defvar-local monkeytype--words-list '())
(defvar-local monkeytype--mistyped-words-list '())
(defvar-local monkeytype--chars-to-words-list '())
(defvar-local monkeytype--hard-transition-list '())

(defun monkeytype--utils-nshuffle (sequence)
  "Shuffle given SEQUENCE.

URL `https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle'"
  (cl-loop for i from (length sequence) downto 2
           do (cl-rotatef (elt sequence (random i))
                          (elt sequence (1- i))))
  sequence)

(defun monkeytype--utils-local-idle-timer (secs repeat function &rest args)
  "Like `run-with-idle-timer', but always run in `current-buffer'.

Cancels itself, if this buffer is killed or after 5 SECS.
REPEAT FUNCTION ARGS."
  (let* ((fns (make-symbol "local-idle-timer"))
         (timer (apply #'run-with-idle-timer secs repeat fns args))
         (fn `(lambda (&rest args)
                (if (or
                     monkeytype--status-paused
                     monkeytype--status-finished
                     (not (buffer-live-p ,(current-buffer))))
                    (cancel-timer ,timer)
                  (with-current-buffer ,(current-buffer)
                    (apply (function ,function) args))))))
    (defalias fns fn)
    fn))

(defun monkeytype--utils-file-path (type)
  "Build path for the TYPE of file to be saved."
  (unless (file-exists-p monkeytype-directory)
    (make-directory monkeytype-directory))

  (concat
   monkeytype-directory
   (format "%s/" type)
   (format "%s" (downcase (format-time-string "%a-%d-%b-%Y-%H-%M-%S")))
   ".txt"))

(defun monkeytype--utils-elapsed-seconds ()
  "Return float with the total time since start."
  (let ((end-time (float-time)))
    (if monkeytype--start-time
        (- end-time monkeytype--start-time)
      0)))

(defun monkeytype--utils-check-same (source typed)
  "Return non-nil if both SOURCE and TYPED are white space or the same."
  (if monkeytype-treat-newline-as-space
      (or (string= source typed)
          (and
           (= (char-syntax (aref source 0)) ?\s)
           (= (char-syntax (aref typed 0)) ?\s)))
    (string= source typed)))

(defun monkeytype--utils-seconds-to-minutes (seconds)
  "Return minutes in float for SECONDS."
  (/ seconds 60.0))

(defun monkeytype--utils-index-words ()
  "Index words."
  (let ((words (split-string
                monkeytype--source-text
                monkeytype-excluded-chars-regexp))
         (index 1))
    (dolist (word words)
      (add-to-list 'monkeytype--words-list `(,index . ,word))
      (setq index (1+ index)))))

(defun monkeytype--utils-index-chars-to-words ()
  "Associate by index cars to words."
  (let ((chars (mapcar #'char-to-string monkeytype--source-text))
         (word-index 1)
         (char-index 1))
    (dolist (char chars)
      (if (string-match monkeytype-excluded-chars-regexp char)
          (progn
            (setq word-index (1+ word-index))
            (setq char-index (1+ char-index)))
        (let ((word (cdr (assoc word-index monkeytype--words-list))))
          (add-to-list
           'monkeytype--chars-to-words-list
           `(,char-index . ,word))
          (setq char-index (1+ char-index)))))))

(defun monkeytype--utils-index-chars (run)
  "RUN Index chars."
  (unless monkeytype--previous-last-entry-index
    (setq monkeytype--previous-last-entry-index 0))

  (let* ((first-entry-index monkeytype--previous-last-entry-index)
         (last-entry (elt (gethash "entries" run) 0))
         (source-text (substring
                       monkeytype--source-text
                       first-entry-index
                       (gethash "source-index" last-entry)))
         (chars (mapcar #'char-to-string source-text))
         (chars-list '())
         (index first-entry-index))
    (dolist (char chars)
      (setq index (1+ index))
      (cl-pushnew `(,index . ,char) chars-list))
    (setq monkeytype--chars-list (reverse chars-list))
    (setq monkeytype--previous-last-entry-index
          (gethash "source-index" (elt (gethash "entries" run) 0)))))

(defun monkeytype--utils-format-words (words)
  "Format WORDS (for test) by applying word related customization settings.

See: `monkeytype-downcase'
See: `monkeytype-randomize'
See: `monkeytype-words-auto-fill'
See: `monkeytype-delete-trailing-whitespace'"
  (let* ((text (mapconcat
                (lambda (word)
                  (if monkeytype-downcase
                      (downcase word)
                    word))
                (if monkeytype-randomize
                    (monkeytype--utils-nshuffle words)
                  words)
                " "))
         (text (with-temp-buffer
                 (insert text)
                 (when monkeytype-words-auto-fill
                   (fill-region (point-min) (point-max)))
                 (when monkeytype-delete-trailing-whitespace
                   (delete-trailing-whitespace))
                 (buffer-string))))
    text))

(defun monkeytype--utils-format-text (text)
  "Format TEXT (for test) by applying customization settings.

See: `monkeytype-auto-fill'
See: `monkeytype-delete-trailing-whitespace'"
  (with-temp-buffer
    (insert text)
    (when monkeytype-auto-fill
      (fill-region (point-min) (point-max)))
    (when monkeytype-delete-trailing-whitespace
      (delete-trailing-whitespace))
    (buffer-string)))

;;;; Calc:

(defun monkeytype--calc-words (chars)
  "Divide all CHARS by `monkeytype-word-divisor'."
  (/ chars monkeytype-word-divisor))

(defun monkeytype--calc-gross-wpm (words minutes)
  "Divides WORDS by MINUTES.

See `monkeytype--calc-words' for WORDS."
  (/ words minutes))

(defun monkeytype--calc-gross-cpm (chars minutes)
  "Divides CHARS by MINUTES."
  (/ chars minutes))

(defun monkeytype--calc-net-wpm (words uncorrected-errors minutes)
  "Net WPM is the gross WPM minus the UNCORRECTED-ERRORS by MINUTES.

See `monkeytype--calc-gross-cpm' for gross WPM.
See `monkeytype--calc-words' for WORDS."
  (let ((net-wpm (- (monkeytype--calc-gross-wpm words minutes)
                    (/ uncorrected-errors minutes))))
    (if (> 0 net-wpm) 0 net-wpm)))

(defun monkeytype--calc-net-cpm (chars uncorrected-errors minutes)
  "Net CPM is the gross CPM minus the UNCORRECTED-ERRORS by MINUTES.

See `monkeytype--calc-gross-cpm' for gross CPM.
UNCORRECTED-ERRORS are re-mistyped CHARS."
  (let ((net-cpm (- (monkeytype--calc-gross-cpm chars minutes)
                    (/ uncorrected-errors minutes))))
    (if (> 0 net-cpm) 0 net-cpm)))

(defun monkeytype--calc-accuracy (chars correct-chars corrections)
  "Accuracy is all CORRECT-CHARS minus CORRECTIONS divided by all CHARS."
  (when (> chars 0)
    (let* ((a-chars (- correct-chars corrections))
           (a-chars (if (> a-chars 0) a-chars 0))
           (accuracy (* (/ a-chars (float chars)) 100.00)))
      accuracy)))

;;;; Process Input:

(defun monkeytype--process-input (region-start region-end delete-length)
  "Process input from REGION-START to REGION-END.

DELETE-LENGTH is the amount of deleted chars in case of deletion."
  (let* ((source-start (1- region-start))
         (source-end (1- region-end))
         (entry (substring-no-properties
                 (buffer-substring region-start region-end)))
         (source (substring monkeytype--source-text source-start source-end))
         (entry-state (aref monkeytype--progress-tracker source-start))
         (correctp (monkeytype--utils-check-same source entry))
         (face-for-entry (monkeytype--typed-text-entry-face correctp))
         ;; No char entered e.g., a command.
         (valid-input (/= region-start region-end)))

    (monkeytype--process-input-restabilize-region
     region-start
     region-end
     entry-state
     delete-length)

    (when valid-input
      (store-substring
       monkeytype--progress-tracker
       source-start
       (if correctp 1 2))

      (cl-incf monkeytype--counter-entries)
      (cl-decf monkeytype--counter-remaining)
      (unless correctp (cl-incf monkeytype--counter-error))

      (set-text-properties
       region-start
       (1+ region-start)
       `(face ,face-for-entry))
      (monkeytype--process-input-add-to-entries source-start entry source)
      (monkeytype--process-input-update-mode-line))

    (goto-char region-end)
    (when (= monkeytype--counter-remaining 0) (monkeytype--run-finish))))

(defun monkeytype--process-input-restabilize-region (start end state deleted)
  "Restabilize current char input region from START to END.

STATE keeps track of text already typed but deleted (e.i., correction).
DELETED is the number of deleted chars before current char input."
  (let* ((source-start (1- start))
         (skippedp (>
                    (+ source-start monkeytype--counter-remaining)
                    (length monkeytype--source-text)) )
         (correctionp (> state 0))
         (deleted-text-p (> deleted 0)))

    ;; On skips update remaining-counter to reflect current position
    (when skippedp
      (setq monkeytype--counter-remaining
            (- (length monkeytype--source-text) source-start)))

    ;; Leaving only the newly typed char
    (delete-region start end)

    (when correctionp
      (monkeytype--process-input-rectify-counters state)

      ;; Reset tracker back to 0 (i.e, new)
      (store-substring monkeytype--progress-tracker source-start 0))

    ;; Re-insert deleted text
    (when deleted-text-p
      (insert (substring
               monkeytype--source-text
               source-start
               (+ source-start deleted))))))

(defun monkeytype--process-input-rectify-counters (entry-state)
  "Update counters on corrections/re-tries based on the ENTRY-STATE.

ENTRY-STATE = 1 correctly re-typed char
ENTRY-STATE = 2 mistyped re-typed char"
  (cond ((= entry-state 1)
         (cl-decf monkeytype--counter-entries)
         (cl-incf monkeytype--counter-remaining))
        ((= entry-state 2)
         (cl-decf monkeytype--counter-entries)
         (cl-incf monkeytype--counter-remaining)
         (cl-decf monkeytype--counter-error)
         (cl-incf monkeytype--counter-correction))))

(defun monkeytype--process-input-add-to-entries (start typed source)
  "Add entry to `monkeytype--current-run-list'.

START is used for indexing purposes.
TYPED is the char input by the user.
SOURCE is the original char."
  (cl-incf monkeytype--counter-input)
  (let ((entry (make-hash-table :test 'equal))
        (seconds (format-seconds
                  "%.2h:%z%.2m:%.2s"
                  (monkeytype--utils-elapsed-seconds))))
    (puthash "input-index" monkeytype--counter-input entry)
    (puthash "typed-entry" typed entry)
    (puthash "source-entry" source entry)
    (puthash "source-index" (1+ start) entry)
    (puthash "error-count" monkeytype--counter-error entry)
    (puthash "correction-count" monkeytype--counter-correction entry)
    (puthash "state" (aref monkeytype--progress-tracker start) entry)
    (puthash "elapsed-seconds" (monkeytype--utils-elapsed-seconds) entry)
    (puthash "formatted-seconds" seconds entry)
    (add-to-list 'monkeytype--current-run-list entry)))

(defun monkeytype--process-input-timer-init ()
  "Start the idle timer (to wait 5 seconds before pausing).

See: `monkeytype--utils-local-idle-timer'"
  (unless monkeytype--start-time
    (setq monkeytype--current-run-start-datetime
          (format-time-string "%a-%d-%b-%Y %H:%M:%S"))
    (setq monkeytype--start-time (float-time))
    (monkeytype--utils-local-idle-timer 5 nil 'monkeytype-pause)))

(defun monkeytype--process-input-update-mode-line ()
  "Update `monkeytype-mode-line' by sending it the current entry info."
  (if monkeytype-mode-line-interval-update
      (let* ((entry (elt monkeytype--current-run-list 0))
             (char-index (if entry (gethash "source-index" entry) 0)))
        (if (and
             (> char-index monkeytype-mode-line-interval-update)
             (= (mod char-index monkeytype-mode-line-interval-update) 0))
            (monkeytype--mode-line-report-status)))))

;;;; Run:

(defun monkeytype--run-pause ()
  "Pause run by resetting hooks and `monkeytype--start-time'."
  (setq monkeytype--start-time nil)
  (monkeytype--run-remove-hooks)
  (monkeytype--run-add-to-list)
  (read-only-mode))

(defun monkeytype--run-finish ()
  "Remove typing hooks and print results."
  (setq monkeytype--status-finished t)

  (unless monkeytype--status-paused
    (setq monkeytype--start-time nil)
    (monkeytype--run-remove-hooks)
    (monkeytype--run-add-to-list))

  (set-buffer-modified-p nil)
  (setq buffer-read-only nil)
  (monkeytype--results)

  (monkeytype--mode-line-report-status)
  (read-only-mode))

(defun monkeytype--run-add-to-list ()
  "Add current run to `monkeytype--run-list'."
  (let ((run (make-hash-table :test 'equal)))
    (puthash "started-at" monkeytype--current-run-start-datetime run)
    (puthash "finished-at" (format-time-string "%a-%d-%b-%Y %H:%M:%S") run)
    (puthash "entries" (vconcat monkeytype--current-run-list) run)
    (add-to-list 'monkeytype--run-list run)))

(defun monkeytype--run-remove-hooks ()
  "Remove hooks."
  (remove-hook 'after-change-functions #'monkeytype--process-input)
  (remove-hook 'first-change-hook #'monkeytype--process-input-timer-init))

(defun monkeytype--run-add-hooks ()
  "Add hooks."
  (make-local-variable 'after-change-functions)
  (make-local-variable 'first-change-hook)
  (add-hook 'after-change-functions #'monkeytype--process-input nil t)
  (add-hook 'first-change-hook #'monkeytype--process-input-timer-init nil t))

;;;; Results:

(defun monkeytype--results ()
  "Print all results."
  (erase-buffer)

  (when (> (length monkeytype--run-list) 1)
    (insert
     (concat
      (monkeytype--results-final)
      (propertize "\n\nRuns Breakdown:\n\n" 'face 'monkeytype-title))))

  (let ((run-index 1))
    (dolist (run (reverse monkeytype--run-list))
      (insert
       (concat
        (propertize
         (format "--(%d)-%s--:\n" run-index (gethash "started-at" run))
         'face
         'monkeytype-title)
        (monkeytype--typed-text run)
        (monkeytype--results-run (gethash "entries" run))
        "\n\n"))

      (setq run-index (1+ run-index))

      (when monkeytype-insert-log
        (insert (monkeytype--log run)))))

  (goto-char (point-min)))

(defun monkeytype--results-get-face (successp)
"Get success or error face based on SUCCESSP."
(if successp
    'monkeytype-results-success
  'monkeytype-results-error))

(defun monkeytype--results-net-wpm (words uncorrected-errors minutes seconds)
  "Net WPM performance result for total WORDS.

Gross-WPM - (UNCORRECTED-ERRORS / MINUTES).
Also shows SECONDS right next to WPM."
  (concat
   (propertize
    (format
     "%.2f/%s"
     (monkeytype--calc-net-wpm words uncorrected-errors minutes)
     (format-seconds "%.2h:%z%.2m:%.2s" seconds))
    'face
    'monkeytype-legend-1)
   (propertize
    (format "[%.2f - (" (monkeytype--calc-gross-wpm words minutes))
    'face
    'monkeytype-legend-2)
   (propertize
    (format "%d" uncorrected-errors)
    'face
    (monkeytype--results-get-face (= uncorrected-errors 0)))
   (propertize
    (format " / %.2f)]\n" minutes)
    'face
    'monkeytype-legend-2)
   (propertize
    "WPM = Gross-WPM - (uncorrected-errors / minutes)"
    'face
    'monkeytype-legend-2)))

(defun monkeytype--results-gross-wpm (words minutes)
  "Gross WPM performance result.

Gross-WPM = WORDS / MINUTES."
  (concat
   (propertize
    (format "%.2f" (monkeytype--calc-gross-wpm words minutes))
    'face
    'monkeytype-legend-1)
   (propertize
    "["
    'face
    'monkeytype-legend-2)
   (propertize
    (format "%.2f" words)
    'face
    'monkeytype-results-success)
   (propertize
    (format " / %.2f]" minutes)
    'face
    'monkeytype-legend-2)
   (propertize
    "\nGross-WPM = words / minutes"
    'face
    'monkeytype-legend-2)))

(defun monkeytype--results-accuracy (chars correct-chars corrections)
  "CHARS CORRECT-CHARS CORRECTIONS."
  (concat
   (propertize
    (format "%.2f%%" (monkeytype--calc-accuracy
                      chars
                      correct-chars
                      corrections))
    'face
    'monkeytype-legend-1)
   (propertize
    (format "[((%.2f - " correct-chars)
    'face
    'monkeytype-legend-2)
   (propertize
    (format "%d" corrections)
    'face
    (monkeytype--results-get-face (= corrections 0)))
   (propertize
    (format ") / %.2f) * 100]" chars)
    'face
    'monkeytype-legend-2)
   (propertize
    "\nAccuracy = ((correct-chars - corrections) / total-chars) * 100"
    'face
    'monkeytype-legend-2)))

(defun monkeytype--results-run (run)
  "Performance results for RUN."
  (let* ((last-entry (elt run 0))
         (elapsed-seconds (gethash "elapsed-seconds" last-entry))
         (elapsed-minutes (monkeytype--utils-seconds-to-minutes
                           elapsed-seconds))
         (entries (if monkeytype--previous-run-last-entry
                      (-
                       (gethash "input-index" last-entry)
                       (gethash
                        "input-index"
                        monkeytype--previous-run-last-entry))
                    (gethash "input-index" last-entry)))
         (errors (if monkeytype--previous-run-last-entry
                     (-
                      (gethash "error-count" last-entry)
                      (gethash
                       "error-count"
                       monkeytype--previous-run-last-entry))
                   (gethash "error-count" last-entry)))
         (corrections (if monkeytype--previous-run-last-entry
                          (-
                           (gethash "correction-count" last-entry)
                           (gethash
                            "correction-count"
                            monkeytype--previous-run-last-entry))
                        (gethash "correction-count" last-entry)))
         (words (monkeytype--calc-words entries)))
    (setq monkeytype--previous-run-last-entry (elt run 0))
    (concat
     (monkeytype--results-net-wpm
      words
      errors
      elapsed-minutes
      elapsed-seconds)
     "\n\n"
     (monkeytype--results-accuracy
      entries
      (- entries errors) corrections)
     "\n\n"
     (monkeytype--results-gross-wpm
      words
      elapsed-minutes))))

(defun monkeytype--results-final ()
  "Final results for typed run(s).

Total time is the sum of all the last entries' elapsed-seconds for each runs."
  (let* ((runs-last-entry (mapcar
                           (lambda (x) (elt (gethash "entries" x) 0))
                           monkeytype--run-list))
         (last-entry (elt runs-last-entry 0))
         (total-elapsed-seconds (apply
                                 #'+
                                 (mapcar
                                  (lambda (x) (gethash "elapsed-seconds" x))
                                  runs-last-entry)))
         (elapsed-minutes (monkeytype--utils-seconds-to-minutes
                           total-elapsed-seconds))
         (entries (gethash "input-index" last-entry))
         (errors (gethash "error-count" last-entry))
         (corrections (gethash "correction-count" last-entry))
         (words (monkeytype--calc-words entries)))
    (concat
     (monkeytype--results-net-wpm
      words
      errors
      elapsed-minutes
      total-elapsed-seconds)
     "\n\n"
     (monkeytype--results-accuracy
      entries
      (- entries errors) corrections)
     "\n\n"
     (monkeytype--results-gross-wpm
      words
      elapsed-minutes))))

;;;; Typed Text

(defun monkeytype--typed-text-entry-face (correctp &optional correctionp)
  "Return the face for the CORRECTP and/or CORRECTIONP entry."
  (if correctionp
      (if correctp
          'monkeytype-correction-correct
        'monkeytype-correction-error)
    (if correctp
        'monkeytype-correct
      'monkeytype-error)))

(defun monkeytype--typed-text-newline (source typed)
  "Newline substitutions depending on SOURCE and TYPED char."
  (if (string= "\n" source)
      (if (or
           (string= " " typed)
           (string= source typed))
          "↵\n"
        (concat typed "↵\n"))
    typed))

(defun monkeytype--typed-text-whitespace (source typed)
  "Whitespace substitutions depending on SOURCE and TYPED char."
  (if (and
       (string= " " typed)
       (not (string= typed source)))
      "·"
    typed))

(defun monkeytype--typed-text-skipped-text (settled-index)
  "Handle skipped text before the typed char at SETTLED-INDEX."
  (let* ((source-index (car (car monkeytype--chars-list)))
         (skipped-length (if source-index
                             (- settled-index source-index)
                           0)))
    (if (= skipped-length 0)
        (progn (pop monkeytype--chars-list) "")
      (cl-loop repeat (1+ skipped-length) do
               (pop monkeytype--chars-list))
      (substring
       monkeytype--source-text
       (1- source-index)
       (1- settled-index)))))

(defun monkeytype--typed-text-add-to-mistyped-list (char)
  "Find associated word for CHAR and add it to mistyped list."
  (let* ((index (gethash "source-index" char))
         (word (cdr (assoc index monkeytype--chars-to-words-list)))
         (word (when word
                 (replace-regexp-in-string
                  monkeytype-excluded-chars-regexp
                  ""
                  word))))
    (when word
      (cl-pushnew word monkeytype--mistyped-words-list))))

(defun monkeytype--typed-text-concat-corrections (corrections entry settled)
  "Concat propertized CORRECTIONS to SETTLED char.

Also add corrections in ENTRY to `monkeytype--mistyped-word-list'."
  (monkeytype--typed-text-add-to-mistyped-list entry)

  (format
   "%s%s"
   settled
   (mapconcat
    (lambda (correction)
      (let* ((correction-char (gethash "typed-entry" correction))
             (state (gethash "state" correction))
             (correction-face
              (monkeytype--typed-text-entry-face (= state 1) t)))
        (propertize (format "%s" correction-char) 'face correction-face)))
    corrections
    "")))

(defun monkeytype--typed-text-collect-errors (settled)
  "Add SETTLED char's associated word and transitions to their respective list.

This is unless the char doesn't belong to any word as defined by the
`monkeytype-excluded-chars-regexp'."
  (unless (= (gethash "state" settled) 1)
    (unless (string-match
             monkeytype-excluded-chars-regexp
             (gethash "source-entry" settled))
      (let* ((char-index (gethash "source-index" settled))
             (hard-transition-p (> char-index 2))
             (hard-transition  (when hard-transition-p
                                 (substring
                                  monkeytype--source-text
                                  (- char-index 2)
                                  char-index)))
             (hard-transition-p (and
                                hard-transition-p
                                (string-match "[^ \n\t]" hard-transition))))

        (when hard-transition-p
          (cl-pushnew hard-transition monkeytype--hard-transition-list))
        (monkeytype--typed-text-add-to-mistyped-list settled)))))

(defun monkeytype--typed-text-to-string (entries)
  "Format typed ENTRIES and return a string."
  (mapconcat
   (lambda (entries-for-source)
     (let* ((tries (cdr entries-for-source))
            (correctionsp (> (length tries) 1))
            (settled (if correctionsp
                         (car (last tries))
                       (car tries)))
            (source-entry (gethash "source-entry" settled))
            (typed-entry (monkeytype--typed-text-newline
                          source-entry
                          (gethash "typed-entry" settled)))
            (typed-entry (monkeytype--typed-text-whitespace
                          source-entry
                          typed-entry))
            (settled-correctp (= (gethash "state" settled) 1))
            (settled-index (gethash "source-index" settled))
            (skipped-text  (monkeytype--typed-text-skipped-text settled-index))
            (propertized-settled (concat
                                  skipped-text
                                  (propertize
                                   (format "%s" typed-entry)
                                   'face
                                   (monkeytype--typed-text-entry-face
                                    settled-correctp))))
            (corrections (when correctionsp (butlast tries))))
       (if correctionsp
           (monkeytype--typed-text-concat-corrections
            corrections
            settled
            propertized-settled)
         (monkeytype--typed-text-collect-errors settled)
         (format "%s" propertized-settled))))
   entries
   ""))

(defun monkeytype--typed-text (run)
  "Typed text for RUN."
  (monkeytype--utils-index-chars run)
  (monkeytype--utils-index-words)
  (monkeytype--utils-index-chars-to-words)
  (format
   "\n%s\n\n"
   (monkeytype--typed-text-to-string
    (seq-group-by
     (lambda (entry) (gethash "source-index" entry))
     (reverse (gethash "entries" run))))))

;;;; Log:

(defun monkeytype--log (run)
  "Log for the RUN."
  (concat
   "Log:"
   (monkeytype--log-header)
   (mapconcat
    (lambda (entry)
      (monkeytype--log-entry entry))
    (reverse (gethash "entries" run))
    "\n")
   "\n"))

(defun monkeytype--log-header ()
  "Log header."
  (format
   "\n|%s|"
   (mapconcat
    #'identity
    '(" I/S Idx "
      " S/T Chr "
      " N/WPM   "
      " N/CPM   "
      " G/WPM   "
      " G/CPM   "
      " Acc %   "
      " Time    "
      " Mends   "
      " Errs    ")
    "|")))

(defun monkeytype--log-entry (entry)
  "Format ENTRY."
  (let* ((source-index (gethash "source-index" entry))
         (typed-entry (gethash "typed-entry" entry))
         (source-entry (gethash "source-entry" entry))
         (typed-entry (if (string= typed-entry "\n") "↵" typed-entry))
         (source-entry (if (string= source-entry "\n") "↵" source-entry))
         (error-count (gethash "error-count" entry))
         (correction-count (gethash "correction-count" entry))
         (input-index (gethash "input-index" entry))
         (state (gethash "state" entry))
         (elapsed-seconds (gethash "elapsed-seconds" entry))
         (elapsed-minutes (monkeytype--utils-seconds-to-minutes
                           elapsed-seconds))
         (typed-entry-face (monkeytype--typed-text-entry-face (= state 1)))
         (propertized-typed-entry (propertize
                                   (format "%S" typed-entry)
                                   'face typed-entry-face)))
    (format "\n|%9s|%9s|%9d|%9d|%9d|%9d|%9.2f|%9s|%9d|%9d|"
            (format "%s %s" input-index source-index)
            (format "%S %s" source-entry propertized-typed-entry)
            (monkeytype--calc-net-wpm
             (monkeytype--calc-words input-index)
             error-count
             elapsed-minutes)
            (monkeytype--calc-net-cpm input-index error-count elapsed-minutes)
            (monkeytype--calc-gross-wpm
             (monkeytype--calc-words input-index)
             elapsed-minutes)
            (monkeytype--calc-gross-cpm input-index elapsed-minutes)
            (monkeytype--calc-accuracy
             input-index
             (- input-index error-count)
             correction-count)
            (format-seconds "%.2h:%z%.2m:%.2s" elapsed-seconds)
            correction-count
            (+ error-count correction-count))))

;;; Mode-line

(defvar-local monkeytype--mode-line-current-entry '())
(defvar-local monkeytype--mode-line-previous-run '())
(defvar-local monkeytype--mode-line-previous-run-last-entry nil)

(defun monkeytype--mode-line-get-face (successp)
"Get success or error face based on SUCCESSP."
(if successp
    'monkeytype-mode-line-success
  'monkeytype-mode-line-error))

(defun monkeytype--mode-line-report-status ()
  "Take care of mode-line updating."
  (setq monkeytype--mode-line-current-entry
        (elt monkeytype--current-run-list 0))
  (setq monkeytype--mode-line-previous-run
        (elt monkeytype--run-list 0))

  (when monkeytype--mode-line-previous-run
    (setq monkeytype--mode-line-previous-run-last-entry
          (elt (gethash "entries" monkeytype--mode-line-previous-run) 0)))

  (when (or
         (not monkeytype--mode-line-current-entry)
         monkeytype--status-finished)
    (setq monkeytype--mode-line-current-entry (make-hash-table :test 'equal)))
  (force-mode-line-update))

(defun monkeytype--mode-line-text ()
  "Show status in mode line."
  (let* ((current-entry monkeytype--mode-line-current-entry)
         (seconds (gethash "elapsed-seconds" current-entry 0))
         (minutes (monkeytype--utils-seconds-to-minutes seconds))
         (previous-last-entry (when monkeytype--mode-line-previous-run
                                monkeytype--mode-line-previous-run-last-entry))
         (previous-run-entry-p (and
                                monkeytype--mode-line-previous-run
                                (> (gethash "input-index" current-entry 0) 0)))
         (entries (if previous-run-entry-p
                      (- (gethash "input-index" current-entry)
                         (gethash "input-index" previous-last-entry))
                    (gethash "input-index" current-entry
                     0)))
         (errors (if previous-run-entry-p
                     (-
                      (gethash "error-count" current-entry)
                      (gethash "error-count" previous-last-entry))
                   (gethash "error-count" current-entry 0)))
         (corrections (if previous-run-entry-p
                          (-
                           (gethash "correction-count" current-entry)
                           (gethash "correction-count" previous-last-entry))
                        (gethash "correction-count" current-entry 0)))
         (words (monkeytype--calc-words entries))
         (net-wpm (if (> words 1)
                      (monkeytype--calc-net-wpm words errors minutes)
                    0))
         (gross-wpm (if (> words 1)
                        (monkeytype--calc-gross-wpm words minutes)
                      0))
         (accuracy (if (> words 1)
                       (monkeytype--calc-accuracy
                        entries
                        (- entries errors)
                        corrections)
                     0))
         (time (format "%s" (format-seconds "%.2h:%z%.2m:%.2s" seconds))))

    (concat
     (propertize "MT[" 'face 'monkeytype-mode-line-normal)
     (propertize (format "%d" net-wpm) 'face 'monkeytype-mode-line-success)
     (propertize "/" 'face 'monkeytype-mode-line-normal)
     (propertize (format "%d" gross-wpm) 'face 'monkeytype-mode-line-normal)
     (propertize " " 'face 'monkeytype-mode-line-normal)
     (propertize (format "%d " accuracy) 'face 'monkeytype-mode-line-normal)
     (propertize time 'face 'monkeytype-mode-line-info)
     (propertize (format " (%d/" words) 'face 'monkeytype-mode-line-normal)
     (propertize
      (format "%d" corrections)
      'face
      (monkeytype--mode-line-get-face (= corrections 0)))
     (propertize "/" 'face 'monkeytype-mode-line-normal)
     (propertize
      (format "%d" errors)
      'face
      (monkeytype--mode-line-get-face (= errors 0)))
     (propertize ")]" 'face 'monkeytype-mode-line-normal))))

;;;; Interactive:

;;;###autoload
(defun monkeytype-region (start end)
  "Type marked region from START to END.

\\[monkeytype-region]"
  (interactive "r")
  (monkeytype--init
   (monkeytype--utils-format-text
    (buffer-substring-no-properties start end))))

;;;###autoload
(defun monkeytype-repeat ()
  "Repeat run.

\\[monkeytype-repeat]"
  (interactive)
  (monkeytype--init
   (monkeytype--utils-format-text monkeytype--source-text)))

;;;###autoload
(defun monkeytype-dummy-text ()
  "Dummy text.

\\[monkeytype-dummy-text]"
  (interactive)
  (monkeytype--init
   (monkeytype--utils-format-text
    (concat
     "\"I have had a dream past the wit of man to say what dream it was,\n"
     "says Bottom.\""))))

;;;###autoload
(defun monkeytype-fortune ()
  "Type fortune.

\\[monkeytype-fortune]"
  (interactive)
  (fortune)
  (monkeytype-buffer))

;;;###autoload
(defun monkeytype-buffer ()
  "Type entire current buffet.

\\[monkeytype-buffer]"
  (interactive)
  (monkeytype--init
   (monkeytype--utils-format-text
    (buffer-substring-no-properties (point-min) (point-max)))))

;;;###autoload
(defun monkeytype-pause ()
  "Pause run.

\\[monkeytype-pause]"
  (interactive)
  (setq monkeytype--status-paused t)
  (when monkeytype--start-time (monkeytype--run-pause))
  (setq monkeytype--current-run-list '())
  (unless monkeytype--status-finished
    (message "Monkeytype: Paused ([C-c C-c r] to resume.)")))

;;;###autoload
(defun monkeytype-stop ()
  "Finish run.

\\[monkeytype-stop]"
  (interactive)
  (monkeytype--run-finish))

;;;###autoload
(defun monkeytype-resume ()
  "Resume run.

\\[monkeytype-resume]"
  (interactive)
  (unless monkeytype--status-finished
    (setq monkeytype--status-paused nil)
    (switch-to-buffer monkeytype--typing-buffer)
    (set-buffer-modified-p nil)
    (monkeytype--run-add-hooks)
    (monkeytype-mode)
    (setq buffer-read-only nil)
    (monkeytype--mode-line-report-status)
    (message "Monkeytype: Timer will start when you start typing.")))

;;;###autoload
(defun monkeytype-mistyped-words ()
  "Practice mistyped words for current test.

\\[monkeytype-mistyped-words]"
  (interactive)
  (if (> (length monkeytype--mistyped-words-list) 0)
      (monkeytype--init
       (monkeytype--utils-format-words monkeytype--mistyped-words-list))
    (message "Monkeytype: No word-errors. ([C-c C-c t] to repeat.)")))

;;;###autoload
(defun monkeytype-hard-transitions ()
  "Practice hard key combinations/transitions for current test.

\\[monkeytype-hard-transitions]"
  (interactive)
  (if (> (length monkeytype--hard-transition-list) 0)
      (let* ((transitions-count (length monkeytype--hard-transition-list))
             (append-times (/
                            monkeytype-minimum-transitions
                            transitions-count))
             (final-list '()))
        (cl-loop repeat append-times do
                 (setq final-list
                       (append final-list monkeytype--hard-transition-list)))
        (monkeytype--init
         (monkeytype--utils-format-words
          (mapconcat #'identity final-list " "))))
    (message "Monkeytype: No transition-errors. ([C-c C-c t] to repeat.)")))

;;;###autoload
(defun monkeytype-save-mistyped-words ()
  "Save mistyped words for current test.

See also: `monkeytype-load-words-from-file'
See also: `monkeytype-most-mistyped-words'

\\[monkeytype-save-mistyped-words]"
  (interactive)
  (let ((path (monkeytype--utils-file-path "words"))
        (words (mapconcat #'identity monkeytype--mistyped-words-list " ")))
    (with-temp-file path (insert words))
    (message "Monkeytype: Words saved successfully to file: %s" path)))

;;;###autoload
(defun monkeytype-save-hard-transitions ()
  "Save hard transitions for current test.

See also: `monkeytype-load-words-from-file'

\\[monkeytype-save-hard-transition]"
  (interactive)
  (let ((path (monkeytype--utils-file-path "transitions"))
        (transitions (mapconcat
                      #'identity
                      monkeytype--hard-transition-list
                      " ")))
    (with-temp-file path (insert transitions))
    (message "Monkeytype: Transitions saved successfully to file: %s" path)))

;;;###autoload
(defun monkeytype-load-words-from-file ()
  "Prompt user to enter words-file to use for typing.

Words will be randomized if `monkeytype-randomize' is set to true.
Words will be downcased if `monkeytype-downcase' is set to true.
Words special characters will get removed based on
`monkeytype-excluded-chars-regexp'.
Buffer will be filled with the vale of `fill-column' if
`monkeytype-words-auto-fill' is set to true.

\\[monkeytype-load-words-from-file]"
  (interactive)
  (let* ((file-path (read-file-name "Enter words file:" monkeytype-directory))
         (words (with-temp-buffer
                  (insert-file-contents file-path)
                  (buffer-string)))
         (words (split-string words monkeytype-excluded-chars-regexp t))
         (words (monkeytype--utils-format-words words)))
    (monkeytype--init words)))

;;;###autoload
(defun monkeytype-region-as-words (start end)
  "Put the marked region from START to END in typing buffer.

Words will be randomized if `monkeytype-randomize' is set to true.
Words will be downcased if `monkeytype-downcase' is set to true.
Words special characters will get removed based on
`monkeytype-excluded-chars-regexp'.
Buffer will be filled with the vale of `fill-column' if `monkeytype-auto-fill'
is set to true.

\\[monkeytype-region-as-words]"
  (interactive "r")
  (let* ((text (buffer-substring-no-properties start end))
         (text (split-string text monkeytype-excluded-chars-regexp t))
         (text (monkeytype--utils-format-words text)))
    (monkeytype--init text)))

;;;###autoload
(defun monkeytype-most-mistyped-words ()
  "Type most mistyped words from all word-files in the `monkeytype-directory'.

See: `monkeytype-save-mistyped-words' for how word-files are saved.

\\[monkeytype-most-mistyped-words]"
  (interactive)
  (let* ((dir (concat monkeytype-directory "/words"))
         (files (directory-files dir t ".txt$" nil))
         (word-list (with-temp-buffer
                      (dolist (file files)
                        (insert-file-contents file))
                      (split-string (buffer-string))))
         (grouped-words (seq-group-by #'identity word-list))
         (grouped-words (seq-group-by #'length grouped-words))
         (word-list '()))

    (dolist (word-group (reverse grouped-words))
      (dolist (word (cdr word-group))
        (cl-pushnew (car word) word-list)))

    (if (> (length word-list) monkeytype-most-mistyped-amount)
        (progn
          (setq word-list (seq-take word-list monkeytype-most-mistyped-amount))
          (monkeytype--init (monkeytype--utils-format-words word-list)))
      (message "Monkeytype: Not enough mistyped words for test."))))

;;;###autoload
(define-minor-mode monkeytype-mode
  "Monkeytype mode is a minor mode for speed/touch typing.

\\{monkeytype-mode-map}"
  :lighter monkeytype-mode-line
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-c p") 'monkeytype-pause)
            (define-key map (kbd "C-c C-c r") 'monkeytype-resume)
            (define-key map (kbd "C-c C-c s") 'monkeytype-stop)
            (define-key map (kbd "C-c C-c t") 'monkeytype-repeat)
            (define-key map (kbd "C-c C-c f") 'monkeytype-fortune)
            (define-key map (kbd "C-c C-c m") 'monkeytype-mistyped-words)
            (define-key map (kbd "C-c C-c h") 'monkeytype-hard-transitions)
            (define-key map (kbd "C-c C-c a") 'monkeytype-save-mistyped-words)
            (define-key map (kbd "C-c C-c o") 'monkeytype-save-hard-transitions)
            map)
  (if monkeytype-mode
      (progn
        (font-lock-mode nil)
        (buffer-face-mode t)
        (buffer-face-set 'monkeytype-default)
        (monkeytype--run-add-hooks)
        (monkeytype--mode-line-report-status))
    (font-lock-mode t)
    (buffer-face-mode nil)))

(provide 'monkeytype)

;;; monkeytype.el ends here
