	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	      `TESTCOVER-MARK-LINE' - MARK WHOLE LINE WITH
			       TESTCOVER
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Installation
.. 1. Quelpa
.. 2. Straight.el
2. Usa
.. 1. Manual


Testcover is a visual code-coverage tool, that marks the form not
completed tested.  It only highlights the last character of a form,
which sometimes don't attract attention and is hard to see, especially
when your code is heavy highlighted.  This package highlights the whole
line, which can easily get your attention.

Enable with `M-x testcover-mark-line-mode', and you're done.


1 Installation
══════════════

  `testcover-mark-line' isn't available on any ELPA right now.  So, you
  have to follow one of the following methods:


1.1 Quelpa
──────────

  ┌────
  │ (quelpa
  │  '(testcover-mark-line
  │    :fetcher git
  │    :url "https://codeberg.org/akib/emacs-testcover-mark-line.git"))
  └────


1.2 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(testcover-mark-line
  │    :type git
  │    :repo "https://codeberg.org/akib/emacs-testcover-mark-line.git"))
  └────


2 Usa
═════

2.1 Manual
──────────

  Download the `testcover-mark-line.el' file and put it in your
  `load-path'.
