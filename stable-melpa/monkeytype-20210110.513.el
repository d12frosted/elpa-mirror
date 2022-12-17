;;; monkeytype.el --- Mode for speed typing -*- lexical-binding: t; -*-

;; Copyright (C) 2020 Pablo Barrantes

;; Author: Pablo Barrantes <xjpablobrx@gmail.com>
;; Maintainer: Pablo Barrantes <xjpablobrx@gmail.com>
;; Version: 0.1.3
;; Package-Version: 20210110.513
;; Package-Commit: 0e949d08198c0bd003f1d5c8cdceb7e36bef22f7
;; Keywords: games
;; URL: https://github.com/jpablobr/emacs-monkeytype
;; Package-Requires: ((emacs "25.1") (scrollable-quick-peek "0.1.0"))

;;; Commentary:

;; Emacs Monkeytype is a typing game/tutor inspired by monkeytype.com
;; but for Emacs.

;; Features:

;; - Type any text you want
;; - Practice mistyped words
;; - Optional mode-line live WPM
;; - Pause/Resume/Stop/Save functionality
;; - Visual representation of typed text including errors and
;;   retries/corrections
;; - Auto stop after 5 seconds of no input
;; - Optionally randomise practice words/transitions
;; - Optionally downcase practice words/transitions
;; - Optionally treat newlines as whitespace
;; - Optionally text auto-fill
;; - Optionally delete trailing whitespace
;; - Select a region of text and treat it as words for practice
;; - After a test, practice troubling/hard key combinations/transitions
;; - Mistyped words or hard transitions can be saved
;; - Saved mistyped/transitions/text can be loaded for practice
;; - Ability to type most (saved) mistyped words
;; - Text for typing can be saved in the `monkeytype-directory' allowing
;;   you to resume later on (even after quitting Emacs).
;; - Download web pages directly to monkeytype-directory directory.

;;; License:

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 2 of the License, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Code:

(require 'cl-lib)
(require 'seq)
(require 'subr-x)
(require 'json)
(require 'map)

(require 'scrollable-quick-peek)

;;;; Customization

(defgroup monkeytype nil
  "Speed/touch typing."
  :group 'games
  :tag "Monkeytype"
  :link '(url-link "https://github.com/jpablobr/emacs-monkeytype"))

(defcustom monkeytype-treat-newline-as-space t
  "Allow continuing to the next line by pressing space."
  :type 'boolean)

(defcustom monkeytype-insert-log nil
  "Show log in results section."
  :type 'boolean)

(defcustom monkeytype-minimum-transitions 50
  "Minimum amount of transitions to practice."
  :type 'integer)

(defcustom monkeytype-mode-line '(:eval (monkeytype--mode-line-text))
  "Monkeytype mode-line formatting."
  :type 'sexp
  :risky t)

(defcustom monkeytype-colored-mode-line t
  "Toggle coloured mode-line WPM status."
  :type 'boolean)

(defcustom monkeytype-mode-line-interval-update 1
  "Number of keystrokes after each mode-line update.
Reducing the frequency of the updates helps reduce lagging on longer
text or when typing too fast."
  :type 'integer)

(defcustom monkeytype-word-divisor 5.0
  "5 is the most common number for these calculations.
Proper word count doesn't work as well since words have different number
of characters. This also makes calculations easier and more accurate."
  :type 'integer)

(defcustom monkeytype-auto-fill nil
  "Toggle auto fill for typing text.
Defaults `fill-column' setting
See also: `monkeytype-words-auto-fill'"
  :type 'boolean)

(defcustom monkeytype-words-auto-fill t
  "Toggle auto fill for words/transitions.
It defaults `fill-column' setting. See: `monkeytype-auto-fill'"
  :type 'boolean)

