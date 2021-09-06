;;; fuzzy-finder.el --- Fuzzy Finder App Integration  -*- lexical-binding: t; -*-

;; Copyright (C) 2020 10sr

;; Some Portions Copyright (C) 2015 Bailey Ling

;; Author: 10sr <8.slashes@gmail.com>
;; Author: Bailey Ling
;; Maintainer: 10sr <8.slashes@gmail.com>
;; Keywords: matching
;; Package-Version: 20210906.217
;; Package-Commit: 915a281fc8e50df84dcc205f9357e8314d60fa54
;; URL: https://github.com/10sr/fuzzy-finder-el
;; Version: 0.0.1
;; Package-Requires: ((emacs "24.4"))

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

;; Fuzzy finder app integration into Emacs.

;; `fuzzy-finder' command starts a fuzzy finder process and calls a function
;; on the selected items.
;; By default it visits selected files.

;; There are a number of applications which can be used with `fuzzy-finder'
;; such as fzf (default), peco, and selecta.

;; You can customize default values used for `fuzzy-finder' execution:
;; fuzzy finder command, input command, action function and so on.
;; These values can also be given when calling `fuzzy-finder' as a function,
;; which is useful when you want to define new interactive commands that uses
;; `fuzzy-finder'.

;;; Code:

(require 'cl-lib)
(require 'nadvice)
(require 'term)
(require 'simple)

(declare-function company-mode "company")

(defgroup fuzzy-finder nil
  "Fuzzy finder app integration for Emacs."
  :group 'convenience)

(defcustom fuzzy-finder-executable "fzf"
  "Name or path of the fuzzy finder executable."
  :type 'string
  :group 'fuzzy-finder)

(defcustom fuzzy-finder-default-arguments "--multi --reverse"
  "Default arguments for `fuzzy-finder' ARGUMENTS keyword."
  :type 'string
  :group 'fuzzy-finder)

