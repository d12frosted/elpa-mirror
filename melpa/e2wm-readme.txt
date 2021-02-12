This is an demonstration implementation of introducing window management to Emacs.
* Management of list of editable buffers
* Assignment of windows for pop-up buffers
* Switching window layout like the perspective in eclipse
* Plug-in extension

The current implementation has following perspectives:
* code      : main coding layout
* two       : side by side layout
* doc       : reading documentation layout
* dashboard : showing plug-ins like dashboard in Mac OSX
* array     : selecting buffers like expose in Mac OSX

; Installation:

(1) Put e2wm.el and window-layout.el in load-path.
(2) Put the following code in your .emacs file,
   (require 'e2wm)
(3) M-x e2wm:start-management to start e2wm.
To stop e2wm, M-x e2wm:stop-management or [C-c ; Q].


; Customization

* Layout recipe (`e2wm:c-PST-NAME-recipe'):

Layout recipe RECIPE (e.g., `e2wm:c-code-recipe') is a recursive
tree-like structure defined as follows:

(SPLIT-TYPE [SPLIT-OPTION]
            WINDOW-or-RECIPE    ; left or upper side
            WINDOW-or-RECIPE)   ; right or lower side

WINDOW is a name (symbol) of the window. This is used in the
`:name' property of the window information list (winfo, see the
next section).

Split types (SPLIT-TYPE):

  - : split vertically
  | : split horizontally

Split option list SPLIT-OPTION is a plist with the following
properties. (the prefix 'left' can be replaced by 'right', 'upper'
and 'lower'.):

  :left-size        : (column or row number) window size
  :left-max-size    : (column or row number) if window size is larger
                    : than this value, the window is shrunken.
  :left-size-ratio  : (0.0 - 1.0) window size ratio. the size of
                    : the other side is the rest.

Note:
The split option can be omitted.
The size parameters, :size, :max-size and :size-ratio, are mutually
exclusive.  The size of a window is related with one of the other
side window. So, if both side windows set size parameters, the
window size may not be adjusted as you write.

* Window information  (`e2wm:c-PST-NAME-winfo'):

Window information (e.g., `e2wm:c-code-winfo') is a list of window
options (plist).  Besides the options defined in window-layout.el,
`:name' (mandatory), `:buffer', `:default-hide' and `:fix-size',
e2wm has additional options.

  :name      [*] : the window name.
  :buffer        : A buffer name or a buffer object to show the window.
                 : If nil or omitted, the current buffer remains.
  :default-hide  : If t, the window is hided initially.
                 : (type: t or nil, default: nil)
  :fix-size      : If t, when the windows are laid out again, the
                 : window size is remained.
                 : (type: t or nil, default: nil)
  :plugin        : Plug-in name.
                 : (type: symbol)
  :plugin-args   : Arguments for the plug-in.  See each plug-in
                 : documentation for use of this option.
                 : (type: any lisp objecct)

; Development memo:

See readme for further documentation.

** Side effects

* advice
 - buffer系
    switch-to-buffer, pop-to-buffer
 - window-configuration系
    current-window-configuration
    window-configuration-frame
    compare-window-configurations
    set-window-configuration
    window-configuration-p
* hook
    kill-buffer-hook
    window-configuration-change-hook
    completion-setup-hook
    after-save-hook
* override variable
    special-display-function

** Local words
pst     : Perspective
e2wm:c- : Configuration variables
e2wm:$  : Structure functions

** Source code layout

Configurations  / e2wm:c-
Fundamental functions
Buffer history management / e2wm:history-
Framework for perspectives / e2wm:pst-
Framework for perspective set / e2wm:pstset-
Advices and hooks (switch-to-buffer, pop-to-buffer and so on)
Framework for plug-ins / e2wm:plugin-
Menu definition / e2wm:menu-
Plug-in definitions / e2wm:def-plugin-
Perspective definitions / e2wm:dp-
  code  / e2wm:dp-code-
  doc   / e2wm:dp-doc-
  two   / e2wm:dp-two-
  dashboard / e2wm:dp-dashboard-
  array / e2wm:dp-array-
Start-up and exit e2wm
