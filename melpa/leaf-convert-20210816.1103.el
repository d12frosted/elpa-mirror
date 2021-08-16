;;; leaf-convert.el --- Convert many format to leaf format  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Version: 1.3.1
;; Package-Version: 20210816.1103
;; Package-Commit: da86654f1021445cc42c1a5a9195f15097352209
;; Keywords: tools
;; Package-Requires: ((emacs "26.1") (leaf "3.6.0") (leaf-keywords "1.1.0") (ppp "2.1"))
;; URL: https://github.com/conao3/leaf-convert.el

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

;; Convert from a plain Elisp to an expression using a leaf.

;; This is accomplished by not just converting use-package's
;; keywords, but by converting them once they have been expanded
;; to a plain Elisp.

;; This may result in a simpler leaf expression, but if there is
;; no corresponding keyword, most of it will be converted to a
;; :config section.

;; Since the source is Elisp, it is possible to convert the leaf
;; to Elisp once and then convert it to leaf again.

;; This can be used to convert miscellaneous settings in the
;; :config section into leaf expressions with appropriate
;; keywords.  It is also possible to optimize settings that are
;; not needed.

;; Currently, the many ~leaf~ keywords are supported for
;; automatic conversion.

;; Please see https://github.com/conao3/leaf-convert.el to get
;; more information.


