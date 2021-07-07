;;; psysh.el --- PsySH, PHP interactive shell (REPL) -*- lexical-binding: t -*-

;; Copyright (C) 2018  Friends of Emacs-PHP development

;; Author: USAMI Kenta <tadsan@zonu.me>
;; Created: 22 Jan 2016
;; Version: 0.0.5
;; Package-Version: 20190709.106
;; Package-Commit: 21250984ad8137aa3440ac12e52475ef03f19fcb
;; Package-Requires: ((emacs "24.3") (s "1.9.0") (f "0.17") (php-runtime "0.2"))
;; Keywords: processes php
;; URL: https://github.com/zonuexe/psysh.el

;; This file is NOT part of GNU Emacs.

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

;; ## Installation
;;
;; ### A: The easy way
;;
;;     $ wget psysh.org/psysh
;;     $ chmod +x psysh
;;
;; And copy or make symlink to your $PATH dir.
;;
;;
;; ### B: The other easy way
;;
;; Get Composer.  See https://getcomposer.org/download/
;;
;;     $ composer g require psy/psysh:@stable
;;
;;
;; ### C: Project local REPL
;;
;; Set `psysh-comint-buffer-process' (buffer local variable).
;;
;;     (setq psysh-comint-buffer-process "path/to/shell.php")
;;
;; `shell.php' is for example:
;;
;;     #!/usr/bin/env php
;;     <?php
;;     // ↓Namespace for your project
;;     namespace Nyaan;
;;     
;;     // load Composer autoload file
;;     require_once __DIR__ . '/vendor/autoload.php';
;;     // load other initialize PHP files
;;     // require_once …
;;     
;;     echo __NAMESPACE__ . " shell\n";
;;     
;;     $sh = new \Psy\Shell();
;;     
;;     // Set project namespace in REPL
;;     if (defined('__NAMESPACE__') && __NAMESPACE__ !== '') {
;;         $sh->addCode(sprintf("namespace %s;", __NAMESPACE__));
;;     }
;;     
;;     $sh->run();
;;     
;;     // Termination message
;;     echo "Bye.\n";
;;
;; See also https://cho-phper.hateblo.jp/entry/2015/11/10/031000 *(Japanese)*
;;

