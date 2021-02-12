                             _____________

                               ACE-PINYIN

                              Junpeng Qiu
                             _____________


Table of Contents
_________________

1 Setup
2 Usage
3 Supported Commands
4 Traditional Chinese Characters Support
5 Disable Word Jumping Support
6 Disable Punctuations Translation
7 Other available commands
.. 7.1 `ace-pinyin-dwim'
.. 7.2 `ace-pinyin-jump-word'
8 Demos
9 Change Log
10 Related Packages


[[file:http://melpa.org/packages/ace-pinyin-badge.svg]]
[[file:http://stable.melpa.org/packages/ace-pinyin-badge.svg]]

Jump to Chinese characters using `ace-jump-mode' or `avy'.

使用 `avy' 或者 `ace-jump-mode' 跳转到中文字符。

[[file:http://melpa.org/packages/ace-pinyin-badge.svg]]
http://melpa.org/#/ace-pinyin

[[file:http://stable.melpa.org/packages/ace-pinyin-badge.svg]]
http://stable.melpa.org/#/ace-pinyin


1 Setup
=======

  Install via [melpa].

  Or if you prefer to install this package manually:
  ,----
  | (add-to-list 'load-path "/path/to/ace-pinyin.el")
  | (require 'ace-pinyin)
  `----


[melpa] http://melpa.org/#/ace-pinyin


2 Usage
=======

  By default this package is using `avy'. If you want to use
  `ace-jump-mode', set `ace-pinyin-use-avy' to `nil'.

  Note `ace-pinyin-use-avy' variable should be set *BEFORE* you call
  `ace-pinyin-global-mode' or `turn-on-ace-pinyin-mode'.

  Example config to use `ace-pinyin' globally:
  ,----
  | ;; (setq ace-pinyin-use-avy nil) ;; uncomment if you want to use `ace-jump-mode'
  | (ace-pinyin-global-mode +1)
  `----


3 Supported Commands
====================

  When using `avy', all `avy' commands (as of 05/06/2016) related to
  char/word jumping are supported:
  - `avy-goto-char'
  - `avy-goto-char-2'
  - `avy-goto-char-in-line'
  - `avy-goto-word-0'
  - `avy-goto-word-1'
  - `avy-goto-subword-0'
  - `avy-goto-subword-1'
  - `avy-goto-word-or-subword-1'

  When using `ace-jump-mode', the following command is supported:
  - `ace-jump-char-mode'

  When the `ace-pinyin-mode' is enabled, the supported commands will be
  able to jump to both Chinese and English characters/words. That is,
  you don't need remember extra commands or create extra key bindings in
  order to jump to Chinese characters. All you need to do is to enable
  the minor mode and use your `avy' or `ace-jump-mode' key bindings to
  jump to Chinese characters.

  In addition, you can also use English punctuations to jump to
  Chinese/English punctuations. For example, use `.' to jump to both `。'
  and `.', and `<' to jump to both `《' and `<' etc. Behind the scene,
  `ace-pinyin' uses [pinyinlib.el] to translate the letter to
  Simplified/Traditional Chinese characters and English punctuations to
  Chinese punctuations. To see the full list of punctuations that are
  supported, see [pinyinlib.el].

  Besides, all other packages using `ace-jump-mode' (or `avy') will also
  be able to handle Chinese characters. For example, if you've installed
  [ace-jump-zap], it will also be able to zap to a Chinese character by
  the first letter of pinyin. Note `ace-jump-zap' is implemented by
  using `ace-jump-mode', so you can't use `avy' in this case. You can
  check out my fork of `ace-jump-zap' using `avy': [avy-zap].


[pinyinlib.el] https://github.com/cute-jumper/pinyinlib.el

[ace-jump-zap] https://github.com/waymondo/ace-jump-zap

[avy-zap] https://github.com/cute-jumper/avy-zap


4 Traditional Chinese Characters Support
========================================

  By default, `ace-pinyin' only supports simplified Chinese characters.
  You can make `ace-pinyin' aware of traditional Chinese characters by
  the following setting:
  ,----
  | (setq ace-pinyin-simplified-chinese-only-p nil)
  `----


5 Disable Word Jumping Support
==============================

  By default, `ace-pinyin' will remap both word jumping and character
  jumping methods in `avy'. If you only want to remap character jumping
  methods, use:
  ,----
  | (setq ace-pinyin-treat-word-as-char nil)
  `----

  After setting this, the following commands in `avy' are not able to
  jump to Chinese characters:
  - `avy-goto-word-0'
  - `avy-goto-word-1'
  - `avy-goto-subword-0'
  - `avy-goto-subword-1'
  - `avy-goto-word-or-subword-1'


6 Disable Punctuations Translation
==================================

  If you don't like the punctuation support(/i.e./, using English
  punctuations to jump to both Chinese/English punctuations), use the
  following code to disable it:
  ,----
  | (setq ace-pinyin-enable-punctuation-translation nil)
  `----


7 Other available commands
==========================

  These commands are not provided in either `avy' or `ace-jump-mode'.
  They're provided in this package in case someone finds them useful.
  You need to assign key bindings for the commands if you want to use
  them.


7.1 `ace-pinyin-dwim'
~~~~~~~~~~~~~~~~~~~~~

  If called with no prefix, it can jump to both Chinese characters and
  English letters. If called with prefix, it can only jump to Chinese
  characters.


7.2 `ace-pinyin-jump-word'
~~~~~~~~~~~~~~~~~~~~~~~~~~

  Using this command, you can jump to the start of a sequence of Chinese
  characters(/i.e./ Chinese word) by typing the sequence of the first
  letters of these character's pinyins. If called without prefix, this
  command will read user's input with a default timeout 1 second(You can
  customize the timeout value). If called with prefix, then it will read
  input from the minibuffer and starts search after you press enter.


8 Demos
=======

  *WARNING*: The following demos are a little bit outdated.

  Enable `ace-pinyin-mode' and use `ace-jump-char-mode' to jump to
  Chinese characters: [./screencasts/ace-pinyin-jump-char.gif]

  If you have installed [ace-jump-zap], then enabling `ace-pinyin-mode'
  will also make `ace-jump-zap-to-char' capable of handling Chinese
  characters. [./screencasts/ace-jump-zap.gif]


[ace-jump-zap] https://github.com/waymondo/ace-jump-zap


9 Change Log
============

  UPDATE(2015-11-26): Now jumping to traditional Chinese characters is
  supported by setting `ace-pinyin-simplified-chinese-only-p' to `nil'.

  UPDATE(2016-05-01): Now `ace-pinyin' uses `avy' by default. If you
  want to use `ace-jump-mode', use:
  ,----
  | (setq ace-pinyin-use-avy nil)
  `----

  UPDATE(2016-05-02): A new variable `ace-pinyin-treat-word-as-char' is
  added and its default value is `t'. When this variable is `t',
  `ace-pinyin' remaps both word and character jumping commands in `avy'
  or `ace-jump-mode'. For example, if you're using `avy', setting this
  variable to `t' will make `avy-goto-word-*' and `avy-goto-subword-*'
  be able to jump to Chinese characters as well as English words.

  UPDATE(2015-05-05): Add `ace-pinyin-enable-punctuation-translation'.

  UPDATE(2015-05-05): Now `ace-pinyin' depends on [pinyinlib.el].


[pinyinlib.el] https://github.com/cute-jumper/pinyinlib.el


10 Related Packages
===================

  - [evil-find-char-pinyin]
  - [pinyinlib.el]
  - [fcitx.el]


[evil-find-char-pinyin]
https://github.com/cute-jumper/evil-find-char-pinyin

[pinyinlib.el] https://github.com/cute-jumper/pinyinlib.el

[fcitx.el] https://github.com/cute-jumper/fcitx.el
