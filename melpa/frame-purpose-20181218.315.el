;;; frame-purpose.el --- Purpose-specific frames  -*- lexical-binding: t; -*-

;; Author: Adam Porter <adam@alphapapa.net>
;; URL: http://github.com/alphapapa/frame-purpose.el
;; Package-Version: 20181218.315
;; Package-Commit: 60778ef3c02cb09a7ccc323732c89bf374dfbffe
;; Version: 1.0
;; Package-Requires: ((emacs "25.1") (dash "2.12") (dash-functional "1.2.0"))
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
(require 'dash-functional)

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
                 (const above)
                 (const below)))

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
(cl-defun frame-purpose-show-sidebar (&optional (side 'right))
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
  (frame-purpose--update-sidebar)
  (let* ((side (cl-case side
                 ;; Invert the side for `split-window'
                 ('left 'right)
                 ('right 'left)
                 ('above 'below)
                 ('below nil)))
         (size (pcase side
                 ((or 'left 'right)
                  (apply #'max (or (--map (+ 3 (length (buffer-name it)))
                                          (buffer-list))
                                   ;; In case the sidebar is opened in a frame without matching buffers
                                   (list 30))))
                 ((or 'nil 'below)
                  1))))
    (split-window nil size side)
    (switch-to-buffer (frame-purpose--sidebar-name))
    (set-window-dedicated-p (selected-window) t)))

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

Remaining keywords are transformed to non-keyword symbols and
passed as frame parameters to `make-frame', which see."
  (unless frame-purpose-mode
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
         (pred (byte-compile (or (map-elt parameters 'buffer-predicate)
                                 `(lambda (buffer)
                                    (with-current-buffer buffer
                                      (or ,(when modes
                                             `(frame-purpose--check-mode ',modes))
                                          ,(when filenames
                                             `(cl-loop for filename in ',filenames
                                                       when buffer-file-name
                                                       thereis (string-match filename buffer-file-name))))))))))
    ;; Validate args
    (unless (or modes filenames (map-elt parameters 'buffer-predicate))
      (user-error "One of `:modes', `:filenames', or `:buffer-predicate' must be set"))
    (when (and (map-elt parameters 'buffer-predicate)
               (or modes filenames))
      (user-error "When buffer-predicate is set, modes and filenames must be unspecified"))
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
  (when-let ((buffer (car (buffer-list frame))))
    (switch-to-buffer buffer)))


;;;;; Sidebar

(defun frame-purpose--buffer-list-update-hook ()
  "Update frame-purpose sidebars in all frames.
To be added to `buffer-list-update-hook'."
  (cl-loop for frame in (frame-list)
           do (with-selected-frame frame
                (when (frame-purpose--get-sidebar)
                  (frame-purpose--update-sidebar)))))

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
            (setq buffer-read-only t
                  cursor-type nil
                  mode-line-format nil)
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
           (grouped-buffers (->> (buffer-list)
                                 (-sort (-on #'string< #'buffer-name))
                                 (-group-by #'buffer-modified-p)
                                 (mapcar #'cdr)))
           (separator (pcase (frame-parameter nil 'sidebar)
                        ((or 'left 'right) "\n")
                        ((or 'above 'below) "  "))))
      (erase-buffer)
      (dolist (group grouped-buffers)
        (cl-loop for buffer in group
                 for string = (frame-purpose--format-buffer buffer)
                 do (insert (propertize string
                                        'buffer buffer)
                            separator)))
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
    (switch-to-buffer buffer)))

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

;;;; Footer

(provide 'frame-purpose)

;;; frame-purpose.el ends here
