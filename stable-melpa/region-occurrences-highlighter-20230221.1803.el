;;; region-occurrences-highlighter.el --- Mark occurrences of current region (selection).  -*- lexical-binding: t; -*-

;; Author: Álvaro González Sotillo <alvarogonzalezsotillo@gmail.com>
;; URL: https://github.com/alvarogonzalezsotillo/region-occurrences-highlighter
;; Package-Version: 20230221.1803
;; Package-Commit: 9c2a3193ccf32f8fa48578a6b8826b2959dac120
;; Package-Requires: ((emacs "24"))
;; Version: 1.5
;; Keywords: convenience

;; This file is not part of GNU Emacs.

;;; License:

;; GNU General Public License v3.0. See COPYING for details.

;;; Commentary:

;; This minor mode marks all the occurrences of the current region (selection)
;;
;; Quick start:
;; Enable region-occurrences-highlighter-mode, via alt-X or using hooks
;;
;; More information at https://github.com/alvarogonzalezsotillo/region-occurrences-highlighter



;;; News:
;;
;;;; Changes since v1.4:
;;
;; - Added `region-occurrences-highlighter-all-visible-buffers' and `region-occurrences-highlighter-case-fold-search'
;;
;;;; Changes since v1.3:
;;
;; - Added global minor mode (thanks to Jen-Chieh Shen)
;;
;;;; Changes since v1.2:
;;
;; - Added `region-occurrences-highlighter-nav-mode' (thanks to Thomas Fini Hansen)
;;
;;;; Changes since v1.1:
;;
;; - Added `region-occurrences-highlighter-ignore-regex'
;;
;;;; Changes since v1.0:
;; - Bug fixes



;;; Code:

