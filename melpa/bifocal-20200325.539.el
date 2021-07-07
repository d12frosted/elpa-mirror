;;; bifocal.el --- Split-screen scrolling for comint-mode buffers -*- lexical-binding: t -*-

;; Authors: Chris Rayner (dchrisrayner@gmail.com)
;; Created: May 23 2011
;; Keywords: frames, processes
;; Package-Version: 20200325.539
;; Package-Commit: de8d09b08b0b30714c4f9b98c97e9577d47b9be6
;; URL: https://github.com/riscy/bifocal-mode
;; SPDX-License-Identifier: GPL-3.0-or-later
;; Package-Requires: ((emacs "24.4"))
;; Version: 0.0.6

;;; Commentary:

;; In bifocal-mode, paging up causes a comint-mode buffer to be split into two
;; windows with a larger window on top (the head) and a smaller input window
;; preserved on the bottom (the tail):
;;
;; +--------------+
;; | -------      |
;; | -------      |
;; | -------      |
;; |    [head]    |
;; |(show history)|
;; +--------------+
;; |    [tail]    |
;; |(show context)|
;; +--------------+
;;
;; This helps with monitoring new output and entering text at the prompt (in the
;; tail window), while reviewing previous output (in the head window).  Paging
;; down all the way causes the split to disappear.
;;
;; Note if you're not on the last line of a buffer, no split will appear.
;;
;; This version tested with Emacs 25.2.1
;;
;; See README.org for more details.

;;; Installation:

;; 1. Move this file to a directory in your load-path or add
;;    this to your .emacs:
;;    (add-to-list 'load-path "~/path/to/this-file/")
;; 2. Next add this line to your .emacs:
;;    (require 'bifocal)

;;; Code:

(require 'comint)
(require 'windmove)

(defgroup bifocal nil
  "For split-screen scrolling inside a comint-mode buffer."
  :prefix "bifocal-"
  :group 'comint
  :link '(url-link
          :tag "bifocal on GitHub"
          "https://github.com/riscy/bifocal-mode"))

(defcustom bifocal-minimum-rows-before-splitting 30
  "The minimum window height before splitting the window is allowed."
  :link '(function-link bifocal--splittable-p)
  :type 'integer)

(defcustom bifocal-lighter " B"
  "Mode-line lighter for the bifocal minor mode."
  :type 'string)

(defcustom bifocal-tail-size 15
  "The number of rows the tail window will have.
This is also the number of lines to scroll by at a time."
  :type 'integer)

(defcustom bifocal-use-dedicated-windows t
  "Whether to flag the head and tail as \"dedicated\" windows.
The original settings are restored when the split is destroyed."
  :link '(function-link window-dedicated-p)
  :type 'boolean)

(defvar bifocal-mode-map
  (let ((keymap (make-sparse-keymap)))
    (define-key keymap (kbd "<prior>") #'bifocal-up)
    (define-key keymap (kbd "<next>") #'bifocal-down)
    (define-key keymap (kbd "<home>") #'bifocal-home)
    (define-key keymap (kbd "M-<") #'bifocal-home)
    (define-key keymap (kbd "<end>") #'bifocal-end)
    (define-key keymap (kbd "M->") #'bifocal-end)
    keymap)
  "Keymap for the bifocal minor mode.")

(defvar-local bifocal--old-comint-move-point-for-output :none
  "Stores a variable's previous value, so it can be restored.")

(defvar-local bifocal--old-comint-scroll-to-bottom-on-input :none
  "Stores a variable's previous value, so it can be restored.")

(defvar-local bifocal--old-window-dedicated-p :none
  "Stores a variable's previous value, so it can be restored.")

(defvar-local bifocal--head nil
  "The \"head\" window, when it exists; otherwise nil.")

(defvar-local bifocal--tail nil
  "The \"tail\" window, when it exists; otherwise nil.")

(defun bifocal-down ()
  "Scroll down.
If the window is split, scroll down in the head window only.
If this scrolls to the last line, remove the split."
  (interactive)
  (if (not (bifocal--find-head))
      (bifocal--move-point-down)
    (bifocal--move-point-down)
    (if (bifocal--last-line-p)
        (bifocal-end)
      (select-window bifocal--tail))
    (bifocal--recenter-on-last-line)))

(defun bifocal-end ()
  "Scroll to the end of the buffer."
  (interactive)
  (bifocal--turn-off))

(defun bifocal-home ()
  "Scroll to the top of the buffer.
Create the head/tail split unless it exists."
  (interactive)
  (bifocal-up 'home))

(defun bifocal-up (&optional home)
  "Scroll up.
If the window is not split, try to split it.  Then scroll up in
the head window.  If HOME is non-nil, scroll to the top."
  (interactive)
  (cond ((bifocal--splittable-p)
         (unless (bifocal--find-head)
           (bifocal--create-split))
         (bifocal--move-point-up home)
         (select-window bifocal--tail)
         (bifocal--recenter-on-last-line))
        (t (bifocal--move-point-up home))))

(defun bifocal--create-split ()
  "Create the head/tail split."
  (split-window-vertically (- (window-height) bifocal-tail-size))
  (setq-local bifocal--head (selected-window))
  (setq-local bifocal--tail (next-window))
  (when (derived-mode-p 'comint-mode)
    (bifocal--set-scroll-options))
  (when bifocal-use-dedicated-windows
    (bifocal--set-dedicated-windows)))

(defun bifocal--destroy-split ()
  "Destroy the head/tail split."
  (bifocal--unset-dedicated-windows)
  (bifocal--unset-scroll-options)
  (when (bifocal--find-head)
    ;; removing the tail always maintains window size, but could move the point:
    (let ((pt (save-window-excursion (select-window bifocal--tail) (point))))
      (delete-window bifocal--tail)
      (goto-char pt)))
  (setq-local bifocal--head nil)
  (setq-local bifocal--tail nil))

(defun bifocal--find-head ()
  "Put the point on the head window.
Return nil if the head window is not identifiable."
  (and bifocal--head
       bifocal--tail
       (cond ((bifocal--point-on-tail-p) (select-window bifocal--head) t)
             ((bifocal--point-on-head-p) t)
             (t nil))))

(defun bifocal--last-line-p ()
  "Whether POINT is on the last line of the buffer."
  (declare (side-effect-free t))
  (let ((inhibit-field-text-motion t))
    (eq (point-max) (point-at-eol))))

(defun bifocal--move-point-down ()
  "Move the point down `bifocal-tail-size' rows, and recenter."
  (move-to-window-line -1)
  (let ((line-move-visual t))
    (ignore-errors (line-move bifocal-tail-size)))
  (recenter -1))

(defun bifocal--move-point-up (&optional home)
  "Move the point up `bifocal-tail-size' rows, and recenter.
If HOME is non-nil, go to `point-min' instead."
  (cond (home
         (goto-char (point-min)))
        ((not (bifocal--top-p))
         (let ((line-move-visual t))
           (ignore-errors (line-move (- bifocal-tail-size))))
         (recenter -1))))

(defun bifocal--oriented-p (start-window dir end-window)
  "Confirm the relative position of two windows viewing one buffer.
That is, START-WINDOW is selected, moving in direction DIR (via
'windmove') selects END-WINDOW, and both view the same buffer."
  (declare (side-effect-free t))
  (and (eq (selected-window) start-window)
       (let ((dir-window (windmove-find-other-window dir)))
         (and (eq dir-window end-window)
              (eq (current-buffer) (window-buffer dir-window))))))

(defun bifocal--point-on-head-p ()
  "Whether the point is on the head window."
  (declare (side-effect-free t))
  (bifocal--oriented-p bifocal--head 'down bifocal--tail))

(defun bifocal--point-on-tail-p ()
  "Whether the point is on the tail window."
  (declare (side-effect-free t))
  (bifocal--oriented-p bifocal--tail 'up bifocal--head))

(defun bifocal--recenter-on-last-line ()
  "Ensure point is on the last line, and recenter."
  (unless (bifocal--last-line-p) (goto-char (point-max)))
  ;; `recenter'ing errors when this isn't the active buffer:
  (ignore-errors (recenter -1))
  ;; move to the input area if we're on the output area:
  (when (eq (get-text-property (point) 'field) 'output)
    (goto-char (point-at-eol))))

(defun bifocal--set-scroll-options ()
  "Adjust comint-scroll variables for split-screen scrolling."
  (when (eq bifocal--old-comint-scroll-to-bottom-on-input :none)
    (setq-local bifocal--old-comint-move-point-for-output
                comint-move-point-for-output))
  (when (eq bifocal--old-comint-scroll-to-bottom-on-input :none)
    (setq-local bifocal--old-comint-scroll-to-bottom-on-input
                comint-scroll-to-bottom-on-input))
  (setq-local comint-move-point-for-output 'this)
  (setq-local comint-scroll-to-bottom-on-input nil))

(defun bifocal--set-dedicated-windows ()
  "Adjust window-dedicated options on the head and tail windows."
  (when (eq bifocal--old-window-dedicated-p :none)
    (setq-local bifocal--old-window-dedicated-p (window-dedicated-p)))
  (set-window-dedicated-p bifocal--head t)
  (set-window-dedicated-p bifocal--tail t))

(defun bifocal--splittable-p ()
  "Whether the current window is able to be split."
  (declare (side-effect-free t))
  (and (bifocal--last-line-p)
       (not (bifocal--top-p))
       (or (bifocal--find-head)
           (>= (window-height) bifocal-minimum-rows-before-splitting))))

(defun bifocal--top-p ()
  "Whether `point-min' is visible in this window."
  (declare (side-effect-free t))
  (save-excursion
    (move-to-window-line 0)
    (eq (point-at-bol) (point-min))))

(defun bifocal--turn-off ()
  "Remove the head/tail split if it exists."
  (bifocal--destroy-split)
  (bifocal--recenter-on-last-line))

(defun bifocal--turn-on ()
  "Call the function `bifocal-mode' if appropriate."
  (when (derived-mode-p 'comint-mode) (bifocal-mode +1)))

(defun bifocal--unset-scroll-options ()
  "Unset comint-scroll variables to their original values."
  (unless (eq bifocal--old-comint-move-point-for-output :none)
    (setq-local comint-move-point-for-output
                bifocal--old-comint-move-point-for-output)
    (setq-local bifocal--old-comint-move-point-for-output :none))
  (unless (eq bifocal--old-comint-scroll-to-bottom-on-input :none)
    (setq-local comint-scroll-to-bottom-on-input
                bifocal--old-comint-scroll-to-bottom-on-input)
    (setq-local bifocal--old-comint-scroll-to-bottom-on-input :none)))

(defun bifocal--unset-dedicated-windows ()
  "Unset window-dedicated options on the head and tail windows."
  (unless (eq bifocal--old-window-dedicated-p :none)
    (when (window-live-p bifocal--head)
      (set-window-dedicated-p bifocal--head bifocal--old-window-dedicated-p))
    (when (window-live-p bifocal--tail)
      (set-window-dedicated-p bifocal--tail bifocal--old-window-dedicated-p))
    (setq bifocal--old-window-dedicated-p :none)))

;;;###autoload
(define-minor-mode bifocal-mode
  "Toggle bifocal-mode on or off.\n
  bifocal-mode splits the buffer into a head and a tail when
paging up and down in a comint-mode derived buffer (such as
shell-mode, inferior-python-mode, etc).\n
  Use `bifocal-global-mode' to enable `bifocal-mode' in all
buffers that support it.\n
  Provides the following bindings:\n
\\{bifocal-mode-map}"
  :lighter bifocal-lighter
  :keymap bifocal-mode-map
  (if bifocal-mode
      nil
    (bifocal--turn-off)))

;;;###autoload
(define-globalized-minor-mode bifocal-global-mode bifocal-mode bifocal--turn-on :require 'bifocal)

(provide 'bifocal)
;;; bifocal.el ends here
