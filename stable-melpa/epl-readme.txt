A package management library for Emacs, based on package.el.

The purpose of this library is to wrap all the quirks and hassle of
package.el into a sane API.

The following functions comprise the public interface of this library:

; Package directory selection

`epl-package-dir' gets the directory of packages.

`epl-default-package-dir' gets the default package directory.

`epl-change-package-dir' changes the directory of packages.

; Package system management

`epl-initialize' initializes the package system and activates all
packages.

`epl-reset' resets the package system.

`epl-refresh' refreshes all package archives.

`epl-add-archive' adds a new package archive.

; Package objects

Struct `epl-requirement' describes a requirement of a package with `name' and
`version' slots.

`epl-requirement-version-string' gets a requirement version as string.

Struct `epl-package' describes an installed or installable package with a
`name' and some internal `description'.

`epl-package-version' gets the version of a package.

`epl-package-version-string' gets the version of a package as string.

`epl-package-summary' gets the summary of a package.

`epl-package-requirements' gets the requirements of a package.

`epl-package-directory' gets the installation directory of a package.

`epl-package-from-buffer' creates a package object for the package contained
in the current buffer.

`epl-package-from-file' creates a package object for a package file, either
plain lisp or tarball.

`epl-package-from-descriptor-file' creates a package object for a package
description (i.e. *-pkg.el) file.

; Package database access

`epl-package-installed-p' determines whether a package is installed, either
built-in or explicitly installed.

`epl-package-outdated-p' determines whether a package is outdated, that is,
whether a package with a higher version number is available.

`epl-built-in-packages', `epl-installed-packages', `epl-outdated-packages'
and `epl-available-packages' get all packages built-in, installed, outdated,
or available for installation respectively.

`epl-find-built-in-package', `epl-find-installed-packages' and
`epl-find-available-packages' find built-in, installed and available packages
by name.

`epl-find-upgrades' finds all upgradable packages.

`epl-built-in-p' return true if package is built-in to Emacs.

; Package operations

`epl-install-file' installs a package file.

`epl-package-install' installs a package.

`epl-package-delete' deletes a package.

`epl-upgrade' upgrades packages.
