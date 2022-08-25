;;; geben-helm-projectile.el --- Integrate helm-projectile with geben

;; Copyright (C) 2016  Matthew Carter

;; Author: Matthew Carter <m@ahungry.com>
;; Maintainer: Matthew Carter <m@ahungry.com>
;; URL: https://github.com/ahungry/geben-helm-projectile
;; Package-Version: 20160611.59
;; Package-Commit: 14db489efcb20c5aa9102288c94cec3c5a87c35d
;; Version: 0.0.3
;; Keywords: ahungry emacs geben helm projectile debug
;; Package-Requires: ((emacs "24") (geben "0.26") (helm-projectile "0.13.0"))

;; This file is not part of GNU Emacs

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; helm-projectile integration for geben (in particular, opening files)

;; Make sure to include the project, then just run geben-helm-projectile-file
;; during an interactive geben session to open a file related to the project.

;;; News:

;;;; Changes since 0.0.2:
;; - Added an autoload line for the interactive export function

;;;; Changes since 0.0.1:
;; - Disable require statement for geben due to issue in it's defadvice

;;;; Changes since 0.0.0:
;; - Created the project

;; Commenting out at the moment, requiring geben causes a defadvice to trigger
;; within the geben package, that breaks network functionality in much of
;; the open-network-stream commands, with an error such as:
;; `ad-Advice-open-network-stream: Wrong type argument: processp, nil'
;; Will add again when issue is fixed in geben

;;(eval-and-compile
;;  (require 'geben)
;;  (require 'helm-projectile))

(defvar geben-helm-projectile-version "0.0.1")

;;; Code:

;;;###autoload
(defun geben-helm-projectile-open-file (&optional arg)
  "Find a file in the current project using helm-projectile to open it.

Use a prefix ARG to force a cache refresh."
  (interactive "P")
    (geben-with-current-session session
      (if (projectile-project-p)
          (projectile-maybe-invalidate-cache arg))
      (let ((helm-ff-transformer-show-only-basename nil)
            (my-sources helm-source-projectile-files-list)
            (file-path (file-name-directory
                        (replace-regexp-in-string "file:\/\/" ""
                        (geben-source-fileuri session (buffer-file-name))))))
	(when file-path
          (cd file-path))
        (add-to-list
         'my-sources
         '(action ("Geben" . (lambda (file) (geben-open-file (geben-source-fileuri session file))))))
        (helm :sources my-sources
              :buffer "*helm projectile*"
              :prompt (projectile-prepend-project-name (if (projectile-project-p)
                                                           "pattern: "
                                                         "Switch to project: "))
              ))))

(provide 'geben-helm-projectile)

;;; geben-helm-projectile.el ends here
