;;; counsel-dash.el --- Browse dash docsets using Ivy -*- lexical-binding: t -*-

;; Copyright (C) 2016 Nathan Kot

;; Author: Nathan Kot <nk@nathankot.com>
;; Version: 0.1.3
;; Package-Version: 20160524.652
;; Package-Commit: a342340bbd8e50e4d1015e0b91d8ecd8f6cdf9f2
;; Package-Requires: ((emacs "24.4") (dash "2.12.1") (dash-functional "1.2.0") (helm-dash "1.3.0") (counsel "0.8.0"))
;; Keywords: dash, ivy, counsel
;; URL: https://github.com/nathankot/counsel-dash

;;; Commentary:

;; Provides counsel-dash, which is an ivy-mode interface for searching dash docsets.

;;; Code:

(require 'dash)
(require 'dash-functional)
(require 'counsel)

; Aliases are used so that we can provide a common interface, irrespective of
; any library changes in the future (e.g if helm-dash de-couples itself into two libraries.)

(defvaralias 'counsel-dash-docsets-path 'helm-dash-docsets-path)
(defvaralias 'counsel-dash-docsets-url 'helm-dash-docsets-url)
(defvaralias 'counsel-dash-min-length 'helm-dash-min-length)
(defvaralias 'counsel-dash-candidate-format 'helm-dash-candidate-format)
(defvaralias 'counsel-dash-enable-debugging 'helm-dash-enable-debugging)
(defvaralias 'counsel-dash-browser-func 'helm-dash-browser-func)
(defvaralias 'counsel-dash-common-docsets 'helm-dash-common-docsets)
(defvaralias 'counsel-dash-ignored-docsets 'helm-dash-ignored-docsets)

(defalias 'counsel-dash-activate-docset 'helm-dash-activate-docset)
(defalias 'counsel-dash-deactivate-docset 'helm-dash-deactivate-docset)
(defalias 'counsel-dash-install-docset 'helm-dash-install-docset)
(defalias 'counsel-dash-install-docset-from-file 'helm-dash-install-docset-from-file)
(defalias 'counsel-dash-install-user-docset 'helm-dash-install-user-docset)
(defalias 'counsel-dash-reset-connections 'helm-dash-reset-connections)

(require 'helm-dash)

(defgroup counsel-dash nil
  "Search Dash docsets using ivy"
  :group 'ivy)

(defvar counsel-dash-history-input nil
  "Input history used by `ivy-read'.")

(defvar counsel-dash--results nil
  "Stores the previously retrieved docset results.")

(defvar-local counsel-dash-docsets nil
  "Docsets to use for this buffer.")

(advice-add #'helm-dash-buffer-local-docsets :around
  (lambda (old-fun &rest args)
    (let ((old (apply old-fun args)))
      (-union old counsel-dash-docsets))))

(defun counsel-dash-collection (s &rest _)
  "Given a string S, query docsets and retrieve result."
  (when (>= (length s) counsel-dash-min-length)
    (setq helm-pattern s)
    (setq counsel-dash--results (helm-dash-search))
    (mapcar 'car counsel-dash--results)))

;;;###autoload
(defun counsel-dash (&optional initial)
  "Query dash docsets.
INITIAL will be used as the initial input, if given."
  (interactive)
  (helm-dash-initialize-debugging-buffer)
  (helm-dash-create-buffer-connections)
  (helm-dash-create-common-connections)
  (ivy-read "Documentation for: "
    'counsel-dash-collection
    :dynamic-collection t
    :history 'counsel-dash-history-input
    :initial-input initial
    :action (lambda (s)
              (-when-let (result (-drop 1 (-first (-compose (-partial 'string= s) 'car) counsel-dash--results)))
                (helm-dash-browse-url result)))))

(provide 'counsel-dash)
;;; counsel-dash.el ends here
