;;; native-complete.el --- Shell completion using native complete mechanisms -*- lexical-binding: t; -*-

;; Copyright (C) 2019 by Troy Hinckley

;; Author: Troy Hinckley <troy.hinckley@gmail.com>
;; URL: https://github.com/CeleritasCelery/emacs-native-shell-complete
;; Package-Version: 20220707.1544
;; Package-Commit: 9dbfc842b3af803f636df61dec6129e1d8593ee4
;; Version: 0.1.0
;; Package-Requires: ((emacs "26.1"))

;; This file is not part of GNU Emacs.

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <https://www.gnu.org/licenses/>.

;;; Commentary:
;; This package interacts with a shell's native completion functionality to
;; provide the same completions in Emacs that you would get from the shell
;; itself.

;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'shell)

(defvar native-complete--command "")
(defvar native-complete--prefix "")
(defvar native-complete--common "")
(defvar native-complete--redirection-command "")
(defvar native-complete--buffer " *native-complete redirect*")

(defgroup native-complete nil
  "Native completion in a shell buffer."
  :group 'shell)

(defcustom native-complete-major-modes '(shell-mode comint-mode)
  "Major modes for which native completion is enabled."
  :type '(repeat function))

(defcustom native-complete-exclude-regex (rx (not (in alnum "-_~()/*.,+$")))
  "Regex of elements to ignore when generating candidates.
Any candidates matching this regex will not be included in final
  list of candidates."
  :type 'regexp)

(defcustom native-complete-style-suffix-alist
  ;; Bash is a little odd in that this command will insert inline (not create a
  ;; new prompt). So we cut and paste it into an echo command so it works with
  ;; redirection.
  '((bash . "\e*' echo '")
    (zsh . "y")
    (csh . "y")
    (sqlite . "\t\ty")
    (default . "\ty"))
  "Alist mapping style symbols to strings appended to completion candidates.
The keys should be the same as the possible values of
`native-complete-style-regex-alist'."
  :type '(alist :key-type symbol :value-type string)
  :options '(bash zsh csh sqlite default))

(defcustom native-complete-style-regex-alist
  `((,(rx bol (or "   ..." "sqlite") "> ") . sqlite))
  "An alist of prompt regex and their completion mechanisms.
the CAR of each alist element is a regex matching the prompt for
a particular shell type. The CDR should be one of the keys (CARs)
of `native-complete-style-suffix-alist'.

You may need to test this on an line editing enabled shell to see
which of these options a particular shell supports. Most shells
support basic TAB completion, but some will not echo the
candidate to output when it is the sole completion. Hence the
need for the other methods as well."
  :type `(alist
          :key-type regexp
          :value-type (choice symbol
                              ,@(mapcar (lambda (pair) `(const ,(car pair)))
                                        native-complete-style-suffix-alist))))

;;;###autoload
(defun native-complete-setup-bash ()
  "Setup support for native-complete enabled bash shells.
This involves not sending the `--noediting' argument as well as
setting `TERM' to a value other then dumb."
  (interactive)
  (when (equal comint-terminfo-terminal "dumb")
    (setq comint-terminfo-terminal "vt50"))
  (setq explicit-bash-args
        (delete "--noediting" explicit-bash-args)))

(defun native-complete-get-completion-style ()
  "Get the completion style based on current prompt."
  (or (cl-loop for (regex . style) in native-complete-style-regex-alist
               if (native-complete--at-prompt-p regex)
               return style)
      (cl-loop for style in '(bash zsh csh)
               if (string-match-p (symbol-name style) shell-file-name)
               return style)
      'default))

(defun native-complete-get-suffix (style)
  "Return string to be appended to completion candidates for STYLE.
See `native-complete-style-suffix-alist'."
  (or (alist-get style native-complete-style-suffix-alist)
      (alist-get 'default native-complete-style-suffix-alist)))

(defun native-complete--at-prompt-p (regex)
  "Point matches the end of a prompt defined by REGEX"
  ;; `inhibit-field-text-motion' alows `line-beginning-position' to move past
  ;; the process mark, which has a special text property marking it as a
  ;; different field.
  (let ((inhibit-field-text-motion t))
    (looking-back regex (line-beginning-position))))

(defun native-complete--redirection-active-p ()
  "Indicate whether redirection is currently active."
  (string-match-p "Redirection"
                  (cond
                   ((stringp mode-line-process)
                    mode-line-process)
                   ((and (consp mode-line-process)
                         (stringp (car mode-line-process)))
                    (car mode-line-process))
                   (t
                    ""))))

(defun native-complete--usable-p ()
  "Return non-nil if native-complete can be used at point."
  (and (memq major-mode native-complete-major-modes)
       (not (native-complete--redirection-active-p))))

(defun native-complete-abort (&rest _)
  "Abort completion and cleanup redirect if needed."
  (when (native-complete--redirection-active-p)
    (comint-redirect-cleanup)))

(advice-add 'comint-send-input :before #'native-complete-abort)

(defun native-complete--split-command (cmd)
  "Split the command into the common and prefix sections"
  (let* ((word-start (or (cl-search " " cmd :from-end t) -1))
         (env-start (or (cl-search "$" cmd :from-end t) -1))
         (path-start (or (cl-search "/" cmd :from-end t) -1))
         (prefix-start (1+ (max word-start env-start path-start))))
    (cons (substring cmd (1+ word-start) prefix-start)
          (substring cmd prefix-start))))

(defun native-complete--get-prefix ()
  "Setup output redirection to query the source shell."
  (let* ((redirect-buffer (get-buffer-create native-complete--buffer))
         (proc (get-buffer-process (current-buffer)))
         (beg (process-mark proc))
         (end (point))
         (cmd (buffer-substring-no-properties beg end))
         (style (cl-letf (((point) beg)) (native-complete-get-completion-style)))
         ;; sanity check makes sure the input line is empty, which is
         ;; not useful when doing input completion
         (comint-redirect-perform-sanity-check nil))
    (unless (cl-letf (((point) beg))
              (native-complete--at-prompt-p comint-prompt-regexp))
      (user-error "`comint-prompt-regexp' does not match prompt"))
    (with-current-buffer redirect-buffer (erase-buffer))
    (setq cmd (replace-regexp-in-string (rx (in "'\"")) "" cmd))
    (cl-destructuring-bind (common . prefix) (native-complete--split-command cmd)
      (setq native-complete--command cmd
            native-complete--common common
            native-complete--prefix prefix
            ;; When the number of candidates is larger then a certain threshold
            ;; most shells will query the user before displaying them all. We
            ;; always send a "y" character to auto-answer these queries so that
            ;; we get all candidates. We do some special handling in
            ;; `native-complete--get-completions' to make sure this "y"
            ;; character never shows up in the completion list.
            native-complete--redirection-command
            (concat cmd (native-complete-get-suffix style))))))

(defun native-complete--get-completions ()
  "Using the redirection output get all completion candidates."
  (let* ((cmd (string-remove-suffix
               native-complete--prefix
               native-complete--command))
         ;; when the sole completion is something like a directory it does not
         ;; append a space. We need to seperate this candidate from the "y"
         ;; character so it will be consumed properly.
         (continued-cmd
          (rx-to-string `(: bos (group ,native-complete--command (+ graph)) "y" (in ""))))
         ;; the current command may be echoed multiple times in the output. We
         ;; only want to leave it when it ends with a space since that means it
         ;; is the sole completion
         (echo-cmd
          (rx-to-string `(: bol ,native-complete--command (* graph) (in ""))))
         ;; Remove the "display all possibilities" query so that it does not get
         ;; picked up as a completion.
         (query-text (rx bol (1+ nonl) "? "
                         (or "[y/n]" "[n/y]" "(y or n)" "(n or y)")
                         (* nonl) eol))
         (ansi-color-context nil)
         (buffer (with-current-buffer native-complete--buffer
                   (when (re-search-backward continued-cmd nil t)
                     (goto-char (match-end 1))
                     (insert " "))
                   (buffer-string))))
    (thread-last (split-string buffer "\n\n")
      (car)
      (ansi-color-filter-apply)
      (replace-regexp-in-string echo-cmd "")
      (replace-regexp-in-string "echo '.+'" "")
      (replace-regexp-in-string query-text "")
      (replace-regexp-in-string (concat "^" (regexp-quote cmd)) "")
      (split-string)
      (cl-remove-if (lambda (x) (string-match-p native-complete-exclude-regex x)))
      (mapcar (lambda (x) (string-remove-prefix native-complete--common x)))
      (mapcar (lambda (x) (string-remove-suffix "*" x)))
      (cl-remove-if-not (lambda (x) (string-prefix-p native-complete--prefix x)))
      (delete-dups))))

(defun native-complete-unload-function ()
  "Unload `native-complete'."
  (advice-remove 'comint-send-input 'native-complete-abort))

;;;###autoload
(defun native-complete-at-point ()
  "Get the candidates from the underlying shell.
This should behave the same as sending TAB in an terminal
emulator."
  (when (native-complete--usable-p)
    (native-complete--get-prefix)
    (comint-redirect-send-command
     native-complete--redirection-command
     native-complete--buffer nil t)
    (unwind-protect
        (while (or quit-flag (null comint-redirect-completed))
          (accept-process-output nil 0.1))
      (unless comint-redirect-completed
        (comint-redirect-cleanup)))
    (list (- (point) (length native-complete--prefix))
          (point)
          (native-complete--get-completions))))

(defun native-complete-tree-assoc (key tree)
  "Search a list tree structure for key."
  (when (consp tree)
    (if (eq (car tree) key)
        t
      (or (native-complete-tree-assoc key (car tree))
          (native-complete-tree-assoc key (cdr tree))))))

;;;###autoload
(defun native-complete-check-config ()
  (interactive)
  "Check the setup of native complete and look for common problems."
  (unless (memq major-mode native-complete-major-modes)
    (user-error "`native-complete-check-setup' must be run from a shell buffer"))
  (let* ((prompt-point (process-mark (get-buffer-process (current-buffer))))
         (completion-style (cl-letf (((point) prompt-point))
                             (native-complete-get-completion-style)))
         (inhibit-field-text-motion t))
    (when (equal comint-prompt-regexp "^")
      (user-error "error: `comint-prompt-regexp' has not been updated. See README for details.\n"))
    (unless (cl-letf (((point) prompt-point))
              (native-complete--at-prompt-p comint-prompt-regexp))
      (user-error "error: current prompt does not match `comint-prompt-regex'.\nprompt -> '%s'\nregex -> %s"
                  (buffer-substring (line-beginning-position) prompt-point)comint-prompt-regexp))
    (when (eq 'bash completion-style)
      (when (equal comint-terminfo-terminal "dumb")
        (user-error "error: `native-complete-setup-bash' not called. Bash is not setup")))
    (if (bound-and-true-p company-mode)
        (unless (native-complete-tree-assoc 'company-native-complete company-backends)
          (user-error "error: `company-native-complete' not one of `company-backends'"))
      (unless (native-complete-tree-assoc 'native-complete-at-point completion-at-point-functions)
        (user-error "error: `native-complete-at-point' not one of `completion-at-point-functions'")))
    (message "Success: native-complete setup for '%s' completion" completion-style)))

(provide 'native-complete)

;;; native-complete.el ends here
