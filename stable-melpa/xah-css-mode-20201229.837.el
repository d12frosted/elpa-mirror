;;; xah-css-mode.el --- Major mode for editing CSS code. -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2013-2020 by Xah Lee

;; Author: Xah Lee ( http://xahlee.info/ )
;; Version: 2.13.20201229002950
;; Created: 18 April 2013
;; Package-Requires: ((emacs "24.3"))
;; Keywords: languages, convenience, css, color
;; License: GPL v3
;; Homepage:  http://ergoemacs.org/emacs/xah-css-mode.html

;; This file is not part of GNU Emacs.

;;; Commentary:

;; Major mode for editing CSS code. Alternative to GNU emacs's builtin `css-mode'.

;; Features:

;; • Correct Syntax coloring ALL CSS words. Does not color typos.

;; • Color coded words by semantics. Each type of CSS words are colored distinctly. e.g. HTML tag names, CSS attribute names, predefined CSS value names, CSS unit names, pseudo selector names, media keywords, etc.

;; • ID selector string and class name in bold for easy identification.

;; • Keyword completion with `ido-mode' interface. Press Tab ↹ after a word to complete. All CSS words are supported: {html5 tags, property names, property value keywords, units, colors, pseudo selectors, “at keywords”, …}.

;; • Single Key Prettify Code Format. Press Tab ↹ before word to reformat current block of code. That is, all lines enclosed by curly brackets {}.

;; • Syntax coloring of hexadecimal color format #rrggbb , #rgb , and HSL Color format hsl(0,68%,42%).

;; • Call `xah-css-hex-to-hsl-color' to convert #rrggbb color format under cursor to HSL Color format.

;; • Call `xah-css-compact-css-region' to minify region.

;; • Call `xah-css-expand-to-multi-lines' to expand minified CSS code to multi-lines format.

;; • Call `describe-function' on `xah-css-mode' for detail.

;;; INSTALL:

;; To manual install,
;; Place the file at ~/.emacs.d/lisp/ . Create the dir if it doesn't exist.
;; Then put the following in ~/.emacs.d/init.el
;; (add-to-list 'load-path "~/.emacs.d/lisp/")
;; (autoload 'xah-css-mode "xah-css-mode" "css major mode." t)

;;; HISTORY

;; version history no longer kept here. See git log.
;; version 2015-01-30 fix a problem with emacs 24.3.1, Debugger entered--Lisp error: (file-error "Cannot open load file" "prog-mode")
;; version 0.3, 2013-05-02 added xah-css-hex-color-to-hsl, and other improvements.
;; version 0.2, 2013-04-22 added xah-css-compact-css-region
;; version 0.1, 2013-04-18 first version


;;; Code:

(require 'color) ; part of emacs 24.1
(require 'newcomment)
(require 'ido)
(require 'lisp-mode) ; for indent-sexp. todo possibly write own customized for css
(require 'xah-replace-pairs)

(defvar xah-css-mode-hook nil "Standard hook for `xah-css-mode'")



(defface xah-css-id-selector
  '(
    (t :foreground "firebrick" :weight bold))
  "face for CSS ID selector “#…”."
  :group 'xah-css-mode )

(defface xah-css-class-selector
  '(
    (t :weight bold))
  "face for CSS class name selector “.…”."
  :group 'xah-css-mode )

;; temp for debugging
(face-spec-set
 'xah-css-id-selector
 '(
   (t :foreground "firebrick" :weight bold))
 'face-defface-spec
 )

(face-spec-set
 'xah-css-class-selector
 '(
   (t :weight bold))
 'face-defface-spec
 )

(defun xah-css-insert-random-color-hsl ()
  "Insert a random color string of CSS HSL format.
Sample output: hsl(100,24%,82%);
URL `http://ergoemacs.org/emacs/emacs_CSS_colors.html'
Version 2015-06-11"
  (interactive)
  (insert (format "hsl(%d,%d%%,%d%%);" (random 360) (random 100) (random 100))))

(defun xah-css-hex-color-to-hsl ()
  "Convert color spec under cursor from “#rrggbb” to CSS HSL format.
 e.g. #ffefd5 ⇒ hsl(37,100%,91%)
URL `http://ergoemacs.org/emacs/elisp_convert_rgb_hsl_color.html'
Version 2016-07-19"
  (interactive)
  (let* (
         ($bds (bounds-of-thing-at-point 'word))
         ($p1 (car $bds))
         ($p2 (cdr $bds))
         ($currentWord (buffer-substring-no-properties $p1 $p2)))
    (if (string-match "[a-fA-F0-9]\\{6\\}" $currentWord)
        (progn
          (delete-region $p1 $p2 )
          (when (equal (char-before) 35) ; 35 is #
            (delete-char -1))
          (insert (xah-css-hex-to-hsl-color $currentWord )))
      (progn
        (user-error "The current word 「%s」 is not of the form #rrggbb." $currentWord)))))

(defun xah-css-hex-to-hsl-color (@hex-str)
  "Convert @hex-str color to CSS HSL format.
Return a string. Example:  \"ffefd5\" ⇒ \"hsl(37,100%,91%)\"
Note: The input string must NOT start with “#”.
URL `http://ergoemacs.org/emacs/emacs_CSS_colors.html'
Version 2016-07-19"
  (let* (
         ($colorVec (xah-css-convert-color-hex-to-vec @hex-str))
         ($R (elt $colorVec 0))
         ($G (elt $colorVec 1))
         ($B (elt $colorVec 2))
         ($hsl (color-rgb-to-hsl $R $G $B))
         ($H (elt $hsl 0))
         ($S (elt $hsl 1))
         ($L (elt $hsl 2)))
    (format "hsl(%d,%d%%,%d%%)" (* $H 360) (* $S 100) (* $L 100))))

(defun xah-css-convert-color-hex-to-vec (@rrggbb)
  "Convert color @rrggbb from “\"rrggbb\"” string to a elisp vector [r g b], where the values are from 0 to 1.
Example:
 (xah-css-convert-color-hex-to-vec \"00ffcc\") ⇒ [0.0 1.0 0.8]

Note: The input string must NOT start with “#”.
URL `http://ergoemacs.org/emacs/emacs_CSS_colors.html'
Version 2016-07-19"
  (vector
   (xah-css-normalize-number-scale (string-to-number (substring @rrggbb 0 2) 16) 255)
   (xah-css-normalize-number-scale (string-to-number (substring @rrggbb 2 4) 16) 255)
   (xah-css-normalize-number-scale (string-to-number (substring @rrggbb 4) 16) 255)))

(defun xah-css-normalize-number-scale (@val @range-max)
  "Scale @val from range [0, @range-max] to [0, 1]
The arguments can be int or float.
Return value is float.
URL `http://ergoemacs.org/emacs/emacs_CSS_colors.html'
Version 2016-07-19"
  (/ (float @val) (float @range-max)))


;;; functions

(defun xah-css-smart-newline ()
  "Insert a newline, maybe add a semicolon before.
Version 2018-02-19"
  (interactive)
  (backward-char )
  (if (looking-at "[a-z0-9]")
      (progn
        (forward-char )
        (if (xah-css-expand-abbrev)
            (progn )
          (progn (insert ";")
                 (newline))))
    (progn
      (forward-char )
      (newline))))

(defun xah-css-compact-block ()
  "Compact current CSS code block.
A block is surrounded by blank lines.
This command basically replace newline char by space.
Version 2015-06-29"
  (interactive)
  (let ($p1 $p2)
    (save-excursion
      (if (re-search-backward "\n[ \t]*\n" nil "move")
          (progn (re-search-forward "\n[ \t]*\n")
                 (setq $p1 (point)))
        (setq $p1 (point)))
      (if (re-search-forward "\n[ \t]*\n" nil "move")
          (progn (re-search-backward "\n[ \t]*\n")
                 (setq $p2 (point)))
        (setq $p2 (point))))
    (save-restriction
      (narrow-to-region $p1 $p2)

      (goto-char (point-min))
      (while (search-forward "\n" nil t)
        (replace-match " "))

      (goto-char (point-min))
      (while (search-forward-regexp "  +" nil t)
        (replace-match " ")))))

(defun xah-css-compact-css-region (&optional @begin @end)
  "Remove unnecessary whitespaces of CSS source code in region.
Works on text selection or the {} block cursor is in, or the {} block before cursor.
Note: this command only add/remove whitespaces.
URL `http://ergoemacs.org/emacs/elisp_css_compressor.html'
Version 2020-12-23"
  (interactive)
  (let ($p1 $p2)
    (if @begin
        (setq $p1 @begin $p2 @end)
      (if (use-region-p)
          (setq $p1 (region-beginning) $p2 (region-end))
        (when (search-backward "{" )
          (setq $p1 (point))
          (when (search-forward "}"))
          (setq $p2 (point)))))
    (save-restriction
      (narrow-to-region $p1 $p2)
      (xah-replace-pairs-region (point-min) (point-max) '( ["\t" " "] ["\n" " "] ["{" " {"] ))
      (xah-replace-regexp-pairs-region (point-min) (point-max) '( ["  +" " "]  ))
      (xah-replace-pairs-region (point-min) (point-max) '( [" }" "}"] ))
      (xah-replace-pairs-region (point-min) (point-max) '( [" ;" ";"] ["; " ";"] ))
      (xah-replace-regexp-pairs-region (point-min) (point-max) '( ["\n\n+" "\n"] ["} ?" "}\n"] )))))

(defun xah-css-compact-css-buffer ()
  "Remove unnecessary whitespaces of CSS source code in buffer.
See `xah-css-compact-css-region'.
URL `http://ergoemacs.org/emacs/elisp_css_compressor.html'
Version 2020-12-18"
  (interactive)
  (xah-css-compact-css-region (point-min) (point-max)))

(defun xah-css-expand-to-multi-lines (&optional @begin @end)
  "Expand minified CSS code to multiple lines.
Works on text selection or the {} block cursor is in, or before cursor.
Note: this command only add/remove whitespaces.
Version 2016-10-02 2020-12-23"
  (interactive)
  (let ($p1 $p2)
    (if @begin
        (setq $p1 @begin $p2 @end)
      (if (use-region-p)
          (setq $p1 (region-beginning) $p2 (region-end))
        (when (search-backward "{" )
          (setq $p1 (point))
          (when (search-forward "}"))
          (setq $p2 (point)))))
    (save-restriction
      (narrow-to-region $p1 $p2)
      (xah-replace-pairs-region
       (point-min)
       (point-max)
       '(
         [";" ";\n"]
         ["/* " "\n/*"]
         ["*/" "*/\n"]
         ["{" "\n{\n"]
         ["}" "\n}\n"]
         ))
      (xah-replace-regexp-pairs-region
       (point-min)
       (point-max)
       '(
         ["\n\n+" "\n"]
         )))))


(defvar xah-css-html-tag-names nil "List of HTML5 tag names.")
(setq xah-css-html-tag-names

'(
"a" "abbr" "address" "applet" "area" "article" "aside" "audio" "b"
"base" "basefont" "bdi" "bdo" "blockquote" "body" "br" "button"
"canvas" "caption" "cite" "code" "col" "colgroup" "command" "datalist"
"dd" "del" "details" "dfn" "div" "dl" "doctype" "dt" "em" "embed"
"fieldset" "figcaption" "figure" "footer" "form" "h1" "h2" "h3" "h4"
"h5" "h6" "head" "header" "hgroup" "hr" "html" "i" "iframe" "img"
"input" "ins" "kbd" "keygen" "label" "legend" "li" "link"
"main"
 "map" "mark"
"menu" "meta" "meter" "nav" "noscript" "object" "ol" "optgroup"
"option" "output" "p" "param" "pre" "progress" "q" "rp" "rt" "ruby"
"s" "samp" "script" "section" "select" "small" "source" "span"
"strong" "style" "sub" "summary" "sup" "table" "tbody" "td" "textarea"
"tfoot" "th" "thead" "time" "title" "tr" "u" "ul" "var" "video" "wbr"

))

(defvar xah-css-property-names nil "List of CSS property names.")
(setq xah-css-property-names
'(

"align-content"
"align-items"
"align-self"
"animation"
"animation-delay"
"animation-direction"
"animation-duration"
"animation-fill-mode"
"animation-iteration-count"
"animation-name"
"animation-play-state"
"animation-timing-function"
"anywhere"
"attr"
"backface-visibility"
"background"
"background-attachment"
"background-clip"
"background-color"
"background-image"
"background-origin"
"background-position"
"background-position-x"
"background-position-y"
"background-repeat"
"background-size"
"border"
"border-bottom"
"border-bottom-color"
"border-bottom-left-radius"
"border-bottom-right-radius"
"border-bottom-style"
"border-bottom-width"
"border-collapse"
"border-color"
"border-image"
"border-image-outset"
"border-image-repeat"
"border-image-slice"
"border-image-source"
"border-image-width"
"border-left"
"border-left-color"
"border-left-style"
"border-left-width"
"border-radius"
"border-right"
"border-right-color"
"border-right-style"
"border-right-width"
"border-spacing"
"border-style"
"border-top"
"border-top-color"
"border-top-left-radius"
"border-top-right-radius"
"border-top-style"
"border-top-width"
"border-width"
"bottom"
"bottom"
"box-decoration-break"
"box-shadow"
"box-sizing"
"break-after"
"break-before"
"break-inside"
"clear"
"color"
"column-count"
"content"
"counter-increment"
"counter-reset"
"cursor"
"direction"
"display"
"filter"
"float"
"font"
"font-family"
"font-size"
"font-style"
"font-weight"
"height"
"left"
"letter-spacing"
"line-height"
"list-style"
"list-style-image"
"list-style-type"
"margin"
"margin-bottom"
"margin-left"
"margin-right"
"margin-top"
"max-height"
"max-width"
"min-height"
"min-width"
"opacity"
"orphans"
"outline"
"overflow"
"padding"
"padding-bottom"
"padding-left"
"padding-right"
"padding-top"
"page-break-after"
"page-break-inside"
"position"
"pre-wrap"
"right"
"tab-size"
"table-layout"
"text-align"
"text-align"
"text-align-last"
"text-combine-horizontal"
"text-decoration"
"text-decoration"
"text-decoration-color"
"text-decoration-line"
"text-decoration-style"
"text-indent"
"text-orientation"
"text-overflow"
"text-rendering"
"text-shadow"
"text-transform"
"text-underline-position"
"top"
"top"
"transform"
"transform-origin"
"transform-style"
"transition"
"transition-delay"
"transition-duration"
"transition-property"
"transition-timing-function"
"unicode-bidi"
"vertical-align"
"visibility"
"white-space"
"widows"
"width"
"word-spacing"
"word-wrap"
"z-index"

"overflow-wrap"

) )

(defvar xah-css-pseudo-selector-names nil "List of CSS pseudo selector names.")
(setq xah-css-pseudo-selector-names '(
":active"
":after"
":any"
":before"
":checked"
":default"
":dir"
":disabled"
":empty"
":enabled"
":first"
":first-child"
":first-letter"
":first-line"
":first-of-type"
":focus"
":fullscreen"
":hover"
":in-range"
":indeterminate"
":invalid"
":lang"
":last-child"
":last-of-type"
":left"
":link"
":not"
":nth-child"
":nth-last-child"
":nth-last-of-type"
":nth-of-type"
":only-child"
":only-of-type"
":optional"
":out-of-range"
":read-only"
":read-write"
":required"
":right"
":root"
":scope"
":target"
":valid"
":visited"
) )

(defvar xah-css-media-keywords nil "List of CSS media keywords.")
(setq xah-css-media-keywords '(
"@charset"
"@document"
"@font-face"
"@import"
"@keyframes"
"@media"
"@namespace"
"@page"
"@supports"
"@viewport"
"print"
"screen"
"all"
"speech"
"and"
"not"
"only"
) ) ; todo

(defvar xah-css-unit-names nil "List of CSS unite names.")
(setq xah-css-unit-names
 '("px" "pt" "pc" "cm" "mm" "in" "em" "rem" "ex" "%" "deg" "ch" "vw" "vh" "vmin" "vmax" ) )

(defvar xah-css-value-kwds nil "List of CSS value names")
(setq
 xah-css-value-kwds
 '(

"absolute"
"alpha"
"at"
"auto"
"avoid"
"blink"
"block"
"bold"
"border-box"
"both"
"bottom"
"break-word"
"calc"
"capitalize"
"center"
"circle"
"collapse"
"content-box"
"dashed"
"dotted"
"double"
"ellipse"
"embed"
"fixed"
"flex"
"flex-start"
"flex-wrap"
"grid"
"groove"
"help"
"hidden"
"hsl"
"hsla"
"important" ; todo, this actually needs to be !important
"inherit"
"initial"
"inline"
"inline-block"
"inset"
"italic"
"justify"
"large"
"left"
"line-through"
"linear-gradient"
"lowercase"
"ltr"
"middle"
"monospace"
"no-repeat"
"none"
"normal"
"nowrap"
"oblique"
"outset"
"overline"
"pointer"
"radial-gradient"
"relative"
"repeat"
"repeat-x"
"repeat-y"
"revert"
"rgb"
"rgba"
"ridge"
"right"
"rotate"
"rotate3d"
"rotateX"
"rotateY"
"rotateZ"
"rtl"
"sans-serif"
"scale"
"scale3d"
"scaleX"
"scaleY"
"scaleZ"
"serif"
"skew"
"skewX"
"skewY"
"small"
"smaller"
"solid"
"square"
"static"
"steps"
"table"
"table-caption"
"table-cell"
"table-column"
"table-column-group"
"table-footer-group"
"table-header-group"
"table-row"
"table-row-group"
"thick"
"thin"
"top"
"translate"
"translate3d"
"translateX"
"translateY"
"translateZ"
"transparent"
"underline"
"unset"
"uppercase"
"url"
"visible"
"wrap"
"x-large"
"xx-large"

   ) )

(defvar xah-css-color-names nil "List of CSS color names.")
(setq xah-css-color-names

'("aliceblue" "antiquewhite" "aqua" "aquamarine" "azure" "beige"
"bisque" "black" "blanchedalmond" "blue" "blueviolet" "brown"
"burlywood" "cadetblue" "chartreuse" "chocolate" "coral"
"cornflowerblue" "cornsilk" "crimson" "cyan" "darkblue" "darkcyan"
"darkgoldenrod" "darkgray" "darkgreen" "darkgrey" "darkkhaki"
"darkmagenta" "darkolivegreen" "darkorange" "darkorchid" "darkred"
"darksalmon" "darkseagreen" "darkslateblue" "darkslategray"
"darkslategrey" "darkturquoise" "darkviolet" "deeppink" "deepskyblue"
"dimgray" "dimgrey" "dodgerblue" "firebrick" "floralwhite"
"forestgreen" "fuchsia" "gainsboro" "ghostwhite" "gold" "goldenrod"
"gray" "green" "greenyellow" "grey" "honeydew" "hotpink" "indianred"
"indigo" "ivory" "khaki" "lavender" "lavenderblush" "lawngreen"
"lemonchiffon" "lightblue" "lightcoral" "lightcyan"
"lightgoldenrodyellow" "lightgray" "lightgreen" "lightgrey"
"lightpink" "lightsalmon" "lightseagreen" "lightskyblue"
"lightslategray" "lightslategrey" "lightsteelblue" "lightyellow"
"lime" "limegreen" "linen" "magenta" "maroon" "mediumaquamarine"
"mediumblue" "mediumorchid" "mediumpurple" "mediumseagreen"
"mediumslateblue" "mediumspringgreen" "mediumturquoise"
"mediumvioletred" "midnightblue" "mintcream" "mistyrose" "moccasin"
"navajowhite" "navy" "oldlace" "olive" "olivedrab" "orange"
"orangered" "orchid" "palegoldenrod" "palegreen" "paleturquoise"
"palevioletred" "papayawhip" "peachpuff" "peru" "pink" "plum"
"powderblue" "purple" "red" "rosybrown" "royalblue" "saddlebrown"
"salmon" "sandybrown" "seagreen" "seashell" "sienna" "silver"
"skyblue" "slateblue" "slategray" "slategrey" "snow" "springgreen"
"steelblue" "tan" "teal" "thistle" "tomato" "turquoise" "violet"
"wheat" "white" "whitesmoke" "yellow" "yellowgreen") )

(defvar xah-css-all-keywords nil "List of all CSS keywords")
(setq xah-css-all-keywords (append xah-css-html-tag-names
                                     xah-css-color-names
                                     xah-css-property-names
                                     xah-css-pseudo-selector-names
                                     xah-css-media-keywords
                                     xah-css-unit-names
                                     xah-css-value-kwds
                                     ))


;; completion

(defun xah-css-complete-symbol ()
  "Perform keyword completion on current word.
This uses `ido-mode' user interface for completion."
  (interactive)
  (let* (
         ($bds (bounds-of-thing-at-point 'symbol))
         ($p1 (car $bds))
         ($p2 (cdr $bds))
         ($current-sym
          (if  (or (null $p1) (null $p2) (equal $p1 $p2))
              ""
            (buffer-substring-no-properties $p1 $p2)))
         $result-sym)
    (when (not $current-sym) (setq $current-sym ""))
    (setq $result-sym
          (ido-completing-read "" xah-css-all-keywords nil nil $current-sym ))
    (delete-region $p1 $p2)
    (insert $result-sym)))


;; syntax table
(defvar xah-css-mode-syntax-table nil "Syntax table for `xah-css-mode'.")
(setq xah-css-mode-syntax-table
      (let ((synTable (make-syntax-table)))

;        (modify-syntax-entry ?0  "." synTable)
;        (modify-syntax-entry ?1  "." synTable)
;        (modify-syntax-entry ?2  "." synTable)
;        (modify-syntax-entry ?3  "." synTable)
;        (modify-syntax-entry ?4  "." synTable)
;        (modify-syntax-entry ?5  "." synTable)
;        (modify-syntax-entry ?6  "." synTable)
;        (modify-syntax-entry ?7  "." synTable)
;        (modify-syntax-entry ?8  "." synTable)
;        (modify-syntax-entry ?9  "." synTable)

        (modify-syntax-entry ?_ "_" synTable)
        (modify-syntax-entry ?: "." synTable)

        (modify-syntax-entry ?- "_" synTable)
        (modify-syntax-entry ?\/ ". 14" synTable) ; /* java style comment*/
        (modify-syntax-entry ?* ". 23" synTable)
        synTable))


;; syntax coloring related

(setq xah-css-font-lock-keywords
      (let (
            (cssPseudoSelectorNames (regexp-opt xah-css-pseudo-selector-names ))
            (htmlTagNames (regexp-opt xah-css-html-tag-names 'symbols))
            (cssPropertieNames (regexp-opt xah-css-property-names 'symbols ))
            (cssValueNames (regexp-opt xah-css-value-kwds 'symbols))
            (cssColorNames (regexp-opt xah-css-color-names 'symbols))
            (cssUnitNames (regexp-opt xah-css-unit-names ))
            (cssMedia (regexp-opt xah-css-media-keywords )))
        `(
          ("#[-_a-zA-Z]+[-_a-zA-Z0-9]*" . 'xah-css-id-selector)
          ("\\.[a-zA-Z]+[-_a-zA-Z0-9]*" . 'xah-css-class-selector)
          (,cssPseudoSelectorNames . font-lock-preprocessor-face)
          (,htmlTagNames . font-lock-function-name-face)
          (,cssPropertieNames . font-lock-variable-name-face )
          (,cssValueNames . font-lock-keyword-face)
          (,cssColorNames . font-lock-constant-face)

          (,(concat "[0-9]" "\\(" cssUnitNames "\\)") . (1 font-lock-type-face))
          ;; (,(concat "[0-9]+" cssUnitNames  ) . font-lock-type-face)

          (,cssMedia . font-lock-builtin-face)

          ("#[[:xdigit:]]\\{6,6\\}" .
           (0 (put-text-property
               (match-beginning 0)
               (match-end 0)
               'face (list :background (match-string-no-properties 0)))))

          ("#[[:xdigit:]]\\{3,3\\};" .
           (0 (put-text-property
               (match-beginning 0)
               (match-end 0)
               'face
               (list
                :background
                (let* (
                       (ms (match-string-no-properties 0))
                       (r (substring ms 1 2))
                       (g (substring ms 2 3))
                       (b (substring ms 3 4)))
                  (concat "#" r r g g b b))))))

          ("hsl( *\\([0-9]\\{1,3\\}\\) *, *\\([0-9]\\{1,3\\}\\)% *, *\\([0-9]\\{1,3\\}\\)% *)" .
           (0 (put-text-property
               (+ (match-beginning 0) 3)
               (match-end 0)
               'face
               (list
                :background
                (concat "#"
                        (mapconcat
                         'identity
                         (mapcar
                          (lambda (x) (format "%02x" (round (* x 255))))
                          (color-hsl-to-rgb
                           (/ (string-to-number (match-string-no-properties 1)) 360.0)
                           (/ (string-to-number (match-string-no-properties 2)) 100.0)
                           (/ (string-to-number (match-string-no-properties 3)) 100.0)))
                         "" )) ;  "#00aa00"
                ))))

          ("'[^']+'" . font-lock-string-face))))


;; indent/reformat related

(defun xah-css-complete-or-indent ()
  "Do keyword completion or indent/prettify-format.

If char before point is letters and char after point is whitespace or punctuation, then do completion, except when in string or comment. In these cases, do `xah-css-prettify-root-sexp'."
  (interactive)
  ;; consider the char to the left or right of cursor. Each side is either empty or char.
  ;; there are 4 cases:
  ;; space▮space → do indent
  ;; space▮char → do indent
  ;; char▮space → do completion
  ;; char ▮char → do indent
  (let ( ($syntax-state (syntax-ppss)))
    (if (or (nth 3 $syntax-state) (nth 4 $syntax-state))
        (xah-css-prettify-root-sexp)
      (if
          (and (looking-back "[-_a-zA-Z]" 1)
               (or (eobp) (looking-at "[\n[:blank:][:punct:]]")))
          (xah-css-complete-symbol)
        (xah-css-prettify-root-sexp)))))

(defun xah-css-prettify-root-sexp ()
  "Prettify format current root sexp group.
Root sexp group is the outmost sexp unit."
  (interactive)
  (save-excursion
    (let ($p1
          ;; $p2
          )
      (xah-css-goto-outmost-bracket)
      (setq $p1 (point))
      (scan-sexps $p1 1)
      ;; (setq $p2 (point))
      (progn
        (goto-char $p1)
        (indent-sexp)
        ;; (indent-region $p1 $p2)
        ;; (c-indent-region $p1 $p2)
        ))))

(defun xah-css-goto-outmost-bracket (&optional pos)
  "Move cursor to the beginning of outer-most bracket, with respect to pos.
Returns true if point is moved, else false."
  (interactive)
  (let (($i 0)
        ($p0 (if (number-or-marker-p pos)
                 pos
               (point))))
    (goto-char $p0)
    (while
        (and (< (setq $i (1+ $i)) 20)
             (not (eq (nth 0 (syntax-ppss (point))) 0)))
      (xah-css-up-list -1 "ESCAPE-STRINGS" "NO-SYNTAX-CROSSING"))
    (if (equal $p0 (point))
        nil
      t
      )))

(defun xah-css-up-list (arg1 &optional arg2 arg3)
  "Backward compatibility fix for emacs 24.4's `up-list'.
emacs 25.x changed `up-list' to take up to 3 args. Before, only 1."
  (interactive)
  (if (>= emacs-major-version 25)
      (up-list arg1 arg2 arg3)
    (up-list arg1)))


;; abbrev

(defun xah-css-abbrev-enable-function ()
  "Return t if not in string or comment. Else nil.
This is for abbrev table property `:enable-function'.
Version 2016-10-24"

  ;; (let (($syntax-state (syntax-ppss)))
  ;;     (not (or (nth 3 $syntax-state) (nth 4 $syntax-state))))
  t
  )

(defun xah-css-expand-abbrev ()
  "Expand the symbol before cursor,
if cursor is not in string or comment.
Returns the abbrev symbol if there's a expansion, else nil.
Version 2016-10-24"
  (interactive)
  (when (xah-css-abbrev-enable-function) ; abbrev property :enable-function doesn't seem to work, so check here instead
    (let (
          $p1 $p2
          $abrStr
          $abrSymbol
          )
      (save-excursion
        (forward-symbol -1)
        (setq $p1 (point))
        (forward-symbol 1)
        (setq $p2 (point)))
      (setq $abrStr (buffer-substring-no-properties $p1 $p2))
      (setq $abrSymbol (abbrev-symbol $abrStr))
      (if $abrSymbol
          (progn
            (abbrev-insert $abrSymbol $abrStr $p1 $p2 )
            (xah-css--abbrev-position-cursor $p1)
            $abrSymbol)
        nil))))

(defun xah-css--abbrev-position-cursor (&optional @pos)
  "Move cursor back to ▮ if exist, else put at end.
Return true if found, else false.
Version 2016-10-24"
  (interactive)
  (let (($found-p (search-backward "▮" (if @pos @pos (max (point-min) (- (point) 100))) t )))
    (when $found-p (forward-char ))
    $found-p
    ))

(defun xah-css--ahf ()
  "Abbrev hook function, used for `define-abbrev'.
 Our use is to prevent inserting the char that triggered expansion. Experimental.
 the “ahf” stand for abbrev hook function.
Version 2016-10-24"
  t)

(put 'xah-css--ahf 'no-self-insert t)

(define-abbrev-table 'xah-css-mode-abbrev-table
  '(

    ("b" "border" xah-css--ahf)
    ("bb" "border-bottom" xah-css--ahf)
    ("bbc" "border-bottom-color" xah-css--ahf)
    ("bbs" "border-bottom-style" xah-css--ahf)
    ("bbw" "border-bottom-width" xah-css--ahf)
    ("bc" "background-color" xah-css--ahf)
    ("bgc" "background-color" xah-css--ahf)
    ("bi" "background-image" xah-css--ahf)
    ("bl" "border-left" xah-css--ahf)
    ("blc" "border-left-color" xah-css--ahf)
    ("bls" "border-left-style" xah-css--ahf)
    ("blw" "border-left-width" xah-css--ahf)
    ("bpx" "background-position-x" xah-css--ahf)
    ("bpy" "background-position-y" xah-css--ahf)
    ("br" "border-radius:16px;" xah-css--ahf)
    ("brc" "border-right-color" xah-css--ahf)
    ("brs" "border-right-style" xah-css--ahf)
    ("brw" "border-right-width" xah-css--ahf)
    ("bs" "background-size" xah-css--ahf)
    ("bt" "border-top" xah-css--ahf)
    ("btc" "border-top-color" xah-css--ahf)
    ("bts" "border-top-style" xah-css--ahf)
    ("btw" "border-top-width" xah-css--ahf)
    ("c" "color" xah-css--ahf)
    ("d" "display" xah-css--ahf)
    ("ff" "font-family" xah-css--ahf)
    ("fl" "first-letter" xah-css--ahf)
    ("fs" "font-size" xah-css--ahf)
    ("fw" "font-weight" xah-css--ahf)
    ("h" "height" xah-css--ahf)
    ("lh" "line-height" xah-css--ahf)
    ("lst" "list-style-type" xah-css--ahf)
    ("m" "margin:16px;" xah-css--ahf)
    ("mb" "margin-bottom" xah-css--ahf)
    ("mh" "max-height" xah-css--ahf)
    ("ml" "margin-left" xah-css--ahf)
    ("mr" "margin-right" xah-css--ahf)
    ("mt" "margin-top" xah-css--ahf)
    ("mw" "max-width" xah-css--ahf)
    ("p" "position" xah-css--ahf)
    ("pb" "padding-bottom" xah-css--ahf)
    ("pd" "padding" xah-css--ahf)
    ("pl" "padding-left" xah-css--ahf)
    ("pr" "padding-right" xah-css--ahf)
    ("pt" "padding-top" xah-css--ahf)
    ("t" "top: 99px;" xah-css--ahf)
    ("ta" "text-align" xah-css--ahf)
    ("td" "text-decoration" xah-css--ahf)
    ("ts" "text-shadow" xah-css--ahf)
    ("v" "visibility" xah-css--ahf)
    ("va" "vertical-align" xah-css--ahf)
    ("w" "width" xah-css--ahf)
    ("ws" "white-space" xah-css--ahf)
    ("zi" "z-index" xah-css--ahf)

    ("background-color" "background-color:silver;" xah-css--ahf)
    ("background-image" "background-image:url(\"[url]\");" xah-css--ahf)
    ("background-position-x" "background-position-x:9px;" xah-css--ahf)
    ("background-position-y" "background-position-y:9px;" xah-css--ahf)
    ("background-size" "background-size:500px;" xah-css--ahf)
    ("border" "border:solid thin gray;" xah-css--ahf)
    ("border-bottom" "border-bottom:solid thin red;" xah-css--ahf)
    ("border-left" "border-left:solid thin blue;" xah-css--ahf)
    ("outline" "outline:solid thin gray;" xah-css--ahf)
    ("border-bottom-color" "border-bottom-color:blue;" xah-css--ahf)
    ("border-bottom-style" "border-bottom-style:none hidden dotted dashed solid double groove ridge inset outset inherit initial unset;" xah-css--ahf)
    ("border-bottom-width" "border-bottom-width:2px;" xah-css--ahf)
    ("border-left-color" "border-left-color:red;" xah-css--ahf)
    ("border-left-style" "border-left-style:none hidden dotted dashed solid double groove ridge inset outset inherit initial unset;" xah-css--ahf)
    ("border-left-width" "border-left-width:3px;" xah-css--ahf)
    ("border-radius" "border-radius:16px;" xah-css--ahf)
    ("border-right-color" "border-right-color:red;" xah-css--ahf)
    ("border-right-style" "border-right-style:3px;" xah-css--ahf)
    ("border-right-width" "border-right-width:3px;" xah-css--ahf)
    ("border-top-color" "border-top-color:red;" xah-css--ahf)
    ("border-top-style" "border-top-style:none hidden dotted dashed solid double groove ridge inset outset inherit initial unset;" xah-css--ahf)
    ("border-top-width" "border-top-width:3px;" xah-css--ahf)
    ("box-shadow" "box-shadow:3px 3px 4px 2px grey;" xah-css--ahf)
    ("clear" "clear:both left right none initial inherit;" xah-css--ahf)
    ("color" "color:red;" xah-css--ahf)
    ("cursor" "cursor:pointer;" xah-css--ahf)
    ("display" "display:inline-block;" xah-css--ahf)
    ("first-letter" "first-letter {font-size:30px;}" xah-css--ahf)
    ("float" "float:none left right initial inherit;" xah-css--ahf)
    ("font-family" "font-family:Arial, sans-serif;" xah-css--ahf)
    ("font-size" "font-size:30px;" xah-css--ahf)
    ("font-weight" "font-weight:bold;" xah-css--ahf)
    ("height" "height:200px;" xah-css--ahf)
    ("left" "left:99px;" xah-css--ahf)
    ("line-height" "line-height:1.5;" xah-css--ahf)
    ("list-style-type" "list-style-type:disc square circle decimal lower-roman upper-roman lower-alpha upper-alpha;" xah-css--ahf)
    ("margin" "margin:8px;" xah-css--ahf)
    ("margin-bottom" "margin-bottom:16px;" xah-css--ahf)
    ("margin-left" "margin-left:16px;" xah-css--ahf)
    ("margin-right" "margin-right:16px;" xah-css--ahf)
    ("margin-top" "margin-top:16px;" xah-css--ahf)
    ("max-height" "max-height:500px;" xah-css--ahf)
    ("max-width" "max-width:500px;" xah-css--ahf)
    ("opacity" "opacity:1;" xah-css--ahf)
    ("padding" "padding:8px;" xah-css--ahf)
    ("padding-bottom" "padding-bottom:16px;" xah-css--ahf)
    ("padding-left" "padding-left:16px;" xah-css--ahf)
    ("padding-right" "padding-right:16px;" xah-css--ahf)
    ("padding-top" "padding-top:16px;" xah-css--ahf)
    ("position" "position:static absolute fixed relative initial inherit;" xah-css--ahf)
    ("rgb" "rgb(▮)" xah-css--ahf)
    ("rgba" "rgba(▮)" xah-css--ahf)
    ("rotate" "rotate(▮9deg)" xah-css--ahf)
    ("rotate3d" "rotate3d(▮)" xah-css--ahf)
    ("rotateX" "rotateX(▮)" xah-css--ahf)
    ("rotateY" "rotateY(▮)" xah-css--ahf)
    ("rotateZ" "rotateZ(▮)" xah-css--ahf)
    ("scale" "scale(▮)" xah-css--ahf)
    ("scale3d" "scale3d(▮)" xah-css--ahf)
    ("scaleX" "scaleX(▮)" xah-css--ahf)
    ("scaleY" "scaleY(▮)" xah-css--ahf)
    ("scaleZ" "scaleZ(▮)" xah-css--ahf)
    ("skew" "skew(▮9deg)" xah-css--ahf)
    ("skewX" "skewX(▮)" xah-css--ahf)
    ("skewY" "skewY(▮)" xah-css--ahf)
    ("steps" "steps(▮)" xah-css--ahf)
    ("text-align" "text-align:left right center justify;" xah-css--ahf)
    ("text-decoration" "text-decoration:underline overline line-through none" xah-css--ahf)
    ("text-shadow" "text-shadow:3px 3px 3px grey" xah-css--ahf)
    ("top" "top:99px;" xah-css--ahf)
    ("translate" "translate(▮px,▮px)" xah-css--ahf)
    ("translate3d" "translate3d(▮)" xah-css--ahf)
    ("translateX" "translateX(▮)" xah-css--ahf)
    ("translateY" "translateY(▮)" xah-css--ahf)
    ("translateZ" "translateZ(▮)" xah-css--ahf)
    ("vertical-align" "vertical-align:top middle bottom baseline sub;" xah-css--ahf)
    ("visibility" "visibility:hidden visible;" xah-css--ahf)
    ("white-space" "white-space:pre-wrap" xah-css--ahf)
    ("width" "width:200px;" xah-css--ahf)
    ("z-index" "z-index:53475;" xah-css--ahf)

    ("media" "@media all and (min-width:1000px) {
▮
}

" xah-css--ahf)

    ;;
    )

  "abbrev table for `xah-css-mode'"
  )

(abbrev-table-put xah-css-mode-abbrev-table :case-fixed t)
(abbrev-table-put xah-css-mode-abbrev-table :system t)
(abbrev-table-put xah-css-mode-abbrev-table :enable-function 'xah-css-abbrev-enable-function)


;; keybinding

(defvar xah-css-mode-map nil "Keybinding for `xah-css-mode'")

(progn
  (setq xah-css-mode-map (make-sparse-keymap))
  (define-key xah-css-mode-map (kbd "TAB") 'xah-css-complete-or-indent)

  (define-key xah-css-mode-map (kbd "RET") 'xah-css-smart-newline)

  (define-prefix-command 'xah-css-mode-no-chord-map)

  ;; todo need to set these to also emacs's conventional major mode keys
  (define-key xah-css-mode-no-chord-map (kbd "r") 'xah-css-insert-random-color-hsl)
  (define-key xah-css-mode-no-chord-map (kbd "c") 'xah-css-hex-color-to-hsl)
  (define-key xah-css-mode-no-chord-map (kbd "p") 'xah-css-compact-css-region)
  (define-key xah-css-mode-no-chord-map (kbd ".") 'xah-css-compact-css-buffer)
  (define-key xah-css-mode-no-chord-map (kbd "e") 'xah-css-expand-to-multi-lines)
  (define-key xah-css-mode-no-chord-map (kbd "u") 'xah-css-complete-symbol)

  ;  (define-key xah-css-mode-map [remap comment-dwim] 'xah-css-comment-dwim)

  ;; define separate, so that user can override the lead key
  (define-key xah-css-mode-map (kbd "C-c C-c") xah-css-mode-no-chord-map))



;;;###autoload
(define-derived-mode xah-css-mode prog-mode "∑css"
  "A major mode for CSS.

URL `http://ergoemacs.org/emacs/xah-css-mode.html'

\\{xah-css-mode-map}"
  (setq font-lock-defaults '((xah-css-font-lock-keywords)))

  (setq-local comment-start "/*")
  (setq-local comment-start-skip "/\\*+[ \t]*")
  (setq-local comment-end "*/")
  (setq-local comment-end-skip "[ \t]*\\*+/")

  (make-local-variable 'abbrev-expand-function)
  (if (version< emacs-version "24.4")
      (add-hook 'abbrev-expand-functions 'xah-css-expand-abbrev nil t)
    (setq abbrev-expand-function 'xah-css-expand-abbrev))

  (abbrev-mode 1)

  :group 'xah-css-mode
  )

(add-to-list 'auto-mode-alist '("\\.css\\'" . xah-css-mode))

(provide 'xah-css-mode)

;;; xah-css-mode.el ends here

