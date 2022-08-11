;;; workroom.el --- Named rooms for work without irrelevant distracting buffers  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Akib Azmain Turja.

;; Author: Akib Azmain Turja <akib@disroot.org>
;; Version: 1.0
;; Package-Requires: ((emacs "25.1"))
;; Keywords: tools, convenience
;; URL: https://codeberg.org/akib/emacs-workroom

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; Workroom provides named "workrooms" (or workspaces), somewhat similar to
;; multiple desktops in GNOME.

;; Each workroom has own set of buffers, allowing you to work on multiple
;; projects without getting lost in all buffers.

;; Each workroom also has its own set of views.  Views are just named
;; window configurations.  They allow you to switch to another window
;; configuration without losing your well-planned current window setup.

;; You can also bookmark a workroom or all your workrooms to restore them
;; at a later time, possibly in another Emacs session.

;; There is always a workroom named "master", which contains all live
;; buffers.  Removing any buffer from this workroom kills that buffer.  You
;; can't kill, rename or bookmark this workroom, but you can customize the
;; variable `workroom-default-room-name' to change its name.

;; All the useful commands can be called with following key sequences:

;;   Key        Command
;;   --------------------------------------
;;   C-x x s    `workroom-switch'
;;   C-x x d    `workroom-kill-view'
;;   C-x x D    `workroom-kill'
;;   C-x x r    `workroom-rename-view'
;;   C-x x R    `workroom-rename'
;;   C-x x c    `workroom-clone-view'
;;   C-x x C    `workroom-clone'
;;   C-x x m    `workroom-bookmark'
;;   C-x x M    `workroom-bookmark-all'
;;   C-x x b    `workroom-switch-to-buffer'
;;   C-x x a    `workroom-add-buffer'
;;   C-x x k    `workroom-remove-buffer'
;;   C-x x K    `workroom-kill-buffer'

;; Here the prefix key sequence is "C-x x", but you can customize
;; `workroom-command-map-prefix' to change it.

;; Adding and removing buffers to/from workrooms can become a burden.  You
;; can automate this process by setting `buffers' slot of `workroom' to a
;; function without arguments returning a list of live buffers.  That list
;; of buffer will be used as the list of buffers of that workroom.  The
;; default workroom is an example of this type of workroom, which uses
;; `buffer-list' for the list of buffers.

;;; Code:

(require 'cl-lib)
(require 'bookmark)

(defgroup workroom nil
  "Named rooms for work without irrelevant distracting buffers."
  :group 'convenience
  :prefix "workroom-"
  :link '(url-link "https://codeberg.org/akib/emacs-workroom"))

(defcustom workroom-command-map-prefix (kbd "C-x x")
  "Prefix key of Workroom commands.

Workroom-Mode must be reenabled for changes to take effect."
  :type 'key-sequence)

(defcustom workroom-default-room-name "master"
  "Name of the default workroom.

This workroom contains all live buffers of the current Emacs session.

Workroom-Mode must be reenabled for changes to take effect."
  :type 'string)

(defcustom workroom-default-view-name "main"
  "Name of the default view."
  :type 'string)

(defcustom workroom-buffer-handler-alist
  '((bookmark :encoder workroom--encode-buffer-bookmark
              :decoder workroom--decode-buffer-bookmark))
  "Alist of functions to encoding/decoding buffer to/from writable object.

Each element of the list is of the form (IDENTIFIER . (:encoder ENCODER
:decoder DECODER)), where ENCODE is a function to encode buffer to writable
object and DECODER is a function to decode a writable object returned by
ENCODER and create the corresponding buffer.  ENCODER is called with a
single argument BUFFER, where BUFFER is the buffer to encode.  It should
return nil if it can't encode BUFFER.  DECODER is called with a single
argument OBJECT, where OBJECT is the object to decode.  It should not
modify window configuration.  IDENTIFIER is used to get the appropiate
decoder function for a object.

Each element of the list tried to encode a buffer.  When no encoder
function can encode the buffer, the buffer is not saved.

NOTE: If you change IDENTIFIER, all buffers encoded with the previous value
can't restored."
  :type '(alist
          :key-type (symbol :tag "Identifier")
          :value-type (list (const :encoder)
                            (function :tag "Encoder function")
                            (const :decoder)
                            (function :tag "Decoder function"))))

(defcustom workroom-mode-lighter
  '(" WR["
    (:eval (propertize (workroom-name (workroom-current-room)) 'face
                       (if (member (current-buffer)
                                   (workroom-buffer-list
                                    (workroom-current-room)))
                           'compilation-info
                         'warning)))
    "]["
    (:eval (propertize (workroom-view-name (workroom-current-view)) 'face
                       (if (member (current-buffer)
                                   (workroom-buffer-list
                                    (workroom-current-room)))
                           'compilation-info
                         'warning)))
    "]")
  "Format of Workroom mode lighter.

The value is a mode line terminal like `mode-line-format'."
  :type 'sexp)

