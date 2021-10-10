;;; all-the-icons-completion.el --- Add icons to completion candidates -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2021 Itai Y. Efrat
;;
;; Author: Itai Y. Efrat <https://github.com/iyefrat>
;; Maintainer: Itai Y. Efrat <itai3397@gmail.com>
;; Created: June 06, 2021
;; Modified: June 06, 2021
;; Version: 0.0.1
;; Package-Version: 20211009.2207
;; Package-Commit: a0f34d68cc12330ab3992a7521f9caa1de3b8470
;; Keywords: convenient, lisp
;; Homepage: https://github.com/iyefrat/all-the-icons-completion
;; Package-Requires: ((emacs "26.1") (all-the-icons "5.0"))
;;
;; This file is not part of GNU Emacs.
;;
;; Licence:
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;;  Add icons to completion candidates.
;;
;;; Code:

(require 'all-the-icons)

(defgroup all-the-icons-completion nil
  "Add icons to completion candidates."
  :version "26.1"
  :group 'appearance
  :group 'convenience
  :prefix "all-the-icons-completion")

(defun all-the-icons-completion-get-icon (cand cat)
  "Return the icon for the candidate CAND of completion category CAT."
  (cl-case cat
    (file (all-the-icons-completion-get-file-icon cand))
    (project-file (all-the-icons-completion-get-file-icon cand))
    (buffer (all-the-icons-completion-get-buffer-icon cand))
    (t "")))

(defun all-the-icons-completion-get-file-icon (cand)
  "Return the icon for the candidate CAND of completion category file."
  (cond ((string-match-p "\\/$" cand) (concat (all-the-icons-icon-for-dir cand) " "))
        (t (concat (all-the-icons-icon-for-file cand) " "))))

(defun all-the-icons-completion-get-buffer-icon (cand)
  "Return the icon for the candidate CAND of completion category buffer."
  (let* ((mode (buffer-local-value 'major-mode (get-buffer cand)))
         (icon (all-the-icons-icon-for-mode mode))
         (parent-icon (all-the-icons-icon-for-mode
                       (get mode 'derived-mode-parent))))
    (concat
     (if (symbolp icon)
         (if (symbolp parent-icon)
             (all-the-icons-faicon "sticky-note-o")
           parent-icon)
       icon)
     " ")))

(defun all-the-icons-completion-completion-metadata-get (orig metadata prop)
  "Meant as :around advice for `completion-metadata-get', Add icons as prefix.
ORIG should be `completion-metadata-get'
METADATA is the metadata.
PROP is the property which is looked up."
  (if (eq prop 'affixation-function)
      (let ((cat (funcall orig metadata 'category))
            (aff (funcall orig metadata 'affixation-function)))
        (cond
         ((and (eq cat 'consult-multi) aff)
          (lambda (cands)
            (mapcar (lambda (x)
                      (pcase-exhaustive x
                        (`(,cand ,prefix ,suffix)
                         (let ((orig (get-text-property 0 'consult-multi cand)))
                           (list cand
                                 (concat (all-the-icons-completion-get-icon (cdr orig) (car orig))
                                         prefix)
                                 suffix)))))
                    (funcall aff cands))))
         ((and cat aff)
          (lambda (cands)
            (mapcar (lambda (x)
                      (pcase-exhaustive x
                        (`(,cand ,prefix ,suffix)
                         (let ((orig (get-text-property 0 'consult-multi cand)))
                           (list cand
                                 (concat (all-the-icons-completion-get-icon cand cat)
                                         prefix)
                                 suffix)))))
                    (funcall aff cands))))
         ((eq cat 'consult-multi)
          (lambda (cands)
            (mapcar (lambda (x)
                      (let ((orig (get-text-property 0 'consult-multi x)))
                        (list x (all-the-icons-completion-get-icon (cdr orig) (car orig)) "")))
                    cands)))
         (cat
          (lambda (cands)
            (mapcar (lambda (x)
                      (list x (all-the-icons-completion-get-icon x cat) ""))
                    cands)))
         (aff)))
    (funcall orig metadata prop)))

;; For the byte compiler
(defvar marginalia-mode)
;;;###autoload
(defun all-the-icons-completion-marginalia-setup ()
  "Hook to `marginalia-mode-hook' to bind `all-the-icons-completion-mode' to it."
  (all-the-icons-completion-mode (if marginalia-mode 1 -1)))

;;;###autoload
(define-minor-mode all-the-icons-completion-mode
  "Add icons to completion candidates."
  :global t
  (if all-the-icons-completion-mode
      (advice-add #'completion-metadata-get :around #'all-the-icons-completion-completion-metadata-get)
    (advice-remove #'completion-metadata-get #'all-the-icons-completion-completion-metadata-get)))

(provide 'all-the-icons-completion)
;;; all-the-icons-completion.el ends here
