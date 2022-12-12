;;; auto-complete-sage.el --- An auto-complete source for sage-shell-mode.
;; Copyright (C) 2012-2016 Sho Takemori.

;; Author: Sho Takemori <stakemorii@gmail.com>
;; URL: https://github.com/stakemori/auto-complete-sage
;; Keywords: Sage, math, auto-complete
;; Version: 0.0.4
;; Package-Requires: ((auto-complete "1.5.1") (sage-shell-mode "0.1.0"))

;;; License
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
;; To setup, put the following lines to ~/.emacs.d/init.el.
;; (add-hook 'sage-shell:sage-mode-hook 'ac-sage-setup)
;; (add-hook 'sage-shell-mode-hook 'ac-sage-setup)

;;; Code:
(require 'auto-complete)
(require 'sage-shell-mode)

(setq sage-shell:completion-function 'auto-complete)
(add-to-list 'ac-modes 'sage-shell-mode)
(add-to-list 'ac-modes 'sage-shell:sage-mode)
(when (fboundp #'eldoc-add-command)
  (eldoc-add-command #'ac-complete #'ac-expand))

(defgroup auto-complete-sage nil "Group for auto-compete-sage"
  :group 'sage-shell)

(defcustom ac-sage-show-quick-help nil
  "Non-nil means show quick help of auto-complete-mode in
`sage-shell-mode' buffers and `sage-shell:sage-mode' buffers."
  :group 'auto-complete-sage
  :type 'boolean)

(defvaralias 'ac-sage-quick-help-ignore-classes
  'sage-shell:inspect-ingnore-classes)

(defcustom ac-sage-complete-on-dot nil
  "Non-nil means `auto-complete' starts when dot is inserted."
  :group 'auto-complete-sage
  :type 'boolean)

(defvar ac-sage--repl-methods-cached nil)
(make-variable-buffer-local 'ac-sage--repl-methods-cached)

(defvar ac-sage--sage-commands-doc-cached nil)
(make-variable-buffer-local 'ac-sage--sage-commands-doc-cached)

(defun ac-sage--sage-commands-doc-clear-cache ()
  (sage-shell:with-current-buffer-safe sage-shell:process-buffer
    (setq ac-sage--sage-commands-doc-cached nil)))

(add-hook 'sage-shell:clear-command-cache-hook
          'ac-sage--sage-commands-doc-clear-cache)

(defun ac-sage--doc-clear-cache ()
  (sage-shell:with-current-buffer-safe sage-shell:process-buffer
    (setq ac-sage--repl-methods-cached nil)))

(cl-defmacro ac-sage--cache-doc (doc-func name base-name
                                          cache-var
                                          &optional (min-len 0))
  `(sage-shell:with-current-buffer-safe sage-shell:process-buffer
     (sage-shell:aif (and (> (length ,name) ,min-len)
                          (assoc-default ,name ,cache-var))
         it
       (when (sage-shell:at-top-level-and-in-sage-p)
         (let ((doc (,doc-func ,name ,base-name)))
           (prog1
               doc
             (setq ,cache-var
                   (cons (cons ,name doc) ,cache-var))))))))

(defun ac-sage-doc (can)
  (when ac-sage-show-quick-help
    (ac-sage--cache-doc ac-sage--doc can nil
                        ac-sage--sage-commands-doc-cached
                        ;; Short names may be re-defined.
                        4)))

(defun ac-sage-repl--base-name-and-name (can)
  (let* ((base-name
          (or (sage-shell-cpl:get-current 'var-base-name)
              (sage-shell:in (sage-shell-cpl:get-current 'interface)
                             sage-shell-interfaces:other-interfaces)))
         (name (sage-shell:aif base-name
                   (format "%s.%s" it can)
                 can)))
    (cons base-name name)))

(defun ac-sage-repl-methods-doc (can)
  (when ac-sage-show-quick-help
    (cl-destructuring-bind (base-name . name)
        (ac-sage-repl--base-name-and-name can)
      (ac-sage--cache-doc ac-sage--doc name base-name
                          ac-sage--repl-methods-cached))))

(defun ac-sage--doc (name base-name)
  (when (and (sage-shell:output-finished-p)
             (sage-shell:redirect-finished-p))
    (let ((doc (sage-shell:trim-right
                (sage-shell:send-command-to-string
                 (format "%s('%s'%s)"
                         (sage-shell:py-mod-func "print_short_doc_and_def")
                         name
                         (sage-shell:aif base-name
                             (format ", base_name='%s'" it)
                           ""))))))
      (unless (string= doc "")
        doc))))

(cl-defmacro ac-sage-repl:-source-base (&key type
                                             name
                                             (pred t) (use-cache t)
                                             (prefix-fun 'ac-prefix-default))
  ;; If the current state is nil, then pred1 returns nil.
  (let ((pred1  (if (eq pred t)
                    `(sage-shell:in
                      ,type
                      (sage-shell-cpl:get-current 'types))
                  `(and (sage-shell:in
                         ,type
                         (sage-shell-cpl:get-current 'types))
                        ,pred)))
        (func-name (intern (concat "ac-sage-repl--"
                                   (or name type) "-prefix"))))
    `(progn
       (defun ,func-name ()
         ,(if (eq use-cache t)
              `(when ,pred1
                 ,(list prefix-fun))
            `(progn
               (sage-shell-cpl:parse-and-set-state)
               (when ,pred1
                 ,(list prefix-fun)))))
       (list
        (cons 'init
              (lambda ()
                (sage-shell-cpl:completion-init
                 (equal this-command 'auto-complete)
                 :compl-state sage-shell-cpl:current-state)))
        (cons 'candidates
              (lambda ()
                (when ,pred1
                  (ac-sage-repl:candidates (list ,type)))))
        (cons 'cache nil)
        (cons 'prefix ',func-name)))))

(defvar ac-source-repl-sage-commands
  (append
   (ac-sage-repl:-source-base
    :type "interface"
    :name "sage-interface"
    :pred (string= (sage-shell-cpl:get-current 'interface) "sage"))
   '((document . ac-sage-doc)
     (symbol . "s"))))

(defvar ac-source-sage-methods
  (append
   (ac-sage-repl:-source-base :type "attributes"
                              :prefix-fun ac-sage:complete-on-dot-prefix)
   '((symbol . "s")
     (requires . 0)
     (document . ac-sage-repl-methods-doc))))

(defun ac-sage-repl:candidates (keys)
  (sage-shell-cpl:candidates :keys keys))

(defvar ac-source-sage-other-interfaces
  (append
   (ac-sage-repl:-source-base
    :type "interface"
    :name "other-interface"
    :pred (not (string= (sage-shell-cpl:get-current 'interface) "sage")))
   '((symbol . "s"))))

(defvar ac-sage-repl-modules
  (append '((symbol . "m")
            (requires . 0))
          (ac-sage-repl:-source-base
           :type "modules" :use-cache nil
           :prefix-fun ac-sage:complete-on-dot-prefix)))

(defvar ac-sage-repl-vars-in-module
  (cons '(symbol . "s")
        (ac-sage-repl:-source-base :type "vars-in-module")))

(defvar ac-sage-repl:python-kwds
  '("abs" "all" "and" "any" "apply" "as" "assert" "basestring"
    "bin" "bool" "break" "buffer" "bytearray" "callable" "chr"
    "class" "classmethod" "cmp" "coerce" "compile" "complex"
    "continue" "def" "del" "delattr" "dict" "dir" "divmod" "elif"
    "else" "enumerate" "eval" "except" "exec" "execfile" "file" "filter"
    "finally" "float" "for" "format" "from" "frozenset" "getattr" "global"
    "globals" "hasattr" "hash" "help" "hex" "id" "if" "import" "in" "input"
    "int" "intern" "is" "isinstance" "issubclass" "iter" "lambda" "len" "list"
    "locals" "long" "map" "max" "memoryview" "min" "next" "not" "object" "oct"
    "open" "or" "ord" "pass" "pow" "print" "property" "raise" "range" "raw"
    "reduce" "reload" "repr" "return" "reversed" "round" "set" "setattr"
    "slice" "sorted" "staticmethod" "str" "sum" "super" "try" "tuple" "type"
    "unichr" "unicode" "vars" "while" "with" "xrange" "yield" "zip" "__import__"))

(defun ac-sage-repl-python-kwds-candidates ()
  (when (and (sage-shell:in "interface"
                            (sage-shell-cpl:get-current 'types))
             (string= (sage-shell-cpl:get-current 'interface) "sage"))
    ac-sage-repl:python-kwds))

(defvar ac-source-sage-repl-python-kwds
  '((candidates . ac-sage-repl-python-kwds-candidates)))

(defvar as-source-sage-repl-argspec
  (ac-sage-repl:-source-base
   :type "in-function-call"
   :name "argspec"))

(defun ac-sage-repl:add-sources ()
  (setq ac-sources
        (append '(ac-sage-repl-modules
                  ac-source-sage-methods
                  ac-sage-repl-vars-in-module
                  ac-source-sage-other-interfaces
                  as-source-sage-repl-argspec
                  ac-source-sage-repl-python-kwds
                  ac-source-repl-sage-commands
                  ac-source-sage-words-in-buffers)
                ac-sources)))



;; sage-edit-ac
(defvar ac-sage-edit:-state-cached nil)

(cl-defmacro ac-sage-edit:-source-base
    (&key type
          name
          (pred t) (use-cache t) (prefix-fun 'ac-prefix-default))
  (let* ((state-var (sage-shell:gensym))
         (-pred  (if (eq pred t)
                     `(sage-shell:in ,type
                                     (sage-shell-cpl:get ,state-var 'types))
                   `(and (sage-shell:in ,type
                                        (sage-shell-cpl:get ,state-var 'types))
                         ,pred)))
         (-state (if (eq use-cache t)
                     'ac-sage-edit:-state-cached
                   '(setq ac-sage-edit:-state-cached
                          (sage-shell-edit:parse-current-state))))
         (func-name (intern (concat "ac-sage-edit--"
                                    (or name type) "-prefix"))))
    `(progn
       (defun ,func-name ()
         (let ((,state-var ,-state))
           (when ,-pred
             ,(list prefix-fun))))
       (list
        (cons 'init
              (lambda ()
                (let ((,state-var ac-sage-edit:-state-cached))
                  (unless sage-shell:process-buffer
                    (sage-shell-edit:set-sage-proc-buf-internal nil nil))
                  (sage-shell-cpl:completion-init
                   (equal this-command 'auto-complete)
                   :compl-state ,state-var))))
        (cons 'candidates
              (lambda ()
                (let ((,state-var ac-sage-edit:-state-cached))
                  (when ,-pred
                    (ac-sage-edit:candidates)))))
        (cons 'cache nil)
        (cons 'prefix ',func-name)))))

(defun ac-sage-edit:candidates ()
  (when (and sage-shell:process-buffer
             (get-buffer sage-shell:process-buffer)
             (sage-shell:redirect-finished-p)
             (sage-shell:output-finished-p))
    (sage-shell-cpl:candidates :state ac-sage-edit:-state-cached)))

(defvar ac-source-sage-commands
  (append
   (ac-sage-edit:-source-base :type "interface"
                              :name "sage-commands")
   '((document . ac-sage-doc)
     (symbol . "s"))))

(defvar ac-source-sage-modules
  (append '((symbol . "m")
            (requires . 0))
          (ac-sage-edit:-source-base
           :type "modules" :use-cache nil
           :prefix-fun ac-sage:complete-on-dot-prefix)))

(defun ac-sage:complete-on-dot-prefix ()
  (let ((pfx (ac-prefix-default)))
    (or pfx
        ;; 46 is ?.
        (if (and ac-sage-complete-on-dot
                 (= (char-before) 46))
            (point)))))

(defvar ac-source-sage-vars-in-modules
  (cons '(symbol . "s")
        (ac-sage-edit:-source-base :type "vars-in-module")))

(defun ac-sage:add-sources ()
  (setq ac-sources
        (append
         ac-sources
         '(ac-source-sage-modules
           ac-source-sage-vars-in-modules
           ac-source-sage-commands
           ac-source-sage-words-in-buffers))))

(defun ac-sage:words-in-sage-buffers ()
  (ac-word-candidates
   (lambda (buf)
     (sage-shell:in (buffer-local-value 'major-mode buf)
                    sage-shell:sage-modes))))

(defvar ac-source-sage-words-in-buffers
  '((init . ac-update-word-index)
    (candidates . ac-sage:words-in-sage-buffers)))

;;;###autoload
(defun ac-sage-setup ()
  (interactive)
  (unless auto-complete-mode
    (auto-complete-mode 1))
  (cond
   ((eq major-mode 'sage-shell-mode)
    (ac-sage-repl:add-sources))
   ((eq major-mode 'sage-shell:sage-mode)
    (ac-sage:add-sources))))

(provide 'auto-complete-sage)
;;; auto-complete-sage.el ends here
