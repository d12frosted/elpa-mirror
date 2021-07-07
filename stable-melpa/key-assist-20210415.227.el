;;; key-assist.el --- Minibuffer keybinding cheatsheet and launcher -*- lexical-binding: t -*-

;; Copyright © 2020-2021, Boruch Baum <boruch_baum@gmx.com>
;; Available for assignment to the Free Software Foundation, Inc.

;; Author: Boruch Baum <boruch_baum@gmx.com>
;; Maintainer: Boruch Baum <boruch_baum@gmx.com>
;; Homepage: https://github.com/Boruch-Baum/emacs-key-assist
;; Keywords: abbrev convenience docs help
;; Package-Version: 20210415.227
;; Package-Commit: fae7ce265db3bcfd1c6153eb051afd8789e61a4b
;; Package: key-assist
;; Version: 1.0
;; Package-Requires: ((emacs "24.3"))
;;
;;   (emacs "24.3") for: lexical-binding, user-error, cl-lib

;; This file is NOT part of GNU Emacs.

;; This is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this software.  If not, see <https://www.gnu.org/licenses/>.

;;
;;; Commentary:

;;   For Emacs *users*:
;;
;;     This package provides an interactive command to easily produce
;;     a keybinding cheat-sheet "on-the-fly", and then to launch any
;;     command on the cheat-sheet list. At its simplest, it gives the
;;     user a list of keybindings for commands specific to the current
;;     buffer's major-mode, but it's trivially simple to ask it to
;;     build an alternative (see below).
;;
;;     Use this package to: learn keybindings; learn what commands are
;;     available specifically for the current buffer; run a command
;;     from a descriptive list; and afterwards return to work quickly.
;;
;;   For Emacs *programmers*:
;;
;;     This package provides a simple, flexible way to produce custom
;;     keybinding cheat-sheets and command launchers for sets of
;;     commands, with each command being described, along with its
;;     direct keybinding for direct use without the launcher (see
;;     below).
;;
;;   If you've ever used packages such as `ivy' or `magit', you've
;;   probably benefited from each's custom combination keybinding
;;   cheatsheet and launcher: `hydra' in the case of `ivy', and
;;   `transient' for `magit'. The current package `key-assist' offers
;;   a generic and very simple alternative requiring only the
;;   `completing-read' function commonly used in core vanilla Emacs.
;;   `key-assist' is trivial to implement "on-the-fly" interactively
;;   for any buffer, and programmatically much simpler to customize
;;   that either `hydra' or `transient'. And it only requires the
;;   Emacs core function `completing-read'.

;;
;;; Dependencies:

;; `cl-lib': For `cl-member',`cl-position'

;;
;;; Installation:

;; 1) Evaluate or load this file.

;;
;;; Interactive operation:

;;   Run M-x `key-assist' from the buffer of interest. Specify a
;;   selection (or don't), press <TAB> to view the presentation, and
;;   then either exit with your new-found knowledge of the command
;;   keybindings, or use standard Emacs tab completion to select an
;;   option, and press <RETURN> to perform the action.
;;
;;   If you choose not to respond to the initial prompt, a list of
;;   keybindings and command descriptions will be generated based upon
;;   the first word of the buffer's major mode. For, example, in a
;;   `w3m' buffer, the list will be of all interactive functions
;;   beginning `w3m-'. This works out to be great as a default, but
;;   isn't always useful. For example, in an `emacs-lisp-mode' buffer
;;   or a `lisp-interaction-mode', what would you expect it to
;;   usefully produce? At the other extreme might be a case of a
;;   buffer with too many obscure keybindings of little use.

;;   You can also respond to the prompt with your own regexp of
;;   commands to show, or with the name of a keymap of your choice.
;;   For the purposes of `key-assist', a regexp can be just a
;;   substring, without REQUIRING any leading or trailing globs.

;;   In all cases, note that the package can only present keybindings
;;   currently active in the current buffer, so if a sub-package
;;   hasn't been loaded yet, that package's keybindings would not be
;;   presented. Also note that the commands are presented sorted by
;;   keybinding length, alphabetically.

;;
;;; Programmating example:

;;   Here's a most simple example that presents all of the keybindings
;;   for 'my-mode:
;;
;;      (defun my-mode-keybinding-cheatsheet-launcher ()
;;        (interactive)
;;        (when (eq major-mode my-mode)
;;          (key-assist)))
;;      (define-key my-mode-map "?"
;;                  'my-mode-keybinding-cheatsheet-launcher)

;;   See the docstrings for functions `key-assist' and
;;   `key-assist--get-cmds' for the description of ARGS that can be
;;   used to customize the output.

;;
;;; Configuration:

;;   Two variables are available to exclude items from the
;;   presentation list: `key-assist-exclude-cmds' and
;;   `key-assist-exclude-regexps'. See there for further information.

;;
;;; Compatability

;;   Tested with Emacs 26.1 and emacs-snapshot 28(~2020-09-16), both
;;   in debian.


;;
;;; Code:

(require 'cl-lib) ;; cl-member, cl-position

;;
;;; Variables:

(defvar key-assist-exclude-cmds
  '(ignore
    self-insert-command
    digit-argument
    negative-argument
    describe-mode)
  "List of commands to always exclude from `key-assist' output.")

(defvar key-assist-exclude-regexps '("-mouse-")
  "List of regexps of commands to exclude from `key-assist' output.")
;; TODO: Don't depend upon a mouse command having the word '-mouse-' in it.


;;
;;; Internal functions:

(defun key-assist--get-keybinding (cmd &optional key-map)
  "Return a string with CMD's shortest keybinding.
Optional arg KEY-MAP defaults to local map."
  (let (shortest)
    (dolist (key (mapcar #'key-description
                         (where-is-internal
                           cmd key-map nil t)))
      (when (or (not shortest)
                (> (length shortest) (length key))
                (and (= 1 (length key))
                     (equal key (downcase key))))
        (setq shortest key)))
    shortest))

(defun key-assist--get-description (cmd)
  "Return a string with CMD's description.
CMD is a symbol of an interactive command."
  (let ((doc (documentation cmd t)))
    (format "\t%s"
      (if (or (not (stringp doc))
              (string-empty-p doc))
        (concat (symbol-name cmd) " (not documented)")
       (when (string-match "\n" doc)
         (setq doc (substring doc 0 (match-beginning 0))))
       (if (equal "." (substring doc -1))
         (substring doc 0 -1)
        doc)))))

(defun key-assist--vet-cmd (cmd result-list)
  "Check whether CMD should be on a `key-assist' list.

Each element of RESULT-LIST is a CMD already accepted, in the
form '(keybinding-string, CMD, description-string).

See `key-assist-exclude-cmds' and `key-assist-exclude-regexps'."
  (and
    (symbolp cmd)
    (commandp cmd)
    (not (cl-member cmd result-list
                    :test (lambda (cmd l) (equal cmd (nth 1 l)))))
    (not (memq cmd key-assist-exclude-cmds))
    (let ((not-found t)
          (cmd-string (symbol-name cmd)))
      (dolist (regexp key-assist-exclude-regexps)
        (when (string-match regexp cmd-string)
          (setq not-found nil)))
      not-found)))

(defun key-assist--parse-cmd (cmd result-list &optional key-map)
  "Extract a command and shortest keybinding from a keymap.

If KEY-MAP is nil, use the local map, and look for CMD there.
Each element of RESULT-LIST is a CMD already accepted, in the
form '(keybinding-string, CMD, description-string).

This is an internal function used by `key-assist'. Returns a list
whose elements are a keybinding string, a command symbol, and a
description string."
  (when (key-assist--vet-cmd cmd result-list)
    (let* ((key-map (when (keymapp key-map) key-map))
           (shortest (key-assist--get-keybinding cmd key-map)))
      (when shortest
        (list shortest cmd (concat shortest (key-assist--get-description cmd)))))))

(defun key-assist--get-cmds (spec &optional nosort nofinish)
  "Return a list of commands, keybindings, and descriptions.

Returns a list of CONS, whose CAR is the command, and whose CDR
is a string of the form \"shortest-keybinding tab-character
command-description\".

Optional arg SPEC may be a regexp string of desired commands. If
NIL, a regexp is generated based upon the first word of the
buffer's major mode. SPEC may also be a keymap of desired
commands. In both of these cases, the resulting list is sorted
alphabetically by keybinding length.

SPEC has additional options of being either a list of commands,
or a list of CONS whose CAR is a command, and whose CDR is either a
description-string or a function which returns a description
string. A final programmatic option is for SPEC to be any
combination of the above options. For that most complex case, the
first list element of SPEC must be the symbol 'collection. For
none of these additional options is sorting performed.

Optional arg NOSORT can be a function to replace the default sort
algorithm with the programmer's desired post-processing, or some
other non-nil value for no sorting at all. If a function, it
should accept a single list of elements (keybinding-string
commandp description-string) and should return a list of
elements (anything commandp description-string).

Optional arg NOFINISH return a list in `key-assist--parse-cmd'
format instead of the list of CONS described above. It is used
internally for processing 'collection lists."
  (when (and spec
             (not (and (stringp spec)
                       (zerop (length spec)))))
    (when (and (stringp spec)
               (boundp (intern spec))
               (keymapp (symbol-value (intern spec))))
        (setq spec (symbol-value (intern spec))))
    (let (result-elem (result-list '()))
      (cond
       ((keymapp spec)
         (let (cmd)
           (dolist (elem spec)
             (cond
              ((atom elem)) ;; eg. 'keymap
              ((listp (setq cmd (cdr elem)))) ;; TODO: possibly also embedded keymap?
              ((commandp cmd) ;; this excludes 'menubar
                (when (setq result-elem (key-assist--parse-cmd cmd result-list))
                  (push result-elem result-list)))))))
       ((stringp spec)
         (mapatoms
           (lambda (x)
              (and (commandp x)
                   (string-match spec (symbol-name x))
                   (when (setq result-elem
                           (key-assist--parse-cmd x result-list))
                     (push result-elem result-list))))))
       ((listp spec)
         (cond
          ((eq (car spec) 'collection)
            (dolist (collection-element (cdr spec))
              ;; Maybe it's more efficient to sort each collection element?
              (let ((temp-list (key-assist--get-cmds collection-element 'nosort 'nofinish)))
                (dolist (elem temp-list)
                  (push elem result-list)))))
          ((commandp (car spec))
            (dolist (cmd spec)
              (when (setq result-elem (key-assist--parse-cmd cmd result-list))
                (push result-elem result-list))))
          (t ; spec is a list of CONS (cmd . (or string function))
            (dolist (elem spec)
              (when (key-assist--vet-cmd (car elem) result-list)
                (let ((shortest (key-assist--get-keybinding (car elem))))
                  (when shortest
                    (push (list shortest
                                (car elem)
                                (if (stringp (cadr elem))
                                  (cadr elem)
                                 (funcall (cadr elem))))
                          result-list))))))))
       (t (error "Improper SPEC format")))
      (setq result-list (nreverse result-list))
      (setq result-list
        (cond
         ((functionp nosort)
           (funcall nosort result-list))
         (nosort result-list)
         (t ; ie. (eq nosort nil)
           (sort result-list
                 (lambda (a b) (cond
                                ((= (length (car a)) (length (car b)))
                                   (string< (car a) (car b)))
                                ((< (length (car a)) (length (car b))))
                                (t nil)))))))
      (if nofinish
        result-list
       (mapcar (lambda (x) (cons (nth 1 x) (nth 2 x)))
               result-list)))))

;;
;;; Interactive functions:

(defun key-assist (&optional spec prompt nosort)
  "Prompt to eval a locally relevant function, with hints and keybindings.
Press TAB to see the hints.

Interactively, the optional arg SPEC is either a regexp string
for candidate commands to match, or a keymap from which to
prepare the hints. If NIL, a regexp is generated based upon the
first word of the buffer's major mode. Results are presented
sorted alphabetically by keybinding length.

Programmatically, optional arg PROMPT can be used to customize
the prompt. For the further programmatic options of SPEC and for
a description of arg NOSORT, see function `key-assist--get-cmds'.

See also variables `key-assist-exclude-regexps' and
`key-assist-exclude-cmds'."
  (interactive)
  (when (not spec)
    (setq spec (symbol-name major-mode)
          spec (substring spec 0 (1+ (string-match "-" spec)))
          spec (read-regexp
                 (format "Press RET for keybinding cheatsheet/launcher for \"%s\" commands,
Or enter a different command regexp or keymap name: " spec)
                         spec)))
  (when (or (not spec)
            (and (stringp spec)
                 (zerop (length spec))))
    (user-error "Nothing to do!"))
  (let ((tab-width 11)
        commands choices choice minibuffer-history)
    (while (not choices)
      (setq commands (key-assist--get-cmds spec nosort))
      (when (not (setq choices (mapcar #'cdr commands)))
        (setq spec (read-regexp (format "No choices found for \"%s\".
Try a differernt command regexp or keymap name: "
                                        spec)
                                spec))))
    (while (not (setq choice
                  (cl-position
                      (completing-read
                        (or prompt "You may need to press TAB to see the result list.
Select an item on the list to launch it: ")
                        choices nil t)
                    choices :test 'equal))))
    (command-execute (car (nth choice commands)))))


;;
;;; Conclusion:

(provide 'key-assist)

;;; key-assist.el ends here

;; NOTE: For integration into emacs:
;; * ref: https://debbugs.gnu.org/cgi/bugreport.cgi?bug=43709
;;        mailto: 43709@debbugs.gnu.org
;; * defcustoms should include  :version "28.1"

;; TODO: Don't require existence of a keybinding for elements in an
;;       explicit SPEC, and let the user execute the command.
