;;; perspective-exwm.el --- Better integration for perspective.el and EXWM -*- lexical-binding: t -*-

;; Copyright (C) 2021-2022 Korytov Pavel
;; Copyright (C) 2008-2020 Natalie Weizenbaum <nex342@gmail.com>

;; Author: Korytov Pavel <thexcloud@gmail.com>
;; Maintainer: Korytov Pavel <thexcloud@gmail.com>
;; Version: 0.1.4
;; Package-Version: 20220125.1939
;; Package-Commit: 8afdbf894a888854ce9dfbe0ad2a5dc41f75ecb8
;; Package-Requires: ((emacs "27.1") (burly "0.2-pre") (exwm "0.26") (perspective "2.17"))
;; Homepage: https://github.com/SqrtMinusOne/perspective-exwm.el

;; This file is NOT part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; A couple of tricks and fixes to make using EXWM and perspective.el
;; a better experience.
;;
;; Most importantly, this package provides `perspective-exwm-mode',
;; which fixes certain annoying issues between the two packages.  Take
;; a look at its docstring for more info.
;;
;; Other useful functions are:
;; - `perspective-exwm-cycle-exwm-buffers-backward' and
;;   `perspective-exwm-cycle-exwm-buffers-backward'
;; - `perspective-exwm-switch-perspective'
;; - `perspective-exwm-copy-to-workspace' and
;;   `perspective-exwm-move-to-workspace'
;;
;; Finally, take a look at the package README at
;; <https://github.com/SqrtMinusOne/perspective-exwm.el> for more
;; information.

