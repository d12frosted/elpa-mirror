;;; erk.el --- Elisp (GitHub) Repository Kit  -*- lexical-binding: t; -*-

;; Copyright (C) 2022 Positron Solutions

;; Author:  <author>
;; Keywords: convenience
;; Package-Version: 20230511.251
;; Package-Commit: f6cca4647538c4dc659f07669938f7e795dba4ee
;; Version: 0.2.0
;; Package-Requires: ((emacs "28.1") (auto-compile "1.2.0") (dash "2.18.0"))
;; Homepage: http://github.com/positron-solutions/elisp-repo-kit

;; Permission is hereby granted, free of charge, to any person obtaining a copy of
;; this software and associated documentation files (the "Software"), to deal in
;; the Software without restriction, including without limitation the rights to
;; use, copy, modify, merge, publish, distribute, sub-license, and/or sell copies of
;; the Software, and to permit persons to whom the Software is furnished to do so,
;; subject to the following conditions:

;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;; IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
;; FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
;; COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
;; IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;; CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;; Set up Emacs package with GitHub repository configuration, complete with
;; Actions CI, tests, lints, and a licensing scheme all ready to go.  Included
;; commands are focused on productivity, appropriate for professional
;; development in elisp.  The goal of the package is streamline authoring &
;; distributing new Emacs packages.  It provides a well-integrated but rigid
;; scheme, aka opinionated.
;;
;; The package also uses its own hosted source as a substrate for creating new
;; packages.  It will clone its source repository and then perform renaming &
;; re-licensing.  Simply call `erk-new' to start a new package.  The
;; README documents remaining setup steps on GitHub and in preparation for
;; publishing on MELPA.
;;
;; As a development aid, the package is versatile enough to work on some elisp
;; packages that were not descended from its own source.  The scope of
;; functionality is primarily to interface with linting and testing frameworks,
;; both in batch and interactive workflows.

;;; Code:

;; see flake.nix for providing dependencies for CI and local development.
(require 'project)
(require 'auto-compile)
(require 'dash)
(require 'ert)
(require 'vc)

(eval-when-compile (require 'subr-x))

(defgroup erk nil "Elisp repository kit." :prefix 'erk :group 'erk)

(defcustom erk-github-package-name "elisp-repo-kit"
  "Default GitHub <project> for cloning templates.
If you rename this repository after forking, you need to set this
to clone from within the fork."
  :group 'erk
  :type 'string)

(defcustom erk-package-prefix "erk"
  "The prefix is used to features and file names."
  :group 'erk
  :type 'string)

(defcustom erk-github-userorg "positron-solutions"
  "Default GitHub <user-or-org> for cloning templates.
If you fork this repository, you need to set this to clone it
from within the fork."
  :group 'erk
  :type 'string)

(defconst erk--gpl3-notice ";; This program is free software; \
you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.")

(defconst erk--rename-maps
  '(( nil "gpl-3.0.txt" "COPYING")
    ("lisp/" "erk.el" nil)
    ("test/" "erk-test.el" nil))
  "List of (directory file replacement-file) forms.")

(defconst erk--files-with-strings
  '("README.org"
    "CONTRIBUTING.org"
    "lisp/erk.el"
    "test/erk-test.el"
    ".github/run-shim.el"))

(defconst erk--delete-files
  '(".github/FUNDING.yml")
  "Files that would require other accounts to migrate.")

(defconst erk--remove-strings
  '("(ERK)")
  "Strings that vanish in renaming.")

(defun erk--project-root ()
  "Return project root or buffer directory."
  (let ((project (project-current)))
    ;; TODO remove pre-28 support
    (or (if (version<= emacs-version "28.0")
            (car (with-suppressed-warnings
                     ((obsolete project-roots))
                   (funcall #'project-roots project)))
          (funcall #'project-root project))
        default-directory)))

(defun erk--reload (features dir)
  "Reload FEATURES, found in DIR."
  (dolist (feature features)
    (when (featurep feature) (unload-feature feature 'force)))
  (let ((load-path (append (list dir) load-path))
        (load-prefer-newer t)
        (auto-compile-on-load-mode t)
        (auto-compile-on-save-mode t)
        ;; ask user to save buffers in the current project
        (save-some-buffers-default-predicate #'save-some-buffers-root))
    (save-some-buffers)
    (dolist (feature features)
      (let ((elc (concat dir "/" (symbol-name feature) ".elc")))
        (unless (file-exists-p elc)
          (byte-compile-file (concat dir "/" (symbol-name feature) ".el"))))
      (require feature))))

(defun erk--dir-features (dir)
  "Return list of features provided by elisp files in DIR.
Except autoloads."
  (let* ((package-files (directory-files dir nil (rx ".el" string-end)))
         (package-files (->> package-files
                             (--reject (string-match-p (rx "autoloads.el" string-end) it)))))
    (mapcar
     (lambda (f) (intern (string-remove-suffix ".el" f)))
     package-files)))

(defun erk--package-features ()
  "List the features defined by the project's package.
This assumes the convention of one elisp file per feature and
feature name derived file name"
  (erk--dir-features (concat (erk--project-root) "lisp" )))

(defun erk--test-features ()
  "List the features defined in project's test packages.
This assumes the convention of one elisp file per feature and
feature name derived file name"
  (erk--dir-features (concat (erk--project-root) "test" )))

;;;###autoload
(defun erk-reload-project-package ()
  "Reload the features this project provides.
The implementation assumes all packages pass package lint,
providing a feature that matches the file name.

This function should attempt not to fail.  It is infrastructure
for development, and being lenient for degenerate cases is fine."
  (interactive)
  (let* ((project-root (erk--project-root))
         (lisp-subdir (concat project-root "lisp"))
         (project-elisp-dir (if (file-exists-p lisp-subdir) lisp-subdir
                              project-root))
         (package-features (erk--dir-features project-elisp-dir)))
    (erk--reload package-features project-elisp-dir)))

;;;###autoload
(defun erk-reload-project-tests ()
  "Reload test features that this project provides.
The implementation assumes all packages pass package lint,
providing a feature that matches the file name.

This function should attempt not to fail.  It is infrastructure
for development, and being lenient for degenerate cases is fine."
  (interactive)
  (let* ((project-root (erk--project-root))
         (lisp-subdir (concat project-root "test"))
         (project-test-dir (if (file-exists-p lisp-subdir) lisp-subdir
                             project-root))
         (package-features (--reject
                            (string-match-p (symbol-name it) (rx "-test.el" eol))
                            (erk--dir-features project-test-dir))))
    (erk--reload package-features project-test-dir)))

;;;###autoload
(defun erk-ert-rerun-this-no-reload ()
  "Rerun the ert test at point, but don't reload anything.
Use this when debugging with external state or debugging elisp
repo kit itself, which may behave strangely if reloaded in the
middle of a command."
  (interactive)
  (save-excursion
    (beginning-of-defun)
    (let* ((form (funcall load-read-function (current-buffer)))
           (name (elt form 1)))
      (ert `(member ,name)))))

;;;###autoload
(defun erk-ert-rerun-this ()
  "Rerun the ert test at point.
Will reload all features and test features."
  (interactive)
  (erk-reload-project-package)
  (erk-reload-project-tests)
  (save-excursion
    (beginning-of-defun)
    (let* ((form (funcall load-read-function (current-buffer)))
           (name (elt form 1)))
      (ert `(member ,name)))))

(defun erk-ert-project-results-buffer ()
  "Return an ERT buffer name based on project name.")

(defun erk-ert-project-selector ()
  "Return a selector for just this project's ERT test.
This selector generates the symbols list before that selector
will run, so new features or new symbols only available after
reload will not be picked up.  Run this after any necessary
feature reloading."
  (let* ((test-features (erk--test-features))
         (test-symbols (->> test-features
                            (-map #'symbol-file)
                            (--map (cdr (assoc it load-history)))
                            (-flatten-n 1)
                            (--filter (eq 'define-symbol-props (car it)))
                            (-map #'cdr)
                            (-flatten-n 2))))
    (message "test-symbols: %s" test-symbols)
    `(satisfies ,(lambda (test)
                   (member (ert-test-name test) test-symbols)))))

;;;###autoload
(defun erk-ert-project ()
  "Run Ert interactively, with selector for this project."
  (interactive)
  (erk-reload-project-package)
  (erk-reload-project-tests)
  (ert (erk-ert-project-selector)))

(defmacro erk--nze (process-form error)
  "Error if there is a non-zero exit.
PROCESS-FORM is the process call that should return zero.
ERROR is the error message."
  `(unless (eq ,process-form 0)
     (pop-to-buffer "erk-clone")
     (error ,error)))

(defun erk--rename-package (dir old-package new-package)
  "Rename FILES in DIR.
`erk--rename-map' is a list of (subdir filename
replacement-filename) triples.  When subdir is nil, it means use
DIR.  If replacement-filename is nil means replace OLD-PACKAGE
with NEW-PACKAGE, using `replace-regexp-in-string'.  DIR is the
root of where we are renaming.  Existing files will be
clobbered."
  (mapc (lambda (f) (delete-file (concat (file-name-as-directory dir) f)))
        erk--delete-files)

  (mapc (lambda (rename-map)
          (let* ((dir (concat dir (or (pop rename-map) "")))
                 (src (pop rename-map))
                 (replacement-filename (pop rename-map))
                 (git-bin (executable-find "git"))
                 (output (get-buffer-create "erk-clone"))
                 (dest (or replacement-filename
                           (replace-regexp-in-string old-package new-package src)))
                 (default-directory dir))
            (when (file-exists-p dest)
              (erk--nze
               (call-process git-bin nil output nil "rm" "-f" dest)
               (format "Could not delete: %s" dest)))
            (erk--nze
             (call-process git-bin nil output nil "mv" src dest)
             (format "Could not move: %s to %s" src dest))))
        erk--rename-maps))

(defun erk--nodash (prefix)
  "Strip dash from PREFIX if present."
  (if (string-match-p (rx "-" eol) prefix)
      (substring prefix 0 (1- (length prefix)))
    prefix))

(defun erk--prefix-match (prefix)
  "Create somewhat collision-safe regex for PREFIX."
  (rx (or whitespace punctuation bol)
      (group (literal (erk--nodash prefix)))
      (or whitespace punctuation eol)))

(defun erk--replace-strings (dir package-name package-prefix author user-org email)
  "Replace values in files that need renaming or re-licensing.
DIR is where we are replacing.  PACKAGE-NAME is the new
package.  PACKAGE-PREFIX is the elisp prefix.  AUTHOR will be
used in copyright notices.  USER-ORG will be used as the first
part of the new github path.  EMAIL is shown after AUTHOR in
package headers."
  (let ((default-directory dir)
        (erk-github-path (concat erk-github-userorg "/"
                                 erk-github-package-name))
        (github-path (concat user-org "/" package-name))
        (package-prefix package-prefix)
        (replace-prefix (erk--prefix-match erk-package-prefix))
        (capitalized-package-title
         (string-join (mapcar #'capitalize
                              (split-string package-name "-"))
                      " "))
        (replace-package-title
         (string-join (mapcar #'capitalize
                              (split-string erk-github-package-name "-"))
                      " ")))
    (mapc
     (lambda (file)
       (with-current-buffer (find-file-noselect (concat dir file) t t)
         ;; append new author to copyright
         (print (format "visiting: %s" (buffer-file-name)))
         (mapc (lambda (s)
                 (while (re-search-forward (rx (literal s)) nil t)
                   (replace-match "")
                   (goto-char (point-min))))
               erk--remove-strings)
         (when (re-search-forward (rx bol ";; Copyright") nil t)
           (end-of-line)
           (insert ", " author))
         (goto-char (point-min))
         (when (re-search-forward (rx "<author>" eol) nil t)
           (replace-match (concat author " <" email ">") nil t))
         (goto-char (point-min))
         ;; replace license with GPL3 notice
         (when (re-search-forward ";; Permission \\(.\\|\n\\)*SOFTWARE.$" nil t)
           (replace-match erk--gpl3-notice nil t))
         (goto-char (point-min))
         ;; update github paths for README links
         (while (re-search-forward erk-github-path nil t)
           (replace-match github-path nil t))
         (goto-char (point-min))
         ;; replace package prefix.  Uses group replacement.
         (while (re-search-forward replace-prefix nil t)
           (replace-match package-prefix nil t nil 1))
         (goto-char (point-min))
         ;; update remaining package name strings.
         (while (re-search-forward erk-github-package-name nil t)
           (replace-match package-name nil t))
         (goto-char (point-min))
         (while (re-search-forward replace-package-title nil t)
           (replace-match capitalized-package-title nil t))
         (save-buffer 0)
         (kill-buffer)))
     erk--files-with-strings)))

;;;###autoload
(defun erk-clone (clone-root package-name user-org &optional rev)
  "Clone elisp-repo-kit to CLONE-ROOT and apply rename.
PACKAGE-NAME will instruct git how to name the clone.  USER-ORG
is the user or organization you will use for your GitHub
repository.  REV can be used to check out a specific revision.
Warning!  The revision may have lost compatibility with the
rename script.  Each rev is intended only to be able to rename
itself, as a quine and for forking as a new template repository."
  (interactive "DClone to directory:")
  (if-let ((git-bin (executable-find "git")))
      (let ((default-directory clone-root)
            (output (get-buffer-create "erk-clone")))
        (erk--nze
         (call-process
          git-bin nil output nil
          "clone"
          (format "https://github.com/%s/%s.git"
                  erk-github-userorg erk-github-package-name)
          (concat default-directory "/" package-name))
         "Clone failed")
        (let ((default-directory (concat clone-root "/" package-name))
              (rev (when rev (if (string-empty-p rev) nil rev))))
          (when rev (erk--nze
                     (call-process git-bin nil output nil "checkout" rev)
                     (format "Checkout %s failed." rev)))
          (erk--nze
           (call-process "rm" nil output nil "-rf" ".git")
           "Removing old history failed.")
          (erk--nze
           (call-process git-bin nil output nil "init") "Git initialization failed.")
          (erk--nze
           (call-process git-bin nil output nil "add" ".") "Git add all failed.")
          (erk--nze
           (call-process git-bin nil output nil "remote" "add" "origin"
                         (format "git@github.com:%s/%s.git"
                                 user-org package-name))
           "Adding new remote failed.")
          ;; return value for renaming
          (concat clone-root "/" package-name "/")))
    (error "Could not find git executible")))

;;;###autoload
(defun erk-rename-relicense (clone-dir package-name package-prefix author user-org email)
  "Rename and relicense your clone of ERK.
CLONE-DIR is your elisp-repo-clone root.  PACKAGE-NAME should be
the long name of the package, what will show up in melpa
etc. PACKAGE-PREFIX is the elisp symbol prefix.  AUTHOR will be used
in copyright notices.  USER-ORG is either your user or
organization, which forms the first part of a github repo path.
EMAIL is shown after AUTHOR in package headers.

This command replaces all instances of:

1. package name
2. author name (appended to copyright)
3. MIT license with GPL3 license notices in package files (not test files or CI)
4. github organization
5. COPYING is changed to just the GPL3.

Then renames the files to reflect package name

Finally, MIT licenses are swapped with GPL3 license notices.
Re-licensing is fully permitted by the MIT license and intended
by the author of this repository."
  (interactive "DCloned directory: \nsPackage name: \nsAuthor: \
\nsGitHub organization or username: \nsEmail: ")
  (erk--replace-strings
   clone-dir package-name package-prefix author user-org email)
  (erk--rename-package clone-dir erk-package-prefix package-name))

;;;###autoload
(defun erk-new (package-name package-prefix clone-root author user-org email &optional rev)
  "Clone elisp-repo-kit, rename, and re-license in one step.
CLONE-ROOT is where you want to clone your package to (including
the clone dir).  PACKAGE-NAME should be the long name of the
package, what will show up in melpa etc.  PACKAGE-PREFIX can be
either the same as the package or a contracted form, such as an
initialism.  AUTHOR will be used in copyright notices.  USER-ORG
is either your user or organization, which forms the first part
of a github repo path.  EMAIL is shown after AUTHOR in package
headers.  Optional REV is either a tag, branch or revision used
in git checkout.

See comments in `erk-clone' and `erk-rename-relicense' for
implementation information and more details about argument usage."
  (interactive
   (let*
       ((package-name
         (read-string
          (format "Package name, such as %s: " erk-github-package-name)
          "foo"))
        (package-prefix
         (erk--nodash
          (read-string
           (format "Package prefix, such as %s: " erk-package-prefix))))
        (clone-root
         (directory-file-name
          (read-directory-name "Clone root: " default-directory)))
        (author
         (let ((default (when (executable-find "git")
                          (string-trim
                           (shell-command-to-string "git config user.name")))))
           (read-string "Author: " default)))
        (user-org (read-string "User or organization name: "))
        (email
         (let ((default (when (executable-find "git")
                          (string-trim
                           (shell-command-to-string "git config user.email")))))
           (read-string "Email: " default)))
        (rev (read-string
              "Rev, tag, or branch (empty implies default branch): ")))
     (list package-name package-prefix clone-root author user-org email rev)))
  (erk-rename-relicense
   (erk-clone clone-root package-name user-org rev)
   package-name package-prefix author user-org email))

(provide 'erk)
;;; erk.el ends here
