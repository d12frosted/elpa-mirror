	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	     WHY-THIS - WHY IS THIS LINE HERE?  ASK VERSION
				CONTROL
	   ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────

1. Screenshots
2. Install
.. 1. MELPA
.. 2. Quelpa
.. 3. Straight.el
3. Supported version control systems
4. Usage
5. Configuration


`why-this' shows why the current line was changed on the right side of
line.  It can also show editing history with heat map.


1 Screenshots
═════════════

  <file:./images/blame.png> Blame on the right side of current line.

  <file:./images/blame-region.png> Blame on the right side of each line
  in region.

  <file:./images/annotate.png> Editing history with heat map.


2 Install
═════════

2.1 MELPA
─────────

  `M-x package-refresh-contents' and `M-x package-install RET why-this'.


2.2 Quelpa
──────────

  Do `M-x quelpa RET why-this', Quelpa should get the recipe from MELPA
  and install it.


2.3 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(why-this :type git
  │ 	    :repo "https://codeberg.org/akib/emacs-why-this.git"))
  └────


3 Supported version control systems
═══════════════════════════════════

  Current only two version control systems are supported:

  • Git
  • Mercurial (note: changes must be saved to be shown)


4 Usage
═══════

  Type `M-x why-this-mode' to enable showing blame.

  Type `M-x why-this' to show blame on echo area.

  Type `M-x why-this-annotate' to show editing history on a dedicated
  buffer.


5 Configuration
═══════════════

  Put the following in your init file to enable `why-this-mode' in every
  possible buffer:

  ┌────
  │ (global-why-this-mode)
  └────

  Note: `why-this-mode' won't be enabled on unsupported buffer.

  Output by `why-this-annotate' may be hard to read depending on the
  theme.  Put the following in your init file to change the colors:

  • For dark theme users:

    ┌────
    │ (set-face-background 'why-this-annotate-heat-map-cold "#203448")
    │ (set-face-background 'why-this-annotate-heat-map-warm "#382f27")
    └────

  • For light theme users:

    ┌────
    │ (set-face-background 'why-this-annotate-heat-map-cold "#dde3f4")
    │ (set-face-background 'why-this-annotate-heat-map-warm "#f0e0d4")
    └────

  To disable the heat map:

  ┌────
  │ (setq why-this-annotate-enable-heat-map nil)
  └────

  Hovering on the message shows a tooltip, to disable it:

  ┌────
  │ (setq why-this-enable-tooltip nil)
  └────

  To get a list of all user options `M-x customize-group RET why-this'.
