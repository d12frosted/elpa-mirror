;;; typo-suggest.el --- Don't make typos with the help of helm and company -*- lexical-binding: t -*-

;; Copyright (C) 2020  Kadir Can Çetin

;; Author: Kadir Can Çetin <kadircancetin@gmail.com>
;; Keywords: convenience, wp
;; Package-Version: 20200830.1143
;; Package-Commit: 3014d18ae2f0b6b857bb613f373e034c743f4d2e
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
(require 'google-translate nil t)
(require 'ivy nil t)


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


(defun typo-suggest--clear-tmp-buffers ()
  "Some tmp buffers witch may not killed because of helm."
  (--map (when (or (s-starts-with? " *http api.datamuse.com" (buffer-name it))
                   (s-starts-with? " *url-http-temp*" (buffer-name it)))
           (with-current-buffer it (kill-buffer)))
         (buffer-list)))

(defun typo-suggest--datamuse-fetch-results (query)
  "Fetching results from datamuse api and return as a string.
Argument QUERY is string which will searched."
  ;;(message "search: %s" query)
  (let ((results nil))

    (with-current-buffer
        (url-retrieve-synchronously
         (format "https://api.datamuse.com/sug?max=%s&s=%s"
                 typo-suggest-suggestion-count query)
         nil nil typo-suggest-timeout)
      (goto-char url-http-end-of-headers)
      (delete-region (point-min)(point))
      (setq results (buffer-string))
      (kill-buffer))


    results))

(defun typo-suggest--datamuse-results (query)
  "Gets json str, return parsed elisp obj.
It returns list of strings suggestion.  Argument QUERY is search
query."
  (let ((res (typo-suggest--datamuse-fetch-results query)))
    ;; (prin1 (nth 0 (mapcar #'cdr (mapcar #'car (json-read-from-string  res)))))
    (mapcar #'cdr (mapcar #'car (json-read-from-string  res)))))


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


(setq typo-suggest--helm-source
      (helm-build-sync-source "Typo Suggest"
        :candidates (lambda (&optional _) (typo-suggest--get-suggestion-list helm-input))
        :fuzzy-match nil
        :action '(("Insert or update" . typo-suggest--insert-or-replace-word)
                  ("Translate" . (lambda (x)
                                   (google-translate-translate
                                    google-translate-default-source-language
                                    google-translate-default-target-language x))))
        :volatile t
        :must-match t
        :match-dynamic t))

(defun typo-suggest--insert-or-replace-word(x)
  "Replace the word under the cursor with X parameter."
  (interactive)
  (save-excursion
    (when (thing-at-point 'word)
      (delete-region (beginning-of-thing 'word) (end-of-thing 'word)))
    (insert x))
  (forward-word)
  (typo-suggest--clear-tmp-buffers))

(defun typo-suggest--do-helm(input)
  "Starting helm suggestion with INPUT parameter."
  (helm :sources typo-suggest--helm-source
        :buffer "*Helm Typo Suggest*"
        :input input))

;;;###autoload
(defun typo-suggest-ivy()
  "Run typo suggest with ivy backend."
  (interactive)
  (let ((word (or (thing-at-point 'word)
                  "")))
    (ivy-read "" 'typo-suggest--get-suggestion-list
              :action 'typo-suggest--insert-or-replace-word
              :initial-input word
              :dynamic-collection t
              :unwind 'typo-suggest--clear-tmp-buffers)))

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
  (if typo-suggest-company-mode
      (progn
        (setq-local typo-suggest--saved-company-settings company-backends)
        (setq-local company-backends '(typo-suggest-company)))
    (setq-local company-backends typo-suggest--saved-company-settings)))


(provide 'typo-suggest)

;;; typo-suggest.el ends here
