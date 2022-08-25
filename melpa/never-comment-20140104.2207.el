;;; never-comment.el --- Never blocks are comment

;; Author: Scott Frazer
;; Maintainer: Toon Claes
;; Version: 1.0
;; Package-Version: 20140104.2207
;; Package-Commit: 1996d003cad6bccf1475f7845d79efacbc7cd673
;; URL: http://stackoverflow.com/a/4554658/89376

;; This file is not currently part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program ; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; Often C programmers type blocks of code between =#if 0= and =#endif=.
;; This code will never be compiler. Therefore some IDE's display this code
;; as comment. With this module, emacs will also do this.

;;; Usage:

;; Just put this file in your emacs load-path and type (require 'never-comment)
;; somewhere in your .emacs init file.

;;; Disclaimer:

;; Original code from Scott Frazer on stackoverflow.com:
;; http://stackoverflow.com/a/4554658/89376

;;; Code:

(declare-function c-put-font-lock-face "cc-fonts")

(defface never-comment-face
  '((t :inherit font-lock-comment-face
       :foreground "grey55"))
  "Face for never commented text."
  :group 'never-comment-faces)

(defun never-comment--c-mode-font-lock (limit)
  "Function that will find #if 0 blocks."
  (save-restriction
    (widen)
    (save-excursion
      (goto-char (point-min))
      (let ((depth 0) str start start-depth)
        (while (re-search-forward "^\\s-*#\\s-*\\(if\\|else\\|endif\\)" limit 'move)
          (setq str (match-string 1))
          (if (string= str "if")
              (progn
                (setq depth (1+ depth))
                (when (and (null start) (looking-at "\\s-+0"))
                  (setq start (match-end 0)
                        start-depth depth)))
            (when (and start (= depth start-depth))
              (c-put-font-lock-face start (match-beginning 0) 'never-comment-face)
              (setq start nil))
            (when (string= str "endif")
              (setq depth (1- depth)))))
        (when (and start (> depth 0))
          (c-put-font-lock-face start (point) 'never-comment-face)))))
  nil)

;;;###autoload
(defun never-comment--c-mode-common-hook ()
  "Hook to show #if 0 blocks as comment."
  (font-lock-add-keywords
   nil
   '((never-comment--c-mode-font-lock (0 never-comment-face prepend))) 'add-to-end))

;;;###autoload
(defun never-comment-init ()
  "Initialize the never-comment hooks"
  (interactive)
  (add-hook 'c-initialization-hook 
            (lambda ()
              (if (require 'never-comment nil t)
                  (add-hook 'c-mode-common-hook 'never-comment--c-mode-common-hook)))))

(provide 'never-comment)
;;; never-comment.el ends here
