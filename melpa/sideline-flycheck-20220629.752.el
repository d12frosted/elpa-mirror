;;; sideline-flycheck.el --- Show flycheck errors with sideline  -*- lexical-binding: t; -*-

;; Copyright (C) 2022  Shen, Jen-Chieh
;; Created date 2022-06-14 17:10:48

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; URL: https://github.com/emacs-sideline/sideline-flycheck
;; Package-Version: 20220629.752
;; Package-Commit: 72e94b34c58e9497abb4f997d2de9f5978b50fa3
;; Version: 0.1.0
;; Package-Requires: ((emacs "27.1") (sideline "0.1.1") (flycheck "0.14") (ht "2.4"))
;; Keywords: convenience flycheck

;; This file is NOT part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
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
;;
;; This package allows display flycheck errors with sideline.
;;
;; 1) Add sideline-flycheck to sideline backends list,
;;
;;   (setq sideline-backends-right '(sideline-flycheck))
;;
;; 2) Then enable sideline-mode in the target buffer,
;;
;;   M-x sideline-mode
;;

;;; Code:

(require 'cl-lib)

(require 'sideline)
(require 'flycheck)
(require 'ht)

(defgroup sideline-flycheck nil
  "Show flycheck errors with sideline."
  :prefix "sideline-flycheck-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/emacs-sideline/sideline-flycheck"))

(defcustom sideline-flycheck-inhibit-functions nil
  "Functions to inhibit display of sideline flycheck."
  :type 'hook
  :group 'sideline-flycheck)

(defvar-local sideline-flycheck--old-display-function nil
  "The former value of `flycheck-display-errors-function'.")

(defvar-local sideline-flycheck--callback nil
  "Callback to display errors with sideline.")

(defvar-local sideline-flycheck--errors (ht-create)
  "Set to t when ready to do next rendering in sideline.")

;;;###autoload
(defun sideline-flycheck (command)
  "Backend for sideline.

Argument COMMAND is required in sideline backend."
  (cl-case command
    (`candidates (cons :async
                       (lambda (callback &rest _)
                         (setq sideline-flycheck--callback callback))))))

(defun sideline-flycheck--show (errors)
  "Display ERRORS, using sideline.el library."
  (when (and errors
             (not (run-hook-with-args-until-success 'sideline-flycheck-inhibit-functions))
             sideline-flycheck--callback)
    (let (msgs)
      (dolist (err errors)
        (let* ((level (flycheck-error-level err))
               (face (if (eq level 'info) 'success level))
               (msg (flycheck-error-message err)))
          (add-face-text-property 0 (length msg) face nil msg)
          (unless (ht-contains-p sideline-flycheck--errors msg)
            (ht-set sideline-flycheck--errors msg nil)
            (push msg msgs))))
      (funcall sideline-flycheck--callback msgs))))

(defun sideline-flycheck--reset ()
  "After sideline is reset."
  (ht-clear sideline-flycheck--errors))

;;;###autoload
(defun sideline-flycheck-setup ()
  "Setup for `flycheck-mode'."
  (cond
   (flycheck-mode
    (setq sideline-flycheck--old-display-function flycheck-display-errors-function)
    (setq-local flycheck-display-errors-function #'sideline-flycheck--show)
    (add-hook 'sideline-reset-hook #'sideline-flycheck--reset nil t))
   (t
    (setq-local flycheck-display-errors-function sideline-flycheck--old-display-function)
    (setq sideline-flycheck--old-display-function nil)
    (remove-hook 'sideline-reset-hook #'sideline-flycheck--reset t)
    (sideline-render))))  ; update sideline once

(provide 'sideline-flycheck)
;;; sideline-flycheck.el ends here
