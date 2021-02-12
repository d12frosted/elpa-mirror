                           _________________

                            WORD OF THE DAY

                              Junpeng Qiu
                           _________________


Table of Contents
_________________

1 Available Sources
2 Commands
.. 2.1 `M-x wotd-select'
.. 2.2 `M-x wotd-all'
3 Config
4 Contribution


[[file:https://melpa.org/packages/wotd-badge.svg]]

Show /Word of the Day/ from 15 online sources in Emacs!


[[file:https://melpa.org/packages/wotd-badge.svg]]
https://melpa.org/#/wotd


1 Available Sources
===================

  - Merriam Webster
  - Wiktionary
  - Macmillan Dictionary
  - Wordsmith
  - Free Dictionary
  - Oxford English Dictionary
  - Urban Dictionary
  - WordThink
  - Oxford Dictionaries
  - Cambridge Dictionary
  - Collins Dictionary
  - Learners Dictionary
  - Wordnik
  - Dictionary.com
  - Bing dict (English word, Chinese definitions.  See also
    [bing-dict.el])


[bing-dict.el] https://github.com/cute-jumper/bing-dict.el


2 Commands
==========

2.1 `M-x wotd-select'
~~~~~~~~~~~~~~~~~~~~~

  Show a word-of-the-day by selecting a source from
  `wotd-enabled-sources'.

  This works asynchronously.


2.2 `M-x wotd-all'
~~~~~~~~~~~~~~~~~~

  Show all the "word-of-the-day"s from `wotd-enabled-sources' in a
  summary buffer, which enables `orgstruct-mode' for easier navigation.

  This works synchronously.  (may be changed later)

  Screenshot: [./screenshots/summary.png]


3 Config
========

  See `wotd-supported-sources' for the complete list of all the
  supported online sources.  You can set `wotd-enabled-sources' to
  controls which sources are enabled.  By default, all the sources
  except `bing dict' are enabled.


4 Contribution
==============

  Welcome to submit PRs to add more online sources!
