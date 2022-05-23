	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
		`CORFU-POPUP' - CORFU POPUP ON TERMINAL
	       ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Table of Contents
─────────────────




Corfu uses child frames to display candidates.  This makes Corfu
unusable on terminal.  This package replaces that with popup/popon,
which works everywhere.  Use M-x corfu-popup-mode to enable.  You'll
probably want to enable it only on terminal.  In that case, put the
following it your init file:

┌────
│ (unless (display-graphic-p)
│   (corfu-popup-mode +1))
└────
