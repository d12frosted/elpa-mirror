;;; blimp.el --- Bustling Image Manipulation Package -*- lexical-binding: t -*-

;; Author: Sebastian Wålinder <s.walinder@gmail.com>
;; URL: https://github.com/walseb/blimp
;; Package-Version: 20180903.2240
;; Package-Commit: 39562f02acc1113595cb253a85bb3b9da743ddd2
;; Version: 1.0
;; Package-Requires: ((emacs "25") (eimp "1.4.0"))
;; Keywords: multimedia, unix

;; blimp.el is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; blimp.el is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This package is a complete wrapper around all imagemagick commands
;; with descriptions, autocompletion (for some commands) and hints
;; displayed in prompt using eimp.el to execute its commands and
;; resize images.
;;
;; Switch the blimp minor mode on programmatically with:
;;
;;     (blimp-mode 1)
;;
;; or toggle interactively with M-x blimp-mode RET.
;;
;; Switch the minor mode on for all image-mode buffers with:
;;
;;     (add-hook 'image-mode-hook 'blimp-mode)
;;
;; Then once blimp-mode is enabled, do `M-x blimp-interface'
;; to to add commands to be executed on the image.
;;
;; The added commands can be executed with `M-x blimp-execute-command-stack'
;; and cleared with `M-x blimp-clear-command-stack'.
;;
;; If you want to execute the command right after selecting it
;; you can do `M-x blimp-interface-execute'.
;;
;; The prefix of the command can also be changed
;; with `M-x blimp-toggle-prefix'.

;;; Code:

(require 'eimp)
(require 'subr-x)
(require 'password-cache)

(defvar blimp-command-stack (list)
  "List of unexecuted commands.")

(defvar blimp-current-prefix "-"
  "The current command prefix.")

(defconst blimp-commands
  [
   ;;Image Settings:
   ["adjoin"                "join images into a single multi-image file"]
   ["affine" "matrix"       "affine transform matrix"]
   ["alpha" "option"        "Set alpha option"]
   ["antialias"             "remove pixel-aliasing"]
   ["authenticate" "password" "decipher image with this password"]
   ["attenuate" "value"     "lessen (or intensify) when adding noise to an image"]
   ["background" "color"    "background color"]
   ["bias" "value"          "add bias when convolving an image"]
   ["black-point-compensation" "use black point compensation"]
   ["blue-primary" "point"  "chromaticity blue primary point"]
   ["bordercolor" "color"   "border color"]
   ["caption" "string"      "assign a caption to an image"]
   ["colors" "value"        "preferred number of colors in the image"]
   ["colorspace" "type"     "alternate image colorspace"]
   ["comment" "string"      "annotate image with comment"]
   ["compose" "operator"    "set image composite operator"]
   ["compress" "type"       "type of pixel compression when writing the image"]
   ["define" "format:option=value" "define one or more image format options"]
   ["delay" "value"         "display the next image after pausing"]
   ["density" "geometry"    "horizontal and vertical density of the image"]
   ["depth" "value"         "image depth"]
   ["direction" "type"      "render text right-to-left or left-to-right"]
   ["display" "server"      "get image or font from this X server"]
   ["dispose" "method"      "layer disposal method"]
   ["dither" "method"       "apply error diffusion to image"]
   ["encoding" "type"       "text encoding type"]
   ["endian" "type"         "endianness (MSB or LSB) of the image"]
   ["family" "name"         "render text with this font family"]
   ["features" "distance"   "analyze image features (e.g. contrast, correlation)"]
   ["fill" "color"          "color to use when filling a graphic primitive"]
   ["filter" "type"         "use this filter when resizing an image"]
   ["font" "name"           "render text with this font"]
   ["format" "string"       "output formatted image characteristics"]
   ["fuzz" "distance"       "colors within this distance are considered equal"]
   ["gravity" "type"        "horizontal and vertical text placement"]
   ["green-primary" "point" "chromaticity green primary point"]
   ["intensity" "method"    "method to generate an intensity value from a pixel"]
   ["intent" "type"         "type of rendering intent when managing the image color"]
   ["interlace" "type"      "type of image interlacing scheme"]
   ["interline-spacing" "value" "set the space between two text lines"]
   ["interpolate" "method"  "pixel color interpolation method"]
   ["interword-spacing" "value" "set the space between two words"]
   ["kerning" "value"       "set the space between two letters"]
   ["label" "string"        "assign a label to an image"]
   ["limit" "type" "value"  "pixel cache resource limit"]
   ["loop" "iterations"     "add Netscape loop extension to your GIF animation"]
   ["matte"                 "store matte channel if the image has one"]
   ["mattecolor" "color"    "frame color"]
   ["monitor"               "monitor progress"]
   ["orient" "type"         "image orientation"]
   ["page" "geometry"       "size and location of an image canvas (setting)"]
   ["path" "path"           "write images to this path on disk"]
   ["ping"                  "efficiently determine image attributes"]
   ["pointsize" "value"     "font point size"]
   ["precision" "value"     "maximum number of significant digits to print"]
   ["preview" "type"        "image preview type"]
   ["quality" "value"       "JPEG/MIFF/PNG compression level"]
   ["quiet"                 "suppress all warning messages"]
   ["read-mask" "filename"  "associate a read mask with the image"]
   ["red-primary" "point"   "chromaticity red primary point"]
   ["regard-warnings"       "pay attention to warning messages"]
   ["remap" "filename"      "transform image colors to match this set of colors"]
   ["respect-parentheses"   "settings remain in effect until parenthesis boundary"]
   ["sampling-factor" "geometry" "horizontal and vertical sampling factor"]
   ["scene" "value"         "image scene number"]
   ["seed" "value"          "seed a new sequence of pseudo-random numbers"]
   ["size" "geometry"       "width and height of image"]
   ["stretch" "type"        "render text with this font stretch"]
   ["stroke" "color"        "graphic primitive stroke color"]
   ["strokewidth" "value"   "graphic primitive stroke width"]
   ["style" "type"          "render text with this font style"]
   ["synchronize"           "synchronize image to storage device"]
   ["taint"                 "declare the image as modified"]
   ["texture" "filename"    "name of texture to tile onto the image background"]
   ["tile-offset" "geometry" "tile offset"]
   ["treedepth" "value"     "color tree depth"]
   ["transparent-color" "color" "transparent color"]
   ["undercolor" "color"    "annotation bounding box color"]
   ["units" "type"          "the units of image resolution"]
   ["verbose"               "print detailed information about the image"]
   ["view"                  "FlashPix viewing transforms"]
   ["virtual-pixel" "method" "virtual pixel access method"]
   ["weight" "type"         "render text with this font weight"]
   ["white-point" "point"   "chromaticity white point"]
   ["write-mask" "filename" "associate a write mask with the image"]

   ;;Image Operators:
   ["adaptive-blur" "geometry" "adaptively blur pixels; decrease effect near edges"]
   ["adaptive-resize" "geometry" "adaptively resize image using 'mesh' interpolation"]
   ["adaptive-sharpen" "geometry" "adaptively sharpen pixels; increase effect near edges"]
   ["annotate" "geometry" "text" "annotate the image with text"]
   ["auto-gamma"            "automagically adjust gamma level of image"]
   ["auto-level"            "automagically adjust color levels of image"]
   ["auto-orient"           "automagically orient (rotate) image"]
   ["auto-threshold" "method" "automatically perform image thresholding"]
   ["bench" "iterations"    "measure performance"]
   ["black-threshold" "value" "force all pixels below the threshold into black"]
   ["blue-shift"            "simulate a scene at nighttime in the moonlight"]
   ["blur" "geometry"       "reduce image noise and reduce detail levels"]
   ["border" "geometry"     "surround image with a border of color"]
   ["brightness-contrast" "geometry" "improve brightness / contrast of the image"]
   ["canny" "geometry"      "detect edges in the image"]
   ["cdl" "filename"        "color correct with a color decision list"]
   ["channel" "mask"        "set the image channel mask"]
   ["charcoal" "geometry"   "simulate a charcoal drawing"]
   ["chop" "geometry"       "remove pixels from the image interior"]
   ["clamp"                 "keep pixel values in range (0-QuantumRange)"]
   ["clip"                  "clip along the first path from the 8BIM profile"]
   ["clip-mask" "filename"  "associate a clip mask with the image"]
   ["clip-path" "id"        "clip along a named path from the 8BIM profile"]
   ["colorize" "value"      "colorize the image with the fill color"]
   ["color-matrix" "matrix" "apply color correction to the image"]
   ["connected-components" "connectivity" "connected-components uniquely labeled"]
   ["contrast"              "enhance or reduce the image contrast"]
   ["contrast-stretch" "geometry" "improve contrast by 'stretching' the intensity range"]
   ["convolve" "coefficients" "apply a convolution kernel to the image"]
   ["cycle" "amount"        "cycle the image colormap"]
   ["decipher" "filename"   "convert cipher pixels to plain pixels"]
   ["deskew" "threshold"    "straighten an image"]
   ["despeckle"             "reduce the speckles within an image"]
   ["distort" "method" "args" "distort images according to given method ad args"]
   ["draw" "string"         "annotate the image with a graphic primitive"]
   ["edge" "radius"         "apply a filter to detect edges in the image"]
   ["encipher" "filename"   "convert plain pixels to cipher pixels"]
   ["emboss" "radius"       "emboss an image"]
   ["enhance"               "apply a digital filter to enhance a noisy image"]
   ["equalize"              "perform histogram equalization to an image"]
   ["evaluate" "operator" "value" "evaluate an arithmetic, relational, or logical expression"]
   ["extent" "geometry"     "set the image size"]
   ["extract" "geometry"    "extract area from image"]
   ["fft"                   "implements the discrete Fourier transform (DFT)"]
   ["flip"                  "flip image vertically"]
   ["floodfill" "geometry" "color" "floodfill the image with color"]
   ["flop"                  "flop image horizontally"]
   ["frame" "geometry"      "surround image with an ornamental border"]
   ["function" "name" "parameters" "apply function over image values"]
   ["gamma" "value"         "level of gamma correction"]
   ["gaussian-blur" "geometry" "reduce image noise and reduce detail levels"]
   ["geometry" "geometry"   "preferred size or location of the image"]
   ["grayscale" "method"    "convert image to grayscale"]
   ["hough-lines" "geometry" "identify lines in the image"]
   ["identify"              "identify the format and characteristics of the image"]
   ["ift"                   "implements the inverse discrete Fourier transform (DFT)"]
   ["implode" "amount"      "implode image pixels about the center"]
   ["interpolative-resize" "geometry" "resize image using interpolation"]
   ["kuwahara" "geometry"   "edge preserving noise reduction filter"]
   ["lat" "geometry"        "local adaptive thresholding"]
   ["level" "value"         "adjust the level of image contrast"]
   ["level-colors" "color,color" "level image with the given colors"]
   ["linear-stretch" "geometry" "improve contrast by 'stretching with saturation'"]
   ["liquid-rescale" "geometry" "rescale image with seam-carving"]
   ["local-contrast" "geometry" "enhance local contrast"]
   ["magnify"               "double the size of the image with pixel art scaling"]
   ["mean-shift" "geometry" "delineate arbitrarily shaped clusters in the image"]
   ["median" "geometry"     "apply a median filter to the image"]
   ["mode" "geometry"       "make each pixel the 'predominant color' of the neighborhood"]
   ["modulate" "value"      "vary the brightness, saturation, and hue"]
   ["monochrome"            "transform image to black and white"]
   ["morphology" "method" "kernel" "apply a morphology method to the image"]
   ["motion-blur" "geometry" "simulate motion blur"]
   ["negate"                "replace every pixel with its complementary color"]
   ["noise" "geometry"      "add or reduce noise in an image"]
   ["normalize"             "transform image to span the full range of colors"]
   ["opaque" "color"        "change this color to the fill color"]
   ["ordered-dither" "NxN"  "add a noise pattern to the image with specific amplitudes"]
   ["paint" "radius"        "simulate an oil painting"]
   ["perceptible" "epsilon" "pixel value less than |epsilon| become epsilon or -epsilon"]
   ["polaroid" "angle"      "simulate a Polaroid picture"]
   ["posterize" "levels"    "reduce the image to a limited number of color levels"]
   ["profile" "filename"    "add, delete, or apply an image profile"]
   ["quantize" "colorspace" "reduce colors in this colorspace"]
   ["raise" "value"         "lighten/darken image edges to create a 3-D effect"]
   ["random-threshold" "low,high" "random threshold the image"]
   ["region" "geometry"     "apply options to a portion of the image"]
   ["render"                "render vector graphics"]
   ["repage" "geometry"     "size and location of an image canvas"]
   ["resample" "geometry"   "change the resolution of an image"]
   ["resize" "geometry"     "resize the image"]
   ["roll" "geometry"       "roll an image vertically or horizontally"]
   ["rotate" "degrees"      "apply Paeth rotation to the image"]
   ["rotational-blur" "angle" "rotational blur the image"]
   ["sample" "geometry"     "scale image with pixel sampling"]
   ["scale" "geometry"      "scale the image"]
   ["segment" "values"      "segment an image"]
   ["selective-blur" "geometry" "selectively blur pixels within a contrast threshold"]
   ["sepia-tone" "threshold" "simulate a sepia-toned photo"]
   ["set" "property" "value"  "set an image property"]
   ["shade" "degrees"       "shade the image using a distant light source"]
   ["shadow" "geometry"     "simulate an image shadow"]
   ["sharpen" "geometry"    "sharpen the image"]
   ["shave" "geometry"      "shave pixels from the image edges"]
   ["shear" "geometry"      "slide one edge of the image along the X or Y axis"]
   ["sigmoidal-contrast" "geometry" "increase the contrast without saturating highlights or shadows"]
   ["sketch" "geometry"     "simulate a pencil sketch"]
   ["solarize" "threshold"  "negate all pixels above the threshold level"]
   ["sparse-color" "method" "args" "fill in a image based on a few color points"]
   ["splice" "geometry"     "splice the background color into the image"]
   ["spread" "radius"       "displace image pixels by a random amount"]
   ["statistic" "type" "radius" "replace each pixel with corresponding statistic from the neighborhood"]
   ["strip"                 "strip image of all profiles and comments"]
   ["swirl" "degrees"       "swirl image pixels about the center"]
   ["threshold" "value"     "threshold the image"]
   ["thumbnail" "geometry"  "create a thumbnail of the image"]
   ["tile" "filename"       "tile image when filling a graphic primitive"]
   ["tint" "value"          "tint the image with the fill color"]
   ["transform"             "affine transform image"]
   ["transparent" "color"   "make this color transparent within the image"]
   ["transpose"             "flip image vertically and rotate 90 degrees"]
   ["transverse"            "flop image horizontally and rotate 270 degrees"]
   ["trim"                  "trim image edges"]
   ["type" "type"           "image type"]
   ["unique-colors"         "discard all but one of any pixel color"]
   ["unsharp" "geometry"    "sharpen the image"]
   ["vignette" "geometry"   "soften the edges of the image in vignette style"]
   ["wave" "geometry"       "alter an image along a sine wave"]
   ["wavelet-denoise" "threshold" "removes noise from the image using a wavelet transform"]
   ["white-threshold" "value" "force all pixels above the threshold into white"]

   ;;Image Channel Operators:
   ["channel-fx" "expression" "exchange, extract, or transfer one or more image channels"]
   ["separate"              "separate an image channel into a grayscale image"]

   ;;Image Sequence Operators:
   ["affinity" "filename"   "transform image colors to match this set of colors"]
   ["append"                "append an image sequence"]
   ["clut"                  "apply a color lookup table to the image"]
   ["coalesce"              "merge a sequence of images"]
   ["combine"               "combine a sequence of images"]
   ["compare"               "mathematically and visually annotate the difference between an image and its reconstruction"]
   ["complex" "operator"    "perform complex mathematics on an image sequence"]
   ["composite"           "composite image"]
   ["copy" "geometry" "offset" "copy pixels from one area of an image to another"]
   ["crop" "geometry"       "cut out a rectangular region of the image"]
   ["deconstruct"           "break down an image sequence into constituent parts"]
   ["evaluate-sequence" "operator" "evaluate an arithmetic, relational, or logical expression"]
   ["flatten"               "flatten a sequence of images"]
   ["fx" "expression"       "apply mathematical expression to an image channel(s)"]
   ["hald-clut"             "apply a Hald color lookup table to the image"]
   ["layers" "method"       "optimize, merge, or compare image layers"]
   ["morph" "value"         "morph an image sequence"]
   ["mosaic"                "create a mosaic from an image sequence"]
   ["poly" "terms"          "build a polynomial from the image sequence and the corresponding terms (coefficients and degree pairs)."]
   ["print" "string"        "interpret string and print to console"]
   ["process" "arguments"   "process the image with a custom image filter"]
   ["smush" "geometry"      "smush an image sequence together"]
   ["write" "filename"      "write images to this file"]

   ;;Image Stack Operators:
   ["delete" "indexes"      "delete the image from the image sequence"]
   ["duplicate" "count,indexes" "duplicate an image one or more times"]
   ["insert" "index"       "insert last image into the image sequence"]
   ["reverse"               "reverse image sequence"]
   ["swap" "indexes"        "swap two images in the image sequence"]
   ])

;; Mode settings
(defvar blimp-minor-mode-map
  (let ((map (make-keymap)))
    (define-key map (kbd "C-c C-o") 'blimp-interface)
    (define-key map (kbd "C-c C-O") 'blimp-interface-execute)
    (define-key map (kbd "C-c C-e") 'blimp-execute-command-stack)
    (define-key map (kbd "C-c C-p") 'blimp-toggle-prefix)
    (define-key map (kbd "C-c C-r") 'blimp-clear-command-stack)
    map)
  "Keymap for blimp mode.")

(defvar blimp-mode-string " BLIMP"
  "Mode line indicator string.")
(make-variable-buffer-local 'blimp-mode-string)

;;;###autoload
(define-minor-mode blimp-mode
  "Toggle Blimp mode."
  nil blimp-mode-string blimp-minor-mode-map
  (when blimp-mode
    (setq blimp-mode-string " BLIMP"))
  (if (not eimp-mode)
      (eimp-mode)))

;;;###autoload
(defun blimp-toggle-prefix (&optional arg)
  "Toggle the command prefix.
If ARG is positive, use + as command prefix.
If ARG is negative, use - as command prefix.
Otherwise toggle between command prefixes."
  (interactive)
  (if (if arg
	  (> arg 0)
	(string= blimp-current-prefix "-"))
      (setq blimp-current-prefix "+")
    (setq blimp-current-prefix "-")))

;;;###autoload
(defun blimp-clear-command-stack ()
  "Remove all unexecuted commands."
  (interactive)
  (setq blimp-command-stack nil))

;;;###autoload
(defun blimp-execute-command-stack ()
  "Execute all unexecuted commands.
Also removes all unexecuted commands after executing them."
  (interactive)
  (if blimp-command-stack
      (progn
	(eimp-mogrify-image blimp-command-stack)
	(blimp-clear-command-stack))))

(defun blimp-get-all-commands ()
  "Get all commands.
For use when choosing which command to execute in `blimp-interface'."
  (delete nil (mapcar (lambda (command-data-entry)
			(interactive)
			(aref command-data-entry 0))
		      blimp-commands)))

