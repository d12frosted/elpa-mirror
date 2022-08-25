;;; nameframe-projectile.el --- Nameframe integration with Projectile

;; Author: John Del Rosario <john2x@gmail.com>
;; URL: https://github.com/john2x/nameframe
;; Package-Version: 20160928.403
;; Package-Commit: 696223c61ca8e8f5cc557d2c198801a2f3c32ad3
;; Version: 0.4.1-beta
;; Package-Requires: ((nameframe "0.4.1-beta") (projectile "0.13.0"))

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

;; This package defines a function to replace Projectile's
;; `projectile-switch-project' which will create/switch to a named frame
;; of the target project.

;; To use this library, put this file in your Emacs load path,
;; and call (nameframe-projectile-mode t).

;;; Code:

(require 'nameframe)
(require 'projectile)

;;;###autoload
(define-minor-mode nameframe-projectile-mode
  "Global minor mode that creates/switches to a frame when switching projects."
  :init-value nil
  :lighter nil
  :global t
  :group 'nameframe
  :require 'nameframe-projectile
  (cond
   (nameframe-projectile-mode
    (nameframe-projectile--add-advice-around-switch-project-by-name)
    (add-hook 'projectile-before-switch-project-hook #'nameframe-projectile--before-switch-project-hook))
   (t
    (remove-hook 'projectile-before-switch-project-hook #'nameframe-projectile--before-switch-project-hook))))

(defun nameframe-projectile--before-switch-project-hook ()
  "Hook to create/switch to a project's frame."
  (let* ((project-to-switch nameframe-projectile--project-to-switch)  ;; set by advise
         (name (file-name-nondirectory (directory-file-name project-to-switch)))
         (curr-frame (selected-frame))
         (frame-alist (nameframe-frame-alist))
         (frame (nameframe-get-frame name frame-alist)))
    (cond
     ;; project frame already exists
     ((and frame (not (equal frame curr-frame)))
      (select-frame-set-input-focus frame))
     ((not frame)
      (nameframe-make-frame name)))))

(defun nameframe-projectile-switch-project-by-name (projectile-switch-project-by-name &rest args)
  "Workaround for https://github.com/bbatsov/projectile/issues/1056
Set the variable nameframe-projectile--project-to-switch to the target project so our hooks can use it."
  (let* ((nameframe-projectile--project-to-switch (car args)))
    (apply projectile-switch-project-by-name args)))

(defun nameframe-projectile--add-advice-around-switch-project-by-name ()
  "Workaround for https://github.com/bbatsov/projectile/issues/1056"
  (advice-add #'projectile-switch-project-by-name :around #'nameframe-projectile-switch-project-by-name))

(provide 'nameframe-projectile)

;;; nameframe-projectile.el ends here
