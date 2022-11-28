;;; corfu-doc.el --- Documentation popup for Corfu -*- lexical-binding: t -*-

;; Copyright (C) 2021-2022 Yuwei Tian

;; Author: Yuwei Tian <ibluefocus@NOSPAM.gmail.com>
;; URL: https://github.com/galeo/corfu-doc
;; Package-Version: 20221128.1533
;; Package-Commit: 0e6125cd042506a048feb7b6446a5653eccfcff5
;; Version: 0.7
;; Keywords: corfu popup documentation convenience
;; Package-Requires: ((emacs "27.1")(corfu "0.25"))

;; This file is not part of GNU Emacs.

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file LICENSE. If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; Display a documentation popup for completion candidate when using Corfu.

;;; Code:

(eval-when-compile
  (require 'cl-lib)
  (require 'subr-x))
(require 'corfu)

(defgroup corfu-doc nil
  "Display documentation popup alongside corfu."
  :group 'corfu
  :prefix "corfu-doc-")

(defcustom corfu-doc-auto t
  "Display documentation popup automatically."
  :type 'boolean)

(defcustom corfu-doc-delay 0.1
  "The number of seconds to wait before displaying the documentation popup.

The value of nil means no delay."
  :type '(choice (const :tag "never (nil)" nil)
                 (const :tag "immediate (0)" 0)
                 (number :tag "seconds")))

(defcustom corfu-doc-transition nil
  "The method to transition the documentaion popup when browsing candidates.

The documentaion popup transition only works when `corfu-auto-delay'
is non-nil and its value is greater than 0.

If this is nil, there is no transition (do nothing), the doc popup
preserves the content of the last candidate.

If the value is 'clear, the documentation content of the last candidate
will be cleared on documentation popup transition.

If the value is 'hide, the documentation popup will be hidden
when brwosing candidates.

It is recommended to select the corresponding transition method
according to the value of `corfu-doc-delay' to reduce flicker or
documentation update delay."
  :type '(choice (const :tag "no transition (nil)" nil)
          (const :tag "clear content" clear)
          (const :tag "hide popup" hide)))

(defcustom corfu-doc-max-width 80
  "The max width of the corfu doc frame in characters."
  :type 'integer)

(defcustom corfu-doc-max-height 10
  "The max height of the corfu doc frame in characters."
  :type 'integer)

(defcustom corfu-doc-resize-frame t
  "Non-nil means resize the corfu doc frame automatically.

If this is nil, do not resize corfu doc frame automatically."
  :type 'boolean)

(defcustom corfu-doc-display-within-parent-frame t
  "Display the doc popup within the parent frame.

If this is nil, it means that the parent frame do not clip child
frames at the parent frame’s edges. The position of the doc popup is
calculated based on the size of the display monitor.

Most window-systems clip a child frame at the native edges
of its parent frame—everything outside these edges
is usually invisible...

NS builds do not clip child frames at the parent frame’s edges,
allowing them to be positioned so they do not obscure the parent frame while
still being visible themselves.

Please see \"(elisp) Child Frames\" in Emacs manual for details."
  :type 'boolean)

(defvar corfu-doc--frame nil
  "Doc frame.")

(defvar corfu-doc--frame-parameters
  (let* ((cw (default-font-width))
         (lmw (* cw corfu-left-margin-width))
         (rmw (* cw corfu-right-margin-width))
         (fp (copy-alist corfu--frame-parameters)))
    (setf (alist-get 'left-fringe fp) (ceiling lmw)
          (alist-get 'right-fringe fp) (ceiling rmw))
    fp)
  "Default doc child frame parameters.")

(defvar-local corfu-doc--auto-timer nil
  "Corfu doc auto idle timer.")

(defvar corfu-doc--cf-window nil
  "Window where the corfu popup is located.")

(defvar-local corfu-doc--candidate nil
  "Completion candidate for the doc popup.")

(defvar-local corfu-doc--cf-popup-edges nil
  "Coordinates of the corfu popup's edges.

The coordinates list has the form (LEFT TOP RIGHT BOTTOM) where all
values are in pixels relative to the origin - the position (0, 0)
- of FRAME's display.  For terminal frames all values are
relative to LEFT and TOP which are both zero.

See `frame-edges' for details.")

(defun corfu-doc--set-vars (candidate cf-popup-edges window)
  "Record the values of local variables required by the doc popup.

CANDIDATE is the current completion candidate the doc is for.

CF-POPUP-EDGES is the coordinates of the current corfu popup's edges.
See `corfu-doc--cf-popup-edges' for details.

WINDOW is the current window where the corfu popup is located."
  (setq corfu-doc--candidate candidate)
  (setq corfu-doc--cf-popup-edges cf-popup-edges)
  (setq corfu-doc--cf-window window))

;; Function adapted from corfu.el by Daniel Mendler
(defun corfu-doc--redirect-focus ()
  "Redirect focus from doc."
  (redirect-frame-focus corfu-doc--frame (frame-parent corfu-doc--frame)))

;; Function adapted from corfu.el by Daniel Mendler
(defun corfu-doc--make-buffer (content)
  "Create corfu doc buffer with CONTENT."
  (let ((fr face-remapping-alist)
        (buffer (get-buffer-create " *corfu-doc*")))
    (with-current-buffer buffer
      ;;; XXX HACK install redirect focus hook
      (add-hook 'pre-command-hook #'corfu-doc--redirect-focus nil 'local)
      ;;; XXX HACK install mouse ignore map
      (use-local-map corfu--mouse-ignore-map)
      (dolist (var corfu--buffer-parameters)
        (set (make-local-variable (car var)) (cdr var)))
      (setq-local indicate-empty-lines nil)
      (setq-local face-remapping-alist (copy-tree fr))
      (cl-pushnew 'corfu-default (alist-get 'default face-remapping-alist))
      (let ((inhibit-modification-hooks t)
            (inhibit-read-only t))
        (erase-buffer)
        (insert content)
        (visual-line-mode 1)  ;; turn on word wrap
        (goto-char (point-min))))
    buffer))

;; Function adapted from corfu.el by Daniel Mendler
(defvar x-gtk-resize-child-frames) ;; Not present on non-gtk builds
(defun corfu-doc--make-frame (content)
  "Make child frame with CONTENT."
  (let* ((window-min-height 1)
         (window-min-width 1)
         (x-gtk-resize-child-frames
          (let ((case-fold-search t))
            (and
             ;; XXX HACK to fix resizing on gtk3/gnome taken from posframe.el
             ;; More information:
             ;; * https://github.com/minad/corfu/issues/17
             ;; * https://gitlab.gnome.org/GNOME/mutter/-/issues/840
             ;; * https://lists.gnu.org/archive/html/emacs-devel/2020-02/msg00001.html
             (string-match-p "gtk3" system-configuration-features)
             (string-match-p "gnome\\|cinnamon" (or (getenv "XDG_CURRENT_DESKTOP")
                                                    (getenv "DESKTOP_SESSION") ""))
             'resize-mode)))
         (after-make-frame-functions)
         (border (alist-get 'child-frame-border-width corfu-doc--frame-parameters))
         (buffer (corfu-doc--make-buffer content)))
    (unless (and (frame-live-p corfu-doc--frame)
                 (eq (frame-parent corfu-doc--frame) (window-frame)))
      (when corfu-doc--frame (delete-frame corfu-doc--frame))
      (setq corfu-doc--frame (make-frame
                              `((parent-frame . ,(window-frame))
                                (minibuffer . ,(minibuffer-window (window-frame)))
                                (line-spacing . ,line-spacing)
                                ;; Set `internal-border-width' for Emacs 27
                                (internal-border-width . ,border)
                                ,@corfu-doc--frame-parameters))))
    ;; XXX HACK Setting the same frame-parameter/face-background is not a nop (BUG!).
    ;; Check explicitly before applying the setting.
    ;; Without the check, the frame flickers on Mac.
    (let* ((face (if (facep 'child-frame-border) 'child-frame-border 'internal-border))
	       (internal-border-color (face-attribute 'corfu-border :background nil 'default))
           (bg-color (face-attribute 'corfu-default :background nil 'default)))
      (unless (and (equal (face-attribute face :background corfu-doc--frame 'default)
                          internal-border-color)
                   (equal (frame-parameter corfu--frame 'background-color) bg-color))
	    (set-face-background face internal-border-color corfu-doc--frame)
        ;; XXX HACK We have to apply the face background before adjusting the frame parameter,
        ;; otherwise the border is not updated (BUG!).
        (set-frame-parameter corfu-doc--frame 'background-color bg-color))
      ;; set fringe color
      (unless (equal (face-attribute 'fringe :background corfu-doc--frame 'default)
                     bg-color)
        (set-face-background 'fringe bg-color corfu-doc--frame)))
    (let ((win (frame-root-window corfu-doc--frame)))
      (set-window-buffer win buffer)
      ;; Mark window as dedicated to prevent frame reuse (#60)
      (set-window-dedicated-p win t))))

(defun corfu-doc--set-frame-position (frame x y width height)
  "Show FRAME at X/Y with WIDTH/HEIGHT."
  (set-frame-position frame x y)
  (set-frame-size frame width height t)
  (make-frame-visible frame))

(defun corfu-doc--get-doc ()
  "Get the documentation for the current completion candidate.

The documentation is trimmed.
Returns nil if an error occurs or the documentation content is empty."
  (when-let
      ((doc
        (ignore-errors
          (cond
            ((= corfu--total 0) nil)  ;; No candidates
            ((< corfu--index 0) nil)  ;; No candidate selected
            (t
             (if-let*
                 ((fun (plist-get corfu--extra :company-doc-buffer))
                  (res
                   ;; fix showing candidate location
                   ;; when fetch helpful documentation
                   (save-excursion
                     (let ((inhibit-message t)
                           (message-log-max nil))
                       (funcall fun (nth corfu--index corfu--candidates))))))
                 (let ((buf (or (car-safe res) res)))
                   (with-current-buffer buf
                     (buffer-string)))
               nil))))))  ;; No documentation available
    (unless (string-empty-p (string-trim doc))
      doc)))

(defun corfu-doc--calc-popup-position (&optional fwidth fheight)
  "Calculate doc popup position (x, y), pixel width and height.

The pixel width and height of the doc popup are calculated by the
documentation content, they can also be specified by optional parameters
FWIDTH and FHEIGHT."
  (let* (x y
         ;; space between corfu popup and corfu doc popup
         ;; set -1 to share the border
         (space -1)
         (cf-parent-frame (frame-parent corfu--frame))
         (cf-frame--pos (frame-position corfu--frame))
         (cf-frame-x (car cf-frame--pos))  ;; corfu--frame x pos
         (cf-frame-y (cdr cf-frame--pos))
         (cf-frame-width (frame-pixel-width corfu--frame))
         (cf-frame-height (frame-pixel-height corfu--frame))
         (cf-parent-frame-pos
           ;; Get inner frame left top edge for corfu frame's parent frame
           ;; See "(elisp) Frame Layout" in Emacs manual
           (cl-subseq (frame-edges cf-parent-frame 'inner) 0 2))
         (cf-parent-frame-x (car cf-parent-frame-pos))
         (cf-parent-frame-y (cadr cf-parent-frame-pos))
         (cf-parent-frame-width (frame-pixel-width cf-parent-frame))
         (cf-parent-frame-height (frame-pixel-height cf-parent-frame))
         (lfw (alist-get 'left-fringe corfu-doc--frame-parameters 0))
         (rfw (alist-get 'right-fringe corfu-doc--frame-parameters 0))
         (cf-doc-frame-width
           (or fwidth
               (if (not corfu-doc-resize-frame)
                   ;; left border + left margin + inner width + right margin + right border
                   (+ 1 lfw (* (frame-char-width) corfu-doc-max-width) rfw 1)
                 (fit-frame-to-buffer corfu-doc--frame
                                      corfu-doc-max-height nil
                                      corfu-doc-max-width nil)
                 ;; outer width - left border - left margin - right margin - right border
                 (- (frame-pixel-width corfu-doc--frame) 1 lfw rfw 1))))
         (cf-doc-frame-height
           (or fheight
               (if (not corfu-doc-resize-frame)
                   (* (frame-char-height) corfu-doc-max-height)
                 ;; outer height - top border - bottom border
                 (- (frame-pixel-height corfu-doc--frame) 1 1))))
         (display-geometry (assq 'geometry (frame-monitor-attributes corfu--frame)))
         (display-width (nth 3 display-geometry))
         (display-height (nth 4 display-geometry))
         (display-x (nth 1 display-geometry))
         (cf-parent-frame-rel-x (- cf-parent-frame-x display-x))
         (display-space-right
           (- display-width
              (+ (+ cf-frame-x cf-frame-width space) cf-parent-frame-rel-x)))
         (display-space-left (- (+ cf-frame-x cf-parent-frame-rel-x) space))
         (cf-parent-frame-space-right
           (- cf-parent-frame-width (+ cf-frame-x cf-frame-width space)))
         (cf-parent-frame-space-left (- cf-frame-x space)))
    (pcase-let ((`(,space-right ,space-left)
                  (if corfu-doc-display-within-parent-frame
                      (list cf-parent-frame-space-right
                            cf-parent-frame-space-left)
                    (list display-space-right
                          display-space-left)))
                (_x-on-left-side-of-cf-frame
                 (- cf-frame-x space cf-doc-frame-width))
                (x-on-right-side-of-cf-frame
                 (+ cf-frame-x cf-frame-width space)))
      (cond
        ((> space-right cf-doc-frame-width)
         (setq x x-on-right-side-of-cf-frame
               y cf-frame-y))
        ((and (< space-right cf-doc-frame-width)
              (> space-left cf-doc-frame-width))
         (setq x
               ;; space that right edge of the DOC-FRAME
               ;; to the right edge of the parent frame
               ;;   calculation:
               ;; (- (+ cf-frame-x cf-parent-frame-x)
               ;;    space
               ;;    (+ cf-parent-frame-x cf-parent-frame-width))
               (- cf-frame-x space cf-parent-frame-width)
               y cf-frame-y))
        (t
         (setq x cf-frame-x)
         (let* ((cf-frame-y-b
                  (+ (cadr (window-inside-pixel-edges))
                     (window-tab-line-height)
                     (or (cdr (posn-x-y (posn-at-point (point)))) 0)
                     (default-line-height)))
                (y-on-top-side-of-cf-frame
                  (- cf-frame-y space 1 cf-doc-frame-height 1))
                (y-on-bottom-side-of-cf-frame
                  (+ cf-frame-y cf-frame-height space)))
           (cond
             ((> cf-frame-y-b cf-frame-y)
              (setq y (max 1 y-on-top-side-of-cf-frame))
              (if (< y-on-top-side-of-cf-frame 0)
                  (setq cf-doc-frame-height
                        (- cf-frame-y y 1 1 space))))
             (t (setq y y-on-bottom-side-of-cf-frame))))))
      ;; reduce the popup width and height to avoid exceeding the frame or display
      (when (= x cf-frame-x)
        (pcase-let ((cw (frame-char-width))
                    (lh (default-line-height))
                    (`(,width-remaining ,height-remaining)
                      (if corfu-doc-display-within-parent-frame
                          (list (- cf-parent-frame-width 1 lfw rfw 1 x)
                                (- cf-parent-frame-height 1 1 y))
                        (list (- display-width 1 lfw rfw 1 x cf-parent-frame-x)
                              (- display-height 1 1 y cf-parent-frame-y)))))
          (when (< width-remaining cf-doc-frame-width)
            (setq cf-doc-frame-width
                  (* (floor (/ width-remaining cw)) cw)))
          (when (< height-remaining cf-doc-frame-height)
            (setq cf-doc-frame-height
                  (* (floor (/ height-remaining lh)) lh))))))
    (list x y cf-doc-frame-width cf-doc-frame-height)))

(defun corfu-doc--get-candidate ()
  "Get the current completion candidate."
  (and (> corfu--total 0)
       (nth corfu--index corfu--candidates)))

(defun corfu-doc--get-cf-popup-edges ()
  "Get coordinates of the corfu popup."
  (frame-edges corfu--frame 'inner))

(defun corfu-doc--should-refresh-popup (candidate)
  "Determine whether the doc popup should be refreshed.

CANDIDATE is the current completion candidate, it should be
compared with the value recorded by `corfu-doc--candiate'."
  (and (string= candidate corfu-doc--candidate)
       (eq (selected-window) corfu-doc--cf-window)
       (frame-live-p corfu-doc--frame)))

(defun corfu-doc--refresh-popup ()
  "Update the position of the doc popup when corfu popup edges changed."
  (unless (corfu-doc--popup-visible-p)
    (make-frame-visible corfu-doc--frame))
  (when (corfu-doc--cf-popup-edges-changed-p)
    (apply #'corfu-doc--set-frame-position
           corfu-doc--frame
           (corfu-doc--calc-popup-position
            (frame-pixel-width corfu-doc--frame)
            (frame-pixel-height corfu-doc--frame)))
    (setq corfu-doc--cf-popup-edges (corfu-doc--get-cf-popup-edges))))

(defun corfu-doc--update-popup (doc)
  "Update the documentation popup with the DOC content."
  (corfu-doc--make-frame doc)
  (apply #'corfu-doc--set-frame-position
         corfu-doc--frame
         (corfu-doc--calc-popup-position)))

(defun corfu-doc--cf-popup-visible-p ()
  "Determine whether the corfu popup is visible."
  (and (frame-live-p corfu--frame)
       (frame-visible-p corfu--frame)))

(defun corfu-doc--should-show-popup (&optional candidate-index)
  "Determine whether the doc popup should be showed.

The optional CANDIDATE-INDEX is the the current completion candidate index,
it should be compared with the value recorded by `corfu--index'."
  (and corfu-mode (corfu--popup-support-p)
       (corfu-doc--cf-popup-visible-p)
       (or (null candidate-index)
           (equal candidate-index corfu--index))))

(defun corfu-doc--manual-popup-show (&optional candidate-index)
  "Show the doc popup manually.

The optional CANDIDATE-INDEX is the the current completion candidate index."
  (when (corfu-doc--should-show-popup candidate-index)
    (when-let ((candidate (corfu-doc--get-candidate))
               (cf-popup-edges (corfu-doc--get-cf-popup-edges)))
      (if (corfu-doc--should-refresh-popup candidate)
          (corfu-doc--refresh-popup)
        ;; fetch documentation and show
        (if-let* ((doc (corfu-doc--get-doc)))
            (progn
              (corfu-doc--update-popup doc)
              (corfu-doc--set-vars
               candidate cf-popup-edges (selected-window)))
          (corfu-doc--popup-hide))))))

(defun corfu-doc--clear-buffer ()
  "Clear the doc popup buffer content."
  (with-current-buffer
      (window-buffer (frame-root-window corfu-doc--frame))
    (let ((inhibit-read-only t))
      (erase-buffer))))

(defun corfu-doc--popup-hide ()
  "Clear the doc popup buffer content and hide it."
  (when (frame-live-p corfu-doc--frame)
    (make-frame-invisible corfu-doc--frame)
    (corfu-doc--clear-buffer)
    (corfu-doc--set-vars nil nil nil)))

(defun corfu-doc--cleanup ()
  "Cleanup advices and hide the doc popup."
  (advice-remove 'corfu--popup-hide #'corfu-doc--cleanup)
  (unless corfu-doc-mode
    (advice-remove 'corfu--popup-show #'corfu-doc--popup-show))
  (corfu-doc--popup-hide))

;;;###autoload
(define-minor-mode corfu-doc-mode
  "Corfu doc minor mode."
  :global t
  :group 'corfu
  (display-warning
   'corfu-doc
   "This package is now obsolete and superseded by the corfu built-in extension \
corfu-popupinfo. Please try to migrate."
   :warning)
  (cond
    (corfu-doc-mode
     (corfu-doc--manual-popup-show)
     (advice-add 'corfu--popup-show :after #'corfu-doc--popup-show)
     (advice-add 'corfu--popup-hide :after #'corfu-doc--popup-hide))
    (t
     (corfu-doc--popup-hide)
     (advice-remove 'corfu--popup-show #'corfu-doc--popup-show)
     (advice-remove 'corfu--popup-hide #'corfu-doc--popup-hide))))

(defun corfu-doc--popup-visible-p ()
  "Determine whether the doc popup is visible."
  (and (frame-live-p corfu-doc--frame)
       (frame-visible-p corfu-doc--frame)))

(defun corfu-doc--make-popup-invisible ()
  "Make the doc popup invisible."
  (make-frame-invisible corfu-doc--frame))

(defun corfu-doc--cf-popup-edges-changed-p ()
  "Determine whether the coordinates of the corfu popup have changed."
  (not (equal (corfu-doc--get-cf-popup-edges)
              corfu-doc--cf-popup-edges)))

(defun corfu-doc--popup-transition ()
  "Transition when updating the documentation popup."
  (when (corfu-doc--popup-visible-p)
    (if (and corfu-doc-mode corfu-doc-auto)
        (when (and (not (null corfu-doc-delay)) (> corfu-doc-delay 0))
          (pcase corfu-doc-transition
            ('clear
             (corfu-doc--clear-buffer)
             (corfu-doc--refresh-popup))
            ('hide (corfu-doc--make-popup-invisible))
            (_ (corfu-doc--refresh-popup))))
      (corfu-doc--popup-hide))))

(defun corfu-doc--popup-show (&rest _args)
  "Show doc popup for the current completion candidate."
  (when corfu-doc--auto-timer
    (cancel-timer corfu-doc--auto-timer)
    (setq corfu-doc--auto-timer nil))
  (when (corfu--popup-support-p)
    (if-let ((candidate (corfu-doc--get-candidate)))
        (progn
          (if (corfu-doc--should-refresh-popup candidate)
              (corfu-doc--refresh-popup)
            (corfu-doc--popup-transition)
            (when (and corfu-doc-mode corfu-doc-auto)
              (setq corfu-doc--auto-timer
                    (run-with-timer corfu-doc-delay nil
                     #'corfu-doc--manual-popup-show corfu--index)))))
      (corfu-doc--popup-hide))))

(defun corfu-doc--popup-scroll (n)
  "Scroll text of the documentaion buffer window upward N lines.

See `scroll-up' for details."
  (when-let ((cf-doc-buf
              (and (corfu-doc--popup-visible-p)
                   (get-buffer " *corfu-doc*"))))
    (with-selected-frame corfu-doc--frame
      (with-current-buffer cf-doc-buf
        (funcall #'scroll-up n)))))

;;;###autoload
(defun corfu-doc-scroll-up (&optional n)
  "Scroll text of doc popup window upward N lines.

If ARG is omitted or nil, scroll upward by a near full screen."
  (interactive "p")
  (corfu-doc--popup-scroll n))

;;;###autoload
(defun corfu-doc-scroll-down (&optional n)
  "Scroll text of doc popup window down N lines.

If ARG is omitted or nil, scroll down by a near full screen."
  (interactive "p")
  (corfu-doc--popup-scroll (- (or n 1))))

;;;###autoload
(defun corfu-doc-toggle ()
  "Toggle the doc popup display or hide.

When using this command to manually hide the doc popup, it will
not be displayed until this command is called again. Even if the
corfu doc mode is turned on and `corfu-doc-auto' is set to Non-nil."
  (interactive)
  (advice-add 'corfu--popup-hide :after #'corfu-doc--cleanup)
  (if (corfu-doc--popup-visible-p)
      (progn
        (corfu-doc--popup-hide)
        (advice-remove 'corfu--popup-show #'corfu-doc--popup-show))
    (corfu-doc--manual-popup-show)
    (advice-add 'corfu--popup-show :after #'corfu-doc--popup-show)))

;;;###autoload
(define-obsolete-function-alias 'toggle-corfu-doc-mode #'corfu-doc-mode "0.7")


(provide 'corfu-doc)
;;; corfu-doc.el ends here
