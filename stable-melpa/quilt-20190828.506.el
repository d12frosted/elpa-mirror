;;; quilt.el --- Minor mode for working with files in quilt  -*- lexical-binding: t; -*-

;; This file is not part of Emacs

;; Copyright (C) 2019 Jan Stranik <jan@stranik.org>
;; Copyright (C) 2011 Jari Aalto <jari.aalto@cante.net>
;; Copyright (C) 2005 Matt Mackall <mpm@selenic.com>

;; Author:	Matt Mackall <mpm@selenic.com>
;; Maintainer:	Jan Stranik <jan@stranik.org>
;; Version:	0.6
;; Package-Version: 20190828.506
;; Package-Commit: b56a1f1acc46cdf8655710e4c8f24f5f31f22c6a
;; Keywords:	extensions
;; Package-Requires: ((emacs "26.0"))
;; URL: https://github.com/jstranik/emacs-quilt

;; This program is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either version 2 of the License, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
;; for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <http://www.gnu.org/licenses/>.
;;
;; Visit <http://www.gnu.org/copyleft/gpl.html> for more information.

;; This software may be used and distributed according to the terms
;; of the GNU General Public License, incorporated herein by reference.
;;
;;; Commentary:
;;
;; This package makes it easy to work with quilt patches on a
;; repository When installed, the files under directory with quilt
;; patches will open as read only.  Users have to invoke `quilt-add`
;; command to edit the file and add it to the current patcheset.
;;
;; Provides M-x commands: quilt-push, quilt-push-all, quilt-pop,
;; quilt-pop-all, quilt-goto, quilt-top, quilt-find-file,
;; quilt-files, quilt-import, quilt-diff, quilt-new, quilt-applied,
;; quilt-add, quilt-edit-patch, quilt-patches, quilt-unapplied,
;; quilt-refresh, quilt-remove, quilt-edit-series, quilt-mode
;; 
;; Quilt manages a series of patches by keeping track of the changes
;; each of them makes.  They are logically organized as a stack, and
;; you can apply, un-apply, refresh them easily by traveling into the
;; stack (push/pop).
;; 
;;; History:
;;  0.6   2019 Jan Stranik <jan@stranik.org>
;;        - Introduced global quilt mode.
;;  0.5   2019 Jan Stranik <jan@stranik.org>
;;        - Packaged for melpa.
;;  0.4.1 2011 Jari Aalto <jari.aato@cante.net>
;;        - Fix nested defuns and lm-mnt.el QA issues in header.
;;  0.4   2005 Matt Mackall <mpm@selenic.com>
;;
;;; Code:

