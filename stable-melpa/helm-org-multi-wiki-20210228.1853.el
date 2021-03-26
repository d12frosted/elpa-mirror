;;; helm-org-multi-wiki.el --- Helm interface to org-multi-wiki -*- lexical-binding: t -*-

;; Copyright (C) 2020 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.3.6
;; Package-Version: 20210228.1853
;; Package-Commit: bf8039aadddaf02569fab473f766071ef7e63563
;; Package-Requires: ((emacs "26.1") (org "9.3") (org-multi-wiki "0.4") (org-ql "0.5") (dash "2.18") (helm-org-ql "0.5") (helm "3.5"))
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
(require 'ol)

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

(defcustom helm-org-multi-wiki-default-namespace nil
  "Default namespace for creating a new file.

This option determines which namespace in
`org-multi-wiki-namespace-list' will be the target of the default
action in Helm dummy sources in this package.

This should be the symbol for a namespace in
`org-multi-wiki-namespace-list' or nil.

If it is nil, `org-multi-wiki-current-namespace' will be the default.

Alternatively, you can select other namespaces by pressing TAB in
the Helm sources."
  :type '(choice nil symbol))

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

(defcustom helm-org-multi-wiki-skip-subtrees t
  "Whether to skip subtrees matching the query for cleaner output."
  :type 'boolean)

(defcustom helm-org-multi-wiki-create-entry-function
  #'org-multi-wiki-visit-entry
  "Function used to create a new entry from the dummy source.

This function should accept the following arguments:

  (func TITLE :namespace NAMESPACE)

where TITLE is the name of the new entry and NAMESPACE is a
symbol to denote the namespace. See `org-multi-wiki-visit-entry'
for an example, which is the default value."
  :type 'function)

(defcustom helm-org-multi-wiki-insert-link-actions
  '(("Insert a link" . helm-org-multi-wiki--insert-link)
    ("Insert a link (modify the label)" . helm-org-multi-wiki--insert-link-with-label))
  "Alist of actions used to insert a link to a heading."
  :type 'alist)

(defmacro helm-org-multi-wiki-with-namespace-buffers (namespaces &rest progn)
  "Evaluate an expression with namespace buffers.

This macro sets `helm-org-multi-wiki-buffers` to buffers from NAMESPACES
and evaluate PROGN."
  (declare (indent 1))
  `(progn
     (setq helm-org-multi-wiki-buffers
           (->> ,namespaces
                (--map (org-multi-wiki-entry-files it :as-buffers t))
                (apply #'append)))
     ,@progn))

(defsubst helm-org-multi-wiki--create-entry (namespace title)
  "In NAMESPACE, create a new entry from TITLE."
  (funcall helm-org-multi-wiki-create-entry-function title :namespace namespace))

(defun helm-org-multi-wiki-create-entry-from-input (namespace)
  "Create an entry in NAMESPACE from the input in the dummy source."
  (let ((title (helm-get-selection)))
    (if (not (string-empty-p title))
        (helm-run-after-exit #'helm-org-multi-wiki--create-entry namespace title)
      (user-error "Input is empty"))))

;;;###autoload
(defmacro helm-org-multi-wiki-def-create-entry-action (namespace)
  "Define a command to create an entry in NAMESPACE via the dummy source.

This function is only provided as a utility."
  `(defun ,(intern (format "helm-org-multi-wiki-create/%s" namespace)) ()
     (interactive)
     (helm-org-multi-wiki-create-entry-from-input (quote ,namespace))))

(defun helm-org-multi-wiki--insert-link (marker &optional modify-label)
  "Insert a link to a heading.

MARKER is the marker to the link target.

If MODIFY-LABEL is non-nil, it prompts for the link text."
  (let* ((plist (org-with-point-at marker
                  ;; TODO: Pass the origin-ns as an argument
                  (org-multi-wiki--get-link-data)))
         (headline (plist-get plist :headline))
         (link-text (if modify-label
                        (read-string "Link label: " headline)
                      headline)))
    (helm-org-multi-wiki--make-link-dwim (plist-get plist :link)
                                         link-text)))

(defun helm-org-multi-wiki--insert-link-with-label (marker)
  "Insert a link to a heading, with the link text modified.

MARKER is the marker to the link target."
  (helm-org-multi-wiki--insert-link marker t))

(defun helm-org-multi-wiki--insert-new-entry-link (namespace title)
  "Insert a link to a non-existent entry.

NAMESPACE is the namespace in which a new entry will be created,
and TITLE is the title of the entry."
  (-> (org-multi-wiki--make-link namespace title :to-file t)
      (helm-org-multi-wiki--make-link-dwim title)))

(defun helm-org-multi-wiki--link-info-at-point ()
  "Return information on the link at point if any."
  (when-let (plist0 (get-char-property (point) 'htmlize-link))
    (save-match-data
      (pcase (org-in-regexp org-link-any-re 2)
        (`(,begin . ,end)
         (let ((raw (buffer-substring-no-properties begin end)))
           (append (list :begin begin :end end
                         :text (when (string-match org-link-bracket-re raw)
                                 (match-string 2 raw)))
                   ;; Contains :uri
                   plist0)))))))

(defun helm-org-multi-wiki--verbatim-info-at-point ()
  "Return information on the verbatim at point if any."
  (save-match-data
    (pcase (org-in-regexp org-verbatim-re 2)
      (`(,begin . ,end)
       (list :begin begin :end end
             :text (buffer-substring-no-properties (match-end 3) (match-end 4)))))))

(defun helm-org-multi-wiki--link-context ()
  "Identify the thing at point for linking."
  (or (when (region-active-p)
        (let* ((begin (region-beginning))
               (end (region-end))
               (text (buffer-substring-no-properties begin end)))
          (list 'region :begin begin :end end :text text)))
      (-some->> (helm-org-multi-wiki--link-info-at-point)
        (cons 'link))
      (-some->> (helm-org-multi-wiki--verbatim-info-at-point)
        (cons 'verbatim))))

(defun helm-org-multi-wiki--make-link-dwim (link text)
  "Produce an Org link depending on the context.

When there is an active region, replace the selected text with a
LINK with the original TEXT as the label. The second argument
will be discarded.

When the point is on a link/verbatim, replace it with a link,
maintaining its text.

Otherwise, it inserts a link to LINK with TEXT as the label."
  (if-let (context (helm-org-multi-wiki--link-context))
      (-let (((&plist :begin :end) (cdr context)))
        (delete-region begin end)
        (goto-char begin)
        (insert (org-link-make-string link (or (plist-get (cdr context) :text)
                                               text))))
    (insert (org-link-make-string link text))))

(defun helm-org-multi-wiki-file-link-insert-action (buffer)
  "Insert a link to BUFFER, with its first heading as the link text."
  (-let (((plist headline) (with-current-buffer buffer
                             (org-with-wide-buffer
                              (goto-char (point-min))
                              (list (org-multi-wiki-entry-file-p)
                                    (when (re-search-forward org-heading-regexp nil t)
                                      (org-get-heading t t t t)))))))
    (helm-org-multi-wiki--make-link-dwim (org-multi-wiki--make-link
                                          (plist-get plist :namespace)
                                          (plist-get plist :basename)
                                          :to-file t)
                                         (or headline
                                             (plist-get plist :basename)))))

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

(defun helm-org-multi-wiki--normalize-namespaces (namespaces)
  "Normalize NAMESPACES, i.e. convert to a list."
  (cl-etypecase namespaces
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

(defcustom helm-org-multi-wiki-file-actions
  '(("Switch to the buffer" . switch-to-buffer)
    ("Switch to the buffer (other window)" . switch-to-buffer-other-window)
    ("Switch to the buffer (other frame)" . switch-to-buffer-other-frame))
  "Helm actions for Org file buffers."
  :type 'alist)

(defcustom helm-org-multi-wiki-default-query '(level 1)
  "Query sent when no input is in the minibuffer."
  :type 'sexp)

(defcustom helm-org-multi-wiki-query-parser
  ;; This is an internal API of org-ql, so it would be better to avoid it
  #'org-ql--query-string-to-sexp
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
                                   :action `(prog1
                                                (helm-org-ql--heading ,window-width)
                                              (when helm-org-multi-wiki-skip-subtrees
                                                (org-end-of-subtree)))))))))
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
   ;; This does not restore the narrowing state, nor does it allow customization.
   ;; Maybe work on this later?
   (persistent-action :initform (lambda (buf)
                                  (switch-to-buffer buf)
                                  (widen)
                                  (goto-char (point-min))
                                  (when (re-search-forward org-heading-regexp nil t)
                                    (org-show-entry))))
   (coerce :initform (lambda (buf)
                       (with-current-buffer buf
                         (org-multi-wiki-run-mode-hooks))
                       buf))
   (action :initform 'helm-org-multi-wiki-file-actions)))

(cl-defun helm-org-multi-wiki-make-dummy-source (namespaces &key
                                                            first
                                                            action)
  "Create a dummy helm source.

NAMESPACES is a list of symbols.

FIRST is the target namespace of the first action, as in
`helm-org-multi-wiki' function.

If ACTION is given, it is used to handle the input. It should be
a function that takes two arguments: a string and a namespace."
  (helm-build-dummy-source "New entry"
    :keymap helm-org-multi-wiki-dummy-source-map
    :action
    (mapcar `(lambda (namespace)
               (cons (format "Create a new entry in %s%s"
                             namespace
                             (if (equal namespace org-multi-wiki-current-namespace)
                                 " (current)"
                               ""))
                     (-partial (or (quote ,action) #'helm-org-multi-wiki--create-entry)
                               namespace)))
            (if (and first (> (length namespaces) 1))
                (cons first (-remove-item first namespaces))
              namespaces))))

(defconst helm-org-multi-wiki-prompt
  "Query (boolean AND): ")

;;;###autoload
(cl-defun helm-org-multi-wiki (&optional namespaces &key first)
  "Visit an entry or create a new entry.

NAMESPACES are are a list of namespaces.
It can be a list of symbols or a symbol.

If FIRST is given, it will be the default namespace in which an
entry is created."
  (interactive (list current-prefix-arg))
  ;; Based on the implementation of helm-org-ql.
  (if (equal namespaces '(4))
      (helm-org-multi-wiki-namespace
       :action
       (list (cons "Run helm-org-mult-wiki on selected namespaces"
                   (lambda (_)
                     (helm-org-multi-wiki (helm-marked-candidates))))))
    (let* ((namespaces (helm-org-multi-wiki--normalize-namespaces namespaces))
           (helm-input-idle-delay helm-org-ql-input-idle-delay)
           (namespace-str (mapconcat #'symbol-name namespaces ","))
           (default-namespace (or helm-org-multi-wiki-default-namespace
                                  org-multi-wiki-current-namespace)))
      (helm-org-multi-wiki-with-namespace-buffers namespaces
        (helm :prompt helm-org-multi-wiki-prompt
              :buffer "*helm org multi wiki*"
              :sources
              (delq nil
                    (list (when helm-org-multi-wiki-show-files
                            (helm-make-source (format "Wiki files in %s" namespace-str)
                                'helm-org-multi-wiki-source-buffers))
                          (helm-make-source (format "Wiki (%s)" namespace-str)
                              'helm-org-multi-wiki-source)
                          (helm-org-multi-wiki-make-dummy-source
                           namespaces
                           :first (or first
                                      (if (memq default-namespace namespaces)
                                          default-namespace
                                        (car namespaces)))))))))))

;;;###autoload
(defun helm-org-multi-wiki-all ()
  "Run `helm-org-multi-wiki' on all configured directories."
  (interactive)
  (helm-org-multi-wiki (mapcar #'car org-multi-wiki-namespace-list)
                       :first (or helm-org-multi-wiki-default-namespace
                                  org-multi-wiki-current-namespace)))

;;;###autoload
(cl-defun helm-org-multi-wiki-insert-link (&key first)
  "Insert a link or converts the region to a link.

FIRST is the default namespace when you create a non-existent
entry."
  (interactive)
  (unless (derived-mode-p 'org-mode)
    (user-error "Not in org-mode"))
  ;; TODO: Add support for regions
  (let* ((namespaces (mapcar #'car org-multi-wiki-namespace-list))
         (helm-input-idle-delay helm-org-ql-input-idle-delay)
         (namespace-str (mapconcat #'symbol-name namespaces ","))
         (context (helm-org-multi-wiki--link-context)))
    (helm-org-multi-wiki-with-namespace-buffers namespaces
      (helm :prompt (cl-case (car context)
                      (region
                       "Replace the region with a link: ")
                      (link
                       "Replace the link: ")
                      (verbatim
                       "Replace the text with a link: ")
                      (_
                       "Insert a link: "))
            :buffer "*helm org multi wiki*"
            :input (-let (((&plist :text :uri) (cdr context)))
                     (or text uri))
            :sources
            (list (when helm-org-multi-wiki-show-files
                    (helm-make-source (format "Wiki files in %s" namespace-str)
                        'helm-org-multi-wiki-source-buffers
                      :action #'helm-org-multi-wiki-file-link-insert-action))
                  (helm-make-source (format "Wiki (%s)" namespace-str)
                      'helm-org-multi-wiki-source
                    :action helm-org-multi-wiki-insert-link-actions)
                  (helm-org-multi-wiki-make-dummy-source namespaces
                                                         :action #'helm-org-multi-wiki--insert-new-entry-link
                                                         :first (or first
                                                                    helm-org-multi-wiki-default-namespace
                                                                    org-multi-wiki-current-namespace)))))))

(provide 'helm-org-multi-wiki)
;;; helm-org-multi-wiki.el ends here
