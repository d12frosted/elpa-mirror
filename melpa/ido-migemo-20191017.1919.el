;;; ido-migemo.el --- Migemo plug-in for Ido

;; Author: myuhe <yuhei.maeda_at_gmail.com>
;; URL: https://github.com/myuhe/ido-migemo.el
;; Package-Version: 20191017.1919
;; Package-Commit: 09a2cc175b500cab7655a25ffc982e78d46ca669
;; Version: 0.1
;; Maintainer: myuhe
;; Copyright (C) :2015 myuhe all rights reserved.
;; Created: :15-09-12
;; Package-Requires: ((migemo "1.9.1"))
;; Keywords: files

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING. If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 0:110-1301, USA.

;;; Commentary:
;;
;; Put the ido-migemo.el to your
;; load-path.
;; Add to .emacs:
;; (require 'ido-migemo)
;;
;; In detail, Read my introduced Article.
;; `http://sheephead.homelinux.org/2015/09/14/7329/'
;;
;;; Changelog:
;; 2015-09-12 Initial release.

;;; Code:

(require 'ido)
(require 'migemo)

;; Customization
(defgroup ido-migemo nil "migemo plug-in for Ido"
  :tag "ido migemo"
  :group 'migemo)

(defcustom ido-migemo-exclude-command-list '(smex)
  "List of commands that ido-migemo ignores. If non-nil, migemo ignores those commands."
  :group 'ido-migemo
  :type '(repeat  (function :tag "exclude command")))

(defcustom ido-migemo-prompt-string "[migemo] "
  "String to display in the Ido Migemo prompt."
  :group 'ido-migemo
  :type 'string)

(defvar ido-migemo-pattern-alist nil)
(defvar ido-migemo-pattern-alist-length 128)
(defvar ido-migemo-orig-set-matches-1 nil)
(defvar ido-migemo-orig-make-prompt nil)

(defvar ido-cur-item)
(defvar ido-process-ignore-lists)
(defvar ido-default-item)
(defvar ido-entry-buffer)
(defvar ido-migemo-this-command nil)

(defun ido-migemo-get-pattern (string)
  (let ((migemo-pattern-alist migemo-pattern-alist)
    (migemo-white-space-regexp " *")
    pattern)
    (let ((case-fold-search nil))
      (while (string-match "[^a-zA-Z]\\([a-z]+\\)" string)
    (setq string
          (replace-match (capitalize (match-string 1 string)) nil nil string 1))))
    (if (setq pattern (assoc string ido-migemo-pattern-alist))
    (prog1
        (cdr pattern)
      (setq ido-migemo-pattern-alist
        (cons pattern
              (delete pattern ido-migemo-pattern-alist))))
      (prog1
      (setq pattern (migemo-get-pattern string))
    (setq ido-migemo-pattern-alist
          (cons (cons string pattern) ido-migemo-pattern-alist))
    (when (> (length ido-migemo-pattern-alist)
         ido-migemo-pattern-alist-length)
      (setcdr
       (nthcdr (1- ido-migemo-pattern-alist-length) ido-migemo-pattern-alist)
       nil))))))

(defun ido-migemo-set-matches-1 (items &optional do-full)
  "Return list of matches in ITEMS."
  (when (eq ido-migemo-this-command nil)
    (setq ido-migemo-this-command  this-command))
  (if (not (memq ido-migemo-this-command
                 ido-migemo-exclude-command-list))
      (let* ((ido-enable-regexp nil)
             (case-fold-search   ido-case-fold)
             (slash (and (not ido-enable-prefix) (ido-final-slash ido-text)))
             (text (if slash (substring ido-text 0 -1) ido-text))
             (rex0 (if ido-enable-regexp text (regexp-quote text)))
             (rexq (concat rex0 (if slash ".*/" "")))
             (re (if ido-enable-prefix (concat "\\`" rexq) rexq))
             (full-re (and do-full
                           (not (and (eq ido-cur-item 'buffer)
                                     ido-buffer-disable-smart-matches))
                           (not ido-enable-regexp)
                           (not (string-match "\$\\'" rex0))
                           (concat "\\`" rex0 (if slash "/" "") "\\'")))
             (suffix-re (and do-full slash
                             (not (and (eq ido-cur-item 'buffer)
                                       ido-buffer-disable-smart-matches))
                             (not ido-enable-regexp)
                             (not (string-match "\$\\'" rex0))
                             (concat rex0 "/\\'")))
             (prefix-re (and full-re (not ido-enable-prefix)
                             (concat "\\`" rexq)))
             (non-prefix-dot (or (not ido-enable-dot-prefix)
                                 (not ido-process-ignore-lists)
                                 ido-enable-prefix
                                 (= (length ido-text) 0)))
             full-matches suffix-matches prefix-matches matches)
        (setq ido-incomplete-regexp nil)
        (condition-case error
            (mapc
             (lambda (item)
               (let ((name (ido-name item)))
                 (if (and (or non-prefix-dot
                              (if (= (aref ido-text 0) ?.)
                                  (= (aref name 0) ?.)
                                (/= (aref name 0) ?.)))
                          (string-match (ido-migemo-get-pattern re) name))
                     (cond
                      ((and (eq ido-cur-item 'buffer)
                            (or (not (stringp ido-default-item))
                                (not (string= name ido-default-item)))
                            (string= name (buffer-name ido-entry-buffer)))
                       (setq matches (cons item matches)))
                      ((and full-re (string-match full-re name))
                       (setq full-matches (cons item full-matches)))
                      ((and suffix-re (string-match suffix-re name))
                       (setq suffix-matches (cons item suffix-matches)))
                      ((and prefix-re (string-match prefix-re name))
                       (setq prefix-matches (cons item prefix-matches)))
                      (t (setq matches (cons item matches))))))
               t)
             items)
          (invalid-regexp
           (setq ido-incomplete-regexp t
                 ;; Consider the invalid regexp message internally as a
                 ;; special-case single match, and handle appropriately
                 ;; elsewhere.
                 matches (cdr error))))
        (when prefix-matches
          (ido-trace "prefix match" prefix-matches)
          ;; Bug#2042.
          (setq matches (nconc prefix-matches matches)))
        (when suffix-matches
          (ido-trace "suffix match" (list text suffix-re suffix-matches))
          (setq matches (nconc suffix-matches matches)))
        (when full-matches
          (ido-trace "full match" (list text full-re full-matches))
          (setq matches (nconc full-matches matches)))
        (when (and (null matches)
                   ido-enable-flex-matching
                   (> (length ido-text) 1)
                   (not ido-enable-regexp))
          (setq re (concat (regexp-quote (string (aref ido-text 0)))
                           (mapconcat (lambda (c)
                                        (concat "[^" (string c) "]*"
                                                (regexp-quote (string c))))
                                      (substring ido-text 1) "")))
          (if ido-enable-prefix
              (setq re (concat "\\`" re)))
          (mapc
           (lambda (item)
             (let ((name (ido-name item)))
               (if (string-match (ido-migemo-get-pattern re) name)
                   (setq matches (cons item matches)))))
           items))
        (delete-consecutive-dups matches t))
    (funcall ido-migemo-orig-set-matches-1 items do-full)))

