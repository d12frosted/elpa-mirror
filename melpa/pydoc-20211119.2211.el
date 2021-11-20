;;; pydoc.el --- functional, syntax highlighted pydoc navigation

;; Copyright (C) 2015 John Kitchin

;; Author: John Kitchin <jkitchin@andrew.cmu.edu>
;; Maintainer: Brian J. Lopes <statmobile@gmail.com>
;; Contributions from Kyle Meyer
;; Created: 8 Mar 2015
;; Version: 0.2
;; Package-Version: 20211119.2211
;; Package-Commit: 3aaffe41e1c5a9d53fbc1de02686c386fd002890
;; Keywords: pydoc, python
;; Homepage: https://github.com/statmobile/pydoc

;;; Commentary:

;; This module runs pydoc on an argument, inserts the output into a help buffer,
;; and then linkifies and colorizes the buffer. For example, some things are
;; linked to open the source code, or to run pydoc on them. Some things are
;; colorized for readability, e.g. environment variables and strings, function
;; names and arguments.
;;
;; https://github.com/statmobile/pydoc
;;
;; pydoc.el provides the following functions.
;; `pydoc' Run this anywhere, and enter the module/class/function you want documentation for
;; `pydoc-at-point' Run this in a Python script to see what doc jedi can find for the point
;; `pydoc-browse' Launches a web browser with documentation.
;; `pydoc-browse-kill' kills the pydoc web server.
;;
;; `pydoc' renders some Sphinx markup as links. Images are shown as overlays.
;;  Most org-links should be active.
;;
;; LaTeX fragments are shown with org-rendered overlays. ;; Note you need to
;; escape some things in the python docstrings, e.g. \\f, \\b, \\\\, \\r, \\n or
;; they will not render correctly.

;;; Changelog:
;;
;; Updated license and headers for release.
;; March 2016: Major rewrite by Kyle Meyer to use help-buffers

;;; Code:

(require 'cl-lib)
(require 'goto-addr)
(require 'help-mode)
;; we use org-mode for python fontification
(require 'org)


;;* Options

(defgroup pydoc nil
  "Help buffer for pydoc."
  :prefix "pydoc"
  :group 'external
  :group 'help)


(defcustom pydoc-command "python -m pydoc"
  "The command to use to run pydoc."
  :type 'string
  :group 'pydoc)


(defcustom pydoc-make-method-buttons t
  "If non-nil, create buttons for methods."
  :type 'boolean
  :group 'pydoc)


(defcustom pydoc-after-finish-hook nil
  "Hook run by after pydoc buffer is prepared."
  :type 'hook
  :group 'pydoc)


(defface pydoc-example-leader-face
  '((t (:inherit font-lock-doc-face)))
  "Face used to highlight code example leader (e.g., \">>>\").")


;;* Buttons
(defun pydoc-find-file-other-window (fname)
  "Open FNAME in other window.
FNAME may end in ::line-number, in which case it also goes to the
line."
  (if (not (string-match "::" fname))
      (find-file-other-window fname)
    (let ((fields (split-string fname "::")))
      (find-file-other-window (car fields))
      (goto-line (string-to-number (nth 1 fields))))))

(define-button-type 'pydoc-source
  :supertype 'help-xref
  ;; 'help-function 'find-file-other-window
  'help-function 'pydoc-find-file-other-window
  'help-echo (purecopy "mouse-2, RET: visit file"))


(define-button-type 'pydoc-source-search
  :supertype 'help-xref
  'help-function (lambda (file search)
                   (find-file-other-window file)
                   (goto-char (point-min))
                   (re-search-forward search nil t)
                   (beginning-of-line))
  'help-echo (purecopy "mouse-2, RET: view in source"))


(define-button-type 'pydoc-help
  :supertype 'help-xref
  'help-function (lambda (pkg) (pydoc pkg))
  'help-echo (purecopy "mouse-2, RET: view pydoc help"))


;;* Buffer information

(defconst pydoc-sections-re
  (rx line-start
      (group
       (one-or-more (any upper))
       (zero-or-more (and (any space) (one-or-more (any upper)))))
      line-end)
  "Regular expression matching top level pydoc sections.")


(defvar pydoc-file nil
  "File associated with the current pydoc buffer.
The help for modules and packages has a \"FILE\" section (unless
they are built-in module like `sys`).")
(put 'pydoc-file 'permanent-local t)
(make-variable-buffer-local 'pydoc-file)


(defvar pydoc-info nil
  "Plist with information about the current pydoc buffer.

Keys include

  type
    The type of object.  This will always be non-nil.  Possible values
    are

      py-package
      py-module

      py-function
      py-class

      py-topic-list   (from \"pydoc topics\")
      py-keyword-list (from \"pydoc keywords\")
      py-module-list  (from \"pydoc modules\")

      py-topic
      py-keyword

      not-found
      unknown

  name
    The name of the object for the current help buffer.  This will be
    nil for help on topics as well as topic, keyword, and modules
    lists.

  in
    The name object, if any, that conains the object display in the
    current help buffer.

  sections
    An alist of section names and positions (if the object has
    sections).")
(put 'pydoc-info'permanent-local t)
(make-variable-buffer-local 'pydoc-info)


(defun pydoc-set-info ()
  "Set up `pydoc-info'for the current pydoc buffer."
  (setq pydoc-info (pydoc-get-info))
  (setq pydoc-info
        (plist-put pydoc-info
                   :sections (pydoc-get-sections))))


(defun pydoc-get-info ()
  "Return help name and type for the current pydoc buffer.

Return a plist with the keywords :name, :type, and :in.  All
return values will have a :type property.

See `pydoc-info' for more details on the keys."
  (save-excursion
    (goto-char (point-min))
    (cond
     ((looking-at "Help on package \\(.+\\) in \\(.+\\):")
      (list :name (match-string-no-properties 1) :type 'py-package
            :in (match-string-no-properties 2)))
     ((looking-at "Help on package \\(.+\\):")
      (list :name (match-string-no-properties 1) :type 'py-package))
     ((looking-at "Help on \\(?:built-in \\)?module \\(.+\\) in \\(.+\\):")
      (list :name (match-string-no-properties 1) :type 'py-module
            :in (match-string-no-properties 2)))
     ((looking-at "Help on \\(?:built-in \\)?module \\(.+\\):")
      (list :name (match-string-no-properties 1) :type 'py-module))
     ((looking-at (concat "Help on \\(?:built-in \\)?function \\(.+\\)"
                          " in \\(?:module \\)?\\(.+\\):"))
      (list :name (match-string-no-properties 1) :type 'py-function
            :in (match-string-no-properties 2)))
     ((looking-at "Help on class \\(.+\\) in \\(.+\\):")
      (list :name (match-string-no-properties 1) :type 'py-class
            :in (match-string-no-properties 2)))
     ((looking-at "The \"\\(.+\\)\" statement")
      (list :name (match-string-no-properties 1) :type 'py-keyword))
     ((looking-at "no Python documentation found for")
      (list :type 'not-found))
     ((looking-at "\\w+.*\n\\*+")
      (list :type 'py-topic))
     ((looking-at (concat "\nHere is a list of available topics."
                          "  Enter any topic name to get more help.$"))
      (list :type 'py-topic-list :start (match-end 0)))
     ((looking-at (concat "\nHere is a list of the Python keywords."
                          "  Enter any keyword to get more help.$"))
      (list :type 'py-keyword-list :start (match-end 0)))
     ;; This should be the last branch before t because it doesn't
     ;; restore point back to the beginning of the buffer.
     ((re-search-forward
       "Please wait a moment while I gather a list of all available modules...$"
       nil t)
      ;; ^ This may not be at a predictable line due to import
      ;; messages, so search for it.
      (let ((start (point)))
        (re-search-forward "Enter any module name to get more help.")
        (list :type 'py-module-list :start start :end (match-beginning 0))))
     (t
      (list :type 'unknown)))))


(defun pydoc-get-sections ()
  "Return sections of the current pydoc buffer.
An alist of (section . position) cells is returned, where
\"section\" the lower case version of the section title."
  (save-excursion
    (goto-char (point-min))
    (let (case-fold-search
          sections name start next-start)
      (while (re-search-forward pydoc-sections-re nil t)
        (setq next-start (match-beginning 0))
        (when name
          (push (cons name (cons start (1- next-start)))
                sections))
        (setq name (downcase (match-string-no-properties 1))
              start next-start))
      (when name
        (push (cons name (cons start (point-max)))
              sections))
      sections)))


(defun pydoc-jump-to-section (section)
  "Jump to pydoc SECTION."
  (interactive
   (list (completing-read "Section: "
                          (mapcar #'car (plist-get pydoc-info :sections)))))
  (let ((start (pydoc--section-start section)))
    (when start
      (goto-char start))))


(defun pydoc--section-start (section)
  "Return start position for SECTION.
Value is obtained from buffer-local `pydoc-info'."
  (car (cdr (assoc section (plist-get pydoc-info :sections)))))


(defmacro pydoc--with-section (section regexp &rest body)
  "Within SECTION gerform REGEXP search.
Execute BODY for each sucessful search."
  (declare (indent 2))
  `(let* ((section-pos (cdr (assoc ,section (plist-get pydoc-info :sections))))
          (case-fold-search nil))
     (when section-pos
       (save-excursion
         (goto-char (car section-pos))
         (while (re-search-forward ,regexp (cdr section-pos) t)
           ,@body)))))


(defun pydoc-make-xrefs (&optional buffer)
  "This is the pydoc version of `help-make-xrefs'.
Optional argument BUFFER which is used if provided."
  (with-current-buffer (or buffer (current-buffer))
    (save-excursion
      (goto-char (point-min))
      (let ((old-modified (buffer-modified-p))
            (case-fold-search nil)
            (inhibit-read-only t))
        (cl-case (plist-get pydoc-info :type)
          ((not-found py-function py-class))
          ((py-topic py-keyword)
           (pydoc--buttonize-related-topics))
          ((py-keyword-list py-topic-list py-module-list)
           (goto-char (plist-get pydoc-info :start))
           (pydoc--buttonize-help-list (plist-get pydoc-info :end)))
          (py-module
           (pydoc--buttonize-file)
           (when pydoc-file
             (pydoc--buttonize-functions pydoc-file)
             (pydoc--buttonize-classes pydoc-file)
             (when pydoc-make-method-buttons
               (pydoc--buttonize-methods pydoc-file))
             (pydoc--buttonize-data pydoc-file)))
          (py-package
           (pydoc--buttonize-package-contents (plist-get pydoc-info :name))
           (pydoc--buttonize-file)
           (when pydoc-file
             (pydoc--buttonize-functions pydoc-file)
             (pydoc--buttonize-classes pydoc-file)
             (when pydoc-make-method-buttons
               (pydoc--buttonize-methods pydoc-file))
             (pydoc--buttonize-data pydoc-file)))
	  ;; When I use `pydoc-at-point' the type here is unknown.
	  (unknown
	   (pydoc--buttonize-file)
	   (pydoc--buttonize-other)))
        (pydoc--buttonize-urls)
        (pydoc--buttonize-sphinx)
        ;; Delete extraneous newlines at the end of the docstring
        (goto-char (point-max))
        (while (and (not (bobp)) (bolp))
          (delete-char -1))
        (insert "\n")
        (pydoc--insert-navigation-links)
        (set-buffer-modified-p old-modified)))))


;;** Buttonize functions
(defun pydoc--buttonize-help-list (&optional limit)
  "Buttonize the help list up to LIMIT."
  (save-excursion
    (while (re-search-forward "\\b\\w+\\b" limit t)
      (help-xref-button 0 'pydoc-help (match-string 0)))))


(defun pydoc--buttonize-related-topics ()
  "Buttonize related topics."
  (save-excursion
    (when (re-search-forward "^Related help topics: \\(\\w+\\)"
                             nil t)
      (help-xref-button 1 'pydoc-help (match-string 1))
      (let ((line-end (point-at-eol)))
        (while (re-search-forward ",\\s-*\\(\\w+\\)" line-end t)
          (help-xref-button 1 'pydoc-help (match-string 1)))))))


(defun pydoc--buttonize-other ()
  "Buttonize the OTHER section.
This section is unique to `pydoc-at-point' output."
  (save-excursion
    (goto-char (point-min))
    (when (re-search-forward "^OTHER MODULES IN THIS FILE" (point-max) t)
      (while (re-search-forward "    \\(.*\\)$" nil t)
	(help-xref-button 1 'pydoc-help (match-string 1))))))


(defun pydoc--insert-navigation-links ()
  "Insert navigation links.
Adapted from `help-make-xrefs'."
  (when (or help-xref-stack help-xref-forward-stack)
    (insert "\n"))
  ;; Make a back-reference in this buffer if appropriate.
  (when help-xref-stack
    (help-insert-xref-button help-back-label 'help-back
                             (current-buffer)))
  ;; Make a forward-reference in this buffer if appropriate.
  (when help-xref-forward-stack
    (when help-xref-stack
      (insert "\t"))
    (help-insert-xref-button help-forward-label 'help-forward
                             (current-buffer)))
  (when (or help-xref-stack help-xref-forward-stack)
    (insert "\n")))


(defun pydoc--buttonize-file ()
  "Buttonize the file section."
  (let ((file-pos (pydoc--section-start "file")))
    (when file-pos
      (save-excursion
        (goto-char file-pos)
        (looking-at "^FILE\n    \\(.+\\)$")
        (let ((file (match-string-no-properties 1)))
	  (setq pydoc-file file)
	  (help-xref-button 1 'pydoc-source pydoc-file))))))


(defun pydoc--buttonize-urls ()
  "Buttonize URLs."
  (save-excursion
    (while (re-search-forward goto-address-url-regexp nil t)
      (help-xref-button 0 'help-url (match-string 0)))))


(defun pydoc--buttonize-functions (file)
  "Buttonize functions for FILE."
  (pydoc--with-section "functions"
      "^\\s-+\\([_a-zA-z0-9]+\\)("
    (let* ((func (match-string 1))
           (search (format "def %s(" func)))
      (help-xref-button 1 'pydoc-source-search file search))))


(defun pydoc--buttonize-classes (file)
  "Buttonize classes for FILE."
  (pydoc--with-section "classes"
      "    class \\([_A-z0-9]+\\)\\(?:(\\(.*\\))\\)*"
    (let* ((class (match-string 1))
           (search (format "^class %s\\b" class))
           ;; TODO Sometimes this doesn't have full path.
           (superclass (match-string 2)))
      (help-xref-button 1 'pydoc-source-search file search)
      (when superclass
        (help-xref-button 2 'pydoc-help superclass)))))


(defun pydoc--buttonize-methods (file)
  "Buttonize methods in the class section for FILE."
  (pydoc--with-section "classes"
      "^     |  \\([a-zA-Z0-9_]*\\)(\\(.*\\))$"
    ;; TODO This is not specific for the class it is under.
    (let* ((meth (match-string 1))
           (search (format "def %s(" meth)))
      (help-xref-button 1 'pydoc-source-search file search))))


(defun pydoc--buttonize-data (file)
  "Buttonize python data for FILE."
  (pydoc--with-section "data"
      "^    \\([_A-Za-z0-9]+\\) ="
    (help-xref-button 1 'pydoc-source-search file (match-string 1))))


(defun pydoc--buttonize-sphinx ()
  "Buttonize Sphinx markup."
  (save-excursion
    ;; TODO Add method?
    (while (re-search-forward ":\\(class\\|func\\|mod\\):`~?\\([^`]*\\)`" nil t)
      (let ((name (match-string 2)))
        (help-xref-button 2 'pydoc-help name)))))


(defun pydoc--buttonize-package-contents (pkg-name)
  "Buttonize package contents for PKG-NAME."
  (pydoc--with-section "package contents"
      "^    \\([a-zA-Z0-9_-]*\\)[ ]?\\((package)\\)?$"
    (let ((package (concat pkg-name "." (match-string 1))))
      (help-xref-button 1 'pydoc-help package))))


;;* Python information
(defun pydoc-builtin-modules ()
  "Return list of built in python modules."
  (mapcar
   'symbol-name
   (read (shell-command-to-string "python -c \"import sys; print('({})'.format(' '.join(['\"{}\"'.format(x) for x in sys.builtin_module_names])))\""))))


(defun pydoc-pip-version ()
  "Return a list of (major minor revision) for the pip version."
  (let* ((output (shell-command-to-string "pip --version"))
	 (string-version (nth 1 (split-string output " " t)))
	 (string-major-minor-rev (split-string string-version "\\.")))
    (mapcar
     'string-to-number
     string-major-minor-rev)))


(defun pydoc-user-modules ()
  "Return a list of strings for user-installed modules."
  (mapcar
   'symbol-name
   (read
    (shell-command-to-string
     ;; Use either importlib_metadata (a backport of importlib.metadata) or
     ;; importlib.metadata itself if it is available.
     (concat python-shell-interpreter " -c \"implib_meta_backport = None\nimplib_meta_python = None\ntry: import importlib_metadata;implib_meta_backport = importlib_metadata\nexcept: pass\ntry: import importlib.metadata;implib_meta_python = importlib.metadata\nexcept: pass\nimplib_meta = implib_meta_python or implib_meta_backport\nmods = sorted(map(lambda x: x.metadata['name'], implib_meta.distributions())); print('({})'.format(' '.join(['\"{}\"'.format(x) for x in mods])))  \"")
     ;; For older versions of Python.
     ;; (concat python-shell-interpreter " -c \"import pip; mods = sorted([i.key for i in pip.get_installed_distributions()]); print('({})'.format(' '.join(['\"{}\"'.format(x) for x in mods])))  \"")
     ))))


(defun pydoc-pkg-modules ()
  "Return list of built in python modules."
  (mapcar
   'symbol-name
   (read (shell-command-to-string "python -c \"import pkgutil; print('({})'.format(' '.join(['\"{}\"'.format(x[1]) for x in pkgutil.iter_modules()])))\""))))


(defun pydoc-topics ()
  "List of topics from the shell command `pydoc topics`."
  (apply
   'append
   (mapcar (lambda (x) (split-string x " " t " "))
	   (cdr (split-string  (shell-command-to-string "python -m pydoc topics") "\n" t " ")))))


(defun pydoc-keywords ()
  "List of topics from the shell command `pydoc keywords`."
  (apply
   'append
   (mapcar (lambda (x) (split-string x " " t " "))
	   (cdr (split-string  (shell-command-to-string "python -m pydoc keywords") "\n" t " ")))))


(defvar *pydoc-all-modules*
  nil
  "Cached value of all modules.")


(defun pydoc-all-modules (&optional reload)
  "Alphabetically sorted list of all modules.
Value is cached to speed up subsequent calls.
Optional RELOAD rereads the cache."
  (if (and (not reload) *pydoc-all-modules*)
      *pydoc-all-modules*
    (setq *pydoc-all-modules*
	  (delete-dups
	   (sort
	    (append
	     (pydoc-topics)
	     (pydoc-keywords)
	     (pydoc-builtin-modules)
	     (pydoc-user-modules)
	     (pydoc-pkg-modules))
	    'string<)))))


;;* Fontification functions
;;** Fontifying code
(defconst pydoc-example-code-leader-re
  (rx line-start
      (zero-or-one " |")                ; Within a class
      (zero-or-more space)
      (group (or ">>>" "..."
                 (and "In [" (one-or-more digit) "]:")))
      " "
      (group (one-or-more not-newline))
      line-end)
  "Regular expression matching leader for Python code snippet.
This will be use to highlight line with Python syntax
highlightling.")


(defun pydoc-fontify-inline-code (limit)
  "Fontify example blocks up to LIMIT.
These are lines marked by `pydoc-example-code-leader-re'."
  (when (re-search-forward pydoc-example-code-leader-re limit t)
    (set-text-properties (match-beginning 1) (match-end 1)
                         '(font-lock-face pydoc-example-leader-face))
    (org-src-font-lock-fontify-block
     "python" (match-beginning 2) (match-end 2))
    t))


;;** Overlay images on LaTeX fragments.
;; Note you need to escape some things in the
;; python docstrings, e.g. \\f, \\b, \\\\, \\r, \\n

(defun pydoc-latex-overlays-1 (limit)
  "Overlay images on \(eqn\) up to LIMIT."
  (while (re-search-forward "\\\\([^ ]*?\\\\)" limit t)
    (save-restriction
      (save-excursion
	(narrow-to-region (match-beginning 0) (match-end 0))
	(goto-char (point-min))
	(org-format-latex
	 (concat temporary-file-directory org-latex-preview-ltxpng-directory "pydoc")
	 default-directory 'overlays "" '()  'forbuffer
	 org-latex-create-formula-image-program)))))


(defun pydoc-latex-overlays-2 (limit)
  "Overlay images on \[eqn\] up to LIMIT."
  (while (re-search-forward "\\\\\\[[^ ]*?\\\\\\]" limit t)
    (save-restriction
      (save-excursion
	(narrow-to-region (match-beginning 0) (match-end 0))
	(goto-char (point-min))
	(org-format-latex
	 (concat temporary-file-directory org-latex-preview-ltxpng-directory "pydoc")
	 default-directory 'overlays "" '()  'forbuffer
	 org-latex-create-formula-image-program)))))


(defun pydoc-latex-overlays-3 (limit)
  "Overlay images on $$eqn$$ up to LIMIT."
  (while (re-search-forward "\\$\\$[^ ]*?\\$\\$" limit t)
    (save-restriction
      (save-excursion
	(narrow-to-region (match-beginning 0) (match-end 0))
	(goto-char (point-min))
	(org-format-latex
	 (concat temporary-file-directory org-latex-preview-ltxpng-directory "pydoc")
	 default-directory 'overlays "" '()  'forbuffer
	 org-latex-create-formula-image-program)))))


(defun pydoc-latex-overlays-4 (limit)
  "Overlay images on $eqn$ up to LIMIT.
this is less robust than useing \(\)"
  (while (re-search-forward "\\([^$]\\|^\\)\\(\\(\\$\\([^	\n,;.$][^$\n]*?\\(\n[^$\n]*?\\)\\{0,2\\}[^	\n,.$]\\)\\$\\)\\)\\([-	.,?;:'\") ]\\|$\\)" limit t)
    (save-restriction
      (save-excursion
	(narrow-to-region (match-beginning 0) (match-end 0))
	(goto-char (point-min))
	(org-format-latex
	 (concat temporary-file-directory org-latex-preview-ltxpng-directory "pydoc")
	 default-directory 'overlays "" '()  'forbuffer
	 org-latex-create-formula-image-program)))))


(defun pydoc-latex-overlays-5 (limit)
  "Overlay images on latex math environments up to LIMIT."
  (while (re-search-forward
	  "^[ \\t]*\\(\\\\begin{\\([a-zA-Z0-9\\*]+\\)[^\\000]+?\\\\end{\\2}\\)"
	  limit t)
    (save-restriction
      (save-excursion
	(narrow-to-region (match-beginning 1) (match-end 1))
	(goto-char (point-min))
	(org-format-latex
	 (concat temporary-file-directory org-latex-preview-ltxpng-directory "pydoc")
	 default-directory 'overlays "" '()  'forbuffer
	 org-latex-create-formula-image-program)))))

;;** font-lock keywords
(defvar pydoc-font-lock-keywords
  `((pydoc-fontify-inline-code)
    (org-activate-plain-links)
    (org-activate-bracket-links)
    (org-do-emphasis-faces)
    (,pydoc-sections-re 0 'bold)
    ("\\$[A-z0-9_]+" 0 font-lock-builtin-face)
    ("``.+?``" 0 font-lock-builtin-face)
    ("`.+?`" 0 font-lock-builtin-face)
    ("\".+?\"" 0 font-lock-string-face)
    ("'.+?'" 0 font-lock-string-face)
    (,(regexp-opt (list "True" "False" "None") 'words)
     1 font-lock-constant-face))
  "Font-lock keywords for pydoc.")


;;* pydoc buffer setup
(defmacro pydoc-with-help-window (buffer-name &rest body)
  "Display buffer named BUFFER-NAME in a pydoc help window.
Execute BODY in the buffer. This is the same as
`with-help-window', except `pydoc-mode-setup' and
`pydoc-mode-finish' are used instead of `help-mode-setup' and
`help-mode-finish'."
  (declare (indent 1) (debug t))
  `(progn
     ;; Make `help-window-point-marker' point nowhere.  The only place
     ;; where this should be set to a buffer position is within BODY.
     (set-marker help-window-point-marker nil)
     (let ((temp-buffer-window-setup-hook
            (cons 'pydoc-mode-setup temp-buffer-window-setup-hook))
           (temp-buffer-window-show-hook
            (cons 'pydoc-mode-finish temp-buffer-window-show-hook)))
       (with-temp-buffer-window
        ,buffer-name nil 'help-window-setup (progn ,@body)))))


(defun pydoc-buffer ()
  "Like `help-buffer', but for pydoc help buffers."
  (buffer-name
   (if (not help-xref-following)
       (get-buffer-create "*pydoc*")
     (unless (derived-mode-p 'help-mode)
       (error "Current buffer is not in Pydoc mode"))
     (current-buffer))))


(defun pydoc-setup-xref (item interactive-p)
  "Like `help-setup-xref', but for pydoc help buffers.
See `help-setup-xref' for ITEM and INTERACTIVE-P documentation."
  (with-current-buffer (pydoc-buffer)
    (when help-xref-stack-item
      (push (cons (point) help-xref-stack-item) help-xref-stack)
      (setq help-xref-forward-stack nil))
    (when interactive-p
      (let ((tail (nthcdr 10 help-xref-stack)))
        ;; Truncate the stack.
        (if tail (setcdr tail nil))))
    (setq help-xref-stack-item item)))

;;* The main major mode definition
(defvar pydoc-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map "n" 'next-line)
    (define-key map "N" 'forward-page)
    (define-key map "p" 'previous-line)
    (define-key map "P" 'backward-page)
    (define-key map "f" 'forward-char)
    (define-key map "b" 'backward-char)
    (define-key map "F" 'forward-word)
    (define-key map "B" 'backward-word)
    (define-key map "o" 'occur)
    (define-key map "s" 'isearch-forward)
    (define-key map "j" 'pydoc-jump-to-section)
    (define-key map "," (lambda () (interactive) (help-xref-go-back (current-buffer))))
    (define-key map "." (lambda () (interactive) (help-xref-go-forward (current-buffer))))
    map)
  "Keymap for Pydoc mode.")


;;;###autoload
(define-derived-mode pydoc-mode help-mode "Pydoc"
  "Major mode for viewing pydoc output.
Commands:
\\{pydoc-mode-map}"
  (set (make-local-variable 'font-lock-defaults)
       '((pydoc-font-lock-keywords) t nil))
  :keymap pydoc-mode-map)


(defun pydoc-mode-setup ()
  "Used in place of `help-mode-setup' in `pydoc-with-help-window'."
  (pydoc-mode)
  (setq buffer-read-only nil))


(defun pydoc-mode-finish ()
  "Used in place of `help-mode-finish' in `pydoc-with-help-window'."
  (when (derived-mode-p 'pydoc-mode)
    (pydoc-set-info)
    (pydoc-make-xrefs (current-buffer))
    (setq buffer-read-only nil)
    ;; When the following functions are in font-lock, emacs tends to crash. So I
    ;; put it here.
    (save-excursion
      (dolist (f '( ;; pydoc-image-overlays
		   pydoc-latex-overlays-1
		   pydoc-latex-overlays-2
		   pydoc-latex-overlays-3
		   pydoc-latex-overlays-4
		   pydoc-latex-overlays-5
		   org-display-inline-images))
	(goto-char (point-min))
	(funcall f nil)))
    (setq buffer-read-only t)
    (run-hooks 'pydoc-after-finish-hook)))

;;* The pydoc functions
;;;###autoload
(defun pydoc (name)
  "Display pydoc information for NAME in `pydoc-buffer'.
Completion is provided with candidates from `pydoc-all-modules'.
This is cached for speed. Use a prefix arg to refresh it."
  (interactive
   (list (completing-read
	  "Name of function or module: "
	  (pydoc-all-modules current-prefix-arg))))
  (pydoc-setup-xref (list #'pydoc name)
		    (called-interactively-p 'interactive))
  (pydoc-with-help-window (pydoc-buffer)
    (call-process-shell-command (concat pydoc-command " " name)
				nil standard-output)))

;;* The pydoc functions
;;;###autoload
(defun pydoc-at-point-no-jedi (&optional prompt)
  "Try to get help for thing at point without python-jedi.
With non-nil PROMPT or without a thing, prompt for the function or module."
  (interactive "P")
  (let ((name-of-symbol-at-point (if (symbol-at-point)
				     (symbol-name (symbol-at-point))
				   "")))
    (if (or prompt
	    (not (symbol-at-point)))
	(pydoc (completing-read
		"Name of function or module: "
		(pydoc-all-modules current-prefix-arg)
		nil nil
		name-of-symbol-at-point))
      (pydoc name-of-symbol-at-point))) )


;;;###autoload
(defun pydoc-at-point ()
  "Try to get help for thing at point.
Requires the python package jedi to be installed.

There is no way right now to get to the full module path. This is a known limitation in jedi."
  (interactive)
  (let* ((script (buffer-string))
	 (line (line-number-at-pos))
	 (column (current-column))
	 (tfile (make-temp-file "py-"))
	 (python-script
	  (format
	   "import jedi
s = jedi.Script(\"\"\"%s\"\"\", %s, %s, path=\"%s\")
gd = s.goto_definitions()

version = [int(x) for x in jedi.__version__.split('.')]

if len(gd) > 0:
    if version[1] == 11:
        script_modules = gd[0]._evaluator.modules
    else:
        script_modules = list(gd[0]._evaluator.module_cache.iterate_modules_with_names())

    if len(script_modules) > 0:
        if version[1] == 11:
            related = '\\n    '.join([smod for smod in script_modules if 'py-' not in smod])
        else:
            related = '\\n    '.join([smod[0] for smod in script_modules if 'py-' not in smod])
    else:
        related = None

    print('''Help on {0}:

NAME
    {3}

{4}

FILE
    {1}::{2}

OTHER MODULES IN THIS FILE
    {5}
'''.format(gd[0].full_name, gd[0].module_path, gd[0].line, gd[0].name, gd[0].docstring(), related))"
	   ;; I found I need to quote double quotes so they
	   ;; work in the script above.
	   (replace-regexp-in-string "\"" "\\\\\"" (replace-regexp-in-string "\\\\" "\\\\\\\\" script))
	   line
	   column
	   tfile)))

    (pydoc-setup-xref (list #'pydoc (thing-at-point 'word))
		      (called-interactively-p 'interactive))

    (pydoc-with-help-window (pydoc-buffer)
      (with-temp-file tfile
	(insert python-script))
      (call-process-shell-command (concat "python " tfile)
				  nil standard-output)
      (delete-file tfile))))


;;** pydoc browser
(defvar *pydoc-browser-process*
  nil
  "Process for the pydoc browser.")


(defvar *pydoc-browser-port*
  nil
  "Port the pydoc browser is on.")


;;;###autoload
(defun pydoc-browse ()
  "Open a browser to pydoc.
Attempts to find an open port, and to reuse the process."
  (interactive)
  (unless *pydoc-browser-process*
    ;; find an open port
    (if (executable-find "lsof")
	(cl-loop for port from 1025
	      if (string= "" (shell-command-to-string (format "lsof -i :%s" port)))
	      return (setq *pydoc-browser-port* (number-to-string port)))
      ;; Windows may not have an lsof command.
      (setq *pydoc-browser-port* "1234"))

    (setq *pydoc-browser-process*
          (apply
           #'start-process
           "pydoc-browser"
           "*pydoc-browser*"
           (append (split-string pydoc-command) `("-p" ,*pydoc-browser-port*)))))
  (browse-url (format "http://localhost:%s" *pydoc-browser-port*)))

;;;###autoload
(defun pydoc-browse-kill ()
  "Kill the pydoc browser."
  (when *pydoc-browser-process*
    (kill-process *pydoc-browser-process*)
    (setq *pydoc-browser-process* nil
	  *pydoc-browser-port* nil)))


(provide 'pydoc)

;;; pydoc.el ends here
