;;; completions-frame.el --- Show completions in child frame -*- lexical-binding: t -*-

;; Copyright (C) 2020 Andrii Kolomoiets

;; Author: Andrii Kolomoiets <andreyk.mad@gmail.com>
;; Keywords: frames
;; Package-Commit: 860e5b97730df7ef5c34584ad164bc69c561db84
;; URL: https://github.com/muffinmad/emacs-completions-frame
;; Package-Version: 20210430.640
;; Package-X-Original-Version: 1.3.2
;; Package-Requires: ((emacs "26.1"))

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Show *Completions* buffer in child frame.
;;
;; Basically it's the function for `display-buffer-alist` with some child
;; frame's position and size manipulation:
;; - Completions frame placed near the point;
;; - It is placed above or below point depending on completions frame height
;;   and available space around the point;
;; - Initial frame width is set to 1 so completion list is arranged in single
;;   column.  This behavior can be configured via `completions-frame-width`
;;   variable.

;;; Code:

(defgroup completions-frame nil
  "Show completions in child frame."
  :group 'completion)

(defcustom completions-frame-color-shift-step 27
  "Shift each of RGB channels of background color by this value.
Background color is \"moved\" towards foreground color of selected frame
to determine background color of completions frame."
  :type 'integer)

(defcustom completions-frame-focus 'original
  "Which frame should take focus once completions frame is shown."
  :type '(choice (const :tag "Do nothing" nil)
                 (const :tag "Select completions frame" completions)
                 (const :tag "Select original frame" original)))

(defcustom completions-frame-condition "\\(\\*\\(Ido \\)?Completions\\)\\|\\(\\*Isearch completions\\)\\*"
  "Regexp matching buffer names.
Used as condition for `display-buffer-alist' entry which see."
  :type 'regexp)

(defcustom completions-frame-width 1
  "Completions frame initial width.
The lesser value the fewer columns will completions occupy.
See `completion--insert-strings'.

Floating-point value can specify width ratio.
See frame size parameters manual."
  :type 'number)

(defcustom completions-frame-border-width 3
  "Completions frame internal border width."
  :type 'number)

(defcustom completions-frame-max-height nil
  "Completions frame maximum height."
  :type '(choice (const :tag "As much as possible" nil)
                 (integer)))

(defvar completions-frame-frame nil)

(defun completions-frame-condition-func (buffer-name _action)
  "Check if `completions-frame-condition' match BUFFER-NAME.
Also checks for `display-graphic-p'.
Used as condition for `display-buffer-alist' entry which see."
  (and (display-graphic-p)
       (string-match-p completions-frame-condition buffer-name)))

(defun completions-frame--shift-color (from to &optional by)
  "Move color FROM towards TO by BY.  If BY is omitted, `mini-frame-color-shift-step' is used."
  (let ((f (ash from -8))
        (by (or by completions-frame-color-shift-step)))
    (cond
     ((> from to) (- f by))
     ((< from to) (+ f by))
     (t f))))

(defun completions-frame-get-background-color (&optional frame)
  "Calculate background color for minibuffer frame from FRAME."
  (let* ((params (frame-parameters frame))
         (bg (color-values (alist-get 'background-color params)))
         (fg (color-values (alist-get 'foreground-color params))))
    (format "#%02x%02x%02x"
            (completions-frame--shift-color (car bg) (car fg))
            (completions-frame--shift-color (cadr bg) (cadr fg))
            (completions-frame--shift-color (caddr bg) (caddr fg)))))

(defun completions-frame-hide (&optional frame force)
  "Call `make-frame-invisible' with FRAME and FORCE and FRAME's parent frame."
  (make-frame-invisible frame force)
  (select-frame-set-input-focus (frame-parameter frame 'parent-frame)))

(defun completions-frame--minibuffer-exit ()
  "Function to run on minibuffer exit.
Hide completion frame if there are visible one."
  (when (and (frame-live-p completions-frame-frame)
             (frame-visible-p completions-frame-frame))
    (completions-frame-hide completions-frame-frame)))

(defun completions-frame-setup ()
  "Completion setup hook.  Set completions frame size and position."
  (when (and (frame-live-p completions-frame-frame)
             (frame-visible-p completions-frame-frame))
    (make-frame-invisible completions-frame-frame)
    (let* ((comp-window (frame-selected-window completions-frame-frame))
           (host-frame (frame-parameter completions-frame-frame 'parent-frame))
           (host-window (frame-selected-window host-frame))
           (point-pos (pos-visible-in-window-p (window-point host-window) host-window t))
           (host-edges (window-edges host-window nil nil t))
           (host-frame-w (frame-inner-width host-frame))
           (host-frame-h (frame-inner-height host-frame))
           (comp-edges (window-edges comp-window t nil t))
           (comp-border (frame-internal-border-width completions-frame-frame))
           (comp-left (frame-parameter completions-frame-frame 'left))
           (comp-size (window-text-pixel-size comp-window t t host-frame-w nil t))
           (comp-w (car comp-size))
           (comp-h (+ comp-border
                      (cdr comp-size)))
           (point-y (+ (cadr point-pos)
                       (cadr host-edges)))
           (point-yb (+ point-y (frame-char-height)))
           (avail-top point-y)
           (avail-bot (- host-frame-h point-yb))
           (ch (min (if completions-frame-max-height
                        (min comp-h (* completions-frame-max-height
                                       (frame-char-height completions-frame-frame)))
                      comp-h
                      (max avail-top avail-bot))))
           (cw (min comp-w host-frame-w))
           (place-bottom (<= ch avail-bot))
           (ct (max 0
                    (if place-bottom
                        point-yb
                      (- point-y ch))))
           (ch (- ch (* (if place-bottom 1 2) comp-border)))
           (left (cond
                  ((> (+ cw (- (caddr comp-edges) (car comp-edges))) host-frame-w) 0)
                  ((> (+ comp-left (+ cw (- (cadr comp-edges) (car comp-edges)))) host-frame-w) -1)
                  (t comp-left))))
      (modify-frame-parameters
       completions-frame-frame
       `((top . ,ct)
         (left . ,left)
         (width . ,(if (> (+ cw (- (caddr comp-edges) (car comp-edges)))
                          host-frame-w)
                       1.0
                     `(text-pixels . ,cw)))
         (height . (text-pixels . ,ch))))
      (make-frame-visible completions-frame-frame)
      (completions-frame-focus-setup))))

(defun completions-frame-focus-setup ()
  "Select frame according to `completions-frame-focus'."
  (when (and completions-frame-focus
             (frame-live-p completions-frame-frame)
             (frame-visible-p completions-frame-frame))
    (select-frame-set-input-focus
     (if (eq completions-frame-focus 'completions)
         completions-frame-frame
       (frame-parameter completions-frame-frame 'parent-frame)))))

(defun completions-frame-display (buffer alist)
  "Display completions BUFFER in child frame.
Create frame if needed and set initial frame parameters.
ALIST is passed to `window--display-buffer'"
  (let* ((frame (selected-frame))
         (parent-frame-parameters `((parent-frame . ,frame)))
         (show-parameters `((height . 1)
                            (width . ,(min completions-frame-width (frame-width frame)))
                            (background-color . ,(completions-frame-get-background-color)))))
    (if (frame-live-p completions-frame-frame)
        (modify-frame-parameters completions-frame-frame parent-frame-parameters)
      (setq completions-frame-frame
            (let ((after-make-frame-functions nil))
              (make-frame (append `((tool-bar-lines . 0)
                                    (visibility . nil)
                                    (auto-hide-function . completions-frame-hide)
                                    (user-position . t)
                                    (user-size . t)
                                    (keep-ratio . t)
                                    (minibuffer . nil)
                                    (undecorated . t)
                                    (internal-border-width . ,completions-frame-border-width)
                                    (drag-internal-border . t)
                                    (drag-with-mode-line . t)
                                    (drag-with-header-line . t)
                                    (top-visible . 1)
                                    (bottom-visible . 1))
                                  parent-frame-parameters
                                  show-parameters))))
      (set-face-background 'fringe nil completions-frame-frame))
    (let ((completion-window (frame-selected-window completions-frame-frame)))
      (modify-frame-parameters
       completions-frame-frame
       ;; set `left' earlier to minimize frame repositioning
       (append `((left . ,(max (car (window-edges nil nil nil t))
                               (+ (car (pos-visible-in-window-p (window-point) nil t))
                                  (car (window-edges nil t nil t))
                                  (- (car (window-edges completion-window t nil t)))))))
               show-parameters))
      (make-frame-visible completions-frame-frame)
      (prog1 (window--display-buffer buffer completion-window 'frame alist)
        (set-window-dedicated-p completion-window 'soft)))))

(defmacro completions-frame--with-frame (name if-not-comp &rest if-comp)
  "Declare NAME to execute IF-COMP or IF-NOT-COMP.
Execute IF-COMP if `completions-frame-frame' is visible.
Execute IF-NOT-COMP otherwise."
  `(defun ,name ()
     (interactive)
     (if (and (frame-live-p completions-frame-frame)
              (frame-visible-p completions-frame-frame))
         (with-selected-frame completions-frame-frame
           ,@if-comp)
       (completion-in-region-mode -1)
       (call-interactively ,if-not-comp))))

(completions-frame--with-frame
 completions-frame-next #'next-line (next-completion 1))
(completions-frame--with-frame
 completions-frame-previous #'previous-line (next-completion -1))
(completions-frame--with-frame
 completions-frame-accept (or (local-key-binding (kbd "RET"))
                              (global-key-binding (kbd "RET")))
 (choose-completion))

(defvar completions-frame-map
  (let ((map (make-sparse-keymap)))
    (define-key map [remap next-line] #'completions-frame-next)
    (define-key map [remap previous-line] #'completions-frame-previous)
    (define-key map (kbd "RET") #'completions-frame-accept)
    map))

(defun completions-frame--cir-mode-hook ()
  "Completion in region mode hook."
  (when completion-in-region-mode
    (setcdr (assq #'completion-in-region-mode
                  minor-mode-overriding-map-alist)
            completions-frame-map)))

;;;###autoload
(define-minor-mode completions-frame-mode
  "Show completions in child frame."
  :global t
  (cond
   (completions-frame-mode
    (add-to-list 'display-buffer-alist '(completions-frame-condition-func completions-frame-display))
    (add-hook 'temp-buffer-window-show-hook #'completions-frame-focus-setup)
    (add-hook 'completion-setup-hook #'completions-frame-setup)
    (add-hook 'minibuffer-exit-hook #'completions-frame--minibuffer-exit)
    (add-hook 'completion-in-region-mode-hook #'completions-frame--cir-mode-hook))
   (t
    (setq display-buffer-alist (delete '(completions-frame-condition-func completions-frame-display) display-buffer-alist))
    (remove-hook 'temp-buffer-window-show-hook #'completions-frame-focus-setup)
    (remove-hook 'completion-setup-hook #'completions-frame-setup)
    (remove-hook 'minibuffer-exit-hook #'completions-frame--minibuffer-exit)
    (remove-hook 'completion-in-region-mode-hook #'completions-frame--cir-mode-hook)
    (when (frame-live-p completions-frame-frame)
      (delete-frame completions-frame-frame)))))

(provide 'completions-frame)

;;; completions-frame.el ends here
