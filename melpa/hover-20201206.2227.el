;;; hover.el --- Package to use hover with flutter -*- lexical-binding: t; -*-

;; Copyright (C) 2020

;; Author: Eric Dallo
;; Version: 1.2.3
;; Package-Version: 20201206.2227
;; Package-Commit: d0f03552c30e31193d3dcce7e927ce24b207cbf6

;; Package-Requires: ((emacs "25.2") (dash "2.14.1"))
;; Keywords: hover, flutter, mobile, tools
;; URL: https://github.com/ericdallo/hover.el

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; hover.el is a package for running the `hover' binary tool from
;; https://github.com/go-flutter-desktop/hover interactively.
;; It is most useful when paired with `dart-mode'.

;;; Code:

(require 'comint)
(require 'dash)

(defgroup hover nil
  "Package to use hover with flutter."
  :group 'tools)

(defcustom hover-buffer-name "*Hover*"
  "Buffer name for hover."
  :type 'string
  :group 'hover)

(defcustom hover-command-path nil
  "Path to hover command."
  :type 'string
  :group 'hover)

(defcustom hover-flutter-sdk-path nil
  "Path to flutter SDK."
  :type 'string
  :group 'hover)

(defcustom hover-hot-reload-on-save nil
  "If non-nil, triggers hot-reload on buffer save."
  :type 'boolean
  :group 'hover)

(defcustom hover-screenshot-path nil
  "If non-nil, save hover screenshot on specified folder.
Default to project root."
  :type 'string
  :group 'hover)

(defcustom hover-screenshot-prefix "hover-"
  "Prefix for file name on `hover-take-screenshot`."
  :type 'string
  :group 'hover)

(defcustom hover-observatory-uri "http://127.0.0.1:50300"
  "Hover custom observatory-uri.
Default is hover's default uri"
  :type 'string
  :group 'hover)

(defcustom hover-clear-buffer-on-hot-restart nil
  "Clear hover buffer after a hot restart."
  :type 'boolean
  :group 'hover)

(defvar hover-mode-map (copy-keymap comint-mode-map)
  "Basic mode map for `hover-run'.")


;;; Internal

(defun hover--build-hover-command ()
  "Check if command exists and return the hover command."
  (or hover-command-path
      (-some-> (executable-find "hover")
        file-truename)
      (error "Hover command not found in path.  Try to configure `hover-command-path`")))

(defun hover--build-flutter-command ()
  "Check if command exists and return the flutter command."
  (or (-some-> hover-flutter-sdk-path
        file-name-as-directory
        (concat "bin/flutter"))
      (executable-find "flutter")))

(defun hover--project-get-root ()
  "Find the root of the current project."
  (or (expand-file-name (locate-dominating-file default-directory "go"))
      (error "This does not appear to be a Hover project (go folder not found), did you already run `hover init`?")))

(defmacro hover--with-running-proccess (args &rest body)
  "ARGS is a space-delimited string of CLI flags passed to `hover`.
Execute BODY while ensuring an inferior `hover` process is running."
  `(let* ((buffer (get-buffer-create hover-buffer-name))
          (alive (hover--running-p))
          (arglist (when ,args (split-string ,args))))
     (with-current-buffer buffer
       (unless (derived-mode-p 'hover-mode)
         (hover-mode))
       (unless alive
         (apply #'make-comint-in-buffer "Hover" buffer (hover--build-hover-command) nil "run" arglist)))
     ,@body))

(defun hover--make-interactive-function (key name)
  "Define a function that sends KEY to the `hover` process.
The function's name will be NAME prefixed with 'hover-'."
  (let* ((name-str (symbol-name name))
         (funcname (intern (concat "hover-" name-str))))
    (defalias funcname
      `(lambda ()
         ,(format "Send key '%s' to inferior hover to invoke '%s' function." key name-str)
         (interactive)
         (hover--send-command ,key)))))

(defun hover--send-command (command)
  "Send COMMAND to a running hover process."
  (hover--with-running-proccess
   nil
   (let ((proc (get-buffer-process hover-buffer-name)))
     (comint-send-string proc command))))

(defun hover--running-p ()
  "Return non-nil if the `hover` process is already running."
  (comint-check-proc hover-buffer-name))

(defun hover--run-command-on-hover-buffer (command)
  "Pop hover buffer window and run COMMAND."
  (let ((current (current-buffer)))
    (pop-to-buffer hover-buffer-name nil t)
    (select-window (get-buffer-window current)))
  (hover--send-command command))

(defun hover--build-screenshot-file-name ()
  "Build screenshot file name with a timestamp."
  (let ((formatted-timestamp (format-time-string "%Y-%m-%dT%T")))
    (concat hover-screenshot-prefix formatted-timestamp ".png")))

(defun hover--take-screenshot (file-path uri)
  "Run `fluter screenshot` to take a screenshot of hover application.
Save on FILE-PATH and use the observatory URI given."
  (compilation-start
   (format "%s screenshot --type=rasterizer --out=%s --observatory-uri=%s" (hover--build-flutter-command) file-path uri)
   t))

(defun hover--current-buffer-dart-p ()
  "Return non nil if current buffer is a dart."
  (string= "dart" (file-name-extension (buffer-file-name))))

(defun hover--clear-buffer ()
  "Clear hover buffer."
  (if (hover--running-p)
      (with-current-buffer hover-buffer-name
        (let ((comint-buffer-maximum-size 0))
          (comint-truncate-buffer)))
    (error "Hover is not running")))

(defun hover--hot-reload ()
  "Trigger hover hot reload."
  (when (and (hover--current-buffer-dart-p)
             (hover--running-p))
    (hover--run-command-on-hover-buffer "r")))


;;; Key bindings

(defconst hover-interactive-keys-alist
  '(("r" . hot-reload)
    ("R" . hot-restart)
    ("h" . help)
    ("w" . widget-hierarchy)
    ("t" . rendering-tree)
    ("L" . layers)
    ("S" . accessibility-traversal-order)
    ("U" . accessibility-inverse-hit-test-order)
    ("i" . inspector)
    ("p" . construction-lines)
    ("o" . operating-systems)
    ("z" . elevation-checker)
    ("P" . performance-overlay)
    ("a" . timeline-events)
    ("d" . detatch)
    ("q" . quit)))

(defun hover-register-key (key name)
  "Register a KEY with NAME recognized by the `hover` process.
A function `hover-NAME' will be created that sends the key to
the `hover` process."
  (let ((func (hover--make-interactive-function key name)))
    (define-key hover-mode-map key func)))

(defun hover-register-keys (key-alist)
  "Call `hover-register-key' on all (key . name) pairs in KEY-ALIST."
  (dolist (item key-alist)
    (hover-register-key (car item) (cdr item))))

(hover-register-keys hover-interactive-keys-alist)


;;; Public interface

(defun hover-run-or-hot-reload ()
  "Start `hover run` or hot-reload if already running."
  (interactive)
  (if (hover--running-p)
      (hover--run-command-on-hover-buffer "r")
    (hover-run)))

(defun hover-run-or-hot-restart ()
  "Start `hover run` or hot-restart if already running."
  (interactive)
  (if (hover--running-p)
      (progn
        (hover--run-command-on-hover-buffer "R")
        (when hover-clear-buffer-on-hot-restart
          (hover--clear-buffer)))
    (hover-run)))

(defun hover-take-screenshot ()
  "Take screenshot of current `hover` application using `flutter screenshot`.
Saves screenshot on `hover-screenshot-path`."
  (interactive)
  (let* ((screenshot-path (or (if hover-screenshot-path
                                  (file-name-as-directory hover-screenshot-path))
                              (hover--project-get-root)))
         (file-name (hover--build-screenshot-file-name))
         (file-path (concat screenshot-path file-name)))
    (hover--take-screenshot file-path hover-observatory-uri)))

(defun hover-clear-buffer ()
  "Clear current hover buffer output."
  (interactive)
  (hover--clear-buffer))

;;;###autoload
(defun hover-kill ()
  "Kill hover buffer."
  (interactive)
  (with-current-buffer hover-buffer-name
    (kill-buffer)))

;;;###autoload
(defun hover-run (&optional args)
  "Execute `hover run` inside Emacs.

ARGS is a space-delimited string of CLI flags passed to
`hover`, and can be nil.  Call with a prefix to be prompted for
args."
  (interactive
   (list (when current-prefix-arg
           (read-string "Args: "))))
  (hover--with-running-proccess
   args
   (pop-to-buffer-same-window buffer)))

;;;###autoload
(define-derived-mode hover-mode comint-mode "Hover"
  "Major mode for `hover-run'."
  (setq comint-prompt-read-only t)
  (setq comint-process-echoes nil)
  (setq process-connection-type nil)
  (setq default-directory (hover--project-get-root))
  (setenv "PATH" (concat (hover--build-flutter-command) ":" (getenv "PATH")))
  (setenv "PATH" (concat (hover--build-hover-command) ":" (getenv "PATH")))
  (when hover-hot-reload-on-save
    (remove-hook 'after-save-hook 'hover--hot-reload)
    (add-hook 'after-save-hook 'hover--hot-reload))
  (define-key hover-mode-map (kbd "C-x q") #'hover-kill))

(provide 'hover)
;;; hover.el ends here
