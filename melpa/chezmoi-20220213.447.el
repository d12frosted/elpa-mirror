;;; chezmoi.el --- A package for interacting with chezmoi -*- lexical-binding: t -*-

;; Author: Harrison Pielke-Lombardo
;; Maintainer: Harrison Pielke-Lombardo
;; Version: 1.0.0
;; Package-Version: 20220213.447
;; Package-Commit: 16ceb4f0ec8d7f1d0af25c62bcb76800066442f0
;; Package-Requires: ((emacs "26.1") (magit "3.0.0"))
;; Homepage: http://www.github.com/tuh8888/chezmoi.el
;; Keywords: vc


;; This file is not part of GNU Emacs

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; For a full copy of the GNU General Public License
;; see <http://www.gnu.org/licenses/>.


;;; Commentary:

;; Chezmoi is a dotfile management system that uses a source-target state
;; architecture. This package provides convenience functions for maintaining
;; synchronization between the source and target states when making changes to
;; your dotfiles through Emacs. It provides alternatives to 'find-file' and
;; 'save-buffer' for source state files which maintain synchronization to the
;; target state. It also provides diff/ediff tools for resolving when dotfiles
;; get out of sync. Dired and magit integration is also provided.

;;; Code:

(require 'magit)
(require 'cl-lib)

(defun chezmoi--select-file (files prompt f)
  "Call F on the selected file from FILES, giving PROMPT."
  (funcall f (completing-read prompt files)))

(defun chezmoi--shell-files (cmd)
  "Helper function to parse files from CMD."
  (let ((result (shell-command-to-string cmd)))
    (split-string result "\n")))

(defun chezmoi-source-file (target-file)
  "Return the source file corresponding to TARGET-FILE."
  (let* ((cmd (concat "chezmoi source-path " (when target-file (shell-quote-argument target-file))))
         (files (chezmoi--shell-files cmd)))
    (cl-first files)))

(defvar chezmoi--source-state-prefix-attrs
  '("after_"
    "before_"
    "create_"
    "dot_"
    "empty_"
    "encrypted_"
    "exact_"
    "executable_"
    "literal_"
    "modify_"
    "once_"
    "onchange_"
    "private_"
    "readonly_"
    "remove_"
    "run_"
    "symlink_")
  "Source state attribute prefixes.")

(defvar chezmoi--source-state-suffix-attrs
  '(".literal"
    ".tmpl")
  "Source state attribute suffixes.")

(chezmoi--unchezmoi-source-file-name "~/.local/share/chezmoi/exact_help/dot_clojure/executable_literal_run_deps.edn.tmpl.literal.tmpl")
"~/.local/share/chezmoi/help/.clojure/literal_run_deps.edn.literal.tmpl"
(defun chezmoi--unchezmoi-source-file-name (source-file)
  "Remove chezmoi attributes from SOURCE-FILE."
  (let* ((base-name (file-name-base source-file))
         (ext (file-name-extension source-file))
         (base-name (if ext (file-name-with-extension base-name ext)
                      base-name))
         ;; TODO Handle ".literal" suffix properly.
         (base-name (cl-reduce (lambda (s attr) (string-replace attr "" s))
                               chezmoi--source-state-suffix-attrs
                               :initial-value base-name))
         (dir (file-name-directory source-file))
         (dir (when dir (cl-reduce (lambda (s attr) (let ((replacement (if (string= "dot_" attr) "." "")))
                                                 (string-replace attr replacement s)))
                                   chezmoi--source-state-prefix-attrs
                                   :initial-value dir)))
         (stop-parsing nil)
         attr)
    (while (and (not stop-parsing) (setq attr (cl-some (lambda (attr) (when (string-prefix-p attr base-name) attr)) chezmoi--source-state-prefix-attrs)))
      (when (string= "literal_" attr) (setq stop-parsing t))
      (setq base-name (substring base-name (length attr)))
      (when (string= "dot_" attr) (setq base-name (concat "." base-name))))

    (file-name-concat dir base-name)))

(defun chezmoi-target-file (source-file)
  "Return the target file corresponding to SOURCE-FILE."
  (let* ((to-find (chezmoi--unchezmoi-source-file-name source-file))
         (potential-targets (cl-remove-if-not (lambda (f)
                                                (let* ((dir (string-replace "~" "~/.local/share/chezmoi" (file-name-directory f)))
                                                       (base (string-replace "." "" (file-name-base f)))
                                                       (ext (file-name-extension f))
                                                       (corrected-f (file-name-concat dir (if ext (file-name-with-extension base ext) base)))
                                                       (trying (expand-file-name corrected-f)))
                                                  (string= trying to-find)))
                                              (chezmoi-managed-files))))
    (cond ((zerop (length potential-targets)) (progn (message "No target found") nil))
          ((not (= 1 (length potential-targets)))
           (progn (message "Multiple targets found: %s. Using first" potential-targets)
                  (cl-first potential-targets)))
          (t (cl-first potential-targets)))))

