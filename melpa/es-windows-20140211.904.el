;;; es-windows.el --- Window-management utilities -*- lexical-binding: t -*-

;;; Version: 0.3
;; Package-Version: 20140211.904
;; Package-Commit: 239e30408cb1adb4bc8bd63e2df34711fa910b4f
;;; Author: sabof
;;; URL: https://github.com/sabof/es-windows
;;; Package-Requires: ((cl-lib "0.3") (emacs "24"))

;;; Commentary:

;; The project is hosted at https://github.com/sabof/es-windows
;; The latest version, and all the relevant information can be found there.

;;; License:

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program ; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Code:

(require 'cl-lib)
(require 'face-remap)

(defgroup es-windows nil
  "Window manipulation utilities."
  :group 'convenience)

(defface esw/label-face
    `((t (:inherit font-lock-function-name-face
                   :height ,(* 2 (face-attribute 'default :height)))))
  "Face used for window labels."
  :group 'es-windows)

(defface esw/selection-face
    `((t (:inherit region)))
  "Face used for the selected window."
  :group 'es-windows)

(defcustom esw/be-helpful t
  "Whether to show help messages."
  :group 'es-windows
  :type 'boolean)

(defcustom esw/show-selection t
  "Whether to dynamically colorize the selected window."
  :group 'es-windows
  :type 'boolean)

(defcustom esw/key-direction-mappings
  '((">" . right)
    ("<" . left)
    ("^" . above)
    ("v" . below))
  "Keys that will trigger splitting."
  :group 'es-windows
  :type 'sexp)

(defvar esw/window-id-mappings nil
  "Internal variable, meant to by bound dynamically.")

(defmacro esw/with-protected-layout (&rest body)
  "An error within the body of this macro will cause the window layout to be restored.
Should this happen, the same (or should restoration fail, another) error will
continue unwinding the stack. Without errors, the macro has no effect."
  (declare (indent 0))
  (let (( spec (cl-gensym)))
    `(let ((,spec (esw/layout-state)))
       (condition-case error
           (progn ,@body)
         (error (esw/set-layout-state ,spec)
                (signal (car error) (cdr error)))))))
(put 'esw/with-protected-layout 'common-lisp-indent-function '(&body))

(defvar esw/with-covered-windows nil)
(defmacro esw/with-covered-windows (mappings cover-window-func &rest body)
  "Cover all windows, using MAPPINGS and COVER-WIDOW-FUNC.

MAPPINGS should be an alist of format \(\(\"label\" . <window>\)\),
It should include internal windows, if `esw/select-window' needs to be aware of them.

COVER-WINDOW-FUNC is a function taking one paraneter, WINDOW,
that will place a buffer in front of if, and return it.

The windows will be covered only once - the macro has no effect, if it's used
recursively."
  (declare (indent 2))
  (let (( spec (cl-gensym))
        ( buffers (cl-gensym)))
    `(if esw/with-covered-windows
         (progn ,@body)
       (let (( esw/with-covered-windows t)
             ( esw/window-id-mappings ,mappings)
             ( ,spec (esw/layout-state))
             ,buffers)
         (unwind-protect
             (progn (setq ,buffers (mapcar ,cover-window-func (esw/window-list)))
                    ,@body)
           (cl-dolist (buffer ,buffers)
             (ignore-errors
               (kill-buffer buffer)))
           (esw/set-layout-state ,spec))))))
(put 'esw/with-covered-windows 'common-lisp-indent-function 2)

(defun esw/parse-user-input (input-string)
  (setq input-string
        (progn (string-match "^ *\\(.*?\\) *$" input-string)
               (match-string 1 input-string)))
  (let* (( keys (mapcar 'string-to-char
                        (mapcar 'car
                                esw/key-direction-mappings)))
         ( divider
           (cl-loop with counter = 0
                    while (and (< counter (length input-string))
                               (not (memq (aref input-string counter) keys)))
                    do (cl-incf counter)
                    finally (cl-return counter)
                    )))
    (cons (when (< 0 (length (substring input-string 0 divider)))
            (substring input-string 0 divider))
          (when (< 0 (length (substring input-string divider)))
            (substring input-string divider)))
    ))

(defvar esw/help-message "
Each number represents an emacs window. Windows followed by H or V, are
internal Horizontal or Vertical splitters. The last window is an external
window, showing this buffer.

Type the number of the window you want, followed by RET, and that window will be
used. You can also type %s instead of RET, in which case the window
will be split in that direction.

If no window is provided, use the closest to root window that can be split.

To prevent this message from showing, set `esw/be-helpful' to `nil'")

(defun esw/window-children (window)
  (let* (( first-child (or (window-left-child window)
                           (window-top-child window)))
         ( children (list first-child)))
    (when first-child
      (while (window-next-sibling (car children))
        (push (window-next-sibling (car children))
              children))
      (nreverse children))))

(defun esw/shortcuts ()
  (let (( keys '("1" "2" "3" "4" "5" "6" "7" "8" "9" "0"
                 "q" "w" "e" "r" "t" "y" "u" "i" "o" "p"
                 "a" "s" "d" "f" "g" "h" "j" "k" "l" ";"
                 "z" "x" "c" "b" "n" "m" "," "." "/"))
        ( action-keys (mapcar 'car esw/key-direction-mappings)))
    (cl-remove-if (lambda (it) (member it action-keys))
                  keys)))

(defun esw/window-side-p (window)
  (window-parameter window 'window-side))

(defun esw/window-side-parent-p (window)
  (cl-some 'esw/window-side-p
           (esw/window-children window)))

(defun esw/window-splittable-p (window)
  (not (or (esw/window-side-p window)
           (esw/window-side-parent-p window))))

(cl-defun esw/window-lineage (&optional (window (selected-window)))
  "Result includes WINDOW."
  (nreverse
   (cl-loop for the-window = window then (window-parent the-window)
            while the-window
            unless (esw/window-side-parent-p the-window)
            collect the-window)))

(cl-defun esw/internal-window-list (&optional (window (frame-root-window)))
  "Provides a list of internal and external windows, starting from WINDOW,
which defaults to the frame root window. Windows that can neither be split or
shown are excluded."
  (let (( result (list window))
        ( fringe (list window))
        new-fringe)
    (while fringe
      (cl-dolist (window fringe)
        (let ((children (esw/window-children window)))
          (when children
            (cl-callf append result children)
            (cl-callf append new-fringe children))))
      (setq fringe new-fringe
            new-fringe nil))
    (cl-delete-if 'esw/window-side-parent-p result)
    ))

(defun esw/window-list ()
  "Provides a list of visible windows."
  (window-list nil nil (frame-first-window)))

(defun esw/cover-label (full-label window)
  (let (( segment-label
          (lambda (window)
            (concat
             (propertize (cdr (assoc window esw/window-id-mappings))
                         'face 'esw/label-face)
             (cond ( (window-left-child window)
                     "H")
                   ( (window-top-child window)
                     "V"))))))
    (if (and full-label (not (esw/window-side-p window)))
        (concat (mapconcat segment-label
                           (esw/window-lineage window)
                           " ")
                (when esw/be-helpful
                  (format esw/help-message
                          (mapconcat 'car
                                     esw/key-direction-mappings
                                     ", "))))
      (funcall segment-label window))))

(defun esw/cover-window (full-label window)
  (let (( buffer (generate-new-buffer
                  (buffer-name
                   (window-buffer window)))))
    (with-current-buffer buffer
      (setq major-mode 'esw/cover-mode)
      (insert (esw/cover-label full-label window))
      (goto-char (point-min))
      (setq cursor-type nil)
      (setq buffer-read-only t)
      (when (window-dedicated-p window)
        (set-window-dedicated-p window nil))
      (set-window-buffer window buffer)
      buffer)))

(defun esw/window-state (window)
  "Get the state of a window.
This state can be transfered to the same, or another window,
with `esw/set-window-state'."
  (list (window-buffer window)
        (window-dedicated-p window)
        (window-point window)
        (esw/window-eobp window)))

(defun esw/set-window-state (window state)
  "STATE is a window state, created by `esw/window-state'."
  (cl-destructuring-bind
      (buffer dedicated point eobp)
      state
    (set-window-buffer window buffer)
    (set-window-dedicated-p window dedicated)
    (set-window-point window point)
    (when eobp (esw/window-goto-eob window))))

(defun esw/layout-state ()
  "Save current layout state. It can be restored with `esw/set-layout-state'."
  (let ((windows (esw/window-list)))
    (list (current-window-configuration)
          (mapcar (lambda (window) (cons window (esw/window-state window)))
                  windows)
          )))

(defun esw/set-layout-state (spec)
  "Restore layout according to a SPEC created by `esw/layout-state'."
  (set-window-configuration (cl-first spec))
  (cl-dolist (state (cl-second spec))
    (cl-destructuring-bind
        (window buffer dedicated point eobp)
        state
      (set-window-point window point)
      (when eobp (esw/window-goto-eob window))
      (set-window-dedicated-p window dedicated))))

(defun esw/mark-window (window state)
  (with-current-buffer (window-buffer window)
    (when (eq major-mode 'esw/cover-mode)
      (if state
          (face-remap-add-relative
           'default 'esw/selection-face)
        (face-remap-remove-relative
         '(default . esw/selection-face))
        ))))

(cl-defun esw/minibuffer-post-command-hook ()
  (let* (( input-string
           (buffer-substring (minibuffer-prompt-end) (point-max)))
         ( parsed-input (esw/parse-user-input input-string))

         ( buffer-id (car parsed-input))
         ( selected-window
           (car (rassoc buffer-id esw/window-id-mappings)))
         ( windows-to-mark
           (when selected-window
             (cl-delete-if 'esw/window-children
                           (esw/internal-window-list
                            selected-window)))))
    (if (and (windowp selected-window)
             (not (esw/window-splittable-p selected-window)))
        (exit-minibuffer)
      (when esw/show-selection
        (cl-dolist (window (window-list))
          (esw/mark-window window (memq window windows-to-mark))
          )))))

(define-minor-mode esw/minibuffer-split-mode
    "Adds splitting keybindings to the minibuffer."
  nil nil (make-sparse-keymap)
  (setcdr esw/minibuffer-split-mode-map nil)
  (cl-dolist (mapping esw/key-direction-mappings)
    (define-key esw/minibuffer-split-mode-map
        (kbd (car mapping))
      'self-insert-and-exit))
  (add-hook 'post-command-hook 'esw/minibuffer-post-command-hook nil t))

;; Test:
;; while true; do date; sleep 0.3; done

(defun esw/window-goto-eob (window)
  (when (window-live-p window)
    (with-selected-window window
      (with-current-buffer (window-buffer window)
        (goto-char (point-max))))))

(defun esw/window-eobp (window)
  (when (window-live-p window)
    (with-selected-window window
      (with-current-buffer (window-buffer window)
        (eobp)))))

;;;###autoload
(cl-defun esw/select-window (&optional prompt show-internal-windows allow-splitting)
  "Query for a window using PROMPT, select and return it.

If SHOW-INTERNAL-WINDOWS is non-nil, show their labels, and accept them as input.
If an internal window is selected, it's children will be deleted.

If ALLOW-SPLITTING is non-nil, provide the user an option to split windows."
  (interactive (list nil t t))
  (unless prompt
    (setq prompt
          (if (and allow-splitting esw/be-helpful)
              (format "Select a window (type a large number followed by %s or RET): "
                      (mapconcat 'car esw/key-direction-mappings ", "))
            "Select window: ")))
  (let* (( all-windows
           (if show-internal-windows
               (esw/internal-window-list)
             (esw/window-list)))
         user-input-split
         selected-window)

    (unless allow-splitting
      (cl-case (length all-windows)
        ( 1 (cl-return-from esw/select-window
              (selected-window)))
        ( 2 (let (( other-window (car (remq (selected-window) all-windows))))
              (unless (esw/window-children other-window)
                (select-window other-window)
                (cl-return-from esw/select-window
                  other-window))))))

    (esw/with-covered-windows
        (cl-mapcar 'cons all-windows (esw/shortcuts))
        (apply-partially 'esw/cover-window show-internal-windows)
      (let (user-input parsed-input)
        (if allow-splitting
            (let (( minibuffer-setup-hook
                    (cons 'esw/minibuffer-split-mode minibuffer-setup-hook)))
              (setq user-input (read-string prompt)))
          (setq user-input
                (condition-case nil
                    (char-to-string
                     (event-basic-type
                      (read-event (or prompt "Select window: "))))
                  (error (user-error "Not a valid window")))))
        (setq parsed-input (esw/parse-user-input user-input))
        (setq selected-window
              (if (car parsed-input)
                  (or (car (rassoc (car parsed-input)
                                   esw/window-id-mappings))
                      (user-error "Not a valid window"))
                (car all-windows)))
        (setq user-input-split (cdr parsed-input))))

    (esw/with-protected-layout
      (if user-input-split
          (setq selected-window
                (split-window selected-window
                              nil
                              (cdr (assoc user-input-split
                                          esw/key-direction-mappings))))
        (when (esw/window-children selected-window)
          (let* ((windows (cdr (esw/internal-window-list selected-window)))
                 (live-windows (cl-remove-if-not 'window-live-p windows)))
            (mapc 'delete-window (cdr live-windows))
            (setq selected-window (car live-windows))
            (set-window-dedicated-p selected-window nil)))))
    (select-window selected-window)
    selected-window))

;;;###autoload
(defun esw/show-buffer (buffer)
  "Show the selected buffer in the selected window."
  (interactive (list (get-buffer-create (read-buffer "Choose buffer: "))))
  (set-window-buffer (esw/select-window nil t t) buffer))

;;;###autoload
(defun esw/move-window (window)
  "Show current buffer in a different window, and delete the old window."
  (interactive (list (selected-window)))
  (unless (eq t (window-deletable-p window))
    (user-error "Can't delete window"))
  (let* (( ori-window window)
         ( buffer (window-buffer ori-window))
         ( new-window (esw/select-window nil t t)))
    (unless (eq new-window ori-window)
      (set-window-buffer new-window buffer)
      (delete-window ori-window))))

;;;###autoload
(defun esw/delete-window ()
  "Choose and delete a window."
  (interactive)
  (esw/with-protected-layout
    (delete-window (esw/select-window "Delete window: " t))))

;;;###autoload
(defun esw/swap-two-windows ()
  "Choose and swap two windows."
  (interactive)
  (let* (window1 window2 window1-state window2-state)
    (esw/with-covered-windows
        (cl-mapcar 'cons (esw/window-list) (esw/shortcuts))
        (apply-partially 'esw/cover-window nil)
      (setq window1 (esw/select-window "Select first window: "))
      (esw/mark-window window1 t)
      (setq window2 (esw/select-window "Select second window: ")))
    (esw/with-protected-layout
      (setq window1-state (esw/window-state window1))
      (setq window2-state (esw/window-state window2))
      (esw/set-window-state window1 window2-state)
      (esw/set-window-state window2 window1-state))))

(provide 'es-windows)
;;; es-windows.el ends here
