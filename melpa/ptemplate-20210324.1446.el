;;; ptemplate.el --- Project templates -*- lexical-binding: t -*-

;; Copyright (C) 2020  Nikita Bloshchanevich

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;; Author: Nikita Bloshchanevich <nikblos@outlook.com>
;; URL: https://github.com/nbfalcon/ptemplate
;; Package-Version: 20210324.1446
;; Package-Commit: b81cc7be8865745c3a60177a244d2a69729ab21b
;; Package-Requires: ((emacs "25.1") (yasnippet "0.13.0"))
;; Version: 2.5.1

;;; Commentary:

;; Creating projects can be a lot of work. Cask files need to be set up, a
;; License file must be added, maybe build system files need to be created. A
;; lot of that can be automated, which is what ptemplate does. You can create a
;; set of templates categorized by type/template like in eclipse, and ptemplate
;; will then initialize the project for you. In the template you can have any
;; number of yasnippets or normal files.

;; Security note: yasnippets allow arbitrary code execution, as do
;; .ptemplate.el files. DO NOT EXPAND UNTRUSTED TEMPLATES. ptemplate DOES NOT
;; make ANY special effort to protect against malicious templates.

;;; Code:

(require 'cl-lib)
(require 'subr-x)                       ; `string-join'

;;; global `declare-function'

(declare-function yas-minor-mode "yasnippet" (&optional arg))
(declare-function yas-expand-snippet "yasnippet" (s &optional start end env))

;;; common utilities (also for the snippet chain)

(defmacro ptemplate--appendlf (newels place)
  "Add list NEWELS to the end of list PLACE."
  (declare (debug (form gv-place)))
  `(cl-callf nconc ,place ,newels))

(defmacro ptemplate--appendf (newelt place)
  "Add NEWELT to the end of list PLACE."
  (declare (debug (form gv-place)))
  `(ptemplate--appendlf (list ,newelt) ,place))

;;; snippet-chain subsystem

(cl-defstruct (ptemplate--snippet-chain-mapping
               (:constructor ptemplate--snippet-chain-mapping<-new)
               (:copier ptemplate--snippet-chain<-copy))
  "Maps a SRC to snippet expansion TARGET."
  (snippet
   nil :documentation
   "The content of the snippet, as a string.")
  (target
   nil :documentation
   "Where SRC is expanded to.")
  (setup-hook
   nil :documentation
   "Run before inserting each snippet.
Each function therein is called without arguments."))

(cl-defstruct (ptemplate--snippet-chain
               (:constructor ptemplate--snippet-chain<-new)
               (:copier ptemplate--snippet-chain<-copy))
  "Holds all state needed for executing a snippet chain.
An instance of this, `ptemplate--snippet-chain-context', is
passed trough each buffer so that they can all share some state."
  (snippets
   nil :documentation
   "List of `ptemplate--snippet-chain-mapping'.
Template directories can have any number of yasnippet files.
These need to be filled in by the user. To do this, there is a
snippet chain: a list of snippets and their target files or
buffers. During expansion of a template directory, first all
snippets are gathered into a list, the first snippet of which is
then shown to the user. If the user presses
\\<ptemplate-snippet-chain-mode-map>
\\[ptemplate-snippet-chain-next], the next item in the snippet
chain is displayed. Buffers are appended to this list when the
user presses \\<ptemplate-snippet-chain-mode-map>
\\[ptemplate-snippet-chain-later].

See also `ptemplate--snippet-chain->start'.")
  (env
   nil :documentation
   "List of variables to set in snippet-chain buffers.
Alist of (SYMBOL . VALUE).

All variables will be made buffer-local before being set in each
snippet-chain buffer. `ptemplate--snippet-chain-context' shouldn't be
included.")
  (finalize-hook
   nil :documentation
   "Hook to run after the snippet chain finishes.
Each function therein gets called without arguments.

This hook needs to be a separate variable and cannot be
implemented by simply appending it to the SNIPPETS field, because
in that case it would get run too early if
`ptemplate--snippet-chain-later' were called at least once, as
then it wouldn't be the last element anymore.")
  (newbuf-hook
   nil :documentation
   "Hook run after each snippet-chain buffer is created.
Can be used to configure `ptemplate--snippet-chain-nokill'. Each
function therein is called with no arguments."))

(defvar-local ptemplate--snippet-chain-nokill nil
  "If set in a snippet-chain buffer, don't kill it.
Normally, `ptemplate--snippet-chain->continue' kills the buffer
when moving on. If this variable is set, don't do that. Useful
when one wants to keep the cursor when reopening a snippet chain
file.")

(defvar-local ptemplate--snippet-chain-next-hook nil
  "Run at the very start of `ptemplate-snippet-chain-next'.
Can be used to modify the buffer before it is saved, add a
`kill-buffer-hook', ....")

(defvar ptemplate--snippet-chain-context nil
  "The instance of `ptemplate--snippet-chain'.
facilitate parallel template expansion. All snippet-chain This
variable is always either `let' bound or buffer-local, to
functions operate on this variable, as defined in their calling
environment.")

(defun ptemplate--read-file (file)
  "Read FILE and return its contents a string."
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(define-minor-mode ptemplate-snippet-chain-mode
  "Minor mode for template directory snippets.
This mode is only for keybindings."
  :init-value nil
  :lighter nil
  :keymap (let ((map (make-sparse-keymap)))
            (define-key map (kbd "C-c C-c") #'ptemplate-snippet-chain-next)
            (define-key map (kbd "C-c C-l") #'ptemplate-snippet-chain-later)
            map))

(defun ptemplate--setup-snippet-env (snippet-env)
  "Set all (SYMBOL . VALUE) pairs in SNIPPET-ENV.
Variables are set buffer-locally."
  (let ((symbols (mapcar #'car snippet-env))
        (values (mapcar #'cdr snippet-env)))
    (mapc #'make-local-variable symbols)
    (cl-mapcar #'set symbols values)))

(defun ptemplate--snippet-chain->continue ()
  "Make the next snippet/buffer in the snippet chain current."
  (let* ((context ptemplate--snippet-chain-context)
         (realchain (ptemplate--snippet-chain-snippets context))
         (next (car realchain)))
    (when realchain
      ;; If the snippet chain is empty, pop fails.
      (pop (ptemplate--snippet-chain-snippets context)))

    (cond
     ((null next)
      (mapc #'funcall (ptemplate--snippet-chain-finalize-hook context)))
     ((bufferp next) (switch-to-buffer next))
     ((ptemplate--snippet-chain-mapping-p next)
      (let ((target (ptemplate--snippet-chain-mapping-target next))
            (snippet (ptemplate--snippet-chain-mapping-snippet next))
            (setup-hook (ptemplate--snippet-chain-mapping-setup-hook next)))
        (require 'yasnippet)
        (with-current-buffer (find-file-noselect target)
          (make-local-variable 'ptemplate--snippet-chain-context)

          (ptemplate--setup-snippet-env (ptemplate--snippet-chain-env context))
          ;; let the user configure the buffer, with the snippet-env already
          ;; bound.
          (mapc #'funcall (ptemplate--snippet-chain-newbuf-hook context))
          (mapc #'funcall setup-hook)

          ;; "yasnippet needs a properly set-up `yas-minor-mode'"
          (yas-minor-mode 1)
          (yas-expand-snippet snippet nil nil)

          (ptemplate-snippet-chain-mode 1)
          (pop-to-buffer-same-window (current-buffer))))))))

(defun ptemplate-snippet-chain-next ()
  "Save the current buffer and continue in the snippet chain.
The buffer is killed after calling this. If the snippet chain is
empty, do nothing."
  (interactive)
  (run-hooks 'ptemplate--snippet-chain-next-hook)
  (save-buffer 0)
  (let ((context ptemplate--snippet-chain-context))
    (if ptemplate--snippet-chain-nokill
        (ptemplate-snippet-chain-mode -1)
      (kill-buffer))
    ;; the `let' needs to be here, as otherwise it would override the
    ;; buffer-local binding
    (let ((ptemplate--snippet-chain-context context))
      (ptemplate--snippet-chain->continue))))

(defun ptemplate-snippet-chain-later ()
  "Save the current buffer to be expanded later.
Use this if you are not sure yet what expansions to use in the
current snippet and want to decide later, after looking at
others."
  (interactive)
  (unless ptemplate--snippet-chain-context
    (user-error "No more snippets to expand"))
  (ptemplate--appendf
   (ptemplate--snippet-chain-snippets ptemplate--snippet-chain-context)
   (current-buffer))
  (ptemplate--snippet-chain->continue))

(defun ptemplate--snippet-chain->start
    (snippets &optional env finalize-hook newbuf-hook)
  "Start a snippet chain with SNIPPETS.
For details, see `ptemplate--snippet-chain-context'.

ENV (alist of (SYMBOL . VALUE)) specifies the variables to set in
each new buffer.

FINALIZE-HOOK is run when the snippet chain finishes. Corresponds
to `ptemplate--snippet-chain-finalize-hook'.

NEWBUF-HOOK is run each time a new snippet chain buffer is
created. Corresponds to `ptemplate--snippet-chain-newbuf-hook'"
  (let ((ptemplate--snippet-chain-context
         (ptemplate--snippet-chain<-new
          :snippets snippets :env env :finalize-hook finalize-hook
          :newbuf-hook newbuf-hook)))
    (ptemplate--snippet-chain->continue)))

;;; common utility functions

(defun ptemplate--maybe-dirify (path)
  "Make PATH a directory path if it is one.
If path is a directory (as determined by `file-directory-p'), run
it trough `file-name-as-directory', otherwise yield PATH as-is."
  (if (file-directory-p path) (file-name-as-directory path) path))

(defun ptemplate--dir-find-relative (path)
  "List all files in PATH recursively.
The list is a string of paths beginning with ./ (or the
platform's equivalent) of all files and directories within it.
Unlike `directory-files-recursively', directories end in the
platform's directory separator. \".\" and \"..\" are not
included."
  (cl-loop for file in (directory-files-recursively path "" t) collect
           (concat "./" (file-relative-name
                         (ptemplate--maybe-dirify file) path))))

(defun ptemplate--list-template-dir-files (path)
  "`ptemplate--list-template-files', but include .ptemplate.el.
PATH specifies the path to examine."
  (mapcar #'ptemplate--file-mapping<-auto
          (cl-delete-if (apply-partially #'string-suffix-p ".nocopy")
                        (ptemplate--dir-find-relative path))))

(defun ptemplate--list-template-dir-files-abs (path)
  "Like `ptemplate--list-template-dir-files'.
The difference is that this version yields an absolute mapping
instead (see `ptemplate--file-map->absoluteify').

PATH specifies that path to the template."
  (ptemplate--file-map->absoluteify
   path (ptemplate--list-template-dir-files path)))

(defun ptemplate--list-template-files (path)
  "Find all files in ptemplate PATH.
The result is a list file-map, as in `ptemplate--file-map'.

Associates each file with its target, removing the extension of
special files (e.g. .nocopy, .yas). Directories are included.
.ptemplate.el and .ptemplate.elc are removed."
  (cl-delete-if
   (lambda (mapping)
     (member (ptemplate--file-mapping-src mapping)
             '("./.ptemplate.el" "./.ptemplate.elc")))
   (ptemplate--list-template-dir-files path)))

(defun ptemplate--list-dir (dir)
  "List DIR, including directories.
A list of the full paths of each file in it is returned. The
special directories \".\" and \"..\" are ignored."
  (cl-delete-if (lambda (f) (or (string= (file-name-base f) ".")
                           (string= (file-name-base f) "..")))
                (directory-files dir t)))

(defmacro ptemplate--prependlf (newels place)
  "Prepend list NEWELS to PLACE.
There is no single-element version of this, because `cl-push'
does that already."
  (declare (debug (form gv-place)))
  `(cl-callf2 nconc ,newels ,place))

;;; copy context

(cl-defstruct (ptemplate--file-mapping
               (:constructor ptemplate--file-mapping<-new)
               (:copier ptemplate--file-mapping<-copy))
  "Holds a file mapping, as can be found in file-maps.
The underlying data-structure of
`ptemplate--copy-context-file-map'."
  (prefix
   nil :documentation
   "Prepended to SRC to yield the actual location.")
  (src
   nil :documentation
   "See PREFIX.
This may be nil, in which case the mapping is to be ignored.")
  (target
   nil :documentation
   "Where the SRC is mapped to.
Relative to the expansion target.")
  (type
   'copy :documentation
   "How this mapping is to be executed.
Possible values are:
- `:copy': copy the content to the target
- `:yas': expand the content using the snippet-chain
- `:autoyas': expand a snippet in the background
- `:nil': ignore this mapping
- `:mkdir': create directory TARGET")
  (content
   nil :documentation
   "An optional string that should be the source content.
If this is specified, SRC is not be read and this string is used
as the buffer content for `:copy', `:yas', .... Useful if mapping
content needs to be computed dynamically. SRC will still
participate in selection (`ptemplate-ignore', ...) though.")
  (snippet-setup-hook
   nil :documentation
   "List of functions run to set up this snippet.
Only makes sense in snippet-chain files. See
`ptemplate-snippet-setup'."))

(defun ptemplate--file-mapping->snippet-p (mapping)
  "Check if MAPPING's type corresponds to a snippet.
These are defined as being expanded using `yasnippet'."
  (memq (ptemplate--file-mapping-type mapping) '(:yas :autoyas)))

(defun ptemplate--file-map->absoluteify (path file-map)
  "Make each relative mapping in FILE-MAP refer to PATH.
A relative mapping is one whose PREFIX is nil. For each of them,
set the PREFIX to PATH, modifying FILE-MAP. Return the result."
  (dolist (mapping file-map)
    (setf (ptemplate--file-mapping-prefix mapping)
          (or (ptemplate--file-mapping-prefix mapping) path)))
  file-map)

(defun ptemplate--auto-map-file (file)
  "Associate FILE to a target file name.
File specifies the template-relative path to a file in a
template."
  (if (member (file-name-extension file) '("keep" "yas" "autoyas"))
      (file-name-sans-extension file)
    file))

(defun ptemplate--mapping-auto-type (src)
  "Deduce the type of the mapping from SRC.
See `ptemplate--file-mapping-type' for details."
  (if src
      (pcase (file-name-extension src)
        ("yas" :yas)
        ("autoyas" :autoyas)
        ;; `:nil' is never an implicit mapping, because then that mapping might
        ;; as well be ommitted in the first place.
        (_ :copy))
    ;; nil maps
    :copy))

(defun ptemplate--file-mapping<-auto (file)
  "Map FILE using `ptemplate--auto-map-file'.
Return a `ptemplate--file-mapping'."
  (ptemplate--file-mapping<-new
   :src file :target (ptemplate--auto-map-file file)
   :type (ptemplate--mapping-auto-type file)))

(cl-defstruct (ptemplate--copy-context
               (:constructor ptemplate--copy-context<-new)
               (:copier ptemplate--copy-context<-copy))
  "Holds data needed by ptemplate's copy phase.
To acquire this state, a template's file need to be listed and
the .ptemplate.el needs to be evaluated against it.
`ptemplate--copy-context->execute'. A `let'-bound, global
instance of this that is used by the .ptemplate.el API is in
`ptemplate--cur-copy-context'."
  (file-map
   nil :documentation
   "List of `ptemplate--file-mapping.'")
  (snippet-env
   nil :documentation
   "Environment used for snippet expansion.
Alist of (SYMBOL . VALUE), like `ptemplate--snippet-chain-env'
but for the entire template.")
  (snippet-conf-hook
   nil :documentation
   "Hook run when creating snippet-chain buffers.
Corresponds to `ptemplate--snippet-chain-newbuf-hook'.")
  (before-snippets
   nil :documentation
   "Hook run before expanding yasnippets.
Each function therein shall take no arguments.

These variables are hooks to allow multiple ptemplate! blocks
that specify :before-yas, :after, ....")
  (finalize-hook
   nil :documentation
   "Hook to run after template expansion finishes.
At this point, no more files need to be copied and no more
snippets need be expanded.

See also `ptemplate--before-expand-hooks'."))

(defun ptemplate--copy-context<-merge-hooks (contexts)
  "Merge all hook-fields of CONTEXTS.
CONTEXTS is a list of `ptemplate--copy-context's. The fields that
are not FILE-MAP of each CONTEXT are concatenated using `nconc',
and the result, also a `ptemplate--copy-context', returned."
  (ptemplate--copy-context<-new
   :snippet-env (mapcan #'ptemplate--copy-context-snippet-env contexts)
   :snippet-conf-hook
   (mapcan #'ptemplate--copy-context-snippet-conf-hook contexts)
   :before-snippets (mapcan #'ptemplate--copy-context-before-snippets contexts)
   :finalize-hook (mapcan #'ptemplate--copy-context-finalize-hook contexts)))

(defvar ptemplate--cur-copy-context nil
  "Current instance of the `ptemplate--copy-context'.
This variable is `let'-bound when evaluating a template and
modified by the helper functions defined in the \".ptemplate.el
API\" section.")

(defvar ptemplate-target-directory nil
  "Target directory of ptemplate expansion.
You can use this in templates. This variable always ends in the
platform-specific directory separator, so you can use this with
`concat' to build file paths.")

(defvar ptemplate-source-directory nil
  "Source directory of ptemplate expansion.")

(defun ptemplate--eval-template (source &optional target)
  "Evaluate the template given by SOURCE.
Gather all of its files, execute the .ptemplate.el file in it and
return a `ptemplate--copy-context' for it. TARGET specifies where
the template should be expanded to and may be left out for
templates that don't make use of `ptemplate-target-directory' in
:init. Both SOURCE and TARGET are directories, with an optional
trailing slash."
  (setq source (file-name-as-directory source))
  (when target (setq target (file-name-as-directory target)))
  (let ((ptemplate-source-directory source)
        (ptemplate-target-directory target)
        (ptemplate--cur-copy-context
         (ptemplate--copy-context<-new
          :file-map (ptemplate--list-template-files source)))
        (dotptemplate (concat source ".ptemplate.el")))
    (when (file-exists-p dotptemplate)
;;; load .ptemplate.el
      ;; NOTE: arbitrary code execution
      (load-file dotptemplate))
    ptemplate--cur-copy-context))

(defun ptemplate--check-duplicate-mappings (mappings)
  "Check for and duplicates in MAPPINGS.
MAPPINGS shall be a list of template file mappings (see
`ptemplate--copy-context-file-map').

If a duplicate is encountered, an `error' is thrown."
  ;; hashmap of all target files mapped to `t'
  (let ((known-targets (make-hash-table :test 'equal)))
    (dolist (mapping mappings)
      (let* ((target (ptemplate--file-mapping-target mapping))
             (prev-source (gethash target known-targets)))
        (when prev-source
          (error "Duplicate mapping encountered: %S came before %S"
                 prev-source mapping))
        (puthash target mapping known-targets)))))

(defun ptemplate--autoyas-expand
    (content target &optional expand-env snippet-setup-hook)
  "Expand yasnippet string CONTENT to file TARGET.
Expansion is done \"headlessly\", that is without showing
buffers. EXPAND-ENV is an environment alist like in
`ptemplate--snippet-chain-env'. Execute each function in
SNIPPET-SETUP-HOOK before expanding the snippet."
  (with-temp-file target
    (require 'yasnippet)

    (ptemplate--setup-snippet-env expand-env)
    (mapc #'funcall snippet-setup-hook)

    (yas-minor-mode 1)
    (yas-expand-snippet content)))

(defun ptemplate--write-file (s file)
  "Write string S to FILE.
Throw an error if FILE already exists."
  (write-region s nil file nil nil nil t))

(defun ptemplate--copy-context->execute (context source target)
  "Copy all files in CONTEXT's file-map.
SOURCE specifies the template's source directory and TARGET the
target directory, which are needed since all paths in CONTEXT are
relative and not stored in it. Note that executing this with a
different SOURCE and TARGET might lead to issues if the template
manually copies files around in its .ptemplate.el :init block.
\(`ptemplate-copy-target' is okay in :finalize\)."
  ;; EDGE CASE: empty templates should yield a directory
  (make-directory target t)

  (setq source (file-name-as-directory source)
        target (file-name-as-directory target))
  (cl-loop with snippet-env = `((ptemplate-source-directory . ,source)
                                (ptemplate-target-directory . ,target)
                                ,@(ptemplate--copy-context-snippet-env context))
           with yasnippets = nil

           with mappings = (ptemplate--copy-context-file-map context)
           initially (ptemplate--check-duplicate-mappings mappings)
           for mapping in mappings

           for src = (ptemplate--file-mapping-src mapping)
           for targetf = (ptemplate--file-mapping-target mapping)

           for realsrc =
           (and src
                (concat (or (ptemplate--file-mapping-prefix mapping) source)
                        src))
           ;; all directories from `ptemplate--list-template-files' end in '/'
           for src-dir? = (and src (directory-name-p realsrc))
           for realtarget = (concat target targetf)

           for snippet-setup-hook =
           (ptemplate--file-mapping-snippet-setup-hook mapping)

           for type = (ptemplate--file-mapping-type mapping)

           for content = (ptemplate--file-mapping-content mapping)

           if (eq type :mkdir) do (make-directory target t)
           else if (or src content) do
           (make-directory
            ;; directories need to be created "as-is" (they may potentially
            ;; be empty); files must not be created as directories however
            ;; but their containing directories instead. This avoids prompts
            ;; asking the user if they really want to save a file even
            ;; though its containing directory was not made yet.
            (if src-dir? realtarget (file-name-directory realtarget)) t)
           and unless src-dir? do
           (pcase type
             (:copy
              (if content (ptemplate--write-file content realtarget)
                (copy-file realsrc realtarget)))
             (:autoyas (ptemplate--autoyas-expand
                        (or content (ptemplate--read-file realsrc))
                        realtarget snippet-env snippet-setup-hook))
             (:yas (push (ptemplate--snippet-chain-mapping<-new
                          :snippet (or content (ptemplate--read-file realsrc))
                          :target realtarget :setup-hook snippet-setup-hook)
                         yasnippets))
             (:nil)                     ; explicitly ignored
             (_ (error "Unknown type %S in mapping %S" type mapping)))

           finally do
           (run-hooks 'ptemplate--before-snippet-hook)
           (ptemplate--snippet-chain->start
            (nreverse yasnippets) snippet-env
            (ptemplate--copy-context-finalize-hook context)
            (ptemplate--copy-context-snippet-conf-hook context))))

;;; Public API

(defun ptemplate--list-dir-dirs (dir)
  "Like `ptemplate-list-dir', but only include directories.
DIR specifies the path to the directory to list."
  (cl-delete-if-not #'file-directory-p (ptemplate--list-dir dir)))

(defun ptemplate-list-template-dir (dir)
  "List all templates in directory DIR.
The result is of the form (TYPE ((NAME . PATH)...))...."
  (let* ((type-dirs (ptemplate--list-dir-dirs dir))
         (types (mapcar #'file-name-base type-dirs))
         (name-dirs (cl-loop for tdir in type-dirs collect
                             (ptemplate--list-dir-dirs tdir)))
         (name-dir-pairs (cl-loop for name-dir in name-dirs collect
                                  (cl-loop for dir in name-dir collect
                                           (cons (file-name-base dir) dir)))))
    (cl-mapcar #'cons types name-dir-pairs)))

(defun ptemplate-list-templates (template-dirs)
  "List all templates in TEMPLATE-DIRS.
The result is an alist ((TYPE (NAME . PATH)...)...)."
  (mapcan #'ptemplate-list-template-dir template-dirs))

(defcustom ptemplate-project-template-dirs '()
  "List of directories containing project templates.
Each directory therein shall be a directory of directories, the
latter specifying the types of templates and the former the names
of the templates.

The templates defined by this list are used in
`ptemplate-new-project', when called interactively. Analogous to
the variable `yas-snippet-dirs'."
  :group 'ptemplate
  :type '(repeat string))

(defun ptemplate-list-project-templates ()
  "List all templates in `ptemplate-project-template-dirs'."
  (ptemplate-list-templates ptemplate-project-template-dirs))

(defcustom ptemplate-directory-template-dirs '()
  "List of directories containing directory templates.
Like `ptemplate-project-template-dirs', but for
`ptemplate-expand-template'."
  :group 'ptemplate
  :type '(repeat string))

(defun ptemplate-list-directory-templates ()
  "List all templates in `ptemplate-project-template-dirs'."
  (ptemplate-list-templates ptemplate-directory-template-dirs))

(defun ptemplate--list-templates-helm (templates)
  "Make a list of helm sources from the user's templates.
TEMPLATES specifies the list of templates for the user to select
from, and is as returned by `ptemplate-list-templates'.

Convert each (TYPE . TEMPLATES) pair into a helm source with TYPE
as its header.

Helm (in particular, helm-source.el) must already be loaded when
this function is called."
  (declare-function helm-make-source "helm" (name class &rest args))
  (cl-loop for (type . templates) in templates collect
           (helm-make-source type 'helm-source-sync :candidates templates)))

(defun ptemplate-prompt-template-helm (templates)
  "Prompt for a template using `helm'.
TEMPLATES is as returned by `ptemplate-list-templates'. The
prompt is a `helm' prompt where all templates are categorized
under their types (as `helm' sources). The return value is the
path to the template, as a string.

This function's API is not stable, and it is only for use in
`ptemplate-template-prompt-function'."
  (require 'helm)
  (declare-function helm "helm")
  (helm :sources (ptemplate--list-templates-helm templates)
        :buffer "*helm ptemplate*"))

(defface ptemplate-type-face '((t :inherit font-lock-function-name-face))
  "Face used to show template types in for the :completing-read backend.
When :completing-read is used as backend in
`ptemplate-template-prompt-function', all entries have a (TYPE)
STRING appended to it. That TYPE is propertized with this face."
  :group 'ptemplate-faces)

(defun ptemplate--list-templates-completing-read (templates)
  "`ptemplate--list-templates-helm', but for `completing-read'.
Returns an alist mapping (propertized) strings, of the form
\"<name> <type>\", to template paths. TEMPLATES is a list of
templates, as returned by `ptemplate-list-templates'."
  (cl-loop for (type . templates) in templates nconc
           (let ((category (propertize (format "(%s)" type)
                                       'face 'ptemplate-type-face)))
             (cl-loop for (name . path) in templates collect
                      (cons (concat name " " category) path)))))

(defvar ptemplate-completing-read-history nil
  "History variable for `completing-read'-based template prompts.
Used by `ptemplate-prompt-template-completing-read' to remember
the history.")

(defun ptemplate-prompt-template-completing-read (templates)
  "Prompt for a template using `completing-read'.
The prompt is a list of \"NAME (TYPE)\" and uses
`completing-read', so can be used with anything that isn't helm.

TEMPLATES is as returned by `ptemplate-list-templates'.

This function's API is not stable, and it for use only as a
`ptemplate-template-prompt-function'."
  (let ((ptemplates (ptemplate--list-templates-completing-read templates)))
    (cdr (assoc (completing-read "Select template: " ptemplates
                                 nil t nil 'ptemplate-completing-read-history)
                ptemplates #'string=))))

(defcustom ptemplate-template-prompt-function
  #'ptemplate-prompt-template-completing-read
  "Prompting method to use to read a template from the user.
The function shall take a single argument, the list of templates
\(as returned by `ptemplates-list-templates'\) and shall return
the path to the template as a string. If the user fails to select
a template, the function may return nil."
  :group 'ptemplate
  :type '(radio
          (const :tag "completing-read (ivy, helm, ...)"
                 ptemplate-prompt-template-completing-read)
          (const :tag "helm" ptemplate-prompt-template-helm)
          (function :tag "Custom function")))

(defcustom ptemplate-workspace-alist '()
  "Alist mapping between template types and workspace folders.
The associated workspaces have form of
`ptemplate-default-workspace', which see."
  :group 'ptemplate
  :type '(alist :key-type (string :tag "Type")
                :value-type (choice (file :tag "Workspace")
                                    (file :tag "Workspaces"))))

(defcustom ptemplate-default-workspace nil
  "Default workspace for `ptemplate-workspace-alist'.
If looking up a template's type in `ptemplate-workspace-alist'
fails, because there is no corresponding entry, use this as a
workspace instead.

This variable may either be a string, specifying the path to the
workspace, or a list of strings. If it is of the latter form, a
prompt will be displayed asking a workspace to be selected before
prompting for a target in `ptemplate-new-project'."
  :group 'ptemplate
  :type '(choice (file :tag "Workspace")
                 (file :tag "Workspaces")))

(defun ptemplate--read-target (template)
  "Prompt the user to supply a project directory for TEMPLATE.
The DIR for `read-file-name' is looked up based on
`ptemplate-workspace-alist'. TEMPLATE's type is deduced from its
path, which means that it should have been obtained using
`ptemplate-list-templates', or at least be in a template
directory."
  (let* ((base (directory-file-name template))
         (type (file-name-nondirectory (directory-file-name
                                        (file-name-directory base))))
         (workspaces (alist-get type ptemplate-workspace-alist
                                ptemplate-default-workspace nil #'string=))
         (workspace (if (listp workspaces)
                        (completing-read "Select workspace: " workspaces nil t)
                      workspaces)))
    (read-file-name "Create project: " workspace workspace)))

(defun ptemplate--read-template (templates caller)
  "Prompt the user for a template.
Prompt with `ptemplate-template-prompt-function' and pass
TEMPLATES to it.

If the user fails to specify an error, throw a `user-error', as
if from CALLER (a symbol), telling the user to select a
template."
  (or (funcall ptemplate-template-prompt-function templates)
      (user-error "`%s': please select a template" caller)))

(defcustom ptemplate-post-expand-hook '()
  "Hook run after expanding a template finishes.
All snippet variables are still bound when this is executed, and
you can acquire the expansion source and target using
`ptemplate-source-directory' and `ptemplate-target-directory'.
The functions therein are called without arguments."
  :group 'ptemplate
  :type 'hook)

;;;###autoload
(defun ptemplate-expand-template (source target)
  "Expand the template in SOURCE to TARGET.
If called interactively, SOURCE is prompted using
`ptemplate-template-prompt-function' and TARGET using
`read-file-name'"
  (interactive
   (list
    (ptemplate--read-template
     (ptemplate-list-directory-templates) #'ptemplate-expand-template)
    (read-file-name "Expand to: ")))
  (let ((context (ptemplate--eval-template source target)))
    ;; ensure `ptemplate-post-expand-hook' is run
    (ptemplate--appendlf ptemplate-post-expand-hook
                         (ptemplate--copy-context-finalize-hook context))
    (ptemplate--copy-context->execute context source target)))

;;;###autoload
(defun ptemplate-new-project (source target)
  "Create a new project based on a template.
Like `ptemplate-expand-template', but ensure that TARGET doesn't
exist and prompt for TARGET differently. SOURCE and TARGET are
passed to `ptemplate-expand-template' unmodified. If called
interactively, TARGET is prompted using `read-file-name', with
the initial directory looked up in `ptemplate-workspace-alist'
using SOURCE's type, defaulting to `ptemplate-default-workspace'.
If even that is nil, use `default-directory'."
  (interactive (let ((template (ptemplate--read-template
                                (ptemplate-list-project-templates)
                                #'ptemplate-new-project)))
                 (list template (ptemplate--read-target template))))
  (when (file-exists-p target)
    (user-error "Directory %s already exists" target))
  (ptemplate-expand-template source target))

;;; auxiliary functions for the .ptemplate.el API

(defun ptemplate--make-basename-regex (file)
  "Return a regex matching FILE as a basename.
FILE shall be a regular expressions matching a path, separated
using slashes, which will be converted to the platform-specific
directory separator. The returned regex will match if FILE
matches at the start of some string or if FILE matches after a
platform-specific directory separator. The returned regexes can
be used to remove files with certain filenames from directory
listings.

Note that . or .. path components are not handled at all, meaning
that \"(string-match-p (ptemplate--make-basename-regex
\"tmp/foo\") \"tmp/foo/../foo\"\)\" will yield nil."
  (declare (side-effect-free t) (pure t))
  (concat (format "\\(?:/\\|\\`\\)%s\\'" file)))

(defun ptemplate--make-path-regex (path)
  "Make a regex matching PATH if some PATH is below it.
The resulting regex shall match if some other path starts with
PATH. Slashes should be used to separate directories in PATH, the
necessary conversion being done for windows and MS DOS. The same
caveats apply as for `ptemplate--make-basename-regex'."
  (declare (side-effect-free t) (pure t))
  (format "\\`%s\\(?:/\\|\\'\\)" path))

(defun ptemplate--simplify-user-path (path)
  "Make PATH a template-relative path without any prefix.
PATH's slashes are converted to the native directory separator
and prefixes like ./ and / are removed. Note that directory
separator conversion is not performed."
  (declare (side-effect-free t) (pure t))
  (let* ((paths (split-string path "/"))
         (paths (cl-delete-if #'string-empty-p paths))
         (paths (cl-delete "." paths :test #'string=)))
    (string-join paths "/")))

(defun ptemplate--normalize-user-path (path)
  "Make PATH usable to query template files.
PATH shall be a user-supplied template source/target relative
PATH, which will be normalized and whose directory separators
will be converted to the platform's native ones."
  (declare (side-effect-free t) (pure t))
  (concat "./" (ptemplate--simplify-user-path path)))

(defun ptemplate--normalize-user-path-file (path)
  "Like `ptemplate--normalize-user-path', but yield a file.
If PATH is equivalent the empty string,
`ptemplate--normalize-user-path' yields \"./\". This isn't always
desirable, so this function handles that edge case by returning
\".\" instead."
  ;; EDGE CASE: the inner s-exp may yield "./".
  (directory-file-name (ptemplate--normalize-user-path path)))

(defun ptemplate--normalize-user-path-dir (path)
  "`ptemplate--normalize-user-path', but yield a directory.
PATH is transformed according to it and the result made a
directory path."
  (file-name-as-directory (ptemplate--normalize-user-path path)))

(defun ptemplate--make-ignore-regex (regexes)
  "Make a delete regex for `ptemplate-ignore'.
REGEXES is a list of strings as described there."
  (declare (side-effect-free t) (pure t))
  (string-join
   (cl-loop for regex in regexes collect
            (if (string-prefix-p "/" regex)
                (ptemplate--make-path-regex
                 (ptemplate--normalize-user-path-file regex))
              (ptemplate--make-basename-regex regex)))
   "\\|"))

(defun ptemplate--prune-template-files (regex)
  "Remove all template whose source files match REGEX.
This function is only supposed to be called from `ptemplate!'."
  (setf (ptemplate--copy-context-file-map ptemplate--cur-copy-context)
        (cl-delete-if
         (lambda (mapping)
           (string-match-p regex (ptemplate--file-mapping-src mapping)))
         (ptemplate--copy-context-file-map ptemplate--cur-copy-context))))

(defun ptemplate--puthash-filemap (file-map table)
  "Insert FILE-MAP's targets into the hash table TABLE.
FILE-MAP shall be a `ptemplate--copy-context-file-map' and TABLE
a hash-table with :test `equal'.

Insert each TARGET of FILE-MAP into TABLE as the KEY, with the
VALUE t."
  (dolist (mapping file-map)
    (puthash (ptemplate--file-mapping-target mapping) t table)))

(defun ptemplate--override-filemap (table file-map)
  "Remove all entries from FILE-MAP already in TABLE non-destructively.
Return the result. See `ptemplate--puthash-filemap' for details."
  (cl-remove-if (lambda (x) (gethash (ptemplate--file-mapping-target x) table))
                file-map))

(defun ptemplate--merge-filemaps (file-maps)
  "Merge FILE-MAPS non-destructively into a single file-map.
Each entry in FILE-MAPS shall be a
`ptemplate--copy-context-file-map'.

Remove each entry whose TARGET was mapped in an earlier FILE-MAP,
meaning that earlier FILE-MAPs take precedence. Do not remove
duplicates in any FILE-MAP."
  (cl-loop with visited-targets = (make-hash-table :test #'equal)
           for file-map in file-maps
           ;; we must use `append' here, as otherwise FILE-MAP would be
           ;; modified before being inserted into VISITED-TARGETS
           append (ptemplate--override-filemap visited-targets file-map)
           do (ptemplate--puthash-filemap file-map visited-targets)))

(defun ptemplate--override-files (file-maps)
  "Override all mappings in FILE-MAPS and apply the result.
Store the result in `ptemplate--copy-context-file-map'.

See `ptemplate--merge-filemaps' for details."
  (setf (ptemplate--copy-context-file-map ptemplate--cur-copy-context)
        (ptemplate--merge-filemaps file-maps)))

;;; .ptemplate.el API

(defun ptemplate-map (src target &optional type content)
  "Map SRC to TARGET for expansion.
SRC is a path relative to the ptemplate being expanded and TARGET
is a path relative to the expansion target.

SRC can also be nil, in which case nothing would be copied, but
TARGET would shadow mappings from inherited or included
templates.

TYPE specifies the type of the mapping (deduced automatically
otherwise). See `ptemplate--file-mapping-type' for the
possibilities.

CONTENT specifies a string to be used as the content of the
mapping, e.g. a yasnippet string, or the desired content of the
target for `:copy'."
  (ptemplate--appendf
   (ptemplate--file-mapping<-new
    :src (and src (ptemplate--normalize-user-path src))
    :target (ptemplate--normalize-user-path target)
    :type (or type (ptemplate--mapping-auto-type src))
    :content content)
   (ptemplate--copy-context-file-map ptemplate--cur-copy-context)))

(defun ptemplate-automap (src &optional type)
  "Map SRC to an automatically deduced target.
Map SRC to a target as if it were part of the template.

TYPE, like in `ptemplate-map', specifies the type of the
mapping."
  (ptemplate-map src (ptemplate--auto-map-file src) type))

(defun ptemplate-remap (src target)
  "Remap template file SRC to TARGET.
SRC shall be a template-relative path separated by slashes
\(conversion is done for windows\). Using .. in SRC will not
work. TARGET shall be the destination, relative to the expansion
target. See `ptemplate--normalize-user-path' for SRC name rules.

Note that directories are not recursively remapped, which means
that all files contained within them retain their original
\(implicit?\) mapping. This means that nonempty directories whose
files haven't been remapped will still be created.

See also `ptemplate-remap-rec'."
  (ptemplate--prune-template-files
   (format "\\`%s/?\\'" (ptemplate--normalize-user-path src)))
  (ptemplate-map src target))

(defun ptemplate-remap-rec (src target)
  "Like `ptemplate-remap', but handle directories recursively instead.
For each directory that is mapped to a directory within SRC,
remap it to that same directory relative to TARGET."
  (let ((remap-regex
         (concat "\\`" (regexp-quote (ptemplate--normalize-user-path-dir src))))
        (target (ptemplate--normalize-user-path-dir target)))
    (dolist (mapping (ptemplate--copy-context-file-map
                      ptemplate--cur-copy-context))
      (setf (ptemplate--file-mapping-target mapping)
            (replace-regexp-in-string
             remap-regex target (ptemplate--file-mapping-target mapping)
             nil t)))))

(defun ptemplate-copy-target (src target)
  "Copy SRC to TARGET, both relative to the expansion target.
Useful if a single snippet expansion needs to be mapped to two
files, in the :finalize block of `ptemplate!'."
  (copy-file (concat ptemplate-target-directory src)
             (concat ptemplate-target-directory target)))

(defun ptemplate-ignore (&rest regexes)
  "REGEXES specify template files to ignore.
See `ptemplate--make-basename-regex' for details. As a special
case, if a REGEX starts with /, it is interpreted as a template
path to ignore (see `ptemplate--make-path-regex'\)."
  (ptemplate--prune-template-files (ptemplate--make-ignore-regex regexes)))

(defun ptemplate-include (&rest dirs)
  "Use all files in DIRS for expansion.
The files are added as if they were part of the current template
being expanded, except that .ptemplate.el and .ptemplate.elc are
valid filenames and are not interpreted.

Mappings from the current template have the highest precedence,
followed by the mappings from DIRS, where mappings from earlier
DIRS win.

To get the opposite behaviour, use `ptemplate-include-override'."
  (ptemplate--override-files
   (cons (ptemplate--copy-context-file-map ptemplate--cur-copy-context)
         (mapcar #'ptemplate--list-template-dir-files-abs dirs))))

(defun ptemplate-include-override (&rest dirs)
  "The opposite of `ptemplate-include' in terms of behaviour.
Later DIRS take precedence. See `ptemplate-include' for details."
  (ptemplate--override-files
   (nconc
    ;; mappings from later DIRs should win.
    (nreverse (mapcar #'ptemplate--list-template-dir-files-abs dirs))
    ;; the current template's mappings
    (list (ptemplate--copy-context-file-map ptemplate--cur-copy-context)))))

(defun ptemplate--inherit-templates (srcs)
  "Inherit the hooks of all templates in SRCS.
This functions evaluates all templates in the template path list
SRCS and prepends their hooks (as defined by
`ptemplate--copy-context<-merge-hooks'\) to the current global
ones.

Return a list of path mappings corresponding to SRCS, each of
which refer to their corresponding sources (see
`ptemplate--file-map->absoluteify'\).

See also `ptemplate-inherit' and `ptemplate-inherit-overriding'."
  (let* ((inherit-contexts
          (cl-loop for src in srcs collect
                   (ptemplate--eval-template src ptemplate-target-directory)))
         (merged-context
          (ptemplate--copy-context<-merge-hooks
           (append inherit-contexts (list ptemplate--cur-copy-context)))))
    ;; don't truncate the file-map
    (setf (ptemplate--copy-context-file-map merged-context)
          (ptemplate--copy-context-file-map ptemplate--cur-copy-context))
    (setq ptemplate--cur-copy-context merged-context)
    (cl-mapcar #'ptemplate--file-map->absoluteify srcs
               (mapcar #'ptemplate--copy-context-file-map inherit-contexts))))

(defun ptemplate-inherit (&rest srcs)
  "Like `ptemplate-include', but also evaluate the .ptemplate.el file.
The hooks of all templates in SRCS are run before the current
template's ones and the files from SRCS are added for expansion.
File maps defined in the current template take precedence, so can
be used to override mappings from SRCS. Mappings from templates
that come earlier in SRCS take precedence over those from later
templates. To ignore files from SRCS, map them from nil using
:map or `ptemplate-map' before calling this function."
  ;; NOTE: templates that come later in DIRS are overridden.
  (ptemplate--override-files
   (cons (ptemplate--copy-context-file-map ptemplate--cur-copy-context)
         (ptemplate--inherit-templates srcs))))

(defun ptemplate-inherit-overriding (&rest srcs)
  "The opposite of `ptemplate-inherit' in terms of behaviour.
To `ptemplate-inherit' what `ptemplate-include-override' is to
`ptemplate-include'. Files from templates that come later in SRCS
take precedence."
  (ptemplate--override-files
   (nconc
    (nreverse (ptemplate--inherit-templates srcs))
    (list (ptemplate--copy-context-file-map ptemplate--cur-copy-context)))))

(defun ptemplate-source (dir)
  "Return DIR as if relative to `ptemplate-source-directory'."
  ;; NOTE: `ptemplate-source-directory' ends in a slash.
  (concat ptemplate-source-directory dir))

(defun ptemplate-target (dir)
  "Return DIR as if relative to `ptemplate-target-directory'."
  (concat ptemplate-target-directory dir))

(defun ptemplate-in-file-sandbox (f)
  "`funcall' F with an isolated filemap.
The file map in which F is executed is initially empty and
appended to the global one afterwards.

Return the result of calling F."
  (let ((old-filemap
          (ptemplate--copy-context-file-map ptemplate--cur-copy-context)))
     (setf (ptemplate--copy-context-file-map ptemplate--cur-copy-context) nil)
     (prog1
         (funcall f)
       (ptemplate--prependlf
        old-filemap
        (ptemplate--copy-context-file-map ptemplate--cur-copy-context)))))

(defmacro ptemplate-with-file-sandbox (&rest body)
  "Like `ptemplate-in-file-sandbox', but as a macro.
Return the result of the last BODY form."
  (declare (indent 0))
  `(ptemplate-file-sandbox (lambda () ,@body)))

;;; snippet configuration

(defun ptemplate-snippet-setup (snippets callback)
  "Run CALLBACK to configure SNIPPETS.
SNIPPETS is a list of target-relative file snippet targets
\(.yas, .autoyas\). If a yasnippet expands to them, CALLBACK is
called and can configure them further. All variables defined in
:snippet-env, :snippet-let, ... are available to it."
  (cl-loop with snippets = (mapcar #'ptemplate--normalize-user-path snippets)
           for mapping in (ptemplate--copy-context-file-map
                           ptemplate--cur-copy-context)
           for target = (ptemplate--file-mapping-target mapping)
           if (member target snippets) do
           (unless (ptemplate--file-mapping->snippet-p mapping)
             (error "Trying to configure non-snippet mapping %S" mapping))
           (ptemplate--appendf
            callback (ptemplate--file-mapping-snippet-setup-hook mapping))))

(defmacro ptemplate-snippet-setup! (snippets &rest body)
  "Like `ptemplate--snippet-setup', but as a macro.
SNIPPETS shall be an expression yielding a list snippet-chain
  (declare (indent 1))
expansion targets. BODY will be executed for each of them."
  `(ptemplate-snippet-setup
    ,snippets (lambda () "Run to configure snippet-chain buffers." ,@body)))

(defun ptemplate-add-snippet-next-hook (&rest functions)
  "Add `ptemplate-snippet-chain-next' functions.
Each function in FUNCTIONS is run at the start of the above
function.

Only for use with `ptemplate-snippet-setup'."
  (dolist (fn functions)
    (add-hook 'ptemplate--snippet-chain-next-hook fn nil t)))

(defmacro ptemplate-add-snippet-next-hook! (&rest body)
  "Like `ptemplate-add-snippet-next-hook', but as a macro.
Add a lambda containing each form in BODY."
  `(ptemplate-add-snippet-next-hook
    (lambda () "Run in `ptemplate-snippet-chain-next'." ,@body)))

(defun ptemplate-set-snippet-kill-p (&optional kill-p)
  "Set whether the snippet buffer should be killed.
When continuing the snippet-chain with
`ptemplate-snippet-chain-next', snippet chain buffers would
usually be killed. Use this function to change that to KILL-P.
Only for use in `ptemplate-snippet-setup'."
  (setq ptemplate--snippet-chain-nokill (not kill-p)))

(defun ptemplate-nokill-snippets (snippets)
  "Don't kill SNIPPETS after expansion.
SNIPPETS is a list of target-relative file snippets (.yas) whose
buffers should not be killed in `ptemplate-snippet-chain-next'."
  (ptemplate-snippet-setup snippets #'ptemplate-set-snippet-kill-p))

(defun ptemplate-nokill-snippets! (&rest snippets)
  "Like `ptemplate-nokill-snippets', but SNIPPETS is &rest."
  (ptemplate-nokill-snippets snippets))

;; ;;;###autoload is unnecessary here, as `ptemplate!' is only useful in
;; .ptemplate.el files, which are only ever loaded from
;; `ptemplate-expand-template', at which point `ptemplate' is already loaded.
(defmacro ptemplate! (&rest args)
  "Define a smart ptemplate with Elisp.
For use in .ptemplate.el files. ARGS is a plist-like list with
any number of sections, specified as :<section name>
FORM... (like in `use-package'). Sections can appear multiple
times: you could, for example, have multiple :init sections, the
FORMs of which would get evaluated in sequence. Supported keyword
are:

:init FORMs to run before expansion. This is the default when no
      section is specified.

:before-snippets FORMs to run before expanding yasnippets.

:after-copy FORMs to run after all files have been copied. The
            ptemplate's snippets need not have been expanded
            already.

:finalize FORMs to run after expansion finishes.

:snippet-env VARIABLES to make available in snippets. Their
             values are examined at the end of `ptemplate!' and
             stored. Each element after :env shall be a symbol or
             a list of the form (SYMBOL VALUEFORM), like in
             `let'. The SYMBOLs should not be quoted. If only a
             symbol is specified, its value is taken from the
             current environment. This way, variables can be
             let-bound outside of `ptemplate!' and used in
             snippets. Leaving out VALUEFORM makes it nil.

:snippet-let VARIABLES to `let*'-bind around the `ptemplate!'
             block and to include in the snippet environment.
             Each ARG shall be a list (SYMBOL VALUEFORM) or just
             SYMBOL. If specified as SYMBOL, the variable is
             initialized to nil. Otherwise, VALUEFORM is used to
             initialize the variable. Note that the value of
             snippet-let blocks can be changed in :init.

:let like :snippet-let, but variables are not added to to snippet
     environment.

:ignore Syntax sugar for `ptemplate-ignore'. Files are pruned
        before :init.

:automap Specify files to `ptemplate-automap'. Executed after
         :ignore. Can be useful to reorder snippets: first
         :ignore \"/\", then :automap them in the correct order.

:automap-typed Like :automap, but of the form (SRC TYPE); SRC and
               TYPE are passed to a single invocation of
               `ptemplate-automap' in that order.

:subdir Make some template-relative paths appear to be in the
        root. Practically, this means not adding its files and
        including it. Evaluated before :init.

:remap ARG shall be of the form (SRC TARGET); calls
       `ptemplate-remap' on the results of evaluating SRC and
       TARGET. Run after :init.

:remap-rec Like :remap, but call `ptemplate-remap-rec' instead.
           Note that it is undefined whether :remap-rec or :remap
           is executed firsts and their order of appearance is
           insignificant.

:map Syntax sugar for `ptemplate-map'. ARG must be of the form
     (SRC TARGET TYPE), both of which are ordinary LISP
     expressions. Run after :remap and :remap-rec.

:inherit Syntax sugar for `ptemplate-inherit'. FORMs may be
         arbitrary Lisp expressions (not just strings). Executed
         after :map.

:inherit-rel Like :inherit, but the paths are relative to the
             expansion source (`ptemplate-source').

:open-bg Expressions yielding files (target-relative) to open
         with `find-file-noselect' at the very end of expansion.

:open Like :open-bg, but open the last file using `find-file'.
      Files that are not the last one will be opened using
      `find-file-noselect'.

:late Executed after :inherit.

Note that because .ptemplate.el files just execute arbitrary
code, you could write them entirely without using this
macro (e.g. by modifying hooks directly, ...). However, you
should still use `ptemplate!', as it abstracts away those
internal details, which are subject to change at any time."
  (declare (indent 0))
  (let ((cur-keyword :init)
        init-forms
        before-yas-forms
        after-copy-forms
        finalize-forms open-fg open-bg
        snippet-env
        around-let
        ignore-expressions automap-forms
        inherited-templates
        include-dirs
        remap-forms map-forms
        late-forms
        nokill-buffers snippet-setup-forms)
    (dolist (arg args)
      (if (keywordp arg)
          (setq cur-keyword arg)
        (pcase cur-keyword
          (:init (push arg init-forms))
          (:before-snippets (push arg before-yas-forms))
          (:after-copy (push arg after-copy-forms))
          (:finalize (push arg finalize-forms))
          (:open (push arg open-fg))
          (:open-bg (push arg open-bg))
          (:snippet-env (push arg snippet-env))
          (:snippet-let
           (push (if (consp arg) (car arg) arg) snippet-env)
           (push arg around-let))
          (:let (push arg around-let))
          (:ignore (push arg ignore-expressions))
          (:automap (push `(ptemplate-automap ,arg) automap-forms))
          (:automap-typed
           (cl-destructuring-bind (src &optional type) arg
             (push `(ptemplate-automap ,src ,@(when type (list type)))
                   automap-forms)))
          (:inherit (push arg inherited-templates))
          (:inherit-rel (push `(ptemplate-source ,arg) inherited-templates))
          (:subdir (let ((simplified-path (ptemplate--simplify-user-path arg)))
                     (push (concat "/" simplified-path) ignore-expressions)
                     (push simplified-path include-dirs)))
          (:remap (push `(ptemplate-remap ,(car arg) ,(cadr arg)) remap-forms))
          (:remap-rec (push `(ptemplate-remap-rec ,(car arg) ,(cadr arg))
                            remap-forms))
          (:map (cl-destructuring-bind (src target &optional type) arg
                  (push `(ptemplate-map ,src ,target ,@(when type (list type)))
                        map-forms)))
          (:late (push arg late-forms))
          (:nokill (push arg nokill-buffers))
          (:snippet-setup
           (push `(ptemplate-snippet-setup (lambda () ,@(cdr arg)) ,@(car arg))
                 snippet-setup-forms))
;;; HACKING: add new `ptemplate' blocks before here

;;; `ptemplate!' error handling
          (_ (error "`ptemplate!': unknown keyword '%s'" cur-keyword)))))
    (macroexp-let*
     (nreverse around-let)
     (macroexp-progn
      (nconc
       (when ignore-expressions
         `((ptemplate-ignore ,@ignore-expressions)))
       (nreverse automap-forms)
       (when include-dirs
         ;; include dirs specified first take precedence
         `((ptemplate-include
            ,@(cl-loop for dir in (nreverse include-dirs)
                       collect (list #'ptemplate-source dir)))))
       (nreverse init-forms)
       (nreverse remap-forms)
       (nreverse map-forms)
       ;; execute late to give the user the chance to map files in a way that
       ;; overrides first.
       (when inherited-templates
         `((ptemplate-inherit ,@inherited-templates)))
       (nreverse late-forms)
       (when before-yas-forms
         `((add-hook 'ptemplate--before-snippet-hook
                     (lambda () "Run before expanding snippets."
                       ,@(nreverse before-yas-forms)))))
       (when after-copy-forms
         `((add-hook 'ptemplate--after-copy-hook
                     (lambda () "Run after copying files."
                       ,@(nreverse after-copy-forms)))))
       (when (or finalize-forms open-bg open-fg)
         `((add-hook 'ptemplate--finalize-hook
                     (lambda () "Run after template expansion finishes."
                       ,@(nreverse finalize-forms)
;;; :open-bg, :open
                       ;; First open all files from :open-bg and then all files
                       ;; except the last :open file (push prepends to the list,
                       ;; so they are in reverse) using `find-file-noselect'.
                       ;; Edge case: open-fg is nil; however, `cdr' nil -> nil.
                       ,@(cl-loop for bg-f in (nconc (nreverse open-bg)
                                                     (nreverse (cdr open-fg)))
                                  collect `(find-file-noselect (ptemplate-target ,bg-f)))
                       ;; Are there any files to be opened in the foreground? If
                       ;; yes, open only the first that way.
                       ,@(when open-fg
                           (list (car open-fg)))))))
       (when snippet-env
         `((ptemplate--appendlf
            (list ,@(cl-loop
                     for var in snippet-env collect
                     (if (listp var)
                         (list #'cons (macroexp-quote (car var)) (cadr var))
                       `(cons ',var ,var))))
            (ptemplate--copy-context-snippet-env ptemplate--cur-copy-context))))
       (nreverse snippet-setup-forms)
       (when nokill-buffers
         ;; `nreverse' is technically unnecessary here, but it looks better in
         ;; the template expansion.
         `((ptemplate-nokill-snippets! ,@(nreverse nokill-buffers)))))))))

(provide 'ptemplate)
;;; ptemplate.el ends here

;;; Fix spell checking
;; LocalWords: UNTRUSTED
;; LocalWords: Nikita
;; LocalWords: Bloshchanevich
;; LocalWords: emacs
;; LocalWords: Elisp
;; LocalWords: ispell
;; LocalWords: ptemplate
;; LocalWords: ptemplate's
;; LocalWords: yasnippet
;; LocalWords: yasnippets
;; LocalWords: yas
;; LocalWords: autoyas
;; LocalWords: nocopy
;; LocalWords: el
;; LocalWords: elc
;; LocalWords: Alist
;; LocalWords: alist
;; LocalWords: plist
;; LocalWords: ENV
;; LocalWords: NEWBUF
;; LocalWords: env
;; LocalWords: DIRS
;; LocalWords: SRC
;; LocalWords: SRCS
;; LocalWords: RSRC
;; LocalWords: FSRC
;; LocalWords: DUP
;; LocalWords: FORMs
;; LocalWords: CONTEXT's
;; LocalWords: init

;; Local Variables:
;; fill-column: 79
;; ispell-dictionary: "en"
;; End:
