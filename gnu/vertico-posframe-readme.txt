		      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		       README OF VERTICO-POSFRAME
		      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. What is vertico-posframe
2. How to enable vertico-posframe
3. Tips
.. 1. How to show fringe to vertico-posframe





1 What is vertico-posframe
══════════════════════════

  vertico-posframe is an vertico extension, which lets vertico use
  posframe to show its candidate menu.

  NOTE: vertico-posframe requires Emacs 26 and do not support mouse
  click.


2 How to enable vertico-posframe
════════════════════════════════

  ┌────
  │ (require 'vertico-posframe)
  │ (vertico-posframe-mode 1)
  └────


3 Tips
══════

3.1 How to show fringe to vertico-posframe
──────────────────────────────────────────

  ┌────
  │ (setq vertico-posframe-parameters
  │       '((left-fringe . 8)
  │         (right-fringe . 8)))
  └────

  By the way, User can set *any* parameters of vertico-posframe with the
  help of `vertico-posframe-parameters'.
