;;; processing-mode.el --- Major mode for Processing 2.0

;; Processing.org language based on Java mode. Adds keyword
;; highlighting for all recognized Processing language functions.
;; Allows compilation of buffers and "sketches" from within Emacs but
;; only for more recent versions of Processing.

;; Copyright (C) 2008, 2009 Rudolf Olah <omouse@gmail.com>
;; Copyright (C) 2012 Bunny Blake <discolingua@gmail.com>
;; Copyright (C) 2012 - 2015 Peter Vasil <mail@petervasil.net>

;; Author: Peter Vasil <mail@petervasil.net>
;; Version: 1.3.0
;; Package-Version: 20171022.2302
;; Package-Commit: 448aba82970c98322629eaf2746e73be6c30c98e
;; Keywords: languages, snippets
;; URL: https://github.com/ptrv/processing2-emacs
;;
;; This program is free software: you can redistribute it and/or modify
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

;; Major mode for Processing 2.0.

;;; Code:

(eval-when-compile
  (require 'compile)
  (require 'cl)
  (require 'easymenu)
  (require 'thingatpt)
  (require 'cc-vars))

;;;; Compatibility
(eval-and-compile
  ;; `setq-local' for Emacs 24.2 and below
  (unless (fboundp 'setq-local)
    (defmacro setq-local (var val)
      "Set variable VAR to value VAL in current buffer."
      `(set (make-local-variable ',var) ,val))))

(defgroup processing nil
  "Major mode for the Processing language."
  :group 'languages
  :prefix "processing-")

(defcustom processing-location
  (eval (cond ((eq system-type 'darwin)
               "/usr/bin/processing-java")
              (t nil)))
  "The path to the processing-java command line tool.

The path should be something like /usr/bin/processing-java."
  :type 'string
  :group 'processing)

(defcustom processing-application-dir
  (eval (cond ((eq system-type 'darwin)
               "/Applications/Processing.app")
              (t nil)))
  "The path of the processing application directory.

On a Mac the default path is `/Applications/Processing.app' and
can also be the directory that contains the app (e.g.
/Applications)."
  :type 'string
  :group 'processing)

(defcustom processing-sketchbook-dir
  (eval (cond ((eq system-type 'darwin)
               "~/Documents/Processing")
              ((eq system-type 'gnu/linux)
               "~/sketchbook")
              (t nil)))
  "The path of the processing sketch directory."
  :type 'string
  :group 'processing)

(define-obsolete-variable-alias
  'processing-sketch-dir
  'processing-sketchbook-dir
  "1.2.1")

(defcustom processing-output-dir nil
  "The output path of the processing command.

If NIL, create output directory in current sketch folder."
  :type '(choice (const :tag "Sub-directory `output' in current Sketch" nil)
                 (string :tag "Path to output directory"))
  :group 'processing)

(defcustom processing-forum-search-url "http://forum.processing.org/two/search?Search=%s"
  "Search URL of the official Processing forums.
%s will be replaced with the search query."
  :type 'string
  :group 'processing)

(defcustom processing-keymap-prefix (kbd "C-c C-p")
  "Processing keymap prefix."
  :type 'string
  :group 'processing)

(defconst processing-platform
  (cond ((eq system-type 'gnu/linux) "linux")
        ((eq system-type 'darwin) "macosx")
        ((or (eq system-type 'ms-dos) (eq system-type 'windows-nt)
             (eq system-type 'cygwin)) "windows"))
  "The platform that Processing is running on.
It can be `linux', `macosx' or `windows'.")

(defconst processing-platform-bits
  (if (string-match "64" system-configuration) "64" "32"))

;; Functions

(defun processing-make-compile-command (sketch-dir output-dir cmd &optional platform bits)
  "Return a string which is the `compile-command' for Processing.
sketches, targetting the sketch files found in SKETCH-DIR, with
the output being stored in OUTPUT-DIR. The command flag that is
executed on the sketch depends on the type of CMD. Optional
arguments are PLATFORM and BITS.

Valid types of commands are:

  - \"build\"
  - \"run\"
  - \"present\"
  - \"export\"

When ``cmd'' is set to \"export-application\", the ``platform''
must be set to one of \"windows\", \"macosx\", or \"linux\". If
no platform is selected, the default platform that Emacs is
running on will be selected."
  (let* ((sketch-name (expand-file-name sketch-dir))
         (cmd-type (if (symbolp 'cmd) (symbol-name cmd) cmd))
         (run-out-dir (expand-file-name output-dir))
         (run-opts (concat " --output="
                           (shell-quote-argument run-out-dir)))
         (export? (if (string= cmd-type "export") t nil))
         (export-platform (if platform platform processing-platform))
         (export-bits (if bits bits processing-platform-bits))
         (export-out-dir (expand-file-name
                          (concat (file-name-as-directory sketch-dir)
                                  "application." export-platform)))
         (export-opts (concat " --platform=" export-platform
                              " --bits=" export-bits
                              " --output="
                              (shell-quote-argument export-out-dir))))
    (concat processing-location
            " --force --sketch=" (shell-quote-argument sketch-name)
            " --" cmd-type
            (if export? export-opts run-opts))))

(defun processing-commander (sketch-dir output-dir cmd &optional platform bits)
  "Run the Processing compiler, using a `compile-command'.
It is constructed using the ``processing-make-compile-command''
function. Arguments are SKETCH-DIR, OUTPUT-DIR and CMD. Optional
arguments PLATFORM and BITS."
  (if (and processing-location (file-exists-p processing-location))
      (compile (processing-make-compile-command sketch-dir output-dir cmd platform bits)
               'processing-compilation-mode)
    (user-error (concat "The variable `processing-location' is either unset "
                        "or the path is invalid. Please define the location "
                        "of the processing command-line executable."))))

(defun* processing--get-output-dir ()
  "Return the output path to use for the procesing command.

If `processing-output-dir' is NIL use sub-directory ``output'' in
Sketch directory as output path."
  (if processing-output-dir
      (let* ((sketch-name (file-name-base
                           (directory-file-name
                            (file-name-directory buffer-file-name))))
             (out-dir (file-name-as-directory processing-output-dir)))
        (unless (file-exists-p out-dir)
          (if (yes-or-no-p (concat "Output directory \""
                                   processing-output-dir
                                   "\" does not exist! Create?"))
              (make-directory out-dir t)
            (return-from processing--get-output-dir nil)))
        (concat out-dir sketch-name "_output"))
    (concat (file-name-directory buffer-file-name) "output")))

(defun processing-sketch-compile (cmd)
  "Run the Processing Commander application with the current Sketch.

CMD is the run type command argument."
  (let ((sketch-dir (file-name-directory buffer-file-name))
        (output-dir (processing--get-output-dir)))
    (if output-dir
        (processing-commander sketch-dir output-dir cmd)
      (message "processing-sketch-compile: No output directory!"))))

(defun processing-sketch-run ()
  "Run sketch."
  (interactive)
  (processing-sketch-compile 'run))

(defun processing-sketch-present ()
  "Run sketch fullscreen."
  (interactive)
  (processing-sketch-compile 'present))

(defun processing-sketch-build ()
  "Run the build command for a Processing sketch.
Processing will process the sketch into .java files and then
compile them into .class files."
  (interactive)
  (processing-sketch-compile 'build))

(defun processing-export-application ()
  "Turn the Processing sketch into a Java application.
Assumes that the platform target is whatever platform Emacs is
running on."
  (interactive)
  (processing-sketch-compile 'export))

;;;###autoload
(defun processing-find-sketch (name &optional arg)
  "Find a processing sketch with NAME in `processing-sketchbook-dir'.
If ARG is non nil or `processing-sketchbook-dir' is nil create new
sketch in current directory."
  (interactive "sSketch name: \nP")
  (let* ((name (remove ?\s name))
         (tmp-name (replace-regexp-in-string "[-]" "_" name)))
    (when (string-equal "" name)
      (error "Please provide a sketch name"))
    (unless (string= tmp-name name)
      (message "File '%s' has been renamed to '%s'!" name tmp-name)
      (setq name tmp-name))
    (let ((sketch-dir name)
          (sketch-name name))
      (if (and processing-sketchbook-dir
               (not arg))
          (setq sketch-dir (concat
                            (file-name-as-directory processing-sketchbook-dir)
                            sketch-dir)))
      (make-directory sketch-dir t)
      (find-file (concat sketch-dir "/" sketch-name ".pde")))))

(define-obsolete-function-alias
  'processing-create-sketch 'processing-find-sketch "1.2.0")

(defun processing--sub-dir (sub-dir)
  (let* ((app-dir (file-name-as-directory processing-application-dir))
         (subdir
          (cond
           ((eq system-type 'gnu/linux)
            (concat app-dir sub-dir))
           ((eq system-type 'darwin)
            (concat app-dir
                    (unless (string-match "Processing.app"
                                          processing-application-dir)
                      "Processing.app/")
                    "Contents/Resources/Java/" sub-dir))
           ((or (eq system-type 'ms-dos) (eq system-type 'windows-nt)
                (eq system-type 'cygwin)) app-dir))))
    subdir))

(defun processing--get-dir (dir)
  (let ((the-dir (processing--sub-dir dir)))
    (if (and processing-application-dir
             (file-exists-p the-dir))
        the-dir
      (user-error (concat "The variable `processing-application-dir' is either"
                          " unset or the directory does not exist.")))))

(defun processing--open-query-in-reference (query)
  "Open QUERY in Processing reference."
  (let ((help-dir (processing--get-dir "modes/java/reference/"))
        help-file-fn help-file-keyword)
    (when help-dir
      (setq help-file-fn (concat help-dir query ".html"))
      (setq help-file-keyword (concat help-dir query "_.html"))
      (cond ((file-exists-p help-file-fn) (browse-url help-file-fn))
            ((file-exists-p help-file-keyword) (browse-url help-file-keyword))
            (t (message "No help file for %s" query))))))

(defun processing-search-in-reference (query)
  "Search QUERY in Processing reference.
When calle interactively, prompt the user for QUERY."
  (interactive "sFind reference for: ")
  ;; trim query before open reference
  (processing--open-query-in-reference (replace-regexp-in-string
                                        "\\`[ \t\n()]*" ""
                                        (replace-regexp-in-string
                                         "[ \t\n()]*\\'" "" query))))

(defun processing-find-in-reference ()
  "Find word under cursor in Processing reference."
  (interactive)
  (processing--open-query-in-reference (thing-at-point 'symbol)))

(defun processing-open-reference ()
  "Open Processing reference."
  (interactive)
  (let ((help-dir (processing--get-dir "modes/java/reference/")))
    (when help-dir
      (browse-url (concat help-dir "index.html")))))

(defun processing-open-examples ()
  "Open examples folder in dired."
  (interactive)
  (let ((examples-dir (processing--get-dir "modes/java/examples")))
    (when examples-dir
      (find-file examples-dir))))

(defun processing-open-sketchbook ()
  "Open sketchbook."
  (interactive)
  (if (file-exists-p processing-sketchbook-dir)
      (find-file processing-sketchbook-dir)
    (user-error (concat "The variable `processing-sketchbook-dir'"
                        " is either unset or the directory does"
                        " not exist."))))

(defun processing--dwim-at-point ()
  "If there's an active selection, return that.
Otherwise, get the symbol at point."
  (if (use-region-p)
      (buffer-substring-no-properties (region-beginning) (region-end))
    (if (symbol-at-point)
        (symbol-name (symbol-at-point)))))

(defun processing-search-forums (query)
  "Search the official Processing forums for the given QUERY and
  open results in browser."
  ;; (interactive "sSearch for: ")
  (interactive (list (read-from-minibuffer
                      "Search string: " (processing--dwim-at-point))))
  (let* ((search-query (replace-regexp-in-string "\\s-+" "%20" query))
         (search-url (format processing-forum-search-url search-query)))
    (browse-url search-url)))

;; Font-lock, keywords
(defvar processing-functions
  '("triangle" "line" "arc" "ellipse" "point" "quad" "rect" "bezier"
    "bezierDetail" "bezierPoint" "bezierTangent" "curve" "curveDetail"
    "curvePoint" "curveTangent" "curveTightness" "box" "sphere"
    "sphereDetail" "background" "size" "fill" "noFill" "stroke"
    "noStroke" "colorMode" "ellipseMode" "rectMode" "smooth" "noSmooth"
    "strokeCap" "strokeJoin" "strokeWeight" "noCursor" "cursor" "random"
    "randomSeed" "floor" "ceil" "noLoop" "loop" "createShape" "loadShape"
    "beginShape" "bezierVertex" "curveVertex" "endShape" "quadraticVertex"
    "vertex" "shape" "shapeMode" "mouseClicked" "mousePressed" "mouseDragged"
    "mouseMoved" "mouseReleased" "keyPressed" "keyReleased" "keyTyped"
    "createInput" "createReader" "loadBytes" "loadStrings" "loadTable"
    "loadXML" "open" "selectFolder" "selectInput" "day" "hour" "millis"
    "minute" "month" "second" "year" "print" "println" "save" "saveFrame"
    "beginRaw" "beginRecord" "createOutput" "createWriter" "endRaw"
    "endRecord" "PrintWriter" "saveBytes" "saveStream" "saveStrings"
    "SelectOutput" "applyMatrix" "popMatrix" "printMatrix" "pushMatrix"
    "resetMatrix" "rotate" "rotateX" "rotateY" "rotateZ" "scale" "shearX"
    "shearY" "translate" "ambientLight" "directionalLight" "lightFalloff"
    "lights" "lightSpecular" "noLights" "normal" "pointLight" "spotLight"
    "beginCamera" "camera" "endCamera" "frustum" "ortho" "perspective"
    "printCamera" "printProjection" "modelX" "modelY" "modelZ" "screenX"
    "screenY" "screenZ" "ambient" "emissive" "shininess" "specular" "alpha"
    "blue" "brightness" "color" "green" "hue" "lerpColor" "red" "saturation"
    "createImage" "image" "imageMode" "loadImage" "noTint" "requestImage"
    "tint" "texture" "textureMode" "textureWrap" "blend" "copy" "filter"
    "get" "loadPixels" "set" "updatePixels" "blendMode" "createGraphics"
    "hint" "loadShader" "resetShader" "shader" "createFont" "loadFont"
    "text" "textFont" "textAlign" "textLeading" "textMode" "textSize"
    "textWidth" "textAscent" "textDescent" "abs" "constrain" "dist" "exp"
    "lerp" "log" "mag" "map" "max" "min" "norm" "pow" "round" "sq" "sqrt"
    "acos" "asin" "atan" "atan2" "cos" "degrees" "radians" "sin" "tan"
    "noise" "noiseDetail" "noiseSeed"))

(defvar processing-constants
  '("ADD" "ALIGN_CENTER" "ALIGN_LEFT" "ALIGN_RIGHT" "ALPHA" "ALPHA_MASK"
    "ALT" "AMBIENT" "ARROW" "ARGB" "BACKSPACE" "BASELINE" "BEVEL" "BLEND"
    "BLUE_MASK" "BLUR" "BOTTOM" "BURN" "CENTER" "CHATTER" "CLOSE" "CMYK"
    "CODED" "COMPLAINT" "COMPOSITE" "COMPONENT" "CONCAVE_POLYGON" "CONTROL"
    "CONVEX_POLYGON" "CORNER" "CORNERS" "CROSS" "CUSTOM" "DARKEST" "DEGREES"
    "DEG_TO_RAD" "DELETE" "DIAMETER" "DIFFERENCE" "DIFFUSE" "DILATE" "DIRECTIONAL"
    "DISABLE_ACCURATE_2D" "DISABLE_ACCURATE_TEXTURES" "DISABLE_DEPTH_MASKS"
    "DISABLE_DEPTH_SORT" "DISABLE_DEPTH_TEST" "DISABLE_NATIVE_FONTS"
    "DISABLE_OPENGL_ERRORS" "DISABLE_TEXTURE_CACHE" "DISABLE_TEXTURE_MIPMAPS"
    "DISABLE_TRANSFORM_CACHE" "DISABLE_STROKE_PERSPECTIVE" "DISABLED"
    "DODGE" "DOWN" "DXF" "ENABLE_ACCURATE_2D" "ENABLE_ACCURATE_TEXTURES"
    "ENABLE_DEPTH_MASKS" "ENABLE_DEPTH_SORT" "ENABLE_DEPTH_TEST"
    "ENABLE_NATIVE_FONTS" "ENABLE_OPENGL_ERRORS" "ENABLE_TEXTURE_CACHE"
    "ENABLE_TEXTURE_MIPMAPS" "ENABLE_TRANSFORM_CACHE" "ENABLE_STROKE_PERSPECTIVE"
    "ENTER" "EPSILON" "ERODE" "ESC" "EXCLUSION" "GIF" "GRAY" "GREEN_MASK"
    "GROUP" "HALF" "HALF_PI" "HAND" "HARD_LIGHT" "HINT_COUNT" "HSB" "IMAGE"
    " INVERT" "JPEG" "LEFT" "LIGHTEST" "LINES" "LINUX" "MACOSX" "MAX_FLOAT"
    " MAX_INT" "MITER" "MODEL" "MOVE" "MULTIPLY" "NORMAL" "NORMALIZED"
    "NO_DEPTH_TEST" "NTSC" "ONE" "OPAQUE" "OPEN" "ORTHOGRAPHIC" "OVERLAY"
    "PAL" "PDF" "P2D" "P3D" "PERSPECTIVE" "PI" "PIXEL_CENTER" "POINT" "POINTS"
    "POSTERIZE" "PROBLEM" "PROJECT" "QUAD_STRIP" "QUADS" "QUARTER_PI"
    "RAD_TO_DEG" "RADIUS" "RADIANS" "RED_MASK" "REPLACE" "RETURN" "RGB"
    "RIGHT" "ROUND" "SCREEN" "SECAM" "SHIFT" "SPECULAR" "SOFT_LIGHT" "SQUARE"
    "SUBTRACT" "SVIDEO" "TAB" "TARGA" "TEXT" "TFF" "THIRD_PI" "THRESHOLD"
    "TIFF" "TOP" "TRIANGLE_FAN" "TRIANGLES" "TRIANGLE_STRIP" "TUNER" "TWO"
    "TWO_PI" "UP" "WAIT" "WHITESPACE" "OPENGL" "JAVA2D"))

(defvar processing-builtins
  '("mouseX" "mouseY" "pmouseX" "pmouseY" "mouseButton" "mousePressed"
    "key" "keyCode" "keyPressed" "width" "height" "frameRate" "frameCount"
    "displayWidth" "displayHeight" "focused" "screenWidth" "screenHeight"))

(defvar processing-functions-regexp (regexp-opt processing-functions 'words))
(defvar processing-constants-regexp (regexp-opt processing-constants 'words))
(defvar processing-builtins-regexp (regexp-opt processing-builtins 'words))

(defconst processing-font-lock-keywords-1
  `((,processing-functions-regexp . font-lock-keyword-face)
    (,processing-constants-regexp . font-lock-constant-face)
    (,processing-builtins-regexp . font-lock-builtin-face)))

(defvar processing-font-lock-keywords processing-font-lock-keywords-1
  "Default expressions to highlight in Processing mode.")

(defvar processing-mode-map
  (let ((map (make-sparse-keymap))
        (pmap (make-sparse-keymap)))
    (define-key pmap "r" 'processing-sketch-run)
    (define-key pmap "p" 'processing-sketch-present)
    (define-key pmap "b" 'processing-sketch-build)
    (define-key pmap "e" 'processing-export-application)
    (define-key pmap "h" 'processing-open-reference)
    (define-key pmap "l" 'processing-open-examples)
    (define-key pmap "d" 'processing-find-in-reference)
    (define-key pmap "f" 'processing-find-sketch)
    (define-key pmap "s" 'processing-search-forums)
    (define-key pmap "o" 'processing-open-sketchbook)
    (define-key pmap "z" 'processing-copy-as-html)
    (define-key map processing-keymap-prefix pmap)
    map)
  "Keymap for processing major mode.")

(easy-menu-define processing-mode-menu processing-mode-map
  "Menu used when Processing major mode is active."
  '("Processing"
    ["Run" processing-sketch-run
     :help "Run processing sketch"]
    ["Run fullscreen" processing-sketch-present
     :help "Run processing sketch fullscreen"]
    ["Build" processing-sketch-build
     :help "Build processing sketch"]
    ["Export" processing-export-application
     :help "Export processing sketch to application"]
    "---"
    ["New sketch" processing-find-sketch
     :help "Create a new sketch or open an existing"]
    "---"
    ["Examples" processing-open-examples
     :help "Open examples folder"]
    ["Reference" processing-open-reference
     :help "Open Processing reference"]
    ["Find in reference" processing-find-in-reference
     :help "Find word under cursor in reference"]
    ["Search in forums" processing-search-forums
     :help "Search in the Processing forum"]
    ["Open Sketchbook" processing-open-sketchbook
     :help "Open sketchbook folder"]
    "---"
    ["Copy as HTML" processing-copy-as-html
     :help "Copy buffer or region as HTML to clipboard"]
    "---"
    ["Settings" (customize-group 'processing)
     :help "Processing settings"]))

;; If htmlize is installed, provide this function to copy buffer or
;; region to clipboard
(defun processing-copy-as-html (&optional arg)
  "Copy buffer or region to clipboard htmlized.
If ARG is non-nil switch to htmlized buffer instead copying to clipboard."
  (interactive "P")
  (if (and (fboundp 'htmlize-buffer)
           (fboundp 'htmlize-region))
      (if (eq (buffer-local-value 'major-mode (get-buffer (current-buffer)))
              'processing-mode)
          (save-excursion
            (let ((htmlbuf (if (region-active-p)
                               (htmlize-region (region-beginning) (region-end))
                             (htmlize-buffer))))
              (if arg
                  (switch-to-buffer htmlbuf)
                (with-current-buffer htmlbuf
                  (clipboard-kill-ring-save (point-min) (point-max)))
                (kill-buffer htmlbuf)
                (message "Copied as HTML to clipboard"))))
        (message (concat "Copy as HTML failed, because current "
                         "buffer is not a Processing buffer.")))
    (user-error "Please install the package htmlize from \
http://fly.srk.fer.hr/~hniksic/emacs/htmlize.el.cgi")))

;;;###autoload
(define-derived-mode processing-mode
  java-mode "Processing"
  "Major mode for Processing.
\\{java-mode-map}"
  (setq-local c-basic-offset 2)
  (setq-local tab-width 2)
  (setq-local indent-tabs-mode nil)
  (c-set-offset 'substatement-open '0)
  (font-lock-add-keywords 'processing-mode processing-font-lock-keywords))

(define-derived-mode processing-compilation-mode
  compilation-mode "Processing Compilation"
  "Compilation mode for Processing."
  (setq-local compilation-error-regexp-alist
              (cons 'processing compilation-error-regexp-alist))
  (setq-local compilation-error-regexp-alist-alist
              (cons '(processing "^\\([[:alnum:]\\_\\/]+\\.pde\\):\\([0-9]+\\):.*$" 1 2)
                    compilation-error-regexp-alist-alist)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.pde$" . processing-mode))

(provide 'processing-mode)
;;; processing-mode.el ends here
