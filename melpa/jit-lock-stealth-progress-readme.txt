This package exposes a buffer-local variable that can be used to access
the progress of stealthy fontifications (used when `jit-lock-stealth-time' is non-nil).
This can the be displayed in the mode-line to indicate the state of fontification.

; Usage

(jit-lock-stealth-progress-mode) ; Expose jit-lock-progress.
This will show the value of `jit-lock-stealth-progress-info' in the mode-line.