(defun chezmoi-managed ()
  "List all files and directories managed by chezmoi."
  (let* ((cmd "chezmoi managed")
         (files (chezmoi--shell-files cmd)))
    (cl-map 'list (lambda (file) (concat "~/" file)) files)))

(defun chezmoi-managed-files ()
  "List only files managed by chezmoi."
  (cl-remove-if #'file-directory-p (chezmoi-managed)))

(defun chezmoi-write (&optional target-file)
  "Run =chezmoi apply= on the TARGET-FILE.
This overwrites the target with the source state."
  (interactive)
  (let ((f (if target-file target-file buffer-file-name))
        (cmd (if target-file "chezmoi apply " "chezmoi apply --source-path ")))
    (if (= 0 (shell-command (concat cmd (shell-quote-argument f))))
        (message "Wrote %s" f)
      (message "Failed to write file"))))

(defun chezmoi-diff (arg)
  "View output of =chezmoi diff= in a diff-buffer.
If ARG is non-nil, switch to the diff-buffer."
  (interactive "i")
  (let ((b (get-buffer-create "*chezmoi-diff*")))
    (with-current-buffer b
      (erase-buffer)
      (shell-command "chezmoi diff" b))
    (unless arg
      (switch-to-buffer b)
      (diff-mode)
      (whitespace-mode 0))
    b))

(defun chezmoi-changed-files ()
  "Use chezmoi diff to return the files that have changed."
  (let ((line-beg nil))
    (with-current-buffer (chezmoi-diff t)
      (goto-char (point-max))
      (let ((files nil))
        (while (setq line-beg (re-search-backward "^\\+\\{3\\} .*" nil t))
          (let ((file-name (substring
                            (buffer-substring-no-properties line-beg
                                                            (line-end-position))
                            5)))
            (push (concat "~" file-name) files)))
        files))))

(defun chezmoi-find ()
  "Edit a source file managed by chezmoi.
If the target file has the same state as the source file,add a hook to
'save-buffer' that applies the source state to the target state. This way, when
the buffer editing the source state is saved the target state is kept in sync.
Note: Does not run =chezmoi edit="
  (interactive)
  (chezmoi--select-file (chezmoi-managed-files)
                        "Select a dotfile to edit: "
                        (lambda (file)
                          (find-file (chezmoi-source-file file))
                          (let ((mode (assoc-default
                                       (file-name-nondirectory file)
                                       auto-mode-alist
                                       'string-match)))
                            (when mode (funcall mode)))
                          (message file)
                          (unless (member file (chezmoi-changed-files))
                            (add-hook 'after-save-hook (lambda () (chezmoi-write nil)) 0 t)))))

(defun chezmoi-ediff ()
  "Choose a dotfile to merge with its source using ediff.
Note: Does not run =chezmoi merge=."
  (interactive)
  (chezmoi--select-file (chezmoi-changed-files)
                        "Select a dotfile to merge: "
                        (lambda (file)
                          (ediff-files (chezmoi-source-file file) file))))

(defun chezmoi-magit-status ()
  "Show the status of the chezmoi source repository."
  (interactive)
  (magit-status-setup-buffer (chezmoi-source-file nil)))

(defun chezmoi--select-files (files prompt f)
  "Iteratively select file from FILES given PROMPT and apply F to each selected.
Selected files are removed after they are selected."
  (let ((files (cl-copy-list files)))
    (while files
      (chezmoi--select-file files
                            (concat prompt " (C-g to stop): ")
                            (lambda (file)
                              (funcall f file)
                              (setq files (remove file files)))))))

(defun chezmoi-write-from-target (target-file)
  "Apply the TARGET-FILE's state to the source file buffer.
Useful for files which are autogenerated outside of chezmoi."
  (interactive (list (chezmoi-target-file buffer-file-name)))
  (with-current-buffer (find-file-noselect (chezmoi-source-file target-file))
    (replace-buffer-contents (find-file-noselect target-file))))

(defun chezmoi-write-files ()
  "Force overwrite multiple dotfiles with their source state."
  (interactive)
  (chezmoi--select-files (chezmoi-changed-files)
                         "Select dotfile to apply source state changes"
                         #'chezmoi-write))


(defun chezmoi-write-files-from-target ()
  "Force overwrite the source state of multiple dotfiles with their target state."
  (interactive)
  (chezmoi--select-files (chezmoi-changed-files)
                         "Select a dotfile to overwrite its source state with target state"
                         #'chezmoi-write-from-target))

(defun chezmoi-open-target ()
  "Open buffer's target file."
  (interactive)
  (find-file (chezmoi-target-file buffer-file-name)))

(defun chezmoi-dired-add-marked-files ()
  "Add files marked in Dired to source state."
  (interactive)
  (dolist (file (dired-get-marked-files))
    (shell-command (concat "chezmoi add " (shell-quote-argument file)))))

(provide 'chezmoi)

;;; chezmoi.el ends here
