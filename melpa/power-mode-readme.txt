At long last, Power Mode [1] is available for the best text editor.

* What does this do?

While `power-mode' is enabled, typing quickly and without pause will
eventually rack up a combo-meter with each keypress shaking the Emacs window
and showering each newly inserted character with explosive particles.

* Caveats

- Don't use this on EXWM or you'll regret it.

- If running Emacs as a daemon, frames might behave weirdly if shaking is
  enabled and you exit power-mode.  It's safe to close them and re-open new
  ones.

- The shaking windows feature may altogether behave terribly and ruin your
  Emacs session.  You can disable this while still retaining particle effects
  by setting `power-mode-streak-shake-threshold' to nil.

[1] https://github.com/codeinthedark/awesome-power-mode
