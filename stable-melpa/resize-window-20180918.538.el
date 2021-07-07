;;; resize-window.el --- easily resize windows          -*- lexical-binding: t; -*-

;; Copyright (C) 2015  Free Software Foundation, Inc.

;; Author: Dan Sutton  <danielsutton01@gmail.com>
;; Maintainer: Dan Sutton  <danielsutton01@gmail.com>
;; URL: https://github.com/dpsutton/resize-mode
;; Package-Version: 20180918.538
;; Package-Commit: 72018aa4d2401b60120588199d4cedd0dc1fbcfb

;; Version: 0.1.0
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))
;; Keywords: window, resize

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:
;; Easily allows you to resize windows.  Rather than guessing that you
;; want `C-u 17 C-x {`, you could just press FFff, which enlarges 5
;; lines, then 5 lines, then one and then one.  The idea is that the
;; normal motions n,p,f,b along with r for reset and w for cycling
;; windows allows for super simple resizing of windows.  All of this is
;; inside of a while loop so that you don't have to invoke more chords
;; to resize again, but just keep using standard motions until you are
;; happy.

;; But, just run `M-x resize-window`. There are only a few commands to learn,
;; and they mimic the normal motions in emacs.

;;   n : Makes the window vertically bigger, think scrolling down. Use
;;        N  to enlarge 5 lines at once.
;;   p : Makes the window vertically smaller, again, like scrolling. Use
;;        P  to shrink 5 lines at once.
;;   f : Makes the window horizontally bigger, like scrolling forward;
;;        F  for five lines at once.
;;   b : window horizontally smaller,  B  for five lines at once.
;;   r : reset window layout to standard
;;   w : cycle through windows so that you can adjust other window
;;       panes.  W  cycles in the opposite direction.
;;   2 : create a new horizontal split
;;   3 : create a new vertical split
;;   0 : delete the current window
;;   k : kill all buffers and put window config on the stack
;;   y : make the window configuration according to the last config
;;   pushed onto the stack
;;   ? : Display menu listing commands


;;; Code:

