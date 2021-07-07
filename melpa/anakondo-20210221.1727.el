;;; anakondo.el --- Adds clj-kondo based Clojure[Script] editing facilities  -*- lexical-binding: t; -*-

;; Copyright (C) 2020  Didier A.

;; Author: Didier A. <didibus@users.noreply.github.com>
;; URL: https://github.com/didibus/anakondo
;; Package-Version: 20210221.1727
;; Package-Commit: c48518560815c49d8d78fb9069906d17e883385e
;; Version: 0.2.1
;; Package-Requires: ((emacs "26.3"))
;; Keywords: clojure, clojurescript, cljc, clj-kondo, completion, languages, tools

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package makes use of clj-kondo's analysis data to provide code editing
;; facilities related to Clojure, ClojureScript and cljc source.

;; See accompanying README file for more info: https://github.com/didibus/anakondo/blob/master/README.org

;;;; Installation

;; See accompanying README file for install instructions: https://github.com/didibus/anakondo/blob/master/README.org#Installation

;;;; Usage

;; See accompanying README file for usage instructions: https://github.com/didibus/anakondo/blob/master/README.org#Usage

;;;; Credits

;; See accompanying README file for credits: https://github.com/didibus/anakondo/blob/master/README.org#Credits

;;; License:

;; MIT License, see accompanying LICENSE file: https://github.com/didibus/anakondo/blob/master/LICENSE

;;; Code:

;;;; Requirements

