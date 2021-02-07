;;; keypress-multi-event.el --- Perform different actions for the same keypress.

;; Copyright 2018 Boruch Baum <boruch_baum@gmx.com>,
;;   and available for assignment to the Free Software Foundation, Inc.
;;   for inclusion in GNU Emacs.

;; Author:           Boruch Baum <boruch_baum@gmx.com>
;; Name:             keypress-multi-event
;; Package-Version: 20190109.530
;; Package-X-Original-Version:  1.0
;; Package-requires: ((emacs "24.3"))
;; Package-Commit: f7041deccd9d03066c2fe41c3443c42a4713ac02
;; Keywords:         abbrev, convenience, wp, keyboard
;; URL:              https://www.github.com/Boruch_Baum/emacs-keypress-multi-event

;; This is free software: you can redistribute it and/or modify it under
;; the terms of the GNU General Public License as published by the Free
;; Software Foundation, either version 3 of the License, or (at your
;; option) any later version.

;; This software is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this software. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;;    This package provides a method to define multiple functions to
;;    be performed for the same keypress. You can use this as a
;;    convenience feature to toggle among several functions. It was
;;    originally written as the back-end for package `home-end',
;;    allowing those two keys to smartly cycle between moving POINT to
;;    the beginning/end of a line, the beginning/end of the window,
;;    the beginning/end of the buffer, and back to POINT.
;;
;;    Create a function which calls `keypress-multi-event' with a list
;;    of the functions to be associated with the keypress, and bind
;;    that keypress to that function. By default, subsequent
;;    keypresses cycle through the list, but you can change that
;;    behavior by optionally adding an index into the list as a second
;;    argument, or you could also directly manipulate the underlying
;;    buffer-local variable `keypress-multi-event--state'. Both
;;    methods are illustrated in package `home-end'.

;;; Code:

(defvar-local keypress-multi-event--state 0)

;;;###autoload
(defun keypress-multi-event (reactions &optional force-this-one)
  "Respond to repeated keyboard-events based upon the number of repetitions.

REACTIONS is a list of functions through which to cycle.

The optional arg FORCE-THIS-ONE is an integer index into REACTIONS.

This function was originally written to support functions
`home-end-home' and `home-end-end' in package `home-end.el'. See
there for a usage example."
  (if (or executing-kbd-macro defining-kbd-macro)
    (funcall (nth 0 reactions))
   (setq keypress-multi-event--state
     (or
       (when force-this-one
         (mod force-this-one (length reactions)))
       (if (eq this-command last-command)
         (mod (1+ keypress-multi-event--state) (length reactions))
        0)))
   (funcall (nth keypress-multi-event--state reactions))))

(provide 'keypress-multi-event)
;;; keypress-multi-event.el ends here
