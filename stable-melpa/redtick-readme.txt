This package provides a little pomodoro timer in the mode-line.

After importing, it shows a little red tick (✓) in the mode-line.
When you click on it, it starts a pomodoro timer.

It only shows the timer in the selected window (a moving timer
replicated in each window is a little bit distracting!).

I thought about this, after seeing the spinner.el package.

I tried to make it efficient:
  - It uses an elisp timer to program the next modification of the
    mode line: no polling, no sleeps...
  - Only works when the mode-line is changed.
  - It uses SOX player, that supports looping wav files without gaps.
    Thanks to the loop, I only launch a player process when starting
    the work or rest interval.
