;;; traad.el --- emacs interface to the traad refactoring server. -*- lexical-binding: t -*-
;;
;; Copyright (c) 2012-2017 Austin Bingham
;;
;; Author: Austin Bingham <austin.bingham@gmail.com>
;; Version: 3.1.1
;; Package-Version: 20180730.48
;; Package-Commit: 98e23363b7e8a590a2f55976123a8c3da75c87a5
;; URL: https://github.com/abingham/traad
;; Package-Requires: ((dash "2.13.0") (deferred "0.3.2") (popup "0.5.0") (request "0.2.0") (request-deferred "0.2.0") (virtualenvwrapper "20151123") (f "0.20.0") (bind-map "1.1.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;; Description:
;;
;; traad is a JSON+HTTP server built around the rope refactoring library. This
;; file provides an API for talking to that server - and thus to rope - from
;; emacs lisp. Or, put another way, it's another way to use rope from emacs.
;;
;; For more details, see the project page at
;; https://github.com/abingham/traad.
;;
;; Installation:
;;
;; Copy traad.el to some location in your emacs load path. Then add
;; "(require 'traad)" to your emacs initialization (.emacs,
;; init.el, or something).
;;
;; Example config:
;;
;;   (require 'traad)
;;
;;; License:
;;
;; Permission is hereby granted, free of charge, to any person
;; obtaining a copy of this software and associated documentation
;; files (the "Software"), to deal in the Software without
;; restriction, including without limitation the rights to use, copy,
;; modify, merge, publish, distribute, sublicense, and/or sell copies
;; of the Software, and to permit persons to whom the Software is
;; furnished to do so, subject to the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Code:

(require 'cl)
(require 'f)
(require 'dash)
(require 'deferred)
(require 'json)
(require 'popup)
(require 'request)
(require 'request-deferred)
(require 'virtualenvwrapper)

(defcustom traad-save-unsaved-buffers 'ask
  "What to do when there are unsaved buffers before a refactoring.

Options are:

`ask'
      Ask the user if buffers should be saved.

`always'
     Always save modified buffers without asking.

`never'
     Never save unmodified buffers."
  :type '(choice (const :tag "Ask the user" ask)
                 (const :tag "Always save changes" always)
                 (const :tag "Never save changes" never))
  :risky t)

(defgroup traad nil
  "A Python refactoring tool."
  :group 'tools
  :group 'programming)

(defconst traad-host "127.0.0.1"
  "The host on which the traad server is running.")

(defcustom traad-server-program nil
  "The name of the traad server program.

If this is nil (default) then the server found in the
`traad-environment-name' virtual environment is used."
  :type '(repeat string)
  :group 'traad)

(defcustom traad-server-args (list "-V" "2")
  "Parameters passed to the traad server before the directory name."
  :type '(repeat string)
  :group 'traad)

(defcustom traad-debug nil
  "Whether debug info should be generated."
  :type '(boolean)
  :group 'traad)

(defconst traad-required-protocol-version 3
  "The required protocol version.")

(defcustom traad-environment-name "traad"
  "The name of the Python environment containing the traad server to use.

When `traad-install-server' runs, it uses this variable to
determine where to install the server.

When `traad-server-program' is nil, this variable is used to
determine where the traad server program is installed.

This name is used by `virtualenvwrapper.el' to locate the
virtual environment into which the desired version of traad is
installed.  If you have multiple traads in different virtual
environment (e.g. one for Python 2 and one for Python 3) then you
may need to dynamically alter this variable to select the one you
want to use."
  :group 'traad)

(defun traad--server-command ()
  "Get the command to launch the server."
  (or traad-server-program
      (venv-with-virtualenv
       traad-environment-name
       (let ((script (funcall 'executable-find "traad")))
         (if script
             (list script)
           (error "No traad executable found"))))))

;; represents a single server instance. We may be running many for different
;; projects.
(cl-defstruct traad--server
  (host "" :read-only t)
  (proc nil :read-only t))

(defun traad--open (directory)
  "Open a traad server in `directory'.

Returns `traad--server' struct.
"
  (let ((proc-buff (get-buffer-create (format "*traad-server: %s*" directory))))
    (with-current-buffer proc-buff
      (erase-buffer)
      (let* ((program (traad--server-command))
             (program (if (listp program) program (list program)))
             (args (append traad-server-args
                           (list "-p" "0")
                           (list directory)))
             (program+args (append program args))
             (default-directory "~/")
             (proc (apply #'start-process "traad-server" proc-buff program+args))
             (cont 1)
             (server nil))
        (while cont
          (set-process-query-on-exit-flag proc nil)
          (accept-process-output proc 0 100 t)
          (cond
           ((string-match "^Listening on http://.*:\\\([0-9]+\\\)/$" (buffer-string))
            (let ((server-host (concat traad-host ":" (match-string 1 (buffer-string)))))
              (setq server (make-traad--server :host server-host :proc proc)
                    cont nil)))
           (t
            (incf cont)
            (when (< 30 cont) ; timeout after 3 seconds
              ;; Kill the process so we don't accumulate idle processes.
              (condition-case nil
                  ;; Just kill the process, not the buffer. The buffer could
                  ;; be useful for diagnostics on why there was a timeout.
                  (kill-process proc)
                (error nil))
              (error "Server timeout.")))))
        server))))

(defun traad--check-protocol-version (path)
  (deferred:$

    (traad--deferred-request path "/protocol_version")

    (deferred:nextc it
      (lambda (req)
        (let ((protocol-version (assoc-default
                                 'protocol-version
                                 (request-response-data req))))
          (if (eq protocol-version traad-required-protocol-version)
              (message "Supported protocol version detected: %s" protocol-version)
            (error "Server protocol version is %s, but we require version %s"
                   protocol-version
                   traad-required-protocol-version)))))))

                                        ; TODO
;; (defun traad-add-cross-project (directory)
;;   "Add a cross-project to the traad instance."
;;   (interactive
;;    (list
;;     (read-directory-name "Directory:")))
;;   (traad-call 'add_cross_project directory))

                                        ; TODO
;; (defun traad-remove-cross-project (directory)
;;   "Remove a cross-project from the traad instance."
;;   (interactive
;;    (list
;;     (completing-read
;;      "Directory: "
;;      (traad-call 'cross_project_directories))))
;;   (traad-call 'remove_cross_project directory))

                                        ; TODO
;; (defun traad-get-cross-project-directories ()
;;   "Get a list of root directories for cross projects."
;;   (interactive)
;;   (traad-call 'cross_project_directories))

(defun traad--unredo (location idx)
  "Common implementation for undo and redo."
  (when (traad--all-changes-saved)
    (lexical-let ((data (list (cons "index" idx))))

      (deferred:$

        (traad--deferred-request
         (buffer-file-name)
         location
         :data data
         :type "POST")

        (deferred:nextc it
          (lambda (rsp)
            (let* ((response (request-response-data rsp))
                   (changesets (assoc-default 'changes response)))
              (-map
               (lambda (changeset)
                 (dolist (path (traad--change-set-to-paths changeset))
                   (let* ((root (traad--find-project-root path))
                          (full-path (expand-file-name (traad--join-path root path)))
                          (buff (get-file-buffer full-path)))
                     (if buff
                         (with-current-buffer buff
                           (revert-buffer :ignore-auto :no-confirm))))))
               changesets)))))))
  )

;;;###autoload
(defun traad-undo (idx)
  "Undo the IDXth change from the history. \
IDX is the position of an entry in the undo list (see: \
traad-history). This change and all that depend on it will be \
undone. \
Python-like negative indexing works here, so you can \
undo the most recent change by passing `-1' (the default value)."
  (interactive
   (list
    (read-number "Index: " -1)))
  (traad--unredo "/history/undo" idx))


;;;###autoload
(defun traad-redo (idx)
  "Redo the IDXth change from the history. \
IDX is the position of an entry in the redo list (see: \
traad-history). This change and all that depend on it will be \
redone. \
Python-like negative indexing works here, so you can \
redo the most recent undo by passing `-1' (the default value)."
  (interactive
   (list
    (read-number "Index: " -1)))
  (traad--unredo "/history/redo" idx))

(defun traad--update-history-buffer ()
  "Update the contents of the history buffer, creating it if \
necessary. Return the history buffer."
  (deferred:$

    (deferred:parallel
      (traad--deferred-request
       (buffer-file-name)
       "/history/view_undo")
      (traad--deferred-request
       (buffer-file-name)
       "/history/view_redo"))

    (deferred:nextc it
      (lambda (inputs)
        (let* ((undo (assoc-default 'history (request-response-data (elt inputs 0))))
               (redo (assoc-default 'history (request-response-data (elt inputs 1))))
               (buff (get-buffer-create "*traad-history*")))
          (set-buffer buff)
          (erase-buffer)
          (insert "== UNDO HISTORY ==\n")
          (if undo (insert (pp-to-string (traad--enumerate undo))))
          (insert "\n")
          (insert "== REDO HISTORY ==\n")
          (if redo (insert (pp-to-string (traad--enumerate redo))))
          buff)))))

;;;###autoload
(defun traad-display-history ()
  "Display undo and redo history."
  (interactive)
  (deferred:$
    (traad--update-history-buffer)
    (deferred:nextc it
      (lambda (buffer)
        (switch-to-buffer buffer)))))

(defun traad--history-info-core (location)
  "Display information on a single undo/redo operation."

  (deferred:$

    (traad--deferred-request
     (buffer-file-name)
     location)

    (deferred:nextc it
      (lambda (rsp)
        (let ((buff (get-buffer-create "*traad-change*"))
              (info (assoc-default 'info (request-response-data rsp))))
          (switch-to-buffer buff)
          (diff-mode)
          (erase-buffer)
          (insert "Description: " (cdr (assoc 'description info)) "\n"
                  "Time: " (number-to-string (cdr (assoc 'time info))) "\n"
                  "Change:\n"
                  (cdr (assoc 'full_change info))))))))

;;;###autoload
(defun traad-undo-info (i)
  "Get info on the I'th undo history."
  (interactive
   (list
    (read-number "Undo index: " -1)))
  (traad--history-info-core
   (concat "/history/undo_info/" (number-to-string i))))

;;;###autoload
(defun traad-redo-info (i)
  "Get info on the I'th redo history."
  (interactive
   (list
    (read-number "Redo index: " -1)))
  (traad--history-info-core
   (concat "/history/redo_info/" (number-to-string i))))

;;;###autoload
(defun traad-auto-import ()
  "Automatically add the necessary import for the current symbol.

Displays a list of potential imports - the user must select the
correct one."
  (interactive)

  (when (traad--all-changes-saved)

    (deferred:$
      (traad--deferred-request
       (buffer-file-name)
       "/auto_import/get_imports"
       :type "POST"
       :data (list (cons "path" (buffer-file-name))
                   (cons "offset" (traad--adjust-point (point)))))

      (deferred:nextc it
        (lambda (rsp)
          (let* ((buff (get-buffer-create "*traad-get-imports*"))
                 (data (request-response-data rsp))
                 (imports (assoc-default 'imports data))
                 (location (assoc-default 'location data))
                 (menu-entries
                  (sort
                   (mapcar
                    (lambda (import)
                      (format "from %s import %s"
                              (elt import 1)
                              (elt import 0)))
                    imports)
                   'string-lessp)))
            (if menu-entries
                (let ((selection (popup-menu*
                                  menu-entries
                                  :margin-left 1
                                  :margin-right 1
                                  )))
                  (save-excursion
                    (goto-line location)
                    (insert selection)
                    (insert "\n")))
              (message "No auto-import candidates (perhaps index is being built)"))))))))

;;;###autoload
(defun* traad-rename (new-name &key (docstrings t) (in-hierarchy t))
  "Rename the object at the current location.

Attempts to rename all occurrences of the object in the project.

Optional arguments `DOCSTRINGS' and `IN-HIERARCHY' set renaming
options:

  - `DOCSTRINGS' (default `t') specifies whether occurrences in
    comments/docstrings should be renamed. For example, let's say
    we're renaming a variable, `var_to_rename` and `DOCSTRINGS'
    is set to `nil':

    | var_to_rename = 'this is a string'                 # [1]
    |
    | some_variable = var_to_rename                      # [2]
    |
    | # This is an occurrence of `var-to-rename`         # [3]
    |
    | def some_function(input_var):
    |     '''Docstring that has `var_to_rename` in it.'''# [4]
    |     return input_var ** 2
    |
    | some_function(var_to_rename)                       # [5]

    Renaming `var_to_rename` to `new_var_name`, this would
    become:

    | new_var_name = 'this is a string'                  # [1]
    |
    | some_variable = new_var_name                       # [2]
    |
    | # This is an occurrence of `var-to-rename`         # [3]
    |
    | def some_function(input_var):
    |     '''Docstring that has `var_to_rename` in it.'''# [4]
    |     return input_var ** 2
    |
    | some_function(new_var_name)                        # [5]

    Note that [1], [2] & [5] were renamed, but [3] &
    [4] (occurrences in a comment and a docstring) were not
    renamed. If `DOCSTRINGS' were `t', [3] & [4] would have been
    renamed.

  - `IN-HIERARCHY' (default `t') specifies whether occurrences
    higher and lower in the hierarchy should be renamed. (In
    practise this means the same method in a subclass or
    superclass) For example, let's say you're renaming some
    method, `method_to_rename`, and `IN-HIERARCHY' is set to
    `nil':

    | class BaseClass(object):
    |     def method_to_rename():                        # [1]
    |         print('This is the super class.')
    |
    | class DerivedClass(BaseClass):
    |     def method_to_rename():                        # [2]
    |         print('This is the derived class.')

    Renaming `BaseClass.method_to_rename` to
    `BaseClass.new_name`, results in:

    | class BaseClass(object):
    |     def new_name():                                # [1]
    |         print('This is the super class.')
    |
    | class DerivedClass(BaseClass):
    |     def method_to_rename():                        # [2]
    |         print('This is the derived class.')

    The original method, [1], is renamed. Note that the override
    method in the subclass, [2], does not get renamed. If
    `IN-HIERARCHY' were set to `t', [2] would also be renamed.

Note that unsure occurrences will not be renamed. Rope may find
occurrences that it is unsure about, which are marked as
`unsure`. These will generally be wrong, so you don't want to
include them all. However, this means you may miss some
occurrences of the object. See the Rope documentation for more
details on the `unsure` parameter.
"
  (interactive
   (list
    (read-string (format "Rename `%s' to: " (thing-at-point 'symbol)))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/rename"
   :data (list (cons "name" new-name)
               (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point)))
               (cons "in_hierarchy" in-hierarchy)
               (cons "docs" docstrings))))

;;;###autoload
(defun traad-rename-advanced (new-name docstrings in-hierarchy)
  "Rename the thing at point, with advanced options."
  (interactive
   (list
    (read-string (format "Rename `%s' to: " (thing-at-point 'symbol)))
    (y-or-n-p "Rename in docstrings & comments? ")
    (y-or-n-p "Rename matching methods in hierarchy (superclass & subclass methods)? ")))
  (traad-rename new-name
                :docstrings docstrings
                :in-hierarchy in-hierarchy))

;;;###autoload
(defun traad-rename-module (new-name)
  "Rename the currently opened module.

Note that this renames the module associated with the current
buffer, NOT the module under point."
  (interactive
   (list
    (read-string (format "Rename `%s' to: "
                         (file-name-sans-extension
                          (file-name-nondirectory
                           (buffer-file-name)))))))
  (deferred:$
    (traad--fetch-perform
     (buffer-file-name)
     "/refactor/rename"
     :data (list (cons "name" new-name)
                 (cons "path" (buffer-file-name))))

    (deferred:nextc it
      (lambda (_)
        (let* ((dir-name (file-name-directory (buffer-file-name)))
               (new-name (expand-file-name (concat dir-name "/" new-name ".py"))))
          (kill-buffer (current-buffer))
          (switch-to-buffer (find-file new-name)))))))

;;;###autoload
(defun traad-move ()
  "Move the current object (DWIM).

Calls the correct form of `move` based on the type of thing at
the point."
  (interactive)
  (pcase (traad-thing-at (point))
    ('module (call-interactively 'traad-move-module))
    ('function (call-interactively 'traad-move-global))
    (_ (call-interactively 'traad-move-module))))


;;;###autoload
(defun traad-move-global (dest)
  "Move the object at the current location to file `DEST'.

Prompts for a `DEST' when called interactively."
  (interactive
   (list
    (read-file-name "Destination file: " nil nil "confirm")))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/move_global"
   :data (list (cons "dest" dest)
               (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-move-module (dest)
  "Move the current module to file `DEST'.

Prompts for a `DEST' when called interactively.

Note that this moves the currently *open* module, not the module
under point."
  (interactive
   (list
    (read-directory-name "Destination directory: " nil nil "confirm")))
  (deferred:$
    (traad--fetch-perform
     (buffer-file-name)
     "/refactor/move_module"
     :data (list (cons "dest" dest)
                 (cons "path" (buffer-file-name))))

    ;; Close current buffer, opening new one on moved file.
    (deferred:nextc it
      (lambda (_)
        (let* ((base_name (file-name-nondirectory (buffer-file-name)))
               (new_name (expand-file-name (concat dest "/" base_name))))
          (kill-buffer (current-buffer))
          (switch-to-buffer (find-file new_name)))))))

;;;###autoload
(defun traad-normalize-arguments ()
  "Normalize the arguments for the method at point.

This refactors all calls to this function to ensure the variables
are called in the correct order. It also removes explicit
references to keyword arguments whenever possible, replacing them
with positional references. For example, given the following:

    | def this_is_a_test(a, b, c=5):
    |     return [a, b, c]
    |
    | this_is_a_test(a=10, b=10, c=20)
    | this_is_a_test(20, 20, c=10)
    | this_is_a_test('a', 'b', 'c')
    | this_is_a_test(b='b', c='c', a='a')
    | this_is_a_test(a='a', b='b')

Calling `traad-normalize-arguments' on `this_is_a_test`, it would
become:

    | def this_is_a_test(a, b, c=5):
    |     return [a, b, c]
    |
    | this_is_a_test(10, 10, 20)
    | this_is_a_test(20, 20, 10)
    | this_is_a_test('a', 'b', 'c')
    | this_is_a_test('a', 'b', 'c')
    | this_is_a_test('a', 'b')

Note that the arguments in [1] were reordered. A more complex
case would be:

    | def longer_function(a, b, c=10, d=20):
    |     return [a, b, c, d]
    |
    | longer_function(a='a', b='b', d='d')

Calling `traad-normalize-arguments' on `longer_function`, it
would become:

    | def longer_function(a, b, c=10, d=20):
    |     return [a, b, c, d]
    |
    | longer_function('a', 'b', d='d')

It cannot remove the keyword reference to `d`, so \"d='d'\" is
retained.
"
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/normalize_arguments"
   :data (list (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-remove-argument (index)
  "Remove the `INDEX'th argument from the signature at point.

Also attempts to remove it from any calls to this function.

For example, let's say we have the following:

    | def some_function(arg1, arg2, arg3=10, arg4='some string'):
    |     '''Do something to some arbitrary parameters.'''
    |     first_half = [arg1, arg2]
    |     second_half = [arg3, arg4]
    |     return first_half, second_half
    |
    | some_function(1, 2, arg3=3, arg4='four')

Calling `traad-remove-argument' on `some_function` with an
`INDEX' of 2, this would become:

    | def some_function(arg1, arg2, arg4='some string'):
    |     '''Do something to some arbitrary parameters.'''
    |     first_half = [arg1, arg2]
    |     second_half = [arg3, arg4]                     # [1]
    |     return first_half, second_half
    |
    | some_function(1, 2, 'four')                        # [2]

It has removed the third argument, `arg3`.

Note:

  - The index counts from zero, so an index of 0 means the first
    argument and an index of 2 means the _third_ argument.

  - It does not remove internal references to the argument (e.g.
    [1]) in the function logic.

  - References to the function also have their function call
    normalised. See [2], where the explicit keyword reference was
    removed in favour of a positional reference. See
    `traad-normalize-arguments' for more information.
"
  (interactive
   (list
    (read-number "Index: ")))
                                        ; TODO: Surely there's a
                                        ; better way to construct
                                        ; these lists...
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/remove_argument"
   :data (list (cons "arg_index" index)
               (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-add-argument (index name default value)
  "Add a new argument at `INDEX' in the signature at point.

Takes the following arguments:

  `INDEX'   - The index to add the argument at. Note that this
              is zero-indexed, so an index of 1 will insert it
              as the _second_ argument.
  `NAME'    - The name of the argument.
  `DEFAULT' - The default value of the argument.
  `VALUE'   - The value to insert for this argument in any
              existing calls to this function.

For example, let's say we have the following:

    | def some_function(arg1, arg2, arg3=10, arg4='some string'):
    |     return [arg1, arg2, arg3, arg4]
    |
    | some_function(1, 2, arg3=3, arg4='four')

Let's call `traad-add-argument' on some_function. We'll supply
the following arguments:

`INDEX'   = 3
`NAME'    = \"new_arg\"
`DEFAULT' = 30
`VALUE'   = 50

This will become:

    | def some_function(arg1, arg2, arg3=10, new_arg=30, arg4='some string'):
    |     return [arg1, arg2, arg3, arg4]
    |
    | some_function(1, 2, 3, 50, 'four')                 # [1]

Note that references to the function also have their function
call normalised. See [1], where the explicit keyword reference
was removed in favour of a positional reference. See
`traad-normalize-arguments' for more information.

Arguments are always added as keyword arguments. Rope does not
discriminate based on position, so you can add keyword arguments
out-of-order. For example, back to the original function:

    | def some_function(arg1, arg2, arg3=10, arg4='some string'):
    |     return [arg1, arg2, arg3, arg4]
    |
    | some_function(1, 2, arg3=3, arg4='four')

Adding the same argument as before at `INDEX' = 1, this will
become:

    | def some_function(arg1, new_arg=30, arg2, arg3=10, arg4='some string'):# [1]
    |     return [arg1, arg2, arg3, arg4]
    |
    | some_function(1, 50, 2, 3, 'four')

Watch line [1]. Note that the sequence argument `arg2` now
appears after `new_arg`, a keyword argument, so the function
signature is no longer valid.
"
  (interactive
   (list
    (read-number "Index: ")
    (read-string "Name: ")
    (read-string "Default: ")
    (read-string "Value: ")))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/add_argument"
   :data (list (cons "arg_index" index)
               (cons "name" name)
               (cons "default" default)
               (cons "value" value)
               (cons "path" (buffer-file-name))
               (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-inline ()
  "Inline this object (replace the object with the thing it represents.)

Inlining can be performed on many objects.

Functions:

  Inlining a function replaces calls to a function with the
  explicit code the function executes. For example:

    | def do_something():
    |     print sys.version
    |     return C()

  Inlining `do_something`, becomes:

    | print sys.version
    | return C()

  Methods, etc. can also be inlined. For example:

    | class C(object):
    |     var = 1
    |
    |     def f(self, p):                                # [1]
    |         result = self.var + pn                     # [1]
    |         return result                              # [1]
    |
    | c = C()
    | x = c.f(1)                                         # [2]

  Inlining `C.f`, becomes:

    | class C(object):
    |     var = 1
    |
    | c = C()
    | result = c.var + pn                                # [2]
    | x = result                                         # [2]

Parameters:

  Inlning a parameter passes the default value of a keyword
  parameter whenever the parameter is not explicitly referenced.
  For example:

    | def f(p1=1, p2=2):
    |     pass
    |
    | f(3, 2)
    | f()                                                # [1]
    | f(3)                                               # [2]
    | f(p1=5, p2=7)                                      # [3]

  Inlining `p2`, becomes:

    | def f(p1=1, p2=2):
    |     pass
    |
    | f(3, 2)
    | f(p2=2)                                            # [1]
    | f(3, 2)                                            # [2]
    | f(5, 7)                                            # [3]

[1] and [2] have had explicit calls to the keyword argument
added. Note that:

  - It prefers positional over keyword calls.

  - It also normalizes the arguments, so [3] is affected. See
    `traad-normalize-arguments' for more information.
"
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/inline"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-introduce-parameter (parameter)
  "Introduce a parameter in a function.

This extracts a hard-coded value in a function, and introduces it
as a parameter. An example may be clearer. Let's say we have:

    | def multiply(value):
    |     result = value * 2
    |     return result
    |
    | my_var = multiply(10)

Let's call `traad-introduce-parameter' when the cursor is on '2'
and with `PARAMETER' = \"multiplier\". It will become:

    | def multiply(value, multiplier=2):
    |     result = value * 2
    |     return result
    |
    | my_var = multiply(10)
"
  (interactive
   (list
    (read-string "Parameter: ")))

  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/introduce_parameter"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point)))
          (cons "parameter" parameter))))

;;;###autoload
(defun traad-encapsulate-field ()
  "Introduce getters and setters and use them instad of references.

For example:

    | class MyClass(object):
    |     def __init__(self):
    |         self.my_var = 1
    |
    | my_class = MyClass()
    | print(my_class.my_var)                             # [1]
    | my_class.my_var = 5                                # [2]

Note that [1] is a get operation. [2] is a set operation.
Encapsulating the field `MyClass.my_var` this becomes:

    | class MyClass(object):
    |     def __init__(self):
    |         self.my_var = 1
    |
    |     def get_my_var(self):
    |         return self.my_var
    |
    |     def set_my_var(self, value):
    |         self.my_var = value
    |
    | my_class = MyClass()
    | print(my_class.get_my_var())                       # [1]
    | my_class.set_my_var(5)                             # [2]

Note that [1] and [2] have had the getters and setters inserted
automatically.
"
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/encapsulate_field"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-local-to-field ()
  "Turns a local variable into a field variable.

In other words, toggles the 'self' keyword or similar. Some
examples may be clearer.

Let's say we have:

    | class MyClass(object):
    |     def __init__(self):
    |         some_var = 1
    |         another_var = some_var * 2

  Calling `local-to-field' on `some_var`, it becomes:

    | class MyClass(object):
    |     def __init__(self):
    |         self.some_var = 1
    |         another_var = self.some_var * 2

Note that the refactoring is only performed on the variable in
scope, not on other occurrences of the name. For example, if we
have:

    | class MyClass(object):
    |     def __init__(self):
    |         some_var = 1
    |         another_var = some_var * 2
    |
    |     def do_something(self):
    |         some_var = 200

  Calling `local-to-field' on `some_var`, it becomes:

    | class MyClass(object):
    |     def __init__(self):
    |         self.some_var = 1
    |         another_var = self.some_var * 2
    |
    |     def do_something(self):
    |         some_var = 200
"
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/local_to_field"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point))))))

;;;###autoload
(defun traad-use-function ()
  "Tries to find the places in which a function can be used and
changes the code to call it instead.

For example, let's say we have the following code:

    | def square(p):
    |     return p ** 2
    |
    | my_var = 3 ** 2                                    # [1]
    |
    | another_var = 4 ** 2                               # [2]

  Performing 'use function' on `square`, becomes:

    | def square(p):
    |     return p ** 2
    |
    | my_var = square(3)                                 # [1]
    |
    | another_var = square(4)                            # [2]

It also works across files. Let's say we have two files,
'mod1.py' and 'mod2.py'. They look as follows:

    mod1.py:
    | def square(p):
    |     return p ** 2
    |
    | my_var = 3 ** 2                                    # [1]

    mod2.py:
    | another_var = 4 ** 2                               # [2]

  Performing 'use function' on `square`, the two files become:

    mod1.py:
    | def square(p):
    |     return p ** 2
    |
    | my_var = square(3)                                 # [1]

    mod2.py:
    | import mod1                                        # [2]
    | another_var = mod1.square(4)                       # [2]
"
  (interactive)
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/refactor/use_function"
   :data (list
          (cons "path" (buffer-file-name))
          (cons "offset" (traad--adjust-point (point))))))

(defun traad--extract-core (location name begin end)
  ;; TODO: refactor this common pattern of getting changes, applying them, and refreshing buffers.
  (traad--fetch-perform-refresh
   (buffer-file-name)
   location
   :data (list (cons "path" (buffer-file-name))
               (cons "start-offset" (traad--adjust-point begin))
               (cons "end-offset" (traad--adjust-point end))
               (cons "name" name))))

;;;###autoload
(defun traad-extract-method (name begin end)
  "Extract the currently selected region to a new method.

Here are some examples from the Rope documentation.
${region_start} and ${region_end} show the selected region for
extraction:

    | def a_func():
    |     a = 1
    |     b = 2 * a
    |     c = ${region_start}a * 2 + b * 3${region_end}  # [1]

After performing extract method (supplying the name `new_func`)
we'll have:

    | def a_func():
    |     a = 1
    |     b = 2 * a
    |     c = new_func(a, b)                             # [1]
    |
    | def new_func(a, b):                                # [2]
    |     return a * 2 + b * 3                           # [2]

For multi-line extractions if we have:

    | def a_func():
    |     a = 1
    |     ${region_start}b = 2 * a                       # [1]
    |     c = a * 2 + b * 3${region_end}                 # [1]
    |     print b, c

After performing extract method we'll have:

    | def a_func():
    |     a = 1
    |     b, c = new_func(a)                             # [1]
    |     print b, c
    |
    | def new_func(a):                                   # [2]
    |     b = 2 * a                                      # [2]
    |     c = a * 2 + b * 3                              # [2]
    |     return b, c                                    # [2]
"
  (interactive "sMethod name: \nr")
  (traad--extract-core "/refactor/extract_method" name begin end))

;;;###autoload
(defun traad-extract-variable (name begin end)
  "Extract the currently selected region to a new variable.

For example, take this code:

    | my_var = 1 * 2 * 3 * 4

${region_start} and ${region_end} show the selected region for
extraction:

    | my_var = ${region_start}1 * 2 * 3${region_end} * 4

Extracting to a new variable, `another_var`, gives:

    | another_var = 1 * 2 * 3
    | my_var = another_var * 4

Traad will _not_ try to replace similar expressions with the new
variable. For example, if we have:

    | my_var = 1 * 2 * 3 * 4
    | similar_var = 1 * 2 * 3                            # [1]

And we extract the following:

    | my_var = ${region_start}1 * 2 * 3${region_end} * 4
    | similar_var = 1 * 2 * 3                            # [1]

Extracting to `another_var` gives:

    | another_var = 1 * 2 * 3
    | my_var = another_var * 4
    | similar_var = 1 * 2 * 3                            # [1]

The expression at [1] will not be replaced with a reference to the
new variable.
"
  (interactive "sVariable name: \nr")
  (traad--extract-core "/refactor/extract_variable" name begin end))

;;;###autoload
(defun traad-organize-imports (filename)
  "Organize the import statements in `filename' according to pep8.

This is the preferred structure:

    [__future__ imports]

    [standard imports]

    [third-party imports]

    [project imports]


    [the rest of module]
"
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/organize"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-expand-star-imports (filename)
  "Expand * import statements in `filename'.

This replaces 'import *' with explicit references to the objects
used in the module.

For example, let's say we have two files, 'mod1.py' and
'mod2.py'. They look as follows:

    mod1.py:
    | def some_function():
    |     return True
    |
    | my_var = 1

    mod2.py:
    | from some_mod import *                             # [1]
    |
    | my_var = some_function()

  Expanding star imports in 'mod2.py' gives:

    mod1.py:
    | def some_function():
    |     return True
    |
    | my_var = 1

    mod2.py:
    | from some_mod import some_function                 # [1]
    |
    | my_var = some_function()

Note that it treats the new assignment of my_var as though it is
creating a variable local to 'mod2.py'.
"
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/expand_stars"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-froms-to-imports (filename)
  "Convert 'from' imports to normal imports in `filename'.

For example:

    | from mod1 import some_function
    |
    | my_var = some_function()

becomes:

    | import mod1
    |
    | my_var = mod1.some_function()
"
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/froms_to_imports"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-relatives-to-absolutes (filename)
  "Convert relative imports to absolute in `filename'."
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  ;; TODO: Find some examples and put them in the docstring.
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/relatives_to_absolutes"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-handle-long-imports (filename)
  "Transform long imports into 'from' imports in `filename'.

Handle long imports command tries to make long imports look
better. It attempts to transform imports like this:

    import pkg1.pkg2.pkg3.pkg4.mod1

into:

    from pkg1.pkg2.pkg3.pkg4 import mod1

Long imports can be identified either by having lots of dots or
being very long. The default configuration considers imported
modules with more than 2 dots or with more than 27 characters to
be long.
"
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (traad--fetch-perform-refresh
   (buffer-file-name)
   "/imports/handle_long_imports"
   :data (list (cons "path" filename))))

;;;###autoload
(defun traad-imports-super-smackdown (filename)
  "Apply all the import reformatting commands Traad provides.

Applies the following commands (in order):
(
  `traad-expand-star-imports'
  `traad-relatives-to-absolutes'
  `traad-froms-to-imports'
  `traad-handle-long-imports'
  `traad-organize-imports'
)
See each of these commands for full documentation.
"
  (interactive
   (list
    (read-file-name "Filename: " (buffer-file-name))))
  (mapcar (lambda (f) (funcall f filename))
          (list
           'traad-expand-star-imports
           'traad-relatives-to-absolutes
           'traad-froms-to-imports
           'traad-handle-long-imports
           'traad-organize-imports)))

(defun traad--get-definition (pos)
  "Get definition for an object.

Returns a deferred which produces an alist containing the result.
The result has the form:

((result   . <\"success\" or \"failure\">)
 (realpath . <the absolute path of the definition's file>)
 (path     . <relative path to the definition's file>)
 (name     . <name of the definition's file>)
 (lineno   . <the line number in the file>))
"
  ;; This function passes the code directly in the request. This could raise
  ;; issues if the buffer is particularly large.
  (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
                            (cons "path" (buffer-file-name))
                            (cons "code" (buffer-string)))))

    (deferred:$
      (traad--deferred-request
       (buffer-file-name)
       "/code_assist/definition"
       :data data
       :type "POST")

      (deferred:nextc it
        (lambda (req)
          (request-response-data req))))))

;;;###autoload
(defun traad-goto-definition (pos)
  "Jump to the position this object was defined."
  (interactive "d")
  (lexical-let ((symbol (thing-at-point 'symbol)))
    (deferred:$
      (traad--get-definition pos)
      (deferred:nextc it
        (lambda (response-data)
          (if response-data
              (let ((success (string= (assoc-default 'result
                                                     response-data)
                                      "success")))
                (if success
                    (let ((full-path (assoc-default 'realpath response-data))
                          (lineno (assoc-default 'lineno response-data)))
                      ;; Jump to the definition
                      (find-file full-path)
                      (goto-line lineno)
                      (beginning-of-line-text)
                      (search-forward symbol (line-end-position) t)
                      ;; Small fix for if the mark was active before the jump -
                      ;; disable it.
                      (deactivate-mark)
                      ;; Visual feedback for user.
                      (recenter)
                      t)
                  (user-error "Could not find definition.")))
            (user-error "No response from Traad server")))))))

;;;###autoload
(defun traad-goto-definition-synchronous (pos)
  "Go to this object's definition. Blocks until the task is completed."
  (interactive "d")
  (deferred:sync!
    (traad-goto-definition pos)))

(defun traad--findit-occurrences (pos)
  "Get all occurences the use of the symbol at POS.

Returns a deferred request. The JSON response has two keys:

((result . <\"success\" or \"failure\">)
 (locations . <a list of location alists>))

If `result' is \"success\", `locations' will hold a list of
locations. Each location is an alist of the form:

((path     . <relative path to the location's file>)
 (name     . <name of the location's file>)
 (realpath . <the absolute path of the location's file>)
 (region   . [<location start> <location end>])
 (offset   . <the offset at which the location starts>)
 (unsure   . <a json-false or json-true value>)
 (lineno   . <the line number in the file>))
"
  (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
                            (cons "path" (buffer-file-name)))))
    (deferred:$
      (traad--deferred-request
       (buffer-file-name)
       "/findit/occurrences"
       :data data
       :type "GET")

      (deferred:nextc it
        (lambda (req)
          (request-response-data req))))))

(defun traad--findit-implementations (pos)
  "Get all implementations the use of the symbol at POS.

Returns a deferred request. The JSON response has two keys:

((result . <\"success\" or \"failure\">)
 (locations . <a list of location alists>))

If `result' is \"success\", `locations' will hold a list of
locations. Each location is an alist of the form:

((path     . <relative path to the location's file>)
 (name     . <name of the location's file>)
 (realpath . <the absolute path of the location's file>)
 (region   . [<location start> <location end>])
 (offset   . <the offset at which the location starts>)
 (unsure   . <a json-false or json-true value>)
 (lineno   . <the line number in the file>))
"
  (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
                            (cons "path" (buffer-file-name)))))
    (deferred:$
      (traad--deferred-request
       (buffer-file-name)
       "/findit/implementations"
       :data data
       :type "GET")

      (deferred:nextc it
        (lambda (req)
          (request-response-data req))))))

(defun traad--findit-definition (pos)
  "Get location of a function definition.

Returns a deferred request. The JSON response has two keys:

((result . <\"success\" or \"failure\">)
 (location . <a location alist>))

If `result' is \"success\", `location' will hold one location in
an alist of the form:

((path     . <relative path to the location's file>)
 (name     . <name of the location's file>)
 (realpath . <the absolute path of the location's file>)
 (region   . [<location start> <location end>])
 (offset   . <the offset at which the location starts>)
 (unsure   . <a json-false or json-true value>)
 (lineno   . <the line number in the file>))
"
  (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
                            (cons "path" (buffer-file-name)))))
    (deferred:$
      (traad--deferred-request
       (buffer-file-name)
       "/findit/definition"
       :data data
       :type "GET")

      (deferred:nextc it
        (lambda (req)
          (request-response-data req))))))

(defun traad--extract-line (file-path line-no)
  "Extract a particular line in a file as a string."
  (with-temp-buffer
    (insert-file-contents file-path)
    (goto-line line-no)
    ;; (thing-at-point 'line) includes newlines at end of line.
    (replace-regexp-in-string "\n" ""
                              (thing-at-point 'line nil))))

(defun traad--button-action-visit-location (&optional button)
  "Command for a button in a findit results buffer.

This function visits a location."
  (interactive)
  (unless button
    (setq button (button-at (point))))
  (let ((filename (button-get button 'filename))
        (offset (button-get button 'offset)))
    (traad--visit-location-result filename offset)))

(defun traad--button-action-preview-location (&optional button)
  "Command for a button in a findit results buffer.

This function previews a location."
  (interactive)
  (unless button
    (setq button (button-at (point))))
  (let ((filename (button-get button 'filename))
        (offset (button-get button 'offset)))
    (traad--preview-location-result filename offset)))

(defvar traad--location-button-keymap (make-sparse-keymap)
  "Sparse keymap to bind to buttons in findit results buffers.")
(set-keymap-parent traad--location-button-keymap button-map)

;; Bind the RET and TAB keys to interact with the button.
(bind-map-set-keys traad--location-button-keymap
  "RET" 'traad--button-action-visit-location
  "TAB" 'traad--button-action-preview-location)

;; (defvar traad--location-results-keymap (make-sparse-keymap)
;;   "The keymap that should be active in location-results buffers")

;; (define-minor-mode traad-location-results-mode
;;   "Minor mode for buffers showing Traad location results."
;;   :init-value nil
;;   :lighter ""
;;   :keymap traad--location-results-keymap)

(defun traad--highlight-indentation (text)
  "Replaces indentation in `TEXT' with interpuncts (·).

`TEXT' should be a string representing a single line. It may not
contain newlines. Interpuncts are used to make the indentation
more obvious. Treats tabs as four characters.
"
  ;; First replace leading spaces. (Allow mixed tabs and spaces.)
  (while (string-match "^[·\t]*\\( \\)" text)
    (setq text (replace-regexp-in-string "^[·\t]*\\( \\)"
                                         (propertize "·" 'face 'font-lock-comment-face)
                                         text nil nil 1)))
  ;; Next replace leading tabs.
  (while (string-match "^[·]*\\(\t\\)" text)
    ;; TODO: Maybe adjust tab length based on user's settings?
    (setq text (replace-regexp-in-string "^[·]*\\(\t\\)"
                                         (propertize "····" 'face 'font-lock-comment-face)
                                         text nil nil 1)))
  text)

(defun traad--insert-location (location &optional longest-name longest-lineno)
  "Insert one location (with properties).

Utility function for `traad--display-findit-locations'."
  (let* ((lineno (assoc-default 'lineno location))
         (offset (assoc-default 'offset location))
         (unsure (traad--location-is-unsure location))
         (region (assoc-default 'region location))
         (realpath (assoc-default 'realpath location))
         (path (assoc-default 'path location))
         (name (assoc-default 'name location))
         (name-format (concat "%" (if longest-name
                                      (format "%s" longest-name)
                                    "")
                              "s"))
         (lineno-format (concat "%" (if longest-lineno
                                        (format "%s" longest-lineno)
                                      "")
                                "s"))
         (location-format (concat name-format "  " lineno-format ":"))
         (line-contents (traad--highlight-indentation
                         (traad--extract-line realpath lineno))))
    ;; Insert the file name and line number.
    (insert (propertize (format location-format name lineno)
                        'face 'italic))
    ;; Turn the file name and line number into a button so the user can visit
    ;; the location.
    (make-text-button (line-beginning-position) (point)
                      'action 'traad--button-action-visit-location
                      'keymap traad--location-button-keymap
                      'face 'button
                      'filename realpath
                      'offset offset
                      'help-echo "TAB: Preview result.  RET: Visit result.")
    ;; Label unsure occurrences with a question mark.
    (if unsure
        (insert " ? ")
      (insert "   "))
    ;; Now insert the actual line.
    (insert line-contents)
    (insert "\n")))

(defun traad--preview-location-result (filename offset)
  "Preview a location result.

This shows a location result without closing the current window."
  (let ((original-window (selected-window)))
    (find-file-other-window filename)
    (goto-char (traad--adjust-point-back offset))
    ;; Small fix for movements within same file with active region.
    (deactivate-mark)
    ;; Recentering on the result makes the location clearer.
    (recenter)
    (select-window original-window)))

(defun traad--visit-location-result (filename offset)
  "Visit a location result in the other window.

This also buries the current buffer."
  (let ((original-window (selected-window)))
    (find-file-other-window filename)
    (goto-char (traad--adjust-point-back offset))
    ;; Small fix for movements within same file with active region.
    (deactivate-mark)
    ;; Recentering on the result makes the location clearer.
    (recenter)
    ;; Finally bury the results buffer.
    (let ((new-window (selected-window)))
      (select-window original-window)
      (bury-buffer)
      (select-window new-window))))

(defun traad--insert-location-headers (longest-name longest-lineno)
  "Insert the headers for a list of locations."
  (let* ((name-format (concat "%" (format "%s" longest-name) "s"))
         (lineno-format (concat "%" (format "%s" longest-lineno) "s"))
         (headers-format (concat name-format "  " lineno-format "    %s")))
    (insert (propertize (format headers-format "File" "Line" "Result")
                        'face 'bold))
    (insert "\n")))

(defun traad--json-truthy (json-value)
  "Checks if a returned json value was truthy.

JSON responses may return some `json-false' or `json-null' value
instead of `nil', to distinguish between null and false in other
languages. This symbol may be truthy, even though it represents
a falsey value. This method decodes it."
  ;; Take the `json-false' and `json-null' values as falsey. Otherwise, use
  ;; Emacs' default interpretation of truthinesss.
  (cond ((eq json-value json-false)
         nil)
        ((eq json-value json-null)
         nil)
        (t (if json-value
               t
             nil))))

(defun traad--location-is-unsure (location)
  "Is the `LOCATION' object unsure?

(Also returns nil if the location has no 'unsure' attribute.)"
  (let ((unsure-response (assoc-default 'unsure location)))
    (traad--json-truthy unsure-response)))

(defun traad--display-findit-locations (findit-type original-name locations &optional buff-name)
  "Display a list of findit locations for the user.

`FINDIT-TYPE' - The type of search (e.g. 'occurences',
                'implementations'), as a symbol or string.
`ORIGINAL-NAME' - The name of the original symbol being located.
`LOCATIONS' - A list of location alists returned by the Traad
              server.
`BUFF-NAME' [OPTIONAL] - The name of the buffer that should be
            used to display the locations. If not provided, a
            name will be generated automatically."
  (switch-to-buffer-other-window
   (get-buffer-create (or buff-name (format "*traad-%s*" findit-type))))
  (read-only-mode 0)
  (erase-buffer)
  (insert (propertize (format "%s for '%s'\n"
                              (capitalize (format "%s" findit-type))
                              original-name)
                      'face 'bold))
  (insert (propertize "  Press `TAB' to preview result. Press `RET' to visit result and close.\n\n"
                      'face 'font-lock-comment-face))
  ;; Calculate some lengths for the different strings.
  (let ((longest-name 0)
        (longest-lineno 0)
        (min-lineno-length 5)
        (max-lineno-length 9)
        (min-name-length 5)
        (max-name-length 30))
    ;; Work out which name is longest. All names should be aligned to the
    ;; longest name. Do the same for the length of the line numbers.
    (mapcar (lambda (location)
              (let* ((name (assoc-default 'name location))
                     (name-length (length name))
                     (lineno (assoc-default 'lineno location))
                     (lineno-length (length (format "%s" lineno))))
                (when (> name-length longest-name)
                  (setq longest-name name-length))
                (when (> lineno-length longest-lineno)
                  (setq longest-lineno lineno-length))))
            locations)
    ;; Name and line number padding should be neither too big nor too small.
    (setq longest-name (max min-name-length
                            (min longest-name
                                 max-lineno-length)))
    (setq longest-lineno (max min-lineno-length
                              (min longest-lineno
                                   min-lineno-length)))
    (traad--insert-location-headers longest-name longest-lineno)
    ;; Store some values we'll need later.
    (let (;; Keep track of the first result's position.
          (first-result-line (line-number-at-pos))
          ;; Keep track of whether any results are unsure.
          (has-unsure-locations nil))
      ;; Print each result. Unsure occurrences will be printed later. Skip them,
      ;; but flag if they exist.
      (or (mapcar (lambda (location)
                    (if (traad--location-is-unsure location)
                        (setq has-unsure-locations t)
                      (traad--insert-location location longest-name longest-lineno)))
                  locations)
          ;; If no results were found, insert a "no results" message.
          (insert (propertize (format "No %s found." findit-type)
                              'face 'italic)))
      ;; List unsure results separately.
      (when has-unsure-locations
        (insert (propertize "\nUnsure Matches:\n"
                            'face 'bold))
        (mapcar (lambda (location)
                  (when (traad--location-is-unsure location)
                    (traad--insert-location location longest-name longest-lineno)))
                locations))
      ;; Put the cursor back on the first result.
      (goto-line first-result-line)))
  (read-only-mode 1))

(defun traad--findit-synchronous (pos findit-func)
  "Apply a findit command synchronously."
  (deferred:sync!
    (apply findit-func pos)))

;;;###autoload
(defun traad-list-occurrences (pos)
  "Return a list of occurrences for the object at `POS'.

Useful for alternate displays, e.g. `helm'."
  (traad--findit-synchronous pos 'traad--findit-occurrences))

;;;###autoload
(defun traad-list-implementations (pos)
  "Return a list of implementatins for the object at `POS'.

Useful for alternate displays, e.g. `helm'."
  (traad--findit-synchronous pos 'traad--findit-implementations))

;;;###autoload
(defun traad-findit-definition-synchronous (pos)
  "Return a list of possible definitions for the object at `POS'.

Useful for alternate displays, e.g. `helm'."
  (traad--findit-synchronous pos 'traad--findit-definition))

(defun traad--findit (pos findit-func findit-type)
  "Generic function to display locations from the findit module in Rope.

`POS' - Position the findit function was called on (in the
        current buffer).
`FINDIT-FUNC' - The elisp findit function that should be called.
`FINDIT-TYPE' - The type of findit command that was called. This
                is used for display purposes."
  (lexical-let ((symbol-name (save-excursion
                               (goto-char pos)
                               (thing-at-point 'symbol))))
    (deferred:$
      (apply findit-func (list pos))
      (deferred:nextc it
        (lambda (res)
          (if (string= (assoc-default 'result res) "success")
              (let ((locations (assoc-default 'locations res)))
                (traad--display-findit-locations findit-type symbol-name locations))
            (user-error (format "Unable to find %s." findit-type))))))))

;;;###autoload
(defun traad-find-occurrences (pos)
  "Finds and displays all occurrences of the current symbol."
  (interactive "d")
  (deferred:sync!
    (traad--findit pos 'traad--findit-occurrences 'occurrences)))

;;;###autoload
(defun traad-find-implementations (pos)
  "Finds and displays all implementations of the current symbol."
  (interactive "d")
  (traad--findit pos 'traad--findit-implementations 'implementations))

;;;###autoload
(defun traad-find-definition (pos)
  "Finds and displays the definition of the current symbol.

Note that this is not the same as `traad-goto-definition'.

  - This function locates the definition with the `findit' module
    from Rope. It does not jump to the definition.

  - `traad-goto-definition' finds the definition with the
    `code_assist' module from Rope. It jumps to the location of
    the definition."
  (interactive "d")
  (lexical-let ((symbol-name (save-excursion
                               (goto-char pos)
                               (thing-at-point 'symbol))))
    (deferred:$
      (traad--findit-definition pos)
      (deferred:nextc it
        (lambda (res)
          (if (string= (assoc-default 'result res) "success")
              (let ((location (assoc-default 'location res)))
                (traad--display-findit-locations 'definition symbol-name (list location)))
            (user-error (format "Unable to find definition."))))))))

;;;###autoload
(defun traad-thing-at (pos)
  "Get the type of the Python thing at `POS'.

When called interactively, displays the type."
  (interactive "d")
  (let* ((data (list (cons "offset" (traad--adjust-point pos))
                     (cons "path" (buffer-file-name))))
         (request-backend 'url-retrieve)
         (url (traad--construct-url (buffer-file-name) "/thing_at"))
         (result (request-response-data
                  (request
                   url
                   :headers '(("Content-Type" . "application/json"))
                   :data (json-encode data)
                   :sync t
                   :parser 'json-read
                   :data (json-encode data)
                   :type "POST"))))
    (let ((result (alist-get 'thing result)))
      (when (called-interactively-p)
        (let ((message-text (if result
                                (format "Type of `%s': `%s'"
                                        (save-excursion
                                          (goto-char pos)
                                          (thing-at-point 'symbol))
                                        result)
                              "No type found for thing at point.")))
          (message message-text)
          (popup-tip message-text)))
      result)))

;;;###autoload
(defun traad-code-assist (pos)
  "Get possible completions at `POS' in current buffer.

This returns an alist like ((completions . [[name documentation scope type]]) (result . \"success\"))"
  (interactive "d")
  (let ((data (list (cons "offset" (traad--adjust-point pos))
                    (cons "path" (buffer-file-name))))
        (request-backend 'url-retrieve)
        (url (traad--construct-url (buffer-file-name) "/code_assist/completions")))
    (request-response-data
     (request
      url
      :headers '(("Content-Type" . "application/json"))
      :data (json-encode data)
      :sync t
      :parser 'json-read
      :data (json-encode data)
      :type "POST"))))

(defun traad--display-in-buffer (msg buffer)
  "Display `msg' in `buffer', clearing the buffer first."
  (let ((cbuff (current-buffer))
        (buff (get-buffer-create buffer))
        (inhibit-read-only 't))
    (pop-to-buffer buff)
    (erase-buffer)
    (insert msg)
    (pop-to-buffer cbuff)))

(defun traad-get-calltip (pos)
  "Get the calltip for an object.

Returns a deferred which produces the calltip string.
"
  (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
                            (cons "path" (buffer-file-name)))))
    (deferred:$
      (traad--deferred-request
       (buffer-file-name)
       "/code_assist/calltip"
       :data data
       :type "POST")
      (deferred:nextc it
        (lambda (req)
          (assoc-default
           'calltip
           (request-response-data req)))))))

;;;###autoload
(defun traad-display-calltip (pos)
  "Display calltip for an object."
  (interactive "d")
  (deferred:$
    (traad-get-calltip pos)
    (deferred:nextc it
      (lambda (calltip)
        (if calltip
            (traad--display-in-buffer
             calltip
             "*traad-calltip*")
          (message "No calltip available."))))))

;;;###autoload
(defun traad-popup-calltip (pos)
  "Display calltip for an object in a popup."
  (interactive "d")
  (lexical-let ((pos pos))
    (deferred:$
      (traad-get-calltip pos)
      (deferred:nextc it
        (lambda (calltip)
          (if calltip
              (popup-tip
               calltip
               :point pos)))))))

(defun traad--get-doc (pos)
  "Get docstring for an object.

Returns a deferred which produces the doc string. If there is not
docstring, the deferred produces nil.
"
  (lexical-let ((data (list (cons "offset" (traad--adjust-point pos))
                            (cons "path" (buffer-file-name)))))
    (deferred:$

      (traad--deferred-request
       (buffer-file-name)
       "/code_assist/doc"
       :data data
       :type "POST")

      (deferred:nextc it
        (lambda (req)
          (assoc-default
           'doc
           (request-response-data req)))))))

;;;###autoload
(defun traad-display-doc (pos)
  "Display docstring for an object."
  (interactive "d")
  (deferred:$
    (traad--get-doc pos)
    (deferred:nextc it
      (lambda (doc)
        (if doc
            (traad--display-in-buffer
             doc
             "*traad-doc*")
          (message "No docstring available."))))))

;;;###autoload
(defun traad-popup-doc (pos)
  "Display docstring for an object in a popup."
  (interactive "d")
  (lexical-let ((pos pos))
    (deferred:$
      (traad--get-doc pos)
      (deferred:nextc it
        (lambda (doc)
          (if doc
              (popup-tip
               doc
               :point pos)))))))

(defvar traad--server-map (make-hash-table :test 'equal)
  "Mapping of project roots to `traad--server' structs.")

;;;###autoload
(defun traad-kill-all ()
  "Kill all traad servers and associated buffers."
  (interactive)
  (maphash
   (lambda (root server)
     (let* ((proc (traad--server-proc server))
            (buff (process-buffer proc)))
       (kill-buffer buff)))
   traad--server-map)
  (clrhash traad--server-map))

(defun traad--get-server (project-root)
  "Get the server entry for `project-root'."
  (gethash project-root traad--server-map))

(defun traad--add-server (project-root server)
  "Add a server entry for `prbject-root'."
  (puthash project-root server traad--server-map))

(defun traad--remove-server (project-root)
  "Remove the server entry for `project-root'."
  (remhash project-root traad--server-map))

(defun traad--ensure-server (project-root)
  "Get the host of the server for `project-root'.

This starts a new server if necessary."
  (let* ((project-root (f-full project-root))
         (server (traad--get-server project-root)))
    (cond
     ;; Is there no server entry for this project?
     ((null server)
      (pcase (traad--open project-root)
        (`nil (error "Unable to start new server"))
        (server
         (traad--add-server project-root server)
         (traad--check-protocol-version project-root)
         (traad--server-host server))))

     ;; Is the process for the entry dead?
     ((not (process-live-p (traad--server-proc server)))
      (traad--remove-server project-root)
      (traad--ensure-server project-root))

     ;; We found a live server!
     (t (traad--server-host server)))))

(defun traad--find-project-root (for-path)
  "Find the root directory for the project containg `for-path'.

Returns `nil' if there is not such project.
"
  (locate-dominating-file for-path ".ropeproject"))

(defun traad--get-host (for-path)
  "Get the host of the server responsible for `for-path'.

This will start a new server if necessary.
"
  (let ((project-root
         (or
          (traad--find-project-root for-path)
          (read-directory-name "Project root? "))))
    (traad--ensure-server project-root)))

(defun traad--construct-url (for-path location)
  "Construct a URL to a specific location on the traad server.

In short: http://server_host:server_port<location>
"
  (let ((host (traad--get-host for-path)))
    (concat "http://" host location)))

(defun traad--save-all ()
  "Save all modified buffers without confirmation and return non-`nil'."
  (save-some-buffers 'no-confirm)
  'saved)

(defun traad--all-changes-saved ()
  "Determine if all unsaved changes are changed.

This checks `traad-save-unsaved-buffers' to know how to behave
when there are modified buffers. This returns non-`nil' only if
there were no modified buffers or if any modified buffers were
saved in the process of this function.
"
  (let ((save-all (lambda () (save-some-buffers 'no-confirm) t)))
    (or
     (not (-any
           (lambda (buff)
             (and (buffer-file-name buff)
                  (buffer-modified-p buff)))
           (buffer-list)))
     (case traad-save-unsaved-buffers
       ('never nil)
       ('always
        (funcall save-all))
       ('ask
        (and (yes-or-no-p "Save modified buffers? ")
             (funcall save-all)))))))

(defun* traad--fetch-perform (for-path location &key (data '()))
  "Perform common refactoring path: fetch changes from
`location' (passing `data' as a payload) and perform them."
  ;; TODO: check for non-success and lack of 'changes key
  (when (traad--all-changes-saved)
    (let ((response nil) (pth for-path))
      (deferred:$

        ;; Get the changes
        (traad--deferred-request
         pth
         location
         :type "POST"
         :data data)

        ;; Perform the changes
        (deferred:nextc it
          (lambda (rsp)
            (let ((response (request-response-data rsp)))
              (traad--deferred-request
               pth
               "/refactor/perform"
               :type "POST"
               :data response))))))))

(defun* traad--fetch-perform-refresh (for-path location &key (data '()))
  "Perform common refactoring path: fetch changes from
`location' (passing `data' as a payload), perform them, and
refresh affected buffers."
  (when (traad--all-changes-saved)
    (let ((response nil) (pth for-path))
      (deferred:$

        ;; Get the changes
        (traad--deferred-request
         pth
         location
         :type "POST"
         :data data)

        ;; Perform the changes
        (deferred:nextc it
          (lambda (rsp)
            (setq response (request-response-data rsp))
            (traad--deferred-request
             pth
             "/refactor/perform"
             :type "POST"
             :data response)))

        ;; Refresh buffers in the response
        (deferred:nextc it
          (lambda (rsp)
            (let ((changeset (assoc-default 'changes response)))
              (dolist (path (traad--change-set-to-paths changeset))
                (let* ((root (traad--find-project-root path))
                       (full-path (expand-file-name (traad--join-path root path)))
                       (buff (get-file-buffer full-path)))
                  (if buff
                      (with-current-buffer buff
                        (revert-buffer :ignore-auto :no-confirm))))))))))))

(defun* traad--deferred-request (for-path location &key (type "GET") (data '()))
  (let ((request-backend 'url-retrieve))
    (request-deferred
     (traad--construct-url for-path location)
     :type type
     :parser 'json-read
     :headers '(("Content-Type" . "application/json;charset=utf-8"))
     :data (encode-coding-string (json-encode data) 'utf-8))))

(defun traad--range (upto)
  "Construct a list of ints from 0 to `UPTO' inclusive."
  (defun range_ (x)
    (if (> x 0)
        (cons x (range_ (- x 1)))
      (list 0)))
  (nreverse (range_ upto)))

(defun traad--enumerate (l)
  (map 'list 'cons (traad--range (length l)) l))

(defun traad--adjust-point (p)
  "Rope uses 0-based indexing, but Emacs points are 1-based.

(Converts from Emacs points to Rope points)"
  (- p 1))

(defun traad--adjust-point-back (p)
  "Emacs uses 1-based indexing, but Rope uses 0-based indexing.

(Converts from Rope points to Emacs points)"
  (+ p 1))

(defun traad--read-lines (path)
  "Return a list of lines of a file at `PATH'."
  (with-temp-buffer
    (insert-file-contents path)
    (split-string (buffer-string) "\n" nil)))

                                        ; TODO: invalidation support?

(defconst traad--install-server-command
  "pip install --upgrade traad")

;;;###autoload
(defun traad-install-server ()
  "Install traad.

This installs the server into the `traad-environment-name'
virtual environment, creating the virtualenv if necessary.

By default, then, it installs traad into
`PYTHON-ENVIRONMENT_DIRECTORY/traad`.

To install Traad for a different version of Python than the
default, ensure the virtual environment exists (and is running
that version of Python) before calling `traad-install-server'."
  (interactive)
  (ignore-errors
    (venv-mkvirtualenv traad-environment-name))
  (venv-with-virtualenv-shell-command
   traad-environment-name
   traad--install-server-command))

;; Utilities
(defun traad--change-set-to-paths (changeset)
  "Get all paths of affected files from a changeset.

A changeset looks like this:
      ['ChangeSet',
        ['Renaming <using_project> to <foo_log>',
          [['ChangeContents',
              ['tests/test_json_api.py',
               '<contents>',
               null]],
           . . .
          ],
          null]]
"
  (let* ((refactoring (elt changeset 1))
         (change-contents (elt refactoring 1)))
    (-map
     (lambda (content)
       (let ((file-change (elt content 1)))
         (elt file-change 0)))
     change-contents)))

(defun traad--join-path (a b)
  "Join two paths. Joins the directory of `A' with `B'."
  (concat (file-name-as-directory a) b))

(provide 'traad)

;;; traad.el ends here
