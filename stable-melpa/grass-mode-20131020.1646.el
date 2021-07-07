;;; grass-mode.el --- Provides Emacs modes for interacting with the GRASS GIS program

;; Copyright (C) Tyler Smith 2013

;; Author: Tyler Smith <tyler@plantarum.ca>
;; Version: 0.1
;; Package-Version: 20131020.1646
;; Package-Commit: 23ca856ca979fec0f90196b357f2b74fe1cc3a73
;; Package-Requires: ((cl-lib "0.2"))
;; Keywords: GRASS, GIS

;; This file is not part of GNU Emacs

;; grass-mode is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; grass-mode is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with grass-mode (see the file COPYING).  If not, see
;; <http://www.gnu.org/licenses/>. 

;;; Commentary:

;; To install, put grass-mode.el in your load path and add 
;; (require 'grass-mode) to your .emacs.

;; Check the customization options in the grass-mode group to make sure
;; Emacs can find your Grass exectuables and help files.

;;; TODO:

;; Make w3m customizations into a minor-mode
;; History browser?
;; per-location logging?
;; per-location scripting support (add to exec-path)?
;; add completion for flags as well as parameters

;;;;;;;;;;;;;;;;;;
;; Dependencies ;;
;;;;;;;;;;;;;;;;;;

(require 'shell)
(require 'cl-lib) 

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customization Variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defgroup grass-mode nil 
  "Running GRASS GIS from within an Emacs buffer."
  :group 'Programming
  :group 'External
  :version "0.1")

;;;###autoload
(define-widget 'grass-program-alist 'lazy
  "Format of `grass-grass-program-alist'."
  :type '(repeat (group (string :tag "Program name (user-readable)")
                        (file :tag "GRASS executable")
                        (directory :tag "Script directory")
                        (directory :tag "HTML documentation directory"))))

;;;###autoload
(defcustom grass-grass-programs-alist 
  '(("Grass64" "/usr/bin/grass" "/usr/lib/grass64" "/usr/share/doc/grass-doc/html"))
  "Alist of grass programs with their binary, script directory, and documentation directory. 
Elements are lists (PROGRAM-NAME BINARY SCRIPT-DIRECTORY DOC-DIRECTORY). PROGRAM-NAME is
the name of the binary as it will be presented to the user. BINARY is the full path to the
GRASS program. SCRIPT-DIRECTORY is the directory where all the GRASS commands are found.
DOC-DIRECTORY is the directory where the HTML help files are found."
  :type 'grass-program-alist
  :group 'grass-mode
  :tag "Grass programs alist")

;;;###autoload
(defcustom grass-completion-file
            (locate-user-emacs-file "grass-completions")
            "Default name of file to store completion table in."
            :type 'file)

;;;###autoload
(defcustom grass-grassdata "~/grassdata"
  "The directory where grass locations are stored."
  :tag "grassdata"
  :group 'grass-mode)

;;;###autoload
(defcustom grass-default-location nil
  "The default starting location."
  :group 'grass-mode)

;;;###autoload
(defcustom grass-default-mapset "PERMANENT"
  "The default starting mapset."
  :group 'grass-mode)

;;;###autoload
(defcustom grass-prompt "$LOCATION_NAME:$MAPSET> "
  "String to format the Grass prompt.
$LOCATION_NAME expands to the name of the grass location.
$MAPSET expands to the name of the grass location.
Normal bash prompt expansions are available, such as:
\\w - the current working directory
\\W - the  basename  of the current working directory"
  :link '(url-link :tag "Bash Prompt Escapes"
                   "http://tldp.org/HOWTO/Bash-Prompt-HOWTO/bash-prompt-escape-sequences.html") 
  :group 'grass-mode)

;;;###autoload
(defcustom grass-prompt-2 "> "
  "String to format the Grass continuation-line prompt, PS2.
The same formatting options from grass-prompt are available."
  :group 'grass-mode)

;;;###autoload
(defcustom grass-log-dir (concat grass-grassdata "/logs")
  "The default directory to store interactive grass session logs.
Set this to nil to turn off logging."
  :group 'grass-mode
  :set-after '(grass-grassdata))

;;;###autoload
(defcustom grass-help-w3m nil 
  "If non-nil, use w3m to browse help docs within Emacs. Otherwise, use
browse-url. w3m must be installed separately in your Emacs to use this!"
  :type 'boolean
  :require 'w3m
  :group 'grass-mode
  :set 'grass-set-w3m-help)

(defvar igrass-mode-hook nil)
(defvar sgrass-mode-hook nil)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;      Global Variables       ;;
;; (shouldn't be set by users) ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar grass-location 
  nil "The currently active grass location")

(defvar grass-process 
  nil "The active Grass process")

(defvar grass-mapset 
  nil "The currently active grass mapset")

(defvar grass-help 
  nil "The buffer where the grass help is found")

(defvar grass-gisbase 
  nil "The top-level directory containing bin and scripts directories")

(defvar grass-program 
  nil "The grass executable")

(defvar grass-doc-dir 
  nil "The location of the Grass html documentation")

(defvar grass-name 
  nil "The user's nickname for the active grass program")

(defvar grass-commands 
  nil "The command-completion table for the currently active grass program")

(defvar grass-doc-files 
  nil "The list of Grass help files")

(defvar grass-doc-table 
  nil "The completion-list for grass help files")

(defvar grass-mode-keywords 
  nil "Keywords to use for keyword font lock in grass mode")

(defvar grass-completion-lookup-table nil
  "You don't really want to muck about with this by hand.
If you want to change it, please use `grass-flush-completions' 
and `grass-redo-completions'.")

(defvar grass-command-updates 
      '(((("v.proj" "input")) grass-complete-foreign-vectors)
        ((("r.proj" "input")) grass-complete-foreign-rasters)
        ((("g.mapset" "mapset") ("r.proj" "mapset")
          ("v.proj" "mapset")) grass-complete-foreign-mapsets)
        ((("g.proj" "location") ("g.mapset" "location")
          ("r.proj" "location") ("v.proj" "location")) grass-location-list)
        ((("g.region" "region")) grass-regions)
        ((("d.rast" "map") ("g.remove" "rast") ("g.region" "rast") ("g.rename" "rast")
          ("r.patch" "input") ("r.colors" "map") 
          ("r.shaded.relief" "map") ;; Grass64
          ("r.shaded.relief" "input") ;; Grass70
          ("r.mask" "input") ("r.null" "map") ("r.resample" "input") ("r.out.ascii" "input") 
          ("r.report" "map") ("r.reclass" "input") ("r.stats" "input") ("r.univar" "map"))
         grass-raster-maps) 
        ((("d.vect" "map") ("d.extract" "input") ("d.path" "map") ("d.vect.chart" "map")
          ("d.vect.thematic" "map") ("d.what.vect" "map") ("d.zoom" "vector") 
          ("g.rename" "vect") ("g.remove" "vect") ("g.region" "vect")
          ("r.carve" "vect") ("r.drain" "vector_points") ("r.le.setup" "vect") 
          ("r.region" "vector") ("r.volume" "centroids") 
          ("v.buffer" "input") ("v.build" "map") ("v.build.polylines" "input")
          ("v.category" "input") ("v.centroids" "input") ("v.class" "map")
          ("v.clean" "input") ("v.colors" "map") ("v.convert" "input")
          ("v.db.addcol" "map") ("v.db.addtable" "map") ("v.db.connect" "map")
          ("v.db.dropcol" "map") ("v.db.droptable" "map") ("v.db.join" "map")
          ("v.db.renamecol" "map") ("v.db.select" "map") ("v.db.update" "map")
          ("v.delaunay" "input") ("v.digit" "map") ("v.dissolve" "input")
          ("v.distance" "to") ("v.distance" "from") ("v.drape" "input")
          ("v.edit" "bgmap") ("v.edit" "map") ("v.extract" "input")
          ("v.extrude" "input") ("v.generalize" "input") ("v.hull" "input")
          ("v.info" "map") ("v.kcv" "input") ("v.kernel" "net") ("v.kernel" "input")
          ("v.label" "map") ("v.label.sa" "map") ("v.lidar.correction" "input")
          ("v.lidar.edgedetection" "input") ("v.lidar.growing" "input")
          ("v.lrs.create" "points") ("v.lrs.create" "in_lines") ("v.lrs.label" "input") 
          ("v.lrs.segment" "input") ("v.lrs.where" "points") ("v.lrs.where" "lines") 
          ("v.neighbors" "input") ("v.net.alloc" "input") ("v.net" "points") 
          ("v.net" "input") ("v.net.iso" "input") ("v.net.path" "input") 
          ("v.net.salesman" "input") ("v.net.steiner" "input") ("v.net.visibility" "input") 
          ("v.normal" "map") ("v.out.ascii" "input") ("v.out.dxf" "input") 
          ("v.out.gpsbabel" "input") ("v.out.ogr" "input") ("v.out.pov" "input") 
          ("v.out.svg" "input") ("v.out.vtk" "input") ("v.outlier" "qgis") 
          ("v.outlier" "input") ("v.overlay" "binput") ("v.overlay" "ainput") 
          ("v.parallel" "input") ("v.patch" "input") ("v.rast.stats" "vector")
          ("v.reclass" "input") ("v.report" "map") ("v.sample" "input")
          ("v.segment" "input") ("v.select" "binput") ("v.select" "ainput")
          ("v.split" "input") ("v.support" "map") ("v.surf.bspline" "sparse")
          ("v.surf.bspline" "input") ("v.surf.idw" "input") ("v.surf.rst" "input")
          ("v.to.3d" "input") ("v.to.db" "map") ("v.to.points" "input")
          ("v.to.rast" "input") ("v.to.rast3" "input") ("v.transform" "input")
          ("v.type" "input") ("v.univar" "map") ("v.vol.rst" "input")
          ("v.voronoi" "input") ("v.what" "map") ("v.what.rast" "vector")
          ("v.what.vect" "vector")) 
         grass-vector-maps)
        ((("db.columns" "table")) grass-all-maps))
      "Modifications to the completion table, adding specialized look-up functions")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Initialization functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Completion setup ;;;

;; Code to use for saving the completion table:
(defun grass-write-completions-to-file ()
  "Write grass-completion-lookup-table to grass-completion-file
http://stackoverflow.com/questions/2321904/elisp-how-to-save-data-in-a-file/2322164#2322164"
  (save-excursion
    (let ((buf (find-file-noselect grass-completion-file)))
      (set-buffer buf)
      (erase-buffer)
      (grass-dump (list 'grass-completion-lookup-table) buf)
      (save-buffer)
      (kill-buffer))))
        

(defun grass-dump (varlist buffer)
  "insert into buffer the setq statement to recreate the variables in VARLIST"
  (cl-loop for var in varlist do
        (print (list 'setq var (list 'quote (symbol-value var)))
               buffer)))

(defun grass-read-completions ()
  "Reads the grass-completion-lookup-table from file.
If the file doesn't exist, offer to reparse the commands."
  (if (not (file-exists-p grass-completion-file))
      (if (yes-or-no-p 
           "Command completion file does not exist. Generate one now? (This will
take several minutes)")
          (grass-add-completions grass-name)
        (message "Command completion unavailable"))
    (load-file grass-completion-file)
    (if (not (assoc grass-name grass-completion-lookup-table))
        (if (yes-or-no-p 
             "Command completion table does not exist. Generate one now? (This will
take several minutes)")
            (grass-add-completions grass-name)
          (message "Command completion unavailable"))
      (setq grass-commands 
            (cadr (assoc grass-name grass-completion-lookup-table))))))

(defun grass-parse-command-list ()
  "Run each grass binary with the --interface-description option, parsing the output to
  generate the completion data for grass-command.

  The return value, used for grass-commands, is a list of the form:

  ((command-one
     ((parameter-one (value1 value2)) 
      (parameter-two nil)))
   (command-two nil))

  Commands with no parameters have a cdr of nil. Parameters without a fixed list of
  possible values get a cdr of nil."

  (let* ((bin-dir (concat grass-gisbase "/bin/"))
         (bins 
          ;;(remove "r.mapcalc"
          ;;(remove "r3.mapcalc" 
          (remove "g.parser" (directory-files bin-dir)))
         ;; g.parser has no interface description in 7.0, FFS!
         ;; r.mapcalc and r3.mapcalc don't have i-d in 6.4
         command-list)
    
    (dolist (bin (cddr bins))           ; drop the '.' and '..' entries
      (push
       (grass-get-bin-params bin)
       command-list))
    (message "parsing complete, storing result...")
    command-list))

(defun grass-get-bin-params (bin)
  "Run bin with the option --interface-description, parsing the output to produce a single
  list element for use in grass-commands. See grass-parse-command-list"
  (let* ((counter 0)
         (help-file (make-temp-file (concat "grass-mode-" bin)))
         (intdesc 
          (progn 
            (message "parsing %s" bin)
            (process-send-string grass-process 
                                 (concat bin " --interface-description > "
                                         help-file "\n")) 
            (while (and (< counter 5)
                        (< (nth 7 (file-attributes help-file)) 1))
              (sleep-for 1)
              (cl-incf counter))
            (if (< counter 5)
                (with-temp-buffer 
                  (insert-file-contents help-file)
                  (delete-file help-file)
                  (libxml-parse-xml-region (point-min) (point-max)))
              (message "%s parsing failed!!" bin)
              nil))))
    (if intdesc
        (list bin
              (let (par-list)
                (dolist (el (cdr intdesc))
                  (if (eq (car el) 'parameter)
                      (push (list (cl-cdaadr el)
                                  (if (assoc 'values el)
                                      (let (val-list)
                                        (dolist (vals (cddr (assoc 'values el)))
                                          (push (cl-caddr (cl-caddr vals)) 
                                                val-list))
                                        val-list))) 
                            par-list)))
                par-list)))))

(defun grass-update-completions (grass-prog com-param-compl)
  "Set the COMPLetion string/function for the PARAMeter of COMmand.
`com-param-compl' is a list, each element is a list of the form (com-param compl).
`com-param' is a list, each element is a list of the form (com param)."

  (message "updating completions...")
  (dolist (com-param com-param-compl)
    (dolist (p (car com-param))
      (if (assoc (cl-second p) 
                 (cadr 
                  (assoc (cl-first p) 
                         (cadr (assoc grass-prog grass-completion-lookup-table)))))
          (setcdr
           (assoc (cl-second p) 
                  (cadr 
                   (assoc (cl-first p) 
                          (cadr (assoc grass-prog grass-completion-lookup-table)))))
           (cdr com-param))))))

(defun grass-flush-completions ()
  "Clears the completion table for the current grass-program"
  (interactive)
  (grass-clear-completions grass-name))

(defun grass-redo-completions ()
  "Resets the completion table for the current grass-program"
  (interactive)
  (grass-flush-completions)
  (grass-add-completions grass-name))

(defun grass-clear-completions (prog)
  "Clears the completion table associated with the binary named `prog'.
prog is the user-readable name from `grass-program-alist'"
  (setq grass-completion-lookup-table 
        (remove (assoc prog grass-completion-lookup-table)
                grass-completion-lookup-table))
  (grass-write-completions-to-file))

(defun grass-add-completions (prog)
  "Generate and save the completion table for the binary named `prog' in
grass-program-alist."
  (process-send-string grass-process "\n")
  (push (list prog
              (grass-parse-command-list))
        grass-completion-lookup-table)
  (grass-update-completions prog grass-command-updates)
  (grass-write-completions-to-file)
  (setq grass-commands 
        (cadr (assoc grass-name grass-completion-lookup-table))))

;;; User prompts ;;;

(defun grass-get-location ()
  "Prompt the user for the location."
  (assoc (completing-read
          (format "Grass location (%s): " grass-default-location)
          (grass-location-list) nil t nil nil grass-default-location)
         (grass-location-list)))

(defun grass-get-mapset ()
  "Prompt the user for the mapset for the current location."
  (completing-read (format "Grass mapset (%s): " grass-default-mapset)
                   (grass-mapset-list) nil t nil nil grass-default-mapset))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Completion Utilities ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun grass-vector-maps (&optional location mapset)
  "Returns a list of all the vector maps in location and mapset.
Defaults to the current location and mapset."
  (let ((loc (if location location grass-location))
        (mapst (if mapset mapset grass-mapset)))
    (let ((map-dir (concat (cdr loc) "/" mapst)))
      (if (member "vector" (directory-files map-dir))
          (directory-files (concat map-dir "/" "vector") nil "^[^.]")))))

(defun grass-raster-maps (&optional location mapset)
  "Returns a list of all the raster maps in location and mapset.
Defaults to the current location and mapset." 
  (let ((loc (if location location grass-location))
        (mapst (if mapset mapset grass-mapset)))
    (let ((map-dir (concat (cdr loc) "/" mapst)))
      (if (member "cell" (directory-files map-dir))
          (directory-files (concat map-dir "/" "cell") nil "^[^.]")))))

(defun grass-all-maps (&optional location mapset)
  "Returns a list of all maps, raster and vector.
Defaults to the current location & mapset"
  (let ((loc (if location location grass-location))
        (mapst (if mapset mapset grass-mapset)))
    (let ((map-dir (concat (cdr loc) "/" mapst)))
      (append (if (member "vector" (directory-files map-dir))
                  (directory-files (concat map-dir "/" "vector") nil "^[^.]"))
              (if (member "cell" (directory-files map-dir))
                  (directory-files (concat map-dir "/" "cell") nil "^[^.]"))))))

(defun grass-complete-foreign-mapsets()
  "Returns a list of all the vector maps in a different location and mapset"
  (let ((f-loc 
         (assoc (save-excursion
                  (comint-bol)
                  (if (search-forward "location=" nil t) 
                      (buffer-substring-no-properties (point)
                                                      (progn (skip-syntax-forward "^ ")
                                                             (point)))))
                (grass-location-list))))
    (if f-loc
        (grass-mapset-list f-loc))))

(defun grass-complete-foreign-vectors()
  "Returns a list of all the vector mapsets in a different location"
  (let ((f-loc 
         (assoc (save-excursion
                  (comint-bol)
                  (if (search-forward "location=" nil t) 
                      (buffer-substring-no-properties (point)
                                                      (progn (skip-syntax-forward "^ ")
                                                             (point)))))
                (grass-location-list)))
        (f-map (save-excursion
                 (comint-bol)
                 (if (search-forward "mapset=" nil t)
                     (buffer-substring-no-properties (point)
                                                     (progn (skip-syntax-forward "^ ")
                                                            (point)))))))
    (if (and f-loc f-map)
        (grass-vector-maps f-loc f-map))))

(defun grass-complete-foreign-rasters()
  "Returns a list of all the raster mapsets in a different location"
  (let ((f-loc 
         (assoc (save-excursion
                  (comint-bol)
                  (if (search-forward "location=" nil t) 
                      (buffer-substring-no-properties (point)
                                                      (progn (skip-syntax-forward "^ ")
                                                             (point)))))
                (grass-location-list)))
        (f-map (save-excursion
                 (comint-bol)
                 (if (search-forward "mapset=" nil t)
                     (buffer-substring-no-properties (point)
                                                     (progn (skip-syntax-forward "^ ")
                                                            (point)))))))
    (if (and f-loc f-map)
        (grass-raster-maps f-loc f-map))))

(defun grass-foreign-vectors()
  "Returns a list of all the vector maps in a different location and mapset"
  (interactive)
  (let ((f-loc (grass-get-location))
        (f-map (grass-get-mapset)))
    (grass-vector-maps f-loc f-map)))

(defun grass-regions (&optional location mapset)
  "List the saved regions for a location and mapset
Defaults to the currently active location and mapset."
  (let ((loc (if location location grass-location))
        (mapst (if mapset mapset grass-mapset)))
    (let ((map-dir (concat (cdr loc) "/" mapst)))
      (if (member "windows" (directory-files map-dir))
          (directory-files (concat map-dir "/" "windows") nil "^[^.]")))))

(defun grass-location-list ()
  "Return an alist of grass locations"
  (when grass-grassdata
    (let* ((location-dirs 
            (cl-remove-if-not 'file-directory-p
                           (directory-files grass-grassdata t "^[^.]")))
           (location-names
            (mapcar 'file-name-nondirectory location-dirs)))
      ;;(grass-mapcar* #'(lambda (x y) (cons x y))
      (cl-mapcar #'(lambda (x y) (cons x y))
                     location-names location-dirs))))

(defun grass-mapset-list (&optional location)
  "List the mapsets for a location, defaulting to the current location."
  (let ((loc (if location
                 location
               grass-location)))
    (mapcar 'file-name-nondirectory
            (cl-remove-if-not 'file-directory-p
                           (directory-files
                            (cdr loc) t "^[^.]")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main completion functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun grass-completion-at-point ()
  (interactive)
  (let ((pt (point))
        start end)
    (save-excursion                     ;; backup to beginning of multi-line command
      (while (progn (beginning-of-line)
                    (looking-at grass-prompt-2))
        (forward-line -1))
      (comint-bol)
      ;; skip over the first token:
      (re-search-forward "\\(\\S +\\)\\s ?" nil t) 

      ;; the match-string is the current command, so if pt is within
      ;; this command, we haven't finished entering it:
      (if (and (>= pt (match-beginning 1))
               (<= pt (match-end 1)))
          ;; still entering the initial command, so try completing Grass commands
          (progn
            (goto-char pt)
            (let* ((bol (save-excursion (comint-bol) (point)))
                   (eol (save-excursion (end-of-line) (point)))
                   (start (progn (skip-syntax-backward "^ " bol)
                                 (point)))
                   (end (progn (skip-syntax-forward "^ " eol)
                               (point))))
              (list start end grass-commands :exclusive 'no))) 
        ;; if this fails, control passes to comint-completion-at-point

        ;; we have a complete command, so lookup parameters in the
        ;; grass-commands table:
        (let ((command (match-string-no-properties 1)))
          (when (cl-member command grass-commands :test 'string= :key 'car)
            (goto-char pt)
            (skip-syntax-backward "^ ")
            (setq start (point))
            (skip-syntax-forward "^ ")
            (setq end (point))
            (if (not (string-match "=" (buffer-substring start end)))
                (list start end (cadr (assoc command grass-commands)) :exclusive 'no)
              (grass-complete-parameters
               command 
               (buffer-substring start (search-backward "="))
               (progn
                 (goto-char pt)
                 (re-search-backward "=\\|,")
                 (forward-char)
                 (point))
               (progn (skip-syntax-forward "^ ") (point))))))))))

(defun igrass-complete-commands ()
  "Returns the list of grass programs. I don't know why, but comint-complete finds some
  but not all of them?"
  (save-excursion
    (let* ((bol (save-excursion (comint-bol) (point)))
           (eol (save-excursion (end-of-line) (point)))
           (start (progn (skip-syntax-backward "^ " bol)
                         (point)))
           (end (progn (skip-syntax-forward "^ " eol)
                       (point))))
      (list start end grass-commands :exclusive 'no))))

(defun grass-complete-parameters (command parameter start end)
  (let ((collection (cl-second (assoc parameter (cadr (assoc command grass-commands))))))
    (list start end 
          (if (functionp collection)
              (funcall collection)
            collection) 
          :exclusive 'no)))

(defun sgrass-complete-commands ()
  (save-excursion
    (let* ((bol (save-excursion (beginning-of-line) (point)))
           (eol (save-excursion (end-of-line) (point)))
           (start (progn (skip-syntax-backward "^ " bol)
                         (point)))
           (end (progn (skip-syntax-forward "^ " eol)
                       (point))))
      (list start end grass-commands :exclusive 'no))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Starting Grass and the modes ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun grass ()
  "Start the Grass process, or switch to the process buffer if it's
already active." 
  (interactive)

  ;; initializations
  (setenv "GRASS_PAGER" "cat")
  (setenv "GRASS_VERBOSE" "0")

  (let ((grass-prog 
         (if (> (length grass-grass-programs-alist) 1)
             (assoc (completing-read "Grass program? " grass-grass-programs-alist)
                    grass-grass-programs-alist)
           (car grass-grass-programs-alist))))

    (setq grass-name (nth 0 grass-prog)
          grass-program (nth 1 grass-prog)
          grass-gisbase (nth 2 grass-prog)
          grass-doc-dir (nth 3 grass-prog)))

  (setq grass-doc-files         ; The list of grass help files
        (delete nil (mapcar #'(lambda (x) 
                                (if (string-match-p "html$" x)
                                    x))
                            (directory-files grass-doc-dir)))
        grass-doc-table)
  
  (mapc #'(lambda (x) 
            (push (cons (substring x 0 -5)
                        (concat grass-doc-dir "/" x)) grass-doc-table))
        grass-doc-files)

  ;; Don't modify the path more than once!
  (unless (member (concat grass-gisbase "/bin") exec-path)
    (add-to-list 'exec-path (concat grass-gisbase "/bin") t))
  (unless (member (concat grass-gisbase "/scripts") exec-path)
    (add-to-list 'exec-path (concat grass-gisbase "/scripts") t))

  ;; Start a new process, or switch to the existing one
  (unless (and (processp grass-process)
               (buffer-name (process-buffer grass-process)))
    (setq grass-location (grass-get-location))
    (setq grass-mapset (grass-get-mapset))
    (setq grass-process (start-process "grass" (concat "*" grass-name "*") grass-program "-text"
                                       (concat  (file-name-as-directory
                                                 (cdr grass-location)) 
                                                grass-mapset ))))

  (grass-read-completions)

  (if (boundp 'grass-commands)
      (setq grass-mode-keywords 
            (list (cons (concat "\\<" (regexp-opt (mapcar 'car grass-commands)) "\\>")
                        font-lock-keyword-face))))

  (switch-to-buffer (process-buffer grass-process))
  (set-process-window-size grass-process (window-height) (window-width))
  (comint-send-string grass-process
                      (format "eval `g.gisenv`\nexport PS2=\"%s\"\n"
                              grass-prompt-2))
  (grass-update-prompt)
  (set-process-filter grass-process 'comint-output-filter)
  (igrass-mode)
  (add-hook 'completion-at-point-functions 'igrass-complete-commands nil t)
  (add-hook 'completion-at-point-functions 'grass-completion-at-point nil t))

(defun comint-fix-window-size ()
  "Change process window size. Used to update process output when Emacs window size changes."
  (when (derived-mode-p 'comint-mode)
    (set-process-window-size (get-buffer-process (current-buffer))
                             (window-height)
                             (window-width))))

(define-derived-mode igrass-mode shell-mode "igrass"
  "Major mode for interacting with a Grass in an inferior
process.\\<igrass-mode-map> \\[comint-send-input] after the end of the
process' output sends the text from the end of process to the end of
the current line. 

\\{igrass-mode-map}"

  ;; Removing '=' from comint-file-name-chars enables file-name
  ;; completion for parameters, e.g., v.in.ascii input=... This may
  ;; cause problems in cases where '=' is part of the file name.

  (unless (memq system-type '(ms-dos windows-nt cygwin))
    (make-local-variable 'comint-file-name-chars)
    (setq comint-file-name-chars
          "[]~/A-Za-z0-9+@:_.$#%,{}-"))

  ;;(setq comint-prompt-regexp "^[^#$%>\n]*[#$%>] +") ;; no longer necessary?
  (define-key igrass-mode-map (kbd "C-c C-v") 'grass-view-help)
  (define-key igrass-mode-map (kbd "C-a") 'comint-bol)
  (define-key igrass-mode-map (kbd "C-c C-l") 'grass-change-location)
  (define-key igrass-mode-map (kbd "C-x k") 'grass-quit)

  (if (boundp 'grass-mode-keywords)
      (setq font-lock-defaults '(grass-mode-keywords)))

  (add-hook 'window-configuration-change-hook 'comint-fix-window-size nil t)
  (run-hooks 'igrass-mode-hook))

(defun grass-change-location ()
  "Prompt the user for a new location and mapset."
  (interactive)
  ;; Should maybe use local variables first here, to insure we don't
  ;; change the globals until the change has been successful?
  (setq grass-location (grass-get-location)
        grass-mapset (grass-get-mapset))
  (comint-send-string grass-process
                      (format "g.mapset location=%s mapset=%s\n"
                              (car grass-location) grass-mapset))
  (grass-update-prompt))

;; my-today is a utility function defined in my .emacs. Most people
;; won't have that already, so add it for everyone else here:
(unless (fboundp 'my-today)
  (defun my-today ()
    "Returns todays date in the format yyyy-mm-dd"
    (car (split-string (shell-command-to-string "date +%Y-%m-%d") "\n"))))

(defun grass-quit ()
  "Send the grass process the quit command, so it will clean up before exiting.
The transcript of the current session is automatically saved (or appended) to a file in
$grass-grassdata/log"
  ;; TODO: This should be converted to a buffer-local kill-buffer-hook!
  (interactive)
  
  (if (y-or-n-p "Kill *GRASS* process buffer?")
      (with-current-buffer (process-buffer grass-process)
        (if (string= (process-status grass-process) "run")
            (comint-send-string grass-process "exit\n"))
        (if grass-log-dir
            (let ((log-file (concat grass-log-dir "/" (my-today) ".grass")))
              (unless (file-exists-p grass-log-dir)
                (mkdir grass-log-dir))
              (append-to-file (point-min) (point-max) log-file))) 
        (let ((kill-buffer-query-functions nil))
          (kill-buffer)))))

(defun grass-update-prompt ()
  "Updates the grass prompt."
  (comint-send-string grass-process
                      (format "eval `g.gisenv`\nexport PS1=\"%s\"\n"
                              grass-prompt))
  (grass-prep-process))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;              sGrass                       ;;
;; Minor mode for editing grass script files ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun grass-send-region (start end)
  "Send the region to the active Grass process"
  (interactive "r")
  (if (and (processp grass-process)
           (buffer-name (process-buffer grass-process)))
      (progn (grass-prep-process)
             (comint-send-region grass-process start end)
             (comint-send-string grass-process "\n"))
    (if (y-or-n-p "No running grass process! Start one?")
        (progn (save-window-excursion (grass))
               (grass-send-region start end)))))

(defun grass-prep-process ()
  "Send a newline to the Grass process window.
An ugly hack, without which commands sent directly by Emacs to Grass,
not entered at the command line, produce output starting at the
current prompt, rather than on the next line."  
  (save-window-excursion
    (switch-to-buffer (process-buffer grass-process))
    (goto-char (process-mark grass-process))
    (insert "\n")
    (set-marker (process-mark grass-process) (point))))

(defun grass-send-line ()
  "Send the current line to the active Grass process."
  (interactive)
  (save-excursion
    (let ((start (progn (beginning-of-line) (point)))
          (end (progn (end-of-line) (point))))
      (grass-send-region start end))))

(defun grass-send-line-and-step ()
  "Send the current line to the active Grass process."
  (interactive)
  (save-excursion
    (let ((start (progn (beginning-of-line) (point)))
          (end (progn (end-of-line) (point))))
      (grass-send-region start end)))
  (forward-line 1))

;;;###autoload
(defun sgrass ()
  "Attach the current buffer to a Grass process.
If there is no currently active grass process, a new one will be started.
If sgrass-minor-mode is already active in the buffer, deactivate it."
  (interactive)
  (if (not sgrass-minor-mode)
      (unless (and grass-process (process-live-p grass-process))
        (if (yes-or-no-p "No active grass process. Start one now? ")
            (save-current-buffer
              (grass))
          (error "No grass process running"))))
  (sgrass-minor-mode))
  
(define-minor-mode sgrass-minor-mode
  "Minor mode for editing Grass scripts, and sending commands to a Grass process. 
Based on Shell-script mode. Don't call this directly - use `sgrass' instead.

\\{sgrass-mode-map}"
  :keymap
  `((,(kbd "C-c C-v") . grass-view-help)
    (,(kbd "C-c C-n") . grass-send-line-and-step)
    (,(kbd "C-c C-l") . grass-change-location)
    (,(kbd "C-c C-r") . grass-send-region)
    ("\t" . completion-at-point))
;;  (require 'cl)
;;  (load "cl-seq")
  (add-hook 'completion-at-point-functions 'sgrass-complete-commands nil t)
  (add-hook 'completion-at-point-functions 'grass-completion-at-point nil t)
  (if (boundp 'grass-mode-keywords)
      (font-lock-add-keywords nil grass-mode-keywords))
  (run-hooks 'sgrass-mode-hook))

;;;;;;;;;;;;;;;;;;;;
;; Help functions ;;
;;;;;;;;;;;;;;;;;;;;

(defun grass-view-help (PREFIX)
  "Prompts the user for a help page to view.
If w3m is the help browser, when called with a prefix it will open a new tab."
  (interactive "P")
  (let* ((key (completing-read "Grass help: " grass-doc-table nil t))
         (file (cdr (assoc key grass-doc-table))))
    (if (not grass-help-w3m)
        (browse-url (concat "file://" file))
      (if (buffer-name grass-help) 
          (if (get-buffer-window grass-help)
              (select-window (get-buffer-window grass-help))
            (switch-to-buffer-other-window grass-help))
        (switch-to-buffer-other-window "*scratch*"))
      (if PREFIX
          (w3m-goto-url-new-session (concat "file://" file))
        (w3m-goto-url (concat "file://" file)))
      (setq grass-help (current-buffer)))))

;;; w3m customizations ;;;

;; This should be a minor mode for w3m buffers that are visiting
;; grass help files!

(defun grass-set-w3m-help (opt value)
  (if (eq value t)
      (if (not (require 'w3m nil t))
          (message "w3m must be installed in order to use grass-help-w3m!")
        (set-default opt value)
        (define-key w3m-mode-map "j" 'grass-jump-to-help-index) 
        (define-key w3m-mode-map "q" 'grass-close-w3m-window)
        (define-key w3m-mode-map "\C-l" 'recenter-top-bottom)
        (define-key w3m-ctl-c-map "\C-v" 'grass-view-help))
    (set-default opt value)))

(defun grass-close-w3m-window ()
  "If grass is running, switch to that window. If not, close w3m windows."
  (interactive)
  (if (and (processp grass-process)
           (buffer-name (process-buffer grass-process)))
      (switch-to-buffer (process-buffer grass-process))
    (w3m-close-window)))

(defun grass-jump-to-help-index (ind &optional PREF)
  "Goto a specific grass help index"
  (interactive "c\nP")
  (let ((dest 
         (concat "file://" grass-doc-dir "/"
                 (cl-case ind
                   (?h "index.html")
                   (?v "vector.html")
                   (?r "raster.html")
                   (?d "display.html")
                   (?b "database.html")
                   (?g "general.html")
                   (t "index.html")))))
    (unless (string= dest (concat "file://" grass-doc-dir))
      (if PREF 
          (w3m-goto-url-new-session dest)
        (w3m-goto-url dest)))))

(provide 'grass-mode)

;;; grass-mode.el ends here
