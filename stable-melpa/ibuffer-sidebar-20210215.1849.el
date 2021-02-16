;;; ibuffer-sidebar.el --- Sidebar for `ibuffer' -*- lexical-binding: t -*-

;; Copyright (C) 2018 James Nguyen

;; Author: James Nguyen <james@jojojames.com>
;; Maintainer: James Nguyen <james@jojojames.com>
;; URL: https://github.com/jojojames/ibuffer-sidebar
;; Package-Version: 20210215.1849
;; Package-Commit: 59e20690fc4f5ccd751e7a13a60664b97f053a1c
;; Version: 0.0.1
;; Package-Requires: ((emacs "25.1"))
;; Keywords: ibuffer, files, tools
;; HomePage: https://github.com/jojojames/ibuffer-sidebar

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
;; Provides a sidebar interface similar to `dired-sidebar', but for `ibuffer'.

;;
;; (use-package ibuffer-sidebar
;;   :bind (("C-x C-b" . ibuffer-sidebar-toggle-sidebar))
;;   :ensure nil
;;   :commands (ibuffer-sidebar-toggle-sidebar))
;;

;;; Code:
(require 'ibuffer)
(require 'face-remap)
(eval-when-compile (require 'subr-x))

;; Compatibility

(eval-and-compile
  (with-no-warnings
    (if (version< emacs-version "26")
        (progn
          (defalias 'ibuffer-sidebar-if-let* #'if-let)
          (defalias 'ibuffer-sidebar-when-let* #'when-let)
          (function-put #'ibuffer-sidebar-if-let* 'lisp-indent-function 2)
          (function-put #'ibuffer-sidebar-when-let* 'lisp-indent-function 1))
      (defalias 'ibuffer-sidebar-if-let* #'if-let*)
      (defalias 'ibuffer-sidebar-when-let* #'when-let*))))

;; Customizations
(defgroup ibuffer-sidebar nil
  "A major mode leveraging `ibuffer-sidebar' to display buffers in a sidebar."
  :group 'convenience)

(defcustom ibuffer-sidebar-use-custom-modeline t
  "Show `ibuffer-sidebar' with custom modeline.

This uses format specified by `ibuffer-sidebar-mode-line-format'."
  :type 'boolean
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-mode-line-format
  '("%e" mode-line-front-space
    mode-line-buffer-identification
    " "  mode-line-end-spaces)
  "Mode line format for `ibuffer-sidebar'."
  :type 'list
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-display-column-titles nil
  "Whether or not to display the column titles in sidebar."
  :type 'boolean
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-display-summary nil
  "Whether or not to display summary in sidebar."
  :type 'boolean
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-width 35
  "Width of the `ibuffer-sidebar' buffer."
  :type 'integer
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-pop-to-sidebar-on-toggle-open t
  "Whether to jump to sidebar upon toggling open.

This is used in conjunction with `ibuffer-sidebar-toggle-sidebar'."
  :type 'boolean
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-use-custom-font nil
  "Show `ibuffer-sidebar' with custom font.

This face can be customized using `ibuffer-sidebar-face'."
  :type 'boolean
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-face nil
  "Face used by `ibuffer-sidebar' for custom font.

This only takes effect if `ibuffer-sidebar-use-custom-font' is true."
  :type 'list
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-display-alist '((side . left) (slot . 1))
  "Alist used in `display-buffer-in-side-window'.

e.g. (display-buffer-in-side-window buffer '((side . left) (slot . 1)))"
  :type 'alist
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-refresh-on-special-commands t
  "Whether or not to trigger auto-revert after certain functions.

Warning: This is implemented by advising specific functions."
  :type 'boolean
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-special-refresh-commands
  '((kill-buffer . 2)
    (find-file . 2)
    (delete-file . 2))
  "A list of commands that will trigger a refresh of the sidebar.

The command can be an alist with the CDR of the alist being the amount of time
to wait to refresh the sidebar after the CAR of the alist is called.

Set this to nil or set `ibuffer-sidebar-refresh-on-special-commands' to nil
to disable automatic refresh when a special command is triggered."
  :type 'list
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-name "*:Buffers:*"
  "The name of `ibuffer-sidebar' buffer."
  :type 'string
  :group 'ibuffer-sidebar)

(defcustom ibuffer-sidebar-refresh-timer 3
  "Refresh sidebar every N seconds. If nil then do not refresh."
  :type 'integer
  :group 'ibuffer-sidebar)


;; Mode

(define-derived-mode ibuffer-sidebar-mode ibuffer-mode
  "Ibuffer-sidebar"
  "A major mode that puts `ibuffer' in a sidebar."
  :group 'ibuffer-sidebar
  (let ((inhibit-read-only t))
    (setq window-size-fixed 'width)

    (when ibuffer-sidebar-use-custom-font
      (ibuffer-sidebar-set-font))

    ;; Remove column titles.
    (unless ibuffer-sidebar-display-column-titles
      (advice-add 'ibuffer-update-title-and-summary
                  :after 'ibuffer-sidebar-remove-column-headings))

    ;; Hide summary.
    (unless ibuffer-sidebar-display-summary
      (setq-local ibuffer-display-summary nil))

    ;; Set default format to be minimal.
    (setq-local ibuffer-formats (append ibuffer-formats '((mark " " name))))
    (setq-local ibuffer-current-format (1- (length ibuffer-formats)))
    (ibuffer-update-format)
    (ibuffer-redisplay t)

    ;; Set up refresh on timer.
    (when ibuffer-sidebar-refresh-timer
      (run-with-idle-timer
       ibuffer-sidebar-refresh-timer
       1
       #'ibuffer-sidebar-refresh-buffer))

    ;; Set up refresh on special commands.
    (when ibuffer-sidebar-refresh-on-special-commands
      (mapc
       (lambda (x)
         (if (consp x)
             (let ((command (car x))
                   (delay (cdr x)))
               (advice-add
                command
                :after
                (defalias (intern (format "ibuffer-sidebar-refresh-after-%S" command))
                  (function
                   (lambda (&rest _)
                     (let ((timer-symbol
                            (intern
                             (format
                              "ibuffer-sidebar-refresh-%S-timer" command))))
                       (when (and (boundp timer-symbol)
                                  (timerp (symbol-value timer-symbol)))
                         (cancel-timer (symbol-value timer-symbol)))
                       (setf
                        (symbol-value timer-symbol)
                        (run-with-idle-timer
                         delay
                         nil
                         #'ibuffer-sidebar-refresh-buffer))))))))
           (advice-add x :after #'ibuffer-sidebar-refresh-buffer)))
       ibuffer-sidebar-special-refresh-commands))

    (when ibuffer-sidebar-use-custom-modeline
      (ibuffer-sidebar-set-mode-line))))

;; User Interface

;;;###autoload
(defun ibuffer-sidebar-toggle-sidebar ()
  "Toggle the `ibuffer-sidebar' window."
  (interactive)
  (if (ibuffer-sidebar-showing-sidebar-p)
      (ibuffer-sidebar-hide-sidebar)
    (ibuffer-sidebar-show-sidebar)
    (when ibuffer-sidebar-pop-to-sidebar-on-toggle-open
      (pop-to-buffer (ibuffer-sidebar-buffer)))))

;;;###autoload
(defun ibuffer-sidebar-show-sidebar ()
  "Show sidebar with `ibuffer'."
  (interactive)
  (let ((buffer (ibuffer-sidebar-get-or-create-buffer)))
    (display-buffer-in-side-window buffer ibuffer-sidebar-display-alist)
    (let ((window (get-buffer-window buffer)))
      (set-window-dedicated-p window t)
      (set-window-parameter window 'no-delete-other-windows t)
      (with-selected-window window
        (let ((window-size-fixed))
          (ibuffer-sidebar-set-width ibuffer-sidebar-width))))
    (ibuffer-sidebar-update-state buffer)))

;;;###autoload
(defun ibuffer-sidebar-hide-sidebar ()
  "Hide `ibuffer-sidebar' in selected frame."
  (ibuffer-sidebar-when-let* ((buffer (ibuffer-sidebar-buffer)))
    (delete-window (get-buffer-window buffer))
    (ibuffer-sidebar-update-state nil)))

;; Helpers

(defun ibuffer-sidebar-showing-sidebar-p (&optional f)
  "Return whether F or `selected-frame' is showing `ibuffer-sidebar'.

Check if F or `selected-frame' contains a sidebar and return corresponding
buffer if buffer has a window attached to it."
  (ibuffer-sidebar-if-let* ((buffer (ibuffer-sidebar-buffer f)))
      (get-buffer-window buffer)
    nil))

(defun ibuffer-sidebar-get-or-create-buffer ()
  "Get or create a `ibuffer-sidebar' buffer."
  (let ((name ibuffer-sidebar-name))
    (ibuffer-sidebar-if-let* ((existing-buffer (get-buffer name)))
        existing-buffer
      (let ((new-buffer (generate-new-buffer name)))
        (with-current-buffer new-buffer
          (ibuffer-sidebar-setup))
        new-buffer))))

(defun ibuffer-sidebar-setup ()
  "Bootstrap `ibuffer-sidebar'.

Sets up both `ibuffer' and `ibuffer-sidebar'."
  (ibuffer-mode)
  (ibuffer-update nil)
  (run-hooks 'ibuffer-hook)
  (ibuffer-sidebar-mode))

(defun ibuffer-sidebar-buffer (&optional f)
  "Return the current sidebar buffer in F or selected frame.

This returns nil if there isn't a buffer for F."
  (let* ((frame (or f (selected-frame)))
         (buffer (frame-parameter frame 'ibuffer-sidebar)))
    (if (buffer-live-p buffer)
        buffer
      (set-frame-parameter frame 'ibuffer-sidebar nil)
      nil)))

(defun ibuffer-sidebar-update-state (buffer &optional f)
  "Update current state with BUFFER for sidebar in F or selected frame."
  (let ((frame (or f (selected-frame))))
    (set-frame-parameter frame 'ibuffer-sidebar buffer)))

(defun ibuffer-sidebar-refresh-buffer (&rest _)
  "Refresh sidebar buffer."
  (ibuffer-sidebar-when-let* ((sidebar (ibuffer-sidebar-buffer))
                              (window (get-buffer-window sidebar)))
    (with-selected-window window
      (ibuffer-update nil t))))

;; UI

(defun ibuffer-sidebar-remove-column-headings (&rest _args)
  "Function ran after `ibuffer-update-title-and-summary' that removes headings.

F should be function `ibuffer-update-title-and-summary'.
ARGS are args for `ibuffer-update-title-and-summary'."
  (when (and (bound-and-true-p ibuffer-sidebar-mode)
             (not ibuffer-sidebar-display-column-titles))
    (with-current-buffer (current-buffer)
      (goto-char 1)
      (search-forward "-\n" nil t)
      (delete-region 1 (point))
      (let ((window-min-height 1))
        (shrink-window-if-larger-than-buffer)))))

(defun ibuffer-sidebar-set-width (width)
  "Set the width of the buffer to WIDTH when it is created."
  ;; Copied from `treemacs--set-width' as well as `neotree'.
  (unless (one-window-p)
    (let ((window-size-fixed)
          (w (max width window-min-width)))
      (cond
       ((> (window-width) w)
        (shrink-window-horizontally  (- (window-width) w)))
       ((< (window-width) w)
        (enlarge-window-horizontally (- w (window-width))))))))

(defun ibuffer-sidebar-set-font ()
  "Customize font in `ibuffer-sidebar'.

Set font to a variable width (proportional) in the current buffer."
  (interactive)
  (setq-local buffer-face-mode-face ibuffer-sidebar-face)
  (buffer-face-mode))

(defun ibuffer-sidebar-set-mode-line ()
  "Customize modeline in `ibuffer-sidebar'."
  (setq mode-line-format ibuffer-sidebar-mode-line-format))

(provide 'ibuffer-sidebar)
;;; ibuffer-sidebar.el ends here
