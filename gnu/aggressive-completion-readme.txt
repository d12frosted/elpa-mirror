Aggressive completion mode (`aggressive-completion-mode') is a minor mode
which automatically completes for you after a short delay
(`aggressive-completion-delay') and shows all possible completions using the
standard completion help (unless the number of possible completions exceeds
`aggressive-completion-max-shown-completions' or
`aggressive-completion-auto-completion-help' is set to nil).

Automatic completion is done after all commands in
`aggressive-completion-auto-complete-commands'.  The function doing
auto-completion is defined by `aggressive-completion-auto-complete-fn' which
defaults to `minibuffer-complete'.

Aggressive completion can be toggled using
`aggressive-completion-toggle-auto-complete' (bound to `M-t' by default)
which is especially useful when trying to find a not yet existing file or
switch to a new buffer.

You can switch from minibuffer to *Completions* buffer and back again using
`aggressive-completion-switch-to-completions' (bound to `M-c' by default).
All keys bound to this command in `aggressive-completion-minibuffer-map'
will be bound to `other-window' in `completion-list-mode-map' so that those
keys act as switch-back-and-forth commands.

Aggressive completion can be used together, in theory, with other completion
UIs.  Using the following configuration, it works quite well with the
vertico package:

Disable completion help since vertico shows the candidates anyhow.

(setq aggressive-completion-auto-completion-help nil)

A command which just expands the common part without selecting a candidate.

(defun th/vertico-complete ()
  (interactive)
  (minibuffer-complete)
  (when vertico--count-ov ;; Only if vertico is active.
    (vertico--exhibit)))

Use that for auto-completion.

(setq aggressive-completion-auto-complete-fn #'th/vertico-complete)

The inline help messages like "Next char not uniqe" make point bump to the
right because of vertico's overlays which is a bit annoying.  And since you
already see your candidates anyhow, the messages aren't important anyhow.

(setq completion-show-inline-help nil)