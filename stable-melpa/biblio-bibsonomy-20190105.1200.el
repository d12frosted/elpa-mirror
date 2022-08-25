;;; biblio-bibsonomy.el --- Lookup bibliographic entries from Bibsonomy -*- lexical-binding: t -*-

;; Copyright (C) 2018 Andreas Jansson and contributors
;;
;; Author: Andreas Jansson and contributors
;; URL: http://github.com/andreasjansson/biblio-bibsonomy/
;; Package-Version: 20190105.1200
;; Package-Commit: fbdb3ecfcd88c179a2358d7967f7ecafef725835
;; Package-Requires: ((emacs "24.4") (biblio-core "0.2"))
;; Version: 1.0
;; Keywords: bib, tex, bibsonomy

;; This file is not part of GNU Emacs.

;;; License:

;; Licensed under the same terms as Emacs.

;;; Commentary:
;;
;; Lookup and download bibliographic records from Bibsonomy.
;;
;; Installation:
;;
;;   1. Install biblio-bibsonomy.el
;;   2. Create an account on www.bibsonomy.org
;;   3. In the Settings tab of the account page, find your API key under the API heading
;;   4. Set the following variables in your Emacs init file:
;;
;;      (require 'biblio-bibsonomy)
;;
;;      (setq
;;       biblio-bibsonomy-api-key "my-api-key"
;;       biblio-bibsonomy-username "my-user-name")
;;
;; Usage:
;;
;;   M-x biblio-lookup
;;
;; biblio-bibsonomy automatically adds itself as a biblio.el backend.

;;; Code:

(require 'subr-x)
(require 'biblio-core)
(require 'cl-lib)

(defgroup biblio-bibsonomy nil
  "Bibsonomy support in biblio.el"
  :group 'biblio)

(defcustom biblio-bibsonomy-username nil
  "Username for Bibsonomy API."
  :group 'biblio-bibsonomy
  :type 'string)

(defcustom biblio-bibsonomy-api-key nil
  "API key for Bibsonomy API."
  :group 'biblio-bibsonomy
  :type 'string)

(defconst biblio-bibsonomy--api-url-root "www.bibsonomy.org/api")

;;;###autoload
(defun biblio-bibsonomy-backend (command &optional arg &rest more)
  "A Bibsonomy backend for biblio.el.
COMMAND, ARG, MORE: See `biblio-backends'."
  (pcase command
    (`name "Bibsonomy")
    (`prompt "Bibsonomy query: ")
    (`url (biblio-bibsonomy--url arg))
    (`parse-buffer (biblio-bibsonomy--parse-search-results))
    (`forward-bibtex (biblio-bibsonomy--forward-bibtex arg (car more)))
    (`register (add-to-list 'biblio-backends #'biblio-bibsonomy-backend))))

(defun biblio-bibsonomy--url (query)
  "Create a Bibsonomy url to look up QUERY."
  (unless (and biblio-bibsonomy-username biblio-bibsonomy-api-key)
    (user-error "The variables `biblio-bibsonomy-username' and `biblio-bibsonomy-api-key' are not defined.\n\nDefine them with:\nM-x customize-group biblio-bibsonomy"))

  (format "https://%s:%s@%s/posts?resourcetype=bibtex&format=bibtex&search=%s"
          biblio-bibsonomy-username biblio-bibsonomy-api-key
          biblio-bibsonomy--api-url-root (url-encode-url query)))

(defun biblio-bibsonomy--intern-keys (alist)
  "Intern keys of ALIST into symbols."
  (mapcar #'(lambda (x) (cons (intern (car x)) (cdr x))) alist))

(defun biblio-bibsonomy--parse-entry ()
  "Parse a single bibtex entry and advance to the next line."
  (bibtex-set-dialect 'BibTeX t)
  (let ((start-point (point))
        (bibtex-string)
        (bibtex-expand-strings t)
        (bibtex-autokey-edit-before-use nil)
        (bibtex-entry-format (remove 'required-fields bibtex-entry-format))
        (bibtex-entry (bibtex-parse-entry t)))
    (when bibtex-entry
      (setq bibtex-string (buffer-substring-no-properties
                           start-point (1+ (point))))
      (forward-line)
      (let-alist (biblio-bibsonomy--intern-keys bibtex-entry)
        (list (cons 'doi .doi)
              (cons 'bibtex bibtex-string)
              (cons 'title (format "%s (%s)" .title .year))
              (cons 'authors (split-string .author " and "))
              (cons 'publisher .publisher)
              (cons 'container .journal)
              (cons 'type .=type=)
              (cons 'url .url)
              (cons 'direct-url .url))))))

(defun biblio-bibsonomy--error-if-remaining-text ()
  "Raise error if there is remaining text in the buffer.
Used after parsing all bibtex entries."
  (let ((remaining-text (buffer-substring-no-properties (point) (point-max))))
   (unless (string-blank-p remaining-text)
     (error "Bibsonomy returned error: %s" remaining-text))))

(defun biblio-bibsonomy--parse-search-results ()
  "Extract search results from Bibsonomy response."
  (biblio-decode-url-buffer 'utf-8)
  (cl-loop with entry
        do (setq entry (biblio-bibsonomy--parse-entry))
        when (not entry)
        return (or (biblio-bibsonomy--error-if-remaining-text) entries)
        collect entry into entries))

(defun biblio-bibsonomy--forward-bibtex (metadata forward-to)
  "Forward auto-formatted BibTeX for Bibsonomy entry METADATA to FORWARD-TO."
  (let-alist metadata
    (funcall forward-to (biblio-format-bibtex .bibtex t))))

;;;###autoload
(add-hook 'biblio-init-hook #'biblio-bibsonomy-backend)

;;;###autoload
(defun biblio-bibsonomy-lookup (&optional query)
  "Start a Bibsonomy search for QUERY, prompting if needed."
  (interactive)
  (biblio-lookup #'biblio-bibsonomy-backend query))

(provide 'biblio-bibsonomy)
;;; biblio-bibsonomy.el ends here
