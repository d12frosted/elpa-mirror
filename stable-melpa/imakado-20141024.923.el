;;; imakado.el --- imakado's usefull macros and functions

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;; Description: imakado's usefull macros and functions
;; Author: imakado <ken.imakado_at_gmail.com>
;; Maintainer: imakado
;; Copyright (C) 2014 imakado
;; Created: :2014-10-23
;; Version: 0.12
;; Keywords: convenience
;; URL: https://github.com/imakado/emacs-imakado

;; Prefix: imakado-

;;; Commentary:

;;; Todo:

(eval-when-compile
  (require 'cl)
  (require 'rx)) ;; eval-when-compile

;;;; Version
(defvar imakado-version 0.11)
(defun imakado-require-version (v)
  (unless (>= imakado-version v)
    (error "\
You need to upgrade imakado.el %s to %s.
You have imakado.el %s at %s."
           imakado-version
           v
           imakado-version
           (progn (require 'find-func)
                  (and (fboundp 'find-library-name)
                       (find-library-name "imakado")))))
  t)
(defalias 'imakado-el-require-version->= 'imakado-require-version)


;;;; imakado-with-gensyms
(eval-and-compile
  (defvar imakado-gensym-prefix "--imakado--")
  (defvar imakado-*gensym-counter* 0)
  (defun imakado-gensym (&optional prefix)
    "Generate a new uninterned symbol.
The name is made by appending a number to PREFIX, default \"G\"."
    (let ((pfix (if (stringp prefix) prefix imakado-gensym-prefix))
          (num (if (integerp prefix) prefix
                 (prog1 imakado-*gensym-counter*
                   (setq imakado-*gensym-counter* (1+ imakado-*gensym-counter*))))))
      (make-symbol (format "%s%d" pfix num))))
  ;; slices
  (defun* imakado-group (source n &key (error-check nil))
    (assert (not (zerop n)))
    (when error-check
      (assert (= (mod (length source) n) 0)))
    (let ((copied-source (copy-sequence source))
          (res))
      (while copied-source
        (push (let* ((ret nil)
                     (source-len (length copied-source)))
                (dotimes (var (min source-len n) (nreverse ret))
                  (push (pop copied-source) ret)))
              res))
      (nreverse res)))
  (defun imakado-allquote (args)
    (loop for arg in args
          collect `(quote ,arg)))
  (defun* imakado-in-aux-test (v choises &key (test 'eq))
    (loop for c in choises
          collect `(,test ,v ,c)))
  (defun imakado-flatten (list)
    "Flatten any lists within ARGS, so that there are no sublists."
    (loop for item in list
          if (listp item)
          nconc (imakado-flatten item)
          else
          collect item))
  ;; copied from cl
  (defun imakado-subseq (seq start &optional end)
    "Return the subsequence of SEQ from START to END.
If END is omitted, it defaults to the length of the sequence.
If START or END is negative, it counts from the end."
    (if (stringp seq) (substring seq start end)
      (let (len)
        (and end (< end 0) (setq end (+ end (setq len (length seq)))))
        (if (< start 0) (setq start (+ start (or len (setq len (length seq))))))
        (cond ((listp seq)
               (if (> start 0) (setq seq (nthcdr start seq)))
               (if end
                   (let ((res nil))
                     (while (>= (setq end (1- end)) start)
                       (push (pop seq) res))
                     (nreverse res))
                 (copy-sequence seq)))
              (t
               (or end (setq end (or len (length seq))))
               (let ((res (make-vector (max (- end start) 0) nil))
                     (i 0))
                 (while (< start end)
                   (aset res i (aref seq start))
                   (setq i (1+ i) start (1+ start)))
                 res))))))
  (defun* imakado-remove-if (pred seq &key (key 'identity))
    (loop for elem in seq
          unless (funcall pred (funcall key elem))
          collect elem))
  (defun* imakado-remove-if-not (pred seq &key (key 'identity))
    (loop for elem in seq
          when (funcall pred (funcall key elem))
          collect elem))
  (defsubst imakado-acdr (key alist)
    (cdr (assq key alist)))
  ) ;; eval-and-compile

(defmacro imakado-with-gensyms (syms &rest body)
  (declare (indent 1)
           (debug ((&rest symbolp)
                   body)))
  (let ((clauses (loop for sym in syms
                      collect `( ,sym  ',(imakado-gensym imakado-gensym-prefix) ))))
    `(let ( ,@clauses )
       ,@body)))

(defmacro imakado-with-lexical-bindings (syms &rest body)
  (declare (indent 1)
           (debug ((&rest symbolp)
                   body)))
  (let ((clauses (loop for sym in syms
                      collect `( ,sym  ,sym ))))
    `(lexical-let ( ,@clauses )
       ,@body)))

;;;; imakado-dirconcat
(defmacro imakado-dirconcat (d1 str)
  (declare (debug (form form)))
  (imakado-with-gensyms (d1-tmp str-temp)
    `(let* ((,d1-tmp ,d1)
            (,d1-tmp (if (file-directory-p ,d1-tmp)
                         (file-name-as-directory ,d1-tmp)
                       (error "not directory: %s" ,d1-tmp)))
            (,str-temp ,str))
       (concat ,d1-tmp ,str))))

(defmacro* imakado-in-directory (directory &rest body)
  (declare (debug (form body))
           (indent 1))
  (let ((before-directory (imakado-gensym)))
    `(let ((,before-directory default-directory)
           (default-directory ,directory))
       (cd ,directory)
       ,@body
       (cd ,before-directory))))

;;;; imakado-remif
(defsubst imakado-remif-aux (pred seq key cond)
  (imakado-with-gensyms (g-pred g-seq g-key g-elem)
    `(let ((,g-pred ,pred)
           (,g-seq ,seq)
           (,g-key ,key)
           (,g-elem nil))
       (loop for ,g-elem in ,g-seq
             ,cond (funcall ,g-pred (funcall ,g-key ,g-elem))
             collect ,g-elem))))
(defmacro* imakado-remif (pred seq &key (key (quote 'identity)))
  (declare (debug (form form &rest [":key" function-form])))
  (imakado-remif-aux pred seq key 'unless))

(defmacro* imakado-!remif (pred seq &key (key (quote 'identity)))
  (declare (debug (form form &rest [":key" function-form])))
  (imakado-remif-aux pred seq key 'when))


;;;; Special
;; almost copied from anything.el
(defmacro imakado-aif (test-form then-form &rest else-forms)
  (declare (indent 2)
           (debug (form form &rest form)))
  "Anaphoric if. Temporary variable `it' is the result of test-form."
  `(let ((it ,test-form))
     (if it ,then-form ,@else-forms)))

(defmacro imakado-awhen (test-form &rest body)
  (declare (indent 1)
           (debug (form body)))
  `(imakado-aif ,test-form
       (progn ,@body)))

(defmacro imakado-awhile (expr &rest body)
  (declare (indent 1)
           (debug (form body)))
  `(do ((it ,expr ,expr))
       ((not it))
     ,@body))

(defmacro imakado-aand (&rest args)
  (declare (debug (&rest form)))
  (cond
   ((null (car args)) t)
   ((null (cdr args)) (car args))
   (t `(imakado-aif ,(car args) (imakado-aand ,@(cdr args))))))

(defmacro aand (&rest args)
  (declare (debug (&rest form)))
  (cond
   ((null (car args)) t)
   ((null (cdr args)) (car args))
   (t `(imakado-aif ,(car args) (imakado-aand ,@(cdr args))))))


(defmacro imakado-acond (&rest clauses)
  (declare (indent 0)
           (debug cond))
  (cond
   ((null clauses) nil)
   (t
    (imakado-with-gensyms (test)
      (let ((clause (car clauses)))
        `(let ((,test ,(car clause)))
           (if ,test
               (let ((it ,test))
                 ,@(cdr clause))
             (imakado-acond ,@(cdr clauses)))))))))

(defmacro imakado-alambda (params &rest body)
  (declare (indent 1)
           (debug lambda))
  `(labels ((caller ,params ,@body))
     'caller))

;;;; imakado-cond-let
(defsubst imakado-cond-let-aux-vars (clauses)
  (let ((vars (delete-dups
               (loop for cla in clauses
                     append (mapcar 'car (cdr cla))))))
    (loop for var in vars
          collect (cons var (imakado-gensym imakado-gensym-prefix)))))
(defsubst imakado-cond-let-aux-binds (vars cla)
  (loop for bindform in (cdr cla)
        for (bind-var . bind-body) = bindform
        when (consp bindform)
        collect `( ,(assoc-default bind-var vars) . ,bind-body)))
(defsubst imakado-cond-let-aux-clause (vars cla body-fn)
  `( ,(car cla)  (let ,(mapcar 'cdr vars)
                   (let ,(imakado-cond-let-aux-binds vars cla)
                     (,body-fn ,@(mapcar 'cdr vars))))))

(defmacro imakado-cond-let (clauses &rest body)
  (declare (indent 1)
           (debug ((&rest (form &rest (symbolp body))) body)))
  (imakado-with-gensyms (body-fn)
    (let ((vars (imakado-cond-let-aux-vars clauses)))
      `(labels ((,body-fn ,(mapcar 'car vars)
                          ,@body))
         (cond
          ,@(loop for cla in clauses
                  collect (imakado-cond-let-aux-clause vars cla body-fn)))))))

;;;; imakado-when-let
;; the code is taken from slime.el
(defmacro* imakado-when-let ((var value) &rest body)
  "Evaluate VALUE, if the result is non-nil bind it to VAR and eval BODY."
  (declare (indent 1)
           (debug ((symbolp form) body)))
  `(let ((,var ,value))
     (when ,var ,@body)))

;;;; imakado-fn
(eval-when-compile
  (defvar imakado-fn-aux-anaph-arg-map
    (loop for n from 1 to 20
          for sym = (intern (format "_%s" n))
          collect `( ,sym . ,n))))
(defsubst imakado-fn-aux-anaph-arg-syms (flatten fn-args-arg fn-args-rest)
  (and (not (equal fn-args-arg '(_)))
       (let ((anaph-arg-syms (mapcar 'car (eval-when-compile
                                            imakado-fn-aux-anaph-arg-map))))
         (imakado-remove-if-not (lambda (atom)
                             (memq atom anaph-arg-syms))
                           flatten))))
(defsubst imakado-fn-aux-appear_? (flatten fn-args-arg fn-args-rest)
  (and (not (equal fn-args-arg '(_)))
       ;; (imakado-fn (_ b) (list b))
       (or (and (null fn-args-rest)
                (memq '_ (imakado-flatten fn-args-arg)))
           (and fn-args-rest
                (not (remove '_ fn-args-arg))))
       (memq  '_ flatten)))
(defsubst imakado-fn-aux (fn-args)
  (let ((flatten (imakado-flatten fn-args))
        (fn-args-arg (car fn-args))
        (fn-args-rest (cdr fn-args)))
    (imakado-acond
      ((imakado-fn-aux-anaph-arg-syms flatten fn-args-arg fn-args-rest)
       (assert (not (memq '_ flatten))
               nil
               "cant use \"_\" and \"(_1 _2 ...)\" at the same time!!")
       (let* ((arg-count (apply 'max
                                (loop for sym in it
                                      collect (assoc-default sym (eval-when-compile
                                                                   imakado-fn-aux-anaph-arg-map)))))
              (lambda-args (mapcar 'car (imakado-subseq (eval-when-compile imakado-fn-aux-anaph-arg-map) 0 arg-count))))
         `(lambda ,lambda-args
            (let ((_0 (list ,@lambda-args)))
              ,@fn-args))))
      ((imakado-fn-aux-appear_? flatten fn-args-arg fn-args-rest)
       `(lambda (_) ,@fn-args))
      (t
       `(lambda ,@fn-args)))))
(defmacro imakado-fn (&rest args)
  (declare (indent defun)
           (debug (&or [&define lambda-list
                                [&optional stringp]
                                [&optional ("interactive" interactive)]
                                def-body]
                       body)))
  `,(imakado-fn-aux args))


;;;; Macro aliases
(eval-and-compile
(defmacro imakado-define-macro-alias (short long)
  `(defmacro ,short (&rest args)
     (declare ,(imakado-awhen (and (fboundp long)
                           (get long 'lisp-indent-function))
                 `(indent ,it))
              ,(imakado-awhen (and (fboundp long)
                           (get long 'edebug-form-spec))
                 `(debug ,it)))
     ,(documentation long)
     `(,',long ,@args)))

(defmacro imakado-define-macro-aliases (&rest args)
  `(progn
     ,@(loop for (short long) in (imakado-group args 2 :error-check t)
             collect `(imakado-define-macro-alias ,short ,long))))
)

;;;; define abbrevs
;; (imakado-define-macro-aliases
;;   imakado-dbind destructuring-bind
;;   mvbind multiple-value-bind
;;   mvsetq multiple-value-setq
;;   )
(imakado-define-macro-aliases
  imakado-dbind destructuring-bind
  imakado-mvbind multiple-value-bind
  imakado-mvsetq multiple-value-setq
  )

;;; destructuring-bind's edebug-spec has broken.
;;; so fix it.
(def-edebug-spec imakado-dbind
  (loop-var form body))


;;;; List

(defmacro imakado-cars (seq)
  (declare (debug (form)))
  `(mapcar 'car ,seq))

(defmacro imakado-cdrs (seq)
  (declare (debug (form)))
  `(mapcar 'cdr ,seq))

(defmacro imakado-cadrs (seq)
  (declare (debug (form)))
  `(mapcar 'cadr ,seq))

(defmacro imakado-assoc-cdrs (keys alist &optional test default)
  (declare (debug (form form)))
  `(mapcar (imakado-fn (assoc-default _ ,alist ,test ,default)) ,keys))

(defmacro imakado-nths (n seq)
  (declare (debug (form form)))
  `(mapcar (imakado-fn (nth ,n _)) ,seq))

(defmacro imakado-in (obj  &rest choises)
  (declare (indent 1)
           (debug (form &rest form)))
  (imakado-with-gensyms (insym)
    `(let ((,insym ,obj))
       (or ,@(imakado-in-aux-test insym choises)))))

(defmacro imakado-inq (obj &rest args)
  (declare (indent 1)
           (debug (form &rest symbolp)))
  `(imakado-in ,obj ,@(imakado-allquote args)))

(defmacro imakado-in= (obj &rest choises)
  (declare (indent 1)
           (debug imakado-in))
  (imakado-with-gensyms (inobj)
    `(let ((,inobj ,obj))
       (or ,@(imakado-in-aux-test inobj choises
                             :test 'equal)))))

(defmacro* imakado-join+ (seq &optional (separator "\n"))
  (declare (debug (form &optional form)))
  `(mapconcat 'identity ,seq ,separator))


;;; Case
(defsubst* imakado-case-cond-clause-aux (v cla &optional (test 'imakado-in))
  (imakado-dbind (key . body) cla
    (cond
     ((consp key) `((,test ,v ,@key) ,@body))
     ((imakado-inq key t otherwise) `(t ,@body))
     (t (error "bad clause")))))
(defmacro imakado-xcase (expr &rest clauses)
  (declare (indent 1)
           (debug case))
  (imakado-with-gensyms (v)
    `(let ((,v ,expr))
       (cond
        ,@(loop for cla in clauses
                collect (imakado-case-cond-clause-aux v cla))))))

;;;; imakado-xcase=
(defsubst* imakado-xcase-clause-aux-test (v keys body &key test)
  `((or ,@(loop for key in keys
                collect `(,test ,key ,v)))
    ,@body))
(defsubst* imakado-xcase-clause-aux (v cla &key (test 'equal))
  (imakado-dbind (key . body) cla
    (cond
     ((consp key) `,@(imakado-xcase-clause-aux-test v key body
                                               :test test))
     ((imakado-inq key t otherwise) `(t ,@body))
     (t (error "bad clause")))))
(defmacro imakado-xcase= (expr &rest clauses)
  (declare (indent 1)
           (debug (form &rest ((&rest form) body))))
  (imakado-with-gensyms (g-expr)
    `(let ((,g-expr ,expr))
       (cond
        ,@(loop for cla in clauses
                collect (imakado-xcase-clause-aux g-expr cla))))))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-xcase= +++++")
      (expect '(OPEN "aaa" CLOSE)
        (let ((tokens '("[" "aaa" "]"))
              (tag1 "[")
              (tag2 "]"))
          (loop for token in tokens
                collect
                (imakado-xcase= token
                  ((tag1) 'OPEN)
                  ((tag2) 'CLOSE)
                  (otherwise
                   token)))))

      (desc "case sensitive.")
      (expect '(token-a token-b otherwise otherwise)
        (let ((tokens '("a" "b" "A" "B"))
              (case-fold-search t))
          (loop for token in tokens
                collect
                (imakado-xcase= token
                  (("a") 'token-a)
                  (("b") 'token-b)
                  (otherwise 'otherwise)))))

      (desc "key must be consed")
      (expect (error)
        (imakado-xcase= "a"
          ("a" 'a)))

      (desc "this is ok")
      (expect 'a
        (imakado-xcase= "a"
          (("a") 'a)))

      (desc "multi key")
      (expect '(OPEN "aaa" CLOSE OPEN "bbb" CLOSE)
        (let ((tokens '("[" "aaa" "]" "(" "bbb" ")"))
              (open "(")
              (openb "[")
              (close ")")
              (closeb "]"))
          (loop for token in tokens
                collect
                (imakado-xcase= token
                  ((open openb) 'OPEN)
                  ((close closeb) 'CLOSE)
                  (otherwise
                   token)))))

      (desc "nil")
      (expect '("nil" "otherwise" "nil" "otherwise")
        (let ((tokens '(nil a nil b)))
          (loop for token in tokens
                collect
                (imakado-xcase= token
                  ((nil) "nil")
                  (otherwise
                   "otherwise")))))
      )))


;;;; Struct
;; copied from slime.el
(defmacro* imakado-with-struct ((conc-name &rest slots) struct &body body)
  "Like with-slots but works only for structs.
\(imakado-fn (CONC-NAME &rest SLOTS) STRUCT &body BODY)"
  (declare (indent 2)
           (debug ((symbolp &rest symbolp) form body)))
  (flet ((reader (slot) (intern (concat (symbol-name conc-name)
                                        (symbol-name slot)))))
    (let ((struct-var (imakado-gensym "imakado-with-struct")))
      `(let ((,struct-var ,struct))
         (symbol-macrolet
             ,(mapcar (lambda (slot)
                        (etypecase slot
                          (symbol `(,slot (,(reader slot) ,struct-var)))
                          (cons `(,(first slot) (,(reader (second slot))
                                                 ,struct-var)))))
                      slots)
           . ,body)))))

(defmacro* imakado-define-with-struct-macro (name conc-name)
  `(defmacro* ,name ( slots struct &rest body)
     (declare (indent 2)
              (debug ((&rest symbolp) form body)))
     `(imakado-with-struct (,',conc-name ,@slots) ,struct ,@body)))

(defsubst imakado-with-struct-all-slots-get-getters-slot? (sym)
  (let ((plist (symbol-plist sym)))
    (and (memq 'cl-compiler-macro plist)
         (memq 'setf-method plist))))
(defsubst imakado-with-struct-all-slots-get-all-slots (prefix)
  (loop for s in (all-completions prefix obarray)
        for sym = (intern s)
        when (imakado-with-struct-all-slots-get-getters-slot? sym)
        collect (let ((slotname (replace-regexp-in-string (concat "^" prefix)
                                                          ""
                                                          s)))
                  (intern slotname))))
(defmacro imakado-define-with-all-slots-struct (name conc-name)
  `(defmacro ,name (struct &rest body)
     (declare (indent 1)
              (debug (form body)))
     (let ((imakado-slots ',(imakado-with-struct-all-slots-get-all-slots (symbol-name conc-name))))
       `(imakado-with-struct (,',conc-name ,@imakado-slots) ,struct ,@body))))

;;;; Progress Reporter
(defmacro imakado-dolist-with-progress-reporter (spec message min-change min-time &rest body)
  (declare (indent 4)
           (debug ((symbolp form &optional form) form form form body)))
  (imakado-with-gensyms (seq seq-length reporter loop-temp)
    `(let* ((,seq ,(nth 1 spec))
            (,seq-length (length ,seq))
            (,reporter (make-progress-reporter ,message 0 (length ,seq) nil ,min-change ,min-time)))
       (loop for ,loop-temp from 0 to (1- ,seq-length)
             do (let ((,(nth 0 spec) (nth ,loop-temp ,seq)))
                  ,@body
                  (progress-reporter-update ,reporter
                                            ,loop-temp))
             finally return (prog1 ,(nth 2 spec)
                              (progress-reporter-done ,reporter))))))

;;;; Regexp
;; idea from rails-lib.el
(defmacro imakado-with-anaphoric-match-utilities (string-used-match &rest body)
  (declare (indent 1)
           (debug (form body)))
  (imakado-with-gensyms (str)
    `(lexical-let ((,str ,string-used-match))
       (symbol-macrolet (
                         ,@(loop for i to 9 append
                                 (let ((sym (intern (concat "$" (number-to-string i))))
                                       (sym-match-beg (intern (concat "$MB-" (number-to-string i))))
                                       (sym-match-end (intern (concat "$ME-" (number-to-string i)))))
                                   `((,sym (match-string ,i ,str))
                                     (,sym-match-beg (match-beginning ,i))
                                     (,sym-match-end (match-end ,i)))))
                         )
         (flet (($ (i) (match-string i ,str))
                ($sub (replacement &optional (i 0) &key fixedcase literal-string) ;args
                      (replace-match replacement fixedcase literal-string ,str i)) ;body
                ($gsub (replacement &optional (i 0) &key fixedcase literal-string start)
                       (with-no-warnings
                         ;; see `imakado-=~'
                         (assert (boundp 'imakado---regexp-used-by-=~))
                         (replace-regexp-in-string imakado---regexp-used-by-=~
                                                   replacement
                                                   ,str
                                                   fixedcase
                                                   literal-string
                                                   i
                                                   start))))
           (symbol-macrolet ( ;;before
                             ,(imakado-awhen str
                                `($b (substring ,it 0 (match-beginning 0))))
                             ;;match
                             ($m (match-string 0 ,str))
                             ($M (match-string-no-properties 0 ,str))
                             ;;after
                             ,(imakado-awhen str
                                `($a (substring ,it (match-end 0) (length ,str))))
                             )
             ,@body))))))

(defmacro imakado-=~ (regexp string &rest body)
  (declare (indent 2)
           (debug (form form body)))
  "regexp matching similar to the imakado-=~ operator found in other languages."
  (imakado-with-gensyms (str)
    `(let ((,str ,string)
           (imakado---regexp-used-by-=~ ,regexp))
       (when (string-match ,regexp ,str)
         (imakado-with-anaphoric-match-utilities ,str
           ,@(if body body '(t)))))))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "test initialize")
      (expect (true)
        (and (require 'imakado)
             (imakado-require-version 0.01)))

      (expect "huga"
        (imakado-with-point-buffer "\
hoge-huga-foo
"
          (when (re-search-forward (rx "-"(group (+ not-newline)) "-") nil t)
            (imakado-with-anaphoric-match-utilities nil
              (buffer-substring $MB-1
                                $ME-1)))))
          

      (desc "+++++ imakado-=~ +++++")
      (desc "If match, return last expr")
      (expect 'b
        (imakado-=~ ".*" "re" 'a 'b))
      (expect nil
        (imakado-=~ ".*" "re" 'a nil))
      (expect t
        (imakado-=~ ".*" "re"))
      (desc "If fail, return nil")
      (expect nil
        (imakado-=~ "never match regexp" "string"))
      (expect nil
        (imakado-=~ "never match regexp" "string" 'body))

      (desc "imakado-with-anaphoric-match-utilities")
      (desc "$1 $2 ...")
      (expect '("Dog" "Alice")
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (imakado-=~ re "---- Dog looking at tiny Alice. ----"
            (list $1 $2))))
      (desc "($ 1) ($ 2) ...")
      (expect '("Dog" "Alice")
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (imakado-=~ re "---- Dog looking at tiny Alice. ----"
            (list ($ 1) ($ 2)))))
      (desc "$b, $m, $a")
      (expect '("---- " "Dog looking at tiny Alice." " ----")
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (imakado-=~ re "---- Dog looking at tiny Alice. ----"
            (list $b
                  $m
                  $a))))
      (desc "$sub") 
      (expect "---- gone ----"
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (imakado-=~ re "---- Dog looking at tiny Alice. ----"
            ($sub "gone"))))
      (desc "\\&")
      (expect "---- Dog looking at tiny Alice. ----"
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (imakado-=~ re "---- Dog looking at tiny Alice. ----"
            ($sub "\\&"))))
      (desc "\\N")
      (expect "---- Dog Alice ----"
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (imakado-=~ re "---- Dog looking at tiny Alice. ----"
            ($sub "\\1 \\2"))))
      (desc ":literal")
      (expect "---- \\1 \\2 ----"
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (imakado-=~ re "---- Dog looking at tiny Alice. ----"
            ($sub "\\1 \\2" 0 :literal-string t))))
      (expect (error)
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (imakado-=~ re "---- Dog looking at tiny Alice. ----"
            ;; missing subexp arg.
            ($sub "\\1 \\2" :literal-string t))))

      (desc "($sub subexp)")
      (expect t
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (let ((newstr (imakado-=~ re "---- Dog looking at tiny Alice. ----"
                          ($sub "elise" 2)))
                (case-fold-search nil)) ; case-sensitive
            (imakado-=~ "Elise" newstr))))
      (desc "($sub subexp :fixedcase t)")
      (expect nil
        (let ((re (concat
                   "\\(" "\\w+" "\\)"   ;1
                   "[ \t]+"
                   "looking"
                   ".*"
                   "\\(" "Alice" "\\)"  ;2
                   "\\."
                   )))
          (let ((newstr (imakado-=~ re "---- Dog looking at tiny Alice. ----"
                          ($sub "elise" 2
                                :fixedcase t)))
                (case-fold-search nil)) ; case-sensitive
            (imakado-=~ "Elise" newstr))))
      (desc "($gsub subexp)")
      (expect t
        (let ((newstr (imakado-=~ "/" "a/b/c"
                        ($gsub "::")))
              (case-fold-search nil)) ; case-sensitive
          (imakado-=~ "a::b::c" newstr)))
      )))

;;; imakado-case-regexp
(defsubst imakado-case-regexp-aux (expr-sym clauses)
  (loop for (regexp-or-sym . body) in clauses
        for body = (or body '(nil))
        collect
        (cond
         ((imakado-inq regexp-or-sym t otherwise)
          `(t ,@body))
         (t
          `((imakado-=~ ,regexp-or-sym ,expr-sym)
            (imakado-with-anaphoric-match-utilities ,expr-sym
              ,@body))))))
(defmacro imakado-case-regexp (expr &rest clauses)
  (declare (indent 1)
           (debug (form &rest (form body))))
  (imakado-with-gensyms (expr-tmp)
    `(let ((,expr-tmp ,expr))
       (etypecase ,expr-tmp
         (string (cond ,@(imakado-case-regexp-aux expr-tmp clauses)))))))

;;;; imakado-match-with-temp-buffer
(defmacro imakado-match-with-temp-buffer (spec &rest body)
  (declare (indent 1)
           (debug ((form form &optional form) body)))
  (let* ((ret-form (nth 2 spec)))
    (imakado-with-gensyms (re str g-loop-res)
      `(imakado-dbind (,re ,str ) (list ,(nth 0 spec) ,(nth 1 spec))
         (with-temp-buffer
             (insert ,str)
             (loop with ,g-loop-res
                   initially (goto-char (point-min))
                   while (re-search-forward ,re nil t)
                   ,@(if ret-form
                        `( do (imakado-with-anaphoric-match-utilities nil
                                ,@body))
                       `(do (push (imakado-with-anaphoric-match-utilities nil
                                  ,@body)
                                ,g-loop-res)))
                   finally return ,(or ret-form `,g-loop-res)))))))

;;;; With-

(defmacro imakado-with-temp-buffer-file (file &rest body)
  (declare (indent 1)
           (debug (form body)))
  `(with-temp-buffer
     (insert-file-contents ,file)
     (goto-char (point-min))
     ,@body))


(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ prepare +++++")
      (expect (true)
        (require 'imakado))
      (desc "+++++ imakado-with-temp-buffer-file +++++")
      (expect ";;; imakado.el - imakado's usefull macros"
        (require 'find-func)
        (imakado-with-temp-buffer-file (find-library-name "imakado")
          (buffer-substring-no-properties (point) (point-at-eol))))
      (expect (error)
        (let ((nonexistent-filename (loop for n from 1 to 9999
                                          for nonexistent-filename = (format "/aa-%s" n)
                                          unless (file-readable-p nonexistent-filename)
                                          return nonexistent-filename)))
          (imakado-with-temp-buffer-file nonexistent-filename
            'no-error))))))

(defmacro imakado-match-with-temp-buffer-file (spec &rest body)
  (declare (indent 1)
           (debug ((form form &optional form) body)))
  (imakado-with-gensyms (g-file-contents-str)
    `(let ((,g-file-contents-str ,(imakado-with-temp-buffer-file (nth 1 spec)
                                    (buffer-substring-no-properties (point-min) (point-max)))))
       (imakado-match-with-temp-buffer (,(nth 0 spec) ,g-file-contents-str ,(nth 2 spec))
         ,@body))))


;;;; Buffer
(defmacro imakado-save-excursion-force (&rest body)
  (declare (indent 0)
           (debug (body)))
  (imakado-with-gensyms (saved-point saved-current-buffer)
    `(let ((,saved-point (point))
           (,saved-current-buffer (current-buffer)))
       (prog1 (progn ,@body)
         (ignore-errors
           (and (eq ,saved-current-buffer (current-buffer))
                (goto-char ,saved-point)))))))

(defsubst imakado-goto-pointmark-and-delete ()
  (when (re-search-forward (rx "`!!'") nil t)
    (replace-match "")))
(defmacro imakado-with-point-buffer (str &rest body)
  (declare (indent 1)
           (debug (form body)))
  `(with-temp-buffer
     (insert ,str)
     (goto-char (point-min))
     (imakado-goto-pointmark-and-delete)
     (progn
       ,@body)))

;;;; Keymap
(defmacro* imakado-define-define-keymap (name keymap &key (doc nil))
  `(etypecase ,keymap
     (keymap
      (defmacro ,name (key-str-or-vector command)
        ,doc
        (typecase key-str-or-vector
          (string `(define-key ,',keymap (kbd ,key-str-or-vector) ,command))
          (t `(define-key ,',keymap ,key-str-or-vector ,command)))))))

;;;; imakado-defcacheable
(defmacro* imakado-defcacheable (name args &rest body)
  (declare (indent 2)
           (debug defun*))
  (flet ((imakado-defcacheable-doc&body (body)
          (typecase (car-safe body)
            (string (values (car body) (cdr body)))
            (otherwise (values nil body)))))
    (destructuring-bind (doc body) (imakado-defcacheable-doc&body body)
      (let* ((cache-var-sym (intern (format "%s-cache" name)))
             (clear-cache-fn-sym (intern (format "%s-clear-cache" name))))
        `(progn
           (defvar ,cache-var-sym nil)
           (setf ,cache-var-sym nil)
           (defun* ,name ,args
             ,doc
             (or ,cache-var-sym
                 (setf ,cache-var-sym
                       (progn ,@body))))
           (defun* ,clear-cache-fn-sym ,args
             (interactive)
             (setf ,cache-var-sym
                   nil)))))))
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-defcacheable +++++")
      (desc "defined ok")
      (expect t
        (let ((call-count 0))
          (makunbound 'imakado---test-defcacheable-fn-cache)
          (fmakunbound 'imakado---test-defcacheable-fn-clear-cache)
          (fmakunbound 'imakado---test-defcacheable-fn)
          (imakado-defcacheable imakado---test-defcacheable-fn ()
            "docstr"
            (prog1 "cache me if you can!"
              (incf call-count)))
          (and (boundp 'imakado---test-defcacheable-fn-cache)
               (fboundp 'imakado---test-defcacheable-fn)
               (fboundp 'imakado---test-defcacheable-fn-clear-cache))))
      (desc "call just once")
      (expect '("cache me if you can!" 1)
        (let ((call-count 0))
          (makunbound 'imakado---test-defcacheable-fn-cache)
          (fmakunbound 'imakado---test-defcacheable-fn-clear-cache)
          (fmakunbound 'imakado---test-defcacheable-fn)
          (imakado-defcacheable imakado---test-defcacheable-fn ()
            "docstr"
            (prog1 "cache me if you can!"
              (incf call-count)))
          (imakado---test-defcacheable-fn)
          (let ((res (imakado---test-defcacheable-fn)))
            (list res call-count))))
      (desc "clear cache")
      (expect 2
        (let ((call-count 0))
          (makunbound 'imakado---test-defcacheable-fn-cache)
          (fmakunbound 'imakado---test-defcacheable-fn-clear-cache)
          (fmakunbound 'imakado---test-defcacheable-fn)
          (imakado-defcacheable imakado---test-defcacheable-fn ()
            "docstr"
            (prog1 "cache me if you can!"
              (incf call-count)))
          (imakado---test-defcacheable-fn)
          (imakado---test-defcacheable-fn-clear-cache)
          (imakado---test-defcacheable-fn)
          call-count))
      (desc "cleanup")
      (expect t
        (progn (makunbound 'imakado---test-defcacheable-fn-cache)
               (fmakunbound 'imakado---test-defcacheable-fn-clear-cache)
               (fmakunbound 'imakado---test-defcacheable-fn)
               t))
      )))

(defmacro* imakado-memoize
    (fn-sym
     &key
     (save-directory nil)
     (encoding nil)
     (hash-size 60))
  (let* ((fn-sym (eval fn-sym))
         (advice-sym (intern (format "memoize-%s" fn-sym)))
         (get-fn-sym (intern (format "%s-get-from-cache" fn-sym)))
         (save-fn-sym (intern (format "%s-save" fn-sym)))
         (load-fn-sym (intern (format "%s-load" fn-sym)))
         (hash-fn-sym (intern (format "%s-hash" fn-sym)))
         (saved-alist-sym (intern (format "%s-alist" fn-sym)))
         (save-file-name (replace-regexp-in-string "/" "-" (format "%s-alist.el" fn-sym))))
    `(progn
       (defvar ,saved-alist-sym nil)
       (defun ,load-fn-sym ()
         (when (and ,save-directory
                    (imakado-aand (imakado-dirconcat ,save-directory ,save-file-name)
                          (file-readable-p it)))
           (ignore-errors
             (load (file-name-sans-extension
                    (imakado-dirconcat ,save-directory ,save-file-name)))
             ,saved-alist-sym)))
       (imakado-defcacheable ,hash-fn-sym ()
         (let ((hsh (make-hash-table :test 'equal :size ,hash-size)))
           (cond
            (,save-directory
             (imakado-aand (,load-fn-sym)
                   (loop for (k . v) in it
                         do (puthash k v hsh)))
             hsh)
            (t hsh))))
       (defun ,save-fn-sym ()
         (ignore-errors
           (when (boundp ',(intern (format "%s-cache" fn-sym)))
             (let ((hash->alist
                    (lambda (hash)
                      (check-type hash hash-table)
                      (loop for k being the hash-keys of hash
                            for v = (gethash k hash)
                            collect (cons k v)))))
               (with-temp-buffer
                 (insert ";; -*- mode: emacs-lisp -*-\n" )
                 (prin1 `(setq ,',saved-alist-sym ',(funcall hash->alist
                                                             (,hash-fn-sym)))
                        (current-buffer))
                 (insert "\n")
                 (let ((coding-system-for-write ,encoding)
                       (save-file (imakado-dirconcat ,save-directory ,save-file-name)))
                   (write-region (point-min)
                                 (point-max)
                                 save-file
                                 nil
                                 )))))))
       (defun ,get-fn-sym (key)
         (gethash key (,hash-fn-sym)))
       (defadvice ,fn-sym (around ,(intern (format "memoize-%s" (symbol-name fn-sym)))
                                  (key)
                                  activate)
         (imakado-acond
           ((,get-fn-sym key)
            (setq ad-return-value it))
           (t
            (let ((res ad-do-it))
              (puthash key res (,hash-fn-sym))))))
       ,(when save-directory
          `(add-hook 'kill-emacs-hook
                     ',save-fn-sym))
       )))
;; (imakado-memoize 'fnn)
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-memoize +++++")
      (desc "prepare")
      (expect t
        (lexical-let ((alist '(("apple" . "fruit")
                               ("cat" . "animal")))
                      (call-count 0))
          (fmakunbound 'imakado---test-memoize-fn)
          (defun* imakado---test-memoize-fn (key)
            (prog1 (assoc-default key alist)
              (incf call-count)))
          t)
        )
      (desc "basic")
      (expect t
        (imakado-memoize 'imakado---test-memoize-fn
                 :save-directory (imakado-dirconcat (file-name-directory
                                             (find-library-name "imakado"))
                                            "tmp")
                 :encoding 'japanese-shift-jis-dos
                 :hash-size 20000)
        (imakado---test-memoize-fn "apple")
        (imakado---test-memoize-fn "cat")
        (imakado---test-memoize-fn-hash)
        (imakado---test-memoize-fn-hash-clear-cache)
        (imakado---test-memoize-fn-save)
        (imakado---test-memoize-fn-load)
        )
      )))


;;;; imakado-do-temp-file
(defmacro* imakado-do-temp-file
    ((temp-file-var
      &optional
      file-contents-string
      temp-file-prefix
      (clean-up-p t)
      (temp-file-suffix nil))
     &rest body)
  (declare (indent 1)
           (debug ((symbolp form &optional form symbolp form) body)))
  (imakado-with-gensyms (g-file-contents-string)
    `(let ((,g-file-contents-string ,file-contents-string)
           (,temp-file-var (make-temp-file (format "%s" (or ,temp-file-prefix "do-temp-file."))
                                           nil
                                           ,temp-file-suffix)))
       (unwind-protect
           (progn
             (with-temp-file ,temp-file-var
               (when ,g-file-contents-string
                 (insert ,g-file-contents-string)))
             ,@body)
         (and ,clean-up-p
              (file-exists-p ,temp-file-var)
              (delete-file ,temp-file-var))))))
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-do-temp-file +++++")
      (expect (regexp "imakado-do-temp-file\\.")
        (imakado-do-temp-file (tempfile "contents")
          tempfile))
      (expect (regexp "prefix-")
        (imakado-do-temp-file (tempfile "contents" "prefix-")
          tempfile))
      (expect "contents"
        (imakado-do-temp-file (tempfile "contents" "prefix-")
          (imakado-with-temp-buffer-file tempfile
            (buffer-substring-no-properties (point-min) (point-max)))))
      (desc "omit arg")
      (expect t
        (imakado-do-temp-file (tempfile)
          (file-exists-p tempfile)))
      (desc "cleanup")
      (expect nil
        (let ((gtempfile nil))
          (imakado-do-temp-file (tempfile "contents" "prefix-")
            (setq gtempfile tempfile))
          (file-exists-p gtempfile)))
      )))


;;;; imakado-for-each-single-property-change
(defmacro imakado-for-each-single-property-change (property imakado-fn)
  "imakado-fn is called with two args (current-point next-change-point)"
  (declare (debug (form form)))
  (imakado-with-gensyms (g-fn g-property g-next-change g-current-point)
    `(let ((,g-fn ,imakado-fn)
           (,g-property ,property)
           (,g-next-change nil)
           (,g-current-point nil))
       (save-excursion
         (loop initially (goto-char (point-min))
               for ,g-next-change = (or (next-single-property-change (point) ,g-property (current-buffer))
                                          (point-max))
               for ,g-current-point = (point)
               until (eobp)
               do (goto-char ,g-next-change)
               do (funcall ,g-fn ,g-current-point ,g-next-change))))))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-for-each-single-property-change +++++")
      (expect (true)
        (imakado-with-temp-buffer-file (find-library-name "imakado")
          (emacs-lisp-mode)
          (font-lock-mode t)
          (save-excursion (font-lock-fontify-region (point-min) (point-max)))
          (let ((ret nil)
                (func-name-collector (lambda (p next-change)
                                       (when (eq (get-text-property p 'face) 'font-lock-function-name-face)
                                         (push (buffer-substring-no-properties p next-change) ret)))))
            (imakado-for-each-single-property-change 'face func-name-collector)
            (imakado-remif (imakado-fn (imakado-=~ "^ik:test-" _)) ret))))
      )))

;;;; Eieio utils
(defsubst imakado-define-defmethod-modifies&rest (args)
  (case (car-safe args)
    ((:before :primary :after :static)
     (values (car args) (cdr args)))
    (t (values nil args))))
(defsubst imakado-define-defmethod-add-self-to-args (class rest)
  (imakado-dbind (args . body) rest
    (cons (cons `(self ,class) args)
          body)))
(defmacro imakado-define-defmethod (name class)
  (declare (debug (symbolp symbolp)))
  `(defmacro* ,name (method &rest body)
     (declare (indent 2)
              (debug (&define
                      [&or name
                           ("setf" :name setf name)]
                      [&optional symbolp]
                      list
                      [&optional stringp]
                      def-body)))
     (imakado-dbind (modifier rest) (imakado-define-defmethod-modifies&rest
                             body)
       (let* ((rest (imakado-define-defmethod-add-self-to-args ',class rest))
              (args (if modifier
                        (cons modifier rest)
                      rest)))
         (cons 'defmethod
               (cons method args))))))

;;;; imakado-defclass+
(defmacro imakado-defclass+ (&rest args)
  (let* ((name (car args))
         (defmethod-macro-sym (intern (format "%s-defmethod" name))))
    `(prog1
       (defclass ,@args)
       (imakado-define-defmethod ,defmethod-macro-sym ,name))))
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-defclass+ +++++")
      (expect "aa"
        (flet ((tests/class-b ()))
          (imakado-defclass+ tests/class-b ()
            ((slot-a :initarg :slot-a
                     :initform nil))
            "class a")
          (tests/class-b-defmethod tests/--test-method ()
                                   (with-slots (slot-a) self
                                     (setf slot-a "aa"))
                                   (with-slots (slot-a) self
                                     slot-a))
          (let ((ins (make-instance 'tests/class-b)))
            (tests/--test-method ins))))
      )))

;;;; imakado-require-methods
(defsubst* imakado-require-methods-aux (class methods)
  (loop for method in methods
        collect `(defmethod ,method ((self ,class) &rest ignore)
                   (error "this function should be implemented in subclasses."))))
(defmacro imakado-require-methods (class methods)
  (declare (indent 1)
           (debug (symbolp list)))
  `(progn ,@(imakado-require-methods-aux class methods)))
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-require-methods +++++")
      (expect (error)
        (progn
          (imakado-defclass+ imakado---test-require-methods ()
            ()
            "class")
          (imakado-require-methods imakado---test-require-methods
            (imakado---test-require-methods-interface-fn))
          (let ((ins (make-instance 'imakado---test-require-methods)))
            (imakado---test-require-methods-interface-fn ins))))
      (desc "call with arg")
      (expect (error)
        (progn
          (imakado-defclass+ imakado---test-require-methods ()
            ()
            "class")
          (imakado-require-methods imakado---test-require-methods
            (imakado---test-require-methods-interface-fn))
          (let ((ins (make-instance 'imakado---test-require-methods)))
            (imakado---test-require-methods-interface-fn ins 'a 'b 'c))))
      )))


;;;; imakado-with-orefs
(defmacro imakado-with-orefs (clauses obj &rest body)
  (declare (indent 2)
           (debug ((symbolp &rest symbolp) form body)))
  (let ((clas
         (loop for cla in clauses
               collect
               (etypecase cla
                 (cons `( ,(car cla) ,`(oref ,obj ,(second cla))))
                 (symbol `( ,cla ,`(oref ,obj ,cla)))))))
    `(let ( ,@clas )
       ,@body)))
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-with-orefs +++++")
      (expect '(1 2)
        (progn
          (imakado-defclass+ imakado---test-with-orefs ()
            ((slo1 :initarg :slo1
                   :type integer)
             (slo2 :initarg :slo2
                   :type integer))
            "class")
          (let ((ins (make-instance 'imakado---test-with-orefs
                                    :slo1 1
                                    :slo2 2)))
            (imakado-with-orefs (slo1 (s2 slo2)) ins
                        (list slo1 s2))))
        )
      )))

;;;; imakado-require-slots
(defmacro imakado-require-slots (class slots)
  (declare (indent 1)
           (debug (symbolp list)))
  `(defmethod initialize-instance :AFTER ((self ,class) &rest ignore)
     (progn
       ,@(loop for slo in slots
               collect
               `(assert (slot-boundp self ',slo))))))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-require-slots +++++")
      (expect (error)
        (progn
          (imakado-defclass+ imakado---test-require-slots ()
            ((slo1 :initarg :slo1
                   :type integer)
             (slo2 :initarg :slo2
                   :type integer))
            "class")
          (imakado-require-slots imakado---test-require-slots
                         (slo2))
          (make-instance 'imakado---test-require-slots
                         :slo1 1))
        )
      (expect t
        (progn
          (imakado-defclass+ imakado---test-require-slots ()
            ((slo1 :initarg :slo1
                   :type integer)
             (slo2 :initarg :slo2
                   :type integer))
            "class")
          (imakado-require-slots imakado---test-require-slots
                         (slo2))
          (imakado---test-require-slots-child-p
           (make-instance 'imakado---test-require-slots
                          :slo1 1
                          :slo2 2)))
        )
      )))




(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-define-defmethod +++++")
      (expect (true)
        (flet ((tests/class-a ())
               (message (&rest args) (print (apply 'format args))))
          (defclass tests/class-a ()
            ((slot-a :initarg :slot-a
                     :initform nil))
            "class a")
          (imakado-define-defmethod def-tests/class-a-method tests/class-a)
          (def-tests/class-a-method imakado---test-say-ya ()
            (message "%s" self))
          (def-tests/class-a-method imakado---test-say-ya :before ()
            (message "%s" ":before imakado---test-say-ya"))
          (let ((res (with-output-to-string
                       (imakado---test-say-ya (make-instance 'tests/class-a)))))
            (and (string-match ":before imakado---test-say-ya" res)
                 (string-match "[object tests/class-a tests/class-a nil]" res)))))

      (desc "+++++ imakado-define-defmethod-modifies&rest +++++")
      (expect '(:before (((cla-a tests/class-a)) (message "%s" ":before say-ya")))
        (imakado-dbind (modifier body) (imakado-define-defmethod-modifies&rest
                                '(:before
                                  ((cla-a tests/class-a))
                                  (message "%s" ":before say-ya")))
          (list modifier body))
        )
      (expect '(nil (((cla-a tests/class-a)) (message "%s" ":before say-ya")))
        (imakado-dbind (modifier body) (imakado-define-defmethod-modifies&rest
                                '(((cla-a tests/class-a))
                                  (message "%s" ":before say-ya")))
          (list modifier body)))

      (desc "+++++ imakado-define-defmethod-add-self-to-args +++++")
      (expect '(((self tests/class-a) arg1 arg2) (message "%s" ":before say-ya"))
        (imakado-define-defmethod-add-self-to-args
         'tests/class-a
         '((arg1 arg2)
           (message "%s" ":before say-ya"))))
      )))


;;;; Simple template
(eval-when-compile
  (defvar imakado-simple-template-expression_mark "=")
  (defvar imakado-simple-template-comment_mark "#")

  (defvar imakado-simple-template-tag-start "[%")
  (defvar imakado-simple-template-tag-end "%]")
  (defvar imakado-simple-template-tag-expression-start
    (concat imakado-simple-template-tag-start
            imakado-simple-template-expression_mark))
  (defvar imakado-simple-template-tag-comment-start
    (concat imakado-simple-template-tag-start
            imakado-simple-template-comment_mark))
  ) ;; eval-when-compile
(eval-when-compile
  (defvar imakado-simple-template-token-separator-re
    (rx (or (eval (eval-when-compile imakado-simple-template-tag-expression-start))
            (eval (eval-when-compile imakado-simple-template-tag-comment-start))
            (eval (eval-when-compile imakado-simple-template-tag-start))
            (eval (eval-when-compile imakado-simple-template-tag-end))))))

(defsubst imakado-simple-template-parse-buffer-get-token-and-advance ()
  (let ((p (point)))
    (cond
     ((eobp) nil)
     ((looking-at (eval-when-compile imakado-simple-template-token-separator-re))
      (prog1 (match-string-no-properties 0)
        (goto-char (match-end 0))))
     ((re-search-forward (eval-when-compile imakado-simple-template-token-separator-re) nil t)
      (goto-char (match-beginning 0))
      (buffer-substring-no-properties p (point)))
     (t
      (prog1 (buffer-substring-no-properties p (point-max))
        (goto-char (point-max)))))))
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "imakado-simple-template-parse-buffer-get-token-and-advance")
      (expect '("The " "[%" "  " "%]" " " "[%#" " perfect " "%]" " " "[%=" " insider " "%]" ".")
        (imakado-with-point-buffer "The [%  %] [%# perfect %] [%= insider %]."
          (goto-char (point-min))
          (loop for token = (imakado-simple-template-parse-buffer-get-token-and-advance)
                while token
                collect token)))
      (desc "newline")
      (expect '("The " "[%" "  " "%]" " " "[%#" " \nperfect " "%]" " " "[%=" " outsider " "%]" ".")
        (imakado-with-point-buffer "The [%  %] [%# \nperfect %] [%= outsider %]."
          (goto-char (point-min))
          (loop for token = (imakado-simple-template-parse-buffer-get-token-and-advance)
                while token
                collect token)))
      (expect nil
        (imakado-with-point-buffer ""
          (goto-char (point-min))
          (loop for token = (imakado-simple-template-parse-buffer-get-token-and-advance)
                while token
                collect token)))
      (expect '("newline\n")
        (imakado-with-point-buffer "newline\n"
          (goto-char (point-min))
          (loop for token = (imakado-simple-template-parse-buffer-get-token-and-advance)
                while token
                collect token)))
      (expect '("[%" " (if flag " "%]" "\n" "[%" " ) " "%]")
        (let ((o "you")
              (flag t)
              (tmpl "\
\[% (if flag %]
\[% ) %]"))
          (imakado-with-point-buffer tmpl
            (goto-char (point-min))
            (loop for token = (imakado-simple-template-parse-buffer-get-token-and-advance)
                  while token
                  collect token))))
      )))

(defsubst imakado-simple-template-parse-buffer ()
  (let ((state 'text)
        (multiline_expression nil)
        (tree nil)
        (tag-end (eval-when-compile imakado-simple-template-tag-end))
        (tag-start (eval-when-compile imakado-simple-template-tag-start))
        (tag-comment-start (eval-when-compile imakado-simple-template-tag-comment-start))
        (expression-start (eval-when-compile imakado-simple-template-tag-expression-start)))
    (loop initially (goto-char (point-min))
          with tokens
          for token = (imakado-simple-template-parse-buffer-get-token-and-advance)
          while token
          do (imakado-xcase= token
               ((tag-end)
                (setq state 'text
                      multiline_expression nil))
               ((tag-start)
                (setq state 'code))
               ((tag-comment-start)
                (setq state 'comment))
               ((expression-start)
                (setq state 'expr))
               (otherwise
                (unless (eq state 'comment)
                  (when multiline_expression
                    (setq state 'code))
                  (when (eq state 'expr)
                    (setq multiline_expression t))
                  (push (list state token) tokens))))
          finally return (nreverse tokens))))
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "imakado-simple-template-parse-buffer")
      (expect nil
        (imakado-with-point-buffer "[%# \nperfect %]"
          (imakado-simple-template-parse-buffer)))
      (expect '((text "The ") (code " aa ") (text " \n ") (text " ") (expr " insider ") (text "."))
        (imakado-with-point-buffer "The [% aa %] \n [%# \nperfect %] [%= insider %]."
          (imakado-simple-template-parse-buffer)))
      )))

(defsubst* imakado-simple-template-compile-aux (type value &key (insert-fn 'insert))
  (ecase type
    (text (prin1 `(,insert-fn ,value) (current-buffer)))
    (code (insert value))
    (expr (insert "(insert " value ")"))))
(defsubst* imakado-simple-template-compile (tree)
  (with-temp-buffer
    (insert "(progn ")
    (loop for (type value) in tree
          do (imakado-simple-template-compile-aux type value))
    (insert ")")
    (goto-char (point-min))
    (condition-case err
        (read (current-buffer))
      (error
       (error "\
ERROR occur during compiling template.\ntree: %S\ncompiled source: %S\nerror-message: %s"
              tree (buffer-substring-no-properties (point-min) (point-max))
              (error-message-string err))))))
(defvar imakado-*simple-template-output-buffer nil
  "this variable must be let bounded")

(defsubst* imakado-simple-template-buffer ()
  ;; this temp var name should be prefixed.
  ;; please see test -> (desc "Note, variable `imakado---form' is seen inside tmplate.")
  (let ((imakado---form (imakado-simple-template-compile
                    (imakado-simple-template-parse-buffer)))
        (imakado---output-buffer
         (and (boundp 'imakado-*simple-template-output-buffer)
              (or (stringp (symbol-value 'imakado-*simple-template-output-buffer))
                  (bufferp (symbol-value 'imakado-*simple-template-output-buffer)))
              (get-buffer (symbol-value 'imakado-*simple-template-output-buffer)))))
    (cond
     (imakado---output-buffer
      (with-current-buffer imakado---output-buffer
        (eval imakado---form)))
     (t
      (with-temp-buffer
        (eval imakado---form)
        (buffer-string))))))

(defsubst* imakado-simple-template (file-or-list-of-file)
  (assert (not (null file-or-list-of-file)))
  (with-temp-buffer
    (etypecase file-or-list-of-file
      (list (dolist (file file-or-list-of-file)
              (insert-file-contents file)
              (goto-char (point-max))))
      (string (insert-file-contents file-or-list-of-file)))
    (imakado-simple-template-buffer)))

(defsubst* imakado-simple-template-string (str-or-list-of-string)
  (assert (not (null str-or-list-of-string)))
  (with-temp-buffer
    (etypecase str-or-list-of-string
      (list (insert (mapconcat 'identity str-or-list-of-string "")))
      (string (insert str-or-list-of-string)))
    (imakado-simple-template-buffer)))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-simple-template +++++")
      (desc "basic string")
      (expect "\nflag is non-nil\n"
        (let ((o "you")
              (flag t)
              (tmpl "\
\[% (cond (flag %]
\[% (insert \"flag is non-nil\") %]
\[%)%][%# end FLAG  %][% (t %][%# ELSE %]
\[%# *commant*  %]
\[% (insert \"flag is nil\") %]
\[% )) %][%# end COND %]"))
          (imakado-simple-template-string tmpl)))

      (desc "Note, variable `imakado---form' is seen inside tmplate.")
      (expect (error)
        (let ((imakado---form "lexical"))
          (imakado-do-temp-file (tfile  "loving [%= imakado---form %].")
            (imakado-simple-template tfile))))

      (desc "this gonna well")
      (expect "i miss lexical scope."
        (let ((other-var-name "lexical"))
          (imakado-do-temp-file (tfile  "i miss [%= other-var-name %] scope.")
            (imakado-simple-template tfile))))

      (desc "last newline")
      (expect "newline\n"
        (imakado-do-temp-file (tfile  "newline\n")
          (imakado-simple-template tfile)))

      (desc "basic file")
      (expect "loving you."
        (let ((o  "you"))
          (imakado-do-temp-file (tfile  "loving [%= o %].")
            (imakado-simple-template tfile))))
      (desc "allow newline inside tag")
      (expect "loving you."
        (let ((o "you"))
          (imakado-do-temp-file (tfile  "loving [%= \n  o \n %].")
            (imakado-simple-template tfile))))

      (desc "just string")
      (expect "loving you."
        (imakado-do-temp-file (tfile  "loving you.")
          (imakado-simple-template tfile)))

      (desc "[%# ... %] COMMENT")
      (expect "loving"
        (imakado-do-temp-file (tfile  "loving[%# COMMENT %]")
          (imakado-simple-template tfile)))

      (desc "[%# ... %] newline inside COMMENT ")
      (expect "loving"
        (imakado-do-temp-file (tfile  "loving[%# \n COMMENT \n  %]")
          (imakado-simple-template tfile)))

      (desc "call with nil")
      (expect (error)
        (imakado-do-temp-file (tfile  "loving[%# \n COMMENT \n  %]")
          (imakado-simple-template nil)))

      (desc "call with empty string")
      (expect (error)
        (imakado-simple-template ""))

      (desc "multiple file")
      (expect "1\n2"
        (let ((tmpl1 "1")
              (tmpl2 "2"))
          (imakado-do-temp-file (tfile1  "[%= tmpl1 %]\n")
            (imakado-do-temp-file (tfile2 "[%= tmpl2 %]")
              (imakado-simple-template (list tfile1 tfile2))))))

      (desc "+++++ imakado-simple-template-string +++++")
      (desc "call with nil")
      (expect (error)
        (imakado-simple-template-string nil))

      (desc "call with empty string")
      (expect ""
        (imakado-simple-template-string ""))


      (desc "imakado-*simple-template-output-buffer")
      (desc "No error even if `imakado-*simple-template-output-buffer' is unbound")
      (expect "loving you."
        (let ((imakado-*simple-template-output-buffer imakado-*simple-template-output-buffer))
          (makunbound 'imakado-*simple-template-output-buffer)
          (assert (not (boundp 'imakado-*simple-template-output-buffer)))
          (let ((tmpl  "loving you."))
            (imakado-simple-template-string tmpl))))

      (desc "widget.el support")
      (expect 'push-button
        (let ((insert-push-button
               (imakado-fn () (widget-create
                       'push-button
                       :action (lambda (widget &rest ignore))
                       :value "push-button")))
              (tmpl "`!!'[% (funcall insert-push-button) %]")
              (imakado-*simple-template-output-buffer
               (get-buffer-create "*simple-template-output-buffer test*")))
          (imakado-simple-template-string tmpl)
          (with-current-buffer "*simple-template-output-buffer test*"
            (goto-char (point-min))
            (imakado-goto-pointmark-and-delete)
            (prog1 (first (get-char-property (point) 'button))
              (kill-buffer "*simple-template-output-buffer test*")))))
      )))

;;;; imakado-try-these
(defmacro imakado-try-these (&rest forms)
  (declare (debug (&rest form)))
  `(or ,@(loop for form in forms
               collect `(ignore-errors ,form))))

(defmacro imakado-define-toggle-command (name var)
  `(defun ,name ()
     (interactive)
     (setq ,var
           (not ,var))
     (when (interactive-p)
       (message "%s: %s" (symbol-name ',var) ,var))))


;;;; Utils
(defun imakado-replace-region-aux (start end cb)
  (let* ((str (buffer-substring-no-properties start end))
         (rep-str (funcall cb str)))
    (when rep-str
      (delete-region start end)
      (insert rep-str))))

(defun imakado-empty-string-p (str)
  (or (string-equal "" str)
      (string-match (rx bos (+ space) eos)
                str)))

(defun imakado-rt (text face)
  "Put a face to the given text."
  (unless (stringp text) (setq text (format "%s" (or text ""))))
  (put-text-property 0 (length text) 'face face text)
  (put-text-property 0 (length text) 'font-lock-face face text)
  text)

(defsubst imakado-pput (text prop val)
  "Put a face to the given text.
v:0.04"
  (unless (stringp text) (setq text (format "%s" (or text ""))))
  (put-text-property 0 (length text) prop val text)
  text)

(defsubst* imakado-make-list (a)
  (if (listp a) a (list a)))

(defsubst* imakado-some (pred xs)
  (loop for x in xs
        thereis (funcall pred x)))

(defsubst* imakado-any-match (regexp-or-regexps str)
  (imakado-awhen (imakado-make-list regexp-or-regexps)
    (imakado-some (imakado-fn (string-match _ str)) it)))
(defalias 'imakado-some-match 'imakado-any-match)


(defsubst* imakado-every (pred xs)
  (loop for x in xs
        always (funcall pred x)))

(defsubst imakado-plist-delete (plist prop)
  "Delete property PROP from property list PLIST by side effect.
This modifies PLIST."
  ;; deal with prop at the start
  (while (eq (car plist) prop)
    (setq plist (cddr plist)))
  ;; deal with empty plist
  (when plist
    (let ((lastcell (cdr plist))
          (l (cddr plist)))
      (while l
        (if (eq (car l) prop)
            (progn
              (setq l (cddr l))
              (setcdr lastcell l))
          (setq lastcell (cdr l)
                l (cddr l))))))
  plist)

(defsubst imakado-nonempty-string-p (string)
  (and (stringp string) (not (string= string ""))))

(defsubst* imakado-acdrs (keys alist)
  (mapcar (imakado-fn (_) (imakado-acdr _ alist)) keys))

(defsubst* imakado-assocdrs (keys alist)
  (mapcar (imakado-fn (_) (assoc-default _ alist)) keys))

(defun imakado-sort-by-regexp (re los)
  (loop for s in los
        with matched
        with unmatched
        if (string-match re s)
        do (push s matched)
        else
        do (push s unmatched)
        finally return (nconc (nreverse matched)
                              (nreverse unmatched))))


(defsubst* imakado-avalue-bind-aux (clauses)
  (loop with bind-keys
        with alist-keys
        for c in clauses
        collect (etypecase c
                  (symbol c)
                  (cons (first c)))
        into bind-keys
        collect (etypecase c
                  (symbol c)
                  (cons (second c)))
        into alist-keys
        finally return (list bind-keys alist-keys)))

(defmacro imakado-avalue-bind (clause-keys alist &rest body)
  (declare
   (debug ((&rest &or
                  symbolp
                  (symbolp sexp))
           form body))
   (indent 2))
  (imakado-dbind (bind-keys alist-keys) (imakado-avalue-bind-aux clause-keys)
    `(imakado-dbind ,bind-keys (imakado-acdrs ',alist-keys ,alist)
       ,@body)))

(defsubst* imakado-assoc-value-bind-aux (clauses)
  (loop with bind-keys
        with alist-keys
        for c in clauses
        collect (etypecase c
                  (string (intern c))
                  (cons (first c)))
        into bind-keys
        collect (etypecase c
                  (string c)
                  (cons (second c)))
        into alist-keys
        finally return (list bind-keys alist-keys)))

(defmacro imakado-assoc-value-bind (clause-keys alist &rest body)
  (declare
   (debug ((&rest &or
                  stringp
                  (symbolp sexp))
           form body))
   (indent 2))
  (imakado-dbind (bind-keys alist-keys) (imakado-assoc-value-bind-aux clause-keys)
    `(imakado-dbind ,bind-keys (imakado-assoc-cdrs ',alist-keys ,alist)
       ,@body)))

(defun* imakado-positions->string (start end &key (buffer (current-buffer)))
  (with-current-buffer buffer
    (imakado-aand (buffer-substring-no-properties
           start end))))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (expect '("bob" "pswd")
        (imakado-awhen '((pass . "pswd")
                 (name . "bob"))
          (imakado-avalue-bind (name pass) it
            (list name pass)))
        )
      (expect '("bob" "pswd")
        (imakado-awhen '((pass . "pswd")
                 (name . "bob"))
          (imakado-avalue-bind ((__name name) (__pass pass)) it
            (list __name __pass)))
        )

      (expect '("bob" "pswd")
        (imakado-awhen '(("pass" . "pswd")
                   ("name" . "bob"))
          (imakado-assoc-value-bind ("name" "pass") it
            (list name pass)))
        )
      (expect '("bob" "pswd")
        (imakado-awhen '(("pass" . "pswd")
                   ("name" . "bob"))
          (imakado-assoc-value-bind ((__name "name") (__pass "pass")) it
            (list __name __pass)))
        ))))

(defun* imakado-cycle-list-gen
  (&key get-list-fn
        (cb 'identity)
        (cache t))
  (imakado-with-lexical-bindings (get-list-fn cb cache)
    (lexical-let* ((lst (cond
                         (cache (funcall get-list-fn))
                         (t nil)))
                   (c -1))
      (imakado-fn ()
        (and (not cache)
             (setq lst (funcall get-list-fn)))
        (and (>= (incf c) (length lst))
             (setq c 0))
        (imakado-aand (nth c lst)
              (funcall cb it))))))


(defmacro imakado-define-cycle-list-function (name &rest args)
  (declare (debug t))
  `(progn
     (defvar ,name nil)
     (setq ,name (imakado-cycle-list-gen ,@args))
     (defun ,name ()
       (funcall ,name))))

(defsubst imakado-fast-pp-alist (alist)
  (when alist
    ;(assert (and (consp alist) (consp (car alist))))
    (imakado-with-point-buffer (format "%S" alist)
      (down-list)
      (loop while (ignore-errors (forward-sexp)
                                 t)
            do (newline))
      (buffer-string))))






(defvar imakado-enable-font-lock nil)
(defun imakado-cl-function-syms ()
  (loop for sym being the symbols
        when (imakado-aand (first (plist-get (symbol-plist sym)
                                     'autoload))
                   (imakado-=~ (rx bol "cl" (or eol "-")
                           ) it))
        collect sym))


(defmacro* imakado-remove-if-any-match (re seqs &rest args)
  `(imakado-remif (imakado-fn (imakado-any-match ,re _)) ,seqs ,@args))


;; Todo
(defun imakado-remove-if-some-match (re seqs)
  (imakado-remove-if (lambda (s) (imakado-any-match re s)) seqs))

(defmacro* imakado-remove-if-not-any-match (re seqs &rest args)
  `(imakado-!remif (imakado-fn (imakado-any-match ,re _)) ,seqs ,@args))

; Todo
(defun imakado-remove-if-not-some-match (re seqs)
  (imakado-remove-if-not (lambda (s) (imakado-any-match re s)) seqs))

(defsubst* imakado-trim (s)
  "Remove whitespace at beginning and end of string."
  (imakado-aand (or (imakado-=~ "\\`[ \t\n\r]+" s
                ($sub "" 0 :fixedcase t :literal-string t))
              s)
          (or (imakado-=~ "[ \t\n\r]+\\'" it
                ($sub "" 0 :fixedcase t :literal-string t))
              it)
          it))

(defsubst* imakado-insert-each-line (los)
  (insert (mapconcat 'identity los "\n")))

(defun* imakado-directory-files-recursively
    (regexp &optional directory type (deep nil) &key (internal-current-deep 0))
  (flet ((any-match
          (regexp-or-regexps file-name)
          (when regexp-or-regexps
            (let ((regexps (if (listp regexp-or-regexps) regexp-or-regexps (list regexp-or-regexps))))
              (imakado-some
               (lambda (re)
                 (string-match re file-name))
               regexps))))
         (check-deep-p
          ()
          (and deep
               (> internal-current-deep deep))))
    (unless (check-deep-p)
      (let* ((directory (or directory default-directory))
             (predfunc (case type
                         ((d dir directory) 'file-directory-p)
                         ((f file) 'file-regular-p)
                         (otherwise 'identity)))
             (files (imakado-remove-if
                     (lambda (s)
                       (string-match (rx bol ".")
                                     (file-name-nondirectory s)))
                     (directory-files directory t nil t)))
             (regexps (if (listp regexp) regexp (list regexp))))
        (loop for file in files
              when (and (funcall predfunc file)
                        (any-match regexps (file-name-nondirectory file)))
              collect file into ret
              when (file-directory-p file)
              nconc (imakado-directory-files-recursively regexp file type deep
                                                   :internal-current-deep (1+ internal-current-deep)) into ret
              finally return ret)))))

(defun imakado-call-process-to-string (program &rest args)
  (with-temp-buffer
    (print args (create-file-buffer "imakado-call-process-to-string args"))
    (apply 'call-process program nil t nil args)
    (buffer-string)))

;;;; Http Utils
(eval-when-compile
  (require 'url-util))

(defsubst* imakado-http-hexify-string (string &optional (encoding 'utf-8))
  (mapconcat
   (lambda (byte)
     (if (memq byte url-unreserved-chars)
         (char-to-string byte)
       (format "%%%02x" byte)))
   (if (multibyte-string-p string)
       (encode-coding-string string encoding)
     string)
   ""))

(defsubst* imakado-http-hexify-region (s e)
  (interactive "r")
  (imakado-replace-region-aux
   s e
   (lambda (str) 
     (imakado-http-hexify-string str))))

(defsubst* imakado-escape-html-region (s e)
  (interactive "r")
  (imakado-replace-region-aux
   s e
   (lambda (str) 
     (imakado-escape-html str))))

(defun* imakado-http-build-query (params &optional (encoding 'utf-8))
  (let ((ret (loop for (k . v) in params
                   for k = (etypecase k
                             (symbol (symbol-name k))
                             (string k))
                   for v = (cond
                            ((stringp v) v)
                            ((and (listp v) (= 1 (length v)))
                             (car v))
                            (t v))
                   nconc
                   (etypecase v
                     (list (loop for v in v
                                 collect (mapconcat 'imakado-http-hexify-string (list k v) "=")))
                     (string (list (mapconcat 'imakado-http-hexify-string (list k v) "="))))
                   )))
    (mapconcat 'identity ret "&")))
(defvar imakado-escape-html-table
  '(
    ("&" . "&amp;")
    (">" . "&gt;")
    ("<" . "&lt;")
    ("\"" . "&quot;")
    ("'" . "&#39;")
    ))

(defvar imakado-escape-html-re
  (rx (group (or "&" ">" "<" "\"" "'"))))


(defun imakado-escape-html (str)
  (imakado-with-point-buffer str
    (goto-char (point-min))
    (loop while (re-search-forward imakado-escape-html-re nil t)
          do (replace-match (assoc-default (match-string 1) imakado-escape-html-table))
          finally return (buffer-substring-no-properties (point-min) (point-max)))))

;; (imakado-escape-html "><&&'=\"&&")
;;;; Buffer Utils
(defsubst* imakado-collect-matches
  (re &optional (count 0) (match-string-fn 'match-string)
      (point-min (point-min)) (point-max (point-max)))
  (save-excursion
    (loop initially (goto-char point-min)
          while (re-search-forward re point-max t)
          collect (funcall match-string-fn count))))

;;;; Mode
(defun imakado-set-minor-mode-mode-line (minor-mode str)
  (when (and (boundp 'minor-mode)
             (assq 'minor-mode minor-mode-alist))
    (setcar (cdr (assq 'minor-mode minor-mode-alist)) str)))

;;;; XXX
(defsubst* imakado-get-buffers-by-regexp (regexp)
  (loop for b being the buffers
        for bn = (buffer-name b)
        when (imakado-any-match regexp bn)
        collect b))

;;;; Utility functions
(defun imakado-remove-rassoc (value alist)
  "Delete by side effect any elements of ALIST whose cdr is `equal' to VALUE.
The modified ALIST is returned.  If the first member of ALIST has a car
that is `equal' to VALUE, there is no way to remove it by side effect;
therefore, write `(setq foo (remrassoc value foo))' to be sure of changing
the value of `foo'."
  (while (and (consp alist)
              (or (not (consp (car alist)))
                  (equal (cdr (car alist)) value)))
    (setq alist (cdr alist)))
  (if (consp alist)
      (let ((prev alist)
            (tail (cdr alist)))
        (while (consp tail)
          (if (and (consp (car tail))
                   (equal (cdr (car tail)) value))
              ;; `(setcdr CELL NEWCDR)' returns NEWCDR.
              (setq tail (setcdr prev (cdr tail)))
            (setq prev (cdr prev)
                  tail (cdr tail))))))
  alist)

(defun* imakado-assoc-remove-all (elem alist &key (test (lambda (elem _) (equal elem _))))
  (loop for dlst in alist
        for (key . val) = dlst
        unless (funcall test elem key)
        collect dlst))

(defun* imakado-assoc-remove-keys (elems alist &key (test (lambda (elem _) (equal elem _))))
  (loop for dlst in alist
        for (key . val) = dlst
        unless (member key elems)
        collect dlst))

(defun* imakado-assoc-remove-regexp (regexp alist)
  (imakado-assoc-remove-all regexp alist
                      :test (lambda (re elem)
                              (imakado-any-match (imakado-make-list re) elem))))
(defun* imakado-assq-remove-all (key alist)
  (imakado-assoc-remove-all key alist
                      :test (lambda (key elem)
                              (eq key elem))))
;;;; Time Utils

;;;; Markdown
(defun imakado-markdown->html (str-or-buffer)
  (let ((cmd "Markdown.pl"))
    (assert (executable-find cmd) t "Cant find %s. Please install Text::Markdown")
    (let ((s (etypecase str-or-buffer
               (string str-or-buffer)
               (buffer (with-current-buffer str-or-buffer
                         (buffer-string))))))
      (imakado-do-temp-file (tempfile s)
        (imakado-call-process-to-string cmd
                                  tempfile)))))

(defun imakado-markdown->html-region (s e)
  (interactive "r")
  (let ((cmd "Markdown.pl"))
    (assert (executable-find cmd) t "Cant find %s. Please install Text::Markdown")
    (imakado-do-temp-file (tempfile (buffer-substring s e))
      (imakado-call-process-to-string cmd
                                tempfile))))


(defvar imakado-markdown-extra-wrapper-program
  "\
\<?php
set_include_path(get_include_path().PATH_SEPARATOR.\"/Applications\");
include_once \"markdown.php\";
$input=($argc==1)? 'php://stdin': $argv[1];
$markdown=file_get_contents($input);
$html=Markdown($markdown);
echo($html);
?>
")
(defvar imakado-markdown-extra-path nil)

(defun imakado-markdown-extra->html (str-or-buffer)
  (let ((s (etypecase str-or-buffer
             (string str-or-buffer)
             (buffer (with-current-buffer str-or-buffer
                       (buffer-string))))))
    (imakado-do-temp-file (wrapper-cmd imakado-markdown-extra-wrapper-program)
      (imakado-do-temp-file (tempfile s)
        (let ((default-directory imakado-markdown-extra-path))
          (imakado-call-process-to-string "php"
                                    wrapper-cmd
                                    tempfile))))))



(defun imakado-markdown-extra->html-region (s e)
  (interactive "r")
  (imakado-markdown-extra->html (buffer-substring s e)))


(defun imakado-pandoc-markdown-extra->html (str-or-buffer)
  (let ((s (etypecase str-or-buffer
             (string str-or-buffer)
             (buffer (with-current-buffer str-or-buffer
                       (buffer-string))))))
    (imakado-do-temp-file (wrapper-cmd imakado-markdown-extra-wrapper-program)
      (imakado-do-temp-file (tempfile s)
        (let ((default-directory imakado-markdown-extra-path))
          (imakado-call-process-to-string "pandoc"
                                    "-f"
                                    "markdown_phpextra"
                                    "-t"
                                    "html"
                                    tempfile))))))
(defun imakado-pandoc-markdown->html-region (s e)
  (interactive "r")
  (let ((str (imakado-pandoc-markdown-extra->html (buffer-substring s e))))
    (delete-region s e)
    (insert str)))


(defun imakado-pandoc-html->markdown (str-or-buffer)
  (let ((s (etypecase str-or-buffer
             (string str-or-buffer)
             (buffer (with-current-buffer str-or-buffer
                       (buffer-string))))))
      (imakado-do-temp-file (tempfile s)
        (let ((default-directory imakado-markdown-extra-path))
          (imakado-call-process-to-string "pandoc"
                                    "-f"
                                    "html"
                                    "-t"
                                    "markdown_phpextra"
                                    tempfile)))))

(defun imakado-pandoc-html->markdown-region (s e)
  (interactive "r")
  (let ((str (imakado-pandoc-html->markdown (buffer-substring s e))))
    (delete-region s e)
    (insert str)))



;;;; Datetime
(defstruct (imakado-$datetime
            (:constructor nil)
            (:constructor imakado---make-$datetime)
            (:copier imakado-$datetime-clone))
  time)

(defsubst* imakado-make-$datetime
  (&key
   year
   (month 1)
   (day 1)
   (hour 0)
   (minute 0)
   (second 0))
  (assert (integerp year) t "\
Mandatory parameter :year missing in call to `imakado-make-$datetime'. year is %s")
  (check-type month (integer 1 12))
  (check-type day (integer 1 31))
  (check-type hour (integer 0 23))
  (check-type minute (integer 0 59))
  (check-type second (integer 0 61))
  (let* ((date (list second minute hour day month year))
         (time (apply 'encode-time date)))
    (imakado---make-$datetime
     :time time)))

(defun imakado-$datetime-now ()
  (imakado---make-$datetime
   :time (current-time)))

(defsubst* imakado-$datetime-from-time (time)
  (assert (numberp (first time)))
  (imakado---make-$datetime
   :time time))

(defsubst* imakado-$datetime-from-epoch (time)
  (imakado-$datetime-from-time
   (seconds-to-time time)))

(defsubst imakado-pretty-$datetime ($datetime)
  (check-type $datetime imakado-$datetime)
  (format-time-string
   "%Y年%m月%d日%H時%M分" (imakado-$datetime-time $datetime)))

(eval-when-compile
  (defvar imakado---$datetime-generate-simple-getters-map
    '(
      (year . "%Y")
      (month . "%m")
      ((day day-of-month mday) . "%d")
      ((day-of-week dow wday) . "%w")
      (hour . "%H")
      (minute . "%M")
      (second . "%S")
      ((day-of-year doy) . "%j")
      ))
  (defmacro imakado---$datetime-generate-simple-getters ()
    (let ((flatten-map
           (loop for (name . fm-str) in imakado---$datetime-generate-simple-getters-map
                 if (consp name)
                 append (loop for n in name
                              collect (cons n fm-str))
                 else
                 collect (cons name fm-str))))
      `(progn
         ,@(loop for (fn-name . fm-str) in flatten-map
                 for full-fn-name-sym = (intern (format "imakado-$datetime-%s" fn-name))
                 collect `(defsubst* ,full-fn-name-sym ($datetime)
                            (check-type $datetime imakado-$datetime)
                            (string-to-number
                             (format-time-string ,fm-str
                                                 (imakado-$datetime-time $datetime)))))))))
;; define imakado-$datetime-year, imakado-$datetime-hour, etc...
(imakado---$datetime-generate-simple-getters)

(defsubst* imakado-$datetime-ymd ($datetime &optional (separator "/"))
  (check-type $datetime imakado-$datetime)
  (check-type separator string)
  (mapconcat 'identity
             (mapcar 'number-to-string
                     (list (imakado-$datetime-year $datetime)
                           (imakado-$datetime-month $datetime)
                           (imakado-$datetime-day $datetime)))
             separator))

(defsubst* imakado-$datetime-leap-year-p ($datetime)
  (check-type $datetime imakado-$datetime)
  (let ((year (imakado-$datetime-year $datetime)))
    (or (and (zerop (% year 4))
             (not (zerop (% year 100))))
        (zerop (% year 400)))))
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (expect t
        (imakado-$datetime-leap-year-p
         (imakado-make-$datetime :year 2000)))
      (expect nil
        (imakado-$datetime-leap-year-p
         (imakado-make-$datetime :year 2001)))
      )))

;;;; add, subtract
(defsubst* imakado-$datetime-add
  ($datetime
   &key
   year
   month
   day
   hour
   minute
   second)
  (check-type $datetime imakado-$datetime)
  (let* ((time (imakado-$datetime-time $datetime))
         (date (decode-time time)))
    (and second
         (setf (nth 0 date)
               (+ (nth 0 date) second)))
    (and minute
         (setf (nth 1 date)
               (+ (nth 1 date) minute)))
    (and hour
         (setf (nth 2 date)
               (+ (nth 2 date) hour)))
    (and day
         (setf (nth 3 date)
               (+ (nth 3 date) day)))
    (and month
         (setf (nth 4 date)
               (+ (nth 4 date) month)))
    (and year
         (setf (nth 5 date)
               (+ (nth 5 date) year)))
    (setf (imakado-$datetime-time $datetime)
          (apply 'encode-time date))
    $datetime))

(defsubst* imakado-$datetime-subtract-keys
  ($datetime
   &key
   year
   month
   day
   hour
   minute
   second)
  (check-type $datetime imakado-$datetime)
  (let* ((time (imakado-$datetime-time $datetime))
         (date (decode-time time)))
    (and second
         (setf (nth 0 date)
               (- (nth 0 date) second)))
    (and minute
         (setf (nth 1 date)
               (- (nth 1 date) minute)))
    (and hour
         (setf (nth 2 date)
               (- (nth 2 date) hour)))
    (and day
         (setf (nth 3 date)
               (- (nth 3 date) day)))
    (and month
         (setf (nth 4 date)
               (- (nth 4 date) month)))
    (and year
         (setf (nth 5 date)
               (- (nth 5 date) year)))
    (setf (imakado-$datetime-time $datetime)
          (apply 'encode-time date))
    $datetime))

(defstruct (imakado-$duration
            (:constructor nil)
            (:constructor imakado---make-$duration))
  difference-float)

(defsubst* imakado-$datetime-subtract-op ($datetime1 $datetime2)
  (check-type $datetime1 imakado-$datetime)
  (check-type $datetime2 imakado-$datetime)
  (imakado---make-$duration
   :difference-float
   (- (float-time (imakado-$datetime-time $datetime1))
      (float-time (imakado-$datetime-time $datetime2)))))

(defun imakado-$datetime-subtract (&rest args)
  (cond
   ((imakado-$datetime-p (second args))
    (imakado-$datetime-subtract-op (first args) (second args)))
   (t
    (apply 'imakado-$datetime-subtract-keys args))))

(defsubst* imakado-$datetime-compare-aux (op $datetime1 $datetime2)
  (check-type $datetime1 imakado-$datetime)
  (check-type $datetime2 imakado-$datetime)
  (funcall op
           (float-time (imakado-$datetime-time $datetime1))
           (float-time (imakado-$datetime-time $datetime2))))
(defsubst* imakado-$datetime-< ($d1 $d2)
  (imakado-$datetime-compare-aux '< $d1 $d2))
(defsubst* imakado-$datetime-> ($d1 $d2)
  (imakado-$datetime-compare-aux '> $d1 $d2))

(defsubst* imakado-$duration-pretty-string-aux (diff-seconds)
  (cond
   ((< diff-seconds 60)
    (values 'second (round diff-seconds)))
   ((< diff-seconds 3600)
    (values 'minute (round (/ diff-seconds 60))))
   ((< diff-seconds (+ 86400 3600))
    (values 'hour (round (/ diff-seconds 3600))))
   ((< diff-seconds (+ 259200 86400))
    (values 'day (round (/ diff-seconds 86400))))
   (t
    nil)))

(defsubst* imakado-$duration-pretty-string-japanese ($duration)
  (check-type $duration imakado-$duration)
  (imakado-acond
    ((imakado-$duration-pretty-string-aux (imakado-$duration-difference-float
                                        $duration))
     (imakado-dbind (tag val) it
       (ecase tag
         (second (format "%s秒" val))
         (minute (format "%s分" val))
         (hour (format "%s時間" val))
         (day (format "%s日" val)))))
    (t (format "%s日" (round
                       (/ (imakado-$duration-difference-float
                           $duration)
                          86400))))))

;;;; XXX
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-$datetime-< +++++")
      (expect nil
        (imakado-$datetime-<
         (imakado-make-$datetime :year 2012
                              :month 7
                              :day 14)
         (imakado-make-$datetime :year 2012
                              :month 7
                              :day 12)))

      (desc "+++++ imakado-$datetime-> +++++")
      (expect t
        (imakado-$datetime->
         (imakado-make-$datetime :year 2012
                              :month 7
                              :day 14)
         (imakado-make-$datetime :year 2012
                              :month 7
                              :day 12)))

      (desc "+++++ imakado-$datetime-subtract +++++")
      (expect "2日"
        (imakado-$duration-pretty-string-japanese
         (imakado-$datetime-subtract
          (imakado-make-$datetime :year 2012
                               :month 7
                               :day 14)
          (imakado-make-$datetime :year 2012
                               :month 7
                               :day 12))))
      (expect "33日"
        (imakado-$duration-pretty-string-japanese
         (imakado-$datetime-subtract
          (imakado-make-$datetime :year 2012
                               :month 8
                               :day 14)
          (imakado-make-$datetime :year 2012
                               :month 7
                               :day 12))))
      (expect "2時間"
        (imakado-$duration-pretty-string-japanese
         (imakado-$datetime-subtract
          (imakado-make-$datetime :year 2012
                               :month 7
                               :day 14
                               :hour 18
                               :minute 0)
          (imakado-make-$datetime :year 2012
                               :month 7
                               :day 14
                               :hour 16
                               :minute 30))))
      (expect "30分"
        (imakado-$duration-pretty-string-japanese
         (imakado-$datetime-subtract
          (imakado-make-$datetime :year 2012
                               :month 7
                               :day 14
                               :hour 18
                               :minute 0)
          (imakado-make-$datetime :year 2012
                               :month 7
                               :day 14
                               :hour 17
                               :minute 30))))
      (expect "30秒"
        (imakado-$duration-pretty-string-japanese
         (imakado-$datetime-subtract
          (imakado-make-$datetime :year 2012
                               :month 7
                               :day 14
                               :hour 18
                               :minute 0)
          (imakado-make-$datetime :year 2012
                               :month 7
                               :day 14
                               :hour 17
                               :minute 59
                               :second 30))))
      )))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-$datetime-add +++++")
      (expect "2020年05月12日01時53分"
        (with-stub
          (stub current-time => '(19436 11933 218000))
          (let ((now (imakado-$datetime-now)))
            (imakado-$datetime-add now
                                :year 10)
            (imakado-$datetime-subtract now
                                     :day 2)
            (imakado-pretty-$datetime now))))

      (expect "2010年05月15日01時53分"
        (with-stub
          (stub current-time => '(19436 11933 218000))
          (let ((now (imakado-$datetime-now)))
            (imakado-pretty-$datetime now) ;;"2010年05月14日01時53分"
            (imakado-$datetime-add now
                                :day 1)
            (imakado-pretty-$datetime now)))
        )

      (desc "+++++ imakado-$datetime-ymd +++++")
      (expect "2010/5/14"
        (with-stub
          (stub current-time => '(19436 11933 218000))
          (let ((now (imakado-$datetime-now)))
            (imakado-$datetime-ymd now))))
      (expect "2010+5+14"
        (with-stub
          (stub current-time => '(19436 11933 218000))
          (let ((now (imakado-$datetime-now)))
            (imakado-$datetime-ymd now "+"))))

      )))






;;;; Datetime Test.
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-make-$datetime +++++")
      (expect (error)
        (imakado-make-$datetime))

      (desc "+++++ imakado-$datetime-now +++++")
      (expect t
        (imakado-$datetime-p (imakado-$datetime-now)))

      (desc "+++++ imakado-$datetime-year +++++")
      (expect (error)
        (imakado-$datetime-year
         'not-$datetime))
      (expect 2000
        (imakado-$datetime-year
         (imakado-make-$datetime :year 2000)))

      (desc "+++++ imakado-$datetime-month +++++")
      (expect 12
        (imakado-$datetime-month
         (imakado-make-$datetime :year 2000
                              :month 12)))

      (desc "+++++ imakado-$datetime-day +++++")
      (expect 30
        (imakado-$datetime-day
         (imakado-make-$datetime :year 2000
                              :month 12
                              :day 30)))
      (expect 30
        (imakado-$datetime-day-of-month
         (imakado-make-$datetime :year 2000
                              :month 12
                              :day 30)))
      (expect 30
        (imakado-$datetime-mday
         (imakado-make-$datetime :year 2000
                              :month 12
                              :day 30)))

      (desc "+++++ imakado-$datetime-day-of-week +++++")
      (desc "Note, Monday is 1")
      (expect 1
        (imakado-$datetime-day-of-week
         (imakado-make-$datetime :year 2010
                              :month 5
                              :day 10)))

      (desc "+++++ imakado-$datetime-hour +++++")
      (expect 9
        (imakado-$datetime-hour
         (imakado-make-$datetime :year 2010
                              :month 5
                              :day 10
                              :hour 9)))

      (desc "+++++ imakado-$datetime-minute +++++")
      (expect 7
        (imakado-$datetime-minute
         (imakado-make-$datetime :year 2010
                              :month 5
                              :day 10
                              :hour 9
                              :minute 7)))

      (desc "+++++ imakado-$datetime-second +++++")
      (expect 59
        (imakado-$datetime-second
         (imakado-make-$datetime :year 2010
                              :month 5
                              :day 10
                              :hour 9
                              :minute 7
                              :second 59)))

      (desc "+++++ imakado-$datetime-day-of-year +++++")
      (expect 365
        (imakado-$datetime-day-of-year
         (imakado-make-$datetime :year 2010
                              :month 12
                              :day 31)))
      (desc "leap year")
      (expect 366
        (imakado-$datetime-day-of-year
         (imakado-make-$datetime :year 2000
                              :month 12
                              :day 31)))

      (desc "+++++ imakado-pretty-$datetime +++++")
      (expect (error)
        (imakado-pretty-$datetime nil))
      (expect "2000年01月01日00時00分"
        (imakado-pretty-$datetime
         (imakado-make-$datetime :year 2000)))
      )))

(defsubst* imakado-days-ago-time (n time)
  (check-type n integer)
  (let ((date (decode-time time)))
    (setf (nth 3 date)
          (- (nth 3 date) n))
    (apply 'encode-time date)))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ Datetime +++++")
      (let* ((test-time '(19423 243 265000))
             (7-days-ago-time (imakado-days-ago-time 7 test-time))
             (6-days-ago-time '(19415 6131))
             (8-days-ago-time '(19412 29939)))
        (assert (equal "05/04/10" (format-time-string "%D" test-time)))
        (assert (equal "04/27/10" (format-time-string "%D" 7-days-ago-time)))
        (assert
         (eq t (time-less-p 7-days-ago-time 6-days-ago-time)))
        (assert
         (eq nil (time-less-p 7-days-ago-time 8-days-ago-time))))
      )))

(defun imakado-pretty-time-japanese (time)
  (assert (numberp (first time)))
  (format-time-string
   "%Y年%m月%d日%H時%M分" time))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-pretty-time-japanese +++++")
      (with-stub
        (stub current-time => '(19435 42791 41987))
        (imakado-pretty-time-japanese (current-time)))
      )))


;;;; symlink
(defun* imakado-get-symlink-target-recursively (f &optional (deep-limit 10))
  (unless (= deep-limit 0)
    (imakado-aif (file-symlink-p f)
        (imakado-get-symlink-target-recursively it (1- deep-limit))
      f)))

(defun imakado-normalize-file-name (path)
  (imakado-aand (expand-file-name path)
        (if (file-directory-p path)
            (concat (imakado-=~ "/*$" it ($sub ""))
                    "/")
          (imakado-=~ "/*$" it ($sub "")))))

;;;; Font lock support
(defgroup imakado nil
  "imakado.el"
  :prefix "imakado-"
  :group 'convenience)
(defface imakado-keyword-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for macros are defined in imakado.el"
  :group 'imakado)

(defvar imakado-keyword-face 'imakado-keyword-face
  "Face name to use for function names.")

(defun imakado-font-lock-keyword-matcher2 (limit)
  (when imakado-enable-font-lock
    (let ((re (rx "("
                  (group (or "imakado-defcacheable"
                             "imakado-define-define-keymap" 
                             "imakado-define-with-all-slots-struct"
                             "imakado-define-with-struct-macro"
                             "imakado-define-macro-aliases"
                             "imakado-define-macro-alias"
                             "imakado-defclass+"
                             "imakado-define-defmethod"
                             "imakado-define-cycle-list-function"
                             ))
                  (+ space)
                  (group (+ (or (syntax symbol) (syntax word)))))))
      (when (re-search-forward re limit t)
        (set-match-data (match-data))
        t))))


(dolist (mode '(emacs-lisp-mode lisp-interaction-mode))
  (font-lock-add-keywords
   mode
   '((imakado-font-lock-keyword-matcher1
      (1 imakado-keyword-face append))
     (imakado-font-lock-keyword-matcher2
      (1 imakado-keyword-face append)
      (2 font-lock-function-name-face append)))))

;;;; Aliases

(defun imakado-font-lock-keywords-1 ()
  (list
   "imakado-require-version"
   "imakado-gensym"
   "imakado-group"
   "imakado-allquote"
   "imakado-in-aux-test"
   "imakado-flatten"
   "imakado-subseq"
   "imakado-remove-if"
   "imakado-remove-if-not"
   "imakado-acdr"
;   "acdr"
   "imakado-assq-rest"
   "imakado-with-gensyms"
   "imakado-with-lexical-bindings"
   "imakado-dirconcat"
   "imakado-remif-aux"
   "imakado-remif"
   "imakado-!remif"
   "imakado-aif"
   "imakado-awhen"
   "imakado-awhile"
   "imakado-aand"
   "imakado-acond"
   "imakado-alambda"
   "imakado-cond-let-aux-vars"
   "imakado-cond-let-aux-binds"
   "imakado-cond-let-aux-clause"
   "imakado-cond-let"
   "imakado-when-let"
   "imakado-fn-aux-anaph-arg-syms"
   "imakado-fn-aux-appear_?"
   "imakado-fn-aux"
   "imakado-fn"
   "imakado-define-macro-alias"
   "imakado-define-macro-aliases"
   "imakado-cars"
   "imakado-cdrs"
   "imakado-cadrs"
   "imakado-assoc-cdrs"
   "imakado-nths"
   "imakado-in"
   "imakado-inq"
   "imakado-in="
   "imakado-join+"
   "imakado-case-cond-clause-aux"
   "imakado-xcase"
   "imakado-xcase-clause-aux-test"
   "imakado-xcase-clause-aux"
   "imakado-xcase="
   "imakado-with-struct"
   "imakado-define-with-struct-macro"
   "imakado-with-struct-all-slots-get-getters-slot?"
   "imakado-with-struct-all-slots-get-all-slots"
   "imakado-define-with-all-slots-struct"
   "imakado-dolist-with-progress-reporter"
   "imakado-with-anaphoric-match-utilities"
   "imakado-=~"
   "imakado-case-regexp-aux"
   "imakado-case-regexp"
   "imakado-match-with-temp-buffer"
   "imakado-with-temp-buffer-file"
   "imakado-match-with-temp-buffer-file"
   "imakado-save-excursion-force"
   "imakado-goto-pointmark-and-delete"
   "imakado-with-point-buffer"
   "imakado-memoize"
   "imakado---test-memoize-fn"
   "imakado-do-temp-file"
   "imakado-for-each-single-property-change"
   "imakado-require-methods-aux"
   "imakado-require-methods"
   "imakado-with-orefs"
   "imakado-require-slots"
   "imakado-simple-template-parse-buffer-get-token-and-advance"
   "imakado-simple-template-parse-buffer"
   "imakado-simple-template-compile-aux"
   "imakado-simple-template-compile"
   "imakado-simple-template-buffer"
   "imakado-simple-template"
   "imakado-simple-template-string"
   "imakado-try-these"
   "imakado-rt"
   "imakado-make-list"
   "imakado-some"
   "imakado-any-match"
   "imakado-every"
   "imakado-collect-matches"
   "imakado-get-buffers-by-regexp"
   "imakado-font-lock-keyword-matcher1"
   "imakado-font-lock-keyword-matcher2"
   "imakado-gensym"
   "imakado-group"
   "imakado-allquote"
   "imakado-flatten"
   "imakado-subseq"
   "imakado-remove-if"
   "imakado-remove-if-not"
   "imakado-acdr"
   "imakado-remif-aux"
   "imakado-goto-pointmark-and-delete"
   "imakado-simple-template-buffer"
   "imakado-rt"
   "imakado-make-list"
   "imakado-some"
   "imakado-any-match"
   "imakado-every"
   "imakado-collect-matches"
   "imakado-get-buffers-by-regexp"
   "imakado-imakado-require-version"
   "imakado-acdr"
   "imakado-with-gensyms"
   "imakado-with-lexical-bindings"
   "imakado-dirconcat"
   "imakado-remif"
   "imakado-!remif"
   "imakado-aif"
   "imakado-awhen"
   "imakado-awhile"
   "imakado-aand"
   "imakado-acond"
   "imakado-alambda"
   "imakado-cond-let"
   "imakado-when-let"
   "imakado-fn"
   "imakado-cars"
   "imakado-cdrs"
   "imakado-cadrs"
   "imakado-assoc-cdrs"
   "imakado-nths"
   "imakado-in"
   "imakado-inq"
   "imakado-in="
   "imakado-join+"
   "imakado-xcase"
   "imakado-xcase="
   "imakado-with-struct"
   "imakado-dolist-with-progress-reporter"
   "imakado-with-anaphoric-match-utilities"
   "imakado-=~"
   "imakado-case-regexp"
   "imakado-match-with-temp-buffer"
   "imakado-with-temp-buffer-file"
   "imakado-match-with-temp-buffer-file"
   "imakado-save-excursion-force"
   "imakado-with-point-buffer"
   "imakado-memoize"
   "imakado-do-temp-file"
   "imakado-for-each-single-property-change"
   "imakado-define-defmethod"
   "imakado-defclass+"
   "imakado-require-methods"
   "imakado-with-orefs"
   "imakado-require-slots"
   "imakado-simple-template"
   "imakado-simple-template-string"
   "imakado-try-these"
   "imakado-font-lock-keywords-1"
   "imakado-test-macro"
   ))

(imakado-defcacheable imakado-font-lock-keyword-matcher1-re ()
    (rx-to-string
     `(and "("
           (group "imakado-"
                  (+ (or (syntax word)
                         (syntax symbol))))
           symbol-end)))

(defun imakado-font-lock-keyword-matcher1 (limit)
  (when imakado-enable-font-lock
    (let ((re (imakado-font-lock-keyword-matcher1-re)))
      (when (re-search-forward re limit t)
        (set-match-data (match-data))
        t))))

(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (expect t
        (imakado-some 'evenp (number-sequence 0 10 2)))
      (expect nil
        (imakado-some 'oddp (number-sequence 0 10 2)))
      (expect t
        (imakado-every 'evenp (number-sequence 0 10 2)))
      (expect nil
        (imakado-every 'evenp '(2 4 5)))
      )))        
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "+++++ imakado-try-these +++++")
      (expect "ok"
        (imakado-try-these (error "aa")
                   (progn "ok")
                   (error "bb")))
      (expect "ok"
        (flet ((imakado---try-these-test () (return nil)))
          (imakado-try-these (imakado---try-these-test)
                     (progn "ok")
                     (error "bb"))))
      (expect nil
        (let ((called nil))
          (flet ((imakado---try-these-test () (setq called t)))
            (imakado-try-these (error "aa")
                       (progn "ok")
                       (imakado---try-these-test))
            called)))
      (expect t
        (let ((called nil))
          (flet ((imakado---try-these-test () (setq called t)))
            (imakado-try-these (error "aa")
                       (progn (imakado---try-these-test)
                              "ok")
                       "bb")
            called)))
      )))


;;;; singularize, Pluralize
(imakado-defcacheable imakado-plural-rules ()
  '(("atlas$" "atlases")
    ("beef$" "beefs")
    ("brother$" "brothers")
    ("child$" "children")
    ("corpus$" "corpuses")
    ("cows$" "cows")
    ("ganglion$" "ganglions")
    ("genie$" "genies")
    ("genus$" "genera")
    ("graffito$" "graffiti")
    ("hoof$" "hoofs")
    ("loaf$" "loaves")
    ("man$" "men")
    ("money$" "monies")
    ("mongoose$" "mongooses")
    ("move$" "moves")
    ("mythos$" "mythoi")
    ("numen$" "numina")
    ("occiput$" "occiputs")
    ("octopus$" "octopuses")
    ("opus$" "opuses")
    ("ox$" "oxen")
    ("penis$" "penises")
    ("person$" "people")
    ("sex$" "sexes")
    ("soliloquy$" "soliloquies")
    ("testis$" "testes")
    ("trilby$" "trilbys")
    ("turf$" "turfs")

    ("\\(.*[nrlm]ese\\)$" "\\1")
    ("\\(.*deer\\)$" "\\1")
    ("\\(.*fish\\)$" "\\1")
    ("\\(.*measles\\)$" "\\1")
    ("\\(.*ois\\)$" "\\1")
    ("\\(.*pox\\)$" "\\1")
    ("\\(.*sheep\\)$" "\\1")
    ("\\(Amoyese\\)$" "\\1")
    ("\\(bison\\)$" "\\1")
    ("\\(Borghese\\)$" "\\1")
    ("\\(bream\\)$" "\\1")
    ("\\(breeches\\)$" "\\1")
    ("\\(britches\\)$" "\\1")
    ("\\(buffalo\\)$" "\\1")
    ("\\(cantus\\)$" "\\1")
    ("\\(carp\\)$" "\\1")
    ("\\(chassis\\)$" "\\1")
    ("\\(clippers\\)$" "\\1")
    ("\\(cod\\)$" "\\1")
    ("\\(coitus\\)$" "\\1")
    ("\\(Congoese\\)$" "\\1")
    ("\\(contretemps\\)$" "\\1")
    ("\\(corps\\)$" "\\1")
    ("\\(debris\\)$" "\\1")
    ("\\(diabetes\\)$" "\\1")
    ("\\(djinn\\)$" "\\1")
    ("\\(eland\\)$" "\\1")
    ("\\(elk\\)$" "\\1")
    ("\\(equipment\\)$" "\\1")
    ("\\(Faroese\\)$" "\\1")
    ("\\(flounder\\)$" "\\1")
    ("\\(Foochowese\\)$" "\\1")
    ("\\(gallows\\)$" "\\1")
    ("\\(Genevese\\)$" "\\1")
    ("\\(Genoese\\)$" "\\1")
    ("\\(Gilbertese\\)$" "\\1")
    ("\\(graffiti\\)$" "\\1")
    ("\\(headquarters\\)$" "\\1")
    ("\\(herpes\\)$" "\\1")
    ("\\(hijinks\\)$" "\\1")
    ("\\(Hottentotese\\)$" "\\1")
    ("\\(information\\)$" "\\1")
    ("\\(innings\\)$" "\\1")
    ("\\(jackanapes\\)$" "\\1")
    ("\\(Kiplingese\\)$" "\\1")
    ("\\(Kongoese\\)$" "\\1")
    ("\\(Lucchese\\)$" "\\1")
    ("\\(mackerel\\)$" "\\1")
    ("\\(Maltese\\)$" "\\1")
    ("\\(media\\)$" "\\1")
    ("\\(mews\\)$" "\\1")
    ("\\(moose\\)$" "\\1")
    ("\\(mumps\\)$" "\\1")
    ("\\(Nankingese\\)$" "\\1")
    ("\\(news\\)$" "\\1")
    ("\\(nexus\\)$" "\\1")
    ("\\(Niasese\\)$" "\\1")
    ("\\(Pekingese\\)$" "\\1")
    ("\\(Piedmontese\\)$" "\\1")
    ("\\(pincers\\)$" "\\1")
    ("\\(Pistoiese\\)$" "\\1")
    ("\\(pliers\\)$" "\\1")
    ("\\(Portuguese\\)$" "\\1")
    ("\\(proceedings\\)$" "\\1")
    ("\\(rabies\\)$" "\\1")
    ("\\(rice\\)$" "\\1")
    ("\\(rhinoceros\\)$" "\\1")
    ("\\(salmon\\)$" "\\1")
    ("\\(Sarawakese\\)$" "\\1")
    ("\\(scissors\\)$" "\\1")
    ("\\(sea[- ]bass\\)$" "\\1")
    ("\\(series\\)$" "\\1")
    ("\\(Shavese\\)$" "\\1")
    ("\\(shears\\)$" "\\1")
    ("\\(siemens\\)$" "\\1")
    ("\\(species\\)$" "\\1")
    ("\\(swine\\)$" "\\1")
    ("\\(testes\\)$" "\\1")
    ("\\(trousers\\)$" "\\1")
    ("\\(trout\\)$" "\\1")
    ("\\(tuna\\)$" "\\1")
    ("\\(Vermontese\\)$" "\\1")
    ("\\(Wenchowese\\)$" "\\1")
    ("\\(whiting\\)$" "\\1")
    ("\\(wildebeest\\)$" "\\1")
    ("\\(Yengeese\\)$" "\\1")

    ("\\(s\\)tatus$" "statuses")
    ("\\(quiz\\)$" "quizzes")
    ("^\\(ox\\)$" "oxen")
    ("\\([m\\|l]\\)ouse$" "\\1ice")
    ("\\(matr\\|vert\\|ind\\)\\(ix\\|ex\\)$" "\\1ices")
    ("\\(x\\|ch\\|ss\\|sh\\)$" "\\1es")
    ("\\([^aeiouy]\\|qu\\)y$" "\\1ies")
    ("\\(hive\\)$" "hives")
    ("\\(\\([^f]\\)fe\\|\\([lr]\\)f\\)$" "\\1\\3ves")
    ("sis$" "ses")
    ("\\([ti]\\)um$" "\\1a")
    ("\\(p\\)erson$" "\\1eople")
    ("\\(m\\)an$" "\\1en")
    ("\\(c\\)hild$" "\\1hildren")
    ("\\(buffal\\|tomat\\)o$" "\\1\\2oes")
    ("\\(alumn\\|bacill\\|cact\\|foc\\|fung\\|nucle\\|radi\\|stimul\\|syllab\\|termin\\|vir\\)us$" "\\1")
    ("us$" "uses")
    ("\\(alias\\)$" "\\1es")
    ("\\(ax\\|cri\\|test\\)is$" "\\1es")
    ("s$" "s")
    ("$" "s"))
  )

(imakado-defcacheable imakado-singular-rules ()
  '(("atlases$" "atlas")
    ("beefs$" "beef")
    ("brothers$" "brother")
    ("children$" "child")
    ("corpuses$" "corpus")
    ("cows$" "cow")
    ("ganglions$" "ganglion")
    ("genies$" "genie")
    ("genera$" "genus")
    ("graffiti$" "graffito")
    ("hoofs$" "hoof")
    ("loaves$" "loaf")
    ("men$" "man")
    ("monies$" "money")
    ("mongooses$" "mongoose")
    ("moves$" "move")
    ("mythoi$" "mythos")
    ("numina$" "numen")
    ("occiputs$" "occiput")
    ("octopuses$" "octopus")
    ("opuses$" "opus")
    ("oxen$" "ox")
    ("penises$" "penis")
    ("people$" "person")
    ("sexes$" "sex")
    ("soliloquies$" "soliloquy")
    ("testes$" "testis")
    ("trilbys$" "trilby")
    ("turfs$" "turf")

    ("\\(.*[nrlm]ese\\)$" "\\1")
    ("\\(.*deer\\)$" "\\1")
    ("\\(.*fish\\)$" "\\1")
    ("\\(.*measles\\)$" "\\1")
    ("\\(.*ois\\)$" "\\1")
    ("\\(.*pox\\)$" "\\1")
    ("\\(.*sheep\\)$" "\\1")
    ("\\(Amoyese\\)$" "\\1")
    ("\\(bison\\)$" "\\1")
    ("\\(Borghese\\)$" "\\1")
    ("\\(bream\\)$" "\\1")
    ("\\(breeches\\)$" "\\1")
    ("\\(britches\\)$" "\\1")
    ("\\(buffalo\\)$" "\\1")
    ("\\(cantus\\)$" "\\1")
    ("\\(carp\\)$" "\\1")
    ("\\(chassis\\)$" "\\1")
    ("\\(clippers\\)$" "\\1")
    ("\\(cod\\)$" "\\1")
    ("\\(coitus\\)$" "\\1")
    ("\\(Congoese\\)$" "\\1")
    ("\\(contretemps\\)$" "\\1")
    ("\\(corps\\)$" "\\1")
    ("\\(debris\\)$" "\\1")
    ("\\(diabetes\\)$" "\\1")
    ("\\(djinn\\)$" "\\1")
    ("\\(eland\\)$" "\\1")
    ("\\(elk\\)$" "\\1")
    ("\\(equipment\\)$" "\\1")
    ("\\(Faroese\\)$" "\\1")
    ("\\(flounder\\)$" "\\1")
    ("\\(Foochowese\\)$" "\\1")
    ("\\(gallows\\)$" "\\1")
    ("\\(Genevese\\)$" "\\1")
    ("\\(Genoese\\)$" "\\1")
    ("\\(Gilbertese\\)$" "\\1")
    ("\\(graffiti\\)$" "\\1")
    ("\\(headquarters\\)$" "\\1")
    ("\\(herpes\\)$" "\\1")
    ("\\(hijinks\\)$" "\\1")
    ("\\(Hottentotese\\)$" "\\1")
    ("\\(information\\)$" "\\1")
    ("\\(innings\\)$" "\\1")
    ("\\(jackanapes\\)$" "\\1")
    ("\\(Kiplingese\\)$" "\\1")
    ("\\(Kongoese\\)$" "\\1")
    ("\\(Lucchese\\)$" "\\1")
    ("\\(mackerel\\)$" "\\1")
    ("\\(Maltese\\)$" "\\1")
    ("\\(media\\)$" "\\1")
    ("\\(mews\\)$" "\\1")
    ("\\(moose\\)$" "\\1")
    ("\\(mumps\\)$" "\\1")
    ("\\(Nankingese\\)$" "\\1")
    ("\\(news\\)$" "\\1")
    ("\\(nexus\\)$" "\\1")
    ("\\(Niasese\\)$" "\\1")
    ("\\(Pekingese\\)$" "\\1")
    ("\\(Piedmontese\\)$" "\\1")
    ("\\(pincers\\)$" "\\1")
    ("\\(Pistoiese\\)$" "\\1")
    ("\\(pliers\\)$" "\\1")
    ("\\(Portuguese\\)$" "\\1")
    ("\\(proceedings\\)$" "\\1")
    ("\\(rabies\\)$" "\\1")
    ("\\(rice\\)$" "\\1")
    ("\\(rhinoceros\\)$" "\\1")
    ("\\(salmon\\)$" "\\1")
    ("\\(Sarawakese\\)$" "\\1")
    ("\\(scissors\\)$" "\\1")
    ("\\(sea[- ]bass\\)$" "\\1")
    ("\\(series\\)$" "\\1")
    ("\\(Shavese\\)$" "\\1")
    ("\\(shears\\)$" "\\1")
    ("\\(siemens\\)$" "\\1")
    ("\\(species\\)$" "\\1")
    ("\\(swine\\)$" "\\1")
    ("\\(testes\\)$" "\\1")
    ("\\(trousers\\)$" "\\1")
    ("\\(trout\\)$" "\\1")
    ("\\(tuna\\)$" "\\1")
    ("\\(Vermontese\\)$" "\\1")
    ("\\(Wenchowese\\)$" "\\1")
    ("\\(whiting\\)$" "\\1")
    ("\\(wildebeest\\)$" "\\1")
    ("\\(Yengeese\\)$" "\\1")

    ("\\(s\\)tatuses$" "\\1\\2tatus")
    ("^\\(.*\\)\\(menu\\)s$" "\\1\\2")
    ("\\(quiz\\)zes$" "\\1")
    ("\\(matr\\)ices$" "\\1ix")
    ("\\(vert\\|ind\\)ices$" "\\1ex")
    ("^\\(ox\\)en" "\\1")
    ("\\(alias\\)\\(es\\)*$" "\\1")
    ("\\(alumn\\|bacill\\|cact\\|foc\\|fung\\|nucle\\|radi\\|stimul\\|syllab\\|termin\\|viri?\\)i$" "\\1us")
    ("\\(cris\\|ax\\|test\\)es$" "\\1is")
    ("\\(shoe\\)s$" "\\1")
    ("\\(o\\)es$" "\\1")
    ("ouses$" "ouse")
    ("uses$" "us")
    ("\\([m\\|l]\\)ice$" "\\1ouse")
    ("\\(x\\|ch\\|ss\\|sh\\)es$" "\\1")
    ("\\(m\\)ovies$" "\\1\\2ovie")
    ("\\(s\\)eries$" "\\1\\2eries")
    ("\\([^aeiouy]\\|qu\\)ies$" "\\1y")
    ("\\([lr]\\)ves$" "\\1f")
    ("\\(tive\\)s$" "\\1")
    ("\\(hive\\)s$" "\\1")
    ("\\(drive\\)s$" "\\1")
    ("\\([^f]\\)ves$" "\\1fe")
    ("\\(^analy\\)ses$" "\\1sis")
    ("\\(\\(a\\)naly\\|\\(b\\)a\\|\\(d\\)iagno\\|\\(p\\)arenthe\\|\\(p\\)rogno\\|\\(s\\)ynop\\|\\(t\\)he\\)ses$" "\\1\\2sis")
    ("\\([ti]\\)a$" "\\1um")
    ("\\(p\\)eople$" "\\1\\2erson")
    ("\\(m\\)en$" "\\1an")
    ("\\(c\\)hildren$" "\\1\\2hild")
    ("\\(n\\)ews$" "\\1\\2ews")
    ("^\\(.*us\\)$" "\\1")
    ("s$" "")
    ("$" ""))
  )

(defun imakado-pluralize (str)
  "Pluralize str"
  (interactive)
  (let ((result str))
    (loop for (from to)  in (imakado-plural-rules) do
          (unless (not (string-match from str))
            (setq result (replace-match to nil nil str))
            (return result)))))

(defun imakado-singularize (str)
  "Singularize str"
  (interactive)
  (let ((result str))
    (loop for (plural-re sing-re) in (imakado-singular-rules) do
          (unless (not (string-match plural-re str))
            (setq result (replace-match sing-re nil nil str))
            (return result)))))


;;;; Sort
;; (sort
(defun* imakado-sort-by-average 
    (lon &key (key 'identity) (average nil))
  (let* ((average (or average
                      (/ (loop for n in lon
                               sum (funcall key n))
                         (length lon))))
         (lon-copied (copy-sequence lon)))
    (sort lon-copied 
          (lambda (a b)
            (let* ((a (funcall key a))
                   (b (funcall key b))
                   (x (abs (- a average)))
                   (y (abs (- b average))))
              (if (= x y)
                  (< a b)
                (< x y))))
          )))

;;;; Misc
(defun* imakado-show-eol (los &key (temp-buffer-name "*imakado-temp*"))
  (imakado-aand (get-buffer-create temp-buffer-name)
        (with-current-buffer it
          (erase-buffer)
          (imakado-insert-each-line los)
          (current-buffer))
        (switch-to-buffer it)))


;;;; Tests
;; need el-expectations.el(written by rubikitch) to run.
;; http://www.emacswiki.org/cgi-bin/wiki/download/el-expectations.el
(dont-compile
  (when (fboundp 'expectations)
    (expectations
      (desc "imakado-awhen")
      (expect "ya"
        (imakado-awhen (or nil "ya")
          it))
      (desc "imakado-awhile")
      (expect '(do you rock me?)
        (let ((l '(do you rock me?))
              (ret nil))
          (imakado-awhile (pop l)
            (push it ret))
          (nreverse ret)))
      (desc "imakado-aand")
      (expect 3
        (imakado-aand (1+ 0)
              (1+ it)
              (1+ it)))
      (desc "imakado-acond")
      (expect "cla1"
        (let ((ret nil))
          (imakado-acond
            (ret (push "ret is non-nil" ret))
            ((progn "cla1") (push it ret))
            (t (push "t" ret)))
          (car ret)))
      (desc "imakado-alambda")
      (expect 120
        (let ((factor (imakado-alambda (lst)
                        (cond
                         ((null lst) 1)
                         (t (* (car lst) (caller (cdr lst))))))))
          (funcall factor '(1 2 3 4 5))))

      (desc "imakado-with-struct")
      (expect 'st-a
        (defstruct (imakado-test-struct
                    (:constructor imakado-make-test-struct (a b)))
          a b)
        (let ((st (imakado-make-test-struct 'st-a 'st-b)))
          (imakado-with-struct (imakado-test-struct- a b) st
            a)))
      (desc "imakado-with-struct setf")
      (expect 'changed
        (defstruct (imakado-test-struct
                    (:constructor imakado-make-test-struct (a b)))
          a b)
        (let ((st (imakado-make-test-struct 'st-a 'st-b)))
          (imakado-with-struct (imakado-test-struct- a b) st
            (setf a 'changed))
          (imakado-with-struct (imakado-test-struct- a) st
            a)))

      (desc "imakado-define-with-all-slots-struct")
      (expect '(st-a st-b)
        (progn
          (defstruct (imakado-test-struct
                      (:constructor imakado-make-test-struct (a b)))
            a b)
          (imakado-define-with-all-slots-struct imakado-with-all-slots-test-struct imakado-test-struct-)
          (let ((st (imakado-make-test-struct 'st-a 'st-b)))
            (imakado-with-all-slots-test-struct st
              (list a b)))))
      (desc "imakado-define-with-all-slots-struct setf")
      (expect '(aa bb)
        (progn
          (defstruct (imakado-test-struct
                      (:constructor imakado-make-test-struct (a b)))
            a b)
          (imakado-define-with-all-slots-struct imakado-with-all-slots-test-struct imakado-test-struct-)
          (let ((st (imakado-make-test-struct 'st-a 'st-b)))
            (imakado-with-all-slots-test-struct st
              (setq a 'aa
                    b 'bb)
              (list a b)))))

      (desc "imakado-with-lexical-bindings")
      (expect '(var-a var-b changed)
        (let ((funcs (let ((a 'var-a)
                           (b 'var-b)
                           (c 'var-c))
                       (imakado-with-lexical-bindings (a b)
                         (list (lambda () a)
                               (lambda () b)
                               (lambda () c))))))
          (destructuring-bind (a b c) '(changed changed changed)
            (mapcar 'funcall funcs))))

      (desc "imakado-define-with-struct-macro")
      (expect 'st-a
        (defstruct (imakado-test-struct
                    (:constructor imakado-make-test-struct (a b)))
          a b)
        (imakado-define-with-struct-macro imakado-with-test-struct imakado-test-struct-)
        (let ((st (imakado-make-test-struct 'st-a 'st-b)))
          (imakado-with-test-struct (a) st
            a)))

      (desc "imakado-case-regexp-aux")
      (expect '(((imakado-=~ "aa" expr) (imakado-with-anaphoric-match-utilities expr "match aa")) ((imakado-=~ "bb" expr) (imakado-with-anaphoric-match-utilities expr "match bb")))
        (imakado-case-regexp-aux 'expr '(("aa" "match aa") ("bb" "match bb"))))

      (expect '((t nil))
        (imakado-case-regexp-aux 'expr '( (t) )))

      (desc "imakado-case-regexp")
      (expect "match huga"
        (imakado-case-regexp (concat "hu" "ga")
          ("^huga" (progn (message "%s" "match!!")
                          "match huga"))
          (t "otherwise")))
      (expect nil
        (imakado-case-regexp (concat "hu" "ga")
          ("huga" nil)
          (t "otherwise")))
      (expect nil
        (imakado-case-regexp (concat "hu" "ga")
          ("never match"
           (progn (message "%s" "match!!")
                  "match"))
          (t nil)))
      (expect nil
        (imakado-case-regexp (concat "hu" "ga")
          ("never match" (progn (message "%s" "match!!")
                                "match"))
          (t )))
      (expect nil
        (imakado-case-regexp (concat "hu" "ga")
          ("never match" (progn (message "%s" "match!!")
                                "match"))
          (otherwise nil)))
      (expect "huga"
        (imakado-case-regexp (concat "hu" "ga")
          ("^huga" $0)
          (t "otherwise")))

      (expect  "match huga"
        (imakado-case-regexp (concat "hu" "ga")
          ((rx "huga") "match huga")
          (t "otherwise")))

      (desc "imakado-define-define-keymap")
      (expect 'imakado-test-command
        (let ((imakado-test-keymap (make-sparse-keymap)))
          (flet ((imakado-test-command (&rest args) (interactive) (apply 'identity args)))
            (imakado-define-define-keymap imakado-define-key-test-keymap imakado-test-keymap)
            (imakado-define-key-test-keymap "<return>" 'imakado-test-command)
            (lookup-key imakado-test-keymap (kbd "<return>")))))

      (expect 'imakado-test-command
        (let ((imakado-test-keymap (make-sparse-keymap)))
          (flet ((imakado-test-command (&rest args) (interactive) (apply 'identity args)))
            (imakado-define-define-keymap imakado-define-key-test-keymap imakado-test-keymap)
            (imakado-define-key-test-keymap [f1] 'imakado-test-command)
            (lookup-key imakado-test-keymap [f1]))))

      (expect 'imakado-test-command
        (let ((imakado-test-keymap (make-sparse-keymap)))
          (flet ((imakado-test-command (&rest args) (interactive) (apply 'identity args)))
            (imakado-define-define-keymap imakado-define-key-test-keymap imakado-test-keymap)
            (imakado-define-key-test-keymap (progn nil "C-c a") (progn "ignore" 'imakado-test-command))
            (lookup-key imakado-test-keymap (progn nil "C-c a")))))

      (expect 'imakado-test-command
        (let ((imakado-test-keymap (make-sparse-keymap)))
          (flet ((imakado-test-command (&rest args) (interactive) (apply 'identity args)))
            (imakado-define-define-keymap imakado-define-key-test-keymap imakado-test-keymap :doc "define imakado-test-keymap key")
            (imakado-define-key-test-keymap "<return>" 'imakado-test-command)
            (lookup-key imakado-test-keymap (kbd "<return>")))))

      (desc "imakado-dolist-with-progress-reporter")
      (expect (regexp "[[:digit:]][[:digit:]]%")
        (flet ((message (&rest args) (print (apply 'format args))))
          (with-output-to-string
            (imakado-dolist-with-progress-reporter (v (number-sequence 0 5)) "msg: " nil 0.1
              (sit-for 0.1)))))
      (expect '(1 2 3)
        (let (ret)
          (imakado-dolist-with-progress-reporter (n '(1 2 3) (nreverse ret)) "" nil nil
            (push n ret))))
      (desc "imakado-cond-let")
      (expect "cd(d c nil)"
        (with-output-to-string
          (imakado-cond-let (((= 1 2) (x (princ 'a)) (y (princ 'b)))
                     ((= 1 1) (y (princ 'c)) (x (princ 'd)))
                     (t       (x (princ 'e)) (z (princ 'f))))
            (princ (list x y z)))))
      (expect 'aa
        (imakado-cond-let ((t (a 'aa)))
          a))

      (desc "imakado-when-let")
      (expect 'foo
        (imakado-when-let (var 'foo)
          var))
      (expect nil
        (imakado-when-let (var (progn nil))
          (progn 'foo)))

      (desc "imakado-in")
      (expect '(t nil)
        (let (var)
          (flet ((op () 'two))
            (list (imakado-in (op) 'one 'two (prog1 'three (setq var 'called)))
                  var))))

      (desc "imakado-group")
      (expect '((1 2) (3 4))
        (imakado-group '(1 2 3 4) 2))
      (expect '((1 2) (3))
        (imakado-group '(1 2 3) 2))
      (expect (error)
        (imakado-group '(1 2 3) 2 :error-check t))
      (expect '((1))
        (imakado-group '(1) 2))
      (expect (error)
        (imakado-group '(1) 2 :error-check t))


      (desc "imakado-define-macro-alias")
      (expect 'alias
        (defmacro imakado-test-macro (arg)
          (imakado-with-gensyms (a)
            `(let ((,a ,arg))
               ,a)))
        (imakado-define-macro-alias imakado-test-macro-alias imakado-test-macro)
        (imakado-test-macro-alias 'alias))

      (desc "imakado-in")
      (expect '(t nil)
        (let (called)
          (let ((op 'otherwise))
            (list
             (imakado-in op 't 'otherwise (prog1 'ya (setq called t)))
             called))))
      (desc "imakado-inq")
      (expect t
        (let ((op 'otherwise))
          (imakado-inq op t otherwise ya)))

      (desc "imakado-xcase")
      (expect '(first t nil)
        (let (called called2)
          (list
           (imakado-xcase 'key
             (((prog1 'key (setq called t))) 'first)
             ((prog1 'ya (setq called2 t)) 'second))
           called called2)))

      (desc "imakado-in")
      (expect t
        (imakado-in (prog1 'apple "apple") "banana" "apple" "pine" 'apple))
      (expect nil
        (imakado-in (progn 'ignore "apple") "banana" "apple" "pine"))
      (desc "imakado-in=")
      (expect t
        (imakado-in= (progn 'ignore "apple") "banana" "apple" "pine"))
      (expect t
        (imakado-in= (progn 'ignore 'apple) "banana" "apple" "pine" (prog1 'apple 'ignore)))

      (desc "imakado-join+")
      (expect "oh my god"
        (imakado-join+ (list "oh" "my" "god") (prog1 " " 'ignore)))


      (desc "imakado-flatten")
      (expect '(a b c d e)
        (imakado-flatten '(a (b (c d)) e)))

      (desc "imakado-subseq")
      (expect '(3 4 5 6 7)
        (imakado-subseq (number-sequence 0 10) 3 8))

      (desc "imakado-remove-if")
      (expect '(0 2 4 6 8 10)
        (imakado-remove-if 'oddp (number-sequence 0 10)))
      (desc "imakado-remove-if-not")
      (expect '(1 3 5 7 9)
        (imakado-remove-if-not 'oddp (number-sequence 0 10)))

      (desc "imakado-fn")
      (expect '(3 2 1)
        (sort (list 1 2 3)
              (imakado-fn (_ b) (> _ b))))
      (expect '(3 2 1)
        (sort (list 1 2 3)
              (imakado-fn (> _1 _2))))
      (expect '(0 1 2 3)
        (imakado-remove-if (imakado-fn (_) (> _ 3)) (number-sequence 0 10)))
      (expect '(0 1 2 3)
        (imakado-remove-if (imakado-fn (> _ 3)) (number-sequence 0 10)))
      (expect '(1 3)
        (apply (imakado-fn (list _1 _3)) '(1 2 3)))

      (expect t
        (funcall (imakado-fn (= 1 (length _)))
                 (list 'a)))
      (desc "imakado-fn error")
      (expect "cant use \"_\" and \"(_1 _2 ...)\" at the same time!!"
        (condition-case err
            (imakado-fn (list _ _1 _2))
          (error "%s" (error-message-string err))))

      (desc "imakado-fn cant use both _<n> and _")
      (expect (error)
        (sort (list 1 2 3)
              (imakado-fn (< _1 _))))

      (desc "imakado-fn _0 is bound to arglist")
      (expect '(a b (a b))
        (apply (imakado-fn (list _1
                         _2
                         _0))
               '(a b)))

      (desc "imakado-cars")
      (expect '("a" "c")
        (imakado-cars '( ("a" . "b") ("c" . "d"))))
      (desc "imakado-cdrs")
      (expect '("b" "d")
        (imakado-cdrs '( ("a" . "b") ("c" . "d"))))

      (desc "imakado-match-with-temp-buffer")
      (expect '("string" "string" "string")
        (imakado-match-with-temp-buffer ((rx "string") "string string string" )
          $m))
      (expect "string string string"
        (imakado-match-with-temp-buffer ((rx "ing") "string string string" (buffer-string))
          $m))
      (expect "  "
        (imakado-match-with-temp-buffer ((rx "string") "string string string" (buffer-string))
          ($sub "")))

      (desc "imakado-remif")
      (expect '("a" "b")
        (imakado-remif (imakado-fn (imakado-=~ (rx bol ".") _))
               (list "a" "b" ".hoge")))
      (expect '("a" "b")
        (imakado-remif (imakado-fn (imakado-=~ (rx bol ".") _))
               (list "a" "b" ".hoge")
               :key 'identity))
      (expect '("a" "b")
        (imakado-remif (imakado-fn (imakado-=~ (rx bol ".") _))
               (list "a" "b" ".hoge")
               :key (imakado-fn (a) a)))

      (desc "imakado-!remif")
      (expect '((1 . "huga"))
        (imakado-!remif (imakado-fn (imakado-=~ "huga" _))
                '( (1 . "huga")
                   (2 . "hoge")
                   (3 . "piyo") )
                :key 'cdr))
      (expect '(".hoge")
        (imakado-!remif (imakado-fn (imakado-=~ (rx bol ".") _))
                (list "a" "b" ".hoge")))
      (expect '(".hoge")
        (imakado-!remif (imakado-fn (imakado-=~ (rx bol ".") _))
                (list "a" "b" ".hoge")
                :key 'identity))
      (expect '(".hoge")
        (imakado-!remif (imakado-fn (imakado-=~ (rx bol ".") _))
                (list "a" "b" ".hoge")
                :key (imakado-fn (a) a)))

      (desc "cadr")
      (expect '("2" "4")
        (imakado-cadrs '( ("1" "2") ("3"  "4"))))

      (desc "imakado-with-point-buffer")
      (expect '("a" "b")
        (imakado-with-point-buffer "aaa`!!'bbb"
          (list
           (char-to-string (preceding-char))
           (char-to-string (following-char)))))

      (desc "imakado-assoc-cdrs")
      (expect '("kval" "vval")
        (imakado-assoc-cdrs '("k" "v")
                    '(("k" . "kval")
                      ("v" . "vval"))))
      (expect '("kval" "vval")
        (imakado-assoc-cdrs '( k v )
                    '((k . "kval")
                      (v . "vval"))))
      (expect '("kval" "vval" "def")
        (imakado-assoc-cdrs '( k v default)
                    '((k . "kval")
                      default
                      (v . "vval"))
                    'eq
                    "def"))
      (desc "imakado-nths")
      (expect '(2 2 2)
        (imakado-nths 2
              (list (number-sequence 0 10)
                    (number-sequence 0 10)
                    (number-sequence 0 10))))
      )))

(provide 'imakado)
;;; imakado.el ends here
