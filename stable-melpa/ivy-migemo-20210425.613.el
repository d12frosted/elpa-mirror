;;; ivy-migemo.el --- Use migemo on ivy              -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  ROCKTAKEY

;; Author: ROCKTAKEY <rocktakey@gmail.com>
;; Keywords: matching
;; Package-Version: 20210425.613
;; Package-Commit: a2ce15abe6a30fae63ed457ab25a80455704f28e

;; Version: 1.4.2
;; Package-Requires: ((emacs "24.3") (ivy "0.13.0") (migemo "1.9.2") (nadvice "0.3"))

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

(require 'cl-lib)
(require 'ivy)
(require 'migemo)

(defgroup ivy-migemo ()
  "Group for ivy-migemo."
  :group 'ivy
  :prefix "ivy-migemo-")

(declare-function swiper--re-builder "ext:swiper")
(declare-function swiper--normalize-regex "ext:swiper")
(declare-function ivy-prescient-re-builder "ext:ivy-prescient")
(defvar prescient-filter-alist)

(defvar ivy-migemo--regex-hash (make-hash-table :test #'equal)
  "Store pre-computed regex.")

(defcustom ivy-migemo-to-migemo-hook nil
  "Hook run when `ivy-migemo' is toggled to migemo."
  :group 'ivy-migemo
  :type 'hook)

(defcustom ivy-migemo-from-migemo-hook nil
  "Hook run when `ivy-migemo' is toggled to ummigemo."
  :group 'ivy-migemo
  :type 'hook)

(defcustom ivy-migemo-toggle-migemo-functions nil
  "Hook run when `ivy-migemo' is toggled.
Each function is called with 1 arg TO-MIGEMO, which is non-nil when `ivy-migemo'
is toggled to migemo."
  :group 'ivy-migemo
  :type 'hook)

(defun ivy-migemo--run-toggle-migemo-hook (to-migemo)
  "Run some hooks about `ivy-migemo'.
If TO-MIGEMO is non-nil, run `ivy-migemo-to-migemo-hook'.  Otherwise, run
`ivy-migemo-from-migemo-hook'.
 In addition, run hook `ivy-migemo-toggle-migemo-functions' with arg TO-MIGEMO,
which is boolean that is non-nil when `ivy' is toggled to migemo."
  (run-hook-with-args 'ivy-migemo-toggle-migemo-functions to-migemo)
  (run-hooks
   (if to-migemo
       'ivy-migemo-to-migemo-hook
     'ivy-migemo-from-migemo-hook)))

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

;; (defun ivy-migemo--prescient-regexp (query &rest _)
;;   "Similar to `prescient-literal-regexp'.
;; Actually, just eval `ivy-migemo--get-pattern' with QUERY."
;;   (ivy-migemo--get-pattern query))

;; FIXME: Too slow to use on some functions such as `counsel-find-file'.
;; Even the error "(invalid-regexp \"Regular expression too big\")" happens.
;; (defun ivy-migemo--prescient-re-builder (query)
;;   "Similar to `ivy-prescient-re-builder'.
;; Use `ivy-migemo--get-pattern' instead of functions of `prescient-filter-alist'.
;; QUERY is passed to `ivy-migemo--get-pattern'."
;;   (let ((prescient-filter-alist
;;          (mapcar
;;           (lambda (arg)
;;             (cons (car arg) #'ivy-migemo--prescient-regexp))
;;           prescient-filter-alist)))
;;     (ivy-prescient-re-builder query)))

(defalias 'ivy-migemo--prescient-re-builder 'ivy-migemo--regex-plus)

(defvar ivy-migemo--regex-function-fuzzy-alist
  '((ivy--regex-plus . ivy--regex-fuzzy)
    (ivy-migemo--regex-plus . ivy-migemo--regex-fuzzy)
    (ivy-migemo--swiper-re-builder-no-migemo-regex-plus . ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy)
    (ivy-migemo--swiper-re-builder-migemo-regex-plus . ivy-migemo--swiper-re-builder-migemo-regex-fuzzy))
  "Alist whose element is (unfuzzy-function . fuzzy-function).")

(defvar ivy-migemo--swiper-regex-function-fuzzy-alist
  '((ivy--regex-fuzzy . ivy-migemo--swiper-re-builder-no-migemo-regex-plus)
    (ivy--regex-plus . ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy)
    (ivy-migemo--regex-fuzzy . ivy-migemo--swiper-re-builder-migemo-regex-plus)
    (ivy-migemo--regex-plus . ivy-migemo--swiper-re-builder-migemo-regex-fuzzy))
  "Alist whose element is (from-function . to-function).
This variable is used only on `swiper'.
This is needed because `ivy' is specialized for `swiper'.")

(defun ivy-migemo--toggle-fuzzy-get (re-func &optional caller)
  "Get toggled function for RE-FUNC.
If CALLER is omitted, (`ivy-state-caller' `ivy-last') is used.
This function uses `ivy-migemo--regex-function-alist' and
`ivy-migemo--swiper-regex-function-alist'."
  (let (f)
    (cond
     ((setq f (cdr (assq re-func ivy-migemo--regex-function-fuzzy-alist)))
      f)
     ((setq f (car (rassq re-func ivy-migemo--regex-function-fuzzy-alist)))
      f)
     ((and (eq re-func 'swiper--re-builder)
           (setq f (cdr (assq (ivy-alist-setting ivy-re-builders-alist
                                                 (or caller
                                                     (ivy-state-caller ivy-last)))
                              ivy-migemo--swiper-regex-function-fuzzy-alist))))
      f)
     (t re-func))))

;;;###autoload
(defun ivy-migemo-toggle-fuzzy ()
  "Toggle the re builder to match fuzzy or not."
  (interactive)
  (setq ivy--old-re nil)
  (setq ivy--regex-function (ivy-migemo--toggle-fuzzy-get ivy--regex-function)))

(defvar ivy-migemo--regex-function-alist
  '(
    ;; Native
    (ivy--regex-fuzzy . ivy-migemo--regex-fuzzy)
    (ivy--regex-plus . ivy-migemo--regex-plus)
    (ivy-prescient-re-builder . ivy-migemo--prescient-re-builder)
    ;; Defined by ivy-migemo
    (ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy . ivy-migemo--swiper-re-builder-migemo-regex-fuzzy)
    (ivy-migemo--swiper-re-builder-no-migemo-regex-plus . ivy-migemo--swiper-re-builder-migemo-regex-plus))
  "Alist whose element is (ummigemo-function . migemo-function).")

(defvar ivy-migemo--swiper-regex-function-alist
  '((ivy--regex-fuzzy        . ivy-migemo--swiper-re-builder-migemo-regex-fuzzy)
    (ivy--regex-plus         . ivy-migemo--swiper-re-builder-migemo-regex-plus)
    (ivy-migemo--regex-fuzzy . ivy-migemo--swiper-re-builder-no-migemo-regex-fuzzy)
    (ivy-migemo--regex-plus  . ivy-migemo--swiper-re-builder-no-migemo-regex-plus))
  "Alist whose element is (from-function . to-function).
This variable is used only on `swiper'.
This is needed because `ivy' is specialized for `swiper'.")

(defvar ivy-migemo--migemo-function-list
  '(ivy-migemo--regex
    ivy-migemo--regex-fuzzy
    ivy-migemo--regex-plus
    ivy-migemo--swiper-re-builder-migemo-regex-fuzzy
    ivy-migemo--swiper-re-builder-migemo-regex-plus)
  "List of functions which are migemo-ized.")

(defun ivy-migemo--toggle-migemo-get (re-func &optional caller)
  "Get toggled function for RE-FUNC.
If CALLER is omitted, (`ivy-state-caller' `ivy-last') is used.
This function uses `ivy-migemo--regex-function-alist' and
`ivy-migemo--swiper-regex-function-alist'."
  (let (f)
     (cond
      ((setq f (cdr (assq re-func ivy-migemo--regex-function-alist)))
       f)
      ((setq f (car (rassq re-func ivy-migemo--regex-function-alist)))
       f)
      ((and (eq re-func 'swiper--re-builder)
            (setq f (cdr (assq (ivy-alist-setting ivy-re-builders-alist
                                                  (or caller
                                                      (ivy-state-caller ivy-last)))
                               ivy-migemo--swiper-regex-function-alist))))
       f)
      (t re-func))))

;;;###autoload
(defun ivy-migemo-toggle-migemo ()
  "Toggle the re builder to use/unuse migemo."
  (interactive)
  (setq ivy--old-re nil)

  (let ((old ivy--regex-function))
    (setq ivy--regex-function (ivy-migemo--toggle-migemo-get ivy--regex-function))
    (unless (eq old ivy--regex-function)
      (ivy-migemo--run-toggle-migemo-hook
       (memq ivy--regex-function ivy-migemo--migemo-function-list)))))


;; For `search-default-mode' handling

(defun ivy-migemo--search-default-handling-mode-swiper-re-builder (original &rest args)
  "Advice `swiper--re-builder' to handle `search-default-mode'.
`search-default-mode' is handled when `ivy-migemo' is turned on.
ORIGINAL and ARGS are for :around advice."
  (let* ((re-builder (ivy-alist-setting ivy-re-builders-alist))
         (search-default-mode
          (unless (memq re-builder ivy-migemo--migemo-function-list)
            search-default-mode)))
    (apply original args)))

;;;###autoload
(define-minor-mode ivy-migemo-search-default-handling-mode
  "When turned on, override functions which use `swiper--re-builder'
to handle `search-default-mode' when `ivy-migemo'is turned on."
  nil
  ""
  nil
  :group 'ivy-migemo
  :global t
  (if ivy-migemo-search-default-handling-mode
      (advice-add 'swiper--re-builder
                  :around #'ivy-migemo--search-default-handling-mode-swiper-re-builder)
    (advice-remove 'swiper--re-builder
                   #'ivy-migemo--search-default-handling-mode-swiper-re-builder)))

;;;###autoload
(define-obsolete-function-alias 'global-ivy-migemo-search-default-handling-mode
  'ivy-migemo-search-default-handling-mode
  "1.3.4")

(provide 'ivy-migemo)
;;; ivy-migemo.el ends here
