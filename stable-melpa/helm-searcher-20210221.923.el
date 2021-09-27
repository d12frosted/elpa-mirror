;;; helm-searcher.el --- Helm interface to use searcher  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  Shen, Jen-Chieh
;; Created date 2020-06-24 13:00:57

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Helm interface to use searcher.
;; Keyword: helm interface searcher search replace grep ag rg
;; Version: 0.2.5
;; Package-Version: 20210221.923
;; Package-Commit: 326b5777db284f1e24c4f94730834e4b1e2bb66c
;; Package-Requires: ((emacs "25.1") (helm "2.0") (searcher "0.1.8") (s "1.12.0") (f "0.20.0"))
;; URL: https://github.com/emacs-helm/helm-searcher

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
;; Helm interface to use searcher.
;;

;;; Code:

(require 'cl-lib)
(require 'helm)
(require 'helm-mode)
(require 'searcher)
(require 's)

(defgroup helm-searcher nil
  "Helm interface to use searcher."
  :prefix "helm-searcher-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/emacs-helm/helm-searcher"))

(defcustom helm-searcher-display-info 'position
  "Display option for file information."
  :type '(choice (const :tag "position" position)
                 (const :tag "line/column" line/column))
  :group 'helm-searcher)

(defcustom helm-searcher-separator ":"
  "Separator string for display."
  :type 'string
  :group 'helm-searcher)

(defconst helm-searcher--buffer-name "*helm-searcher*"
  "Buffer name when using `helm-searcher'.")

(defconst helm-searcher--prompt-format "[Searcher] %s: "
  "Prompt string when using `helm-searcher'.")

(defvar helm-searcher--target-buffer nil
  "Record down the current target buffer.")

(defvar helm-searcher--search-string ""
  "Record down the current search string.")

(defvar helm-searcher--replace-string ""
  "Record down the current replace string.")

(defvar helm-searcher--replace-candidates '()
  "Record down all the candidates for searching.")

;;; Util

(defun helm-searcher--project-path ()
  "Get the current project path."
  (cdr (project-current)))

(defconst helm-searcher--search-project-source
  (helm-build-sync-source
   "Searcher"
   :candidates (lambda () (helm-searcher--do-search-project helm-pattern))
   :action #'helm-searcher--do-search-complete-action
   :volatile t)
  "Source that uses for search in project.")

(defconst helm-searcher--search-file-source
  (helm-build-sync-source
   "Searcher"
   :candidates (lambda () (helm-searcher--do-search-file helm-pattern))
   :action #'helm-searcher--do-search-complete-action
   :volatile t)
  "Source that uses for search in file.")

(defconst helm-searcher--replace-project-source
  (helm-build-sync-source
   "Searcher"
   :candidates (lambda () (helm-searcher--do-search-project helm-pattern))
   :action #'helm-searcher--do-replace-matched-action
   :volatile t)
  "Source that uses for replace in project.")

(defconst helm-searcher--replace-file-source
  (helm-build-sync-source
   "Searcher"
   :candidates (lambda () (helm-searcher--do-search-file helm-pattern))
   :action #'helm-searcher--do-replace-matched-action
   :volatile t)
  "Source that uses for replace in file.")

(defconst helm-searcher--replace-complete-source
  (helm-build-sync-source
   "Searcher"
   :candidates (lambda () (helm-searcher--do-replace helm-pattern))
   :action #'helm-searcher--do-replace-complete-action
   :volatile t)
  "Source that uses for replace in for current all selected candidates.
This is uses by both replace in file and project.")

(defun helm-searcher--is-contain-list-string (in-list in-str)
  "Check if IN-STR contain in any string in the IN-LIST."
  (cl-some #'(lambda (lb-sub-str) (string-match-p (regexp-quote lb-sub-str) in-str)) in-list))

(defun helm-searcher--goto-line (ln)
  "Goto LN line number."
  (goto-char (point-min))
  (forward-line (1- ln)))

(defun helm-searcher--get-string-from-file (path)
  "Return PATH file content."
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

(defun helm-searcher--separator-string ()
  "Return the separator string with text properties."
  (propertize helm-searcher-separator 'face 'default))

(defun helm-searcher--propertize-line-string (ln-str input col)
  "Propertize the LN-STR with INPUT and column (COL)."
  (let ((sec1 (+ col (length input))))
    ;; TODO:
    ;; 1) Seems like this sometimes break for miscalculation?
    ;; 2) Maybe it breaks because of the non-ascii character?
    (ignore-errors
      (concat
       (substring ln-str 0 col)
       (propertize (substring ln-str col sec1) 'face 'helm-grep-match)
       (substring ln-str sec1 (length ln-str))))))

(defun helm-searcher--read-selection (selection)
  "Read SELECTION and return list of data (file, line, column)."
  (let ((buf-lst (buffer-list)) buf-name buf-regex sel-lst found)
    (setq found
          (cl-some (lambda (buf)
                     (setq buf-name (buffer-name buf)
                           buf-regex (format "^%s" (regexp-quote buf-name)))
                     (string-match-p buf-regex selection))
                   buf-lst))
    (setq selection (s-replace-regexp buf-regex "" selection)
          sel-lst (split-string selection helm-searcher-separator))
    (list (if found buf-name (nth 0 sel-lst)) (nth 1 sel-lst) (nth 2 sel-lst))))

(defun helm-searcher--candidate-to-plist (cand)
  "Convert CAND string to a plist data."
  (let* ((data (helm-searcher--read-selection cand))
         (file (nth 0 data)) ln-str
         pos ln col)
    (cl-case helm-searcher-display-info
      (position
       (setq pos (nth 1 data)
             ln-str (nth 2 data)))
      (line/column
       (setq ln (nth 1 data)
             col (nth 2 data)
             ln-str (nth 3 data))))
    (list :file file :string ln-str :start pos :line-number ln :column col)))

;;; Search

(defun helm-searcher--init ()
  "Initialize and get ready for searcher to search."
  (searcher-clean-cache))

(defun helm-searcher--do-search-complete-action (cand)
  "Do action with CAND."
  (let* ((project-dir (helm-searcher--project-path))
         (data (helm-searcher--candidate-to-plist cand))
         (file (plist-get data :file)) (filename (f-filename file))
         (pos (plist-get data :start))
         (ln (plist-get data :line-number))
         (col (plist-get data :column)))
    (when project-dir (setq file (f-join project-dir file)))
    (if (file-exists-p file) (find-file file) (switch-to-buffer filename))
    (cl-case helm-searcher-display-info
      (position
       (setq pos (string-to-number pos))
       (goto-char (1+ pos)))
      (line/column
       (setq ln (string-to-number ln) col (string-to-number col))
       (helm-searcher--goto-line ln)
       (move-to-column col)))))

(defun helm-searcher--do-search-input-action (input cands dir)
  "Do the search action by INPUT, CANDS and DIR."
  (let ((candidates '())
        (file nil) (ln-str nil) (pos nil) (ln nil) (col nil)
        (candidate ""))
    (setq helm-searcher--replace-candidates '())  ; Clean up.
    (dolist (item cands)
      (setq file (plist-get item :file)) (setq file (s-replace dir "" file))
      (progn  ; Resolve line string.
        (setq ln-str (plist-get item :string))
        (setq col (plist-get item :column))
        (setq ln-str (helm-searcher--propertize-line-string ln-str input col)))
      (progn  ; Resolve information.
        (setq pos (plist-get item :start)) (setq pos (number-to-string pos))
        (setq ln (plist-get item :line-number)) (setq ln (number-to-string ln))
        (setq col (number-to-string col)))
      (setq candidate
            (cl-case helm-searcher-display-info
              (position
               (concat (propertize file 'face 'helm-moccur-buffer)
                       (helm-searcher--separator-string)
                       (propertize pos 'face 'helm-grep-lineno)
                       (helm-searcher--separator-string)
                       ln-str))
              (line/column
               (concat (propertize file 'face 'helm-moccur-buffer)
                       (helm-searcher--separator-string)
                       (propertize ln 'face 'helm-grep-lineno)
                       (helm-searcher--separator-string)
                       (propertize col 'face 'helm-grep-lineno)
                       (helm-searcher--separator-string)
                       ln-str))))
      (push candidate candidates)
      ;; Record down all the candidates.
      (push (cons candidate item) helm-searcher--replace-candidates))
    candidates))

(defun helm-searcher--do-search-project (input)
  "Search for INPUT in project."
  (let ((project-dir (helm-searcher--project-path))
        (cands (searcher-search-in-project input)))
    (setq helm-searcher--search-string input)
    (helm-searcher--do-search-input-action input cands project-dir)))

(defun helm-searcher--do-search-file (input)
  "Search for INPUT in file."
  (let ((dir (f-slash (f-dirname helm-searcher--target-buffer)))
        (cands (searcher-search-in-file helm-searcher--target-buffer input)))
    (setq helm-searcher--search-string input)
    (helm-searcher--do-search-input-action input cands dir)))

;;;###autoload
(defun helm-searcher-search-project ()
  "Search through the project."
  (interactive)
  (helm-searcher--init)
  (helm :sources '(helm-searcher--search-project-source)
        :prompt (format helm-searcher--prompt-format "Search")
        :buffer helm-searcher--buffer-name))

;;;###autoload
(defun helm-searcher-search-file ()
  "Search through current file."
  (interactive)
  (helm-searcher--init)
  (let ((helm-searcher--target-buffer (or (buffer-file-name) (buffer-name))))
    (helm :sources '(helm-searcher--search-file-source)
          :prompt (format helm-searcher--prompt-format "Search")
          :buffer helm-searcher--buffer-name)))

;;; Replace

(defun helm-searcher--do-replace-complete-action (_cand)
  "Replace all recorded candidates."
  (let ((output-files '()))
    (dolist (cand helm-searcher--replace-candidates)
      (let* ((cand-plist (cdr cand))
             (file (plist-get cand-plist :file))
             (new-content nil))
        (unless (helm-searcher--is-contain-list-string output-files file)
          (push file output-files)
          (setq new-content (s-replace-regexp helm-searcher--search-string
                                              helm-searcher--replace-string
                                              (helm-searcher--get-string-from-file file)
                                              t))
          (write-region new-content nil file))))))

(defun helm-searcher--do-replace (input)
  "Update the candidates with INPUT in helm so the user can look at it."
  (setq helm-searcher--replace-string input)
  (let ((candidates '()))
    (dolist (cand helm-searcher--replace-candidates)
      (let* ((cand-str (car cand)) (cand-plist (cdr cand))
             (ln-str (plist-get cand-plist :string)))
        (setq cand
              (concat
               (substring cand-str 0 (- (length cand-str) (length ln-str)))
               (s-replace-regexp helm-searcher--search-string input ln-str t)))
        (push cand candidates)))
    (reverse candidates)))

(defun helm-searcher--do-replace-matched-action (_cand)
  "Get the new string input and replace all candidates."
  (helm :sources '(helm-searcher--replace-complete-source)
        :prompt (format helm-searcher--prompt-format
                        (format "Replace %s with" helm-searcher--search-string))
        :buffer helm-searcher--buffer-name))

;;;###autoload
(defun helm-searcher-replace-project ()
  "Search and replace string in project."
  (interactive)
  (helm-searcher--init)
  (helm :sources '(helm-searcher--replace-project-source)
        :prompt (format helm-searcher--prompt-format "Replace")
        :buffer helm-searcher--buffer-name))

;;;###autoload
(defun helm-searcher-replace-file ()
  "Search and replace string in file."
  (interactive)
  (helm-searcher--init)
  (let ((helm-searcher--target-buffer (or (buffer-file-name) (buffer-name))))
    (helm :sources '(helm-searcher--replace-file-source)
          :prompt (format helm-searcher--prompt-format "Replace")
          :buffer helm-searcher--buffer-name)))

(provide 'helm-searcher)
;;; helm-searcher.el ends here
