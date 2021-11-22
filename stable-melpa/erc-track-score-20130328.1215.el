;;; erc-track-score.el --- Add score support to tracked channel buffers

;; Copyright (C) 2010 Julien Danjou

;; Author: Julien Danjou <julien@danjou.info>
;; URL: http://julien.danjou.info/erc-track-score.html
;; Package-Version: 20130328.1215
;; Package-Commit: 5b27531ea6b1a4c4b703b270dfa9128cb5bfdaa3

;; This file is NOT part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Change `erc-track-showcount' value to transform it to a score.

;; (require 'erc-track-score)
;; (erc-track-mode 1)
;; (erc-track-score-mode 1)
;; (setq erc-track-showcount t)

(eval-when-compile (require 'cl))
(require 'erc)
(require 'erc-track)
(require 'erc-match)
(require 'timer)

;;; Code:

(defgroup erc-track-score nil
  "Show score of tracked active buffers in the modeline."
  :group 'erc-track)

(defcustom erc-track-score-reset-every 10
  "How often in seconds to change the channel score by
  `erc-track-score-reset-by' in order to reset it to 0."
  :group 'erc-track-score
  :type 'number)

(defcustom erc-track-score-reset-by 1
  "How much to subtract or add to from the score of the channel
  every `erc-track-score-reset-every'."
  :group 'erc-track-score
  :type 'number)

(defcustom erc-track-score-matched-text
  '((current-nick 20)
    (keyword 5)
    (pal 2)
    (dangerous-host -5)
    (fool -2))
  "Assoc list of scores to add when text is matched. It should be
  used with form (KEY SCORE), where KEY is a valid key from
  `erc-text-matched-hook', and score the score to add current
  channel. Note that this score is added after the score has been
  incremented by 1 because a message has been received."
  :group 'erc-track-score)

(defvar erc-track-score-timer nil
  "The timer of the channel tracking score.")

(defun erc-track-score-reset ()
  (dolist (channel-entry erc-modified-channels-alist)
    (let ((erc-channel-buffer (car channel-entry)))
      (save-excursion
        (set-buffer erc-channel-buffer)
        (let* ((number-of-unseen-message (nth 1 channel-entry))
               (operator (cond ((> number-of-unseen-message 0) '-)
                               ((< number-of-unseen-message 0) '+)
                               (t nil))))
          (when operator
            (setf (nth 1 channel-entry) (funcall
                                         operator
                                         (nth 1 channel-entry)
                                         erc-track-score-reset-by)))))))
  (erc-modified-channels-display))

(defun erc-track-score-update-on-match (match-type nickuserhost message)
  "Function called when `erc-match' matches something."
  (let ((channel-entry (assoc (current-buffer) erc-modified-channels-alist)))
    (when channel-entry
      (let ((erc-channel-number-of-unseen-message (nth 1 channel-entry)))
        (let ((score
               (assoc
                match-type
                erc-track-score-matched-text)))
          (when score
            (setf (nth 1 channel-entry)
                  (+ (cadr score)
                     (nth 1 channel-entry)))
            (erc-modified-channels-display)))))))

;;;###autoload (autoload 'erc-track-score-mode "erc-track-score" nil t)
(define-erc-module track-score nil
  "This mode adds score support to erc-track."
  ((unless erc-track-score-timer
     (setq erc-track-score-timer
           (run-with-timer
            erc-track-score-reset-every
            erc-track-score-reset-every
            'erc-track-score-reset)))
   (add-hook 'erc-text-matched-hook 'erc-track-score-update-on-match))
  ((when erc-track-score-timer
     (cancel-timer erc-track-score-timer))
   (remove-hook 'erc-text-matched-hook 'erc-track-score-update-on-match)))

(provide 'erc-track-score)

;;; erc-track-score.el ends here
