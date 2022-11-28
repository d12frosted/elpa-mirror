;;; agtags.el --- A frontend to GNU Global -*- lexical-binding: t; -*-

;; Copyright (C) 2018 Vietor Liu

;; Author: Vietor Liu <vietor.liu@gmail.com>
;; Version: 0.2.2
;; Keywords: tools, convenience
;; Created: 2018-12-14
;; URL: https://github.com/vietor/agtags
;; Package-Requires: ((emacs "25"))

;; This program is free software; you can redistribute it and/or modify
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
;; A package to integrate GNU Global source code tagging system
;; (http://www.gnu.org/software/global) with Emacs.

;;; Code:
(require 'grep)
(require 'xref)
(require 'compile)
(require 'subr-x)
(require 'pcase)

(defvar agtags-mode)

(defgroup agtags nil
  "GNU Global source code tagging system."
  :group 'tools)

(defcustom agtags-key-prefix "C-c t"
  "It is used for the prefix key of agtags's command."
  :safe 'stringp
  :type 'string
  :group 'agtags)

(defcustom agtags-global-ignore-case nil
  "Non-nil if Global should ignore case in the search pattern."
  :safe 'booleanp
  :type 'boolean
  :group 'agtags)

(defcustom agtags-global-treat-text nil
  "Non-nil if Global should include matches from text files.
This affects 'agtags--find-file' and 'agtags--find-grep'."
  :safe 'booleanp
  :type 'boolean
  :group 'agtags)

(defvar agtags--history-list nil
  "Gtags history list.")

(defconst agtags--display-buffer-dwim '((display-buffer-reuse-window
                                         display-buffer-same-window)
                                        (inhibit-same-window . nil))
  "Custom 'display-buffer-overriding-action' in agtags-*-mode.")

(defvar agtags--global-to-list-cache nil
  "Cache for 'agtags--run-cached-global-to-list.")

;;
;; The private functions
;;

(defun agtags--quote (string)
  "Return a regular expression whose only exact match is STRING."
  (cond ((string-match-p "^-" string)
         (concat "\\" string))
        (t (regexp-quote string))))

(defun agtags--get-root ()
  "Get and validate env  `GTAGSROOT`."
  (let ((dir (getenv "GTAGSROOT")))
    (when (string-empty-p dir)
      (error "No env `GTAGSROOT` provided"))
    dir))

(defun agtags--is-active ()
  "Test global was created."
  (let ((dir (getenv "GTAGSROOT")))
    (and (> (length dir) 0)
         (file-regular-p (expand-file-name "GTAGS" dir)))))

(defun agtags--run-global-to-list (arguments)
  "Execute the global command to list, use ARGUMENTS;
Return nil if an error occured."
  (let ((default-directory (agtags--get-root)))
    (condition-case nil
        (apply #'process-lines "global" arguments)
      (error nil))))

(defun agtags--run-cached-global-to-list (arguments)
  "Execute the global command to list and cache it, use ARGUMENTS;
Return nil if an error occured."
  (let ((cache-key (string-join arguments "$"))
        (result-data nil))
    (if (and agtags--global-to-list-cache
             (string= (car agtags--global-to-list-cache) cache-key))
        (cdr agtags--global-to-list-cache)
      (progn
        (setq result-data (agtags--run-global-to-list arguments))
        (when result-data
          (setq agtags--global-to-list-cache (cons cache-key result-data)))
        result-data))))

(defun agtags--run-global-to-mode (arguments &optional result)
  "Execute the global command to agtags-*-mode, use ARGUMENTS;
Output format use RESULT."
  (let* ((xr (or result "grep"))
         (xs (delq nil (append (list "global"
                                     (format "--result=%s" xr)
                                     (and agtags-global-ignore-case "-i")
                                     (and agtags-global-treat-text "-o"))
                               arguments)))
         (default-directory (agtags--get-root))
         (display-buffer-overriding-action agtags--display-buffer-dwim))
    (compilation-start (mapconcat #'identity xs " ")
                       (if (string= xr "path") 'agtags-path-mode 'agtags-grep-mode))))

(defun agtags--run-global-completing (flag string predicate code)
  "Completion Function with FLAG for `completing-read'.
Require: STRING PREDICATE CODE."
  (let* ((xs (delq nil (append (list "-c"
                                     (and (eq flag 'files) "-P")
                                     (and (eq flag 'rtags) "-r")
                                     (and agtags-global-ignore-case "-i")
                                     (and agtags-global-treat-text "-o")
                                     string))))
         (candidates (agtags--run-cached-global-to-list xs)))
    (cond ((eq code nil)
	       (try-completion string candidates predicate))
	      ((eq code t)
	       (all-completions string candidates predicate))
	      ((eq code 'lambda)
	       (if (intern-soft string candidates) t nil)))))

(defun agtags--read-dwim ()
  "If there's an active selection, return that.
Otherwise, get the symbol at point, as a string."
  (cond ((use-region-p)
         (buffer-substring-no-properties (region-beginning) (region-end)))
        ((symbol-at-point)
         (substring-no-properties
          (symbol-name (symbol-at-point))))))

(defun agtags--read-input (prompt)
  "Read a value from the minibuffer with PROMPT."
  (let ((final-prompt (format "%s: " prompt)))
    (read-from-minibuffer final-prompt nil nil nil agtags--history-list)))

(defun agtags--read-input-dwim (prompt)
  "Read a value from the minibuffer with PROMPT.
If there's a string at point, offer that as a default."
  (let* ((suggested (agtags--read-dwim))
         (final-prompt (if suggested
                           (format "%s (default %s): " prompt suggested)
                         (format "%s: " prompt)))
         (user-input (read-from-minibuffer
                      final-prompt
                      nil nil nil agtags--history-list suggested)))
    (if (> (length user-input) 0) user-input suggested)))

(defun agtags--read-completing (flag prompt)
  "Read a value from the Completion by FLAG with PROMPT."
  (let* ((final-prompt (format "%s: " prompt))
         (user-input (completing-read
                      final-prompt
                      (lambda (string predicate code)
                        (agtags--run-global-completing flag string predicate code))
                      nil nil nil agtags--history-list)))
    user-input))

(defun agtags--read-completing-dwim (flag prompt)
  "Read a value from the Completion by FLAG with PROMPT.
If there's a string at point, offer that as a default."
  (let* ((suggested (agtags--read-dwim))
         (final-prompt (if suggested
                           (format "%s (default %s): " prompt suggested)
                         (format "%s: " prompt)))
         (user-input (completing-read
                      final-prompt
                      (lambda (string predicate code)
                        (agtags--run-global-completing flag string predicate code))
                      nil nil nil agtags--history-list suggested)))
    (if (> (length user-input) 0) user-input suggested)))

;;
;; The agtags-*-mode support
;;

(defun agtags--auto-update()
  "Auto update tags file, when buffer was save."
  (when (and agtags-mode
             buffer-file-name
             (agtags--is-active)
             (string-prefix-p (agtags--get-root) buffer-file-name))
    (setq agtags--global-to-list-cache nil)
    (call-process "global" nil nil nil "-u" (concat "--single-update=" buffer-file-name))))

(defadvice compile-goto-error (around agtags activate)
  "Use same window when goto selected."
  (let ((display-buffer-overriding-action agtags--display-buffer-dwim))
    ad-do-it))

(defconst agtags--global-mode-font-lock-keywords
  '(("^Global \\(exited abnormally\\|interrupt\\|killed\\|terminated\\)\\(?:.*with code \\([0-9]+\\)\\)?.*"
     (1 'compilation-error)
     (2 'compilation-error nil t))
    ("^Global found \\([0-9]+\\)" (1 compilation-info-face)))
  "Common highlighting expressions for agtags-*-mode.")

(defconst agtags--global-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map special-mode-map)
    (define-key map [follow-link] 'mouse-face)
    (define-key map [mouse-2] 'compile-goto-error)
    (define-key map "\r" 'compile-goto-error)
    (define-key map "\C-m" 'compile-goto-error)
    (define-key map "g" 'recompile)
    (define-key map "n" 'compilation-next-error)
    (define-key map "p" 'compilation-previous-error)
    (define-key map "{" 'compilation-previous-file)
    (define-key map "}" 'compilation-next-file)
    map)
  "Common keymap for agtags-*-mode.")

(defconst agtags--path-regexp-alist
  `((,"^\\(?:[^\"'\n]*/\\)?[^ )\t\n]+$" 0))
  "Custom 'compilation-error-regexp-alist' for `agtags-path-mode`.")

(defconst agtags--grep-regexp-alist
  `((,"^\\(.+?\\):\\([0-9]+\\):\\(?:$\\|[^0-9\n]\\|[0-9][^0-9\n]\\|[0-9][0-9].\\)"
     1 2
     (,(lambda ()
         (let* ((start (1+ (match-end 2)))
                (mbeg (text-property-any start (line-end-position) 'global-color t)))
           (and mbeg (- mbeg start)))))
     nil 1))
  "Custom 'compilation-error-regexp-alist' for `agtags-grep-mode`.")

(defun agtags--global-mode-finished (buffer _tatus)
  "Function to call when a gun global process finishes.
BUFFER is the global's mode buffer, STATUS was the finish status."
  (let* ((name (buffer-name buffer))
         (dname (if (string= name "*agtags-grep*")
                    "*agtags-path*"
                  "*agtags-grep*"))
         (dbuffer (get-buffer dname)))
    (when dbuffer
      (delete-windows-on dbuffer)
      (kill-buffer dbuffer))))

;;
;; The agtags-grep-mode
;;

(defvar agtags-grep-mode-map agtags--global-mode-map)
(defvar agtags-grep-mode-font-lock-keywords agtags--global-mode-font-lock-keywords)

;;;###autoload
(define-derived-mode agtags-grep-mode grep-mode "Global Grep"
  "A mode for showing outputs from gnu global."
  (setq-local grep-scroll-output nil)
  (setq-local grep-highlight-matches nil)
  (setq-local compilation-always-kill t)
  (setq-local compilation-disable-input t)
  (setq-local compilation-error-screen-columns nil)
  (setq-local compilation-scroll-output 'first-error)
  (setq-local compilation-error-regexp-alist agtags--grep-regexp-alist)
  (setq-local compilation-finish-functions #'agtags--global-mode-finished))

;;
;; The agtags-path-mode
;;

(defvar agtags-path-mode-map agtags--global-mode-map)
(defvar agtags-path-mode-font-lock-keywords agtags--global-mode-font-lock-keywords)

;;;###autoload
(define-compilation-mode agtags-path-mode "Global Files"
  "A mode for showing files from gnu global."
  (setq-local compilation-error-face grep-hit-face)
  (setq-local compilation-always-kill t)
  (setq-local compilation-disable-input t)
  (setq-local compilation-error-screen-columns nil)
  (setq-local compilation-scroll-output 'first-error)
  (setq-local compilation-error-regexp-alist agtags--path-regexp-alist)
  (setq-local compilation-finish-functions #'agtags--global-mode-finished))

;;
;; The agtags-mode
;;

(defvar agtags--completion-table
  (let ((fun (lambda (prefix)
               (agtags--run-cached-global-to-list (list "-c" prefix)))))
    (completion-table-dynamic fun)))

(defun agtags--completion-at-point ()
  "A function for `completion-at-point-functions'."
  (pcase (bounds-of-thing-at-point 'symbol)
    (`(,beg . ,end)
     (when (< beg end)
       (list beg end agtags--completion-table
             :annotation-function (lambda (_) " Gtags")
             :exclusive 'no)))))

(defun agtags-xref--make-xref (ctags-x-line)
  "Create and return an xref object pointing to a file location.
This uses the output of a based on global -x output line provided
in CTAGS-X-LINE argument.  If the line does not match the
expected format, return nil."
  (if (string-match
       "^\\([^ \t]+\\)[ \t]+\\([0-9]+\\)[ \t]+\\([^ \t\]+\\)[ \t]+\\(.*\\)"
       ctags-x-line)
      (xref-make (match-string 4 ctags-x-line)
                 (xref-make-file-location (match-string 3 ctags-x-line)
                                          (string-to-number (match-string 2 ctags-x-line))
                                          0))))

(defun agtags-xref--find-symbol (symbol &rest args)
  "Run GNU Global to find a symbol SYMBOL.
Return the results as a list of xref location objects.  ARGS are
any additional command line arguments to pass to GNU Global."
  (let* ((process-args (append
                        args
                        (list "-x" "-a" symbol)))
         (global-output (agtags--run-global-to-list process-args)))
    (remove nil (mapcar #'agtags-xref--make-xref global-output))))

(defun agtags-xref--backend ()
  "The agtags backend for Xref."
  (when (agtags--is-active)
    'agtags))

(cl-defmethod xref-backend-identifier-at-point ((_backend (eql agtags)))
  (agtags--read-dwim))

(cl-defmethod xref-backend-identifier-completion-table ((_backend (eql agtags)))
  agtags--completion-table)

(cl-defmethod xref-backend-definitions ((_backend (eql agtags)) symbol)
  (agtags-xref--find-symbol (agtags--quote symbol) "-d"))

(cl-defmethod xref-backend-references ((_backend (eql agtags)) symbol)
  (agtags-xref--find-symbol (agtags--quote symbol) "-r"))

(cl-defmethod xref-backend-apropos ((_backend (eql agtags)) symbol)
  (agtags-xref--find-symbol symbol "-g"))

;;;###autoload
(define-minor-mode agtags-mode nil
  :lighter " Gtags"
  (if agtags-mode
      (progn
        (add-hook 'before-save-hook 'agtags--auto-update nil t)
        (add-hook 'xref-backend-functions 'agtags-xref--backend nil t)
        (add-hook 'completion-at-point-functions #'agtags--completion-at-point t t))
    (progn
      (remove-hook 'before-save-hook 'agtags--auto-update t)
      (remove-hook 'xref-backend-functions 'agtags-xref--backend t)
      (remove-hook 'completion-at-point-functions #'agtags--completion-at-point t))))

;;
;; The interactive functions
;;

(defun agtags-update-tags ()
  "Create or Update tag files (e.g. GTAGS) in directory `GTAGSROOT`."
  (interactive)
  (setq agtags--global-to-list-cache nil)
  (let ((rootpath (agtags--get-root)))
    (dolist (file (list "GRTAGS" "GPATH" "GTAGS"))
      (ignore-errors
        (delete-file (expand-file-name file rootpath))))
    (with-temp-buffer
      (cd rootpath)
      (when (zerop (call-process (executable-find "gtags") nil t nil "-i"))
        (message "Tags create or update by GTAGS")))))

(defun agtags-open-file ()
  "Input pattern and move to the top of the file."
  (interactive)
  (let ((user-input (agtags--read-completing 'files "Open file")))
    (when (> (length user-input) 0)
      (find-file (expand-file-name user-input (agtags--get-root))))))

(defun agtags-find-file ()
  "Input pattern, search file and move to the top of the file."
  (interactive)
  (let ((user-input (agtags--read-input "Find files")))
    (when (> (length user-input) 0)
      (agtags--run-global-to-mode (list "-P" (shell-quote-argument user-input) "path")))))

(defun agtags-find-tag ()
  "Input tag and move to the locations."
  (interactive)
  (let ((user-input (agtags--read-completing-dwim 'tags "Find tag")))
    (when (> (length user-input) 0)
      (agtags--run-global-to-mode (list (shell-quote-argument (agtags--quote user-input)))))))

(defun agtags-find-rtag ()
  "Input rtags and move to the locations."
  (interactive)
  (let ((user-input (agtags--read-completing-dwim 'rtags "Find rtag")))
    (when (> (length user-input) 0)
      (agtags--run-global-to-mode (list "-r" (shell-quote-argument (agtags--quote user-input)))))))

(defun agtags-find-with-pattern ()
  "Input pattern, search with grep(1) and move to the locations."
  (interactive)
  (let ((user-input (agtags--read-input-dwim "Search pattern")))
    (when (> (length user-input) 0)
      (agtags--run-global-to-mode (list "-g" (shell-quote-argument user-input))))))

(defun agtags-find-with-string ()
  "Input string, search as substring and move to the locations."
  (interactive)
  (let ((user-input (agtags--read-input-dwim "Search string")))
    (when (> (length user-input) 0)
      (agtags--run-global-to-mode (list "-g" (shell-quote-argument (agtags--quote user-input)))))))

(defun agtags-switch-dwim ()
  "Switch to last agtags-*-mode buffer."
  (interactive)
  (let ((buffer (or (get-buffer "*agtags-grep*")
                    (get-buffer "*agtags-path*")
                    (other-buffer (current-buffer) 1))))
    (when buffer
      (switch-to-buffer buffer))))

;;
;; The public functions
;;

;;;###autoload
(defun agtags-bind-keys()
  "Set global key bindings for agtags."
  (dolist (pair '(("q" . agtags-switch-dwim)
                  ("b" . agtags-update-tags)
                  ("f" . agtags-open-file)
                  ("F" . agtags-find-file)
                  ("t" . agtags-find-tag)
                  ("r" . agtags-find-rtag)
                  ("p" . agtags-find-with-string)
                  ("g" . agtags-find-with-pattern)))
    (global-set-key (kbd (concat agtags-key-prefix " " (car pair))) (cdr pair))))

;;;###autoload
(defun agtags-update-root (root)
  "Set ROOT directory of the project for agtags."
  (setenv "GTAGSROOT" root)
  (setq agtags--global-to-list-cache nil))

(provide 'agtags)
;;; agtags.el ends here
