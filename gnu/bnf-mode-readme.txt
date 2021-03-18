* BNF Mode for GNU Emacs

[[https://www.gnu.org/licenses/gpl-3.0.txt][https://img.shields.io/badge/license-GPL_3-green.svg]]
[[https://github.com/sergeyklay/bnf-mode/actions][https://github.com/sergeyklay/bnf-mode/workflows/build/badge.svg]]
[[https://codecov.io/gh/sergeyklay/bnf-mode][https://codecov.io/gh/sergeyklay/bnf-mode/branch/master/graph/badge.svg]]
[[https://melpa.org/#/bnf-mode][https://melpa.org/packages/bnf-mode-badge.svg]]
[[https://stable.melpa.org/#/bnf-mode][https://stable.melpa.org/packages/bnf-mode-badge.svg]]

A GNU Emacs major mode for editing BNF grammars.

#+begin_quote
“Precise language is not the problem.  Clear language is the problem.”

Richard Feynman
#+end_quote

Currently provides basic syntax and font-locking for BNF files.  BNF notation is
supported exactly form as it was first announced in the ALGOL 60 report.
EBNF and ABNF are not supported but their implementation is planned in the near
future.

When developing this mode, the following documents were taken into account:

- [[https://www.masswerk.at/algol60/report.htm][Revised Report on the Algorithmic Language Algol 60]]
- [[https://tools.ietf.org/html/rfc822][RFC822]]: Standard for ARPA Internet Text Messages
- [[https://tools.ietf.org/html/rfc5234][RFC5234]]: Augmented BNF for Syntax Specifications: ABNF
- [[https://tools.ietf.org/html/rfc7405][RFC7405]]: Case-Sensitive String Support in ABNF

** Features

- Basic syntax definition
- Syntax highlighting

** Installation

Known to work with GNU Emacs 24.3 and later.  BNF Mode may work with
older versions of Emacs, or with other flavors of Emacs (e.g. XEmacs)
but this is /not/ guaranteed.  Bug reports for problems related to using
BNF Mode with older versions of Emacs will most like not be addressed.

The master of all the material is the Git repository at
https://github.com/sergeyklay/bnf-mode .

NOTE: The ~master~ branch will always contain the latest unstable version.
If you wish to check older versions or formal, tagged release, please switch
to the relevant [[https://github.com/sergeyklay/bnf-mode/tags][tag]].

The recommended way is to use [[https://elpa.gnu.org/][ELPA]], [[https://stable.melpa.org/][MELPA Stable]] or [[https://melpa.org/][MELPA]]. If either is in your
=package-archives=, do:

#+begin_src
M-x package-install RET bnf-mode RET
#+end_src

To learn on how to use any other installation methods refer to relevant
documentation.

** Usage

*** Interactive Commands

| Command (For the ~M-x~ prompt.) | Description                      |
|---------------------------------+----------------------------------|
| ~bnf-mode~                      | Switches to BNF Mode.            |

By default any file that matches the glob ~*.bnf~ is automatically opened
in ~bnf-mode~.

** Customization

To customize various options, use command as follows:

#+begin_src
M-x customize-group RET bnf RET
#+end_src

** Support

Feel free to ask question or make suggestions in our [[https://github.com/sergeyklay/bnf-mode/issues][issue tracker]] .

** Changes

To see what has changed in recent versions of BNF Mode see:
https://github.com/sergeyklay/bnf-mode/blob/master/NEWS .

** External Links

- [[https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form][Wikipedia: Backus–Naur form]]
- [[https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form][Wikipedia: Extended Backus–Naur form]]
- [[https://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_form][Wikipedia: Augmented Backus–Naur form]]
- [[https://www.cl.cam.ac.uk/~mgk25/iso-14977.pdf][ISO/IEC 14977: EBNF]]
- [[https://www.ics.uci.edu/~pattis/ICS-33/lectures/ebnf.pdf][EBNF: A Notation to Describe Syntax]]

** License

BNF Mode is open source software licensed under the [[https://github.com/sergeyklay/bnf-mode/blob/master/LICENSE][GNU General Public Licence version 3]].
Copyright © 2019, 2020, Free Software Foundation, Inc.

*** Note On Copyright Years

In copyright notices where the copyright holder is the Free Software Foundation,
then where a range of years appears, this is an inclusive range that applies to
every year in the range.  For example: 2005-2008 represents the years 2005,
2006, 2007, and 2008.
