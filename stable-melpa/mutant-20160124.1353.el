;;; mutant.el --- An interface for the Mutant testing tool

;; Copyright (C) 2016 Pedro Lambert <pedrolambert at google mail>

;; Author: Pedro Lambert
;; URL: http://github.com/p-lambert/mutant.el
;; Package-Version: 20160124.1353
;; Package-Commit: aff50603a70a110f4ecd7142963ef719e8c11c06
;; Version: 1.0
;; Keywords: mutant, testing
;; Package-Requires: ((emacs "24.4") (dash "2.1.0"))

;; This file is NOT part of GNU Emacs.
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; See <http://www.gnu.org/licenses/> for a copy of the GNU General
;; Public License.

;;; Commentary:
;;
;; This package provides an interface for dealing with the
;; [Mutant](https://github.com/mbj/mutant) testing tool, enabling
;; one to easily launch it from a `.rb` file or even from a `dired` buffer.
;; The generated output is nicely formatted and provides direct links
;; to the errors reported by the mutations. I've tried
;; to mimic the `rspec-mode` overall experience as much as possible.

;;; Installation:
;;
;; This package can be installed via `MELPA`, or manually by downloading
;; `mutant.el` and adding it to your init file, as it follows:
;;
;; ```elisp
;; (add-to-list 'load-path "/path/to/mutant")
;; (require 'mutant)
;; ```
;;
;; For having `mutant-mode` enabled automatically, I suggest you
;; to do the following:
;;
;; ```elisp
;; (add-hook 'ruby-mode-hook 'mutant-mode)
;; ```

;;; Usage:
;;
;; By default, the following keybindings will be available:
;;
;; * <kbd>C-c . f</kbd> runs `mutant-check-file`
;; * <kbd>C-c . c</kbd> runs `mutant-check-custom`
;;
;; For `dired` mode integration, just add the following to your
;; configuration file:
;;
;; ```elisp
;; (add-hook 'dired-mode-hook 'mutant-dired-mode)
;; ```
;;
;; By doing so, you'll be able to mark files and then press <kbd>C-c . f</kbd>
;; for running `mutant` on them.
;;
;; See the [Function Documentation](#function-documentation) for more details.

;;; Customization:
;;
;; If you're a `rvm` user, you might have to add the following to your
;; configuration file:
;;
;; ```elisp
;; (add-hook 'mutant-precompile-hook
;;           (lambda () (rvm-activate-corresponding-ruby)))
;; ```
;; Notice that this obviously requires `rvm.el` to be installed.
;;
;; In order to execute the `mutant` command with a `bundle exec` prefix,
;; simply add the following to your configuration file:
;;
;; ```elisp
;; (setq mutant-cmd-base "bundle exec mutant")
;; ```

;;
;;; Changelog:
;;
;; 1.0 - First release. <br/>

;;; Code
(require 'dash)
(require 'ansi-color)
(require 'compile)

(defgroup mutant nil
  "An interface for Mutant."
  :group 'tools
  :group 'convenience)

(defcustom mutant-project-root-files
  '(".git" "Gemfile" ".projectile")
  "A list of files that might indicate the root directory of a project."
  :group 'mutant
  :type '(repeat string))

(defcustom mutant-cmd-base "mutant"
  "The command used to run mutant"
  :group 'mutant
  :type 'string)

(defcustom mutant-strategy "rspec"
  "The strategy to be used in mutation."
  :group 'mutant
  :type 'string)

(defcustom mutant-regexp-alist
  '(("\\(_spec\\)?\\.rb" . "")
    ("^\\(app\\|spec\\|test\\)\\/.+?\\/" . "")
    ("^lib\\/" . "")
    ("/" . "::")
    ("_" . ""))
  "A list of regular expressions to be applied upon a file name."
  :group 'mutant
  :type '(alist :key-type string :value-type string))

(defcustom mutant-precompile-hook nil
  "Hooks executed before running the mutant command."
  :group 'mutant
  :type 'hook)

(defun mutant--cmd-builder (&optional match-exp)
  "Build each part of the mutant command."
  (-> mutant-cmd-base
      (mutant--join (mutant--cmd-rails-env))
      (mutant--join (mutant--cmd-env))
      (mutant--join (mutant--cmd-strategy))
      (mutant--join match-exp)))

(defun mutant--cmd-strategy ()
  "Returns the strategy (--use option) used by mutant."
  (mutant--join "--use" mutant-strategy))

(defun mutant--cmd-rails-env ()
  "Boot Rails environment, if available."
  (when (file-exists-p
         (expand-file-name "config/environment.rb" (mutant--project-root)))
    "--require ./config/environment"))

(defun mutant--cmd-env ()
  "Setup load path and require necessary files."
  (let ((default-directory (or (mutant--project-root) default-directory)))
    (let ((lib-files (file-expand-wildcards "lib/*\.rb")))
      (when (and lib-files (not (mutant--cmd-rails-env)))
      (--> lib-files
           (mapconcat 'identity it " ")
           (replace-regexp-in-string "lib\\/\\(.+?\\).rb" "\\1" it t)
           (mutant--join "--include lib --require" it))))))

(defun mutant--project-root ()
  "Retrieve the root directory of a project if available.
The current directory is assumed to be the project's root otherwise."
  (or (->> mutant-project-root-files
        (--map (locate-dominating-file default-directory it))
        (-remove #'null)
        (car))
      (error "You're not into a project")))

(defun mutant--guess-class-name (file-name)
  "Guess the name of a class based on FILE-NAME."
  (let* ((relative-name (file-relative-name file-name (mutant--project-root)))
         (class-name (capitalize relative-name)))
    (->> mutant-regexp-alist
         (--reduce-from (replace-regexp-in-string (car it) (cdr it) acc nil t)
                        class-name))))

(defun mutant--run (match-exp)
  "Execute mutant command under compilation mode with given MATCH-EXP."
  (run-hooks 'mutant-precompile-hook)
  (let ((default-directory (or (mutant--project-root) default-directory))
        (full-cmd (mutant--cmd-builder match-exp)))
    (compile full-cmd 'mutant-compilation-mode)))

(defun mutant--join (&rest args)
  (--> args
       (-remove #'null it)
       (mapconcat 'identity it " ")))

(defun mutant--colorize-compilation-buffer ()
  (read-only-mode -1)
  (ansi-color-apply-on-region compilation-filter-start (point))
  (read-only-mode +1))

(define-compilation-mode mutant-compilation-mode "Mutant Compilation"
  "Compilation mode for Mutant output."
  (add-hook 'compilation-filter-hook 'mutant--colorize-compilation-buffer nil t))

;;;###autoload
(defun mutant-check-file (&optional file-name)
  "Run Mutant over a single file.
If none is given, then `buffer-file-name` is used."
  (interactive)
  (let* ((file-name (or file-name (buffer-file-name)))
         (class-name (mutant--guess-class-name file-name)))
    (mutant--run class-name)))

;;;###autoload
(defun mutant-check-from-dired ()
  "Run Mutant over all marked files in dired.
If there are no files marked, use that under cursor."
  (interactive)
  (--> (dired-get-marked-files)
       (mapconcat 'mutant--guess-class-name it " ")
       (mutant--run it)))

;;;###autoload
(defun mutant-check-custom (&optional match-exp)
  "Run Mutant over MATCH-EXP.
When called without argument, prompt user."
  (interactive)
  (let ((match-exp (or match-exp (read-string "Match expression: "))))
    (mutant--run match-exp)))

(defcustom mutant-keymap-prefix (kbd "C-c .")
  "Mutant keymap prefix."
  :group 'mutant
  :type 'string)

(defvar mutant-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "f") 'mutant-check-file)
      (define-key prefix-map (kbd "c") 'mutant-check-custom)

      (define-key map mutant-keymap-prefix prefix-map))
    map)
  "Keymap for mutant-mode.")

(defvar mutant-dired-mode-map
  (let ((map (make-sparse-keymap)))
    (let ((prefix-map (make-sparse-keymap)))
      (define-key prefix-map (kbd "f") 'mutant-check-from-dired)
      (define-key prefix-map (kbd "c") 'mutant-check-custom)

      (define-key map mutant-keymap-prefix prefix-map))
    map)
  "Keymap for mutant-dired-mode.")

;;;###autoload
(define-minor-mode mutant-mode
  "Minor mode to interface with Mutant

\\{mutant-mode-map}"
  :lighter " Mutant"
  :keymap mutant-mode-map
  :group 'mutant)

(define-minor-mode mutant-dired-mode
  "Minor mode for running Mutant from Dired buffers

\\{mutant-dired-mode-map}"
  :lighter ""
  :keymap `((,mutant-key-command-prefix . mutant-dired-mode-keymap))
  :group 'mutant)

(provide 'mutant)
;;; mutant.el ends here
