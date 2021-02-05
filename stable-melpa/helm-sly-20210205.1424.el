;;; helm-sly.el --- Helm sources and some utilities for SLY. -*- lexical-binding: t -*-

;; Copyright (C) 2019, 2020, 2021 Pierre Neidhardt <mail@ambrevar.xyz>
;;
;; Author: Pierre Neidhardt <mail@ambrevar.xyz>
;; URL: https://github.com/emacs-helm/helm-sly
;; Package-Version: 20210205.1424
;; Package-Commit: 3691626c80620e992a338c3222283d9149f1ecb5
;; Version: 0.7.2
;; Keywords: convenience, helm, sly, lisp
;; Package-Requires: ((emacs "25.1") (helm "3.2") (cl-lib "0.5") (sly "0.0"))

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; A Helm for using SLY.
;;
;; The complete command list:
;;
;;  `helm-sly-list-connections'
;;    Yet another Lisp connection list with `helm'.
;;  `helm-sly-apropos'
;;    Yet another `apropos' with `helm'.
;;  `helm-sly-mini'
;;    Like ~helm-sly-list-connections~, but include an extra source of
;;    Lisp-related buffers, like the events buffer or the scratch buffer.

;;; Installation:
;;
;; Add helm-sly.el to your load-path.
;; Set up SLY properly.
;;
;; To use Helm instead of the Xref buffer, enable `global-helm-sly-mode'.
;;
;; To enable Helm for completion, two options:
;;
;; - Without company:
;;
;;   (add-hook 'sly-mrepl-hook #'helm-sly-disable-internal-completion)
;;
;;   If you want fuzzy-matching:
;;
;;   (setq helm-completion-in-region-fuzzy-match t)
;;
;;
;; - With company, install helm-company
;;   (https://github.com/Sodel-the-Vociferous/helm-company), then:
;;
;;   (add-hook 'sly-mrepl-hook #'company-mode)
;;   (require 'helm-company)
;;   (define-key sly-mrepl-mode-map (kbd "<tab>") 'helm-company)

;;; Code:

(require 'helm)
(require 'helm-buffers)
(require 'sly)
(require 'cl-lib)

(declare-function sly-mrepl--find-buffer "sly-mrepl.el")
(declare-function sly-mrepl-new "sly-mrepl.el")
(declare-function sly-scratch "sly-scratch.el")

(defun helm-sly-disable-internal-completion ()
  "Disable SLY own's completion system, e.g. to use Helm instead.
This is mostly useful when added to `sly-mrepl-hook'."
  (sly-symbol-completion-mode -1))

(defgroup helm-sly nil
  "Helm sources and some utilities for SLY."
  :prefix "helm-sly-"
  :group 'helm
  :link '(url-link :tag "GitHub" "https://github.com/emacs-helm/helm-sly"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defvar helm-sly-connections-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-buffer-map)
    (define-key map (kbd "C-c o") 'helm-sly-run-go-to-repl-other-window)
    (define-key map (kbd "M-D") 'helm-sly-run-delete-buffers)
    (define-key map (kbd "M-R") 'helm-sly-run-rename-connection-buffer)
    map)
  "Keymap for Lisp connection source in Helm.")

(defun helm-sly-output-buffer (&optional connection)
  "Generic wrapper for CONNECTION output buffer."
  (sly-mrepl--find-buffer (or connection (sly-current-connection))))

(defun helm-sly-go-to-repl (_candidate &optional other-window-p)
  "Switched to marked REPL(s)."
  (helm-window-show-buffers
   (mapcar (lambda (candidate)
             (let ((buffer (nth 1 candidate))
                   (connection (nth 0 candidate)))
               (or buffer
                   (and (process-live-p connection)
                        ;; WARNING: Current buffer might be another mrepl, in
                        ;; which case we must locally nullify
                        ;; `sly-buffer-connection' and
                        ;; `sly-dispatching-connection' as per
                        ;; `sly-mrepl--find-buffer'.
                        (let ((sly-buffer-connection nil)
                              (sly-dispatching-connection nil))
                          (sly-mrepl-new connection)))
                   (sly))))
           (helm-marked-candidates))
   other-window-p))
(put 'helm-sly-go-to-repl 'helm-only t)

(defun helm-sly-go-to-repl-other-window (_candidate)
  "Switched to marked REPL(s)."
  (helm-sly-go-to-repl nil :other-window-p))
(put 'helm-sly-go-to-repl-other-window 'helm-only t)

(defun helm-sly-process (connection)
  "Generic wrapper for CONNECTION process."
  (sly-process connection))

(defun helm-sly-connection-number (connection)
  "Generic wrapper for CONNECTION number."
  (sly-connection-number connection))

(defun helm-sly-connection-name (connection)
  "Generic wrapper for CONNECTION name."
  (sly-connection-name connection))

(defun helm-sly-pid (connection)
  "Generic wrapper for CONNECTION pid."
  (sly-pid connection))

(defun helm-sly-implementation-type (connection)
  "Generic wrapper for CONNECTION implementation type."
  (sly-lisp-implementation-type connection))

(defun helm-sly-debug-buffers (connection)
  "Generic wrapper for CONNECTION debug buffers."
  (sly-db-buffers connection))

(defun helm-sly-buffer-connection (buffer)
  "Generic wrapper for BUFFER's connection."
  (when (bufferp buffer)
    (with-current-buffer buffer
      sly-buffer-connection)))

(defun helm-sly-go-to-inferior (_candidate)
  "Switched to inferior Lisps associated with the marked connections."
  (helm-window-show-buffers
   (cl-loop for c in (helm-marked-candidates)
            collect (process-buffer (helm-sly-process
                                     (helm-sly-buffer-connection c))))))
(put 'helm-sly-go-to-inferior 'helm-only t)

(defun helm-sly-go-to-debug (_candidate)
  "Switched to debug buffers associated with the marked connections."
  (let ((db-buffers (mapcan (lambda (candidate)
                              (helm-sly-debug-buffers (car candidate)))
                            (helm-marked-candidates))))
    (if db-buffers
        (helm-window-show-buffers db-buffers)
      (message "No debug buffers"))))
(put 'helm-sly-go-to-debug 'helm-only t)

(defun helm-sly-run-go-to-repl-other-window ()
  "Run `helm-sly-go-to-repl-other-window' action from `helm-sly--c-source-connection'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-sly-go-to-repl-other-window)))
(put 'helm-sly-run-go-to-repl-other-window 'helm-only t)

(defun helm-sly-run-delete-buffers ()
  "Run `helm-sly-delete-buffers' action from `helm-sly--c-source-connection'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-sly-delete-buffers)))
(put 'helm-sly-run-delete-buffers 'helm-only t)

(defun helm-sly-set-default-connection (candidate)
  "Set connection to use by default to that of CANDIDATE buffer."
  (let ((connection (car candidate)))
    (sly-select-connection connection)))
(put 'helm-sly-rename-connection-buffer 'helm-only t)

(defun helm-sly--net-processes ()
  "Generic wrapper around connection processes."
  sly-net-processes)

(defun helm-sly-delete-buffers (&optional _candidate)
  "Kill marked REPL(s).
Kill their inferior Lisps as well if they are the last buffer
connected to it."
  (dolist (c (helm-marked-candidates))
    (let ((last-connection?
           (not (memq (car c)
                      (mapcar #'helm-sly-buffer-connection
                              (delete (cadr c)
                                      (helm-sly--repl-buffers)))))))
      (when last-connection?
        (let ((sly-dispatching-connection (car c)))
          (ignore-errors (sly-quit-lisp t))))
      (kill-buffer (cadr c)))))
(put 'helm-sly-delete-buffers 'helm-only t)

(defun helm-sly-restart-connections (_candidate)
  "Restart marked REPLs' inferior Lisps."
  (dolist (c (helm-marked-candidates))
    (sly-restart-connection-at-point (helm-sly-buffer-connection c))))
(put 'helm-sly-restart-connections 'helm-only t)

(defun helm-sly-run-rename-connection-buffer ()
  "Run `helm-sly-rename-connection-buffer' action from `helm-sly--c-source-connection'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-sly-rename-connection-buffer)))
(put 'helm-sly-run-rename-connection 'helm-only t)

(defun helm-sly-rename-connection-buffer (candidate)
  "Rename REPL buffer for CANDIDATE."
  (let* ((sly-dispatching-connection (car candidate)))
    (when (cadr candidate)
      (with-current-buffer (cadr candidate)
        (rename-buffer (helm-read-string "New name: " (buffer-name)))))))
(put 'helm-sly-rename-connection-buffer 'helm-only t)

(defcustom helm-sly-connection-actions
  `(("Go to REPL" . helm-sly-go-to-repl)
    (,(substitute-command-keys "Go to REPL in other window \\<helm-sly-connections-map>`\\[helm-sly-run-go-to-repl-other-window]'")
     . helm-sly-go-to-repl-other-window)
    ("Set default" . helm-sly-set-default-connection)
    ("Restart" . helm-sly-restart-connections)
    (,(substitute-command-keys "Rename REPL buffer \\<helm-sly-connections-map>`\\[helm-sly-run-rename-connection-buffer]'")
     . helm-sly-rename-connection-buffer)
    (,(substitute-command-keys "Quit \\<helm-sly-connections-map>`\\[helm-sly-run-delete-buffers]'")
     . helm-sly-delete-buffers)
    ("Go to inferior Lisp" . helm-sly-go-to-inferior)
    ("Go to debug buffers" . helm-sly-go-to-debug))
  "Actions for `helm-sly-list-connections`."
  :group 'helm-sly
  :type '(alist :key-type string :value-type function))

(defun helm-sly-format-connection (connection buffer)
  (let ((fstring "%s%2s  %-16s  %-17s  %-7s %-s %s"))
    (format fstring
            (if (eq sly-default-connection connection)
                "*"
              " ")
            (helm-sly-connection-number connection)
            (helm-sly-connection-name connection)
            (or (process-id connection) (process-contact connection))
            (helm-sly-pid connection)
            (helm-sly-implementation-type connection)
            buffer)))

(defcustom helm-sly-connection-formatter #'helm-sly-format-connection
  "Function that takes a connection and return the Helm display string.
This can be used to customize the formatting of the buffer/connection sources."
  :group 'helm-sly
  :type 'function)

(defun helm-sly--connection-candidates (p &optional buffer)
  "Return (DISPLAY-VALUE . REAL-VALUE) for connection P.
The REAL-VALUE is (P BUFFER).
If BUFFER is nil, the inferior Lisp buffer is used in the display function."
  (setq buffer (or buffer
                   (helm-sly-output-buffer p)))
  (cons
   (funcall helm-sly-connection-formatter p (or buffer
                                                (sly-inferior-lisp-buffer p)))
   (list p buffer)))

(defun helm-sly--repl-buffers (&optional connection thread)
  "Return the list of buffers association to CONNECTION and/or THREAD.
Inspired by `sly-mrepl--find-buffer'."
  (cl-remove-if-not
   (lambda (x)
     (with-current-buffer x
       (and (eq major-mode 'sly-mrepl-mode)
            (or (not connection)
                (eq sly-buffer-connection
                    connection))
            (or (not thread)
                (eq thread sly-current-thread)))))
   (buffer-list)))

(cl-defun helm-sly--repl-buffer-candidates (&optional connection predicate)
  "Return buffer/connection candidates.
It returns all REPL buffer candidates matching CONNECTION.
Further filter the candidates with PREDICATE.
Without CONNECTION or PREDICATE, return all REPL buffer candidates and all
buffer-less connections (both matching PREDICATE).
Current buffer is listed last."
  (let* ((repl-buffers (helm-sly--repl-buffers connection))
         (repl-buffers (if predicate
                           (cl-remove-if-not predicate repl-buffers)
                         repl-buffers))
         (buffer-connections (cl-delete-duplicates
                              (mapcar #'helm-sly-buffer-connection
                                      repl-buffers))))
    (let* ((result
            (append (mapcar (lambda (b)
                              (helm-sly--connection-candidates
                               (helm-sly-buffer-connection b)
                               b))
                            repl-buffers)
                    (unless (or connection predicate)
                      (mapcar #'helm-sly--connection-candidates
                              (cl-set-difference
                               (reverse (helm-sly--net-processes))
                               buffer-connections)))))
           (current-buffer-candidate
            (cl-find (current-buffer)
                     result
                     :key #'cl-third)))
      (append (cl-delete current-buffer-candidate result)
              (and current-buffer-candidate
                   (list current-buffer-candidate))))))

(cl-defun helm-sly--c-source-connection (&optional (candidates
                                                    (helm-sly--repl-buffer-candidates))
                                                   (name "Lisp connections"))
  "Build Helm source of Lisp connections.
You can easily customize the candidates by, for instance, calling
`helm-sly--repl-buffer-candidates' over a specific connection."
  (helm-build-sync-source name
    :candidates candidates
    :action helm-sly-connection-actions
    :keymap helm-sly-connections-map))

;;;###autoload
(defun helm-sly-list-connections ()
  "List Lisp connections with Helm."
  (interactive)
  (helm :sources (list (helm-sly--c-source-connection))
        :buffer "*helm-sly-list-connections*"))

(defun helm-sly--buffer-candidates ()
  "Collect Lisp-related buffers, like the `events' buffer.
If the buffer does not exist, we use the associated function to generate it.

The list is in the (DISPLAY . REAL) form.
REAL is either a buffer or a function returning a buffer."
  (append
   `(,(cons (sly-buffer-name :events :connection (sly-current-connection))
            #'sly-pop-to-events-buffer)
     ,(cons (sly-buffer-name :threads :connection (sly-current-connection))
            #'sly-list-threads)
     ,(cons (sly-buffer-name :inferior :connection (sly-current-connection))
            #'sly-inferior-lisp-buffer))
   (when (sly-db-buffers (sly-current-connection))
     (list
      (cons (sly-buffer-name :db :connection (sly-current-connection))
            #'sly-db-pop-to-debugger)))
   (list (cons (sly-buffer-name :scratch)
               #'sly-scratch))
   (delq nil (mapcar (lambda (name)
                       (let ((buffer (get-buffer name)))
                         (when buffer
                           (cons name buffer))))
                     '("*sly-description*" "*sly-compilation*")))))


(defun helm-sly-switch-buffers (_candidate)
  "Switch to buffer candidates and replace current buffer.

If more than one buffer marked switch to these buffers in separate windows.
If a prefix arg is given split windows vertically."
  (helm-window-show-buffers
   (cl-loop for b in (helm-marked-candidates)
            collect (if (functionp b)
                        (call-interactively b)
                      b))))
(put 'helm-sly-switch-buffers 'helm-only t)

(defun helm-sly-build-buffers-source ()
  "Build Helm source of Lisp buffers."
  (helm-build-sync-source "Build buffers"
    :candidates (helm-sly--buffer-candidates)
    :action `(("Switch to buffer(s)" . helm-sly-switch-buffers))))

(defun helm-sly-new-repl (name)
  "Spawn new SLY REPL with name NAME."
  (or (ignore-errors
        (sly-mrepl-new (sly-connection) name))
      (sly)))

(defun helm-sly-new-repl-choose-lisp (&optional _name)
  "Spawn new SLY REPL on a new connection."
  ;; TODO: Name is ignored for now.  Is there a way to pass the buffer name?
  ;; Advising or using cl-letf on sly-mrepl-new does not seem to work.
  (let ((current-prefix-arg '-))
    (call-interactively #'sly)))

(defvar helm-sly-new
  (helm-build-dummy-source "Open new REPL"
    :action (helm-make-actions
             "Open new REPL" 'helm-sly-new-repl
             "Open new REPL with chosen Lisp" 'helm-sly-new-repl-choose-lisp))
  "Helm source to make new REPLs.")

(defun helm-sly-lisp-buffer-p (buffer)
  "Return non-nil if BUFFER is derived from `lisp-mode'."
  (with-current-buffer buffer
    (derived-mode-p 'lisp-mode)))

(cl-defun helm-sly-lisp-buffer-source (&key (name "Lisp buffers")
                                            (predicate #'helm-sly-lisp-buffer-p))
  (helm-make-source name 'helm-source-buffers
    :buffer-list (lambda ()
                   (mapcar #'buffer-name
                           (cl-remove-if-not predicate
                                             (buffer-list))))))

(defun helm-sly-mini ()
  "Helm for Lisp connections and buffers."
  (interactive)
  (helm :sources (list (helm-sly--c-source-connection)
                       helm-sly-new
                       (helm-sly-lisp-buffer-source)
                       (helm-sly-build-buffers-source))
        :buffer "*helm-sly-mini*"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun helm-sly--format-apropos-entry (entry)
  "Generic wrapper around apropos' entries.
ENTRY is in the following form:

\(:designator (\"FORMAT-SYMBOL\" \"ALEXANDRIA\" t)
 :function \"Constructs a string by applying ARGUMENTS to string designator CONTROL as\"
 :arglist \"(PACKAGE CONTROL &REST ARGUMENTS)\"
 :bounds ((11 17)))"
  (let* ((designator (plist-get entry :designator))
         (type (nth 2 entry))
         (synopsis (plist-get entry type))
         (arglist (plist-get entry :arglist)))
    (let ((real-value (downcase (sly-apropos-designator-string designator))))
      (cons
       (format "%s [%s%s]%s"
               (propertize real-value
                           'face 'sly-apropos-symbol)
               (propertize (upcase-initials
                              (replace-regexp-in-string
                               "-" " " (substring (symbol-name type) 1)))
                           'face 'italic)
               (if (cl-find type '(:function :generic-function :macro))
                   (downcase (format " %s" arglist))
                 "")
               (if (eq synopsis :not-documented)
                   ""
                 (concat "\n" synopsis)))
       real-value))))

(defun helm-sly-apropos-inspect (name)
  (sly-inspect (format "(quote %s)" name)))

(defun helm-sly-apropos-describe-other-window (name)
  ;; Warning: Both Helm and `sly-describe-symbol' have their own
  ;; buffer-switching logic.
  ;; To ensure `sly-describe-symbol' does not replace the current Helm buffer,
  ;; we switch to it now.
  (switch-to-buffer (sly-buffer-name :description))
  (sly-describe-symbol name))

(defcustom helm-sly-apropos-actions
  `(("Describe" . sly-describe-symbol)
    ("Go to source" . sly-edit-definition)
    ("Inspect definition" . helm-sly-apropos-inspect)
    ;; `sly-edit-uses' combines `sly-who-calls', `sly-who-references', and
    ;; `sly-who-macroexpands'.
    ("Find all the references to this symbol" . sly-edit-uses)
    ;; `sly-calls-who' seems to only work on LispWorks, while `sly-list-callees'
    ;; works everywhere.
    ("Show all known callees" . sly-list-callees)
    ("Show bindings of a global variable" . sly-who-binds)
    ("Show assignments to a global variable" . sly-who-sets)
    ("Show all known methods specialized on a class" . sly-who-specializes))
  "Actions for `helm-sly--apropos-source'.
This is similar to the `sly-apropos-symbol' button type."
  :group 'helm-sly
  :type '(alist :key-type string :value-type function))

(defun helm-sly--apropos-source (name external-only case-sensitive current-package)
  "Build source that provides Helm completion against `apropos'.
- NAME: name of the source.
- EXTERNAL-ONLY: only search external symbols.
- CASE-SENSITIVE: match case in apropos search.
- CURRENT-PACKAGE: only search symbols in current package."
  (helm-build-sync-source name
    :candidates
    `(lambda ()
       (with-current-buffer helm-current-buffer
         (cl-loop for entry in (sly-eval
                                (list 'slynk-apropos:apropos-list-for-emacs
                                      ;; Warning: Properties crash Slynk!
                                      ;; See https://github.com/joaotavora/sly/issues/370.
                                      (regexp-quote (substring-no-properties helm-pattern))
                                      ,(not (null external-only))
                                      ,(not (null case-sensitive))
                                      (when ,current-package
                                        (helm-sly-current-package))))
                  collect (helm-sly--format-apropos-entry entry))))
    :requires-pattern 2
    :fuzzy-match t
    :multiline t
    :persistent-help "Describe"
    :action helm-sly-apropos-actions
    :persistent-action #'helm-sly-apropos-describe-other-window))

(defun helm-sly-current-package ()
  "Return the Common Lisp package in the current context."
  (or sly-buffer-package
      (sly-current-package)))

(defvar helm-sly--c-source-apropos-symbol-current-package
  (helm-sly--apropos-source
   "Apropos (current package)"
   nil
   nil
   (helm-sly-current-package)))

(defvar helm-sly--c-source-apropos-symbol-current-external-package
  (helm-sly--apropos-source
   "Apropos (current external package)"
   'external-only
   nil
   (helm-sly-current-package)))

(defvar helm-sly--c-source-apropos-symbol-all-external-package
  (helm-sly--apropos-source
   "Apropos (all external packages)"
   'external-only
   nil
   nil))

(defvar helm-sly--c-source-apropos-symbol-all-package
  (helm-sly--apropos-source
   "Apropos (all packages)"
   nil
   nil
   nil))

(defvar helm-sly-apropos-sources
  '(helm-sly--c-source-apropos-symbol-current-package
    helm-sly--c-source-apropos-symbol-current-external-package
    helm-sly--c-source-apropos-symbol-all-external-package
    helm-sly--c-source-apropos-symbol-all-package)
  "List of Helm sources for `helm-sly-apropos'.")

;;;###autoload
(defun helm-sly-apropos ()
  "Yet another Apropos with `helm'.
It won't display before you start entering a pattern."
  (interactive)
  (helm :sources helm-sly-apropos-sources
        :buffer "*helm lisp apropos*"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(defun helm-sly-normalize-xrefs (xref-alist)
  "Like `sly-insert-xrefs' but return a formatted list of strings instead.
XREF-ALIST is as per `sly-insert-xrefs'.
The strings are formatted as \"GROUP: LABEL\"."
  (cl-loop for (group . refs) in xref-alist
           append
           (cl-loop for (label location) in refs
                    collect
                    (list group label location))))

(defun helm-sly-xref-lineno (location)
  "Return line number of xref's LOCATION.
Return 0 if location does not refer to a proper file."
  (or
   (ignore-errors
     (save-window-excursion
       (sly--pop-to-source-location location
                                    'sly-xref)
       (line-number-at-pos
        (car (alist-get :position (cdr location))))))
   0))

(defun helm-sly-xref-transformer (candidates)
  "Transform CANDIDATES to \"GROUP: LABEL\".
CANDIDATES is a list of (GROUP LABEL LOCATION) as per
`helm-sly-normalize-xrefs'."
  (cl-loop for (group label location) in candidates
           collect (cons (concat (propertize (abbreviate-file-name group)
                                             'face 'helm-grep-file)
                                 ":"
                                 (propertize
                                  (number-to-string (helm-sly-xref-lineno location))
                                  'face 'helm-grep-lineno)
                                 ":"
                                 (sly-one-line-ify label))
                         (list group label location))))

(defun helm-sly-xref-goto (candidate)
  "Go to CANDIDATE xref location."
  (let ((location (nth 2 candidate)))
    (switch-to-buffer
     (save-window-excursion
       (sly--pop-to-source-location location 'sly-xref)))))

(defun helm-sly-xref-recompile (_candidate &optional policy)
  "Recompile selected candidates.
POLICY is as per `sly-compile-defun'.
The POLICY of NIL defaults to `sly-compilation-policy'."
  (let ((sly-compilation-policy (sly-compute-policy policy)))
    (let ((labels '())
          (locations '()))
      (dolist (candidate (helm-marked-candidates))
        (push (nth 1 candidate) labels)
        (push (nth 2 candidate) locations))
      (sly-recompile-locations
       locations
       (lambda (results)
         (message "Recompilation results: %s"
                  (mapconcat (lambda (result)
                               (concat (pop labels) " "
                                       (if (sly-compilation-result.successp result)
                                           "OK"
                                         "fail")))
                             results
                             ", ")))))))

(defun helm-sly-xref-recompile-debug1 (_candidate)
  "Recompile selected candidates with debug level 1."
  (helm-sly-xref-recompile nil 1))

(defun helm-sly-xref-recompile-debug2 (_candidate)
  "Recompile selected candidates with debug level 2."
  (helm-sly-xref-recompile nil 2))

(defun helm-sly-xref-recompile-debug3 (_candidate)
  "Recompile selected candidates with debug level 3."
  (helm-sly-xref-recompile nil 3))

(defun helm-sly-xref-recompile-speed1 (_candidate)
  "Recompile selected candidates with speed level 1."
  (helm-sly-xref-recompile nil -1))

(defun helm-sly-xref-recompile-speed2 (_candidate)
  "Recompile selected candidates with speed level 2."
  (helm-sly-xref-recompile nil -2))

(defun helm-sly-xref-recompile-speed3 (_candidate)
  "Recompile selected candidates with speed level 3."
  (helm-sly-xref-recompile nil -3))

(defun helm-sly-build-xref-source (xrefs)
  "Return a Helm source of XREFS."
  (helm-build-sync-source "Lisp xrefs"
    :candidates (helm-sly-normalize-xrefs xrefs)
    :candidate-transformer 'helm-sly-xref-transformer
    :action `(("Switch to buffer(s)" . helm-sly-xref-goto)
              ("Recompile" . helm-sly-xref-recompile)
              ("Recompile (debug 1)" . helm-sly-xref-recompile-debug1)
              ("Recompile (debug 2)" . helm-sly-xref-recompile-debug2)
              ("Recompile (debug 3)" . helm-sly-xref-recompile-debug3)
              ("Recompile (speed 1)" . helm-sly-xref-recompile-speed1)
              ("Recompile (speed 2)" . helm-sly-xref-recompile-speed2)
              ("Recompile (speed 3)" . helm-sly-xref-recompile-speed3))))

(defun helm-sly-show-xref-buffer (xrefs _type _symbol _package &optional _method)
  "Show XREFS.
See `sly-xref--show-results'."
  (helm :sources (list (helm-sly-build-xref-source xrefs))
        :buffer "*helm-sly-xref*"))

;;;###autoload
(define-minor-mode helm-sly-mode
  "Use Helm for Lisp xref selections.
Note that the local minor mode has a global effect, thus making
`global-helm-sly-mode' and `helm-sly-mode' equivalent."
  ;; TODO: Is it possible to disable the local minor mode?
  :init-value nil
  (let ((target 'sly-xref--show-results))
    ;; TODO: Weirdly enough, the advice seems to be ignored once in a while.
    ;; See https://github.com/joaotavora/sly/issues/408.
    (if (advice-member-p #'helm-sly-show-xref-buffer target)
        (advice-remove target #'helm-sly-show-xref-buffer)
      (advice-add target :override #'helm-sly-show-xref-buffer))))

;;;###autoload
(define-globalized-minor-mode global-helm-sly-mode
  helm-sly-mode
  helm-sly-mode
  :require 'helm-sly)

(provide 'helm-sly)
;;; helm-sly.el ends here
