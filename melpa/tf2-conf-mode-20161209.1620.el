;;; tf2-conf-mode.el --- TF2 Configuration files syntax highlighting

;; Copyright (C) 2016  Guillermo Robles <guillerobles1995@gmail.com>

;; Author: Guillermo Robles <guillerobles1995@gmail.com>
;; URL: https://github.com/wynro/emacs-tf2-conf-mode
;; Package-Version: 20161209.1620
;; Package-Commit: 94c971da4a78d55da2848d1e76d513e5e0a8f7eb
;; Keywords: languages
;; Version: 1.0

;; This file is not part of GNU Emacs.

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

;; Major mode for editing TF2 Configuration files

;;; Code:

(defconst tf2-conf-font-lock-keywords
  (list
   '("\\\/\/.*" . font-lock-comment-face)
   '("\\<\\(alias\\|bind\\|cl_\\(?:d\\(?:emoviewoverride\\|ownloadfilter\\|rawhud\\)\\|showfps\\|vote_ui_active_after_voting\\)\\|d\\(?:emo\\(?:list\\|ui2?\\)\\|isguise\\)\\|ex\\(?:ec\\|it\\|plode\\)\\|f\\(?:ov\\(?:_desired\\)?\\|ps_max\\)\\|h\\(?:idepanel\\|ud_\\(?:combattext_batching\\|fastswitch\\)\\)\\|impulse\\|jpeg\\(?:_quality\\)?\\|kill\\|m\\(?:at_\\(?:bumpmap\\|compressedtextures\\|dxlevel\\|p\\(?:hong\\|icmip\\)\\|queue_mode\\|specular\\)\\|p_\\(?:autoteambalance\\|decals\\|maxrounds\\|restartround\\|\\(?:t\\(?:eams_unbalance_\\|ime\\)\\|win\\)limit\\)\\)\\|net_graph\\(?:height\\|pos\\)?\\|record demoname\\|s\\(?:ay\\(?:_team\\)?\\|creenshot\\|how\\(?:mapinfo\\|scores\\)\\|top\\|v_\\(?:all\\(?:ow\\(?:\\(?:down\\|up\\)load\\)\\|talk\\)\\|gravity\\|hltv\\|lan\\|pa\\(?:ssword\\|usable\\)\\|voiceenable\\)\\)\\|t\\(?:f_\\(?:dingaling_pitchm\\(?:\\(?:ax\\|in\\)dmg\\)\\|hud_target_id_\\(?:alpha\\|disable_floating_health\\)\\)\\|oggleconsole\\)\\|v\\(?:iewmodel_fov\\|oice\\(?:_menu_[123]\\|menu\\|record\\)\\)\\)\\>" . font-lock-builtin-face)
   '("\\<\\(tf_weapon_\\(?:b\\(?:at\\(?:_\\(?:fish\\|wood\\)\\)?\\|o\\(?:nesaw\\|ttle\\)\\|uff_item\\)\\|c\\(?:l\\(?:eaver\\|ub\\)\\|\\(?:ompound_\\|ross\\)bow\\)\\|f\\(?:i\\(?:reaxe\\|sts\\)\\|la\\(?:methrower\\|regun\\)\\)\\|grenadelauncher\\|handgun_scout_\\(?:\\(?:prim\\|second\\)ary\\)\\|jar\\(?:_milk\\)?\\|k\\(?:atana\\|nife\\)\\|l\\(?:aser_pointer\\|unchbox\\(?:_drink\\)?\\)\\|m\\(?:e\\(?:chanical_arm\\|digun\\)\\|inigun\\)\\|p\\(?:article_cannon\\|da_\\(?:engineer_\\(?:build\\|destroy\\)\\|spy\\)\\|i\\(?:pebomblauncher\\|stol\\(?:_scout\\)?\\)\\)\\|r\\(?:aygun\\|evolver\\|o\\(?:bot_arm\\|cketlauncher\\(?:_\\(?:airstrike\\|directhit\\)\\)?\\)\\)\\|s\\(?:cattergun\\|entry_revenge\\|ho\\(?:tgun_\\(?:hwg\\|p\\(?:rimary\\|yro\\)\\|soldier\\)\\|vel\\)\\|mg\\|niperrifle\\(?:_\\(?:classic\\|decap\\)\\)?\\|oda_popper\\|tickbomb\\|word\\|yringegun_medic\\)\\|wrench\\)\\)\\>" . font-lock-constant-face)
   '("\\<\\(ALT\\|BACKSPACE\\|C\\(?:APSLOCK\\|TRL\\)\\|D\\(?:EL\\|OWNARROW\\)\\|E\\(?:N\\(?:D\\|TER\\)\\|SCAPE\\)\\|F\\(?:1[012]\\|[1-9]\\)\\|HOME\\|INS\\|L\\(?:EFTARROW\\|WIN\\)\\|M\\(?:OUSE[1-5]\\|WHEEL\\(?:DOWN\\|UP\\)\\)\\|NUMLOCK\\|PG\\(?:DN\\|UP\\)\\|R\\(?:CTRL\\|IGHTARROW\\|SHIFT\\|WIN\\)\\|S\\(?:CROLLLOCK\\|EMICOLON\\|HIFT\\|PACE\\)\\|TAB\\|UPARROW\\|[]\"',.-9=A-[`-]\\)\\>" . font-lock-constant-face)
   )
  "Font lock keywords for TF2 Config Mode."
  )

(defvar tf2-conf-mode-syntax-table nil "Syntax table for `tf2-conf-mode'.")
(setq tf2-conf-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?_ "w" table)
    (modify-syntax-entry ?\/ ". 12b" table)
    (modify-syntax-entry ?\n "> b" table)
    table))

(defun tf2-conf-indent-line ()
  "Indent current line of TF2 Configuration."
  (indent-line-to 0))

(defun tf2-conf-outline-level ()
  "Outline level of TF2 Configuration."
  0)

;;;###autoload
(define-derived-mode tf2-conf-mode conf-mode "Config[TF2]"
  "Major mode for editing CS:GO configuration files."

  (setq font-lock-defaults  '(tf2-conf-font-lock-keywords nil t nil)
	case-fold-search     t)

  (set (make-local-variable 'comment-start) "//")
  (set (make-local-variable 'comment-start-skip)
       (concat (regexp-quote comment-start) "+\\s *"))
  (set (make-local-variable 'comment-end) "")

  (set (make-local-variable 'indent-line-function)
       'tf2-conf-indent-line)
)

(provide 'tf2-conf-mode)
;;; tf2-conf-mode.el ends here
