;;; fluxus-mode.el --- Major mode for interfacing with Fluxus

;; Copyright (C) 2016 modula t.

;; Author: modula t. <defaultxr@gmail.com>
;; Homepage: https://github.com/defaultxr/fluxus-mode
;; Version: 0.5
;; Package-Version: 20210715.58
;; Package-Commit: a14578640c578a4fd09cb7e25da1e87d637719ae
;; Package-Requires: ((osc "0.1") (emacs "24.4"))
;; Keywords: languages

;; This file is not part of GNU Emacs.

;; Fluxus-Mode is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; Foobar is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Fluxus-Mode.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This package provides an interface to the Fluxus live coding environment.
;;
;; According to the official Fluxus site at http://www.pawfal.org/fluxus/ ,
;; Fluxus is a 3D game engine for livecoding worlds into existence.  It is
;; a rapid prototyping, playing and learning environment for 3D graphics,
;; sound and games.  It extends the Racket language with graphical commands
;; and can be used within its own livecoding environment or from within the
;; DrRacket IDE.
;;
;; This package allows Fluxus to be used from within Emacs.

;;; Code:

;; custom

(defgroup fluxus-mode nil
  "Fluxus interface."
  :group 'external
  :prefix "fluxus-")

(defcustom fluxus-osc-host "127.0.0.1"
  "The host that the Fluxus process is running on."
  :type '(string))

(defcustom fluxus-osc-port 34343
  "The port to send Fluxus OSC messages through."
  :type '(integer))

(defcustom fluxus-flash-region-on-eval t
  "Whether or not to flash the region being evaluated."
  :type '(boolean))

;; setup

(require 'osc)

(defun fluxus-make-osc-client (host port)
  "Make the OSC connection to Fluxus on host HOST and port PORT."
  (make-network-process
   :name "OSC client"
   :host host
   :service port
   :type 'datagram
   :family 'ipv4
   :noquery t))

(defvar fluxus-client (fluxus-make-osc-client fluxus-osc-host fluxus-osc-port)
  "The OSC connection to Fluxus.")

(defvar fluxus-process nil
  "The Fluxus process.")

(defvar fluxus-mode-directory (file-name-directory load-file-name)
  "The directory that fluxus-mode resides in.")

;; internal functions

(defun fluxus-send (text)
  "Send TEXT as code to Fluxus."
  (osc-send-message fluxus-client "/code" text))

(defun fluxus-current-task ()
  "Return a task name for the current file."
  (car (split-string (buffer-name) "\\.")))

(defun fluxus-flash-region (start end)
  "Temporarily highlight region from START to END."
  (when fluxus-flash-region-on-eval
    (pulse-momentary-highlight-region start end)))

;; interactive functions

;;;###autoload
(defun fluxus-start () ;; FIX: use process sentinels to avoid having to use `sit-for'
  "Start or restart Fluxus."
  (interactive)
  (fluxus-stop)
  (setq fluxus-process (start-process "fluxus" "*Fluxus*" "/usr/bin/fluxus" "-x" (concat fluxus-mode-directory "fluxus.scm")))
  (with-current-buffer "*Fluxus*"
    (let ((window (display-buffer (current-buffer))))
      (goto-char (point-max))
      (save-selected-window
        (set-window-point window (point-max))
        (setq-local scroll-conservatively 1000)))))

(defun fluxus-stop ()
  "Stops Fluxus."
  (interactive)
  (when (process-live-p fluxus-process)
    (interrupt-process fluxus-process)
    (setq fluxus-process nil)
    (sit-for 0.5)))

(defun fluxus-show ()
  "Displays the Fluxus buffer."
  (interactive)
  (with-current-buffer "*Fluxus*"
    (let ((window (display-buffer (current-buffer))))
        (goto-char (point-max)))))

(defun fluxus-spawn-task ()
  "Spawn a task named as the filename."
  (interactive)
  (osc-send-message fluxus-client "/spawn-task" (fluxus-current-task)))

(defun fluxus-rm-task ()
  "Remove the current buffer as a task."
  (interactive)
  (osc-send-message fluxus-client "/rm-task" (fluxus-current-task)))

(defun fluxus-rm-all-tasks ()
  "Remove all tasks."
  (interactive)
  (osc-send-message fluxus-client "/rm-all-tasks" ""))
    
(defun fluxus-send-region ()
  "Send the region to Fluxus."
  (interactive)
  (let ((beg (region-beginning))
        (end (region-end)))
    (fluxus-flash-region beg end)
    (fluxus-send (buffer-substring-no-properties beg end))))

(defun fluxus-send-buffer ()
  "Send the current buffer to Fluxus."
  (interactive)
  (let ((beg (point-min))
        (end (point-max)))
    (fluxus-flash-region beg end)
    (fluxus-send (buffer-substring-no-properties beg end))))

(defun fluxus-send-defun ()
  "Send the current top level form to Fluxus."
  (interactive)
  (let ((beg (save-excursion (forward-char) (beginning-of-defun) (point)))
        (end (save-excursion (end-of-defun) (point))))
    (fluxus-flash-region beg end)
    (fluxus-send (buffer-substring-no-properties beg end))))

(defun fluxus-send-dwim ()
  "Send the region to Fluxus. If the region isn't active, send the top level form currently under point."
  (interactive)
  (if (region-active-p)
      (fluxus-send-region)
    (fluxus-send-defun)))

(defun fluxus-load ()
  "Load the current file."
  (interactive)
  (osc-send-message fluxus-client "/load" buffer-file-name))

(defun fluxus-load-and-spawn ()
  "Load and spawn the current file as a task."
  (interactive)
  (fluxus-load)
  (fluxus-spawn-task))

;; mode

(defconst fluxus-keywords
  ;; (regexp-opt
  ;;  '("start-audio" "colour" "vector" "gh" "gain"
  ;;    "build-cube" "build-sphere" "build-plane" "every-frame"
  ;;    "scale" "translate" "rotate" "with-state" "clear"
  ;;    "destroy" "with-primitive" "parent" "time" "delta"
  ;;    "texture" "opacity" "pdata-map!" "pdata-index-map!" "build-torus"
  ;;    "build-seg-plane" "build-cylinder" "build-polygons")
  ;;  'symbols)
  '( ;; from http://www.pawfal.org/fluxus/docs/0.17/en/index.html
   ;; frisbee
   "vec3" "vec3-x" "vec3-y" "vec3-z" "vec3-integral" "scene"
   ;; scheme-utils
   "detach-parent" "with-state" "with-primitive" "with-pixels-renderer" "with-ffgl" "pdata-map!" "pdata-index-map!" "pdata-fold" "pdata-index-fold" "vadd" "vsub" "vmul" "vdiv" "collada-import" "vmix" "vclamp" "vsquash" "lerp" "vlerp" "mlerp" "get-line-from-xy" "world-pos" "mouse-pos" "mouse-pos-z" "2dvec->angle" "pixels-circle" "pixels-blend-circle" "pixels-dodge" "pixels-burn" "pixels-clear" "pixels-index" "pixels-texcoord" "poly-type" "poly-for-each-face" "poly-for-each-triangle" "poly-build-triangulate" "poly-for-each-tri-sample" "build-extrusion" "build-partial-extrusion" "partial-extrude" "build-disk" "rndf" "crndf" "rndvec" "crndvec" "srndvec" "hsrndvec" "grndf" "grndvec" "rndbary" "hrndbary" "build-circle-points" "pdata-for-each-tri-sample" "expand" "occlusion-texture-bake"
   ;; openal
   "oa-start" "oa-load-sample" "oa-update" "oa-play" "oa-set-head-pos" "oa-set-poly" "oa-set-cull-dist" "oa-set-acoustics"
   ;; util-functions
   "time" "delta" "flxrnd" "flxseed" "set-searchpathss" "get-searchpaths" "fullpath" "framedump" "tiled-framedump"
   ;; primitives
   "build-cube" "build-polygons" "build-sphere" "build-icosphere" "build-torus" "build-plane" "build-seg-plane" "build-cylinder" "build-ribbon" "build-text" "build-type" "build-extruded-type" "type->poly" "text-params" "ribbon-inverse-normals" "build-nurbs-sphere" "build-nurbs-plane" "build-particles" "build-image" "build-voxels" "voxels->blobby" "voxels->poly" "voxels-width" "voxels-height" "voxels-depth" "voxels-calc-gradient" "voxels-sphere-influence" "voxels-sphere-solid" "voxels-sphere-cube" "voxels-threshold" "voxels-point-light" "build-locator" "locator-bounding-radius" "load-primitive" "clear-geometry-cache" "save-primitive" "build-pixels" "pixels-upload" "pixels-download" "pixels->texture" "pixels-width" "pixels-height" "pixels-renderer-activate" "build-blobby" "blobby->poly" "draw-instance" "draw-cube" "draw-plane" "draw-sphere" "draw-cylinder" "draw-torus" "draw-line" "destroy" "poly-indices" "poly-type-enum" "poly-indexed?" "poly-set-index" "poly-convert-to-indexed" "build-copy" "make-pfunc" "pfunc-set!" "pfunc-run" "geo/line-intersect" "recalc-bb" "bb/bb-intersect?" "bb/point-intersect?" "get-children" "get-parent" "get-bb"
   ;; primitive-data
   "pdata-ref" "pdata-set!" "pdata-add" "pdata-exists?" "pdata-names" "pdata-op" "pdata-copy" "pdata-size" "recalc-normals"
   ;; local-state
   "push" "pop" "grab" "ungrab" "apply-transform" "opacity" "wire-opacity" "shinyness" "colour" "colour-mode" "rgb->hsv" "hsv->rgb" "wire-colour" "normal-colour" "specular" "ambient" "emissive" "identity" "concat" "translate" "rotate" "scale" "get-transform" "get-global-transform" "parent" "line-width" "point-width" "blend-mode" "hint-on" "hint-off" "hint-solid" "hint-wire" "hint-wire-stippled" "hint-frustum-cull" "hint-normalise" "hint-noblend" "hint-nozwrite" "line-pattern" "hint-normal" "hint-points" "hint-anti-alias" "hint-unlit" "hint-vertcols" "hint-box" "hint-none" "hint-origin" "hint-cast-shadow" "hint-depth-sort" "hint-ignore-depth" "hint-lazy-parent" "hint-cull-ccw" "hint-sphere-map" "texture" "is-resident?" "set-texture-priority" "multitexture" "print-scene-graph" "hide" "camera-hide" "selectable" "backfacecull" "shader" "shader-source" "clear-shader-cache" "shader-set!" "texture-params"
   ;; global-state
   "clear-engine" "blur" "fog" "show-axis" "show-fps" "lock-camera" "camera-lag" "load-texture" "clear-texture-cache" "frustum" "clip" "ortho" "persp" "set-ortho-zoom" "clear-colour" "clear-frame" "clear-zbuffer" "clear-accum" "build-camera" "current-camera" "viewport" "get-camera" "get-locked-matrix" "set-camera" "get-projection-transform" "set-projection-transform" "get-screen-size" "set-screen-size" "select" "select-all" "desiredfps" "draw-buffer" "read-buffer" "set-stereo-mode" "set-colour-mask" "shadow-light" "shadow-length" "shadow-debug" "accum" "print-info" "set-cursor" "set-full-screen"
   ;; ffgl
   "ffgl-load" "ffgl-get-info" "ffgl-get-parameters" "ffgl-get-parameter-default" "ffgl-get-parameter" "ffgl-activate" "ffgl-active?" "ffgl-get-min-inputs" "ffgl-get-max-inputs" "ffgl-set-time!" "ffgl-process" "ffgl-clear-instances" "ffgl-clear-cache" "with-ffgl" "ffgl-set-parameter!"
   ;; video
   "video-clear-cache" "video-load" "video-tcoords" "video-update" "video-play" "video-stop" "video-seek" "video-width" "video-height" "video-imgptr" "camera-list-devices" "camera-clear-cache" "camera-init" "camera-update" "camera-tcoords" "camera-width" "camera-height" "camera-imgptr"
   ;; artkp
   "ar-init" "ar-set-threshold" "ar-get-threshold" "ar-auto-threshold" "ar-set-pattern-width" "ar-activate-vignetting-compensation" "ar-detect" "ar-get-projection-matrix" "ar-get-modelview-matrix" "ar-get-id" "ar-get-confidence" "ar-load-pattern"
   ;; audio
   "start-audio" "gh" "ga" "gain" "process" "smoothing-bias" "update-audio" "set-num-frequency-bins" "get-num-frequency-bins"
   ;; renderer
   "make-renderer" "renderer-grab" "renderer-ungrab" "fluxus-render" "tick-physics" "render-physics" "reset-renderers" "reshape" "fluxus-init" "fluxus-error-log"
   ;; lights
   "make-light" "light-ambient" "light-diffuse" "light-specular" "light-position" "light-spot-angle" "light-spot-exponent" "light-attenuation" "light-direction"
   ;; maths
   "vmulc" "vaddc" "vsubc" "vdivc" "vtransform" "vtransform-rot" "vnormalise" "vdot" "vmag" "vreflect" "vdist" "vdist-sq" "vcross" "mmul" "madd" "msub" "mdiv" "mident" "mtranslate" "mrotate" "mscale" "mtranspose" "minverse" "maim" "matrix->euler" "qaxisangle" "qmul" "qnormalise" "qtomatrix" "qconjugate" "fmod" "snoise" "noise" "noise-seed" "noise-detail"
   ;; physics
   "collisions" "ground-plane" "active-box" "active-cylinder" "active-sphere" "active-mesh" "passive-box" "passive-cylinder" "passive-sphere" "passive-mesh" "physics-remove" "surface-params" "build-balljoint" "build-fixedjoint" "build-hingejoint" "build-sliderjoint" "build-hinge2joint" "build-amotorjoint" "joint-param" "joint-angle" "joint-slide" "set-max-physical" "set-mass" "gravity" "kick" "twist" "add-force" "add-torque" "set-gravity-mode" "has-collided"
   ;; turtle
   "turtle-prim" "turtle-vert" "turtle-build" "turtle-move" "turtle-push" "turtle-pop" "turtle-turn" "turtle-reset" "turtle-attach" "turtle-skip" "turtle-position" "turtle-seek" "get-turtle-transform"
   ;; midi
   "midi-info" "midiin-open" "midiout-open" "midiin-close" "midiout-close" "midi-cc" "midi-ccn" "midi-note" "midi-program" "midi-peek" "midi-send" "midi-position" "midi-clocks-per-beat" "midi-beats-per-bar" "midi-set-signature"
   ;; osc
   "osc-source" "osc-msg" "osc" "osc-destination" "osc-peek" "osc-send"
   ;; scratchpad
   "reset-camera" "set-camera-transform" "get-camera-transform" "set-help-locale!" "help" "key-pressed" "keys-down" "key-special-pressed" "keys-special-down" "key-modifiers" "key-pressed-this-frame" "key-special-pressed-this-frame" "mouse-x" "mouse-y" "mouse-button" "mouse-wheel" "mouse-over" "every-frame" "clear" "start-framedump" "end-framedump" "set-physics-debug" "override-frame-callback" "set-auto-indent-tab" "set-camera-update" "spawn-task" "rm-task" "rm-all-tasks" "ls-tasks" "task-running?" "spawn-timed-task"
   ;; fluxa
   "reload" "sine" "saw" "tri" "squ" "white" "pink" "add" "sub" "mul" "div" "pow" "adsr" "mooglp" "moogbp" "mooghp" "formant" "sample" "crush" "distort" "klip" "echo" "ks" "play" "play-now" "fluxa-debug" "volume" "pan" "max-synths" "searchpath" "eq" "comp" "note" "reset" "clock-map" "zmod" "seq"
   ;; planetarium
   "dome-set-camera-transform" "dome-camera-set-fov" "dome-camera-lag" "dome-build" "dome-setup-main-camera"
   ;; testing-functions
   "self-test" "run-scripts"
   ;; voxels-utils
   "voxel-index" "voxels-pos"
   ))

(defun fluxus-completion-at-point ()
  "This is the function to be used for the hook `completion-at-point-functions'."
  (interactive)
  (let* ((bds (bounds-of-thing-at-point 'symbol))
         (start (car bds))
         (end (cdr bds)))
    (list start end fluxus-keywords . nil)))

(defvar fluxus-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "C-c C-l") 'fluxus-load)
    (define-key map (kbd "C-c C-f") 'fluxus-send-buffer)
    (define-key map (kbd "C-c C-c") 'fluxus-send-dwim)
    (define-key map (kbd "C-c C-o") 'fluxus-start)
    (define-key map (kbd "C-c >") 'fluxus-show)
    map)
  "Keymap for fluxus-mode.")

;;;###autoload
(define-derived-mode fluxus-mode scheme-mode
  "Fluxus"
  "Fluxus mode"
  (font-lock-add-keywords nil `((,(regexp-opt fluxus-keywords 'symbols) . 'font-lock-function-name-face)))
  (add-hook 'completion-at-point-functions 'fluxus-completion-at-point nil 'local))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.flx\\'" . fluxus-mode))

(provide 'fluxus-mode)

;;; fluxus-mode.el ends here
