Table of Contents
─────────────────

1. Writegood Mode
2. Basic Usage
3. Readability tests
4. Customization
.. 1. Faces
.. 2. Weasel Words
.. 3. Passive Voice Irregulars
5. Alternatives


1 Writegood Mode
════════════════

  This is a minor mode to aid in finding common writing problems.  [Matt
  Might's weaselwords scripts] inspired this mode.

  It highlights text based on a set of weasel-words, passive-voice and
  duplicate words.


[Matt Might's weaselwords scripts]
<http://matt.might.net/articles/shell-scripts-for-passive-voice-weasel-words-duplicates/>


2 Basic Usage
═════════════

  First, load in the mode.

  ┌────
  │ (add-to-list 'load-path "path/to/writegood-mode")
  │ (require 'writegood-mode)
  │ (global-set-key "\C-cg" 'writegood-mode)
  └────


  I use the command key above to start the mode when I wish to check my
  writing.

  Alternatively, this package is also available on MELPA. If installed
  through the package manager, then only the global key customization
  would be necessary.


3 Readability tests
═══════════════════

  There are now two functions to perform [Flesch-Kincaid scoring] and
  grade-level estimation. These follow the known algorithms, but may
  differ from other implementations due to the syllable estimation.

  I use these global keys to get to the readability tests:

  ┌────
  │ (global-set-key "\C-c\C-gg" 'writegood-grade-level)
  │ (global-set-key "\C-c\C-ge" 'writegood-reading-ease)
  └────


[Flesch-Kincaid scoring]
<http://en.wikipedia.org/wiki/Flesch%E2%80%93Kincaid_readability_tests>


4 Customization
═══════════════

  The user is free to customize three main portions of the mode.


4.1 Faces
─────────

  The three faces used pull from the default warning face and add subtle
  backgrounds.  There is a separate face for each check performed.

  • Weasel words (`writegood-weasels-face')
  • Passive voice (`writegood-passive-voice-face')
  • Duplicate words (`writegood-duplicates-face')


4.2 Weasel Words
────────────────

  There is a large list of included weasel words, but you may have your
  own.  See the `write-good-weasel-words' variable to modify this list.

  Additionally, if you require more than a list of words to mark up your
  content, then there is a custom variable,
  `writegood-weasel-words-additional-regexp' that allows a custom
  regular expression for matching whatever you heart desires (expressed
  as a regex).


4.3 Passive Voice Irregulars
────────────────────────────

  There is also a list of irregular passive voice verbs.  These are the
  verbs that do not end in 'ed' to signify past tense. This variable
  allow the user to modify the list as needed.

  Similar to weasel words, the custom variable
  `writegood-passive-voice-irregulars-additional-regexp' allows the use
  of an additional regular expression to highlight passive voice
  irregulars.


5 Alternatives
══════════════

  [Artbollocks] looks to be an alternative mode to this one.


[Artbollocks] <https://github.com/sachac/artbollocks-mode>