;;; Code:
(require 'cc-mode)
(require 'comint)
(require 'thingatpt)
(require 's)
(require 'f)
(require 'php-runtime)
;; (require 'xdg) ; Emacs 25.3?


(defgroup psysh nil
  "PsySH"
  :tag "PsySH"
  :prefix "psysh-"
  :group 'php
  :group 'tools)

(defcustom psysh-history-file-path nil
  "Path to PsySH history file."
  :type '(choice (const  :tag "Use default path" nil)
                 (string :tag "Path to history file")))

(defcustom psysh-inherit-history t
  "If non-nil, inherits PsySH input history."
  :type 'boolean)

(defcustom psysh-doc-install-local-php-manual t
  "If non-nil, install PHP manual automatically."
  :type 'boolean)

(defconst psysh-doc-php-manual-language-url-alist
  '(("English" . "http://psysh.org/manual/en/php_manual.sqlite")
    ("Brazilian Portuguese" . "http://psysh.org/manual/pt_BR/php_manual.sqlite")
    ("Chinese (Simplified)" . "http://psysh.org/manual/zh/php_manual.sqlite")
    ("French" . "http://psysh.org/manual/fr/php_manual.sqlite")
    ("German" . "http://psysh.org/manual/de/php_manual.sqlite")
    ("Japanese" . "http://psysh.org/manual/ja/php_manual.sqlite")
    ("Romanian" . "http://psysh.org/manual/ro/php_manual.sqlite")
    ("Russian" . "http://psysh.org/manual/ru/php_manual.sqlite")
    ("Spanish" . "http://psysh.org/manual/es/php_manual.sqlite")
    ("Turkish" . "http://psysh.org/manual/tr/php_manual.sqlite")))

(defvar psysh-doc--do-not-ask-install-php-manial nil)

;; PsySH REPL Mode functions
(defvar psysh-mode-map
  (let ((map (make-sparse-keymap)))
    ;;
    map))

(defvar psysh-mode-input-syntax-table
  (let ((syntax-table (make-syntax-table)))
    (c-populate-syntax-table syntax-table)
    (modify-syntax-entry ?$ "_" syntax-table)
    syntax-table)
  "Syntax table used for the comint input.")

(defvar psysh-mode-output-syntax-table
  (let ((syntax-table (make-syntax-table comint-mode-syntax-table)))
    (modify-syntax-entry ?' "." syntax-table)
    (modify-syntax-entry ?\" "." syntax-table)
    syntax-table)
  "Syntax table used for the outpyt from psysh.

Strings are turned into punctuation so that if they come
unbalanced they will not break the rest of the buffer.")

(defun psysh--output-filter-remove-syntax (&rest _ignore)
  "Place the `syntax-table' property on the psysh output.

See `psysh-mode-output-syntax-table'."
  (put-text-property (or (point-min)
                         (previous-single-property-change (point) 'field)) (point)
                     'syntax-table psysh-mode-output-syntax-table))

(define-derived-mode psysh-mode comint-mode "PsySH"
  "Major-mode for PsySH REPL."
  :syntax-table psysh-mode-input-syntax-table
  (when (featurep 'php-mode)
    (set (make-local-variable 'font-lock-defaults)
         '(php-font-lock-keywords nil nil)))
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  (add-hook 'comint-output-filter-functions 'psysh--output-filter-remove-syntax 'append 'local)
  (setq-local comint-process-echoes t)

  (let ((history-path (or psysh-history-file-path (f-join (psysh--config-dir-path) "psysh_history"))))
    (when (and psysh-inherit-history (file-regular-p history-path))
      (psysh--insertion-history-lines
       (psysh--load-history history-path (ring-size comint-input-ring))))))

(defvar psysh-comint-buffer-process
  nil
  "A list (buffer-name process) is arguments for `make-comint'.")
(make-variable-buffer-local 'psysh-comint-buffer-process)

(defvar psysh-mode-hook nil
  "List of functions to be executed on entry to `psysh-mode'.")

(defconst psysh--re-prompt "^>>> ")

(defun psysh--detect-buffer ()
  "Return tuple list, comint buffer name and program."
  (or psysh-comint-buffer-process
      '("psysh" "psysh")))

(defun psysh--make-process ()
  "Make a Comint process NAME in BUFFER, running PROGRAM."
  (apply 'make-comint (psysh--detect-buffer)))

(defun psysh--copy-variables-from-php-mode ()
  "Set ac-sources from php-mode."
  (when (fboundp 'php-mode)
    (let ((current-major-mode major-mode)
          (php-mode-ac-sources nil))
      (with-temp-buffer
        (php-mode)

        (when (boundp 'psysh-enable-eldoc)
          (setq psysh-enable-eldoc (and (boundp 'eldoc-mode) eldoc-mode)))

        (if (and (boundp 'auto-complete-mode)
                 auto-complete-mode
                 (boundp 'ac-sources))
            (progn
              (setq php-mode-ac-sources ac-sources)
              (funcall current-major-mode)
              (setq ac-sources (append ac-sources php-mode-ac-sources)))
          (funcall current-major-mode))))))

(defun psysh--enable-eldoc ()
  "Turn on php-eldoc."
  (when (fboundp 'php-eldoc-enable)
    (php-eldoc-enable)
    (eldoc-mode 1)))

(defun psysh-eval-region (begin end)
  "Evalute PHP code BEGIN to END."
  (interactive "r")
  (let ((buf (psysh--make-process)))
    (comint-send-region buf begin end)))

(defun psysh-restart ()
  "Restart PsySH process."
  (interactive)
  (when (eq major-mode 'psysh-mode)
    (delete-process (get-buffer-process (current-buffer)))
    (psysh)))


;; History
(defun psysh--config-dir-path ()
  "Return path to PsySH config dir."
  ;; TODO: maybe next version Emacs bundles xdg.el?
  (if (eq system-type 'windows-nt)
      (f-join (s-replace-all '(("\\" . "/"))
                             (or (getenv "APPDATA")
                                 (f-join (getenv "HOME") "AppData"))) "PsySH")
    (f-join (or (getenv "XDG_CONFIG_HOME")
                (f-join (getenv "HOME") ".config"))
            "psysh")))

(defun psysh--load-history (path n)
  "Load input history from PATH and return N elements."
  (with-temp-buffer
    (insert-file-contents-literally path)
    (goto-char (point-max))
    (reverse
     (cl-loop repeat n
              do (beginning-of-line)
              never (eq (point) (point-min))
              collect (buffer-substring-no-properties (point)
                                                      (save-excursion (end-of-line)
                                                                      (point)))
              do (forward-line -1)))))

(defun psysh--insertion-history-lines (history)
  "Insert `HISTORY' lines to `comint-input-ring'."
  (cl-loop for line in history
           unless (string= "" line)
           do (comint-add-to-input-history line)))


;; PsySH Doc Mode functions
(defvar psysh-doc-buffer-name "*psysh doc*")

(defcustom psysh-doc-buffer-color 'auto
  "Coloring PsySH buffer."
  :type '(choice (const :tag "Auto detect color mode." 'auto)
                 (const :tag "Use only PsySH original coloring." 'only-psysh)
                 (const :tag "Use only Emacs font-lock coloring." 'only-emacs)
                 (const :tag "Use multiple coloring mechanism." 'mixed)
                 (const :tag "No coloring." 'none)))

(defcustom psysh-doc-display-function #'view-buffer-other-window
  "Function to display PsySH doc buffer."
  :type '(function))

(defun psysh-doc--php-manual-user-local-path ()
  "Return list of path to PHP manual."
  (if (eq system-type 'windows-nt)
      (expand-file-name "PsySH/php_manual.sqlite" (getenv "APPDATA"))
    (expand-file-name "~/.local/share/psysh/php_manual.sqlite")))

(defun psysh-doc--installed-php-manual-path ()
  "Return non-NIL when PHP manual has been installed."
  (cl-loop for path in (list (psysh-doc--php-manual-user-local-path)
                             "/usr/local/share/psysh/php_manual.sqlite")
           if (file-exists-p path)
           return (prog1 path
                    (setq psysh-doc--do-not-ask-install-php-manial t))))

(defun psysh-doc--download-php-manual (url save-path)
  "Download PHP Manual database by `URL' to `SAVE-PATH'."
  (let ((dir (file-name-directory save-path)))
    (unless (file-directory-p dir)
      (mkdir dir t)))
  (php-runtime-expr
   (format "copy(%s, %s)"
           (php-runtime-quote-string url)
           (php-runtime-quote-string save-path)))
  (message "Download complete."))

(defun psysh-doc-install-php-manual (url)
  "Install PHP Manual database by `URL' to user local directory."
  (interactive
   (list (assoc-default
          (completing-read "Select language of PHP manual: "
                           psysh-doc-php-manual-language-url-alist)
          psysh-doc-php-manual-language-url-alist)))
  (psysh-doc--download-php-manual url (psysh-doc--php-manual-user-local-path)))

;;;###autoload
(defun psysh-doc-buffer (target &optional buf)
  "Execute PsySH Doc `TARGET' and Return PsySH buffer `BUF'."
  (if (null buf) (setq buf (get-buffer-create psysh-doc-buffer-name)))
  (with-current-buffer buf
    (read-only-mode -1)
    (erase-buffer)
    (insert "doc " target)
    (message "%s %s" (nth 1 (psysh--detect-buffer)) (buffer-substring (point-min) (point-max)))
    (apply 'call-process-region (point-min) (point-max) (nth 1 (psysh--detect-buffer)) t t nil
           (if (memq psysh-doc-buffer-color '(none only-emacs))
               '("--no-color")
             '("--color")))
    (unless (memq psysh-doc-buffer-color '(none only-emacs))
      (ansi-color-apply-on-region (point-min) (point-max)))
    (goto-char (point-min))
    (when (search-forward-regexp psysh--re-prompt nil t)
      (delete-region (point-min) (match-beginning 0)))
    (goto-char (point-max))
    (when (search-backward-regexp (concat psysh--re-prompt "$") nil t)
      (delete-region (match-beginning 0) (point-max)))
    (goto-char (point-min))
    (unless (eq major-mode 'psysh-doc-mode)
      (psysh-doc-mode)))
  buf)

;;;###autoload
(define-derived-mode psysh-doc-mode prog-mode "PsySH-doc"
  "Major mode for viewing PsySH Doc."
  (setq show-trailing-whitespace nil)
  (read-only-mode +1))

;;;###autoload
(defun psysh-doc-string (target)
  "Return string of PsySH Doc `TARGET'."
  (let ((psysh-doc-buffer-color nil))
    (with-current-buffer (psysh-doc-buffer target (current-buffer))
      (buffer-substring-no-properties (point-min) (point-max)))))

;;;###autoload
(defun psysh-doc (target)
  "Display PsySH doc `TARGET'."
  (interactive
   (list (read-string
          "Input class or function name: "
          (if (region-active-p)
              (buffer-substring-no-properties (region-beginning) (region-end))
            (thing-at-point 'symbol)))))
  (when (and psysh-doc-install-local-php-manual
             (not psysh-doc--do-not-ask-install-php-manial)
             (null (psysh-doc--installed-php-manual-path))
             (yes-or-no-p "PHP manual database has not been installed. Download it? "))
    (call-interactively #'psysh-doc-install-php-manual))
  (funcall psysh-doc-display-function (psysh-doc-buffer target)))


;; PsySH Command

;;;###autoload
(defun psysh ()
  "Run PsySH interactive shell."
  (interactive)
  (switch-to-buffer (psysh--make-process))

  (set (make-local-variable 'psysh-enable-eldoc) nil)
  (psysh--copy-variables-from-php-mode)

  (when (and (boundp 'psysh-enable-eldoc) psysh-enable-eldoc)
    (add-hook 'psysh-mode-hook #'psysh--enable-eldoc))

  (psysh-mode)
  (run-hooks 'psysh-mode-hook))
(put 'psysh 'interactive-only 'psysh-run)

;;;###autoload
(defun psysh-run (buffer-name process)
  "Run PsySH interactive-shell in `BUFFER-NAME' and `PROCESS'."
  (let ((psysh-comint-buffer-process (list buffer-name process)))
    (call-interactively 'psysh)))

(provide 'psysh)
;;; psysh.el ends here
