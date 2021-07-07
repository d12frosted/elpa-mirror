;;; requirejs.el --- Requirejs import manipulation and source traversal.

;; Author: Joe Heyming <joeheyming@gmail.com>
;; URL: https://github.com/syohex/requirejs-emacs
;; Package-Version: 20150904.2318
;; Package-Commit: 7d73453653b6b97cca59fcde8d529b5a228fbc01
;; Version: 1.1
;; Keywords: javascript, requirejs
;; Package-Requires: ((js2-mode "20150713")(popup "0.5.3")(s "1.9.0")(cl-lib "0.5"))

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
;; This module allows you to:
;;  - Sort a define block
;;   - define rules about how to sort shims/aliases
;;  - Helps you add new define paths to a define block
;;   - which uses the above sorting functionality when any arbitrary line is added to the path array.
;;  - Allows you to jump to a module under your cursor as long as it exists in the same requirejs project.

;; installation: put this file under an Emacs Lisp directory, then include this file (require 'requirejs)
;;  Usage:
;; Here is a sample configuration that may be helpful to get going.
;; 
;; (setq requirejs-require-base "~/path/to/your/project")
;; (requirejs-add-alias "jquery" "$" "path/to/jquery-<version>.js")
;;
;; (add-hook 'js2-mode-hook
;;           '(lambda ()
;;              (local-set-key [(super a) ?s ?r ] 'requirejs-sort-require-paths)
;;              (local-set-key [(super a) ?a ?r ] 'requirejs-add-to-define)
;;              (local-set-key [(super a) ?r ?j ] 'requirejs-jump-to-module)
;;              ))

;;; Code:

(require 'js2-mode)
(require 'popup)
(require 'cl-lib)
(require 's)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; js2-mode utilities
;;  These utilities use the js2-mode abstract syntax tree to do useful operations
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; 

(defun requirejs-js2-node-quoted-contents (node)
  "Get the inner text of a quoted string.  e.g 'foo' -> yeilds foo.
Argument NODE A js2-node."
  (let ((node-pos (js2-node-abs-pos node)))
    (buffer-substring-no-properties (+ 1 node-pos) (- (+ node-pos (js2-node-len node)) 1))))

(defun requirejs-js2-goto-node (fn)
  "Go to a js2-node using the passed in function.
Returns that node, if any.
Argument FN A js2-node function that takes a js2-node and returns a js2-node."
  (let* ( (node (js2-node-at-point))
          (child-node (funcall fn node)) )
    (if child-node
        (goto-char (js2-node-abs-pos child-node)))
    child-node))

(defun requirejs-js2-goto-first-child-node()
  "Goes to the first child, returns that node, if any."
  (interactive)
  (requirejs-js2-goto-node 'js2-node-first-child))

(defun requirejs-js2-goto-last-child-node()
  "Goes to the first child, returns that node, if any."
  (interactive)
  (requirejs-js2-goto-node 'js2-node-last-child))

(defun requirejs-js2-goto-parent-node()
  "Goes to your parent node, returns that node."
  (interactive)
  (let ((curnode (js2-node-at-point))
        (node (requirejs-js2-goto-node 'js2-node-parent)))
    (if (eq (js2-node-abs-pos curnode) (js2-node-abs-pos node))
        (progn
          (setq node (js2-node-at-point))
          (goto-char (- (js2-node-abs-pos node) 1))
          (setq node (js2-node-at-point))
          (goto-char (js2-node-abs-pos node))
          node) node)))

(defun requirejs-js2-goto-next-node()
  "Goes to the next sibling, if any.  Returns the sibling"
  (interactive)
  (requirejs-js2-goto-node 'js2-node-next-sibling))

(defun requirej-js2-goto-prev-node()
  "Goes to the previous sibling, if any.  Returns the sibling"
  (interactive)
  (requirejs-js2-goto-node 'js2-node-prev-sibling))

(defun requirejs-js2-goto-nth-child(n)
  "Goes to the nth child, if any.  Returns the child"
  (interactive (list (string-to-number (read-string "Goto child: "))))
  (let* ((current (js2-node-at-point))
         (parent (js2-node-parent current))
         (child (nth n (js2-node-child-list parent))))
    (if child (goto-char (js2-node-abs-pos child))) child))

;; The following functions were shamelessly stolen from https://github.com/ScottyB/ac-js2
(defun requirejs-js2-root-or-node ()
  "Return the current node or js2-ast-root node."
  (let ((node (js2-node-at-point)))
    (if (js2-ast-root-p node)
        node
      (js2-node-get-enclosing-scope node))))

(defun requirejs-js2-get-function-name (fn-node)
  "Return the name of the function FN-NODE.
Value may be either function name or the variable name that holds
the function."
  (let ((parent (js2-node-parent fn-node)))
    (if (js2-function-node-p fn-node)
        (or (js2-function-name fn-node)
            (if (js2-var-init-node-p parent)
                (js2-name-node-name (js2-var-init-node-target parent)))))))

(defun requirejs-js2-get-function-node (name scope)
  "Return node of function named NAME in SCOPE."
  (catch 'function-found
    (js2-visit-ast
     scope
     (lambda (node end-p)
       (when (and (not end-p)
                  (string= name (requirejs-js2-get-function-name node)))
         (throw 'function-found node))
       t))
    nil))

(defun requirejs-js2-get-function-call-node (name scope)
  "Return node of function named NAME in SCOPE."
  (catch 'function-found
    (js2-visit-ast
     scope
     (lambda (node end-p)
       (when (and (not end-p)
                  (= (js2-node-type node) js2-NAME)
                  (string= name (js2-name-node-name node))
                  (= (js2-node-type (js2-node-parent node)) js2-CALL)
                  )
         (throw 'function-found node))
       t))
    nil))

(defun requirejs-js2-name-declaration (name)
  "Return the declaration node for node named NAME."
  (let* ((node (requirejs-js2-root-or-node))
         (scope-def (js2-get-defining-scope node name))
         (scope (if scope-def (js2-scope-get-symbol scope-def name) nil))
         (symbol (if scope (js2-symbol-ast-node scope) nil)))
    (if (not symbol)
        (requirejs-js2-get-function-node name scope-def)
      symbol)))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar requirejs-define-or-require "define" "`requirejs-define-or-require' Stores weather your project uses require([], function(){}) style imports or define([], function() {}).")

(defun requirejs-goto-define()
  "Jump to the define at the beginning of the buffer"
  (interactive)
  (let* ( (define-node (requirejs-js2-get-function-call-node requirejs-define-or-require (js2-node-root (js2-node-at-point)) ))
          (define-call (js2-node-parent define-node)) )
    (goto-char (+ (js2-node-abs-pos define-call) (js2-call-node-lp define-call) ))
    (search-forward "[")
    (backward-char 1)))

(defun requirejs-get-require-paths()
  "Gets all the require paths and returns them without quotes."
  (interactive)
  (save-excursion
    (requirejs-goto-define)
    (let ((node (requirejs-js2-goto-first-child-node))
          (require-paths '()))
      (while (not (null node))
        (push (requirejs-js2-node-quoted-contents node) require-paths)
        (setq node (js2-node-next-sibling node)))
      require-paths
      )))

(defun requirejs-clear-list()
  "Look at your parent node and clear out all child nodes"
  (interactive)
  (backward-up-list)
  (mark-sexp)
  (kill-region (+ 1(region-beginning)) (- (region-end) 1) )
  (forward-char 1))

;; Define a structure for storing an alias
(cl-defstruct requirejs-alias
  "A rule for a special shim in your requirejs conf"
  label ;; The lookup value of an alias
  variableName ;; The desired variable name to place in a define function.
  path) ;; The path that we will sort by.


(defvar requirejs-aliases (make-hash-table :test 'equal)
  "`requirejs-aliases' is a table that stores user defined aliases.
An alias is added with `requirejs-add-alias'")

(defvar requirejs-alias-var-lookup (make-hash-table :test 'equal)
  "`requirejs-alias-var-lookup' Defines a reverse lookup of variable name to requirejs alias.")

(defun requirejs-add-alias (label variableName path)
  "Add a requirejs config shim to `requirejs-aliases'.

Argument LABEL The label we are using to look up the alias.
Argument VARIABLENAME The name of the variable
 as it should appear in the define block.
Argument PATH The exact path that is found under `requirejs-require-base'.

Example 1:
 If you want to expose that lookup: knockout, but name the variable ko:
 (requirejs-add-alias \"knockout\" \"ko\" \"knockout\")
 This says that when you sort require PATHs,
  we will interpret knockout as the variable ko:
 define(['knockout'], function(ko) { ... }
 The third string is used to determine how to sort

Example 2: if you include lodash, but you want to sort by 'Lodash', not '_':
 (requirejs-add-alias \"_\", \"_\" \"lodash\")
 This will make sure the define block looks like this:
 define(['knockout', '_'], function(ko, _) { ... }  instead of this:
 define(['_', 'knockout'], function(_, ko) { ... }  because K comes before L"
  (interactive)
  (let ((alias (make-requirejs-alias :label label :variableName variableName :path path)))
    (puthash label alias requirejs-aliases)
    (puthash variableName alias requirejs-alias-var-lookup)
    ))

(defun requirejs-path-compare(a b)
  "Compare paths ignore case"
  (string< (downcase a) (downcase b)))

(defun requirejs-alias-compare(a b)
  "Compare paths ignore case"
  (let* ((alias-a (gethash a requirejs-aliases))
         (alias-b (gethash b requirejs-aliases))
         (shim-a (if alias-a (requirejs-alias-path alias-a) a))
         (shim-b (if alias-b (requirejs-alias-path alias-b) b)))
    (string< shim-a shim-b)))


(defvar requirejs-var-formatter '(lambda (path basename) nil)
  "Override `requirejs-var-formatter' to add variable formatting rules.
If this returns nil, then we use the basename
 of the path as the default variable name.
If `requirejs-var-formatter' returns a string,
 then we will use that string for the variable name.")

(defvar requirejs-text-suffix "TextStr"
  "Requirejs text! paths are constructed with this string.
We take the basename of the path file and tack on `requirejs-text-suffix'.
Override this if TextStr doesn't work for you.")

(defun requirejs-get-variable-name(path)
  (interactive)
  (let* ((basename (car (last (split-string path "/" )) ))
         (shim (gethash path requirejs-aliases))
         (formatted (funcall requirejs-var-formatter path basename))
         )
    (cond
     ;; if path is a alias
     (shim (requirejs-alias-variableName shim))
     ;; if path is a text! path
     ((string-match "^text!" path)
      (concat (file-name-sans-extension basename) requirejs-text-suffix))
     ;; if path was formatted by requirejs-var-formatter
     (formatted formatted)
     
     ;; default return the basename
     (t basename)
     )))

(defvar requirejs-tail-path '(lambda (path) nil)
  "Specify if a path belongs at the of the requirejs define block.
Certain teams/companies have guidelines where they always
 put text! paths at the end of the function declaration.
In this case, you would (setq requirejs-tail-path 'your-team-requirements)
`requirejs-tail-path' takes a path and if it should be put at the end,
returns a non-nil value.")

(defun requirejs-sort-require-paths(&optional other)
  "Sorts the paths inside define, then injects variable names into the corresponding function declaration."
  (interactive)
  (let ( (require-paths (requirejs-get-require-paths))
         (standard-paths '())
         (tail-paths '())
         (final-list '()) )

    (if other
        (push other require-paths))
    (setq require-paths (delete-dups require-paths))
    
    ;; Create two lists, standard-paths go at the beginning
    ;;  tail-paths go at the end
    (dolist (elt require-paths)
      (progn
        (if (or (gethash elt requirejs-aliases) (funcall requirejs-tail-path elt))
            (push elt tail-paths)
          (push elt standard-paths))))

    ;; final-list stores the list we will inject into the define block
    (setq final-list
          (append (sort standard-paths 'requirejs-path-compare)
                  (sort tail-paths 'requirejs-alias-compare)))
    (save-excursion
      (requirejs-goto-define)
      (requirejs-js2-goto-next-node)
      
      (let ((node (requirejs-js2-goto-nth-child 1)))
        (if (= (length (js2-node-child-list node)) 0)
            (search-forward "(")
          (requirejs-js2-goto-first-child-node))
        )
      (requirejs-clear-list)

      ;; inject the function variable params
      (insert (mapconcat 'identity (mapcar 'requirejs-get-variable-name  final-list) ", "))

      (requirejs-goto-define)
      (let (
            (node (requirejs-js2-goto-first-child-node))
            (end))
        (if (not node) (search-forward "["))
        (requirejs-clear-list)
        (if node (progn (insert "\n\n") (backward-char 1)))
        
        ;; inject the newline separated variables
        (insert (mapconcat 'identity (mapcar #'(lambda(a) (concat "'" a "'")) final-list) ",\n"))
        
        ;; indent the define block
        (setq end  (+ 1 (point)))
        (requirejs-goto-define)
        (js2-indent-region (point) end)
        )

      ;; eightify the list manually since the syntax tree spacing may be borked at this point.
      (requirejs-js2-goto-next-node)
      (let ((node (requirejs-js2-goto-first-child-node))
            (next-column-spot))
        (while node
          (setq next-column-spot (+ (current-column) (js2-node-len node)))
          (if (> next-column-spot 80)
              (progn
                (search-forward-regexp "[ ,]")
                (insert "\n")
                (js2-indent-line)))

          (setq node (requirejs-js2-goto-next-node))
          )
        )
      )
    ))

(defun requirejs-is-define-call (node)
  "Return true if the NODE is a CALL node and it equals 'define'."
  (and
   (= (js2-node-type node) js2-CALL)
   (equal requirejs-define-or-require (buffer-substring (js2-node-abs-pos node) (+ 6 (js2-node-abs-pos node)) )) ))

(defun requirejs-jump-to()
  "Goes to the variable declaration of the node under the cursor.  If you are inside a define block's function parameters, `requirejs-jump-to' attempts to call `requirejs-jump-to-module' to go to the corresponding file."
  (interactive)
  (let* ( (node (js2-node-at-point))
          (name (js2-name-node-name node))
          (declaration (requirejs-js2-name-declaration name))
          (define) )
    (if declaration
        (progn
          (setq define (js2-node-parent (js2-node-parent node)))
          (if (requirejs-is-define-call define)
              ;; navigate to corresponding path
              (requirejs-jump-to-module))
          
          ;; jump to the declaration
          (goto-char (js2-node-abs-pos declaration)) )) ))

(defvar requirejs-require-base nil
  "`requirejs-require-base' is the base path for looking for javascript files.")

(defvar requirejs-path-formatter '(lambda (a) a)
  "`requirejs-path-formatter' takes a found javascript file and formats it so it can go in a define([...] block.")

(defvar requirejs-popup-keymap
  (let ((keymap (make-sparse-keymap)))
    (set-keymap-parent keymap popup-menu-keymap)
    (define-key keymap [return] 'popup-select )
    (define-key keymap [tab] 'popup-select )
    keymap)
  "*A keymap for `requirejs-jump-to-module' of `requirejs'.")

(defun requirejs-validate-project ()
  "Determines if your requireJS project is valid to be able to run filesystem actions."
  (if (not requirejs-require-base) (error "Please set requirejs-require-base to your requireJS project root")))

(defun requirejs-navigate (filename)
  "Navigates to a file, if it exists.  Errors out if FILENAME is a directory."
  (let ((filepath (concat requirejs-require-base filename)))
    (if (not (file-directory-p filepath))
        (find-file-existing filepath)
      (error (format "Won't navigate, %s is a directory." filepath)))))

(defun requirejs-find-filepath (variableName)
  "Invokes a find command under `requirejs-require-base' and look for VARIABLENAME."
  (message (format "Finding variableName: '%s' ..." variableName))
  (requirejs-validate-project)
  (let* ((command (format "cd %s; find . -name \"%s.js\"" requirejs-require-base variableName))
        (files (split-string (s-trim (shell-command-to-string command)) "\n")))
    ;; (message (format "command = %s" command))
    ;; (message (format "files = %s %s" files (length files)))
    (cond ((equal (car files) "") (error (format "Can't find module: %s" variableName)))
          ((= (length files) 1) (s-trim (cl-first files)))
          ((> (length files) 1) (popup-menu* files :keymap requirejs-popup-keymap))
          )))

(defun requirejs-jump-to-module ()
  "Jump to the file that is behind the variable name under your cursor.
If more than one file matches your variable name,
 requirejs provides a menu to select the appropriate file.
`requirejs-require-base' Must be set in order to execute this function."
  (interactive)
  (requirejs-validate-project)
  (let* (
         (node (js2-node-at-point))
         (name (buffer-substring (js2-node-abs-pos node) (js2-node-abs-end node)))
         (alias (gethash name requirejs-alias-var-lookup))
         (result)
         )
    (message (format "alias = %s" alias))
    (if alias
        (progn
          (setq result (requirejs-alias-path alias))
          (message (format "Jumping to requirejs alias = %s" result))
          (requirejs-navigate result))
      (progn
        (setq result (requirejs-find-filepath name))
        (message (format "Jumping to: %s" result))
        (requirejs-navigate result)
        ))))

(defun requirejs-add-to-define ()
  "Add the path behind the variable name under your cursor to the define block.
If more than one file matches your variable name,
 requirejs provides a menu to prompt for the appropriate file path.
`requirejs-require-base' Must be set in order to execute this function."
  (interactive)
  (requirejs-validate-project)
  (let* ( (node (js2-node-at-point))
          (name (buffer-substring (js2-node-abs-pos node) (js2-node-abs-end node)))
          (alias (gethash name requirejs-alias-var-lookup))
          (result) )
    (message (format "alias = %s" alias))
    (if alias (progn
                (setq result (requirejs-alias-label alias))
                (message (format "Adding requirejs alias = %s" result))
                (requirejs-sort-require-paths result))
      (progn
        (setq result
              (replace-regexp-in-string "^\.\/" ""
                                        (replace-regexp-in-string "\.js$" ""
                                                                  (requirejs-find-filepath name))))
        (message (format "Adding: %s" result))
        (requirejs-sort-require-paths (funcall requirejs-path-formatter result))
        ))))

(defun requirejs-reset-project ()
  "Reset all project specific variables."
  (interactive)
  (setq requirejs-require-base nil)
  (setq requirejs-path-formatter '(lambda (a) a))
  (clrhash requirejs-aliases)
  (clrhash requirejs-alias-var-lookup)
  (setq requirejs-var-formatter '(lambda (path basename) nil))
  (setq requirejs-tail-path '(lambda (path) nil)))

(defun requirejs-js2-eightify-list (&optional line-break)
  "Formats a list (parameters or an array) to be at most 80 characters wide.
Optional argument LINE-BREAK If true,
 we will add a line break around the list that is 80ified."
  (interactive)
  (save-excursion
    (let* ((parent (requirejs-js2-goto-parent-node))
           (orig-pos (point))
           (nodes (js2-node-child-list parent))
           (node-length (length nodes))
           (n (- node-length 1))
           (node (nth n nodes))
           (next-column-spot))
      (goto-char (js2-node-abs-end node))
      (kill-region (point) (progn
			 (search-forward-regexp ")\\|]")
			 (- (point) 1) ))
      ;; Remove whitespace around nodes
      (while (>= n 0)
        (goto-char (js2-node-abs-pos node))
        (setq next-column-spot (point))
        (kill-region (progn
                       (search-backward-regexp "[,(\[]")
                       (+ (point) 1)) next-column-spot)
        (setq n (- n 1))
        (setq node (nth n nodes)))
      (if (looking-at "(")
          (forward-char 1))
      (setq n (+ n 1))
      (if line-break
          (progn
            (insert "\n")
            (js2-indent-line) ))
      (while (< n node-length)
        (setq next-column-spot (current-column)) ;;(+ (current-column) (js2-node-len node)))
        (if (> next-column-spot 80)
            (progn
              (delete-char -1) ;; remove the added space
              (insert "\n")
              (js2-indent-line)))
        (goto-char (+ (+(point) (js2-node-len node)) 1))
        (if (looking-at ",")
            (forward-char 1))
        (insert " ")
        (setq n (+ n 1))
        (setq node (nth n nodes)) )
      (delete-char -1)
      (if line-break
          (progn
            (backward-char 1)
            (insert "\n"))) )))

(provide 'requirejs)

;;; requirejs.el ends here
