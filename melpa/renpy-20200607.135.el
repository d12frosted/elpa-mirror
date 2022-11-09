;;; renpy.el --- silly walks for Renpy  -*- coding: iso-8859-1 -*-

;; Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009
;;   Free Software Foundation, Inc.
;; Copyright (C) 2018
;;   Billy Wade

;; Author: PyTom <pytom@bishoujo.us>

;; Based on python.el, which has the following maintainership:

;; Maintainer: Dave Love <fx@gnu.org>; Quildreen Motta <https://github.com/robotlolita>; Billy Wade <https://github.com/billywade>
;; Created: Nov 2003
;; Version: 0.3
;; Package-Version: 20200607.135
;; Package-Commit: f2f95a72a8c842f229f80999132e8ea8ee73f6fc
;; Homepage: https://github.com/billywade/renpy-mode
;; Keywords: languages

;;; Commentary:

;; PyTom's old major mode for Ren'Py, the visual studio engine

;;; License:

;; This file is part of GNU Emacs.

;; GNU Emacs is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Emacs is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <http://www.gnu.org/licenses/>.

;;; Code:

(setq renpy-generic-imenu 
      '( ( nil "\\b\\(label\\|menu\\)\\s-+\\(\\w+\\):" 2)
         ( nil "\\b\\(screen\\)\\s-+\\(\\w+\\):" 2)
         ( nil "\\b\\(transform\\)\\s-+\\(\\w+\\):" 2)
         ; ( nil "\\bcall\\s-+\\w+\\s-+from\\s-+\\(\\w+\\)" 1)
         ( nil "\\b\\(def\\|class\\)\\s-+\\(\\w+\\)" 2)
         ))

(require 'comint)

(eval-when-compile
  (require 'compile)
  (require 'hippie-exp))

(autoload 'comint-mode "comint")

(defgroup renpy nil
  "Silly walks in the Renpy language."
  :group 'languages
  :version "22.1"
  :link '(emacs-commentary-link "renpy"))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.rpy\\'" . renpy-mode))
(add-to-list 'auto-mode-alist '("\\.rpym\\'" . renpy-mode))
(add-to-list 'same-window-buffer-names "*Renpy*")

;;;; Font lock

(defvar renpy-font-lock-keywords
  `(,(rx symbol-start
	 ;; From v 2.5 reference, � keywords.
	 ;; def and class dealt with separately below
	 (or "and" "as" "assert" "break" "continue" "del" "elif" "else"
	     "except" "exec" "finally" "for" "from" "global" "if"
	     "import" "in" "is" "lambda" "not" "or" "pass" "print"
	     "raise" "return" "try" "while" "with" "yield"
             ;; Not real keywords, but close enough to be fontified as such
             "self" "True" "False"
"$"
"add"
"and"
"animation"
"as"
"as"
"assert"
"at"
"bar"
"behind"
"block"
"break"
"button"
"call"
"choice"
"circles"
"class"
"clockwise"
"contains"
"continue"
"counterclockwise"
"def"
"define"
"del"
"elif"
"else"
"event"
"except"
"exec"
"expression"
"finally"
"fixed"
"for"
"frame"
"from"
"function"
"global"
"grid"
"has"
"hbox"
"hide"
"hotbar"
"hotspot"
"if"
"if"
"image"
"imagebutton"
"imagemap"
"import"
"in"
"in"
"init"
"input"
"is"
"jump"
"key"
"knot"
"label"
"lambda"
"menu"
"not"
"null"
"nvl"
"on"
"onlayer"
"or"
"parallel"
"pass"
"pause"
"play"
"print"
"python"
"queue"
"raise"
"repeat"
"return"
"return"
"scene"
"screen"
"set"
"show"
"side"
"stop"
"text"
"textbutton"
"time"
"timer"
"transform"
"transform"
"try"
"use"
"vbar"
"vbox"
"viewport"
"while"
"while"
"window"
"with"
"with"
"yield"
"zorder"
             )
	 symbol-end)
    (,(rx symbol-start "None" symbol-end)	; see � Keywords in 2.5 manual
     . font-lock-constant-face)
    ;; Definitions
    (,(rx symbol-start (group "class") (1+ space) (group (1+ (or word ?_))))
     (1 font-lock-keyword-face) (2 font-lock-type-face))
    (,(rx symbol-start (group "label") (1+ space) (group (1+ (or word ?_))))
     (1 font-lock-keyword-face) (2 font-lock-type-face))
    (,(rx symbol-start (group "screen") (1+ space) (group (1+ (or word ?_))))
     (1 font-lock-keyword-face) (2 font-lock-type-face))
    (,(rx symbol-start (group "transform") (1+ space) (group (1+ (or word ?_))))
     (1 font-lock-keyword-face) (2 font-lock-type-face))
    (,(rx symbol-start (group "def") (1+ space) (group (1+ (or word ?_))))
     (1 font-lock-keyword-face) (2 font-lock-function-name-face))
    ;; Top-level assignments are worth highlighting.
    (,(rx line-start (group (1+ (or word ?_))) (0+ space) "=")
     (1 font-lock-variable-name-face))
    (,(rx line-start (* (any " \t")) (group "@" (1+ (or word ?_)))) ; decorators
     (1 font-lock-type-face))
    ;; Built-ins.  (The next three blocks are from
    ;; `__builtin__.__dict__.keys()' in Renpy 2.5.1.)  These patterns
    ;; are debateable, but they at least help to spot possible
    ;; shadowing of builtins.
    (,(rx symbol-start (or
	  ;; exceptions
	  "ArithmeticError" "AssertionError" "AttributeError"
	  "BaseException" "DeprecationWarning" "EOFError"
	  "EnvironmentError" "Exception" "FloatingPointError"
	  "FutureWarning" "GeneratorExit" "IOError" "ImportError"
	  "ImportWarning" "IndentationError" "IndexError" "KeyError"
	  "KeyboardInterrupt" "LookupError" "MemoryError" "NameError"
	  "NotImplemented" "NotImplementedError" "OSError"
	  "OverflowError" "PendingDeprecationWarning" "ReferenceError"
	  "RuntimeError" "RuntimeWarning" "StandardError"
	  "StopIteration" "SyntaxError" "SyntaxWarning" "SystemError"
	  "SystemExit" "TabError" "TypeError" "UnboundLocalError"
	  "UnicodeDecodeError" "UnicodeEncodeError" "UnicodeError"
	  "UnicodeTranslateError" "UnicodeWarning" "UserWarning"
	  "ValueError" "Warning" "ZeroDivisionError") symbol-end)
     . font-lock-type-face)
    (,(rx (or line-start (not (any ". \t"))) (* (any " \t")) symbol-start
	  (group (or
	  ;; callable built-ins, fontified when not appearing as
	  ;; object attributes
	  "abs" "all" "any" "apply" "basestring" "bool" "buffer" "callable"
	  "chr" "classmethod" "cmp" "coerce" "compile" "complex"
	  "copyright" "credits" "delattr" "dict" "dir" "divmod"
	  "enumerate" "eval" "execfile" "exit" "file" "filter" "float"
	  "frozenset" "getattr" "globals" "hasattr" "hash" "help"
	  "hex" "id" "input" "int" "intern" "isinstance" "issubclass"
	  "iter" "len" "license" "list" "locals" "long" "map" "max"
	  "min" "object" "oct" "open" "ord" "pow" "property" "quit"
	  "range" "raw_input" "reduce" "reload" "repr" "reversed"
	  "round" "set" "setattr" "slice" "sorted" "staticmethod"
	  "str" "sum" "super" "tuple" "type" "unichr" "unicode" "vars"
	  "xrange" "zip"
"action"
"activate_align"
"activate_alignaround"
"activate_alpha"
"activate_anchor"
"activate_angle"
"activate_antialias"
"activate_area"
"activate_around"
"activate_background"
"activate_bar_invert"
"activate_bar_resizing"
"activate_bar_vertical"
"activate_black_color"
"activate_bold"
"activate_bottom_bar"
"activate_bottom_gutter"
"activate_bottom_margin"
"activate_bottom_padding"
"activate_box_layout"
"activate_clipping"
"activate_color"
"activate_corner1"
"activate_corner2"
"activate_crop"
"activate_delay"
"activate_drop_shadow"
"activate_drop_shadow_color"
"activate_first_indent"
"activate_first_spacing"
"activate_fit_first"
"activate_font"
"activate_foreground"
"activate_italic"
"activate_justify"
"activate_language"
"activate_layout"
"activate_left_bar"
"activate_left_gutter"
"activate_left_margin"
"activate_left_padding"
"activate_line_spacing"
"activate_min_width"
"activate_minwidth"
"activate_mouse"
"activate_offset"
"activate_outlines"
"activate_pos"
"activate_radius"
"activate_rest_indent"
"activate_right_bar"
"activate_right_gutter"
"activate_right_margin"
"activate_right_padding"
"activate_rotate"
"activate_rotate_pad"
"activate_size"
"activate_size_group"
"activate_slow_abortable"
"activate_slow_cps"
"activate_slow_cps_multiplier"
"activate_sound"
"activate_spacing"
"activate_subpixel"
"activate_text_align"
"activate_text_y_fudge"
"activate_thumb"
"activate_thumb_offset"
"activate_thumb_shadow"
"activate_top_bar"
"activate_top_gutter"
"activate_top_margin"
"activate_top_padding"
"activate_underline"
"activate_unscrollable"
"activate_xalign"
"activate_xanchor"
"activate_xanchoraround"
"activate_xaround"
"activate_xfill"
"activate_xmargin"
"activate_xmaximum"
"activate_xminimum"
"activate_xoffset"
"activate_xpadding"
"activate_xpos"
"activate_xzoom"
"activate_yalign"
"activate_yanchor"
"activate_yanchoraround"
"activate_yaround"
"activate_yfill"
"activate_ymargin"
"activate_ymaximum"
"activate_yminimum"
"activate_yoffset"
"activate_ypadding"
"activate_ypos"
"activate_yzoom"
"activate_zoom"
"adjustment"
"align"
"alignaround"
"allow"
"alpha"
"anchor"
"angle"
"antialias"
"area"
"around"
"auto"
"background"
"bar_invert"
"bar_resizing"
"bar_vertical"
"black_color"
"bold"
"bottom_bar"
"bottom_gutter"
"bottom_margin"
"bottom_padding"
"box_layout"
"changed"
"child_size"
"clicked"
"clipping"
"color"
"corner1"
"corner2"
"crop"
"default"
"delay"
"draggable"
"drop_shadow"
"drop_shadow_color"
"exclude"
"first_indent"
"first_spacing"
"fit_first"
"focus"
"font"
"foreground"
"ground"
"height"
"hover"
"hover_align"
"hover_alignaround"
"hover_alpha"
"hover_anchor"
"hover_angle"
"hover_antialias"
"hover_area"
"hover_around"
"hover_background"
"hover_bar_invert"
"hover_bar_resizing"
"hover_bar_vertical"
"hover_black_color"
"hover_bold"
"hover_bottom_bar"
"hover_bottom_gutter"
"hover_bottom_margin"
"hover_bottom_padding"
"hover_box_layout"
"hover_clipping"
"hover_color"
"hover_corner1"
"hover_corner2"
"hover_crop"
"hover_delay"
"hover_drop_shadow"
"hover_drop_shadow_color"
"hover_first_indent"
"hover_first_spacing"
"hover_fit_first"
"hover_font"
"hover_foreground"
"hover_italic"
"hover_justify"
"hover_language"
"hover_layout"
"hover_left_bar"
"hover_left_gutter"
"hover_left_margin"
"hover_left_padding"
"hover_line_spacing"
"hover_min_width"
"hover_minwidth"
"hover_mouse"
"hover_offset"
"hover_outlines"
"hover_pos"
"hover_radius"
"hover_rest_indent"
"hover_right_bar"
"hover_right_gutter"
"hover_right_margin"
"hover_right_padding"
"hover_rotate"
"hover_rotate_pad"
"hover_size"
"hover_size_group"
"hover_slow_abortable"
"hover_slow_cps"
"hover_slow_cps_multiplier"
"hover_sound"
"hover_spacing"
"hover_subpixel"
"hover_text_align"
"hover_text_y_fudge"
"hover_thumb"
"hover_thumb_offset"
"hover_thumb_shadow"
"hover_top_bar"
"hover_top_gutter"
"hover_top_margin"
"hover_top_padding"
"hover_underline"
"hover_unscrollable"
"hover_xalign"
"hover_xanchor"
"hover_xanchoraround"
"hover_xaround"
"hover_xfill"
"hover_xmargin"
"hover_xmaximum"
"hover_xminimum"
"hover_xoffset"
"hover_xpadding"
"hover_xpos"
"hover_xzoom"
"hover_yalign"
"hover_yanchor"
"hover_yanchoraround"
"hover_yaround"
"hover_yfill"
"hover_ymargin"
"hover_ymaximum"
"hover_yminimum"
"hover_yoffset"
"hover_ypadding"
"hover_ypos"
"hover_yzoom"
"hover_zoom"
"hovered"
"id"
"idle"
"idle_align"
"idle_alignaround"
"idle_alpha"
"idle_anchor"
"idle_angle"
"idle_antialias"
"idle_area"
"idle_around"
"idle_background"
"idle_bar_invert"
"idle_bar_resizing"
"idle_bar_vertical"
"idle_black_color"
"idle_bold"
"idle_bottom_bar"
"idle_bottom_gutter"
"idle_bottom_margin"
"idle_bottom_padding"
"idle_box_layout"
"idle_clipping"
"idle_color"
"idle_corner1"
"idle_corner2"
"idle_crop"
"idle_delay"
"idle_drop_shadow"
"idle_drop_shadow_color"
"idle_first_indent"
"idle_first_spacing"
"idle_fit_first"
"idle_font"
"idle_foreground"
"idle_italic"
"idle_justify"
"idle_language"
"idle_layout"
"idle_left_bar"
"idle_left_gutter"
"idle_left_margin"
"idle_left_padding"
"idle_line_spacing"
"idle_min_width"
"idle_minwidth"
"idle_mouse"
"idle_offset"
"idle_outlines"
"idle_pos"
"idle_radius"
"idle_rest_indent"
"idle_right_bar"
"idle_right_gutter"
"idle_right_margin"
"idle_right_padding"
"idle_rotate"
"idle_rotate_pad"
"idle_size"
"idle_size_group"
"idle_slow_abortable"
"idle_slow_cps"
"idle_slow_cps_multiplier"
"idle_sound"
"idle_spacing"
"idle_subpixel"
"idle_text_align"
"idle_text_y_fudge"
"idle_thumb"
"idle_thumb_offset"
"idle_thumb_shadow"
"idle_top_bar"
"idle_top_gutter"
"idle_top_margin"
"idle_top_padding"
"idle_underline"
"idle_unscrollable"
"idle_xalign"
"idle_xanchor"
"idle_xanchoraround"
"idle_xaround"
"idle_xfill"
"idle_xmargin"
"idle_xmaximum"
"idle_xminimum"
"idle_xoffset"
"idle_xpadding"
"idle_xpos"
"idle_xzoom"
"idle_yalign"
"idle_yanchor"
"idle_yanchoraround"
"idle_yaround"
"idle_yfill"
"idle_ymargin"
"idle_ymaximum"
"idle_yminimum"
"idle_yoffset"
"idle_ypadding"
"idle_ypos"
"idle_yzoom"
"idle_zoom"
"image_style"
"insensitive"
"insensitive_align"
"insensitive_alignaround"
"insensitive_alpha"
"insensitive_anchor"
"insensitive_angle"
"insensitive_antialias"
"insensitive_area"
"insensitive_around"
"insensitive_background"
"insensitive_bar_invert"
"insensitive_bar_resizing"
"insensitive_bar_vertical"
"insensitive_black_color"
"insensitive_bold"
"insensitive_bottom_bar"
"insensitive_bottom_gutter"
"insensitive_bottom_margin"
"insensitive_bottom_padding"
"insensitive_box_layout"
"insensitive_clipping"
"insensitive_color"
"insensitive_corner1"
"insensitive_corner2"
"insensitive_crop"
"insensitive_delay"
"insensitive_drop_shadow"
"insensitive_drop_shadow_color"
"insensitive_first_indent"
"insensitive_first_spacing"
"insensitive_fit_first"
"insensitive_font"
"insensitive_foreground"
"insensitive_italic"
"insensitive_justify"
"insensitive_language"
"insensitive_layout"
"insensitive_left_bar"
"insensitive_left_gutter"
"insensitive_left_margin"
"insensitive_left_padding"
"insensitive_line_spacing"
"insensitive_min_width"
"insensitive_minwidth"
"insensitive_mouse"
"insensitive_offset"
"insensitive_outlines"
"insensitive_pos"
"insensitive_radius"
"insensitive_rest_indent"
"insensitive_right_bar"
"insensitive_right_gutter"
"insensitive_right_margin"
"insensitive_right_padding"
"insensitive_rotate"
"insensitive_rotate_pad"
"insensitive_size"
"insensitive_size_group"
"insensitive_slow_abortable"
"insensitive_slow_cps"
"insensitive_slow_cps_multiplier"
"insensitive_sound"
"insensitive_spacing"
"insensitive_subpixel"
"insensitive_text_align"
"insensitive_text_y_fudge"
"insensitive_thumb"
"insensitive_thumb_offset"
"insensitive_thumb_shadow"
"insensitive_top_bar"
"insensitive_top_gutter"
"insensitive_top_margin"
"insensitive_top_padding"
"insensitive_underline"
"insensitive_unscrollable"
"insensitive_xalign"
"insensitive_xanchor"
"insensitive_xanchoraround"
"insensitive_xaround"
"insensitive_xfill"
"insensitive_xmargin"
"insensitive_xmaximum"
"insensitive_xminimum"
"insensitive_xoffset"
"insensitive_xpadding"
"insensitive_xpos"
"insensitive_xzoom"
"insensitive_yalign"
"insensitive_yanchor"
"insensitive_yanchoraround"
"insensitive_yaround"
"insensitive_yfill"
"insensitive_ymargin"
"insensitive_ymaximum"
"insensitive_yminimum"
"insensitive_yoffset"
"insensitive_ypadding"
"insensitive_ypos"
"insensitive_yzoom"
"insensitive_zoom"
"italic"
"justify"
"language"
"layout"
"left_bar"
"left_gutter"
"left_margin"
"left_padding"
"length"
"line_spacing"
"min_width"
"minwidth"
"mouse"
"mousewheel"
"offset"
"outlines"
"pos"
"prefix"
"radius"
"range"
"rest_indent"
"right_bar"
"right_gutter"
"right_margin"
"right_padding"
"rotate"
"rotate_pad"
"selected_activate_align"
"selected_activate_alignaround"
"selected_activate_alpha"
"selected_activate_anchor"
"selected_activate_angle"
"selected_activate_antialias"
"selected_activate_area"
"selected_activate_around"
"selected_activate_background"
"selected_activate_bar_invert"
"selected_activate_bar_resizing"
"selected_activate_bar_vertical"
"selected_activate_black_color"
"selected_activate_bold"
"selected_activate_bottom_bar"
"selected_activate_bottom_gutter"
"selected_activate_bottom_margin"
"selected_activate_bottom_padding"
"selected_activate_box_layout"
"selected_activate_clipping"
"selected_activate_color"
"selected_activate_corner1"
"selected_activate_corner2"
"selected_activate_crop"
"selected_activate_delay"
"selected_activate_drop_shadow"
"selected_activate_drop_shadow_color"
"selected_activate_first_indent"
"selected_activate_first_spacing"
"selected_activate_fit_first"
"selected_activate_font"
"selected_activate_foreground"
"selected_activate_italic"
"selected_activate_justify"
"selected_activate_language"
"selected_activate_layout"
"selected_activate_left_bar"
"selected_activate_left_gutter"
"selected_activate_left_margin"
"selected_activate_left_padding"
"selected_activate_line_spacing"
"selected_activate_min_width"
"selected_activate_minwidth"
"selected_activate_mouse"
"selected_activate_offset"
"selected_activate_outlines"
"selected_activate_pos"
"selected_activate_radius"
"selected_activate_rest_indent"
"selected_activate_right_bar"
"selected_activate_right_gutter"
"selected_activate_right_margin"
"selected_activate_right_padding"
"selected_activate_rotate"
"selected_activate_rotate_pad"
"selected_activate_size"
"selected_activate_size_group"
"selected_activate_slow_abortable"
"selected_activate_slow_cps"
"selected_activate_slow_cps_multiplier"
"selected_activate_sound"
"selected_activate_spacing"
"selected_activate_subpixel"
"selected_activate_text_align"
"selected_activate_text_y_fudge"
"selected_activate_thumb"
"selected_activate_thumb_offset"
"selected_activate_thumb_shadow"
"selected_activate_top_bar"
"selected_activate_top_gutter"
"selected_activate_top_margin"
"selected_activate_top_padding"
"selected_activate_underline"
"selected_activate_unscrollable"
"selected_activate_xalign"
"selected_activate_xanchor"
"selected_activate_xanchoraround"
"selected_activate_xaround"
"selected_activate_xfill"
"selected_activate_xmargin"
"selected_activate_xmaximum"
"selected_activate_xminimum"
"selected_activate_xoffset"
"selected_activate_xpadding"
"selected_activate_xpos"
"selected_activate_xzoom"
"selected_activate_yalign"
"selected_activate_yanchor"
"selected_activate_yanchoraround"
"selected_activate_yaround"
"selected_activate_yfill"
"selected_activate_ymargin"
"selected_activate_ymaximum"
"selected_activate_yminimum"
"selected_activate_yoffset"
"selected_activate_ypadding"
"selected_activate_ypos"
"selected_activate_yzoom"
"selected_activate_zoom"
"selected_align"
"selected_alignaround"
"selected_alpha"
"selected_anchor"
"selected_angle"
"selected_antialias"
"selected_area"
"selected_around"
"selected_background"
"selected_bar_invert"
"selected_bar_resizing"
"selected_bar_vertical"
"selected_black_color"
"selected_bold"
"selected_bottom_bar"
"selected_bottom_gutter"
"selected_bottom_margin"
"selected_bottom_padding"
"selected_box_layout"
"selected_clipping"
"selected_color"
"selected_corner1"
"selected_corner2"
"selected_crop"
"selected_delay"
"selected_drop_shadow"
"selected_drop_shadow_color"
"selected_first_indent"
"selected_first_spacing"
"selected_fit_first"
"selected_font"
"selected_foreground"
"selected_hover"
"selected_hover_align"
"selected_hover_alignaround"
"selected_hover_alpha"
"selected_hover_anchor"
"selected_hover_angle"
"selected_hover_antialias"
"selected_hover_area"
"selected_hover_around"
"selected_hover_background"
"selected_hover_bar_invert"
"selected_hover_bar_resizing"
"selected_hover_bar_vertical"
"selected_hover_black_color"
"selected_hover_bold"
"selected_hover_bottom_bar"
"selected_hover_bottom_gutter"
"selected_hover_bottom_margin"
"selected_hover_bottom_padding"
"selected_hover_box_layout"
"selected_hover_clipping"
"selected_hover_color"
"selected_hover_corner1"
"selected_hover_corner2"
"selected_hover_crop"
"selected_hover_delay"
"selected_hover_drop_shadow"
"selected_hover_drop_shadow_color"
"selected_hover_first_indent"
"selected_hover_first_spacing"
"selected_hover_fit_first"
"selected_hover_font"
"selected_hover_foreground"
"selected_hover_italic"
"selected_hover_justify"
"selected_hover_language"
"selected_hover_layout"
"selected_hover_left_bar"
"selected_hover_left_gutter"
"selected_hover_left_margin"
"selected_hover_left_padding"
"selected_hover_line_spacing"
"selected_hover_min_width"
"selected_hover_minwidth"
"selected_hover_mouse"
"selected_hover_offset"
"selected_hover_outlines"
"selected_hover_pos"
"selected_hover_radius"
"selected_hover_rest_indent"
"selected_hover_right_bar"
"selected_hover_right_gutter"
"selected_hover_right_margin"
"selected_hover_right_padding"
"selected_hover_rotate"
"selected_hover_rotate_pad"
"selected_hover_size"
"selected_hover_size_group"
"selected_hover_slow_abortable"
"selected_hover_slow_cps"
"selected_hover_slow_cps_multiplier"
"selected_hover_sound"
"selected_hover_spacing"
"selected_hover_subpixel"
"selected_hover_text_align"
"selected_hover_text_y_fudge"
"selected_hover_thumb"
"selected_hover_thumb_offset"
"selected_hover_thumb_shadow"
"selected_hover_top_bar"
"selected_hover_top_gutter"
"selected_hover_top_margin"
"selected_hover_top_padding"
"selected_hover_underline"
"selected_hover_unscrollable"
"selected_hover_xalign"
"selected_hover_xanchor"
"selected_hover_xanchoraround"
"selected_hover_xaround"
"selected_hover_xfill"
"selected_hover_xmargin"
"selected_hover_xmaximum"
"selected_hover_xminimum"
"selected_hover_xoffset"
"selected_hover_xpadding"
"selected_hover_xpos"
"selected_hover_xzoom"
"selected_hover_yalign"
"selected_hover_yanchor"
"selected_hover_yanchoraround"
"selected_hover_yaround"
"selected_hover_yfill"
"selected_hover_ymargin"
"selected_hover_ymaximum"
"selected_hover_yminimum"
"selected_hover_yoffset"
"selected_hover_ypadding"
"selected_hover_ypos"
"selected_hover_yzoom"
"selected_hover_zoom"
"selected_idle"
"selected_idle_align"
"selected_idle_alignaround"
"selected_idle_alpha"
"selected_idle_anchor"
"selected_idle_angle"
"selected_idle_antialias"
"selected_idle_area"
"selected_idle_around"
"selected_idle_background"
"selected_idle_bar_invert"
"selected_idle_bar_resizing"
"selected_idle_bar_vertical"
"selected_idle_black_color"
"selected_idle_bold"
"selected_idle_bottom_bar"
"selected_idle_bottom_gutter"
"selected_idle_bottom_margin"
"selected_idle_bottom_padding"
"selected_idle_box_layout"
"selected_idle_clipping"
"selected_idle_color"
"selected_idle_corner1"
"selected_idle_corner2"
"selected_idle_crop"
"selected_idle_delay"
"selected_idle_drop_shadow"
"selected_idle_drop_shadow_color"
"selected_idle_first_indent"
"selected_idle_first_spacing"
"selected_idle_fit_first"
"selected_idle_font"
"selected_idle_foreground"
"selected_idle_italic"
"selected_idle_justify"
"selected_idle_language"
"selected_idle_layout"
"selected_idle_left_bar"
"selected_idle_left_gutter"
"selected_idle_left_margin"
"selected_idle_left_padding"
"selected_idle_line_spacing"
"selected_idle_min_width"
"selected_idle_minwidth"
"selected_idle_mouse"
"selected_idle_offset"
"selected_idle_outlines"
"selected_idle_pos"
"selected_idle_radius"
"selected_idle_rest_indent"
"selected_idle_right_bar"
"selected_idle_right_gutter"
"selected_idle_right_margin"
"selected_idle_right_padding"
"selected_idle_rotate"
"selected_idle_rotate_pad"
"selected_idle_size"
"selected_idle_size_group"
"selected_idle_slow_abortable"
"selected_idle_slow_cps"
"selected_idle_slow_cps_multiplier"
"selected_idle_sound"
"selected_idle_spacing"
"selected_idle_subpixel"
"selected_idle_text_align"
"selected_idle_text_y_fudge"
"selected_idle_thumb"
"selected_idle_thumb_offset"
"selected_idle_thumb_shadow"
"selected_idle_top_bar"
"selected_idle_top_gutter"
"selected_idle_top_margin"
"selected_idle_top_padding"
"selected_idle_underline"
"selected_idle_unscrollable"
"selected_idle_xalign"
"selected_idle_xanchor"
"selected_idle_xanchoraround"
"selected_idle_xaround"
"selected_idle_xfill"
"selected_idle_xmargin"
"selected_idle_xmaximum"
"selected_idle_xminimum"
"selected_idle_xoffset"
"selected_idle_xpadding"
"selected_idle_xpos"
"selected_idle_xzoom"
"selected_idle_yalign"
"selected_idle_yanchor"
"selected_idle_yanchoraround"
"selected_idle_yaround"
"selected_idle_yfill"
"selected_idle_ymargin"
"selected_idle_ymaximum"
"selected_idle_yminimum"
"selected_idle_yoffset"
"selected_idle_ypadding"
"selected_idle_ypos"
"selected_idle_yzoom"
"selected_idle_zoom"
"selected_insensitive_align"
"selected_insensitive_alignaround"
"selected_insensitive_alpha"
"selected_insensitive_anchor"
"selected_insensitive_angle"
"selected_insensitive_antialias"
"selected_insensitive_area"
"selected_insensitive_around"
"selected_insensitive_background"
"selected_insensitive_bar_invert"
"selected_insensitive_bar_resizing"
"selected_insensitive_bar_vertical"
"selected_insensitive_black_color"
"selected_insensitive_bold"
"selected_insensitive_bottom_bar"
"selected_insensitive_bottom_gutter"
"selected_insensitive_bottom_margin"
"selected_insensitive_bottom_padding"
"selected_insensitive_box_layout"
"selected_insensitive_clipping"
"selected_insensitive_color"
"selected_insensitive_corner1"
"selected_insensitive_corner2"
"selected_insensitive_crop"
"selected_insensitive_delay"
"selected_insensitive_drop_shadow"
"selected_insensitive_drop_shadow_color"
"selected_insensitive_first_indent"
"selected_insensitive_first_spacing"
"selected_insensitive_fit_first"
"selected_insensitive_font"
"selected_insensitive_foreground"
"selected_insensitive_italic"
"selected_insensitive_justify"
"selected_insensitive_language"
"selected_insensitive_layout"
"selected_insensitive_left_bar"
"selected_insensitive_left_gutter"
"selected_insensitive_left_margin"
"selected_insensitive_left_padding"
"selected_insensitive_line_spacing"
"selected_insensitive_min_width"
"selected_insensitive_minwidth"
"selected_insensitive_mouse"
"selected_insensitive_offset"
"selected_insensitive_outlines"
"selected_insensitive_pos"
"selected_insensitive_radius"
"selected_insensitive_rest_indent"
"selected_insensitive_right_bar"
"selected_insensitive_right_gutter"
"selected_insensitive_right_margin"
"selected_insensitive_right_padding"
"selected_insensitive_rotate"
"selected_insensitive_rotate_pad"
"selected_insensitive_size"
"selected_insensitive_size_group"
"selected_insensitive_slow_abortable"
"selected_insensitive_slow_cps"
"selected_insensitive_slow_cps_multiplier"
"selected_insensitive_sound"
"selected_insensitive_spacing"
"selected_insensitive_subpixel"
"selected_insensitive_text_align"
"selected_insensitive_text_y_fudge"
"selected_insensitive_thumb"
"selected_insensitive_thumb_offset"
"selected_insensitive_thumb_shadow"
"selected_insensitive_top_bar"
"selected_insensitive_top_gutter"
"selected_insensitive_top_margin"
"selected_insensitive_top_padding"
"selected_insensitive_underline"
"selected_insensitive_unscrollable"
"selected_insensitive_xalign"
"selected_insensitive_xanchor"
"selected_insensitive_xanchoraround"
"selected_insensitive_xaround"
"selected_insensitive_xfill"
"selected_insensitive_xmargin"
"selected_insensitive_xmaximum"
"selected_insensitive_xminimum"
"selected_insensitive_xoffset"
"selected_insensitive_xpadding"
"selected_insensitive_xpos"
"selected_insensitive_xzoom"
"selected_insensitive_yalign"
"selected_insensitive_yanchor"
"selected_insensitive_yanchoraround"
"selected_insensitive_yaround"
"selected_insensitive_yfill"
"selected_insensitive_ymargin"
"selected_insensitive_ymaximum"
"selected_insensitive_yminimum"
"selected_insensitive_yoffset"
"selected_insensitive_ypadding"
"selected_insensitive_ypos"
"selected_insensitive_yzoom"
"selected_insensitive_zoom"
"selected_italic"
"selected_justify"
"selected_language"
"selected_layout"
"selected_left_bar"
"selected_left_gutter"
"selected_left_margin"
"selected_left_padding"
"selected_line_spacing"
"selected_min_width"
"selected_minwidth"
"selected_mouse"
"selected_offset"
"selected_outlines"
"selected_pos"
"selected_radius"
"selected_rest_indent"
"selected_right_bar"
"selected_right_gutter"
"selected_right_margin"
"selected_right_padding"
"selected_rotate"
"selected_rotate_pad"
"selected_size"
"selected_size_group"
"selected_slow_abortable"
"selected_slow_cps"
"selected_slow_cps_multiplier"
"selected_sound"
"selected_spacing"
"selected_subpixel"
"selected_text_align"
"selected_text_y_fudge"
"selected_thumb"
"selected_thumb_offset"
"selected_thumb_shadow"
"selected_top_bar"
"selected_top_gutter"
"selected_top_margin"
"selected_top_padding"
"selected_underline"
"selected_unscrollable"
"selected_xalign"
"selected_xanchor"
"selected_xanchoraround"
"selected_xaround"
"selected_xfill"
"selected_xmargin"
"selected_xmaximum"
"selected_xminimum"
"selected_xoffset"
"selected_xpadding"
"selected_xpos"
"selected_xzoom"
"selected_yalign"
"selected_yanchor"
"selected_yanchoraround"
"selected_yaround"
"selected_yfill"
"selected_ymargin"
"selected_ymaximum"
"selected_yminimum"
"selected_yoffset"
"selected_ypadding"
"selected_ypos"
"selected_yzoom"
"selected_zoom"
"size"
"size_group"
"slow"
"slow_abortable"
"slow_cps"
"slow_cps_multiplier"
"sound"
"spacing"
"style"
"style_group"
"subpixel"
"suffix"
"text_align"
"text_style"
"text_y_fudge"
"thumb"
"thumb_offset"
"thumb_shadow"
"top_bar"
"top_gutter"
"top_margin"
"top_padding"
"transpose"
"underline"
"unhovered"
"unscrollable"
"value"
"width"
"xadjustment"
"xalign"
"xanchor"
"xanchoraround"
"xaround"
"xfill"
"xmargin"
"xmaximum"
"xminimum"
"xoffset"
"xpadding"
"xpos"
"xzoom"
"yadjustment"
"yalign"
"yanchor"
"yanchoraround"
"yaround"
"yfill"
"ymargin"
"ymaximum"
"yminimum"
"yoffset"
"ypadding"
"ypos"
"yzoom"
"zoom"
          )) symbol-end)
     (1 font-lock-builtin-face))
    (,(rx symbol-start (or
	  ;; other built-ins
	  "True" "False" "None" "Ellipsis"
	  "_" "__debug__" "__doc__" "__import__" "__name__") symbol-end)
     . font-lock-builtin-face)))

(defconst renpy-font-lock-syntactic-keywords
  ;; Make outer chars of matching triple-quote sequences into generic
  ;; string delimiters.  Fixme: Is there a better way?
  ;; First avoid a sequence preceded by an odd number of backslashes.
  `((,(rx (not (any ?\\))
	  ?\\ (* (and ?\\ ?\\))
	  (group (syntax string-quote))
	  (backref 1)
	  (group (backref 1)))
     (2 ,(string-to-syntax "\"")))	; dummy
    (,(rx (group (optional (any "uUrR"))) ; prefix gets syntax property
	  (optional (any "rR"))		  ; possible second prefix
	  (group (syntax string-quote))   ; maybe gets property
	  (backref 2)			  ; per first quote
	  (group (backref 2)))		  ; maybe gets property
     (1 (renpy-quote-syntax 1))
     (2 (renpy-quote-syntax 2))
     (3 (renpy-quote-syntax 3)))
    ;; This doesn't really help.
;;;     (,(rx (and ?\\ (group ?\n))) (1 " "))
    ))

(defun renpy-quote-syntax (n)
  "Put `syntax-table' property correctly on triple quote.
Used for syntactic keywords.  N is the match number (1, 2 or 3)."
  ;; Given a triple quote, we have to check the context to know
  ;; whether this is an opening or closing triple or whether it's
  ;; quoted anyhow, and should be ignored.  (For that we need to do
  ;; the same job as `syntax-ppss' to be correct and it seems to be OK
  ;; to use it here despite initial worries.)  We also have to sort
  ;; out a possible prefix -- well, we don't _have_ to, but I think it
  ;; should be treated as part of the string.

  ;; Test cases:
  ;;  ur"""ar""" x='"' # """
  ;; x = ''' """ ' a
  ;; '''
  ;; x '"""' x """ \"""" x
  (save-excursion
    (goto-char (match-beginning 0))
    (cond
     ;; Consider property for the last char if in a fenced string.
     ((= n 3)
      (let* ((font-lock-syntactic-keywords nil)
	     (syntax (syntax-ppss)))
	(when (eq t (nth 3 syntax))	; after unclosed fence
	  (goto-char (nth 8 syntax))	; fence position
	  (skip-chars-forward "uUrR")	; skip any prefix
	  ;; Is it a matching sequence?
	  (if (eq (char-after) (char-after (match-beginning 2)))
	      (eval-when-compile (string-to-syntax "|"))))))
     ;; Consider property for initial char, accounting for prefixes.
     ((or (and (= n 2)			; leading quote (not prefix)
	       (= (match-beginning 1) (match-end 1))) ; prefix is null
	  (and (= n 1)			; prefix
	       (/= (match-beginning 1) (match-end 1)))) ; non-empty
      (let ((font-lock-syntactic-keywords nil))
	(unless (eq 'string (syntax-ppss-context (syntax-ppss)))
	  (eval-when-compile (string-to-syntax "|")))))
     ;; Otherwise (we're in a non-matching string) the property is
     ;; nil, which is OK.
     )))

;; This isn't currently in `font-lock-defaults' as probably not worth
;; it -- we basically only mess with a few normally-symbol characters.

;; (defun renpy-font-lock-syntactic-face-function (state)
;;   "`font-lock-syntactic-face-function' for Renpy mode.
;; Returns the string or comment face as usual, with side effect of putting
;; a `syntax-table' property on the inside of the string or comment which is
;; the standard syntax table."
;;   (if (nth 3 state)
;;       (save-excursion
;; 	(goto-char (nth 8 state))
;; 	(condition-case nil
;; 	    (forward-sexp)
;; 	  (error nil))
;; 	(put-text-property (1+ (nth 8 state)) (1- (point))
;; 			   'syntax-table (standard-syntax-table))
;; 	'font-lock-string-face)
;;     (put-text-property (1+ (nth 8 state)) (line-end-position)
;; 			   'syntax-table (standard-syntax-table))
;;     'font-lock-comment-face))

;;;; Keymap and syntax

(defvar renpy-mode-map
  (let ((map (make-sparse-keymap)))
    ;; Mostly taken from renpy-mode.el.
    (define-key map ":" 'renpy-electric-colon)
    (define-key map "\177" 'renpy-backspace)
    (define-key map "\C-c<" 'renpy-shift-left)
    (define-key map "\C-c>" 'renpy-shift-right)
    (define-key map "\C-c\C-k" 'renpy-mark-block)
    (define-key map "\C-c\C-n" 'renpy-next-statement)
    (define-key map "\C-c\C-p" 'renpy-previous-statement)
    (define-key map "\C-c\C-u" 'renpy-beginning-of-block)
    (define-key map "\C-c\C-f" 'renpy-describe-symbol)
    (define-key map "\C-c\C-w" 'renpy-check)
    (define-key map "\C-c\C-v" 'renpy-check) ; a la sgml-mode
    (substitute-key-definition 'complete-symbol 'symbol-complete
			       map global-map)
    (easy-menu-define renpy-menu map "Ren'Py Mode menu"
      `("Ren'Py"
	:help "Ren'Py-specific Features"
	["Shift region left" renpy-shift-left :active mark-active
	 :help "Shift by a single indentation step"]
	["Shift region right" renpy-shift-right :active mark-active
	 :help "Shift by a single indentation step"]
	"-"
	["Mark block" renpy-mark-block
	 :help "Mark innermost block around point"]
	["Start of block" renpy-beginning-of-block
	 :help "Go to start of innermost definition around point"]
	["End of block" renpy-end-of-block
	 :help "Go to end of innermost definition around point"]
        ))
    map))

;; Fixme: add toolbar stuff for useful things like symbol help, send
;; region, at least.  (Shouldn't be specific to Renpy, obviously.)
;; eric has items including: (un)indent, (un)comment, restart script,
;; run script, debug script; also things for profiling, unit testing.

(defvar renpy-mode-syntax-table
  (let ((table (make-syntax-table)))
    ;; Give punctuation syntax to ASCII that normally has symbol
    ;; syntax or has word syntax and isn't a letter.
    (let ((symbol (string-to-syntax "_"))
	  (sst (standard-syntax-table)))
      (dotimes (i 128)
	(unless (= i ?_)
	  (if (equal symbol (aref sst i))
	      (modify-syntax-entry i "." table)))))
    (modify-syntax-entry ?$ "." table)
    (modify-syntax-entry ?% "." table)
    ;; exceptions
    (modify-syntax-entry ?# "<" table)
    (modify-syntax-entry ?\n ">" table)
    (modify-syntax-entry ?' "\"" table)
    (modify-syntax-entry ?` "$" table)
    table))

;;;; Utility stuff

(defsubst renpy-in-string-comment ()
  "Return non-nil if point is in a Renpy literal (a comment or string)."
  ;; We don't need to save the match data.
  (nth 8 (syntax-ppss)))

(defconst renpy-space-backslash-table
  (let ((table (copy-syntax-table renpy-mode-syntax-table)))
    (modify-syntax-entry ?\\ " " table)
    table)
  "`renpy-mode-syntax-table' with backslash given whitespace syntax.")

(defun renpy-skip-comments-blanks (&optional backward)
  "Skip comments and blank lines.
BACKWARD non-nil means go backwards, otherwise go forwards.
Backslash is treated as whitespace so that continued blank lines
are skipped.  Doesn't move out of comments -- should be outside
or at end of line."
  (let ((arg (if backward
		 ;; If we're in a comment (including on the trailing
		 ;; newline), forward-comment doesn't move backwards out
		 ;; of it.  Don't set the syntax table round this bit!
		 (let ((syntax (syntax-ppss)))
		   (if (nth 4 syntax)
		       (goto-char (nth 8 syntax)))
		   (- (point-max)))
	       (point-max))))
    (with-syntax-table renpy-space-backslash-table
      (forward-comment arg))))

(defun renpy-backslash-continuation-line-p ()
  "Non-nil if preceding line ends with backslash that is not in a comment."
  (and (eq ?\\ (char-before (line-end-position 0)))
       (not (syntax-ppss-context (syntax-ppss)))))

(defun renpy-continuation-line-p ()
  "Return non-nil if current line continues a previous one.
The criteria are that the previous line ends in a backslash outside
comments and strings, or that point is within brackets/parens."
  (or (renpy-backslash-continuation-line-p)
      (let ((depth (syntax-ppss-depth
		    (save-excursion ; syntax-ppss with arg changes point
		      (syntax-ppss (line-beginning-position))))))
	(or (> depth 0)
	    (if (< depth 0)	  ; Unbalanced brackets -- act locally
		(save-excursion
		  (condition-case ()
		      (progn (backward-up-list) t) ; actually within brackets
		    (error nil))))))))

(defun renpy-comment-line-p ()
  "Return non-nil if and only if current line has only a comment."
  (save-excursion
    (end-of-line)
    (when (eq 'comment (syntax-ppss-context (syntax-ppss)))
      (back-to-indentation)
      (looking-at (rx (or (syntax comment-start) line-end))))))

(defun renpy-blank-line-p ()
  "Return non-nil if and only if current line is blank."
  (save-excursion
    (beginning-of-line)
    (looking-at "\\s-*$")))

(defun renpy-beginning-of-string ()
  "Go to beginning of string around point.
Do nothing if not in string."
  (let ((state (syntax-ppss)))
    (when (eq 'string (syntax-ppss-context state))
      (goto-char (nth 8 state)))))

(defun renpy-open-block-statement-p (&optional bos)
  "Return non-nil if statement at point opens a block.
BOS non-nil means point is known to be at beginning of statement."
  (save-excursion
    (unless bos (renpy-beginning-of-statement))

    ; A statement opens a block if it ends with :.
    (renpy-end-of-statement)
    (equal (char-before) 58)))

    ;; (looking-at (rx (and (or "if" "else" "elif" "while" "for" "def"
    ;;     		     "class" "try" "except" "finally" "with")
    ;;     		 symbol-end)))))

(defun renpy-close-block-statement-p (&optional bos)
  "Return non-nil if current line is a statement closing a block.
BOS non-nil means point is at beginning of statement.
The criteria are that the line isn't a comment or in string and
 starts with keyword `raise', `break', `continue' or `pass'."
  (save-excursion
    (unless bos (renpy-beginning-of-statement))
    (back-to-indentation)
    (looking-at (rx (or "return" "raise" "break" "continue" "pass")
		    symbol-end))))

(defun renpy-outdent-p ()
  "Return non-nil if current line should outdent a level."
  (save-excursion
    (back-to-indentation)
    (and (looking-at (rx (and (or "else" "finally" "except" "elif")
			      symbol-end)))
	 (not (renpy-in-string-comment))
	 ;; Ensure there's a previous statement and move to it.
	 (zerop (renpy-previous-statement))
	 (not (renpy-close-block-statement-p t))
	 ;; Fixme: check this
	 (not (renpy-open-block-statement-p)))))

;;;; Indentation.

(defcustom renpy-indent 4
  "Number of columns for a unit of indentation in Renpy mode.
See also `\\[renpy-guess-indent]'"
  :group 'renpy
  :type 'integer)
(put 'renpy-indent 'safe-local-variable 'integerp)

(defcustom renpy-guess-indent nil
  "Non-nil means Renpy mode guesses `renpy-indent' for the buffer."
  :type 'boolean
  :group 'renpy)

(defcustom renpy-indent-string-contents t
  "Non-nil means indent contents of multi-line strings together.
This means indent them the same as the preceding non-blank line.
Otherwise preserve their indentation.

This only applies to `doc' strings, i.e. those that form statements;
the indentation is preserved in others."
  :type '(choice (const :tag "Align with preceding" t)
		 (const :tag "Preserve indentation" nil))
  :group 'renpy)

(defcustom renpy-honour-comment-indentation nil
  "Non-nil means indent relative to preceding comment line.
Only do this for comments where the leading comment character is
followed by space.  This doesn't apply to comment lines, which
are always indented in lines with preceding comments."
  :type 'boolean
  :group 'renpy)

(defcustom renpy-continuation-offset 4
  "Number of columns of additional indentation for continuation lines.
Continuation lines follow a backslash-terminated line starting a
statement."
  :group 'renpy
  :type 'integer)



(defun renpy-guess-indent ()
  "Guess step for indentation of current buffer.
Set `renpy-indent' locally to the value guessed."
  (interactive)
  (save-excursion
    (save-restriction
      (widen)
      (goto-char (point-min))
      (let (done indent)
	(while (and (not done) (not (eobp)))
	  (when (and (re-search-forward (rx ?: (0+ space)
					    (or (syntax comment-start)
						line-end))
					nil 'move)
		     (renpy-open-block-statement-p))
	    (save-excursion
	      (renpy-beginning-of-statement)
	      (let ((initial (current-indentation)))
		(if (zerop (renpy-next-statement))
		    (setq indent (- (current-indentation) initial)))
		(if (and indent (>= indent 2) (<= indent 8)) ; sanity check
		    (setq done t))))))
	(when done
	  (when (/= indent (default-value 'renpy-indent))
	    (set (make-local-variable 'renpy-indent) indent)
	    (unless (= tab-width renpy-indent)
	      (setq indent-tabs-mode nil)))
	  indent)))))

;; Alist of possible indentations and start of statement they would
;; close.  Used in indentation cycling (below).
(defvar renpy-indent-list nil
  "Internal use.")
;; Length of the above
(defvar renpy-indent-list-length nil
  "Internal use.")
;; Current index into the alist.
(defvar renpy-indent-index nil
  "Internal use.")

(defun renpy-calculate-indentation ()
  "Calculate Renpy indentation for line at point."
  (setq renpy-indent-list nil
	renpy-indent-list-length 1)
  (save-excursion
    (beginning-of-line)
    (let ((syntax (syntax-ppss))
	  start)
      (cond
       ((eq 'string (syntax-ppss-context syntax)) ; multi-line string
	(if (not renpy-indent-string-contents)
	    (current-indentation)
	  ;; Only respect `renpy-indent-string-contents' in doc
	  ;; strings (defined as those which form statements).
	  (if (not (save-excursion
		     (renpy-beginning-of-statement)
		     (looking-at (rx (or (syntax string-delimiter)
					 (syntax string-quote))))))
	      (current-indentation)
	    ;; Find indentation of preceding non-blank line within string.
	    (setq start (nth 8 syntax))
	    (forward-line -1)
	    (while (and (< start (point)) (looking-at "\\s-*$"))
	      (forward-line -1))
	    (current-indentation))))
       ((renpy-continuation-line-p)   ; after backslash, or bracketed
	(let ((point (point))
	      (open-start (cadr syntax))
	      (backslash (renpy-backslash-continuation-line-p))
	      (colon (eq ?: (char-before (1- (line-beginning-position))))))
	  (if open-start
	      ;; Inside bracketed expression.
	      (progn
		(goto-char (1+ open-start))
		;; Look for first item in list (preceding point) and
		;; align with it, if found.
		(if (with-syntax-table renpy-space-backslash-table
		      (let ((parse-sexp-ignore-comments t))
			(condition-case ()
			    (progn (forward-sexp)
				   (backward-sexp)
				   (< (point) point))
			  (error nil))))
		    ;; Extra level if we're backslash-continued or
		    ;; following a key.
		    (if (or backslash colon)
			(+ renpy-indent (current-column))
			(current-column))
		  ;; Otherwise indent relative to statement start, one
		  ;; level per bracketing level.
		  (goto-char (1+ open-start))
		  (renpy-beginning-of-statement)
		  (+ (current-indentation) (* (car syntax) renpy-indent))))
	    ;; Otherwise backslash-continued.
	    (forward-line -1)
	    (if (renpy-continuation-line-p)
		;; We're past first continuation line.  Align with
		;; previous line.
		(current-indentation)
	      ;; First continuation line.  Indent one step, with an
	      ;; extra one if statement opens a block.
	      (renpy-beginning-of-statement)
	      (+ (current-indentation) renpy-continuation-offset
		 (if (renpy-open-block-statement-p t)
		     renpy-indent
		   0))))))
       ((bobp) 0)
       ;; Fixme: Like renpy-mode.el; not convinced by this.
       ((looking-at (rx (0+ space) (syntax comment-start)
			(not (any " \t\n")))) ; non-indentable comment
	(current-indentation))
       ((and renpy-honour-comment-indentation
	     ;; Back over whitespace, newlines, non-indentable comments.
	     (catch 'done
	       (while (cond ((bobp) nil)
			    ((not (forward-comment -1))
			     nil)	; not at comment start
			    ;; Now at start of comment -- trailing one?
			    ((/= (current-column) (current-indentation))
			     nil)
			    ;; Indentable comment, like renpy-mode.el?
			    ((and (looking-at (rx (syntax comment-start)
						  (or space line-end)))
				  (/= 0 (current-column)))
			     (throw 'done (current-column)))
			    ;; Else skip it (loop).
			    (t))))))
       (t
	(renpy-indentation-levels)
	;; Prefer to indent comments with an immediately-following
	;; statement, e.g.
	;;       ...
	;;   # ...
	;;   def ...
	(when (and (> renpy-indent-list-length 1)
		   (renpy-comment-line-p))
	  (forward-line)
	  (unless (renpy-comment-line-p)
	    (let ((elt (assq (current-indentation) renpy-indent-list)))
	      (setq renpy-indent-list
		    (nconc (delete elt renpy-indent-list)
			   (list elt))))))
	(caar (last renpy-indent-list)))))))

;;;; Cycling through the possible indentations with successive TABs.

;; These don't need to be buffer-local since they're only relevant
;; during a cycle.

(defun renpy-initial-text ()
  "Text of line following indentation and ignoring any trailing comment."
  (save-excursion
    (buffer-substring (progn
			(back-to-indentation)
			(point))
		      (progn
			(end-of-line)
			(forward-comment -1)
			(point)))))

(defconst renpy-block-pairs
  '(("else" "if" "elif" "while" "for" "try" "except")
    ("elif" "if" "elif")
    ("except" "try" "except")
    ("finally" "try" "except"))
  "Alist of keyword matches.
The car of an element is a keyword introducing a statement which
can close a block opened by a keyword in the cdr.")

(defun renpy-first-word ()
  "Return first word (actually symbol) on the line."
  (save-excursion
    (back-to-indentation)
    (current-word t)))

(defun renpy-indentation-levels ()
  "Return a list of possible indentations for this line.
It is assumed not to be a continuation line or in a multi-line string.
Includes the default indentation and those which would close all
enclosing blocks.  Elements of the list are actually pairs:
\(INDENTATION . TEXT), where TEXT is the initial text of the
corresponding block opening (or nil)."
  (save-excursion
    (let ((initial "")
	  levels indent)
      ;; Only one possibility immediately following a block open
      ;; statement, assuming it doesn't have a `suite' on the same line.
      (cond
       ((save-excursion (and (renpy-previous-statement)
			     (renpy-open-block-statement-p t)
			     (setq indent (current-indentation))
			     ;; Check we don't have something like:
			     ;;   if ...: ...
			     (if (progn (renpy-end-of-statement)
					(renpy-skip-comments-blanks t)
					(eq ?: (char-before)))
				 (setq indent (+ renpy-indent indent)))))
	(push (cons indent initial) levels))
       ;; Only one possibility for comment line immediately following
       ;; another.
       ((save-excursion
	  (when (renpy-comment-line-p)
	    (forward-line -1)
	    (if (renpy-comment-line-p)
		(push (cons (current-indentation) initial) levels)))))
       ;; Fixme: Maybe have a case here which indents (only) first
       ;; line after a lambda.
       (t
	(let ((start (car (assoc (renpy-first-word) renpy-block-pairs))))
	  (renpy-previous-statement)
	  ;; Is this a valid indentation for the line of interest?
	  (unless (or (if start		; potentially only outdentable
			  ;; Check for things like:
			  ;;   if ...: ...
			  ;;   else ...:
			  ;; where the second line need not be outdented.
			  (not (member (renpy-first-word)
				       (cdr (assoc start
						   renpy-block-pairs)))))
		      ;; Not sensible to indent to the same level as
		      ;; previous `return' &c.
		      (renpy-close-block-statement-p))
	    (push (cons (current-indentation) (renpy-initial-text))
		  levels))
	  (while (renpy-beginning-of-block)
	    (when (or (not start)
		      (member (renpy-first-word)
			      (cdr (assoc start renpy-block-pairs))))
	      (push (cons (current-indentation) (renpy-initial-text))
		    levels))))))
      (prog1 (or levels (setq levels '((0 . ""))))
	(setq renpy-indent-list levels
	      renpy-indent-list-length (length renpy-indent-list))))))

;; This is basically what `renpy-indent-line' would be if we didn't
;; do the cycling.
(defun renpy-indent-line-1 (&optional leave)
  "Subroutine of `renpy-indent-line'.
Does non-repeated indentation.  LEAVE non-nil means leave
indentation if it is valid, i.e. one of the positions returned by
`renpy-calculate-indentation'."
  (let ((target (renpy-calculate-indentation))
	(pos (- (point-max) (point))))
    (if (or (= target (current-indentation))
	    ;; Maybe keep a valid indentation.
	    (and leave renpy-indent-list
		 (assq (current-indentation) renpy-indent-list)))
	(if (< (current-column) (current-indentation))
	    (back-to-indentation))
      (beginning-of-line)
      (delete-horizontal-space)
      (indent-to target)
      (if (> (- (point-max) pos) (point))
	  (goto-char (- (point-max) pos))))))

(defun renpy-indent-line-2 ()
  "Indent current line as Renpy code.
When invoked via `indent-for-tab-command', cycle through possible
indentations for current line.  The cycle is broken by a command
different from `indent-for-tab-command', i.e. successive TABs do
the cycling."
  (interactive)
  (if (and (eq this-command 'indent-for-tab-command)
	   (eq last-command this-command))
      (if (= 1 renpy-indent-list-length)
	  (message "Sole indentation")
	(progn (setq renpy-indent-index
		     (% (1+ renpy-indent-index) renpy-indent-list-length))
	       (beginning-of-line)
	       (delete-horizontal-space)
	       (indent-to (car (nth renpy-indent-index renpy-indent-list)))
	       (if (renpy-block-end-p)
		   (let ((text (cdr (nth renpy-indent-index
					 renpy-indent-list))))
		     (if text
			 (message "Closes: %s" text))))))
    (renpy-indent-line-1)
    (setq renpy-indent-index (1- renpy-indent-list-length))))

(defun renpy-indent-region (start end)
  "`indent-region-function' for Renpy.
Leaves validly-indented lines alone, i.e. doesn't indent to
another valid position."
  (save-excursion
    (goto-char end)
    (setq end (point-marker))
    (goto-char start)
    (or (bolp) (forward-line 1))
    (while (< (point) end)
      (or (and (bolp) (eolp))
	  (renpy-indent-line-1 t))
      (forward-line 1))
    (move-marker end nil)))

(defun renpy-block-end-p ()
  "Non-nil if this is a line in a statement closing a block,
or a blank line indented to where it would close a block."
  (and (not (renpy-comment-line-p))
       (or (renpy-close-block-statement-p t)
	   (< (current-indentation)
	      (save-excursion
		(renpy-previous-statement)
		(current-indentation))))))

;;;; Movement.

;; Fixme:  Define {for,back}ward-sexp-function?  Maybe skip units like
;; block, statement, depending on context.

(defun renpy-beginning-of-defun ()
  "`beginning-of-defun-function' for Renpy.
Finds beginning of innermost nested class or method definition.
Returns the name of the definition found at the end, or nil if
reached start of buffer."
  (let ((ci (current-indentation))
	(def-re (rx line-start (0+ space) (or "def" "class") (1+ space)
		    (group (1+ (or word (syntax symbol))))))
	found lep) ;; def-line
    (if (renpy-comment-line-p)
	(setq ci most-positive-fixnum))
    (while (and (not (bobp)) (not found))
      ;; Treat bol at beginning of function as outside function so
      ;; that successive C-M-a makes progress backwards.
      ;;(setq def-line (looking-at def-re))
      (unless (bolp) (end-of-line))
      (setq lep (line-end-position))
      (if (and (re-search-backward def-re nil 'move)
	       ;; Must be less indented or matching top level, or
	       ;; equally indented if we started on a definition line.
	       (let ((in (current-indentation)))
		 (or (and (zerop ci) (zerop in))
		     (= lep (line-end-position)) ; on initial line
		     ;; Not sure why it was like this -- fails in case of
		     ;; last internal function followed by first
		     ;; non-def statement of the main body.
;; 		     (and def-line (= in ci))
		     (= in ci)
		     (< in ci)))
	       (not (renpy-in-string-comment)))
	  (setq found t)))
    found))

(defun renpy-end-of-defun ()
  "`end-of-defun-function' for Renpy.
Finds end of innermost nested class or method definition."
  (let ((orig (point))
	(pattern (rx line-start (0+ space) (or "def" "class") space)))
    ;; Go to start of current block and check whether it's at top
    ;; level.  If it is, and not a block start, look forward for
    ;; definition statement.
    (when (renpy-comment-line-p)
      (end-of-line)
      (forward-comment most-positive-fixnum))
    (if (not (renpy-open-block-statement-p))
	(renpy-beginning-of-block))
    (if (zerop (current-indentation))
	(unless (renpy-open-block-statement-p)
	  (while (and (re-search-forward pattern nil 'move)
		      (renpy-in-string-comment))) ; just loop
	  (unless (eobp)
	    (beginning-of-line)))
      ;; Don't move before top-level statement that would end defun.
      (end-of-line)
      (renpy-beginning-of-defun))
    ;; If we got to the start of buffer, look forward for
    ;; definition statement.
    (if (and (bobp) (not (looking-at "def\\|class")))
	(while (and (not (eobp))
		    (re-search-forward pattern nil 'move)
		    (renpy-in-string-comment)))) ; just loop
    ;; We're at a definition statement (or end-of-buffer).
    (unless (eobp)
      (renpy-end-of-block)
      ;; Count trailing space in defun (but not trailing comments).
      (skip-syntax-forward " >")
      (unless (eobp)			; e.g. missing final newline
	(beginning-of-line)))
    ;; Catch pathological cases like this, where the beginning-of-defun
    ;; skips to a definition we're not in:
    ;; if ...:
    ;;     ...
    ;; else:
    ;;     ...  # point here
    ;;     ...
    ;;     def ...
    (if (< (point) orig)
	(goto-char (point-max)))))

(defun renpy-beginning-of-statement ()
  "Go to start of current statement.
Accounts for continuation lines, multi-line strings, and
multi-line bracketed expressions."
  (beginning-of-line)
  (renpy-beginning-of-string)
  (let (point)
    (while (and (renpy-continuation-line-p)
		(if point
		    (< (point) point)
		  t))
      (beginning-of-line)
      (if (renpy-backslash-continuation-line-p)
	  (progn
	    (forward-line -1)
	    (while (renpy-backslash-continuation-line-p)
	      (forward-line -1)))
	(renpy-beginning-of-string)
	(renpy-skip-out))
      (setq point (point))))
  (back-to-indentation))

(defun renpy-skip-out (&optional forward syntax)
  "Skip out of any nested brackets.
Skip forward if FORWARD is non-nil, else backward.
If SYNTAX is non-nil it is the state returned by `syntax-ppss' at point.
Return non-nil if and only if skipping was done."
  (let ((depth (syntax-ppss-depth (or syntax (syntax-ppss))))
	(forward (if forward -1 1)))
    (unless (zerop depth)
      (if (> depth 0)
	  ;; Skip forward out of nested brackets.
	  (condition-case ()		; beware invalid syntax
	      (progn (backward-up-list (* forward depth)) t)
	    (error nil))
	;; Invalid syntax (too many closed brackets).
	;; Skip out of as many as possible.
	(let (done)
	  (while (condition-case ()
		     (progn (backward-up-list forward)
			    (setq done t))
		   (error nil)))
	  done)))))

(defun renpy-end-of-statement ()
  "Go to the end of the current statement and return point.
Usually this is the start of the next line, but if this is a
multi-line statement we need to skip over the continuation lines.
On a comment line, go to end of line."
  (end-of-line)
  (while (let (comment)
	   ;; Move past any enclosing strings and sexps, or stop if
	   ;; we're in a comment.
	   (while (let ((s (syntax-ppss)))
		    (cond ((eq 'comment (syntax-ppss-context s))
			   (setq comment t)
			   nil)
			  ((eq 'string (syntax-ppss-context s))
			   ;; Go to start of string and skip it.
                           (let ((pos (point)))
                             (goto-char (nth 8 s))
                             (condition-case () ; beware invalid syntax
                                 (progn (forward-sexp) t)
                               ;; If there's a mismatched string, make sure
                               ;; we still overall move *forward*.
                               (error (goto-char pos) (end-of-line)))))
			  ((renpy-skip-out t s))))
	     (end-of-line))
	   (unless comment
	     (eq ?\\ (char-before))))	; Line continued?
    (end-of-line 2))			; Try next line.
  (point))

(defun renpy-previous-statement (&optional count)
  "Go to start of previous statement.
With argument COUNT, do it COUNT times.  Stop at beginning of buffer.
Return count of statements left to move."
  (interactive "p")
  (unless count (setq count 1))
  (if (< count 0)
      (renpy-next-statement (- count))
    (renpy-beginning-of-statement)
    (while (and (> count 0) (not (bobp)))
      (renpy-skip-comments-blanks t)
      (renpy-beginning-of-statement)
      (unless (bobp) (setq count (1- count))))
    count))

(defun renpy-next-statement (&optional count)
  "Go to start of next statement.
With argument COUNT, do it COUNT times.  Stop at end of buffer.
Return count of statements left to move."
  (interactive "p")
  (unless count (setq count 1))
  (if (< count 0)
      (renpy-previous-statement (- count))
    (beginning-of-line)
    (let (bogus)
      (while (and (> count 0) (not (eobp)) (not bogus))
	(renpy-end-of-statement)
	(renpy-skip-comments-blanks)
	(if (eq 'string (syntax-ppss-context (syntax-ppss)))
	    (setq bogus t)
	  (unless (eobp)
	    (setq count (1- count))))))
    count))

(defun renpy-beginning-of-block (&optional arg)
  "Go to start of current block.
With numeric arg, do it that many times.  If ARG is negative, call
`renpy-end-of-block' instead.
If point is on the first line of a block, use its outer block.
If current statement is in column zero, don't move and return nil.
Otherwise return non-nil."
  (interactive "p")
  (unless arg (setq arg 1))
  (cond
   ((zerop arg))
   ((< arg 0) (renpy-end-of-block (- arg)))
   (t
    (let ((point (point)))
      (if (or (renpy-comment-line-p)
	      (renpy-blank-line-p))
	  (renpy-skip-comments-blanks t))
      (renpy-beginning-of-statement)
      (let ((ci (current-indentation)))
	(if (zerop ci)
	    (not (goto-char point))	; return nil
	  ;; Look upwards for less indented statement.
	  (if (catch 'done
;;; This is slower than the below.
;;; 	  (while (zerop (renpy-previous-statement))
;;; 	    (when (and (< (current-indentation) ci)
;;; 		       (renpy-open-block-statement-p t))
;;; 	      (beginning-of-line)
;;; 	      (throw 'done t)))
		(while (and (zerop (forward-line -1)))
		  (when (and (< (current-indentation) ci)
			     (not (renpy-comment-line-p))
			     ;; Move to beginning to save effort in case
			     ;; this is in string.
			     (progn (renpy-beginning-of-statement) t)
			     (renpy-open-block-statement-p t))
		    (beginning-of-line)
		    (throw 'done t)))
		(not (goto-char point))) ; Failed -- return nil
	      (renpy-beginning-of-block (1- arg)))))))))

(defun renpy-end-of-block (&optional arg)
  "Go to end of current block.
With numeric arg, do it that many times.  If ARG is negative,
call `renpy-beginning-of-block' instead.
If current statement is in column zero and doesn't open a block,
don't move and return nil.  Otherwise return t."
  (interactive "p")
  (unless arg (setq arg 1))
  (if (< arg 0)
      (renpy-beginning-of-block (- arg))
    (while (and (> arg 0)
		(let* ((point (point))
		       (_ (if (renpy-comment-line-p)
			      (renpy-skip-comments-blanks t)))
		       (ci (current-indentation))
		       (open (renpy-open-block-statement-p)))
		  (if (and (zerop ci) (not open))
		      (not (goto-char point))
		    (catch 'done
		      (while (zerop (renpy-next-statement))
			(when (or (and open (<= (current-indentation) ci))
				  (< (current-indentation) ci))
			  (renpy-skip-comments-blanks t)
			  (beginning-of-line 2)
			  (throw 'done t)))))))
      (setq arg (1- arg)))
    (zerop arg)))

(defvar renpy-which-func-length-limit 40
  "Non-strict length limit for `renpy-which-func' output.")

(defun renpy-which-func ()
  (let ((function-name (renpy-current-defun renpy-which-func-length-limit)))
    (set-text-properties 0 (length function-name) nil function-name)
    function-name))


;;;; Imenu.

;; For possibily speeding this up, here's the top of the ELP profile
;; for rescanning pydoc.py (2.2k lines, 90kb):
;; Function Name                         Call Count  Elapsed Time  Average Time
;; ====================================  ==========  =============  ============
;; renpy-imenu-create-index             156         2.430906      0.0155827307
;; renpy-end-of-defun                   155         1.2718260000  0.0082053290
;; renpy-end-of-block                   155         1.1898689999  0.0076765741
;; renpy-next-statement                 2970        1.024717      0.0003450225
;; renpy-end-of-statement               2970        0.4332190000  0.0001458649
;; renpy-beginning-of-defun             265         0.0918479999  0.0003465962
;; renpy-skip-comments-blanks           3125        0.0753319999  2.410...e-05

(defvar renpy-recursing)
;;;; `Electric' commands.

(defun renpy-electric-colon (arg)
  "Insert a colon and maybe outdent the line if it is a statement like `else'.
With numeric ARG, just insert that many colons.  With \\[universal-argument],
just insert a single colon."
  (interactive "*P")
  (self-insert-command (if (not (integerp arg)) 1 arg))
  (and (not arg)
       (eolp)
       (renpy-outdent-p)
       (not (renpy-in-string-comment))
       (> (current-indentation) (renpy-calculate-indentation))
       (renpy-indent-line)))		; OK, do it
(put 'renpy-electric-colon 'delete-selection t)

(defun renpy-backspace (arg)
  "Maybe delete a level of indentation on the current line.
Do so if point is at the end of the line's indentation outside
strings and comments.
Otherwise just call `backward-delete-char-untabify'.
Repeat ARG times."
  (interactive "*p")
  (if (or (/= (current-indentation) (current-column))
	  (bolp)
	  (renpy-continuation-line-p)
	  (renpy-in-string-comment))
      (backward-delete-char-untabify arg)
    ;; Look for the largest valid indentation which is smaller than
    ;; the current indentation.
    (let ((indent 0)
	  (ci (current-indentation))
	  (indents (renpy-indentation-levels))
	  initial)
      (dolist (x indents)
	(if (< (car x) ci)
	    (setq indent (max indent (car x)))))
      (setq initial (cdr (assq indent indents)))
      (if (> (length initial) 0)
	  (message "Closes %s" initial))
      (delete-horizontal-space)
      (indent-to indent))))
(put 'renpy-backspace 'delete-selection 'supersede)

(defun renpy-fill-paragraph-2 (&optional justify)
  "`fill-paragraph-function' handling multi-line strings and possibly comments.
If any of the current line is in or at the end of a multi-line string,
fill the string or the paragraph of it that point is in, preserving
the string's indentation."
  (interactive "P")
  (or (fill-comment-paragraph justify)
      (save-excursion
	(end-of-line)
	(let* ((syntax (syntax-ppss))
	       (orig (point))
	       start end)
	  (cond ((nth 4 syntax)	; comment.   fixme: loses with trailing one
		 (let (fill-paragraph-function)
		   (fill-paragraph justify)))
		;; The `paragraph-start' and `paragraph-separate'
		;; variables don't allow us to delimit the last
		;; paragraph in a multi-line string properly, so narrow
		;; to the string and then fill around (the end of) the
		;; current line.
		((eq t (nth 3 syntax))	; in fenced string
		 (goto-char (nth 8 syntax)) ; string start
		 (setq start (line-beginning-position))
		 (setq end (condition-case () ; for unbalanced quotes
                               (progn (forward-sexp)
                                      (- (point) 3))
                             (error (point-max)))))
		((re-search-backward "\\s|\\s-*\\=" nil t) ; end of fenced string
		 (forward-char)
		 (setq end (point))
		 (condition-case ()
		     (progn (backward-sexp)
			    (setq start (line-beginning-position)))
		   (error nil))))
	  (when end
	    (save-restriction
	      (narrow-to-region start end)
	      (goto-char orig)
	      ;; Avoid losing leading and trailing newlines in doc
	      ;; strings written like:
	      ;;   """
	      ;;   ...
	      ;;   """
	      (let ((paragraph-separate
		     ;; Note that the string could be part of an
		     ;; expression, so it can have preceding and
		     ;; trailing non-whitespace.
		     (concat
		      (rx (or
			   ;; Opening triple quote without following text.
			   (and (* nonl)
				(group (syntax string-delimiter))
				(repeat 2 (backref 1))
				;; Fixme:  Not sure about including
				;; trailing whitespace.
				(* (any " \t"))
				eol)
			   ;; Closing trailing quote without preceding text.
			   (and (group (any ?\" ?')) (backref 2)
				(syntax string-delimiter))))
		      "\\(?:" paragraph-separate "\\)"))
		    fill-paragraph-function)
		(fill-paragraph justify))))))) t)

(defun renpy-shift-left (start end &optional count)
  "Shift lines in region COUNT (the prefix arg) columns to the left.
COUNT defaults to `renpy-indent'.  If region isn't active, just shift
current line.  The region shifted includes the lines in which START and
END lie.  It is an error if any lines in the region are indented less than
COUNT columns."
  (interactive
   (if mark-active
       (list (region-beginning) (region-end) current-prefix-arg)
     (list (line-beginning-position) (line-end-position) current-prefix-arg)))
  (if count
      (setq count (prefix-numeric-value count))
    (setq count renpy-indent))
  (when (> count 0)
    (save-excursion
      (goto-char start)
      (while (< (point) end)
	(if (and (< (current-indentation) count)
		 (not (looking-at "[ \t]*$")))
	    (error "Can't shift all lines enough"))
	(forward-line))
      (indent-rigidly start end (- count)))))

(add-to-list 'debug-ignored-errors "^Can't shift all lines enough")

(defun renpy-shift-right (start end &optional count)
  "Shift lines in region COUNT (the prefix arg) columns to the right.
COUNT defaults to `renpy-indent'.  If region isn't active, just shift
current line.  The region shifted includes the lines in which START and
END lie."
  (interactive
   (if mark-active
       (list (region-beginning) (region-end) current-prefix-arg)
     (list (line-beginning-position) (line-end-position) current-prefix-arg)))
  (if count
      (setq count (prefix-numeric-value count))
    (setq count renpy-indent))
  (indent-rigidly start end count))

(defun renpy-outline-level ()
  "`outline-level' function for Renpy mode.
The level is the number of `renpy-indent' steps of indentation
of current line."
  (1+ (/ (current-indentation) renpy-indent)))

;; Fixme: Consider top-level assignments, imports, &c.
(defun renpy-current-defun (&optional length-limit)
  "`add-log-current-defun-function' for Renpy."
  (save-excursion
    ;; Move up the tree of nested `class' and `def' blocks until we
    ;; get to zero indentation, accumulating the defined names.
    (let ((accum)
	  (length -1))
      (catch 'done
	(while (or (null length-limit)
		   (null (cdr accum))
		   (< length length-limit))
	  (let ((started-from (point)))
	    (renpy-beginning-of-block)
	    (end-of-line)
	    (beginning-of-defun)
	    (when (= (point) started-from)
	      (throw 'done nil)))
	  (when (looking-at (rx (0+ space) (or "def" "class") (1+ space)
				(group (1+ (or word (syntax symbol))))))
	    (push (match-string 1) accum)
	    (setq length (+ length 1 (length (car accum)))))
	  (when (= (current-indentation) 0)
	    (throw 'done nil))))
      (when accum
	(when (and length-limit (> length length-limit))
	  (setcar accum ".."))
	(mapconcat 'identity accum ".")))))

(defun renpy-mark-block ()
  "Mark the block around point.
Uses `renpy-beginning-of-block', `renpy-end-of-block'."
  (interactive)
  (push-mark)
  (renpy-beginning-of-block)
  (push-mark (point) nil t)
  (renpy-end-of-block)
  (exchange-point-and-mark))

;;;; Modes.

;; pdb tracking is alert once this file is loaded, but takes no action if
;; `renpy-pdbtrack-do-tracking-p' is nil.

(defvar outline-heading-end-regexp)
(defvar eldoc-documentation-function)
(defvar renpy-mode-running)            ;Dynamically scoped var.

;;;###autoload
(define-derived-mode renpy-mode fundamental-mode "Ren'Py"
  "Major mode for editing Renpy files.
Turns on Font Lock mode unconditionally since it is currently required
for correct parsing of the source.
See also `jython-mode', which is actually invoked if the buffer appears to
contain Jython code.  See also `run-renpy' and associated Renpy mode
commands for running Renpy under Emacs.

The Emacs commands which work with `defun's, e.g. \\[beginning-of-defun], deal
with nested `def' and `class' blocks.  They take the innermost one as
current without distinguishing method and class definitions.  Used multiple
times, they move over others at the same indentation level until they reach
the end of definitions at that level, when they move up a level.
\\<renpy-mode-map>
Colon is electric: it outdents the line if appropriate, e.g. for
an else statement.  \\[renpy-backspace] at the beginning of an indented statement
deletes a level of indentation to close the current block; otherwise it
deletes a character backward.  TAB indents the current line relative to
the preceding code.  Successive TABs, with no intervening command, cycle
through the possibilities for indentation on the basis of enclosing blocks.

\\[fill-paragraph] fills comments and multi-line strings appropriately, but has no
effect outside them.

Supports Eldoc mode (only for functions, using a Renpy process),
Info-Look and Imenu.  In Outline minor mode, `class' and `def'
lines count as headers.  Symbol completion is available in the
same way as in the Renpy shell using the `rlcompleter' module
and this is added to the Hippie Expand functions locally if
Hippie Expand mode is turned on.  Completion of symbols of the
form x.y only works if the components are literal
module/attribute names, not variables.  An abbrev table is set up
with skeleton expansions for compound statement templates.

\\{renpy-mode-map}"
  :group 'renpy
  (set (make-local-variable 'font-lock-defaults)
       '(renpy-font-lock-keywords nil nil nil nil
				   (font-lock-syntactic-keywords
				    . renpy-font-lock-syntactic-keywords)
				   ;; This probably isn't worth it.
				   ;; (font-lock-syntactic-face-function
				   ;;  . renpy-font-lock-syntactic-face-function)
				   ))
  (set (make-local-variable 'parse-sexp-lookup-properties) t)
  (set (make-local-variable 'parse-sexp-ignore-comments) t)
  (set (make-local-variable 'comment-start) "# ")
  (set (make-local-variable 'indent-line-function) #'renpy-indent-line)
  (set (make-local-variable 'indent-region-function) #'renpy-indent-region)
  (set (make-local-variable 'paragraph-start) "\\s-*$")
  (set (make-local-variable 'fill-paragraph-function) 'renpy-fill-paragraph)
  (set (make-local-variable 'require-final-newline) mode-require-final-newline)
  (set (make-local-variable 'add-log-current-defun-function)
       #'renpy-current-defun)
  (set (make-local-variable 'outline-regexp)
       (rx (* space) (or "class" "def" "elif" "else" "except" "finally"
			 "for" "if" "try" "while" "with")
	   symbol-end))
  (set (make-local-variable 'outline-heading-end-regexp) ":\\s-*\n")
  (set (make-local-variable 'outline-level) #'renpy-outline-level)
  (set (make-local-variable 'open-paren-in-column-0-is-defun-start) nil)
  (make-local-variable 'renpy-saved-check-command)
  (set (make-local-variable 'beginning-of-defun-function)
       'renpy-beginning-of-defun)
  (set (make-local-variable 'end-of-defun-function) 'renpy-end-of-defun)
  (add-hook 'which-func-functions 'renpy-which-func nil t)

  (setq imenu-create-index-function 'imenu-default-create-index-function)
  (setq imenu-generic-expression renpy-generic-imenu)
  
  (set (make-local-variable 'eldoc-documentation-function)
       #'renpy-eldoc-function)
;;  (add-hook 'eldoc-mode-hook
;;	    (lambda () (run-renpy nil t)) ; need it running
;;	    nil t)
  (set (make-local-variable 'symbol-completion-symbol-function)
       'renpy-partial-symbol)
  (set (make-local-variable 'symbol-completion-completions-function)
       'renpy-symbol-completions)
  ;; Fixme: should be in hideshow.  This seems to be of limited use
  ;; since it isn't (can't be) indentation-based.  Also hide-level
  ;; doesn't seem to work properly.
  (add-to-list 'hs-special-modes-alist
	       `(renpy-mode "^\\s-*\\(?:def\\|class\\)\\>" nil "#"
		 ,(lambda (arg)
		    (renpy-end-of-defun)
		    (skip-chars-backward " \t\n"))
		 nil))
  (set (make-local-variable 'skeleton-further-elements)
       '((< '(backward-delete-char-untabify (min renpy-indent
						 (current-column))))
	 (^ '(- (1+ (current-indentation))))))
  ;; Let's not mess with hippie-expand.  Symbol-completion should rather be
  ;; bound to another key, since it has different performance requirements.
  ;; (if (featurep 'hippie-exp)
  ;;     (set (make-local-variable 'hippie-expand-try-functions-list)
  ;;          (cons 'symbol-completion-try-complete
  ;;       	 hippie-expand-try-functions-list)))
  ;; Renpy defines TABs as being 8-char wide.
  (set (make-local-variable 'tab-width) 8)
  (unless font-lock-mode (font-lock-mode 1))
  (when renpy-guess-indent (renpy-guess-indent))
  ;; Let's make it harder for the user to shoot himself in the foot.
  (unless (= tab-width renpy-indent)
    (setq indent-tabs-mode nil))
  )

;; Not done automatically in Emacs 21 or 22.
(defcustom renpy-mode-hook nil
  "Hook run when entering Renpy mode."
  :group 'renpy
  :type 'hook)
(custom-add-option 'renpy-mode-hook 'imenu-add-menubar-index)
(custom-add-option 'renpy-mode-hook
		   (lambda ()
		     "Turn off Indent Tabs mode."
		     (setq indent-tabs-mode nil)))
(custom-add-option 'renpy-mode-hook 'turn-on-eldoc-mode)
(custom-add-option 'renpy-mode-hook 'abbrev-mode)
(custom-add-option 'renpy-mode-hook 'renpy-setup-brm)


(defun renpy-in-literal ()
  (syntax-ppss-context (syntax-ppss)))

; Indents a paragraph. We also handle strings properly.
(defun renpy-fill-paragraph (&optional justify)
  (interactive)
  (if (eq (renpy-in-literal) 'string)
      (let* ((string-indentation (renpy-string-indentation))
             (fill-prefix (renpy-string-fill-prefix))
             (fill-column (- fill-column string-indentation))
             (fill-paragraph-function nil)
             (indent-line-function nil)
             )
        
        (message "fill prefix: %S" fill-prefix)

        (renpy-fill-string (renpy-string-start))
        t
        )
    (renpy-fill-paragraph-2 justify)
    )   
  )

; Indents the current line. 
(defun renpy-indent-line (&optional arg)
  (interactive)

  ; Let python-mode indent. (Always needed to keep python-mode sane.)
  (renpy-indent-line-2)

  ; Reindent strings if appropriate.
  (save-excursion
    (beginning-of-line)
    (if (eq (renpy-in-literal) 'string)
        (progn 
          (delete-horizontal-space)
          (indent-to (renpy-string-indentation))
          )
      ))

  (if ( < (current-column) (current-indentation) )
      (back-to-indentation) )

  )


; Computes the start of the current string.
(defun renpy-string-start ()
  (nth 8 (parse-partial-sexp (point-min) (point)))
  )

; Computes the amount of indentation needed to put the current string
; in the right spot.
(defun renpy-string-indentation () 
  (+ 1
     (save-excursion
       (- (goto-char (renpy-string-start))
          (progn (beginning-of-line) (point)))
       )
     )
  )



(provide 'renpy)

;;; renpy.el ends here
