;;; company-native-complete.el --- Company completion using native-complete -*- lexical-binding: t; -*-

;; Copyright (C) 2019 by Troy Hinckley

;; Author: Troy Hinckley <troy.hinckley@gmail.com>
;; URL: https://github.com/CeleritasCelery/emacs-native-shell-complete
;; Package-Version: 20200315.2144
;; Package-Commit: cf142e84eaa4dd91bc75d96a5d26dab5e38eba4c
;; Version: 0.1.0
;; Package-Requires: ((emacs "25.1")(company "0.9.0")(native-complete "0.1.0"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This package provides a company backend for use with native-complete.

;;; Code:

(require 'native-complete)
(require 'company)

(defvar comint-redirect-hook)

(defun company-native-complete--candidates (callback)
  "Get candidates for `company-native-complete'.
Send results by calling CALLBACK."
  (add-hook 'comint-redirect-hook
            (lambda ()
              (setq comint-redirect-hook nil)
              (funcall callback (native-complete--get-completions))))
  (comint-redirect-send-command
   native-complete--redirection-command
   native-complete--buffer nil t))

(defun company-native-complete--prefix ()
  "Get prefix for `company-native-complete'."
  (when (native-complete--usable-p)
    (native-complete--get-prefix)
    (cond
     ((string-prefix-p "-" native-complete--prefix)
      (cons native-complete--prefix t))
     ((string-match-p "/" native-complete--common)
      (cons native-complete--prefix
            (+ (length native-complete--common)
               (length native-complete--prefix))))
     (t native-complete--prefix))))

;;;###autoload
(defun company-native-complete (command &rest _ignored)
  "Completion for native shell complete functionality.
Dispatch based on COMMAND."
  (interactive '(interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-native-complete))
    (prefix (company-native-complete--prefix))
    (candidates (cons :async 'company-native-complete--candidates))
    (ignore-case t)))

(provide 'company-native-complete)

;;; company-native-complete.el ends here
