;;; cframe.el --- Customize a frame and fast switch size and positions  -*- lexical-binding: t; -*-

;; Copyright (C) 2015 - 2020 Paul Landes

;; Version: 0.4
;; Package-Version: 20201222.1930
;; Package-Commit: 38544521e82befc06e397123a118dd96dda2c6b6
;; Author: Paul Landes
;; Maintainer: Paul Landes
;; Keywords: frames
;; URL: https://github.com/plandes/cframe
;; Package-Requires: ((emacs "26") (buffer-manage "0.11") (dash "2.17.0"))

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; Allows for customization of Emacs frames, which include height and width of
;; new Emacs frames.  Options for new frames are those given to `make-frame`.
;; This is handy for those that rather resize your Emacs frames with a key
;; binding than using your mouse.

;; The library "learns" frame configurations, then restores them later on:

;; * Record frame positions with `M-x cframe-add-or-advance-setting`.
;; * Restore previous settings on start up with `cframe-restore`.
;; * Cycles through configuratinos with `cframe-add-or-advance-setting`.
;; * Pull up the [entries buffer] with `cframe-list`.

;; I use the following in my `~/.emacs` configuration file:

;; (require 'cframe)
;; ;; frame size settings based on screen dimentions
;; (global-set-key "\C-x9" 'cframe-restore)
;; ;; doesn't clobber anything in shell, Emacs Lisp buffers (maybe others?)
;; (global-set-key "\C-\\" 'cframe-add-or-advance-setting)
;; ;; toggle full or maximized screen
;; (global-set-key "\C-x\C-\\" 'cframe-toggle-frame-full-or-maximized)


;;; Code:

(require 'cl-lib)
(require 'eieio)
(require 'dash)
(require 'config-manage)

(defvar cframe-settings-restore-hooks nil
  "Functions to call with `cframae-settings-restore' is called.
When hook functions are called `setting' is bound to an instance
of `cframe-settings'.")

(defclass cframe-setting (config-entry)
  ((width :initarg :width
	  :initform 80
	  :type integer
	  :documentation "Width of the frame.")
   (height :initarg :height
	   :initform 120
	   :type integer
	   :documentation "Height of the frame.")
   (position :initarg :position
	     :initform (0 . 0)
	     :type cons
	     :documentation "Top/left position of the frame.")
   (full-mode :initarg :full-mode
	      :initform none
	      :type symbol
	      :documentation "One of to indicate the frame is in:
 * `fullscreen': full screen mode
 * `maximized': maximized taking up the entire screen
 * `none': neither fullscreen nor maximized"))
  :method-invocation-order :c3
  :documentation "A frame settings: size and location.")

(cl-defmethod initialize-instance ((this cframe-setting) &optional slots)
  "Initialize THIS instance using SLOTS as initial values."
  (config-entry-save this)
  (cframe-setting-set-name this)
  (setq slots (plist-put slots :pslots
			 (append (plist-get slots :pslots)
				 '(width height position full-mode))))
  (cl-call-next-method this slots))

(cl-defmethod cframe-setting-frame ((this cframe-setting))
  "Return THIS setting's frame."
  (ignore this)
  (selected-frame))

(cl-defmethod config-entry-description ((this cframe-setting))
  "Get the description of THIS configuration's entry."
  (with-slots (width height full-mode) this
    (format "w: %d, h: %d, f: %S" width height full-mode)))

(cl-defmethod cframe-setting-frame-attributes ((this cframe-setting))
  "Return attributes about THIS frame."
  (let ((frame (cframe-setting-frame this)))
    (-> frame
	frame-monitor-attributes
	(append (cons (cons 'fullscreen
			    (frame-parameter frame 'fullscreen))
		      nil)))))

(cl-defmethod cframe-setting-frame-full-mode ((this cframe-setting))
  "Return THIS frame's full mode as a symbol.

See the `cframe-setting' class's `full-slot' for more information."
  (cl-case (->> (cframe-setting-frame-attributes this)
		(assq 'fullscreen)
		cdr)
    ('fullscreen 'fullscreen)
    ('fullboth 'fullscreen)
    ('maximized 'maximized)
    (t 'none)))

(cl-defmethod config-entry-save ((this cframe-setting))
  "Save THIS current frame's configuration."
  (let ((frame (cframe-setting-frame this)))
    (with-slots (width height position full-mode) this
      (setq width (frame-width frame)
	    height (frame-height frame)
	    position (frame-position)
	    full-mode (cframe-setting-frame-full-mode this)))))

(cl-defmethod config-entry-restore ((this cframe-setting))
  "Restore THIS frame's to the current state of the setting."
  (let ((frame (cframe-setting-frame this))
	(prev-full-mode (cframe-setting-frame-full-mode this))
	(next-full-mode (slot-value this 'full-mode)))
    (with-slots (width height position) this
      (unless (eq prev-full-mode next-full-mode)
	(cl-case prev-full-mode
	  ('fullscreen (toggle-frame-fullscreen))
	  ('maximized (toggle-frame-maximized))))
      (cl-case next-full-mode
	('fullscreen (toggle-frame-fullscreen))
	('maximized (toggle-frame-maximized))
	(t (set-frame-width frame width)
	   (set-frame-height frame height)
	   (set-frame-position frame (car position) (cdr position)))))
    (let ((setting this))
      (ignore setting)
      (run-hooks 'cframe-settings-restore-hooks))))

(cl-defmethod cframe-setting-set-name ((this cframe-setting)
				       &optional new-name)
  "Set the name of THIS `cframe-setting' to NEW-NAME."
  (with-slots (width full-mode) this
    (let ((new-name
	   (or new-name
	       (cond ((not (eq 'none full-mode)) (prin1-to-string full-mode))
		     ((<= width 80) "narrow")
		     ((<= width 140) "wide")
		     (t "huge")))))
      (config-entry-set-name this new-name))))

(cl-defmethod eieio-object-name-string ((this cframe-setting))
  "Return a string as a representation of the in memory instance of THIS."
  (with-slots (object-name width height position full-mode) this
    (format "%s: [top: %d, left: %d, width: %d, height: %d, full: %S]"
	    (or (slot-value this 'object-name)
		(cl-call-next-method))
	    (car position) (cdr position) width height full-mode)))



(defun cframe-display-id ()
  "Create a key for a display."
  (cons (display-pixel-height)
	(display-pixel-width)))

(defclass cframe-display (config-manager)
  ((id :initarg :id
       :initform (cframe-display-id)
       :type cons
       :documentation "Identifies this display."))
  :method-invocation-order :c3
  :documentation "Represents a monitor display.")

(cl-defmethod initialize-instance ((this cframe-display) &optional slots)
  "Initialize THIS instance using SLOTS as initial values."
  (setq slots (plist-put slots :pslots
			 (append (plist-get slots :pslots) '(id)))
	slots (plist-put slots :cycle-method 'next)
	slots (plist-put slots :list-header-fields
			 '("C" "Name" "Dimensions")))
  (cl-call-next-method this slots))

(cl-defmethod config-manager-entry-default-name ((this cframe-display))
  "Return the default name for THIS configuration display."
  (with-slots (id) this
    (format "Display (%d X %d)" (car id) (cdr id))))

(cl-defmethod config-manager-new-entry ((this cframe-display) &optional _)
  "Return a new configuration `cframe-setting' instance for THIS display."
  (ignore this)
  (cframe-setting))

(cl-defmethod eieio-object-name-string ((this cframe-display))
  "Return a string as a representation of the in memory instance of THIS."
  (with-slots (id entries) this
    (format "%s [%s]: %d entries"
	    (cl-call-next-method this) id (length entries))))

(cl-defmethod config-manager--update-entries ((this cframe-display) _)
  "Save THIS configuration frame using `cframe-save'."
  (ignore this)
  (cframe-save))

(cl-defmethod config-manager-list-entries-buffer ((this cframe-display)
						  &optional _)
  "Create a listing of configuration frame entries for THIS display.

See `config-manage-mode' super class for more information."
  (->> (config-manager-name this)
       capitalize
       (format "*%s Entries*")
       (cl-call-next-method this)))


(defclass cframe-manager (config-persistable)
  ((displays :initarg :displays
	     :initform nil
	     :type list
	     :documentation "Displays that have settings."))
  :method-invocation-order :c3
  :documentation "Manages displays.")

(cl-defmethod initialize-instance ((this cframe-manager) &optional slots)
  "Initialize THIS instance using SLOTS as initial values."
  (setq slots (plist-put slots :pslots
			 (append (plist-get slots :pslots) '(displays))))
  (cl-call-next-method this slots))

(cl-defmethod cframe-manager-display ((this cframe-manager)
				      &optional no-create-p id)
  "Get display with index ID from THIS manager.
If the dipslay doesn't exist create a new display if NO-CREATE-P is non-nil."
  (with-slots (displays) this
    (let* ((find-id (or id (cframe-display-id)))
	   (display (->> displays
			 (cl-remove-if #'(lambda (display)
					   (with-slots (id) display
					     (not (equal find-id id)))))
			 car)))
      (when (and (null display) (not no-create-p))
	(setq display (cframe-display :object-name "frame")
	      displays (append displays (list display))))
      display)))

(cl-defmethod cframe-manager-advance-display ((this cframe-manager)
					      &optional criteria)
  "Iterate the settings for THIS current display and restore it.

See `config-manager-entry' for the CRITERIA parameter."
  (let ((criteria (or criteria 'cycle)))
    (-> (cframe-manager-display this)
	(config-manager-activate criteria))))

(cl-defmethod cframe-manager-reset ((this cframe-manager))
  "Reset the configuration of the current display for THIS manager."
  (with-slots (displays) this
    (dolist (display displays)
      (config-manager-list-clear display))))



;; funcs
(defgroup cframe nil
  "Customize a frame and fast switch size and positions."
  :group 'cframe
  :prefix "cframe-")

(defcustom cframe-persistency-file-name
  (expand-file-name "cframe" user-emacs-directory)
  "File containing the Flex compile configuration data."
  :type 'file
  :group 'cframe
  :set (lambda (sym val)
	 (set-default sym val)
	 (if (and (boundp 'cframe-manager-singleton)
		  cframe-manager-singleton)
	     (oset cframe-manager-singleton :file val))))

(defvar cframe-manager-singleton nil
  "The singleton manager instance.")

(defun cframe-manager-singleton ()
  "Return the configuration manager singleton."
  (or cframe-manager-singleton (cframe-restore)))

;;;###autoload
(defun cframe-current-setting (&optional include-display-p)
  "Get the current frame setting.

If INCLUDE-DISPLAY-P is non-nil, or provided interactively with
\\[universal-argument]]."
  (interactive "P")
  (let* ((display (-> (cframe-manager-singleton)
		      cframe-manager-display))
	 (setting (config-manager-current-instance display)))
    (when (called-interactively-p 'interactive)
      (let ((fmt-fn #'eieio-object-name-string))
	(->> (if include-display-p
		 (let ((props (mapconcat
			       #'(lambda (arg)
				   (format "%s=%s" (car arg) (cdr arg)))
			       (cframe-setting-frame-attributes setting)
			       ", ")))
		   (concat (funcall fmt-fn display) ", " props)))
	     (concat (funcall fmt-fn setting))
	     message)))
    setting))

;;;###autoload
(defun cframe-add-or-advance-setting (addp)
  "Either add with ADDP the current frame setting advance the next."
  (interactive (list current-prefix-arg))
  (if addp
      (progn
	(-> (cframe-manager-singleton)
	    cframe-manager-display
	    config-manager-add-entry)
	(message "Added setting and saved"))
    (-> (cframe-manager-singleton)
	cframe-manager-advance-display))
  (cframe-current-setting))

;;;###autoload
(defun cframe-save ()
  "Save the state of all custom frame settings."
  (interactive)
  (-> (cframe-manager-singleton)
      config-persistable-save))

;;;###autoload
(defun cframe-restore ()
  "Restore the state of all custom frame settings."
  (interactive)
  (let* ((file (expand-file-name "cframe" user-emacs-directory))
	 (mng (if (file-exists-p file)
		  (with-temp-buffer
		    (insert-file-contents file)
		    (->> (read (buffer-string))
			 config-persistent-unpersist))
		(cframe-reset))))
    (oset mng :file file)
    (setq cframe-manager-singleton mng)
    (cframe-manager-advance-display mng 'first)
    mng))

;;;###autoload
(defun cframe-reset (&optional hardp)
  "Reset the state of the custom frame manager.

HARDP means to recreate the manager instance, all data is reset
\\(across all displays).  This is very destructive.

This blows away all frame settings configuration in memory.  To
wipe the state on the storage call `cframe-restore' or
`cframe-add-or-advance-setting' after calling this."
  (interactive "P")
  (when (or hardp (not cframe-manager-singleton))
    (setq cframe-manager-singleton
	  (cframe-manager :file cframe-persistency-file-name)))
  (cframe-manager-reset cframe-manager-singleton)
  cframe-manager-singleton)

;;;###autoload
(defun cframe-list ()
  "List settings for current display."
  (interactive)
  (let ((display (cframe-manager-display (cframe-manager-singleton) t)))
    (if display
	(config-manager-list-entries-buffer display)
      (error "No display entries--use `cframe-add-or-advance-setting'"))))



;; utility

;;;###autoload
(defun cframe-toggle-frame-full-or-maximized (maximized-p)
  "Either change to full screen mode or maximize the window when MAXIMIZED-P."
  (interactive "P")
  (funcall (if maximized-p
	       #'toggle-frame-maximized
	     #'toggle-frame-fullscreen)))


(provide 'cframe)

;;; cframe.el ends here
