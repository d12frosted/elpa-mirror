
Overview
========

This library provides minor mode `smooth-scroll-mode' which adds
smooth scrolling feature to Emacs.


INSTALLING
==========
To install this library, save this file to a directory in your
`load-path' (you can view the current `load-path' using "C-h v
load-path RET" within Emacs), then add the following line to your
.emacs startup file:

   (require 'smooth-scroll)
   (smooth-scroll-mode t)


USING
=====
To toggle smooth scrolling feature, just type:

  `M-x smooth-scroll-mode RET'

while smooth scrolling feature is enabled, the string "SScr" will
be displayed on mode line.

Also check out the customization group

  `M-x customize-group RET smooth-scroll RET'


Additional commands provided by `smooth-scroll.el'.
===================================================

This library provides commands that brings `in place scrolling'
feature, listed below:

   `scroll-up-1'
   `scroll-down-1'
   `scroll-left-1'
   `scroll-right-1'

Bind these commands to any key you like for your convenience.

   Keymap example:

     (global-set-key [(control  down)]  'scroll-up-1)
     (global-set-key [(control  up)]    'scroll-down-1)
     (global-set-key [(control  left)]  'scroll-right-1)
     (global-set-key [(control  right)] 'scroll-left-1)

     NOTE: Keys described above won't work on non window-system.


KNOWN PROBLEMS
==============
- The speed of smooth scrolling is very slow on `Carbon Emacs'
  and `Cocoa Emacs' on Mac OS X. If you want to use smooth scrolling
  feature comfortably on these Emacsen, set large number
  (e.g. 4, 6 or 8) to the variable `smooth-scroll/vscroll-step-size'
  and `smooth-scroll/hscroll-step-size'.

- `scroll-left-1' and `scroll-right-1' may not work properly
  when the `smooth-scroll-mode' is turned off, due to the behavior
  of original `scroll-left' and `scroll-right' functions.
