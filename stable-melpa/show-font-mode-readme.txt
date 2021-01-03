; Display on modeline the low-level font picked by Emacs at point.
; Useful to debug issues with fontsets.
;
; The size of the font in pixels is shown before the font as
; width×height.  Notice that multiple monospace fonts won’t align
; unless they have the same width.  In custom-faces, you can fix
; this by adjusting the "height” property of the relevant face as a
; floating-point multiplier, until it matches the other fonts.
;
; This package also provides a colourful overlay to paint each font
; in the buffer in a different colour
; (‘show-font-mode-overlay’).  This feature is currently a bit
; buggy but it works to visualise font selection.  Use
; ‘show-font-mode-clear-overlay’ to undo.
