;;; raycast-mode.el --- Develop Raycast Extensions -*- lexical-binding: t; -*-

;; Copyright (c) 2022 John Buckley <nhoj.buckley@gmail.com>

;; Author: John Buckley <nhoj.buckley@gmail.com>
;; URL: https://github.com/nhojb/raycast-mode
;; Package-Version: 20230607.2107
;; Package-Commit: f6401605cc9dfacdcaaf98d5844348b818cfc010
;; Version: 1.0
;; Keywords: convenience, languages, tools
;; Package-Requires: ((emacs "26.1"))

;; This file is not part of GNU Emacs.

;; MIT License

;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:

;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
;; BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
;; ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
;; SOFTWARE.

;;; Commentary:

;; A minor mode for developers building Raycast extensions.
;;
;; Features:
;;
;; Develop, lint, build and publish your Raycast extensions from Emacs.
;;
;; For more information visit: https://developers.raycast.com
;;
;; Installation:
;;
;; In your `init.el`
;;
;; (require 'raycast-mode)
;;
;; or with `use-package`:
;;
;; (use-package raycast-mode)
;;

;;; Code:

(require 'compile)
(require 'easymenu)

(defgroup raycast nil
  "A minor mode for building, running & validating Raycast extensions."
  :group 'emacs
  :prefix "raycast-mode:")

(defcustom raycast-mode-emoji t
  "If non-nil enable emoji in ray output."
  :type 'boolean
  :group 'raycast)

(defcustom raycast-mode-target nil
  "If non-nil use the specific ray target."
  :type 'string
  :group 'raycast)

(defcustom raycast-mode-use-menu t
  "If non-nil enable lighter menu."
  :type 'boolean
  :group 'raycast)

(defvar raycast-mode-map
  (let ((map (make-sparse-keymap))) map)
  "Keymap for `raycast-mode`.")

(easy-menu-define raycast--mode-menu
  raycast-mode-map
  "Menu used when `raycast-mode' is active."
  '("Raycast" :visible raycast-mode-use-menu
    "----"
    ["Develop..." raycast-develop
     :help "Start the extension in development mode and watch for changes"]
    ["Stop..." raycast-stop
     :visible compilation-in-progress
     :help "Stop the extension development mode"]
    ["Build..." raycast-build
     :help "Build the extension"]
    ["Lint..." raycast-lint
     :help "Validate the extension manifest and metadata, and lint its source code"]
    ["Fix lint..." raycast-fix-lint
     :help "Attempt to fix any validation or linter errors"]
    ["Publish..." raycast-publish
     :help "Build and publish the extension for distribution. Requires a Team account."]
    "----"
    ["Install..." raycast-install
     :help "Run npm install"]
    ["Update..." raycast-update
     :help "Run npm update"]
    "----"))

(defun raycast-build ()
  "Build the extension."
  (interactive)
  (raycast--run "build"))

(defun raycast-develop ()
  "Start the extension in development mode."
  (interactive)
  (raycast--run "dev" raycast-mode-target))

(defun raycast-lint ()
  "Validate the extension manifest and metadata, and lint its source code."
  (interactive)
  (raycast--run "lint"))

(defun raycast-fix-lint ()
  "Attempt to fix any validation or linter errors."
  (interactive)
  (raycast--run "fix-lint"))

(defun raycast-publish ()
  "Build and publish the extension for distribution - requires a Team account."
  (interactive)
  (raycast--run "publish"))

(defun raycast-stop ()
  "Stop development."
  (interactive)
  (kill-compilation))

(defun raycast-install ()
  "Run npm install."
  (interactive)
  (raycast--npm "install"))

(defun raycast-update ()
  "Run npm update."
  (interactive)
  (raycast--npm "update"))

(defun raycast--extension-directory ()
  "Get the current extension's root directory."
  (or (locate-dominating-file default-directory "package.json")
      default-directory))

(defun raycast--run (command &optional target)
  "Run ray COMMAND for the current extension and TARGET."
  (let ((default-directory (raycast--extension-directory))
        (run-command (cond
                      ((and raycast-mode-emoji target)
                       (format "npm run %s -- --emoji --target %s"
                               (shell-quote-argument command)
                               (shell-quote-argument target)))
                      (raycast-mode-emoji
                       (format "npm run %s -- --emoji"
                               (shell-quote-argument command)))
                      (target
                       (format "npm run %s -- --target %s"
                               (shell-quote-argument command)
                               (shell-quote-argument target)))
                      (t (format "npm run %s"
                                 (shell-quote-argument command))))))
    (compile run-command)))

(defun raycast--npm (command)
  "Run npm COMMAND for the current extension."
  (let ((default-directory (raycast--extension-directory)))
    (compile (format "npm %s" command))))

;;;###autoload
(define-minor-mode raycast-mode
  "Minor mode for building Raycast extensions."
  :lighter " raycast"
  :keymap raycast-mode-map)

(provide 'raycast-mode)

;;; raycast-mode.el ends here

