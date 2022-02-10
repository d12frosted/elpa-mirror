;;; amread-mode.el --- A minor mode helper user speed-reading -*- lexical-binding: t; -*-

;;; Time-stamp: <2020-06-23 23:44:49 stardiviner>

;; Authors: stardiviner <numbchild@gmail.com>
;; Package-Requires: ((emacs "24.3") (cl-lib "0.6.1"))
;; Package-Commit: a3358645582148e81bff54e18877451b747173bb
;; Package-Version: 20220210.1354
;; Package-X-Original-Version: 0.1
;; Keywords: wp
;; homepage: https://repo.or.cz/amread-mode.git

;; amread-mode is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; amread-mode is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;; 
;;; Usage
;;;
;;; 1. Launch amread-mode with command `amread-mode'.
;;; 2. Stop amread-mode by pressing [q].

;;; Code:
(require 'cl-lib)


(defcustom amread-speed 3.0
  "Read words per second."
  :type 'float
  :safe #'floatp
  :group 'amread-mode)

(defcustom amread-scroll-style nil
  "Set amread auto scroll style by word or line."
  :type '(choice (const :tag "scroll by word" word)
                 (const :tag "scroll by line" line))
  :safe #'symbolp
  :group 'amread-mode)

(defface amread-highlight-face
  '((t :foreground "black" :background "orange"))
  "Face for amread-mode highlight."
  :group 'amread-mode)

(defvar amread--timer nil)
(defvar amread--current-position nil)
(defvar amread--overlay nil)

(defun amread--word-update ()
  "Scroll forward by word as step."
  (let* ((begin (point))
         ;; move point forward. NOTE This forwarding must be here before moving overlay forward.
         (_length (+ (skip-chars-forward "^\s\t\n—") (skip-chars-forward "—")))
         (end (point)))
    (if (eobp)
        (progn
          (amread-mode -1)
          (setq amread--current-position nil))
      ;; create the overlay if does not exist
      (unless amread--overlay
        (setq amread--overlay (make-overlay begin end)))
      ;; move overlay forward
      (when amread--overlay
        (move-overlay amread--overlay begin end))
      (setq amread--current-position (point))
      (overlay-put amread--overlay 'face 'amread-highlight-face)
      (skip-chars-forward "\s\t\n—"))))

(defun amread--line-update ()
  "Scroll forward by line as step."
  (let* ((line-begin (line-beginning-position))
         (line-end (line-end-position)))
    (if (eobp) ; reached end of buffer.
        (progn
          (amread-mode -1)
          (setq amread--current-position nil))
      ;; create line overlay to highlight current reading line.
      (unless amread--overlay
        (setq amread--overlay (make-overlay line-begin line-end)))
      ;; scroll down line
      (when amread--overlay
        (move-overlay amread--overlay line-begin line-end))
      (overlay-put amread--overlay 'face 'amread-highlight-face)
      (forward-line 1))))

(defun amread--update ()
  "Update and scroll forward under Emacs timer."
  (if (eq amread-scroll-style 'word)
      (amread--word-update)
    (amread--line-update)))

(defun amread--scroll-style-ask ()
  "Ask which scroll style to use."
  (let ((style (intern (completing-read "amread-mode scroll style: " '("word" "line")))))
    (setq amread-scroll-style style)))

(defun amread--get-line-words (&optional pos)
  "Get the line words of position."
  (save-excursion
    (and pos (goto-char pos))
    (count-words (line-end-position) (line-beginning-position))))

(defun amread--get-next-line-words ()
  "Get the next line words."
  (amread--get-line-words (save-excursion (forward-line) (point))))

(defun amread--get-line-length (&optional pos)
  "Get the line length of position."
  (save-excursion
    (and pos (goto-char pos))
    (- (line-end-position) (line-beginning-position))))

(defun amread--get-next-line-length ()
  "Get the next line length."
  (amread--get-line-words (save-excursion (forward-line) (point))))

;;;###autoload
(defun amread-start ()
  "Start / resume amread."
  (interactive)
  (read-only-mode 1)
  (or amread-scroll-style (amread--scroll-style-ask))
  ;; resume from paused position
  (cl-case amread-scroll-style
    (word
     (when amread--current-position
       (goto-char amread--current-position))
     (setq amread--timer
           (run-with-timer 0 (/ 1.0 amread-speed) #'amread--update)))
    (line
     (when amread--current-position
       (goto-char (point-min))
       (forward-line amread--current-position))
     (let* ((next-line-words (amread--get-next-line-words)) ; for English
            (amread--stick-secs (/ next-line-words amread-speed)))
       (setq amread--timer
             (run-with-timer amread--stick-secs nil #'amread--update)))))
  (message "I start reading..."))

;;;###autoload
(defun amread-stop ()
  "Stop amread."
  (interactive)
  (when amread--timer
    (cancel-timer amread--timer)
    (setq amread--timer nil)
    (when amread--overlay
      (delete-overlay amread--overlay)))
  (setq amread-scroll-style nil)
  (read-only-mode -1)
  (message "I stopped reading."))

(defun amread-pause-or-resume ()
  "Pause or resume amread."
  (interactive)
  (if amread--timer
      (amread-stop)
    (amread-start)))

(defun amread-mode-quit ()
  "Disable `amread-mode'."
  (interactive)
  (amread-mode -1))

(defun amread-speed-up ()
  "Speed up `amread-mode'."
  (interactive)
  (setq amread-speed (cl-incf amread-speed 0.2)))

(defun amread-speed-down ()
  "Speed down `amread-mode'."
  (interactive)
  (setq amread-speed (cl-decf amread-speed 0.2)))

(defvar amread-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "q") #'amread-mode-quit)
    (define-key map (kbd "SPC") #'amread-pause-or-resume)
    (define-key map [remap keyboard-quit] #'amread-mode-quit)
    (define-key map (kbd "+") #'amread-speed-up)
    (define-key map (kbd "-") #'amread-speed-down)
    map)
  "Keymap for `amread-mode' buffers.")

;;;###autoload
(define-minor-mode amread-mode
  "I'm reading mode."
  :init nil
  :lighter " amreading"
  :keymap amread-mode-map
  (if amread-mode
      (amread-start)
    (amread-stop)))



(provide 'amread-mode)

;;; amread-mode.el ends here
