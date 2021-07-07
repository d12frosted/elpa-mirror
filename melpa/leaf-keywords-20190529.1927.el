;;; leaf-keywords.el --- Additional keywords for leaf.el       -*- lexical-binding: t; -*-

;; Copyright (C) 2018  Naoya Yamashita

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Maintainer: Naoya Yamashita <conao3@gmail.com>
;; Keywords: lisp settings
;; Package-Version: 20190529.1927
;; Package-Commit: 9352716f153582cdf801a13e17dc04cfcd2bb951
;; Version: 1.1.0
;; URL: https://github.com/conao3/leaf-keywords.el
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

;; simpify init.el

;;; Code:

(require 'leaf)

(defgroup leaf-keywords nil
  "Additional keywords for `leaf'."
  :group 'lisp)

(defconst leaf-keywords-raw-keywords leaf-keywords
  "Raw `leaf-keywords' before this package change.")

(defconst leaf-keywords-raw-normalize leaf-normalize
  "Raw `leaf-normalize' before this package change.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Additional keywords, normalize
;;

(defvar leaf-keywords-init-frg nil)
(defun leaf-keywords-set-keywords (sym val)
  "Set SYM as VAL and modify `leaf-keywords'."
  (set-default sym val)
  (when leaf-keywords-init-frg
    (leaf-keywords-init)))

(defun leaf-keywords-set-normalize (sym val)
  "Set SYM as VAL and modify `leaf-normalize'."
  (set-default sym val)
  (when leaf-keywords-init-frg
    (leaf-keywords-init)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Actual implementation
;;

(defcustom leaf-keywords-before-conditions
  (cdr nil)
  "Additional `leaf-keywords' before conditional branching.
:disabled :leaf-protect ... :preface <this place> :when :unless :if"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-after-conditions
  (cdr
   '(:dummy
     :el-get `((eval-after-load 'el-get
                 '(progn ,@(mapcar (lambda (elm) `(el-get-bundle ,@elm)) leaf--value)))
               ,@leaf--body)))
  "Additional `leaf-keywords' after conditional branching.
:when :unless :if :ensure <this place> :after"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-before-load
  (cdr
   '(:dummy
     :diminish   `((eval-after-load 'diminish
                     '(progn ,@(mapcar (lambda (elm) `(diminish ,@elm)) leaf--value)))
                   ,@leaf--body)
     :delight    `((eval-after-load 'delight
                     '(progn ,@(mapcar (lambda (elm) `(delight ,@elm)) leaf--value)))
                   ,@leaf--body)
     :hydra      (progn
                   (leaf-register-autoload (cadr leaf--value) leaf--name)
                   `((eval-after-load 'hydra
                       '(progn ,@(mapcar (lambda (elm) `(defhydra ,@elm)) (car leaf--value))))
                     ,@leaf--body))
     :combo      (progn
                   (leaf-register-autoload (cadr leaf--value) leaf--name)
                   `((eval-after-load 'key-combo
                       '(progn ,@(mapcar (lambda (elm) `(key-combo-define ,@elm)) (car leaf--value))))
                     ,@leaf--body))
     :combo*     (progn
                   (leaf-register-autoload (cadr leaf--value) leaf--name)
                   `((eval-after-load 'key-combo
                       '(progn ,@(mapcar (lambda (elm) `(key-combo-define ,@elm)) (car leaf--value))))
                     ,@leaf--body))
     :smartrep   (progn
                   (leaf-register-autoload (cadr leaf--value) leaf--name)
                   `((eval-after-load 'smartrep
                       '(progn ,@(mapcar (lambda (elm) `(smartrep-define-key ,@elm)) (car leaf--value))))
                     ,@leaf--body))
     :smartrep*  (progn
                   (leaf-register-autoload (cadr leaf--value) leaf--name)
                   `((eval-after-load 'smartrep
                       '(progn ,@(mapcar (lambda (elm) `(smartrep-define-key ,@elm)) (car leaf--value))))
                     ,@leaf--body))
     :chord      (progn
                   (leaf-register-autoload (cadr leaf--value) leaf--name)
                   `((eval-after-load 'key-chord
                       '(progn (leaf-key-chords ,(car leaf--value))))
                     ,@leaf--body))
     :chord*     (progn
                   (leaf-register-autoload (cadr leaf--value) leaf--name)
                   `((eval-after-load 'key-chord
                       '(progn (leaf-key-chords* ,(car leaf--value))))
                     ,@leaf--body))))
  "Additional `leaf-keywords' after wait loading.