(require 'hi-lock)

(defvar region-occurrences-highlighter--previous-region nil)
;;(make-variable-buffer-local 'region-occurrences-highlighter--previous-region)

(defgroup region-occurrences-highlighter-group nil
  "Region occurrences highlighter."
  :group 'convenience)


(defface region-occurrences-highlighter-face
  '((t (:inverse-video t)))
  "Face for occurrences of current region.")

(defcustom region-occurrences-highlighter-case-fold-search t
  "Non-nil means highlightings will ignore case (see `case-fold-search')."
  :type 'boolean)

(defcustom region-occurrences-highlighter-max-buffer-size 999999
  "If the buffer size is bigger, don't perform highlighting due to performance reasons."
  :type 'integer)

(defcustom region-occurrences-highlighter-all-visible-buffers t
  "If non nil, region is highlighted in buffers of all visible windows."
  :type 'boolean)

(defcustom region-occurrences-highlighter-max-size 300
  "Maximum length of region of which highlight occurrences."
  :type 'integer)

(defcustom region-occurrences-highlighter-min-size 3
  "Minimum length of region to highlight occurrences."
  :type 'integer)

(defcustom region-occurrences-highlighter-ignore-regex "[[:space:]\n]+"
  "Ignore selection if matches this regex.  Set it to empty string to maintain compatibility with previous versions."
  :type 'string)

(defun region-occurrences-highlighter--ignore(str)
  "Check if STR matches the ignore regex."
  (or
   (not region-occurrences-highlighter-ignore-regex)
   (string=
    ""
    (replace-regexp-in-string region-occurrences-highlighter-ignore-regex "" str))))


(defun region-occurrences-highlighter--accept (begin end)
  "Accept to highlight occurrences if BEGIN and END are between limits, and the selection doesn't match ignore regex."
  (and
   (not (eq begin end))
   (>= (abs (- begin end)) region-occurrences-highlighter-min-size)
   (<= (abs (- begin end)) region-occurrences-highlighter-max-size)
   (let ((str (buffer-substring-no-properties begin end)))
     (not (region-occurrences-highlighter--ignore str)))))

;;;###autoload
(define-minor-mode region-occurrences-highlighter-mode
  "Highlight the current region and its occurrences, a la Visual Code."
  :group region-occurrences-highlighter-group

  (remove-hook 'post-command-hook #'region-occurrences-highlighter--change-hook t)
  (when region-occurrences-highlighter-mode
    (add-hook 'post-command-hook #'region-occurrences-highlighter--change-hook t)))

(defun region-occurrences-highlighter--turn-on-region-occurrences-highlighter-mode ()
  "Turn on the 'region-occurrences-highlighter-mode'."
  (region-occurrences-highlighter-mode 1))

;;;###autoload
(define-globalized-minor-mode global-region-occurrences-highlighter-mode
  region-occurrences-highlighter-mode region-occurrences-highlighter--turn-on-region-occurrences-highlighter-mode
  :require 'region-occurrences-highlighter)

(defun region-occurrences-highlighter--change-hook ()
  "Called each time the region is changed."

  ;;; REMOVE PREVIOUS HIGHLIGHTED REGION
  (when region-occurrences-highlighter--previous-region

    (region-occurrences-highlighter--update-buffers
     region-occurrences-highlighter--previous-region
     nil)
    
    (setq region-occurrences-highlighter--previous-region nil)
    (region-occurrences-highlighter-nav-mode -1))

  (when region-occurrences-highlighter-mode

    ;;; HIGHLIGHT THE CURRENT REGION
    (when (and (region-active-p)
               (not deactivate-mark))
      (let ((begin (region-beginning))
            (end (region-end)))
        (when (region-occurrences-highlighter--accept begin end)
          (let ((str (regexp-quote (buffer-substring-no-properties begin end))))

            (region-occurrences-highlighter--update-buffers
             region-occurrences-highlighter--previous-region
             str)
            
            (setq region-occurrences-highlighter--previous-region str)
            (region-occurrences-highlighter-nav-mode 1)))))))

(defun region-occurrences-highlighter--buffers-to-highlight ()
  "Return a list of the buffers where the highlighting will be performed, honoring `region-occurrences-highlighter-all-visible-buffers'."
  (if region-occurrences-highlighter-all-visible-buffers
      (let ((buffers nil)
            (current-frame (selected-frame)))
        (dolist (frame (frame-list))
          (with-selected-frame frame
            (walk-windows (lambda (window)
                            (let ((buffer (window-buffer window)))
                              (when (not (member buffer buffers))
                                (push buffer buffers)))))))
        (select-frame current-frame)
        buffers)
    (list (current-buffer))))

(defun region-occurrences-highlighter--update-buffers(previous-region current-region)
  "Update the highlightings in all buffers but the current buffer."
  (let* (
         (case-fold-search region-occurrences-highlighter-case-fold-search)
         (previous (if (and  previous-region case-fold-search) (downcase previous-region) previous-region))
         (current (if (and current-region case-fold-search) (downcase current-region) current-region)))
    (dolist (buffer (region-occurrences-highlighter--buffers-to-highlight))
      (with-current-buffer buffer
        (when previous
          (unhighlight-regexp previous))
        (when current
          (if (< (buffer-size) region-occurrences-highlighter-max-buffer-size)
              (highlight-regexp current 'region-occurrences-highlighter-face)
            (warn "Buffer too big for region-occurrences-highlighter: %s (see region-occurrences-highlighter-max-buffer-size)" buffer)))))))

(defvar region-occurrences-highlighter-nav-mode-map
  (make-sparse-keymap)
  "Keymap for `region-occurrences-highlighter-nav-mode-map'.")

(define-minor-mode region-occurrences-highlighter-nav-mode
  "Navigate the highlighted regions.

\\{region-occurrences-highlighter-nav-mode-map}")

(defun region-occurrences-highlighter-next ()
  "Jump to the next highlighted region."
  (interactive)
  (region-occurrences-highlighter--jump 1))



(defun region-occurrences-highlighter-prev ()
  "Jump to the previous highlighted region."
  (interactive)
  (region-occurrences-highlighter--jump -1))

(defun region-occurrences-highlighter-jump (dir)
  "The function `region-occurrences-highlighter-jump' was not private (--) in previous version."
  (region-occurrences-highlighter--jump dir))

(make-obsolete 'region-occurrences-highlighter-jump 'region-occurrences-highlighter--jump "Version 1.5")

(defun region-occurrences-highlighter--jump (dir)
  "Jump to the next or previous highlighted region.
DIR has to be 1 or -1."
  (if region-occurrences-highlighter--previous-region
      ;; If the point is before the mark when going forward or vice
      ;; versa, we need to exchange point and mark in order to not hit
      ;; the current region when searching.
      (let ((swap (if (< (point) (mark)) (eq dir 1) (eq dir -1)))
            (case-fold-search region-occurrences-highlighter-case-fold-search))
        (when swap
          (exchange-point-and-mark))
        (if (re-search-forward region-occurrences-highlighter--previous-region nil t dir)
            (progn
              (set-mark (point))
              (re-search-backward region-occurrences-highlighter--previous-region nil t dir)
              ;; Make sure that point and mark is in the same order as the
              ;; original selection.
              (when (not swap)
                (exchange-point-and-mark))
              (activate-mark))
          (message "No more highlights")
          ;; Undo the swap.
          (when swap
            (exchange-point-and-mark))))
    (error "No region highlighted")))

(provide 'region-occurrences-highlighter)
;;; region-occurrences-highlighter.el ends here
