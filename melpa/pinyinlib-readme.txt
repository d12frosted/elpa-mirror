                             ______________

                              PINYINLIB.EL

                              Junpeng Qiu
                             ______________


Table of Contents
_________________

1 Functions
.. 1.1 `pinyinlib-build-regexp-char'
.. 1.2 `pinyinlib-build-regexp-string'
2 Packages that Use This Library
3 Acknowledgment
4 Contribute


[[file:https://melpa.org/packages/pinyinlib-badge.svg]]
[[file:https://stable.melpa.org/packages/pinyinlib-badge.svg]]

Library for converting first letter of Pinyin to Simplified/Traditional
Chinese characters.


[[file:https://melpa.org/packages/pinyinlib-badge.svg]]
https://melpa.org/#/pinyinlib

[[file:https://stable.melpa.org/packages/pinyinlib-badge.svg]]
https://stable.melpa.org/#/pinyinlib


1 Functions
===========

1.1 `pinyinlib-build-regexp-char'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  `pinyinlib-build-regexp-char' converts a letter to a regular
  expression containing all the Chinese characters whose pinyins start
  with the letter.  It accepts five parameters:
  ,----
  | char &optional no-punc-p tranditional-p only-chinese-p mixed-p
  `----

  The first parameter `char' is the letter to be converted.  The latter
  four parameters are optional.
  - If `no-punc-p' is `t': it will not convert English punctuations to
    Chinese punctuations.

  - If `traditional-p' is `t': traditional Chinese characters are used
    instead of simplified Chinese characters.

  - If `only-chinese-p' is `t': the resulting regular expression doesn't
    contain the English letter `char'.

  - If `mixed-p' is `t': the resulting regular expression will mix
    traditional and simplified Chinese characters. This parameter will take
    precedence over `traditional-p'.

  When converting English punctuactions to Chinese/English punctuations,
  it uses the following table:
   English Punctuation  Chinese & English Punctuations
  -----------------------------------------------------
   .                    。.
   ,                    ，,
   ?                    ？?
   :                    ：:
   !                    ！!
   ;                    ；;
   \\                   、\\
   (                    （(
   )                    ）)
   <                    《<
   >                    》>
   ~                    ～~
   '                    ‘’「」'
   "                    “”『』\"
   *                    ×*
   $                    ￥$


1.2 `pinyinlib-build-regexp-string'
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  It is same as `pinyinlib-build-regexp-char', except that its first
  parameter is a string so that it can convert a sequence of letters to
  a regular expression.


2 Packages that Use This Library
================================

  - [ace-pinyin]
  - [evil-find-char-pinyin]
  - [find-by-pinyin-dired]
  - [pinyin-search]


[ace-pinyin] https://github.com/cute-jumper/ace-pinyin

[evil-find-char-pinyin]
https://github.com/cute-jumper/evil-find-char-pinyin

[find-by-pinyin-dired]
https://github.com/redguardtoo/find-by-pinyin-dired

[pinyin-search] https://github.com/xuchunyang/pinyin-search.el


3 Acknowledgment
================

  - The ASCII char to Chinese character
    table(`pinyinlib--simplified-char-table' in code) is from
    [https://github.com/redguardtoo/find-by-pinyin-dired].
  - @erstern adds the table for traditional Chinese characters.


4 Contribute
============

  Contributions are always welcome.  If you want to add some common
  pinyin related functions that might be useful for other packages,
  please send me a PR.