;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'package)
(require 'lisp-mnt)
(require 'thingatpt)
(require 'leaf)
(require 'leaf-keywords)
(require 'ppp)

(defgroup leaf-convert nil
  "Convert many format to leaf format."
  :prefix "leaf-convert-"
  :group 'tools
  :link '(url-link :tag "Github" "https://github.com/conao3/leaf-convert.el"))

(defcustom leaf-convert-prefer-list-keywords
  (leaf-list
   :bind :bind* :chord :chord*
   :mode :interpreter :magic :magic-fallback :hook
   :custom :custom* :custom-face :pl-custom :auth-custom
   :setq :pre-setq :setq-default
   :pl-setq :pl-pre-setq :pl-setq-default
   :auth-setq :auth-pre-setq :auth-setq-defualt)
  "Prefer list output keywords."
  :group 'leaf-convert
  :type 'sexp)

(defcustom leaf-convert-except-after
  (leaf-list
   cl-lib let-alist pkg-info json seq
   dash dash-functional s f ht ov
   bind-key async promise async-await
   memoise popup popwin request simple-httpd transient htmlize)
  "Except packages for :after keyword.
see `leaf-convert--fill-info'"
  :group 'leaf-convert
  :type 'sexp)

(defcustom leaf-convert-preface-op-list
  (leaf-list
   defun defmacro cl-defun cl-defmacro)
  "Sexp op list should be expand in :preface section."
  :group 'leaf-convert
  :type 'sexp)

(defvar leaf-convert-config-like-keywords '(:preface :init :config :mode-hook)
  "Keywords like :config.")

(defvar leaf-convert-mode-like-keywords '(:mode :interpreter :magic :magic-fallback :hook)
  "Keywords like :mode.")

(defvar leaf-convert-omit-leaf-name-keywords '(:ensure :feather :package :require :after)
  "Keywords that interpret t as leaf--name.")


;;; Patterns

(defun leaf-convert--mode-line-structp (elm &optional addquote)
  "Return non-nil if ELM is varid mode-line structure.
If ADDQUOTE is non-nill, check pattern after quoted ELM.
See https://www.gnu.org/software/emacs/manual/html_node/elisp/Mode-Line-Data.html"
  (pcase (if addquote `',elm elm)
    ((pred null) t)
    ((pred stringp) t)
    (`',(pred null) t)
    (`',(pred stringp) t)
    (`',(pred symbolp) t)
    (`'(,(pred stringp) . ,_rest) t)
    (`'(,(pred listp) . ,_rest) t)
    (`'(:eval ,_form) t)
    (`'(:propertize ,_elt . ,_props) t)
    (`'(,(pred symbolp) ,_then ,_else) t)
    (`'(,(pred integerp) . ,_rest) t)))

(defun leaf-convert-contents--parse-bind-keys (op bind-keys-args contents)
  "Parse bind-keys argument and push values to CONTENTS.
OP is bind-keys or bind-keys* symbol.
BIND-KEYS-ARGS is bind-keys' all argument."
  (let* ((keyword (pcase op ('bind-keys 'bind) ('bind-keys* 'bind*)))
         (leaf-keys-args (alist-get keyword contents))
         keyalist mapalist
         rawargs unknownfrg)
    (setq rawargs bind-keys-args)
    (while leaf-keys-args
      (pcase (pop leaf-keys-args)
        (`(,(or `,(and (pred stringp) key) `,(and (pred vectorp) key)))
         (push `(,key . nil) (alist-get 'global-map keyalist)))
        (`(,(or `,(and (pred stringp) key) `,(and (pred vectorp) key)) . ,fn)
         (push `(,key . ,fn) (alist-get 'global-map keyalist)))
        (`(,(and (pred symbolp) map) :package ,(and (pred symbolp) pkg) . ,cells)
         (when-let (p (alist-get map mapalist))
           (unless (eq p pkg)
             (setq unknownfrg t)))
         (setf (alist-get map mapalist) pkg)
         (dolist (cell cells)
           (pcase cell
             (`(,(or `,(and (pred stringp) key) `,(and (pred vectorp) key)))
              (push `(,key . nil) (alist-get map keyalist)))
             (`(,(or `,(and (pred stringp) key) `,(and (pred vectorp) key)) . ,fn)
              (push `(,key . ,fn) (alist-get map keyalist)))
             (_
              (setq unknownfrg t)))))
        (`(,(and (pred symbolp) map) . ,cells)
         (dolist (cell cells)
           (pcase cell
             (`(,(or `,(and (pred stringp) key) `,(and (pred vectorp) key)))
              (push `(,key . nil) (alist-get map keyalist)))
             (`(,(or `,(and (pred stringp) key) `,(and (pred vectorp) key)) . ,fn)
              (push `(,key . ,fn) (alist-get map keyalist)))
             (_
              (setq unknownfrg t)))))
        (_
         (setq unknownfrg t))))
    (let ((map 'global-map) pkg)
      (while bind-keys-args
        (pcase (pop bind-keys-args)
          ((or :prefix :prefix-map)
           (setq unknownfrg t))
          (:map
           (setq map (pop bind-keys-args)))
          (:package
           (setq pkg (pop bind-keys-args))
           (unless (eq 'global-map map)
             (when-let (p (alist-get map mapalist))
               (unless (eq p pkg)
                 (setq unknownfrg t)))
             (setf (alist-get map mapalist) pkg)))
          (`(,key . ,(and (pred symbolp) fn))
           (push `(,key . ,fn) (alist-get map keyalist)))
          (_
           (setq unknownfrg t)))))
    (if (and (or unknownfrg (not keyword)) rawargs)
        (push `(,op ,@rawargs) (alist-get 'config contents))
      (let (tmp)
        (setq tmp `(,@(let (lst)
                        (pcase-dolist (`(,map . ,keys) keyalist)
                          (unless (eq 'global-map map)
                            (if-let ((mappkg (alist-get map mapalist)))
                                (setf (alist-get map lst) `(:package ,mappkg ,@(nreverse (delete-dups keys))))
                              (setf (alist-get map lst) (nreverse (delete-dups keys))))))
                        (nreverse lst))
                    ,@(delete-dups (alist-get 'global-map keyalist))))
        (setf (alist-get keyword contents) tmp)))
    contents))

(defun leaf-convert-contents-new--sexp-1 (sexp contents)
  "Internal recursive function of `leaf-convert-contents-new--sexp'.
Add convert SEXP to leaf-convert-contents to CONTENTS."
  (cl-flet ((constp (elm) (pcase elm ((pred atom) t) (`(quote ,_) t) (`(function ,_) t)))
            (fnp (elm) (pcase elm ('nil t) (`(quote ,(pred symbolp)) t) (`(function ,(pred symbolp)) t)))
            (modelinep (elm) (leaf-convert--mode-line-structp elm))
            (quotemodelinep (elm) (leaf-convert--mode-line-structp elm t)))
    (pcase sexp
      ;; :load-path, :load-path*
      (`(add-to-list 'load-path ,(and (pred stringp) elm))
       (let ((relpath (file-relative-name elm user-emacs-directory)))
         (if (not (string-match "\\.\\./" relpath))
             (push relpath (alist-get 'load-path* contents))
           (push elm (alist-get 'load-path contents)))))
      (`(add-to-list 'load-path (locate-user-emacs-file ,(and (pred stringp) elm)))
       (push elm (alist-get 'load-path* contents)))
      (`(add-to-list 'load-path (concat user-emacs-directory ,(and (pred stringp) elm)))
       (push elm (alist-get 'load-path* contents)))
      (`(eval-and-compile (add-to-list 'load-path ,(and (pred stringp) elm))) ; use-package's :load-path
       (setq contents (leaf-convert-contents-new--sexp-1 `(add-to-list 'load-path ,elm) contents)))

      ;; :defun
      (`(declare-function ,(and (pred atom) elm) ,(and (pred stringp) file) . ,_args)
       (push `(,elm . ,(intern file)) (alist-get 'defun contents)))

      ;; :defvar
      (`(defvar ,(and (pred atom) elm))
       (push elm (alist-get 'defvar contents)))
      (`(defvar ,(and (pred atom) elm) ,(and (pred constp) val))
       (push `(,elm . ,val) (alist-get 'setq contents)))

      ;; :ensure
      (`(package-install ',(and (pred symbolp) elm))
       (push elm (alist-get 'ensure contents)))
      (`(use-package-ensure-elpa ',(and (pred symbolp) elm) ',val 'nil)
       (dolist (v val)
         (if (eq t v)
             (push elm (alist-get 'ensure contents))
           (push v (alist-get 'ensure contents)))))

      ;; :commands
      (`(autoload ,(or `',(and (pred symbolp) elm) `#',(and (pred symbolp) elm)) . ,_args)
       (push elm (alist-get 'commands contents)))
      (`(unless (fboundp ,(or `',(and (pred symbolp) fn) `#',(and (pred symbolp) fn)))
          (autoload ,(or `',(and (pred symbolp) elm) `#',(and (pred symbolp) elm)) . ,_args))
       (if (eq fn elm)
           (push elm (alist-get 'commands contents))
         (push sexp (alist-get 'config contents))))

      ;; :bind, :bind*
      (`(define-key global-map ,(or `(kbd ,key) `,(and (pred vectorp) key)) ,(and (pred fnp) fn))
       (push `(,key . ,(cadr fn)) (alist-get 'bind contents)))
      (`(define-key ,(or 'override-global-map 'leaf-key-override-global-map) ,(or `(kbd ,key) `,(and (pred vectorp) key)) ,(and (pred fnp) fn))
       (push `(,key . ,(cadr fn)) (alist-get 'bind* contents)))
      (`(define-key ,(and (pred symbolp) map) ,(or `(kbd ,key) `,(and (pred vectorp) key)) ,(and (pred fnp) fn))
       (push `(,map (,key . ,(cadr fn))) (alist-get 'bind contents)))
      (`(global-set-key ,(or `(kbd ,key) `,(and (pred vectorp) key) `,(and (pred stringp) key)) ,(and (pred fnp) fn))
       (setq contents (leaf-convert-contents-new--sexp-1 `(define-key global-map ,(if (stringp key) `(kbd ,key) key) ,fn) contents)))
      (`(global-unset-key ,(or `(kbd ,key) `,(and (pred vectorp) key) `,(and (pred stringp) key)))
       (setq contents (leaf-convert-contents-new--sexp-1 `(define-key global-map ,(if (stringp key) `(kbd ,key) key) nil) contents)))
      (`(bind-key ,key ,(and (pred fnp) fn))
       (setq contents (leaf-convert-contents-new--sexp-1 `(define-key global-map ,(if (stringp key) `(kbd ,key) key) ,fn) contents)))
      (`(bind-key ,key ,(and (pred fnp) fn) ,(and (pred symbolp) map))
       (setq contents (leaf-convert-contents-new--sexp-1 `(define-key ,map ,(if (stringp key) `(kbd ,key) key) ,fn) contents)))
      (`(bind-key* ,key ,(and (pred fnp) fn))
       (setq contents (leaf-convert-contents-new--sexp-1 `(define-key override-global-map ,(if (stringp key) `(kbd ,key) key) ,fn) contents)))
      (`(,(and (or 'bind-keys 'bind-keys*) op) . ,args)
       (setq contents (leaf-convert-contents--parse-bind-keys op args contents)))

      (`(leaf-key ,key ,(and (pred fnp) fn))
       (setq contents (leaf-convert-contents-new--sexp-1 `(define-key global-map ,(if (stringp key) `(kbd ,key) key) ,fn) contents)))
      (`(leaf-key ,key ,(and (pred fnp) fn) ,(and (pred symbolp) map))
       (setq contents (leaf-convert-contents-new--sexp-1 `(define-key ,map ,(if (stringp key) `(kbd ,key) key) ,fn) contents)))
      (`(leaf-key* ,key ,(and (pred fnp) fn))
       (setq contents (leaf-convert-contents-new--sexp-1 `(define-key leaf-key-override-global-map ,(if (stringp key) `(kbd ,key) key) ,fn) contents)))
      (`(leaf-keys ,spec)
       (let ((spec* (if (cdr (last spec)) (list spec) spec)))
         (dolist (elm spec*)
           (push elm (alist-get 'bind contents)))))
      (`(leaf-keys* ,spec)
       (let ((spec* (if (cdr (last spec)) (list spec) spec)))
         (dolist (elm spec*)
           (push elm (alist-get 'bind* contents)))))

      ;; :mode, :interpreter, :magic, :magic-fallback
      (`(add-to-list ',(and (or 'auto-mode-alist 'interpreter-mode-alist 'magic-mode-alist 'magic-fallback-mode-alist) lst)
                     '(,(and (pred stringp) elm) . ,(and (pred symbolp) fn)))
       (let ((key (pcase lst
                    ('auto-mode-alist 'mode)
                    ('interpreter-mode-alist 'interpreter)
                    ('magic-mode-alist 'magic)
                    ('magic-fallback-mode-alist 'magic-fallback))))
         (push `(,elm . ,fn) (alist-get key contents))))

      ;; :hook
      (`(add-hook ',(and (pred symbolp) elm) ,(or `',(and (pred symbolp) fn) `#',(and (pred symbolp) fn)))
       (push `(,elm . ,fn) (alist-get 'hook contents)))
      (`(add-hook ',(and (pred symbolp) elm) ,(or `',(and (pred symbolp) fn) `#',(and (pred symbolp) fn)) ,_append)
       (push `(,elm . ,fn) (alist-get 'hook contents)))

      ;; :custom, :custom*
      (`(customize-set-variable ',(and (pred symbolp) elm) ,(and (pred constp) val))
       (push `(,elm . ,val) (alist-get 'custom contents)))
      (`(customize-set-variable ',(and (pred symbolp) elm) ,(and (pred constp) val) ,(pred (string-match "^Customized with use-package")))
       (setq contents (leaf-convert-contents-new--sexp-1 `(customize-set-variable ',elm ,val) contents)))
      (`(customize-set-variable ',(and (pred symbolp) elm) ,(and (pred constp) val) ,(pred (string-match "^Customized with leaf")))
       (setq contents (leaf-convert-contents-new--sexp-1 `(customize-set-variable ',elm ,val) contents)))
      (`(customize-set-variable ',(and (pred symbolp) elm) ,(and (pred constp) val) ,(and (pred stringp) desc))
       (push `(,elm ,val ,desc) (alist-get 'custom* contents)))
      (`(funcall (or (get ',(and (pred symbolp) elm) 'custom-set) #'set-default) ',(and (pred symbolp) elm2) ,(and (pred constp) val))
       (if (eq elm elm2)
           (setq contents (leaf-convert-contents-new--sexp-1 `(customize-set-variable ',elm ,val) contents))
         (push sexp (alist-get 'config contents))))
      (`(custom-set-variables . ,specs)
       (dolist (spec specs)
         (pcase spec
           (`'(,(and (pred symbolp) elm) ,val ,desc)
            (setq contents (leaf-convert-contents-new--sexp-1 `(customize-set-variable ',elm ,val ,desc) contents)))
           (`'(,(and (pred symbolp) elm) ,val)
            (setq contents (leaf-convert-contents-new--sexp-1 `(customize-set-variable ',elm ,val) contents)))
           (``(,(and (pred symbolp) elm) ,(and (pred constp) val))
            (setq contents (leaf-convert-contents-new--sexp-1 `(customize-set-variable ',elm ,val) contents)))
           (_
            (push `(customize-set-variables ,spec) (alist-get 'config contents))))))

      ;; :custom-face
      (`(custom-set-faces . ,specs)
       (dolist (spec specs)
         (pcase spec
           (`'(,(and (pred symbolp) elm) ,val)
            (push `(,elm . ',val) (alist-get 'custom-face contents)))
           (`(backquote (,(and (pred symbolp) elm) ,val))          ; use-package support
            (if (memq '\, (leaf-flatten val))
                (push `(custom-set-faces (backquote (,elm ,val))) (alist-get 'config contents))
              (push `(,elm . ',val) (alist-get 'custom-face contents))))
           (_
            (push `(custom-set-faces ,spec) (alist-get 'config contents))))))

      ;; :require
      (`(require ',(and (pred symbolp) elm))
       (progn                           ; move :config sexp to :init section
         (setf (alist-get 'pre-setq contents) (alist-get 'setq contents)) (setf (alist-get 'setq contents nil 'remove) nil)
         (setf (alist-get 'init contents) (alist-get 'config contents)) (setf (alist-get 'config contents nil 'remove) nil))
       (push elm (alist-get 'require contents)))
      (`(require ',(and (pred symbolp) elm) nil ,_)
       (setq contents (leaf-convert-contents-new--sexp-1 `(require ',elm) contents)))

      ;; :chord, :chord*
      (`(key-chord-define-global ,(or (and (pred stringp) key) (and (pred vector) key)) ',(and (pred symbolp) fn))
       (push `(,key . ,fn) (alist-get 'chord contents)))
      (`(bind-chord ,(or (and (pred stringp) key) (and (pred vector) key)) ',(and (pred symbolp) fn))
       (push `(,key . ,fn) (alist-get 'chord contents)))

      ;; :diminish, :delight
      (`(,(and (or 'diminish 'delight) op) ',(and (pred symbolp) elm))
       (push elm (alist-get op contents)))
      (`(diminish ',(and (pred symbolp) elm) ,(and (pred modelinep) val))
       (push `(,elm . ,val) (alist-get 'diminish contents)))
      (`(delight ',(and (pred symbolp) elm) ,(and (pred modelinep) val))
       (push `(,elm ,val) (alist-get 'delight contents)))
      (`(delight ',(and (pred symbolp) elm) ,(and (pred modelinep) val) :major)
       (push `(,elm ,val :major) (alist-get 'delight contents)))
      (`(delight ',(and (pred symbolp) elm) ,(and (pred modelinep) val) ,(or (and (pred stringp) pkg) `',(and (pred symbolp) pkg)))
       (push `(,elm ,val ,pkg) (alist-get 'delight contents)))
      (`(delight ',(and (pred listp) spec))
       (dolist (args spec)
         (pcase args
           (`(,(and (pred symbolp) mode))
            (setq contents (leaf-convert-contents-new--sexp-1 `(delight ',mode) contents)))
           (`(,(and (pred symbolp) mode) ,(and (pred quotemodelinep) val))
            (setq contents (leaf-convert-contents-new--sexp-1 `(delight ',mode ,(if (or (stringp val) (null val)) val `',val)) contents)))
           (`(,(and (pred symbolp) mode) ,(and (pred quotemodelinep) val) ,(and (pred symbolp) pkg))
            (setq contents (leaf-convert-contents-new--sexp-1 `(delight ',mode ,(if (or (stringp val) (null val)) val `',val) ',pkg) contents)))
           (`(,(and (pred symbolp) mode) ,(and (pred quotemodelinep) val) ,(and (pred stringp) file))
            (setq contents (leaf-convert-contents-new--sexp-1 `(delight ',mode ,(if (or (stringp val) (null val)) val `',val) ,file) contents)))
           (_ (push `(delight '(,args)) (alist-get 'config contents))))))

      ;; :setq, :setq-default
      (`(,(and (or 'setq 'setq-default) op) ,(and (pred atom) elm) ,(and (pred constp) val))
       (push `(,elm . ,val) (alist-get op contents)))
      (`(,(and (or 'setq 'setq-default) op) ,sym ,val . ,(and (pred identity) args))
       (setq contents (leaf-convert-contents-new--sexp-1 `(,op ,sym ,val) contents))
       (setq contents (leaf-convert-contents-new--sexp-1 `(,op ,@args) contents)))

      ;; special Sexp will expand :preface
      (`(,(pred (lambda (elm) (memq elm leaf-convert-preface-op-list))) . ,_body)
       (push sexp (alist-get 'preface contents)))

      ;; use-package, leaf
      (`(,(or 'use-package 'leaf) ,(and (pred symbolp) pkg) . ,_body)
       (let* ((form (leaf-convert--expand-use-package sexp))
              (target (pcase form
                        (`(progn . ,body) `(prog1 ',pkg ,@body))
                        (_ `(prog1 ',pkg ,form))))
              (leaf* (eval `(leaf-convert-from-contents (leaf-convert-contents-new--sexp ,target)))))
         (push leaf* (alist-get 'config contents))))

      ;; any
      (_ (push sexp (alist-get 'config contents)))))
  contents)

(defun leaf-convert-contents-new--sexp-internal (sexp &optional contents toplevel)
  "Internal function of `leaf-convert-contents-new--sexp'.
Convert SEXP to leaf-convert-contents.
If specified CONTENTS, add value to it instead of create new instance.
When TOPLEVEL is non-nil, it converts sexp, which affects the
whole block like `eval-after-load', into leaf keyword.'"
  (pcase sexp
    ;; leaf--name, progn
    (`(prog1 ,(or `',name (and (pred stringp) name)) . ,body)
     (setf (alist-get 'leaf-convert--name contents) (leaf-convert--symbol-from-string name))
     (setq contents (leaf-convert-contents-new--sexp-internal `(progn ,@body) contents toplevel)))

    ;; progn
    (`(progn . ,body)
     (dolist (elm body)
       (setq contents (leaf-convert-contents-new--sexp-internal elm contents (and toplevel (equal elm (car body)))))))

    ;; :when, :unless, :if
    (`(unless (fboundp ,(or `',(and (pred symbolp) fn) `#',(and (pred symbolp) fn))) ; use-pakage :commands idiom
        (autoload ,(or `',(and (pred symbolp) elm) `#',(and (pred symbolp) elm)) . ,_args))
     (if (eq fn elm)
         (push elm (alist-get 'commands contents))
       (push sexp (alist-get 'config contents))))
    (`(when (fboundp ',(and (or 'diminish 'delight) fn)) (,(and (or 'diminish 'delight) op) . ,body))
     (if (eq fn op)
         (setq contents (leaf-convert-contents-new--sexp-1 `(,op ,@body) contents))
       (push sexp (alist-get 'config contents))))

    (`(,(and (or 'when 'unless) op) (symbol-value ',sym) . ,body)
     (setq contents (leaf-convert-contents-new--sexp-internal `(,(if (eq 'when op) 'when 'unless) ,sym ,@body) contents toplevel)))
    (`(,(and (or 'when 'unless) op) (not ,condition) . ,body)
     (setq contents (leaf-convert-contents-new--sexp-internal `(,(if (eq 'when op) 'unless 'when) ,condition ,@body) contents toplevel)))
    (`(,(and (or 'when 'unless) op) (and . ,conditions) . ,body)
     (let ((toplevel* (or toplevel)))   ; TODO
       (if (not toplevel*)
           (push sexp (alist-get 'config contents))
         (let ((form body))
           (dolist (elm (reverse conditions))
             (setq form `((,(if (eq 'when op) 'when 'unless) ,elm ,@form))))
           (setq contents (leaf-convert-contents-new--sexp-internal (car form) contents toplevel))))))
    (`(,(and (or 'when 'unless) op) ,condition . ,body)
     (let ((toplevel* (or toplevel)))   ; TODO
       (if (not toplevel*)
           (push sexp (alist-get 'config contents))
         (push condition (alist-get (if (eq 'when op) 'when 'unless) contents))
         (setq contents (leaf-convert-contents-new--sexp-internal `(progn ,@body) contents toplevel*)))))
    (`(if ,condition ,body)
     (setq contents (leaf-convert-contents-new--sexp-internal `(when ,condition ,body) contents toplevel)))
    (`(if ,condition ,body nil)
     (setq contents (leaf-convert-contents-new--sexp-internal `(when ,condition ,body) contents toplevel)))
    (`(if ,condition nil . ,body)
     (setq contents (leaf-convert-contents-new--sexp-internal `(when (not ,condition) ,@body) contents toplevel)))
    (`(if . ,_body)
     (push sexp (alist-get 'config contents)))

    ;; leaf--name, :after
    (`(with-eval-after-load ,(or `',name (and (pred stringp) name))
        . ,body)
     (setq contents (leaf-convert-contents-new--sexp-internal `(eval-after-load ',name '(progn ,@body)) contents toplevel)))

    ;; leaf--name, :after
    (`(eval-after-load ,(or `',name (and (pred stringp) name))
        ',body)
     (let ((toplevel* (or toplevel)))   ; TODO
       (if (not toplevel*)
           (push sexp (alist-get 'config contents))
         (unless (alist-get 'leaf-convert--name contents)
           (setf (alist-get 'leaf-convert--name contents) (leaf-convert--symbol-from-string name)))
         (push name (alist-get 'after contents))
         (setq contents (leaf-convert-contents-new--sexp-internal body contents toplevel)))))

    ;; any
    (_ (setq contents (leaf-convert-contents-new--sexp-1 sexp contents))))
  contents)

(defmacro leaf-convert-contents-new--sexp (sexp &optional contents)
  "Convert SEXP to leaf-convert-contents.
If specified CONTENTS, add value to it instead of new instance."
  `(leaf-convert-contents-new--sexp-internal ',sexp ,contents 'toplevel))

(defun leaf-convert--fill-info (contents)
  "Add :doc, :file, :url information to CONTENTS."
  ;; see `describe-package-1'
  (let* ((pkg (alist-get 'leaf-convert--name contents))
         (desc (when pkg
                 (or
                  (if (package-desc-p pkg) pkg)
                  (cadr (assq pkg package-alist))
                  (let ((built-in (assq pkg package--builtins)))
                    (if built-in
                        (package--from-builtin built-in)
                      (cadr (assq pkg package-archive-contents)))))))
         docs reqs tags files urls)
    (cond
     ((and (not pkg)))
     ((and pkg (not desc))
      (if-let (file (locate-file (format "%s.el" pkg) load-path load-file-rep-suffixes))
          (with-temp-buffer
            (insert-file-contents file)
            (push file files)
            (push (lm-summary) docs)
            (push (lm-homepage) urls)
            (dolist (keyword (lm-keywords-list)) (push keyword tags))
            (setq reqs (when-let (str (lm-header "package-requires"))
                         (mapcar #'(lambda (elt) `(,(car elt) ,(version-to-list (cadr elt))))
                                 (package--prepare-dependencies
                                  (package-read-from-string str)))))
            (if (or (package-built-in-p pkg) (string-match-p "/share/" file))
                (push "builtin" tags)
              (push "out-of-MELPA" tags)
              (push pkg (alist-get 'require contents))
              (push (intern (format "{{user}}/%s" pkg)) (alist-get 'el-get contents))))
        (push "out-of-MELPA" tags)
        (push pkg (alist-get 'require contents))
        (push (intern (format "{{user}}/%s" pkg)) (alist-get 'el-get contents))))
     ((and pkg desc)
      (push (package-desc-summary desc) docs)
      (push (locate-file (format "%s.el" pkg) load-path load-file-rep-suffixes) files)
      (push (cdr (assoc :url (package-desc-extras desc))) urls)
      (dolist (keyword (package-desc--keywords desc)) (push keyword tags))
      (setq reqs (package-desc-reqs desc))
      (if (package-built-in-p desc)
          (push "builtin" tags)
        (push pkg (alist-get 'ensure contents)))))

    (push (format-time-string "%Y-%m-%d") (alist-get 'added contents))
    (dolist (doc docs)   (when doc (push doc (alist-get 'doc contents))))
    (dolist (tag tags)   (when tag (push tag (alist-get 'tag contents))))
    ;; (dolist (file files) (when file (push (concat "~/" (file-relative-name file "~/")) (alist-get 'file contents))))
    (dolist (url urls)   (when url (push url (alist-get 'url contents))))
    
    (dolist (elm reqs)
      (pcase elm
        (`(emacs ,ver)
         (let ((ver* (string-join (mapcar 'number-to-string ver) ".")))
           (push (format "emacs>=%s" ver*) (alist-get 'tag contents))
           (push (format "emacs-%s" ver*) (alist-get 'req contents))
           (push (string-to-number ver*) (alist-get 'emacs>= contents))))
        (`(,pkg ,ver)
         (let ((ver* (string-join (mapcar 'number-to-string ver) ".")))
           (push (format "%s-%s" pkg ver*) (alist-get 'req contents))
           (unless (memq pkg leaf-convert-except-after)
             (push pkg (alist-get 'after contents)))))))
    contents))

;;;###autoload
(defun leaf-convert-insert-template (pkg)
  "Insert template `leaf' block for PKG using package.el cache.
And kill generated leaf block to quick yank."
  (interactive
   ;; see `package-install'
   (progn
     ;; Initialize the package system to get the list of package
     ;; symbols for completion.
     (unless package--initialized
       (package-initialize t))
     (unless package-archive-contents
       (package-refresh-contents))
     (list (intern (completing-read
                    "Package name: "
                    (thread-last (append
                                  (mapcar (lambda (elm) (symbol-name (car elm))) package-archive-contents)

                                  ;; see `load-library'
                                  (locate-file-completion-table load-path (get-load-suffixes) "" nil t))
                      (mapcar (lambda (elm) (if (string-suffix-p "/" elm) nil elm)))
                      (delete-dups)))))))
  (let ((standard-output (current-buffer)))
    (thread-last (leaf-convert-contents-new--sexp-internal `(prog1 ',pkg) nil 'toplevel)
      (leaf-convert--fill-info)
      (leaf-convert-from-contents)
      (ppp-sexp)))
  (delete-char -1)
  (backward-sexp)
  (indent-sexp)
  (forward-sexp))


;;; Functions

(defvar leaf-expand-minimally)
(defvar use-package-expand-minimally)
(defvar use-package-ensure-function)

(defun leaf-convert--expand-use-package (sexp)
  "Macroexpand-1 for use-package SEXP.

  (ppp-sexp
   (macroexpand-1
    '(use-package color-moccur
       :commands isearch-moccur
       :config
       (use-package moccur-edit))))
  ;;=> (progn
  ;;     (unless (fboundp 'isearch-moccur)
  ;;       (autoload #'isearch-moccur \"color-moccur\" nil t))
  ;;     (eval-after-load 'color-moccur
  ;;       '(progn
  ;;          (require 'moccur-edit nil nil)
  ;;          t)))
  
  (ppp-sexp
   (leaf-convert--expand-use-package
    '(use-package color-moccur
       :commands isearch-moccur
       :config
       (use-package moccur-edit))))
  ;;=> (progn
  ;;     (unless (fboundp 'isearch-moccur)
  ;;       (autoload #'isearch-moccur \"color-moccur\" nil t))
  ;;     (eval-after-load 'color-moccur
  ;;       '(progn
  ;;          (use-package moccur-edit)
  ;;          t)))"
  (let* ((op (car sexp))
         (sym (gensym))
         (form (thread-last sexp
                 (cl-subst sym 'use-package)
                 (funcall (lambda (elm) (setf (car elm) op) elm))
                 (funcall (lambda (elm)
                            (let ((use-package-expand-minimally t)
                                  (leaf-expand-minimally t))
                              (macroexpand-1 elm))))
                 (cl-subst 'use-package sym)))
         (form* (thread-last sexp
                  (cl-subst sym 'use-package)
                  (funcall (lambda (elm) (setf (car elm) op) elm))
                  (funcall (lambda (elm)
                             (let ((use-package-expand-minimally t)
                                   (leaf-expand-minimally t)
                                   (byte-compile-current-file t)  ; use-package hack
                                   (use-package-ensure-function 'ignore))
                               (macroexpand-1 elm))))
                  (cl-subst 'use-package sym)))
         extra)
    (dolist (elm form*)
      (pcase elm
        (`(eval-and-compile . ,forms)
         (dolist (e forms)
           (pcase e
             (`(defvar ,(and (pred symbolp) sym))
              (push `(defvar ,sym) extra)))))))
    (pcase form
      (`(progn . ,body)
       (if extra `(progn ,@(nreverse extra) ,@body) form))
      (_
       (if extra `(progn ,@(nreverse extra) ,form) form)))))

(defun leaf-convert--symbol-from-string (elm)
  "Convert ELM to symbol.  If ELM is nil, return DEFAULT.
ELM can be string or symbol."
  (if (stringp elm) (intern elm) elm))

(defun leaf-convert--optimize-over-keyword (contents)
  "Optimize CONTENTS over keyword.

:commands
  - The elements can be omitted for :bind, :bind* functions.
  - The elements can be omitted for cdr of :mode like keywords arguments.
  - The elements can be omitted if the mode symbol could be guessed.

:mode :interpreter :magic :magic-fallback
  - The pair's cdr can be omitted if the same as leaf--name.
  - The pair's cdr can be omitted if the mode symbol could be guessed.

:defun
  - The pair's cdr can be omitted if the mode symbol could be guessed."
  (let ((name (alist-get 'leaf-convert--name contents))
        (keys (mapcar #'car contents)))
    (when (and (memq 'commands keys)
               (leaf-list-memq (append '(bind bind*)
                                       (mapcar #'leaf-sym-from-keyword leaf-convert-mode-like-keywords))
                               keys))
      (setf (alist-get 'commands contents)
            (cl-set-difference
             (alist-get 'commands contents)
             (append (cadr (eval `(leaf-keys ,(alist-get 'bind contents) 'dryrun)))
                     (cadr (eval `(leaf-keys ,(alist-get 'bind* contents) 'dryrun)))
                     (let (ret)
                       (dolist (key (mapcar #'leaf-sym-from-keyword leaf-convert-mode-like-keywords))
                         (dolist (elm (alist-get key contents))
                           (pcase elm
                             (`(,(and (pred stringp) _fn) . ,sym)
                              (push sym ret)))))
                       ret)))))

    (when (and (memq 'leaf-convert--name keys)
               (leaf-list-memq keys (mapcar #'leaf-sym-from-keyword leaf-convert-mode-like-keywords)))
      (dolist (key (mapcar #'leaf-sym-from-keyword leaf-convert-mode-like-keywords))
        (when (memq key keys)
          (let (tmp)
            (dolist (pair (alist-get key contents))
              (if (and (listp pair) (eq (leaf-mode-sym (cdr pair)) (leaf-mode-sym name)))
                  (push (car pair) tmp)
                (push pair tmp)))
            (setf (alist-get key contents) (nreverse tmp))))))

    (when (and (memq 'leaf-convert--name keys)
               (leaf-list-memq keys (mapcar #'leaf-sym-from-keyword leaf-convert-mode-like-keywords)))
      (let (guessp)                 ; t means, use guess major-mode feature
        (dolist (key (mapcar #'leaf-sym-from-keyword leaf-convert-mode-like-keywords))
          (when (memq key keys)
            (dolist (pair (alist-get key contents))
              (unless (listp pair)
                (setq guessp t)))))
        (when guessp
          (setf (alist-get 'commands contents)
                (delq (leaf-mode-sym (alist-get 'leaf-convert--name contents)) (alist-get 'commands contents))))))

    (when (and (memq 'leaf-convert--name keys) (memq 'defun keys))
      (let (tmp)
        (dolist (pair (alist-get 'defun contents))
          (if (and (leaf-pairp pair) (eq (cdr pair) name))
              (push (car pair) tmp)
            (push pair tmp)))
        (setf (alist-get 'defun contents) (nreverse tmp))))

    contents))

(defun leaf-convert--convert-eval-after-load (key val)
  "Convert `eval-after-load' to `with-eval-after-load' for VAL.
If KEY is the member of :preface :init :config."
  (if (not (memq key leaf-convert-config-like-keywords))
      val
    (let (val*)
      (dolist (elm val)
        (pcase elm
          (`(eval-after-load ,(or `',name (and (pred stringp) name))
              ',body)
           (push `(with-eval-after-load ',name
                    ,@(pcase body
                        (`(progn . ,body*)
                         (leaf-convert--remove-constant :config body*))
                        (_ `(,body))))
                 val*))
          (_ (push elm val*))))
      (nreverse val*))))

(defun leaf-convert--remove-constant (key val)
  "Remove constant in VAL if KEY is the member of remove-constant-keywords."
  (if (not (memq key leaf-convert-config-like-keywords))
      val
    (thread-last val
      (mapcar (lambda (elm) (if (atom elm) nil elm)))
      (delq nil))))

(defun leaf-convert--omit-leaf-name (pkg key val)
  "Convert PKG symbol to t if KEY is the menber of omittable-keywords.
KEY and VAL is the key and value currently trying to convert.
CONTENTS is the value of all the leaf-convert-contents.

If VAL contains the same value as leaf--name, replace it with t."
  (pcase (list
          (memq key leaf-convert-omit-leaf-name-keywords)
          (memq pkg val))
    (`(nil ,_) val)
    (`(,_ nil) val)
    (`(,_ ,_)  (append '(t) (delq pkg val)))))


;;; Main

(defun leaf-convert-from-contents (contents)
  "Convert CONTENTS (as leaf-convert-contents) to leaf format."
  (unless leaf-keywords-init-frg
    (leaf-keywords-init))
  (let ((pkg (or (alist-get 'leaf-convert--name contents) 'leaf-convert))
        (all-keywords (leaf-available-keywords)))
    (when-let (unknown (thread-last (mapcar #'car contents)
                         (mapcar (lambda (key)
                                   (unless (memq (intern (format ":%s" key)) all-keywords) key)))
                         (delq 'leaf-convert--name)
                         (delq nil)))
      (error "Unknown keyword%s included.  Unknown: %s"
             (if (= 1 (length unknown)) "" "s") unknown))
    (if-let ((body (and (equal '(config) (mapcar #'car contents))
                        (pcase (alist-get 'config contents)
                          (`((leaf . ,body)) body)))))
        `(leaf ,@body)
      `(leaf ,pkg
         ,@(let ((contents* (leaf-convert--optimize-over-keyword contents)))
             (mapcan
              (lambda (key)
                (when-let* ((value (alist-get (leaf-sym-from-keyword key) contents*))
                            (value* (thread-last value
                                      (nreverse)
                                      (leaf-convert--convert-eval-after-load key)
                                      (leaf-convert--omit-leaf-name pkg key)
                                      (leaf-convert--remove-constant key)
                                      (delete-dups))))
                  (if (memq key leaf-convert-prefer-list-keywords)
                      `(,key ,value*)
                    `(,key ,@value*))))
              all-keywords))))))

;;;###autoload
(defmacro leaf-convert (&rest body)
  "Convert BODY as plain Elisp to leaf format."
  `(leaf-convert-from-contents
    (leaf-convert-contents-new--sexp (progn ,@body))))

;;;###autoload
(defun leaf-convert-region-replace (beg end)
  "Replace Elisp BEG to END to leaf format.

This command support prefix argument.
  - With a normal, replace region with converted leaf form.
  - With a `\\[universal-argument]', insert converted leaf form after region."
  (interactive "r")
  (let* ((str (format "(progn %s)" (buffer-substring beg end)))
         (form (read str))
         (res (eval `(leaf-convert ,form))))
    (if (null current-prefix-arg)
        (delete-region beg end)
      (goto-char end)
      (newline))
    (insert (ppp-sexp-to-string res))
    (delete-char -1)
    (indent-region
     (save-excursion (thing-at-point--beginning-of-sexp) (point)) (point))))

;;;###autoload
(defun leaf-convert-region-pop (beg end)
  "Pop a buffer showing the result of converting Elisp BEG to END to a leaf."
  (interactive "r")
  (let* ((str (format "(progn\n%s)" (buffer-substring beg end)))
         (form (read str))
         (res (eval `(leaf-convert ,form))))
    (with-current-buffer (get-buffer-create "*leaf-convert*")
      (let ((inhibit-read-only t)
            (str (with-temp-buffer
                   (insert ";; Converted Leaf form\n")
                   (insert ";; --------------------------------------------------\n")
                   (insert (ppp-sexp-to-string res))
                   (insert "\n\n")
                   (insert ";; Selected Elisp\n")
                   (insert ";; --------------------------------------------------\n")
                   (insert str)
                   (emacs-lisp-mode)
                   (font-lock-mode)
                   (font-lock-default-fontify-buffer)
                   (indent-region (point-min) (point-max))
                   (buffer-string))))
        (erase-buffer)
        (insert str)
        (help-mode)
        (pop-to-buffer (current-buffer))))))

;;;###autoload
(defun leaf-convert-buffer-replace ()
  "Replace Elisp buffer to leaf form."
  (interactive)
  (leaf-convert-region-replace (point-min) (point-max)))

;;;###autoload
(defun leaf-convert-buffer-pop ()
  "Pop converted leaf buffer from Elisp buffer."
  (interactive)
  (leaf-convert-region-pop (point-min) (point-max)))

(provide 'leaf-convert)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; leaf-convert.el ends here
