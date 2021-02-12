
* About eprime-mode

An E-prime checking mode for Emacs.
Read more here - https://en.wikipedia.org/wiki/E-prime.
Naturally, all of this file that can, conforms to E'.

Adds the following functionality:

  - M-x eprime-check-buffer to check the buffer

  - A minor mode, eprime-mode, which checks the buffer and
    any text you enter thereafter.

  - M-x eprime-remove corrections to remove its corrections

  - Customisable face for banned words. eprime-banned-words-face

  - M-x eprime-check-word to check only the current word

  - Can customise banned words (by pushing onto eprime-baned-words)

  - Default different face than FlySpell for ease of use together
