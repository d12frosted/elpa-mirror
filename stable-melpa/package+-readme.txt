Provides extensions to `package.el` for Emacs 24 and later.

Declares a manifest of packages that should be installed on this
system, installing any missing packages and removing any installed
packages that are not in the manifest.

This makes it easy to keep a list of packages under version control
and replicated across all your environments, without having to have
all the packages themselves under version control.

Example:

(package-initialize)
(add-to-list 'package-archives
'("melpa" . "http://melpa.milkbox.net/packages/") t)
(unless (package-installed-p 'package+)
(package-install 'package+))

(package-manifest 'ag
'expand-region
'magit
'melpa
'package+
'paredit
'ruby-mode
'ssh
'window-number)
