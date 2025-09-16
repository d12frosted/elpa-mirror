                          ━━━━━━━━━━━━━━━━━━━━
                           STANDARD-KEYS-MODE
                          ━━━━━━━━━━━━━━━━━━━━





1 Introduction
══════════════

  standard-keys-mode is yet another CUA-like mode that aims to emulate
  the standard and common keybindings found in many modern editors.


1.1 Motivation
──────────────

  Using Emacs is often difficult, and configuring its shortcuts tedious,
  within the Emacs ecosystem there have been packages that tried to
  change these shortcuts to ones easier to use and more common in modern
  times.  However, over time, many are becoming obsolete, are often not
  easy to configure or do not work in current versions of Emacs.

  My frustration, and seeing how there are more modal-editing packages
  than modifier-based ones, motivated me to create `standard-keys-mode'.

  This packages aims to: help *newcomers* to use Emacs while keeping
  familiar keybinding; help those who want to make a *gradual
  adaptation* to Emacs; or be used *only to remap* some key prefixes.

  For those who already use Emacs, this package can be considered /the/
  [meow] /or/ [ryo] /of modifier-based shortcuts/, providing the
  following features inspired by these packages:

  ⁃ Ready to use.  /No need to make so much configurations./

  ⁃ Easy to use.  /You can use the common keys you mostly know./

  ⁃ Minimal but easy to extend.  /No dependencies needed, allowing
    creating your own modifier-based environment./

  ⁃ Provide new editing commands that are not available in Emacs.

  ⁃ Compatible with Emacs Ecosystem.  /The keybindings will remain
    compatible with the vanilla Emacs and third-party packages keymaps,/
    /without the need to modify them or reinvent the wheel./


[meow] <https://github.com/meow-edit/meow>

[ryo] <https://github.com/Kungsgeten/ryo-modal>


2 [Get started]
═══════════════

  For install and use `standard-keys-mode', see the [GET_STARTED.org]
  file, which additionally provides a simple and documented template
  configuration with several tips to help you get started with Emacs and
  standard-keys easily.


[Get started] <file:GET_STARTED.org>

[GET_STARTED.org] <file:GET_STARTED.org>


3 Configuration
═══════════════

3.1 Keybindings
───────────────

  `standard-keys-mode' comes with additional ready-to-use keymaps themes
  based on other editors, keyboards, and Emacs packages.

  For more information about the keymaps you can see the following
  files:

  ⁃ [KEYMAP_THEMES_LIST.org] Complete list of included keymap themes and
    their shortcuts.

  ⁃ [CONFIGURING_KEYMAPS.org] Guide to configure the keymap themes and
    their shortcuts, and creating your own keymap.

  standard-keys uses the following shortcuts by default (defined in
  `standard-keys-default-keymap'):

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   key                         command                                                                          
  ──────────────────────────────────────────────────────────────────────────────────────────────────────────────
   `Control' `o'               `find-file' (Open file)                                                          
   `Control' `Shift' `o'       `revert-buffer' (Refresh/Update current buffer file state)                       
   `Control' `w'               `kill-current-buffer' (Quit/Kill current buffer)                                 
   `Control' `q'               `save-buffers-kill-terminal' (Quit Emacs)                                        
   `Control' `e'               `C-x' prefix                                                                     
   `Control' `d'               `C-c' prefix                                                                     
   `Control' `x'               `kill-region' (Cut)                                                              
   `Control' `c'               `kill-ring-save' (Copy)                                                          
   `Control' `v'               `yank' (Paste)                                                                   
   `Control' `z'               `undo'                                                                           
   `Control' `y'               `undo-redo' (Redo)                                                               
   `Control' `Shift' `z'       `undo-redo' (Redo)                                                               
   `Control' `f'               `isearch-forward'  (Search forward)                                              
   `Control' `Shift' `f'       `isearch-backward' (Search backward)                                             
   `Control' `r'               `query-replace' (Replace)                                                        
   `Control' `Shift' `r'       `query-replace-regexp' (Replace with regexp)                                     
   `Control' `s'               `save-buffer' (Save buffer/file)                                                 
   `Control' `Shift' `s'       `write-file' (Save buffer/file as)                                               
   `Control' `p'               `print-buffer' (Print buffer/file)                                               
   `Control' `a'               `mark-whole-buffer' (Select All)                                                 
   `Control' `+'               `text-scale-increase' (Zoom in)                                                  
   `Control' `-'               `text-scale-decrease' (Zoom out)                                                 
   `Control' `='               `text-scale-adjust' (Set Zoom)                                                   
   `Control' `n'               `standard-keys-create-new-buffer' (Create a new empty buffer)                    
   `Control' `;'               `comment-line' (Comment out current line)                                        
   `Alt/Meta' `1'              `delete-other-windows'                                                           
   `Alt/Meta' `2'              `split-window-below'                                                             
   `Alt/Meta' `3'              `split-window-right'                                                             
   `Control' `RETURN'          `rectangle-mark-mode' (Select in rectangle mode)                                 
   `Control' `Shift' `RETURN'  `standard-keys-newline-and-indent-before-point' (Insert a newline before cursor) 
   `Control' `b'               `switch-to-buffer'                                                               
   `HOME'                      `standard-keys-move-beginning-of-line-or-indentation'                            
   `ESC'                       `standard-keys-keyboard-quit' (Cancel current action, similar to C-g)            
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


