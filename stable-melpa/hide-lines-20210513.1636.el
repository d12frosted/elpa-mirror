;;; hide-lines.el --- Commands for hiding lines based on a regexp

;; Filename: hide-lines.el
;; Description: Commands for hiding lines based on a regexp
;; Author: Mark Hulme-Jones <ture at plig cucumber dot net>
;; Maintainer: Joe Bloggs <vapniks@yahoo.com>
;; Version: 20130623.1701
;; Package-Version: 20210513.1636
;; Package-Commit: f0828c15e50db5eddb905de783e7683b04d1eca3
;; Last-Updated: Fri Nov 27 19:10:05 2015
;;           By: Joe Bloggs
;; URL: https://github.com/vapniks/hide-lines
;; Keywords: convenience
;; Compatibility: GNU Emacs 24.3.1
;; Package-Requires:
;;
;; Features that might be required by this library:
;;
;;
;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; The simplest way to make hide-lines work is to add the following
;; lines to your .emacs file:
;;
;; (autoload 'hide-lines "hide-lines" "Hide lines based on a regexp" t)
;; (global-set-key (kbd "C-c /") 'hide-lines)
;;
;; Now, when you type C-c /, you will be prompted for a regexp
;; (regular expression).  All lines matching this regexp will be
;; hidden in the buffer.
;;
;; Alternatively, you can type C-u C-c / (ie. provide a prefix
;; argument to the hide-lines command) to hide all lines that *do not*
;; match the specified regexp.  If you want to reveal previously hidden
;; lines you can use any other prefix, e.g. C-u C-u C-c /
;;



;;; Commands:
;;
;; Below is a complete list of commands:
;;
;;  `hide-lines'
;;    Hide lines matching the specified regexp.
;;    Keybinding: M-x hide-lines
;;  `hide-lines-not-matching'
;;    Hide lines that don't match the specified regexp.
;;    Keybinding: M-x hide-lines-not-matching
;;  `hide-lines-matching'
;;    Hide lines matching the specified regexp.
;;    Keybinding: M-x hide-lines-matching
;;  `hide-lines-show-all'
;;    Show all areas hidden by the filter-buffer command.
;;    Keybinding: M-x hide-lines-show-all
;;  `hide-blocks-not-matching'
;;    Hide text that is not between lines matching START-TEXT and END-TEXT.
;;    Keybinding: M-x hide-blocks-not-matching
;;  `hide-blocks-matching'
;;    Hide text that is between lines matching START-TEXT and END-TEXT.
;;    Keybinding: M-x hide-blocks-matching
;;
;;; Customizable Options:
;;
;; Below is a list of customizable options:
;;
;;  `hide-lines-reverse-prefix'
;;    If non-nil then `hide-lines' will call `hide-lines-matching' by default, and `hide-lines-not-matching' with a single prefix.
;;    default = nil

;;; Installation:
;;
;; Put hide-lines.el in a directory in your load-path, e.g. ~/.emacs.d/
;; You can add a directory to your load-path with the following line in ~/.emacs
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;; where ~/elisp is the directory you want to add
;; (you don't need to do this for ~/.emacs.d - it's added by default).
;;
;; Add the following to your ~/.emacs startup file.
;;
;; (require 'hide-lines)

;;; Change log:
;;
;; 2013/06/22 - Add namespace prefixes to functions and variables.
;;              Add licence and add to Marmalade repo.
;;              Alter hide-lines so that it can also show all lines
;;
;; 24/03/2004 - Incorporate fix for infinite loop bug from David Hansen.
;; 2021/01/17 - PRouleau: set hide-lines group parent to convenience,
;;              matching what packages states. Fixed checkdoc warnings.

;;; Acknowledgements:
;;
;; David Hansen.
;;

;;; TODO
;;
;;
;;

;;; Require


;;; Code:

(defgroup hide-lines nil
  "Commands for hiding lines based on a regexp."
  :group 'convenience)

(defvar-local hide-lines-invisible-areas ()
  "List of invisible overlays used by hidelines")

(defcustom hide-lines-reverse-prefix nil
  "Control what command `hide-lines' calls by default.

- If non-nil then `hide-lines' will call `hide-lines-matching' by default,
  and `hide-lines-not-matching' with a single prefix.
- Otherwise it's the other way round.

In either case a prefix arg with any value apart from 1 or 4 will
call `hide-lines-show-all'."
  :type 'boolean
  :group 'hide-lines)

(make-variable-buffer-local 'hide-lines-reverse-prefix)

(add-to-invisibility-spec 'hl)

;;;###autoload
(defun hide-lines (&optional arg)
  "Hide lines matching the specified regexp.
With prefix ARG of 4 (\\[universal-argument]) hide lines that do not match the
specified regexp.  With any other prefix arg, reveal all hidden lines."
  (interactive "p")
  (cond ((= arg 4) (call-interactively
                    (if hide-lines-reverse-prefix 'hide-lines-matching
                      'hide-lines-not-matching)))
        ((= arg 1) (call-interactively
                    (if hide-lines-reverse-prefix 'hide-lines-not-matching
                      'hide-lines-matching)))
        (t (call-interactively 'hide-lines-show-all))))

;;;###autoload
(defun hide-blocks (&optional arg)
  "Hide blocks of lines between matching regexps.
With prefix ARG of 4 (\\[universal-argument]) hide blocks that do not match the
specified regexps.  With any other prefix arg, reveal all hidden blocks."
  (interactive "p")
  (cond ((= arg 4) (call-interactively
                    (if hide-lines-reverse-prefix 'hide-blocks-matching
                      'hide-blocks-not-matching)))
        ((= arg 1) (call-interactively
                    (if hide-lines-reverse-prefix 'hide-blocks-not-matching
                      'hide-blocks-matching)))
        (t (call-interactively 'hide-lines-show-all))))

(defun hide-lines-invisible-p (start end)
  "Return non-nil if region between START and END is already hidden."
  (remove nil (mapcar (lambda (ov)
			(and (<= (overlay-start ov) start)
			     (>= (overlay-end ov) end)))
		      hide-lines-invisible-areas)))

(defun hide-lines-add-overlay (start end)
  "Add an overlay from `START' to `END' in the current buffer.
Push the overlay onto the `hide-lines-invisible-areas' list"
  (unless (hide-lines-invisible-p start end)
    (let ((overlay (make-overlay start end)))
      (push overlay hide-lines-invisible-areas)
      (unless (member 'hl buffer-invisibility-spec)
	(add-to-invisibility-spec 'hl))
      (overlay-put overlay 'invisible 'hl))))

;;;###autoload
(defun hide-lines-not-matching (search-text)
  "Hide lines that don't match the regexp SEARCH-TEXT."
  (interactive "MHide lines not matched by regexp: ")
  (set (make-local-variable 'line-move-ignore-invisible) t)
  (save-excursion
    (goto-char (point-min))
    (let ((start-position (point-min))
          (pos (re-search-forward search-text nil t)))
      (while pos
        (beginning-of-line)
        (hide-lines-add-overlay start-position (point))
        (forward-line 1)
        (setq start-position (point))
        (if (eq (point) (point-max))
            (setq pos nil)
          (setq pos (re-search-forward search-text nil t))))
      (hide-lines-add-overlay start-position (point-max)))))

;;;###autoload
(defun hide-lines-matching  (search-text)
  "Hide lines matching the regexp SEARCH-TEXT."
  (interactive "MHide lines matching regexp: ")
  (set (make-local-variable 'line-move-ignore-invisible) t)
  (save-excursion
    (goto-char (point-min))
    (let ((pos (re-search-forward search-text nil t))
          start-position)
      (while pos
        (beginning-of-line)
        (setq start-position (point))
        (end-of-line)
        (hide-lines-add-overlay start-position (+ 1 (point)))
        (forward-line 1)
        (if (eq (point) (point-max))
            (setq pos nil)
          (setq pos (re-search-forward search-text nil t)))))))

;;;###autoload
(defun hide-blocks-not-matching (start-text end-text)
  "Hide text that is not between lines matching START-TEXT and END-TEXT."
  (interactive (list (read-regexp "Regexp matching start lines of blocks: ")
		     (read-regexp "Regexp matching end lines of blocks: ")))
  (set (make-local-variable 'line-move-ignore-invisible) t)
  (save-excursion
    (goto-char (point-min))
    (let ((start-position (point-min))
          (pos (re-search-forward start-text nil t)))
      (while pos
        (beginning-of-line)
        (hide-lines-add-overlay start-position (point))
	(forward-line 1)
	(if (re-search-forward end-text nil t)
	    (beginning-of-line)
	  (goto-char (point-max)))
        (setq start-position (point))
        (if (eq (point) (point-max))
            (setq pos nil)
          (setq pos (re-search-forward start-text nil t))))
      (hide-lines-add-overlay start-position (point-max)))))

;;;###autoload
(defun hide-blocks-matching (start-text end-text)
  "Hide text that is between lines matching START-TEXT and END-TEXT."
  (interactive (list (read-regexp "Regexp matching start lines of blocks: ")
		     (read-regexp "Regexp matching end lines of blocks: ")))
  (set (make-local-variable 'line-move-ignore-invisible) t)
  (save-excursion
    (goto-char (point-min))
    (let ((pos (re-search-forward start-text nil t))
          start-position)
      (while pos
        (beginning-of-line)
        (setq start-position (point))
	(forward-line 1)
	(if (re-search-forward end-text nil t)
	    (beginning-of-line)
	  (goto-char (point-max)))
        (hide-lines-add-overlay start-position (point))
        (if (eq (point) (point-max))
            (setq pos nil)
          (setq pos (re-search-forward start-text nil t)))))))

;;;###autoload
(defun hide-lines-show-all ()
  "Unhide all hidden areas."
  (interactive)
  (mapc (lambda (overlay) (delete-overlay overlay))
        hide-lines-invisible-areas)
  (setq hide-lines-invisible-areas ())
  (remove-from-invisibility-spec 'hl))

(defun hide-lines-kill-hidden (&optional deletep)
  "Kill all hidden areas.
If called with prefix arg (or DELETEP is non-nil) dont save the
text to the kill ring (this is faster, but you can't retrieve the hidden text)."
  (interactive "P")
  (mapc (lambda (overlay)
	  (funcall (if deletep 'delete-region 'kill-region)
		   (overlay-start overlay)
		   (overlay-end overlay))
	  (delete-overlay overlay))
        hide-lines-invisible-areas)
  (setq hide-lines-invisible-areas ())
  (remove-from-invisibility-spec 'hl))

(provide 'hide-lines)

;; (magit-push)
;; (yaoddmuse-post "EmacsWiki" "hide-lines.el" (buffer-name) (buffer-string) "update")

;;; hide-lines.el ends here