(defun blimp-get-command-entry-data (command)
  "Gets the data entry for COMMAND.
This includes a command name, arguments and a description."
  (nth 0 (delete nil (mapcar (lambda (command-array)
			       (interactive)
			       (if (string= (aref command-array 0) command) command-array nil))
			     blimp-commands))))

(defun blimp-prompt-for-arguments (command argument description)
  "Opens an appropriate prompt for COMMAND ARGUMENT with a DESCRIPTION shown in prompt."
  (pcase argument
    ("option" (blimp-type-completing-read command argument description))
    ("type" (blimp-type-completing-read command argument description))
    ("operator" (blimp-type-completing-read command argument description))
    ("method" (blimp-type-completing-read command argument description))
    ("name" (blimp-type-completing-read command argument description))
    ("property" (blimp-type-completing-read command argument description))
    ("mask" (blimp-type-completing-read command argument description))
    ("NxN" (blimp-type-completing-read command argument description))
    ("matrix" (blimp-find-file-completing-read command argument description))
    ("password" (password-read "Enter password (it will be stored in plaintext until the commands have been executed) "))
    ("value" (blimp-number-completing-read command argument nil description))
    ("amount" (blimp-number-completing-read command argument nil description))
    ("threshold" (blimp-number-completing-read command argument "number 0 to 100" description t))
    ("iterations" (blimp-number-completing-read command argument "number" description))
    ("distance" (blimp-number-completing-read command argument "distance" description))
    ("args" (blimp-number-completing-read command argument "x,y... Point amount is dependant on method" description))
    ("epsilon" (blimp-number-completing-read command argument "number" description))
    ("angle" (blimp-number-completing-read command argument "(+ or -)number" description))
    ("degrees" (blimp-number-completing-read command argument "(+ or -)number" description))
    ("levels" (blimp-number-completing-read command argument "number" description))
    ("offset" (blimp-number-completing-read command argument nil description))
    ("index" (blimp-number-completing-read command argument nil description))
    ("color" (blimp-color-completing-read command argument description))
    ("color,color" (blimp-color-completing-read command argument description))
    ("geometry" (blimp-geometry-completing-read command argument description))
    ("point" (blimp-point-completing-read command argument "x,y" description))
    ("indexes" (blimp-point-completing-read command argument "index,index" description))
    ("count,indexes" (blimp-point-completing-read command argument "count,index" description))
    ("low,high" (blimp-point-completing-read command argument "number,number" description))
    ("filename" (blimp-find-file-completing-read command argument description))
    ("path" (blimp-find-file-completing-read command argument description))
    ("string" (blimp-completing-read command argument nil "string" description))
    ("text" (blimp-completing-read command argument nil "string" description))
    ("family" (blimp-completing-read command argument nil "family name" description))
    ("format:option=value" (blimp-completing-read command argument nil nil description))
    ("server" (blimp-completing-read command argument nil "Specify X server" description))
    ("id" (blimp-completing-read command argument nil "ID" description))
    ("coefficients" (blimp-completing-read command argument nil nil description))
    ("radius" (blimp-radius-sigma-completing-read command argument nil description nil))
    ("expression" (blimp-completing-read command argument nil nil description))
    ("terms" (blimp-completing-read command argument nil nil description))
    ("arguments" (blimp-completing-read command argument nil nil description))
    (_ (blimp-completing-read command argument nil "???" description))))

