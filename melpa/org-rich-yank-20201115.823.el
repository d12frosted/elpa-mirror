;;; org-rich-yank.el --- Paste with org-mode markup and link to source -*- lexical-binding: t -*-

;; Copyright (C) 2018-2020 Kevin Brubeck Unhammer

;; Author: Kevin Brubeck Unhammer <unhammer@fsfe.org>
;; Version: 0.2.1
;; Package-Version: 20201115.823
;; Package-Commit: 56d698c2614025538f456479c79073ef40399bc3
;; URL: https://github.com/unhammer/org-rich-yank
;; Package-Requires: ((emacs "24.4"))
;; Keywords: convenience, hypermedia, org

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;;; Do you often yank source code into your org files, manually
;;; surrounding it in #+BEGIN_SRC blocks? This package will give you a
;;; new way of pasting that automatically surrounds the snippet in
;;; blocks, marked with the major mode of where the code came from,
;;; and adds a link to the source file after the block.

;;; To use, require and bind whatever keys you prefer to the
;;; interactive functions:
;;;
;;; (require 'org-rich-yank)
;;; (eval-after-load 'org
;;;   '(define-key org-mode-map (kbd "C-M-y") #'org-rich-yank)))
;;;

;;; If you prefer `use-package', the above settings would be:
;;;
;;; (use-package org-rich-yank
;;;   :ensure t
;;;   :config
;;;   (eval-after-load 'org
;;;     '(define-key org-mode-map (kbd "C-M-y") #'org-rich-yank)))
;;;
;;; Note that we eagerly load `org-rich-yank', so we can capture yanks
;;; that happen before `org' is loaded.


;;; Code:

(defgroup org-rich-yank nil
  "Options for org-rich-yank"
  :tag "org-rich-yank"
  :group 'org)

(defcustom org-rich-yank-add-target-indent t
  "Give all lines of paste the same indentation as the first one.
If this variable is non-nil and point is indented before pasting,
all lines below will also get that indentation."
  :group 'org-rich-yank
  :type 'boolean)

(defvar org-rich-yank--buffer nil)

(defun org-rich-yank--store (&rest _args)
  "Store current buffer in `org-rich-yank--buffer'.
ARGS ignored."
  (setq org-rich-yank--buffer (current-buffer)))

;;;###autoload
(defun org-rich-yank-enable ()
  "Add the advices that store the buffer of the current kill."
  (advice-add #'kill-append :after #'org-rich-yank--store)
  (advice-add #'kill-new :after #'org-rich-yank--store))

;; Always do this on load – safe to run multiple times
(org-rich-yank-enable)

(defun org-rich-yank-disable ()
  "Remove the advices that store the buffer of the current kill."
  (advice-remove #'kill-append #'org-rich-yank--store)
  (advice-remove #'kill-new #'org-rich-yank--store))

(defun org-rich-yank--trim-nl (str)
  "Trim surrounding newlines from STR."
  (replace-regexp-in-string "\\`[\n\r]+\\|[\n\r]+\\'"
                            ""
                            str))

(declare-function diff-goto-source "diff-mode")
(declare-function gnus-article-show-summary "gnus-art")

(defun org-rich-yank--store-link ()
  "Store the link using `org-store-link' without erroring out."
  (with-demoted-errors
      (cond ((and (eq major-mode 'gnus-article-mode)
                  (fboundp #'gnus-article-show-summary))
             ;; Workaround for possible bug in org-gnus-store-link: If
             ;; you've moved point in the summary, org-store-link from
             ;; the article will give the wrong link
             (save-window-excursion (gnus-article-show-summary)
                                    (org-store-link nil)))
            ((and (eq major-mode 'diff-mode))
             (save-window-excursion
               (diff-goto-source)
               (org-store-link nil)))
            ;; org-store-link doesn't do eww-mode yet as of 8.2.10 at least:
            ((and (eq major-mode 'eww-mode)
                  (boundp 'eww-data)
                  (plist-get eww-data :url))
             (format "[[%s][%s]]"
                     (plist-get eww-data :url)
                     (or (plist-get eww-data :title)
                         (plist-get eww-data :url))))
            (t (org-store-link nil)))))

(defun org-rich-yank--link ()
  "Get an org-link to the current kill."
  (with-current-buffer org-rich-yank--buffer
    (let ((link (org-rich-yank--store-link)))
      ;; TODO: make it (file-relative-name … dir-of-org-file) if
      ;; they're in the same projectile-project
      (when link (concat link "\n")))))

(defun org-rich-yank-indent (paste)
  "Prepend current indentation to each line of PASTE."
  (let* ((s (buffer-substring (line-beginning-position) (point)))
         (indent (progn (string-match "\\s *$" s)
                        (match-string 0 s))))
    (replace-regexp-in-string "\n"
                              (concat "\n" indent)
                              paste)))

;;;###autoload
(defun org-rich-yank ()
  "Yank, surrounded by #+BEGIN_SRC block with major mode of originating buffer."
  (interactive)
  (if org-rich-yank--buffer
      (let* ((source-mode (buffer-local-value 'major-mode org-rich-yank--buffer))
             (paste
              (concat
               (format "#+BEGIN_SRC %s\n"
                       (replace-regexp-in-string "-mode$" "" (symbol-name source-mode)))
               (org-rich-yank--trim-nl (current-kill 0))
               (format "\n#+END_SRC\n")
               (org-rich-yank--link))))
        (insert
         (if org-rich-yank-add-target-indent
             (org-rich-yank-indent paste)
           paste)))
    (message "`org-rich-yank' doesn't know the source buffer – please `kill-ring-save' and try again.")))


(provide 'org-rich-yank)
;;; org-rich-yank.el ends here
