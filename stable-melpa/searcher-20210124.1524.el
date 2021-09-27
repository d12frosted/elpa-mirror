;;; searcher.el --- Searcher in pure elisp  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  Shen, Jen-Chieh
;; Created date 2020-06-19 20:12:01

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Searcher in pure elisp
;; Keyword: search searcher project file text string
;; Version: 0.4.1
;; Package-Version: 20210124.1524
;; Package-Commit: 137c5791fb5a307192138a6d7c62340253bb4521
;; Package-Requires: ((emacs "25.1") (dash "2.10") (f "0.20.0"))
;; URL: https://github.com/jcs-elpa/searcher

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
;; Searcher in pure elisp
;;

;;; Code:

(require 'cl-lib)
(require 'dash)
(require 'f)
(require 'subr-x)

(defgroup searcher nil
  "Searcher in pure elisp."
  :prefix "searcher-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/searcher"))

(defcustom searcher-ignore-dirs
  '("/[.]log/"
    "/[.]vs/" "/[.]vscode/"
    "/[.]svn/" "/[.]git/" "/[.]hg/" "/[.]bzr/"
    "/[.]idea/"
    "/[.]tox/"
    "/[.]stack-work/"
    "/[.]ccls-cache/" "/[.]clangd/"
    "/[.]ensime_cache/" "/[.]eunit/" "/[.]fslckout/"
    "/[Bb]in/" "/[Bb]uild/" "/res/" "/[.]src/"
    "/SCCS/" "/RCS/" "/CVS/" "/MCVS/" "/_MTN/" "/_FOSSIL_/"
    "/_darcs/" "/{arch}/"
    "/node_modules/")
  "List of path you want to ignore by the searcher."
  :type 'list
  :group 'searcher)

(defcustom searcher-ignore-files
  '("[.]gitignore" "[.]gitattributes"
    "[.]meta" "[.]iso"
    "[.]img" "[.]png" "[.]jpg" "[.]jpng" "[.]gif"
    "[.]psd"
    "[.]obj" "[.]maya" "[.]fbx"
    "[.]mp3" "[.]wav"
    "[.]mp4"  "[.]avi" "[.]flv" "[.]mov" "[.]webm" "[.]mpg" "[.]mkv" "[.]wmv"
    "[.]exe" "[.]bin"
    "[.]elc" "[.]javac" "[.]pyc"
    "[.]lib" "[.]dll" "[.]o" "[.]a")
  "List of files you want to ignore by the searcher."
  :type 'list
  :group 'searcher)

(defcustom searcher-use-cache t
  "Use cache to speed up the search speed."
  :type 'boolean
  :group 'searcher)

(defcustom searcher-search-type 'regex
  "Type of the searching algorithm."
  :type '(choice (const :tag "regex" regex)
                 (const :tag "regex-fuzzy" regex-fuzzy)
                 (const :tag "flx" flx))
  :group 'searcher)

(defcustom searcher-flx-threshold 25
  "Target score we accept for outputting the search result."
  :type 'integer
  :group 'searcher)

(defvar searcher--cache-project-files nil
  "Cache for valid project files.
Do `searcher-clean-cache' if project tree strucutre has been changed.")

;;; External

(declare-function flx-score "ext:flx.el")

;;; Util

(defun searcher--is-contain-list-string-regexp (in-list in-str)
  "Check if IN-STR contain in any string in the IN-LIST."
  (cl-some (lambda (lb-sub-str) (string-match-p lb-sub-str in-str)) in-list))

(defun searcher--f-directories-ignore-directories (path &optional rec)
  "Find all directories in PATH by ignored common directories with FN and REC."
  (let ((dirs (f-directories path)) (valid-dirs '()) (final-dirs '()))
    (dolist (dir dirs)
      (unless (searcher--is-contain-list-string-regexp searcher-ignore-dirs (f-slash dir))
        (push dir valid-dirs)))
    (when rec
      (dolist (dir valid-dirs)
        (push (searcher--f-directories-ignore-directories dir rec) final-dirs)))
    (setq valid-dirs (reverse valid-dirs))
    (setq final-dirs (reverse final-dirs))
    (-flatten (append valid-dirs final-dirs))))

(defun searcher--f-files-ignore-directories (path &optional fn rec)
  "Find all files in PATH by ignored common directories with FN and REC."
  (let ((dirs (append (list path) (searcher--f-directories-ignore-directories path rec)))
        (files '()))
    (dolist (dir dirs) (push (f-files dir fn) files))
    (-flatten (reverse files))))

(defun searcher--line-string ()
  "Return string at line with current cursor position."
  (substring (buffer-string) (1- (line-beginning-position)) (1- (line-end-position))))

;;; Fuzzy

(defun searcher--trim-trailing-re (regex)
  "Trim incomplete REGEX.
If REGEX ends with \\|, trim it, since then it matches an empty string."
  (if (string-match "\\`\\(.*\\)[\\]|\\'" regex) (match-string 1 regex) regex))

(defun searcher--regex-fuzzy (str)
  "Build a regex sequence from STR.
Insert .* between each char."
  (setq str (searcher--trim-trailing-re str))
  (if (string-match "\\`\\(\\^?\\)\\(.*?\\)\\(\\$?\\)\\'" str)
      (concat (match-string 1 str)
              (let ((lst (string-to-list (match-string 2 str))))
                (apply #'concat
                       (cl-mapcar
                        #'concat
                        (cons "" (cdr (mapcar (lambda (c) (format "[^%c\n]*" c))
                                              lst)))
                        (mapcar (lambda (x) (format "\\(%s\\)" (regexp-quote (char-to-string x))))
                                lst))))
              (match-string 3 str))
    str))

;;; Core

(defun searcher--form-match (file ln-str start end ln col)
  "Form a match candidate; data are FILE, START, END and LN-STR."
  (list :file file :string ln-str :start start :end end :line-number ln :column col))

(defun searcher-clean-cache ()
  "Clean up the cache files."
  (setq searcher--cache-project-files nil))

(defun searcher--search-string (str-or-regex)
  "Return search string depends on `searcher-search-type' and STR-OR-REGEX."
  (cond ((or (eq searcher-search-type 'regex-fuzzy)
             (eq searcher-search-type 'flx))
         (searcher--regex-fuzzy str-or-regex))
        (t str-or-regex)))

(defun searcher--init ()
  "Initialize searcher."
  (cond ((eq searcher-search-type 'flx)
         (require 'flx))))

;;;###autoload
(defun searcher-search-in-project (str-or-regex)
  "Search STR-OR-REGEX from the root of project directory."
  (let ((project-path (cdr (project-current))))
    (if project-path
        (searcher-search-in-path project-path str-or-regex)
      (error "[ERROR] No project root folder found from default path"))))

;;;###autoload
(defun searcher-search-in-path (path str-or-regex)
  "Search STR-OR-REGEX from PATH."
  (let ((result '()))
    (when (or (not searcher--cache-project-files)
              (not searcher-use-cache))
      (setq searcher--cache-project-files
            (searcher--f-files-ignore-directories
             path
             (lambda (file)  ; Filter it.
               (not (searcher--is-contain-list-string-regexp searcher-ignore-files file)))
             t)))
    (dolist (file searcher--cache-project-files)
      (push (searcher-search-in-file file str-or-regex) result))
    (-flatten-n 1 result)))

;;;###autoload
(defun searcher-search-in-file (file str-or-regex)
  "Search STR-OR-REGEX in FILE."
  (searcher--init)
  (let ((matches '()) (ln 1) col (ln-pt 1) delta-ln start end push-it
        (real-regex str-or-regex))
    (setq str-or-regex (searcher--search-string str-or-regex))
    (unless (string-empty-p str-or-regex)
      (with-temp-buffer
        (if (file-exists-p file)
            (insert-file-contents file)
          (insert (with-current-buffer file (buffer-string))))
        (goto-char (point-min))
        ;; NOTE: We still need `ignore-errors' because it doesn't handle
        ;; invalid regular expression issue!
        (while (ignore-errors (search-forward-regexp str-or-regex nil t))
          (setq start (match-beginning 0) end (match-end 0))
          (setq col (save-excursion (goto-char start) (current-column))
                delta-ln (1- (count-lines ln-pt start))  ; Calculate lines.
                ;; Function `count-lines' missing 1 if column is at 0, so we
                ;; add 1 back to line if column is 0.
                ln (+ ln delta-ln (if (= col 0) 1 0))
                ln-pt start)
          (setq push-it
                (cond ((eq searcher-search-type 'flx)
                       (let* ((match-str (substring (buffer-string) (1- start) (1- end)))
                              (score-data (flx-score match-str real-regex))
                              (score (if score-data (nth 0 score-data) nil))
                              (good-score-p (if score (< searcher-flx-threshold score) nil)))
                         good-score-p))
                      (t t)))
          ;; Push if good.
          (when push-it
            (push (searcher--form-match file (searcher--line-string)
                                        start end ln col)
                  matches)
            (setq push-it nil)))))
    matches))

(provide 'searcher)
;;; searcher.el ends here
