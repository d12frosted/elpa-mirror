Casual Suite is an umbrella package to support a single installation point
for all Casual user interfaces for Emacs.

INSTALL

Casual Suite versions 3.0 or greater offer a simplified installation with the
command `casual-suite-init'. By default this command will setup interfaces
for all supported Casual modules, both built-in modes/modules and 3^{rd}
party. Run this via `execute-execute-command' (M-x) or add the following
Elisp to your Emacs initialization file.

  (require 'casual-suite)
  (casual-suite-init)

Note that `casual-suite-init' will only work if Casual Suite is installed via
`package-install'.
