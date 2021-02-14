;;; l.el --- Compact syntax for short lambda       -*- lexical-binding: t -*-

;; Copyright (C) 2021  Jonas Bernoulli

;; Authors: Jonas Bernoulli <jonas@bernoul.li>
;; URL: https://git.sr.ht/~tarsius/l
;; Package-Version: 20210213.1840
;; Package-Commit: e73d5e11db9aaa6ff6186e464b25255f13701c42
;; Keywords: extensions

;; Package-Requires: ((seq "2.20"))

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Compact syntax for short lambda.

;; After `llama', this is my second attempt at providing such syntax
;; without having the power to add actual new syntax to Emacs, which
;; means that I have to fake it, which means that compromises cannot
;; be avoided.

;; The `l' macro allows you to write one of these three expressions:
;;
;;     (l`list % %2 %*)
;;     (l'list % %2 %*)
;;     (l list % %2 %*)
;;
;; all of which are turned into:
;;
;;     (lambda (% %2 &rest %*)
;;       (list % %2 %*))

;; This behaves similarly to backquote/unquote syntax, which is why I
;; recommend using the first variant, with the "`" character.  I have
;; also considered using "," instead of "%" as the unquote character,
;; but have decided against it because it cannot be used by itself at
;; the end of a list.

;; You may wish to substitute some fancy character for `l':
;;
;;     (defun my-prettify-l-symbol ()
;;       (cl-pushnew '("l" . ?ƒ) prettify-symbols-alist))
;;     (add-hook 'emacs-lisp-mode-hook 'my-prettify-l-symbol)
;;     (add-hook 'emacs-lisp-mode-hook 'lisp-prettify-more-symbols)

;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'seq)

;;;###autoload
(defmacro l (fn &rest body)
  `(lambda ,(l--arguments body)
     (,(if (car-safe fn)
           (cadr fn)
         fn)
      ,@body)))

(defun l--arguments (data)
  (let ((args (make-vector 10 nil)))
    (l--collect data args)
    `(,@(let ((n 0))
          (mapcar (lambda (symbol)
                    (cl-incf n)
                    (or symbol (intern (format "_%%%s" n))))
                  (reverse (seq-drop-while
                            'null
                            (reverse (seq-subseq args 1))))))
      ,@(and (aref args 0) '(&rest %*)))))

(defun l--collect (data args)
  (cond
   ((symbolp data)
    (let ((name (symbol-name data)) pos)
      (when (string-match "\\`%\\([1-9*]\\)?\\'" name)
        (setq pos (match-string 1 name))
        (setq pos (cond ((equal pos "*") 0)
                        ((not pos) 1)
                        (t (string-to-number pos))))
        (when (and (= pos 1)
                   (aref args 1)
                   (not (equal data (aref args 1))))
          (error "%% and %%1 are mutually exclusive"))
        (aset args pos data))))
   ((and (not (eq (car-safe data) '##))
         (or (listp data)
             (vectorp data)))
    (seq-doseq (elt data)
      (l--collect elt args)))))

;;; _
(provide 'l)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; l.el ends here
