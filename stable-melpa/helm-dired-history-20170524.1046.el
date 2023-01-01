;;; helm-dired-history.el --- Show dired history with helm.el support.

;; Author: Joseph(纪秀峰) <jixiuf@gmail.com>
;; Copyright (C) 2011,2012, Joseph(纪秀峰), all rights reserved.
;; Created: 2011-03-26
;; Version: 1.2
;; Package-Version: 20170524.1046
;; Package-Commit: 281523f9fc46cf00fafd670ba5cd16552a607212
;; X-URL:https://github.com/jixiuf/helm-dired-history
;; Keywords: helm, dired history
;; Package-Requires: ((helm "1.9.8")(cl-lib "0.5"))
;;
;; Features that might be required by this library:
;;
;; `helm' `dired'
;;
;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth
;; Floor, Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; Someone like to reuse the current dired buffer to visit
;; another directory, so that you just need open one dired
;; buffer. but the bad point is ,you can't  easily go
;; forward and back in different dired directory. this file
;; can remember dired directory you have visited and list them
;; using `helm.el'.

;; integrating dired history feature into commands like
;; dired-do-copy and dired-do-rename. What I think of is that when
;; user press C (copy) or R (rename) mode, it is excellent to have
;; an option allowing users to select a directory from the history
;; list.

;; after integrated the initial-input of `dired' `dired-other-window'
;; and `dired-other-frame' are changed from default-directory to empty,
;; and the first element of history is default-directory,so you can
;; just press `RET' or `C-j' to select it.



;;; Installation:

;; (require 'savehist)
;; (add-to-list 'savehist-additional-variables 'helm-dired-history-variable)
;; (savehist-mode 1)

;; (with-eval-after-load 'dired
;;   (require 'helm-dired-history)
;; ;; if you are using ido,you'd better disable ido for dired
;; ;; (define-key (cdr ido-minor-mode-map-entry) [remap dired] nil) ;in ido-setup-hook
;;   (define-key dired-mode-map "," 'dired))
;; or
;; (with-eval-after-load 'dired
;;   (require 'helm-dired-history)
;;   (define-key dired-mode-map "," 'dired))


;;; Code:

(require 'dired)
(require 'dired-aux)
(require 'helm-mode)
(require 'cl-lib)

(defgroup helm-dired-history nil
  "dired history for Helm."
  :group 'helm)


(defcustom helm-dired-history-max 200
  "length of history for helm-dired-history"
  :type 'number
  :group 'helm-dired-history)
(defvar helm-dired-history-variable nil)

(defvar helm-dired-history-cleanup-p nil)


(defun helm-dired-history--update(dir)
  "update variable `helm-dired-history-variable'."
  (unless helm-dired-history-cleanup-p
    (setq helm-dired-history-cleanup-p t)
    (let ((tmp-history ))
      (dolist (d helm-dired-history-variable)
        (when (or (file-remote-p d) (file-directory-p d))
          (add-to-list 'tmp-history d t)))
      (setq helm-dired-history-variable tmp-history)))
  (setq helm-dired-history-variable
        (delete-dups (delete dir helm-dired-history-variable)))
  (setq helm-dired-history-variable
        (append (list dir) helm-dired-history-variable))
  (helm-dired-history-trim))

(defun helm-dired-history-update()
  "update variable `helm-dired-history-variable'."
  (helm-dired-history--update (dired-current-directory)))

;;when you open dired buffer ,update `helm-dired-history-variable'.
(add-hook 'dired-after-readin-hook 'helm-dired-history-update)

(defun helm-dired-history-trim ()
  "Retain only the first `helm-dired-history-max' items in VALUE."
  (if (> (length helm-dired-history-variable) helm-dired-history-max)
      (setcdr (nthcdr (1- helm-dired-history-max) helm-dired-history-variable) nil)))


;; integrating dired history feature into commands like
;; dired-do-copy and dired-do-rename.
;;see https://github.com/jixiuf/helm-dired-history/issues/6
(defadvice dired-mark-read-file-name(around helm-dired-history activate)
  (cl-letf (((symbol-function 'read-file-name)
             #'helm-dired-history-read-file-name))
    ad-do-it))

(defadvice dired-read-dir-and-switches(around helm-dired-history activate)
  (helm-dired-history--update (expand-file-name default-directory))
  (let ((default-directory default-directory))
    (unless (next-read-file-uses-dialog-p) (setq default-directory ""))
    (cl-letf (((symbol-function 'read-file-name)
               #'helm-dired-history-read-file-name))
      ad-do-it)))

(defadvice dired-do-compress-to(around helm-dired-history activate)
  (cl-letf (((symbol-function 'read-file-name)
             #'helm-dired-history-read-file-name))
    ad-do-it))

(defun helm-dired-history-read-file-name
    (prompt &optional dir default-filename mustmatch initial predicate)
  (let ((helm-mode-reverse-history nil))
    (if dir
        (helm-read-file-name prompt
                             :name dir
                             :initial-input dir
                             :history helm-dired-history-variable)
      (helm-read-file-name prompt
                           :history helm-dired-history-variable))))


(provide 'helm-dired-history)
;;; helm-dired-history.el ends here.
