You can take a look at screenshots and acquire more information on:

    https://github.com/kuanyui/moe-theme.el


= Requirements ==============================================================

  - Emacs 24 (or above)
  - 256 colors terminal (or higher)

= Usage =====================================================================

  Add you to your .emacs:

     (require 'moe-theme)
     (moe-dark)
         or
     (moe-light)

  But if you want to install manually, add this first:

     (add-to-list 'custom-theme-load-path "~/path/to/moe-theme")
     (add-to-list 'load-path "~/path/to/moe-theme")

= Customizations ============================================================

   It's impossible to satisfy everyone with one theme, so `moe-theme` provide
   some customizations that you may like.

   ### Resize Titles ########################################################

   You may want to resize the titles in `markdown-mode', `org-mode', or
   `rst-mode':

     (setq moe-theme-resize-markdown-title '(2.0 1.7 1.5 1.3 1.0 1.0))
     (setq moe-theme-resize-org-title '(2.2 1.8 1.6 1.4 1.2 1.0 1.0 1.0 1.0))
     (setq moe-theme-resize-rst-title '(2.0 1.7 1.5 1.3 1.1 1.0))

   Markdown should have 6 items; org has 9 items; rst has 6 items.

   The values should be lists. Larger the values, larger the fonts.
   If you don't like this, just leave them nil, and all the titles will be
   the same size.

   ### Colorful Mode-line and Powerline #####################################

   Tired of boring blue mode-line? Set default mode-line color like this:

     (setq moe-theme-mode-line-color 'orange)

   Available colors: blue, orange, magenta, yellow, purple, red, cyan, w/b.

   You can use `moe-theme-select-color' to change color interactively.

   Mayby you'll also like `moe-theme-random-color', which gives you a
   random mood :D.

   ### Powerline ############################################################

   Now we supports Powerline (https://github.com/milkypostman/powerline),
   which makes mode-line looks fabulous! We recommended installing Powerline
   and run `powerline-moe-theme'.

   ### Too Yellow Background? ###############################################

   With 256-colors, default yellow background of moe-light may be too yellow
   and harsh to eyes on some screens.

   If you encounter this problem, and want to set background color to #ffffff
   in terminal, set the value of `moe-light-pure-white-background-in-terminal'
   to t:

       (setq moe-light-pure-white-background-in-terminal t)

   ### Highlight Buffer-id on Mode-line? ####################################

   You may be dislike default highlight on mode-line-buffer-id, now it can be
   disable:

       (setq moe-theme-highlight-buffer-id nil)


= Auto Switching ============================================================

  I prefer a terminal with a black-on-white color scheme. I found that in the
daytime, sunlight is strong and black-on-white is more readable; However,
white-on-black would be less harsh to the eyes at night.

  So if you like, you can add the following line to your ~/.emacs to
automatically switch between moe-dark and moe-light according to the system
time:

   (require 'moe-theme-switcher)

  By adding the line above, your Emacs will have a light theme in the day
 and a dark one at night. =w=+


# Live in Antarctica? #######################################################

  Daytime is longer in summer but shorter in winter; or you live in a high
latitude region which midnight-sun or polar-night may occur such as Finland
or Antarctica?

  There's a variable `moe-theme-switch-by-sunrise-and-sunset` would solve
your problem (default value is `t`)

  If this value is `nil`, `moe-theme-switcher` will switch theme at fixed
time (06:00 and 18:00).

  If this value is `t` and both `calendar-latitude` and `calendar-longitude`
are set properly, the switching will be triggered at the sunrise and sunset
time of the local calendar.

  Take "Keelung, Taiwan" (25N,121E) for example, you can set like this:

	(setq calendar-latitude +25)
	(setq calendar-longitude +121)
