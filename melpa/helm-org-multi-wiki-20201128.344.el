;;; helm-org-multi-wiki.el --- Helm interface to org-multi-wiki -*- lexical-binding: t -*-

;; Copyright (C) 2020 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.3.2
;; Package-Version: 20201128.344
;; Package-Commit: cb845051cdce97e369bc7a900212e024cf2edb60
;; Package-Requires: ((emacs "26.1") (org-multi-wiki "0.3") (org-ql "0.4") (dash "2.12") (helm-org "1.0") (helm "3.5"))
;; Keywords: org, outlines
;; URL: https://github.com/akirak/org-multi-wiki

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This package provides a helm interface to org-multi-wiki.

;;; Code:

(require 'dash)
(require 'org-multi-wiki)
(require 'org-ql)
(require 'helm)
(require 'helm-org-ql)

;; Silence byte-compiler
(defvar helm-map)
(defvar helm-input-idle-delay)
(defvar helm-org-ql-input-idle-delay)
(defvar helm-org-ql-map)

(defgroup helm-org-multi-wiki nil
  "Helm interface to org-multi-wiki."
  :group 'org-multi-wiki
  :group 'helm)

(defvar helm-org-multi-wiki-dummy-source-map
  (let ((map (make-composed-keymap nil helm-map)))
    map)
  "Keymap for the dummy source.")

(defcustom helm-org-multi-wiki-show-files t
  "Whether to prepend file list in `helm-org-multi-wiki'."
  :type 'boolean)

(defcustom helm-org-multi-wiki-namespace-actions
  (quote (("Switch" . org-multi-wiki-switch)
          ("Search in namespace(s)"
           . (lambda (ns)
               (helm-org-multi-wiki (or (helm-marked-candidates) ns))))))
  "Alist of actions in `helm-org-multi-wiki-namespace'."
  :type '(alist :key-type string :value-type (or symbol function)))

(defcustom helm-org-multi-wiki-namespace-persistent-action
  ;; TODO: Add a persistent action for namespace
  nil
  "Persistent action in `helm-org-multi-wiki-namespace'."
  :type 'function)

(defun helm-org-multi-wiki-create-entry-from-input (namespace)
  "Create an entry in NAMESPACE from the input in the dummy source."
  (let ((inp (helm-get-selection)))
    (if (not (string-empty-p inp))
        (helm-run-after-exit #'org-multi-wiki-visit-entry inp :namespace namespace)
      (user-error "Input is empty"))))

;;;###autoload
(defmacro helm-org-multi-wiki-def-create-entry-action (namespace)
  "Define a command to creating an entry in NAMESPACE via the dummy source."
  `(defun ,(intern (format "helm-org-multi-wiki-create/%s" namespace)) ()
     (interactive)
     (helm-org-multi-wiki-create-entry-from-input (quote ,namespace))))

(defsubst helm-org-multi-wiki--format-ns-cand (x)
  "Format a helm candidate label of a namespace entry X."
  (pcase-let ((`(,ns ,root . _) x))
    (format "%s (%s)" ns root)))

(defclass helm-org-multi-wiki-source-namespace-symbol (helm-source-sync)
  ((candidates
    :initform (lambda ()
                (-map (lambda (x)
                        (cons (helm-org-multi-wiki--format-ns-cand x)
                              (car x)))
                      org-multi-wiki-namespace-list)))
   (persistent-action :initform 'helm-org-multi-wiki-namespace-persistent-action)))

;; Like `helm-org-multi-wiki-source-namespace-symbol' in the above,
;; but returns the whole alist entry.
(defclass helm-org-multi-wiki-source-namespace-entry (helm-source-sync)
  ((candidates
    :initform (lambda ()
                (-map (lambda (x)
                        (cons (helm-org-multi-wiki--format-ns-cand x)
                              x))
                      org-multi-wiki-namespace-list)))))

(cl-defun helm-org-multi-wiki-namespace (&key prompt action)
  "Select directory namespaces using helm.

PROMPT and ACTION are passed to helm."
  (interactive)
  (let ((prompt (or prompt "org-multi-wiki namespaces: "))
        (action (or action
                    (if (called-interactively-p 'any)
                        helm-org-multi-wiki-namespace-actions
                      (lambda (candidate)
                        (or (helm-marked-candidates) candidate))))))
    (helm :prompt prompt
          :sources
          (helm-make-source "Wiki namespace"
              'helm-org-multi-wiki-source-namespace-symbol
            :action action))))

(defvar helm-org-multi-wiki-buffers nil)

(defvar helm-org-multi-wiki-map
  (make-composed-keymap nil helm-org-ql-map))

(defcustom helm-org-multi-wiki-actions nil
  "Alist of actions in `helm-org-multi-wiki'.

This can be nil.  In that case, `helm-org-ql-actions' will be
inherited."
  :type 'alist)

(defcustom helm-org-multi-wiki-default-query '(level 1)
  "Query sent when no input is in the minibuffer."
  :type 'sexp)

(defcustom helm-org-multi-wiki-query-parser #'org-ql--plain-query
  "Function used to parse the plain query.

The function should take a plain query of org-ql.el as the argument
and return an S expression query."
  :type 'function)

;; Based on `helm-org-ql-source' from helm-org-ql.el at 0.5-pre.
(defclass helm-org-multi-wiki-source (helm-source-sync)
  ((candidates :initform (lambda ()
                           (let* ((query (if (string-empty-p helm-pattern)
                                             helm-org-multi-wiki-default-query
                                           (funcall helm-org-multi-wiki-query-parser helm-pattern)))
                                  (window-width (window-width (helm-window))))
                             (when query
                               (with-current-buffer (helm-buffer-get)
                                 (setq helm-org-ql-buffers-files helm-org-multi-wiki-buffers))
                               (ignore-errors
                                 ;; Ignore errors that might be caused by partially typed queries.
                                 (org-ql-select helm-org-multi-wiki-buffers query
                                   :action `(helm-org-ql--heading ,window-width)))))))
   (match :initform #'identity)
   (fuzzy-match :initform nil)
   (multimatch :initform nil)
   (nohighlight :initform t)
   (volatile :initform t)
   (keymap :initform 'helm-org-multi-wiki-map)
   (action :initform (or helm-org-multi-wiki-actions
                         helm-org-ql-actions))))

(defclass helm-org-multi-wiki-source-buffers (helm-source-sync)
  ((candidates :initform (lambda ()
                           (-map (lambda (buf)
                                   (cons (buffer-name buf) buf))
                                 helm-org-multi-wiki-buffers)))
   (persistent-action :initform (lambda (buf)
                                  (switch-to-buffer buf)
                                  (widen)
                                  (goto-char (point-min))
                                  (when (re-search-forward org-heading-regexp nil t)
                                    (org-show-entry))))
   (action :initform #'switch-to-buffer)))

(cl-defun helm-org-multi-wiki-make-dummy-source (namespaces &key first)
  "Create a dummy helm source.

NAMESPACES and FIRST are the same as in `helm-org-multi-wiki'."
  (helm-build-dummy-source "New entry"
    :keymap helm-org-multi-wiki-dummy-source-map
    :action
    (mapcar (lambda (namespace)
              (cons (format "Create a new entry in %s%s"
                            namespace
                            (if (equal namespace first)
                                " (current)"
                              ""))
                    (lambda (inp)
                      (org-multi-wiki-visit-entry inp :namespace namespace))))
            (if (and first (> (length namespaces) 1))
                (cons first (-remove-item first namespaces))
              namespaces))))

;;;###autoload
(cl-defun helm-org-multi-wiki (&optional namespaces &key first)
  "Visit an entry or create a new entry.

NAMESPACES are are a list of namespaces.
It can be a list of symbols or a symbol.

When FIRST is given, it is the default target of entry creation."
  (interactive)
  ;; Based on the implementation of helm-org-ql.
  (pcase current-prefix-arg
    ('(4) (let ((current-prefix-arg nil))
            (helm-org-multi-wiki-namespace
             :action
             (list (cons "Run helm-org-mult-wiki on selected namespaces"
                         (lambda (_)
                           (helm-org-multi-wiki (helm-marked-candidates))))))))
    (_ (let* ((namespaces (cl-etypecase namespaces
                            ;; Normalize namespaces to make it a list of symbols.
                            (null (if org-multi-wiki-current-namespace
                                      (list org-multi-wiki-current-namespace)
                                    (let ((namespaces (helm-org-multi-wiki-namespace
                                                       :prompt "Switch to a namespace: ")))
                                      (unless namespaces
                                        (user-error "Please select a namespace"))
                                      (org-multi-wiki-switch (car-safe namespaces))
                                      namespaces)))
                            (list namespaces)
                            (symbol (list namespaces))))
              (boolean 'and)
              (helm-input-idle-delay helm-org-ql-input-idle-delay)
              (files (->> namespaces
                          (--map (org-multi-wiki-entry-files it :as-buffers t))
                          (apply #'append)))
              (namespace-str (mapconcat #'symbol-name namespaces ",")))
         (setq helm-org-multi-wiki-buffers files)
         (helm :prompt (format "Query (boolean %s): " (-> boolean symbol-name upcase))
               :buffer "*helm org multi wiki*"
               :sources
               (delq nil
                     (list (when helm-org-multi-wiki-show-files
                             (helm-make-source (format "Wiki files in %s" namespace-str)
                                 'helm-org-multi-wiki-source-buffers))
                           (helm-make-source (format "Wiki (%s)" namespace-str)
                               'helm-org-multi-wiki-source)
                           (helm-org-multi-wiki-make-dummy-source namespaces :first first))))))))

;;;###autoload
(defun helm-org-multi-wiki-all ()
  "Run `helm-org-multi-wiki' on all configured directories."
  (interactive)
  (helm-org-multi-wiki (mapcar #'car org-multi-wiki-namespace-list)
                       :first org-multi-wiki-current-namespace))

(provide 'helm-org-multi-wiki)
;;; helm-org-multi-wiki.el ends here
