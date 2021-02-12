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

; Notes about the implementation:

The implementation is pretty straightforward and mostly consists of
functions to find permutations and subsets of words; I'm sure this
could be made much faster.

The most important aspect for game play is actually the word list:
in order for the game to be fun it must know all the words you can
think of, but not have too many obscure words.  It turns out to be
surprisingly difficult to find that balance.  My approach is as
follows:

1. Take the SIL english word list and intersect it with the New
   Oxford English Dictionary which comes with mac osx.  I then
   removed the three letter words which were obviously acronyms,
   abbreviations for longer words, or racial slurs.  This is the
   "expert" word list and contains about 85,000 words.
   (source: http://www-01.sil.org/linguistics/wordlists/english/)

2. Take the "8" word list from
   http://www.keithv.com/software/wlist/ and intersect it with the
   "expert" list.  This becomes the "hard" list and contains about
   47,000 words.

3. Take the "9" word list from the above link and intersect with
   with the "expert" list.  This is the "medium" list and contains
   about 36,000 words.

4. Take the "10" word list from the above link and intersect it
   with the "expert" list.  This contains 21,000 words and is the
   "easy" list.

Let me know how you find the difficulty levels -- I'd really
appreciate the feedback!

; Installation:

Use package.el. You'll need to add MELPA to your archives:

(require 'package)
(add-to-list 'package-archives
             '("melpa" . "http://melpa.milkbox.net/packages/") t)

Alternatively, you can just save this file and do the standard
(add-to-list 'load-path "/path/to/jumblr.el")
(require 'jumblr)

; Customization:

See the defvar definitions at the beginning of the source code.
For example, to switch the dictionary, add the following to your
.emacs:

(setq jumblr-dict-file "dict/easy.txt")
