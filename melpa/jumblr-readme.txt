Provides a function `jumblr-new-game' (aliased to `jumblr') which
launches a word game closely based on the old TextTwist by Yahoo.

The interface should be pretty intuitive: it displays a sequence of
letters, along with a series of blanks.  The blanks represent words
which can be made from the letters.  You type a word and "submit"
it by either hitting SPC or RET; the word replaces one of the
blanks if it fits.  Hitting SPC or RET with an empty guess
reshuffles the letters.

I tried to make the interface pretty responsive; take a look at the
screenshots in the github repository for a sense of how it works.
