;;; wwg.el --- Writer word goals  -*- lexical-binding: t -*-

;; Copyright (C) 2021 Andrea

;; Author: Andrea andrea-dev@hotmail.com>
;; Version: 0.1.1
;; Package-Version: 20210614.1527
;; Package-Commit: 46c8a7c71275ced2c662c1222d4b85319f80dd83
;; Package-Requires: ((emacs "25.1"))
;; Keywords: wp
;; Homepage: https://github.com/ag91/writer-word-goals

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>

;;; Commentary:

;; A mode that gives you focus in achieving your writing goals.
;;
;; This mode allows you to set a writing goal and achieve it. The main
;; feature is to let you define a number of words and the mode
;; periodically prizes your efforts by printing encouragement messages
;; in the console. The messages shows only when your cursor is in the
;; buffer in which you set a writing goal. This mode also allows you
;; to set multiple goals in different buffers, although it is not
;; advised because distracting.
;;
;; The aim of this mode is to give a structure in your writing. The
;; idea is to write everyday N (ideally 1k) words. The next day you
;; should edit what you wrote, and write some more.
;;
;; This mode also provides editing utilities. `wwg-editing-mode' lets
;; you set a goal for your editing session. Once this start, `wwg'
;; will encourage your editing progress as `wwg-mode' does. It will
;; also show the parts of your text that are less readable.
;;
;; Furthermore, you can see how readable your text is while you are
;; writing: just use `wwg-score-sentences-mode' and
;; `wwg-score-paragraphs-mode' according to the granularity you need.
;;
;; Other utilities provide similar functionality:
;; - count-words: Emacs built-in to count the words in the buffer
;; - org-wc: this counts words in Org-Mode buffers
;; - wc-goal-mode and wc-mode: these keep track of how many words you wrote in the modeline
;;
;; This mode differs from the above because encourages you
;; periodically to not surrender your writing dreams.
;;
;; See documentation on https://github.com/ag91/writer-word-goals

;;; Code:

(defgroup wwg nil
  "Options specific to wwg."
  :tag "wwg"
  :group 'wwg)

(defvar wwg-active-timer-alist
  nil
  "Alist of (buffer . timer) bindings to cleanup achieved targets.")

(defvar wwg-monitor-function
  'wwg-check-count-and-beep-with-message-if-finished
  "The function to monitor the target was reached in buffer.
It takes two arguments: a number (target) and the buffer.
   It should return any value when it finds the target satisfied for cleanup purposes.")

(defcustom wwg-monitor-period
  15
  "How many seconds before checking if a writer has reached the words target.
Defaults to a minute."
  :group 'wwg
  :type 'string)

(defun wwg-choose-message (remaining-words)
  "Produce a message according to the delta between TARGET-COUNT and REMAINING-WORDS."
  (cond
   ((< remaining-words 50) "Fabulous, so close!")
   ((< remaining-words 200) "You are quite done, awesome!")
   ((< remaining-words 500) "Okay, doing good effort there!")
   ((< remaining-words 800) "Not bad!")
   ('otherwise "Okay!")))

(defun wwg-check-count-and-beep-with-message-if-finished (target-count buffer)
  "Beep if TARGET-COUNT was reached in BUFFER."
  (let* ((total-so-far
          (with-current-buffer buffer
            (count-words (point-min) (point-max))))
         (remaining-words (- target-count total-so-far)))
    (if (<= remaining-words 0)
        (progn
          (beep)
          (message
           "Well done! You wrote %s words, and %s extra words of what you planned!!"
           target-count
           (abs remaining-words))
          'finished)
      (message
       "%s %s words left."
       (wwg-choose-message remaining-words)
       remaining-words)
      nil)))

(defun wwg-run-monitor (target-number buffer &optional fn)
  "Call `wwg-monitor-function' with TARGET-NUMBER and BUFFER.
Cleanup timer if completed.
Optionally pass a custom FN to monitor."
  (when (and
         (eq buffer (current-buffer))
         (funcall (or fn wwg-monitor-function) target-number buffer))
    (cancel-timer (car (alist-get buffer wwg-active-timer-alist)))))

