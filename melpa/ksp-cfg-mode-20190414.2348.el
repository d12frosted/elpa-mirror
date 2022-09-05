;;; ksp-cfg-mode.el --- major mode for editing KSP CFG files -*- lexical-binding: t; -*-

;; Copyright (c) 2016-2019 Emily Backes

;; Author: Emily Backes <lucca@accela.net>
;; Maintainer: Emily Backes <lucca@accela.net>
;; Created: 3 May 2016

;; Version: 0.6
;; Package-Commit: faec8bd8456c67276d065eb68c88a30efcef59ef
;; Package-Version: 20190414.2348
;; Package-X-Original-Version: 0.6
;; Keywords: data
;; URL: http://github.com/lashtear/ksp-cfg-mode
;; Homepage: http://github.com/lashtear/ksp-cfg-mode
;; Package: ksp-cfg-mode
;; Package-Requires: ((emacs "24") (cl-lib "0.5"))

;; This file is not part of GNU Emacs.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:
;;
;; * Redistributions of source code must retain the above copyright
;;   notice, this list of conditions and the following disclaimer.
;;
;; * Redistributions in binary form must reproduce the above copyright
;;   notice, this list of conditions and the following disclaimer in
;;   the documentation and/or other materials provided with the
;;   distribution.
;;
;; * Neither the names of the authors nor the names of contributors
;;   may be used to endorse or promote products derived from this
;;   software without specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS
;; OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY
;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;;; Commentary:

;; This defines a new major mode for KSP modding of part files that
;; provides syntax highlighting and intelligent indentation.

;;; Code:

