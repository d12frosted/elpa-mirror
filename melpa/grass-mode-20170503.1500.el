;;; grass-mode.el --- Provides Emacs modes for interacting with the GRASS GIS program

;; Copyright (C) Tyler Smith 2017

;; Author: Tyler Smith <tyler@plantarum.ca>
;; Version: 0.5
;; Package-Version: 20170503.1500
;; Package-Commit: 8a7e9dcb2295eef1ec25d886b05e09c876bd8398
;; Package-Requires: ((cl-lib "0.2") (dash "2.8.0"))
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

;; Check the customization options in the grass-mode group to make sure
;; Emacs can find your Grass exectuables and help files.

;;; TODO:

;; History browser?
;; per-location logging?
;; per-location scripting support (add to exec-path)?

;;;;;;;;;;;;;;;;;;
;; Dependencies ;;
;;;;;;;;;;;;;;;;;;

(require 'shell)
(require 'cl-lib) 
(require 'dash)                         ; using only -flatten

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customization Variables ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defgroup grass-mode nil 
  "Running GRASS GIS from within an Emacs buffer."
  :group 'Programming
  :group 'External
  :version "0.3")

;;;###autoload
(define-widget 'grass-program-alist 'lazy
  "Format of `grass-grass-program-alist'."
  :type '(repeat (group (string :tag "Program name (user-readable)")
                        (file :tag "GRASS executable")
                        (directory :tag "GRASS installation directory"))))

;;;###autoload
(defcustom grass-grass-programs-alist 
  '(("Grass70" "/usr/bin/grass" "/usr/lib/grass70"))
  "Alist of grass programs with their binary, script directory, and documentation directory. 
Elements are lists (PROGRAM-NAME BINARY INSTALL-DIRECTORY).

PROGRAM-NAME is the name of the binary as it will be presented to
the user.

BINARY is the full path to the GRASS program.

INSTALL-DIRECTORY is the root directory of the GRASS
installation, where grass-mode will find the bin, scripts and
doc/html directories.

The default values are the locations used in Debian GNU Linux.

** Finding the correct locations on other systems **

As of GRASS70, you can find the location of the INSTALL-DIRECTORY by
issuing the following command on the command-line:

Linux/Mac:
grass --config path

Windows:
C:\>grass70.bat --config path


Binary: from the command line, enter 'which grass' to find the
binary location. e.g., which grass -> /usr/bin/grass
"
  :type 'grass-program-alist
  :group 'grass-mode
  :tag "Grass programs alist")