(defun ido-migemo-cleanup-command ()
  (setq ido-migemo-this-command nil))

(defun turn-on-ido-migemo ()
  (when (eq nil ido-migemo-orig-set-matches-1)
    (setq ido-migemo-orig-set-matches-1 (symbol-function 'ido-set-matches-1)))
  (unless ido-mode (ido-mode 1))
  (fset 'ido-set-matches-1 'ido-migemo-set-matches-1)
  (ad-activate-regexp "prefix-ido-make-prompt")
  (add-hook 'ido-minibuffer-setup-hook 'ido-migemo-set-prompt)
  (add-hook 'minibuffer-exit-hook 'ido-migemo-cleanup-command))

(defun turn-off-ido-migemo ()
  (fset 'ido-set-matches-1 ido-migemo-orig-set-matches-1)
  (ad-deactivate-regexp "prefix-ido-make-prompt")
  (remove-hook 'ido-minibuffer-setup-hook 'ido-migemo-set-prompt)
  (remove-hook 'minibuffer-exit-hook 'ido-migemo-cleanup-command))

(defun ido-migemo-set-prompt ()
  (unless (memq this-command ido-migemo-exclude-command-list)
    (let ((inhibit-read-only t)
          (pos (point)))
      (put-text-property (point-min) (length ido-migemo-prompt-string) 'face 'success))))

(defadvice ido-make-prompt (after prefix-ido-make-prompt)
  "Add prompt to ido."
  (unless (memq this-command ido-migemo-exclude-command-list)
  (setq ad-return-value (concat ido-migemo-prompt-string ad-return-value ))))

;;;###autoload
(define-minor-mode ido-migemo-mode
  "`ido-migemo-mode' is minor mode for Japanese increment search using  `migemo'.
this command toggles the mode. Non-null prefix argument turns on the mode.
Null prefix argument turns off the mode."
  :global t
  (if ido-migemo-mode
      (turn-on-ido-migemo)
    (turn-off-ido-migemo)))

(provide 'ido-migemo)

;;; ido-migemo.el ends here