(eval-when-compile
  (require 'cl-lib)) ;; using cl-case and cl-loop

(defgroup ksp-cfg nil
  "Major mode for editing Kerbal Space Program cfg files in Emacs."
  :group 'languages
  :prefix "ksp-cfg-")

(defcustom ksp-cfg-basic-indent 8
  "Indentation of KSP cfg structures inside curly braces.

Squad seems to use 8-- or at least tab characters; see
`ksp-cfg-tab-width' for more information."
  :type 'integer
  :group 'ksp-cfg
  :safe t)

(defcustom ksp-cfg-tab-width 8
  "Width of the tab character for KSP cfg files.

Squad seems to use tabs for their basic indent, so setting this
to match `ksp-cfg-basic-indent' will match their layout no matter
what width you use."
  :type 'integer
  :group 'ksp-cfg
  :safe t)

(defcustom ksp-cfg-cleanup-on-load nil
  "Run ‘ksp-cfg-cleanup’ on load for indentation."
  :type 'boolean
  :group 'ksp-cfg
  :safe t)

(defcustom ksp-cfg-cleanup-on-save nil
  "Run ‘ksp-cfg-cleanup’ on save for indentation."
  :type 'boolean
  :group 'ksp-cfg
  :safe t)

(defcustom ksp-cfg-indent-method #'ksp-cfg-indent-line
  "Select single-line indentation methodology."
  :type '(radio (function-item #'ksp-cfg-indent-line)
                (function-item #'ksp-cfg-indent-line-inductive))
  :group 'ksp-cfg
  :risky t)

(defcustom ksp-cfg-show-idle-help t
  "Display context-sensitive help when idle."
  :type 'boolean
  :group 'ksp-cfg
  :risky t)

(defcustom ksp-cfg-idle-delay 0.125
  "Seconds of delay before showing context-sensitive help.

Use `ksp-cfg-idle-help` to disable this entirely."
  :type 'number
  :group 'ksp-cfg
  :risky t)

(defgroup ksp-cfg-faces nil
  "Configure the faces used by ksp-cfg font locking."
  :group 'ksp-cfg
  :group 'faces
  :prefix "ksp-cfg-")

(defface ksp-cfg-node-face
  '((t (:inherit font-lock-type-face)))
  "Face for KSP-cfg nodes, used to open brace-blocks like PART, MODULE, etc."
  :group 'ksp-cfg-faces)

(defface ksp-cfg-key-face
  '((t (:inherit font-lock-variable-name-face)))
  "Face for KSP-cfg keys, which come before = inside nodes."
  :group 'ksp-cfg-faces)

(defface ksp-cfg-name-face
  '((t (:inherit font-lock-variable-name-face :slant italic)))
  "Face for KSP-cfg names, as in \[name\] or name = ..."
  :group 'ksp-cfg-faces)

(defface ksp-cfg-constant-face
  '((default :inherit font-lock-constant-face))
  "Face for KSP-cfg known constants, like true and false."
  :group 'ksp-cfg-faces)

(defface ksp-cfg-number-face
  '((t (:inherit font-lock-string-face)))
  "Face for KSP-cfg numbers."
  :group 'ksp-cfg-faces)

(defface ksp-cfg-filter-face
  '((t (:inherit font-lock-builtin-face)))
  "Face for KSP-cfg filters, such as :HAS :NEEDS and :FINAL."
  :group 'ksp-cfg-faces)

(defface ksp-cfg-operator-face
  '((t (:inherit font-lock-keyword-face)))
  "Face for KSP-cfg operators."
  :group 'ksp-cfg-faces)

;; Generated from KSP 1.6.1 using something like:
;; $ find ~/.local/share/Steam/SteamApps/common/Kerbal\ Space\ Program/GameData/Squad -type f -name \*.cfg -print0 |xargs -0 grep '^\s*[A-Z]' |grep -v = |cut -d: -f2 |perl -pe 's[//.*$][]; s/\W+/ /g; s/^\s+//; s/\s+$//; $_="\"$_\"\n"' |sort -u |tr \\n \  |fmt
(defvar ksp-cfg-node-types
  '("AbortActionGroup" "AGENT" "ARM" "AUDIO" "AUDIO_LOOP" "AUDIO_MULTI_POOL"
    "Base" "BRAKES" "CAMERA_MODE" "CAMERA_MOUSE_TOGGLE" "CAMERA_NEXT"
    "CAMERA_ORBIT_DOWN" "CAMERA_ORBIT_LEFT" "CAMERA_ORBIT_RIGHT"
    "CAMERA_ORBIT_UP" "CAMERA_RESET" "Conclusion" "CONSTRAINFX"
    "CONSTRAINLOOKFX" "CONSTRAINT" "CONTROLPOINT" "CREW_REQUEST"
    "CustomActionGroup1" "CustomActionGroup10" "CustomActionGroup2"
    "CustomActionGroup3" "CustomActionGroup4" "CustomActionGroup5"
    "CustomActionGroup6" "CustomActionGroup7" "CustomActionGroup8"
    "CustomActionGroup9" "DISPLAY_MODES" "Distribution" "Docking_toggleRotLin"
    "DRAG_CUBE" "Editor_coordSystem" "Editor_fineTweak"
    "Editor_modeOffset" "Editor_modePlace" "Editor_modeRoot"
    "Editor_modeRotate" "Editor_partSearch" "Editor_pitchDown"
    "Editor_pitchUp" "Editor_resetRotation" "Editor_rollLeft"
    "Editor_rollRight" "Editor_toggleAngleSnap" "Editor_toggleSymMethod"
    "Editor_toggleSymMode" "Editor_yawLeft" "Editor_yawRight"
    "Editor_zoomScrollModifier" "EFFECT" "EFFECTS" "EVA_back" "EVA_Board"
    "EVA_ChuteDeploy" "EVA_forward" "EVA_Jump" "EVA_left" "EVA_Lights"
    "EVA_Orient" "EVA_Pack_back" "EVA_Pack_down" "EVA_Pack_forward"
    "EVA_Pack_left" "EVA_Pack_right" "EVA_Pack_up" "EVA_right" "EVA_Run"
    "EVA_ToggleMovementMode" "EVA_TogglePack" "EVA_Use" "EVA_yaw_left"
    "EVA_yaw_right" "Exceptional" "EXPERIENCE_TRAIT" "EXPERIMENT_DEFINITION"
    "Expiration" "EXTRA_INFO" "Flag" "FOCUS_NEXT_VESSEL" "FOCUS_PREV_VESSEL"
    "Funds" "GAMEOBJECTS" "GLOBAL_RESOURCE" "Grand" "HEADLIGHT_TOGGLE"
    "INPUT_RESOURCE" "INTERNAL" "Introduction" "IonPlume" "ISRU"
    "KEYBOARD_LAYOUT" "KEY_MAP" "LANDING_GEAR" "LAUNCH_STAGES"
    "LINUX_VARIANT" "MAP_VIEW_TOGGLE" "MODEL" "MODEL_MULTI_PARTICLE"
    "MODEL_PARTICLE" "MODIFIER_KEY" "MODULE" "NAVBALL_TOGGLE" "NODES"
    "OSX_VARIANT" "OUTPUT_RESOURCE" "PARAM" "Parent" "PART" "PART_REQUEST"
    "PassiveEnergy" "PAUSE" "PITCH_DOWN" "PITCH_UP" "PLANETARY_RESOURCE"
    "PRECISION_CTRL" "PREFAB_PARTICLE" "Problem" "Progression" "PROP"
    "PROPELLANT" "QUICKLOAD" "QUICKSAVE" "RCS_TOGGLE" "RDNode" "Recovery"
    "Reputation" "REQUIRED_EFFECTS" "RESOURCE" "RESOURCE_CONFIGURATION"
    "RESOURCE_DEFINITION" "RESOURCE_OVERLAY_CONFIGURATION_DOTS"
    "RESOURCE_OVERLAY_CONFIGURATION_LINES"
    "RESOURCE_OVERLAY_CONFIGURATION_SOLID" "RESOURCE_PROCESS"
    "RESOURCE_REQUEST" "RESULTS" "ROLL_LEFT" "ROLL_RIGHT" "SAS_HOLD"
    "SAS_TOGGLE" "Satellite" "Science" "SCROLL_ICONS_DOWN" "SCROLL_ICONS_UP"
    "SCROLL_VIEW_DOWN" "SCROLL_VIEW_UP" "Sentinel" "Significant" "Station"
    "STORY_DEF" "STRATEGY" "STRATEGY_DEPARTMENT" "Survey" "SURVEY_DEFINITION"
    "TAKE_SCREENSHOT" "TemperatureModifier" "Test" "TEXTURE"
    "ThermalEfficiency" "THROTTLE_CUTOFF" "THROTTLE_DOWN" "THROTTLE_FULL"
    "THROTTLE_UP" "Thrust" "TIME_WARP_DECREASE" "TIME_WARP_INCREASE"
    "TIME_WARP_STOP" "TOGGLE_FLIGHT_FORCES" "TOGGLE_LABELS"
    "TOGGLE_SPACENAV_FLIGHT_CONTROL" "TOGGLE_SPACENAV_ROLL_LOCK"
    "TOGGLE_STATUS_SCREEN" "TOGGLE_TEMP_GAUGES" "TOGGLE_TEMP_OVERLAY"
    "TOGGLE_UI" "Tour" "TRANSLATE_BACK" "TRANSLATE_DOWN" "TRANSLATE_FWD"
    "TRANSLATE_LEFT" "TRANSLATE_RIGHT" "TRANSLATE_UP" "Trivial"
    "TUTORIAL" "UIMODE_DOCKING" "UIMODE_STAGING" "VARIANT" "VARIANTTHEME"
    "WHEEL_STEER_LEFT" "WHEEL_STEER_RIGHT" "WHEEL_THROTTLE_DOWN"
    "WHEEL_THROTTLE_UP" "YAW_LEFT" "YAW_RIGHT" "ZOOM_IN" "ZOOM_OUT")
  "A list of strings describing the node type keywords known to KSP.")

;;; Generated from ModuleManager 2.8.1
;;; $ perl -ne 'next unless /":([a-z]+)\[?"/i; print "\"$1\"\n"' moduleManager.cs |sort -u |fmt
(defvar ksp-cfg-filter-types
  '("AFTER" "BEFORE" "FINAL" "FIRST" "FOR" "HAS" "LEGACY" "NEEDS")
  "A list of :FILTER operations from ModuleManager.")

(defvar ksp-cfg-wildcarded-name-regexp
  "\\(?:\\s_+\\|\\*\\|\\?\\)+")

(defvar ksp-cfg-node-decl-regexp
  (concat "\\([-@+$!%]?\\)\\("
          (regexp-opt ksp-cfg-node-types 'symbols)
          "\\)\\(?:\\[\\("
          ksp-cfg-wildcarded-name-regexp
          "\\)\\]\\)?"))

(defun ksp-cfg-explain-node-decl ()
  "Provide context-sensitive help related to a cfg NODE.

The node should have been just-matched with
`ksp-cfg-node-decl-regexp'."
  (let ((op (match-string 1))
        (node-type (match-string 2))
        (target (match-string 4)))
    (message "%s%s: %s %s node%s"
             op
             node-type
             (cl-case (string-to-char op)
               (?@ "edit an existing")
               ((?+ ?$) "copy an existing")
               ((?- ?!) "delete an existing")
               (?% "edit or create a new")
               (t "create a new"))
             node-type
             (if target (concat " named " target) ""))))

(defvar ksp-cfg-filter-spec-regexp
  (concat ":\\(" (regexp-opt ksp-cfg-filter-types 'symbols) "\\)"))

(defun ksp-cfg-explain-filter-spec ()
  "Provide context-sensitive help related to a :filter or :pass term.

The specshould have been just-matched with
`ksp-cfg-filter-spec-regexp'."
  (let ((filter-type (match-string 1))
        (decased-type (upcase (match-string 1))))
    (message ":%s%s" filter-type
             (cond
              ((equal decased-type "HAS")
               "[...]: filter by nodes that have ...")
              ((equal decased-type "NEEDS")
               "[...]: apply this patch only if ... is present")
              ((equal decased-type "FIRST")
               ": apply this patch in the first pass")
              ((equal decased-type "LEGACY")
               ": apply this patch in the legacy pass -- don't use this")
              ((equal decased-type "BEFORE")
               "[modname]: apply this patch before the patches for modname")
              ((equal decased-type "FOR")
               "[modname]: apply this patch with the patches for modname")
              ((equal decased-type "AFTER")
               "[modname]: apply this patch after the patches for modname")
              ((equal decased-type "FINAL")
               ": apply this patch in the final pass, after all others")))))

(defvar ksp-cfg-filter-payload-regexp
  (concat "\\([,&|]?\\)\\([-!@#~]\\)\\(\\s_+\\)\\(?:\\[\\("
          ksp-cfg-wildcarded-name-regexp
          "\\)\\]\\)?"))

(defun ksp-cfg-explain-filter-payload ()
  "Provide context-sensitive help related to :use filter guts.

The payloads should have been just-matched with
`ksp-cfg-filter-payload-regexp'."
  (let ((outer-context (match-string 1))
        (inner-operator (match-string 2))
        (symbol-operand (match-string 3))
        (symbol-target (match-string 4)))
    (message "filter payload: %s%s%s"
             (cl-case (string-to-char outer-context)
               (?| (concat outer-context ": ... OR "))
               ((?& ?,) (concat outer-context ": ... AND "))
               (t ""))
             (format
              (cl-case (string-to-char inner-operator)
                (?@ "%s: include %s nodes")
                ((?! ?-) "%s: exclude %s nodes")
                (?# "%s: include %s keys")
                (?~ "%s: exclude %s keys"))
              inner-operator
              symbol-operand)
             (if symbol-target (concat "matching " symbol-target) ""))))

(defvar ksp-cfg-keywords
  `((,ksp-cfg-node-decl-regexp
     (1 'ksp-cfg-operator-face)
     (2 'ksp-cfg-node-face)
     (4 'ksp-cfg-name-face nil t))
    ("^\\s-*\\(\\s.?\\)\\(name\\)\\s-*=\\s-*\\(\\s_+\\)\\s-*$"
     (1 'ksp-cfg-operator-face)
     (2 'ksp-cfg-key-face)
     (3 'ksp-cfg-name-face))
    ("^\\s-*\\(\\s.?\\)\\(\\s_+\\)\\s-*\\s.?="
     (1 'ksp-cfg-operator-face)
     (2 'ksp-cfg-key-face))
    ("\\([#~]\\)\\(\\s_+\\)"
     (1 'ksp-cfg-operator-face)
     (2 'ksp-cfg-key-face))
    ("\\_<\\([Tt]rue\\|[Ff]alse\\)\\_>"
     (1 'ksp-cfg-constant-face))
    ("\\(-?\\_<[0-9]+\\(?:\\.[0-9]+\\)?\\(?:[eE][-+]?[0-9]+\\)?\\)\\_>"
     (1 'ksp-cfg-number-face))
    (,(concat "\\(:" (regexp-opt ksp-cfg-filter-types 'symbols) "\\)")
     (1 'ksp-cfg-filter-face)))
  "Keywords used by ‘ksp-cfg-mode’ font-locking.")

(defvar ksp-cfg-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry '(?! . ?~) "." st)
    (modify-syntax-entry '(?A . ?Z) "w" st)
    (modify-syntax-entry '(?a . ?z) "w" st)
    (modify-syntax-entry '(?0 . ?9) "w" st)
    (modify-syntax-entry ?_ "_" st)
    (modify-syntax-entry ?\  "-" st)
    (modify-syntax-entry ?\t "-" st)
    (modify-syntax-entry ?\{ "(\}" st)
    (modify-syntax-entry ?\} ")\{" st)
    (modify-syntax-entry ?\[ "(\]" st)
    (modify-syntax-entry ?\] ")\[" st)
    (modify-syntax-entry ?\n "> " st)
    (modify-syntax-entry ?\r "> " st)
    (modify-syntax-entry ?/ ". 12" st)
    ;;; Note specifically that parens do not behave as parens; Squad's
    ;;; parts keywords have odd unmatched ones all over the place.

    ;;; Note also that there is no string-syntax defined; we could
    ;;; enable = for this (to end-of-line, I suppose), but that isn't
    ;;; always desirable either.
    st)
  "Syntax table used in `ksp-cfg-mode' buffers.")

(defvar ksp-cfg-mode-abbrev-table nil
  "Abbreviation table used in ‘ksp-cfg-mode’ buffers.")
(define-abbrev-table 'ksp-cfg-mode-abbrev-table '())

(defvar ksp-cfg-mode-map
  (let ((map (make-sparse-keymap "KSP-cfg mode")))
    (define-key map "\C-c\C-c" 'comment-region)
    map)
  "Keymap used in ‘ksp-cfg-mode’ buffers.")

(defun ksp-cfg-region-balance (start end)
  "Determine the structural balance across the described region.

Currently this is called with START at (point-min), so it scans
from the beginning of the buffer for any region, which is not a
good idea for full-buffer re-indentation (O(n^2)).  As KSP
configs are generally fairly small, this will do for now.

Generally END should be the beginning or end of the current line.

This simple lexer does understand and handle the // so that
commented structures do not interfere with indentation."
  (save-excursion
    (let ((s (progn
               (goto-char start)
               (beginning-of-line)
               (point))))
      (cl-loop
       initially (goto-char s)
       do (skip-chars-forward "^{}/" end)
       while (< (point) end)
       if (looking-at "{") sum +1 into balance
       else if (looking-at "}") sum -1 into balance
       else if (looking-at "//") do (end-of-line) end end end
       if (not (eql (point) (point-max)))
       do (progn (forward-char) (skip-chars-forward "^{}/"))
       end
       finally return balance))))

(defun ksp-cfg-indent-line ()
  "Indent the current line using the whole buffer.

This function uses `ksp-cfg-region-balance' with start
at (point-min), so it scans from the beginning of the buffer.
Only the current line is changed, but all previous lines are
considered.

If indenting a region, use `ksp-cfg-indent-region', which will
operate at O(n) rather than O(n^2).  See also
`ksp-cfg-indent-line-inductive' which assumes prior lines are
correct."
  (interactive "*")
  (save-excursion
    (let* ((bol (progn (beginning-of-line) (point)))
           (eol (progn (end-of-line) (point)))
           (nest (ksp-cfg-region-balance (point-min) eol))
           (local-change (ksp-cfg-region-balance bol eol))
           (goal (* ksp-cfg-basic-indent
                    (- nest (max 0 local-change))))
           (delta (- goal (current-indentation))))
      (when (and (>= goal 0) (not (zerop delta)))
        (indent-rigidly bol eol delta)))))

(defun ksp-cfg-previous-balance ()
  "Determine the previous indent level.

This does not handle comments specially, except through
`ksp-cfg-region-balance' on some previous line.  Compare with
`ksp-cfg-indent-line' for the calculation.

This value should match `ksp-cfg-region-balance' over the region
from the beginning of the buffer to just before the current
line-- assuming that was indented right."
  (save-excursion
    (beginning-of-line)
    (skip-syntax-backward "->")
    (let* ((bol (progn (beginning-of-line) (point)))
           (eol (progn (end-of-line) (point)))
           (prev-indent (ceiling (current-indentation)
                                 ksp-cfg-basic-indent))
           (local-change (ksp-cfg-region-balance bol eol)))
      (+ prev-indent (max 0 local-change)))))

(defun ksp-cfg-indent-line-inductive ()
  "Indent the current line assuming lines above are correct.

See also `ksp-cfg-indent-line'."
  (interactive "*")
  (save-excursion
    (let* ((bol (progn (beginning-of-line) (point)))
           (eol (progn (end-of-line) (point)))
           (prev-bal (ksp-cfg-previous-balance))
           (local-change (ksp-cfg-region-balance bol eol))
           (goal (* ksp-cfg-basic-indent
                    (+ prev-bal (min 0 local-change))))
           (delta (- goal (current-indentation))))
      (when (and (>= goal 0) (not (zerop delta)))
        (indent-rigidly bol eol delta)))))

(defun ksp-cfg-indent-region (start end)
  "Indent the region START .. END."
  (interactive "*r")
  (let ((garbage-collection-messages nil))
    (cl-symbol-macrolet ((work-end (min end (point-max))))
      (save-excursion
        (cl-loop
         with pr
         initially (progn
                     (goto-char start)
                     (ksp-cfg-indent-line)
                     (forward-line 1)
                     (setq pr
                           (make-progress-reporter "Indenting region..."
                                                   (point) work-end
                                                   (point) start)))
         while (< (point) work-end)
         do (progn
              (ksp-cfg-indent-line-inductive)
              (end-of-line)
              (if (not (eobp)) (forward-line))
              (and pr (progress-reporter-update pr (min (point) work-end))))
         finally (progn
                   (and pr (progress-reporter-done pr))
                   (deactivate-mark)))))))

(defun ksp-cfg-cleanup ()
  "Perform various cleanups of the buffer.

This will re-indent, convert spaces to tabs, and perform general
whitespace cleanup like trailing blank removal."
  (interactive "*")
  (tabify (point-min) (point-max))
  (ksp-cfg-indent-region (point-min) (point-max))
  (whitespace-cleanup))

;; shamelessly borrowed timer from eldoc-mode
(defvar ksp-cfg-timer nil
  "KSP-cfg's timer object.")
(defvar ksp-cfg-current-idle-delay ksp-cfg-idle-delay
  "Idle time delay in use by KSP-cfg's timer.

This is used to notice changes to `ksp-cfg-idle-delay'.")

(defun ksp-cfg-schedule-timer ()
  "Install the context-help timer.

Check first to make certain it is enabled by
`ksp-cfg-show-idle-help' and not already running.  Adjust delay
time if already running and the `ksp-cfg-idle-delay' has
changed."
  (or (not ksp-cfg-show-idle-help)
      (and ksp-cfg-timer
           (memq ksp-cfg-timer timer-idle-list))
      (setq ksp-cfg-timer
            (run-with-idle-timer
             ksp-cfg-idle-delay nil
             (lambda () (ksp-cfg-show-help)))))
  (cond ((not (= ksp-cfg-idle-delay ksp-cfg-current-idle-delay))
         (setq ksp-cfg-current-idle-delay ksp-cfg-idle-delay)
         (timer-set-idle-time ksp-cfg-timer ksp-cfg-idle-delay t))))

(defun ksp-cfg-in-value-of-key-p (key)
  "Return non-nil if point is inside the value of key KEY."
  (save-excursion
    (let ((origin (point))
          (re (concat "^\\s-*\\s.?" key "\\s-*=")))
      (search-forward-regexp re origin t))))

(defun ksp-cfg-show-help ()
  "Try to display a context-relevant help message.

Looks around the `point' for recognizable structures.  Ensures
the message doesn't go to the *Messages* buffer."
  (let ((message-log-max nil))
    (and
     (not (or this-command
              executing-kbd-macro
              (bound-and-true-p edebug-active)))
     (save-excursion
       ;; Well, let's see what we find.

       ;; First, save match state because we're running inside an
       ;; idle-timer event.  cf. elisp 24 manual 33.6.4.
       (let ((match-state (match-data)))
         (unwind-protect
             (let* ((origin (point))
                    (bol (progn (beginning-of-line) (point))))
               (goto-char origin)

               ;; Backup a step if we're off the end of the line.
               (when (and (eolp)
                          (not (bolp)))
                 (backward-char))

               ;; Ensure we aren't still bonking our heads on the end of the buffer.
               (when (not (eobp))
                 ;; Backup past the boring pair-closes
                 (skip-syntax-backward ")-" bol)

                 ;; If we're looking at something that might be a symbol, find
                 ;; the beginning.
                 (when (eq (char-syntax (char-after)) ?_)
                   (skip-syntax-backward "_" bol))

                 ;; and the beginning of any prefixed punctuation
                 (skip-syntax-backward "." bol)

                 ;; but if that puts us at the start of a [...], then do that
                 ;; again, unless it's a :has
                 (when (and (eq (char-before) ?\[)
                            (not (looking-back ":HAS\\[" bol)))
                   (backward-char)
                   (skip-syntax-backward "_" bol)
                   (skip-syntax-backward "." bol))

                 (cond
                  ((looking-at ".*=") nil) ;; no help for keys yet
                  ((and (looking-at ksp-cfg-node-decl-regexp)
                        (not (looking-back ":HAS\\[" (- (point) 5) t)))
                   (ksp-cfg-explain-node-decl))
                  ((looking-at ksp-cfg-filter-spec-regexp)
                   (ksp-cfg-explain-filter-spec))
                  ((looking-at ksp-cfg-filter-payload-regexp)
                   (ksp-cfg-explain-filter-payload))
                  ((ksp-cfg-in-value-of-key-p "attachRules")
                   (message "%s" "attachRules: list of numbers (0=false, 1=true): stack, srfAttach, allowStack, allowSrfAttach, allowCollision"))
                  ((ksp-cfg-in-value-of-key-p "name")
                   (message "%s" "name: sets the name of this node"))
                  (t nil))))
           (set-match-data match-state)))))))

(defun ksp-cfg-clear-message ()
  "Clear the message display, if any."
  (let ((message-log-max nil))
    (message nil)))

(defun ksp-cfg-maybe-cleanup-on-save ()
  "Call `ksp-cfg-cleanup' from the `before-save-hook' if enabled."
  (when ksp-cfg-cleanup-on-save
    (ksp-cfg-cleanup)))

;;;###autoload
(define-derived-mode ksp-cfg-mode fundamental-mode "KSP-cfg"
  "Major mode for editing Kerbal Space Program .cfg files.

See http://wiki.kerbalspaceprogram.com/wiki/CFG_File_Documentation
for more information on how this data is structured and how it
might be used.

\\<ksp-cfg-mode-map>"
  :group 'ksp-cfg

  ;; already buffer-local when set
  (setq font-lock-defaults  '(ksp-cfg-keywords nil t nil)
        indent-tabs-mode     t
        tab-width            ksp-cfg-tab-width
        local-abbrev-table   ksp-cfg-mode-abbrev-table
        case-fold-search     t)

  ;; make buffer-local for our purposes
  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'comment-start-skip) "//+\\s-*")
  (set (make-local-variable 'comment-end) "")
  (set (make-local-variable 'indent-line-function)
       (lambda () (funcall ksp-cfg-indent-method)))
  (set (make-local-variable 'indent-region-function)
       #'ksp-cfg-indent-region)

  (add-hook (make-local-variable 'post-command-hook)
            #'ksp-cfg-schedule-timer nil t)
  (add-hook (make-local-variable 'pre-command-hook)
            #'ksp-cfg-clear-message nil t)
  (add-hook (make-local-variable 'before-save-hook)
            #'ksp-cfg-maybe-cleanup-on-save)
  (when ksp-cfg-cleanup-on-load
    (ksp-cfg-cleanup)))

(provide 'ksp-cfg-mode)

;;; ksp-cfg-mode.el ends here

;; Local Variables:
;; indent-tabs-mode: nil
;; End:
