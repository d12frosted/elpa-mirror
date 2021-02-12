;;; exwm-float.el --- Convenient modes and bindings for floating EXWM frames -*- lexical-binding: t  -*-

;; Copyright (C) 2020 Mehmet Tekman <mtekman89@gmail.com>

;; Author: Mehmet Tekman
;; URL: https://gitlab.com/mtekman/exwm-float.el
;; Package-Version: 20210207.2035
;; Package-Commit: eb1b60b4a65e1ca5e323ef68a284ec6af72e637a
;; Keywords: outlines
;; Package-Requires: ((emacs "25.1") (xelb "0.18") (exwm "0.24") (popwin "1.0.2"))
;; Version: 0.4

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;;; Commentary:

;; This package adds a minor-mode and some convenience functions to
;; easily move picture-in-picture frames around the screen and to
;; toggle playing and pausing video windows.

;;; Code:
(require 'xcb)
(require 'exwm-core)
(require 'exwm-input)
(require 'exwm-floating)
(require 'exwm-workspace)
(require 'exwm-manage)
(require 'popwin)

(defgroup exwm-float nil
  "Customization group for picture-in-picture."
  :group 'exwm-floating)

(defcustom exwm-float-modify-amount
  '(:move-slow 20 :move-fast 100 :resize 50)
  "Incremental pixel amounts to MOVE-SLOW, MOVE-FAST or RESIZE.
These act on the floating frame during the minor mode."
  :type 'plist
  :group 'exwm-float)

(defcustom exwm-float-frame-defaults
  '((:title nil ;;"Picture-in-Picture"
            :geometry '(x 0.6 y 0.05 width 600 height 500)
            :decoration  '(floating-mode-line nil
                                              tiling-mode-line nil
                                              floating-header-line nil
                                              tiling-header-line nil
                                              char-mode nil)))
  "Default window geometries and decorations for the spawned floating window.
Completely overrides the `exwm-manage-configurations' custom
variable.

Each config will be applied to the matching floating window with
TITLE.  If TITLE is nil, then it matches all.  Note that
specifying nil for certain options is not the same as leaving
them out.  See `exwm-manage-configurations' for more
information."
  :type 'list ;; TODO: Specify the type format better, see the above variable for more info.
  :group 'exwm-float)

(defcustom exwm-float-border
  '(:stationary ("navy" . 1) :moving ("maroon" . 3))
  "Floating border and width when stationary and during move-mode."
  :type 'plist
  :group 'exwm-float)

(defcustom exwm-float-custom-modes
  '(;; Move window slow
    (:title nil :common-fn exwm-float-move-direction
            :keyargs ((\S-left . ('left))
                      (\S-right . ('right))
                      (\S-up .  ('up))
                      (\S-down . ('down))))
    ;; Move window fast
    (:title nil :common-fn exwm-float-move-direction
            :keyargs ((\S-\M-left . ('left t))
                      (\S-\M-right . ('right t))
                      (\S-\M-up . ('up t))
                      (\S-\M-down . ('down t))))
    ;; Resize window
    (:title nil :common-fn exwm-float-resize-delta
            :keyargs ((\M-left . ('dec nil))
                      (\M-right . ('inc nil))
                      (\M-up . (nil 'dec))
                      (\M-down . (nil 'inc))))
    ;; Common controls
    (:title nil :keyargs (;; (?s . (call-interactively #'exwm-float-position-save))
                          (?q . (exwm-float--inner-mode-exit))
                          (return . (exwm-float--inner-mode-exit))))
    ;; Video-specific controls
    (:title "Picture-in-Picture" :common-fn exwm-float--send-key
            :keyargs (left right up down ? ))
    (:title "Picture-in-Picture" :keyargs ((\S-? . (exwm-float-forcetoggle-video)))))
  "A keymap list, loaded when TITLE matches `exwm-title' for the float window.

If TITLE is nil, then the mode is enabled on all floating
windows.  The bindings are set by binding the car of each KEYARGS
to the COMMON-FN plus the cdr of each KEYARGS.

e.g.1 (:title \"Foo\" :common-fn #'fun1 :keyargs '((a 9)))
         becomes (([a] . (fun1 a))
                  ([9] . (fun1 9)))

e.g.2 (:title \"Bar\" :common-fn #'fun2 :keyargs '((a . (b 22))
                                                   (9 . (123 m))
                                                   (left . (1 1))))
         becomes (([a] . (fun2 b 22))
                  ([9] . (fun2 123 m))
                  ([left] . (fun2 1 1)))

e.g.3 (:title \"Baz\" :common-fn nil :keyargs '((a . (fun1 1 22))
                                                (b . (fun2 f g))))
         becomes (([a] . (fun1 1 22))
                  ([b] . (fun2 f g)))

Keys are either literal characters (e.g. ? for Space, ?f for 'f',
etc) or keysyms found in `xcb-keysyms.el'."
  :type 'list
  :group 'exwm-float)

(defcustom exwm-float-position-configs
  '((:name "NW" :key "1" :title nil :x 0 :y 0 :width 0.25 :height 0.25)
    (:name "NE" :key "2" :title nil :x -0.25 :y 0 :width 0.25 :height 0.25)
    (:name "SW" :key "3" :title nil :x 0 :y -0.25 :width 0.25 :height 0.25)
    (:name "SE" :key "4" :title nil :x -0.25 :y -0.25 :width 0.25 :height 0.25)
    (:name "Center" :key "5" :title nil :x 0.25 :y 0.25 :width 0.5 :height 0.5)
    (:name "Hide" :key "h" :title nil :x 0.5 :y -1 :width 1 :height 1))
  "Property list of window properties.

A `(:name N :key K :title T :x X :y Y :width W :height H))' list
elements, where K denotes the keyboard sequence used to place the
floating window matching TITLE to position X and Y and resizing
it to W and H.  All positions can be fractional (denoting
proportion of screen space) or integers (denoting absolute
pixels), and if negative are treated as offsets from the screen
boundary.  If TITLE is nil, then apply to the first floating
window.  The name N is ignored."
  :type 'plist
  :group 'exwm-float)

(defun exwm-float--frame-geometry ()
  "Get geometry of current frame."
  (with-slots (x y width height)
      (xcb:+request-unchecked+reply exwm--connection
          (make-instance
           'xcb:GetGeometry :drawable
           (frame-parameter exwm--floating-frame 'exwm-container)))
    (list :x x :y y :width width :height height)))

;; --- BEGIN: Position Saving Functions ---
;;
;; These are disabled for now due to the issues with refreshing the keymap
;;
;; (defvar exwm-float-position-file
;;   (concat (file-name-as-directory user-emacs-directory) "float_positions.el")
;;   "File to store floating video positions.")
;;
;; (defun exwm-float-position-save (hotkey)
;;   "Save the current floating window position to a HOTKEY."
;;   (interactive (list (read-key-sequence "Hotkey: ")))
;;   (let* ((geometry (exwm-float--do-floatfunc-and-restore
;;                   (lambda (cwin fwin)
;;                     (exwm-float--frame-geometry))))
;;          (posinfo (append (list :key hotkey :title exwm-title) geometry)))
;;     (message "Binding: %s" posinfo)
;;     (exwm-float--position-store posinfo)))
;;     ;;(exwm-float--refresh-minor-mode)))

;; (defun exwm-float--position-store (posinfo)
;;   "Store the following POSINFO into the
;; `exwm-float-position-configs' variable, and sync with the
;; `exwm-float-position-file'."
;;   (pushnew posinfo exwm-float-position-configs)
;;   (if exwm-float-position-configs
;;       (with-temp-buffer
;;         (insert "(")
;;         (dolist (elem exwm-float-position-configs)
;;           (let ((name (plist-get elem :name))
;;                 (key (plist-get elem :key)) (title (plist-get elem :title))
;;                 (x (plist-get elem :x)) (y (plist-get elem :y))
;;                 (w (plist-get elem :width)) (h (plist-get elem :height)))
;;             (if (eq 'string (type-of name)) (setq name (concat "\"" name "\"")))
;;             (if (eq 'string (type-of key)) (setq key (concat "\"" key "\"")))
;;             (if (eq 'string (type-of title)) (setq title (concat "\"" title "\"")))
;;             ;; Probably an easier way to ensure that values which have quotes are quoted, but eh.
;;             (insert (format "(:name %s :key %s :title %s :x %s :y %s :width %s :height %s)\n "
;;                             name key title x y w h))))
;;         (search-backward ")")
;;         (insert ")")
;;         (write-file exwm-float-position-file))))

;; (defun exwm-float--position-restore ()
;;   "Set the `exwm-float-position-configs' variable from the contents of the `exwm-float-position-file' and return it (to be fed directly into `exwm-float--position-expandbindings')."
;;   (if exwm-float-position-file
;;       (with-temp-buffer
;;         (unless (file-exists-p exwm-float-position-file)
;;           (with-temp-buffer
;;             (insert "")
;;             (write-file exwm-float-position-file)))
;;         (insert-file-contents exwm-float-position-file)
;;         (let ((tmpvar (read-from-string (let ((it (buffer-string))) (if (equal it "") "nil" it)))))
;;           (if (car tmpvar)
;;               (setq exwm-float-position-configs (car tmpvar))
;;             (user-error "Cannot parse"))))
;;     (user-error "`exwm-float-position-file' not set")))
;;
;; --- END: Position Saving Functions ---

(defun exwm-float--position-expandbindings (position-config map)
  "Expand the bindings from POSITION-CONFIG.

There are read from `exwm-float--position-restore' into the
keymap MAP, and check for conflicts."
  (dolist (binding position-config)
    (let* ((key (plist-get binding :key))
           (existing-binding (key-binding (kbd key)))
           (not-bound (or (not existing-binding)
                          (eq existing-binding 'self-insert-command))))
      (if not-bound
          (let* ((title (plist-get binding :title))
                 (x (plist-get binding :x)) (y (plist-get binding :y))
                 (w (plist-get binding :width)) (h (plist-get binding :height))
                 (func `(lambda () (interactive)
                          (exwm-float-move ,x ,y ,w ,h ,title)
                          (message "%s" binding))))
            (define-key map key func))
        (user-error "Key: %s is already set" key)))))

(defun exwm-float--convert2keymap (entry &optional map)
  "Convert ENTRY in `exwm-float-custom-modes' into keymap MAP."
  (let ((title (plist-get entry :title))
        (commonfn (plist-get entry :common-fn))
        (keyargs (plist-get entry :keyargs))
        (map (or map (make-sparse-keymap))))
    (dolist (it keyargs)
      (let* ((key (if (eq (type-of it) 'cons) (car it) it))
             (args (if (eq (type-of it) 'cons) (cdr it)))
             (func (if commonfn
                       (if (not args) ;; only key
                           `(,commonfn ',key)
                         `(,commonfn ,@args))
                     ;; no initial function
                     (if (not args)
                         `(',key)
                       `(,@args))))
             ;; TODO: Find a cleaner way to write the above
             (titlefunc `(lambda () (interactive)
                           (if (or (not ,title) ;; no title, or a direct match
                                   (string= (with-current-buffer
                                                (exwm-float--get-floating-buffer)
                                              exwm-title)
                                            ,title))
                               ,func)))
             (press (cond ((eq key 'SPC) `[? ])
                          (t `[,key]))))
        (define-key map press titlefunc)))
    map))

;; C-M-x to redefine this
;;(unintern 'exwm-float-innermode)
(define-minor-mode exwm-float-innermode
  "The minor mode for manipulating the exwm floating frame.
Works only when called from non-floating frame, and it should therefore only
be called from the `exwm-float-mode' function, which ensures this.

This mode should never be called directly, or at least never on a floating
window buffer."
  :init-value nil
  :lighter " FloatMode"
  :keymap (let ((map (make-sparse-keymap)))
            ;; Load user-mode bindings
            (dolist (entry exwm-float-custom-modes)
              (exwm-float--convert2keymap entry map))
            ;; Load user-position bindings
            (exwm-float--position-expandbindings
             exwm-float-position-configs map)
            ;; (exwm-float--position-restore) map)
            map)
  ;; init
  (let ((colwid (plist-get exwm-float-border
                           (if exwm-float-innermode :moving :stationary))))
    (customize-set-variable 'exwm-floating-border-color (car colwid))
    (customize-set-variable 'exwm-floating-border-width (cdr colwid))))

(defun exwm-float--refresh-minor-mode ()
  "Refresh the minor mode for `exwm-float-position-configs' to take effect."
  ;;(exwm-float-mode -1)
  ;;(exwm-float-mode 1)
  (exwm-float--inner-mode-exit)
  (exwm-float-mode))


(defun exwm-float--send-key (keyseq)
  "Send KEYSEQ to floating window."
  (exwm-float--do-floatfunc-and-restore
   (lambda (c f) (ignore c f)(exwm-input--fake-key keyseq))))

(defun exwm-float--inner-mode-exit ()
  "Functions to run on move-mode exit.  Hooked to `exwm-floating-exit-hook'."
  (remove-hook 'quit-window-hook #'exwm-float--inner-mode-exit)
  (remove-hook 'next-error-hook #'exwm-float--inner-mode-exit)
  (when (get-buffer "EXWM FloatMode")
    (exwm-float-innermode -1)
    (kill-buffer "EXWM FloatMode")))

(defvar exwm-float--prebuffer nil
  "Window before minor-mode was called, to be restored on exit.")

;;;###autoload
(defun exwm-float-mode (&optional junk)
  "Parent caller for `function `exwm-float-innermode'.
Selects the floating window and sets the minor mode to STATE, 1
for on, anything else for off.  Event JUNK is discarded."
  (interactive)
  (ignore junk)
  (when (exwm-float--get-floating-frame)
    (select-frame exwm-workspace--current) ;; grab workspace, not floating win
    (let* ((floater (get-buffer-create "EXWM FloatMode"))
           (newwin (popwin:popup-buffer floater
                                        :height 2 :position 'bottom
                                        :dedicated t :stick t :tail t)))
      (ignore newwin)
      (with-current-buffer "EXWM FloatMode"
        (add-hook 'quit-window-hook #'exwm-float--inner-mode-exit)
        (add-hook 'next-error-hook #'exwm-float--inner-mode-exit)
        (setq-local buffer-read-only t)
        (exwm-float-innermode 1)))))

(defvar exwm-float--float-buffer nil
  "Buffer currently showed in the floating frame.")

(defun exwm-float--get-floating-buffer ()
  "Get the floating frame buffer.
If not found or currently active, search for it and update it."
  (if (and (buffer-live-p exwm-float--float-buffer)
           (with-current-buffer exwm-float--float-buffer
             exwm--floating-frame))
      exwm-float--float-buffer
    ;; Attempt to find new buffer
    (dolist (buff (buffer-list)
                  (if (buffer-live-p exwm-float--float-buffer)
                      exwm-float--float-buffer))
      (if (with-current-buffer buff exwm--floating-frame)
          (setq exwm-float--float-buffer buff)))))

(defun exwm-float--get-floating-window ()
  "Get the window of the floating buffer."
  (let ((it (exwm-float--get-floating-buffer)))
    (if it (get-buffer-window it t))))

(defun exwm-float--get-floating-frame ()
  "Get the frame of the floating buffer."
  (let ((it (exwm-float--get-floating-window)))
    (if it (window-frame it))))

(defun exwm-float--do-floatfunc-and-restore (func)
  "Select the floating window, perform FUNC and then restore the current window.
If the floating window is already selected, then just run FUNC."
  (let ((curr-win (get-buffer-window (current-buffer) t))
        (float-win (exwm-float--get-floating-window)))
    (unless float-win
      ;; Disable mode-mode if it's enabled
      (if exwm-float-innermode (exwm-float--inner-mode-exit))
      (user-error "No floating window available"))
    (if (eq curr-win float-win)
        (funcall func curr-win float-win)
      (select-window float-win)
      (let ((res (funcall func curr-win float-win)))
        (select-window curr-win)
        res)))) ;; return result of func

;;;###autoload
(defun exwm-float-setup ()
  "Main initialisation function.

Setup the floating window properties and associate it with the
floating window.  Call this function upon loading the package."
  (interactive)
  (dolist (config exwm-float-frame-defaults)
    (let* ((title (plist-get config :title))
           (geom (plist-get config :geometry))
           (decor (plist-get config :decoration))
           (newentry `((equal exwm-title ,title) ,@geom ,@decor)))
      (add-to-list 'exwm-manage-configurations newentry)))
  ;; onsetup, disable the tab-bar in this frame
  (add-hook 'exwm-floating-setup-hook
            (lambda () (interactive)
              (set-frame-parameter (exwm-float--get-floating-frame)
                                   'tab-bar-lines 0)))
  ;; onexit, close the minor-mode
  (add-hook 'exwm-floating-exit-hook #'exwm-float--inner-mode-exit))

(defun exwm-float--mouse-click (&optional pos button-num window-id)
  "Perform a mouse click at position POS.

POS can be an (x . y) cons pair, nil to click at the current
location, or 'center to click in the center of the window.  By
default BUTTON-NUM is `1' (i.e. main click) and the WINDOW-ID
is the currently selected window."
  (let* ((button-index (intern (format "xcb:ButtonIndex:%d" (or button-num 1))))
         (button-mask (intern (format "xcb:ButtonMask:%d" (or button-num 1))))
         (window-id (or window-id (exwm--buffer->id
                                   (window-buffer (selected-window)))
                        (user-error "No window selected")))
         (xy-pos (cond ((eq pos 'center) (cons (floor (/ (window-pixel-width) 2))
                                               (floor (/ (window-pixel-height) 2))))
                       ((not pos) (mouse-absolute-pixel-position))
                       (t pos))) ;; assume X . Y
         (button-actions `((xcb:ButtonPress . ,button-mask)
                           (xcb:ButtonRelease . 0))))
    (dolist (b-action button-actions)
      (xcb:+request exwm--connection
          (make-instance 'xcb:SendEvent
                         :propagate 0
                         :destination window-id
                         :event-mask xcb:EventMask:NoEvent
                         :event (xcb:marshal
                                 (make-instance (car b-action)
                                                :detail button-index
                                                :time xcb:Time:CurrentTime
                                                :root exwm--root
                                                :event window-id
                                                :child 0
                                                :root-x (car xy-pos)
                                                :root-y (cdr xy-pos)
                                                :event-x (car xy-pos)
                                                :event-y (cdr xy-pos)
                                                :state (cdr b-action)
                                                :same-screen 0)
                                 exwm--connection))))
    (xcb:flush exwm--connection)
    xy-pos))

(defun exwm-float--get-nonfloating-window ()
  "Get the first window in a non-floating buffer."
  (car (window-list exwm-workspace--current)))

;; (defvar exwm-float--video-toggle nil
;;   "The video play/pause state.")

(defun exwm-float-forcetoggle-video ()
  "Toggle the play/pause state of the video.
It assumes the first tabbed position would yield the play/pause button."
  (interactive)
  (exwm-float--do-floatfunc-and-restore
   (lambda (curr-win float-win)
     (ignore curr-win float-win)
     ;; -- The below commented section does not work reliably
     ;; (setq exwm-float--video-toggle (not exwm-float--video-toggle))
     ;; (exwm-input--fake-key
     ;;  (if exwm-float--video-toggle 'XF86AudioPause 'XF86AudioPlay))
     (exwm-input--fake-key 'escape)
     (exwm-float--mouse-click 'center 2) ;; middle click
     (exwm-input--fake-key 'tab)
     (exwm-input--fake-key 'return)
     (exwm-input--fake-key 'S-tab)))) ;; reset button position

(defun exwm-float-move-direction (direction &optional amount)
  "Move floating frame by AMOUNT in DIRECTION symbol: left, right, up, down.

If AMOUNT is nil then use the :move-slow amount, if t then use
the :move-fast amount, otherwise assume a pixel increment."
  (interactive (list (read-key "Direction ")))
  (let ((amount (cond ((not amount) (plist-get exwm-float-modify-amount :move-slow))
                      ((booleanp amount) (plist-get exwm-float-modify-amount :move-fast))
                      (t amount))))
    (exwm-float--do-floatfunc-and-restore
     (lambda (a b)
       (ignore a b)
       (cond ((eq direction 'left) (exwm-floating-move (- amount) 0))
             ((eq direction 'right) (exwm-floating-move amount 0))
             ((eq direction 'up) (exwm-floating-move 0 (- amount)))
             ((eq direction 'down) (exwm-floating-move 0 amount))
             (t (user-error "No such direction")))
       (with-slots (x y width height)
           (xcb:+request-unchecked+reply
               exwm--connection (make-instance
                                 'xcb:GetGeometry
                                 :drawable (frame-parameter exwm--floating-frame
                                                            'exwm-container)))
         (message "%s" (list :x x :y y :width: width :height height)))))))

(defun exwm-float--tolength (val dimension)
  "Scale a VAL to DIMENSION where appropriate.

If VAL is positive integer or nil return it, if a positive float
scale it by DIMENSION.  If VAL is a negative integer then
subtract it from DIMENSION.  If VAL is a negative float, then
scale it by DIMENSION and subtract from DIMENSION.

Used exclusively by `exwm-float-move'."
  (cond ((not val) val)
        ((integerp val) (if (>= val 0) val
                          (+ dimension val)))
        (t (floor (if (>= val 0) (* val dimension)
                    (+ dimension (* val dimension)))))))

(defun exwm-float-move (x y width height &optional title)
  "Move and resize floating window.

Move to position X and Y and size WIDTH and HEIGHT, optionally
only if the window TITLE.  If any of the required arguments are
fractional, then it scales itself to the size of the screen as
determined by `(x-display-pixel-height/width)'."
  (interactive "nx: \nny: \nnwidth: \nnheight: ")
  (exwm-float--do-floatfunc-and-restore
   (lambda (a b)
     (ignore a b)
     (let ((floating-container (frame-parameter exwm--floating-frame
                                                'exwm-container)))
       ;; if no title → continue
       ;; if title and match → continue
       (if (not (or (not title) (string= title exwm-title)))
           (user-error "'%s' not a set config")
         (let* ((pwt (x-display-pixel-width))
                (pht (x-display-pixel-height))
                (x (exwm-float--tolength x pwt))
                (y (exwm-float--tolength y pht))
                (width (exwm-float--tolength width pwt))
                (height (exwm-float--tolength height pht)))
           (exwm--set-geometry floating-container x y width height)
           (exwm--set-geometry exwm--id x y width height)
           (xcb:flush exwm--connection)))))))

(defun exwm-float-resize-delta (&optional deltax deltay)
  "Resize the floating window by DELTAX pixels right and DELTAY pixels down.

Both DELTAX and DELTAY default to 0 if nil.  Both values can also
take the value 'inc or 'dec which reference the :resize keyword
amount from `exwm-float-modify-amount'.  This command
should be bound locally."
  (exwm-float--do-floatfunc-and-restore
   (lambda (cwin fwin)
     (ignore cwin fwin)
     (exwm--log "DeltaX: %s, DeltaY: %s" deltax deltay)
     (unless (and (derived-mode-p 'exwm-mode) exwm--floating-frame)
       (user-error "[EXWM] `exwm-floating-move' is only for floating X windows"))
     (setq deltax (cond ((eq deltax 'inc) (plist-get exwm-float-modify-amount :resize))
                        ((eq deltax 'dec) (- (plist-get exwm-float-modify-amount :resize)))
                        ((not deltax) 0)
                        (t deltax)))
     (setq deltay (cond ((eq deltay 'inc) (plist-get exwm-float-modify-amount :resize))
                        ((eq deltay 'dec) (- (plist-get exwm-float-modify-amount :resize)))
                        ((not deltay) 0)
                        (t deltay)))
     (unless (and (= 0 deltax) (= 0 deltay))
       (let* ((floating-container (frame-parameter exwm--floating-frame
                                                   'exwm-container))
              (geometry (xcb:+request-unchecked+reply exwm--connection
                            (make-instance 'xcb:GetGeometry
                                           :drawable floating-container)))
              (_edges (window-inside-absolute-pixel-edges)))
         (with-slots (x y width height) geometry
           (let ((width-new (+ width deltax))
                 (height-new (+ height deltay)))
             (exwm--set-geometry floating-container nil nil width-new height-new)
             (exwm--set-geometry exwm--id nil nil width-new height-new)
             (xcb:flush exwm--connection)
             (message "%s" (list :x x :y y :width: width-new :height height-new)))))))))

(defun exwm-float-resize (width height)
  "Resize the floating window to WIDTH pixels and to HEIGHT pixels."
  (interactive "nWidth: \nnHeight: ")
  (exwm--log "width: %s, height: %s" width height)
  (unless (and (derived-mode-p 'exwm-mode) exwm--floating-frame)
    (user-error "[EXWM] `exwm-floating-move' is only for floating X windows"))
  (unless width (setq width 1))
  (unless height (setq height 1))
  (unless (and (= 0 width) (= 0 height))
    (let ((floating-container (frame-parameter exwm--floating-frame
                                               'exwm-container)))
      (exwm--set-geometry floating-container nil nil width height)
      (exwm--set-geometry exwm--id nil nil width height)
      (xcb:flush exwm--connection))))

(defun exwm-float-pause-media-windows (&optional matchstr num)
  "Pause all media windows matching regex MATCHSTR, and limit to the first NUM.

If MATCHSTR is nil, default to `.*[Ww]atch.*'.  If NUM is nil,
limit to none."
  (interactive)
  (let* ((matchstr (or matchstr (rx (seq (* any)
                                         (or "YouTube" (any ?W ?w) "atch")
                                         (* any)))))
         (blist (buffer-list))
         (nblist (length blist))
         (num (or num nblist)) ;; if nil consider all entries
         (ind -1)
         (toggled-windows ""))
    ;;(walk-windows (lambda (win)((
    (while (and (< (setq ind (1+ ind)) nblist) (> num 0))
      (let* ((buff (nth ind blist))
             (wid (exwm--buffer->id buff)))
        (when wid
          (with-current-buffer buff
            (and exwm-title
                 (when (string-match matchstr exwm-title)
                   (setq toggled-windows (concat toggled-windows
                                                 (format "'%s %s "
                                                         exwm-title
                                                         (exwm-float--mouse-click 'center 1 wid))))
                   (setq num (1- num))))))))
    (exwm-float-forcetoggle-video)
    (message "Toggled: %s" toggled-windows)))

(provide 'exwm-float)
;;; exwm-float.el ends here
