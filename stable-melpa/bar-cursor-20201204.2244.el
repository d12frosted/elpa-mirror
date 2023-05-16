;;; bar-cursor.el --- package used to switch block cursor to a bar

;; This file is not part of Emacs

;; Copyright (C) 2001 by Joseph L. Casadonte Jr.
;; Copyright (C) 2013-2021 by Andrew Johnson
;; Author:          Joe Casadonte (emacs@northbound-train.com)
;; Maintainer:      Andrew Johnson (andrew@andrewjamesjohnson.com)
;; Created:         July 1, 2001
;; Keywords:        files
;; Package-Version: 20201204.2244
;; Package-Commit: 78f195b6db63459033c4f1c7e7add5d82f3ce424
;; URL: https://github.com/ajsquared/bar-cursor
;; Version: 2.0

;; COPYRIGHT NOTICE

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:
;;
;;  Simple package to convert the block cursor into a bar cursor.  In
;;  overwrite mode, the bar cursor changes back into a block cursor.
;;  This is a global minor mode.

;;; Installation:
;;
;; 1. Place bar-cursor.el somewhere on your Emacs load path.
;; 2. Add (require 'bar-cursor) to your .emacs
;; 3. Add (bar-cursor-mode 1) to your .emacs
;;
;; bar-cursor.el is also available in Melpa.  See
;; https://github.com/melpa/melpa#usage for information on using
;; Melpa.  Then you can run M-x package-install bar-cursor to install
;; it.

;;; Usage:
;;
;;  M-x `bar-cursor-mode'
;;      Toggles bar-cursor-mode on & off.  Optional arg turns
;;      bar-cursor-mode on iff arg is a positive integer.

;;; Credits:
;;
;;  The basis for this code comes from Steve Kemp by way of the
;;  NTEmacs mailing list.

;;; Comments:
;;
;;  Any comments, suggestions, bug reports or upgrade requests are
;;  welcome.  Please create issues or send pull requests via Github at
;;  https://github.com/ajsquared/bar-cursor.

;;; Change Log:
;;
;;  See https://github.com/ajsquared/bar-cursor/commits/master

;;; Code:

;;; **************************************************************************
;;; ***** mode definition
;;; **************************************************************************

;;;###autoload
(define-minor-mode bar-cursor-mode
  "Toggle use of 'bar-cursor-mode'.

This global minor mode changes cursor to a bar cursor in insert
mode, and a block cursor in overwrite mode."
  :lighter " bar"
  :init-value nil
  :keymap nil
  :global t

  (add-hook 'overwrite-mode-hook 'bar-cursor-set-cursor)
  (add-hook 'after-make-frame-functions 'bar-cursor-set-cursor)
  (bar-cursor-set-cursor))

;;; **************************************************************************
;;; ***** utility functions
;;; **************************************************************************

(defun bar-cursor-set-cursor-type (cursor &optional frame)
  "Set the ‘cursor-type’ for the named frame.

CURSOR is the name of the cursor to use (bar or block -- any others?).
FRAME is optional frame to set the cursor for; current frame is used
if not passed in."
  (interactive)
  (unless frame
	  (setq frame (selected-frame)))

  ;; Do the modification.
  (modify-frame-parameters frame
	(list (cons 'cursor-type cursor))))

(defun bar-cursor-set-cursor (&optional frame)
  "Set the ‘cursor-type’ according to the insertion mode.

FRAME is optional frame to set the cursor for; current frame is used
if not passed in."
  (if (and bar-cursor-mode (not overwrite-mode))
	  (bar-cursor-set-cursor-type 'bar frame)
	(bar-cursor-set-cursor-type 'block frame)))

(provide 'bar-cursor)

;;; bar-cursor.el ends here
