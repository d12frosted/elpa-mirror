
This package provides a minor mode `dired-icon-mode' to display an icon for
each file type in dired buffers.  Currently MacOS and systems which run GTK
3, such as GNU/Linux, GNU/kFreeBSD and FreeBSD, are fully supported
(pre-requisition for GTK systems: PyGObject for Python 3
<https://wiki.gnome.org/action/show/Projects/PyGObject> and optionally the
file command <http://darwinsys.com/file/>).  On other systems, currently only
directory icons are displayed.

To display the icons in a dired buffer, simply call M-x `dired-icon-mode'
inside a dired buffer.  To always display the file icons in dired buffers,
add the following to your ~/.emacs or ~/.emacs.d/init.el:

    (add-hook 'dired-mode-hook 'dired-icon-mode)

To report bugs and make feature requests, please open a new ticket at the
issue tracker <https://gitlab.com/xuhdev/dired-icon/issues>.  To contribute,
please create a merge request at
<https://gitlab.com/xuhdev/dired-icon/merge_requests>.
