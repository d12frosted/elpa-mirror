This package implements Arnold G. Reinhold's diceware method for
Emacs.  For more information regarding diceware, see
http://world.std.com/~reinhold/diceware.html
Diceware (C) 1995-2020 Arnold G. Reinhold

IMPORTANT: Please read the below section to know how to use this
package, as it requires additional files *NOT* included in the base
install.  Apart from the listed requirements, this package requires (ideally)
one or more casino-grade dice for true random number generation.


Basic setup:

This package requires a so called wordlist to function as intended.
This file serves as the pool of random words from which your secure
passphrase is generated.  Put a wordlist for passphrase generation
into the directory specified by ‘dw-directory’.  It will be
automatically generated the first time this package is loaded.  If
you don't already have a wordlist, you can find two common, English
wordlists below:

https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt
http://world.std.com/%7Ereinhold/diceware.wordlist.asc

The above wordlist from the EFF is also provided as a
pre-internalized form in ‘dw-eff-large’.  If you prefer to try out
the package *without* having to download a separate file, just add
the following to your init:

(with-eval-after-load 'dw
  (setq-default dw-current-wordlist dw-eff-large))

The former generates passphrases with long, common words while the
latter favors short words and letter combinations, which may be
harder to remember but quicker to type.  You can find wordlists
for many other languages here:

http://world.std.com/~reinhold/diceware.html#Diceware%20in%20Other%20Languages|outline

Basic usage:

1) Choose a buffer to write your passphrase in (temporarily).
2) Roll your dice, reading them in some consistent way (e.g. left to
   right) every time, and typing them neatly separated in groups of
   five.  You can separate them using any character matched by
   ‘dw-separator-regexp’ (whitespace by default).  For example, if you
   rolled ⚄⚂⚀⚅⚅, type "53166".  You will need five times as many die
   rolls as you want words in your passphrase (six being a decent
   amount for normal passphrases).
3) Mark the region where you wrote down your sequence of rolls and
   use the command ‘dw-passgen-region’.  You may need to choose a
   wordlist depending on your setup.  See the documentation for
   ‘dw-named-wordlists’ below for how to skip this step and set up
   a default wordlist.

This package provides the following interactive commands:

* dw-passgen-region

   The all-in-one interactive passphrase generation command, and
   most likely everything you'll ever need from this package.  Just
   mark the region containing your written down die rolls and run
   the command.

* dw-set-wordlist

    Manually set a wordlist without invoking ‘dw-passgen-region’,
    and regardless of whether a wordlist has been set for the
    current buffer before.

Final notes:
The package itself is not at all required to create diceware
passphrases, but automates the table lookup bit of it.
