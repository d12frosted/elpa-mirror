Find as many word as possible in a 100 seconds.  Words are scored by
length and the scrablle letter value.

M-x 100secwp to start the game

You need to have aspell installed, it will check for valid words.

THANKS:

Inspiration from an Android game written by SpiceLabs http://spicelabs.in

I dedicate this code to my grandmother who taught me to play Scrabble

BUGS:

INSTALLATION:

Use ELPA

install aspell english dictionary.  On Ubuntu or Debian type the following:

sudo apt-get install aspell aspell-en

TODO

 - add other languages such as french
 - input letter one by one like the original game
 - really stop after 100 seconds
 - display something more fancy with letter points (SVG would be cool!)
 - use ispell.el
 - display best possible score on a given deck at the end of the game
 - use gamegrid.el for dealing with high score
 - use defcustom for variables
 - add unit testing
 - use global state less (functional style programming)
 - clock ticks with timer
 - use face to display picked letter
   (insert (propertize "foo" 'face 'highlight))
 - kill score buffer when quiting
 - use a list instead of a string for the deck letters
 - add command to shuffle the deck
 - navigate to source code in other window to pretend working while playing

search for TODO within the file

VERSION

version 1

version 1.1

bump version number to see if it gets published