;;; find-by-pinyin-dired.el --- Find file by first PinYin character of Chinese Hanzi

;; Copyright (C) 2015 Chen Bin

;; Author: Chen Bin <chenbin.sh@gmail.com>
;; URL: http://github.com/redguardtoo/find-by-pinyin-dired
;; Package-Version: 20180210.218
;; Package-Commit: 3b4781148dddc84a701ad76c0934ed991ecd59d5
;; Package-Requires: ((pinyinlib "0.1.0"))
;; Keywords: Hanzi Chinese dired find file pinyin
;; Version: 0.0.3

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
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

;;; Commentary:

;; Place this file somewhere (say ~/.emacs/lisp), add below code into your .emacs:
;; (add-to-list 'load-path "~/.emacs.d/lisp/")
;; (require 'find-by-pinyin-dired)
;;
;; Then `M-x find-by-pinyin-dired' or `M-x find-by-pinyin-in-project-dired'.
;;
;;   - If `find-by-pinyin-no-punc-p' is `t': English punctuation is converted to
;;     Chinese punctuation.

;;   - If `find-by-pinyin-traditional-p' is `t': traditional Chinese characters are used
;;     instead of simplified Chinese characters.

;;   - If `find-by-pinyin-only-chinese-p' is `t': the resulting regular expression doesn't
;;     contain the English letter.

;;; Code:

(require 'find-lisp)
(require 'pinyinlib)

(defvar find-by-pinyin-project-root nil
  "The project root directory used by `find-by-pinyin-in-project-dired'.")

(defvar find-by-pinyin-no-punc-p nil
  "not convert English punctuation to Chinese punctuation.")

(defvar find-by-pinyin-traditional-p nil
  "Traditional Chinese characters instead of simplified Chinese characters are used.")

(defvar find-by-pinyin-only-chinese-p nil
  "Don't search the English letters.")

(defun find-by-pinyin-create-regexp (str)
  (pinyinlib-build-regexp-string str
                                 find-by-pinyin-no-punc-p
                                 find-by-pinyin-traditional-p
                                 find-by-pinyin-only-chinese-p))

;;;###autoload
(defun find-by-pinyin-dired (dir pattern)
  "Search DIR recursively for files/directories matching the PATTERN.
Then run Dired on those files.
PATTERN is sequence of first character of PinYin of each Chinese character.
Space in PATTERN match a number of any Chinese characters.
For example, pattern 'hh tt' find file '好好学习天天向上.txt'."
  (interactive
   "DSearch directory: \nsFile name (first characters of Hanzi Pinyin): ")
  (let* ((pys (split-string pattern "[ \t]+"))
         (regexp (format ".*%s.*"
                         (mapconcat 'find-by-pinyin-create-regexp pys ".*"))))
    ;; find-lisp-find-dired is a lisp version
    (find-lisp-find-dired dir regexp)))

;;;###autoload
(defun find-by-pinyin-in-project-dired (pattern)
  "Simlar to `find-by-pinyin-dired' while search directory automatically detected.
The directory is detected by `ffip-project-root' if `find-file-in-project' installed."
  (interactive "sFile name (first characters of Hanzi Pinyin): ")
  (let* ((dir (or find-by-pinyin-project-root
                  (if (fboundp 'ffip-project-root) (ffip-project-root)))))
    (if dir (find-by-pinyin-dired dir pattern))))

(provide 'find-by-pinyin-dired)
;;; find-by-pinyin-dired.el ends here
