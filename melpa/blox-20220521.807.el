;;; blox.el --- Interaction with Roblox tooling -*- lexical-binding: t; -*-

;; Copyright (C) 2021 Kenneth Loeffler

;; Author: Kenneth Loeffler <kenloef@gmail.com>
;; Version: 0.4.0
;; Package-Version: 20220521.807
;; Package-Commit: 9ebebb65fb38b5570ba8dfbb5ec835633c06b67d
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

(defun blox--run-after-build-sentinel (script-path build-path)
  "Process sentinel to run SCRIPT-PATH in BUILD-PATH once finished."
  (lambda (_process event)
    (if (equal event "finished\n")
        (blox-run-in-roblox
         script-path
         build-path))))

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
  "Return the path of the build file corresponding to PROJECT-PATH."
  (concat (file-name-sans-extension (file-name-base project-path))
          (blox--roblox-file-extension project-path)))

(defun blox--find-file (filename)
  "Use function `locate-dominating-file' to find FILENAME.
Start at `default-directory'.  If the file cannot be located,
fall back to `default-directory' to make Rojo generate an error
message.  Return the path to the file."
  (concat (file-truename (or (locate-dominating-file default-directory filename)
              default-directory))
          filename))

(defun blox-rojo-serve (project-path)
  "Serve the Rojo project at PROJECT-PATH."
  (blox--save-some-lua-mode-buffers)
  (if (blox--kill-if-running-p "*rojo-serve*")
      (with-current-buffer (get-buffer-create "*rojo-serve*")
        (help-mode)
        (make-process
         :name "*rojo-serve*"
         :buffer (current-buffer)
         :filter (blox--echo-filter "blox-rojo-serve")
         :command
         (list blox-rojo-executable "serve"
               project-path)))))

(defun blox-rojo-build (project-path output-path &optional sentinel)
  "Build the Rojo project at PROJECT-PATH to OUTPUT-PATH if provided.
If the function SENTINEL is provided, attach it to the Rojo
process.  If OUTPUT-PATH is not provided, build to the project directory instead."
  (blox--save-some-lua-mode-buffers)
  (with-current-buffer (get-buffer-create "*rojo-build*")
    (help-mode)
    (make-process
     :name "*rojo-build*"
     :buffer (current-buffer)
     :filter (blox--echo-filter "blox-rojo-build")
     :sentinel sentinel
     :command
     (list blox-rojo-executable
           "build" project-path
           "--output" output-path))))

(defun blox-run-in-roblox (script-path build-path)
  "Run the Lua script at SCRIPT-PATH in BUILD-PATH with run-in-roblox."
  (if (blox--kill-if-running-p "*run-in-roblox*")
        (with-current-buffer (get-buffer-create "*run-in-roblox*")
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
                 "--place" build-path
                 "--script" script-path)))))

(defun blox-prompt-serve ()
  "Prompt to serve a Rojo project."
  (interactive)
  (blox-rojo-serve (read-file-name "Choose project: "
                                   (or (vc-root-dir)
                                       default-directory))))

(defun blox-prompt-build ()
  "Prompt for a Rojo project and a path to build to."
  (interactive)
  (blox-rojo-build (read-file-name "Choose project path: "
                                   (or (vc-root-dir)
                                       default-directory))
                   (read-file-name "Choose output path: "
                                   (or (vc-root-dir)
                                       default-directory))))

(defun blox-prompt-build-and-run ()
  "Prompt to build a Rojo project, then for a script to run in it.
The script and project files are expected to be under the same
directory.  If this is not the case, abort and display a message
in the echo area."
  (interactive)
  (let* ((directory (or (vc-root-dir) default-directory))
         (project-path (read-file-name "Choose project: " directory))
         (script-path (read-file-name "Choose script: " directory))
         (output-path (concat (file-name-directory script-path)
                              (blox--build-filename project-path))))
    (blox-rojo-build
     project-path
     output-path
     (blox--run-after-build-sentinel script-path
                                     output-path))))

(defun blox-test ()
  "Run `blox-test-script' in `blox-test-project' with run-in-roblox."
  (interactive)
  (let* ((test-project-path (blox--find-file blox-test-project))
         (test-script-path (blox--find-file blox-test-script))
         (output-path (concat
                       (file-name-directory test-script-path)
                       (blox--build-filename test-project-path))))
    (blox-rojo-build
     test-project-path
     output-path
     (blox--run-after-build-sentinel test-script-path
                                     output-path))))

(provide 'blox)

;; Local variables:
;; indent-tabs-mode: nil
;; End:

;;; blox.el ends here