(defun blimp-read-command (command &optional command-data)
  "Prompts for possible COMMAND arguments.
If COMMAND-DATA is supplied, use it for prompts
Returns results if input is legitimate."
  (let* ((command-data (if command-data
			   command-data
			 (blimp-get-command-entry-data command))))
    (if command-data
	;; Get COMMAND from car of blimp-commands, and remove nils
	(delete nil (mapcar
		     (lambda (current-data-entry) (interactive)
		       (let* ((current-position
			       (cl-position current-data-entry command-data)))
			 (if (= current-position 0)
			     (concat blimp-current-prefix current-data-entry)
			   (if (not (= current-position
				       (- (length command-data) 1)))
			       (blimp-prompt-for-arguments
				command current-data-entry
				(aref command-data (- (length command-data) 1)))))))
		     command-data))
      (error "Error: Command does not exist"))))

;;;###autoload
(defun blimp-interface (&optional command)
  "Prompt user for arguments of COMMAND if any and add to command stack.
If COMMAND is nil, prompt user for which command should be executed."
  (interactive)
  (blimp-add-to-command-stack
   (if command
       (blimp-read-command command)
     (blimp-read-command
      (completing-read (concat "Choose command: "
			       (if blimp-command-stack
				   (concat  "(Queued commands: "
					    (string-join blimp-command-stack " ") ") ")))
		       (blimp-get-all-commands))))))

