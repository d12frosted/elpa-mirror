;;; quick-shell-keybind.el --- Interactively bind a key to shell commands

;; URL: https://github.com/eyeinsky/quick-shell-keybind
;; Package-Version: 20171023.613
;; Package-Commit: 5f4541a5a5554d108bf16b5fd1713e962161ca1b
;; Version: 0.0.1
;; Author: eyeinsky <eyeinsky9@gmail.com>
;; Keywords: maint convenience processes
;; Package-Requires: ((emacs "24"))

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; Interactive prompt for key, a shell buffer name, and a sequence of
;; shell commands to run in that buffer.  Simply pressing <RET> at
;; "Command to run" will stop it for asking for more.
;;
;; To set it up you bind the definer to some key, e.g:
;;
;;     (global-set-key (kbd "C-c C-t") #'quick-shell-keybind)
;;
;; Using this will now start the prompt sequence.
;;
;; The variable 'quick-shell-keybind-default-buffer-name' can be used
;; customize the default buffer to something other than "*shell*".


;;; Code:

(require 'comint)

(defgroup quick-shell-keybind nil
  "Quick shell keybind"
  :group 'tools)

(defcustom quick-shell-keybind-default-buffer-name "*shell*"
  "Default buffer name for target shell."
  :type 'string
  :group 'quick-shell-keybind)

(defun quick-shell-keybind--ask-until (n)
  "Ask commands until empty string, keep count with N."
  (let ((str (read-string (message "Command to run [%i]: " n))))
    (if	(string= str
		 "")
	'()
      (cons str (quick-shell-keybind--ask-until (+ 1 n))))))

(defun quick-shell-keybind--send (command)
  "Insert and execute COMMAND in sell."
  (insert command)
  (comint-send-input))

;;;###autoload
(defun quick-shell-keybind (key buffer commands)
  "Bind KEY to run in shell BUFFER a sequence of COMMANDS."
  (interactive (list (read-key-sequence "Enter key: ")
		     (read-string (message "Buffer (default %s): "
					   quick-shell-keybind-default-buffer-name) nil nil
					   quick-shell-keybind-default-buffer-name)
		     (quick-shell-keybind--ask-until 1)))
  (global-set-key (kbd key)
		  `(lambda ()
		     (interactive)
		     (with-current-buffer ',buffer
		       (goto-char (point-max))
		       (mapcar #'quick-shell-keybind--send ',commands)))))

(provide 'quick-shell-keybind)

;;; quick-shell-keybind.el ends here
