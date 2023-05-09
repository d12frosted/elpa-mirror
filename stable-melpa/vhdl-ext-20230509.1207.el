;;; vhdl-ext.el --- VHDL Extensions -*- lexical-binding: t -*-

;; Copyright (C) 2022-2023 Gonzalo Larumbe

;; Author: Gonzalo Larumbe <gonzalomlarumbe@gmail.com>
;; URL: https://github.com/gmlarumbe/vhdl-ext
;; Package-Version: 20230509.1207
;; Package-Commit: 0c1a1be2068564917dbc7811bbee4167c720c816
;; Version: 0.1.0
;; Keywords: VHDL, IDE, Tools
;; Package-Requires: ((emacs "28.1") (eglot "1.9") (lsp-mode "8.0.1") (ag "0.48") (ripgrep "0.4.0") (hydra "0.15.0") (flycheck "33-cvs"))

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

;; Extensions for VHDL Mode:
;;  - Tree-sitter support (requires Emacs 29)
;;  - Improve syntax highlighting
;;  - LSP configuration for `lsp-mode' and `eglot'
;;  - Additional options for `flycheck' linters
;;  - Improve `imenu': detect instances
;;  - Navigate through instances in a module
;;  - Jump to definition/reference of module at point
;;  - Templates insertion via `hydra'

;;; Code:

(require 'vhdl-mode)
(require 'eglot)
(require 'lsp-mode)
(require 'lsp-vhdl)
(require 'ag)
(require 'ripgrep)
(require 'hydra)
(require 'flycheck)


;;; Customization
(defgroup vhdl-ext nil
  "VHDL Extensions."
  :group 'languages
  :group 'vhdl-mode)

(defcustom vhdl-ext-jump-to-parent-module-engine "ag"
  "Default program to find parent module instantiations.
Either `rg' or `ag' are implemented."
  :type '(choice (const :tag "silver searcher" "ag")
                 (const :tag "ripgrep"         "rg"))
  :group 'vhdl-ext)


;;; Utils
(defconst vhdl-ext-blank-optional-re "[[:blank:]\n]*")
(defconst vhdl-ext-blank-mandatory-re "[[:blank:]\n]+")
(defconst vhdl-ext-identifier-re "[a-zA-Z_][a-zA-Z0-9_-]*")
(defconst vhdl-ext-instance-re
  (concat "^\\s-*\\(?1:" vhdl-ext-identifier-re "\\)\\s-*:" vhdl-ext-blank-optional-re ; Instance name
          "\\(?2:\\(?3:component\\s-+\\|configuration\\s-+\\|\\(?4:entity\\s-+\\(?5:" vhdl-ext-identifier-re "\\)\\.\\)\\)\\)?"
          "\\(?6:" vhdl-ext-identifier-re "\\)" vhdl-ext-blank-optional-re ; Entity name
          "\\(--[^\n]*" vhdl-ext-blank-mandatory-re "\\)*\\(generic\\|port\\)\\s-+map\\>"))
(defconst vhdl-ext-entity-re "^\\s-*\\(entity\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\)")
(defconst vhdl-ext-function-re "^\\s-*\\(\\(\\(impure\\|pure\\)\\s-+\\|\\)function\\)\\s-+\\(\"?\\(\\w\\|\\s_\\)+\"?\\)")
(defconst vhdl-ext-procedure-re "^\\s-*\\(\\(\\(impure\\|pure\\)\\s-+\\|\\)procedure\\)\\s-+\\(\"?\\(\\w\\|\\s_\\)+\"?\\)")
(defconst vhdl-ext-component-re "^\\s-*\\(component\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\)")
(defconst vhdl-ext-process-re "^\\s-*\\(\\(\\w\\|\\s_\\)+\\)\\s-*:\\(\\s-\\|\n\\)*\\(\\(postponed\\s-+\\|\\)process\\)")
(defconst vhdl-ext-block-re "^\\s-*\\(\\(\\w\\|\\s_\\)+\\)\\s-*:\\(\\s-\\|\n\\)*\\(block\\)")
(defconst vhdl-ext-package-re "^\\s-*\\(package\\( body\\|\\)\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\)")
(defconst vhdl-ext-configuration-re "^\\s-*\\(configuration\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\s-+of\\s-+\\(\\w\\|\\s_\\)+\\)")
(defconst vhdl-ext-architecture-re "^\\s-*\\(architecture\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\s-+of\\s-+\\(\\w\\|\\s_\\)+\\)")
(defconst vhdl-ext-context-re "^\\s-*\\(context\\)\\s-+\\(\\(\\w\\|\\s_\\)+\\)")

(defvar vhdl-ext-buffer-list nil)
(defvar vhdl-ext-dir-list nil)


(defun vhdl-ext-path-join (arg1 arg2)
  "Join path of ARG1 and ARG2."
  (if (and arg1 arg2)
      (concat (file-name-as-directory arg1) arg2)
    (error "Cannot join path with nil arguments")
    nil))

(defun vhdl-ext-replace-regexp (regexp to-string start end)
  "Wrapper function for programatic use of `replace-regexp'.
Replace REGEXP with TO-STRING from START to END."
  (let* ((marker (make-marker))
         (endpos (when end (set-marker marker end))))
    (save-excursion
      (goto-char start)
      (while (re-search-forward regexp endpos t)
        (replace-match to-string)))))

(defun vhdl-ext-replace-regexp-whole-buffer (regexp to-string)
  "Replace REGEXP with TO-STRING on whole `current-buffer'."
  (vhdl-ext-replace-regexp regexp to-string (point-min) nil))

(defun vhdl-ext-replace-string (string to-string start end &optional fixedcase)
  "Wrapper function for programatic use of `replace-string'.
Replace STRING with TO-STRING from START to END.

If optional arg FIXEDCASE is non-nil, do not alter the case of
the replacement text (see `replace-match' for more info)."
  (let* ((marker (make-marker))
         (endpos (when end (set-marker marker end))))
    (save-excursion
      (goto-char start)
      (while (search-forward string endpos t)
        (replace-match to-string fixedcase)))))

(defun vhdl-ext-scan-buffer-entities ()
  "Find entities in current buffer.
Return list with found entities or nil if not found."
  (let (entities)
    (save-excursion
      (goto-char (point-min))
      (while (vhdl-re-search-forward vhdl-ext-entity-re nil t)
        (push (match-string-no-properties 2) entities)))
    (delete-dups entities)))

(defun vhdl-ext-read-file-entities (&optional file)
  "Find entities in current buffer.
Find entities in FILE if optional arg is non-nil.
Return list with found entities or nil if not found."
  (let ((buf (if file
                 (get-file-buffer file)
               (current-buffer)))
        (debug nil))
    (if buf
        (with-current-buffer buf
          (vhdl-ext-scan-buffer-entities))
      ;; If FILE buffer is not being visited, use a temporary buffer
      (with-temp-buffer
        (when debug
          (clone-indirect-buffer-other-window "*debug*" t))
        (insert-file-contents file)
        (vhdl-ext-scan-buffer-entities)))))

(defun vhdl-ext-select-file-entity (&optional file)
  "Select file entity from FILE.
If only one entity was found return it as a string.
If more than one entity was found, select between available ones.
Return nil if no entity was found."
  (let ((entities (vhdl-ext-read-file-entities file)))
    (if (cdr entities)
        (completing-read "Select entity: " entities)
      (car entities))))

(defun vhdl-ext-project-root ()
  "Find current project root, depending on available packages."
  (or (and (project-current)
           (project-root (project-current)))
      default-directory))

(defun vhdl-ext-update-buffer-and-dir-list ()
  "Update Vhdl-mode opened buffers and directories lists."
  (let (vhdl-buffers vhdl-dirs)
    (dolist (buf (buffer-list (current-buffer)))
      (with-current-buffer buf
        (when (or (eq major-mode 'vhdl-mode)
                  (eq major-mode 'vhdl-ts-mode))
          (push buf vhdl-buffers)
          (unless (member default-directory vhdl-dirs)
            (push default-directory vhdl-dirs)))))
    (setq vhdl-ext-buffer-list vhdl-buffers)
    (setq vhdl-ext-dir-list vhdl-dirs)))

(defun vhdl-ext-get-standard ()
  "Get current standard as a string from `vhdl-standard'."
  (let ((std (car vhdl-standard)))
    (if (equal std 8)
        (format "0%s" std)
      (format "%s" std))))

(defun vhdl-ext-kill-buffer-hook ()
  "VHDL hook to run when killing a buffer."
  (setq vhdl-ext-buffer-list (remove (current-buffer) vhdl-ext-buffer-list)))

(defun vhdl-ext-workdir ()
  "Return the working library directory according to current project.
Check `vhdl-project-alist'."
  (let ((root (nth 1 (vhdl-aget vhdl-project-alist vhdl-project)))
        (dir  (nth 7 (vhdl-aget vhdl-project-alist vhdl-project))))
    (when (and root dir)
      (vhdl-ext-path-join root dir))))


;;; Navigation
;;  - Find instances forward/backwards
;;  - Jump to definition/reference of entity at point
(defun vhdl-ext-find-entity-instance (&optional limit bwd interactive-p)
  "Search for a VHDL entity/instance.
Optional LIMIT argument bounds the search.

If optional argument BWD is non-nil search backwards instead.

Third arg INTERACTIVE-P specifies whether function call should be treated as if
it was interactive.  This changes the position where point will be at the end of
the function call."
  (let ((found nil)
        (pos))
    (save-excursion
      (when interactive-p
        (if bwd
            (backward-char))
        (forward-char))
      (while (and (not found)
                  (if bwd
                      (re-search-backward vhdl-ext-instance-re limit t)
                    (re-search-forward vhdl-ext-instance-re limit t)))
        (unless (or (equal (face-at-point) 'font-lock-comment-face)
                    (equal (face-at-point) 'font-lock-string-face))
          (setq found t)
          (if interactive-p
              (setq pos (match-beginning 6))
            (setq pos (point))))))
    (when found
      (goto-char pos))))

(defun vhdl-ext-find-entity-instance-fwd (&optional limit)
  "Search forward for a VHDL entity/instance.
Optional LIMIT argument bounds the search."
  (interactive)
  (let ((interactive-p (called-interactively-p 'any)))
    (vhdl-ext-find-entity-instance limit nil interactive-p)))

(defun vhdl-ext-find-entity-instance-bwd (&optional limit)
  "Search backward for a VHDL entity/instance.
Optional LIMIT argument bounds the search."
  (interactive)
  (let ((interactive-p (called-interactively-p 'any)))
    (vhdl-ext-find-entity-instance limit :bwd interactive-p)))

(defun vhdl-ext-instance-at-point ()
  "Return list with entity and instance names if point is at an instance."
  (let ((point-cur (point))
        point-instance-begin point-instance-end instance-type instance-name)
    (save-excursion
      (when (and (vhdl-re-search-forward ";" nil t)
                 (vhdl-ext-find-entity-instance-bwd) ; Sets match data
                 (setq instance-name (match-string-no-properties 1))
                 (setq instance-type (match-string-no-properties 6))
                 (setq point-instance-begin (match-beginning 1))
                 (vhdl-re-search-forward ";" nil t) ; Needed to avoid issues with last instance on a file
                 (setq point-instance-end (1- (point))))
        (if (and (>= point-cur point-instance-begin)
                 (<= point-cur point-instance-end))
            (list instance-type instance-name)
          nil)))))

(defun vhdl-ext-jump-to-entity-at-point (&optional ref)
  "Jump to definition of instance at point.
If REF is non-nil show references instead."
  (interactive)
  (let ((entity (car (vhdl-ext-instance-at-point))))
    (if entity
        (progn
          (if ref
              (xref-find-references entity)
            (xref-find-definitions entity))
          entity) ; Report entity name
      (user-error "Not inside a VHDL instance"))))

(defun vhdl-ext-jump-to-entity-at-point-def ()
  "Jump to definition of entity at point."
  (interactive)
  (vhdl-ext-jump-to-entity-at-point))

(defun vhdl-ext-jump-to-entity-at-point-ref ()
  "Show references of entity at point."
  (interactive)
  (vhdl-ext-jump-to-entity-at-point :ref))


;;;; Jump to parent module
(defvar vhdl-ext-jump-to-parent-module-point-marker nil
  "Point marker to save the state of the buffer where the search was started.
Used in ag/rg end of search hooks to conditionally set the xref marker stack.")
(defvar vhdl-ext-jump-to-parent-module-name nil)
(defvar vhdl-ext-jump-to-parent-module-dir nil)
(defvar vhdl-ext-jump-to-parent-trigger nil
  "Variable to run the post ag/rg command hook.
Run only when the ag/rg search was triggered by `vhdl-ext-jump-to-parent-entity'
command.")

(defun vhdl-ext-jump-to-parent-entity ()
  "Find current module/interface instantiations via `ag'/`rg'.
Configuration should be done so that `vhdl-ext-navigation-ag-rg-hook' is run
after the search has been done."
  (interactive)
  (let* ((proj-dir (vhdl-ext-project-root))
         (entity-name (or (vhdl-ext-select-file-entity buffer-file-name)
                          (error "No entity found @ %s" buffer-file-name)))
         ;; Regexp fetched from `vhdl-ext-instance-re', replaced "\\s-" with "[ ]"
         ;; and dismissing \n to allow for easy elisp to pcre conversion
         (entity-instance-pcre (concat "^[ ]*(" vhdl-ext-identifier-re ")[ ]*:[ ]*" ; Instance name
                                       "(((component)|(configuration)|(entity))[ ]+(" vhdl-ext-identifier-re ")\\.)?"
                                       "\\b(" entity-name ")\\b")))
    ;; Update variables used by the ag/rg search finished hooks
    (setq vhdl-ext-jump-to-parent-module-name entity-name)
    (setq vhdl-ext-jump-to-parent-module-dir proj-dir)
    ;; Perform project based search
    (cond
     ;; Try ripgrep
     ((and (string= vhdl-ext-jump-to-parent-module-engine "rg")
           (executable-find "rg"))
      (let ((rg-extra-args '("-t" "vhdl" "--pcre2" "--multiline" "--stats")))
        (setq vhdl-ext-jump-to-parent-module-point-marker (point-marker))
        (setq vhdl-ext-jump-to-parent-trigger t)
        (ripgrep-regexp entity-instance-pcre proj-dir rg-extra-args)))
     ;; Try ag
     ((and (string= vhdl-ext-jump-to-parent-module-engine "ag")
           (executable-find "ag"))
      (let ((ag-arguments ag-arguments)
            (extra-ag-args '("--vhdl" "--stats")))
        (dolist (extra-ag-arg extra-ag-args)
          (add-to-list 'ag-arguments extra-ag-arg :append))
        (setq vhdl-ext-jump-to-parent-module-point-marker (point-marker))
        (setq vhdl-ext-jump-to-parent-trigger t)
        (ag-regexp entity-instance-pcre proj-dir)))
     ;; Fallback
     (t
      (error "Did not find `rg' nor `ag' in $PATH")))))

(defun vhdl-ext-navigation-ag-rg-hook ()
  "Jump to the first result and push xref marker if there were any matches.
Kill the buffer if there is only one match."
  (when vhdl-ext-jump-to-parent-trigger
    (let ((entity-name (propertize vhdl-ext-jump-to-parent-module-name 'face '(:foreground "green")))
          (dir (propertize vhdl-ext-jump-to-parent-module-dir 'face '(:foreground "light blue")))
          (num-matches))
      (save-excursion
        (goto-char (point-min))
        (re-search-forward "^\\([0-9]+\\) matches\\s-*$" nil :noerror)
        (setq num-matches (string-to-number (match-string-no-properties 1))))
      (cond ((eq num-matches 1)
             (xref-push-marker-stack vhdl-ext-jump-to-parent-module-point-marker)
             (next-error)
             (kill-buffer (current-buffer))
             (message "Jump to only match for [%s] @ %s" entity-name dir))
            ((> num-matches 1)
             (xref-push-marker-stack vhdl-ext-jump-to-parent-module-point-marker)
             (next-error)
             (message "Showing matches for [%s] @ %s" entity-name dir))
            (t
             (kill-buffer (current-buffer))
             (message "No matches found")))
      (setq vhdl-ext-jump-to-parent-trigger nil))))


;;; Imenu
(defconst vhdl-ext-imenu-generic-expression
  `(("Instance"      vhdl-ext-find-entity-instance-bwd 6)
    ("Function"      ,vhdl-ext-function-re 4)
    ("Procedure"     ,vhdl-ext-procedure-re 4)
    ("Process"       ,vhdl-ext-process-re 1)
    ("Component"     ,vhdl-ext-component-re 2)
    ("Block"         ,vhdl-ext-block-re 1)
    ("Package"       ,vhdl-ext-package-re 3)
    ("Configuration" ,vhdl-ext-configuration-re 2)
    ("Architecture"  ,vhdl-ext-architecture-re 2)
    ("Entity"        ,vhdl-ext-entity-re 2)
    ("Context"       ,vhdl-ext-context-re 2))
  "Imenu generic expression for VHDL Mode.  See `imenu-generic-expression'.")

(defun vhdl-ext-index-menu-init ()
  "Initialize index menu."
  (setq-local imenu-case-fold-search t)
  (setq-local imenu-generic-expression vhdl-ext-imenu-generic-expression)
  (when (and vhdl-index-menu
             (fboundp 'imenu))
    (imenu-add-to-menubar "Index")))


;;; Templates
(defun vhdl-ext-entity-from-file (file &optional port-copy)
  "Find first entity declaration in FILE.
If optional arg PORT-COPY is non-nil, get generic and port information from an
entity or component declaration via `vhdl-port-copy'."
  (with-temp-buffer
    (insert-file-contents file)
    (when (re-search-forward vhdl-ext-entity-re nil t)
      (when port-copy
        (save-match-data
          (vhdl-port-copy)))
      (match-string-no-properties 2))))

(defun vhdl-ext-insert-instance-from-file (file)
  "Insert entity instance from FILE."
  (interactive "FSelect entity from file:")
  (let* ((entity-name (vhdl-ext-entity-from-file file :port-copy))
         (instance-name (read-string "Instance-name: " (concat "I_" (upcase entity-name)))))
    (vhdl-port-paste-instance instance-name)))

(defun vhdl-ext-insert-testbench-from-file (file outfile)
  "Create testbench from entity of selected FILE in OUTFILE."
  (interactive "FSelect entity from file:\nFOutput file: ")
  (when (file-exists-p outfile)
    (error "File %s exists" outfile))
  (vhdl-ext-entity-from-file file :port-copy)
  (find-file outfile)
  (vhdl-port-paste-testbench))

;;;; Hydra
(defhydra vhdl-ext-hydra (:color blue
                          :hint nil)
  ("ac"  (vhdl-template-architecture) "architecture" :column "A-C")
  ("al"  (vhdl-template-alias)        "alias")
  ("as"  (vhdl-template-assert)       "assert")
  ("at"  (vhdl-template-attribute)    "attribute")
  ("cc"  (vhdl-template-case)         "case")
  ("cp"  (vhdl-template-component)    "component")
  ("ct"  (vhdl-template-constant)     "constant")
  ("en"  (vhdl-template-entity)       "entity" :column "E-G")
  ("fl"  (vhdl-template-file)         "file")
  ("fn"  (vhdl-template-function)     "function")
  ("for" (vhdl-template-for)          "for")
  ("ge"  (vhdl-template-generic)      "generic")
  ("gn"  (vhdl-template-generate)     "generate")
  ("hd"  (vhdl-template-header)       "header" :column "H-P")
  ("if"  (vhdl-template-if-then)      "if-then")
  ("pc"  (vhdl-template-process-comb) "process comb")
  ("pb"  (vhdl-template-package-body) "package body")
  ("pd"  (vhdl-template-package-decl) "package decl")
  ("pkg" (call-interactively #'vhdl-template-insert-package) "library package")
  ("pr"  (vhdl-template-procedure)    "procedure")
  ("ps"  (vhdl-template-process-seq)  "process seq")
  ("rp"  (vhdl-template-report)       "report" :column "R-W")
  ("sg"  (vhdl-template-signal)       "signal")
  ("ty"  (vhdl-template-type)         "type")
  ("va"  (vhdl-template-variable)     "variable")
  ("wh"  (vhdl-template-while-loop)   "while")

  ("@"   (vhdl-template-clocked-wait) "clocked wait" :column "Others")
  ("IS"  (call-interactively #'vhdl-ext-insert-instance-from-file) "Instance")
  ("TS"  (call-interactively #'vhdl-ext-insert-testbench-from-file) "Testbench")

  ;;;;;;;;;;
  ;; Exit ;;
  ;;;;;;;;;;
  ("q"   nil nil :color blue)
  ("C-g" nil nil :color blue))


;;; Syntax highlighting
;; Improved syntax highlighting based on `font-lock' keywords overriding.
;;
;; Multiline Font Locking has reliability limitations in Emacs.
;;  - https://www.gnu.org/software/emacs/manual/html_node/elisp/Multiline-Font-Lock.html
;;  - https://www.gnu.org/software/emacs/manual/html_node/elisp/Font-Lock-Multiline.html
;;
;; One way to ensure reliable rehighlighting of multiline font-lock constructs
;; is by using the `font-lock-multiline' text property.
;; - The `font-lock-multiline' variable might seem to be working but is not reliable.
;; - Using the `font-lock-multiline' property might apply to a few lines (such is the case).
;;   For longer sections it is necessary to create font lock custom functions and gets
;;   more complicated.
;;
;; Search based fontification:
;; - https://www.gnu.org/software/emacs/manual/html_node/elisp/Search_002dbased-Fontification.html

;;;; Faces
(defvar vhdl-ext-font-lock-punctuation-face 'vhdl-ext-font-lock-punctuation-face)
(defface vhdl-ext-font-lock-punctuation-face
  '((t (:foreground "burlywood")))
  "Face for punctuation symbols:
!,;:?'=<>*"
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-punctuation-bold-face 'vhdl-ext-font-lock-punctuation-bold-face)
(defface vhdl-ext-font-lock-punctuation-bold-face
  '((t (:inherit vhdl-ext-font-lock-punctuation-face :weight extra-bold)))
  "Face for bold punctuation symbols, such as &^~+-/|."
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-braces-face 'vhdl-ext-font-lock-braces-face)
(defface vhdl-ext-font-lock-braces-face
  '((t (:foreground "goldenrod")))
  "Face for braces []."
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-parenthesis-face 'vhdl-ext-font-lock-parenthesis-face)
(defface vhdl-ext-font-lock-parenthesis-face
  '((t (:foreground "dark goldenrod")))
  "Face for parenthesis ()."
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-curly-brackets-face 'vhdl-ext-font-lock-curly-brackets-face)
(defface vhdl-ext-font-lock-curly-brackets-face
  '((t (:foreground "DarkGoldenrod2")))
  "Face for curly brackets {}."
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-braces-content-face 'vhdl-ext-font-lock-braces-content-face)
(defface vhdl-ext-font-lock-braces-content-face
  '((t (:foreground "yellow green")))
  "Face for content between braces: arrays, bit vector width and indexing."
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-port-connection-face 'vhdl-ext-font-lock-port-connection-face)
(defface vhdl-ext-font-lock-port-connection-face
  '((t (:foreground "bisque2")))
  "Face for port connections of instances.
portA => signalA,
portB => signalB
);"
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-entity-face 'vhdl-ext-font-lock-entity-face)
(defface vhdl-ext-font-lock-entity-face
  '((t (:foreground "green1")))
  "Face for entity names."
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-instance-face 'vhdl-ext-font-lock-instance-face)
(defface vhdl-ext-font-lock-instance-face
  '((t (:foreground "medium spring green")))
  "Face for instance names."
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-instance-lib-face 'vhdl-ext-font-lock-instance-lib-face)
(defface vhdl-ext-font-lock-instance-lib-face
  '((t (:foreground "gray70")))
  "Face for instances lib prefix."
  :group 'vhdl-ext-font-lock-faces)

(defvar vhdl-ext-font-lock-translate-off-face 'vhdl-ext-font-lock-translate-off-face)
(defface vhdl-ext-font-lock-translate-off-face
  '((t (:background "gray20" :slant italic)))
  "Face for pragmas between comments, e.g:
* translate_off / * translate_on"
  :group 'vhdl-ext-font-lock-faces)


;;;; Regexps
(defconst vhdl-ext-font-lock-punctuation-re "\\([!,;:?'=<>]\\|\\*\\)")
(defconst vhdl-ext-font-lock-punctuation-bold-re "\\([&^~+-]\\||\\|\\.\\|\\/\\)")
(defconst vhdl-ext-font-lock-parenthesis-re "[()]")
(defconst vhdl-ext-font-lock-curly-brackets-re "[{}]")
(defconst vhdl-ext-font-lock-braces-re "\\(\\[\\|\\]\\)")
(defconst vhdl-ext-font-lock-common-constructs-re
  (concat "^\\s-*\\(\\w+\\)\\s-*:[ \t\n\r\f]*\\(\\("
          "assert\\|block\\|case\\|exit\\|for\\|if\\|loop\\|next\\|null\\|"
          "postponed\\|process\\|"
          "with\\|while"
          "\\)\\>\\|\\w+\\s-*\\(([^\n]*)\\|\\.\\w+\\)*\\s-*<=\\)"))
(defconst vhdl-ext-font-lock-labels-in-block-and-components-re
  (concat "^\\s-*for\\s-+\\(\\w+\\(,\\s-*\\w+\\)*\\)\\>\\s-*"
          "\\(:[ \t\n\r\f]*\\(\\w+\\)\\|[^i \t]\\)"))
(defconst vhdl-ext-font-lock-brackets-content-range-re "\\(?1:(\\)\\(?2:[ )+*/$0-9a-zA-Z:_-]*\\)\\s-+\\(?3:\\(down\\)?to\\)\\s-+\\(?4:[ (+*/$0-9a-zA-Z:_-]*\\)\\(?5:)\\)")
(defconst vhdl-ext-font-lock-brackets-content-index-re "\\(?1:(\\)\\s-*\\(?2:[0-9]+\\)\\s-*\\(?3:)\\)")
(defconst vhdl-ext-font-lock-directive-keywords-re
  (eval-when-compile
    (regexp-opt '("psl" "pragma" "synopsys" "synthesis") 'symbols)))
(defconst vhdl-ext-font-lock-highlight-variable-declaration-names nil)

;;;; Functions
(defun vhdl-ext-font-lock-entity-instance-fontify (limit)
  "Search based fontification function of VHDL entities/instances.
Bound search by LIMIT."
  (let (start-line-pos end-line-pos)
    (when (vhdl-ext-find-entity-instance-fwd limit)
      (setq start-line-pos (save-excursion
                             (goto-char (match-beginning 0))
                             (line-beginning-position)))
      (setq end-line-pos (save-excursion
                           (goto-char (match-end 0))
                           (line-end-position)))
      (unless (get-text-property (point) 'font-lock-multiline)
        (put-text-property start-line-pos end-line-pos 'font-lock-multiline t))
      (point))))

(defun vhdl-ext-font-lock-within-translate-off ()
  "Similar as analogous `vhdl-within-translate-off' function.
Take `vhdl-ext-font-lock-directive-keywords-re' words into account instead of
only pragma."
  (and (save-excursion
         (re-search-backward
          (concat
           "^\\s-*--\\s-*" vhdl-ext-font-lock-directive-keywords-re "\\s-*translate_\\(on\\|off\\)\\s-*\n") nil t))
       (equal "off" (match-string 1))
       (point)))

(defun vhdl-ext-font-lock-start-translate-off (limit)
  "Similar as analogous `vhdl-start-translate-off' function.
Take `vhdl-ext-font-lock-directive-keywords-re' words into account instead of
only pragma.
Regex search bound to LIMIT."
  (when (re-search-forward
         (concat
          "^\\s-*--\\s-*" vhdl-ext-font-lock-directive-keywords-re "\\s-*translate_off\\s-*\n") limit t)
    (match-beginning 0)))

(defun vhdl-ext-font-lock-end-translate-off (limit)
  "Similar as analogous `vhdl-end-translate-off' function.
Take `vhdl-ext-font-lock-directive-keywords-re' words into account instead of
only pragma.
Regex search bound to LIMIT."
  (re-search-forward
   (concat "^\\s-*--\\s-*" vhdl-ext-font-lock-directive-keywords-re "\\s-*translate_on\\s-*\n") limit t))

(defun vhdl-ext-font-lock-match-translate-off (limit)
  "Similar as analogous `vhdl-match-translate-off' function.
Take `vhdl-ext-font-lock-directive-keywords-re' words into account instead of
only pragma.
Regex search bound to LIMIT."
  (when (< (point) limit)
    (let ((start (or (vhdl-ext-font-lock-within-translate-off)
                     (vhdl-ext-font-lock-start-translate-off limit)))
          (case-fold-search t))
      (when start
        (let ((end (or (vhdl-ext-font-lock-end-translate-off limit) limit)))
          (put-text-property start end 'font-lock-multiline t)
          (set-match-data (list start end))
          (goto-char end))))))

(defun vhdl-ext-font-lock-match-common-constructs-fontify (limit)
  "Search based fontification function for VHDL common constructs.
Adds the `font-lock-multiline' text property.
Regex search bound to LIMIT."
  (while (re-search-forward vhdl-ext-font-lock-common-constructs-re limit t)
    (put-text-property (match-beginning 0) (match-end 0) 'font-lock-multiline t)
    (point)))

(defun vhdl-ext-font-lock-match-labels-block-comp-fontify (limit)
  "Search based fontification function for VHDL labels in blocks and components.
Adds the `font-lock-multiline' text property.
Regex search bound to LIMIT."
  (while (re-search-forward vhdl-ext-font-lock-labels-in-block-and-components-re limit t)
    (put-text-property (match-beginning 0) (match-end 0) 'font-lock-multiline t)
    (point)))


;;;; Font-lock keywords
(defconst vhdl-ext-font-lock-keywords-0
  (list
   (list (concat "\\(^\\|[ \t(.']\\)\\(<" vhdl-template-prompt-syntax ">\\)")
         2 'vhdl-font-lock-prompt-face t)
   (list (concat "--\\s-*" vhdl-ext-font-lock-directive-keywords-re "\\s-+\\(.*\\)$")
         '(0 'vhdl-ext-font-lock-translate-off-face prepend)
         '(1 'vhdl-ext-font-lock-preprocessor-face prepend))
   ;; highlight c-preprocessor directives
   (list "^#[ \t]*\\(\\w+\\)\\([ \t]+\\(\\w+\\)\\)?"
         '(1 font-lock-builtin-face)
         '(3 font-lock-variable-name-face nil t))))

(defconst vhdl-ext-font-lock-keywords-1
  (list
   ;; highlight keywords and standardized types, attributes, enumeration, values, and subprograms
   (list (concat "'" vhdl-attributes-regexp)
         1 'vhdl-font-lock-attribute-face)
   (list vhdl-types-regexp       1 'font-lock-type-face)
   (list vhdl-functions-regexp   1 'font-lock-builtin-face)
   (list vhdl-packages-regexp    1 'font-lock-builtin-face)
   (list vhdl-enum-values-regexp 1 'vhdl-font-lock-enumvalue-face)
   (list vhdl-constants-regexp   1 'font-lock-constant-face)
   (list vhdl-keywords-regexp    1 'font-lock-keyword-face)))

(defconst vhdl-ext-font-lock-keywords-2
  (append
   (list
    ;; highlight names of units, subprograms, and components when declared
    (list
     (concat
      "^\\s-*\\("
      "architecture\\|configuration\\|context\\|entity\\|package"
      "\\(\\s-+body\\)?\\|"
      "\\(\\(impure\\|pure\\)\\s-+\\)?function\\|procedure\\|component"
      "\\)\\s-+\\(\\w+\\)")
     5 'font-lock-function-name-face)

    ;; highlight entity names of architectures and configurations
    (list
     "^\\s-*\\(architecture\\|configuration\\)\\s-+\\w+\\s-+of\\s-+\\(\\w+\\)"
     2 'font-lock-function-name-face)

    ;; highlight labels of common constructs (function-based search to add `font-lock-multiline' property)
    '(vhdl-ext-font-lock-match-common-constructs-fontify
      (1 'font-lock-function-name-face))

    ;; highlight label and component name of every instantiation (configuration, component and entity)
    '(vhdl-ext-font-lock-entity-instance-fontify
      (1 'vhdl-ext-font-lock-instance-face)
      ;; 3rd argument nil avoids font-locking in case there is no match (instantiation declaring component)
      (5 'vhdl-ext-font-lock-instance-lib-face nil t)
      (6 'vhdl-ext-font-lock-entity-face))

    ;; highlight names and labels at end of constructs
    (list
     (concat
      "^\\s-*end\\s-+\\(\\("
      "architecture\\|block\\|case\\|component\\|configuration\\|context\\|"
      "entity\\|for\\|function\\|generate\\|if\\|loop\\|package"
      "\\(\\s-+body\\)?\\|procedure\\|\\(postponed\\s-+\\)?process\\|"
      "units"
      "\\)\\s-+\\)?\\(\\w*\\)")
     5 'font-lock-function-name-face)

    ;; highlight labels in exit and next statements
    (list
     (concat
      "^\\s-*\\(\\w+\\s-*:\\s-*\\)?\\(exit\\|next\\)\\s-+\\(\\w*\\)")
     3 'font-lock-function-name-face)

    ;; highlight entity name in attribute specifications
    (list
     (concat
      "^\\s-*attribute\\s-+\\w+\\s-+of\\s-+\\(\\w+\\(,\\s-*\\w+\\)*\\)\\s-*:")
     1 'font-lock-function-name-face)

    ;; highlight labels in block and component specifications
    '(vhdl-ext-font-lock-match-labels-block-comp-fontify
      (1 font-lock-function-name-face) (4 font-lock-function-name-face nil t))

    ;; highlight names in library clauses
    (list "^\\s-*library\\>"
          '(vhdl-font-lock-match-item nil nil (1 font-lock-function-name-face)))

    ;; highlight names in use clauses
    (list
     (concat
      "\\<\\(context\\|use\\)\\s-+\\(\\(entity\\|configuration\\)\\s-+\\)?"
      "\\(\\w+\\)\\(\\.\\(\\w+\\)\\)?\\((\\(\\w+\\))\\)?")
     '(4 font-lock-function-name-face) '(6 font-lock-function-name-face nil t)
     '(8 font-lock-function-name-face nil t))

    ;; highlight attribute name in attribute declarations/specifications
    (list
     (concat
      "^\\s-*attribute\\s-+\\(\\w+\\)")
     1 'vhdl-font-lock-attribute-face)

    ;; highlight type/nature name in (sub)type/(sub)nature declarations
    (list
     (concat
      "^\\s-*\\(\\(sub\\)?\\(nature\\|type\\)\\|end\\s-+\\(record\\|protected\\)\\)\\s-+\\(\\w+\\)")
     5 'font-lock-type-face)

    ;; highlight formal parameters in component instantiations and subprogram
    ;; calls
    (list "\\(=>\\)"
          '(vhdl-font-lock-match-item
            (progn (goto-char (match-beginning 1))
                   (skip-syntax-backward " ")
                   (while (= (preceding-char) ?\)) (backward-sexp))
                   (skip-syntax-backward "w_")
                   (skip-syntax-backward " ")
                   (when (memq (preceding-char) '(?n ?N ?|))
                     (goto-char (point-max))))
            (goto-char (match-end 1)) (1 vhdl-ext-font-lock-port-connection-face)))

    ;; highlight alias/group/quantity declaration names and for-loop/-generate
    ;; variables
    (list "\\<\\(alias\\|for\\|group\\|quantity\\)\\s-+\\w+\\s-+\\(across\\|in\\|is\\)\\>"
          '(vhdl-font-lock-match-item
            (progn (goto-char (match-end 1)) (match-beginning 2))
            nil (1 font-lock-variable-name-face)))

    ;; highlight tool directives
    (list
     (concat
      "^\\s-*\\(`\\w+\\)")
     1 'font-lock-preprocessor-face))

   ;; highlight signal/variable/constant declaration names
   (when vhdl-ext-font-lock-highlight-variable-declaration-names
     (list "\\(:[^=]\\)"
           '(vhdl-font-lock-match-item
             (progn (goto-char (match-beginning 1))
                    (skip-syntax-backward " ")
                    (skip-syntax-backward "w_")
                    (skip-syntax-backward " ")
                    (while (= (preceding-char) ?,)
                      (backward-char 1)
                      (skip-syntax-backward " ")
                      (skip-syntax-backward "w_")
                      (skip-syntax-backward " ")))
             (goto-char (match-end 1)) (1 vhdl-ext-font-lock-variable-name-face))))))


;; highlight words with special syntax.
(defconst vhdl-ext-font-lock-keywords-3
  (let ((syntax-alist vhdl-special-syntax-alist) ; "generic/constant" "type" "variable"
        keywords)
    (while syntax-alist
      (setq keywords
            (cons
             (list (concat "\\(" (nth 1 (car syntax-alist)) "\\)") 1
                   (vhdl-function-name
                    "vhdl-font-lock" (nth 0 (car syntax-alist)) "face")
                   (nth 4 (car syntax-alist)))
             keywords))
      (setq syntax-alist (cdr syntax-alist)))
    keywords))

;; highlight additional reserved words
(defconst vhdl-ext-font-lock-keywords-4
  (list (list vhdl-reserved-words-regexp 1
              'vhdl-font-lock-reserved-words-face)))

;; highlight translate_off regions
(defconst vhdl-ext-font-lock-keywords-5
  '((vhdl-ext-font-lock-match-translate-off
     (0 vhdl-ext-font-lock-translate-off-face prepend))))

;; Punctuation and other symbols
(defconst vhdl-ext-font-lock-keywords-6
  (list
   ;; Punctuation
   (list vhdl-ext-font-lock-punctuation-re 0 vhdl-ext-font-lock-punctuation-face)
   (list vhdl-ext-font-lock-punctuation-bold-re 0 vhdl-ext-font-lock-punctuation-bold-face)
   ;; Bit range
   (list vhdl-ext-font-lock-brackets-content-range-re
         '(1 vhdl-ext-font-lock-curly-brackets-face)
         '(5 vhdl-ext-font-lock-curly-brackets-face)
         '(2 vhdl-ext-font-lock-braces-content-face)
         '(4 vhdl-ext-font-lock-braces-content-face)
         '(3 vhdl-ext-font-lock-instance-lib-face))
   ;; Bit index
   (list vhdl-ext-font-lock-brackets-content-index-re
         '(1 vhdl-ext-font-lock-curly-brackets-face)
         '(3 vhdl-ext-font-lock-curly-brackets-face)
         '(2 vhdl-ext-font-lock-braces-content-face))
   ;; Braces and brackets
   (list vhdl-ext-font-lock-braces-re 0 vhdl-ext-font-lock-braces-face)
   (list vhdl-ext-font-lock-parenthesis-re 0 vhdl-ext-font-lock-parenthesis-face)
   (list vhdl-ext-font-lock-curly-brackets-re 0 vhdl-ext-font-lock-curly-brackets-face)))

;; highlight everything together
(defconst vhdl-ext-font-lock-keywords
  (append
   vhdl-ext-font-lock-keywords-6
   vhdl-ext-font-lock-keywords-0
   vhdl-ext-font-lock-keywords-1
   vhdl-ext-font-lock-keywords-4 ; Empty by default
   vhdl-ext-font-lock-keywords-3
   vhdl-ext-font-lock-keywords-2
   vhdl-ext-font-lock-keywords-5))

;;;; Setup
(defun vhdl-ext-font-lock-setup ()
  "Setup syntax highlighting of VHDL buffers.
Add `vhdl-ext-mode' font lock keywords before running
`vhdl-mode' in order to populate `font-lock-keywords-alist'
before `font-lock' is loaded."
  (font-lock-add-keywords 'vhdl-mode vhdl-ext-font-lock-keywords 'set))


;;; Flycheck
;;;; GHDL
(defcustom vhdl-ext-flycheck-extra-include nil
  "Extra includes for GHDL flycheck."
  :type '(repeat (directory))
  :group 'vhdl-ext)

;; Overriding of `vhdl-ghdl' syntax checker to add more options
(flycheck-def-option-var vhdl-ext-flycheck-ghdl-include-path nil vhdl-ghdl
  "A list of include directories for GHDL.

List of strings where each is a directory to be added to the include path of
GHDL."
  :type '(repeat (directory :tag "Include directory"))
  :safe #'flycheck-string-list-p
  :package-version '(flycheck . "32"))

(flycheck-def-option-var vhdl-ext-flycheck-ghdl-work-lib vhdl-default-library vhdl-ghdl
  "Work library name to be used for GHDL."
  :type '(choice (const :tag "Default library" vhdl-default-library)
                 (string :tag "Custom work library"))
  :safe #'stringp
  :package-version '(flycheck . "32"))

(flycheck-def-args-var vhdl-ext-flycheck-ghdl-extra-args vhdl-ghdl
  :package-version '(flycheck . "32"))

(flycheck-define-checker vhdl-ghdl
  "A VHDL syntax checker using GHDL.
See URL `https://github.com/ghdl/ghdl'."
  :command ("ghdl"
            "-s" ; only do the syntax checking
            (option "--std=" flycheck-ghdl-language-standard concat)
            (option "--workdir=" flycheck-ghdl-workdir concat)
            (option "--ieee=" flycheck-ghdl-ieee-library concat)
            ;; Additional options
            (option-list "-P" vhdl-ext-flycheck-ghdl-include-path concat)
            (option "--work=" vhdl-ext-flycheck-ghdl-work-lib concat)
            ;; Extra args
            (eval vhdl-ext-flycheck-ghdl-extra-args)
            source)
  :error-patterns
  ((info    line-start (file-name) ":" line ":" column ":note: "    (message) line-end)
   (warning line-start (file-name) ":" line ":" column ":warning: " (message) line-end)
   (error   line-start (file-name) ":" line ":" column ": "         (message) line-end))
  :modes (vhdl-mode vhdl-ts-mode))


;;;; vhdl_lang
(flycheck-def-config-file-var flycheck-vhdl-lang-config-file vhdl-lang "vhdl_lang.toml")

(flycheck-define-checker vhdl-lang
  "Rust_hdl VHDL Language Frontend.

See URL `https://github.com/VHDL-LS/rust_hdl'."
  :command ("vhdl_lang"
            (config-file "--config" flycheck-vhdl-lang-config-file))
  :standard-input t
  :error-patterns
  ((info    line-start "hint: "    (message) "\n" "   --> " (file-name) ":" line line-end)
   (warning line-start "warning: " (message) "\n" "   --> " (file-name) ":" line line-end)
   (error   line-start "error: "   (message) "\n" "   --> " (file-name) ":" line line-end))
  :modes (vhdl-mode vhdl-ts-mode))


;;;; vhdl-tool
;; https://git.vhdltool.com/vhdl-tool/configs/src/master/emacs
;; INFO: Requires running following command in the background:
;;  $ vhdl-tool server
(flycheck-define-checker vhdl-tool
  "A VHDL syntax checker, type checker and linter using VHDL-Tool.

See URL `http://vhdltool.com'."
  :command ("vhdl-tool" "client" "lint" "--compact" "--stdin" "-f" source)
  :standard-input t
  :error-patterns
  ((warning line-start (file-name) ":" line ":" column ":w:" (message) line-end)
   (error   line-start (file-name) ":" line ":" column ":e:" (message) line-end))
  :modes (vhdl-mode vhdl-ts-mode))

;;; LSP
;; Support for various VHDL language servers (already supported by `lsp-mode', adds support for `eglot'):
;;     - rust_hdl: https://github.com/VHDL-LS/rust_hdl.git
;;     - ghdl_language_server: https://github.com/ghdl/ghdl-language-server.git
;;     - vhdl-tool: http://vhdltool.com
;;     - hdl_checker: https://github.com/suoto/hdl_checker
(defcustom vhdl-ext-lsp-available-servers
  '((ve-hdl-checker . ("hdl_checker" "--lsp"))
    (ve-rust-hdl    . "vhdl_ls")
    (ve-ghdl-ls     . "ghdl-ls")
    (ve-vhdl-tool   . ("vhdl-tool" "lsp")))
  "Vhdl-ext available LSP servers."
  :type '(alist :key-type (symbol)
                :value-type (string))
  :group 'vhdl-ext)

(defconst vhdl-ext-lsp-server-ids
  (mapcar #'car vhdl-ext-lsp-available-servers))

;;;; lsp-mode
(defvar vhdl-ext-lsp-mode-default-server 've-rust-hdl)

(defun vhdl-ext-lsp-setup ()
  "Configure VHDL for `lsp-mode'.
Register clients."
  (interactive)
  (let (server-id server-bin)
    ;; Add `vhdl-ts-mode' to the list of existing lsp ids
    (unless (alist-get 'vhdl-ts-mode lsp-language-id-configuration)
      (push (cons 'vhdl-ts-mode "vhdl") lsp-language-id-configuration))
    ;; Register clients
    (dolist (server vhdl-ext-lsp-available-servers)
      (setq server-id (car server))
      (setq server-bin (cdr server))
      (setq lsp-vhdl-server server-id)
      (lsp-register-client
       (make-lsp-client :new-connection (lsp-stdio-connection server-bin)
                        :major-modes '(vhdl-mode vhdl-ts-mode)
                        :server-id server-id))
      (message "Registered lsp-client: %s" server-id))))

(defun vhdl-ext-lsp-set-server (server-id)
  "Set language server defined by SERVER-ID.
Disable the rest to avoid handling priorities.
Override any previous configuration for `vhdl-mode' and `vhdl-ts-mode'."
  (interactive (list (intern (completing-read "Server-id: " vhdl-ext-lsp-server-ids nil t))))
  (let ((cmd (cdr (assoc server-id vhdl-ext-lsp-available-servers))))
    (if (not (executable-find (if (listp cmd)
                                  (car cmd)
                                cmd)))
        (message "%s not in $PATH, skipping config..." server-id)
      ;; Else configure available server
      (dolist (mode '(vhdl-mode vhdl-ts-mode))
        (setq lsp-disabled-clients (assq-delete-all mode lsp-disabled-clients))
        (push (cons mode (remove server-id vhdl-ext-lsp-server-ids)) lsp-disabled-clients))
      (message "[VHDL LSP]: %s" server-id))))


;;;; eglot
(defvar vhdl-ext-eglot-default-server 've-rust-hdl)

(defun vhdl-ext-eglot-set-server (server-id)
  "Configure VHDL for `eglot' for selected SERVER-ID.
Override any previous configuration for `vhdl-mode' and `vhdl-ts-mode'."
  (interactive (list (intern (completing-read "Server-id: " vhdl-ext-lsp-server-ids nil t))))
  (let ((cmd (alist-get server-id vhdl-ext-lsp-available-servers)))
    (unless cmd
      (error "%s not recognized as a supported server" server-id))
    (if (not (executable-find (if (listp cmd)
                                  (car cmd)
                                cmd)))
        (message "%s not in $PATH, skipping config..." server-id)
      ;; Else configure available server
      (dolist (mode '(vhdl-mode vhdl-ts-mode))
        (setq eglot-server-programs (assq-delete-all mode eglot-server-programs))
        (if (listp cmd)
            (push (append (list mode) cmd) eglot-server-programs)
          (push (list mode cmd) eglot-server-programs)))
      (message "Set eglot VHDL server: %s" server-id))))


;;; Major-mode
(defvar vhdl-ext-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-M-u") 'vhdl-ext-find-entity-instance-bwd)
    (define-key map (kbd "C-M-d") 'vhdl-ext-find-entity-instance-fwd)
    (define-key map (kbd "C-M-.") 'vhdl-ext-jump-to-parent-entity)
    (define-key map (kbd "C-c M-.") 'vhdl-ext-jump-to-entity-at-point-def)
    (define-key map (kbd "C-c M-?") 'vhdl-ext-jump-to-entity-at-point-ref)
    (define-key map (kbd "C-c C-t") 'vhdl-ext-hydra/body)
    map)
  "Key map for the `vhdl-ext'.")


;;;###autoload
(defun vhdl-ext-mode-setup ()
  "Setup `vhdl-ext-mode' depending on enabled features."
  (interactive)
  ;; Jump to parent module ag/ripgrep hooks
  (add-hook 'ag-search-finished-hook #'vhdl-ext-navigation-ag-rg-hook)
  (add-hook 'ripgrep-search-finished-hook #'vhdl-ext-navigation-ag-rg-hook)
  ;; Font lock
  (vhdl-ext-font-lock-setup)
  ;; Lsp
  (vhdl-ext-lsp-setup)
  (vhdl-ext-lsp-set-server vhdl-ext-lsp-mode-default-server)
  (vhdl-ext-eglot-set-server vhdl-ext-eglot-default-server))

;;;###autoload
(define-minor-mode vhdl-ext-mode
  "Minor mode for editing VHDL files.

\\{vhdl-ext-mode-map}"
  :lighter " vX"
  :global nil
  (if vhdl-ext-mode
      (progn
        (vhdl-ext-update-buffer-and-dir-list)
        (setq flycheck-ghdl-language-standard (vhdl-ext-get-standard))
        (setq flycheck-ghdl-workdir (vhdl-ext-workdir))
        (setq vhdl-ext-flycheck-ghdl-include-path (append vhdl-ext-flycheck-extra-include vhdl-ext-dir-list))
        (setq vhdl-ext-flycheck-ghdl-work-lib (vhdl-work-library))
        (add-hook 'kill-buffer-hook #'vhdl-ext-kill-buffer-hook nil :local)
        ;; `vhdl-mode'-only customization (exclude `vhdl-ts-mode')
        (when (eq major-mode 'vhdl-mode)
          ;; Imenu
          (advice-add 'vhdl-index-menu-init :override #'vhdl-ext-index-menu-init)
          ;; Font-lock
          ;;   It's not possible to add font-lock keywords to minor-modes.
          ;;   The workaround consists in add/remove keywords to the major mode when
          ;;   the minor mode is loaded/unloaded.
          ;;   https://emacs.stackexchange.com/questions/60198/font-lock-add-keywords-is-not-working
          (font-lock-flush)
          (setq-local font-lock-multiline nil)))
    ;; Cleanup
    (remove-hook 'kill-buffer-hook #'vhdl-ext-kill-buffer-hook :local)
    (advice-remove 'vhdl-index-menu-init #'vhdl-ext-index-menu-init)))


;;; Provide
(provide 'vhdl-ext)

;;; vhdl-ext.el ends here

;; Silence Hydra byte-compiler docstring warnings
;;
;; Local Variables:
;; byte-compile-warnings: (not docstrings)
;; End:
