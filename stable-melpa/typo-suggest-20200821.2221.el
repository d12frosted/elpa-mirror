;;; typo-suggest.el --- Don't make typos with the help of helm and company -*- lexical-binding: t -*-

;; Copyright (C) 2020  Kadir Can Çetin

;; Author: Kadir Can Çetin <kadircancetin@gmail.com>
;; Keywords: convenience, wp
;; Package-Version: 20200821.2221
;; Package-Commit: 938fdad51d1177627ed9a34da6b937481861bda2
;; Package-Requires: ((emacs "24.3") (helm "3.0") (company "0.9.10") (s "1.12.0") (dash "2.13.0"))
;; URL: https://github.com/kadircancetin/typo-suggest
;; Version: 0.0.4

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
;;  This package is a datamuse api or Ispell backends for fixing typos, getting suggestions and
;;  finding the correct word with ~helm~ or ~company-mode~.
;;
;; This package relies on the third-party Datamuse's /sug API (doc: https://www.datamuse.com/api/)
;; if you select to use datamuse backend.  The API is free to use any usage and without API key has
;; a daily 100,000 requests per day limit.  You can contact us with any problem with
;; https://github.com/kadircancetin/typo-suggest.
;;
;; If you want to use Ispell (https://www.gnu.org/software/ispell/) , you have to installed on your
;; computer.

;;; Code:
(require 'cl-lib)
(require 'json)
(require 'thingatpt)
(require 'dash)
(require 'helm)
(require 'company)
(require 's)
;; (require 'google-translate)

(defgroup typo-suggest nil
  "Fix the typos"
  :group 'matching
  :group 'helm)

(defcustom typo-suggest-suggestion-count 20
  "Number of suggestions for 'helm and company completion."
  :type 'integer
  :group 'typo-suggest)

(defcustom typo-suggest-timeout 1
  "Number of seconds to try maximum server waiting time."
  :type 'integer
  :group 'typo-suggest)

(defcustom typo-suggest-default-search-method 'datamuse
  "Select the backend of completion.  `datamuse' or `ispell' are currently supported."
  :type 'symbol
  :group 'typo-suggest)


(defvar typo-suggest--saved-company-settings nil
  "Local value for `typo-suggest-company-mode' support.")


(defun typo-suggest--datamuse-fetch-results (query)
  "Fetching results from datamuse api and return as a string.
Argument QUERY is string which will searched."
  (with-current-buffer
      ;; TODO: show error or something to user if bigger than 'typo-suggest-timeout sec
      (url-retrieve-synchronously
       (format "https://api.datamuse.com/sug?max=%s&s=%s"
               typo-suggest-suggestion-count query)
       nil t typo-suggest-timeout)
    (goto-char (point-min))
    (re-search-forward "^$")
    (delete-region (point)(point-min))(buffer-string)))

(defun typo-suggest--datamuse-results (fetched-str)
  "Gets json str, return parsed elisp obj.
It returns list of strings suggestion.  Argument FETCHED-STR is
comes from `typo-suggest--datamuse-fetch-results'."
  (mapcar #'cdr (mapcar #'car (json-read-from-string  (typo-suggest--datamuse-fetch-results fetched-str)))))


(defun typo-suggest--ispell-filter-fixes-line (terminal-output word)
  "Filters Ispell's TERMINAL-OUTPUT with WORD wich if line is hasn't suggested any fix."
  (car (-filter
        (lambda (line)
          (when (s-contains? (format "& %s" word) line)
            t))
        (split-string terminal-output "\n"))))

(defun typo-suggest--parse-ispell-suggest(terminal-output word)
  "Parse Ispell's TERMINAL-OUTPUT and searched WORD.  It return suggested list."
  (let* ((line-fixes (typo-suggest--ispell-filter-fixes-line terminal-output word))
         (is-wrong? (s-contains? "#" (car (cdr (split-string terminal-output "\n"))))))

    (cond
     (line-fixes (-map 's-trim (split-string
                                (car (cdr (split-string line-fixes ":")))
                                ",")))
     (is-wrong? 'nil)
     (t (list word)))))

(defun typo-suggest--ispell-results (query)
  "Run Ispell commands, parse it and return suggested Ispell list corresponding the QUERY."
  (typo-suggest--parse-ispell-suggest
   (with-temp-buffer
     (insert query)
     (call-process-region 1 (point-max) "ispell" t t "*tmp*" "-a")
     (buffer-string))
   query))


(defun typo-suggest--get-suggestion-list(query)
  "Return suggested list corresponding QUERY and `typo-suggest-default-search-method'."
  (cond
   ((eq typo-suggest-default-search-method 'ispell) (typo-suggest--ispell-results query))
   ((eq typo-suggest-default-search-method 'datamuse) (typo-suggest--datamuse-results query))))


(defun typo-suggest--helm-insert-or-replace-word(x)
  "Replace the word under the cursor with X parameter."
  (interactive)
  (save-excursion
    (when (thing-at-point 'word)
      (delete-region (beginning-of-thing 'word) (end-of-thing 'word)))
    (insert x)))

(defun typo-suggest--do-helm(input)
  "Starting helm suggestion with INPUT parameter."
  (helm :sources
        (helm-build-sync-source "Typo Suggest"
          :candidates (lambda (&optional _) (typo-suggest--get-suggestion-list helm-input))
          :fuzzy-match nil
          :action '(("Insert or update" . typo-suggest--helm-insert-or-replace-word)
                    ;; TODO: make configurable google translate integration.
                    ;; ("Translate" . (lambda (x) (google-translate-translate "en" "tr" x)))
                    )

          :volatile t
          :must-match t
          ;; :nohighlight t
          :match-dynamic t)
        :buffer "*Helm Typo Suggest*"
        :input input))


;;;###autoload
(defun typo-suggest-helm()
  "Get word suggestion from datamuse api with helm."
  (interactive)
  (typo-suggest--do-helm (thing-at-point 'word)))


;;;###autoload
(defun typo-suggest-company (command &optional arg &rest _ignored)
  "Get word suggestion from datamuse api with company mode.
Argument COMMAND is used for company.
Optional argument ARG Is used from company to send which will search."
  (interactive (list 'interactive))
  (cl-case command
    (interactive (company-begin-backend 'typo-suggest-company))
    (prefix (company-grab-symbol))
    (candidates  (typo-suggest--get-suggestion-list arg))
    (no-cache t)
    (require-match nil)
    (meta (format "Word search %s" arg))))


;;;###autoload
(define-minor-mode typo-suggest-company-mode
  "Disable all company backends and enable typo-suggest-company or wise versa."
  :lighter "typo"
  ;; :keymap flycheck-mode-map
  (if typo-suggest-company-mode
      (progn
        (setq-local typo-suggest--saved-company-settings company-backends)
        (setq-local company-backends '(typo-suggest-company)))
    (setq-local company-backends typo-suggest--saved-company-settings)))


(provide 'typo-suggest)

;;; typo-suggest.el ends here