(defvar workroom-switch-hook nil
  "Normal hook run after switching room or view.")

(defvar workroom-kill-room-hook nil
  "Normal hook run after killing a room.")

(defvar workroom-kill-view-hook nil
  "Normal hook run after killing a view.")

(defvar workroom-rename-room-hook nil
  "Normal hook run after renaming a room.")

(defvar workroom-rename-view-hook nil
  "Normal hook run after renaming a view.")

(defvar workroom-buffer-list-change-hook nil
  "Normal hook run after changing the buffer list of a workroom.")

(cl-defstruct workroom
  "Structure for workroom."
  (name nil
        :documentation "Name of the workroom."
        :type string)
  (views nil
         :documentation "Views of the workroom."
         :type list)
  (buffers nil
           :documentation "Buffers of the workroom.")
  (default-p nil
    :documentation "Whether the workroom is the default one.")
  (previous-view-list nil
                      :documentation "List of previously selected views.")
  (view-history nil
                :documentation "`completing-read' history of view names."))

(cl-defstruct workroom-view
  "Structure for view of workroom."
  (name nil
        :documentation "Name of the view."
        :type string)
  (window-config nil
                 :documentation "Window configuration of the view."))

(defalias 'workroomp #'workroom-p)

(defvar workroom--default-view-of-default-room "main"
  "Name of default view of default workroom.")

(defvar workroom--rooms nil
  "List of currently live workrooms.")

(defvar workroom--room-history nil
  "`completing-read' history list of workroom names.")

(defvar workroom--view-history nil
  "`completing-read' history list of workroom view names.")

(defvar workroom-mode)

(defvar workroom-mode-map (make-sparse-keymap)
  "Keymap for Workroom-Mode.")

