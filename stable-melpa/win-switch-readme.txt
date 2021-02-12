
 If you use multiple windows in an Emacs frame, you may find yourself
 moving through the window configuration using `other-window' (C-x o)
 again and again. Because the order of windows in the window list
 need not relate intuitively to windows' positions, moving
 efficiently can require context-specific prefix arguments along the
 way. The tiring outcome is that navigation through a complex window
 configuration demands many keystrokes and nontrivial attention.
 This package is designed to solve that problem.

 While the `windmove' package provides functions for moving
 intuitively among windows, the natural key bindings for these
 functions (e.g., the arrow keys with some modifier) require a
 distant and thus inefficient hand movement. Moreover, one often
 wants to mix a variety of window-based operations (other-window,
 previous-window, directional movement, resizing) in rapid
 succession.

 This package builds on the windmove functionality by defining a
 command `win-switch-dispatch' that engages a dynamic, transient
 keyboard override, allowing one to efficiently move among defined
 windows (and frames) -- and even resize, split, delete them -- with
 minimal fuss and effort. When the override is engaged, the movement
 and resizing commands are bound to simple keys that can be pressed
 quickly with one hand. The override ends either when the user exits
 explicitly or after a configurable idle time threshold. The happy
 outcome is fast and seamless navigation.

 To use the package, execute the following code either directly
 or in your .emacs file:

     (require 'win-switch)
     (global-set-key "\C-xo" 'win-switch-dispatch)

 or use whatever keybinding you ordinarily have set to `other-window'.
 Alternatively, you can use one of a variety of predefined configuration
 commands, as in

     (require 'win-switch)
     (win-switch-setup-keys-ijkl "\C-xo")

 which has the same effect as the above.

 Now, when executing a window switch (i.e., hitting C-xo), Emacs enters
 window switching mode, which lasts until either the user exits the
 mode or the idle time exceeds the threshold `win-switch-idle-time'.
 During this override, selected keys move among windows (or frames)
 or resize the windows. The following keys are bound by default:

   + i select the window above the current window.
   + k select the window below the current window.
   + j select the window left of the current window.
   + l select the window right of the current window.
   + o cycle forward through the window list in the current frame.
   + p cycle backward through the window list in the current frame.
   + SPACE cycles among existing frames.
   + u (and RETURN) exit window switching mode.
   + I and K vertically enlarge and shrink the current window, respectively.
   + L and J horizontally enlarge and shrink the current window, respectively.
   + h and ; split the current window, horizontally and vertically, respectively.
   + ESCAPE acts as an "emergency" exit

 All other keys exit window switching mode and execute their original function.

 By default, window selection wraps around when moving across a frame
 edge and window switching mode is forgone when there are only two
 windows. But these features, the key bindings, and other parameters
 can all be customized, either with the customization facility or
 with defvar and setter functions.

 The default keybindings are designed for fast and intuitve,
 one-handed operation, but if desired the key bindings can be easily
 adjusted or reset. Several alternative key configurations are pre-defined
 (see `win-switch-setup-keys-ijkl', `win-switch-setup-keys-arrow-ctrl',
 `win-switch-setup-keys-arrow-meta', and `win-switch-setup-keys-esdf'
 below). The keys also can be rebound in groups via the variables
 `win-switch-<name>-keys' where <name> can be one of up, down, left,
 right, next-window, previous-window, enlarge-vertically,
 shrink-vertically, enlarge-horizontally, shrink-horizontally,
 other-frame, exit, split-vertically, split-horizontally, delete-window,
 or emergency-exit. These variables should not be set directly,
 but rather should be set either by customize or by
 using the functions `win-switch-add-key', `win-switch-delete-key',
 and `win-switch-set-keys'. For example:

   (win-switch-add-key    "O" 'previous-window)
   (win-switch-delete-key "p" 'previous-window)
   (win-switch-set-keys   '(" " "," "m") 'other-frame)

 Note that the last arguments here are win-switch commands not elisp
 functions. (Note also that the emergency-exit keys do a hard exit in
 case of an unexpected error in user-defined code such as in
 customized feedback functions. This command may be removed in future
 versions.) At least one exit key must always be defined. Revised
 bindings can be set in in the hook `win-switch-load-hook' before
 loading the package. (Also see `win-switch-define-key' for setting
 general commands in the win-switch keymap, and
 `win-switch-set-once-key' for setting commands in the once only
 keymap used by `win-switch-dispatch-once'.)

 Besides key bindings, the most important customization options are
 the following:

   + `win-switch-idle-time'
   + `win-switch-window-threshold'
   + `win-switch-other-window-first'
   + `win-switch-wrap-around'  (set via `win-switch-set-wrap-around')

 The idle time should be set so that one does not have to either rush
 or wait. (While explicit exit always works, it is nice to have
 window-switching mode end on its own at just the right time.) This
 may require some personalized fiddling to find a comfortable value,
 though the default should be pretty good. The window-threshold and
 other-window-first control when and if window switching mode is
 entered. And wrap-around determines if moving across the edge of the
 frame wraps around to the window on the other side.

 The other customizable parameters are as follows:

   + `win-switch-provide-visual-feedback'
   + `win-switch-feedback-background-color'
   + `win-switch-feedback-foreground-color'
   + `win-switch-on-feedback-function'
   + `win-switch-off-feedback-function'
   + `win-switch-other-window-function'

 The feedback mechanisms are intended to make it salient when
 window switching mode is on or off and can be customized at
 several scales. The other-window-function replaces `other-window'
 for moving between window; the primary motivation is to allow
 `icicle-other-window-or-frame' under icicles.

 And four hooks can be set as well:

   + `win-switch-load-hook'
   + `win-switch-on-hook'
   + `win-switch-off-hook'
   + `win-switch-abort-hook'

 The following functions are used to set options:

   + `win-switch-set-wrap-around'
   + `win-switch-add-key'
   + `win-switch-delete-key'
   + `win-switch-set-keys'

 There are three main entry points for using this functionality

   + `win-switch-dispatch' (alias `win-switch-mode')
   + `win-switch-dispatch-once'
   + `win-switch-dispatch-with'

 The first is the main function, the second is a prefix command that
 gives one switch only but allows easy maneuvering in up to five
 windows with a single keystroke. (The `once' keys can be set using
 the `win-switch-set-once-keys' command.) The last constructs
 commands for keybindings that dispatch after some other command.
 (See `win-switch-setup-keys-arrow' for a nice example of its use.)

 NOTE: win-switch is not a formal major or minor mode, more of an
       overriding mode. This started as a way to explore dynamic
       keybindings, an idea that is generalized considerably in
       my packages `quick-nav' and `power-keys'. The latter
       introduces some programming abstractions that can be used
       to easily install dynamic keymaps of several flavors.
       I plan to use the `power-keys' mechanisms for this package
       in a later version.

Code Contents
  1. (@> "User-Configurable Parameters")
  2. (@> "User-Configurable Key Bindings")
  3. (@> "Preventing Default Shadowing")
  4. (@> "Internal Configuration Data")
  5. (@> "Internal Functions and Macros")
  6. (@> "Actions and Key Commands")
  7. (@> "Customization Initializers and Option Setters")
  8. (@> "User Entry Points")
  9. (@> "Pre-defined Configurations")
