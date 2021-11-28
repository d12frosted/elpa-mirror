;;; smart-compile.el --- an interface to `compile'

;; Copyright (C) 1998-2021  by Seiji Zenitani

;; Author: Seiji Zenitani <zenitani@gmail.com>
;; Version: 20211127
;; Package-Version: 20211127.1702
;; Package-Commit: df771e8cf0f7d5ed455c74bf7d9c1e366f47922f
;; Keywords: tools, unix
;; Created: 1998-12-27
;; Compatibility: Emacs 21 or later
;; URL(en): https://github.com/zenitani/elisp/blob/master/smart-compile.el
;; URL(jp): https://sci.nao.ac.jp/MEMBER/zenitani/elisp-j.html#smart-compile

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;; This package provides `smart-compile' function.
;; You can associate a particular file with a particular compile function,
;; by editing `smart-compile-alist'.
;; If you are using a build system such as make or cargo, you can associate its build system file with a
;; compile function as well, by editing `smart-compile-build-system-alist'.
;;
;; To use this package, add these lines to your .emacs file:
;;     (require 'smart-compile)
;;
;; Note that it requires emacs 21 or later.

;;; Code:

(defgroup smart-compile nil
  "An interface to `compile'."
  :group 'processes
  :prefix "smart-compile")

(defcustom smart-compile-alist '(
  (emacs-lisp-mode    . (emacs-lisp-byte-compile))
  (html-mode          . (browse-url-of-buffer))
  (nxhtml-mode        . (browse-url-of-buffer))
  (html-helper-mode   . (browse-url-of-buffer))
  (octave-mode        . (run-octave))
  ("\\.c\\'"          . "gcc -O2 %f -lm -o %n")
;;  ("\\.c\\'"          . "gcc -O2 %f -lm -o %n && ./%n") ;; unix, macOS
;;  ("\\.c\\'"          . "gcc -O2 %f -lm -o %n && %n") ;; win
  ("\\.[Cc]+[Pp]*\\'" . "g++ -O2 %f -lm -o %n")
  ("\\.cron\\(tab\\)?\\'" . "crontab %f")
  ("\\.cu\\'"         . "nvcc %f -o %n")
  ("\\.cuf\\'"        . "nvfortran -Mcuda -O2 %f -o %n")
  ("\\.[Ff]\\'"       . "gfortran %f -o %n")
  ("\\.[Ff]90\\'"     . "gfortran %f -o %n")
  ("\\.go\\'"         . "go run %f")
  ("\\.hs\\'"         . "ghc %f -o %n")
  ("\\.java\\'"       . "javac %f")
  ("\\.jl\\'"         . "julia %f")
  ("\\.lua\\'"        . "lua %f")
  ("\\.m\\'"          . "gcc -O2 %f -lobjc -lpthread -o %n")
  ("\\.mp\\'"         . "mptopdf %f")
  ("\\.php\\'"        . "php %f")
  ("\\.pl\\'"         . "perl %f")
  ("\\.p[l]?6\\'"     . "perl6 %f")
  ("\\.py\\'"         . "python3 %f")
  ("\\.raku\\'"       . "perl6 %f")
  ("\\.rb\\'"         . "ruby %f")
  ("\\.rs\\'"         . "rustc %f -o %n")
  ("\\.swift\\'"      . "swiftc %f -o %n")
  ("\\.tex\\'"        . (tex-file))
  ("\\.texi\\'"       . "makeinfo %f")
;;  ("\\.php\\'"        . "php -l %f") ; syntax check
;;  ("\\.pl\\'"         . "perl -cw %f") ; syntax check
;;  ("\\.rb\\'"         . "ruby -cw %f") ; syntax check
)  "Alist of filename patterns vs corresponding format control strings.
Each element looks like (REGEXP . STRING) or (MAJOR-MODE . STRING).
Visiting a file whose name matches REGEXP specifies STRING as the
format control string.  Instead of REGEXP, MAJOR-MODE can also be used.
The compilation command will be generated from STRING.
The following %-sequences will be replaced by:

  %F  absolute pathname            ( /usr/local/bin/netscape.bin )
  %f  file name without directory  ( netscape.bin )
  %n  file name without extension  ( netscape )
  %e  extension of file name       ( bin )

  %o  value of `smart-compile-option-string'  ( \"user-defined\" ).

If the second item of the alist element is an emacs-lisp FUNCTION,
evaluate FUNCTION instead of running a compilation command.
"
   :type '(repeat
           (cons
            (choice
             (regexp :tag "Filename pattern")
             (function :tag "Major-mode"))
            (choice
             (string :tag "Compilation command")
             (sexp :tag "Lisp expression"))))
   :group 'smart-compile)
(put 'smart-compile-alist 'risky-local-variable t)

(defvar smart-compile-build-root-directory nil
  "The directory that the current file path should be taken relative to.

This is usually the `default-directory', but if there's a \"build system\" (see
`smart-compile-build-system-alist'), it will be the directory that the current file path should be
taken relative to.")
(make-variable-buffer-local 'smart-compile-build-root-directory)

(defconst smart-compile-replace-alist '(
  ("%F" . (buffer-file-name))
  ("%f" . (file-relative-name
           (buffer-file-name)
           smart-compile-build-root-directory))
  ("%n" . (file-relative-name
           (file-name-sans-extension (buffer-file-name))
           smart-compile-build-root-directory))
  ("%e" . (or (file-name-extension (buffer-file-name)) ""))
  ("%o" . smart-compile-option-string)
;;   ("%U" . (user-login-name))
  )
  "Alist of %-sequences for format control strings in `smart-compile-alist'.")
(put 'smart-compile-replace-alist 'risky-local-variable t)

(defcustom smart-compile-make-program "make "
  "The command by which to invoke the make program."
  :type 'string
  :group 'smart-compile)

(defcustom smart-compile-build-system-alist
  '(("\\`[mM]akefile\\'" . smart-compile-make-program)
    ("\\`Gemfile\\'"     . "bundle install")
    ("\\`Rakefile\\'"    . "rake")
    ("\\`Cargo.toml\\'"  . "cargo build ")
    ("\\`pants\\'"       . "./pants %f"))
  "Alist of \"build system file\" patterns vs corresponding format control strings.

Similar to `smart-compile-alist', each element may look like (REGEXP . STRING) or
(REGEXP . SEXP).

If a \"build system file\" matching the regexp exists in any parent directory, the `compile-command'
first changes to the directory containing the build system file, and then the string or the sexp
result is used as the rest of the command.

NOTE: If the matching alist entry is a (REGEXP . STRING), then a similar sequence of %-sequence
replacements from `smart-compile-replace-alist' are applied to the string, but %f and %n are
relative to the \"build root\" directory containing the \"build system file\"."
  :type '(repeat
          (cons
           (regexp :tag "Build system filename pattern")
           (choice
            (string :tag "Compilation command")
            (sexp :tag "Lisp expression"))))
  :group 'smart-compile)
(put 'smart-compile-build-system-alist 'risky-local-variable t)

(defvar smart-compile-check-build-system t)
(make-variable-buffer-local 'smart-compile-check-build-system)

(defcustom smart-compile-option-string ""
  "The option string that replaces %o.  The default is empty."
  :type 'string
  :group 'smart-compile)

(defun smart-compile--is-root-directory (dir)
  "Taken from `ido-is-root-directory'."
  (or
   (string-equal "/" dir)
   (and (memq system-type '(windows-nt ms-dos))
        (string-match "\\`[a-zA-Z]:[/\\]\\'" dir))
   (string-match "\\`/[^:/][^:/]+:\\'" dir)))

(defun smart-compile--filter-files (paths)
  "Return a list with the members of PATHS that are regular files."
  (let ((ret nil))
    (dolist (path paths ret)
      (when (file-regular-p path)
        (push path ret)))))

(defun smart-compile--find-build-system-file (alist)
  "Find the ALIST entry with a matching regexp in any parent directory."
  (let ((cur-dir default-directory)
        (found-entry nil))
    (while (and (not found-entry)
                (not (smart-compile--is-root-directory cur-dir)))
      ;; Within each parent directory, loop over the alist and try matching each regexp.
      (let ((cur-alist alist))
        (while (and (not found-entry)
                    cur-alist)
          (let* ((regexp (caar cur-alist))
                 (build-system-files
                  (smart-compile--filter-files (directory-files cur-dir t regexp nil))))
            (if build-system-files
                (setq found-entry (cons (car build-system-files) (cdar cur-alist)))
              (setq cur-alist (cdr cur-alist))))))
      (setq cur-dir (expand-file-name ".." cur-dir)))
    found-entry))

(defun smart-compile--explicit-same-dir-filename (path)
  "Return a file path that always has a leading directory component."
  (if (file-name-directory path)
      path
    (format "./%s" path)))

;;;###autoload
(defun smart-compile (&optional arg)
  "An interface to `compile'.
It calls `compile' or other compile function,
which is defined in `smart-compile-alist'."
  (interactive "p")
  (let ((name (buffer-file-name))
        (not-yet t))

    (if (not name)(error "cannot get filename."))
;;     (message (number-to-string arg))

    ;; Set the "root" directory next to the file, for most cases.
    (setq smart-compile-build-root-directory default-directory)
    (cond

     ;; local command
     ;; The prefix 4 (C-u M-x smart-compile) skips this section
     ;; in order to re-generate the compile-command
     ((and (not (= arg 4)) ; C-u M-x smart-compile
           (local-variable-p 'compile-command)
           compile-command)
      (call-interactively 'compile)
      (setq not-yet nil)
      )

     ;; make? or other build systems?
     (smart-compile-check-build-system
      (let ((maybe-build-system-file
             (smart-compile--find-build-system-file smart-compile-build-system-alist)))
        (if maybe-build-system-file
            (let* ((build-system-file (expand-file-name (car maybe-build-system-file)))
                   (command-or-string-entry (cdr maybe-build-system-file))
                   (command-string
                    (if (stringp command-or-string-entry)
                        ;; Set the root directory as the one containing the "build system file".
                        (let ((smart-compile-build-root-directory
                               (file-name-directory build-system-file)))
                          (smart-compile-string command-or-string-entry))
                      (eval command-or-string-entry))))
              (if (y-or-n-p (format "%s is found. Try '%s'? "
                                    (smart-compile--explicit-same-dir-filename build-system-file)
                                    command-string))
                  ;; Same directory returns nil for `file-name-directory'.
                  (let ((default-directory (or (file-name-directory build-system-file)
                                               default-directory)))
                    (set (make-local-variable 'compile-command)
                         command-string)
                    (call-interactively 'compile)
                    (setq not-yet nil))
                (setq smart-compile-check-build-system nil))))
        ))
     ) ;; end of (cond ...)

    ;; compile
    (let( (alist smart-compile-alist)
          (case-fold-search nil)
          (function nil) )
      (while (and alist not-yet)
        (if (or
             (and (symbolp (caar alist))
                  (eq (caar alist) major-mode))
             (and (stringp (caar alist))
                  (string-match (caar alist) name))
             )
            (progn
              (setq function (cdar alist))
              (if (stringp function)
                  (progn
                    (set (make-local-variable 'compile-command)
                         (smart-compile-string function))
                    (call-interactively 'compile)
                    )
                (if (listp function)
                    (eval function)
                    ))
              (setq alist nil)
              (setq not-yet nil)
              )
          (setq alist (cdr alist)) )
        ))

    ;; If compile-command is not defined and the contents begins with "#!",
    ;; set compile-command to filename.
    (if (and not-yet
             (not (memq system-type '(windows-nt ms-dos)))
             (not (string-match "/\\.[^/]+$" name))
             (not
              (and (local-variable-p 'compile-command)
                   compile-command))
             )
        (save-restriction
          (widen)
          (if (equal "#!" (buffer-substring 1 (min 3 (point-max))))
              (set (make-local-variable 'compile-command) name)
            ))
      )

    ;; compile
    (if not-yet (call-interactively 'compile) )

    ))

(defun smart-compile-string (format-string)
  "Replace all the special format specifiers from `smart-compile-replace-alist' in FORMAT-STRING.

If `buffer-file-name' is not bound to a string, no replacements will be made."
  (if (and (boundp 'buffer-file-name)
           (stringp buffer-file-name))
      (let ((rlist smart-compile-replace-alist)
            (case-fold-search nil))
        (while rlist
          (while (string-match (caar rlist) format-string)
            (setq format-string
                  (replace-match
                   (eval (cdar rlist)) t nil format-string)))
          (setq rlist (cdr rlist))
          )
        ))
  format-string)

(provide 'smart-compile)

;;; smart-compile.el ends here
