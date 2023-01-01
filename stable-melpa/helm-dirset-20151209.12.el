;;; helm-dirset.el --- helm sources for multi directories
;; -*- Mode: Emacs-Lisp -*-

;; Copyright (C) 2014 by 101000code/101000LAB

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA

;; Version: 0.1.0
;; Package-Version: 20151209.12
;; Package-Commit: eb30810cd26e1ee73d84a863e6b2667700e9aead
;; Author: k1LoW (Kenichirou Oyama), <k1lowxb [at] gmail [dot] com> <k1low [at] 101000lab [dot] org>
;; Keywords: files, directories
;; URL: http://101000lab.org
;; Package-Requires: ((f "0.16.2") (helm "1.6.1") (s "1.9.0") (cl-lib "0.5"))

;;; Commentary:

;;; Code:

;;require
(require 'cl-lib)
(require 'f)
(require 's)
(require 'helm-config)

(defvar helm-dirset-default-action
  `(action
     ("Find File" . find-file))
  "Default action of helm-dirset-sources.")

(defun helm-dirset-sources (absolute-dir-list &optional recursive ignore actions)
  "Create 'Open ABSOLUTE-DIR-LIST' helm-sources.  If RECURSIVE is true, search files recursively.  IGNORE: file ignore regexp.  ACTIONS: custom helm actions."
  (let (sources)
    (unless (listp absolute-dir-list)
      (setq absolute-dir-list (list absolute-dir-list)))
    (unless actions
      (setq actions helm-dirset-default-action))
    (cl-loop for d in absolute-dir-list do
             (unless (not (f-dir? d))
               (push
                `((name . ,(concat "Open directory: " d))
                  (candidates . ,(cl-remove-if (lambda (x) (and ignore (s-matches? ignore x))) (helm-dirset-sources-directory-files d recursive)))
                  (display-to-real . (lambda (candidate)
                                       (f-join ,d candidate)))
                  ,actions)
                sources)))
    (reverse sources)))

(defun helm-dirset-sources-directory-files (dir &optional recursive)
  "Get DIR files.  If RECURSIVE = true, get DIR recuresively."
  (-map
   (lambda (file) (f-relative file dir))
   (f-files dir (lambda (file) (not (s-matches? "\\(\\.svn\\|\\.git\\)" (f-long file)))) recursive)))

(provide 'helm-dirset)

;;; end
;;; helm-dirset.el ends here
