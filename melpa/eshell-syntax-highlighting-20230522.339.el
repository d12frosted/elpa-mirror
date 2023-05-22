;;; eshell-syntax-highlighting.el --- Highlight eshell commands  -*- lexical-binding:t -*-

;; Copyright (C) 2020-2023 Alex Kreisher

;; Author: Alex Kreisher <akreisher18@gmail.com>
;; Version: 0.5
;; Package-Version: 20230522.339
;; Package-Commit: 29d5ca0e86da8a91e6889f34f687f41ea613e61f
;; Package-Requires: ((emacs "25.1"))
;; Keywords: convenience
;; URL: https://github.com/akreisher/eshell-syntax-highlighting

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
;;
;; Provides syntax highlighting for Eshell.
;;
;; Highlights commands as the user types to validate commands and syntax.
;;


;;; Code:

(eval-when-compile
  (require 'cl-lib)
  (require 'esh-mode)
  (require 'eshell)
  (require 'em-alias)
  (require 'em-dirs)
  (require 'em-prompt))

(require 'esh-util)
(require 'em-alias)


(defgroup eshell-syntax-highlighting nil
  "Faces used to highlight the syntax of Eshell commands."
  :tag "Eshell Syntax Highlighting"
  :group 'eshell)

(defcustom eshell-syntax-highlighting-highlight-elisp t
  "Whether to natively parse Emacs Lisp through a temporary buffer."
  :type 'boolean
  :group 'eshell-syntax-highlighting)


(defcustom eshell-syntax-highlighting-highlight-in-remote-dirs nil
  "Whether to perform syntax highlighting in remote directories."
  :type 'boolean
  :group 'eshell-syntax-highlighting)


(defface eshell-syntax-highlighting-default-face
         '((t :inherit default))
  "Default face for Eshell commands."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-envvar-face
         '((t :inherit font-lock-variable-name-face))
  "Face used for environment variables in an Eshell command."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-comment-face
         '((t :inherit font-lock-comment-face))
  "Face used for comments in an Eshell command."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-delimiter-face
         '((t :inherit default))
  "Face used for delimiters in an Eshell command."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-option-face
         '((t :inherit font-lock-constant-face))
  "Face used for options in an Eshell command."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-string-face
         '((t :inherit font-lock-string-face))
  "Face used for quoted strings in Eshell arguments."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-shell-command-face
         '((t :inherit success))
  "Face used for valid shell in an Eshell command."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-lisp-function-face
         '((t :inherit font-lock-function-name-face))
  "Face used for Emacs Lisp functions."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-alias-face
         '((t :inherit eshell-syntax-highlighting-shell-command-face))
  "Face used for Eshell aliases."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-invalid-face
         '((t :inherit error))
  "Face used for invalid Eshell commands."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-directory-face
         '((t :inherit font-lock-type-face))
  "Face used for directories in command position if ‘eshell-cd-on-directory’ is t."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-file-arg-face
         '((t :underline t))
  "Face used for command arguments which are existing files."
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-command-substitution-face
         '((t :inherit font-lock-escape-face))
  "Face for $ command substitution delimiters."
  :group 'eshell-syntax-highlighting)


(defvar eshell-syntax-highlighting--word-boundary-regexp "[^[:space:]&|;]*")

(defun eshell-syntax-highlighting--executable-find (command)
  "Check if COMMAND is on the variable `exec-path'."
  (if (< emacs-major-version 27)
      (executable-find command)
    (executable-find command t)))

(defun eshell-syntax-highlighting--find-unescaped (seq end)
  "Find first unescaped instance of SEQ before END."
  (if (looking-at (concat "\\(?:\\\\\\\\\\)*" seq))
      (when (<= (match-end 0) end)
        (goto-char (match-end 0))
        (point))
    (re-search-forward
     (concat "\\(\\([^\\\\]\\(\\\\\\\\\\)+\\|[^\\\\]\\)\\)" seq)
     end end)))

(defun eshell-syntax-highlighting--highlight (beg end type)
  "Highlight word from BEG to END based on TYPE."
  (set-text-properties beg end nil nil)
  (let ((face
         (cl-case type
           (default 'eshell-syntax-highlighting-default-face)
           (command 'eshell-syntax-highlighting-shell-command-face)
           (alias 'eshell-syntax-highlighting-alias-face)
           (lisp 'eshell-syntax-highlighting-lisp-function-face)
           (string 'eshell-syntax-highlighting-string-face)
           (invalid 'eshell-syntax-highlighting-invalid-face)
           (envvar 'eshell-syntax-highlighting-envvar-face)
           (directory 'eshell-syntax-highlighting-directory-face)
           (comment 'eshell-syntax-highlighting-comment-face)
           (delimiter 'eshell-syntax-highlighting-delimiter-face)
           (option 'eshell-syntax-highlighting-option-face)
           (file-arg 'eshell-syntax-highlighting-file-arg-face)
           (substitution 'eshell-syntax-highlighting-command-substitution-face)
           (t 'eshell-syntax-highlighting-default-face))))
    (add-face-text-property beg end face)))

(defun eshell-syntax-highlighting--highlight-elisp (beg end)
  "Highlight Emacs Lisp in region (BEG, END) natively through a temp buffer."
  (let* ((elisp-end (condition-case
                  nil (scan-sexps beg 1)
                (scan-error end)))
         (str (buffer-substring-no-properties beg elisp-end)))
    (if (not eshell-syntax-highlighting-highlight-elisp)
        (eshell-syntax-highlighting--highlight beg (point) 'default)
      (goto-char beg)
      (insert
       (with-temp-buffer
         (erase-buffer)
         (insert str)
         (delay-mode-hooks (emacs-lisp-mode))
         (font-lock-default-function 'emacs-lisp-mode)
         (font-lock-default-fontify-region (point-min) (point-max) nil)
         (buffer-string)))
      (delete-region (point) (+ (point) (length str))))
    (goto-char elisp-end)))

(defun eshell-syntax-highlighting--highlight-substitutions (beg end)
  "Find and highlight command substitutions in region (BEG, END)."
  (let ((curr-point (point)))
    (goto-char beg)
    (while (and (eshell-syntax-highlighting--find-unescaped "\\$" end) (< (point) end))
        (cond
         ((looking-at "{\\|<")
          ;; Command substitution
          (let* ((match-symbol (if (string-equal (match-string-no-properties 0) "{") "}" ">"))
                 (subs-start (+ (point) 1))
                 (subs-end (progn (eshell-syntax-highlighting--find-unescaped match-symbol end)
                                  (backward-char)
                                  (when (not (looking-at match-symbol))
                                    (forward-char))
                                  (point))))
            (goto-char subs-start)
            (eshell-syntax-highlighting--highlight (- subs-start 2) (point) 'substitution)
            (eshell-syntax-highlighting--parse-and-highlight 'command subs-end)
            (when (looking-at match-symbol)
              (forward-char)
              (eshell-syntax-highlighting--highlight (- (point) 1) (point) 'substitution))))
         ((looking-at "(")
          ;; Elisp substitution
          (eshell-syntax-highlighting--highlight (- (point) 1) (point) 'substitution)
          (eshell-syntax-highlighting--highlight-elisp (point) end))
         (t
          ;; Variable substitution
          (let ((start (- (point) 1)))
            (re-search-forward "[^[:space:]\\[&|;]*" end t)
            ;; Handle variable indexing
            (if (looking-at "\\[") (eshell-syntax-highlighting--find-unescaped "]" end))
            (eshell-syntax-highlighting--highlight start (point) 'envvar)))))
    (goto-char curr-point)))


(defun eshell-syntax-highlighting--highlight-filename (beg end)
  "Highlight argument file in region (BEG, END)."
  (re-search-forward eshell-syntax-highlighting--word-boundary-regexp (min end (line-end-position)))
  (eshell-syntax-highlighting--highlight
   beg (point)
   (cond
    ((file-exists-p (match-string 0)) 'file-arg)
    (t 'default))))

(defun eshell-syntax-highlighting--parse-command (beg end command)
  "Parse COMMAND in region (BEG, END) and highlight."
  (let ((next-expected
         (cond
          ;; Command wrappers (sudo, time)
          ((string-match "^\\(\\*\\|eshell/\\)?\\(sudo\\|time\\)$" command)
           (eshell-syntax-highlighting--highlight
            beg (point)
            (if (and (match-string 1 command)
                     (string-equal (match-string 1 command) "eshell/"))
                'lisp
              'command))
           'command)

          ;; Executable file
          ((and (string-match-p ".*/.+" command)
                (file-regular-p command)
                (file-executable-p command))
           (eshell-syntax-highlighting--highlight beg (point) 'command)
           'argument)

          ;; Explicit external command
          ((and (char-equal eshell-explicit-command-char (aref command 0))
                (eshell-syntax-highlighting--executable-find (substring command 1 nil)))
           (eshell-syntax-highlighting--highlight beg (point) 'command)
           'argument)

          ;; Eshell alias
          ((eshell-lookup-alias command)
           (eshell-syntax-highlighting--highlight beg (point) 'alias)
           'argument)

          ;; Built-in
          ((functionp (intern (concat "eshell/" command)))
           (eshell-syntax-highlighting--highlight beg (point) 'command)
           'argument)

          ;; Prioritized lisp function
          ((and eshell-prefer-lisp-functions
                (functionp (intern command)))
           (eshell-syntax-highlighting--highlight beg (point) 'lisp)
           'argument)

          ;; Executable
          ((eshell-syntax-highlighting--executable-find command)
           (eshell-syntax-highlighting--highlight beg (point) 'command)
           'argument)

          ;; Lisp
          ((functionp (intern command))
           (eshell-syntax-highlighting--highlight beg (point) 'lisp)
           'argument)

          ;; For loop
          ;; Disable highlighting from here on out
          ((string-equal "for" command)
           (eshell-syntax-highlighting--highlight beg end 'default)
           (goto-char end)
           'argument)

          ;; Directory for cd
          ((and eshell-cd-on-directory
                (file-directory-p command))
           (eshell-syntax-highlighting--highlight beg (point) 'directory)
           'argument)

          ;; Invalid command
          (t
           (eshell-syntax-highlighting--highlight beg (point) 'invalid)
           'argument))))
    (eshell-syntax-highlighting--highlight-substitutions beg end)
    (eshell-syntax-highlighting--parse-and-highlight next-expected end)))

(defun eshell-syntax-highlighting--parse-and-highlight (expected end)
  "Parse and highlight from point until END, expecting token of type EXPECTED."
  ;; Whitespace
  (when (re-search-forward "\\s-*" end t)
    (eshell-syntax-highlighting--highlight
     (match-beginning 0) (match-end 0) 'default))

  (let ((beg (point)))
    (cond
     ;; Exit at eol
     ((eolp) nil)
     ((>= beg end) nil)

     ;; Redirection
     ((and (looking-at ">") (eq expected 'argument))
      (re-search-forward ">+\\s-*" end t)
      (if (not (looking-at "#<"))
          ;; Redirect to normal file.
          (eshell-syntax-highlighting--highlight-filename (point) end)
        ;; Redirection to buffer #<buffer-name>.
        (eshell-syntax-highlighting--find-unescaped ">" end)
        (eshell-syntax-highlighting--highlight beg (point) 'default))
      (eshell-syntax-highlighting--parse-and-highlight 'argument end))

     ;; Comments
     ((looking-at "#")
      (eshell-syntax-highlighting--highlight beg end 'comment))

     ;; Options
     ((looking-at "-")
      (re-search-forward eshell-syntax-highlighting--word-boundary-regexp (min end (line-end-position)))
      (eshell-syntax-highlighting--highlight beg (point) 'option)
      (eshell-syntax-highlighting--highlight-substitutions beg end)
      (eshell-syntax-highlighting--parse-and-highlight expected end))

     ;; Line-wrapping backslash
     ((looking-at "\\\\\n")
      (goto-char (min end (match-end 0)))
      (eshell-syntax-highlighting--highlight beg (point) 'default)
      (eshell-syntax-highlighting--parse-and-highlight expected end))

     ;; Delimiters
     ((looking-at "\\(\\(|\\|&\\|;\\)+\\s-*\\)+")
      (goto-char (min end (match-end 0)))
      (if (eq expected 'command)
          (eshell-syntax-highlighting--highlight beg (point) 'invalid)
        (eshell-syntax-highlighting--highlight beg (point) 'delimiter))
      (eshell-syntax-highlighting--parse-and-highlight 'command end))


     ;; Commands
     ((eq expected 'command)
      (cond
       ;; Parenthesized Emacs Lisp
       ((looking-at-p "(")
        (eshell-syntax-highlighting--highlight-elisp beg end)
        (eshell-syntax-highlighting--parse-and-highlight 'argument end))

	   ;; Environment variable
	   ((looking-at "[[:alpha:]_][[:alnum:]_]*=")
        (goto-char (min end (match-end 0)))
		(if (looking-at "[\"']")
            (progn (when (< (point) end) (forward-char))
		           (eshell-syntax-highlighting--find-unescaped (match-string 0) end))
		  (re-search-forward eshell-syntax-highlighting--word-boundary-regexp (min end (line-end-position))))
		(eshell-syntax-highlighting--highlight beg (point) 'envvar)
        (eshell-syntax-highlighting--highlight-substitutions beg (point))
		(eshell-syntax-highlighting--parse-and-highlight 'command end))

       ;; Command string
       (t
        (re-search-forward eshell-syntax-highlighting--word-boundary-regexp (min end (line-end-position)))
        (eshell-syntax-highlighting--parse-command beg end (match-string-no-properties 0)))))

     (t
      (cond
       ;; Quoted string
       ((looking-at "[\"']")
        (when (<= (point) end) (forward-char))
		(eshell-syntax-highlighting--find-unescaped (match-string 0) end)
        (eshell-syntax-highlighting--highlight beg (point) 'string)
        (eshell-syntax-highlighting--highlight-substitutions beg (point))
        (eshell-syntax-highlighting--parse-and-highlight 'argument end))

       ;; Argument
       (t
        (eshell-syntax-highlighting--highlight-filename beg end)
        (eshell-syntax-highlighting--highlight-substitutions beg (point))
        (eshell-syntax-highlighting--parse-and-highlight 'argument end)))))))


(defun eshell-syntax-highlighting--enable-highlighting ()
  "Parse and highlight the command at the last Eshell prompt."
  (let ((beg (point))
        (non-essential t))
    (when (and (eq major-mode 'eshell-mode)
               (not eshell-non-interactive-p)
               (not mark-active)
               (or
                eshell-syntax-highlighting-highlight-in-remote-dirs
                (not (file-remote-p default-directory))))
      (with-silent-modifications
        (save-excursion
          (goto-char eshell-last-output-end)
          (forward-line 0)
          (when (re-search-forward eshell-prompt-regexp (line-end-position) t)
            (eshell-syntax-highlighting--parse-and-highlight 'command (point-max)))))
      ;; save-excursion marker is deleted when highlighting elisp,
      ;; so explicitly pop back to initial point.
      (goto-char beg))))


;;;###autoload
(define-minor-mode eshell-syntax-highlighting-mode
  "Toggle syntax highlighting for Eshell."
  :lighter nil
  :keymap nil
  (if (and eshell-syntax-highlighting-mode
           (eq major-mode 'eshell-mode)
           (not eshell-non-interactive-p))
      (add-hook 'post-command-hook
                #'eshell-syntax-highlighting--enable-highlighting nil t)
    (remove-hook 'post-command-hook
                 #'eshell-syntax-highlighting--enable-highlighting t)))

;;;###autoload
(define-globalized-minor-mode eshell-syntax-highlighting-global-mode
  eshell-syntax-highlighting-mode eshell-syntax-highlighting--global-on)

(defun eshell-syntax-highlighting--global-on ()
  "Enable eshell-syntax-highlighting only in appropriate buffers."
  (when (and (eq major-mode 'eshell-mode)
             (not eshell-non-interactive-p))
    (eshell-syntax-highlighting-mode +1)))

(provide 'eshell-syntax-highlighting)
;;; eshell-syntax-highlighting.el ends here
