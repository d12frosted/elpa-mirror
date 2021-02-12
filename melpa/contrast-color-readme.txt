
This package only provide a single function that return a contrast
color using CIEDE2000 algorithm.


Usage:

  (contrast-color "#ff00ff") ; -> "#1b5e20"

                 or

  (contrast-color "Brightmagenta") ; -> "#1b5e20"


Note that as default color candidates, this package uses
‘contrast-color-material-colors’ variable, which is defined based
on Google’s material design, but if you want to change this color
definition you can do like this:

   (contrast-color-set '("black" "white"))

But keep in mind that providing many colors may increase calculation time.
