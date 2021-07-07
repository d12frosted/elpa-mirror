;;; helm-project-persist.el --- Helm integration for project-persist package
;;
;; Author: Sliim <sliim@mailoo.org>
;; Version: 1.0.0
;; Package-Version: 20151210.1543
;; Package-Commit: 357950fbac18090985a750e40d5d8b10ee9dcd53
;; Package-Requires: ((helm "1.5.2") (project-persist "0.1.4"))
;; Keywords: project-persist project helm

;; This file is not part of GNU Emacs.

;;; Commentary:

;; helm-project-persist provides capabilities to show and open
;; registered project from project-persist.

;;; License:

;; This program is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License
;; as published by the Free Software Foundation; either version 3
;; of the License, or (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Code:

;; requires
(require 'project-persist)
(require 'helm)
(require 'helm-files)

(defvar helm-c-source-project-persist-project-list
  `((name . "Project list")
    (disable-shortcuts)
    (init . (lambda ()
              (with-current-buffer (helm-candidate-buffer 'local)
                (insert
                 (s-join "\n" (project-persist--project-list))))))
    (candidates-in-buffer)
    (candidate-number-limit . 10)
    (keymap . ,helm-generic-files-map)
    (help-message . helm-generic-file-help-message)
    (mode-line . helm-generic-file-mode-line-string)
    (action . (lambda (candidate)
                (project-persist--offer-save-if-open-project)
                (project-persist--project-open candidate))))
  "Helm source definition.")

;;;###autoload
(defun helm-project-persist ()
  "Show and Open project with Helm."
  (interactive)
  (helm :sources '(helm-c-source-project-persist-project-list)
        :buffer "*helm-pp*"
        :prompt "Project: "))

(provide 'helm-project-persist)

;;; helm-project-persist.el ends here
