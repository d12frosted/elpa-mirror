This package provides an interface to the ArchLinux package manager.

Put this in your .emacs file to enable autoloading of pkgbuild-mode
and auto-recognition of "PKGBUILD" files:

 (autoload 'pkgbuild-mode "pkgbuild-mode.el" "PKGBUILD mode." t)
 (setq auto-mode-alist (append '(("/PKGBUILD$" . pkgbuild-mode))
                               auto-mode-alist))
