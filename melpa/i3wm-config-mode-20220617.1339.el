;;; i3wm-config-mode.el --- Better syntax highlighting for i3wm's config file -*- lexical-binding: t -*-

;; Copyright (C) 2020 Alexander Miller

;; Author: Alexander Miller <alexanderm@web.de>
;; Package-Requires: ((emacs "24.1"))
;; Package-Version: 20220617.1339
;; Package-Commit: 3574d88241118ed6cc5a3022b6dde58d6f5af9dd
;; Homepage: https://github.com/Alexander-Miller/i3wm-Config-Mode
;; Version: 1.0
;; Keywords: faces, languages, i3wm, font-lock

;; This program is free software; you can redistribute it and/or modify
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
;; Better syntax highlighting for i3wm's config.  Everything else is inherited
;; from `conf-space-mode.'

;;; Code:

(defgroup i3wm-config nil
  "Configuration options for i3wm-config-mode."
  :prefix "i3wm-config-"
  :group 'conf
  :link '(url-link :tag "URL" "https://github.com/Alexander-Miller/i3wm-Config-Mode")
  :link '(emacs-commentary-link :tag "Commentary" "i3wm-config-mode.el"))

(defface i3wm-config-verb
  '((t :inherit font-lock-function-name-face))
  "Face for actions or verbs like 'set', 'bindsym', 'move' etc.")

(defface i3wm-config-flag
  '((t :inherit font-lock-type-face))
  "Face for flags like '--release' and '--no-startup-id'.")

(defface i3wm-config-variable
  '((t :inherit font-lock-constant-face))
  "Face for $variables.")

(defface i3wm-config-value-assign
  '((t :inherit font-lock-variable-name-face))
  "Face for value assignments - e.g. the 'y' in 'set x y'.")

(defface i3wm-config-numbers
  '((t :inherit font-lock-constant-face))
  "Face for numbers.")

(defface i3wm-config-bindsym-key
  '((t :inherit font-lock-variable-name-face))
  "Face for the keys used in bindsym assignments.")

(defface i3wm-config-unit
  '((t :inherit font-lock-type-face))
  "Face for units like 'px', 'ms', 'ppt'.")

(defface i3wm-config-for-window-predictate
  '((t :inherit font-lock-builtin-face))
  "Face for the predicates in for_window assignments -
the 'x' in 'for_window [x=y]'.")

(defface i3wm-config-exec
  '((t :inherit font-lock-builtin-face))
  "Face for the text inside an exec statement.")

(defface i3wm-config-adjective
  '((t :inherit font-lock-type-face))
  "Face for adjectives and modifiers like 'floating', 'tabbed', 'sticky' or 'current'.")

(defface i3wm-config-noun
  '((t :inherit font-lock-keyword-face))
  "Face for fixed noun & keywords like 'workspace', 'mode', 'position' or 'fullscreen'.")

(defface i3wm-config-constant
  '((t :inherit font-lock-constant-face))
  "Face for constant values like 'top', 'invisble', 'yes' or 'no'.")

(defface i3wm-config-operator
  '((t :inherit font-lock-builtin-face))
  "Face for various operators like '&&', '+', and '|'.")

(defface i3wm-config-block-name
  '((t :inherit font-lock-type-face))
  "Face for curly brace delimited block name like 'colors { ... }'.")

(defvar i3wm-config-font-lock-keywords
  `(
    ;; Bindsym keys
    ( ,(rx
        (group-n 1 "bindsym")
        (0+ space)
        (opt
         (group-n 2 (? "--" (1+ (or alnum "-" "_")))))
        (0+ space)
        (opt
         (or (group-n 3 "$" (1+ alnum))
             (group-n 4 (1+ alnum)))
         (? (group-n 5 "+")))
        (opt
         (or (group-n 6 "$" (1+ alnum))
             (group-n 7 (1+ alnum)))
         (? (group-n 8 "+")))
        (opt
         (or (group-n 9 "$" (1+ alnum))
             (group-n 10 (1+ alnum)))
         (? (group-n 11 "+"))))
      (1 'i3wm-config-verb nil t)
      (2 'i3wm-config-flag nil t)
      (3 'i3wm-config-variable nil t)
      (4 'i3wm-config-bindsym-key nil t)
      (5 'i3wm-config-operator nil t)
      (6 'i3wm-config-variable nil t)
      (7 'i3wm-config-bindsym-key nil t)
      (8 'i3wm-config-operator nil t)
      (9 'i3wm-config-variable nil t)
      (10 'i3wm-config-bindsym-key nil t)
      (11 'i3wm-config-operator nil t))

    ;; set from resource
    ( ,(rx
        (group-n 1 "set_from_resource")
        (0+ space)
        (opt
         (group-n 2 "$" (1+ alnum))
         (opt
          (0+ space)
          (group-n 3 (1+ word))
          (opt
           (0+ space)
           (group-n 4 (1+ any))))))
      (1 'i3wm-config-verb nil t)
      (2 'i3wm-config-variable nil t)
      (3 'i3wm-config-value-assign nil t)
      (4 'i3wm-config-constant nil t))

    ;; Exec
    ( ,(rx
        (group-n 1 "exec" (? "_" (1+ alnum)))
        (0+ space)
        (opt
         (group-n 2 (? "--" (1+ (or alnum "-" "_"))))
         (0+ space)
         (opt
          (group-n 3 (1+ any) eol))))
      (1 'i3wm-config-verb nil t)
      (2 'i3wm-config-flag nil t)
      (3 'i3wm-config-exec nil t))

    ;; floating modifier set
    ( ,(rx
        (group-n 1 "floating_modifier")
        (0+ space)
        (opt
         (group-n 2 "$" (1+ (or "-" "_" alnum)))))
      (1 'i3wm-config-noun nil t)
      (2 'i3wm-config-value-assign nil t))


    ;; Set
    ( ,(rx
        (group-n 1 "set")
        (0+ space)
        (opt
         (group-n 2 "$" (1+ (or "-" "_" alnum)))
         (opt
          (group-n 3 (1+ any) eol))))
      (1 'i3wm-config-verb nil t)
      (2 'i3wm-config-variable nil t)
      (3 'i3wm-config-value-assign nil t))

    ;; Colon assignments
    ( ,(rx (seq
            (1+ nonl)
            ":"
            (group-n 1 (1+ (not (any "\n" "\""))))))
      1
      'i3wm-config-value-assign)

    ;; Block openers
    ( ,(rx (seq
            symbol-start
            (group-n 1 (1+ (or "_" "-" word)))
            symbol-end
            (opt (1+ space) "\"" (0+ any) "\"")
            (1+ space)
            "{"))
      1 'i3wm-config-block-name)

    ;; Verbs
    ( ,(rx
        (seq
         symbol-start
         (or
          "set"
          "disable"
          "set_from_resource"
          "back_and_forth"
          "bindsym"
          "to"
          "or"
          "exec"
          "exec_always"
          "kill"
          "nop"
          "move"
          "show"
          "split"
          "focus"
          "toggle"
          "i3-msg"
          "reload"
          "restart"
          "resize"
          "grow"
          "shrink"
          "plus"
          "minus"
          "enable"
          "assign"
          "for_window"
          "no_focus")
         symbol-end))
      0
      'i3wm-config-verb)

    ;; Adjectives/modifiers
    ( ,(rx (seq
            symbol-start
            (or
             "tabbed"
             "stacking"
             "left"
             "right"
             "up"
             "down"
             "urgent"
             "sticky"
             "current"
             "global"
             "outer"
             "inner"
             "latest"
             "floating"
             "mode_toggle"
             "all"
             "h"
             "v")
            symbol-end))
      0
      'i3wm-config-adjective)

    ;; Nouns
    ( ,(rx (seq
            symbol-start
            (or
             "scratchpad"
             "workspace_auto_back_and_forth"
             "workspace_buttons"
             "workspace"
             "mode"
             "gaps"
             "output"
             "parent"
             "child"
             "container"
             "layout"
             "height"
             "width"
             "focus_follows_mouse"
             "smart_borders"
             "smart_gaps"
             "mouse_warping"
             "force_display_urgency_hint"
             "new_window"
             "new_float"
             "font"
             "focus_on_window_activation"
             "pango"
             "status_command"
             "i3bar_command"
             "border"
             "position"
             "tray_padding"
             "tray_output"
             "strip_workspace_numbers"
             "binding_mode_indicator"
             "background"
             "binding_mode"
             "statusline"
             "separator_symbol"
             "separator"
             "focused_workspace"
             "active_workspace"
             "inactive_workspace"
             "urgent_workspace"
             "number"
             "window"
             "fullscreen")
            symbol-end))
      (0 'i3wm-config-noun nil t))

    ;; numbers
    ( ,(rx (seq
            symbol-start
            (? (or "-" "+"))
            (group-n 1 (1+ num))))
      1
      'i3wm-config-numbers)

    ;; Constants
    ( ,(rx
        (seq
         symbol-start
         (or
          "i3bar"
          "yes"
          "no"
          "on"
          "none"
          "top"
          "invisible"
          "hidden"
          "dock"
          "mouse")
         symbol-end))
      0 'i3wm-config-constant)

    ;; Units
    ( ,(rx (seq
            (? (1+ num))
            (group-n 1 (or "px" "pixel" "ms" "ppt"))
            symbol-end))
      1 'i3wm-config-unit)

    ;; + = | : etc
    ( ,(rx (or "+" "&&" "-" "=" "|" ":" "," ";"))
      0 'i3wm-config-operator)

    ;; for_window predicates
    ( ,(rx (or
            "class"
            "title"
            "instance"
            "window_role"
            "window_type"))
      0 'i3wm-config-for-window-predictate)

    ;; client.*color* assigments
    ( ,(rx (seq
            symbol-start
            (1+ (or "_" word))
            "."
            (1+ (or "_"  word))
            symbol-end))
      0 'i3wm-config-noun)))

;;;###autoload
(define-derived-mode i3wm-config-mode conf-space-mode "i3wm Config"
  (font-lock-add-keywords nil i3wm-config-font-lock-keywords 'set))

;;;###autoload
(add-to-list 'auto-mode-alist '("i3/config\\'" . i3wm-config-mode))

(provide 'i3wm-config-mode)

;;; i3wm-config-mode.el ends here
