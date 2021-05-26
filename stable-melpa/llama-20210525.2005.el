;;; llama.el --- Anonymous function literals       -*- lexical-binding: t -*-

;; Copyright (C) 2020-2021  Jonas Bernoulli

;; Authors: Jonas Bernoulli <jonas@bernoul.li>
;; URL: https://git.sr.ht/~tarsius/llama
;; Package-Version: 20210525.2005
;; Package-Commit: 2694b2aeb1c87bb2ad8b0f611ca438c30f5eaeae
;; Keywords: extensions

;; Package-Requires: ((seq "2.20"))
;; SPDX-License-Identifier: GPL-3.0-or-later

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

;; This package provides anonymous function literals for Emacs-Lisp.

;; Unfortunately anonymous function literals won't be added to Emacs
;; anytime soon.  The arguments as to why we would like to have that
;; has been layed out convincingly but the proposal has been rejected
;; anyway.

;; Several packages exist that implement anonymous function literals,
;; but until now they all either are waiting for a patch to the C part
;; be merged into Emacs, or they depart too far from the ideal syntax.

;; In a stroke of luck I discovered a loophole that allows us to have
;; almost the syntax that we want without having to convince anyone.
;;
;;   $(foo %)        is what I would have used if it were up to me.
;;   #(foo %)        works just as well for me.
;;   ##(foo %)       is similar enough to that.
;;   (##foo %)       is the loophole that I discovered.

;; Even though there is no space between the second # and `foo', this
;; last form is read as a list with three arguments (## foo %) and it
;; is also indented the way we want!
;;
;;   (##foo %
;;          bar)

;; This is good enough for me, but with a bit of font-lock trickery,
;; we can even get it to be display like this:
;;
;;   ##(foo %
;;          bar)
;;
;; This is completely optional and you have to opt-in by enabling
;; `llama-mode' (or the global variant `global-llama-mode').

;; An unfortunate edge-case exists that you have to be aware off; if
;; no argument is placed on the same line as the function, then Emacs
;; does not indent as we would want it too:
;;
;;   (##foo                                         ##(foo
;;    bar)        which llama-mode displays as       bar)

;; I recommend that in this case you simply write this instead:
;;
;;   (## foo                                        ##( foo
;;       bar)     which llama-mode displays as          bar)

;; It is my hope that this package helps to eventually get similar
;; syntax into Emacs itself, by demonstrating that this is useful and
;; that people want to use it.

;;; Code:

(eval-when-compile (require 'cl-lib))
(require 'seq)

;;;###autoload
(defmacro ## (fn &rest args)
    "Return an anonymous function.

The returned function calls the function FN with arguments ARGS
and returns its value.

The arguments of the outer function are determined recursively
from ARGS.  Each symbol from `%1' through `%9' that appears in
ARGS is treated as a positional argument.  Missing arguments
are named `_%N', which keeps the byte-compiler quiet.  `%' is
a shorthand for `%1'; only one of these can appear in ARGS.
`%*' represents extra `&rest' arguments.

Instead of:

  (lambda (a _ c &rest d)
    (foo a (bar c) d))

you can use this macro and write:

  (##foo % (bar %3) %*)

which expands to:

  (lambda (% _%2 %3 &rest %*)
    (foo % (bar %3) %*))

Note that there really does not have to be any whitespace
between \"##\" and \"foo\"!

If you enable `llama-mode' or `global-llama-mode', then the
above is *displayed* as:

  ##(foo % (bar %3) %*)"
  (cl-check-type fn symbol)
  `(lambda ,(llama--arguments args)
     (,fn ,@args)))

(defun llama--arguments (data)
  (let ((args (make-vector 10 nil)))
    (llama--collect data args)
    `(,@(let ((n 0))
          (mapcar (lambda (symbol)
                    (cl-incf n)
                    (or symbol (intern (format "_%%%s" n))))
                  (reverse (seq-drop-while
                            'null
                            (reverse (seq-subseq args 1))))))
      ,@(and (aref args 0) '(&rest %*)))))

(defun llama--collect (data args)
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
      (llama--collect elt args)))))

(defvar llama--keywords
  '(("(##" (0 (llama--transpose)))))

(defun llama--transpose ()
  (and (not (nth 8 (syntax-ppss)))
       `(face nil display "##(")))

(defvar-local llama--display-already-managed nil)

;;;###autoload
(define-minor-mode llama-mode
  "Toggle Llama mode.

When Llama mode is enabled then forms like (##foo %) are
displayed as ##(foo %) instead.

You can enable this mode locally in desired buffers, or use
`global-llama-mode' to enable it in all `emacs-lisp-mode'
buffers."
  :init-value nil
  (cond
   (llama-mode
    (font-lock-add-keywords nil llama--keywords)
    (add-to-list 'font-lock-extra-managed-props 'display)
    (when (memq 'display font-lock-extra-managed-props)
      (setq llama--display-already-managed t)))
   (t
    (font-lock-remove-keywords nil llama--keywords)
    (if llama--display-already-managed
        (setq llama--display-already-managed nil)
      (setq font-lock-extra-managed-props
            (delq 'display font-lock-extra-managed-props)))
    (with-silent-modifications
      (remove-text-properties (point-min) (point-max) '(display nil)))))
  (font-lock-flush))

;;;###autoload
(define-globalized-minor-mode global-llama-mode
  llama-mode llama--turn-on-mode
  :group 'lisp)

(defun llama--turn-on-mode ()
  (when (and (not llama-mode)
             (derived-mode-p 'emacs-lisp-mode))
    (llama-mode 1)))

;;; _
(provide 'llama)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; llama.el ends here
