;;; decl.el --- Library for organizing code declaratively -*- lexical-binding: t; -*-

;; Author: Preetpal S. Sohal
;; URL: https://github.com/preetpalS/decl.el
;; Package-Version: 20221027.1823
;; Package-Commit: 1b11ee91c4b2a2d30b236debf65538fbe4bf10a9
;; Version: 1.0.6
;; Package-Requires: ((dash "2.5.0") (emacs "24.3") (cl-lib "0.3"))
;; License: GNU General Public License Version 3

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

;; ;;; init.el --- sample init.el using library
;;
;; (package-initialize)
;; (add-to-list 'package-archives '("melpa" . "http://melpa.milkbox.net/packages/") t)
;;
;; (add-hook
;;  'after-init-hook
;;  (lambda () "Your init file"
;;    (require 'decl)
;;    (decl-block :init)
;;    (decl-node :mac-osx :init (lambda () (eq system-type 'darwin)))
;;    (decl-node :windows :init (lambda () (eq system-type 'windows-nt)))
;;    (decl-node :linux :init (lambda () (eq system-type 'gnu/linux)))
;;    (decl-node :gui :init (lambda () (if window-system t nil)))
;;    (decl-node :mac-osx-fullscreen-support :init
;;               (lambda ()
;;                 (defun toggle-fullscreen (&optional f)
;;                   (interactive)
;;                   (let ((current-value (frame-parameter nil 'fullscreen)))
;;                     (set-frame-parameter nil 'fullscreen
;;                                          (if (equal 'fullboth current-value)
;;                                              (if (boundp 'old-fullscreen) old-fullscreen nil)
;;                                            (progn (setq old-fullscreen current-value)
;;                                                   'fullboth)))))
;;
;;                 t)
;;               '(:gui :mac-osx))
;;    (decl-node :windows-consolas :init
;;               (lambda ()
;;                 (set-face-attribute 'default nil :font "consolas-14:antialias=natural"))
;;               '(:windows :gui))
;;    (decl-solve :init)
;;    ; Optionally execute for a report on the solver's execution: (decl-report :init)
;;    ))
;;
;; (provide 'init)
;;
;; ;;; init.el sample ends here

;;; Code:

;;;; DEPENDENCIES
;; Emacs libraries
(require 'cl-lib)
(require 'eieio)
(require 'eieio-base)
;; External libraries
(require 'dash)
;;;; END OF DEPENDENCIES


;; Variables that the user can modify to alter library behaviour.
(defgroup decl ()
  "Customize group for decl.el"
  :group 'lisp
  :prefix "decl-")

(defcustom decl-config-allow-duplicate-keyword-name-usage nil
  "Set to a truthy value to allow keywords to be used more than once to
refer to any 'decl-node' or 'decl-block'."
  :type 'boolean
  :group 'decl)

(defcustom decl-config-allow-decl-blocks-to-be-overwritten nil
  "Set to a truthy value to allow decl-blocks to be overwritten by the
function 'decl-block'.

DECL-CONFIG-ALLOW-DUPLICATE-KEYWORD-NAME-USAGE must be set to a truthy value
in order for this functionality to be become available."
  :type 'boolean
  :group 'decl)

(defcustom decl-config-allow-decl-nodes-to-be-overwritten nil
  "Set to a truthy value to allow decl-nodes to be overwritten by the function
'decl-node'.

DECL-CONFIG-ALLOW-DUPLICATE-KEYWORD-NAME-USAGE must be set to a truthy value
in order for this functionality to be become available."
  :type 'boolean
  :group 'decl)

(defcustom decl-config-fail-at-errors nil
  "Set to a truthy value to prevent this library from catching errors when
executing the lambda functions stored within 'decl-node' instances."
  :type 'boolean
  :group 'decl)

(defcustom decl-config-print-execution-status-messages nil
  "Set to a truthy value to allow this library to log execution status messages."
  :type 'boolean
  :group 'decl)


;; Convenience macros and functions ("!" indicates first argument will be mutated).
(defmacro decl--plist-put! (pl k v)
  (list 'setq pl (list 'plist-put pl k v)))

(defmacro decl-cons! (l e)
  (list 'setq l (list 'cons e l)))

(defmacro decl--concat! (s a)
  (list 'setq s (list 'concat s a)))

(defvar decl--increasing-count 0)
(defun decl--generate-increasing-number-string ()
  "Generate number strings (like \"0\", \"1\", ...) that are of increasing value each time this function is called."
  (number-to-string (cl-incf decl--increasing-count)))

(defun decl--plist-keys (pl)
  "Return new list containing the keys of the given plist, PL."
  (if (eq (mod (length pl) 2) 0)
      (let ((l nil) (leftover (cl-copy-seq pl)))
        (while (> (length leftover) 1)
          (decl-cons! l (car leftover))
          (setq leftover (nthcdr 2 leftover)))
        l)
    (error "Every plist must contain at an even number of elements!")))



;; The following code finds cycles in a directed graph (functions contain "digraph" in names).
;; It was written in a prior version of this library, but not modified for this release since
;; it is somewhat independent of the main functionality of this library.
(defclass decl---digraph (eieio-named)
  ((edges
    :initarg :edges
    :initform nil
    :type list
    :custom string
    :documentation "A list of plists. Each plist edge has the keys :start and :end along with any number of other flags")
   (vertices
    :initarg :vertices
    :initform nil
    :type list
    :custom string
    :documentation "A list of plists. Each plist vertex has the key :value along with any number of other flags"))
  "Base library representation of a digraph. Edges and vertices are just represented as plists for flexibility and simplicity.")

(defun decl---compare-plist-based-digraph-consisting-of-eq-able-elements (a b) ; Only used for debugging and testing
  "This function is for comparing two plist-based digraphs of the form:

Let e be any eq-able element. A plist-based digraph looks like the following: '(e (e e) e (e) e nil e nil)"
  (if (eq (length a) (length b))
      (let ((a-keys (decl--plist-keys a))
            (b-keys (decl--plist-keys b)))
        (if (eq (length a-keys) (length (cl-union a-keys b-keys))) ; Tests if a-keys and b-keys contain all the same elements
            (catch 'return
              (progn
                (cl-dolist (e a-keys)
                  (let ((a-key-list (plist-get a e))
                        (b-key-list (plist-get b e)))
                    (when (not (eq
                                (length b-key-list)
                                (length (cl-union a-key-list b-key-list))))
                      (throw 'return nil))))
                (throw 'return t)))
          nil))
    nil))

(defun decl---digraph-create-from-plist-based-digraph-consisting-of-eq-able-elements (g)
  "G is a plist graph."
  (let ((edges nil) (vertices nil))
    (progn
      (cl-dolist (e g)
        (when (not (listp e))
          (let ((vertex nil))
            (decl--plist-put! vertex :value e)
            (decl-cons! vertices vertex)

            (let ((l (plist-get g e)))
              (cl-dolist (e2 l)
                (let ((edge nil))
                  (decl--plist-put! edge :start e)
                  (decl--plist-put! edge :end e2)
                  (decl-cons! edges edge)))))))

      (decl---digraph (decl--generate-increasing-number-string)
                      :edges edges :vertices vertices))))

;; This is the only function that is called to find cycles outside of the
;; portion of code dedicated to finding cycles in a directed graph.
(defun decl---tarjan-strongly-connected-components-algorithm-for-plist-based-digraph-consisting-of-eq-able-elements--strong-connect (v index s sccs graph)
  "v is a vertex (plist with existing :value key)."
  (decl--plist-put! v :index index)
  (decl--plist-put! v :lowlink index)
  (cl-incf index)
  (decl-cons! s v)

  (cl-dolist (edge (oref graph edges))
    (when (eq (plist-get edge :start) (plist-get v :value))
      (let ((w ; w is another vertex, specifically
             (-first
              (lambda (x) "Used to find vertex that is :end in an edge"
                (eq (plist-get x :value) (plist-get edge :end)))
              (oref graph vertices))))
        (if (eq (plist-get w :index) nil)
            (progn ; Successor w has not yet been visited; recurse on it
              (let ((triplet (decl---tarjan-strongly-connected-components-algorithm-for-plist-based-digraph-consisting-of-eq-able-elements--strong-connect w index s sccs graph)))
                (setq index (nth 0 triplet))
                (setq s (nth 1 triplet))
                (setq sccs (nth 2 triplet))
                (decl--plist-put! v :index (min (plist-get v :lowlink)
                                                (plist-get w :lowlink)))))
          (cl-dolist (e s) ; Successor w is in stack S and hence in the current SCC
            (when (eq (plist-get e :value) (plist-get w :value))
              (decl--plist-put! v :lowlink (min (plist-get v :lowlink)
                                                (plist-get w :index)))))
          )) ; End of let that defines the end vertex w
      )) ; End of cl-dolist that iterates over the edges in the graph

  (if (eq (plist-get v :lowlink) (plist-get v :index)) ; If v is a root node, pop the stack and generate an SCC
      (let ((scc nil)
            (w nil))
        (catch 'break
          (while t
            (setq w (car s)) ; set w to be the top element in s
            (setq s (cdr s)) ; pop the top element off the stack s
            (decl-cons! scc w)
            (when (eq (plist-get w :value) (plist-get v :value))
              (throw 'break nil))))

        (decl-cons! sccs scc))) ; End of if that creates and scc
  `(,index ,s ,sccs))

(defun decl--tarjan-strongly-connected-components-algorithm-for-plist-based-digraph-consisting-of-eq-able-elements (g)
  "G is a plist graph (eq-able elements key to a list of the same type of elements as the key)."
  (let ((index 0)
        (s nil) ; Contains vertices, it is supposed to be a stack
        (sccs nil)
        (graph
         (decl---digraph-create-from-plist-based-digraph-consisting-of-eq-able-elements g)))

    (cl-dolist (vertex (oref graph vertices))
      (when (eq (plist-get vertex :index) nil)
        (let ((triplet (decl---tarjan-strongly-connected-components-algorithm-for-plist-based-digraph-consisting-of-eq-able-elements--strong-connect vertex index s sccs graph)))
                    (setq index (nth 0 triplet))
                    (setq s (nth 1 triplet))
                    (setq sccs (nth 2 triplet)))))
    sccs))
;; End of the code finds cycles in a digraph.


;; Private library variables that hold state
(defvar decl--decl-block-holder nil
  "This property list contains all 'decl-block' instances.")

(defvar decl--keyword-database (make-hash-table :test 'eq)
  "This stores every keyword used to name a 'decl-block' or 'decl-node'.")

;; Special type definition
(cl-deftype decl--decl-node--execution-status ()
            '(member
              :null
              :non-existent-constraint
              :depends-on-non-existent-constraint
              :involved-in-cyclical-relationship
              :failed-via-failed-dependency
              :failed-via-throwing-error
              :failed-via-returning-nil
              :successful))

;;;; Library class definitions
(defclass decl--block (eieio-named)
  ((keyword-name
    :initarg :keyword-name
    :type keyword
    :documentation "User-assigned keyword name.")
   (nodes
    :initarg :nodes
    :initform nil
    :type list
    :documentation "Contains all decl-nodes that belong to this decl-block.")
   (generated-data-structures-and-results
    :initarg :generated-data-structures-and-results
    :initform nil
    :type list
    :documentation "This is a property list used for storing data structures and results
generated during a call to decl-solve.

This slot is nil until decl-solve is called for this block.")))

(defclass decl--node (eieio-named)
  ((keyword-name
    :initarg :keyword-name
    :type keyword
    :documentation "User-assigned keyword name.")
   (lambda-function-that-only-returns-t-or-nil-depending-on-node-execution
    :initarg :lambda-function-that-only-returns-t-or-nil-depending-on-node-execution
    :initform (lambda () "Empty lambda that always returns nil." nil)
    :type function
    :documentation "This function's execution will only be considered a failure if
it returns nil or if it throws an error.")
   (keyword-names-of-dependencies
    :initarg :keyword-names-of-dependencies
    :initform nil
    :type list
    :documentation "A list of keywords.

If this list is empty, the stored lambda will be executed.
If the list is not empty, the execution-status slot of all members of this list
must be :successful for the stored lambda to be executed.")
   (execution-status
    :initarg :execution-status
    :initform :null
    :type decl--decl-node--execution-status
    :documentation "Gives information about decl--node execution status.")
   (execution-error-message
    :initarg :execution-error-message
    :initform ""
    :type string
    :documentation "A place to store error messages from execution of stored lambda function.")))

(cl-defmethod decl--decl--block--has-fate-been-determined ((this decl--block))
  "Iterates through the given decl--block's nodes slot and returns true if and
only if all members of the list have their execution-status slot not set to :null."
  (catch 'return
    (let ((nodes (oref this nodes)))
      (cl-dolist (node nodes)
        (when (eq (oref node execution-status) :null)
          (throw 'return nil)))
      (throw 'return t))))

(cl-defmethod decl--decl--block--generate-data-structures-and-results
  ((this decl--block))
  "This method builds the plist contained in the given decl--block's
'generated-data-structures-and-results' slot.

The keyword :plist-of-nodes indexes a plist that maps keywords to decl--nodes
within the given decl--block's generated-data-structures-and-results slot.

The keyword :list-of-node-keyword-names indexes a list that stores the keywords
referring to nodes within the given decl--block's generated-data-structures-and-results
slot.

The keyword :list-of-dependency-keyword-names indexes a list that stores the keywords
referring to dependencies within the given decl--block's generated-data-structures-and-results
slot.

The keyword :directed-graph-from-nodes-to-dependencies...

The keyword :directed-graph-from-dependencies-to-nodes..."
  (let ((generated-data-structures-and-results (oref this generated-data-structures-and-results))
        (plist-of-nodes nil)
        (list-of-node-keyword-names nil)
        (list-of-dependency-keyword-names nil)
        (directed-graph-from-nodes-to-dependencies nil)
        (directed-graph-from-dependencies-to-nodes nil)
        (nodes (oref this nodes)))
    ;; Generate plist-of-nodes
    (cl-dolist
        (node nodes)
      (decl--plist-put!
       plist-of-nodes
       (oref node keyword-name)
       node))

    ;; Store plist-of-nodes in generated-data-structures-and-results
    (decl--plist-put!
     generated-data-structures-and-results
     :plist-of-nodes
     plist-of-nodes)

    ;; Generate list-of-node-keyword-names
    (cl-dolist
        (node nodes)
      (decl-cons! list-of-node-keyword-names (oref node keyword-name)))

    ;; Store list-of-node-keyword-names in generated-data-structures-and-results
    (decl--plist-put!
     generated-data-structures-and-results
     :list-of-node-keyword-names
     list-of-node-keyword-names)

    ;; Generate list-of-dependency-keyword-names
    (cl-dolist (node nodes)
      (cl-dolist (e (oref node keyword-names-of-dependencies))
        (decl-cons! list-of-dependency-keyword-names e)))

    ;; Store list-of-dependency-keyword-names
    (decl--plist-put!
     generated-data-structures-and-results
     :list-of-dependency-keyword-names
     (-uniq list-of-dependency-keyword-names))

    ;; Generate directed-graph-from-nodes-to-dependencies
    (cl-dolist (node nodes)
      (let ((k (oref node keyword-name)))
        (decl--plist-put!
         directed-graph-from-nodes-to-dependencies
         k
         (cl-copy-seq (oref node keyword-names-of-dependencies)))))

    ;; Store directed-graph-from-nodes-to-dependencies in generated-data-structures-and-results
    (decl--plist-put!
     generated-data-structures-and-results
     :directed-graph-from-nodes-to-dependencies
     directed-graph-from-nodes-to-dependencies)

    ;; Generate directed-graph-from-dependencies-to-nodes
    (cl-dolist (node nodes)
      (let ((k (oref node keyword-name)))
        (cl-dolist (e (oref node keyword-names-of-dependencies))
          (decl--plist-put!
           directed-graph-from-dependencies-to-nodes
           e
           (cons k (plist-get
                    directed-graph-from-dependencies-to-nodes
                    e))))))

    ;; Store directed-graph-from-dependencies-to-nodes in generated-data-structures-and-results
    (decl--plist-put!
     generated-data-structures-and-results
     :directed-graph-from-dependencies-to-nodes
     directed-graph-from-dependencies-to-nodes)

    (oset this generated-data-structures-and-results generated-data-structures-and-results)))

(cl-defmethod decl--decl--block--access-item-from-generated-data-structures-and-results
  ((this decl--block) keyword-key)
  (if (keywordp keyword-key)
      (plist-get
       (oref this generated-data-structures-and-results)
       keyword-key)
    (error "Only keys of the type keyword are allowed to access values from generated-data-structures-and-results")))

(cl-defmethod decl--decl--block--find-non-existent-dependencies
  ((this decl--block))
  (let ((list-of-dependency-keyword-names
         (decl--decl--block--access-item-from-generated-data-structures-and-results this :list-of-dependency-keyword-names))
        (list-of-node-keyword-names
         (decl--decl--block--access-item-from-generated-data-structures-and-results this :list-of-node-keyword-names)))
    (-difference list-of-dependency-keyword-names list-of-node-keyword-names)))

(cl-defmethod decl--decl--block--keyword-names-of-nodes-with-non-existent-constraints
  ((this decl--block))
  (let
      ((to-return nil)
       (directed-graph-from-dependencies-to-nodes
        (decl--decl--block--access-item-from-generated-data-structures-and-results
         this :directed-graph-from-dependencies-to-nodes))
       (non-existent-constraint-keywords (decl--decl--block--find-non-existent-dependencies this)))
    (cl-dolist (e non-existent-constraint-keywords)
      (decl-cons! to-return (plist-get directed-graph-from-dependencies-to-nodes e)))
    (-uniq (-flatten to-return))))

(cl-defmethod decl--decl--node--execute ((this decl--node))
  (let ((execution-status (oref this execution-status))
        (stored-lambda (oref this lambda-function-that-only-returns-t-or-nil-depending-on-node-execution)))
    (when decl-config-print-execution-status-messages
      (print (concat "Executing decl-node: "
                     (prin1-to-string (oref this keyword-name)))))

    (if (eq execution-status :null)
        (if decl-config-fail-at-errors
            (let ((stored-lambda-return-value nil))
              (setq stored-lambda-return-value (funcall stored-lambda))
              (if stored-lambda-return-value
                  (oset this execution-status :successful)
                (oset this execution-status :failed-via-returning-nil)))
          (let ((stored-lambda-return-value nil))
            (unwind-protect
                (condition-case err
                    (setq stored-lambda-return-value
                          (funcall stored-lambda))
                  (error
                   (progn
                     (setq stored-lambda-return-value :failed-via-throwing-error)
                     (oset this execution-error-message (error-message-string err)))))
              (oset this execution-status (if (eq stored-lambda-return-value nil)
                                              :failed-via-returning-nil
                                            (if (eq :failed-via-throwing-error stored-lambda-return-value)
                                                stored-lambda-return-value
                                              :successful))))))
      (error "Attempting to execute a decl--node that has already been executed!"))))

(defun decl--decl--block--solve--mark-as-not-executable-recursively (vertex plist-of-nodes directed-graph-from-dependencies-to-nodes directed-graph-from-nodes-to-dependencies &optional failure-status)
  "vertex is a decl--node."
  (let ((e-keyword (oref vertex keyword-name)))
    (cl-dolist (dependent-node-keyword (plist-get
                                        directed-graph-from-dependencies-to-nodes
                                        e-keyword))
      (let ((ee (plist-get plist-of-nodes dependent-node-keyword)))
        (when (eq (oref ee execution-status) :null)
          (oset ee
                execution-status (if failure-status failure-status :failed-via-failed-dependency))
          (decl--decl--block--solve--mark-as-not-executable-recursively ee plist-of-nodes directed-graph-from-dependencies-to-nodes directed-graph-from-nodes-to-dependencies failure-status))
        )))) ;; End of defun

(cl-defmethod decl--decl--block--solve ((this decl--block))
  (decl--decl--block--generate-data-structures-and-results this)
  (when decl-config-print-execution-status-messages
    (print (concat "Loading decl-block '"
                   (prin1-to-string (oref this keyword-name))
                   "' . . .")))

  (let ((plist-of-nodes
         (decl--decl--block--access-item-from-generated-data-structures-and-results this :plist-of-nodes))
        (generated-data-structures-and-results (oref this generated-data-structures-and-results))
        (directed-graph-from-dependencies-to-nodes
         (decl--decl--block--access-item-from-generated-data-structures-and-results
          this :directed-graph-from-dependencies-to-nodes))
        (directed-graph-from-nodes-to-dependencies
          (decl--decl--block--access-item-from-generated-data-structures-and-results
           this :directed-graph-from-nodes-to-dependencies)))

    (let ((non-existent-constraint-symbols (decl--decl--block--find-non-existent-dependencies this)))
      (cl-dolist (e non-existent-constraint-symbols)
        (oset
         this nodes
         (cons (decl--node (decl--generate-increasing-number-string)
                           :keyword-name e
                           :lambda-function-that-only-returns-t-or-nil-depending-on-node-execution (lambda () "Dummy nil function." nil))
               (oref this nodes)))
        (decl--plist-put!
         generated-data-structures-and-results
         :plist-of-nodes
         (decl--plist-put!
          plist-of-nodes
          e
          (car (oref this nodes))))
        (decl--plist-put! directed-graph-from-nodes-to-dependencies e nil))
      (let ((symbols-of-nodes-that-have-non-existent-constraints
             (decl--decl--block--keyword-names-of-nodes-with-non-existent-constraints this))
            (sccs (decl--tarjan-strongly-connected-components-algorithm-for-plist-based-digraph-consisting-of-eq-able-elements
                   directed-graph-from-nodes-to-dependencies))
            (circular-dependent-node-symbols nil))
        (cl-dolist (e sccs)
          (when (> (length e) 1)
            (cl-dolist (e2 e)
              (decl-cons! circular-dependent-node-symbols (plist-get e2 :value)))))
        (let ((nodes (oref this nodes)))
          (cl-dolist (e nodes)
            (when (memq (oref e keyword-name) non-existent-constraint-symbols)
              (when (eq :null (oref e execution-status))
                (oset e execution-status :non-existent-constraint))))
          (cl-dolist (e nodes)
            (when (memq (oref e keyword-name) symbols-of-nodes-that-have-non-existent-constraints)
              (when (eq :null (oref e execution-status))
                (oset e execution-status :depends-on-non-existent-constraint)
                (decl--decl--block--solve--mark-as-not-executable-recursively e plist-of-nodes directed-graph-from-dependencies-to-nodes directed-graph-from-nodes-to-dependencies :depends-on-non-existent-constraint))))
          (cl-dolist (e nodes)
            (when (or
                   (memq (oref e keyword-name) circular-dependent-node-symbols)

                   ;; The next test is needed since strongly connected components
                   ;; of size one may or may not indicate a cycle. This library
                   ;; assumes that all nodes within a strongly connected component
                   ;; of size 2 or greater are in a cyclical relationship with
                   ;; each other.
                   (memq (oref e keyword-name) (oref e keyword-names-of-dependencies)))
              (when (eq :null (oref e execution-status))
                (oset e execution-status :involved-in-cyclical-relationship)
                (decl--decl--block--solve--mark-as-not-executable-recursively e plist-of-nodes directed-graph-from-dependencies-to-nodes directed-graph-from-nodes-to-dependencies :involved-in-cyclical-relationship))))
          (let ((decl-num-iter 0))
            (while (and (not (decl--decl--block--has-fate-been-determined this))
                        (not (> decl-num-iter 0)))
              (cl-incf decl-num-iter)
              (cl-dolist (node nodes)
                ;; Final work done here
                (when (eq (oref node execution-status) :null)
                  (setq decl-num-iter 0)
                  (when (eq (oref node keyword-names-of-dependencies) nil)
                    (decl--decl--node--execute node)
                    (if (eq :successful (oref node execution-status))
                        (let ((e-keyword (oref node keyword-name)))
                          (cl-dolist (dependent-node-keyword (plist-get
                                                           directed-graph-from-dependencies-to-nodes
                                                           e-keyword))
                            (let ((ee (plist-get plist-of-nodes dependent-node-keyword)))
                              (oset ee
                                    keyword-names-of-dependencies
                                    (-reject (lambda (x) (eq x e-keyword)) (oref ee keyword-names-of-dependencies)))
                              )))
                      (decl--decl--block--solve--mark-as-not-executable-recursively node plist-of-nodes directed-graph-from-dependencies-to-nodes directed-graph-from-nodes-to-dependencies))
                    ))))) ; End of while of execution of node
          ))))

  (when decl-config-print-execution-status-messages
    (print (concat "Decl-block '"
                   (prin1-to-string (oref this keyword-name))
                   "' solved!"))))

;; Functions that might interact with user by throwing an error
(defun decl--decl-block-keyword-name--type-check (decl-block-keyword-name)
  (unless (keywordp decl-block-keyword-name)
    (error "DECL-BLOCK-KEYWORD-NAME must be of the type keyword")))

(defun decl--decl-node-keyword-name--type-check (decl-node-keyword-name)
  (unless (keywordp decl-node-keyword-name)
    (error "DECL-NODE-KEYWORD-NAME must be of the type keyword")))

(defun decl--keyword-uniqueness-test (k)
  (unless decl-config-allow-duplicate-keyword-name-usage
    (when (gethash k decl--keyword-database)
      (error "Keywords that name 'decl-block' or 'decl-node' instances must be
unique"))))

(defun decl--attempt-to-store-decl-block (k v)
  (if decl-config-allow-decl-blocks-to-be-overwritten
      (decl--plist-put! decl--decl-block-holder k v)
    (if (not (plist-get decl--decl-block-holder k))
        (decl--plist-put! decl--decl-block-holder k v)
      (error
       (concat
        "There is already a decl-block referred to by the keyword '"
        (prin1-to-string k)
        "'.")))))

;; Public functions

;;;###autoload
(defun decl-block (decl-block-keyword-name)
  "Create new 'decl-block' instance that is managed by library.

DECL-BLOCK-KEYWORD-NAME must be a keyword.

\(decl-block decl-block-keyword-name)"
  (decl--decl-block-keyword-name--type-check decl-block-keyword-name)

  (decl--keyword-uniqueness-test decl-block-keyword-name)

  (decl--attempt-to-store-decl-block
   decl-block-keyword-name
   (decl--block (decl--generate-increasing-number-string)
                :keyword-name decl-block-keyword-name)))

;;;###autoload
(defun decl-node (decl-node-keyword-name
                  decl-block-keyword-name
                  lambda-function-that-only-returns-t-or-nil-depending-on-node-execution
                  &optional dependencies)
  "Creates a new 'decl-node' instance that is stored within a 'decl-block'.

DECL-NODE-KEYWORD-NAME must be a keyword.

DECL-BLOCK-KEYWORD-NAME must be a keyword.

LAMBDA-FUNCTION-THAT-ONLY-RETURNS-T-OR-NIL-DEPENDING-ON-NODE-EXECUTION (self-explanatory).

DEPENDENCIES must be a list of keywords.

\(decl-node decl-node-keyword-name decl-block-keyword-name dependencies)"
  (decl--decl-node-keyword-name--type-check decl-node-keyword-name)
  (decl--decl-block-keyword-name--type-check decl-block-keyword-name)
  (unless (functionp lambda-function-that-only-returns-t-or-nil-depending-on-node-execution)
    (error "LAMBDA-FUNCTION-THAT-ONLY-RETURNS-T-OR-NIL-DEPENDING-ON-NODE-EXECUTION must be a lambda function"))

  (decl--keyword-uniqueness-test decl-node-keyword-name)

  (unless (plist-member decl--decl-block-holder decl-block-keyword-name)
    (error "Attempting to create a 'decl-node' for a 'decl-block' that does not exist"))

  (let ((decl-block-of-interest (plist-get decl--decl-block-holder decl-block-keyword-name)))
    (when (memq decl-node-keyword-name
                (-map (lambda (x) "Gets keyword-name from decl--node." (oref x keyword-name))
                      (oref decl-block-of-interest nodes)))
      (unless decl-config-allow-decl-nodes-to-be-overwritten
        (error "Attempted to create a node using a keyword that is already used to refer to a node that is referring to another node with the existing decl-block!"))

      (oset decl-block-of-interest nodes (-remove (lambda (x) (eq decl-node-keyword-name (oref x keyword-name))) (oref decl-block-of-interest nodes))))

    (when dependencies
      (if (listp dependencies)
          (if (-every? (lambda (x) (keywordp x)) dependencies)
              (unless (eq (length (-uniq dependencies)) (length dependencies))
                (error "All members of DEPENDENCIES must be unique!"))
            (error "All members of DEPENDENCIES must be keywords!"))
        (error "Argument DEPENDENCIES must be a list!")))

    (oset decl-block-of-interest nodes
          (cons (decl--node (decl--generate-increasing-number-string)
                            :keyword-name decl-node-keyword-name
                            :lambda-function-that-only-returns-t-or-nil-depending-on-node-execution lambda-function-that-only-returns-t-or-nil-depending-on-node-execution
                            :keyword-names-of-dependencies dependencies)
                (oref decl-block-of-interest nodes)))))

;;;###autoload
(defun decl-solve (decl-block-keyword-name)
  "Attempt to execute the lambda functions stored within the 'decl-node' instances
stored within the 'decl-block' referred to by the given DECL-BLOCK-KEYWORD-NAME.

DECL-BLOCK-KEYWORD-NAME must be a keyword.

\(decl-solve decl-block-keyword-name)"
  (decl--decl-block-keyword-name--type-check decl-block-keyword-name)
  (if (plist-member decl--decl-block-holder decl-block-keyword-name)
      (decl--decl--block--solve (plist-get decl--decl-block-holder decl-block-keyword-name))
    (error "Attempting to execute a decl-block that doesn't exist!"))
  )

;;;###autoload
(defun decl-report (decl-block-keyword-name)
  "Reports on the solving of any 'decl-block' via 'decl-solve' in an org-mode buffer.

DECL-BLOCK-KEYWORD-NAME must be a keyword.

\(decl-report decl-block-keyword-name)"
  (interactive "SEnter DECL-BLOCK-KEYWORD-NAME (must be a keyword): ")
  (if (keywordp decl-block-keyword-name)
      (progn
        (decl--decl-block-keyword-name--type-check decl-block-keyword-name)
        (let ((buffer-name-status-report
               (concat "decl-block: '" (symbol-name decl-block-keyword-name) "' Status Report.org")))
          (with-current-buffer
              (get-buffer-create buffer-name-status-report)
            ;; Mark buffer contents and delete the buffer contents
            (mark-whole-buffer)
            (delete-region (region-beginning) (region-end))

            ;; Insert generated report into buffer
            (insert
             (if (plist-member decl--decl-block-holder decl-block-keyword-name)
                 (let ((decl-exec-block (plist-get decl--decl-block-holder decl-block-keyword-name))
                       (null-nodes nil)
                       (non-existent-nodes nil)
                       (non-existent-dependencies-nodes nil)
                       (cyclical-relationship-nodes nil)
                       (failed-dependency-nodes nil)
                       (failed-error-nodes nil)
                       (failed-nil-nodes nil)
                       (successful-nodes nil))
                   (let ((nodes (oref decl-exec-block nodes)))
                     (cl-dolist (node nodes)
                       (let ((node-name (oref node keyword-name)))
                         (cond
                          ((eq (oref node execution-status) :null) (decl-cons! null-nodes node-name))
                          ((eq (oref node execution-status) :non-existent-constraint) (decl-cons! non-existent-nodes node-name))
                          ((eq (oref node execution-status) :depends-on-non-existent-constraint) (decl-cons! non-existent-dependencies-nodes node-name))
                          ((eq (oref node execution-status) :involved-in-cyclical-relationship) (decl-cons! cyclical-relationship-nodes node-name))
                          ((eq (oref node execution-status) :failed-via-failed-dependency) (decl-cons! failed-dependency-nodes node-name))
                          ((eq (oref node execution-status) :failed-via-throwing-error) (decl-cons! failed-error-nodes node-name))
                          ((eq (oref node execution-status) :failed-via-returning-nil) (decl-cons! failed-nil-nodes node-name))
                          ((eq (oref node execution-status) :successful) (decl-cons! successful-nodes node-name))))))

                   (let ((to-return (concat "* " buffer-name-status-report "\n")))
                     (decl--concat! to-return "** Nodes successfully executed\n")

                     (cl-dolist (e successful-nodes)
                       (decl--concat! to-return (concat "*** " (prin1-to-string e) "\n")))

                     (decl--concat! to-return "** Nodes failing from returning nil\n")

                     (cl-dolist (e failed-nil-nodes)
                       (decl--concat! to-return (concat "*** " (prin1-to-string e) "\n")))

                     (decl--concat! to-return "** Nodes failing from throwing an error\n")

                     (cl-dolist (e failed-error-nodes)
                       (decl--concat! to-return (concat "*** " (prin1-to-string e) "\n"))
                       (decl--concat! to-return (concat "**** " "Error Message String" "\n"))
                       (decl--concat! to-return (concat (oref (plist-get (decl--decl--block--access-item-from-generated-data-structures-and-results decl-exec-block :plist-of-nodes) e) execution-error-message)
                                                        "\n")))

                     (decl--concat! to-return "** Nodes failing because of failing dependencies\n")

                     (cl-dolist (e failed-dependency-nodes)
                       (decl--concat! to-return (concat "*** " (prin1-to-string e) "\n")))

                     (decl--concat! to-return "** Nodes involved in cyclical relationships\n")

                     (cl-dolist (e cyclical-relationship-nodes)
                       (decl--concat! to-return (concat "*** " (prin1-to-string e) "\n")))

                     (decl--concat! to-return "** Nodes relying on non-existent dependencies\n")

                     (cl-dolist (e non-existent-dependencies-nodes)
                       (decl--concat! to-return (concat "*** " (prin1-to-string e) "\n")))

                     (decl--concat! to-return "** Non-existent dependencies\n")

                     (cl-dolist (e non-existent-nodes)
                       (decl--concat! to-return (concat "*** " (prin1-to-string e) "\n")))

                     (decl--concat! to-return "** Null nodes\n")

                     (cl-dolist (e null-nodes)
                       (decl--concat! to-return (concat "*** " (prin1-to-string e) "\n")))

                     to-return))

               (error "Attempted to refer to a decl-block that does not exist")))

            ;; These following lines make the newly created buffer an org-mode buffer and then indent the buffer accordingly
            (org-mode))

          (switch-to-buffer (get-buffer buffer-name-status-report)))) ; End of TRUE condition of keywordp conditional
    (message "DECL-BLOCK-KEYWORD-NAME must be of the type keyword")))

;;;###autoload
(defun decl-wrap (decl-library-usage-lambda)
  "Place your usage of the decl library within a lambda function and pass it to
decl-wrap to avoid retaining state. For example, if you want to define a build
process using this library, like using a makefile, you can use wrap your code
within a decl-wrap block to avoid storing data time each run your build process."
  (if (functionp decl-library-usage-lambda)
      (let ((decl--decl-block-holder nil)
            (decl--keyword-database (make-hash-table :test 'eq)))
        (funcall decl-library-usage-lambda))
    (error "The function decl-wrap only takes a function as an argument!")))

(provide 'decl)

;;; decl.el ends here
