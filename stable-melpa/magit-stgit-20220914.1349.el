;;; magit-stgit.el --- StGit extension for Magit  -*- lexical-binding: t; -*-

;; Copyright (C) 2011-2019  The Magit Project Contributors

;; Author: Lluís Vilanova <vilanova@ac.upc.edu>
;; Maintainer: UNMAINTAINED
;; Keywords: vc tools
;; Package-Version: 20220914.1349
;; Package-Commit: bf96fa0f40c087329ad7e6a3b1946de7df03559c

;; Package: magit-stgit
;; Package-Requires: ((emacs "24.4") (magit "2.12.0") (magit-popup "2.12.0"))

;; Magit-StGit is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; Magit-StGit is distributed in the hope that it will be useful, but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
;; or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with Magit-StGit.  If not, see http://www.gnu.org/licenses.

;;; Commentary:

;; This package is no longer maintained.

;; This package provides very basic support for StGit.
;;
;;   StGit (Stacked Git) is an application that aims to provide a
;;   convenient way to maintain a patch stack on top of a Git branch.
;;
;; For information about StGit see http://stacked-git.github.io.
;;
;; If you are looking for full fledged StGit support in Emacs, then
;; have a look at `stgit.el' which is distributed with StGit.

;; When `magit-stgit-mode' is turned on then the current patch series
;; is displayed in the status buffer.  While point is on a patch the
;; changes it introduces can be shown using `RET', it can be selected
;; as the current patch using `a', and it can be discarded using `k'.
;; Other StGit commands are available from the StGit popup on `/'.

;; To enable the mode in a particular repository use:
;;
;;   cd /path/to/repository
;;   git config --add magit.extension stgit
;;
;; To enable the mode for all repositories use:
;;
;;   git config --global --add magit.extension stgit
;;
;; To enable the mode globally without dropping to a shell:
;;
;;   (add-hook 'magit-mode-hook 'magit-stgit-mode)

;;; Code:

(require 'cl-lib)
(require 'dash)

(require 'magit)
(require 'magit-popup)

;;; Options
;;;; Variables

(defgroup magit-stgit nil
  "StGit support for Magit."
  :group 'magit-extensions)

(defgroup magit-stgit-commands nil
  "Options controlling behavior of certain commands."
  :group 'magit-stgit)


(defcustom magit-stgit-executable "stg"
  "The name of the StGit executable."
  :group 'magit-stgit
  :type 'string)

(defcustom magit-stgit-show-patch-name t
  "Whether to prefix patch messages with the patch name, in patch series."
  :group 'magit-stgit
  :type 'boolean)

(defcustom magit-stgit-mode-lighter " Stg"
  "Mode-line lighter for Magit-Stgit mode."
  :group 'magit-stgit
  :type 'string)

;;;; Faces

(defgroup magit-stgit-faces nil
  "Faces used by Magit-StGit."
  :group 'magit-stgit
  :group 'magit-faces)

(defface magit-stgit-patch
  '((t :inherit magit-hash))
  "Face for name of a stgit patch."
  :group 'magit-stgit-faces)

(add-to-list 'magit-ref-namespaces
             (cons "^refs/patches/\\(.+\\)" 'magit-stgit-patch))

(defface magit-stgit-current
  '((((background dark)) (:weight bold :foreground "yellow"))
    (((background light)) (:weight bold :foreground "purple"))
    (t (:weight bold)))
  "Face for the current stgit patch."
  :group 'magit-stgit-faces)

(defface magit-stgit-applied
  '((t :inherit magit-cherry-equivalent))
  "Face for an applied stgit patch."
  :group 'magit-stgit-faces)

(defface magit-stgit-unapplied
  '((t :inherit magit-cherry-unmatched))
  "Face for an unapplied stgit patch."
  :group 'magit-stgit-faces)

(defface magit-stgit-empty
  '((t :inherit magit-diff-removed))
  "Face for an empty stgit patch."
  :group 'magit-stgit-faces)

(defface magit-stgit-hidden
  '((t :inherit magit-diff-context))
  "Face for an hidden stgit patch."
  :group 'magit-stgit-faces)

;;; Utilities

(defun magit-run-stgit (&rest args)
  "Run StGit command with given arguments.
Any list in ARGS is flattened."
  (magit-run-stgit-callback (lambda ()) args))

(defun magit-run-stgit-async (&rest args)
  "Asynchronously run StGit command with given arguments.
Any list in ARGS is flattened."
  (with-editor "GIT_EDITOR"
    (let ((magit-process-popup-time -1))
      (message "Running %s %s" magit-stgit-executable
               (mapconcat 'identity (-flatten args) " "))
      (apply #'magit-start-process magit-stgit-executable nil (-flatten args)))))

(defun magit-run-stgit-and-mark-remove (patches &rest args)
  "Run `magit-run-stgit' and `magit-stgit-mark-remove'.
