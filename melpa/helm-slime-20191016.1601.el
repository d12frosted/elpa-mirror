;;; helm-slime.el --- helm-sources and some utilities for SLIME. -*- lexical-binding: t -*-

;; Copyright (C) 2009 Takeshi Banse <takebi@laafc.net>
;;               2012 Michael Markert <markert.michael@googlemail.com>
;;               2013 Thierry Volpiatto <thierry.volpiatto@gmail.com>
;;               2016 Syohei Yoshida <syohex@gmail.com>
;;               2018, 2019 Pierre Neidhardt <mail@ambrevar.xyz>
;; Author: Takeshi Banse <takebi@laafc.net>
;; URL: https://github.com/emacs-helm/helm-slime
;; Package-Version: 20191016.1601
;; Package-Commit: 7886cc49906a87ebd73be3b71f5dd6b1433a9b7b
;; Version: 0.4.0
;; Keywords: convenience, helm, slime
;; Package-Requires: ((emacs "25") (helm "3.2") (slime "2.18") (cl-lib "0.5"))

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
;; A Helm for SLIME.
;;
;; The complete command list:
;;
;;  `helm-slime-complete'
;;    Select a symbol from the SLIME completion systems.
;;  `helm-slime-list-connections'
;;    Yet another `slime-list-connections' with `helm'.
;;  `helm-slime-apropos'
;;    Yet another `slime-apropos' with `helm'.
;;  `helm-slime-repl-history'
;;    Select an input from the SLIME repl's history and insert it.
;;  `helm-slime-mini'
;;    Like `helm-slime-list-connections', but include an extra
;;    source of SLIME-related buffers, like the events buffer or the scratch buffer.

;;; Installation:
;;
;; Add helm-slime.el to your load-path.
;; Set up SLIME properly.
;; Call `slime-setup' and include 'helm-slime as the arguments:
;;
;;   (slime-setup '([others contribs ...] helm-slime))
;;
;; or simply require helm-slime in some appropriate manner.
;;
;; To use Helm instead of the Xref buffer, enable `global-helm-slime-mode'.

;;; Code:

(require 'helm)
(require 'helm-buffers)
(require 'slime)
(require 'slime-c-p-c)
(require 'slime-fuzzy)
(require 'slime-repl)
(require 'cl-lib)

(defvar helm-slime--complete-target "")

(defun helm-slime--insert (candidate)
  "Default action for `helm-slime-complete-type'."
  (let ((pt (point)))
    (when (and (search-backward helm-slime--complete-target nil t)
               (string= (buffer-substring (point) pt) helm-slime--complete-target))
      (delete-region (point) pt)))
  (insert candidate))

(cl-defun helm-slime--symbol-position-funcall
    (f &optional (end-pt (point)) (beg-pt (slime-symbol-start-pos)))
  (let* ((end (move-marker (make-marker) end-pt))
         (beg (move-marker (make-marker) beg-pt)))
    (unwind-protect
        (funcall f beg end)
      (set-marker end nil)
      (set-marker beg nil))))

