;;; literate-coffee-mode.el --- major-mode for Literate CoffeeScript -*- lexical-binding: t; -*-

;; Copyright (C) 2017 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-literate-coffee-mode
;; Package-Version: 20170211.1515
;; Package-Commit: 55ce0305495f4a38c8063c4bd63deb1e1252373d
;; Version: 0.04
;; Package-Requires: ((coffee-mode "0.5.0"))

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

;;; Code:

(require 'coffee-mode)

(defun litcoffee--font-lock-regexp (limit)
  (and (re-search-forward coffee-regexp-regexp limit t)
       (goto-char (match-end 0))
       (not (get-text-property (point) 'litcoffee-not-highlight))))

(defun litcoffee--font-lock-this (limit)
  (and (re-search-forward coffee-this-regexp limit t)
       (goto-char (match-end 0))
       (not (get-text-property (point) 'litcoffee-not-highlight))))

(defun litcoffee--font-lock-prototype (limit)
  (and (re-search-forward coffee-prototype-regexp limit t)
       (goto-char (match-end 0))
       (not (get-text-property (point) 'litcoffee-not-highlight))))

(defun litcoffee--font-lock-assign (limit)
  (and (re-search-forward coffee-assign-regexp limit t)
       (goto-char (match-end 0))
       (not (get-text-property (point) 'litcoffee-not-highlight))))

(defun litcoffee--font-lock-local-assign (limit)
  (and (re-search-forward coffee-local-assign-regexp limit t)
       (goto-char (match-end 1))
       (not (get-text-property (point) 'litcoffee-not-highlight))))

(defun litcoffee--font-lock-boolean (limit)
  (and (re-search-forward coffee-boolean-regexp limit t)
       (goto-char (match-end 0))
       (not (get-text-property (point) 'litcoffee-not-highlight))))

(defun litcoffee--font-lock-lambda (limit)
  (and (re-search-forward coffee-lambda-regexp limit t)
       (goto-char (match-end 1))
       (not (get-text-property (point) 'litcoffee-not-highlight))))

(defun litcoffee--font-lock-keywords (limit)
  (and (re-search-forward coffee-keywords-regexp limit t)
       (goto-char (match-end 1))
       (not (get-text-property (point) 'litcoffee-not-highlight))))

(defvar litcoffee--string-interpolation-regexp
  "#{[^}\n\\\\]*\\(?:\\\\.[^}\n\\\\]*\\)*}")

(defun litcoffee--font-lock-string-interpolation (limit)
  (and (re-search-forward litcoffee--string-interpolation-regexp limit t)
       (goto-char (match-end 0))
       (not (get-text-property (point) 'litcoffee-not-highlight))))

(defvar litcoffee-font-lock-keywords
  `((litcoffee--font-lock-regexp 0 font-lock-constant-face)
    (litcoffee--font-lock-this 0 font-lock-variable-name-face)
    (litcoffee--font-lock-prototype 0 font-lock-type-face)
    (litcoffee--font-lock-assign 0 font-lock-type-face)
    (litcoffee--font-lock-local-assign 1 font-lock-variable-name-face)
    (litcoffee--font-lock-boolean 0 font-lock-constant-face)
    (litcoffee--font-lock-lambda 1 font-lock-function-name-face)
    (litcoffee--font-lock-keywords 1 font-lock-keyword-face)
    (litcoffee--font-lock-string-interpolation 0 font-lock-variable-name-face t)))

(defun litcoffee--syntax-propertize-regexp-function (start end)
  (save-excursion
    (goto-char start)
    (when (re-search-forward "\\(?:[^\\]\\)\\(/\\)" end t)
      (let ((ppss (progn
                    (goto-char (match-beginning 1))
                    (syntax-ppss))))
        (when (nth 8 ppss)
          (put-text-property (match-beginning 1) (match-end 1)
                             'syntax-table (string-to-syntax "_")))))))

(defun litcoffee-syntax-propertize-function (start end)
  (goto-char start)
  (funcall
   (syntax-propertize-rules
    ("^\\(.\\{4\\}\\).*$"
     (0 (ignore
         (let ((head-of-line (match-string 1))
               (start (match-beginning 0))
               (end (match-end 0)))
           (if (string-match-p "\\`\\(\t\\| \\{4,\\}\\)" head-of-line)
               (litcoffee--syntax-propertize-regexp-function start end)
             (put-text-property start end 'litcoffee-not-highlight t)
             (save-excursion
               (goto-char start)
               (while (re-search-forward "['\"]" end t)
                 (put-text-property (match-beginning 0) (match-end 0)
                                    'syntax-table (string-to-syntax "_")))))))))
    (coffee-block-strings-delimiter
     (0 (ignore (coffee-syntax-block-strings-stringify))))
    ("^[[:space:]]\\{4,\\}*\\(###\\)\\([[:space:]]+.*\\)?$"
     (1 (ignore
         (let ((after-triple-hash (match-string-no-properties 2)))
           (when (or (not after-triple-hash)
                     (not (string-match-p "###\\'" after-triple-hash)))
             (put-text-property (match-beginning 1) (match-end 1)
                                'syntax-table (string-to-syntax "!"))))))))
   (point) end))

;;;###autoload
(define-derived-mode litcoffee-mode coffee-mode "LitCoffee"
  "Major mode for editing Literate CoffeeScript."
  (setq font-lock-defaults '((litcoffee-font-lock-keywords)))
  (set (make-local-variable 'syntax-propertize-function)
       'litcoffee-syntax-propertize-function))

(provide 'literate-coffee-mode)

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.litcoffee\\'" . litcoffee-mode))
;;;###autoload
(add-to-list 'auto-mode-alist '("\\.coffee.md\\'" . litcoffee-mode))

;;; literate-coffee-mode.el ends here
