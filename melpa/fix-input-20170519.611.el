;;; fix-input.el --- Make input methods play nicely with alternative keyboard layout on OS level -*- lexical-binding: t; -*-
;;
;; Copyright © 2016–2017 Mark Karpov <markkarpov92@gmail.com>
;;
;; Author: Mark Karpov <markkarpov92@gmail.com>
;; URL: https://github.com/mrkkrp/fix-input
;; Package-Version: 20170519.611
;; Package-Commit: a70edfa7880ff9b082f358607d2a9ad6a8dcc8f3
;; Version: 0.1.1
;; Package-Requires: ((emacs "24.4"))
;; Keywords: input method
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation, either version 3 of the License, or (at your
;; option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
;; Public License for more details.
;;
;; You should have received a copy of the GNU General Public License along
;; with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Let's suppose that you have switched to Dvorak or Colemak.  Chances are
;; you're going to use that layout everywhere, not only in Emacs (we still
;; need to leave Emacs sometimes and use other programs), so you setup it on
;; OS level or maybe you even have hardware Dvorak keyboard.  You adapt to
;; this new layout and everything is OK.
;;
;; Now suppose that you need to input non-Latin text and for that you
;; naturally need to activate an input method in Emacs.  The nightmare
;; begins: input methods in Emacs translate Latin characters as if they are
;; on a traditional QWERTY layout.  So now the input method you used before
;; does not work anymore.
;;
;; One solution is to define a new custom input method and call it for
;; example `dvorak-russian'.  But that is not a general solution to the
;; problem—we want to be able to make any existing input method work just
;; the same with any Latin layout on OS level.  This package generates
;; “fixed” input methods knowing input method that corresponds to layout on
;; OS level and input method you want to fix.  And I want to tell you—it's a
;; win.

;;; Code:

(require 'cl-lib)
(require 'quail)

;;;###autoload
(defun fix-input (base-method old-method new-method)
  "Adjust an input method for an alternative Latin layout on OS level.

In fact, entirely new input method is generated.  BASE-METHOD
describes the new alternative layout on OS level.  OLD-METHOD
will be copied as NEW-METHOD so the layout in which keys are laid
on the keyboard when OLD-METHOD is used with QWERTY will be the
same when NEW-METHOD is used with that new alternative layout.

BASE-METHOD, OLD-METHOD, and NEW-METHOD are strings—names of
input methods, they all must be different.

This function uses Quail (and assumes that all input methods are
defined with it), but it does not select the new package."
  (when (or (string= base-method old-method)
            (string= base-method new-method)
            (string= new-method  old-method))
    (error "All input methods must be different"))
  (fix-input--load-libs base-method)
  (fix-input--load-libs old-method)
  (let* ((base-map (nth 2 (quail-package base-method)))
         (old (quail-package old-method))
         (old-title (nth 1 old))
         (old-map (nth 2 old))
         (old-stuff (nthcdr 3 old))
         (new-map
          (mapcar
           (lambda (item)
             (when item
               (cl-destructuring-bind (ch . val) item
                 ;; NOTE The approach may be brittle, since it does not take
                 ;; into account all possible formats of the translation map
                 ;; (described in the docs for `quile-map-p'), only for the
                 ;; format I have encountered in practice with input methods
                 ;; that are of interest for me. If this does not work for
                 ;; you, open an issue on GitHub issue tracker of the
                 ;; project (or better yet open a PR if you can fix it
                 ;; yourself).
                 (cons
                  (or (elt (elt (cadr (assoc ch base-map)) 0) 0) ch)
                  (cl-copy-list val)))))
           old-map))
         (oldi (assoc old-method input-method-alist)))
    (quail-add-package
     (append
      (list new-method old-title new-map)
      (cl-copy-list old-stuff)))
    (let ((slot (assoc new-method input-method-alist))
          (val  (cl-copy-list (cdr oldi))))
      (if slot
          (setcdr slot val)
        (push (cons new-method val)
              input-method-alist))))
  nil)

(defun fix-input--load-libs (input-method)
  "Load libraries for the specified INPUT-METHOD, but do not activate it.

If INPUT-METHOD is not defined, signal an error.  Return the list
of libraries loaded."
  (let ((slot (assoc input-method input-method-alist)))
    (unless slot
      (error "No such input method: ‘%s’" input-method))
    (mapc
     (lambda (library)
       (unless (load library t)
         (error "Having trouble loading ‘%s’" library)))
     (nthcdr 5 slot))))

(provide 'fix-input)

;;; fix-input.el ends here
