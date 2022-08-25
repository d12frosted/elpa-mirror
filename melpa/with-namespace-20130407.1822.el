;;; with-namespace.el --- interoperable elisp namespaces

;; Copyright (C) 2013 Wilfred Hughes

;; Author: Wilfred Hughes <me@wilfred.me.uk>
;; Version: 1.1
;; Package-Version: 20130407.1822
;; Package-Commit: 36828a40428c8e53c117f2df830b2f7a59ddd306
;; Keywords: namespaces
;; Package-Requires: ((dash "1.1.0") (loop "1.1"))

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

;;; Commentary

;; Many elisp packages already use `my-project-foo' and
;; `my-project--internal-bar' naming conventions. `with-namespace'
;; allows you to define a collection of functions, variables etc
;; without having to write the prefix in front of every symbol.

;; It works by simply rewriting all the symbols of top-level
;; definitions, so the following code:

;; (with-namespace "my-project"
;;     (defun foo () (-greet "world"))
;;     (defun -greet (thing) (format "hello %s" thing))
;;     (defvar bar 3 "some docstring"))

;; compiles to:

;; (defun my-project-foo () (my-project--greet "world"))
;; (defun my-project--greet (thing) (format "hello %s" thing))
;; (defvar my-project-bar 3 "some docstring")

;; By producing code that many elisp developers would write anyway,
;; `with-namespace' does not require downstream users to even know
;; about it.

;; Note that in tracebacks, you will see the compiled function names,
;; so trying to jump to a definition will give "Unable to find
;; location in file" within the file. You can work around this by
;; using macrostep (available on MELPA) to temporarily expand the
;; `with-statement' form. Whilst expanded, you can jump straight to
;; the definition.

;;; Todo

;; * Document
;; * Explore importing from other namespaces (everything, public only, named only)

;;; Changelog

;; 1.1 -- Added support for defmacro, defconst and defstruct, and
;; allow more to be added by the user
;; 1.0 -- Initial release

;;; Similar projects

;; * https://github.com/skeeto/elisp-fakespace/
;; * https://github.com/sigma/codex

(require 'loop)
(require 'dash)

(defun with-namespace--replace-nested-list (from to list)
  "Replace all occurrences of atom FROM with TO
in an (arbitrarily nested) proper LIST."
  (--map
   (cond
    ((consp it) (with-namespace--replace-nested-list from to it))
    ((eq it from) to)
    ('t it))
   list))

(defvar with-namespace--suported-defs
  (list 'defun 'defvar 'defmacro 'defconst 'defstruct))

;; nope, with-namespace isn't written with with-namespace. That'd be insane. There'd
;; also be bootstrapping issues.
(defun with-namespace--get-definitions (definitions)
  (let ((ns-symbols nil))
    (loop-for-each definition definitions
      (let ((definition-type (car definition))
            (new-symbol (cadr definition)))
        (unless (memq definition-type with-namespace--suported-defs)
          (error "with-namespace doesn't support %s definitions -- file a bug!" (car definition)))
        (add-to-list 'ns-symbols new-symbol)))
    ns-symbols))

(defvar with-namespace--separator "-")

(defmacro with-namespace (prefix &rest definitions)
  "Rewrite a list DEFINITIONS of defun or defvar sexps so their
symbol starts with PREFIX."
  (declare (indent defun)
           (debug (stringp "prefix" &rest form)))
  (let ((ns-symbols (with-namespace--get-definitions definitions)))
    (loop-for-each ns-symbol ns-symbols
      (let ((fully-qualified-symbol
             (intern
              (concat prefix
                      with-namespace--separator
                      (symbol-name ns-symbol)))))
        (setq definitions
              (with-namespace--replace-nested-list ns-symbol fully-qualified-symbol definitions))))
    `(progn ,@definitions)))

(provide 'with-namespace)
;;; with-namespace.el ends here
