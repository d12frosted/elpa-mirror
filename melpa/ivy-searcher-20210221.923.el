;;; ivy-searcher.el --- Ivy interface to use searcher  -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021  Shen, Jen-Chieh
;; Created date 2020-06-19 22:30:03

;; Author: Shen, Jen-Chieh <jcs090218@gmail.com>
;; Description: Ivy interface to use searcher.
;; Keyword: ivy interface searcher search replace grep ag rg
;; Version: 0.3.10
;; Package-Version: 20210221.923
;; Package-Commit: 0e8280ef40814eab1065d442146fe81ab1fc6149
;; Package-Requires: ((emacs "25.1") (ivy "0.8.0") (searcher "0.1.8") (s "1.12.0") (f "0.20.0"))
;; URL: https://github.com/jcs-elpa/ivy-searcher

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
;; Ivy interface to use searcher.
;;

;;; Code:

(require 'cl-lib)
(require 'ivy)
(require 'searcher)
(require 's)

(defgroup ivy-searcher nil
  "Ivy interface to use searcher."
  :prefix "ivy-searcher-"
  :group 'tool
  :link '(url-link :tag "Repository" "https://github.com/jcs-elpa/ivy-searcher"))

(defcustom ivy-searcher-display-info 'position
  "Display option for file information."
  :type '(choice (const :tag "position" position)
                 (const :tag "line/column" line/column))
  :group 'ivy-searcher)

(defcustom ivy-searcher-separator ":"
  "Separator string for display."
  :type 'string
  :group 'ivy-searcher)

(defcustom ivy-searcher-default-input ""
  "Default initial input for searcher."
  :type 'string
  :group 'ivy-searcher)

(defcustom ivy-searcher-preselect nil
  "Preselect option."
  :type '(choice (const :tag "none" nil)
                 (const :tag "previous search candidate" previous)
                 (const :tag "next search candidate" next))
  :group 'ivy-searcher)

(defconst ivy-searcher--prompt-format "[Searcher] %s: "
  "Prompt string when using `ivy-searcher'.")

(defvar ivy-searcher--initial-input nil
  "Current initial input for searcher.")

(defvar ivy-searcher--last-input nil
  "Record down the last input for preselecting behaviour.")

(defvar ivy-searcher--target-buffer nil
  "Record down the current target buffer.")

(defvar ivy-searcher--search-string ""
  "Record down the current search string.")

(defvar ivy-searcher--replace-string ""
  "Record down the current replace string.")

(defvar ivy-searcher--candidates '()
  "Record down all the candidates for searching.")

(defvar ivy-searcher--buffer-info '()
  "List of data about the current winodw buffer.")

(defvar ivy-searcher--current-dir ""
  "Record the current search directory in order to find respect relative path.")

;;; Util

(defun ivy-searcher--project-path ()
  "Get the current project path."
  (cdr (project-current)))

(defun ivy-searcher--is-contain-list-string (in-list in-str)
  "Check if IN-STR contain in any string in the IN-LIST."
  (cl-some (lambda (lb-sub-str) (string-match-p (regexp-quote lb-sub-str) in-str)) in-list))

(defun ivy-searcher--goto-line (ln)
  "Goto LN line number."
  (goto-char (point-min))
  (forward-line (1- ln)))

(defun ivy-searcher--get-string-from-file (path)
  "Return PATH file content."
  (with-temp-buffer
    (insert-file-contents path)
    (buffer-string)))

(defun ivy-searcher--separator-string ()
  "Return the separator string with text properties."
  (propertize ivy-searcher-separator 'face 'default))

(defun ivy-searcher--propertize-line-string (ln-str input col)
  "Propertize the LN-STR with INPUT and column (COL)."
  (let ((sec1 (+ col (length input))))
    ;; TODO:
    ;; 1) Seems like this sometimes break for miscalculation?
    ;; 2) Maybe it breaks because of the non-ascii character?
    (ignore-errors
      (concat
       (substring ln-str 0 col)
       (propertize (substring ln-str col sec1) 'face 'ivy-highlight-face)
       (substring ln-str sec1 (length ln-str))))))

(defun ivy-searcher--read-selection (selection)
  "Read SELECTION and return list of data (file, line, column)."
  (let ((buf-lst (buffer-list)) buf-name buf-regex sel-lst found)
    (setq found
          (cl-some (lambda (buf)
                     (setq buf-name (buffer-name buf)
                           buf-regex (format "^%s" (regexp-quote buf-name)))
                     (string-match-p buf-regex selection))
                   buf-lst))
    (setq selection (s-replace-regexp buf-regex "" selection)
          sel-lst (split-string selection ivy-searcher-separator))
    (list (if found buf-name (nth 0 sel-lst)) (nth 1 sel-lst) (nth 2 sel-lst))))

(defun ivy-searcher--candidate-to-plist (cand)
  "Convert CAND string to a plist data."
  (let* ((data (ivy-searcher--read-selection cand))
         (file (nth 0 data)) ln-str
         pos ln col)
    (cl-case ivy-searcher-display-info
      (position
       (setq pos (nth 1 data)
             ln-str (nth 2 data)))
      (line/column
       (setq ln (nth 1 data)
             col (nth 2 data)
             ln-str (nth 3 data))))
    (list :file file :string ln-str :start pos :line-number ln :column col)))

(defun ivy-searcher--initial-input-or-region ()
  "Return the default initiali input depend if region is active or not."
  (if (use-region-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    ivy-searcher-default-input))

;;; Search

(defun ivy-searcher--delay-display ()
  "Delay display a bit so the preselect can get updated."
  (let ((ivy-dynamic-exhibit-delay-ms 0.1)) (ivy--queue-exhibit)))

(defun ivy-searcher--search-preselect ()
  "Preselect the candidate depends on `ivy-searcher-preselect' option."
  (when (and ivy-searcher-preselect
             (not (string= ivy-searcher--last-input ivy-text)))
    (setq ivy-searcher--last-input ivy-text)  ; Record last input.
    (let ((pre-file (plist-get ivy-searcher--buffer-info :file))
          (pre-pos (plist-get ivy-searcher--buffer-info :start))
          (pre-ln (plist-get ivy-searcher--buffer-info :line-number))
          (pre-col (plist-get ivy-searcher--buffer-info :column))
          select-index
          (del-val (if (eq ivy-searcher-preselect 'previous) -1 0)))
      (setq select-index
            (cl-position
             nil ivy-searcher--candidates
             :test
             (lambda (_key cand)
               (let* ((cand-plist (cdr cand))
                      (cand-file (plist-get cand-plist :file))
                      (cand-pos (plist-get cand-plist :start))
                      (cand-ln (plist-get cand-plist :line-number))
                      (cand-col (plist-get cand-plist :column)))
                 (when (string= cand-file pre-file)
                   (cl-case ivy-searcher-display-info
                     (position (<= pre-pos cand-pos))
                     (line/column (or (< pre-ln cand-ln)
                                      (and (<= pre-ln cand-ln)
                                           (< pre-col cand-col))))))))))
      (if select-index
          ;; Use `max' to prevent it goes lower than 0.
          (ivy-set-index (max (+ select-index del-val) 0))
        (ivy-set-index 0))
      (ivy-searcher--delay-display))))

(defun ivy-searcher--init ()
  "Initialize and get ready for searcher to search."
  (searcher-clean-cache)
  (setq ivy-searcher--buffer-info (list :file (or (buffer-file-name) (buffer-name))
                                        :start (point)
                                        :line-number (line-number-at-pos)
                                        :column (1- (current-column)))))

(defun ivy-searcher--do-search-complete-action (cand)
  "Do action with CAND."
  (let* ((data (ivy-searcher--candidate-to-plist cand))
         (file (plist-get data :file)) (filename (f-filename file))
         (pos (plist-get data :start))
         (ln (plist-get data :line-number))
         (col (plist-get data :column)))
    (setq file (f-join ivy-searcher--current-dir file))
    (if (file-exists-p file) (find-file file) (switch-to-buffer filename))
    (cl-case ivy-searcher-display-info
      (position
       (setq pos (string-to-number pos))
       (goto-char (1+ pos)))
      (line/column
       (setq ln (string-to-number ln)
             col (string-to-number col))
       (ivy-searcher--goto-line ln)
       (move-to-column col)))))

(defun ivy-searcher--do-search-input-action (input cands dir)
  "Do the search action by INPUT, CANDS and DIR."
  (let ((candidates '()) (candidate "") file ln-str pos ln col)
    (setq ivy-searcher--current-dir dir)
    (setq ivy-searcher--candidates '())  ; Clean up.
    (dolist (item cands)
      (setq file (plist-get item :file)) (setq file (s-replace dir "" file))
      (progn  ; Resolve line string.
        (setq ln-str (plist-get item :string))
        (setq col (plist-get item :column))
        (setq ln-str (ivy-searcher--propertize-line-string ln-str input col)))
      (progn  ; Resolve information.
        (setq pos (plist-get item :start)) (setq pos (number-to-string pos))
        (setq ln (plist-get item :line-number)) (setq ln (number-to-string ln))
        (setq col (number-to-string col)))
      (setq candidate
            (cl-case ivy-searcher-display-info
              (position
               (concat (propertize file 'face 'ivy-grep-info)
                       (ivy-searcher--separator-string)
                       (propertize pos 'face 'ivy-grep-line-number)
                       (ivy-searcher--separator-string)
                       ln-str))
              (line/column
               (concat (propertize file 'face 'ivy-grep-info)
                       (ivy-searcher--separator-string)
                       (propertize ln 'face 'ivy-grep-line-number)
                       (ivy-searcher--separator-string)
                       (propertize col 'face 'ivy-grep-line-number)
                       (ivy-searcher--separator-string)
                       ln-str))))
      (push candidate candidates)
      ;; Record down all the candidates.
      (push (cons candidate item) ivy-searcher--candidates))
    candidates))

(defun ivy-searcher--do-search-project (input)
  "Search for INPUT in project."
  (let ((project-dir (ivy-searcher--project-path))
        (cands (searcher-search-in-project input)))
    (setq ivy-searcher--search-string input)
    (ivy-searcher--do-search-input-action input cands project-dir)))

(defun ivy-searcher--do-search-file (input)
  "Search for INPUT in file."
  (let ((dir (f-slash (f-dirname ivy-searcher--target-buffer)))
        (cands (searcher-search-in-file ivy-searcher--target-buffer input)))
    (setq ivy-searcher--search-string input)
    (ivy-searcher--do-search-input-action input cands dir)))

;;;###autoload
(defun ivy-searcher-search-project ()
  "Search through the project."
  (interactive)
  (ivy-searcher--init)
  (let ((ivy-searcher--initial-input (ivy-searcher--initial-input-or-region)))
    (ivy-read (format ivy-searcher--prompt-format "Search")
              #'ivy-searcher--do-search-project
              :initial-input ivy-searcher--initial-input
              :dynamic-collection t
              :require-match t
              :update-fn #'ivy-searcher--search-preselect
              :action #'ivy-searcher--do-search-complete-action)))

;;;###autoload
(defun ivy-searcher-search-file ()
  "Search through current file."
  (interactive)
  (ivy-searcher--init)
  (let ((ivy-searcher--initial-input (ivy-searcher--initial-input-or-region))
        (ivy-searcher--target-buffer (or (buffer-file-name) (buffer-name))))
    (ivy-read (format ivy-searcher--prompt-format "Search")
              #'ivy-searcher--do-search-file
              :initial-input ivy-searcher--initial-input
              :dynamic-collection t
              :require-match t
              :update-fn #'ivy-searcher--search-preselect
              :action #'ivy-searcher--do-search-complete-action)))

;;; Replace

(defun ivy-searcher--do-replace-complete-action (_cand)
  "Replace all recorded candidates."
  (let ((output-files '()))
    (dolist (cand ivy-searcher--candidates)
      (let* ((cand-plist (cdr cand))
             (file (plist-get cand-plist :file))
             (new-content nil))
        (unless (ivy-searcher--is-contain-list-string output-files file)
          (push file output-files)
          (setq new-content (s-replace-regexp ivy-searcher--search-string
                                              ivy-searcher--replace-string
                                              (ivy-searcher--get-string-from-file file)
                                              t))
          (write-region new-content nil file))))))

(defun ivy-searcher--do-replace (input)
  "Update the candidates with INPUT in ivy so the user can look at it."
  (setq ivy-searcher--replace-string input)
  (let ((candidates '()))
    (dolist (cand ivy-searcher--candidates)
      (let* ((cand-str (car cand)) (cand-plist (cdr cand))
             (ln-str (plist-get cand-plist :string)))
        (setq cand
              (concat
               (substring cand-str 0 (- (length cand-str) (length ln-str)))
               (s-replace-regexp ivy-searcher--search-string input ln-str t)))
        (push cand candidates)))
    (reverse candidates)))

(defun ivy-searcher--do-replace-matched-action (_cand)
  "Get the new string input and replace all candidates."
  (ivy-read (format ivy-searcher--prompt-format
                    (format "Replace %s with" ivy-searcher--search-string))
            #'ivy-searcher--do-replace
            :dynamic-collection t
            :require-match t
            :update-fn #'ivy-searcher--search-preselect
            :action #'ivy-searcher--do-replace-complete-action))

;;;###autoload
(defun ivy-searcher-replace-project ()
  "Search and replace string in project."
  (interactive)
  (ivy-searcher--init)
  (let ((ivy-searcher--initial-input (ivy-searcher--initial-input-or-region)))
    (ivy-read (format ivy-searcher--prompt-format "Replace")
              #'ivy-searcher--do-search-project
              :initial-input ivy-searcher--initial-input
              :dynamic-collection t
              :require-match t
              :update-fn #'ivy-searcher--search-preselect
              :action #'ivy-searcher--do-replace-matched-action)))

;;;###autoload
(defun ivy-searcher-replace-file ()
  "Search and replace string in file."
  (interactive)
  (ivy-searcher--init)
  (let ((ivy-searcher--initial-input (ivy-searcher--initial-input-or-region))
        (ivy-searcher--target-buffer (or (buffer-file-name) (buffer-name))))
    (ivy-read (format ivy-searcher--prompt-format "Replace")
              #'ivy-searcher--do-search-file
              :initial-input ivy-searcher--initial-input
              :dynamic-collection t
              :require-match t
              :update-fn #'ivy-searcher--search-preselect
              :action #'ivy-searcher--do-replace-matched-action)))

(provide 'ivy-searcher)
;;; ivy-searcher.el ends here
