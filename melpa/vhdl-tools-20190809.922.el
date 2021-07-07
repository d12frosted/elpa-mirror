;;; vhdl-tools.el --- Utilities for navigating vhdl sources. -*- lexical-binding: t; -*-

;; Based on `vhdl-goto-def' at `http://www.emacswiki.org/emacs/vhdl-goto-def.el'

;; Copyright (C) 2003 Free Software Foundation, Inc.
;; Copyright (C) 2015-2019 Cayetano Santos

;; Original author:  wandad guscheh <wandad.guscheh@fh-hagenberg.at>
;; Author:           Cayetano Santos
;; Keywords: languages, convenience
;; Package-Version: 20190809.922
;; Package-Commit: 5202db4c6a511a90a950a723293d11d55ec05264
;; Filename: vhdl-tools.el
;; Description: Utilities for navigating vhdl sources.
;; URL: https://github.com/csantosb/vhdl-tools/wiki
;; Compatibility: GNU Emacs >= 26.2
;; Version: 6.2
;; Package-Requires: ((ggtags "0.8.13") (emacs "26.2") (helm-rg "0.1") outshine)

;;; License:
;;
;; This file is NOT part of GNU Emacs.
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; `vhdl-tools' provide a minor mode based intended to complete the great `vhdl-mode'.
;; It adds an extra layer of functionality on top of the later, extensively
;; using `ggtags' to manage a vhdl project. `vhdl-tools' relies on `helm',
;; `imenu' and `outshine' features to ease navigating vhdl
;; sources.  Additionally, it provides `vOrg' mode too, which benefits of all
;; `Org' features.

;;; Install:
;;
;; To install, proceed as usual: add to path and require after loading `vhdl-mode'
;;
;; (with-eval-after-load 'vhdl-mode
;;   (add-to-list 'load-path "...")
;;   (require 'vhdl-tools))
;;
;; or install from Melpa
;;
;;   M-x package-install RET vhdl-tools
;;
;; Then, activate the minor mode by completing the `vhdl-mode' hook.
;;
;; (add-hook 'vhdl-mode-hook
;;	  (lambda ()
;;	    (vhdl-tools-mode 1)))

;;; Use:
;;
;; Have a look at customization possibilities with \M-x customize-group `vhdl-tools'.
;;
;; For details, refer to  https://github.com/csantosb/vhdl-tools/wiki
;;
;; An example configuration file may be found at https://github.com/csantosb/vhdl-tools/wiki/Setup#example-configuration-file

;;; Todo:

;;; Code:

(eval-when-compile
  (require 'ggtags)
  (require 'helm-rg)
  (require 'outshine))

(require 'vhdl-mode)
(require 'vc)

;;; Groups

(defgroup vhdl-tools nil "Some customizations of vhdl-tools package"
  :group 'local)

(defgroup vhdl-tools-vorg nil "Some customizations of vhdl-tools vorg package"
  :group 'local)

;;; Variables

;;;; User Variables

;;;;; vOrg

(defcustom vhdl-tools-vorg-src-vhdl-dir nil
  "Stores the relative placement of vhdl code with respect to vorg sources.
When nil, both share same directory."
  :type 'string :group 'vhdl-tools-vorg)

(defcustom vhdl-tools-vorg-src-vorg-dir nil
  "Stores the relative placement of vorg sources with respect to vhdl code.
When nil, both share same directory."
  :type 'string :group 'vhdl-tools-vorg)

(defcustom vhdl-tools-vorg-tangle-comment-format-beg "@@@"
  "Variable to assign to `org-babel-tangle-comment-format-beg' during `vorg' tangling."
  :type 'string :group 'vhdl-tools-vorg)

(defcustom vhdl-tools-vorg-tangle-comment-format-end "@@@"
  "Variable to assign to `org-babel-tangle-comment-format-end' during `vorg' tangling."
  :type 'string :group 'vhdl-tools-vorg)

(defcustom vhdl-tools-vorg-tangle-comments-link nil
  "Flag to force set the comments:link header in vhdl src blocks."
  :type 'boolean :group 'vhdl-tools-vorg)

(defcustom vhdl-tools-vorg-tangle-header-argument-var nil
  "Variable used to filter code blocks to be tangled."
  :type 'boolean :group 'vhdl-tools-vorg)

;;;;; tools

(defcustom vhdl-tools-max-lines-disable-features 1500
  "Disable slower `vhdl-tools' features in buffers beyond this number of lines."
  :type 'boolean :group 'vhdl-tools)

(defcustom vhdl-tools-verbose nil
  "Make `vhdl-tools' verbose."
  :type 'boolean :group 'vhdl-tools)

(defcustom vhdl-tools-allowed-chars-in-signal "a-z0-9A-Z_"
  "Regexp with allowed characters in signal, constant or function.
Needed to determine end of name."
  :type 'string :group 'vhdl-tools)

(defcustom vhdl-tools-imenu-regexp "^\\s-*--\\s-\\([*]\\{1,8\\}\\s-.+\\)"
  "Regexp ..."
  :type 'string :group 'vhdl-tools)

(defcustom vhdl-tools-outline-regexp "^\\s-*--\\s-\\([*]\\{1,8\\}\\)\\s-\\(.*\\)$"
  "Regexp to be used as `outline-regexp' when `vhdl-tools' minor mode is active."
  :type 'string :group 'vhdl-tools)

(defcustom vhdl-tools-use-outshine nil
  "Flag to activate `outshine' when `vhdl-tools' minor mode in active."
  :type 'boolean :group 'vhdl-tools)

(defcustom vhdl-tools-manage-folding nil
  "Flag to allow remapping auto folding when jumping around."
  :type 'boolean :group 'vhdl-tools)

(defcustom vhdl-tools-recenter-nb-lines 10
  "Number of lines from top of scren to recenter point after jumping to new location."
  :type 'integer :group 'vhdl-tools)

(defcustom vhdl-tools-save-before-imenu t
  "Save current buffer before calling imenu."
  :type 'boolean :group 'vhdl-tools)

