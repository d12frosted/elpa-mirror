;;; plur.el --- Easily search and replace multiple variants of a word  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Chunyang Xu

;; Author: Chunyang Xu <xuchunyang.me@gmail.com>
;; URL: https://github.com/xuchunyang/plur
;; Package-Version: 20160504.924
;; Package-Commit: 5bdd3b9a2f0624414bd596e798644713cd1545f0
;; Version: 0.1
;; Package-Requires: ((emacs "24.4"))

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
;; * Plur

;; This package introduces a new syntax =...{subexp1,subexp2,...}...= to search and
;; replace a group of words.  Three commands are provided by this package:
;;
;; - ~plur-isearch-forward~
;; - ~plur-query-replace~
;; - ~plur-replace~
;;
;; ** Replace example
;;
;; To replace "mouse" with "cat" and "mice" with "cats" using:
;;
;; #+BEGIN_SRC undefined
;; M-x plur-query-replace RET m{ouse,ice} RET cat{,s} RET
;; #+END_SRC
;;
;; For more examples,
;;
;; - Facility to Building
;;
;; facilit{y,ies}  building{,s}
;;
;; - Mouse to Trackpad
;;
;; m{ouse,ice}  trackpad{,s}
;;
;; - Swap Emacs and Vim
;;
;; {emacs,vim}  {vim,emacs}
;;
;; ** Search example
;;
;; To search "mouse" and "mice" using:
;;
;; #+BEGIN_SRC undefined
;; M-x plur-isearch-forward RET m{ouse,ice}
;; #+END_SRC
;;
;; ** Requirements
;;
;; - Emacs 24.4 or higher
;;
;; ** Installation
;;
;; *** MELPA
;;
;; Plur is available from [[https://melpa.org][Melpa]]. You can install it using:
;;
;; #+BEGIN_SRC undefined
;; M-x package-install RET plur RET
;; #+END_SRC
;;
;; *** Manually
;;
;; Make sure plur.el is saved in a directory in you ~load-path~ and load it. Add something
;; like
;;
;; #+BEGIN_SRC emacs-lisp
;; (add-to-list 'load-path "path/to/plur/")
;; (require 'plur)
;; #+END_SRC
;;
;; to your init file.
;;
;; ** Acknowledge
;;
;; This package is inspired by [[https://github.com/tpope/vim-abolish][vim-abolish]].

;;; Code:

(require 'cl-lib)

(defun plur-split-string (s)
  ;; "m{ice,ouse}" => ("m" ("ice,ouse"))
  (let ((start 0) strings)
    (while (string-match "{\\([^{}]*\\)}" s start)
      (let ((prefix (substring s start (match-beginning 0))))
        (unless (string= "" prefix)
          (push prefix strings)))
      (push (list (match-string 1 s)) strings)
      (setq start (match-end 0)))
    (let ((tail (substring s start)))
      (unless (string= "" tail)
        (push tail strings)))
    (nreverse strings)))

(defun plur-build-rx-form (strings)
  (let ((form '(and)))
    (dolist (item strings form)
      (setq form
            (append form (if (stringp item)
                             (list item)
                           (list (append '(or) (split-string (car item) ",")))))))))

(defun plur-build-regexp (string)
  (rx-to-string
   (plur-build-rx-form
    (plur-split-string string)) 'no-group))

(defun plur-isearch-regexp (string &optional _lax)
  (plur-build-regexp string))

(put 'plur-isearch-regexp 'isearch-message-prefix "plur ")

;;;###autoload
(defun plur-isearch-forward (&optional _not-plur no-recursive-edit)
  (interactive "P\np")
  (isearch-mode t nil nil (not no-recursive-edit) 'plur-isearch-regexp))

;; This autoload cookie is just for package.el user who wants bind some key to this
;; command on `isearch-mode-map' in h{is,er} init file without requiring this feature.
;;;###autoload
(defun plur-isearch-query-replace (&optional arg)
  "Start `plur-query-replace' from `plur-isearch-forward'."
  (interactive
   (list current-prefix-arg))
  (barf-if-buffer-read-only)
  (let ((search-upper-case nil)
        (search-invisible isearch-invisible)
        (backward (and arg (eq arg '-)))
        (isearch-recursive-edit nil)
        (from-string isearch-string)
        to-string)
    (isearch-done nil t)
    (isearch-clean-overlays)
    (if (and isearch-other-end
             (if backward
                 (> isearch-other-end (point))
               (< isearch-other-end (point)))
             (not (and transient-mark-mode mark-active
                       (if backward
                           (> (mark) (point))
                         (< (mark) (point))))))
        (goto-char isearch-other-end))
    (set query-replace-from-history-variable
         (cons isearch-string
               (symbol-value query-replace-from-history-variable)))
    (setq to-string
          (query-replace-read-to
           from-string
           (concat "Query replace"
                   (isearch--describe-regexp-mode isearch-regexp-function t)
                   (if (and transient-mark-mode mark-active) " in region" ""))
           t))
    (cl-destructuring-bind (from-string to-string) (plur-replace-subr from-string to-string)
      (perform-replace from-string to-string t t nil nil nil
                       (if (and transient-mark-mode mark-active) (region-beginning))
                       (if (and transient-mark-mode mark-active) (region-end))))
    (and isearch-recursive-edit (exit-recursive-edit))))

(defun plur-normalize-strings (strings)
  ;; ("m" ("ice,ouse") => (("m") ("ice" "ouse"))
  (let (result)
    (dolist (elt strings)
      (if (stringp elt)
          (push (list elt) result)
        (push (split-string (car elt) ",") result)))
    (nreverse result)))

(defun plur-expand-string (string)
  ;; facilit{y,ies} => ("facility" "facilities")
  (let ((strings (plur-normalize-strings
                  (plur-split-string string)))
        (results '("")) aux)
    (dolist (elt strings results)       ; List
      (setq aux nil)
      (dolist (elt1 elt)                ; String
        (dolist (prefix results)        ; String
          (push (concat prefix elt1) aux)))
      (setq results (nreverse aux)))))

(defun plur-string-all-upper-case-p (string)
  (string= string (upcase string)))

(defun plur-string-all-lower-case-p (string)
  (string= string (downcase string)))

(defun plur-string-capitalized-p (string)
  "Return non-nil if the first letter of STRING is upper case."
  (plur-string-all-upper-case-p (substring string 0 1)))

(defun plur-string-preserve-upper-case (s1 s2)
  "Preserve upper case in S1 and S2.
S1 and S1 are same string but in different case.
For example, \"Foobar\", \"fooBar\" => \"FooBar\"."
  (apply 'string
         (cl-mapcar (lambda (c1 c2)
                      (if (and (= (downcase c1) c1)
                               (= (downcase c1) c2))
                          c1
                        (upcase c1)))
                    s1 s2)))

(defun plur-replace-find-match (matches from-string)
  "Return a function as the cdr of replacement for `perform-replace'."
  (lambda (_data _count)
    ;; Simulate `case-replace' to preserve case in replacement
    ;; See (info "(emacs) Replacement and Lax Matches")
    (let* ((search (match-string 0))
           (replacement
            (cdr (assoc (downcase search) matches))))
      (if (or (not (plur-string-all-lower-case-p from-string)) ; if search contains any
              case-replace                                     ; upper-case letter,
              case-fold-search)                                ; don't change case
          replacement
        (plur-string-preserve-upper-case
         (cond
          ((plur-string-all-lower-case-p search) (downcase replacement))
          ((plur-string-all-upper-case-p search) (upcase replacement))
          ((plur-string-capitalized-p search) (capitalize replacement))
          (t replacement))
         replacement)))))

(defun plur-replace-subr (from-string to-string)
  "Return a list contains search and replacement for `perform-replace'."
  (let ((matches
         (cl-mapcar 'cons
                    (mapcar 'downcase (plur-expand-string from-string))
                    (plur-expand-string to-string))))
    (setq to-string
          (cons (plur-replace-find-match matches from-string) nil)))
  (setq from-string (plur-build-regexp from-string))
  (list from-string to-string))

;;;###autoload
(defun plur-query-replace (from-string to-string &optional delimited start end backward)
  (interactive
   (let ((common
          (query-replace-read-args
           (concat "Plur Query replace"
                   (if current-prefix-arg
                       (if (eq current-prefix-arg '-) " backward" " word")
                     "")
                   (if (use-region-p) " in region" ""))
           nil)))
     (list (nth 0 common) (nth 1 common) (nth 2 common)
           (if (use-region-p) (region-beginning))
           (if (use-region-p) (region-end))
           (nth 3 common))))
  (cl-destructuring-bind (from-string to-string) (plur-replace-subr from-string to-string)
    (perform-replace from-string to-string t t delimited nil nil start end backward)))

;;;###autoload
(defun plur-replace (from-string to-string &optional delimited start end backward)
  (interactive
   (let ((common
          (query-replace-read-args
           (concat "Plur Replace"
                   (if current-prefix-arg
                       (if (eq current-prefix-arg '-) " backward" " word")
                     "")
                   (if (use-region-p) " in region" ""))
           t)))
     (list (nth 0 common) (nth 1 common) (nth 2 common)
           (if (use-region-p) (region-beginning))
           (if (use-region-p) (region-end))
           (nth 3 common))))
  (cl-destructuring-bind (from-string to-string) (plur-replace-subr from-string to-string)
    (perform-replace from-string to-string nil t delimited nil nil start end backward)))


(provide 'plur)

;; Local Variables:
;; fill-column: 90
;; End:

;;; plur.el ends here
