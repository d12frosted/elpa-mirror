;;; overseer.el --- Ert-runner Integration Into Emacs -*- lexical-binding: t -*-

;; Copyright © 2014-2015 Samuel Tonini
;;
;; Author: Samuel Tonini <tonini.samuel@gmail.com>

;; URL: http://www.github.com/tonini/overseer.el
;; Package-Version: 20180226.619
;; Package-Commit: 02d49f582e80e36b4334c9187801c5ecfb027789
;; Version: 0.3.0
;; Package-Requires: ((emacs "24") (dash "2.10.0") (pkg-info "0.4") (f "0.18.1"))
;; Keywords:

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
;; along with this program. If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Ert-runner Integration Into Emacs.

;;; Code:

(require 'compile)
(require 'dash)
(require 'f)
(require 'pkg-info)
(require 'ansi-color)

(defgroup overseer nil
  "Ert-runner Integration Into Emacs."
  :prefix "overseer-"
  :group 'applications
  :link '(url-link :tag "Github" "https://github.com/tonini/overseer.el")
  :link '(emacs-commentary-link :tag "Commentary" "overseer"))

;; Variables

(defcustom overseer-command "cask exec ert-runner"
  "The shell command for ert-runner."
  :type 'string
  :group 'overseer)

(defvar overseer-buffer-name "*overseer*"
  "Name of the overseer buffer.")

(defvar overseer--buffer-name nil
  "Used to store compilation name so recompilation works as expected.")
(make-variable-buffer-local 'overseer--buffer-name)

(defvar overseer--project-root-indicators
  '("Cask")
  "Files which indicate a root of a emacs lisp package.")

(defvar overseer--save-buffers-predicate
  (lambda () (string-prefix-p "*" (buffer-name))))

;; Private functions

(defun overseer--build-runner-cmdlist (command)
  "Build the arguments list for the runner with COMMAND."
  (remove "" (-flatten
              (list (if (stringp command)
                        (split-string command)
                      command)))))

(defun overseer--handle-ansi-color ()
  (ansi-color-apply-on-region (point-min) (point-max)))

(defun overseer--remove-header ()
  (delete-matching-lines "\\(ert-runner finished at\\|mode: overseer-buffer\\|ert-runner started at\\)"
                         (point-min) (point-max)))

(defun overseer--project-root-identifier (file indicators)
  (let ((root-dir (if indicators (locate-dominating-file file (car indicators)) nil)))
    (cond (root-dir (f-slash (directory-file-name (expand-file-name root-dir))))
          (indicators (overseer--project-root-identifier file (cdr indicators)))
          (t nil))))

(defun overseer--kill-any-orphan-proc ()
  "Ensure any dangling buffer process is killed."
  (let ((orphan-proc (get-buffer-process (buffer-name))))
    (when orphan-proc
      (kill-process orphan-proc))))

(defun overseer--test-file (filename)
  "Run ert-runner with the current FILENAME as argument."
  (overseer-execute (list (expand-file-name filename))))

(defun overseer--test-pattern (pattern)
  "Run ert-runner for tests matching PATTERN."
  (overseer-execute (list "-p" pattern)))

(defun overseer--current-buffer-test-file-p ()
  "Return t if the current buffer is a test file."
  (string-match "-test\.el$" (or (buffer-file-name) "")))

;; Public functions

(defun overseer-project-root ()
  "Return path to the current emacs lisp package root directory."
  (let ((file (file-name-as-directory (expand-file-name default-directory))))
    (or
     (overseer--project-root-identifier file overseer--project-root-indicators)
     (user-error "Overseer unable to identify project root"))))

(define-compilation-mode overseer-buffer-mode "ert-runner"
  "Overseer compilation mode."
  (progn
    (font-lock-add-keywords nil
                            '(("^Finished in .*$" . font-lock-string-face)
                              ("^ert-runner.*$" . font-lock-string-face)))
    ;; Set any bound buffer name buffer-locally
    (setq overseer--buffer-name overseer--buffer-name)
    (set (make-local-variable 'kill-buffer-hook)
         'overseer--kill-any-orphan-proc)))

(defun overseer-compilation-run (cmdlist buffer-name)
  "Run CMDLIST in BUFFER-NAME and returns the compilation buffer."
  (save-some-buffers (not compilation-ask-about-save) overseer--save-buffers-predicate)
  (let* ((overseer--buffer-name buffer-name)
         (compilation-filter-start (point-min)))
    (with-current-buffer
        (compilation-start (mapconcat 'concat cmdlist " ")
                           'overseer-buffer-mode
                           (lambda (_b) overseer--buffer-name))
      (set (make-local-variable 'compilation-error-regexp-alist) (cons 'overseer compilation-error-regexp-alist))
      (add-hook 'compilation-filter-hook 'overseer--handle-ansi-color nil t)
      (add-hook 'compilation-filter-hook 'overseer--remove-header nil t))))

(defun overseer-test ()
  "Run ert-runner."
  (interactive)
  (overseer-execute '()))

(defun overseer-test-run-test ()
  "Run ert-runner for the test at point."
  (interactive)
  (save-excursion
    (end-of-defun)
    (beginning-of-defun)
    (let ((function (read (current-buffer))))
      (if (string= "ert-deftest" (car function))
          (overseer--test-pattern (symbol-name (cadr function)))
        (message "No test at point")))))

(defun overseer-help ()
  "Run ert-runner with --help as argument."
  (interactive)
  (overseer-execute '("--help")))

(defun overseer-test-this-buffer ()
  "Run ert-runner with the current `buffer-file-name' as argument."
  (interactive)
  (if (overseer--current-buffer-test-file-p)
      (overseer-execute (list (buffer-file-name)))
    (message (format "%s is no test file."
                     (file-name-nondirectory (buffer-file-name))))))

(defun overseer-test-file (filename)
  "Run `overseer--test-file' with the FILENAME."
  (interactive "Fmix test: ")
  (overseer--test-file filename))

(defun overseer-test-debug ()
  "Run ert-runner with --debug as argument."
  (interactive)
  (overseer-execute '("--debug")))

(defun overseer-test-verbose ()
  "Run ert-runner with --verbose as argument."
  (interactive)
  (overseer-execute '("--verbose")))

(defun overseer-test-quiet ()
  "Run ert-runner with --quiet as argument."
  (interactive)
  (overseer-execute '("--quiet")))

(defun overseer-test-tags (tags)
  "Run ert-runner for the given TAGS."
  (interactive "Mert-runner -t: ")
  (overseer-execute (list "-t" tags)))

(defvar overseer--prompt-history nil
  "List of recent prompts read from minibuffer.")

(defun overseer-test-prompt (command)
  "Run ert-runner with custom arguments."
  (interactive
   (list (let ((default (car-safe overseer--prompt-history)))
           (read-string
            (if default
                (format "ert-runner (default \"%s\"): " default)
              "ert-runner ")
            nil 'overseer--prompt-history default t))))
  (overseer-execute (list command)))

(defun overseer-execute (cmdlist)
  "Execute an ert-runner with CMDLIST as arguments."
  (let ((original-default-directory default-directory))
    (unwind-protect
        (let ((default-directory (overseer-project-root)))
          (overseer-compilation-run (overseer--build-runner-cmdlist (list overseer-command cmdlist))
                                    overseer-buffer-name))
      (setq default-directory original-default-directory))))

;;;###autoload
(defun overseer-version (&optional show-version)
  "Get the Overseer version as string.

If called interactively or if SHOW-VERSION is non-nil, show the
version in the echo area and the messages buffer.

The returned string includes both, the version from package.el
and the library version, if both a present and different.

If the version number could not be determined, signal an error,
if called interactively, or if SHOW-VERSION is non-nil, otherwise
just return nil."
  (interactive (list t))
  (let ((version (pkg-info-version-info 'overseer)))
    (when show-version
      (message "Overseer version: %s" version))
    version))

(defvar overseer-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c , a") 'overseer-test)
    (define-key map (kbd "C-c , t") 'overseer-test-run-test)
    (define-key map (kbd "C-c , b") 'overseer-test-this-buffer)
    (define-key map (kbd "C-c , f") 'overseer-test-file)
    (define-key map (kbd "C-c , g") 'overseer-test-tags)
    (define-key map (kbd "C-c , p") 'overseer-test-prompt)
    (define-key map (kbd "C-c , d") 'overseer-test-debug)
    (define-key map (kbd "C-c , q") 'overseer-test-quiet)
    (define-key map (kbd "C-c , v") 'overseer-test-verbose)
    (define-key map (kbd "C-c , h") 'overseer-help)
    map)
  "The keymap used when `overseer-mode' is active.")

;;;###autoload
(define-minor-mode overseer-mode
  "Minor mode for emacs lisp files to test through ert-runner.

Key bindings:
\\{overseer-mode-map}"
  nil
  " overseer"
  :group 'overseer
  :global nil
  :keymap 'overseer-mode-map)

;;;###autoload
(defun overseer-enable-mode ()
  (if (overseer--current-buffer-test-file-p)
      (overseer-mode)))

;;;###autoload
(dolist (hook '(emacs-lisp-mode-hook))
  (add-hook hook 'overseer-enable-mode))

(provide 'overseer)

;;; overseer.el ends here
