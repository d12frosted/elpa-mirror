;;; nerd-icons-completion.el --- Add icons to completion candidates -*- lexical-binding: t; -*-

;; Copyright (C) 2023 Hongyu Ding <rainstormstudio@yahoo.com>

;; Author: Hongyu Ding <rainstormstudio@yahoo.com>
;; Keywords: lisp
;; Package-Version: 20230430.1611
;; Package-Commit: 5cfee6ff1b9647c783bae944402d60440ce04cbb
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1") (nerd-icons "0.0.1"))
;; URL: https://github.com/rainstormstudio/nerd-icons-completion
;; Keywords: convenient, files, icons

;; This program is free software: you can redistribute it and/or modify
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

;; Add nerd-icons to completion candidates.
;; nerd-icons-completion is inspired by
;; `all-the-icons-completion': https://github.com/iyefrat/all-the-icons-completion

;;; Code:

(require 'nerd-icons)

(defgroup nerd-icons-completion nil
  "Add icons to completion candidates."
  :group 'appearance
  :group 'convenience
  :prefix "nerd-icons-completion")

(defface nerd-icons-completion-dir-face
  '((t nil))
  "Face for the directory icon."
  :group 'nerd-icons-faces)

(cl-defgeneric nerd-icons-completion-get-icon (_cand _cat)
  "Return the icon for the candidate CAND of completion category CAT."
  "")

(cl-defmethod nerd-icons-completion-get-icon (cand (_cat (eql file)))
  "Return the icon for the candidate CAND of completion category file."
  (cond ((string-match-p "\\/$" cand)
         (concat
          (nerd-icons-icon-for-dir cand :face 'nerd-icons-completion-dir-face)
          " "))
        (t (concat (nerd-icons-icon-for-file cand) " "))))

(cl-defmethod nerd-icons-completion-get-icon (cand (_cat (eql project-file)))
  "Return the icon for the candidate CAND of completion category project-file."
  (nerd-icons-completion-get-icon cand 'file))

(cl-defmethod nerd-icons-completion-get-icon (cand (_cat (eql buffer)))
  "Return the icon for the candidate CAND of completion category buffer."
  (let* ((mode (buffer-local-value 'major-mode (get-buffer cand)))
         (icon (nerd-icons-icon-for-mode mode))
         (parent-icon (nerd-icons-icon-for-mode
                       (get mode 'derived-mode-parent))))
    (concat
     (if (symbolp icon)
         (if (symbolp parent-icon)
             (nerd-icons-faicon "nf-fa-sticky_note_o")
           parent-icon)
       icon)
     " ")))

(autoload 'bookmark-get-filename "bookmark")
(cl-defmethod nerd-icons-completion-get-icon (cand (_cat (eql bookmark)))
  "Return the icon for the candidate CAND of completion category bookmark."
  (if-let (fname (bookmark-get-filename cand))
      (nerd-icons-completion-get-icon fname 'file)
    (concat (nerd-icons-octicon "nf-oct-bookmark" :face 'nerd-icons-completion-dir-face) " ")))

(defun nerd-icons-completion-completion-metadata-get (orig metadata prop)
  "Meant as :around advice for `completion-metadata-get', Add icons as prefix.
ORIG should be `completion-metadata-get'
METADATA is the metadata.
PROP is the property which is looked up."
  (if (eq prop 'affixation-function)
      (let ((cat (funcall orig metadata 'category))
            (aff (or (funcall orig metadata 'affixation-function)
                     (when-let ((ann (funcall orig metadata 'annotation-function)))
                       (lambda (cands)
                         (mapcar (lambda (x) (list x "" (funcall ann x))) cands))))))
        (cond
         ((and (eq cat 'multi-category) aff)
          (lambda (cands)
            (mapcar (lambda (x)
                      (pcase-exhaustive x
                        (`(,cand ,prefix ,suffix)
                         (let ((orig (get-text-property 0 'multi-category cand)))
                           (list cand
                                 (concat (nerd-icons-completion-get-icon (cdr orig) (car orig))
                                         prefix)
                                 suffix)))))
                    (funcall aff cands))))
         ((and cat aff)
          (lambda (cands)
            (mapcar (lambda (x)
                      (pcase-exhaustive x
                        (`(,cand ,prefix ,suffix)
                         (list cand
                               (concat (nerd-icons-completion-get-icon cand cat)
                                       prefix)
                               suffix))))
                    (funcall aff cands))))
         ((eq cat 'multi-category)
          (lambda (cands)
            (mapcar (lambda (x)
                      (let ((orig (get-text-property 0 'multi-category x)))
                        (list x (nerd-icons-completion-get-icon (cdr orig) (car orig)) "")))
                    cands)))
         (cat
          (lambda (cands)
            (mapcar (lambda (x)
                      (list x (nerd-icons-completion-get-icon x cat) ""))
                    cands)))
         (aff)))
    (funcall orig metadata prop)))

;; For the byte compiler
(defvar marginalia-mode)
;;;###autoload
(defun nerd-icons-completion-marginalia-setup ()
  "Hook to `marginalia-mode-hook' to bind `nerd-icons-completion-mode' to it."
  (nerd-icons-completion-mode (if marginalia-mode 1 -1)))

;;;###autoload
(define-minor-mode nerd-icons-completion-mode
  "Add icons to completion candidates."
  :global t
  (if nerd-icons-completion-mode
      (advice-add #'completion-metadata-get :around #'nerd-icons-completion-completion-metadata-get)
    (advice-remove #'completion-metadata-get #'nerd-icons-completion-completion-metadata-get)))

(provide 'nerd-icons-completion)
;;; nerd-icons-completion.el ends here
