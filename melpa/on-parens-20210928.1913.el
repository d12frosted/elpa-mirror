;;; on-parens.el --- smartparens wrapper to fit with evil-mode/vim normal-state -*- lexical-binding: t; -*-

;; Copyright (C) 2015

;; Author:  William G Hatch
;; Keywords: evil, smartparens
;; Package-Version: 20210928.1913
;; Package-Commit: b8ee8cea45c9b34820fcb951f522f13e3736d216
;; Package-Requires: ((dash "2.10.0") (emacs "24") (evil "1.1.6") (smartparens "1.6.3"))

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

;; In vi/vim/evil-mode in normal-state, the cursor is viewed as being
;; ON a character rather than BETWEEN characters.  This breaks
;; smartparens particularly when it tries to put you past the last
;; character of the line, since normal-state will push point back one
;; character so it can be viewed as on the last character rather than
;; past it.  Additionally, most vim/evil movements go to the beginning
;; of a text object, with an alternative version that goes to the end.
;; Emacs tends to go past the end of things when it goes forward, but
;; to the beginning when it goes back.
;;
;; This provides movements for normal-state that go forward and back
;; to specifically the beginning or end of sexps, as well as up or
;; down.

;;; Code:

(require 'dash)
(require 'smartparens)
(require 'evil) ; for evil-jump-item


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Section for getting needed info out of smartparens settings

(defun on-parens--get-specs (sp-def)
  ;; return a list of smartparen specs that are global or for an active mode
  (let ((mode (car sp-def)))
    (if (or
         (equal t mode)
         (equal mode major-mode)
         (-contains? minor-mode-list mode))
        (cdr sp-def)
      nil)))
(defun on-parens--get-delim-from-spec (sp-spec open?)
  ;; get the delimiter from the spec
  (let ((kw (if open? :open :close)))
    (cond ((not sp-spec) nil)
          ((equal (car sp-spec) kw) (cadr sp-spec))
          (t (on-parens--get-delim-from-spec (cdr sp-spec) open?)))))

(defun on-parens--delim-list (open?)
  (let ((get-delim (lambda (x) (on-parens--get-delim-from-spec x open?))))
    (-flatten (-map (lambda (def)
                      (-map get-delim
                            (on-parens--get-specs def)))
                    sp-pairs))))

(defun on-parens--at-delim-p (open?)
  ;; TODO - handle multi-character delimiters better.  This only returns true if point is at the beginning of a multi-char delimiter.
  ;; Previously this just returned true, but now it returns the string of the delimiter it's on.
  (let ((delims (-map 'regexp-quote (on-parens--delim-list open?))))
    (-reduce-from (lambda (prev cur)
                    (if prev prev
                      (and (looking-at-p cur) cur)))
                  nil
                  delims)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Predicates!

;; TODO - handle delimiters like "" better.
(defun on-parens-on-open? ()
  "Is point on an opening smartparens delimiter?"
  (on-parens--at-delim-p t))
(defun on-parens-on-close? ()
  "Is point on a closing smartparens delimiter?"
  (on-parens--at-delim-p nil))
(defun on-parens-on-delimiter? ()
  "Is point on a smartparens delimiter?"
  (or (on-parens-on-open?) (on-parens-on-close?)))


(defun on-parens--advances? (move fwd?)
  ;; does this movement function move the direction we expect?
  (save-excursion
    (let ((cur-point (point))
          (end-point (progn
                       (funcall move)
                       (point))))
      (if fwd?
          (> end-point cur-point)
        (< end-point cur-point)))))

(defun on-parens--movements-equal? (a b)
  (let ((am (save-excursion (funcall a) (point)))
        (bm (save-excursion (funcall b) (point))))
    (equal am bm)))

(defun on-parens--from-close-on-last-sexp? ()
  (on-parens--movements-equal?
   (lambda ()
     (forward-char)
     (sp-forward-sexp))
   (lambda ()
     (forward-char)
     (sp-up-sexp))))

(defun on-parens--from-open-on-last-sexp? ()
  (on-parens--advances? 'sp-next-sexp nil))
(defun on-parens--on-last-sexp? ()
  (cond ((on-parens-on-open?) (on-parens--from-open-on-last-sexp?))
        ((on-parens-on-close?) (on-parens--from-close-on-last-sexp?))
        (t (on-parens--on-last-symbol-sexp?))))

(defun on-parens--from-open-on-first-sexp? ()
  (on-parens--advances? 'sp-previous-sexp t))
(defun on-parens--from-close-on-first-sexp? ()
  (on-parens--advances? (lambda ()
                          (evil-jump-item)
                          (sp-previous-sexp))
                        t))
(defun on-parens--on-first-sexp? ()
  (cond ((on-parens-on-open?) (on-parens--from-open-on-first-sexp?))
        ((on-parens-on-close?) (on-parens--from-close-on-first-sexp?))
        ;; they can't all be the same because sp functions act differently in
        ;; the middle of symbols
        (t (on-parens--on-end-of-last-symbol-sexp?))))

(defun on-parens--on-start-of-symbol-sexp? ()
  ;; If backward-sexp then forward-sexp nets a backward movement, it means
  ;; we were at the start of the symbol.
  (on-parens--advances? (lambda ()
                          (sp-backward-sexp)
                          (sp-forward-sexp))
                        nil))
(defun on-parens--on-end-of-symbol-sexp? ()
  (on-parens--movements-equal?
   'forward-char (lambda () (sp-backward-sexp) (sp-forward-sexp))))
(defun on-parens--on-start-of-first-symbol-sexp? ()
  (on-parens--movements-equal?
   'sp-backward-sexp 'sp-backward-up-sexp))
(defun on-parens--on-end-of-last-symbol-sexp? ()
  (on-parens--movements-equal?
   'sp-up-sexp (lambda () (forward-char) (sp-forward-sexp))))
(defun on-parens--on-first-symbol-sexp? ()
  (on-parens--movements-equal?
   'sp-forward-sexp (lambda () (sp-beginning-of-sexp) (sp-forward-sexp))))
(defun on-parens--on-last-symbol-sexp? ()
  (or (on-parens--movements-equal?
       'sp-backward-sexp (lambda () (sp-end-of-sexp) (sp-backward-sexp)))
      ;; IE on the first char of the last symbol-sexp
      (on-parens--movements-equal?
       'ignore (lambda () (sp-end-of-sexp) (sp-backward-sexp)))))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Motion commands

(defmacro on-parens--command-wrap (name command opposite docs)
  ;; Wrapper code to make a command that takes an optionally negative
  ;; prefix argument, because they're all the same
  `(defun ,name (&optional arg)
     ,docs
     (interactive "p")
     (if (< arg 0)
         (,opposite (abs arg))
       (dotimes (_i arg)
         (,command)))))

(defun on-parens--forward-sexp-from-on-open ()
  (when (on-parens--advances? 'sp-next-sexp t)
    (sp-next-sexp)))
(defun on-parens--forward-sexp-from-on-close ()
  (let ((move (lambda () (forward-char) (sp-next-sexp))))
    (when (on-parens--advances? move t)
      (funcall move))))
;; if not on delimiters, use normal sp-next-sexp
(defun on-parens--forward-sexp ()
  (cond ((on-parens-on-open?) (on-parens--forward-sexp-from-on-open))
        ((on-parens-on-close?) (on-parens--forward-sexp-from-on-close))
        (t (unless (on-parens--on-last-symbol-sexp?)
             (sp-forward-sexp)
             (sp-next-sexp)))))
;;;###autoload (autoload 'on-parens-forward-sexp "on-parens.el" "" t)
(on-parens--command-wrap on-parens-forward-sexp
                         on-parens--forward-sexp
                         on-parens-backward-sexp
                         "Move forward to the start of the next sexp.")

(defun on-parens--backward-sexp-from-on-open ()
  (unless (on-parens--on-first-sexp?)
    (sp-backward-sexp)))
(defun on-parens--backward-sexp-from-on-close ()
  (evil-jump-item))
(defun on-parens--backward-sexp ()
  (cond ((on-parens-on-open?) (on-parens--backward-sexp-from-on-open))
        ((on-parens-on-close?) (on-parens--backward-sexp-from-on-close))
        (t (unless (on-parens--movements-equal? 'sp-backward-sexp
                                                'sp-backward-up-sexp)
             (sp-backward-sexp)))))
;;;###autoload (autoload 'on-parens-backward-sexp "on-parens.el" "" t)
(on-parens--command-wrap on-parens-backward-sexp
                         on-parens--backward-sexp
                         on-parens-forward-sexp
                         "Move backward to the start of the next sexp.")

(defun on-parens--forward-sexp-end-from-on-open ()
  (evil-jump-item))
(defun on-parens--forward-sexp-end-from-on-close ()
  (unless (on-parens--on-last-sexp?)
    (forward-char)
    (sp-forward-sexp)
    (backward-char)))
(defun on-parens--forward-sexp-end-else ()
  (unless (on-parens--on-end-of-last-symbol-sexp?)
    (forward-char)
    (sp-forward-sexp)
    (backward-char)))
(defun on-parens--forward-sexp-end ()
  (cond ((on-parens-on-open?) (on-parens--forward-sexp-end-from-on-open))
        ((on-parens-on-close?) (on-parens--forward-sexp-end-from-on-close))
        (t (on-parens--forward-sexp-end-else))))
;;;###autoload (autoload 'on-parens-forward-sexp-end "on-parens.el" "" t)
(on-parens--command-wrap on-parens-forward-sexp-end
                         on-parens--forward-sexp-end
                         on-parens-backward-sexp-end
                         "Move forward to the next end of a sexp.")

(defun on-parens--backward-sexp-end-from-on-open ()
  (unless (on-parens--on-first-sexp?)
    (on-parens--backward-sexp-from-on-open)
    (on-parens--forward-sexp-end)))
(defun on-parens--backward-sexp-end-from-on-close ()
  (unless (on-parens--on-first-sexp?)
    (evil-jump-item)
    (on-parens--backward-sexp-end-from-on-open)))
(defun on-parens--backward-sexp-end-else ()
  (unless (on-parens--on-first-symbol-sexp?)
    (unless (on-parens--on-start-of-symbol-sexp?)
      (on-parens--backward-sexp))
    (on-parens--backward-sexp)
    (on-parens--forward-sexp-end)))
(defun on-parens--backward-sexp-end ()
  (cond ((on-parens-on-open?) (on-parens--backward-sexp-end-from-on-open))
        ((on-parens-on-close?) (on-parens--backward-sexp-end-from-on-close))
        (t (on-parens--backward-sexp-end-else))))
;;;###autoload (autoload 'on-parens-backward-sexp-end "on-parens.el" "" t)
(on-parens--command-wrap on-parens-backward-sexp-end
                         on-parens--backward-sexp-end
                         on-parens-forward-sexp-end
                         "Move backward to the next end of a sexp.")

(defun on-parens--up-sexp ()
  (when (on-parens-on-close?)
    (forward-char))
  (sp-backward-up-sexp)
  ;; When this is the argument of an evil operator (delete or change), don't delete
  ;; the starting paren.  Use `on-parens-on-open?` to get the size of the delimiter.
  (when (evil-operator-state-p)
    (forward-char (length (on-parens-on-open?)))))
;;;###autoload (autoload 'on-parens-up-sexp "on-parens.el" "" t)
(on-parens--command-wrap on-parens-up-sexp
                         on-parens--up-sexp
                         on-parens-down-sexp
                         "Move up to the start of the containing sexp.")
(defun on-parens--up-sexp-end ()
  (when (on-parens-on-close?)
    (forward-char))
  (let ((start-point (point)))
    (sp-up-sexp)
    (backward-char)
    (if (> start-point (point))
        ;; If we went backward, then we didn't actually go up to a closer, so go back to start.
        (goto-char start-point)
      ;; If we went forward, we don't want to delete part of a multi-character delimiter in operator mode, so go back to the start of the delimiter.
      (when (evil-operator-state-p)
        (while (and (not (on-parens-on-close?)) (not (= start-point (point))))
          (backward-char))))))
;;;###autoload (autoload 'on-parens-up-sexp-end "on-parens.el" "" t)
(on-parens--command-wrap on-parens-up-sexp-end
                         on-parens--up-sexp-end
                         on-parens-down-sexp
                         "Move up to the end of the containing sexp.")

(defun on-parens--down-sexp ()
  ;; Surprise!!!
  (sp-down-sexp))
;;;###autoload (autoload 'on-parens-down-sexp "on-parens.el" "" t)
(on-parens--command-wrap on-parens-down-sexp
                         on-parens--down-sexp
                         on-parens-up-sexp
                         "Move down to the beginning of the contained sexp.")
(defun on-parens--down-sexp-end ()
  (sp-down-sexp)
  (sp-end-of-sexp)
  (backward-char))
;;;###autoload (autoload 'on-parens-down-sexp-end "on-parens.el" "" t)
(on-parens--command-wrap on-parens-down-sexp-end
                         on-parens--down-sexp-end
                         on-parens-up-sexp
                         "Move down to the end of the contained sexp.")

(defun on-parens--forward-sexp-in-supersexp ()
  (on-parens--up-sexp)
  (on-parens--forward-sexp)
  (on-parens--down-sexp))
(defun on-parens--backward-sexp-in-supersexp ()
  (on-parens--up-sexp)
  (on-parens--backward-sexp-end)
  (on-parens--down-sexp))
;;;###autoload (autoload 'on-parens-forward-sexp-in-supersexp "on-parens.el" "" t)
(on-parens--command-wrap on-parens-forward-sexp-in-supersexp
                         on-parens--forward-sexp-in-supersexp
                         on-parens-backward-sexp-in-supersexp
                         "up, forward, down")
;;;###autoload (autoload 'on-parens-backward-sexp-in-supersexp "on-parens.el" "" t)
(on-parens--command-wrap on-parens-backward-sexp-in-supersexp
                         on-parens--backward-sexp-in-supersexp
                         on-parens-forward-sexp-in-supersexp
                         "up, backward, down")


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; editing commands!

(defmacro on-parens--maybe-forwarded (name forward-p action)
  `(defun ,name (&optional arg)
     (interactive "p")
     (let ((fwd (,forward-p)))
       (when fwd
         (forward-char))
       (,action arg)
       (when fwd
         (backward-char)))))

;;;###autoload (autoload 'on-parens-forward-slurp "on-parens.el" "" t)
(on-parens--maybe-forwarded on-parens-forward-slurp
                            on-parens-on-open?
                            sp-forward-slurp-sexp)
;;;###autoload (autoload 'on-parens-backward-slurp "on-parens.el" "" t)
(on-parens--maybe-forwarded on-parens-backward-slurp
                            on-parens-on-open?
                            sp-backward-slurp-sexp)
;;;###autoload (autoload 'on-parens-forward-barf "on-parens.el" "" t)
(on-parens--maybe-forwarded on-parens-forward-barf
                            on-parens-on-open?
                            sp-forward-barf-sexp)
;;;###autoload (autoload 'on-parens-backward-barf "on-parens.el" "" t)
(on-parens--maybe-forwarded on-parens-backward-barf
                            on-parens-on-open?
                            sp-backward-barf-sexp)
;;;###autoload (autoload 'on-parens-splice "on-parens.el" "" t)
(on-parens--maybe-forwarded on-parens-splice
                            on-parens-on-open?
                            sp-splice-sexp)
;;;###autoload (autoload 'on-parens-split-supersexp "on-parens.el" "" t)
(on-parens--maybe-forwarded on-parens-split-supersexp
                            on-parens-on-close?
                            sp-split-sexp)
;;;###autoload (autoload 'on-parens-join-neighbor-sexp "on-parens.el" "" t)
(on-parens--maybe-forwarded on-parens-join-neighbor-sexp
                            on-parens-on-close?
                            sp-join-sexp)
;;;###autoload
(defun on-parens-kill-sexp (&optional arg)
  "It's actually just sp-kill-sexp!"
  (interactive "p")
  (sp-kill-sexp arg))


(provide 'on-parens)
;;; on-parens.el ends here
