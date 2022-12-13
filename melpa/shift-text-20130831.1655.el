;;; shift-text.el --- Move the region in 4 directions, in a way similar to Eclipse's
;;; Version: 0.3
;; Package-Version: 20130831.1655
;; Package-Commit: 1be9cbf994000022172ceb746fe1d597f57ea8ba
;;; Author: sabof
;;; URL: https://github.com/sabof/shift-text
;;; Package-Requires: ((cl-lib "1.0") (es-lib "0.3"))

;;; Commentary:

;; The project is hosted at https://github.com/sabof/shift-text
;; The latest version, and all the relevant information can be found there.

;;; License:

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program ; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

(require 'cl-lib)
(require 'es-lib)

(defvar st-indent-step
  (lambda ()
    (cond
      ( (eq major-mode 'js-mode)
        js-indent-level)
      ( (eq major-mode 'css-mode)
        css-indent-offset)
      ( (memq major-mode
              '(emacs-lisp-mode
                lisp-mode
                lisp-interaction-mode
                scheme-mode))
        2)
      ( t tab-width)
      ))
  "How much to indent when shifting horizontally.

You can set it for specific modes in their mode-hooks with `setq-local'.
For example \(setq-local st-indent-step 2\).

Can also be a function called without arguments and evaluting to a number.")

(defun st--section-marking-end-of-line (&optional pos using-region)
  (save-excursion
    (when pos
      (goto-char pos))
    (if (and using-region (equal (current-column) 0))
        (point)
      (min (point-max) (1+ (es-total-line-end-position))))))

(defun st--normalize-pos (pos)
  (min (point-max) (max (point-min) pos)))

(defun st--shift-text-internal (arg)
  (let* (( was-active (use-region-p))
         ( first-line-was-folded
           (save-excursion
             (when was-active
               (goto-char (region-beginning)))
             (es-line-folded-p)))
         ( initial-column (current-column))
         ( start (es-total-line-beginning-position
                  (if was-active
                      (region-beginning)
                      (point))))
         ( end (st--section-marking-end-of-line
                (if was-active
                    (region-end)
                    (point))
                was-active))
         ( virtual-overlays
           (mapcar 'es-preserve-overlay (overlays-in start end)))
         ( text (delete-and-extract-region start end))
         new-start
         difference)
    (es-total-forward-line arg)
    (unless (zerop (current-column))
      (insert ?\n ))
    (setq new-start (point)
          difference (- new-start start))
    (insert text)
    (unless (equal (aref text (1- (length text)))
                   ?\n )
      (insert ?\n ))
    (cl-dolist (ov virtual-overlays)
      (setf (nth 1 ov) (st--normalize-pos (+ (nth 1 ov) difference)))
      (setf (nth 2 ov) (st--normalize-pos (+ (nth 2 ov) difference))))
    (mapc 'es-restore-overlay virtual-overlays)
    (set-mark new-start)
    (exchange-point-and-mark)
    (if (or was-active first-line-was-folded)
        (setq deactivate-mark nil
              cua--explicit-region-start nil)
      (progn (move-to-column initial-column t)
             (deactivate-mark)))))

(defun st--indent-rigidly-internal (arg)
  (let* (( indent-step (if (functionp st-indent-step)
                           (funcall st-indent-step)
                         st-indent-step))
         ( indentation-ammout
           (* arg indent-step))
         ( old-indentation
           (save-excursion
             (when (use-region-p)
               (goto-char (region-beginning)))
             (current-indentation)))
         ( old-indentation-adujusted
           (* indent-step
              (/ old-indentation
                 indent-step)))
         ( desired-indentation
           (+ old-indentation-adujusted
              indentation-ammout))
         ( new-ammount
           (- desired-indentation old-indentation)))
    (cond ( (use-region-p)
            (let (( start
                    (es-total-line-beginning-position
                     (region-beginning)))
                  ( end
                    (st--section-marking-end-of-line
                     (region-end)
                     t)))
              (set-mark end)
              (goto-char start)
              (indent-rigidly start end new-ammount)
              (setq deactivate-mark nil)))
          ( (es-line-empty-p)
            (if (> desired-indentation old-indentation)
                (indent-to desired-indentation)
              (goto-char (max (line-beginning-position)
                              (+ desired-indentation
                                 (line-beginning-position))))
              (delete-region (point) (line-end-position))
              ))
          ( t (indent-rigidly
               (es-total-line-beginning-position (point))
               (st--section-marking-end-of-line (point))
               new-ammount)))))

;;;###autoload
(defun shift-text-down ()
  "Move region or the current line down."
  (interactive)
  (st--shift-text-internal 1))

;;;###autoload
(defun shift-text-up ()
  "Move region or the current line up."
  (interactive)
  (st--shift-text-internal -1))

;;;###autoload
(defun shift-text-left ()
  "Move region or the current line left."
  (interactive)
  (st--indent-rigidly-internal -1))

;;;###autoload
(defun shift-text-right ()
  "Move region or the current line right."
  (interactive)
  (st--indent-rigidly-internal 1))

(provide 'shift-text)
;;; shift-text.el ends here
