;;; keymap-utils.el --- Keymap utilities  -*- lexical-binding:t -*-

;; Copyright (C) 2008-2023 Jonas Bernoulli

;; Author: Jonas Bernoulli <jonas@bernoul.li>
;; Homepage: https://github.com/tarsius/keymap-utils
;; Keywords: convenience extensions
;; Package-Version: 20230213.1152
;; Package-Commit: 1806ff73b0a68e84234d65c7d08a18cf3f0d29e5

;; Package-Requires: ((emacs "25.1") (compat "29.1.3.4"))

;; SPDX-License-Identifier: GPL-3.0-or-later

;; This file is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published
;; by the Free Software Foundation, either version 3 of the License,
;; or (at your option) any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this file.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides some utilities useful for inspecting and
;; modifying keymaps.

;;; Code:

(require 'cl-lib)
(require 'compat)

;;; Predicates

(defun kmu-keymap-variable-p (object)
  "Return t if OBJECT is a symbol whose variable definition is a keymap."
  (and (symbolp object)
       (boundp  object)
       (keymapp (symbol-value object))))

(defun kmu-keymap-list-p (object)
  "Return t if OBJECT is a list whose first element is the symbol `keymap'."
  (and (listp   object)
       (keymapp object)))

(defun kmu-prefix-command-p (object)
  "Return non-nil if OBJECT is a symbol whose function definition is a keymap.
The value returned is the keymap stored as OBJECT's variable
definition or else the variable which holds the keymap."
  (and (symbolp object)
       (fboundp object)
       (keymapp (symbol-function object))
       (if (and (boundp  object)
                (keymapp (symbol-value object)))
           (symbol-value object)
         (kmu-keymap-variable (symbol-function object)))))

(defun kmu-full-keymap-p (object)
  "Return t if OBJECT is a full keymap.
A full keymap is a keymap whose second element is a char-table."
  (if (kmu-prefix-command-p object)
      (char-table-p (cadr (symbol-function object)))
    (and (keymapp object)
         (char-table-p (cadr object)))))

(defun kmu-sparse-keymap-p (object)
  "Return t if OBJECT is a sparse keymap.
A sparse keymap is a keymap whose second element is not a char-table."
  (if (kmu-prefix-command-p object)
      (not (char-table-p (cadr (symbol-function object))))
    (and (keymapp object)
         (not (char-table-p (cadr object))))))

(defun kmu-menu-binding-p (object)
  "Return t if OBJECT is a menu binding."
  (and (listp object)
       (or (stringp (car object))
           (eq (car object) 'menu-item))))

(defun kmu-char-table-event-p (keymap event)
  "Return t if EVENT is or would be stored in KEYMAP's char-table.
If KEYMAP is a sparse keymap or, for a full keymap, if EVENT
is or would be stored outside its char-table, then return nil.
EVENT should be a character or symbol."
  (and (not (symbolp event))
       (char-table-p (cadr keymap))
       (ignore-errors (and (char-table-range (cadr keymap) event) t))))

;;; Key Lookup

(defun kmu-lookup-local-key ( keymap key
                              &optional accept-default no-remap position)
  "In KEYMAP, look up key sequence KEY.  Return the definition.

Unlike `keymap-lookup' (which see) this doesn't consider bindings
made in KEYMAP's parent keymap."
  (keymap-lookup (kmu--strip-keymap keymap)
                 key accept-default no-remap position))

(defun kmu-lookup-parent-key ( keymap key
                              &optional accept-default no-remap position)
  "In KEYMAP's parent keymap, look up key sequence KEY.
Return the definition.

Unlike `keymap-lookup' (which see) this only considers bindings
made in KEYMAP's parent keymap and recursively all parent keymaps
of keymaps events in KEYMAP are bound to."
  (keymap-lookup (kmu--collect-parmaps keymap)
                 key accept-default no-remap position))

(defun kmu--strip-keymap (keymap)
  "Return a copy of KEYMAP with all parent keymaps removed.

This not only removes the parent keymap of KEYMAP but also recursively
the parent keymap of any keymap a key in KEYMAP is bound to."
  (cl-labels ((strip-keymap (keymap)
                (set-keymap-parent keymap nil)
                (cl-loop for _key being the key-code of keymap
                         using (key-binding binding) do
                         (and (keymapp binding)
                              (not (kmu-prefix-command-p binding))
                              (strip-keymap binding)))
                keymap))
    (strip-keymap (copy-keymap keymap))))

(defun kmu--collect-parmaps (keymap)
  "Return a copy of KEYMAP with all local bindings removed."
  (cl-labels ((collect-parmaps (keymap)
                (let ((new-keymap (make-sparse-keymap)))
                  (set-keymap-parent new-keymap (keymap-parent keymap))
                  (set-keymap-parent keymap nil)
                  (cl-loop for key being the key-code of keymap
                           using (key-binding binding) do
                           (and (keymapp binding)
                                (not (kmu-prefix-command-p binding))
                                (define-key new-keymap (vector key)
                                            (collect-parmaps binding))))
                  new-keymap)))
    (collect-parmaps (copy-keymap keymap))))

;;; Keymap Variables

;;;###autoload
(defun kmu-current-local-mapvar (&optional interactive)
  "Return the variable bound to the current local keymap.
Interactively also show the variable in the echo area.
\n(fn)"
  (interactive (list t))
  (let ((mapvar (kmu-keymap-variable (current-local-map))))
    (when interactive
      (message (if mapvar
                   (symbol-name mapvar)
                 "Cannot determine current local keymap variable")))
    mapvar))

(defun kmu-keymap-variable (keymap &rest exclude)
  "Return a dynamically-bound symbol whose value is KEYMAP.

Comparison is done with `eq'.  If there are multiple variables
whose value is KEYMAP it is undefined which is returned.

Ignore symbols listed in optional EXCLUDE.  Use this to prevent a
symbol from being returned which is dynamically bound to KEYMAP."
  (and (keymapp keymap)
       (catch 'found
         (mapatoms (lambda (sym)
                     (and (not (memq sym exclude))
                          (boundp sym)
                          (eq (symbol-value sym) keymap)
                          (throw 'found sym)))))))

(defun kmu-keymap-prefix-command (keymap)
  "Return a dynamically-bound symbol whose function definition is KEYMAP.

Comparison is done with `eq'.  If there are multiple symbols
whose function definition is KEYMAP it is undefined which is
returned."
  (and (keymapp keymap)
       (catch 'found
         (mapatoms (lambda (sym)
                     (and (fboundp sym)
                          (eq (symbol-function sym) keymap)
                          (throw 'found sym)))))))

(defun kmu-keymap-parent (keymap &optional need-symbol &rest exclude)
  "Return the parent keymap of KEYMAP.

If a dynamically-bound variable exists whose value is KEYMAP's
parent keymap return that.  Otherwise if KEYMAP does not have
a parent keymap return nil.  Otherwise if KEYMAP has a parent
keymap but no variable is bound to it return the parent keymap,
unless optional NEED-SYMBOL is non-nil in which case nil is
returned.

Comparison is done with `eq'.  If there are multiple variables
whose value is the keymap it is undefined which is returned.

Ignore symbols listed in optional EXCLUDE.  Use this to prevent
a symbol from being returned which is dynamically bound to the
parent keymap."
  (and-let* ((parent (keymap-parent keymap)))
    (or (apply #'kmu-keymap-variable parent exclude)
        (and (not need-symbol) parent))))

(defun kmu-mapvar-list (&optional exclude-prefix-commands)
  "Return a list of all keymap variables.

If optional EXCLUDE-PREFIX-COMMANDS is non-nil exclude all
variables whose variable definition is also the function
definition of a prefix command."
  (let ((prefix-commands
         (and exclude-prefix-commands
              (kmu-prefix-command-list))))
    (cl-loop for symbol being the symbols
             when (kmu-keymap-variable-p symbol)
             when (not (memq symbol prefix-commands))
             collect symbol)))

(defun kmu-prefix-command-list ()
  "Return a list of all prefix commands."
  (cl-loop for symbol being the symbols
           when (kmu-prefix-command-p symbol)
           collect symbol))

(defun kmu-read-mapvar (prompt)
  "Read the name of a keymap variable and return it as a symbol.
Prompt with PROMPT.  A keymap variable is one for which
`kmu-keymap-variable-p' returns non-nil."
  (let ((mapvar (intern (completing-read prompt obarray
                                         #'kmu-keymap-variable-p t nil nil))))
    (if (eq mapvar '##)
        (error "No mapvar selected")
      mapvar)))

;;; Editing Keymaps

(defmacro kmu-edit-keymap (mapvar feature &rest args)
  "Define all keys in ARGS in the keymap stored in MAPVAR.

MAPVAR is a variable whose value is a keymap.  If FEATURE is nil,
then that keymap is modified immediately.  If FEATURE is a symbol
or string, then the keymap isn't modified until after that
library/file has been loaded.  The FEATURE has to be specified if
it isn't always loaded and MAPVAR does not exist until after it
has been loaded.

The simplest form ARGS can take is (KEY DEF ...), but see below
for details.

Each KEY is a string that satisfies `key-valid-p'.

Each DEF can be anything that can be a key's definition according
to `keymap-set'.

A DEF can also be the symbol `:remove' in which case the KEY's
existing definition (if any) is removed (not just unset) from
KEYMAP using `keymap-unset' with t as the value of the REMOVE
argument.

The symbol `>' is a synonym for `:remove', which is useful when
you want to move a binding from one key to another and make that
explicit:

  (keymap-edit foo-mode-map foo
    \"a\" > \"b\" moved-command)

A DEF can also be the symbol `=' in which case the binding of the
preceding KEY is *not* changed.  This is useful when you want to
make it explicit that an existing binding is kept when creating a
new binding:

  (keymap-edit foo-mode-map foo
    \"a\" = \"b\" copied-command)

Finally the symbol `_' can appear anywhere in ARGS and this macro
just treats it as whitespace.  This is useful because it allows
aligning keys and commands without having to fight the automatic
indentation mechanism:

  (keymap-edit foo-mode-map foo
    \"a\" > \"b\" moved-command
    _     \"c\" newly-bound-command)"
  (declare (indent 2))
  (let (body)
    (while args
      (let ((key (pop args)))
        (unless (eq key '_)
          (let ((def (pop args)))
            (while (eq def '_)
              (setq def (pop args)))
            (cl-case def
              (=)
              ((> :remove)
               (unless (cl-member-if (lambda (form)
                                       (and (eq (car form) 'keymap-set)
                                            (equal (car (cddr form)) key)))
                                     body)
                 (push `(keymap-unset ,mapvar ,key t) body)))
              (t
               (push `(keymap-set ,mapvar ,key ,def) body)))))))
    (if feature
        `(with-eval-after-load ',feature
           (defvar ,mapvar)
           ,@(nreverse body))
      (macroexp-progn (nreverse body)))))

;;; Keymap Mapping

(defvar kmu-char-range-minimum 9)

(defun kmu-keymap-bindings (keymap &optional prefix)
  "Return a list of all event sequence bindings in KEYMAP.

Each element has the form (KEY DEF), where KEY is the event
sequence that is bound (a vector), and DEF is the definition it
is bound to.

When the definition of an event is another keymap list then
recursively build up an event sequence and instead of returning
an element with the initial event and its definition once, return
an element for each event sequence and the definition it is bound
to.

The last event in an event sequence may be a character range.
\n(fn KEYMAP)"
  (let ((min (1- kmu-char-range-minimum))
        v vv)
    (map-keymap-internal
     (lambda (key def)
       (if (kmu-keymap-list-p def)
           (setq v (append (kmu-keymap-bindings def (list key)) v))
         (push (list key def) v)))
     keymap)
    (while v
      (pcase-let ((`(,key ,def) (pop v)))
        (if (vectorp key)
            (push (list key def) vv)
          (let (beg end mem)
            (if (consp key)
                (setq beg (car key) end (cdr key))
              (when (integerp key)
                (setq beg key end key)
                (while (and (setq mem (car (cl-member (1- beg) v :key #'car)))
                            (equal (cadr mem) def))
                  (cl-decf beg)
                  (setq v (remove mem v)))
                (while (and (setq mem (car (cl-member (1+ end) v :key #'car)))
                            (equal (cadr mem) def))
                  (cl-incf end)
                  (setq v (remove mem v)))))
            (cond ((or (not beg) (eq beg end))
                   (push (list key def) vv))
                  ((< (- end beg) min)
                   (cl-loop for key from beg to end
                            do (push (list key def) vv)))
                  (t
                   (push (list (cons beg end) def) vv)))))))
    (mapcar (lambda (binding)
              (pcase-let ((`(,key ,def) binding))
                (list (vconcat prefix (if (vectorp key) key (vector key)))
                      def)))
            vv)))

(defun kmu-map-keymap (function keymap)
  "Call FUNCTION once for each event sequence binding in KEYMAP.

FUNCTION is called with two arguments: the event sequence that is
bound (a vector), and the definition it is bound to.

When the definition of an event is another keymap list then
recursively build up an event sequence and instead of calling
FUNCTION with the initial event and its definition once, call
FUNCTION once for each event sequence and the definition it is
bound to.

The last event in an event sequence may be a character range."
  (mapc (lambda (e) (apply function e)) (kmu-keymap-bindings keymap)))

(defun kmu-keymap-definitions (keymap &optional nomenu nomouse)
  "Return a list of all definitions in KEYMAP.

Each element has the form (DEF KEY...), where eacho KEY is an
event sequence (a vector) that is bound to DEF.

When the definition of an event is another keymap list then
recursively build up an event sequence and instead of returning
an element with the initial event and its definition once, return
an element for each event sequence and the definition it is bound
to.

The last event in an event sequence may be a character range.
\n(fn KEYMAP)"
  (let (bindings)
    (kmu-map-keymap (lambda (key def)
                      (cond ((and nomenu (kmu-menu-binding-p def)))
                            ((and nomouse (mouse-event-p (aref key 0))))
                            ((if-let ((elt (assq def bindings)))
                                 (setcdr elt (cons key (cdr elt)))
                               (push (list def key) bindings)))))
                    keymap)
    bindings))

;;; _
(provide 'keymap-utils)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; keymap-utils.el ends here
