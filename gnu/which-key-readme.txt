Table of Contents
─────────────────

1. which-key
.. 1. Recent Changes
..... 1. 2021-06-21: Add support for menu-item bindings
..... 2. 2020-08-28: Added `which-key-add-keymap-based-replacements'
..... 3. 2019-08-01: Added `which-key-show-early-on-C-h'
..... 4. 2017-12-13: Added `which-key-enable-extended-define-key'
..... 5. 2017-11-13: Added `which-key-show-major-mode'
.. 2. Introduction
.. 3. Table of Contents                                          :TOC_3:
.. 4. Install
..... 1. MELPA
..... 2. Manually
.. 5. Initial Setup
..... 1. Side Window Bottom Option
..... 2. Side Window Right Option
..... 3. Side Window Right then Bottom
..... 4. Minibuffer Option
.. 6. Manual Activation
.. 7. Additional Commands
.. 8. Special Features and Configuration Options
..... 1. Popup Type Options
..... 2. Custom String Replacement Options
..... 3. Sorting Options
..... 4. Paging Options
..... 5. Face Customization Options
..... 6. Other Options
.. 9. Support for Third-Party Libraries
..... 1. Key-chord
..... 2. Evil operators
..... 3. God-mode
.. 10. More Examples
..... 1. Nice Display with Split Frame
.. 11. Known Issues
.. 12. Thanks


