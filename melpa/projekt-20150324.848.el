;;; projekt.el --- some kind of staging for CVS -*- lexical-binding: t -*-

;; Author: Engelke Eschner <tekai@gmx.li>
;; Version: 0.1
;; Package-Version: 20150324.848
;; Package-Commit: a65e554e5d8b0def08c5d06f3fe34fec40bebd83
;; Package-Requires: ((emacs "24"))
;; Created: 2013-04-04

;; LICENSE
;; Copyright (c) 2013 Engelke Eschner
;; All rights reserved.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;     * Redistributions of source code must retain the above copyright
;;       notice, this list of conditions and the following disclaimer.
;;     * Redistributions in binary form must reproduce the above
;;       copyright notice, this list of conditions and the following
;;       disclaimer in the documentation and/or other materials provided
;;       with the distribution.
;;     * Neither the name of the projekt.el nor the names of its
;;       contributors may be used to endorse or promote products derived
;;       from this software without specific prior written permission.

;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
;; "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
;; LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
;; A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT
;; HOLDER> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
;; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
;; PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
;; PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
;; OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
;; (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
;; OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:
;; DESCRIPTION
;; TODO

;; Ideas
;; - Add list of files  in commit to menu (with function
;;   switch-to-buffer or find-file)
;; - Better remove/add (no dups)
;; - deployment ?
;; - foo deploy ?
;; - bak?
;; - keep patch/rev stuff
;; - use vc instead of straight cvs
;; - parse .project for more data?
;; TODO
;; - only update menu after projekt-add-file or edit/save
;; - update menu on buffer/project switch
;; - sort commit list
;; - never add a file twice

;;; Code:
(defvar projekt-mode-map
  (let ((map (make-sparse-keymap)))

    ;; Keybindings
    (define-key map (kbd "C-c p a") 'projekt-add-file)
    (define-key map (kbd "C-c p e") 'projekt-edit-list)
    (define-key map (kbd "C-c p d") 'projekt-diff)

    ;; Menu in reverse order
    (define-key map [menu-bar projekt]
      (cons "Projekt" (make-sparse-keymap "Projekt")))

    (define-key map [menu-bar projekt commit-0]
      '(menu-item "--single-dashed-line"))

    (define-key map [menu-bar projekt edit-list]
      '(menu-item "Edit commit list" projekt-edit-list))

    (define-key map [menu-bar projekt add-file]
      '(menu-item "Add current file to commit list" projekt-add-file))

    map))

(defun projekt-update-menu ()
  "Update the menu to add entries for the current commit files."
  (let* ((prj (projekt-get))
         (root (plist-get (cdr prj) :dir))
         (commit (plist-get (cdr prj) :commit))
         (map (lookup-key projekt-mode-map [menu-bar projekt])))
    (save-current-buffer
      (let ((buf (if (bufferp commit)
                     buf
                   (find-file-noselect commit)))
            (new-menu)
            (n 0))
        (set-buffer buf)
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward "^\\([^\n]+\\)\n" nil t)
            (let ((file (buffer-substring (match-beginning 1)
                                          (match-end 1))))
              (incf n)
              (message file)
              (define-key-after map
                  (vector (intern (format "commit-%d" n)))
                `(menu-item ,file (lambda () (interactive) (projekt-edit-file ,file)))
                'commit-0))))
        projekt-mode-map))))

(defun projekt-clean-menu ()
  "Remove the commit files from the menu."
  (let ((map (cdr (lookup-key projekt-mode-map [menu-bar projekt]))))
    ;; cdr until commit-0
    (while (and map (not (equal 'commit-0 (caar map))))
      (setq map (cdr map)))
    ;; cut off after commit-0
    (when (and map (equal 'commit-0 (caar map)))
      (rplacd map nil))
    projekt-mode-map))

;;;###autoload
(define-minor-mode projekt-mode
    "Toggle projekt mode.
Interactively with no argument, this command toggles the mode.
A positive prefix argument enables the mode, any other prefix
argument disables it.  From Lisp, argument omitted or nil enables
the mode, `toggle' toggles the state.

When projekt mode is enabled it allows to to create a commit list
and add files or edit it."
  ;; The initial value.
  nil
  ;; The indicator for the mode line.
  " .prj"
  ;; The minor mode bindings.
  projekt-mode-map
  :group 'projekt)

(defvar projekts-list nil "Keeps a list of open projects.")
; '((<tld> :dir "/path/to/project" :commit "commit-file-name OR buffer")))


(defun projekt-hook ()
  "Hook to start projekt mode."
  (when (and buffer-file-name (projekt-get))
    (projekt-mode t)
    (add-hook 'menu-bar-update-hook 'projekt-menu-hook nil t)))

(add-hook 'find-file-hook 'projekt-hook)

(defun projekt-menu-hook ()
  "Update the commit list in the menu."
  (when projekt-mode
    (projekt-clean-menu)
    (projekt-update-menu)))

(defun projekt-edit-file (file)
  "Open FILE in current project."
  (find-file (concat (projekt/dir) file)))

(defun projekt-get ()
  "Get data for the current project."
  (when (projekt-find-root)
    (let* ((root (projekt-find-root))
           (name (file-name-nondirectory (directory-file-name root)))
           (prj (assoc name projekts-list)))
      (when (not prj)
        (setq prj (list name :dir root :commit (concat root "commit")))
        (setq projekts-list (cons prj projekts-list)))
      prj)))

(defun projekt-file-p ()
  "Check if the file associated with the current buffer is in a project."
  (when buffer-file-name
    (let (projekt-root)
      (dolist (prj projekts-list)
        (setq projekt-root (plist-get (cdr prj) :dir))
        (when (string-equal
               projekt-root
               (substring buffer-file-name 0 (length projekt-root)))
          prj)))))

(defvar projekt-comment-buf nil
  "Buffer for commenting a commit.")

(defun projekt-find-root ()
  "Find the root path of a project."
  (let ((root (locate-dominating-file default-directory ".project")))
    (when root
      (expand-file-name (file-truename root)))))

(defun projekt-add-file ()
  "Add current file to commit list."
  (interactive)
  (let* ((prj (projekt-get))
         (root (plist-get (cdr prj) :dir))
         (commit (plist-get (cdr prj) :commit))
         (file (expand-file-name (file-truename (buffer-file-name)))))
    (save-current-buffer
      (let ((buf (if (bufferp commit)
                     buf
                   (find-file-noselect commit))))
        (set-buffer buf)
        (goto-char (- (point-max) 1))
        (when (not (looking-at "\n"))
          (goto-char (point-max))
          (insert ?\n))
        (goto-char (point-max))
        (insert (substring file (length root)))
        (insert ?\n)
        (save-buffer buf)))
    (projekt-update-menu)))

(defun projekt-edit-list ()
  "Edit the commit list."
  (interactive)
  (let* ((root (projekt-find-root))
         (commit (concat root "commit")))
    (when (file-exists-p commit)
      (find-file commit))))

(defun projekt-commit ()
  "Open commit list then commit files in list."
  (interactive)
  (if (eq (current-buffer) projekt-comment-buf)
      (projekt-cvs-commit)
    (let ((root (projekt-find-root))
          (file (buffer-file-name)))
      (if (not (string= file (concat root "commit")))
          (projekt-edit-list)
        (projekt-get-comment)))))

(defun projekt-get-comment ()
  (setq projekt-comment-buf (generate-new-buffer "cvs commit comment"))
  (switch-to-buffer projekt-comment-buf))

(defun projekt/commit (&optional prj)
  (plist-get (cdr (if prj prj (projekt-get))) :commit))

(defun projekt/dir (&optional prj)
  (plist-get (cdr (if prj prj (projekt-get))) :dir))

(defun projekt-get-commmit ()
  "Return the commit buffer, open when necessary."
  (let* ((prj (projekt-get))
         (commit (projekt/commit prj)))
    (if (bufferp commit)
        commit
      (find-file-noselect commit))))

(defun projekt-cvs-commit ()
  "Take buffer content and use it as commit comment"
  (let ((comment (buffer-string))
        (prj (projekt-get))
        (buf (projekt/commit prj))
        (root (projekt/dir prj))
        files)
    (set-buffer buf)

    (goto-char (point-min))
    (while (re-search-forward "^ *\\([^()\n]*[^()\n ]\\) *\n" nil t)
      (let ((file (buffer-substring-no-properties
                   (match-beginning 1) (match-end 1))))
        (setq file (shell-quote-argument file))
        (setq files (cons file files))))
    (setq files (mapconcat 'identity files " "))

    (setq comment (replace-regexp-in-string "\\\\" "\\\\\\\\" comment))
    (setq comment (replace-regexp-in-string "\"" "\\\\\"" comment))
    (cd-absolute root)
    (shell-command (concat "cvs commit -m \"" comment "\" " files))
    (kill-buffer projekt-comment-buf)
    (setq projekt-comment-buf nil)))

(defun projekt-cvs-remove ()
  (interactive)
  (projekt-add-file)
  (delete-file (buffer-file-name))
  (shell-command (concat "cvs remove " (projekt-buffer-file))))

(defun projekt-cvs-add ()
  (interactive)
  (projekt-add-file)
  (shell-command (concat "cvs add " (projekt-buffer-file))))

(defun projekt-buffer-file ()
  (string-match ".*/" (buffer-file-name))
  (substring (buffer-file-name) (match-end 0)))

(defun projekt-commit-list ()
  (let* ((prj (projekt-get))
         (root (plist-get (cdr prj) :dir))
         (commit (plist-get (cdr prj) :commit))
         list)
    (save-current-buffer
      (let ((buf (if (bufferp commit)
                     buf
                   (find-file-noselect commit))))
        (set-buffer buf)
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward "^\\([^\n]+\\)\n" nil t)
            (let ((file (buffer-substring (match-beginning 1)
                                          (match-end 1))))
              (setq list (cons file list)))))))
    list))

(defun projekt-diff ()
  "Show diffs of all files to be committed."
  (interactive)
  (let ((files (projekt-commit-list))
        (diff-buffer (get-buffer-create "*projekt diff*"))
        (proj-dir (projekt/dir))
        ;; HACK prevent outbut in echo area by shell-command
        (max-mini-window-height 0))
    (when (not (null files))
      (setq files (sort files 'string-lessp))
      (set-buffer diff-buffer)
      (setq default-directory proj-dir)
      (shell-command
       (concat "cvs diff "
               (mapconcat 'identity diff-switches " ")
               " "
               (mapconcat 'identity files " "))
       diff-buffer)
      (diff-mode)
      (setq buffer-read-only 1)
      (pop-to-buffer diff-buffer 'other-window))))

(provide 'projekt)
;;; projekt.el ends here
