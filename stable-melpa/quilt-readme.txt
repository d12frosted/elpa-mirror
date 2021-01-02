
This package makes it easy to work with quilt patches on a
repository When installed, the files under directory with quilt
patches will open as read only.  Users have to invoke `quilt-add`
command to edit the file and add it to the current patcheset.

Provides M-x commands: quilt-push, quilt-push-all, quilt-pop,
quilt-pop-all, quilt-goto, quilt-top, quilt-find-file,
quilt-files, quilt-import, quilt-diff, quilt-new, quilt-applied,
quilt-add, quilt-edit-patch, quilt-patches, quilt-unapplied,
quilt-refresh, quilt-remove, quilt-edit-series, quilt-mode

Quilt manages a series of patches by keeping track of the changes
each of them makes.  They are logically organized as a stack, and
you can apply, un-apply, refresh them easily by traveling into the
stack (push/pop).