:after ... <this place> :leaf-defer"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-after-load
  (cdr nil)
  "Additional `leaf-keywords' after wait loading.
:leaf-defer ... <this place> :init :require"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-after-require
  (cdr nil)
  "Additional `leaf-keywords' after wait loading.
:require ... <this place> :config"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-normalize
  '(((memq leaf--key '())
     ;; Accept: 't, 'nil, symbol and list of these (and nested)
     ;; Return: symbol list.
     ;; Note  : 't will convert to 'leaf--name
     ;;         if 'nil placed on top, ignore all argument
     ;;         remove duplicate element
     (let ((ret (leaf-flatten leaf--value)))
       (if (eq nil (car ret))
           nil
         (delete-dups (delq nil (leaf-subst t leaf--name ret))))))

    ((memq leaf--key '(:chord :chord*))
     ;; Accept: list of pair (bind . func), (bind . nil)
     ;;         ([:{{hoge}}-map] [:package {{pkg}}](bind . func) (bind . func) ...)
     ;;         optional, [:{{hoge}}-map] [:package {{pkg}}]
     ;; Return: list of ([:{{hoge}}-map] [:package {{pkg}}] (bind . func))
     (eval `(leaf-key-chords ,leaf--value ,leaf--name)))

    ((memq leaf--key '())
     ;; Accept: (sym . val), ((sym sym ...) . val), (sym sym ... . val)
     ;; Return: list of pair (sym . val)
     ;; Note  : atom ('t, 'nil, symbol) is just ignored
     ;;         remove duplicate configure
     (mapcar (lambda (elm)
               (cond
                ((leaf-pairp elm)
                 (if (eq t (car elm)) `(,leaf--name . (cdr elm)) elm))
                ((memq leaf--key '())
                 (if (eq t elm) `(,leaf--name . nil) `(,elm . nil)))
                ((memq leaf--key '())
                 `(,elm . ,leaf--name))
                ((memq leaf--key '())
                 elm)
                (t
                 elm)))
             (mapcan (lambda (elm)
                       (leaf-normalize-list-in-list elm 'dotlistp))
                     leaf--value)))

    ((memq leaf--key '(:hydra))
     (let ((fn (lambda (elm)
                 (mapcar (lambda (el) (cadr el))
                         (if (stringp (nth 2 elm)) (nthcdr 3 elm) (nthcdr 2 elm)))))
           (val) (fns))
       (setq val (mapcan
                  (lambda (elm)
                    (cond
                     ((and (listp elm) (listp (car elm)))
                      (progn (mapc (lambda (el) (setq fns (append fns (funcall fn el)))) elm) elm))
                     ((listp elm)
                      (progn (setq fns (append fns (funcall fn elm))) `(,elm)))))
                  leaf--value))
       `(,val ,fns)))

    ((memq leaf--key '(:combo :combo*))
     (let ((map (if (eq :combo leaf--key) 'global-map 'leaf-key-override-global-map))
           (val) (fns))
       (setq val (mapcan
                  (lambda (elm)
                    (cond
                     ((and (listp elm)
                           (listp (car elm))
                           (listp (caar elm)))
                      (mapcan
                       (lambda (el)
                         (let ((emap  (and (symbolp (car el)) (car el)))   ; el's map
                               (binds (if (leaf-pairp (car el)) el (cdr el))))
                           (mapcar
                            (lambda (el)
                              (setq fns (append fns (if (listp (cdr el)) (cdr el) `(,(cdr el)))))
                              `(,(or emap map) ,(car el) ,(if (stringp (cdr el)) (cdr el) `',(cdr el))))
                            binds)))
                       elm))
                     ((listp elm)
                      (let ((emap  (and (symbolp (car elm)) (car elm)))    ; elm's map
                            (binds (if (leaf-pairp (car elm)) elm (cdr elm))))
                        (mapcar
                         (lambda (el)
                           (setq fns (append fns (if (listp (cdr el)) (cdr el) `(,(cdr el)))))
                           `(,(or emap map) ,(car el) ,(if (stringp (cdr el)) (cdr el) `',(cdr el))))
                         binds)))))
                  leaf--value))
       `(,val ,(delq nil (mapcar (lambda (elm) (when (symbolp elm) elm)) fns)))))

    ((memq leaf--key '(:smartrep :smartrep*))
     (let ((map (if (eq :smartrep leaf--key) 'global-map 'leaf-key-override-global-map))
           (val) (fns))
       (setq val (mapcan
                  (lambda (elm)
                    (cond
                     ((and (listp elm) (listp (car elm)))
                      (mapcar
                       (lambda (el)
                         (let ((a (nth 0 el))
                               (b (nth 1 el))
                               (c (nth 2 el)))
                           (and (listp b) (eq 'quote (car b)) (setq b (eval b)))
                           (and (listp c) (eq 'quote (car c)) (setq c (eval c)))
                           (if (stringp (car el))
                               (progn (setq fns (append fns (mapcar #'cdr b))) `(,map ,a ',b))
                             (progn (setq fns (append fns (mapcar #'cdr c))) `(,a ,b ',c)))))
                       elm))
                     ((listp elm)
                      (let ((a (nth 0 elm))
                            (b (nth 1 elm))
                            (c (nth 2 elm)))
                        (and (listp b) (eq 'quote (car b)) (setq b (eval b)))
                        (and (listp c) (eq 'quote (car c)) (setq c (eval c)))
                        (if (stringp (car elm))
                            (progn (setq fns (append fns (mapcar #'cdr b))) `((,map ,a ',b)))
                          (progn (setq fns (append fns (mapcar #'cdr c))) `((,a ,b ',c))))))))
                  leaf--value))
       `(,val ,(delq nil (mapcar
                          (lambda (elm)
                            (cond ((symbolp elm) elm)
                                  ((and (listp elm) (eq 'quote (car elm))) (eval elm))))
                          fns)))))

    ((memq leaf--key '(:delight))
     (mapcan
      (lambda (elm)
        (cond
         ((eq t elm) `((',leaf--name)))
         ((symbolp elm) `((',elm)))
         ((stringp elm) `((',leaf--name ,elm)))
         ((and (listp elm) (listp (car elm))) (mapcar (lambda (el) `(',(car el) ,@(cdr el))) elm))
         ((listp elm) `((',(car elm) ,@(cdr elm))))))
      leaf--value))

    ((memq leaf--key '(:diminish))
     (mapcar
      (lambda (elm) (if (stringp (car elm)) `(,leaf--name ,(car elm)) elm))
      (mapcar
       (lambda (elm)
         (leaf-normalize-list-in-list (if (eq t elm) leaf--name elm) 'allow-dotlist))
       leaf--value)))

    ((memq leaf--key '(:el-get))
     (mapcar
      (lambda (elm)
        (leaf-normalize-list-in-list (if (eq t elm) leaf--name elm) 'allow-dotlist))
      leaf--value)))
  "Additional `leaf-normalize'."
  :set #'leaf-keywords-set-normalize
  :type 'sexp
  :group 'leaf-keywords)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Support functions
;;

(defmacro leaf-key-chord (chord command &optional keymap)
  "Bind CHORD to COMMAND in KEYMAP (`global-map' if not passed).

CHORD must be 2 length of string
COMMAND must be an interactive function or lambda form.

KEYMAP, if present, should be a keymap and not a quoted symbol.
For example:
  (leaf-key-chord \"jk\" 'undo 'c-mode-map)"
  (let ((key1 (logand 255 (aref chord 0)))
        (key2 (logand 255 (aref chord 1))))
    (if (eq key1 key2)
        `(leaf-key [key-chord ,key1 ,key2] ,command ,keymap)
      `(progn
         (leaf-key [key-chord ,key1 ,key2] ,command ,keymap)
         (leaf-key [key-chord ,key2 ,key1] ,command ,keymap)))))

(defmacro leaf-key-chord* (key command)
  "Similar to `leaf-key-chord', but overrides any mode-specific bindings.
Bind COMMAND at KEY."
  `(leaf-key-chord ,key ,command 'leaf-key-override-global-map))

(defmacro leaf-key-chords (bind &optional dryrun-name)
  "Bind multiple BIND for KEYMAP defined in PKG.
BIND is (KEY . COMMAND) or (KEY . nil) to unbind KEY.
This macro is minor change version form `leaf-keys'.

OPTIONAL:
  BIND also accept below form.
    (:{{map}} :package {{pkg}} (KEY . COMMAND) (KEY . COMMAND))
  KEYMAP is quoted keymap name.
  PKG is quoted package name which define KEYMAP.
  (wrap `eval-after-load' PKG)

  If DRYRUN-NAME is non-nil, return list like
  (LEAF_KEYS-FORMS (FN FN ...))

  If omit :package of BIND, fill it in LEAF_KEYS-FORM.

NOTE: BIND can also accept list of these."
  (let ((pairp (lambda (x)
                 (condition-case _err
                     (and (listp x)
                          (or (stringp (eval (car x)))
                              (vectorp (eval (car x))))
                          (atom (cdr x)))
                   (error nil))))
        (recurfn) (forms) (bds) (fns))
    (setq recurfn
          (lambda (bind)
            (cond
             ((funcall pairp bind)
              (push `(leaf-key-chord ,(car bind) #',(cdr bind)) forms)
              (push bind bds)
              (push (cdr bind) fns))
             ((and (listp (car bind))
                   (funcall pairp (car bind)))
              (mapcar (lambda (elm)
                        (if (funcall pairp elm)
                            (progn
                              (push `(leaf-key-chord ,(car elm) #',(cdr elm)) forms)
                              (push elm bds)
                              (push (cdr elm) fns))
                          (funcall recurfn elm)))
                      bind))
             ((or (keywordp (car bind))
                  (symbolp (car bind)))
              (let* ((map (if (keywordp (car bind))
                              (intern (substring (symbol-name (car bind)) 1))
                            (car bind)))
                     (pkg (leaf-plist-get :package (cdr bind)))
                     (pkgs (if (atom pkg) `(,pkg) pkg))
                     (elmbind (if pkg (nthcdr 3 bind) (nthcdr 1 bind)))
                     (elmbinds (if (funcall pairp (car elmbind))
                                   elmbind (car elmbind)))
                     (form `(progn
                              ,@(mapcar
                                 (lambda (elm)
                                   (push (cdr elm) fns)
                                   `(leaf-key-chord ,(car elm) #',(cdr elm) ',map))
                                 elmbinds))))
                (push (if pkg bind
                        `(,(intern (concat ":" (symbol-name map)))
                          :package ,dryrun-name
                          ,@elmbinds))
                      bds)
                (when pkg
                  (dolist (elmpkg pkgs)
                    (setq form `(eval-after-load ',elmpkg ',form))))
                (push form forms)))
             (t
              (mapcar (lambda (elm) (funcall recurfn elm)) bind)))))
    (funcall recurfn bind)
    (if dryrun-name `'(,(nreverse bds) ,(nreverse fns))
      (if (cdr forms) `(progn ,@(nreverse forms)) (car forms)))))

(defmacro leaf-key-chords* (bind)
  "Similar to `leaf-key-chords', but overrides any mode-specific bindings for BIND."
  (let ((binds (if (and (atom (car bind)) (atom (cdr bind)))
                   `(,bind) bind)))
    `(leaf-key-chords (:leaf-key-override-global-map ,@binds))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;  Main initializer
;;

(defun leaf-keywords-init ()
  "Add additional keywords to `leaf'."
  (setq leaf-keywords-init-frg t)

  ;; restore raw `leaf-keywords'
  (setq leaf-keywords leaf-keywords-raw-keywords)

  ;; :disabled :leaf-protect ... :preface <this place> :when :unless :if
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :when
          leaf-keywords-before-conditions))

  ;; :when :unless :if :ensure <this place> :after
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :after
          leaf-keywords-after-conditions))

  ;; :after ... <this place> :leaf-defer
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :leaf-defer
          leaf-keywords-before-load))

  ;; :leaf-defer ... <this place> :init :require
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :init
          leaf-keywords-after-load))

  ;; :require ... <this place> :config
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :config
          leaf-keywords-after-require))

  ;; add additional normalize on the top
  (setq leaf-normalize
        (append leaf-keywords-normalize leaf-keywords-raw-normalize))

  ;; define new leaf-expand-* variable
  (eval
   `(progn
      ,@(mapcar
         (lambda (elm)
           (let ((keyname (substring (symbol-name elm) 1)))
             `(defcustom ,(intern (format "leaf-expand-%s" keyname)) t
                ,(format "If nil, do not expand values for :%s." keyname)
                :type 'boolean
                :group 'leaf)))
         (leaf-plist-keys leaf-keywords)))))

(provide 'leaf-keywords)
;;; leaf-keywords.el ends here