;;;; Internal Variables

(defconst vhdl-tools-vorg-vhdl-align-alist
  (reverse
   (let ((orig-alist (copy-alist vhdl-align-alist))
	 (new-vhdl-align-alist nil))
     ;;(message (format "\n\n" ))
     (while orig-alist
       (let* ((element (nth 0 orig-alist))
	      (element-content (cons 'vhdl-tools-mode
				     (cdr element))))
	 (setq new-vhdl-align-alist
	       (push element-content new-vhdl-align-alist))
	 (setq orig-alist (cdr orig-alist))))
     new-vhdl-align-alist)))

(defvar vhdl-tools--jump-into-module-name nil)

(defvar vhdl-tools--store-link-link nil)

(defvar vhdl-tools--follow-links-tag nil)

(defvar vhdl-tools--follow-links-tosearch nil)

(defvar vhdl-tools--currently-publishing nil
  "To be set to t when publishing to avoid problems.")

(defvar vhdl-tools--ggtags-available (and (require 'ggtags)
					  (require 'helm-rg)
					  (executable-find "global")
					  t)
  "Sets availability of ggtags feature following installed packages.")

(defvar vhdl-tools--imenu-available (and (require 'imenu)
					 t)
  "Sets availability of imenu feature following installed packages.")

(defvar vhdl-tools--outshine-available (and (require 'outshine)
					    t)
  "Sets availability of outshine feature following installed packages.")

;;; Helper

;; Ancillary, internal functions

(defun vhdl-tools--cleanup-tangled ()
  "Make invisible reference comments after tangling."
  (interactive)
  (save-excursion
    (when vhdl-tools-use-outshine
      (outline-show-all)
      (goto-char (point-min)))
    (while (re-search-forward (format "^-- %s.*$" vhdl-tools-vorg-tangle-comment-format-beg) nil t nil)
      (let ((endp (point))
	    (begp (progn (beginning-of-line) (point))))
	(overlay-put (make-overlay begp endp)
		     'invisible
		     (intern "vhdl-tangled")))
      (forward-line))
    (add-to-invisibility-spec 'vhdl-tangled)
    (vhdl-tools--fold)))

(defun vhdl-tools--fold ()
  "Fold to current heading level."
  (when (and vhdl-tools-use-outshine
	     vhdl-tools-manage-folding
	     ;; only when heading exists
	     (save-excursion
	       (beginning-of-line)
	       (or (outline-on-heading-p)
		   (save-excursion
		     (re-search-backward (concat "^\\(?:" outline-regexp "\\)")
					 nil t)))))
    (save-excursion
      (when (< (count-lines 1 (point-max)) vhdl-tools-max-lines-disable-features)
	(outline-hide-sublevels 5))
      (outline-back-to-heading nil)
      (outline-show-entry))))

(defun vhdl-tools--push-marker ()
  "Push tag (stolen from elisp-slime-nav.el)."
  (if (fboundp 'xref-push-marker-stack)
      (xref-push-marker-stack)
    (with-no-warnings
      (ring-insert find-tag-marker-ring (point-marker))))
  (setq ggtags-tag-ring-index nil))

(defun vhdl-tools--get-name ()
  "Extract word at current position."
  (thing-at-point 'symbol t))

(defun vhdl-tools--get-entity-or-package-name ()
  "Return name of entity / package or empty string if nothing found."
  (save-excursion
    (goto-char (point-min))
    (if (re-search-forward "^ *\\(entity\\|package\\) +" nil t nil)
	(vhdl-tools--get-name)
      "")))

(defun vhdl-tools--imenu-with-initial-minibuffer (str)
  "Imenu pre filled with `STR'."
  (funcall `(lambda ()
	      (interactive)
	      (minibuffer-with-setup-hook
		  (lambda () (insert (format "%s " ,str)))
		(call-interactively 'helm-semantic-or-imenu)))))

(defun vhdl-tools--post-jump-function ()
  "To be called after jumping to recenter, indent, etc."
  (when vhdl-tools-manage-folding
    (recenter-top-bottom vhdl-tools-recenter-nb-lines))
  (back-to-indentation))

(defun vhdl-tools-vorg--post-jump-function ()
  "To be called after jumping to recenter, indent, etc."
  (when vhdl-tools-manage-folding
    (recenter-top-bottom vhdl-tools-recenter-nb-lines))
  (back-to-indentation))

(defun vhdl-tools-vorg--get-vhdl-file (orgfile)
  "Return the sibling vhdl code of `ORGFILE'.
`ORGFILE' is the filename without extension."
  (if (and vhdl-tools-vorg-src-vhdl-dir
	   (file-exists-p vhdl-tools-vorg-src-vhdl-dir))
      (format "%s/%s.vhd" vhdl-tools-vorg-src-vhdl-dir orgfile)
    (format "%s.vhd" orgfile)))

(defun vhdl-tools--get-vorg-file (vhdlfile)
  "Return the sibling vorg source file of `VHDLFILE'.
`VHDLFILE' is the filename without extension."
  (if (and vhdl-tools-vorg-src-vorg-dir
	   (file-exists-p vhdl-tools-vorg-src-vorg-dir))
      (format "%s/%s.org" vhdl-tools-vorg-src-vorg-dir vhdlfile)
    (format "%s.vhd" (file-name-base vhdlfile))))

;;; Feature: misc

;;;; Beautify

(defun vhdl-tools-beautify-region (arg)
  "Call beautify-region but auto activate region first.
With a prefix ARG, fall back to default behaviour."
  (interactive "P")
  (if (equal arg '(4))
      (call-interactively 'vhdl-beautify-region)
    (save-excursion
      (when (not (region-active-p))
	(mark-paragraph))
      (call-interactively 'vhdl-beautify-region))))

;;;; Get to first

;; Utility to jump to first time a symbol appears on file

(defun vhdl-tools-getto-first ()
  "Jump to first occurrence of symbol at point.
When no symbol at point, move point to indentation."
  (interactive)
  ;; when no symbol at point, just get back to bol
  (if (not (vhdl-tools--get-name))
      (back-to-indentation)
    ;; else, get there
    (progn
      (vhdl-tools--push-marker)
      (let ((vhdl-tools-getto-first-name (vhdl-tools--get-name)))
	(goto-char (point-min))
	(search-forward-regexp vhdl-tools-getto-first-name nil t)
	(backward-word)
	(vhdl-tools--fold)
	(when vhdl-tools-manage-folding
	  (recenter-top-bottom vhdl-tools-recenter-nb-lines))))))

;;; Feature: Jumping

;;;; Get definition

(defun vhdl-tools-get-buffer (entity-or-package-name)
  "Return buffer where ENTITY-OR-PACKAGE-NAME is found."
  (save-excursion
    (let ((thisfile (format "%s.vhd" entity-or-package-name)))
      ;; if open buffer exists, return it
      (if (get-buffer thisfile)
	  (get-buffer thisfile)
	;; if file exist, open it and return buffer
	(if (file-exists-p thisfile)
	    (progn
	      (find-file-noselect thisfile)
	      (get-buffer thisfile))
	  ;; search over all existing buffers
	  (let ((current-buffer-list (buffer-list))
		(counter 0)
		found)
	    ;; loop over all buffers
	    (while (and (nth counter current-buffer-list)
			(not found))
	      (set-buffer (nth counter current-buffer-list))
	      (if (equal entity-or-package-name (vhdl-tools--get-entity-or-package-name))
		  (setq found t)
		(setq counter (1+ counter))))
	    (if found
		(nth counter current-buffer-list)
	      nil)))))))

(defun vhdl-tools-package-names ()
  "Return a list of strings of all used packages or nil if nothing found.
Only use the form work.NAME.something."
  (save-excursion
    (let ((packages))
      ;; search for packages in current buffer
      (goto-char (point-min))
      (while (re-search-forward "^ *use  *work\." nil t nil)
	(forward-char)
	(when (not (member (vhdl-tools--get-name) packages))
	  (push (vhdl-tools--get-name) packages)))
      ;; search in all open buffers
      (dolist (var (buffer-list))
	(set-buffer var)
	(goto-char (point-min))
	(while (re-search-forward "^ *use  *work\." nil t nil)
	  (forward-char)
	  (when (not (member (vhdl-tools--get-name) packages))
	    (push (vhdl-tools--get-name) packages))))
      ;; search in all files in current dir
      (dolist (var (file-expand-wildcards "*.vhd"))
	(when (not (get-buffer var))
	  (find-file-noselect var))
	(set-buffer var)
	(goto-char (point-min))
	(while (re-search-forward "^ *use  *work\." nil t nil)
	  (forward-char)
	  (when (not (member (vhdl-tools--get-name) packages))
	    (push (vhdl-tools--get-name) packages))))
      packages)))

(defun vhdl-tools-process-file (name)
  "Search within a package or a vhdl file for NAME.
Test if it is a type definition or not."
  (let ((found nil)
	should-be-in-entity
	beginning-of-entity-port
	end-of-entity
	end-of-entity-port
	apoint)
    (save-excursion
      (goto-char (point-min))
      ;; search for entity ... is line
      (setq beginning-of-entity-port
	    (re-search-forward
	     (concat "^[ \t]*entity[ \n\t]+[" vhdl-tools-allowed-chars-in-signal "]+[ \n\t]+is") nil t nil))
      (if beginning-of-entity-port
	  (progn
	    (setq end-of-entity (save-excursion (re-search-forward "^[ \t]*end")))
	    (re-search-forward "port[ \n\t]*(" nil t nil)
	    (setq end-of-entity-port (progn (up-list) (point)))
	    (goto-char (point-min))
	    (setq should-be-in-entity (re-search-forward (concat " +" name "[ \n\t]+") nil t nil))
	    (if (and should-be-in-entity
		     (< beginning-of-entity-port should-be-in-entity)
		     (> end-of-entity-port should-be-in-entity)
		     (< (save-excursion (re-search-forward ":" nil t nil))
			(save-excursion (re-search-forward "\n" nil t nil)))
		     (< (point)
			(save-excursion (re-search-forward ":" nil t nil)))
		     (< end-of-entity-port
			end-of-entity))
		(setq found (point)))))
      (goto-char (point-min))
      (while (and (not found)
		  (re-search-forward "^ *\\(component\\|function\\|procedure\\|constant\\|file\\|type\\|subtype\\)[ \n\t]+" nil t nil))
	(if (equal name (vhdl-tools--get-name))
	    (setq found (point))))
      (goto-char (point-min))
      (while (and (not found)
		  (re-search-forward "^[ \t]*signal[ \n\t]+" nil t nil))
	(if (equal name (vhdl-tools--get-name))
	    (setq found (point))
	  (while (> (save-excursion (search-forward ":" nil t nil))
		    (if (setq apoint (save-excursion (search-forward "," nil t nil))) apoint 0))
	    (search-forward "," nil t nil)
	    (if (equal name (vhdl-tools--get-name))
		(setq found (point)))))))
    (if found found nil)))

(defun vhdl-tools-goto-type-def ()
  "Read word at point and try to find corresponding signal or type definition.
This function first tries to find a signal or type definition in the buffer from
where the function have been called.  It can only jump to signal, constant,
type and subtype definitions.  Works also for signals in an entity (in and out
ports, function will then jump to the entity).  To go back to the point where
the function has been called press.  If there was nothing found, it reads the
packages used, and works through all opened buffers to find packages used in
the vhdl file.  If a definition has been found in a package, package will be
displayed.  To go back to original vhdl file press."
  (interactive)
  (if (not ggtags-mode)
      (message "[VHDL Tools] ggtags feature not enabled.")
    (progn
      ;; when no symbol at point, move forward to next symbol
      (vhdl-tools--push-marker)
      (when (not (vhdl-tools--get-name))
	(back-to-indentation))
      ;; check if found definition in calling file
      (if (not (setq found (vhdl-tools-process-file (vhdl-tools--get-name))))
	  ;; no definition found in calling file found
	  (let ((to-search-for (vhdl-tools--get-name))
		(package-list (vhdl-tools-package-names))
		(counter 0)
		found
		package-buffer)
	    ;; loop over all packages _____________________________________
	    (while (and (not found)
			(nth counter package-list))
	      (setq package-buffer
		    (vhdl-tools-get-buffer (nth counter package-list)))
	      (with-current-buffer package-buffer
		(setq found (vhdl-tools-process-file to-search-for)))
	      (setq counter (1+ counter)))
	    ;; loop over ____________________________________________________
	    (if found
		(progn
		  (switch-to-buffer package-buffer)
		  (goto-char found)
		  (vhdl-tools--post-jump-function))
	      (message "sorry, no corresponding definition found")))
	;; found in current file
	(progn
	  (goto-char found)
	  (vhdl-tools--post-jump-function))))))

;;;; Jump into module

(defun vhdl-tools-jump-into-module()
  "When point is at an instance, jump into the module.
Additionally, move point to signal at point.
Declare a key-bind to get back to the original point."
  (interactive)
  (if (not ggtags-mode)
      (message "[VHDL Tools] ggtags feature not enabled.")
    (progn
      (back-to-indentation)
      ;; when nil, do nothing
      (when (vhdl-tools--get-name)
	;; necessary during hook (see later)
	(setq vhdl-tools--jump-into-module-name (vhdl-tools--get-name))
	(vhdl-tools--push-marker)
	(save-excursion
	  ;; case of component instantiation
	  ;; locate component name to jump into
	  (if (search-backward-regexp "\\(?:\\(?:generic\\|port\\) map\\)" nil t)
	      (progn
		(search-backward-regexp "[a-zA-Z0-9]+ *: +" nil t)
		(back-to-indentation)
		(search-forward-regexp " *: +\\(entity work.\\)?" nil t))
	    ;; case of component declaration
	    (progn
	      (search-backward-regexp " component ")
	      ;; in case there is a comment at the end of the entity line
	      (back-to-indentation)
	      (search-forward-regexp "  " nil t)
	      (backward-char 3)))
	  ;; empty old content in hook
	  (setq ggtags-find-tag-hook nil)
	  ;; update hook to execute an action
	  ;; once jumped to new buffer
	  (add-hook 'ggtags-find-tag-hook
		    '(lambda()
		       (when (progn
			       (vhdl-tools--fold)
			       (search-forward-regexp
				(format "^ *%s " vhdl-tools--jump-into-module-name)
				nil t))
			 (vhdl-tools--fold)
			 (vhdl-tools--post-jump-function)
			 ;; erase modified hook
			 (setq vhdl-tools--jump-into-module-name nil)
			 ;; erase hook
			 (setq ggtags-find-tag-hook nil))
		       ;; remove last jump so that `pop-tag-mark' will get to
		       ;; original position before jumping
		       (ring-remove find-tag-marker-ring 0)))
	  ;; jump !
	  (call-interactively 'ggtags-find-definition))))))

;;;; Jump Upper

;; Utility to jump to upper level

(defun vhdl-tools-jump-upper ()
  "Get to upper level module and move point to signal at point.
When no symbol at point, move point to indentation."
  (interactive)
  (if (not ggtags-mode)
      (message "[VHDL Tools] ggtags feature not enabled.")
    (progn
      ;; when no symbol at point, move forward to next symbol
      (when (not (vhdl-tools--get-name))
	(back-to-indentation))
      (let ((vhdl-tools-thing (vhdl-tools--get-name))
	    (helm-execute-action-at-once-if-one t)
	    (vhdl-tools-name
	     (save-excursion
	       ;; first, try to search forward
	       (when (not (search-forward-regexp "^entity" nil t))
		 ;; if not found, try to search backward
		 (search-backward-regexp "^entity")
		 (forward-word))
	       (forward-char 2)
	       (vhdl-tools--get-name)))
	    (helm-rg--current-dir (vc-root-dir))
	    (helm-rg-default-glob-string "*.vhd"))
	(vhdl-tools--push-marker)
	;; Jump by searching using helm-rg
	(helm-rg
	 (format "\\s*.+ : (entity work.)?%s(\\(.*\\))?$" vhdl-tools-name))
	;; search except if nil
	(when vhdl-tools-thing
	  ;; limit the search to end of paragraph (end of instance)
	  (let ((max-point (save-excursion
			     (end-of-paragraph-text)
			     (point))))
	    (search-forward-regexp
	     (format "%s " vhdl-tools-thing) max-point t)
	    (vhdl-tools--fold)
	    (vhdl-tools--post-jump-function)))))))

;;; Feature: imenu navigation

;;;; Standard Imenu

(defun vhdl-tools-imenu()
  "Call native imenu, setting generic expression first."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50))
    (when vhdl-tools-save-before-imenu
      (set-buffer-modified-p t)
      (save-buffer))
    (call-interactively 'helm-semantic-or-imenu)
    (vhdl-tools--fold)
    (vhdl-tools--post-jump-function)))

;;;; Instances

(defun vhdl-tools-imenu-instance()
  "Call imenu for instances, setting generic expression first."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50))
    (when vhdl-tools-save-before-imenu
      (set-buffer-modified-p t)
      (save-buffer))
    (vhdl-tools--imenu-with-initial-minibuffer "^Instance")
    (vhdl-tools--fold)
    (vhdl-tools--post-jump-function)))

;;;; Processes

(defun vhdl-tools-imenu-processes()
  "Call imenu for processes, setting generic expression first."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50))
    (when vhdl-tools-save-before-imenu
      (set-buffer-modified-p t)
      (save-buffer))
    (vhdl-tools--imenu-with-initial-minibuffer "^Process")
    (vhdl-tools--fold)
    (vhdl-tools--post-jump-function)))

;;;; Components

(defun vhdl-tools-imenu-component()
  "Call imenu for components, setting generic expression first."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50))
    (when vhdl-tools-save-before-imenu
      (set-buffer-modified-p t)
      (save-buffer))
    (vhdl-tools--imenu-with-initial-minibuffer "^Component")
    (vhdl-tools--fold)
    (vhdl-tools--post-jump-function)))

