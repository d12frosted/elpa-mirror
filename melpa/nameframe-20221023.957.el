;;; nameframe.el --- Manage frames by name.

;; Author: John Del Rosario <john2x@gmail.com>
;; URL: https://github.com/john2x/nameframe
;; Package-Version: 20221023.957
;; Package-Commit: 06d3400750c6b33ae215b9ac2922ee4dafd6b506
;; Version: 0.5.0-beta

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

;; This package defines utility functions for managing frames by their
;; names.  It is meant to be used together with Projectile (or
;; project.el) and perspective.el.
;;
;; To enable Projectile integration, call (nameframe-projectile-mode).
;; To enable project.el integration, call (nameframe-project-mode).
;; To enable perspective.el integration, call (nameframe-perspective-mode).

;;; Code:

(defgroup nameframe nil
  "Manage frames by name."
  :group 'tools
  :group 'convenience)

(defun nameframe-frame-alist ()
  "Return an alist of named frames."
  (nameframe--build-frames-alist-from-frame-list (frame-list)))

(defun nameframe-make-frame (frame-name)
  "Make a new frame with name FRAME-NAME."
  (let ((frame (make-frame `((name . ,frame-name)))))
    (select-frame-set-input-focus frame)
    (run-hook-with-args 'nameframe-make-frame-hook frame)))

(defun nameframe-frame-exists-p (frame-name &optional frame-alist)
  "Check if a frame with FRAME-NAME exists.
If FRAME-ALIST is non-nil, then it is used instead of calling
`nameframe-frame-alist'."
  (and (nameframe-get-frame frame-name frame-alist) t))

(defun nameframe-get-frame (frame-name &optional frame-alist)
  "Return the frame with FRAME-NAME if it exists, or nil.
If FRAME-ALIST is non-nil, then it is used instead of calling
`nameframe-frame-alist'."
  (let ((frame-alist (or frame-alist (nameframe-frame-alist))))
    (cdr (assoc frame-name frame-alist))))

(defmacro nameframe-with-frame (frame-name &rest body)
  "Create and/or switch to a frame named FRAME-NAME and execute BODY.
BODY is only executed iff a new frame is created."
  `(let ((frame (nameframe-get-frame ,frame-name)))
     (if (not frame)
         (let ((frame (nameframe-make-frame ,frame-name)))
           ,@body)
       (select-frame-set-input-focus frame))))

;;;###autoload
(defun nameframe-switch-frame (frame-name)
  "Interactively switch to an existing frame with name FRAME-NAME."
  (interactive
   (list (completing-read "Switch to frame: " (mapcar 'car (nameframe-frame-alist)))))
  ;; is it possible that `nameframe-frame-alist' would return a different value
  ;; from the previous call done in the `interactive' form above?
  (let* ((frame-alist (nameframe-frame-alist))
         (frame (nameframe-get-frame frame-name frame-alist)))
    (when frame
      (message "Switched to frame %s" frame-name)
      (select-frame-set-input-focus frame))))

;;;###autoload
(defun nameframe-create-frame (frame-name)
  "Interactively create a frame with name FRAME-NAME and switch to it."
  (interactive "sCreate frame named: ")
  (let* ((frame-alist (nameframe-frame-alist))
         (frame (nameframe-get-frame frame-name frame-alist)))
    (if (not frame)
        (let ((frame (nameframe-make-frame frame-name))
              (buffer-name "*scratch*"))
          (if (not (get-buffer buffer-name))
              (with-current-buffer (get-buffer-create buffer-name)
                (funcall initial-major-mode))
            (switch-to-buffer (get-buffer buffer-name))))
      (select-frame-set-input-focus frame))))

(defun nameframe--get-frame-name (frame)
  "Helper function to extract the name of a FRAME."
  (cdr (assq 'name (frame-parameters frame))))

(defun nameframe--build-frames-alist-from-frame-list (frame-list)
  "Return an alist of name-frame pairs from a FRAME-LIST (i.e. returned value of the `frame-list' function)."
  (mapcar (lambda (f) `(,(nameframe--get-frame-name f) . ,f)) frame-list))

(defcustom nameframe-make-frame-hook nil
  "Hooks run when a frame is created.
The created frame is passed as an argument to the hook functions."
  :group 'nameframe
  :type 'hook)

(provide 'nameframe)

;;; nameframe.el ends here
