1 Isl                                                              :TOC:
═════

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


1.1 Introduction
────────────────

  Isl like Isearch-light.  An Isearch replacement for Emacs.  Multi
  search expression(s) in symbols, words and/or lines in
  `current-buffer'.


1.2 Features
────────────

  • Provide [multi matching], a real minibuffer, no unexpected quit or
    errors and comprehensive mode-line indicators.

  • Old position is always saved in mark-ring when exiting to a new
    place.

  • Only one command `isl-search' for all which cycle in all matches
    without stopping.

  • Select nearest match from your position, not necessarily after or
    before, this initial match can be reached back at any moment.

  • Allow jumping to `Iedit' at any time during the search.

  • Allow jumping to `helm-occur' at any time.

  • Allow showing only the matching lines with their context.

  • Help available at any time during search without having to quit
    session.

  • Allow resuming previous session in each buffer isl had visited.

  It aims to keep simple with only the needed features, no extra
  features you will never use.


[multi matching] <https://github.com/thierryvolpiatto/isl
?tab=readme-ov-file#about-multi-matching>


1.3 Dependencies
────────────────

  No mandatory dependencies, but for a better experience install [Helm]
  to have `helm-occur', [Iedit] to allow jumping to iedit session and
  [bm] to mark interesting positions while navigating (if you use this
  you will want as well [helm-bm] to retrieve later these positions).


[Helm] <https://github.com/emacs-helm/helm>

[Iedit] <https://github.com/victorhge/iedit>

[bm] <https://github.com/joodland/bm>

[helm-bm] <https://github.com/emacs-helm/helm-bm>


1.4 Install
───────────

1.4.1 From package
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Isl is available in NonGnu Elpa.  Use `package-install' to install it.


1.4.2 From source
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Add isl.el to `load-path' and compile it.

  Then add `(require 'isl)' in your init file.

  Even better, you can autoload it:

  ┌────
  │ (autoload 'isl-search "isl" nil t)
  │ (autoload 'isl-narrow-to-defun "isl" nil t)
  │ (autoload 'isl-resume "isl" nil t)
  └────


1.5 Configure
─────────────

  You may want to disable all `Isearch' global bindings:

  ┌────
  │ (global-set-key [remap isearch-forward] 'undefined)
  │ (global-set-key [remap isearch-backward] 'undefined)
  │ (global-set-key [remap isearch-forward-regexp] 'undefined)
  │ (global-set-key [remap isearch-backward-regexp] 'undefined)
  │ (global-set-key (kbd "C-r") nil)
  │ (global-set-key (kbd "C-s") nil)
  │ (global-set-key (kbd "C-M-s") nil)
  │ (global-set-key (kbd "C-M-r") nil)
  └────

  And then rebind the necessary keys to isl-* commands:

  ┌────
  │ (global-set-key (kbd "C-s")   'isl-search)
  │ (global-set-key (kbd "C-z")   'isl-narrow-to-defun)
  │ (global-set-key (kbd "C-M-s") 'isl-resume)
  └────

  You will find severals user variables prefixed with `isl-', see M-x
  customize-variable.

  NOTE: many of them can be toggled while in `isl-search' session, so
  you may not need to modify them unless you want to change the default
  behavior.


1.6 Usage
─────────

  `M-x isl-search'

  The mode-line give you several infos, arrows up/down tell you the
  direction where you are actually moving, the `>' and `<' mean you are
  either below or above initial position in buffer. Regex or Literal
  tell you the style of search you are using. Case sensitivity in use is
  notified by `*', `0' or `1' which mean smart, nil or t for
  `case-fold-search'.

  Don't forget `C-h m' which show you all these commands while running
  Isl.

  NOTE: Another map `isl-mini-map' is used when excuting-kbd-macro, you
  may want to modify it accordingly to fit with `isl-map'.


1.6.1 Available commands
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   C-h m    Display or quit this help buffer                     
   C-q      Quit this help buffer                                
   C-n      Goto next occurence                                  
   C-p      Goto previous occurence                              
   M-v      Scroll down                                          
   C-v      Scroll up                                            
   RET      Exit at current position                             
   C-]      Quit and restore initial position                    
   C-w      Yank word at point                                   
   C-z      Yank symbol at point                                 
   C-l      Recenter current buffer                              
   M-r      Toggle matching style (regexp/litteral)              
   M-c      Change case fold search (cycle: *=smart, 1=t, 0=nil) 
   M-<      Goto first occurence                                 
   M->      Goto last occurence                                  
   M-=      Goto closest occurence from start                    
   M-s      Jump to helm-occur                                   
   C-;      Jump to iedit-mode                                   
   M-%      Jump to query replace                                
   C-'      Hide or show non matching lines                      
   C-j      Toggle multi search style (InLine/InSymbol)          
   M-i      Toggle searching in invisible text                   
   C-!      Add bookmark BM to current pos                       
   C-c C-k  Kill selected occurence                              
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


1.7 About multi matching
────────────────────────

  By default `isl-search' uses multi matching like Helm, with limitation
  to symbol, not line like in Helm, that means "foo bar" matches
  "foo-bar" or "bar-foo" but not a line with "foo" and "bar" inside.



  when you want to match e.g. "foo some text bar", you have to use
  regexp e.g. "foo.*bar" or switch to multi match line matching with C-j
  aka `isl-toggle-multi-search-in-line'.



  To use multi matching, separate text with one space, each pattern
  beginning by "!" will mean match everything but this, e.g. "foo !bar"
  will not match "foo-bar" but will match "foo-baz".



  Note: You can jump to `helm-occur' for a line based search at any
  time.  You can also jump to [iedit-mode] with multi match pattern (you
  may have an error if all the matches do not refer to the same word or
  symbol).


[iedit-mode] <https://github.com/victorhge/iedit>


1.8 Isl vs helm-occur
─────────────────────

  Isl is a good tool for searching words or symbols in a buffer and even
  if it can search several words separated by spaces, helm-occur is more
  efficient for this as it is based on line searching.

  Helm-occur is not efficient when you have to search in a buffer with
  continuous text with no newlines e.g. some logs or debug logs etc… you
  have better time using isl.

  A good compromise is to start searching with isl and if it turns out
  what you need to match is whole lines instead of words or symbols,
  switch to helm-occur with `isl-jump-to-helm-occur' bound by default to
  `M-s'.

  UPDATE: Isl can now switch to a line based search like `helm-occur'
  easily.


1.9 Use Isl for helm-help
─────────────────────────

  Starting from Emacs-27 Isearch works more or less with unexpected
  effects, you have better time using `isl-search' as the search command
  for helm-help, here how to replace default setting by `isl` in
  helm-help:

  ┌────
  │ (with-eval-after-load 'helm-lib
  │   (autoload 'isl-search "isl" nil t)
  │   (helm-help-define-key "C-s" nil)
  │   (helm-help-define-key "C-r" nil)
  │   (helm-help-define-key "C-s" 'isl-search))    
  └────

  An alternative is to customize `helm-help-hkmap` from the customize
  interface.
