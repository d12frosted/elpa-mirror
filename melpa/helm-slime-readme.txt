
A Helm for SLIME.

The complete command list:

 `helm-slime-complete'
   Select a symbol from the SLIME completion systems.
 `helm-slime-list-connections'
   Yet another `slime-list-connections' with `helm'.
 `helm-slime-apropos'
   Yet another `slime-apropos' with `helm'.
 `helm-slime-repl-history'
   Select an input from the SLIME repl's history and insert it.
 `helm-slime-mini'
   Like `helm-slime-list-connections', but include an extra
   source of SLIME-related buffers, like the events buffer or the scratch buffer.

; Installation:

Add helm-slime.el to your load-path.
Set up SLIME properly.
Call `slime-setup' and include 'helm-slime as the arguments:

  (slime-setup '([others contribs ...] helm-slime))

or simply require helm-slime in some appropriate manner.

To use Helm instead of the Xref buffer, enable `global-helm-slime-mode'.
