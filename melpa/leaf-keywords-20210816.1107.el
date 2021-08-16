;;; leaf-keywords.el --- Additional leaf.el keywords for external packages       -*- lexical-binding: t; -*-

;; Copyright (C) 2018-2019  Naoya Yamashita <conao3@gmail.com>

;; Author: Naoya Yamashita <conao3@gmail.com>
;; Maintainer: Naoya Yamashita <conao3@gmail.com>
;; Keywords: lisp settings
;; Package-Version: 20210816.1107
;; Package-Commit: 849b579f87c263e2f1d7fb7eda93b6ce441f217e
;; Version: 2.0.7
;; URL: https://github.com/conao3/leaf-keywords.el
;; Package-Requires: ((emacs "24.4") (leaf "3.5.0"))

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

;; leaf-keywords.el provide additional keywords for leaf.el
;; This package defines keywords that are dependent on an external package.
;;
;; More information is [[https://github.com/conao3/leaf-keywords.el][here]]


;;; Code:

(require 'cl-lib)
(require 'leaf)

(defgroup leaf-keywords nil
  "Additional keywords for `leaf'."
  :group 'lisp)

;;; custom variable setters

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

;;; implementation

(defvar leaf-keywords-packages-list
  (leaf-list
   ;; `leaf-keywords-before-conditions'


   ;; `leaf-keywords-after-conditions'
   ;; straight users require straight.el or straight-x.el
   ;; straight
   feather el-get system-packages

   ;; `leaf-keywords-before-require'
   hydra major-mode-hydra pretty-hydra key-combo smartrep
   key-chord grugru

   ;; `leaf-keywords-after-require'
   diminish delight)
  "List of dependent packages.")

(defcustom leaf-keywords-before-protection nil
  "Additional `leaf-keywords' before protection.
:disabled <this place> :leaf-protect"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-documentation-keywords
  (leaf-list
   :comment    `(,@leaf--body))
  "Additional `leaf-keywords' documentation keywords.
:doc :req :tag <this place> :file :url"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-before-conditions nil
  "Additional `leaf-keywords' before conditional branching.
:leaf-protect ... :preface <this place> :when :unless :if"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-after-conditions
  (leaf-list
   :feather    `(,@(mapcar (lambda (elm) `(leaf-handler-package ,leaf--name ,(car elm) ,(cdr elm))) leaf--value)
                 (feather-add-after-installed-hook-sexp ,(caar (last leaf--value)) ,@leaf--body))
   :straight   `(,@(mapcar (lambda (elm) `(straight-use-package ',elm)) leaf--value) ,@leaf--body)
   :el-get     `(,@(mapcar (lambda (elm) `(el-get-bundle ,@elm)) leaf--value) ,@leaf--body)
   :ensure-system-package
   `(,@(mapcar (lambda (elm)
                 (let ((a (car elm)) (d (cdr elm)))
                   (cond
                    ((null d)
                     `(unless (executable-find ,(symbol-name a))
                        (system-packages-install ,(symbol-name a))))
                    ((symbolp d)
                     `(unless ,(if (stringp a) `(file-exists-p ,a) `(executable-find ,(symbol-name a)))
                        (system-packages-install ,(symbol-name d))))
                    ((stringp d)
                     `(unless ,(if (stringp a) `(file-exists-p ,a) `(executable-find ,(symbol-name a)))
                        (async-shell-command ,d))))))
               leaf--value)
     ,@leaf--body))
  "Additional `leaf-keywords' after conditional branching.
