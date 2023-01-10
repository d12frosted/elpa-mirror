;;; pc-bufsw.el --- PC style quick buffer switcher

;; This is free and unencumbered software released into the public domain.
;;
;; Anyone is free to copy, modify, publish, use, compile, sell, or
;; distribute this software, either in source code form or as a compiled
;; binary, for any purpose, commercial or non-commercial, and by any
;; means.
;;
;; In jurisdictions that recognize copyright laws, the author or authors
;; of this software dedicate any and all copyright interest in the
;; software to the public domain. We make this dedication for the benefit
;; of the public at large and to the detriment of our heirs and
;; successors. We intend this dedication to be an overt act of
;; relinquishment in perpetuity of all present and future rights to this
;; software under copyright law.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
;; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
;; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.

;; Author: Igor Bukanov <igor@mir2.org>
;; Version: 3.2
;; Package-Version: 20201011.1918
;; Package-Commit: a7295e4813d636d5a20605d134acd42e4e4fe8fa
;; Keywords: buffer
;; URL: https://github.com/ibukanov/pc-bufsw

;;; Commentary:

;; This switches Emacs buffers according to
;; most-recently-used/least-recently-used order using `C-tab` and
;; `C-S-tab` keys.  It is similar to window or tab switchers that are
;; available in PC desktop environments or applications.

;;; ChangeLog:

;; 2018-12-21 (3.2 release)
;; pc-bufsw-other-windows option

;; 2018-12-20 (3.1 release)
;; Turn pc-bufsw into a minor mode for simpler keymap management.

;; 2015-09-18 (3.0 release)
;; Support for the customization.
;; Support for autoloading.
;; Using pc-bufsw- for public and pc-bufsw-- for private functions and
;; variables, not non-standard pc-bufsw:: prefix for function names.

;; 2007-06-27 (2.0 release)
;; Removal of window switching facility making pc-bufsw to switch only between
;; buffers. Emacs and window managers provides enough key bindings to switch
;; between windows and frames.

;; 2005-08-25
;; Introduction of pc-bufsw--keep-focus-window mode. This is not the
;; start of the feature creep as the old mode is kept for compatibility
;; as users may not appreciate the new behavior.

;; 2005-08-17 (1.3 release)
;; * Use buffer-display-time to construct buffer list in proper least
;;   recently used order to defeat bury-buffer abuse by various tools.
;; * When switching from initial window, restore the original buffer
;;   there.
;; * Fix frame switching using select-frame-set-input-focus. It does
;;   not resolve all the issue, but at least it works.

;;; Code:

;;;###autoload
(defun pc-bufsw-mru ()
  "Switch to the most recently used buffer."
  (interactive)
  (pc-bufsw--walk 1))

;;;###autoload
(defun pc-bufsw-lru ()
  "Switch to the least recently used buffer."
  (interactive)
  (pc-bufsw--walk -1))

;;;###autoload
(defun pc-bufsw-clear-default-keybindings ()
  "Deprecated. Customize `pc-bufsw-keys' instead."
  (message "pc-bufsw-clear-default-keybindings is deprecated. Customize pc-bufsw-keys instead.")
  (setcdr pc-bufsw-map nil))

;;;###autoload
(defun pc-bufsw-default-keybindings ()
  "Deprecated.  Use (`pc-bufsw' t) instead."
  (message "pc-bufsw-default-keybindings is deprecated. Use (`pc-bufsw' t) instead.")
  (pc-bufsw t))

;; Copy into the autoload file the minor mode definition and
;; pc-bufsw-update-keybindings literally so calling (p-bufsw t) does
;; not load the rest of the file until the user presses the keys. I
;; also copy defcustom definitions literally due to
;; https://stackoverflow.com/questions/32693757/emacs-package-customization-and-autoloads

