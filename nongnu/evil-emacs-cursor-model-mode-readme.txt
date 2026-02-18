                     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
                      EVIL EMACS CURSOR MODEL MODE
                     ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


This is a mode for using Emacs' cursor between characters model in
evil-mode's normal-state.


License
───────

  Creative Commons Attribution-ShareAlike 4.0 International License
  <https://creativecommons.org/licenses/by-sa/4.0/>

  Supposedly this is convertible to GPL 3.


Thanks
╌╌╌╌╌╌

  Toby Cubitt coded the motions in the cursor model.
  <https://www.dr-qubit.org/Evil_cursor_model.html>


Install
───────

  Download evil-emacs-cursor-model-mode.el, open and install it with
  (package-install-from-buffer).  Add the following code to your
  init.el:
  ┌────
  │ (require 'evil-emacs-cursor-model-mode)
  │ (evil-emacs-cursor-model-mode 1)
  └────


Cursor models
─────────────

  Vim works with two cursor models.  A cursor /on top of/ characters
  model in normal-state and /between/ characters in insert-state.  The
  evil-emacs-cursor-model-mode unify these to a cursor between model in
  all states.

  Furthermore it becomes natural to change some keybindings in this
  framework.  I preserve evil-mode's /modal/ interface!


Keybindings
───────────

  Even though or maybe because I come from the Emacs world, I don't like
  layers.  `<shift>' just like `<ctrl>' is a layer and I try to minimize
  the use of them in keybindings.  To do this the mode will change three
  keybindings in evil-mode's normal-state keys.


The `a' binding
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  First and foremost Vim's `a' in normal-state makes little sense in
  this mode.  Evil-mode's (evil-append) is just `l' (evil-forward-char)
  and `i' (evil-insert).  That is how you should think if you adopt the
  mode's cursor model.

  Therefore I bind (evil-append-line) to `a'.

  Entering insert-state at the end of line (evil-append-line) makes
  sense, whereas (evil-append) does not.  The mode has the keymap
  evil-emacs-cursor-model-mode-map where you can rebind `A' if you wish.


The `p' and `o' bindings
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  With the change to `a' it is natural to have a look at `p' too.  When
  you are not pasting a full line, Vim's `p' makes little sense in this
  mode.  Move forward and paste is strange to prioritize with a lower
  case binding.

  Therefore I swap evil-mode's `p' and `P'.

  When you use the mode, you might find yourself only using the
  (evil-paste-before) command to paste.  Vim's need for two paste
  commands is compensation for the normal-state cursor model.  Other
  editors only have one paste command and this mode also mainly have
  one.  (evil-paste-after) is still bound to `P' and can be useful, but
  you can contextually replace it with `jp' or `lp'.

  Last I swap evil-mode's `o' and `O' so they are consistent with `p'
  and `P' when you paste lines.


Summary
╌╌╌╌╌╌╌

  These are all normal-state keybindings:

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   This mode's binding  Vim's binding  Alternative        Lisp function       
  ────────────────────────────────────────────────────────────────────────────
   `a'                  `A'            `$i'               (evil-append-line)  
   `A'                  `a'            `li'               (evil-append)       
   `o'                  `O'                               (evil-open-above)   
   `O'                  `o'            `jo' and `a<RET>'  (evil-open-below)   
   `p'                  `P'                               (evil-paste-before) 
   `P'                  `p'            `jp' or `lp'       (evil-paste-after)  
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Besides these commands the mode manipulate motions so the cursor
  between characters model will work.  E.g. `E' should bring you to the
  end of a word rather than between the last two characters of a word.
  These manipulations all work seamlessly and should feel natural.


The line nugget idea
────────────────────

  One idea of the mode is to reduce the use of layers and bindings.
  When the commands change as described above, you might start to adopt
  a new philosophy.  The idea is to work with motions among line
  nuggets.

  With this mode the /commands/ focus on the current line and you can
  replace all layers with motions.  If you want to open the next line
  you can use `jo' or `a<RET>' which are both two keystrokes, but so are
  `<shift>o'.  Same works for paste where `jp' can replace the mode's
  `P', when you paste a line.

  Note that the /motions/ `f', `t', `w', `b', `e', and `ge' still have
  their upper case variants.

  The mindset is that you focus and work on the current line.  I feel
  this logic is easier to comprehend and internalize if you are not a
  power user.


Efficiency
╌╌╌╌╌╌╌╌╌╌

  Compared to Vim the efficiency is roughly the same with this mode.  If
  you need to work with the next line you will need weakly more
  keystrokes.  When dealing with the current line nugget you might need
  fewer.  In most situations you will probably solve whatever you want
  to do, with roughly the same number of keystrokes.

  Using a layer increase complexity because it does not only require
  that you use two keys.  It also adds a restriction on holding down a
  key while pressing other keys.  The following is not fair, but I find
  it harder to write "hEll" than "hello".

  Ultimately the modal framework focus on editing text (working with the
  current line) rather than adding new text (working with additional
  lines).


Drawbacks
─────────

  The main drawback is that it will be harder to work efficiently with a
  vanilla Vi, Vim or evil-mode editor.  The former mentioned muscle
  memory will work against you.

  The mode will also mess with Vim's "verb" → "noun" mindset.  Motions
  are nouns and usually the idea is to minimize their use.  Replacing
  layers with motions are in conflict with this idea.


Combined command and motion
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  Vim has commands that combine a functionality with a motion.  A useful
  application of the command/motion behavior is Vim's `xp' which /swap/
  two characters and move the cursor forward.  This is less accessible
  in this mode because I swap the paste commands (`xP').

  The lisp function (transpose-chars) does roughly the same thing
  without involving the kill ring.  I bind it to `gs' in my init, but
  this is /not/ a part of the mode.
  ┌────
  │ (bind-keys
  │  :map evil-normal-state-map
  │  ("gs" . transpose-chars))
  └────
  Vim's default `gs' is (sit-for 1) but evil-mode doesn't implement it.

  Note that evil-mode's behavior is still available so e.g. `~'
  (evil-invert-char) will work on the (char-after) and move forward.


Touching delimiters
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  If you have touching delimiters like "(…)(…)" and your cursor is
  between them, then `%' will jump back to the first "(".  In this mode
  there is no evil-mode way to toggle back and forth between the second
  set of delimiters when the two sets are touching.


Visual block
╌╌╌╌╌╌╌╌╌╌╌╌

  Last the mode does nothing to `C-v' which is still working with a
  cursor on top of character model.  In practice `C-v' is still usable
  and useful but it does have bugs tied to motions and the end of line
  position.

  Emacs' `C-x <SPC>' (rectangle-mark-mode) works in insert-state but not
  in normal-state.  If `C-v' fails I suggest you fall back on marking
  with `v' and use the `C-x r' bindings.


1 Raison d'être speculation
═══════════════════════════

  The /line nugget/ mindset will use less commands and the logic is
  easier to learn and internalize.

  Alternatively the reason for the mode might be to introduce Vim or
  evil-mode.  The mode can make it a better experience to pick up the
  /modal framework/.

  Last Emacs pinky is a real thing and /fewer layers/ might be
  important.  This will also be helpful to people who use "sticky keys"
  accessibility.

  To me all three reasons are important.  I like line nuggets in a modal
  framework with few layers.
