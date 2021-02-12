This is for people trying to type Turkish documents on a U.S.
keyboard.

; Installation:

If you have `melpa' and `emacs24' installed, simply type:

	M-x package-install turkish

Add following lines to your init file:

    (require 'turkish)
Then turn on the turkish mode:
      M-x turkish-mode


Emacs Turkish Extension (c) Deniz Yuret, 2006, 2010

In turkish-mode your words should be automatically corrected
whenever you hit space.  Alternatively you can select a region and
use M-x turkish-correct-region.  If the program makes a mistake
you can toggle a character's accent using C-t.

The program was inspired by Gokhan Tur's deasciifier:
      http://www.hlst.sabanciuniv.edu/TL/deascii.html

The program uses decision lists (included at the end of this file)
which was created based on sample Turkish news text using the GPA
algorithm.  For more information on GPA:
      http://www.denizyuret.com/pub/iscis06

Current test set accuracy is approximately 1 error every 214
corrections, or every 140 words.  (Using 1000000 training, 100000
validation instances for each letter, and 100000 out of sample
words for testing) Details on each ambiguous character is given
below.  Columns are:

(1) ambiguous character
(2) number of instances
(3) number of errors
(4) error period = (2/3)
(5) number of rules.

(c 10503 46 228 2547)
(g 11316 14 808 752)
(i 66470 322 206 2953)
(o 17298 57 303 1621)
(s 23410 151 155 3198)
(u 24395 124 196 2394)
(all 153392 714 214 13465)

Making emacs work with foreign characters is tricky business. You
need to set the coding system for three things:
(1) file coding system is set with prefer-coding-system.  Each
call adds a coding system at the front of the priority list for
automatic detection.  The last one is used for new files.
(2) set-terminal-coding-system for the terminal output.
(3) set-keyboard-coding system for keyboard input.
The following uses utf-8 as default, but will recognize latin-5
files as well:

(prefer-coding-system 'iso-latin-5)
(prefer-coding-system 'utf-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
