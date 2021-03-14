;;; hgignore-mode.el --- a major mode for editing hgignore files -*- lexical-binding: t -*-

;;; Copyright (C) 2014-2015 Omair Majid

;; Author: Omair Majid <omair.majid@gmail.com>
;; URL: http://github.com/omajid/hgignore-mode
;; Package-Version: 20210314.431
;; Package-Commit: 2c5aa4c238848f5b4f2955afcfb5f21ea513653b
;; Keywords: convenience vc hg
;; Version: 0.1.20150329

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; A major mode for editing hgignore files.  Adds basic syntax
;; highlighting, commenting and completion support.

;;; Code:

(require 'newcomment)

(defconst hgignore--keywords
  (list
   (cons (regexp-opt '("syntax" "regexp" "glob") 'symbols)
         'font-lock-keyword-face))
  "Keywords recognized by font-lock for `hgignore-mode'.")

(defun hgignore--completion-at-point ()
  "`completion-at-point' support for hgignore-mode."
  (if (looking-back "^syntax: ?" nil)
      (hgignore--complete-syntax)
    (hgignore--complete-raw-path)))

(defun hgignore--complete-syntax ()
  "Complete the `syntax' parts of hgignore."
  (when (looking-back "^syntax: ?" nil)
    (list (line-beginning-position) (point)
          (list "syntax: regexp" "syntax: glob"))))

(defun hgignore--complete-raw-path ()
  "Complete paths, escaping according to the currently active syntax."
  (let* ((line-start (save-excursion
                       (beginning-of-line)
                       (point)))
         (completion-start (save-excursion
                             (condition-case nil
                                 (progn
                                   (end-of-line)
                                   (1+ (re-search-backward "/" line-start)))
                               (error line-start))))
         (root-path (file-name-directory (buffer-file-name)))
         (base-path (buffer-substring-no-properties line-start completion-start))
         (path (concat root-path base-path "/"))
         (how-to-quote (save-excursion
                         (condition-case nil
                             (progn
                               (re-search-backward "^syntax: \\(regexp\\|glob\\)$")
                               (if (string-equal (match-string 1) "regexp")
                                   #'regexp-quote
                                 #'identity))
                           (error #'regexp-quote)))))
    (list completion-start
          (point)
          (mapcar how-to-quote (directory-files path)))))

;; prog-mode was introduced in emacs 24.1
(defalias 'hgignore--parent-mode
  (if (fboundp 'prog-mode)
      'prog-mode
    'fundamental-mode))

;;;###autoload
(define-derived-mode hgignore-mode hgignore--parent-mode "hgignore"
  "Major mode for editing .hgignore files."
  ;; set up font-lock
  (setq font-lock-defaults (list hgignore--keywords))
  ;; syntax table
  (let (table hgignore-mode-syntax-table)
    (modify-syntax-entry ?\# "<" table)
    (modify-syntax-entry ?\n ">" table))
  ;; comment/uncomment correctly
  (setq comment-start "#")
  (setq comment-end "")
  ;; auto completion
  (add-hook 'completion-at-point-functions #'hgignore--completion-at-point nil t))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.hgignore\\'" . hgignore-mode))

(provide 'hgignore-mode)
;;; hgignore-mode.el ends here