;;;###autoload
(unless (fboundp 'pc-bufsw-update-keybindings)

  (defun pc-bufsw-update-keybindings ()
    "Enable keybindings according to `pc-bufsw-keys'."
    ;; Clear existing entries if any
    (setcdr pc-bufsw-map nil)
    (mapc (lambda (key) (define-key pc-bufsw-map key 'pc-bufsw-mru))
	  (car pc-bufsw-keys))
    (mapc (lambda (key) (define-key pc-bufsw-map key 'pc-bufsw-lru))
	  (cadr pc-bufsw-keys)))

  (defvar pc-bufsw-map
    (make-sparse-keymap)
    "pc-bufsw mode keymap.")

  (define-minor-mode pc-bufsw
    "A minor mode to switch Emacs buffers according to most recently used order.

    This is similar to window or tab switchers that are available in PC desktop
    environments or applications. By default it uses Ctrl-Tab and Ctrl-Shift-Tabs
    key to switch according to most-recently-used or least-recently-used order.
    To customize keybindings edit `pc-bufsw-keys'."

    :keymap 'pc-bufsw-map
    :global t
    :group 'pc-bufsw
    (when pc-bufsw
      (pc-bufsw-update-keybindings)))

  (defgroup pc-bufsw nil
    "Settings for PC style quick buffer switcher."
    :group 'convenience)

  (defcustom pc-bufsw-keys
    '(([C-tab] "\e[1;5I" "\e[1;5i") ([C-S-tab] [C-S-iso-lefttab] "\e[1;6I" "\e[1;6i"))
    "Two-element list with key sets to cycle from most to least recently
used buffers and in reverse.  The default sets contain <C-tab> and <C-S-tab> plus sequence
reported by some terminals when pressing those keys that Emacs does not recognize as such."
    :group 'pc-bufsw
    :type '(list (repeat
		  :tag "Cycle from most to least recently used buffers using any of"
		  key-sequence)
		 (repeat
		  :tag "Cycle from least to most recently used buffers using any of"
		  key-sequence))
    :set (lambda (symbol value)
	   (set-default symbol value)
	   (pc-bufsw-update-keybindings)))

  (defcustom pc-bufsw-keys-enable nil
    "Deprecated.  Instead customize `pc-bufsw' to turn it on or
     call (pc-bufsw t) in Emacs ini file."
    :group 'pc-bufsw
    :type 'boolean
    :set-after '(pc-bufsw-keys)
    :set (lambda (symbol value)
	   (set-default symbol value)
	   (when value
	     (message "pc-bufsw-keys-enable is deprecated. Customize pc-bufsw instead.")
	     (pc-bufsw value))))

  (defcustom pc-bufsw-quit-time 3
    "Quit buffer switching after the given time in seconds.  If
there is no input during this interval the last choosen buffer
becomes current."
    :group 'pc-bufsw
    :type 'number)

  (defcustom pc-bufsw-wrap-index t
    "Wrap to the other end of the buffer list when attempting to navigate past its edge."
    :group 'pc-bufsw
    :type 'boolean
    :version "3.1")

  (defcustom pc-bufsw-other-windows nil
    "Defines how to treat other windows and their buffers."
    :type '(radio
	    (const
	     :tag "All Buffers"
	     :doc "Use all buffers for switching including buffers from other windows."
	     nil)
	    (const
	     :tag "Skip"
	     :doc "Switch only to buffers not already shown in other windows."
	     :skip))
    :group 'pc-bufsw
    :version "3.2")

  (defcustom pc-bufsw-decorator-left "<"
    "Defines which character is used when decorating the selected buffer.

Formatting can be added using text properties, e.g.:
(setq pc-bufsw-decorator-left (propertize \"[\" \\='face \\='bold))"
    :type 'string)
  (defcustom pc-bufsw-decorator-right ">"
    "Defines which character is used when decorating the selected buffer.

Formatting can be added using text properties, e.g.:
(setq pc-bufsw-decorator-right (propertize \"]\" \\='face \\='bold))"
    :type 'string)

  (defcustom pc-bufsw-buffer-face nil
    "If non-nil, use this face for buffer names."
    :type '(choice (const nil)
                   face))
  (defcustom pc-bufsw-window-buffer-face nil
    "If non-nil, use this face for names of buffers previously displayed in the current window."
    :type '(choice (const nil)
                   face))
  (defcustom pc-bufsw-frame-buffer-face nil
    "If non-nil, use this face for names of buffers previously displayed in the current frame."
    :type '(choice (const nil)
                   face))
  (defcustom pc-bufsw-selected-buffer-face nil
    "If non-nil, use this face for selected buffer names."
    :type '(choice (const nil)
                   face))

  (defcustom pc-bufsw-prefer-current-window nil
    "Prefer buffers previously displayed in the current window when building buffer list."
    :type 'boolean)
  (defcustom pc-bufsw-prefer-current-frame nil
    "Prefer buffers previously displayed in the current frame when building buffer list."
    :type 'boolean)

  (pc-bufsw-update-keybindings)

  ;; Support older code using (setq pc-bufsw-keys-enable t) in ini files before
  ;; explicit require calls.
  (when pc-bufsw-keys-enable
    (pc-bufsw t)))

(defvar pc-bufsw--walk-vector nil
  "Vector of buffers to navigate during buffer switch.
Buffers are odered from most to least recently used.")

(defvar pc-bufsw--cur-index 0
  "Index of currently selected buffer in `pc-bufsw--walk-vector'.")

(defun pc-bufsw--walk (direction)
  ;; Main loop. It does 4 things. First, select new buffer and/or
  ;; windows according to user input. Second, it selects the newly
  ;; choosen buffer/windows/frame. Third, it draw in the echo area
  ;; line with buffer names. Forth, it waits for a timeout to
  ;; terminate the switching.
  (when (and (null pc-bufsw--walk-vector) (pc-bufsw--can-start))
    (setq pc-bufsw--cur-index 0)
    (setq pc-bufsw--walk-vector (pc-bufsw--get-walk-vector))
    (add-hook 'pre-command-hook 'pc-bufsw--switch-hook))
  (when pc-bufsw--walk-vector
    (let ((prev-index pc-bufsw--cur-index))
      (pc-bufsw--choose-next-index direction)
      (when (/= pc-bufsw--cur-index prev-index)
	(pc-bufsw--preview-buffer
	 (aref pc-bufsw--walk-vector pc-bufsw--cur-index)))
      (pc-bufsw--show-buffers-names)
      (when (sit-for pc-bufsw-quit-time)
	(pc-bufsw--finish)))))

(defun pc-bufsw--preview-buffer (buf)
  "Switch to buffer BUF, preserving window/frame buffer histories."
  (let ((old-prev-buffers (window-prev-buffers))
	(old-next-buffers (window-next-buffers)))
    (switch-to-buffer buf t)
    (set-window-prev-buffers (selected-window) old-prev-buffers)
    (set-window-next-buffers (selected-window) old-next-buffers)))

(defun pc-bufsw--can-start ()
  (not (window-minibuffer-p (selected-window))))

(defun pc-bufsw--switch-hook ()
  ;; Hook to access next input from user.
  (when (or (null pc-bufsw--walk-vector)
	    (not (or (eq 'pc-bufsw-lru this-command)
		     (eq 'pc-bufsw-mru this-command)
		     (eq 'handle-switch-frame this-command))))
    (pc-bufsw--finish)))

(defun pc-bufsw--get-walk-vector ()
  ;; Construct main buffer vector.
  (let (assembled
	(num 0)
	(buffers (append
		  (list (current-buffer))
		  (when pc-bufsw-prefer-current-window
		    (mapcar #'car (window-prev-buffers)))
		  (when pc-bufsw-prefer-current-frame
		    (frame-parameter (selected-frame) 'buffer-list))
		  (buffer-list))))
    (dolist (buf buffers)
      (when (and (< num 100) ; Limit results to avoid O(n^2)
		 (not (memq buf assembled))
		 (pc-bufsw--can-work-buffer buf)
		 (cond
		  ((eq pc-bufsw-other-windows :skip)
		   (not (get-buffer-window buf)))
		  (t)))
	(setq assembled (cons buf assembled)
	      num (1+ num))))
    (vconcat (nreverse assembled))))

(defun pc-bufsw--can-work-buffer (buffer)
  ;; Return nil if buffer is not suitable for switch.
  (let ((name (buffer-name buffer)))
    (and name (not (equal ?\  (aref name 0))))))

(defun pc-bufsw--show-buffers-names ()
  ;; Echo buffer list. Current buffer marked by <>.
  (let* ((width (frame-width))
	 (n (pc-bufsw--find-first-visible width))
	 (str (pc-bufsw--make-show-str n width)))
    (message "%s" str)))

(defun pc-bufsw--find-first-visible (width)
  (let ((first-visible 0)
	(i 1)
	(visible-length (pc-bufsw--show-name-len 0 t)))
    (while (<= i pc-bufsw--cur-index)
      (let ((cur-length (pc-bufsw--show-name-len i (= first-visible i))))
	(setq visible-length (+ visible-length cur-length))
	(when (> visible-length width)
	  (setq first-visible i)
	  (setq visible-length cur-length)))
      (setq i (1+ i)))
    first-visible))

(defun pc-bufsw--show-name-len (i at-left-edge)
  (+ (if at-left-edge 2 3)
     (length (buffer-name (aref pc-bufsw--walk-vector i)))))

(defun pc-bufsw--make-show-str (first-visible width)
  (let* ((i (1+ first-visible))
	 (count (length pc-bufsw--walk-vector))
	 (str (pc-bufsw--show-name first-visible t))
	 (visible-length (length str))
	 (continue-loop (not (= i count))))
    (while continue-loop
      (let* ((name (pc-bufsw--show-name i nil))
	     (name-len (length name)))
	(setq visible-length (+ visible-length name-len))
	(if (> visible-length width)
	    (setq continue-loop nil)
	  (setq str (concat str name))
	  (setq i (1+ i))
	  (when (= i count)
	    (setq continue-loop nil)))))
    str))

(defun pc-bufsw--show-name (i at-left-edge)
  (let* ((buf (aref pc-bufsw--walk-vector i))
	 (name (buffer-name buf))
	 (current (= i pc-bufsw--cur-index))
	 (face (cond
		((and pc-bufsw-selected-buffer-face current)
		 pc-bufsw-selected-buffer-face)
		((and pc-bufsw-window-buffer-face
		      (or (eq buf (aref pc-bufsw--walk-vector 0))
			  ;; window-prev-buffers et al should not
			  ;; change while pc-bufsw is active.
			  (memq buf (mapcar #'car (window-prev-buffers)))))
		 pc-bufsw-window-buffer-face)
		((and pc-bufsw-frame-buffer-face
		      (memq buf (frame-parameter (selected-frame) 'buffer-list)))
		 pc-bufsw-frame-buffer-face)
		(t pc-bufsw-buffer-face))))
    (concat
     (if at-left-edge "" " ")
     (if current pc-bufsw-decorator-left
       (make-string (length pc-bufsw-decorator-left) ?\ ))
     (if face (propertize name 'face face) name)
     (if current pc-bufsw-decorator-right
       (make-string (length pc-bufsw-decorator-right) ?\ ))
     )))

(defun pc-bufsw--choose-next-index (direction)
  (setq pc-bufsw--cur-index
	(if pc-bufsw-wrap-index
	    (mod (+ pc-bufsw--cur-index direction)
		 (length pc-bufsw--walk-vector))
	  (max 0 (min (1- (length pc-bufsw--walk-vector))
		      (+ pc-bufsw--cur-index direction))))))

(defun pc-bufsw--finish ()
  ;; Called on switch mode close.
  (pc-bufsw--restore-order (aref pc-bufsw--walk-vector pc-bufsw--cur-index))
  ;; Switch back to the original and target buffer,
  ;; ensuring they are in the buffer history in that order.
  (switch-to-buffer (aref pc-bufsw--walk-vector 0))
  (switch-to-buffer (aref pc-bufsw--walk-vector pc-bufsw--cur-index))
  (remove-hook 'pre-command-hook 'pc-bufsw--switch-hook)
  (setq pc-bufsw--walk-vector nil)
  (setq pc-bufsw--cur-index 0)
  (message nil))

(defun pc-bufsw--restore-order (chosen-buffer)
  "Ensure CHOSEN-BUFFER is at the front of the current frame's buffer list."
  (set-frame-parameter
   nil 'buffer-list
   (cons chosen-buffer
	 (delq chosen-buffer (frame-parameter nil 'buffer-list))))
  (set-frame-parameter
   nil 'buried-buffer-list
   (delq chosen-buffer (frame-parameter nil 'buried-buffer-list))))

(provide 'pc-bufsw)

;;; pc-bufsw.el ends here
