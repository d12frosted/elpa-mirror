;;; orgstrap.el --- Bootstrap an Org file using file local variables -*- lexical-binding: t -*-

;; Author: Tom Gillespie
;; URL: https://github.com/tgbugs/orgstrap
;; Package-Version: 20210926.2314
;; Package-Commit: b99455846908d007cf50ca1ef7093554dc3121a0
;; Keywords: lisp org org-mode bootstrap
;; Version: 1.3
;; Package-Requires: ((emacs "24.4"))

;;;; License and Commentary

;; License:
;; SPDX-License-Identifier: GPL-3.0-or-later

;;; Commentary:

;; orgstrap is a specification and tooling for bootstrapping Org files.

;; It allows Org files to describe their own requirements, and
;; define their own functionality, making them self-contained,
;; standalone computational artifacts, dependent only on Emacs,
;; or other implementations of the Org-babel protocol in the future.

;; orgstrap.el is an elisp implementation of the orgstrap conventions.
;; It defines a regional minor mode for `org-mode' that runs orgstrap
;; blocks.  It also provides `orgstrap-init' and `orgstrap-edit-mode'
;; to simplify authoring of orgstrapped files.  For more details see
;; README.org which is also the literate source for this orgstrap.el
;; file in the git repo at
;; https://github.com/tgbugs/orgstrap/blob/master/README.org
;; or whever you can find git:c1b28526ef9931654b72dff559da2205feb87f75

;; Code in an orgstrap block is usually meant to be executed directly by its
;; containing Org file.  However, if the code is something that will be reused
;; over time outside the defining Org file, then it may be better to tangle and
;; load the file so that it is easier to debug/xref functions.  The code in
;; this orgstrap.el file in particular is tangled for inclusion in one of the
;; *elpas so as to protect the orgstrap namespace and to make it eaiser to
;; use orgstrap in Emacs.

;; The license for the orgstrap.el code reflects the fact that the
;; code for expanding and hashing blocks reuses code from ob-core.el,
;; which at the time of writing is licensed as part of Emacs.

;;; Code:

(require 'org)

(require 'org-element)

(require 'cl-lib)

(defvar orgstrap-mode nil
  "Variable to track whether `orgstrap-mode' is enabled.")

(cl-eval-when (eval compile load)
  ;; prevent warnings since this is used as a variable in a macro
  (defvar orgstrap-orgstrap-block-name "orgstrap"
    "Set the default blockname to orgstrap by convention.
This makes it easier to search for orgstrap if someone encounters
an orgstrapped file and wants to know what is going on."))

(defvar orgstrap-default-cypher 'sha256
  "The default cypher passed to `secure-hash' when hashing blocks.")

(defvar-local orgstrap-cypher orgstrap-default-cypher
  "Local variable for the cypher for the current buffer.
If you change `orgstrap-default-cypher' you should update this as well
using `setq-default' since it will not change automatically.")
(put 'orgstrap-cypher 'safe-local-variable (lambda (v) (ignore v) t))

(defvar-local orgstrap-block-checksum nil
  "Local variable for the expected checksum for the current orgstrap block.")
;; `orgstrap-block-checksum' is not a safe local variable, if it is set
;; as safe then there will be no check and code will execute without a check
;; it is also not risky, so we leave it unmarked

(defconst orgstrap--internal-norm-funcs
  '(orgstrap-norm-func--prp-1.0
    orgstrap-norm-func--prp-1.1
    orgstrap-norm-func--dprp-1.0)
  "List internally implemented normalization functions.
Used to determine which norm func names are safe local variables.")

(defvar-local orgstrap-norm-func-name nil
  "Local variable for the name of the current orgstrap-norm-func.")
(put 'orgstrap-norm-func-name 'safe-local-variable
     (lambda (value) (and orgstrap-mode (memq value orgstrap--internal-norm-funcs))))
;; Unless `orgstrap-mode' is enabled and the name is in the list of
;; functions that are implemented internally this is not safe

(defvar-local orgstrap-norm-func #'orgstrap-norm-func--dprp-1.0
  "Dynamic variable to simplify calling normalizaiton functions.
Defaults to `orgstrap-norm-func--dprp-1.0'.")

(defvar orgstrap--debug nil
  "If non-nil run `orgstrap-norm' in debug mode.")

(defgroup orgstrap nil
  "Tools for bootstraping Org mode files using Org Babel."
  :tag "orgstrap"
  :group 'org
  :link '(url-link :tag "README on GitHub"
                   "https://github.com/tgbugs/orgstrap/blob/master/README.org"))

(defcustom orgstrap-always-edit nil
  "If non-nil command `orgstrap-mode' activates command `orgstrap-edit-mode'."
  :type 'boolean
  :group 'orgstrap)

(defcustom orgstrap-always-eval nil
  "Always try to run orgstrap blocks even when populating `org-agenda'."
  :type 'boolean
  :group 'orgstrap)

(defcustom orgstrap-always-eval-whitelist nil
  "List of files that should always try to run orgstrap blocks."
  :type 'list
  :group 'orgstrap)

(defcustom orgstrap-file-blacklist nil
  "List of files that should never run orgstrap blocks.

For files on the blacklist `orgstrap-block-checksum' is removed from
the local variables list so that the checksum will not be added to
the `safe-local-variable-values' list.  If it were added it would then
be impossible to prevent execution of the source block when `orgstrap-mode'
is disabled.

This is useful when developing a block that modifies Emacs' configuration.
NOTE this variable only works if `orgstrap-mode' is enabled."
  :type 'list
  :group 'orgstrap)

;; orgstrap blacklist

(defun orgstrap-blacklist-current-file (&optional universal-argument)
  "Add the current file to `orgstrap-file-blacklist'.
If UNIVERSAL-ARGUMENT is provided do not run `orgstrap-revoke-current-buffer'."
  ;; It is usually better to revoke a checksum when its file is blacklisted since
  ;; it is easier for the user to add the checksum again when needed than it is
  ;; for them to revoke manually. The prefix argument allows users who know that
  ;; they only want to blacklist the file and not revoke to do so though such
  ;; cases are expected to be fairly rare.

  ;; FIXME blacklisting a bad file that has already been approved is painful
  ;; right now, you have to manually set `enable-local-eval' to nil, load the
  ;; file, run this function, and then reset `enable-local-eval'.
  (interactive "P")
  (unless universal-argument
    (orgstrap-revoke-current-buffer))
  (add-to-list 'orgstrap-file-blacklist (buffer-file-name))
  (customize-save-variable 'orgstrap-file-blacklist orgstrap-file-blacklist))

(defun orgstrap-unblacklist-current-file ()
  "Remove the current file from `orgstrap-file-blacklist'."
  (interactive)
  (setq orgstrap-file-blacklist (delete (buffer-file-name) orgstrap-file-blacklist))
  (customize-save-variable 'orgstrap-file-blacklist orgstrap-file-blacklist))

;; orgstrap revoke

(defun orgstrap-revoke-checksums (&rest checksums)
  "Delete CHECKSUMS or all checksums if nil from `safe-local-variables-values'."
  (interactive)
  (cl-delete-if (lambda (pair)
                  (cl-destructuring-bind (key . value)
                      pair
                    (and
                     (eq key 'orgstrap-block-checksum)
                     (or (null checksums) (memq value checksums)))))
                safe-local-variable-values)
  (customize-save-variable 'safe-local-variable-values safe-local-variable-values))

(defun orgstrap-revoke-current-buffer ()
  "Delete checksum(s) for current buffer from `safe-local-variable-values'.
Deletes embedded and current values of `orgstrap-block-checksum'."
  (interactive)
  (let* ((elv (orgstrap--read-current-local-variables))
         (cpair (assoc 'orgstrap-block-checksum elv))
         (checksum-existing (and cpair (cdr cpair))))
    (orgstrap-revoke-checksums orgstrap-block-checksum checksum-existing)))

(defun orgstrap-revoke-elvs ()
  "Delete all approved orgstrap elvs from `safe-local-variable-values'."
  (interactive)
  (cl-delete-if #'orgstrap--match-elvs safe-local-variable-values)
  (customize-save-variable 'safe-local-variable-values safe-local-variable-values))

(define-obsolete-function-alias
  'orgstrap-revoke-eval-local-variables
  #'orgstrap-revoke-elvs
  "1.2.4"
  "Replaced by the more compact `orgstrap-revoke-elvs'.")

;; orgstrap run helpers

;;;###autoload
(defun orgstrap--confirm-eval-portable (lang _body)
  "A backwards compatible, portable implementation for confirm-eval.
This should be called by `org-confirm-babel-evaluate'.  As implemented
the only LANG that is supported is emacs-lisp or elisp.  The argument
_BODY is rederived for portability and thus not used."
  ;; `org-confirm-babel-evaluate' will prompt the user when the value
  ;; that is returned is non-nil, therefore we negate positive matchs
  (not (and (member lang '("elisp" "emacs-lisp"))
            (let* ((body (orgstrap--expand-body (org-babel-get-src-block-info)))
                   (body-normalized (orgstrap-norm body))
                   (content-checksum
                    (intern
                     (secure-hash
                      orgstrap-cypher
                      body-normalized))))
              ;;(message "%s %s" orgstrap-block-checksum content-checksum)
              ;;(message "%s" body-normalized)
              (eq orgstrap-block-checksum content-checksum)))))
;; portable eval is used as the default implementation in orgstrap.el
;;;###autoload
(unless (fboundp #'orgstrap--confirm-eval)
  (defalias 'orgstrap--confirm-eval #'orgstrap--confirm-eval-portable))

;; orgstrap-mode implementation

(defun orgstrap--org-buffer ()
  "Only run when in `org-mode' and command `orgstrap-mode' is enabled.
Sets further hooks."
  (when enable-local-eval
    ;; if `enable-local-eval' is nil we honor it and will not run
    ;; orgstrap blocks natively, this matches the behavior of the
    ;; embedded elvs and simplifies logic for cases
    ;; where orgstrap should not run (e.g. when populating `org-agenda')
    (advice-add #'hack-local-variables-confirm :around #'orgstrap--hack-lv-confirm)
    (unless (member (buffer-file-name) orgstrap-file-blacklist)
      (add-hook 'before-hack-local-variables-hook #'orgstrap--before-hack-lv nil t))))

(defun orgstrap--hack-lv-confirm (command &rest args)
  "Advise `hack-local-variables-confirm' to remove orgstrap eval variables.
COMMAND should be `hack-local-variables-confirm' with ARGS (all-vars
unsafe-vars risky-vars dir-name)."
  (advice-remove #'hack-local-variables-confirm #'orgstrap--hack-lv-confirm)
  (cl-destructuring-bind (all-vars unsafe-vars risky-vars dir-name)
      (cl-loop
       for arg in
       (if (member (buffer-file-name) orgstrap-file-blacklist)
           (cl-loop ; zap checksums for blacklisted
            for arg in args collect
            (if (listp arg)
                (cl-delete-if
                 (lambda (pair) (eq (car pair) 'orgstrap-block-checksum))
                 arg)
              arg))
         args)
       collect ; use `cl-delete-if' to mutate the lists in calling scope
       (if (listp arg) (cl-delete-if #'orgstrap--match-elvs arg) arg))
    ;; After removal we have to recheck to see if unsafe-vars and
    ;; risky-vars are empty so we can skip the confirm dialogue. If we
    ;; do not, then the dialogue breaks the flow.
    (or (and (null unsafe-vars)
             (null risky-vars))
        (funcall command all-vars unsafe-vars risky-vars dir-name))))

(defun orgstrap--before-hack-lv ()
  "If `orgstrap' is in the current buffer, add hook to run the orgstrap block."
  ;; This approach is safer than trying to introspect some of the implementation
  ;; internals. This hook will only run if there are actually local variables to
  ;; hack, so there is little to no chance of lingering hooks if an error occures
  (remove-hook 'before-hack-local-variables-hook #'orgstrap--before-hack-lv t)
  ;; XXX we have to remove elvs here since `hack-local-variables-confirm' is not called
  ;; if all variables are marked as safe, e.g. via `orgstrap-whitelist-file'
  ;; FIXME other interactions between blacklist and whitelist may need to be handled here
  (setq file-local-variables-alist (cl-delete-if #'orgstrap--match-elvs file-local-variables-alist))
  (add-hook 'hack-local-variables-hook #'orgstrap--hack-lv nil t))

(defun orgstrap--used-in-current-buffer-p ()
  "Return t if all the required orgstrap prop line local variables are present."
  (and (boundp 'orgstrap-cypher) orgstrap-cypher
       (boundp 'orgstrap-block-checksum) orgstrap-block-checksum
       (boundp 'orgstrap-norm-func-name) orgstrap-norm-func-name))

(defmacro orgstrap--lv-common-with-block-name ()
  "Helper macro to allow use of same code between core and lv impls."
  `(progn
     (let (enable-local-eval) (vc-find-file-hook)) ; use the obsolete alias since it works in 24
     (let ((ocbe org-confirm-babel-evaluate)
           (obs (org-babel-find-named-block ,orgstrap-orgstrap-block-name))) ; quasiquoted when nowebbed
       (if obs
           (unwind-protect
               (save-excursion
                 (setq-local orgstrap-norm-func orgstrap-norm-func-name)
                 (setq-local org-confirm-babel-evaluate #'orgstrap--confirm-eval)
                 (goto-char obs) ; FIXME `org-save-outline-visibility' but that is not portable
                 (org-babel-execute-src-block))
             (when (eq org-confirm-babel-evaluate #'orgstrap--confirm-eval)
               ;; XXX allow orgstrap blocks to set ocbe so audit for that
               (setq-local org-confirm-babel-evaluate ocbe))
             (org-set-visibility-according-to-property))
         ;; FIXME warn or error here?
         (warn "No orgstrap block.")))))

(defun orgstrap--hack-lv ()
  "If orgstrap is present, run the orgstrap block for the current buffer."
  ;; we remove this hook here and we do not have to worry because
  ;; it is always added by `orgstrap--before-hack-lv'
  (remove-hook 'hack-local-variables-hook #'orgstrap--hack-lv t)
  (when (orgstrap--used-in-current-buffer-p)
    (orgstrap--lv-common-with-block-name)
    (when orgstrap-always-edit
      (orgstrap-edit-mode 1))))

(defun orgstrap--match-elvs (pair)
  "Return nil if PAIR matchs any elv used by orgstrap.
Avoid false positives if possible if at all possible."
  (and (eq (car pair) 'eval)
       ;;(message "%s" (cdr pair))
       ;; keep the detection simple for now, any eval lv that
       ;; so much as mentions orgstrap is nuked, and in the future
       ;; if orgstrap-nb is used we may need to nuke that too
       (string-match "orgstrap" (prin1-to-string (cdr pair)))))

;;;###autoload
(defun orgstrap-mode (&optional arg)
  "A regional minor mode for `org-mode' that automatically runs orgstrap blocks.
When visiting an Org file or activating `org-mode', if orgstrap prop line local
variables are detect then use the installed orgstrap implementation to run the
orgstrap block.  If orgstrap embedded local variables are present, they will not
be executed.  `orgstrap-mode' is not a normal minor mode since it does not run
any hooks and when enabled only adds a function to `org-mode-hook'.  ARG is the
universal prefix argument."
  (interactive "P")
  (ignore arg)
  (let ((turn-on (not orgstrap-mode)))
    (cond (turn-on
           (add-hook 'org-mode-hook #'orgstrap--org-buffer)
           (setq orgstrap-mode t)
           (message "orgstrap-mode enabled"))
          (arg) ; orgstrap-mode already enabled so don't disable it
          (t
           (remove-hook 'org-mode-hook #'orgstrap--org-buffer)
           (setq orgstrap-mode nil)
           (message "orgstrap-mode disabled")))))

;; orgstrap do not run aka `org-agenda' eval protection

(defun orgstrap--advise-no-eval-lv (command &rest args)
  "Advise COMMAND to disable elvs for files loaded inside it.
ARGS vary by COMMAND.

If the elvs are disabled then `orgstrap-block-checksum' is added
to the `ignored-local-variables' list for files loaded inside
COMMAND.  This makes it possible to open orgstrapped files where
the elvs will not run without having to accept the irrelevant
variable for `orgstrap-block-checksum'."
  ;; continually prompting users to accept a local variable when they
  ;; cannot inspect the file and when accidentally accepting could
  ;; allow unchecked execution at some point in the future is bad
  ;; better to simply pretend that the elvs and the block checksum
  ;; do not even exist unless the file is explicitly on a whitelist

  ;; orgstrapped files are just plain old org files in this context
  ;; since agenda doesn't use any babel functionality ... of course
  ;; I can totally imagine using orgstrap to automatically populate
  ;; an org file or update an org file using orgstrap to keep the
  ;; agenda in sync with some external source ... so need a variable
  ;; to control this
  (if orgstrap-always-eval
      (apply command args)
    (let* ((enable-local-eval
            (and args
                 orgstrap-always-eval-whitelist
                 (member (car args)
                         orgstrap-always-eval-whitelist)
                 enable-local-eval))
           (ignored-local-variables
            (if enable-local-eval ignored-local-variables
              (cons 'orgstrap-block-checksum ignored-local-variables))))
      (apply command args))))

(advice-add #'org-get-agenda-file-buffer :around #'orgstrap--advise-no-eval-lv)

;;; dev helpers

(defcustom orgstrap-developer-checksums-file (concat user-emacs-directory "orgstrap-developer-checksums.el")
  "Path to developer checksums file."
  :type 'path
  :group 'orgstrap)

(defcustom orgstrap-save-developer-checksums nil ; FIXME naming
  "Whether or not to save checksums of orgstrap blocks under development."
  :type 'boolean
  :group 'orgstrap
  :set (lambda (variable value)
         (set-default variable value)
         (if value
             (add-hook 'orgstrap-on-change-hook #'orgstrap-save-developer-checksums)
           (remove-hook 'orgstrap-on-change-hook #'orgstrap-save-developer-checksums))))

(defvar orgstrap-developer-checksums nil ; not custom because it is saved elsewhere
  "List of checksums for orgstrap blocks created or modified by the user.")

(defun orgstrap--pp-to-string (value)
  "Ensure that we actually print the whole VALUE not just the summarized subset."
  (let (print-level print-length)
    (pp-to-string value)))

(defun orgstrap-revoke-developer-checksums (&optional universal-argument)
  "Remove all saved developer checksums.  UNIVERSAL-ARGUMENT is a placeholder."
  (interactive "P") (ignore universal-argument)
  (setq orgstrap-developer-checksums nil)
  (orgstrap-save-developer-checksums t))

(defun orgstrap-save-developer-checksums (&optional overwrite)
  "Function to update `orgstrap-developer-checksums-file'.
If OVERWRITE is non-nil then overwrite the existing checksums."
  (interactive "P")
  (if orgstrap-save-developer-checksums
      (let* ((checksums orgstrap-developer-checksums)
             (buffer (find-file-noselect orgstrap-developer-checksums-file)))
        (with-current-buffer buffer
          (unwind-protect
              (progn
                (lock-buffer)
                (let* ((saved (and (not (= (buffer-size) 0)) (cadr (nth 2 (read (buffer-string))))))
                       ;; XXX NOTE saved is not used to updated `orgstrap-developer-checksums' here
                       ;; FIXME massively inefficient
                       (combined (or (and (not overwrite)
                                          (cl-remove-duplicates (append checksums saved)))
                                     checksums)))
                  ;; TODO do we need to check whether combined and saved are different?
                  ;; (message "checksums: %s\nsaved: %s\ncombined: %s" checksums saved combined)
                  (erase-buffer)
                  (insert ";;; -*- mode: emacs-lisp; lexical-binding: t -*-\n")
                  (insert ";;; DO NOT EDIT THIS FILE IT IS AUTOGENERATED AND WILL BE OVERWRITTEN!\n\n")
                  (insert (string-replace
                           " " "\n"
                           (orgstrap--pp-to-string `(setq orgstrap-developer-checksums ',combined))))
                  (insert "\n;;; set developer checksums as safe local variables\n\n")
                  (insert
                   (orgstrap--pp-to-string
                    '(mapcar (lambda (checksum-value)
                               (add-to-list 'safe-local-variable-values
                                            (cons 'orgstrap-block-checksum checksum-value)))
                             orgstrap-developer-checksums)))
                  (pp-buffer)
                  (indent-region (point-min) (point-max))
                  (save-buffer)))
            (unlock-buffer)
            (kill-buffer))))
    (warn "No checksums were saved because `orgstrap-save-developer-checksums' is not set.")))


;;; edit helpers
(defvar orgstrap--clone-stamp-source-buffer-block nil
  "Source code buffer and block for `orgstrap-stamp'.")

(defcustom orgstrap-on-change-hook nil
  "Hook run via `before-save-hook' when command `orgstrap-edit-mode' is enabled.
Only runs when the contents of the orgstrap block have changed."
  :type 'hook
  :group 'orgstrap)

(defcustom orgstrap-use-minimal-local-variables nil
  "Set whether minimal, smaller but less portable variables are used.
If nil then backward compatible local variables are used instead.
If the value is customized to be non-nil then compact local variables
are used and `orgstrap-min-org-version' is set accordingly.  If the
current version of org mode does not support the features required to
use the minimal variables then the portable variables are used instead."
  :type 'boolean
  :group 'orgstrap)

;; edit utility functions
(defun orgstrap--current-buffer-cypher ()
  "Return the cypher used for the current buffer.
The value is `orgstrap-cypher' if it is bound otherwise
`orgstrap-default-cypher' is returned."
  (if (boundp 'orgstrap-cypher) orgstrap-cypher orgstrap-default-cypher))

(defun orgstrap-org-src-coderef-regexp (_fmt &optional label)
  "Backport `org-src-coderef-regexp' for 24 and 25.
See the upstream docstring for info on LABEL.
_FMT has the wrong meaning in 24 and 25."
  (let ((fmt org-coderef-label-format))
    (format "\\([:blank:]*\\(%s\\)[:blank:]*\\)$"
            (replace-regexp-in-string
             "%s"
             (if label
                 (regexp-quote label)
               "\\([-a-zA-Z0-9_][-a-zA-Z0-9_ ]*\\)")
             (regexp-quote fmt)
             nil t))))
(unless (fboundp #'org-src-coderef-regexp)
  (defalias 'org-src-coderef-regexp #'orgstrap-org-src-coderef-regexp))
(defun orgstrap--expand-body (info)
  "Expand noweb references in INFO body and remove any coderefs."
  ;; this is a backport of `org-babel--expand-body'
  (let ((coderef (nth 6 info))
        (expand
         (if (org-babel-noweb-p (nth 2 info) :eval)
             (org-babel-expand-noweb-references info)
           (nth 1 info))))
    (if (not coderef)
        expand
      (replace-regexp-in-string
       (org-src-coderef-regexp coderef) "" expand nil nil 1))))

(defun orgstrap-norm (body)
  "Normalize BODY."
  (if orgstrap--debug
      (orgstrap-norm-debug body)
    (funcall orgstrap-norm-func body)))

(defun orgstrap-norm-debug (body)
  "Insert BODY normalized with NORM-FUNC into a buffer for easier debug."
  (let* ((print-quoted nil)
         (bname (format "body-norm-%s" emacs-major-version))
         (buffer (let ((existing (get-buffer bname)))
                   (if existing existing
                     (create-file-buffer bname))))
         (body-normalized (funcall orgstrap-norm-func body)))
    (with-current-buffer buffer
      (erase-buffer)
      (insert body-normalized))
    body-normalized))

;; orgstrap normalization functions

(defun orgstrap-norm-func--dprp-1.0 (body)
  "Normalize BODY using dprp-1.0."
  (let ((p (read (concat "(progn\n" body "\n)")))
        (m '(defun defun-local defmacro defvar defvar-local defconst defcustom))
        print-quoted print-length print-level)
    (cl-labels
        ((f
          (b)
          (cl-loop
           for e in b when (listp e) do ; for expression in body when the expression is a list
           (or
            (and
             (memq (car e) m) ; is a form with docstrings
             (let ((n (nthcdr 4 e))) ; body after docstring
               (and
                (stringp (nth 3 e)) ; has a docstring
                (or (cl-subseq m 3) n) ; var or doc not last
                (f n) ; recurse for nested
                ;; splice out the docstring and return t to avoid the other branch
                (or (setcdr (cddr e) n) t))))
            ;; recurse e.g. for (when x (defvar y t))
            (f e)))
          p))
      (prin1-to-string (f p)))))

(defun orgstrap-norm-func--prp-1.1 (body)
  "Normalize BODY using prp-1.1."
  (let (print-quoted print-length print-level)
    (prin1-to-string (read (concat "(progn\n" body "\n)")))))

(defun orgstrap-norm-func--prp-1.0 (body)
  "Normalize BODY using prp-1.0."
  (let ((print-quoted nil))
    (prin1-to-string (read (concat "(progn\n" body "\n)")))))
(make-obsolete #'orgstrap-norm-func--prp-1.0 #'orgstrap-norm-func--prp-1.1 "1.2")


(defun orgstrap--goto-named-src-block (blockname)
  "Goto org block named BLOCKNAME.
Like `org-babel-goto-named-src-block' but non-interactive, does
not use the mark ring, and errors if the block is not found."
  (let ((obs (org-babel-find-named-block blockname)))
    (if obs (goto-char obs)
      (error "No block named %s" blockname))))

(defmacro orgstrap--with-block (blockname &rest macro-body)
  "Go to the source block named BLOCKNAME and execute MACRO-BODY.
The macro provides local bindings for four names:
`info', `params', `body-unexpanded', and `body'."
  (declare (indent defun))
  `(save-excursion
     (let* ((info
             (org-save-outline-visibility 'use-markers
               (orgstrap--goto-named-src-block ,blockname)
               (org-babel-get-src-block-info)))
            (params (nth 2 info))
            (body-unexpanded (nth 1 info))
            (body (orgstrap--expand-body info)))
       ,@macro-body)))

(defun orgstrap--update-on-change ()
  "Run via the `before-save-hook' local variable.
Test if the checksum of the orgstrap block has changed,
if so update the `orgstrap-block-checksum' local variable
and then run `orgstrap-on-change-hook'."
  (let* ((elv (orgstrap--read-current-local-variables))
         (cpair (assoc 'orgstrap-block-checksum elv))
         (checksum-existing (and cpair (cdr cpair)))
         (checksum (orgstrap-get-block-checksum)))
    (unless (eq checksum-existing (intern checksum))
      (remove-hook 'before-save-hook #'orgstrap--update-on-change t)
      ;; for some reason tangling from a buffer counts as saving from that buffer
      ;; so have to remove the hook to avoid infinite loop
      (unwind-protect
          (save-excursion
            (undo)
            (undo-boundary) ; insert an undo boundary so that the
            ;; changes to the checksum are transparent to the user
            (undo) ; undo the undo above
            (orgstrap-add-block-checksum nil checksum)
            (run-hooks 'orgstrap-on-change-hook))
        (add-hook 'before-save-hook #'orgstrap--update-on-change nil t)))))

(defun orgstrap--get-actual-params (params)
  "Filter defaults, nulls, and junk from src block PARAMS."
  (let ((defaults (append org-babel-default-header-args
                          org-babel-default-header-args:emacs-lisp)))
    (cl-remove-if (lambda (pair)
                    (or (member pair defaults)
                        (memq (car pair) '(:result-params :result-type))
                        (null (cdr pair))))
                  params)))

(defun orgstrap-header-source-element (header-name &optional block-name &rest more-names)
  "Given HEADER-NAME find the element that provides its value.
If BLOCK-NAME is non-nil then search for headers for that block,
otherwise search for headers associated with the current block.
If MORE-NAMES are provided return the value for each (or nil)."
  ;; get the current headers, see if the value is set anywhere
  ;; or if it is default, search for default anyway just to be sure
  ;; return nil if not found
  ;; when searching for any header go to the end of the src line
  ;; `re-search-backward' from that point for :header-arg but not
  ;; going beyond the affiliated keywords for the current element
  ;; (if you can get affiliated keywords for the current element
  ;; that might simplify the search as well? check the impl for how
  ;; the actual values are obtained during execution etc)
  ;; when found use `org-element-at-point' to obtain the element

  ;; in another function the operates on the element
  ;; the element will give start, end, value, etc.
  ;; find bounds of value from element or sub element
  ;; delete the value, replace with new value
  (ignore header-name block-name more-names)
  (error "Not implemented TODO"))

(defun orgstrap-update-src-block-header (name new-params &optional update)
  "Add header arguments to block NAME from NEW-PARAMS from some other block.
Existing header arguments will NOT be removed if they are not included in
NEW-PARAMS.  If UPDATE is non-nil existing header arguments are updated."
  (let ((new-act-params (orgstrap--get-actual-params new-params)))
    (orgstrap--with-block name
      (ignore body body-unexpanded)
      (let ((existing-act-params (orgstrap--get-actual-params params)))
        (dolist (pair new-act-params)
          (cl-destructuring-bind (key . value)
              pair
            (let ((header-arg (substring (symbol-name key) 1)))
              (if (assq key existing-act-params)
                  (if update
                      (unless (member pair existing-act-params)
                        ;; TODO remove existing
                        ;; `org-babel-insert-header-arg' does not remove
                        ;; and it is not trivial to find the actual location
                        ;; of an existing header argument there are 4 places
                        ;; that we will have to look and then in some cases
                        ;; we will have to append even if we do find them
                        (org-babel-insert-header-arg header-arg value)
                        ;; This message works around the fact that we don't
                        ;; have replace here, only append TODO consider
                        ;; changing the way update works to be nil, replace,
                        ;; or append once an in-place replace is implemented
                        (message "%s superseded for block %s." key name))
                    (warn "%s already defined for block %s!" key name))
                (org-babel-insert-header-arg header-arg value)))))))))

;; edit user facing functions
(defun orgstrap-get-block-checksum (&optional cypher)
  "Calculate the `orgstrap-block-checksum' for the current buffer using CYPHER."
  (interactive)
  (orgstrap--with-block orgstrap-orgstrap-block-name
    (ignore params body-unexpanded)
    (let ((cypher (or cypher (orgstrap--current-buffer-cypher)))
          (body-normalized (orgstrap-norm body)))
      (secure-hash cypher body-normalized))))

(defun orgstrap-add-block-checksum (&optional cypher checksum)
  "Add `orgstrap-block-checksum' to file local variables of `current-buffer'.

The optional CYPHER argument should almost never be used,
instead change the value of `orgstrap-default-cypher' or manually
change the file property line variable.  CHECKSUM can be passed
directly if it has been calculated before and only needs to be set.

If `orgstrap-save-developer-checksums' is non-nil then add the checksum to
`orsgrap-developer-checksums'."
  (interactive)
  (let* ((cypher (or cypher (orgstrap--current-buffer-cypher)))
         (orgstrap-block-checksum (or checksum (orgstrap-get-block-checksum cypher))))
    (when orgstrap-block-checksum
      (save-excursion
        (add-file-local-variable-prop-line 'orgstrap-cypher         cypher)
        (add-file-local-variable-prop-line 'orgstrap-norm-func-name orgstrap-norm-func)
        (add-file-local-variable-prop-line 'orgstrap-block-checksum (intern orgstrap-block-checksum)))
      (when orgstrap-save-developer-checksums
        (add-to-list 'orgstrap-developer-checksums (intern orgstrap-block-checksum))))
    orgstrap-block-checksum))

(defun orgstrap-run-block ()
  "Evaluate the orgstrap block for the current buffer."
  ;; bind to :orb or something like that
  (interactive)
  (save-excursion
    (orgstrap--goto-named-src-block orgstrap-orgstrap-block-name)
    (org-babel-execute-src-block)))

(defun orgstrap-clone (&optional universal-argument)
  "Set current block or orgstrap block as the source for `orgstrap-stamp'.
If a UNIVERSAL-ARGUMENT is supplied then the orgstrap block is always used."
  ;; TODO consider whether to avoid the inversion of behavior around C-u
  ;; namely that nil -> always from orgstrap block, C-u -> current block
  ;; this would avoid confusion where unprefixed could produce both
  ;; behaviors and only switch when already on a src block
  (interactive "P")
  (let ((current-element (org-element-at-point))
        (current-buffer (current-buffer)))
    (if (and (eq (org-element-type current-element) 'src-block)
             (not universal-argument))
        (let ((block-name (org-element-property :name current-element)))
          (if block-name
              (setq orgstrap--clone-stamp-source-buffer-block
                    (cons current-buffer block-name))
            (warn "The current block has no name, it cannot be a clone source!")))
      (if (orgstrap--used-in-current-buffer-p)
          (setq orgstrap--clone-stamp-source-buffer-block
                (cons current-buffer orgstrap-orgstrap-block-name))
        (warn "orgstrap is not used in the current buffer!")))))

(defun orgstrap-stamp (&optional universal-argument overwrite)
  "Stamp orgstrap block via `orgstrap-clone' to current buffer.
If UNIVERSAL-ARGUMENT is '(16) aka (C-u C-u) this will OVERWRITE any existing
block.  If you are not calling this interactively all as (orgstrap-stamp nil t)
for calirty.  You cannot stamp an orgstrap block into its own buffer."
  (interactive "P")
  (unless (eq major-mode 'org-mode)
    (user-error "`orgstrap-stamp' only works in org-mode buffers"))
  (unless orgstrap--clone-stamp-source-buffer-block
    (user-error "No value to clone!  Use `orgstrap-clone' first"))
  (let ((overwrite (or overwrite (equal universal-argument '(16))))
        (source-buffer (car orgstrap--clone-stamp-source-buffer-block))
        (source-block-name (cdr orgstrap--clone-stamp-source-buffer-block))
        (target-buffer (current-buffer)))
    (when (eq source-buffer target-buffer)
      (error "Source and target are the same buffer.  Not stamping!"))
    (cl-destructuring-bind (source-body
                            source-params
                            org-adapt-indentation
                            org-edit-src-content-indentation)
        (save-window-excursion
          (with-current-buffer source-buffer
            (orgstrap--with-block source-block-name
              (ignore body-unexpanded)
              (list body
                    params
                    org-adapt-indentation
                    org-edit-src-content-indentation))))
      (if (and (not overwrite)
               (member orgstrap-orgstrap-block-name
                       (org-babel-src-block-names)))
          (warn "orgstrap block already exists not stamping!")
        (orgstrap--add-orgstrap-block source-body) ; FIXME somehow the hash is different !?!??!
        (orgstrap-update-src-block-header orgstrap-orgstrap-block-name source-params t)
        (orgstrap-add-block-checksum) ; I think it is correct to add the checksum here
        (message "Stamped orgsrap block from %s" (buffer-file-name source-buffer))))))

;;;###autoload
(define-minor-mode orgstrap-edit-mode
  "Minor mode for editing with orgstrapped files."
  :init-value nil :lighter "" :keymap nil
  (unless (eq major-mode 'org-mode)
    (setq orgstrap-edit-mode 0)
    (user-error "`orgstrap-edit-mode' only works with org-mode buffers"))

  (cond (orgstrap-edit-mode
         (add-hook 'before-save-hook #'orgstrap--update-on-change nil t))
        (t
         (remove-hook 'before-save-hook #'orgstrap--update-on-change t))))

;;; init helpers
(defvar orgstrap-link-message "jump to the orgstrap block for this file"
  "Default message for file internal links.")

(defvar-local orgstrap--local-variables nil
  "Variable to capture local variables from `hack-local-variables'.")

;; local variable generation functions

(defun orgstrap--get-min-org-version (info minimal)
  "Get minimum org mode version needed by the orgstrap block for this file.
INFO is the source block info.  MINIMAL sets whether to use minimal local vars."
  (if minimal
      (let ((coderef (or (nth 6 info) org-coderef-label-format))
            (noweb (org-babel-noweb-p (nth 2 info) :eval)))
        (if noweb
            "9.3.8"
          (let* ((body (or (nth 1 info) ""))
                 (crrx (org-src-coderef-regexp coderef))
                 (pos (string-match crrx body))
                 (commented
                  (and pos (string-match
                            (concat (rx ";" (zero-or-more whitespace)) crrx) body))))
            ;; FIXME the right way to do this is similar to what is done in
            ;; `org-export-resolve-coderef' but for now we know we are in elisp
            (if (or (not pos) commented)
                "8.2.10"
              "9.3.8"))))
    "8.2.10"))

(defun orgstrap--have-min-org-version (info minimal)
  "See if current version of org meets minimum requirements for orgstrap block.
INFO is the source block info.
MINIMAL is passed to `orgstrap--get-min-org-version'."
  (let ((actual (org-version))
        (need (orgstrap--get-min-org-version info minimal)))
    (or (not need)
        (string< need actual)
        (string= need actual))))

(defun orgstrap--dedoc (sexp)
  "Remove docstrings from SEXP.  WARNING mutates sexp!"
  (let ((m '(defun defun-local defmacro defvar defvar-local defconst defcustom)))
    (cl-loop
     for e in sexp when (listp e) do ; for expression in sexp when the expression is a list
     (or
      (and
       (memq (car e) m) ; is a form with docstrings
       (let ((n (nthcdr 4 e))) ; body after docstring
         (and
          (stringp (nth 3 e)) ; has a docstring
          (or (cl-subseq m 3) n) ; var or doc not last
          (orgstrap--dedoc n) ; recurse for nested
          ;; splice out the docstring and return t to avoid the other branch
          (or (setcdr (cddr e) n) t))))
      ;; recurse e.g. for (when x (defvar y t))
      (orgstrap--dedoc e))))
  sexp)

(defun orgstrap--local-variables--check-version (info &optional minimal)
  "Return the version check local variables given INFO and MINIMAL."
  `(
    (setq-local orgstrap-min-org-version ,(orgstrap--get-min-org-version info minimal))
    (let ((actual (org-version))
          (need orgstrap-min-org-version))
      (or (fboundp #'orgstrap--confirm-eval) ; orgstrap with portable is already present on the system
          (not need)
          (string< need actual)
          (string= need actual)
          (error "Your Org is too old! %s < %s" actual need)))))

(defun orgstrap--local-variables--norm (&optional norm-func-name)
  "Return the normalization function for local variables given NORM-FUNC-NAME."
  (let ((norm-func-name (or norm-func-name (default-value 'orgstrap-norm-func))))
    (cl-case norm-func-name
      (orgstrap-norm-func--dprp-1.0
       '(
         (defun orgstrap-norm-func--dprp-1.0 (body)
           "Normalize BODY using dprp-1.0."
           (let ((p (read (concat "(progn\n" body "\n)")))
                 (m '(defun defun-local defmacro defvar defvar-local defconst defcustom))
                 print-quoted print-length print-level)
             (cl-labels
                 ((f
                   (b)
                   (cl-loop
                    for e in b when (listp e) do ; for expression in body when the expression is a list
                    (or
                     (and
                      (memq (car e) m) ; is a form with docstrings
                      (let ((n (nthcdr 4 e))) ; body after docstring
                        (and
                         (stringp (nth 3 e)) ; has a docstring
                         (or (cl-subseq m 3) n) ; var or doc not last
                         (f n) ; recurse for nested
                         ;; splice out the docstring and return t to avoid the other branch
                         (or (setcdr (cddr e) n) t))))
                     ;; recurse e.g. for (when x (defvar y t))
                     (f e)))
                   p))
               (prin1-to-string (f p)))))))
      (orgstrap-norm-func--prp-1.1
       '(
         (defun orgstrap-norm-func--prp-1.1 (body)
           "Normalize BODY using prp-1.1."
           (let (print-quoted print-length print-level)
             (prin1-to-string (read (concat "(progn\n" body "\n)")))))))
      (orgstrap-norm-func--prp-1.0
       (error "`orgstrap-norm-func--prp-1.0' is deprecated.
Please update `orgstrap-norm-func-name' to `orgstrap-norm-func--prp-1.1'"))
      (otherwise (error "Don't know that normalization function %s" norm-func-name)))))

(defun orgstrap--local-variables--norm-common ()
  "Return the common normalization functions for local variables."
  '(
    (unless (boundp 'orgstrap-norm-func)
      (defvar-local orgstrap-norm-func orgstrap-norm-func-name))

    (defun orgstrap-norm-embd (body)
      "Normalize BODY."
      (funcall orgstrap-norm-func body))

    (unless (fboundp #'orgstrap-norm)
      (defalias 'orgstrap-norm #'orgstrap-norm-embd))))

(defun orgstrap--local-variables--eval (info &optional minimal)
  "Return the portable or MINIMAL elvs given INFO."
  (let* ((minimal (or minimal orgstrap-use-minimal-local-variables))
         (minimal (and minimal (orgstrap--have-min-org-version info minimal))))
    (if minimal
        '(
          (defun orgstrap--confirm-eval-minimal (lang body)
            (not (and (member lang '("elisp" "emacs-lisp"))
                      (eq orgstrap-block-checksum
                          (intern
                           (secure-hash
                            orgstrap-cypher
                            (orgstrap-norm body)))))))
          (unless (fboundp #'orgstrap--confirm-eval)
            ;; if `orgstrap--confirm-eval' is bound use it since it is
            ;; is the portable version XXX NOTE the minimal version will
            ;; not be installed as local variables if it detects that there
            ;; are unescaped coderefs since those will cause portable and minimal
            ;; to produce different hashes
            (defalias 'orgstrap--confirm-eval #'orgstrap--confirm-eval-minimal)))
      '(
;; if you automatically reindent it will break these two
(defun orgstrap-org-src-coderef-regexp (_fmt &optional label)
  "Backport `org-src-coderef-regexp' for 24 and 25.
See the upstream docstring for info on LABEL.
_FMT has the wrong meaning in 24 and 25."
  (let ((fmt org-coderef-label-format))
    (format "\\([:blank:]*\\(%s\\)[:blank:]*\\)$"
            (replace-regexp-in-string
             "%s"
             (if label
                 (regexp-quote label)
               "\\([-a-zA-Z0-9_][-a-zA-Z0-9_ ]*\\)")
             (regexp-quote fmt)
             nil t))))
(unless (fboundp #'org-src-coderef-regexp)
  (defalias 'org-src-coderef-regexp #'orgstrap-org-src-coderef-regexp))
(defun orgstrap--expand-body (info)
  "Expand noweb references in INFO body and remove any coderefs."
  ;; this is a backport of `org-babel--expand-body'
  (let ((coderef (nth 6 info))
        (expand
         (if (org-babel-noweb-p (nth 2 info) :eval)
             (org-babel-expand-noweb-references info)
           (nth 1 info))))
    (if (not coderef)
        expand
      (replace-regexp-in-string
       (org-src-coderef-regexp coderef) "" expand nil nil 1))))

;;;###autoload
(defun orgstrap--confirm-eval-portable (lang _body)
  "A backwards compatible, portable implementation for confirm-eval.
This should be called by `org-confirm-babel-evaluate'.  As implemented
the only LANG that is supported is emacs-lisp or elisp.  The argument
_BODY is rederived for portability and thus not used."
  ;; `org-confirm-babel-evaluate' will prompt the user when the value
  ;; that is returned is non-nil, therefore we negate positive matchs
  (not (and (member lang '("elisp" "emacs-lisp"))
            (let* ((body (orgstrap--expand-body (org-babel-get-src-block-info)))
                   (body-normalized (orgstrap-norm body))
                   (content-checksum
                    (intern
                     (secure-hash
                      orgstrap-cypher
                      body-normalized))))
              ;;(message "%s %s" orgstrap-block-checksum content-checksum)
              ;;(message "%s" body-normalized)
              (eq orgstrap-block-checksum content-checksum)))))
;; portable eval is used as the default implementation in orgstrap.el
;;;###autoload
(unless (fboundp #'orgstrap--confirm-eval)
  (defalias 'orgstrap--confirm-eval #'orgstrap--confirm-eval-portable))))))

(defun orgstrap--local-variables--eval-common ()
  "Return the common eval check functions for local variables."
  `( ; quasiquote to fill in `orgstrap-orgstrap-block-name'
    (let (enable-local-eval) (vc-find-file-hook)) ; use the obsolete alias since it works in 24
    (let ((ocbe org-confirm-babel-evaluate)
          (obs (org-babel-find-named-block ,orgstrap-orgstrap-block-name))) ; quasiquoted when nowebbed
      (if obs
          (unwind-protect
              (save-excursion
                (setq-local orgstrap-norm-func orgstrap-norm-func-name)
                (setq-local org-confirm-babel-evaluate #'orgstrap--confirm-eval)
                (goto-char obs) ; FIXME `org-save-outline-visibility' but that is not portable
                (org-babel-execute-src-block))
            (when (eq org-confirm-babel-evaluate #'orgstrap--confirm-eval)
              ;; XXX allow orgstrap blocks to set ocbe so audit for that
              (setq-local org-confirm-babel-evaluate ocbe))
            (org-set-visibility-according-to-property))
        ;; FIXME warn or error here?
        (warn "No orgstrap block.")))))

;; init utility functions

(defun orgstrap--new-heading-elisp-block (heading block-name &optional header-args noexport)
  "Create a new elisp block named BLOCK-NAME in a new heading titled HEADING.
The heading is inserted at the top of the current file.
HEADER-ARGS is an alist of symbols that are converted to strings.
If NOEXPORT is non-nil then the :noexport: tag is added to the heading."
  (declare (indent 1))
  (save-excursion
    (goto-char (point-min))
    (outline-next-heading)  ;; alternately outline-next-heading
    (org-meta-return)
    (insert (format "%s%s\n" heading (if noexport " :noexport:" "")))
    ;;(org-edit-headline heading)
    ;;(when noexport (org-set-tags "noexport"))
    (move-end-of-line 1)
    (insert "\n#+name: " block-name "\n")
    (insert "#+begin_src elisp")
    (mapc (lambda (header-arg-value)
            (insert " :" (symbol-name (car header-arg-value))
                    " " (symbol-name (cdr header-arg-value))))
          header-args)
    (insert "\n#+end_src\n")))

(defun orgstrap--trap-hack-locals (command &rest args)
  "Advice for `hack-local-variables-filter' to do nothing except the following.
Set `orgstrap--local-variables' to the reversed list of read variables which
are the first argument in the lambda list ARGS.
COMMAND is unused since we don't actually want to hack the local variables,
just get their current values."
  (ignore command)
  (setq-local orgstrap--local-variables (reverse (car args)))
  nil)

(defun orgstrap--read-current-local-variables ()
  "Return the local variables for the current file without applying them."
  (interactive)
  ;; orgstrap--local-variables is a temporary local variable that is used to
  ;; capture the input to `hack-local-variables-filter' it is unset at the end
  ;; of this function so that it cannot accidentally be used when it might be stale
  (setq-local orgstrap--local-variables nil)
  (let ((enable-local-variables t))
    (advice-add #'hack-local-variables-filter :around #'orgstrap--trap-hack-locals)
    (unwind-protect
        (hack-local-variables nil)
      (advice-remove #'hack-local-variables-filter #'orgstrap--trap-hack-locals))
    (let ((local-variables orgstrap--local-variables))
      (makunbound 'orgstrap--local-variables)
      local-variables)))

(defun orgstrap--add-link-to-orgstrap-block (&optional link-message)
  "Add an `org-mode' link pointing to the orgstrap block for the current file.
The link is placed in comment on the second line of the file.  LINK-MESSAGE
can be used to override the default value set via `orgstrap-link-message'"
  (interactive)  ; TODO prompt for message with C-u ?
  (goto-char (point-min))
  (next-logical-line) ; required to get correct behavior?
  (let ((link-message (or link-message orgstrap-link-message)))
    (unless (save-excursion
              (re-search-forward
               (format "^# \\[\\[%s\\]\\[.+\\]\\]$"
                       orgstrap-orgstrap-block-name)
               nil t)) ; XXX for some reason save-excursion fails so we have to reset
      (goto-char (point-min))
      (next-logical-line)  ; use logical-line to avoid issues with visual line mode
      (insert (format "# [[%s][%s]]\n"
                      orgstrap-orgstrap-block-name
                      (or link-message orgstrap-link-message))))))

(defun orgstrap--add-orgstrap-block (&optional block-contents)
  "Add a new elisp source block with #+name: orgstrap to the current buffer.
If a block with that name already exists raise an error.
Insert BLOCK-CONTENTS if they are supplied."
  (interactive)
  (let ((all-block-names (org-babel-src-block-names)))
    (if (member orgstrap-orgstrap-block-name all-block-names)
        (warn "orgstrap block already exists not adding!")
      (goto-char (point-max))
      (insert "\n")
      (orgstrap--new-heading-elisp-block "Bootstrap"
        orgstrap-orgstrap-block-name
        '((results . none)
          (exports . none)
          (lexical . yes))
        'noexport)
      (goto-char (point-max))
      (insert "\n** Local Variables :ARCHIVE:\n")
      (orgstrap--with-block orgstrap-orgstrap-block-name
        (ignore params body-unexpanded body)
        (when block-contents
          ;; FIXME `org-babel-update-block-body' is broken in < 26
          ;; for now warn and fail if the version is known bad NOTE trying to backport
          ;; is not simple because there are changes to the function signatures
          (if (string< org-version "8.3.4")
              (warn "Your version of Org is too old to use this feature! %s < 8.3.4"
                    org-version)
            (org-babel-update-block-body block-contents)))
        nil))))

(defun orgstrap--lv-command (info &optional minimal norm-func-name)
  "Create the elvs for an orgstrapped file.
INFO is the output of `org-babel-get-src-block-info' for the orgstrap block.
MINIMAL determines whether a non-portable block has been requested.
NORM-FUNC-NAME is the name of the function that will be used to normalize orgstrap blocks."
  (let ((lv-cver (orgstrap--local-variables--check-version
                  info
                  minimal))
        (lv-norm (orgstrap--local-variables--norm
                  norm-func-name))
        (lv-ncom (orgstrap--local-variables--norm-common))
        (lv-eval (orgstrap--local-variables--eval
                  info
                  minimal))
        (lv-ecom (orgstrap--local-variables--eval-common)))
    (cons 'progn (orgstrap--dedoc (append lv-cver lv-norm lv-ncom lv-eval lv-ecom)))))

(defun orgstrap--add-file-local-variables (&optional minimal norm-func-name)
  "Add the file local variables needed to make orgstrap work.
MINIMAL is used to control whether the portable or minimal block is used.
If MINIMAL is set but the orgstrap block uses features like noweb and
uncommented coderefs and function `org-version' is too old, then the portable
block will be used.  NORM-FUNC-NAME is an optional argument that can be provided
to determine which normalization function is used independent of the current
buffer or global setting for `orgstrap-norm-func'.

When run, this function replaces any existing orgstrap elv with the latest
implementation available according to the preferences for the current buffer
and configuration.  Other elvs are retained if they are present, and the
orgstrap elv is always added first."
  ;; switching comments probably wont work ? we can try
  ;; Use a prefix argument (i.e. C-u) to add file local variables comments instead of in a :noexport:
  (interactive)
  (let ((info (save-excursion
                (orgstrap--goto-named-src-block orgstrap-orgstrap-block-name)
                (org-babel-get-src-block-info)))
        (elv (orgstrap--read-current-local-variables)))
    (let ((lv-command (orgstrap--lv-command info minimal norm-func-name))
          (commands-existing (mapcar #'cdr (cl-remove-if-not (lambda (l) (eq (car l) 'eval)) elv))))
      (let* ((stripped
              (cl-remove-if
               (lambda (cmd) (orgstrap--match-elvs (cons 'eval cmd)))
               commands-existing))
             (eval-commands (cons lv-command stripped)))
        (when commands-existing
          (delete-file-local-variable 'eval))
        (let ((print-escape-newlines t)  ; needed to preserve the escaped newlines
              ;; if `print-length' or `print-level' is accidentally set
              ;; `add-file-local-variable' will truncate the sexp with and elispsis
              ;; this is clearly a bug in `add-file-local-variable' and possibly in
              ;; something deeper, `print-length' is the only one that has actually
              ;; caused issues, but better safe than sorry
              print-length print-level)
          (mapcar (lambda (sexp) (add-file-local-variable 'eval sexp)) eval-commands))))))

;; init user facing functions

;;;###autoload
(defun orgstrap-init (&optional prefix-argument)
  "Initialize orgstrap in a buffer and enable command `orgstrap-edit-mode'.
PREFIX-ARGUMENT is essentially minimal from other functions, when non-nil
the minimal local variables will be used if possible."
  (interactive "P")
  (unless (eq major-mode 'org-mode)
    (error "Cannot orgstrap, buffer not in `org-mode' it is in %s!" major-mode))
  ;; TODO option for no link?
  ;; TODO option for local variables in comments vs noexport
  (let (onf)
    (let ((orgstrap-norm-func
           (or (cdr (assoc 'orgstrap-norm-func-name (orgstrap--read-current-local-variables)))
               (default-value 'orgstrap-norm-func))))
      (save-excursion
        (orgstrap--add-orgstrap-block)
        (orgstrap-add-block-checksum)
        (orgstrap--add-link-to-orgstrap-block)
        ;; FIXME sometimes local variables don't populate due to an out of range error
        (orgstrap--add-file-local-variables
         (or prefix-argument orgstrap-use-minimal-local-variables))
        (orgstrap-edit-mode 1)
        (setq onf orgstrap-norm-func)))
      ;; reset to ensure that a stale value is not inserted on next save
      (setq-local orgstrap-norm-func onf)))

;;; extra helpers

(defun orgstrap-update-src-block (name content)
  "Set the content of source block named NAME to string CONTENT.
XXX NOTE THAT THIS CANNOT BE USED WITH #+BEGIN_EXAMPLE BLOCKS."
  ;; FIXME this seems to fail if the existing block is empty?
  ;; or at least adding file local variables fails?
  (let ((block (org-babel-find-named-block name)))
    (if block
        (save-excursion
          (orgstrap--goto-named-src-block name)
          (org-babel-update-block-body content))
      (error "No block with name %s" name))))

(defun orgstrap-get-src-block-checksum (&optional cypher)
  "Calculate of the checksum of the current source block using CYPHER."
  (interactive)
  (let* ((info (org-babel-get-src-block-info))
         (params (nth 2 info))
         (body-unexpanded (nth 1 info))
         (body (orgstrap--expand-body info))
         (body-normalized
          (orgstrap-norm body))
         (cypher (or cypher (orgstrap--current-buffer-cypher))))
    (ignore params body-unexpanded)
    (secure-hash cypher body-normalized)))

(defun orgstrap-get-named-src-block-checksum (name &optional cypher)
  "Calculate the checksum of the first sourc block named NAME using CYPHER."
  (interactive)
  (orgstrap--with-block name
    (ignore params body-unexpanded)
    (let ((cypher (or cypher (orgstrap--current-buffer-cypher)))
          (body-normalized
           (orgstrap-norm body)))
      (secure-hash cypher body-normalized))))

(defun orgstrap-run-additional-blocks (&rest name-checksum)
  "Securely run additional blocks in languages other than elisp.
Do this by providing the name of the block and the checksum to be embedded
in the orgstrap block as NAME-CHECKSUM pairs."
  (ignore name-checksum)
  (error "TODO"))

(defun orgstrap--get-elvs (&optional from-flv-alist)
  "Return the elvs as they are written in the current buffer.
If FROM-FLV-ALIST is not null display the elvs that are in `file-local-variables-alist'."
  (cl-loop
   for var in
   (if from-flv-alist
       file-local-variables-alist
     (orgstrap--read-current-local-variables))
   when (orgstrap--match-elvs var)
   return (cdr var)))

(defun orgstrap-inspect-elvs (&optional from-flv-alist)
  "Display the elvs for the current buffer.
If FROM-FLV-ALIST is not null display the elvs that are in `file-local-variables-alist'."
  (interactive "P")
  (let ((buffer (get-buffer-create (format "%s orgstrap elvs" (buffer-file-name))))
        (elvs (orgstrap--get-elvs from-flv-alist))
        (cypher orgstrap-cypher)
        print-length print-level)
    (with-current-buffer buffer
      (emacs-lisp-mode)
      (read-only-mode)
      (let ((inhibit-read-only t))
        (erase-buffer)
        ;; TODO insert checksum in comment
        (insert ";; -*- elvs-checksum: "
                (secure-hash cypher (orgstrap-norm (pp-to-string elvs)))
                "; -*-\n")
        (insert (pp-to-string elvs))
        (goto-char (point-min))
        (while (re-search-forward "(\\(let\\|defun\\|when\\|unless\\|if\\|read\\)" nil t)
          (join-line 1))
        (indent-region (point-min) (point-max)))
      (local-set-key (kbd "q") #'quit-window)
      (goto-char (point-min)))
    (display-buffer buffer)))

(defun orgstrap--whitelist-current-buffer ()
  "Mark local variable values in the current buffer as safe."
  (let ((lvs (orgstrap--read-current-local-variables)))
    (customize-push-and-save 'safe-local-variable-values lvs)))

;; extra user facing functions

;;;###autoload
(defun orgstrap-whitelist-file (path)
  "Add local variables in PATH as safe custom variable values.
This is useful when distributing orgstrapped files.

Use with a command similar to the following.
Since -batch implies -q, `user-init-file' must be passed explicitly.

emacs -batch -eval \\
\"(let ((user-init-file (pop argv)) (file (pop argv))) (package-initialize) (orgstrap-whitelist-file file))\" \\
~/.emacs.d/init.el /path/to/whitelist.org"
  (with-current-buffer (find-file-literally path)
    (orgstrap--whitelist-current-buffer)
    (kill-buffer)))

(provide 'orgstrap)

;;; orgstrap.el ends here