;;;###autoload
(defun blimp-interface-execute (&optional command)
  "Prompt user for arguments of COMMAND if any and add to command stack.
If COMMAND is nil, prompt user for which command should be executed.
COMMAND will be executed instantly."
  (interactive)
  (blimp-interface command)
  (blimp-execute-command-stack))

(defun blimp-command-type-exceptions (command)
  "Get types by COMMAND.
These are manually added types for when the imagemagick documentation is bad."
  (pcase command
    ("limit" (list "width" "height" "area" "memory" "map" "disk" "file" "thread"
		   "throttle" "time"))
    ("font" (delete "Font:" (blimp-get-command-type-list
			     (concat command " | grep Font:"))))
    ("ordered-dither"
     (list "threshold" "checks" "o2x2" "o3x3" "o4x4" "o8x8" "h3x4a" "h6x6a"
	   "h8x8a" "h3x4o" "h6x6o" "h8x8o" "h36x16o" "c5x5b" "c5x5w" "c6x6b"
	   "c6x6w" "c7x7b" "c7x7w"))
    ;; Incomplete
    ("property" (list "comment" "origsize" "profile"))))

(defun blimp-get-command-type-list (command)
  "Fetches command types for COMMAND from the imagemagick documentation.
Command types can be a method, property, etc."
  (let* ((manual-command-list (blimp-command-type-exceptions command)))
    (if manual-command-list
	manual-command-list
      (let* ((command-list (shell-command-to-string
			    (concat eimp-mogrify-program " -list " command))))
	(if (string-match-p "\\(?:mogrify:\\|unrecognized\\)" command-list)
	    nil
	  (let* ((result (split-string command-list)))
	    result))))))

