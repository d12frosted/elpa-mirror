;;; yaml-tomato.el --- copy or show the yaml path currently under cursor.

;; Author: qrczeno
;; Created: 22-Nov-2015
;; Version: 0.1
;; Package-Version: 20151123.753
;; Package-Commit: 1272c502fac6ce6b0f8b7f8a9beb353f0b35e13c
;; Keywords: Yaml
;; Package-Requires: ((s "1.9"))

;;; Commentary:

;; Usage:
;; **yaml-tomato** provides two functions you could use while working with yaml file:
;;   - 'yaml-tomato-show-current-path' displays current yaml path under cursor in message box
;;   - 'yaml-tomato-copy' copies the current yaml path under cursor to kill-ring and clipboard

;;; Code:

(require 's)

(defvar yaml-tomato--spaces-per-tab 1)

(defun yaml-tomato--get-yaml-key (string)
  "Get the yaml tag from STRING."
  (car (s-slice-at ":" (s-trim string))))

(defun yaml-tomato--current-path ()
  "Get the tags path under cursor."
  (let* ((path '())
         (get-key (lambda () (yaml-tomato--get-yaml-key (s-trim (thing-at-point 'line t)))))
         (search-previous (lambda (spaces) (re-search-backward (s-concat "^" (s-repeat spaces " ") "[a-zA-Z\(]") nil t nil)))
         (white-spaces (current-indentation)))
    (save-excursion
      (while (not (bobp))
        (let* ((current-line (thing-at-point 'line t)))
          (end-of-line)
          (when (funcall search-previous white-spaces)
              (add-to-list 'path (funcall get-key)))
            (setq white-spaces (- white-spaces yaml-tomato--spaces-per-tab)))))
    path))

;;;###autoload
(defun yaml-tomato-show-current-path ()
  "Show current yaml path in message buffer."
  (interactive)
  (message (s-join "." (yaml-tomato--current-path))))

;;;###autoload
(defun yaml-tomato-copy ()
  "Copy current path to 'kill-ring'."
  (interactive)
  (kill-new (s-join "." (yaml-tomato--current-path))))

(provide 'yaml-tomato)
;;; yaml-tomato.el ends here
