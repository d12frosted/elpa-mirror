;;; fd-dired.el --- find-dired alternative using fd  -*- lexical-binding: t; -*-

;; Copyright © 2018, Free Software Foundation, Inc.

;; Version: 0.1.0
;; URL: https://github.com/yqrashawn/fd-dired
;; Package-Requires: ((emacs "25"))
;; Author: Rashawn Zhang <namy.19@gmail.com>
;; Created:  3 July 2018
;; Keywords: tools, fd, find, dired

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

;; Provide a dired-mode interface for fd's result.  Same functionality as
;; find-dired, use fd instead.  Depend on find-dired.

;; Just call `fd-dired'.

;;; Code:

(require 'find-dired)
(require 'ibuffer)
(require 'ibuf-ext)

(defvar fd-dired-program "fd"
  "The default fd program.")

(defvar fd-grep-dired-program "rg"
  "The default fd grep program.")

(defvar fd-dired-input-fd-args ""
  "Last used fd arguments.")

(defvar fd-dired-args-history nil
  "History list of fd arguments entered in the minibuffer.")

(defgroup fd-dired nil
  "fd-dired customize group."
  :prefix "fd-dired-"
  :group 'fd-dired)

(defcustom fd-dired-display-in-current-window t
  "Whether display result"
  :type 'boolean
  :safe #'booleanp
  :group 'fd-dired)

(defcustom fd-dired-pre-fd-args "-0 -c never"
  "Fd arguments inserted before user arguments."
  :type 'string
  :group 'fd-dired)

(defcustom fd-grep-dired-pre-grep-args "--color never --regexp"
  "Fd grep arguments inserted before user arguments."
  :type 'string
  :group 'fd-dired)

(defcustom fd-dired-ls-option
  (pcase system-type
    ('darwin
     ;; NOTE: here `gls' need to `brew install coreutils'
     (if (executable-find "gls")
         `(,(concat "| xargs -0 " "gls -ld --quoting-style=literal | uniq") . "-ld")
       (warn "macOS system default 'ls' command does not support option --quoting-style=literal.\n Please install with: brew install coreutils")))
    (_
     `(,(concat "| xargs -0 " insert-directory-program " -ld --quoting-style=literal | uniq") . "-ld")))
  "A pair of options to produce and parse an `ls -l'-type list from `fd'.
This is a cons of two strings (FD-ARGUMENTS . LS-SWITCHES).
FD-ARGUMENTS is the option passed to `fd' to produce a file
listing in the desired format.  LS-SWITCHES is a set of `ls'
switches that tell dired how to parse the output of `fd'.

For more information, see `FIND-LS-OPTION'."
  :type '(cons :tag "Fd arguments pair"
               (string :tag "Fd arguments")
               (string :tag "Ls Switches"))
  :group 'fd-dired)

(defcustom fd-dired-generate-random-buffer nil
  "Generate random buffer name.
If this variable is non-nil, new fd-dired buffers will have
random and hidden names."
  :type 'boolean
  :group 'fd-dired)


;;;###autoload
(defun fd-dired (dir args)
  "Run `fd' and go into Dired mode on a buffer of the output.
The command run (after changing into DIR) is essentially

    fd . ARGS -ls

except that the car of the variable `fd-dired-ls-option' specifies what to
use in place of \"-ls\" as the final argument."
  (interactive (list (read-directory-name "Run fd in directory: " nil "" t)
                     (read-string "Run fd (with args and search): " fd-dired-input-fd-args
                                  '(fd-dired-args-history . 1))))
  (let ((dired-buffers dired-buffers)
        (fd-dired-buffer-name (if fd-dired-generate-random-buffer
                                  (format " *%s*" (make-temp-name "Fd "))
                                "*Fd*")))
    ;; Expand DIR ("" means default-directory), and make sure it has a
    ;; trailing slash.
    (setq dir (file-name-as-directory (expand-file-name (or dir default-directory))))
    ;; Check that it's really a directory.
    (or (file-directory-p dir)
        (error "Fd-dired needs a directory: %s" dir))

    (get-buffer-create fd-dired-buffer-name)
    (if fd-dired-display-in-current-window
        (display-buffer (get-buffer fd-dired-buffer-name) nil)
      (display-buffer-below-selected (get-buffer fd-dired-buffer-name) nil)
      (select-window (get-buffer-window fd-dired-buffer-name)))

    (with-current-buffer (get-buffer fd-dired-buffer-name)
      ;; prepare buffer
      (widen)
      (kill-all-local-variables)
      (setq buffer-read-only nil)
      (erase-buffer)

      ;; Start the process.
      (setq default-directory dir
            fd-dired-input-fd-args args        ; save for next interactive call
            args (concat fd-dired-program " " fd-dired-pre-fd-args
                         ;; " . "
                         (if (string= args "")
                             ""
                           (concat
                            " " args " "
                            " "))
                         (if (string-match "\\`\\(.*\\) {} \\(\\\\;\\|+\\)\\'"
                                           (car fd-dired-ls-option))
                             (format "%s %s %s"
                                     (match-string 1 (car fd-dired-ls-option))
                                     (shell-quote-argument "{}")
                                     find-exec-terminator)
                           (car fd-dired-ls-option))))
      (shell-command (concat args " &") (get-buffer-create fd-dired-buffer-name))

      ;; enable Dired mode
      ;; The next statement will bomb in classic dired (no optional arg allowed)
      (dired-mode dir (cdr fd-dired-ls-option))
      ;; provide a keybinding to kill the find process
      (let ((map (make-sparse-keymap)))
        (set-keymap-parent map (current-local-map))
        (define-key map "\C-c\C-k" #'kill-find)
        (define-key map (kbd "M-S") #'fd-dired-save-search-as-name)
        (use-local-map map))
      ;; disable Dired sort
      (make-local-variable 'dired-sort-inhibit)
      (setq dired-sort-inhibit t)
      (set (make-local-variable 'revert-buffer-function)
           `(lambda (ignore-auto noconfirm)
              (fd-dired ,dir ,fd-dired-input-fd-args)))
      ;; Set `subdir-alist' so that Tree Dired will work:
      (if (fboundp 'dired-simple-subdir-alist)
          ;; will work even with nested dired format (dired-nstd.el,v 1.15
          ;; and later)
          (dired-simple-subdir-alist)
        ;; else we have an ancient tree dired (or classic dired, where
        ;; this does no harm)
        (set (make-local-variable 'dired-subdir-alist)
             (list (cons default-directory (point-min-marker)))))
      (set (make-local-variable 'dired-subdir-switches) find-ls-subdir-switches)
      (setq buffer-read-only nil)
      ;; Subdir headlerline must come first because the first marker in
      ;; `subdir-alist' points there.
      (insert "  " dir ":\n")

      ;; Make second line a ``find'' line in analogy to the ``total'' or
      ;; ``wildcard'' line.
      (let ((point (point)))
        (insert "  " args "\n")
        (dired-insert-set-properties point (point)))
      (setq buffer-read-only t)

      (let ((proc (get-buffer-process (get-buffer fd-dired-buffer-name))))
        (set-process-filter proc (function find-dired-filter))
        (set-process-sentinel proc (function find-dired-sentinel))
        ;; Initialize the process marker; it is used by the filter.
        (move-marker (process-mark proc) (point) (get-buffer fd-dired-buffer-name)))
      (setq mode-line-process '(":%s")))))

;;;###autoload
(defun fd-name-dired (dir pattern)
  "Search DIR recursively for files matching the globbing pattern PATTERN,
and run Dired on those files.
PATTERN is a shell wildcard (not an Emacs regexp) and need not be quoted.
The default command run (after changing into DIR) is

    fd . ARGS \\='PATTERN\\=' | fd-dired-ls-option"
  (interactive
   "DFd-name (directory): \nsFd-name (filename regexp): ")
  (fd-dired dir (shell-quote-argument pattern)))

;;;###autoload
(defun fd-grep-dired (dir regexp)
  "Find files in DIR that contain matches for REGEXP and start Dired on output.
The command run (after changing into DIR) is

  fd . ARGS --exec rg --regexp REGEXP -0 -ls | fd-dired-ls-option"
  (interactive "DFd-grep (directory): \nsFd-grep (rg regexp): ")
  (fd-dired dir (concat "--exec " fd-grep-dired-program
                        " " fd-grep-dired-pre-grep-args " "
		                (shell-quote-argument regexp)
                        " -0 -ls ")))

(defun fd-dired-cleanup ()
  "Clean up fd-dired created temp buffers for multiple searching processes."
  (mapcar 'kill-buffer
          (seq-filter
           (lambda (buffer-name)
             (string-match-p (rx (seq "*Fd " (zero-or-more nonl) "*")) buffer-name))
           (mapcar 'buffer-name (buffer-list)))))

(add-hook 'kill-emacs-hook #'fd-dired-cleanup)

(defun fd-dired-save-search-as-name (newname)
  "Save the search result in current result buffer.
NEWNAME will be added to the result buffer name.  New searches will use the
standard buffer unless the search is done from a saved buffer in
which case the saved buffer will be reused."
  (interactive "sSave search as name: ")
  (let ((buffer (current-buffer)))
    (when (and (string-match-p (rx bos (? " ") "*Fd") (buffer-name buffer))
               (derived-mode-p 'dired-mode))
      (with-current-buffer buffer
        (rename-buffer (format "*Fd %s*" newname) t)))))

(defun fd-dired-list-searches ()
  "List all fd buffers in `ibuffer'."
  (interactive)
  (let ((buffer-name "*Searches fd*")
        (other-window (equal current-prefix-arg '(4))))
    (ibuffer other-window buffer-name
             `((mode . dired-mode) (name . ,(rx bos "*Fd"))))
    (with-current-buffer buffer-name
      (ibuffer-auto-mode)
      (set (make-local-variable 'ibuffer-use-header-line) nil)
      (ibuffer-clear-filter-groups))))

(provide 'fd-dired)

;;; fd-dired.el ends here
