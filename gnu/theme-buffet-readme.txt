Theme-Buffet lets the user specify different time periods of the day and for
each period, a list of preferred themes to be randomly loaded accordingly.
To install you just have to clone the repo from the url, add the path to the
'load-path variable and then require the library.  Here's an example, for
those who still love the Emacs 28 or earlier way of doing things:

   # In the terminal
   git clone https://git.sr.ht/~bboal/theme-buffet ~/.emacs.d/theme-buffet

   ;; In Emacs, evaluate
   (add-to-list 'load-path "~/.emacs.d/theme-buffet")
   (require 'theme-buffet)

The newest way, from Emacs 29 onward:

   (package-vc-install "https://git.sr.ht/~bboal/theme-buffet")

There are two templates preconfigured available for usage.  One enabled by
default, with the standard themes that come with vanilla Emacs; the other
more fancier, can be easily enabled by evaluating the following:

	  (setq theme-buffet-menu 'modus-ef)

The binding above will set the themes to be either Modus or Ef, authored by
Protesilaos Stavrou <https://git.sr.ht/~protesilaos>, distributed across six
periods of the day (night, twilight, morning, day, afternoon and evening).
The library will not require the aforementioned package, you will have to
install it manual if you intent to use it.  Finally to start using
Theme-Buffet, evaluate:

   (theme-buffet-mode 1)

Following the appanage way of Emacs, both the names and number of themes and
time periods can be freely changed while mantaining the same structure.
There is also a time-offset that can be set by the user to match a specific
time-zone/personal preference.  E.g

   (setq theme-buffet-time-offset 2)

All this can be achieved by tweaking `theme-buffet-end-user'.  For
inspiration, take a look at `theme-buffet--modus-ef' which is used when
setting `theme-buffet-menu' to 'modus-ef like demonstrated above.


Usage:

There are several interactive functions available to the user serving as
entry points to the package.

To set the menu for the desired themes property list and have the themes
change when the periods do: `theme-buffet-built-in',
`theme-buffet-modus-ef' and `theme-buffet-end-user'.

To set the timer for a certain time interval of hours or minutes:
`theme-buffet-timer-hours' or `theme-buffet-timer-mins'.

To load a theme from the current period: `theme-buffet-a-la-carte'.  If
instead you want to load a random theme from a prompted period, there's
`theme-buffet-order-other-period'.  To load an existing random theme use
`theme-buffet-anything-goes'.

Some examples in lisp:

   (theme-buffet-modus-ef) ; to set the theme plist to Modus and Ef
   (theme-buffet-timer-mins 30) ; to change theme every 30m from now
   (theme-buffet-timer-hours 2) ; to also change every 2h from now

Interactively, as an example, you would press M-x
`theme-buffet-order-other-period'.  Then, after choosing any defined period,
you would get returned a random loaded theme from the aforementioned period.


Disclaimer from Bruno Boal to the reader: This package was produced during my
learning sessions with Protesilaos "Prot" Stavrou and improved as homework.
Most of the credit goes to him, the mistakes you may find are my own.
Personally, despite the disadvantages and advantages of not being a
professional programmer, it is essential for me to always have fun and
enjoyment during learning and programming.  In this respect, mission
accomplished, a big "thank you!" to my mentor.  Also, keep in mind at least
two things - the fact that this package, like many others before it, has its
genesis in a collective effort, with didatic purposes and personal use in
mind, but also that future improvements could and should come from people
like you, a user of free software.

Happy hacking!