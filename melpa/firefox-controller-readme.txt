           __________________________________________________

                FIREFOX-CONTROLLER: AN IMPROVED FIREFOX
                         CONTROLLER FOR EMACS!

                              Junpeng Qiu
           __________________________________________________


Table of Contents
_________________

1 Installation
.. 1.1 Firefox Extension
.. 1.2 Emacs Extensions
2 Intro
3 `firefox-controller-remote-mode'
4 `firefox-controller-direct-mode'
5 Define Your Own Key Sequences to Be Sent
6 Customization
7 Acknowledgment





1 Installation
==============

1.1 Firefox Extension
~~~~~~~~~~~~~~~~~~~~~

  Install [MozRepl] in Firefox.


  [MozRepl] https://addons.mozilla.org/en-US/firefox/addon/mozrepl/


1.2 Emacs Extensions
~~~~~~~~~~~~~~~~~~~~

  This package is now on [melpa]. You can install directly from [melpa]
  using `package.el'.

  Or use the following steps to install manually:
  1. Install [moz.el] and [popwin-el].
  2. Install this package and add it to your load path
     ,----
     | (add-to-list 'load-path "/path/to/firefox-controller.el")
     | (require 'firefox-controller)
     `----

  [melpa] http://melpa.org/

  [moz.el] https://github.com/bard/mozrepl/wiki/Emacs-integration

  [popwin-el] https://github.com/m2ym/popwin-el


2 Intro
=======

  This project started as a fork of [Wenshan]'s [moz-controller], but I
  ended up rewriting most of the code and chose a quite different way to
  use it.

  In `firefox-controller', we have two different modes:
  1. `firefox-controller-remote-mode': This is based on the original
     `moz-controller', but the number of available commands increases
     from 11 to more than 30, and simpler key bindings and a better UI
     are also provided.
  2. `firefox-controller-direct-mode': In this mode, you can send the
     keys directly to firefox.


  [Wenshan] https://github.com/RenWenshan

  [moz-controller] https://github.com/RenWenshan/emacs-moz-controller


3 `firefox-controller-remote-mode'
==================================

  Use `M-x firefox-controller-remote-mode' to enter
  `firefox-controller-remote-mode'. It is called `remote-mode' because
  the keys that you pressed are handled by Emacs and Emacs will send
  control commands to firefox.

  Here is the screeshot when using `firefox-controller-remote-mode':
  [https://github.com/cute-jumper/ace-pinyin/blob/master/screenshots/remote-mode.png]

  As we can see in the screenshot, we have defined most of the commonly used
  commands in firefox. For example, n to scroll down by one page, and t to
  open a new tab and switch to it. You can exit the
  `firefox-controller-remote-mode' by q.

  To search the web page, press s. Here is the screenshot for the search
  mode in `firefox-controller-remote-mode' (we are searching "bibtex" in
  the current web page): [./screenshots/search-mode.png]

  However, you don't necessarily need to call
  `firefox-controller-remote-mode' to use these commands. You can bind
  your own key to a specific command. Look at the
  `firefox-controller--remote-mode-keymap-alist' variable to find out the
  commands that can be bound to. For example, you can use C-c m L to copy
  the current tab' URL by:
  ,----
  | (global-set-key (kbd "C-c m L")
  |                 #'firefox-controller-get-current-url)
  `----


4 `firefox-controller-direct-mode'
==================================

  The limitation of `firefox-controller-remote-mode' is that under that
  mode, the web page is /non-interactive/. We can only view, scroll,
  switch tab, search and open another tab for a new URL. However, if you
  want to jump to a link or enter some text in the input box, these
  functions are not implemented. Here comes
  `firefox-controller-direct-mode', which can be combined with some
  powerful firefox extensions such as [KeySnail] to build emacs-like
  mouseless browsing experience for firefox. We don't have to recreate
  some firefox extensions in `firefox-controller-remote-mode'.

  The use of `firefox-controller-direct-mode' is quite straightforward.
  `M-x firefox-controller-direct-mode', then you can use all the key
  bindings as if you are in firefox instead of Emacs, except for four
  special key bindings:
  1. C-M-g: Move the current focus to the content window. This is useful
     when you want to move out of the address bar or search bar to perform
     some page navigation(scroll up/down, open some link, etc.).
  2. M-g: This is bound to `firefox-controller-highlight-focus', which can
     show a temporary background color in the current focused element.
     This command is useful since the foreground application is Emacs,
     firefox won't show the current focused element(at least, we can't see
     it in Plasma 5 in Linux, which is my test environment). You can use
     M-g to give you a visual hint about the location of the cursor.
  3. C-z: This command switches from the current mode to
     `firefox-controller-remote-mode'.
  4. C-g: Exit `firefox-controller-direct-mode'.

  Here is the screenshot to use `firefox-controller-direct-mode':
  [https://github.com/cute-jumper/ace-pinyin/blob/master/screenshots/direct-mode.gif]

  Explanation: After I invoke `firefox-controller-direct-mode', I type
  C-l to go to the address bar, and use M-g to highlight my current
  location(which is the address bar of course). Then go to google.com,
  and use M-g again to confirm the current focused element in firefox is
  the search box. After I type and search "emacs", I use KeySnail's
  plugin [hok] to jump to a link and open it.


  [KeySnail] https://github.com/mooz/keysnail

  [hok] https://github.com/mooz/keysnail/raw/master/plugins/hok.ks.js


5 Define Your Own Key Sequences to Be Sent
==========================================

  You can use `firefox-controller-send-key-sequence' function to define
  your own key sequences which can be sent directly to firefox.

  For example, we define C-c m g to open a new tab and go to
  www.google.com:
  ,----
  | (global-set-key (kbd "C-c m g")
  |                 (lambda ()
  |                   (interactive)
  |                   (firefox-controller-send-key-sequence
  |                    "C-t C-l www.google.com <return>")))
  `----

  Make sure your key sequence can be read by the `kbd' function.



6 Customization
===============

  - `firefox-controller-zoom-step': Zoom step. Default value is 0.1.
  - `firefox-controller-highlight-focus-background': The background
     color used by `firefox-controller-highlight-focus' command. Default
     value is "yellow".


7 Acknowledgment
================

  - [RenWenshan] for the original [moz-controller].


  [RenWenshan] https://github.com/RenWenshan/

  [moz-controller] https://github.com/RenWenshan/emacs-moz-controller
