;;; hl-sentence.el --- highlight a sentence based on customizable face

;; Copyright (c) 2011 Donald Ephraim Curtis

;; Author: Donald Ephraim Curtis <dcurtis@milkbox.net>
;; URL: http://github.com/milkypostman/hl-sentence
;; Package-Version: 20110815.1654
;; Package-Commit: f88882772f1a29fabb54194cc8aacd80d7f5b085
;; Version: 3
;; Keywords: highlighting

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.


;;; Code:

(setq hl-sentence-face (make-face 'hl-sentence-face))

(defun hl-sentence-begin-pos () (save-excursion (unless (= (point) (point-max)) (forward-char)) (backward-sentence) (point)))
(defun hl-sentence-end-pos () (save-excursion (unless (= (point) (point-max)) (forward-char)) (backward-sentence) (forward-sentence) (point)))

;; (setq hl-sentence-mode nil)

(defun hl-sentence-current (&rest ignore)
  "Highlight current sentence."
    (and hl-sentence-mode (> (buffer-size) 0)
    (progn
      (and  (boundp 'hl-sentence-extent)
        hl-sentence-extent
        (move-overlay hl-sentence-extent (hl-sentence-begin-pos) (hl-sentence-end-pos) (current-buffer)) ;;; XEmacs: use set-extent-endpoints instead of move-overlay
      )
)))

(setq hl-sentence-extent (make-overlay 0 0))
(overlay-put hl-sentence-extent 'face hl-sentence-face)

;;;###autoload
(define-minor-mode hl-sentence-mode
  "Enable highlighting of currentent sentence."
  :init-value nil
  (progn
    (if hl-sentence-mode
          (add-hook 'post-command-hook 'hl-sentence-current nil t)
      (move-overlay hl-sentence-extent 0 0 (current-buffer))
      (remove-hook 'post-command-hook 'hl-sentence-current t)))
  )


(provide 'hl-sentence)


;;; hl-sentence.el ends here
