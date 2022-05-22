;;; stem-reading-mode.el --- Highlight word stems for speed-reading -*- lexical-binding: t -*-

;; Author: Yuri D'Elia <wavexx@thregr.org>
;; Version: 0.1
;; Package-Version: 20220522.1053
;; Package-Commit: 6efc9962e3a19a452c7ab9636cf1e2566a51bd38
;; URL: https://gitlab.com/wavexx/stem-reading-mode.el
;; Package-Requires: ((emacs "25.1"))
;; Keywords: convenience, wp

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;;; Commentary:

;; Highlight word stems in text buffers, thereby providing artificial
;; fixation points to improve speed reading.
;;
;; Use M-x stem-reading-mode in a text buffer to turn on (or off) the
;; minor mode. Customize `stem-reading-highlight-face' to modify the
;; default highlight. Set `stem-reading-overlay' to add the highlight
;; to all words unconditionally.
;;
;; With some modes, instead of highlighting the word stem, it might be
;; convenient to de-light the remaining part of a word instead. You can
;; achieve this effect by customizing `stem-reading-delight-face'.
;;
;; On Hi-Dpi displays (and a good font), a configuration similar to the
;; following can give excellent results:
;;
;; (require 'stem-reading-mode)
;; (set-face-attribute 'stem-reading-highlight-face nil :weight 'unspecified)
;; (set-face-attribute 'stem-reading-delight-face nil :weight 'light)

;;; Code:

;; Customizable parameters
(defgroup stem-reading nil
  "Minor mode highlighting word stems for speed-reading."
  :group 'text)

(defface stem-reading-highlight-face
  '((t :weight bold))
  "Face used for highlighting word stems."
  :group 'stem-reading)

(defface stem-reading-delight-face
  '((t))
  "Face used for delighting the regular (non-stemmed) part of a word."
  :group 'stem-reading)

(defcustom stem-reading-overlay nil
  "Control the priority of the stem highlight.
When nil (default), only highlight words which are not already
highlighted by other modes.

When t or 'prepend, prepend the highlight face to all words so that it
has higher priority than other modes.

When 'append, append the highlight instead.

Requires a mode toggle to take effect."
  :type '(choice (const t)
		 (const prepend)
		 (const append)
		 (const nil))
  :group 'stem-reading)

(defvar stem-reading--overlay-state nil
  "Overlay state since the last mode activation.")


;; Helper functions
(defun stem-reading--keywords ()
  "Compute font-lock keywords for word stems."
  (let ((priority stem-reading--overlay-state))
    (let ((keywords `(("\\<\\(\\w\\)\\(\\w\\{,2\\}\\)"
		       (1 'stem-reading-highlight-face ,priority)
		       (2 'stem-reading-delight-face ,priority)))))
      (dotimes (c 16)
	(let ((n (+ 2 c)))
	  (push (list
		 (format
		  "\\<\\(\\w\\{%d\\}\\)\\(\\w\\{%d,\\}\\)"
		  n (ceiling (* n 0.6)))
		 `(1 'stem-reading-highlight-face ,priority)
		 `(2 'stem-reading-delight-face ,priority))
		keywords)))
      keywords)))


;;;###autoload
(define-minor-mode stem-reading-mode
  "Highlight word stems for speed-reading."
  :lighter " SR"
  (cond
   (stem-reading-mode
    (setq stem-reading--overlay-state
	  (if (eq stem-reading-overlay t) 'prepend
	    stem-reading-overlay))
    (font-lock-add-keywords nil (stem-reading--keywords) 'append))
   (t
    (font-lock-remove-keywords nil (stem-reading--keywords))))
  (font-lock-flush))


(provide 'stem-reading-mode)

;;; stem-reading-mode.el ends here
