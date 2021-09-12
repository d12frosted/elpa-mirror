;;; multi-project.el --- Find files, compile, and search for multiple projects.

;; Copyright (C) 2010 - 2021

;; Author: Shawn Ellis <shawn.ellis17@gmail.com>
;; Version: 0.0.38
;; Package-Version: 20210908.1233
;; Package-Commit: e213d1f64e173b437a2981afc5d85f90aa40a03e
;; Package-Requires: ((emacs "25"))
;; URL: https://hg.osdn.net/view/multi-project/multi-project
;; Keywords: convenience project management
;;

;; multi-project.el is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; multi-project.el is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;;
;; Multi-project simplifies working with different projects by providing support
;; for creating, deleting, and searching with projects.  Multi-project
;; supports interactively finding a file within a project by using a TAGS file.

;;
;; To use multi-project add the following lines within your .emacs file:
;;
;; (require 'multi-project)
;; (multi-project-mode)
;;
;; The multi-project bindings below are for switching to a project, finding
;; files within a project, compilation, or grepping a project.
;;
;; C-xpa - Anchor a project          Remember the current project
;; C-xpc - Project compile           Run the compilation command for a project
;; C-xpj - Project jump              Displays a list of projects
;;                                   multi-project-anchored
;; C-xpg - Run grep-find             Runs grep-find at project root
;; C-xpl - Last project or anchor    Jumps to the last project or anchor
;; C-xpp - Present project           Jumps to the current project root
;; C-xpP - Present project new frame Present project in a new frame
;; C-xpf - Find project files        Interactively find project files
;; C-xpn - Add a new project         Prompts for new project information
;; C-xpr - Go to project root        Visits the project root
;; C-xps - Project shell             Creates a project shell
;; C-xpu - Resets the anchor         Unsets the project anchor
;; C-xpv - Visit a project           Visits another project in a separate frame

;;
;; From the project selection buffer the following bindings are present:
;; a     - Anchor a project          Remembers the project to quickly return
;;                                   after visiting another project.
;; C-n   - Next project              Move the cursor to the next project
;; C-p   - Previous project          Move the cursor to the previous project
;; d     - Delete a project          Marks the project for deletion
;; g     - Grep a project            Executes grep-find in the selected projects
;; r     - Reset search              Resets the project search filter
;; s     - Search projects           Searches by name for a project
;; N     - Add new project           Prompts for project information
;; q     - Quit
;; u     - Unmark a project          Removes the mark for a project
;; x     - Executes actions          Executes the selected operations

;;
;; The multi-project-compilation-command variable can be set to a function
;; that provides a customized compilation command.  For example,
;;
;; (defun my-compilation-command (project-list)
;;   (let ((project-name (car project-list))
;;	   (project-dir (nth 1 project-list))
;;	   (project-subdir (nth 2 project-list)))
;;
;;     (cond ((string-match "proj1" project-name)
;;	      (concat "ant -f " project-dir "/" project-subdir "/build.xml"))
;;	     (t
;;	      (concat "make -C " project-dir "/" project-subdir)))))
;;
;; (setq multi-project-compilation-command 'my-compilation-command)

;;; Code:

(require 'compile)
(require 'etags)
(require 'easymenu)
(require 'grep)
(require 'tramp)
(require 'xref)

(defgroup multi-project nil
  "Support for working with multiple projects."
  :prefix "multi-project"
  :group 'convenience)

(defcustom multi-project-roots nil
  "A list describing the project, filesystem root, subdirectory under the root, and the TAGS location."
  :type 'sexp :group 'multi-project)

(defcustom multi-project-compilation-command 'multi-project-compile-command
  "The fuction to use when compiling a project."
  :type 'string :group 'multi-project)

(defcustom multi-project-grep-exclusions '(".git" ".hg" ".svn" "node_modules" "build" ".gradle" "target")
  "List of directories to ignore when running grep."
  :type 'string :group 'multi-project)

(defvar multi-project-dir (concat user-emacs-directory "multi-project")
  "Directory of the saved settings for multi-project.")

(defvar multi-project-file "mp"
  "File of the saved settings for multi-project.")

(defvar multi-project-last nil
  "Visits the last project that was switched to.")

(defvar multi-project-anchored nil
  "Visits the anchored project.")

(defvar multi-project-current-name nil
  "The current selected project name.")

(defvar multi-project-history '()
  "The history list of projects.")

(defvar multi-project-history-index 0
  "Index for the project history.")

(defvar multi-project-overlay nil
  "Overlay used to highlight the current selection.")

(defvar multi-project-previous-input nil
  "Prior input when performing a search.")

(defvar multi-project-previous-file-input nil
  "Prior input when performing a file search." )

(defconst multi-project-buffer "*mp*"
  "Buffer used for finding projects.")

(defface multi-project-selection-face
  ;; check if inherit attribute is supported
  (if (assq :inherit custom-face-attributes)
      '((t (:inherit highlight :underline nil)))

    '((((class color) (background light))
       (:background "darkseagreen2"))
      (((class color) (background dark))
       (:background "darkolivegreen"))
      (t (:inverse-video t))))
  "Face for highlighting the currently selected file name."
  :group 'multi-project)

(defvar multi-project-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-x pa") 'multi-project-anchor)
    (define-key map (kbd "C-x pi") 'multi-project-insert-path)
    (define-key map (kbd "C-x pu") 'multi-project-reset-anchor)
    (define-key map (kbd "C-x pl") 'multi-project-last)
    (define-key map (kbd "C-x pr") 'multi-project-root)
    (define-key map (kbd "C-x pj") 'multi-project-display-projects)
    (define-key map (kbd "C-x pc") 'multi-project-compile)
    (define-key map (kbd "C-x pv") 'multi-project-visit-project)
    (define-key map (kbd "C-x pf") 'multi-project-find-file)
    (define-key map (kbd "C-x pn") 'multi-project-add-project)
    (define-key map (kbd "C-x pp") 'multi-project-present-project)
    (define-key map (kbd "C-x pP") 'multi-project-present-project-new-frame)
    (define-key map (kbd "C-x pg") 'multi-project-interactive-grep)
    (define-key map (kbd "C-x ps") 'multi-project-shell)
    (define-key map (kbd "C-x pt") 'multi-project-recreate-tags)

    (easy-menu-define multi-project-mode-menu map "'multi-project-mode' menu"
      '("MP"
	["Jump to a project" multi-project-display-projects t]
	["Jump to the project root" multi-project-root t]
	["Jump to current project" multi-project-present-project t]
	["Jump to current project in new frame " multi-project-present-project-new-frame t]
	["Visit a project in new frame" multi-project-visit-project t]
	["Compile..." multi-project-compile t]
	["Find file..." multi-project-find-file t]
	["Grep project ..." multi-project-interactive-grep t]
	["Add project..." multi-project-add-project t]
	["Anchor project" multi-project-anchor t]
	["Reset anchor" multi-project-reset-anchor t]
	["Last project" multi-project-last t]))

    map)
  "Global keymap for multi-project.")

(defvar multi-project-map
  (let ((map (copy-keymap minibuffer-local-map)))
    (define-key map (kbd "<down>") 'multi-project-next-line)
    (define-key map (kbd "C-n") 'multi-project-next-line)
    (define-key map (kbd "M-n") 'multi-project-next-line)
    (define-key map (kbd "n") 'multi-project-next-line)
    (define-key map (kbd "<up>") 'multi-project-previous-line)
    (define-key map (kbd "C-p") 'multi-project-previous-line)
    (define-key map (kbd "M-p") 'multi-project-previous-line)
    (define-key map (kbd "p") 'multi-project-previous-line)
    (define-key map (kbd "<prior>") 'multi-project-previous-page)
    (define-key map (kbd "<RET>") 'multi-project-display-select)
    (define-key map (kbd "f") 'multi-project-display-select)
    (define-key map (kbd "a") 'multi-project-display-anchor)
    (define-key map (kbd "o") 'multi-project-display-select-other-window)
    (define-key map (kbd "<C-return>") 'multi-project-display-select-other-window)
    (define-key map (kbd "q") 'multi-project-quit)
    (define-key map (kbd "s") 'multi-project-display-search)
    (define-key map (kbd "r") 'multi-project-display-reset)
    (define-key map (kbd "d") 'multi-project-mark-deletions)
    (define-key map (kbd "g") 'multi-project-mark-grep)
    (define-key map (kbd "u") 'multi-project-unmark-project)
    (define-key map (kbd "x") 'multi-project-execute-actions)
    (define-key map (kbd "N") 'multi-project-new-project)
    (define-key map [mouse-2] 'multi-project-mouse-select)
    map)
  "Keymap for multi-project.")

(defvar multi-project-minibuffer-map
  (let ((map (copy-keymap minibuffer-local-map)))
    (define-key map (kbd "<RET>") 'multi-project-exit-minibuffer)
    (define-key map (kbd "<down>") 'multi-project-next-line)
    (define-key map (kbd "<up>") 'multi-project-previous-line)
    (define-key map (kbd "C-p") 'multi-project-previous-line)
    (define-key map (kbd "C-n") 'multi-project-next-line)
    map)
  "Keymap for multi-project-minibuffer.")

(defun multi-project-open (projectdir directory &optional location load-file otherwindow)
  "Open the project. The PROJECTDIR specifies the project
directory and the location argument is used to place the cursor
on a file or directory within PROJECTDIR. Optional argument
load-file will invoke `find-file`. A non-nil OTHERWINDOW argument
opens up a buffer in a different windows."
  (when projectdir

    (when location
      (setq directory location))

    (let ((filename (concat projectdir "/" directory)))

      (if load-file
	  (find-file filename)
	  (progn
	    (if otherwindow
		(dired-other-window projectdir)
	      (dired projectdir))

	    (goto-char (point-min))
	    (when (re-search-forward directory nil t)
              (goto-char (match-beginning 0))))))))


(defun multi-project-open-project (solutionlist &optional location otherwindow)
  "Open up a dired window based upon the project.
Argument SOLUTIONLIST Optional argument LOCATION Optional
argument OTHERWINDOW open another window."
  (let ((project-dir (nth 1 solutionlist))
	(project-cursor-on-file (nth 2 solutionlist))
	(project-load-file (nth 4 solutionlist)))

    (multi-project-open project-dir project-cursor-on-file location project-load-file  otherwindow)))

(defun multi-project-filter-name (project lst)
  "Filter based upon the the PROJECT name of the LST."
  (car
   (delq nil
	 (mapcar (lambda (x) (and (string= project (car x)) x)) lst))))

(defun multi-project-parent-file (file)
  "Return the parent of the FILE."
  (mapconcat 'identity (butlast (split-string file "/")) "/"))

(defun multi-project-compare-matches (dir lst)
  "Return the projects for DIR found in the working directories in LST."
  (let ((normalized-dir (abbreviate-file-name (directory-file-name dir))))
  (delq nil (mapcar (lambda (x) (if (string-equal normalized-dir
						  (nth 1 x))
				    x)) lst))))

(defun multi-project-filter-dir (dir lst)
  "Return the projects for DIR based upon the LST of working directories."
  (let (project)
    (when (> (length dir) 0)
      (setq project (multi-project-compare-matches dir lst))
      (if project
	  (car project)
	(multi-project-filter-dir (multi-project-parent-file dir) lst)))))

(defun multi-project-filter-empty-string (lst)
  "Filter out empty strings from LST."
  (delq nil
	(mapcar (lambda (x) (when (> (length x) 0) x)) lst)))

(defun multi-project-trim-string (lst)
  "Remove whitespace from the beginning and end of the string found within LST."
  (mapcar (lambda (x)
            (replace-regexp-in-string "\\`[ \t\n]*" "" (replace-regexp-in-string "[ \t\n]*\\'" "" x))) lst))


(defun multi-project-find-by-directory ()
  "Return the project from the set of defined projects in 'multi-projects-roots."
  (multi-project-filter-dir default-directory multi-project-roots))


(defun multi-project-find-by-name (projectname)
  "Returns the project list that corresponds to the project name"
  (multi-project-filter-name projectname multi-project-roots))

(defun multi-project-prompt ()
  "Prompts for the project to work with."
  (let (result
        solution
        prompt)
    (dolist (item (reverse multi-project-roots) prompt)
      (setq prompt (append (car item) " " prompt)))
    (setq solution (read-from-minibuffer (concat "Project: " prompt "? ") nil))
    (setq result (multi-project-find-by-name solution))
    result))

(defun multi-project-file-exists (project regexp)
  "Return true if the PROJECT constains a filename with a matching REGEXP."
  (directory-files (nth 1 project) nil regexp))

(defun multi-project-cmd (cmd)
  "Append .bat to CMD if executing under Windows."
  (if (eq system-type 'windows-nt)
      (concat cmd ".bat")
    cmd))

(defun multi-project-compile-command (project)
  "Provide a compilation command based upon the PROJECT."
  (cond ((multi-project-file-exists project "Makefile")
	 (concat "make -C " (nth 1 project) " "))

	((multi-project-file-exists project "build.gradle")
	 (concat (nth 1 project) "/" (multi-project-cmd "gradlew -b ")
		 (nth 1 project) "/build.gradle build"))

	((multi-project-file-exists project "pom.xml")
	 "mvn compile")

	((multi-project-file-exists project "build.xml")
	 (concat "ant -f " (nth 1 project) "/build.xml "))

	((multi-project-file-exists project ".lein.*")
	 "lein compile")

	((multi-project-file-exists project "node_modules")
	 "npm run build")

	((multi-project-file-exists project "Rakefile")
	 (concat "rake -f " (nth 1 project) "/Rakefile"))

	(t "make ")))

(defun multi-project-compile-prompt (command)
  "Read the compilation COMMAND from the minibuffer."
  (read-from-minibuffer "Compile command: "
                        command nil nil
                        (if (equal (car compile-history) command)
                            '(compile-history . 1)
                          'compile-history)))

(defun multi-project-compile-buffer-name (mode-name)
  "Return the compilation buffer name based upon the project and MODE-NAME."

  (let ((projectlist (multi-project-find-by-directory)))
    (cond (projectlist
	   (concat "*" (car projectlist) "-" (downcase mode-name) "*"))
	  (t
	   (concat "*" (downcase mode-name) "*")))))

;;;###autoload
(defun multi-project-compile ()
  "Compiles a project based upon the current directory of the buffer."
  (interactive)
  (let ((solutionlist (multi-project-find-by-directory)))
    (cond ((and solutionlist (boundp 'compile-history) compile-history
                (string-match (funcall multi-project-compilation-command solutionlist)
                              (car compile-history)))
           (setq compile-command (car compile-history)))

          (solutionlist
           (setq compile-command
                 (funcall multi-project-compilation-command solutionlist)))

          (t
           (setq solutionlist (multi-project-find-by-name multi-project-last))
           (when solutionlist
             (setq compile-command
                   (funcall multi-project-compilation-command solutionlist)))))

    ; Set the function for naming the compilation buffer
    (unless compilation-buffer-name-function
      (setq compilation-buffer-name-function 'multi-project-compile-buffer-name))
    (compile (multi-project-compile-prompt compile-command))))

(defun multi-project-find-root (parentDir childDir)
  "Return the project root based upon the PARENTDIR and CHILDDIR."
  (interactive)

  (let ((tlst (split-string childDir "[/\\]"))
        (lst (split-string parentDir "[/\\]"))
        (fpath)
        (tfpath)
        (index 0)
        (root))
    (while lst
      (setq fpath (car lst))
      (setq lst (cdr lst))
      (setq tfpath (nth index tlst))
      (setq index (1+ index))

      (if (string-equal fpath tfpath)
          (if root
              (setq root (append root (list fpath)))
            (setq root (list fpath)))))

    (if (nth index tlst)
        (setq root (append root (list (nth index tlst)))))
    (mapconcat 'identity root "/")))

(defun multi-project-basename (directory)
  "Return the basename of a DIRECTORY."
  (let ((lst (split-string directory "[/\\]")))
    (car (last lst))))

(defun multi-project-dir-as-file (directory)
  "Convert a DIRECTORY name that trails with a slash to a filename."
  (replace-regexp-in-string "/$" "" directory))

(defun multi-project-remote-file (filename)
  "Return the FILENAME if it is remote and nil if it is local."
  (if (and (fboundp 'file-remote-p)
	   (file-remote-p filename))
      filename
    ;; No 'file-remote-p so try to determine by filename
    (if (string-match "@?\\w+:" filename)
	filename)))

;;;###autoload
(defun multi-project-root ()
  "Jumps to the root of a project based upon current directory."
  (interactive)
  (let ((solutionlist (multi-project-find-by-directory)))
    (if solutionlist
        (let ((searchdir (multi-project-find-root (nth 1 solutionlist)
                                                  default-directory)))
          (multi-project-open (nth 1 solutionlist) (nth 2 solutionlist)
                              (multi-project-basename searchdir)))
      (multi-project-display-projects))))

(defun multi-project-dirname (filename)
  "Return the directory name of FILENAME."
  (let (filelist
        result)
    (setq filelist (reverse (split-string filename "/")))
    (mapc (lambda (x) (setq result (concat x "/" result)))
          (cdr filelist))
    (directory-file-name result)))

(defun multi-project-visit-tags (filename)
  "Visit the TAGS for FILENAME."
  (let ((tags-revert-without-query t))
    (visit-tags-table filename)))

;;;###autoload
(defun multi-project-change-tags (&optional project)
  "Visits tags file based upon current directory or optional
PROJECT argument."
  (interactive)
  (let (solutionlist)

    (if project
        (setq solutionlist (multi-project-find-by-name project))
      (setq solutionlist (multi-project-find-by-directory)))

    (when solutionlist
	(setq multi-project-current-name (car solutionlist))

        (let* ((filename (nth 3 solutionlist))
	       (filename-expanded (when filename
				    (expand-file-name filename)))
	       (tags-buffer (get-buffer "TAGS"))
	       (same-tags-file (string= (buffer-file-name tags-buffer) filename-expanded)))

	  (when (and tags-buffer (not same-tags-file))
	    (kill-buffer tags-buffer))

          (when (and filename
		     (not same-tags-file)
		     (file-exists-p filename-expanded))

            (let ((large-file-warning-threshold nil)
                  (tags-add-tables nil))
	      (multi-project-visit-tags filename)
	      (message "TAGS changed to %s" tags-file-name)))))))

;;;###autoload
(defun multi-project-last()
  "Jumps to the last chosen project."
  (interactive)
  (let (project result)
    (if multi-project-anchored
        (setq project multi-project-anchored)

      (when multi-project-history
	(setq multi-project-history-index (% (+ multi-project-history-index 1)
					     (length multi-project-history)))
	(setq project (nth multi-project-history-index multi-project-history))))

    (when project
      (setq multi-project-current-name project)

      (setq result (multi-project-find-by-name project))
      (when result
	(multi-project-change-tags project)
	(multi-project-open-project result)
	(message "Last project %s" project)))))

;;;###autoload
(defun multi-project-anchor()
  "Prevent the tracking of switching between projects and always
use the anchored project."
  (interactive)
  (setq multi-project-anchored (car (multi-project-find-by-directory)))
  (if multi-project-anchored
      (message "%s anchored" multi-project-anchored)))

;;;###autoload
(defun multi-project-reset-anchor()
  "Clears out the anchoring of a project."
  (interactive)
  (when multi-project-anchored
    (message "%s no longer anchored." multi-project-anchored)
    (setq multi-project-anchored nil)))

(defun multi-project-display-anchor()
  (interactive)
  (let ((project-list (multi-project-select)))
    (when project-list
      (setq multi-project-anchored (car project-list))
      (message "%s anchored" multi-project-anchored))))

;;;###autoload
(defun multi-project-display-change-tags()
  (interactive)
  (let ((project-list (multi-project-select)))
    (when project-list
      (multi-project-change-tags (car project-list))
      (message "Loaded tags for %s " (car project-list)))))

(defun multi-project-max-length(projects)
  "Return the max length of the project within PROJECTS."
  (if projects
      (apply 'max(mapcar (lambda (x) (length (car x))) projects))))

(defun multi-project-insert-line(key fs max-length)
  (let ((numspaces (- max-length (length key))))

    (insert (concat "  " key))
    (while (> numspaces 0)
      (insert " ")
      (setq numspaces (- numspaces 1)))
    (insert "\t")
    (insert fs)

    (insert " ")
    (add-text-properties (point-at-bol) (point-at-eol)
                         '(mouse-face highlight))
    (insert "\n")))

;;;###autoload
(defun multi-project-display-projects()
  "Displays a buffer with the projects"
  (interactive)
  (multi-project-create-display multi-project-previous-input)
  (switch-to-buffer multi-project-buffer))

(defun multi-project-display-reset()
  "Resets the filter used for the projects."
  (interactive)
  (setq multi-project-previous-input nil)
  (multi-project-display-projects))


(defun multi-project-create-display(&optional projectkey)
  "Inserts the configured projects into the multi-project buffer."
  (get-buffer-create multi-project-buffer)

  (with-current-buffer multi-project-buffer
    (multi-project-minor-mode 1)
    (setq buffer-read-only nil)

    ;; Borrowed from package.el.  Thanks!
    (setq header-line-format
	  (mapconcat
	   (lambda (pair)
	     (let ((column (car pair))
		   (name (cdr pair)))
	       (concat
		;; Insert a space that aligns the button properly.
		(propertize " " 'display (list 'space :align-to column)
			    'face 'fixed-pitch)
		;; Set up the column button.
		(if (string= name "Directory")
		    name
		  (propertize name
			      'column-name name
			      'help-echo "mouse-1: sort by column"
			      'mouse-face 'highlight
			      )))))
	   ;; We take a trick from buff-menu and have a dummy leading
	   ;; space to align the header line with the beginning of the
	   ;; text.  This doesn't really work properly on Emacs 21,
	   ;; but it is close enough.
	   '((0 . "")
	     (2 . "Project")
	     (30 . "Directory"))
	   ""))

    (setq multi-project-roots (sort multi-project-roots (lambda (a b) (string< (car a) (car b)))))
    (erase-buffer)
    (let ((max-length (multi-project-max-length multi-project-roots)))
      (dolist (item multi-project-roots)
	(if (and projectkey
		 (string-match projectkey (car item)))
	    (multi-project-insert-line (car item) (nth 1 item) max-length))

	(if (equal projectkey nil)
	    (multi-project-insert-line (car item) (nth 1 item) max-length))))
      (setq buffer-read-only t)

    (goto-char (point-min))

    (setq multi-project-overlay (make-overlay (point-min) (point-min)))
    (overlay-put multi-project-overlay 'face 'multi-project-selection-face)
    (multi-project-mark-line)))


(defun multi-project-mark-line ()
  "Mark the current line."
  (move-overlay multi-project-overlay (point-at-bol) (point-at-eol)))

(defun multi-project-move-selection (buf movefunc movearg)
  "Move the selection marker to a new position in BUF determined by MOVEFUNC and MOVEARG."
  (unless (= (buffer-size (get-buffer buf)) 0)
    (save-selected-window
      (select-window (get-buffer-window buf))

      (condition-case nil
          (funcall movefunc movearg)
        (beginning-of-buffer (goto-char (point-min)))
        (end-of-buffer (goto-char (point-max))))

      ;; if line end is point-max then it's either an incomplete line or
      ;; the end of the output, so move up a line
      (if (= (point-at-eol) (point-max))
          (forward-line -1))

      (multi-project-mark-line))))

(defun multi-project-previous-line ()
  "Move selection to the previous line."
  (interactive)
  (multi-project-move-selection multi-project-buffer 'next-line -1))

(defun multi-project-next-line ()
  "Move selection to the next line."
  (interactive)
  (multi-project-move-selection multi-project-buffer 'next-line 1))

(define-minor-mode multi-project-minor-mode
  "Minor mode for working with multiple projects."
  nil
  " MP-Proj"
  multi-project-map)

(defun multi-project-quit ()
  "Kill the MP buffer."
  (interactive)
  (quit-window))

(defun multi-project-switch (project-name &optional otherwindow)
  "Switch to the project based upon the PROJECT-NAME and optionally open OTHERWINDOW."
  (let ((project-list (multi-project-find-by-name project-name)))
    (setq multi-project-current-name (car project-list))
    (multi-project-change-tags (car project-list))
    (multi-project-open-project project-list nil otherwindow)

    (when (not (string-equal multi-project-current-name
			     (car multi-project-history)))
      (setq multi-project-history-index 0)
      (push multi-project-current-name multi-project-history))))


(defun multi-project-select ()
  "Select the project from the displayed list."
  (interactive)
  (let ((selectedline (buffer-substring-no-properties (point-at-bol)
						      (point-at-eol)))
        (solution)
        (project-list))
    (setq solution (multi-project-trim-string
                    (multi-project-filter-empty-string
                     (split-string selectedline "[\t]+"))))
    (setq project-list (multi-project-find-by-name (car solution)))
    project-list))

(defun multi-project-display-select (&optional otherwindow)
  "Select the project and visit the project's tree.
Optional argument OTHERWINDOW if true, the display is created in a secondary window.e."
  (interactive)
  (let ((project-list (multi-project-select)))
    (when project-list
      (if (not (string= multi-project-current-name multi-project-last))
          (setq multi-project-last multi-project-current-name))

      (multi-project-switch (car project-list) otherwindow))))

(defun multi-project-display-select-other-window ()
  "Select the project, but places it in another window."
  (interactive)
  (multi-project-display-select t))

(defun multi-project-check-input()
  "Check for input."
  (let ((input (minibuffer-contents)))
    (if (not (string-equal input multi-project-previous-input))
        (progn
          (multi-project-create-display input)
          (setq multi-project-previous-input input)))))

(defun multi-project-exit-minibuffer()
  "Exit from the minibuffer."
  (interactive)
  (exit-minibuffer))

(defun multi-project-display-search ()
  "Search the list of projects for keywords."
  (interactive)
  (add-hook 'post-command-hook 'multi-project-check-input)

  (unwind-protect
      (let ((minibuffer-local-map multi-project-minibuffer-map))
        (read-string "substring: "))
    (remove-hook 'post-command-hook 'multi-project-check-input))

  (with-current-buffer multi-project-buffer
    (multi-project-display-select)))


(defconst multi-project-file-buffer "*mp-find-file*"
  "Buffer used for finding files.")

(defun multi-project-tag-find-files (pattern)
  "Find a list of files based upon a regular expression PATTERN."
  (let (result)
    (save-excursion
      (let ((large-file-warning-threshold nil)
            (tags-add-tables nil))
        (when (and (get-buffer "TAGS") (visit-tags-table-buffer))
	  (unless tags-table-files (tags-table-files))

	  (dolist (file tags-table-files)
	    (when (and (string-match pattern (file-name-nondirectory file))
		       file)
	      (setq result (cons file result)))))))
    (sort result (lambda (a b) (string< a b)))))

(defun multi-project-gtag-find-files (pattern)
  "Find a list of files based upon a regular expression PATTERN."
  (let ((mp-gtags-buffer (get-buffer-create "*mp-gtags*")))
    (with-current-buffer mp-gtags-buffer
      (erase-buffer)
      (call-process "global" nil t nil "-Poe" pattern)
      (list (buffer-string)))))

(defun multi-project-find-files (pattern)
  "Find a list of files based upon a PATTERN."
  (let ((tags-type (multi-project-tags-type
		    (multi-project-find-by-name multi-project-current-name))))
    (cond ((string= tags-type 'TAGS)
	   (multi-project-tag-find-files pattern))
	  ((string= tags-type 'GTAGS)
	   (multi-project-gtag-find-files pattern))
	  (t
	   (multi-project-tag-find-files pattern)))))

(defun multi-project-tags-type (project)
  "Return TAGS or GTAGS based upon the PROJECT."
  (let ((project-dir (nth 1 project)))
    (cond ((and (>= (length project) 4) (file-exists-p (nth 3 project)))
	   'TAGS)
	  ((file-exists-p (concat project-dir "/" "GTAGS"))
	   'GTAGS)
	  ((file-exists-p (concat project-dir "/" "TAGS"))
	   'TAGS))))

(defvar multi-project-file-minibuffer-map
  (let ((map (copy-keymap minibuffer-local-map)))
    (define-key map (kbd "<down>") 'multi-project-file-next-line)
    (define-key map (kbd "C-n") 'multi-project-file-next-line)
    (define-key map (kbd "<up>") 'multi-project-file-previous-line)
    (define-key map (kbd "C-p") 'multi-project-file-previous-line)
    (define-key map (kbd "<RET>") 'multi-project-exit-minibuffer)
    map)
  "Keymap for `multi-project-file' mode.")

(defun multi-project-file-previous-line ()
  "Move selection to the previous line."
  (interactive)
  (multi-project-move-selection multi-project-file-buffer 'next-logical-line -1))

(defun multi-project-file-next-line ()
  "Move selection to the next line."
  (interactive)
  (save-excursion multi-project-file-buffer
                  (multi-project-move-selection multi-project-file-buffer
                                                'next-logical-line 1)))

(defun multi-project-find-file-display (input)
  "Display the list of files that match INPUT from the minibuffer."
  (interactive)

  (with-current-buffer multi-project-file-buffer
    (when multi-project-current-name
      (let (result)
	(setq result (multi-project-find-files input))
	(setq buffer-read-only nil)
	(erase-buffer)
	(dolist (item result)
	  (insert item "\n"))

	(if (= (point) (point-max))
	    (goto-char (point-min)))

	(setq buffer-read-only t)

	(multi-project-mark-line)))))

(defun multi-project-check-file-input()
  "Check for input"
  (if (sit-for 0.2)
      (let ((input (minibuffer-contents)))
        (if (and (not (string-equal input multi-project-previous-file-input))
                 (>= (length input) 1))
            (progn
              (multi-project-find-file-display input)
              (setq multi-project-previous-file-input input))))))

(defun multi-project-file-select ()
  "Select from the list of files presented."
  (with-current-buffer multi-project-file-buffer
    (let ((filename (buffer-substring-no-properties (point-at-bol)
						    (point-at-eol))))
      (save-excursion
	(visit-tags-table-buffer)
	(find-file filename)))))

;;;###autoload
(defun multi-project-find-file ()
  "Search a TAGS file for a particular file that match a user's input."

  (interactive)

  (let ((tags-revert-without-query t))
    ;; Try determining which TAGS file
    (multi-project-change-tags)

    (add-hook 'post-command-hook 'multi-project-check-file-input)

    (switch-to-buffer multi-project-file-buffer)
    (setq multi-project-overlay (make-overlay (point-min) (point-min)))
    (overlay-put multi-project-overlay 'face 'multi-project-selection-face)

    (unwind-protect
	(let ((minibuffer-local-map multi-project-file-minibuffer-map))
	  (read-string "Filename substring: "))
      (remove-hook 'post-command-hook 'multi-project-check-file-input))

    (with-current-buffer multi-project-file-buffer
      (multi-project-file-select))
    (kill-buffer multi-project-file-buffer)))

;;;###autoload
(defadvice xref-find-definitions (before multi-project-xref-find-definitions)
  "Switch the TAGS table based upon the project directory before trying to find the definition."
  (let ((project (multi-project-find-by-directory)))
    (when project
      (multi-project-change-tags (car project)))))

(defun multi-project-file-base (directory filename)
  "The DIRECTORY is removed from FILENAME."
  (replace-regexp-in-string (concat directory "/?")  "" filename))

(defun multi-project-create-tags-manually (project-dir project-tags)
  "Create a TAGS file based upon PROJECT-DIR and PROJECT-TAGS."
  (let* ((files (directory-files-recursively project-dir ".+"))
	 (relative-files
	  (mapcar (lambda (x) (file-relative-name x project-dir)) files)))

    (message "Creating TAGS...")
    (multi-project-add-tags-files relative-files project-tags)))

(defun multi-project-add-tags-files (files tags-file)
  "Add the list of FILES to the TAGS-FILE file."

  (if (file-exists-p tags-file)
      (multi-project-visit-tags tags-file))

  (let ((tags-buf (get-buffer-create "TAGS")))
    (with-current-buffer tags-buf
      (goto-char (point-max))

      (while files
	(insert "\n")
        (insert (car files) ",0\n")
	(setq files (cdr files)))
      (write-region (point-min) (point-max) tags-file))))


(defun multi-project-create-tags (project-name project-directory project-tags)
  "Create a TAGS file based upon the the PROJECT-NAME and PROJECT-DIRECTORY.
The contents are written to PROJECT-TAGS."

  (let ((buffer-name (concat "*" project-name "-TAGS*"))
	(etags-command
	 (multi-project-create-tags-command project-directory
					    project-tags))
	(process))

    ;; Kill off any prior TAGS buffer
    (if (get-buffer "TAGS")
	(kill-buffer (get-buffer "TAGS")))

    ;; Kill off the created temp TAGS buffer if it exists from a prior
    ;; invocation
    (if (get-buffer buffer-name)
	(kill-buffer (get-buffer buffer-name)))


    (setq process (multi-project-execute-tags-command buffer-name etags-command))

    ;; Create a list of files if etags is unable to provide
    ;; any contents for the TAGS file

    (sleep-for 1)

    (if (and (eq (process-status process) 'exit)
	     (or (not (file-exists-p project-tags))
		 (= 0 (nth 7 (file-attributes project-tags)))))
	(multi-project-create-tags-manually project-directory project-tags))))


(defun multi-project-recreate-tags ()
  "Create or re-create the TAGS file based upon the project."
  (interactive)

  (let ((project (multi-project-dir-current)))
    (when project
      (let* ((project-name (car project))
	     (project-dir (nth 1 project))
	     (project-tags (nth 3 project)))

	(unless project-tags
	  (setq project-tags (concat project-dir "/TAGS"))
	  (setq project (append project (list project-tags)))

	  (multi-project-delete-project (car project))
	  (add-to-list 'multi-project-roots project t)
	  (multi-project-save-projects))

	(multi-project-create-tags project-name project-dir project-tags)
	(multi-project-change-tags (car project))))))

(defun multi-project-current ()
  "Find the project based upon the current project and the current directory."
  (let ((result multi-project-current-name)
	(project))
    (unless result
      (setq project (multi-project-find-by-directory))
      (if project
	  (setq result (car project))))
    (multi-project-find-by-name result)))

(defun multi-project-dir-current ()
  "Find the project based upon the current directory and the current project."

  (let ((result (multi-project-find-by-directory)))
    (unless result
      (setq result (multi-project-current)))
    result))

;;;###autoload
(defun multi-project-present-project ()
  "Jumps to the present project."
  (interactive)
  (let ((projectlist (multi-project-current)))
    (multi-project-open-project projectlist)))

(defun multi-project-create-frame-parameters ()
  (let ((frame-parameters-alist default-frame-alist)
	frame)
    (unless frame-parameters-alist
      (let ((frame-start (car (frame-position)))
	    (frame-width (frame-outer-width)))
	(list (cons 'width (frame-width))
	      (cons 'height (frame-height))
	      (cons 'left (+ frame-start frame-width)))))))

;;;###autoload
(defun multi-project-present-project-new-frame ()
  "Jumps to the present project in a new frame."
  (interactive)
  (let* ((frame-parameters-alist (multi-project-create-frame-parameters))
	 (frame (make-frame frame-parameters-alist)))

    (select-frame-set-input-focus frame)
    (multi-project-present-project)))

;;;###autoload
(defun multi-project-visit-project ()
  "Makes a new frame with the list of projects to visit."
  (interactive)

  (let* ((frame-parameters-alist (multi-project-create-frame-parameters))
	 (frame (make-frame frame-parameters-alist)))
    (select-frame-set-input-focus frame)
    (multi-project-display-projects)))

(defun multi-project-compose-exclusion (filename)
  (when (file-exists-p filename)
    (concat "-path '*/" filename "' -prune -o")))

(defun multi-project-compose-grep ()
  "Compose the grep command and ignore version control directories.
Directories like .git, .hg, node_modules, and .svn will be
ignored. If a version control directory is not found, the default
‘grep-find-command’ is returned"
  (let 	(exclusion-list
	 exclusions)


    (setq exclusion-list (delq nil (mapcar (lambda (x)
					     (when (and x (file-exists-p x))
					       (multi-project-compose-exclusion x)))
					   multi-project-grep-exclusions)))

    (setq exclusions (string-join exclusion-list " "))

    (if exclusions
	(let ((command (concat "find . " exclusions " -type f -exec grep -nH -e  {} +")))
	  (cons command (- (length command) 4)))
      grep-find-command)))

;;;###autoload
(defun multi-project-interactive-grep ()
  "Run ‘grep-find’ interactively."
  (interactive)
  (multi-project-root)
  (let ((orig-command grep-find-command))
    (grep-apply-setting 'grep-find-command (multi-project-compose-grep))
    (call-interactively 'grep-find)
    (grep-apply-setting 'grep-find-command orig-command)))


;;;###autoload
(defun multi-project-shell ()
  "Create a shell with a buffer name of the project.
The function first looks if the current directory is within a
known project.  If no projects are found, then the current
project is used."
  (interactive)

  (let ((project (multi-project-dir-current)))
    (when project
      (let* ((buffer-name (concat "*shell-" "<" (car project) ">*"))
	     (buffer (get-buffer buffer-name)))

	;; create the buffer and invoke the shell
	(unless buffer
	  (setq buffer (get-buffer-create buffer-name))
	  (set-buffer buffer)

	  ;; Set the working directory to the current directory if the
	  ;; invocation occurred within a project directory. If not, then create
	  ;; the directory at the project root.

	  (let (shell-directory)
	    (if (multi-project-find-by-directory)
		(setq shell-directory default-directory)
	      (setq shell-directory (nth 1 project)))
	    (cd shell-directory)))

	(shell buffer)))))


(defun multi-project-execute-tags-command (buffer-name etags-command)
  "Generate a TAGS file in BUFFER-NAME for ETAGS-COMMAND."
  (start-file-process-shell-command buffer-name (get-buffer buffer-name)
				    etags-command))

(defun multi-project-tramp-local-file (filename)
  "Return the local filename if we have a remote FILENAME."
  (cond ((and (fboundp 'file-remote-p)
	      (fboundp 'tramp-dissect-file-name)
	      (fboundp 'tramp-file-name-localname)
	      (file-remote-p filename))
	 (let ((tramp-vec (tramp-dissect-file-name filename)))
	   (tramp-file-name-localname tramp-vec)))

	;; older verison of tramp so just try grabbing the last element
	((and (fboundp 'file-remote-p) (file-remote-p filename))
	 (car (last (split-string filename ":"))))

	(t filename)))

(defun multi-project-create-tags-command (project-directory project-tags)
  "Return the tags command based upon PROJECT-DIRECTORY and PROJECT-TAGS."
  (interactive)

  (let ((local-project-directory
	 (multi-project-tramp-local-file project-directory))

	(local-project-tags (multi-project-tramp-local-file
			     (expand-file-name project-tags))))

    (let ((files-command (concat "cd " local-project-directory "; "
				 "find . -type f -print")))

      (cond ((file-exists-p (concat local-project-directory "/.hg"))
	     (setq files-command "hg locate"))

	    ((file-exists-p (concat local-project-directory "/.svn"))
	     (setq files-command "svn ls -R | grep -v -e '/$'"))

	    ((file-exists-p (concat local-project-directory "/.git"))
	     (setq files-command
		   "git ls-tree --full-tree -r --name-only HEAD "))

	    ((file-exists-p (concat local-project-directory "/build.gradle"))
	     (setq files-command (concat "cd " local-project-directory "; "
					 "find . -path '*/build' -prune -o -type f -print")))
	    ((file-exists-p (concat local-project-directory "/pom.xml"))
	     (setq files-command
		   (concat "cd " local-project-directory "; "
			   "find . -path '*/target' -prune -o -type f -print"))))

      (concat files-command " | etags -o " local-project-tags " -"))))

(defun multi-project-add-project ()
  "Add a project to the list of projects."
  (interactive)
  (let ((project-name (buffer-name))
        project-directory
        project-tags
        project-subdir
        project-list
	project-load-file)

    (setq project-name (read-from-minibuffer "Project name: "
					     project-name nil nil nil
					     project-name))
    (setq project-directory
          (multi-project-dir-as-file
           (read-file-name "Project directory: " nil default-directory)))

    (setq project-subdir
	  (multi-project-basename
           (multi-project-dir-as-file
            (read-file-name "Place cursor on: "
			    (file-name-as-directory project-directory)
                            (file-name-as-directory project-directory)))))

    (when (and (file-regular-p (concat project-directory "/" project-subdir))
	       (y-or-n-p (concat "Load " project-subdir " when visiting")))
      (setq project-load-file t))

    (when (y-or-n-p "Use a TAGS file? ")
      (let ((tags-file (concat project-directory "/TAGS")))

	(setq project-tags (read-file-name "Project tags: " tags-file tags-file))
	(when (not (file-exists-p project-tags))
	  (message "Creating TAGS file...")
	  (multi-project-create-tags project-name project-directory project-tags))))

    (setq project-list (list project-name project-directory project-subdir project-tags project-load-file))


    (add-to-list 'multi-project-roots project-list t)
    (multi-project-save-projects)

    (multi-project-switch (car project-list))
    (message "Added %s" project-name)
    project-name))

(defun multi-project-delete-project (project)
  "Delete a project named PROJECT from the list of managed projects."
  (let ((lst (multi-project-filter-name project multi-project-roots)))
    (setq multi-project-roots (delq lst multi-project-roots))
    (multi-project-save-projects)))

(defun multi-project-filename ()
  "Construct the filename used for saving or loading projects."
  (concat multi-project-dir "/" multi-project-file))

(defun multi-project-save-projects ()
  "Save the project configuration to a file."
  (interactive)
  (let ((mp-file (multi-project-filename)))
    (if (not (file-exists-p multi-project-dir))
        (make-directory multi-project-dir t))

    (multi-project-write-file mp-file)
    (message "Projects saved to %s" mp-file)))

(defun multi-project-write-file (filename)
  "Write `multi-project-roots' to FILENAME."
  (message "Saving project configuration to file %s..." filename)
  (with-current-buffer (get-buffer-create "*MP-Projects*")
    (erase-buffer)
    (goto-char (point-min))
    (pp multi-project-roots (current-buffer))
    (condition-case nil
        (write-region (point-min) (point-max) filename)
      (file-error (message "Can't write %s" filename)))
    (kill-buffer (current-buffer))))

(defun multi-project-list-from-buffer ()
  "Create a list from the `current-buffer'."
  (save-excursion
    (goto-char (point-min))
    (if (search-forward "(" nil t)
        (progn
          (forward-char -1)
          (read (current-buffer)))
      (error "Not multi-project format"))))

(defun multi-project-read-file (filename)
  "Read the FILENAME and set `multi-project-roots'."
  (when (file-exists-p filename)
    (with-current-buffer (find-file-noselect filename)
      (multi-project-list-from-buffer))))

(defun multi-project-read-projects ()
  "Read the project configuration."
  (interactive)
  (setq multi-project-roots (multi-project-read-file (multi-project-filename)))
  (message "Projects read from %s." (multi-project-filename)))

(defun multi-project-mark-project (mark-symbol)
  "Mark the selected projects with MARK-SYMBOL."
  (setq buffer-read-only nil)
  (goto-char (point-at-bol))
  (insert mark-symbol)
  (delete-char 1)
  (multi-project-next-line)
  (goto-char (point-at-bol))
  (setq buffer-read-only t))

(defun multi-project-unmark-project ()
  "Unmark the selected projects."
  (interactive)
  (setq buffer-read-only nil)
  (goto-char (point-at-bol))
  (delete-char 1)
  (insert " ")
  (goto-char (point-at-bol))
  (multi-project-next-line)
  (setq buffer-read-only t))

(defun multi-project-new-project ()
  "Add a new project from the multi-project display."
  (interactive)
  (let ((project (multi-project-add-project)))
    (when project
      (multi-project-display-projects)
      (goto-char (point-min))
      (when (re-search-forward project nil t)
          (goto-char (point-at-bol))
          (multi-project-mark-line)))))

(defun multi-project-mark-deletions ()
  "Mark the project for deletion."
  (interactive)
  (multi-project-mark-project "D"))

(defun multi-project-mark-grep ()
  "Mark the project for executing grep."
  (interactive)
  (multi-project-mark-project "G"))

(defun multi-project-marked-projects (marker)
  "Return a list of marked projects based upon MARKER."
  (let (lst)
    (save-excursion
      (goto-char (point-min))
      (while (re-search-forward (concat "^" marker " +\\([^\t]+\\)") nil t)
        (setq lst (cons (match-string 1) lst))))
    (multi-project-trim-string lst)))

(defun multi-project-delete-projects (projects)
  "Execute the action on the marked PROJECTS."
  (when projects
    (let ((current-point (point)))
      (when (y-or-n-p (concat "Remove "
			      (mapconcat 'identity projects ", ")
			      "? "))
	(dolist (project (multi-project-marked-projects "D"))
	  (multi-project-delete-project project))
	(multi-project-display-projects)
	(if (> current-point (point-max))
	    (setq current-point (point-max)))
	(goto-char current-point)
	(goto-char (point-at-bol))
	(multi-project-mark-line)))))

(defun multi-project-grep-project (project regex files)
  "Execute grep on PROJECT based upon REGEX and FILES."
  (let ((projectdir (nth 1 (multi-project-find-by-name project)))
        (buffername (concat "*" project "-grep*")))

    (save-excursion
      (if (get-buffer buffername)
	  (kill-buffer buffername))
      (grep-compute-defaults)
      (rgrep regex files projectdir)
      (when (not (get-buffer buffername))
	(set-buffer (get-buffer "*grep*"))
	(rename-buffer buffername)))
    buffername))

(defun multi-project-display-grep-buffers (bufferlist)
  "Display the grep results in BUFFERLIST."
  (dolist (buffer bufferlist)
    (set-window-buffer (split-window (get-largest-window)) buffer))
  (balance-windows))

(defun multi-project-read-regexp ()
  "Read regexp arg for searching."
  (let* ((default (car grep-regexp-history))
	 (prompt (concat "Search for"
			 (if (and default (> (length default) 0))
			     (format " (default \"%s\"): " default) ": "))))
    (if (and (>= emacs-major-version 24)
	     (>= emacs-minor-version 3))
	(read-regexp prompt default 'grep-regexp-history)
      (read-regexp prompt default))))

(defun multi-project-grep-projects (projects)
  "Execute the action on the marked PROJECTS."
  (when projects
    (let ((regex (multi-project-read-regexp))
	  (files (read-from-minibuffer "File pattern: " "*"))
	  (bufferlist ()))
      (dolist (project projects)
	(setq bufferlist (cons
			  (multi-project-grep-project project regex files)
			  bufferlist)))
      (delete-other-windows)
      (multi-project-display-grep-buffers bufferlist))))

(defun multi-project-execute-actions ()
  "Execute the action on the marked projects."
  (interactive)
  (multi-project-grep-projects (multi-project-marked-projects "G"))
  (multi-project-delete-projects (multi-project-marked-projects "D")))

(defun multi-project-mouse-select (event)
  "Visit the project that was clicked on based upon EVENT."
  (interactive "e")
  (let ((window (posn-window (event-end event)))
        (pos (posn-point (event-end event))))

    (with-current-buffer (window-buffer window)
      (goto-char pos)
      (multi-project-display-select))))

(defun multi-project-insert-path ()
  "Insert the directory path of the current project."
  (interactive)
  (let ((project (multi-project-find-by-name multi-project-current-name)))
    (when project
      (insert (expand-file-name (nth 1 project))))))


;;;###autoload
(define-minor-mode multi-project-mode
  "Toggle multi-project mode."
  nil
  " MP"
  multi-project-mode-map
  :global t
  :group 'project
  (if multi-project-mode
      (progn
        (unless multi-project-roots
          (multi-project-read-projects))

        (ad-enable-advice 'xref-find-definitions 'before 'multi-project-xref-find-definitions)
        (ad-activate 'xref-find-definitions))
    (ad-disable-advice 'xref-find-definitions 'before 'multi-project-xref-find-definitions)))

(provide 'multi-project)

;;; multi-project.el ends here
