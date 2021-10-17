;;; eshell-syntax-highlighting.el --- Highlight eshell commands  -*- lexical-binding:t -*-

;; Copyright (C) 2020 Alex Kreisher

;; Author: Alex Kreisher <akreisher18@gmail.com>
;; Version: 0.3
;; Package-Version: 20210429.413
;; Package-Commit: 8e3a685fc6d97af79e1046e5b24385786d8e92f6
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
  "Face used for directories in command position if ‘eshell-cd-on-directory’ is t"
  :group 'eshell-syntax-highlighting)

(defface eshell-syntax-highlighting-file-arg-face
         '((t :underline t))
  "Face used for command arguments which are existing files."
  :group 'eshell-syntax-highlighting)

(defun eshell-syntax-highlighting--goto-string-end (delim)
  "Find the end of a string delimited by DELIM."
  (unless
      (re-search-forward
	   ;; Ignore escaped delimiters.
       (concat "\\(\\`\\|[^\\\\]\\)" delim) nil t)
          (goto-char (point-max))))

(defun eshell-syntax-highlighting--highlight (beg end type)
  "Highlight word from BEG to END based on TYPE."
  (set-text-properties beg end nil nil)
  (let ((face
         (cl-case type
           ('default 'eshell-syntax-highlighting-default-face)
           ('command 'eshell-syntax-highlighting-shell-command-face)
           ('alias 'eshell-syntax-highlighting-alias-face)
           ('lisp 'eshell-syntax-highlighting-lisp-function-face)
           ('string 'eshell-syntax-highlighting-string-face)
           ('invalid 'eshell-syntax-highlighting-invalid-face)
           ('envvar 'eshell-syntax-highlighting-envvar-face)
           ('directory 'eshell-syntax-highlighting-directory-face)
           ('comment 'eshell-syntax-highlighting-comment-face)
           ('file-arg 'eshell-syntax-highlighting-file-arg-face)
           (t 'eshell-syntax-highlighting-default-face))))
    (add-face-text-property beg end face)))

(defun eshell-syntax-highlighting--highlight-elisp (beg)
  "Highlight Emacs Lisp starting at BEG natively through a temp buffer."
  (let* ((end (condition-case
                  nil (scan-sexps beg 1)
                ('scan-error (point-max))))
         (str (buffer-substring-no-properties beg end)))
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
    (goto-char end)))

(defun eshell-syntax-highlighting--parse-command (beg command)
  "Parse COMMAND starting at BEG and dispatch to highlighting and continued parsing."
  (cond

   ;; Command wrappers (sudo, time)
   ((string-match "^\\(\\*\\|eshell/\\)?\\(sudo\\|time\\)$" command)
    (eshell-syntax-highlighting--highlight
     beg (point)
     (if (and (match-string 1 command)
              (string-equal (match-string 1 command) "eshell/"))
         'lisp
       'command))
    (eshell-syntax-highlighting--parse-and-highlight 'command))

   ;; Executable file
   ((and (string-match-p ".*/.+" command)
         (file-regular-p command)
         (file-executable-p command))
        (eshell-syntax-highlighting--highlight beg (point) 'command)
        (eshell-syntax-highlighting--parse-and-highlight 'argument))

   ;; Explicit external command
   ((and (char-equal eshell-explicit-command-char (aref command 0))
         (executable-find (substring command 1 nil)))
    (eshell-syntax-highlighting--highlight beg (point) 'command)
    (eshell-syntax-highlighting--parse-and-highlight 'argument))

   ;; Eshell alias
   ((eshell-lookup-alias command)
    (eshell-syntax-highlighting--highlight beg (point) 'alias)
    (eshell-syntax-highlighting--parse-and-highlight 'argument))

   ;; Built-in
   ((functionp (intern (concat "eshell/" command)))
    (eshell-syntax-highlighting--highlight beg (point) 'command)
    (eshell-syntax-highlighting--parse-and-highlight 'argument))

   ;; Prioritized lisp function
   ((and eshell-prefer-lisp-functions
         (functionp (intern command)))
    (eshell-syntax-highlighting--highlight beg (point) 'lisp)
    (eshell-syntax-highlighting--parse-and-highlight 'argument))

   ;; Executable
   ((executable-find command)
    (eshell-syntax-highlighting--highlight beg (point) 'command)
    (eshell-syntax-highlighting--parse-and-highlight 'argument))

   ;; Lisp
   ((functionp (intern command))
    (eshell-syntax-highlighting--highlight beg (point) 'lisp)
    (eshell-syntax-highlighting--parse-and-highlight 'argument))

   ;; For loop
   ;; Disable highlighting from here on out
   ((string-equal "for" command)
    (eshell-syntax-highlighting--highlight beg (point-max) 'default))

   ;; Directory for cd
   ((and eshell-cd-on-directory
         (file-directory-p command))
    (eshell-syntax-highlighting--highlight beg (point) 'directory)
    (eshell-syntax-highlighting--parse-and-highlight 'argument))

   ;; Invalid command
   (t
    (eshell-syntax-highlighting--highlight beg (point) 'invalid)
    (eshell-syntax-highlighting--parse-and-highlight 'argument))))

(defun eshell-syntax-highlighting--parse-and-highlight (expected)
  "Parse and highlight from point, expecting token of type EXPECTED."

  ;; Whitespace
  (when (re-search-forward "\\s-*" nil t)
    (eshell-syntax-highlighting--highlight
     (match-beginning 0) (match-end 0) 'default))

  (let ((beg (point)))
    (cond
     ;; Exit at eol
     ((eolp) nil)

     ;; Comments
     ((looking-at "#")
      (eshell-syntax-highlighting--highlight beg (point-max) 'comment))

     ;; Line-wrapping backslash
     ((looking-at "\\\\\n")
      (goto-char (match-end 0))
      (eshell-syntax-highlighting--highlight beg (point) 'default)
      (eshell-syntax-highlighting--parse-and-highlight expected))

     ;; Delimiters
     ((looking-at "[&|;]")
      (goto-char (match-end 0))
      (if (eq 'expected 'command)
          (eshell-syntax-highlighting--highlight beg (point) 'invalid)
        (eshell-syntax-highlighting--highlight beg (point) 'default))
      (eshell-syntax-highlighting--parse-and-highlight 'command))

     ;; Commands
     ((eq expected 'command)
      (cond
       ;; Parenthesized Emacs Lisp
       ((looking-at-p "(")
        (eshell-syntax-highlighting--highlight-elisp beg)
        (eshell-syntax-highlighting--parse-and-highlight 'argument))

	   ;; Environment variabale
	   ((looking-at "[a-zA-Z0-9_]+=")
		(goto-char (match-end 0))
		(if (looking-at "[\"']")
			(eshell-syntax-highlighting--goto-string-end (match-string 0))
		  (re-search-forward "[^[:space:]&|;]*" (line-end-position)))
		(eshell-syntax-highlighting--highlight beg (point) 'envvar)
		(eshell-syntax-highlighting--parse-and-highlight 'command))

       ;; Command string
       (t
        (re-search-forward "[^[:space:]&|;]*" (line-end-position))
        (eshell-syntax-highlighting--parse-command beg (match-string-no-properties 0)))))

     (t
      (cond

       ;; Quoted string
       ((looking-at "[\"']")
		(eshell-syntax-highlighting--goto-string-end (match-string 0))
        (eshell-syntax-highlighting--highlight beg (point) 'string)
        (eshell-syntax-highlighting--parse-and-highlight 'argument))

       ;; Argument
       (t
        (search-forward-regexp "[^[:space:]&|;]*" (line-end-position))
        (eshell-syntax-highlighting--highlight
         beg (point) (cond
                      ((file-exists-p (match-string 0)) 'file-arg)
                      (t 'default)))
        (eshell-syntax-highlighting--parse-and-highlight 'argument)))))))


(defun eshell-syntax-highlighting--enable-highlighting ()
  "Parse and highlight the command at the last Eshell prompt."
  (when (and (eq major-mode 'eshell-mode)
             (not eshell-non-interactive-p)
             (not mark-active))
    (let ((beg (point))
          (non-essential t))
      (save-excursion
        (goto-char eshell-last-output-end)
        (forward-line 0)
        (when (re-search-forward eshell-prompt-regexp (line-end-position) t)
          (ignore-errors
            (eshell-syntax-highlighting--parse-and-highlight 'command))))
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