(defcustom fuzzy-finder-default-input-command nil
  "Default value for `fuzzy-finder' INPUT-COMMAND keyword."
  :type 'string
  :group 'fuzzy-finder)

(defcustom fuzzy-finder-default-action #'fuzzy-finder-action-find-files
  "Default value for `fuzzy-finder' ACTION keyword."
  :type 'function
  :group 'fuzzy-finder)

(defcustom fuzzy-finder-default-output-delimiter "\n"
  "Default value for `fuzzy-finder' OUTPUT-DELIMITER keyword."
  :type 'string
  :group 'fuzzy-finder)

(defcustom fuzzy-finder-default-window-height 12
  "Default value for `fuzzy-finder' WINDOW-HEIGHT keyword."
  :type 'integer
  :group 'fuzzy-finder)

(defcustom fuzzy-finder-init-hook nil
  "Hook run just after initialize fuzzy finder buffer."
  :type 'hook
  :group 'fuzzy-finder)

(defcustom fuzzy-finder-exit-hook nil
  "Hook run just before starting exit process of fuzzy finder."
  :type 'hook
  :group 'fuzzy-finder)

(defvar fuzzy-finder--window-configuration nil
  "Window configuration before showing fuzzy finder buffer.")

(defconst fuzzy-finder--process-name "fuzzy-finder"
  "Process name for fuzzy finder.")

(defvar-local fuzzy-finder--output-file nil
  "File name for output of fuzzy-finder result.")

(defvar-local fuzzy-finder--output-delimiter nil
  "Delimiter for output of fuzzy-finder result.")

(defvar-local fuzzy-finder--action nil
  "Action function given to this fuzzy-finder session.")



(defsubst fuzzy-finder--get-buffer-create (&optional force-recreate)
  "Get or create buffer for fuzzy finder process.

If optional FORCE-RECREATE is set to non-nil and buffer already exists,
destroy it and create new buffer with same name."
  (let* ((name (concat "*" fuzzy-finder--process-name "*"))
         (buf (get-buffer name)))
    (when (and buf
               force-recreate)
      (kill-buffer buf))
    (get-buffer-create name)))

(defun fuzzy-finder--display-buffer (buf height)
  "Display fuzzy finder BUF and set window height to HEIGHT.

This function sets current buffer to BUF, and returns created window."
  (let ((new-window nil)
        (height (min height
                     (/ (frame-height) 2))))
    (setq new-window (split-window (frame-root-window)
                                   (- height)
                                   'below))
    (select-window new-window)
    (switch-to-buffer buf)
    new-window))

(defun fuzzy-finder--command (executable arguments input-command output-file)
  "Construct command line string for fuzzy finder process.

EXECUTABLE should be a name of path of fuzzy finder and it will be invoked with
ARGUMENTS.
If INPUT-COMMAND is non-nil and not a empty string, the output will be piped
into the fuzzy finder process.
OUTPUT-FILE is a temporary file that selection results will be stored."
  ;; TODO: Support windows
  (cl-assert executable)
  (cl-assert arguments)
  (cl-assert output-file)
  (format "%s%s %s>%s"
          (if (and input-command
                   (not (string= input-command
                                 "")))
              (concat input-command "|")
            "")
          (shell-quote-argument executable)
          arguments
          (shell-quote-argument output-file)))
;; (fuzzy-finder--command "fz f" "--reverse" "find ." "/a b/tmp.out")

(cl-defun fuzzy-finder--after-term-handle-exit (&rest _)
  "Call the action function when fuzzy-finder program terminated normally.

Should be hooked to `term-handle-exit'."
  (unless fuzzy-finder--output-file
    (cl-return-from fuzzy-finder--after-term-handle-exit))

  (run-hooks 'fuzzy-finder-exit-hook)
  (let* ((buf (current-buffer))
         (output-file fuzzy-finder--output-file)
         (output-delimiter fuzzy-finder--output-delimiter)
         (action fuzzy-finder--action)
         (text (with-temp-buffer
                 (insert-file-contents output-file)
                 (buffer-substring-no-properties (point-min) (point-max))))
         (lines (split-string text output-delimiter t)))
    (delete-file output-file)
    (set-window-configuration fuzzy-finder--window-configuration)
    (when lines
      (with-current-buffer buf
        (funcall action lines)))))
(advice-add #'term-handle-exit
            :after
            #'fuzzy-finder--after-term-handle-exit)

;;;###autoload
(cl-defun fuzzy-finder (&key (directory default-directory)
                             (arguments fuzzy-finder-default-arguments)
                             (input-command fuzzy-finder-default-input-command)
                             (action fuzzy-finder-default-action)
                             (output-delimiter fuzzy-finder-default-output-delimiter)
                             (window-height fuzzy-finder-default-window-height))
  "Execute fuzzy-finder application.

Open a term buffer and start fuzzy-finder process using ARGUMENTS.
After the process exits successfully call ACTION function with selected items.

All arguments are optional keyword arguments.
There is a variable that defines default value for each argument except for
DIRECTORY.  For example, `fuzzy-finder-default-arguments' for the ARGUMENTS key.

`:directory DIRECTORY'
    Set the directory to start fuzzy-finder application from.
    If not given current `default-directory' will be used.

`:arguments ARGUMENTS'
    Command line arguments to be passed to `fuzzy-finder-executable'.

`:input-command INPUT-COMMAND'
    When non-empty string is given for INPUT-COMMAND, the stdout of this
    command result will be piped (\"|\") into the the fuzzy-finder process.
    Otherwise, fuzzy-finder process will be invoked without any input, thus
    the application default might be used (\"$FZF_DEFAULT_COMMAND\" for
    example).

`:action ACTION'
    Callback function that results of fuzzy-finder selection will be passed to.

    This function shall accept one argument RESULTS.
    RESULTS is a list of string of fuzzy-finder selection: it will be made by
    splitting stdout of command by OUTPUT-DELIMITER.

`:output-delimiter OUTPUT-DELIMITER'
    Regular expression to split the command output.
    When the stdout is delimited by ASCII NUL characters, this value should be
    \"\\0\".

`:window-height WINDOW-HEIGHT'
    Interger height of window that displays fuzzy-finder buffer."
  (interactive)
  (unless (executable-find fuzzy-finder-executable)
    (user-error "Fuzzy-finder-executable \"%s\" not found"
                fuzzy-finder-executable))
  ;; Modified from fzf.el: https://github.com/bling/fzf.el
  (setq fuzzy-finder--window-configuration
        (current-window-configuration))

  (let* ((buf (fuzzy-finder--get-buffer-create t))
         (output-file (make-temp-file "fzf-el-result"))
         (command (fuzzy-finder--command fuzzy-finder-executable
                                         arguments
                                         input-command
                                         output-file)))

    (fuzzy-finder--display-buffer buf window-height)

    (cd directory)
    (make-term fuzzy-finder--process-name
               shell-file-name
               nil
               shell-command-switch
               command)
    (term-char-mode)

    (setq-local fuzzy-finder--output-file output-file)
    (setq-local fuzzy-finder--output-delimiter output-delimiter)
    (setq-local fuzzy-finder--action action)

    (linum-mode 0)
    (visual-line-mode 0)
    (when (fboundp #'company-mode)
      (company-mode 0))
    (setq-local mode-line-format nil)
    (setq-local scroll-margin 0)
    (setq-local scroll-conservatively 0)
    (setq-local term-suppress-hard-newline t)  ; for paths wider than the window
    (setq-local show-trailing-whitespace nil)
    (setq-local display-line-numbers nil)
    (face-remap-add-relative 'mode-line '(:box nil))

    (fuzzy-finder-mode 1)
    (run-hooks 'fuzzy-finder-init-hook)))

(defun fuzzy-finder-abort ()
  "Abort current fuzzy finder process."
  (interactive)
  (let ((buf (fuzzy-finder--get-buffer-create)))
    (when buf
      (interrupt-process buf))))

(defvar fuzzy-finder-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-g") 'fuzzy-finder-abort)
    map)
  "Keymap for `fuzzy-finder-mode'.")

(define-minor-mode fuzzy-finder-mode
  "Minor-mode for `fuzzy-finder' buffer.

The main purpose of this minor-mode is to define some keybindings.")

(defun fuzzy-finder-action-find-files (files)
  "Visit FILES."
  (dolist (file (mapcar #'expand-file-name  files))
    (find-file file)))

(defun fuzzy-finder-action-find-files-goto-line (results)
  "Visit files and then goto line.

RESULTS should a list of strings.
Each string should be in the form of:

    FILENAME:LINENUMBER:CONTENT"
  ;; Modified from fzf.el: https://github.com/bling/fzf.el
  (let ((results (mapcar (lambda (result)
                           (let* ((fields (split-string result ":"))
                                  (file (pop fields))
                                  (linenumber (pop fields)))
                             (list :file (expand-file-name file)
                                   :linenumber (and linenumber
                                                    (string-to-number linenumber)))))
                         results)))
    (dolist (result results)
      (find-file (plist-get result :file))
      (when (plist-get result :linenumber)
        (goto-char (point-min))
        (forward-line (1- (plist-get result :linenumber)))
        (back-to-indentation)))))

(declare-function projectile-project-root "projectile")

;;;###autoload
(defun fuzzy-finder-find-files-projectile ()
  "Execute fuzzy finder and visit resulting files.

If projectile package is available and root directory is found, start from that
directory."
  (interactive)
  (let ((dir (or (ignore-errors
                   (require 'projectile)
                   (projectile-project-root))
                 default-directory)))
    (fuzzy-finder :directory dir
                  :action #'fuzzy-finder-action-find-files)))

;;;###autoload
(defun fuzzy-finder-goto-gitgrep-line ()
  "Select line with fuzzy finder and go to selected point in a git repository.

Run git grep command to generate input lines."
  (interactive)
  (let ((dir (or (ignore-errors
                   (require 'projectile)
                   (projectile-project-root))
                 default-directory)))
    (fuzzy-finder :directory dir
                  :input-command "git grep -nH ^"
                  :action #'fuzzy-finder-action-find-files-goto-line)))

(provide 'fuzzy-finder)

;;; fuzzy-finder.el ends here