(require 'cl-lib)

(defgroup resize-window nil
  "Quickly resize current window"
  :group 'convenience
  :prefix "rw-")

(defcustom resize-window-coarse-argument 5
  "Set how big a capital letter movement is."
  :type 'integer)

(defcustom resize-window-fine-argument 1
  "Set how big the default movement should be."
  :type 'integer)

(defcustom resize-window-allow-backgrounds t
  "Allow resize mode to set a background.
This is also valuable to see that you are in resize mode."
  :type 'boolean)

(defcustom resize-window-swap-capital-and-lowercase-behavior nil
  "Reverse default behavior of lower case and uppercase arguments."
  :type 'boolean)

(defcustom resize-window-notify-with-messages t
  "Show notifications in message bar."
  :type 'boolean)

(defvar resize-window--background-overlay ()
  "Holder for background overlay.")

(defvar resize-window--window-stack ()
  "Stack for holding window configurations.")

(defface resize-window-background
  '((t (:foreground "gray40")))
  "Face for when resizing window.")

(defun resize-window-lowercase-argument ()
  "Return the behavior for lowercase entries.
Example, normally n maps to enlarge vertically by 1. However,
if you have swapped capital and lowercase behavior, then
this should return the coarse adjustment."
  (if resize-window-swap-capital-and-lowercase-behavior
      resize-window-coarse-argument
    resize-window-fine-argument))

(defun resize-window-uppercase-argument ()
  "Return the behavior for uppercase entries.
Example, normally N maps to enlarge vertically by 5. However,
if you have swapped capital and lowercase behavior, then this
should return the fine adjustment (default 1)."
  (if resize-window-swap-capital-and-lowercase-behavior
      resize-window-fine-argument
    resize-window-coarse-argument))

(defvar resize-window-dispatch-alist
  '((?n resize-window--enlarge-down          " Resize - Expand down" t)
    (?p resize-window--enlarge-up            " Resize - Expand up" t)
    (?f resize-window--enlarge-horizontally  " Resize - horizontally" t)
    (?b resize-window--shrink-horizontally   " Resize - shrink horizontally" t)
    (?r resize-window--reset-windows         " Resize - reset window layout" nil)
    (?w resize-window--cycle-window-positive " Resize - cycle window" nil)
    (?W resize-window--cycle-window-negative " Resize - cycle window" nil)
    (?2 split-window-below " Split window horizontally" nil)
    (?3 split-window-right " Slit window vertically" nil)
    (?0 resize-window--delete-window " Delete window" nil)
    (?k resize-window--kill-other-windows " Kill other windows (save state)" nil)
    (?y resize-window--restore-windows " (when state) Restore window configuration" nil)
    (?? resize-window--display-menu          " Resize - display menu" nil))
  "List of actions for `resize-window-dispatch-default.
Main data structure of the dispatcher with the form:
\(char function documentation match-capitals\)")

(defvar resize-window-alias-list
  '((right ?f)
    (down ?n)
    (left ?b)
    (up ?p))
  "List of aliases for commands.
Rather than have to use n, etc, you can alias keys for others.")

(defun resize-window--notify (&rest info)
  "Notify with INFO, a string.
This is just a pass through to message usually.  However, it can be
overridden in tests to test the output of message."
  (when resize-window-notify-with-messages (apply #'message info)))

(defun resize-window--match-alias (key)
  "Taken the KEY or keyboard selection from `read-key` check for alias.
Match the KEY against the alias table.  If found, return the value that it
points to, which should be a key in the ‘resize-window-dispatch-alist’.
Otherwise, return the key."
  (let ((alias (assoc key resize-window-alias-list)))
    (if alias
        (car (cdr alias))
      key)))

(defun resize-window--choice-keybinding (choice)
  "Get the keybinding associated with CHOICE."
  (car choice))

(defun resize-window--choice-documentation (choice)
  "Get the documentation associated with CHOICE."
  (car (cdr (cdr choice))))

(defun resize-window--choice-lambda (choice)
  "Get the lambda associated with CHOICE."
  (car (cdr choice)))

(defun resize-window--allows-capitals (choice)
  "To save time typing, we will tell whether we allow capitals for scaling.
To do so, we check to see whether CHOICE allows for capitals by
checking its last spot in the list for whether it is true or
nil."
  (car (last choice)))

(defun resize-window--display-choice (choice)
  "Formats screen message about CHOICE.
CHOICE is a \(key function description allows-capital\)."
  (let ((key (resize-window--choice-keybinding choice)))
    (format "%s: %s " (if (resize-window--allows-capitals choice)
                          (format "%s|%s"
                                  (string key)
                                  (string (- key 32)))
                        (string key))
            (resize-window--choice-documentation choice))))

(defun resize-window--get-documentation-strings ()
  (mapconcat #'identity (mapcar 'resize-window--display-choice
                              resize-window-dispatch-alist)
             "\n"))

(defun resize-window--make-background ()
  "Place a background over the current window."
  (when resize-window-allow-backgrounds
    (let ((ol (make-overlay
               (point-min)
               (point-max)
               (window-buffer))))
      (overlay-put ol 'face 'resize-window-background)
      ol)))

(defun resize-window--execute-action (choice &optional scaled)
  "Given a CHOICE, grab values out of the alist.
If SCALED, then call action with the resize-window-capital-argument."
  ;; (char function description)
  (let ((action (resize-window--choice-lambda choice))
        (description (resize-window--choice-documentation choice)))
    (unless (equal (resize-window--choice-keybinding choice) ??)
      (resize-window--notify "%s" description))
    (condition-case nil
     (if scaled
         (funcall action (resize-window-uppercase-argument))
       (funcall action))

     (wrong-number-of-arguments
      (resize-window--notify "Invalid arity in function for %s"
                             (char-to-string
                              (resize-window--choice-keybinding choice)))))))

;;;###autoload
(defun resize-window ()
  "Resize the window.
Press n to enlarge down, p to enlarge up, b to enlarge left and f
to enlarge right."
  (interactive)
  (setq resize-window--background-overlay (resize-window--make-background))
  (resize-window--notify "Resize mode: enter character, ? for help")
  (condition-case nil
   (let ((reading-characters t)
         ;; allow mini-buffer to collapse after displaying menu
         (resize-mini-windows t))
     (while reading-characters
       (let* ((char (resize-window--match-alias (read-key)))
              (choice (assoc char resize-window-dispatch-alist))
              (capital (when (numberp char)
                         (assoc (+ char 32) resize-window-dispatch-alist))))
         (cond
          (choice (resize-window--execute-action choice))
          ((and capital (resize-window--allows-capitals capital))
           ;; rather than pass an argument, we tell it to "scale" it
           ;; with t and that method can worry about how to get that
           ;; action
           (resize-window--execute-action capital t))
          (t (setq reading-characters nil)
             (delete-overlay resize-window--background-overlay))))))
   (quit (resize-window--delete-overlays))))

;;; Function Handlers
(defun resize-window--enlarge-down (&optional size)
  "Extend the current window downwards by optional SIZE.
If no SIZE is given, extend by `resize-window-default-argument`"
  (let ((size (or size (resize-window-lowercase-argument))))
    (enlarge-window size)))

(defun resize-window--enlarge-up (&optional size)
  "Bring bottom edge back up by one or optional SIZE."
  (let ((size (or size (resize-window-lowercase-argument))))
    (enlarge-window (- size))))

(defun resize-window--enlarge-horizontally (&optional size)
  "Enlarge the window horizontally by one or optional SIZE."
  (let ((size (or size (resize-window-lowercase-argument))))
    (enlarge-window size t)))

(defun resize-window--shrink-horizontally (&optional size)
  "Shrink the window horizontally by one or optional SIZE."
  (let ((size (or size (resize-window-lowercase-argument))))
    (enlarge-window (- size) t)))

(defun resize-window--reset-windows ()
  "Reset window layout to even spread."
  (balance-windows))

(defun resize-window--delete-overlays ()
  (delete-overlay resize-window--background-overlay))

(defun resize-window--create-overlay ()
  (setq resize-window--background-overlay (resize-window--make-background)))

(defun resize-window--cycle-window-positive ()
  "Cycle windows."
  (delete-overlay resize-window--background-overlay)
  (other-window 1)
  (setq resize-window--background-overlay (resize-window--make-background)))

(defun resize-window--cycle-window-negative ()
  "Cycle windows negative."
  (delete-overlay resize-window--background-overlay)
  (other-window -1)
  (setq resize-window--background-overlay (resize-window--make-background)))

(defun resize-window--display-menu ()
  "Display menu in minibuffer."
  (resize-window--notify "%s" (resize-window--get-documentation-strings)))

(defun resize-window--delete-window ()
  (delete-overlay resize-window--background-overlay)
  (delete-window)
  (setq resize-window--background-overlay (resize-window--make-background)))

(defun resize-window--window-push ()
  (push (current-window-configuration) resize-window--window-stack))

(defun resize-window--window-pop ()
  (pop resize-window--window-stack))

(defun resize-window--kill-other-windows ()
  (resize-window--delete-overlays)
  (resize-window--window-push)
  (delete-other-windows)
  (resize-window--create-overlay))

(defun resize-window--restore-windows ()
  (let ((config (resize-window--window-pop)))
    (when config
      (resize-window--delete-overlays)
      (set-window-configuration config)
      (resize-window--create-overlay))))

(defvar resize-window--capital-letters (number-sequence ?A ?Z))
(defvar resize-window--lower-letters (number-sequence ?a ?z))

(defun resize-window--key-available? (key)
  (let ((keys (mapcar #'resize-window--choice-keybinding resize-window-dispatch-alist)))
    (not (member key keys))))

(defun resize-window-add-choice (key func doc &optional allows-capitals)
  "Register a function for resize-window.
KEY is the char (eg ?c) that should invoke the FUNC. DOC is a doc
string for the help menu, and optional ALLOWS-CAPITALS should be
t or nil. Functions should be of zero arity if they do not allow
capitals, and should be of optional single arity if they allow
capitals. Invoking with the capital will pass the capital
argument."
  (if (resize-window--key-available? key)
      (push (list key func doc allows-capitals) resize-window-dispatch-alist)
      (message "The `%s` key is already taken for resize-window." (char-to-string key))))

(provide 'resize-window)
;;; resize-window.el ends here