(defun wwg-monitor-word-count-for-buffer (target-number buffer &optional fn)
  "Monitor if the writer reached the TARGET-NUMBER in BUFFER.
It runs only every `wwg-monitor-period' seconds.
Optionally pass a custom FN to monitor."
  (add-to-list
   'wwg-active-timer-alist
   (list
    buffer
    (run-with-timer
     wwg-monitor-period
     wwg-monitor-period
     `(lambda () (wwg-run-monitor ,target-number ,buffer ',fn))))))

;;;###autoload
(define-minor-mode wwg-mode
  "Toggle writer goal mode for writing some number of words."
  :group 'wwg
  (if (not wwg-mode)
      (cancel-timer (car (alist-get (current-buffer) wwg-active-timer-alist)))
    (let* ((current (count-words (point-min) (point-max)))
           (target (read-number "How many words do you want to write? " 1000)))
      (wwg-monitor-word-count-for-buffer (+ current target) (current-buffer)))))

;; BEGIN editing

(defface wwg-red-face
  '((((class grayscale)
      (background light)) (:background "DimGray"))
    (((class grayscale)
      (background dark))  (:background "LightGray"))
    (((class color)
      (background light)) (:foreground "Black" :background "OrangeRed"))
    (((class color)
      (background dark))  (:foreground "Black" :background "DarkOrange1")))
  "Face used to highlight current line.")

(defface wwg-yellow-face
  '((((class grayscale)
      (background light)) (:background "DimGray"))
    (((class grayscale)
      (background dark))  (:background "LightGray"))
    (((class color)
      (background light)) (:foreground "Black" :background "LightYellow"))
    (((class color)
      (background dark))  (:foreground "Black" :background "DarkOrange1")))
  "Face used to highlight current line.")

(defface wwg-green-face
  '((((class grayscale)
      (background light)) (:background "DimGray"))
    (((class grayscale)
      (background dark))  (:background "LightGray"))
    (((class color)
      (background light)) (:foreground "Black" :background "LightGreen"))
    (((class color)
      (background dark))  (:foreground "Black" :background "DarkOrange1")))
  "Face used to highlight current line.")

