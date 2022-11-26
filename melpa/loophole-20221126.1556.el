;;; loophole.el --- Manage temporary key bindings -*- lexical-binding: t -*-

;; Copyright (C) 2020-2022 0x60DF

;; Author: 0x60DF <0x60df@gmail.com>
;; Created: 30 Aug 2020
;; Version: 0.8.3
;; Package-Version: 20221126.1556
;; Package-Commit: dadc3fadc68b13501c4dbe89109f30deb0d3441a
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

(when (version< emacs-version "28")
  (declare-function describe-keymap nil)
  (declare-function seq-uniq "seq"))

(defvar kmacro-ring)
(declare-function kmacro-loop-setup-function "kmacro")
(declare-function kmacro-extract-lambda "kmacro")
(declare-function kmacro-ring-head "kmacro")
(declare-function kmacro-p "kmacro")

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
must be unique for each element of this variable.

Set of map-variable, state-variable, and keymap object is a
unit of temporary key bindings, called Loophole map.
Variables and keymap can be referred each other via this
variable, and `symbol-plist'.
Map-variable has a property :loophole-state-variable,
and state-variable has a property :loophole-map-variable.
The values of those properties are as name suggests.
This is to say,
map-variable ---(symbol-plist)----> state-variable
map-variable ---(symbol-value)----> keymap object
state-variable -(symbol-plist)----> map-variable
state-variable -(assq map-alist)--> keymap object
keymap object --(rassq map-alist)-> state-variable

Map-variable has other properties as well as
:loophole-state-variable.  These keep the properties of the
Loophole map.  All properties other than
:loophole-state-variable are listed below.
:loophole-tag : Tag string of the Loophole map.
:loophole-protected-keymap : Keymap object which holds key
  bindings for keymap entry.  The same object as the value
  of this property is added to `keymap-parent', and thus
  keymap entries in this property take effect while they are
  not overwritten by binding command.  Value of this
  property looks like
  (keymap (keymap ... (key1 keymap ... body of entry1))
          (keymap ... (key1 . undefined))
          (keymap ... (key2 keymap ... body of entry2))
          (keymap ... (key2 . undefined))
          ...),
  here, keymap object containing `undefined' is a wall for
  the concerning key.  Owing to this wall, the key is shaded
  and key bindings defined in the following entries whose
  prefix key is the concerning key are not merged.
:loophole-form-storage : Alist of a key and forms which
  derives a entry of key binding.  This property is used for
  key bindings whose entry should be a same object as
  something other feature refers.  Loophole functions use
  this property to properly restore such key bindings.
  For example, `loohpole-load' refers this property and
  performes binding for keymap object which is bound to
  something variable.  As a result, both this key binding
  and the variable shares the same keymap object.
  Modification on that keymap via that variable is reflected
  to the key binding of Loophole map.

As mentioned above, Loophole uses `keymap-parent' of keymap
object of Loophole map.  `loophole-base-map',
:loophole-protected-keymap, or composed keymap of them may
be set as parent.
Note that, when registering keymap whose `keymap-parent' is
not nil, Loophole handles it and compose it with
`loophole-base-map'.  However, after registeration,
manipulating `keymap-parent' may corrupt Loophole map.
See the documentation string of `loophole-register' for
detailes.

This variable is a pivot of Loophole.
Temporary key bindings take effect as this variable is
added to `emulation-mode-map-alists'.
The value of this variable is a major part of whole state of
Loophole.")

(defvar loophole--buffer-list t
  "List of buffers on which Loophole variables have local value.
Loophole mode maintains this variable as up to date.
When Loophole mode is disabled, this variable is set as t
in order to tell that this variable is not maintained.

This list may contain buffers which are dead or no longer
having no local variables, because Loophole mode cannot
recognize some special cases on which buffer or local
variables are killed silently.
Instead of refering this variable directly, use the function
`loophole-buffer-list' to safely get buffers which are live
and having local variables.")

(defvar-local loophole--editing t
  "Variable of keymap which is currently being edited.
Loophole binds keys in this keymap.  When this value is nil,
Loophole may generate new keymap and bind keys in it.

If default value of this variable is t, editing session is
local, and buffer local values are used; otherwise, editing
session is global, and default value is used.

Use function `loophole-editing' to get the value of this
variable.
You should not set this variable directly, instead use
`loophole-start-editing'.")

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
  "Timer for stopping editing loophole map.
By default, local timers are used.
If editing session is globalized, default value is used.")

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
  :type 'integer)

(defcustom loophole-allow-keyboard-quit t
  "If non-nil, binding commands can be quit even while reading keys.
If binidng commands use reading key function other than
`loophole-read-key' and its variant, this variable takes no
effect."
  :type 'boolean)

(defcustom loophole-decide-obtaining-method-after-read-key 'negative-argument
  "Flag if obtaining method is decided after read key.

If this value is non-nil, binding commands decide obtaining
method after reading key.

If the value is 'negative-argument, a apecial case of
non-nil, binding commands decide obtaining method after
reading key only when they are called with
`negative-argument'.

If the value is nil, binding commands decide obtaining
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
  :type '(choice
          (const :tag "No" nil)
          (const :tag "Yes, only with negative-argument" negative-argument)
          (other :tag "Yes" t)))

(defcustom loophole-protect-keymap-entry t
  "If non-nil, when keymap object is bound, it will be protected.
Protected entry is referable, but not writable.
This prevents accidental modification on existing keymap.

Technically, these entries are bound in the parent keymap.
When some other new bindings shade protected entry, they
are removed from parent keymap.  Furthermore, when existing
ordinary binding shades protected entry on binidng it,
shader will be removed.  Thus, user can use protected
entries as well as ordinary entries except for that they are
write protected."
  :type 'boolean)

(defcustom loophole-read-key-limit-time 1.0
  "Limit time in seconds for `loophole-read-key-with-time-limit'."
  :type 'number)

(define-obsolete-variable-alias 'loophole-kmacro-by-read-key-finish-key
  'loophole-read-key-termination-key "0.8.2")
(define-obsolete-variable-alias 'loophole-array-by-read-key-finish-key
  'loophole-read-key-termination-key "0.8.2")
(defcustom loophole-read-key-termination-key (where-is-internal
                                              'keyboard-quit nil t)
  "Key sequence to finish `loophole-read-key-until-termination-key'."
  :type 'key-sequence)

(defcustom loophole-read-buffer-inhibit-recursive-edit nil
  "Flag if `recursive-edit' is inhibited on `loophole-read-buffer'.
Instead of it, `loophole-read-buffer' set up some utilities
and `signal' quit.  One of the utilities is a binidng
`loophole-read-buffer-finish-key' with a command which calls
CALLBACK with one argument a read form.
By these utilities, user can work with the buffer as well as
using `recursive-edit' while released from `recursive-edit'."
  :type 'boolean)

(defcustom loophole-read-buffer-finish-key [?\C-c ?\C-c]
  "Key for finishing `loophole-read-buffer'."
  :type 'key-sequence)

(defcustom loophole-read-buffer-abort-key [?\C-c ?\C-k]
  "Key for aborting `loophole-read-buffer'."
  :type 'key-sequence)

(defcustom loophole-force-overwrite-bound-variable t
  "Flag if use bound variable and overwrite it without prompting."
  :type 'boolean)

(defcustom loophole-force-make-variable-buffer-local t
  "Flag if `make-variable-buffer-local' is done without prompting."
  :type 'boolean)

(defcustom loophole-force-unintern nil
  "Flag if `unintern' is done without prompting."
  :type 'boolean)

(defcustom loophole-make-register-always-read-tag 'infer
  "Flag if interactive `loophole-register' always reads tag string.
If non-nil, `loophole-register' always reads tag string,
but if symbol infer is set, `loophole-register' try to infer
tag string before asking."
  :type '(choice
          (const :tag "No" nil)
          (const :tag "Yes, but try to infer first" multiline)
          (other :tag "Yes" t)))

(defcustom loophole-make-describe-use-builtin nil
  "Flag if `loophole-describe' uses builtin `describe-keymap'.
This option takes effect with Emacs 28 or later."
  :type 'boolean)

(defcustom loophole-timer-default-time (* 60 60)
  "Default time in seconds for auto disabling timer."
  :type 'number)

(defcustom loophole-editing-timer-default-time (* 60 5)
  "Default time in seconds for auto stopping editing timer."
  :type 'number)

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
  :type 'string)

(define-obsolete-variable-alias 'loophole-kmacro-by-recursive-edit-map
  'loophole-defining-kmacro-map "0.8.2")
(defvar loophole-defining-kmacro-map
  (let ((map (make-sparse-keymap)))
    (define-key map "\C-c[" #'loophole-end-kmacro)
    (define-key map "\C-c\\" #'loophole-abort-kmacro)
    map)
  "Keymap for defining kmacro with Loophole utilities.
This map is enabled temporarily during
`loophole-obtain-kmacro-by-recursive-edit', and
`loophole-obtain-kmacro-on-top-level' to offer some bindings
which is helpful for defining kmacro.
Activity of this map is controled by
`loophole-defining-kmacro-map-flag'.")

(define-obsolete-variable-alias 'loophole-kmacro-by-recursive-edit-map-flag
  'loophole-defining-kmacro-map-flag "0.8.2")
(defcustom loophole-defining-kmacro-map-flag t
  "Non-nil means `loophole-defining-kmacro-map' is enabled."
  :type 'boolean)

(define-obsolete-variable-alias 'loophole-kmacro-by-recursive-edit-map-tag
  'loophole-defining-kmacro-map-tag "0.8.2")
(defcustom loophole-defining-kmacro-map-tag
  "kmacro[End: \\[loophole-end-kmacro], Abort: \\[loophole-abort-kmacro]]"
  "Tag string for `loophole-defining-kmacro-map'."
  :type 'string)

(defcustom loophole-alternative-read-key-function
  #'loophole-read-key-with-time-limit
  "Alternative read key function for `loophole-read-key'.
The value of this user options should be a function which
takes one argument a standard prompt string and returns read
key sequence.

`loophole-unset-key' and `loophole-reset-key' called with
prefix argument use this function to read key.

For binding commands, and `loophole-set-key', this option
does not take effect, becase they refer loophole-*-order
which can specify more conplex rules to read key."
  :type 'function)

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
READ-KEY is a function which takes one argument a standard
prompt string and returns key sequence to be bound.
OBTAIN-KEYMAP is a function which takes one argument the
key to be bound, and returns keymap object on which key and
entry are bound; this overrides `loophole-editing'.

If `loophole-decide-obtaining-method-after-read-key' is
non-nil other than 'negative-argument, or while it is
'negative-argument and `loophole-bind-entry' is called with
`negative-argument', :key property will be omitted and
default `loophole-read-key' will be used for reading key."
  :risky t
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
\(OBTAIN-ENTRY :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes one argument a standard
prompt string and returns key sequence to be bound.
OBTAIN-KEYMAP is a function which takes one argument the
key to be bound, and returns keymap object on which key and
entry are bound; this overrides `loophole-editing'.

If `loophole-decide-obtaining-method-after-read-key' is
non-nil, or while it is 'negative-argument and
`loophole-bind-command' is called with `negative-argument',
:key property will be omitted and default
`loophole-read-key' will be used for reading key."
  :risky t
  :type '(repeat sexp))

(defcustom loophole-bind-kmacro-order
  '(loophole-obtain-kmacro-by-recursive-edit
    loophole-obtain-kmacro-by-read-key
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
\(OBTAIN-ENTRY :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes one argument a standard
prompt string and returns key sequence to be bound.
OBTAIN-KEYMAP is a function which takes one argument the
key to be bound, and returns keymap object on which key and
entry are bound; this overrides `loophole-editing'.

If `loophole-decide-obtaining-method-after-read-key' is
non-nil other than 'negative-argument, or while it is
'negative-argument and `loophole-bind-kmacro' is called with
`negative-argument', :key property will be omitted and
default `loophole-read-key' will be used for reading key."
  :risky t
  :type '(repeat sexp))

(defcustom loophole-bind-array-order
  '(loophole-obtain-array-by-read-key
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
\(OBTAIN-ENTRY :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes one argument a standard
prompt string and returns key sequence to be bound.
OBTAIN-KEYMAP is a function which takes one argument the
key to be bound, and returns keymap object on which key and
entry are bound; this overrides `loophole-editing'.

If `loophole-decide-obtaining-method-after-read-key' is
non-nil other than 'negative-argument, or while it is
'negative-argument and `loophole-bind-array' is called with
`negative-argument', :key property will be omitted and
default `loophole-read-key' will be used for reading key."
  :risky t
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
\(OBTAIN-ENTRY :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes one argument a standard
prompt string and returns key sequence to be bound.
OBTAIN-KEYMAP is a function which takes one argument the
key to be bound, and returns keymap object on which key and
entry are bound; this overrides `loophole-editing'.

If `loophole-decide-obtaining-method-after-read-key' is
non-nil other than 'negative-argument, or while it is
'negative-argument and `loophole-bind-keymap' is called with
`negative-argument', :key property will be omitted and
default `loophole-read-key' will be used for reading key."
  :risky t
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
\(OBTAIN-ENTRY :key READ-KEY :keymap OBTAIN-KEYMAP).
READ-KEY is a function which takes one argument a standard
prompt string and returns key sequence to be bound.
OBTAIN-KEYMAP is a function which takes one argument the
key to be bound, and returns keymap object on which key and
entry are bound; this overrides `loophole-editing'.

If `loophole-decide-obtaining-method-after-read-key' is
non-nil other than 'negative-argument, or while it is
'negative-argument and `loophole-bind-symbol' is called with
`negative-argument', :key property will be omitted and
default `loophole-read-key' will be used for reading key."
  :risky t
  :type '(repeat sexp))

(defcustom loophole-set-key-order
  '(loophole-obtain-command-by-read-command
    loophole-obtain-kmacro-by-recursive-edit
    loophole-obtain-command-by-key-sequence
    loophole-obtain-kmacro-by-read-key
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
READ-KEY is a function which takes one argument a standard
prompt string and returns key sequence to be bound.

If `loophole-decide-obtaining-method-after-read-key' is
non-nil other than 'negative-argument, or while it is
'negative-argument and `loophole-set-key' is called with
`negative-argument', :key property will be omitted and
default `loophole-read-key' will be used for reading key."
  :risky t
  :type '(repeat sexp))

(define-obsolete-variable-alias 'loophole-register-functions
  'loophole-after-register-functions "0.7.6")
(defcustom loophole-after-register-functions nil
  "Hook for `loophole-register'.
Functions added to this user option are called with one
argument, registered map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-unregister-functions
  'loophole-after-unregister-functions "0.7.6")
(defcustom loophole-after-unregister-functions nil
  "Hook for `loophole-unregister'.
Functions added to this user option are called with one
argument, unregistered map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-prioritize-functions
  'loophole-after-prioritize-functions "0.7.6")
(defcustom loophole-after-prioritize-functions nil
  "Hook for `loophole-prioritize'.
Functions added to this user option are called with one
argument, prioritized map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-globalize-functions
  'loophole-after-globalize-functions "0.7.6")
(defcustom loophole-after-globalize-functions nil
  "Hook for `loophole-globalize'.
Functions added to this user option are called with one
argument, globalized map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-localize-functions
  'loophole-after-localize-functions "0.7.6")
(defcustom loophole-after-localize-functions nil
  "Hook for `loophole-localize'.
Functions added to this user option are called with one
argument, localized map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-enable-functions
  'loophole-after-enable-functions "0.7.6")
(defcustom loophole-after-enable-functions nil
  "Hook for `loophole-enable'.
Functions added to this user option are called with one
argument, enabled map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-disable-functions
  'loophole-after-disable-functions "0.7.6")
(defcustom loophole-after-disable-functions nil
  "Hook for `loophole-disable'.
Functions added to this user option are called with one
argument, disabled map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-start-editing-functions
  'loophole-after-start-editing-functions "0.7.6")
(defcustom loophole-after-start-editing-functions nil
  "Hook for `loophole-start-editing'.
Functions added to this user option are called with one
argument, which is being edited map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-stop-editing-functions
  'loophole-after-stop-editing-functions "0.7.6")
(defcustom loophole-after-stop-editing-functions nil
  "Hook for `loophole-stop-editing'.
Functions added to this user option are called with one
argument, which has been edited map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-globalize-editing-functions
  'loophole-after-globalize-editing-functions "0.7.6")
(defcustom loophole-after-globalize-editing-functions nil
  "Hook for `loophole-globalize-editing'.
Functions added to this user option are called with one
argument, which is being edited map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-localize-editing-functions
  'loophole-after-localize-editing-functions "0.7.6")
(defcustom loophole-after-localize-editing-functions nil
  "Hook for `loophole-localize-editing'.
Functions added to this user option are called with one
argument, which is being edited map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-name-functions
  'loophole-after-name-functions "0.7.6")
(defcustom loophole-after-name-functions nil
  "Hook for `loophole-name'.
Functions added to this user option are called with one
argument, named new map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-merge-functions
  'loophole-after-merge-functions "0.7.6")
(defcustom loophole-after-merge-functions nil
  "Hook for `loophole-merge'.
Functions added to this user option are called with one
argument, merger map variable."
  :type 'hook)

(define-obsolete-variable-alias 'loophole-duplicate-functions
  'loophole-after-duplicate-functions "0.7.6")
(defcustom loophole-after-duplicate-functions nil
  "Hook for `loophole-duplicate'.
Functions added to this user option are called with two
argument, first one is original map variable and second one
is duplicated new map variable."
  :type 'hook)

(defcustom loophole-read-buffer-set-up-hook nil
  "Hook run after the buffer for `loophole-read-buffer' is set up."
  :type 'hook)

(defcustom loophole-bind-hook nil
  "Hook for `loophole-bind-entry'.
Because binding commands including `loophole-set-key' and
`loophole-unset-key' finally call `loophole-bind-entry',
this hook is run with all of them."
  :type 'hook)

(defcustom loophole-default-storage-file
  (concat user-emacs-directory "loophole-maps")
  "Default file path to storage Loophole maps.
`loophole-save' and `loophole-load' use this user option if
file is not specified by an argument."
  :type 'file)

(defcustom loophole-make-load-overwrite-map 'temporary
  "Flag if `loophole-load' overwrites existing map without prompt.
If the value is symbol all, any map will be overwritten.
If the value is symbol temporary, only temporary maps that
look like loophole-n-map will be overwritten.
If the value is function, it will be used as predicate that
takes one argument, each map-variable of loaded Loophole
maps.
If the value is non-nil but other than above, normal
Loophole maps that look like loophole-*-map will be
overwritten.
If the value is nil, always ask user to overwrite a map."
  :type '(choice (const :tag "Temporary Loophole maps" temporary)
                 (const :tag "All registered maps" all)
                 (const nil)
                 (function :tag "Predicate to filter maps")
                 (other :tag "Normal Loophole maps" t)))

(defcustom loophole-print-event-in-char-read-syntax t
  "Flag if question mark format is used for printing ordinary keys.
This user option mainly affects to modifying functions like
`loophole-modify-kmacro' and `loophole-modify-array'.
When they print events stored in kmacro or array, this user
option is referred to decide format.

If nil, ordinary key event is printed as raw integer."
  :type 'boolean)

(defcustom loophole-tag-sign "#"
  "String indicating tag string of Loophole map."
  :type 'string)

(defcustom loophole-mode-lighter-base " L"
  "Lighter base string for mode line."
  :type 'string)

(defcustom loophole-mode-lighter-editing-sign "+"
  "Lighter editing sign string for mode line."
  :type 'string)

(defcustom loophole-mode-lighter-suspending-sign "-"
  "Lighter suspending sign string for mode line."
  :type 'string)

(defcustom loophole-mode-lighter-use-face nil
  "Flag if lighter use face.
Even if this value is non-nil, mode-line lighter of Loophole
may stay having no face with default `mode-line-format',
because `minor-mode-alist' in default `mode-line-format',
and `mode-line-modes' may be already propertized with some
text properties.  To show `loophole-mode-lighter' with face,
`mode-line-format' have to be modified by something like the
following customization form.  Note that the following form
eliminates help echos and clickable buttons.
  (setq mode-line-modes
        (list \"%[\" \"(\"
              \\='mode-name
              \\='mode-line-process
              \\='minor-mode-alist
              \"%n\" \")\" \"%]\" \" \"))"
  :type 'boolean)

(defconst loophole-mode-lighter-preset-alist
  '((tag . (""
            loophole-mode-lighter-base
            (:eval (if (and (loophole-suspending-p)
                            (not loophole-mode-lighter-use-face))
                       loophole-mode-lighter-suspending-sign))
            (:eval (if (loophole-editing)
                       (concat
                        loophole-mode-lighter-editing-sign
                        (let ((tag (get (loophole-editing) :loophole-tag)))
                          (if (and loophole-mode-lighter-use-face
                                   (stringp tag))
                              (propertize (replace-regexp-in-string
                                           "%" "%%"
                                           (substitute-command-keys tag))
                                          'face 'loophole-editing)
                            tag)))))
            (:eval
             (let ((l (seq-filter #'symbol-value
                                  (loophole-state-variable-list))))
               (if (zerop (length l))
                   ""
                 (concat loophole-tag-sign
                         (mapconcat
                          (lambda (state-variable)
                            (let ((e (replace-regexp-in-string
                                      "%" "%%"
                                      (substitute-command-keys
                                       (let ((tag (get
                                                   (get state-variable
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
               (:eval (if (loophole-editing)
                          loophole-mode-lighter-editing-sign))
               (:eval (let ((n (length
                                (seq-filter #'symbol-value
                                            (loophole-state-variable-list)))))
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
               (:eval (if (loophole-editing)
                          loophole-mode-lighter-editing-sign))))
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
  :type 'sexp)

(defface loophole-using
  '((t :inherit error))
  "Face used for section of lighter showing active Loophole map.")

(defface loophole-editing
  '((t))
  "Face used for section of lighter showing editing Loophole map.")

(defface loophole-suspending
  '((t :inherit shadow))
  "Face used for suffixes of lighter while loophole is suspending.")

;;; Auxiliary functions

(defun loophole-map-variable (state-variable)
  "Return map-variable of STATE-VARIABLE."
  (let ((map-variable (get state-variable :loophole-map-variable))
        (keymap
         (cdr (assq state-variable (default-value 'loophole--map-alist)))))
    (if (and map-variable
             (eq (symbol-value map-variable) keymap))
        map-variable
      (error "The argument is not valid state-variable: %s" state-variable))))

(defun loophole-state-variable (map-variable)
  "Return state-variable of MAP-VARIABLE."
  (let* ((state-variable (get map-variable :loophole-state-variable))
         (keymap
          (cdr (assq state-variable (default-value 'loophole--map-alist)))))
    (if (and state-variable
             map-variable
             (eq (symbol-value map-variable) keymap))
        state-variable
      (error "The argument is not valid map-variable: %s" map-variable))))

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
    (if (and loophole-allow-keyboard-quit
             (loophole-key-equal
              (vconcat (where-is-internal 'keyboard-quit nil t))
              (vconcat key)))
        (keyboard-quit))
    key))

(defun loophole-read-key-with-time-limit (prompt)
  "Read keys with time limit, and return read key sequence.
PROMPT is a prompt string displayed at the first time for
reading key.  For a second or later time for reading key,
read keys will be shown in echo area."
  (let ((menu-prompting nil)
        (quit (vconcat (where-is-internal 'keyboard-quit nil t)))
        (read-keys nil))
    (let ((timer (run-with-idle-timer
                  loophole-read-key-limit-time
                  t
                  (lambda ()
                    (if read-keys (throw 'loophole-read-keys read-keys))))))
      (unwind-protect
          (let ((key (catch 'loophole-read-keys
                       (setq read-keys (vector (read-key prompt)))
                       (while t
                         (if (and loophole-allow-keyboard-quit
                                  (not (zerop (length quit)))
                                  (loophole-key-equal
                                   (seq-take (reverse read-keys) (length quit))
                                   quit))
                             (keyboard-quit))
                         (setq read-keys
                               (vconcat read-keys
                                        (vector
                                         (read-key
                                          (mapconcat (lambda (e)
                                                       (key-description
                                                        (vector e)))
                                                     read-keys
                                                     " ")))))))))
            (or (vectorp key) (stringp key)
                (signal 'wrong-type-argument (list 'arrayp key)))
            key)
        (cancel-timer timer)))))

(defun loophole-read-key-until-termination-key (prompt)
  "Read keys until termination key, and return read key sequence.
PROMPT is a prompt string displayed with termination key and
read keys.

By default, `loophole-read-key-termination-key' is \\[keyboard-quit]
the key bound to `keyboard-quit'.  In this situation, you
cannot use \\[keyboard-quit] for quitting.
Once `loophole-read-key-termination-key' is changed, and
user option `loophole-allow-keyboard-quit' is non-nil,
\\[keyboard-quit] takes effect as quit."
  (let ((finish (vconcat loophole-read-key-termination-key))
        (quit (vconcat (where-is-internal 'keyboard-quit nil t))))
    (or (not (zerop (length finish)))
        (and loophole-allow-keyboard-quit (not (zerop (length quit))))
        (user-error "Neither finishing key nor quitting key is invalid"))
    (let ((menu-prompting nil))
      (letrec
          ((read-arbitrary-key-sequence
            (lambda (v)
              (let* ((k (vector
                         (read-key
                          (format "%s%s(%s to %s) [%s]"
                                  prompt
                                  (if (string-match "[^ ]$" prompt) " " "")
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
                      ((and loophole-allow-keyboard-quit
                            (not (zerop (length quit)))
                            (loophole-key-equal (seq-take k-v (length quit))
                                                quit))
                       (keyboard-quit))
                      (t (funcall read-arbitrary-key-sequence k-v)))))))
        (funcall read-arbitrary-key-sequence [])))))

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
  (let* ((map-variable-list
          (if predicate
              (seq-filter predicate (loophole-map-variable-list))
            (loophole-map-variable-list)))
         (help-condition '((index . 0) (last)))
         (minibuffer-help-form
          `(funcall
            #',(lambda ()
                 (let ((completions (all-completions
                                     (minibuffer-contents)
                                     minibuffer-completion-table
                                     minibuffer-completion-predicate))
                       (index (cdr (assq 'index help-condition)))
                       (last (cdr (assq 'last help-condition))))
                   (if completions
                       (progn
                         (if (equal completions last)
                             (push `(index
                                     .
                                     ,(if (< index (- (length completions) 1))
                                          (1+ index)
                                        0))
                                   help-condition)
                           (push '(index . 0) help-condition)
                           (push `(last . ,completions) help-condition))
                         (let* ((i (cdr (assq 'index help-condition)))
                                (map-variable (intern (elt completions i))))
                           (if map-variable (loophole-describe map-variable))))
                     (push '(index . 0) help-condition)
                     (push `(last . ,completions) help-condition)))))))
    (unless map-variable-list
      (user-error "There are no suitable loophole maps"))
    (intern (completing-read prompt map-variable-list nil t))))

(defmacro loophole--with-current-buffer-other-window (buffer-or-name &rest body)
  "Execute BODY with BUFFER-OR-NAME displayed in other window.
The buffer specified by BUFFER-OR-NAME is transiently
displayed in other window, and immediately after body is
executed, original window configuration is recovered."
  (declare (debug t) (indent 1))
  `(let ((window (selected-window))
         (frame (selected-frame))
         other-window)
     (unwind-protect
         (progn
           (switch-to-buffer-other-window (get-buffer-create ,buffer-or-name) t)
           (setq other-window (selected-window))
           ,@body)
       (if (window-prev-buffers)
           (progn
             (switch-to-prev-buffer other-window)
             (if (frame-live-p frame) (select-frame-set-input-focus frame t))
             (if (window-live-p window) (select-window window t)))
         (if (= 1 (length (window-list)))
             (delete-frame nil t)
           (delete-window))))))

(defun loophole-read-buffer (callback &optional buffer)
  "Read Lisp object from current buffer after user modifies it.

This function usually starts `recursive-edit', to give user
an environment for writing Lisp form on a buffer.
Typing `loophole-read-buffer-finish-key' finishes writing
form, and the first form is read and returned.
Typing `loophole-read-buffer-abort-key' aborts it.

If user option `loophole-read-buffer-inhibit-recursive-edit'
is non-nil, this function set up some utilities and `signal'
quit.  One of the utilities is a binidng
`loophole-read-buffer-finish-key' with a command which calls
CALLBACK with one argument a read form.
By these utilities, user can use the buffer as well as using
`recursive-edit' while released from `recursive-edit'.
To allow user to choose inhibiting `recursive-edit',
CALLBACK must be defined.

If optional argument BUFFER is non-nil and is an alive
buffer, use it instead of current buffer."
  (setq buffer (or (if (buffer-live-p buffer) buffer)
                   (current-buffer)))
  (with-current-buffer buffer
    (let* ((mode major-mode)
           (clean-buffer (lambda ()
                           (if (buffer-live-p buffer)
                               (with-current-buffer buffer
                                 (setq header-line-format nil)
                                 (use-local-map emacs-lisp-mode-map)
                                 (funcall mode))))))
      (emacs-lisp-mode)
      (use-local-map (let ((map (make-sparse-keymap)))
                       (set-keymap-parent map emacs-lisp-mode-map)
                       map))
      (setq header-line-format
            `(""
              mode-line-front-space
              ,(format "Writing lisp form.  finish `%s', Abort `%s'."
                       (key-description loophole-read-buffer-finish-key)
                       (key-description loophole-read-buffer-abort-key))))
      (if loophole-read-buffer-inhibit-recursive-edit
          (let* ((window (selected-window))
                 (frame (selected-frame))
                 (clean-window (lambda ()
                                 (if (window-prev-buffers)
                                     (progn
                                       (switch-to-prev-buffer nil t)
                                       (if (frame-live-p frame)
                                           (select-frame-set-input-focus frame
                                                                         t))
                                       (if (window-live-p window)
                                           (select-window window t)))
                                   (if (= 1 (length (window-list)))
                                       (delete-frame nil t)
                                     (delete-window)))))
                 (hook-function (make-symbol
                                 "loophole-one-time-hook-function")))
            (define-key (current-local-map) loophole-read-buffer-finish-key
              (lambda ()
                (interactive)
                (funcall clean-buffer)
                (unwind-protect
                    (if (functionp callback)
                        (save-excursion
                          (goto-char 1)
                          (funcall callback (read (current-buffer)))))
                  (funcall clean-window))))
            (define-key (current-local-map) loophole-read-buffer-abort-key
              (lambda ()
                (interactive)
                (funcall clean-buffer)
                (funcall clean-window)))
            (fset hook-function
                  (lambda ()
                    (unwind-protect
                        (progn
                          (switch-to-buffer-other-window buffer)
                          (run-hooks 'loophole-read-buffer-set-up-hook)
                          (message nil))
                      (remove-hook 'post-command-hook hook-function))))
            (add-hook 'post-command-hook hook-function)
            (signal 'quit nil))
        (define-key (current-local-map) loophole-read-buffer-finish-key
          (lambda ()
            (interactive)
            (funcall clean-buffer)
            (exit-recursive-edit)))
        (define-key (current-local-map) loophole-read-buffer-abort-key
          (lambda ()
            (interactive)
            (funcall clean-buffer)
            (abort-recursive-edit)))
        (loophole--with-current-buffer-other-window buffer
          (run-hooks 'loophole-read-buffer-set-up-hook)
          (recursive-edit)
          (save-excursion
            (goto-char 1)
            (read (current-buffer))))))))

(defun loophole-map-variable-for-keymap (keymap)
  "Return map variable whose value is KEYMAP."
  (let* ((state-variable (car (rassq keymap loophole--map-alist)))
         (map-variable (get state-variable :loophole-map-variable)))
    (if (eq (symbol-value map-variable) keymap)
        map-variable)))

(defun loophole-map-variable-for-key-binding (key)
  "Return map variable for active KEY in `loophole--map-alist'."
  (get (car (seq-find (lambda (a)
                        (let ((binding (lookup-key (cdr a) key t)))
                          (and (symbol-value (car a))
                               binding
                               (not (numberp binding))
                               (eq binding (key-binding key t)))))
                      loophole--map-alist))
       :loophole-map-variable))

(defun loophole-priority-is-local-p ()
  "Non-nil if priority of Loophole maps is local on current buffer.
Technically, non-nil if `loophole--map-alist' has local
value on `current-buffer'."
  (local-variable-p 'loophole--map-alist))

(defun loophole-global-p (map-variable)
  "Non-nil if MAP-VARIABLE is registered as global map."
  (and (loophole-registered-p map-variable)
       (not (local-variable-if-set-p
             (get map-variable :loophole-state-variable)))))

(defun loophole-global-editing-p ()
  "Non-nil if editing session is global."
  (not (eq (default-value 'loophole--editing) t)))

(defun loophole-suspending-p ()
  "Non-nil during suspending Loophole.
During suspension, `loophole--map-alist' is removed from
`emulation-mode-map-alists'.
Consequently, all Loophole maps lose effect while its state
is preserved."
  (not (memq 'loophole--map-alist emulation-mode-map-alists)))

(defun loophole-editing ()
  "Return map variable which is being currently edited.
If editing session is global, return default value of
`loophole--editing'.  If editing session is local, return
buffer local value."
  (if (eq (default-value 'loophole--editing) t)
      (if (local-variable-p 'loophole--editing)
          loophole--editing
        nil)
    (default-value 'loophole--editing)))

(defun loophole--char-read-syntax (event)
  "Return printed representation of EVENT by question mark format.
This function assumes that EVENT is a component of a vector
for keyboard events.
An ordinary key event, i.e., integer is translated into
question mark format string; otherwise, EVENT itself is
returned."
  (if (integerp event)
      (let ((modifiers (event-modifiers event))
            (basic-type (event-basic-type event)))
        (format "?%s%s"
                (mapconcat (lambda (modifier)
                             (format "\\%s-"
                                     (cond ((eq modifier 'meta) "M")
                                           ((eq modifier 'control) "C")
                                           ((eq modifier 'shift) "S")
                                           ((eq modifier 'hyper) "H")
                                           ((eq modifier 'super) "s")
                                           ((eq modifier 'alt) "A"))))
                           modifiers "")
                (char-to-string basic-type)))
    (prin1-to-string event)))

(defun loophole--symbol-function-recursively (symbol)
  "Return function definition of SYMBOL traced recursively.
`indirect-function' is used to find definition but if
cyclic-function-indirection is signaled, SYMBOL itself is
returned."
  (condition-case _
      (indirect-function symbol)
    (cyclic-function-indirection symbol)))

(defun loophole--protected-keymap-entry-list (protected-keymap)
  "Return list of protected keymap element from raw PROTECTED-KEYMAP.
PROTECTED-KEYMAP is flatten keymap object stored in the each
map-variable as symbol property :loophole-protected-keymap.
It looks like
  (keymap (keymap ... body of entry1)
          (keymap ... wall of entry1)
          (keymap ... body of entry2)
          (keymap ... wall of entry2)
          ...).
This function makes each entry grouped and return a list of
them.  It looks like
  (((keymap ... body of entry1) (keymap ... wall of entry1))
   ((keymap ... body of entry2) (keymap ... wall of entry2))
   ...)."
  (if (and (keymapp protected-keymap)
           (keymap-parent protected-keymap))
      (error "Protected keymap is corrupted, it has parent keymap: %s"
             protected-keymap))
  (letrec ((entry-list
            (lambda (current)
              (cond ((null current) current)
                    ((null (cdr current))
                     (error
                      "Protected keymap is corrupted, it has odd length: %s"
                      protected-keymap))
                    (t (cons (list (car current) (cadr current))
                             (funcall entry-list (cddr current))))))))
    (funcall entry-list (cdr protected-keymap))))

(defun loophole--add-protected-keymap-entry (map-variable key keymap)
  "Add KEYMAP bound with KEY in protected region of MAP-VARIABLE.
Protected keymap is set in keymap parent and symbol property
:loophole-protected-keymap.
Ordinary key bindings that shades KEY will be removed to
make KEYMAP accessible."
  (unless (keymapp keymap)
    (signal 'wrong-type-argument (list 'keymapp keymap)))
  (let* ((map (symbol-value map-variable))
         (parent (keymap-parent map))
         (protected-keymap (get map-variable :loophole-protected-keymap)))
    (let ((lookup (lookup-key protected-keymap key))
          (trace (loophole--trace-key-to-find-non-keymap-entry
                  key protected-keymap)))
      (when (and (numberp lookup) trace)
        (error "Key sequence %s starts with non-prefix key %s"
               (key-description key)
               (key-description trace))))
    (set-keymap-parent map nil)
    (unwind-protect
        (letrec
            ((existing-cell
              (lambda (key-list object)
                (cond ((or (null object) (null key-list)) nil)
                      ((not (keymapp object))
                       (error
                        "Key sequence %s starts with non-prefix key %s"
                        (key-description key)
                        (key-description (vconcat
                                          (butlast (append key nil)
                                                   (length key-list))))))
                      ((assoc (car key-list) object #'eql)
                       (or (funcall existing-cell
                                    (cdr key-list)
                                    (cdr (assoc (car key-list) object #'eql)))
                           (letrec ((one-before
                                     (lambda (last-key list)
                                       (cond ((eql (caadr list) last-key) list)
                                             (t (funcall one-before last-key
                                                         (cdr list)))))))
                             (funcall one-before (car key-list) object))))))))
          (let ((cell (funcall existing-cell (append key nil) map)))
            (if cell (setcdr cell (cddr cell)))))
      (set-keymap-parent map parent))
    (unless protected-keymap
      (setq protected-keymap (make-sparse-keymap))
      (put map-variable :loophole-protected-keymap protected-keymap)
      (let ((parent (keymap-parent map)))
        (cond ((null parent) (set-keymap-parent map protected-keymap))
              ((memq loophole-base-map parent)
               (setcdr parent (cons protected-keymap (cdr parent))))
              (t (set-keymap-parent map (make-composed-keymap
                                         (list protected-keymap parent)))))))
    (setcdr protected-keymap
            (let ((body-map (make-sparse-keymap))
                  (wall-map (make-sparse-keymap)))
              (define-key body-map key keymap)
              (define-key wall-map key 'undefined)
              (cons body-map (cons wall-map (cdr protected-keymap)))))))

(defun loophole--set-ordinary-entry (map-variable key entry)
  "Set KEY as ordinary ENTRY in MAP-VARIABLE.
This function `define-key' KEY and ENTRY in a keymap bound
with MAP-VARIABLE with taking care of protected keymap
entry.  When KEY shades existing protected keymap entry,
they will be removed."
  (let ((protected-keymap (get map-variable :loophole-protected-keymap)))
    (if (< 0 (length key))
        (let ((non-prefix-key (loophole--trace-key-to-find-non-keymap-entry
                               (vconcat (butlast (append key nil) 1))
                               protected-keymap)))
          (if non-prefix-key
              (error "Key sequence %s starts with non-prefix key %s"
                     (key-description key)
                     (key-description non-prefix-key)))))
    (define-key (symbol-value map-variable) key entry)
    (letrec ((shadedp
              (lambda (object key-list)
                (cond ((null key-list))
                      ((and (keymapp object)
                            (progn
                              (if (symbolp object)
                                  (setq object (symbol-function object)))
                              (= 2 (length object)))
                            (assoc (car key-list) object #'eql))
                       (funcall shadedp
                                (cdr (assoc (car key-list) object #'eql))
                                (cdr key-list)))))))
      (dolist (shaded (apply
                       #'append
                       (seq-filter (lambda (protected-element)
                                     (funcall shadedp (car protected-element)
                                              (append key nil)))
                                   (loophole--protected-keymap-entry-list
                                    protected-keymap))))
        (setcdr protected-keymap (delq shaded (cdr protected-keymap))))
      (when (< (length protected-keymap) 2)
        (let* ((map (symbol-value map-variable))
               (parent (keymap-parent map)))
          (cond ((eq parent protected-keymap) (set-keymap-parent map nil))
                ((memq protected-keymap parent)
                 (setcdr parent (delq protected-keymap (cdr parent)))
                 (if (= (length parent) 2)
                     (set-keymap-parent map (cadr parent)))))
          (put map-variable :loophole-protected-keymap nil))))))

(defun loophole--protected-keymap-prefix-key (protected-element)
  "Return prefix keys vector of PROTECTED-ELEMENT.
PROTECTED-ELEMENT must be a list object representing
protected keymap entry, i.e., looks like
  ((keymap (KEY (keymap ... (KEY . SYMBOL))))
   (keymap (KEY (keymap ... (KEY . undefined)))))
or
  ((keymap (KEY (keymap ... (KEY . (keymap ...)))))
   (keymap (KEY (keymap ... (KEY . undefined))))).
First one is for a symbol whose function cell is a keymap.
Second one is for a keymap object.
The portion (KEY (keymap ... (KEY ...))) is a prefix key,
and SYMBOL and last (keymap ...) is an entry.

Actually, this function searches the symbol undefined in
the cadr of PROTECTED-ELEMENT and return found keys vector."
  (letrec ((prefix-key-list
            (lambda (object)
              (cond ((eq object 'undefined) nil)
                    ((or (not (consp (cdr object)))
                         (not (= (length object) 2))
                         (not (or (characterp (caadr object))
                                  (symbolp (caadr object))))
                         (not (or (keymapp (cdadr object))
                                  (eq 'undefined (cdadr object)))))
                     (error "KEYMAP is not an element of protected keymap"))
                    (t (cons (caadr object)
                             (funcall prefix-key-list (cdadr object))))))))
    (vconcat (funcall prefix-key-list (cadr protected-element)))))

(defun loophole--trace-key-to-find-non-keymap-entry (key-sequence keymap)
  "Trace KEY-SEQUENCE in KEYMAP to find non-keymap entry.
If found, return a key sequence bound to non-keymap entry;
otherwise, return nil."
  (letrec ((find-non-keymap-entry
            (lambda (reversal-key-list)
              (let ((entry (lookup-key keymap
                                       (vconcat (reverse reversal-key-list)))))
                (cond ((or (null reversal-key-list) (null entry)) nil)
                      ((or (keymapp entry) (numberp entry))
                       (funcall find-non-keymap-entry (cdr reversal-key-list)))
                      (t (vconcat (reverse reversal-key-list))))))))
    (funcall find-non-keymap-entry (reverse (append key-sequence nil)))))

(defun loophole-toss-binding-form (key form)
  "Try to store FORM in a Loophole map of the next binding.
This function adds advice which try to add cons cell of KEY
and FORM to the symbol property :loophole-form-storage of
map-variable which is returned from subsequent
`loophole-bind-entry' if it successfully binds KEY and entry
derived from FORM.

Regardless of the binding result, advice is removed.

Some Loophole functions use stored forms to keep KEY bound
with appropriate object,  typically, a keymap object.
For example, when `loophole-save' saves Loophole map who
have a binding for keymap object, it will be printed in a
storage file and link for the object is lost.  If a form for
getting that keymap object is stored, `loophole-save' also
saves this form in a file, and `loophole-load' reproduce the
link to the keymap object.

Usually, obtaining methods who obtain keymap object may call
this function.

Be careful when FORM has a side effect, because FORM is
evaluated occasionally in future."
  (let ((advice (make-symbol "loophole-one-time-advice")))
    (fset advice (lambda (bind-entry binding-key binding-entry
                                     &optional binding-keymap)
                   (unwind-protect
                       (let ((map-variable
                              (apply bind-entry
                                     binding-key binding-entry binding-keymap)))
                         (if (and (loophole-key-equal key binding-key)
                                  (eq (eval form) binding-entry))
                             (put map-variable
                                  :loophole-form-storage
                                  (cons (cons key form)
                                        (get map-variable
                                             :loophole-form-storage))))
                         map-variable)
                     (advice-remove 'loophole-bind-entry advice))))
    (advice-add 'loophole-bind-entry :around advice)))

(defun loophole--valid-form (map-variable)
  "Return list of valid stored form of MAP-VARIABLE.
Invalid and duplicated forms are removed by side effect."
  (let ((valid-form (seq-uniq
                     (seq-filter (lambda (key-form)
                                   (eq (lookup-key
                                        (symbol-value map-variable)
                                        (car key-form))
                                       (eval (cdr key-form))))
                                 (get map-variable :loophole-form-storage)))))
    (put map-variable :loophole-form-storage valid-form)
    valid-form))

(defun loophole--erase-local-timers (map-variable)
  "Cancel and remove all local timers for MAP-VARIABLE .
This function is intended to be used in `loophole-globalize'
and `loophole-unregister'."
  (dolist (buffer (loophole-buffer-list))
    (with-current-buffer buffer
      (when (local-variable-p 'loophole--timer-alist)
        (let ((timer (cdr (assq map-variable loophole--timer-alist))))
          (if (timerp timer) (cancel-timer timer)))
        (setq loophole--timer-alist
              (seq-filter (lambda (cell) (not (eq (car cell) map-variable)))
                          loophole--timer-alist))
        (if (null loophole--timer-alist)
            (kill-local-variable 'loophole--timer-alist))))))

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
    (dolist (replacing-buffer (loophole-buffer-list))
      (with-current-buffer replacing-buffer
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
                       (list new-map-variable (current-buffer))))))))))))

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

(defun loophole-tag-string (map-variable)
  "Return tag string for MAP-VARIABLE."
  (if (loophole-registered-p map-variable)
      (get map-variable :loophole-tag)
    (error "Specified argument is not valid map-variable: %s" map-variable)))

(defun loophole-buffer-list ()
  "Return buffer list on which Loophole variables have local value.
This function sanitize orphan hooks by side effect.
`loophole--follow-killing-local-variable' on
`change-major-mode-hook' and `kill-buffer-hook' is removed,
if certain Loophole buffer no longer has local Loophole
variable."
  (let ((filter (lambda (buffer)
                  (and (buffer-live-p buffer)
                       (with-current-buffer buffer
                         (let ((hava-local-variable
                                (seq-some
                                 #'local-variable-p
                                 (loophole-local-variable-if-set-list))))
                           (unless hava-local-variable
                             (remove-hook
                              'change-major-mode-hook
                              #'loophole--follow-killing-local-variable t)
                             (remove-hook
                              'kill-buffer-hook
                              #'loophole--follow-killing-local-variable t))
                           hava-local-variable))))))
    (if (listp loophole--buffer-list)
        (setq loophole--buffer-list (seq-filter filter loophole--buffer-list))
      (seq-filter filter (buffer-list)))))

(defun loophole-registered-p (map-variable &optional state-variable)
  "Return non-nil if MAP-VARIABLE is registered to loophole.
If optional argument STATE-VARIABLE is not nil,
Return non-nil if both MAP-VARIABLE and STATE-VARIABLE are
registered, and they are associated."
  (and map-variable
       (if state-variable
           (eq state-variable (get map-variable :loophole-state-variable))
         (setq state-variable (get map-variable :loophole-state-variable)))
       (eq map-variable (get state-variable :loophole-map-variable))
       (eq (symbol-value map-variable)
           (cdr (assq state-variable (default-value 'loophole--map-alist))))))

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
If parent of keymap of MAP-VARIABLE is non-nil when setting
parent keymap, composed keymap is made from exisiting parent
and `loophole-base-map'.
Because `loophole-unregister' assumes that a keymap parent
has a form described above, if other feature modifies keymap
parent, `loophole-unregister' cannot remove
`loophole-base-map' properly.

Furthermore, Loophole uses parent keymap for protected
keymap entry.  Therefore, if other feature modifies keymap
parent of registered Loophole map, some entries may be
corrupted.
Be careful especially when registering keymaps controlled by
the feature other than Loophole.

If called interactively, read MAP-VARIABLE, STATE-VARIABLE.
When called with prefix argument, read TAG and ask user if
MAP-VARIABLE is registered as GLOBAL and WITHOUT-BASE-MAP."
  (interactive
   (let* ((map-variable-list (loophole-map-variable-list))
          (state-variable-list (loophole-state-variable-list))
          (arg-map-variable
           (intern (completing-read
                    "Map-variable: "
                    obarray
                    (lambda (s)
                      (and (boundp s) (not (keywordp s))
                           (keymapp (symbol-value s))
                           (not (memq s map-variable-list))))
                    t)))
          (arg-state-variable
           (intern (completing-read
                    "State-variable: "
                    obarray
                    (lambda (s)
                      (and (boundp s) (not (keywordp s))
                           (not (eq arg-map-variable s))
                           (not (memq s map-variable-list))
                           (not (memq s state-variable-list))))
                    t)))
          (arg-tag
           (cond ((and (eq loophole-make-register-always-read-tag 'infer)
                       (null current-prefix-arg))
                  (let ((map-variable-name (symbol-name arg-map-variable)))
                    (cond ((string-match "loophole-\\([0-9]+\\)-map"
                                         map-variable-name)
                           (match-string 1 map-variable-name))
                          ((string-match "loophole-\\(.+\\)-map"
                                         map-variable-name)
                           (substring (match-string 1 map-variable-name) 0 1))
                          (t (read-string (format "Tag for keymap %s: "
                                                  arg-map-variable))))))
                 ((or loophole-make-register-always-read-tag
                      current-prefix-arg)
                  (read-string (format "Tag for keymap %s: " arg-map-variable)))
                 (t nil)))
          (arg-global (if current-prefix-arg
                          (y-or-n-p "Register as global Loophole map? ")))
          (arg-without-base-map (if current-prefix-arg
                                    (y-or-n-p "Register without base map? "))))
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
  (dolist (buffer (loophole-buffer-list))
    (with-current-buffer buffer
      (if (local-variable-p 'loophole--map-alist)
          (setq loophole--map-alist
                (cons `(,state-variable . ,(symbol-value map-variable))
                      loophole--map-alist)))))
  (let ((parent (keymap-parent (symbol-value map-variable))))
    (unless (and parent
                 (or (eq parent (get map-variable :loophole-protected-keymap))
                     (memq (get map-variable :loophole-protected-keymap)
                           parent)))
      (put map-variable :loophole-protected-keymap nil)))
  (loophole--valid-form map-variable)
  (when (and (listp loophole--buffer-list)
             (not global))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (local-variable-p state-variable)
          (add-to-list 'loophole--buffer-list buffer nil #'eq)
          (force-mode-line-update))))
    (add-variable-watcher state-variable
                          #'loophole--follow-adding-local-variable))
  (unless without-base-map
    (let ((parent (keymap-parent (symbol-value map-variable))))
      (cond ((null parent)
             (set-keymap-parent (symbol-value map-variable) loophole-base-map))
            ((and (get map-variable :loophole-protected-keymap)
                  (memq (get map-variable :loophole-protected-keymap) parent))
             (let ((grand-parent (keymap-parent parent)))
               (set-keymap-parent parent nil)
               (unwind-protect
                   (setcdr (last parent) (cons loophole-base-map nil))
                 (set-keymap-parent parent grand-parent))))
            (t (set-keymap-parent (symbol-value map-variable)
                                  (make-composed-keymap
                                   (list parent loophole-base-map)))))))
  (run-hook-with-args 'loophole-after-register-functions map-variable))

(defun loophole-unregister (map-variable &optional sanitize)
  "Unregister MAP-VARIABLE from Loophole.
Even after MAP-VARIABLE is unregistered, some data are kept
in a `symbol-plist' of MAP-VARIABLE in preparation for
re-registration.
If optional argument SANITIZE is non-nil, all data are
removed.

When called interactively with prefix-argument, SANITIZE is
set as non-nil."
  (interactive (list (loophole-read-map-variable "Unregister keymap:")
                     current-prefix-arg))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (if (loophole-global-p map-variable)
      (loophole--erase-global-timer map-variable)
    (loophole--erase-local-timers map-variable))
  (if (loophole-global-editing-p)
      (progn
        (loophole-stop-editing-timer)
        (loophole-stop-editing)
        (force-mode-line-update t))
    (dolist (buffer (loophole-buffer-list))
      (with-current-buffer buffer
        (when (and (local-variable-p 'loophole--editing)
                   (eq loophole--editing map-variable))
          (loophole-stop-editing-timer)
          (loophole-stop-editing)
          (force-mode-line-update)))))
  (let ((state-variable (get map-variable :loophole-state-variable)))
    (when (listp loophole--buffer-list)
      (remove-variable-watcher state-variable
                               #'loophole--follow-adding-local-variable)
      (dolist (buffer (loophole-buffer-list))
        (with-current-buffer buffer
          (when (and (local-variable-p state-variable)
                     (not (seq-some
                           #'local-variable-p
                           (remq state-variable
                                 (loophole-local-variable-if-set-list)))))
            (setq loophole--buffer-list
                  (delq buffer loophole--buffer-list))
            (remove-hook 'change-major-mode-hook
                         #'loophole--follow-killing-local-variable t)
            (remove-hook 'kill-buffer-hook
                         #'loophole--follow-killing-local-variable t)))))
    (let ((parent (keymap-parent (symbol-value map-variable))))
      (cond ((eq parent loophole-base-map)
             (set-keymap-parent (symbol-value map-variable) nil))
            ((memq loophole-base-map parent)
             (let ((grand-parent (keymap-parent parent)))
               (set-keymap-parent parent nil)
               (unwind-protect
                   (let ((others (remq loophole-base-map (cdr parent))))
                     (set-keymap-parent
                      (symbol-value map-variable)
                      (cond ((or grand-parent (< 1 (length others)))
                             (make-composed-keymap others grand-parent))
                            ((zerop (length others)) nil)
                            (t (car others)))))
                 (if (and grand-parent
                          (eq (keymap-parent (symbol-value map-variable))
                              parent))
                     (set-keymap-parent parent grand-parent)))))))
    (when sanitize
      (put map-variable :loophole-form-storage nil)
      (put map-variable :loophole-protected-keymap nil))
    (dolist (buffer (loophole-buffer-list))
      (with-current-buffer buffer
        (if (local-variable-p 'loophole--map-alist)
            (setq loophole--map-alist
                  (seq-filter
                   (lambda (cell) (not (eq (car cell) state-variable)))
                   loophole--map-alist)))))
    (setq-default loophole--map-alist
                  (seq-filter (lambda (cell)
                                (not (eq (car cell) state-variable)))
                              (default-value 'loophole--map-alist)))
    (put map-variable :loophole-tag nil)
    (put state-variable :loophole-map-variable nil)
    (put map-variable :loophole-state-variable nil))
  (run-hook-with-args 'loophole-after-unregister-functions map-variable))

(defun loophole-prioritize (map-variable &optional only)
  "Give first priority to MAP-VARIABLE.
This is done by move the entry in `loophole--map-alist' to
the front.

This function modifies both local and default value of
`loophole--map-alist'.  If optional argument ONLY is
a symbol local, only local value is modified; or if ONLY is
a symbol default, only default value is modified."
  (interactive (list (loophole-read-map-variable "Prioritize keymap: ")))
  (if (loophole-registered-p map-variable)
      (let ((state-variable (get map-variable :loophole-state-variable)))
        (unless (eq only 'default)
          (setq loophole--map-alist
                (cons `(,state-variable . ,(symbol-value map-variable))
                      (seq-filter (lambda (cell)
                                    (not (eq (car cell) state-variable)))
                                  loophole--map-alist))))
        (unless (eq only 'local)
          (setq-default
           loophole--map-alist
           (cons `(,state-variable . ,(symbol-value map-variable))
                 (seq-filter (lambda (cell)
                               (not (eq (car cell) state-variable)))
                             (default-value 'loophole--map-alist)))))
        (run-hook-with-args 'loophole-after-prioritize-functions map-variable))
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
      (dolist (buffer (loophole-buffer-list))
        (with-current-buffer buffer
          (if (local-variable-p 'loophole--map-alist)
              (let ((cell (assq state-variable loophole--map-alist)))
                (if (consp cell) (setcar cell globalized-state-variable))))
          (if (listp loophole--buffer-list)
              (unless (seq-some #'local-variable-p
                                (loophole-local-variable-if-set-list))
                (setq loophole--buffer-list
                      (delq (current-buffer) loophole--buffer-list))
                (remove-hook 'change-major-mode-hook
                             #'loophole--follow-killing-local-variable t)
                (remove-hook 'kill-buffer-hook
                             #'loophole--follow-killing-local-variable t))))))
    (loophole--erase-local-timers map-variable)
    (run-hook-with-args 'loophole-after-globalize-functions map-variable)))

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
      (run-hook-with-args 'loophole-after-localize-functions map-variable))))

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
        (run-hook-with-args 'loophole-after-enable-functions map-variable))
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
        (run-hook-with-args 'loophole-after-disable-functions map-variable))
    (user-error "Specified map-variable %s is not registered" map-variable)))

(defun loophole-disable-latest ()
  "Disable the lastly added or prioritized active keymap."
  (interactive)
  (let* ((state-variable
          (seq-find #'symbol-value (loophole-state-variable-list)))
         (map-variable (get state-variable :loophole-map-variable)))
    (if map-variable
        (loophole-disable map-variable)
      (message "There are no enabled loophole maps"))))

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
manipulated as unregistered; their properties for Loophole
are set as nil, they are removed from `loophole--map-alist'.

If loophole-MAP-NAME-map or loophole-MAP-NAME-map-state have
been already bound, this function asks user if Loophole can
use it anyway.
These query can be skipped with yes by setting t to
`loophole-force-overwrite-bound-variable'.

Global or local behavior is also inherited.
loophole-MAP-NAME-map-state is prepared by the same manner
of `loophole-register'.
If global or local property of loophole-MAP-NAME-map-state
does not match with MAP-VARIABLE, this function asks user
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
  (if (and (stringp map-name) (not (< 0 (length map-name))))
    (user-error "Name cannot be empty string"))
  (let* ((state-variable (get map-variable :loophole-state-variable))
         (map-variable-name (format "loophole-%s-map" map-name))
         (state-variable-name (concat map-variable-name "-state"))
         (tag (or tag (substring map-name 0 1))))
    (let ((named-map-variable (intern map-variable-name))
          (named-state-variable (intern state-variable-name)))
      (if (loophole-registered-p named-map-variable)
          (user-error "Specified name %s has already been used" map-name))
      (if (boundp named-map-variable)
          (unless (or loophole-force-overwrite-bound-variable
                      (yes-or-no-p
                       (format "%s has already been bound.  Use it anyway? "
                               named-map-variable)))
            (user-error "Abort naming.  Variable %s is preserved"))
        (put named-map-variable 'variable-documentation
             "Keymap for temporary use.
Introduced by `loophole-name'."))
      (if (boundp named-state-variable)
          (unless (or loophole-force-overwrite-bound-variable
                      (yes-or-no-p
                       (format "%s has already been bound.  Use it anyway? "
                               named-state-variable)))
            (user-error "Abort naming.  Variable %s is preserved"))
        (put named-state-variable 'variable-documentation
             (format "State of `%s'.
Introduced by `loophole-name'." named-map-variable)))
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
      (set named-map-variable (symbol-value map-variable))
      (if (not (local-variable-if-set-p named-state-variable))
          (set named-state-variable (symbol-value state-variable))
        (set-default named-state-variable nil)
        (dolist (buffer (loophole-buffer-list))
          (with-current-buffer buffer
            (if (local-variable-p state-variable)
                (set named-state-variable (symbol-value state-variable))))))
      (put named-map-variable :loophole-state-variable named-state-variable)
      (put named-state-variable :loophole-map-variable named-map-variable)
      (put named-map-variable :loophole-tag tag)
      (if (and (local-variable-if-set-p named-state-variable)
               (listp loophole--buffer-list))
          (add-variable-watcher named-state-variable
                                #'loophole--follow-adding-local-variable))
      (put named-map-variable :loophole-protected-keymap
           (get map-variable :loophole-protected-keymap))
      (put named-map-variable :loophole-form-storage
           (get map-variable :loophole-form-storage))
      (let ((cell (assq state-variable (default-value 'loophole--map-alist))))
        (if (consp cell) (setcar cell named-state-variable)))
      (dolist (buffer (loophole-buffer-list))
        (with-current-buffer buffer
          (if (local-variable-p 'loophole--map-alist)
              (let ((cell (assq state-variable loophole--map-alist)))
                (if (consp cell) (setcar cell named-state-variable))))))
      (if (loophole-global-editing-p)
          (progn
            (setq-default loophole--editing named-map-variable)
            (force-mode-line-update t))
        (dolist (buffer (loophole-buffer-list))
          (with-current-buffer buffer
            (when (and (local-variable-p 'loophole--editing)
                       (eq map-variable loophole--editing))
              (setq loophole--editing named-map-variable)
              (force-mode-line-update)))))
      (loophole--replace-map-variable-of-timer map-variable named-map-variable)
      (if (listp loophole--buffer-list)
          (remove-variable-watcher state-variable
                                   #'loophole--follow-adding-local-variable))
      (put map-variable :loophole-tag nil)
      (put state-variable :loophole-map-variable nil)
      (put map-variable :loophole-state-variable nil)
      (run-hook-with-args 'loophole-after-name-functions named-map-variable))))

(defun loophole-tag (map-variable tag)
  "Set TAG to tag string of MAP-VARIABLE."
  (interactive
   (let* ((arg-map-variable
           (loophole-read-map-variable "Tag keymap: "))
          (arg-tag (read-string
                    (format "New tag for keymap %s%s%s: "
                            arg-map-variable
                            loophole-tag-sign
                            (loophole-tag-string arg-map-variable)))))
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
  (if (loophole-global-editing-p)
      (progn
        (setq-default loophole--editing map-variable)
        (force-mode-line-update t))
    (setq loophole--editing map-variable)
    (force-mode-line-update))
  (run-hook-with-args 'loophole-after-start-editing-functions map-variable))

(defun loophole-stop-editing ()
  "Stop keymap editing session."
  (interactive)
  (let ((map-variable (loophole-editing)))
    (if (loophole-global-editing-p)
        (progn
          (setq-default loophole--editing nil)
          (force-mode-line-update t))
      (setq loophole--editing nil)
      (force-mode-line-update))
    (run-hook-with-args 'loophole-after-stop-editing-functions map-variable)))

(defun loophole-globalize-editing ()
  "Make editing session global."
  (interactive)
  (if (loophole-global-editing-p)
      (message "Editing session is already global")
    (let ((editing (loophole-editing)))
      (dolist (buffer (loophole-buffer-list))
        (with-current-buffer buffer
          (when (local-variable-p 'loophole--editing-timer)
            (loophole-stop-editing-timer)
            (kill-local-variable 'loophole--editing-timer))
          (when (local-variable-p 'loophole--editing)
            (loophole-stop-editing)
            (kill-local-variable 'loophole--editing))))
      (setq-default loophole--editing editing)
      (force-mode-line-update t)
      (if (called-interactively-p 'interactive)
          (message "Editing session is globalized"))
      (run-hook-with-args 'loophole-after-globalize-editing-functions
                          editing))))

(defun loophole-localize-editing ()
  "Make editing session local."
  (interactive)
  (if (not (loophole-global-editing-p))
      (message "Editing session is already local")
    (let ((editing (loophole-editing)))
      (loophole-stop-editing)
      (loophole-stop-editing-timer)
      (setq-default loophole--editing-timer nil)
      (setq-default loophole--editing t)
      (setq loophole--editing editing)
      (force-mode-line-update t)
      (if (called-interactively-p 'interactive)
          (message "Editing session is localized"))
      (run-hook-with-args 'loophole-after-localize-editing-functions editing))))

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
                     (find-orphan-temporary-map-variable
                      (lambda (i)
                        (let ((s (intern
                                  (format "loophole-%d-map" i))))
                          (cond ((< loophole-temporary-map-max i) nil)
                                ((memq s reversal-map-variable-list)
                                 (funcall
                                  find-orphan-temporary-map-variable (1+ i)))
                                (t s)))))
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
                                  (loophole-buffer-list)))
                                (string-match
                                 "loophole-[0-9]+-map"
                                 (symbol-name map-var))))
                         reversal-map-variable-list)))
                     (find-earliest-used-temporary-map-variable
                      (lambda ()
                        (seq-find (lambda (map-var)
                                    (string-match
                                     "loophole-[0-9]+-map"
                                     (symbol-name map-var)))
                                  reversal-map-variable-list))))
              (or (funcall find-nonbound-temporary-map-variable 1)
                  (funcall find-orphan-temporary-map-variable 1)
                  (funcall find-earliest-used-disabled-temporary-map-variable)
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
    (if (local-variable-if-set-p state-variable)
        (unless (boundp state-variable) (setq-default state-variable nil))
      (if (loophole-global-p map-variable)
          (loophole-localize map-variable)
        (make-variable-buffer-local state-variable)))
    (dolist (buffer (loophole-buffer-list))
      (with-current-buffer buffer
        (when (and (local-variable-p state-variable)
                   (boundp state-variable)
                   (symbol-value state-variable))
          (set state-variable nil)
          (force-mode-line-update))))
    (if (loophole-registered-p map-variable state-variable)
        (loophole-unregister map-variable t))
    (set map-variable (make-sparse-keymap))
    (loophole-register map-variable state-variable tag)
    map-variable))

(defun loophole-ready-map ()
  "Return available temporary keymap.
If currently editing keymap exists, return it; otherwise
generate new one, prepare it, and return it."
  (let ((map-variable (or (loophole-editing)
                          (let ((generated (loophole-generate)))
                            (loophole-enable generated)
                            (loophole-start-editing generated)
                            generated))))
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
  (let ((timer (if (loophole-global-editing-p)
                   (default-value 'loophole--editing-timer)
                 loophole--editing-timer)))
    (if (timerp timer)
        (progn
          (timer-set-time timer (timer-relative-time nil time))
          (if (or (timer--triggered timer)
                  (not (memq timer timer-list)))
              (timer-activate timer)))
      (if (loophole-global-editing-p)
          (setq-default loophole--editing-timer
                        (run-with-timer time nil
                                        (lambda ()
                                          (loophole-stop-editing)
                                          (force-mode-line-update t))))
        (setq loophole--editing-timer
              (run-with-timer time nil (lambda (buffer)
                                         (if (buffer-live-p buffer)
                                             (with-current-buffer buffer
                                               (loophole-stop-editing)
                                               (force-mode-line-update))))
                              (current-buffer))))))
  (if (called-interactively-p 'interactive)
      (message "Editing timer is started")))

(defun loophole-stop-editing-timer ()
  "Cancel timer for stopping editing session."
  (interactive)
  (let ((timer (if (loophole-global-editing-p)
                   (default-value 'loophole--editing-timer)
                 loophole--editing-timer)))
    (if (and (timerp timer)
             (not (timer--triggered timer))
             (memq timer timer-list))
        (progn
          (cancel-timer timer)
          (if (called-interactively-p 'interactive)
              (message "Editing timer is stopped")))
      (if (called-interactively-p 'interactive)
          (message "No active editing timer exist")))))

(defun loophole-extend-editing-timer (time)
  "Extend time of editing timer by TIME in second.
If TIME is negative, shorten timer."
  (interactive
   (list (read-number "Time to extend editing timer in sec: "
                      loophole-editing-timer-default-time)))
  (unless (integerp time) (error "Specified time is invalid: %s" time))
  (let ((timer (if (loophole-global-editing-p)
                   (default-value 'loophole--editing-timer)
                 loophole--editing-timer)))
    (if (timerp timer)
        (progn
          (timer-set-time timer (timer-relative-time (timer--time timer) time))
          (if (or (timer--triggered timer)
                  (not (memq timer timer-list)))
              (timer-activate timer)))
      (message "Editing timer does not exist"))))

(defun loophole-describe (map-variable)
  "Display all key bindings in MAP-VARIABLE."
  (interactive (list (loophole-read-map-variable "Describe keymap: ")))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (if (and (version<= "28" emacs-version) loophole-make-describe-use-builtin)
      (describe-keymap map-variable)
    (help-setup-xref `(loophole-describe ,map-variable)
                     (called-interactively-p 'interactive))
    (with-help-window (help-buffer)
      (princ (format "`%s' %sLoophole Map Bindings:\n"
                     map-variable (if (loophole-global-p map-variable)
                                      "Globalized "
                                    "")))
      (terpri)
      (with-current-buffer standard-output
        (save-excursion
          (insert
           (let* ((line-list (split-string (substitute-command-keys
                                            (format "\\{%s}" map-variable))
                                           "\n"))
                  (assoc-list
                   (mapcar
                    (lambda (line)
                      (cons line
                            (let ((keys (replace-regexp-in-string
                                         "^\\(.+?\\)\\(  \\| \\.\\. \\).*"
                                         "\\1"
                                         line)))
                              (if (stringp keys)
                                  (lookup-key
                                   (symbol-value map-variable)
                                   (kbd keys))))))
                    line-list))
                  (expanded-list
                   (mapcar (lambda (assoc)
                             (replace-regexp-in-string
                              "\\(\\(\\?\\?\\)\\|\\(Keyboard Macro\\)\\)$"
                              (let ((entry (cdr assoc)))
                                (cond ((and (fboundp 'kmacro-p)
                                            (kmacro-p entry))
                                       (let ((kmacro
                                              (kmacro-extract-lambda entry)))
                                         (format
                                          "%s"
                                          (cons
                                           (format "[%s]" (key-description
                                                           (car kmacro)))
                                           (cdr kmacro)))))
                                      ((byte-code-function-p entry)
                                       "Byte Code")
                                      ((and (listp entry)
                                            (memq (car entry)
                                                  '(lambda closure)))
                                       (with-temp-buffer
                                         (emacs-lisp-mode)
                                         (pp entry (current-buffer))
                                         (font-lock-ensure)
                                         (let* ((begin (string-match
                                                        "\\s-" (car assoc)))
                                                (end (string-match
                                                      "\\?" (car assoc)))
                                                (prefix (concat
                                                         (make-string
                                                          begin ?\s)
                                                         (substring
                                                          (car assoc)
                                                          begin end))))
                                           (replace-regexp-in-string
                                            "\n\\([^\n]\\)"
                                            (format "\n%s\\1" prefix)
                                            (replace-regexp-in-string
                                             "\n$" "" (buffer-string))))))
                                      ((stringp entry)
                                       (format "\"%s\"" entry))
                                      ((vectorp entry)
                                       (format "[%s]" (key-description entry)))
                                      ((or (numberp entry) (null entry))
                                       "\\1")
                                      (t (format "%s" entry))))
                              (car assoc) t t))
                           assoc-list)))
             (mapconcat #'identity expanded-list "\n")))
          (goto-char 1)
          (re-search-forward "`\\([^`']+\\)'" nil t)
          (help-xref-button 1 'help-variable map-variable))))))

(defun loophole-merge (map-variable merger-map-variable)
  "Merge MAP-VARIABLE to MARGER-MAP-VARIABLE.
A copy of MAP-VARIABLE is made, and each element
of that copy will be embedded into MERGER-MAP-VARIABLE.
Therefore, once merge is completed, keymaps bound to
MAP-VARIABLE and MERGER-MAP-VARIABLE are independent.

Most of copies are inserted to the tail of
MERGER-MAP-VARIABLE.  However, if a certain element is a typical one:
a cons cell of an event and a binding or any variant of it,
and first event of this element exists on
MERGER-MAP-VARIABLE, the element is merged into the element
of MERGER-MAP-VARIABLE.  On merging elements, events of
MERGER-MAP-VARIABLE gets priority to MAP-VARIABLE; i.e.,
events of MAP-VARIABLE will be merged into the element of
MERGER-MAP-VARIABLE, only if that events does not exists on
MERGER-MAP-VARIABLE and not blocked on upstream of
MERGER-MAP-VARIABLE.

After merge is completed, MAP-VARIABLE will be unregistered
from Loophole."
  (interactive
   (let* ((arg-map-variable (loophole-read-map-variable "Merge keymap: "))
          (arg-merger-map-variable
           (loophole-read-map-variable "Merge into keymap: "
                                       (lambda (map-variable)
                                         (not (eq map-variable
                                                  arg-map-variable))))))
     (list arg-map-variable arg-merger-map-variable)))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (unless (loophole-registered-p merger-map-variable)
    (user-error "Specified merger-map-variable %s is not registered"
                merger-map-variable))
  (letrec
      ((trim-existing-on-protected
        (lambda (key-vector element)
          (if (and (listp element)
                   (or (characterp (car element))
                       (symbolp (car element)))
                   (not (eq 'keymap (car element))))
              (let* ((key-sequence (vconcat key-vector (vector (car element))))
                     (protected-keymap
                      (get merger-map-variable :loophole-protected-keymap))
                     (lookup (lookup-key protected-keymap key-sequence)))
                (cond ((keymapp lookup)
                       (if (keymapp (cdr element))
                           (cons (car element)
                                 (cons (cadr element)
                                       (remq nil
                                             (mapcar
                                              (lambda (sub-element)
                                                (funcall
                                                 trim-existing-on-protected
                                                 key-sequence
                                                 sub-element))
                                              (cddr element)))))))
                      ((or (null lookup)
                           (null (loophole--trace-key-to-find-non-keymap-entry
                                  key-sequence protected-keymap)))
                       element)))
            element)))
       (valid-form (loophole--valid-form map-variable)))
    (letrec ((merge-element
              (lambda (element merger-element reversal-key-list)
                (if (and (keymapp (cdr element)) (keymapp (cdr merger-element)))
                    (let ((parent (keymap-parent (cdr element)))
                          (merger-parent (keymap-parent (cdr merger-element))))
                      (set-keymap-parent (cdr element) nil)
                      (set-keymap-parent (cdr merger-element) nil)
                      (unwind-protect
                          (dolist (sub-element (cddr element))
                            (let ((merger-sub-element
                                   (assq (car-safe sub-element)
                                         (cddr merger-element)))
                                  (key
                                   (if (and (listp sub-element)
                                            (or (characterp (car sub-element))
                                                (symbolp (car sub-element)))
                                            (not (eq 'keymap
                                                     (car sub-element))))
                                       (car sub-element))))
                              (if (and key merger-sub-element)
                                  (funcall merge-element
                                           sub-element merger-sub-element
                                           (cons (car sub-element)
                                                 reversal-key-list))
                                (unless (memq sub-element (cddr merger-element))
                                  (let* ((trimmed-sub-element
                                          (funcall
                                           trim-existing-on-protected
                                           (vconcat (reverse reversal-key-list))
                                           sub-element))
                                         (key-vector
                                          (if key
                                              (vconcat
                                               (vector key)
                                               (reverse reversal-key-list))))
                                         (form
                                          (cdr (assoc key-vector valid-form))))
                                    (if trimmed-sub-element
                                        (if (and key-vector form)
                                            (when (equal
                                                   (cdr trimmed-sub-element)
                                                   (cdr sub-element))
                                              (setcdr
                                               (last merger-element)
                                               (cons (cons key (eval form))
                                                     nil))
                                              (put
                                               merger-map-variable
                                               :loophole-form-storage
                                               (cons
                                                (cons key-vector form)
                                                (get merger-map-variable
                                                     :loophole-form-storage))))
                                          (setcdr (last merger-element)
                                                  (cons trimmed-sub-element
                                                        nil)))))))))
                        (set-keymap-parent (cdr merger-element) merger-parent)
                        (set-keymap-parent (cdr element) parent)))))))
      (let* ((map (copy-keymap (symbol-value map-variable)))
             (merger-map (symbol-value merger-map-variable))
             (pseudo-root-element (cons nil map))
             (pseudo-merger-root-element (cons nil merger-map)))
        (funcall merge-element pseudo-root-element
                 pseudo-merger-root-element nil))))
  (let ((protected-keymap (get map-variable :loophole-protected-keymap))
        (valid-form (loophole--valid-form map-variable)))
    (if protected-keymap
        (dolist (protected-element (reverse
                                    (loophole--protected-keymap-entry-list
                                     protected-keymap)))
          (let* ((prefix-key (loophole--protected-keymap-prefix-key
                              protected-element))
                 (entry (lookup-key (car protected-element) prefix-key))
                 (merger-keymap (symbol-value merger-map-variable))
                 (form (cdr (assoc prefix-key valid-form))))
            (when (or (null (lookup-key merger-keymap prefix-key))
                    (null (loophole--trace-key-to-find-non-keymap-entry
                           prefix-key merger-keymap)))
              (loophole--add-protected-keymap-entry
               merger-map-variable prefix-key entry)
              (if form
                  (put merger-map-variable :loophole-form-storage
                       (cons
                        (cons prefix-key form)
                        (get merger-map-variable :loophole-form-storage)))))))))
  (loophole-unregister map-variable t)
  (run-hook-with-args 'loophole-after-merge-functions merger-map-variable))

(defun loophole-duplicate (map-variable &optional map-name tag)
  "Duplicate MAP-VARIABLE.
If optional argument MAP-NAME is given, use it for new map;
otherwise, generate map by `loophole-generate'.
Optional argument TAG specifies tag string for new map, but
if MAP-NAME is nil, TAG will be omitted even with non-nil
value.

When interactive, MAP-NAME and TAG will be asked if called
with any prefix argument."
  (interactive
   (let* ((arg-map-variable (loophole-read-map-variable "Duplicate keymap: "))
          (arg-map-name
           (if current-prefix-arg
               (read-string (format "Name[%stag] for duplicated keymap %s: "
                                    loophole-tag-sign
                                    arg-map-variable))))
          (arg-tag
           (if (stringp arg-map-name)
               (let ((match (string-match loophole-tag-sign arg-map-name)))
                 (if match
                     (prog1
                         (substring arg-map-name
                                    (1+ match)
                                    (length arg-map-name))
                       (setq arg-map-name (substring arg-map-name 0 match)))
                   (read-string (format "Tag for duplicated keymap %s: "
                                        arg-map-variable)))))))
     (list arg-map-variable arg-map-name arg-tag)))
  (unless (loophole-registered-p map-variable)
    (user-error "Specified map-variable %s is not registered" map-variable))
  (if (and (stringp map-name) (not (< 0 (length map-name))))
    (user-error "Name cannot be empty string"))
  (let (duplicated-map-variable)
    (if map-name
        (let* ((map-variable-name (format "loophole-%s-map" map-name))
               (state-variable-name (concat map-variable-name "-state"))
               (tag (or tag (substring map-name 0 1)))
               (duplicated-state-variable (intern state-variable-name)))
          (setq duplicated-map-variable (intern map-variable-name))
          (if (loophole-registered-p duplicated-map-variable)
              (user-error "Specified name %s has already been used" map-name))
          (if (boundp duplicated-map-variable)
              (unless (or loophole-force-overwrite-bound-variable
                          (yes-or-no-p
                           (format "%s has already been bound.  Use it anyway? "
                                   duplicated-map-variable)))
                (user-error "Abort duplicating.  Variable %s is preserved"))
            (put duplicated-map-variable 'variable-documentation
                 "Keymap for temporary use.
Introduced by `loophole-duplicate'."))
          (if (boundp duplicated-state-variable)
              (unless (or loophole-force-overwrite-bound-variable
                          (yes-or-no-p
                           (format "%s has already been bound.  Use it anyway? "
                                   duplicated-state-variable)))
                (user-error "Abort duplicating.  Variable %s is preserved"))
            (put duplicated-state-variable 'variable-documentation
                 (format "State of `%s'.
Introduced by `loophole-duplicate'." duplicated-map-variable)))
          (if (local-variable-if-set-p
               (get map-variable :loophole-state-variable))
              (unless (local-variable-if-set-p duplicated-state-variable)
                (if (or loophole-force-make-variable-buffer-local
                        (yes-or-no-p
                         (format "%s is defined as global.  Make it local? "
                                 duplicated-state-variable)))
                    (make-variable-buffer-local duplicated-state-variable)
                  (user-error (concat "Abort duplicating."
                                      "  Gloabl variable cannot be used"
                                      " for local state-variable"))))
            (if (local-variable-if-set-p duplicated-state-variable)
                (if (or loophole-force-unintern
                        (yes-or-no-p (format
                                      "%s is defined as local.  Unintern it? "
                                      duplicated-state-variable)))
                    (let ((function (symbol-function duplicated-state-variable))
                          (plist (symbol-plist duplicated-state-variable)))
                      (unintern (symbol-name duplicated-state-variable) nil)
                      (setq duplicated-state-variable
                            (intern state-variable-name))
                      (fset duplicated-state-variable function)
                      (setplist duplicated-state-variable plist))
                  (user-error (concat "Abort duplicating."
                                      "  Local variable if set cannot be used"
                                      " for global state-variable")))))
          (set duplicated-map-variable (make-sparse-keymap))
          (set duplicated-state-variable nil)
          (loophole-register duplicated-map-variable duplicated-state-variable
                             tag (loophole-global-p map-variable)))
      (setq duplicated-map-variable (loophole-generate)))
    (let ((valid-form (loophole--valid-form map-variable))
          (parent (keymap-parent (symbol-value map-variable))))
      (set-keymap-parent (symbol-value map-variable) nil)
      (unwind-protect
          (let ((protected-keymap (get map-variable :loophole-protected-keymap))
                (duplicated-keymap (symbol-value duplicated-map-variable)))
            (setcdr duplicated-keymap
                    (cdr (copy-keymap (symbol-value map-variable))))
            (dolist (key-form valid-form)
              (let ((lookup (lookup-key duplicated-keymap (car key-form))))
                (when (and lookup (not (numberp lookup)))
                  (define-key duplicated-keymap (car key-form)
                    (eval (cdr key-form)))
                  (put duplicated-map-variable
                       :loophole-form-storage
                       (cons (cons (car key-form)
                                   (cdr key-form))
                             (get duplicated-map-variable
                                  :loophole-form-storage))))))
            (set-keymap-parent
             duplicated-keymap
             (cond ((or (and protected-keymap
                             (memq protected-keymap parent))
                        (memq loophole-base-map parent))
                    (let ((grand-parent (keymap-parent parent)))
                      (set-keymap-parent parent nil)
                      (unwind-protect
                          (if (and protected-keymap
                                   (memq protected-keymap parent))
                              (make-composed-keymap
                               (remq protected-keymap (cdr parent))
                               grand-parent)
                            (let ((duplicated-parent (copy-sequence parent)))
                              (set-keymap-parent duplicated-parent grand-parent)
                              duplicated-parent))
                        (set-keymap-parent parent grand-parent))))
                   ((and protected-keymap (eq parent protected-keymap)) nil)
                   (t parent)))
            (if protected-keymap
                (dolist (protected-element
                         (reverse (loophole--protected-keymap-entry-list
                                   protected-keymap)))
                  (let* ((prefix-key (loophole--protected-keymap-prefix-key
                                      protected-element))
                         (entry (lookup-key (car protected-element)
                                            prefix-key))
                         (form (cdr (assoc prefix-key valid-form))))
                    (loophole--add-protected-keymap-entry
                     duplicated-map-variable prefix-key entry)
                    (if form
                        (put duplicated-map-variable :loophole-form-storage
                             (cons (cons prefix-key form)
                                   (get duplicated-map-variable
                                        :loophole-form-storage))))))))
          (set-keymap-parent (symbol-value map-variable) parent)))
    (if (called-interactively-p 'interactive)
        (message "%s is duplicated to %s"
                 map-variable duplicated-map-variable))
    (run-hook-with-args 'loophole-after-duplicate-functions
                        map-variable duplicated-map-variable)))

(defun loophole-save (&optional target file)
  "Save Loophole maps to file storage.

By default, normal Loophole maps that look like
loophole-*-map will be saved into
`loophole-default-storage-file'.
Maps who contain object(s) that has no read syntax, e.g.,
buffer, window, frame...  will be omitted.

If an optional argument TARGET is non-nil, saving target is
changed according to the value of TARGET.
When TARGET is a symbol named, named Loophole map, i.e.,
loophole-*-map but not loophole-n-map will be saved.
When TARGET is a symbol all, all registered maps will be
saved.
When TARGET is a function, it will be used as a filter
function who takes one argument, each map-variable of
Loophole maps.
When TARGET is a list, listed map-variables will be saved.
Other than above, falls back on nil.

If an optional argument FILE is non-nil, this function will
save maps into FILE instead of
`loophole-default-storage-file'.

When called interactively with a prefix argument, TARGET and
FILE will be asked."
  (interactive (list (if current-prefix-arg
                         (intern
                          (completing-read "Saving target: " '(named all))))
                     (if current-prefix-arg
                         (read-file-name "Loading file: "))))
  (setq file (or file loophole-default-storage-file))
  (if (file-writable-p file)
      (let* ((target-filter
              (cond ((eq target 'named)
                     (lambda (map-variable)
                       (let ((name (symbol-name map-variable)))
                         (and (string-match "^loophole-.+-map$" name)
                              (not (string-match "^loophole-[0-9]+-map$"
                                                 name))))))
                    ((eq target 'all) (lambda (_) t))
                    ((functionp target) target)
                    ((consp target) (lambda (map-variable)
                                      (memq map-variable target)))
                    (t (lambda (map-variable)
                         (let ((name (symbol-name map-variable)))
                           (string-match "^loophole-.+-map$" name))))))
             (map-variable-list
              (seq-filter target-filter
                          (mapcar (lambda (e)
                                    (get (car e) :loophole-map-variable))
                                  (default-value 'loophole--map-alist))))
             (valid-map-variable-list
              (seq-filter (lambda (map-variable)
                            (with-temp-buffer
                              (save-excursion
                                (prin1 (symbol-value map-variable)
                                       (current-buffer)))
                              (condition-case _e
                                  (progn (read (current-buffer)) t)
                                (invalid-read-syntax
                                 (message (concat
                                           "%s is not saved.  "
                                           "It contains object(s) "
                                           "that has no read syntax.")
                                          map-variable)
                                 nil))))
                          map-variable-list))
             (printed-map-list
              (mapcar
               (lambda (map-variable)
                 (let* ((valid-form (loophole--valid-form map-variable))
                        (protected-keymap
                         (get map-variable :loophole-protected-keymap))
                        (protected-keymap-copy
                         (let ((having-form
                                (apply
                                 #'append
                                 (seq-filter
                                  (lambda (protected-element)
                                    (seq-find
                                     (lambda (key-form)
                                       (eq (lookup-key (cdr protected-element)
                                                       (car key-form))
                                           'undefined))
                                     valid-form))
                                  (loophole--protected-keymap-entry-list
                                   protected-keymap)))))
                           (seq-filter (lambda (element)
                                         (not (memq element having-form)))
                                       protected-keymap))))
                   `(,map-variable
                     ,(let ((keymap (copy-keymap
                                     (symbol-value map-variable))))
                        (set-keymap-parent keymap nil)
                        (dolist (key-form valid-form)
                          (let ((entry (lookup-key
                                        keymap
                                        (car key-form))))
                            (if (and entry (not (numberp entry)))
                                (define-key keymap (car key-form) nil))))
                        keymap)
                     :parent
                     ,(let ((parent (keymap-parent
                                     (symbol-value map-variable))))
                        (cond ((eq parent loophole-base-map)
                               'loophole-base-map)
                              ((and protected-keymap
                                    (eq parent protected-keymap))
                               `(quote ,protected-keymap-copy))
                              ((or (memq loophole-base-map parent)
                                   (and protected-keymap
                                        (memq protected-keymap parent)))
                               (let* ((copy (copy-sequence parent))
                                      (protected-cell
                                       (and protected-keymap
                                            (memq protected-keymap copy))))
                                 (if protected-cell
                                     (setcar protected-cell
                                             protected-keymap-copy))
                                 (if (memq loophole-base-map parent)
                                     (let ((grand-parent
                                            (keymap-parent copy)))
                                       (set-keymap-parent copy nil)
                                       (let ((others (remq loophole-base-map
                                                           (cdr copy))))
                                         `(make-composed-keymap
                                           (append (quote ,others)
                                                   (list loophole-base-map))
                                           (quote ,grand-parent))))
                                   `(quote ,copy))))
                              (t `(quote ,parent))))
                     :documentation ,(get map-variable
                                          'variable-documentation)
                     :state-variable ,(get map-variable
                                           :loophole-state-variable)
                     :state-variable-documentation
                     ,(get (get map-variable :loophole-state-variable)
                           'variable-documentation)
                     :tag ,(get map-variable :loophole-tag)
                     :global ,(not (local-variable-if-set-p
                                    (get map-variable
                                         :loophole-state-variable)))
                     :protected-keymap ,protected-keymap-copy
                     :form-storage ,valid-form)))
                      valid-map-variable-list)))
        (with-temp-file file
          (insert (format ";;; -*- mode: %s -*-\n\n"
                          (if (version< emacs-version "28")
                              'emacs-lisp
                            'lisp-data)))
          (pp printed-map-list (current-buffer))))
    (message "File storage is not writable: %s" file)))

(defun loophole-load (&optional target file)
  "Load Loophole maps from file storage.

By default, normal saved maps that look like
loophole-*-map will be loaded from
`loophole-default-storage-file'.
If read maps from file storage have already been bound or
registered, this function asks user to overwrite it.
`loophole-make-load-overwrite-map' specifies maps which will
be overwritten without asking.

If an optional argument TARGET is non-nil, loading target is
changed according to the value of TARGET.
When TARGET is a symbol named,  named Loophole map, i.e.,
loophole-*-map but not loophole-n-map will be loaded.
When TARGET is a symbol all, all registered maps will be
loaded.
When TARGET is a function, it will be used as a filter
function who takes one argument, each map-variable of
saved maps.
Other than above, falls back on nil.

If an optional argument FILE is non-nil, this function load
maps from FILE instead of `loophole-default-storage-file'.

When called interactively with a prefix argument, TARGET and
FILE will be asked."
  (interactive (list (if current-prefix-arg
                         (intern
                          (completing-read "Loading target: " '(named all))))
                     (if current-prefix-arg
                         (read-file-name "Loading file: "))))
  (setq file (or file loophole-default-storage-file))
  (if (file-readable-p file)
      (let* ((target-filter
              (cond ((eq target 'named)
                     (lambda (map)
                       (let ((name (symbol-name (car map))))
                         (and (string-match "^loophole-.+-map$" name)
                              (not (string-match "^loophole-[0-9]+-map$"
                                                 name))))))
                    ((eq target 'all) (lambda (_) t))
                    ((functionp target) target)
                    (t (lambda (map)
                         (let ((name (symbol-name (car map))))
                           (string-match "^loophole-.+-map$" name))))))
             (read-map-list
              (with-temp-buffer
                (insert-file-contents file)
                (read (current-buffer))))
             (map-list (seq-filter target-filter read-map-list)))
        (dolist (map (reverse map-list))
          (let* ((map-variable (car map))
                 (keymap (cadr map))
                 (plist (cddr map))
                 (parent (eval (plist-get plist :parent)))
                 (documentation (plist-get plist :documentation))
                 (state-variable (plist-get plist :state-variable))
                 (state-variable-documentation
                  (plist-get plist :state-variable-documentation))
                 (tag (plist-get plist :tag))
                 (global (plist-get plist :global))
                 (protected-keymap (plist-get plist :protected-keymap))
                 (form-storage (plist-get plist :form-storage)))
            (when (or (and (not (loophole-registered-p map-variable))
                           (not (boundp map-variable))
                           (not (boundp state-variable)))
                      (cond ((eq loophole-make-load-overwrite-map 'all))
                            ((eq loophole-make-load-overwrite-map 'temporary)
                             (string-match "^loophole-[0-9]+-map$"
                                           (symbol-name map-variable)))
                            ((functionp loophole-make-load-overwrite-map)
                             (funcall loophole-make-load-overwrite-map
                                      map-variable))
                            (loophole-make-load-overwrite-map
                             (string-match "^loophole-.+-map$"
                                           (symbol-name map-variable))))
                      (yes-or-no-p
                       (format
                        (concat "%s has already been bound or registered.  "
                                "Overwrite it? ")
                        map-variable)))
              (if (loophole-registered-p map-variable)
                  (loophole-unregister map-variable t))
              (set map-variable keymap)
              (put map-variable 'variable-documentation documentation)
              (set-keymap-parent keymap parent)
              (set state-variable nil)
              (put state-variable 'variable-documentation
                   state-variable-documentation)
              (put map-variable :loophole-protected-keymap protected-keymap)
              (loophole-register map-variable state-variable tag global t)
              (dolist (key-form form-storage)
                (loophole-bind-entry (car key-form) (eval (cdr key-form))
                                     keymap))
              (put map-variable :loophole-form-storage form-storage)))))
    (message "File storage is not readable: %s" file)))

;;; Binding utilities

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

(defun loophole-read-key-for-kmacro-by-read-key (prompt)
  "`loophole-read-key' with checking finish and quit key.
PROMPT is a string for reading key."
  (declare (obsolete nil "0.8.2"))
  (let ((finish (vconcat loophole-kmacro-by-read-key-finish-key))
        (quit (vconcat (where-is-internal 'keyboard-quit nil t))))
    (or (not (zerop (length finish)))
        (not (zerop (length quit)))
        (user-error "Neither finishing key nor quitting key is invalid")))
  (loophole-read-key prompt))

(defun loophole-read-key-for-array-by-read-key (prompt)
  "`loophole-read-key' with checking finish and quit key.
PROMPT is a string for reading key."
  (declare (obsolete nil "0.8.2"))
  (let ((finish (vconcat loophole-array-by-read-key-finish-key))
        (quit (vconcat (where-is-internal 'keyboard-quit nil t))))
    (or (not (zerop (length finish)))
        (not (zerop (length quit)))
        (user-error "Neither finishing key nor quitting key is invalid")))
  (loophole-read-key prompt))

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
      (when (or (null loophole-decide-obtaining-method-after-read-key)
                (and (eq loophole-decide-obtaining-method-after-read-key
                         'negative-argument)
                     (not (< n 0))))
        (setq obtaining-method-spec (funcall decide-obtaining-method n))
        (setq read-key-function
              (funcall get-read-key-function obtaining-method-spec))
        (setq obtain-entry-function
              (funcall get-obtain-entry-function obtaining-method-spec))
        (setq obtain-keymap-function
              (unless without-keymap
                (funcall get-obtain-keymap-function obtaining-method-spec))))
      (save-current-buffer
        (let ((arg-key
               (funcall (or read-key-function #'loophole-read-key)
                        "Set key temporarily: ")))
          (unless (or (null loophole-decide-obtaining-method-after-read-key)
                      (and (eq loophole-decide-obtaining-method-after-read-key
                               'negative-argument)
                           (not (< n 0))))
            (setq obtaining-method-spec (funcall decide-obtaining-method n))
            (setq obtain-entry-function
                  (funcall get-obtain-entry-function obtaining-method-spec))
            (setq obtain-keymap-function
                  (unless without-keymap
                    (funcall get-obtain-keymap-function
                             obtaining-method-spec))))
          (let* ((arg-keymap
                  (if (and (not without-keymap) obtain-keymap-function)
                      (funcall obtain-keymap-function arg-key)))
                 (arg-entry
                  (if arg-keymap
                      (funcall obtain-entry-function arg-key arg-keymap)
                    (funcall obtain-entry-function arg-key))))
            (if without-keymap
                (list arg-key arg-entry)
              (list arg-key arg-entry arg-keymap))))))))

;;; Obtaining methods

(defun loophole-obtain-object (key &optional _keymap)
  "Return any Lisp object.
Object is obtained as return value of `eval-minibuffer'.
Read minibuffer with prompt in which KEY is embedded."
  (eval-minibuffer (format "Set key %s to entry: " (key-description key))))

(defun loophole-obtain-command-by-read-command (key &optional _keymap)
  "Return command obtained by reading command symbol.
Read command with prompt in which KEY is embedded."
  (read-command (format "Set key %s to command: " (key-description key))))

(defun loophole-obtain-command-by-key-sequence (key &optional _keymap)
  "Return command obtained by key sequence lookup.
Read key sequence with prompt in which KEY is embedded."
  (let ((binding (key-binding (loophole-read-key
                               (format
                                "Set key %s to command bound for: "
                                (key-description key)))
                              t)))
    (message "%s" binding)
    binding))

(defun loophole-obtain-command-by-lambda-form (key &optional keymap)
  "Return command obtained by writing lambda form.
This function provides work space for writing lambda form as
a temporary buffer.
The first form of the buffer is read, and if it is a valid
lambda form, this function returns it.
Note that this function just read the buffer and does not
evaluate the form.

Because this function uses `loophole-read-buffer' to give
user a workspace, if user option
`loophole-read-buffer-inhibit-recursive-edit' is non-nil,
a binding command who calls this function is quit, and
workspace is remained with transient local binidngs whose
entry binds KEY and obtained lambda form.
If optional argument KEYMAP is non-nil, they are bound on
KEYMAP."
  (let ((binding-buffer (current-buffer))
        (writing-buffer (get-buffer-create "*Loophole*")))
    (with-current-buffer writing-buffer
      (erase-buffer)
      (insert ";; For obtaining lambda form.\n\n")
      (insert loophole-command-by-lambda-form-format)
      (if (search-backward "(#)" nil t) (delete-region (point) (+ (point) 3)))
      (setq buffer-undo-list nil)
      (deactivate-mark t))
    (let* ((test-and-return
            (lambda (form)
              (if (and (commandp form)
                       (listp form)
                       (eq (car form) 'lambda))
                  form
                (user-error
                 "Obtained Lisp object is not valid lambda command: %s" form))))
           (test-and-bind
            (lambda (form)
              (if (buffer-live-p binding-buffer)
                  (with-current-buffer binding-buffer
                    (loophole-bind-entry key (funcall test-and-return form)
                                         (if keymap
                                             keymap
                                           (loophole-ready-map))))
                (user-error
                 (concat "Lambda form is not bound "
                         "because the anchored buffer is not alive"))))))
      (funcall test-and-return (loophole-read-buffer test-and-bind
                                                     writing-buffer)))))

(defun loophole-obtain-kmacro-by-read-key (key &optional _keymap)
  "Return kmacro obtained by reading key.
This function uses `loophole-read-key-until-termination-key'
to define kmacro.  Read keys until
`loophole-read-key-termination-key' will be kmacro.

By default, `loophole-read-key-termination-key' is \\[keyboard-quit]
the key bound to `keyboard-quit'.  In this situation, you
cannot use \\[keyboard-quit] for quitting.
Once `loophole-read-key-termination-key' is changed, and
user option `loophole-allow-keyboard-quit' is non-nil,
\\[keyboard-quit] takes effect as quit.

KEY which is about to be bound is embedded in prompt string."
  (let ((macro (loophole-read-key-until-termination-key
                (format "Set key %s to kmacro: " (key-description key)))))
    (kmacro-start-macro nil)
    (end-kbd-macro nil #'kmacro-loop-setup-function)
    (setq last-kbd-macro macro)
    (kmacro-lambda-form (kmacro-ring-head))))

(defun loophole-obtain-kmacro-by-recursive-edit (_key &optional _keymap)
  "Return kmacro obtained by recursive edit.
\\<loophole-mode-map>
This function starts recursive edit in order to offer
keyboard macro defining work space.  Definition can be
finished by calling `loophole-end-kmacro' which is bound to
\\[loophole-end-kmacro].
Besides, Definition can be aborted by calling
`loophole-abort-kmacro' which is bound to \\[loophole-abort-kmacro].
\\<loophole-defining-kmacro-map>
If `loophole-defining-kmacro-map-flag' is non-nil,
special keymap `loophole-defining-kmacro-map' is
enabled only during recursive edit.
Actually, `loophole-defining-kmacro-map' is
registered to Loophole as a gloabl map, and unregistered
after recursive edit is ended.
In this case, `loophole-end-kmacro' is bound to \\[loophole-end-kmacro].
and `loophole-abort-kmacro' is bound to \\[loophole-abort-kmacro]."
  (loophole-register 'loophole-defining-kmacro-map
                     'loophole-defining-kmacro-map-flag
                      loophole-defining-kmacro-map-tag
                      t)
  (unwind-protect
      (loophole-start-kmacro)
    (loophole-unregister 'loophole-defining-kmacro-map))
  (kmacro-lambda-form (kmacro-ring-head)))

(defun loophole-obtain-kmacro-on-top-level (key &optional keymap)
  "Exit binidng command once and bind kmacro after defining it.
Be careful to use this method, because this function does
not return value but emit signal and exit binding command
to avoid using `recursive-edit'.
This method is a counterpart of
`loophole-obtain-kmacro-by-recursive-edit'.
\\<loophole-mode-map>
When this method is invoked, keyboard macro defining session
is activated, and binidng command is exited, then controll
is completely returned to user.  User can define keyboard
macro in ordinary environment.
Definition can be finished by calling
`loophole-end-kmacro' which is bound to \\[loophole-end-kmacro],
then defined keyboard macro is bound to KEY.
Besides, Definition can be aborted by calling
`loophole-abort-kmacro' which is bound to \\[loophole-abort-kmacro],
or more simply, `keyboard-quit' (\\[keyboard-quit]) abort definition
properly.
\\<loophole-defining-kmacro-map>
If `loophole-defining-kmacro-map-flag' is non-nil,
special keymap `loophole-defining-kmacro-map' is
enabled only during keyboard macro defining session.
Actually, `loophole-defining-kmacro-map' is
registered to Loophole as a gloabl map, and unregistered
after defining session is ended.
In this case, `loophole-end-kmacro' is bound to \\[loophole-end-kmacro].
and `loophole-abort-kmacro' is bound to \\[loophole-abort-kmacro].

If optional argument KEYMAP is non-nil, KEY and keyboard
macro are bound on KEYMAP."
  (let* ((end (make-symbol "loophole-kmacro-on-top-level-end"))
         (abort (make-symbol "loophole-kmacro-on-top-level-abort"))
         (clean (lambda ()
                  (advice-remove 'loophole-end-kmacro end)
                  (advice-remove 'loophole-abort-kmacro abort)
                  (if (loophole-registered-p
                       'loophole-defining-kmacro-map)
                      (loophole-unregister
                       'loophole-defining-kmacro-map))))
         (buffer (current-buffer)))
    (fset end (lambda ()
                (interactive)
                (unwind-protect
                    (when defining-kbd-macro
                      (kmacro-end-macro nil)
                      (if (buffer-live-p buffer)
                          (with-current-buffer buffer
                            (loophole-bind-entry
                             key
                             (kmacro-lambda-form (kmacro-ring-head))
                             keymap))
                        (user-error
                         (concat "Kmacro is not bound "
                                 "because the anchored buffer is not alive"))))
                  (funcall clean))))
    (fset abort (lambda ()
                  (interactive)
                  (unwind-protect
                      (if defining-kbd-macro (keyboard-quit))
                    (funcall clean))))
    (loophole-register 'loophole-defining-kmacro-map
                       'loophole-defining-kmacro-map-flag
                       loophole-defining-kmacro-map-tag
                       t)
    (advice-add 'loophole-end-kmacro :override end)
    (advice-add 'loophole-abort-kmacro :override abort)
    (let ((setup (make-symbol "loophole-one-time-hook-function"))
          (follow (make-symbol "loophole-transient-hook-function")))
      (fset setup (lambda ()
                    (unwind-protect
                        (funcall-interactively #'loophole-start-kmacro)
                      (add-hook 'post-command-hook follow)
                      (remove-hook 'post-command-hook setup))))
      (fset follow (lambda ()
                     (unless defining-kbd-macro
                       (unwind-protect
                           (funcall clean)
                         (remove-hook 'post-command-hook follow)))))
      (add-hook 'post-command-hook setup))
    (signal 'quit nil)))

(defun loophole-obtain-kmacro-by-recall-record (key &optional _keymap)
  "Return kmacro obtained by recalling record.
Completing read record with prompt in which KEY is embedded."
  (unless (featurep 'kmacro)
    (user-error "Record is void, kmacro has not been loaded"))
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

(defun loophole-obtain-array-by-read-key (key &optional _keymap)
  "Return array obtained by reading key.
This function uses `loophole-read-key-until-termination-key'
to define kbd macro denoted by array.  Read keys until
`loophole-read-key-termination-key' will be kbd macro.

By default, `loophole-read-key-termination-key' is \\[keyboard-quit]
the key bound to `keyboard-quit'.  In this situation, you
cannot use \\[keyboard-quit] for quitting.
Once `loophole-read-key-termination-key' is changed, and
user option `loophole-allow-keyboard-quit' is non-nil,
\\[keyboard-quit] takes effect as quit.

KEY which is about to be bound is embedded in prompt string."
  (loophole-read-key-until-termination-key
   (format "Set key %s to array: " (key-description key))))

(defun loophole-obtain-array-by-read-string (key &optional _keymap)
  "Return array obtained by `read-string'.
Read string with prompt in which KEY is embedded ."
  (read-string (format "Set key %s to array: " (key-description key))))

(defun loophole-obtain-keymap-by-read-keymap-variable (key &optional _keymap)
  "Return keymap obtained by reading keymap variable.
Read keymap variable with prompt in which KEY is embedded."
  (let ((variable (intern
                   (completing-read (format
                                     "Set key %s to keymap bound to symbol: "
                                     (key-description key))
                                    obarray
                                    (lambda (s)
                                      (and (boundp s)
                                           (not (keywordp s))
                                           (keymapp (symbol-value s))))
                                    t))))
    (loophole-toss-binding-form key variable)
    (symbol-value variable)))

(defun loophole-obtain-keymap-by-read-keymap-function (key &optional _keymap)
  "Return keymap obtained by reading keymap function.
Read keymap function with prompt in which KEY is embedded.
Keymap function is a symbol whose function cell is a keymap
or a symbol whose function cell is ultimately a keymap."
  (let ((symbol (intern
                 (completing-read
                  (format "Set key %s to keymap fbound to symbol: "
                          (key-description key))
                  obarray
                  (lambda (s)
                    (let ((f (loophole--symbol-function-recursively s)))
                      (and (not (symbolp f)) (keymapp f))))
                  t))))
    (loophole-toss-binding-form key `(loophole--symbol-function-recursively
                                      ',symbol))
    (loophole--symbol-function-recursively symbol)))

(defun loophole-obtain-symbol-by-read-keymap-function (key &optional _keymap)
  "Return symbol obtained by reading keymap function.
Read keymap function with prompt in which KEY is embedded.
Keymap function is a symbol whose function cell is a keymap
or a symbol whose function cell is ultimately a keymap."
  (intern (completing-read
           (format "Set key %s to symbol whose function cell is keymap: "
                   (key-description key))
           obarray
           (lambda (s)
             (let ((f (loophole--symbol-function-recursively s)))
               (and (not (symbolp f)) (keymapp f))))
           t)))

(defun loophole-obtain-symbol-by-read-command (key &optional _keymap)
  "Return symbol obtained by reading command symbol.
Read command with prompt in which KEY is embedded."
  (read-command
   (format "Set key %s to symbol whose function cell is command: "
           (key-description key))))

(defun loophole-obtain-symbol-by-read-array-function (key &optional _keymap)
  "Return symbol obtained by reading array function.
Read array function with prompt in which KEY is embedded.
Array function is a symbol whose function cell is an array
or a symbol whose function cell is ultimately an array."
  (intern (completing-read
           (format "Set key %s to symbol whose function cell is array: "
                   (key-description key))
           obarray
           (lambda (s)
             (let ((f (loophole--symbol-function-recursively s)))
               (or (vectorp f) (stringp f))))
           t)))

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

If ENTRY is a keymap object or a symbol whose function cell
is a keymap object, this function checks a value of
`loophole-protect-keymap-entry'.  If the value is non-nil,
KEY and ENTRY is bound in a parent map to protect bound
ENTRY.  Protected entries act as well as ordinary entries
but they will never been overwritten.
When some other new bindings shades protected bindings,
they will be removed.

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
affects the timing of this `completing-read'.

Return map-variable on which KEY and ENTRY are bound."
  (interactive
   (loophole--arg-list loophole-bind-entry-order current-prefix-arg))
  (or (vectorp key) (stringp key)
      (signal 'wrong-type-argument (list 'arrayp key)))
  (setq keymap
        (if keymap
            (let ((map-variable (loophole-map-variable-for-keymap keymap)))
              (if (and map-variable
                       (loophole-registered-p map-variable))
                  keymap
                (user-error "Invalid keymap: %s" keymap)))
          (loophole-ready-map)))
  (let ((map-variable (loophole-map-variable-for-keymap keymap)))
    (if (and (keymapp entry) loophole-protect-keymap-entry)
        (loophole--add-protected-keymap-entry map-variable key entry)
      (loophole--set-ordinary-entry map-variable key entry))
    (run-hooks 'loophole-bind-hook)
    map-variable))

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
affects the timing of this `completing-read'.

Return map-variable on which KEY and COMMAND are bound."
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
affects the timing of this `completing-read'.

Return map-variable on which KEY and KMACRO are bound."
  (interactive
   (loophole--arg-list loophole-bind-kmacro-order current-prefix-arg))
  (unless (featurep 'kmacro)
    (user-error
     "Specified object cannot be valid kmacro, feature has not been loaded"))
  (if (kmacro-p kmacro)
      (loophole-bind-entry key kmacro keymap)
    (user-error "Invalid kmacro: %s" kmacro)))

;;;###autoload
(defun loophole-bind-last-kmacro (key)
  "Bind KEY to the lastly accessed keyboard macro.
Currently editing keymap or generated new one is used for
binding.

Return map-variable on which KEY is bound."
  (interactive (list (loophole-read-key "Set key temporarily: ")))
  (unless (featurep 'kmacro)
    (user-error "Last kmacro is void, kmacro has not been loaded"))
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
affects the timing of this `completing-read'.

Return map-variable on which KEY and ARRAY are bound."
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
affects the timing of this `completing-read'.

Return map-variable on which KEY and KEYMAP are bound."
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
affects the timing of this `completing-read'.

Return map-variable on which KEY and SYMBOL are bound."
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
  (loophole-bind-entry key entry)
  entry)

(defun loophole-unset-key (key)
  "Unset the temporary binding of KEY of `loophole-editing'.
When called interactively, KEY will be read by
`loophole-read-key'.  If called with prefix argument, KEY
will be read by `loophole-alternative-read-key-function'
whose default value is `loophole-read-key-with-time-limit'.
By using `loophole-read-key-with-time-limit', prefix key as
well as ordinary binding can be unset."
  (interactive (if (loophole-editing)
                   (list (funcall
                          (if current-prefix-arg
                              loophole-alternative-read-key-function
                            #'loophole-read-key)
                          "Unset temporarily set key: "))
                 (user-error "There is no editing map")))
  (let ((map (symbol-value (loophole-editing))))
    (when map
      (loophole-bind-entry key nil map)
      (if (called-interactively-p 'interactive)
          (message "Key %s is unset" (key-description key)))
      nil)))

(defun loophole-key-binding (keys &optional accept-default)
  "Return the binding for KEYS in currently active Loophole maps.
KEYS should be a string or vector which represents key
sequence.
Optional argument ACCEPT-DEFAULT has same meaning as
`lookup-key'.  When non-nil, default binidngs are also
looked up."
  (lookup-key (make-composed-keymap
               (mapcar #'cdr
                       (seq-filter (lambda (state-map)
                                     (symbol-value (car state-map)))
                                   loophole--map-alist)))
              keys
              accept-default))

(defun loophole-reset-key (key new-key)
  "Reset the binding for KEY of `loophole-editing' with NEW-KEY.
Actually, new binding for NEW-KEY is set and KEY will be
unset.
When called interactively, KEY and NEW-KEY will be read by
`loophole-read-key'.  If called with prefix argument, KEY
and NEW-KEY will be read by
`loophole-alternative-read-key-function' whose default value
is `loophole-read-key-with-time-limit'.
By using `loophole-read-key-with-time-limit', prefix key as
well as ordinary binding can be reset."
  (interactive (if (loophole-editing)
                   (let ((old-key (funcall
                                   (if current-prefix-arg
                                       loophole-alternative-read-key-function
                                     #'loophole-read-key)
                                   "Reset temporarily set key: ")))
                     (list old-key
                           (funcall
                            (if current-prefix-arg
                                #'loophole-read-key-with-time-limit
                              #'loophole-read-key)
                            (format "New key for %s: "
                                    (key-description old-key)))))
                 (user-error "There is no editing map")))
  (let* ((map (symbol-value (loophole-editing)))
         (entry (lookup-key map key)))
    (when (and map entry (not (numberp entry)))
      (loophole-bind-entry new-key entry map)
      (loophole-bind-entry key nil map)
      (if (called-interactively-p 'interactive)
          (message "Key %s is reset to %s"
                   (key-description key)
                   (key-description new-key)))
      entry)))

;;; Entry modifiers

(defun loophole-modify-lambda-form (key &optional map-variable)
  "Modify lambda form bound to KEY in editing keymap.
If MAP-VARIABLE is non-nil, that is looked up instead of
editing keymap.

This function print bound lambda form to temporary buffer,
and read it back when modifying is finished.
This function does not evaluate the form but just read it.
If temporary buffer contains multiple forms when finished,
the first one will be read.

Because this function uses `loophole-read-buffer' to give
user a workspace, if user option
`loophole-read-buffer-inhibit-recursive-edit' is non-nil,
this command is quit, and temporary buffer is remained with
transient local binidngs whose entry binds KEY and modified
lambda form."
  (interactive (if (or current-prefix-arg (loophole-editing) )
                   (list (loophole-read-key "Modify lambda form for key: ")
                         (if current-prefix-arg
                             (loophole-read-map-variable "Lookup: ")))
                 (user-error "There is no editing map")))
  (if map-variable
      (unless (loophole-registered-p map-variable)
        (user-error "Specified map-variable %s is not registered" map-variable))
    (setq map-variable (loophole-editing)))
  (let ((entry (lookup-key (symbol-value map-variable) key))
        (buffer (get-buffer-create "*Loophole*")))
    (cond ((or (null entry) (numberp entry))
           (user-error "No entry found in loophole map: %s" map-variable))
          ((not (and (commandp entry)
                     (listp entry)
                     (eq (car entry) 'lambda)))
           (user-error "Bound entry is not lambda form: %s" entry)))
    (with-current-buffer buffer
      (erase-buffer)
      (insert ";; For modifying lambda form.\n\n")
      (pp entry (current-buffer))
      (setq buffer-undo-list nil)
      (deactivate-mark t))
    (let ((test-and-bind
           (lambda (form)
             (if (and (commandp form)
                      (listp form)
                      (eq (car form) 'lambda))
                 (loophole-bind-entry key form (symbol-value map-variable))
               (user-error
                "Modified Lisp object is not valid lambda command: %s"
                form)))))
      (funcall test-and-bind (loophole-read-buffer test-and-bind buffer)))))

(defun loophole-modify-kmacro (key &optional map-variable)
  "Modify kmacro bound to KEY in editing keymap.
If MAP-VARIABLE is non-nil, that is looked up instead of
editing keymap.

This function print bound kmacro to temporary buffer, and
read it back when modifying is finished.
Although kmacro object is a lambda form when bound to key,
extracted raw form will be printed.
Raw form of kmacro consists of basic keyboard macro which is
a string or a vector, counter integer, and counter format.

If temporary buffer contains multiple forms when finished,
the first one will be read.

Because this function uses `loophole-read-buffer' to give
user a workspace, if user option
`loophole-read-buffer-inhibit-recursive-edit' is non-nil,
this command is quit, and temporary buffer is remained with
transient local binidngs whose entry binds KEY and modified
lambda form."
  (interactive (if (or current-prefix-arg (loophole-editing) )
                   (list (loophole-read-key "Modify kmacro for key: ")
                         (if current-prefix-arg
                             (loophole-read-map-variable "Lookup: ")))
                 (user-error "There is no editing map")))
  (if map-variable
      (unless (loophole-registered-p map-variable)
        (user-error "Specified map-variable %s is not registered" map-variable))
    (setq map-variable (loophole-editing)))
  (let ((entry (lookup-key (symbol-value map-variable) key))
        (buffer (get-buffer-create "*Loophole*")))
    (unless (featurep 'kmacro)
      (user-error "Bound entry cannot be kmacro, feature has not been loaded"))
    (cond ((or (null entry) (numberp entry))
           (user-error "No entry found in loophole map: %s" map-variable))
          ((not (kmacro-p entry))
           (user-error "Bound entry is not kmacro: %s" entry)))
    (with-current-buffer buffer
      (erase-buffer)
      (insert ";; For modifying kmacro.\n\n")
      (let ((extracted (kmacro-extract-lambda entry)))
        (insert ";; Format: ([KEYS OF KMACRO]\n")
        (insert ";;          COUNTER \"COUNTER-FORMAT\")\n")
        (insert ";; Key description: " (key-description (car extracted)) "\n")
        (if loophole-print-event-in-char-read-syntax
            (insert "(["
                    (mapconcat #'loophole--char-read-syntax (car extracted) " ")
                    "]\n "
                    (substring (prin1-to-string (cdr extracted)) 1)
                    "\n")
          (pp extracted (current-buffer))))
      (setq buffer-undo-list nil)
      (deactivate-mark t))
    (let ((test-and-bind
           (lambda (form)
             (let ((kmacro (kmacro-lambda-form form)))
               (if (kmacro-p kmacro)
                   (loophole-bind-entry key kmacro
                                        (symbol-value map-variable))
                 (user-error "Modified Lisp object is not kmacro: %s"
                             kmacro))))))
      (funcall test-and-bind (loophole-read-buffer test-and-bind buffer)))))

(defun loophole-modify-array (key &optional map-variable)
  "Modify array bound to KEY in editing keymap.
If MAP-VARIABLE is non-nil, that is looked up instead of
editing keymap.

This function print bound array to temporary buffer, and
read it back when modifying is finished.
This function does not evaluate the form but just read it.
If temporary buffer contains multiple forms when finished,
the first one will be read.

Because this function uses `loophole-read-buffer' to give
user a workspace, if user option
`loophole-read-buffer-inhibit-recursive-edit' is non-nil,
this command is quit, and temporary buffer is remained with
transient local binidngs whose entry binds KEY and modified
lambda form."
  (interactive (if (or current-prefix-arg (loophole-editing) )
                   (list (loophole-read-key "Modify array for key: ")
                         (if current-prefix-arg
                             (loophole-read-map-variable "Lookup: ")))
                 (user-error "There is no editing map")))
  (if map-variable
      (unless (loophole-registered-p map-variable)
        (user-error "Specified map-variable %s is not registered" map-variable))
    (setq map-variable (loophole-editing)))
  (let ((entry (lookup-key (symbol-value map-variable) key))
        (buffer (get-buffer-create "*Loophole*")))
    (cond ((or (null entry) (numberp entry))
           (user-error "No entry found in loophole map: %s" map-variable))
          ((not (or (vectorp entry) (stringp entry)))
           (user-error "Bound entry is not array: %s" entry)))
    (with-current-buffer buffer
      (erase-buffer)
      (insert ";; For modifying array.\n\n")
      (insert ";; Format: [KEYS OF KBD MACRO]\n")
      (insert ";; Key description: " (key-description entry) "\n")
      (if loophole-print-event-in-char-read-syntax
          (insert "[" (mapconcat #'loophole--char-read-syntax entry " ") "]\n")
        (pp entry (current-buffer)))
      (setq buffer-undo-list nil)
      (deactivate-mark t))
    (let ((test-and-bind (lambda (form)
                           (if (or (vectorp form) (stringp form))
                               (loophole-bind-entry
                                key form (symbol-value map-variable))
                             (user-error
                              "Modified Lisp object is not array: %s"
                              form)))))
      (funcall test-and-bind (loophole-read-buffer test-and-bind buffer)))))

(defun loophole-modify-entry (key &optional map-variable)
  "Modify entry bound to KEY in editing keymap.
If MAP-VARIABLE is non-nil, that is looked up instead of
editing keymap.

This function checks entry bound to KEY and call proper
function to modify it."
  (interactive (if (or current-prefix-arg (loophole-editing) )
                   (list (loophole-read-key "Modify entry for key: ")
                         (if current-prefix-arg
                             (loophole-read-map-variable "Lookup: ")))
                 (user-error "There is no editing map")))
  (if map-variable
      (unless (loophole-registered-p map-variable)
        (user-error "Specified map-variable %s is not registered" map-variable))
    (setq map-variable (loophole-editing)))
  (let ((entry (lookup-key (symbol-value map-variable) key)))
    (cond ((or (null entry) (numberp entry))
           (user-error "No entry found in loophole map: %s" map-variable))
          ((kmacro-p entry) (loophole-modify-kmacro key map-variable))
          ((and (commandp entry) (listp entry) (eq (car entry) 'lambda))
           (loophole-modify-lambda-form key map-variable))
          ((or (vectorp entry) (stringp entry))
           (loophole-modify-array key map-variable))
          (t (message "%s is bound to unmodifiable entry: %s" key entry)))))

;;; Base control

(defun loophole-suspend ()
  "Suspend Loophole.
To suspend Loophole, this function delete
`loophole--map-alist' from `emulation-mode-map-alists'."
  (interactive)
  (setq emulation-mode-map-alists
        (delq 'loophole--map-alist emulation-mode-map-alists))
  (setq loophole--suspended t))

;;;###autoload
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
  (dolist (buffer (loophole-buffer-list))
    (with-current-buffer buffer
      (loophole-disable-all)
      (loophole-stop-editing)))
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
  :global t
  :lighter loophole-mode-lighter
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map "\C-c[" #'loophole-set-key)
            (define-key map "\C-c\\" #'loophole-disable-latest)
            (define-key map "\C-c]{" #'loophole-register)
            (define-key map "\C-c]}" #'loophole-unregister)
            (define-key map "\C-c]^" #'loophole-prioritize)
            (define-key map "\C-c]>" #'loophole-globalize)
            (define-key map "\C-c]<" #'loophole-localize)
            (define-key map "\C-c][" #'loophole-start-editing)
            (define-key map "\C-c]]" #'loophole-stop-editing)
            (define-key map "\C-c]-" #'loophole-globalize-editing)
            (define-key map "\C-c]=" #'loophole-localize-editing)
            (define-key map "\C-c];" #'loophole-name)
            (define-key map "\C-c]#" #'loophole-tag)
            (define-key map "\C-c]/" #'loophole-describe)
            (define-key map "\C-c]," #'loophole-suspend)
            (define-key map "\C-c]." #'loophole-resume)
            (define-key map "\C-c]q" #'loophole-quit)
            (define-key map "\C-c]p" #'loophole-prioritize)
            (define-key map "\C-c]n" #'loophole-name)
            (define-key map "\C-c]h" #'loophole-describe)
            (define-key map "\C-c]s" #'loophole-set-key)
            (define-key map "\C-c]u" #'loophole-unset-key)
            (define-key map "\C-c]r" #'loophole-reset-key)
            (define-key map "\C-c]e" #'loophole-enable)
            (define-key map "\C-c]d" #'loophole-disable)
            (define-key map "\C-c]D" #'loophole-disable-all)
            (define-key map "\C-c]cd" #'loophole-duplicate)
            (define-key map "\C-c]cm" #'loophole-merge)
            (define-key map "\C-c]t[" #'loophole-start-timer)
            (define-key map "\C-c]t]" #'loophole-stop-timer)
            (define-key map "\C-c]t+" #'loophole-extend-timer)
            (define-key map "\C-c]te[" #'loophole-start-editing-timer)
            (define-key map "\C-c]te]" #'loophole-stop-editing-timer)
            (define-key map "\C-c]te+" #'loophole-extend-editing-timer)
            (define-key map "\C-c]\\" #'loophole-disable-latest)
            (define-key map "\C-c](" #'loophole-start-kmacro)
            (define-key map "\C-c])" #'loophole-end-kmacro)
            (define-key map "\C-c]ks" #'loophole-start-kmacro)
            (define-key map "\C-c]ke" #'loophole-end-kmacro)
            (define-key map "\C-c]ka" #'loophole-abort-kmacro)
            (define-key map "\C-c]kb" #'loophole-bind-last-kmacro)
            (define-key map "\C-c]be" #'loophole-bind-entry)
            (define-key map "\C-c]bc" #'loophole-bind-command)
            (define-key map "\C-c]bk" #'loophole-bind-kmacro)
            (define-key map "\C-c]bK" #'loophole-bind-last-kmacro)
            (define-key map "\C-c]ba" #'loophole-bind-array)
            (define-key map "\C-c]bm" #'loophole-bind-keymap)
            (define-key map "\C-c]bs" #'loophole-bind-symbol)
            (define-key map "\C-c]m" #'loophole-modify-entry)
            map)
  (if loophole-mode
      (progn
        (setq loophole--buffer-list nil)
        (dolist (buffer (buffer-list))
          (with-current-buffer buffer
            (if (seq-some #'local-variable-p
                          (loophole-local-variable-if-set-list))
                (push buffer loophole--buffer-list))))
        (dolist (variable (loophole-local-variable-if-set-list))
          (add-variable-watcher variable
                                #'loophole--follow-adding-local-variable))
        (dolist (buffer loophole--buffer-list)
          (with-current-buffer buffer
            (add-hook 'change-major-mode-hook
                      #'loophole--follow-killing-local-variable nil t)
            (add-hook 'kill-buffer-hook
                      #'loophole--follow-killing-local-variable nil t)))
        (unless loophole--suspended (loophole-resume)))
    (let ((flag loophole--suspended))
      (loophole-suspend)
      (setq loophole--suspended flag))
    (dolist (buffer (loophole-buffer-list))
      (with-current-buffer buffer
        (remove-hook 'kill-buffer-hook
                     #'loophole--follow-killing-local-variable t)
        (remove-hook 'change-major-mode-hook
                     #'loophole--follow-killing-local-variable t)))
    (dolist (variable (loophole-local-variable-if-set-list))
      (remove-variable-watcher variable
                               #'loophole--follow-adding-local-variable))
    (setq loophole--buffer-list t)))

;;; Customization helpers

(defvar loophole-auto-start-editing-for-existing-binding-advice nil
  "Advice function for auto start editing for existing bidning.
If `loophole-use-auto-start-editing-for-existing-binding' is
set non-nil, advice for start editing is kept in this variable.")

(defvar loophole-idle-prioritize-timer nil
  "Idle timer for prioritization.
If `loophole-use-idle-prioritize' is set non-nil, idle timer
is kept in this variable.
Idle timer prioritizes specified Loophole maps for all local
values and default value of `loophole--map-alist'.")

(defvar loophole-idle-save-timer nil
  "Idle timer for saving.
If `loophole-use-idle-save' is set non-nil, idle timer is
kept in this variable.
Idle timer do `loophole-save'.")

(defun loophole-turn-on-auto-prioritize ()
  "Turn on auto prioritize as user customization.
Add hooks to call `loophole-prioritize' for
`loophole-globalize', `loophole-localize'
`loophole-enable', `loophole-name',
`loophole-start-editing', `loophole-merge' and
`loophole-duplicate'.

All of hooks are optional.
Instead of using this function, user can pick some hooks
from function definition for optimized customization."
  (add-hook 'loophole-after-globalize-functions #'loophole-prioritize)
  (add-hook 'loophole-after-localize-functions #'loophole-prioritize)
  (add-hook 'loophole-after-enable-functions #'loophole-prioritize)
  (add-hook 'loophole-after-name-functions #'loophole-prioritize)
  (add-hook 'loophole-after-start-editing-functions #'loophole-prioritize)
  (add-hook 'loophole-after-merge-functions #'loophole-prioritize)
  (add-hook 'loophole-after-duplicate-functions
            (lambda (_map-variable duplicated-map-variable)
              (loophole-prioritize duplicated-map-variable))))

(defun loophole-turn-off-auto-prioritize ()
  "Turn off auto prioritize as user customization.
Remove hooks added by `loophole-turn-on-auto-prioritize'."
  (remove-hook 'loophole-after-globalize-functions #'loophole-prioritize)
  (remove-hook 'loophole-after-localize-functions #'loophole-prioritize)
  (remove-hook 'loophole-after-enable-functions #'loophole-prioritize)
  (remove-hook 'loophole-after-name-functions #'loophole-prioritize)
  (remove-hook 'loophole-after-start-editing-functions #'loophole-prioritize)
  (remove-hook 'loophole-after-merge-functions #'loophole-prioritize)
  (remove-hook 'loophole-after-duplicate-functions
               (lambda (_map-variable duplicated-map-variable)
                 (loophole-prioritize duplicated-map-variable))))

(defun loophole-turn-on-auto-stop-editing ()
  "Turn on auto stop-editing as user customization.
Add hooks to call `loophole-stop-editing' for
`loophole-prioritize', `loophole-globalize',
`loophole-localize', `loophole-enable',`loophole-disable',
`loophole-name', `loophole-merge' and `loophole-duplicate'.
 `loophole-disable-latest' and `loophole-disable-all' are
also affected by the hook for `loophole-disable'.

All of hooks are optional.
Instead of using this function, user can pick some hooks
from function definition for optimized customization."
  (add-hook 'loophole-after-prioritize-functions
            (lambda (map-variable)
              (unless (eq map-variable (loophole-editing))
                (loophole-stop-editing))))
  (add-hook 'loophole-after-globalize-functions
            (lambda (map-variable)
              (unless (eq map-variable (loophole-editing))
                (loophole-stop-editing))))
  (add-hook 'loophole-after-localize-functions
            (lambda (map-variable)
              (unless (eq map-variable (loophole-editing))
                (loophole-stop-editing))))
  (add-hook 'loophole-after-enable-functions
            (lambda (map-variable)
              (unless (eq map-variable (loophole-editing))
                (loophole-stop-editing))))
  (add-hook 'loophole-after-disable-functions
            (lambda (map-variable)
              (if (eq map-variable (loophole-editing))
                  (loophole-stop-editing))))
  (add-hook 'loophole-after-name-functions
            (lambda (map-variable)
              (unless (eq map-variable (loophole-editing))
                (loophole-stop-editing))))
  (add-hook 'loophole-after-merge-functions
            (lambda (map-variable)
              (unless (eq map-variable (loophole-editing))
                (loophole-stop-editing))))
  (add-hook 'loophole-after-duplicate-functions
            (lambda (map-variable _duplicated-map-variable)
              (unless (eq map-variable (loophole-editing))
                (loophole-stop-editing)))))

(defun loophole-turn-off-auto-stop-editing ()
  "Turn off auto stop-editing as user customization.
Remove hooks added by `loophole-turn-on-auto-stop-editing'."
  (remove-hook 'loophole-after-prioritize-functions
               (lambda (map-variable)
                 (unless (eq map-variable (loophole-editing))
                   (loophole-stop-editing))))
  (remove-hook 'loophole-after-globalize-functions
               (lambda (map-variable)
                 (unless (eq map-variable (loophole-editing))
                   (loophole-stop-editing))))
  (remove-hook 'loophole-after-localize-functions
               (lambda (map-variable)
                 (unless (eq map-variable (loophole-editing))
                   (loophole-stop-editing))))
  (remove-hook 'loophole-after-enable-functions
               (lambda (map-variable)
                 (unless (eq map-variable (loophole-editing))
                   (loophole-stop-editing))))
  (remove-hook 'loophole-after-disable-functions
               (lambda (map-variable)
                 (if (eq map-variable (loophole-editing))
                     (loophole-stop-editing))))
  (remove-hook 'loophole-after-merge-functions
               (lambda (map-variable)
                 (unless (eq map-variable (loophole-editing))
                   (loophole-stop-editing))))
  (remove-hook 'loophole-after-duplicate-functions
               (lambda (map-variable _duplicated-map-variable)
                 (unless (eq map-variable (loophole-editing))
                   (loophole-stop-editing)))))

(defun loophole-turn-on-auto-resume ()
  "Turn on auto resume as user customization.
Add hooks to call `loophole-resume' for
`loophole-register', `loophole-prioritize',
 `loophole-globalize', `loophole-localize',
`loophole-enable', `loophole-name',
`loophole-start-editing', `loophole-globalize-editing',
`loophole-localize-editing', `loophole-merge',
`loophole-duplicate' and `loophole-bind-entry'.
Binding commands including `loophole-set-key' and
`loophole-unset-key' are also affected by the hook of
`loophole-bind-entry'.

All of hooks are optional.
Instead of using this function, user can pick some hooks
from function definition for optimized customization."
  (add-hook 'loophole-after-register-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-prioritize-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-globalize-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-localize-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-enable-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-name-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-start-editing-functions
            (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-globalize-editing-functions
            (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-localize-editing-functions
            (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-merge-functions (lambda (_) (loophole-resume)))
  (add-hook 'loophole-after-duplicate-functions
            (lambda (_ __) (loophole-resume)))
  (add-hook 'loophole-bind-hook #'loophole-resume))

(defun loophole-turn-off-auto-resume ()
  "Turn off auto resume as user customization.
Remove hooks added by `loophole-turn-on-auto-resume'."
  (remove-hook 'loophole-after-register-functions
               (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-prioritize-functions
               (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-globalize-functions
               (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-localize-functions
               (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-enable-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-name-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-start-editing-functions
               (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-globalize-editing-functions
               (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-localize-editing-functions
               (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-merge-functions (lambda (_) (loophole-resume)))
  (remove-hook 'loophole-after-duplicate-functions
               (lambda (_ __) (loophole-resume)))
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
  (add-hook 'loophole-after-prioritize-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable))))
  (add-hook 'loophole-after-globalize-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable))))
  (add-hook 'loophole-after-localize-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable))))
  (add-hook 'loophole-after-enable-functions #'loophole-start-timer)
  (add-hook 'loophole-after-disable-functions #'loophole-stop-timer)
  (add-hook 'loophole-after-name-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable))))
  (add-hook 'loophole-after-start-editing-functions
            (lambda (map-variable)
              (if (symbol-value (get map-variable :loophole-state-variable))
                  (loophole-start-timer map-variable)))))

(defun loophole-turn-off-auto-timer ()
  "Turn off auto timer as user customization.
Remove hooks added by `loophole-turn-on-auto-timer'."
  (remove-hook 'loophole-after-prioritize-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable))))
  (remove-hook 'loophole-after-globalize-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable))))
  (remove-hook 'loophole-after-localize-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable))))
  (remove-hook 'loophole-after-enable-functions #'loophole-start-timer)
  (remove-hook 'loophole-after-disable-functions #'loophole-stop-timer)
  (remove-hook 'loophole-after-name-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable))))
  (remove-hook 'loophole-after-start-editing-functions
               (lambda (map-variable)
                 (if (symbol-value (get map-variable :loophole-state-variable))
                     (loophole-start-timer map-variable)))))

(defun loophole-turn-on-auto-editing-timer ()
  "Turn on auto timer as user customization.
Add hooks to call `loophole-start-editing-timer' and
`loophole-stop-editing-timer' for `loophole-prioritize',
`loophole-globalize', `loophole-localize',
`loophole-enable', `loophole-name',
`loophole-start-editing', `loophole-stop-editing',
`loophole-globalize-editing' and
`loophole-localize-editing'.

All of hooks are optional.
Instead of using this function, user can pick some hooks
from function definition for optimized customization."
  (add-hook 'loophole-after-prioritize-functions
            (lambda (map-variable)
              (if (eq map-variable (loophole-editing))
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-after-globalize-functions
            (lambda (map-variable)
              (if (eq map-variable (loophole-editing))
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-after-localize-functions
            (lambda (map-variable)
              (if (eq map-variable (loophole-editing))
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-after-enable-functions
            (lambda (map-variable)
              (if (eq map-variable (loophole-editing))
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-after-name-functions
            (lambda (map-variable)
              (if (eq map-variable (loophole-editing))
                  (loophole-start-editing-timer))))
  (add-hook 'loophole-after-start-editing-functions
            (lambda (_) (loophole-start-editing-timer)))
  (add-hook 'loophole-after-stop-editing-functions
            (lambda (_) (loophole-stop-editing-timer)))
  (add-hook 'loophole-after-globalize-editing-functions
            (lambda (_) (loophole-start-editing-timer)))
  (add-hook 'loophole-after-localize-editing-functions
            (lambda (_) (loophole-start-editing-timer))))

(defun loophole-turn-off-auto-editing-timer ()
  "Turn off auto editing timer as user customization.
Remove hooks added by `loophole-turn-on-auto-editing-timer'."
  (remove-hook 'loophole-after-prioritize-functions
               (lambda (map-variable)
                 (if (eq map-variable (loophole-editing))
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-after-globalize-functions
               (lambda (map-variable)
                 (if (eq map-variable (loophole-editing))
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-after-localize-functions
               (lambda (map-variable)
                 (if (eq map-variable (loophole-editing))
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-after-enable-functions
               (lambda (map-variable)
                 (if (eq map-variable (loophole-editing))
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-after-name-functions
               (lambda (map-variable)
                 (if (eq map-variable (loophole-editing))
                     (loophole-start-editing-timer))))
  (remove-hook 'loophole-after-start-editing-functions
               (lambda (_) (loophole-start-editing-timer)))
  (remove-hook 'loophole-after-stop-editing-functions
               (lambda (_) (loophole-stop-editing-timer)))
  (remove-hook 'loophole-after-globalize-editing-functions
               (lambda (_) (loophole-start-editing-timer)))
  (remove-hook 'loophole-after-localize-editing-functions
               (lambda (_) (loophole-start-editing-timer))))

(defun loophole-turn-on-auto-start-editing-for-existing-binding (&optional ask)
  "Turn on auto edit for existing key binidngs as user customization.

Some Loophole commands edit existing key bindings.
This function set up advices to start editing session
automatically with the keymap which holds concerned key
binding.

If optional argument ASK is non-nil, this function asks user
if editing session should be started.

This fuction add advice to `loophole-unset-key',
`loophole-reset-key', `loophole-modify-lambda-form',
`loophole-modify-kmacro', `loophole-modify-array' and
`loophole-modify-entry'.
All of advices are optional.
Instead of using this function, user can pick some advices
from function defining from optimized customization."
  (if loophole-auto-start-editing-for-existing-binding-advice
      (loophole-turn-off-auto-start-editing-for-existing-binding))
  (setq loophole-auto-start-editing-for-existing-binding-advice
        (lambda (key &rest _)
          (interactive
           (lambda (spec)
             (let ((active (seq-some #'symbol-value
                                     (loophole-state-variable-list))))
               (if active (advice-add 'loophole-editing
                                      :filter-return (lambda (__) t)))
               (unwind-protect
                   (advice-eval-interactive-spec spec)
                 (if active (advice-remove 'loophole-editing
                                           (lambda (__) t)))))))
          (let ((editing (loophole-editing))
                (map-variable (loophole-map-variable-for-key-binding key)))
            (if (and (loophole-registered-p map-variable)
                     (not (eq map-variable editing))
                     (or (null ask)
                         (prog1 (y-or-n-p
                                 (format
                                  "Currently editing %s.  Start editing %s? "
                                  (if editing editing "session is stopped")
                                  map-variable))
                           (message nil))))
                (loophole-start-editing map-variable)))))
  (let ((advice loophole-auto-start-editing-for-existing-binding-advice))
    (advice-add 'loophole-unset-key :before advice)
    (advice-add 'loophole-reset-key :before advice)
    (advice-add 'loophole-modify-lambda-form :before advice)
    (advice-add 'loophole-modify-kmacro :before advice)
    (advice-add 'loophole-modify-array :before advice)
    (advice-add 'loophole-modify-entry :before advice)))

(defun loophole-turn-off-auto-start-editing-for-existing-binding ()
  "Turn off auto edit for existing key binidngs as user customization.
Remove advices added by
`loophole-turn-on-auto-start-editing-for-existing-binding'."
  (let ((advice loophole-auto-start-editing-for-existing-binding-advice))
    (advice-remove 'loophole-unset-key advice)
    (advice-remove 'loophole-reset-key advice)
    (advice-remove 'loophole-modify-lambda-form advice)
    (advice-remove 'loophole-modify-kmacro advice)
    (advice-remove 'loophole-modify-array advice)
    (advice-remove 'loophole-modify-entry advice))
  (setq loophole-auto-start-editing-for-existing-binding-advice nil))

(defun loophole-turn-on-idle-prioritize (&optional target time)
  "Turn on idle prioritization as user customization.
Start idle timer for prioritizing Loophole maps.

By default, named Loophole maps that look like
loophole-*-map but not loophole-n-map will be prioritized
after 900 seconds.

Optional argument TARGET modifies prioritizing target.
When TARGET is a symbol normal, normal Loophole maps which
looks like loophole-*-map will be prioritized.
When TARGET is a function, it should return a list of
map-variable, and returned map-variables will be
prioritized.
When TARGET is a list, listed map-variables will be
prioritized.
Other than above, falls back on nil.

When TARGET intermediately derives a list, entries which are
not registered to Loophole is omitted, and first entry of the
list gets highest priority.
Otherwise, current order is preserved among prioritized
Loophole maps.

Optional argument TIME in seconds modifies duration time
of idle timer.

Idle timer is set in `loophole-idle-prioritize-timer'."
  (setq time (if (numberp time) time (* 60 15)))
  (if (timerp loophole-idle-prioritize-timer)
      (cancel-timer loophole-idle-prioritize-timer))
  (setq loophole-idle-prioritize-timer
        (run-with-idle-timer
         time
         t
         (lambda ()
           (let ((get-list
                  (cond ((eq target 'normal)
                         (lambda ()
                           (seq-filter
                            (lambda (map-variable)
                              (let ((name (symbol-name map-variable)))
                                (string-match "^loophole-.+-map$" name)))
                            (loophole-map-variable-list))))
                        ((functionp target) target)
                        ((consp target) (lambda () target))
                        (t
                         (lambda ()
                           (seq-filter
                            (lambda (map-variable)
                              (let ((name (symbol-name map-variable)))
                                (and (string-match "^loophole-.+-map$" name)
                                     (not (string-match "^loophole-[0-9]+-map$"
                                                        name)))))
                            (loophole-map-variable-list))))))
                 (test-and-filter
                  (lambda (map-variable-list)
                    (unless (listp map-variable-list)
                      (user-error
                       (format
                        "Idle prioritize failed.  %s does not derive list"
                        target)))
                    (seq-filter (lambda (map-variable)
                                  (and (symbolp map-variable)
                                       (loophole-registered-p map-variable)))
                                map-variable-list))))
             (dolist (buffer (loophole-buffer-list))
               (with-current-buffer buffer
                 (if (loophole-priority-is-local-p)
                     (dolist (map-variable
                              (reverse
                               (funcall test-and-filter (funcall get-list))))
                       (loophole-prioritize map-variable 'local)))))
             (with-temp-buffer
               (dolist (map-variable
                        (reverse (funcall test-and-filter (funcall get-list))))
                 (loophole-prioritize map-variable 'default))))))))

(defun loophole-turn-off-idle-prioritize ()
  "Turn off idle prioritization as user customization.
Cancel timer `loophole-idle-prioritize-timer' and set nil
to it."
  (if (timerp loophole-idle-prioritize-timer)
      (cancel-timer loophole-idle-prioritize-timer))
  (setq loophole-idle-prioritize-timer nil))

(defun loophole-turn-on-idle-save (&optional target time)
  "Turn on idle saving as user customization.
Start idle timer for saving Loophole maps.
Idle timer is set in `loophole-idle-save-timer'.

Optional argument TARGET will be passed to `loophole-save',
and TIME in seconds is used for duration time for idle timer
whose default value is 1800 seconds."
  (setq time (if (numberp time) time (* 60 30)))
  (if (timerp loophole-idle-save-timer)
      (cancel-timer loophole-idle-save-timer))
  (setq loophole-idle-save-timer
        (run-with-idle-timer time t #'loophole-save target)))

(defun loophole-turn-off-idle-save ()
  "Turn off idle saving as user customization.
Cancel timer `loophole-idle-save-timer' and set nil to it."
  (if (timerp loophole-idle-save-timer)
      (cancel-timer loophole-idle-save-timer))
  (setq loophole-idle-save-timer nil))

(defcustom loophole-use-auto-prioritize t
  "Flag if prioritize Loophole map automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-prioritize' or
`loophole-turn-off-auto-prioritize' manually.
They setup some hooks.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-prioritize'."
  :type 'boolean
  :set (lambda (symbol value)
         (if value
             (loophole-turn-on-auto-prioritize)
           (if (boundp symbol) (loophole-turn-off-auto-prioritize)))
         (set-default symbol value)))

(defcustom loophole-use-auto-stop-editing t
  "Flag if stop editing keymap automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-stop-editing' or
`loophole-turn-off-auto-stop-editing' manually.
They setup some hooks.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-stop-editing'."
  :type 'boolean
  :set (lambda (symbol value)
         (if value
             (loophole-turn-on-auto-stop-editing)
           (if (boundp symbol) (loophole-turn-off-auto-stop-editing)))
         (set-default symbol value)))

(defcustom loophole-use-auto-resume t
  "Flag if resume Loophole automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-resume' or
`loophole-turn-off-auto-resume' manually.
They setup some hooks.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-resume'."
  :type 'boolean
  :set (lambda (symbol value)
         (if value
             (loophole-turn-on-auto-resume)
           (if (boundp symbol) (loophole-turn-off-auto-resume)))
         (set-default symbol value)))

(defcustom loophole-use-auto-timer nil
  "Flag if start timer for disabling Loophole map automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-timer' or
`loophole-turn-off-auto-timer' manually.
They setup some hooks.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-timer'."
  :type 'boolean
  :set (lambda (symbol value)
         (if value
             (loophole-turn-on-auto-timer)
           (if (boundp symbol) (loophole-turn-off-auto-timer)))
         (set-default symbol value)))

(defcustom loophole-use-auto-editing-timer nil
  "Flag if start timer for stopping editing session automatically.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-editing-timer' or
`loophole-turn-off-auto-editing-timer' manually.
They setup some hooks.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-editing-timer'."
  :type 'boolean
  :set (lambda (symbol value)
         (if value
             (loophole-turn-on-auto-editing-timer)
           (if (boundp symbol) (loophole-turn-off-auto-editing-timer)))
         (set-default symbol value)))

(defcustom loophole-use-auto-start-editing-for-existing-binding nil
  "Flag if start editing automatically when existing key is looked up.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-auto-start-editing-for-existing-binding'
or
`loophole-turn-off-auto-start-editing-for-existing-binding'
manually.
They setup some advices.

If the value of this user option is a list, it is applied to
`loophole-turn-on-auto-start-editing-for-existing-binding'.
In that case, the value should be a list whose first element
is a flag if user is asked to confirm starting editing
session.

For more detailed customization, see documentation string of
`loophole-turn-on-auto-start-editing-for-existing-binding'."
  :type 'sexp
  :set (lambda (symbol value)
         (if value
             (if (listp value)
                 (apply
                  #'loophole-turn-on-auto-start-editing-for-existing-binding
                  value)
               (loophole-turn-on-auto-start-editing-for-existing-binding))
           (if (boundp symbol)
               (loophole-turn-off-auto-start-editing-for-existing-binding)))
         (set-default symbol value)))

(defcustom loophole-use-idle-prioritize nil
  "Flag if prioritize Loophole maps when idle.
When non-nil, idle prioritization is enabled by calling
`loophole-turn-on-idle-prioritize'.

If the value of this user option is a list, it is applied to
`loophole-turn-on-idle-prioritize'.
In that case, the value should be a list whose first element
is a target specifier for prioritizing and second element is
a duration time.

When target specifier is a symbol normal, normal Loophole
maps which looks like loophole-*-map will be prioritized.
When target specifier is a function, it should return a list
of map-variable, and returned map-variables will be
prioritized.
When target specifier is a list, listed map-variables will
be prioritized.
Other than above, named Loophole maps that look like
loophole-*-map but not loophole-n-map will be prioritized.

Default duration time is 900 seconds.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-idle-prioritize' or
`loophole-turn-off-idle-prioritize' manually.
They setup idle timer."
  :risky t
  :type 'sexp
  :set (lambda (symbol value)
         (if value
             (if (listp value)
                 (apply #'loophole-turn-on-idle-prioritize value)
               (loophole-turn-on-idle-prioritize))
           (if (boundp symbol) (loophole-turn-off-idle-prioritize)))
         (set-default symbol value)))

(defcustom loophole-use-idle-save nil
  "Flag if save Loophole maps when idle.
When non-nil, idle saving is enabled by calling
`loophole-turn-on-idle-save'.

If the value of this user option is a list, it is applied to
`loophole-turn-on-idle-save'.
In that case, the value should be a list whose first element
is a target specifier for saving and second element is
a duration time.

Target specifier is passed to `loophole-save' as an argument
TARGET through `loophople-turn-on-idle-save'.
Therefore, when  target specifier is a symbol named, named
Loophole map, i.e., loophole-*-map but not loophole-n-map
will be saved.
When target specifier is a symbol all, all registered maps
will be saved.
When target specifier is a function, it will be used as
a filter function who takes one argument, each map-variable
of Loophole maps.
When target specifier is a list, listed map-variables will
be saved.
Other than above, normal Loophole maps that look like
loophole-*-map will be saved.

Default duration time is 1800 seconds.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-turn-on-idle-save' or
`loophole-turn-off-idle-save' manually.
They setup idle timer."
  :risky t
  :type 'sexp
  :set (lambda (symbol value)
         (if value
             (if (listp value)
                 (apply #'loophole-turn-on-idle-save value)
               (loophole-turn-on-idle-save))
           (if (boundp symbol) (loophole-turn-off-idle-save)))
         (set-default symbol value)))

;;; A macro for defining keymap

(defvar font-lock-beg)
(defvar font-lock-end)

(defconst loophole--define-map-font-lock-regexp
  "(\\(loophole-define-map\\)\\_>[ 	]*\\(\\(?:\\sw\\|\\s_\\|\\\\.\\)+\\)?"
  "Regexp that matches with head of `loophole-define-map' form.")

(defun loophole--define-map-font-lock-extend-region ()
  "Extending region of multiline font lock for `loophole-define-map'.
If cursor is located in `loophole-define-map' form, extend
region to the beginning and end of the form.
Futhermore, if `loophole-define-map' follows cursor on the
same line, multiline font lock region covers
`loophole-define-map' form."
  (save-excursion
    (when (or (re-search-forward loophole--define-map-font-lock-regexp
                                 (line-end-position) t)
              (catch 'found
                (while (ignore-errors (up-list nil t t) t)
                  (let ((limit (point)))
                    (if (ignore-errors (backward-sexp) t)
                        (let ((search (re-search-forward
                                       loophole--define-map-font-lock-regexp
                                       limit t)))
                          (if search (throw 'found search))))))))
      (if (< (match-beginning 0) font-lock-beg)
          (setq font-lock-beg (match-beginning 0)))
      (goto-char (match-beginning 0))
      (if (ignore-errors (forward-sexp) t)
          (if (< font-lock-end (point)) (setq font-lock-end (point)))))))

(defun loophole--define-map-font-lock-function (limit)
  "Font lock matcher for `loophole-define-map'.
LIMIT is used for limiting search region."
  (save-excursion
    (if (re-search-forward loophole--define-map-font-lock-regexp limit t)
        (let ((match-data (match-data)))
          (when (< 4 (length match-data))
            (when (and (ignore-errors (forward-sexp 2) t)
                       (< (point) limit)
                       (re-search-forward
                        "[ 	\n]*\\(\\(?:\\sw\\|\\s_\\|\\\\.\\)+\\)"
                        limit t))
              (setcar (cdr match-data) (cadddr (match-data)))
              (setq match-data (append match-data (cddr (match-data))))
              (when (ignore-errors (forward-sexp) t)
                (skip-chars-forward "[ 	\n]")
                (let ((beg (point-marker)))
                  (if (and (looking-at "\"")
                           (ignore-errors (forward-sexp) t)
                           (< (point) limit))
                      (let ((end (point-marker)))
                        (setcar (cdr match-data) end)
                        (setq match-data
                              (append match-data (list beg end))))))))
            (set-match-data match-data))
          t))))

(defun loophole--define-map-add-font-lock-extend-region-function ()
  "Add `loophole--define-map-font-lock-extend-region' to hook."
  (add-hook 'font-lock-extend-region-functions
            #'loophole--define-map-font-lock-extend-region nil t))

(defun loophole--font-lock-keywords (&optional multiline)
  "Return keyboards of Loophole for font lock.
If the optional argument MULTILINE is non-nil, the keywords
support multiline."
  `((,(if multiline
          #'loophole--define-map-font-lock-function
        loophole--define-map-font-lock-regexp)
     (1 font-lock-keyword-face)
     (2 font-lock-variable-name-face nil t)
     (3 font-lock-variable-name-face nil t)
     (4 font-lock-doc-face t t))))

(defun loophole-font-lock-add-keywords (&optional multiline)
  "Add keyboards of Loophole for font lock.
If the optional argument MULTILINE is non-nil, the keyboards
supporting multiline are added."
  (let ((keywords (loophole--font-lock-keywords multiline))
        (modes '(emacs-lisp-mode lisp-interaction-mode)))
    (dolist (mode modes)
      (if multiline
          (add-hook
           (intern (concat (symbol-name mode) "-hook"))
           #'loophole--define-map-add-font-lock-extend-region-function))
      (font-lock-add-keywords mode keywords))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (memq major-mode modes)
          (if multiline
              (loophole--define-map-add-font-lock-extend-region-function))
          (font-lock-add-keywords nil keywords))))))

(defun loophole-font-lock-remove-keywords (&optional multiline)
  "Remove keyboards of Loophole for font lock.
If the optional argument MULTILINE is non-nil, the keyboards
supporting multiline are removed."
  (let ((keywords (loophole--font-lock-keywords multiline))
        (modes '(emacs-lisp-mode lisp-interaction-mode)))
    (dolist (mode modes)
      (if multiline
          (remove-hook
           (intern (concat (symbol-name mode) "-hook"))
           #'loophole--define-map-add-font-lock-extend-region-function))
      (font-lock-remove-keywords mode keywords))
    (dolist (buffer (buffer-list))
      (with-current-buffer buffer
        (when (memq major-mode modes)
          (if multiline
              (remove-hook 'font-lock-extend-region-functions
                            #'loophole--define-map-font-lock-extend-region t))
          (font-lock-remove-keywords nil keywords))))))

(make-obsolete-variable
 'loophole-font-lock-multiline
 "Font lock activity is now handled by `loophole-font-lock'."
 "0.8.2")
(defcustom loophole-font-lock 'multiline
  "Flag if font lock for Loophole forms is enabled.

Because this option uses :set property, `setq' does not work
for this variable.  Use `custom-set-variables' or call
`loophole-font-lock-add-keywords' or
`loophole-font-lock-remove-keywords' manually.
They setup some hooks and add or remove keyboards.

If the value of this option is non-nil, font lock for
Loophole form is enabled, and especially for the symbol
multiline, multiline font lock is enabled.
When using multiline, `jit-lock-contextually' should be
non-nil on buffers containing Loophole forms like
`loophole-define-map' to properly rehighlight forms."
  :type '(choice
          (const :tag "Disable font lock" nil)
          (const :tag "Enable font lock with support for multiline" multiline)
          (other :tag "Enable" t))
  :set (lambda (symbol new-value)
         (let ((old-value (if (boundp symbol) (symbol-value symbol))))
           (if new-value
               (unless old-value
                 (loophole-font-lock-add-keywords (eq new-value 'multiline)))
             (when old-value
               (loophole-font-lock-remove-keywords (eq old-value 'multiline)))))
         (set-default symbol new-value)))

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
  (declare (debug t) (doc-string 3) (indent 1))
  (unless state
    (setq state (intern (concat (symbol-name map) "-state"))))
  `(progn
     (defvar ,map (let ((s ,spec))
                    (cond ((keymapp s) s)
                          ((listp s)
                           (let ((m (make-sparse-keymap)))
                             (dolist (key-binding s)
                               (define-key m
                                 (car key-binding)
                                 (cdr key-binding)))
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
