;;; sideline-flymake.el --- Show flymake errors with sideline  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Shen, Jen-Chieh

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Maintainer: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/emacs-sideline/sideline-flymake
;; Package-Version: 20221009.1555
;; Package-Commit: e1e1f5cbdfa9ac352e884de97d68da4ea41cc060
;; Version: 0.1.1
;; Package-Requires: ((emacs "27.1") (sideline "0.1.0"))
;; Keywords: convenience flymake

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program. If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package allows display flymake errors with sideline.
;;
;; 1) Add sideline-flymake to sideline backends list,
;;
;;   (setq sideline-backends-right '(sideline-flymake))
;;
;; 2) Then enable sideline-mode in the target buffer,
;;
;;   M-x sideline-mode
;;

;;; Code:

(require 'cl-lib)
(require 'flymake)
(require 'subr-x)

(require 'sideline)

(defgroup sideline-flymake nil
  "Show flymake errors with sideline."
  :prefix "sideline-flymake-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/emacs-sideline/sideline-flymake"))

;;;###autoload
(defun sideline-flymake (command)
  "Backend for sideline.

Argument COMMAND is required in sideline backend."
  (cl-case command
    (`candidates (cons :async #'sideline-flymake--show-errors))))

(defun sideline-flymake--get-errors ()
  "Return flymake errors."
  ;; Don't need to take care of the region, since sideline cannot display with
  ;; region is active.
  (flymake-diagnostics (point)))

(defun sideline-flymake--show-errors (callback &rest _)
  "Execute CALLBACK to display with sideline."
  (when flymake-mode
    (when-let ((errors (sideline-flymake--get-errors)))
      (dolist (err errors)
        (let* ((text (flymake-diagnostic-text err))
               (type (flymake-diagnostic-type err))
               (face (cl-case type
                       ('eglot-error 'error)
                       ('eglot-warning 'warning)
                       (:error 'error)
                       (:warning 'warning)
                       (t 'success))))
          (add-face-text-property 0 (length text) face nil text)
          (funcall callback (list text)))))))

(provide 'sideline-flymake)
;;; sideline-flymake.el ends here
