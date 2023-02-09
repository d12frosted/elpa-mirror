;;; echo-bar.el --- Turn the echo area into a custom status bar  -*- lexical-binding: t; -*-

;; Copyright (C) 2021-2022  Adam Tillou

;; Author: Adam Tillou <qaiviq@gmail.com>
;; Keywords: convenience, tools
;; Package-Version: 20230209.1350
;; Package-Commit: 03cae6d045636948d8b47979d85774e39556f9e1
;; Version: 1.0.0
;; Homepage: https://github.com/qaiviq/echo-bar.el

;; Note: This package will work without lexical binding, so there is no
;; Emacs 24 requirement.

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

;; This package will allow you to display a custom status at the end
;; of the echo area, like polybar but inside of Emacs.

;; To install, just run `M-x package-install RET echo-bar RET`.
;; To customize the text that gets displayed, set the variable
;; `echo-bar-function` to the name of your own custom function.
;; To turn the echo bar on or off, use `echo-bar-mode`.

;;; Code:

(require 'timer)
(require 'minibuffer)
(require 'overlay)
(require 'seq)

(defgroup echo-bar nil
  "Display text at the end of the echo area."
  :group 'applications)

(defcustom echo-bar-function #'echo-bar-default-function
  "Function that returns the text displayed in the echo bar."
  :group 'echo-bar
  :type 'function)

(defcustom echo-bar-format
  '(:eval (format-time-string "%b %d | %H:%M:%S"))
  "Format of the text displayed in the echo bar.

This format will only apply if `echo-bar-function' is set to
`echo-bar-default-function', otherwise, the output of
`echo-bar-function' will be used.

See `mode-line-format' for more info about the required format."
  :group 'echo-bar
  :type 'sexp)

(defcustom echo-bar-right-padding 2
  "Number of columns between the text and right margin."
  :group 'echo-bar
  :type 'number)

(defcustom echo-bar-minibuffer t
  "If non-nil, also display the echo bar when in the minibuffer."
  :group 'echo-bar
  :type 'boolean)

(defcustom echo-bar-update-interval 1
  "Interval in seconds between updating the echo bar contents.

If nil, don't update the echo bar automatically."
  :group 'echo-bar
  :type 'number)

(defvar echo-bar-timer nil
  "Timer used to update the echo bar.")

(defvar echo-bar-text nil
  "The text currently displayed in the echo bar.")

(defvar echo-bar-overlays nil
  "List of overlays displaying the echo bar contents.")

;;;###autoload
(define-minor-mode echo-bar-mode
  "Display text at the end of the echo area."
  :global t
  (if echo-bar-mode
      (echo-bar-enable)
    (echo-bar-disable)))

;;;###autoload
(defun echo-bar-enable ()
  "Turn on the echo bar."
  (interactive)
  ;; Disable any existing echo bar to remove conflicts
  (echo-bar-disable)

  ;; Create overlays in each echo area buffer. Use `get-buffer-create' to make
  ;; sure that the buffer is created even if no messages were outputted before
  (dolist (buf (mapcar #'get-buffer-create
                       '(" *Echo Area 0*" " *Echo Area 1*")))
    (with-current-buffer buf
      (remove-overlays (point-min) (point-max))
      (echo-bar--new-overlay)))

  ;; Start the timer to automatically update
  (when echo-bar-update-interval
    (run-with-timer 0 echo-bar-update-interval 'echo-bar-update))
  (echo-bar-update) ;; Update immediately

  ;; Add the setup function to the minibuffer hook
  (when echo-bar-minibuffer
    (add-hook 'minibuffer-setup-hook #'echo-bar--minibuffer-setup)))

;;;###autoload
(defun echo-bar-disable ()
  "Turn off the echo bar."
  (interactive)
  ;; Remove echo bar overlays
  (mapc 'delete-overlay echo-bar-overlays)
  (setq echo-bar-overlays nil)

  ;; Remove text from Minibuf-0
  (with-current-buffer (window-buffer
                        (minibuffer-window))
    (delete-region (point-min) (point-max)))

  ;; Cancel the update timer
  (cancel-function-timers #'echo-bar-update)

  ;; Remove the setup function from the minibuffer hook
  (remove-hook 'minibuffer-setup-hook #'echo-bar--minibuffer-setup))

;; TODO: Use function `string-pixel-width' after 29.1
(defun echo-bar--string-pixel-width (str)
  "Return the width of STR in pixels."

  ;; Make sure the temp buffer settings match the minibuffer settings
  (with-selected-window (minibuffer-window)
    (if (fboundp #'string-pixel-width)
        (string-pixel-width str)
      (require 'shr)
      (shr-string-pixel-width str))))

(defun echo-bar--str-len (str)
  "Calculate STR in pixel width."
  (let ((width (frame-char-width))
        (len (echo-bar--string-pixel-width str)))
    (+ (/ len width)
       (if (zerop (% len width)) 0 1))))  ; add one if exceeed

(defun echo-bar-set-text (text)
  "Set the text displayed by the echo bar to TEXT."
  (let* ((wid (+ (echo-bar--str-len text) echo-bar-right-padding))
         ;; Maximum length for the echo area message before wrap to next line
         (max-len (- (frame-width) wid 5))
         ;; Align the text to the correct width to make it right aligned
         (spc (propertize " " 'cursor 1 'display
                          `(space :align-to (- right-fringe ,wid)))))

    (setq echo-bar-text (concat spc text))

    ;; Add the correct text to each echo bar overlay
    (dolist (o echo-bar-overlays)
      (when (overlay-buffer o)

        (with-current-buffer (overlay-buffer o)
          ;; Wrap the text to the next line if the echo bar text is too long
          (if (> (mod (point-max) (frame-width)) max-len)
              (overlay-put o 'after-string (concat "\n" echo-bar-text))
            (overlay-put o 'after-string echo-bar-text)))))

    ;; Display the text in Minibuf-0, as overlays don't show up
    (with-current-buffer (window-buffer
                          (minibuffer-window))
      ;; Don't override existing text in minibuffer, such as ispell
      (when (get-text-property (point-min) 'echo-bar)
        (delete-region (point-min) (point-max)))
      (when (= (point-min) (point-max))
        (insert (propertize echo-bar-text 'echo-bar t))))))

(defun echo-bar--new-overlay (&optional remove-dead buffer)
  "Add new echo-bar overlay to BUFFER.
When REMOVE-DEAD is non-nil, also remove any dead overlays, i.e.,
those without a buffer from the beginning of the internal list of
overlays."
  (when remove-dead
    ;; Remove all dead overlays from the list
    (setq echo-bar-overlays
          (seq-filter 'overlay-buffer echo-bar-overlays)))

  (let ((new-overlay (make-overlay (point-max)
                                   (point-max) buffer t t)))
    (push new-overlay echo-bar-overlays)
    new-overlay))

(defun echo-bar--minibuffer-setup ()
  "Setup the echo bar in the minibuffer."
  (overlay-put (echo-bar--new-overlay t) 'priority 1)
  (echo-bar-update))

(defun echo-bar-update ()
  "Get new text to be displayed from `echo-bar-default-function`."
  (interactive)
  (when echo-bar-mode
    (echo-bar-set-text (funcall echo-bar-function))))

(defun echo-bar-default-function ()
  "The default function to use for the contents of the echo bar.
Returns the formatted text from `echo-bar-format'."
  (format-mode-line echo-bar-format))

(provide 'echo-bar)
;;; echo-bar.el ends here
