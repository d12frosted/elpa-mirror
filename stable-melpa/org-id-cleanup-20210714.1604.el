;;; org-id-cleanup.el --- Interactively find, present and maybe clean up unused IDs of org-id     -*- lexical-binding: t; -*-

;; Copyright (C) 2020-2021 Free Software Foundation, Inc.

;; Author: Marc Ihm <1@2484.de>
;; URL: https://github.com/marcIhm/org-id-cleanup
;; Package-Version: 20210714.1604
;; Package-Commit: 416c95fc9ad8551f1d9544f2504c866daac5477e
;; Version: 1.7.0
;; Package-Requires: ((org "9.3") (dash "2.12") (emacs "26.3"))

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
;;

;;; Commentary:

;; Purpose:
;;
;;  Interactively find and clean up unused IDs of org-id.
;;  The term 'unused' refers to IDs, that have been created by org-id
;;  regularly, but are now no longer referenced from anywhere within in org.
;;  This might e.g. happen by deleting a link, that once referenced such an id.
;;
;;  Normal usage of org-id does not lead to a lot of such unused IDs, and
;;  org-id does not suffer much from them.
;;
;;  However, some usage patterns or packages (like org-working-set) may
;;  produce a larger number of such unused IDs; in such cases it might be
;;  helpful to clean up with org-id-cleanup.
;;
;; Setup:
;;
;;  org-id-cleanup should be installed with package.el
;;

;;; Change Log:

;;   Version 1.7
;;
;;   - Compute differences to previous invocation and offer files to be
;;     added back
;;
;;   Version 1.6
;;
;;   - Restructured instructions
;;   - Various clarifications
;;
;;   Version 1.5
;;
;;   - Scan more files for IDs
;;   - Write list of files to log
;;   - Offer to revert all changes
;;   - More hints
;;
;;   Version 1.4
;;
;;   - Clarification regarding archives
;;   - Rely on org-id-files
;;   - Refactoring
;;
;;   Version 1.3
;;
;;   - Write a log of deleted IDs
;;
;;   Version 1.2
;;
;;   - Adding tests
;;   - Preparing for melpa
;;
;;   Version 1.1
;;
;;   - Respecting attachments
;;   - Refactoring
;;
;;   Version 1.0
;;
;;   - Initial Version
;;

;;; Code:

