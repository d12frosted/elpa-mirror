pif.el is designed to prevent the Initial Flash of Light when
starting up Emacs.

After installing you need to call ~pif-early~ from ~early-init.el~.
This hides certain UI elements and sets the position and size for
the initial frame.  Next call ~pif APPEARANCE~, where APPEARANCE is
either 'light, or 'dark.  This ensures the correct colors are set
to prevent the "Initial Flash of Light".

On macOS, if your Emacs distribution supports it, invoke this
function from the ~ns-system-appearance-change-functions~-hook to
automatically apply the current mode (light or dark) based on
system settings.

In ~init.el~, call ~pif-reset~ to reset the colors and install
~pif-update APPEARANCE~ in the ~kill-emacs-hook~.  This allows pif
to save the position, size of the initial-frame, and some colors
for the next start.

Here's the exact setup that I use:

In ~early-init.el~:

(add-to-list 'load-path (expand-file-name (locate-user-emacs-file "local/pif")))
(require 'pif)
(pif-early)
(add-hook 'ns-system-appearance-change-functions #'pif)


In ~init.el~:

(when (featurep 'pif)
  (pif-reset)
  (remove-hook 'ns-system-appearance-change-functions #'pif)
  (add-hook 'kill-emacs-hook (lambda ()
                               (pif-update ns-system-appearance))))
