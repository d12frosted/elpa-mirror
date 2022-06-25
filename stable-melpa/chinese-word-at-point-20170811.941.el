;;; chinese-word-at-point.el --- Add `chinese-word' thing to `thing-at-point'

;; Copyright © 2015 Chunyang Xu

;; Author: Chunyang Xu <xuchunyang56@gmail.com>
;; URL: https://github.com/xuchunyang/chinese-word-at-point.el
;; Package-Version: 20170811.941
;; Package-Commit: 8223d7439e005555b86995a005b225ae042f0538
;; Package-Requires: ((cl-lib "0.5"))
;; Version: 0.2.3
;; Created: 9 Jan 2015
;; Keywords: convenience, Chinese

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides two additional `chinese-word' and `chinese-or-other-word'
;; things to `thing-at-point' function.

;; Using:
;;
;; 1. Use (thing-at-point 'chinese-word) to get Chinese word at point
;; 2. Use (thing-at-point 'chinese-or-other-word) to get any possible word
;; (including Chinese) at point
;;
;; You can also use (chinese-word-at-point) and (chinese-or-other-word-at-point)
;; if you prefer.
;;
;; 3. use (chinese-word-chinese-string-p string) to test whether a string consists
;; of pure Chinese characters.

;;; Code:

(require 'cl-lib)
(require 'thingatpt)

(defvar chinese-word-split-command
  "echo %s | python -m jieba -q -d ' '"
  "Set command for Chinese text segmentation.

The result should separated by one space.

I know two Chinese word segmentation tools, which have command line
interface, are jieba (结巴中文分词) and scws, both of them are hosting
on Github.")

(defun chinese-word--split-by-space (chinese-string)
  "Split CHINESE-STRING by one space.
Return Chinese words as a string separated by one space"
  (shell-command-to-string
   (format chinese-word-split-command chinese-string)))

(defun chinese-word-chinese-string-p (string)
  "Return t if STRING is a Chinese string."
  (if (string-match (format "\\cC\\{%s\\}" (length string)) string)
      t
    nil))
(define-obsolete-function-alias
  'chinese-word-cjk-string-p 'chinese-word-chinese-string-p "0.2.2")

(defun chinese-word-at-point-bounds ()
  "Return the bounds of the (most likely) Chinese word at point."
  (save-excursion
    (let ((current-word (thing-at-point 'word)))
      (when (and current-word (chinese-word-chinese-string-p current-word))
        (let* ((boundary (bounds-of-thing-at-point 'word))
               (beginning-pos (car boundary))
               (end-pos (cdr boundary))
               (current-pos (point))
               (index beginning-pos)
               (old-index beginning-pos))
          (cl-dolist (word (split-string (chinese-word--split-by-space
                                          current-word)))
            (cl-incf index (length word))
            (if (and (>= current-pos old-index)
                     (< current-pos index))
                (cl-return (cons old-index index))
              (if (= index end-pos)       ; When point is just behind word
                  (cl-return (cons old-index index)))
              (setq old-index index))))))))

(put 'chinese-word 'bounds-of-thing-at-point 'chinese-word-at-point-bounds)

(defun chinese-or-other-word-at-point-bounds ()
  "Return the bounds of the Chinese or other language word at point.

Here's \"other\" means any language words that Emacs can understand,
i.e. (thing-at-point 'word) can get proper word."
  (save-excursion
    (let ((current-word (thing-at-point 'word)))
      (if (and current-word (chinese-word-chinese-string-p current-word))
          (chinese-word-at-point-bounds)
        (bounds-of-thing-at-point 'word)))))

(put 'chinese-or-other-word 'bounds-of-thing-at-point
     'chinese-or-other-word-at-point-bounds)

;;;###autoload
(defun chinese-word-at-point ()
  "Return the (most likely) Chinese word at point, or nil if none is found."
  (thing-at-point 'chinese-word))

;;;###autoload
(defun chinese-or-other-word-at-point ()
  "Return the Chinese or other language word at point, or nil if none is found.

Here's \"other\" denotes any language words that Emacs can understand,
i.e. (thing-at-point 'word) can get proper word."
  (thing-at-point 'chinese-or-other-word))

(provide 'chinese-word-at-point)

;; Local Variables:
;; coding: utf-8
;; End:

;;; chinese-word-at-point.el ends here