(defcustom monkeytype-delete-trailing-whitespace t
  "Toggle delete trailing whitespace."
  :type 'boolean)

(defcustom monkeytype-downcase t
  "Toggle downcasing of mistyped words."
  :type 'boolean)

(defcustom monkeytype-directory "~/.monkeytype/"
  "Monkeytype directory."
  :type 'string)

(defcustom monkeytype-randomize t
  "Toggle randomizing of words."
  :type 'boolean)

(defcustom monkeytype-excluded-chars-regexp "[^[:alnum:]']"
  "Regexp used for getting valid words."
  :type 'string)

(defcustom monkeytype-most-mistyped-amount 100
  "Amount of words in most mistyped words test."
  :type 'integer)

(defcustom monkeytype-file-name-format "%a-%d-%b-%Y-%H-%M-%S"
  "Format for time-stamped files for saving."
  :type 'string)

(defcustom monkeytype-asciify t
  "ASCII character encode downloaded web-pages.
Iconv(1) must be installed."
  :type 'boolean)

;;;; Faces

(defgroup monkeytype-faces nil
  "Faces used by Monkeytype."
  :group 'monkeytype
  :group 'faces)

(defface monkeytype-default
  '((t :inherit default))
  "Face for text area.")

(defface monkeytype-dimmed
  '((((class color) (background light)) :foreground "#999999")
    (((class color) (background  dark)) :foreground "#888888"))
  "Face for correctly typed char.")

(defface monkeytype-notice
  '((((class color) (background light)) :foreground "#B79508")
    (((class color) (background  dark)) :foreground "#cd950c"))
  "Face for correctly typed char.")

(defface monkeytype-correct
  '((t :inherit monkeytype-dimmed))
  "Face for correctly typed char.")

(defface monkeytype-error
  '((t (
        :foreground "#cc6666"
        :underline (:color "#cc6666" :style wave))))
  "Face for wrongly typed char.")

(defface monkeytype-correction-error
  '((t (
        :inherit region
        :foreground "#ff6c6b"
        :underline (:color "#ff6c6b" :style wave))))
  "Face for wrongly typed correction.")

(defface monkeytype-correction-correct
  '((t (:inherit region :foreground "#b9ca4a")))
  "Face for correctly typed correction.")

(defface monkeytype-read-only
  '((t :inherit monkeytype-dimmed :strike-through t :slant italic))
  "Face for results titles.")

(defface monkeytype-title
  '((t :inherit default))
  "Face for results titles.")

(defface monkeytype-legend-1
  '((t :inherit monkeytype-notice))
  "Face for results legend 1.")

(defface monkeytype-legend-2
  '((t (:slant italic :height 0.9)))
  "Face for results legend 2.")

(defface monkeytype-results-success
  '((t (:foreground "#98be65" :height 0.9)))
  "Face for results success text.")

(defface monkeytype-results-error
  '((t (:foreground "#cc6666" :height 0.9)))
  "Face for results error text.")

(defface monkeytype-mode-line-success
  '((t (:foreground "#98be65")))
  "Face for mode-line success text.")

(defface monkeytype-mode-line-error
  '((t (:foreground "#ff6c6b")))
  "Face for mode-line error text.")

(defface monkeytype-mode-line-normal
  '((t :inherit default))
  "Face for mode-line normal text.")

(defface monkeytype-mode-line-info
  '((t :inherit monkeytype-notice))
  "Face for mode-line info text.")

;;;; Init:

(defvar-local monkeytype--buffer-name "*Monkeytype*")
(defvar-local monkeytype--runs '())
(defvar-local monkeytype--start-time nil)
(defvar-local monkeytype--wpm-peek-text nil)
(defvar monkeytype--typing-buffer nil)
(defvar monkeytype--source-text "")
(defvar monketype--utils-disabled-props
  `(
    read-only t
    rear-nonsticky (read-only)
    front-sticky (read-only)
    face monkeytype-read-only))

;; Text-File
(defvar monkeytype--text-file-directory nil)
(defvar monkeytype--text-file-last-entry nil)
(defvar monkeytype--text-file nil)

;; Status
(defvar-local monkeytype--status-finished nil)
(defvar-local monkeytype--status-paused nil)

;; Counters
(defvar-local monkeytype--counter-chars 0)
(defvar-local monkeytype--counter-input 0)
(defvar-local monkeytype--counter-error 0)
(defvar-local monkeytype--counter-correction 0)
(defvar-local monkeytype--counter-remaining 0)
(defvar-local monkeytype--counter-ignored-change 0)

;; Run
(defvar-local monkeytype--progress-tracker "")
(defvar-local monkeytype--current-run '())
(defvar-local monkeytype--current-entry '())
(defvar-local monkeytype--current-run-start-datetime nil)

;; Results
(defvar-local monkeytype--previous-last-entry-index nil)
(defvar-local monkeytype--previous-run-last-entry nil)
(defvar-local monkeytype--previous-run '())

(defun monkeytype (text &optional fn)
  "Set up a new buffer for the typing exercise on TEXT.
TEXT-FILE-P is used to know if the test is text-file based."
  (setq monkeytype--typing-buffer
        (generate-new-buffer monkeytype--buffer-name))

  (set-buffer monkeytype--typing-buffer)
  (erase-buffer)

  (setq monkeytype--source-text text)
  (setq monkeytype--counter-remaining (1+ (length text)))
  (setq monkeytype--progress-tracker (make-string (length text) 0))

  (insert monkeytype--source-text)
  (goto-char 0)
  (when fn (funcall fn))

  ;; `set-buffer-modified-p' has no be set to nil before adding the
  ;; change hooks for them to work, so it has to happen right before
  ;; loading `monkeytype-mode'.
  (set-buffer-modified-p nil)
  (monkeytype-mode)

  (switch-to-buffer monkeytype--typing-buffer)
  (message "Monkeytype: Timer will start when you start typing."))

;;;; Utils:

(defvar-local monkeytype--chars '())
(defvar-local monkeytype--words '())
(defvar-local monkeytype--mistyped-words '())
(defvar-local monkeytype--chars-to-words '())
(defvar-local monkeytype--hard-transitions '())
(defvar-local monkeytype--idle-timer nil)

(defun monketype--utils-reset-read-only-text-properties ()
  "Reset text properties entire buffer (even read-only)."
  ;; Allow removing read-only properties.
  (setq inhibit-read-only t)
  ;; Remove all text properties
  (set-text-properties (point-min) (point-max) nil)
  ;; Disable inhibit-read-only back again.
  (setq inhibit-read-only nil))

(defun monkeytype--utils-nshuffle (sequence)
  "Shuffle given SEQUENCE.

URL `https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle'"
  (cl-loop for i from (length sequence) downto 2
           do (cl-rotatef (elt sequence (random i))
                          (elt sequence (1- i))))
  sequence)

(defun monkeytype--utils-idle-timer (secs func)
  "Idle timer for pausing run after 5 SECS.
FUNC and ARGS are passed directly to `run-with-idle-timer'."
  (setq monkeytype--idle-timer (run-with-idle-timer secs nil func)))

(defun monkeytype--utils-file-path (type)
  "Build path for the TYPE of file to be saved."
  (let* ((dir (when monkeytype--text-file
                (string-trim
                 monkeytype--text-file "^/.+/" "\\.[[:alnum:]]+\\'")))
         (path (if dir (concat "text/" dir "/" type) type))
         (path (concat monkeytype-directory path))
         (file (format-time-string monkeytype-file-name-format))
         (file (format "/%s.txt" (downcase file))))
    (unless (file-exists-p path) (make-directory path t))
    (concat path file)))

(defun monkeytype--utils-text-file-name ()
  "Name for the text-file run's JSON file."
  (format "%s" (downcase (format-time-string monkeytype-file-name-format))))

(defun monkeytype--utils-save-run (run)
  "Save RUN as JSON format `monkeytype--text-file-directory'."
  (let* ((dir  (concat monkeytype--text-file-directory "json/"))
         (path (concat dir (monkeytype--utils-text-file-name) ".json")))
    (when (> (length (gethash 'entries run)) 0)
      (with-temp-file path (insert (json-encode run))))))

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
    (cl-loop for word in words do
             (cl-pushnew (cons index word) monkeytype--words)
             (setq index (1+ index)))))

(defun monkeytype--utils-index-chars-to-words ()
  "Associate by their index chars to words.

See: `monkeytype--utils-index-words'
See: `monkeytype--utils-index-chars'"
  (let ((chars (mapcar #'char-to-string monkeytype--source-text))
        (word-index 1)
        (char-index 1))
    (cl-loop for char in chars do
             (if (string-match monkeytype-excluded-chars-regexp char)
                 (progn
                   (setq word-index (1+ word-index))
                   (setq char-index (1+ char-index)))
               (let ((word (cdr (assoc word-index monkeytype--words))))
                 (cl-pushnew (cons char-index word) monkeytype--chars-to-words)
                 (setq char-index (1+ char-index)))))))

(defun monkeytype--utils-index-chars (run)
  "Index chars for given RUN."
  (unless monkeytype--previous-last-entry-index
    (setq monkeytype--previous-last-entry-index 0))

  (let* ((start monkeytype--previous-last-entry-index)
         (last-entry (elt (gethash 'entries run) 0))
         (end (gethash 'source-index last-entry))
         (source-text (substring monkeytype--source-text start end))
         (chars (mapcar #'char-to-string source-text))
         (chars-list '())
         (index start))
    (cl-loop for char in chars do
             (setq index (1+ index))
             (cl-pushnew (cons index char) chars-list))
    (setq monkeytype--chars (reverse chars-list))
    (setq monkeytype--previous-last-entry-index
          (gethash 'source-index (elt (gethash 'entries run) 0)))))

(defun monkeytype--utils-format-words (words)
  "Format WORDS by applying word related customization settings.

See: `monkeytype-downcase'
See: `monkeytype-randomize'
See: `monkeytype-words-auto-fill'
See: `monkeytype-delete-trailing-whitespace'"
  (with-temp-buffer
    (insert
     (mapconcat
      (lambda (word) (if monkeytype-downcase (downcase word) word))
      (if monkeytype-randomize (monkeytype--utils-nshuffle words) words)
      " "))
    (when monkeytype-words-auto-fill
      (fill-region (point-min) (point-max)))
    (when monkeytype-delete-trailing-whitespace
      (delete-trailing-whitespace))
    (buffer-string)))

(defun monkeytype--utils-format-text (text)
  "Format TEXT (for test) by applying customization settings.

See: `monkeytype-auto-fill'
See: `monkeytype-delete-trailing-whitespace'"
  (with-temp-buffer
    (insert text)
    (when monkeytype-auto-fill (fill-region (point-min) (point-max)))
    (when monkeytype-delete-trailing-whitespace (delete-trailing-whitespace))
    (buffer-string)))

(defun monkeytype--utils-check-for-iconv ()
  "Verify that iconv(1) is installed."
  (when monkeytype-asciify
    (if (executable-find "iconv")
        t
      (error "Monketype Error: Iconv(1) executable not installed"))))

(defun monkeytype--utils-check-for-pandoc ()
  "Verify that pandoc(1) is installed."
  (if (executable-find "pandoc")
      t
    (error "Monketype Error: pandoc(1) executable not installed")))

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

Since there can be up to five errors for each word (see:
`monkeytype--calc-words' for WORDS calculation) if net-WPM is negative, return 0
instead.

See `monkeytype--calc-gross-cpm' for gross WPM."
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

(defun monkeytype--process-input (start end delete-length)
  "Process input from region START to region END.
DELETE-LENGTH is the amount of deleted chars in case of deletion."
  (let* ((source-start (1- start))
         (source-end (1- end))
         (entry (substring-no-properties
                 (buffer-substring start end)))
         (source (substring monkeytype--source-text source-start source-end))
         (state (aref monkeytype--progress-tracker source-start))
         (correctp (monkeytype--utils-check-same source entry))
         (tracker (if correctp 1 2))
         (face-for-entry (monkeytype--typed-text-entry-face correctp))
         (valid-input (<= (length source) 1)))

    (monkeytype--process-input-restabilize start end state delete-length)

    (when valid-input
      (store-substring monkeytype--progress-tracker source-start tracker)

      (cl-decf monkeytype--counter-remaining)
      (unless correctp (cl-incf monkeytype--counter-error))

      (set-text-properties start (1+ start) `(face ,face-for-entry))

      (unless (= start end) ; Do not add no-char (e.i., deletion) entries
        (cl-incf monkeytype--counter-chars)
        (monkeytype--process-input-add-to-entries source-start entry source))

      (monkeytype--process-input-update-mode-line))

    (goto-char end)
    (when (= monkeytype--counter-remaining 0) (monkeytype--run-finish))))

(defun monkeytype--process-input-restabilize (start end state deleted)
  "Restabilize input-region from START to END.

STATE keeps track of text already typed but deleted (e.i., correction).
DELETED is the number of deleted chars before current char input."
  (let* ((source-start (1- start))
         (skippedp (>
                    (+ source-start monkeytype--counter-remaining)
                    (length monkeytype--source-text)) )
         (correctionp (> state 0))
         (deleted-text-p (and (= start end) (> deleted 0)))
         (deleted-end (+ source-start deleted)))

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

    ;; Re-insert deleted text and update remaining counter
    (when deleted-text-p
      (setq monkeytype--counter-remaining
            (- (length monkeytype--source-text) source-start))
      (insert
       (substring monkeytype--source-text source-start deleted-end)))))

(defun monkeytype--process-input-rectify-counters (entry-state)
  "Update counters on corrections/re-tries based on the ENTRY-STATE.

ENTRY-STATE = 0 not a correction
ENTRY-STATE = 1 correctly re-typed char
ENTRY-STATE = 2 mistyped re-typed char"
  (unless (= entry-state 0) ; ignore unless it's a correction
    (cl-incf monkeytype--counter-remaining)
    ;; Update corrections counter on correct or incorrect retries.
    ;; This means that in terms of wpm-accuracy correct or incorrect
    ;; retries they get counted affecting the score negatively.
    (cl-incf monkeytype--counter-correction)
    (when (= entry-state 2)
      (cl-decf monkeytype--counter-error))))

(defun monkeytype--process-input-add-to-entries (start typed source)
  "Add entry to `monkeytype--current-run'.

START is used for indexing purposes.
TYPED is the char input by the user.
SOURCE is the original char."
  (cl-incf monkeytype--counter-input)
  (let ((entry (make-hash-table :test 'equal))
        (seconds (format-seconds
                  "%.2h:%z%.2m:%.2s"
                  (monkeytype--utils-elapsed-seconds))))
    (puthash 'chars monkeytype--counter-chars entry)
    (puthash 'input-index monkeytype--counter-input entry)
    (puthash 'typed-entry typed entry)
    (puthash 'source-entry source entry)
    (puthash 'source-index (1+ start) entry)
    (puthash 'error-count monkeytype--counter-error entry)
    (puthash 'correction-count monkeytype--counter-correction entry)
    (puthash 'state (aref monkeytype--progress-tracker start) entry)
    (puthash 'elapsed-seconds (monkeytype--utils-elapsed-seconds) entry)
    (puthash 'formatted-seconds seconds entry)
    (add-to-list 'monkeytype--current-run entry)))

(defun monkeytype--process-input-timer-init ()
  "Start the idle timer (to wait 5 seconds before pausing).

See: `monkeytype--utils-idle-timer'"
  (unless monkeytype--start-time
    (setq monkeytype--current-run-start-datetime
          (format-time-string "%a-%d-%b-%Y %H:%M:%S"))
    (setq monkeytype--start-time (float-time))
    (monkeytype--utils-idle-timer 5 'monkeytype-pause)))

(defun monkeytype--process-input-update-mode-line ()
  "Update `monkeytype-mode-line' by sending it the current entry info."
  (if (and
       monkeytype-mode-line
       monkeytype-mode-line-interval-update)
      (let* ((entry (elt monkeytype--current-run 0))
             (char-index (if entry (gethash 'source-index entry) 0)))
        (if (and
             (> char-index monkeytype-mode-line-interval-update)
             (= (mod char-index monkeytype-mode-line-interval-update) 0))
            (monkeytype--mode-line-report-status)))))

;;;; Run:

(defun monkeytype--run-pause ()
  "Pause run by resetting hooks and `monkeytype--start-time'."
  (setq monkeytype--start-time nil)
  (cancel-timer monkeytype--idle-timer)
  (monkeytype--run-remove-hooks)
  (monkeytype--run-add-to-list)

  (when monkeytype--text-file
    (monkeytype--utils-save-run (elt monkeytype--runs 0)))

  (let* ((last-run (elt monkeytype--runs 0))
         (last-entry (elt (gethash 'entries last-run) 0))
         (end (1+ (gethash 'source-index last-entry))))
    (monketype--utils-reset-read-only-text-properties)
    (add-text-properties 1 end monketype--utils-disabled-props))

  (read-only-mode))

(defun monkeytype--run-finish ()
  "Remove typing hooks and print results."
  (setq monkeytype--status-finished t)
  (monketype--utils-reset-read-only-text-properties)

  ;; `monketytype--wpm-peek' updated these vars so they
  ;; have to be set back to nil for the final results.
  (setq
   monkeytype--text-file-directory nil
   monkeytype--text-file-last-entry nil
   monkeytype--text-file nil
   monkeytype--previous-last-entry-index nil
   monkeytype--previous-run-last-entry nil
   monkeytype--previous-run '())

  (unless monkeytype--status-paused
    (setq monkeytype--start-time nil)
    (cancel-timer monkeytype--idle-timer)
    (monkeytype--run-remove-hooks)
    (monkeytype--run-add-to-list)
    (setq monkeytype--current-run '())
    (when monkeytype--text-file
      (monkeytype--utils-save-run (elt monkeytype--runs 0))))

  (setq buffer-read-only nil)

  (message "Monkeytype: Processing results...")
  (monkeytype--results)
  (message "Monkeytype: Results generated successfully.")

  (monkeytype--mode-line-report-status)
  (read-only-mode))

(defun monkeytype--run-add-to-list ()
  "Add current run to `monkeytype--runs'."
  (let ((run (make-hash-table :test 'equal)))
    (puthash 'started-at monkeytype--current-run-start-datetime run)
    (puthash 'finished-at (format-time-string "%a-%d-%b-%Y %H:%M:%S") run)
    (puthash 'entries monkeytype--current-run run)
    (add-to-list 'monkeytype--runs run)))

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

  (when monkeytype--text-file
    (let* ((path monkeytype--text-file)
           (dir (concat (string-trim path nil "\\.txt\\'") "/json"))
           (runs (directory-files dir t "\\.json\\'" nil)))
      (setq monkeytype--runs '())
      (dolist (run runs)
        (let* ((run (json-read-file run))
               (run-hash (make-hash-table :test 'equal))
               (entries (mapcar
                         (lambda (x)
                           (map-into x 'hash-table))
                         (cdr (assoc 'entries run)))))
          (puthash 'started-at (cdr (assoc 'started-at run)) run-hash)
          (puthash 'finished-at (cdr (assoc 'finished-at run)) run-hash)
          (puthash 'entries entries run-hash)
          (add-to-list 'monkeytype--runs run-hash)))))

  (when (> (length monkeytype--runs) 1)
    (let* ((title-1 "Final Results for a Total of %d Runs\n\n")
           (title-1 (format title-1 (length monkeytype--runs)))
           (title-1 (propertize title-1 'face 'monkeytype-title))
           (title-2 "\n\nRuns Breakdown:\n\n")
           (title-2 (propertize title-2 'face 'monkeytype-title)))
      (insert (concat title-1 (monkeytype--results-final) title-2))))

  (let ((run-index 1))
    (dolist (run (reverse monkeytype--runs))
      (let* ((title "%d) %s:\n")
             (title (format title run-index (gethash 'started-at run)))
             (title (replace-regexp-in-string "-" " " title))
             (title (propertize title 'face 'monkeytype-title))
             (title (and (> (length monkeytype--runs) 1) title))
             (run-typed-text (monkeytype--typed-text run))
             (run-results (monkeytype--results-run (gethash 'entries run))))
        (insert
         (concat title run-results "\n\nTyped Text:\n" run-typed-text)))

      (setq run-index (1+ run-index))

      (when monkeytype-insert-log
        (insert (monkeytype--log run)))))

  (goto-char (point-min)))

(defun monkeytype--results-get-face (successp)
  "Get success or error face based on SUCCESSP."
  (if successp 'monkeytype-results-success 'monkeytype-results-error))

(defun monkeytype--results-net-wpm (words errors minutes seconds)
  "Net WPM performance result for total WORDS.

Gross-WPM - (ERRORS / MINUTES).
Also shows SECONDS right next to WPM."
  (let* ((seconds (format-seconds "%.2h:%z%.2m:%.2s" seconds))
         (net-wpm (monkeytype--calc-net-wpm words errors minutes))
         (net-wpm (format "%.2f/%s" net-wpm seconds))
         (net-wpm (propertize net-wpm 'face 'monkeytype-legend-1))
         (gross-wpm (monkeytype--calc-gross-wpm words minutes))
         (gross-wpm (format "[%.2f - (" gross-wpm))
         (gross-wpm (propertize gross-wpm 'face 'monkeytype-legend-2))
         (errors-face (monkeytype--results-get-face (= errors 0)))
         (errors-lable (format "%d" errors))
         (errors-lable (propertize errors-lable 'face errors-face))
         (minutes-lable (format " / %.2f)]\n" minutes))
         (minutes-lable (propertize minutes-lable 'face 'monkeytype-legend-2))
         (info-label "WPM = Gross-WPM - (uncorrected-errors / minutes)")
         (info-label (propertize info-label 'face 'monkeytype-legend-2)))
    (concat net-wpm gross-wpm errors-lable minutes-lable info-label)))

(defun monkeytype--results-gross-wpm (words minutes)
  "Gross WPM performance result.

Gross-WPM = WORDS / MINUTES."
  (let* ((gross-wpm (monkeytype--calc-gross-wpm words minutes))
         (gross-wpm (format "%.2f" gross-wpm))
         (gross-wpm (propertize gross-wpm 'face 'monkeytype-legend-1))
         (open-bracket (propertize "[" 'face 'monkeytype-legend-2))
         (words-label (format "%.2f" words))
         (words-label (propertize words-label 'face 'monkeytype-results-success))
         (minutes-label (format " / %.2f]" minutes))
         (minutes-label (propertize minutes-label 'face 'monkeytype-legend-2))
         (help-label "\nGross-WPM = words / minutes")
         (help-label (propertize help-label 'face 'monkeytype-legend-2)))
    (concat gross-wpm open-bracket words-label minutes-label help-label)))

(defun monkeytype--results-accuracy (chars correct corrections)
  "Calculate accuracy: ((CORRECT - CORRECTIONS) / CHARS) * 100."
  (let* ((acc (monkeytype--calc-accuracy chars correct corrections))
         (acc (format "%.2f%%" acc))
         (acc (propertize acc 'face 'monkeytype-legend-1))
         (correct-lable (format "[((%.2f - " correct))
         (correct-lable (propertize correct-lable 'face 'monkeytype-legend-2))
         (corrections-face (monkeytype--results-get-face (= corrections 0)))
         (corrections-lable (format "%d" corrections))
         (corrections-lable (propertize corrections-lable 'face corrections-face))
         (chars-lable (format ") / %.2f) * 100]" chars))
         (chars-lable (propertize chars-lable 'face 'monkeytype-legend-2))
         (help-lable "\nAccuracy = ((correct-chars - corrections) / total-chars) * 100")
         (help-lable (propertize help-lable 'face 'monkeytype-legend-2)))
    (concat acc correct-lable corrections-lable chars-lable help-lable)))

(defun monkeytype--results-run (run)
  "Performance results for RUN."
  (let* ((last-entry (elt run 0))
         (previous-entry monkeytype--previous-run-last-entry)
         (seconds (gethash 'elapsed-seconds last-entry))
         (minutes (monkeytype--utils-seconds-to-minutes seconds))
         (char-count (gethash 'chars last-entry))
         (errors (gethash 'error-count last-entry))
         (corrections (gethash 'correction-count last-entry))
         (words (monkeytype--calc-words char-count))
         (str-format "%s\n\n%s\n\n%s"))

    (when previous-entry
      (setq char-count (- char-count (gethash 'chars previous-entry)))
      (setq words (monkeytype--calc-words char-count))
      (setq errors (- errors (gethash 'error-count previous-entry)))
      (setq corrections
            (- corrections (gethash 'correction-count previous-entry))))

    (setq monkeytype--previous-run-last-entry (elt run 0))

    (concat
     (format
      str-format
      (monkeytype--results-net-wpm words errors minutes seconds)
      (monkeytype--results-accuracy
       char-count
       (- char-count errors)
       corrections)
      (monkeytype--results-gross-wpm words minutes)))))

(defun monkeytype--results-final ()
  "Final results for typed run(s).
Total time is the sum of all the last entries' elapsed-seconds for each
run."
  (let* ((last-entries (mapcar
                        (lambda (x) (elt (gethash 'entries x) 0))
                        monkeytype--runs))
         (last-entry (elt last-entries 0))
         (total-seconds (mapcar
                         (lambda (x) (gethash 'elapsed-seconds x))
                         last-entries))
         (total-seconds (apply #'+ total-seconds))
         (minutes (monkeytype--utils-seconds-to-minutes total-seconds))
         (char-count (gethash 'chars last-entry))
         (errors (gethash 'error-count last-entry))
         (corrections (gethash 'correction-count last-entry))
         (words (monkeytype--calc-words char-count))
         (str-format "%s\n\n%s\n\n%s")
         (net-wpm (monkeytype--results-net-wpm words errors minutes total-seconds))
         (acc (monkeytype--results-accuracy char-count (- char-count errors) corrections))
         (gross-wpm (monkeytype--results-gross-wpm words minutes)))
    (concat (format str-format net-wpm acc gross-wpm))))

;;;; Typed Text:

(defun monkeytype--typed-text-entry-face (correctp &optional correctionp)
  "Return the face for the CORRECTP and/or CORRECTIONP entry."
  (if correctionp
      (if correctp 'monkeytype-correction-correct 'monkeytype-correction-error)
    (if correctp 'monkeytype-correct 'monkeytype-error)))

(defun monkeytype--typed-text-newline (source typed)
  "Newline substitutions depending on SOURCE and TYPED char."
  (if (string= "\n" source)
      (if (or (string= " " typed) (string= source typed))
          "↵\n"
        (concat typed "↵\n"))
    typed))

(defun monkeytype--typed-text-whitespace (source typed)
  "Whitespace substitutions depending on SOURCE and TYPED char."
  (if (and (string= " " typed) (not (string= typed source))) "·" typed))

(defun monkeytype--typed-text-skipped (settled)
  "Handle skipped text before the typed char at SETTLED."
  (let* ((start (car (car monkeytype--chars)))
         (skipped-length (when start (- settled start))))
    (if skipped-length
        (progn (pop monkeytype--chars) "")
      (cl-loop repeat (1+ skipped-length) do
               (pop monkeytype--chars))
      (substring monkeytype--source-text (1- start) (1- settled)))))

(defun monkeytype--typed-text-add-to-mistyped-list (char)
  "Find associated word for CHAR and add it to mistyped list."
  (let* ((index (gethash 'source-index char))
         (word (cdr (assoc index monkeytype--chars-to-words))))
    (when word
      (cl-pushnew
       (replace-regexp-in-string monkeytype-excluded-chars-regexp "" word)
       monkeytype--mistyped-words))))

(defun monkeytype--typed-text-concat-corrections (corrections entry settled)
  "Concat propertized CORRECTIONS to SETTLED char.
Also add corrections in ENTRY to `monkeytype--mistyped-word-list'."
  (monkeytype--typed-text-add-to-mistyped-list entry)

  (format
   "%s%s"
   settled
   (mapconcat
    (lambda (correction)
      (let* ((correction-char (gethash 'typed-entry correction))
             (state (gethash 'state correction))
             (correction-face
              (monkeytype--typed-text-entry-face (= state 1) t)))
        (propertize (format "%s" correction-char) 'face correction-face)))
    corrections
    "")))

(defun monkeytype--typed-text-collect-errors (settled)
  "Add SETTLED char's associated word/transition to their respective list.
This is unless the char doesn't belong to any word as defined by the
`monkeytype-excluded-chars-regexp'."
  (unless (= (gethash 'state settled) 1)
    (unless (string-match
             monkeytype-excluded-chars-regexp
             (gethash 'source-entry settled))
      (let* ((index (gethash 'source-index settled))
             (transition-p (> index 2))
             (transition  (when transition-p
                            (substring
                             monkeytype--source-text
                             (- index 2)
                             index)))
             (transition-p (and
                            transition-p
                            (string-match "[^ \n\t]" transition))))

        (when transition-p
          (cl-pushnew transition monkeytype--hard-transitions))
        (monkeytype--typed-text-add-to-mistyped-list settled)))))

(defun monkeytype--typed-text-to-string (entries)
  "Format typed ENTRIES and return a string."
  (mapconcat
   (lambda (entries-for-source)
     (let* ((tries (cdr entries-for-source))
            (correctionsp (> (length tries) 1))
            (settled (if correctionsp (car (last tries)) (car tries)))
            (source-entry (gethash 'source-entry settled))
            (typed-entry (monkeytype--typed-text-newline
                          source-entry
                          (gethash 'typed-entry settled)))
            (typed-entry (monkeytype--typed-text-whitespace
                          source-entry
                          typed-entry))
            (settled-correctp (= (gethash 'state settled) 1))
            (settled-index (gethash 'source-index settled))
            (skipped-text  (monkeytype--typed-text-skipped settled-index))
            (prop-settled (propertize
                           (format "%s" typed-entry)
                           'face
                           (monkeytype--typed-text-entry-face
                            settled-correctp)))
            (prop-settled (concat skipped-text prop-settled))
            (corrections (when correctionsp (butlast tries))))
       (if correctionsp
           (monkeytype--typed-text-concat-corrections
            corrections
            settled
            prop-settled)
         (monkeytype--typed-text-collect-errors settled)
         (format "%s" prop-settled))))
   entries
   ""))

(defun monkeytype--typed-text (run)
  "Typed text for RUN."
  (monkeytype--utils-index-chars run)

  (unless monkeytype--words
    (monkeytype--utils-index-words))

  (unless monkeytype--chars-to-words
    (monkeytype--utils-index-chars-to-words))

  (format
   "\n%s\n\n"
   (monkeytype--typed-text-to-string
    (seq-group-by
     (lambda (entry) (gethash 'source-index entry))
     (reverse (gethash 'entries run))))))

;;;; Log:

(defun monkeytype--log (run)
  "Log for the RUN."
  (let* ((entries (reverse (gethash 'entries run)))
         (entries (mapconcat #'monkeytype--log-entry entries "\n")))
    (concat "Log:" (monkeytype--log-header) entries "\n")))

(defun monkeytype--log-header ()
  "Log header."
  (concat
   "\n|"
   "I/S Idx | S/T Chr | N/WPM   | N/CPM   | G/WPM   |"
   "G/CPM   | Acc %   | Time    | Mends   | Errs    |"))

(defun monkeytype--log-entry (entry)
  "Format ENTRY."
  (let* ((chars (gethash 'chars entry))
         (source-index (gethash 'source-index entry))
         (typed-entry (gethash 'typed-entry entry))
         (source-entry (gethash 'source-entry entry))
         (typed-entry (if (string= typed-entry "\n") "↵" typed-entry))
         (source-entry (if (string= source-entry "\n") "↵" source-entry))
         (error-count (gethash 'error-count entry))
         (correction-count (gethash 'correction-count entry))
         (input-index (gethash 'input-index entry))
         (state (gethash 'state entry))
         (elapsed-seconds (gethash 'elapsed-seconds entry))
         (minutes (monkeytype--utils-seconds-to-minutes elapsed-seconds))
         (typed-entry-face (monkeytype--typed-text-entry-face (= state 1)))
         (propertized-typed-entry (propertize
                                   (format "%S" typed-entry)
                                   'face
                                   typed-entry-face)))
    (format "\n|%9s|%9s|%9d|%9d|%9d|%9d|%9.2f|%9s|%9d|%9d|"
            (format "%s %s" input-index source-index)
            (format "%S %s" source-entry propertized-typed-entry)
            (monkeytype--calc-net-wpm
             (monkeytype--calc-words chars)
             error-count
             minutes)
            (monkeytype--calc-net-cpm input-index error-count minutes)
            (monkeytype--calc-gross-wpm
             (monkeytype--calc-words chars)
             minutes)
            (monkeytype--calc-gross-cpm input-index minutes)
            (monkeytype--calc-accuracy
             input-index
             (- input-index error-count)
             correction-count)
            (format-seconds "%.2h:%z%.2m:%.2s" elapsed-seconds)
            correction-count
            (+ error-count correction-count))))

;;;; Mode-line:

(defun monkeytype--mode-line-get-face (successp)
  "Get success or error face based on SUCCESSP."
  (if successp 'monkeytype-mode-line-success 'monkeytype-mode-line-error))

(defun monkeytype--mode-line-report-status ()
  "Take care of mode-line updating."
  (force-mode-line-update))

(defun monkeytype--mode-line-get-current-entry ()
  "Set current entry for mode-line calculations.

Possible scenarios:
1. Either on text-file or not: `monkeytyped--current-run' last entry
2. status-finished: empty hash (to zero out mode-line numbers)
3. status-paused: Either on text-file or not: `monkeytype--runs' last run last
entry, since on paused event current run gets stored in there and
`monkeytype--current-run' has been set to nil."
  (cond (monkeytype--status-finished
         (make-hash-table :test 'equal))
        (monkeytype--status-paused
         (elt (gethash 'entries (elt monkeytype--runs 0)) 0))
        (monkeytype--current-run
         (elt monkeytype--current-run 0))
        (t (make-hash-table :test 'equal))))

(defun monkeytype--mode-line-get-previous-entry ()
  "Set previous entry for mode-line calculations."
  (cond
   ((>= (length monkeytype--runs) 1)
    ;; After pausing even for the first time it will seem that there's
    ;; already a previous run since one side-effects of pausing is a run
    ;; addition to the `monkeytype--runs' list creating a false positive.
    ;; Hence, on the first pause the previous entry must be nil and the
    ;; subsequent one ahead of the normal previous entry.
    (if monkeytype--status-paused
        (if (> (length monkeytype--runs) 1)
            (elt (gethash 'entries (elt monkeytype--runs 1)) 0)
          (if monkeytype--text-file monkeytype--text-file-last-entry nil))
      (elt (gethash 'entries (elt monkeytype--runs 0)) 0)))
   (monkeytype--text-file monkeytype--text-file-last-entry)))

(defun monkeytype--mode-line-get-results ()
  "Get results for current state in typing text."
  (let* ((net-wpm 0) (gross-wpm 0) (accuracy 0)
         (current (monkeytype--mode-line-get-current-entry))
         (previous (monkeytype--mode-line-get-previous-entry))
         (char-count (gethash 'chars current 0))
         (errors (gethash 'error-count current 0))
         (corrections (gethash 'correction-count current 0))
         (words (monkeytype--calc-words char-count))
         (seconds (gethash 'elapsed-seconds current 0))
         (minutes (monkeytype--utils-seconds-to-minutes seconds))
         (time (format "%s" (format-seconds "%.2h:%z%.2m:%.2s" seconds)))
         (not-paused (> (gethash 'input-index current 0) 0))
         (results (make-hash-table  :test 'equal)))

    (when (and previous not-paused)
      (setq char-count (- char-count (gethash 'chars previous 0)))
      (setq words (monkeytype--calc-words char-count))
      (setq errors (- errors (gethash 'error-count previous 0)))
      (setq corrections (- corrections (gethash 'correction-count previous 0))))

    (when (> words 1) ; at least > that 5 chars
      (setq net-wpm (monkeytype--calc-net-wpm words errors minutes))
      (setq gross-wpm (monkeytype--calc-gross-wpm words minutes))
      (setq accuracy
            (monkeytype--calc-accuracy char-count (- char-count errors) corrections)))

    (puthash 'net-wpm net-wpm results)
    (puthash 'gross-wpm gross-wpm results)
    (puthash 'accuracy accuracy results)
    (puthash 'time time results)
    (puthash 'words  words results)
    (puthash 'corrections corrections results)
    (puthash 'errors errors results)
    results))

(defun monkeytype--mode-line-colored-text ()
  "Show coloured version of status in mode line."
  (let* ((results (monkeytype--mode-line-get-results))
        (net-wpm (format "%d" (gethash 'net-wpm results)))
        (gross-wpm (format "%d" (gethash 'gross-wpm results)))
        (accuracy (format "%d" (gethash 'accuracy results)))
        (time (gethash 'time results))
        (words (format "%d" (gethash 'words results)))
        (corrections (gethash 'corrections results))
        (errors (gethash 'errors results))
        (corrections-face (monkeytype--mode-line-get-face
                           (= corrections 0)))
        (errors-face (monkeytype--mode-line-get-face
                      (= errors 0)))
        (corrections (format "%d" corrections))
        (errors (format "%d" errors)))

    (concat
     (propertize "[" 'face 'monkeytype-mode-line-normal)
     (propertize net-wpm 'face 'monkeytype-mode-line-success)
     (propertize "/" 'face 'monkeytype-mode-line-normal)
     (propertize gross-wpm 'face 'monkeytype-mode-line-normal)
     (propertize " " 'face 'monkeytype-mode-line-normal)
     (propertize accuracy 'face 'monkeytype-mode-line-normal)
     (propertize " " 'face 'monkeytype-mode-line-normal)
     (propertize time 'face 'monkeytype-mode-line-info)
     (propertize " (" 'face 'monkeytype-mode-line-normal)
     (propertize words 'face 'monkeytype-mode-line-normal)
     (propertize "/" 'face 'monkeytype-mode-line-normal)
     (propertize corrections 'face corrections-face)
     (propertize "/" 'face 'monkeytype-mode-line-normal)
     (propertize errors 'face errors-face)
     (propertize ")]" 'face 'monkeytype-mode-line-normal))))

(defun monkeytype--mode-line-text ()
  "Show status in mode line."
  (if monkeytype-colored-mode-line
      (monkeytype--mode-line-colored-text)
    (let ((results (monkeytype--mode-line-get-results)))
      (format
       "[%d/%d %d %s (%d/%d/%d)]"
       (gethash 'net-wpm results)
       (gethash 'gross-wpm results)
       (gethash 'accuracy results)
       (gethash 'time results)
       (gethash 'words results)
       (gethash 'corrections results)
       (gethash 'errors results)))))

;;;; Interactive:

;;;###autoload
(defun monkeytype-region (start end)
  "Type marked region from START to END.

\\[monkeytype-region]"
  (interactive "r")
  (monkeytype
   (monkeytype--utils-format-text
    (buffer-substring-no-properties start end))))

;;;###autoload
(defun monkeytype-repeat ()
  "Repeat run.

\\[monkeytype-repeat]"
  (interactive)
  (monkeytype
   (monkeytype--utils-format-text monkeytype--source-text)))

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
  (monkeytype
   (monkeytype--utils-format-text
    (buffer-substring-no-properties (point-min) (point-max)))))

;;;###autoload
(defun monkeytype-pause ()
  "Pause run.

\\[monkeytype-pause]"
  (interactive)
  (setq monkeytype--status-paused t)
  (when monkeytype--start-time (monkeytype--run-pause))
  (monkeytype-wpm-peek)
  (setq monkeytype--current-run '())
  (unless monkeytype--status-finished
    (message "Monkeytype: Paused ([C-c C-c r] to resume.)")))

;;;###autoload
(defun monkeytype-stop ()
  "Finish run.

\\[monkeytype-stop]"
  (interactive)
  (setq monkeytype--wpm-peek-text nil)
  (monkeytype--run-finish))

;;;###autoload
(defun monkeytype-resume ()
  "Resume run.

\\[monkeytype-resume]"
  (interactive)
  (unless monkeytype--status-finished
    (setq monkeytype--status-paused nil)
    (when monkeytype--wpm-peek-text
      (quick-peek-hide)
      (setq monkeytype--wpm-peek-text nil))

    (switch-to-buffer monkeytype--typing-buffer)

    ;; `set-buffer-modified-p' has no be set to nil before adding
    ;; the change-hooks for them to work, so it has to happen right
    ;; before loading monkeytype-mode.
    (set-buffer-modified-p nil)
    (monkeytype-mode)

    (setq buffer-read-only nil)
    (monkeytype--mode-line-report-status)
    (message "Monkeytype: Timer will start when you start typing.")))

;;;###autoload
(defun monkeytype-mistyped-words ()
  "Practice mistyped words for current test.

\\[monkeytype-mistyped-words]"
  (interactive)
  (if (> (length monkeytype--mistyped-words) 0)
      (monkeytype
       (monkeytype--utils-format-words monkeytype--mistyped-words))
    (message "Monkeytype: No word-errors. ([C-c C-c t] to repeat.)")))

;;;###autoload
(defun monkeytype-hard-transitions ()
  "Practice hard key combinations/transitions for current test.

\\[monkeytype-hard-transitions]"
  (interactive)
  (if (> (length monkeytype--hard-transitions) 0)
      (let* ((count (length monkeytype--hard-transitions))
             (append-times (/ monkeytype-minimum-transitions count))
             (final-list '()))
        (cl-loop repeat append-times do
                 (setq final-list
                       (append final-list monkeytype--hard-transitions)))
        (monkeytype
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
  (let* ((path "words")
         (path (monkeytype--utils-file-path path))
         (words (mapconcat #'identity monkeytype--mistyped-words " ")))
    (with-temp-file path (insert words))
    (message "Monkeytype: Words saved successfully to file: %s" path)))

;;;###autoload
(defun monkeytype-save-hard-transitions ()
  "Save hard transitions for current test.

See also: `monkeytype-load-words-from-file'

\\[monkeytype-save-hard-transition]"
  (interactive)
  (let ((path (monkeytype--utils-file-path "transitions")))
    (with-temp-file path
      (insert (mapconcat #'identity monkeytype--hard-transitions " ")))
    (message "Monkeytype: Transitions saved successfully in: %s" path)))

;;;###autoload
(defun monkeytype-load-text-from-file ()
  "Prompt user to enter text-file to use for typing.
Buffer will be filled with the vale of `fill-column' if
`monkeytype-auto-fill' is set to true.

\\[monkeytype-load-text-from-file]"
  (interactive)
  (let* ((dir (concat monkeytype-directory "text/"))
         (path (progn
                 (unless (file-exists-p dir) (make-directory dir t))
                 (read-file-name "Enter text file for typing:" dir)))
         (dir (concat (string-trim path nil "\\.txt\\'") "/"))
         (json-dir (concat dir "json/"))
         (runs (progn
                 (unless (file-exists-p json-dir) (make-directory json-dir t))
                 (directory-files json-dir t "\\.json\\'" nil)))
         (last-run (when runs (elt (reverse runs) 0)))
         (last-run (when last-run (json-read-file last-run)))
         (entries (when last-run (cdr (assoc 'entries last-run))))
         (last-entry (when entries (elt entries 0)))
         (last-entry (when last-entry (map-into last-entry 'hash-table)))
         (text (monkeytype--utils-format-text
                (with-temp-buffer
                  (insert-file-contents path)
                  (buffer-string)))))

    (setq monkeytype--text-file-last-entry last-entry)
    (setq monkeytype--text-file-directory dir)
    (setq monkeytype--text-file path)

    (monkeytype
     text
     (when last-entry
      (lambda ()
        (monkeytype-load-text-from-file-start text last-entry))))))

(defun monkeytype-load-text-from-file-start (text entry)
  "Allow resuming/continuing typing TEXT by setting vars to last ENTRY."
  (let* ((index (gethash 'source-index entry))
         (input-index (gethash 'input-index entry))
         (chars (gethash 'chars entry))
         (errors (gethash 'error-count entry))
         (corrections (gethash 'correction-count entry))
         (end-point (1+ index))
         (remaining-counter (1+ (- (length text) end-point ))))
    (setq monkeytype--counter-remaining remaining-counter)
    (setq monkeytype--counter-chars chars)
    (setq monkeytype--counter-input input-index)
    (setq monkeytype--counter-error errors)
    (setq monkeytype--counter-correction corrections)
    (setq monkeytype--counter-ignored-change 0)
    (add-text-properties 1 end-point monketype--utils-disabled-props)
    (goto-char end-point)))

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
  (let* ((path (read-file-name "Enter words file:" monkeytype-directory))
         (words (with-temp-buffer
                  (insert-file-contents path)
                  (buffer-string)))
         (words (split-string words monkeytype-excluded-chars-regexp t))
         (words (monkeytype--utils-format-words words)))
    (monkeytype words)))

;;;###autoload
(defun monkeytype-region-as-words (start end)
  "Put the marked region from START to END in typing buffer.

Words will be randomized if `monkeytype-randomize' is set to true.
Words will be downcased if `monkeytype-downcase' is set to true.
Words special characters will get removed based on
`monkeytype-excluded-chars-regexp'.
Buffer will be filled with the vale of `fill-column' if
`monkeytype-auto-fill' is set to true.

\\[monkeytype-region-as-words]"
  (interactive "r")
  (let* ((text (buffer-substring-no-properties start end))
         (text (split-string text monkeytype-excluded-chars-regexp t))
         (text (monkeytype--utils-format-words text)))
    (monkeytype text)))

;;;###autoload
(defun monkeytype-most-mistyped-words ()
  "Type most mistyped words from all word-files in `monkeytype-directory'.

See: `monkeytype-save-mistyped-words' for how word-files are saved.

\\[monkeytype-most-mistyped-words]"
  (interactive)
  (let* ((dir (concat monkeytype-directory "/words"))
         (files (directory-files dir t "\\.txt\\'" nil))
         (words (with-temp-buffer
                  (dolist (file files)
                    (insert-file-contents file))
                  (split-string (buffer-string))))
         (grouped-words (seq-group-by #'identity words))
         (grouped-words (seq-group-by #'length grouped-words))
         (words '()))

    (dolist (word-group (reverse grouped-words))
      (dolist (word (cdr word-group))
        (cl-pushnew (car word) words)))

    (if (> (length words) monkeytype-most-mistyped-amount)
        (progn
          (setq words (seq-take words monkeytype-most-mistyped-amount))
          (monkeytype (monkeytype--utils-format-words words)))
      (message "Monkeytype: Not enough mistyped words for test."))))


;;;###autoload
(defun monkeytype-save-text-from-url (url file-name)
  "Download URL to `monketype-directory', naming it FILE-NAME.

This function shells out to pandoc(1) which character-encodes in UTF-8
so some characters might not be desirable for monkeytyping, so the custom
`monkeytype-asciify' option has be given to optionally allow for
further character encoding to ASCII (using iconv(1))."
  (interactive "sURL: \nsName for the text-file:")

  (monkeytype--utils-check-for-pandoc)
  (let* ((path (concat monkeytype-directory "text/" file-name))
         (cmd "pandoc")
         (url-opts (format " -s -r html %s" url))
         (text-opts " -t plain")
         (asciify (if (monkeytype--utils-check-for-iconv)
                      (format
                       " | iconv -c --to-code=ASCII//TRANSLIT > %s"
                       path)
                    (format " -o %s" path))))

    (when (file-exists-p path)
      (error "Monkeytype Error: File %s already exists" path))

    (shell-command (concat cmd url-opts text-opts asciify))
    (find-file path)))

;;;###autoload
(defun monkeytype-toggle-mode-line ()
  "Hide or show WPM results in mode-line."
  (interactive)
  (if monkeytype-mode-line
      (setq monkeytype-mode-line nil)
    (setq monkeytype-mode-line '(:eval (monkeytype--mode-line-text))))
  (monkeytype--mode-line-report-status))

;;;###autoload
(defun monkeytype-wpm-peek ()
  "Hide/Show overlay with WPM info."
  (interactive)
  (when monkeytype--status-finished
    (error "Monkeytype Error: Can't peek WPM when already finished"))

  (unless (> (quick-peek-hide (point)) 0)
    (message "Monkeytype: Generating WPM results.")

    (setq monkeytype--previous-run-last-entry
          (monkeytype--mode-line-get-previous-entry))

    (when  monkeytype--previous-run-last-entry
      (setq monkeytype--previous-last-entry-index
            (gethash 'source-index monkeytype--previous-run-last-entry)))

    (unless monkeytype--wpm-peek-text
      (let* ((run (elt monkeytype--runs 0))
             (run-typed-text (monkeytype--typed-text run))
             (run-results (monkeytype--results-run (gethash 'entries run)))
             (str (concat run-results "\n\nTyped Text:\n" run-typed-text)))
        (scrollable-quick-peek-show str (point) 10 10))
      (setq monkeytype--wpm-peek-text t))))

;;;; Minor mode:
(defvar monkeytype-mode-map
  (let ((map (make-sparse-keymap))
        (mappings '("C-c C-c p" monkeytype-pause
                    "C-c C-c r" monkeytype-resume
                    "C-c C-c s" monkeytype-stop
                    "C-c C-c t" monkeytype-repeat
                    "C-c C-c f" monkeytype-fortune
                    "C-c C-c m" monkeytype-mistyped-words
                    "C-c C-c h" monkeytype-hard-transitions
                    "C-c C-c a" monkeytype-save-mistyped-words
                    "C-c C-c l" monkeytype-toggle-mode-line
                    "C-c C-c e" monkeytype-wpm-peek
                    "C-c C-c o" monkeytype-save-hard-transitions)))
    (cl-loop for (key fn) on mappings by #'cddr
             do (define-key map (kbd key) fn))
    map)
  "Keymap for `monkeytype-mode' buffers.")

;;;###autoload
(define-minor-mode monkeytype-mode
  "Monkeytype mode is a minor mode for speed/touch typing.

\\{monkeytype-mode-map}"
  :lighter monkeytype-mode-line
  :keymap monkeytype-mode-map
  (if monkeytype-mode
      (progn
        (font-lock-mode nil)
        (buffer-face-mode t)
        (buffer-face-set 'monkeytype-default)
        (monkeytype--run-add-hooks))
    (font-lock-mode t)
    (buffer-face-mode nil)))

(provide 'monkeytype)

;;; monkeytype.el ends here
