;;; helm-migemo.el --- Migemo plug-in for helm -*- lexical-binding: t -*-

;; Copyright (C) 2007-2012 rubikitch
;; Copyright (C) 2015 Yuhei Maeda <yuhei.maeda_at_gmail.com>
;; Author: rubikitch <rubikitch@ruby-lang.org>
;; Maintainer: Yuhei Maeda <yuhei.maeda_at_gmail.com>
;; Version: 1.22
;; Package-Version: 20151010.356
;; Package-Commit: 66c6a19d07c6a385daefd2090d0709d26b608b4e
;; Package-Requires: ((emacs "24.4") (helm-core "1.7.8") (migemo "1.9") (cl-lib "0.5"))
;; Created: 2009-04-13
;; Keywords: matching, convenience, tools, i18n
;; URL: https://github.com/emacs-jp/helm-migemo

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Migemo extension of `helm'. Use `helm-migemo' instead of
;; `helm'. If `helm-migemo' is invoked with prefix argument,
;; `helm' is migemo-ized. This means that pattern matching of
;; `helm' candidates is done by migemo-expanded `helm-pattern'.

;;; Commands:
;;
;; Below are complete command list:
;;
;;  `helm-migemo'
;;    `helm' with migemo extension.
;;
;;; Customizable Options:
;;
;; Below are customizable option list:
;;

;; If you want to use migemo search source-locally, add (migemo) to
;; the source. It sets match and search attribute appropriately for
;; migemo.

;;; Setting:

;; (require 'helm-migemo)
;; (define-key global-map [(control ?:)] 'helm-migemo)

;;; Bug:

;; Simultaneous use of (candidates-in-buffer), (search
;; . migemo-forward) and (delayed) scrambles *helm* buffer. Maybe
;; because of collision of `migemo-process' and `run-with-idle-timer'

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'migemo nil t)

(defvar helm-use-migemo nil
  "[Internal] If non-nil, `helm' is migemo-ized.")

;;;###autoload
(defun helm-migemo (with-migemo &rest helm-args)
  "`helm' with migemo extension.
With prefix arugument, `helm-pattern' is migemo-ized, otherwise normal `helm'."
  (interactive "P")
  (let ((helm-use-migemo with-migemo))
    (apply 'helm helm-args)))

(defvar helm-previous-migemo-info '("" . "")
  "[Internal] Previous migemo query for helm-migemo.")
(cl-defun helm-string-match-with-migemo (str &optional (pattern helm-pattern))
  "Migemo version of `string-match'."
  (unless (string= pattern (car helm-previous-migemo-info))
    (setq helm-previous-migemo-info (cons pattern (migemo-get-pattern pattern))))
  (string-match (cdr helm-previous-migemo-info) str))

  (cl-defun helm-mp-3migemo-match (str &optional (pattern helm-pattern))
    (cl-loop for (pred . re) in (helm-mm-3-get-patterns pattern)
             always (funcall pred (helm-string-match-with-migemo str re))))
  (defun helm-mp-3migemo-search (pattern &rest _ignore)
    (helm-mm-3-search-base pattern 'migemo-forward 'migemo-forward))
  (defun helm-mp-3migemo-search-backward (pattern &rest _ignore)
    (helm-mm-3-search-base pattern 'migemo-backward 'migemo-backward))
;; (helm-string-match-with-migemo "日本語入力" "nihongo")
;; (helm-string-match-with-migemo "日本語入力" "nyuuryoku")
;; (helm-mp-3migemo-match "日本語入力" "nihongo nyuuryoku")
(defun helm-compile-source--migemo (source)
  (if (not (featurep 'migemo))
      source
    (let* ((match-identity-p
            (or (assoc 'candidates-in-buffer source)
                (equal '(identity) (assoc-default 'match source))))

           (matcher 'helm-mp-3migemo-match)
           (searcher (if (assoc 'search-from-end source)

                           'helm-mp-3migemo-search-backward
                         'helm-mp-3migemo-search)))
      (cond (helm-use-migemo
             `((delayed)
               (search ,@(assoc-default 'search source) ,searcher)
               ,(if match-identity-p
                    '(match identity)
                  `(match ,matcher
                          ,@(assoc-default 'match source)))
               ,@source))
            ((assoc 'migemo source)
             `((search ,searcher)
               ,(if match-identity-p
                    '(match identity)
                  `(match ,matcher))
               ,@source))
            (t source)))))
(add-to-list 'helm-compile-source-functions 'helm-compile-source--migemo t)

(defvar helm-migemize-command-idle-delay 0.1
  "`helm-idle-delay' for migemized command.")
(defmacro helm-migemize-command (command)
  "Use migemo in COMMAND when selectiong candidate by `helm'.
Bind `helm-use-migemo' = t in COMMAND.
`helm-migemize-command-idle-delay' is used instead of  `helm-idle-delay'."
  `(defadvice ,command (around helm-use-migemo activate)
     (let ((helm-use-migemo t)
           (helm-idle-delay helm-migemize-command-idle-delay))
       ad-do-it)))

(with-eval-after-load "helm-migemo"
  ;; redefinition
  (defun helm-compile-source--candidates-in-buffer (source)
    (helm-aif (assoc 'candidates-in-buffer source)
        (append source
                `((candidates
                   . ,(or (cdr it)
                          (lambda ()
                            ;; Do not use `source' because other plugins
                            ;; (such as helm-migemo) may change it
                            (helm-candidates-in-buffer (helm-get-current-source)))))
                  (volatile) (match identity)))
      source)))

(provide 'helm-migemo)

;; How to save (DO NOT REMOVE!!)
;; (progn (magit-push) (emacswiki-post "helm-migemo.el"))
;;; helm-migemo.el ends here
