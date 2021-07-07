;;; company-irony-c-headers.el --- Company mode backend for C/C++ header files with Irony

;; Copyright (C) 2015 Yutian Li

;; Author: Yutian Li <hotpxless@gmail.com>
;; Version: 1.0.0
;; Package-Version: 20151018.909
;; Package-Commit: 72c386aeb079fb261d9ec02e39211272f76bbd97
;; URL: https://github.com/hotpxl/company-irony-c-headers
;; Keywords: c company
;; Package-Requires: ((cl-lib "0.5") (company "0.9.0") (irony "0.2.0"))

;; This program is free software: you can redistribute it and/or modify
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

;; This file provides `company-irony-c-headers`, a company backend
;; that completes C/C++ header files. Large chunks of code are taken
;; from
;; [company-c-headers](https://github.com/randomphrase/company-c-headers). It
;; also works with `irony-mode` to obtain compiler options.

;; Usage:
;;    (require 'company-irony-c-headers)
;;    ;; Load with `irony-mode` as a grouped backend
;;    (eval-after-load 'company
;;      '(add-to-list
;;        'company-backends '(company-irony-c-headers company-irony)))

;; When compiler options change, call
;; `company-irony-c-headers-reload-compiler-output` manually to
;; reload.

;;; Code:

(require 'cl-lib)
(require 'company)
(require 'irony)

(defvar company-irony-c-headers--compiler-executable "clang++"
  "Compiler executable.")

(defun company-irony-c-headers--include-decl ()
  "Match include syntax."
  (rx
   line-start
   "#" (zero-or-more blank) "include"
   (one-or-more blank)
   (or (and "<" (submatch-n 1 (zero-or-more (not-char ?>))))
       (and "\"" (submatch-n 2 (zero-or-more (not-char ?\")))))))

(defvar company-irony-c-headers--modes
  '(c++-mode c-mode)
  "Mode supported.")

(defun company-irony-c-headers--lang ()
  "Get language."
  (irony--lang-compile-option))

(defun company-irony-c-headers--default-compiler-options ()
  "Get default compiler options to obtain include paths."
  (append (company-irony-c-headers--lang) '("-v" "-E" "-")))

(defun company-irony-c-headers--user-compiler-options ()
  "Get compiler options."
  irony--compile-options)

(defun company-irony-c-headers--working-dir ()
  "Get working directory."
  (if irony--working-directory
      (file-name-as-directory irony--working-directory)
    default-directory))

(defvar-local company-irony-c-headers--compiler-output nil
  "Compiler generated output for search paths.")

(defun company-irony-c-headers-reload-compiler-output ()
  "Call compiler to get search paths."
  (interactive)
  (when (and company-irony-c-headers--compiler-executable
             (company-irony-c-headers--working-dir))
    (setq
     company-irony-c-headers--compiler-output
     (let ((uco (company-irony-c-headers--user-compiler-options))
           (dco (company-irony-c-headers--default-compiler-options))
           (default-directory (company-irony-c-headers--working-dir)))
       (with-temp-buffer
             (apply 'call-process
                    company-irony-c-headers--compiler-executable nil t nil
                    (append
                     uco
                     dco))
             (goto-char (point-min))
             (let (quote-directories
                   angle-directories
                   (start "#include \"...\" search starts here:")
                   (second-start "#include <...> search starts here:")
                   (stop "End of search list."))
               (when (search-forward start nil t)
                 (forward-line 1)
                 (while (not (looking-at-p second-start))
                   ;; Skip whitespace at the begining of the line.
                   (skip-chars-forward "[:blank:]" (point-at-eol))
                   (let ((p
                          (replace-regexp-in-string
                           "\\s-+(framework directory)"
                           "" (buffer-substring (point) (point-at-eol)))))
                     (push p quote-directories))
                   (forward-line 1))
                 (forward-line 1)
                 (while (not (or (looking-at-p stop) (eolp)))
                   ;; Skip whitespace at the begining of the line.
                   (skip-chars-forward "[:blank:]" (point-at-eol))
                   (let ((p
                          (replace-regexp-in-string
                           "\\s-+(framework directory)"
                           "" (buffer-substring (point) (point-at-eol)))))
                     (push p quote-directories)
                     (push p angle-directories))
                   (forward-line 1)))
               (list
                (reverse quote-directories)
                (reverse angle-directories))))))))

(defun company-irony-c-headers--search-paths ()
  "Retrieve compiler search paths."
  (unless company-irony-c-headers--compiler-output
    (company-irony-c-headers-reload-compiler-output))
  company-irony-c-headers--compiler-output)

(defun company-irony-c-headers--resolve-paths (paths)
  "Resolve PATHS relative to working directory."
  (let ((working-dir (company-irony-c-headers--working-dir)))
    (mapcar
     (lambda (i)
       (file-name-as-directory
        (expand-file-name i working-dir))) paths)))

(defun company-irony-c-headers--resolved-search-paths (q)
  "Get resolved paths.  Q indicates whether it is quoted."
  (if q
      (let ((cur-dir
             (if (buffer-file-name)
                 (file-name-directory (buffer-file-name))
               (file-name-as-directory (expand-file-name "")))))
        (cons
         cur-dir
         (company-irony-c-headers--resolve-paths
          (nth 0 (company-irony-c-headers--search-paths)))
         ))
    (company-irony-c-headers--resolve-paths
     (nth 1 (company-irony-c-headers--search-paths)))))

(defun company-irony-c-headers--prefix ()
  "Find prefix for matching."
  (if (looking-back
       (company-irony-c-headers--include-decl) (line-beginning-position))
      (let ((match
             (if (match-string-no-properties 1)
                 (propertize (match-string-no-properties 1) 'quote nil)
               (if (match-string-no-properties 2)
                   (propertize (match-string-no-properties 2) 'quote t)))))
        (if (and (/= (length match) 0)
                 (= (aref match (1- (length match))) ?/))
            (cons match t)
          match))))

(defun company-irony-c-headers--candidates-for (prefix dir)
  "Return a list of candidates for PREFIX in directory DIR."
  (let* ((prefixdir (file-name-directory prefix))
         (subdir (if prefixdir
                     (expand-file-name prefixdir dir)
                   dir))
         (prefixfile (file-name-nondirectory prefix))
         candidates)
    ;; Remove "." and "..".
    (when (file-directory-p subdir)
      (setq candidates
            (cl-remove-if
             (lambda (f)
               (cl-member
                (directory-file-name f) '("." "..") :test 'equal))
             (file-name-all-completions prefixfile subdir)))
      ;; Sort candidates.
      (setq candidates (sort candidates #'string<))
      ;; Add property.
      (mapcar
       (lambda (c)
         (let ((real (if prefixdir
                         (concat prefixdir c)
                       c)))
           (propertize
            real
            'directory subdir))) candidates))))

(defun company-irony-c-headers--candidates (prefix)
  "Return candidates for PREFIX."
  (let* ((quoted (get-text-property 0 'quote prefix))
         (p (company-irony-c-headers--resolved-search-paths quoted))
         candidates)
    (mapc (lambda (i)
            (when (file-directory-p i)
              (setq
               candidates
               (append
                candidates
                (company-irony-c-headers--candidates-for prefix i)))
              ))
          p)
    (cl-delete-duplicates
     candidates
     :test 'string=
     :from-end t)))

(defun company-irony-c-headers--meta (candidate)
  "Return the metadata associated with CANDIDATE.  Just the directory."
  (get-text-property 0 'directory candidate))

(defun company-irony-c-headers--location (candidate)
  "Return the location associated with CANDIDATE."
  (cons (concat (file-name-as-directory (get-text-property 0 'directory candidate))
                (file-name-nondirectory candidate))
        1))

;;;###autoload
(defun company-irony-c-headers (command &optional arg &rest ignored)
  "Company backend for C/C++ header files.  Taking COMMAND ARG IGNORED."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'company-irony-c-headers))
    (prefix
     (if (member major-mode company-irony-c-headers--modes)
         (company-irony-c-headers--prefix)))
    (init (company-irony-c-headers-reload-compiler-output))
    (sorted t)
    (candidates (company-irony-c-headers--candidates arg))
    (location (company-irony-c-headers--location arg))
    (meta (company-irony-c-headers--meta arg))
    (post-completion
     ;; ARG here lost property. Need to rematch prefix.
     (let ((matched (company-irony-c-headers--prefix)))
       (if (consp matched)
           (setq matched (car matched)))
       (unless (equal matched (file-name-as-directory matched))
         (if (get-text-property 0 'quote matched)
             (if (looking-at "\"")
               (forward-char)
               (insert "\""))
           (if (looking-at ">")
             (forward-char)
             (insert ">"))))))))

(provide 'company-irony-c-headers)

;;; company-irony-c-headers.el ends here
