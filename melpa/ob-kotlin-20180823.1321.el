;;; ob-kotlin.el --- org-babel functions for kotlin evaluation

;; Copyright (C) 2015 ZHOU Feng

;; Author: ZHOU Feng <zf.pascal@gmail.com>
;; URL: http://github.com/zweifisch/ob-kotlin
;; Package-Version: 20180823.1321
;; Package-Commit: b817ffb7fd03a25897eb2aba24af2035bbe3cfa8
;; Keywords: org babel kotlin
;; Version: 0.0.1
;; Created: 12th Mar 2015
;; Package-Requires: ((org "8"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; org-babel functions for kotlin evaluation
;;

;;; Code:
(require 'ob)

(defvar ob-kotlin-process-output "")

(defvar ob-kotlin-eoe "ob-kotlin-eoe")

(defgroup ob-kotlin nil
  "org-babel functions for kotlin evaluation"
  :group 'org)

(defcustom ob-kotlin:kotlinc "kotlinc"
  "kotlin compiler"
  :group 'ob-kotlin
  :type 'string)

(defun org-babel-execute:kotlin (body params)
  (let ((session (cdr (assoc :session params)))
        (file (cdr (assoc :file params))))
    (ob-kotlin--ensure-session session)
    (let* ((tmp (org-babel-temp-file "kotlin-"))
           (load (progn
                   (with-temp-file tmp (insert body))
                   (format ":load %s" tmp)))
           (result (ob-kotlin-eval-in-repl session load)))
      (unless file result))))

(defun ob-kotlin--ensure-session (session)
  (let ((name (format "*ob-kotlin-%s*" session)))
    (unless (and (get-process name)
                 (process-live-p (get-process name)))
      (let ((process (with-current-buffer (get-buffer-create name)
                       (start-process name name ob-kotlin:kotlinc))))
        (sit-for 1)
        (set-process-filter process 'ob-kotlin--process-filter)
        (ob-kotlin--wait "Welcome to Kotlin")))))

(defun ob-kotlin--process-filter (process output)
  (setq ob-kotlin-process-output (concat ob-kotlin-process-output output)))

(defun ob-kotlin--wait (pattern)
  (while (not (string-match-p pattern ob-kotlin-process-output))
    (sit-for 1)))

(defun ob-kotlin-eval-in-repl (session body)
  (let ((name (format "*ob-kotlin-%s*" session)))
    (setq ob-kotlin-process-output "")
    (process-send-string name (format "%s\n\"%s\"\n" body ob-kotlin-eoe))
    (accept-process-output (get-process name) nil nil 1)
    (ob-kotlin--wait ob-kotlin-eoe)
    (replace-regexp-in-string
     "^>>> " ""
     (replace-regexp-in-string
      (format "\\(^>>> \\)?%s\n" ob-kotlin-eoe) "" ob-kotlin-process-output))))

(provide 'ob-kotlin)
;;; ob-kotlin.el ends here
