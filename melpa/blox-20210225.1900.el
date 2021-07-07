;;; blox.el --- Interaction with Roblox tooling -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Kenneth Loeffler

;; Author: Kenneth Loeffler <kenneth.loeffler@outlook.com>
;; Version: 0.3.0
;; Package-Version: 20210225.1900
;; Package-Commit: 2bf0e618451fb1da11263d8a35ffcd9210590c0a
;; Keywords: roblox, rojo, tools
;; URL: https://github.com/kennethloeffler/blox
;; Package-Requires: ((emacs "25.1"))

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

;; blox provides functions to run Roblox tooling such as Rojo (see
;; https://github.com/rojo-rbx/rojo) from Emacs.

;; blox doesn't bind any keys by itself; assuming `lua-mode' is
;; installed and loaded, a configuration might look something like
;; this:

;; (require 'blox)

;; (define-key lua-prefix-mode-map (kbd "s") #'blox-prompt-serve)
;; (define-key lua-prefix-mode-map (kbd "b") #'blox-prompt-build)
;; (define-key lua-prefix-mode-map (kbd "t") #'blox-test)

;; Or with `use-package':

;; (use-package blox
;;   :bind (:map lua-prefix-mode-map
;;               ("s" . blox-prompt-serve)
;;               ("b" . blox-prompt-build)
;;               ("t" . blox-test)))

;;; Code:

(defgroup blox nil
  "Customization for Roblox tooling."
  :prefix 'blox-
  :group 'tools)

(defgroup blox-executables nil
  "Names of executable files."
  :group 'blox)

(defcustom blox-binary-output nil
  "Whether to output binary place and model files."
  :type 'boolean
  :group 'blox)

(defcustom blox-default-project "default.project.json"
  "The name of the Rojo project file to use by default."
  :type 'string
  :group 'blox)

(defcustom blox-test-project "test.project.json"
  "The name of the project file to use for `blox-test'."
  :type 'string
  :group 'blox)

(defcustom blox-test-script "TestRunner.server.lua"
  "The name of the Lua script file to use for `blox-test'."
  :type 'string
  :group 'blox)

(defcustom blox-rojo-executable "rojo"
  "The name of the executable to use when running Rojo."
  :type 'string
  :group 'blox-executables)

(defcustom blox-run-in-roblox-executable "run-in-roblox.exe"
  "The name of the executable to use when running run-in-roblox."
  :type 'string
  :group 'blox-executables)

(defun blox--save-some-lua-mode-buffers ()
  "Prompt to save any unsaved `lua-mode' buffers."
  (save-some-buffers nil (lambda ()
                           (eq major-mode 'lua-mode))))

(defun blox--echo (message-string command-name)
  "Display MESSAGE-STRING prefixed with COMMAND-NAME in the echo area.
Removes any trailing newlines from MESSAGE-STRING."
  (message "[%s]: %s"
           command-name
           (replace-regexp-in-string "\n\\'" "" message-string)))

(defun blox--echo-filter (command-name)
  "Process filter to display process output in the echo area.
The filter prefixes any output with COMMAND-NAME and writes the
result to the process buffer, in addition to displaying it in the
echo area."
  (lambda (proc string)
    (with-current-buffer (process-buffer proc)
      (let ((moving (= (point) (process-mark proc))))
        (setq buffer-read-only nil)
        (save-excursion
          (goto-char (process-mark proc))
          (insert string)
          (set-marker (process-mark proc) (point)))
        (if moving (goto-char (process-mark proc)))
        (setq buffer-read-only t))
      (blox--echo string command-name))))

(defun blox--run-in-roblox-sentinel (buffer)
  "Process sentinel to call `display-buffer' on BUFFER.
Also enable `help-mode' in BUFFER and display a message in the
echo area."
  (lambda (_process _event)
    (with-current-buffer buffer
      (help-mode)
      (display-buffer buffer)
      (blox--echo "Waiting for output from Roblox Studio...done"
                  "blox-run-in-roblox"))))

(defun blox--run-after-build-sentinel (script-path project-path)
  "Process sentinel to run SCRIPT-PATH in PROJECT-PATH once finished."
  (lambda (_process event)
    (if (equal event "finished\n")
        (blox-run-in-roblox
         script-path
         (blox--build-filename project-path)))))

(defun blox--kill-if-running-p (process-name)
  "Prompt to kill the process buffer of PROCESS-NAME if it is running.
Return t if the answer is \"yes\" or if the process is not
running.  Return nil if the process is running and the answer is
\"no\"."
  (or (not (get-process process-name))
      (kill-buffer (process-buffer (get-process process-name)))))

(defun blox--roblox-file-extension (project-path)
  "Return the appropriate Roblox file extension for PROJECT-PATH."
  (with-temp-buffer
    (insert-file-contents project-path)
    (concat (if (search-forward "DataModel" nil t)
                ".rbxl"
              ".rbxm")
            (if blox-binary-output "" "x"))))

(defun blox--build-filename (project-path)
  "Return the path of the build corresponding to PROJECT-PATH."
  (concat (file-name-sans-extension (file-name-base project-path))
          (blox--roblox-file-extension project-path)))

(defun blox--path (filename)
  "Use function `locate-dominating-file' to find FILENAME.
Start at `default-directory'.  If the file cannot be located,
fall back to `default-directory' to make Rojo generate an error
message.  Return the path to the file."
  (concat (or (locate-dominating-file default-directory filename)
              default-directory)
          filename))

(defun blox-rojo-serve (project-path)
  "Serve the Rojo project at PROJECT-PATH."
  (blox--save-some-lua-mode-buffers)
  (if (blox--kill-if-running-p "*rojo-serve*")
      (with-current-buffer (get-buffer-create "*rojo-serve*")
        (cd (file-name-directory project-path))
        (help-mode)
        (make-process
         :name "*rojo-serve*"
         :buffer (current-buffer)
         :filter (blox--echo-filter "blox-rojo-serve")
         :command
         (list blox-rojo-executable "serve"
               (file-name-nondirectory project-path))))))

(defun blox-rojo-build (project-path &optional sentinel)
  "Build the Rojo project at PROJECT-PATH.
If the function SENTINEL is provided, attach it to the Rojo
process."
  (blox--save-some-lua-mode-buffers)
  (with-current-buffer (get-buffer-create "*rojo-build*")
    (cd (file-name-directory project-path))
    (help-mode)
    (make-process
     :name "*rojo-build*"
     :buffer (current-buffer)
     :filter (blox--echo-filter "blox-rojo-build")
     :sentinel sentinel
     :command
     (list blox-rojo-executable "build"
           (file-name-nondirectory project-path)
           "--output" (blox--build-filename project-path)))))

(defun blox-run-in-roblox (script-path build-filename)
  "Run the Lua script at SCRIPT-PATH in BUILD-FILENAME with run-in-roblox.
Both SCRIPT-PATH and BUILD-FILENAME must be in the same
directory.  If this is not the case, abort and display a message
in the echo area."
  (if (blox--kill-if-running-p "*run-in-roblox*")
      (if (not (locate-file build-filename
                            (list (file-name-directory script-path))))
          ;; run-in-roblox doesn't produce a very useful error message
          ;; for this case so we'll do it ourselves!
          (blox--echo
           "Script and place files must be under the same directory"
           "blox-run-in-roblox")
        (with-current-buffer (get-buffer-create "*run-in-roblox*")
          (cd (file-name-directory script-path))
          (blox--echo "Waiting for output from Roblox Studio..."
                      "blox-run-in-roblox")
          (setq buffer-read-only nil)
          (erase-buffer)
          (setq buffer-read-only t)
          (make-process
           :name "*run-in-roblox*"
           :buffer (current-buffer)
           :sentinel (blox--run-in-roblox-sentinel (current-buffer))
           :command
           (list blox-run-in-roblox-executable
                 "--place" build-filename
                 "--script" (file-name-nondirectory script-path)))))))

(defun blox-prompt-serve ()
  "Prompt to serve a Rojo project."
  (interactive)
  (blox-rojo-serve (read-file-name "Choose project: "
                                   (or (vc-root-dir)
                                       default-directory))))

(defun blox-prompt-build ()
  "Prompt to build a Rojo project."
  (interactive)
  (blox-rojo-build (read-file-name "Choose project: "
                                   (or (vc-root-dir)
                                       default-directory))))

(defun blox-build-default ()
  "Build `blox-default-project'."
  (interactive)
  (blox-rojo-build (blox--path blox-default-project)))

(defun blox-serve-default ()
  "Serve `blox-default-project'."
  (interactive)
  (blox-rojo-serve (blox--path blox-default-project)))

(defun blox-prompt-build-and-run ()
  "Prompt to build a Rojo project, then for a script to run in it.
The script and project files are expected to be under the same
directory.  If this is not the case, abort and display a message
in the echo area."
  (interactive)
  (let* ((directory (or (vc-root-dir) default-directory))
         (project (read-file-name "Choose project: " directory))
         (script (read-file-name "Choose script " directory)))
    (blox-rojo-build project
                     (blox--run-after-build-sentinel script
                                                     project))))

(defun blox-test ()
  "Run `blox-test-script' in `blox-test-project' with run-in-roblox.
`blox-test-script' and `blox-test-project' should both be under
the same directory."
  (interactive)
  (let ((test-project (blox--path blox-test-project))
        (test-script (blox--path blox-test-script)))
    (blox-rojo-build
     test-project
     (blox--run-after-build-sentinel test-script test-project))))

(provide 'blox)

;; Local variables:
;; indent-tabs-mode: nil
;; End:

;;; blox.el ends here