;;; Code:
(require 'burly)
(require 'exwm)
(require 'perspective)
(require 'cl-lib)

(defgroup perspective-exwm nil
  "Integration between perspective.el and EXWM."
  :group 'frames)

(defun perspective-exwm--get-class ()
  "A function to return the current EXWM class name."
  exwm-class-name)

(defun perspective-exwm--get-title ()
  "A function to return the current EXWM window title."
  exwm-title)

(defcustom perspective-exwm-get-exwm-buffer-name #'perspective-exwm--get-class
  "A function to get the EXWM buffer title.

Meant to be ran in the context of the target buffer, e.g. with
`with-current-buffer'.

The two default options are:
- `perspective-exwm--get-class' - returns EXWM class
- `perspective-exwm--get-title' - returns EXWM title"
  :group 'perspective-exwm
  :type 'function
  :options '(perspective-exwm--get-class perspective-exwm--get-title))

(defcustom perspective-exwm-override-initial-name nil
  "Set initial perspective name for a particular EXWM workspace."
  :group 'perspective-exwm
  :type '(alist :key-type (integer :tag "EXWM workspace index")
                :value-type (string :tag "Initial perspective name")))

(defface perspective-exwm-cycle-current-face
  '((t (:inherit warning)))
  "Face for the current buffer in the buffer cycling message."
  :group 'perspective-exwm)

(defface perspective-exwm-cycle-skip-face
  '((t (:inherit persp-selected-face)))
  "Face for the buffer to skip in the buffer cycling message."
  :group 'perspective-exwm)

(defface perspective-exwm-current-workspace-face
  '((t (:inherit warning)))
  "Face for the current workspace number.

Used in `perspective-exwm-switch-perspective'."
  :group 'perspective-exwm)

(defface perspective-exwm-selected-pespective-face
  '((t (:inherit persp-selected-face)))
  "Face for the selected perspective.

Used in `perspective-exwm-switch-perspective'."
  :group 'perspective-exwm)

(defun perspective-exwm--cycle-exwm-buffers (dir)
  "Cycle EXWM buffers in the current perspective.

DIR is either 'forward or 'backward.  A buffer is skipped if it is
already displayed in some other window of the current
perspective.  The buffer name comes from
`perspective-exwm-get-exwm-buffer-name'.

The function prints out the state to the messages.  The current
buffer after the switch is highlighted with `warning', skipped
buffer is highlighted with `persp-selected-face'"
  (let* ((current (current-buffer))
         (ignore-rx (persp--make-ignore-buffer-rx))
         (exwm-data
          (cl-loop for buf in (persp-current-buffers)
                   for is-another = (and (get-buffer-window buf) (not (eq current buf)))
                   if (and (buffer-live-p buf)
                           (eq 'exwm-mode (buffer-local-value 'major-mode buf))
                           (not (string-match-p ignore-rx (buffer-name buf))))
                   collect buf into all-buffers
                   and if (not is-another) collect buf into cycle-buffers
                   finally (return (list all-buffers cycle-buffers))))
         (all-buffers (nth 0 exwm-data))
         (cycle-buffers (nth 1 exwm-data))
         (current-pos (or (cl-position current cycle-buffers) -1)))
    (if (seq-empty-p cycle-buffers)
        (message "No EXWM buffers to cycle!")
      (let* ((next-pos (% (+ current-pos (length cycle-buffers)
                             (if (eq dir 'forward) 1 -1))
                          (length cycle-buffers)))
             (next-buffer (nth next-pos cycle-buffers)))
        (switch-to-buffer next-buffer)
        (message
         "%s"
         (cl-loop for buf in all-buffers
                  for name = (with-current-buffer buf (funcall perspective-exwm-get-exwm-buffer-name))
                  for is-current = (eq (current-buffer) buf)
                  for is-skip = (not (member buf cycle-buffers))
                  if is-current
                  concat (concat "[" (propertize name 'face 'perspective-exwm-cycle-current-face) "] ") into res
                  else if is-skip
                  concat (concat "[" (propertize name 'face 'perspective-exwm-cycle-skip-face) "] ") into res
                  else
                  concat (format " %s  " name) into res
                  finally return res))))))

;;;###autoload
(defun perspective-exwm-cycle-exwm-buffers-forward ()
  "Cycle EXWM buffers in the current perspective forward.

Take a look at `perspective-exwm--cycle-exwm-buffers' for more
detail."
  (interactive)
  (perspective-exwm--cycle-exwm-buffers 'forward))

;;;###autoload
(defun perspective-exwm-cycle-exwm-buffers-backward ()
  "Cycle EXWM buffers in the current perspective backward.

Take a look at `perspective-exwm--cycle-exwm-buffers' for more
detail."
  (interactive)
  (perspective-exwm--cycle-exwm-buffers 'backward))

;;;###autoload
(defun perspective-exwm-switch-perspective ()
  "Switch to a perspective on any workspace."
  (interactive)
  (let* ((choices
          (cl-loop for i from 0 to (1- (exwm-workspace--count))
                   for frame = (nth i exwm-workspace--list)
                   for workspace-name = (apply exwm-workspace-index-map (list i))
                   with current-workspace-index = exwm-workspace-current-index
                   append
                   (with-selected-frame frame
                     (cl-loop for persp-name being the hash-keys of (perspectives-hash)
                              with current-persp-name = (persp-current-name)
                              collect
                              (cons
                               (format "%-4s %s"
                                       (if (= i current-workspace-index)
                                           (propertize
                                            (format "[%s]" workspace-name)
                                            'face
                                            'perspective-exwm-current-workspace-face)
                                         (format "[%s]" workspace-name))
                                       (if (string-equal persp-name current-persp-name)
                                           (propertize
                                            persp-name
                                            'face
                                            'perspective-exwm-selected-pespective-face)
                                         persp-name))
                               (cons i persp-name))))))
         (choice (cdr (assoc (completing-read "Select a perspective: " choices) choices))))
    (exwm-workspace-switch (car choice))
    (persp-switch (cdr choice))))

;;;###autoload
(defun perspective-exwm-copy-to-workspace (&optional move)
  "Copy the current perspective to another EXWM workspace.

If MOVE is t, move the perspective instead."
  (interactive)
  (when (and move (= 1 (hash-table-count (perspectives-hash))))
    (user-error "Can't move the only workspace"))
  (let* ((target-workspace (exwm-workspace--prompt-for-workspace))
         (persp-name (persp-current-name))
         (url (burly-windows-url))
         (buffers (persp-current-buffers)))
    (unless (= (cl-position target-workspace exwm-workspace--list)
               exwm-workspace-current-index)
      (when (gethash persp-name (perspectives-hash target-workspace))
        (user-error "Perspective with name \"%s\" already exists on the target workspace" persp-name))
      (with-selected-frame target-workspace
        (with-perspective persp-name
          (mapc #'persp-add-buffer buffers)
          (burly-open-url url))
        (persp-switch persp-name)
        (persp-update-modestring))
      (when move
        (persp-kill persp-name))
      (exwm-workspace-switch target-workspace))))

;;;###autoload
(defun perspective-exwm-move-to-workspace ()
  "Move the current perspective to an EXWM workspace."
  (interactive)
  (perspective-exwm-copy-to-workspace t))

(defun perspective-exwm--delete-frame-around (fun &rest args)
  "An advice around `persp-delete-frame'.

FUN is `persp-delete-frame', ARGS are passed to FUN with `apply'.

Do not run the function if the frame is floating, because it
occasionally breaks the current perspective in the \"parent\"
frame."
  (unless (and (derived-mode-p 'exwm-mode) exwm--floating-frame)
    (apply fun args)))

(defvar perspective-exwm--override-current-index nil
  "The true index of the workspace under creation.

Overrides the index in `perspective-exwm--init-frame-around'.")

(defvar perspective-exwm--is-floating nil
  "If true, the frame under creation is floating.")

(defun perspective-exwm--init-frame-around (fun &rest args)
  "An advice around `persp-init-frame'.

Overrides `persp-initial-frame-name' according to
`perspective-exwm-override-initial-name'.

FUN should be `persp-init-frame', ARGS are passed to FUN with `apply'.

The first argument of ARGS is frame.  Thus, the workspace index is
either the position of the frame in `exwm-workspace--list', or a
length of that list if it's not yet there.  This approach seems
to work best, e.g. when doing `exwm-workspace-switch-create' and
creating multiple workspaces at once."
  (let* ((workspace-index
          (or perspective-exwm--override-current-index
              (cl-position (car args) exwm-workspace--list)
              (length exwm-workspace--list)))
         (persp-initial-frame-name
          (or
           (cdr (assoc workspace-index
                       perspective-exwm-override-initial-name))
           (format "main-%s" (funcall exwm-workspace-index-map workspace-index))))
         (persp-initial-frame-name
          (if perspective-exwm--is-floating
              (format "%s-floating" persp-initial-frame-name)
            persp-initial-frame-name)))
    (apply fun args)))

(defun perspective-exwm--floating-set-floating-around (fun &rest args)
  "An advice around `exwm-floating--set-floating'.

FUN should be `exwm-floating--set-floating', ARGS are passed to
FUN with `apply'.

This function creates a floating window, so this advice indicates
that with seting `perspective-exwm--is-floating'"
  (let ((perspective-exwm--override-current-index exwm-workspace-current-index)
        (perspective-exwm--is-floating t))
    (apply fun args)))

(defun perspective-exwm--workspace-add-around (fun &rest args)
  "An advice around `exwm-workspace-add'.

FUN should be `exwm-workspace-add', ARGS are passed to FUN with
`apply'.

This is necessary because `exwm-workspace-add' first calls
`make-frame' and only then moves it to the right index,
i.e. there is no way to determine the true index of workspace
under creation `persp-init-frame'."
  (let ((perspective-exwm--override-current-index (car args)))
    (apply fun args)))

(defun perspective-exwm--after-exwm-init ()
  "Create perspectives in workspaces.

`perspective-exwm-override-initial-name' determines initial names
of perspectives.

The function is meant to be run from `exwm-init-hook'."
  (cl-loop for workspace-index from 0 to (exwm-workspace--count)
           for frame in exwm-workspace--list
           for target-name = (or
                              (cdr (assoc workspace-index
                                          perspective-exwm-override-initial-name))
                              (format "main-%s" (funcall exwm-workspace-index-map workspace-index)))
           do (with-selected-frame frame
                (let ((current-name (persp-current-name)))
                  (unless (string-equal current-name target-name)
                    (persp-switch target-name)
                    (persp-kill current-name))))))


(cl-defun perspective-exwm--persp-buffer-in-other-p (buffer)
  "Return nil if BUFFER is only in the current perspective.
Otherwise, returns (FRAME . NAME), the frame and name of another
perspective that has the buffer.

Prefers perspectives in the selected frame.

This version of the function also excludes EXWM buffers from
appearing to be in other frames, because an EXWM buffer can be
only in one frame."
  (cl-loop for frame in
           (sort (frame-list)
                 (lambda (_frame1 frame2) (not (eq frame2 (selected-frame)))))
           do (cl-loop for persp being the hash-values of (perspectives-hash frame)
                       if (and (not (and (equal frame (selected-frame))
                                         (equal (persp-name persp) (persp-name (persp-curr frame)))))
                               (not (and (not (equal frame (selected-frame)))
                                         (eq (buffer-local-value 'major-mode buffer) 'exwm-mode)))
                               (memq buffer (persp-buffers persp)))
                       do (cl-return-from perspective-exwm--persp-buffer-in-other-p
                            (cons frame (persp-name persp)))))
  nil)

(defun perspective-exwm--persp-set-buffer-override (buffer-or-name)
  "Move BUFFER-OR-NAME to the current perspective.

The original version `persp-set-buffer' from perspective.el
sometimes copies perspectives from all other workspaces to the
current one.  This version stabilizes that behaviour by wrapping
calls to `persp-forget-buffer' in `with-selected-frame'."
  (interactive
   (list
    (let ((read-buffer-function nil))
      (read-buffer "Set buffer to perspective: "))))
  (let ((buffer (get-buffer buffer-or-name)))
    (if (not (buffer-live-p buffer))
        (message "buffer %s doesn't exist" buffer-or-name)
      (persp-add-buffer buffer)
      ;; Do not use the combination "while `persp-buffer-in-other-p'",
      ;; if the buffer is not removed from other perspectives, it will
      ;; go into an infinite loop.
      (cl-loop with current-persp-name = (persp-current-name)
               for frame in exwm-workspace--list
               do (with-selected-frame frame
                    (cl-loop for persp-name being the hash-keys of (perspectives-hash)
                             unless (string-equal persp-name current-persp-name)
                             do (with-perspective persp-name
                                  (persp-forget-buffer buffer))))))))

;;;###autoload
(defun perspective-exwm-revive-perspectives ()
  "Make perspectives in the current frame not killed."
  (interactive)
  (let ((to-switch nil))
    (maphash
     (lambda (_ v)
       (setf (persp-killed v) nil)
       (unless to-switch
         (setq to-switch v)))
     (frame-parameter nil 'persp--hash))
    (when to-switch
      (persp-switch (persp-name to-switch)))))

;;;###autoload
(cl-defun perspective-exwm-assign-window (&key workspace-index persp-name)
  "Move current the buffer to another workspace and/or perspective.

WORKSPACE-INDEX is index of the workspace as in
`exwm-workspace--list'.  PERSP-NAME is the name of the target
perspective.

The function is useful to be ran from `exwm-manage-finish-hook',
e.g. like this:
\(defun my/exwm-configure-window ()
  (interactive)
  (pcase exwm-class-name
    ((or \"Firefox\" \"Nightly\") (perspective-exwm-assign-window
                               :workspace-index 2
                               :persp-name \"browser\"))))"
  (let ((buffer (current-buffer)))
    (when (and workspace-index (not (= workspace-index exwm-workspace-current-index)))
      (exwm-workspace-move-window workspace-index))
    (when persp-name
      (with-selected-frame (nth (or workspace-index
                                    exwm-workspace-current-index)
                                exwm-workspace--list)
        (with-perspective persp-name
          (persp-set-buffer buffer))
        (persp-switch-to-buffer buffer)))))

;;;###autoload
(define-minor-mode perspective-exwm-mode
  "A minor mode for intergrating perspective.el and EXWM.

The mode does a couple of things:
 - fixes a bug with half-killing the current perspective when closing
   a floating window.  I haven't tested this as thoroughly, so run
   `perspective-exwm-revive-perspectives' if the problem arises
   anyway.
 - fixes a bug with running `persp-set-buffer' on an EXWM buffer that
   was moved between workspaces by advising `persp-buffer-in-other-p'.
 - fixes a bug with `persp-set-buffer' copying all the
   perspectives from other workspaces to the current one
 - adjusts the name of the inital perspective in the new workspace.
   It tries to get the name from the
   `perspective-exwm-override-initial-name' variable and falls back to
   \"main-<index>\".

The latter also serves a purpose, because otherwise there are
issues with multiple perspectives sharing the same scratch
buffer.

Be sure to activate this mode before `exwm-enable', so that the
inital workspaces are created with the new perspective names."
  :global t
  :after-hook
  (progn
    (if perspective-exwm-mode
        (progn
          (advice-add #'persp-delete-frame
                      :around #'perspective-exwm--delete-frame-around)
          (advice-add #'persp-init-frame
                      :around #'perspective-exwm--init-frame-around)
          (advice-add #'persp-buffer-in-other-p
                      :override #'perspective-exwm--persp-buffer-in-other-p)
          (advice-add #'persp-set-buffer
                      :override #'perspective-exwm--persp-set-buffer-override)
          (advice-add #'exwm-workspace-add
                      :around #'perspective-exwm--workspace-add-around)
          (advice-add #'exwm-floating--set-floating
                      :around #'perspective-exwm--floating-set-floating-around)
          (add-hook 'exwm-init-hook #'perspective-exwm--after-exwm-init))
      (advice-remove #'persp-delete-frame
                     #'perspective-exwm--delete-frame-around)
      (advice-remove #'persp-init-frame
                     #'perspective-exwm--init-frame-around)
      (advice-remove #'persp-buffer-in-other-p
                     #'perspective-exwm--persp-buffer-in-other-p)
      (advice-remove #'persp-set-buffer
                     #'perspective-exwm--persp-set-buffer-override)
      (advice-remove #'exwm-workspace-add
                     #'perspective-exwm--workspace-add-around)
      (advice-remove #'exwm-floating--set-floating
                     #'perspective-exwm--floating-set-floating-around)
      (remove-hook 'exwm-init-hook #'perspective-exwm--after-exwm-init))))

(provide 'perspective-exwm)
;;; perspective-exwm.el ends here
