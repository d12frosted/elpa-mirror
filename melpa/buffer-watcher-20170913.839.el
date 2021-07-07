;;; buffer-watcher.el --- Easily run shell scripts per filetype/directory when a buffer is saved

;; Copyright (C) 2014-2017 Nicolas Petton

;; Author: Nicolas Petton <nicolas@petton.fr>
;; Package: buffer-watcher
;; Package-Requires: ((f "0.16.2") (cl-lib "0.5"))
;; Package-Version: 20170913.839
;; Package-Commit: b32c67c8a5d724257d759f4c903d0dedc32246ef
;; Version: 0.1

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
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Makes it easy to run shell scripts per filetype/directory when a buffer is saved.

;;; Code:

(require 'f)
(require 'cl-lib)

(defcustom buffer-watcher-commands nil
  "List of all buffer-watcher commands to run.
Each entry is a list like the following:

  (mode directory shell_command)

name          The command name.
mode          The mode that should be active for the saved buffer.
directory     The directory in which the buffer file should be (or
              one subdirectory).
shell_command The shell command to run.  Occurences of \"%\" are replaced
              with the current buffer's file name."
  :group 'buffer-watcher
  :type '(repeat
          (list (string :tag "Command name")
                (symbol :tag "Active mode")
                (string :tag "Buffer file in directory")
                (string :tag "Shell command"))))

(defun buffer-watcher-run-commands ()
  "Run all commands for the current buffer."
  (dolist (command (buffer-watcher-current-buffer-commands))
    (buffer-watcher-run-command command)))

(defun buffer-watcher-run-command (command)
  "Run the buffer watcher command COMMAND for the current buffer."
  (let ((command-name (car command))
        (default-directory (concat (directory-file-name (nth 2 command)) "/"))
        (shell-command (nth 3 command)))
    (message "%s" (concat "Running buffer watcher " command-name "..."))
    (start-process-shell-command command-name
				 (get-buffer-create "*buffer-watcher-output*")
				 (buffer-watcher-shell-script shell-command))))


(defun buffer-watcher-shell-script (script)
  "Return the final shell script to execute.
Occurences of \"%\" in SCRIPT are replaced with the current buffer's file name."
  (replace-regexp-in-string "\\%" (shell-quote-argument (buffer-file-name)) script))

(defun buffer-watcher-current-buffer-commands ()
  "Return all commands that apply to the current buffer."
  (delq nil (mapcar (lambda (command)
                      (let ((mode (cadr command))
                            (directory (cl-caddr command)))
                        (and (eq major-mode mode)
                             (f-descendant-of? (buffer-file-name) directory)
                             command)))
                    buffer-watcher-commands)))

(add-hook 'after-save-hook #'buffer-watcher-run-commands)

(provide 'buffer-watcher)
;;; buffer-watcher.el ends here
