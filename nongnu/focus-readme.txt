Table of Contents
─────────────────

1. Focus
2. Installation
3. Usage
.. 1. Focus read-only mode
4. Customization
.. 1. Faces


[file:https://melpa.org/packages/focus-badge.svg]
[file:https://stable.melpa.org/packages/focus-badge.svg]


[file:https://melpa.org/packages/focus-badge.svg]
<https://melpa.org/#/focus>

[file:https://stable.melpa.org/packages/focus-badge.svg]
<https://stable.melpa.org/#/focus>


1 Focus
═══════

  <file:./focus-demo.gif>

  This is Focus, a package that dims surrounding text. It works with any
  theme and can be configured to focus in on different regions like
  sentences, paragraphs or code-blocks.


2 Installation
══════════════

  It's available on [MELPA] and [MELPA Stable]:

  ┌────
  │ M-x package-install focus
  └────


[MELPA] <https://melpa.org/#/focus>

[MELPA Stable] <https://stable.melpa.org/#/focus>


3 Usage
═══════

  Enable `focus-mode' with `M-x focus-mode'.

  A few interactive functions are provided:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Function              Description                                                              
  ────────────────────────────────────────────────────────────────────────────────────────────────
   `focus-change-thing'  Adjust the narrowness of the focused section for the current buffer      
   `focus-pin'           Pin the focused section to its current location or the region, if active 
   `focus-unpin'         Unpin the focused section                                                
   `focus-next-thing'    Move the point to the middle of the Nth next thing                       
   `focus-prev-thing'    Move the point to the middle of the Nth previous thing                   
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Focus relies on [Thing At Point], which can retrieve a /thing/
  surrounding the point. These /things/ may be a symbol, list,
  S-expression (sexp), function definition (defun), sentence, line, page
  and others. Calling `M-x focus-change-thing' allows you to
  interactively change the kind of region which should be in focus.


[Thing At Point] <https://www.emacswiki.org/emacs/ThingAtPoint>

3.1 Focus read-only mode
────────────────────────

  Enable `focus-read-only-mode' with `M-x focus-read-only-mode'. It
  inhibits changes in a buffer, hides the cursor and provides bindings
  for moving between /things/.

  Some bindings for simple navigation and exiting `focus-read-only-mode`
  are provided.

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Keybinding  Description                 
  ─────────────────────────────────────────
   `n'         Jump to next /thing/        
   `SPC'       Jump to next /thing/        
   `p'         Jump to previous /thing/    
   `S-SPC'     Jump to previous /thing/    
   `i'         Exit `focus-read-only-mode' 
   `q'         Exit `focus-read-only-mode' 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


4 Customization
═══════════════

  The choice of what /thing/ is suitable for a mode may be configured by
  setting the variable `focus-mode-to-thing'. The default is

  ┌────
  │ '((prog-mode . defun) (text-mode . sentence))
  └────

  For modes inheriting `prog-mode' (which are most programming modes),
  the default is the function-body, and for modes inheriting
  `text-mode', the default is a sentence.

  For instance, adding the following to your `.emacs'-file:

  ┌────
  │ (add-to-list 'focus-mode-to-thing '(python-mode . paragraph))
  └────

  changes `python-mode' to focus in on code-blocks with no blank lines
  rather than the entire function.

  According to [this reddit post], Focus plays nice with `lsp-mode'.


[this reddit post]
<https://www.reddit.com/r/emacs/comments/b1vrar/lsp_support_for_focusel_using_lspmode/>

4.1 Faces
─────────

  Focus offers two faces, one for the focused- and unfocused area. By
  default, the `focus-focused' is the empty face, meaning there is no
  change, and `focus-unfocused' inherits the comment face (which is
  usually subtle). The faces can easily be customized via `M-x
  list-faces-display'.
