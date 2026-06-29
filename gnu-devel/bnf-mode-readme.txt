1 BNF Mode for GNU Emacs
════════════════════════

  [https://img.shields.io/badge/license-GPL_3-green.svg]
  [https://github.com/sergeyklay/bnf-mode/workflows/build/badge.svg]
  [https://elpa.gnu.org/packages/bnf-mode.svg]
  [https://melpa.org/packages/bnf-mode-badge.svg]
  [https://stable.melpa.org/packages/bnf-mode-badge.svg]

  A GNU Emacs major mode for editing BNF grammars.

        “Precise language is not the problem.  Clear language is
        the problem.”

        Richard Feynman

  Currently provides basic syntax and font-locking for BNF files.  BNF
  notation is supported exactly form as it was first announced in the
  ALGOL 60 report.  EBNF and ABNF are not supported but their
  implementation is planned in the near future.

  When developing this mode, the following documents were taken into
  account:

  • [Revised Report on the Algorithmic Language Algol 60]
  • [RFC822]: Standard for ARPA Internet Text Messages
  • [RFC5234]: Augmented BNF for Syntax Specifications: ABNF
  • [RFC7405]: Case-Sensitive String Support in ABNF


[https://img.shields.io/badge/license-GPL_3-green.svg]
<https://www.gnu.org/licenses/gpl-3.0.txt>

[https://github.com/sergeyklay/bnf-mode/workflows/build/badge.svg]
<https://github.com/sergeyklay/bnf-mode/actions>

[https://elpa.gnu.org/packages/bnf-mode.svg]
<https://elpa.gnu.org/packages/bnf-mode.html>

[https://melpa.org/packages/bnf-mode-badge.svg]
<https://melpa.org/#/bnf-mode>

[https://stable.melpa.org/packages/bnf-mode-badge.svg]
<https://stable.melpa.org/#/bnf-mode>

[Revised Report on the Algorithmic Language Algol 60]
<https://www.masswerk.at/algol60/report.htm>

[RFC822] <https://tools.ietf.org/html/rfc822>

[RFC5234] <https://tools.ietf.org/html/rfc5234>

[RFC7405] <https://tools.ietf.org/html/rfc7405>

1.1 Features
────────────

  • Basic syntax definition
  • Syntax highlighting


1.2 Installation
────────────────

  The current version of BNF Mode known to work with GNU Emacs 27.1 and
  later.  It may still function with older versions of Emacs, or with
  other flavors of Emacs (e.g. XEmacs) but this is /not/ guaranteed.
  Bug reports for problems related to using this version of BNF Mode
  with older versions of Emacs will most like not be addressed.

  The master of all the material is the Git repository at
  <https://github.com/sergeyklay/bnf-mode> .

  NOTE: The `main' branch will always contain the latest unstable
  version.  If you wish to check older versions or formal, tagged
  release, please switch to the relevant [tag].

  The recommended way is to use [ELPA], [MELPA Stable] or [MELPA]. If
  either is in your `package-archives', do:

  ┌────
  │ M-x package-install RET bnf-mode RET
  └────

  To learn on how to use any other installation methods refer to
  relevant documentation.


[tag] <https://github.com/sergeyklay/bnf-mode/tags>

[ELPA] <https://elpa.gnu.org/>

[MELPA Stable] <https://stable.melpa.org/>

[MELPA] <https://melpa.org/>


1.3 Usage
─────────

1.3.1 Interactive Commands
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
   Command (For the `M-x' prompt.)  Description           
  ────────────────────────────────────────────────────────
   `bnf-mode'                       Switches to BNF Mode. 
  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  By default any file that matches the glob `*.bnf' is automatically
  opened in `bnf-mode'.


1.4 Customization
─────────────────

  To customize various options, use command as follows:

  ┌────
  │ M-x customize-group RET bnf RET
  └────


1.5 Support
───────────

  Feel free to ask question or make suggestions in our [issue tracker] .


[issue tracker] <https://github.com/sergeyklay/bnf-mode/issues>


1.6 Changes
───────────

  To see what has changed in recent versions of BNF Mode see:
  <https://github.com/sergeyklay/bnf-mode/blob/main/NEWS> .


1.7 External Links
──────────────────

  • [Wikipedia: Backus–Naur form]
  • [Wikipedia: Extended Backus–Naur form]
  • [Wikipedia: Augmented Backus–Naur form]
  • [ISO/IEC 14977: EBNF]
  • [EBNF: A Notation to Describe Syntax]


[Wikipedia: Backus–Naur form]
<https://en.wikipedia.org/wiki/Backus%E2%80%93Naur_form>

[Wikipedia: Extended Backus–Naur form]
<https://en.wikipedia.org/wiki/Extended_Backus%E2%80%93Naur_form>

[Wikipedia: Augmented Backus–Naur form]
<https://en.wikipedia.org/wiki/Augmented_Backus%E2%80%93Naur_form>

[ISO/IEC 14977: EBNF] <https://www.cl.cam.ac.uk/~mgk25/iso-14977.pdf>

[EBNF: A Notation to Describe Syntax]
<https://www.ics.uci.edu/~pattis/ICS-33/lectures/ebnf.pdf>


1.8 License
───────────

  BNF Mode is open source software licensed under the [GNU General
  Public Licence version 3].  Copyright © 2019, 2020, 2021, 2022, 2023,
  2024 Free Software Foundation, Inc.


[GNU General Public Licence version 3]
<https://github.com/sergeyklay/bnf-mode/blob/main/LICENSE>

1.8.1 Note On Copyright Years
╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌

  In copyright notices where the copyright holder is the Free Software
  Foundation, then where a range of years appears, this is an inclusive
  range that applies to every year in the range.  For example: 2005-2008
  represents the years 2005, 2006, 2007, and 2008.
