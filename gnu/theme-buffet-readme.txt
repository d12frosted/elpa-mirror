The theme-buffet package arranges to automatically change themes during
specific times of the day or at fixed intervals.  The collection of themes is
customisable, with the default options covering the built-in Emacs themes as
well as Prot's modus-themes and ef-themes.

Usage:

There are several interactive functions available to the user serving as
entry points to the package.

To set the menu for the desired themes property list and have the themes
change when the periods do: `theme-buffet-built-in',
`theme-buffet-modus-ef' and `theme-buffet-end-user'.

To set the timer for a certain time interval of hours or minutes:
`theme-buffet-timer-hours' or `theme-buffet-timer-mins' functions.

To load a theme from the current period: `theme-buffet-a-la-carte'.  If
instead you want to load a random theme from a prompted period, there's
`theme-buffet-order-other-period'.  To load an existing random theme use
`theme-buffet-anything-goes'.

Some examples in lisp:

   (theme-buffet-modus-ef) ; to set the theme plist to Modus and Ef
   (theme-buffet-timer-mins 30) ; to change theme every 30m from now
   (theme-buffet-timer-hours 2) ; to also change every 2h from now

Take a moment to actually look into the code and use the `customize-group'
option to tweak all the variables if needed.

For inspiration or constructive criticism, here is the developer's
installation/configuration `use-package' snippet:

   (use-package theme-buffet
     :demand t
     :functions calendar-current-time-zone
     theme-buffet-modus-ef theme-buffet-timer-hours
     :config
     (require 'cal-dst)
     (setopt theme-buffet-time-offset
             (1+ (/ (cadr (calendar-current-time-zone)) 60)))
     (theme-buffet-modus-ef)
     (theme-buffet-timer-hours 1))


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