	      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
	       `CORFU-TERMINAL' - CORFU POPUP ON TERMINAL
	      ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━


Corfu uses child frames to display candidates.  This makes Corfu
unusable on terminal.  This package replaces that with popup/popon,
which works everywhere.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
 GUI                    Terminal (Colorterm)         TTY (with face customizations) 
────────────────────────────────────────────────────────────────────────────────────
 <file:./demo-gui.png>  <file:./demo-colorterm.png>  <file:./demo-tty.png>          
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

/Note: The above screenshots were taken with `kind-icon' enabled./ /And
the TTY screenshot isn't a screenshot of a real TTY, it was/ /emulated
on a terminal emulator with `TERM=linux' and `COLORTERM=',/ /and the
Corfu faces were modified to make the popup/popon visible on/ /TTY./


1 Installation
══════════════

1.1 Package
───────────

  Install from NonGNU ELPA.


1.2 Quelpa
──────────

  ┌────
  │ (quelpa '(corfu-terminal
  │ 	  :fetcher git
  │ 	  :url "https://codeberg.org/akib/emacs-corfu-terminal.git"))
  └────


1.3 Straight.el
───────────────

  ┌────
  │ (straight-use-package
  │  '(corfu-terminal
  │    :type git
  │    :repo "https://codeberg.org/akib/emacs-corfu-terminal.git"))
  └────


1.4 Manual
──────────

  Download the `corfu-terminal.el' file and put it in your `load-path'.


2 Usage
═══════

  Enable the global minor mode `M-x corfu-terminal-mode' to enable
  it. You'll probably want to enable it only on terminal.  In that case,
  put the following in your init file:

  ┌────
  │ (unless (display-graphic-p)
  │   (corfu-terminal-mode +1))
  └────


3 Complementary Packages
════════════════════════

  • [`kind-icon']: `kind-icon' adds an icon in front of each candidate
    describing the kind of the candidate.
  • [`corfu-doc'] and [`corfu-doc-terminal']: `corfu-doc' show a
    documentation popup for the current candidate.  `corfu-doc-terminal'
    provides a Popon (overlay) based display, so that you can use it on
    terminal.


[`kind-icon'] <https://github.com/jdtsmith/kind-icon>

[`corfu-doc'] <https://github.com/galeo/corfu-doc>

[`corfu-doc-terminal']
<https://codeberg.org/akib/emacs-corfu-doc-terminal>
