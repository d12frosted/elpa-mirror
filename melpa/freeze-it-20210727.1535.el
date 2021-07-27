;;; freeze-it.el --- Minor mode to make your previous writing read-only  -*- lexical-binding: t; -*-

;; Copyright (c) 2020-2021  Paul W. Rankin

;; Author: Paul W. Rankin <pwr@bydasein.com>
;; Keywords: wp, text
;; Package-Version: 20210727.1535
;; Package-Commit: 151d264a0d0593b413b5a984b391023e905a190b
;; Version: 0.2.2
;; Package-Requires: ((emacs "24.4"))
;; URL: https://github.com/rnkn/freeze-it

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Freeze It
;; =========

;; An Emacs minor mode to kill your inner editor! Every writer struggles to
;; balance their creative and critical sides, with progress frequently
;; hindered by the temptation to go back and revise to get things *just
;; right*. Freeze It aims to combat this temptation.

;; After an idle delay freeze-it-delay all text between point-min and a
;; configurable distance before point will be made read-only.

;; Option freeze-it-go-back controls how far this distance "goes back"
;; before freezing text. This can be nil, word, line, visible-line,
;; line, or paragraph.

;; Command freeze-it-show will momentarily highlight read-only text in
;; the buffer while there is no user input. The highlighting uses
;; freeze-it-show face and displays for freeze-it-show-delay seconds.

;; Text remains read-only until you kill the buffer, so that you can't
;; cheat. This is by design, because the minor mode targets the
;; psychological *temptation* to revise your writing, rather than just the
;; ability.

;; Installation
;; ------------

;; The latest stable release is available via [MELPA-stable][1]. First, add
;; MELPA-stable to your package archives:

;;     M-x customize-option RET package-archives RET

;; Insert an entry named melpa-stable with URL:
;; https://stable.melpa.org/packages/

;; You can then find the latest stable version of freeze-it in the list
;; returned by:

;;     M-x list-packages RET

;; If you prefer the latest but perhaps unstable version, do the above
;; using [MELPA][2].


;; Bugs and Feature Requests
;; -------------------------

;; Send me an email (address in the package header). For bugs, please
;; ensure you can reproduce with:

;;     $ emacs -Q -l freeze-it.el

;; Known issues are tracked with FIXME comments in the source.


;; [1]: https://stable.melpa.org/#/freeze-it
;; [2]: https://melpa.org/#/freeze-it


;;; Code:

(defgroup freeze-it
  nil
  "Options for freeze minor mode."
  :prefix "freeze-it-"
  :group 'text)

(defcustom freeze-it-delay
  5
  "Number of seconds in idle time before running `freeze-it-now'."
  :type 'number
  :safe 'numberp
  :group 'freeze-it)

(defcustom freeze-it-go-back
  'line
  "Amount of text before point to go back before freezing."
  :type '(choice (const :tag "None" nil)
                 (const :tag "Word" word)
                 (const :tag "Line" line)
                 (const :tag "Visible Line" visible-line)
                 (const :tag "Paragraph" paragraph))
  :safe 'symbolp
  :group 'freeze-it)

(defcustom freeze-it-lighter
  " FREEZE!"
  "Mode-line indicator for `freeze-it-mode'."
  :type '(choice (const :tag "No lighter" "") string)
  :safe 'stringp
  :group 'freeze-it)

(defcustom freeze-it-show-delay 1.25
  "Number of seconds to show read-only text with `freeze-it-show'."
  :type 'number
  :safe 'numberp
  :group 'freeze-it)

(defface freeze-it-show
  '((t (:inherit shadow)))
  "Default face for showing read-only text with `freeze-it-show'.")

(defvar-local freeze-it-overlay nil
  "Overlay used to highlight read-only text.")

(defun freeze-it-now ()
  "Make text before point read-only, first going back by `freeze-it-go-back'."
  (when (bound-and-true-p freeze-it-mode)
    (save-excursion
      (save-restriction
        (widen)
        (let ((go-back
               (intern-soft (concat "forward-"
                                    (symbol-name freeze-it-go-back)))))
          (when go-back (funcall go-back -1)))
        (with-silent-modifications
          (put-text-property (point-min) (point) 'read-only t))))))

(defun freeze-it-make-overlay ()
  "Make the overlay highlighting read-only text."
  (setq freeze-it-overlay
        (make-overlay (point-min)
                      (next-single-property-change (point-min) 'read-only)))
  (overlay-put freeze-it-overlay 'face 'freeze-it-show))

(defun freeze-it-delete-overlay ()
  "Remove the overlay highlighting read-only text."
  (when (overlayp freeze-it-overlay)
    (delete-overlay freeze-it-overlay)))

(defun freeze-it-show ()
  "Momentarily highlight read-only text."
  (interactive)
  (when (get-char-property (point-min) 'read-only)
    (unwind-protect
        (while-no-input
          (freeze-it-make-overlay)
          (redisplay)
          (sleep-for freeze-it-show-delay))
      (freeze-it-delete-overlay))))

(define-minor-mode freeze-it-mode
  "When enabled, text before point in the current buffer is made
read-only after idle timer `freeze-it-delay'.

Option `freeze-it-go-back' will go back this far before making
everything prior read-only.

Option `freeze-it-delay' is the number of seconds to wait before
freezing text.

The text remains read-only until you kill the buffer, so that you
can't cheat."
  :init-value nil
  :lighter freeze-it-lighter
  (if freeze-it-mode
      (run-with-idle-timer freeze-it-delay t #'freeze-it-now)
    (cancel-function-timers #'freeze-it-now)
    (message "Freeze-It mode disabled in current buffer; \
note that frozen text remains read-only")))

(provide 'freeze-it)
;;; freeze-it.el ends here

;; Local Variables:
;; coding: utf-8
;; fill-column: 80
;; require-final-newline: t
;; sentence-end-double-space: nil
;; indent-tabs-mode: nil
;; End:
