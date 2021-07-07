;;; import-js.el --- Import Javascript dependencies -*- lexical-binding: t; -*-
;; Copyright (C) 2015 Henric Trotzig and Kevin Kehl
;;
;; Author: Kevin Kehl <kevin.kehl@gmail.com>
;; URL: http://github.com/Galooshi/emacs-import-js/
;; Package-Version: 20180709.1833
;; Package-Commit: fb1f167e33c388b09a2afd32fbda90a67bfb2e40
;; Package-Requires: ((grizzl "0.1.0") (emacs "24"))
;; Version: 1.0.0
;; Keywords: javascript

;; This file is not part of GNU Emacs.

;;; License:

;; Licensed under the MIT license, see:
;; http://github.com/Galooshi/emacs-import-js/blob/master/LICENSE

;;; Commentary:

;; Quick start:
;; run-import-js
;;
;; Bind the following commands:
;; import-js-import
;; import-js-goto
;;
;; For a detailed introduction see:
;; http://github.com/Galooshi/emacs-import-js/blob/master/README.md

;;; Code:

(require 'json)

(eval-when-compile
  (require 'grizzl))

(defvar import-js-handler nil "Current import-js output handler")
(defvar import-js-output "" "Partial import-js output")
(defvar import-js-process nil "Current import-js process")
(defvar import-js-current-project-root nil "Current project root")

(defun import-js-check-daemon ()
  (unless import-js-process
    (throw 'import-js-daemon "import-js-daemon not running")))

(defun import-js-json-encode-alist (alist)
  (let ((json-encoding-pretty-print nil))
    (json-encode-alist alist)))

(defun import-js-send-input (input-alist)
  "Append the current buffer content and path to file to a data alist, and send to import-js"
  (let ((input-json (import-js-json-encode-alist (append input-alist
                                                         `(("fileContent" . ,(buffer-string))
                                                           ("pathToFile" . ,(buffer-file-name)))))))
    (process-send-string import-js-process input-json)
    (process-send-string import-js-process "\n")))

(defun import-js-locate-project-root (path)
  "Find the dir containing package.json by walking up the dir tree from path"
  (let ((parent-dir (file-name-directory path))
        (project-found nil))
    (while (and parent-dir (not (setf project-found (file-exists-p (concat parent-dir "package.json")))))
      (let* ((pd (file-name-directory (directory-file-name parent-dir)))
             (pd-exists (not (equal pd parent-dir))))
        (setf parent-dir (if pd-exists pd nil))))
    (if project-found parent-dir ".")))

(defun import-js-word-at-point ()
  "Get the module of interest"
  (save-excursion
    (skip-chars-backward "A-Za-z0-9:_")
    (let ((beg (point)) module)
      (skip-chars-forward "A-Za-z0-9:_")
      (setq module (buffer-substring-no-properties beg (point)))
      module)))

(defun import-js-write-content (import-data)
  "Write output data from import-js to the buffer"
  (let ((file-content (cdr (assoc 'fileContent import-data))))
    (write-region file-content nil buffer-file-name))
  (revert-buffer t t t))

(defun import-js-add (add-alist)
  "Resolves an import with multiple matches"
  (import-js-send-input `(("command" . "add")
                          ("commandArg" . ,add-alist))))

(defun import-js-handle-unresolved (unresolved word)
  "Map unresolved imports to a path"
  (let ((paths (mapcar
                (lambda (car)
                  (cdr (assoc 'importPath car)))
                (cdr (assoc-string word unresolved)))))
    (minibuffer-with-setup-hook
        (lambda () (make-sparse-keymap))
      (grizzl-completing-read (format "Unresolved import (%s)" word)
                              (grizzl-make-index
                               paths
                               'files
                               import-js-current-project-root
                               nil)))))

(defun import-js-handle-data (process data)
  "Handles STDOUT from node, which arrives in chunks"
  (setq import-js-output (concat import-js-output data))
  (if (string-match "DAEMON active" data)
      ;; Ignore the startup message
      (setq import-js-output "")
    (when (string-match "\n$" data)
      (let ((import-data import-js-output))
        (setq import-js-output "")
        (funcall import-js-handler import-data)))))

(defun import-js-handle-imports (import-data)
  "Check to see if import is unresolved. If resolved, write file. Else, prompt the user to select"
  (let* ((import-alist (json-read-from-string import-data))
         (unresolved (cdr (assoc 'unresolvedImports import-alist))))
    (if unresolved
        (import-js-add (mapcar
                        (lambda (word)
                          (let ((key (car word)))
                            (cons key (import-js-handle-unresolved unresolved key))))
                        unresolved))
      (import-js-write-content import-alist))))

(defun import-js-handle-goto (import-data)
  "Navigate to the indicated file"
  (let ((goto-list (json-read-from-string import-data)))
    (find-file (cdr (assoc 'goto goto-list)))))

;;;###autoload
(defun import-js-import ()
  "Run import-js on a particular module"
  (interactive)
  (save-some-buffers)
  (import-js-check-daemon)
  (setq import-js-output "")
  (setq import-js-handler 'import-js-handle-imports)
  (import-js-send-input `(("command" . "word")
                          ("commandArg" . ,(import-js-word-at-point)))))

;;;###autoload
(defun import-js-fix ()
  "Run import-js on an entire file, importing or fixing as necessary"
  (interactive)
  (save-some-buffers)
  (import-js-check-daemon)
  (setq import-js-output "")
  (setq import-js-handler 'import-js-handle-imports)
  (import-js-send-input `(("command" . "fix"))))

;;;###autoload
(defun import-js-goto ()
  "Run import-js goto function, which returns a path to the specified module"
  (interactive)
  (import-js-check-daemon)
  (setq import-js-output "")
  (setq import-js-handler 'import-js-handle-goto)
  (import-js-send-input `(("command" . "goto")
                          ("commandArg" . ,(import-js-word-at-point)))))

;;;###autoload
(defun run-import-js ()
  "Start the import-js daemon"
  (interactive)
  (kill-import-js)
  (let ((process-connection-type nil))
    (setq import-js-process (start-process "import-js" nil "importjsd" "start" (format "--parent-pid=%s" (emacs-pid))))
    (set-process-filter import-js-process 'import-js-handle-data)))

;;;###autoload
(defun kill-import-js ()
  "Kill the currently running import-js daemon process"
  (interactive)
  (if import-js-process
      (delete-process import-js-process)))

(provide 'import-js)
;;; import-js.el ends here