[KEYMAP_THEMES_LIST.org] <file:KEYMAP_THEMES_LIST.org>

[CONFIGURING_KEYMAPS.org] <file:CONFIGURING_KEYMAPS.org>


3.2 User options
────────────────

  ⁃ `standard-keys-update-commands-descriptions'

    If non-nil, commands docstring descriptions should use the remaped
    `C-x' and `C-c'.

    This only have effect if
    `standard-keys-update-commands-descriptions' is non-nil.

    default: `t'

  ⁃ `standard-keys-override-new-C-x-and-C-c-commands'

    If non-nil, commands bounds in `C-x' and `C-c' must take precedence
    over other keymaps.

    *WARNING:* Enabling this may override some terminal specific
    keybindings and only should be used only for override the `C-x' and
    `C-c' only in buffers or modes which take precedence over
    `standard-keys-map'.

    Intended to be used for copy/cut text in magit buffers or in URLs
    with `goto-address-mode' enabled.

    default: `nil'

  ⁃ `standard-keys-map-style'

    The keymap style to use.

    Use this option to change the default keymap to use.

    default: `'standard-keys-default-keymap'


4 Troubleshooting
═════════════════

4.1 The copy and cut commands (C-c, C-x) doesn't work well in magit or with goto-address-mode.
──────────────────────────────────────────────────────────────────────────────────────────────

  This is a common bug, `standard-keys-mode' provides the variable
  `standard-keys-override-C-x-and-C-c-commands' as workaround, which is
  disabled by default, you can set it to `t' for enable this.


4.2 The menu-bar command keybinding description is not updated.
───────────────────────────────────────────────────────────────

  Currently there is not a possible workaround, but as an alternative,
  the `marginalia' package provides detailed information about the
  commands keybindings.


4.3 I cannot rebind `C-g' properly
──────────────────────────────────

  It is not possible to remap `C-g' properly.

  Although solutions such as this can be used:

  ┌────
  │ (keymap-unset standard-keys-default-keymap "C-g")
  │ (keymap-set standard-keys-default-keymap "ESC" (standard-keys-key-keybinding "C-g"))
  └────

  The emergency quit (typing `C-g' once or many times) is hardcoded in
  Emacs C source code and cannot be changed.

  So, when Emacs gets stuck, pressing the remaped `C-g' (e.g. `ESC')
  will not quit from current loop.


5 Alternatives
══════════════

[ergoemacs] <http://ergoemacs.github.io/>

5.1 [ergoemacs].
────────────────

        A minor-mode that aims to:
        • Use/Create ergonomic keybindings in emacs that will
          reduce RSI
        • Use the commonly bound keys familiar to most people
          today. Ctrl+C for copy, Ctrl+z for undo, etc.

  ergoemacs is very opinated, from my experience, it is hard to
  customize and use, the documentation is very outdated, and does not
  work properly in recent versions of Emacs.

  But if you don't care about this, you can try it.


[ergoemacs] <http://ergoemacs.github.io/>


5.2 [cua-mode] (built-in in Emacs).
───────────────────────────────────

        CUA mode is a global minor mode.  When enabled, typed text
        replaces the active selection, and you can use C-z, C-x,
        C-c, and C-v to undo, cut, copy, and paste in addition to
        the normal Emacs bindings.  The C-x and C-c keys only do
        cut and copy when the region is active, so in most cases,
        they do not conflict with the normal function of these
        prefix keys.

  cua-mode doesn't include the classic commands that you may expect: C-o
  (Open), C-s (Save), C-f (Search), etc; so you will probably have to
  invest time in configuring it.

  However cua-mode mode includes some features you may be interested in
  (e.g. `cua-enable-cursor-indications', `cua-toggle-rectangle-mark',
  etc).


[cua-mode]
<https://www.gnu.org/software/emacs/manual/html_node/emacs/CUA-Bindings.html>


5.3 [wakib-keys]
────────────────

        Emacs minor mode that provides a modern, efficient and
        easy to learn keybindings.  This mode makes it easy to
        pick up Emacs and start unlocking its potential without
        having to sacrifice its power. The point of this mode it
        to leverage common shortcuts that you are used to while
        making it easy to learn Emacs.

  wakib-keys was the inspiration for package.

  Like standard-keys-mode, wakib rebinds the C-x/C-c prefixes to C-e/C-d
  respectively.  However wakib has been somewhat outdated, with some
  bugs in recent versions of Emacs.

  If you are using an older Emacs version (prior 29.x), you can use
  wakib-keys instead of standard-keys-mode.

  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
  Thanks to Abdulla Bubshait (darkstego) for creating wakib-keys, which
  was the inspiration for this package.


[wakib-keys] <https://github.com/darkstego/wakib-keys>
