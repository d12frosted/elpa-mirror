;;; perspeen.el --- An Emacs package for multi-workspace  -*- lexical-binding: t; -*-

;; Copyright (C) 2016  Peng Li

;; Author: Peng Li <seudut@gmail.com>
;; Keywords: lisp
;; Package-Version: 20161130.1701
;; Package-Commit: 30ee14339cf8fe2e59e5384085afee3f8eb58dda

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

;; This package is intended to combine perspective and elscreen, make each workspace
;; has its own buffers window-configuration and tabs. The goal is to make Emacs much
;; convenient to work with multiple workspaces at the same time.
;; the same time.

;;; Code:

(defgroup perspeen nil
  "A minor mode combining perspeen and elscreen "
  :group 'frame)

(defface perspeen-selected-face
  '((t (:weight bold :foreground "Black" :background "Red")))
  "Face used to highlight the current perspeen workspace on the modeline.")

(defcustom perspeen-modestring-dividers '("[" "]" "|")
  "Plist of strings used to divide workspace on modeline.")

(defvar perspeen-ws-before-switch-hook nil
  "Hook run before switch workspace.")

(defvar perspeen-ws-after-switch-hook nil
  "Hook run after switch workspace.")

(defun sd/make-variables-frame-local (&rest list)
  "Make all elements in list as frame local variable"
  (mapc (lambda (v)
	    (make-variable-frame-local v))
	  list))

(sd/make-variables-frame-local
 (defvar perspeen-modestring nil
   "The string displayed on the modeline representing the perspeen-mode.")
 (defvar perspeen-ws-list nil
   "The list storing all workspace in current frame.")
 (defvar perspeen-current-ws nil
   "The perspeen structure with current workspace.")
 (defvar perspeen-last-ws nil
   "The perspeen structure with last workspace.")
 (defvar perspeen-max-ws-prefix 1
   "The prefix number of the workspace name."))

(put 'perspeen-modestring 'risky-local-variable t)

;;* Keymap
(defvar perspeen-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "s-c") 'perspeen-create-ws)
    (define-key map (kbd "s-n") 'perspeen-next-ws)
    (define-key map (kbd "s-p") 'perspeen-previous-ws)
    (define-key map (kbd "s-`") 'perspeen-goto-last-ws)
    (define-key map (kbd "s-e") 'perspeen-ws-eshell)
    map)
  "Keymap for perspeen-mode.")

(cl-defstruct (perspeen-ws-struct)
  name buffers killed local-variables
  (root-dir default-directory)
  (buffer-history buffer-name-history)
  (window-configuration (current-window-configuration))
  (point-marker (point-marker)))
  
	  
(defun perspeen-update-mode-string ()
  "Update `perspeen-modestring' when `perspeen-ws-list' is changed."
  (let ((full-string))
    (mapc (lambda (ws)
	    (let* ((name (perspeen-ws-struct-name ws))
		   (string-name (format "%s" name))
		   (prop-name))
	      (if (equal name (perspeen-ws-struct-name perspeen-current-ws))
		  (setq prop-name (propertize string-name 'face 'perspeen-selected-face))
		(setq prop-name (propertize string-name 'mouse-face 'mode-line-highlight)))
	      (setq full-string (append full-string
					(list (nth 2 perspeen-modestring-dividers) prop-name)))))
	  perspeen-ws-list)
    (setq full-string (cdr full-string))
    (setq perspeen-modestring (append (list (nth 0 perspeen-modestring-dividers))
				      full-string
				      (list (nth 1 perspeen-modestring-dividers))))))

(defun perspeen-create-ws ()
  "Create a new workspace."
  (interactive)
  (perspeen-new-ws-internal)
  (perspeen-update-mode-string))

(defun perspeen-delete-ws ()
  "Remove current workspace."
  (interactive)
  (let ((prev-ws))
    (setq prev-ws (nth 1 (memq perspeen-current-ws (reverse perspeen-ws-list))))
    (delq perspeen-current-ws perspeen-ws-list)
    (perspeen-switch-ws-internal prev-ws))
  (perspeen-update-mode-string))

(defun perspeen-rename-ws (name)
  "Rename the current workspace. The workspace name begin with a number and
a comma as the prefix, the command won't change the prefix."
  (interactive
   (list (read-string "Enter the new name: ")))
  (let ((old-name (perspeen-ws-struct-name perspeen-current-ws))
	(new-name))
    (setq new-name (replace-regexp-in-string ":.*$" (concat ":" name " ") old-name))
    (setf (perspeen-ws-struct-name perspeen-current-ws) new-name))
  (perspeen-update-mode-string))

(defun perspeen-ws-eshell (&optional arg)
  "Create or switch to eshell buffer with current workspace root directory."
  (interactive)
  (let* ((ebufs)
	 (dir-name (car (last (split-string (perspeen-ws-struct-root-dir perspeen-current-ws)
					    "/" t))))
	 (new-eshell-name)
	 (full-eshell-name)
	 (ii 1))
    (setq ebufs
	  (delq nil (mapcar (lambda (buf)
			      (if (and (buffer-live-p buf)
				       (equal (with-current-buffer buf major-mode) 'eshell-mode))
				  buf))
			    (perspeen-ws-struct-buffers perspeen-current-ws))))
    (if (> (length ebufs) 0)
	(switch-to-buffer (car ebufs))
      (with-temp-buffer
	(setq-local default-directory (perspeen-ws-struct-root-dir perspeen-current-ws))
	(eshell 'N)
	(setq new-eshell-name (concat eshell-buffer-name "<" dir-name ">"))
	(setq full-eshell-name new-eshell-name)
	(while (get-buffer full-eshell-name)
	  (setq ii (+ ii 1))
	  (setq full-eshell-name (concat new-eshell-name "-" (number-to-string ii))))
	(rename-buffer full-eshell-name)
	(push (current-buffer) (perspeen-ws-struct-buffers perspeen-current-ws))))))

(defun perspeen-change-root-dir (dir)
  "Change the root direcoty of current workspace."
  (interactive
   (list (read-directory-name "Inpu Dir: " default-directory)))
  (setq dir (directory-file-name dir))
  (setf (perspeen-ws-struct-root-dir perspeen-current-ws) dir)
  ;; change the default directory of scratch buffer
  (mapc (lambda (buf)
	  (when (and (buffer-name buf) (string-match "^*scratch" (buffer-name buf)))
	    (with-current-buffer buf
	      (setq-local default-directory dir))))
	(perspeen-ws-struct-buffers perspeen-current-ws))
  ;; rename current ws
  (perspeen-rename-ws (car (last
			    (split-string (perspeen-ws-struct-root-dir perspeen-current-ws) "/" t))))
  (perspeen-update-mode-string)
  (message "Root directory chagned to %s" (format dir)))

(defun perspeen-next-ws ()
  "Switch to next workspace."
  (interactive)
  (let ((next-ws))
    (setq next-ws (nth 1 (memq perspeen-current-ws perspeen-ws-list)))
    (perspeen-switch-ws-internal (or next-ws (nth 0 perspeen-ws-list))))
  (perspeen-update-mode-string))

(defun perspeen-previous-ws ()
  "Switch to previous wrokspace."
  (interactive)
  (let ((prev-ws))
    (setq prev-ws (nth 1 (memq perspeen-current-ws (reverse perspeen-ws-list))))
    (perspeen-switch-ws-internal (or prev-ws (nth 0 (reverse perspeen-ws-list)))))
  (perspeen-update-mode-string))

(defun perspeen-goto-last-ws ()
  "Switch to the last workspace."
  (interactive)
  (when perspeen-last-ws
    (perspeen-switch-ws-internal perspeen-last-ws)
    (perspeen-update-mode-string)))

(defun perspeen-goto-ws (index)
  "Switch to the index workspace. Index is a numeric argument."
  (interactive "p")
  (if (and (<= index (length perspeen-ws-list))
	   (> index 0))
      (progn
	(perspeen-switch-ws-internal (nth (- index 1) perspeen-ws-list))
	(perspeen-update-mode-string))
    (message "No %d workspace found" index)))

(defun perspeen-switch-ws-internal (ws)
  "Switch to another workspace. Save the old windows configuration
and restore the new configuration."
  (when ws
    (unless (equal ws perspeen-current-ws)
      (run-hooks 'perspeen-ws-before-switch-hook)
      ;; save the windows configuration and point marker
      (setf (perspeen-ws-struct-window-configuration perspeen-current-ws) (current-window-configuration))
      (setf (perspeen-ws-struct-point-marker perspeen-current-ws) (point-marker))
      ;; set the current and last  workspace
      (setq perspeen-last-ws perspeen-current-ws)
      (setq perspeen-current-ws ws)
      ;; pop up the previous windows configuration and point marker
      (set-window-configuration (perspeen-ws-struct-window-configuration perspeen-current-ws))
      (goto-char (perspeen-ws-struct-point-marker perspeen-current-ws))
      (run-hooks 'perspeen-ws-after-switch-hook))))

(defun perspeen-get-new-ws-name ()
  "Generate a name for a new workspace."
  (let ((name))
    (setq name (concat " " (number-to-string perspeen-max-ws-prefix)":ws "))
    (setq perspeen-max-ws-prefix (+ perspeen-max-ws-prefix 1))
    name))

(defun perspeen-new-ws-internal ()
  "Create a new workspace."
  (let ((new-ws (make-perspeen-ws-struct :name (perspeen-get-new-ws-name))))
    (add-to-list 'perspeen-ws-list new-ws t)
    (setq perspeen-last-ws perspeen-current-ws)
    (setq perspeen-current-ws new-ws))
  ;; if it the first workspace, use the current buffer list
  ;; else add new scratch buffer and clear the buffers
  (if (= 1 (length perspeen-ws-list))
      (progn
	(setf (perspeen-ws-struct-buffers perspeen-current-ws)
	      ;; remove the buffer begins with space, which are invisible
	      (delq nil (mapcar (lambda (buf)
				  (unless (string-match "^ " (buffer-name buf))
				    buf))
				(buffer-list)))))
    ;; This is not the first workspace
    (switch-to-buffer (concat "*scratch*<" (perspeen-ws-struct-name perspeen-current-ws) ">"))
    (insert (concat ";; " (buffer-name) "\n\n"))
    (setf (perspeen-ws-struct-buffers perspeen-current-ws) (list (current-buffer)))
    (funcall initial-major-mode)
    (delete-other-windows)
    ;; initialize the windows configuration of the new workspace
    (setf (perspeen-ws-struct-window-configuration perspeen-current-ws) (current-window-configuration))
    (setf (perspeen-ws-struct-point-marker perspeen-current-ws) (point-marker))))

(defun perspeen-set-ido-buffers ()
  "Change the variable `ido-temp-list' to restrict the ido buffers candidates."
  ;; modify the ido-temp-list and restrict the ido candidates
  ;; only add the same buffer in ido-temp-list and current workspace buffers
  (setq ido-temp-list
	(remq nil
	      (mapcar (lambda (buf-name)
			(if (member (get-buffer buf-name) (perspeen-ws-struct-buffers perspeen-current-ws))
			    buf-name))
		      ido-temp-list))))


(defun perspeen-switch-to-buffer (buf-or-name &optional norecord force-same-window)
  "Advice of switch to buffer, add the new buffer to the buffer list of current workspace."
  (when buf-or-name
    (unless (memq (get-buffer buf-or-name) (perspeen-ws-struct-buffers perspeen-current-ws))
      (push (get-buffer buf-or-name) (perspeen-ws-struct-buffers perspeen-current-ws)))))

(defun perspeen-display-buffer (buffer-or-name &optional action frame)
  "Advice of display buffer, add it to the buffer list of current workspace."
  (when buffer-or-name
    (unless (memq (get-buffer buffer-or-name) (perspeen-ws-struct-buffers perspeen-current-ws))
      (push (get-buffer buffer-or-name) (perspeen-ws-struct-buffers perspeen-current-ws)))))

;;;###autoload
(define-minor-mode perspeen-mode
  "Toggle Perspeen mode on or off."
  :global t
  :keymap perspeen-mode-map
  (if perspeen-mode
      (progn
	;; init local variables
	(setq perspeen-ws-list '())
	(setq global-mode-string (or global-mode-string '("")))
	;; create first workspace and put in into hash
	(perspeen-new-ws-internal)
	;; update perspeen-modestring
	(perspeen-update-mode-string)
	(unless (memq 'perspeen-modestring global-mode-string)
	  (setq global-mode-string (append global-mode-string '(perspeen-modestring))))
	(advice-add 'switch-to-buffer :after #'perspeen-switch-to-buffer)
	(advice-add 'display-buffer :after #'perspeen-display-buffer)
	(add-hook 'ido-make-buffer-list-hook 'perspeen-set-ido-buffers)
	
	;; run the hooks
	(run-hooks 'perspeen-mode-hook))
    ;; clear variables
    (setq global-mode-string (delq 'perspeen-modestring global-mode-string))
    (remove-hook 'ido-make-buffer-list-hook 'perspeen-set-ido-buffers)
    (advice-remove 'switch-to-buffer #'perspeen-switch-to-buffer)
    (advice-remove 'display-buffer #'perspeen-display-buffer)
    (setq perspeen-max-ws-prefix 1)
    (setq perspeen-ws-list nil)))

(provide 'perspeen)
;;; perspeen.el ends here