:when :unless :if ... :ensure <this place> :after"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-before-require
  (leaf-list
   :hydra      (progn
                 (leaf-register-autoload (cadr leaf--value) leaf--name)
                 `(,@(mapcar (lambda (elm) `(defhydra ,@elm)) (car leaf--value)) ,@leaf--body))
   :mode-hydra (progn
                 (leaf-register-autoload (cadr leaf--value) leaf--name)
                 `(,@(mapcar (lambda (elm) `(major-mode-hydra-define+ ,@elm)) (car leaf--value)) ,@leaf--body))
   :pretty-hydra (progn
                   (leaf-register-autoload (cadr leaf--value) leaf--name)
                   `(,@(mapcar (lambda (elm) `(pretty-hydra-define+ ,@elm)) (car leaf--value)) ,@leaf--body))
   :transient  (progn
                 ;; (leaf-register-autoload (cadr leaf--value) leaf--name)
                 `(,@(mapcar (lambda (elm) `(transient-define-prefix ,@elm)) (car leaf--value)) ,@leaf--body))
   :combo      (progn
                 (leaf-register-autoload (cadr leaf--value) leaf--name)
                 `(,@(mapcar (lambda (elm) `(key-combo-define ,@elm)) (car leaf--value)) ,@leaf--body))
   :combo*     (progn
                 (leaf-register-autoload (cadr leaf--value) leaf--name)
                 `(,@(mapcar (lambda (elm) `(key-combo-define ,@elm)) (car leaf--value)) ,@leaf--body))
   :smartrep   (progn
                 (leaf-register-autoload (cadr leaf--value) leaf--name)
                 `(,@(mapcar (lambda (elm) `(smartrep-define-key ,@elm)) (car leaf--value)) ,@leaf--body))
   :smartrep*  (progn
                 (leaf-register-autoload (cadr leaf--value) leaf--name)
                 `(,@(mapcar (lambda (elm) `(smartrep-define-key ,@elm)) (car leaf--value)) ,@leaf--body))
   :chord      (progn
                 (leaf-register-autoload (cadr leaf--value) leaf--name)
                 `((leaf-key-chords ,(car leaf--value)) ,@leaf--body))
   :chord*     (progn
                 (leaf-register-autoload (cadr leaf--value) leaf--name)
                 `((leaf-key-chords* ,(car leaf--value)) ,@leaf--body))
   :mode-hook  `(,@(mapcar (lambda (elm) `(leaf-keywords-handler-mode-hook ,leaf--name ,(car elm) ,@(cadr elm))) leaf--value) ,@leaf--body))
  "Additional `leaf-keywords' before wait loading.
