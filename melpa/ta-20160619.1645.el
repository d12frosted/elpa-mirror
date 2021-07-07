;;; ta.el --- A tool to deal with Chinese homophonic characters  -*- lexical-binding: t; -*-

;; Author: kuanyui <azazabc123@gmail.com>
;; Package-Requires: ((emacs "24.3") (cl-lib "0.5"))
;; Package-Version: 20160619.1645
;; Package-Commit: 668ad41e71f374f8c32c8d0532f3d8485b355d35
;; X-URL: http://github.com/kuanyui/ta.el
;; Version: 1.0
;; Keywords: tools

;; WTFPL 2.0
;; Ono Hiroko (kuanyui) (ɔ) Copyleft 2015
;;
;; This program is free software. It comes without any warranty, to
;; the extent permitted by applicable law. You can redistribute it
;; and/or modify it under the terms of the Do What The Fuck You Want
;; To Public License, Version 2, as published by Sam Hocevar. See
;; http://www.wtfpl.net/ for more details.

;;; Commentary:
;;
;; - M-x `ta-mode' to activate, then:
;;   + Use `M-p' and `M-n' to modify the homophonic characters.
;;   + Use `M-i' and `M-o' to jump between all possible candidate characters.
;;

;;; Code:

(require 'cl-lib)

(defvar-local ta-overlay nil)
(defvar-local ta-current-position nil)
(defvar-local ta-current-homophony-list nil)

(defvar ta-flattened-homophony-list nil)
(defvar ta--timer-object nil)

;; ======================================================
;; Settings
;; ======================================================

(defvar ta-homophony-list
  '(("他" "她" "它" "牠" "祂")
    ("你" "妳")
    ("的" "得")
    ("訂" "定")
    ("作" "做" "坐")
    ("在" "再")
    ("板" "版"))
  "The homophonic characters' list. Feel free to customized this
  if you need."  )

(defvar ta-max-search-range 300
  "Max search range for possible homophony.")


(defvar ta-delay 0.1
  "The number of seconds to wait.")

;; ======================================================
;; Homophony list function
;; ======================================================

(defun ta-reload-homophony-list ()
  "Update `ta-flattened-homophony-list',
which is a flatten list, like '(20182 22905 ...)"
  (interactive)
  (setq ta-flattened-homophony-list (mapcar (lambda (c) (string-to-char c))
                                            (apply #'append ta-homophony-list))))

(defun ta-get-homophony-list (char-str)
  "Get the homophony list of CHAR-STR"
  (car (cl-member char-str
                  ta-homophony-list
                  :test (lambda (char list) (member char list)))))

(defun ta-on-possible-candidate-character-p (position)
  (ta-get-homophony-list (char-to-string (char-after (point)))))

;; ======================================================
;; Face
;; ======================================================

(defface ta-highlight
  '((((class color) (background light))
     (:foreground "#ff8700"))
    (((class color) (background dark))
     (:foreground "#ffa722")))
  "Face for all candidates"
  :group 'ta-faces)

;; ======================================================
;; Minor-mode
;; ======================================================

(defun ta-post-command-hook ()
  (if (null ta-delay)
      (ta-find-previous-candidate)
    (when (null ta--timer-object)
      (setq ta--timer-object
            (run-with-idle-timer ta-delay nil
                                 (lambda ()
                                   (ta-auto-update-candidate)
                                   (setq ta--timer-object nil)))))))

(defun ta-pre-command-hook ()
  ;; (ta-delete-all-overlays)
  )

;;;###autoload
(define-minor-mode ta-mode
  "Deal with homophonic characters"
  :lighter " ta"
  :global nil
  :keymap (let ((map (make-sparse-keymap)))
            map)
  (if ta-mode
      (progn
        (ta-reload-homophony-list)
        (add-hook 'pre-command-hook 'ta-pre-command-hook nil t)
        (add-hook 'post-command-hook 'ta-post-command-hook nil t))
    (progn
      (ta-delete-all-overlays)
      (remove-hook 'pre-command-hook 'ta-pre-command-hook t)
      (remove-hook 'post-command-hook 'ta-post-command-hook t))))

;; ======================================================
;; Overlays
;; ======================================================

(defun ta-make-overlay (position face)
  "Allocate an overlay to highlight a possible candidate character."
  (let ((ol (make-overlay position (+ 1 position) nil t nil)))
    (overlay-put ol 'face face)
    (overlay-put ol 'ta-overlay t)))

(defun ta-delete-region-overlay (begin end)
  (remove-overlays begin end 'ta-overlay t))

(defun ta-delete-all-overlays ()
  (ta-delete-region-overlay (point-min) (point-max)))

(defun ta-overlay-p (obj)
  "Return true if o is an overlay used by flyspell."
  (and (overlayp obj) (overlay-get obj 'ta-overlay)))

;; ======================================================
;; Main
;; ======================================================

(defun ta-replace-char (position character)
  "Replace the char in position, then add face."
  (delete-region position (+ position 1))
  (save-excursion
    (goto-char position)
    (insert character))
  (ta-make-overlay position 'ta-highlight))

(defun ta-auto-update-candidate ()
  "Update `ta-current-position' and `ta-current-homophony-list' within
 `ta-max-search-range' steps.
Used in idle timer."
  (interactive)
  (save-excursion
    (cl-do ((i ta-max-search-range (1- i)))
        (
         ;;End Test
         (or (= i 0)
             (= (point) (point-min))
             (memq (char-after (point)) ta-flattened-homophony-list))
         ;; Final Result (Run after end test passed)
         (progn
           (ta-delete-all-overlays)
           (when (memq (char-after (point)) ta-flattened-homophony-list)
             (ta-make-overlay (point) 'ta-highlight)
             (setq ta-current-position (point)
                   ta-current-homophony-list (ta-get-homophony-list
                                              (char-to-string
                                               (char-after ta-current-position))))
             (point))))
      ;; Main
      (left-char))))

(defun ta-find-previous-candidate (&optional reverse)
  "Update `ta-current-position' and `ta-current-homophony-list',
 without any range limit. When REVERSE is non-nil,
find nextcandidate. Should be called interactively, not by idle timer."
  (interactive)
  (save-excursion
    (cl-do ((i 0 (1+ i)))
        (
         ;;End Test
         (or (and reverse (= (point) (point-max)))
             (= (point) (point-min))
             (memq (char-after (point)) ta-flattened-homophony-list))
         ;; Final Result (Run after end test passed)
         (if (memq (char-after (point)) ta-flattened-homophony-list) ;If found candidate
             (progn
               (ta-delete-all-overlays)
               (ta-make-overlay (point) 'ta-highlight)
               (setq ta-current-position (point)
                     ta-current-homophony-list (ta-get-homophony-list
                                                (char-to-string
                                                 (char-after ta-current-position))))
               (point))
           (message (if reverse "The last candidate" "The first candidate"))))
      ;; Main
      (if reverse (right-char) (left-char)))))

(defun ta--get-next-elem (elem list)
  (let ((l (member elem list)))
    (if (null (cdr l))
        (car list)
      (cadr l))))

(defun ta-next-homophony (&optional reverse)
  (interactive)
  (ta-find-previous-candidate)
  (let ((dont-move (if (or (eobp)
                           (and (eq (1- (point)) ta-current-position)
                                (not (ta-on-possible-candidate-character-p (point)))))
                       t nil
                       )))

    (if (memq (char-after ta-current-position) ta-flattened-homophony-list)
        (if (and
             (number-or-marker-p ta-current-position)
             (<= (1+ ta-current-position) (point-max)))
            (let ((current-character (char-to-string (char-after ta-current-position))))
              (ta-replace-char
               ta-current-position
               (ta--get-next-elem current-character
                                  (if reverse
                                      (reverse ta-current-homophony-list)
                                    ta-current-homophony-list)))
              (if dont-move (right-char))))
      (message "No candidate found."))))

(defun ta-previous-homophony ()
  (interactive)
  (ta-next-homophony 'reverse))

(defun ta-left ()
  (interactive)
  (if (number-or-marker-p ta-current-position)
      (progn
        (left-char)
        (ta-find-previous-candidate)
        (goto-char ta-current-position))
    (message "Cannot find any candidate")))

(defun ta-right ()
  (interactive)
  (if (number-or-marker-p ta-current-position)
      (progn
        (right-char)
        (ta-find-previous-candidate 'reverse)
        (goto-char ta-current-position))
    (message "Cannot find any candidate")))

(provide 'ta)
;;; ta.el ends here
