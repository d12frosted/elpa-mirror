;;; sfz-mode.el --- Major mode for SFZ files -*- lexical-binding: t; -*-

;; Copyright (C) 2019 Jean Pierre Cimalando

;; Author: Jean Pierre Cimalando <jp-dev@inbox.ru>
;; Created: 29 Dec 2019
;; Version: 0.1
;; Keywords: languages
;; Homepage: https://github.com/sfztools/emacs-sfz-mode
;; Package-Requires: ((emacs "25.1"))

;; This file is not part of GNU Emacs.

;; MIT License
;;
;; Permission is hereby granted, free of charge, to any person obtaining
;; a copy of this software and associated documentation files (the
;; "Software"), to deal in the Software without restriction, including
;; without limitation the rights to use, copy, modify, merge, publish,
;; distribute, sublicense, and/or sell copies of the Software, and to
;; permit persons to whom the Software is furnished to do so, subject to
;; the following conditions:
;;
;; The above copyright notice and this permission notice shall be
;; included in all copies or substantial portions of the Software.
;;
;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
;; NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
;; LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
;; WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:
;; This is a basic mode for edition of SFZ instruments.

;;; Code:

(require 'seq)

(defgroup sfz nil
  "Editing SFZ code."
  :group 'languages
  :prefix "sfz-")

(defface sfz-header-face
  '((t :inherit font-lock-keyword-face))
  "Face for SFZ headers."
  :group 'sfz)

(defface sfz-opcode-face
  '((t :inherit font-lock-builtin-face))
  "Face for SFZ opcodes."
  :group 'sfz)

(defface sfz-unrecognized-opcode-face
  '((t :inherit font-lock-warning-face))
  "Face for SFZ unrecognized opcodes."
  :group 'sfz)

(defface sfz-number-face
  '((t :inherit font-lock-constant-face))
  "Face for SFZ number literals."
  :group 'sfz)

(defface sfz-string-face
  '((t :inherit font-lock-string-face))
  "Face for SFZ string literals."
  :group 'sfz)

(defvar sfz-mode-hook nil)

(defvar sfz-mode-map
  (let ((map (make-sparse-keymap)))
    map)
  "Keymap used in `sfz-mode' buffers.")

(defvar sfz--all-headers
  '("<region>" "<group>" "<control>" "<global>" "<curve>" "<effect>" "<master>" "<midi>")
  "The current list of documented SFZ headers (as of 29th December 2019).")

(defvar sfz--all-opcodes
  '("#define" "#include" "*_mod" "amp_keycenter" "amp_keytrack" "amp_random" "amp_velcurve_N" "amp_veltrack" "ampeg_attack" "ampeg_attack_onccN" "ampeg_attack_shape" "ampeg_attackccN" "ampeg_decay" "ampeg_decay_onccN" "ampeg_decay_shape" "ampeg_decay_zero" "ampeg_decayccN" "ampeg_delay" "ampeg_delay_onccN" "ampeg_delayccN" "ampeg_dynamic" "ampeg_hold" "ampeg_hold_onccN" "ampeg_holdccN" "ampeg_release" "ampeg_release_onccN" "ampeg_release_shape" "ampeg_release_zero" "ampeg_releaseccN" "ampeg_start" "ampeg_start_onccN" "ampeg_startccN" "ampeg_sustain" "ampeg_sustain_onccN" "ampeg_sustainccN" "amplfo_delay" "amplfo_depth" "amplfo_depth_onccN" "amplfo_depthccN" "amplfo_depthchanaft" "amplfo_depthpolyaft" "amplfo_fade" "amplfo_freq" "amplfo_freqccN" "amplfo_freqchanaft" "amplfo_freqpolyaft" "amplitude" "amplitude_curveccN" "amplitude_onccN" "amplitude_smoothccN" "bend_down" "bend_smooth" "bend_step" "bend_stepdown" "bend_stepup" "bend_up" "count" "curve_index" "cutoff" "cutoff2" "cutoff2_curveccN" "cutoff2_onccN" "cutoff2_smoothccN" "cutoff2_stepccN" "cutoff_ccN" "cutoff_chanaft" "cutoff_curveccN" "cutoff_onccN" "cutoff_polyaft" "cutoff_smoothccN" "cutoff_stepccN" "default_path" "delay" "delay_beats" "delay_ccN" "delay_onccN" "delay_random" "delay_samples" "delay_samples_onccN" "direction" "effect1" "effect2" "egN_amplitude" "egN_amplitude_onccX" "egN_bitred" "egN_bitred_onccX" "egN_curveX" "egN_cutoff" "egN_cutoff2" "egN_cutoff2_onccX" "egN_cutoff_onccX" "egN_decim" "egN_decim_onccX" "egN_depth_lfoX" "egN_depthadd_lfoX" "egN_driveshape" "egN_driveshape_onccX" "egN_eqXbw" "egN_eqXbw_onccY" "egN_eqXfreq" "egN_eqXfreq_onccY" "egN_eqXgain" "egN_eqXgain_onccY" "egN_freq_lfoX" "egN_levelX" "egN_levelX_onccY" "egN_loop" "egN_loop_count" "egN_noiselevel" "egN_noiselevel_onccX" "egN_noisestep" "egN_noisestep_onccX" "egN_noisetone" "egN_noisetone_onccX" "egN_pan" "egN_pan_curve" "egN_pan_curveccX" "egN_pan_onccX" "egN_pitch" "egN_pitch_onccX" "egN_points" "egN_rectify" "egN_rectify_onccX" "egN_resonance" "egN_resonance2" "egN_resonance2_onccX" "egN_resonance_onccX" "egN_ringmod" "egN_ringmod_onccX" "egN_shapeX" "egN_sustain" "egN_timeX" "egN_timeX_onccY" "egN_volume" "egN_volume_onccX" "egN_width" "egN_width_onccX" "end" "eqN_bw" "eqN_bw_onccX" "eqN_bwccX" "eqN_dynamic" "eqN_freq" "eqN_freq_onccX" "eqN_freqccX" "eqN_gain" "eqN_gain_onccX" "eqN_gainccX" "fil2_keycenter" "fil2_keytrack" "fil2_type" "fil2_veltrack" "fil_keycenter" "fil_keytrack" "fil_random" "fil_type" "fil_veltrack" "fileg_attack" "fileg_attack_onccN" "fileg_attack_shape" "fileg_decay" "fileg_decay_onccN" "fileg_decay_shape" "fileg_decay_zero" "fileg_delay" "fileg_delay_onccN" "fileg_depth" "fileg_depth_onccN" "fileg_dynamic" "fileg_hold" "fileg_hold_onccN" "fileg_release" "fileg_release_onccN" "fileg_release_shape" "fileg_release_zero" "fileg_start" "fileg_start_onccN" "fileg_sustain" "fileg_sustain_onccN" "fillfo_delay" "fillfo_depth" "fillfo_depth_onccN" "fillfo_depthccN" "fillfo_depthchanaft" "fillfo_depthpolyaft" "fillfo_fade" "fillfo_freq" "fillfo_freqccN" "fillfo_freqchanaft" "fillfo_freqpolyaft" "gain_ccN" "gain_onccN" "global_amplitude" "global_label" "global_volume" "group" "group_amplitude" "group_label" "group_volume" "hibend" "hibpm" "hiccN" "hichan" "hichanaft" "hihdccN" "hikey" "hint_*" "hipolyaft" "hiprog" "hirand" "hitimer" "hivel" "image" "key" "label_ccN" "lfoN_amplitude" "lfoN_amplitude_onccX" "lfoN_amplitude_smoothccX" "lfoN_amplitude_stepccX" "lfoN_bitred" "lfoN_bitred_onccX" "lfoN_bitred_smoothccX" "lfoN_bitred_stepccX" "lfoN_count" "lfoN_cutoff" "lfoN_cutoff2" "lfoN_cutoff2_onccX" "lfoN_cutoff2_smoothccX" "lfoN_cutoff2_stepccX" "lfoN_cutoff_onccX" "lfoN_cutoff_smoothccX" "lfoN_cutoff_stepccX" "lfoN_decim" "lfoN_decim_onccX" "lfoN_decim_smoothccX" "lfoN_decim_stepccX" "lfoN_delay" "lfoN_delay_onccX" "lfoN_depth_lfoX" "lfoN_depthadd_lfoX" "lfoN_drive" "lfoN_drive_onccX" "lfoN_drive_smoothccX" "lfoN_drive_stepccX" "lfoN_eqXbw" "lfoN_eqXbw_onccY" "lfoN_eqXbw_smoothccY" "lfoN_eqXbw_stepccY" "lfoN_eqXfreq" "lfoN_eqXfreq_onccY" "lfoN_eqXfreq_smoothccY" "lfoN_eqXfreq_stepccY" "lfoN_eqXgain" "lfoN_eqXgain_onccY" "lfoN_eqXgain_smoothccY" "lfoN_eqXgain_stepccY" "lfoN_fade" "lfoN_fade_onccX" "lfoN_freq" "lfoN_freq_lfoX" "lfoN_freq_onccX" "lfoN_freq_smoothccX" "lfoN_freq_stepccX" "lfoN_noiselevel" "lfoN_noiselevel_onccX" "lfoN_noiselevel_smoothccX" "lfoN_noiselevel_stepccX" "lfoN_noisestep" "lfoN_noisestep_onccX" "lfoN_noisestep_smoothccX" "lfoN_noisestep_stepccX" "lfoN_noisetone" "lfoN_noisetone_onccX" "lfoN_noisetone_smoothccX" "lfoN_noisetone_stepccX" "lfoN_offsetX" "lfoN_pan" "lfoN_pan_onccX" "lfoN_pan_smoothccX" "lfoN_pan_stepccX" "lfoN_phase" "lfoN_phase_onccX" "lfoN_pitch" "lfoN_pitch_onccX" "lfoN_pitch_smoothccX" "lfoN_pitch_stepccX" "lfoN_ratio" "lfoN_resonance" "lfoN_resonance2" "lfoN_resonance2_onccX" "lfoN_resonance2_smoothccX" "lfoN_resonance2_stepccX" "lfoN_resonance_onccX" "lfoN_resonance_smoothccX" "lfoN_resonance_stepccX" "lfoN_scale" "lfoN_smooth" "lfoN_smooth_onccX" "lfoN_stepX" "lfoN_steps" "lfoN_volume" "lfoN_volume_onccX" "lfoN_volume_smoothccX" "lfoN_volume_stepccX" "lfoN_wave" "lfoN_wave2" "lfoN_wave_onccX" "lfoN_width" "lfoN_width_onccX" "lfoN_width_smoothccX" "lfoN_width_stepccX" "load_end" "load_mode" "load_start" "lobend" "lobpm" "loccN" "lochan" "lochanaft" "lohdccN" "lokey" "loop_count" "loop_crossfade" "loop_end" "loop_mode" "loop_start" "loop_type" "loopend" "loopmode" "loopstart" "lopolyaft" "loprog" "lorand" "lotimer" "lovel" "master_amplitude" "master_label" "master_volume" "md5" "noise_filter" "noise_level" "noise_level_onccN" "noise_level_smoothccN" "noise_step" "noise_step_onccN" "noise_stereo" "noise_tone" "noise_tone_onccN" "note_offset" "note_polyphony" "note_selfmask" "octave_offset" "off_by" "off_curve" "off_mode" "off_shape" "off_time" "offset" "offset_ccN" "offset_onccN" "offset_random" "on_hiccN" "on_loccN" "oscillator" "oscillator_detune" "oscillator_detune_onccN" "oscillator_mod_depth" "oscillator_mod_depth_onccN" "oscillator_mod_smoothccN" "oscillator_mode" "oscillator_multi" "oscillator_phase" "oscillator_quality" "oscillator_table_size" "output" "pan" "pan_curveccN" "pan_keycenter" "pan_keytrack" "pan_law" "pan_onccN" "pan_smoothccN" "pan_stepccN" "pan_veltrack" "param_offset" "phase" "pitch" "pitch_curveccN" "pitch_keycenter" "pitch_keytrack" "pitch_onccN" "pitch_random" "pitch_smoothccN" "pitch_stepccN" "pitch_veltrack" "pitcheg_attack" "pitcheg_attack_onccN" "pitcheg_attack_shape" "pitcheg_decay" "pitcheg_decay_onccN" "pitcheg_decay_shape" "pitcheg_decay_zero" "pitcheg_delay" "pitcheg_delay_onccN" "pitcheg_depth" "pitcheg_depth_onccN" "pitcheg_dynamic" "pitcheg_hold" "pitcheg_hold_onccN" "pitcheg_release" "pitcheg_release_onccN" "pitcheg_release_shape" "pitcheg_release_zero" "pitcheg_start" "pitcheg_start_onccN" "pitcheg_sustain" "pitcheg_sustain_onccN" "pitchlfo_delay" "pitchlfo_depth" "pitchlfo_depth_onccN" "pitchlfo_depthccN" "pitchlfo_depthchanaft" "pitchlfo_depthpolyaft" "pitchlfo_fade" "pitchlfo_freq" "pitchlfo_freqccN" "pitchlfo_freqchanaft" "pitchlfo_freqpolyaft" "polyphony" "polyphony_group" "position" "region_label" "resonance" "resonance2" "resonance2_curveccN" "resonance2_onccN" "resonance2_smoothccN" "resonance2_stepccN" "resonance_curveccN" "resonance_onccN" "resonance_smoothccN" "resonance_stepccN" "reverse_hiccN" "reverse_loccN" "rt_dead" "rt_decay" "sample" "sample_quality" "script" "seq_length" "seq_position" "set_ccN" "set_hdccN" "sostenuto_cc" "sostenuto_lo" "sostenuto_sw" "start_hiccN" "start_loccN" "stop_beats" "stop_hiccN" "stop_loccN" "sustain_cc" "sustain_lo" "sustain_sw" "sw_default" "sw_down" "sw_hikey" "sw_hilast" "sw_label" "sw_last" "sw_lokey" "sw_lolast" "sw_note_offset" "sw_octave_offset" "sw_previous" "sw_up" "sw_vel" "sync_beats" "sync_offset" "transpose" "trigger" "tune" "tune_curveccN" "tune_onccN" "tune_smoothccN" "tune_stepccN" "vN" "varNN_curveccX" "varNN_mod" "varNN_onccX" "varNN_target" "vendor_specific" "volume" "volume_curveccN" "volume_onccN" "volume_smoothccN" "volume_stepccN" "waveguide" "width" "width_curveccN" "width_onccN" "width_smoothccN" "width_stepccN" "xf_cccurve" "xf_keycurve" "xf_velcurve" "xfin_hiccN" "xfin_hikey" "xfin_hivel" "xfin_loccN" "xfin_lokey" "xfin_lovel" "xfout_hiccN" "xfout_hikey" "xfout_hivel" "xfout_loccN" "xfout_lokey" "xfout_lovel")
  "The current list of documented SFZ opcodes (as of 29th December 2019).")

(defun sfz--make-regex-S (opcode-S)
  "Create a regular expression to match a special opcode OPCODE-S."
  (with-output-to-string
    (princ "\\(?:")
    (seq-doseq (char opcode-S)
      (princ (cond ((member char '(?N ?X ?Y)) "[0-9]+")
                   ((member char '(?*)) "[a-zA-Z_][a-zA-Z0-9_]*")
                   (t (regexp-quote (char-to-string char))))))
    (princ "\\)")))

(defun sfz--S-opcode-p (opcode)
  "Return whether the OPCODE argument is special: numbered or wildcard."
  (seq-some (lambda (char) (seq-contains opcode char)) '(?N ?X ?Y ?*)))

(defun sfz--regexp-opt (strings)
  "Create an optimized regex from a list STRINGS of sfz opcodes.
This works in a similar fashion to REGEXP-OPT.  The opcodes which contain
characters N, X, Y or * are specially handled: these are substituted with
appropriate expressions to handle numbering and wildcards."
  (with-output-to-string
    (princ "\\(")
    (let* ((nonN-strings (seq-filter (lambda (s) (not (sfz--S-opcode-p s))) strings))
           (N-strings (seq-filter #'sfz--S-opcode-p strings))
           (nonN-regexp (regexp-opt nonN-strings))
           (N-regexp (mapconcat #'identity (mapcar #'sfz--make-regex-S N-strings) "\\|")))
      (princ nonN-regexp)
      (unless (seq-some #'seq-empty-p `(,nonN-regexp ,N-regexp)) (princ "\\|"))
      (princ N-regexp))
    (princ "\\)")))

(defvar sfz-font-lock-keywords
  `(;; the headers, eg. "<region>"
    (,(regexp-opt sfz--all-headers t) . 'sfz-header-face)
    ;; the opcodes, eg. "sample"
    (,(concat "\\<" (sfz--regexp-opt sfz--all-opcodes) "\\>") . 'sfz-opcode-face)
    ;; the numeric rhs
    ("=\\([-+]?[0-9]?\.[0-9]+\\>\\)" 1 'sfz-number-face)
    ("=\\([-+]?[0-9]+\\>\\)" 1 'sfz-number-face)
    ;; the string rhs (right whitespace match for several statements on one line)
    ("=\\([a-zA-Z0-9-_#.& \t/\\(),*]+\\)\\(?: \\|\t\\|$\\)" 1 'sfz-string-face)
    ;; the unrecognized opcode
    ("\\<\\([a-zA-Z0-9_]+\\)=" 1 'sfz-unrecognized-opcode-face))
  "Default highlighting expressions for `sfz-mode'.")

(defun sfz-indent-line ()
  "Indent current line as SFZ code."
  (interactive)
  (indent-line-to 0))

(defvar sfz-mode-syntax-table
  (let ((st (make-syntax-table)))
    (modify-syntax-entry ?_ "w" st)
    (modify-syntax-entry ?# "w" st) ; allow ?# as part of word (#define, #include)
    (modify-syntax-entry ?/ ". 124b" st)
    (modify-syntax-entry ?* ". 23" st)
    (modify-syntax-entry ?\n "> b" st)
    st)
  "Syntax table for `sfz-mode'.")

;;;###autoload
(define-derived-mode sfz-mode prog-mode "SFZ"
  "Major mode for editing SFZ files."
  :group 'sfz
  (set (make-local-variable 'font-lock-defaults) '(sfz-font-lock-keywords))
  (set (make-local-variable 'indent-line-function) 'sfz-indent-line)
  (set (make-local-variable 'comment-start) "// ")
  (set (make-local-variable 'comment-start-skip) "//+\\s *"))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sfz\\'" . sfz-mode))

(provide 'sfz-mode)
;;; sfz-mode.el ends here
