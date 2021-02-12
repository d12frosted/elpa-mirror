`helm-exwm' run a Helm session over the list of EXWM buffers.

To separate EXWM buffers from Emacs buffers in `helm-mini', set up the sources as follows:

  (setq helm-exwm-emacs-buffers-source (helm-exwm-build-emacs-buffers-source))
  (setq helm-exwm-source (helm-exwm-build-source))
  (setq helm-mini-default-sources `(helm-exwm-emacs-buffers-source
                                    helm-exwm-source
                                    helm-source-recentf)

`helm-exwm-switch' is a convenience X application launcher using Helm to
switch between the various windows of one or several specific applications.
See `helm-exwm-switch-browser' for an example.
