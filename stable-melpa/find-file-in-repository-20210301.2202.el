;;; find-file-in-repository.el --- Quickly find files in a git, mercurial or other repository

;; Copyright (C) 2012  Samuel Hoffstaetter

;; Author: Samuel Hoffstaetter <samuel@hoffstaetter.com>
;; Keywords: files, convenience, repository, project, source control
;; Package-Version: 20210301.2202
;; Package-Commit: 10f5bd919ce35691addc5ce0d281597a46813a79
;; URL: https://github.com/hoffstaetter/find-file-in-repository
;; Version: 1.3

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides a drop-in replacement for find-file (ie. the
;; "C-x f" command), that auto-completes all files in the current git,
;; mercurial, or other type of repository. When outside of a
;; repository, find-file-in-repository conveniently drops back to
;; using find-file, (or ido-find-file), which makes it a suitable
;; replacement for the "C-x f" keybinding.
;;
;; It is similar to, but faster and more robust than the find-file-in-project
;; package. It relies on git/mercurial/etc to provide fast cached file name
;; completions, which means that repository features such as
;; .gitignore/.hgignore/etc are fully supported out of the box.
;;
;; This library currently has support for:
;;     git, mercurial, darcs, bazaar, monotone, svn
;;
;; By default ido completion is used if ido is enabled. Completion
;; method can be customized via `ffir-completion' variable. Possible
;; values are nil (default), 'find-file, 'ido and 'ivy.
;;
;; Contributions for support of other repository types are welcome.
;; Please send a pull request to
;; https://github.com/hoffstaetter/find-file-in-repository and I will
;; be happy to include your modifications.
;;
;; Recommended keybinding:
;;    (global-set-key (kbd "C-x f") 'find-file-in-repository)

;;; Code:

(defgroup find-file-in-repository nil
  "Find file in repository."
  :group 'convenience)

(defcustom ffir-completion nil
  "Completion framework. Options are nil, find-file, ido and ivy."
  :type 'symbol
  :group 'find-file-in-repository)

(defcustom ffir-git-use-recurse-submodules nil
  "Whether to use --recurse-submodules for git ls-files. Git currently doesn't support combinding this option with --others (show untracked files)"
  :type 'boolean
  :safe 'booleanp
  :group 'find-file-in-repository)

(defcustom ffir-prompt "Find file in repository: "
  "Prompt to display."
  :type 'string
  :safe 'stringp
  :group 'find-file-in-repository)

(defun ffir-shell-command (command file-separator working-dir)
  "Executes 'command' and returns the list of printed files in
   the form '((short/file/name . full/path/to/file) ...). The
   'file-separator' character is used to split the file names
   printed by the shell command and is usually set to \\n or \\0"
  (let* ((default-directory working-dir)
         (command-output (shell-command-to-string command))
         (files (delete "" (split-string command-output file-separator))))
    (mapcar (lambda (file)
              (cons file (expand-file-name file working-dir)))
            files)))

(defun ffir-locate-dominating-file (file name)
  "Identical to 'locate-dominating-file' on modern Emacs. We
  re-implement it here, since locate-dominating-file doesn't
  accept 'name' predicates on older versions of emacs."
  (setq file (abbreviate-file-name file))
  (let ((root nil) try)
    (while (not (or root
                    (null file)
                    (string-match locate-dominating-stop-dir-regexp file)))
      (setq try (if (stringp name)
                    (file-exists-p (expand-file-name name file))
                  (funcall name file)))
      (cond (try (setq root file))
            ((equal file (setq file (file-name-directory
                                     (directory-file-name file))))
             (setq file nil))))
    (if root (file-name-as-directory root))))

(defun ffir-locate-dominating-file-top (start-directory filename)
  "Returns the furthest ancestor directory of 'start-directory'
   that contains a file of name 'filename'"
  (when start-directory
    (let ((next-directory
           (ffir-locate-dominating-file start-directory filename)))
      (if next-directory
          (ffir-locate-dominating-file-top next-directory filename)
        (expand-file-name start-directory)))))

(defun ffir-directory-contains-which-file (file-list directory)
  "Checks which of the files in 'file-list' exists inside
  'directory'. The file-list is a list (filename . value) tuples.
  For the first filename that exists in the directory, the
  corresponding value is returned. If 'directory' contains none
  of the filenames, nil is returned."
  (when file-list
    (let ((filename (expand-file-name (car (car file-list)) directory)))
      (if (file-exists-p filename)
          (cdr (car file-list))
        (ffir-directory-contains-which-file (cdr file-list) directory)))))

(defun ffir-when-ido (ido-value non-ido-value)
  "Returns ido-value when ido is enabled, otherwise returns non-ido-value."
  (if (and (boundp 'ido-mode) ido-mode)
      ido-value
    non-ido-value))

(defvar ffir-avoid-HOME-repository
  't
  "When set to nil, find-file-in-repository will accept the
  user's $HOME directory as a valid repository when it
  contains a .git/.hg/_darcs/(...) file.")

(defvar ffir-repository-types
  `((".git"   . ,(lambda (dir)
                   (ffir-shell-command
                    (if ffir-git-use-recurse-submodules
                        "git ls-files --recurse-submodules -zc --exclude-standard"
                      "git ls-files -zco --exclude-standard")                       "\0" dir)))
    (".hg"    . ,(lambda (dir)
                   (ffir-shell-command "hg locate -0"          "\0" dir)))
    ("_darcs" . ,(lambda (dir)
                   (ffir-shell-command "darcs show files -0"   "\0" dir)))
    (".bzr"   . ,(lambda (dir)
                   (ffir-shell-command
                    "bzr ls --versioned --recursive -0"        "\0" dir)))
    ("_MTN"   . ,(lambda (dir)
                   (ffir-shell-command "mtn list known"        "\n" dir)))

    ;; svn repos must be searched differently from others since
    ;; every svn sub-directory contains a .svn folder as well
    (".svn"   . ,(lambda (start-dir) (ffir-shell-command "svn list" "\n"
                                      (ffir-locate-dominating-file-top
                                       start-dir ".svn")))))
  "List of supported repository types for find-file-in-repository.
  The first entry in each tuple is a file name determining the
  repository type. The second entry in the tuple is a function
  that takes as argument the repository root, and returns the
  list of file names tracked by the repository.")

(defun ffir-ido-setup ()
  "Add fallback bindings to ido keymap while ffir is active."
  (define-key ido-completion-map (kbd "C-x C-f") 'ido-fallback-command)
  (define-key ido-completion-map (kbd "C-x f") 'ido-fallback-command))

(defun ffip-ivy-fallback-command ()
  (interactive)
  (ivy-quit-and-run (command-execute (ffir-default-find-file-command))))

(defun ffir-ivy-make-keymap ()
  "Create a map with fallback bindings to ido keymap while ffir is active."
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x C-f") 'ffip-ivy-fallback-command)
    (define-key map (kbd "C-x f") 'ffip-ivy-fallback-command)
    map))

(defun ffir-find-file (file-list)
  "Actually find file to open, using completing-read."
  (let ((file (completing-read ffir-prompt
                        (mapcar 'car file-list))))
    (find-file (cdr (assoc file file-list)))))

(defun ffir-ido-find-file (file-list)
  "Actually find file to open, using ido."
  (add-hook 'ido-setup-hook 'ffir-ido-setup)
  (unwind-protect
      (let* ((file (ido-completing-read ffir-prompt
                                        (mapcar 'car file-list)))
             (path (or (cdr (assoc file file-list)) file)))
        (cond
         (file (find-file path))
         ((eq ido-exit 'fallback) (ido-find-file))))
    (remove-hook 'ido-setup-hook 'ffir-ido-setup)))

(defun ffir-ivy-find-file (file-list)
  "Actually find file to open, using ivy."
  (let* ((file (ivy-read ffir-prompt
                         (mapcar 'car file-list)
                         :keymap (ffir-ivy-make-keymap)))
               (path (or (cdr (assoc file file-list)) file)))
         (when file (find-file path))))

(defun ffir-default-find-file (file-list)
  "Actually find file to open, taking into account ffir-completion."
  (let ((find-file
         (cond ((eq ffir-completion 'find-file) 'ffir-find-file)
               ((eq ffir-completion 'ido) 'ffir-ido-find-file)
               ((eq ffir-completion 'ivy) 'ffir-ivy-find-file)
               ((if (and (boundp 'ido-mode) ido-mode)
                    'ffir-ido-find-file 'ffir-find-file)))))
    (funcall find-file file-list)))

(defun ffir-default-find-file-command ()
  (cond ((eq ffir-completion 'find-file) 'find-file)
        ((eq ffir-completion 'ido) 'ido-find-file)
        ((if (and (boundp 'ido-mode) ido-mode) 'ido-find-file 'find-file))))

;;;###autoload
(defun find-file-in-repository ()
  "find-file-in-repository will autocomplete all files in the
   current git, mercurial or other type of repository, using
   ido-find-file when available. When the current file is not
   located inside of any repository, falls back on a regular
   find-file operation."
  (interactive)
  (let ((repo-directory (ffir-locate-dominating-file
                         default-directory
                         (lambda (directory)
                           (ffir-directory-contains-which-file
                            ffir-repository-types directory))))
        (home-dir (format "%s/" (getenv "HOME"))))
    ;; check whether we are in a supported repository type
    (if (and repo-directory
             (not (and ffir-avoid-HOME-repository
                       (equal (expand-file-name repo-directory)
                              (expand-file-name home-dir)))))
        ;; auto-complete files tracked by the repository system
        (let* ((repo-directory (expand-file-name repo-directory))
               (file-list (funcall (ffir-directory-contains-which-file
                                    ffir-repository-types repo-directory)
                                   repo-directory)))
          (ffir-default-find-file file-list))
      ;; fall back on regular find-file when no repository can be found
      (command-execute (ffir-default-find-file-command)))))

;;;###autoload
(defalias 'ffir 'find-file-in-repository)

;;;###autoload
(progn
  (put 'ffir-repository-types 'safe-local-variable 'listp)
  (put 'ffir-avoid-HOME-repository 'safe-local-variable 'booleanp))

(provide 'find-file-in-repository)
;;; find-file-in-repository.el ends here
