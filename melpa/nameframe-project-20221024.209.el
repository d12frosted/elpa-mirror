;;; nameframe-project.el --- Nameframe integration with project.el

;; Author: John Del Rosario <john2x@gmail.com>
;; URL: https://github.com/john2x/nameframe
;; Package-Version: 20221024.209
;; Package-Commit: 3116b6738f74a95e144a75344355e09f72620e01
;; Version: 0.5.0-beta
;; Package-Requires: ((emacs "28.1") (nameframe "0.5.0-beta") (project "0.8.1"))

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

;; This package defines a function to advice
;; `project-switch-project' which will create/switch to a named frame
;; of the target project.

;; To use this library, put this file in your Emacs load path,
;; and call (nameframe-project-mode t).

;;; Code:

(require 'nameframe)
(require 'project)

;;;###autoload
(define-minor-mode nameframe-project-mode
  "Global minor mode that creates/switches to a frame when switching projects."
  :init-value nil
  :lighter nil
  :global t
  :group 'nameframe
  :require 'nameframe-project
  (cond
   (nameframe-project-mode
    (advice-add #'project-switch-project :before #'nameframe-project-switch-project-advice))
   (t
    (advice-remove #'project-switch-project #'nameframe-project-switch-project-advice))))

(defun nameframe-project-switch-project-advice (dir &rest args)
  "Advice for `project-switch-project' so a frame is created for a project.
DIR and ARGS are args for the adviced function."
  (let* ((name (file-name-nondirectory (directory-file-name dir)))
         (curr-frame (selected-frame))
         (frame-alist (nameframe-frame-alist))
         (frame (nameframe-get-frame name frame-alist)))
    (cond
     ;; project frame already exists
     ((and frame (not (equal frame curr-frame)))
      (select-frame-set-input-focus frame))
     ((not frame)
      (nameframe-make-frame name)))))

(provide 'nameframe-project)

;;; nameframe-project.el ends here
