1 Devil Mode
════════════

  [file:https://melpa.org/packages/devil-badge.svg]
  [file:https://stable.melpa.org/packages/devil-badge.svg]
  [file:https://elpa.nongnu.org/nongnu/devil.svg]
  [file:https://img.shields.io/badge/mastodon-%40susam-%2355f.svg]

  Devil mode trades your comma key in exchange for a modifier-free
  editing experience in Emacs.  Yes, the comma key!  The key you would
  normally wield for punctuation in nearly every corner of text.  Yes,
  this is twisted!  It would not be called the Devil otherwise, would
  it?  If it were any more rational, we might call it something divine,
  like, uh, the God mode?  But alas, there is nothing divine to be found
  here.  Welcome, instead, to the realm of the Devil!  You will be
  granted the occasional use of the comma key for punctuation, but only
  if you can charm the Devil.  But beware, for in this sinister domain,
  you must relinquish your comma key and embrace an editing experience
  that whispers wicked secrets into your fingertips!


[file:https://melpa.org/packages/devil-badge.svg]
<https://melpa.org/#/devil>

[file:https://stable.melpa.org/packages/devil-badge.svg]
<https://stable.melpa.org/#/devil>

[file:https://elpa.nongnu.org/nongnu/devil.svg]
<https://elpa.nongnu.org/nongnu/devil.html>

[file:https://img.shields.io/badge/mastodon-%40susam-%2355f.svg]
<https://mastodon.social/@susam>

1.1 Introduction
────────────────

  Devil is available in MELPA as well as NonGNU ELPA.  If you are using
  Emacs 28.1 or a more recent version of Emacs, you can get the latest
  stable version of Devil by typing `M-x package-install RET devil RET'.
  Otherwise, you need to add MELPA or NonGNU ELPA to your list of
  package archives and then install MELPA.  More details on the
  installation procedure is provided in the [manual].

  By default, Devil mode rebinds the comma key to activate Devil.  Once
  activated, Devil reads a so-called Devil key sequence from you.  As
  you type your Devil key sequence, Devil translates the key sequence to
  a regular Emacs key sequence.  If any command is bound to the
  translated Emacs key sequence, Devil runs that command and then
  deactivates itself.

  By default, each comma in the Devil key sequence is translated to
  "C-".  For example, if you type ", x , f", Devil translates it to "C-x
  C-f".  Similarly ", m" is translated to "M-".  If you type ", m x",
  Devil translates it to "M-x".  Further ", m m" is translated to
  "C-M-".  If you type ", m m f" Devil translates it to "C-M-f".  There
  are several other translations available in the default translation
  rules that let you enjoy working with Emacs while avoiding modifier
  keys.  Further, the Devil activation key, translation rules, etc. are
  customisable.  Thus if you do not like the default choices made in
  this package, you can customise it easily to suit your preferences.

  Read the [manual] to learn how to install, use, and customise Devil.


[manual] <https://susam.github.io/devil/>


1.2 Channels
────────────

  The author of this project hangs out at the following places online:

  • Website: [susam.net]
  • Mastodon: [@susam@mastodon.social]
  • GitHub: [@susam]

  You are welcome to subscribe to, follow, or join one or more of the
  above channels to receive updates from the author or ask questions
  about this project.


[susam.net] <https://susam.net>

[@susam@mastodon.social] <https://mastodon.social/@susam>

[@susam] <https://github.com/susam>


1.3 Support
───────────

  To report bugs, suggest improvements, or ask questions, [create
  issues].


[create issues] <https://github.com/susam/devil/issues>


1.4 Contributing
────────────────

  See [CONTRIBUTING.org] for contribution guidelines.


[CONTRIBUTING.org]
<https://github.com/susam/devil/blob/main/CONTRIBUTING.org>


1.5 Thanks
──────────

  Thanks to:

  • [Chris Rayner] for initial code review.
  • [Philip Kaludercic] for initial code review and patches.
  • [Morgan Willcock] for initial feedback and code reviews.


[Chris Rayner] <https://github.com/riscy>

[Philip Kaludercic] <https://github.com/phikal>

[Morgan Willcock] <https://github.com/morganwillcock>


1.6 Reactions
─────────────

  Some amusing reactions to this project collected from various corners
  of the world wide web:

        Every bit of this horrifies me, and I can't believe you've
        done it.  Outstanding.  Well done!  – [@kstrauser]

        This is insane.  I am going to try it immediately.  –
        [@jrockway]

        Will defiantly check this out.  – [@strings]

        Defiantly!  – [@oantolin]

        😈 – [@SequentialDesign]


[@kstrauser] <https://news.ycombinator.com/item?id=35953341>

[@jrockway] <https://news.ycombinator.com/item?id=35855621>

[@strings]
<https://old.reddit.com/r/emacs/comments/13aj99j/devil_mode_a_twisted_key_sequence_translator_for/jj94y35/>

[@oantolin]
<https://old.reddit.com/r/emacs/comments/13aj99j/devil_mode_a_twisted_key_sequence_translator_for/jj98owf/>

[@SequentialDesign]
<https://old.reddit.com/r/emacs/comments/13aj99j/devil_mode_a_twisted_key_sequence_translator_for/jj72ive/>


1.7 More
────────

  See [Emacs4CL], a DIY quick-starter kit to set up Emacs for Common
  Lisp programming.

  See [Emfy], a DIY quick-starter kit to set up Emacs for general
  purpose editing and programming.


[Emacs4CL] <https://github.com/susam/emacs4cl>

[Emfy] <https://github.com/susam/emfy>
