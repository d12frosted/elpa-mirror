Calle 24 provides toolbar support for SF Symbols. It achieves this by
substituting Emacs image assets with SF Symbols by proxy.

This package is only intended to be used by Emacs (NS variant) running on
macOS.

INSTALLATION

Upon installation or subsequent updates of the package `calle24' from MELPA,
run the following command:

M-x `calle24-install'

You should restart Emacs after running the above command to see the tool bar
images replaced with their SF Symbols equivalent.

CONFIGURATION

Add the following code to your Emacs initialization to load
appearance-specific images.

(calle24-refresh-appearance)
(add-hook 'compilation-mode-hook #'calle24-refresh-appearance)

UNINSTALL

In the event that you do not wish to use Calle 24, perform the following
steps before deleting the calle24 package.

1. Remove the directory `calle24-image-directory' in `user-emacs-directory'.
2. Remove the `calle24-image-directory' from `image-load-path'.
