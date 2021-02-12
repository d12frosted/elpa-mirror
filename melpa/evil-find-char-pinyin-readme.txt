                        _______________________

                         EVIL-FIND-CHAR-PINYIN

                              Junpeng Qiu
                        _______________________


Table of Contents
_________________

1 Installation
2 Usage
3 Optional `evil-snipe' Integration
4 Config
.. 4.1 Enable Traditional Chinese Support
.. 4.2 Disable Punctuaction Support
5 Related Packages


Evil's f/F/t/T commands with Pinyin support, with optional [evil-snipe]
integration.

让 Evil 的 f/F/t/T 命令支持拼音首字母搜索。 可选的对 [evil-snipe] 的支持。


[evil-snipe] https://github.com/hlissner/evil-snipe


1 Installation
==============

  Recommendation: Install from [melpa].

  If you install this package manually:
  ,----
  | (add-to-list 'load-path "/path/to/evil-find-char-pinyin.el")
  | (require 'evil-find-char-pinyin)
  `----


[melpa] http://melpa.org


2 Usage
=======

  To enable the mode:
  ,----
  | (evil-find-char-pinyin-mode +1)
  `----

  After you enable the mode, `evil''s f/F/t/T commands are able to jump
  to Chinese characters by their Pinyin. You can also use `;' and =,= to
  repeat the last f/F/t/T command.

  For example (`|' is the location of the cursor):
  ,----
  | |我能吞下玻璃而不伤身体。
  `----

  `dft' will delete `我能吞' .

  It also supports Chinese punctuactions:
  ,----
  | |我能吞下玻璃而不伤身体。
  `----

  `dt.' will delete up to `。'.

  This package uses [pinyinlib.el] behind the scene to translate the
  letter to Simplified/Traditional Chinese characters and English
  punctuations to Chinese punctuations. To see the full list of Chinese
  punctuations that are supported, look at [pinyinlib.el].


[pinyinlib.el] https://github.com/cute-jumper/pinyinlib.el


3 Optional `evil-snipe' Integration
===================================

  If you're using [evil-snipe] for 2-char searching in evil, you can
  enable `evil-snipe' integration:
  ,----
  | (evil-find-char-pinyin-toggle-snipe-integration t)
  `----

  Use `nil' as the parameter to disable the integration.

  After enabling this feature, all of `evil-snipe''s commands:
  - `evil-snipe-repeat' and `evil-snipe-repeat-reverse'
  - `evil-snipe-s' and `evil-snipe-S'
  - `evil-snipe-x' and `evil-snipe-X'
  - `evil-snipe-f' and `evil-snipe-F'
  - `evil-snipe-t' and `evil-snipe-T'
  are able to search Chinese characters by letters.


[evil-snipe] https://github.com/hlissner/evil-snipe


4 Config
========

4.1 Enable Traditional Chinese Support
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  By default, only Simplifed Chinese charaters are supported. To enable
  Traditional Chinese support:
  ,----
  | (setq evil-find-char-pinyin-only-simplified nil)
  `----


4.2 Disable Punctuaction Support
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

  If you don't want the punctuation support, use:
  ,----
  | (setq evil-find-char-pinyin-enable-punctuation-translation nil)
  `----


5 Related Packages
==================

  - [pinyinlib.el]
  - [ace-pinyin]
  - [find-by-pinyin-dired]
  - [pinyin-search]
  - [fcitx.el]


[pinyinlib.el] https://github.com/cute-jumper/pinyinlib.el

[ace-pinyin] https://github.com/cute-jumper/ace-pinyin

[find-by-pinyin-dired]
https://github.com/redguardtoo/find-by-pinyin-dired

[pinyin-search] https://github.com/xuchunyang/pinyin-search.el

[fcitx.el] https://github.com/cute-jumper/fcitx.el