(defun blimp-add-to-command-stack (values)
  "Add list VALUES to the end of `blimp-command-stack'."
  (if (not blimp-command-stack)
      (progn
	(push (car values) blimp-command-stack)
	(setq values (delete (car values) values))))
  (mapc #'(lambda (arg) (interactive)
	    (push arg (cdr (last blimp-command-stack))))
	values))

;;* `Completing reads'
(defun blimp-completing-read (command argument collection input-format description)
  "Completing read wrapper with correct formating.
It formats COMMAND, ARGUMENT, INPUT-FORMAT
and DESCRIPTION and puts it in the prompt.
COLLECTION is added as autocompletion entries."
  (completing-read
   (concat "(" blimp-current-prefix " prefix) " command " - " argument " : "
	   (if (and input-format (not (string-empty-p input-format)))
	       (concat "(format: " input-format ") "))
	   "(info: " description ") ")
   collection))

(defun blimp-type-completing-read (command argument description)
  "Completing read for types.
Types in blimp are the result of doing `magick -list COMMAND'
in a shell and then formatting it.
It formats COMMAND, ARGUMENT, and DESCRIPTION and puts it in the prompt."
  (let* ((command-type-data (blimp-get-command-type-list command)))
    (if command-type-data
	(blimp-completing-read command
			       argument command-type-data nil description)
      (blimp-completing-read command argument nil "Missing autocomplete"
			     description))))

