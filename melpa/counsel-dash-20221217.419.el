;;; counsel-dash.el --- Browse dash docsets using Ivy -*- lexical-binding: t -*-

;; Copyright (C) 2016 Nathan Kot

;; Author: Nathan Kot <nk@nathankot.com>
;; Version: 0.1.3
;; Package-Version: 20221217.419
;; Package-Commit: 04117bffc8badd85c9f4fdb17648fd56e83fe832
;; Package-Requires: ((emacs "24.4") (dash-docs "1.4.0") (counsel "0.8.0") (cl-lib "0.5"))
;; Keywords: dash, ivy, counsel
;; URL: https://github.com/nathankot/counsel-dash
;;
;;; Commentary:
;; Provides counsel-dash, which is an ivy-mode interface for searching dash docsets.
;;
;; M-x counsel-dash
;; M-x counsel-dash-at-point
;;
;;; Code:

(require 'cl-lib)
(require 'subr-x)
(require 'dash-docs)
(require 'ivy)

(defgroup counsel-dash nil
  "Search Dash docsets using ivy"
  :prefix "counsel-dash"
  :group 'ivy)

; Aliases are used so that we can provide a common interface, irrespective of
; any library changes in the future.

(defvaralias 'counsel-dash-docsets-path 'dash-docs-docsets-path)
(defvaralias 'counsel-dash-docsets-url 'dash-docs-docsets-url)
(defvaralias 'counsel-dash-min-length 'dash-docs-min-length)
(defvaralias 'counsel-dash-candidate-format 'dash-docs-candidate-format)
(defvaralias 'counsel-dash-enable-debugging 'dash-docs-enable-debugging)
(defvaralias 'counsel-dash-browser-func 'dash-docs-browser-func)
(defvaralias 'counsel-dash-common-docsets 'dash-docs-common-docsets)
(defvaralias 'counsel-dash-ignored-docsets 'dash-docs-ignored-docsets)

(defalias 'counsel-dash-activate-docset 'dash-docs-activate-docset)
(defalias 'counsel-dash-deactivate-docset 'dash-docs-deactivate-docset)
(defalias 'counsel-dash-install-docset 'dash-docs-install-docset)
(defalias 'counsel-dash-install-docset-from-file 'dash-docs-install-docset-from-file)
(defalias 'counsel-dash-install-user-docset 'dash-docs-install-user-docset)
(defalias 'counsel-dash-reset-connections 'dash-docs-reset-connections)

(defvar counsel-dash-history-input nil
  "Input history used by `ivy-read'.")

(defvar counsel-dash--results nil
  "Stores the previously retrieved docset results.")

(defvar-local counsel-dash-docsets nil
  "Docsets to use for this buffer.")

(advice-add #'dash-docs-buffer-local-docsets :around
            (lambda (old-fun &rest args)
              (let ((old (apply old-fun args)))
                (cl-remove-duplicates (append old counsel-dash-docsets)))))

(defun counsel-dash--collection (s &rest _)
  "Given a string S, query docsets and retrieve result."
  (setq counsel-dash--results (dash-docs-search s))
  (mapcar 'car counsel-dash--results))

(defun counsel-dash--browse-matching-result (match)
  "Given a MATCH, find matching result and browse it's url."
  (when-let ((result
              (cdr (cl-find-if (lambda (e)
                                 (string= match (car e))) counsel-dash--results))))
    (dash-docs-browse-url result)))


;;; Autoloads

;;;###autoload
(defun counsel-dash (&optional initial)
  "Query dash docsets.
INITIAL will be used as the initial input, if given."
  (interactive)
  (dash-docs-initialize-debugging-buffer)
  (dash-docs-create-buffer-connections)
  (dash-docs-create-common-connections)
  (let ((cb (current-buffer)))
    (ivy-read "Documentation for: "
              #'(lambda (s &rest _) (with-current-buffer cb (counsel-dash--collection s)))
              :dynamic-collection t
              :history #'dash-docs-history-input
              :initial-input initial
              :action #'counsel-dash--browse-matching-result)))

;;;###autoload
(defun counsel-dash-at-point ()
  "Bring up a `counsel-dash' search interface with symbol at point."
  (interactive)
  (counsel-dash
   (substring-no-properties (or (thing-at-point 'symbol) ""))))

(provide 'counsel-dash)

;;; counsel-dash.el ends here
