This package provides an interface for searching, getting information,
voting for, subscribing and downloading packages from the Arch User
Repository (AUR) <https://aur.archlinux.org/>.

To manually install the package, add the following to your init-file:

  (add-to-list 'load-path "/path/to/aurel-dir")
  (autoload 'aurel-package-info "aurel" nil t)
  (autoload 'aurel-package-search "aurel" nil t)
  (autoload 'aurel-package-search-by-name "aurel" nil t)
  (autoload 'aurel-maintainer-search "aurel" nil t)
  (autoload 'aurel-installed-packages "aurel" nil t)

Also set a directory where downloaded packages will be put:

  (setq aurel-download-directory "~/aur")

To search for packages, use `aurel-package-search' or
`aurel-maintainer-search' commands.  If you know the name of a
package, use `aurel-package-info' command.  Also you can display a
list of installed AUR packages with `aurel-installed-packages'.

Information about the packages is represented in a list-like buffer
similar to a buffer containing emacs packages.  Press "h" to see a
hint (a summary of the available key bindings).  To get more info
about a package (or marked packages), press "RET".  To download a
package, press "d" (don't forget to set `aurel-download-directory'
before).  In a list buffer, you can mark several packages for
downloading with "m"/"M" (and unmark with "u"/"U" and "DEL"); also
you can perform filtering (press "f f" to enable a filter and "f d"
to disable all filters) of a current list to hide particular
packages.

It is possible to move to the previous/next displayed results with
"l"/"r" (each aurel buffer has its own history) and to refresh
information with "g".

After receiving information about the packages, pacman is called to
find what packages are installed.  To disable that, set
`aurel-installed-packages-check' to nil.

To vote/subscribe for a package, press "v"/"s" (with prefix,
unvote/unsubscribe) in a package info buffer (you should have an AUR
account for that).  To add information about "Voted"/"Subscribed"
status, use the following:

  (setq aurel-aur-user-package-info-check t)

For full description and screenshots, see
<https://github.com/alezost/aurel>.
