;;; highlight-parentheses.el --- Highlight surrounding parentheses
;;
;; Copyright (C) 2007, 2009, 2013 Nikolaj Schumacher
;; Copyright (C) 2018 Tim Perkins
;;
;; Author: Nikolaj Schumacher <bugs * nschum de>
;; Maintainer: Tassilo Horn <tsdh@gnu.org>
;; Version: 2.0.0
;; Package-Version: 20210104.1625
;; Package-Commit: 23fe07f588ff1e835fb9db12f1073b22d8d7ba68
;; Keywords: faces, matching
;; URL: https://github.com/tsdh/highlight-parentheses.el
;;      http://nschum.de/src/emacs/highlight-parentheses/ (old website)
;; Package-Requires: ((emacs "24.3") (cl-lib "0.6.1"))
;; Compatibility: GNU Emacs 24.3, GNU Emacs 25.x, GNU Emacs 26.x, Emacs 27.x
;;
;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 2
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Add the following to your .emacs file:
;; (require 'highlight-parentheses)
;;
;; Enable the mode using M-x highlight-parentheses-mode or by adding it to a
;; hook.
;;
;;; Code:

(require 'cl-lib)

(defgroup highlight-parentheses nil
  "Highlight surrounding parentheses"
  :group 'faces
  :group 'matching)


;;; Custom Variables

(define-obsolete-function-alias
  'hl-paren-set 'highlight-parentheses--set "2.0.0")
(defun highlight-parentheses--set (variable value)
  "Set VARIABLE to a new VALUE and update highlighted parens in all buffers.

This function is used so that appropriate custom variables apply
immediately once set (through the custom interface)."
  (set variable value)
  ;; REVIEW: I assume this check is here for cases that are too early into the
  ;; load process?
  (when (fboundp 'highlight-parentheses--color-update)
    (highlight-parentheses--color-update)))

;; TODO: There should probably be more documentation on how this variable works
;; as a function.  Same for the others.
(define-obsolete-variable-alias 'hl-paren-colors
  'highlight-parentheses-colors "2.0.0")
(defcustom highlight-parentheses-colors
  '("firebrick1" "IndianRed1" "IndianRed3" "IndianRed4")
  "List of colors for the highlighted parentheses.
The list starts with the inside parentheses and moves outwards."
  :type '(choice (repeat color) function)
  :set #'highlight-parentheses--set
  :group 'highlight-parentheses)

(define-obsolete-variable-alias 'hl-paren-background-colors
  'highlight-parentheses-background-colors "2.0.0")
(defcustom highlight-parentheses-background-colors nil
  "List of colors for the background highlighted parentheses.
The list starts with the inside parentheses and moves outwards."
  :type '(choice (repeat color) function)
  :set #'highlight-parentheses--set
  :group 'highlight-parentheses)

(define-obsolete-variable-alias 'hl-paren-attributes
  'highlight-parentheses-attributes "2.0.0")
(defcustom highlight-parentheses-attributes nil
  "List of face attributes for the highlighted parentheses.
The list starts with the inside parentheses and moves outwards."
  :type '(choice plist function)
  :set #'highlight-parentheses--set
  :group 'highlight-parentheses)

(define-obsolete-variable-alias 'hl-paren-highlight-adjacent
  'highlight-parentheses-highlight-adjacent "2.0.0")
(defcustom highlight-parentheses-highlight-adjacent nil
  "Highlight adjacent parentheses, just like Show Paren mode."
  :type '(boolean)
  :set #'highlight-parentheses--set
  :group 'highlight-parentheses)

(define-obsolete-variable-alias 'hl-paren-delay
  'highlight-parentheses-delay "2.0.0")
(defcustom highlight-parentheses-delay 0.137
  "Fraction of seconds after which the overlays are adjusted.
In general, this should at least be larger than your keyboard
repeat rate in order to prevent excessive movements of the
overlays when scrolling or moving point by pressing and holding
\\[next-line], \\[scroll-up-command] and friends."
  :type 'number
  :group 'highlight-parentheses)


;; Custom Faces

(define-obsolete-face-alias 'hl-paren-face
  'highlight-parentheses-highlight "2.0.0")
(defface highlight-parentheses-highlight nil
  "Face used for highlighting parentheses.
Color attributes might be overriden by `highlight-parentheses-colors' and
`highlight-parentheses-background-colors'."
  :group 'highlight-parentheses)


;;; Internal Variables

(defvar-local highlight-parentheses--overlays nil
  "This buffers currently active overlays.")

(defvar-local highlight-parentheses--last-point 0
  "The last point for which parentheses were highlighted.
This is used to prevent analyzing the same context over and over.")

(defvar-local highlight-parentheses--timer nil
  "A timer initiating the movement of the `highlight-parentheses--overlays'.")


;;; Internal Functions
(define-obsolete-function-alias 'hl-paren-delete-overlays
  'highlight-parentheses--delete-overlays "2.0.0")

(cl-defun highlight-parentheses--delete-overlays
    (&optional (overlays highlight-parentheses--overlays))
  "Delete all overlays set by Highlight Parentheses in the current buffer.

If the optional argument OVERLAYS (a list) is non-nil, delete all
overlays in it instead."
  (mapc #'delete-overlay overlays))

(define-obsolete-function-alias 'hl-paren-highlight
  'highlight-parentheses--highlight "2.0.0")
(defun highlight-parentheses--highlight ()
  "Highlight the parentheses around point."
  (unless (= (point) highlight-parentheses--last-point)
    (setq highlight-parentheses--last-point (point))
    (let ((overlays highlight-parentheses--overlays)
          pos1 pos2)
      (save-excursion
        (ignore-errors
          (when highlight-parentheses-highlight-adjacent
            (cond ((memq (preceding-char) '(?\) ?\} ?\] ?\>))
                   (backward-char 1))
                  ((memq (following-char) '(?\( ?\{ ?\[ ?\<))
                   (forward-char 1))))
          (while (and (setq pos1 (cadr (syntax-ppss pos1)))
                      (cdr overlays))
            (move-overlay (pop overlays) pos1 (1+ pos1))
            (when (setq pos2 (scan-sexps pos1 1))
              (move-overlay (pop overlays) (1- pos2) pos2)))))
      (highlight-parentheses--delete-overlays overlays))))

(define-obsolete-function-alias 'hl-paren-initiate-highlight
  'highlight-parentheses--initiate-highlight "2.0.0")
(defun highlight-parentheses--initiate-highlight ()
  "Move the `highlight-parentheses--overlays' after a `highlight-parentheses-delay' secs."
  (when highlight-parentheses--timer
    (cancel-timer highlight-parentheses--timer))
  (setq highlight-parentheses--timer
        (run-at-time highlight-parentheses-delay nil
                     #'highlight-parentheses--highlight)))


;;; Mode Functions
;;;###autoload
(define-minor-mode highlight-parentheses-mode
  "Minor mode to highlight the surrounding parentheses."
  ;; REVIEW: Given the minor mode has no menu, we could also remove the lighter.
  nil " hl-p" nil
  (highlight-parentheses--delete-overlays)
  (kill-local-variable 'highlight-parentheses--overlays)
  (kill-local-variable 'highlight-parentheses--last-point)
  (remove-hook 'post-command-hook
               #'highlight-parentheses--initiate-highlight t)
  (remove-hook 'before-revert-hook
               #'highlight-parentheses--delete-overlays)
  (remove-hook 'change-major-mode-hook
               #'highlight-parentheses--delete-overlays)
  (when (and highlight-parentheses-mode
             ;; Don't enable in *Messages* buffer.
             ;; https://github.com/tsdh/highlight-parentheses.el/issues/14
             (not (eq major-mode 'messages-buffer-mode))
             (not (string= (buffer-name) "*Messages*")))
    (highlight-parentheses--create-overlays)
    (add-hook 'post-command-hook
              #'highlight-parentheses--initiate-highlight nil t)
    (add-hook 'before-revert-hook
              #'highlight-parentheses--delete-overlays)
    (add-hook 'change-major-mode-hook
              #'highlight-parentheses--delete-overlays)))

;;;###autoload
(define-globalized-minor-mode global-highlight-parentheses-mode
  highlight-parentheses-mode
  (lambda () (highlight-parentheses-mode 1)))


;;; Overlays

(defun highlight-parentheses--create-overlays ()
  "Initialize `highlight-parentheses--overlays' buffer-locally."
  (let ((fg (if (functionp highlight-parentheses-colors)
                (funcall highlight-parentheses-colors)
              highlight-parentheses-colors))
        (bg (if (functionp highlight-parentheses-background-colors)
                (funcall highlight-parentheses-background-colors)
              highlight-parentheses-background-colors))
        (attr (if (functionp highlight-parentheses-attributes)
                  (funcall highlight-parentheses-attributes)
                highlight-parentheses-attributes))
        attributes)
    (while (or fg bg attr)
      (setq attributes (face-attr-construct 'highlight-parentheses-highlight))
      (let ((car-fg (car fg))
            (car-bg (car bg))
            (car-attr (car attr)))
        (cl-loop for (key . (val . _rest)) on car-attr by #'cddr
              do (setq attributes
                       (plist-put attributes key val)))
        (when car-fg
          (setq attributes (plist-put attributes :foreground car-fg)))
        (when car-bg
          (setq attributes (plist-put attributes :background car-bg))))
      (pop fg)
      (pop bg)
      (pop attr)
      (dotimes (i 2) ;; front and back
        (push (make-overlay 0 0 nil t) highlight-parentheses--overlays)
        (overlay-put (car highlight-parentheses--overlays) 'font-lock-face attributes)))
    (setq highlight-parentheses--overlays (nreverse highlight-parentheses--overlays))))

(defun highlight-parentheses--color-update ()
  "Force-update highlighted parentheses in all buffers."
  (dolist (buffer (buffer-list))
    (with-current-buffer buffer
      (when highlight-parentheses--overlays
        (highlight-parentheses--delete-overlays)
        (setq highlight-parentheses--overlays nil)
        (highlight-parentheses--create-overlays)
        (let ((highlight-parentheses--last-point -1)) ;; force update
          (highlight-parentheses--highlight))))))

(provide 'highlight-parentheses)

;;; highlight-parentheses.el ends here
