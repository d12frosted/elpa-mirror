;;; syntree.el --- Draw plain text constituency trees  -*- lexical-binding: t; -*-

;; Copyright (C) 2021, 2022 Enrico Flor

;; Author: Enrico Flor <enrico@eflor.net>
;; Maintainer: Enrico Flor <enrico@eflor.net>
;; URL: https://github.com/enricoflor/syntree
;; Package-Version: 20220122.2341
;; Package-Commit: 45d010b071c32cab4a3a5d336d6c01cde49657f8
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (transient "0.3.7"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Syntree.el returns plain text constituency trees, given an input
;; that specifies the constituency.  It is primarily aimed at
;; linguists (syntacticians, semanticists etc.) who might want to have
;; trees in their plain text nodes because of their portability, but
;; it can of course be used to draw any sort of tree of the suitable
;; form.
;;
;; For full documentation, see the readme file at
;;          <https://github.com/enricoflor/syntree>

;;; Code:

(require 'cl-lib)
(require 'transient)
(eval-when-compile
  (require 'subr-x))

;; Global variables

(defgroup syntree nil
  "Generate plain text constituency trees."
  :prefix "syntree-"
  :link '(url-link :tag "Website for syntree"
                   "https://github.com/enricoflor/syntree")
  :group 'convenience)

;; These five variables determine the shape of the output tree and are
;; meant for the user to set.

(defcustom syntree-padding 2
  "The minimal amount of spaces between any two nodes.
It can be temporarily overidden by passing a numerical prefix
argument when calling one of the interactive functions."
  :type 'integer
  :group 'syntree)

(defcustom syntree-wrap 0
  "If less than 1, don't wrap terminal strings, else if N, wrap at N length.
If you set this variable to 10, the text of leaves and of labels
will be, if possible, word-wrapped so that each line is not
longer than 10."
  :type 'integer
  :group 'syntree)

(defcustom syntree-height 1
  "If more than 1, add as many \"|\" to lengthen the stems."
  :type 'integer
  :group 'syntree)

(defcustom syntree-smooth-branches nil
  "If nil, the output tree has square branches, if t, smooth.
This value is reset at every invocation of an interactive
function."
  :type 'boolean
  :group 'syntree)

(defcustom syntree-one-line nil
  "If t, the terminals in the output are on the same line.
If nil, the terminals are at different heights.  This value is
reset at every invocation of an interactive function."
  :type 'boolean
  :group 'syntree)

;; Basic string functions

(defun syntree--fill (s p w)
  "If S is shorter than W, pad right and left with P.
Always return a string that is at least as long as W."
  (let* ((diff (max 0 (- w (length s))))
         (post (/ diff 2))
         (pre (- diff post)))
    (concat (apply #'concat (make-list pre p))
            s
            (apply #'concat (make-list post p)))))

(defun syntree--wrap-string (s w)
  "Word-wrap string S at width W.  If W < 1, don't wrap."
  (let ((wrap
         (cond ((not (numberp w))
                most-positive-fixnum)
               ((< w 1)
                most-positive-fixnum)
               (t w))))
    (with-temp-buffer
      (insert s)
      (goto-char (point-min))
      (let ((fill-column wrap)
            (adaptive-fill-mode nil))
        (fill-region (point-min) (point-max)))
      (buffer-string))))

;; Converting leaf strings into terminal nodes

(defun syntree--split-and-wrap (s)
  "Split S at \"\\n\", wrap at desired length, and split again.
Return a list of strings."
  (flatten-tree
   (mapcar (lambda (x) (split-string x "[\f\t\n\r\v]+" t))
           (mapcar (lambda (x) (syntree--wrap-string x syntree-wrap))
                   (split-string (string-trim s)
                                 "[\f\t\n\r\v]+" t)))))

(defun syntree--split-leaf-string (s)
  "Take a string S and return a list of label and text strings.
Whatever comes before the first \":\" is going to be the label.
The text can be either one string or as many strings as there are
newlines in the input or as a result or 'syntree--wrap-string' to
the wrap length specified by 'syntree-wrap'."
  (let* ((str
          (string-trim s))
         (str-one-line
          (replace-regexp-in-string "\n" "" str))
         (raw-label
          (if (string= (string-trim-right str-one-line ":.*$")
                       str)
              ""
            (string-trim-right str-one-line ":.*$")))
         (raw-text
          (string-trim-left str "^[^:]*:")))
    (cons raw-label
          (syntree--split-and-wrap raw-text))))

(defun syntree--gen-leaf (s)
  "Convert the string S into a node.
Return a list of whose car is the numerical value of the width of
the node, and whose cdr is a list of strings."
  (let* ((leaf-list
          (syntree--split-leaf-string s))
         (width
          (apply #'max
                 (mapcar #'length leaf-list)))
         (padded-leaf-list
          (mapcar (lambda (x) (syntree--fill x " " width))
                  (cdr leaf-list)))
         (label
          (if (or (string= "_" (car leaf-list))
                  (string-blank-p (car leaf-list)))
              (syntree--fill "|" " " width)
            (syntree--fill (string-remove-prefix "_" (car leaf-list))
                           " " width)))
         (stem
          (if (> syntree-height 1)
              (make-list syntree-height (syntree--fill "|" " " width))
            (syntree--fill "|" " " width))))
    (cons width
          (mapcan #'flatten-tree
                  (list
                   stem
                   label
                   (when (and (string-prefix-p "_" (car leaf-list))
                              (> width 2))     ; add roof
                     (list
                      (replace-regexp-in-string "^_\\|_$" "."
                                                (syntree--fill "|" "_" width))
                      (replace-regexp-in-string "^_\\|_$" "|"
                                                (apply #'concat
                                                       (make-list width "_")))))
                   padded-leaf-list)))))

(defun syntree--replace-terminal-strings (l)
  "Replace every terminal string in L with the node it represents.
Every string in L that is not the first member of a list is a
terminal, and before building the tree with 'syntree--merge' it
must be replaced with a node: a list whose car is a numerical
value (the width of the node) and whose cdr is a list of strings.
Each node is the output of 'syntree--gen-leaf'."
  (cons (car l)
        (mapcar
         (lambda (x) (if (stringp x)
                         (syntree--gen-leaf x)
                       (syntree--replace-terminal-strings x)))
         (cdr l))))

;; Building subtrees

(defun syntree--adjust-depth (node max-depth)
  "Depending on the value of 'syntree-one-line', make NODE reach MAX-DEPTH.
If 'syntree-one-line' is nil, this will append the amount of
empty strings of length (car NODE) to (cadr NODE) until its
length is MAX-DEPTH.  If 'syntree-one-line' is t, this will
prepend the right amount of stem strings of length (car NODE)
to (cadr NODE) instead."
  (let* ((spaces (apply #'concat (make-list (car node) " ")))
         (stem (syntree--fill "|" " " (car node)))
         (original-list-of-strings (cdr node))
         (diff (- max-depth
                  (length original-list-of-strings))))
    (cons (car node)
          (if syntree-one-line               ; add stem strings to the top
              (nconc (make-list diff stem)
                     (cdr node))
            (nconc original-list-of-strings ; add empty strings to the bottom
                   (make-list diff spaces))))))

(defvar syntree--padding-s "  "
  "The string used as a padding.
This value is reset at every invocation of an interactive
function according to the value of 'syntree-padding': specifying
a different global value for 'syntree--padding-s' has no effect.")

(defun syntree--concatenate-nodes (l)
  "L being a list of nodes, return the result of concatenating them.
The depth of the individual nodes is adjusted and the the
resulting node is obtained by zipping the lists of strings of
each node, concatenating them with the desidered amount of
padding."
  (let* ((max-depth
          (apply #'max
                 (mapcar (lambda (x) (length (cdr x)))
                         l)))
         (terminals-list
          (mapcar (lambda (x) (cdr
                               (syntree--adjust-depth x
                                                      max-depth)))
                  l))
         (total-width
          (+ (* (1- (length l))
                (length syntree--padding-s))
             (apply #'+
                    (mapcar #'car
                            l)))))
    (cons total-width
          (syntree--zip-concat-lists-of-strings terminals-list))))

(defun syntree--zip-concat-lists-of-strings (l)
  "Given a list of nodes L, concatenate them.
Zip (cadr node) for each node in L, concatenate the strings with
the desired amount of padding between them.  Return a complex
node."
  (cond ((= (length l) 1)
         (car l))
        ((= (length l) 2)
         (cl-mapcar (lambda (x y) (concat x syntree--padding-s y))
                    (car l)
                    (cadr l)))
        (t
         (cl-mapcar (lambda (x y) (concat x syntree--padding-s y))
                     (car l)
                     (syntree--zip-concat-lists-of-strings (cdr l))))))

(defun syntree--draw-branch (s)
  "Given string of stems S, return a branch string connecting them."
  (if (= (length (replace-regexp-in-string "\s" "" s))
         1)
      ""
    (let* ((left-offset
            (replace-regexp-in-string "|.*$" "" s))
           (right-offset
            (replace-regexp-in-string "^.*|" "" s))
           (branch-width
            (- (length s)
               (+ (length left-offset)
                  (length right-offset))))
           (raw-branch
            (concat left-offset
                    (replace-regexp-in-string "^_\\|_$" "."
                                              (syntree--fill "|" "_"
                                                             branch-width))
                    right-offset)))
      (if syntree-smooth-branches
          (replace-regexp-in-string "\\." " " raw-branch)
        raw-branch))))

(defun syntree--split-branch (s)
  "Return list of branch, left and right offset.
S is the string containing the branch."
  (list (replace-regexp-in-string "\s" "" s)
        (replace-regexp-in-string "[^\s]" ""
                                  (replace-regexp-in-string "\s*$" "" s))
        (replace-regexp-in-string "[^\s]" ""
                                  (replace-regexp-in-string "^\s*" "" s))))

(defun syntree--gen-label-list (label-string branch-string)
  "Return a list of strings to be concatenated as the label.
LABEL-STRING is the string in the input that is a label of one
constituent.  BRANCH-STRING is the string containing the
horizontal branch."
  (if (string-blank-p (string-trim label-string))
      ;; If the label is empty, all we need is to copy the branch
      ;; string replacing everything that is not a "|" with white
      ;; space:
      (replace-regexp-in-string "[^|]" " " branch-string)
    (let* ((label-list
            (syntree--split-and-wrap label-string))
           (branch-segments
            (syntree--split-branch branch-string))
           (label-width
            (apply #'max (mapcar #'length label-list))))
      (if (> label-width
             (length (car branch-segments)))
          ;; If the label is larger than the branch (not the branch
          ;; string, the branch!), then just center each string in
          ;; label-list.
          (mapcar (lambda (x) (syntree--fill x " " (length branch-string)))
                  label-list)
        ;; Otherwise, center each string in label-list relative to the
        ;; branch, and then pad left and right with the left and right
        ;; offsets.
        (mapcar (lambda (x) (concat (cadr branch-segments)
                                    (syntree--fill x
                                                   " "
                                                   (length
                                                    (car branch-segments)))
                                    (caddr branch-segments)))
                label-list)))))

(defun syntree--homogenize-length (l)
  "Make all strings in L as long as the longest one.
Return a list whose car is the length of all the strings, and
whose cadr is all the strings in L, padded with whitespace via
'syntree--fill' so that they are the same length, which is the
length of the longest string in L."
  (let ((max-length
         (apply #'max (mapcar #'length l))))
    (cons max-length
          (mapcar (lambda (x) (syntree--fill x " " max-length))
                  (cl-delete-if #'string-blank-p l)))))

(defun syntree--replace-outer-stems (l)
  "Replace first and last \"|\" in L with \"/\" and \"\\\".
If 'syntree-smooth-branches' is nil, or there isn't more than one stem, do
nothing."
  (let ((new-top
         (replace-regexp-in-string "^\\(\s*\\)|" "\\1/"
                                   (replace-regexp-in-string "|\\(\s*\\)$"
                                                             "\\\\\\1"
                                                             (car l)))))
    (if (or (not syntree-smooth-branches)
            (= (length (replace-regexp-in-string "\s" "" (car l)))
               1))
        (identity l)
      (cl-replace l (cons new-top (cdr l))))))

(defun syntree--gen-subtree (lab d)
  "Return a branching node given a label and a list of nodes.
LAB is the label string, D the list of daughter nodes."
  (let* ((subtree
          (cdr (syntree--concatenate-nodes d)))
         (branch-string
          (syntree--draw-branch (car subtree)))
         (label
          (syntree--gen-label-list lab
                                   branch-string))
         (single-stem
          (if (= (length (replace-regexp-in-string "\s" "" (car subtree)))
                 1)               ; there is only one stem
              (car subtree)
            (replace-regexp-in-string "[^|]" " "
                                      branch-string))))
    (syntree--homogenize-length
     (mapcan #'flatten-tree
             (list single-stem
                    label
                    (when (> syntree-height 1)
                      (make-list syntree-height
                                 (replace-regexp-in-string "[^|]" " "
                                                           branch-string)))
                    branch-string
                    (syntree--replace-outer-stems subtree))))))

;; Building the tree

(defun syntree--ready-constituent-p (l)
  "Check that L is a constituent ready to be merged into a subtree.
Return t if the first member of L is a label and all others are
nodes, nil otherwise."
  (ignore-errors
    (and (stringp (car l))
         (cl-every #'numberp
                   (mapcar #'car
                           (cdr l))))))

(defun syntree--merge (l)
  "Recursively generate all subtrees of list L.
Return the top node."
  (if (syntree--ready-constituent-p l)
      (syntree--gen-subtree (car l) (cdr l))
    (syntree--merge
     (cons (car l)
           (mapcar (lambda (x) (if (numberp (car x))
                                   (identity x)
                                 (syntree--merge x)))
                   (cdr l))))))

(defun syntree--add-newlines (l)
  "Append \"\\n\" to each string in (cadr L) and concatenate them all.
Also, remove the stem from the top node, and return the resulting
string (cadr L), which is the plain text tree."
   (concat "\n"   ; add empty line for insertion or yanking
           (apply #'concat
                  (mapcar
                   (lambda (x) (concat x "\n"))
                   (cl-delete (cadr l)
                              (cdr l))))))
(defun syntree--sublists (l)
  "Return list of all sublists of L."
  (cons l
        (when (listp l)
          (mapcan (lambda (x) (when (listp x)
                                (syntree--sublists x)))
                  (identity l)))))

(defun syntree--get-string ()
  "Return first list after point as buffer substring.
Check that the string is syntactically well-formed as an input
for 'syntree--main', and yield an informative 'user-error' if it
is not."
  (catch 'error
    (unless (search-forward "(" nil t)
      (throw 'error nil))
    (backward-char)
    (mark-sexp)
    (exchange-point-and-mark)
    (let ((candidate
           (buffer-substring-no-properties (region-beginning)
                                           (region-end))))
      (deactivate-mark)
      (unless (ignore-errors (read candidate))
        (throw 'error nil))
      (unless (cl-every #'stringp
                        (flatten-tree (read candidate)))
        (user-error
         "Not a valid input: each element must be a string"))
      (unless (cl-every (lambda (x) (> (length x) 1))
                        (syntree--sublists (read candidate)))
        (user-error
         "Not a valid input: each constituent must be labeled"))
      candidate)))

(defun syntree--main (s arg)
  "Return the plain text tree given input string S.
ARG is the prefix argument passed by the interactive function
that calls this function.  If it is nil, the value of
'syntree--padding-s' is a string of length 'syntree-padding'.
Otherwise, it is a string of length 'ARG'."
  ;; If the input is not valid, exit the function with a helpful
  ;; message.
  (if arg
      (setq syntree--padding-s
            (apply #'concat (make-list arg " ")))
    (setq syntree--padding-s
          (apply #'concat (make-list syntree-padding " "))))
  ;; If the input is valid, convert it into a list and
  ;; return the tree.
  (syntree--add-newlines
   (syntree--merge
    (syntree--replace-terminal-strings (read s)))))

;;; Transient

(defvar syntree--defaults '())
(defvar syntree--current '())

(defun syntree--save-defaults ()
  "Return an alist specifying the default value of each variable."
  (let ((defaults '()))
    (push (cons 'syntree-wrap syntree-wrap) defaults)
    (push (cons 'syntree-height syntree-height) defaults)
    (push (cons 'syntree-padding syntree-padding) defaults)
    (push (cons 'syntree-one-line syntree-one-line) defaults)
    (push (cons 'syntree-smooth-branches syntree-smooth-branches) defaults)
    defaults))

(transient-define-suffix syntree--set-padding (val)
  "Set the value of 'syntree-padding'.
If this function is not called as a transient suffix command, the
new value is set globally as a default for the rest of the
session."
  :description "set variable value"
  :transient t
  (interactive "nPadding amount: ")
  (let ((amount
         (if (> 1 val)
             1
           val)))
    (if syntree--defaults
        (progn
          (setf (alist-get 'syntree-padding
                           syntree--current)
                amount)
          (syntree--show-values))
      (setq syntree-padding amount)
      (message "syntree-padding set to %s" amount))))

(transient-define-suffix syntree--set-height (val)
  "Set the value of 'syntree-height'.
If this function is not called as a transient suffix command, the
new value is set globally as a default for the rest of the
session."
  :description "set variable value"
  :transient t
  (interactive "nMinimum height of branches: ")
  (let ((amount
         (if (> 1 val)
             1
           val)))
    (if syntree--defaults
        (progn
          (setf (alist-get 'syntree-height
                           syntree--current)
                amount)
          (syntree--show-values))
      (setq syntree-height amount)
      (message "syntree-height set to %s" amount))))

(transient-define-suffix syntree--set-wrap (val)
  "Set the value of 'syntree-wrap'.
If this function is not called as a transient suffix command, the
new value is set globally as a default for the rest of the
session."
  :description "set variable value"
  :transient t
  (interactive "nMaximum lenght of strings (0 means no wrapping): ")
  (let ((amount
         (if (> 1 val)
             0
           val)))
    (if syntree--defaults
        (progn
          (setf (alist-get 'syntree-wrap
                           syntree--current)
                amount)
          (syntree--show-values))
      (setq syntree-wrap amount)
      (message "syntree-wrap set to %s" amount))))

(transient-define-suffix syntree--toggle-smooth ()
  "Toggle the value of 'syntree-smooth-branches'.
If this function is not called as a transient suffix command, the
new value is set globally as a default for the rest of the
session."
  :description "set variable value"
  :transient t
  (interactive)
  (if syntree--defaults
      (let ((new-value
             (not (alist-get 'syntree-smooth-branches syntree--current))))
        (setf (alist-get 'syntree-smooth-branches
                         syntree--current)
              new-value)
        (syntree--show-values))
    (let ((new-value
           (not syntree-smooth-branches)))
      (setq syntree-smooth-branches new-value)
      (message "syntree-smooth-branches set to %s" new-value))))

(transient-define-suffix syntree--toggle-one-line ()
  "Toggle the value of 'syntree-one-line'.
If this function is not called as a transient suffix command, the
new value is set globally as a default for the rest of the
session."
  :description "set variable value"
  :transient t
  (interactive)
  (if syntree--defaults
      (let ((new-value
             (not (alist-get 'syntree-one-line syntree--current))))
        (setf (alist-get 'syntree-one-line
                         syntree--current)
              new-value)
        (syntree--show-values))
    (let ((new-value
           (not syntree-one-line)))
      (setq syntree-one-line new-value)
      (message "syntree-one-line set to %s" new-value))))

(defun syntree--show-values ()
  "Echo the current values of the relevant variables."
  (message
   "syntree-smooth-branches = %s
syntree-one-line        = %s
syntree-padding         = %s
syntree-height          = %s
syntree-wrap            = %s"
   (alist-get 'syntree-smooth-branches syntree--current)
   (alist-get 'syntree-one-line syntree--current)
   (alist-get 'syntree-padding syntree--current)
   (alist-get 'syntree-height syntree--current)
   (alist-get 'syntree-wrap syntree--current)))

;; The next four functions quit the transient, set the values of the
;; syntree variables according to the alist 'syntree--current' and
;; evaluate either 'syntree-insert' or 'syntree-kill'.  If the chosen
;; values are to be kept as the defaults for the rest of the Emacs
;; session, nothing is to be done except setting the alists
;; 'syntree--current' and 'syntree--defaults' to nil.  Otherwise, the
;; values in 'syntree--defaults' are restored before doing so.

(transient-define-suffix syntree--exit-insert-save ()
  :description "exit transient"
  (interactive)
  (transient-quit-all)
  (dolist (v syntree--current)
    (set (car v)
         (alist-get (car v) syntree--current)))
  (funcall #'syntree-insert)
  (setq syntree--current '()
        syntree--defaults '()))

(transient-define-suffix syntree--exit-kill-save ()
  :description "exit transient"
  (interactive)
  (transient-quit-all)
  (dolist (v syntree--current)
    (set (car v)
         (alist-get (car v) syntree--current)))
  (funcall #'syntree-kill)
  (setq syntree--current '()
        syntree--defaults '()))

(transient-define-suffix syntree--exit-insert ()
  :description "exit transient"
  (interactive)
  (dolist (v syntree--current)
    (set (car v)
         (alist-get (car v) syntree--current)))
  (funcall #'syntree-insert)
  (dolist (v syntree--defaults)
    (set (car v)
         (alist-get (car v) syntree--defaults)))
  (setq syntree--current '()
        syntree--defaults '()))

(transient-define-suffix syntree--exit-kill ()
  :description "exit transient"
  (interactive)
  (dolist (v syntree--current)
    (set (car v)
         (alist-get (car v) syntree--current)))
  (funcall #'syntree-kill)
  (dolist (v syntree--defaults)
    (set (car v)
         (alist-get (car v) syntree--defaults)))
  (setq syntree--current '()
        syntree--defaults '()))

(transient-define-prefix syntree--set-variables ()
  [:class transient-columns
   ["Set variables"
    ("s" "Toggle value of smooth-branches" syntree--toggle-smooth)
    ("l" "Toggle value of one-line" syntree--toggle-one-line)
    ("p" "Set amount of padding" syntree--set-padding)
    ("h" "Set minumum height of branches" syntree--set-height)
    ("w" "Set value for word-wrapping" syntree--set-wrap)]
   ["Actions"
    ("i" " Insert tree" syntree--exit-insert)
    ("k" " Kill tree" syntree--exit-kill)
    ("!i" "Insert tree and save current values" syntree--exit-insert-save)
    ("!k" "Kill tree and save current values" syntree--exit-kill-save)]])

;;; The interactive functions

;;;###autoload
(defun syntree-insert (&optional arg)
  "Insert the tree at the first empty line after point.
If there is no such line, insert it at the end of the buffer.
The optional prefix argument ARG specifies a temporary value for
the amount of padding."
  (interactive "P")
  (save-excursion
    (let ((input (syntree--get-string)))
      (unless input
        (user-error "No valid input found"))
      (unless (search-forward-regexp "^\s*$" nil t)
        (goto-char (point-max))
        (newline t nil))
      (insert (syntree--main input arg))
      (message nil))))

;;;###autoload
(defun syntree-kill (&optional arg)
  "Add the tree as latest kill to the 'kill-ring'.
The optional prefix argument ARG specifies a temporary value for
the amount of padding."
  (interactive "P")
  (save-excursion
    (let ((input (syntree--get-string)))
      (unless input
        (user-error "No valid input found"))
      (kill-new (syntree--main input arg))
      (message nil))))

;; Before invoking the transient with 'syntree--set-variables', this
;; function stores the current (i.e., the default) values of the
;; syntree variables in an association list, 'syntree--defaults', and
;; makes a copy of it, 'syntree--current'.  It is the latter that will
;; be manipulated by the suffix commands made available by
;; 'syntree--set-variables'.  The defaults are kept separate so that
;; they can be restored after the tree was generated, if the user
;; wants.  Both association list will be reset to nil automatically
;; after the tree is generated.

;;;###autoload
(defun syntree-custom ()
  "Open a transient buffer to set the syntree variables.
The default values are saved in an alist, and either restored or
not depending on the action taken once in the transient.
Evaluates 'syntree-insert' or 'syntree-kill' to generate the
output tree."
  (interactive)
  (setq syntree--defaults (syntree--save-defaults))
  (setq syntree--current (copy-alist syntree--defaults))
  (save-excursion
    (let ((input (syntree--get-string)))
      (unless input
        (user-error "No valid input found"))
      (syntree--set-variables))))

(provide 'syntree)

;;; _
;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; syntree.el ends here
