M-x current-word-highlight-mode or M-x global-current-word-highlight-mode
Enabling it in a hook is recommended.  But you don't want it enabled
for all buffers, just programming ones.
Example:
(add-hook 'prog-mode-hook 'current-word-highlight-mode)

I referred to idle-highlight-mode(by Phil Hagelberg, Cornelius Mika) for highlighting and commentary.