(require 'json)
(eval-when-compile (require 'subr-x))
(require 'dabbrev)
(require 'cl-lib)

;;;; Declares

(declare-function projectile-project-root "ext:projectile")
(declare-function project-root "ext:project" (project) t)
(declare-function project-roots "ext:project" (project) t)
(declare-function clojure-project-dir "ext:clojure-mode")

;;;; Customization

(defgroup anakondo nil
  "Clojure, ClojureScript and cljc minor mode powered by clj-kondo."
  :group 'clojure)

(defcustom anakondo-minor-mode-lighter " k"
  "Text to display in the mode line when anakondo minor mode is on."
  :type 'string
  :group 'anakondo)

;;;; Variables

(defvar anakondo--cache nil
  "Cache where per-project clj-kondo analysis maps are stored.")

(defvar-local anakondo--completion-candidates-cache nil
  "Store the last start position in we completed at car,
and the completion candidates for it at cdr for buffer.")

(defconst anakondo--clojure-default-imports
  #s(hash-table
     test equal
     data ("Compiler" "clojure.lang.Compiler"
           "AbstractMethodError" "java.lang.AbstractMethodError"
           "Appendable" "java.lang.Appendable"
           "ArithmeticException" "java.lang.ArithmeticException"
           "ArrayIndexOutOfBoundsException" "java.lang.ArrayIndexOutOfBoundsException"
           "ArrayStoreException" "java.lang.ArrayStoreException"
           "AssertionError" "java.lang.AssertionError"
           "Boolean" "java.lang.Boolean"
           "Byte" "java.lang.Byte"
           "CharSequence" "java.lang.CharSequence"
           "Character" "java.lang.Character"
           "Class" "java.lang.Class"
           "ClassCastException" "java.lang.ClassCastException"
           "ClassCircularityError" "java.lang.ClassCircularityError"
           "ClassFormatError" "java.lang.ClassFormatError"
           "ClassLoader" "java.lang.ClassLoader"
           "ClassNotFoundException" "java.lang.ClassNotFoundException"
           "CloneNotSupportedException" "java.lang.CloneNotSupportedException"
           "Cloneable" "java.lang.Cloneable"
           "Comparable" "java.lang.Comparable"
           "Deprecated" "java.lang.Deprecated"
           "Double" "java.lang.Double"
           "Enum" "java.lang.Enum"
           "EnumConstantNotPresentException" "java.lang.EnumConstantNotPresentException"
           "Error" "java.lang.Error"
           "Exception" "java.lang.Exception"
           "ExceptionInInitializerError" "java.lang.ExceptionInInitializerError"
           "Float" "java.lang.Float"
           "IllegalAccessError" "java.lang.IllegalAccessError"
           "IllegalAccessException" "java.lang.IllegalAccessException"
           "IllegalArgumentException" "java.lang.IllegalArgumentException"
           "IllegalMonitorStateException" "java.lang.IllegalMonitorStateException"
           "IllegalStateException" "java.lang.IllegalStateException"
           "IllegalThreadStateException" "java.lang.IllegalThreadStateException"
           "IncompatibleClassChangeError" "java.lang.IncompatibleClassChangeError"
           "IndexOutOfBoundsException" "java.lang.IndexOutOfBoundsException"
           "InheritableThreadLocal" "java.lang.InheritableThreadLocal"
           "InstantiationError" "java.lang.InstantiationError"
           "InstantiationException" "java.lang.InstantiationException"
           "Integer" "java.lang.Integer"
           "InternalError" "java.lang.InternalError"
           "InterruptedException" "java.lang.InterruptedException"
           "Iterable" "java.lang.Iterable"
           "LinkageError" "java.lang.LinkageError"
           "Long" "java.lang.Long"
           "Math" "java.lang.Math"
           "NegativeArraySizeException" "java.lang.NegativeArraySizeException"
           "NoClassDefFoundError" "java.lang.NoClassDefFoundError"
           "NoSuchFieldError" "java.lang.NoSuchFieldError"
           "NoSuchFieldException" "java.lang.NoSuchFieldException"
           "NoSuchMethodError" "java.lang.NoSuchMethodError"
           "NoSuchMethodException" "java.lang.NoSuchMethodException"
           "NullPointerException" "java.lang.NullPointerException"
           "Number" "java.lang.Number"
           "NumberFormatException" "java.lang.NumberFormatException"
           "Object" "java.lang.Object"
           "OutOfMemoryError" "java.lang.OutOfMemoryError"
           "Override" "java.lang.Override"
           "Package" "java.lang.Package"
           "Process" "java.lang.Process"
           "ProcessBuilder" "java.lang.ProcessBuilder"
           "Readable" "java.lang.Readable"
           "Runnable" "java.lang.Runnable"
           "Runtime" "java.lang.Runtime"
           "RuntimeException" "java.lang.RuntimeException"
           "RuntimePermission" "java.lang.RuntimePermission"
           "SecurityException" "java.lang.SecurityException"
           "SecurityManager" "java.lang.SecurityManager"
           "Short" "java.lang.Short"
           "StackOverflowError" "java.lang.StackOverflowError"
           "StackTraceElement" "java.lang.StackTraceElement"
           "StrictMath" "java.lang.StrictMath"
           "String" "java.lang.String"
           "StringBuffer" "java.lang.StringBuffer"
           "StringBuilder" "java.lang.StringBuilder"
           "StringIndexOutOfBoundsException" "java.lang.StringIndexOutOfBoundsException"
           "SuppressWarnings" "java.lang.SuppressWarnings"
           "System" "java.lang.System"
           "Thread" "java.lang.Thread"
           "Thread$State" "java.lang.Thread$State"
           "Thread$UncaughtExceptionHandler" "java.lang.Thread$UncaughtExceptionHandler"
           "ThreadDeath" "java.lang.ThreadDeath"
           "ThreadGroup" "java.lang.ThreadGroup"
           "ThreadLocal" "java.lang.ThreadLocal"
           "Throwable" "java.lang.Throwable"
           "TypeNotPresentException" "java.lang.TypeNotPresentException"
           "UnknownError" "java.lang.UnknownError"
           "UnsatisfiedLinkError" "java.lang.UnsatisfiedLinkError"
           "UnsupportedClassVersionError" "java.lang.UnsupportedClassVersionError"
           "UnsupportedOperationException" "java.lang.UnsupportedOperationException"
           "VerifyError" "java.lang.VerifyError"
           "VirtualMachineError" "java.lang.VirtualMachineError"
           "Void" "java.lang.Void"
           "BigDecimal" "java.math.BigDecimal"
           "BigInteger" "java.math.BigInteger"
           "concurrent.Callable" "java.util.concurrent.Callable")))

(defconst anakondo--clojure-default-imports-reverse
  (let* ((clojure-default-imports-reverse (make-hash-table :test 'equal)))
    (maphash
     (lambda (k v)
       (puthash v k clojure-default-imports-reverse))
     anakondo--clojure-default-imports)
    clojure-default-imports-reverse))

;;;;; Keymaps

(defvar anakondo-minor-mode-map
  ;; This makes it easy and much less verbose to define keys
  (let ((map (make-sparse-keymap "Anakondo minor mode map"))
        (maps (list
               ;; Mappings go here, e.g.:
               ;; "RET" #'package-name-RET-command
               ;; [remap search-forward] #'package-name-search-forward
               )))
    (cl-loop for (key fn) on maps by #'cddr
             do (progn
                  (when (stringp key)
                    (setq key (kbd key)))
                  (define-key map key fn)))
    map)
  "Keymap used to specify key-bindings for anakondo minor mode.")

;;;; Macros

(defmacro anakondo--with-project-root (&rest body)
  "Invoke BODY with `root' bound to the project root.

We try to find the project root by:
1. Trying to query `clojure-mode' for it.
2. Trying to query `projectile' for it.
3. Trying to query `project' for it.
4. Defaulting to the `default-directory' of the buffer otherwise.

Anaphoric macro, binds `root' implicitly."
  `(let* ((root (or (and (featurep 'clojure-mode) (clojure-project-dir))
                    (and (featurep 'projectile) (projectile-project-root))
                    (anakondo--project-get-project-root)
                    default-directory)))
     ,@body))

;;;; Functions

(defun anakondo--project-get-project-root ()
  "Wrapper around `project.el' for getting project root."
  (when-let ((project (and (featurep 'project)
                           (project-current))))
    ;; `project-root' function can be missing, as it was added
    ;; recently, and `project-roots' function was deprecated.  The
    ;; main difference is that `project-root' returns single project
    ;; root, while `project-roots' always returns a list but we only
    ;; interested in first candidate.  More info can be found in
    ;; commit `5044c190' at Emacs source code repository.
    (if (fboundp #'project-root)
        (project-root project)
      (car (with-no-warnings
             (project-roots project))))))

(defun anakondo--get-project-cache (root)
  "Return clj-kondo analysis cache for given project ROOT."
  (gethash root anakondo--cache))

(defun anakondo--set-project-cache (root root-cache)
  "Set given clj-kondo analysis ROOT-CACHE for given project ROOT."
  (puthash root root-cache anakondo--cache))

(defun anakondo--get-project-var-def-cache ()
  "Return cached var-definitions for current project."
  (anakondo--with-project-root
   (gethash :var-def-cache (anakondo--get-project-cache root))))

(defun anakondo--get-project-ns-def-cache ()
  "Return cached ns-definitions for current project."
  (anakondo--with-project-root
   (gethash :ns-def-cache (anakondo--get-project-cache root))))

(defun anakondo--get-project-ns-usage-cache ()
  "Return cached ns-usages for current project."
  (anakondo--with-project-root
   (gethash :ns-usage-cache (anakondo--get-project-cache root))))

(defun anakondo--get-project-java-classes-cache ()
  "Return cached java-classes for current project."
  (anakondo--with-project-root
   (gethash :java-classes-cache (anakondo--get-project-cache root))))

(defun anakondo--completion-symbol-bounds ()
  "Return bounds of symbol at point which needs completion.

Tries to infer start and end of Clojure symbol at point.

It is smart enough to skip number literals, strings, comments,
keywords, meta, tagged literals, Java fields and methods and
character literals.

It is smart enough to ignore quote, syntax quote, unquote,
unquote-splice and @ deref."
  (let* ((pt (point))
         (syntax (syntax-ppss))
         (skip-regex "a-zA-Z0-9*+!_'?<>=/.:^#\\\\-"))
    ;; Don't auto-complete inside strings or comments
    (unless (or (nth 3 syntax)          ;skip strings
                (nth 4 syntax))         ;skip comments
      (save-excursion
        (skip-chars-backward skip-regex)
        (let ((ch (char-after)))
          (unless (or (and ch (>= ch ?0) (<= ch ?9)) ;skip numbers
                      (and ch (= ch ?:)) ;skip keywords
                      (and ch (= ch ?\\)) ;skip chars
                      (and ch (= ch ?^)) ;skip meta
                      (and ch (= ch ?#)) ;skip tagged literal
                      (and ch (= ch ?.))) ;skip . at start as reserved by Clojure
            (when (and ch (= ch ?'))
              (forward-char))
            (setq pt (point))
            (skip-chars-forward skip-regex)
            (cons pt (point))))))))

(defun anakondo--get-buffer-lang ()
  "Return the current buffer detected Clojure language.

Used when calling clj-kondo `--lang' argument.

Return nil if Clojure not detected."
  (if buffer-file-name
      (file-name-extension buffer-file-name)
    (pcase major-mode
      ('clojure-mode "clj")
      ('clojurec-mode "cljc")
      ('clojurescript-mode "cljs"))))

(defun anakondo--clj-kondo-analyse-sync (path default-lang)
  "Return clj-kondo's analysis data as a hash-map of lists and keywords.

Is synchronous, and will block Emacs until done.

PATH is the value passed to clj-kondo's `--lint' option.  It can be a path to a
file, directory or classpath.  In the case of a directory or classpath,
only .clj, .cljs and .cljc will be processed.  Use `-' as path for having it
analyze current buffer.

DEFAULT-LANG is the value passed to clj-kondo's `--lang' option.  If lang cannot
be derived from the file extension this option will be used."
  (let* ((buffer "*anakondo*")
         (analysis-key :analysis)
         (kondo-command (concat "clj-kondo --lint '" path
                                "' --config '{:output {:analysis true :format :json}}'"))
         (kondo-command (if default-lang
                            (concat kondo-command " --lang '" default-lang "'")
                          kondo-command)))
    (unwind-protect
        (let* ((_ (call-shell-region nil nil
                                     kondo-command
                                     nil buffer))
               (json-object-type 'hash-table)
               (json-array-type 'list)
               (json-key-type 'keyword)
               (kondo-result-hashmap (with-current-buffer buffer
                                       (goto-char (point-min))
                                       (json-read))))
          (gethash analysis-key kondo-result-hashmap))
      (when (get-buffer buffer)
        (kill-buffer buffer)))))

(defun anakondo--get-project-path ()
  "Return the path to `--lint' for clj-kondo in current project.

It uses Clojure's `tools.deps' to get the project's classpath."
  ;; TODO: add support for lein, boot, and default to directory otherwise
  (shell-command-to-string "clojure -Spath"))

(defun anakondo--string->keyword (str)
  "Convert STR to an interned keyword symbol."
  (when str
    (intern (concat ":" str))))

(defun anakondo--upsert-var-def-cache (var-def-cache-table var-defs &optional invalidation-ns)
  "Update or insert var-definitions into cache.

Update or insert into VAR-DEF-CACHE-TABLE the clj-kondo var-definitions from
VAR-DEFS.

INVALIDATION-NS : optional, can be a keyword of the namespace to invalidate
                  before updating.  This means it'll replace the cached
                  var-definitions for that namespace instead of merging it in.
                  This is useful when we want to remove var-definitions
                  no longer present in the source code from the cache."
  (when invalidation-ns
    (remhash invalidation-ns var-def-cache-table))
  (seq-reduce
   (lambda (hash-table var-def)
     (let* ((key (anakondo--string->keyword (gethash :ns var-def)))
            (curr-val (gethash key hash-table))
            (var-def-key (anakondo--string->keyword (gethash :name var-def))))
       (if curr-val
           (progn
             (puthash var-def-key var-def curr-val)
             (puthash key curr-val hash-table))
         (let* ((new-curr-val (make-hash-table)))
           (puthash var-def-key var-def new-curr-val)
           (puthash key new-curr-val hash-table)))
       hash-table))
   var-defs
   var-def-cache-table))

(defun anakondo--upsert-ns-def-cache (ns-def-cache-table ns-defs)
  "Update or insert ns-definitions into cache.

Update or insert into NS-DEF-CACHE-TABLE the clj-kondo ns-definitions from
NS-DEFS."
  (seq-reduce
   (lambda (hash-table ns-def)
     (let* ((key (anakondo--string->keyword (gethash :name ns-def))))
       (puthash key ns-def hash-table)
       hash-table))
   ns-defs
   ns-def-cache-table))

(defun anakondo--upsert-ns-usage-cache (ns-usage-cache-table ns-usages &optional invalidation-ns)
  "Update or insert ns-usages into cache.

Update or insert into NS-USAGE-CACHE-TABLE the clj-kondo
ns-usages from NS-USAGES.

INVALIDATION-NS : optional, can be a keyword of the namespace to
                  invalidate before updating.  This means it'll
                  replace the cached ns-usages for that namespace
                  instead of merging it in.  This is useful when
                  we want to remove ns-usages no longer present
                  in the source code from the cache."
  (when invalidation-ns
    (remhash invalidation-ns ns-usage-cache-table))
  (seq-reduce
   (lambda (hash-table ns-usage)
     (let* ((key (anakondo--string->keyword (gethash :from ns-usage)))
            (curr-val (gethash key hash-table))
            (ns-usage-key (anakondo--string->keyword (gethash :to ns-usage))))
       (if curr-val
           (progn
             (puthash ns-usage-key ns-usage curr-val)
             (puthash key curr-val hash-table))
         (let* ((new-curr-val (make-hash-table)))
           (puthash ns-usage-key ns-usage new-curr-val)
           (puthash key new-curr-val hash-table)))
       hash-table))
   ns-usages
   ns-usage-cache-table))

(defun anakondo--clj-kondo-project-analyse-sync (var-def-cache-table ns-def-cache-table ns-usage-cache-table)
  "Analyze project synchronously using clj-kondo.

Analyze synchronously the current project and upsert the analysis result
into the given VAR-DEF-CACHE-TABLE, NS-DEF-CACHE-TABLE and NS-USAGE-CACHE-TABLE."
  (anakondo--with-project-root
   (let* ((kondo-analyses (anakondo--clj-kondo-analyse-sync (anakondo--get-project-path) (anakondo--get-buffer-lang)))
          (var-defs (gethash :var-definitions kondo-analyses))
          (ns-defs (gethash :namespace-definitions kondo-analyses))
          (ns-usages (gethash :namespace-usages kondo-analyses)))
     (anakondo--upsert-var-def-cache var-def-cache-table var-defs)
     (anakondo--upsert-ns-def-cache ns-def-cache-table ns-defs)
     (anakondo--upsert-ns-usage-cache ns-usage-cache-table ns-usages)
     root)))

(defun anakondo--clj-kondo-buffer-analyse-sync (var-def-cache-table ns-def-cache-table ns-usage-cache-table)
  "Analyze buffer synchronously using clj-kondo.

Analyze synchronously the current buffer and upsert the analysis result into
the given VAR-DEF-CACHE-TABLE, NS-DEF-CACHE-TABLE and NS-USAGE-CACHE-TABLE.

It is synchronous and will block Emacs, but should be fast enough we don't
bother messaging the user.  Also, this is called by `completion-at-point', which
for command `company-mode', means it is called on every keystroke that qualifies
for completion, and messaging was excessive in that case."
  (let* ((kondo-analyses (anakondo--clj-kondo-analyse-sync "-" (anakondo--get-buffer-lang)))
         (var-defs (gethash :var-definitions kondo-analyses))
         (ns-defs (gethash :namespace-definitions kondo-analyses))
         (ns-usages (gethash :namespace-usages kondo-analyses))
         (curr-ns-def (car ns-defs))
         ;; Default to user namespace when there is no namespace defined in the buffer
         (curr-ns (if curr-ns-def
                      (anakondo--string->keyword (gethash :name curr-ns-def))
                    :user)))
    (anakondo--upsert-var-def-cache var-def-cache-table var-defs curr-ns)
    (anakondo--upsert-ns-def-cache ns-def-cache-table ns-defs)
    (anakondo--upsert-ns-usage-cache ns-usage-cache-table ns-usages curr-ns)
    curr-ns))

(defun anakondo--jar-analize-sync (classpath-list)
  "Return the list of Java classes contained in the Jars from CLASSPATH-LIST."
  (let* ((jars (seq-filter
                (lambda (path)
                  (string-match-p ".*\.jar$" path))
                classpath-list)))
    (let* (jars-tf)
      (dolist (jar jars jars-tf)
        (setq jars-tf
              (append
               jars-tf
               (with-temp-buffer
                 (shell-command (concat "jar tf '" jar "'") t)
                 (goto-char (point-min))
                 (let (classes)
                   (while (not (eobp))
                     (let ((line (buffer-substring (point)
                                                   (progn (forward-line 1) (point)))))
                       (when (string-match "\\(?1:^[^$]+\/[^$]+\\)\.class$" line)
                         (let* ((linet (match-string 1 line)))
                           (unless (string-match-p "__init" linet)
                             (let* ((class (replace-regexp-in-string "/" "." linet)))
                               (setq classes (cons class classes))))))))
                   classes))))))))

(defun anakondo--make-class-map (class-name methods-and-fields)
  "Make a java class definition hash table map.

{:name CLASS-NAME
 :methods-and-fields METHODS-AND-FIELDS}"
  (let* ((class-map (make-hash-table)))
    (puthash :name class-name class-map)
    (puthash :methods-and-fields methods-and-fields class-map)
    class-map))

(defun anakondo--java-analyze-class-map (classpath class)
  "Return the class-map containing Java methods and fields for given CLASS.

CLASSPATH : The classpath where CLASS can be found in."
  (let* (methods-and-fields)
    (with-temp-buffer
      (shell-command (concat "javap -cp '" classpath "' -public '" class "'") t)
      (goto-char (point-min))
      (while (not (eobp))
        (let* ((line (buffer-substring (point)
                                       (progn (forward-line 1) (point))))
               (method-field-map (make-hash-table)))
          (when (string-match ".*static \\(final \\)?\\(?1:[^\s]+\\) \\(?2:[^\s]+?\\)\\(?3:\(.*\\)?;$" line)
            (let* ((return-type (match-string 1 line))
                   (name (match-string 2 line))
                   (signature (match-string 3 line))
                   (method? (when signature t)))
              (puthash :return-type return-type method-field-map)
              (puthash :name name method-field-map)
              (puthash :signature signature method-field-map)
              (puthash :method? method? method-field-map)
              (setq methods-and-fields (cons method-field-map methods-and-fields)))))))
    (anakondo--make-class-map class methods-and-fields)))

(defun anakondo--get-java-boot-classpath-list ()
  "Return the Java boot classpath as a list."
  (let* ((boot-classpath (with-temp-buffer
                           (shell-command "java -XshowSettings:properties -version" t)
                           (goto-char (point-min))
                           (search-forward "sun.boot.class.path =" nil t)
                           (kill-line 0)
                           (let* (boot-classpath)
                             (catch 'done
                               (while (not (eobp))
                                 (let* ((line (buffer-substring-no-properties (line-beginning-position) (line-end-position))))
                                   (when (string-match-p "^.*=.*$" line)
                                     (throw 'done nil))
                                   (setq boot-classpath
                                         (cons
                                          (string-trim
                                           line)
                                          boot-classpath))
                                   (forward-line 1))))
                             boot-classpath))))
    boot-classpath))

(defun anakondo--get-java-analysis-classpath (as)
  "Return classpath that contain both project classpath and boot classpath.

AS : can be 'list if you want classpath returned as a list
     or 'cp if you want classpath returned as a java style
     colon separated string classpath."
  (let* ((project-path (anakondo--get-project-path))
         (project-classpaths-list (split-string project-path ":" nil "[[:blank:]\n]*"))
         (java-boot-classpath-list (anakondo--get-java-boot-classpath-list))
         (analysis-classpath-list (cl-concatenate 'list project-classpaths-list java-boot-classpath-list)))
    (cl-case as
      ('list analysis-classpath-list)
      ('cp (string-join analysis-classpath-list ":")))))

(defun anakondo--java-project-analyse-sync (java-classes-cache)
  "Analyze project for all Java classes and their methods and fields.

Updates JAVA-CLASSES-CACHE with the result."
  (let* ((analysis-classpath-list (anakondo--get-java-analysis-classpath 'list))
         (classes (anakondo--jar-analize-sync analysis-classpath-list)))
    (dolist (class classes nil)
      (puthash (anakondo--string->keyword class)
               ;; We will delay the loading of the methods-and-fields
               ;; until necessary for those whose methods-and-fields
               ;; are marked as 'lazy.
               (anakondo--make-class-map class 'lazy)
               java-classes-cache))))

(defun anakondo--safe-hash-table-values (hash-table)
  "Return hash tables values or nil.

Like `hash-table-values', but return nil instead of signaling an error when
HASH-TABLE is nil."
  (when hash-table
    (hash-table-values hash-table)))

(defun anakondo--get-clj-kondo-completion-candidates ()
  "Return completion candidates at point for current buffer.

Return a candidate list compatible with `completion-at-point' for current
symbol at point.

How it works:
1. It gets the current namespace by analyzing the current buffer with clj-kondo.
2. As it analyses the current buffer with clj-kondo, it will also take this
   opportunity to upsert the result back into the analysis cache of the current
   project.
3. It will then grab from the current project's caches the vars from the current
   namespace and the vars from all namespaces it requires, as well as the list
   of all available namespaces and join them all into out candidates list.
4. It'll properly prefix the alias or the namespace qualifier for Vars from the
   required namespaces.  If there is an alias, it uses the alias, else the
   namespace qualifier.
5. Does not support refer yet.
6. Does not support keywords yet.
7. Does not support locals yet."
  (let* ((var-def-cache (anakondo--get-project-var-def-cache))
         (ns-def-cache (anakondo--get-project-ns-def-cache))
         (ns-usage-cache (anakondo--get-project-ns-usage-cache))
         ;; Fix clj-kondo issue: https://github.com/borkdude/clj-kondo/issues/866
         ;; We need to send to clj-kondo the buffer with prefix that doesn't end in forward slash
         (prefix-end-in-forward-slash? (when (and (char-before) (= (char-before) ?/))
                                         (delete-char -1)
                                         t))
         (curr-ns (anakondo--clj-kondo-buffer-analyse-sync var-def-cache ns-def-cache ns-usage-cache)))
    ;; Restore deleted forward-slash
    (when prefix-end-in-forward-slash?
      (insert ?/))
    (append
     (mapcar
      (lambda (var-def)
        (gethash :name var-def))
      (append
       (anakondo--safe-hash-table-values (gethash curr-ns var-def-cache))
       (anakondo--safe-hash-table-values (gethash :clojure.core var-def-cache))))
     (mapcar
      (lambda (ns-def)
        (gethash :name ns-def))
      (anakondo--safe-hash-table-values ns-def-cache))
     (seq-mapcat
      (lambda (ns-usage)
        (let* ((ns-name (gethash :to ns-usage))
               (alias (gethash :alias ns-usage))
               (ns-qualifier (or alias ns-name))
               (ns-key (anakondo--string->keyword ns-name))
               (ns-var-names (mapcar
                              (lambda (var-def)
                                (gethash :name var-def))
                              (anakondo--safe-hash-table-values (gethash ns-key var-def-cache)))))
          (mapcar
           (lambda (var-name)
             (concat ns-qualifier "/" var-name))
           ns-var-names)))
      (anakondo--safe-hash-table-values (gethash curr-ns ns-usage-cache))))))

(defun anakondo--get-local-completion-candidates (prefix prefix-start)
  "Return a local candidate list for current symbol at point.

Does not use clj-kondo, will perform a heuristic search for locals on
best effort.

Heuristic:
  Uses dabbrev to find all symbols between the top level form up to
  prefix-start.

PREFIX : string for which to find all candidates that can complete it.
PREFIX-START : start point of PREFIX, candidates are found up to
               PREFIX-START."
  (let* ((all-expansions nil)
         expansion
         (syntax (syntax-ppss))
         (top-level-form-start (car (nth 9 syntax))))
    (when top-level-form-start
      (save-excursion
        (save-restriction
          (narrow-to-region top-level-form-start prefix-start)
          (dabbrev--reset-global-variables)
          (while (setq expansion (dabbrev--search prefix t nil))
            (when (anakondo--completion-symbol-bounds)
              (setq all-expansions (cons expansion all-expansions)))))))
    all-expansions))

(defun anakondo--get-java-completion-candidates (prefix)
  "Return the java completion candidates at point for given PREFIX.

PREFIX : Used to figure out when we should complete java classes
         versus completing java methods and fields by checking
         if prefix ends in a forward slash or not."
  (let* ((java-classes-cache (anakondo--get-project-java-classes-cache))
         (class-to-complete (when (string-match "^\\(?1:.*\\)/.*$" prefix)
                              (match-string 1 prefix))))
    (append
     (when class-to-complete
       (let* ((default-import (gethash class-to-complete anakondo--clojure-default-imports)))
         (when default-import
           (setq class-to-complete default-import))
         (let* ((class-map (gethash (anakondo--string->keyword class-to-complete) java-classes-cache)))
           (when class-map
             (let* ((methods-and-fields (gethash :methods-and-fields class-map))
                    (methods-and-fields (if (eq methods-and-fields 'lazy)
                                            (let* ((class-map (anakondo--java-analyze-class-map
                                                               (anakondo--get-java-analysis-classpath 'cp)
                                                               class-to-complete)))
                                              (puthash (anakondo--string->keyword class-to-complete)
                                                       class-map
                                                       java-classes-cache)
                                              (gethash :methods-and-fields class-map))
                                          methods-and-fields)))
               (mapcar
                (lambda (method-or-field)
                  (if default-import
                      (concat (gethash class-to-complete anakondo--clojure-default-imports-reverse)
                              "/" (gethash :name method-or-field))
                    (concat class-to-complete "/" (gethash :name method-or-field))))
                methods-and-fields))))))
     (mapcar
      (lambda (class-map)
        (gethash :name class-map))
      (anakondo--safe-hash-table-values java-classes-cache))
     (hash-table-keys anakondo--clojure-default-imports))))

(defun anakondo-completion-at-point ()
  "Get anakondo's completion at point.

Return a `completion-at-point' list for use with
`completion-at-point-functions' generated from clj-kondo's analysis."
  (let* ((bounds (anakondo--completion-symbol-bounds))
         (start (car bounds))
         (end (cdr bounds)))
    (when bounds
      (list
       start
       end
       (completion-table-dynamic
        (lambda (prefix)
          ;; Invalidate cache if prefix ends in / since java completion
          ;; must re-run in that case, as it doesn't initially return
          ;; completions post /
          (when (string-match-p "^.*/$" prefix)
            (setq-local anakondo--completion-candidates-cache nil))
          (if (and anakondo--completion-candidates-cache
                   (= start (car anakondo--completion-candidates-cache)))
              (cdr (append
                    anakondo--completion-candidates-cache
                    (anakondo--get-local-completion-candidates prefix start)))
            (let* ((candidates (append
                                (anakondo--get-clj-kondo-completion-candidates)
                                (unless (equal (anakondo--get-buffer-lang) "cljs")
                                  (anakondo--get-java-completion-candidates prefix)))))
              (setq-local anakondo--completion-candidates-cache (cons start candidates))
              (append
               candidates
               (anakondo--get-local-completion-candidates prefix start))))))))))

(defun anakondo--project-analyse-sync (var-def-cache ns-def-cache ns-usage-cache java-classes-cache)
  "Analyze project, updating caches with analysis result.

Caches which will be updated are VAR-DEF-CACHE, NS-DEF-CACHE, NS-USAGE-CACHE,
JAVA-CLASSES-CACHE."
  (message "Analysing project for completion...")
  (anakondo--clj-kondo-project-analyse-sync var-def-cache ns-def-cache ns-usage-cache)
  (anakondo--java-project-analyse-sync java-classes-cache)
  (message "Analysing project for completion...done"))

(defun anakondo--init-project-cache (root)
  "Initialize analysis caches for project ROOT.

Initialize clj-kondo analysis cache of caches for given ROOT, if it isn't
already.

This includes performing initial clj-kondo project wide analysis and upserting
it into the newly initialized cache.

Cache looks like:
{root {:var-def-cache {ns {var {var-def-map}}}
       :ns-def-cache {ns {ns-def-map}}
       :ns-usage-cache {ns {to-ns {ns-usage-map}}}
       :java-classes {class {methods/fields {signatures}}}}}"
  (unless anakondo--cache
    (setq anakondo--cache (make-hash-table :test 'equal)))
  (let* ((root-cache (anakondo--get-project-cache root)))
    (if (not root-cache)
        (let* ((root-cache (make-hash-table))
               (var-def-cache (make-hash-table))
               (ns-def-cache (make-hash-table))
               (ns-usage-cache (make-hash-table))
               (java-classes-cache (make-hash-table)))
          (puthash :var-def-cache var-def-cache root-cache)
          (puthash :ns-def-cache ns-def-cache root-cache)
          (puthash :ns-usage-cache ns-usage-cache root-cache)
          (puthash :java-classes-cache java-classes-cache root-cache)
          (anakondo--set-project-cache root root-cache)
          (anakondo--project-analyse-sync var-def-cache ns-def-cache ns-usage-cache java-classes-cache))
      (let* ((var-def-cache (anakondo--get-project-var-def-cache))
             (ns-def-cache (anakondo--get-project-ns-def-cache))
             (ns-usage-cache (anakondo--get-project-ns-usage-cache)))
        (anakondo--clj-kondo-buffer-analyse-sync var-def-cache ns-def-cache ns-usage-cache)))))

(defun anakondo--delete-project-cache (root)
  "Delete the cache for the given ROOT project, releasing its memory."
  (when anakondo--cache
    (when (anakondo--get-project-cache root)
      (remhash root anakondo--cache))))

;;;;; Commands

;;;###autoload
(define-minor-mode anakondo-minor-mode
  "Minor mode for Clojure[Script] completion powered by clj-kondo.

Toggle anakondo-minor-mode on or off.

With a prefix argument ARG, enable anakondo-minor-mode if ARG is
positive, and disable it otherwise. If called from Lisp, enable
the mode if ARG is omitted or nil, and toggle it if ARG is ‘toggle’."
  nil
  anakondo-minor-mode-lighter
  anakondo-minor-mode-map
  (if anakondo-minor-mode
      (anakondo--minor-mode-enter)
    (anakondo--minor-mode-exit)))

(defun anakondo-refresh-project-cache ()
  "Refresh the anakondo project analysis cache.

Run this command if you feel anakondo is out-of-sync with your project source.
Will not pick up changes to source which have not been saved.  So you might want
to save your buffers first.

Runs synchronously, and might take a few seconds for big projects."
  (interactive)
  (anakondo--minor-mode-guard)
  (let* ((var-def-cache (anakondo--get-project-var-def-cache))
         (ns-def-cache (anakondo--get-project-ns-def-cache))
         (ns-usage-cache (anakondo--get-project-ns-usage-cache))
         (java-classes-cache (anakondo--get-project-java-classes-cache)))
    (anakondo--project-analyse-sync var-def-cache ns-def-cache ns-usage-cache java-classes-cache)))

;;;;; Support

(defun anakondo--minor-mode-enter ()
  "Setup command `anakondo-minor-mode' in current buffer."
  (add-hook 'completion-at-point-functions #'anakondo-completion-at-point nil t)
  (anakondo--with-project-root
   (anakondo--init-project-cache root)))

(defun anakondo--minor-mode-exit ()
  "Tear down command `anakondo-minor-mode' in current buffer."
  (remove-hook 'completion-at-point-functions #'anakondo-completion-at-point t)
  (anakondo--with-project-root
   (anakondo--delete-project-cache root))
  (setq-local anakondo--completion-candidates-cache nil))

(defun anakondo--minor-mode-guard ()
  "Signal an error when command `anakondo-minor-mode' is not on.

Signal an error when command `anakondo-minor-mode' is not on in current
buffer."
  (unless anakondo-minor-mode
    (error "Anakondo minor mode not on in current buffer")))

;;;; Footer

(provide 'anakondo)

;;; anakondo.el ends here
