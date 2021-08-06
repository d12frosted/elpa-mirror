;;; picpocket.el --- Image viewer -*- lexical-binding: t; coding: utf-8-unix -*-

;; Copyright (C) 2017-2020 Johan Claesson
;; Author: Johan Claesson <johanwclaesson@gmail.com>
;; Maintainer: Johan Claesson <johanwclaesson@gmail.com>
;; URL: https://github.com/johanclaesson/picpocket
;; Package-Version: 20210806.1135
;; Package-Commit: 7e30e96c26b1ff0d374612534c3e09d309426252
;; Version: 42
;; Keywords: multimedia
;; Package-Requires: ((emacs "25.1"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Picpocket is an image viewer which requires GNU Emacs 27.1 or later
;; or 25.1-26.3 compiled with ImageMagick.  It have commands for:
;;
;; * File operations on the picture files (delete, move, copy, hardlink).
;; * Scale and rotate the picture.
;; * Associate pictures with tags which are saved to disk.
;; * Filter pictures according to tags.
;; * Customizing keystrokes for quick tagging and file operations.
;; * Undo and visual history of undoable commands.
;;
;;
;; Main entry points
;; -----------------
;;
;; Command: picpocket
;;   View the pictures in the current directory.
;;
;; Command: picpocket-directory
;;   View the pictures in specified directory.
;;
;;
;; Main keybindings
;; ----------------
;;
;; Space     - Next picture
;; BackSpace - Previous picture
;; r         - Rename picture file
;; c         - Copy picture file
;; k         - Delete picture file
;; t         - Edit tags
;; s         - Slide-show mode
;; [         - Rotate counter-clockwise
;; ]         - Rotate clockwise
;; +         - Scale in
;; -         - Scale out
;; u         - Undo
;; M-u       - View history of undoable actions
;; e         - Customize keystrokes (see below)
;; TAB f     - Toggle full-screen
;; TAB r     - Toggle recursive inclusion of pictures in sub-directories
;; l l       - List current pictures
;; l n       - List current pictures with thumbnails
;; l T       - Browse tag database
;;
;; With prefix argument many of the commands will operatate on all the
;; pictures in the current list instead of just the current picture.
;;
;;
;; Disclaimer
;; ----------
;;
;; Picpocket will secretly do stuff in the background with idle
;; timers.  This includes to load upcoming pictures into the image
;; cache.  The intention is that they should block Emacs for so short
;; periods that it is not noticable.  But if you want to get rid of
;; them set `picpocket-inhibit-timers' or kill the picpocket buffer.
;;
;;
;; Keystroke customization
;; -----------------------
;;
;; Keystokes can be bound to commands that move/copy pictures into
;; directories and/or tag them.  The following creates commands on
;; keys 1 though 5 to tag according to liking.  Also creates some
;; commands to move picture files to directories according to genre.
;; Finally creates also one command to copy pictures to a backup
;; directory in the user's home directory.
;;
;; (defvar my-picpocket-alist
;;   '((?1 tag "bad")
;;     (?2 tag "sigh")
;;     (?3 tag "good")
;;     (?4 tag "great")
;;     (?5 tag "awesome")
;;     (?F move "fantasy")
;;     (?S move "scifi")
;;     (?P move "steampunk")
;;     (?H move "horror")
;;     (?U move "urban-fantasy")
;;     (?B copy "~/backup")))
;;
;; (setq picpocket-keystroke-alist 'my-picpocket-alist)
;;
;; Digits and capital letters with no modifiers is reserved for these
;; kind of user keybindings.
;;
;; It is recommended to set `picpocket-keystroke-alist' to a symbol as
;; above.  That makes the command `picpocket-edit-keystrokes' (bound
;; to `e' in picpocket buffer) jump to your definition for quick
;; changes.  Edit the list and type M-C-x to save it.
;;
;; See the doc of `picpocket-keystroke-alist' for about the same thing
;; but with a few more details.

;;
;; Tag database
;; ------------
;;
;; Tags associated with pictures are saved to disk.  By default to
;; ~/.emacs.d/picpocket/.  This database maps the sha1 checksum of
;; picture files to list of tags.  This implies that you can rename or
;; move around the file anywhere and the tags will still be remembered
;; when you view it with picpocket again.
;;
;; If you change the picture file content the sha1 checksum will
;; change.  For example this would happen if you rotate or crop the
;; picture with an external program.  That will break the association
;; between sha1 checksum and tags.  However picpocket also stores the
;; file name for each entry of tags.  The command
;; `picpocket-db-update' will go through the database and offer to
;; recover such lost associations.
;;
;; If you change the file-name and the file content at the same time
;; there is no way to recover automatically.


;;; Code:

(eval-when-compile
  (require 'time-date)
  (require 'ido))

(require 'cl-lib)
(require 'cl-seq)
(require 'dired)
(require 'subr-x)
(require 'ring)
(require 'ewoc)
(require 'time-date)
(require 'image)
(require 'seq)
(require 'exif nil t)

;;; Options

(defgroup picpocket nil "Picture viewer."
  :group 'multimedia)

(defcustom picpocket-keystroke-alist nil
  "Symbol of variable with an alist of picpocket keystrokes.
\\<picpocket-mode-map>
Elements in the alist have the form (KEY ACTION TARGET).

KEY is a single character, a string accepted by `kbd' or a vector
accepted by `define-key'.

ACTION is tag, move, copy or hardlink.

TARGET is a string.  For ACTION tag it is the tag to add.  For
the other actions it is the destination directory.

Example:

 (defvar my-picpocket-alist
   '((?1 tag \"bad\")
     (?2 tag \"sigh\")
     (?3 tag \"good\")
     (?4 tag \"great\")
     (?5 tag \"awesome\")))

 (setq picpocket-keystroke-alist 'my-picpocket-alist)

There exist a convenience command `picpocket-edit-keystrokes' that
will jump to the definition that the variable
`picpocket-keystroke-alist' points to.  It is bound to
\\[picpocket-keystroke-alist] in the picpocket buffer."
  :risky t
  :type 'symbol)

(define-obsolete-variable-alias 'picpocket-filter-consider-dir-as-tag
  'picpocket-consider-dir-as-tag "picpocket v41")

(defcustom picpocket-consider-dir-as-tag t
  "If non-nil the directory name will be added as a tag."
  :type 'boolean)

(defcustom picpocket-dirs-not-considered-tags nil
  "List of directory names which will not be considered tags.

This is only relevant if `picpocket-consider-dir-as-tag'
is non-nil."
  :type 'list)

(defface picpocket-dir-tags-face  '((((background light))
                                     (:foreground "blue" :slant italic))
                                    (((background dark))
                                     (:foreground "cyan" :slant italic)))
  "Face for tags derived from the directory the file is stored in.")

(defface picpocket-list-main-field '((t (:weight bold)))
  "Face for the file-name in list buffers.")

(defface picpocket-header-file '((t (:inherit highlight)))
  "Face for the file-name in the header.")

(defface picpocket-dim-face '((t (:foreground "gray")))
  "Face for unavailable commands.")


(defvar picpocket-filter-ignore-hyphens t
  "If non-nil the filter ignores underscores and dashes.")


(defcustom picpocket-fit :x-and-y
  "Fit picture size to window when non-nil."
  :type '(choice (const :tag "Fit to both width and height" :x-and-y)
                 (const :tag "Fit to width" :x)
                 (const :tag "Fit to height" :y)
                 (const :tag "Show picture in it's natural size" nil)))

(defcustom picpocket-scale 100
  "Picture scaling in percent."
  :type 'integer)

(defcustom picpocket-header t
  "If non-nil display a header line in picpocket buffer."
  :type 'boolean)

(defcustom picpocket-header-line-format '(:eval (picpocket-header-line))
  "The value for `header-line-format' in picpocket buffers.
Enabled if `picpocket-header' is non-nil."
  :type 'sexp)

(defcustom picpocket-header-full-path nil
  "If non-nil display the whole file path in header line."
  :type 'boolean)

(defcustom picpocket-tags-style :list
  "How a list of tags are displayed."
  :type '(choice (const :tag "Org style :tag1:tag2:" :org)
                 (const :tag "Lisp list style (tag1 tag2)" :list)))

(defcustom picpocket-confirm-delete (not noninteractive)
  "If non-nil let user confirm file delete."
  :type 'boolean)

(defcustom picpocket-backdrop-command nil
  "Command to set desktop backdrop with.
\\<picpocket-mode-map>
Used by `picpocket-set-backdrop' bound to \\[picpocket-backdrop-command] in
picpocket buffer.  If this variable is nil then
`picpocket-set-backdrop' will attempt to find an usable command and
assign it to this variable."
  :type 'string)

(defcustom picpocket-recursive nil
  "If non-nil include sub-directories recursively.
\\<picpocket-mode-map>
This variable can be toggled with the `picpocket-toggle-recursive'
command.  It is bound to \\[picpocket-toggle-recursive] in the
picpocket buffer."
  :type 'boolean)

(defcustom picpocket-follow-symlinks t
  "If non-nil follow symlinks while traversing directories recursively.

Symlinks that points to picture files are always followed.
This option concerns only symlinks that points to directories."
  :type 'boolean)

(defcustom picpocket-destination-dir "~/"
  "Destination dir if `picpocket-destination-relative-current' is nil.

Destination dir is the default target dir for move, copy and
hardlink commands."
  :type 'directory)

(defcustom picpocket-destination-relative-current t
  "If non-nil the destination dir is the current directory.
\\<picpocket-mode-map>
If nil it is the value of variable `picpocket-destination-dir'.  This
variable can be toggled with the command
`picpocket-toggle-destination-dir' bound to
\\[picpocket-toggle-destination-dir] in the picpocket buffer."
  :type 'boolean)

(defcustom picpocket-thumbnail-size 5
  "The heigth of picpocket undo thumbnails.
Specified in number of default line heigths."
  :type 'integer)

(defcustom picpocket-scroll-pixels 10
  "How many pixels to scroll.
This affects commands `picpocket-scroll-up' and `picpocket-scroll-down'.
Horisontal scrolling commands always scroll one column."
  :type 'integer)

(defcustom picpocket-scroll-factor 0.1
  "How much to scroll as a part of the total picture heigth.
This affects the commands `picpocket-scroll-some-*'."
  :type 'number)

(defcustom picpocket-frame-foreground-color nil
  "Foreground color of picpocket fullscreen frame."
  :type 'color)

(defcustom picpocket-frame-background-color nil
  "Background color of picpocket fullscreen frame."
  :type 'color)

(defcustom picpocket-fullscreen-hook nil
  "Normal hook that runs in newly created fullscreen frames."
  :type 'hook)

(defcustom picpocket-slide-show-delay 8
  "Number of seconds to pause for each picture in slide show."
  :type 'number)

(defcustom picpocket-trust-exif-rotation t
  "If non-nil initialize the rotation with exif data when available."
  :type 'boolean)



;;; Variables

;; PENDING some of these would make sense to convert to defcustom

(defconst picpocket-version 42)
(defconst picpocket-buffer "*picpocket*")
(defconst picpocket-undo-buffer "*picpocket-undo*")
(defconst picpocket-list-buffer "*picpocket-list*")
(defconst picpocket-identical-files-buffer "*picpocket-identical-files*")

(defvar picpocket-popping-buffers
  (list picpocket-undo-buffer
        picpocket-identical-files-buffer)
  "List of buffers that pops to another window when they appear.
Only commands that use the `picpocket-with-singleton-buffer'
macro are affected by this list.")

(defvar picpocket-idle-functions
  '((picpocket-update-current-bytes 0.1)
    (picpocket-maybe-save-journal 0.2)
    (picpocket-look-ahead-next 0.2)
    (picpocket-compute-filter-index 0.5 picpocket-pos-p)
    (picpocket-compute-filter-match-count 1)
    (picpocket-traverse-pic-list 3 picpocket-pic-list-p)
    (picpocket-save-journal 60))
  "List of functions to run in background when Emacs is idle.
Elements in the list are lists of the form (WORK-FUNCTION
INTERVAL STATE-PREDICATE).  STATE-PREDICATE is optional.
WORK-FUNCTION is called with two arguments after INTERVAL seconds
of idle time.  The arguments are DEADLINE-FUNCTION and STATE.  If
it will do a lot of work the WORK-FUNCTION is supposed to
periodically call DEADLINE-FUNCTION to check if it's time is up.
DEADLINE-FUNCTION will return non-nil when it is time to stop.
The return value from WORK-FUNCTION is supposed to be the new
STATE.  And that will be passed as the second argument to
WORK-FUNCTION at the next invocation.")
;; PENDING (picpocket-look-ahead-more 2)
;; PENDING (picpocket-update-header picpocket-update-header-seconds)))
(defvar picpocket-timers nil)
(defvar picpocket-inhibit-timers nil)
(defvar picpocket-idle-f-deadline (seconds-to-time 0.2))
(defvar picpocket-idle-f-pause (seconds-to-time 0.1))
(defvar picpocket-idle-f-debug nil)
(defvar picpocket-idle-f-header-info nil)

(defvar picpocket-gimp-executable (executable-find "gimp"))
(defvar picpocket-look-ahead-max 5)
(defvar picpocket-frame nil)
(defvar picpocket-old-frame nil)
(defvar picpocket-last-action nil)
(defvar picpocket-last-arg nil)
(defvar picpocket-debug nil)
(defvar picpocket-sum 0)
(defvar picpocket-picture-regexp nil)
(defvar picpocket-last-look-ahead nil)
(defvar picpocket-clock-alist nil)
(defvar picpocket-adapt-to-window-size-change t)
(defvar picpocket-entry-function nil)
(defvar picpocket-entry-args nil)
(defvar picpocket-filter nil)
(defvar picpocket-window-size nil
  "The current window size in pixels.
This is kept for the benefit of the idle timer functions that do
not necessarily run with the picpocket window selected.")
(defvar picpocket-header-text "")
(defvar picpocket-demote-warnings nil)
(defvar picpocket-sha1sum-executable nil)
(defvar picpocket-old-keystroke-alist nil)
(defvar picpocket-default-backdrop-commands
  '(("display" . "-window root -alpha off")
    ("feh" . "--bg-tile")
    ("hsetroot" . "-tile")
    ("xsetbg")))
(defvar picpocket-tag-completion-table (make-vector 127 0))
(defvar picpocket-minibuffer-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map minibuffer-local-map)
    (define-key map [tab] #'completion-at-point)
    map)
  "Keymap used for completing tags in minibuffer.")
(defvar picpocket-max-undo-thumbnails 4)
(defvar picpocket-undo-list-size 25)
(defvar picpocket-undo-ring nil)
(defvar picpocket-fatal nil)
(defvar picpocket-scroll-command nil)
(defvar picpocket-old-fit nil)
(defvar picpocket-last-frame-that-used-minibuffer nil)
(defvar picpocket-list-pic-list nil)
(defvar picpocket-identical-files-pic nil)
(defvar picpocket-list-entry-function nil)
(defvar picpocket-list-thumbnails nil)
(defvar picpocket-thumbnail-margin 4)
(defvar picpocket-list-max-width 45)
(defvar picpocket-prefer-imagemagick (< emacs-major-version 27)
  "If non-nil prefer imagemagick over other image types.

The default is to prefer imagemagick before 27.1 to get support
for scale and rotate.")
(defvar picpocket-update-hook nil)
(defvar picpocket-enable-mini-buffer t)
(defvar picpocket-mini-buffer-width (if noninteractive 4 220))
(defvar picpocket-mini-buffer "*picpocket-mini*")




;; Variables displayed in the header-line must be marked as risky.
(dolist (symbol '(picpocket-index
                  picpocket-list-length
                  picpocket-current
                  picpocket-filter
                  picpocket-header-text))
  (put symbol 'risky-local-variable t))


;;; The list of pictures

(cl-defstruct picpocket-pos
  current
  index
  filter-index)

(defvar picpocket-list nil
  "The `picpocket-list' is a double-linked list of all pictures in directory.
The car contains a `picpocket-pic' struct whose prev slot points to
the previous cons cell.  The next cell is in the cdr.

Note that this is a circular data structure and `print-circle'
should be non-nil when printing it.")
(defvar picpocket-list-length nil)
(defvar picpocket-current nil)
(defvar picpocket-index 0
  "The `picpocket-index' is starting from 1 (incompatible with elt).
When there are no pictures in the list `picpocket-index' is zero.")

(cl-defstruct picpocket-pic
  prev
  dir
  file
  sha
  size
  bytes
  rotation)


(defsubst picpocket-pic (pic)
  (car (or pic
           picpocket-current
           (error "No current picture"))))

(defsubst picpocket-prev (&optional pic)
  (picpocket-pic-prev (picpocket-pic pic)))

(defsubst picpocket-dir (&optional pic)
  (picpocket-pic-dir (picpocket-pic pic)))

(defsubst picpocket-file (&optional pic)
  (picpocket-pic-file (picpocket-pic pic)))

(defsubst picpocket-sha (&optional pic)
  (picpocket-pic-sha (picpocket-pic pic)))

(defsubst picpocket-size (&optional pic)
  (picpocket-pic-size (picpocket-pic pic)))

(defsubst picpocket-bytes (&optional pic)
  (picpocket-pic-bytes (picpocket-pic pic)))

(defsubst picpocket-rotation (&optional pic)
  (picpocket-pic-rotation (picpocket-pic pic)))


(defsubst picpocket-set-prev (pic value)
  (setf (picpocket-pic-prev (picpocket-pic pic)) value))

(defsubst picpocket-set-dir (pic value)
  (setf (picpocket-pic-dir (picpocket-pic pic)) value))

(defsubst picpocket-set-file (pic value)
  (setf (picpocket-pic-file (picpocket-pic pic)) value))

(defsubst picpocket-set-sha (pic value)
  (setf (picpocket-pic-sha (picpocket-pic pic)) value))

(defsubst picpocket-set-size (pic value)
  (setf (picpocket-pic-size (picpocket-pic pic)) value))

(defsubst picpocket-set-bytes (pic value)
  (setf (picpocket-pic-bytes (picpocket-pic pic)) value))

(defsubst picpocket-set-rotation (pic value)
  (setf (picpocket-pic-rotation (picpocket-pic pic)) value))

(defun picpocket-pic-list-p (pic)
  (and (listp pic)
       (picpocket-pic-p (car pic))))


;;; Macros

(defmacro picpocket-command (&rest body)
  "Macro used in normal picpocket commands.
It is used in all commands except for those that switch to
another buffer.  It takes care of common stuff that shall be done
before and after all commands in picpocket mode.  The convention
is to invoke this macro in the BODY of all command functions.  It
is not used in subroutines because that would make it harder to
verify that it is used in all commands (and preferably only used
one time)."
  (declare (indent defun)
           (debug (body)))
  (let ((rc (make-symbol "rc")))
    `(progn
       (picpocket-ensure-picpocket-buffer)
       (let ((,rc (progn ,@body)))
         (picpocket-ensure-picpocket-buffer)
         (picpocket-update-buffers)
         ,rc))))

(defmacro picpocket-with-singleton-buffer (name &rest body)
  (declare (indent 1)
           (debug (form form body)))
  (let ((buffer (make-symbol "buffer"))
        (old-buffer (make-symbol "old-buffer")))
    `(let ((,old-buffer (buffer-name)))
       (when (get-buffer ,name)
         (kill-buffer ,name))
       (let ((,buffer (get-buffer-create ,name)))
         (if (and (member ,name picpocket-popping-buffers)
                  (not (string-equal ,old-buffer ,name)))
             (pop-to-buffer ,buffer)
           (switch-to-buffer ,buffer))
         (with-current-buffer ,buffer
           (buffer-disable-undo)
           ,@body)))))


(cl-defmacro picpocket-when-let ((var value) &rest body)
  "Evaluate VALUE, if the result is non-nil bind it to VAR and eval BODY."
  (declare (debug ((symbolp form) body))
           (indent 1))
  `(let ((,var ,value))
     (when ,var ,@body)))

(defmacro picpocket-time-string (&rest forms)
  (declare (indent defun)
           (debug (body)))
  `(picpocket-sec-string (cadr (picpocket-time ,@forms))))

(defun picpocket-sec-string (time)
  (let ((sec (format "%.06f" (float-time time))))
    (concat (substring sec 0 -3)
            "_"
            (substring sec -3)
            "s")))

(defmacro picpocket-time (&rest forms)
  "Evaluate FORMS and return (rc time).
The reason it does not return (rc . time) is to be able to bind
with `cl-multiple-value-bind' etc."
  (declare (indent defun)
           (debug (body)))
  (let ((before (make-symbol "before"))
        (rc (make-symbol "rc")))
    `(let ((,before (current-time))
           (,rc (progn ,@forms)))
       (list ,rc (time-since ,before)))))

(defmacro picpocket-clock (&rest body)
  (declare (indent defun))
  (let ((thing (caar body)))
    `(picpocket-clock-thing ',thing ,@body)))

(defmacro picpocket-clock-thing (thing &rest body)
  (declare (indent 1))
  (let ((rc (make-symbol "rc"))
        (s (make-symbol "s"))
        (sum (make-symbol "sum")))
    `(cl-destructuring-bind (,rc ,s) (picpocket-time (progn ,@body))
       (let ((,sum (assq ,thing picpocket-clock-alist)))
         (if ,sum
             (setcdr ,sum (time-add ,s (cdr ,sum)))
           (push (cons ,thing ,s) picpocket-clock-alist)))
       ,rc)))

(defmacro picpocket-with-clock (title &rest body)
  (declare (debug (stringp body))
           (indent 1))
  `(let (picpocket-clock-alist)
     (prog1
         (progn ,@body)
       (picpocket-clock-report ,title))))


;;; Picpocket mode

(define-derived-mode picpocket-base-mode special-mode "picpocket-base"
  "Base major mode for buffers with images.
This mode is not used directly.  Other modes inherit from this mode.

\\{picpocket-base-mode-map}"
  (buffer-disable-undo)
  ;; Ensure imagemagick is preferred.
  ;; (when picpocket-prefer-imagemagick
  ;; (unless (eq 'imagemagick (cdar image-type-file-name-regexps))
  ;; (let ((entry (rassq 'imagemagick image-type-file-name-regexps)))
  ;; (setq-local image-type-file-name-regexps
  ;; (cons entry
  ;; (delete entry (cl-copy-list
  ;; image-type-file-name-regexps))))))
  ;; (setq-local image-type-header-regexps nil))
  (when (boundp 'image-scaling-factor)
    (setq-local image-scaling-factor 1.0))
  ;; image-map is embedded as text property on all images,
  ;; we do not want that in this buffer.
  (when (boundp 'image-map)
    (setq-local image-map nil))
  (setq truncate-lines t
        auto-hscroll-mode nil
        picpocket-fatal nil))

(define-derived-mode picpocket-mode picpocket-base-mode "picpocket"
  "Major mode for the main *picpocket* buffer.

\\{picpocket-mode-map}"
  ;; PENDING
  ;; :after-hook (picpocket-update-keymap)
  (picpocket-db-init)
  (picpocket-db-compile-tags-for-completion)
  (setq header-line-format (when picpocket-header
                             picpocket-header-line-format)
        vertical-scroll-bar nil
        cursor-type nil
        left-fringe-width 0
        right-fringe-width 0)
  ;; Call set-window-buffer to update the fringes.
  ;; PENDING should call set-window-buffer in create function instead?
  (set-window-buffer (selected-window) (current-buffer))
  (when (eq (selected-frame) picpocket-frame)
    (setq mode-line-format nil))
  (add-hook 'kill-emacs-hook #'picpocket-delete-trashcan)
  (add-hook 'kill-buffer-hook #'picpocket-save-journal nil t)
  (add-hook 'kill-buffer-hook #'picpocket-cleanup-most-hooks nil t)
  (add-hook 'kill-buffer-hook #'picpocket-cleanup-misc nil t)
  (add-hook 'window-size-change-functions
            #'picpocket-window-size-change-function)
  (add-hook 'buffer-list-update-hook #'picpocket-maybe-update-keymap)
  (add-hook 'buffer-list-update-hook #'picpocket-maybe-rescale)
  (picpocket-init-timers)
  (picpocket-update-keymap))

(defun picpocket-unload-function ()
  (message "Unloading picpocket")
  (picpocket-cancel-timers)
  (picpocket-delete-trashcan)
  (picpocket-cleanup-most-hooks)
  (remove-hook 'kill-emacs-hook #'picpocket-delete-trashcan)
  nil)

(defvar picpocket-base-toggle-map
  (let ((map (make-sparse-keymap
              (concat "Toggle:"
                      " [d - destination]"
                      " [r - recursive]"
                      " [l - follow symlinks]"
                      " [t - dir-tags]"
                      " [n - thumbnails]"
                      " [D - debug]"))))
    (define-key map [?d] #'picpocket-toggle-destination-dir)
    (define-key map [?r] #'picpocket-toggle-recursive)
    (define-key map [?l] #'picpocket-toggle-follow-symlinks)
    (define-key map [?t] #'picpocket-toggle-dir-tags)
    (define-key map [?n] #'picpocket-toggle-thumbnails)
    (define-key map [?D] #'picpocket-toggle-debug)
    map))

(defvar picpocket-toggle-map
  (let ((map (make-sparse-keymap
              ;; PENDING compute...
              (concat "Toggle:"
                      " [f - fullscreen]"
                      " [h - header]"
                      " [d - destination]"
                      " [r - recursive]"
                      " [l - follow symlinks]"
                      " [t - dir-tags]"
                      " [n - thumbnails]"
                      " [D - debug]"))))
    (set-keymap-parent map picpocket-base-toggle-map)
    (define-key map [?f] #'picpocket-toggle-fullscreen-frame)
    (define-key map [?h] #'picpocket-toggle-header)
    map))

(let ((map (make-sparse-keymap)))
  (suppress-keymap map)
  (define-key map [??] #'picpocket-help)
  (define-key map [tab] picpocket-toggle-map)
  (define-key map [backspace] #'picpocket-previous)
  (define-key map [?p] #'picpocket-previous)
  (define-key map [?\s] #'picpocket-next)
  (define-key map [?n] #'picpocket-next)
  (define-key map [?d] #'picpocket-dired)
  (define-key map [?v] #'picpocket-visit-file)
  (define-key map [?e] #'picpocket-edit-keystrokes)
  (define-key map [home] #'picpocket-home)
  (define-key map [?k] #'picpocket-delete-file)
  (define-key map [deletechar] #'picpocket-delete-file)
  (define-key map [end] #'picpocket-end)
  (define-key map [?q] #'picpocket-quit)
  (define-key map [?s] #'picpocket-slide-show)
  (define-key map [?r] #'picpocket-rename)
  (define-key map [?m] #'picpocket-move)
  (define-key map [?c] #'picpocket-copy)
  (define-key map [?h] #'picpocket-hardlink)
  (define-key map [(meta ?m)] #'picpocket-move-by-keystroke)
  (define-key map [(meta ?c)] #'picpocket-copy-by-keystroke)
  (define-key map [(meta ?l)] #'picpocket-hardlink-by-keystroke)
  (define-key map [(meta ?t)] #'picpocket-tag-by-keystroke)
  (define-key map [?t] #'picpocket-edit-tags)
  (define-key map [?z] #'picpocket-repeat)
  (define-key map [?g] #'picpocket-revert)
  (define-key map [?.] #'picpocket-dired-up-directory)
  (define-key map [?f] #'picpocket-set-filter)
  (define-key map [(meta ?f)] #'picpocket-set-filter-by-keystroke)
  (define-key map [?\[] #'picpocket-rotate-counter-clockwise)
  (define-key map [?\]] #'picpocket-rotate-clockwise)
  (define-key map [?{] #'picpocket-rotate-counter-clockwise-10-degrees)
  (define-key map [?}] #'picpocket-rotate-clockwise-10-degrees)
  (define-key map [(meta ?\[)] #'picpocket-reset-rotation)
  (define-key map [(meta ?\])] #'picpocket-save-rotation)
  (define-key map [?+] #'picpocket-scale-in)
  (define-key map [?=] #'picpocket-scale-in)
  (define-key map [?-] #'picpocket-scale-out)
  (define-key map [?0] #'picpocket-reset-scale)
  (define-key map [(meta ?b)] #'picpocket-fit-to-both-width-and-height)
  (define-key map [(meta ?w)] #'picpocket-fit-to-width)
  (define-key map [(meta ?h)] #'picpocket-fit-to-height)
  (define-key map [(meta ?n)] #'picpocket-no-fit)
  (define-key map [left] #'picpocket-scroll-left)
  (define-key map [right] #'picpocket-scroll-right)
  (define-key map [(meta left)] #'picpocket-scroll-some-left)
  (define-key map [(meta right)] #'picpocket-scroll-some-right)
  (define-key map [(control left)] #'picpocket-scroll-to-max-left)
  (define-key map [(control right)] #'picpocket-scroll-to-max-right)
  (define-key map [up] #'picpocket-scroll-up)
  (define-key map [down] #'picpocket-scroll-down)
  (define-key map [(control up)] #'picpocket-scroll-to-top)
  (define-key map [(control down)] #'picpocket-scroll-to-bottom)
  (define-key map [(meta up)] #'picpocket-scroll-some-up)
  (define-key map [(meta down)] #'picpocket-scroll-some-down)
  (define-key map [(control meta down)] #'picpocket-start-scroll-down)
  (define-key map [(control meta up)] #'picpocket-start-scroll-up)
  (define-key map [(control meta left)] #'picpocket-start-scroll-left)
  (define-key map [(control meta right)] #'picpocket-start-scroll-right)
  (define-key map [(meta ?a)] #'picpocket-auto-scroll)
  (define-key map [(meta ?s)] #'picpocket-stop-or-start-scroll)
  (define-key map [mouse-4] #'picpocket-scroll-up)
  (define-key map [mouse-5] #'picpocket-scroll-down)
  (define-key map [mouse-6] #'picpocket-scroll-left)
  (define-key map [mouse-7] #'picpocket-scroll-right)
  (define-key map [?u] #'picpocket-undo)
  (define-key map [(meta ?u)] #'picpocket-visit-undo-list)
  (define-key map [?j] #'picpocket-jump)
  (define-key map [?x ?g] #'picpocket-gimp-open)
  (define-key map [?x ?t] #'picpocket-trim)
  (define-key map [?x ?b] #'picpocket-set-backdrop)
  (define-key map [?l ?i] #'picpocket-list-identical-files)
  (define-key map [?l ?l] #'picpocket-list-current-list)
  (define-key map [?l ?t] #'picpocket-list-current-by-tags)
  (define-key map [?l ?T] #'picpocket-list-all-tags)
  (define-key map [?l ?n] #'picpocket-list-current-list-with-thumbnails)
  (define-key map [?|] #'picpocket-toggle-mini-window)
  (setq picpocket-mode-map map))


;;; Entry points

;;;###autoload
(defun picpocket ()
  "View the pictures in the current directory."
  (interactive)
  (let ((selected-file (cond ((buffer-file-name)
                              (file-truename (buffer-file-name)))
                             ((eq major-mode 'dired-mode)
                              (dired-get-filename nil t))
                             ((and (eq major-mode 'picpocket-mode)
                                   picpocket-current)
                              (picpocket-absfile))
                             (t nil))))
    (picpocket-directory default-directory selected-file)))

(defun picpocket-directory (dir &optional selected-file)
  "View the pictures in DIR starting with SELECTED-FILE."
  (interactive "DDirectory: ")
  (setq picpocket-entry-function 'picpocket-directory
        picpocket-entry-args (list dir))
  (let ((files (picpocket-file-list dir)))
    (picpocket-create-buffer files selected-file dir)))

(defun picpocket-files (files &optional selected-file)
  "View the list of image files in FILES starting with SELECTED-FILE."
  (setq picpocket-entry-function 'picpocket-files
        picpocket-entry-args (list files)
        files (cl-loop for file in files
                       when (picpocket-picture-file-p file t)
                       collect file))
  (picpocket-create-buffer files selected-file))

;;;###autoload
(defun picpocket-list-all-tags ()
  "Browse database of picpocket tags.

Tags are added to pictures with for example the
`picpocket-edit-tags' command inside the picpocket buffer (bound to
\\[picpocket-edit-tags])."
  (interactive)
  (picpocket-with-singleton-buffer picpocket-list-buffer
    (picpocket-list-tags-mode)
    (setq-local picpocket-list-entry-function #'picpocket-list-all-tags)
    (setq-local picpocket-list-pic-list nil)
    (picpocket-list-tags-refresh)
    (tabulated-list-sort 0)))

;;;###autoload
(defun picpocket-db-update ()
  "Manage the tag database.

Enter a special buffer where any suspicious database entries are
listed.  Suspicious entries are for example when files that have
disappeared.  Maybe they have been deleted outside of picpocket.
And the entries in picpocket now points to nowhere.  If there are
any such entries they will be listed in this buffer.  And there
will be an offer to clean up those entries from the database.

Note that this command can take some time to finish since it goes
through the entire database."
  (interactive)
  (picpocket-do-db-update))


;;; Picpocket mode commands

(defun picpocket-rotate-counter-clockwise (&optional arg)
  "Display the current picture rotated 90 degrees to the left.
This command do not change the picture file on disk.  With prefix
arg (ARG) read a number in the minibuffer and set rotation to
that."
  (interactive "P")
  (picpocket-command
    (picpocket-rotate -90.0 arg)))

(defun picpocket-rotate-clockwise (&optional arg)
  "Display the current picture rotated 90 degrees to the right.
This command do not change the picture file on disk.  With prefix
arg (ARG) read a number in the minibuffer and set rotation to
that."
  (interactive "P")
  (picpocket-command
    (picpocket-rotate 90.0 arg)))

(defun picpocket-rotate-counter-clockwise-10-degrees (&optional arg)
  "Display the current picture rotated 10 degrees to the left.
This command do not change the picture file on disk.  With prefix
arg (ARG) read a number in the minibuffer and set rotation to
that."
  (interactive "P")
  (picpocket-command
    (picpocket-check-rotation-support)
    (picpocket-rotate -10.0 arg)))

(defun picpocket-rotate-clockwise-10-degrees (&optional arg)
  "Display the current picture rotated 10 degrees to the right.
This command do not change the picture file on disk.  With prefix
arg (ARG) read a number in the minibuffer and set rotation to
that."
  (interactive "P")
  (picpocket-command
    (picpocket-check-rotation-support)
    (picpocket-rotate 10.0 arg)))

(defun picpocket-check-rotation-support ()
  (unless (eq 'imagemagick (picpocket-image-type picpocket-current))
    (message "%s%s"
             "Rotating to non-square angels require Emacs compiled with "
             "imagemagick and `picpocket-prefer-imagemagick' non-nil")))

(defun picpocket-reset-rotation ()
  "Display the current picture as is without any rotation."
  (interactive)
  (picpocket-command
    (picpocket-current-picture-check)
    (picpocket-set-rotation picpocket-current 0.0)))

(defun picpocket-rotate (delta arg)
  (let ((degrees (if arg
                     (float (read-number "Set rotation in degrees"
                                         (picpocket-rotation)))
                   (+ (picpocket-rotation) delta))))
    (setq degrees (mod degrees 360.0))
    (picpocket-current-picture-check)
    (picpocket-set-rotation picpocket-current degrees)))

(defun picpocket-scale-in (&optional arg)
  "Zoom in 10%.
With prefix arg (ARG) read scale percent in minibuffer."
  (interactive "P")
  (picpocket-command
    (if arg
        (setq picpocket-scale (read-number "Scale factor: " picpocket-scale))
      (picpocket-alter-scale 10))))

(defun picpocket-scale-out (&optional arg)
  "Zoom out 10%.
With prefix arg (ARG) read scale percent in minibuffer."
  (interactive "P")
  (picpocket-command
    (if arg
        (setq picpocket-scale (read-number "Scale factor: "
                                           picpocket-scale))
      (picpocket-alter-scale -10))
    (when (picpocket-current-picture-p)
      (picpocket-avoid-overscroll))))

(defun picpocket-reset-scale ()
  "Reset the scale to 100%."
  (interactive)
  (picpocket-command
    (setq picpocket-scale 100)
    (message "Restore the scale to 100%%")
    (when (picpocket-current-picture-p)
      (picpocket-avoid-overscroll))))

(defun picpocket-fit-to-both-width-and-height ()
  "Fit the picture to both width and height of window.
Fitting is done before applying the scaling factor.  That is, it
will only really fit when the scaling is the default 100%.  The
scaling can be restored to 100% by typing \\[picpocket-reset-scale]
\(bound to the command `picpocket-reset-scale')."
  (interactive)
  (picpocket-command
    (picpocket-reset-scroll)
    (setq picpocket-fit :x-and-y)
    (message "Fit picture to both width and height")))

(defun picpocket-fit-to-width ()
  "Fit the picture to the width of window.
Fitting is done before applying the scaling factor.  That is, it
will only really fit when the scaling is the default 100%.  The
scaling can be restored to 100% by typing \\[picpocket-reset-scale]
\(bound to the command `picpocket-reset-scale')."
  (interactive)
  (picpocket-command
    (picpocket-reset-scroll)
    (setq picpocket-fit :x)
    (message "Fit picture to width")))

(defun picpocket-fit-to-height ()
  "Fit the picture to the height of window.
Fitting is done before applying the scaling factor.  That is, it
will only really fit when the scaling is the default 100%.  The
scaling can be restored to 100% by typing \\[picpocket-reset-scale]
\(bound to the command `picpocket-reset-scale')."
  (interactive)
  (picpocket-command
    (picpocket-reset-scroll)
    (setq picpocket-fit :y)
    (message "Fit picture to height")))

(defun picpocket-no-fit ()
  "Do not fit the picture to the window."
  (interactive)
  (picpocket-command
    (picpocket-reset-scroll)
    (setq picpocket-fit nil)
    (message "Do not fit picture to window size")))


(defun picpocket-set-backdrop ()
  "Attempt to install the current picture as desktop backdrop."
  (interactive)
  (picpocket-command
    (picpocket-current-picture-check)
    (setq picpocket-backdrop-command (or picpocket-backdrop-command
                                         (picpocket-default-backdrop-command)))
    (unless picpocket-backdrop-command
      (error (concat "Command to set backdrop not found."
                     " Set picpocket-backdrop-command or install %s")
             (picpocket-default-backdrop-commands-string)))
    (let* ((words (split-string picpocket-backdrop-command))
           (cmd (car words))
           (file (picpocket-absfile))
           (args (append (cdr words) (list file))))
      (with-temp-buffer
        (unless (zerop (apply #'call-process cmd nil t nil args))
          (error "Command \"%s %s\" failed with output \"%s\""
                 picpocket-backdrop-command file (buffer-string))))
      (message "%s installed %s as backdrop" cmd file))))

(defun picpocket-default-backdrop-command ()
  (cl-loop for (cmd . args) in picpocket-default-backdrop-commands
           when (executable-find cmd)
           return (concat cmd " " args " ")))


(defun picpocket-default-backdrop-commands-string ()
  (concat
   (mapconcat #'identity
              (butlast (mapcar #'car picpocket-default-backdrop-commands))
              ", ")
   " or "
   (caar (last picpocket-default-backdrop-commands))))

(defun picpocket-toggle-debug ()
  "Toggle debug mode."
  (interactive)
  (setq picpocket-debug (not picpocket-debug))
  (message "Picpocket debug is %s" (if picpocket-debug "on" "off")))

(defun picpocket-toggle-recursive ()
  "Toggle recursive inclusion of sub-directories.
Directories whose name starts with a dot will not be traversed.
However picture files whose name starts with dot will be
included."
  (interactive)
  (picpocket-command
    (setq picpocket-recursive (not picpocket-recursive))
    (picpocket-do-revert)
    (message (if picpocket-recursive
                 "Recursively include pictures in subdirectories"
               "Only show pictures in current directory"))))

(defun picpocket-toggle-follow-symlinks ()
  "Toggle whether to follow symlinks while recursively traversing directories.
Symlinks that points to picture files are always followed.
This command concerns only symlinks that points to directories."
  (interactive)
  (picpocket-command
    (setq picpocket-follow-symlinks (not picpocket-follow-symlinks))
    (picpocket-do-revert)
    (message (if picpocket-follow-symlinks
                 "Follow symlinks"
               "Do not follow symlinks"))))

(defun picpocket-toggle-dir-tags ()
  "Toggle the value of `picpocket-consider-dir-as-tag'."
  (interactive)
  (picpocket-command
    (setq picpocket-consider-dir-as-tag
          (not picpocket-consider-dir-as-tag))
    (force-mode-line-update)
    (message "%s containing directories as tags"
             (if picpocket-consider-dir-as-tag
                 "Count"
               "Do not count"))))

(defun picpocket-quit ()
  "Quit picpocket."
  (interactive)
  (picpocket-disable-fullscreen)
  (picpocket-when-let (w (picpocket-visible-window picpocket-mini-buffer))
    (delete-window w))
  (picpocket-save-journal)
  (quit-window))

(defun picpocket-disable-fullscreen ()
  (when (picpocket-fullscreen-p)
    (picpocket-toggle-fullscreen-frame)))

(defun picpocket-toggle-destination-dir (&optional ask-for-dir)
  "Toggle the destination for file operations.

File operations are move, copy and hardlink.  Either the
destination is relative to the current directory.  Or it is
relative the value of variable `picpocket-destination-dir'.

With prefix arg ask for a directory and set variable
`picpocket-destination-dir' to that.  Calling from Lisp with the argument
ASK-FOR-DIR non-nil will also do that."
  (interactive "P")
  (if ask-for-dir
      (setq picpocket-destination-relative-current nil
            picpocket-destination-dir
            (read-directory-name "Destination dir: "))
    (setq picpocket-destination-relative-current
          (not picpocket-destination-relative-current)))
  (force-mode-line-update)
  (message "Destination directory is relative to %s"
           (if picpocket-destination-relative-current
               "the current directory"
             picpocket-destination-dir)))

(defun picpocket-toggle-thumbnails ()
  "Toggle thumbnails in list buffers.

\(Thumbnails are always enabled in undo buffers)."
  (interactive)
  (setq picpocket-list-thumbnails (not picpocket-list-thumbnails))
  (when picpocket-list-entry-function
    (funcall picpocket-list-entry-function))
  (message "Thumbnails %s" (if picpocket-list-thumbnails
                               "on"
                             "off")))


(defun picpocket-edit-keystrokes ()
  "Move to definition of variable `picpocket-keystroke-alist'.
To use this command you must set variable `picpocket-keystroke-alist'
to a variable symbol.  The purpose of this command is to be
able to quickly move to the definition and edit keystrokes."
  (interactive)
  (unless (and picpocket-keystroke-alist
               (symbolp picpocket-keystroke-alist))
    (user-error (concat "You need to set picpocket-keystroke-alist "
                        "to a symbol for this command to work")))
  (find-variable-other-window picpocket-keystroke-alist)
  (goto-char (point-at-eol)))

(defun picpocket-slide-show ()
  "Start slide-show."
  (interactive)
  (picpocket-command
    (while (and (not (input-pending-p))
                (picpocket-next-pos))
      (picpocket-next)
      (when (picpocket-next-pos)
        (sit-for picpocket-slide-show-delay)))
    (message "End of slide-show")))

(defun picpocket-visit-file ()
  "Open the current picture in default mode (normally `image-mode')."
  (interactive)
  (picpocket-current-picture-check)
  (find-file (picpocket-absfile)))

(defun picpocket-toggle-fullscreen-frame ()
  "Toggle use of fullscreen frame.

The first call will show the picpocket buffer in a newly created
frame in fullscreen mode.  It is meant to only show the picpocket
buffer (but this is not enforced).  The second call will delete
this frame and go back to the old frame."
  (interactive)
  (picpocket-command
    (if (picpocket-fullscreen-p)
        (let ((inhibit-quit t)
              (mini-buffer (get-buffer picpocket-mini-buffer))
              (mini-enabled (picpocket-visible-window picpocket-mini-buffer)))
          (delete-frame picpocket-frame)
          (setq picpocket-frame nil)
          (picpocket-select-frame picpocket-old-frame)
          (with-selected-frame picpocket-old-frame
            (switch-to-buffer picpocket-buffer)
            (if mini-enabled
                (unless (picpocket-visible-window picpocket-mini-buffer)
                  (picpocket-add-mini-window))
              (picpocket-when-let (w (picpocket-visible-window
                                      picpocket-mini-buffer))
                (delete-window w))))
          (when mini-buffer
            (with-current-buffer mini-buffer
              (setq mode-line-format (default-value 'mode-line-format))))
          (with-current-buffer picpocket-buffer
            (setq mode-line-format (default-value 'mode-line-format))))
      ;; Bury the picpocket buffer in the old frame.  This relieves
      ;; the display engine from updating that as well.  This is
      ;; important when the fullscreen frame have a different
      ;; background-color or foreground-color (see
      ;; picpocket-frame-background-color and
      ;; picpocket-frame-foreground-color).  These frame parameters
      ;; are considered during image cache lookup (see
      ;; image.c:search_image_cache).  Therefore each frame would have
      ;; it's own cache entry in the case where these colors differ.
      (bury-buffer)
      (setq picpocket-old-frame (selected-frame))
      ;; Do not disable scroll bars and fringes, they are disabled
      ;; on buffer level instead.
      (let ((inhibit-quit t)
            (mini-enabled (picpocket-visible-window picpocket-mini-buffer)))
        (setq picpocket-frame (picpocket-fullscreen-frame))
        (picpocket-select-frame picpocket-frame)
        (switch-to-buffer picpocket-buffer)
        (when mini-enabled
          (picpocket-add-mini-window))
        (with-current-buffer picpocket-buffer
          (setq mode-line-format nil)
          ;; PENDING use after-focus-change-function instead...?
          (with-no-warnings
            (add-hook 'focus-in-hook #'picpocket-focus))
          (add-hook 'minibuffer-setup-hook #'picpocket-minibuffer-setup)
          (add-hook 'minibuffer-exit-hook #'picpocket-minibuffer-exit)
          (with-selected-frame picpocket-frame
            (run-hooks 'picpocket-fullscreen-hook))))
      ;; Resdisplay seem to be needed to get accurate return value from
      ;; window-inside-pixel-edges.
      (redisplay))))


(defun picpocket-fullscreen-frame ()
  (let ((foreground (or picpocket-frame-foreground-color
                        (frame-parameter nil 'foreground-color)))
        (background (or picpocket-frame-background-color
                        (frame-parameter nil 'background-color))))
    (make-frame `((name . "picpocket")
                  (menu-bar-lines . 0)
                  (tool-bar-lines . 0)
                  (minibuffer . nil)
                  (fullscreen . fullboth)
                  (foreground-color . ,foreground)
                  (background-color . ,background)))))


(defun picpocket-focus ()
  "Update picture when `picpocket-minibuffer-exit' select the picpocket frame.
Without this the picture size may be fitted to the wrong frame.
This hook make sure it is fitted to the picpocket frame."
  (and (eq (selected-frame) picpocket-frame)
       (eq (current-buffer) (get-buffer picpocket-buffer))
       (picpocket-update-main-buffer)))

(defun picpocket-minibuffer-setup ()
  (setq picpocket-last-frame-that-used-minibuffer last-event-frame)
  (when (eq picpocket-frame last-event-frame)
    (select-frame-set-input-focus default-minibuffer-frame)))

(defun picpocket-minibuffer-exit ()
  (when (and (picpocket-fullscreen-p)
             (eq picpocket-frame picpocket-last-frame-that-used-minibuffer))
    (select-frame-set-input-focus picpocket-frame)))

(defun picpocket-fullscreen-p ()
  (and picpocket-frame
       (frame-live-p picpocket-frame)))

(defun picpocket-frame ()
  (if (picpocket-fullscreen-p)
      picpocket-frame
    (selected-frame)))

(defun picpocket-select-frame (frame)
  (select-frame-set-input-focus frame)
  (switch-to-buffer picpocket-buffer)
  ;; set-window-buffer will update the fringes.
  (set-window-buffer (selected-window) (current-buffer)))


(defun picpocket-next ()
  "Move to the next picture in the current list."
  (interactive)
  (picpocket-command
    (let ((next (picpocket-next-pos)))
      (if next
          (picpocket-set-pos next)
        (picpocket-no-file "next")))))

(defun picpocket-next-pos (&optional pos silent)
  (unless pos
    (setq pos (picpocket-current-pos)))
  (let (printed)
    (prog1
        (cl-loop for pic = (cdr (picpocket-pos-current pos)) then (cdr pic)
                 for index = (1+ (picpocket-pos-index pos)) then (1+ index)
                 while pic
                 when (picpocket-filter-match-p pic)
                 return (make-picpocket-pos
                         :current pic
                         :index index
                         :filter-index
                         (when (picpocket-pos-filter-index pos)
                           (1+ (picpocket-pos-filter-index pos))))
                 with next-progress-index = (+ (picpocket-pos-index pos) 100)
                 when (>= index next-progress-index)
                 do (unless silent
                      (setq printed t)
                      (message "Searching at index %s..." index)
                      (setq next-progress-index (+ next-progress-index 100))))
      (when printed
        (message nil)))))

(defun picpocket-current-pos ()
  (make-picpocket-pos :current picpocket-current
                      :index picpocket-index
                      :filter-index (picpocket-filter-index)))

(defun picpocket-next-pic ()
  (picpocket-when-let (pos (picpocket-next-pos nil 'silent))
    (picpocket-pos-current pos)))

(defun picpocket-previous ()
  "Move to the previous picture in the current list."
  (interactive)
  (picpocket-command
    (let ((prev (picpocket-previous-pos)))
      (if prev
          (picpocket-set-pos prev)
        (picpocket-no-file "previous")))))

(defun picpocket-previous-pic ()
  (picpocket-when-let (pos (picpocket-previous-pos 'silent))
    (picpocket-pos-current pos)))

(defun picpocket-previous-pos (&optional silent)
  (let (printed)
    (prog1
        (cl-loop for pic = (picpocket-safe-prev picpocket-current)
                 then (picpocket-safe-prev pic)
                 for index = (1- picpocket-index)
                 then (1- index)
                 while pic
                 when (picpocket-filter-match-p pic)
                 return (make-picpocket-pos :current pic
                                            :index index
                                            :filter-index
                                            (when (picpocket-filter-index)
                                              (1- (picpocket-filter-index))))
                 with next-progress-index = (- picpocket-index 100)
                 when (<= index next-progress-index)
                 do (unless silent
                      (setq printed t)
                      (message "Searching at index %s..." index)
                      (setq next-progress-index (- next-progress-index 100))))
      (when printed
        (message nil)))))


(defun picpocket-safe-prev (pic)
  (when pic
    (picpocket-prev pic)))

(defun picpocket-home ()
  "Move to the first picture in the current list."
  (interactive)
  (picpocket-command
    (picpocket-set-pos (picpocket-first-pos))
    (unless (picpocket-filter-match-p picpocket-current)
      (let ((next (picpocket-next-pos)))
        (if next
            (picpocket-set-pos next)
          (picpocket-no-file))))))

(defun picpocket-first-pos ()
  (make-picpocket-pos :current picpocket-list
                      :index 1
                      :filter-index
                      (if (picpocket-filter-match-p picpocket-list)
                          1
                        0)))

(defun picpocket-end ()
  "Move to the last picture in the current list."
  (interactive)
  (picpocket-command
    (picpocket-current-picture-check)
    (picpocket-set-pos (picpocket-last-pos))
    (unless (picpocket-filter-match-p picpocket-current)
      (let ((prev (picpocket-previous-pos)))
        (if prev
            (picpocket-set-pos prev)
          (picpocket-no-file))))))

(defun picpocket-last-pos ()
  (cl-loop for pic on picpocket-current
           for index = picpocket-index then (1+ index)
           when (null (cdr pic))
           return (make-picpocket-pos :current pic
                                      :index index)))

(defun picpocket-delete-file ()
  "Permanently delete the current picture file."
  (interactive)
  (picpocket-command
    (picpocket-current-picture-check)
    (when (picpocket-confirm-delete-file (picpocket-file))
      (picpocket-action 'delete nil))))

(defun picpocket-confirm-delete-file (file)
  (or (not picpocket-confirm-delete)
      (picpocket-y-or-n-p "Delete file %s from disk? "
                          file)))

(defun picpocket-y-or-n-p (format &rest objects)
  (let* ((prompt (apply #'format format objects))
         (header-line-format (concat prompt " (y or n)")))
    (y-or-n-p prompt)))

(defun picpocket-repeat ()
  "Repeat the last repeatable action.
The repeatable actions are:
1. Move/copy/hardlink the current picture to a directory.
2. Add a tag to or remove a tag from the current picture."
  (interactive)
  (picpocket-command
    (unless picpocket-last-action
      (user-error "No repeatable action have been done"))
    (picpocket-action picpocket-last-action picpocket-last-arg)))

(defun picpocket-dired ()
  "Visit the current directory in `dired-mode'."
  (interactive)
  (if picpocket-current
      (let ((dir (picpocket-dir))
            (file (picpocket-absfile)))
        (dired default-directory)
        (when (and (equal dir (file-truename default-directory))
                   (file-exists-p file))
          (dired-goto-file file)))
    (dired default-directory)))

(defun picpocket-dired-up-directory ()
  "Enter Dired mode in the parent directory."
  (interactive)
  (let ((dir default-directory))
    (quit-window)
    (dired (file-name-directory (directory-file-name dir)))
    (dired-goto-file dir)))

(defun picpocket-toggle-header ()
  "Toggle the display of the header line."
  (interactive)
  (picpocket-command
    (setq picpocket-header (not picpocket-header)
          header-line-format (when picpocket-header
                               picpocket-header-line-format))
    (force-mode-line-update)))


(defun picpocket-revert ()
  "Revert the current picpocket buffer.
Update the current list of pictures.
When called from Lisp return the new picpocket buffer."
  (interactive)
  (picpocket-command
    (picpocket-do-revert)))

(defun picpocket-do-revert ()
  (when (display-graphic-p)
    (clear-image-cache))
  ;; Selected-file is the second arg to all possible
  ;; picpocket-entry-functions.
  (apply picpocket-entry-function (append picpocket-entry-args
                                          (when picpocket-current
                                            (list (picpocket-absfile))))))

(defun picpocket-rename (dst)
  "Edit the filename of current picture.
If only the filename is changed the picture will stay as the
current picture.  But if it is moved to another directory it will
be removed from the picpocket list.
When called from Lisp DST is the new absolute filename."
  (interactive (list (progn
                       (picpocket-current-picture-check)
                       (when (boundp 'ido-read-file-name-non-ido)
                         (add-to-list 'ido-read-file-name-non-ido this-command))
                       (read-file-name "To: " nil (picpocket-file) nil
                                       (picpocket-file)))))
  (picpocket-command
    (picpocket-current-picture-check)
    (picpocket-action (if (file-directory-p dst)
                          'move
                        'rename)
                      dst)))


(defun picpocket-move (all dst)
  "Move current picture to another directory.
With prefix arg (ALL) move all pictures in the picpocket list.
The picture will also be removed from the picpocket list.
When called from Lisp DST is the destination directory."
  (interactive (picpocket-read-destination 'move))
  (picpocket-command
    (picpocket-action 'move dst all)))

(defun picpocket-copy (all dst)
  "Copy the current picture to another directory.
With prefix arg (ALL) copy all pictures in the current list.
When called from Lisp DST is the destination directory."
  (interactive (picpocket-read-destination 'copy))
  (picpocket-command
    (picpocket-action 'copy dst all)))

(defun picpocket-hardlink (all dst)
  "Make a hard link to the current picture in another directory.
With prefix arg (ALL) hard link all pictures in the current list.
When called from Lisp DST is the destination directory."
  (interactive (picpocket-read-destination 'hardlink))
  (picpocket-command
    (picpocket-action 'hardlink dst all)))

(defun picpocket-read-destination (action)
  (picpocket-current-picture-check)
  (list (when current-prefix-arg
          'all)
        (file-name-as-directory
         (read-directory-name (format "%s%s to: "
                                      (capitalize (symbol-name action))
                                      (if current-prefix-arg
                                          " all pictures"
                                        ""))
                              (picpocket-destination-dir)))))


(defun picpocket-destination-dir ()
  (if picpocket-destination-relative-current
      default-directory
    picpocket-destination-dir))

(defun picpocket-destination-dir-info ()
  (if picpocket-destination-relative-current
      "."
    picpocket-destination-dir))

(defun picpocket-move-by-keystroke (all)
  "Move the current picture.
The destination directory is determined by a keystroke that is
lookup up in the variable `picpocket-keystroke-alist'.
With prefix arg (ALL) move all pictures in the current list."
  (interactive "P")
  (picpocket-command
    (picpocket-file-by-keystroke-command 'move all)))

(defun picpocket-copy-by-keystroke (all)
  "Copy the current picture.
The destination directory is determined by a keystroke that is
lookup up in the variable `picpocket-keystroke-alist'.
With prefix arg (ALL) copy all pictures in the current list."
  (interactive "P")
  (picpocket-command
    (picpocket-file-by-keystroke-command 'copy all)))

(defun picpocket-hardlink-by-keystroke (all)
  "Make a hard link to the current picture.
The destination directory is determined by a keystroke that is
lookup up in the variable `picpocket-keystroke-alist'.
With prefix arg (ALL) hard link all pictures in the current list."
  (interactive "P")
  (picpocket-command
    (picpocket-file-by-keystroke-command 'hardlink all)))

(defun picpocket-file-by-keystroke-command (action all)
  (picpocket-current-picture-check)
  (let ((prompt (format "directory to %s%s to"
                        (symbol-name action)
                        (if all " all pictures" ""))))
    (picpocket-action action
                      (picpocket-read-key prompt)
                      (when all 'all))))


(defun picpocket-tag-by-keystroke (&optional all)
  "Add a tag to the current picture.
The tag is determined by a keystroke that is looked up in the
variable `picpocket-keystroke-alist'.

With prefix arg (ALL) the tag is added to all pictures in the
current list.  Type a minus sign (-) before the keystroke to
remove the tag from all pictures instead."
  (interactive "P")
  (picpocket-command
    (picpocket-current-picture-check)
    (pcase (picpocket-read-key-to-add-or-remove-tag nil all)
      (`(,remove ,tag)
       (picpocket-action (if remove 'remove-tag 'add-tag)
                         tag
                         (if all 'all))))))

(defun picpocket-edit-tags (&optional all tags-string)
  "Edit the tags associated with current picture.
To enter multiple tags separate them with spaces.

With prefix arg (ALL) enter a single tag and add it to all
pictures in the current list.  If TAGS-STRING begins with a minus
sign (-) then the tag is removed from all pictures instead."
  (interactive "P")
  (picpocket-command
    (if all
        (picpocket-tag-to-all (or tags-string
                                  (picpocket-read-tag-for-all)))
      (picpocket-current-picture-check)
      (let* ((old-tags (picpocket-tags))
             (old-tags-string (picpocket-tags-string-to-edit old-tags))
             (new-tags-string (or tags-string
                                  (picpocket-read-tags "Tags: "
                                                       old-tags-string)))
             (tags-to-add (cl-set-difference
                           (picpocket-tags-string-to-list new-tags-string)
                           old-tags))
             (hint (picpocket-key-hint tags-to-add)))
        (picpocket-action 'set-tags new-tags-string)
        (when hint
          (picpocket-tags-message picpocket-current hint))))))

(defun picpocket-key-hint (tags-to-add)
  (let ((hints (cl-loop for (key action arg) in (picpocket-keystroke-alist)
                        when (and (eq action 'tag)
                                  arg
                                  (memq (intern arg) tags-to-add))
                        collect (format "%s -> tag %s"
                                        (picpocket-key-description key)
                                        arg))))
    (when hints
      (format " (available keystrokes: %s)" (string-join hints " and ")))))

(defun picpocket-tags-message (pic &optional hint)
  (if (picpocket-tags pic)
      (message "Tags set to %s%s"
               (picpocket-format-tags (picpocket-tags pic))
               (or hint ""))
    (message "Tags cleared")))


(defun picpocket-read-tag-for-all ()
  (picpocket-read-tags "Type tag to add to all files (-tag to remove): "))

(defun picpocket-tag-to-all (tag-string)
  "Add a tag (TAG-STRING) to all pictures in current picpocket buffer.
If tag starts with minus remove tag instead of add."
  (cond ((string-match "\\`[:space:]*\\'" tag-string)
         (message "Empty string, no action"))
        ((not (eq 1 (length (split-string tag-string))))
         (message "Cannot handle more than one tag at a time"))
        ((eq (elt tag-string 0) ?-)
         (let ((tag (substring tag-string 1)))
           (picpocket-action 'remove-tag tag 'all)
           (message "Tag %s was removed from all" tag)))
        (t
         (picpocket-action 'add-tag tag-string 'all)
         (message "All tagged with %s" tag-string))))

(defun picpocket-read-tags (prompt &optional old-tags-string)
  (let ((string (minibuffer-with-setup-hook
                    (lambda ()
                      (setq-local completion-at-point-functions
                                  (list #'picpocket-tag-completion-at-point)))
                  (read-from-minibuffer prompt
                                        old-tags-string
                                        picpocket-minibuffer-map))))
    (dolist (tag (split-string string))
      (intern (string-remove-prefix "-" tag)
              picpocket-tag-completion-table))
    string))

(defun picpocket-tag-completion-at-point ()
  (list (save-excursion
          (skip-chars-backward "^ ")
          (skip-chars-forward "-")
          (point))
        (point)
        picpocket-tag-completion-table))

(defun picpocket-tags-string-to-edit (tags)
  (when tags
    (concat (mapconcat #'symbol-name tags " ") " ")))

(defun picpocket-set-filter (filter-string)
  "Enter the current picpocket filter.
The filter is a list of tags.  Only pictures with all the tags in
the filter is shown.  To enter multiple tags separate them with
spaces.

If `picpocket-consider-dir-as-tag' is non-nil also the
containing directory counts as a tag as far as the filter is
concerned.

When called from Lisp the argument FILTER-STRING is a
space-separated string."
  (interactive (list (picpocket-read-tags
                      "Show only pictures with these tags: ")))
  (picpocket-command
    (picpocket-do-set-filter (mapcar #'intern (split-string filter-string)))
    (if picpocket-filter
        (message "Filter is %s" (picpocket-format-tags picpocket-filter))
      (message "No filter"))))

(defun picpocket-do-set-filter (filter)
  (setq picpocket-filter filter)
  (picpocket-reset-filter-counters))

(defun picpocket-reset-filter-counters ()
  (picpocket-idle-f-restart #'picpocket-compute-filter-index)
  (picpocket-idle-f-restart #'picpocket-compute-filter-match-count))

(defun picpocket-filter-match-p (pic)
  (or (null picpocket-filter)
      (cl-subsetp (picpocket-remove-hyphens
                   picpocket-filter)
                  (picpocket-remove-hyphens
                   (picpocket-all-tags pic)))))

(defun picpocket-remove-hyphens (list-or-symbol)
  (cond ((not picpocket-filter-ignore-hyphens)
         list-or-symbol)
        ((consp list-or-symbol)
         (mapcar #'picpocket-remove-hyphens list-or-symbol))
        (t (let ((str (symbol-name list-or-symbol)))
             (if (string-match "[-_]" str)
                 (let ((chars (string-to-list str)))
                   (intern (apply #'string (delete ?- (delete ?_ chars)))))
               list-or-symbol)))))

(defun picpocket-all-tags (pic)
  (delete-dups (append (picpocket-tags pic)
                       (picpocket-dir-tags pic))))

(defun picpocket-dir-tags (&optional pic)
  (picpocket-files-dir-tags (picpocket-all-files pic)))

(defun picpocket-files-dir-tags (files)
  (when picpocket-consider-dir-as-tag
    (cl-set-difference
     (delete-dups (mapcar (lambda (file)
                            (intern
                             (file-name-nondirectory
                              (directory-file-name
                               (file-name-directory file)))))
                          files))
     (mapcar #'picpocket-ensure-symbol
             picpocket-dirs-not-considered-tags))))

(defun picpocket-ensure-symbol (string-or-symbol)
  (if (stringp string-or-symbol)
      (intern string-or-symbol)
    string-or-symbol))

(defun picpocket-no-file (&optional direction)
  (user-error (picpocket-join "No"
                              direction
                              "file"
                              (when picpocket-filter
                                (format "match filter %s" picpocket-filter)))))

(defun picpocket-set-filter-by-keystroke ()
  "Show only pictures having the tag in the current filter."
  (interactive)
  (picpocket-command
    (picpocket-set-filter (picpocket-read-key "filtering tag"))))


(defun picpocket-jump ()
  "Jump to picture specified by file-name or index number."
  (interactive)
  (picpocket-command
    (let ((nr-or-file-name (completing-read "Jump to index or file-name: "
                                            (picpocket-jump-completions))))
      (or (picpocket-jump-to-index nr-or-file-name)
          (picpocket-jump-to-file nr-or-file-name)))))


(defun picpocket-jump-completions ()
  (picpocket-collect-completions (if (picpocket-filter-match-count)
                                     #'picpocket-filter-match-p
                                   #'picpocket-true)))

(defun picpocket-collect-completions (predicate)
  (cl-loop for i from 1 to picpocket-list-length
           for pic on picpocket-list
           when (funcall predicate pic)
           append (list (number-to-string i) (picpocket-file pic))))

(defun picpocket-jump-to-index (string)
  (when (string-match "^[0-9]+$" string)
    (let ((index (string-to-number string)))
      (picpocket-when-let (pic (picpocket-pic-by-index index))
        (picpocket-set-pos (make-picpocket-pos :current pic
                                               :index index))
        t))))


(defun picpocket-pic-by-index (n)
  (and (< 0 n)
       (<= n picpocket-list-length)
       (cl-loop for pic on picpocket-list
                repeat (1- n)
                finally return pic)))

(defun picpocket-jump-to-file (file)
  (let ((pos-list (picpocket-pos-list-by-file file)))
    (cond ((null pos-list)
           (user-error "Picture not found (%s)" file))
          ((eq 1 (length pos-list))
           (picpocket-set-pos (car pos-list)))
          (t
           (let ((prompt (format "%s is available in %s directories.  Select: "
                                 file (length pos-list))))
             (picpocket-set-pos (picpocket-select-pos-by-dir pos-list
                                                             prompt))
             t)))))

(defun picpocket-pos-list-by-file (file)
  (cl-loop for pic on picpocket-list
           for index = 1 then (1+ index)
           when (equal (picpocket-file pic) file)
           collect (make-picpocket-pos :current pic
                                       :index index)))

(defun picpocket-select-pos-by-dir (pos-list prompt)
  (let* ((dirs (cl-loop for pos in pos-list
                        collect (picpocket-dir (picpocket-pos-current pos))))
         (dir (completing-read prompt dirs nil t)))
    (cl-loop for pos in pos-list
             when (equal dir (picpocket-dir (picpocket-pos-current pos)))
             return pos)))


(defun picpocket-gimp-open ()
  "Run gimp on the current picture."
  (interactive)
  (and picpocket-gimp-executable
       (not (file-name-absolute-p picpocket-gimp-executable))
       (setq picpocket-gimp-executable
             (executable-find picpocket-gimp-executable)))
  (picpocket-current-picture-check)
  (start-process picpocket-gimp-executable
                 nil
                 picpocket-gimp-executable
                 (picpocket-absfile)))

(defun picpocket-trim ()
  "Create a copy of picture with edges trimmed.

The trim removes border areas of single color.
The external tool convert is invoked.

The trimmed file will inherit the file-name of the original with
\".trim.\" appended before the extension.

To undo this command simply delete the trimmed file.  (There is
no explicit undo support in `picpocket-undo' for this command.)"
  (interactive)
  (picpocket-command
    (picpocket-current-picture-check)
    (let* ((file (picpocket-absfile))
           (trimmed-file (concat (file-name-sans-extension file)
                                 ".trim."
                                 (file-name-extension file)))
           (tags (picpocket-tags)))
      (when (file-exists-p trimmed-file)
        (unless (y-or-n-p (format "File %s exist.  Overwrite? "
                                  trimmed-file))
          (error "Abort")))
      (unless (zerop (call-process "convert" nil nil nil
                                   "-fuzz" "1%" "-trim" file trimmed-file))
        (error "Failed to trim"))
      (picpocket-list-insert-before-current (picpocket-make-pic
                                            trimmed-file))
      (picpocket-tags-set picpocket-current tags)
      (message "Trim ok"))))



;;; Scrolling and trolling

(defun picpocket-auto-scroll ()
  "Fit picture to one window edge and start continous scroll."
  (interactive)
  (unless picpocket-old-fit
    (setq picpocket-old-fit picpocket-fit))
  (picpocket-ensure-picpocket-buffer)
  (picpocket-current-picture-check)
  (setq picpocket-fit :x-and-y)
  (set-window-hscroll nil 0)
  (set-window-vscroll nil 0)
  (pcase (picpocket-size-param picpocket-current
                               (picpocket-current-window-size))
    (`(:width . ,_) (progn
                      (setq picpocket-fit :y)
                      (picpocket-update-main-buffer)
                      (picpocket-start-scroll-right)))
    (`(:height . ,_) (progn
                       (setq picpocket-fit :x)
                       (picpocket-update-main-buffer)
                       (picpocket-start-scroll-down)))))

(defun picpocket-stop-or-start-scroll ()
  "Pause or resume ongoing continous scroll."
  (interactive)
  (if picpocket-scroll-command
      (if (memq last-command '(picpocket-start-scroll-down
                               picpocket-start-scroll-up
                               picpocket-start-scroll-left
                               picpocket-start-scroll-right
                               picpocket-auto-scroll))
          (message "Pause")
        (setq this-command picpocket-scroll-command)
        (funcall picpocket-scroll-command))
    (message "Not currently scrolling")))


(defun picpocket-start-scroll-down ()
  "Start continuous scroll down.

Scroll can be paused with `picpocket-stop-or-start-scroll'.
Scroll will also stop if any other command is invoked."
  (interactive)
  (setq picpocket-scroll-command #'picpocket-start-scroll-down)
  (picpocket-vscroll 1 nil (picpocket-max-vscroll-pixels)))

(defun picpocket-start-scroll-up ()
  "Start continuous scroll up.

Scroll can be paused with `picpocket-stop-or-start-scroll'.
Scroll will also stop if any other command is invoked."
  (interactive)
  (setq picpocket-scroll-command #'picpocket-start-scroll-up)
  (picpocket-vscroll -1 0 nil))

(defun picpocket-vscroll (delta min max)
  (cl-loop for i = (window-vscroll nil t) then (+ i delta)
           do (set-window-vscroll nil i t)
           do (sit-for 0.002)
           until (and min (<= i min))
           until (and max (>= i max))
           until (input-pending-p))
  (unless (input-pending-p)
    (setq picpocket-scroll-command nil)))


(defun picpocket-start-scroll-left ()
  "Start continuous scroll to the left.

Scroll can be paused with `picpocket-stop-or-start-scroll'.
Scroll will also stop if any other command is invoked."
  (interactive)
  (setq picpocket-scroll-command #'picpocket-start-scroll-left)
  (picpocket-hscroll -1 0 nil))

(defun picpocket-start-scroll-right ()
  "Start continuous scroll to the right.

Scroll can be paused with `picpocket-stop-or-start-scroll'.
Scroll will also stop if any other command is invoked."
  (interactive)
  (setq picpocket-scroll-command #'picpocket-start-scroll-right)
  (picpocket-hscroll 1 nil (picpocket-max-hscroll-columns)))

(defun picpocket-hscroll (delta min max)
  (cl-loop for i = (window-hscroll nil) then (+ i delta)
           do (set-window-hscroll nil i)
           do (sit-for 0.033)
           until (and min (<= i min))
           until (and max (>= i max))
           until (input-pending-p))
  (unless (input-pending-p)
    (setq picpocket-scroll-command nil)))


(defun picpocket-scroll-up ()
  "Scroll `picpocket-scroll-pixels' pixels up."
  (interactive)
  (let ((vscroll (window-vscroll nil t)))
    (set-window-vscroll nil
                        (max 0
                             (- vscroll picpocket-scroll-pixels))
                        t)))

(defun picpocket-scroll-down ()
  "Scroll `picpocket-scroll-pixels' pixels down."
  (interactive)
  (let* ((vscroll (window-vscroll nil t))
         (scaled-y (cdr (picpocket-scaled-size)))
         (max-vscroll (- scaled-y (cdr (picpocket-current-window-size)))))
    (set-window-vscroll nil
                        (min max-vscroll
                             (+ vscroll picpocket-scroll-pixels))
                        t)))

(defun picpocket-scroll-some-up ()
  "Jump scroll up.

The length scrolled is the height of the picture multiplied with
`picpocket-scroll-factor'."
  (interactive)
  (let ((vscroll (window-vscroll nil t)))
    (set-window-vscroll nil
                        (max 0
                             (- vscroll (picpocket-some-pixels)))
                        t)))

(defun picpocket-scroll-some-down ()
  "Jump scroll down.

The length scrolled is the height of the picture multiplied with
`picpocket-scroll-factor'."
  (interactive)
  (let* ((vscroll (window-vscroll nil t))
         (max-vscroll (picpocket-max-vscroll-pixels)))
    (set-window-vscroll nil
                        (min max-vscroll
                             (+ vscroll (picpocket-some-pixels)))
                        t)))

(defun picpocket-scroll-to-top ()
  "Reset vertical scroll."
  (interactive)
  (set-window-vscroll nil 0 t))

(defun picpocket-scroll-to-bottom ()
  "Set vertical scroll to maximum."
  (interactive)
  (set-window-vscroll nil (picpocket-max-vscroll-pixels) t))


(defun picpocket-some-pixels ()
  (let ((scaled-y (cdr (picpocket-scaled-size))))
    (* scaled-y picpocket-scroll-factor)))

(defun picpocket-max-vscroll-pixels ()
  (let* ((scaled-y (cdr (picpocket-scaled-size))))
    (- scaled-y (cdr (picpocket-current-window-size)))))

(defun picpocket-scaled-size ()
  (pcase-let* ((`(,pic-x . ,pic-y) (picpocket-size-force)))
    (pcase (picpocket-size-param picpocket-current
                                 (picpocket-current-window-size))
      (`(:width . ,param-x) (cons (picpocket-scale param-x)
                                  (/ (* picpocket-scale param-x pic-y)
                                     (* 100 pic-x))))
      (`(:height . ,param-y) (cons (/ (* picpocket-scale param-y pic-x)
                                      (* 100 pic-y))
                                   (picpocket-scale param-y))))))


(defun picpocket-scroll-left ()
  "Scroll one column left."
  (interactive)
  (set-window-hscroll nil (1- (window-hscroll nil))))

(defun picpocket-scroll-right ()
  "Scroll one column right."
  (interactive)
  (let ((hscroll (window-hscroll nil))
        (max-cols (picpocket-max-hscroll-columns)))
    (set-window-hscroll nil (min max-cols
                                 (1+ hscroll)))))

(defun picpocket-scroll-some-left ()
  "Jump scroll to the left.

The length scrolled is the width of the picture multiplied with
`picpocket-scroll-factor'."
  (interactive)
  (set-window-hscroll nil (- (window-hscroll nil)
                             (picpocket-some-columns))))


(defun picpocket-scroll-some-right ()
  "Jump scroll to the right.

The length scrolled is the width of the picture multiplied with
`picpocket-scroll-factor'."
  (interactive)
  (pcase-let ((hscroll (window-hscroll nil))
              (`(,some-cols . ,max-cols) (picpocket-some-and-max-columns)))
    (set-window-hscroll nil (min max-cols
                                 (+ hscroll some-cols)))))

(defun picpocket-scroll-to-max-left ()
  "Reset horisontal scroll."
  (interactive)
  (set-window-hscroll nil 0))

(defun picpocket-scroll-to-max-right ()
  "Set horisontal scroll to maximum."
  (interactive)
  (set-window-hscroll nil (picpocket-max-hscroll-columns)))

(defun picpocket-some-columns ()
  (car (picpocket-some-and-max-columns)))

(defun picpocket-max-hscroll-columns ()
  (cdr (picpocket-some-and-max-columns)))

(defun picpocket-some-and-max-columns ()
  (let* ((scaled-x (car (picpocket-scaled-size)))
         (window-x (car (picpocket-current-window-size)))
         (window-cols (window-width))
         (pic-cols (/ (* scaled-x window-cols) window-x))
         (some-cols (round (* picpocket-scroll-factor pic-cols)))
         (max-cols (- pic-cols (window-width))))
    (cons some-cols max-cols)))


(defun picpocket-avoid-overscroll ()
  (when (frame-parameter nil 'window-system)
    (set-window-vscroll nil
                        (min (window-vscroll nil t)
                             (picpocket-max-vscroll-pixels))
                        t)
    (set-window-hscroll nil
                        (min (window-hscroll nil)
                             (picpocket-max-hscroll-columns)))))

(defun picpocket-reset ()
  (picpocket-reset-scroll)
  (picpocket-list-reset)
  (picpocket-idle-f-restart-all))

(defun picpocket-set-pos (pos)
  (picpocket-reset-scroll)
  (picpocket-list-set-pos pos))

(defun picpocket-reset-scroll ()
  (set-window-vscroll nil 0 t)
  (set-window-hscroll nil 0)
  (setq picpocket-scroll-command nil)
  (when picpocket-old-fit
    (setq picpocket-fit picpocket-old-fit)
    (setq picpocket-old-fit nil)))



;;; Pic double-linked list functions

;; These will call tag handling functions.

(defun picpocket-absfile (&optional pic)
  (unless pic
    (setq pic picpocket-current))
  (concat (picpocket-dir pic) (picpocket-file pic)))

(defun picpocket-set-absfile (pic absfile)
  (picpocket-set-file pic (file-name-nondirectory absfile))
  (picpocket-set-dir pic (file-name-directory absfile)))

(defun picpocket-make-pic (absfile)
  (make-picpocket-pic :dir (file-truename (file-name-directory absfile))
                      :file (file-name-nondirectory absfile)))

(defun picpocket-list-reset ()
  (setq picpocket-list nil
        picpocket-list-length 0)
  (picpocket-list-set-pos (make-picpocket-pos)))

(defun picpocket-list-set-pos (pos)
  (let ((inhibit-quit t))
    (setq picpocket-current (picpocket-pos-current pos))
    (setq picpocket-index (or (picpocket-pos-index pos)
                              (picpocket-calculate-index picpocket-current)))
    (picpocket-set-filter-index (picpocket-pos-filter-index pos))
    (unless (picpocket-filter-index)
      (picpocket-idle-f-restart #'picpocket-compute-filter-index))))

(defun picpocket-list-search (absfile)
  (cl-loop for pic on picpocket-list
           when (equal absfile (picpocket-absfile pic))
           return pic))

(defun picpocket-calculate-index (&optional current)
  (cl-loop for pic on picpocket-list
           count 1
           until (eq pic (or current picpocket-current))))

(defun picpocket-list-delete (&optional pic filter-match-cell)
  (setq pic (or pic
                picpocket-current))
  (let ((filter-match (if filter-match-cell
                          (car filter-match-cell)
                        (picpocket-filter-match-p pic))))
    (clear-image-cache (picpocket-absfile pic))
    (setq picpocket-list-length (1- picpocket-list-length))
    (if (picpocket-prev pic)
        (setcdr (picpocket-prev pic) (cdr pic))
      (setq picpocket-list (cdr pic)))
    (if (cdr pic)
        (progn
          (picpocket-set-prev (cdr pic) (picpocket-prev pic))
          (when (eq picpocket-current pic)
            (picpocket-set-pos
             (make-picpocket-pos :current (cdr pic)
                                 :index picpocket-index))))
      (if (picpocket-prev pic)
          (when (eq picpocket-current pic)
            (picpocket-set-pos
             (make-picpocket-pos :current (picpocket-prev pic)
                                 :index (1- picpocket-index))))
        (picpocket-reset)))
    ;; The updating of filter count variables assumes that it is the
    ;; current picture that is deleted.
    (picpocket-idle-f-restart-all-unfinished)
    (when (and picpocket-filter
               filter-match)
      (when (picpocket-filter-match-count)
        (picpocket-set-filter-match-count (1- (picpocket-filter-match-count)))
        ;; If it was the last matching pic that was deleted filter
        ;; index should drop by one (to the value of
        ;; picpocket-filter-match-count).
        (when (picpocket-filter-index)
          (picpocket-set-filter-index (min (picpocket-filter-index)
                                           (picpocket-filter-match-count))))))))


(defun picpocket-list-insert-after-current (p)
  "Insert P after current pic and make P current."
  (let ((inhibit-quit t)
        (prev picpocket-current)
        (next (cdr picpocket-current)))
    (setq picpocket-list-length (1+ picpocket-list-length))
    (setf (picpocket-pic-prev p) prev)
    (picpocket-set-pos (make-picpocket-pos :current (cons p next)
                                           :index (1+ picpocket-index)))
    (if prev
        (setcdr prev picpocket-current)
      (setq picpocket-list picpocket-current))
    (when next
      (picpocket-set-prev next picpocket-current))
    (picpocket-idle-f-restart-all-filter-related)))

(defun picpocket-list-insert-before-current (p)
  "Insert P before current pic and make P current."
  (let ((inhibit-quit t)
        (prev (and picpocket-current
                   (picpocket-prev picpocket-current)))
        (next picpocket-current))
    (setq picpocket-list-length (1+ picpocket-list-length))
    (setf (picpocket-pic-prev p) prev)
    (picpocket-set-pos (make-picpocket-pos :current (cons p next)
                                           :index (max 1 picpocket-index)))
    (if prev
        (setcdr prev picpocket-current)
      (setq picpocket-list picpocket-current))
    (when next
      (picpocket-set-prev next picpocket-current))
    (picpocket-idle-f-restart-all-filter-related)))


(defun picpocket-create-picpocket-list (files &optional selected-file)
  (picpocket-reset)
  (setq picpocket-list
        (cl-loop for absfile in files
                 if (file-exists-p absfile)
                 collect (picpocket-make-pic absfile)
                 else do (message "%s do not exist" absfile)))
  (cl-loop for pic on picpocket-list
           with prev = nil
           do (picpocket-set-prev pic prev)
           do (setq prev pic))
  (setq picpocket-list-length (length picpocket-list))
  (picpocket-set-pos (or (and selected-file
                              (picpocket-picture-file-p selected-file t)
                              (cl-loop for pic on picpocket-list
                                       for index = 1 then (1+ index)
                                       when (equal selected-file
                                                   (picpocket-absfile pic))
                                       return (make-picpocket-pos
                                               :current pic
                                               :index index)))
                         (make-picpocket-pos :current picpocket-list
                                             :index 1))))

(defun picpocket-picture-file-p (file &optional verbose)
  (let ((case-fold-search t))
    (cond ((not (file-regular-p file))
           (when verbose
             (message "Skipping %s which is not a regular file" file))
           nil)
          ((null (picpocket-picture-regexp))
           (error "No image support in this Emacs build"))
          ((not (string-match (picpocket-picture-regexp) file))
           (when verbose
             (message "Skipping %s which is not a picture file" file))
           nil)
          (t t))))

(defvar picpocket-done-dirs nil)
(defvar picpocket-file-count 0)

(defun picpocket-file-list (dir)
  (let ((picpocket-file-count 0)
        (picpocket-done-dirs nil))
    (prog1
        (picpocket-file-list2 (directory-file-name (file-truename dir)))
      (message "Found %s pictures" picpocket-file-count))))


(defun picpocket-file-list2 (dir)
  (picpocket-file-list-debug "dir %s" dir)
  (push dir picpocket-done-dirs)
  (condition-case err
      ;; Do not descend into dot directories.
      (let ((files (picpocket-sort-files (directory-files dir nil "^[^.]" t)))
            absfile pic-files sub-files subdirs)
        (picpocket-file-list-debug "  files %s" files)
        (dolist (file files)
          (setq absfile (expand-file-name file dir))
          (if (file-directory-p absfile)
              (push absfile subdirs)
            (when (picpocket-picture-file-p absfile)
              (push absfile pic-files)
              (when (zerop (% (cl-incf picpocket-file-count) 100))
                (message "Found %s pictures so far%s"
                         picpocket-file-count
                         (if picpocket-recursive
                             (format " (at %s)" dir)
                           ""))))))
        (setq pic-files (nreverse pic-files))
        (when picpocket-recursive
          (dolist (subdir subdirs)
            (picpocket-file-list-debug "  subdir %s" subdir)
            (picpocket-file-list-debug "         %s" (expand-file-name subdir))
            (picpocket-file-list-debug "    from %s" dir)
            (when (or picpocket-follow-symlinks
                      (not (file-symlink-p subdir)))
              (let ((true-subdir (directory-file-name
                                  (file-truename subdir))))
                (unless (or (picpocket-dot-file-p subdir)
                            ;; Do not follow links to the root.
                            (string-equal "/" true-subdir)
                            (member true-subdir picpocket-done-dirs))
                  (setq sub-files (append (picpocket-file-list2 true-subdir)
                                          sub-files)))))))
        (append pic-files sub-files))
    (file-error (progn
                  (warn "Failed to access %s (%s)" dir err)
                  nil))))

(defvar picpocket-file-list-debug nil)
(defun picpocket-file-list-debug (format &rest args)
  (when picpocket-file-list-debug
    (apply #'message format args)))



(defun picpocket-sort-files (files)
  (sort files #'picpocket-file-name-lessp))

;; PENDING Replace picpocket-file-name-lessp with string-version-lessp
;; when Emacs 26 is mainstream.
(defun picpocket-file-name-lessp (a b)
  (cond ((and (equal "" a)
              (not (equal "" b)))
         t)
        ((equal "" b)
         nil)
        ((and (picpocket-string-start-with-number-p a)
              (picpocket-string-start-with-number-p b))
         (pcase-let ((`(,a-number . ,a-rest) (picpocket-parse-number a))
                     (`(,b-number . ,b-rest) (picpocket-parse-number b)))
           (if (= a-number b-number)
               (picpocket-file-name-lessp a-rest b-rest)
             (< a-number b-number))))
        (t (let ((a-char (aref a 0))
                 (b-char (aref b 0)))
             (if (= a-char b-char)
                 (picpocket-file-name-lessp (substring a 1) (substring b 1))
               (< a-char b-char))))))

(defun picpocket-parse-number (string)
  (picpocket-do-parse-number string ""))

(defun picpocket-do-parse-number (string acc)
  (if (picpocket-string-start-with-number-p string)
      (picpocket-do-parse-number (substring string 1)
                                 (concat acc (substring string 0 1)))
    (cons (string-to-number acc) string)))

(defun picpocket-string-start-with-number-p (s)
  (unless (zerop (length s))
    (picpocket-char-is-number-p (aref s 0))))

(defun picpocket-char-is-number-p (c)
  (and (>= c ?0)
       (<= c ?9)))

(defun picpocket-dot-file-p (file)
  "Return t if the FILE's name start with a dot."
  (eq (elt (file-name-nondirectory file) 0) ?.))



;;; Tag database interface functions

;; This layer translates from struct picpocket-pic to a sha1 checksum.
;; This checksum is refered to as sha and is used as index in the
;; database below.

(defun picpocket-tags (&optional pic)
  (picpocket-tags-by-sha pic))

(defun picpocket-tags-by-sha (&optional pic)
  (unless (zerop (picpocket-db-count))
    (picpocket-db-tags (picpocket-sha-force pic))))

(defun picpocket-all-files (&optional pic)
  (or (unless (zerop (picpocket-db-count))
        (picpocket-db-files (picpocket-sha-force pic)))

      (list (picpocket-absfile pic))))


(defun picpocket-tags-set (pic new-tags)
  (let ((match-before (picpocket-filter-match-p pic)))
    (picpocket-db-tags-set (picpocket-sha-force pic)
                           (picpocket-absfile pic)
                           new-tags)
    (let ((match-after (picpocket-filter-match-p pic)))
      (when (picpocket-xor match-before match-after)
        (picpocket-idle-f-restart #'picpocket-compute-filter-index)
        (if (picpocket-filter-match-count)
            (picpocket-set-filter-match-count (+ (picpocket-filter-match-count)
                                                 (if match-after 1 -1)))
          (picpocket-idle-f-restart #'picpocket-compute-filter-match-count))))))

(defun picpocket-xor (a b)
  (not (eq (not a) (not b))))


(defun picpocket-tags-move-file (pic old-file new-file)
  (picpocket-db-tags-move-file (picpocket-sha-force pic) old-file new-file))

(defun picpocket-tags-copy-file (pic new-file)
  (picpocket-db-tags-copy-file (picpocket-sha-force pic) new-file))

(defun picpocket-tags-delete-file (pic deleted-file)
  (picpocket-db-tags-delete-file (picpocket-sha-force pic) deleted-file))


(defun picpocket-sha-force (pic)
  "Return the sha1 checksum of PIC.
The checksum will be computed if not already available.
Also, if there is a matching entry in the database with tags
then the file of PIC will be added to that entry."
  (or (picpocket-sha pic)
      (picpocket-save-sha-in-pic-and-db pic)))


(defun picpocket-save-sha-in-pic-and-db (pic)
  (let* ((file (picpocket-absfile pic))
         (sha (picpocket-sha1sum file))
         (inhibit-quit t))
    (picpocket-set-sha pic sha)
    (picpocket-db-tags-add-file sha file)
    sha))


(defun picpocket-sha1sum (file)
  (if (or picpocket-sha1sum-executable
          (setq picpocket-sha1sum-executable (executable-find "sha1sum")))
      (with-temp-buffer
        (unless (zerop (call-process picpocket-sha1sum-executable
                                     nil t nil file))
          (error "Failed to compute sha for %s" file))
        (goto-char (point-min))
        (skip-chars-forward "0-9a-f")
        (unless (eq (point) 41)
          (error "Unrecognized output from sha1sum for %s" file))
        (buffer-substring (point-min) (point)))
    (with-temp-buffer
      (insert-file-contents-literally file)
      (sha1 (current-buffer)))))

;;; Tag database internal functions

;; This layer translates from sha to data.  This layer knows about the
;; representation of the database entries.  The database maps from sha
;; to a plist with the following keys:
;;
;; :files - list of truename file-names with this sha.
;; :tags - list of tag symbols.
;;

(defmacro picpocket-with-db (sha var-list &rest body)
  "Convenience macro for tag database access.
SHA is the sha1sum of the picture to lookup.  VAR-LIST contains
one or more of the symbols plist, tags and files.  BODY will be
evaluated with the symbols in VAR-LIST bound to their values in
the database for the given SHA."
  (declare (indent 2)
           (debug (form form body)))
  (let ((invalid (cl-set-difference var-list '(plist files tags))))
    (when invalid
      (error "Invalid symbols in picpocket-with-db var-list: %s"
             invalid)))
  `(let* ((plist (picpocket-db-get ,sha))
          ,(if (memq 'files var-list)
               '(files (plist-get plist :files))
             'ignored)
          ,(if (memq 'tags var-list)
               '(tags (plist-get plist :tags))
             'ignored))
     ,@body))

(defun picpocket-db-tags (sha)
  (picpocket-with-db sha (tags)
    tags))

(defun picpocket-db-files (sha)
  (picpocket-with-db sha (files)
    files))

(defun picpocket-db-tags-add-file (sha file)
  (picpocket-with-db sha (plist files tags)
    (when tags
      (unless (member file files)
        (setq plist (plist-put plist :files (cons file files)))
        (picpocket-db-put sha plist)))))

(defun picpocket-db-tags-set (sha file new-tags)
  (picpocket-with-db sha (plist files)
    (if new-tags
        (picpocket-db-put sha (list :files (picpocket-add-to-list file files)
                                    :tags new-tags))
      (when plist
        (picpocket-db-remove sha)))))

(defun picpocket-add-to-list (element list)
  (cl-adjoin element list :test 'equal))

(defun picpocket-db-tags-move-file (sha old-file new-file)
  (picpocket-with-db sha (plist files)
    (when plist
      (let ((new-files (picpocket-add-to-list new-file
                                              (delete old-file files))))
        (picpocket-db-put sha (plist-put plist :files new-files))))))

(defun picpocket-db-tags-copy-file (sha new-file)
  (picpocket-with-db sha (plist files)
    (when plist
      (unless (member new-file files)
        (picpocket-db-put sha
                          (plist-put plist :files (cons new-file files)))))))

(defun picpocket-db-tags-delete-file (sha deleted-file)
  (picpocket-with-db sha (plist files)
    (when plist
      (let ((new-files (delete deleted-file files)))
        (if new-files
            (picpocket-db-put sha (plist-put plist :files new-files))
          (picpocket-db-remove sha))))))







;;; List modes


;; PENDING user defined commands...
;; make them work in list buffers as well...
;; (or at least not show help for them...)


(defvar picpocket-list-commands nil
  "The documentation for functions is not known at compile time.
Therefore save a list of these command and copy documentation in
the end of this file.")

(defmacro picpocket-list-command (f)
  "Wrapper for picpocket commands to work from list modes.

F is the picpocket command."
  (let ((list-f (intern (concat (symbol-name f) "-in-list"))))
    `(progn
       (push #',f picpocket-list-commands)
       (defun ,list-f ()
         ,(if (symbol-function f)
              (documentation f t)
            (concat "Like `" (symbol-name f) "' in list modes."))
         (interactive)
         (let ((entry-f picpocket-list-entry-function))
           (with-current-buffer picpocket-buffer
             (call-interactively #',f)
             (funcall entry-f)))))))

(defmacro picpocket-list-file-command (f)
  "Wrapper for picpocket file commands to work from list modes.

F is the picpocket command."
  (let ((list-f (intern (concat (symbol-name f) "-in-list"))))
    `(progn
       (push #',f picpocket-list-commands)
       (defun ,list-f ()
         ,(if (symbol-function f)
              (documentation f t)
            (concat "Like `" (symbol-name f) "' in list modes."))
         (interactive)
         (let ((absfile (tabulated-list-get-id))
               (entry-f picpocket-list-entry-function))
           (unless absfile
             (error "No file on this line"))
           (unless (file-exists-p absfile)
             (error "File %s not found" absfile))
           (with-current-buffer picpocket-buffer
             (picpocket-jump-to-absfile absfile)
             (call-interactively #',f)
             (funcall entry-f)))))))

(define-derived-mode picpocket-tab-mode tabulated-list-mode
  "picpocket-tab"
  "Base mode for picpocket modes derived from tabulated-list-mode.

\\{picpocket-tab-mode-map}"
  nil)

(define-derived-mode picpocket-list-mode picpocket-tab-mode
  "picpocket-list"
  "Major mode for listing the pictures in a picpocket buffer.

\\{picpocket-list-mode-map}"
  (add-hook 'tabulated-list-revert-hook #'picpocket-list-refresh nil t))

(define-derived-mode picpocket-list-tags-mode picpocket-tab-mode
  "picpocket-list-tags"
  "Major mode for listing the tags in the picpocket database.

\\{picpocket-list-tags-mode-map}"
  (add-hook 'tabulated-list-revert-hook #'picpocket-list-tags-refresh nil t))

(define-derived-mode picpocket-list-identical-files-mode picpocket-tab-mode
  "picpocket-list-identical-files"
  "Major mode for listing identical files according to picpocket database.

\\{picpocket-list-identical-files-mode-map}"
  (add-hook 'tabulated-list-revert-hook #'picpocket-list-identical-files-refresh
            nil t))

(let ((map (make-sparse-keymap)))
  (set-keymap-parent map tabulated-list-mode-map)
  (define-key map [?\ ] #'next-line)
  (define-key map [backspace] #'previous-line)
  (define-key map [tab] picpocket-base-toggle-map)
  (define-key map [?u] #'picpocket-undo)
  (define-key map [(meta ?u)] #'picpocket-visit-undo-list)
  (define-key map [??] #'picpocket-help)
  (define-key map [?d] #'picpocket-dired)
  (define-key map [?e] #'picpocket-edit-keystrokes)
  (define-key map [?.] #'picpocket-dired-up-directory)
  (define-key map [?=] #'picpocket-larger-thumbnails)
  (define-key map [?+] #'picpocket-larger-thumbnails)
  (define-key map [?-] #'picpocket-smaller-thumbnails)
  (define-key map [?l ?l] #'picpocket-list-current-list)
  (define-key map [?l ?t] #'picpocket-list-current-by-tags)
  (define-key map [?l ?T] #'picpocket-list-all-tags)
  (define-key map [?l ?n] #'picpocket-list-current-list-with-thumbnails)
  ;; PENDING
  ;; Commands for splitting window for picpocket and list buffers.
  ;; Make n and p in list buffer update picpocket buffer.
  ;; (define-key map [?l ?b ?l] #'picpocket-list-current-list-below)
  ;; (define-key map [?l ?b ?t] #'picpocket-list-current-by-tags-below)
  ;; (define-key map [?l ?b ?T] #'picpocket-list-all-tags-below)
  ;; (define-key map [?l ?r ?l] #'picpocket-list-current-list-right)
  ;; (define-key map [?l ?r ?t] #'picpocket-list-current-by-tags-right)
  ;; (define-key map [?l ?r ?T] #'picpocket-list-all-tags-right)
  ;; PENDING
  ;; (define-key map [?b ?n] #'picpocket-sort-by-number-of-files)
  ;; (define-key map [?b ?t] #'picpocket-sort-by-tags)
  ;; (define-key map [?b ?s] #'picpocket-sort-by-score)
  ;; (define-key map [?b ?r] #'picpocket-reverse-sort-order)
  (setq picpocket-tab-mode-map map))

(defvar picpocket-list-toggle-map
  (let ((map (make-sparse-keymap)))
    ;; (let ((map (copy-keymap picpocket-base-toggle-map)))
    (set-keymap-parent map picpocket-base-toggle-map)
    (define-key map [?r] (picpocket-list-command
                          picpocket-toggle-recursive))
    (define-key map [?l] (picpocket-list-command
                          picpocket-toggle-follow-symlinks))
    (define-key map [?t] (picpocket-list-command
                          picpocket-toggle-dir-tags))
    map))

(let ((map (make-sparse-keymap)))
  (set-keymap-parent map picpocket-tab-mode-map)
  (define-key map [return] #'picpocket-list-enter)
  (define-key map [tab] picpocket-list-toggle-map)
  ;; PENDING
  ;; (define-key map [?b ?f] #'picpocket-sort-by-file-name)
  ;; (define-key map [?b ?k] #'picpocket-sort-by-kilo-byte)
  (define-key map [?v] #'picpocket-visit-file)
  (define-key map [?s] #'picpocket-list-slide-show)
  (let ((kill (picpocket-list-file-command picpocket-delete-file)))
    (define-key map [?k] kill)
    (define-key map [deletechar] kill))
  (define-key map [?r] (picpocket-list-file-command picpocket-rename))
  (define-key map [?m] (picpocket-list-file-command picpocket-move))
  (define-key map [?c] (picpocket-list-file-command picpocket-copy))
  (define-key map [?h] (picpocket-list-file-command picpocket-hardlink))
  (define-key map [(meta ?m)] (picpocket-list-file-command
                               picpocket-move-by-keystroke))
  (define-key map [(meta ?c)] (picpocket-list-file-command
                               picpocket-copy-by-keystroke))
  (define-key map [(meta ?l)] (picpocket-list-file-command
                               picpocket-hardlink-by-keystroke))
  (define-key map [(meta ?t)] (picpocket-list-file-command
                               picpocket-tag-by-keystroke))
  (define-key map [?t] (picpocket-list-file-command picpocket-edit-tags))
  (define-key map [?z] (picpocket-list-file-command picpocket-repeat))
  (define-key map [?f] (picpocket-list-command picpocket-set-filter))
  (define-key map [(meta ?f)] (picpocket-list-command
                               picpocket-set-filter-by-keystroke))
  (define-key map [?j] (picpocket-list-command picpocket-jump))
  (define-key map [?x ?g] (picpocket-list-file-command picpocket-gimp-open))
  (define-key map [?x ?t] (picpocket-list-file-command picpocket-trim))
  (define-key map [?x ?b] (picpocket-list-file-command picpocket-set-backdrop))
  (define-key map [?l ?i] #'picpocket-list-identical-files)
  (setq picpocket-list-mode-map map))

(let ((map (make-sparse-keymap)))
  (set-keymap-parent map picpocket-tab-mode-map)
  (define-key map [return] #'picpocket-select-files-with-tag)
  (setq picpocket-list-tags-mode-map map))

;; PENDING
;; picpocket-list-file-command to identical files modes as well...?
;; maybe common parent mode...
;; Or maybe get rid of identical files mode altogether instead...?

(let ((map (make-sparse-keymap)))
  (set-keymap-parent map picpocket-tab-mode-map)
  (define-key map [return] #'picpocket-select-identical-files)
  (define-key map [?k] #'picpocket-delete-identical-file)
  (define-key map [?b ?n] nil)
  (setq picpocket-list-identical-files-mode-map map))


;;; List mode

(defun picpocket-list-current-list ()
  "Switch to a buffer listing the pictures currently in the picpocket list."
  (interactive)
  (let ((absfile (cl-case major-mode
                   (picpocket-mode
                    (picpocket-absfile))
                   (picpocket-list-mode
                    (tabulated-list-get-id))
                   (t
                    nil))))
    (picpocket-with-singleton-buffer picpocket-list-buffer
      (picpocket-list-mode)
      (setq-local picpocket-list-entry-function #'picpocket-list-current-list)
      (tabulated-list-revert)
      (when absfile
        (picpocket-list-goto-absfile absfile)))))

(defun picpocket-list-current-list-with-thumbnails ()
  "Switch to a buffer listing the pictures currently in the picpocket list.

Enables thumbnails pictures.  Thumbnails can also be toggled with
\\[picpocket-toggle-thumbnails] (bound to
`picpocket-toggle-thumbnails)."
  (interactive)
  (setq picpocket-list-thumbnails t)
  (picpocket-list-current-list))

(defun picpocket-list-goto-absfile (absfile)
  (goto-char (point-min))
  (while (and (not (equal (tabulated-list-get-id) absfile))
              (not (eobp)))
    (forward-line 1))
  (unless (equal (tabulated-list-get-id) absfile)
    (goto-char (point-min))))


(defun picpocket-list-refresh ()
  (setq-local tabulated-list-format
              (vector (list "Index" 5 t)
                      (if picpocket-list-thumbnails
                          (list "Image" 22 t)
                        (list "" 0 t))
                      (list "Filename" 24 t)
                      (list "Size" 8 (picpocket-tab-lesser-f 2))
                      (list "Score" 3 (picpocket-tab-lesser-f 3))
                      (list "Tags" 24 t)
                      (list "Dir-Tags" 24 t)
                      (list "Identical-Files" 5 (picpocket-tab-lesser-f 6))
                      (list "Directory" 32 t)))
  (setq tabulated-list-entries
        (cl-loop for pic on picpocket-list
                 for i = 1 then (1+ i)
                 when (picpocket-filter-match-p pic)
                 collect (list (picpocket-absfile pic)
                               (vector (number-to-string i)
                                       (picpocket-list-thumbnail pic)
                                       (propertize (picpocket-file pic)
                                                   'font-lock-face
                                                   'picpocket-list-main-field)
                                       (picpocket-kb
                                        (picpocket-bytes-force pic))
                                       (picpocket-score-string pic)
                                       (picpocket-tags-string pic)
                                       (picpocket-dir-tags-string pic)
                                       (number-to-string
                                        (length (picpocket-all-files pic)))
                                       (picpocket-dir pic)))))
  (picpocket-adapt-column-width)
  (tabulated-list-init-header))

(defun picpocket-list-thumbnail (pic)
  (let ((file (picpocket-absfile pic)))
    (if (and picpocket-list-thumbnails
             (display-images-p)
             (file-exists-p file))
        (let ((max-width (* 2 (picpocket-thumbnail-pixels))))
          (concat (propertize " "
                              'display
                              (picpocket-create-thumbnail
                               file
                               ;; PENDING - For some reason the
                               ;; thumbnails do not show in the undo
                               ;; buffer in Emacs 26 and earlier if
                               ;; :margin and :max-width are given.
                               ;; It does not seem to be a problem
                               ;; here in list mode.
                               :margin picpocket-thumbnail-margin
                               :max-width max-width))
                  (propertize " "
                              'display
                              (cons 'space (list :align-to 27)))))
      "")))

(defun picpocket-create-thumbnail (file &rest args)
  (apply #'create-image
         file
         (picpocket-image-type file)
         nil
         :height (picpocket-thumbnail-pixels)
         args))

(defun picpocket-thumbnail-pixels ()
   (* picpocket-thumbnail-size (frame-char-height)))

(defun picpocket-larger-thumbnails ()
  "Enlarge the thumbnails."
  (interactive)
  (setq picpocket-thumbnail-size
        (1+ (round (* 1.1 picpocket-thumbnail-size))))
  (message "Thumbnail size is %s" picpocket-thumbnail-size)
  (funcall picpocket-list-entry-function))

(defun picpocket-smaller-thumbnails ()
  "Enlarge the thumbnails."
  (interactive)
  (setq picpocket-thumbnail-size
        (max 1 (1- (round (* 0.9 picpocket-thumbnail-size)))))
  (message "Thumbnail size is %s" picpocket-thumbnail-size)
  (funcall picpocket-list-entry-function))


;;; List tags mode

(defun picpocket-list-current-by-tags ()
  "Switch to a buffer listing the tags of the current picpocket pictures."
  (interactive)
  (picpocket-with-singleton-buffer picpocket-list-buffer
    (picpocket-list-tags-mode)
    (setq-local picpocket-list-entry-function #'picpocket-list-current-by-tags)
    (setq-local picpocket-list-pic-list picpocket-list)
    (picpocket-list-tags-refresh)
    (tabulated-list-sort 0)))

(defun picpocket-tab-lesser-f (field)
  (lambda (a b)
    (picpocket-file-name-lessp (elt (cadr a) field)
                               (elt (cadr b) field))))

(defun picpocket-list-tags-refresh ()
  (unless (fboundp 'alist-get)
    (error "Not supported before Emacs 25.1"))
  (setq-local tabulated-list-format (vector (list "Tag" 20 t)
                                            (list "Count" 5
                                                  (picpocket-tab-lesser-f 1))
                                            (list "Max Score" 5
                                                  (picpocket-tab-lesser-f 2))))
  (let (nr-alist score-alist)
    (if picpocket-list-pic-list
        (cl-loop for pic on picpocket-list-pic-list
                 do (dolist (tag (picpocket-tags pic))
                      (cl-incf (alist-get tag nr-alist 0))
                      (setf (alist-get tag score-alist)
                            (max (alist-get tag score-alist 0)
                                 (picpocket-score pic)))))
      (picpocket-db-mapc
       (lambda (_sha plist)
         (let* ((tags (picpocket-tag-plist-all-tags plist))
                (max-score (picpocket-symbol-max tags)))
           (dolist (tag tags)
             (cl-incf (alist-get tag nr-alist 0))
             (setf (alist-get tag score-alist)
                   (max (alist-get tag score-alist 0) max-score)))))))
    (setq tabulated-list-entries
          (cl-loop for (tag . nr) in nr-alist
                   collect (list tag
                                 (vector (propertize (symbol-name tag)
                                                     'font-lock-face
                                                     'picpocket-list-main-field)
                                         (number-to-string nr)
                                         (picpocket-field
                                          (alist-get
                                           tag score-alist)))))))
  (picpocket-adapt-column-width)
  (tabulated-list-init-header))

(defun picpocket-tag-plist-all-tags (plist)
  (let ((tags (plist-get plist :tags))
        (files (plist-get plist :files)))
    (delete-dups (append (picpocket-files-dir-tags files)
                         tags))))

(defun picpocket-field (x)
  (cond ((stringp x)
         x)
        ((numberp x)
         (number-to-string x))
        ((null x)
         "-")))

(defun picpocket-list-slide-show ()
  "Start slide-show from current picture."
  (interactive)
  (let ((absfile (tabulated-list-get-id)))
    (switch-to-buffer picpocket-buffer)
    (with-current-buffer picpocket-buffer
      (picpocket-jump-to-absfile absfile)
      (picpocket-update-main-buffer)
      (sit-for picpocket-slide-show-delay)
      (picpocket-slide-show))))

(defun picpocket-jump-to-absfile (absfile)
  (let ((pos-list (picpocket-first-pos-by-absfile absfile)))
    (unless pos-list
      (error "Picture not found (%s)" absfile))
    (picpocket-set-pos pos-list)))

(defun picpocket-first-pos-by-absfile (absfile)
  (cl-loop for pic on picpocket-list
           for index = 1 then (1+ index)
           when (equal (picpocket-absfile pic) absfile)
           return (make-picpocket-pos :current pic
                                      :index index)))

(defun picpocket-sort-by-number-of-files ()
  "Sort list by the number of files."
  (interactive)
  ;; PENDING
  ;; (if (eq major-mode 'picpocket-mode)
  ;; (set sort function and revert...)
  (setq tabulated-list-sort-key
        (cons (if (eq major-mode 'picpocket-list-mode)
                  "Identical-Files"
                "Count")
              ;; t here means flip -> higher numbers first
              t))
  (tabulated-list-init-header)
  (tabulated-list-print t))

(defun picpocket-reverse-sort-order ()
  "Flip the sort order."
  (interactive)
  (if (eq major-mode 'picpocket-mode)
      t
    (setcdr tabulated-list-sort-key (not (cdr tabulated-list-sort-key)))
    (tabulated-list-init-header)
    (tabulated-list-print t)))

(defun picpocket-tab-col-index (column-name)
  (1- (cl-loop for (name . _) across tabulated-list-format
               count 1
               until (string-equal name column-name))))

(defun picpocket-list-enter ()
  "Go back to picpocket buffer."
  (interactive)
  (picpocket-files (cl-loop for (absfile _) in tabulated-list-entries
                            collect absfile)
                   (tabulated-list-get-id)))

(defun picpocket-select-files-with-tag ()
  "Switch to picpocket buffer with pictures tagged with current tag."
  (interactive)
  (let ((tag (tabulated-list-get-id)))
    (picpocket-files (if picpocket-list-pic-list
                         (cl-loop for pic on picpocket-list-pic-list
                                  when (memq tag (picpocket-tags pic))
                                  collect (picpocket-absfile pic))
                       (let (files)
                         (picpocket-db-mapc
                          (lambda (_sha plist)
                            (let ((tags (picpocket-tag-plist-all-tags plist))
                                  (file (car (plist-get plist :files))))
                              (when (memq tag tags)
                                (cl-pushnew file files)))))
                         files)))))

(defun picpocket-select-identical-files ()
  "Switch to picpocket buffer with the listed identical pictures."
  (interactive)
  (picpocket-files (picpocket-all-files picpocket-identical-files-pic)
                   (tabulated-list-get-id)))



(defun picpocket-score (pic)
  (picpocket-symbol-max (picpocket-all-tags pic)))

(defun picpocket-symbol-max (symbols)
  (let ((max 0))
    (dolist (tag symbols)
      (when (string-match "^[0-9]+$" (symbol-name tag))
        (let ((n (string-to-number (symbol-name tag))))
          (when (or (null max)
                    (> n max))
            (setq max n)))))
    max))

(defun picpocket-score-string (pic)
  (let ((score (picpocket-score pic)))
    (if score
        (number-to-string score)
      "-")))

(defun picpocket-adapt-column-width ()
  (setq tabulated-list-format
        (cl-loop for (header _ . rest) across tabulated-list-format
                 for i = 0 then (1+ i)
                 vconcat (vector
                          (cons header
                                (cons (if (string-equal header "Image")
                                          22
                                        (min picpocket-list-max-width
                                             (max (picpocket-column-width i)
                                                  (length header))))
                                      rest))))))

(defun picpocket-column-width (column-index)
  (or (cl-loop for (_id desc) in tabulated-list-entries
               maximize (length (aref desc column-index)))
      0))


;;; List identical-files mode

(defun picpocket-list-identical-files ()
  "Switch to buffer listing the known identical copies of current picture.

The files are identified with a query to the tag database.
Therefore only pictures that have tags are considered."
  (interactive)
  (let ((pic (cl-case major-mode
               (picpocket-mode
                picpocket-current)
               (picpocket-list-mode
                (picpocket-first-pic-by-absfile (tabulated-list-get-id)))
               (picpocket-list-identical-files-mode
                picpocket-identical-files-pic)
               (t
                (error "Mode %s not supported" major-mode)))))
    (picpocket-with-singleton-buffer picpocket-identical-files-buffer
      (picpocket-list-identical-files-mode)
      (setq-local picpocket-list-entry-function
                  #'picpocket-list-identical-files)
      (setq-local picpocket-identical-files-pic pic)
      (setq-local picpocket-list-pic-list picpocket-list)
      (tabulated-list-revert))))
;; (picpocket-list-identical-files-refresh)
;; (tabulated-list-sort 0))))

(defun picpocket-first-pic-by-absfile (absfile)
  (cl-loop for pic on picpocket-list
           when (equal (picpocket-absfile pic) absfile)
           return pic))

(defun picpocket-list-identical-files-refresh ()
  (setq-local tabulated-list-format
              (vector (list "Filename" 48 t)
                      (list "Size" 8 (picpocket-tab-lesser-f 1))
                      (list "Score" 5 (picpocket-tab-lesser-f 2))
                      (list "Tags" 24 t)
                      (list "Dir-Tags" 24 t)))
  (let ((pic picpocket-identical-files-pic))
    (setq-local tabulated-list-entries
                (cl-loop for file in (picpocket-all-files pic)
                         when (file-exists-p file)
                         collect (list file
                                       (vector
                                        (propertize file
                                                    'font-lock-face
                                                    'picpocket-list-main-field)
                                        (picpocket-kb
                                         (picpocket-bytes-force pic))
                                        (picpocket-score-string pic)
                                        (picpocket-tags-string pic)
                                        (picpocket-dir-tags-string pic))))))
  (picpocket-adapt-column-width)
  (tabulated-list-init-header))


(defun picpocket-delete-identical-file ()
  "Delete file."
  (interactive)
  (let ((file (tabulated-list-get-id))
        (entry (tabulated-list-get-entry)))
    (unless (and file entry)
      (user-error "Nothing to delete"))
    (when (picpocket-confirm-delete-file file)
      (if (eq 1 (length tabulated-list-entries))
          (picpocket-action 'delete nil picpocket-identical-files-pic)
        (picpocket-action 'delete-duplicate
                          entry
                          picpocket-identical-files-pic))
      (picpocket-update-buffers))))

;; Do not bother to remove filename from tags database here.  It
;; cause no harm to keep it.  To remove it would unnecesarily
;; complicate undo.  Especially in the case when all identical-files are
;; removed.
;;
;; PENDING - Need to take care of *picpocket* when all identical-files
;; are deleted or picpocket-update-buffers is enough?
(defun picpocket-delete-duplicate-action (entry pic)
  (let* ((inhibit-quit t)
         (sha (picpocket-sha-force pic))
         (file (picpocket-get-tab-col "Filename" entry))
         (trash-file (picpocket-trash-file file)))
    (unless (file-exists-p file)
      (error "File %s does not exist" file))
    (picpocket-tags-delete-file pic file)
    (rename-file file trash-file)
    (picpocket-stash-undo-op :action 'delete-duplicate
                             :file file
                             :sha sha
                             :trash-file trash-file
                             ;; :tabulated-entry entry
                             )))

(defun picpocket-get-tab-col (header &optional entry)
  (unless entry
    (setq entry (tabulated-list-get-entry)))
  (let ((index (cl-loop for (header-name . _) across tabulated-list-format
                        for i = 0 then (1+ i)
                        when (string-equal header-name header)
                        return i)))
    (aref entry index)))

;; PENDING - Sometimes the top of duplicate buffer is scrolled out
;; of sight.  Quite annoying.
(defun picpocket-undo-delete-duplicate-action (op)
  (let ((trash-file (picpocket-op-trash-file op))
        (file (picpocket-op-file op))
        (sha (picpocket-op-sha op))
        (inhibit-quit t))
    (if (not (file-exists-p trash-file))
        (picpocket-undo-fail "Cannot undelete %s, %s does not exist"
                             (file-name-nondirectory file)
                             trash-file)
      (make-directory (file-name-directory file) t)
      (picpocket-db-tags-copy-file sha file)
      (rename-file trash-file file)
      (picpocket-undo-ok "Undeleted the duplicate %s" file))))



;;; Tag database management

(defvar picpocket-db-update-mode-map nil)
(defvar picpocket-db-update-buffer "*picpocket-db-update*")

(defun picpocket-do-db-update ()
  (picpocket-with-singleton-buffer picpocket-db-update-buffer
    (picpocket-really-do-db-update)))

(defun picpocket-really-do-db-update ()
  (let* ((alist (picpocket-db-traverse))
         (sha-changed (cdr (assq :sha-changed alist)))
         (unique-file-missing (cdr (assq :unique-file-missing alist)))
         (redundant-file-missing (cdr (assq :redundant-file-missing alist)))
         buffer-read-only)
    (setq truncate-lines t)
    (insert "\n")

    (setq picpocket-db-update-mode-map (make-sparse-keymap))

    (insert (picpocket-emph "%s tags (%s unique) on %s files found.\n\n"
                            (picpocket-db-number-of-tags)
                            (picpocket-db-number-of-unique-tags)
                            (picpocket-db-count)))

    ;; exif -c -o x.jpg --ifd=EXIF -t0x9286 --set-value=foo x.jpg
    (if (null sha-changed)
        (insert
         (picpocket-emph "No files with changed sha1 checksum found.\n\n"))
      (let ((n (length sha-changed)))
        (picpocket-db-update-command [?s]
          (lambda ()
            (insert (picpocket-emph "The following %s file%s have "
                                    n (picpocket-plural-s n))
                    (picpocket-emph "changed %s sha1 checksum.\n"
                                    (picpocket-plural-its-their n))
                    "Type "
                    (picpocket-emph "s")
                    " to update picpocket database with the new"
                    " sha1 checksum values.\n\n")
            (picpocket-insert-file-list sha-changed))
          (lambda ()
            (picpocket-update-sha sha-changed)
            (insert
             (picpocket-emph "Sha1 checksums for %s file%s were updated.\n"
                             n (picpocket-plural-s n)))))))

    (if (null redundant-file-missing)
        (insert (picpocket-emph "No missing redundant files.\n\n"))
      (let ((n (length redundant-file-missing)))
        (picpocket-db-update-command [?r]
          (lambda ()
            (insert (picpocket-emph "The following %s redundant file name%s"
                                    n (picpocket-plural-s n))
                    (picpocket-emph " were not found on disk.\n")
                    "Their database entries contains at least one other"
                    " file that do exist.\n"
                    "Type "
                    (picpocket-emph "r")
                    " to remove these file names from the picpocket database.\n"
                    "(Their database entries will not be removed.)\n\n")
            (picpocket-insert-file-list redundant-file-missing))
          (lambda ()
            (picpocket-remove-file-names-in-db redundant-file-missing)
            (insert (picpocket-emph "Removed %s missing "
                                    n)
                    (picpocket-emph "redundant file name%s from database."
                                    (picpocket-plural-s n)))))))

    (if (null unique-file-missing)
        (insert (picpocket-emph "No missing unique files.\n\n"))
      (let ((n (length unique-file-missing)))
        (picpocket-db-update-command [?u]
          (lambda ()
            (insert (picpocket-emph "The following %s unique file name%s"
                                    n (picpocket-plural-s n))
                    (picpocket-emph " were not found on disk.\n")
                    "Their database entries do not contain any"
                    " existing files.\n"
                    "Type "
                    (picpocket-emph "u")
                    " to remove these entries from the picpocket database.\n"
                    "(Their database entries will be removed.)\n\n")
            (picpocket-insert-file-list unique-file-missing))
          (lambda ()
            (picpocket-remove-file-names-in-db unique-file-missing)
            (insert (picpocket-emph "Removed %s missing unique file name%s"
                                    n (picpocket-plural-s n))
                    (picpocket-emph " and their entries from database."))))))

    (goto-char (point-min))
    (picpocket-db-update-mode)))

(defun picpocket-db-update-command (key text-function command-function)
  "Create a command and bind it to KEY.

The TEXT-FUNCTION will be called immediately and is supposed to
insert some text describing what COMMAND-FUNCTION does.  When KEY
is typed that text will be deleted and the COMMAND-FUNCTION will
be called.  COMMAND-FUNCTION may also insert some text and that
will end up replacing the deleted text."
  (declare (indent defun))
  (let ((start (point)))
    (funcall text-function)
    (insert "\n")
    (let ((overlay (make-overlay start (1- (point)))))
      (define-key picpocket-db-update-mode-map key
        (lambda ()
          (interactive)
          (if (null (overlay-start overlay))
              (message "Nothing more to do")
            (let (buffer-read-only)
              (goto-char (overlay-start overlay))
              (delete-region (overlay-start overlay)
                             (overlay-end overlay))
              (delete-overlay overlay)
              (funcall command-function)
              (insert "\n"))))))))


(defun picpocket-update-sha (sha-changed)
  (cl-loop for (file new-tags sha new-sha) in sha-changed
           do (picpocket-with-db new-sha (plist files tags)
                (picpocket-db-put new-sha (list :files
                                                (picpocket-add-to-list file
                                                                       files)
                                                :tags
                                                (cl-union tags
                                                          new-tags))))
           do (picpocket-with-db sha (plist files)
                (let ((remaining-files (delete file files)))
                  (if remaining-files
                      (picpocket-db-put sha (plist-put plist
                                                       :files
                                                       remaining-files))
                    (picpocket-db-remove sha))))))

(defun picpocket-remove-file-names-in-db (missing-files)
  (cl-loop for (file ignored sha) in missing-files
           do (picpocket-with-db sha (plist files)
                (let ((new-files (delete file files)))
                  (if new-files
                      (picpocket-db-put sha (plist-put plist
                                                       :files
                                                       new-files))
                    (picpocket-db-remove sha))))))

(defun picpocket-emph (format &rest args)
  (propertize (apply #'format format args)
              'face 'bold
              'font-lock-face 'bold))

(defun picpocket-insert-file-list (list)
  (dolist (entry list)
    (insert "  "
            (picpocket-join (car entry)
                            (picpocket-format-tags (cadr entry)))
            "\n")))

(define-derived-mode picpocket-db-update-mode special-mode "picpocket-db-update"
  "Major mode for interacting with picpocket database.

\\{picpocket-db-update-mode-map}"
  (define-key picpocket-db-update-mode-map [?g] #'picpocket-db-update)
  (setq truncate-lines t))

(defun picpocket-db-traverse ()
  (picpocket-db-init)
  (let ((progress (make-progress-reporter "Traversing database "
                                          0
                                          (picpocket-db-count)))
        (i 0)
        sha-changed
        unique-file-missing
        redundant-file-missing)
    (picpocket-db-mapc
     (lambda (sha plist)
       (let ((tags (plist-get plist :tags))
             (files (plist-get plist :files))
             missing-files existing-files)
         (dolist (file files)
           (if (file-exists-p file)
               (let ((new-sha (picpocket-sha1sum file)))
                 (unless (equal sha new-sha)
                   (push (list file tags sha new-sha) sha-changed))
                 (push file existing-files))
             (push (list file tags sha) missing-files)))
         (when missing-files
           (if existing-files
               (setq redundant-file-missing
                     (append missing-files
                             redundant-file-missing))
             (setq unique-file-missing
                   (append missing-files
                           unique-file-missing))))
         (cl-incf i)
         (progress-reporter-update progress i))))
    (progress-reporter-done progress)
    (list (cons :sha-changed sha-changed)
          (cons :unique-file-missing unique-file-missing)
          (cons :redundant-file-missing redundant-file-missing))))

(defun picpocket-db-compile-tags-for-completion ()
  (picpocket-db-mapc (lambda (_ plist)
                       (dolist (tag (plist-get plist :tags))
                         (intern (symbol-name tag)
                                 picpocket-tag-completion-table)))))

(defun picpocket-db-number-of-tags ()
  (let ((count 0))
    (picpocket-db-mapc (lambda (_ plist)
                         (cl-incf count (length (plist-get plist :tags)))))
    count))

(defun picpocket-db-number-of-unique-tags ()
  (let ((count 0))
    (mapatoms (lambda (_) (cl-incf count)) picpocket-tag-completion-table)
    count))


;;; Database

;; This "database" stores a hash table in a text file.
;; The file format is:
;;
;; (version VERSION)
;; (format FORMAT)
;; (data-version DATA-VERSION)
;;
;; where VERSION is the integer version of the picp database and
;; DATA-VERSION is the integer version of the stored data.  FORMAT is
;; either list or hash-table.  In case of hash-table format the next
;; value is the hash table itself.  The hash table maps sha1 checksums
;; to data entries.  In case of list format lists like (SHA DATA)
;; follows for every hash table entry.
;;
;; TODO
;; SQL support (no, not really)
;; NoSQL support (don't we have that already?)


(defvar picpocket-db-dir (concat user-emacs-directory "picpocket/"))

(defconst picpocket-db-version 1)

(defvar picpocket-db nil)

(defvar picpocket-db-remove-corrupted-files nil)

(defvar picpocket-db-format 'list
  "Either `list' or `hash-table'.
`hash-table' is faster.
`list' makes the database files more readable.")

(defvar picpocket-db-valid-formats '(list hash-table))

(defvar picpocket-db-journal-size 0)


(defun picpocket-db-journal-size ()
  picpocket-db-journal-size)

(defun picpocket-db-get (sha)
  (gethash sha picpocket-db))

(defun picpocket-db-put (sha data)
  (let ((inhibit-quit t)
        (coding-system-for-write 'utf-8-unix)
        print-level print-length)
    (if data
        (puthash sha data picpocket-db)
      (remhash sha picpocket-db))
    (with-temp-buffer
      (let ((standard-output (current-buffer)))
        (unless (file-exists-p (picpocket-db-file :journal))
          (picpocket-db-insert-header)
          (prin1 (list 'version picpocket-db-version))
          (insert "\n"))
        (picpocket-db-insert-list-item (list sha data))
        (write-region (point-min)
                      (point-max)
                      (picpocket-db-file :journal)
                      t
                      'silent)))
    (cl-incf picpocket-db-journal-size)))

(defun picpocket-db-insert-header ()
  (insert (picpocket-db-header) "\n"))

(defconst picpocket-db-header-text
  "This file is auto-generated by picpocket.el in Emacs.
Not meant to be manually edited.  But if you plan to manually
edit this file you should first kill the *picpocket* buffer in
any Emacs.  Otherwise your edits may become overwritten.")

(defun picpocket-db-header ()
  (with-temp-buffer
    (let ((fill-column 54)
          (comment-start ";; "))
    (insert "-*- coding: utf-8-unix; no-byte-compile: t -*-\n\n"
            picpocket-db-header-text)
    (fill-paragraph)
    (comment-region (point-min) (point-max))
    (goto-char (point-min))
    (while (re-search-forward " +$" nil t)
      (replace-match ""))
    (buffer-string))))

(defun picpocket-db-insert-list-item (item)
  (prin1 item)
  (insert "\n"))

(defun picpocket-db-remove (sha)
  (picpocket-db-put sha nil))

(defun picpocket-db-clear ()
  (when (hash-table-p picpocket-db)
    (clrhash picpocket-db))
  (setq picpocket-db (picpocket-db-new-hash-table)))

(defun picpocket-db-count ()
  (hash-table-count picpocket-db))

(defun picpocket-db-init ()
  (make-directory picpocket-db-dir t)
  (let ((db (picpocket-db-read nil))
        (old (picpocket-db-read :old)))
    (setq picpocket-db
          (cond ((and (hash-table-p db) (null old))
                 db)
                ((and (null db) (null old))
                 (picpocket-db-new-hash-table))
                ((and (not (hash-table-p db)) (hash-table-p old))
                 (picpocket-warn "Recovering with picpocket old file")
                 old)
                ((and (hash-table-p db) (hash-table-p old))
                 (picpocket-warn "Ignoring spurious picpocket old file (%s)"
                                 (picpocket-db-file :old))
                 (when picpocket-db-remove-corrupted-files
                   (delete-file (picpocket-db-file :old)))
                 db)
                ((and (hash-table-p db) (eq old 'error))
                 (picpocket-warn "Ignoring corrupt picpocket old file (%s)"
                                 (picpocket-db-file :old))
                 (when picpocket-db-remove-corrupted-files
                   (delete-file (picpocket-db-file :old)))
                 db)
                (t
                 (message "(hash-table-p db) %s" (hash-table-p db))
                 (message "(hash-table-p old) %s" (hash-table-p old))
                 (message "db %s" db)
                 (message "old %s" old)
                 (picpocket-fatal "Cannot recover picpocket database in %s"
                                  picpocket-db-dir))))
    (when (file-exists-p (picpocket-db-file :journal))
      (picpocket-db-read-journal)
      (picpocket-db-save))))

(defun picpocket-fatal (format &rest args)
  (let ((message (apply #'format format args)))
    (setq picpocket-fatal message)
    (error message)))


(defun picpocket-db-new-hash-table ()
  (make-hash-table :test 'equal))

(defun picpocket-db-read (file-symbol)
  (let ((db-file (picpocket-db-file file-symbol)))
    (when (file-exists-p db-file)
      (condition-case err
          (with-temp-buffer
            (insert-file-contents db-file)
            (let* ((standard-input (current-buffer))
                   (version (cadr (read)))
                   (format (cadr (read)))
                   (ignored (cadr (read))))
              (unless (equal version picpocket-db-version)
                (error "Unknown picpocket database version %s in %s"
                       version db-file))
              (cl-case format
                (hash-table (picpocket-db-read-hash-table))
                (list (picpocket-db-read-list))
                (t (error "Unknown format %s in %s (%s)"
                          format
                          db-file
                          (picpocket-db-valid-formats-string))))))
        (error (picpocket-warn "Failed to read %s - %s" db-file err)
               'error)))))

(defun picpocket-db-read-hash-table ()
  (let ((db (read)))
    (unless (hash-table-p db)
      (error "Not a proper hash table"))
    db))

(defun picpocket-db-read-list ()
  (picpocket-db-read-and-hash-list (picpocket-db-new-hash-table)))

(defun picpocket-db-read-and-hash-list (hash-table &optional counter)
  (condition-case ignored
      (while t
        (cl-destructuring-bind (key value) (read)
          (if value
              (puthash key value hash-table)
            (remhash key hash-table))
          (when counter
            (set counter (1+ (symbol-value counter))))))
    (end-of-file))
  hash-table)


(defun picpocket-db-save ()
  (let ((db-file (picpocket-db-file))
        (tmp-file (picpocket-db-file :tmp))
        (old-file (picpocket-db-file :old))
        (journal-file (picpocket-db-file :journal)))
    (with-temp-file tmp-file
      (set-buffer-file-coding-system 'utf-8-unix)
      (let ((standard-output (current-buffer))
            (print-level print-length))
        (picpocket-db-insert-header)
        (prin1 (list 'version picpocket-db-version))
        (insert "\n")
        (prin1 (list 'format picpocket-db-format))
        (insert "\n")
        (prin1 (list 'data-version 1))
        (insert "\n")
        (cl-case picpocket-db-format
          (hash-table (picpocket-db-save-hash-table))
          (list (picpocket-db-save-list))
          (t (error "Unknown value of picpocket-db-format %s (%s)"
                    picpocket-db-format (picpocket-db-valid-formats-string))))
        (insert "\n")
        (insert ";; Local Variables:\n")
        (insert ";; whitespace-line-column: 1000\n")
        (insert ";; End:\n")))
    (let ((inhibit-quit t))
      (when (file-exists-p db-file)
        (copy-file db-file old-file))
      (copy-file tmp-file db-file t)
      (delete-file tmp-file)
      (when (file-exists-p old-file)
        (delete-file old-file))
      (when (file-exists-p journal-file)
        (delete-file journal-file))
      (setq picpocket-db-journal-size 0))))




(defun picpocket-db-valid-formats-string ()
  (format "should be %s"
          (mapconcat #'symbol-name picpocket-db-valid-formats " or ")))


(defun picpocket-db-save-hash-table ()
  (prin1 picpocket-db)
  (insert "\n"))

(defun picpocket-db-dump ()
  (with-temp-buffer
    (picpocket-db-save-list)
    (buffer-string)))

(defun picpocket-db-save-list ()
  (let (list)
    (maphash (lambda (key value)
               (push (list key value) list))
             picpocket-db)
    ;; PENDING - optionally sort the list.
    (dolist (element list)
      (picpocket-db-insert-list-item element))))

(defun picpocket-db-file (&optional symbol)
  (concat picpocket-db-dir
          "picpocket-db"
          (when symbol
            (concat "-" (substring (symbol-name symbol) 1)))
          ".el"))

(defun picpocket-db-read-journal ()
  (setq picpocket-db-journal-size 0)
  (let ((journal-file (picpocket-db-file :journal)))
    (when (file-exists-p journal-file)
      (with-temp-buffer
        (insert-file-contents journal-file)
        (let* ((standard-input (current-buffer))
               (version (cadr (read))))
          (if (not (equal picpocket-db-version version))
              (picpocket-warn
               "Ignoring picpocket journal %s of unknown version %s"
               journal-file version)
            (picpocket-db-read-and-hash-list picpocket-db
                                             'picpocket-db-journal-size)))))))

(defun picpocket-db-mapc (f)
  (maphash f picpocket-db))




;;; Idle timer functions


;; The following measures how long time the time comparison in the
;; deadline function takes.  It estimates how expensive it is to
;; restart unfinished idle functions.

;; 1000000 3400ms
;; 100000  340ms
;; 10000   13ms (+130ms sometimes (gc i suppose))

;; (picpocket-time-string
;; (let ((start (current-time)))
;; (dotimes (i 1000000)
;; (time-less-p picpocket-idle-f-deadline
;; (time-subtract (current-time) start)))))
;; (garbage-collect)


(defun picpocket-set-idle-f-state (f state)
  (put f 'picpocket-state state))

(defun picpocket-idle-f-state (f)
  (get f 'picpocket-state))

(defun picpocket-set-idle-f-result (f result)
  (put f 'picpocket-result result))

(defun picpocket-idle-f-result (f)
  (get f 'picpocket-result))

(defun picpocket-set-idle-f-resume-timer (f resume-timer)
  (put f 'picpocket-resume-timer resume-timer))

(defun picpocket-idle-f-resume-timer (f)
  (get f 'picpocket-resume-timer))


(defun picpocket-idle-f-restart-all ()
  (cl-loop for (f . _) in picpocket-idle-functions
           do (picpocket-idle-f-restart f)))

(defun picpocket-idle-f-restart (f)
  (unless (assq f picpocket-idle-functions)
    (error "Invalid argument to picpocket-idle-f-restart (%s)" f))
  (picpocket-set-idle-f-state f nil)
  (picpocket-set-idle-f-result f nil))

(defun picpocket-idle-f-restart-all-unfinished ()
  (cl-loop for (f . _) in picpocket-idle-functions
           do (picpocket-idle-f-restart-unfinished f)))

;; Unfinished is here defined as state not being the symbol done.
(defun picpocket-idle-f-restart-unfinished (f)
  (unless (eq 'done (picpocket-idle-f-state f))
    (picpocket-idle-f-restart f)))

(defun picpocket-idle-f-restart-all-filter-related ()
  (picpocket-idle-f-restart #'picpocket-compute-filter-index)
  (picpocket-idle-f-restart #'picpocket-compute-filter-match-count))



(defun picpocket-idle-functions ()
  (cl-loop for (f . _) in picpocket-idle-functions
           collect f))


(defun picpocket-init-timers ()
  (picpocket-cancel-timers)
  (picpocket-idle-f-restart-all)
  (unless picpocket-inhibit-timers
    (add-hook 'kill-buffer-hook #'picpocket-cancel-timers nil t)
    (let ((inhibit-quit t))
      (setq picpocket-timers
            (cl-loop for (f s _p) in picpocket-idle-functions
                     for sec = (if (functionp s)
                                   (funcall s)
                                 s)
                     collect (run-with-idle-timer sec
                                                  t
                                                  #'picpocket-run-idle-f
                                                  f))))))

(defun picpocket-cancel-timers ()
  (dolist (timer picpocket-timers)
    (cancel-timer timer))
  (setq picpocket-timers nil)
  (dolist (f (picpocket-idle-functions))
    (picpocket-cancel-resume-timer f)))

(defun picpocket-cancel-resume-timer (f)
  (let ((resume-timer (picpocket-idle-f-resume-timer f)))
    (when resume-timer
      (picpocket-set-idle-f-resume-timer f nil)
      (cancel-timer resume-timer))))


(defun picpocket-run-idle-f (f)
  (let ((debug-on-error picpocket-idle-f-debug)
        (buffer (get-buffer picpocket-buffer))
        (state (get f 'picpocket-state))
        (state-predicate (cl-caddr (assq f picpocket-idle-functions))))
    (picpocket-cancel-resume-timer f)
    (or (null state)
        (eq state 'done)
        (null state-predicate)
        (funcall state-predicate state)
        (error "%s: invalid state %s" f state))
    (cond (picpocket-inhibit-timers
           (picpocket-cancel-timers))
          (buffer
           (with-current-buffer buffer
             (picpocket-run-idle-f-in-buffer f state)))
          (t (picpocket-cancel-timers)))))

(defun picpocket-run-idle-f-in-buffer (f state)
  (cond ((null picpocket-list)
         (picpocket-cancel-timers))
        ((null picpocket-db)
         (message "Cancel idle timers since picpocket-db is nil")
         (picpocket-cancel-timers))
        ((not (file-directory-p default-directory))
         (message "Closing picpocket buffer since %s does not exist any more"
                  default-directory)
         (kill-buffer picpocket-buffer)
         (picpocket-cancel-timers))
        ((eq state 'done)
         (when picpocket-idle-f-debug
           (message "picpocket idle f %s already done" f)))
        (t
         (condition-case err
             (progn
               (setq state (funcall f (picpocket-make-deadline-function) state))
               (picpocket-set-idle-f-state f state)
               (when (and state
                          (not (eq state 'done)))
                 (picpocket-set-idle-f-resume-timer
                  f
                  (run-with-idle-timer (time-add (or (current-idle-time)
                                                     (seconds-to-time 0))
                                                 picpocket-idle-f-pause)
                                       nil
                                       #'picpocket-run-idle-f
                                       f))))
           (quit (message "picpocket-run-idle-f %s interrupted by quit"
                          f)
                 (signal (car err) (cdr err)))))))

(defun picpocket-make-deadline-function ()
  (let ((start (current-time)))
    (lambda ()
      (time-less-p picpocket-idle-f-deadline
                   (time-subtract (current-time) start)))))


(defun picpocket-traverse-pic-list (deadline-function state)
  (cl-loop for pic on (or state picpocket-list)
           for i = 1 then (1+ i)
           do (picpocket-ensure-cache pic)
           when (null (cdr pic))
           return (progn
                    (when picpocket-idle-f-debug
                      (message "picpocket-traverse-pic-list is done (i %s)" i))
                    'done)
           when (funcall deadline-function)
           return (progn
                    (when picpocket-idle-f-debug
                      (message "picpocket-traverse-pic-list travsersed %s" i))
                    (cdr pic))))

;; Do not call picpocket-size-force here since it eats a lot of memory
;; and cpu for very little use.  (Also it may push out the very next
;; pic from the emacs image cache.  So if it was called then
;; picpocket-traverse-pic-list should call picpocket-look-ahead-next
;; after the loop to put it back if needed.)
(defun picpocket-ensure-cache (pic)
  (when (file-exists-p (picpocket-absfile pic))
    ;; If the user have no saved tags there is no reason to compute sha.
    (unless (zerop (picpocket-db-count))
      (picpocket-sha-force pic))
    (picpocket-rotation-force pic)
    (picpocket-bytes-force pic)))


;; STATE is (COUNT . PIC).  Done when list is traversed.  Then the
;; total count is stored as the result and the state will be the
;; symbol done.
(defun picpocket-compute-filter-match-count (deadline-function state)
  (when picpocket-idle-f-debug
    (if (consp state)
        (message "picpocket-compute-filter-match-count count %s left %s"
                 (car state) (length (cdr state)))
      (message "picpocket-compute-filter-match-count state %s"
               state)))
  (when picpocket-filter
    (let* ((state (or state (cons 0 picpocket-list)))
           (count (car state))
           (state-pic (cdr state)))
      (cl-loop for pic on state-pic
               for i = 1 then (1+ i)
               do (when (picpocket-filter-match-p pic)
                    (cl-incf count))
               when (null (cdr pic))
               return (progn
                        (picpocket-set-filter-match-count count)
                        (when picpocket-idle-f-debug
                          (message "picpocket-compute-filter-match-count done"))
                        'done)
               when (funcall deadline-function)
               return (progn
                        (when picpocket-idle-f-debug
                          (message "picpocket-compute-filter-match-count i %s"
                                   i))
                        (cons count (cdr pic)))))))

(defun picpocket-filter-match-count ()
  (picpocket-idle-f-result #'picpocket-compute-filter-match-count))

(defun picpocket-set-filter-match-count (count)
  (picpocket-set-idle-f-result #'picpocket-compute-filter-match-count count))

(defun picpocket-no-matching-pictures-p ()
  (and (picpocket-filter-match-count)
       (zerop (picpocket-filter-match-count))))


;; STATE is a picpocket-pos struct.  Done when the correct index is
;; found which is then stored as result.  State is then the symbol
;; done.  If the user is going backwards in the list there is a small
;; risk that this traversing loop will miss and go to the end of the
;; list without finding the index.  Then it will return nil and so it
;; will restart.
(defun picpocket-compute-filter-index (deadline-function state)
  (when (and picpocket-filter
             (not (picpocket-no-matching-pictures-p)))
    (setq state (or state (picpocket-first-pos)))
    (cl-loop for pos = state then (picpocket-next-pos pos 'silent)
             for i = 1 then (1+ i)
             when (and pos
                       (eq (picpocket-pos-current pos) picpocket-current))
             return (progn
                      (picpocket-set-filter-index
                       (picpocket-pos-filter-index pos))
                      (when picpocket-idle-f-debug
                        (message "picpocket-compute-filter-index done"))
                      'done)
             when (funcall deadline-function)
             return (progn
                      (when picpocket-idle-f-debug
                        (message "picpocket-compute-filter-index i %s" i))
                      pos))))

(defun picpocket-filter-index ()
  (picpocket-idle-f-result #'picpocket-compute-filter-index))

(defun picpocket-set-filter-index (index)
  (picpocket-set-idle-f-result #'picpocket-compute-filter-index index))

(defun picpocket-idle-f-info ()
  (let* ((state-index (picpocket-idle-f-state
                       #'picpocket-compute-filter-index))
         (state-count (picpocket-idle-f-state
                       #'picpocket-compute-filter-match-count))
         (state-traverse (picpocket-idle-f-state
                          #'picpocket-traverse-pic-list))
         (index (if (picpocket-pos-p state-index)
                    (length (picpocket-pos-current state-index))
                  state-index))
         (count (if (consp state-count)
                    (format "(%s (left %s))"
                            (car state-count)
                            (length (cdr state-count)))
                  state-count))
         (traverse (if (listp state-traverse)
                       (length state-traverse)
                     state-traverse)))
    (format "{%s / %s %s}" index count traverse)))



(defun picpocket-update-current-bytes (&rest ignored)
  (let ((bytes (picpocket-bytes)))
    (picpocket-bytes-force picpocket-current)
    (unless bytes
      (force-mode-line-update)))
  nil)

(defun picpocket-maybe-save-journal (&rest ignored)
  (when (> (picpocket-db-journal-size) 100)
    (picpocket-db-save))
  nil)

(defun picpocket-save-journal (&rest ignored)
  (unless (zerop (picpocket-db-journal-size))
    (picpocket-db-save))
  nil)

;; This is skipped when there is a filter.  With a filter this
;; operation could potentially take a very long time.  And it
;; currently do not care about any deadlines.
(defun picpocket-look-ahead-next (&rest ignored)
  (unless picpocket-filter
    (let ((pic (or (picpocket-next-pic) (picpocket-previous-pic))))
      (when (and pic
                 (not (eq pic picpocket-last-look-ahead)))
        (picpocket-look-ahead-and-save-time pic)
        (setq picpocket-last-look-ahead pic))))
  nil)


(defun picpocket-look-ahead-more (deadline-function ignored)
  (let ((s (cadr (picpocket-time (picpocket-look-ahead-more2
                                  deadline-function)))))
    (picpocket-debug s "more")))

(defun picpocket-look-ahead-more2 (deadline-function)
  (cl-loop for pic on picpocket-current
           for count = 0 then (1+ count)
           until (funcall deadline-function)
           finally return count
           repeat picpocket-look-ahead-max
           do (picpocket-look-ahead-and-save-time pic)))


;;; Buffer content functions

;; (PENDING Mini buffer could optionally show previous and next images as
;; smaller thumbnails?)

(defun picpocket-toggle-mini-window ()
  "Toggle a mini window to the left."
  (interactive)
  (picpocket-command
    (let ((mini-window (picpocket-visible-window picpocket-mini-buffer)))
      (if mini-window
          (delete-window mini-window)
        (picpocket-add-mini-window)))))

(defun picpocket-add-mini-window ()
  (let ((mini-buffer (get-buffer-create picpocket-mini-buffer))
        (mini-window (split-window nil (- picpocket-mini-buffer-width)
                                   'left t)))
    (with-current-buffer mini-buffer
      (picpocket-base-mode)
      (setq vertical-scroll-bar nil
            cursor-type nil
            left-fringe-width 0
            right-fringe-width 0)
      (when (picpocket-fullscreen-p)
        (setq mode-line-format nil)))
    (set-window-buffer mini-window mini-buffer)))
;; PENDING delete mode line in fullscreen...

(defun picpocket-update-mini-buffer ()
  (with-current-buffer (get-buffer-create picpocket-mini-buffer)
    (let (buffer-read-only)
      (erase-buffer)
      (when (and picpocket-current
                 (file-exists-p (picpocket-absfile)))
        (when picpocket-header
          (insert "\n"))
        (picpocket-insert-image (picpocket-create-mini-image picpocket-current))
        (goto-char (point-min))))))

(defun picpocket-insert-image (image)
  (if (display-images-p)
      (insert-image image)
    (insert "\n\n[This display does not support images]"))
  (goto-char (point-min)))

(defun picpocket-update-buffers ()
  (run-hooks 'picpocket-update-hook)
  (picpocket-update-the-main-buffer)
  (when (picpocket-visible-window picpocket-mini-buffer)
    (picpocket-update-mini-buffer))
  (when (buffer-live-p (get-buffer picpocket-undo-buffer))
    (picpocket-update-undo-buffer))
  ;; Update possible current list buffer (do not bother to find and
  ;; update all list buffers).
  (when (derived-mode-p 'picpocket-tab-mode)
    (revert-buffer)))

(defun picpocket-create-mini-image (pic)
  (let ((w (picpocket-visible-window picpocket-mini-buffer)))
    (pcase-let ((`(,keyword . ,value)
                 (picpocket-size-param pic (cons (window-pixel-width w)
                                                 (window-pixel-height w)))))
      (create-image (picpocket-absfile pic)
                    (picpocket-image-type pic)
                    nil
                    :rotation (picpocket-rotation-force pic)
                    keyword value))))

(defun picpocket-rotation-force (pic)
  (or (picpocket-rotation pic)
      (picpocket-set-rotation pic (picpocket-guess-rotation pic))))

(defun picpocket-guess-rotation (pic)
  (or (and (fboundp 'exif-orientation)
           (fboundp 'exif-parse-file)
           picpocket-trust-exif-rotation
           (exif-orientation (condition-case nil
                                 (exif-parse-file (picpocket-absfile pic))
                               (exif-error nil))))
      0.0))

(defun picpocket-save-rotation ()
  "Alter the EXIF metadata of the current file to include rotation."
  (interactive)
  (picpocket-command
    (unless (executable-find "exif")
      (error "Command exif not found"))
    (let ((orientation (picpocket-degrees-to-orientation (picpocket-rotation)))
          (tags (picpocket-tags)))
      (when (zerop orientation)
        (error "Rotation %s cannot be represented in EXIF metadata"
               (picpocket-rotation)))
      (with-temp-buffer
        (let ((rc (call-process "exif" nil t nil
                                ;; PENDING if the file do not already
                                ;; have an EXIF section that can be
                                ;; created if the --create-exif option
                                ;; is provided.  However it seem like
                                ;; emacs cannot read a EXIF section
                                ;; created in such a way.  So for now
                                ;; let command fail immediately
                                ;; instead.
                                "--ifd=0"
                                "--tag=Orientation"
                                (format "--set-value=%s" orientation)
                                (format "--output=%s" (picpocket-absfile))
                                (picpocket-absfile))))
          (unless (zerop rc)
            (message "exif command returned %s on %s with output: %s"
                     rc (picpocket-absfile) (buffer-string))
            (error "The exif command failed"))))
      (picpocket-save-sha-in-pic-and-db picpocket-current)
      (picpocket-save-size-in-pic picpocket-current)
      (picpocket-save-bytes-in-pic picpocket-current)
      (picpocket-tags-set picpocket-current tags)
      (clear-image-cache (picpocket-absfile))
      (message "Rotation saved in file"))))

(defun picpocket-degrees-to-orientation (degrees)
  (cl-case (truncate degrees)
    (0 1)
    (90 6)
    (180 3)
    (270 8)
    (t 0)))


(defun picpocket-update-the-main-buffer ()
  (when (buffer-live-p (get-buffer picpocket-buffer))
    (with-current-buffer picpocket-buffer
      (picpocket-update-main-buffer))))

(defun picpocket-update-identical-files-buffer ()
  (when (buffer-live-p (get-buffer picpocket-identical-files-buffer))
    (with-current-buffer picpocket-identical-files-buffer
      (revert-buffer))))

(defun picpocket-ensure-picpocket-buffer ()
  (unless (and (equal (buffer-name) picpocket-buffer)
               (eq major-mode 'picpocket-mode))
    (error "%s requires picpocket mode" (or this-command
                                            "This"))))

(defun picpocket-update-main-buffer ()
  (let ((s (cadr (picpocket-time (picpocket-do-update-main-buffer)))))
    (picpocket-debug s "%s %s" this-command picpocket-index)))

(defun picpocket-do-update-main-buffer ()
  (picpocket-ensure-picpocket-buffer)
  (let (buffer-read-only)
    (erase-buffer)
    (cond (picpocket-fatal
           (picpocket-show-fatal))
          ((picpocket-try-set-matching-picture)
           (cd (picpocket-dir))
           (if (file-exists-p (picpocket-absfile))
               (picpocket-insert-pic picpocket-current)
             (insert "\n\nFile " (picpocket-file) " no longer exist.\n")))
          (t
           (picpocket-no-pictures)))
    (force-mode-line-update)))

(defun picpocket-insert-pic (pic)
  (picpocket-insert-image
   (picpocket-create-image pic (picpocket-save-window-size))))

(defun picpocket-show-fatal ()
  (insert (propertize "\n\nFatal error: " 'face 'bold)
          picpocket-fatal
          "\n\n")
  (picpocket-dired-hint))

(defun picpocket-dired-hint ()
  (insert (format "Type %s for dired in %s.\n"
                  (picpocket-where-is 'picpocket-dired)
                  (abbreviate-file-name default-directory))))

(defun picpocket-try-set-matching-picture ()
  "Return nil if no matching picture was found."
  (when picpocket-current
    (or (picpocket-filter-match-p picpocket-current)
        (picpocket-when-let (pos (or (picpocket-next-pos)
                                     (picpocket-previous-pos)))
          (picpocket-set-pos pos)
          t))))

(defun picpocket-current-picture-check ()
  (unless picpocket-current
    (user-error "No current picture available"))
  (unless (picpocket-filter-match-p picpocket-current)
    (user-error "No picture matching filter %s"
                (picpocket-format-tags picpocket-filter)))
  (unless (file-exists-p (picpocket-absfile))
    (error "File %s no longer exists" (picpocket-file))))

(defun picpocket-current-picture-p ()
  (and picpocket-current
       (picpocket-filter-match-p picpocket-current)
       (file-exists-p (picpocket-absfile))))

(defun picpocket-no-pictures ()
  (insert (propertize (format "\n\nNo pictures in list%s.\n\n"
                              (if picpocket-filter
                                  (format " matching filter %s"
                                          picpocket-filter)
                                ""))
                      'face 'bold))
  (when picpocket-filter
    (insert (format "Type %s to edit filter.\n"
                    (picpocket-where-is 'picpocket-set-filter))))
  (and (eq picpocket-entry-function 'picpocket-directory)
       (not picpocket-recursive)
       (insert
        (format "Type %s to recursively include pictures in subdirectories.\n"
                (picpocket-where-is 'picpocket-toggle-recursive))))
  (picpocket-dired-hint))


(defun picpocket-where-is (command)
  (let ((binding (where-is-internal command overriding-local-map t)))
    (propertize (if binding
                    (key-description binding)
                  (concat "M-x " (symbol-name command)))
                'face 'bold)))


(defun picpocket-create-buffer (files &optional selected-file dir)
  (and (< emacs-major-version 27)
       picpocket-prefer-imagemagick
       (not (image-type-available-p 'imagemagick))
       (message "%s%s" "For picpocket it is recommended that Emacs below 27.1 "
                "are built with imagemagick"))
  (when selected-file
    (setq selected-file (file-truename
                         (expand-file-name selected-file dir))))
  (picpocket-with-singleton-buffer picpocket-buffer
    (when dir
      (cd dir))
    (picpocket-mode)
    (condition-case err
        (picpocket-create-picpocket-list files selected-file)
      (quit (picpocket-reset)
            (signal (car err) (cdr err))))
    (picpocket-update-main-buffer)))


;;; Image handling

(defun picpocket-save-window-size ()
  "Save the current window size.
This is for the benefit of timer functions that do not
necessarily run with the picpocket window selected."
  (setq picpocket-window-size (picpocket-current-window-size)))

(defun picpocket-current-window-size ()
  (cl-destructuring-bind (x0 y0 x1 y1) (window-inside-pixel-edges)
    ;; For some reason Emacs 25.0 refuses to draw image in a right
    ;; margin that seem to be (frame-char-width) pixels wide.
    ;; Therefore subtract that.
    (cons (- x1 x0 (frame-char-width))
          (- y1 y0))))

(defun picpocket-create-image (pic canvas-size)
  (pcase-let ((`(,keyword . ,value) (picpocket-clock
                                      (picpocket-size-param pic canvas-size))))
    (create-image (picpocket-absfile pic)
                  (picpocket-image-type pic)
                  nil
                  :rotation (picpocket-rotation-force pic)
                  keyword (picpocket-scale value))))

(defun picpocket-image-type (_pic-or-filename)
  (and picpocket-prefer-imagemagick
       (image-type-available-p 'imagemagick)
       'imagemagick))

(defun picpocket-size-param (pic canvas-size)
  (pcase-let ((canvas-ratio (picpocket-cons-ratio canvas-size))
              (rot-ratio (picpocket-cons-ratio (picpocket-rotated-size pic)))
              (`(,pic-x . ,_) (picpocket-size-force pic)))
    (pcase picpocket-fit
      (:x-and-y (if (> canvas-ratio rot-ratio)
                    (picpocket-height-size-param pic canvas-size)
                  (picpocket-width-size-param pic canvas-size)))
      (:x (picpocket-width-size-param pic canvas-size))
      (:y (picpocket-height-size-param pic canvas-size))
      (_ (cons :width pic-x)))))

(defun picpocket-height-size-param (pic canvas-size)
  (pcase-let* ((`(,_ . ,canvas-y) canvas-size)
               (`(,_ . ,pic-y) (picpocket-size-force pic))
               (`(,_ . ,rot-y) (picpocket-rotated-size pic))
               (y-ratio (picpocket-ratio pic-y rot-y)))
    (cons :height (round (* y-ratio canvas-y)))))

(defun picpocket-width-size-param (pic canvas-size)
  (pcase-let* ((`(,canvas-x . ,_) canvas-size)
               (`(,pic-x . ,_) (picpocket-size-force pic))
               (`(,rot-x . ,_) (picpocket-rotated-size pic))
               (x-ratio (picpocket-ratio pic-x rot-x)))
    (cons :width (round (* x-ratio canvas-x)))))

(defun picpocket-size-force (&optional pic)
  (unless pic
    (setq pic picpocket-current))
  (or (picpocket-size pic)
      (picpocket-save-size-in-pic pic)))

(defun picpocket-save-size-in-pic (pic)
  (picpocket-set-size
   pic (picpocket-image-size (create-image (picpocket-absfile pic)
                                           (picpocket-image-type pic)
                                           nil
                                           ;; The size in pic is the
                                           ;; unrotated size.
                                           :rotation 0.0))))

(defun picpocket-rotated-size (pic)
  (if (zerop (picpocket-rotation-force pic))
      (picpocket-size-force pic)
    (picpocket-image-size (create-image (picpocket-absfile pic)
                                        (picpocket-image-type pic)
                                        nil
                                        :rotation (picpocket-rotation pic)))))

(defun picpocket-image-size (image &optional frame)
  (if (display-images-p)
      (image-size image t frame)
    (cons 100 100)))


(cl-defun picpocket-cons-ratio ((a . b))
  (/ (float a) b))

(defun picpocket-ratio (a b)
  (/ (float a) b))

(defun picpocket-look-ahead-and-save-time (pic)
  (let ((s (cadr (picpocket-time (picpocket-look-ahead pic))))
        (picpocket-sum 0))
    (picpocket-debug s "look")))

(defun picpocket-look-ahead (pic)
  (picpocket-ensure-cache pic)
  (picpocket-image-size (picpocket-create-image pic picpocket-window-size)
                        (picpocket-frame)))


(defun picpocket-scale (n)
  (/ (* picpocket-scale n) 100))

(defun picpocket-alter-scale (delta)
  (setq picpocket-scale
        (max 10 (+ picpocket-scale delta)))
  (message "Scaling factor is %s%%" picpocket-scale))

(defun picpocket-picture-regexp ()
  (or picpocket-picture-regexp
      (setq picpocket-picture-regexp
            (if (and picpocket-prefer-imagemagick
                     (image-type-available-p 'imagemagick))
                (car (rassq 'imagemagick image-type-file-name-regexps))
              (mapconcat #'identity
                         (cl-loop for (regexp . mode) in auto-mode-alist
                                  when (eq mode 'image-mode)
                                  collect regexp)
                         "\\|")))))

(defun picpocket-clear-image-cache ()
  "Clear image cache.  Only useful for benchmarks."
  (interactive)
  (picpocket-command
    (setq picpocket-sum 0)
    (message "Clear image cache %s"
             (picpocket-time-string (clear-image-cache t)))))


;;; English functions

(defun picpocket-plural-s (n)
  (if (eq n 1)
      ""
    "s"))

(defun picpocket-plural-its-their (n)
  (if (eq n 1)
      "its"
    "their"))



;;; Keystroke and keymap functions

(defun picpocket-read-key (what)
  (let* ((prompt (format "Type a keystroke to select %s (type ? for help): "
                         what))
         (key (read-key-sequence-vector prompt)))
    (cond ((equal key [7])
           (keyboard-quit))
          ((equal key [??])
           (picpocket-key-help what)
           (with-current-buffer picpocket-buffer
             (picpocket-read-key what)))
          (t (picpocket-lookup-key-strict key)))))

(defun picpocket-read-key-to-add-or-remove-tag (&optional remove all)
  (let* ((prompt
          (format "Type a keystroke to select tag to %s %s(type ? for help): "
                  (if remove "remove" "add")
                  (if all "to all pictures " "")))
         (key (read-key-sequence-vector prompt)))
    (cond ((equal key [7])
           (keyboard-quit))
          ((equal key [??])
           (picpocket-key-help (if remove
                                   "tag to remove"
                                 "tag to add"))
           (with-current-buffer picpocket-buffer
             (picpocket-read-key-to-add-or-remove-tag remove all)))
          ((equal key [?-])
           (picpocket-read-key-to-add-or-remove-tag (not remove) all))
          (t (list remove (picpocket-lookup-key-strict key))))))

(defun picpocket-lookup-key-strict (key)
  (or (picpocket-lookup-key key)
      (error "Keystroke %s is not defined in picpocket-keystroke-alist"
             (key-description key))))

(defun picpocket-lookup-key (x)
  (cl-loop for (key ignored arg) in (picpocket-keystroke-alist-nodups)
           when (equal (picpocket-key-vector x)
                       (picpocket-key-vector key))
           return arg))

(defun picpocket-keystroke-alist-nodups ()
  (let ((input (picpocket-keystroke-alist))
        (output nil))
    (while input
      (let* ((first-entry (car input))
             (first-key (car first-entry))
             (remaining-entries (cdr input)))
        (unless (assoc first-key remaining-entries)
          (setq output (cons first-entry output)))
        (setq input remaining-entries)))
    (reverse output)))


(defun picpocket-keystroke-alist ()
  (if (symbolp picpocket-keystroke-alist)
      (symbol-value picpocket-keystroke-alist)
    picpocket-keystroke-alist))

(defun picpocket-key-description (key)
  (key-description (picpocket-key-vector key)))

(defun picpocket-key-vector (key)
  (if (vectorp key)
      key
    (if (stringp key)
        (apply #'vector (listify-key-sequence (kbd key)))
      (vector key))))

(defun picpocket-keymap-to-list (prefix map)
  (let (list)
    (map-keymap (lambda (key binding)
                  (if (keymapp binding)
                      (setq list (append list (picpocket-keymap-to-list
                                               (vconcat prefix (vector key))
                                               binding)))
                    (let ((key-stroke (vconcat prefix (vector key))))
                      (and (eq (key-binding key-stroke) binding)
                           (not (eq binding 'undefined))
                           (not (eq binding 'remap))
                           (not (eq binding 'forward-button))
                           (not (get binding 'picpocket-user-command))
                           (push (cons key-stroke binding) list)))))
                map)
    list))

(defun picpocket-key-sort-string (keystroke)
  (cl-loop for key across keystroke
           concat (format "%10s%2s"
                          (event-basic-type key)
                          (picpocket-modifier-weigth key))))

(defun picpocket-modifier-weigth (key)
  (cl-loop for modifier in (event-modifiers key)
           sum (cl-case modifier
                 (shift 1)
                 (control 2)
                 (meta 4)
                 (super 8)
                 (t 0))))



(defun picpocket-update-keymap ()
  (picpocket-cleanup-keymap nil picpocket-mode-map)
  ;; Do not call picpocket-define-keymap here because that may
  ;; override user regular define-key settings.
  (cl-loop for (key action arg) in (picpocket-keystroke-alist)
           do (define-key picpocket-mode-map
                (picpocket-key-vector key)
                (cond ((memq action '(tag add-tag))
                       (intern arg picpocket-tag-completion-table)
                       (picpocket-user-tag-command arg))
                      ((memq action '(move copy hardlink))
                       (picpocket-user-file-command action arg))
                      ((symbolp action)
                       action)
                      (t
                       (error (concat "Invalid entry in"
                                      " picpocket-keystroke-alist"
                                      " (%s %s %s)")
                              key action arg)))))
  (when (buffer-live-p (get-buffer picpocket-buffer))
    (with-current-buffer picpocket-buffer
      (use-local-map picpocket-mode-map)))
  (setq picpocket-old-keystroke-alist (picpocket-keystroke-alist)))


(defvar picpocket-tmp-map nil)

(defun picpocket-cleanup-keymap (key value)
  (cond ((keymapp value)
         (let ((picpocket-tmp-map value))
           (map-keymap #'picpocket-cleanup-keymap value)))
        ((and (symbolp value)
              (get value 'picpocket-user-command)
              (characterp key))
         (define-key picpocket-tmp-map (vector key) #'undefined))))


(defun picpocket-user-tag-command (tag)
  "Create a command that add TAG to current picture."
  (let ((symbol (intern (picpocket-command-name 'add-tag tag))))
    (fset symbol `(lambda ()
                    ,(format "Add tag %s." tag)
                    (interactive)
                    (picpocket-command
                      (picpocket-action 'add-tag ,tag))))
    (put symbol 'picpocket-user-command 'add-tag)
    symbol))

(defun picpocket-user-file-command (action dst)
  "Create a command that move/copy/hardlink the current picture.
ACTION is one of the symbols move, copy or hardlink.
DST is the destination directory."
  (let ((symbol (intern (picpocket-command-name action dst))))
    (fset symbol `(lambda ()
                    ,(picpocket-command-doc action dst)
                    (interactive)
                    (picpocket-command
                      (picpocket-action ',action ,dst))))
    (put symbol 'picpocket-user-command 'file)
    symbol))

(defun picpocket-command-name (action arg)
  (pcase action
    ((or `add-tag `tag) (concat "picpocket-add-tag-" arg))
    (`move (concat "picpocket-move-to-" arg))
    (`copy (concat "picpocket-copy-to-" arg))
    (`hardlink (concat "picpocket-hardlink-to-" arg))
    (f (symbol-name f))))

(defun picpocket-command-doc (action dst)
  (format "%s image file to directory %s."
          (capitalize (symbol-name action))
          dst))

;;; Help functions

(defvar picpocket-help-count 0)
(defvar picpocket-is-sole-window nil)

(defvar picpocket-help-map
  (let ((map (make-sparse-keymap)))
    (define-key map [??] 'picpocket-help)
    map))

(defun picpocket-help ()
  "Toggle display of help for commands.

First invocation will display help for user defined commands if
there are any.  User defined commands are defined by setting the
variable `picpocket-keystroke-alist').

Second invocation will display help for built-in commands for
picpocket mode.

Third invocation will hide the help buffer."
  (interactive)
  ;; (picpocket-command
  (if (eq last-command this-command)
      (setq picpocket-help-count (1+ picpocket-help-count))
    (setq picpocket-help-count 0
          picpocket-is-sole-window (eq 1 (count-windows))))
  (if (picpocket-keystroke-alist)
      (pcase picpocket-help-count
        (0 (picpocket-help-user-commands)
           (picpocket-help-finish))
        (1 (picpocket-help-mode-commands)
           (picpocket-help-finish))
        (_ (setq picpocket-help-count -1)
           (picpocket-hide-help)))
    (pcase picpocket-help-count
      (0 (picpocket-help-mode-commands)
         (picpocket-help-finish))
      (_ (setq picpocket-help-count -1)
         (picpocket-hide-help)))))

(defun picpocket-help-finish ()
  (when picpocket-is-sole-window
    (with-selected-window (picpocket-visible-window (help-buffer))
      (picpocket-shrink-to-fit)))
  ;; This is only needed if help buffer was selected,
  ;; see `help-window-select'.
  (set-transient-map picpocket-help-map))

(defun picpocket-hide-help ()
  (let ((help (picpocket-visible-window (help-buffer))))
    (when help
      (if picpocket-is-sole-window
          (delete-window help)
        (with-selected-window help
          (quit-window))))))

(defun picpocket-visible-window (buffer-name)
  (cl-loop for window being the windows
           when (string-equal buffer-name
                              (buffer-name (window-buffer window)))
           return window))

(defun picpocket-visible-buffers ()
  (mapcar (lambda (window)
            (buffer-name (window-buffer window)))
          (window-list)))

(defun picpocket-shrink-to-fit ()
  (when (window-combined-p nil t)
    (shrink-window-horizontally (- (window-width) (picpocket-buffer-width) 1))))

(defun picpocket-buffer-width ()
  (save-excursion
    (goto-char (point-min))
    (cl-loop until (eobp)
             maximize (- (point-at-eol) (point-at-bol))
             do (forward-line 1))))


(defun picpocket-help-mode-commands ()
  (help-setup-xref (list #'picpocket-help-mode-commands)
                   (called-interactively-p 'interactive))
  (let ((mode major-mode)
        (map (current-local-map))
        (buffer (current-buffer)))
    (with-help-window (help-buffer)
      (with-current-buffer standard-output
        (princ (format "%s commands:\n\n" mode))
        (princ "key             binding\n")
        (princ "---             -------\n\n")
        (let ((commands (sort (with-current-buffer buffer
                                (picpocket-keymap-to-list nil map))
                              (lambda (a b)
                                (string-lessp
                                 (picpocket-key-sort-string (car a))
                                 (picpocket-key-sort-string (car b)))))))
          (cl-loop for (key . binding) in (seq-uniq commands)
                   do (when binding
                        (princ (format "%-16s" (key-description key)))
                        (if (eq binding 'picpocket-repeat)
                            (picpocket-repeat-help)
                          (princ (symbol-name binding)))
                        (princ "\n"))))))))



;; Help mode will make hyperlinks for all commands found at end of
;; line.  For picpocket-repeat we add stuff after command name so that
;; will not trigger.  Therefore make our own hyperlink for
;; picpocket-repeat.
(defun picpocket-repeat-help ()
  (insert-text-button "picpocket-repeat"
                      'type 'help-function
                      'help-args (list 'picpocket-repeat))
  (princ (format " (%s %s)" picpocket-last-action picpocket-last-arg)))


(defun picpocket-help-user-commands ()
  (help-setup-xref (list #'picpocket-help-user-commands)
                   (called-interactively-p 'interactive))
  (with-help-window (help-buffer)
    (princ "User defined picpocket commands:\n\n")
    (princ "key             binding\n")
    (princ "---             -------\n\n")
    (cl-loop for (key action arg) in (picpocket-keystroke-alist-nodups)
             do (princ (format "%-16s%s\n"
                               (key-description (picpocket-key-vector key))
                               (picpocket-command-name action arg))))))

(defun picpocket-key-help (&optional what)
  (help-setup-xref (list #'picpocket-key-help what)
                   (called-interactively-p 'interactive))
  (with-help-window (help-buffer)
    (setq what (or what "directory/tag"))
    (princ (format "key             %s\n" what))
    (princ (format "---             %s\n\n" (make-string (length what) ?-)))
    (when (string-equal what "tag to remove")
      (princ (format "-               add tag instead of remove\n")))
    (when (string-equal what "tag to add")
      (princ (format "-               remove tag instead of add\n")))
    (cl-loop for (key ignored arg) in (picpocket-keystroke-alist-nodups)
             do (princ (format "%-16s%s\n"
                               (key-description (picpocket-key-vector key))
                               arg)))))


;;; Undoable actions functions

;; To add a new undoable action update picpocket-undoable-actions,
;; picpocket-do-action, picpocket-undo-action, picpocket-undoable-text
;; and picpocket-op-image-file.


(defvar picpocket-undo-ewoc nil)
(defvar picpocket-undo-legend-ewoc nil)
;; (defvar picpocket-undo-window nil)
(defvar picpocket-current-undo-node nil)
(defvar picpocket-trashcan nil)



(cl-defstruct picpocket-undoable
  ;; State is the symbol incomplete, done or undone.
  state
  ;; Action is a symbol in the list picpocket-undoable-actions.
  action
  ;; Arg is a string dependant on action:
  ;;   add-tag    - tag
  ;;   remove-tag - tag
  ;;   set-tags   - space-separated tags
  ;;   delete     - nil
  ;;   rename     - new absolute filename (directory may be changed)
  ;;   move       - new absolute directory
  ;;   copy       - absolute destination directory
  ;;   hardlink   - absolute destination directory
  arg
  ;; If all is non-nil then the action is applied to all pictures in
  ;; the current picpocket list.
  all
  ;; ops is a list of picpocket-op structs.  Usually there is only a single
  ;; operation in this list.  But in case the all slot is non-nil
  ;; there will be one entry in this list per picture.
  ops)

(cl-defstruct picpocket-op
  action
  file
  sha
  to-file
  trash-file
  tags
  ;; tabulated-entry
  tag)

(cl-defstruct picpocket-legend
  key
  text
  predicate)

(defconst picpocket-undoable-actions '(add-tag
                                       remove-tag
                                       set-tags
                                       delete
                                       rename
                                       move
                                       copy
                                       hardlink
                                       delete-duplicate))
(defconst picpocket-repeatable-actions '(move
                                         copy
                                         hardlink
                                         add-tag
                                         remove-tag))

(unless (cl-subsetp picpocket-repeatable-actions picpocket-undoable-actions)
  (error "Some repeatable action is not undoable"))

(defun picpocket-action (action arg &optional pic)
  "All undoable actions go through this function.

A subset of the picpocket commands trigger undoable actions.
These are listed in the constant `picpocket-undoable-actions'.  ACTION
is a symbol from this list.

A subset of the undoable actions are repeatable.  These are
listed in the constant `picpocket-repeatable-actions'.  Repeatable
actions can be repeated with the command `picpocket-repeat'.

ARG is a string.  For file operations it is the destination
directory or filename.  For tag operations it is the tag or tags
separated with space.

PIC is the picture to work on.  It defaults to `picpocket-current'.
If PIC is the symbol `all' then the action is applied to all
pictures in the current picpocket list (this is not supported for
the delete action, though)."
  (unless (memq action picpocket-undoable-actions)
    (error "Action %s is not undoable" action))
  (picpocket-current-picture-check)
  (picpocket-stash-undo-begin :action action
                              :arg arg
                              :all (eq pic 'all))
  (if (eq pic 'all)
      (let ((pic picpocket-list)
            next)
        (while pic
          (setq next (cdr pic))
          (when (picpocket-filter-match-p pic)
            (picpocket-do-action action arg pic))
          (setq pic next)))
    (picpocket-current-picture-check)
    (picpocket-do-action action arg pic)
    (when (memq action picpocket-repeatable-actions)
      (picpocket-save-repeatable-action action arg)))
  (picpocket-stash-undo-end))

(defun picpocket-save-repeatable-action (action arg)
  (setq picpocket-last-action action
        picpocket-last-arg arg))

;; Currently single pic actions print message here.
;; PENDING - Move the message calls to the sub-routines....
;; Callers of picpocket-action with 'all also print a summary
;; message when all pictures are handled.
;; PENDING - (funcall (intern (concat "picpocket-" action "-action"))) ?
;; or some CL voodoo?
;; or a table with all information in one place:
;; ((set-tags picpocket-set-tags-action nil)
;; (add-tag picpocket-add-tag-action picpocket-undo-add-tag-action
;; picpocket-print-add-tag)...)
(defun picpocket-do-action (action arg pic)
  (pcase action
    (`set-tags
     (picpocket-set-tags-action arg pic)
     (picpocket-tags-message pic))
    (`add-tag
     (picpocket-add-tag-action arg pic)
     (message "%s is tagged with %s" (picpocket-file pic) arg))
    (`remove-tag
     (picpocket-remove-tag-action arg pic)
     (message "Tag %s is removed from %s" arg (picpocket-file pic)))
    (`delete
     (when (eq 'all pic)
       (error "Refusing to delete all pictures"))
     (let ((file (picpocket-file pic)))
       (picpocket-delete-action pic)
       (message "%s is deleted, type `%s' to undo"
                file
                (picpocket-where-is #'picpocket-undo))))
    ((or `move `rename `copy `hardlink)
     (picpocket-file-action action arg pic))
    (`delete-duplicate
     (picpocket-delete-duplicate-action arg pic))
    (_
     (error "Unknown action %s %s" action arg))))

(defvar picpocket-undo-fail nil)
(defvar picpocket-undo-ok nil)

(defun picpocket-undo-action (undoable)
  (unless (picpocket-undoable-is-undoable-p undoable)
    (error "Action is not undoable"))
  (let (picpocket-undo-fail picpocket-undo-ok)
    (dolist (op (picpocket-undoable-ops undoable))
      (picpocket-undo-op op))
    (cond ((and (null picpocket-undo-fail) (null picpocket-undo-ok))
           (message "Nothing to undo")
           (setf (picpocket-undoable-state undoable) 'undone))
          ((null picpocket-undo-fail)
           (message "Undo ok %s"
                    (picpocket-undo-summary picpocket-undo-ok))
           (setf (picpocket-undoable-state undoable) 'undone))
          ((null picpocket-undo-ok)
           (message "Undo failed %s"
                    (picpocket-undo-summary picpocket-undo-fail)))
          (t
           (message "Undo partly failed (%s actions failed, %s actions ok)"
                    (length picpocket-undo-fail)
                    (length picpocket-undo-ok))
           (setf (picpocket-undoable-state undoable) 'incomplete)))))

(defun picpocket-undo-op (op)
  (pcase (picpocket-op-action op)
    (`delete (picpocket-undo-delete-action op))
    (`add-tag (picpocket-undo-add-tag-action op))
    (`remove-tag (picpocket-undo-remove-tag-action op))
    ((or `rename `move) (picpocket-undo-file-relocate-action op))
    ((or `copy `hardlink) (picpocket-undo-file-duplicate-action op))
    (`delete-duplicate (picpocket-undo-delete-duplicate-action op))))

(defun picpocket-undo-summary (list)
  (if (cdr list)
      (format "(%s actions)" (length list))
    (format "(%s)" (car list))))

(defun picpocket-undo-fail (format &rest args)
  (let ((text (apply #'format format args)))
    (message text)
    (warn text)
    (push text picpocket-undo-fail)))

(defun picpocket-undo-ok (format &rest args)
  (let ((text (apply #'format format args)))
    (message text)
    (push text picpocket-undo-ok)))



(defun picpocket-delete-action (pic)
  (let ((inhibit-quit t)
        (file (picpocket-absfile pic))
        (filter-match (picpocket-filter-match-p pic))
        (trash-file (picpocket-trash-file (picpocket-file pic))))
    (picpocket-stash-undo-op :action 'delete
                             :file (picpocket-absfile pic)
                             :tags (picpocket-tags pic)
                             :trash-file trash-file)
    (picpocket-sha-force pic)
    (rename-file file trash-file)
    (picpocket-tags-delete-file pic file)
    (picpocket-list-delete pic (list filter-match))))


(defun picpocket-undo-delete-action (op)
  (let ((trash-file (picpocket-op-trash-file op))
        (file (picpocket-op-file op))
        (tags (picpocket-op-tags op))
        (inhibit-quit t))
    (if (not (file-exists-p trash-file))
        (picpocket-undo-fail "Cannot undelete %s, %s does not exist"
                             (file-name-nondirectory file)
                             trash-file)
      (make-directory (file-name-directory file) t)
      (rename-file trash-file file)
      (picpocket-list-insert-before-current (picpocket-make-pic file))
      (picpocket-tags-set picpocket-current tags)
      (picpocket-undo-ok "Undeleted %s" (file-name-nondirectory file)))))

(defun picpocket-trash-file (filename)
  (setq filename (file-name-nondirectory filename))
  (unless picpocket-trashcan
    (setq picpocket-trashcan (file-name-as-directory
                              (make-temp-file "picpocket-trash" t))))
  (make-directory picpocket-trashcan t)
  (cl-loop for i = 1 then (1+ i)
           for f = (picpocket-trash-file-candidate filename i)
           unless (file-exists-p f)
           return f))

(defun picpocket-trash-file-candidate (filename i)
  (if (eq i 1)
      (expand-file-name filename picpocket-trashcan)
    (concat picpocket-trashcan
            (file-name-sans-extension filename)
            "_"
            (number-to-string i)
            (if (file-name-extension filename) "." "")
            (file-name-extension filename))))


(defun picpocket-add-tag-action (tag-string &optional pic)
  (let* ((pic (or pic picpocket-current))
         (tag (intern tag-string))
         (tags (picpocket-tags pic))
         (inhibit-quit t))
    (unless (memq tag tags)
      (picpocket-tags-set pic (append tags (list tag)))
      (picpocket-stash-undo-op :action 'add-tag
                               :file (picpocket-absfile pic)
                               :sha (picpocket-sha-force pic)
                               :tag tag))))

(defun picpocket-undo-add-tag-action (op)
  (let* ((file (picpocket-op-file op))
         (tag (picpocket-op-tag op))
         (sha (picpocket-op-sha op))
         (current-tags (picpocket-db-tags sha)))
    (when (memq tag current-tags)
      (picpocket-db-tags-set sha file (delq tag current-tags))
      (picpocket-reset-filter-counters))
    (picpocket-undo-ok "Undo add tag %s to %s"
                       tag
                       (file-name-nondirectory file))))

(defun picpocket-remove-tag-action (tag-string &optional pic)
  (let* ((pic (or pic picpocket-current))
         (tag (intern tag-string))
         (tags (picpocket-tags pic))
         (inhibit-quit t))
    (when (memq tag tags)
      (picpocket-tags-set pic (delq tag tags))
      (picpocket-stash-undo-op :action 'remove-tag
                               :file (picpocket-absfile pic)
                               :sha (picpocket-sha-force pic)
                               :tag tag))))

(defun picpocket-undo-remove-tag-action (op)
  (let* ((file (picpocket-op-file op))
         (tag (picpocket-op-tag op))
         (sha (picpocket-op-sha op))
         (current-tags (picpocket-db-tags sha)))
    (unless (memq tag current-tags)
      (picpocket-db-tags-set sha file (append current-tags (list tag)))
      (picpocket-reset-filter-counters))
    (picpocket-undo-ok "Undo remove tag %s from %s"
                       tag
                       (file-name-nondirectory file))))

(defun picpocket-set-tags-action (tags-string pic)
  (let* ((pic (or pic picpocket-current))
         (old-tags (picpocket-tags pic))
         (new-tags (picpocket-tags-string-to-list tags-string))
         (inhibit-quit t))
    (picpocket-tags-set pic new-tags)
    (dolist (tag (cl-set-difference old-tags new-tags))
      (picpocket-stash-undo-op :action 'remove-tag
                               :file (picpocket-absfile pic)
                               :sha (picpocket-sha-force pic)
                               :tag tag))
    (dolist (tag (cl-set-difference new-tags old-tags))
      (picpocket-stash-undo-op :action 'add-tag
                               :file (picpocket-absfile pic)
                               :sha (picpocket-sha-force pic)
                               :tag tag))))


(defun picpocket-tags-string-to-list (tags-string)
  (cl-delete-duplicates
   (mapcar #'intern
           (split-string tags-string))))

(defun picpocket-new-absfile-for-file-action (action dst pic)
  (file-truename
   (if (eq action 'rename)
       dst
     (expand-file-name (picpocket-file pic)
                       (if (or (file-name-absolute-p dst)
                               picpocket-destination-relative-current)
                           dst
                         (expand-file-name dst picpocket-destination-dir))))))

(defun picpocket-file-action (action dst pic)
  (let* ((pic (or pic picpocket-current))
         (new-absfile (picpocket-new-absfile-for-file-action action dst pic))
         (old-dir (picpocket-dir pic))
         (old-file (picpocket-file pic))
         (old-absfile (concat old-dir old-file))
         (new-dir (file-name-directory new-absfile))
         (new-file (file-name-nondirectory new-absfile))
         (ok-if-already-exists noninteractive))
    (make-directory new-dir t)
    (while (and (file-exists-p new-absfile)
                (not ok-if-already-exists))
      (cond ((equal old-absfile new-absfile)
             (user-error "Attempt to %s file to itself"
                         (symbol-name action)))
            ((file-directory-p new-absfile)
             (error "%s already exists as a directory" new-absfile))
            ((picpocket-files-identical-p old-absfile new-absfile)
             (if (y-or-n-p (concat "Identical file already exists in "
                                   new-dir ".  Overwrite? "))
                 (setq ok-if-already-exists t)
               (user-error "Not overwriting %s" new-absfile)))
            (t
             (setq new-file (picpocket-compare pic new-absfile)
                   new-absfile (concat new-dir new-file)))))
    (pcase action
      ((or `move `rename)
       (picpocket-file-relocate-action action old-absfile new-absfile pic))
      ((or `copy `hardlink)
       (picpocket-file-duplicate-action action old-absfile new-absfile pic))
      (_ (error "Invalid picpocket action %s" action)))))

(defun picpocket-files-identical-p (a b)
  (and (file-exists-p a)
       (file-exists-p b)
       (let ((a-bytes (picpocket-file-bytes a))
             (b-bytes (picpocket-file-bytes b)))
         (eq a-bytes b-bytes))
       (if (executable-find "diff")
           (zerop (call-process "diff" nil nil nil "-q"
                                (expand-file-name a)
                                (expand-file-name b)))
         (picpocket-elisp-files-identical-p a b))))

(defun picpocket-elisp-files-identical-p (a b)
  (string-equal (picpocket-file-content a)
                (picpocket-file-content b)))

(defun picpocket-file-content (file)
  (with-temp-buffer
    (buffer-disable-undo)
    (insert-file-contents-literally file)
    (buffer-substring-no-properties (point-min) (point-max))))

(defun picpocket-file-relocate-action (action old-absfile new-absfile pic)
  (let ((new-dir (file-name-directory new-absfile))
        (new-file (file-name-nondirectory new-absfile))
        (old-dir (file-name-directory old-absfile))
        (old-file (file-name-nondirectory old-absfile))
        (inhibit-quit t)
        trash-file)
    (when (file-exists-p new-absfile)
      (setq trash-file (picpocket-trash-file new-file))
      (rename-file new-absfile trash-file))
    (picpocket-stash-undo-op :action action
                             :file old-absfile
                             :to-file new-absfile
                             :trash-file trash-file
                             :sha (picpocket-sha-force pic))
    (picpocket-sha-force pic)
    (rename-file old-absfile new-absfile t)
    (picpocket-tags-move-file pic old-absfile new-absfile)
    (cond ((or (eq action 'move)
               (equal old-file new-file))
           (picpocket-list-delete pic)
           (message "Moved %s to %s"
                    (file-name-nondirectory old-absfile)
                    (file-name-directory new-absfile)))
          ((equal old-dir new-dir)
           (picpocket-set-file pic new-file)
           (message "Renamed %s to %s" old-file new-file))
          (t
           (picpocket-list-delete pic)
           (message "Renamed and moved %s to %s" old-file new-absfile)))))

(defun picpocket-undo-file-relocate-action (op)
  (let ((file (picpocket-op-file op))
        (to-file (picpocket-op-to-file op))
        (trash-file (picpocket-op-trash-file op))
        (sha (picpocket-op-sha op))
        (inhibit-quit t))
    (cond ((not (file-exists-p to-file))
           (picpocket-undo-fail "Cannot undo %s, %s does not exist"
                                (picpocket-op-action op)
                                to-file))
          ((file-exists-p file)
           (picpocket-undo-fail "Cannot undo %s, %s already exist"
                                (picpocket-op-action op)
                                file))
          (t
           (make-directory (file-name-directory file) t)
           (rename-file to-file file)
           (picpocket-db-tags-move-file sha to-file file)
           (when trash-file
             (rename-file trash-file to-file))
           (let ((pic (picpocket-list-search to-file)))
             (if pic
                 (picpocket-set-absfile pic file)
               (picpocket-list-insert-before-current (picpocket-make-pic
                                                      file))))
           (picpocket-undo-ok "%s %s back"
                              (picpocket-action-past-tense
                               (picpocket-op-action op))
                              (file-name-nondirectory file))))))

(defun picpocket-file-duplicate-action (action old-absfile new-absfile pic)
  (let ((old-file (file-name-nondirectory old-absfile))
        (inhibit-quit t)
        trash-file)
    (picpocket-tags-copy-file picpocket-current new-absfile)
    (when (file-exists-p new-absfile)
      (setq trash-file (picpocket-trash-file new-absfile))
      (rename-file new-absfile trash-file))
    (if (eq action 'copy)
        (copy-file old-absfile new-absfile t)
      (add-name-to-file old-absfile new-absfile t))
    (picpocket-stash-undo-op :action action
                             :file old-absfile
                             :to-file new-absfile
                             :trash-file trash-file
                             :sha (picpocket-sha-force pic))
    (picpocket-duplicate-message action old-file new-absfile)))

(defun picpocket-undo-file-duplicate-action (op)
  (let ((to-file (picpocket-op-to-file op))
        (trash-file (picpocket-op-trash-file op))
        (sha (picpocket-op-sha op))
        (inhibit-quit t))
    (cond ((not (file-exists-p to-file))
           (picpocket-undo-fail "Cannot undo %s, %s does not exist"
                                (picpocket-op-action op)
                                to-file))
          (t
           (delete-file to-file)
           (when trash-file
             (rename-file trash-file to-file))
           (picpocket-db-tags-delete-file sha to-file)
           (if (eq 'copy (picpocket-op-action op))
               (picpocket-undo-ok "Uncopied %s"
                                  (file-name-nondirectory to-file))
             (picpocket-undo-ok "Un-hard-linked %s"
                                (file-name-nondirectory to-file)))))))

(defun picpocket-duplicate-message (action old dst)
  (message "%s %s to %s"
           (if (eq action 'copy)
               "Copied"
             "Hard linked")
           old
           dst))

(defun picpocket-compare (pic new-absfile)
  (unwind-protect
      (let (picpocket-adapt-to-window-size-change)
        (picpocket-show-two-pictures pic new-absfile)
        (read-string (format (concat "File already exists (size %s)."
                                     "  Rename this (size %s) to: ")
                             (picpocket-kb (picpocket-file-bytes new-absfile))
                             (picpocket-kb (picpocket-bytes-force pic)))
                     (picpocket-file pic)))
    (picpocket-update-main-buffer)))

(defun picpocket-show-two-pictures (pic new)
  (picpocket-ensure-picpocket-buffer)
  (cl-destructuring-bind (window-width . window-height)
      (picpocket-save-window-size)
    (let* ((line-height (+ (frame-char-height)
                           (or line-spacing
                               (frame-parameter nil 'line-spacing)
                               0)))
           (pic-height (/ (- window-height (* 2 line-height)) 2))
           (picpocket-fit (picpocket-standard-value 'picpocket-fit))
           (picpocket-scale (picpocket-standard-value 'picpocket-scale))
           buffer-read-only)
      (erase-buffer)
      (insert (format "About to overwrite this picture (%s):\n"
                      (picpocket-kb (picpocket-file-bytes new))))
      (insert-image (picpocket-create-image (list (picpocket-make-pic new))
                                            (cons window-width pic-height)))
      (insert (format "\nWith this picture (%s):\n"
                      (picpocket-kb (picpocket-bytes-force pic))))
      (insert-image (picpocket-create-image pic (cons window-width pic-height)))
      (goto-char (point-min)))))

(defun picpocket-standard-value (symbol)
  (eval (car (get symbol 'standard-value))))


;;; Undo commands

(defun picpocket-undo ()
  "Undo last command.
\\<picpocket-mode-map>
Most commands are undoable.  All commands that delete, move, copy
or hardlink files are undoable.  Also all commands that adds or
removes tags.  This includes commands that have been defined by
the user customizing variable `picpocket-keystroke-alist'.

Navigational commands and commands that affect the
display (rotation and scaling) are not undoable.

The last `picpocket-undo-list-size' undoable commands are saved.  Type
\\[picpocket-visit-undo-list] to view a list of them in a special
buffer.  In that buffer it is possible to select and undo any
command in the list.

This command picks the first undoable command in that list."
  (interactive)
  ;; (picpocket-command
  (let ((undoable (when picpocket-undo-ring
                    (cl-loop for i from 0 to (ring-length picpocket-undo-ring)
                             for undoable = (ring-ref picpocket-undo-ring i)
                             while undoable
                             when (picpocket-undoable-is-undoable-p undoable)
                             return undoable))))
    (if undoable
        (progn
          (picpocket-undo-action undoable)
          (picpocket-update-buffers))
      (user-error "No undoable actions have been done"))))


(defun picpocket-undoable-is-undoable-p (undoable)
  (memq (picpocket-undoable-state undoable)
        '(done incomplete)))

(defun picpocket-visit-undo-list ()
  "List the current undoable commands in a separate buffer."
  (interactive)
  (picpocket-with-singleton-buffer picpocket-undo-buffer
    (picpocket-undo-mode)
    (picpocket-update-undo-buffer)))




;;; Undo stash functions

(defun picpocket-stash-undo-begin (&rest args)
  (unless picpocket-undo-ring
    (setq picpocket-undo-ring (make-ring picpocket-undo-list-size)))
  (picpocket-maybe-grow-undo-ring)
  (picpocket-remove-empty-incomplete-entries)
  (picpocket-remove-one-if-stash-is-full)
  (ring-insert picpocket-undo-ring
               (apply #'make-picpocket-undoable
                      :state 'incomplete
                      args)))

;; Grow if needed, but in contrast the ring is never shrinked
;; dynamically.
(defun picpocket-maybe-grow-undo-ring ()
  (let ((size (ring-size picpocket-undo-ring)))
    (when (> picpocket-undo-list-size size)
      (ring-extend picpocket-undo-ring (- picpocket-undo-list-size size)))))

(defun picpocket-remove-empty-incomplete-entries ()
  (while (let ((newest (and (not (ring-empty-p picpocket-undo-ring))
                            (ring-ref picpocket-undo-ring 0))))
           (and newest
                (eq (picpocket-undoable-state newest) 'incomplete)
                (null (picpocket-undoable-ops newest))))
    (picpocket-cleanup-undo-entry (ring-remove picpocket-undo-ring 0))))

(defun picpocket-remove-one-if-stash-is-full ()
  (when (= (ring-length picpocket-undo-ring)
           (ring-size picpocket-undo-ring))
    (picpocket-cleanup-undo-entry (ring-remove picpocket-undo-ring))))

(defun picpocket-cleanup-undo-entry (undo)
  (dolist (op (picpocket-undoable-ops undo))
    (and (picpocket-op-trash-file op)
         (file-exists-p (picpocket-op-trash-file op))
         (delete-file (picpocket-op-trash-file op)))))

(defun picpocket-stash-undo-op (&rest args)
  (when (or (null picpocket-undo-ring)
            (ring-empty-p picpocket-undo-ring))
    (error "Call to picpocket-stash-undo-op before picpocket-stash-undo-begin"))
  (push (apply #'make-picpocket-op args)
        (picpocket-undoable-ops (ring-ref picpocket-undo-ring 0))))

(defun picpocket-stash-undo-end ()
  (let ((current-undo (ring-ref picpocket-undo-ring 0)))
    (setf (picpocket-undoable-ops current-undo)
          (reverse (picpocket-undoable-ops current-undo)))
    (setf (picpocket-undoable-state current-undo) 'done)))




;;; The undo buffer's ewoc population

;; There are two ewocs in the undo buffer.
;;
;; One is called picpocket-legend-ewoc and shows a legend for the available
;; commands in the undo-buffer.  The node data is instances of the
;; struct picpocket-undo-legend.  The text for a command is dimmed out if
;; it is not appropriate for the thing at point.
;;
;; The other is called picpocket-undo-ewoc and shows the list of undoable
;; things.  The node data is instances of the struct picpocket-undoable.  It is
;; a mirror of the picpocket-undo-ring - it contain the same data in the
;; same order.  Whenever a command alter the picpocket-undo-ring the
;; picpocket-undo-ewoc will be rebuilt from scratch (the picpocket-command macro
;; takes care of that).

(defun picpocket-update-undo-buffer ()
  (with-current-buffer picpocket-undo-buffer
    (let ((progress nil)
          (i 0)
          (start-time (current-time))
          (buffer-read-only nil))
      (erase-buffer)
      (insert "\n"
              (picpocket-emph "Picpocket undo buffer")
              "\n")
      (setq picpocket-undo-legend-ewoc (ewoc-create #'picpocket-undo-legend-pp))
      (picpocket-undo-legend-add "u"
                                 "undo an entry"
                                 #'picpocket-current-undoable-p)
      (picpocket-undo-legend-add "n"
                                 "move to next entry"
                                 #'picpocket-current-have-next-p)
      (picpocket-undo-legend-add "p"
                                 "move to previous entry"
                                 #'picpocket-current-have-previous-p)
      (picpocket-undo-legend-add "q"
                                 "return to picpocket buffer"
                                 #'picpocket-true)
      (goto-char (point-max))
      (insert "List of undoable actions with the most recent first:\n\n")
      (setq picpocket-current-undo-node nil
            picpocket-undo-ewoc (ewoc-create #'picpocket-undo-pp
                                             nil nil t))
      (if (or (null picpocket-undo-ring)
              (ring-empty-p picpocket-undo-ring))
          (insert "\n(There is nothing to undo)")
        (dolist (undoable (ring-elements picpocket-undo-ring))
          (ewoc-enter-last picpocket-undo-ewoc undoable)
          (cl-incf i)
          (when (picpocket-more-than-half-a-second-since-p start-time)
            (setq progress (or progress (make-progress-reporter
                                         "Making undo buffer "
                                         0
                                         (ring-length picpocket-undo-ring))))
            (progress-reporter-update progress i))))
      (picpocket-init-current-undo)
      (picpocket-update-current-undo)
      (when progress
        (progress-reporter-done progress)))))

(defun picpocket-more-than-half-a-second-since-p (time)
  (time-less-p (seconds-to-time 0.5)
               (time-subtract (current-time) time)))


(defun picpocket-undo-pp (undoable)
  (insert (if (and picpocket-current-undo-node
                   (eq undoable (ewoc-data picpocket-current-undo-node)))
              (picpocket-emph " -> ")
            "    ")
          (capitalize (symbol-name (picpocket-undoable-state undoable)))
          " action: "
          (picpocket-undoable-text undoable))
  (insert "\n      ")
  (let ((ops (picpocket-undoable-ops undoable)))
    (cl-loop for i from 0 to (1- picpocket-max-undo-thumbnails)
             for op = (elt ops i)
             while op
             do (picpocket-undo-thumbnail undoable op)
             do (insert " "))
    (when (elt ops picpocket-max-undo-thumbnails)
      (insert "....")))
  (insert "\n")
  (insert (propertize "\n" 'line-height 1.5)))


(defun picpocket-undo-thumbnail (undoable &optional op)
  (let ((op (or op (car (picpocket-undoable-ops undoable)))))
    (picpocket-insert-thumbnail (picpocket-op-image-file undoable op))))

(defun picpocket-insert-thumbnail (file)
  (and (display-images-p)
       file
       (file-exists-p file)
       (insert-image (picpocket-create-thumbnail file))))

;; PENDING - could provide :thumbnail-file to picpocket-stash-undo-op instead.
(defun picpocket-op-image-file (undoable op)
  (if (eq (picpocket-undoable-state undoable) 'undone)
      (picpocket-op-file op)
    (pcase (picpocket-undoable-action undoable)
      ((or `set-tags `add-tag `remove-tag) (picpocket-op-file op))
      (`delete (picpocket-op-trash-file op))
      (`delete-duplicate (picpocket-op-trash-file op))
      (_ (picpocket-op-to-file op)))))


(defconst picpocket-empty-op (make-picpocket-op :file "nothing"))

(defun picpocket-undoable-text (undoable)
  (let* ((action (picpocket-undoable-action undoable))
         (arg (picpocket-undoable-arg undoable))
         (ops (picpocket-undoable-ops undoable))
         (first-op (or (car ops) picpocket-empty-op))
         (file (if (picpocket-undoable-all undoable)
                   (format "all %s pictures" (length ops))
                 (file-name-nondirectory (picpocket-op-file first-op)))))
    (pcase action
      (`set-tags (concat "set tags to "
                         (picpocket-format-tags arg)
                         " on "
                         file))
      (`add-tag (concat "add tag "
                        arg
                        " to "
                        file))
      (`remove-tag (concat "remove tag "
                           arg
                           " from "
                           file))
      (`delete (concat "delete " file))
      (`delete-duplicate (concat "delete duplicate " file))
      (_ (concat (symbol-name action)
                 " "
                 file
                 " to "
                 arg)))))


(defun picpocket-undo-legend-add (key text predicate)
  (ewoc-enter-last picpocket-undo-legend-ewoc
                   (make-picpocket-legend :key key
                                          :text text
                                          :predicate predicate)))

(defun picpocket-current-have-previous-p (current)
  (and current
       (not (eq current
                (picpocket-first-undo-node)))))

(defun picpocket-current-have-next-p (current)
  (and current
       (not (eq current
                (picpocket-last-undo-node)))))

(defun picpocket-current-undoable-p (current)
  (and current
       (memq (picpocket-undoable-state (ewoc-data current))
             '(done incomplete))))

(defun picpocket-current-redoable-p (current)
  (and current
       (eq (picpocket-undoable-state (ewoc-data current))
           'undone)))

(defun picpocket-true (&rest ignored)
  t)

(defun picpocket-undo-legend-pp (legend)
  (let ((valid (funcall (picpocket-legend-predicate legend)
                        picpocket-current-undo-node)))
    (insert (propertize (concat "  Type "
                                (if valid
                                    (picpocket-emph (picpocket-legend-key
                                                     legend))
                                  (picpocket-legend-key legend))
                                " to "
                                (picpocket-legend-text legend)
                                ".")
                        'font-lock-face
                        (if valid
                            'default
                          'picpocket-dim-face)))))


(defun picpocket-init-current-undo ()
  (setq picpocket-current-undo-node (picpocket-first-undo-node)))

(defun picpocket-update-current-undo ()
  (when picpocket-current-undo-node
    (ewoc-invalidate picpocket-undo-ewoc picpocket-current-undo-node)
    (ewoc-goto-node picpocket-undo-ewoc picpocket-current-undo-node))
  (save-excursion
    (ewoc-refresh picpocket-undo-legend-ewoc)))

(defun picpocket-first-undo-node ()
  (ewoc-nth picpocket-undo-ewoc 0))

(defun picpocket-last-undo-node ()
  (ewoc-nth picpocket-undo-ewoc -1))

(defun picpocket-ewoc-find-node (ewoc data)
  (cl-loop for i = 0 then (1+ i)
           for node = (ewoc-nth ewoc i)
           while node
           when (eq data (ewoc-data node))
           return node))


;;; The undo buffer's commands

(define-derived-mode picpocket-undo-mode picpocket-base-mode "picpocket-undo"
  "Major mode for picpocket undo buffer.

\\{picpocket-undo-mode-map}")

(let ((map (make-sparse-keymap)))
  (suppress-keymap map)
  (define-key map [?u] #'picpocket-undo-undo)
  (define-key map [?n] #'picpocket-undo-next)
  (define-key map [?p] #'picpocket-undo-previous)
  (define-key map [return] #'picpocket-select-undo-entry-at-point)
  (define-key map [?q] #'picpocket-undo-quit)
  (setq picpocket-undo-mode-map map))

(defun picpocket-undo-undo ()
  "Undo the current action."
  (interactive)
  (unless picpocket-current-undo-node
    (picpocket-select-undo-entry-at-point))
  (unless picpocket-current-undo-node
    (error "No action available"))
  (picpocket-undo-action (ewoc-data picpocket-current-undo-node))
  (picpocket-update-the-main-buffer)
  (ewoc-invalidate picpocket-undo-ewoc picpocket-current-undo-node))

(defun picpocket-select-undo-entry-at-point ()
  "Select the action at point."
  (interactive)
  (picpocket-undo-move 0))

(defun picpocket-undo-next ()
  "Move forward to next action."
  (interactive)
  (picpocket-undo-move 1))

(defun picpocket-undo-previous ()
  "Move backward to previous action."
  (interactive)
  (picpocket-undo-move -1))

(defun picpocket-undo-move (direction)
  (unless (picpocket-first-undo-node)
    (error "No undoable or redoable actions available"))
  (let ((old-node picpocket-current-undo-node))
    (setq picpocket-current-undo-node nil)
    (when old-node
      (ewoc-invalidate picpocket-undo-ewoc old-node)))
  (pcase direction
    (-1 (ewoc-goto-prev picpocket-undo-ewoc 1))
    (1 (ewoc-goto-next picpocket-undo-ewoc 1)))
  (setq picpocket-current-undo-node (ewoc-locate picpocket-undo-ewoc))
  (picpocket-update-current-undo)
  (picpocket-show-legend-at-top))

(defun picpocket-show-legend-at-top ()
  (when (eq picpocket-current-undo-node (picpocket-first-undo-node))
    (recenter)))

(defun picpocket-undo-quit ()
  "Delete the undo buffer and go back to the picpocket buffer."
  (interactive)
  ;; Kill the undo buffer so we don't have to refresh it while it is
  ;; buried.
  (quit-window 'kill))



;;; Header line functions

(defun picpocket-header-line ()
  (if (eq (selected-frame) picpocket-frame)
      (picpocket-fullscreen-header-line)
    (picpocket-header-pic-info)))

(defun picpocket-fullscreen-header-line ()
  (concat (picpocket-header-pic-info)
          (let ((msg (picpocket-escape-percent (current-message))))
            (if msg
                (concat " - " msg)
              ""))))

(defun picpocket-header-pic-info ()
  (and picpocket-current
       picpocket-list
       picpocket-db
       (picpocket-join
        (concat (format "%s/%s "
                        picpocket-index
                        picpocket-list-length)
                (picpocket-escape-percent (picpocket-header-dir))
                "/"
                (propertize
                 (picpocket-escape-percent (picpocket-file))
                 'face 'picpocket-header-file)
                (propertize
                 (if (picpocket-multiple-identical-exists-p picpocket-current)
                     "+"
                   "")
                 'help-echo
                 "There are multiple identical copies of this files"))
        (when picpocket-debug
          picpocket-header-text)
        (picpocket-maybe-kb)
        (picpocket-scale-info)
        (picpocket-rotation-info)
        (picpocket-format-tags (picpocket-tags picpocket-current)
                               (cl-set-difference (picpocket-dir-tags
                                                   picpocket-current)
                                                  (picpocket-tags
                                                   picpocket-current)))
        (picpocket-filter-info)
        (picpocket-destination-dir-info)
        (when picpocket-idle-f-header-info
          (picpocket-idle-f-info)))))

(defun picpocket-join (&rest strings)
  (mapconcat 'identity
             (delete nil (delete "" strings))
             " "))

(defun picpocket-escape-percent (string)
  (when string
    (replace-regexp-in-string "%" "%%" string)))

(defun picpocket-header-dir ()
  (if picpocket-header-full-path
      ;; abbreviate-file-name substitutes the users home directory
      ;; with "~".  This do not work if the home directory is a
      ;; symbolic link.  That case is fixed by appending to
      ;; directory-abbrev-alist here.
      (let ((directory-abbrev-alist
             (append directory-abbrev-alist
                     (list (cons (file-truename "~")
                                 (getenv "HOME"))))))
        (abbreviate-file-name (directory-file-name (picpocket-dir))))
    (file-name-nondirectory (directory-file-name (picpocket-dir)))))

(defun picpocket-multiple-identical-exists-p (pic)
  (cl-loop for file in (picpocket-all-files pic)
           with count = 0
           when (file-exists-p file) do (cl-incf count)
           when (> count 1) return t))

(defun picpocket-maybe-kb ()
  (let ((bytes (picpocket-bytes picpocket-current)))
    (if bytes
        (picpocket-kb bytes)
      "")))


(defun picpocket-bytes-force (pic)
  (or (picpocket-bytes pic)
      (picpocket-save-bytes-in-pic pic)))

(defun picpocket-save-bytes-in-pic (pic)
  (picpocket-set-bytes pic (picpocket-file-bytes (picpocket-absfile pic))))

(defun picpocket-file-bytes (file)
  (let ((attributes (file-attributes file)))
    (if attributes
        (elt attributes 7)
      (error "File %s do not exist" file))))

(defun picpocket-kb (bytes)
  (if (<= 1024 bytes)
      (format "%sk" (/ bytes 1024))
    (format "%s" bytes)))

(defun picpocket-scale-info ()
  (unless (eq picpocket-scale 100)
    (format "%s%%%%" picpocket-scale)))

(defun picpocket-rotation-info ()
  (let ((degrees (picpocket-rotation picpocket-current)))
    (unless (zerop degrees)
      (format "%s°" (truncate degrees)))))

(defun picpocket-format-tags (tags &optional dir-tags)
  (when (stringp tags)
    (setq tags (picpocket-tags-string-to-list tags)))
  (unless picpocket-consider-dir-as-tag
    (setq dir-tags nil))
  (when (stringp dir-tags)
    (setq dir-tags (picpocket-tags-string-to-list dir-tags)))
  (when (or tags dir-tags)
    (cl-case picpocket-tags-style
      (:org (picpocket-do-format-tag ":%s%s%s:" ":" tags dir-tags))
      (t (picpocket-do-format-tag "(%s%s%s)" " " tags dir-tags)))))

(defun picpocket-do-format-tag (format-string delim tags &optional dir-tags)
  (format format-string
          (mapconcat #'symbol-name tags delim)
                 (if (and tags dir-tags) delim "")
                 (propertize (mapconcat #'symbol-name dir-tags delim)
                             'face 'picpocket-dir-tags-face)))

(defun picpocket-tags-string (pic)
  (or (picpocket-format-tags (picpocket-tags pic)) "-"))

(defun picpocket-dir-tags-string (pic)
  (or (picpocket-format-tags nil (picpocket-dir-tags pic)) "-"))

(defun picpocket-filter-info ()
  (when picpocket-filter
    (format "[filter: %s %s/%s]"
            (picpocket-format-tags picpocket-filter)
            (or (picpocket-filter-index) "?")
            (or (picpocket-filter-match-count) "?"))))

;;; Hook functions

(defun picpocket-cleanup-most-hooks ()
  (remove-hook 'window-size-change-functions
               #'picpocket-window-size-change-function)
  (remove-hook 'buffer-list-update-hook
               #'picpocket-maybe-update-keymap)
  (remove-hook 'buffer-list-update-hook
               #'picpocket-maybe-rescale)
  ;; PENDING use after-focus-change-function instead...?
  (with-no-warnings
    (remove-hook 'focus-in-hook
                 #'picpocket-focus))
  (remove-hook 'minibuffer-setup-hook
               #'picpocket-minibuffer-setup)
  (remove-hook 'minibuffer-exit-hook
               #'picpocket-minibuffer-exit))

(defun picpocket-cleanup-misc ()
  (when picpocket-old-fit
    (setq picpocket-fit picpocket-old-fit)
    (setq picpocket-old-fit nil)))

(defun picpocket-window-size-change-function (frame)
  (when picpocket-adapt-to-window-size-change
    (dolist (window (window-list frame 'no-minibuffer))
      (when (eq (get-buffer picpocket-buffer) (window-buffer window))
        (with-selected-window window
          (with-current-buffer picpocket-buffer
            (picpocket-reset-scroll)
            (picpocket-update-main-buffer)))))))

(defun picpocket-maybe-update-keymap ()
  (and picpocket-keystroke-alist
       (get-buffer picpocket-buffer)
       (eq (current-buffer) (get-buffer picpocket-buffer))
       (not (eq (picpocket-keystroke-alist)
                picpocket-old-keystroke-alist))
       (picpocket-update-keymap)))

(defun picpocket-maybe-rescale ()
  (let ((buffer (get-buffer picpocket-buffer)))
    (and buffer
         picpocket-adapt-to-window-size-change
         (eq (current-buffer) buffer)
         (eq (window-buffer) buffer)
         ;; It is important to check and save window size here.
         ;; Otherwise the call to picpocket-update-buffer may trigger
         ;; an infinite loop via buffer-list-update-hook.
         (progn
           ;; (picpocket-reset-scroll)
           (unless (equal picpocket-window-size (picpocket-save-window-size))
             (picpocket-update-main-buffer))))))

(defun picpocket-delete-trashcan ()
  (when picpocket-trashcan
    (delete-directory picpocket-trashcan t)
    (setq picpocket-trashcan nil)))



;;; Debug functions

(defun picpocket-debug (s format &rest args)
  (when picpocket-debug
    (setq picpocket-sum (time-add picpocket-sum s))
    (setq picpocket-header-text (format "(%s %s (%s))"
                                        (apply #'format format args)
                                        (picpocket-sec-string s)
                                        (picpocket-sec-string picpocket-sum)))
    (message "picpocket-debug: %s" picpocket-header-text)))

(defvar picpocket-dump-buffer "*picpocket-dump*")

(defun picpocket-dump ()
  "Print some picpocket variables."
  (interactive)
  (with-current-buffer (get-buffer-create picpocket-dump-buffer)
    (erase-buffer))
  (picpocket-dump-var 'picpocket-list)
  (picpocket-dump-var 'picpocket-current)
  (picpocket-dump-var 'picpocket-index)
  (picpocket-dump-var 'picpocket-list-length)
  (picpocket-dump-var 'picpocket-filter)
  (picpocket-dump-var 'picpocket-fatal)
  (picpocket-dump-var 'picpocket-recursive)
  (picpocket-dump-var 'picpocket-version)
  (picpocket-dump-var 'picpocket-entry-function)
  (picpocket-dump-var 'picpocket-entry-args)
  (picpocket-dump-var 'picpocket-picture-regexp)
  (picpocket-dump-var 'image-type-file-name-regexps)
  (picpocket-dump-some "pp-current-pos"
                       (picpocket-simplify-pos (picpocket-current-pos)))
  (picpocket-dump-some "pp-next-pos"
                       (picpocket-simplify-pos (picpocket-next-pos)))
  (picpocket-dump-some "pp-prev-pos"
                       (picpocket-simplify-pos (picpocket-previous-pos)))
  (picpocket-dump-some "dir-files"
                       (directory-files default-directory nil "^[^.]" t))
  (picpocket-dump-some "pp-file-list"
                       (picpocket-file-list default-directory))
  (switch-to-buffer picpocket-dump-buffer))

(defun picpocket-dump-some (name value)
  (with-current-buffer picpocket-dump-buffer
    (insert (format "%-20s %s\n"
                    (replace-regexp-in-string "^picpocket" "pp" name)
                    (with-temp-buffer
                      (pp value (current-buffer))
                      (goto-char (point-min))
                      (forward-line)
                      (indent-rigidly (point) (point-max) 20)
                      (buffer-string))))))

(defun picpocket-dump-var (var)
  (let ((value (symbol-value var)))
    (and (listp value)
         (picpocket-pic-p (car value))
         (setq value (picpocket-simplify-list value)))
    (picpocket-dump-some (symbol-name var) value)))



(defun picpocket-simplify-list (&optional list)
  "Print the LIST or current picture list without the prev links.
With the prev links it is harder to follow the list."
  (cl-loop for pic in (or list picpocket-list)
           for copy = (copy-picpocket-pic pic)
           do (setf (picpocket-pic-prev copy) :prev)
           collect copy))

(defun picpocket-simplify-pos (pos)
  (and pos
       (picpocket-pos-current pos)
       (make-picpocket-pos :current (picpocket-pic-file
                                     (car (picpocket-pos-current pos)))
                           :index (picpocket-pos-index pos)
                           :filter-index (picpocket-pos-filter-index pos))))

(defun picpocket-dump-list (&optional list)
  (pp (picpocket-simplify-list list)))

(defun picpocket-action-past-tense (action)
  (cl-case action
    (add-tag "Tagged")
    (copy "Copied")
    (move "Moved")
    (rename "Renamed")
    (hardlink "Hard linked")))

;; PENDING - just for comparing performance between single-linked and
;; double-linked lists.
(defun picpocket-backwards ()
  "Move backwards without using double-linked list."
  (interactive)
  (picpocket-command
    (when (eq picpocket-list picpocket-current)
      (user-error "No previous pic"))
    (let* ((list picpocket-list)
           (time (picpocket-time-string
                   (while (not (eq picpocket-current (cdr list)))
                     (setq list (cdr list))))))
      (picpocket-set-pos (make-picpocket-pos :current list
                                             :index (1- picpocket-index)))
      (message "Back %s" time))))

(defun picpocket-warn (format &rest args)
  (let ((format (concat "picpocket-warn: " format)))
    (apply #'message format args)
    (unless picpocket-demote-warnings
      (apply #'warn format args))))

;; PENDING - keeping this debug stuff for now.
(defvar picpocket-start (current-time))
(defun picpocket-msg (&rest args)
  (when nil
    (with-current-buffer (get-buffer-create "*piclog*")
      (save-excursion
        (goto-char (point-max))
        (insert (format "%f %s\n"
                        (time-to-seconds (time-since picpocket-start))
                        (mapconcat (lambda (x)
                                     (if (stringp x)
                                         x
                                       (prin1-to-string x)))
                                   args
                                   " ")))))))

(cl-loop for f in picpocket-list-commands
         for list-f = (intern (concat (symbol-name f) "-in-list"))
         do (put list-f 'function-documentation (documentation f)))

(provide 'picpocket)

;;; picpocket.el ends here