1 which-key
═══════════

  [https://elpa.gnu.org/packages/which-key.svg]
  [http://melpa.org/packages/which-key-badge.svg]
  [file:http://stable.melpa.org/packages/which-key-badge.svg]


[https://elpa.gnu.org/packages/which-key.svg]
<https://elpa.gnu.org/packages/which-key.html>

[http://melpa.org/packages/which-key-badge.svg]
<http://melpa.org/#/which-key>

[file:http://stable.melpa.org/packages/which-key-badge.svg]
<http://stable.melpa.org/#/which-key>

1.1 Recent Changes
──────────────────

1.1.1 2021-06-21: Add support for menu-item bindings
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  `which-key' will now detect and compute the result of `menu-item'
  bindings. As a consequence of reworking the internals,
  `which-key-enable-extended-define-key' is now obsolete (the associated
  behavior is supported by default).


1.1.2 2020-08-28: Added `which-key-add-keymap-based-replacements'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This function provides an alternative interface allowing replacements
  to be stored directly in keymaps, allowing one to avoid using
  `which-key-replacement-alist', which may cause performance issues when
  it gets very big.


1.1.3 2019-08-01: Added `which-key-show-early-on-C-h'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Allows one to trigger `which-key' on demand, rather than
  automatically. See the docstring and .


1.1.4 2017-12-13: Added `which-key-enable-extended-define-key'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Allows for a concise syntax to specify replacement text using
  `define-key' or alternatives that use `define-key' internally. See the
  docstring and .


1.1.5 2017-11-13: Added `which-key-show-major-mode'
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Shows active bindings in current major-mode map.


1.2 Introduction
────────────────

  `which-key' is a minor mode for Emacs that displays the key bindings
  following your currently entered incomplete command (a prefix) in a
  popup. For example, after enabling the minor mode if you enter `C-x'
  and wait for the default of 1 second the minibuffer will expand with
  all of the available key bindings that follow `C-x' (or as many as
  space allows given your settings).  This includes prefixes like `C-x
  8' which are shown in a different face. Screenshots of what the popup
  will look like are included below. `which-key' started as a rewrite of
  [guide-key-mode], but the feature sets have diverged to a certain
  extent.


[guide-key-mode] <https://github.com/kai2nenobu/guide-key>


1.3 Table of Contents                                            :TOC_3:
─────────────────────

  • 

    • 

      • 
      • 
      • 
      • 
      • 
    • 
    • 

      • 
      • 
    • 

      • 
      • 
      • 
      • 
    • 
    • 
    • 

      • 
      • 
      • 
      • 
      • 
      • 
    • 

      • 
      • 
      • 
    • 

      • 
    • 
    • 


1.4 Install
───────────

1.4.1 MELPA
╌╌╌╌╌╌╌╌╌╌╌

  After setting up [MELPA] as a repository, use `M-x package-install
  which-key' or your preferred method. You will need to call
  `which-key-mode' to enable the minor mode of course.


[MELPA] <http://melpa.org>


1.4.2 Manually
╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Add which-key.el to your `load-path' and require. Something like
  ┌────
  │ (add-to-list 'load-path "path/to/which-key.el")
  │ (require 'which-key)
  │ (which-key-mode)
  └────


1.5 Initial Setup
─────────────────

  No further setup is required if you are happy with the default
  setup. To try other options, there are 3 choices of default configs
  that are preconfigured (then customize to your liking). The main
  choice is where you want the which-key buffer to display. Screenshots
  of the default options are shown in the next sections.

  In each case, we show as many key bindings as we can fit in the buffer
  within the constraints. The constraints are determined by several
  factors, including your Emacs settings, the size of the current Emacs
  frame, and the which-key settings, most of which are described below.

  There are many substitution abilities included, which are quite
  flexible (ability to use regexp for example). This makes which-key
  very customizable.


1.5.1 Side Window Bottom Option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Popup side window on bottom. This is the current default. To restore
  this setup use

  ┌────
  │ (which-key-setup-side-window-bottom)
  └────

  <file:./img/which-key-bottom.png>


1.5.2 Side Window Right Option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Popup side window on right. For defaults use

  ┌────
  │ (which-key-setup-side-window-right)
  └────

  Note the defaults are fairly conservative and will tend to not display
  on narrower frames. If you get a message saying which-key can't
  display the keys, try making your frame wider or adjusting the
  defaults related to the maximum width (see `M-x customize-group
  which-key').

  <file:./img/which-key-right.png>


1.5.3 Side Window Right then Bottom
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  This is a combination of the previous two choices. It will try to use
  the right side, but if there is no room it will switch to using the
  bottom, which is usually easier to fit keys into. This setting can be
  helpful if the size of the Emacs frame changes frequently, which might
  be the case if you are using a dynamic/tiling window manager.

  ┌────
  │ (which-key-setup-side-window-right-bottom)
  └────


1.5.4 Minibuffer Option
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Take over the minibuffer. For the recommended configuration use

  ┌────
  │ (which-key-setup-minibuffer)
  └────

  <file:./img/which-key-minibuffer.png>

  Note the maximum height of the minibuffer is controlled through the
  built-in variable `max-mini-window-height'. Also, the paging commands
  do not work reliably with the minibuffer option. Use the side window
  on the bottom option if you need paging.


1.6 Manual Activation
─────────────────────

  If you only want the `which-key' popup when you need it, you can try a
  setup along the following lines

  ┌────
  │ ;; Allow C-h to trigger which-key before it is done automatically
  │ (setq which-key-show-early-on-C-h t)
  │ ;; make sure which-key doesn't show normally but refreshes quickly after it is
  │ ;; triggered.
  │ (setq which-key-idle-delay 10000)
  │ (setq which-key-idle-secondary-delay 0.05)
  │ (which-key-mode)
  └────

  This will prevent which-key from showing automatically, and allow you
  to use `C-h' in the middle of a key sequence to show the `which-key'
  buffer and keep it open for the remainder of the key sequence.


1.7 Additional Commands
───────────────────────

  • `which-key-show-top-level' will show most key bindings without a
    prefix. It is most and not all, because many are probably not
    interesting to most users.
  • `which-key-show-major-mode' will show the currently active
    major-mode bindings. It's similar to `C-h m' but in a which-key
    format. It is also aware of evil commands defined using
    `evil-define-key'.
  • `which-key-show-next-page-cycle' /
    `which-key-show-previous-page-cycle' will flip pages in a circle.
  • `which-key-show-next-page-no-cycle' /
    `which-key-show-previous-page-no-cycle' will flip pages and stop at
    first/last page.
  • `which-key-undo' can be used to undo the last keypress when in the
    middle of a key sequence.


1.8 Special Features and Configuration Options
──────────────────────────────────────────────

  There are more options than the ones described here. All of the
  configurable variables are available through `M-x customize-group
  which-key'.


1.8.1 Popup Type Options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  There are three different popup types that which-key can use by
  default to display the available keys. The variable
  `which-key-popup-type' decides which one is used.


◊ 1.8.1.1 minibuffer

  ┌────
  │ (setq which-key-popup-type 'minibuffer)
  └────
  Show keys in the minibuffer.


◊ 1.8.1.2 side window

  ┌────
  │ (setq which-key-popup-type 'side-window)
  └────
  Show keys in a side window. This popup type has further options:
  ┌────
  │ ;; location of which-key window. valid values: top, bottom, left, right,
  │ ;; or a list of any of the two. If it's a list, which-key will always try
  │ ;; the first location first. It will go to the second location if there is
  │ ;; not enough room to display any keys in the first location
  │ (setq which-key-side-window-location 'bottom)
  │ 
  │ ;; max width of which-key window, when displayed at left or right.
  │ ;; valid values: number of columns (integer), or percentage out of current
  │ ;; frame's width (float larger than 0 and smaller than 1)
  │ (setq which-key-side-window-max-width 0.33)
  │ 
  │ ;; max height of which-key window, when displayed at top or bottom.
  │ ;; valid values: number of lines (integer), or percentage out of current
  │ ;; frame's height (float larger than 0 and smaller than 1)
  │ (setq which-key-side-window-max-height 0.25)
  └────


◊ 1.8.1.3 frame

  ┌────
  │ (setq which-key-popup-type 'frame)
  └────
  Show keys in a popup frame. This popup won't work very well in a
  terminal, where only one frame can be shown at any given moment. This
  popup type has further options:
  ┌────
  │ ;; max width of which-key frame: number of columns (an integer)
  │ (setq which-key-frame-max-width 60)
  │ 
  │ ;; max height of which-key frame: number of lines (an integer)
  │ (setq which-key-frame-max-height 20)
  └────


◊ 1.8.1.4 custom

  Write your own display functions! This requires you to write three
  functions, `which-key-custom-popup-max-dimensions-function',
  `which-key-custom-show-popup-function', and
  `which-key-custom-hide-popup-function'. Refer to the documentation for
  those variables for more information, but here is a working example
  (this is the current implementation of side-window bottom).


  ┌────
  │ (setq which-key-popup-type 'custom)
  │ (defun which-key-custom-popup-max-dimensions-function (ignore)
  │   (cons
  │    (which-key-height-or-percentage-to-height
  │     which-key-side-window-max-height)
  │    (frame-width)))
  │ (defun fit-horizonatally ()
  │   (let ((fit-window-to-buffer-horizontally t))
  │     (fit-window-to-buffer)))
  │ (defun which-key-custom-show-popup-function (act-popup-dim)
  │   (let* ((alist '((window-width . fit-horizontally)
  │ 		  (window-height . fit-window-to-buffer))))
  │     (if (get-buffer-window which-key--buffer)
  │ 	(display-buffer-reuse-window which-key--buffer alist)
  │       (display-buffer-in-major-side-window which-key--buffer
  │ 					   'bottom 0 alist))))
  │ (defun which-key-custom-hide-popup-function ()
  │   (when (buffer-live-p which-key--buffer)
  │     (quit-windows-on which-key--buffer)))
  └────


1.8.2 Custom String Replacement Options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  You can customize the way the keys show in the buffer using three
  different replacement methods. The first, keymap-based replacement, is
  preferred and will take precedence over the others. The remaining
  methods are still available, because they pre-date the first and are
  more flexible in what they can accomplish.


◊ 1.8.2.1 Keymap-based replacement

  Using this method, which-key can display a custom string for a key
  definition in some keymap. There are two ways to define a keymap-based
  replacement. The preferred way is to use `define-key' (or a command
  that uses `define-key' internally) with a cons cell as the
  definition. For example,

  ┌────
  │ (define-key some-map "f" '("foo" . command-foo))
  │ (define-key some-map "b" '("bar-prefix" . (keymap)))
  └────

  binds `command-foo' to `f' in `some-map', but also stores the string
  "foo" which which-key will extract to use to describe this
  command. The second example binds an empty keymap to `b' in `some-map'
  and uses "bar-prefix" to describe it. These bindings are accepted by
  `define-key' natively (i.e., with or without which-key being
  loaded). Since many key-binding utilities use `define-key' internally,
  this functionality should be available with your favorite method of
  defining keys as well.

  The second method is to use
  `which-key-add-keymap-based-replacements'. The statement

  ┌────
  │ (define-key some-map "f" 'long-command-name-foo)
  │ (define-key some-map "b" some-prefix-map)
  │ (which-key-add-keymap-based-replacements some-map
  │   "f" '("foo" . long-command-name-foo)
  │   "b" '("bar-prefix" . (keymap)))
  └────

  uses `define-key' to add two bindings and tells which-key to use the
  string "foo" in place of "command-foo" and the string "bar-prefix" for
  an empty prefix map. `which-key-add-keymap-based-replacements' just
  uses `define-key' to bind (or rebind) the command.

  There are other methods of telling which-key to replace command names,
  which are described next. The keymap-based replacements should be the
  most performant since they use built-in functionality of
  emacs. However, the alternatives can be more flexible in telling
  which-key how and when to replace text. They can be used
  simultaneously, but which-key will give precedence to the keymap-based
  replacement when it exists.


◊ 1.8.2.2 Key-Based replacement

  Using this method, the description of a key is replaced using a string
  that you provide. Here's an example

  ┌────
  │ (which-key-add-key-based-replacements
  │   "C-x C-f" "find files")
  └────

  where the first string is the key combination whose description you
  want to replace, in a form suitable for `kbd'. For that key
  combination, which-key overwrites the description with the second
  string, "find files". In the second type of entry you can restrict the
  replacements to a major-mode. For example,

  ┌────
  │ (which-key-add-major-mode-key-based-replacements 'org-mode
  │   "C-c C-c" "Org C-c C-c"
  │   "C-c C-a" "Org Attach")
  └────

  Here the first entry is the major-mode followed by a list of the first
  type of entries. In case the same key combination is listed under a
  major-mode and by itself, the major-mode version takes precedence.


◊ 1.8.2.3 Key and Description replacement

  The second and third methods target the text used for the keys and the
  descriptions directly. The relevant variable is
  `which-key-replacement-alist'.  Here's an example of one of the
  default key replacements

  ┌────
  │ (push '(("<\\([[:alnum:]-]+\\)>" . nil) . ("\\1" . nil))
  │       which-key-replacement-alist)
  └────

  Each element of the outer cons cell is a cons cell of the form `(KEY
       . BINDING)'. The `car' of the outer cons determines how to match
       key bindings while the `cdr' determines how those matches are
       replaced. See the docstring of `which-key-replacement-alist' for
       more information.

  The next example shows how to replace the description.

  ┌────
  │ (push '((nil . "left") . (nil . "lft")) which-key-replacement-alist)
  └────

  Here is an example of using key replacement to include Unicode
  characters in the results. Unfortunately, using Unicode characters may
  upset the alignment of the which-key buffer, because Unicode
  characters can have different widths even in a monospace font and
  alignment is based on character width.

  ┌────
  │ (add-to-list 'which-key-replacement-alist '(("TAB" . nil) . ("↹" . nil)))
  │ (add-to-list 'which-key-replacement-alist '(("RET" . nil) . ("⏎" . nil)))
  │ (add-to-list 'which-key-replacement-alist '(("DEL" . nil) . ("⇤" . nil)))
  │ (add-to-list 'which-key-replacement-alist '(("SPC" . nil) . ("␣" . nil)))
  └────

  The `cdr' may also be a function that receives a `cons' of the form
       `(KEY . BINDING)' and produces a `cons' of the same form. This
       allows for interesting ideas like this one suggested by
       [@pdcawley] in [PR #147].

  ┌────
  │ (push (cons '(nil . "paredit-mode")
  │ 	    (lambda (kb)
  │ 	      (cons (car kb)
  │ 		    (if paredit-mode
  │ 			"[x] paredit-mode"
  │ 		      "[ ] paredit-mode"))))
  │       which-key-replacement-alist)
  └────

  The box will be checked if `paredit-mode' is currently active.


  [@pdcawley] <https://github.com/pdcawley>

  [PR #147] <https://github.com/justbur/emacs-which-key/pull/147>


1.8.3 Sorting Options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  By default the output is sorted by the key in a custom order. The
  default order is to sort lexicographically within each "class" of key,
  where the classes and their order are

  `Special (SPC, TAB, ...) < Single Character (ASCII) (a, ...) <
  Modifier (C-, M-, ...) < Other'

  You can control the order by setting this variable. This also shows
  the other available options.

  ┌────
  │ ;; default
  │ (setq which-key-sort-order 'which-key-key-order)
  │ ;; same as default, except single characters are sorted alphabetically
  │ ;; (setq which-key-sort-order 'which-key-key-order-alpha)
  │ ;; same as default, except all prefix keys are grouped together at the end
  │ ;; (setq which-key-sort-order 'which-key-prefix-then-key-order)
  │ ;; same as default, except all keys from local maps shown first
  │ ;; (setq which-key-sort-order 'which-key-local-then-key-order)
  │ ;; sort based on the key description ignoring case
  │ ;; (setq which-key-sort-order 'which-key-description-order)
  └────


1.8.4 Paging Options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  There are at least several prefixes that have many keys bound to them,
  like `C-x'. which-key displays as many keys as it can given your
  settings, but for these prefixes this may not be enough. The paging
  feature gives you the ability to bind a key to the function
  `which-key-C-h-dispatch' which will allow you to cycle through the
  pages without changing the key sequence you were in the middle of
  typing. There are two slightly different ways of doing this.


◊ 1.8.4.1 Method 1 (default): Using C-h (or `help-char')

  This is the easiest way, and is turned on by default. Use
  ┌────
  │ (setq which-key-use-C-h-commands nil)
  └────
  to disable the behavior (this will only take effect after toggling
  which-key-mode if it is already enabled). `C-h' can be used with any
  prefix to switch pages when there are multiple pages of keys. This
  changes the default behavior of Emacs which is to show a list of key
  bindings that apply to a prefix.  For example, if you were to type
  `C-x C-h' you would get a list of commands that follow `C-x'. This
  uses which-key instead to show those keys, and unlike the Emacs
  default saves the incomplete prefix that you just entered so that the
  next keystroke can complete the command.

  The commands are:
  • Cycle through the pages forward with `n' (or `C-n')
  • Cycle backwards with `p' (or `C-p')
  • Undo the last entered key (!) with `u' (or `C-u')
  • Call the default command bound to `C-h', usually
    `describe-prefix-bindings', with `h' (or `C-h')

  This is especially useful for those who like `helm-descbinds' but also
  want to use `C-h' as their which-key paging key.

  Note `C-h' is by default equivalent to `?' in this context.

  Note also that using `C-h' will not work with the `C-h' prefix, unless
  you make further adjustments. See Issues [#93] and [#175] for example.


  [#93] <https://github.com/justbur/emacs-which-key/issues/93>

  [#175] <https://github.com/justbur/emacs-which-key/issues/175>


◊ 1.8.4.2 Method 2: Bind your own keys

  Essentially, all you need to do for a prefix like `C-x' is the
  following which will bind `<f5>' to the relevant command.

  ┌────
  │ (define-key which-key-mode-map (kbd "C-x <f5>") 'which-key-C-h-dispatch)
  └────

  This is completely equivalent to

  ┌────
  │ (setq which-key-paging-prefixes '("C-x"))
  │ (setq which-key-paging-key "<f5>")
  └────

  where the latter are provided for convenience if you have a lot of
  prefixes.


1.8.5 Face Customization Options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The faces that which-key uses are
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Face                                    Applied To                     Default Definition                                          
  ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   `which-key-key-face'                    Every key sequence             `:inherit font-lock-constant-face'                          
   `which-key-separator-face'              The separator (→)              `:inherit font-lock-comment-face'                           
   `which-key-note-face'                   Hints and notes                `:inherit which-key-separator-face'                         
   `which-key-special-key-face'            User-defined special keys      `:inherit which-key-key-face :inverse-video t :weight bold' 
   `which-key-group-description-face'      Command groups (i.e, keymaps)  `:inherit font-lock-keyword-face'                           
   `which-key-command-description-face'    Commands not in local-map      `:inherit font-lock-function-name-face'                     
   `which-key-local-map-description-face'  Commands in local-map          `:inherit which-key-command-description-face'               
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  The last two deserve some explanation. A command lives in one of many
  possible keymaps. You can distinguish between local maps, which depend
  on the buffer you are in, which modes are active, etc., and the global
  map which applies everywhere. It might be useful for you to
  distinguish between the two. One way to do this is to remove the
  default face from `which-key-command-description-face' like this

  ┌────
  │ (set-face-attribute 'which-key-command-description-face nil :inherit nil)
  └────

  another is to make the local map keys appear in bold

  ┌────
  │ (set-face-attribute 'which-key-local-map-description-face nil :weight 'bold)
  └────

  You can also use `M-x customize-face' to customize any of the above
  faces to your liking.


1.8.6 Other Options
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  The options below are also available through customize. Their defaults
  are shown.

  ┌────
  │ ;; Set the time delay (in seconds) for the which-key popup to appear. A value of
  │ ;; zero might cause issues so a non-zero value is recommended.
  │ (setq which-key-idle-delay 1.0)
  │ 
  │ ;; Set the maximum length (in characters) for key descriptions (commands or
  │ ;; prefixes). Descriptions that are longer are truncated and have ".." added.
  │ (setq which-key-max-description-length 27)
  │ 
  │ ;; Use additional padding between columns of keys. This variable specifies the
  │ ;; number of spaces to add to the left of each column.
  │ (setq which-key-add-column-padding 0)
  │ 
  │ ;; The maximum number of columns to display in the which-key buffer. nil means
  │ ;; don't impose a maximum.
  │ (setq which-key-max-display-columns nil)
  │ 
  │ ;; Set the separator used between keys and descriptions. Change this setting to
  │ ;; an ASCII character if your font does not show the default arrow. The second
  │ ;; setting here allows for extra padding for Unicode characters. which-key uses
  │ ;; characters as a means of width measurement, so wide Unicode characters can
  │ ;; throw off the calculation.
  │ (setq which-key-separator " → " )
  │ (setq which-key-unicode-correction 3)
  │ 
  │ ;; Set the prefix string that will be inserted in front of prefix commands
  │ ;; (i.e., commands that represent a sub-map).
  │ (setq which-key-prefix-prefix "+" )
  │ 
  │ ;; Set the special keys. These are automatically truncated to one character and
  │ ;; have which-key-special-key-face applied. Disabled by default. An example
  │ ;; setting is
  │ ;; (setq which-key-special-keys '("SPC" "TAB" "RET" "ESC" "DEL"))
  │ (setq which-key-special-keys nil)
  │ 
  │ ;; Show the key prefix on the left, top, or bottom (nil means hide the prefix).
  │ ;; The prefix consists of the keys you have typed so far. which-key also shows
  │ ;; the page information along with the prefix.
  │ (setq which-key-show-prefix 'left)
  │ 
  │ ;; Set to t to show the count of keys shown vs. total keys in the mode line.
  │ (setq which-key-show-remaining-keys nil)
  └────


1.9 Support for Third-Party Libraries
─────────────────────────────────────

  Some support is provided for third-party libraries which don't use
  standard methods of looking up commands. Some of these need to be
  enabled explicitly. This code includes some hacks, so please report
  any problems.


1.9.1 Key-chord
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Enabled by default.


1.9.2 Evil operators
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Evil motions and text objects following an operator like `d' are not
  all looked up in a standard way. Support is controlled through
  `which-key-allow-evil-operators' which should be non-nil if evil is
  loaded before which-key and through
  `which-key-show-operator-state-maps' which needs to be enabled
  explicitly because it is more of a hack. The former allows for the
  inner and outer text object maps to show, while the latter shows
  motions as well.


1.9.3 God-mode
╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Call `(which-key-enable-god-mode-support)' after loading god-mode to
  enable support for god-mode key sequences. This is new and
  experimental, so please report any issues.


1.10 More Examples
──────────────────

1.10.1 Nice Display with Split Frame
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Unlike guide-key, which-key looks good even if the frame is split into
  several windows.
  <file:./img/which-key-right-split.png>

  <file:./img/which-key-bottom-split.png>


1.11 Known Issues
─────────────────

  • A few users have reported crashes related to which-key popups when
    quitting a key sequence with `C-g'. A possible fix is discussed in
    [this issue].


[this issue] <https://github.com/justbur/emacs-which-key/issues/130>


1.12 Thanks
───────────

  Special thanks to
  • [@bmag] for helping with the initial development and finding many
    bugs.
  • [@iqbalansari] who among other things adapted the code to make
    `which-key-show-top-level' possible.


[@bmag] <https://github.com/bmag>

[@iqbalansari] <https://github/iqbalansari>