(defun blimp-number-completing-read (command argument input-format description &optional percentage-result)
  "Completing read with some basic check for numbers.
If PERCENTAGE-RESULT is non-nil, add a % sign at the end if none are supplied
It formats COMMAND, ARGUMENT, INPUT-FORMAT
and DESCRIPTION and puts it in the prompt.
If PERCENTAGE-RESULT is non-nil, add a percentage
mark at the end of the user input and inform the user of this."
  (let* ((new-format (concat input-format
			     (if percentage-result
				 " (% auto added if not supplied)"
			       nil))))
    (let* ((input-text
	    (blimp-completing-read command argument nil new-format
				   description)))
      ;; Accept "x" as an argument separator
      (if (or (string-match-p "[:a-v:]" input-text)
	      (string-match-p "[:y-z:]" input-text))
	  (error "Error: Input wasn't a number")
	(if percentage-result
	    (progn
	      (if (string-match-p (regexp-quote "\%") input-text)
		  input-text
		(concat input-text "%")))
	  input-text)))))

(defun blimp-point-completing-read (command argument input-format description)
  "Completing read with some basic check for points.
It formats COMMAND, ARGUMENT, INPUT-FORMAT
and DESCRIPTION and puts it in the prompt."
  (let* ((point
	  (blimp-number-completing-read command argument input-format
					description)))
    (if (string-match-p ".\\(\\,\\)." point)
	point
      (error "Error: Input does not follow format x,y. Example: 100,200"))))

