Provides language support for Yu-Gi-Oh! deck files.  These typically have a
".ydk" extension.  They are used in YGOPro and other dueling simulators.

YDK files consist of lists of newline-delimited integers.  These integers
correspond to the 8-digit "passcodes" unique to each card. (See
http://yugioh.wikia.com/wiki/Passcode for details.)  Each newline-delimited
integer represents one copy of a corresponding card in a deck.

Comments may appear anywhere in a file, starting with "#" or "!", followed by
(usually) arbitrary characters, ending with a newline.

There are three "magic" comments which typically denote the beginning of a
new deck (that is, the Main Deck, Extra Deck or Side Deck).  Conventionally,
these magic comments are of the forms:

    #main
    #extra
    !side

The magic comments are highlighted specially in this mode to make them more
distinguishable.

Putting it all together, a YDK file specifying a deck,

- created by someone named Jackson
- with the following cards in his Main Deck:
  - 3x Blue-Eyes White Dragon
  - 1x Lord of D.
  - 1x The Flute of Summoning Dragon
- and this card in his Extra Deck:
  - 1x Blue-Eyes Ultimate Dragon
- and this card in his Side Deck:
  - 1x Cipher Soldier

would look something like this:

    #created by Jackson
    #main
    89631139
    89631139
    89631139
    17985575
    43973174
    #extra
    23995346
    !side
    79853073

Also, YDK mode will calculate the total number of cards in the Main, Extra
and Side Decks (in that order), and display those totals in the modeline.
The above deck would have a modeline display of:

    (YDK[5/1/1])