(defcustom quilt-edit-top-only t
  "Non-nill means allow editing of any quilt patch in the series."
  :type 'boolean
  :group 'quilt)


(defun quilt-find-dir (fn)
  "Find the top level dir for quilt from FN."
  (when fn
    (let ((d (file-name-directory fn)))
      (cond
       ((file-accessible-directory-p (concat d "/.pc"))
	d)
       ((equal fn d)
	nil)
       (t
	(quilt-find-dir (directory-file-name d)))))))

(defun quilt-dir (&optional fn)
  "Return root for quilt patches or nil if FN is not under quilt."
  (quilt-find-dir (if fn fn (or buffer-file-name
				dired-directory))))

(defun quilt--drop-dir (fn)
  (let* ((d (quilt-find-dir fn)))
    (substring fn (length d) (length fn))))

(defun quilt-p (&optional fn)
  "Check if the given file FN or current buffer is in a quilt tree."
  (if (quilt-dir fn) 't nil))

(defun quilt-save ()
  "Save all files under quilt system."
  (save-some-buffers nil 'quilt-p))

(defun quilt-owned-p (fn)
  "Check if the buffer FN is quilt controlled."
  (if (not fn)
      nil
    (let* ((pd (file-name-nondirectory
		(directory-file-name (file-name-directory fn)))))
      (and
       (not (string-match "\\(~$\\|\\.rej$\\)" fn))
       (not (equal pd "patches"))
       (not (equal pd ".pc"))
       (quilt-p fn)))))

(defun quilt-cmd (cmd &optional buf)
  "Execute a quilt command CMD at the top of the quilt tree.

If BUF is non-nill writes command output to that buffer."
  (let* ((d default-directory)
	 (qd (quilt-dir)))
    (unless qd (error "File %s is not part of quilt tree" (buffer-file-name)))
    (cd qd)
    (shell-command (concat "quilt " cmd) buf)
    (cd d)))

(defun quilt-cmd-to-string (cmd)
  "Execute a quilt command CMD at the top of the quilt tree for the given buffer."
  (let* ((d default-directory))
    (cd (quilt-dir))
    (let ((r (shell-command-to-string (concat "quilt " cmd))))
      (cd d) r)))

(defun quilt-applied-list ()
  "Return list of applied quilt patches."
  (split-string (quilt-cmd-to-string "applied") "\n"))

(defun quilt-file-list ()
  "Return list of files modified by the topmost patch."
  (split-string (quilt-cmd-to-string "files") "\n"))

(defun quilt-patch-list ()
  "Lists of patches managed by quilt."
  (split-string (quilt-cmd-to-string "series") "\n"))

(defun quilt-top-patch ()
  "Return top (current) quilt patch."
  (let ((top (quilt-cmd-to-string "top")))
    (if (equal top "")
	nil
	(substring top 0 -1))))

(defun quilt-to-alist (list n)
  (if list
      (cons (cons (car list) n)
	    (quilt-to-alist (cdr list) (+ 1 n)))
    nil))

(defun quilt-complete-list (p l)
  (completing-read p (quilt-to-alist l 0) nil t))

(defun quilt-editable-1 (file dirs qd)
  (if (car dirs)
      (if (file-exists-p (concat qd ".pc/" (car dirs) "/" file))
	  't
	(quilt-editable-1 file (cdr dirs) qd))
    nil))

(defun quilt-editable (f)
  (let* ((qd (quilt-dir))
	 (fn (quilt--drop-dir f)))
    (quilt-editable-1 fn
		      (if quilt-edit-top-only
			  (list (quilt-top-patch))
			(cdr (cdr (directory-files (concat qd ".pc/")))))
		      qd)))

(defun quilt-short-patchname ()
  (let* ((p (quilt-top-patch)))
    (if (not p)
	"none"
      (let* ((p2 (file-name-sans-extension p)))
	   (if (< (length p2) 10)
	       p2
	     (concat (substring p2 0 8) ".."))))))

(defvar-local quilt-mode-line nil)
(defun quilt-update-modeline ()
  "Update quilt modeline."
  (interactive)
  (setq quilt-mode-line
	(concat " Q:" (quilt-short-patchname)))
  (force-mode-line-update))

(defun quilt-revert-1 (buf)
  (with-current-buffer buf
    (if (quilt-owned-p buffer-file-name)
	(quilt-update-modeline))
    (if (and (quilt-owned-p buffer-file-name)
	     (not (buffer-modified-p)))
	(revert-buffer 't 't))))

(defun quilt-revert-list (buffers)
  (if (not (cdr buffers))
      nil
    (quilt-revert-1 (car buffers))
    (quilt-revert-list (cdr buffers))))

(defun quilt-revert ()
  (quilt-revert-list (buffer-list)))

(defun quilt-push (arg)
  "Push next patch, force with prefix argument.

ARG if non-nil forces push."
  (interactive "p")
  (quilt-save)
  (if (> arg 1)
      (quilt-cmd "push -f" "*quilt*")
    (quilt-cmd "push -q"))
  (quilt-revert))

(defun quilt-pop (arg)
  "Pop top patch, force with prefix argument.

ARG if non-nil forces push."
  (interactive "p")
  (quilt-save)
  (if (> arg 1)
      (quilt-cmd "pop -f")
    (quilt-cmd "pop -q"))
  (quilt-revert))

(defun quilt-push-all (arg)
  "Push all remaining patches.

ARG if non-nil forces push."
  (interactive "p")
  (quilt-save)
  (if (> arg 1)
      (quilt-cmd "push -f" "*quilt*")
    (quilt-cmd "push -qa"))
  (quilt-revert))

(defun quilt-pop-all (arg)
  "Pop all applied patches, force with prefix arg.

ARG if non-nil forces push."
  (interactive "p")
  (quilt-save)
  (if (> arg 1)
      (quilt-cmd "pop -af")
    (quilt-cmd "pop -qa"))
  (quilt-revert))

(defun quilt-goto ()
  "Go to a specified patch."
  (interactive)
  (let* ((arg (quilt-complete-list "Goto patch: " (quilt-patch-list))))
       (quilt-save)
       (if (file-exists-p (concat (quilt-dir) ".pc/" arg))
	   (quilt-cmd (concat "pop -q " arg) "*quilt*")
	 (quilt-cmd (concat "push -q " arg) "*quilt*")))
  (quilt-revert))

(defun quilt-top ()
  "Display topmost patch."
  (interactive)
  (quilt-cmd "top"))

(defun quilt-find-file ()
  "Find a file in the topmost patch."
  (interactive)
  (find-file (concat (quilt-dir)
		     (quilt-complete-list "File: " (quilt-file-list)))))

(defun quilt-files ()
  "Display files in topmost patch."
  (interactive)
  (quilt-cmd "files"))

(defun quilt-import (file patch-name)
  "Imports a patch from file FILE into the quilt.

PATCH-NAME.patch is name under which quilt stores the patch."
  (interactive "fPatch to import: \nsPatch name: ")
  (quilt-cmd (concat "import -n " (shell-quote-argument patch-name) ".patch " (shell-quote-argument file))))

(defconst quilt--diff-buffer-name "*quilt diff*")
(defun quilt-diff ()
  "Display diff for the top patchset."
  (interactive)
  (quilt-save)
  (let ((diff (get-buffer-create quilt--diff-buffer-name))
	(inhibit-read-only t))
    (quilt-cmd "diff" diff)
    
    (with-current-buffer diff
      (diff-mode)
      (read-only-mode))
    (message nil) 			; clear messages
    (pop-to-buffer diff)))

(defun quilt-new (f)
  "Create a new patch called F.

The extension .patch is automatically added to the patch name."
  (interactive "sPatch name:")
  (quilt-save)
  (quilt-cmd (concat "new " (shell-quote-argument f) ".patch"))
  (quilt-revert))

(defun quilt-init (root)
  "Create a new quilt patch repository at directory ROOT."
  (interactive "DQuilt root directory: ")
  (let ((default-directory root))
    (shell-command "quilt init")))

(defun quilt-applied ()
  "Show applied patches."
  (interactive)
  (quilt-cmd "applied" "*quilt*"))

(defun quilt-add (buf)
  "Add a file associtaed with buffer BUF to the current patch."
  (interactive "@b")
  (quilt-cmd (concat "add " (shell-quote-argument (quilt--drop-dir (buffer-file-name (get-buffer buf))))))
  (quilt-revert))

(defun quilt-edit-patch ()
  "Edit the topmost patch."
  (interactive)
  (quilt-save)
  (find-file (concat (quilt-dir) "/patches/" (quilt-top-patch))))

(defun quilt-patches ()
  "Show which patches modify the current buffer."
  (interactive)
  (quilt-cmd (concat "patches " (quilt--drop-dir buffer-file-name))))

(defun quilt-unapplied ()
  "Display unapplied patch list."
  (interactive)
  (quilt-cmd "unapplied" "*quilt*"))

(defun quilt-refresh ()
  "Refresh the current patch."
  (interactive)
  (quilt-save)
  (quilt-cmd "refresh"))

(defun quilt-remove ()
  "Remove a file from the current patch and revert it."
  (interactive)
  (let* ((f (quilt--drop-dir buffer-file-name)))
    (if (y-or-n-p (format "Really drop %s? " f))
	(quilt-cmd (concat "remove " f))))
  (quilt-revert))

(defun quilt-edit-series ()
  "Edit the patch series file."
  (interactive)
  (find-file (concat (quilt-find-dir buffer-file-name) "/patches/series")))

(defvar quilt-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m "\C-c/t" 'quilt-top)
    (define-key m "\C-c/f" 'quilt-find-file)
    (define-key m "\C-c/F" 'quilt-files)
    (define-key m "\C-c/d" 'quilt-diff)
    (define-key m "\C-c/p" 'quilt-push)
    (define-key m "\C-c/o" 'quilt-pop)
    (define-key m "\C-c/P" 'quilt-push-all)
    (define-key m "\C-c/O" 'quilt-pop-all)
    (define-key m "\C-c/g" 'quilt-goto)
    (define-key m "\C-c/A" 'quilt-applied)
    (define-key m "\C-c/n" 'quilt-new)
    (define-key m "\C-c/d" 'quilt-diff)
    (define-key m "\C-c/i" 'quilt-import)
    (define-key m "\C-c/a" 'quilt-add)
    (define-key m "\C-c/e" 'quilt-edit-patch)
    (define-key m "\C-c/m" 'quilt-patches)
    (define-key m "\C-c/u" 'quilt-unapplied)
    (define-key m "\C-c/r" 'quilt-refresh)
    (define-key m "\C-c/R" 'quilt-remove)
    (define-key m "\C-c/s" 'quilt-edit-series)
    m))


;;;###autoload
(define-minor-mode quilt-mode
  "Quilt minor mode. With positive arg, enable quilt-mode.

\\{quilt-mode-map}
"
  :init-value nil
  :lighter quilt-mode-line
  :keymap 'quilt-mode-map
  (when quilt-mode
    (unless (quilt-p) (error "File is not part of quilt tree. Call \"quilt init\" first."))
      (let* ((f buffer-file-name))
	(if (quilt-owned-p f)
	    (if (not (quilt-editable f))
		(read-only-mode)
	      (read-only-mode 0)))
	(quilt-update-modeline))))


(defun quilt--hook ()
  "Enable quilt mode for quilt-controlled files."
  (if (buffer-file-name)
      (if (quilt-p) (quilt-mode 1))))

;;;###autoload
(define-globalized-minor-mode global-quilt-mode quilt-mode quilt--hook)

;;;###autoload
(progn
  (global-quilt-mode 1))

(provide 'quilt)
;;; quilt.el ends here
