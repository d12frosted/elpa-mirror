;;; frame-purpose.el --- Purpose-specific frames  -*- lexical-binding: t; -*-

;; Author: Adam Porter <adam@alphapapa.net>
;; URL: http://github.com/alphapapa/frame-purpose.el
;; Package-Version: 20211011.1518
;; Package-Commit: 7d498147445cc0afb87b922a8225d2e163e5ed5a
;; Version: 1.2-pre
;; Package-Requires: ((emacs "25.1") (dash "2.18"))
;; Keywords: buffers, convenience, frames

;;; Commentary:

;; `frame-purpose' makes it easy to open purpose-specific frames that only show certain buffers,
;; e.g. by buffers' major mode, their filename or directory, etc, with custom frame/X-window
;; titles, icons, and other frame parameters.

;; Note that this does not lock buffers to certain frames, and it does not prevent frames from
;; showing any buffer.  It works by overriding the `buffer-list' function so that, within a
;; purpose-specific frame, any code that uses `buffer-list' (e.g. `list-buffers', `ibuffer', Helm
;; buffer-related commands) will only show buffers for that frame's purpose.  You could say that,
;; within a purpose-specific frame, you would have to "go out of your way" to show a buffer that's
;; not related to that frame's purpose.

;;;; Usage:

;; First, enable `frame-purpose-mode'.  This overrides `buffer-list' with a function that acts
;; appropriately on purpose-specific frames.  When the mode is disabled, `buffer-list' is returned
;; to its original definition, and purpose-specific frames will no longer act specially.

;; There are some built-in interactive commands:

;; + `frame-purpose-make-directory-frame': Make a purpose-specific frame for buffers associated with
;; DIRECTORY.  DIRECTORY defaults to the current buffer's directory.

;; + `frame-purpose-make-mode-frame': Make a purpose-specific frame for buffers in major MODE.  MODE
;; defaults to the current buffer's major mode.

;;  + `frame-purpose-show-sidebar': Show list of purpose-specific buffers on SIDE of this frame.
;;  When a buffer in the list is selected, the last-used window switches to that buffer.  Makes a
;;  new buffer if necessary.  SIDE is a symbol, one of left, right, top, or bottom.