Argument PATCHES sets the marks to remove, and ARGS the arguments to StGit."
  (magit-run-stgit-callback (lambda () (magit-stgit-mark-remove patches)) args))

(defun magit-run-stgit-callback (callback &rest args)
  "Run StGit command with given arguments.
Function CALLBACK will be executed before refreshing the buffer.
Any list in ARGS is flattened."
  (apply #'magit-call-process magit-stgit-executable (-flatten args))
  (funcall callback)
  (magit-refresh))

(defun magit-stgit-lines (&rest args)
  (with-temp-buffer
    (apply 'process-file magit-stgit-executable nil (list t nil) nil args)
    (split-string (buffer-string) "\n" 'omit-nulls)))

(defvar magit-stgit-read-patch-history nil)

(defun magit-stgit-read-patch (prompt &optional require-match)
  (magit-completing-read prompt (magit-stgit-lines "series" "--noprefix")
                         nil require-match
                         nil 'magit-stgit-read-patch-history))

(defun magit-stgit-patches-sorted (patches)
  "Return elements in PATCHES with the same partial order as the series."
  (let ((original (magit-stgit-lines "series" "--noprefix"))
        sorted)
    (mapc (lambda (patch)
            (when (member patch patches)
              (add-to-list 'sorted patch t)))
          original)
    sorted))

(defun magit-stgit-read-patches (use-region use-marks use-point require-match prompt)
  "Return list of selected patches.
If USE-REGION and there is an active region, return marked
patches in it (if USE-MARKS), or all patches in the region if
USE-MARKS is not set or none is marked.
Else, if USE-MARKS and some patches are marked, return these.
Else, if USE-POINT, return the patch at point.
Else, if PROMPT, ask the user for the name of a patch using
PROMPT."
  (let* ((region (and use-region (magit-region-values 'stgit-patch)))
         (intersection (cl-intersection region magit-stgit-marked-patches
                                        :test #'equal)))
    (or (and use-marks
             intersection)
        region
        (and use-marks
             (magit-stgit-patches-sorted magit-stgit-marked-patches))
        (list (or (and use-point (magit-section-when stgit-patch))
                  (and prompt (magit-stgit-read-patch prompt require-match)))))))

;;; Marking

(defvar-local magit-stgit-marked-patches nil
  "Internal list of marked patches.")

(defun magit-stgit-mark-contains (patch)
  "Whether the given PATCH is marked."
  (member patch magit-stgit-marked-patches))

(defun magit-stgit-mark-add (patches)
  "Set mark of patches.
See `magit-stgit-mark-toggle' for the meaning of PATCHES."
  (interactive (list (magit-stgit-read-patches t nil t t "Patch name")))
  (mapc (lambda (patch)
          (add-to-list 'magit-stgit-marked-patches patch))
        patches)
  (when (called-interactively-p 'any)
    (forward-line)
    (magit-refresh)))

(defun magit-stgit-mark-remove (patches)
  "Unset mark of patches.
See `magit-stgit-mark-toggle' for the meaning of PATCHES."
  (interactive (list (magit-stgit-read-patches t nil t t "Patch name")))
  (mapc (lambda (patch)
          (setq magit-stgit-marked-patches (delete patch magit-stgit-marked-patches)))
        patches)
  (when (called-interactively-p 'any)
    (forward-line)
    (magit-refresh)))

(defun magit-stgit-mark-toggle (patches)
  "Toggle mark of patches.
If given, PATCHES specifies the patch names.
Else, if there is an active region, toggles these.
Else, if point is in an StGit section, toggles the patch at point.
Else, asks the user for a patch name."
  (interactive (list (magit-stgit-read-patches t nil t t "Patch name")))
  (mapc (lambda (patch)
          (if (magit-stgit-mark-contains patch)
              (magit-stgit-mark-remove (list patch))
            (magit-stgit-mark-add (list patch))))
        patches)
  (when (called-interactively-p 'any)
    (forward-line)
    (magit-refresh)))

;;; Commands

(magit-define-popup magit-stgit-popup
  "Popup console for StGit commands."
  'magit-stgit-commands
  :actions '((?i  "Init"     magit-stgit-init)
             ;;
             (?N  "New"      magit-stgit-new-popup)
             (?n  "Rename"   magit-stgit-rename)
             (?e  "Edit"     magit-stgit-edit-popup)
             (?c  "Commit"   magit-stgit-commit-popup)
             (?C  "Uncommit" magit-stgit-uncommit-popup)
             (?k  "Delete"   magit-stgit-delete-popup)
             ;;
             (?f  "Float"    magit-stgit-float-popup)
             (?s  "Sink"     magit-stgit-sink-popup)
             ;;
             (?\r "Show"     magit-stgit-show)
             (?a  "Goto"     magit-stgit-goto-popup)
             ;;
             (?m  "Mail patches" magit-stgit-mail-popup)
             ;;
             (?g  "Refresh"  magit-stgit-refresh-popup)
             (?r  "Repair"   magit-stgit-repair)
             (?R  "Rebase"   magit-stgit-rebase-popup)
             ;;
             (?z  "Undo"     magit-stgit-undo-popup)
             (?Z  "Redo"     magit-stgit-redo-popup)))

;;;###autoload
(defun magit-stgit-init ()
  "Initialize StGit support for the current branch."
  (interactive)
  (magit-run-stgit "init"))

(defvar magit-stgit-new-filename-regexp ".stgit-\\(new\\|edit\\).txt")

(defun magit-stgit-new-check-buffer ()
  "Check if buffer is an StGit commit message."
  ;; TODO: must remove the stray file on cancel
  (and buffer-file-name
       (string-match-p magit-stgit-new-filename-regexp buffer-file-name)
       (git-commit-setup)))

(magit-define-popup magit-stgit-new-popup
  "Popup console for StGit new."
  'magit-stgit-commands
  :switches '((?a "Add \"Acked-by:\" line" "--ack")
              (?s "Add \"Signed-off-by:\" line" "--sign"))
  :options  '((?n "Set patch name" ""
                  (lambda (prompt default) (read-from-minibuffer "Patch name: " default))))
  :actions  '((?N  "New"  magit-stgit-new))
  :default-action #'magit-stgit-new)

;;;###autoload
(defun magit-stgit-new (&rest args)
  "Create a new StGit patch.
Use ARGS to pass additional arguments."
  (interactive (magit-stgit-new-arguments))
  (magit-run-stgit-async "new" args))

(magit-define-popup magit-stgit-edit-popup
  "Popup console for StGit edit."
  'magit-stgit-commands
  :switches '((?s "Add \"Signed-off-by:\" line" "--sign")
              (?a "Add \"Acked-by:\" line" "--ack"))
  :actions  '((?e  "Edit"  magit-stgit-edit))
  :default-action #'magit-stgit-edit)

;;;###autoload
(defun magit-stgit-edit (patch &rest args)
  "Edit the description of an existing StGit PATCH.
Use ARGS to pass additional arguments."
  (interactive (list (magit-stgit-read-patches nil nil t nil "Edit patch (default is top)")
                     (magit-stgit-edit-arguments)))
  (magit-run-stgit-async "edit" "--edit" args "--" patch))

(magit-define-popup magit-stgit-float-popup
  "Popup console for StGit float."
  'magit-stgit-commands
  :switches '((?k "Keep the local changes" "--keep"))
  :actions  '((?f  "Float"  magit-stgit-float))
  :default-action #'magit-stgit-float)

;;;###autoload
(defun magit-stgit-float (patches &rest args)
  "Float StGit PATCHES to the top.
Use ARGS to pass additional arguments."
  (interactive (list (magit-stgit-read-patches t t t t "Float patch")
                     (magit-stgit-float-arguments)))
  (magit-run-stgit-and-mark-remove patches "float" args "--" patches))

;;;###autoload
(defun magit-stgit-rename (oldname newname)
  "Rename StGit patch OLDNAME to NEWNAME."
  (interactive
   (list (magit-stgit-read-patch "Patch to rename" t)
         (read-from-minibuffer "New name: ")))
  (magit-run-stgit "rename" oldname newname))

(magit-define-popup magit-stgit-sink-popup
  "Popup console for StGit sink."
  'magit-stgit-commands
  :switches '((?k "Keep the local changes" "--keep"))
  :options  '((?t "Sink patches below the target patch (else to bottom)"
                  "--to="
                  (lambda (prompt &optional default) (magit-stgit-read-patch prompt t))))
  :actions  '((?s  "Sink"  magit-stgit-sink))
  :default-action #'magit-stgit-float)

;;;###autoload
(defun magit-stgit-sink (patches &rest args)
  "Sink StGit PATCHES deeper down the stack.
Use ARGS to pass additional arguments."
  (interactive (list (magit-stgit-read-patches t t t t "Sink patch")
                     (magit-stgit-sink-arguments)))
  (when (and (called-interactively-p 'any)
             (not magit-current-popup))
    (let ((target (magit-stgit-read-patch "Target patch (default is bottom)")))
      (when target
        (setq args (append args (list "-t" target))))))
  (magit-run-stgit-and-mark-remove patches "sink" args "--" patches))

(magit-define-popup magit-stgit-commit-popup
  "Popup console for StGit commit."
  'magit-stgit-commands
  :switches '((?a "Commit all applied patches" "--all"))
  :options  '((?n "Commit the specified number of patches" "--number=" read-number))
  :actions  '((?c  "Commit"  magit-stgit-commit))
  :default-action #'magit-stgit-commit)

;;;###autoload
(defun magit-stgit-commit (patches &rest args)
  "Permanently store patches into the stack base."
  (interactive (list (magit-stgit-read-patches t t t t nil)
                     (magit-stgit-commit-arguments)))
  (when (and (member "--all" (car args))
             (= 1 (length patches)))
    (setq patches (list nil)))
  (magit-run-stgit-and-mark-remove patches "commit" args "--" patches))

(magit-define-popup magit-stgit-uncommit-popup
  "Popup console for StGit uncommit."
  'magit-stgit-commands
  :options  '((?n "Uncommit the specified number of commits" "--num=" read-number))
  :actions  '((?C  "Uncommit"  magit-stgit-uncommit))
  :default-action #'magit-stgit-uncommit)

;;;###autoload
(defun magit-stgit-uncommit (&rest args)
  "Turn regular commits into StGit patches."
  (interactive (-flatten (list (magit-stgit-uncommit-arguments))))
  (magit-run-stgit "uncommit" args))

(magit-define-popup magit-stgit-refresh-popup
  "Popup console for StGit refresh."
  'magit-stgit-commands
  :switches '((?u "Only update the current patch files"    "--update")
              (?i "Refresh from index instead of worktree" "--index")
              (?F "Force refresh even if index is dirty"   "--force")
              (?e "Edit the patch description"             "--edit")
              (?s "Add \"Signed-off-by:\" line"            "--sign")
              (?a "Add \"Acked-by:\" line"                 "--ack"))
  :actions  '((?g  "Refresh"  magit-stgit-refresh))
  :default-action #'magit-stgit-refresh)

;;;###autoload
(defun magit-stgit-refresh (&optional patch &rest args)
  "Refresh StGit patch PATCH.
Use ARGS to pass additional arguments."
  (interactive (list (magit-stgit-read-patches nil nil t nil "Refresh patch (default top)")
                     (magit-stgit-refresh-arguments)))
  (setq patch (nth 0 patch))
  (when patch
    (setq args (append args (list (format "--patch=%s" patch)))))
  (magit-run-stgit-async "refresh" args))

;;;###autoload
(defun magit-stgit-repair ()
  "Repair StGit metadata if branch was modified with git commands.
In the case of Git commits these will be imported as new patches
into the series."
  (interactive)
  (message "Repairing series...")
  (magit-run-stgit "repair")
  (message "Repairing series...done"))

(magit-define-popup magit-stgit-rebase-popup
  "Popup console for StGit rebase."
  'magit-stgit-commands
  :switches '((?n "Do not push the patches back after rebasing" "--nopush")
              (?m "Check for patches merged upstream"           "--merged"))
  :actions  '((?R  "Rebase"  magit-stgit-rebase))
  :default-action #'magit-stgit-rebase)

;;;###autoload
(defun magit-stgit-rebase (&rest args)
  "Rebase a StGit patch series.
Use ARGS to pass additional arguments"
  (interactive (magit-stgit-rebase-arguments))
  (let* ((branch (magit-get-current-branch))
         (remote (magit-get-remote branch)))
    (if (not (and remote branch))
        (user-error "Branch has no upstream")
      (when (y-or-n-p "Update remote first? ")
        (message "Updating remote...")
        (magit-run-git-async "remote" "update" remote)
        (message "Updating remote...done"))
      (magit-run-stgit "rebase" args "--" (format "remotes/%s/%s" remote branch)))))

(magit-define-popup magit-stgit-delete-popup
  "Popup console for StGit delete."
  'magit-stgit-commands
  :switches '((?s "Spill patch contents to worktree and index" "--spill"))
  :actions  '((?k  "Delete"  magit-stgit-delete))
  :default-action #'magit-stgit-delete)

;;;###autoload
(defun magit-stgit-delete (patches &rest args)
  "Delete StGit patches.
Argument PATCHES is a list of patchnames.
Use ARGS to pass additional arguments."
  (interactive (list (magit-stgit-read-patches t t t t "Delete patch")
                     (magit-stgit-delete-arguments)))
  (let ((affected-files
         (-mapcat (lambda (patch)
                    (magit-stgit-lines "files" "--bare" patch))
                  patches)))
    (when (and (called-interactively-p 'any)
               (not magit-current-popup)
               (and affected-files (y-or-n-p "Spill contents? ")))
      (setq args (append args (list "--spill")))))
  (let ((spill (member "--spill" args)))
    (when spill
      (setq spill (list "--spill")))
    (when (or (not (called-interactively-p 'any))
              (yes-or-no-p (format "Delete%s patch%s %s? "
                                   (if spill " and spill" "")
                                   (if (> (length patches) 1) "es" "")
                                   (mapconcat (lambda (patch) (format "`%s'" patch)) patches ", "))))
      (magit-run-stgit-and-mark-remove patches "delete" args "--" patches))))

(magit-define-popup magit-stgit-goto-popup
  "Popup console for StGit goto."
  'magit-stgit-commands
  :switches '((?k "Keep the local changes"            "--keep")
              (?m "Check for patches merged upstream" "--merged"))
  :actions  '((?a  "Goto"  magit-stgit-goto))
  :default-action #'magit-stgit-goto)

;;;###autoload
(defun magit-stgit-goto (patch &rest args)
  "Set PATCH as target of StGit push and pop operations.
Use ARGS to pass additional arguments."
  (interactive (list (magit-stgit-read-patches nil nil t t "Goto patch")
                     (magit-stgit-goto-arguments)))
  (magit-run-stgit "goto" patch args))

;;;###autoload
(defun magit-stgit-show (patch)
  "Show diff of a StGit patch."
  (interactive (magit-stgit-read-patches nil nil t t "Show patch"))
  (magit-show-commit (car (magit-stgit-lines "id" patch))))

(magit-define-popup magit-stgit-undo-popup
  "Popup console for StGit undo."
  'magit-stgit-commands
  :options  '((?n "Undo the last N commands" "--number=" read-number))
  :switches '((?h "Discard changes in index/worktree" "--hard"))
  :actions  '((?z  "Undo"  magit-stgit-undo))
  :default-action #'magit-stgit-undo)

;;;###autoload
(defun magit-stgit-undo (&rest args)
  "Undo the last operation.
Use ARGS to pass additional arguments."
  (interactive (magit-stgit-undo-arguments))
  (magit-run-stgit "undo" args))

(magit-define-popup magit-stgit-redo-popup
  "Popup console for StGit redo."
  'magit-stgit-commands
  :options  '((?n "Undo the last N commands" "--number=" read-number))
  :switches '((?h "Discard changes in index/worktree" "--hard"))
  :actions  '((?Z  "Redo"  magit-stgit-redo))
  :default-action #'magit-stgit-redo)

;;;###autoload
(defun magit-stgit-redo (&rest args)
  "Undo the last undo operation.
Use ARGS to pass additional arguments."
  (interactive (magit-stgit-redo-arguments))
  (magit-run-stgit "redo" args))

;;;; magit-stgit-mail

(magit-define-popup magit-stgit-mail-popup
  "Popup console for StGit mail."
  'magit-stgit-commands
  :man-page "stg-mail"
  :switches '((?m "Generate an mbox file instead of sending" "--mbox")
              (?g "Use git send-email" "--git" t)
              (?e "Edit cover letter before send" "--edit-cover")
              (?a "Auto-detect recipients for each patch" "--auto")
              (?A "Auto-detect To, Cc and Bcc for all patches from cover"
                  "--auto-recipients" t))
  :options '((?o "Set file as cover message" "--cover="
                 (lambda (prompt default) (read-file-name "Find file: " default)))
             (?v "Add version to [PATCH ...]" "--version=")
             (?p "Add prefix to [... PATCH ...]" "--prefix=")
             (?t "Mail To" "--to=")
             (?c "Mail Cc" "--cc=")
             (?b "Mail Bcc:" "--bcc="))
  :actions '((?m "Send" magit-stgit-mail)))

;;;###autoload
(defun magit-stgit-mail (patches &rest args)
  "Send PATCHES with \"stg mail\".

If a cover is specified, it will be searched to automatically set
the To, Cc, and Bcc fields for all patches."
  (interactive (list (magit-stgit-read-patches t t t t "Send patch")
                     (magit-stgit-mail-arguments)))
  (setq args (-flatten args))           ; nested list when called from popup
  (let* ((auto "--auto-recipients")
         (have-auto (member auto args))
         (cover (car (delq nil (mapcar (lambda (arg)
                                         (if (string-prefix-p "--cover=" arg)
                                             arg nil))
                                       args))))
         (cover-pos -1))
    (when have-auto
      (setq args (delete auto args)))
    (when (and have-auto cover)
      (setq cover (substring cover 8))
      (setq cover (with-temp-buffer (insert-file-contents cover)
                                    (buffer-string)))
      (while (setq cover-pos
                   (string-match
                        "^\\(To\\|Cc\\|Bcc\\):[[:space:]]+\\(.*\\)[[:space:]]*$"
                        cover (1+ cover-pos)))
        (let ((field (match-string 1 cover))
              (recipient (match-string 2 cover)))
          (setq field (match-string 1 cover))
          (when (string-match "<" recipient)
            (setq recipient (format "\"%s\"" recipient)))
          (cond ((equal field "To")
                 (setq args (cons (format "--to=%s" recipient)
                                  args)))
                ((equal field "Cc")
                 (setq args (cons (format "--cc=%s" recipient)
                                  args)))
                ((equal field "Bcc")
                 (setq args (cons (format "--bcc=%s" recipient)
                                  args)))))))
    (magit-run-stgit-async "mail" args patches)))

;;; Mode

(defvar magit-stgit-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "/" 'magit-stgit-popup)
    map))

(magit-define-popup-action 'magit-dispatch-popup ?/ "StGit" 'magit-stgit-popup)

;;;###autoload
(define-minor-mode magit-stgit-mode
  "StGit support for Magit."
  :lighter magit-stgit-mode-lighter
  :keymap  magit-stgit-mode-map
  (unless (derived-mode-p 'magit-mode)
    (user-error "This mode only makes sense with Magit"))
  (if magit-stgit-mode
      (progn
        (magit-add-section-hook 'magit-status-sections-hook
                                'magit-insert-stgit-series
                                'magit-insert-stashes t t)
        (add-hook 'find-file-hook #'magit-stgit-new-check-buffer))
    (remove-hook 'magit-status-sections-hook
                 'magit-insert-stgit-series t)
    (remove-hook 'find-file-hook #'magit-stgit-new-check-buffer))
  (when (called-interactively-p 'any)
    (magit-refresh)))

;;;###autoload
(custom-add-option 'magit-mode-hook #'magit-stgit-mode)

(easy-menu-define magit-stgit-mode-menu nil "Magit-Stgit mode menu"
  '("StGit" :visible magit-stgit-mode
    ["Initialize" magit-stgit-init
     :help "Initialize StGit support for the current branch"]
    "---"
    ["Create new patch" magit-stgit-new-popup
     :help "Create a new StGit patch"]
    ["Rename patch" magit-stgit-rename
     :help "Rename a patch"]
    ["Edit patch" magit-stgit-edit-popup
     :help "Edit a patch"]
    ["Commit patch" magit-stgit-commit-popup
     :help "Permanently store the base patch into the stack base"]
    ["Uncommit patch" magit-stgit-uncommit-popup
     :help "Turn a regular commit into an StGit patch"]
    ["Delete patch" magit-stgit-delete-popup
     :help "Delete an StGit patch"]
    "---"
    ["Float patch" magit-stgit-float-popup
     :help "Float StGit patch to the top"]
    ["Sink patch" magit-stgit-sink-popup
     :help "Sink StGit patch deeper down the stack"]
    "---"
    ["Refresh patch" magit-stgit-refresh-popup
     :help "Refresh the contents of a patch in an StGit series"]
    ["Repair" magit-stgit-repair
     :help "Repair StGit metadata if branch was modified with git commands"]
    ["Rebase series" magit-stgit-rebase-popup
     :help "Rebase an StGit patch series"]
    "---"
    ["Undo the last operation" magit-stgit-undo-popup
     :help "Undo the last operation"]
    ["Undo the last undo operation" magit-stgit-redo-popup
     :help "Undo the last undo operation"]))

(easy-menu-add-item 'magit-mode-menu '("Extensions") magit-stgit-mode-menu)

;;; Sections

(defconst magit-stgit-patch-re
  "^\\(.\\)\\([-+>!]\\) \\([^ ]+\\) +# \\(.*\\)$")

(defvar magit-stgit-patch-section-map
  (let ((map (make-sparse-keymap)))
    (define-key map "k"  'magit-stgit-delete)
    (define-key map "a"  'magit-stgit-goto)
    (define-key map "\r" 'magit-stgit-show)
    (define-key map "#"  #'magit-stgit-mark-toggle)
    map))

(defun magit-insert-stgit-series ()
  (when magit-stgit-mode
    (magit-insert-section (stgit-series)
      (magit-insert-heading "Patch series:")
      (let ((beg (point)))
        (process-file magit-stgit-executable nil (list t nil) nil
                      "series" "--all" "--empty" "--description")
        (if (= (point) beg)
            (magit-cancel-section)
          (save-restriction
            (narrow-to-region beg (point))
            (goto-char beg)
            (magit-wash-sequence #'magit-stgit-wash-patch)))
        (insert ?\n)))))

(defun magit-stgit-wash-patch ()
  (when (looking-at magit-stgit-patch-re)
    (magit-bind-match-strings (empty state patch msg) nil
      (delete-region (point) (point-at-eol))
      (magit-insert-section (stgit-patch patch)
        (insert (if (magit-stgit-mark-contains patch) "#" " "))
        (insert (propertize state 'face
                            (cond ((equal state ">") 'magit-stgit-current)
                                  ((equal state "+") 'magit-stgit-applied)
                                  ((equal state "-") 'magit-stgit-unapplied)
                                  ((equal state "!") 'magit-stgit-hidden)
                                  (t (user-error "Unknown stgit patch state: %s"
                                                 state)))))
        (insert (propertize empty 'face 'magit-stgit-empty) ?\s)
        (when magit-stgit-show-patch-name
          (insert (propertize patch 'face 'magit-stgit-patch) ?\s))
        (insert msg)
        (put-text-property (line-beginning-position) (1+ (line-end-position))
                           'keymap 'magit-stgit-patch-map)
        (forward-line)))))

;;; magit-stgit.el ends soon

(define-obsolete-function-alias 'turn-on-magit-stgit 'magit-stgit-mode "2014-08-31")

(provide 'magit-stgit)
;; Local Variables:
;; indent-tabs-mode: nil
;; End:
;;; magit-stgit.el ends here
