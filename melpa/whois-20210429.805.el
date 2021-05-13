;;; whois.el --- Syntax highlighted domain name queries using system whois

;; Copyright 2019, 2020, 2021 Lassi Kortela
;; SPDX-License-Identifier: GPL-2.0-or-later

;; Author: Lassi Kortela <lassi@lassi.io>
;; URL: https://github.com/lassik/emacs-whois
;; Package-Version: 20210429.805
;; Package-Commit: 6ce65ec5c992b1e1cb538610f1c3708e9d467c39
;; Version: 0.3.0
;; Package-Requires: ((emacs "24"))
;; Keywords: network comm

;; This file is not part of GNU Emacs.

;;; Commentary:

;; This package complements (does not replace) the standard whois
;; functionality of GNU Emacs.  It provides:

;; * A `whois-mode' with font-lock highlighting to make whois
;;   responses easier to read.

;; * A `whois-shell' command to make a whois query using the system
;;   whois program instead of Emacs' own (often not up to date) whois
;;   client.

;; * A `whois-expand' command to repeat the last whois query using the
;;   domain registrar's own whois server.

;; To replace Emacs' own `whois' command with the one from this
;; package:

;; (when (require 'whois nil t) (defalias 'whois 'whois-shell))

;;; Code:

;; GNU Emacs defines the following variables and functions in
;; net-utils.el.  We will be careful not to step on any of them.

;; defcustom whois-guess-server
;; defcustom whois-reverse-lookup-server
;; defcustom whois-server-list
;; defcustom whois-server-name
;; defcustom whois-server-tld

;; defun whois
;; defun whois-get-tld
;; defun whois-reverse-lookup

(require 'net-utils)

(defconst whois-mode-syntax-table
  (let ((st (make-syntax-table)))
    ;; Treat double quotes as ordinary punctuation, not special string
    ;; delimiters for syntax highlighting.
    (modify-syntax-entry ?\" "." st)
    st))

(defconst whois-mode-font-lock-keywords
  `(;; Comment starting with one or more #;%* characters and space.
    ("^[#;%*]+\\(?: .*\\)?$"
     (0 font-lock-comment-face))
    ;; >>> Last update of whois database: ... <<<
    ("^>>> Last update.*?: \\(.*?\\) <<<$"
     (0 font-lock-type-face)
     (1 font-lock-preprocessor-face t))
    ;; Keyword: Value (special case for DNSSEC)
    ("^ *\\(DNSSEC\\.*:\\)\\(.*\\)$"
     (1 font-lock-type-face)
     (2 font-lock-function-name-face))
    ;; Keyword: Value (special case for Domain Name, Name Server, etc.)
    ("^ *\\(.*?Name.*?:\\|.*?Server.*?\\)\\(.*\\)$"
     (1 font-lock-type-face)
     (2 font-lock-function-name-face))
    ;; Keyword: Value (lowercase key......:, e.g. fi/se domains)
    ("^ *\\([a-z0-9 -]+\\.*:\\)\\(.*\\)$"
     (1 font-lock-type-face)
     (2 font-lock-string-face))
    ;; Keyword: Value (generic case)
    ("^ *\\([A-Z][A-Za-z0-9-/ ]+[a-z][A-Za-z0-9-/ ]+\\.*:\\)\\(.*\\)$"
     (1 font-lock-type-face)
     (2 font-lock-string-face))
    ;; Date and time in ISO format (yyyy-mm-ddThh:mm:ss). Optionally
    ;; followed by fractional seconds and/or timezone.
    (,(concat "[12][09][0-9][0-9]-[0-9][0-9]-[0-9][0-9]"
              "\\(?:[T ][0-2][0-9]:[0-5][0-9]:[0-6][0-9]"
              "\\(?:\\.[0-9]+\\)?"
              "\\(?: ?Z\\| ?[+-][0-9][0-9]:?[0-9][0-9]\\)?\\)?")
     (0 font-lock-preprocessor-face t))
    ;; Date and time in d.m.yyyy h:m:s format.
    (,(concat "[0-3]?[0-9]\\.[0-1]?[0-9]\\.[12][09][0-9][0-9] "
              "[0-2]?[0-9]:[0-5]?[0-9]:[0-6]?[0-9]")
     (0 font-lock-preprocessor-face t))
    ;; Email address (or other address using @ syntax)
    ("[A-Za-z0-9.+-]+@[A-Za-z0-9.-]+"
     (0 font-lock-variable-name-face t))
    ;; Web URL
    ("https?://[A-Za-z0-9.:/#?&=_+-]*"
     (0 font-lock-variable-name-face t))))

;;;###autoload
(define-derived-mode whois-mode special-mode "Whois"
  "Major mode for browsing WHOIS domain name registration records."
  :syntax-table whois-mode-syntax-table
  (setq buffer-read-only nil)
  (set (make-local-variable 'paragraph-separate) "[ \t]*$")
  (set (make-local-variable 'paragraph-start) "[ \t]*$")
  (set (make-local-variable 'font-lock-defaults)
       '((whois-mode-font-lock-keywords) nil nil ((?_ . "w")) nil)))

;;;###autoload
(defun whois-shell (query)
  "Run whois domain name query using external program.

QUERY is usually the domain name to search for (e.g.
\"gnu.org\"), but if you give some flags to the whois client then
it can mean something different. It's possible to give command
line options to the whois program by separating them with
spaces."
  (interactive "sWhois query (and command line options): ")
  (switch-to-buffer (get-buffer-create "*Whois*"))
  (unless (equal 'whois-mode major-mode)
    (whois-mode))
  (erase-buffer)
  (start-process-shell-command
   "whois" (current-buffer) (concat "whois " query)))

(defun whois-expand ()
  "Expand the whois information in the current buffer.

This command parses the domain name and the registrar's whois
server from the whois information in the current buffer. It then
does a query for the domain on that server (via `whois-shell').

Many domain registrars run their own whois server. Registrars'
servers typically give much more detailed information than the
generic whois servers where queries are sent by default.

Most of the time you'd want to run this from the *Whois* buffer,
in which case the information in that buffer will be expanded."
  (interactive)
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (let ((case-fold-search t) domain server)
        (unless (re-search-forward
                 "^ *domain.*?: +\\([a-z0-9.-]+\\)" nil t)
          (error "No domain name"))
        (setq domain (downcase (match-string 1)))
        (unless (re-search-forward
                 "registrar whois server: \\([a-z0-9.-]+\\)" nil t)
          (error "Registrar whois server not known"))
        (setq server (downcase (match-string 1)))
        (message "Looking up %s using %s..." domain server)
        (whois-shell (concat "-h " server " " domain))))))

(provide 'whois)

;;; whois.el ends here