;;;; Headings

(defun vhdl-tools-imenu-headers()
  "Call imenu for headings, setting generic expression first."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50)
	(imenu-generic-expression `(("" ,vhdl-tools-imenu-regexp 1))))
    (when vhdl-tools-save-before-imenu
      (set-buffer-modified-p t)
      (save-buffer))
    (call-interactively 'helm-semantic-or-imenu)
    (vhdl-tools--fold)
    (vhdl-tools--post-jump-function)))

;;;; All

(defun vhdl-tools-imenu-all()
  "In a vhdl buffer, call `helm-semantic-or-imenu', show all items.
Processes, instances and doc headers are shown in order of appearance."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50)
	(imenu-generic-expression
	 `(;; process
	   ("" "^\\s-*\\(\\(\\w\\|\\s_\\)+\\)\\s-*:\\(\\s-\\|\n\\)*\\(\\(postponed\\s-+\\|\\)process\\)" 1)
	   ;; instance
	   ("" "^\\s-*\\(\\(\\w\\|\\s_\\)+\\s-*:\\(\\s-\\|\n\\)*\\(entity\\s-+\\(\\w\\|\\s_\\)+\\.\\)?\\(\\w\\|\\s_\\)+\\)\\(\\s-\\|\n\\)+\\(generic\\|port\\)\\s-+map\\>" 1)
	   ;; Headings
	   ("" ,vhdl-tools-imenu-regexp 1)
	   ("Subprogram" "^\\s-*\\(\\(\\(impure\\|pure\\)\\s-+\\|\\)function\\|procedure\\)\\s-+\\(\"?\\(\\w\\|\\s_\\)+\"?\\)" 4)
	   ;; ("Instance" "^\\s-*\\(\\(\\w\\|\\s_\\)+\\s-*:\\(\\s-\\|\n\\)*\\(entity\\s-+\\(\\w\\|\\s_\\)+\\.\\)?\\(\\w\\|\\s_\\)+\\)\\(\\s-\\|\n\\)+\\(generic\\|port\\)\\s-+map\\>" 1)
	   ("Component" "^\\s-*\\(component\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\)" 2)
	   ("Procedural" "^\\s-*\\(\\(\\w\\|\\s_\\)+\\)\\s-*:\\(\\s-\\|\n\\)*\\(procedural\\)" 1)
	   ;; ("Process" "^\\s-*\\(\\(\\w\\|\\s_\\)+\\)\\s-*:\\(\\s-\\|\n\\)*\\(\\(postponed\\s-+\\|\\)process\\)" 1)
	   ("Block" "^\\s-*\\(\\(\\w\\|\\s_\\)+\\)\\s-*:\\(\\s-\\|\n\\)*\\(block\\)" 1)
	   ("Package" "^\\s-*\\(package\\( body\\|\\)\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\)" 3)
	   ("Configuration" "^\\s-*\\(configuration\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\s-+of\\s-+\\(\\w\\|\\s_\\)+\\)" 2)
	   ;; Architecture
	   ("" "^\\s-*\\(architecture\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\s-+of\\s-+\\(\\w\\|\\s_\\)+\\)" 2)
	   ("Entity" "^\\s-*\\(entity\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\)" 2)
	   ("Context" "^\\s-*\\(context\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\)" 2))))
    (when vhdl-tools-save-before-imenu
      (set-buffer-modified-p t)
      (save-buffer))
    (call-interactively 'helm-semantic-or-imenu)
    (vhdl-tools--fold)))

;;; Feature: Links
;;
;; The goal here is, using the ggtags infrastructure, to implement a mechanism to
;; follow links in comments.
;;
;; For example, in the form of =tag@tosearch=
;;
;; "TM_IO_Sequencer@Pixel"
;;
;; will get to the definition of ~TM_IO_Sequencer~, and then forward search for
;; ~Pixel~. To achieve this, I update a hook before switching buffers with
;; ~find-tag~.

;;;; Link Store

(defun vhdl-tools-store-link ()
  "Store current line as a link."
  (interactive)
  (let* ((myline (vhdl-tools-vorg-get-current-line))
	 (myentity (save-excursion
		     (search-backward-regexp "entity")
		     (forward-word)
		     (forward-char 2)
		     (vhdl-tools--get-name)))
	 (mylink (format "%s\@%s" myentity myline)))
    (message mylink)
    (setq vhdl-tools--store-link-link mylink)))

;;;; Link Paste

(defun vhdl-tools-paste-link()
  "Paste previous stored link."
  (interactive)
  (insert (format "`%s`" vhdl-tools--store-link-link)))

;;;; Link Follow

(defun vhdl-tools-follow-links(arg)
  "Follow links in the form of Tag:ToSearch'."
  (interactive "P")
  ;; get item in the form of tag@tosearch
  (save-excursion
    (let* ((tmp-point-min (progn  ;; beginning of item
			    (search-backward-regexp "\`" )
			    (+ 1 (point))))
	   (tmp-point-max (progn ;; end of item
			    (forward-char 1)
			    (search-forward-regexp "\`" )
			    (- (point) 1)))
	   (vhdl-tools-follow-links-item ;; item
	    (buffer-substring-no-properties
	     tmp-point-min tmp-point-max)))
      ;; tag
      (setq vhdl-tools--follow-links-tag
	    (substring vhdl-tools-follow-links-item 0
		       (string-match "@" vhdl-tools-follow-links-item)))
      ;; tosearch
      (setq vhdl-tools--follow-links-tosearch
	    ;; with a prefix argument, ignore tosearch
	    (when (not (equal arg '(4)))
	      nil
	      (if (string-match "@" vhdl-tools-follow-links-item)
		  (substring
		   vhdl-tools-follow-links-item
		   (+ 1 (string-match "@" vhdl-tools-follow-links-item)) nil)
		nil)))))
  ;; when tosearch non nil, update hook to execute an action
  (when vhdl-tools--follow-links-tosearch
    ;; empty old content in hook
    (setq ggtags-find-tag-hook nil)
    (vhdl-tools--push-marker)
    ;; declare action after jumping to new buffer
    (add-hook 'ggtags-find-tag-hook
	      '(lambda()
		 ;; action: forward search
		 ;; if no tosearch is found, do nothing
		 (when (search-forward vhdl-tools--follow-links-tosearch nil t)
		   ;; otherwise, do this
		   (vhdl-tools--post-jump-function))
		 ;; erase modified hook
		 (setq vhdl-tools--follow-links-tosearch nil)
		 (setq ggtags-find-tag-hook nil)))
    ;; jump !
    (ggtags-find-definition vhdl-tools--follow-links-tag)))

;;; Org / VHDL

;; Following the literate programming paradigm, here we intend to provide some
;; infrastructure to deal with jumping between a "filename.vhd" and its
;; corresponding "filename.org", the former being tangled from the latter.

;;;; VHDL to VOrg

(defun vhdl-tools-vorg-jump-to-vorg()
  "From `vhdl' file, jump to same line in `vorg' file."
  (interactive)
  (let* ((orgfile (vhdl-tools--get-vorg-file (file-name-base)))
	 ;; store current line
	 (myline_tmp
	  (replace-regexp-in-string "+" "\\\\+"
				    (vhdl-tools-vorg-get-current-line)))
	 (myline_tmp2 (replace-regexp-in-string " +" " +" myline_tmp))
	 (myline (format "^ *%s" myline_tmp2)))
    (if (file-exists-p orgfile)
	(progn
	  (if vhdl-tools-vorg-tangle-comments-link
	      ;; use org feature
	      ;; I disable `org-id-update-id-locations' to speed-up things
	      (cl-letf (((symbol-function 'org-id-update-id-locations)
			 (lambda (&optional files silent) nil)))
		(org-babel-tangle-jump-to-org))
	    ;; use custom search
	    (progn
	      (find-file orgfile)
	      (goto-char (point-min))
	      (re-search-forward myline nil t nil)))
	  ;; (org-content 5)
	  ;; (org-back-to-heading nil)
	  ;; (org-show-subtree)
	  ;; (re-search-forward myline nil t nil)
	  (recenter-top-bottom vhdl-tools-recenter-nb-lines)
	  (back-to-indentation))
      (message (format "no %s.org file exists" orgfile)))))

;;;; VOrg to VHDL

(defun vhdl-tools-vorg-jump-from-vorg()
  "From `vorg' file, jump to `vhdl' file, tangling before if necessary."
  (interactive)
  (call-interactively 'vhdl-tools-vorg-tangle)
  (let* ((vhdlfile (vhdl-tools-vorg--get-vhdl-file (file-name-base)))
	 ;; store current line
	 (myline_tmp
	  (replace-regexp-in-string "+" "\\\\+"
				    (vhdl-tools-vorg-get-current-line)))
	 (myline_tmp2 (replace-regexp-in-string " +" " +" myline_tmp))
	 (myline (format "^ *%s" myline_tmp2)))
    (when (file-exists-p vhdlfile)
      (find-file vhdlfile)
      (goto-char (point-min))
      (when vhdl-tools-use-outshine
	(outline-next-heading))
      (when (re-search-forward myline nil t nil)
	(vhdl-tools--fold)
	(re-search-forward myline nil t nil)
	(recenter-top-bottom vhdl-tools-recenter-nb-lines)
	(back-to-indentation)))))

;;;; VOrg to module

(defun vhdl-tools-vorg-jump-from-vorg-into-module()
  "From `vorg' file, jump to same line in `vhdl' file.
Tangle the code before if necessary, then jump into module."
  (interactive)
  (vhdl-tools-vorg-jump-from-vorg)
  (vhdl-tools-jump-into-module))

;;;; VOrg tangle

(defun vhdl-tools-vorg-tangle (orgfile &optional force)
  "Tangle a `vorg' `ORGFILE' file to its corresponding `vhdl' file.
With an argument `FORCE', force tangling regardless of files status.
`ORGFILE' must be the filename without extension."
  ;; (interactive (list (format "%s.org" (file-name-base))))
  (interactive (list (file-name-base)))
  (let ((vhdlfile (vhdl-tools-vorg--get-vhdl-file orgfile))
	(orgfilefull (format "%s.org" orgfile)))
    (if (or force
	    (file-newer-than-file-p orgfilefull vhdlfile)
	    (not (file-exists-p vhdlfile)))
	;; do tangle
	(let (;; When tangling the org file, this code helps to auto set proper
	      ;; indentation, whitespace fixup, alignment, and case fixing to
	      ;; entire exported buffer
	      (org-babel-post-tangle-hook (lambda()
					    (vhdl-beautify-buffer)
					    (save-buffer)))
	      (org-babel-tangle-uncomment-comments nil)
	      ;; list of property/value pairs that can be inherited by any entry.
	      (org-global-properties
	       '(("header-args:vhdl-tools" .
		  ":prologue (vhdl-tools-vorg-prologue-header-argument) :tangle (vhdl-tools-vorg-tangle-header-argument)")))
	      ;; sets the "comments:link" header arg
	      ;; possible as this is constant header arg, not dynamic with code block
	      (org-babel-default-header-args
	       (if vhdl-tools-vorg-tangle-comments-link
		   (cons '(:comments . "link")
			 (assq-delete-all :comments org-babel-default-header-args))
		 org-babel-default-header-args))
	      (org-babel-tangle-comment-format-beg
	       (format "%s %s" vhdl-tools-vorg-tangle-comment-format-beg
		       org-babel-tangle-comment-format-beg))
	      (org-babel-tangle-comment-format-end
	       (format "%s %s" vhdl-tools-vorg-tangle-comment-format-end
		       org-babel-tangle-comment-format-end)))
	  ;; tangle and beautify the tangled file only when there are tangled blocks
	  (when (org-babel-tangle-file orgfilefull vhdlfile "vhdl-tools")
	    (when vhdl-tools-verbose
	      (message (format "File %s tangled to %s." orgfilefull vhdlfile)))))
      ;; don't tangle
      (when vhdl-tools-verbose
	(message (format "File %s NOT tangled to %s." orgfile vhdlfile))))))

(defun vhdl-tools-vorg-tangle-all (arg)
  "Tangle all `vorg' files in current dir to its corresponding `vhdl' file.
With a prefix argument `ARG' force tangling regardless of files status."
  (interactive "P")
  (let ((vc-follow-symlinks nil)
	(vhdl-tools-verbose t)
	(org-global-properties
	 '(("header-args:vhdl" . ":prologue (vhdl-tools-vorg-prologue-header-argument) :tangle (vhdl-tools-vorg-tangle-header-argument)"))))
    (loop for thisfile in (file-expand-wildcards "*.org") do
	  (unless (string-match "readme" thisfile)
	    (vhdl-tools-vorg-tangle
	     (file-name-base thisfile)
	     (if (equal arg '(4))
		 t
	       nil))))))

;;;; Vorg detangle

;; (defun vhdl-tools-vorg-detangle ()
;;   "Detangle current `vorg' file to its corresponding `vhdl' file."
;;   (interactive)
;;   (let ((old-buffer (current-buffer)))
;;     (cl-letf (((symbol-function 'org-id-update-id-locations)
;;	       (lambda (&optional files silent) nil)))
;;       (org-babel-with-temp-filebuffer (buffer-file-name)
;;	(goto-char (point-min))
;;	(delete-matching-lines "^--\s\\*+\s.*$")
;;	(delete-matching-lines "^$")
;;	(org-babel-detangle)
;;	(save-buffer))))
;;   (vhdl-tools-vorg-jump-to-vorg)
;;   (save-buffer))

(defun vhdl-tools-vorg-detangle ()
  "Detangle current `vorg' file to its corresponding `vhdl' file."
  (interactive)
  (save-window-excursion
    (let ((old-buffer (current-buffer)))
      (cl-letf (((symbol-function 'org-id-update-id-locations)
		 (lambda (&optional files silent) nil)))
	(with-temp-buffer
	  (insert-buffer-substring old-buffer)
	  (goto-char (point-min))
	  (delete-matching-lines "^--\s\\*+\s.*$")
	  (delete-matching-lines "^$")
	  (org-babel-detangle)))))
  (vhdl-tools-vorg-jump-to-vorg)
  (save-buffer))

;;;; VOrg source block beautify

(defun vhdl-tools-vorg-publish ()
  "Publish project."
  (interactive)
  (let ((vhdl-tools--currently-publishing t)
	(current-prefix-arg '(4)))
    (call-interactively 'org-publish)))

;;;; VOrg source editing beautify

(defun vhdl-tools-vorg-src-edit-beautify ()
  "To be added to `org-src-mode-hook' when `vorg' mode is active.
Beautifies source code blocks before editing."
  (when (and (string= major-mode "vhdl-tools-mode")
	     (not vhdl-tools--currently-publishing))
    (require 'vhdl-mode)
    (vhdl-beautify-buffer)))

;;;; VOrg source block beautify

(defun vhdl-tools-vorg-src-block-beautify ()
  "Beautify of source code block at point."
  (interactive)
  (when (org-in-src-block-p t)
    (org-edit-src-code)
    (vhdl-beautify-buffer)
    (org-edit-src-save)
    (org-edit-src-exit)))

;;;; Vorg Helper

;; Ancillary functions

(defun vhdl-tools-vorg-get-current-line ()
  "Send current line avoiding any comments."
  (save-excursion
    (back-to-indentation)
    (let ((vhdl-tools-vorg-line-beginning (point)))
      ;; check there is a comment in current line
      (if (let ((maxposition (save-excursion
			       (end-of-line)
			       (point))))
	    (save-excursion
	      (re-search-forward "--" maxposition t)))
	  (progn
	    (re-search-forward "--")
	    (re-search-backward " ")
	    ;; previous non whitespace character
	    (re-search-backward "\\S-"))
	(end-of-line))
      (buffer-substring-no-properties
       vhdl-tools-vorg-line-beginning
       (point)))))

(defun vhdl-tools-vorg-tangle-header-argument ()
  "To be used as def argument to `tangle' in source block header."
  ;; TODO: replace org-get-tags-at by org-get-tags
  (if (let ((mytags (org-get-tags (point) t)))
	(or (member vhdl-tools-vorg-tangle-header-argument-var mytags)
	    (null mytags)))
      (vhdl-tools-vorg--get-vhdl-file (file-name-base))
    "no"))

(defun vhdl-tools-vorg-prologue-header-argument ()
  "To be used as def argument to `prologue' in source block header."
  (save-excursion
    (let ((debug-on-error nil))
      (when (org-back-to-heading nil)
	(let ((heading (car (cdr (org-element-headline-parser (point))))))
	  (format "\n-- %s %s\n"
		  (if (> (plist-get heading ':level) 1)
		      (make-string (- (plist-get heading ':level) 1)
				   ?*)
		    (make-string 1 ?*))
		  (plist-get heading ':raw-value)))))))

;;;; Vorg Headings

;;;;; Get to next

(defun vhdl-tools-vorg-headings-next()
  "Get to next heading in vorg buffer."
  (interactive)
  (org-next-visible-heading 1)
  (when vhdl-tools-manage-folding
    (outline-hide-sublevels 5)
    (org-show-entry)
    (vhdl-tools-vorg--post-jump-function)))

;;;;; Get to previous

(defun vhdl-tools-vorg-headings-prev()
  "Get to next heading in vorg buffer."
  (interactive)
  (org-previous-visible-heading 1)
  (when vhdl-tools-manage-folding
    (outline-hide-sublevels 5)
    (org-show-entry)
    (vhdl-tools-vorg--post-jump-function)))

;;; Minor Mode - Tools

;;;; Mode bindings

(defvar vhdl-tools-mode-map
  (let ((map (make-sparse-keymap)))

    ;; mode bindings: links related
    (define-key map (kbd "C-c M-l") #'vhdl-tools-follow-links)
    (define-key map (kbd "C-c M-w") #'vhdl-tools-store-link)
    (define-key map (kbd "C-c M-y") #'vhdl-tools-paste-link)

    ;; mode bindings: ggtags related
    (when vhdl-tools--ggtags-available
      (define-key map (kbd "C-c M-.") #'vhdl-tools-jump-into-module)
      (define-key map (kbd "C-c M-u") #'vhdl-tools-jump-upper)
      (define-key map (kbd "C-c M-D") #'vhdl-tools-goto-type-def))

    ;; mode bindings: misc
    (define-key map (kbd "C-c M-a") #'vhdl-tools-getto-first)
    (define-key map (kbd "C-c M-b") #'vhdl-tools-beautify-region)

    (define-key map (kbd "C-c M-^") (lambda(&optional arg)
				      (interactive "P")
				      (if (equal arg '(4))
					  (vhdl-tools-vorg-detangle)
					(vhdl-tools-vorg-jump-to-vorg))))

    ;; mode bindings: imenu related
    (when vhdl-tools--imenu-available
      (define-prefix-command 'vhdl-tools-imenu-map)
      (define-key map (kbd "C-x c i") 'vhdl-tools-imenu-map)
      (define-key vhdl-tools-imenu-map (kbd "m") #'vhdl-tools-imenu)
      (define-key vhdl-tools-imenu-map (kbd "i") #'vhdl-tools-imenu-instance)
      (define-key vhdl-tools-imenu-map (kbd "p") #'vhdl-tools-imenu-processes)
      (define-key vhdl-tools-imenu-map (kbd "c") #'vhdl-tools-imenu-component)
      (define-key vhdl-tools-imenu-map (kbd "h") #'vhdl-tools-imenu-headers)
      (define-key vhdl-tools-imenu-map (kbd "a") #'vhdl-tools-imenu-all))
    map))

;;;; Mode

;;;###autoload
(define-minor-mode vhdl-tools-mode
  "Utilities for navigating vhdl sources.

Key bindings:
\\{map}"
  :init-value nil
  :lighter " vtool"
  :global nil
  :keymap vhdl-tools-mode-map

  ;; Enable mode global features
  (if vhdl-tools-mode
      (progn
	;; puts the reference comments around in the source file out of sight
	(when vhdl-tools-vorg-tangle-comments-link
	  (vhdl-tools--cleanup-tangled))
	;; a bit of feedback
	(when vhdl-tools-verbose
	  (message "[VHDL Tools] enabled.")))
    ;; a bit of feedback
    (when vhdl-tools-verbose
      (message "[VHDL Tools] NOT enabled.")))
  ;; optionally enable links handling related features

  ;; optionally enable imenu related features
  (if (and vhdl-tools-mode
	   vhdl-tools--imenu-available)
      (progn
	;; a bit of feedback
	(when vhdl-tools-verbose
	  (message "[VHDL Tools] imenu feature enabled.")))
    ;; a bit of feedback
    (when vhdl-tools-verbose
      (message "[VHDL Tools] imenu feature not enabled.")))

  ;; optionally enable ggtags related features
  (if (and vhdl-tools-mode
	   vhdl-tools--ggtags-available
	   (buffer-file-name)
	   (vc-root-dir)
	   (file-exists-p
	    (format "%sGTAGS" (vc-root-dir))))
      (progn
	(ggtags-mode 1)
	;; a bit of feedback
	(when vhdl-tools-verbose
	  (message "[VHDL Tools] ggtags feature enabled.")))
    ;; a bit of feedback
    (when vhdl-tools-verbose
      (message "[VHDL Tools] ggtags feature not enabled.")))

  ;; optionally enable outshine related features
  (if (and vhdl-tools-mode
	   vhdl-tools--outshine-available
	   vhdl-tools-use-outshine)
      (progn
	(outshine-mode 1)
	(setq-local outline-regexp vhdl-tools-outline-regexp)
	;; a bit of feedback
	(when vhdl-tools-verbose
	  (message "[VHDL Tools] feature outshine enabled.")))
    ;; a bit of feedback
    (when vhdl-tools-verbose
      (message "[VHDL Tools] feature outshine not enabled."))))

;;; Derived Mode - vOrg

;;;; Mode bindings

(defvar vhdl-tools-vorg-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c M-,") #'vhdl-tools-vorg-jump-from-vorg)
    (define-key map (kbd "C-c M-.") #'vhdl-tools-vorg-jump-from-vorg-into-module)
    (define-key map [remap org-babel-tangle] #'vhdl-tools-vorg-tangle)
    (define-key map (kbd "C-c C-v _") #'vhdl-tools-vorg-tangle-all)
    (define-key map (kbd "C-c C-n") #'vhdl-tools-vorg-headings-next)
    (define-key map (kbd "C-c C-p") #'vhdl-tools-vorg-headings-prev)
    (define-key map (kbd "C-c M-b") #'vhdl-tools-vorg-src-block-beautify)
    (define-key map (kbd "C-c M-P") #'vhdl-tools-vorg-publish)
    map))

;;;; Mode

;;;###autoload
(define-derived-mode vhdl-tools-vorg-mode org-mode "vOrg"
  "Utilities for navigating vhdl sources in vorg files.

Key bindings:
\\{vhdl-tools-vorg-mode-map}"

  (progn

    ;; update hook
    (add-to-list 'org-src-mode-hook 'vhdl-tools-vorg-src-edit-beautify)

    ;; This auto removes any mode line on top of the vorg file before exporting
    (add-hook 'org-export-before-processing-hook
	      (lambda ()
		(save-excursion
		  (goto-char (point-min))
		  (re-search-forward "-\\*- mode: vhdl-tools-vorg -\\*-")
		  (delete-region (point-min) (point))))
	      nil t)

    ;; a bit of feedback
    (when vhdl-tools-verbose
      (message "VHDL Tools Vorg enabled."))))

(provide 'vhdl-tools)

;;; vhdl-tools.el ends here
