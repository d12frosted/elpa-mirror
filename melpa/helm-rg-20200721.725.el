;;; helm-rg.el --- a helm interface to ripgrep -*- lexical-binding: t -*-

;; Author: Danny McClanahan
;; Version: 0.1
;; Package-Version: 20200721.725
;; Package-Commit: ee0a3c09da0c843715344919400ab0a0190cc9dc
;; URL: https://github.com/cosmicexplorer/helm-rg
;; Package-Requires: ((emacs "25") (cl-lib "0.5") (dash "2.13.0") (helm "2.8.8"))
;; Keywords: find, file, files, helm, fast, rg, ripgrep, grep, search, match

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; The below is generated from a README at
;; https://github.com/cosmicexplorer/helm-rg.

;; MELPA: https://melpa.org/#/helm-rg

;; !`helm-rg' example usage (./emacs-helm-rg.png)

;; Search massive codebases extremely fast, using `ripgrep'
;; (https://github.com/BurntSushi/ripgrep) and `helm'
;; (https://github.com/emacs-helm/helm). Inspired by `helm-ag'
;; (https://github.com/syohex/emacs-helm-ag) and `f3'
;; (https://github.com/cosmicexplorer/f3).

;; Also check out rg.el (https://github.com/dajva/rg.el), which I haven't used
;; much but seems pretty cool.


;; Usage:

;; *See the `ripgrep' whirlwind tour
;; (https://github.com/BurntSushi/ripgrep#whirlwind-tour) for further
;; information on invoking `ripgrep'.*

;; - Invoke the interactive function `helm-rg' to start a search with `ripgrep'
;; in the current directory.
;;     - `helm' is used to browse the results and update the output as you
;; type.
;;     - Each line has the file path, the line number, and the column number of
;; the start of the match, and each part is highlighted differently.
;;     - Use `TAB' to invoke the helm persistent action, which previews the
;; result and highlights the matched text in the preview.
;;     - Use `RET' to visit the file containing the result, move point to the
;; start of the match, and recenter.
;;         - The result's buffer is displayed with
;; `helm-rg-display-buffer-normal-method' (which defaults to
;; `switch-to-buffer').
;;         - Use a prefix argument (`C-u RET') to open the buffer with
;; `helm-rg-display-buffer-alternate-method' (which defaults to
;; `pop-to-buffer').
;; - The text entered into the minibuffer is interpreted into a PCRE
;; (https://pcre.org) regexp to pass to `ripgrep'.
;;     - `helm-rg''s pattern syntax is basically PCRE, but single spaces
;; basically act as a more powerful conjunction operator.
;;         - For example, the pattern `a b' in the minibuffer is transformed
;; into `a.*b|b.*a'.
;;             - The single space can be used to find lines with any
;; permutation of the regexps on either side of the space.
;;             - Two spaces in a row will search for a literal single space.
;;         - `ripgrep''s `--smart-case' option is used so that case-sensitive
;; search is only on if any of the characters in the pattern are capitalized.
;;             - For example, `ab' (conceptually) searches `[Aa][bB]', but `Ab'
;; in the minibuffer will only search for the pattern `Ab' with `ripgrep',
;; because it has at least one uppercase letter.
;; - Use `M-d' to select a new directory to search from.
;; - Use `M-g' to input a glob pattern to filter files by, e.g. `*.py'.
;;     - The glob pattern defaults to the value of
;; `helm-rg-default-glob-string', which is an empty string (matches every file)
;; unless you customize it.
;;     - Pressing `M-g' again shows the same minibuffer prompt for the glob
;; pattern, with the string that was previously input.
;; - Use `<left>' and `<right>' to go up and down by files in the results.
;;     - `<up>' and `<down>' simply go up and down by match result, and there
;; may be many matches for your pattern in a single file, even multiple on a
;; single line (which `ripgrep' reports as multiple separate results).
;;     - The `<left>' and `<right>' keys will move up or down until it lands on
;; a result from a different file than it started on.
;;         - When moving by file, `helm-rg' will cycle around the results list,
;; but it will print a harmless error message instead of looping infinitely if
;; all results are from the same file.
;; - Use the interactive autoloaded function `helm-rg-display-help' to see the
;; ripgrep command's usage info.


;; TODO:

;; *items checked completed here are ready to be added to the docs above*

;; - [x] make a keybinding to drop into an "edit mode" and edit file content
;; inline in results like `helm-ag' (https://github.com/syohex/emacs-helm-ag)
;;     - *currently called "bounce mode"* in the alpha stage
;;     - [x] needs to dedup results from the same line
;;         - [x] should also merge the colorations
;;         - [x] this might be easier without using the `--vimgrep' flag (!!!)
;;     - [x] can insert markers on either side of each line to find the text
;; added or removed
;;     - [x] can change the filename by editing the file line
;;         - [x] needs to reset all the file data for each entry if the file
;; name is being changed!!!
;;     - [x] can expand the windows of text beyond single lines at a time
;;         - using `helm-rg--expand-match-context' and/or
;; `helm-rg--spread-match-context'
;;         - [x] and pop into another buffer for a quick view if you want
;;           - can use `helm-rg--visit-current-file-for-bounce'
;;         - [ ] can expand up and down from file header lines to add lines
;; from the top or bottom of the file!
;;         - [ ] can use newlines in inserted text
;;             - not for file names -- newlines are still removed there
;;             - would need to use text properties to move by match results
;; then, for everything that uses `helm-rg--apply-matches-with-file-for-bounce'
;; basically
;;     - [x] visiting the file should go to the appropriate line of the file!
;; - [x] color all results in the file in the async action!
;;     - [x] don't recolor when switching to a different result in the same
;; file!
;;     - [x] don't color matches whenever file path matches
;; `helm-rg-shallow-highlight-files-regexp'
;; - [ ] use `ripgrep' file types instead of flattening globbing out into
;; `helm-rg-default-glob-string'
;;     - user defines file types in a `defcustom', and can interactively toggle
;; the accepted file types
;;     - user can also set the default set of file types
;;         - as a dir-local variable!!
;; - [ ] add testing
;;   - [ ] should be testing all of our interactive functions
;;       - in all configurations (for all permutations of `defcustom' values)
;;   - [ ] also everything that's called by helm
;;       - does helm have any frameworks to make integration testing easier?
;; - [ ] publish `update-commentary.el' and the associated machinery
;;     - as an npm package, MELPA package, pandoc writer, *???*
;; - [ ] make a keybinding for running `helm-rg' on dired marked files
;;     - then you could do an `f3' search, bounce to dired, then immediately
;; `helm-rg' on just the file paths from the `f3' search, *which would be
;; sick*


;; License:

;; GPL 3.0+ (./LICENSE)

;; End Commentary


;;; Code:

(require 'ansi-color)
(require 'cl-lib)
(require 'dash)
(require 'font-lock)
(require 'helm)
(require 'helm-files)
(require 'helm-grep)
(require 'helm-lib)
(require 'pcase)
(require 'rx)
(require 'subr-x)


;; Customization Helpers
(defun helm-rg--always-safe-local (_)
  "Use as a :safe predicate in a `defcustom' form to accept any local override."
  t)

(defun helm-rg--gen-defcustom-form-from-alist (name alist doc args)
  ;; TODO: get all the pcase macros at the very top of the file!
  (let ((alist-resolved (pcase-exhaustive alist
                          ((and (pred symbolp) x) (symbol-value x))
                          ((and (pred listp) x) x))))
    `(defcustom ,name ',(car (helm-rg--alist-keys alist-resolved))
       ,doc
       :type `(radio ,@(--map `(const ,it) (helm-rg--alist-keys ',alist-resolved)))
       :group 'helm-rg
       ,@args)))

(defmacro helm-rg--defcustom-from-alist (name alist doc &rest args)
  "Create a `defcustom' named NAME which can take the keys of ALIST as values.

The DOC and ARGS are passed on to the generated `defcustom' form. The default value for the
`defcustom' is the `car' of the first element of ALIST. ALIST must be the unquoted name of a
variable containing an alist."
  (declare (indent 2))
  (helm-rg--gen-defcustom-form-from-alist name alist doc args))


;; CL deftypes
(cl-deftype helm-rg-existing-file ()
  `(and string
        (satisfies file-exists-p)))

(cl-deftype helm-rg-existing-directory ()
  `(and helm-rg-existing-file
        (satisfies file-directory-p)))


;; Interesting macros
(cl-defmacro helm-rg--with-gensyms ((&rest syms) &rest body)
  (declare (indent 1))
  `(let ,(--map `(,it (cl-gensym)) syms)
     ,@body))

(defmacro helm-rg--_ (expr)
  "Replace all instances of `_' in EXPR with an anonymous argument.

Return a lambda accepting that argument."
  (declare (debug (sexp body)))
  (helm-rg--with-gensyms (arg)
    `(lambda (,arg)
       ,(cl-subst arg '_ expr :test #'eq))))

(cl-defun helm-rg--join-conditions (conditions &key (joiner 'or))
  "If CONDITIONS has one element, return it, otherwise wrap them with JOINER.

This is used because `pcase' doesn't accept conditions with a single element (e.g. `(or 3)')."
  (pcase-exhaustive conditions
    (`nil (error "The list of conditions may not be nil (with joiner '%S')" joiner))
    (`(,single-sexp) single-sexp)
    (x `(,joiner ,@x))))

(pcase-defmacro helm-rg-cl-typep (&rest types)
  "Matches when the subject is any of TYPES, using `cl-typep'."
  (helm-rg--with-gensyms (val)
    `(and ,val
          ,(helm-rg--join-conditions
            (--map `(guard (cl-typep ,val ',it)) types)))))

(pcase-defmacro helm-rg-deref-sym (sym)
  "???"
  (list 'quote (eval sym)))

(defconst helm-rg--keyword-symbol-rx-expr `(: bos ":"))

(cl-deftype helm-rg-non-keyword-symbol ()
  `(and symbol
        (not keyword)))

(defun helm-rg--make-non-keyword-sym-from-keyword-sym (kw-sym)
  (cl-check-type kw-sym keyword)
  (->> kw-sym
       (symbol-name)
       (replace-regexp-in-string (rx-to-string helm-rg--keyword-symbol-rx-expr) "")
       (intern)))

(defun helm-rg--make-keyword-from-non-keyword-sym (non-kw-sym)
  (cl-check-type non-kw-sym helm-rg-non-keyword-symbol)
  (->> non-kw-sym
       (symbol-name)
       (format ":%s")
       (intern)))

(defun helm-rg--parse-plist-spec (plist-spec)
  (pcase-exhaustive plist-spec
    (`(,(and (helm-rg-cl-typep keyword) kw-sym)
       ,value)
     `(,kw-sym ,value))
    ((and (helm-rg-cl-typep helm-rg-non-keyword-symbol)
          sym)
     `(,(helm-rg--make-keyword-from-non-keyword-sym sym)
       ,sym))))

(defmacro helm-rg-construct-plist (&rest plist-specs)
  (->> plist-specs
       (-map #'helm-rg--parse-plist-spec)
       (apply #'append '(list))))

(defun helm-rg--parse-&optional-spec (optional-spec)
  (pcase-exhaustive optional-spec
    (`(,upat ,initform ,svar)
     (helm-rg-construct-plist upat initform svar))
    (`(,upat ,initform)
     (helm-rg-construct-plist upat initform))
    ((or `(,upat) upat)
     (helm-rg-construct-plist upat))))

(defun helm-rg--read-&optional-specs (parsed-optional-spec-list)
  (pcase-exhaustive parsed-optional-spec-list
    (`(,cur . ,rest)
     `(or (and `nil
               ,@(->> (cons cur rest)
                      (--map (cl-destructuring-bind (&key upat initform svar) it
                               `(,@(and svar `((let ,svar nil)))
                                 (let ,upat ,initform))))
                      (funcall #'append)
                      (-flatten-n 1)))
          ,(cl-destructuring-bind (&key upat _initform svar) cur
             (helm-rg--join-conditions
              ;; FIXME: put the below comment in the docstrings for optional and keyword pcase
              ;; macros!
              ;; NB: SVAR is bound before INITFORM is evaluated, which means you can refer to SVAR
              ;; within INITFORM (and more importantly, within UPAT)!
              `(,@(and svar `((let ,svar t)))
                ,(->> (and rest
                           (->> rest
                                (helm-rg--read-&optional-specs)
                                (list '\,)))
                      (cons (list '\, upat))
                      (list '\`)))
              :joiner 'and))))))

(pcase-defmacro helm-rg-&optional (&rest all-optional-specs)
  (->> all-optional-specs
       (-map #'helm-rg--parse-&optional-spec)
       (helm-rg--read-&optional-specs)))

(defun helm-rg--parse-&key-spec (key-spec)
  (pcase-exhaustive key-spec
    ((and (or :exhaustive :required) special-sym)
     special-sym)
    (`(,(or `(,(and (helm-rg-cl-typep keyword)
                    kw-sym)
              ,upat)
            (and (or `(,upat) upat)
                 (let kw-sym (helm-rg--make-keyword-from-non-keyword-sym upat))))
       . ,(or
           (and :required
                (let required t)
                (let initform nil)
                (let svar nil))
           (and (helm-rg-&optional initform svar)
                (let required nil))))
     (helm-rg-construct-plist kw-sym upat required initform svar))
    ((and (helm-rg-cl-typep helm-rg-non-keyword-symbol)
          upat)
     (helm-rg-construct-plist
      (:kw-sym (helm-rg--make-keyword-from-non-keyword-sym upat))
      upat
      (:required nil)
      (:initform nil)
      (:svar nil)))))

(defun helm-rg--flipped-plist-member (prop plist)
  (plist-member plist prop))

(defun helm-rg--plist-parse-pairs (plist)
  (cl-loop
   with prev-keyword = nil
   for el in plist
   for is-keyword-posn = t then (not is-keyword-posn)
   when is-keyword-posn
   do (progn
        (cl-check-type el keyword)
        (setq prev-keyword el))
   else
   collect (list prev-keyword el)
   into pairs
   finally return (progn
                    (cl-assert (not is-keyword-posn) t
                               (format "Invalid plist %S ends on keyword '%S'"
                                       plist prev-keyword))
                    pairs)))

(defun helm-rg--plist-keys (plist)
  (->> plist
       (helm-rg--plist-parse-pairs)
       (-map #'car)))

(defun helm-rg--force-required-parsed-&key-spec (spec)
  (cl-destructuring-bind (&key kw-sym upat required initform svar) spec
    ;; TODO: better error messaging here!
    (cl-assert (not initform))
    (cl-assert (not svar))
    (cl-assert (not required))
    (helm-rg-construct-plist kw-sym upat (:required t) (:initform nil) (:svar nil))))

(cl-defun helm-rg--find-first-duplicate (seq &key (test #'eq))
  (cl-loop
   with tbl = (make-hash-table :test test)
   for el in seq
   when (gethash el tbl)
   return el
   else do (puthash el t tbl)
   finally return nil))

(cl-defun helm-rg--read-&key-specs (parsed-key-spec-list &key exhaustive)
  (let* ((all-keys (->> parsed-key-spec-list
                        (--keep (pcase-exhaustive it
                                  (:required nil)
                                  (x (plist-get x :kw-sym))))))
         (first-duplicate-key (helm-rg--find-first-duplicate all-keys)))
    (when first-duplicate-key
      (error "Keyword '%S' provided more than once for keyword set %S"
             first-duplicate-key all-keys))
    (let ((pcase-expr
           (pcase-exhaustive parsed-key-spec-list
             (`(:required . ,rest)
              (--> rest
                   (-map #'helm-rg--force-required-parsed-&key-spec it)
                   (helm-rg--read-&key-specs it)))
             (`(,cur . ,rest)
              (helm-rg--join-conditions
               `(,(helm-rg--join-conditions
                   (cl-destructuring-bind
                       (&key kw-sym upat required initform svar) cur
                     `((app (helm-rg--flipped-plist-member ,kw-sym)
                            ,(helm-rg--join-conditions
                              `(,@(unless required
                                    `((and `nil
                                           ,@(and svar `((let ,svar nil)))
                                           (let ,upat ,initform))))
                                ,(helm-rg--join-conditions
                                  `(,@(and svar `((let ,svar t)))
                                    ;; `plist-member' gives us the rest of the list too -- discard
                                    ;; by matching it to `_'.
                                    ,(->> (list kw-sym (list '\, upat) '\, '_)
                                          (list '\`)))
                                  :joiner 'and))
                              :joiner 'or))))
                   :joiner 'and)
                 ,@(and rest (list (helm-rg--read-&key-specs rest))))
               :joiner 'and)))))
      (if exhaustive
          (helm-rg--with-gensyms (exp-plist-keys)
            `(and
              ;; NB: we do not attempt to parse the `pcase' subject as a plist (done with
              ;; `helm-rg--plist-keys') unless `:exhaustive' is provided (we just use `plist-get')
              ;; -- this is intentional.
              (and (app (helm-rg--plist-keys) ,exp-plist-keys)
                   (guard (not (-difference ,exp-plist-keys ',all-keys))))
              ,pcase-expr))
        pcase-expr))))

(pcase-defmacro helm-rg-&key (&rest all-key-specs)
  ;;; TODO: add alist matching -- this should be trivial, just allowing
  ;;; non-keyword syms in the argument spec.
  (pcase all-key-specs
    (`(:exhaustive . ,rest)
     (--> rest
          (-map #'helm-rg--parse-&key-spec it)
          (helm-rg--read-&key-specs it :exhaustive t)))
    (specs (->> specs
                (-map #'helm-rg--parse-&key-spec)
                (helm-rg--read-&key-specs)))))

(pcase-defmacro helm-rg-&key-complete (&rest all-key-specs)
  "`helm-rg-&key', but there must be no other keys, and all the keys in ALL-KEY-SPECS must exist."
  `(helm-rg-&key :exhaustive :required ,@all-key-specs))

(defun helm-rg--parse-format-spec (format-spec)
  "Convert a list FORMAT-SPEC into some result for `helm-rg--make-formatter'."
  (pcase-exhaustive format-spec
    ((and (helm-rg-cl-typep string) x)
     (helm-rg-construct-plist
      (:fmt x) (:expr nil) (:argument nil)))
    ((and (helm-rg-cl-typep helm-rg-non-keyword-symbol) sym)
     (helm-rg-construct-plist (:fmt "%s") (:expr sym) (:argument nil)))
    ((and (helm-rg-cl-typep keyword)
          (app (helm-rg--make-non-keyword-sym-from-keyword-sym)
               non-kw-sym))
     (helm-rg-construct-plist (:fmt "%s") (:expr non-kw-sym) (:argument non-kw-sym)))
    (`(,(or (and (helm-rg-cl-typep keyword)
                 (app (helm-rg--make-non-keyword-sym-from-keyword-sym)
                      argument)
                 (let expr argument))
            (and expr (let argument nil)))
       . ,(helm-rg-&key (fmt "%s")))
     (helm-rg-construct-plist fmt expr argument))))

(defun helm-rg--read-format-specs (format-spec-list)
  (cl-loop
   with fmts = nil
   with exprs = nil
   with arguments = nil
   for parsed-spec in (-map #'helm-rg--parse-format-spec format-spec-list)
   ;; TODO: turn this into an unzip-plists method/macro or something!
   do (cl-destructuring-bind (&key fmt expr argument) parsed-spec
        (push fmt fmts)
        (when expr (push expr exprs))
        (when argument (push argument arguments)))
   finally return (helm-rg-construct-plist
                   (:fmts (reverse fmts))
                   (:exprs (reverse exprs))
                   (:arguments (-> arguments (-uniq) (reverse))))))

(cl-defmacro helm-rg-format ((format-specs &rest kwargs) &key (sep " "))
  (cl-destructuring-bind (&key fmts exprs arguments)
      (helm-rg--read-format-specs format-specs)
    (cond
     (arguments
      `(cl-destructuring-bind (&key ,@arguments) ',kwargs
         ;; TODO: a "once-only" macro that's just sugar for gensyms
         (format (mapconcat #'identity (list ,@fmts) ,sep) ,@exprs)))
     (kwargs
      (error "No arguments were declared, but keyword arguments %S were provided" kwargs))
     (t
      `(format (mapconcat #'identity (list ,@fmts) ,sep) ,@exprs)))))

(cl-defmacro helm-rg-make-formatter (format-specs &key (sep " "))
  (cl-destructuring-bind (&key fmts exprs arguments)
      (helm-rg--read-format-specs format-specs)
    (unless arguments
      (error "No arguments were declared in the specs %S" format-specs))
    ;; TODO: make a macro that can create a lambda with visible keyword arguments (a "cl-lambda"
    ;; type thing)
    (helm-rg--with-gensyms (args)
      `(lambda (&rest ,args)
         (cl-destructuring-bind (&key ,@arguments) ,args
           (format (mapconcat #'identity (list ,@fmts) ,sep) ,@exprs))))))

(defun helm-rg--validate-rx-kwarg (keyword-sym-for-binding)
  (pcase-exhaustive keyword-sym-for-binding
    ((and (helm-rg-cl-typep keyword)
          (app (helm-rg--make-non-keyword-sym-from-keyword-sym)
               non-kw-sym))
     non-kw-sym)
    ((and (helm-rg-cl-typep symbol)
          non-kw-sym
          (app (helm-rg--make-keyword-from-non-keyword-sym)
               kw-sym))
     (error (helm-rg-format
                (("symbol" (non-kw-sym :fmt "%S")
                  "must be a keyword arg" (kw-sym :fmt "(e.g. %S)."))))))))

(defun helm-rg--apply-tree-fun (mapper tree)
  "Apply MAPPER to the nodes of TREE using `-tree-map-nodes'.

This method applies MAPPER, saves the result, and if the result is non-nil, returns the result
instead of the node of MAPPER, otherwise it continues to recurse down the nodes of TREE."
  (let (intermediate-value-holder)
    (-tree-map-nodes
     (helm-rg--_ (setq intermediate-value-holder (funcall mapper _)))
     (helm-rg--_ intermediate-value-holder)
     tree)))

(defmacro helm-rg--pcase-tree (tree &rest pcase-exprs)
  "Apply a `pcase' to the nodes of TREE with `helm-rg--apply-tree-fun'.

PCASE-EXPRS are the cases provided to `pcase'. If the `pcase' cases do not
match the node (returns nil), it continues to recurse down the tree --
otherwise, the return value replaces the node of the tree."
  (declare (indent 1))
  `(helm-rg--apply-tree-fun
    (helm-rg--_ (pcase _ ,@pcase-exprs))
    ,tree))

(defconst helm-rg--named-group-symbol 'named-group)
(defconst helm-rg--eval-expr-symbol 'eval)
(defconst helm-rg--duplicate-var-eval-form-error-str
  "'%S' variable name used a second time in evaluation of form '%S'.
previous vars were: %S")
(defconst helm-rg--duplicate-var-literal-form-error-str
  "'%S' variable named used a second time in declaration of regexp group '%S'.
previous vars were: %S")
(cl-defun helm-rg--transform-rx-sexp (sexp &key (group-num-init 1))
  (let ((all-bind-vars-mappings nil))
    (--> (helm-rg--pcase-tree sexp
           ;; `(eval ,eval-expr) => evaluate the expression!
           ;; NB: this occurs at macro-expansion time, like the equivalent `rx'
           ;; pcase macro, which is before any surrounding let-bindings occur!)
           (`(,(helm-rg-deref-sym helm-rg--eval-expr-symbol) ,eval-expr)
            (cl-destructuring-bind (&key transformed bind-vars)
                (helm-rg--transform-rx-sexp (eval eval-expr t) :group-num-init group-num-init)
              (cl-loop
               for quoted-var in bind-vars
               do (progn
                    (cl-incf group-num-init)
                    (when (cl-find quoted-var all-bind-vars-mappings)
                      (error helm-rg--duplicate-var-eval-form-error-str
                             quoted-var eval-expr all-bind-vars-mappings))
                    (push quoted-var all-bind-vars-mappings)))
              transformed))
           ;; `(named-group :var-name . ,rx-forms) => create an explicitly-numbered regexp group
           ;; and, if the resulting regexp matches, bind the match string for that numbered group to
           ;; var-name (without the initial ":", which is required)!
           (`(,(helm-rg-deref-sym helm-rg--named-group-symbol)
              ,(app (helm-rg--validate-rx-kwarg) binding-var)
              . ,rx-forms)
            ;; We have bound to this variable -- save the current group number and push this
            ;; variable onto the list of binding variables.
            (let ((cur-group-num group-num-init))
              (push binding-var all-bind-vars-mappings)
              (cl-incf group-num-init)
              (cl-loop
               for sub-rx in rx-forms
               collect (cl-destructuring-bind (&key transformed bind-vars)
                           (helm-rg--transform-rx-sexp sub-rx :group-num-init group-num-init)
                         (cl-loop
                          for quoted-var in bind-vars
                          do (progn
                               (cl-incf group-num-init)
                               (when (cl-find quoted-var all-bind-vars-mappings)
                                 (error
                                  helm-rg--duplicate-var-literal-form-error-str
                                  quoted-var sub-rx all-bind-vars-mappings))
                               (push quoted-var all-bind-vars-mappings)))
                         transformed)
               into all-transformed-exprs
               finally return `(group-n ,cur-group-num ,@all-transformed-exprs)))))
         (list :transformed it :bind-vars (reverse all-bind-vars-mappings)))))

(defmacro helm-rg-pcase-cl-defmacro (&rest args)
  "`pcase-defmacro', but the --pcase-macroexpander function is a `cl-defun'.
\n(fn NAME ARGS [DOC] &rest BODY...)"
  (declare (indent 2) (debug defun) (doc-string 3))
  (->> `(pcase-defmacro ,@args)
       (macroexpand-1)
       (cl-subst 'cl-defun 'defun)))

(helm-rg-pcase-cl-defmacro helm-rg-rx (rx-sexp)
  ;; FIXME: have some way to get the indices of each bound var (for things like
  ;; `match-data')
  (pcase-exhaustive (helm-rg--transform-rx-sexp rx-sexp)
    ((helm-rg-&key-complete transformed bind-vars)
     (helm-rg--with-gensyms (str-sym)
       `(and ,str-sym
             ,(helm-rg--join-conditions
               ;; We would just delegate to `rx--pcase-macroexpander', but requiring subr errors
               ;; out, extremely mysteriously.
               `((pred (string-match (rx-to-string ',transformed)))
                 ,@(cl-loop for symbol-to-bind in bind-vars
                            for match-index upfrom 1
                            collect `(let ,symbol-to-bind (match-string ,match-index ,str-sym))))
               :joiner 'and))))))

(defun helm-rg--prefix-symbol-with-underscore (sym)
  (->> sym
       (symbol-name)
       (format "_%s")
       (intern)))

(defmacro helm-rg-mark-unused (vars &rest body)
  (declare (indent 1))
  `(let (,@(--map `(,(helm-rg--prefix-symbol-with-underscore it) ,it) vars))
     ,@body))


;; Public error types
(define-error 'helm-rg-error "Error invoking `helm-rg'")


;; Customization
(defgroup helm-rg nil
  "Group for `helm-rg' customizations."
  :group 'helm-grep)

(defcustom helm-rg-ripgrep-executable (executable-find "rg")
  "The location of the ripgrep binary executable."
  :type 'string
  :group 'helm-rg)

(defcustom helm-rg-default-glob-string ""
  "The glob pattern used for the '-g' argument to ripgrep.
Set to the empty string to match every file."
  :type 'string
  :safe #'helm-rg--always-safe-local
  :group 'helm-rg)

(defcustom helm-rg-default-extra-args nil
  "Extra arguments passed to ripgrep on the command line.
Note that default filename globbing and case sensitivity can be set with their own defcustoms, and
can be modified while invoking `helm-rg' -- see the help for that method. If the extra arguments are
ones you use commonly, consider submitting a pull request to
https://github.com/cosmicexplorer/helm-rg with a specific `defcustom' and keybinding for that
particular ripgrep option and set of options."
  :type '(repeat string)
  :safe #'helm-rg--always-safe-local
  :group 'helm-rg)

(defcustom helm-rg-default-directory 'default
  "Specification for starting directory to invoke ripgrep in.
Used in `helm-rg--interpret-starting-dir'. Possible values:

'default => Use `default-directory'.
'git-root => Use \"git rev-parse --show-toplevel\" (see
             `helm-rg-git-executable').
<string> => Use the directory at path <string>."
  :type '(choice symbol string)
  :safe #'helm-rg--always-safe-local
  :group 'helm-rg)

(defcustom helm-rg-git-executable (executable-find "git")
  "Location of git executable."
  :type 'string
  :group 'helm-rg)

(defcustom helm-rg-thing-at-point 'symbol
  "Type of object at point to initialize the `helm-rg' minibuffer input with."
  :type 'symbol
  :safe #'helm-rg--always-safe-local
  :group 'helm-rg)

(defcustom helm-rg-input-min-search-chars 2
  "Ripgrep will not be invoked unless the input is at least this many chars.

See `helm-rg--make-process' and `helm-rg--make-dummy-process' if interested."
  ;; FIXME: this should be a *positive* integer!
  :type 'integer
  :safe #'helm-rg--always-safe-local
  :group 'helm-rg)

(defcustom helm-rg-display-buffer-normal-method #'switch-to-buffer
  "A function accepting a single argument BUF and displaying the buffer.

The default function to invoke to display a visited buffer in some window in
`helm-rg'."
  :type 'function
  :group 'helm-rg)

(defcustom helm-rg-display-buffer-alternate-method #'pop-to-buffer
  "A function accepting a single argument BUF and displaying the buffer.

The function will be invoked if a prefix argument is used when visiting a result
in `helm-rg'."
  :type 'function
  :group 'helm-rg)

(defcustom helm-rg-shallow-highlight-files-regexp nil
  "Regexp describing file paths to only partially highlight, for performance reasons.

By default, `helm-rg' will create overlays to highlight all the matches from ripgrep in a file when
previewing a result. This is done each time a match is selected, even for buffers already
previewed. Creating these overlays can be slow for files with lots of matches in some search. If
this variable is set to an elisp regexp and some file path matches it, `helm-rg' will only highlight
the current line of the file and the matches in that line when previewing that file."
  :type 'regexp
  :safe #'helm-rg--always-safe-local
  :group 'helm-rg)

(defcustom helm-rg-prepend-file-name-line-at-top-of-matches t
  "Whether to put the file path as a separate line in `helm-rg' output above the file's matches.

The file can be visited as if it was a match on the first line of the file (without any matched
text).

FIXME: if this is nil and `helm-rg-include-file-on-every-match-line' is t, you get a stream of just
line numbers and content, without any file names. We should unify these two boolean options somehow
to get all three allowable states."
  :type 'boolean
  :group 'helm-rg)

(defcustom helm-rg-include-file-on-every-match-line nil
  "Whether to include the file path on every line of `helm-rg' output.

This is purely an interface change, and does not affect anything else."
  :type 'boolean
  :group 'helm-rg)

(defcustom helm-rg--default-expand-match-lines-for-bounce 3
  "???"
  ;; FIXME: this should be a *positive* integer!
  :type 'integer
  :group 'helm-rg)


;; Faces
(defface helm-rg-preview-line-highlight
  '((t (:background "green" :foreground "black")))
  "Face for the line of text matched by the ripgrep process."
  :group 'helm-rg)

(defface helm-rg-base-rg-cmd-face
  '((t (:foreground "gray" :weight normal)))
  "Face for the ripgrep executable in the ripgrep invocation."
  :group 'helm-rg)

(defface helm-rg-extra-arg-face
  '((t (:foreground "yellow" :weight normal)))
  "Face for any arguments added to the command line through `helm-rg--extra-args'."
  :group 'helm-rg)

(defface helm-rg-inactive-arg-face
  '((t (:foreground "gray" :weight normal)))
  "Face for non-essential arguments in the ripgrep invocation."
  :group 'helm-rg)

(defface helm-rg-active-arg-face
  '((t (:foreground "green")))
  "Face for arguments in the ripgrep invocation which affect the results."
  :group 'helm-rg)

(defface helm-rg-directory-cmd-face
  '((t (:foreground "brown" :background "black" :weight normal)))
  "Face for any directories provided as paths to the ripgrep invocation.")

(defface helm-rg-error-message
  '((t (:foreground "red")))
  "Face for error text displayed in the `helm-buffer' for `helm-rg'."
  :group 'helm-rg)

(defface helm-rg-title-face
  '((t (:foreground "purple" :background "black" :weight bold)))
  "Face for the title of the ripgrep async helm source."
  :group 'helm-rg)

(defface helm-rg-directory-header-face
  '((t (:foreground "white" :background "black" :weight bold)))
  "Face for the current directory in the header of the `helm-buffer' for `helm-rg'."
  :group 'helm-rg)

(defface helm-rg-file-match-face
  '((t (:foreground "#0ff" :underline t)))
  "Face for the file name when displaying matches in the `helm-buffer' for `helm-rg'."
  :group 'helm-rg)

(defface helm-rg-colon-separator-ripgrep-output-face
  '((t (:foreground "white")))
  "Face for the separator between file, line, and match text in ripgrep output."
  :group 'helm-rg)

(defface helm-rg-line-number-match-face
  '((t (:foreground "orange" :underline t)))
  "Face for line numbers when displaying matches in the `helm-buffer' for `helm-rg'."
  :group 'helm-rg)

(defface helm-rg-match-text-face
  '((t (:foreground "white" :background "purple")))
  "Face for displaying matches in the `helm-buffer' and in file previews for `helm-rg'."
  :group 'helm-rg)


;; Constants
(defconst helm-rg--color-format-argument-alist
  '((red :cmd-line "red" :text-property "red3"))
  "Alist mapping symbols to color descriptions.

This alist mapps (a symbol named after a color) -> (strings to describe that symbol on the ripgrep
command line and in an Emacs text property). This allows `helm-rg' to identify matched text using
ripgrep's highlighted output directly instead of doing it ourselves, by telling ripgrep to highlight
matches a specific color, then searching for that specific color as a text property in the output.")

(defconst helm-rg--style-format-argument-alist
  '((bold :cmd-line "bold" :text-property bold))
  "Very similar to `helm-rg--color-format-argument-alist', but for non-color styling.")

(defconst helm-rg--case-sensitive-argument-alist
  '((smart-case "--smart-case")
    (case-sensitive "--case-sensitive")
    (case-insensitive "--ignore-case"))
  "Alist of methods of treating case-sensitivity when invoking ripgrep.

The value is the ripgrep command line argument which enforces the specified type of
case-sensitivity.")

(defconst helm-rg--ripgrep-argv-format-alist
  `((helm-rg-ripgrep-executable :face helm-rg-base-rg-cmd-face)
    ((->> helm-rg--case-sensitive-argument-alist
          (helm-rg--alist-get-exhaustive helm-rg--case-sensitivity))
     :face helm-rg-active-arg-face)
    ("--color=ansi" :face helm-rg-inactive-arg-face)
    ((helm-rg--construct-match-color-format-arguments)
     :face helm-rg-inactive-arg-face)
    ((unless (helm-rg--empty-glob-p helm-rg--glob-string)
       (list "-g" helm-rg--glob-string))
     :face helm-rg-active-arg-face)
    (helm-rg--extra-args :face helm-rg-extra-arg-face)
    (it
     :face font-lock-string-face)
    ((helm-rg--process-paths-to-search helm-rg--paths-to-search)
     :face helm-rg-directory-cmd-face))
  "Alist mapping (sexp -> face) describing how to generate and propertize the argv for ripgrep.")

(defconst helm-rg--helm-buffer-name "*helm-rg*")
(defconst helm-rg--process-name "*helm-rg--rg*")
(defconst helm-rg--process-buffer-name "*helm-rg--rg-output*")

(defconst helm-rg--error-process-name "*helm-rg--error-process*")
(defconst helm-rg--error-buffer-name "*helm-rg--errors*")

(defconst helm-rg--ripgrep-help-buffer-name "helm-rg-usage-help")

(defconst helm-rg--bounce-buffer-name "helm-rg-bounce-buf")

(defconst helm-rg--output-new-file-line-rx-expr
  `(named-group
    :whole-line
    (: bos
       (named-group :file-path (+? (not (any 0))))
       eos))
  "Regexp for ripgrep output which marks the start of results for a new file.

See `helm-rg--process-transition' for usage.")

(defconst helm-rg--numbered-text-line-rx-expr
  `(named-group
    :whole-line
    (: bos
       (named-group :line-num-str (+ digit))
       ":"
       (named-group :content (*? anything))
       eos))
  "Regexp for ripgrep output which marks a matched line, with the line number and content.

See `helm-rg--process-transition' for usage.")

(defconst helm-rg--persistent-action-display-buffer-method #'switch-to-buffer
  "A function accepting a single argument BUF and displaying the buffer.

Let-bound to `helm-rg--display-buffer-method' in `helm-rg--async-persistent-action'.")

(defconst helm-rg--loop-input-pattern-regexp
  (rx
   (:
    (* (char ? ))
    ;; group 1 = single entire element
    (group
     (+
      (|
       (not (in ? ))
       (= 2 ? ))))))
  "Regexp applied iteratively to split the input interpreted by `helm-rg'.")

(defconst helm-rg--all-whitespace-regexp
  (rx (: bos (zero-or-more space) eos)))

(defconst helm-rg--jump-location-text-property 'helm-rg-jump-to
  "Name of a text property attached to the colorized ripgrep output.

This text property contains location and match info. See `helm-rg--process-transition' for usage.")

(defconst helm-rg--helm-header-property-name 'helm-header
  "Property used for the \"header\" of the `helm-buffer' displayed in `helm-rg'.

This header is generated by helm, and is separate from the process output.")


;; Variables
(defvar helm-rg--append-persistent-buffers nil
  "Whether to record buffers opened during an `helm-rg' session.")

(defvar helm-rg--cur-persistent-bufs nil
  "List of buffers opened temporarily during an `helm-rg' session.")

(defvar helm-rg--matches-in-current-file-overlays nil
  "List of overlays used to highlight matches in `helm-rg'.")

(defvar helm-rg--current-line-overlay nil
  "Overlay for highlighting the selected matching line in a file in `helm-rg'.")

(defvar helm-rg--current-dir nil
  "Working directory for the current `helm-rg' session.")

(defvar helm-rg--last-dir nil
  "Last used working directory for resume.")

(defvar helm-rg--glob-string nil
  "Glob string used for the current `helm-rg' session.")

(defvar helm-rg--glob-string-history nil
  "History variable for the selection of `helm-rg--glob-string'.")

(defvar helm-rg--extra-args nil
  "Arguments not associated with other `helm-rg' options, added to the ripgrep command line.")

(defvar helm-rg--extra-args-history nil
  "History variable for the selection of `helm-rg--extra-args'.")

(defvar helm-rg--input-history nil
  "History variable for the pattern input to the ripgrep process.")

(defvar helm-rg--display-buffer-method nil
  "The method to use to display a buffer visiting a result.
Should accept one argument BUF, the buffer to display.")

(defvar helm-rg--paths-to-search nil
  ;; FIXME: we have multiple `defvar's which just mirror `defcustoms' (and can then be toggled while
  ;; searching) -- we should almost definitely have a macro to declare/access these kinds of
  ;; variables uniformly.
  "List of paths to use in the ripgrep command.
All paths are interpreted relative to the directory ripgrep is invoked from.
When nil, searches from the directory ripgrep is invoked from.
See the documentation for `helm-rg-default-directory'.")

(defvar helm-rg--case-sensitivity nil
  "Key of `helm-rg--case-sensitive-argument-alist' to use in a `helm-rg' session.")

(defvar helm-rg--previously-highlighted-buffer nil
  "Previous buffer visited in between async actions of a `helm-rg' session.

Used to cache the overlays drawn for matches within a file when visiting matches in the same file
using `helm-rg--async-persistent-action'.")

(defvar helm-rg--last-argv nil
  "Argument list for the most recent ripgrep invocation.

Used for the command line header in `helm-rg--bounce-mode'.")


;; Buffer-local Variables
(defvar-local helm-rg--process-output-parse-state
  (list :cur-file nil)
  "Contains state which is updated as the ripgrep output is processed.

This is buffer-local because it is specific to a single process invocation and is manipulated in
that process's buffer. See `helm-rg--parse-process-output' for usage.")

(defvar-local helm-rg--beginning-of-bounce-content-mark nil
  "Contains a marker pointing to the beginning of the match results in a `helm-rg--bounce' buffer.")

(defvar-local helm-rg--do-font-locking nil
  "If t, colorize the file text as it would be in an editor.

This may be expensive for larger files, so it is turned off if
`helm-rg-shallow-highlight-files-regexp' is a regexp matching the file's path.")


;; Utilities
(defun helm-rg--alist-get-exhaustive (key alist)
  "Get KEY from ALIST, or throw an error."
  (or (alist-get key alist)
      (error "Key '%s' was not found in alist '%S' during an exhaustiveness check"
             key alist)))

(defun helm-rg--alist-keys (alist)
  "Get all keys of ALIST."
  (cl-mapcar #'car alist))

(defmacro helm-rg--get-optional-typed (type-name obj &rest body)
  "If OBJ is non-nil, check its type against TYPE-NAME, then bind it to `it' and execute BODY."
  (declare (indent 2))
  `(let ((it ,obj))
     (when it
       (cl-check-type it ,type-name)
       ,@body)))

(defmacro helm-rg--into-temp-buffer (to-insert &rest body)
  "Execute BODY at the beginning of a `with-temp-buffer' containing TO-INSERT."
  (declare (indent 1))
  `(with-temp-buffer
     (insert ,to-insert)
     (goto-char (point-min))
     ,@body))

(defmacro helm-rg--with-named-temp-buffer (name &rest body)
  "Execute BODY after binding the result of a `with-temp-buffer' to NAME.

BODY is executed in the original buffer, not the new temp buffer."
  (declare (indent 1))
  (let ((cur-buf (cl-gensym "helm-rg--with-named-temp-buffer")))
    `(let ((,cur-buf (current-buffer)))
       (with-temp-buffer
         (let ((,name (current-buffer)))
           (with-current-buffer ,cur-buf
             ,@body))))))


;; Logic
(defun helm-rg--make-dummy-process (input err-msg)
  "Make a process that immediately exits to display just a title.

Provide INPUT to represent the `helm-pattern', and ERR-MSG as the reasoning for failing to display
any results."
  (let* ((dummy-proc (make-process
                      :name helm-rg--process-name
                      :buffer helm-rg--process-buffer-name
                      :command '("echo")
                      :noquery t))
         (input-repr
          (cond
           ((string= input "")
            "<empty string>")
           ((string-match-p helm-rg--all-whitespace-regexp input)
            "<whitespace>")
           (t input)))
         (helm-src-name
          (format "%s %s: %s"
                  (helm-rg--make-face 'helm-rg-error-message "no results for input")
                  (helm-rg--make-face 'font-lock-string-face input-repr)
                  (helm-rg--make-face 'helm-rg-error-message err-msg))))
    (helm-attrset 'name helm-src-name)
    dummy-proc))

(defun helm-rg--validate-or-make-dummy-process (input)
  (cond
   ((< (length input) helm-rg-input-min-search-chars)
    (helm-rg--make-dummy-process
     input
     (format "must be at least %d characters" helm-rg-input-min-search-chars)))
   (t t)))

(defun helm-rg--join (sep seq)
  (mapconcat #'identity seq sep))

(defun helm-rg--props (props str)
  (apply #'propertize (append (list str) props)))

(defun helm-rg--make-face (face str)
  (helm-rg--props `(face ,face) str))

(defun helm-rg--process-paths-to-search (paths)
  (cl-check-type helm-rg--current-dir helm-rg-existing-directory)
  (cl-loop
   for path in paths
   for expanded = (expand-file-name path helm-rg--current-dir)
   unless (file-exists-p expanded)
   do (error (concat "Error: expanded path '%s' does not exist. "
                     "The cwd was '%s', and the paths provided were %S.")
             expanded
             helm-rg--current-dir
             paths)
   ;; TODO: a `pcase-defmacro' or `pcase' wrapper which checks that all possible cases of a
   ;; `helm-rg--defcustom-from-alist' are enumerated at compile time!
   ;; TODO: `helm-resume' currently fails on resume in the 'relative case.
   collect (pcase-exhaustive helm-rg-file-paths-in-matches-behavior
             (`relative (file-relative-name expanded helm-rg--current-dir))
             (`absolute expanded))))

(defun helm-rg--empty-glob-p (glob-str)
  (or (null glob-str)
      (string-blank-p glob-str)))

(defun helm-rg--construct-argv (pattern)
  "Create an argument list from the `helm-pattern' PATTERN for the ripgrep command.

This argument list is propertized for display in the `helm-buffer' header when using `helm-rg', and
is used directly to invoke ripgrep. It uses `defcustom' values, and `defvar' values bound in other
functions."
  ;; TODO: document these pcase deconstructions in the docstring for
  ;; `helm-rg--ripgrep-argv-format-alist'!
  (cl-loop
   for el in helm-rg--ripgrep-argv-format-alist
   append (pcase-exhaustive el
            (`(,(or (and `it (let expr pattern)) expr) :face ,face-sym)
             (pcase-exhaustive (eval expr)
               ((and (pred listp) args)
                (--map (helm-rg--make-face face-sym it) args))
               (arg
                (list (helm-rg--make-face face-sym arg))))))))

(defun helm-rg--make-process-from-argv (argv)
  (let* ((real-proc (make-process
                     :name helm-rg--process-name
                     :buffer helm-rg--process-buffer-name
                     :command argv
                     :noquery t))
         (helm-src-name
          (format "argv: %s" (helm-rg--join " " argv))))
    (helm-attrset 'name helm-src-name)
    (set-process-query-on-exit-flag real-proc nil)
    real-proc))

(defun helm-rg--make-process ()
  "Invoke ripgrep in `helm-rg--current-dir' with `helm-pattern'.
Make a dummy process if the input is empty with a clear message to the user."
  (let* ((default-directory helm-rg--current-dir)
         (input helm-pattern))
    (pcase-exhaustive (helm-rg--validate-or-make-dummy-process input)
      ((and (pred processp) x)
       (setq helm-rg--last-argv nil)
       x)
      (`t
       (let* ((rg-regexp (helm-rg--helm-pattern-to-ripgrep-regexp input))
              (argv (helm-rg--construct-argv rg-regexp))
              (real-proc (helm-rg--make-process-from-argv argv)))
         (setq helm-rg--last-argv argv)
         real-proc)))))

(defun helm-rg--make-overlay-with-face (beg end face)
  "Generate an overlay in region BEG to END with face FACE."
  (let ((olay (make-overlay beg end)))
    (overlay-put olay 'face face)
    olay))

(defun helm-rg--delete-match-overlays ()
  "Delete all cached overlays in `helm-rg--matches-in-current-file-overlays', and clear it."
  (mapc #'delete-overlay helm-rg--matches-in-current-file-overlays)
  (setq helm-rg--matches-in-current-file-overlays nil))

(defun helm-rg--delete-line-overlay ()
  "Delete the cached overlay `helm-rg--current-line-overlay', if it exists, and clear it."
  (helm-rg--get-optional-typed overlay helm-rg--current-line-overlay
    (delete-overlay it))
  (setq helm-rg--current-line-overlay nil))

(defun helm-rg--collect-lines-matches-current-file (orig-line-parsed)
  "Collect all of the matched text regions from ripgrep's highlighted output from ORIG-LINE-PARSED."
  ;; If we are on a file's line, stay where we are, otherwise back up to the closest file line above
  ;; the current line (this is the file that "owns" the entry).
  (cl-destructuring-bind (&key
                          ((:file orig-file))
                          ((:line-num _orig-line-num))
                          ((:match-results _orig-match-results)))
      orig-line-parsed
    ;; Collect all the results on all matching lines of the file.
    (with-helm-window
      (helm-rg--file-backward t)
      (let ((all-match-results nil))
        ;; Process the first line (`helm-rg--iterate-results' will advance
        ;; past the initial element).
        (cl-destructuring-bind (&key _file line-num match-results) (helm-rg--current-jump-location)
          (when (and line-num match-results)
            (push (list :match-line-num line-num
                        :line-match-results match-results)
                  all-match-results)))
        (helm-rg--iterate-results
         'forward
         :success-fn (lambda (cur-line-parsed)
                       (cl-destructuring-bind (&key file line-num match-results)
                           cur-line-parsed
                         (cl-check-type orig-file string)
                         (cl-check-type file string)
                         (if (not (string= orig-file file))
                             ;; We have reached the results from a different file, so done.
                             t
                           (progn
                             ;; In filename lines, these are nil.
                             (when (and line-num match-results)
                               (push (list :match-line-num line-num
                                           :line-match-results match-results)
                                     all-match-results))
                             ;; We loop forever if there's only one file in
                             ;; the results unless we return this as success.
                             (helm-end-of-source-p)))))
         :failure-fn (lambda (cur-line-parsed)
                       (helm-rg--different-file-line orig-line-parsed cur-line-parsed)))
        (helm-rg--iterate-results
         'backward
         :success-fn (lambda (cur-line-parsed)
                       (helm-rg--on-same-entry orig-line-parsed cur-line-parsed))
         :failure-fn #'ignore)
        (reverse all-match-results)))))

(defun helm-rg--convert-lines-matches-to-overlays (line-match-results)
  (beginning-of-line)
  (--map (cl-destructuring-bind (&key beg end) it
           (helm-rg--make-overlay-with-face
            (+ (point) beg) (+ (point) end)
            'helm-rg-match-text-face))
         line-match-results))

(defun helm-rg--make-match-overlays-for-result (cur-file-matches)
  (save-excursion
    (goto-char (point-min))
    (cl-loop
     with cur-line = 1
     for line-match-set in cur-file-matches
     append (cl-destructuring-bind (&key match-line-num line-match-results)
                line-match-set
              (let ((lines-diff (- match-line-num cur-line)))
                (cl-assert (>= lines-diff 0))
                (forward-line lines-diff)
                (cl-incf cur-line lines-diff)
                (cl-assert (not (eobp)))
                (helm-rg--convert-lines-matches-to-overlays line-match-results))))))

(defun helm-rg--async-action (parsed-output &optional highlight-matches)
  "Visit the file at the line and column according to PARSED-OUTPUT.

The match is highlighted in its buffer if HIGHLIGHT-MATCHES is non-nil."
  (let ((default-directory helm-rg--current-dir)
        (helm-rg--display-buffer-method
         (or helm-rg--display-buffer-method
             ;; If a prefix arg is given for the async action or persistent action, use the
             ;; alternate buffer display method (which by default is `pop-to-buffer').
             (if helm-current-prefix-arg helm-rg-display-buffer-alternate-method
               helm-rg-display-buffer-normal-method))))
    ;; We always want to delete the line overlay if it exists, no matter what.
    (helm-rg--delete-line-overlay)
    (cl-destructuring-bind (&key file line-num match-results) parsed-output
      (let* ((file-abs-path (expand-file-name file))
             (buffer-to-display
              (or (when-let ((visiting-buf (find-buffer-visiting file-abs-path)))
                    ;; TODO: prompt to save the buffer if modified? something?
                    visiting-buf)
                  (let ((new-buf (find-file-noselect file-abs-path)))
                    (when helm-rg--append-persistent-buffers
                      (push new-buf helm-rg--cur-persistent-bufs))
                    new-buf)))
             (cur-file-matches
              ;; Clear the old matches and make new ones, if this is a different file than the last
              ;; one we visited in this session.
              (cond
               ;; We don't highlight any matches, probably because we are the async action and just
               ;; want to jump to a file location.
               ((not highlight-matches)
                nil)
               ;; If the file path matches `helm-rg-shallow-highlight-files-regexp', just
               ;; highlight the matches for the current line, if any. We need to do this again, even
               ;; if it is the same file, because the single line number to draw may change.
               ((and (stringp helm-rg-shallow-highlight-files-regexp)
                     (string-match-p helm-rg-shallow-highlight-files-regexp file-abs-path))
                ;; Delete the overlay for the previous line.
                (helm-rg--delete-match-overlays)
                (list (list :match-line-num line-num
                            :line-match-results match-results)))
               ;; This is the same buffer as last time, so do nothing.
               ((eq helm-rg--previously-highlighted-buffer buffer-to-display)
                nil)
               (t
                ;; This is a different buffer, so record that.
                (setq helm-rg--previously-highlighted-buffer buffer-to-display)
                ;; Clear the old lines (from the previous buffer) and make new ones.
                (helm-rg--delete-match-overlays)
                (helm-rg--collect-lines-matches-current-file parsed-output)))))
        ;; Display the buffer visiting the file with the matches.
        (funcall helm-rg--display-buffer-method buffer-to-display)
        ;; Make overlays highlighting all the matches (unless we are in the same file as
        ;; before, or highlight-matches is nil).
        (when cur-file-matches
          (setq helm-rg--matches-in-current-file-overlays
                (helm-rg--make-match-overlays-for-result cur-file-matches)))
        ;; Advance in the file to the given line.
        (goto-char (point-min))
        (helm-rg--get-optional-typed natnum line-num
          (forward-line (1- it)))
        ;; Make a line overlay, if requested.
        (when highlight-matches
          (let ((line-olay
                 (helm-rg--make-overlay-with-face (line-beginning-position) (line-end-position)
                                                  'helm-rg-preview-line-highlight)))
            (setq helm-rg--current-line-overlay line-olay)))
        ;; Move to the first match in the line (all lines have >= 1 match because ripgrep only
        ;; outputs matching lines).
        (let ((first-match-beginning (plist-get (car match-results) :beg)))
          (helm-rg--get-optional-typed natnum first-match-beginning
            (forward-char it)))
        (recenter)))))

(defun helm-rg--async-persistent-action (parsed-output)
  "Visit the file at the line and column specified by PARSED-OUTPUT.

Call `helm-rg--async-action', but push the buffer corresponding to PARSED-OUTPUT to
`helm-rg--matches-in-current-file-overlays', if there was no buffer visiting it already."
  (let ((helm-rg--append-persistent-buffers t)
        (helm-rg--display-buffer-method helm-rg--persistent-action-display-buffer-method))
    (helm-rg--async-action parsed-output t)))

(defun helm-rg--kill-proc-if-live (proc-name)
  "Delete the process named PROC-NAME, if it is alive."
  (let ((proc (get-process proc-name)))
    (when (process-live-p proc)
      (delete-process proc))))

(defun helm-rg--kill-bufs-if-live (&rest bufs)
  "Kill any live buffers in BUFS."
  (mapc
   (lambda (buf)
     (when (buffer-live-p (get-buffer buf))
       (kill-buffer buf)))
   bufs))

(defun helm-rg--unwind-cleanup ()
  "Reset all the temporary state in `defvar's in this package."
  (helm-rg--delete-match-overlays)
  (helm-rg--delete-line-overlay)
  (cl-loop
   for opened-buf in helm-rg--cur-persistent-bufs
   unless (eq (current-buffer) opened-buf)
   do (kill-buffer opened-buf)
   finally (setq helm-rg--cur-persistent-bufs nil))
  (helm-rg--kill-proc-if-live helm-rg--process-name)
  ;; Don't delete `helm-rg--helm-buffer-name' to support using e.g. `helm-resume'.
  ;; TODO: add testing for this use case.
  (helm-rg--kill-bufs-if-live helm-rg--process-buffer-name
                              helm-rg--error-buffer-name)
  (setq helm-rg--glob-string nil
        helm-rg--extra-args nil
        helm-rg--paths-to-search nil
        helm-rg--case-sensitivity nil
        helm-rg--previously-highlighted-buffer nil
        helm-rg--last-argv nil))

(defun helm-rg--do-helm-rg (rg-pattern)
  "Invoke ripgrep to search for RG-PATTERN, using `helm'."
  (helm :sources '(helm-rg-process-source)
        :buffer helm-rg--helm-buffer-name
        :input rg-pattern
        :prompt "rg pattern: "))

(defun helm-rg--get-thing-at-pt ()
  "Get the object surrounding point, or the empty string."
  (helm-aif (thing-at-point helm-rg-thing-at-point)
      (substring-no-properties it)
    ""))

(defun helm-rg--header-name (src-name)
  (format "%s %s @ %s"
          (helm-rg--make-face 'helm-rg-title-face "rg")
          src-name
          (helm-rg--make-face 'helm-rg-directory-header-face helm-rg--current-dir)))

(defun helm-rg--current-jump-location (&optional object)
  (get-text-property (line-beginning-position) helm-rg--jump-location-text-property object))

(defun helm-rg--get-jump-location-from-line (line)
  "Get the value of `helm-rg--jump-location-text-property' at the start of LINE."
  ;; When there is an empty pattern, the argument can be nil due to the way helm handles our dummy
  ;; process. There may be a way to avoid having to do this check.
  (when line
    (get-text-property 0 helm-rg--jump-location-text-property line)))

(defun helm-rg--display-to-real (_)
  "Extract the information from the process filter stored in the current entry's text properties.

Note that this doesn't use the argument at all. I don't think you can get the currently selected
line without the text properties scrubbed using helm without doing this."
  (helm-rg--get-jump-location-from-line (helm-get-selection nil 'withprop)))

(defun helm-rg--collect-matches (regexp)
  (cl-loop while (re-search-forward regexp nil t)
           collect (match-string 1)))

(defun helm-rg--helm-pattern-to-ripgrep-regexp (pattern)
  "Transform PATTERN (the `helm-input') into a Perl-compatible regular expression.

TODO: add ert testing for this function!"
  ;; For example: "a  b c" => "a b.*c|c.*a b".
  (->>
   ;; Split the pattern into our definition of "components". Suppose PATTERN is "a  b c". Then:
   ;; "a  b c" => '("a  b" "c")
   (helm-rg--into-temp-buffer pattern
     (helm-rg--collect-matches helm-rg--loop-input-pattern-regexp))
   ;; Two spaces in a row becomes a single space in the output regexp. Each component is now a
   ;; regexp.
   ;; '("a  b" "c") => '("a b" "c")
   (--map (replace-regexp-in-string (rx (= 2 ? )) " " it))
   ;; All permutations of all component regexps.
   ;; '("a b" "c") => '(("a b" "c") ("c" "a b"))
   (-permutations)
   ;; Each permutation is converted into a regexp which matches a line containing each regexp in
   ;; the permutation in order, each separated by 0 or more non-newline characters.
   ;; '(("a b" "c") ("c" "a b")) => '("a  b.*c" "c.*a  b")
   (--map (helm-rg--join ".*" it))
   ;; Return a regexp which matches any of the resulting regexps.
   ;; '("a  b.*c" "c.*a  b") => "a b.*c|c.*a b"
   (helm-rg--join "|")))

(defun helm-rg--advance-forward ()
  "Move forward a line in the results, cycling if necessary."
  (interactive)
  (let ((helm-move-to-line-cycle-in-source t))
    (if (helm-end-of-source-p)
        (helm-beginning-of-buffer)
      (helm-next-line))))

(defun helm-rg--advance-backward ()
  "Move backward a line in the results, cycling if necessary."
  (interactive)
  (let ((helm-move-to-line-cycle-in-source t))
    (if (helm-beginning-of-source-p)
        (helm-end-of-buffer)
      (helm-previous-line))))

(define-error 'helm-rg--helm-buffer-iteration-error
  "Iterating over ripgrep match results in the helm buffer failed."
  'helm-rg-error)

(cl-defun helm-rg--iterate-results (direction &key success-fn failure-fn)
  (with-helm-buffer
    (let ((move-fn
           (pcase-exhaustive direction
             (`forward #'helm-rg--advance-forward)
             (`backward #'helm-rg--advance-backward))))
      (call-interactively move-fn)
      (cl-loop
       for cur-line-parsed = (helm-rg--current-jump-location)
       until (funcall success-fn cur-line-parsed)
       if (funcall failure-fn cur-line-parsed)
       return (signal 'helm-rg--helm-buffer-iteration-error "could not cycle to the next entry")
       else do (call-interactively move-fn)))))

(defun helm-rg--current-line-contents ()
  "`helm-current-line-contents' doesn't keep text properties."
  (buffer-substring (point-at-bol) (point-at-eol)))

(cl-defun helm-rg--nullable-states-different (a b &key (cmp #'eq))
  "Compare A and B respecting nullability using CMP.

When CMP is `string=', the following results:
(A=nil, B=nil) => nil
(A=\"a\", B=nil) => t
(A=nil, B=\"a\") => t
(A=\"a\", B=\"a\") => nil
(A=\"a\", B=\"b\") => t

TODO: throw the above into an ert test!"
  (if a
      (not (and b (funcall cmp a b)))
    b))

(defun helm-rg--on-same-entry (orig-line-parsed cur-line-parsed)
  (cl-destructuring-bind (&key ((:file orig-file)) ((:line-num orig-line-num)) ((:match-results _)))
      orig-line-parsed
    (cl-check-type orig-file string)
    (cl-destructuring-bind (&key ((:file cur-file)) ((:line-num cur-line-num)) ((:match-results _)))
        cur-line-parsed
      (cl-check-type cur-file string)
      (and (string= orig-file cur-file)
           (not (helm-rg--nullable-states-different orig-line-num cur-line-num :cmp #'=))))))

(defun helm-rg--different-file-line (orig-line-parsed cur-line-parsed)
  (cl-destructuring-bind (&key ((:file orig-file)) ((:line-num _)) ((:match-results _)))
      orig-line-parsed
    (cl-check-type orig-file string)
    (cl-destructuring-bind (&key ((:file cur-file)) ((:line-num _)) ((:match-results _)))
        cur-line-parsed
      (cl-check-type cur-file string)
      (not (string= orig-file cur-file)))))

(defun helm-rg--move-file (direction)
  "Move through matching lines from ripgrep in the given DIRECTION.

This will loop around the results when advancing past the beginning or end of the results."
  (with-helm-buffer
    (let* ((orig-line-parsed (helm-rg--current-jump-location)))
      (helm-rg--iterate-results
       direction
       :success-fn (lambda (cur-line-parsed)
                     (helm-rg--different-file-line orig-line-parsed cur-line-parsed))
       :failure-fn (lambda (cur-line-parsed)
                     (helm-rg--on-same-entry orig-line-parsed cur-line-parsed))))))

(defun helm-rg--file-forward ()
  "Move forward to the beginning of the next file in the output, cycling if necessary."
  (interactive)
  (condition-case _err
      (helm-rg--move-file 'forward)
    (helm-rg--helm-buffer-iteration-error
     (with-helm-window (helm-end-of-buffer)))))

(defun helm-rg--do-file-backward-dwim (stay-if-at-top-of-file)
  (with-helm-window
    (let ((orig-line-parsed (helm-rg--current-jump-location)))
      (helm-rg--advance-backward)
      (let* ((before-line-parsed (helm-rg--current-jump-location))
             (at-top-of-file-p (helm-rg--different-file-line orig-line-parsed before-line-parsed)))
        (unless (and at-top-of-file-p (not stay-if-at-top-of-file))
          (helm-rg--advance-forward))
        (helm-rg--move-file 'backward))
      ;; `helm-rg--move-file' gets us one before the line we actually want when going backwards.
      (helm-rg--advance-forward))))

(defun helm-rg--file-backward (stay-if-at-top-of-file)
  "Move backward to the beginning of the previous file in the output, cycling if necessary.

STAY-IF-AT-TOP-OF-FILE determines whether to move to the previous file if point is at the top of a
file in the output."
  (interactive (list nil))
  (condition-case _err
      (helm-rg--do-file-backward-dwim stay-if-at-top-of-file)
    (helm-rg--helm-buffer-iteration-error
     (with-helm-window (helm-beginning-of-buffer)))))

(defconst helm--whitespace-trim-rx-expr
  '(| (: bos (+ whitespace)) (: (+ whitespace) eos)))

(defun helm-rg--trim-whitespace (str)
  (-> (rx-to-string helm--whitespace-trim-rx-expr)
      (replace-regexp-in-string "" str)))

(defun helm-rg--process-output (exe &rest args)
  "Get output from a process EXE with string arguments ARGS.

Merges stdout and stderr, and trims whitespace from the result."
  (with-temp-buffer
    (let ((proc (make-process
                 :name "temp-proc"
                 :buffer (current-buffer)
                 :command `(,exe ,@args)
                 :sentinel #'ignore)))
      (while (accept-process-output proc nil nil t)))
    (helm-rg--trim-whitespace (buffer-string))))

(defun helm-rg--check-directory-path (path)
  (if (and path (file-directory-p path)) path
    (error "Path '%S' was not a directory" path)))

(defun helm-rg--make-help-buffer (help-buf-name)
  ;; FIXME: this could be more useful -- but also, is it going to matter to anyone but the
  ;; developer?
  (with-current-buffer (get-buffer-create help-buf-name)
    (read-only-mode -1)
    (erase-buffer)
    (fundamental-mode)
    (insert (helm-rg--process-output helm-rg-ripgrep-executable "--help"))
    (goto-char (point-min))
    (read-only-mode 1)
    (current-buffer)))

(defun helm-rg--lookup-default-alist (alist elt)
  (if elt
      (helm-rg--alist-get-exhaustive elt alist)
    (cdar alist)))

(defun helm-rg--lookup-color (&optional color)
  (helm-rg--lookup-default-alist helm-rg--color-format-argument-alist color))

(defun helm-rg--lookup-style (&optional style)
  (helm-rg--lookup-default-alist helm-rg--style-format-argument-alist style))

(defun helm-rg--construct-match-color-format-arguments ()
  (list
   (format "--colors=match:fg:%s"
           (plist-get (helm-rg--lookup-color) :cmd-line))
   (format "--colors=match:style:%s"
           (plist-get (helm-rg--lookup-style) :cmd-line))))

(defun helm-rg--construct-match-text-properties ()
  (cl-destructuring-bind (&key ((:text-property style-text-property)) ((:cmd-line _)))
      (helm-rg--lookup-style)
    (cl-destructuring-bind (&key ((:text-property color-text-property)) ((:cmd-line _)))
        (helm-rg--lookup-color)
      `(,style-text-property
        (foreground-color . ,color-text-property)))))

(defun helm-rg--is-match (position object)
  (let ((text-props-for-position (get-text-property position 'font-lock-face object))
        (text-props-for-match (helm-rg--construct-match-text-properties)))
    (equal text-props-for-position text-props-for-match)))

(defun helm-rg--first-match-start-ripgrep-output (position match-line &optional find-end)
  (cl-loop
   with line-char-index = position
   for is-match-p = (helm-rg--is-match line-char-index match-line)
   until (if find-end (not is-match-p) is-match-p)
   for next-chg = (next-single-property-change line-char-index 'font-lock-face match-line)
   if next-chg do (setq line-char-index next-chg)
   else return (if find-end
                   ;; char at end of line is end of match
                   (length match-line)
                 nil)
   finally return line-char-index))

(defun helm-rg--parse-propertize-match-regions-from-match-line (match-line)
  (cl-loop
   with line-char-index = 0
   for match-beg = (helm-rg--first-match-start-ripgrep-output line-char-index match-line)
   unless match-beg
   return (list :propertized-line (concat cur-match-str
                                          (substring match-line match-end))
                :match-regions match-regions)
   concat (substring match-line match-end match-beg)
   into cur-match-str
   for match-end = (helm-rg--first-match-start-ripgrep-output match-beg match-line t)
   collect (list :beg match-beg :end match-end)
   into match-regions
   do (setq line-char-index match-end)
   concat (--> match-line
               (substring it match-beg match-end)
               (helm-rg--make-face 'helm-rg-match-text-face it))
   into cur-match-str))

(cl-defun helm-rg--join-output-line (&key cur-file line-num-str propertized-line)
  (helm-rg--join (->> ":"
                      (helm-rg--make-face 'helm-rg-colon-separator-ripgrep-output-face))
                 `(,@(and cur-file (list cur-file))
                   ,(->> line-num-str
                         (helm-rg--make-face 'helm-rg-line-number-match-face))
                   ,propertized-line)))

(defun helm-rg--process-transition (cur-file line)
  (pcase-exhaustive line
    ;; When we see an empty line, we clear all the state.
    ((helm-rg-rx (: bos eos))
     (list :file-path nil))
    ;; When we see a line with a number and text, we must be collecting match lines from a
    ;; particular file right now. Parse the line and add "jump" information as text properties.
    ((and (helm-rg-rx (eval helm-rg--numbered-text-line-rx-expr))
          (let (helm-rg-&key-complete propertized-line match-regions)
            (helm-rg--parse-propertize-match-regions-from-match-line content)))
     (cl-check-type cur-file string)
     (helm-rg-mark-unused (content whole-line)
       (let* ((prefixed-line (helm-rg--join-output-line
                              :cur-file (and helm-rg-include-file-on-every-match-line cur-file)
                              :line-num-str line-num-str
                              :propertized-line propertized-line))
              (line-num (string-to-number line-num-str))
              (jump-to (list :file cur-file
                             :line-num line-num
                             :match-results match-regions))
              (output-line
               (propertize prefixed-line helm-rg--jump-location-text-property jump-to)))
         (list :file-path cur-file
               :line-content output-line))))
    ;; If we see a line with just a filename, we must have just finished the results from another
    ;; file. We update the state to the file parsed from this line, but we may not insert anything
    ;; into the output depending on the user's customizations.
    ((helm-rg-rx (eval helm-rg--output-new-file-line-rx-expr))
     ;; FIXME: why does this fail?
     ;; (cl-check-type cur-file null)
     (let* ((whole-line-effaced (helm-rg--make-face 'helm-rg-file-match-face whole-line))
            (file-path-effaced (helm-rg--make-face 'helm-rg-file-match-face file-path))
            (jump-to (list :file file-path-effaced))
            (output-line
             (propertize whole-line-effaced helm-rg--jump-location-text-property jump-to)))
       (append
        (list :file-path file-path-effaced)
        (and helm-rg-prepend-file-name-line-at-top-of-matches
             (list :line-content output-line)))))))

(defun helm-rg--maybe-get-line (content)
  (helm-rg--into-temp-buffer content
    (if (re-search-forward (rx (: (group (*? anything)) "\n")) nil t)
        (list :line (match-string 1)
              :rest (buffer-substring (point) (point-max)))
      (list :line nil
            :rest (buffer-string)))))

(defun helm-rg--parse-process-output (input-line)
  ;; TODO: document this function!
  (let* ((colored-line (ansi-color-apply input-line))
         (string-result
          (cl-destructuring-bind (&key cur-file) helm-rg--process-output-parse-state
            (-if-let* ((parsed (helm-rg--process-transition cur-file colored-line)))
                (cl-destructuring-bind (&key file-path line-content) parsed
                  (setq-local helm-rg--process-output-parse-state (list :cur-file file-path))
                  ;; Exits here.
                  (or line-content ""))
              (error "Line '%s' could not be parsed! state was: '%S'"
                     colored-line helm-rg--process-output-parse-state)))))
    string-result))


;; Bounce-mode specific functions (temporary, experimental)
(defun helm-rg--freeze-header-for-bounce (argv)
  (cl-assert (get-text-property (point-min) helm-rg--helm-header-property-name))
  ;; We want to keep the helm header with the argv for reference, but we don't want it to affect
  ;; any of the editing, so we make it read-only.
  (let ((helm-header-end
         (next-single-property-change (point-min) helm-rg--helm-header-property-name))
        (inhibit-read-only t))
    (delete-region (point-min) (1+ helm-header-end))
    (insert (format "%s\n" (helm-rg--join " " argv)))
    (let ((new-argv-end (point)))
      ;; This means insertion after the header (the first char of the buffer text) won't take on
      ;; the header's face.
      (put-text-property (point-min) new-argv-end 'rear-nonsticky '(face read-only))
      ;; This stops insertion before the header as well (the beginning of the buffer).
      (put-text-property (point-min) new-argv-end 'front-sticky '(face read-only))
      ;; Finally set everything to read-only.
      (put-text-property (point-min) new-argv-end 'read-only t))))

(defun helm-rg--maybe-insert-file-heading-for-bounce (cur-jump-loc)
  ;; TODO: insert the file line if it's not there (if
  ;; `helm-rg-prepend-file-name-line-at-top-of-matches' is nil)!
  ;; (i.e. check to make sure this function works)
  (let ((inhibit-read-only t)
        (pt (point)))
    ;; NB: the file line is NOT readonly!!! It can be used to modify the file names.
    (pcase-exhaustive cur-jump-loc
      ((helm-rg-&key line-num :required file)
       (cl-check-type file string)
       ;; FIXME: add some divider above each file line!!!
       (if (not line-num)
           ;; We already have an appropriate file heading. We assume all file entries are a single
           ;; line at this point, because the user has not started editing the buffer yet.
           (helm-rg--down-for-bounce)
         ;; We need to insert the file's line.
         ;; NB: we cut off the location entry to only the file, because we are
         ;; making a file header line.
         ;; TODO: make file header line creation into a factory method
         (let* ((file-entry-loc (list :file file))
                (propertized-file-entry-line
                 (propertize file helm-rg--jump-location-text-property file-entry-loc)))
           (insert (format "%s\n" propertized-file-entry-line))))))

    ;; TODO: ???
    (put-text-property pt (point) 'front-sticky `(face ,helm-rg--jump-location-text-property))))

(defun helm-rg--propertize-line-number-prefix-range (beg end)
  ;; Inserting text at the beginning is not allowed, except for the newline before this
  ;; entry.
  (put-text-property beg end 'front-sticky '(read-only))
  ;; Inserting text after this entry is allowed, and we don't want it to take the face of this
  ;; text.
  (put-text-property beg end 'rear-nonsticky '(face read-only))
  ;; Apply the read-only property.
  ;; FIXME: can we remove this (1-) here? Why is it here?
  (put-text-property (1- beg) end 'read-only t))

(defun helm-rg--format-match-line-for-bounce (jump-loc)
  (let ((inhibit-read-only t))
    (pcase-exhaustive jump-loc
      ((helm-rg-&key :required file line-num)
       ;; TODO: remove the file from the match line if it's there (if
       ;; `helm-rg-include-file-on-every-match-line' is non-nil)!
       ;; (i.e. just check to make sure this line works)
       (when (looking-at (rx-to-string `(: bol ,file ":")))
         (replace-match ""))
       ;; TODO: fix cl-destructuring-bind, and merge with pcase and regexp matching (allowing named
       ;; matches)!
       ;; We are looking at a line number.
       (cl-assert (looking-at (rx-to-string `(: bol (group-n 1 ,(number-to-string line-num)) ":"))))
       ;; Make the propertized line number text read-only.
       (let* ((matched-number-str (match-string 1))
              (matched-num (string-to-number matched-number-str)))
         ;; TODO: is this check necessary?
         (cl-assert (= matched-num line-num)))
       (helm-rg--propertize-line-number-prefix-range (match-beginning 0) (match-end 0)))))
  ;; We can use `forward-line' here, because we are building the bounce buffer (so there are no
  ;; multiline entries).
  (forward-line 1))

(defun helm-rg--propertize-match-line-from-file-for-bounce (line-to-propertize jump-loc)
  ;; Copy the input string, because we will be mutating it.
  (let ((resulting-line (cl-copy-seq line-to-propertize)))
    (pcase-exhaustive jump-loc
      ((helm-rg-&key :required match-results)
       ;; Apply face to matches within the text to insert.
       (cl-loop for match in match-results
                do (cl-destructuring-bind (&key beg end) match
                     (put-text-property beg end 'face 'helm-rg-match-text-face
                                        resulting-line)))
       ;; Apply the jump location to the text to insert.
       (put-text-property 0 (length resulting-line) helm-rg--jump-location-text-property jump-loc
                          resulting-line)
       resulting-line))))

(defun helm-rg--line-from-corresponding-file-for-bounce (scratch-buf)
  "Get the corresponding line in the file's buffer SCRATCH-BUF, and return it.

SCRATCH-BUF has already been advanced to the appropriate line."
  (with-current-buffer scratch-buf
    (let ((beg (line-beginning-position))
          (end (line-end-position)))
      (when helm-rg--do-font-locking
        (font-lock-ensure beg end))
      (buffer-substring beg end))))

(defun helm-rg--rewrite-propertized-match-line-from-file-for-bounce (scratch-buf jump-loc)
  (let* ((cur-line-in-file-to-propertize
          (helm-rg--line-from-corresponding-file-for-bounce scratch-buf))
         (line-to-insert
          (helm-rg--propertize-match-line-from-file-for-bounce
           cur-line-in-file-to-propertize jump-loc)))
    (delete-region (point) (line-end-position))
    (insert line-to-insert)))

(cl-defun helm-rg--insert-new-match-line-for-bounce (&key file line-to-insert line-contents)
  (let* ((output-line (helm-rg--join-output-line
                       :line-num-str (number-to-string line-to-insert)
                       :propertized-line line-contents))
         (inhibit-read-only t))
    (insert (format "%s\n" output-line))
    (helm-rg--up-for-bounce)
    (helm-rg--propertize-line-number-prefix-range
     (line-beginning-position) (point))
    (let ((new-entry-props (list :file file
                                 :line-num line-to-insert
                                 :match-results nil)))
      (put-text-property (line-beginning-position) (line-end-position)
                         helm-rg--jump-location-text-property new-entry-props)
      new-entry-props)))

(defun helm-rg--expand-match-lines-for-bounce (before after match-loc scratch-buf)
  (cl-destructuring-bind (&key ((:file orig-file))
                               ((:line-num orig-line-num))
                               ((:match-results _orig-match-results)))
      match-loc
    ;; Insert any "before" lines.
    (save-excursion
      (cl-loop
       for line-to-insert from (1- orig-line-num) downto (- orig-line-num before)
       do (helm-rg--up-for-bounce)
       for cur-loc = (helm-rg--current-jump-location)
       do (let ((cur-file (plist-get cur-loc :file))
                (cur-line-num (plist-get cur-loc :line-num)))
            (cl-assert (string= cur-file orig-file))
            ;; If it is not equal, and the lines are sorted, then the line we wish to insert must be
            ;; >= any line above, at all times (induction).
            ;; Checking for line-num means this will always insert after a file header (this file's
            ;; header).
            (with-current-buffer scratch-buf
              (forward-line -1))
            ;; Unless we are already on the correct line.
            (unless (and cur-line-num (= cur-line-num line-to-insert))
              (let ((cur-line-in-file
                     (helm-rg--line-from-corresponding-file-for-bounce scratch-buf)))
                ;; Our line is greater than this one. Insert ours after this line.
                (helm-rg--down-for-bounce)
                (helm-rg--insert-new-match-line-for-bounce
                 :file orig-file
                 :line-to-insert line-to-insert
                 :line-contents cur-line-in-file))))))
    (with-current-buffer scratch-buf
      (forward-line before))
    ;; Insert any "after" lines. We need a save-excursion because we need to start at the middle
    ;; here.
    (cl-loop
     for line-to-insert from (1+ orig-line-num) upto (+ orig-line-num after)
     do (helm-rg--down-for-bounce)
     for cur-loc = (helm-rg--current-jump-location)
     do (let ((cur-line-num (plist-get cur-loc :line-num)))
          (with-current-buffer scratch-buf
            (forward-line 1))
          ;; Checking for line-num means this will always insert before a file header (the next
          ;; file's header).
          (unless (and cur-line-num (= cur-line-num line-to-insert))
            (let ((cur-line-in-file
                   (helm-rg--line-from-corresponding-file-for-bounce scratch-buf)))
              ;; Our line is less than this one -- insert it above (no motion).
              (helm-rg--insert-new-match-line-for-bounce
               :file orig-file
               :line-to-insert line-to-insert
               :line-contents cur-line-in-file)))))))

(defun helm-rg--expand-match-context-for-bounce (before after)
  ;; TODO: allow doing this expansion on a file header line to expand from the top or bottom of a
  ;; file!
  (cl-check-type before natnum)
  (cl-check-type after natnum)
  (save-excursion
    (let ((cur-match-entry (helm-rg--current-jump-location)))
      (pcase-exhaustive cur-match-entry
        ((helm-rg-&key line-num :required file)
         (if (not line-num)
             ;; We are on a file header line.
             (message "the current line is a file: %s and currently cannot be expanded from." file)
           (helm-rg--apply-matches-with-file-for-bounce
            :match-line-visitor (lambda (scratch-buf match-loc)
                                  (helm-rg--expand-match-lines-for-bounce
                                   before after match-loc scratch-buf))
            ;; TODO: make the filter kwargs into a single object, or a single function.
            :filter-to-file file
            :filter-to-match cur-match-entry)))))))

(defun helm-rg--save-match-line-content-to-file-for-bounce
    (scratch-buf jump-loc maybe-new-file-name)
  ;; We are at the beginning of the match text.
  (let ((match-text
         ;; Insert the text without any of our coloration.
         (buffer-substring-no-properties (point) (line-end-position))))
    ;; This buffer has already been moved to the appropriate line.
    (with-current-buffer scratch-buf
      (delete-region (line-beginning-position) (line-end-position))
      (insert match-text))
    ;; If we have changed the file name, we need to rewrite the jump location for this line.
    (pcase-exhaustive jump-loc
      ((helm-rg-&key :required file)
       (unless (string= file maybe-new-file-name)
         (let ((new-props
                (helm-rg--copy-jump-location-and-override
                 jump-loc (list :file maybe-new-file-name)))
               (inhibit-read-only t))
           (put-text-property (line-beginning-position) (line-end-position)
                              helm-rg--jump-location-text-property new-props)))))))

(cl-defun helm-rg--iterate-match-entries-for-bounce (&key file-visitor match-visitor end-of-file-fn)
  (goto-char helm-rg--beginning-of-bounce-content-mark)
  (cl-loop
   while (not (eobp))
   for file-header-loc = (helm-rg--current-jump-location)
   for cur-file = (plist-get file-header-loc :file)
   do (funcall file-visitor file-header-loc)
   do (cl-loop
       for match-loc = (helm-rg--current-jump-location)
       for match-file = (plist-get match-loc :file)
       while (string= cur-file match-file)
       do (funcall match-visitor match-loc))
   if end-of-file-fn
   do (funcall end-of-file-fn file-header-loc)))

(defun helm-rg--process-line-numbered-matches-for-bounce ()
  (helm-rg--iterate-match-entries-for-bounce
   :file-visitor (lambda (file-header-loc)
                   (helm-rg--maybe-insert-file-heading-for-bounce file-header-loc))
   :match-visitor (lambda (match-loc)
                    (helm-rg--format-match-line-for-bounce match-loc))))

(defun helm-rg--insert-colorized-file-contents-for-bounce (scratch-buf file-header-loc)
  (cl-destructuring-bind (&key file) file-header-loc
    (with-current-buffer scratch-buf
      (insert-file-contents file t nil nil t)
      ;; Don't apply e.g. syntax highlighting if e.g. this file is very large (according to
      ;; `helm-rg-shallow-highlight-files-regexp').
      (unless (and helm-rg-shallow-highlight-files-regexp
                   (string-match-p helm-rg-shallow-highlight-files-regexp file))
        (normal-mode)
        (font-lock-mode 1)
        (setq-local helm-rg--do-font-locking t))
      (goto-char (point-min)))))

(defun helm-rg--file-equals (file1 file2)
  (string= file1 file2))

(defun helm-rg--match-entry-equals (entry1 entry2)
  (equal entry1 entry2))

(defun helm-rg--make-line-number-prefix-regexp-for-bounce (line-num)
  (rx-to-string `(: bol ,(number-to-string line-num) ":")))

(define-error 'helm-rg--bounce-mode-iteration-error
  "Iterating over files in bounce mode failed."
  'helm-rg-error)

(cl-defun helm-rg--apply-matches-with-file-for-bounce
    (&key file-header-line-visitor match-line-visitor finalize-file-buffer-fn
          filter-to-file filter-to-match)
  (cl-check-type match-line-visitor function)
  (let ((did-find-matching-entry-p nil)
        is-matching-file-p
        cur-line)
    (helm-rg--with-named-temp-buffer scratch-buf
      (helm-rg--iterate-match-entries-for-bounce
       :file-visitor (lambda (file-header-loc)
                       (cl-destructuring-bind (&key file) file-header-loc
                         (setq is-matching-file-p
                               (if filter-to-file
                                   (helm-rg--file-equals file filter-to-file)
                                 t)))
                       (setq cur-line 1)
                       (helm-rg--insert-colorized-file-contents-for-bounce
                        scratch-buf file-header-loc)
                       (when (and file-header-line-visitor is-matching-file-p)
                         (funcall file-header-line-visitor file-header-loc))
                       (helm-rg--down-for-bounce))
       :match-visitor (lambda (match-loc)
                        (pcase-exhaustive match-loc
                          ((helm-rg-&key :required line-num)
                           (re-search-forward
                            (helm-rg--make-line-number-prefix-regexp-for-bounce line-num))
                           (let ((line-diff (- line-num cur-line)))
                             (cl-assert (or (and (= cur-line 1)
                                                 (= line-num 1))
                                            (> line-diff 0)))
                             (with-current-buffer scratch-buf
                               (forward-line line-diff))
                             (when (and is-matching-file-p
                                        (if filter-to-match
                                            (helm-rg--match-entry-equals filter-to-match match-loc)
                                          t))
                               (setq did-find-matching-entry-p t)
                               (funcall match-line-visitor scratch-buf match-loc))
                             ;; Update the line number in the scratch buffer to the one from this
                             ;; match line.
                             (setq cur-line line-num)
                             (helm-rg--down-for-bounce)))))
       :end-of-file-fn (when finalize-file-buffer-fn
                         (lambda (file-header-loc)
                           (when is-matching-file-p
                             (funcall finalize-file-buffer-fn file-header-loc scratch-buf))))))
    ;; FIXME: fix the error message here
    (unless did-find-matching-entry-p
      (signal 'helm-rg--bounce-mode-iteration-error
              (format "no entries matched the filter objects: %S, %S"
                      filter-to-file filter-to-match)))))

(defun helm-rg--copy-jump-location-and-override (old-loc new-loc)
  (cl-destructuring-bind (&key file line-num match-results) old-loc
    (cl-destructuring-bind (&key ((:file new-file))
                                 ((:line-num new-line-num))
                                 ((:match-results new-match-results)))
        new-loc
      `(:file ,(or new-file file)
        ,@(helm-rg--get-optional-typed natnum (or new-line-num line-num)
            `(:line-num ,it))
        ,@(helm-rg--get-optional-typed list (or new-match-results match-results)
            `(:match-results ,it))))))

(defun helm-rg--rewrite-file-header-line-for-bounce (file-header-loc)
  (cl-destructuring-bind (&key file) file-header-loc
    (let ((inhibit-read-only t))
      (delete-region (point) (line-end-position))
      (insert file)
      (put-text-property (line-beginning-position) (line-end-position)
                         helm-rg--jump-location-text-property file-header-loc))))

(defun helm-rg--reread-entries-from-file-for-bounce (just-this-file-p)
  (let ((filter-to-file-name (when just-this-file-p
                               (pcase-exhaustive (helm-rg--current-jump-location)
                                 ((helm-rg-&key :required file)
                                  file)))))
    (helm-rg--apply-matches-with-file-for-bounce
     :file-header-line-visitor #'helm-rg--rewrite-file-header-line-for-bounce
     :match-line-visitor #'helm-rg--rewrite-propertized-match-line-from-file-for-bounce
     :filter-to-file filter-to-file-name)))

(defun helm-rg--validate-file-name-change-and-propertize-for-bounce (_orig-file-name)
  ;; TODO: do some validation (???)
  (let* ((new-file-name-maybe (buffer-substring (point) (line-end-position)))
         (inhibit-read-only t))
    ;; Rewrite the :file jump location text property with the new file name.
    (put-text-property (point) (line-end-position)
                       helm-rg--jump-location-text-property (list :file new-file-name-maybe))
    new-file-name-maybe))

(defun helm-rg--up-for-bounce ()
  (forward-line -1)
  (beginning-of-line))

(defun helm-rg--down-for-bounce ()
  (forward-line 1)
  (beginning-of-line))

(defun helm-rg--do-file-rename-for-bounce (scratch-buf orig-file new-file)
  (with-current-buffer scratch-buf
    (let ((prev-scratch-buf-name (buffer-name)))
      (write-file new-file t)
      (erase-buffer)
      (set-visited-file-name nil t)
      (rename-buffer prev-scratch-buf-name)))
  ;; if any buffer visiting, switch to the new file!
  (cl-loop for buf in (helm-file-buffers orig-file)
           do (with-current-buffer buf
                (set-visited-file-name new-file t t)
                ;; Confirm reverting the buffer.
                (revert-buffer nil nil t)))
  ;; Move the original file into the trash.
  (move-file-to-trash orig-file))

(defun helm-rg--save-entries-to-file-for-bounce (just-this-file-p)
  (let ((filter-to-file-name (when just-this-file-p
                               (pcase-exhaustive (helm-rg--current-jump-location)
                                 ((helm-rg-&key :required file)
                                  file))))
        ;; The content of the file header -- if it is different, we rename the file.
        maybe-new-file-name)
    (helm-rg--apply-matches-with-file-for-bounce
     :file-header-line-visitor
     (lambda (file-header-loc)
       (pcase-exhaustive file-header-loc
         ((helm-rg-&key :required file)
          (setq maybe-new-file-name
                (helm-rg--validate-file-name-change-and-propertize-for-bounce file)))))
     :match-line-visitor (lambda (scratch-buf jump-loc)
                           (helm-rg--save-match-line-content-to-file-for-bounce
                            scratch-buf jump-loc maybe-new-file-name))
     :finalize-file-buffer-fn (lambda (file-header-loc scratch-buf)
                                (cl-destructuring-bind (&key ((:file orig-file))) file-header-loc
                                  (if (string= orig-file maybe-new-file-name)
                                      (with-current-buffer scratch-buf
                                        ;; Commit our edits to the various lines of this file to
                                        ;; disk.
                                        (save-buffer))
                                    (helm-rg--do-file-rename-for-bounce
                                     scratch-buf orig-file maybe-new-file-name))))
     :filter-to-file filter-to-file-name)))

(defun helm-rg--make-buffer-for-bounce ()
  ;; Make a new buffer instead of assuming you'll only want one session at a time. This will become
  ;; especially useful when live editing is introduced.
  (let ((new-buf (--> helm-rg--bounce-buffer-name
                      (format "%s: '%s' @ %s" it helm-pattern helm-rg--current-dir)
                      (generate-new-buffer it))))
    (with-helm-buffer
      (copy-to-buffer new-buf (point-min) (point-max)))
    (with-current-buffer new-buf
      ;; TODO: add test to ensure we are in the same directory!
      (cd helm-rg--current-dir)
      (helm-rg--bounce-mode)
      ;; Fix up, then advance past the end of the header.
      (helm-rg--freeze-header-for-bounce helm-rg--last-argv)
      (setq-local helm-rg--beginning-of-bounce-content-mark
                  (-> (make-marker) (set-marker (point))))
      (save-excursion
        (helm-rg--process-line-numbered-matches-for-bounce)
        ;; TODO: remove the final newline somehow, but don't break the ability to add newlines!
        (cl-assert (and (eobp) (bolp) (eolp))))
      (set-buffer-modified-p nil))
    new-buf))

(defun helm-rg--bounce ()
  "Enter into `helm-rg--bounce-mode' in a new buffer from the results for `helm-rg'."
  (interactive)
  (let ((new-buf (helm-rg--make-buffer-for-bounce)))
    (helm-rg--run-after-exit
     (funcall helm-rg-display-buffer-normal-method new-buf))))

(defun helm-rg--bounce-refresh ()
  "Revert all the contents in the bounce mode buffer to what they were in the file."
  (interactive)
  ;; TODO: fix prompts
  (if (and (buffer-modified-p)
           (not (y-or-n-p "Changes found. lose changes and overwrite anyway? ")))
      (message "%s" "No changes were made")
    (message "%s" "Reading file contents... ")
    (save-excursion
      (helm-rg--reread-entries-from-file-for-bounce nil))
    (set-buffer-modified-p nil)))

(defun helm-rg--bounce-refresh-current-file ()
  "Revert just the contents of the current file in the bounce mode buffer."
  (interactive)
  ;; TODO: add messaging!
  ;; FIXME: add some indicator of whether the current file contents have been modified, not just
  ;; everything in the bounce buffer!
  (save-excursion
    (helm-rg--reread-entries-from-file-for-bounce t)))

(defun helm-rg--bounce-dump ()
  "Save the contents of all the files in the bounce mode buffer."
  (interactive)
  (if (not (buffer-modified-p))
      (message "%s" "no changes to save!")
    (message "%s" "saving file contents...")
    (save-excursion
      (helm-rg--save-entries-to-file-for-bounce nil))
    (set-buffer-modified-p nil)))

(defun helm-rg--bounce-dump-current-file ()
  "Save just the content of the current file in the bounce mode buffer."
  (interactive)
  ;; TODO: add messaging!
  (save-excursion
    (helm-rg--save-entries-to-file-for-bounce t)))

(defun helm-rg--spread-match-context (signed-amount)
  "Read the contents of the current line and SIGNED-AMOUNT lines above or below from the file."
  (interactive "p")
  ;; TODO: add useful messaging!
  (cond
   ((zerop signed-amount))
   ((> signed-amount 0)
    (helm-rg--expand-match-context-for-bounce 0 signed-amount))
   (t
    (cl-assert (< signed-amount 0))
    (helm-rg--expand-match-context-for-bounce (abs signed-amount) 0))))

(defun helm-rg--expand-match-context (unsigned-amount)
  "Read the contents of the current line and UNSIGNED-AMOUNT lines above and below from the file."
  (interactive (list (if (numberp current-prefix-arg) (abs current-prefix-arg)
                       helm-rg--default-expand-match-lines-for-bounce)))
  ;; TODO: add useful messaging!
  (helm-rg--expand-match-context-for-bounce unsigned-amount unsigned-amount))

(defun helm-rg--visit-current-file-for-bounce ()
  "Jump to the current line of the current file where point is at in bounce mode."
  (interactive)
  ;; TODO: add useful messaging!
  ;; TODO: visit the right line number too!!! (if on a match line)
  (save-excursion
    (pcase-exhaustive (helm-rg--current-jump-location)
      ((helm-rg-&key line-num :required file)
       (let ((buf-for-file (find-file-noselect file)))
         ;; We could have a separate defcustom for this, but I think that's a setting nobody will
         ;; want to tweak, and if they do, they can override it very easily by making an interactive
         ;; method and let-binding `helm-rg-display-buffer-alternate-method' before calling this
         ;; one.
         (funcall helm-rg-display-buffer-alternate-method buf-for-file)
         (when line-num
           (goto-char (point-min))
           (forward-line (1- line-num)))
         (recenter))))))


;; Toggles and settings
(defmacro helm-rg--run-after-exit (&rest body)
  "Wrap BODY in `helm-run-after-exit'."
  `(helm-run-after-exit (lambda () ,@body)))

(defmacro helm-rg--set-setting-and-restart (bind-var expr)
  "Save `helm-rg' variables, then set the given BIND-VAR to EXPR, then restart search."
  (declare (indent 1))
  `(let* ((pat helm-pattern)
          (start-dir helm-rg--current-dir))
     (helm-rg--run-after-exit
      (let ((helm-rg--current-dir start-dir)
            (,bind-var ,expr))
        (helm-rg--do-helm-rg pat)))))

(defun helm-rg--set-glob (glob-str)
  "Set the glob string used to invoke ripgrep, then search again."
  ;; NB: The single argument GLOB-STR is for testability' -- we need to call `read-string' within the
  ;; body of `helm-rg--set-setting-and-restart' to avoid a recursive edit.
  (interactive (list nil))
  (helm-rg--set-setting-and-restart helm-rg--glob-string
    (or glob-str
        (read-string
         "rg glob: " helm-rg--glob-string 'helm-rg--glob-string-history))))

(defun helm-rg--set-extra-args (arg-str)
  "Set any extra arguments to ripgrep, then search again.

NOTE: this method is only able to parse double quotes -- single-quoted strings with spaces in them
will be split!"
  ;; TODO: find a package or implement real shell quoting for this!
  (interactive (list nil))
  (helm-rg--set-setting-and-restart helm-rg--extra-args
    (split-string-and-unquote
     (or arg-str
         (read-string
          "rg extra args: " helm-rg--extra-args 'helm-rg--extra-args-history)))))

(defun helm-rg--set-dir ()
  "Set the directory in which to invoke ripgrep and search again."
  (interactive)
  (let ((pat helm-pattern))
    (helm-rg--run-after-exit
     (let ((helm-rg--current-dir
            (read-directory-name "rg directory: " helm-rg--current-dir nil t)))
       (helm-rg--do-helm-rg pat)))))

(defun helm-rg--is-executable-file (path)
  (and path
       (file-executable-p path)
       (not (file-directory-p path))))

(defun helm-rg--get-git-root ()
  (if (helm-rg--is-executable-file helm-rg-git-executable)
      (helm-rg--process-output helm-rg-git-executable
                               "rev-parse" "--show-toplevel")
    (error "The defvar helm-rg-git-executable is not an executable file (was: %S)"
           helm-rg-git-executable)))

(defun helm-rg--interpret-starting-dir (default-directory-spec)
  (pcase-exhaustive default-directory-spec
    ('default default-directory)
    ('git-root (helm-rg--get-git-root))
    ;; TODO: add a test for this function for all values of the directory spec (see #5)!
    ((pred stringp) (helm-rg--check-directory-path default-directory-spec))))

(defun helm-rg--set-case-sensitivity ()
  "Set the value of `helm-rg--case-sensitivity' and re-run `helm-rg'."
  (interactive)
  (let ((pat helm-pattern)
        (start-dir helm-rg--current-dir))
    (helm-rg--run-after-exit
     ;; TODO: see if all of this rebinding of the defvars is necessary, and if it must occur then
     ;; make it part of the `helm-rg--run-after-exit' macro.
     (let* ((helm-rg--current-dir start-dir)
            (all-sensitivity-keys
             (helm-rg--alist-keys helm-rg--case-sensitive-argument-alist))
            (sensitivity-selection
             (completing-read "Choose case sensitivity: " all-sensitivity-keys nil t))
            (helm-rg--case-sensitivity (intern sensitivity-selection)))
       (helm-rg--do-helm-rg pat)))))

(defun helm-rg--resume (orig-fun arg)
  (let ((helm-rg--current-dir helm-rg--last-dir))
    (funcall orig-fun arg)))

(advice-add 'helm-resume :around #'helm-rg--resume)


;; Keymaps
(defconst helm-rg-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    ;; TODO: basically all of these functions need to be tested.
    (define-key map (kbd "M-b") #'helm-rg--bounce)
    (define-key map (kbd "M-g") #'helm-rg--set-glob)
    (define-key map (kbd "M-m") #'helm-rg--set-extra-args)
    (define-key map (kbd "M-d") #'helm-rg--set-dir)
    (define-key map (kbd "M-c") #'helm-rg--set-case-sensitivity)
    (define-key map (kbd "<right>") #'helm-rg--file-forward)
    (define-key map (kbd "<left>") #'helm-rg--file-backward)
    map)
  "Keymap for `helm-rg'.")

(defconst helm-rg--bounce-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x C-r") #'helm-rg--bounce-refresh)
    (define-key map (kbd "C-c C-r") #'helm-rg--bounce-refresh-current-file)
    (define-key map (kbd "C-x C-s") #'helm-rg--bounce-dump)
    (define-key map (kbd "C-c C-s") #'helm-rg--bounce-dump-current-file)
    (define-key map (kbd "C-c f") #'helm-rg--visit-current-file-for-bounce)
    (define-key map (kbd "C-c e") #'helm-rg--expand-match-context)
    (define-key map (kbd "C-c C-e") #'helm-rg--spread-match-context)
    map)
  "Keymap for `helm-rg--bounce-mode'.")


;; Helm sources
(defconst helm-rg-process-source
  (helm-make-source "ripgrep" 'helm-source-async
    ;; FIXME: we don't want the header to be hydrated by helm, it's huge and blue and
    ;; unnecessary. Do it ourselves, then we don't have to delete the header in
    ;; `helm-rg--freeze-header-for-bounce'.
    :nohighlight t
    :nomark t
    :header-name #'helm-rg--header-name
    :keymap 'helm-rg-map
    :history 'helm-rg--input-history
    :help-message "FIXME: useful help message!!!"
    ;; TODO: basically all of these functions need to be tested.
    :candidates-process #'helm-rg--make-process
    :action (helm-make-actions "Visit" #'helm-rg--async-action)
    :filter-one-by-one #'helm-rg--parse-process-output
    :display-to-real #'helm-rg--display-to-real
    ;; TODO: add a `defcustom' for this.
    ;; :candidate-number-limit 200
    ;; It doesn't seem there is any obvious way to get the original input if using
    ;; :pattern-transformer.
    :persistent-action #'helm-rg--async-persistent-action
    :persistent-help "Visit result buffer and highlight matches"
    :requires-pattern nil
    :group 'helm-rg)
  "Helm async source to search files in a directory using ripgrep.")


;; Major modes
(define-derived-mode helm-rg--bounce-mode fundamental-mode "BOUNCE"
  "TODO: document this!

\\{helm-rg--bounce-mode-map}"
  ;; TODO: consider whether other kwargs of this macro would be useful!
  :group 'helm-rg
  (font-lock-mode 1))


;; Meta-programmed defcustom forms
(helm-rg--defcustom-from-alist helm-rg-default-case-sensitivity
    helm-rg--case-sensitive-argument-alist
  "Case sensitivity to use in ripgrep searches.

This is the default value for `helm-rg--case-sensitivity', which can be modified with
`helm-rg--set-case-sensitivity' during a `helm-rg' session.

This must be an element of `helm-rg--case-sensitive-argument-alist'.")

(helm-rg--defcustom-from-alist helm-rg-file-paths-in-matches-behavior
    ((relative) (absolute))
  "Whether to print each file's absolute path in matches on every line of `helm-rg' output.

This is currently necessary to be compatible with `helm-resume'.")


;; Autoloaded functions
;;;###autoload
(defun helm-rg (rg-pattern &optional pfx paths)
  "Search for the PCRE regexp RG-PATTERN extremely quickly with ripgrep.

When invoked interactively with a prefix argument, or when PFX is non-nil,
set the cwd for the ripgrep process to `default-directory'. Otherwise use the
cwd as described by `helm-rg-default-directory'.

If PATHS is non-nil, ripgrep will search only those paths, relative to the
process's cwd. Otherwise, the process's cwd will be searched.

Note that ripgrep respects glob patterns from .gitignore, .rgignore, and .ignore
files, excluding files matching those patterns. This composes with the glob
defined by `helm-rg-default-glob-string', which only finds files matching the
glob, and can be overridden with `helm-rg--set-glob', which is defined in
`helm-rg-map'.

There are many more `defcustom' forms, which are visible by searching for \"defcustom\" in the
`helm-rg' source (which can be located using `find-function'). These `defcustom' forms set defaults
for options which can be modified while invoking `helm-rg' using the keybindings listed below.

The ripgrep command's help output can be printed into its own buffer for
reference with the interactive command `helm-rg-display-help'.

\\{helm-rg-map}"
  (interactive (list (helm-rg--get-thing-at-pt) current-prefix-arg nil))
  (let* ((helm-rg--current-dir
          (or helm-rg--current-dir
              (and pfx default-directory)
              (helm-rg--interpret-starting-dir helm-rg-default-directory)))
         ;; TODO: make some declarative way to ensure these variables are all initialized and
         ;; destroyed (an alist `defconst' should do the trick)!
         (helm-rg--glob-string
          (or helm-rg--glob-string
              helm-rg-default-glob-string))
         (helm-rg--extra-args
          (or helm-rg--extra-args
              helm-rg-default-extra-args))
         (helm-rg--paths-to-search
          (or helm-rg--paths-to-search
              paths))
         (helm-rg--case-sensitivity
          (or helm-rg--case-sensitivity
              helm-rg-default-case-sensitivity)))
    ;; FIXME: make all the `defvar's into buffer-local variables (or give them local counterparts)?
    ;; the idea is that `helm-resume' can be applied and work with the async action -- currently it
    ;; tries to find a buffer which we killed in the cleanup here when we do the async action
    ;; (i think)
    (setq helm-rg--last-dir helm-rg--current-dir)
    (unwind-protect (helm-rg--do-helm-rg rg-pattern)
      (helm-rg--unwind-cleanup))))

;;;###autoload
(defun helm-rg-display-help (&optional pfx)
  "Display a buffer with the ripgrep command's usage help.

The help buffer will be reused if it was already created. A prefix argument when
invoked interactively, or a non-nil value for PFX, will display the help buffer
in the current window. Otherwise, if the help buffer is already being displayed
in some window, select that window, or else display the help buffer with
`pop-to-buffer'."
  (interactive "P")
  (let ((filled-out-help-buf
         (or (get-buffer helm-rg--ripgrep-help-buffer-name)
             (helm-rg--make-help-buffer helm-rg--ripgrep-help-buffer-name))))
    (if pfx (switch-to-buffer filled-out-help-buf)
      (-if-let* ((buf-win (get-buffer-window filled-out-help-buf t)))
          (select-window buf-win)
        (pop-to-buffer filled-out-help-buf)))))

;;;###autoload
(defun helm-rg-from-isearch ()
  "Invoke `helm-rg' from isearch."
  (interactive)
  (let ((input (if isearch-regexp isearch-string (regexp-quote isearch-string))))
    (isearch-exit)
    (helm-rg input)))

(provide 'helm-rg)
;;; helm-rg.el ends here
