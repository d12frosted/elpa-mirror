Provides async shell command completion using fzf-native for scoring.
The native layer handles process I/O on a background thread, ANSI
stripping, and parallel fzf scoring.  The Elisp layer provides
while-no-input responsiveness, a candidate cap, and a live stats overlay.

Quick start:
  (fzfa-setup)   ; register completion style + category override
  (fzfa-find-files)
