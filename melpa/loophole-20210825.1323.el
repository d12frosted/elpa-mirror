;;; loophole.el --- Manage temporary key bindings -*- lexical-binding: t -*-

;; Copyright (C) 2020, 2021 0x60DF

;; Author: 0x60DF <0x60df@gmail.com>
;; Created: 30 Aug 2020
;; Version: 0.6.4
;; Package-Version: 20210825.1323
;; Package-Commit: 71f0b40cdcffdbae84214d3d82c0a8aae154a69f
;; Keywords: convenience
;; URL: https://github.com/0x60df/loophole
;; Package-Requires: ((emacs "27.1"))

;; This file is not part of GNU Emacs.

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

;; Loophole provides temporary key bindings management feature.
;; Keys can be set by interactive interface in disposable keymaps
;; which are automatically generated for temporary use.

;; Run `loophole-mode' to setup Loophole.
;; Call `loophole-set-key' to set a temporary key binding.
;; See https://github.com/0x60df/loophole/blob/master/README.md for datails.

;;; Code:

(require 'kmacro)

(defgroup loophole nil
  "Manage temporary key bindings."
  :group 'convenience)

;;; Internal variables

(defvar-local loophole--map-alist nil
  "Alist of keymaps for loophole.
Syntax is same as `minor-mode-map-alist', i.e. each element
looks like (STATE-VARIABLE . KEYMAP).  STATE-VARIABLE is a
symbol whose boolean value represents if the KEYMAP is
active or not.  KEYMAP is a keymap object.
STATE-VARIABLE, KEYMAP and map-variable which holds KEYMAP
must be unique for each element of this variable.")

(defvar loophole--buffer-list nil
  "List of buffers on which Loophole variables have local value.
Loophole mode maintains this variable as up to date.
When Loophole mode is disabled, this variable is set as t
in order to tell that this variable is not maintained.")

(defvar-local loophole--editing nil
  "Variable of keymap which is currently being edited.
Loophole binds keys in this keymap.  When this value is nil,
Loophole may generate new keymap and bind keys in it.")

(defvar loophole--suspended nil
  "Non-nil if Loophole is suspended manually.
Once Loophole is resumed, this comes back to nil.
To see true state of suspension, use
`loophole-suspending-p' instead of this variable.")

(defvar-local loophole--timer-alist nil
  "Alist of timer for disabling Loophole map.
Each element looks like (MAP-VARIABLE . TIMER).
MAP-VARIABLE is a symbol which holds keymap.
TIMER is a timer for MAP-VARIABLE on current buffer.
Default value holds timers for global Loophole map.")

(defvar-local loophole--editing-timer nil
  "Timer for stopping editing loophole map.")

(defvar loophole--read-map-variable-help-condition
  '((index . 0) (last))
  "Condition of help for `loophole-read-map-variable'.")

;;; User options

(defvar loophole-base-map (make-sparse-keymap)
  "Base keymap for all Loophole maps.
This keymap will be inherited to all Loophole maps,
except for the case user explicitly decline inheritance
when `loophole-register'.")

(defcustom loophole-temporary-map-max 8
  "Maximum number of temporary keymaps.
When the number of bound temporary keymaps is
`loophole-temporary-map-max' or higher, generating new map
overwrites the disabled earliest used one, unregistered one
or enabled earliest used one."
  :group 'loophole
  :type 'integer)

(defcustom loophole-allow-keyboard-quit t
  "If non-nil, binding commands can be quit even while reading keys.
If binidng commands use reading key function other than
`loohpole-read-key', this variable takes no effect."
  :group 'loophole
  :type 'boolean)

(defcustom loophole-decide-obtaining-method-after-read-key 'negative-argument
  "Option for the timing when obtaining method is decided.

If this value is t, binding commands always decide
obtaining method after reading key.

If this value is 'negative-argument, binding commands
decide obtaining method after reading key only when
they are called with `negative-argument'.

Otherwise, binding commands always decide obtaining
method before reading key.

The timing of decision affect to behavior of binding
commands like `loophole-set-key', especially for the case
they are called with `negative-argument'.
Binding commands with `negative-argument' ask user which
obtaining method to use.
If decision occurs after reading key, the prompt for
asking obtaining method arises after the other prompt which
is for reading key.

Besides, if decision is after reading key, optional
:key property of obtaining method defined at other user
options like `loophole-set-key-order' will be omitted."
  :group 'loophole
  :type 'boolean)

(defcustom loophole-force-make-variable-buffer-local t
  "Flag if `make-variable-buffer-local' is done without prompting."
  :group 'loophole
  :type 'boolean)

(defcustom loophole-force-unintern nil
  "Flag if `unintern' is done without prompting."
  :group 'loophole
  :type 'boolean)

(defcustom loophole-force-overwrite-parent-map nil
  "Flag if `set-keymap-parent' is done without prompting.
If parent of the keymap which is about to be
`set-keymap-parent' is nil, parent is set without prompt
regardless of the value of this user option."
  :group 'loophole
  :type 'boolean)

(defcustom loophole-make-register-always-read-tag t
  "Flag if interactive `loophole-register' always reads tag string."
  :group 'loophole
  :type 'boolean)

(defcustom loophole-timer-default-time (* 60 60)
  "Default time in seconds for auto disabling timer."
  :group 'loophole
  :type 'number)

(defcustom loophole-editing-timer-default-time (* 60 5)
  "Default time in seconds for auto stopping editing timer."
  :group 'loophole
  :type 'number)

(defvar loophole-write-lisp-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map emacs-lisp-mode-map)
    (define-key map (kbd "C-c C-c") #'loophole-finish-writing-lisp)
    (define-key map (kbd "C-c C-k") #'loophole-abort-writing-lisp)
    map)
  "Keymap for `loophole-write-lisp-mode'.")

(defcustom loophole-command-by-lambda-form-format
  (concat "(lambda (&optional arg)\n"
          "  \"Temporary command on `loophole'.\"\n"
          "  (interactive \"P\")\n"
          "  (#))")
  "Format for writing lambda form buffer.
This is used by `loophole-obtain-command-by-lambda-form'.
Character sequence (#) indicates where cursor will be
placed, and it will be removed when the format is inserted
in the buffer."
  :risky t
  :group 'loophole
  :type 'string)

(defcustom loophole-kmacro-by-read-key-finish-key (where-is-internal
                                                   'keyboard-quit nil t)
  "Key sequence to finish definition of keyboard macro.
This is used by `loophole-obtain-kmacro-by-read-key'."
  :group 'loophole
  :type 'key-sequence)

(defvar loophole-kmacro-by-recursive-edit-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c [") #'loophole-end-kmacro)
    (define-key map (kbd "C-c \\") #'loophole-abort-kmacro)
    map)
  "Keymap for `loophole-obtain-kmacro-by-recursive-edit'.
This map is enabled temporarily during
`loophole-obtain-kmacro-by-recursive-edit',
and activity of this map is controled by
`loophole-kmacro-by-recursive-edit-map-flag'.")

(defcustom loophole-kmacro-by-recursive-edit-map-flag t
  "Non-nil means `loophole-kmacro-by-recursive-edit-map' is enabled."
  :group 'loophole
  :type 'boolean)

(defcustom loophole-kmacro-by-recursive-edit-map-tag
  "kmacro[End: \\[loophole-end-kmacro], Abort: \\[loophole-abort-kmacro]]"
  "Tag string for `loophole-kmacro-by-recursive-edit-map'."
  :group 'loophole
  :type 'string)

(defcustom loophole-array-by-read-key-finish-key (where-is-internal
                                                  'keyboard-quit nil t)
  "Key sequence to finish inputting key sequence.
This is used by `loophole-obtain-array-by-read-key'."
  :group 'loophole
  :type 'key-sequence)

(defcustom loophole-bind-entry-order
  '(loophole-obtain-object)
  "The priority list of methods to obtain any Lisp object for binding.
`loophole-bind-entry' refers this variable to select
obtaining method.  First element gets first priority.
Each element should be a function which takes one argument
the key to be bound and returns any Lisp object for binding
entry.

Each element optionally can be a list whose car is a
function described above, and cdr is a plist whose property
may be :key and/or :keymap.  It looks like
\(OBTAIN-ENTRY :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes no arguments and returns
key sequence to be bound.
OBTAIN-KEYMAP is a function which takes two arguments the
key and entry to be bound, and returns keymap object on
which key and entry are bound; this overrides
`loophole--editing'.

If `loophole-decide-obtaining-method-after-read-key' is t,
or while it is 'negative-argument and `loophole-bind-entry'
is called with `negative-argument',
:key property will be omitted and default
`loophole-read-key' will be used for reading key."
  :risky t
  :group 'loophole
  :type '(repeat sexp))

(defcustom loophole-bind-command-order
  '(loophole-obtain-command-by-read-command
    loophole-obtain-command-by-key-sequence
    loophole-obtain-command-by-lambda-form
    loophole-obtain-object)
  "The priority list of methods to obtain command for binding.
`loophole-bind-command' refers this variable to select
obtaining method.  First element gets first priority.
Each element should be a function which takes one argument
the key to be bound and returns a command for binding entry.

Each element optionally can be a list whose car is a
function described above, and cdr is a plist whose property
may be :key and/or :keymap.  It looks like
\(OBTAIN-COMMAND :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes no arguments and returns
key sequence to be bound.
OBTAIN-KEYMAP is a function which takes two arguments the
key and command to be bound, and returns keymap object on
which key and command are bound; this overrides
`loophole--editing'.

If `loophole-decide-obtaining-method-after-read-key' is t,
or while it is 'negative-argument and
`loophole-bind-command' is called with `negative-argument',
:key property will be omitted and default
`loophole-read-key' will be used for reading key."
  :risky t
  :group 'loophole
  :type '(repeat sexp))

(defcustom loophole-bind-kmacro-order
  '(loophole-obtain-kmacro-by-recursive-edit
    (loophole-obtain-kmacro-by-read-key
     :key loophole-read-key-for-kmacro-by-read-key)
    loophole-obtain-kmacro-by-recall-record
    loophole-obtain-object)
  "The priority list of methods to obtain kmacro for binding.
`loophole-bind-kmacro' refers this variable to select
obtaining method.  First element gets first priority.
Each element should be a function which takes one argument
the key to be bound and returns a kmacro object for binding
entry.

Each element optionally can be a list whose car is a
function described above, and cdr is a plist whose property
may be :key and/or :keymap.  It looks like
\(OBTAIN-KMACRO :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes no arguments and returns
key sequence to be bound.
OBTAIN-KEYMAP is a function which takes two arguments the
key and kmacro to be bound, and returns keymap object on
which key and kmacro are bound; this overrides
`loophole--editing'.

If `loophole-decide-obtaining-method-after-read-key' is t,
or while it is 'negative-argument and `loophole-bind-kmacro'
is called with `negative-argument',
:key property will be omitted and default
`loophole-read-key' will be used for reading key."
  :risky t
  :group 'loophole
  :type '(repeat sexp))

(defcustom loophole-bind-array-order
  '((loophole-obtain-array-by-read-key
     :key loophole-read-key-for-array-by-read-key)
    loophole-obtain-array-by-read-string
    loophole-obtain-object)
  "The priority list of methods to obtain array for binding.
`loophole-bind-array' refers this variable to select
obtaining method.  First element gets first priority.
Each element should be a function which takes one argument
the key to be bound and returns a array for binding entry.

Each element optionally can be a list whose car is a
function described above, and cdr is a plist whose property
may be :key and/or :keymap.  It looks like
\(OBTAIN-ARRAY :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes no arguments and returns
key sequence to be bound.
OBTAIN-KEYMAP is a function which takes two arguments the
key and array to be bound, and returns keymap object on
which key and array are bound; this overrides
`loophole--editing'.

If `loophole-decide-obtaining-method-after-read-key' is t,
or while it is 'negative-argument and `loophole-bind-array'
is called with `negative-argument',
:key property will be omitted and default
`loophole-read-key' will be used for reading key."
  :risky t
  :group 'loophole
  :type '(repeat sexp))

(defcustom loophole-bind-keymap-order
  '(loophole-obtain-keymap-by-read-keymap-variable
    loophole-obtain-keymap-by-read-keymap-function
    loophole-obtain-object)
  "The priority list of methods to obtain keymap for binding.
`loophole-bind-keymap' refers this variable to select
obtaining method.  First element gets first priority.
Each element should be a function which takes one argument
the key to be bound and returns a keymap object for binding
entry.

Each element optionally can be a list whose car is a
function described above, and cdr is a plist whose property
may be :key and/or :keymap.  It looks like
\(OBTAIN-KEYMAP :key READ-KEY :keymap OBTAIN-ANOTHER-KEYMAP).
READ-KEY is a function which takes no arguments and returns
key sequence to be bound.
OBTAIN-ANOTHER-KEYMAP is a function which takes two
arguments the key and keymap to be bound, and returns
another-keymap object on which key and keymap are bound;
this overrides `loophole--editing'.

If `loophole-decide-obtaining-method-after-read-key' is t,
or while it is 'negative-argument and `loophole-bind-keymap'
is called with `negative-argument',
:key property will be omitted and default
`loophole-read-key' will be used for reading key."
  :risky t
  :group 'loophole
  :type '(repeat sexp))

(defcustom loophole-bind-symbol-order
  '(loophole-obtain-symbol-by-read-keymap-function
    loophole-obtain-symbol-by-read-command
    loophole-obtain-symbol-by-read-array-function
    loophole-obtain-object)
  "The priority list of methods to obtain symbol for binding.
`loophole-bind-symbol' refers this variable to select
obtaining method.  First element gets first priority.
Each element should be a function which takes one argument
the key to be bound and returns a symbol for binding entry.

Each element optionally can be a list whose car is a
function described above, and cdr is a plist whose property
may be :key and/or :keymap.  It looks like
\(OBTAIN-SYMBOL :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes no arguments and returns
key sequence to be bound.
OBTAIN-KEYMAP is a function which takes two arguments the
key and symbol to be bound, and returns keymap object on
which key and symbol are bound; this overrides
`loophole--editing'.

If `loophole-decide-obtaining-method-after-read-key' is t,
or while it is 'negative-argument and `loophole-bind-symbol'
is called with `negative-argument',
:key property will be omitted and default
`loophole-read-key' will be used for reading key."
  :risky t
  :group 'loophole
  :type '(repeat sexp))

(defcustom loophole-set-key-order
  '(loophole-obtain-command-by-read-command
    loophole-obtain-kmacro-by-recursive-edit
    loophole-obtain-command-by-key-sequence
    (loophole-obtain-kmacro-by-read-key
     :key loophole-read-key-for-array-by-read-key)
    loophole-obtain-command-by-lambda-form
    loophole-obtain-kmacro-by-recall-record
    loophole-obtain-object)
  "The priority list of methods to obtain object for binding.
`loophole-set-key' refers this to select obtaining method.
First element gets first priority.
Each element should be a function which takes one argument
the key to be bound and returns any Lisp object for binding
entry

Each element optionally can be a list whose car is a
function described above, and cdr is a plist which has
a property :key.  It looks like
\(OBTAIN-ENTRY :key READ-KEY).
READ-KEY is a function which takes no arguments and returns
key sequence to be bound.

If `loophole-decide-obtaining-method-after-read-key' is t,
or while it is 'negative-argument and `loophole-set-key' is
called with `negative-argument',
:key property will be omitted and default
`loophole-read-key' will be used for reading key."
  :risky t
  :group 'loophole
  :type '(repeat sexp))

(defcustom loophole-register-functions nil
  "Hook for `loophole-register'.
Functions added to this user option are called with one
argument, registered map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-unregister-functions nil
  "Hook for `loophole-unregister'.
Functions added to this user option are called with one
argument, unregistered map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-prioritize-functions nil
  "Hook for `loophole-prioritize'.
Functions added to this user option are called with one
argument, prioritized map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-globalize-functions nil
  "Hook for `loophole-globalize'.
Functions added to this user option are called with one
argument, globalized map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-localize-functions nil
  "Hook for `loophole-localize'.
Functions added to this user option are called with one
argument, localized map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-enable-functions nil
  "Hook for `loophole-enable'.
Functions added to this user option are called with one
argument, enabled map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-disable-functions nil
  "Hook for `loophole-disable'.
Functions added to this user option are called with one
argument, disabled map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-start-editing-functions nil
  "Hook for `loophole-start-editing'.
Functions added to this user option are called with one
argument, which is being edited map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-stop-editing-functions nil
  "Hook for `loophole-stop-editing'.
Functions added to this user option are called with one
argument, which has been edited map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-name-functions nil
  "Hook for `loophole-name'.
Functions added to this user option are called with one
argument, named new map variable."
  :group 'loophole
  :type 'hook)

(defcustom loophole-bind-hook nil
  "Hook for `loophole-bind-entry'.
Because binding commands including `loophole-set-key' and
`loophole-unset-key' finally call `loophole-bind-entry',
this hook is run with all of them."
  :group 'loophole
  :type 'hook)

(defcustom loophole-tag-sign "#"
  "String indicating tag string of Loophole map."
  :group 'loophole
  :type 'string)

(defcustom loophole-mode-lighter-base " L"
  "Lighter base string for mode line."
  :group 'loophole
  :type 'string)

(defcustom loophole-mode-lighter-editing-sign "+"
  "Lighter editing sign string for mode line."
  :group 'loophole
  :type 'string)

(defcustom loophole-mode-lighter-suspending-sign "-"
  "Lighter suspending sign string for mode line."
  :group 'loophole
  :type 'string)

(defcustom loophole-mode-lighter-use-face nil
  "Flag if lighter use face."
  :group 'loophole
  :type 'boolean)

(defconst loophole-mode-lighter-preset-alist
  '((tag . (""
            loophole-mode-lighter-base
            (:eval (if (and (loophole-suspending-p)
                            (not loophole-mode-lighter-use-face))
                       loophole-mode-lighter-suspending-sign))
            (loophole--editing
             (""
              loophole-mode-lighter-editing-sign
              (:eval (let ((tag (get loophole--editing :loophole-tag)))
                       (if (and loophole-mode-lighter-use-face
                                (stringp tag))
                           (propertize (replace-regexp-in-string
                                        "%" "%%" (substitute-command-keys tag))
                                       'face 'loophole-editing)
                         tag)))))
            (:eval
             (let ((l (seq-filter (lambda (a) (symbol-value (car a)))
                                  loophole--map-alist)))
               (if (zerop (length l))
                   ""
                 (concat loophole-tag-sign
                         (mapconcat
                          (lambda (a)
                            (let ((e (replace-regexp-in-string
                                      "%" "%%"
                                      (substitute-command-keys
                                       (let ((tag (get
                                                   (get (car a)
                                                        :loophole-map-variable)
                                                   :loophole-tag)))
                                         (if (stringp tag)
                                             tag
                                           ""))))))
                              (if (and loophole-mode-lighter-use-face
                                       (stringp e))
                                  (propertize e
                                              'face (if (loophole-suspending-p)
                                                        'loophole-suspending
                                                      'loophole-using))
                                e)))
                          l ",")))))))
    (number . (""
               loophole-mode-lighter-base
               (:eval (if (and (loophole-suspending-p)
                               (not loophole-mode-lighter-use-face))
                          loophole-mode-lighter-suspending-sign))
               (loophole--editing loophole-mode-lighter-editing-sign)
               (:eval (let ((n (length
                                (delq nil
                                      (mapcar
                                       (lambda (e) (symbol-value (car e)))
                                       loophole--map-alist)))))
                        (if (zerop n)
                            ""
                          (concat ":"
                                  (let ((s (int-to-string n)))
                                    (if loophole-mode-lighter-use-face
                                        (propertize
                                         s 'face
                                         (if (loophole-suspending-p)
                                             'loophole-suspending
                                           'loophole-using))
                                      s))))))))
    (simple . (""
               loophole-mode-lighter-base
               (:eval (if (loophole-suspending-p)
                          loophole-mode-lighter-suspending-sign))
               (loophole--editing loophole-mode-lighter-editing-sign)))
    (static . loophole-mode-lighter-base))
  "Alist of preset for `loophole-mode-lighter'.
Each element looks like (STYLE . DEFINITION).
STYLE is a symbol which represents DEFINITION.
DEFINITION is a mode line construct.

Four presets are provided:  tag, number, simple and static.
tag:    display lighter-base suffixed with suspending
        status, editing status and concatenated tag strings
        of keymaps.  If no keymaps are enabled, tag suffix
        is omitted.
number: display lighter-base suffixed with suspending
        status, editing status and number of enabled
        keymaps.  If no keymaps are enabled, numeric suffix
        is omitted.
simple: display lighter-base suffixed with suspending
        status and editing status.
static: display lighter-base with no suffix.")
(put 'loophole-mode-lighter-preset-alist 'risky-local-variable t)

(defcustom loophole-mode-lighter
  (cdr (assq 'tag loophole-mode-lighter-preset-alist))
  "Lighter for Loophole mode.
Any mode-line construct is vaild for this variable.
`loophole-mode-lighter-preset-alist' offers preset for this.

Although many user options and constant prefixed with
loophole-mode-lighter- exist, Loophole mode only refers
this variable.  Other user options are materials for the
presets described above.
When you use presets, you can tweak mode-line lighter by
these user options.
Besides, they might be useful when you set your own lighter
format."
  :risky t
  :group 'loophole
  :type 'sexp)

(defface loophole-using
  '((t :inherit error))
  "Face used for section of lighter showing active Loophole map."
  :group 'loophole)

(defface loophole-editing
  '((t))
  "Face used for section of lighter showing editing Loophole map."
  :group 'loophole)

(defface loophole-suspending
  '((t :inherit shadow))
  "Face used for suffixes of lighter while loophole is suspending."
  :group 'loophole)

;;; Auxiliary functions

(defun loophole-map-variable-list ()
  "Return list of all keymap variables for loophole.
Elements are ordered according to `loophole--map-alist'."
  (mapcar (lambda (e)
            (get (car e) :loophole-map-variable))
          loophole--map-alist))

(defun loophole-state-variable-list ()
  "Return list of all state variables for loophole.
Elements are ordered according to `loophole--map-alist'."
  (mapcar #'car loophole--map-alist))

(defun loophole-key-equal (k1 k2)
  "Return t if two key sequences K1 and K2 are equivalent.
Specifically, this function get `key-description' of each
key, and compare them by `equal'."
  (equal (key-description k1) (key-description k2)))

(defun loophole-local-variable-if-set-list ()
  "Return list of symbols which is Loophole local variable if set."
  `(loophole--map-alist
    loophole--editing
    loophole--timer-alist
    loophole--editing-timer
    ,@(seq-filter #'local-variable-if-set-p (loophole-state-variable-list))))

(defun loophole-read-key (prompt)
  "Read and return key sequence for bindings.
PROMPT is a string for reading key.
If `loophole-allow-keyboard-quit' is non-nil,
\\[keyboard-quit] invokes `keyboard-quit'.
Otherwise, \\[keyboard-quit] will be returned as it is read."
  (let* ((menu-prompting nil)
         (key (read-key-sequence prompt nil t)))
    (or (vectorp key) (stringp key)
        (signal 'wrong-type-argument (list 'arrayp key)))
    (and loophole-allow-keyboard-quit
         (loophole-key-equal
          (vconcat (where-is-internal 'keyboard-quit nil t))
          (vconcat key))
         (keyboard-quit))
    key))

(defun loophole-read-map-variable (prompt &optional predicate)
  "`completing-read' existing map-variable and return read one.
PROMPT is used for `completing-read'.

If optional argument PREDICATE is non-nil, it should be
a function which filters candidates for `completing-read'.
Otherwise, bare `loophole-map-variable-list' is used for
candidates.
PREDICATE shoud get one argument, a map variable, and return
non-nil if that map variable should be used for candidates.

If there are no candidates after PREDICATE is applied to
`loophole-map-variable-list', this function finally signals
`user-error'."
  (let ((map-variable-list
         (if predicate
             (seq-filter predicate (loophole-map-variable-list))
           (loophole-map-variable-list)))
        (minibuffer-help-form
         '(let ((completions (all-completions
                              (minibuffer-contents)
                              minibuffer-completion-table
                              minibuffer-completion-predicate))
                (index (cdr
                        (assq 'index
                              loophole--read-map-variable-help-condition)))
                (last (cdr
                       (assq 'last
                             loophole--read-map-variable-help-condition))))
            (if completions
                (progn
                  (if (equal completions last)
                      (push `(index . ,(if (< index (- (length completions) 1))
                                           (1+ index)
                                         0))
                            loophole--read-map-variable-help-condition)
                    (push '(index . 0)
                          loophole--read-map-variable-help-condition)
                    (push `(last . ,completions)
                          loophole--read-map-variable-help-condition))
                  (let* ((i (cdr (assq
                                  'index
                                  loophole--read-map-variable-help-condition)))
                         (map-variable (intern (elt completions i))))
                    (if map-variable (loophole-describe map-variable))))
              (push '(index . 0)
                    loophole--read-map-variable-help-condition)
              (push `(last . ,completions)
                    loophole--read-map-variable-help-condition)))))
    (unwind-protect
        (intern (completing-read prompt map-variable-list nil t))
      (setq loophole--read-map-variable-help-condition '((index . 0) (last)))
      (if (null map-variable-list)
          (user-error "There are no suitable loophole maps")))))

(defun loophole-map-variable-for-keymap (keymap)
  "Return map variable whose value is KEYMAP."
  (let* ((state-variable (car (rassq keymap loophole--map-alist)))
         (map-variable (get state-variable :loophole-map-variable)))
    (if (eq (symbol-value map-variable) keymap)
        map-variable)))

(defun loophole-map-variable-for-key-binding (key)
  "Return map variable for active KEY in `loophole--map-alist'."
  (get (car (seq-find (lambda (a)
                        (let ((binding (lookup-key (cdr a) key)))
                          (and (symbol-value (car a))
                               binding
                               (eq binding (key-binding key)))))
                      loophole--map-alist))
       :loophole-map-variable))

(defun loophole-global-p (map-variable)
  "Non-nil if MAP-VARIABLE is registered as global map."
  (and (loophole-registered-p map-variable)
       (not (local-variable-if-set-p
             (get map-variable :loophole-state-variable)))))

(defun loophole-suspending-p ()
  "Non-nil during suspending Loophole.
During suspension, `loophole--map-alist' is removed from
`emulation-mode-map-alists'.
Consequently, all Loophole maps lose effect while its state
is preserved."
  (not (memq 'loophole--map-alist emulation-mode-map-alists)))

(defun loophole--erase-local-timers (map-variable)
  "Cancel and remove all local timers for MAP-VARIABLE .
This function is intended to be used in `loophole-globalize'
and `loophole-unregister'."
  (mapc (lambda (buffer)
          (with-current-buffer buffer
            (when (local-variable-p 'loophole--timer-alist)
              (let ((timer (cdr (assq map-variable loophole--timer-alist))))
                (if (timerp timer) (cancel-timer timer)))
              (setq loophole--timer-alist
                    (seq-filter (lambda (cell)
                                  (not (eq (car cell) map-variable)))
                                loophole--timer-alist)))))
        (if (listp loophole--buffer-list)
            loophole--buffer-list
          (buffer-list))))

(defun loophole--erase-global-timer (map-variable)
  "Cancel and remove global timer for MAP-VARIABLE.
This function is intended to be used in `loophole-localize'
and `loophole-unregister'."
  (let ((timer
         (cdr (assq map-variable (default-value 'loophole--timer-alist)))))
    (if (timerp timer) (cancel-timer timer)))
  (setq-default loophole--timer-alist
                (seq-filter (lambda (cell)
                              (not (eq (car cell) map-variable)))
                            (default-value 'loophole--timer-alist))))

(defun loophole--replace-map-variable-of-timer (map-variable new-map-variable)
  "Update `loophole--timer-alist' and timer when naming MAP-VARIABLE.
Updated ones refer to NEW-MAP-VARIABLE.
All buffer local alists and timers are updated.
This function is intended to be used in `loophole-name'."
  (if (loophole-global-p new-map-variable)
      (let ((cell (assq map-variable (default-value 'loophole--timer-alist))))
        (when cell
          (setcar cell new-map-variable)
          (let ((timer (cdr cell)))
            (if (timerp timer)
                (timer-set-function
                 timer
                 (lambda (map-variable)
                   (when (loophole-registered-p map-variable)
                     (loophole-disable map-variable)
                     (force-mode-line-update t)))
                 (list new-map-variable))))))
    (mapc (lambda (buffer)
            (with-current-buffer buffer
              (if (local-variable-p 'loophole--timer-alist)
                  (let ((cell (assq map-variable loophole--timer-alist)))
                    (when cell
                      (setcar cell new-map-variable)
                      (let ((timer (cdr cell)))
                        (if (timerp timer)
                            (timer-set-function
                             timer
                             (lambda (map-variable buffer)
                               (if (and (loophole-registered-p map-variable)
                                        (buffer-live-p buffer))
                                   (with-current-buffer buffer
                                     (loophole-disable map-variable)
                                     (force-mode-line-update))))
                             (list new-map-variable (current-buffer))))))))))
          (if (listp loophole--buffer-list)
              loophole--buffer-list
            (buffer-list)))))

(defun loophole--follow-adding-local-variable (_symbol _newval operation where)
  "Update `loophole--buffer-list' for adding local variable.
This function is intented to be used for
`add-variable-watcher'.  Only while Loophole mode is
enabled, this function is added as variable watcher.
When OPERATION is set and WHERE is non-nil, WHERE is added
to `loophole--buffer-list'."
  (when (and (eq operation 'set)
             where
             (not (memq where loophole--buffer-list)))
    (push where loophole--buffer-list)
    (with-current-buffer where
      (add-hook 'change-major-mode-hook
                #'loophole--follow-killing-local-variable nil t)
      (add-hook 'kill-buffer-hook
                #'loophole--follow-killing-local-variable nil t))))

(defun loophole--follow-killing-local-variable ()
  "Update `loophole--buffer-list' for killing local variable.
This function is intended to be added to
`change-major-mode-hook' and `kill-buffer-hook'.
Only while Loophole mode is enabled, this functions is
added to the hooks above."
  (setq loophole--buffer-list (delq (current-buffer) loophole--buffer-list))
  (remove-hook 'change-major-mode-hook
               #'loophole--follow-killing-local-variable t)
  (remove-hook 'kill-buffer-hook
               #'loophole--follow-killing-local-variable t))

(defun loophole-registered-p (map-variable &optional state-variable)
  "Return non-nil if MAP-VARIABLE is registered to loophole.
If optional argument STATE-VARIABLE is not nil,
Return non-nil if both MAP-VARIABLE and STATE-VARIABLE are
registered, and they are associated."
  (and (if state-variable
           (eq state-variable (get map-variable :loophole-state-variable))
         (setq state-variable (get map-variable :loophole-state-variable)))
       (eq map-variable (get state-variable :loophole-map-variable))
       (assq state-variable (default-value 'loophole--map-alist))))

;;; Main functions

;;;###autoload
(defun loophole-register (map-variable state-variable &optional tag
                                       global without-base-map)
  "Register the set of MAP-VARIABLE and STATE-VARIABLE to Loophole.
Optional argument TAG is a tag string which may be shown in
mode line.  TAG should not contain `loophole-tag-sign',
because tag may be prefixed by `loophole-tag-sign' on the
mode-line.

If optional argument GLOBAL is non-nil, MAP-VARIABLE and
STATE-VARIABLE are registered as globalized Loophole map.
It means that STATE-VARIABLE must not be marked as
`make-variable-buffer-local'.  If marked, this function ask
user if `unintern' STATE-VARIABLE is acceptable.
If answer is yes, STATE-VARIABLE is uninterned and interned
again.  Value, function and plist of STATE-VARIABLE are
ported to newly interned STATE-VARIABLE.
Otherwise, register is aborted safely.

On the other hand, if STATE-VARIABLE is not marked as
`make-variable-buffer-local', and GLOBAL is nil,
this function ask user if `make-variable-buffer-local'
STATE-VARIABLE is acceptable.
These query can be skipped with yes by setting t to
`loophole-force-make-variable-buffer-local' and
`loophole-force-unintern'.

Unless WITHOUT-BASE-MAP is non-nil, `loophole-base-map' is
set as parent keymap for MAP-VARIABLE.
 if parent of keymap of MAP-VARIABLE is non-nil When setting
parent keymap, this function ask user if it is overwritten.
This query also can be skipped with yes by setting t to
`loophole-force-overwrite-parent-map'.

If called interactively, read MAP-VARIABLE, STATE-VARIABLE.
When called with prefix argument, read TAG and ask user if
MAP-VARIABLE is registered as GLOBAL and WITHOUT-BASE-MAP."
  (interactive
   (let* ((arg-map-variable
           (intern (completing-read "Map-variable: "
                                    obarray
                                    (lambda (s)
                                      (and (boundp s) (not (keywordp s))
                                           (keymapp (symbol-value s)))))))
          (arg-state-variable
           (intern (completing-read "State-variable: "
                                    obarray
                                    (lambda (s)
                                      (and (boundp s) (not (keywordp s)))))))
          (arg-tag (if (or loophole-make-register-always-read-tag
                           current-prefix-arg)
                       (read-string
                        (format "Tag for keymap %s: " arg-map-variable))))
          (arg-global (if current-prefix-arg (y-or-n-p "Global? ")))
          (arg-without-base-map (if current-prefix-arg
                                    (y-or-n-p "Without base map? "))))
     (list arg-map-variable arg-state-variable arg-tag
           arg-global arg-without-base-map)))
  (cond ((loophole-registered-p map-variable state-variable)
         (user-error "Specified variables are already registered: %s, %s"
                     map-variable state-variable))
        ((memq map-variable (loophole-map-variable-list))
         (user-error "Specified map-variable is already used: %s"
                     map-variable))
        ((memq state-variable (loophole-state-variable-list))
         (user-error "Specified state-variable is already used: %s"
                     state-variable))
        ((seq-find (lambda (a)
                     (let ((keymap (cdr a)))
                       (eq keymap (symbol-value map-variable))))
                   loophole--map-alist)
         (user-error
          "Specified map-variable holds keymap which is already used: %s"
          map-variable)))
  (if (and (not without-base-map)
           (keymap-parent (symbol-value map-variable)))
      (unless (or loophole-force-overwrite-parent-map
                  (yes-or-no-p
                   (format
                    "%s has parent map.  Overwrite it by `loophole-base-map'? "
                    map-variable)))
        (setq without-base-map t)))
  (if global
      (if (local-variable-if-set-p state-variable)
          (if (or loophole-force-unintern
                  (yes-or-no-p (format
                                "%s is defined as local.  Unintern it? "
                                state-variable)))
              (let ((value (if (boundp state-variable)
                               (symbol-value state-variable)))
                    (function (symbol-function state-variable))
                    (plist (symbol-plist state-variable)))
                (unintern (symbol-name state-variable) nil)
                (setq state-variable (intern (symbol-name state-variable)))
                (set state-variable value)
                (fset state-variable function)
                (setplist state-variable plist))
            (user-error (concat "Abort register."
                                "  Local variable if set cannot be used"
                                " for global state-variable"))))
    (unless (local-variable-if-set-p state-variable)
      (if (or loophole-force-make-variable-buffer-local
              (yes-or-no-p (format
                            "%s is defined as global.  Make it local? "
                            state-variable)))
          (make-variable-buffer-local state-variable)
        (user-error (concat "Abort register."
                            "  Gloabl variable cannot be used"
                            " for local state-variable")))))
  (put map-variable :loophole-state-variable state-variable)
  (put state-variable :loophole-map-variable map-variable)
  (put map-variable :loophole-tag tag)
  (setq-default loophole--map-alist
                (cons `(,state-variable . ,(symbol-value map-variable))
                      (default-value 'loophole--map-alist)))
  (mapc (lambda (buffer)
          (with-current-buffer buffer
            (if (local-variable-p 'loophole--map-alist)
                (setq loophole--map-alist
                      (cons `(,state-variable . ,(symbol-value map-variable))
                            loophole--map-alist)))))
        (if (listp loophole--buffer-list)
            loophole--buffer-list
          (buffer-list)))
  (unless without-base-map
    (set-keymap-parent (symbol-value map-variable) loophole-base-map))
  (when (and (listp loophole--buffer-list)
             (not global))
    (mapc (lambda (buffer)
            (with-current-buffer buffer
              (if (local-variable-p state-variable)
                  (add-to-list 'loophole--buffer-list buffer nil #'eq))))
          (buffer-list))
    (add-variable-watcher state-variable
                          #'loophole--follow-adding-local-variable))
  (run-hook-with-args 'loophole-register-functions map-variable))

(defun loophole-unregister (map-variable)
  "Unregister MAP-VARIABLE from loophole."
  (interactive (list (loophole-read-map-variable "Unregister keymap:")))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (if (loophole-global-p map-variable)
      (loophole--erase-global-timer map-variable)
    (loophole--erase-local-timers map-variable))
  (mapc (lambda (buffer)
          (with-current-buffer buffer
            (when (and (local-variable-p 'loophole--editing)
                       (eq loophole--editing map-variable))
              (loophole-stop-editing-timer)
              (loophole-stop-editing))))
        (if (listp loophole--buffer-list)
            loophole--buffer-list
          (buffer-list)))
  (let ((state-variable (get map-variable :loophole-state-variable)))
    (when (listp loophole--buffer-list)
      (remove-variable-watcher state-variable
                               #'loophole--follow-adding-local-variable)
      (mapc (lambda (buffer)
              (with-current-buffer buffer
                (if (and (local-variable-p state-variable)
                         (not (seq-some #'local-variable-p
                                        (loophole-local-variable-if-set-list))))
                    (setq loophole--buffer-list
                          (delq buffer loophole--buffer-list)))))
            loophole--buffer-list))
    (if (eq (keymap-parent (symbol-value map-variable))
            loophole-base-map)
        (set-keymap-parent (symbol-value map-variable) nil))
    (mapc (lambda (buffer)
            (with-current-buffer buffer
              (if (local-variable-p 'loophole--map-alist)
                  (setq loophole--map-alist
                        (seq-filter (lambda (cell)
                                      (not (eq (car cell) state-variable)))
                                    loophole--map-alist)))))
          (if (listp loophole--buffer-list)
              loophole--buffer-list
            (buffer-list)))
    (setq-default loophole--map-alist
                  (seq-filter (lambda (cell)
                                (not (eq (car cell) state-variable)))
                              (default-value 'loophole--map-alist)))
    (put map-variable :loophole-tag nil)
    (put state-variable :loophole-map-variable nil)
    (put map-variable :loophole-state-variable nil))
  (run-hook-with-args 'loophole-unregister-functions map-variable))

(defun loophole-prioritize (map-variable)
  "Give first priority to MAP-VARIABLE.
This is done by move the entry in `loophole--map-alist' to
the front."
  (interactive (list (loophole-read-map-variable "Prioritize keymap: ")))
  (if (loophole-registered-p map-variable)
      (let ((state-variable (get map-variable :loophole-state-variable)))
        (setq loophole--map-alist
              (cons `(,state-variable . ,(symbol-value map-variable))
                    (seq-filter (lambda (cell)
                                  (not (eq (car cell) state-variable)))
                                loophole--map-alist)))
        (setq-default
         loophole--map-alist
         (cons `(,state-variable . ,(symbol-value map-variable))
               (seq-filter (lambda (cell)
                             (not (eq (car cell) state-variable)))
                           (default-value 'loophole--map-alist))))
        (run-hook-with-args 'loophole-prioritize-functions map-variable))
    (user-error "Specified map-variable %s is not registered" map-variable)))

(defun loophole-globalize (map-variable)
  "Make MAP-VARIABLE global."
  (interactive (list (loophole-read-map-variable
                      "Globalize keymap: "
                      (lambda (map-variable)
                        (not (loophole-global-p map-variable))))))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (if (loophole-global-p map-variable)
      (message "Specified map-variable %s is already global" map-variable)
    (let ((state-variable (get map-variable :loophole-state-variable))
          globalized-state-variable)
      (if (or loophole-force-unintern
              (yes-or-no-p (format "%s is defined as local.  Unintern it? "
                                   state-variable)))
          (let ((value (if (boundp state-variable)
                           (symbol-value state-variable)))
                (function (symbol-function state-variable))
                (plist (symbol-plist state-variable)))
            (unintern (symbol-name state-variable) nil)
            (setq globalized-state-variable
                  (intern (symbol-name state-variable)))
            (set globalized-state-variable value)
            (fset globalized-state-variable function)
            (setplist globalized-state-variable plist)
            (force-mode-line-update t))
        (user-error (concat "Abort globalize."
                            "  Local variable if set cannot be used"
                            " for global state-variable")))
      (put map-variable :loophole-state-variable globalized-state-variable)
      (let ((cell (assq state-variable (default-value 'loophole--map-alist))))
        (if (consp cell) (setcar cell globalized-state-variable)))
      (mapc
       (lambda (buffer)
         (with-current-buffer buffer
           (if (local-variable-p 'loophole--map-alist)
               (let ((cell (assq state-variable loophole--map-alist)))
                 (if (consp cell)
                     (setcar cell globalized-state-variable))))
           (if (listp loophole--buffer-list)
               (unless (seq-some
                        #'local-variable-p
                        (loophole-local-variable-if-set-list))
                 (setq loophole--buffer-list
                       (delq buffer loophole--buffer-list))))))
       (if (listp loophole--buffer-list)
           loophole--buffer-list
         (buffer-list))))
    (loophole--erase-local-timers map-variable)
    (run-hook-with-args 'loophole-globalize-functions map-variable)))

(defun loophole-localize (map-variable)
  "Make MAP-VARIABLE local."
  (interactive (list (loophole-read-map-variable "Localize keymap: "
                                                 #'loophole-global-p)))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (if (not (loophole-global-p map-variable))
      (message "Specified map-variable %s is already local" map-variable)
    (let ((state-variable (get map-variable :loophole-state-variable)))
      (if (or loophole-force-make-variable-buffer-local
              (yes-or-no-p (format "%s is defined as gloabl.  Make it local? "
                                   state-variable)))
          (let ((state (symbol-value state-variable)))
            (set state-variable nil)
            (make-variable-buffer-local state-variable)
            (if (listp loophole--buffer-list)
                (add-variable-watcher state-variable
                                      #'loophole--follow-adding-local-variable))
            (set state-variable state)
            (force-mode-line-update t))
        (user-error (concat "Abort localize."
                            "  Gloabl variable cannot be used"
                            " for local state-variable")))
      (loophole--erase-global-timer map-variable)
      (run-hook-with-args 'loophole-localize-functions map-variable))))

(defun loophole-enable (map-variable)
  "Enable the keymap stored in MAP-VARIABLE."
  (interactive
   (list (loophole-read-map-variable
          "Enable keymap temporarily: "
          (lambda (map-variable)
            (not (symbol-value (get map-variable :loophole-state-variable)))))))
  (if (loophole-registered-p map-variable)
      (let ((state-variable (get map-variable :loophole-state-variable)))
        (set state-variable t)
        (run-hook-with-args 'loophole-enable-functions map-variable))
    (user-error "Specified map-variable %s is not registered" map-variable)))

(defun loophole-disable (map-variable)
  "Disable the keymap stored in MAP-VARIABLE."
  (interactive
   (list (loophole-read-map-variable
          "Disable keymap temporarily: "
          (lambda (map-variable)
            (symbol-value (get map-variable :loophole-state-variable))))))
  (if (loophole-registered-p map-variable)
      (let ((state-variable (get map-variable :loophole-state-variable)))
        (set state-variable nil)
        (run-hook-with-args 'loophole-disable-functions map-variable))
    (user-error "Specified map-variable %s is not registered" map-variable)))

(defun loophole-disable-latest ()
  "Disable the lastly added or prioritized active keymap."
  (interactive)
  (let* ((state-variable
          (seq-find #'symbol-value (loophole-state-variable-list)))
         (map-variable (get state-variable :loophole-map-variable)))
    (if map-variable
        (loophole-disable map-variable)
      (user-error "There are no enabled loophole maps"))))

(defun loophole-disable-all ()
  "Disable the all keymaps."
  (interactive)
  (dolist (map-variable (loophole-map-variable-list))
    (loophole-disable map-variable)))

(defun loophole-name (map-variable map-name &optional tag)
  "Name MAP-VARIABLE as MAP-NAME.
If optional argument TAG is non-nil, tag string for the map
is set as TAG; otherwise, initial character of MAP-NAME is
used as tag string.
Old MAP-VARIABLE and corresponding state-variable are
initialized; their documentation is set as nil, they are
unbound, their properties for Loophole are set as nil, they
are removed from `loophole--map-alist'.

If loophole-MAP-NAME-map or loophole-MAP-NAME-map-state have
been already bound, this function signals `user-error'.
Only unbound name can be used for MAP-NAME.

Global or local behavior is also inherited.
loophole-MAP-NAME-map-state is prepared by the same manner
of `loophole-register'.
If global or local property of loophole-MAP-NAME-map-state
does not match with MAP-VARIABLE, this function ask user
if Loophole can fit it.
These query can be skipped with yes by setting t to
`loophole-force-make-variable-buffer-local' and
`loophole-force-unintern' as with `loophole-register'.

When interactive call, this function asks MAP-VARIABLE and
MAP-NAME.  If prefix-argument is non-nil, TAG is also asked.
If MAP-NAME contains `loophole-tag-sign', use a following
string as TAG regardless of the value of prefix-argument."
  (interactive
   (let* ((arg-map-variable (loophole-read-map-variable "Name keymap: "))
          (arg-map-name (read-string (format "New name[%stag] for keymap %s: "
                                             loophole-tag-sign
                                             arg-map-variable)))
          (arg-tag (let ((match (string-match loophole-tag-sign arg-map-name)))
                     (cond (match
                            (prog1
                                (substring arg-map-name
                                           (1+ match)
                                           (length arg-map-name))
                              (setq arg-map-name
                                    (substring arg-map-name 0 match))))
                           (current-prefix-arg
                            (read-string (format "New tag for keymap %s: "
                                                 arg-map-variable)))))))
     (list arg-map-variable arg-map-name arg-tag)))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (unless (< 0 (length map-name))
    (user-error "Name cannot be empty"))
  (let* ((state-variable (get map-variable :loophole-state-variable))
         (map-variable-name (format "loophole-%s-map" map-name))
         (state-variable-name (concat map-variable-name "-state"))
         (tag (or tag (substring map-name 0 1))))
    (let ((named-map-variable (intern map-variable-name))
          (named-state-variable (intern state-variable-name)))
      (let ((bound (seq-find #'boundp
                             (list named-map-variable named-state-variable))))
        (if bound
            (user-error "Specified name %s has already been bound" bound)))
      (if (local-variable-if-set-p state-variable)
          (unless (local-variable-if-set-p named-state-variable)
            (if (or loophole-force-make-variable-buffer-local
                    (yes-or-no-p (format
                                  "%s is defined as global.  Make it local? "
                                  named-state-variable)))
                (make-variable-buffer-local named-state-variable)
              (user-error (concat "Abort naming."
                                  "  Gloabl variable cannot be used"
                                  " for local state-variable"))))
        (if (local-variable-if-set-p named-state-variable)
            (if (or loophole-force-unintern
                    (yes-or-no-p (format
                                  "%s is defined as local.  Unintern it? "
                                  named-state-variable)))
                (let ((function (symbol-function named-state-variable))
                      (plist (symbol-plist named-state-variable)))
                  (unintern (symbol-name named-state-variable) nil)
                  (setq named-state-variable (intern state-variable-name))
                  (fset named-state-variable function)
                  (setplist named-state-variable plist))
              (user-error (concat "Abort naming."
                                  "  Local variable if set cannot be used"
                                  " for global state-variable")))))
      (put named-map-variable 'variable-documentation
           (format "Keymap for temporary use.
Introduced by `loophole-name' for renaming %s
which had been already unbound." map-variable))
      (put named-state-variable 'variable-documentation
           (format "State of `%s'.
Introduced by `loophole-name' for renaming %s
which had been already unbound." named-map-variable state-variable))
      (set named-map-variable (symbol-value map-variable))
      (if (not (local-variable-if-set-p named-state-variable))
          (set named-state-variable (symbol-value state-variable))
        (set-default named-state-variable nil)
        (mapc
         (lambda (buffer)
           (with-current-buffer buffer
             (if (local-variable-p state-variable)
                 (set named-state-variable (symbol-value state-variable)))))
         (if (listp loophole--buffer-list)
             loophole--buffer-list
           (buffer-list))))
      (put named-map-variable :loophole-state-variable named-state-variable)
      (put named-state-variable :loophole-map-variable named-map-variable)
      (put named-map-variable :loophole-tag tag)
      (if (and (local-variable-if-set-p named-state-variable)
               (listp loophole--buffer-list))
          (add-variable-watcher named-state-variable
                                #'loophole--follow-adding-local-variable))
      (let ((cell (assq state-variable (default-value 'loophole--map-alist))))
        (if (consp cell) (setcar cell named-state-variable)))
      (mapc (lambda (buffer)
              (with-current-buffer buffer
                (if (local-variable-p 'loophole--map-alist)
                    (let ((cell (assq state-variable loophole--map-alist)))
                      (if (consp cell) (setcar cell named-state-variable))))))
            (if (listp loophole--buffer-list)
                loophole--buffer-list
              (buffer-list)))
      (mapc (lambda (buffer)
              (with-current-buffer buffer
                (if (and (local-variable-p 'loophole--editing)
                         (eq map-variable loophole--editing))
                    (setq loophole--editing named-map-variable))))
            (if (listp loophole--buffer-list)
                loophole--buffer-list
              (buffer-list)))
      (loophole--replace-map-variable-of-timer map-variable named-map-variable)
      (if (listp loophole--buffer-list)
          (remove-variable-watcher state-variable
                                   #'loophole--follow-adding-local-variable))
      (put map-variable :loophole-tag nil)
      (put state-variable :loophole-map-variable nil)
      (put map-variable :loophole-state-variable nil)
      (makunbound state-variable)
      (makunbound map-variable)
      (put state-variable 'variable-documentation nil)
      (put map-variable 'variable-documentation nil)
      (run-hook-with-args 'loophole-name-functions named-map-variable))))

(defun loophole-tag (map-variable tag)
  "Set TAG to tag string of MAP-VARIABLE."
  (interactive
   (let* ((arg-map-variable
           (loophole-read-map-variable "Tag keymap: "))
          (arg-tag (read-string
                    (format "New tag for keymap %s%s%s: "
                            arg-map-variable
                            loophole-tag-sign
                            (get arg-map-variable :loophole-tag)))))
     (list arg-map-variable arg-tag)))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (put map-variable :loophole-tag tag)
  (force-mode-line-update t))

(defun loophole-start-editing (map-variable)
  "Start keymap editing session with MAP-VARIABLE."
  (interactive (list (loophole-read-map-variable "Start editing keymap: ")))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (setq loophole--editing map-variable)
  (run-hook-with-args 'loophole-start-editing-functions map-variable))

(defun loophole-stop-editing ()
  "Stop keymap editing session."
  (interactive)
  (let ((map-variable loophole--editing))
    (setq loophole--editing nil)
    (run-hook-with-args 'loophole-stop-editing-functions map-variable)))

(defun loophole-generate ()
  "Return Loophole map variable whose value is newly generated keymap.

Name of map variable is loophole-n-map.
If the number of temporary keymap is
`loophole-temporary-map-max' or higher, disabled earliest
used one, unregistered one or enabled earliest used one will
be overwritten by new sparse keymap.

This function also binds state variable for map variable.
State variable is named as map-variable-state."
  (let* ((map-variable
          (let ((reversal-map-variable-list
                 (reverse (mapcar (lambda (e)
                                    (get (car e) :loophole-map-variable))
                                  (default-value 'loophole--map-alist)))))
            (letrec ((find-nonbound-temporary-map-variable
                      (lambda (i)
                        (let ((s (intern (format "loophole-%d-map" i))))
                          (cond ((< loophole-temporary-map-max i) nil)
                                ((boundp s)
                                 (funcall
                                  find-nonbound-temporary-map-variable (1+ i)))
                                (t (progn
                                     (put s 'variable-documentation
                                          "Keymap for temporary use.
Generated by `loophole-generate'.")
                                     s))))))
                     (find-earliest-used-disabled-temporary-map-variable
                      (lambda ()
                        (seq-find
                         (lambda (map-var)
                           (and (not
                                 (seq-some
                                  (lambda (buffer)
                                    (with-current-buffer buffer
                                      (let ((state-var
                                             (get map-var
                                                  :loophole-state-variable)))
                                        (symbol-value state-var))))
                                  (if (listp loophole--buffer-list)
                                      loophole--buffer-list
                                    (buffer-list))))
                                (string-match
                                 "loophole-[0-9]+-map"
                                 (symbol-name map-var))))
                         reversal-map-variable-list)))
                     (find-orphan-temporary-map-variable
                      (lambda (i)
                        (let ((s (intern
                                  (format "loophole-%d-map" i))))
                          (cond ((< loophole-temporary-map-max i) nil)
                                ((memq s reversal-map-variable-list)
                                 (funcall
                                  find-orphan-temporary-map-variable (1+ i)))
                                (t s)))))
                     (find-earliest-used-temporary-map-variable
                      (lambda ()
                        (seq-find (lambda (map-var)
                                    (string-match
                                     "loophole-[0-9]+-map"
                                     (symbol-name map-var)))
                                  reversal-map-variable-list))))
              (or (funcall find-nonbound-temporary-map-variable 1)
                  (funcall find-earliest-used-disabled-temporary-map-variable)
                  (funcall find-orphan-temporary-map-variable 1)
                  (funcall find-earliest-used-temporary-map-variable)
                  (error
                   "Loophole maps or `loophole--map-alist' might be broken")))))
         (state-variable (let ((s (intern (concat (symbol-name map-variable)
                                                  "-state"))))
                           (unless (boundp s)
                             (put s 'variable-documentation
                                  (format "State of `%s'.
Generated by `loophole-generate'." map-variable)))
                           s))
         (tag (replace-regexp-in-string
               "loophole-\\([0-9]+\\)-map" "\\1"
               (symbol-name map-variable))))
    (set map-variable (make-sparse-keymap))
    (if (local-variable-if-set-p state-variable)
        (unless (boundp state-variable) (setq-default state-variable nil))
      (if (loophole-global-p map-variable)
          (loophole-localize map-variable)
        (make-variable-buffer-local state-variable)))
    (mapc (lambda (buffer)
            (with-current-buffer buffer
              (when (and (local-variable-p state-variable)
                         (boundp state-variable)
                         (symbol-value state-variable))
                (set state-variable nil)
                (force-mode-line-update))))
          (if (listp loophole--buffer-list)
              loophole--buffer-list
            (buffer-list)))
    (unless (loophole-registered-p map-variable state-variable)
      (loophole-register map-variable state-variable tag))
    map-variable))

(defun loophole-ready-map ()
  "Return available temporary keymap.
If currently editing keymap exists, return it; otherwise
generate new one, prepare it, and return it."
  (let ((map-variable
         (cond (loophole--editing loophole--editing)
               (t (let ((generated (loophole-generate)))
                    (loophole-enable generated)
                    (loophole-start-editing generated)
                    generated)))))
    (symbol-value map-variable)))

(defun loophole-start-timer (map-variable &optional time)
  "Setup or update timer for disabling MAP-VARIABLE.
If optional argument TIME is integer describing time in
second, use it for timer; otherwise use
`loophole-timer-default-time'.

When called interactively, TIME is asked if prefix argument
is non-nil."
  (interactive
   (let* ((arg-map-variable
           (loophole-read-map-variable
            "Start timer for keymap: "
            (lambda (map-variable)
              (symbol-value (get map-variable :loophole-state-variable)))))
          (arg-time
           (if current-prefix-arg
               (read-number (format "Time for disabling keymap %s in sec: "
                                    arg-map-variable)
                            loophole-timer-default-time))))
     (list arg-map-variable arg-time)))
  (unless (integerp time) (setq time loophole-timer-default-time))
  (let ((timer (cdr (assq map-variable
                          (if (loophole-global-p map-variable)
                              (default-value 'loophole--timer-alist)
                            loophole--timer-alist)))))
    (if (timerp timer)
        (progn
          (timer-set-time timer (timer-relative-time nil time))
          (if (or (timer--triggered timer)
                  (not (memq timer timer-list)))
              (timer-activate timer)))
      (if (loophole-global-p map-variable)
          (setq-default loophole--timer-alist
                        (cons `(,map-variable
                                .
                                ,(run-with-timer
                                  time
                                  nil
                                  (lambda (map-variable)
                                    (when (loophole-registered-p map-variable)
                                      (loophole-disable map-variable)
                                      (force-mode-line-update t)))
                                  map-variable))
                              (default-value 'loophole--timer-alist)))
        (setq loophole--timer-alist
              (cons `(,map-variable
                      .
                      ,(run-with-timer
                        time
                        nil
                        (lambda (map-variable buffer)
                          (if (and (loophole-registered-p map-variable)
                                   (buffer-live-p buffer))
                              (with-current-buffer buffer
                                (loophole-disable map-variable)
                                (force-mode-line-update))))
                        map-variable (current-buffer)))
                    (if (local-variable-p 'loophole--timer-alist)
                        loophole--timer-alist)))))))

(defun loophole-stop-timer (map-variable)
  "Cancel timer for disabling MAP-VARIABLE."
  (interactive
   (list (loophole-read-map-variable
          "Stop timer for keymap: "
          (lambda (map-variable)
            (let ((timer (cdr (assq map-variable
                                    (if (loophole-global-p map-variable)
                                        (default-value 'loophole--timer-alist)
                                      loophole--timer-alist)))))
              (and (timerp timer)
                   (not (timer--triggered timer))
                   (memq timer timer-list)))))))
  (let ((timer (cdr (assq map-variable
                          (if (loophole-global-p map-variable)
                              (default-value 'loophole--timer-alist)
                            loophole--timer-alist)))))
    (if (and (timerp timer)
             (not (timer--triggered timer))
             (memq timer timer-list))
        (cancel-timer timer))))

(defun loophole-extend-timer (map-variable time)
  "Extend time of timer for MAP-VARIABLE by time in second.
If TIME is negative, shorten timer."
  (interactive
   (let* ((arg-map-variable
           (loophole-read-map-variable
            "Extend time of timer for keymap: "
            (lambda (map-variable)
              (let ((timer (cdr (assq map-variable
                                      (if (loophole-global-p map-variable)
                                          (default-value 'loophole--timer-alist)
                                        loophole--timer-alist)))))
                (and (timerp timer)
                     (not (timer--triggered timer))
                     (memq timer timer-list))))))
          (arg-time
           (read-number
            (format "Time to extend timer for %s in sec: "
                    arg-map-variable)
            loophole-timer-default-time)))
     (list arg-map-variable arg-time)))
  (unless (integerp time) (error "Specified time is invalid: %s" time))
  (let ((timer (cdr (assq map-variable
                          (if (loophole-global-p map-variable)
                              (default-value 'loophole--timer-alist)
                            loophole--timer-alist)))))
    (if (timerp timer)
        (progn
          (timer-set-time timer (timer-relative-time (timer--time timer) time))
          (if (or (timer--triggered timer)
                  (not (memq timer timer-list)))
              (timer-activate timer)))
      (message "Timer for keymap %s does not exist" map-variable))))

(defun loophole-start-editing-timer (&optional time)
  "Setup or update timer for stopping editing session.
If optional argument TIME is integer describing time in
second, use it for timer; otherwise use
`loophole-editing-timer-default-time'.

When called interactively, TIME is asked if prefix argument
is non-nil."
  (interactive
   (list (if current-prefix-arg
             (read-number "Time for stopping editing in sec: "
                          loophole-editing-timer-default-time))))
  (unless (integerp time) (setq time loophole-editing-timer-default-time))
  (if (timerp loophole--editing-timer)
      (progn
        (timer-set-time loophole--editing-timer (timer-relative-time nil time))
        (if (or (timer--triggered loophole--editing-timer)
                (not (memq loophole--editing-timer timer-list)))
            (timer-activate loophole--editing-timer)))
    (setq loophole--editing-timer
          (run-with-timer time nil (lambda (buffer)
                                     (if (buffer-live-p buffer)
                                         (with-current-buffer buffer
                                           (loophole-stop-editing)
                                           (force-mode-line-update))))
                          (current-buffer))))
  (if (called-interactively-p 'interactive)
      (message "Editing timer is started")))

(defun loophole-stop-editing-timer ()
  "Cancel timer for stopping editing session."
  (interactive)
  (if (and (timerp loophole--editing-timer)
           (not (timer--triggered loophole--editing-timer))
           (memq loophole--editing-timer timer-list))
      (progn
        (cancel-timer loophole--editing-timer)
        (if (called-interactively-p 'interactive)
            (message "Editing timer is stopped")))
    (if (called-interactively-p 'interactive)
        (message "No active editing timer exist"))))

(defun loophole-extend-editing-timer (time)
  "Extend time of editing timer by TIME in second.
If TIME is negative, shorten timer."
  (interactive
   (list (read-number "Time to extend editing timer in sec: "
                      loophole-editing-timer-default-time)))
  (unless (integerp time) (error "Specified time is invalid: %s" time))
  (if (timerp loophole--editing-timer)
      (progn
        (timer-set-time loophole--editing-timer
                        (timer-relative-time
                         (timer--time loophole--editing-timer) time))
        (if (or (timer--triggered loophole--editing-timer)
                (not (memq loophole--editing-timer timer-list)))
            (timer-activate loophole--editing-timer)))
    (message "Editing timer does not exist")))

(defun loophole-describe (map-variable)
  "Display all key bindings in MAP-VARIABLE."
  (interactive (list (loophole-read-map-variable "Describe keymap: ")))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (help-setup-xref `(loophole-describe ,map-variable)
                   (called-interactively-p 'interactive))
  (with-help-window (help-buffer)
    (princ (format "`%s' %sLoophole Map Bindings:\n"
                   map-variable (if (loophole-global-p map-variable)
                                    "Globalized "
                                  "")))
    (princ (substitute-command-keys
            (format "\\{%s}" map-variable)))
    (with-current-buffer standard-output
      (save-excursion
        (re-search-backward "`\\([^`']+\\)'" nil t)
        (help-xref-button 1 'help-variable map-variable)))))

;;; Binding utilities

(define-derived-mode loophole-write-lisp-mode emacs-lisp-mode
  "Loophole Write Lisp"
  "Auxiliary major mode for writing Lisp form in Loophole.
Calling this major mode in Lisp program offers
`emacs-lisp-mode' like environment with few key bindings and
recursive edit.
After finish or abort writing, caller can get written
forms by `buffer-string'.
If writing is finished, forms following calling this
function will be evaluated.
In order to do something even for abort case, call this
function in body form of `unwind-protect' and write follow
up forms in unwind forms."
  :group 'loophole
  (setq header-line-format
        `(""
          mode-line-front-space
          ,(substitute-command-keys
            (concat "\\<loophole-write-lisp-mode-map>"
                    "Writing lisp form.  "
                    "finish `\\[loophole-finish-writing-lisp]', "
                    "Abort `\\[loophole-abort-writing-lisp]'."))))
  (recursive-edit))

(defun loophole-finish-writing-lisp ()
  "Finish writing Lisp form in `loophole-write-lisp-mode' buffer."
  (interactive)
  (unless (zerop (recursion-depth))
    (if (eq major-mode 'loophole-write-lisp-mode)
        (emacs-lisp-mode))
    (exit-recursive-edit)))

(defun loophole-abort-writing-lisp ()
  "Abort writing Lisp form in `loophole-write-lisp-mode' buffer."
  (interactive)
  (unless (zerop (recursion-depth))
    (if (eq major-mode 'loophole-write-lisp-mode)
        (emacs-lisp-mode))
    (abort-recursive-edit)))

(defun loophole-start-kmacro ()
  "Start defining keyboard macro.
Definition can be finished by calling `loophole-end-kmacro'."
  (interactive)
  (kmacro-start-macro nil)
  (let* ((end (where-is-internal 'loophole-end-kmacro nil t))
         (abort (where-is-internal 'loophole-abort-kmacro nil t))
         (prefix (if (or end abort)
                     "Defining keyboard macro... "
                   "Defining kmacro "))
         (body (format "[End: %s, Abort: %s]"
                       (if end
                           (key-description end)
                         "M-x loophole-end-kmacro")
                       (if abort
                           (key-description abort)
                         "M-x loophole-abort-kmacro"))))
    (message "%s%s" prefix body))
  (unless (called-interactively-p 'any) (recursive-edit)))

(defun loophole-end-kmacro ()
  "End defining keyboard macro."
  (interactive)
  (unwind-protect
      (kmacro-end-macro nil)
    (unless (zerop (recursion-depth)) (exit-recursive-edit))))

(defun loophole-abort-kmacro ()
  "Abort defining keyboard macro."
  (interactive)
  (unless (zerop (recursion-depth)) (abort-recursive-edit))
  (keyboard-quit))

(defun loophole-read-key-for-kmacro-by-read-key ()
  "`loophole-read-key' with checking finish and quit key."
  (let ((finish (vconcat loophole-kmacro-by-read-key-finish-key))
        (quit (vconcat (where-is-internal 'keyboard-quit nil t))))
    (or (not (zerop (length finish)))
        (not (zerop (length quit)))
        (user-error "Neither finishing key nor quitting key is invalid")))
  (loophole-read-key "Set key temporarily: "))

(defun loophole-read-key-for-array-by-read-key ()
  "`loophole-read-key' with checking finish and quit key."
  (let ((finish (vconcat loophole-array-by-read-key-finish-key))
        (quit (vconcat (where-is-internal 'keyboard-quit nil t))))
    (or (not (zerop (length finish)))
        (not (zerop (length quit)))
        (user-error "Neither finishing key nor quitting key is invalid")))
  (loophole-read-key "Set key temporarily: "))

(defun loophole-prefix-arg-rank (arg)
  "Return rank value for raw prefix argument ARG.
In the context of this function, rank of prefix argument is
defined as follows.
The rank of no prefix argument is 0.
The rank of prefix argument specified by \\[universal-argument] and C-1 is 1,
The rank of \\[universal-argument] \\[universal-argument] and C-2 is 2,
Likewise, rank n means \\[universal-argument] * n or C-[n].
For the `negative-argument', the rank is
`prefix-numeric-value' of prefix argument."
  (cond ((null arg) 0)
        ((listp arg) (truncate (log (prefix-numeric-value arg) 4)))
        ((natnump arg) arg)
        (t (prefix-numeric-value arg))))

(defun loophole--arg-list (order prefix-argument &optional without-keymap)
  "Return list of arguments for binding commands.
Read key, obtain Lisp object for binding, and optionaly
obtain keymap object for key and binding based on ORDER and
PREFIX-ARGUMENT .
If optional argument WITHOUT-KEYMAP is non-nil, this
function does not try to obtain keymap, and return list of
key and binding only."
  (let ((n (loophole-prefix-arg-rank prefix-argument)))
    (if (< (1- (length order)) n)
        (user-error "Undefined prefix argument"))
    (let ((decide-obtaining-method
           (lambda (m)
             (if (< m 0)
                 (let ((alist (mapcar (lambda (e) (cons (format "%s" e) e))
                                      order)))
                   (cdr (assoc
                         (completing-read "Obtaining method: " alist nil t)
                         alist)))
               (elt order m))))
          (get-read-key-function
           (lambda (spec)
             (if (consp spec)
                 (plist-get (cdr spec) :key))))
          (get-obtain-entry-function
           (lambda (spec)
             (cond ((functionp spec) spec)
                   ((consp spec) (car spec))
                   (t (error "Obtaining method %s is invalid" spec)))))
          (get-obtain-keymap-function
           (lambda (spec)
             (if (consp spec)
                 (plist-get (cdr spec) :keymap))))
          obtaining-method-spec
          read-key-function
          obtain-entry-function
          obtain-keymap-function)
      (unless (or (eq loophole-decide-obtaining-method-after-read-key t)
                  (and (eq loophole-decide-obtaining-method-after-read-key
                           'negative-argument)
                       (< n 0)))
        (setq obtaining-method-spec (funcall decide-obtaining-method n))
        (setq read-key-function
              (funcall get-read-key-function obtaining-method-spec))
        (setq obtain-entry-function
              (funcall get-obtain-entry-function obtaining-method-spec))
        (setq obtain-keymap-function
              (unless without-keymap
                (funcall get-obtain-keymap-function obtaining-method-spec))))
      (let ((arg-key
             (if read-key-function
                 (funcall read-key-function)
               (loophole-read-key "Set key temporarily: "))))
        (when (or (eq loophole-decide-obtaining-method-after-read-key t)
                  (and (eq loophole-decide-obtaining-method-after-read-key
                           'negative-argument)
                       (< n 0)))
          (setq obtaining-method-spec (funcall decide-obtaining-method n))
          (setq obtain-entry-function
                (funcall get-obtain-entry-function obtaining-method-spec))
          (setq obtain-keymap-function
                (unless without-keymap
                  (funcall get-obtain-keymap-function obtaining-method-spec))))
        (let* ((arg-entry (funcall obtain-entry-function arg-key))
               (arg-keymap (if (and (not without-keymap)
                                    obtain-keymap-function)
                               (funcall obtain-keymap-function
                                        arg-key
                                        arg-entry))))
          (if without-keymap
              (list arg-key arg-entry)
            (list arg-key arg-entry arg-keymap)))))))

;;; Obtaining methods

(defun loophole-obtain-object (key)
  "Return any Lisp object.
Object is obtained as return value of `eval-minibuffer'.
Read minibuffer with prompt in which KEY is embedded."
  (eval-minibuffer (format "Set key %s to entry: " (key-description key))))

(defun loophole-obtain-command-by-read-command (key)
  "Return command obtained by reading command symbol.
Read command with prompt in which KEY is embedded."
  (read-command (format "Set key %s to command: " (key-description key))))

(defun loophole-obtain-command-by-key-sequence (key)
  "Return command obtained by key sequence lookup.
Read key sequence with prompt in which KEY is embedded."
  (let ((binding (key-binding (loophole-read-key
                               (format
                                "Set key %s to command bound for: "
                                (key-description key))))))
    (message "%s" binding)
    binding))

(defun loophole-obtain-command-by-lambda-form (_key)
  "Return command obtained by writing lambda form.
This function provides work space for writing lambda form as
a temporary buffer.
Actually, any Lisp forms can be written in a temporary
buffer, and if return value of evaluating first form is
valid lambda command, this function return it."
  (let ((buffer (current-buffer))
        (window (selected-window))
        (frame (selected-frame))
        (configuration-list (mapcar #'current-window-configuration
                                      (frame-list))))
    (unwind-protect
        (let ((workspace (get-buffer-create "*Loophole*")))
          (switch-to-buffer-other-window workspace t)
          (erase-buffer)
          (insert ";; For obtaining lambda form.\n\n")
          (insert loophole-command-by-lambda-form-format)
          (let ((found (search-backward "(#)" nil t)))
            (if found (delete-region (point) (+ (point) 3))))
          (loophole-write-lisp-mode)
          (with-current-buffer workspace (goto-char 1))
          (let ((lambda-form (eval (read workspace))))
            (if (and (commandp lambda-form)
                     (listp lambda-form)
                     (eq (car lambda-form) 'lambda))
                lambda-form
              (user-error
               "Obtained Lisp object is not valid lambda command: %s"
               lambda-form))))
      (let ((configuration
             (seq-find (lambda (c)
                         (eq (selected-frame) (window-configuration-frame c)))
                       configuration-list)))
        (if configuration
            (set-window-configuration configuration)
          (delete-frame)))
      (if (frame-live-p frame) (select-frame-set-input-focus frame t))
      (if (window-live-p window) (select-window window t))
      (if (buffer-live-p buffer) (switch-to-buffer buffer t t)))))

(defun loophole-obtain-kmacro-by-read-key (key)
  "Return kmacro obtained by reading key.
This function `read-key' recursively with prompt in which
KEY is embedded.  When you finish keyboard macro, type
`loophole-kmacro-by-read-key-finish-key'.
By default, `loophole-kmacro-by-read-key-finish-key' is \\[keyboard-quit]
the key bound to `keyboard-quit'.  In this situation, you
cannot use \\[keyboard-quit] for quitting.
Once `loophole-kmacro-by-read-key-finish-key' is changed,
you can finish definition of kmacro by new finish key, and
\\[keyboard-quit] takes effect as quit."
  (let ((finish (vconcat loophole-kmacro-by-read-key-finish-key))
        (quit (vconcat (where-is-internal 'keyboard-quit nil t))))
    (or (not (zerop (length finish)))
        (not (zerop (length quit)))
        (user-error "Neither finishing key nor quitting key is invalid"))
    (let ((menu-prompting nil))
      (letrec
          ((read-arbitrary-key-sequence
            (lambda (v)
              (let* ((k (vector
                         (read-key
                          (format "Set key %s to kmacro: (%s to %s) [%s]"
                                  (key-description key)
                                  (if (zerop (length finish))
                                      (key-description quit)
                                    (key-description finish))
                                  (if (zerop (length finish))
                                      "quit"
                                    "finish")
                                  (mapconcat (lambda (e)
                                               (key-description (vector e)))
                                             (reverse v)
                                             " ")))))
                     (k-v (vconcat k v)))
                (cond ((and (not (zerop (length finish)))
                            (loophole-key-equal (seq-take k-v (length finish))
                                                finish))
                       (seq-take (reverse k-v)
                                 (- (length k-v) (length finish))))
                      ((and (not (zerop (length quit)))
                            (loophole-key-equal (seq-take k-v (length quit))
                                                quit))
                       (keyboard-quit))
                      (t (funcall read-arbitrary-key-sequence k-v)))))))
        (let ((macro (funcall read-arbitrary-key-sequence [])))
          (kmacro-start-macro nil)
          (end-kbd-macro nil #'kmacro-loop-setup-function)
          (setq last-kbd-macro macro)
          (kmacro-lambda-form (kmacro-ring-head)))))))

(defun loophole-obtain-kmacro-by-recursive-edit (_key)
  "Return kmacro obtained by recursive edit.
\\<loophole-mode-map>
This function starts recursive edit in order to offer
keyboard macro defining work space.  Definition can be
finished by calling `loophole-end-kmacro' which is bound to
\\[loophole-end-kmacro].
Besides, Definition can be aborted by calling
`loophole-abort-kmacro' which is bound to \\[loophole-abort-kmacro].
\\<loophole-kmacro-by-recursive-edit-map>
If `loophole-kmacro-by-recursive-edit-map-flag' is non-nil,
special keymap `loophole-kmacro-by-recursive-edit-map' is
enabled only during recursive edit.
Actually, `loophole-kmacro-by-recursive-edit-map' is
registered to Loophole as a gloabl map, and unregistered
after recursive edit is ended.
In this case, `loophole-end-kmacro' is bound to \\[loophole-end-kmacro].
and `loophole-abort-kmacro' is bound to \\[loophole-abort-kmacro]."
  (loophole-register 'loophole-kmacro-by-recursive-edit-map
                     'loophole-kmacro-by-recursive-edit-map-flag
                      loophole-kmacro-by-recursive-edit-map-tag
                      t)
  (unwind-protect
      (loophole-start-kmacro)
    (loophole-unregister 'loophole-kmacro-by-recursive-edit-map))
  (kmacro-lambda-form (kmacro-ring-head)))

(defun loophole-obtain-kmacro-by-recall-record (key)
  "Return kmacro obtained by recalling record.
Completing read record with prompt in which KEY is embedded."
  (letrec
      ((make-label-kmacro-alist
        (lambda (ring counter)
          (let* ((raw-label (key-description (car (car ring))))
                 (entry (assoc raw-label counter))
                 (number (if entry (1+ (cdr entry)) 1))
                 (label (if entry
                            (format "%s <%d>" raw-label number)
                          raw-label)))
            (cond ((null ring) ring)
                  (t (cons
                      `(,label . ,(car ring))
                      (funcall make-label-kmacro-alist
                               (cdr ring)
                               (cons `(,raw-label . ,number) counter)))))))))
    (let* ((head (kmacro-ring-head))
           (alist (funcall make-label-kmacro-alist
                           (if head
                               (cons head kmacro-ring)
                             kmacro-ring)
                           nil))
           (read (completing-read (format "Set key %s to kmacro: "
                                          (key-description key))
                                  alist nil t)))
      (kmacro-lambda-form (cdr (assoc read alist))))))

(defun loophole-obtain-array-by-read-key (key)
  "Return array obtained by reading key.
This function `read-key' recursively with prompt in which
KEY is embedded.  When you finish inputting key sequence,
type `loophole-array-by-read-key-finish-key'.
By default, `loophole-array-by-read-key-finish-key' is \\[keyboard-quit]
the key bound to `keyboard-quit'.  In this situation, you
cannot use \\[keyboard-quit] for quitting.
Once `loophole-array-by-read-key-finish-key' is changed, you
can finish definition of array by new finish key, and \\[keyboard-quit]
takes effect as quit."
  (let ((finish (vconcat loophole-array-by-read-key-finish-key))
        (quit (vconcat (where-is-internal 'keyboard-quit nil t))))
    (or (not (zerop (length finish)))
        (not (zerop (length quit)))
        (user-error "Neither finishing key nor quitting key is invalid"))
    (let ((menu-prompting nil))
      (letrec
          ((read-arbitrary-key-sequence
            (lambda (v)
              (let* ((k (vector
                         (read-key
                          (format "Set key %s to array: (%s to %s) [%s]"
                                  (key-description key)
                                  (if (zerop (length finish))
                                      (key-description quit)
                                    (key-description finish))
                                  (if (zerop (length finish))
                                      "quit"
                                    "finish")
                                  (mapconcat (lambda (e)
                                               (key-description (vector e)))
                                             (reverse v)
                                             " ")))))
                     (k-v (vconcat k v)))
                (cond ((and (not (zerop (length finish)))
                            (loophole-key-equal (seq-take k-v (length finish))
                                                finish))
                       (seq-take (reverse k-v)
                                 (- (length k-v) (length finish))))
                      ((and (not (zerop (length quit)))
                            (loophole-key-equal (seq-take k-v (length quit))
                                                quit))
                       (keyboard-quit))
                      (t (funcall read-arbitrary-key-sequence k-v)))))))
        (funcall read-arbitrary-key-sequence [])))))

(defun loophole-obtain-array-by-read-string (key)
  "Return array obtained by `read-string'.
Read string with prompt in which KEY is embedded ."
  (read-string (format "Set key %s to array: " (key-description key))))

(defun loophole-obtain-keymap-by-read-keymap-variable (key)
  "Return keymap obtained by reading keymap variable.
Read keymap variable with prompt in which KEY is embedded."
  (symbol-value
   (intern
    (completing-read
     (format "Set key %s to keymap bound to symbol: " (key-description key))
     obarray
     (lambda (s)
       (and (boundp s)
            (not (keywordp s))
            (keymapp (symbol-value s))))))))

(defun loophole-obtain-keymap-by-read-keymap-function (key)
  "Return keymap obtained by reading keymap function.
Read keymap function with prompt in which KEY is embedded.
Keymap function is a symbol whose function cell is a keymap
or a symbol whose function cell is ultimately a keymap."
  (letrec ((symbol-function-recursively
            (lambda (s)
              (let ((f (symbol-function s)))
                (cond ((eq f s) f)
                      ((not (symbolp f)) f)
                      (t (funcall symbol-function-recursively f)))))))
    (funcall symbol-function-recursively
             (intern
              (completing-read
               (format "Set key %s to keymap fbound to symbol: "
                       (key-description key))
               obarray
               (lambda (s)
                 (let ((f (funcall symbol-function-recursively s)))
                   (keymapp f))))))))

(defun loophole-obtain-symbol-by-read-keymap-function (key)
  "Return symbol obtained by reading keymap function.
Read keymap function with prompt in which KEY is embedded.
Keymap function is a symbol whose function cell is a keymap
or a symbol whose function cell is ultimately a keymap."
  (letrec ((symbol-function-recursively
            (lambda (s)
              (let ((f (symbol-function s)))
                (cond ((eq f s) f)
                      ((not (symbolp f)) f)
                      (t (funcall symbol-function-recursively f)))))))
    (intern
     (completing-read
      (format "Set key %s to symbol whose function cell is keymap: "
              (key-description key))
      obarray
      (lambda (s)
        (let ((f (funcall symbol-function-recursively s)))
          (keymapp f)))))))

(defun loophole-obtain-symbol-by-read-command (key)
  "Return symbol obtained by reading command symbol.
Read command with prompt in which KEY is embedded."
  (read-command
   (format "Set key %s to symbol whose function cell is command: "
           (key-description key))))

(defun loophole-obtain-symbol-by-read-array-function (key)
  "Return symbol obtained by reading array function.
Read array function with prompt in which KEY is embedded.
Array function is a symbol whose function cell is an array
or a symbol whose function cell is ultimately an array."
  (letrec ((symbol-function-recursively
            (lambda (s)
              (let ((f (symbol-function s)))
                (cond ((eq f s) f)
                      ((not (symbolp f)) f)
                      (t (funcall symbol-function-recursively f)))))))
    (intern
     (completing-read
      (format "Set key %s to symbol whose function cell is array: "
              (key-description key))
      obarray
      (lambda (s)
        (let ((f (funcall symbol-function-recursively s)))
          (or (vectorp f) (stringp f))))))))

;;; Binding commands

;;;###autoload
(defun loophole-bind-entry (key entry &optional keymap)
  "Bind KEY to ENTRY temporarily.
Any Lisp object is acceptable for ENTRY, but only few types
make sense.  Meaningful types of ENTRY is completely same as
general keymap entry.

By default, KEY is bound in the currently editing keymap or
generated new one.  If optional argument KEYMAP is non-nil,
and it is registered to Loophole, KEYMAP is used instead.

When called interactively, this function decides
obtaining method for ENTRY according to
`loophole-bind-entry-order', prefix argument and
`loophole-decide-obtaining-method-after-read-key'.
When this function called without prefix argument,
the first element of `loophole-bind-entry-order' is
employed as obtaining method.
\\[universal-argument] and C-1 invokes the second element,
\\[universal-argument] \\[universal-argument] and C-2 invokes the third one.
Likewise \\[universal-argument] * n and C-[n] invoke the (n+1)th element.
If `negative-argument' is used, `completing-read' obtaining
method.  `loophole-decide-obtaining-method-after-read-key'
affects the timing of this `completing-read'."
  (interactive
   (loophole--arg-list loophole-bind-entry-order current-prefix-arg))
  (define-key
    (if keymap
        (let ((map-variable (loophole-map-variable-for-keymap keymap)))
          (if (and map-variable
                   (loophole-registered-p map-variable))
              keymap
            (user-error "Invalid keymap: %s" keymap)))
      (loophole-ready-map))
    key
    entry)
  (run-hooks 'loophole-bind-hook))

;;;###autoload
(defun loophole-bind-command (key command &optional keymap)
  "Bind KEY to COMMAND temporarily.
COMMAND must be a command.

This function finally calls `loophole-bind-entry', so that
the keymap used for binding and the meaning of optional
arguments KEYMAP are same as `loophole-bind-entry'.
See docstring of `loophole-bind-entry'for more details.

When called interactively, this function decides
obtaining method for COMMAND according to
`loophole-bind-command-order', prefix argument and
`loophole-decide-obtaining-method-after-read-key'.
When this function called without prefix argument,
the first element of `loophole-bind-command-order' is
employed as obtaining method.
\\[universal-argument] and C-1 invokes the second element,
\\[universal-argument] \\[universal-argument] and C-2 invokes the third one.
Likewise \\[universal-argument] * n and C-[n] invoke the (n+1)th element.
If `negative-argument' is used, `completing-read' obtaining
method.  `loophole-decide-obtaining-method-after-read-key'
affects the timing of this `completing-read'."
  (interactive
   (loophole--arg-list loophole-bind-command-order current-prefix-arg))
  (if (commandp command)
      (loophole-bind-entry key command keymap)
    (user-error "Invalid command: %s" command)))

;;;###autoload
(defun loophole-bind-kmacro (key kmacro &optional keymap)
  "Bind KEY to KMACRO temporarily.
KMACRO must be a `kmacro' object.

This function finally calls `loophole-bind-entry', so that
the keymap used for binding and the meaning of optional
arguments KEYMAP are same as `loophole-bind-entry'.
See docstring of `loophole-bind-entry' for more details.

When called interactively, this function decides
obtaining method for KMACRO according to
`loophole-bind-kmacro-order', prefix argument and
`loophole-decide-obtaining-method-after-read-key'.
When this function is called without prefix argument,
the first element of `loophole-bind-kmacro-order' is
employed as obtaining method.
\\[universal-argument] and C-1 invokes the second element,
\\[universal-argument] \\[universal-argument] and C-2 invokes the third one.
Likewise \\[universal-argument] * n and C-[n] invoke the (n+1)th element.
If `negative-argument' is used, `completing-read' obtaining
method.  `loophole-decide-obtaining-method-after-read-key'
affects the timing of this `completing-read'."
  (interactive
   (loophole--arg-list loophole-bind-kmacro-order current-prefix-arg))
  (if (kmacro-p kmacro)
      (loophole-bind-entry key kmacro keymap)
    (user-error "Invalid kmacro: %s" kmacro)))

;;;###autoload
(defun loophole-bind-last-kmacro (key)
  "Bind KEY to the lastly accessed keyboard macro.
Currently editing keymap or generated new one is used for
binding."
  (interactive (list (loophole-read-key "Set key temporarily: ")))
  (loophole-bind-kmacro key (kmacro-lambda-form (kmacro-ring-head))))

;;;###autoload
(defun loophole-bind-array (key array &optional keymap)
  "Bind KEY to ARRAY temporarily.
ARRAY must be either a string or vector, which work as
a basic keyboard macro.

This function finally calls `loophole-bind-entry', so that
the keymap used for binding and the meaning of optional
arguments KEYMAP are same as `loophole-bind-entry'.
See docstring of `loophole-bind-entry'for more details.

When called interactively, this function decides
obtaining method for ARRAY according to
`loophole-bind-array-order', prefix argument and
`loophole-decide-obtaining-method-after-read-key'.
When this function called without prefix argument,
the first element of `loophole-bind-array-order' is
employed as obtaining method.
\\[universal-argument] and C-1 invokes the second element,
\\[universal-argument] \\[universal-argument] and C-2 invokes the third one.
Likewise \\[universal-argument] * n and C-[n] invoke the (n+1)th element.
If `negative-argument' is used, `completing-read' obtaining
method.  `loophole-decide-obtaining-method-after-read-key'
affects the timing of this `completing-read'."
  (interactive
   (loophole--arg-list loophole-bind-array-order current-prefix-arg))
  (if (or (vectorp array) (stringp array))
      (loophole-bind-entry key array keymap)
    (user-error "Invalid array : %s" array)))

;;;###autoload
(defun loophole-bind-keymap (key keymap &optional another-keymap)
  "Bind KEY to KEYMAP temporarily.
KEYMAP must be a keymap object, and KEY will be
a prefix key for KEYMAP.

This function finally calls `loophole-bind-entry', so that
the keymap in which KEY and KEYMAP are bound is samely
determined as `loophole-bind-entry'.
Optional argument ANOTHER-KEYMAP has same meaning with the
argument KEYMAP of `loophole-bind-entry'.
See docstring of `loophole-bind-entry' for more details.

When called interactively, this function decides
obtaining method for KEYMAP according to
`loophole-bind-keymap-order', prefix argument and
`loophole-decide-obtaining-method-after-read-key'.
When this function called without prefix argument,
the first element of `loophole-bind-keymap-order' is
employed as obtaining method.
\\[universal-argument] and C-1 invokes the second element,
\\[universal-argument] \\[universal-argument] and C-2 invokes the third one.
Likewise \\[universal-argument] * n and C-[n] invoke the (n+1)th element.
If `negative-argument' is used, `completing-read' obtaining
method.  `loophole-decide-obtaining-method-after-read-key'
affects the timing of this `completing-read'."
  (interactive
   (loophole--arg-list loophole-bind-keymap-order current-prefix-arg))
  (if (keymapp keymap)
      (loophole-bind-entry key keymap another-keymap)
    (user-error "Invalid keymap : %s" keymap)))

;;;###autoload
(defun loophole-bind-symbol (key symbol &optional keymap)
  "Bind KEY to SYMBOL temporarily.
SYMBOL must be a symbol whose function cell is a keymap,
a command , a keyboard macro or a symbol whose function
cell is ultimately either of above when scanned recursively.

This function finally calls `loophole-bind-entry', so that
the keymap used for binding and the meaning of optional
arguments KEYMAP are same as `loophole-bind-entry'.
See docstring of `loophole-bind-entry'for more details.

When called interactively, this function decides
obtaining method for SYMBOL according to
`loophole-bind-symbol-order', prefix argument and
`loophole-decide-obtaining-method-after-read-key'.
When this function called without prefix argument,
the first element of `loophole-bind-symbol-order' is
employed as obtaining method.
\\[universal-argument] and C-1 invokes the second element,
\\[universal-argument] \\[universal-argument] and C-2 invokes the third one.
Likewise \\[universal-argument] * n and C-[n] invoke the (n+1)th element.
If `negative-argument' is used, `completing-read' obtaining
method.  `loophole-decide-obtaining-method-after-read-key'
affects the timing of this `completing-read'."
  (interactive
   (loophole--arg-list loophole-bind-symbol-order current-prefix-arg))
  (letrec ((inspect-function-cell
            (lambda (symbol)
              (let ((function-cell (symbol-function symbol)))
                (or (keymapp function-cell)
                    (commandp function-cell)
                    (if (and function-cell (symbolp function-cell))
                        (funcall inspect-function-cell function-cell)))))))
    (if (and (symbolp symbol)
             (funcall inspect-function-cell symbol))
        (loophole-bind-entry key symbol keymap)
      (user-error "Invalid symbol : %s" symbol))))

;;;###autoload
(defun loophole-set-key (key entry)
  "Set the temporary binding for KEY and ENTRY.
This function finally calls `loophole-bind-entry', so that
the keymap used for binding is same as
`loophole-bind-entry', i.e. currently editing keymap or
generated new one is used.  ENTRY is also same as
`loophole-bind-entry'.  Any Lisp object is acceptable for
ENTRY, although only few types make sense.  Meaningful types
of ENTRY is completely same as general keymap entry.

When called interactively, this function decides
obtaining method for ENTRY according to
`loophole-set-key-order', prefix argument and
`loophole-decide-obtaining-method-after-read-key'.
When this function is called without prefix argument,
the first element of `loophole-set-key-order' is
employed as obtaining method.
\\[universal-argument] and C-1 invokes the second element,
\\[universal-argument] \\[universal-argument] and C-2 invokes the third one.
Likewise \\[universal-argument] * n and C-[n] invoke the (n+1)th element.
If `negative-argument' is used, `completing-read' obtaining
method.  `loophole-decide-obtaining-method-after-read-key'
affects the timing of this `completing-read'."
  (interactive (loophole--arg-list loophole-set-key-order current-prefix-arg t))
  (loophole-bind-entry key entry))

(defun loophole-unset-key (key)
  "Unset the temporary biding of KEY of `loophole--editing'."
  (interactive (if loophole--editing
                   (list (loophole-read-key "Unset temporarily set key: "))
                 (user-error "There is no editing map")))
  (if loophole--editing
      (let ((map (symbol-value loophole--editing)))
        (if (lookup-key map key)
            (loophole-bind-entry key nil map)))))

;;; Entry modifiers

(defun loophole-modify-lambda-form (key &optional map-variable)
  "Modify lambda form bound to KEY in MAP-VARIABLE.
If MAP-VARIABLE is nil, lookup all active loophole maps.

This function print bound lambda form to temporary buffer,
and read it back when modifying is finished.
In contrast with `loophole-obtain-command-by-lambda-form',
this function does not evaluate the form but just read it.
If temporary buffer contains multiple form when finished,
the first one will be read."
  (interactive (list (loophole-read-key "Modify lambda form for key: ")
                     (if current-prefix-arg
                         (loophole-read-map-variable "Lookup: "))))
  (if map-variable
      (unless (loophole-registered-p map-variable)
        (user-error "Specified map-variable %s is not registered" map-variable))
    (setq map-variable (loophole-map-variable-for-key-binding key))
    (unless map-variable
      (user-error "No entry found in loophole maps for key: %s"
                  (key-description key))))
  (let ((buffer (current-buffer))
        (window (selected-window))
        (frame (selected-frame))
        (configuration-list (mapcar #'current-window-configuration
                                    (frame-list)))
        (entry (lookup-key (symbol-value map-variable) key)))
    (cond ((null entry)
           (user-error "No entry found in loophole map: %s" map-variable))
          ((not (and (commandp entry)
                     (listp entry)
                     (eq (car entry) 'lambda)))
           (user-error "Bound entry is not lambda form: %s" entry)))
    (unwind-protect
        (let ((workspace (get-buffer-create "*Loophole*")))
          (switch-to-buffer-other-window workspace t)
          (erase-buffer)
          (insert ";; For modifying lambda form.\n\n")
          (pp entry workspace)
          (loophole-write-lisp-mode)
          (with-current-buffer workspace (goto-char 1))
          (let ((lambda-form (read workspace)))
            (if (and (commandp lambda-form)
                     (listp lambda-form)
                     (eq (car lambda-form) 'lambda))
                (loophole-bind-entry key lambda-form
                                     (symbol-value map-variable))
              (user-error
               "Modified Lisp object is not valid lambda command: %s"
               lambda-form))))
      (let ((configuration
             (seq-find (lambda (c)
                         (eq (selected-frame) (window-configuration-frame c)))
                       configuration-list)))
        (if configuration
            (set-window-configuration configuration)
          (delete-frame)))
      (if (frame-live-p frame) (select-frame-set-input-focus frame t))
      (if (window-live-p window) (select-window window t))
      (if (buffer-live-p buffer) (switch-to-buffer buffer t t)))))

(defun loophole-modify-kmacro (key &optional map-variable)
  "Modify kmacro bound to KEY in MAP-VARIABLE.
If MAP-VARIABLE is nil, lookup all active loophole maps.

This function print bound kmacro to temporary buffer, and
read it back when modifying is finished.
Because kmacro object is actually a lambda form wrapping
basic keyboard macro, a string or a vector,
lambda form will be printed in temporary buffer.

If temporary buffer contains multiple form when finished,
the first one will be read."
  (interactive (list (loophole-read-key "Modify kmacro for key: ")
                     (if current-prefix-arg
                         (loophole-read-map-variable "Lookup: "))))
  (if map-variable
      (unless (loophole-registered-p map-variable)
        (user-error "Specified map-variable %s is not registered" map-variable))
    (setq map-variable (loophole-map-variable-for-key-binding key))
    (unless map-variable
      (user-error "No entry found in loophole maps for key: %s"
                  (key-description key))))
  (let ((buffer (current-buffer))
        (window (selected-window))
        (frame (selected-frame))
        (configuration-list (mapcar #'current-window-configuration
                                    (frame-list)))
        (entry (lookup-key (symbol-value map-variable) key)))
    (cond ((null entry)
           (user-error "No entry found in loophole map: %s" map-variable))
          ((not (kmacro-p entry))
           (user-error "Bound entry is not kmacro: %s" entry)))
    (unwind-protect
        (let ((workspace (get-buffer-create "*Loophole*")))
          (switch-to-buffer-other-window workspace t)
          (erase-buffer)
          (insert ";; For modifying kmacro.\n\n")
          (pp entry workspace)
          (loophole-write-lisp-mode)
          (with-current-buffer workspace (goto-char 1))
          (let ((kmacro (read workspace)))
            (if (kmacro-p kmacro)
                (loophole-bind-entry key kmacro (symbol-value map-variable))
              (user-error
               "Modified Lisp object is not kmacro: %s" kmacro))))
      (let ((configuration
             (seq-find (lambda (c)
                         (eq (selected-frame) (window-configuration-frame c)))
                       configuration-list)))
        (if configuration
            (set-window-configuration configuration)
          (delete-frame)))
      (if (frame-live-p frame) (select-frame-set-input-focus frame t))
      (if (window-live-p window) (select-window window t))
      (if (buffer-live-p buffer) (switch-to-buffer buffer t t)))))

(defun loophole-modify-array (key &optional map-variable)
  "Modify array bound to KEY in MAP-VARIABLE.
If MAP-VARIABLE is nil, lookup all active loophole maps.

This function print bound array to temporary buffer, and
read it back when modifying is finished.
This function does not evaluate the form but just read it.
If temporary buffer contains multiple form when finished,
the first one will be read."
  (interactive (list (loophole-read-key "Modify array for key: ")
                     (if current-prefix-arg
                         (loophole-read-map-variable "Lookup: "))))
  (if map-variable
      (unless (loophole-registered-p map-variable)
        (user-error "Specified map-variable %s is not registered" map-variable))
    (setq map-variable (loophole-map-variable-for-key-binding key))
    (unless map-variable
      (user-error "No entry found in loophole maps for key: %s"
                  (key-description key))))
  (let ((buffer (current-buffer))
        (window (selected-window))
        (frame (selected-frame))
        (configuration-list (mapcar #'current-window-configuration
                                    (frame-list)))
        (entry (lookup-key (symbol-value map-variable) key)))
    (cond ((null entry)
           (user-error "No entry found in loophole map: %s" map-variable))
          ((not (or (vectorp entry) (stringp entry)))
           (user-error "Bound entry is not array: %s" entry)))
    (unwind-protect
        (let ((workspace (get-buffer-create "*Loophole*")))
          (switch-to-buffer-other-window workspace t)
          (erase-buffer)
          (insert ";; For modifying array.\n\n")
          (pp entry workspace)
          (loophole-write-lisp-mode)
          (with-current-buffer workspace (goto-char 1))
          (let ((array (read workspace)))
            (if (or (vectorp array) (stringp array))
                (loophole-bind-entry key array (symbol-value map-variable))
              (user-error
               "Modified Lisp object is not array: %s" array))))
      (let ((configuration
             (seq-find (lambda (c)
                         (eq (selected-frame) (window-configuration-frame c)))
                       configuration-list)))
        (if configuration
            (set-window-configuration configuration)
          (delete-frame)))
      (if (frame-live-p frame) (select-frame-set-input-focus frame t))
      (if (window-live-p window) (select-window window t))
      (if (buffer-live-p buffer) (switch-to-buffer buffer t t)))))

;;; Base control

;;;###autoload
(defun loophole-suspend ()
  "Suspend Loophole.
To suspend Loophole, this function delete
`loophole--map-alist' from `emulation-mode-map-alists'."
  (interactive)
  (setq emulation-mode-map-alists
        (delq 'loophole--map-alist emulation-mode-map-alists))
  (setq loophole--suspended t))

(defun loophole-resume ()
  "Resume Loophole.
To resume Loophole, this functions add
`loophole--map-alist' to `emulation-mode-map-alists'
unless `loophole--map-alist' is a member of
`emulation-mode-map-alists'."
  (interactive)
  (add-to-list 'emulation-mode-map-alists 'loophole--map-alist nil #'eq)
  (setq loophole--suspended nil))

(defun loophole-quit ()
  "Quit Loophole completely.
Disable the all keymaps, stop editing, and turn off
Loophole mode."
  (interactive)
  (mapc (lambda (buffer)
          (with-current-buffer buffer
            (loophole-disable-all)
            (loophole-stop-editing)))
        (if (listp loophole--buffer-list)
            loophole--buffer-list
          (buffer-list)))
  (loophole-mode 0)
  (force-mode-line-update t))

;;;###autoload
(define-minor-mode loophole-mode
  "Toggle Loophole mode.

Loophole mode offers temporary key bindings management
utilities; key bindings for Loophole commands, mode-line
lighter, and performance support, though Loophole commands
work correctly without Loophole mode.

When Loophole mode is enabled, Loophole is basically
resumed.  Then, active Loophole maps take effect; in other
words, you can use key bindings bound in keymaps which are
registered to Loophole and whose state is non-nil.

For the details of mode-line lighter, see documentation
string of `loophole-mode-lighter'.

Followings are the key bindings for Loophole commands.

\\{loophole-mode-map}"
  :group 'loophole
  :global t
  :lighter loophole-mode-lighter
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c [") #'loophole-set-key)
            (define-key map (kbd "C-c \\") #'loophole-disable-latest)
            (define-key map (kbd "C-c ] {") #'loophole-register)
            (define-key map (kbd "C-c ] }") #'loophole-unregister)
            (define-key map (kbd "C-c ] ^") #'loophole-prioritize)
            (define-key map (kbd "C-c ] >") #'loophole-globalize)
            (define-key map (kbd "C-c ] <") #'loophole-localize)
            (define-key map (kbd "C-c ] [") #'loophole-start-editing)
            (define-key map (kbd "C-c ] ]") #'loophole-stop-editing)
            (define-key map (kbd "C-c ] ;") #'loophole-name)
            (define-key map (kbd "C-c ] #") #'loophole-tag)
            (define-key map (kbd "C-c ] /") #'loophole-describe)
            (define-key map (kbd "C-c ] ,") #'loophole-suspend)
            (define-key map (kbd "C-c ] .") #'loophole-resume)
            (define-key map (kbd "C-c ] q") #'loophole-quit)
            (define-key map (kbd "C-c ] p") #'loophole-prioritize)
            (define-key map (kbd "C-c ] n") #'loophole-name)
            (define-key map (kbd "C-c ] h") #'loophole-describe)
            (define-key map (kbd "C-c ] s") #'loophole-set-key)
            (define-key map (kbd "C-c ] u") #'loophole-unset-key)
            (define-key map (kbd "C-c ] e") #'loophole-enable)
            (define-key map (kbd "C-c ] d") #'loophole-disable)
            (define-key map (kbd "C-c ] D") #'loophole-disable-all)
            (define-key map (kbd "C-c ] t [") #'loophole-start-timer)
            (define-key map (kbd "C-c ] t ]") #'loophole-stop-timer)
            (define-key map (kbd "C-c ] t +") #'loophole-extend-timer)
            (define-key map (kbd "C-c ] t e [") #'loophole-start-editing-timer)
            (define-key map (kbd "C-c ] t e ]") #'loophole-stop-editing-timer)
            (define-key map (kbd "C-c ] t e +") #'loophole-extend-editing-timer)
            (define-key map (kbd "C-c ] \\") #'loophole-disable-latest)
            (define-key map (kbd "C-c ] (") #'loophole-start-kmacro)
            (define-key map (kbd "C-c ] )") #'loophole-end-kmacro)
            (define-key map (kbd "C-c ] k s") #'loophole-start-kmacro)
            (define-key map (kbd "C-c ] k e") #'loophole-end-kmacro)
            (define-key map (kbd "C-c ] k a") #'loophole-abort-kmacro)
            (define-key map (kbd "C-c ] k b") #'loophole-bind-last-kmacro)
            (define-key map (kbd "C-c ] b e") #'loophole-bind-entry)
            (define-key map (kbd "C-c ] b c") #'loophole-bind-command)
            (define-key map (kbd "C-c ] b k") #'loophole-bind-kmacro)
            (define-key map (kbd "C-c ] b K") #'loophole-bind-last-kmacro)
            (define-key map (kbd "C-c ] b a") #'loophole-bind-array)
            (define-key map (kbd "C-c ] b m") #'loophole-bind-keymap)
            (define-key map (kbd "C-c ] b s") #'loophole-bind-symbol)
            (define-key map (kbd "C-c ] m l") #'loophole-modify-lambda-form)
            (define-key map (kbd "C-c ] m k") #'loophole-modify-kmacro)
            (define-key map (kbd "C-c ] m a") #'loophole-modify-array)
            map)
  (if loophole-mode
      (progn
        (setq loophole--buffer-list nil)
        (mapc (lambda (buffer)
                (with-current-buffer buffer
                  (if (seq-some #'local-variable-p
                                (loophole-local-variable-if-set-list))
                      (push buffer loophole--buffer-list))))
              (buffer-list))
        (dolist (variable (loophole-local-variable-if-set-list))
          (add-variable-watcher variable
                                #'loophole--follow-adding-local-variable))
        (mapc (lambda (buffer)
                (with-current-buffer buffer
                  (add-hook 'change-major-mode-hook
                            #'loophole--follow-killing-local-variable nil t)
                  (add-hook 'kill-buffer-hook
                            #'loophole--follow-killing-local-variable nil t)))
              loophole--buffer-list)
        (unless loophole--suspended (loophole-resume)))
    (let ((flag loophole--suspended))
      (loophole-suspend)
      (setq loophole--suspended flag))
    (mapc (lambda (buffer)
            (with-current-buffer buffer
              (remove-hook 'kill-buffer-hook
                           #'loophole--follow-killing-local-variable t)
              (remove-hook 'change-major-mode-hook
                           #'loophole--follow-killing-local-variable t)))
          loophole--buffer-list)
    (dolist (variable (loophole-local-variable-if-set-list))
      (remove-variable-watcher variable
                               #'loophole--follow-adding-local-variable))
    (setq loophole--buffer-list t)))

;;; Customization helpers

(defun loophole-turn-on-auto-prioritize ()
  "Turn on auto prioritize as user customization.
Add hooks to call `loophole-prioritize' for
`loophole-globalize', `loophole-localize'
`loophole-enable', `loophole-name' and
`loophole-start-editing'.

All of hooks are optional.
Instead of using this function, user can pick some hooks
from function definition for optimized customization."
  (add-hook 'loophole-globalize-functions #'loophole-prioritize)
  (add-hook 'loophole-localize-functions #'loophole-prioritize)
  (add-hook 'loophole-enable-functions #'loophole-prioritize)
  (add-hook 'loophole-name-functions #'loophole-prioritize)
  (add-hook 'loophole-start-editing-functions #'loophole-prioritize))

(defun loophole-turn-off-auto-prioritize ()
  "Turn off auto prioritize as user customization.
Remove hooks added by `loophole-turn-on-auto-prioritize'."
  (remove-hook 'loophole-globalize-functions #'loophole-prioritize)
  (remove-hook 'loophole-localize-functions #'loophole-prioritize)
  (remove-hook 'loophole-enable-functions #'loophole-prioritize)
  (remove-hook 'loophole-name-functions #'loophole-prioritize)
  (remove-hook 'loophole-start-editing-functions #'loophole-prioritize))

(defun loophole-turn-on-auto-stop-editing ()
  "Turn on auto stop-editing as user customization.
Add hooks to call `loophole-stop-editing' for
`loophole-prioritize', `loophole-globalize',
`loophole-localize', `loophole-enable',`loophole-disable'
and `loophole-name'.
 `loophole-disable-latest' and `loophole-disable-all' are
also affected by the hook for `loophole-disable'.

All of hooks are optional.
Instead of using this function, user can pick some hooks
from function definition for optimized customization."
  (add-hook 'loophole-prioritize-functions
            (lambda (map-variable)
              (unless (eq map-variable loophole--editing)
                (loophole-stop-editing))))
  (add-hook 'loophole-globalize-functions
            (lambda (map-variable)
              (unless (eq map-variable loophole--editing)
                (loophole-stop-editing))))
  (add-hook 'loophole-localize-functions
            (lambda (map-variable)
              (unless (eq map-variable loophole--editing)
                (loophole-stop-editing))))
  (add-hook 'loophole-enable-functions
            (lambda (map-variable)
              (unless (eq map-variable loophole--editing)
                (loophole-stop-editing))))
  (add-hook 'loophole-disable-functions
            (lambda (map-variable)
              (if (eq map-variable loophole--editing)
                  (loophole-stop-editing))))
  (add-hook 'loophole-name-functions
            (lambda (map-variable)
              (unless (eq map-variable loophole--editing)
                (loophole-stop-editing)))))

(defun loophole-turn-off-auto-stop-editing ()
  "Turn off auto stop-editing as user customization.
Remove hooks added by `loophole-turn-on-auto-stop-editing'."
  (remove-hook 'loophole-prioritize-functions
               (lambda (map-variable)
                 (unless (eq map-variable loophole--editing)
                   (loophole-stop-editing))))
  (remove-hook 'loophole-globalize-functions
               (lambda (map-variable)
                 (unless (eq map-variable loophole--editing)
                   (loophole-stop-editing))))
  (remove-hook 'loophole-localize-functions
               (lambda (map-variable)
                 (unless (eq map-variable loophole--editing)
                   (loophole-stop-editing))))
  (remove-hook 'loophole-enable-functions
               (lambda (map-variable)
                 (unless (eq map-variable loophole--editing)
                   (loophole-stop-editing))))
  (remove-hook 'loophole-disable-functions
               (lambda (map-variable)
                 (if (eq map-variable loophole--editing)
                     (loophole-stop-editing))))
  (remove-hook 'loophole-name-functions
               (lambda (map-variable)
                 (unless (eq map-variable loophole--editing)
                   (loophole-stop-editing)))))

(defun loophole-turn-on-auto-resume ()
  "Turn on auto resume as user customization.
Add hooks to call `loophole-resume' for
`loophole-register', `loophole-prioritize',
 `loophole-globalize', `loophole-localize',
`loophole-enable', `loophole-name', `loophole-start-editing'
and `loophole-bind-entry'.
Binding commands including `loophole-set-key' and
`loophole-unset-key' are also affected by the hook of
`loophole-bind-entry'.

All of hooks are optional.
Instead of using this function, user can pick some hooks
from function definition for optimized customization."
  (add-hook 'loophole-register-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-prioritize-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-globalize-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-localize-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-enable-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-name-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-start-editing-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-bind-hook #'loophole-resume))

(defun loophole-turn-off-auto-resume ()
  "Turn off auto resume as user customization.
Remove hooks added by `loophole-turn-on-auto-resume'."
  (remove-hook 'loophole-register-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-prioritize-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-globalize-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-localize-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-enable-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-name-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-start-editing-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-bind-hook #'loophole-resume))

(defun loophole-turn-on-auto-timer ()
  "Turn on auto timer as user customization.
Add hooks to call `loophole-start-timer' and
`loophole-stop-timer' for `loophole-prioritize',
`loophole-globalize', `loophole-localize',
`loophole-enable', `loophole-disable', `loophole-name' and
`loophole-start-editing'.

All of hooks are optional.
Instead of using this function, user can pick some hooks
from function definition for optimized customization."
  (add-hook 'loophole-prioritize-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable))))
  (add-hook 'loophole-globalize-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable))))
  (add-hook 'loophole-localize-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable))))
  (add-hook 'loophole-enable-functions #'loophole-start-timer)
  (add-hook 'loophole-disable-functions #'loophole-stop-timer)
  (add-hook 'loophole-name-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable))))
  (add-hook 'loophole-start-editing-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable)))))

(defun loophole-turn-off-auto-timer ()
  "Turn off auto timer as user customization.
Remove hooks added by `loophole-turn-on-auto-timer'."
  (remove-hook 'loophole-prioritize-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable))))
  (remove-hook 'loophole-globalize-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable))))
  (remove-hook 'loophole-localize-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable))))
  (remove-hook 'loophole-enable-functions #'loophole-start-timer)
  (remove-hook 'loophole-disable-functions #'loophole-stop-timer)
  (remove-hook 'loophole-name-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable))))
  (remove-hook 'loophole-start-editing-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable)))))

(defun loophole-turn-on-auto-editing-timer ()
  "Turn on auto timer as user customization.
Add hooks to call `loophole-start-editing-timer' and
`loophole-stop-editing-timer' for `loophole-prioritize',
`loophole-globalize', `loophole-localize',
`loophole-enable', `loophole-name', `loophole-start-editing'
and `loophole-stop-editing'.

All of hooks are optional.
Instead of using this function, user can pick some hooks
from function definition for optimized customization."
  (add-hook 'loophole-prioritize-functions
            (lambda (map-variable)
              (if (eq map-variable loophole--editing)
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-globalize-functions
            (lambda (map-variable)
              (if (eq map-variable loophole--editing)
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-localize-functions
            (lambda (map-variable)
              (if (eq map-variable loophole--editing)
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-enable-functions
            (lambda (map-variable)
              (if (eq map-variable loophole--editing)
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-name-functions
            (lambda (map-variable)
              (if (eq map-variable loophole--editing)
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-start-editing-functions
            (lambda (_) (loophole-start-editing-timer)))
  (add-hook 'loophole-stop-editing-functions
            (lambda (_) (loophole-stop-editing-timer))))

(defun loophole-turn-off-auto-editing-timer ()
  "Turn off auto editing timer as user customization.
Remove hooks added by `loophole-turn-on-auto-editing-timer'."
  (remove-hook 'loophole-prioritize-functions
               (lambda (map-variable)
                 (if (eq map-variable loophole--editing)
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-globalize-functions
               (lambda (map-variable)
                 (if (eq map-variable loophole--editing)
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-localize-functions
               (lambda (map-variable)
                 (if (eq map-variable loophole--editing)
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-enable-functions
               (lambda (map-variable)
                 (if (eq map-variable loophole--editing)
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-name-functions
               (lambda (map-variable)
                 (if (eq map-variable loophole--editing)
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-start-editing-functions
               (lambda (_) (loophole-start-editing-timer)))
  (remove-hook 'loophole-stop-editing-functions
               (lambda (_) (loophole-stop-editing-timer))))

(defcustom loophole-use-auto-prioritize t
  "Flag if prioritize Loophole map automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-prioritize' or
`loophole-turn-off-auto-prioritize' manually.
They setup some hooks.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-prioritize'."
  :group 'loophole
  :type 'boolean
  :set (lambda (symbol value)
         (set-default symbol value)
         (if value
             (loophole-turn-on-auto-prioritize)
           (loophole-turn-off-auto-prioritize))))

(defcustom loophole-use-auto-stop-editing t
  "Flag if stop editing keymap automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-stop-editing' or
`loophole-turn-off-auto-stop-editing' manually.
They setup some hooks.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-stop-editing'."
  :group 'loophole
  :type 'boolean
  :set (lambda (symbol value)
         (set-default symbol value)
         (if value
             (loophole-turn-on-auto-stop-editing)
           (loophole-turn-off-auto-stop-editing))))

(defcustom loophole-use-auto-resume t
  "Flag if resume Loophole automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-resume' or
`loophole-turn-off-auto-resume' manually.
They setup some hooks.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-resume'."
  :group 'loophole
  :type 'boolean
  :set (lambda (symbol value)
         (set-default symbol value)
         (if value
             (loophole-turn-on-auto-resume)
           (loophole-turn-off-auto-resume))))

(defcustom loophole-use-auto-timer nil
  "Flag if start timer for disabling Loophole map automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-timer' or
`loophole-turn-off-auto-timer' manually.
They setup some hooks and advice.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-timer'."
  :group 'loophole
  :type 'boolean
  :set (lambda (symbol value)
         (set-default symbol value)
         (if value
             (loophole-turn-on-auto-timer)
           (loophole-turn-off-auto-timer))))

(defcustom loophole-use-auto-editing-timer nil
  "Flag if start timer for stopping editing session automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-editing-timer' or
`loophole-turn-off-auto-editing-timer' manually.
They setup some hooks.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-editing-timer'."
  :group 'loophole
  :type 'boolean
  :set (lambda (symbol value)
         (set-default symbol value)
         (if value
             (loophole-turn-on-auto-editing-timer)
           (loophole-turn-off-auto-editing-timer))))

;;; A macro for defining keymap

;;;###autoload
(defmacro loophole-define-map (map &optional spec docstring
                                   state state-init-value state-docstring
                                   tag global without-base-map)
  "Macro for defining loophole map.
Define map variable and state variable, and register them.

Define map variable by MAP, SPEC and DOCSTRING.
If SPEC is evaluated as keymap, use it as init value of
MAP.  If SPEC is evaluated as list, this macro expect it as
an alist of which element looks like (KEY . ENTRY).
If SPEC is evaluated as nil, make sparse keymap.
Otherwise, emit error signal.
DOCSTRING is passed to `defvar'.

Define state variable by STATE, STATE-INIT-VALUE and
STATE-DOCSTRING.
If STATE is literal nil or omitted, define variable named as
MAP-state.
STATE-INIT-VALUE is used as it is.
If STATE-DOCSTRING is nil, use fixed phrase.
If GLOBAL is literal nil or omitted,
`make-variable-buffer-local' for state-variable is added to
expanded forms.

TAG, GLOBAL and WITHOUT-BASE-MAP are passed to
`loophole-register'."
  (declare (doc-string 3) (indent 1))
  (unless state
    (setq state (intern (concat (symbol-name map) "-state"))))
  `(progn
     (defvar ,map (let ((s ,spec))
                    (cond ((keymapp s) s)
                          ((listp s)
                           (let ((m (make-sparse-keymap)))
                             (mapc (lambda (key-binding)
                                     (define-key m
                                       (car key-binding)
                                       (cdr key-binding)))
                                   s)
                             m))
                          ((null s) (make-sparse-keymap))
                          (t (error "Invalid keymap %" s))))
       ,docstring)
     (defvar ,state ,state-init-value
       (if ,state-docstring
           ,state-docstring
         (format "State of Loophole map `%s'." ',map)))
     ,(unless global
        `(make-variable-buffer-local ',state))
     (loophole-register ',map ',state ,tag ,global ,without-base-map)))

(dolist (mode '(emacs-lisp-mode lisp-interaction-mode))
  (font-lock-add-keywords
   mode
   '(("(\\(loophole-define-map\\)\\_>[ 	]*\\(\\(?:\\sw\\|\\s_\\|\\\\.\\)+\\)?"
      (1 font-lock-keyword-face)
      (2 font-lock-variable-name-face nil t)))))

;;; Aliases for main interfaces

(defalias 'loophole-open #'loophole-set-key)
(defalias 'loophole-close #'loophole-unset-key)
(defalias 'loophole-cover #'loophole-disable)
(defalias 'loophole-cover-latest #'loophole-disable-latest)
(defalias 'loophole-cover-all #'loophole-disable-all)
(defalias 'loophole-reveal #'loophole-enable)
(defalias 'loophole-edit #'loophole-start-editing)
(defalias 'loophole-break #'loophole-stop-editing)

(provide 'loophole)

;;; loophole.el ends here
