;;; clocker.el --- Note taker and clock-in enforcer
;;; Commentary:

;; Copyright (C) 2015-2016 Roman Gonzalez.

;; Author: Roman Gonzalez <romanandreg@gmail.com>
;; Maintainer: Roman Gonzalez <romanandreg@gmail.com>
;; Version: 0.0.11
;; Package-Version: 20190214.1833
;; Package-Commit: c4d76968a49287ce3bac0832bb5d5d076054c96f
;; Package-Requires: ((projectile "0.11.0") (dash "2.10") (spaceline "2.0.1"))
;; Keywords: org

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.  This program is
;; distributed in the hope that it will be useful, but WITHOUT ANY
;; WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public
;; License for more details.  You should have received a copy of the
;; GNU General Public License along with this program.  If not, see
;; <http://www.gnu.org/licenses/>.

(require 'dash)
(require 'em-glob)
(require 'org-clock)
(require 'projectile)
(require 'spaceline)
(require 'vc-git)

;;; Code:

;;;;;;;;;;;;;;;;;;;;
;; customizable variables

(defface clocker-mode-line-clock-in-face
  '((t (:foreground "white" :background "#F2686C" :inherit mode-line)))
  "Clocker's face for CLOCK-IN mode-line message."
  :group 'clocker)

(defcustom clocker-issue-format-regex nil
  "Holds regex that extracts issue-id from a branch name.

When this value is null, clocker won't infer org file names from
branch names."
  :group 'clocker)

(defcustom clocker-extra-annoying t
  "Stops file from being saved when true and not clocked-in.

This is recommended if you really want to enforce yourself to
clock-in."
  :group 'clocker)

(defcustom clocker-project-issue-folder "org"
  "Name of the directory that will hold the org files per issue."
  :group 'clocker)

(defcustom clocker-skip-after-save-hook-on-extensions '("org")
  "Holds file extensions that won't be affected by clocker's `after-save-hook'.

If a file extension is here, the `after-save-hook' won't do any
checks if not clocked in"
  :group 'clocker)


(defcustom clocker-skip-after-save-hook-on-mode '()
  "Holds mode names that won't be affected by clocker's `after-save-hook'.

If a buffer has mode that belongs to this list, the
`after-save-hook' won't do any checks if not clocked in"
  :group 'clocker)

(defcustom clocker-skip-after-save-hook-on-file-name '("COMMIT_EDITMSG")
  "Holds file names that won't be affected by clocker's `after-save-hook'.

If a buffer represents a file with a name that exists on this list, the
`after-save-hook' won't do any checks if not clocked in"
  :group 'clocker)

(defcustom clocker-keep-org-file-always-visible t
  "Opens a buffer with the org-file if hidden.

This happens when clocked-in."
  :group 'clocker)

(defcustom clocker-search-org-buffer-in-all-frames t
  "Search for an org buffer on all frames.

This variable will affect behavior once you are clocked-in, is
particularly handy when you have more than one frame."
  :group 'clocker)

(defvar clocker-on-auto-save nil
  "Indicate if the current save is happening because of an auto-save.

This variable will be set to `t' when a callback registered in
the `auto-save-hook' is called.  Once the clocker
`after-save-hook' is called, this variable is going to be set to nil.")

;;;;;;;;;;;;;;;;;;;;
;; util

(defun clocker-org-clocking-p ()
  "Check if org clock-in is on."
  (and (fboundp 'org-clocking-p)
       (org-clocking-p)))


(eval-after-load 'powerline
  '(spaceline-define-segment clocker-status
     "CLOCK-IN powerline widget."
     (when (and clocker-mode (not (clocker-org-clocking-p)))
       " CLOCK-IN ")
     :face 'clocker-mode-line-clock-in-face))

;; shamelessly stolen from
;; http://stackoverflow.com/questions/5536304/emacs-stock-major-modes-list#answer-19165202
(defun clocker-get-major-modes-list ()
  "Return a list of all major-modes registered on the editor"
  (let (output)
    (mapatoms
     #'(lambda (fn-symbol)
         (and (commandp fn-symbol)
              (string-match "-mode$" (symbol-name fn-symbol))
              ;; auto-loaded
              (or
               (and (autoloadp (symbol-function fn-symbol))
                    (let ((doc (documentation fn-symbol)))
                      (when doc
                        (and
                         (let ((doc-split (help-split-fundoc doc fn-symbol)))
                           (and
                            ;; car is argument list
                            doc-split
                            ;; major mode starters have no arguments
                            (null (cdr (read (car doc-split))))))
                         ;; If the doc contains "minor"...
                         (if (string-match "[mM]inor" doc)
                             ;; it should also contain "major".
                             (string-match "[mM]ajor" doc)
                           ;; else we cannot decide therefrom
                           t)))))
               (null (help-function-arglist fn-symbol)))
              (setq output (cons (symbol-name fn-symbol) output)))))
    output))

;;;;;;;;;;;;;;;;;;;;
;; find buffer with org-file open

(defun clocker-should-perform-save-hook? (file-name)
  "Check if clocker ignores saves on file with extension file-ext"
  (let ((file-ext (and file-name
                       (file-name-extension file-name))))
    (and
     (not (-contains? clocker-skip-after-save-hook-on-file-name (file-name-base file-name)))
     (not (-contains? clocker-skip-after-save-hook-on-extensions file-ext))
     (not (-contains? clocker-skip-after-save-hook-on-mode (symbol-name major-mode))))))

(defun clocker-first-org-buffer ()
  "Return first buffer that has an .org extension."
  (->> (buffer-list)
       (--filter
        (let ((buffer-name (buffer-file-name it)))
          (and buffer-name (string-match ".org$" buffer-name))))
       -first-item))

;;;;;;;;;;;;;;;;;;;;
;; find global org-file (sitting on home most likely)

(defun clocker-get-parent-dir (dir)
  "Return the parent directory path of given DIR."
  (if (or (not dir)
          (string-equal dir "/"))
      nil
    (file-name-directory
     (directory-file-name dir))))

(defun clocker-locate-dominating-file (glob &optional start-dir)
    "Locates a file on the hierarchy tree using a GLOB.

Similar `locate-dominating-file', although accepts a GLOB instead
of simple string.

If START-DIR is not specified, starts in `default-directory`."
    (let* ((dir (or start-dir default-directory))
           (files-found (directory-files dir
                                         nil
                                         (eshell-glob-regexp glob)))
           (full-paths (->> files-found
                            (--mapcat (let ((path (concat dir it)))
                                        (if (file-directory-p path)
                                            '()
                                          (list path)))))))
      (cond
       (full-paths
        (car full-paths))
       ((not (or (string= dir "/")
                 (string= dir "~/")))
        (clocker-locate-dominating-file glob (clocker-get-parent-dir dir)))
       (t nil))))

(defun clocker-find-dominating-org-file ()
  "Lookup on directory tree for a file with an org extension.

returns nil if it can't find any"
  (clocker-locate-dominating-file "*.org"))

;;;;;;;;;;;;;;;;;;;;
;; find org file per-issue

(defun clocker-issue-org-file (project-root issue-id)
  "Use PROJECT-ROOT and ISSUE-ID to infer a file name."
  (concat project-root
          (file-name-as-directory clocker-project-issue-folder)
          (concat issue-id ".org")))

(defun clocker-get-issue-id-from-branch-name (issue-regex branch-name)
  "Use ISSUE-REGEX to get issue-id from a BRANCH-NAME."
  (when (and issue-regex branch-name (string-match issue-regex branch-name))
    (match-string 0 branch-name)))

(defun clocker-find-issue-org-file ()
  "Infer an org file name from issue number on current's branch name.

This works when the `clocker-issue-format-regex` is not nil."
  (when clocker-issue-format-regex
      (let* ((project-root (projectile-project-root))
             (branch-name (car (vc-git-branches)))
             (issue-id (clocker-get-issue-id-from-branch-name clocker-issue-format-regex
                                                                      branch-name)))
        (and issue-id (clocker-issue-org-file project-root issue-id)))))


;;;;;;;;;;;;;;;;;;;;
;; clocked-in functionality

;;;###autoload
(defun clocker-org-clock-goto (&optional select)
  "Open file that has the currently clocked-in entry, or to the
most recently clocked one.

With prefix arg SELECT, offer recently clocked tasks for selection."
  (interactive "@P")
  (let* ((current (current-buffer))
         (recent nil)
         (m (cond
             (select
              (or (org-clock-select-task "Select task to go to: ")
                  (error "No task selected")))
             ((org-clocking-p) org-clock-marker)
             ((and org-clock-goto-may-find-recent-task
                   (car org-clock-history)
                   (marker-buffer (car org-clock-history)))
              (setq recent t)
              (car org-clock-history))
             (t (error "No active or recent clock task"))))
         (org-buffer (marker-buffer m)))

    (unless (get-buffer-window org-buffer
                               (if clocker-search-org-buffer-in-all-frames
                                   t
                                 0))
      (pop-to-buffer org-buffer
                     t ;; display a new window with the org file
                     t ;; don't put this navigation to the cache of visited buffers
                     )
      (if (or (< m (point-min)) (> m (point-max))) (widen))
      (goto-char m)
      (org-show-entry)
      (org-back-to-heading t)
      (org-cycle-hide-drawers 'children)
      (org-reveal)
      (if recent
          (message "No running clock, this is the most recently clocked task"))
      (run-hooks 'org-clock-goto-hook)
      (other-window 1))))

;;;;;;;;;;;;;;;;;;;;
;; main functions

;;;###autoload
(defun clocker-open-org-file ()
  "Open an appropiate org file.

It traverses files in the following order:

1) It tries to find an open buffer that has a file with .org
extension, if found switch to it.

2) If 1 is nil and `clocker-issue-format-regex' is not nil, it
   tries to open/create an org file using the issue number on the
   branch

3) If `clocker-issue-format-regex' is nil, it will traverse your
tree hierarchy and finds the closest org file."
  (interactive)
  (let* ((buffer-orgfile (clocker-first-org-buffer)))
    (cond
     (buffer-orgfile
      (progn
        (delete-other-windows)
        (switch-to-buffer buffer-orgfile)))
     (t
      (let* ((file-orgfile (clocker-find-issue-org-file))
             (file-orgfile (or file-orgfile (clocker-find-dominating-org-file))))
        (if file-orgfile
            (find-file file-orgfile)
          (message "clocker: could not find/infer org file.")))))))

(defun clocker-save-hook (question-msg raise-exception)
  (interactive)
  (if clocker-on-auto-save
      ;; set `clocker-on-auto-save' to nil in case a new save hook is
      ;; called
      (setq clocker-on-auto-save nil)
    ;; else
    (let* ((current-file (buffer-file-name)))
      (when (and current-file
                 (clocker-should-perform-save-hook? current-file))

          (if (not (clocker-org-clocking-p))
              (progn
                (y-or-n-p question-msg)
                (clocker-open-org-file)
                (when raise-exception (throw 'clocker-clock-in t)))
            ;; else
            (when clocker-keep-org-file-always-visible
              (clocker-org-clock-goto nil)))))))

;;;###autoload
(defun clocker-auto-save-hook ()
  "Set `clocker-on-auto-save' to t"
  (interactive)
  (setq clocker-on-auto-save t)
  (when (buffer-file-name)
    (save-buffer)))

;;;###autoload
(defun clocker-before-save-hook ()
  "Execute `clocker-open-org-file' and asks even more annoying questions if not clocked-in."
  (interactive)
  (clocker-save-hook "Won't save until you clock in, continue?" t))

;;;###autoload
(defun clocker-after-save-hook ()
  "Execute `'clocker-open-org-file' and asks annoying questions if not clocked-in."
  (interactive)
  (clocker-save-hook "Did you remember to clock in?" nil))

;;;###autoload
(defun clocker-skip-on-major-mode (a-mode)
  "Add given mode to the
`clocker-skip-after-save-hook-on-mode' list."
  (interactive
   (list (ido-completing-read
          "Which mode? "
          (get-major-modes-list)
          nil
          nil
          (symbol-name major-mode))))
  (when (y-or-n-p
         (format "Are you sure you want to add mode %s to clocker's ignore list" a-mode))
    (add-to-list 'clocker-skip-after-save-hook-on-mode
                 a-mode)))

;;;###autoload
(defun clocker-stop-skip-on-major-mode (a-mode)
  "Remove given mode from
`clocker-skip-after-save-hook-on-mode' list."
  (interactive
   (list (ido-completing-read
          "Which mode? "
          clocker-skip-after-save-hook-on-mode)))
  (delete a-mode clocker-skip-after-save-hook-on-mode))

;;;###autoload
(define-minor-mode clocker-mode
  "Enable clock-in enforce strategies"
  :lighter " Clocker"
  :global t
  (if clocker-mode
      (progn
        (add-hook 'auto-save-hook  'clocker-auto-save-hook t)
        (if clocker-extra-annoying
            (add-hook 'before-save-hook 'clocker-before-save-hook t)
          ;; else
          (add-hook 'after-save-hook 'clocker-after-save-hook t)))
    (progn
      (remove-hook 'before-save-hook 'clocker-before-save-hook)
      (remove-hook 'after-save-hook 'clocker-after-save-hook)
      (remove-hook 'auto-save-hook 'clocker-auto-save-hook))))

(provide 'clocker)

;;; clocker.el ends here