(require 'org)
(require 'button)
(require 'org-attach)
(require 'dash)
(require 'subr-x)
(require 'org-id)

;; Version of this package
(defvar org-id-cleanup-version "1.7.0" "Version of `org-working-set', format is major.minor.bugfix, where \"major\" are incompatible changes and \"minor\" are new features.")

(defvar org-id-cleanup--assistant-buffer-name "*Assistant for deleting IDs*")
(defvar org-id-cleanup--all-steps '(save backup complete-files review-files collect-ids review-ids cleanup-ids save-again) "List of all supported steps.")
(defvar org-id-cleanup--current-step nil "Current step in assistant.")
(defvar org-id-cleanup--files nil "List of all files to be scanned while cleaning ids.")
(defvar org-id-cleanup--unref-unattach-ids nil "List of IDs not referenced from files and not having attachments.  Candidates for deletion.")
(defvar org-id-cleanup--num-deleted-ids 0 "Number of IDs deleted.")
(defvar org-id-cleanup--num-attach 0 "Number of IDs that are referenced by their attachment directory only.")
(defvar org-id-cleanup--num-all-ids 0 "Number of all IDs.")
(defvar org-id-cleanup--log-file-name (concat (file-name-directory org-id-locations-file) "org-id-cleanup-log-of-deletions.org")
 "Filename for log buffer; derived from value of 'org-id-locations-file'.")
(defvar org-id-cleanup--log-buffer nil "Log buffer, once opened.")

;; User-visible function and dispatch
(defun org-id-cleanup ()
  ;; Do NOT edit the part of this help-text before version number. It will
  ;; be overwritten with Commentary-section from beginning of this file.
  ;; Editing after version number is fine.
  ;;
  ;; For Rake: Insert here
  "Interactively find and clean up unused IDs of org-id.
The term 'unused' refers to IDs, that have been created by org-id
regularly, but are now no longer referenced from anywhere within in org.
This might e.g. happen by deleting a link, that once referenced such an id.

Normal usage of org-id does not lead to a lot of such unused IDs, and
org-id does not suffer much from them.

However, some usage patterns or packages (like org-working-set) may
produce a larger number of such unused IDs; in such cases it might be
helpful to clean up with org-id-cleanup.

This is version 1.7.0 of org-id-cleanup.el.

This assistant is the only interactive function of this package.
Detailed explanations are shown in each step; please read them
carefully and then operate the relevant buttons."
  (interactive)
  (org-id-cleanup--do 'save))


(defun org-id-cleanup--do (go-to)
  "Do the work for `org-id-cleanup'.
GO-TO the next step or one of symbols 'previous or 'next."

  ;; check arguments and compute next step
  (setq org-id-cleanup--current-step
        (if (member go-to '(previous next))
            (nth (+ (if (eq go-to 'next) +1 -1)
                    (org-id-cleanup--step-to-num))
                 org-id-cleanup--all-steps)
          go-to))
  
  ;; prepare buffer
  (pop-to-buffer-same-window (get-buffer-create org-id-cleanup--assistant-buffer-name))
  (setq buffer-read-only nil)
  (delete-other-windows)
  (erase-buffer)
  ;; breadcrumbs
  (dolist (st org-id-cleanup--all-steps)
    (insert (propertize (format "%s - " (symbol-name st))
                        'face (if (<= (org-id-cleanup--step-to-num st)
                                      (org-id-cleanup--step-to-num))
                                  'org-agenda-dimmed-todo-face nil))))
  (backward-delete-char 3)
  
  (insert "\n\nThis assistant helps to clean up IDs from your org-files, it tries to remove only IDs, that are not referenced any longer.")
  (fill-paragraph)
  (insert "\n\n")

  ;; common controls
  (when (eq org-id-cleanup--current-step (cl-first org-id-cleanup--all-steps))
    (insert "It operates in steps, and explains what is going to happen in each step; it presents buttons, that when pressed execute the described action and take you to the next step. Pressing a button can be done either with the return-key or with the mouse.")
    (fill-paragraph)
    (insert "\n\n")
    (insert "The line of steps at the top of this window shows the progress within this assistant. No IDs will be deleted unless you confirm so in step 'cleanup-ids'")
    (fill-paragraph)
    (insert "\n\n\n"))
  (insert (format "Step %d of %s: %s"
                  (1+ (org-id-cleanup--step-to-num))
                  (length org-id-cleanup--all-steps)
                  (symbol-name org-id-cleanup--current-step)))
  (when (> (org-id-cleanup--step-to-num) 0)
    (insert (propertize "   (or back to " 'face 'org-agenda-dimmed-todo-face))
    (insert-button
     (propertize
      (symbol-name (nth (1- (org-id-cleanup--step-to-num)) org-id-cleanup--all-steps))
      'face 'org-agenda-dimmed-todo-face) 'action
     (lambda (_) (org-id-cleanup--do 'previous)))
    (insert (propertize ")" 'face 'org-agenda-dimmed-todo-face)))
  (insert "\n\n\n")

  ;; dispatch according to step
  (funcall (intern (concat "org-id-cleanup--step-" (symbol-name org-id-cleanup--current-step))))

  ;; finish buffer before leaving it to the user to press any buttons therein; see individual steps
  (recenter -1)
  (message "Please read comments and instructions and proceed by clicking the appropriate buttons.")
  (setq buffer-read-only t))


;; Individual steps
(defun org-id-cleanup--step-save ()
  "Step from `org-id-cleanup--do'."

  (let (pt)
    (insert "You need to save all org buffers and update org-id locations: ")

    (insert-button
     "go" 'action
     (lambda (_)
       (goto-char (point-max))
       (let ((inhibit-read-only t))
         (insert "\n\n\nSaving buffers ... ")
         (redisplay)
         (org-save-all-org-buffers)
         (insert "done\nUpdating id locations ... ")
         (redisplay)
         (org-id-update-id-locations))
       ;; continue with next step
       (org-id-cleanup--do 'next)))

    (setq pt (point))
    (when (fboundp 'org-working-set)
      (insert "\n\n\nNote: You have loaded the package org-working-set. If you use it regularly you may want to truncate its journal to a reasonable length (e.g. 90 days back), because it keeps links to all nodes that have been in your working-set in the past; that way the related IDs can not be deleted, because they are referenced at least once.")
      (fill-paragraph))
    (goto-char pt)))


(defun org-id-cleanup--step-backup ()
  "Step from `org-id-cleanup--do'."

  (if (not org-id-track-globally)
      (insert "\n\nThe variable `org-id-track-globally' is not set, therefore this assistant cannot be useful and will not continue.\n")

    (insert "Please make sure that you have a backup, if something goes wrong !\n\n\nThis assistant cannot do this for you; so please come back when done\nand press this ")
    (insert-button "button" 'action
                     (lambda (_) (org-id-cleanup--do 'next)))))


(defun org-id-cleanup--step-complete-files ()
  "Step from `org-id--cleanup-do'."
  (let* ((head-of-files "--- start of extra files to be scanned ---")
         (tail-of-files "---   end of extra files to be scanned ---")
         (text-point-files (org-id-cleanup--get-latest-log-heading))
         (files-was (nth 2 text-point-files))
         (preset-files
          (org-id-cleanup--normalize-files
           ;; this mirrors the list of files constructed in org-id-update-id-locations
           (org-agenda-files t org-id-search-archives)
           (unless (symbolp org-id-extra-files)
	     org-id-extra-files)
           org-id-files
           user-init-file
           custom-file))
         pt pt2 was-but-not-is)
    (forward-line -2)
    (insert (propertize "Scroll down for continue-button.\n\n" 'face 'org-agenda-dimmed-todo-face))
    (setq pt2 (point))
    (insert (format "Complete the list of %d files that will be scanned and might be changed:\n\n" (length preset-files)))
    (org-id-cleanup--insert-files preset-files)
    (insert "\n\nSee the end of this screen to learn, what files should be present in the list above.")
    
    (insert "\n\n\nIf you want more files or directories to be scanned,\nplease add them to the list of extra files below: ")
    (insert-button
     "browse" 'action
     (lambda (_)
       (let ((file (read-file-name "Choose a single files or a whole directory: " org-directory))
             (inhibit-read-only t)
             pt)
         (when file
           (goto-char (point-min))
           (search-forward head-of-files)
           (forward-line 1)
           (setq pt (point))
           (search-forward tail-of-files)
           (forward-line 0)
           (insert file)
           (insert "\n")
           (add-text-properties pt (point) '(inhibit-read-only t))))))
    (insert "\n\n" head-of-files "\n")
    (setq pt (point))
    (setq was-but-not-is (-difference files-was preset-files))
    (mapc (lambda (x) (insert (format "%s\n" x))) was-but-not-is)
    (add-text-properties pt (point) '(inhibit-read-only t))
    (insert tail-of-files "\n")
    (insert (propertize "(usual editing commands (e.g. C-k) apply.)\n" 'face 'org-agenda-dimmed-todo-face))
    (when was-but-not-is
      (insert (propertize "\nPlease note: " 'face 'org-warning))
      (insert "The list above has been prepopulated with all the files, that have been present in the previous invocation but are NOT present any longer; you may remove them though, e.g. if they do not contain any IDs.")
      (fill-paragraph)
      (insert (format "\nThe headline of the previous invocation was (click to visit):\n\n  "))
      (org-id-cleanup--insert-button-browse-previous text-point-files)
      (insert "\n"))

    (insert "\n\nAfter that, you may ")
    (insert-button
     "continue" 'action
     (lambda (_)
       ;; change global state
       (setq org-id-cleanup--files
             (org-id-cleanup--normalize-files
              preset-files
              (org-id-cleanup--collect-extra-files head-of-files)))
       ;; continue with next step
       (org-id-cleanup--do 'next)))
    (setq pt (point))

    (insert "\n\n\n")
    (insert (propertize "What files should be present in the list above ?" 'face 'org-level-2))
    (insert "\n\nThe list should include all files that:\n\n"
            " - Contain nodes with IDs            (which will be removed, if not referenced from anywhere)\n"
            " - Have references or links to IDs   (which protect those IDs from being removed)\n\n"
            "(of course, most of your org-files may contain both)")
    (insert "\n\nPlease note: If the list of files and directories is incomplete, this might lead to IDs being removed, that are still referenced from a file that is missing in the list.")
    (fill-paragraph)

    (insert "\n\nIDs may also appear in lisp-files, so your user init file has already been added. But if you use IDs from within other lisp-code, this will not be noticed. However, to protect such IDs once and for all, it is enough to list them anywhere within your org-files (e.g. below a dedicated heading 'protected IDs'). ")
    (fill-paragraph)

    (insert "\n\nMoreover, you might have the habit of using IDs completely outside of org (e.g. in your calendar); such use cannot be noticed by this package, and if there are no other references from within org, these IDs will be deleted. But again, to protect those, it is enough to list them anywhere within your org-files.")
    (fill-paragraph)

    (insert "\n\nPlease note, that regarding archives, this assistant relies on the handling configured for org-id in `org-id-search-archives'. Especially: If you do not search your archives for ids, references within your archives will not protect IDs from beeing removed.")
    (fill-paragraph)
    (goto-char pt2)))


(defun org-id-cleanup--step-review-files ()
  "Step from `org-id--cleanup-do'."
  (let ((text-point-files (org-id-cleanup--get-latest-log-heading))
        pt)
    (forward-line -2)
    (insert (propertize "Scroll down for continue-button.\n\n" 'face 'org-agenda-dimmed-todo-face))
    (setq pt (point))
    (insert (format "Review the list of %d files that will be scanned; the org-file among them might be changed:\n\n" (length org-id-cleanup--files)))
    (org-id-cleanup--insert-files org-id-cleanup--files)
    (insert "\n\nThis list contains any extra files or directories you might have added in the previous step.")
    (insert "\n\n\nIf you want to compare this list with previous invocations, you may browse:\n\n  ")
    (org-id-cleanup--insert-button-browse-previous text-point-files)
    (insert "\n\n\nWhen satisfied, ")
    (insert-button
     "continue" 'action
     (lambda (_)
       ;; continue with next step
       (org-id-cleanup--do 'next)))
    (insert (propertize "\n\n\nOr, to add more files, go " 'face 'org-agenda-dimmed-todo-face))
    (insert-button
     (propertize "back" 'face 'org-agenda-dimmed-todo-face) 'action
     (lambda (_) (org-id-cleanup--do 'previous)))
    (goto-char pt)))
     

(defun org-id-cleanup--step-collect-ids ()
  "Step from `org-id--cleanup-do'."
  (insert (format "Now the relevant %d files will be scanned for IDs.\n\n" (length org-id-cleanup--files)))
  (insert "Any IDs, that are used for attachment directories will be kept; the same is true,\nif the node is merely tagged as having an attachment.\n\n")
  (insert "From now on, please refrain from leaving this assistant to create links to IDs, because they would not be taken into account any more.")
  (fill-paragraph)
  (insert "\n\n\nScan files for IDs and ")

  (insert-button "continue" 'action 'org-id-cleanup--action-collect-ids))


(defun org-id-cleanup--step-review-ids ()
  "Step from `org-id--cleanup-do'."
  (let ((head-of-ids "--- List of IDs to be deleted ---")
        pt pt2 pct)
    (setq pct (* 100 (/ (float (length org-id-cleanup--unref-unattach-ids)) org-id-cleanup--num-all-ids)))
    (insert (format "Find below the list of IDs (%d out of %d) that will be deleted; pressing TAB on an id will show the respective node.\n" (length org-id-cleanup--unref-unattach-ids) org-id-cleanup--num-all-ids))
    (insert (format "%d IDs are not in the list and will be kept, because they have associated attachments.\n\n" org-id-cleanup--num-attach))
    (insert "You may remove IDs from the list as you like to keep them from being deleted.\nUsual editing commands (e.g. C-k) apply.")
    (insert (format "\n\nThe list below contains %.1f %% of all IDs; if this is more than expected, the list of files to be scanned might have been incomplete and you may want to " pct))
    (insert-button "add files to be scanned" 'action
                   (lambda (_) (org-id-cleanup--do 'complete-files)))
    (insert " for references to IDs.")
    (fill-paragraph)
    (insert "\n\nIf satisfied, ")

    (insert-button
     "continue" 'action
     (lambda (_)
       (local-unset-key (kbd "<tab>")) ; tab is no longer needed in next step
       ;; change global state
       (setq org-id-cleanup--unref-unattach-ids (org-id-cleanup--collect-ids head-of-ids))
       ;; continue with next step
       (org-id-cleanup--do 'next)))

    (setq pt (point))
    (insert (propertize "\n\ndeletion will not happen yet." 'face 'org-agenda-dimmed-todo-face))
    (insert "\n\n\n" head-of-ids "\n")
    (setq pt2 (point))
    (dolist (id org-id-cleanup--unref-unattach-ids)
      (insert id "\n"))
    (add-text-properties pt2 (point) '(inhibit-read-only t))
    (goto-char pt)
    (local-set-key (kbd "<tab>") 'org-id-cleanup--peek-into-id)))


(defun org-id-cleanup--step-cleanup-ids ()
  "Step from `org-id--cleanup-do'."
  (let (pt)
    (insert "Please make sure, that you have not manually created new links referencing any IDs while the last two steps of this assistant were active.")
    (fill-paragraph)
    (insert
     (format "\n\nFor your reference, a log of all changes will be appended to %s.\n" org-id-cleanup--log-file-name)
     "This log will contain sufficient information (id, filename, point and outline path) to manually restore selected IDs later; you may browse it before saving your files in the last step.")
    (fill-paragraph)
    (insert "\n\n\n")
    (insert (propertize (format "  >>>  To REMOVE %s IDs out of %d UNCONDITIONALLY, press this  " (length org-id-cleanup--unref-unattach-ids) org-id-cleanup--num-all-ids) 'face 'org-warning))
    
    (insert-button (propertize "button" 'face 'org-warning) 'action 'org-id-cleanup--action-cleanup-ids)
    
    (insert (propertize "  <<<" 'face 'org-warning))
    (setq pt (point))
    (insert "\n\n\nOr, to review those IDs, go ")
    (insert-button
     "back" 'action
     (lambda (_) (org-id-cleanup--do 'previous)))
    (insert "\n")
    (goto-char pt)))


(defun org-id-cleanup--step-save-again ()
  "Step from `org-id--cleanup-do'."
  (insert (format "   Deleted %d IDs (out of %d).\n\n\n" org-id-cleanup--num-deleted-ids org-id-cleanup--num-all-ids))
  (insert (format "A log of all changes has been appended to %s\n" org-id-cleanup--log-file-name))
  (insert "\nYou may want to ")
  (insert-button
   "browse" 'action
   (lambda (_) (pop-to-buffer org-id-cleanup--log-buffer)))
  (insert " this file to see, what has been removed from your org-buffers but not saved yet.\n")
  (insert "If you want to discard those changes alltogether, you may ")
  (insert-button
   "revert all" 'action 'org-id-cleanup--action-revert)
  (insert " changed org buffers, as the files have not been saved yet.")
  (fill-paragraph)
       
  (insert "\n\n\nFinally, if satisfied, you should again save all org buffers, update id locations and save them: ")

  (insert-button
   "go" 'action
   (lambda (_)
     (let ((inhibit-read-only t))
       (goto-char (point-max))
       (insert "\n\n\nSaving buffers ... ")
       (redisplay)
       (org-save-all-org-buffers)
       (insert "done\nUpdating ids ... ")
       (redisplay)
       (org-id-update-id-locations org-id-cleanup--files)
       (insert "done\nSaving id locations ...")
       (redisplay)
       (org-id-locations-save)
       
       (insert "done\n\nAssistant done; you may close this window ...\n")))))


;; Some steps have longer actions, that need their own function
(defun org-id-cleanup--action-collect-ids (_)
  "Action for `org-id-cleanup--step-collect-ids.
Collect ids not referenced from anywhere; the list of IDs will then be used in the next step"
  (let ((counters (make-hash-table :test 'equal))
        (scanned 0)
        (attach 0)
        ids pgreporter unref unref-unattach)

    ;; collect all IDs
    (maphash (lambda (id _) (unless (string= id "") (push id ids))) org-id-locations)
    (setq pgreporter (make-progress-reporter (format "Scanning %d files..." (length org-id-cleanup--files)) 1 (length org-id-cleanup--files)))

    ;; visit each file an count occurrences of IDs
    (dolist (file org-id-cleanup--files)
      (with-current-buffer (find-file-noselect file)
        (dolist (id ids)
          (goto-char (point-min))
          (while (search-forward id nil t)
            (cl-incf (gethash id counters 0)))))
      (progress-reporter-update pgreporter (cl-incf scanned)))

    ;; keep only IDs, that have appeared only once
    (maphash (lambda (id count) (if (eq count 1) (push id unref))) counters)

    ;; keep only IDs, that are not used in attachment dir
    (dolist (id unref)
      (let ((pos (org-id-find id)))
        (with-current-buffer  (find-file-noselect (car pos))
          (goto-char (cdr pos))
          (if (or (and (fboundp 'org-attach-dir-from-id) ; only known in emacs 27
		       (string= (org-attach-dir-from-id id) (org-attach-dir)))
		  ;; assume id is used in attachments even if only last 12 chars match
                  (cl-search (substring id -12) (org-attach-dir))
                  (member "ATTACH" (org-get-tags))
                  (member "attach" (org-get-tags))
                  (member org-attach-auto-tag (org-get-tags)))
              (cl-incf attach)
            (push id unref-unattach)))))

    (progress-reporter-done pgreporter)

    ;; change global state
    (setq org-id-cleanup--unref-unattach-ids unref-unattach)
    (setq org-id-cleanup--num-all-ids (length ids))
    (setq org-id-cleanup--num-attach attach)
    ;; continue with next step
    (org-id-cleanup--do 'next)))


(defun org-id-cleanup--action-cleanup-ids (_)
  "Action for `org-id-cleanup--step-cleanup-ids.
Actually delete IDs."

  (let ((scanned 0)
        (inhibit-read-only t)
        pgreporter)
    ;; prepare
    (org-id-cleanup--open-log (length org-id-cleanup--unref-unattach-ids) org-id-cleanup--num-all-ids)
    (with-current-buffer org-id-cleanup--assistant-buffer-name
      (goto-char (point-max))
      (setq org-id-cleanup--num-deleted-ids 0)
      (insert "\n\nRemoving unused IDs ... ")
      (redisplay))
    (setq pgreporter (make-progress-reporter (format "Removing %d IDs..." (length org-id-cleanup--unref-unattach-ids)) 1 (length org-id-cleanup--unref-unattach-ids)))

    ;; loop of deletion
    (dolist (id org-id-cleanup--unref-unattach-ids)
      (pop-to-buffer (find-file-noselect (gethash id org-id-locations)))
      (goto-char (point-min))
      (search-forward id)
      ;; by prior computation, id should only appear once as the id property of a node; anything else is an internal error
      (unless (string= id (org-id-get))
        (error "Expected id of this node to be %s, but found %s" id (org-id-get)))
      ;; log first
      (org-id-cleanup--append-to-log id (buffer-file-name) (point) (-concat (org-get-outline-path) (list (nth 4 (org-heading-components)))))
      ;; then delete
      (org-delete-property "ID")
      (org-remove-empty-drawer-at (point))
      (cl-incf org-id-cleanup--num-deleted-ids)
      (progress-reporter-update pgreporter (cl-incf scanned)))

    (progress-reporter-done pgreporter)
    (org-id-cleanup--write-log)
    (sleep-for 1)
    
    ;; change global state
    (setq org-id-cleanup--unref-unattach-ids nil)

    ;; continue with next step
    (org-id-cleanup--do 'next)))


(defun org-id-cleanup--action-revert (_)
  "Revert all changes done by assistant."
   (let ((num 0) fname txt)
     (dolist (buf (buffer-list))
       (setq fname (buffer-file-name buf))
       (when (and fname
                  (buffer-modified-p buf)
                  (file-readable-p fname)
                  (member fname org-id-cleanup--files))
         (with-current-buffer buf
           (with-demoted-errors "Error: %S"
             (revert-buffer t t)
             (cl-incf num)))))
     (message "Reverted changes to %d files" num)
     (setq txt (with-temp-buffer
                 (insert (format "Reverted changes to %d files at " num))
                 (org-insert-time-stamp nil t t)
                 (buffer-string)))
     (with-current-buffer org-id-cleanup--log-buffer
       (goto-char (point-max))
       (org-up-heading-all 1)
       (org-next-visible-heading 1)
       (insert "  - " txt "\n\n"))
     (with-current-buffer org-id-cleanup--assistant-buffer-name
       (goto-char (point-max))
       (let ((inhibit-read-only t))
         (insert "\n\n" txt)))))



;; Some helper functions
(defun org-id-cleanup--insert-files (files)
  "Insert given list of FILES into current buffer using full window width."
  (let ((tab-stop-list '(2 42 82)))
    (dolist (name files)
      (if (> (+ (indent-next-tab-stop (current-column))
                (length name))
             (- (window-width) 10))
          (insert "\n"))
      (tab-to-tab-stop)
      (insert name))))


(defun org-id-cleanup--insert-button-browse-previous (tpf)
  "Insert a button to browse previous file."
  (insert-button
   (nth 0 tpf) 'action
   (lambda (_)
     (find-file-other-window org-id-cleanup--log-file-name)
     (with-selected-window (get-buffer-window (get-file-buffer org-id-cleanup--log-file-name))
       (org-set-startup-visibility)
       (goto-char (nth 1 tpf))
       (recenter 2)))))


(defun org-id-cleanup--collect-extra-files (head)
  "Collect and return edited list of extra file.
Argument HEAD is a marker-string that precedes the list of files in buffer."
  (let (file files)
    (goto-char (point-min))
    (search-forward head)
    (delete-trailing-whitespace (point) (point-max))
    (forward-line)
    (while (not (looking-at "---"))
      (setq file (buffer-substring (point) (point-at-eol)))
      (cond
       ((file-directory-p file)
        (setq files (append files (directory-files file t org-agenda-file-regexp))))
       ((file-exists-p file)
        (push file files))
       (t (error "%s is neither a file nor a directory" file)))
      (forward-line))
    files))


(defun org-id-cleanup--collect-ids (head)
  "Collect and return edited list of IDs from content of buffer.
Argument HEAD is a marker-string, that precedes the list of ids in buffer."
  (let (id ids)
    (goto-char (point-min))
    (search-forward head)
    (delete-trailing-whitespace (point) (point-max))
    (forward-line)
    (while (not (= (point) (point-max)))
      (setq id (string-trim (buffer-substring (point-at-bol) (point-at-eol))))
      (when (> (length id) 0)
        (unless (>= (length id) 12) ; 12 is the length of an org-generated id, uuidgen generates longer ids
          (error "Id %s does not seem to be a valid uuid" id))
        (push id ids))
      (forward-line))
    ids))


(defun org-id-cleanup--peek-into-id ()
  "Show node with if of current line in other window."
  (interactive)
  (let* ((id (string-trim (buffer-substring (point-at-bol) (point-at-eol))))
         (marker (org-id-find id t)))
    (unless marker
      (error "Cannot find ID %s" id))
    (delete-other-windows)
    (pop-to-buffer (marker-buffer marker) '(display-buffer-below-selected (inhibit-same-window . t)) t)
    (goto-char marker)
    (search-forward id)
    (beginning-of-line)
    (org-show-context 'tree)
    (recenter)
    (other-window 1)
    (message "Context of node with id %s" id)))


(defun org-id-cleanup--step-to-num (&optional step)
  "Return number of current STEP (defaults to `org-id-cleanup--current-step') within list of all steps (counting from 0)."
  (unless step
    (setq step org-id-cleanup--current-step))
  (- (length org-id-cleanup--all-steps)
     (length (member step org-id-cleanup--all-steps))))


(defun org-id-cleanup--normalize-files (&rest lists-or-strings)
  "Bring a LISTS-OR-STRINGS of filenames in standard form.
By sorting, removing dups and mapping to true filename."
  (delete-consecutive-dups
   (sort
    (mapcar #'file-truename
            (-flatten lists-or-strings))
    'string<)))


(defun org-id-cleanup--get-latest-log-heading ()
  "Get latest heading from log buffer."
  (or (ignore-errors
        (save-window-excursion
          (save-current-buffer
            (find-file org-id-cleanup--log-file-name)
            (goto-char (point-max))
            (if (re-search-backward "^\* " nil t)
                (let (files)
                  (ignore-errors
                    (save-excursion
                      (search-forward-regexp (org-item-re))
                      (setq files (mapcar (lambda (x)
                                            (car (last (split-string (car x)))))
                                          (cdr (org-list-parse-list))))))
                  (list (org-get-heading t t t t) (point) files))
              nil))))
      (list "no prior heading" 0 nil)))


(defun org-id-cleanup--open-log (num-to-be-deleted num-all)
  "Open Log buffer.
NUM-TO-BE-DELETED and NUM-ALL used for explanation."
  (setq org-id-cleanup--log-buffer (find-file-noselect org-id-cleanup--log-file-name))
  (with-current-buffer org-id-cleanup--log-buffer
    (goto-char (point-max))
    (org-mode)
    (insert "\n\n* org-id-cleanup at ")
    (org-insert-time-stamp nil t t)
    (insert (format " scanned %d files and deleted %d IDs out of %d\n" (length org-id-cleanup--files) num-to-be-deleted num-all))
    (insert "\n** List of files scanned\n\n")
    (let ((i 0))
      (mapc (lambda (name) (insert (format "   - %d : %s\n" (cl-incf i) name))) (sort org-id-cleanup--files 'string<)))
    (insert "\n** List of IDs deleted\n")
    (save-buffer)))


(defun org-id-cleanup--append-to-log (id filename point path)
  "Append to Log buffer.
ID, FILENAME, POINT and PATH specify detailed location of the id deleted."
  (with-current-buffer org-id-cleanup--log-buffer
    (insert "\n")
    (insert (format "   - ID :: %s\n" id))
    (insert (format "     - Filename :: %s\n" filename))
    (insert (format "     - Point :: %d\n" point))
    (insert "    - Path to node:\n")
    (dolist (ti path)
      (insert (format "       - %s\n" ti)))
    (delete-blank-lines)))


(defun org-id-cleanup--write-log ()
  "Write Log buffer to its file."
  (with-current-buffer org-id-cleanup--log-buffer
    (save-buffer)))


(provide 'org-id-cleanup)

;; Local Variables:
;; fill-column: 75
;; comment-column: 50
;; End:

;;; org-id-cleanup.el ends here
