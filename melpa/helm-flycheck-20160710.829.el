;;; helm-flycheck.el --- Show flycheck errors with helm

;; Copyright (C) 2013-2016 Yasuyuki Oka <yasuyk@gmail.com>

;; Author: Yasuyuki Oka <yasuyk@gmail.com>
;; Version: 0.4
;; Package-Version: 20160710.829
;; Package-Commit: 3cf7d3bb194acacc6395f88360588013d92675d6
;; URL: https://github.com/yasuyk/helm-flycheck
;; Package-Requires: ((dash "2.12.1") (flycheck "28") (helm-core "1.9.8"))
;; Keywords: helm, flycheck

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

;; Installation:

;; Add the following to your Emacs init file:
;;
;;  (require 'helm-flycheck) ;; Not necessary if using ELPA package
;;  (eval-after-load 'flycheck
;;    '(define-key flycheck-mode-map (kbd "C-c ! h") 'helm-flycheck))

;; That's all.

;;; Code:

(require 'dash)
(require 'flycheck)
(require 'helm)

(defvar helm-source-flycheck
  '((name . "Flycheck")
    (init . helm-flycheck-init)
    (candidates . helm-flycheck-candidates)
    (action-transformer helm-flycheck-action-transformer)
    (multiline)
    (action . (("Go to" . helm-flycheck-action-goto-error)))
    (follow . 1)))


(defvar helm-flycheck-candidates nil)

(defconst helm-flycheck-status-message-no-errors
  "There are no errors in the current buffer.")

(defconst helm-flycheck-status-message-syntax-checking
  "Syntax checking now. Do action to reexecute `helm-flycheck'.")

(defconst helm-flycheck-status-message-checker-not-found
  "A suitable syntax checker is not found. \
See Selection in flycheck manual, for more information.")

(defconst helm-flycheck-status-message-failed
  "The syntax check failed. Inspect the *Messages* buffer for details.")

(defconst helm-flycheck-status-message-dubious
  "The syntax check had a dubious result. \
Inspect the *Messages* buffer for details.")

(defun helm-flycheck-init ()
  "Initialize `helm-source-flycheck'."
  (setq helm-flycheck-candidates
        (if (flycheck-has-current-errors-p)
            (mapcar 'helm-flycheck-make-candidate
                    (sort flycheck-current-errors #'flycheck-error-<))
          (list (helm-flycheck-status-message)))))

(defun helm-flycheck-status-message ()
  "Return message about `flycheck' STATUS."
  (cond ((equal flycheck-last-status-change 'finished)
         helm-flycheck-status-message-no-errors)
        ((equal flycheck-last-status-change 'running)
         helm-flycheck-status-message-syntax-checking)
        ((equal flycheck-last-status-change 'no-checker)
         helm-flycheck-status-message-checker-not-found)
        ((equal flycheck-last-status-change 'errored)
         helm-flycheck-status-message-failed)
        ((equal flycheck-last-status-change 'suspicious)
         helm-flycheck-status-message-dubious)))

(defun helm-flycheck-make-candidate (error)
  "Return a cons constructed from string of message and ERROR."
  (cons (helm-flycheck-candidate-display-string error) error))

(defun helm-flycheck-candidate-display-string (error)
  "Return a string of message constructed from ERROR."
  (let ((face (-> error
                flycheck-error-level
                flycheck-error-level-error-list-face)))
    (format "%5s %3s%8s  %s"
            (propertize (number-to-string (flycheck-error-line error)) 'font-lock-face 'flycheck-error-list-line-number)
            (-if-let (column (flycheck-error-column error))
                (propertize (number-to-string column) 'font-lock-face 'flycheck-error-list-column-number) "")
            (propertize (symbol-name (flycheck-error-level error))
                        'font-lock-face face)
            (or (flycheck-error-message error) ""))))

(defun helm-flycheck-action-transformer (actions candidate)
  "Return modified ACTIONS if CANDIDATE is status message."
  (if (stringp candidate)
      (cond ((string= candidate helm-flycheck-status-message-no-errors) nil)
            ((string= candidate helm-flycheck-status-message-syntax-checking)
             '(("Reexecute helm-flycheck" . helm-flycheck-action-reexecute)))
            ((string= candidate helm-flycheck-status-message-checker-not-found)
             '(("Enter info of Syntax checker selection" .
                helm-flycheck-action-selection-info)))
            ((or (string= candidate helm-flycheck-status-message-failed)
                 (string= candidate helm-flycheck-status-message-dubious))
             '(("Switch to *Messages*" .
                helm-flycheck-action-switch-to-messages-buffer))))
    actions))

(defun helm-flycheck-action-goto-error (candidate)
  "Visit error of CANDIDATE."
  (let ((buffer (flycheck-error-buffer candidate))
        (lineno (flycheck-error-line candidate))
        error-pos)
    (with-current-buffer buffer
      (switch-to-buffer buffer)
      (goto-char (point-min))
      (forward-line (1- lineno))
      (setq error-pos
            (car
             (->> (flycheck-overlays-in
                   (point)
                   (save-excursion (forward-line 1) (point)))
               (-map #'overlay-start)
               -uniq
               (-sort #'<=))))
      (goto-char error-pos)
      (let ((recenter-redisplay nil))
        (recenter)))))

(defun helm-flycheck-action-reexecute (candidate)
  "Reexecute `helm-flycheck' without CANDIDATE."
  (catch 'exit
    (helm-run-after-exit 'helm-flycheck)))

(defun helm-flycheck-action-switch-to-messages-buffer (candidate)
  "Switch to *Messages* buffer without CANDIDATE."
  (switch-to-buffer "*Messages*"))

(defun helm-flycheck-action-selection-info (candidate)
  "Enter info of flycheck syntax checker selection without CANDIDATE."
  (info "(flycheck)Top > Usage > Selection"))

(defun helm-flycheck-preselect ()
  "PreSelect nearest error from the current point."
  (let* ((point (point))
         (overlays-at-point (flycheck-overlays-at point))
         candidates nearest-point)
    (if overlays-at-point
        (helm-flycheck-candidate-display-string
         (car (flycheck-overlay-errors-at point)))
      (setq candidates (->> (flycheck-overlays-in (point-min) (point-max))
                         (-map #'overlay-start)
                         -uniq))
      (setq nearest-point (helm-flycheck-nearest-point point candidates))
      (when nearest-point
        (helm-flycheck-candidate-display-string
         (car (flycheck-overlay-errors-at nearest-point)))))))

(defun helm-flycheck-nearest-point (current-point points)
  "Return nearest point from CURRENT-POINT in POINTS."
  (--tree-reduce-from
   (if (< (abs (- current-point it)) (abs (- current-point acc)))
       it acc) (car points) points))

;;;###autoload
(defun helm-flycheck ()
  "Show flycheck errors with `helm'."
  (interactive)
  (unless flycheck-mode
    (user-error "Flycheck mode not enabled"))
  (helm :sources 'helm-source-flycheck
        :buffer "*helm flycheck*"
        :preselect (helm-flycheck-preselect)))

(provide 'helm-flycheck)

;; Local Variables:
;; coding: utf-8
;; End:

;;; helm-flycheck.el ends here
