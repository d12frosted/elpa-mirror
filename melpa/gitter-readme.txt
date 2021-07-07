                             _____________

                               GITTER.EL

                              Chunyang Xu
                             _____________


Table of Contents
_________________

1 Prerequisites
2 Install
.. 2.1 Melpa
.. 2.2 Manually
3 Setup
4 Usage
5 Customization
.. 5.1 Emoji
6 Limitation
7 To do


[[https://melpa.org/packages/gitter-badge.svg]]
[[https://travis-ci.org/xuchunyang/gitter.el.svg?branch=master]]
[[https://badges.gitter.im/M-x-Gitter/Lobby.svg]]

A [Gitter] client for [GNU Emacs].


[[https://melpa.org/packages/gitter-badge.svg]]
https://melpa.org/#/gitter

[[https://travis-ci.org/xuchunyang/gitter.el.svg?branch=master]]
https://travis-ci.org/xuchunyang/gitter.el

[[https://badges.gitter.im/M-x-Gitter/Lobby.svg]]
https://gitter.im/M-x-Gitter/Lobby

[Gitter] https://gitter.im/

[GNU Emacs] https://www.gnu.org/software/emacs/


1 Prerequisites
===============

  - cURL
  - Emacs 24.1 or newer


2 Install
=========

2.1 Melpa
~~~~~~~~~

  `gitter.el' is available from Melpa. After[setting up] Melpa as a
  repository and update the local package list, you can install
  `gitter.el' and its dependencies using `M-x package-install gitter'.


[setting up] https://melpa.org/#/getting-started


2.2 Manually
~~~~~~~~~~~~

  Add gitter.el to your `load-path' and require. Something like:

  ,----
  | (add-to-list 'load-path "path/to/gitter.el/")
  | (require 'gitter)
  `----

  If you want to avoid loading `gitter.el' at Emacs startup, autoload
  the `gitter' command instead of requiring.


3 Setup
=======

  You need to set `gitter-token' to the authentication-token. Follow
  these steps to get your token:
  1) Visit URL `[https://developer.gitter.im]'
  2) Click Sign in (top right)
  3) You will see your personal access token at URL
     `[https://developer.gitter.im/apps]'

  When you save this variable, DON'T WRITE IT ANYWHERE PUBLIC.

  ,----
  | (setq gitter-token "your-token")
  `----


4 Usage
=======

  Type `M-x gitter' to join a room and start chatting.


5 Customization
===============

5.1 Emoji
~~~~~~~~~

  If you want to display Emoji, install [emojify] *or*
  [emoji-cheat-sheet-plus] *or* [company-emoji], they are all available
  from MELPA. You only need to install one of them, but if you install
  more than one of them, the priority is emojify >
  emoji-cheat-sheet-plus > company-emoji.


[emojify] https://github.com/iqbalansari/emacs-emojify

[emoji-cheat-sheet-plus]
https://github.com/syl20bnr/emacs-emoji-cheat-sheet-plus

[company-emoji] https://github.com/dunn/company-emoji


6 Limitation
============

  If you are a serious Gitter user (I am not) and you compare this
  little program with other official Gitter clients, I guess you will
  probably be very disappointed: lack of functions and features, buggy
  etc, so now you have been warned. However, feedback, suggestion and
  patch are always welcome.

  By the way, Gitter provides [IRC access] and there are several
  well-known IRC clients for Emacs.


[IRC access] https://irc.gitter.im/


7 To do
=======

  - [ ] Markup message
    - plain link
    - Markdown link
    - Github-flavored Markdown image
    - @mention
    - Github #issue
    - Markdown inline code block (add syntax highlighting if it is
      possible and very easy)
    - Github-flavored fenced code block (add syntax highlighting if it
      has proper language tag)
    - Github-flavored indented with four spaces code block (prefer no
      syntax highlighting to avoiding guessing what language the code is
      in, I don't like guess)
    - etc
