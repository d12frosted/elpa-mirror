;;; org-multi-wiki.el --- Multiple wikis based on Org mode -*- lexical-binding: t -*-

;; Copyright (C) 2020 Akira Komamura

;; Author: Akira Komamura <akira.komamura@gmail.com>
;; Version: 0.4.3
;; Package-Version: 20210324.1820
;; Package-Commit: bf8039aadddaf02569fab473f766071ef7e63563
;; Package-Requires: ((emacs "26.1") (dash "2.12") (s "1.12") (org-ql "0.5") (org "9.3"))
;; Keywords: org outlines files
;; URL: https://github.com/akirak/org-multi-wiki

;; This file is not part of GNU Emacs.

;;; License:

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; This library provides an infrastructure for multiple wikis on a
;; single machine, based on org-mode.

;; For configuration, see README.

;; For practical use, see helm-org-multi-wiki.el.

;;; Code:

(require 'subr-x)
(require 'dash)
(require 's)
(require 'org)
(require 'ol)

(declare-function org-ql-select "ext:org-ql-select")

(defvar recentf-exclude)

(defgroup org-multi-wiki nil
  "Multiple wikis based on org-mode."
  :group 'org)

;;;;  Custom variables
(defvar org-multi-wiki-file-regexp)

(defun org-multi-wiki--extensions-to-regexp (extensions)
  "Produce a regular expression for a list of file EXTENSIONS."
  (concat "\\`[^.].*\\(?:"
          (mapconcat (lambda (ext)
                       (concat "\\(?:"
                               (regexp-quote ext)
                               "\\)"))
                     extensions
                     "\\|")
          "\\)\\'"))

(defcustom org-multi-wiki-file-extensions '(".org" ".org.gpg")
  "List of file extensions for wiki entries.

The first one is used to create a new file by default."
  :type '(repeat string)
  :set (lambda (sym value)
         (set sym value)
         (setq org-multi-wiki-file-regexp
               (org-multi-wiki--extensions-to-regexp value)))
  :group 'org-multi-wiki)

(defvar org-multi-wiki-recentf-regexp nil)

(defun org-multi-wiki--recentf-regexp (namespace-list)
  "Compile `org-multi-wiki-recentf-regexp' for later use.

NAMESPACE-LIST should be the value of the namespace list."
  (when namespace-list
    (let ((dirs (->> namespace-list
                     (--map (let ((dir (file-name-as-directory
                                        (expand-file-name (nth 1 it)))))
                              (->> (list dir (ignore-errors
                                               (file-truename dir)))
                                   (-non-nil)
                                   (-uniq))))
                     (-flatten-n 1))))
      (rx-to-string `(and bol
                          (or ,@dirs)
                          (+ anything)
                          (or ,@org-multi-wiki-file-extensions)
                          eol)))))

(defcustom org-multi-wiki-namespace-list
  nil
  "List of namespace configurations for wikis.

Each entry in this variable should be a list containing the
following items, in that order:

- A symbol to uniquely identify the directory.
- A file path to the directory containing Org files.
- A plist to set directory-specific options.

The plist can contain the following keys which correspond certain
custom variables for the global setting:

- `:top-level-link-fragments'"
  :type '(repeat (list (symbol :tag "Namespace")
                       (directory :tag "Directory")
                       (plist :inline t :tag "Options"
                              :options
                              (((const :doc "Generate a link fragment to each top-level heading."
                                       :top-level-link-fragments)
                                (boolean))
                               ((const :doc "Recursively search files in subdirectories"
                                       :recursive)
                                (boolean))))))
  :set (lambda (sym value)
         (set sym value)
         (setq org-multi-wiki-recentf-regexp
               (org-multi-wiki--recentf-regexp value)))
  :group 'org-multi-wiki)

(define-obsolete-variable-alias 'org-multi-wiki-directories
  org-multi-wiki-namespace-list "0.3")

(defcustom org-multi-wiki-default-namespace
  (caar org-multi-wiki-namespace-list)
  "Default namespace of wikis.

This should be the first element of one of the entries in
`org-multi-wiki-namespace-list'."
  :type 'symbol
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-recentf-exclude nil
  "Whether to exclude wiki files from recent files."
  :type 'boolean
  :set (lambda (symbol value)
         (set symbol value)
         (require 'recentf)
         (if value
             (add-to-list 'recentf-exclude #'org-multi-wiki-recentf-file-p t)
           (delq #'org-multi-wiki-recentf-file-p recentf-exclude))))

(defcustom org-multi-wiki-escape-file-name-fn
  #'org-multi-wiki-escape-file-name-camelcase-1
  "Function used to generated an escaped file name from a heading."
  :type 'function
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-entry-template-fn
  #'org-multi-wiki-default-entry-template-fn
  "Function to create an initial Org entry from a heading."
  :type 'function
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-display-buffer-fn
  #'pop-to-buffer
  "Function used to display Org buffers."
  :type 'function
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-ignore-missing-directories nil
  "Whether to prevent an error when a directory is missing.

When non-nil, return an empty result from
`org-multi-wiki-entry-files' when the directory does not exist."
  :type 'boolean
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-filename-removed-words
  '("a" "an" "the")
  "List of words that should be removed from file names."
  :type '(repeat string)
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-want-custom-id nil
  "Whether to prompt for a CUSTOM_ID property.

If this variable is non-nil, non-top-level headings in a wiki
entry will always be linked with a CUSTOM_ID."
  :type 'boolean
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-custom-id-escape-fn
  #'org-multi-wiki-default-custom-id-escape-fn
  "Function used to escape CUSTOM_ID properties.

The function takes a heading as the argument."
  :type 'function
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-top-level-link-fragments nil
  "Whether to add an ID/headline fragment to a link to each top level heading."
  :type 'boolean
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-allow-omit-namespace t
  "Whether to omit the namespace ID in a link to the same namespace."
  :type 'boolean
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-rename-buffer t
  "Whether to rename Org buffers to represent the directory.

When this variable is non-nil, Org buffers opened this package
are renamed so that they contain their directory IDs.

This is a hack for `helm-org-ql'.

This setting does not affect buffers that are already open"
  :type 'boolean
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-rg-executable "rg"
  "Executable name of ripgrep."
  :type 'filename
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-rg-args '("--color=never" "--files")
  "Command line arguments passed to rg."
  :type '(repeat string)
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-buffer-name-fn
  #'org-multi-wiki-buffer-name-1
  "Function to determine the names of Org buffers.

The function takes a plist as arguments.
See `org-multi-wiki-buffer-name-1' for an example."
  :type 'function
  :group 'org-multi-wiki)

(defcustom org-multi-wiki-removal-block-functions
  '(org-multi-wiki-entry-file-p)
  "Block removal of a subtree if any of these functions returns non-nil.

This is curently effective in
`org-multi-wiki-create-entry-from-subtree'.

These functions take no argument and should return non-nil if the
user must not muve the subtree at point to another file."
  :type '(repeat function)
  :group 'org-multi-wiki)

;;;; Other variables
(defvar org-multi-wiki-current-namespace org-multi-wiki-default-namespace)

(defvar-local org-multi-wiki-mode-hooks-delayed nil
  "Whether `run-mode-hooks' has been delayed in the buffer.")

(defvar org-multi-wiki-gpg-skip-file-list nil)
(defvar org-multi-wiki-gpg-skip-namespace-list nil)
(defvar org-multi-wiki-gpg-skip-globally nil)

;;;; Macros
(defmacro org-multi-wiki--def-option (key)
  "Define a function to retrieve KEY option."
  (let ((func (intern (format "org-multi-wiki--%s" key)))
        (plist-key (intern (concat ":" key)))
        (default-var (intern (concat "org-multi-wiki-" key))))
    `(defun ,func (namespace)
       ,(format "Retrieve the value of %s for NAMESPACE." key)
       (if-let (entry (assoc namespace org-multi-wiki-namespace-list))
           (let ((plist (cddr entry)))
             (or (plist-get plist ,plist-key)
                 (symbol-value ,default-var)))
         (user-error "No entry for %s in org-multi-wiki-namespace-list"
                     namespace)))))

(org-multi-wiki--def-option "top-level-link-fragments")

;;;; Default functions
(defun org-multi-wiki-escape-file-name-camelcase-1 (heading)
  "Escape HEADING suitable for use in file name."
  (cl-labels ((filename-escape
               (str)
               (s-replace-regexp (rx (not (any alnum "-._" nonascii))) "" str)))
    (-let* (((_ dir name) (s-match (rx bol
                                       (group (* (*? anything) "/"))
                                       (group (+ anything))
                                       eol)
                                   heading))
            (words (split-string name (rx (any space)))))
      (concat dir
              (if (= 1 (length words))
                  (filename-escape (car words))
                (->> words
                     (-filter #'org-multi-wiki--meaningful-word-p)
                     (-map #'filename-escape)
                     (-map #'upcase-initials)
                     (string-join)))))))

(defun org-multi-wiki--meaningful-word-p (word)
  "Check if WORD is a meaningful word.

This function returns nil if the word should be removed from a
file name."
  (not (cl-member word org-multi-wiki-filename-removed-words
                  :test #'string-equal)))

(defun org-multi-wiki-default-entry-template-fn (heading)
  "Generate an Org entry from HEADING."
  (concat "* " heading "\n"))

(defun org-multi-wiki-default-custom-id-escape-fn (heading)
  "Escape HEADING for a CUSTOM_ID property."
  (--> (split-string heading (rx (any "-_" space)))
       (-map (lambda (str)
               (s-replace-regexp (rx (not (any alnum))) "" str))
             it)
       (-map #'downcase it)
       (string-join it "-")))

;;;; Modes
;;;###autoload
(define-minor-mode org-multi-wiki-global-mode nil
  nil nil nil
  :global t
  :after-hook
  (cond
   (org-multi-wiki-global-mode
    (add-hook 'org-mode #'org-multi-wiki-check-buffer)
    (advice-add 'org-link-escape
                :filter-return #'org-multi-wiki-strip-namespace)
    ;; Run mode hooks when `org-show-entry' is called.
    ;; This is useful when an entry is visited by `helm-org-ql'.
    (advice-add 'org-show-entry :before #'org-multi-wiki-run-mode-hooks)
    (org-link-set-parameters "wiki" :follow #'org-multi-wiki-follow-link
                             :store #'org-multi-wiki-store-link
                             :complete #'org-multi-wiki-complete-link))
   (t
    (remove-hook 'org-mode #'org-multi-wiki-check-buffer)
    (advice-remove 'org-link-escape #'org-multi-wiki-strip-namespace)
    (advice-remove 'org-show-entry #'org-multi-wiki-run-mode-hooks)
    (cl-delete (assoc "wiki" org-link-parameters) org-link-parameters))))

(define-minor-mode org-multi-wiki-mode
  "Minor mode that should be activated in all wiki buffers."
  nil nil nil)

;;;; Configuration helpers
;;;###autoload
(cl-defun org-multi-wiki-add-namespaces (namespaces)
  "Add entries to `org-multi-wiki-namespace-list'.

This is a convenient function for adding an entry to the namespace list.

NAMESPACES should be a list of entries to add to the
variable. There won't be duplicate namespaces, and hooks for the
variable is run if necessary."
  (dolist (entry namespaces)
    (let ((cell (assoc (car entry) org-multi-wiki-namespace-list)))
      (funcall (or (get 'org-multi-wiki-namespace-list 'custom-set) #'set)
               'org-multi-wiki-namespace-list
               (if cell
                   (progn
                     (setcdr cell (cdr entry))
                     org-multi-wiki-namespace-list)
                 (append org-multi-wiki-namespace-list
                         (list entry)))))))

;;;; File and directory infrastructure
(defun org-multi-wiki-check-buffer ()
  "Check if the current buffer is an wiki entry."
  (when (ignore-errors
          (org-multi-wiki-entry-file-p))
    (org-multi-wiki-mode 1)))

(defun org-multi-wiki-directory (&optional namespace)
  "Get the root directory of NAMESPACE."
  (let ((namespace (or namespace org-multi-wiki-current-namespace)))
    (or (car-safe (alist-get namespace org-multi-wiki-namespace-list))
        (error "No entry exists for %s in org-multi-wiki-namespace-list"
               namespace))))

(defun org-multi-wiki-select-namespace (&optional prompt)
  "Select a wiki id using `completing-read', with an optional PROMPT."
  (intern (completing-read (or prompt (format "Wiki [current %s]: "
                                              org-multi-wiki-current-namespace))
                           (mapcar #'car org-multi-wiki-namespace-list)
                           nil t nil nil org-multi-wiki-current-namespace)))

;;;###autoload
(defun org-multi-wiki-entry-file-p (&optional file)
  "Check if FILE is a wiki entry.

If the file is a wiki entry, this functions returns a plist.

If FILE is omitted, the current buffer is assumed."
  (let* ((file (or file (buffer-file-name (or (org-base-buffer (current-buffer))
                                              (current-buffer)))))
         (directory (file-name-directory file))
         root-directory sans-extension namespace)
    (and (-any (lambda (extension)
                 (when (string-suffix-p extension file)
                   (setq sans-extension (string-remove-suffix extension file))))
               org-multi-wiki-file-extensions)
         (-any (lambda (entry)
                 (let ((dir (file-name-as-directory (nth 1 entry))))
                   (when (or (file-equal-p directory dir)
                             (string-prefix-p (expand-file-name dir)
                                              (expand-file-name directory)))
                     (setq root-directory dir
                           namespace (car entry)))))
               org-multi-wiki-namespace-list)
         (list :file file
               :namespace namespace
               :basename (file-relative-name (file-truename sans-extension)
                                             (file-truename root-directory))))))

;;;###autoload
(defsubst org-multi-wiki-recentf-file-p (filename)
  "Test if FILENAME matches the recentf exclude pattern.

This is not exactly the same as
`org-multi-wiki-entry-file-p'. This one tries to be faster by
using a precompiled regular expression, at the cost of accuracy."
  ;; The regular expression can be nil if the namespace list is empty
  (when org-multi-wiki-recentf-regexp
    (string-match-p org-multi-wiki-recentf-regexp filename)))

;;;###autoload
(defun org-multi-wiki-in-namespace-p (namespace &optional dir)
  "Check if a file/directory is in a particular namespace.

This checks if the directory is in/on a wiki NAMESPACE, which is
a symbol. If the directory is in/on the namespace, this function
returns non-nil.

By default, the directory is `default-directory', but you can
explicitly give it as DIR."
  (let* ((data (or (assoc namespace org-multi-wiki-namespace-list)
                   (error "Namespace %s is undefined" namespace)))
         (root (nth 1 data))
         (recursive (plist-get (-drop 2 data) :recursive))
         (dir (or (and dir (file-name-as-directory dir))
                  default-directory)))
    (if recursive
        (string-prefix-p (file-truename root) (file-truename dir))
      (file-equal-p dir root))))

(defun org-multi-wiki--current-namespace ()
  "Return the namespace of the current buffer."
  (plist-get (org-multi-wiki-entry-file-p) :namespace))

(defun org-multi-wiki--plist-get (prop &optional namespace)
  "Select PROP from the properties of NAMESPACE."
  (let* ((namespace (or namespace org-multi-wiki-current-namespace))
         (plist (cdr-safe (alist-get namespace org-multi-wiki-namespace-list))))
    (plist-get plist prop)))

;;;###autoload
(cl-defun org-multi-wiki-entry-files (&optional namespace &key as-buffers)
  "Get a list of Org files in a namespace.

If NAMESPACE is omitted, the current namespace is used, as in
`org-multi-wiki-directory'.

If AS-BUFFERS is non-nil, this function returns a list of buffers
instead of file names."
  (let* ((namespace (or namespace org-multi-wiki-current-namespace))
         (dir (org-multi-wiki-directory namespace))
         (recursive (org-multi-wiki--plist-get :recursive namespace))
         (files (if recursive
                    (org-multi-wiki--org-files-recursively dir)
                  (directory-files dir t org-multi-wiki-file-regexp))))
    (if as-buffers
        (->> files
             (-map (lambda (file)
                     (or (find-buffer-visiting file)
                         (org-multi-wiki--find-file-noselect :namespace namespace
                                                             :file file
                                                             :dir dir))))
             ;; If there is a file which failed to decrypt, it is nil.
             (delq nil))
      files)))

(cl-defun org-multi-wiki--find-file-noselect (&key file namespace dir)
  "Create a new buffer for an Org file.

FILE is an absolute file to the Org file, and NAMESPACE and DIR
contain the file."
  (let ((gpg-p (string-suffix-p ".gpg" file)))
    ;; If some files are GPG-encrypted and the
    ;; key is temporarily unavailble, the user
    ;; may want to read only unencrypted files.
    ;;
    ;; As a workaround, if there is an error
    ;; while reading a file ending with .gpg,
    ;; this function assumes that it is a
    ;; decryption issue and skips the following
    ;; decryption.
    (unless (and gpg-p
                 (or org-multi-wiki-gpg-skip-globally
                     (memq namespace org-multi-wiki-gpg-skip-namespace-list)
                     (member file org-multi-wiki-gpg-skip-file-list)))
      (condition-case nil
          (let* ((default-directory (file-name-directory file))
                 (buf (create-file-buffer file)))
            ;; Based on the implementation by @kungsgeten
            ;; for faster loading of many Org files.
            ;; https://github.com/alphapapa/org-ql/issues/88#issuecomment-570568341
            (with-current-buffer buf
              (insert-file-contents file)
              (setq buffer-file-name file)
              (when org-multi-wiki-rename-buffer
                (rename-buffer
                 (funcall org-multi-wiki-buffer-name-fn
                          :namespace namespace :file file :dir dir)
                 t))
              (set-buffer-modified-p nil)
              ;; Use delay-mode-hooks for faster loading.
              (delay-mode-hooks (set-auto-mode))
              (setq org-multi-wiki-mode-hooks-delayed t))
            buf)
        (error (progn
                 (when gpg-p
                   (pcase (read-char-choice
                           "Skip the following decryption on [f]ile, [n]amespace, [a]ll: "
                           (string-to-list "fna"))
                     (?f (push file org-multi-wiki-gpg-skip-file-list))
                     (?n (push namespace org-multi-wiki-gpg-skip-namespace-list))
                     (?a (setq org-multi-wiki-gpg-skip-globally t))))
                 nil))))))

(defun org-multi-wiki-run-mode-hooks ()
  "Run mode hooks delayed by org-multi-wiki."
  (when org-multi-wiki-mode-hooks-delayed
    (run-mode-hooks)
    (setq org-multi-wiki-mode-hooks-delayed nil)))

(cl-defun org-multi-wiki-buffer-name-1 (&key namespace file dir)
  "Return a buffer name suitable for Wiki.

NAMESPACE is the name space of the wiki, FILE is the file name,
and DIR is the root directory of the namespace."
  (format "%s:%s" namespace (file-relative-name file dir)))

(defun org-multi-wiki--org-files-recursively (dir)
  "Get a list of Org files in DIR recursively."
  (let ((default-directory dir))
    (mapcar (lambda (fpath) (expand-file-name fpath dir))
            (apply #'process-lines
                   org-multi-wiki-rg-executable
                   "-g" (format "*{%s}"
                                (string-join org-multi-wiki-file-extensions
                                             ","))
                   org-multi-wiki-rg-args))))

(defun org-multi-wiki-expand-org-file-names (directory basename)
  "Return a list of possible Org file names in DIRECTORY with BASENAME."
  (-map (lambda (extension)
          (expand-file-name (concat basename extension) directory))
        org-multi-wiki-file-extensions))

(cl-defun org-multi-wiki-link-file-name (file &key namespace dir)
  "Return a file name in an Org link.

FILE is an absolute file name to an Org file.

Either NAMESPACE or DIR to the wiki should be specified."
  (let ((dir (or dir (org-multi-wiki-directory namespace)))
        (extension (-find (lambda (extension)
                            (string-suffix-p extension file))
                          org-multi-wiki-file-extensions)))
    (unless extension
      (error "No matching extension in `org-multi-wiki-file-extensions'"))
    (->> (file-relative-name file dir)
         (string-remove-suffix extension))))

(defun org-multi-wiki--find-heading (heading dir)
  "Find a file of HEADING in DIR."
  (let* ((escaped-filenames (org-multi-wiki-expand-org-file-names
                             dir (funcall org-multi-wiki-escape-file-name-fn heading)))
         (filenames (append (org-multi-wiki-expand-org-file-names
                             dir heading)
                            escaped-filenames)))
    (or (cl-find-if #'file-exists-p filenames)
        (car escaped-filenames))))

(cl-defun org-multi-wiki--setup-new-buffer (buf namespace fpath dir)
  "Set up a buffer for a new wiki entry.

See `org-multi-wiki-visit-entry' for BUF, NAMESPACE, FPATH, and DIR."
  (when org-multi-wiki-rename-buffer
    (with-current-buffer buf
      (rename-buffer (funcall org-multi-wiki-buffer-name-fn
                              :namespace namespace :file fpath :dir dir)
                     t))))

;;;; Custom link type
;;;###autoload
(defun org-multi-wiki-follow-link (link)
  "Follow a wiki LINK."
  (when (string-match (rx bol (group-n 1 (* (any alnum "-")))
                          ":" (group-n 2 (+? anything))
                          (optional "::"
                                    (or (and "#" (group-n 3 (+ anything)))
                                        (and "*" (group-n 4 (+ anything)))))
                          eol)
                      link)
    (let* ((id (if (string-empty-p (match-string 1 link))
                   (save-match-data
                     (org-multi-wiki--current-namespace))
                 (intern (match-string 1 link))))
           (basename (match-string 2 link))
           (custom-id (match-string 3 link))
           (headline (match-string 4 link))
           (info (assoc id org-multi-wiki-namespace-list #'eq))
           (root (if info
                     (nth 1 info)
                   (user-error "Wiki directory for %s is undefined" id)))
           (file (or (cl-find-if #'file-exists-p
                                 (org-multi-wiki-expand-org-file-names root basename))
                     (cl-find-if #'file-exists-p
                                 (org-multi-wiki-expand-org-file-names
                                  root
                                  (funcall org-multi-wiki-escape-file-name-fn basename))))))
      (cond
       (file (find-file file))
       (t (let ((marker (and headline
                             (car-safe (org-ql-select (org-multi-wiki-entry-files id)
                                         `(and (level 1)
                                               (heading ,headline))
                                         :action '(point-marker))))))
            (if marker
                (org-goto-marker-or-bmk marker)
              (org-multi-wiki-visit-entry basename :namespace id)))))
      (let ((pos (or (and custom-id
                          (or (car-safe (org-ql-select (current-buffer)
                                          `(property "CUSTOM_ID" ,custom-id)
                                          :action '(point)))
                              (user-error "Cannot find an entry with CUSTOM_ID %s" custom-id)))
                     (and headline
                          (or (car-safe (org-ql-select (current-buffer)
                                          `(heading ,headline)
                                          :action '(point)))
                              (user-error "Cannot find an entry with heading %s" headline))))))
        (when pos (goto-char pos))))))

;;;###autoload
(defun org-multi-wiki-store-link ()
  "Store a link."
  (when-let* ((plist (org-multi-wiki--get-link-data nil))
              (link-brackets (org-link-make-string (plist-get plist :link)
                                                   (plist-get plist :headline))))
    (org-link-store-props :type "wiki"
                          ;; :file (plist-get plist :file)
                          ;; :node headline
                          :link (plist-get plist :link)
                          :description (plist-get plist :headline))
    link-brackets))

(cl-defun org-multi-wiki--make-link (ns basename
                                        &key
                                        origin-ns
                                        custom-id
                                        level
                                        headline
                                        to-file)
  "Create a Org link URI.

For NS, BASENAME, ORIGIN-NS, CUSTOM-ID, LEVEL, and HEADLINE
See `org-multi-wiki--get-link-data'

When TO-FILE, it generates a link to the file itself."
  (format "wiki:%s:%s%s"
          (if (not (and origin-ns
                        org-multi-wiki-allow-omit-namespace
                        (eq origin-ns ns)))
              (symbol-name ns)
            "")
          basename
          (or (and to-file
                   "")
              (and (not (org-multi-wiki--top-level-link-fragments ns))
                   (= level 1)
                   "")
              (and custom-id
                   (concat "::#" custom-id))
              (concat "::*" headline))))

(defun org-multi-wiki--get-link-data (&optional origin-ns)
  "Return data needed for generating a link.

ORIGIN-NS, if specified, is the namespace of the link orientation."
  (when (derived-mode-p 'org-mode)
    (when-let (plist (org-multi-wiki-entry-file-p))
      (when (org-before-first-heading-p)
        (user-error "You cannot store the link of a wiki entry before the first heading"))
      (-let* (((level _ _ _ headline _) (org-heading-components))
              (custom-id (or (org-entry-get nil "CUSTOM_ID")
                             (and org-multi-wiki-want-custom-id
                                  (or (org-multi-wiki--top-level-link-fragments (plist-get plist :namespace))
                                      (> level 1))
                                  (let* ((default (->> headline
                                                       (org-link-display-format)
                                                       (funcall org-multi-wiki-custom-id-escape-fn)))
                                         (custom-id (read-string
                                                     (format "CUSTOM_ID for the heading [%s]: "
                                                             default)
                                                     nil nil default)))
                                    (when custom-id
                                      (org-entry-put nil "CUSTOM_ID" custom-id)
                                      custom-id)))))
              (clean-headline (org-link-display-format headline)))
        (list :link (org-multi-wiki--make-link (plist-get plist :namespace)
                                               (plist-get plist :basename)
                                               :origin-ns origin-ns
                                               :custom-id custom-id
                                               :headline clean-headline
                                               :level level)
              :headline clean-headline)))))

(defun org-multi-wiki-strip-namespace (link)
  "Strip namespace from LINK if possible."
  (if (and (string-prefix-p "wiki:" link)
           org-multi-wiki-allow-omit-namespace
           (string-match (rx bol "wiki:"
                             (group (*? (not (any ":")))) ":"
                             (group (+ anything)) eol)
                         link)
           (eq (intern (match-string 1 link))
               (save-match-data
                 (plist-get (org-multi-wiki-entry-file-p) :namespace))))
      (concat "wiki::" (match-string 2 link))
    link))

(defun org-multi-wiki--strip-org-extension (filename)
  "Strip .org or .org.gpg from FILENAME."
  (save-match-data
    (if (string-match (rx (or ".org" ".org.gpg") eos) filename)
        (substring filename 0 (car (match-data)))
      filename)))

(defun org-multi-wiki-complete-link ()
  "Support for the Org link completion mechanism."
  (let* ((origin-ns (plist-get (org-multi-wiki-entry-file-p) :namespace))
         (namespace (intern (completing-read "Wiki: "
                                             (->> org-multi-wiki-namespace-list
                                                  (-map #'car)
                                                  (-map #'symbol-name))
                                             nil t nil nil origin-ns)))
         (files (org-multi-wiki-entry-files namespace))
         (alist (mapcar (lambda (file)
                          (cons (org-multi-wiki-link-file-name
                                 file :namespace namespace)
                                file))
                        files))
         (inp (completing-read "File or heading: "
                               (mapcar #'car alist)
                               nil nil
                               (when (region-active-p)
                                 (buffer-substring-no-properties
                                  (region-beginning) (region-end)))))
         (file (cdr-safe (assoc inp alist))))
    (if file
        (plist-get (with-current-buffer
                       (or (find-buffer-visiting file)
                           (find-file-noselect file))
                     (org-with-wide-buffer
                      (let* ((heading (completing-read "Heading: "
                                                       (org-multi-wiki--toplevel-headings-markers)
                                                       nil t))
                             (marker (get-char-property 0 'marker heading)))
                        (goto-char marker)
                        (org-multi-wiki--get-link-data origin-ns))))
                   :link)
      (org-multi-wiki--make-link namespace
                                 (org-multi-wiki--strip-org-extension inp)
                                 :origin-ns origin-ns
                                 :to-file t))))

(defun org-multi-wiki--toplevel-headings-markers ()
  "Return the top level headings with their markers."
  (let (headings)
    (goto-char (point-min))
    (while (re-search-forward (rx bol (+ "*") space) nil t)
      (push (propertize (string-trim-right (thing-at-point 'line t))
                        'marker (point-marker))
            headings))
    (nreverse headings)))

;;;; Other utility functions

(defun org-multi-wiki--trim-statistic-cookie (text)
  "Eliminate statistic cookie from a heading TEXT."
  (save-match-data
    (if (string-match (rx (+ space)
                          "[" (or (and (* (any digit)) "%")
                                  (and (+ (any digit)) "/"
                                       (+ (any digit))))
                          "]"
                          (* space) eol)
                      text)
        (substring text 0 (car (match-data)))
      text)))

(defun org-multi-wiki--cleanup-heading (text)
  "Clean up an Org heading TEXT to make it neutral."
  (->> text
       (org-multi-wiki--trim-statistic-cookie)
       (org-link-display-format)))

;;;; Commands

;;;###autoload
(defun org-multi-wiki-switch (namespace)
  "Set the current wiki to NAMESPACE."
  (interactive (list (org-multi-wiki-select-namespace)))
  (when-let (dir (org-multi-wiki-directory namespace))
    (setq org-multi-wiki-current-namespace namespace)
    (message "Set the current wiki to \"%s\" (%s)" namespace
             org-multi-wiki-current-namespace)))

;;;###autoload
(cl-defun org-multi-wiki-visit-entry (heading &key
                                              namespace
                                              filename)
  "Visit an entry of the heading.

HEADING in the root heading of an Org file to create or look
for. It looks for an existing entry in NAMESPACE or create a new
one if none. A file is determined based on
`org-multi-wiki-escape-file-name-fn', unless you explicitly
specify a FILENAME."
  (interactive (let ((namespace (or (and current-prefix-arg
                                         (org-multi-wiki-select-namespace))
                                    org-multi-wiki-current-namespace
                                    (user-error "No current namespace"))))
                 (list (completing-read (format "org-multi-wiki [namespace %s]: "
                                                namespace)
                                        (->> (org-multi-wiki-entry-files namespace)
                                             (-map (lambda (file)
                                                     (org-multi-wiki-link-file-name
                                                      file :namespace namespace)))))
                       :namespace namespace)))
  (let* ((dir (org-multi-wiki-directory namespace))
         (fpath (progn
                  (unless (and dir (file-directory-p dir))
                    (user-error "Wiki directory is nil or missing: %s" dir))
                  (if filename
                      (expand-file-name filename dir)
                    (org-multi-wiki--find-heading heading dir))))
         (new (not (file-exists-p fpath)))
         (existing-buffer (find-buffer-visiting fpath))
         ;; Set default-directory to allow directory-specific templates
         (default-directory dir)
         (buf (or existing-buffer
                  (when new
                    (let ((parent (file-name-directory fpath)))
                      (unless (file-directory-p parent)
                        (make-directory parent t)))
                    (with-current-buffer (create-file-buffer fpath)
                      (setq buffer-file-name fpath)
                      (insert (funcall org-multi-wiki-entry-template-fn heading))
                      (set-auto-mode)
                      (current-buffer)))
                  (find-file-noselect fpath))))
    (unless existing-buffer
      (org-multi-wiki--setup-new-buffer buf namespace fpath dir))
    (with-current-buffer buf
      (org-multi-wiki-run-mode-hooks))
    (funcall org-multi-wiki-display-buffer-fn buf)))

(defsubst org-multi-wiki--removal-blocked-p ()
  "Return non-nil if the user must not remove the subtree at point."
  (-any #'funcall org-multi-wiki-removal-block-functions))

;;;###autoload
(defun org-multi-wiki-create-entry-from-subtree (namespace)
  "Create a new entry from the current subtree.

This command creates a new entry in the selected NAMESPACE, from
an Org subtree outside of any wiki.

After successful operation, the original subtree is deleted from
the source file."
  (interactive (list (if (org-multi-wiki--removal-blocked-p)
                         (user-error "You cannot move this wiki entry/subtree")
                       (org-multi-wiki-select-namespace "Namespace: "))))
  (unless (derived-mode-p 'org-mode)
    (user-error "Must be run inside org-mode"))
  (when (org-multi-wiki--removal-blocked-p)
    (user-error "You cannot move this wiki entry/subtree"))
  (let* ((heading (org-multi-wiki--cleanup-heading
                   (org-get-heading t t t t)))
         ;; Let the user determine the file name.
         ;;
         ;; The user can edit the heading after the entry creation, so
         ;; only the file name matters at this point.
         (filename (read-string "Filename: "
                                (concat (substring-no-properties
                                         (funcall org-multi-wiki-escape-file-name-fn
                                                  heading))
                                        ".org")))
         ;; Append a suffix to the file name if it does not end with
         ;; .org or .gpg
         (filename (if (or (string-match-p (rx (or ".org" ".gpg") eol) filename))
                       filename
                     (concat filename ".org")))
         (directory (org-multi-wiki-directory namespace))
         (fpath (expand-file-name filename directory)))
    ;; Run some verification here
    (unless (and directory (file-directory-p directory))
      (user-error "Directory is nil or non-existent: %s" directory))
    (when (file-exists-p fpath)
      (error "File already exists: %s" fpath))
    (when (find-buffer-visiting fpath)
      (error "Buffer visiting the file already exists: %s" fpath))
    (let ((buf (find-file-noselect fpath)))
      (condition-case err
          (progn
            ;; TODO: Apply the template to the new file but don't create an entry in it
            (org-multi-wiki--setup-new-buffer buf namespace fpath directory)
            (org-refile nil nil (list heading fpath nil nil))
            (with-current-buffer buf
              (goto-char (point-min)))
            (funcall org-multi-wiki-display-buffer-fn buf))
        (error
         ;; Clean up the created buffer if it has zero length
         (when (zerop (buffer-size buf))
           (kill-buffer buf))
         (error err))))))

(provide 'org-multi-wiki)
;;; org-multi-wiki.el ends here