(defun wwg-pick-color-face (score)
  "Pick a face according to SCORE."
  (cond
   ((<= score 50) 'wwg-red-face)
   ((<= score 85) 'wwg-yellow-face)
   ('otherwise 'wwg-green-face)))

;;;;; BEGIN Taken from writegood-mode: you should try this awesome mode out https://github.com/bnbeckwith/writegood-mode

(defcustom wwg-sentence-punctuation
  '(?. ?? ?!)
  "List of punctuation denoting sentence end."
  :group 'wwg
  :type '(repeat character))

(defun wwg-count-words (rstart rend)
  "Count the words specified by the region bounded by RSTART and REND."
  (if (boundp 'count-words)
      (count-words rstart rend)
    (how-many "[[:word:]]+" rstart rend)))

(defun wwg-count-sentences (rstart rend)
  "Count the sentences specified by the region bounded by RSTART and REND."
  (how-many (regexp-opt-charset wwg-sentence-punctuation) rstart rend))

(defun wwg-count-syllables (rstart rend)
  "Count the number of syllables in the region bounded by RSTART and REND.
This is approximate.
Consecutive vowels count as one syllable.
The endings -es -ed and -e are not counted as syllables."
  (- (how-many "[aeiouy]+" rstart rend)
     (how-many "\\(es\\|ed\\|e\\)\\b" rstart rend)))

(defun wwg-fk-parameters (&optional rstart rend)
  "Flesch-Kincaid reading parameters.
Optionally pass a region with RSTART and REND."
  (let* ((start (cond (rstart rstart)
                      ((and transient-mark-mode mark-active) (region-beginning))
                      ('t (point-min))))
         (end   (cond (rend rend)
                      ((and transient-mark-mode mark-active) (region-end))
                      ('t (point-max))))
         (words     (float (wwg-count-words start end)))
         (syllables (float (wwg-count-syllables start end)))
         (sentences (float (wwg-count-sentences start end))))
    (list sentences words syllables)))

(defun wwg-calculate-reading-ease (&optional start end)
  "Calculate score of Flesch-Kincaid reading ease test.
Optionally pass the region bounded by START and END.

Scores roughly between 0 and 100."
  (let* ((params (wwg-fk-parameters start end))
         (sentences (nth 0 params))
         (words     (nth 1 params))
         (syllables (nth 2 params)))
    (- 206.835 (* 1.015 (/ words sentences)) (* 84.6 (/ syllables words)))))

;;;;; END Taken from writegood-mode

(defun wwg-highlight-paragraphs ()
  "Highlight paragraphs according to easy score."
  (save-excursion
    (goto-char (point-min))
    (let (last-visited)
      (while (and
              (bounds-of-thing-at-point 'paragraph)
              (not (eq last-visited (point-max))))
        (let* ((bounds (bounds-of-thing-at-point 'paragraph))
               (begin (car bounds))
               (end (cdr bounds))
               (score (wwg-calculate-reading-ease begin end))
               (color-face (wwg-pick-color-face score)))
          (ignore-errors (wwg-unhighlight-region begin))
          (wwg-highlight-region begin end color-face)
          (setq last-visited (point))
          (forward-paragraph))))))

(defun wwg-unhighlight-paragraphs ()
  "Remove paragraph highlighting."
  (save-excursion
    (goto-char (point-min))
    (let (last-visited)
      (while (and
              (bounds-of-thing-at-point 'paragraph)
              (not (eq last-visited (point-max))))
        (let ((bounds (bounds-of-thing-at-point 'paragraph)))
          (wwg-unhighlight-region (car bounds))
          (setq last-visited (point))
          (forward-paragraph))))))

(defun wwg-highlight-sentences ()
  "Highlight sentences according to easy score."
  (save-excursion
    (goto-char (point-min))
    (while (bounds-of-thing-at-point 'sentence)
      (let* ((bounds (bounds-of-thing-at-point 'sentence))
             (begin (car bounds))
             (end (cdr bounds))
             (score (wwg-calculate-reading-ease begin end))
             (color-face (wwg-pick-color-face score)))
        (ignore-errors (wwg-unhighlight-region begin))
        (wwg-highlight-region begin end color-face)
        (forward-sentence)))))

(defun wwg-unhighlight-sentences ()
  "Remove sentence highlighting."
  (save-excursion
    (goto-char (point-min))
    (while (bounds-of-thing-at-point 'sentence)
      (let ((bounds (bounds-of-thing-at-point 'sentence)))
        (wwg-unhighlight-region (car bounds))
        (forward-sentence)))))

(defun wwg-highlight-region (begin end &optional color-face)
  "Highlight region between BEGIN and END in green, unless COLOR-FACE."
  (let ((overlay (make-overlay begin end)))
    (overlay-put overlay 'category 'wwg-overlay)
    (overlay-put overlay 'face (or color-face 'wwg-green-face))))

(defun wwg-unhighlight-region (point)
  "Delete any overlay at POINT. Optionally only those with COLOR-FACE."
  (let* ((overlays (overlays-at point))
         (wwg-overlays (seq-filter (lambda (it) (eq (overlay-get it 'category) 'wwg-overlay)) overlays)))
    (dolist (it wwg-overlays) (delete-overlay it))))

(defvar wwg-editing-highlighting-atom 'sentence "What to highlight for editing.")

(defun wwg-highlight-for-editing ()
  "Highlight complexity for editing."
  (interactive)
  (cond
   ((eq wwg-editing-highlighting-atom 'sentence) (wwg-highlight-sentences))
   ((eq wwg-editing-highlighting-atom 'paragraph) (wwg-highlight-paragraphs))))

(defun wwg-unhighlight-for-editing ()
  "Unhighlight complexity for editing."
  (interactive)
  (cond
   ((eq wwg-editing-highlighting-atom 'sentence) (wwg-unhighlight-sentences))
   ((eq wwg-editing-highlighting-atom 'paragraph) (wwg-unhighlight-paragraphs))))

(defun wwg-toggle-highlighting-atom ()
  "Toggle `wwg-toggle-highlighting-atom' for highlighting style between sentences and paragraphs."
  (interactive)
  (cond
   ((eq wwg-editing-highlighting-atom 'sentence)
    (progn
      (setq wwg-editing-highlighting-atom 'paragraph)
      (wwg-unhighlight-sentences)
      (wwg-highlight-for-editing)))
   ((eq wwg-editing-highlighting-atom 'paragraph)
    (progn
      (setq wwg-editing-highlighting-atom 'sentence)
      (wwg-unhighlight-paragraphs)
      (wwg-highlight-for-editing)))))

(defun wwg-toggle-highlighting ()
  "Toggle editing highlighting."
  (interactive)
  (if (ignore-errors (eq 'wwg-overlay (overlay-get (car (overlays-at (point-min))) 'category)))
      (wwg-unhighlight-for-editing)
    (wwg-highlight-for-editing)))

(defun wwg-highlight-sentences-after-end ()
  "Highlight readibility in paragraphs if last command ended a sentence."
  (if (string-match-p
       sentence-end-base
       (make-string 1 last-command-event))
      (wwg-highlight-sentences)))

;;;###autoload
(define-minor-mode wwg-score-sentences-mode
  "Toggle writer goal mode highlighting for sentences readibility."
  :group 'wwg
  (if (not wwg-score-sentences-mode)
      (progn
        (wwg-unhighlight-sentences)
        (remove-hook 'after-save-hook #'wwg-highlight-sentences 't)
        (remove-hook 'post-self-insert-hook #'wwg-highlight-sentences-after-end 't))
    (wwg-highlight-sentences)
    (add-hook 'after-save-hook #'wwg-highlight-sentences nil 't)
    (add-hook 'post-self-insert-hook #'wwg-highlight-sentences-after-end nil 't)))

(defun wwg-highlight-paragraphs-after-fill ()
  "Highlight readibility in paragraphs if last command was a paragraph fill."
  (if (string-match-p
       (regexp-quote "fill-paragraph")
       (symbol-name real-this-command))
      (wwg-highlight-paragraphs)))

;;;###autoload
(define-minor-mode wwg-score-paragraphs-mode
  "Toggle writer goal mode highlighting for paragraphs readibility."
  :group 'wwg
  (if (not wwg-score-paragraphs-mode)
      (progn
        (wwg-unhighlight-paragraphs)
        (remove-hook 'after-save-hook #'wwg-highlight-paragraphs 't)
        (remove-hook 'post-command-hook #'wwg-highlight-paragraphs-after-fill 't))
    (wwg-highlight-paragraphs)
    (add-hook 'after-save-hook #'wwg-highlight-paragraphs nil 't)
    (add-hook 'post-command-hook #'wwg-highlight-paragraphs-after-fill nil 't)))

(defun wwg-editing-highlighting-hook-fn ()
  "Hook function after saving to use during an editing session to find more easily editing targets."
  (wwg-unhighlight-for-editing)
  (wwg-highlight-for-editing))

(defun wwg-calculate-readability-buffer (buffer)
  "Calculate readability of BUFFER."
  (with-current-buffer buffer
    (wwg-calculate-reading-ease (point-min) (point-max))))

(defun wwg-editing-goal-diff (editing-goal buffer)
  "Check how far away we are from EDITING-GOAL in BUFFER."
  (- editing-goal (wwg-calculate-readability-buffer buffer)))

(defun wwg-editing-goal-reached-p (editing-goal buffer)
  "Check if EDITING-GOAL is reached in BUFFER."
  (<= (wwg-editing-goal-diff editing-goal buffer) 0))

(defun wwg-check-readibility-and-beep-with-message-if-finished (target-count buffer)
  "Beep if TARGET-COUNT was reached in BUFFER."
  (if (wwg-editing-goal-reached-p target-count buffer)
      (progn
        (beep)
        (wwg-unhighlight-for-editing)
        (remove-hook 'after-save-hook 'wwg-editing-highlighting-hook-fn 't)
        (message
         "Well done! You increased readability of %.2f%%, now it is at %.2f%%!!"
         target-count
         (wwg-calculate-readability-buffer buffer)))
    (message
     "Okay! Just %.2f%% readability more."
     (wwg-editing-goal-diff target-count buffer))
    nil))

(defun wwg-get-editing-goal ()
  "Ask user for a rate of improvement."
  (let* ((goal-as-string
          (completing-read
           "Choose readability increase: "
           (list "Easy: 5%" "Medium: 20%" "Hard: 50%")
           nil
           't
           nil
           nil
           "Easy: 5%"))
         (untrimmed-goal
          (substring
           goal-as-string
           (- (length goal-as-string) 3)
           (- (length goal-as-string) 1))))
    (string-to-number
     (string-trim untrimmed-goal))))

;;;###autoload
(define-minor-mode wwg-editing-mode
  "Toggle writer goal mode for writing some number of words."
  :group 'wwg
  (if (not wwg-editing-mode)
      (progn
        (wwg-score-sentences-mode -1)
        (remove-hook 'after-save-hook 'wwg-editing-highlighting-hook-fn 't)
        (cancel-timer (car (alist-get (current-buffer) wwg-active-timer-alist))))
    (let* ((target (wwg-get-editing-goal))
           (buffer (current-buffer))
           (current-readibility (wwg-calculate-readability-buffer buffer)))
      (add-hook 'after-save-hook 'wwg-editing-highlighting-hook-fn nil 't)
      (wwg-score-sentences-mode 1)
      (wwg-monitor-word-count-for-buffer
       (+ current-readibility target)
       buffer
       #'wwg-check-readibility-and-beep-with-message-if-finished))))

;; END editing

(provide 'wwg)
;;; wwg.el ends here

;; Local Variables:
;; time-stamp-pattern: "10/Version:\\?[ \t]+1.%02y%02m%02d\\?\n"
;; End:
