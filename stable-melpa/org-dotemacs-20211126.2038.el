;;; org-dotemacs.el --- Store your emacs config as an org file, and choose which bits to load.

;; Filename: org-dotemacs.el
;; Description: Store your emacs config as an org file, and load code snippets based on tag matches.
;; Author: Joe Bloggs <vapniks@yahoo.com>
;; Maintainer: Joe Bloggs <vapniks@yahoo.com>
;; Copyleft (Ↄ) 2013, Joe Bloggs, all rites reversed.
;; Created: 2013-04-27 20:19:18
;; Version: 0.4
;; Package-Version: 20211126.2038
;; Package-Commit: 598759f4a139f94da62836e8f8064da6377536b2
;; Last-Updated: 2018-07-28 22:22:18
;;           By: Joe Bloggs
;; URL: https://github.com/vapniks/org-dotemacs
;; Keywords: local
;; Compatibility: GNU Emacs 24.3.1
;; Package-Requires: ((org "7.9.3") (cl-lib "0.5"))
;;
;; Features that might be required by this library:
;;
;; org cl
;;

;;; This file is NOT part of GNU Emacs

;;; License
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.
;; If not, see <http://www.gnu.org/licenses/>.

;;; Commentary: 
;;
;; Bitcoin donations gratefully accepted: 1Ph9srQBspJCDS9CnGUyWJPTrU4ydX9Aa3
;;
;; Keeping your emacs config in an org file makes it easier for you to keep your .emacs under control,
;; and avoid DotEmacsBankruptcy.
;; With your config code stored in an org file you can easily edit the structure and keep notes.
;; Note: it can also be used for organizing other elisp config files such as .gnus.el and .ercrc.el.
;; 
;; This library allows you to load elisp code from an org file on emacs startup.
;; You can also limit the code that is loaded to certain tagged headers using an org tag match,
;; and specify dependencies between code blocks.
;; Using tag matches you can also reuse the same org file for different emacs setups by specifying different
;; tag matches for each setup, or load parts of the file on demand.
;; 
;;; Commands/Usage 
;; 
;; The main command is `org-dotemacs-load-default' which loads your default org-dotemacs file (~/.dotemacs.org)
;; and prompts for a tag match to specify which code blocks to load. 
;; In this way you can load bits of config code when you need them.
;; 
;; You can also put this command in your InitFile (see Installation below) to load the code on startup.
;; To change the default org file use the `org-dotemacs-default-file' option.
;; If you want to load a different org file from your default one, use `org-dotemacs-load-file'.
;; 
;; For faster loading you may prefer to keep your config code in a separate elisp file, and just update this file now and again
;; by exporting the code from the org file.
;; Use the `org-dotemacs-load-file' command for this and specify a target elisp file when prompted.
;; Note however that you may get errors when loading the elisp file that you didnt get with the org file.
;; This is because in order to process the org-file some other libraries are loaded which are not loaded when the elisp file loads.
;; You will have to experiment for yourself.
;;
;; After loading you can inspect the *Messages* buffer to see which blocks were successfully loaded and which had errors.
;; If you call the `org-dotemacs-jump-to-block' command on one of the org-dotemacs lines in this buffer it will take you to
;; the block mentioned on that line, or you can prompt for one by using a prefix with this command.
;;
;;; Structure of the org file 
;; 
;; The elisp code should be contained in emacs-lisp code blocks, e.g:
;; 
;; #+BEGIN_SRC emacs-lisp
;; (setq line-number-mode t)
;; (setq column-number-mode t)
;; (setq frame-title-format "%b")
;; (set-background-color "Black")
;; (set-foreground-color "White")
;; (set-cursor-color "White")
;; #+END_SRC
;; 
;; Ideally you should have each code block under a separate org subtree, then you can use properties to
;; name the blocks and define dependencies, and tags and todo states to specify which blocks
;; should be loaded (see below). You can specify that certain blocks are loaded only when certain conditions hold
;; by customizing `org-dotemacs-conditional-tags'. By default operating system tags (linux, windows, mac, hurd, freebsd,
;; unix) are set to only load when the corresponding operating system is being used (as reported by the `system-type' variable).
;; So for example, any blocks tagged with "linux" will only be loaded if `system-type' is eq to 'gnu/linux.
;; These conditional tags are overridden by any tag-match supplied to the command line.
;; 
;; I prefer to keep all my code block subtrees under a single header, and use other headers for keeping notes,
;; defining buffer-wide properties, etc. This way I can get a nice column view of the code blocks
;; (see the columns view section below).
;; 
;;;  Block dependencies 
;; 
;; You can enforce dependencies between code blocks by defining NAME & DEPENDS properties for the subtrees containing the
;; blocks (preferred). The NAME property should contain the name of the block, and the DEPENDS property should contain a space
;; separated list of block names that this block depends on. If a block doesn't have it's own NAME property it will be given
;; a default name of "@N" where N is the buffer position of the start of the block.
;; If `org-dotemacs-dependency-inheritance' is non-nil then block dependencies will be inherited from parent headers.
;; 
;; A block will not be loaded until all of its dependencies have been loaded.
;; 
;;;  Tags and TODO states 
;; 
;; You can tag your subtrees and use tag matches to specify which blocks to evaluate in calls to `org-dotemacs-load-file'
;; and `org-dotemacs-load-default'. See "Matching tags and properties" in the org manual for more information on tag matches.
;; 
;; Also, by default any blocks in a subtree marked with a todo state of BROKEN will not be evaluated.
;; You can specify which TODO states to include/exclude for evaluation by customizing the `org-dotemacs-include-todo' and
;; `org-dotemacs-exclude-todo' options.
;; 
;; To add the BROKEN state to the list of todo states for the file you need to add buffer-wide todo states by adding a line
;; like this somewhere in your org file (see "Per file keywords" in the org manual).
;; 
;; #+TODO: BROKEN CHECK TODO
;; 
;;;  Columns View 
;; 
;; If you use properties for defining names and dependencies then you can get a nice column view of your code subtrees
;; with the following columns view specification:
;; 
;; #+COLUMNS: %35ITEM %15NAME %35DEPENDS %15TAGS %TODO
;; 
;; This can be placed anywhere in your dotemacs org file.
;; Then if you press C-c C-x C-c on the toplevel header for your code blocks you'll get a column view that allows you
;; to easily change the names, dependencies, tags and todo states.
;; 
;;;  Error handling 
;; 
;; Error handling can be controlled by customizing `org-dotemacs-error-handling' or by setting the error-handling
;; command line option when starting emacs.
;; By default code blocks with unmet dependencies or errors are skipped over as soon as an error is encountered,
;; but you can also specify that org-dotemacs should halt or try to reload the blocks.
;; In the latter case each time a new block is successfully loaded, any unsuccessful blocks will be retried.
;; 
;;;  Command line options 
;; 
;; org-dotemacs.el will look for two command line options when loaded: error-handling (for setting the value of
;; `org-dotemacs-error-handling') and tag-match (for specifying which headers to load).
;; For example if you enter the following at the command line:
;; 
;;        emacs --error-handling retry --tag-match "settings-mouse"
;; 
;; Then only code blocks tagged "settings" but not "mouse" will be loaded, and org-dotemacs will try to reload any
;; blocks that have errors. If no tag-match is specified on the command line then `org-dotemacs-conditional-tags'
;; will be used to determine which blocks can be loaded by default.
;; 
;;;  Installation 
;; 
;; Put org-dotemacs.el in a directory in your load-path, e.g. ~/.emacs.d/
;; You can add a directory to your load-path with the following line in ~/.emacs
;; (add-to-list 'load-path (expand-file-name "~/elisp"))
;; where ~/elisp is the directory you want to add 
;; (you don't need to do this for ~/.emacs.d - it's added by default).
;; 
;; Then make sure you have an ~/.dotemacs.org file and add the following lines to
;; the end of your .emacs file:
;; 
;; (load-file "~/.emacs.d/org-dotemacs.el")
;; (let (find-file-hook) (org-dotemacs-load-default))
;; 
;; or if you want to just load code blocks matching a tag match:
;; 
;; (load-file "~/.emacs.d/org-dotemacs.el")
;; (let (find-file-hook) (org-dotemacs-load-default "<TAG-MATCH>"))
;; 
;; To load a different org file either customize `org-dotemacs-default-file' or use the
;; `org-dotemacs-load-file' function, e.g:
;; 
;; (load-file "~/.emacs.d/org-dotemacs.el")
;; (let (find-file-hook) (org-dotemacs-load-file "<TAG-MATCH>" "~/.emacs.d/my_emacs_config.org"))
;; 


;;; Customize:
;;
;; `org-dotemacs-conditional-tags' : A list of tags/regexps and corresponding conditions for loading blocks.
;; `org-dotemacs-default-file' : The default org file containing the code blocks to load when `org-dotemacs-load-file' is called.
;; `org-dotemacs-error-handling' : Indicates how errors should be handled by `org-dotemacs-load-blocks'.
;; `org-dotemacs-include-todo' : A regular expression matching TODO states to be included.
;; `org-dotemacs-exclude-todo' : A regular expression matching TODO states to be excluded.
;; `org-dotemacs-noselect-on-jump' : Whether to display or select org-dotemacs file when `org-dotemacs-jump-to-block' is called.
;;
;; All of the above can customized by:
;;      M-x customize-group RET org-dotemacs RET
;;

;;; Change log:
;; [2018-07-28 Sat]
;;      * Refactor code to use org-dotemacs-topo-sort
;;	
;; [2013-04-27]
;;      * First released.
;; 

;;; Acknowledgements:
;;
;; 
;;

;;; TODO
;;
;; Option to show prominent warning message if some blocks didn't load (e.g. in large font in dedicated buffer after startup)
;; Option to show full backtrace on error?

;;; Require
(require 'cl-lib)
(require 'org-element)
(require 'org)

;;; Code:



(defgroup org-dotemacs nil
  "Store your emacs config as an org file, and choose which bits to load."
  :group 'org)

(defcustom org-dotemacs-default-file "~/.dotemacs.org"
  "The default org file containing the code blocks to load when `org-dotemacs-load-file' is called."
  :group 'org-dotemacs
  :type '(file :must-match t))

(defcustom org-dotemacs-error-handling 'skip
  "Indicates how errors should be handled by `org-dotemacs-load-blocks'.
If eq to 'skip then errors will be skipped over (default).
If eq to 'retry then `org-dotemacs-load-blocks' will attempt to reload any blocks containing errors,
after each successfully loaded block.
In all other cases errors will cause evaluation to halt as normal.
In all cases errors will be reported in the *Messages* buffer as normal.

This variable can be set from the command line using the dotemacs-error-handling argument."
  :group 'org-dotemacs
  :type 'symbol)

(defcustom org-dotemacs-include-todo nil
  "A regular expression matching TODO states to be included.
If non-nil then only headers with TODO states matching this regexp will be checked for code blocks.
See also `org-dotemacs-exclude-todo'."
  :group 'org-dotemacs
  :type 'regexp)

(defcustom org-dotemacs-exclude-todo "BROKEN"
  "A regular expression matching TODO states to be excluded.
If non-nil then headers with TODO states matching this regexp will not be checked for code blocks.
See also `org-dotemacs-include-todo'."
  :group 'org-dotemacs
  :type 'regexp)

(defcustom org-dotemacs-conditional-tags '(("linux" . (eq system-type 'gnu/linux))
                                           ("windows" . (member system-type '(ms-dos windows-nt cygwin)))
                                           ("mac" . (eq system-type 'darwin))
                                           ("hurd" . (eq system-type 'gnu))
                                           ("freebsd" . (eq system-type 'gnu/kfreebsd))
                                           ("unix" . (member system-type '(aix berkely-unix hpux irix usg-unix-v))))
  "A list of tags/regexps and corresponding conditions for loading blocks.
If a block has a tag matching a regexp in this list then it will only be loaded if the corresponding
condition evaluates to non-nil. All other blocks are loaded as normal.
This behaviour is overridden if a tag-match is supplied on the command line."
  :group 'org-dotemacs
  :type '(repeat (cons (string :tag "Tag/regexp:")
                       (sexp :tag "Predicate expression:"))))

(defcustom org-dotemacs-dependency-inheritance nil
  "Whether dependency properties (:DEPENDS:) can be inherited or not.
This is passed straight to `org-entry-get'. See the documentation of that function for more info."
  :group 'org-dotemacs
  :type '(choice (const nil) (const t) (const selective)))

(defcustom org-dotemacs-noselect-on-jump nil
  "If non-nil then don't select buffer when `org-dotemacs-jump-to-block' is called, just display it."
  :group 'org-dotemacs
  :type 'boolean)

(defvar org-dotemacs-tag-match nil
  "An org tag match string indicating which code blocks to load with `org-dotemacs-load-file'.
This overrides the match argument to `org-dotemacs-load-file' and is set by the emacs command line
argument '--tag-match'.")

(defvar org-dotemacs-loaded-blocks nil
  "Alist of loaded files, blocks and positions.")

;;;###autoload
;; simple-call-tree-info: DONE
(defun org-dotemacs-default-match nil
  "Return the default tag match string based on items in `org-dotemacs-conditional-tags' (which see)."
  (let ((str (cl-loop for (regex . condition) in org-dotemacs-conditional-tags
                      if (not (eval condition)) concat (concat regex "$\\|^"))))
    (if (not (equal str ""))
        (concat "-{\\(?:^" (substring str 0 -3) "\\)}"))))

;; The following function is based on code from el-get-dependencies.el : https://github.com/dimitri/el-get/
;; simple-call-tree-info: DONE
;;;###autoload
(cl-defun org-dotemacs-topo-sort (graph blocks &optional haltonerror)
  "Returns a list of items whose order is consistent with the supplied dependency GRAPH.
GRAPH is an alist whose keys are block names, and whose values are lists of block names 
on which the corresponding key depends.
BLOCKS is an alist of (NAME . CODE) pairs, containing the code blocks corresponding to 
the names in GRAPH. These BLOCKS will be evaluated as the return list is created.
If SKIPERRORS determines what to do about blocks which throw errors when evaluated;

A list of the following four values is returned.
1: list of block names sorted such that dependent blocks come after their dependencies in the list.
   Failed blocks, and blocks with failed dependencies will not be included in this list.
2: boolean indicating whether all blocks in the input GRAPH are present in the previous list.
3: list of failed blocks (i.e. blocks that threw errors when evaluated).
4: list of blocks which could not be processed because they depend on failed blocks, or are part of
   a circular dependency."
  (let* ((entries (make-hash-table :test 'equal))
	 ;; function to return the entry for vertex v. Each entry is a cons
	 ;; whose car is the number of outstanding dependencies of vertex
	 ;; and whose cdr is a list of dependents of vertex.
	 (entry (lambda (v)
		  (or (gethash v entries)
		      (puthash v (cons 0 '()) entries)))))
    ;; populate entries initially
    (dolist (gvertex graph)
      (cl-destructuring-bind (vertex &rest dependencies) gvertex
	(let ((ventry (funcall entry vertex)))
	  (dolist (dependency dependencies)
	    (let ((dentry (funcall entry dependency)))
	      (unless (equal dependency vertex)
		(cl-incf (car ventry))
		(push vertex (cdr dentry))))))))
    ;; L is the list of sorted elements, and S the set of vertices with no outstanding dependencies.
    (let (L S failed)
      (maphash (lambda (k v) (if (zerop (car v)) (push k S))) entries)
      ;; Until there are no vertices with no outstanding dependencies,
      ;; process vertices from S, adding them to L.
      (cl-do* () ((cl-endp S))
	(let* ((v (pop S))
	       (ventry (funcall entry v))
	       (block (cdr (assoc v blocks))))
	  (remhash v entries)
	  ;; try to eval this block
	  (if block
	      (if (with-temp-buffer
		    (insert block)
		    (condition-case err 
			(progn (eval-buffer)
			       (message "org-dotemacs: %s block evaluated" v)
			       nil)
		      (error (funcall (if haltonerror 'error 'message)
				      "org-dotemacs: %s block has error: %s"
				      v (error-message-string err))
			     t)))
		  (push v failed)
		(dolist (dependant (cdr ventry) (push v L))
		  (when (zerop (cl-decf (car (funcall entry dependant))))
		    (push dependant S)))))))
      ;; return values
      (let ((all-sorted-p (zerop (hash-table-count entries))))
	(list (nreverse L) all-sorted-p failed (unless all-sorted-p entries))))))

;;;###autoload
;; simple-call-tree-info: CHANGE  
(cl-defun org-dotemacs-load-file (&optional (match org-dotemacs-tag-match)
					    (file org-dotemacs-default-file)
					    target-file
					    (error-handling org-dotemacs-error-handling))
  "Load the elisp code from code blocks in org FILE under headers matching tag MATCH.
Tag matches supplied at the command line get priority over those supplied by the MATCH argument,
and if both of these are nil then `org-dotemacs-default-match' will be used to create a tag match.
If you need to override the command line tag-match set `org-dotemacs-tag-match' to nil.
If TARGET-FILE is supplied it should be a filename to save the elisp code to, but it should
not be any of the default config files .emacs, .emacs.el, .emacs.elc or init.el
 (the function will halt with an error in those cases). If TARGET-FILE is newer than FILE then
TARGET-FILE will be loaded and FILE will not be processed. Otherwise TARGET-FILE will be overwritten
by the code blocks in FILE.
The optional argument ERROR-HANDLING determines how errors are handled and takes default value
`org-dotemacs-error-handling' (which see)."
  (interactive (list nil
                     (read-file-name (format "File to load (default %s): " org-dotemacs-default-file)
                                     (file-name-directory org-dotemacs-default-file)
                                     org-dotemacs-default-file
                                     t nil
				     (lambda (file)
				       (string-match "\\.org$" file)))
                     (if (y-or-n-p "Save elisp code to separate file?")
                         (read-file-name "Save to file: " user-emacs-directory))))
  (if (and target-file (string-match "\\(?:\\.emacs\\(?:\\.elc?\\)?\\|init\\.elc?\\)$" target-file))
      (error "org-dotemacs: Refuse to overwrite %s" target-file))
  (require 'ob-core)
  (cl-flet ((age (file) (float-time
                         (time-subtract (current-time)
                                        (nth 5 (or (file-attributes (file-truename file))
                                                   (file-attributes file)))))))
    (let* ((matchstr (or match (org-dotemacs-default-match)))
	   (matcher (if matchstr
			(cdr (org-make-tags-matcher matchstr))
		      (lambda (&rest args) t)))
	   (todo-only nil)
	   blocks positions graph
	   ;; make sure we dont get any strange behaviour from hooks
	   find-file-hook change-major-mode-after-body-hook
	   text-mode-hook outline-mode-hook org-mode-hook)
      (if (and target-file
	       (file-exists-p target-file)
	       (> (age file) (age target-file)))
	  (load-file target-file)
	(message "org-dotemacs: parsing %s" file)
	(org-babel-map-src-blocks file
	  (let* ((parts (org-heading-components))
		 (todo (nth 2 parts))
		 (tags (org-get-tags-at)))
	    (if (and (equal lang "emacs-lisp")
		     (if (and todo org-dotemacs-include-todo)
			 (string-match org-dotemacs-include-todo todo)
		       t)
		     (if (and todo org-dotemacs-exclude-todo)
			 (not (string-match org-dotemacs-exclude-todo todo))
		       t)
		     (save-excursion
		       (unless (outline-on-heading-p t)
			 (outline-previous-heading))
		       (funcall matcher
				(nth 2 parts)
				tags
				(car parts))))
		(let ((name (or (org-entry-get beg-block "NAME")
				(concat "@" (number-to-string (point)))))
		      (depends (org-entry-get beg-block "DEPENDS" org-dotemacs-dependency-inheritance)))
		  (push (cons name (and depends (split-string depends "[[:space:]]+"))) graph)
		  (push (point) positions)
		  (push (cons name (substring-no-properties (or body ""))) blocks)))))
	(let ((efile (expand-file-name file))
	      (blkalist (cl-loop for blk in (mapcar 'car graph)
				 for pos in positions
				 collect (cons blk pos))))
	  (if (assoc efile org-dotemacs-loaded-blocks)
	      (setcdr (assoc efile org-dotemacs-loaded-blocks) blkalist)
	    (push (cons efile blkalist) org-dotemacs-loaded-blocks)))
	(cl-destructuring-bind (evaled-blocks allgood bad-blocks unevaled-blocks)
	    (org-dotemacs-topo-sort graph blocks (not (memq error-handling '(skip retry))))
	  (if (eq error-handling 'retry)
	      (let ((oldlen 0))
		(while (/= oldlen (length bad-blocks))
		  ;; remove evaled-blocks from graph and try again
		  (message "org-dotemacs: re-trying bad blocks")
		  (setq oldlen (length bad-blocks)
			vals (org-dotemacs-topo-sort
			      (cl-loop for (node . lst) in graph
				       unless (member node evaled-blocks)
				       collect (cons node
						     (cl-remove-if (lambda (x) (member x evaled-blocks)) lst)))
			      (cl-remove-if (lambda (x) (member (car x) evaled-blocks)) blocks)))
		  (setq evaled-blocks (append evaled-blocks (car vals))
			allgood (nth 1 vals)
			bad-blocks (nth 2 vals)
			unevaled-blocks (nth 3 vals)))))
	  (if target-file
	      (with-temp-buffer
		(insert (concat ";; org-dotemacs: code extracted from " file "\n"))
		(dolist (blk evaled-blocks)
		  (insert (concat ";; Block = " blk "\n"))
		  (insert (concat "(message \"org-dotemacs: evaluating " blk " block\")\n"))
		  (insert (cdr (assoc blk blocks))))
		(insert (format "(message \"org-dotemacs: %s blocks evaluated.\")\n" (length evaled-blocks)))
		(insert (format "(message \"org-dotemacs: %s blocks not considered (see %s).\")\n"
				(+ (length bad-blocks)
				   (length unevaled-blocks))
				file))
		(write-file target-file)))
	  (if allgood
	      (message "org-dotemacs: all %d blocks evaluated successfully."
		       (length evaled-blocks))
	    (cl-flet ((msgfn (lst msg1 &optional (msg2 msg1))
			     (if (> (length lst) 0)
				 (if (= (length lst) 1)
				     (message (concat "org-dotemacs: 1 block " msg1 ": %s") lst)
				   (message (concat "org-dotemacs: %d blocks " msg2 ": %s") (length lst) lst))
			       (message (concat "org-dotemacs: no blocks " msg2)))))
	      (msgfn evaled-blocks "evaluated successfully")
	      (msgfn bad-blocks "has errors" "have errors")
	      (let* ((baddeps (cl-loop for (v . deps) in graph
				       if (cl-intersection deps bad-blocks :test 'equal)
				       collect v))
		     all circular)
		(maphash (lambda (k v) (push k all)) unevaled-blocks)
		(maphash (lambda (k v)
			   (if (cl-intersection (cdr v) all :test 'equal) (push k circular)))
			 unevaled-blocks)
		(msgfn baddeps
		       "depends on blocks with errors" "depend on blocks with errors")
		(msgfn (cl-set-difference all (append circular baddeps))
		       "depends on unevaluated blocks" "depend on unevaluated blocks")
		(msgfn circular "has circular dependencies" "have circular dependencies")))))))))

;;;###autoload
;; simple-call-tree-info: CHANGE  
(cl-defun org-dotemacs-load-default (&optional (match org-dotemacs-tag-match) savep)
  "Load code from `org-dotemacs-default-file' matching tag MATCH.
If SAVEP is non-nil then `org-dotemacs-load-file' will be called with TARGET-FILE
argument set to the value of `org-dotemacs-default-file' with the file ending 
replaced with \".el\".
The user will not be prompted for the location of any files."
  (interactive (list nil))
  (org-dotemacs-load-file
   match org-dotemacs-default-file
   (if savep
       (concat (file-name-sans-extension org-dotemacs-default-file)
	       ".el"))))

;;;###autoload
;; simple-call-tree-info: CHECK
(cl-defun org-dotemacs-jump-to-block (blkname &optional (file org-dotemacs-default-file)
					      (displayonly org-dotemacs-noselect-on-jump))
  "Jump to block named BLKNAME in FILE (`org-dotemacs-default-file' by default).
If called interactively from an \"org-dotemacs:\" line in the *Messages* buffer
the block mentioned on that line will be used for BLKNAME. Otherwise prompt for a block.
If DISPLAYONLY is non-nil display the block in another window but don't visit it.
See also `org-dotemacs-noselect-on-jump'."
  (interactive (let ((file (if current-prefix-arg
			       (read-file-name "File: " user-emacs-directory
					       org-dotemacs-default-file t)
			     (if (and (eq major-mode 'messages-buffer-mode)
				      (save-excursion 
					(re-search-backward
					 "org-dotemacs: parsing \\(.*\\)" nil t)))
				 (match-string 1)
			       org-dotemacs-default-file))))
		 (list (if (and (eq major-mode 'messages-buffer-mode)
				(not current-prefix-arg)
				(save-excursion (forward-line 0)
						(re-search-forward
						 "org-dotemacs: \\(.*\\) block \\(evaluated\\|has error\\)"
						 (line-end-position) t)))
			   (match-string 1)
			 (completing-read
			  "Block name: " (mapcar 'car
						 (cdr (assoc (expand-file-name file)
							     org-dotemacs-loaded-blocks)))))
		       file)))
  (let* ((blks (cdr (assoc (expand-file-name file) org-dotemacs-loaded-blocks)))
	 (pos (cdr (assoc blkname blks)))
	 (buf (find-file-noselect file)))
    (if displayonly
	(display-buffer buf)
      (find-file file))
    (with-selected-window 
	(get-buffer-window buf)
      (setq pos (or pos
		    (save-excursion
		      (and
		       (goto-char (point-min))
		       (re-search-forward (concat ":NAME: *" (regexp-quote blkname)) nil t)
		       (let ((case-fold-search t))
			 (search-forward "#+BEGIN_SRC" nil t))
		       (point)))))
      (if (not pos)
	  (error "Unable to find block: %s" blkname)
	(goto-char pos)
	(outline-show-entry)
	(recenter 0)))))

;; Code to handle command line arguments
(let* ((errpos (or (cl-position-if (lambda (x) (equal x "-error-handling")) command-line-args)
		   (cl-position-if (lambda (x) (equal x "--error-handling")) command-line-args)))
       (errval (if errpos (nth (+ 1 errpos) command-line-args)))
       (tagpos (or (cl-position-if (lambda (x) (equal x "-tag-match")) command-line-args)
		   (cl-position-if (lambda (x) (equal x "--tag-match")) command-line-args)))
       (tagval (if tagpos (nth (+ 1 tagpos) command-line-args))))
  (when errval
    (setq org-dotemacs-error-handling (intern errval))
    ;; now that they’ve been processed, remove the option
    ;; and value from command-line-args (as Emacs expects)
    (setcdr (nthcdr (1- errpos) command-line-args) (nthcdr (+ 2 errpos) command-line-args)))
  (when tagval
    (setq org-dotemacs-tag-match tagval)
    ;; same here
    (setcdr (nthcdr (1- tagpos) command-line-args) (nthcdr (+ 2 tagpos) command-line-args))))

(message "org-dotemacs: error-handling = %s" (concat "'" (symbol-name org-dotemacs-error-handling)))
(message "org-dotemacs: tag-match = %s" org-dotemacs-tag-match)

(provide 'org-dotemacs)

;; (magit-push)
;; (yaoddmuse-post "EmacsWiki" "org-dotemacs.el" (buffer-name) (buffer-string) "update")

;;; org-dotemacs.el ends here
