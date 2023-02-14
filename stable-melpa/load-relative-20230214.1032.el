;;; load-relative.el --- Relative file load (within a multi-file Emacs package) -*- lexical-binding: t -*-

;; Author: Rocky Bernstein <rocky@gnu.org>
;; Version: 1.3.2
;; Package-Version: 20230214.1032
;; Package-Commit: b7987c265a64435299d6b02f960ed2c894c4a145
;; Keywords: internal
;; URL: https://github.com/rocky/emacs-load-relative
;; Compatibility: GNU Emacs 23.x

;; Copyright (C) 2015-2020, 2023 Free Software Foundation, Inc

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Here we provide functions which facilitate writing multi-file Emacs
;; packages and facilitate running from the source tree without having
;; to "install" code or fiddle with evil `load-path'.  See
;; https://github.com/rocky/emacs-load-relative/wiki/NYC-Lisp-talk for
;; the the rationale behind this.
;;
;; The functions we add are relative versions of `load', `require' and
;; `find-file-no-select' and versions which take list arguments.  We also add a
;; `__FILE__' function and a `provide-me' macro.

;; The latest version of this code is at:
;;     https://github.com/rocky/emacs-load-relative/

;; `__FILE__' returns the file name that that the calling program is
;; running.  If you are `eval''ing a buffer then the file name of that
;; buffer is used.  The name was selected to be analogous to the name
;; used in C, Perl, Python, and Ruby.

;; `load-relative' loads an Emacs Lisp file relative to another
;; (presumably currently running) Emacs Lisp file.  For example suppose
;; you have Emacs Lisp files "foo.el" and "bar.el" in the same
;; directory.  To load "bar.el" from inside Emacs Lisp file "foo.el":
;;
;;     (require 'load-relative)
;;     (load-relative "baz")
;;
;; The above `load-relative' line could above have also been written as:
;;
;;     (load-relative "./baz")
;; or:
;;     (load-relative "baz.el")  # if you want to exclude any byte-compiled files
;;
;; Use `require-relative' if you want to `require' the file instead of
;; `load'ing it:
;;
;;    (require-relative "baz")
;;
;; or:
;;
;;    (require-relative "./baz")
;;
;; The above not only does a `require' on 'baz', but makes sure you
;; get that from the same file as you would have if you had issued
;; `load_relative'.
;;
;; Use `require-relative-list' when you have a list of files you want
;; to `require'.  To `require-relative' them all in one shot:
;;
;;     (require-relative-list '("dbgr-init" "dbgr-fringe"))
;;
;; The macro `provide-me' saves you the trouble of adding a
;; symbol after `provide' using the file basename (without directory
;; or file extension) as the name of the thing you want to
;; provide.
;;
;; Using this constrains the `provide' name to be the same as
;; the filename, but I consider that a good thing.
;;
;; The function `find-file-noselect-relative' provides a way of accessing
;; resources which are located relative to the currently running Emacs Lisp
;; file.  This is probably most useful when running Emacs as a scripting engine
;; for batch processing or with tests cases.  For example, this form will find
;; the README file for this package.
;;
;;     (find-file-noselect-relative "README.md")
;;
;; `find-file-noselect-relative' also takes wildcards, as does it's
;; non-relative namesake.
;;
;; The macro `with-relative-file' runs in a buffer with the contents of the
;; given relative file.
;;
;;    (with-relative-file "README.md"
;;      (buffer-substring))
;;
;; This is easier if you care about the contents of the file, rather than
;; a buffer.

;;; Code:

;; Press C-x C-e at the end of the next line configure the program in GNU emacs
;; for building via "make" to get set up.
;; (compile (format "EMACSLOADPATH=:%s ./autogen.sh" "."))
;; After that you can run:
;; (compile "make check")

;;;###autoload
(defun __FILE__ (&optional symbol)
  "Return the string name of file/buffer that is currently begin executed.

The first approach for getting this information is perhaps the
most pervasive and reliable.  But it the most low-level and not
part of a public API, so it might change in future
implementations.  This method uses the name that is recorded by
readevalloop of `lread.c' as the car of variable
`current-load-list'.

Failing that, we use `load-file-name' which should work in some
subset of the same places that the first method works.  However
`load-file-name' will be nil for code that is eval'd.  To cover
those cases, we try function `buffer-file-name' which is initially
correct, for eval'd code, but will change and may be wrong if the
code sets or switches buffers after the initial execution.

As a last resort, you can pass in SYMBOL which should be some
symbol that has been previously defined if none of the above
methods work we will use the file-name value find via
`symbol-file'."
  ;; Not used right now:
  ;; Failing the above the next approach we try is to use the value of
  ;; $# - 'the name of this file as a string'. Although it doesn't
  ;; work for eval-like things, it has the advantage that this value
  ;; persists after loading or evaluating a file. So it would be
  ;; suitable if __FILE__ were called from inside a function.

  (cond

   ;; lread.c's readevalloop sets (car current-load-list)
   ;; via macro LOADHIST_ATTACH of lisp.h. At least in Emacs
   ;; 23.0.91 and this code goes back to '93.
   ((stringp (car-safe current-load-list)) (car current-load-list))

   ;; load-like things. 'relative-file-expand' tests in
   ;; test/test-load.el indicates we should put this ahead of
   ;; $#.
   (load-file-name)

   ;; Pick up "name of this file as a string" which is set on
   ;; reading and persists. In contrast, load-file-name is set only
   ;; inside eval. As such, it won't work when not in the middle of
   ;; loading.
   ;; (#$)

   ;; eval-like things
   ((buffer-file-name))

   ;; When byte compiling. FIXME: use a more thorough precondition like
   ;; byte-compile-file is somehwere in the backtrace or that
   ;; bytecomp-filename comes from that routine?
   ;; FIXME: `bytecomp-filename' doesn't exist any more (since Emacs-24.1).
   ((boundp 'bytecomp-filename) bytecomp-filename)

   (t (symbol-file symbol) ;; last resort
      )))

(defun autoload-relative (function-or-list
                          file &optional docstring interactive type
                          symbol)
  ;; FIXME: Docstring talks of FUNCTION but argname is `function-or-list'.
  "Autoload an Emacs Lisp file relative to Emacs Lisp code that is in the process
of being loaded or eval'd.


Define FUNCTION to autoload from FILE.  FUNCTION is a symbol.

FILE is a string to pass to `load'.

DOCSTRING is documentation for the function.

INTERACTIVE if non-nil says function can be called
interactively.

TYPE indicates the type of the object: nil or omitted says
function is a function, `keymap' says function is really a
keymap, and `macro' or t says function is really a macro.  Third
through fifth args give info about the real definition.  They
default to nil.  If function is already defined other than as an
autoload, this does nothing and returns nil.

SYMBOL is the location of of the file of where that was
defined (as given by `symbol-file' is used if other methods of
finding __FILE__ don't work."

  (if (listp function-or-list)
      ;; FIXME: This looks broken:
      ;; - Shouldn't it iterate on `function-or-list' instead of `file'?
      ;; - Shouldn't the `autoload' take `function' rather than
      ;;   `function-or-list' as argument?
      (mapc (lambda(_function)
              (autoload function-or-list
                (relative-expand-file-name file symbol)
                docstring interactive type))
              file)
    (autoload function-or-list (relative-expand-file-name file symbol)
      docstring interactive type))
  )

;;;###autoload
(defun find-file-noselect-relative (filename &optional nowarn rawfile wildcards)
  "Read relative FILENAME into a buffer and return the buffer.
If a buffer exists visiting FILENAME, return that one, but
verify that the file has not changed since visited or saved.
The buffer is not selected, just returned to the caller.
Optional second arg NOWARN non-nil means suppress any warning messages.
Optional third arg RAWFILE non-nil means the file is read literally.
Optional fourth arg WILDCARDS non-nil means do wildcard processing
and visit all the matching files.  When wildcards are actually
used and expanded, return a list of buffers that are visiting
the various files."
  (find-file-noselect (relative-expand-file-name filename)
                      nowarn rawfile wildcards))

;;;###autoload
(defmacro with-relative-file (file &rest body)
  "Read the relative FILE into a temporary buffer and evaluate BODY
in this buffer."
  (declare (indent 1) (debug t))
  `(with-temp-buffer
     (insert-file-contents
      (relative-expand-file-name
       ,file))
     ,@body))

;;;###autoload
(defun load-relative (file-or-list &optional symbol)
  "Load an Emacs Lisp file relative to Emacs Lisp code that is in
the process of being loaded or eval'd.

FILE-OR-LIST is either a string or a list of strings containing
files that you want to loaded.  If SYMBOL is given, the location of
of the file of where that was defined (as given by `symbol-file' is used
if other methods of finding __FILE__ don't work."

  (if (listp file-or-list)
      (mapcar (lambda(relative-file)
                (load (relative-expand-file-name relative-file symbol)))
              file-or-list)
    (load (relative-expand-file-name file-or-list symbol)))
  )

(defun relative-expand-file-name(relative-file &optional opt-file)
  "Expand RELATIVE-FILE relative to the Emacs Lisp code that is in
the process of being loaded or eval'd.

WARNING: it is best to run this function before any
buffer-setting or buffer changing operations."
  (let ((file (or opt-file (__FILE__) default-directory))
        (prefix))
    (unless file
      ;; FIXME: Since default-directory should basically never be nil, this
      ;; should basically never trigger!
      (error "Can't expand __FILE__ here and no file name given"))
    (setq prefix (file-name-directory file))
    (expand-file-name (concat prefix relative-file))))

;;;###autoload
(defun require-relative (relative-file &optional opt-file opt-prefix)
  "Run `require' on an Emacs Lisp file relative to the Emacs Lisp code
that is in the process of being loaded or eval'd.  The symbol used in require
is the base file name (without directory or file extension) treated as a
symbol.

WARNING: it is best to to run this function before any
buffer-setting or buffer changing operations."
  (let* ((relative-file (if (symbolp relative-file)
                            (symbol-name relative-file)
                          relative-file))
         (require-string-name
          (concat opt-prefix (file-name-sans-extension
                              (file-name-nondirectory relative-file)))))
    (require (intern require-string-name)
             (relative-expand-file-name relative-file opt-file))))

;;;###autoload
(defmacro require-relative-list (list &optional opt-prefix)
  "Run `require-relative' on each name in LIST which should be a list of
strings, each string being the relative name of file you want to run."
  `(eval-and-compile
     (dolist (rel-file ,list)
       (require-relative rel-file (__FILE__) ,opt-prefix))))

;;;###autoload
(defmacro provide-me ( &optional prefix )
  "Call `provide' with the feature's symbol name made from
source-code's file basename sans extension.  For example if you
write (provide-me) inside file ~/lisp/foo.el, this is the same as
writing: (provide \\='foo).

With a prefix, that prefix is prepended to the `provide' So in
the previous example, if you write (provide-me \"bar-\") this is the
same as writing (provide \\='bar-foo)."
  `(provide (intern (concat ,prefix (file-name-sans-extension
                                     (file-name-nondirectory (__FILE__)))))))

(provide-me)

;;; load-relative.el ends here