;; For more fine-grained control, or for scripted use, the primary function is
;; `frame-purpose-make-frame'.  For example:

;; Make a frame to show only Org-mode buffers, with a custom frame (X window) title and icon:
;; (frame-purpose-make-frame :modes 'org-mode
;;                           :title "Org"
;;                           :icon-type "~/src/emacs/org-mode/logo.png")

;; Make a frame to show only `matrix-client' buffers, with a custom frame (X window) title and icon,
;; and showing a list of buffers in a sidebar window on the right side of the frame:
;; (frame-purpose-make-frame :modes 'matrix-client-mode
;;                           :title "Matrix"
;;                           :icon-type (expand-file-name "~/src/emacs/matrix-client-el/logo.png")
;;                           :sidebar 'right)

;;; License:

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

;;; Code:

;;;; Requirements

(require 'cl-lib)
(require 'map)
(require 'subr-x)

(require 'dash)

;;;; Customization

(defgroup frame-purpose nil
  "Customization options for `frame-purpose-mode'."
  :link '(url-link "http://github.com/alphapapa/frame-purpose.el")
  :group 'convenience)

(defcustom frame-purpose--initial-buffer-fn #'frame-purpose--initial-buffer
  "Called to choose the buffer to show in new frames."
  :type 'function)

(defcustom frame-purpose-sidebar-default-side 'right
  "Default side of sidebar window."
  :type '(choice (const right :value)
                 (const left)
                 (const top)
                 (const bottom)))

(defcustom frame-purpose-sidebar-mode-blacklist
  '(
    "elfeed-"
    )
  "List of major modes which should not be used with `frame-purpose' sidebars.
For one reason or another, using a sidebar with buffers in these
major modes may cause problems.  For example,
`elfeed-search-update' uses temporary buffers to download and
process feeds, and every time it opens or closes a temp buffer,
`buffer-list' is called, which updates the list of buffers in the
sidebar, and this seems to significantly slow down the feed
updating process.  Until a fix or workaround can be found, it's
best to simply avoid using a sidebar with these major modes.  So,
if `frame-purpose-show-sidebar' is called from a buffer in one of
these major modes (or a major mode matching one of these
strings), an error will be signaled (it's not a perfect solution,
but it should help)."
  :type '(repeat (choice symbol string)))

;;;; Mode

;;;###autoload
(define-minor-mode frame-purpose-mode
  "Toggle `frame-purpose-mode', allowing the easy creation of purpose-specific frames.
This works by overriding `buffer-list' in frames which have their
`buffer-predicate' parameter set.  If any unusual behavior is
noticed in Emacs as a result of the override, disabling this mode
should restore correct behavior."
  :require 'frame-purpose
  :global t
  :init-value nil
  (if frame-purpose-mode
      (frame-purpose--enable)
    (frame-purpose--disable)))

(defun frame-purpose--enable ()
  "Store original `buffer-list' definition and override it.
Also add function to `buffer-list-update-hook'.  Called by
command `frame-purpose-mode'.  Do not call this function manually, or
Emacs may start behaving very strangely...."
  (unless (fboundp 'frame-purpose--buffer-list-original)
    ;; Avoid calling this twice, or it will define frame-purpose--buffer-list-original as itself,
    ;; causing infinite recursion whenever Emacs calls buffer-list, which tends to cause problems
    ;; (no, of course I didn't learn this the hard way...).
    (fset 'frame-purpose--buffer-list-original (symbol-function #'buffer-list))
    (advice-add #'buffer-list :override #'frame-purpose--buffer-list)
    (add-hook 'buffer-list-update-hook #'frame-purpose--buffer-list-update-hook)))

(defun frame-purpose--disable ()
  "Restore original `buffer-list' definition.
Also remove function from `buffer-list-update-hook'.  Called by
command `frame-purpose-mode'."
  (advice-remove #'buffer-list #'frame-purpose--buffer-list)
  (fmakunbound 'frame-purpose--buffer-list-original)
  (remove-hook 'buffer-list-update-hook #'frame-purpose--buffer-list-update-hook))

;;;; Commands

;;;###autoload
(cl-defun frame-purpose-make-directory-frame (&optional (directory default-directory))
  "Make a purpose-specific frame for buffers associated with DIRECTORY.
DIRECTORY defaults to the current buffer's directory."
  (interactive)
  (frame-purpose-make-frame :filenames (rx-to-string `(seq bos ,(expand-file-name directory)))
                            :title (file-name-nondirectory (directory-file-name directory))))

;;;###autoload
(cl-defun frame-purpose-make-mode-frame (&optional (mode major-mode))
  "Make a purpose-specific frame for buffers in major MODE.
MODE defaults to the current buffer's major mode."
  (interactive)
  (frame-purpose-make-frame :modes mode
                            :title (symbol-name mode)))

;;;###autoload
(cl-defun frame-purpose-show-sidebar (&optional (side 'right side-set-p))
  "Show list of purpose-specific buffers on SIDE of this frame.
When a buffer in the list is selected, the last-used window
switches to that buffer.  Makes a new buffer if necessary.  SIDE
is a symbol, one of left, right, top, or bottom."
  (interactive)
  (unless (frame-parameter nil 'buffer-predicate)
    (user-error "This frame has no specific purpose"))
  (when (and (> (length frame-purpose-sidebar-mode-blacklist) 0)
             (cl-loop for mode in frame-purpose-sidebar-mode-blacklist
                      thereis (cl-typecase mode
                                (symbol (eq mode major-mode))
                                (string (string-match mode (symbol-name major-mode))))))
    (user-error "The sidebar should generally not be used with buffers in %s.  See option `frame-purpose-sidebar-mode-blacklist'"
                major-mode))
  (unless side-set-p
    (setq side (frame-parameter nil 'sidebar)))
  (let* ((target-size (pcase side
                        ((or 'left 'right)
                         (apply #'max (or (--map (+ 4 (length (buffer-name it)))
                                                 (funcall (frame-parameter nil 'sidebar-buffers-fn)))
                                          ;; In case the sidebar is opened in a frame without matching buffers
                                          (list 30))))
                        ((or 'top 'bottom)
                         1)))
         (dimension-parameter (pcase side
                                ((or 'left 'right) 'window-width)
                                ((or 'top 'bottom) 'window-height))))
    (with-current-buffer (frame-purpose--get-sidebar 'create)
      (funcall (frame-parameter nil 'sidebar-update-fn))
      (goto-char (point-min))
      (display-buffer-in-side-window
       (current-buffer)
       (list (cons 'side side)
             (cons 'slot 0)
             (cons 'preserve-size (cons t t))
             (cons dimension-parameter target-size)
             (cons 'window-parameters (list (cons 'no-delete-other-windows t))))))))

;;;; Functions

;;;###autoload
(cl-defun frame-purpose-make-frame (&rest args)
  "Make a new, purpose-specific frame.
The new frame will only display buffers with the specified
attributes.

ARGS is a plist of keyword-value pairs, including:

`:modes': One or a list of major modes, matched against buffers'
major modes.

`:filenames': One or a list of regular expressions matched
 against buffers' filenames.

`:buffer-predicate': A function which takes a single argument, a
buffer, and returns non-nil when the buffer matches the frame's
purpose.  When set, `:modes' and `:filenames' must not also be
set.

`:buffer-sort-fns': A list of sorting functions which take one
argument, a list of buffers, and return the list sorted as
desired.  By default, buffers are sorted by modified status and
name.

`:sidebar': When non-nil, display a sidebar on the given side
showing buffers matching `:sidebar-buffers-fn'.  One of `top',
`bottom', `left', or `right'.

`:sidebar-buffers-fn': A function which takes no arguments and
returns a list of buffers to be displayed in the sidebar.  If
nil, `buffer-list' is used.  Using a custom function for this
when possible may substantially improve performance.

`:sidebar-update-fn': A function which updates the sidebar
buffer.  By default, `frame-purpose--update-sidebar'.  You may
override this if you know what you're doing.

`:sidebar-header': Value for `header-line-format' in the sidebar.

`:sidebar-auto-update': Whether to automatically update the
sidebar buffer whenever `buffer-list-update-hook' is called.  On
by default, but may degrade Emacs performance.

`:sidebar-update-on-buffer-switch': Whether to automatically
update the sidebar when the user selects a buffer from the
sidebar.  Disabled by default.  If `:sidebar-auto-update' is
non-nil, this should remain nil.

`:require-mode': If nil, don't require `frame-purpose-mode' to be
activated before making the frame.  By default, this option is
non-nil.  Note that if the mode is disabled, the `buffer-list'
function will not be overridden, so commands in the frame that
call `buffer-list' will act on all buffers, not just ones related
to the frame's purpose.  It may be useful to disable this
requirement when customizing the sidebar options, because
overriding `buffer-list' can sometimes have adverse effects on
Emacs.

In effect, you can have a \"light\" version of
`frame-purpose-mode' by writing your own `:sidebar-buffers-fn',
disabling `frame-purpose-mode', and updating the sidebar buffer
manually.  For example, `frame-purpose-make-frame' returns the
frame it creates, so that value can be used to write your own
code to call `frame-purpose--update-sidebar' in the frame when
appropriate (e.g. on user action, on a hook, on a network event,
on a timer, etc).

Remaining keywords are transformed to non-keyword symbols and
passed as frame parameters to `make-frame', which see."
  (when (and (not frame-purpose-mode) (plist-get args :require-mode))
    ;; TODO: Allow making frames when the mode is not enabled.  It can still be useful, because it
    ;; can make a sidebar that is updated manually, and without the performance impact of overriding
    ;; `buffer-list'.
    (user-error "Enable `frame-purpose-mode' first"))
  ;; Process args
  (let* ((parameters (cl-loop for (keyword value) on args by #'cddr
                              for symbol = (intern (substring (symbol-name keyword) 1))
                              collect (cons symbol value)))
         (modes (when-let (modes (map-elt parameters 'modes))
                  (cl-typecase modes
                    (symbol (list modes))
                    (list modes))))
         (filenames (when-let (filenames (map-elt parameters 'filenames))
                      (cl-typecase filenames
                        (string (list filenames))
                        (list filenames))))
         (pred (byte-compile
                (or (map-elt parameters 'buffer-predicate)
                    `(lambda (buffer)
                       (or ,(when modes
                              `(frame-purpose--buffer-mode-matches-p buffer ',modes))
                           ,(when filenames
                              `(cl-loop for filename in ',filenames
                                        when (buffer-local-value 'buffer-file-name buffer)
                                        thereis (string-match filename (buffer-local-value 'buffer-file-name buffer))))))))))
    ;; Validate args
    (unless (or modes filenames (map-elt parameters 'buffer-predicate))
      (user-error "One of `:modes', `:filenames', or `:buffer-predicate' must be set"))
    (when (and (map-elt parameters 'buffer-predicate)
               (or modes filenames))
      (user-error "When buffer-predicate is set, modes and filenames must be unspecified"))
    (unless (member 'sidebar-auto-update (map-keys parameters))
      ;; Enable sidebar-auto-update by default.
      (map-put parameters 'sidebar-auto-update t))
    ;; Make frame
    (with-selected-frame (make-frame parameters)
      ;; Add predicate. NOTE: It would be easy to put the predicate in `parameters' before calling
      ;; `make-frame', but that would mean that the predicate would be a closure whose lexical
      ;; environment contained itself, which becomes a circular reference.  Sometimes that seems to
      ;; cause a problem.  I don't know why it only seems to happen sometimes.  But let's just avoid
      ;; that problem completely by not doing that.
      (set-frame-parameter nil 'buffer-predicate
                           pred)
      (funcall frame-purpose--initial-buffer-fn)
      (when (frame-parameter nil 'sidebar)
        (frame-purpose-show-sidebar (frame-parameter nil 'sidebar)))
      (unless (frame-parameter nil 'sidebar-update-fn)
        (set-frame-parameter nil 'sidebar-update-fn #'frame-purpose--update-sidebar))
      (selected-frame))))

(defsubst frame-purpose--check-mode (modes)
  "Return non-nil if any of MODES match `major-mode'.
MODES is a list of one or more symbols or strings.  Symbols are
compared with `eq', and strings are regexps compared against the
major mode's name with `string-match'."
  (cl-loop for mode in modes
           thereis (cl-typecase mode
                     (symbol (eq mode major-mode))
                     (string (string-match mode (symbol-name major-mode))))))

(defsubst frame-purpose--buffer-mode-matches-p (buffer modes)
  "Return non-nil if any of BUFFER's MODES match `major-mode'.
MODES is a list of one or more symbols or strings.  Symbols are
compared with `eq', and strings are regexps compared against the
major mode's name with `string-match'."
  (cl-loop for mode in modes
           thereis (cl-typecase mode
                     (symbol (eq mode (buffer-local-value 'major-mode buffer)))
                     (string (string-match mode (symbol-name (buffer-local-value 'major-mode buffer)))))))

(defun frame-purpose--buffer-list (&optional frame)
  "Return list of buffers.  When FRAME has a buffer-predicate, only return frames passing it."
  ;; NOTE: Overriding `buffer-list' may have unexpected consequences because of interactions with
  ;; other code that calls it and may expect to receive an unfiltered list of buffers.  But...so
  ;; far, it seems okay...
  (cl-flet ((buffer-list (&optional frame)
                         (frame-purpose--buffer-list-original frame)))
    (if-let ((pred (frame-parameter frame 'buffer-predicate)))
        (cl-loop for buffer in (buffer-list frame)
                 when (funcall pred buffer)
                 collect buffer)
      (buffer-list frame))))

(defun frame-purpose--initial-buffer (&optional frame)
  "Switch to the first valid buffer in FRAME.
FRAME defaults to the current frame."
  (when-let* ((fn (frame-parameter frame 'sidebar-buffers-fn))
              (buffer (car (funcall fn))))
    (switch-to-buffer buffer)))

;;;;; Sidebar

(defun frame-purpose--buffer-list-update-hook ()
  "Update frame-purpose sidebars in all frames.
If a frame's `sidebar-auto-update' parameter is nil, its sidebar
is not updated.  To be added to `buffer-list-update-hook'."
  (cl-loop for frame in (frame-list)
           do (with-selected-frame frame
                (when (and (frame-parameter nil 'sidebar-auto-update)
                           (frame-purpose--get-sidebar))
                  (funcall (frame-parameter nil 'sidebar-update-fn))))))

(defun frame-purpose--get-sidebar (&optional create)
  "Return the current frame's purpose-specific, buffer-listing sidebar buffer.
When CREATE is non-nil, create the buffer if necessary."
  (when-let ((buffer-name (frame-purpose--sidebar-name)))
    (or (get-buffer buffer-name)
        (when create
          (unless (frame-parameter nil 'sidebar)
            ;; Set sidebar frame parameter if unset (e.g. if user calls `frame-purpose-make-frame'
            ;; without a `:sidebar' arg, then calls `frame-purpose-show-sidebar'.  FIXME: There might
            ;; be a nicer way to do this.
            (set-frame-parameter nil 'sidebar frame-purpose-sidebar-default-side))
          (with-current-buffer (get-buffer-create buffer-name)
            (setq buffer-undo-list t
                  buffer-read-only t
                  cursor-in-non-selected-windows nil
                  mode-line-format nil
                  header-line-format (frame-parameter nil 'sidebar-header))
            (use-local-map (make-sparse-keymap))
            (mapc (lambda (key)
                    (local-set-key (kbd key) #'frame-purpose--sidebar-switch-to-buffer))
                  '("<mouse-1>" "RET"))
            (local-set-key (kbd "<down-mouse-1>") #'mouse-set-point)
            (current-buffer))))))

(defun frame-purpose--update-sidebar ()
  "Update sidebar for this frame."
  (with-current-buffer (frame-purpose--get-sidebar 'create)
    (let* ((saved-point (point))
           (inhibit-read-only t)
           (buffer-sort-fns (or (frame-parameter nil 'buffer-sort-fns)
                                (list (-on #'string< #'buffer-name)
                                      (-on #'< #'buffer-modified-tick))))
           (buffers (funcall (or (frame-parameter nil 'sidebar-buffers-fn)
                                 #'buffer-list)))
           (buffers (dolist (fn buffer-sort-fns buffers)
                      (setq buffers (-sort fn buffers))))
           (separator (pcase (frame-parameter nil 'sidebar)
                        ((or 'left 'right) "\n")
                        ((or 'top 'bottom) "  "))))
      (erase-buffer)
      (cl-loop for buffer in buffers
               for string = (frame-purpose--format-buffer buffer)
               do (insert (propertize string 'buffer buffer)
                          separator))
      (goto-char saved-point))))

(defun frame-purpose--sidebar-name (&optional frame)
  "Return name of purpose-specific buffer list buffer for FRAME (or current frame)."
  (when-let ((frame-title (frame-parameter frame 'title)))
    (format "*frame-purpose-buffers for frame: %s*" frame-title)))

(defun frame-purpose--format-buffer (buffer)
  "Return formatted string representing BUFFER.
For insertion into sidebar."
  (let ((faces))
    (when (buffer-modified-p buffer)
      (push '(:weight bold) faces))
    (when (frame-purpose--buffer-visible-p buffer)
      (push '(:inherit highlight) faces))
    (propertize (buffer-name buffer)
                'face faces)))

(defun frame-purpose--buffer-visible-p (buffer)
  "Return non-nil if BUFFER is visible in current frame."
  (cl-loop for window in (window-list)
           thereis (equal buffer (window-buffer window))))

(defun frame-purpose--sidebar-switch-to-buffer ()
  "Switch previously used window to the buffer chosen in the sidebar.
The previously used window is typically the one that was active
when the user clicked in the sidebar."
  (interactive)
  (when-let ((buffer (get-text-property (point) 'buffer)))
    (select-window (get-mru-window nil nil 'not-selected))
    (switch-to-buffer buffer))
  (when (frame-parameter nil 'sidebar-update-on-buffer-switch)
    (funcall (frame-parameter nil 'sidebar-update-fn))))

;;;;; Throttle

(defun frame-purpose--throttle (func interval)
  "Throttle FUNC: a closure, lambda, or symbol.

If argument is a symbol then install the throttled function over
the original function.  INTERVAL, a number of seconds or a
duration string as used by `timer-duration', determines how much
time must pass before FUNC will be allowed to run again."
  (cl-typecase func
    (symbol
     (when (get func :frame-purpose-throttle-original-function)
       (user-error "%s is already throttled" func))
     (put func :frame-purpose-throttle-original-documentation (documentation func))
     (put func 'function-documentation
          (concat (documentation func) " (throttled)"))
     (put func :frame-purpose-throttle-original-function (symbol-function func))
     (fset func (frame-purpose--throttle-wrap (symbol-function func) interval))
     func)
    (function (frame-purpose--throttle-wrap func interval))))

(defun frame-purpose--throttle-wrap (func interval)
  "Return the throttled version of FUNC.
INTERVAL, a number of seconds or a duration string as used by
`timer-duration', determines how much time must pass before FUNC
will be allowed to run again."
  (let ((interval (cl-typecase interval
                    ;; Convert interval to seconds
                    (float interval)
                    (integer interval)
                    (string (timer-duration interval))
                    (t (user-error "Invalid interval: %s" interval))))
        last-run-time)
    (lambda (&rest args)
      (when (or (null last-run-time)
                (>= (float-time (time-subtract (current-time) last-run-time))
                    interval))
        (setq last-run-time (current-time))
        (apply func args)))))

;; Throttle the update-sidebar function, because sometimes it can be very slow and make Emacs loop
;; for a long time.  This is a hacky workaround, but it does help.

;; NOTE: Disabling for now, because it may not be desirable when using custom sidebar update
;; functions.

;;  (frame-purpose--throttle #'frame-purpose--update-sidebar 1)

;;;; Footer

(provide 'frame-purpose)

;;; frame-purpose.el ends here