(defun blimp-geometry-completing-read (command argument description)
  "Completing read with some hints on which format is relevant.
It formats COMMAND, ARGUMENT,and DESCRIPTION
and puts it in the prompt."
  (blimp-completing-read command argument nil "X, XxY, xY, X%, XxY%, xY%, +X+Y (relative), X! / X^ / 4:3~ (perserve/ignore/select aspect ratio)" description))

(defun blimp-find-file-completing-read (command argument description)
  "Read-file-name wrapper with correct formating.
It formats COMMAND, ARGUMENT,and DESCRIPTION
and puts it in the prompt."
  (let* ((file (read-file-name
		(concat "(" blimp-current-prefix " prefix) " command "- "
			argument " (info: " description ") ")
		default-directory)))
    (if (and (file-exists-p file) (not (directory-name-p file)))
	file
      nil)))

(defun blimp-color-completing-read (command argument description)
  "Completing read with some hints on which format is relevant.
It formats COMMAND, ARGUMENT,and DESCRIPTION
and puts it in the prompt."
  (blimp-completing-read command argument nil
			 "blue or #aabbcc or rgb(255,255,255)" description))

(defun blimp-radius-sigma-completing-read (command argument collection description &optional both-radius-and-sigma)
  "Completing read with some basic check for radius (and sigma).
If BOTH-RADIUS-AND-SIGMA is non-nil, prompt the user for both radius and sigma.
It formats COMMAND, ARGUMENT,and DESCRIPTION and puts it in the prompt.
COLLECTION is added as autocompletion entries.
If BOTH-RADIUS-AND-SIGMA is non-nil, prompt usere for both radius and sigma"
  (let* ((input-text
	  (blimp-completing-read
	   command argument collection
	   (concat "5 (radius)"
		   (if both-radius-and-sigma "or 5,9 (radius,sigma)"))
	   description)))
    ;; Do a simple check for letters that aren't x
    (if (or (string-match-p "[:a-v:]" input-text)
	    (string-match-p "[:y-z:]" input-text))
	(error "Error: Input does not follow format x,y. Example: 100,200")
      input-text)))

(provide 'blimp)

;;; blimp.el ends here
