;;; nlinum-hl.el --- heal nlinum's line numbers -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2017-2021 Henrik Lissner
;;
;; Author: Henrik Lissner <http://github/hlissner>
;; Maintainer: Henrik Lissner <git@henrik.io>
;; Created: Jun 03, 2017
;; Modified: November 12, 2021
;; Version: 1.0.7
;; Package-Version: 20211112.1241
;; Package-Commit: 22f8d75ecdaab67e0d6d0d2da4766358456ca4f5
;; Keywords: nlinum highlight current line faces
;; Homepage: https://github.com/hlissner/emacs-nlinum-hl
;; Package-Requires: ((emacs "24.4") (nlinum "1.7") (cl-lib "0.5"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; `nlinum-hl' is an nlinum extension that tries to mitigate disappearing line
;; numbers in buffers that have been open a while (a known issue with nlinum).
;;
;;; Installation:
;;
;; M-x package-install RET nlinum-hl
;;
;;   (require 'nlinum-hl)
;;
;; 90% of the time this should be all you need.
;;
;; However, certain major-modes, commands and functions will still eat up line
;; numbers, typically as a result of using `with-silent-modifications` or
;; preventing jit-lock from detecting changes in general.
;;
;; In that case, this package provides these functions:
;;
;; + `nlinum-hl-flush-region': flush a specific region in the current window.
;; + `nlinum-hl-flush-all-windows': flush all open windows.
;; + `nlinum-hl-flush-window': flush the current window.
;;
;; Here are some examples of how to use them:
;;
;;   ;; A shotgun approach that refreshes line numbers on a regular basis:
;;   ;; Runs occasionally, though unpredictably
;;   (add-hook 'post-gc-hook #'nlinum-hl-flush-all-windows)
;;
;;   ;; whenever Emacs loses/gains focus
;;   (add-hook 'focus-in-hook  #'nlinum-hl-flush-all-windows)
;;   (add-hook 'focus-out-hook #'nlinum-hl-flush-all-windows)
;;   ;; ...or switches windows
;;   (advice-add #'select-window :before #'nlinum-hl-do-select-window-flush)
;;   (advice-add #'select-window :after  #'nlinum-hl-do-select-window-flush)
;;
;;   ;; after X amount of idle time
;;   (run-with-idle-timer 5 t #'nlinum-hl-flush-window)
;;   (run-with-idle-timer 30 t #'nlinum-hl-flush-all-windows)
;;
;;   ;; Bind it for flush-on-demand (this might be excessive)
;;   (global-set-key (kbd "<f9>") #'nlinum-hl-flush-all-windows)
;;   (global-set-key (kbd "<f8>") #'nlinum-hl-flush-window)
;;   (global-set-key (kbd "<f7>") #'nlinum-hl-flush-region) ; on selections
;;
;; Also included are a variety of `nlinum-hl-do-*' advice functions, meant to be
;; attached to certain functions with `advice-add'.
;;
;; Here are all the known issues and fixes (feel free to report/contribute
;; more):
;;
;;   ;; With `markdown-fontify-code-blocks-natively' enabled in `markdown-mode',
;;   ;; line numbers tend to vanish next to code blocks.
;;   (advice-add #'markdown-fontify-code-block-natively
;;               :after #'nlinum-hl-do-markdown-fontify-region)
;;
;;   ;; When using `web-mode's code-folding an entire range of line numbers will
;;   ;; vanish in the affected area.
;;   (advice-add #'web-mode-fold-or-unfold :after #'nlinum-hl-do-generic-flush)
;;
;;   ;; Changing fonts can leave nlinum line numbers in their original size; this
;;   ;; forces them to resize.
;;   (add-hook 'after-setting-font-hook #'nlinum-hl-flush-all-windows)
;;
;;; Code:

(require 'cl-lib)
(require 'nlinum)

(defgroup nlinum-hl nil
  "Options for nlinum-hl."
  :group 'faces)

;;
(defun nlinum-hl-flush-region (&optional beg end)
  "Redraw nlinum within the region BEG and END (points)."
  (interactive "r")
  (when nlinum-mode
    (nlinum--region (or beg (point-min))
                    (or end (point-max)))))

(defun nlinum-hl-flush-window (&optional window force-p)
  "If line numbers are missing in the current WINDOW, force nlinum to redraw.

If FORCE-P (universal argument), then do it regardless of whether line numbers
are missing or not."
  (interactive "iP")
  (let ((window (or window (selected-window)))
        (orig-win (selected-window)))
    (with-selected-window window
      (when nlinum-mode
        (let ((wbeg (window-start))
              (wend (window-end))
              (lines 0)
              (ovs 0))
          (unless force-p
            (save-excursion
              (goto-char wbeg)
              (while (and (<= (point) wend)
                          (not (eobp)))
                (cl-loop with lbeg = (line-beginning-position)
                         for ov in (overlays-in lbeg (1+ lbeg))
                         if (overlay-get ov 'nlinum)
                         do (cl-incf ovs))
                (forward-line 1)
                (cl-incf lines))))
          (when (or force-p (not (= ovs lines)))
            (nlinum-hl-flush-region)))))))

(defun nlinum-hl-flush-all-windows (&rest _)
  "Flush nlinum in all visible windows."
  (interactive)
  (mapc #'nlinum-hl-flush-window (window-list))
  nil)

(defun nlinum-hl-do-select-window-flush (&optional _ norecord &rest _)
  "Advice function for flushing the current window."
  ;; norecord check is necessary to prevent infinite recursion in
  ;; `select-window'
  (when (not norecord)
    (nlinum-hl-flush-window)))

(defun nlinum-hl-do-generic-flush (&rest _)
  "Advice function for flushing the current window."
  (nlinum-hl-flush-window))

(defun nlinum-hl-do-region (start limit)
  "Advice for `nlinum--region' that fixes a off-by-one error, causing missing
line numbers at certain intervals.

Credit for this fix goes to: https://github.com/gilbertw1"
  (save-excursion
    (let ((inhibit-point-motion-hooks t))
      (goto-char start)
      (unless (bolp) (forward-line 1))
      (remove-overlays (point) limit 'nlinum t)
      (let ((line (nlinum--line-number-at-pos)))
        (while
            (and (not (eobp)) (<= (point) limit)
                 (let* ((ol (make-overlay (point) (1+ (point))))
                        (str (funcall nlinum-format-function
                                      line nlinum--width))
                        (width (string-width str)))
                   (when (< nlinum--width width)
                     (setq nlinum--width width)
                     (nlinum--flush))
                   (overlay-put ol 'nlinum t)
                   (overlay-put ol 'evaporate t)
                   (overlay-put ol 'before-string
                                (propertize " " 'display
                                            `((margin left-margin) ,str)))
                   (setq line (1+ line))
                   (zerop (forward-line 1))))))))
  nil)
(advice-add #'nlinum--region :override #'nlinum-hl-do-region)

(defun nlinum-hl-do-markdown-fontify-region (_ beg end)
  "Advice for `markdown-fontify-code-block-natively' to fix disappearing line
numbers when rendering code blocks with `markdown-fontify-code-blocks-natively'
on."
  (nlinum-hl-do-region beg end))

(provide 'nlinum-hl)
;;; nlinum-hl.el ends here
