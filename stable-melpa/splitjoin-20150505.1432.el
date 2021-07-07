;;; splitjoin.el ---  Transition between multiline and single-line code

;; Copyright (C) 2015 by Syohei YOSHIDA

;; Author: Syohei YOSHIDA <syohex@gmail.com>
;; URL: https://github.com/syohex/emacs-splitjoin
;; Package-Version: 20150505.1432
;; Package-Commit: e2945ee269e6e90f0243d6f2a33e067bb0a2873c
;; Version: 0.01
;; Package-Requires: ((cl-lib "0.5"))

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

;; splitjoin.el is Emacs port of splitjoin.vim(https://github.com/AndrewRadev/splitjoin.vim).
;; splitjoin provides command which translates between multiline and single
;; line code, for example translation between block condition and postfix
;; condition in ruby-mode.

;;; Code:

(require 'cl-lib)

;; Suppress byte-compile warnings
(declare-function ruby-beginning-of-block "ruby-mode")
(declare-function ruby-end-of-block "ruby-mode")
(declare-function coffee-indent-line "coffee-mode")

(defconst splitjoin--supported-modes
  '(ruby-mode coffee-mode))

(defsubst splitjoin--in-string-or-comment-p ()
  (nth 8 (syntax-ppss)))

(defsubst splitjoin--current-line ()
  (buffer-substring-no-properties (line-beginning-position) (line-end-position)))

(defun splitjoin--block-condition-ruby-p ()
  (let ((curline (line-number-at-pos))
        beginning-line end-line)
    (back-to-indentation)
    (unless (looking-at "\\(?:if\\|unless\\|while\\|until\\)\\s-*")
      (ruby-beginning-of-block))
    (when (looking-at "\\(?:if\\|unless\\|while\\|until\\)\\s-*\\(.+\\)\\s-*$")
      (setq beginning-line (line-number-at-pos))
      (ruby-end-of-block)
      (when (looking-at-p "\\(end\\|}\\)\\>")
        (setq end-line (line-number-at-pos))
        (if (not (and (<= beginning-line curline) (<= curline end-line)))
            (error "Here is not condition block")
          (if (<= (- end-line beginning-line) 2)
              t
            (prog1 nil
              (message "This block is more than 2 lines."))))))))

(defun splitjoin--block-condition-coffee-p ()
  (goto-char (line-beginning-position))
  (back-to-indentation)
  (let ((block-start-re "\\=\\(?:if\\|unless\\|while\\|until\\|for\\)\\s-*.+$")
        curindent)
    (unless (looking-at-p block-start-re)
      (setq curindent (current-indentation))
      (forward-line -1)
      (back-to-indentation))
    (let ((block-indent (current-indentation)))
      (when (and (looking-at-p block-start-re)
                 (or (not curindent) (< block-indent curindent)))
        (let ((lines 0)
              finish)
          (while (not finish)
            (forward-line 1)
            (let ((indent (current-indentation))
                  (line (splitjoin--current-line)))
              (when (and (< block-indent indent)
                         (not (string-match-p "\\`\\s-*\\'" line)))
                (cl-incf lines))
              (when (or (eobp) (>= block-indent (current-indentation)))
                (setq finish t))))
          (= lines 1))))))

(defun splitjoin--block-condition-p (mode)
  (save-excursion
    (cl-case mode
      (ruby-mode (splitjoin--block-condition-ruby-p))
      (coffee-mode (splitjoin--block-condition-coffee-p)))))

(defun splitjoin--postfix-condition-ruby-p ()
  (save-excursion
    (back-to-indentation)
    (unless (looking-at-p "\\=\\(?:if\\|unless\\|while\\|until\\)")
      (goto-char (line-end-position))
      (looking-back "\\(?:if\\|unless\\|while\\|until\\)\\s-+\\(.+\\)\\s-*\\=" nil))))

(defun splitjoin--postfix-condition-coffee-p ()
  (save-excursion
    (back-to-indentation)
    (unless (looking-at-p "\\=\\(?:if\\|unless\\|while\\|until\\|for\\)")
      (goto-char (line-end-position))
      (looking-back "\\(?:if\\|unless\\|while\\|until\\|for\\)\\s-+\\(.+\\)\\s-*\\=" nil))))

(defun splitjoin--postfix-condition-p (mode)
  (cl-case mode
    (ruby-mode (splitjoin--postfix-condition-ruby-p))
    (coffee-mode (splitjoin--postfix-condition-coffee-p))))

(defun splitjoin--beginning-of-block-p (mode)
  (cl-case mode
    (ruby-mode (looking-at-p "\\=\\(?:if\\|unless\\|while\\|until\\)\\b"))
    (coffee-mode (looking-at-p "\\=\\(?:if\\|unless\\|while\\|until\\|for\\)\\b"))))

(defun splitjoin--beginning-of-block (mode)
  (cl-case mode
    (ruby-mode (ruby-beginning-of-block))
    (coffee-mode
     (forward-line -1)
     (back-to-indentation))))

(defun splitjoin--retrieve-block-condition-common (mode)
  (save-excursion
    (back-to-indentation)
    (unless (splitjoin--beginning-of-block-p mode)
      (splitjoin--beginning-of-block mode))
    ;; TODO condition has multiple lines
    (let ((cond-start (point)))
      (goto-char (line-end-position))
      (skip-chars-backward " \t")
      (buffer-substring-no-properties cond-start (point)))))

(defun splitjoin--retrieve-block-condition (mode)
  (cl-case mode
    ((ruby-mode coffee-mode) (splitjoin--retrieve-block-condition-common mode))))

(defun splitjoin--end-of-block (mode)
  (cl-case mode
    (ruby-mode (ruby-end-of-block))))

(defun splitjoin--indent-postfix (mode &optional indent)
  (cl-case mode
    (ruby-mode (indent-for-tab-command))
    (coffee-mode (indent-to indent))))

(defun splitjoin--to-postfix-condition-common (mode condition)
  (save-excursion
    (let (start end body start-indent)
      (back-to-indentation)
      (unless (splitjoin--beginning-of-block-p mode)
        (splitjoin--beginning-of-block mode))
      (setq start (point) start-indent (current-indentation))
      (forward-line 1)
      (back-to-indentation)
      (let ((body-start (point)))
        (goto-char (line-end-position))
        (delete-horizontal-space)
        (setq body (buffer-substring-no-properties body-start (point))))
      (splitjoin--end-of-block mode)
      (skip-chars-forward "^ \t\r\n")
      (setq end (point))
      (delete-region start end)
      (insert body " " condition)
      (splitjoin--indent-postfix mode start-indent))))

(defun splitjoin--to-postfix-condition (mode)
  (let ((condition (splitjoin--retrieve-block-condition mode)))
    (cl-case mode
      ((ruby-mode coffee-mode)
       (splitjoin--to-postfix-condition-common mode condition)))))

(defsubst splitjoin--opening-block (close-type)
  (cl-case close-type
    (brace "{") ;; XXX Fix when perl is supported
    (otherwise "")))

(defsubst splitjoin--closing-block (close-type)
  (cl-case close-type
    (brace "}")
    (end "end")))

(defun splitjoin--indent-block (mode start end &optional block-indent)
  (cl-case mode
    (ruby-mode
     (indent-region start end))
    (coffee-mode
     (goto-char start)
     (indent-to block-indent)
     (goto-char end)
     (back-to-indentation)
     (indent-to block-indent)
     (coffee-indent-line))))

(defsubst splitjoin--postfix-condition-regexp (mode)
  (cl-case mode
    (ruby-mode
     "\\=\\(.+\\)\\s-+\\(\\(?:if\\|unless\\|while\\|until\\)\\s-*.+\\)\\s-*$")
    (coffee-mode
     "\\=\\(.+\\)\\s-+\\(\\(?:if\\|unless\\|while\\|until\\|for\\)\\s-*.+\\)\\s-*$")))

(defun splitjoin--to-block-condition-common (mode close-type)
  (save-excursion
    (goto-char (line-beginning-position))
    (back-to-indentation)
    (let ((start (point))
          (end (line-end-position))
          (curindent (current-indentation))
          (regexp (splitjoin--postfix-condition-regexp mode)))
      (if (not (re-search-forward regexp end t))
          (error "Error: Cannot get condition expression.")
        (let ((body (match-string-no-properties 1))
              (condition (match-string-no-properties 2))
              (opening-block (splitjoin--opening-block close-type))
              (closing-block (splitjoin--closing-block close-type))
              block-start)
          (delete-region start end)
          (setq block-start (point))
          (insert condition opening-block "\n" body)
          (when closing-block
            (insert (concat "\n" closing-block)))
          (splitjoin--indent-block mode block-start (point) curindent))))))

(defun splitjoin--to-block-condition (mode)
  (cl-case mode
    (ruby-mode (splitjoin--to-block-condition-common mode 'end))
    (coffee-mode (splitjoin--to-block-condition-common mode nil))))

;;;###autoload
(defun splitjoin ()
  (interactive)
  (unless (memq major-mode splitjoin--supported-modes)
    (error "Error: '%s' is not supported" major-mode))
  (if (splitjoin--postfix-condition-p major-mode)
      (splitjoin--to-block-condition major-mode)
    (if (splitjoin--block-condition-p major-mode)
        (splitjoin--to-postfix-condition major-mode)
      (error "Here is neither postfix condition nor block condition"))))

(provide 'splitjoin)

;;; splitjoin.el ends here
