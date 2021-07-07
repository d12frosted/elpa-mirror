;;; vhdl-tools.el --- Utilities for navigating vhdl sources -*- lexical-binding: t; -*-

;; Copyright (C) 2015-2020 Cayetano Santos

;; Author: Cayetano Santos
;; Keywords:  convenience, languages, vhdl
;; Package-Version: 20200330.1819
;; Package-Commit: b5d1eec90bb43ba10178219245afbddb6601e85b
;; Filename: vhdl-tools.el
;; Description: Utilities for navigating vhdl sources.
;; Homepage: https://gitlab.com/emacs-elisp/vhdl-tools/-/wikis/home
;; Compatibility: GNU Emacs >= 26.3
;; Version: 6.3.pre
;; Package-Requires: ((ggtags "0.9.0") (emacs "26.2") (helm-rg "0.1") (outshine "3.1-pre"))

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
;; `vhdl-tools' provides a minor mode intended to complete the great `vhdl-mode'.
;; It adds an extra layer of functionality on top of the later, extensively
;; using `ggtags' to manage a vhdl project. `vhdl-tools' relies on `helm-rg',
;; `imenu' and `outshine' features to ease navigating vhdl sources.

;;; Install:
;;
;; https://gitlab.com/emacs-elisp/vhdl-tools/-/wikis/Install

;;; Use:
;;
;; Have a look at customization possibilities with \M-x customize-group `vhdl-tools'.
;;
;; For details, refer to https://gitlab.com/emacs-elisp/vhdl-tools/-/wikis/Use
;;
;; An example configuration file may be found at https://gitlab.com/emacs-elisp/vhdl-tools/-/wikis/Setup#example-configuration-file

;;; Todo:

;;; Code:

;;;; Requirements

(eval-when-compile
  (require 'ggtags)
  (require 'helm-rg)
  (require 'outshine))

(require 'vhdl-mode)
(require 'vc)

;;; Groups

(defgroup vhdl-tools nil "Some customizations of vhdl-tools package"
  :group 'local)

;;; Variables

;;;; User Variables

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
	    (helm-rg--current-dir (vc-find-root (buffer-file-name) ".git"))
	    (helm-rg-default-glob-string "*.vhd"))
	(vhdl-tools--push-marker)
	;; Jump by searching using helm-rg
	(helm-rg
	 (format "\\s*.+\\s:\\s(entity\\swork.)?%s(\\(.*\\))?$" vhdl-tools-name))
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

;; TODO: remove helm customizations, move them to user custom configuration by
;; using around advices

(defun vhdl-tools-imenu()
  "Call native imenu, setting generic expression first."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50)
	(helm-display-function #'helm-default-display-buffer)
	(helm-split-window-default-side
	 (if (> (window-width) 105)
	     'right
	   'below )))
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
	(helm-candidate-number-limit 50)
	(helm-display-function #'helm-default-display-buffer)
	(helm-split-window-default-side
	 (if (> (window-width) 105)
	     'right
	   'below )))
    (when vhdl-tools-save-before-imenu
      (set-buffer-modified-p t)
      (save-buffer))
    (vhdl-tools--imenu-with-initial-minibuffer "^instance")
    (vhdl-tools--fold)
    (vhdl-tools--post-jump-function)))

;;;; Processes

(defun vhdl-tools-imenu-processes()
  "Call imenu for processes, setting generic expression first."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50)
	(helm-display-function #'helm-default-display-buffer)
	(helm-split-window-default-side
	 (if (> (window-width) 105)
	     'right
	   'below )))
    (when vhdl-tools-save-before-imenu
      (set-buffer-modified-p t)
      (save-buffer))
    (vhdl-tools--imenu-with-initial-minibuffer "^process")
    (vhdl-tools--fold)
    (vhdl-tools--post-jump-function)))

;;;; Components

(defun vhdl-tools-imenu-component()
  "Call imenu for components, setting generic expression first."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50)
	(helm-display-function #'helm-default-display-buffer)
	(helm-split-window-default-side
	 (if (> (window-width) 105)
	     'right
	   'below )))
    (when vhdl-tools-save-before-imenu
      (set-buffer-modified-p t)
      (save-buffer))
    (vhdl-tools--imenu-with-initial-minibuffer "^component")
    (vhdl-tools--fold)
    (vhdl-tools--post-jump-function)))

;;;; Headings

(defun vhdl-tools-imenu-headers()
  "Call imenu for headings, setting generic expression first."
  (interactive)
  (let ((helm-autoresize-max-height 100)
	(helm-candidate-number-limit 50)
	(helm-display-function #'helm-default-display-buffer)
	(helm-split-window-default-side
	 (if (> (window-width) 105)
	     'right
	   'below ))
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
	(helm-display-function #'helm-default-display-buffer)
	(helm-split-window-default-side
	 (if (> (window-width) 105)
	     'right
	   'below ))
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

(defun vhdl-tools-follow-links(&optional arg)
  "Follow links in the form of Tag:ToSearch'.
With a prefix `ARG' ignore tosearch."
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
	   (vc-find-root (buffer-file-name) ".git")
	   (file-exists-p
	    (format "%sGTAGS" (vc-find-root (buffer-file-name) ".git"))))
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

(provide 'vhdl-tools)

;;; vhdl-tools.el ends here