;;;###autoload
(defcustom grass-completion-file
            (locate-user-emacs-file "grass-completions")
            "Default name of file to store completion table in.
Users don't need to read or edit this file. The primary (only) reason to
change this variable is if your Emacs configuration does not use .emacs.d/,
or you have some other reason not to want this file in the default location."
            :group 'grass-mode
            :type 'file)

;;;###autoload
(defcustom grass-eldoc-args nil
  "If non-nil, eldoc displays the arguments of the GRASS
function, rather than the function description."
  :group 'grass-mode
  :type 'sexp)

;;;###autoload
(defcustom grass-grassdata "~/grassdata"
  "The directory where grass locations are stored."
  :tag "grassdata"
  :group 'grass-mode)

;;;###autoload
(defcustom grass-default-location nil
  "The default starting location for GRASS.
When you start grass-mode, you are prompted for the map location
you wish to open. If this value is set, it will be offered as the
default value for the prompt. Whether or not it is set, you can
still choose any other location in your grassdata directory."
  :group 'grass-mode)

;;;###autoload
(defcustom grass-default-mapset "PERMANENT"
  "The default starting GRASS mapset.
When you open a new location, you are prompted for the mapset you
wish to open. If this value is set, it will be offered as the
default value at this prompt. Whether or not it is set, you can
still choose any other location in your grassdata directory."
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
Set this to nil to turn off logging. If it is not nil, when you quit your
GRASS session, your transcript will be saved to a file in this directory.
The file will be named for the current date."
  :group 'grass-mode
  :set-after '(grass-grassdata))

;;;###autoload
(defcustom grass-help-browser 'eww
  "Which browser to use to view GRASS help files.
A symbol (not a string!):
`eww' for the built-in Emacs eww web-browser (default)
`external' for the external web browser called via browse-url;
 "
  :type 'symbol
  :group 'grass-mode)

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
  nil "The top-level directory containing bin, scripts, and doc directories")

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
        ((("d.rast" "map") ("d.what.rast" "map")
          ("g.remove" "rast") ("g.region" "rast") ("g.rename" "rast")
          ("r.patch" "input") ("r.colors" "map") 
          ("r.shaded.relief" "map") ;; Grass64
          ("r.shaded.relief" "input") ;; Grass70
          ("r.mask" "input") ("r.null" "map") ("r.resample" "input") ("r.out.ascii" "input") 
          ("r.report" "map") ("r.reclass" "input") ("r.stats" "input")
          ("r.univar" "map") ("r.slope.aspect" "elevation") ("r.horizon" "elevin")
          ("v.what.rast" "raster"))
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
      "Modifications to the completion table, adding specialized look-up functions.
The automatic parsing pulls out all the static argument options. This
function list indicates which arguments are provided by grass-mode
functions. e.g., The `vector' argument of `v.what.vect' is provided by the
function `grass-vector-maps'. I maintain this list by hand, as the same
argument name (i.e., `input') means different things for different
functions.")

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

  ((command-one description
     ((parameter-one description (value1 value2)) 
      (parameter-two description nil)))
   (command-two description nil))

Commands with no parameters have a cdr of nil. Parameters without a fixed list of
possible values get a cdr of nil."

  (let* ((bin-dir (concat grass-gisbase "/bin/"))
         (script-dir (concat grass-gisbase "/scripts/"))
         (bins                          
          (remove "g.parser" (directory-files bin-dir)))
         (scripts (directory-files script-dir))
         (progs (remove "." (remove ".." (append bins scripts))))
         command-list)
    ;; note switching from bins to progs - forgot to include scripts in the original
    ;; version. 
    
    (dolist (prog (cddr progs))
      (push
       (grass-get-bin-params prog)
       command-list))
    (message "parsing complete, storing result...")
    command-list))

(defun grass-get-label-or-desc (al)
  "Returns the text of the label, if present, or the description otherwise, or nil if
neither are present."
  (if (assoc 'label (cdr al))
      (grass-fixup-string-whitespace
       (cl-third (assoc 'label (cdr al))))
    (if (assoc 'description (cdr al))
        (grass-fixup-string-whitespace
         (cl-third (assoc 'description (cdr al))))
      nil)))

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
              ;; attribute 7 is file size!
              ;; help-file is usually produced instantly, but OS-level
              ;; issues may occasionally delay this. If the file is still
              ;; empty, wait a half- second and then retry. Note that some
              ;; commands do not support --interface-description. So after
              ;; 5 times through this loop, help-file will still be empty,
              ;; so we move on and ignore them.
              (sleep-for 0.5)
              (cl-incf counter))
            (if (< counter 5)           ; counter is >= 5 only if help-file was never written
                (with-temp-buffer 
                  (insert-file-contents help-file)
                  (delete-file help-file)
                  (libxml-parse-xml-region (point-min) (point-max)))
              (message "%s parsing failed!!" bin)
              nil))))
    (when intdesc
      (let ((param-list
             (cl-remove-if-not #'(lambda (el) (eq (car el) 'parameter))
                               (cdr intdesc)))
            (flag-list
             (cl-remove-if-not #'(lambda (el) (eq (car el) 'flag))
                               (cdr intdesc))))
        (list bin
              (grass-get-label-or-desc (cdr intdesc))
              (let (par-list)
                (dolist (el param-list)
                  (push (list 
                         ;; parameter name, the second element of the first slot
                         (cl-cdaadr el) 
                         (grass-get-label-or-desc el)
                         (if (assoc 'values el)
                             (let (val-list)
                               (dolist (vals (cddr (assoc 'values el)))
                                 (push (cl-caddr (cl-caddr vals)) 
                                       val-list))
                               val-list))) 
                        par-list))
                (dolist (el flag-list)
                  (push (list 
                         ;; flag name, the second element of the first slot
                         (concat "-" (cl-cdaadr el)) 
                         (grass-get-label-or-desc el)) 
                        par-list)) 
                par-list))))))


(defun grass-update-completions (grass-prog com-param-compl)
  "Set the COMPLetion string/function for the PARAMeter of COMmand.
`com-param-compl' is a list, each element is a list of the form (com-param compl).
`com-param' is a list, each element is a list of the form (com param).
Note that this function alters the list stored in grass-completion-lookup-table, it does
not directly alter the contents of the active grass-commands list."

  (message "updating completions...")
  (dolist (com-param com-param-compl)
    (dolist (p (car com-param))
      (if (assoc (cl-second p) 
                 (cl-caddr 
                  (assoc (cl-first p) 
                         (cadr (assoc grass-prog grass-completion-lookup-table)))))
          (setcdr
           (cdr
            (assoc (cl-second p) 
                   (cl-caddr 
                    (assoc (cl-first p) 
                           (cadr (assoc grass-prog grass-completion-lookup-table))))))
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
  (grass-update-completions prog grass-command-updates) ;; see docs for grass-command-updates
  (grass-write-completions-to-file)
  (setq grass-commands 
        (cadr (assoc grass-name grass-completion-lookup-table))))

;;; User prompts ;;;

(defun grass-get-location ()
  "Prompt the user for the location. Returns a cons with the location name
in car, the directory path in cdr (both as strings)."
  (let* ((sel
         (completing-read
          (format "Grass location (%s): " grass-default-location)
          (grass-location-list) nil nil nil nil grass-default-location))
         (lkup (assoc sel (grass-location-list))))
    (if lkup lkup ;; if it exists, return the location
      (if (y-or-n-p (format "Location doesn't exist, create: <%s> ?" sel) )
          (list sel)))))

(defun grass-get-mapset ()
  "Prompt the user for the mapset for the current location."
  (completing-read (format "Grass mapset (%s): " grass-default-mapset)
                   (grass-mapset-list) nil t nil nil grass-default-mapset))

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Completion Utilities ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun grass-all-maps (&optional type location mapset skip-permanent)
  "Returns a list of maps in the given location and mapset.
Defaults to both rasters and vectors, unless type is explicitly set to
either of those strings.
Defaults to the current location and mapset.
Includes the PERMANENT mapset unless skip-permanent is non-nil.
"
  (let* ((loc (if location location grass-location))
         (mtypes (cond ((and (stringp type)
                             (string-equal type "raster"))
                        '("cell"))
                       ((and (stringp type)
                             (string-equal type "vector"))
                        '("vector"))
                       (t '("vector" "cell"))))
         (mapst (if mapset mapset grass-mapset))
         (map-dirs (list (list (concat (cdr loc) "/") mapst))))
    (unless (or skip-permanent
                (string-equal "PERMANENT" mapst))
      (add-to-list 'map-dirs (list (concat (cdr loc) "/") "PERMANENT")))
    (-flatten
     (cl-loop for type in mtypes
              collect
              (cl-loop for dir in map-dirs
                       collect
                       (if (member type (directory-files (mapconcat 'identity dir "")))
                           (mapcar #'(lambda (x) (concat x "@" (cadr dir)))
                                   (directory-files (concat (mapconcat
                                                             'identity dir
                                                             "") "/" type)
                                                    nil "^[^.]"))))))))

(defun grass-vector-maps (&optional location mapset skip-permanent)
  (grass-all-maps "vector" location mapset skip-permanent))

(defun grass-raster-maps (&optional location mapset skip-permanent)
  (grass-all-maps "raster" location mapset skip-permanent))

;; (defun grass-vector-maps (&optional location mapset skip-permanent)
;;   "Returns a list of all the vector maps in location and mapset.
;; Defaults to the current location and mapset. Unless skip-permanent is
;; non-nil, the PERMANENT mapset will be included in the list."
;;   (let* ((loc (if location location grass-location))
;;         (mapst (if mapset mapset grass-mapset))
;;         (map-dirs (list (cons (concat (cdr loc) "/") mapst))))
;;     (unless (or skip-permanent
;;                 (string-equal "PERMANENT" mapst))
;;       (add-to-list 'map-dirs (cons (concat (cdr loc) "/") "PERMANENT")))
;;     (-mapcat '(lambda (x) (if (member "vector" (directory-files x))
;;                              (directory-files (concat x "/" "vector")
;;                                               nil "^[^.]")))
;;             map-dirs)))

;; (defun grass-raster-maps (&optional location mapset skip-permanent)
;;   "Returns a list of all the raster maps in location and mapset.
;; Defaults to the current location and mapset." 
;;   (let* ((loc (if location location grass-location))
;;         (mapst (if mapset mapset grass-mapset))
;;         (map-dirs (list (concat (cdr loc) "/" mapst))))
;;     (unless (or skip-permanent
;;                 (string-equal "PERMANENT" mapst))
;;       (add-to-list 'map-dirs (concat (cdr loc) "/PERMANENT")))
;;     (-mapcat '(lambda (x) (if (member "cell" (directory-files x))
;;                               (directory-files (concat x "/" "cell")
;;                                                nil "^[^.]")))
;;              map-dirs))) 

;; (defun grass-all-maps (&optional location mapset)
;;   "Returns a list of all maps, raster and vector.
;; Defaults to the current location & mapset"
;;   (let ((loc (if location location grass-location))
;;         (mapst (if mapset mapset grass-mapset)))
;;     (let ((map-dir (concat (cdr loc) "/" mapst)))
;;       (append (if (member "vector" (directory-files map-dir))
;;                   (directory-files (concat map-dir "/" "vector") nil "^[^.]"))
;;               (if (member "cell" (directory-files map-dir))
;;                   (directory-files (concat map-dir "/" "cell") nil "^[^.]"))))))

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

(defun grass-current-command ()
  "Retrieve the current command"
  (save-excursion
    (let ((pt (point)))
      (while
          (progn (beginning-of-line)
                 (looking-at grass-prompt-2))
        (forward-line -1))
      (comint-bol)
      ;; skip over the first token:
      (re-search-forward "\\(\\S +\\)\\s ?" nil t) 

      (if (or (not (match-beginning 1)) ;; no match
              (and (>= pt (match-beginning 1)) 
                   (<= pt (match-end 1)))
              ;; the match-string is the current command, so if pt is within
              ;; this command, we haven't finished entering it:
              )
          nil                             ; not a complete command
        (match-string-no-properties 1) ; possibly a complete command!
        ))))

(defun grass-current-parameter ()
  "Retrieve the current parameter.
This assumes there is a complete command already."
  (save-excursion 
    (let ((pt (point)))
      (skip-syntax-backward "^ ")
      (if (looking-at "\\S +=")
          (progn (re-search-forward ".+[^=]" pt t)
                 (match-string-no-properties 0))
        (if (looking-at "-.+")
            (progn (re-search-forward "-.+" pt t)
                   (match-string-no-properties 0)))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Main completion functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun grass-completion-at-point ()
  (interactive)
  (let ((command (grass-current-command))
        (pt (point))
        start end)
    (save-excursion 
      (if (not command)
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
        (when (cl-member command grass-commands :test 'string= :key 'car)
          (goto-char pt)
          (skip-syntax-backward "^ ")
          (setq start (point))
          (skip-syntax-forward "^ ")
          (setq end (point))
          (if (not (string-match "=" (buffer-substring start end)))
              (list start end (cl-caddr (assoc command grass-commands)) :exclusive 'no)
            (grass-complete-parameters
             command 
             (buffer-substring start (search-backward "="))
             (progn
               (goto-char pt)
               (re-search-backward "=\\|,")
               (forward-char)
               (point))
             (progn (skip-syntax-forward "^ ") (point)))))))))

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
  (let ((collection (cl-third (assoc parameter (cl-caddr (assoc command grass-commands))))))
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

;;;;;;;;;;;
;; Eldoc ;;
;;;;;;;;;;;

(defun grass-eldoc-function ()
  "Retrieve the docstring for the current parameter, or command if no parameter, or nil."
  (let* ((command (grass-current-command))
         (param (if command (grass-current-parameter)))
         data)
    (cond ((and param (assoc param (cl-third (assoc command grass-commands))))
           (cl-second (assoc param (cl-third (assoc command grass-commands)))))
          ((and command (assoc command grass-commands))
           (if grass-eldoc-args
               (let ((result ""))
                 (dolist ( el (sort (mapcar 'car (cl-third (assoc command grass-commands))) 'string<))
                   (setq result (concat result el " ")))
                 result)
               (cl-second (assoc command grass-commands))))
          (t nil))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Starting Grass and the modes ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;###autoload
(defun grass (PREF)
  "Start the Grass process, or switch to the process buffer if it's
already active. With a prefix force the creation of a new process." 
  (interactive "P")

  ;; initializations
  (setenv "GRASS_PAGER" "cat")
  ;; I think the following correction is no longer needed with ido-ubiquitous?
  ;;   (when (and (boundp 'ido-ubiquitous-mode)
  ;;              (equal ido-ubiquitous-mode t)
  ;;              (equal ido-ubiquitous-enable-old-style-default t)
  ;;              )
  ;;     (read-from-minibuffer "ido-ubiquitous-enable-old-style-default is t - \
  ;; you might want to turn that off in grass-mode! (return to proceed)"))
  (let ((grass-prog 
         (if (> (length grass-grass-programs-alist) 1)
             ;; NB: there are problems with the completion here if you use
             ;; ido-ubiquitous and have
             ;; ido-ubiquitous-enable-old-style-default set to 't'. In that
             ;; case, the you must enter something, you cannot simply
             ;; select the default by hitting enter immediately. If this
             ;; annoys you, (as it does me) customize that variable to nil!
             (assoc (completing-read "Grass program? " grass-grass-programs-alist)
                    grass-grass-programs-alist)
           (car grass-grass-programs-alist))))

    (setq grass-name (nth 0 grass-prog)
          grass-program (nth 1 grass-prog)
          grass-gisbase (nth 2 grass-prog)
          grass-doc-dir (concat grass-gisbase "/docs/html/")))

  (message "grass name: %s" grass-name)
  
  (setq grass-doc-files         ; The list of grass help files
        (delete nil (mapcar #'(lambda (x) 
                                (if (string-match-p "html$" x)
                                    x))
                            (directory-files grass-doc-dir)))
        grass-doc-table nil)

  (mapc #'(lambda (x) 
            (push (cons (substring x 0 -5)
                        (concat grass-doc-dir "/" x)) grass-doc-table))
        grass-doc-files)

  (message "doc table set")
  ;; Don't modify the path more than once!
  (unless (member (concat grass-gisbase "/bin") exec-path)
    (add-to-list 'exec-path (concat grass-gisbase "/bin") t))
  (unless (member (concat grass-gisbase "/scripts") exec-path)
    (add-to-list 'exec-path (concat grass-gisbase "/scripts") t))

  ;; Start a new process, or switch to the existing one
  (unless (and (processp grass-process)
               (buffer-name (process-buffer grass-process))
               (not PREF))

    (setq grass-location (grass-get-location))

    (while (not grass-location)
      (setq grass-location (grass-get-location)))

    (let ((arg1 "")
          (arg2 "")
          (arg3 ""))
      (if (cdr grass-location) ;; location exists
          (progn (setq grass-mapset (grass-get-mapset))
                 (setq arg1
                       (concat 
                        (file-name-as-directory
                         (cdr grass-location)) 
                        grass-mapset))
                 ;; NB: passing empty arguments to grass via start-process
                 ;; causes GRASS to ignore all arguments? Not sure why this
                 ;; happens, but as a result opening grass will
                 ;; automatically load the previous mapset, and ignore the
                 ;; users selected mapset at this point. As a quick fix,
                 ;; when we are not creating a new mapset, and so don't
                 ;; need arg2 and arg3, we call start-process with a single
                 ;; argument here. A separate branch of the 'if' form
                 ;; handles the three-argument call.
                 (setq grass-process
                       (start-process "grass" (concat "*" grass-name "*")
                                      grass-program "-text" arg1)))
        (setq arg1 "-c") ;; new location
        (setq arg2 (expand-file-name (read-file-name "Georeferenced file: ")))
        (setq arg3 (concat
                    (expand-file-name grass-grassdata) "/"  (car grass-location)))
        (message "Loading grass location: %s %s %s %s"
                 grass-program "-text" arg1 arg2 arg3)
        (setq grass-process
              (start-process "grass" (concat "*" grass-name "*")
                             grass-program "-text" arg1 arg2 arg3)))))

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

(defun grass-fix-window-size ()
  "Change process window size. Used to update process output when Emacs window size changes."
  (when (derived-mode-p 'comint-mode)
    (ignore-errors (set-process-window-size (get-buffer-process (current-buffer))
                                            (window-height)
                                            (window-width)))))

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
  (define-key igrass-mode-map [C-return] 'grass-send-command-and-move)

  (if (boundp 'grass-mode-keywords)
      (setq font-lock-defaults '(grass-mode-keywords)))

  (set (make-local-variable 'eldoc-documentation-function) 'grass-eldoc-function)
  (add-hook 'window-configuration-change-hook 'grass-fix-window-size nil t)
  (run-hooks 'igrass-mode-hook))

(defun grass-send-command-and-move ()
  "Send the command on this line, and move point to the next command."
  (interactive)
  (let ((grass-tmp-point (point)))
    (comint-send-input)
    (goto-char grass-tmp-point)
    (comint-next-prompt 1)))

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
            (let ((log-file (concat grass-log-dir "/" 
                                    (car (split-string (shell-command-to-string "date +%Y-%m-%d") "\n")) ".grass")))
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
        (progn (save-window-excursion (grass nil))
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
              (grass nil))
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
    (,(kbd "M-TAB")   . completion-at-point)
    (,(kbd "C-c C-r") . grass-send-region))
;;  (require 'cl)
;;  (load "cl-seq")
  :lighter
  "sgrass"
  (add-hook 'completion-at-point-functions 'sgrass-complete-commands nil t)
  (add-hook 'completion-at-point-functions 'grass-completion-at-point nil t)
  (if (boundp 'grass-mode-keywords)
      (font-lock-add-keywords nil grass-mode-keywords))
  (run-hooks 'sgrass-mode-hook))

;;;;;;;;;;;;;;;;;;;;
;; Help functions ;;
;;;;;;;;;;;;;;;;;;;;

(defun grass-view-help ()
  "Prompts the user for a help page to view."
  (interactive)
  (let* ((key (completing-read "Grass help: "
                               grass-doc-table nil t nil nil
                               (grass-current-command)))
         (file (cdr (assoc key grass-doc-table)))
         (url (concat "file://" file)))
    (grass-help-dispatch url)))

(defun grass-help-dispatch (url)
  "Call the appropriate browser to view the help files."
  (cl-case grass-help-browser
    ('external
     (browse-url url))
    ('eww
     (if (and (one-window-p) (not (string-equal (buffer-name) "*eww*")))
         (split-window))
     (if (get-buffer-window "*eww*")
         (select-window (get-buffer-window "*eww*"))
       (other-window 1))
     (add-hook 'eww-mode-hook 'grass-help-jump-mode)
     (eww url)
     (message "eww called"))))

(defvar grass-help-jump-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "j") 'ghj-jump-to-help-index)
    (define-key map (kbd "m") 'ghj-link-menu)
    (define-key map (kbd "h") 'grass-view-help)
    (define-key map (kbd "C-c C-v") 'grass-view-help)
    map))

(define-minor-mode grass-help-jump-mode
  "Toggle GRASS help jump mode.
Turns on the keyboard shortcuts for jumping directly to the GRASS help
index pages. Also adds a shortcut to quickly select from any link on the
page. 

\\{grass-help-jump-mode-map}
"
  nil ;; initial value
  " GHJ" ;; indicator line
  nil ;; keybindings
  (read-only-mode 1))

(defun ghj-get-links ()
  "Returns an alist of all links, with their titles, from the current
buffer."
  (let (links)
    (save-excursion
      (goto-char (point-min))
      (while (not (eobp))
        (let* ((url (get-text-property (point) 'shr-url))
               (next-change
                (or (next-property-change (point) (current-buffer))
                    (point-max)))
               (title (buffer-substring-no-properties (point) next-change ))
               (pair (list (list title url))))
          (if url (setq links (append links pair)))
          (goto-char next-change))))
    links))

(defun ghj-link-menu ()
  "Prompts for a link from the current buffer, then follows it."
  (interactive)
  (let ((url (cadr (assoc (completing-read "Link: " (ghj-get-links) nil t)
                          (ghj-get-links)))))
    (cond
     ((not url)
      (message "No link under point"))
     ((string-match "^mailto:" url)
      (browse-url-mail url))
     ;; This is a #target url in the same page as the current one.
     ((and (url-target (url-generic-parse-url url))
	   (eww-same-page-p url eww-current-url))
      (eww-save-history)
      (eww-display-html 'utf8 url eww-current-dom))
     (t
      (eww-browse-url url)))))

(defun ghj-jump-to-help-index ()
  "Goto a specific grass help index"
  (interactive)
  (message "h: index  [v]ector  [r]aster  [d]isplay  data[b]ase  [g]eneral")
  (let* ((ind (read-char))
         (dest 
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
      (grass-help-dispatch dest))))

;;;;;;;;;;;;;;;
;; Utilities ;;
;;;;;;;;;;;;;;;

(defun grass-fixup-string-whitespace (string)
  (replace-regexp-in-string 
               "\n" ""
               (replace-regexp-in-string 
                "^[ \t\n]*" "" 
                string)))

(provide 'grass-mode)

;;; grass-mode.el ends here
