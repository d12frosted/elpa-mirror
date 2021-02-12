Colemak Evil
============

Colemak Evil is a set of remappings that implements some of
Shai Coleman's awesome Vim remappings in Emacs
([more information](http://forum.colemak.com/viewtopic.php?id=50)).

Here are the main differences from Shai's mappings:

* The only Vim mapping that works in insert mode is Esc (this avoids
  conflicts with Emacs's shortucts). Tab in insert mode doesn't take
  you into normal mode.
* Folding and several other features aren't implemented.

Setup
-----

You can install Colemak Evil (as `colemak-evil`) from the MELPA repository.
Once it's installed, add the following to your `.emacs` file:

    (require 'colemak-evil)

Tips
----

Type :hints (or just :h) to bring up the hint screen.

Escape takes you into normal mode, but you may find that defining your
own key combination using
[Key Chord](http://www.emacswiki.org/emacs/key-chord.el) to be more
comfortable. The only adjacent home-row combinations that are
relatively uncommon in English "hn" and "td." If you find yourself
unintentionally entering normal mode when typing quickly, you might
try reducing the key delay:

    (key-chord-define-global "td" 'evil-normal-state)
    (setq key-chord-two-keys-delay .01)

If this doesn't work, you can use the spacebar as one of the keys:

    (key-chord-define-global " e" 'evil-normal-state)

There are also some Vim features that haven't yet been implemented in
Evil. You'll probably have to add quite a few of your own mappings to
get your setup where you want it. For insert-mode mappings, check out
[ErgoEmacs](http://ergoemacs.org/emacs/ergonomic_emacs_keybinding.html),
which provides saner alternatives to Emacs's mappings (there's a
Colemak version).

An Alternative
--------------

[Lalopmak Evil](https://github.com/lalopmak/lalopmak-evil), another
set of Emacs mappings based on Shai's Vim layout, "takes some of
Shai's ideas even further." If you're used to and happy with Shai's
mappings, you'll probably be satisfied with Colemak Evil. But if
you're just starting out or you're an efficiency fanatic, Lalopmak
Evil may be the better choice.
