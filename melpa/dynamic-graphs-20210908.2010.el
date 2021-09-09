;;; dynamic-graphs.el --- Manipulation with graphviz graphs  -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2020, 2021  Tomas Zellerin
;;
;; Author: Tomas Zellerin <tomas@zellerin.cz>
;; Keywords: tools
;; Package-Commit: 64ca58dffecdecb636f7fe61c0c86e9c3c64d4dd
;; Package-Version: 20210908.2010
;; Package-X-Original-Version: 1.0
;; URL: https://github.com/zellerin/dynamic-graphs
;; Package-Requires: ((emacs "26.1"))
;;
;;
;; This program is free software; you can redistribute it and/or modify
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

;; Make dynamic graphs: take a graph (as defined for graphviz), apply
;; some filters, and display it as an image.  The graph can be either
;; a function that inserts the graph (and is called for each
;; redisplay), or a buffer that can change.  An imap file is created
;; in addition to the image so that clicks on image can be related to
;; individual nodes (TODO: only for rectangles so far)
;;
;; The filters can apply both enhancing operations (add colors, ...)
;; and more complicated operations coded in gvpr.  As a special case
;; there is a filter that removes all nodes that are more distant than
;; a parameter from a root node.
;;
;; The image is displayed with a specialized minor mode.
;; Predefined key bindings on the displayed image in this mode include:
;; - e (dynamic-graphs-set-engine) change grahviz engine (dot, circo, ...)
;; - c (dynamic-graphs-remove-cycles) change whether cycles are removed
;; - 1-9 (dynamic-graphs-zoom-by-key) set maximum displayed distance from a root node
;; - mouse-1 (dynamic-graphs-shift-focus-or-follow-link) shift root
;;   node or follow link defined in imap file - that is, in URL
;;   attribute of the node.  Link is followed by customizable
;;   function, by default `browse-url' - but
;;   `org-link-open-from-string' might be more useful.  See docstring
;;   for details.
;;
;; Example:
;;
;; (dynamic-graphs-display-graph "test" nil
;;		   (lambda ()
;;		     (insert "digraph Gr {A->B B->C C->A A->E->F->G}"))
;;		   '(2 remove-cycles "N {style=\"filled\",fillcolor=\"lightgreen\"}"
;;                   node-refs boxize))
;;
;;; Code:
;;
;;; Customizable variable
(require 'seq)
(require 'cl-lib)
(require 'view)
(require 'cus-edit)

(defcustom dynamic-graphs-filters '(3 default node-refs)
  "Default filter for dynamic-graphs.

This should be list of filters.

 Each filter can be:
- a string that denotes either name of a gvpr file to be applied or
  direct gvpr transformation,
- an integer that denotes that only nodes with distance from root less
  or equal to the number should be kept,
- symbol `remove-cycles' that causes cycles removal,

The variable is set buffer-local in the image buffers so that it can
be changed dynamically.

The default value somewhat arbitrarily sets kept distance to 3; this
applies only when a root is set."
  :group 'dynamic-graphs
  :type '(repeat
	  (choice (integer :tag "Maximum distance from root to keep")
		  (string :tag "gvpr code to apply")
		  (file :must-match t :tag "gvpr source file to apply")
		  (const :tag "Remove cycles in graph" remove-cycles)
		  (symbol :tag "Reference to dynamic-graphs-transformations"))))

(put 'dynamic-graphs-filters 'permanent-local t)

(defvar dynamic-graphs-engines
  '((?d "dot" "directed graphs")
    (?c "circo" "undirected graphs")
    (?n "neato" "radial layouts")
    (?t "twopi" "circular layout")
    (?f "fdp" "undirected graphs")
    (?s "sfdp" "large undirected graphs")
    (?o "osage" "squarified tree map")
    (?p "patchwork" "array based layouts"))
  "List of available Graphviz programs with intended usage.")

(defcustom dynamic-graphs-cmd "twopi"
  "Command to create final image."
  :group 'dynamic-graphs
  :type `(choice ,@(mapcar (lambda (a)
			     `(const  :tag ,(format "%s - %s" (cadr a) (caddr a)) ,(cadr a)))
			   dynamic-graphs-engines)))

(put 'dynamic-graphs-cmd 'permanent-local t)

(defcustom dynamic-graphs-image-directory (file-truename temporary-file-directory)
  "Directory for the created images."
  :group 'dynamic-graphs
  :type 'directory)

(defcustom dynamic-graphs-follow-link-fn 'browse-url
  "Function to follow links in the graphs.

I found `org-link-open-from-string' more useful than `browse-url', but if
I set it as default, I would have to make org mode a dependency."
  :type '(choice
	  (const :tag "Open as web" browse-url)
	  (const :tag "Open as org link" org-link-open-from-string)
	  (const :tag "Just display the link" (lambda (a) (message "%s" a)))
	  function)
  :group 'dynamic-graph)

(defvar dynamic-graphs-make-graph-fn
  (lambda () (error "Source of graph unknown, cant rebuild after change"))
  "Function that creates the displayed graph.")

(make-variable-buffer-local 'dynamic-graphs-make-graph-fn)
(put 'dynamic-graphs-filters 'permanent-local t)
(put 'dynamic-graphs-follow-link-fn 'permanent-local t)


(defvar-local dynamic-graphs-root nil
  "Root node for dijkstra algorithm if set.

The variable is set buffer-local in the image buffers so that it can
be changed dynamically.")

(defcustom dynamic-graphs-transformations
  '((boxize . "N {shape=\"box\"}")
    (node-refs . "N[!URL] {URL=sprintf(\"id:%s\", $.name)}")
    (default . "BEG_G{overlap=\"false\", fontname=\"Courier\"}
N[dist && dist==0.0]{style=\"filled\",fillcolor=\"yellow\",fontsize=\"22\"}"))
  "Named predefined transformations gvdr snippets or sources.

The names can be used in the `dynamic-graphs-filters' to make it more
manageable.

Predefined cases include:
- boxize :: sets nodes shape to box.  That is the only imap file the
  code can handle at the moment,
- default :: sample simple transformation used in the default filter.
  User is expected to customize it based on the preferences, or change
  it to a style file.
- node-refs :: add URL to each node based on its name.  This is needed
  for moving root around."
  :group 'dynamic-graphs
  :type '(alist :key-type symbol :value-type string))

(defcustom dynamic-graphs-ignore-ids ()
  "IDs that are ignored in graphs.

Work in progress, do not expect it to work now.

The variable is set buffer-local in the image buffers so that it can
be changed dynamically."
  :group 'dynamic-graphs
  :type '(repeat string))

;;; Helper functions
(defun dynamic-graphs-get-scale (image)
  "Get scale of the IMAGE."
  (let ((size (and image (image-size image t)))
	(src-type (if (member :file image) :file :data)))
    (if (and image
	     (eq (car image) 'image)
	     ;; 27.1 support
	     (or (and (fboundp 'image-transforms-p) (image-transforms-p))
		 (eq (plist-get (cdr image) :type) 'imagemagick)))
	;; see comment i n image.c for compute_image_size: -1 x -1 is
	;; native
	(let* ((full-image (create-image (plist-get (cdr image) src-type)
					 (plist-get (cdr image) :type)
					 (eq src-type :data)
					   :width -1 :height -1))
	       (full-size
		(progn (image-flush full-image)
		       (image-size full-image t))))
	  (/ (float (car full-size)) (car size)))
      1.0)))

(defun dynamic-graphs-cmd (name delete buffer &rest pars)
  "Apply command NAME with PARS as a filter on the current buffer.

If it fails, collect relevant data and throw an error.
DELETE and BUFFER are passed to CALL-PROCESS-REGION."
  (let* ((before (buffer-string))
	 (errfile (make-temp-file "dynamic-graphs-error"))
	 (res (apply #'call-process-region (point-min)
		     (point-max) name delete (list buffer errfile) pars)))
    (when
	;; Graphviz tools mostly return 1 on error
	;; however, acyclic returns 255
	;; and gvpr can print error, make empty output and return 0
	;; so I check whether there is some error output, but then
	;; without -q some dummy warnings are printed, so -q is needed.
	(or (and (equal name "gvpr")
		 (< 0 (file-attribute-size (file-attributes errfile))))
	    (and (>= res (if (equal name "acyclic") 255 1))))

      (let ((after (buffer-string)))
	(insert errfile) ; display something
	(switch-to-buffer "*dynamic-graph-source*")
	(delete-region (point-min) (point-max))
	(insert before)
	(view-mode)
	(switch-to-buffer "*dynamic-graph-result*" after)
	(delete-region (point-min) (point-max))
	(view-mode)
	(find-file-read-only errfile)
	(user-error
	 "Failed %s %s; see *dynamic-graph-source*, *dynamic-graph-result* and  %s for details" name (cdr pars) errfile)))
    (delete-file errfile)))

(defun dynamic-graphs-filter (name &rest pars)
  "Apply command NAME with PARS as a filter on the current buffer.

Throw error if it failed."
  (apply #'dynamic-graphs-cmd name t t nil pars))


(defun dynamic-graphs-apply-filters (filters)
  "Apply FILTERS on current buffer.

 See `dynamic-graphs-filters' for the syntax."
  (let ((root dynamic-graphs-root))
    (dolist (filter (or filters dynamic-graphs-filters))
      (when (symbolp filter)
	(setq filter
	      (or (cdr (assoc filter dynamic-graphs-transformations))
		  filter)))
      (cond
       ((and (stringp filter) (file-exists-p (expand-file-name filter)))
	(dynamic-graphs-filter "gvpr" "-qc" "-f" filter))
       ((and (stringp filter))
	(dynamic-graphs-filter "gvpr" "-qc"  filter))
       ((integerp filter)
	(when root
	  (dynamic-graphs-filter "dijkstra" root)
	  (dynamic-graphs-filter "gvpr" "-c" "-a" (format "%d.0" filter)
		"-q" "BEGIN{float maxdist; sscanf(ARGV[0], \"%f\", &maxdist)}
 N[!dist || dist >= maxdist] {delete(root, $)}")))
       ((eq filter 'remove-cycles)
	(dynamic-graphs-filter "acyclic")
	(dynamic-graphs-filter "tred"))
       ((and (consp filter)
	     (eq (car filter) 'ignore))
	(delete-matching-lines (regexp-opt (cdr filter))
			       (point-min) (point-max)))
       (t (error "Unknown transformation %s" filter)))))  )

(defun dynamic-graphs-create-outputs (suffixes &optional base-file-name root make-graph-fn filters)
  "Create files of types SUFFIXES.

The files are created in the `dynamic-graphs-image-directory'
directory named by the `BASE-FILE-NAME'.

The `MAKE-GRAPH-FN' inserts the original graph into the buffer.  The
graph is modified as specified by the list `FILTERS'.  See
`dynamic-graphs-filters' for the syntax.

The `ROOT', if not null, indicates the root node for cutting off far
nodes.

Finally, process the graph with variable `dynamic-graphs-cmd' to create
outputs with each of SUFFIXES type."
  (let ((cmd dynamic-graphs-cmd)
	(base-file-name (or base-file-name (file-name-base (buffer-name))))
	(root (or root dynamic-graphs-root))
	(make-graph-fn (or make-graph-fn dynamic-graphs-make-graph-fn))
	(filters (or filters dynamic-graphs-filters)))
    (with-temp-buffer
      (funcall make-graph-fn)
      (setq dynamic-graphs-root root)
      (dynamic-graphs-apply-filters filters)
      (dolist (type suffixes)
	(dynamic-graphs-cmd cmd
	      nil nil nil "-o" (concat dynamic-graphs-image-directory "/" base-file-name "." type) "-T" type))
      (buffer-string))))

(defvar dynamic-graphs-parsed nil
  "Parsed cmapx file, if available.")
(put 'dynamic-graphs-parsed 'permanent-local t)


(defun dynamic-graphs-rebuild-graph (base-file-name root make-graph-fn &optional filters)
  "Create png and imap files.

The files are created in the `dynamic-graphs-image-directory'
directory named by the `BASE-FILE-NAME'.

The `MAKE-GRAPH-FN' inserts the original graph into the buffer.  The
graph is modified as specified by the list `FILTERS'.  See
`dynamic-graphs-filters' for the syntax.

The `ROOT', if not null, indicates the root node for cutting off far
nodes.

Finally, process the graph with variable `dynamic-graphs-cmd' to
create image and imap file from the final graph.

Return the graph as the string (mainly for debugging purposes)."
  (let ((code (dynamic-graphs-create-outputs nil base-file-name root make-graph-fn filters))
	(cmd dynamic-graphs-cmd))
    (setq-local dynamic-graphs-parsed
	  (with-temp-buffer
	    (insert code)
	    (dynamic-graphs-cmd cmd t t nil "-T" "cmapx")
	    (let ((p (libxml-parse-xml-region (point-min) (point-max))))
	      (unless (eq (car p) 'map)
		(message "Cmapx parse unexpected situation: %s\n%s" p (buffer-string)))
	      nil
	      (cddr p))))
    code))

(defun dynamic-graphs-save-gv ()
  "Save current image in dot format as .gv file."
  (interactive)
  (dynamic-graphs-create-outputs '("gv")))

(defun dynamic-graphs-save-pdf ()
  "Save current image as .pdf file."
  (interactive)
  (dynamic-graphs-create-outputs '("pdf")))

(defun dynamic-graphs-rebuild-and-display (&optional base-file-name root make-graph-fn filters)
  "Redisplay the graph in the current buffer.

  Specifically set local values of some global parameters and run
  `dynamic-graphs-rebuild-graph' with appropriate arguments.

  Display the resulting png file or, when there is already a buffer
  with the file, redisplay.

Arguments `BASE-FILE-NAME', `ROOT', `MAKE-GRAPH-FN' and `FILTERS' are as
in `REBUILD-GRAPH'"
  (switch-to-buffer (concat base-file-name ".png")) ; just to be sure
  (let ((inhibit-read-only t))
    (delete-region (point-min) (point-max)))
  (set-buffer-multibyte t)
  (insert (dynamic-graphs-rebuild-graph base-file-name root make-graph-fn filters))
  (set-buffer-multibyte nil)
  (let ((coding-system-for-read 'no-conversion))
       (dynamic-graphs-filter dynamic-graphs-cmd "-T" "png")
       (image-mode))
     (setq-local dynamic-graphs-filters filters)
     (setq-local dynamic-graphs-root root)
     (setq-local dynamic-graphs-make-graph-fn make-graph-fn)
     (dynamic-graphs-graph-mode t))

;;;###autoload
(defun dynamic-graphs-display-graph (&optional base-file-name root make-graph-fn filters)
  "Display graph image and put it dynamic-graphs-mode on.

This is a shortcut for `dynamic-graphs-rebuild-graph' with defaulting
parameters.

All parameters - BASE-FILE-NAME ROOT MAKE-GRAPH-FN and FILTERS - are
optional with sensible defaults."
  (dynamic-graphs-rebuild-and-display (or base-file-name (file-name-base (buffer-name)))
			(or root dynamic-graphs-root)
			(or make-graph-fn dynamic-graphs-make-graph-fn)
			(or filters dynamic-graphs-filters)))

;;;###autoload
(defun dynamic-graphs-display-graph-buffer (root filters)
  "Make a dynamic graph from a graphviz buffer.

There is no default ROOT
node by default, and `dynamic-graphs-filters' - either default value or a
buffer-local if set, are used as default FILTERS when called
interactively."
  (interactive (list nil dynamic-graphs-filters))
  (let* ((buffer (current-buffer))
	 (buffer-directory (when (buffer-file-name buffer)
			     (expand-file-name (file-name-directory (buffer-file-name buffer))))))
    (dynamic-graphs-rebuild-and-display (file-name-base (buffer-name))
			  root
			  (lambda ()
			    (insert-buffer-substring buffer)
			    (when buffer-directory
			      (setq default-directory buffer-directory)))
			  filters)))

(defun dynamic-graphs--get-coords ()
  "Read coordinates from image so that they can be used in a map definition."
  (interactive)
  (let ((e (read-event "Click somewhere: ")))
    (let* ((scale (dynamic-graphs-get-scale (get-char-property (point-min) 'display)))
	   (pos (posn-x-y (event-start e)))
	   (x (* (car pos) scale))
	   (y (* (cdr pos) scale)))
      (message "%s %s" x y))))

;;; Mouse handlers (expect imap/cmapx file in place with proper structure)
(defun dynamic-graphs-get-rects-sexp (sexp x y)
  "Get reference related to the screen point X Y from the SEXP that describes node links."
  ;; SEXP is  (map ((id . XXX)) (area ((...)))...
  (with-temp-buffer
    (seq-some
     (lambda (item)
       (when (eq (car item) 'area)
	 (let-alist (cadr item)
	   (let ((coords (mapcar #'string-to-number (split-string  .coords ","))))
	     (if (and
		  (equal .shape "rect")
		  (> (nth 2 coords) x (nth 0 coords))
		  (> (nth 3 coords) y  (nth 1 coords)))
		 (cadr item))))))
     sexp)))

(defun dynamic-graphs-get-rects-imap (file x y)
  "Get reference related to the screen point X Y from the imap FILE.

To be used for existing imap files; note that cmapx format is
preferred and generated now."
  (when (file-readable-p file)
    (with-temp-buffer
      (insert-file-contents file)
      (goto-char 1)
      (let (res)
	(while (and (null res)
		    (re-search-forward (rx bol "rect "
					   (group (one-or-more nonl))
					   " " (group (one-or-more nonl))
					   "," (group (one-or-more nonl))
					   " " (group (one-or-more nonl))
					   "," (group (one-or-more nonl))
					   eol)
				       nil t))
	  (if (and
	       (> (string-to-number (match-string 4)) x (string-to-number (match-string 2)))
	       (> (string-to-number (match-string 5)) y (string-to-number (match-string 3))))
	      (setf res (match-string 1))))
	(list (cons 'href res))))))

(defun dynamic-graphs-get-rects-cmapx (file raw-x raw-y)
  "Get reference related to the screen point RAW-X RAW-Y from the cmapx FILE."
    (with-temp-buffer
      (insert-file-contents file)
      (let ((res (libxml-parse-xml-region (point-min) (point-max))))
	;; res is (map ((id . XXX)) (area ((...)))...
	(dynamic-graphs-get-rects-sexp (cddr res) raw-x raw-y))))

(defun dynamic-graphs-event-node (e)
  "Get a href value of an event E.

First a cmapx file and then imap file is tried to get the data.  The
coordinates are scaled to reflect image zooming."
  (let* ((pos (posn-x-y (event-start e)))
	 (base (and buffer-file-name (file-name-sans-extension buffer-file-name)))
	 (cmapx-file (and base (concat (file-name-sans-extension buffer-file-name) ".cmapx")))
	 (imap-file (and base (concat (file-name-sans-extension buffer-file-name) ".imap")))
	 (scale (dynamic-graphs-get-scale (get-char-property (point-min) 'display)))
	 (x (* (car pos) scale))
	 (y (* (cdr pos) scale)))
    (cond
     (dynamic-graphs-parsed (dynamic-graphs-get-rects-sexp dynamic-graphs-parsed x y))
     ;; If the entry was through dynamic-graphs entry points, :parsed
     ;; always exists. So following is needed only when we do not
     ;; start from the gv code.
     ((file-readable-p cmapx-file) (dynamic-graphs-get-rects-cmapx cmapx-file x y))
     ((file-readable-p imap-file) (dynamic-graphs-get-rects-imap imap-file x y))
     (t (error "Node map not found")))))

(defun dynamic-graphs-shift-focus-or-follow-link (e)
  "Follow link or shift root node.

If the node in image has id set (cmapx only) or URL in form of
\"id:something\", there is a specific `dynamic-graphs-make-graph-fn'
and this is first click, make it new root node.

Otherwise, follow the URL with the the `dynamic-graphs-follow-link-fn'.

Argument E is the event."
  (interactive "@e")
  (let-alist (dynamic-graphs-event-node e)
    (cond
;;; This does not work well: neither .id nor .title in general match
;;; node name. Would be nice to have it work, though.

;;     ((and (= (event-click-count e) 1))
;;      (when (and .href (sit-for 0.2 t))
;;	;; wait for second click
;;	(dynamic-graphs-display-graph (file-name-base) (or .alt .title))))
     ((and .href
	   (not (eql dynamic-graphs-make-graph-fn (default-value 'dynamic-graphs-make-graph-fn)))
	   (= (event-click-count e) 1)
	   (= 3 (cl-mismatch .href "id:")))
      (when (sit-for 0.2 t)
	;; wait for second click. What is proper variable for timing?
	(dynamic-graphs-display-graph (file-name-base (buffer-name)) (substring .href 3))))
     (.href (funcall dynamic-graphs-follow-link-fn .href)))))

;;; Key handlers
(defun dynamic-graphs-zoom-by-key (&optional keys)
  "Set distance to cut-off graph nodes based on the KEYS that invoked it."
  (interactive (list (this-command-keys)))
  (setq-local dynamic-graphs-filters
	      (mapcar (lambda (a) (if (integerp a)
				      (- (aref keys 0) 48)
				    a))
		      dynamic-graphs-filters))
  (dynamic-graphs-display-graph))

(defun dynamic-graphs-toggle-cycles ()
  "Toggle whether cycles should be broken."
  (interactive)

  (setq-local dynamic-graphs-filters
	      (if (member 'remove-cycles dynamic-graphs-filters)
		  (remove 'remove-cycles dynamic-graphs-filters)
		(append dynamic-graphs-filters '(remove-cycles))))
  (dynamic-graphs-display-graph))

(defun dynamic-graphs-clean-root ()
  "Clean root to display full graph."
  (interactive)
  (setq dynamic-graphs-root nil)
  (dynamic-graphs-display-graph)  )

(defun dynamic-graphs-set-engine (&optional engine)
  "Locally set ENGINE for graph creation."
  (interactive (cdr (read-multiple-choice "Engine: "
					  (mapcar (lambda (a) `(,(car a) ,(cadr a))) dynamic-graphs-engines))))
  (setq-local dynamic-graphs-cmd engine)
  (dynamic-graphs-display-graph))

;;; Minor mode with handlers
(defvar dynamic-graphs-keymap
  (let ((km (make-sparse-keymap)))
    (define-key km [mouse-1] 'dynamic-graphs-shift-focus-or-follow-link)
    (define-key km "1" 'dynamic-graphs-zoom-by-key)
    (define-key km "2" 'dynamic-graphs-zoom-by-key)
    (define-key km "3" 'dynamic-graphs-zoom-by-key)
    (define-key km "4" 'dynamic-graphs-zoom-by-key)
    (define-key km "5" 'dynamic-graphs-zoom-by-key)
    (define-key km "6" 'dynamic-graphs-zoom-by-key)
    (define-key km "7" 'dynamic-graphs-zoom-by-key)
    (define-key km "8" 'dynamic-graphs-zoom-by-key)
    (define-key km "9" 'dynamic-graphs-zoom-by-key)
    (define-key km "c" 'dynamic-graphs-toggle-cycles)
    (define-key km "e" 'dynamic-graphs-set-engine)
    (define-key km "!" 'dynamic-graphs-save-gv)
    (define-key km "p" 'dynamic-graphs-save-pdf)
    (define-key km "/" 'dynamic-graphs-clean-root)
    (define-key km "?" 'dynamic-graphs-help)
    (define-key km "ds" 'dynamic-graphs-add-filter-string)
    (define-key km "dp" 'dynamic-graphs-pop-filter)
    (define-key km "dd" 'dynamic-graphs-add-predefined-filter)
    (define-key km "C" 'dynamic-graphs-customize-locals)
    (define-key km "d0" 'dynamic-graphs-clean-filters)

    km))

(define-minor-mode dynamic-graphs-graph-mode "Local mode for dynamic images.

Allows shift focus to a different mode, and zoom in or zoom out
to see less or more distant nodes.

\\{dynamic-graphs-keymap}" nil "(dyn)" dynamic-graphs-keymap
(setq-local revert-buffer-function (lambda (_a _b)
				     (dynamic-graphs-display-graph))))

(defun dynamic-graphs-help ()
  "Experimental: show alt texts or href on nodes."
  (interactive)
  (track-mouse
    (let ((event))
      (while (and
	      (setq event (read-event))
	      (mouse-movement-p event))
	(let-alist (dynamic-graphs-event-node event)
	  (when (and (or .alt .href)
		     (sit-for 0.3))
	    (tooltip-show (or (and (> (length .alt) 0) .alt) .href))))))))

(defun dynamic-graphs-add-filter-string (filter)
  "Add new filter string `FILTER` to current buffer list of filters."
  (interactive "sGvpr code: ")
  (push filter dynamic-graphs-filters)
  (dynamic-graphs-display-graph))

(defcustom dynamic-graphs-filter-string ""
  "GVPR code to be applied by next `dynamic-graphs-apply-filter'.

May be edited by `customize-variable`.

May be set by `dynamic-graphs-pop-filter'.

Can be reapplied by `dynamic-graphs-reapply-filter`.  This is NOT buffer local by design."
  :group 'dynamic-graphs
  :type 'string)

(defun dynamic-graphs-pop-filter ()
  "Remove most recent filter from current buffer list of filters.

The removed filter is stored to `dynamic-graphs-filter-string` so that it can be edited or reapplied."
  (interactive)
  (setq dynamic-graphs-filter-string   (pop dynamic-graphs-filters))
  (dynamic-graphs-display-graph)
  (message "Popped %s" dynamic-graphs-filter-string))

(defun dynamic-graphs-apply-filter ()
  "Add `dynamic-graphs-filter-string` in current buffer."
  (interactive)
  (push dynamic-graphs-filter-string dynamic-graphs-filters )
  (dynamic-graphs-display-graph))

(defun dynamic-graphs-add-predefined-filter (filter)
  "Add a predefined (in `dynamic-graphs-transformations`) filter `FILTER` to the current image."
  (interactive (list (intern
		      (completing-read "Add filter: " (mapcar #'car dynamic-graphs-transformations)
				       nil t))))
  (push filter dynamic-graphs-filters)
  (dynamic-graphs-display-graph))

(defun dynamic-graphs-clean-filters ()
  "Set list of filters to default one."
  (interactive)
  (setq-local dynamic-graphs-filters (default-value 'dynamic-graphs-filters))
  (dynamic-graphs-display-graph))

(defun dynamic-graphs--make-widget (buffer tag variable &optional type)
  "Create a widget for local setting of a VARIABLE in the BUFFER.

Prefix it in the current buffer with TAG, and use TYPE for the
widget; if not set, derive it from the customization type of VARIABLE."
  (widget-create
   (or type (custom-variable-type variable))
   :value (with-current-buffer buffer (symbol-value variable))
   :tag tag
   :notify (lambda (widget &rest _ignore)
	     (with-current-buffer buffer
	       (set variable (widget-value widget)))))
  (widget-insert "\n"))

(defun dynamic-graphs-customize-locals ()
  "Customize local setings for dynamic-graphs."
  (interactive)
  (let ((buffer-to-customize (current-buffer)))
    (switch-to-buffer-other-window "*Dynamic graphs local config*")
    (kill-all-local-variables)
    (let ((inhibit-read-only t))
      (erase-buffer))
    (remove-overlays)

    (dynamic-graphs--make-widget buffer-to-customize "On double click" 'dynamic-graphs-follow-link-fn)
    (dynamic-graphs--make-widget buffer-to-customize "Command to display" 'dynamic-graphs-cmd)
    (dynamic-graphs--make-widget buffer-to-customize "Root node" 'dynamic-graphs-root '(choice (const :tag "None" nil) string))
    (dynamic-graphs--make-widget buffer-to-customize "Filters used" 'dynamic-graphs-filters)
    (widget-create 'push-button
		   :tag "Apply"
		   :notify (lambda (&rest _ignore)
			     (save-current-buffer
			       (pop-to-buffer buffer-to-customize)
			       (dynamic-graphs-display-graph)))))
  (use-local-map widget-keymap)
  (widget-setup))


(provide 'dynamic-graphs)
;;; dynamic-graphs.el ends here
