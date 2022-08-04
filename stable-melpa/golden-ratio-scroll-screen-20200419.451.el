;;; golden-ratio-scroll-screen.el --- Scroll half screen down or up, and highlight current line

;; Author: 纪秀峰 <jixiuf at gmail dot com>
;; Copyright (C) 2011~2015,纪秀峰 , all rights reserved.
;; Created: 2011-03-01
;; Version: 1.1
;; URL:   https://github.com/jixiuf/golden-ratio-scroll-screen
;; Keywords: scroll screen highlight
;;
;; This file is NOT part of GNU Emacs
;;
;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:

;; Scroll screen down or up, and highlight current line before
;; or after scrolling
;; the lines it scrolling is screen_height*0.618

;; And the following to your ~/.emacs startup file.
;;
;; (require 'golden-ratio-scroll-screen)
;; (global-set-key [remap scroll-down-command] 'golden-ratio-scroll-screen-down)
;; (global-set-key [remap scroll-up-command] 'golden-ratio-scroll-screen-up)
;;
;; or:
;;
;; (autoload 'golden-ratio-scroll-screen-down "golden-ratio-scroll-screen" "scroll half screen down" t)
;; (autoload 'golden-ratio-scroll-screen-up "golden-ratio-scroll-screen" "scroll half screen up" t)
;; (global-set-key [remap scroll-down-command] 'golden-ratio-scroll-screen-down)
;; (global-set-key [remap scroll-up-command] 'golden-ratio-scroll-screen-up)
;;

;;; Codes

;; (require 'dired)

(declare-function dired-previous-line "dired")
(declare-function dired-next-line "dired")
(autoload 'dired-previous-line "dired")
(autoload 'dired-next-line "dired")

(defgroup golden-ratio-scroll-screen nil
  "scroll screen half down or up."
  :prefix "golden-ratio-scroll-screen"
  :group 'scrolling)
(defcustom golden-ratio-scroll-recenter t
  "recenter or not after scroll"
  :group 'golden-ratio-scroll-screen
  :type 'boolean)

(defcustom golden-ratio-scroll-screen-ratio 1.618
  "forward or backward (window-text-height)/this-value lines "
  :group 'golden-ratio-scroll-screen
  :type 'number)

(defcustom golden-ratio-scroll-highlight-flag 'both
  "highlight or not before or after scroll"
  :group 'golden-ratio-scroll-screen
  :type '(choice
          (const :tag "do not highlight" nil)
          (const :tag "highlight line before scroll" 'before)
          (const :tag "highlight line after scroll" 'after)
          (const :tag "highlight line both before and after scroll" 'both)))

(defcustom golden-ratio-scroll-highlight-delay (cons 0.15 0.1)
  "*How long to highlight the line ."
  :group 'golden-ratio-scroll-screen
  :type 'number)

(defcustom golden-ratio-scroll-screen-up-hook nil
  ""
  :type 'hook)
(defcustom golden-ratio-scroll-screen-down-hook nil
  ""
  :type 'hook)

(defface golden-ratio-scroll-highlight-line-face
  `((t (,@(and (>= emacs-major-version 27) '(:extend t))
        :background "cadetblue4"
        :foreground "white"
        :weight bold)))
  "Font Lock mode face used to highlight line.
 (borrowed from etags-select.el)"
  :group 'golden-ratio-scroll-screen)

(defun golden-ratio-scroll-highlight (beg end delay)
  "Highlight a region temporarily.
  (borrowed from etags-select.el)"
  (if (featurep 'xemacs)
      (let ((extent (make-extent beg end)))
        (set-extent-property extent 'face
                             'golden-ratio-scroll-highlight-line-face)
        (sit-for delay)
        (delete-extent extent))
    (let ((ov (make-overlay beg end)))
      (overlay-put ov 'face 'golden-ratio-scroll-highlight-line-face)
      (sit-for delay)
      (delete-overlay ov))))

(defvar golden-ratio-scroll-screen-previous-point (point-marker))

;;;###autoload
(defun golden-ratio-scroll-screen-up()
  "scroll half screen up"
  (interactive)
  (let ((old-marker golden-ratio-scroll-screen-previous-point)
        (bol-before-jump (point-at-bol))
        (eol-before-jump (1+ (point-at-eol)))
        (scroll-line-cnt (round (/ (window-text-height)
                                   golden-ratio-scroll-screen-ratio))))
    (setq golden-ratio-scroll-screen-previous-point (point-marker))
    (if (and (not (and (equal (current-buffer) (marker-buffer old-marker))
                       (equal (marker-position old-marker) (point))))
             (equal last-command 'golden-ratio-scroll-screen-down))
        (goto-char (marker-position old-marker))
      (forward-visible-line scroll-line-cnt))
    (when (and (member major-mode '(dired-mode wdired-mode))
               (equal (point-max) (point)))
      (dired-previous-line 1))
    (when golden-ratio-scroll-recenter
      (recenter (+ scroll-line-cnt (/ (- (window-text-height) scroll-line-cnt) 2))))
    (when (member golden-ratio-scroll-highlight-flag '(before both))
      (golden-ratio-scroll-highlight
       bol-before-jump eol-before-jump
       (car golden-ratio-scroll-highlight-delay)))
    (when (member golden-ratio-scroll-highlight-flag '(after both))
      (golden-ratio-scroll-highlight
       (point-at-bol) (1+ (point-at-eol))
       (cdr golden-ratio-scroll-highlight-delay)))
    (run-hooks 'golden-ratio-scroll-screen-down-hook)))

;;;###autoload
(defun golden-ratio-scroll-screen-down()
  "scroll half screen down"
  (interactive)
  (let ((old-marker golden-ratio-scroll-screen-previous-point)
        (bol-before-jump (point-at-bol))
        (eol-before-jump (1+ (point-at-eol)))
        (scroll-line-cnt (round (/ (window-text-height)
                                   golden-ratio-scroll-screen-ratio))))
    (setq golden-ratio-scroll-screen-previous-point (point-marker))
    (if (and  (not (and (equal (current-buffer) (marker-buffer old-marker))
                        (equal (marker-position old-marker) (point))))
              (equal last-command 'golden-ratio-scroll-screen-up))
        (goto-char (marker-position old-marker))
      (forward-visible-line (- 0 scroll-line-cnt)))
    (when (and (member major-mode '(dired-mode wdired-mode))
               (equal (point-min) (point)))
      (dired-next-line 2))
    (when golden-ratio-scroll-recenter
      (recenter (/ (- (window-text-height) scroll-line-cnt) 2)))
    (when (member golden-ratio-scroll-highlight-flag '(before both))
      (golden-ratio-scroll-highlight
       bol-before-jump eol-before-jump
       (car golden-ratio-scroll-highlight-delay)))
    (when (member golden-ratio-scroll-highlight-flag '(after both))
      (golden-ratio-scroll-highlight
       (point-at-bol) (1+ (point-at-eol))
       (cdr golden-ratio-scroll-highlight-delay))))
  (run-hooks 'golden-ratio-scroll-screen-up-hook))

(put 'golden-ratio-scroll-screen-up 'scroll-command t)
(put 'golden-ratio-scroll-screen-down 'scroll-command t)

(provide 'golden-ratio-scroll-screen)

;;; golden-ratio-scroll-screen.el ends here