:after ... <this place> :require"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-after-require
  (leaf-list
   :delight    `(,@(mapcar (lambda (elm) `(delight ,@elm)) leaf--value) ,@leaf--body)
   :diminish   `((with-eval-after-load ',leaf--name ,@(mapcar (lambda (elm) `(diminish ',(car elm) ,(cdr elm))) leaf--value)) ,@leaf--body)
   :blackout   `((with-eval-after-load ',leaf--name ,@(mapcar (lambda (elm) `(blackout ',(car elm) ,(cdr elm))) leaf--value)) ,@leaf--body)
   :grugru     `((grugru-define-multiple ,@leaf--value) ,@leaf--body))
  "Additional `leaf-keywords' after require.
:require <this place> :config"
  :set #'leaf-keywords-set-keywords
  :type 'sexp
  :group 'leaf-keywords)

(defcustom leaf-keywords-after-config nil
  "Additional `leaf-keywords' after config.
:config <this place> :setq"
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

    ((memq leaf--key '(:feather :diminish :blackout :ensure-system-package))
     ;; Accept: (sym . val), ((sym sym ...) . val), (sym sym ... . val)
     ;; Return: list of pair (sym . val)
     ;; Note  : atom ('t, 'nil, symbol) is just ignored
     ;;         remove duplicate configure
     (mapcar (lambda (elm)
               (cond
                ((leaf-pairp elm)
                 (if (eq t (car elm)) `(,leaf--name . ,(cdr elm)) elm))
                ((memq leaf--key '(:feather :ensure-system-package))
                 (if (equal '(t) elm) `(,leaf--name . nil) `(,@elm . nil)))
                ((memq leaf--key '())
                 `(,@elm . ,leaf--name))
                ((memq leaf--key '())
                 `(,@elm . leaf-default-plstore))
                ((memq leaf--key '(:diminish :blackout))
                 (let ((elm* (car elm)))
                   (cond
                    ((equal t elm*) `(,(leaf-mode-sym leaf--name) . nil))
                    ((symbolp elm*) `(,(leaf-mode-sym elm*) . nil))
                    ((stringp elm*) `(,(leaf-mode-sym leaf--name) . ,elm*)))))
                (t
                 elm)))
             (mapcan
              (lambda (elm) (leaf-normalize-list-in-list elm 'dotlistp))
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

    ((memq leaf--key '(:mode-hydra :pretty-hydra))
     (let ((fn (lambda (elm)
                 (mapcan (lambda (el) (mapcar (lambda (e) (when (listp e) (cadr e))) (when (listp el) el))) elm)))
           val fns)
       (setq val (mapcan
                  (lambda (elm)
                    (cond
                     ((stringp (car-safe elm)) (setq fns (append fns (funcall fn elm))) `((,leaf--name nil ,elm)))
                     ((listp (car-safe elm)) (setq fns (append fns (funcall fn (cadr elm)))) `((,leaf--name ,@elm)))
                     ((symbolp (car-safe elm)) (setq fns (append fns (funcall fn (cl-caddr elm)))) `((,@elm)))))
                  leaf--value))
       `(,val ,fns)))

    ((memq leaf--key '(:transient))
     ;; TODO: parse transient argument and get functions
     (let (val fns)
       (setq val (mapcan
                  (lambda (elm)
                    (cond
                     ((and (listp elm) (listp (car elm)))
                      (progn
                        ;; (mapc (lambda (el) (setq fns (append fns (funcall fn el)))) elm)
                        elm))
                     ((listp elm)
                      (progn
                        ;; (setq fns (append fns (funcall fn elm)))
                        `(,elm)))))
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
         ((eq t elm) `((',(leaf-mode-sym leaf--name))))
         ((symbolp elm) `((',(leaf-mode-sym elm))))
         ((stringp elm) `((',(leaf-mode-sym leaf--name) ,elm)))
         ((and (listp elm) (listp (car elm))) (mapcar (lambda (el) `(',(car el) ,@(cdr el))) elm))
         ((listp elm) `((',(car elm) ,@(cdr elm))))))
      leaf--value))

    ((memq leaf--key '(:el-get))
     (unless (eq (car-safe leaf--value) nil)
       (mapcar
        (lambda (elm)
          (leaf-keywords-normalize-list-in-list (if (eq t elm) leaf--name elm) 'allow-dotlist))
        leaf--value)))

    ((memq leaf--key '(:straight))
     (unless (eq (car-safe leaf--value) nil)
       (mapcar
        (lambda (elm)
          (if (eq t elm) leaf--name elm))
        leaf--value)))

    ((memq leaf--key '(:grugru))
     (cl-flet ((rightvaluep
                (obj)
                (when obj
                  (or
                   (functionp obj)
                   (and (listp obj) (cl-every #'stringp obj))))))
       (mapcar
        (lambda (arg)
          (if (rightvaluep (cdr arg))
              (list (leaf-mode-sym leaf--name) arg)
            arg))
        (if (or
             (rightvaluep (cdar leaf--value))
             (and
              (not
               (or (rightvaluep (cdr-safe (caar leaf--value)))
                   (rightvaluep (cdr-safe (car-safe (cdr-safe (caar leaf--value)))))))
              (rightvaluep (cdar (cdar leaf--value)))))
            leaf--value (car leaf--value)))))

    ((memq leaf--key '(:mode-hook))
     (mapcar
      (lambda (elm)
        (let ((fn (lambda (elm)
                    (if (string-suffix-p "-hook" elm)
                        elm
                      (funcall #'concat
                               (symbol-name leaf--name)
                               (when (not (string-suffix-p "-mode" elm)) "-mode")
                               "-hook")))))
          (if (symbolp (car elm))
              (let ((symname (symbol-name (car elm))))
                `(,(intern (funcall fn symname)) ,@(cdr elm)))
            `(,(intern (funcall fn (symbol-name leaf--name))) ,elm))))
      (mapcan
       (lambda (elm)
         (if (not (symbolp (car elm)))
             (list elm)
           (let ((i 0) hooks body)
             (while (string-suffix-p "-hook" (and (symbolp (nth i elm))
                                                  (symbol-name (nth i elm))))
               (cl-incf i))
             (setq hooks (cl-subseq elm 0 i))
             (setq body (cl-subseq elm i))
             (mapcar
              (lambda (elm) `(,elm ,body))
              hooks))))
       (mapcan
        (lambda (elm)
          (if (and (car-safe (car elm))
                   (symbolp (caar elm))
                   (string-suffix-p "-hook" (symbol-name (caar elm))))
              elm
            (list elm)))
        (let ((store leaf--value) ret hooks)
          (while store
            (let ((elm (pop store)))
              (if (not (string-suffix-p "-hook" (or (and (car-safe elm)
                                                         (symbolp (car elm))
                                                         (symbol-name (car elm)))
                                                    (and (car-safe (car elm))
                                                         (symbolp (caar elm))
                                                         (symbol-name (caar elm))))))
                  (push elm hooks)
                (setq ret `(,(reverse hooks) ,@ret))
                (push elm ret)
                (setq hooks nil))))
          (setq ret `(,(reverse hooks) ,@ret))
          (delq nil (nreverse ret))))))))
  "Additional `leaf-normalize'."
  :set #'leaf-keywords-set-normalize
  :type 'sexp
  :group 'leaf-keywords)


;;;; Utility functions

(defun leaf-insert-list-after (lst aelm targetlst)
  "Insert TARGETLST after AELM in LST."
  (declare (indent 2))
  (let ((retlst) (frg))
    (dolist (elm lst)
      (if (eq elm aelm)
          (setq frg t
                retlst (append `(,@(reverse targetlst) ,aelm) retlst))
        (setq retlst (cons elm retlst))))
    (unless frg
      (warn (format "%s is not found in given list" aelm)))
    (nreverse retlst)))

(defun leaf-insert-list-before (lst belm targetlst)
  "Insert TARGETLST before BELM in LST."
  (declare (indent 2))
  (let ((retlst) (frg))
    (dolist (elm lst)
      (if (eq elm belm)
          (setq frg t
                retlst (append `(,belm ,@(reverse targetlst)) retlst))
        (setq retlst (cons elm retlst))))
    (unless frg
      (warn (format "%s is not found in given list" belm)))
    (nreverse retlst)))

(defun leaf-keywords-normalize-list-in-list (lst &optional dotlistp distribute)
  "Return normalized list from LST.

Example:
  - when DOTLISTP is nil
    a                 => (a)
    (a b c)           => (a b c)
    (a . b)           => (a . b)
    (a . nil)         => (a . nil)
    (a)               => (a . nil)
    ((a . b) (c . d)) => ((a . b) (c . d))
    ((a) (b) (c))     => ((a) (b) (c))
    ((a b c) . d)     => ((a b c) . d)

  - when DOTLISTP is non-nil
    a                 => (a)
    (a b c)           => (a b c)
    (a . b)           => ((a . b))
    (a . nil)         => ((a . nil))
    (a)               => ((a . nil))
    ((a . b) (c . d)) => ((a . b) (c . d))
    ((a) (b) (c))     => ((a) (b) (c))
    ((a b c) . d)     => (((a b c) . d))

  - when DISTRIBUTE is non-nil (NEED DOTLISTP is also non-nil)
    ((a b c) . d)           => ((a . d) (b . d) (c . d))
    ((x . y) ((a b c) . d)) => ((x . y) (a . d) (b . d) (c . d))"
  (cond
   ((not dotlistp)
    (if (atom lst) (list lst) lst))
   ((and dotlistp (not distribute))
    (if (or (atom lst)
            (and (leaf-pairp lst 'allow)
                 (not (leaf-pairp (car lst) 'allow)))) ; not list of pairs
        (list lst) lst))
   ((and dotlistp distribute)
    (if (and (listp lst)
             (and (listp (car lst)) (leaf-dotlistp lst)))
        (let ((dist (cdr lst)))
          (mapcar (lambda (elm) `(,elm . ,dist)) (car lst)))
      (if (or (atom lst) (leaf-dotlistp lst))
          (list lst)
        (funcall (if (fboundp 'mapcan) #'mapcan #'leaf-mapcaappend)
                 (lambda (elm) (leaf-keywords-normalize-list-in-list elm t t)) lst))))))


;;;; Support functions

;;;###autoload
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

;;;###autoload
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

;;;###autoload
(defmacro leaf-key-chords* (bind)
  "Similar to `leaf-key-chords', but overrides any mode-specific bindings for BIND."
  (let ((binds (if (and (atom (car bind)) (atom (cdr bind)))
                   `(,bind) bind)))
    `(leaf-key-chords (:leaf-key-override-global-map ,@binds))))


;;; Handlers

(defmacro leaf-keywords-handler-mode-hook (name hook &rest body)
  "Handler define hook function for HOOK in NAME leaf block."
  (declare (indent 2))
  (let ((fnsym (intern (format "leaf-keywords-mode-hook--%s--%s" name hook))))
    `(progn
       (defun ,fnsym ()
         ,(format "Function autogenerated by leaf-keywords in leaf-block `%s' for hook `%s'." name hook)
         ,@body)
       (add-hook ',hook ',fnsym))))


;;;; Main initializer

(defvar leaf-keywords-raw-keywords nil
  "Raw `leaf-keywords' before being modified by this package.")

(defvar leaf-keywords-raw-normalize nil
  "Raw `leaf-normalize' before being modified by this package.")

;;;###autoload
(defun leaf-keywords-init (&optional renew)
  "Add additional keywords to `leaf'.
If RENEW is non-nil, renew leaf-{keywords, normalize} cache."
  (setq leaf-keywords-init-frg t)

  (when renew
    (setq leaf-keywords-raw-keywords nil)
    (setq leaf-keywords-raw-normalize nil))

  (unless leaf-keywords-raw-keywords (setq leaf-keywords-raw-keywords leaf-keywords))
  (unless leaf-keywords-raw-normalize (setq leaf-keywords-raw-normalize leaf-normalize))

  ;; restore raw `leaf-keywords'
  (setq leaf-keywords leaf-keywords-raw-keywords)
  (setq leaf-normalize leaf-keywords-raw-normalize)

  ;; :disabled <this place> :leaf-protect
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :leaf-protect
          leaf-keywords-before-protection))

  ;; :leaf-protect ... :preface <this place> :when :unless :if
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :when
          leaf-keywords-before-conditions))

  ;; :doc :req :tag <this place> :file :url
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :file
          leaf-keywords-documentation-keywords))

  ;; :when :unless :if :ensure <this place> :after
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :after
          leaf-keywords-after-conditions))

  ;; :after ... <this place> :require
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :require
          leaf-keywords-before-require))

  ;; :require ... <this place> :leaf-defer
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :leaf-defer
          leaf-keywords-after-require))

  ;; :config <this place> :setq
  (setq leaf-keywords
        (leaf-insert-list-before leaf-keywords :setq
          leaf-keywords-after-config))

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
         (leaf-plist-keys leaf-keywords))))

  ;; require all dependent packages
  (dolist (pkg leaf-keywords-packages-list)
    (require pkg nil 'no-error)))

(provide 'leaf-keywords)

;; Local Variables:
;; indent-tabs-mode: nil
;; End:

;;; leaf-keywords.el ends here
