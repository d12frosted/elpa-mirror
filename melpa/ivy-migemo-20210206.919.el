;;; ivy-migemo.el --- Use migemo on ivy              -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  ROCKTAKEY

;; Author: ROCKTAKEY <rocktakey@gmail.com>
;; Keywords: matching
;; Package-Version: 20210206.919
;; Package-Commit: 9cdf3823b3303d69c0c77dfee91136817da12aea

;; Version: 1.1.4
;; Package-Requires: ((emacs "24.3") (ivy "0.13.0") (migemo "1.9.2"))

;; URL: https://github.com/ROCKTAKEY/ivy-migemo
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;;; Use migemo on ivy.
;;; How to Use?
;;
;;     ;; Toggle migemo and fuzzy by command.
;;     (define-key ivy-minibuffer-map (kbd "M-f")
;;     (define-key ivy-minibuffer-map (kbd "M-m")
;;
;;     ;; If you want to defaultly use migemo on swiper and counsel-find-file:
;;     (setq ivy-re-builders-alist '((t . ivy--regex-plus)
;;                                   (swiper . ivy-migemo--regex-plus)
;;                                   (counsel-find-file . ivy-migemo--regex-plus))
;;                                   ;(counsel-other-function . ivy-migemo--regex-plus)
;;                                   )
;;     ;; Or you prefer fuzzy match like ido:
;;     (setq ivy-re-builders-alist '((t . ivy--regex-plus)
;;                                   (swiper . ivy-migemo--regex-fuzzy)
;;                                   (counsel-find-file . ivy-migemo--regex-fuzzy))
;;                                   ;(counsel-other-function . ivy-migemo--regex-fuzzy)
;;                                   )
;;
;;; Functions
;;;; ~ivy-migemo-toggle-fuzzy~
;;    Toggle fuzzy match or not on ivy.  Almost same as ~ivy-toggle-fuzzy~, except
;;    this function can also be used to toggle between ~ivy-migemo--regex-fuzzy~ and
;;    ~ivy-migemo--regex-plus~.
;;;; ~ivy-migemo-toggle-migemo~
;;    Toggle using migemo or not on ivy.
;;; License
;;   This package is licensed by GPLv3.



;;; Code:

(require 'ivy)
(require 'migemo)

(defgroup ivy-migemo ()
  "Group for ivy-migemo."
  :group 'ivy
  :prefix "ivy-migemo-")

(declare-function swiper--re-builder "ext:swiper")

(defvar ivy-migemo--regex-hash (make-hash-table :test #'equal)
  "Store pre-computed regex.")

(defun ivy-migemo--get-pattern (word)
  "Same as `migemo-get-pattern' except \"\\(\" is replaced to \"\\(:?\".

WORD"
  (let* ((str (migemo-get-pattern word))
         (len (length str))
         (result nil)
         (escape? nil)
         c)
    (dotimes (i len)
      (setq c (aref str i))
      (push
       (if escape?
           (if (eq c ?\()
               "(?:"
             (char-to-string c))
         (char-to-string c))
       result)
      (setq escape? (and (eq ?\\ c) (not escape?))))
    (apply #'concat (nreverse result))))

(defun ivy-migemo--regex (str &optional greedy)
  "Same as `ivy--regex' except using migemo.
Make regex sequence from STR (greedily if GREEDY is non-nil).
Each string made by splitting STR with space can match Japanese."
  (let ((hashed (unless greedy
                  (gethash str ivy-migemo--regex-hash))))
    (if hashed
        (progn
          (setq ivy--subexps (car hashed))
          (cdr hashed))
      (when (string-match-p "\\(?:[^\\]\\|^\\)\\\\\\'" str)
        (setq str (substring str 0 -1)))
      (setq str (ivy--trim-trailing-re str))
      (cdr (puthash str
                    (let ((subs (ivy--split str)))
                      (if (= (length subs) 1)
                          (cons
                           (setq ivy--subexps 0)
                           (if (string-match-p "\\`\\.[^.]" (car subs))
                               (concat "\\." (substring (car subs) 1))
                             (ivy-migemo--get-pattern (car subs))))
                        (cons
                         (setq ivy--subexps (length subs))
                         (replace-regexp-in-string
                          "\\.\\*\\??\\\\( "
                          "\\( "
                          (mapconcat
                           (lambda (x)
                             (if (string-match-p "\\`\\\\([^?][^\0]*\\\\)\\'" x)
                                 x
                               (format "\\(%s\\)"
                                       (ivy-migemo--get-pattern x))))
                           subs
                           (if greedy ".*" ".*?"))
                          nil t))))
                    ivy-migemo--regex-hash)))))

(defun ivy-migemo--regex-plus (str)
  "Same as `ivy--regex-plus' except using migemo.
Make regex sequence from STR.
Each string made by splitting STR with space or `!' can match Japanese."
  (let ((parts (ivy--split-negation str)))
    (cl-case (length parts)
      (0
       "")
      (1
       (if (= (aref str 0) ?!)
           (list (cons "" t)
                 (list (ivy-migemo--regex (car parts))))
         (ivy-migemo--regex (car parts))))
      (2
       (cons
        (cons (ivy-migemo--regex (car parts)) t)
        (mapcar #'(lambda (arg)
                    (list (ivy-migemo--get-pattern arg)))
                  (split-string (cadr parts) " " t))))
      (t (error "Unexpected: use only one !")))))

(defun ivy-migemo--regex-fuzzy (str)
  "Same as `ivy--regex-fuzzy' except using migemo.
Make regex sequence from STR.
STR can match Japanese word (but not fuzzy match)."
  (setq str (ivy--trim-trailing-re str))
  (if (string-match "\\`\\(\\^?\\)\\(.*?\\)\\(\\$?\\)\\'" str)
      (prog1
          (concat (match-string 1 str)
                  (let ((lst (string-to-list (match-string 2 str))))
                    (apply
                     #'concat
                     `("\\("
                       ,@(cl-mapcar
                          #'concat
                          (cons "" (cdr (mapcar (lambda (c) (format "[^%c\n]*" c))
                                                lst)))
                          (mapcar (lambda (x) (format "\\(%s\\)" (regexp-quote (char-to-string x))))
                                  lst))
                       "\\)\\|"
                       ,(ivy-migemo--get-pattern (match-string 2 str)))))
                  (match-string 3 str))
        (setq ivy--subexps (length (match-string 2 str))))
    str))

(defun ivy-migemo--swiper-re-builder-with (str re-builder)
  "Apply `swiper--re-builder' forced to use RE-BUILDER with STR as argument."
  (let ((ivy-re-builders-alist `((t . ,re-builder))))
    (swiper--re-builder str)))

(defun ivy-migemo--swiper-re-builder-migemo-regex-plus (str)
  "Apply `swiper--re-builder' forced to use `ivy-migemo--regex-plus' with STR as argument."
  (ivy-migemo--swiper-re-builder-with str #'ivy-migemo--regex-plus))

(defun ivy-migemo--swiper-re-builder-migemo-regex-fuzzy (str)
  "Apply `swiper--re-builder' forced to use `ivy-migemo--regex-fuzzy' with STR as argument."
  (ivy-migemo--swiper-re-builder-with str #'ivy-migemo--regex-fuzzy))

(defun ivy-migemo--swiper-re-builder-no-migemo-regex-plus (str)
  "Apply `swiper--re-builder' forced to use `ivy--regex-plus' with STR as argument."
  (ivy-migemo--swiper-re-builder-with str #'ivy--regex-plus))

(defun ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy (str)
  "Apply `swiper--re-builder' forced to use `ivy--regex-fuzzy' with STR as argument."
  (ivy-migemo--swiper-re-builder-with str #'ivy--regex-fuzzy))

;;;###autoload
(defun ivy-migemo-toggle-fuzzy ()
  "Toggle the re builder to match fuzzy or not."
  (interactive)
  (setq ivy--old-re nil)
  (setq
   ivy--regex-function
   (pcase ivy--regex-function
     (`ivy--regex-fuzzy        #'ivy--regex-plus)
     (`ivy--regex-plus         #'ivy--regex-fuzzy)
     (`ivy-migemo--regex-fuzzy #'ivy-migemo--regex-plus)
     (`ivy-migemo--regex-plus  #'ivy-migemo--regex-fuzzy)
     (`swiper--re-builder
      (pcase (ivy-alist-setting ivy-re-builders-alist)
        (`ivy--regex-fuzzy        #'ivy-migemo--swiper-re-builder-no-migemo-regex-plus)
        (`ivy--regex-plus         #'ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy)
        (`ivy-migemo--regex-fuzzy #'ivy-migemo--swiper-re-builder-migemo-regex-plus)
        (`ivy-migemo--regex-plus  #'ivy-migemo--swiper-re-builder-migemo-regex-fuzzy)))
     (`ivy-migemo--swiper-re-builder-no-migemo-regex-plus  #'ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy)
     (`ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy #'ivy-migemo--swiper-re-builder-no-migemo-regex-plus)
     (`ivy-migemo--swiper-re-builder-migemo-regex-plus     #'ivy-migemo--swiper-re-builder-migemo-regex-fuzzy)
     (`ivy-migemo--swiper-re-builder-migemo-regex-fuzzy    #'ivy-migemo--swiper-re-builder-migemo-regex-plus))))

;;;###autoload
(defun ivy-migemo-toggle-migemo ()
  "Toggle the re builder to use/unuse migemo."
  (interactive)
  (setq ivy--old-re nil)
  (setq
   ivy--regex-function
   (pcase ivy--regex-function
     (`ivy--regex-fuzzy        #'ivy-migemo--regex-fuzzy)
     (`ivy--regex-plus         #'ivy-migemo--regex-plus)
     (`ivy-migemo--regex-fuzzy #'ivy--regex-fuzzy)
     (`ivy-migemo--regex-plus  #'ivy--regex-plus)
     (`swiper--re-builder
      (pcase (ivy-alist-setting ivy-re-builders-alist)
        (`ivy--regex-fuzzy        #'ivy-migemo--swiper-re-builder-migemo-regex-fuzzy)
        (`ivy--regex-plus         #'ivy-migemo--swiper-re-builder-migemo-regex-plus)
        (`ivy-migemo--regex-fuzzy #'ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy)
        (`ivy-migemo--regex-plus  #'ivy-migemo--swiper-re-builder-no-migemo-regex-plus)))
     (`ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy #'ivy-migemo--swiper-re-builder-migemo-regex-fuzzy)
      (`ivy-migemo--swiper-re-builder-no-migemo-regex-plus  #'ivy-migemo--swiper-re-builder-migemo-regex-plus)
      (`ivy-migemo--swiper-re-builder-migemo-regex-fuzzy    #'ivy-migemo--swiper-re-builder-no-migemo-regex-plus)
      (`ivy-migemo--swiper-re-builder-migemo-regex-plus     #'ivy-migemo--swiper-re-builder-no-migemo-regex-plus))))

(provide 'ivy-migemo)
;;; ivy-migemo.el ends here
