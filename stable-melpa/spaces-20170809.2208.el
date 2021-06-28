;;; spaces.el --- Create and switch between named window configurations.
;;
;; Author: Steven Thomas
;; Created: 16 Oct 2011
;; Keywords: frames convenience
;; Package-Version: 20170809.2208
;; Package-Commit: 6bdb51e9a346907d60a9625f6180bddd06be6674
;; Version: 0.1.0
;; URL: https://github.com/chumpage/chumpy-windows
;;
;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.
;;
;;; Commentary:
;;
;; Spaces helps you manage complex window configurations by letting you
;; give them names and quickly switch between them. The core function
;; is sp-switch-space.
;;
;; See https://github.com/chumpage/chumpy-windows for more
;; documentation, and to submit patches.
;;
;;; Code:

(require 'ido)
(require 'cl)

(defvar sp-spaces nil
  "List of available spaces")
(defvar sp-current-space nil
  "The currently selected space")

(defun sp-string-empty (str) (= (length str) 0))

(defun sp-alist-remove (alist key)
  (remove* key alist :key 'car :test 'equal))

(defun sp-alist-move-to-front (alist key)
  (let ((element (assoc key alist)))
    (if element
        (cons element (sp-alist-remove alist key))
        (sp-alist-remove alist key))))

(defun sp-buffer-point-map ()
  (save-excursion
    (mapcar (lambda (buffer) (cons (buffer-name buffer)
                                   (progn (set-buffer buffer) (point))))
            (buffer-list))))

(defun sp-apply-buffer-points (buff-point-map)
  (mapc (lambda (window) (let* ((buffer (window-buffer window))
                                (buffer-point (cdr (assoc (buffer-name buffer) buff-point-map))))
                           (when buffer-point (set-window-point window buffer-point))))
        (window-list))
  nil)

(defun sp-space-exists (name)
  "Returns t if the specified space exists, nil otherwise."
  (not (null (assoc name sp-spaces))))

(defun sp-space-config (name)
  "Returns the space's window config."
  (when (not (sp-space-exists name))
    (error "no space '%S'" name))
  (cdr (assoc name sp-spaces)))

(defun sp-set-space-config (name config)
  "Sets the space's window config."
  (when (not (sp-space-exists name))
    (error "no space '%S'" name))
  (setcdr (assoc name sp-spaces) config))

(defun sp-space-names ()
  "Returns a list of all space names."
  (mapcar 'car sp-spaces))

(defun sp-space-configs ()
  "Returns a list of all space configs."
  (mapcar 'cdr sp-spaces))

(defun sp-apply-space-config (name)
  (when (not (sp-space-exists name))
    (error "no space '%S'" name))
  (let ((points (sp-buffer-point-map)))
    (set-window-configuration (sp-space-config name))
    (sp-apply-buffer-points points)))

(defun sp-new-space (&optional name)
  "Creates a new space with the given name. Called interactively,
prompts the user for the new space name."
  (interactive)
  (let ((name (or name (read-string "space name: "))))
    (setq sp-spaces (cons (cons name (current-window-configuration))
                         (sp-alist-remove sp-spaces name)))
    (setq sp-current-space name)))

(defun sp-save-space ()
  "Saves the configuration for the current space. This is done
automatically when you use sp-switch-space."
  (interactive)
  (sp-new-space sp-current-space))

(defun sp-clear-spaces (&optional disable-prompt)
  "Kills all spaces. Prompts the user to confirm unless
DISABLE-PROMPT is non-nil."
  (interactive)
  (when (and sp-spaces (not disable-prompt) (y-or-n-p "really kill all spaces? "))
    (setq sp-spaces nil)
    (setq sp-current-space nil)))

(defun sp-kill-space (&optional name)
  "Kills the specified space. Called interactively,
prompts the user for the space to kill."
  (interactive)
  (if (null sp-spaces)
      (error "no spaces defined yet")
      (let ((name (if name name (ido-completing-read "kill space: "
                                                     (append (sp-space-names) '("*all*"))))))
        (when (not (sp-string-empty name))
          (if (string-equal name "*all*")
              (sp-clear-spaces)
              (progn (when (string-equal sp-current-space name)
                       (setq sp-current-space nil))
                     (setq sp-spaces (sp-alist-remove sp-spaces name))))))))

(defun sp-switch-space (&optional name)
  "Switch to the specified space. Called interactively, prompts
the user for the space to switch to. Before the space is
switched, the current window configuration is saved in the
current space. As a special case, if the space we're switching to
is the current space, we reload the current space's saved
config."
  (interactive)
  (if (and (null name) (null sp-spaces))
      (sp-new-space)
      (let ((name (or name (ido-completing-read "space: "
                                                (let ((names (sp-space-names)))
                                                  (append
                                                   (remove* (car names) names :test 'equal)
                                                   (list (car names))))))))
        (when (not (sp-string-empty name))
          (if (string-equal sp-current-space name)
              ;; as a special case, if we're switching to the current space, just reload the
              ;; config
              (sp-apply-space-config name)
              ;; otherwise save the config for the current space, then load the config for
              ;; the newly selected space
              (progn (when sp-current-space
                       (sp-set-space-config sp-current-space (current-window-configuration)))
                     (if (sp-space-exists name)
                         (progn (setq sp-spaces (sp-alist-move-to-front sp-spaces name))
                                (setq sp-current-space name)
                                (sp-apply-space-config name))
                         (sp-new-space name))))))))

(defun sp-show-space ()
  "Show the current space in the minibuffer."
  (interactive)
  (if sp-current-space
      (message "%s" sp-current-space)
      (if sp-spaces
          (message "no space selected")
          (message "no spaces defined"))))

(provide 'spaces)

;; Local Variables:
;; byte-compile-warnings: (not cl-functions)
;; End:

;;; spaces.el ends here