(defvar workroom-command-map
  (let ((keymap (make-sparse-keymap)))
    ;; NOTE:  Be sure to update commentary and README when you modify this.
    (define-key keymap "s" #'workroom-switch)
    (define-key keymap "d" #'workroom-kill-view)
    (define-key keymap "D" #'workroom-kill)
    (define-key keymap "r" #'workroom-rename-view)
    (define-key keymap "R" #'workroom-rename)
    (define-key keymap "c" #'workroom-clone-view)
    (define-key keymap "C" #'workroom-clone)
    (define-key keymap "m" #'workroom-bookmark)
    (define-key keymap "M" #'workroom-bookmark-all)
    (define-key keymap "b" #'workroom-switch-to-buffer)
    (define-key keymap "a" #'workroom-add-buffer)
    (define-key keymap "k" #'workroom-remove-buffer)
    (define-key keymap "K" #'workroom-kill-buffer)
    keymap)
  "Keymap containing all useful commands of Workroom.")

(define-key workroom-mode-map workroom-command-map-prefix
  workroom-command-map)

(defun workroom-get (name)
  "Return the workroom named NAME.

If no such workroom exists, return nil."
  (catch 'found
    (dolist (room workroom--rooms nil)
      (when (equal name (workroom-name room))
        (throw 'found room)))))

(defun workroom-get-create (name)
  "Return the workroom named NAME.

If no such workroom exists, create a new one named NAME and return that."
  (let ((room (workroom-get name)))
    (unless room
      (setq room (make-workroom
                  :name name
                  :buffers (list (get-buffer-create "*scratch*"))))
      (push room workroom--rooms))
    room))

(defun workroom-get-default ()
  "Return the default workroom."
  (catch 'found
    (dolist (room workroom--rooms nil)
      (when (workroom-default-p room)
        (throw 'found room)))))

(defun workroom-view-get (room name)
  "Return the view of ROOM named NAME.

If no such view exists, return nil."
  (catch 'found
    (dolist (view (workroom-views room) nil)
      (when (equal name (workroom-view-name view))
        (throw 'found view)))))

(defun workroom-view-get-create (room name)
  "Return the view of ROOM named NAME.

If no such view exists, create a new one named NAME and return that."
  (let ((view (workroom-view-get room name)))
    (unless view
      (setq view (make-workroom-view :name name))
      (push view (workroom-views room)))
    view))

(defun workroom-buffer-list (room)
  "Return the buffer list of workroom ROOM."
  (let ((buffers (workroom-buffers room)))
    (if (functionp buffers)
        (funcall buffers)
      buffers)))

(defun workroom-current-room (&optional frame)
  "Return the current workroom of FRAME."
  (frame-parameter frame 'workroom-current-room))

(defun workroom-current-view (&optional frame)
  "Return the current view of FRAME."
  (frame-parameter frame 'workroom-current-view))

(defun workroom-previous-room-list (&optional frame)
  "Return the list of the previous workrooms of FRAME."
  (frame-parameter frame 'workroom-previous-room-list))

(defun workroom--read (prompt &optional def require-match predicate)
  "Read the name of a workroom and return it as a string.

Prompt with PROMPT, where PROMPT should be a string without trailing colon
and/or space.

Return DEF when input is empty, where DEF is either a string or nil.

REQUIRE-MATCH and PREDICATE is same as in `completing-read'."
  (completing-read (concat prompt
                           (when def
                             (format " (default %s)" def))
                           ": ")
                   (mapcar #'workroom-name workroom--rooms)
                   predicate require-match nil 'workroom--room-history
                   def))

(defun workroom--read-to-switch (prompt &optional def require-match
                                        predicate)
  "Read the name of a workroom other than current one and return it.

See `workroom--read' for PROMPT, DEF, REQUIRE-MATCH and PREDICATE."
  (workroom--read prompt def require-match
                  (lambda (cand)
                    (and (not (equal
                               (workroom-name (workroom-current-room))
                               (if (consp cand) (car cand) cand)))
                         (if predicate
                             (funcall predicate cand)
                           t)))))

(defun workroom--read-view (room prompt &optional def require-match
                                 predicate)
  "Read the name of a view of ROOM and return it as a string.

Prompt with PROMPT, where PROMPT should be a string without trailing colon
and/or space.

Return DEF when input is empty, where DEF is either a string or nil.

REQUIRE-MATCH and PREDICATE is same as in `completing-read'."
  (let ((workroom--view-history (workroom-view-history room)))
    (prog1
        (completing-read (concat prompt
                                 (when def
                                   (format " (default %s)" def))
                                 ": ")
                         (mapcar #'workroom-view-name
                                 (workroom-views room))
                         predicate require-match nil
                         'workroom--room-history def)
      (setf (workroom-view-history room) workroom--view-history))))

(defun workroom--read-view-to-switch (room prompt &optional def
                                           require-match predicate)
  "Read the name of a view of ROOM other than current one and return it.

See `workroom--read' for PROMPT, DEF, REQUIRE-MATCH and PREDICATE."
  (workroom--read-view room prompt def require-match
                       (if (eq room (workroom-current-room))
                           (lambda (cand)
                             (and (not (equal
                                        (workroom-view-name
                                         (workroom-current-view))
                                        (if (consp cand) (car cand) cand)))
                                  (if predicate
                                      (funcall predicate cand)
                                    t)))
                         predicate)))

(defun workroom--read-member-buffer (room prompt &optional def
                                          require-match predicate)
  "Read the name of a member buffer of ROOM.

ROOM should be a `workroom'.  Prompt with PROMPT, where PROMPT should be a
string.  DEF, REQUIRE-MATCH and PREDICATE is same as in `read-buffer'."
  (let ((read-buffer-function nil))
    (read-buffer prompt def require-match
                 (lambda (cand)
                   (and (member
                         (get-buffer (if (consp cand) (car cand) cand))
                         (workroom-buffer-list room))
                        (if predicate
                            (funcall predicate cand)
                          t))))))

(defun workroom--read-non-member-buffer (room prompt &optional def
                                              require-match predicate)
  "Read the name of a buffer which isn't a member of ROOM.

ROOM should be a `workroom'.  Prompt with PROMPT, where PROMPT should be a
string.  DEF, REQUIRE-MATCH and PREDICATE is same as in `read-buffer'."
  (let ((read-buffer-function nil))
    (read-buffer prompt def require-match
                 (lambda (cand)
                   (and (not (member
                              (get-buffer (if (consp cand)
                                              (car cand)
                                            cand))
                              (workroom-buffer-list room)))
                        (if predicate
                            (funcall predicate cand)
                          t))))))

(defun workroom-read-buffer-function (prompt &optional def
                                             require-match predicate)
  "Read buffer function restricted to buffers of the current workspace.

PROMPT, DEF, REQUIRE-MATCH and PREDICATE is same as in `read-buffer'."
  (workroom--read-member-buffer (workroom-current-room) prompt def
                                require-match predicate))

(defun workroom--save-window-config ()
  "Return a object describing the current window configuration."
  (window-state-get (frame-root-window)))

(defun workroom--load-window-config (state)
  "Load window configuration STATE."
  (if state
      (cl-labels ((sanitize
                   (entry)
                   (cond
                    ((or (not (consp entry))
                         (atom (cdr entry)))
                     entry)
                    ((eq (car entry) 'leaf)
                     (let ((writable nil))
                       (let ((buffer (car (alist-get 'buffer
                                                     (cdr entry)))))
                         (when (stringp buffer)
                           (setq writable t))
                         (unless (buffer-live-p (get-buffer buffer))
                           (let ((scratch (get-buffer-create "*scratch*")))
                             (with-current-buffer scratch
                               (setf (car (alist-get 'buffer (cdr entry)))
                                     (if writable "*scratch*" scratch))
                               (setf (alist-get 'point
                                                (cdr (alist-get
                                                      'buffer
                                                      (cdr entry))))
                                     (if writable
                                         (point-min)
                                       (copy-marker
                                        (point-min)
                                        window-point-insertion-type)))
                               (setf (alist-get 'start
                                                (cdr (alist-get
                                                      'buffer
                                                      (cdr entry))))
                                     (if writable
                                         (point-min)
                                       (copy-marker (point-min))))))))
                       (let ((prev (alist-get 'prev-buffers (cdr entry))))
                         (setf
                          (alist-get 'prev-buffers (cdr entry))
                          (mapcar
                           (lambda (entry)
                             (if (buffer-live-p (get-buffer (car entry)))
                                 entry
                               (let ((scratch (get-buffer-create
                                               "*scratch*")))
                                 (with-current-buffer scratch
                                   (if writable
                                       (list "*scratch*"
                                             (point-min)
                                             (point-min))
                                     (list
                                      scratch
                                      (copy-marker (point-min))
                                      (copy-marker
                                       (point-min)
                                       window-point-insertion-type)))))))
                           prev)))
                       (let ((next (alist-get 'next-buffers (cdr entry))))
                         (setf (alist-get 'next-buffers (cdr entry))
                               (mapcar
                                (lambda (buffer)
                                  (if (buffer-live-p (get-buffer buffer))
                                      buffer
                                    (let ((buffer (get-buffer-create
                                                   "*scratch*")))
                                      (if writable "*scratch*" buffer))))
                                next))))
                     entry)
                    (t
                     (mapcar #'sanitize entry)))))

        ;; Sanitize window state (remove references to non-existant
        ;; buffers) before loading it.
        (window-state-put (cons (car state) (sanitize (cdr state)))
                          (frame-root-window) 'safe))
    (delete-other-windows)
    (set-window-dedicated-p (selected-window) nil)
    (switch-to-buffer "*scratch*")))

(defun workroom--encode-buffer-bookmark (buffer)
  "Encode BUFFER using `bookmark-make-record'."
  (with-current-buffer buffer
    (ignore-errors
      (bookmark-make-record))))

(defun workroom--decode-buffer-bookmark (object)
  "Decode OBJECT using `bookmark-jump'."
  (save-window-excursion

    ;; Make sure `display-buffer' only changes the window configuration of
    ;; the selected frame, so that `save-window-excursion' can revert it.
    (let* ((buffers nil)
           (display-buffer-overriding-action
            `(,(lambda (buffer _)
                 (push buffer buffers)
                 (set-window-buffer (frame-first-window) buffer))
              . nil)))
      (bookmark-jump object)
      (car buffers))))

(defun workroom--encode (room)
  "Encode workroom ROOM to a printable object."
  (cons
   0                                    ; Format.
   (list (workroom-name room)
         (mapcar (lambda (view)
                   (cons (workroom-view-name view)
                         (save-window-excursion
                           (workroom--load-window-config
                            (workroom-view-window-config view))
                           (window-state-get (frame-root-window) t))))
                 (workroom-views room))
         (cl-remove-if
          #'null
          (mapcar (lambda (buffer)
                    (catch 'done
                      (dolist (entry workroom-buffer-handler-alist nil)
                        (when-let ((object (funcall (plist-get (cdr entry)
                                                               :encoder)
                                                    buffer)))
                          (throw 'done (cons (car entry) object))))))
                  (workroom-buffer-list room)))
         (when (functionp (workroom-buffers room))
           (workroom-buffers room)))))

(defun workroom--decode (object)
  "Decode OBJECT to a workroom."
  (pcase (car object)
    (0
     (let ((buffers (mapcar (lambda (entry)
                              (funcall
                               (plist-get
                                (alist-get (car entry)
                                           workroom-buffer-handler-alist)
                                :decoder)
                               (cdr entry)))
                            (nth 2 (cdr object)))))
       (make-workroom
        :name (nth 0 (cdr object))
        :views (mapcar (lambda (view-obj)
                         (make-workroom-view
                          :name (car view-obj)
                          :window-config (cdr view-obj)))
                       (nth 1 (cdr object)))
        :buffers (if (nth 3 (cdr object))
                     (nth 3 (cdr object))
                   buffers))))
    (_
     (error "Unknown format of encoding"))))

(defun workroom--restore-rooms (data)
  "Restore workrooms in DATA."
  (pcase (car data)
    ('workroom
     (let ((room (workroom--decode (cdr data))))
       (when-let ((existing (workroom-get (workroom-name room))))
         (unless (y-or-n-p (format-message "Workroom `%s' already\
 exists, overwrite? " (workroom-name room)))
           (user-error "Workroom `%s' exists" (workroom-name room)))
         (workroom-kill existing))
       (push room workroom--rooms)))
    ('workroom-set
     (unless (y-or-n-p "All your workrooms will be overwritten, proceed? ")
       (user-error "Cancelled"))
     (let ((rooms nil)
           (rooms-to-kill nil))
       (dolist (object (cdr data))
         (let ((room (workroom--decode object)))
           (when-let ((existing (workroom-get (workroom-name room))))
             (unless (y-or-n-p (format-message "Workroom `%s' already\
 exists, overwrite? " (workroom-name room)))
               (user-error "Workroom `%s' exists" (workroom-name room)))
             (push existing rooms-to-kill))
           (push room rooms)))
       (mapc #'workroom-kill rooms-to-kill)
       (setq workroom--rooms (nconc rooms workroom--rooms))))))

(defun workroom--read-bookmark (prompt)
  "Read a bookmark name, prompting with PROMPT, without requiring match."
  (bookmark-maybe-load-default-file)
  (completing-read prompt (lambda (string predicate action)
                            (if (eq action 'metadata)
                                '(metadata (category . bookmark))
                              (complete-with-action action bookmark-alist
                                                    string predicate)))
                   nil nil nil 'bookmark-history))

(defun workroom--remove-buffer-refs ()
  "Remove references of current buffer from all workrooms."
  (dolist (room workroom--rooms)
    ;; When buffers is a list, its our responsibility to keep it clean, and
    ;; when its is function, its their responsibility to not return killed
    ;; buffers.
    (unless (functionp (workroom-buffers room))
      (workroom-remove-buffer (current-buffer) room))))

(defmacro workroom--require-mode-enable (&rest body)
  "Execute BODY if Workroom-Mode is enabled, otherwise signal error."
  (declare (indent 0))
  `(if (not workroom-mode)
       (user-error "Workroom mode is not enabled")
     ,@body))

;;;###autoload
(defun workroom-bookmark-jump (bookmark)
  "Handle BOOKMARK."
  (workroom--require-mode-enable
    (let ((data (alist-get 'data (bookmark-get-bookmark-record bookmark))))
      (workroom--restore-rooms data))))

(defun workroom--init-frame (frame)
  "Initialize frame FRAME."
  (when (and (not (frame-parameter frame 'parent-frame))
             (eq (frame-parameter frame 'minibuffer) t))
    (with-selected-frame frame
      (workroom-switch (workroom-get-default)
                       workroom--default-view-of-default-room)
      (set-frame-parameter nil 'workroom-previous-room-list
                           (cdr
                            (frame-parameter
                             nil 'workroom-previous-room-list))))))

(defun workroom-switch (room view)
  "Switch to workroom ROOM if not already and switch to view VIEW of ROOM.

If called interactively, prompt for view to switch.  If prefix argument is
given, ask for workroom to switch before.

ROOM may be a `workroom' object or string.  If ROOM is a `workroom' object,
switch to that workroom.  If ROOM is a string, create a workroom with that
name if it doesn't exist, then switch to the workroom."
  (interactive
   (workroom--require-mode-enable
     (let ((room
            (if current-prefix-arg
                (workroom--read-to-switch
                 "Switch to workroom"
                 (cond
                  ((and (eq (car (workroom-previous-room-list))
                            (workroom-current-room))
                        (< 1 (length (workroom-previous-room-list))))
                   (workroom-name (cadr (workroom-previous-room-list))))
                  ((car (workroom-previous-room-list))
                   (workroom-name (car (workroom-previous-room-list))))))
              (workroom-current-room))))
       (when (and (stringp room) (string-empty-p room))
         (setq room workroom-default-room-name))
       (setq room (workroom-get-create room))
       (let ((view
              (workroom--read-view-to-switch
               room "Switch to view"
               (cond
                ((and (eq (car (workroom-previous-view-list room))
                          (workroom-current-view))
                      (< 1 (length (workroom-previous-view-list room))))
                 (workroom-name (cadr (workroom-previous-view-list room))))
                ((car (workroom-previous-view-list room))
                 (workroom-name
                  (car (workroom-previous-view-list room))))))))
         (when (and (stringp view) (string-empty-p view))
           (setq view workroom-default-view-name))
         (list room view)))))
  (when (stringp room)
    (setq room (workroom-get-create room)))
  (when (stringp view)
    (setq view (workroom-view-get-create room view)))
  (unless (eq room (workroom-current-room))
    (when (workroom-current-room)
      (set-frame-parameter
       nil 'workroom-previous-room-list
       (cons (workroom-current-room)
             (frame-parameter nil 'workroom-previous-room-list))))
    (set-frame-parameter nil 'workroom-current-room room))
  (unless (eq view (workroom-current-view))
    (when (workroom-current-view)
      (setf (workroom-view-window-config (workroom-current-view))
            (workroom--save-window-config)))
    (set-frame-parameter nil 'workroom-current-view view)
    (workroom--load-window-config (workroom-view-window-config view))
    (run-hooks 'workroom-switch-hook)))

(defun workroom-kill (room)
  "Kill workroom ROOM."
  (interactive (workroom--require-mode-enable
                 (list (workroom--read
                        "Kill workroom" (workroom-name
                                         (workroom-current-room))
                        t (lambda (cand)
                            (not (workroom-default-p
                                  (workroom-get (if (consp cand)
                                                    (car cand)
                                                  cand)))))))))
  (when (stringp room)
    (setq room (workroom-get room)))
  (when room
    (when (workroom-default-p room)
      (error "Cannot kill default workroom"))
    (when (eq room (workroom-current-room))
      (workroom-switch (workroom-get-default)
                       workroom--default-view-of-default-room))
    (setq workroom--rooms (delete room workroom--rooms))
    (run-hooks 'workroom-kill-room-hook)))

(defun workroom-kill-view (room view)
  "Kill view VIEW of workroom ROOM."
  (interactive
   (workroom--require-mode-enable
     (let ((room
            (if current-prefix-arg
                (workroom-get
                 (workroom--read
                  "Parent workroom" (workroom-name (workroom-current-room))
                  t))
              (workroom-current-room))))
       (when (eq (length (workroom-views room)) 1)
         (user-error "Cannot kill the last view of a workroom"))
       (list room (workroom--read-view
                   room "Kill view"
                   (when (eq room (workroom-current-room))
                     (workroom-view-name (workroom-current-view))))))))
  (when (stringp room)
    (setq room (workroom-get room)))
  (when (stringp view)
    (setq view (workroom-view-get room view)))
  (when (and room view)
    (when (eq (length (workroom-views room)) 1)
      (error "Cannot kill the last view of a workroom"))
    (when (eq view (workroom-current-view))
      (workroom-switch room (car (workroom-views room)))
      (pop (workroom-previous-view-list room)))
    (setf (workroom-views room) (delete view (workroom-views room)))
    (run-hooks 'workroom-kill-view-hook)))

(defun workroom-rename (room new-name)
  "Rename workroom ROOM to NEW-NAME."
  (interactive
   (workroom--require-mode-enable
     (let ((room (workroom--read
                  "Rename workroom" (workroom-name
                                     (workroom-current-room))
                  t (lambda (cand)
                      (not (workroom-default-p
                            (workroom-get (if (consp cand)
                                              (car cand)
                                            cand))))))))
       (list room (read-string (format-message
                                "Rename workroom `%s' to: " room))))))
  (when (stringp room)
    (setq room (workroom-get room)))
  (setf (workroom-name room) new-name)
  (run-hooks 'workroom-rename-room-hook))

(defun workroom-rename-view (room view new-name)
  "Rename view VIEW of workroom ROOM to NEW-NAME."
  (interactive
   (workroom--require-mode-enable
     (let* ((room
             (if current-prefix-arg
                 (workroom-get
                  (workroom--read
                   "Parent workroom" (workroom-name
                                      (workroom-current-room))
                   t))
               (workroom-current-room)))
            (view (workroom--read-view
                   room (format-message "Rename view of workroom `%s'"
                                        (workroom-name room))
                   (when (eq room (workroom-current-room))
                     (workroom-view-name (workroom-current-view)))
                   t)))
       (list room view
             (read-string (format-message
                           "Rename view `%s' of workroom `%s' to: "
                           view (workroom-name room)))))))
  (when (stringp room)
    (setq room (workroom-get room)))
  (when (stringp view)
    (setq view (workroom-view-get room view)))
  (setf (workroom-view-name view) new-name)
  (run-hooks 'workroom-rename-view-hook))

(defun workroom-clone (room name)
  "Create a new workroom named NAME which is a clone of workroom ROOM."
  (interactive
   (workroom--require-mode-enable
     (let ((room (workroom--read
                  "Clone workroom" (workroom-name
                                    (workroom-current-room))
                  t (lambda (cand)
                      (not (functionp (workroom-buffers
                                       (workroom-get (if (consp cand)
                                                         (car cand)
                                                       cand)))))))))
       (list room (read-string "Name of cloned workroom: ")))))
  (when (stringp room)
    (setq room (workroom-get room)))
  (let ((clone (make-workroom :name name
                              :views (mapcar #'copy-sequence
                                             (workroom-views room))
                              :buffers (workroom-buffers room))))
    (push clone workroom--rooms)
    clone))

(defun workroom-clone-view (room view name)
  "Create a view of workroom ROOM named NAME which is clone of view VIEW."
  (interactive
   (workroom--require-mode-enable
     (let* ((room
             (if current-prefix-arg
                 (workroom-get
                  (workroom--read
                   "Parent workroom" (workroom-name
                                      (workroom-current-room))
                   t))
               (workroom-current-room)))
            (view (workroom--read-view
                   room (format-message "Clone view of workroom `%s'"
                                        (workroom-name room))
                   (when (eq room (workroom-current-room))
                     (workroom-view-name (workroom-current-view)))
                   t)))
       (list room view (read-string "Name of cloned view: ")))))
  (when (stringp room)
    (setq room (workroom-get room)))
  (when (stringp view)
    (setq view (workroom-view-get room view)))
  (let ((clone (make-workroom-view
                :name name
                :window-config (workroom-view-window-config view))))
    (push clone (workroom-views room))
    clone))

(defun workroom-bookmark (room name no-overwrite)
  "Save workroom ROOM to a bookmark named NAME.

If NO-OVERWRITE is nil or prefix arg is given, don't overwrite any previous
bookmark with the same name.

The default workroom cannot be saved."
  (interactive (list (workroom--read "Workroom" nil t
                                     (lambda (cand)
                                       (not (equal (workroom-name
                                                    (workroom-get-default))
                                                   (if (consp cand)
                                                       (car cand)
                                                     cand)))))
                     (workroom--read-bookmark "Save to bookmark: ")
                     current-prefix-arg))
  (when (stringp room)
    (setq room (workroom-get room)))
  (dolist (frame (frame-list))
    (when (frame-parameter frame 'workroom-current-room)
      (with-selected-frame frame
        (setf (workroom-view-window-config (workroom-current-view))
              (workroom--save-window-config)))))
  (bookmark-store name `((data . (workroom . ,(workroom--encode room)))
                         (handler . workroom-bookmark-jump))
                  no-overwrite))

(defun workroom-bookmark-all (name no-overwrite)
  "Save all workrooms except the default one to a bookmark named NAME.

If NO-OVERWRITE is nil or prefix arg is given, don't overwrite any previous
bookmark with the same name."
  (interactive (list (workroom--read-bookmark "Save to bookmark: ")
                     current-prefix-arg))
  (dolist (frame (frame-list))
    (when (frame-parameter frame 'workroom-current-room)
      (with-selected-frame frame
        (setf (workroom-view-window-config (workroom-current-view))
              (workroom--save-window-config)))))
  (bookmark-store name
                  `((data . (workroom-set . ,(mapcar
                                              #'workroom--encode
                                              (remove
                                               (workroom-get-default)
                                               workroom--rooms))))
                    (handler . workroom-bookmark-jump))
                  no-overwrite))

(defun workroom-add-buffer (buffer &optional room)
  "Add BUFFER to workroom ROOM.

ROOM should be a `workroom'.  When ROOM is a `workroom' object, add BUFFER
to it.  If ROOM is nil, add BUFFER to the room of the selected frame.

If ROOM is the default workroom, do nothing."
  (interactive (workroom--require-mode-enable
                 (when (functionp (workroom-buffers
                                   (workroom-current-room)))
                   (user-error (concat "Cannot add buffer to workroom with"
                                       " dynamic buffer list")))
                 (list (get-buffer-create
                        (workroom--read-non-member-buffer
                         (workroom-current-room) "Add buffer: "
                         (when (not (member (current-buffer)
                                            (workroom-buffer-list
                                             (workroom-current-room))))
                           (current-buffer))))
                       nil)))
  (unless room
    (setq room (workroom-current-room)))
  (if (functionp (workroom-buffers room))
      (error "Cannot add buffer to workroom with dynamic buffer list")
    (unless (member buffer (workroom-buffers room))
      (push buffer (workroom-buffers room))
      (run-hooks 'workroom-buffer-list-change-hook))))

(defun workroom-remove-buffer (buffer &optional room)
  "Remove BUFFER from workroom ROOM.

ROOM should be a `workroom'.  When ROOM is a `workroom' object, remove
BUFFER from it.  If ROOM is nil, remove BUFFER to the room of the selected
frame.

If ROOM is the default workroom, kill buffer."
  (interactive (workroom--require-mode-enable
                 (when (and (functionp (workroom-buffers
                                        (workroom-current-room)))
                            (not (workroom-default-p
                                  (workroom-current-room))))
                   (user-error (concat "Cannot remove buffer from"
                                       " non-default workroom with dynamic"
                                       " buffer list")))
                 (list (get-buffer
                        (workroom--read-member-buffer
                         (workroom-current-room)
                         "Remove buffer: "
                         (when (member (current-buffer)
                                       (workroom-buffer-list
                                        (workroom-current-room)))
                           (current-buffer))
                         t))
                       nil)))
  (unless room
    (setq room (workroom-current-room)))
  (if (not (functionp (workroom-buffers room)))
      (when (member buffer (workroom-buffers room))
        (setf (workroom-buffers room)
              (delete buffer (workroom-buffers room)))
        (run-hooks 'workroom-buffer-list-change-hook))
    (unless (workroom-default-p room)
      (error (concat "Cannot remove buffer from non-default workroom with"
                     " dynamic buffer list")))
    (kill-buffer buffer)))

(defmacro workroom-define-replacement (fn)
  "Define `workroom-FN' as replacement for FN.

The defined function is restricts user to the buffers of current workroom
while selecting buffer by setting `read-buffer' function to
`workroom-read-buffer-function', unless prefix arg is given."
  `(defun ,(intern (format "workroom-%S" fn)) ()
     ,(format "Like `%S' but restricted to current workroom.

When prefix arg is given, don't restrict." fn)
     (declare (interactive-only ,(format "Use `%S' instead." fn)))
     (interactive)
     (if current-prefix-arg
         (call-interactively #',fn)
       (let ((read-buffer-function #'workroom-read-buffer-function))
         (call-interactively #',fn)))))

(workroom-define-replacement switch-to-buffer)
(workroom-define-replacement kill-buffer)

;;;###autoload
(define-minor-mode workroom-mode
  "Toggle workroom mode."
  :lighter (:eval workroom-mode-lighter) ; TODO: Why the `:eval' is needed?
  :global t
  (substitute-key-definition 'workroom-command-map nil workroom-mode-map)
  (define-key workroom-mode-map workroom-command-map-prefix
    workroom-command-map)
  (if workroom-mode
      (progn
        (let ((default-room (workroom-get-default)))
          (unless default-room
            (setq default-room
                  (make-workroom
                   :name workroom-default-room-name
                   :views (list
                           (make-workroom-view
                            :name workroom-default-view-name
                            :window-config
                            (workroom--save-window-config)))
                   :buffers #'buffer-list
                   :default-p t))
            (push default-room workroom--rooms))
          (unless (equal (workroom-name default-room)
                         workroom-default-room-name)
            (setf (workroom-name default-room)
                  workroom-default-room-name)))
        (mapc #'workroom--init-frame (frame-list))
        (add-hook 'after-make-frame-functions #'workroom--init-frame)
        (add-hook 'kill-buffer-hook #'workroom--remove-buffer-refs))
    (dolist (frame (frame-list))
      (when (frame-parameter frame 'workroom-current-room)
        (with-selected-frame frame
          (setf (workroom-view-window-config (workroom-current-view))
                (workroom--save-window-config))
          (set-frame-parameter nil 'workroom-current-room nil)
          (set-frame-parameter nil 'workroom-current-view nil)
          (set-frame-parameter nil 'workroom-previous-room-list nil))))
    (remove-hook 'after-make-frame-functions #'workroom--init-frame)
    (remove-hook 'kill-buffer-hook #'workroom--remove-buffer-refs)))

(provide 'workroom)
;;; workroom.el ends here
