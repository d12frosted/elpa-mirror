;;; ergoemacs-status.el --- Adaptive Status Bar / Mode Line -*- lexical-binding: t -*-
;; 
;; Filename: ergoemacs-status.el
;; Description: Adaptive Status Bar / Mode Line
;; Author: Matthew Fidler
;; Maintainer: Matthew Fidler
;; Created: Fri Mar  4 14:13:50 2016 (-0600)
;; Version: 0.1
;; Package-Version: 20160318.538
;; Package-Commit: d952cc2361adf6eb4d6af60950ad4ab699c81320
;; Package-Requires: ((powerline "2.3") (mode-icons "0.1.0"))
;;
;;; Commentary:
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;; 
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.
;; 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;;; Code:
(require 'powerline nil t)
(require 'mode-icons nil t)
(eval-when-compile
  (require 'cl))

(declare-function ergoemacs-next-emacs-buffer "ergoemacs-lib")
(declare-function ergoemacs-next-user-buffer "ergoemacs-lib")
(declare-function ergoemacs-previous-emacs-buffer "ergoemacs-lib")
(declare-function ergoemacs-previous-user-buffer "ergoemacs-lib")

(defvar ergoemacs-menu--get-major-modes)

(declare-function mode-icons-get-mode-icon "mode-icons")
(declare-function mode-icons-mode "mode-icons")
(declare-function mode-icons-propertize-mode "mode-icons")
(declare-function mode-icons--read-only-status "mode-icons")
(declare-function mode-icons--modified-status "mode-icons")

(declare-function flycheck-count-errors "flycheck")


(declare-function powerline-current-separator "powerline")
(declare-function powerline-selected-window-active "powerline")

(defmacro ergoemacs-status-save-buffer-state (&rest body)
  "Eval BODY without modifiying the buffer state.
This then restore the buffer state under the assumption that no significant
modification has been made in BODY.  A change is considered
significant if it affects the buffer text in any way that isn't
completely restored again.  Changes in text properties like `face' or
`syntax-table' are considered insignificant.  This macro allows text
properties to be changed, even in a read-only buffer.

This macro should be placed around all calculations which set
\"insignificant\" text properties in a buffer, even when the buffer is
known to be writeable.  That way, these text properties remain set
even if the user undoes the command which set them.

This macro should ALWAYS be placed around \"temporary\" internal buffer
changes \(like adding a newline to calculate a text-property then
deleting it again\), so that the user never sees them on his
`buffer-undo-list'.  

However, any user-visible changes to the buffer \(like auto-newlines\)
must not be within a `ergoemacs-status-save-buffer-state', since the user then
wouldn't be able to undo them.

The return value is the value of the last form in BODY.

This was stole/modified from `c-save-buffer-state'"
  `(let* ((modified (buffer-modified-p)) (buffer-undo-list t)
          (inhibit-read-only t) (inhibit-point-motion-hooks t)
          before-change-functions after-change-functions
          deactivate-mark
          buffer-file-name buffer-file-truename ; Prevent primitives checking
                                        ; for file modification
          )
     (unwind-protect
         (progn ,@body)
       (and (not modified)
            (buffer-modified-p)
            (set-buffer-modified-p nil)))))

(defvar ergoemacs-status-file (locate-user-emacs-file ".ergoemacs-status.el")
  "The `ergoemacs-status-mode' preferences file.")

(defcustom ergoemacs-status-popup-languages t
  "Allow Swapping of `major-modes' when clicking the `mode-name'."
  :type 'boolean
  :group 'ergoemacs-status)

(defcustom ergoemacs-status-change-buffer 'ergoemacs-status-group-function
  "Method of changing buffer."
  :type '(choice
	  (function :tag "Function to group buffers.")
	  (const :tag "Switch to next/previous user/emacs buffer." 'ergoemacs)
	  (const :tag "Use emacs default method." nil))
  :group 'ergoemacs-status)

(defface ergoemacs-status-selected-element
  '((t :background "#e6c200" :foreground "#0024e6" :inherit mode-line))
  "Face for the modeline in buffers with Flycheck errors."
  :group 'ergoemacs-status)

(defvar ergoemacs-status--major-mode-menu-map nil)

(defun ergoemacs-status--major-mode-menu-map (&optional _)
  "Popup major modes and information about current mode."
  (interactive)
  (ergoemacs-status-save-buffer-state
   (or ergoemacs-status--major-mode-menu-map
       (set (make-local-variable 'ergoemacs-status--major-mode-menu-map)
	    ;; This require `ergoemacs-mode'.
	    (let ((map (and ergoemacs-status-popup-languages
			    ;; Mode in menu
			    (boundp 'ergoemacs-menu--get-major-modes)
			    (memq major-mode ergoemacs-menu--get-major-modes)
			    (key-binding [menu-bar languages])))
		  mmap)
	      (if (not map)
		  (mouse-menu-major-mode-map)
		(setq mmap (mouse-menu-major-mode-map))
		(define-key map [major-mode-sep-b] '(menu-item  "---"))
		(define-key map [major-mode] (cons (nth 1 mmap) mmap))
		map))))))

(defun ergoemacs-status-buffer-list ()
  "List of buffers shown in popup menu."
  (delq nil
        (mapcar #'(lambda (b)
                    (cond
                     ;; Always include the current buffer.
                     ((eq (current-buffer) b) b)
                     ((buffer-file-name b) b)
                     ((char-equal ?\  (aref (buffer-name b) 0)) nil)
                     ((buffer-live-p b) b)))
                (buffer-list))))

(defun ergoemacs-status-group-function (&optional buffer)
  "What group does the current BUFFER belong to?"
  (if (char-equal ?\* (aref (buffer-name buffer) 0))
      "Emacs Buffer"
    "User Buffer"))

(defun ergoemacs-status-menu (&optional buffer)
  "Create the BUFFER name menu."
  (let* ((cb (or buffer (current-buffer)))
	 (group (with-current-buffer cb
		  (if (functionp ergoemacs-status-change-buffer)
		      (funcall ergoemacs-status-change-buffer)
		    '("Common"))))
	 (groups '())
	 (buf-list (sort
		    (mapcar
		     ;; for each buffer, create list: buffer, buffer name, groups-list
		     ;; sort on buffer name; store to bl (buffer list)
		     (lambda (b)
		       (let (tmp0 tmp1 tmp2)
			 (with-current-buffer b
			   (setq tmp0 b
				 tmp1 (buffer-name b)
				 tmp2 (if (functionp ergoemacs-status-change-buffer)
					  (funcall ergoemacs-status-change-buffer)
					"Common"))
			   (unless (or (string= group tmp2) (assoc tmp2 groups))
			     (push (cons tmp2 (intern tmp2)) groups))
			   (list tmp0 tmp1 tmp2 (intern tmp1)))))
		     (ergoemacs-status-buffer-list))
		    (lambda (e1 e2)
		      (or (and (string= (nth 2 e2) (nth 2 e2))
			       (not (string-lessp (nth 1 e1) (nth 1 e2))))
			  (not (string-lessp (nth 2 e1) (nth 2 e2)))))))
	 menu menu2 tmp)
    (dolist (item buf-list)
      (if (string= (nth 2 item) group)
	  (unless (eq cb (nth 0 item))
	    (push `(,(nth 3 item) menu-item ,(nth 1 item) (lambda() (interactive) (funcall menu-bar-select-buffer-function ,(nth 0 item)))) menu))
	(if (setq tmp (assoc (nth 2 item) menu2))
	    (push `(,(nth 3 item) menu-item ,(nth 1 item) (lambda() (interactive) (funcall menu-bar-select-buffer-function ,(nth 0 item))))
		  (cdr tmp))
	  (push (list (nth 2 item) `(,(nth 3 item) menu-item ,(nth 1 item) (lambda() (interactive) (funcall menu-bar-select-buffer-function ,(nth 0 item))))) menu2))))
    (setq menu `(keymap ,(if (or menu (> (length menu2) 1))
			     group
			   (car (car menu2)))
			,@(if (or menu (> (length menu2) 1))
			      (mapcar
			       (lambda(elt)
				 `(,(intern (car elt)) menu-item ,(car elt) (keymap ,@(cdr elt))))
			       menu2)
			    (cdr (car menu2)))
			,(when (and menu (>= (length menu2) 1))
			   '(sepb menu-item "--"))
			,@menu))
    menu))

(defun ergoemacs-status-mouse-1-buffer (event)
  "Next ergoemacs buffer.

EVENT is where the mouse-click occured and is used to figure out
what window is associated with the mode-line click."
  (interactive "e")
  (with-selected-window (posn-window (event-start event))
    (let ((emacs-buffer-p (string-match-p "^[*]" (buffer-name))))
      (cond
       ((functionp ergoemacs-status-change-buffer)
	(popup-menu (ergoemacs-status-menu)))
       ((and ergoemacs-status-change-buffer emacs-buffer-p (fboundp #'ergoemacs-next-emacs-buffer))
	(ergoemacs-next-emacs-buffer))
       ((and ergoemacs-status-change-buffer (fboundp #'ergoemacs-next-user-buffer))
	(ergoemacs-next-user-buffer))
       (t
	(next-buffer))))))

(defun ergoemacs-status-mouse-3-buffer (event)
  "Prevous ergoemacs buffer.

EVENT is where the mouse clicked and is used to figure out which
buffer is selected with mode-line click."
  (interactive "e")
  (with-selected-window (posn-window (event-start event))
    (let ((emacs-buffer-p (string-match-p "^[*]" (buffer-name))))
      (cond
       ((functionp ergoemacs-status-change-buffer)
	(popup-menu (ergoemacs-status-menu)))
       ((and ergoemacs-status-change-buffer emacs-buffer-p (fboundp #'ergoemacs-previous-emacs-buffer))
	(ergoemacs-previous-emacs-buffer))
       ((and ergoemacs-status-change-buffer (fboundp #'ergoemacs-previous-user-buffer))
	(ergoemacs-previous-user-buffer))
       (t
	(previous-buffer))))))

(defcustom ergoemacs-status-use-vc t
  "Include vc in mode-line."
  :type 'boolean
  :group 'ergoemacs-status)

(defun ergoemacs-status--property-substrings (str prop)
  "Return a list of substrings of STR when PROP change."
  ;; Taken from powerline by Donald Ephraim Curtis, Jason Milkins and
  ;; Nicolas Rougier
  (let ((beg 0) (end 0)
        (len (length str))
        (out))
    (while (< end (length str))
      (setq end (or (next-single-property-change beg prop str) len))
      (setq out (append out (list (substring str beg (setq beg end))))))
    out))

(defun ergoemacs-status--ensure-list (item)
  "Ensure that ITEM is a list."
  (or (and (listp item) item) (list item)))

(defun ergoemacs-status--add-text-property (str prop val)
  "For STR add PROP property set to VAL value."
  ;; Taken from powerline by Donald Ephraim Curtis, Jason Milkins and
  ;; Nicolas Rougier
  ;; Changed so that prop is not just 'face
  ;; Also changed to not force list, or add a nil to the list
  (mapconcat
   (lambda (mm)
     (let ((cur (get-text-property 0 prop mm)))
       (if (not cur)
	   (propertize mm prop val)
	 (propertize mm prop (append (ergoemacs-status--ensure-list cur) (list val))))))
   (ergoemacs-status--property-substrings str prop)
   ""))

(defun ergoemacs-status--if--1 (lst-or-string)
  "Render LST-OR-STRING conditionally.

If this list contains functions, and they return nil, don't
render anything.  The last element should be a string, list or
symbol to render in the mode-line."
  (cond
   ((consp lst-or-string)
    (catch 'found-it
      (dolist (elt lst-or-string)
	(cond
	 ((functionp elt)
	  (let ((tmp (funcall elt)))
	    (if (or (and tmp (stringp tmp)) (listp tmp))
		(throw 'found-it tmp)
	      ;; Otherwise, assume its a boolean.
	      ;; If didn't
	      (when (and (booleanp tmp)
			 (not tmp))
		(throw 'found-it "")))))
	 
	 ((and elt (stringp elt))
	  (throw 'found-it elt))
	 ((and elt (consp elt))
	  (throw 'found-it elt))
	 ((and (symbolp elt) (boundp elt) (or (consp (symbol-value elt)) (stringp (symbol-value elt))))
	  (throw 'found-it (symbol-value elt)))))
      ""))
   ((and lst-or-string (stringp lst-or-string))
    lst-or-string)
   (t "")))

(defun ergoemacs-status--if (str &optional face)
  "Render STR as mode-line data using FACE."
  (let* ((rendered-str (format-mode-line (ergoemacs-status--if--1 str))))
    (if face
	(ergoemacs-status--add-text-property rendered-str 'face face)
      rendered-str)))

(defun ergoemacs-status--set-buffer-file-coding-system (event)
  "Set buffer file-coding.
EVENT tells what window to set the codings system."
  (interactive "e")
  (with-selected-window (posn-window (event-start event))
    (call-interactively #'set-buffer-file-coding-system)))

(defun ergoemacs-status--encoding ()
  "Encoding mode-line."
  (propertize (format "%s" (coding-system-type buffer-file-coding-system))
	      'mouse-face 'mode-line-highlight
	      'help-echo (format "mouse-1: Change buffer coding system\n%s"
				 (coding-system-doc-string buffer-file-coding-system))
	      'local-map '(keymap
			   (mode-line keymap
				      (mouse-1 . ergoemacs-status--set-buffer-file-coding-system)))))

(defvar ergoemacs-status-sep-swap
  '(alternate arrow arrow-fade bar box brace butt chamfer contour curve rounded roundstub wave zigzag)
  "List of separators to swap.")

(defvar powerline-default-separator)

(defun ergoemacs-status-sep-swap ()
  "Swap separators used in powerline."
  (interactive)
  (let ((sep (memq powerline-default-separator ergoemacs-status-sep-swap)))
    (when sep
      (setq sep (cdr sep))
      (if (= (length sep) 0)
	  (setq powerline-default-separator (car ergoemacs-status-sep-swap))
	(setq powerline-default-separator (car sep))))
    (force-mode-line-update )))

(defvar ergoemacs-status--sep-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line mouse-3] #'ergoemacs-status-right-click)
    (define-key map [mode-line down-mouse-1] #'ergoemacs-status-sep-swap)
    map)
  "Keymap for separators.")

(defvar powerline-default-separator-dir)
(defvar ergoemacs-status--sep 'left
  "Direction if current separator. 

Used with `ergoemacs-status--sep'.")

(defvar ergoemacs-status--swap '(alternate bar box chamfer contour rounded wave zigzag)
  "Separators that swap directions with every separator used.")

(defun ergoemacs-status--sep (&rest args)
  "Separator between elements.
The additional ARGS are the fonts applied.  This uses `powerline' functions."
  (let* ((dir ergoemacs-status--sep)
	 (cs (powerline-current-separator))
	 (separator (and (fboundp #'powerline-current-separator)
			 (intern (format "powerline-%s-%s" cs
					 (or (and (eq dir 'left)
						  (car powerline-default-separator-dir))
					     (cdr powerline-default-separator-dir))))))
	 (args (mapcar
		(lambda(face)
		  (let* ((f (or (and (symbolp face) face)
				(and (consp face) (symbolp (car face)) (car face))))
			 (fa (assoc f face-remapping-alist)))
		    (if fa
			(car (cdr fa))
		      f)))
		args)))
    (when (fboundp separator)
      (let ((img (apply separator args)))
	(when (and (listp img) (eq 'image (car img)))
	  (when (memq cs ergoemacs-status--swap)
	    (setq ergoemacs-status--sep
		  (or (and (eq 'left ergoemacs-status--sep) 'right) 'left)))
	  (propertize " " 'display img
		      'face (plist-get (cdr img) :face)
		      'mouse-face 'mode-line-highlight
		      'local-map ergoemacs-status--sep-map
		      'help-echo "Separator\nmouse-1: Swap separator\nmouse-3: mode-line properties."))))))

(defvar ergoemacs-status--lhs nil
  "Internal variable to render left handed side of mode-line.")

(defvar ergoemacs-status--center nil
  "Internal variable to render center of mode-line.")

(defvar ergoemacs-status--rhs nil
  "Internal variable to render right handed side of mode-line.")

(defvar ergoemacs-status--lhs nil)
(defvar ergoemacs-status--center nil)
(defvar ergoemacs-status--rhs nil)

(defvar ergoemacs-status--automatic-hidden-minor-modes nil
  "List of minor modes hidden due to either space or adaptive hiding of minor-modes.")

;; Adapted from powerline.
(defvar ergoemacs-status--suppressed-minor-modes '(isearch-mode)
  "List of suppressed minor modes.")


(defun ergoemacs-minor-mode-menu-from-indicator (indicator &optional dont-popup)
  "Show menu for minor mode specified by INDICATOR.

Interactively, INDICATOR is read using completion.
If there is no menu defined for the minor mode, then create one with
items `Turn Off', `Hide' and `Help'.

When DONT-POPUP is non-nil, return the menu without actually popping up the menu."
  (interactive
   (list (completing-read
	  "Minor mode indicator: "
	  (describe-minor-mode-completion-table-for-indicator))))
  (let* ((minor-mode (or (and (stringp indicator) (lookup-minor-mode-from-indicator indicator))
			 (and (symbolp indicator) indicator)))
         (mm-fun (or (get minor-mode :minor-mode-function) minor-mode)))
    (unless minor-mode (error "Cannot find minor mode for `%s'" indicator))
    (let* ((map (cdr-safe (assq minor-mode minor-mode-map-alist)))
           (menu (and (keymapp map) (lookup-key map [menu-bar])))
	   (hidden (memq minor-mode ergoemacs-status--automatic-hidden-minor-modes)))
      (setq menu
            (if menu
                (if hidden
		    (mouse-menu-non-singleton menu)
		  `(,@(mouse-menu-non-singleton menu)
		    (sep-minor-mode-ind menu-item "--")
		    (hide menu-item ,(if dont-popup
					 "Show this minor-mode"
				       "Hide this minor-mode")
			  (lambda () (interactive)
			    (ergoemacs-minor-mode-hide ',mm-fun ,dont-popup)))))
	      `(keymap
                ,indicator
                (turn-off menu-item "Turn Off minor mode" ,mm-fun)
		,(if hidden nil
		   `(hide menu-item ,(if dont-popup
				     "Show this minor-mode"
				   "Hide this minor-mode")
		      (lambda () (interactive)
			(ergoemacs-minor-mode-hide ',mm-fun ,dont-popup))))
                (help menu-item "Help for minor mode"
                      (lambda () (interactive)
                        (describe-function ',mm-fun))))))
      (if dont-popup menu
	(popup-menu menu)))))

(defun ergoemacs-status--minor-mode-mouse (click-group click-type string)
  "Return mouse handler for CLICK-GROUP given CLICK-TYPE and STRING."
  ;; Taken from Powerline
  (cond ((eq click-group 'minor)
         (cond ((eq click-type 'menu)
                `(lambda (event)
                   (interactive "@e")
                   (ergoemacs-minor-mode-menu-from-indicator ,string)))
               ((eq click-type 'help)
                `(lambda (event)
                   (interactive "@e")
                   (describe-minor-mode-from-indicator ,string)))
               (t
                `(lambda (event)
                   (interactive "@e")
                   nil))))
        (t
         `(lambda (event)
            (interactive "@e")
            nil))))

(defvar ergoemacs-status--transient-hidden-minor-modes '()
  "List of temorarily hidden modes that are not saved between sessions.")

(defvar ergoemacs-status--hidden-minor-modes '()
  "List of tempoarily hidden modes.")

(defcustom ergoemacs-status-hidden-indicators
  '("FlyC-")
  "Minor modes that will be hidden based on indicator status."
  :type '(repeat
	  (string :tag "Minor mode indicator"))
  :group 'ergoemacs-status)

(defcustom ergoemacs-status-hidden-regexp "\\(Ergo.*\\[.*\\]\\)"
  "Regular Expression of adaptive hidden indicators."
  :type '(choice
	  (regexp :tag "Regular Expression")
	  (const :tag "No additional mapping."))
  :group 'ergoemacs-status)

(defvar ergoemacs-status--regexp-hidden nil
  "Regular Expression of when minor mode are hidden.")

(defun ergoemacs-status-save-file--sym (sym)
  "Print SYM Emacs Lisp value in current buffer."
  (let ((print-level nil)
          (print-length nil))
      (insert "(setq " (symbol-name sym) " '")
      (prin1 (symbol-value sym) (current-buffer))
      (goto-char (point-max))
      (insert ")\n")))

(defvar ergoemacs-status--suppressed-elements nil
  "List of suppressed `ergoemacs-status' elements.")

(defvar ergoemacs-status-current nil
  "Current layout of mode-line.")

(defvar ergoemacs-status-save-symbols
  '(ergoemacs-status--hidden-minor-modes
    ergoemacs-status--suppressed-minor-modes
    ergoemacs-status-current
    ergoemacs-status--suppressed-elements
    ergoemacs-status-elements-popup-save
    powerline-default-separator
    ergoemacs-status--minor-modes-separator)
  "List of symbols to save in `ergoemacs-status-file'.")

(defun ergoemacs-status-save-file ()
  "Save preferences to `ergoemacs-status-file'."
  (ergoemacs-status-save-buffer-state
   (with-temp-file ergoemacs-status-file
     (insert ";; -*- coding: utf-8-emacs -*-\n"
	     ";; This file is automatically generated by the `ergoemacs-status-mode'.\n")
     (dolist (sym ergoemacs-status-save-symbols)
       (ergoemacs-status-save-file--sym sym))
     (insert "(add-hook 'emacs-startup-hook #'ergoemacs-status-elements-popup-restore)\n(add-hook 'emacs-startup-hook #'ergoemacs-status-current-update)\n;;; end of file\n"))))

(defun ergoemacs-minor-mode-hide (minor-mode &optional show transient)
  "Hide a minor-mode based on mode indicator MINOR-MODE.

When SHOW is non-nil, show instead of hide the MINOR-MODE.

When TRANSIENT is non-nil, hide this minor mode
tranisently (doesn't save between sessions).

This function also saves your prefrences to
`ergoemacs-status-file' by calling the function
`ergoemacs-status-save-file'."
  (let ((present-p (memq minor-mode (or (and transient ergoemacs-status--transient-hidden-minor-modes)
					ergoemacs-status--hidden-minor-modes)))
	(refresh-p t))
    (cond
     ((and show present-p transient)
      (setq ergoemacs-status--transient-hidden-minor-modes (delq minor-mode ergoemacs-status--transient-hidden-minor-modes)))
     ((and show present-p)
      (setq ergoemacs-status--hidden-minor-modes (delq minor-mode ergoemacs-status--hidden-minor-modes)))
     ((and transient (not present-p))
      (push minor-mode ergoemacs-status--transient-hidden-minor-modes))
     ((not present-p)
      (push minor-mode ergoemacs-status--hidden-minor-modes))
     (t
      (setq refresh-p nil)))
    (when refresh-p
      (unless transient
	(ergoemacs-status-save-file))
      (force-mode-line-update))))

(defun ergoemacs-minor-mode-hidden-menu (&optional _event)
  "Display a list of the hidden minor modes.
Currently this ignores the _EVENT data."
  (interactive "@e")
  (popup-menu
   `(keymap
     ,@(mapcar
       (lambda(m)
	 `(,m menu-item ,(format "%s" m) ,(ergoemacs-minor-mode-menu-from-indicator m t)))
       (let (ret)
	 (dolist (elt (append ergoemacs-status--hidden-minor-modes
			      ergoemacs-status--transient-hidden-minor-modes
			      ergoemacs-status--automatic-hidden-minor-modes))
	   (when (and (boundp elt) (symbol-value elt))
	     (push elt ret)))
	 ret))
     "Hidden Minor Modes")))

(defun ergoemacs-minor-mode-alist ()
  "Get a list of the minor-modes."
  (let (ret)
    (dolist (a (reverse minor-mode-alist))
      (unless (memq (car a) (append ergoemacs-status--hidden-minor-modes
				    ergoemacs-status--transient-hidden-minor-modes
				    ergoemacs-status--suppressed-minor-modes))
	(push a ret)))
    ret))

(defvar ergoemacs-status--minor-modes-p t
  "Determine if `ergoemacs-status--minor-modes' generates space.")

(defvar ergoemacs-status--minor-modes-available nil)
(defun ergoemacs-status--minor-modes-available (mode-line face1 &optional reduce)
  "Calculate the space available for minor-modes.

MODE-LINE is the mode-line face.  FACE1 is the alternative face.
passed to `ergoemacs-status--eval-lhs',
`ergoemacs-status--eval-rhs' and
`ergoemacs-status--eval-center'.

REDUCE is the current reduction level being calculated."
  (let (lhs rhs center)
    (setq ergoemacs-status--minor-modes-p nil)
    (unwind-protect
	(setq lhs (ergoemacs-status--eval-lhs mode-line face1 reduce)
	      rhs (ergoemacs-status--eval-rhs mode-line face1 reduce)
	      center (ergoemacs-status--eval-center mode-line face1 reduce))
      (setq ergoemacs-status--minor-modes-p t
	    ergoemacs-status--minor-modes-available (- (ergoemacs-status--eval-width)
						     (+ (ergoemacs-status--eval-width lhs)
							(ergoemacs-status--eval-width rhs)
							(ergoemacs-status--eval-width center)))))))

(defvar ergoemacs-status--minor-modes-separator " "
  "Separator for minor modes.")

(defun ergoemacs-status--minor-modes ()
  "Get minor modes."
  (let* ((width 0)
	 (ret ""))
    (unless ergoemacs-status--regexp-hidden
      (setq ergoemacs-status--regexp-hidden (concat "\\` *" (regexp-opt ergoemacs-status-hidden-indicators 't)
						    (or (and ergoemacs-status-hidden-regexp "\\|") "")
						    (or ergoemacs-status-hidden-regexp "")
						    "\\'")))
    (when ergoemacs-status--minor-modes-p
      (setq ergoemacs-status--automatic-hidden-minor-modes nil
	    ret (replace-regexp-in-string
		 " +$" ""
		 (mapconcat (lambda (mm)
			      (if (or (not (numberp ergoemacs-status--minor-modes-available))
				      (< width ergoemacs-status--minor-modes-available))
				  (let ((cur (propertize mm
							 'mouse-face 'mode-line-highlight
							 'help-echo "Minor mode\n mouse-1: Display minor mode menu\n mouse-2: Show help for minor mode\n mouse-3: Toggle minor modes"
							 'local-map (let ((map (make-sparse-keymap)))
								      (define-key map
									[mode-line down-mouse-1]
									(ergoemacs-status--minor-mode-mouse 'minor 'menu mm))
								      (define-key map
									[mode-line mouse-2]
									(ergoemacs-status--minor-mode-mouse 'minor 'help mm))
								      (define-key map
									[mode-line down-mouse-3]
									(ergoemacs-status--minor-mode-mouse 'minor 'menu mm))
								      (define-key map
									[header-line down-mouse-3]
									(ergoemacs-status--minor-mode-mouse 'minor 'menu mm))
								      map))))
				    ;; (message "`%s';%s" cur (string-match-p ergoemacs-status--regexp-hidden cur))
				    (if (string-match-p ergoemacs-status--regexp-hidden cur)
					(progn
					  (push (lookup-minor-mode-from-indicator mm) ergoemacs-status--automatic-hidden-minor-modes)
					  "")
				      (if (or (not (numberp ergoemacs-status--minor-modes-available))
					      (< width ergoemacs-status--minor-modes-available))
					  cur
					(push (lookup-minor-mode-from-indicator mm) ergoemacs-status--automatic-hidden-minor-modes)
					"")))
				(push (lookup-minor-mode-from-indicator mm) ergoemacs-status--automatic-hidden-minor-modes)
				""))
			    (split-string (format-mode-line (ergoemacs-minor-mode-alist)))
			    ergoemacs-status--minor-modes-separator))))
    (when (or (not ergoemacs-status--minor-modes-p)
	      ergoemacs-status--automatic-hidden-minor-modes
	      (catch 'found
		(dolist (elt ergoemacs-status--hidden-minor-modes)
		  (when (and (boundp elt) (symbol-value elt))
		    (throw 'found t)))
		nil))
      (setq ret (concat ret ergoemacs-status--minor-modes-separator
			(propertize (if (and (fboundp #'mode-icons-propertize-mode))
					(mode-icons-propertize-mode "+" (list "+" #xf151 'FontAwesome))
				      "+")
				    'mouse-face 'mode-line-highlight
				    'help-echo "Hidden Minor Modes\nmouse-1: Display hidden minor modes"
				    'local-map (let ((map (make-sparse-keymap)))
						 (define-key map [mode-line down-mouse-1] 'ergoemacs-minor-mode-hidden-menu)
						 (define-key map [mode-line down-mouse-3] 'ergoemacs-minor-mode-hidden-menu)
						 map)))
	    ret (replace-regexp-in-string (format "%s%s+"
						  (regexp-quote ergoemacs-status--minor-modes-separator)
						  (regexp-quote ergoemacs-status--minor-modes-separator))
					  ergoemacs-status--minor-modes-separator ret)))
    ret))

(defvar ergoemacs-status-position-map
  (let ((map (copy-keymap mode-line-column-line-number-mode-map)))
    ;; (define-key map [mode-line down-mouse-3]
    ;;   (lookup-key map [mode-line down-mouse-1]))
    ;; (define-key (lookup-key map [mode-line down-mouse-3])
    ;;   [size-indication-mode]
    ;;   '(menu-item "Display Buffer Size"
    ;; 		  size-indication-mode
    ;; 		  :help "Toggle displaying file size in the mode-line"
    ;; 		  :button (:toggle . size-indication-mode)))
    (define-key map [mode-line down-mouse-1] 'ignore)
    (define-key map [mode-line mouse-1] 'ergoemacs-status-goto-line)
    map)
  "Position map (includes function `size-indication-mode').")

(defun ergoemacs-status-goto-line (event)
  "Goto line.
EVENT is the mouse-click event to determine the window where
`goto-line' is called."
  (interactive "e")
  (with-selected-window (posn-window (event-start event))
    (call-interactively #'goto-line)))

(defun ergoemacs-status-position ()
  "`ergoemacs-status-mode' line position."
  (let ((col (propertize
	      (or (and line-number-mode "%3c") "")
	      'mouse-face 'mode-line-highlight
	      'local-map ergoemacs-status-position-map)))
    (when  (>= (current-column) 80)
      (setq col (propertize col 'face 'error)))
    (concat (propertize
	     (or (and column-number-mode "%4l") "")
	     ;; 'face 'bold
	     'mouse-face 'mode-line-highlight
	     'local-map ergoemacs-status-position-map)
	    (or (and column-number-mode line-number-mode ":") "")
	    col)))

(defun ergoemacs-status-size-indication-mode ()
  "Gives mode-line information when variable `size-indication-mode' is non-nil."
  (when size-indication-mode
    (propertize
     "%I"
     'mouse-face 'mode-line-highlight
     'local-map ergoemacs-status-position-map)))

(defun ergoemacs-status--read-only ()
  "Gives read-only indicator."
  (propertize (mode-icons--read-only-status)
	      'face 'mode-line-buffer-id))

(defun ergoemacs-status--modified ()
  "Gives modified indicator."
  (when (buffer-file-name)
    (propertize (mode-icons--modified-status)
		'face 'mode-line-buffer-id)))

(defvar flycheck-current-errors)

(defun ergoemacs-status--flycheck ()
  "Element for flycheck."
  (when (and (boundp 'flycheck-mode) flycheck-mode)
    (ergoemacs-status-save-buffer-state
     (let ((info (flycheck-count-errors flycheck-current-errors))
	   tmp
	   ret)
       (when (setq tmp (assoc 'error info))
	 (push (propertize
		(format "+%s"(cdr tmp))
		'face 'error
		'local-map '(keymap
			     (mode-line keymap
					(mouse-1 . flycheck-next-error)
					(mouse-3 . flycheck-prev-error))))
	       ret))
       (when (setq tmp (assoc 'warning info))
	 (push (propertize
		(format "+%s" (cdr tmp))
		'face 'warning
		'local-map '(keymap
			     (mode-line keymap
					(mouse-1 . flycheck-next-error)
					(mouse-3 . flycheck-prev-error))))
	       ret))
       (when (setq tmp (assoc 'info info))
	 (push (propertize
		(format "+%s" (cdr tmp))
		'face 'font-lock-doc-face
		'local-map '(keymap
			     (mode-line keymap
					(mouse-1 . flycheck-next-error)
					(mouse-3 . flycheck-prev-error))))
	       ret))
       (when ret
	 ;; (push 'flycheck-mode ergoemacs-status--automatic-hidden-minor-modes)
	 (setq ret (mapconcat (lambda(x) x) (reverse ret) " ")))
       ret))))

(defun ergoemacs-status--nyan ()
  "Nyan element for ergoemacs-status."
  (when (and (boundp 'nyan-mode) nyan-mode)
    (ergoemacs-status-save-buffer-state
     (format-mode-line '(:eval (list (nyan-create)))))))

(defun ergoemacs-status--anzu ()
  "Anzu element for `ergoemacs-status-mode'."
  (when (bound-and-true-p anzu--state)
    (anzu--update-mode-line)))

(defvar evil-state)
(defvar evil-visual-selection)

;; Adapted from spaceline.
(defun ergoemacs-status--column-number-at-pos (pos)
  "Column number at POS.  Analog to `line-number-at-pos'."
  (save-excursion (goto-char pos) (current-column)))

(defun ergoemacs-status--selection-info ()
  "Information about the size of the current selection, when applicable.
Supports both Emacs and Evil cursor conventions."
  (when (or mark-active
            (and (bound-and-true-p evil-local-mode)
                 (eq 'visual evil-state)))
    (let* ((lines (count-lines (region-beginning) (min (1+ (region-end)) (point-max))))
	   (chars (- (1+ (region-end)) (region-beginning)))
	   (cols (1+ (abs (- (ergoemacs-status--column-number-at-pos (region-end))
			     (ergoemacs-status--column-number-at-pos (region-beginning))))))
	   (evil (and (bound-and-true-p evil-state) (eq 'visual evil-state)))
	   (rect (or (bound-and-true-p rectangle-mark-mode)
		     (and evil (eq 'block evil-visual-selection))))
	   (multi-line (or (> lines 1) (and evil (eq 'line evil-visual-selection)))))
      (cond
       (rect (format "%d×%d block" lines (if evil cols (1- cols))))
       (multi-line (format "%d lines" lines))
       (t (format "%d chars" (if evil chars (1- chars))))))))

(defun ergoemacs-status--hud ()
  "HUD for ergoemacs-status."
  "Heads up display"
  (powerline-hud 'mode-line 'powerline-active1))

(defcustom ergoemacs-status-elements
  '((:anzu (ergoemacs-status--anzu) 4 "Anzu")
    (:selection-info (ergoemacs-status--selection-info) 1 "Selection Information")
    (:read-only (ergoemacs-status--read-only) 3 "Read Only Indicator")
    (:buffer-id (ergoemacs-status-buffer-id) nil "Buffer Name")
    (:modified (ergoemacs-status--modified) nil "Modified Indicator")
    (:size (ergoemacs-status-size-indication-mode) 2 (("Buffer Size" size-indication-mode)))
    (:nyan (ergoemacs-status--nyan) 1 (("Nyan mode" nyan-mode)))
    (:flycheck (ergoemacs-status--flycheck) 1 "Flycheck Errors")
    (:position (ergoemacs-status-position) 2 ( ("Line" line-number-mode)
						  ("Column" column-number-mode)))
    (:vc (ergoemacs-status-use-vc powerline-vc) 1 "Version Control")
    (:minor (ergoemacs-status--minor-modes)  4 "Minor Mode List")
    (:narrow (mode-icons--generate-narrow) 4 "Narrow Indicator")
    (:global (global-mode-string) nil nil (("Time" display-time-mode)
					   ("Battery Charge" display-battery-mode)
					   ("Fancy Battery Charge" fancy-battery-mode)))
    (:coding ((lambda() (not (string= "undecided" (ergoemacs-status--encoding)))) ergoemacs-status--encoding) 2 "Coding System")
    (:eol ((lambda() (not (string= ":" (mode-line-eol-desc)))) mode-icons--mode-line-eol-desc mode-line-eol-desc) 2 "End Of Line Convention")
    (:major (ergoemacs-status-major-mode-item) nil nil "Language/Major mode")
    (:which-func (ergoemacs-status-which-function-mode) nil nil "Which function")
    (:process (mode-line-process) 1 nil "Process")
    (:hud (ergoemacs-status--hud) 1 nil "Heads Up Display"))
  "Elements of mode-line recognized by `ergoemacs-status-mode'.

This is a list of element recognized by `ergoemacs-status-mode'."
  :type '(repeat
	  (list
	   (symbol :tag "Element Name")
	   (sexp :tag "Element Expression")
	   (choice :tag "How this element is collapsed"
	     (const :tag "Always keep this element" nil)
	     (integer :tag "Reduction Level"))
	   (choice :tag "Description"
		   (const :tag "No Description")
		   (string :tag "Description")
		   (repeat
		    (list
		     (string :tag "Description")
		     (symbol :tag "Minor mode function"))))))
  :group 'ergoemacs-status)

(defun ergoemacs-status-elements-toggle (elt)
  "Toggle the display of ELT."
  (if (memq elt ergoemacs-status--suppressed-elements)
      (setq ergoemacs-status--suppressed-elements (delq elt ergoemacs-status--suppressed-elements))
    (push elt ergoemacs-status--suppressed-elements))
  (ergoemacs-status-save-file)
  (ergoemacs-status-current-update)
  (force-mode-line-update))

(defun ergoemacs-status-right-click (event)
  "Right click context menu for EVENT."
  (interactive "e")
  (with-selected-window (posn-window (event-start event))
    (ergoemacs-status-elements-popup)))

(defvar ergoemacs-status-elements-popup nil)
(defvar ergoemacs-status-elements-popup-save nil)

(defun ergoemacs-status-elements-popup-save ()
  "Save mode status defined in right-click menu."
  (setq ergoemacs-status-elements-popup-save nil)
  (dolist (elt ergoemacs-status-elements-popup)
    (push (list elt (symbol-value elt))
	  ergoemacs-status-elements-popup-save))
  (ergoemacs-status-save-file))

(defun ergoemacs-status-elements-popup-restore ()
  "Restore status defined in right-click menu."
  (dolist (elt ergoemacs-status-elements-popup-save)
    (when (fboundp (nth 0 elt))
      (if (nth 1 elt)
	  (funcall (nth 0 elt) 1)
	(funcall (nth 0 elt) -1)))))


(defun ergoemacs-status-elements-popup (&optional dont-popup)
  "Popup menu about displayed `ergoemacs-status' elements.
When DONT-POPUP is non-nil, just return the menu"
  (let ((map (make-sparse-keymap "Status Bar"))
	(i 0))
    (define-key map [arrow-type] `(menu-item "Separators"
					     ,(let ((map (make-sparse-keymap "Separator")))
						(dolist (elt (reverse ergoemacs-status-sep-swap))
						  (define-key map (vector elt) `(menu-item ,(format "%s" elt)
											   (lambda(&rest _) (interactive)
											     (setq powerline-default-separator ',elt)
											     (force-mode-line-update)
											     (ergoemacs-status-save-file))
											   :button (:toggle . (eq powerline-default-separator ',elt)))))
						map)))
    (define-key map [sep-toggle] '(menu-item "---")) 
    (dolist (elt (reverse (append (plist-get ergoemacs-status-current :left)
				  (list "--")
				  (plist-get ergoemacs-status-current :center)
				  (list "--")
				  (plist-get ergoemacs-status-current :right))))
      (cond
       ((equal elt "--")
	(define-key map (vector (intern (format "status-element-popup-sep-%s" i))) '(menu-item  "---")))
       ((consp elt)
	(dolist (group-elt elt)
	  (when (setq elt (assoc group-elt ergoemacs-status-elements))
	    (if (stringp (nth 3 elt))
		(define-key map (vector (car elt))
		  `(menu-item ,(nth 3 elt) (lambda(&rest _) (interactive) (ergoemacs-status-elements-toggle ,(car elt)))
			      :button (:toggle . (not (memq ,(car elt) ergoemacs-status--suppressed-elements)))))
	      (dolist (new-elt (reverse (nth 3 elt)))
		(when (fboundp (nth 1 new-elt))
		  (pushnew (nth 1 new-elt) ergoemacs-status-elements-popup)
		  (define-key map (vector (nth 1 new-elt))
		  `(menu-item ,(nth 0 new-elt) (lambda (&rest _) (interactive) (call-interactively ',(nth 1 new-elt)) (ergoemacs-status-elements-popup-save)) :button (:toggle . ,(nth 1 new-elt))))))))))
       (t
	(when (setq elt (assoc elt ergoemacs-status-elements))
	  (if (stringp (nth 3 elt))
	      (define-key map (vector (car elt))
		`(menu-item ,(nth 3 elt) (lambda(&rest _) (interactive) (ergoemacs-status-elements-toggle ,(car elt)))
			    :button (:toggle . (not (memq ,(car elt) ergoemacs-status--suppressed-elements)))))
	    (dolist (new-elt (reverse (nth 3 elt)))
	      (when (fboundp (nth 1 new-elt))
		(pushnew (nth 1 new-elt) ergoemacs-status-elements-popup)
		(define-key map (vector (nth 1 new-elt))
		  `(menu-item ,(nth 0 new-elt) (lambda (&rest _) (interactive) (call-interactively ',(nth 1 new-elt)) (ergoemacs-status-elements-popup-save)) :button (:toggle . ,(nth 1 new-elt))))))))))
      (setq i (1+ i)))
    (if dont-popup map
      (popup-menu map))))

(defvar ergoemacs-status-buffer-id-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line mouse-1] #'ergoemacs-status-mouse-1-buffer)
    (define-key map [mode-line mouse-3] #'ergoemacs-status-mouse-3-buffer)
    map)
  "Keymap for clicking on the buffer status.")

(defun ergoemacs-status-buffer-id ()
  "Gives the Buffer identification string."
  (propertize "%12b"
	      'mouse-face 'mode-line-highlight
	      'face 'mode-line-buffer-id
	      'local-map ergoemacs-status-buffer-id-map
	      'help-echo "Buffer name\nBuffer menu"))

(defvar ergoemacs-status-major-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line down -mouse-3] (lookup-key mode-line-major-mode-keymap [mode-line down-mouse-3]))
    (define-key map [mode-line mouse-2] #'describe-mode)
    (define-key map [mode-line down-mouse-1]
      `(menu-item "Menu Bar" ignore :filter ergoemacs-status--major-mode-menu-map))
    map)
  "Major mode keymap.")

(defun ergoemacs-status-major-mode-item ()
  "Gives `major-mode' item for mode-line."
  (propertize mode-name
	      'mouse-face 'mode-line-highlight
	      'local-map ergoemacs-status-major-mode-map
	      'help-echo "Major mode\nmouse-1: Display major mode menu\nmouse-2: Show help for major mode\nmouse-3: Toggle minor modes"))

(defvar which-func-format)
(defun ergoemacs-status-which-function-mode ()
  "Display `which-func-format' without brackets."
  (when (and (boundp 'which-function-mode) which-function-mode)
    (substring (format-mode-line which-func-format) 1 -1)))

(defun ergoemacs-status-current-update (&optional theme-list direction)
  "Update mode-line processing based on `ergoemacs-status-current'.

This should be called with no arguments.  The optional arguments
are for a recursive calls to this function.

THEME-LIST is the list of components.  This is passed when
`ergoemacs-status-current-update' is called recursively.

DIRECTION is the direction of the current
update.  (Either :left, :center or :right).  This is passed
through a recursive call of `ergoemacs-status-current-update'."
  (if (memq :flycheck ergoemacs-status--suppressed-elements)
      (ergoemacs-minor-mode-hide 'flycheck-mode nil t)
    (ergoemacs-minor-mode-hide 'flycheck-mode t t))
  (if (not direction)
      (setq ergoemacs-status--lhs (ergoemacs-status-current-update (plist-get ergoemacs-status-current :left) :left)
	    ergoemacs-status--center (ergoemacs-status-current-update (plist-get ergoemacs-status-current :center) :center) 
	    ergoemacs-status--rhs (ergoemacs-status-current-update (plist-get ergoemacs-status-current :right) :right))
    (let (ret
	  stat-elt
	  reduce
	  ifc
	  lst
	  first-p
	  last-p)
      (dolist (elt (reverse theme-list))
	(setq first-p t)
	(if (consp elt)
	    (dolist (combine-elt (reverse elt))
	      (cond
	       ((and (setq stat-elt (and (not (memq combine-elt ergoemacs-status--suppressed-elements))
					 (assoc combine-elt ergoemacs-status-elements))))
		(setq ifc (nth 1 stat-elt)
		      reduce (nth 2 stat-elt)
		      last-p (eq (car theme-list) combine-elt) 
		      lst nil)
		(when reduce
		  (push reduce lst)
		  (push :reduce lst))
		(push elt lst)
		(push :element lst)
		(unless (or (and last-p (not (eq direction :right)))
			    (and first-p (eq direction :right)))
		  (push t lst)
		  (push :last-p lst))
		(push ifc lst)
		(push lst ret)
		(setq first-p nil))))
	  
	  (cond
	   ((setq stat-elt (and (not (memq elt ergoemacs-status--suppressed-elements))
				(assoc elt ergoemacs-status-elements)))
	    (setq ifc (nth 1 stat-elt)
		  reduce (nth 2 stat-elt)
		  lst nil)
	    (when reduce
	      (push reduce lst)
	      (push :reduce lst))
	    (push elt lst)
	    (push :element lst)
	    (push ifc lst)
	    (push lst ret)))))
      ret)))

(defun ergoemacs-status--atom ()
  "Atom style layout."
  (setq ergoemacs-status-current
	'(:left ((:read-only :buffer-id :modified) :size :nyan :position :vc)
		:center ((:minor :narrow))
		:right (:global :process :coding :eol :major)))
  (ergoemacs-status-current-update)
  (force-mode-line-update))

(defun ergoemacs-status--center ()
  "Center theme."
  (setq ergoemacs-status-current
	'(:left (:major :which :vc :size :nyan :position :flycheck)
		 :center ((:read-only :buffer-id :modified))
		 :right (:global :process :coding :eol (:minor :narrow))))
  (ergoemacs-status-current-update)
  (force-mode-line-update))

(defun ergoemacs-status--xah ()
  "Xah status theme."
  (setq ergoemacs-status-current
	'(:left ((:read-only :buffer-id :modified) :size :nyan :position :major :global)))
  (ergoemacs-status-current-update)
  (force-mode-line-update))

(defun ergoemacs-status--space ()
  "Spacemacs like theme."
  (setq ergoemacs-status-current
	'(:left ((:persp-name :workspace-number :window-number)
		 ;; :anzu
		 :auto-compile
		 (:read-only :size :buffer-id :modified :remote) :major :flycheck :minor :process :erc :vc
		 :org-pomodoro :org-clock :nyan-cat)
		:right (:battery :selection-info :coding :eol :position :hud))
	powerline-default-separator 'wave 
	ergoemacs-status--minor-modes-separator "|")
  (ergoemacs-status-current-update)
  (force-mode-line-update))

(ergoemacs-status--space)

(defun ergoemacs-status--eval-center (mode-line face1 &optional reduce)
  "Evalate the center of the mode-line.
MODE-LINE is mode-line face
FACE1 is the alternative face.
REDUCE is the reduction level."
  (unless (memq ergoemacs-status--sep ergoemacs-status--swap)
    (setq ergoemacs-status--sep 'left))
  (or (and ergoemacs-status--center (ergoemacs-status--stack ergoemacs-status--center mode-line face1 'center reduce))
      ""))

(defun ergoemacs-status--eval-lhs (mode-line face1 &optional reduce)
  "Evalate the left hand side of the mode-line.
MODE-LINE is mode-line face
FACE1 is the alternative face.
REDUCE is the reduction level."
  (setq ergoemacs-status--sep 'left)
  (ergoemacs-status--stack ergoemacs-status--lhs mode-line face1 'left reduce))

(defun ergoemacs-status--eval-rhs (mode-line face1 &optional reduce)
  "Evalate the right hand side of the mode-line.
MODE-LINE is mode-line face
FACE1 is the alternative face.
REDUCE is the reduction level."
  (unless (memq ergoemacs-status--sep ergoemacs-status--swap)
    (setq ergoemacs-status--sep 'right))
  (or (and ergoemacs-status--rhs (ergoemacs-status--stack ergoemacs-status--rhs mode-line face1 'right reduce)) ""))


(defvar ergoemacs-status-down-element nil)

(defvar ergoemacs-status--eval nil)

(defun ergoemacs-status-hover (x-position)
  "Get the hover element at the X-POSITION."
  (let ((i 0))
    (catch 'found
      (dolist (elt ergoemacs-status--eval)
	(setq i (+ i (nth 1 elt)))
	(when (<= x-position i)
	  (throw 'found (nth 0 elt))))
      nil)))

(defun ergoemacs-status-swap-hover-- (elt hover)
  "Internal function for `ergoemacs-status-swap-hover'.
Swaps ELT based on HOVER element and `ergoemacs-status-down-element'"
  (cond
   ((equal elt hover)
    ergoemacs-status-down-element)
   ((equal elt ergoemacs-status-down-element)
    hover)
   (t elt)))

(defun ergoemacs-status-swap-hover (hover)
  "Change `ergoemacs-status-current' based on swapping elements.
HOVER is the current element that is being overed over and will
be swapped with the `ergoemacs-status-down-element' element."
  (when ergoemacs-status-down-element
    (let* ((left (plist-get ergoemacs-status-current :left))
	   (center (plist-get ergoemacs-status-current :center))
	   (right (plist-get ergoemacs-status-current :right))
	   (down (cond
		  ((member ergoemacs-status-down-element left) 'left)
		  ((member ergoemacs-status-down-element center) 'center)
		  ((member ergoemacs-status-down-element right) 'right)))
	   (hover-region (cond
			  ((member hover left) 'left)
			  ((member hover center) 'center)
			  ((member hover right) 'right)))
	   tmp)
      (cond
       ;; Same element.
       ((and (eq down hover-region) (eq down 'left))
	(setq left (mapcar (lambda(elt) (ergoemacs-status-swap-hover-- elt hover)) left)))
       ((and (eq down hover-region) (eq down 'center))
	(setq center (mapcar (lambda(elt) (ergoemacs-status-swap-hover-- elt hover)) center)))
       ((and (eq down hover-region) (eq down 'right))
	(setq right (mapcar (lambda(elt) (ergoemacs-status-swap-hover-- elt hover)) right)))
       ;; left->center
       ((and (eq down 'left) (eq hover-region 'center))
	(dolist (elt (reverse left))
	  (unless (equal ergoemacs-status-down-element elt)
	    (push elt tmp)))
	(push ergoemacs-status-down-element center)
	(setq left tmp))
       ;; center->left
       ((and (eq down 'center) (eq hover-region 'left))
	(dolist (elt (reverse center))
	  (unless (equal ergoemacs-status-down-element elt)
	    (push elt tmp)))
	(push ergoemacs-status-down-element left)
	(setq center tmp))
       ;; left->right
       ((and (eq down 'left) (eq hover-region 'right))
	(dolist (elt (reverse left))
	  (unless (equal ergoemacs-status-down-element elt)
	    (push elt tmp)))
	(push ergoemacs-status-down-element right)
	(setq left tmp))
       ;; right->left
       ((and (eq down 'right) (eq hover-region 'left))
	(dolist (elt (reverse right))
	  (unless (equal ergoemacs-status-down-element elt)
	    (push elt tmp)))
	(push ergoemacs-status-down-element left)
	(setq right tmp))
       ;; center->right
       ((and (eq down 'center) (eq hover-region 'right))
	(dolist (elt (reverse center))
	  (unless (equal ergoemacs-status-down-element elt)
	    (push elt tmp)))
	(push ergoemacs-status-down-element right)
	(setq center tmp))
       ;; right->center
       ((and (eq down 'right) (eq hover-region 'center))
	(dolist (elt (reverse right))
	  (unless (equal ergoemacs-status-down-element elt)
	    (push elt tmp)))
	(push ergoemacs-status-down-element center)
	(setq right tmp)))
      (setq ergoemacs-status-current `(:left ,left :center ,center :right ,right))
      (ergoemacs-status-current-update)
      (force-mode-line-update))))

(defun ergoemacs-status-down (start-event)
  "Handle down-mouse events on `mode-line'.
START-EVENT is where the mouse was clicked."
  (interactive "e")
  (let* ((start (event-start start-event))
	 (window (posn-window start))
	 (frame (window-frame window))
	 (object (posn-object start))
	 ;; (minibuffer-window (minibuffer-window frame))
	 (element (and (stringp (car object))
		       (get-text-property (cdr object) :element (car object))))
	 hover finished event position)
    (setq ergoemacs-status-down-element element)
    (force-mode-line-update)
    (track-mouse
      (while (not finished)
	(setq event (read-event)
	      position (mouse-position))
	;; Do nothing if
	;;   - there is a switch-frame event.
	;;   - the mouse isn't in the frame that we started in
	;;   - the mouse isn't in any Emacs frame
	;; Drag if
	;;   - there is a mouse-movement event
	;;   - there is a scroll-bar-movement event (Why? -- cyd)
	;;     (same as mouse movement for our purposes)
	;; Quit if
	;;   - there is a keyboard event or some other unknown event.
	(cond
	 ((not (consp event))
	  (setq finished t))
	 ((memq (car event) '(switch-frame select-window))
	  nil)
	 ((not (memq (car event) '(mouse-movement scroll-bar-movement)))
	  (when (consp event)
	    ;; Do not unread ANY mouse events.
	    (unless (eq (event-basic-type (car event)) 'mouse-1)
	      (push event unread-command-events)))
	  (setq finished t))
	 ((not (and (eq (car position) frame)
		    (cadr position)))
	  nil))
	(when (and (not finished))
	  (setq hover (ergoemacs-status-hover (car (cdr position))))
	  (when hover
	    (ergoemacs-status-swap-hover hover)))
	(clear-this-command-keys t)))
    (setq ergoemacs-status-down-element nil)
    (ergoemacs-status-save-file)
    (force-mode-line-update)))

(defun ergoemacs-status--modify-map (map)
  "Modify MAP to include context menu. 
Also allows arrangment with C- M- or S- dragging of elements."
  (let ((map map) tmp)
    (if (not map)
	(setq map (make-sparse-keymap))
      (setq map (copy-keymap map)))
    (when (or (not (setq tmp (lookup-key map [mode-line mouse-3])))
	      (memq tmp '(ergoemacs-ignore ignore)))
      ;; (message "Add to %s" elt)
      (define-key map [mode-line mouse-3] #'ergoemacs-status-right-click))
    (define-key map [mode-line C-down-mouse-1] #'ergoemacs-status-down)
    (define-key map [mode-line M-down-mouse-1] #'ergoemacs-status-down)
    (define-key map [mode-line S-down-mouse-1] #'ergoemacs-status-down)
    ;; (setq down-mouse-1 (lookup-key map [mode-line down-mouse-1])
    ;; 	  mouse-1 (lookup-key map [mode-line mouse-1]))
    ;; (when (and down-mouse-1 (or (not mouse-1) (memq mouse-1 '(ignore ergoemacs-ignore))))
    ;;   (define-key map [mode-line mouse-1] down-mouse-1)
    ;;   (define-key map [mode-line down-mouse-1] #'ergoemacs-status-down)
    ;;   (define-key map [mode-line drag-mouse-1] #'ergoemacs-status-drag))
    map))

(defun ergoemacs-status--pad (str &optional type)
  "Pads STR retaining properties at end or beginning of string.

When TYPE is:

- missing or :right, it pads the right with a space.
- :left, it pads the left with a space.
- :both, it pads the left and right with spaces.

This padding is sticky -- it inherits the properties of the
string on the left or the right.  Additionally the final text
properties of front-sticky is set to nil and read-nonsticy is set
to t. This removes the stickiness properties of the string."
  (let* ((modified (buffer-modified-p)) (buffer-undo-list t)
	 (inhibit-read-only t) (inhibit-point-motion-hooks t)
	 before-change-functions after-change-functions
	 deactivate-mark
					; Prevent primitives checking  for file modification
	 buffer-file-name buffer-file-truename
	 (type (or type :right))
	 (str (propertize str 'front-sticky t)))
    (unwind-protect
	(propertize (with-temp-buffer
		      (insert str)
		      (when (memq type '(:right :both))
			(insert-and-inherit " "))
		      (when (memq type '(:left :both))
			(goto-char (point-min))
			(insert-and-inherit " "))
		      (buffer-string))
		    'front-sticky nil
		    'rear-nonsticky t)
      (and (not modified)
	   (buffer-modified-p)
	   (set-buffer-modified-p nil)))))

(defun ergoemacs-status--stack (mode-line-list face1 face2 dir &optional reduction-level)
  "Stacks mode-line elements.
MODE-LINE-LIST is the list of elements to stack.
FACE1 is the first face to alternate between
FACE2 is the second face to alternate between
DIR is the direction 'left 'right or 'center
REDUCTION-LEVEL is the level the current element is being reduced to."
  (let* (ret
	 (face-list (list face1 face2))
	 (len (length face-list))
	 (i 0)
	 plist ifs reduce
	 (lst (if (eq dir 'right)
		  mode-line-list
		(reverse mode-line-list)))
	 (cur-dir dir)
	 last-face cur-face tmp)
    (dolist (elt lst)
      (setq ifs (car elt)
	    plist (cdr elt)
	    reduce (plist-get plist :reduce))
      (unless (and reduce (integerp reduce)
		   reduction-level (integerp reduction-level)
		   (<= reduce reduction-level))
	;; Still in the running.
	(setq tmp (ergoemacs-status--if ifs (if (and ergoemacs-status-down-element
						     (equal (plist-get plist :element) ergoemacs-status-down-element))
						'ergoemacs-status-selected-element 
					      (nth (mod i len) face-list))))
	(unless (and tmp (stringp tmp) (string= (format-mode-line tmp) ""))
	  (unless (or (plist-get plist :last-p) (eq dir 'center))
	    (setq i (1+ i)))
	  (setq tmp (propertize (replace-regexp-in-string "\\( +$\\|^ +\\)" "" tmp)
				:element (plist-get plist :element)))
	  (push tmp ret))))
    (when (eq (get-text-property 0 'face (format-mode-line (nth 0 ret)))
		(nth 1 face-list))
      ;; Reverse faces
      (setq ret (mapcar (lambda(elt)
      			  (cond
      			   ((eq (get-text-property 0 'face elt) (nth 0 face-list))
      			    (propertize elt 'face (nth 1 face-list)))
      			   ((eq (get-text-property 0 'face elt) (nth 1 face-list))
      			    (propertize elt 'face (nth 0 face-list)))
      			   (t elt)))
      			ret)))
    ;; Fix keys -- Right click brings up conext menu.
    (setq ret (mapcar
	       (lambda(elt)
		 (mapconcat
		  (lambda (mm)
		    (propertize mm 'local-map (ergoemacs-status--modify-map (get-text-property 0 'local-map mm))))
		  (ergoemacs-status--property-substrings elt 'local-map)
		  ""))
	       ret))
    ;; Add separators
    (setq last-face (get-text-property 0 'face (nth 0 ret))
	  ret (mapcar
	       (lambda(elt)
		 (setq cur-face (get-text-property 0 'face elt))
		 (prog1
		     (cond
		      ((equal cur-face last-face)
		       (ergoemacs-status--pad elt))
		      ((eq dir 'left)
		       (concat (ergoemacs-status--sep last-face cur-face)
			       (ergoemacs-status--pad elt :both)))
		      ((eq dir 'right)
		       (concat (ergoemacs-status--pad elt :both) (ergoemacs-status--sep cur-face last-face)))
		      ((eq dir 'center)
		       (ergoemacs-status--pad elt :both)))
		   (setq last-face cur-face)))
	       ret))
    (cond
     ((eq dir 'center)
      (setq tmp (ergoemacs-status--pad (pop ret) :left)
	    ret (append (list (ergoemacs-status--sep face2 face1))
			(list tmp)
			ret
			(progn
			  (unless (memq ergoemacs-status--sep ergoemacs-status--swap)
			    (setq ergoemacs-status--sep 'right))
			  (list (ergoemacs-status--sep face1 face2))))))
     ((eq last-face face2))
     ((eq dir 'left)
      (setq ret (append ret (list (ergoemacs-status--sep last-face face2)))))
     ((eq dir 'right)
      (setq ret (append ret (list (ergoemacs-status--sep face2 last-face))))))
    (setq ret (if (eq dir 'right)
		  (reverse ret)
		ret))))

(defcustom ergoemacs-status-extra-width 0
  "Extra width to add."
  :type 'integer
  :group 'ergoemacs-status)

(defcustom ergoemacs-status-width-multiplier 1.0
  "Multiplier for width."
  :type 'number
  :group 'ergoemacs-status)

(defvar ergoemacs-status--pixel-width-p nil
  "Determines if the mode line tries to calculate width in pixels.")

(defun ergoemacs-status--eval-width (&optional what)
  "Evaluate the width of an element or window.
If WHAT is nil, this returns the width of a window.
If WHAT is an element, returns the width of that element."
  (if ergoemacs-status--pixel-width-p
      (ergoemacs-status--eval-width-pixels what)
    (ergoemacs-status--eval-width-col what)))

(defun ergoemacs-status--eval-string-width-pixels (str)
  "Get string STR width in pixels."
  (with-current-buffer (get-buffer-create " *ergoemacs-eval-width*")
	(delete-region (point-min) (point-max))
	(insert str)
	(car (window-text-pixel-size nil (point-min) (point-max)))))

(defun ergoemacs-status--eval-width-pixels (&optional what)
  "Get the width of the display in pixels.
If WHAT is nil, return the width of the display.
If WHAT is an element, return the width of the element."
  (ergoemacs-status--eval-width-col what t))

(defun ergoemacs-status--eval-width-col-string (str &optional pixels-p)
  "Figure out the column width of STR.
When PIXELS-P is non-nil, use pixels instead of column width."
  (apply
   '+
   (mapcar (lambda(x)
	     (let ((display (get-text-property 0 'display x)))
	       (if display
		   (car (image-size display pixels-p))
		 (if pixels-p
		     (ergoemacs-status--eval-string-width-pixels x)
		   (string-width x)))))
	   (ergoemacs-status--property-substrings str 'display))))

(defvar ergoemacs-stats--ignore-eval-p nil
  "Determine if the evaluate will complete.")

(defun ergoemacs-status--eval-width-col (&optional what pixels-p)
  "Eval width of WHAT, which is formated with `format-mode-line'.
When WHAT is nil, return the width of the window.
When PIXELS-P is non-nil, return the width in pixels instead of column width."
  (or (and what (ergoemacs-status--eval-width-col-string (format-mode-line what pixels-p)))
      (if pixels-p
	  (let ((width (ergoemacs-status--eval-width-col))
		(cw (frame-char-width)))
	    (* cw width))
	(let ((width (window-width))
	      ;; (cw (frame-char-width))
	      tmp)
	  (when (setq tmp (window-margins))
	    (setq width (apply '+ width (list (or (car tmp) 0) (or (cdr tmp) 0)))))
	  (setq width (* ergoemacs-status-width-multiplier (+ width ergoemacs-status-extra-width)))
	  (setq ergoemacs-stats--ignore-eval-p t)
	  (unwind-protect
	      (setq width (- width (ergoemacs-status--eval-width-col-string (format-mode-line mode-line-format) pixels-p)))
	    (setq ergoemacs-stats--ignore-eval-p nil))))))

(defvar ergoemacs-status-max-reduction 4)

(defvar mode-icons-read-only-space)

(defvar mode-icons-show-mode-name)

(defvar mode-icons-eol-text)

(defvar mode-icons-cached-mode-name)

(defvar ergoemacs-status--eval-blank-map
  (let ((map (make-sparse-keymap)))
    (define-key map [mode-line mouse-3] #'ergoemacs-status-right-click)
    (define-key map [mode-line down-mouse-1] #'mouse-drag-mode-line)
    map)
  "Keymap for the filling spaces.")

(defun ergoemacs-status--eval ()
  "Mode-line element for `ergoemacs-status' mode-line."
  (if ergoemacs-stats--ignore-eval-p ""
    ;; This will dynamically grow/fill areas
    (setq mode-icons-read-only-space nil
	  mode-icons-show-mode-name t
	  mode-icons-eol-text t
	  mode-name (or (and (fboundp #'mode-icons-get-mode-icon)
			     (ergoemacs-status-save-buffer-state
			      (mode-icons-get-mode-icon (or mode-icons-cached-mode-name mode-name))))
			mode-name))
    (let* ((active (or (and (fboundp #'powerline-selected-window-active) (powerline-selected-window-active)) t))
	   (mode-line (if active 'mode-line 'mode-line-inactive))
	   (face1 (if active 'powerline-active1 'powerline-inactive1))
	   (face2 (if active 'powerline-active2 'powerline-inactive2))
	   (mode-icons-read-only-space nil)
	   (mode-icons-show-mode-name t)
	   lhs rhs center
	   wlhs wrhs wcenter
	   available
	   (reduce-level 1))
      (setq ergoemacs-status--minor-modes-available nil
	    lhs (ergoemacs-status--eval-lhs mode-line face1 face2)
	    rhs (ergoemacs-status--eval-rhs mode-line face1 face2)
	    center (ergoemacs-status--eval-center mode-line face1 face2)
	    wlhs (ergoemacs-status--eval-width lhs)
	    wrhs (ergoemacs-status--eval-width rhs)
	    wcenter (ergoemacs-status--eval-width center)) 
      (when (> (+ wlhs wrhs wcenter) (ergoemacs-status--eval-width))
	(setq mode-icons-read-only-space nil
	      mode-icons-show-mode-name nil
	      mode-icons-eol-text nil
	      mode-name (or (and (fboundp #'mode-icons-get-mode-icon)
				 (mode-icons-get-mode-icon (or mode-icons-cached-mode-name mode-name)))
			    mode-name)
	      lhs (ergoemacs-status--eval-lhs mode-line face1 face2)
	      rhs (ergoemacs-status--eval-rhs mode-line face1 face2)
	      center (ergoemacs-status--eval-center mode-line face1 face2)
	      wlhs (ergoemacs-status--eval-width lhs)
	      wrhs (ergoemacs-status--eval-width rhs)
	      wcenter (ergoemacs-status--eval-width center))
	(while (and (<= reduce-level ergoemacs-status-max-reduction)
		    (> (+ wlhs wrhs wcenter) (ergoemacs-status--eval-width)))
	  (setq mode-icons-read-only-space nil
		mode-icons-show-mode-name nil
		mode-icons-eol-text nil
		lhs (ergoemacs-status--minor-modes-available mode-line face1)
		lhs (ergoemacs-status--eval-lhs mode-line face1 reduce-level)
		rhs (ergoemacs-status--eval-rhs mode-line face1 reduce-level)
		center (ergoemacs-status--eval-center mode-line face1 reduce-level)
		wlhs (ergoemacs-status--eval-width lhs)
		wrhs (ergoemacs-status--eval-width rhs)
		wcenter (ergoemacs-status--eval-width center)
		reduce-level (+ reduce-level 1))))
      (setq available (/ (- (ergoemacs-status--eval-width) (+ wlhs wrhs wcenter)) 2))
      (if ergoemacs-status--pixel-width-p
	  (setq available (list available)))
      ;; (message "a: %s (%3.1f %3.1f %3.1f; %3.1f)" available wlhs wrhs wcenter (ergoemacs-status--eval-width))
      (prog1
	  (set (make-local-variable 'ergoemacs-status--eval)
		(list lhs
		      (propertize (make-string (floor available) ? ) 'display `((space :width ,available))
				  'face face1
				  'local-map ergoemacs-status--eval-blank-map)
		      center
		      (propertize (make-string (floor available) ? ) 'display `((space :width ,available))
				  'face face1
				  'local-map ergoemacs-status--eval-blank-map)
		      rhs))
	(set (make-local-variable 'ergoemacs-status--eval)
	      (mapcar
	       (lambda(x)
		 (list (get-text-property 0 :element x)
		       (or (ignore-errors (ergoemacs-status--eval-width x))
			   available)))
	       (ergoemacs-status--property-substrings (format-mode-line ergoemacs-status--eval) :element)))))))

(defun ergoemacs-status--variable-pitch (&optional frame)
  "Change the mode-line faces to have variable picth fonts.
FRAME is the frame that is modified."
  (dolist (face '(mode-line mode-line-inactive
			    powerline-active1
			    powerline-inactive1
			    powerline-active2 powerline-inactive2))
    (set-face-attribute face frame
			  :family (face-attribute 'variable-pitch :family)
			  :foundry (face-attribute 'variable-pitch :foundry)
			  :height 125)))

(defvar ergoemacs-old-mode-line-format nil
  "Old `mode-line-format'.")

(defvar ergoemacs-old-mode-line-front-space nil
  "Old `mode-line-front-space'.")

(defvar ergoemacs-old-mode-line-mule-info nil
  "Old `mode-line-mule-info'.")

(defvar ergoemacs-old-mode-line-client nil
  "Old `mode-line-client'.")

(defvar ergoemacs-old-mode-line-modified nil
  "Old `mode-line-modified'.")

(defvar ergoemacs-old-mode-line-remote nil
  "Old `mode-line-remote'.")

(defvar ergoemacs-old-mode-line-frame-identification nil
  "Old `mode-line-frame-identification'.")

(defvar ergoemacs-old-mode-line-buffer-identification nil
  "Old `mode-line-buffer-identification'.")

(defvar ergoemacs-old-mode-line-position nil
  "Old `mode-line-position'.")

(defvar ergoemacs-old-mode-line-modes nil
  "Old `mode-line-modes'.")

(defvar ergoemacs-old-mode-line-misc-info nil
  "Old `mode-line-misc-info'.")

(defvar ergoemacs-old-mode-line-end-spaces nil
  "Old `mode-line-end-spaces'.")

(defvar ergoemacs-status-save-mouse-3 nil
  "Old right click button.")

(defun ergoemacs-status-format (&optional restore)
  "Setup `ergoemacs-status' `mode-line-format'.
When RESTORE is non-nil, restore the `mode-line-format'.r"
  (if restore
      (progn
	(set-default 'mode-line-format
		     ergoemacs-old-mode-line-format)
	(setq mode-line-front-space ergoemacs-old-mode-line-front-space
	      mode-line-mule-info ergoemacs-old-mode-line-mule-info
	      mode-line-client ergoemacs-old-mode-line-client
	      mode-line-modified ergoemacs-old-mode-line-modified
	      mode-line-remote ergoemacs-old-mode-line-remote
	      mode-line-frame-identification ergoemacs-old-mode-line-frame-identification
	      mode-line-buffer-identification ergoemacs-old-mode-line-buffer-identification
	      mode-line-position ergoemacs-old-mode-line-position
	      mode-line-modes ergoemacs-old-mode-line-modes
	      mode-line-misc-info ergoemacs-old-mode-line-misc-info
	      mode-line-end-spaces ergoemacs-old-mode-line-end-spaces)
	(define-key global-map [mode-line mouse-3] (symbol-value ergoemacs-status-save-mouse-3))
	;; FIXME -- restore old in all buffers.e
	)
    (unless ergoemacs-old-mode-line-format
      (setq ergoemacs-old-mode-line-format mode-line-format
	    ergoemacs-old-mode-line-front-space mode-line-front-space
	    ergoemacs-old-mode-line-mule-info mode-line-mule-info
	    ergoemacs-old-mode-line-client mode-line-client
	    ergoemacs-old-mode-line-modified mode-line-modified
	    ergoemacs-old-mode-line-remote mode-line-remote
	    ergoemacs-old-mode-line-frame-identification mode-line-frame-identification
	    ergoemacs-old-mode-line-buffer-identification mode-line-buffer-identification
	    ergoemacs-old-mode-line-position mode-line-position
	    ergoemacs-old-mode-line-modes mode-line-modes
	    ergoemacs-old-mode-line-misc-info mode-line-misc-info
	    ergoemacs-old-mode-line-end-spaces mode-line-end-spaces
	    ergoemacs-status-save-mouse-3 (key-binding [mode-line mouse-3])))

    (setq-default mode-line-format
		  `("%e" mode-line-front-space
		    ;; mode-line-mule-info
		    ;; mode-line-client
		    ;; mode-line-modified
		    ;; mode-line-remote
		    ;; mode-line-frame-identification
		    ;; mode-line-buffer-identification
		    ;; mode-line-position -- in position function
		    ;; mode-line-modes --not changed
		    (:eval (ergoemacs-status--eval))
		    mode-line-misc-info
		    mode-line-end-spaces))
    (setq mode-line-front-space (list "")
	  mode-line-mule-info (list "")
	  mode-line-client (list "")
	  mode-line-modified (list "")
	  mode-line-remote (list "")
	  mode-line-frame-identification (list "")
	  mode-line-buffer-identification (list "")
	  mode-line-position (list "")
	  mode-line-modes (list "")
	  mode-line-misc-info (list "")
	  mode-line-end-spaces (list ""))
    ;; FIXME -- Apply to all buffers.
    (force-mode-line-update)))

(defvar ergoemacs-status-turn-off-mode-icons nil)
(defvar mode-icons-mode)
(define-minor-mode ergoemacs-status-mode
  "Ergoemacs status mode."
  :global t
  (if ergoemacs-status-mode
      (progn
	(if (and (boundp 'mode-icons-mode) mode-icons-mode)
	    (setq ergoemacs-status-turn-off-mode-icons nil)
	  (setq ergoemacs-status-turn-off-mode-icons t)
	  (mode-icons-mode 1))
	(ergoemacs-status-format))
    (when ergoemacs-status-turn-off-mode-icons
      (mode-icons-mode -1))
    (ergoemacs-status-format t)))

(load ergoemacs-status-file t)
(provide 'ergoemacs-status)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; ergoemacs-status.el ends here