(defclass helm-slime-complete-type (helm-source-in-buffer)
  ((action :initform '(("Insert" . helm-slime--insert)
                       ("Describe symbol" . slime-describe-symbol)
                       ("Edit definition" . slime-edit-definition)))
   (persistent-action :initform #'slime-describe-symbol)
   (volatile :initform t)
   (get-line :initform #'buffer-substring))
  "SLIME complete.")

(defun helm-slime--asc-init-candidates-buffer-base (complete-fn insert-fn)
  (let ((put-text-property1 (lambda (s)
                              (put-text-property (point-at-bol 0)
                                                 (point-at-eol 0)
                                                 'helm-realvalue
                                                 s))))
    (let* ((completion-result (with-current-buffer helm-current-buffer
                                (funcall complete-fn)))
           (completions (if (listp (cl-first completion-result))
                            (cl-first completion-result)
                          completion-result))
           (base  (slime-symbol-at-point)))
      (with-current-buffer (helm-candidate-buffer 'global)
        (funcall insert-fn completions base put-text-property1)))))

(defun helm-slime--asc-init-candidates-buffer-basic-insert-function (completions base put-text-property1)
  (let ((len (length base)))
    (dolist (c completions)
      (let ((start (point)))
        (insert c)
        (put-text-property start (+ start len) 'face 'bold)
        (insert "\n")
        (funcall put-text-property1 c)))))

(defun helm-slime--asc-simple-init ()
  (helm-slime--asc-init-candidates-buffer-base
   (slime-curry 'slime-simple-completions helm-slime--complete-target)
   'helm-slime--asc-init-candidates-buffer-basic-insert-function))

(defun helm-slime--asc-compound-init ()
  (helm-slime--asc-init-candidates-buffer-base
   (slime-curry 'helm-slime--symbol-position-funcall 'slime-contextual-completions)
   'helm-slime--asc-init-candidates-buffer-basic-insert-function))

(cl-defun helm-slime--asc-fuzzy-init (&optional
                                (insert-choice-fn
                                 'slime-fuzzy-insert-completion-choice))
  (helm-slime--asc-init-candidates-buffer-base
   (slime-curry 'slime-fuzzy-completions helm-slime--complete-target)
   (lambda (completions _ put-text-property1)
     (with-current-buffer (helm-candidate-buffer 'global)
       (let ((max-len (cl-loop for (x _) in completions maximize (length x))))
         (dolist (c completions)
           (funcall insert-choice-fn c max-len)
           (funcall put-text-property1 (car c))))))))

(defvar helm-slime-simple-complete-source
  (helm-make-source "SLIME simple complete" 'helm-slime-complete-type
    :init #'helm-slime--asc-simple-init))

(defvar helm-slime-compound-complete-source
  (helm-make-source "SLIME compound complete" 'helm-slime-complete-type
    :init #'helm-slime--asc-compound-init))

(defvar helm-slime-fuzzy-complete-source
  (helm-make-source "SLIME fuzzy complete" 'helm-slime-complete-type
    :init #'helm-slime--asc-fuzzy-init
    :fuzzy-match t))

(defvar helm-slime-complete-sources
  '(helm-slime-simple-complete-source
    helm-slime-fuzzy-complete-source
    helm-slime-compound-complete-source)
  "List of Helm sources used for completion.")

(defun helm-slime--helm-complete (sources target &optional limit input-idle-delay target-is-default-input-p)
  "Run Helm for completion."
  (let ((helm-candidate-number-limit (or limit helm-candidate-number-limit))
        (helm-input-idle-delay (or input-idle-delay helm-input-idle-delay))
        (helm-execute-action-at-once-if-one t)
        (helm-slime--complete-target target)
        (enable-recursive-minibuffers t)
        helm-full-frame)
    (helm :sources sources
          :input (if target-is-default-input-p target nil)
          :buffer "*helm complete*")))

;;;###autoload
(defun helm-slime-complete ()
  "Select a symbol from the SLIME completion systems."
  (interactive)
  (helm-slime--helm-complete helm-slime-complete-sources
                             (helm-slime--symbol-position-funcall
                              #'buffer-substring-no-properties)
                             nil nil t))

(defvar helm-slime-connections-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map helm-map)
    (define-key map (kbd "M-D") 'helm-slime-run-quit-connection)
    (define-key map (kbd "M-R") 'helm-slime-run-rename-connection-buffer)
    map)
  "Keymap for SLIME connection source in Helm.")

(defun helm-slime-go-to-repl (_candidate)
  "Switched to marked REPL(s)."
  (helm-window-show-buffers
   (cl-loop for c in (helm-marked-candidates)
            collect (let ((slime-dispatching-connection c))
                      (slime-output-buffer)))))
(put 'helm-slime-go-to-repl 'helm-only t)

(defun helm-slime-go-to-inferior (_candidate)
  "Switched to inferior Lisps associated with the marked connections."
  (helm-window-show-buffers
   (cl-loop for c in (helm-marked-candidates)
            collect (process-buffer (slime-process c)))))
(put 'helm-slime-go-to-inferior 'helm-only t)

(defun helm-slime-go-to-sldb (_candidate)
  "Switched to sldb buffers associated with the marked connections."
  (helm-window-show-buffers
   (cl-loop for c in (helm-marked-candidates)
            append (sldb-buffers c))))
(put 'helm-slime-go-to-sldb 'helm-only t)

(defun helm-slime-run-quit-connection ()
  "Run `helm-slime-quit-connections' action from `helm-slime--c-source-slime-connection'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-slime-quit-connections)))
(put 'helm-slime-run-quit-connection 'helm-only t)

(defun helm-slime-quit-connections (&optional _candidate)
  "Kill marked REPL(s) and their inferior Lisps."
  (dolist (c (helm-marked-candidates))
    (let ((slime-dispatching-connection c))
      (slime-repl-quit))))
(put 'helm-slime-quit-connections 'helm-only t)

(defun helm-slime-restart-connections (_candidate)
  "Restart marked REPLs' inferior Lisps."
  (dolist (c (helm-marked-candidates))
    (slime-restart-connection-at-point c)))
(put 'helm-slime-restart-connections 'helm-only t)

(defun helm-slime-run-rename-connection-buffer ()
  "Run `helm-slime-rename-connection-buffer' action from `helm-slime--c-source-slime-connection'."
  (interactive)
  (with-helm-alive-p
    (helm-exit-and-execute-action 'helm-slime-rename-connection-buffer)))
(put 'helm-slime-run-quit-connection 'helm-only t)

(defun helm-slime-rename-connection-buffer (_candidate)
  "Rename REPL buffer."
  (dolist (c (helm-marked-candidates))
    (let ((slime-dispatching-connection c))
      (with-current-buffer (slime-output-buffer)
        (rename-buffer (helm-read-string "New name: " (buffer-name)))))))
(put 'helm-slime-rename-connection-buffer 'helm-only t)

(defcustom helm-slime-connection-actions
  `(("Go to REPL" . helm-slime-go-to-repl)
    ("Set default" . slime-select-connection)
    ("Restart" . helm-slime-restart-connections)
    (,(substitute-command-keys "Rename REPL buffer \\<helm-slime-connections-map>`\\[helm-slime-run-rename-connection-buffer]'")
     . helm-slime-rename-connection-buffer)
    (,(substitute-command-keys "Quit \\<helm-slime-connections-map>`\\[helm-slime-run-quit-connection]'")
     . helm-slime-quit-connections)
    ("Go to inferior Lisp" . helm-slime-go-to-inferior)
    ("Go to sldb buffers" . helm-slime-go-to-sldb))
  "Actions for `helm-slime-list-connections`."
  :group 'helm-slime
  :type '(alist :key-type string :value-type function))

(defun helm-slime--connection-candidates ()
  (let* ((fstring "%s%2s  %-10s  %-17s  %-7s %-s %s")
         (collect (lambda (p)
                    (cons
                     (format fstring
                             (if (eq slime-default-connection p) "*" " ")
                             (slime-connection-number p)
                             (slime-connection-name p)
                             (or (process-id p) (process-contact p))
                             (slime-pid p)
                             (slime-lisp-implementation-type p)
                             (slime-connection-output-buffer p))
                     p))))
                  (mapcar collect (reverse slime-net-processes))))

(defun helm-slime--c-source-slime-connection ()
  (helm-build-sync-source "SLIME connections"
    :candidates (helm-slime--connection-candidates)
    :action helm-slime-connection-actions
    :keymap helm-slime-connections-map))

;;;###autoload
(defun helm-slime-list-connections ()
  "Yet another `slime-list-connections' with `helm'."
  (interactive)
  (helm :sources (list (helm-slime--c-source-slime-connection))
        :buffer "*helm-slime-list-connections*"))

(defun helm-slime--buffer-candidates ()
  "Collect SLIME related buffers, like the `events' buffer.
If the buffer does not exist, we use the associated function to generate it.

The list is in the (DISPLAY . REAL) form.  Because Helm seems to
require that REAL be a string, we need to (funcall (intern
\"function\")) in `helm-slime-switch-buffers' to generate the
buffer."
  (list (cons slime-event-buffer-name "slime-events-buffer")
        (cons slime-threads-buffer-name "slime-list-threads")
        (cons (slime-buffer-name :scratch) "slime-scratch-buffer")))

(defun helm-slime-switch-buffers (_candidate)
  "Switch to buffer candidates and replace current buffer.

If more than one buffer marked switch to these buffers in separate windows.
If a prefix arg is given split windows vertically."
  (helm-window-show-buffers
   (cl-loop for b in (helm-marked-candidates)
            collect (funcall (intern b)))))

(defun helm-slime-build-buffers-source ()
  (helm-build-sync-source "SLIME buffers"
    :candidates (helm-slime--buffer-candidates)
    :action `(("Switch to buffer(s)" . helm-slime-switch-buffers))))

(defun helm-slime-new-repl (name)
  "Fetch URL and render the page in a new buffer.
If the input doesn't look like an URL or a domain name, the
word(s) will be searched for via `eww-search-prefix'."
  ;; TODO: Set REPL buffer name to *slime-repl NAME*.
  ;; The following does not work.
  ;; (rename-buffer (format "*slime-repl %s*" name))
  (cl-flet ((slime-repl-buffer (&optional create _connection)
                               (funcall (if create #'get-buffer-create #'get-buffer)
                                        (format "*slime-repl %s*" ;; (slime-connection-name connection)
                                                name))))
    (slime)))

(defun helm-slime-new-repl-choose-lisp (name)
  "Fetch URL and render the page in a new buffer.
If the input doesn't look like an URL or a domain name, the
word(s) will be searched for via `eww-search-prefix'."
  (let ((current-prefix-arg '-))
    (helm-slime-new-repl name)))

(defvar helm-slime-new
  (helm-build-dummy-source "Open new REPL"
    :action (helm-make-actions
             "Open new REPL" 'helm-slime-new-repl
             "Open new REPL with chosen Lisp" 'helm-slime-new-repl-choose-lisp)))

(defun helm-slime-mini ()
  "Helm for SLIME connections and buffers."
  (interactive)
  (helm :sources (list (helm-slime--c-source-slime-connection)
                       helm-slime-new
                       (helm-slime-build-buffers-source))
        :buffer "*helm-slime-mini*"))

(defclass helm-slime-apropos-type (helm-source-sync)
  ((action :initform '(("Describe symbol" . slime-describe-symbol)
                       ("Edit definition" . slime-edit-definition)))
   (persistent-action :initform #'slime-describe-symbol)
   ;;(volatile :initform t)
   (requires-pattern :initform 2))
  "SLIME apropos.")

(defun helm-slime--apropos-source (name slime-expressions)
  "Build source that provides Helm completion against `slime-apropos'."
  (helm-make-source name 'helm-slime-apropos-type
    :candidates `(lambda ()
                   (with-current-buffer helm-current-buffer
                     (cl-loop for plist in (slime-eval ,slime-expressions)
                              collect (plist-get plist :designator))))))

(defvar helm-slime--c-source-slime-apropos-symbol-current-package
  (helm-slime--apropos-source "SLIME apropos (current package)"
                        (quote
                         `(swank:apropos-list-for-emacs
                           ,helm-pattern
                           nil
                           nil
                           ,(or slime-buffer-package
                                (slime-current-package))))))

(defvar helm-slime--c-source-slime-apropos-symbol-current-external-package
  (helm-slime--apropos-source "SLIME apropos (current external package)"
                        (quote
                         `(swank:apropos-list-for-emacs
                           ,helm-pattern
                           t
                           nil
                           ,(or slime-buffer-package
                                (slime-current-package))))))

(defvar helm-slime--c-source-slime-apropos-symbol-all-external-package
  (helm-slime--apropos-source "SLIME apropos (all external packages)"
                        (quote
                         `(swank:apropos-list-for-emacs
                           ,helm-pattern
                           t
                           nil
                           nil))))

(defvar helm-slime--c-source-slime-apropos-symbol-all-package
  (helm-slime--apropos-source "SLIME apropos (all packages)"
                        (quote
                         `(swank:apropos-list-for-emacs
                           ,helm-pattern
                           nil
                           nil
                           nil))))

(defvar helm-slime-apropos-sources
  '(helm-slime--c-source-slime-apropos-symbol-current-package
    helm-slime--c-source-slime-apropos-symbol-current-external-package
    helm-slime--c-source-slime-apropos-symbol-all-external-package
    helm-slime--c-source-slime-apropos-symbol-all-package)
  "List of Helm sources for `helm-slime-apropos'.")

;;;###autoload
(defun helm-slime-apropos ()
  "Yet another `slime-apropos' with `helm'."
  (interactive)
  (helm :sources helm-slime-apropos-sources
        :buffer "*helm SLIME apropos*"))

(defun helm-slime-repl-input-history-action (candidate)
  "Default action for `helm-slime-repl-history'."
  (slime-repl-history-replace 'backward
                              (concat "^" (regexp-quote candidate) "$")))

(defgroup helm-slime nil
  "SLIME for Helm."
  :group 'helm)

(defcustom helm-slime-history-max-offset 400
  "Max number of chars displayed per candidate in `helm-slime-repl-history'.
When `t', don't truncate candidate, show all.
By default it is approximatively the number of bits contained in five lines
of 80 chars each i.e 80*5.
Note that if you set this to nil multiline will be disabled, i.e you
will not have anymore separators between candidates."
  :type '(choice (const :tag "Disabled" t)
          (integer :tag "Max candidate offset"))
  :group 'helm-slime)

(defvar helm-slime-source-repl-input-history
  (helm-build-sync-source "REPL history"
    :candidates (lambda ()
                  (with-helm-current-buffer
                    slime-repl-input-history))
    :action 'helm-slime-repl-input-history-action
    :multiline 'helm-slime-history-max-offset)
  "Source that provides Helm completion against `slime-repl-input-history'.")

;;;###autoload
(defun helm-slime-repl-history ()
  "Select an input from the SLIME repl's history and insert it."
  (interactive)
  (cond
   ((derived-mode-p 'slime-mrepl-mode)
    (helm-comint-input-ring))
   ((derived-mode-p 'slime-repl-mode)
    (helm :sources 'helm-slime-source-repl-input-history
          :input (buffer-substring-no-properties (point) slime-repl-input-start-mark)
          :buffer "*helm SLIME history*"))))


(defun helm-slime-normalize-xrefs (xref-alist)
  "Like `slime-insert-xrefs' but return a formatted list of strings instead.
The strings are formatted as \"GROUP: LABEL\"."
  (cl-loop for (group . refs) in xref-alist
           append
           (cl-loop for (label location) in refs
                    collect
                    (list group label location))))

(defun helm-slime-xref-lineno (location)
  "Return 0 if there is location does not refer to a proper file."
  (or
   (ignore-errors

     (with-current-buffer (progn (slime-goto-location-buffer (nth 1 location))
                                 (current-buffer))
       (line-number-at-pos
        (car (alist-get :position (cdr location))))))
   0))

(defun helm-slime-xref-transformer (candidates)
  "Transform CANDIDATES (a list of (GROUP LABEL LOCATION))
to \"GROUP: LABEL\"."
  (cl-loop for (group label location) in candidates
           collect (cons (concat (propertize (abbreviate-file-name group)
                                             'face 'helm-grep-file)
                                 ":"
                                 (propertize
                                  (number-to-string (helm-slime-xref-lineno location))
                                  'face 'helm-grep-lineno)
                                 ":"
                                 (slime-one-line-ify label))
                         (list group label location))))

(defun helm-slime-xref-goto (candidate)
  (let ((location (nth 2 candidate)))
    (switch-to-buffer
     (save-window-excursion
       (slime-show-source-location location t 1)
       (slime-goto-location-buffer (nth 1 location))))))

(defun helm-slime-build-xref-source (xrefs)
  (helm-build-sync-source "SLIME xrefs"
    :candidates (helm-slime-normalize-xrefs xrefs)
    :candidate-transformer 'helm-slime-xref-transformer
    :action `(("Switch to buffer(s)" . helm-slime-xref-goto))))

(defun helm-slime-show-xref-buffer (xrefs _type _symbol _package)
  (helm :sources (list (helm-slime-build-xref-source xrefs))
        :buffer "*helm-slime-xref*"))

;;;###autoload
(define-minor-mode helm-slime-mode
  "Use Helm for SLIME xref selections.
Note that the local minor mode has a global effect, thus making
`global-helm-slime-mode' and `helm-slime-mode' equivalent."
  ;; TODO: Is it possible to disable the local minor mode?
  :init-value nil
  (if (advice-member-p 'helm-slime-show-xref-buffer 'slime-show-xref-buffer)
      (advice-remove 'slime-show-xref-buffer 'helm-slime-show-xref-buffer)
    (advice-add 'slime-show-xref-buffer :override 'helm-slime-show-xref-buffer)))

;;;###autoload
(define-globalized-minor-mode global-helm-slime-mode
  helm-slime-mode
  helm-slime-mode
  :require 'helm-slime)

(provide 'helm-slime)
;;; helm-slime.el ends here
