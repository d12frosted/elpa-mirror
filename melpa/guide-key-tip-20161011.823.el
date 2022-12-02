;;; guide-key-tip.el --- Show guide-key.el hints using pos-tip.el

;; Copyright (C) 2014  Hiroaki Otsu

;; Author: Hiroaki Otsu <ootsuhiroaki@gmail.com>
;; Keywords: help convenience Tooltip
;; Package-Version: 20161011.823
;; Package-Commit: 02c5d4b0b65f3e91be5a47f0ff1ae5e86e00c64e
;; URL: https://github.com/aki2o/guide-key-tip
;; Version: 0.0.1
;; Package-Requires: ((guide-key "1.2.3") (pos-tip "0.4.5"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;; 
;; This extension shows guide-key.el hints using pos-tip.el.

;;; Dependency:
;; 
;; - guide-key.el ( see <https://github.com/kbkbkbkb1/guide-key> )
;; - pos-tip.el

;;; Installation:
;;
;; Put this to your load-path.
;; And put the following lines in your .emacs or site-start.el file.
;; 
;; (require 'guide-key-tip)

;;; Configuration:
;; 
;; ;; Make config suit for you. About the config item, see Customization or eval the following sexp.
;; ;; (customize-group "guide-key-tip")
;; 
;; (setq guide-key-tip/enabled t)

;;; Customization:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'user-variable :prefix "guide-key-tip/" :docstring t)
;; `guide-key-tip/enabled'
;; Whether enable to use pos-tip.el for `guide-key/popup-function'.
;; 
;;  *** END auto-documentation

;;; API:
;; 
;; [EVAL] (autodoc-document-lisp-buffer :type 'command :prefix "guide-key-tip/" :docstring t)
;; `guide-key-tip/toggle-enable'
;; Toggle `guide-key-tip/enabled'.
;; 
;;  *** END auto-documentation
;; [Note] Functions and variables other than listed above, Those specifications may be changed without notice.

;;; Tested On:
;; 
;; - Emacs ... GNU Emacs 24.3.1 (i686-pc-linux-gnu, GTK+ Version 3.4.2) of 2013-08-22 on chindi02, modified by Debian
;; - guide-key.el ... Version 1.2.3
;; - pos-tip.el ... Version 0.4.5


;; Enjoy!!!

(require 'cl-lib)
(require 'guide-key)
(require 'pos-tip)

(defgroup guide-key-tip nil
  "Show guide-key.el hints using pos-tip.el."
  :group 'guide-key
  :prefix "guide-key-tip/")

(defcustom guide-key-tip/enabled nil
  "Whether to use pos-tip.el for `guide-key/popup-function'."
  :type 'boolean
  :group 'guide-key-tip)

(defface guide-key-tip/pos-tip-face '((t (:bold t)))
  "Face for the tip of pos-tip.el."
  :group 'guide-key-tip)


(defun guide-key-tip--get-pos-tip-size (string)
  "Return (WIDTH . HEIGHT) of the tip of pos-tip.el generated from STRING."
  (let* ((w-h (pos-tip-string-width-height string))
         (width (pos-tip-tooltip-width (car w-h) (frame-char-width)))
         (height (pos-tip-tooltip-height (cdr w-h) (frame-char-height))))
    (cons width height)))

(defun guide-key-tip--get-pos-tip-location ()
  "Return (WND RIGHT BOTTOM) as the location to show the tip of pos-tip.el."
  (let ((leftpt 0)
        (toppt 0)
        wnd rightpt bottompt)
    (dolist (w (window-list))
      (let* ((edges (when (not (minibufferp (window-buffer w)))
                      (window-pixel-edges w)))
             (currleftpt (or (nth 0 edges) -1))
             (currtoppt (or (nth 1 edges) -1)))
        (when (and (= currleftpt 0)
                   (= currtoppt 0))
          (setq wnd w))
        (when (or (not rightpt)
                  (> currleftpt leftpt))
          (setq rightpt (nth 2 edges))
          (setq leftpt currleftpt))
        (when (or (not bottompt)
                  (> currtoppt toppt))
          (setq bottompt (nth 3 edges))
          (setq toppt currtoppt))))
    (list wnd rightpt bottompt)))

(defun guide-key-tip/pos-tip-show (&optional input)
  "Popup function called after delay of `guide-key/idle-delay' seconds."
  (if (or (not window-system)
          (not (featurep 'pos-tip)))
      (guide-key/popup-function input)
    (let ((key-seq (or input (this-command-keys-vector)))
          (dsc-buf (current-buffer)))
      (cl-multiple-value-bind (wnd rightpt bottompt) (guide-key-tip--get-pos-tip-location)
        (with-temp-buffer
          (setq truncate-lines t)     ; don't fold line
          (setq indent-tabs-mode nil) ; don't use tab as white space
          (text-scale-set guide-key/text-scale-amount)
          (describe-buffer-bindings dsc-buf key-seq)
          (when (> (guide-key/format-guide-buffer key-seq) 0)
            (guide-key/turn-off-idle-timer)
            (copy-face 'guide-key-tip/pos-tip-face 'pos-tip-temp)
            (when (eq (face-attribute 'pos-tip-temp :font) 'unspecified)
              (set-face-font 'pos-tip-temp (frame-parameter nil 'font)))
            (set-face-bold 'pos-tip-temp (face-bold-p 'guide-key-tip/pos-tip-face))
            (let* ((string (buffer-string))
                   (string (propertize string 'face 'pos-tip-temp))
                   (max-width (pos-tip-x-display-width))
                   (max-height (pos-tip-x-display-height))
                   (tipsize (guide-key-tip--get-pos-tip-size string))
                   (tipsize (cond ((or (> (car tipsize) max-width)
                                       (> (cdr tipsize) max-height))
                                   (setq string (pos-tip-truncate-string string max-width max-height))
                                   (guide-key-tip--get-pos-tip-size string))
                                  (t
                                   tipsize)))
                   (tipwidth (car tipsize))
                   (tipheight (cdr tipsize))
                   (dx (- rightpt tipwidth 10))
                   (dy (- bottompt tipheight)))
              (pos-tip-show-no-propertize
               string 'pos-tip-temp 1 wnd 300 tipwidth tipheight nil dx dy))))))))


(defadvice guide-key/popup-function (around guide-key-tip activate)
  (if guide-key-tip/enabled
      (guide-key-tip/pos-tip-show (ad-get-arg 0))
    ad-do-it))


;;;###autoload
(defun guide-key-tip/toggle-enable ()
  "Toggle `guide-key-tip/enabled'."
  (interactive)
  (message "guide-key-tip/enabled is %s"
           (setq guide-key-tip/enabled (not guide-key-tip/enabled))))


(provide 'guide-key-tip)
;;; guide-key-tip.el ends here
