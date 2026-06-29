-- Display the recursive size of directories in Dired --

This file defines a minor mode `dired-du-mode' to show
the recursive size of directories in Dired buffers.
If `du' program is available, then the directory sizes are
obtained with it.  Otherwise, the directory sizes are obtained
with Lisp.  The former is faster and provide a more precise value.
For directories where the user doesn't have read permission,
the recursive size is not obtained.
Once this mode is enabled, every new Dired buffer displays
recursive dir sizes.

To enable the mode at start up:

1) Store the file in a directory within `load-path'.
2) Add the following into .emacs file:

   (add-hook 'dired-mode-hook #'dired-du-mode)

Note that obtaining the recursive size of all the directories
in a Dired buffer might be very slow: it may significantly delay
the time to display a new Dired buffer.
Instead of enabling `dired-du-mode' by default in all Dired buffers
you might prefer to use this mode just as an interfaz to
the `du' program: you can enable it in the current Dired buffer,
and disable it once you have finished checking the used space.

-- Number of marked files and their size --

In addition, this library adds a command, `dired-du-count-sizes',
to count the number of marked files and how much space
they use; the command accepts a particular character mark
i.e., '*' or all kind of marks i.e, any character other than ?\s.

Bugs
====
* Some progress reporter might show percent > 100.

* Order by size only works with directory recursive sizes if you use
  `ls-lisp' with `ls-lisp-use-insert-directory-program' set nil; otherwise,
  the external ls program is responsible to do the sorting ignoring
  the recursive dir sizes.


 Internal variables defined here:

  `dired-du--user-warned', `dired-du-dir-info',
  `dired-du-filesp-subdir-header', `dired-du-find-dired-buffer',
  `dired-du-local-subdir-header', `dired-du-mode',
  `dired-du-remote-subdir-header'.

 Coustom variables defined here:

  `dired-du-bind-count-sizes', `dired-du-bind-human-toggle',
  `dired-du-bind-mode', `dired-du-on-find-dired-ok',
  `dired-du-size-format', `dired-du-update-headers',
  `dired-du-used-space-program'.

 Macros defined here:

  `dired-du-map-over-marks', `dired-du-with-saved-marks'.

 Commands defined here:

  `dired-du--toggle-human-readable', `dired-du-count-sizes',
  `dired-du-drop-all-subdirs', `dired-du-insert-marked-dirs',
  `dired-du-on-find-dired-ok-toggle', `dired-du-recompute-dir-size',
  `dired-du-update-dir-info'.

 Non-interactive functions defined here:

  `dired-du--cache-dir-info', `dired-du--change-human-sizes',
  `dired-du--count-sizes-1', `dired-du--count-sizes-2',
  `dired-du--create-or-check-dir-info', `dired-du--delete-entry',
  `dired-du--drop-unexistent-files', `dired-du--file-in-dir-info-p',
  `dired-du--find-dired-around', `dired-du--fullname-to-glob-pos',
  `dired-du--get-all-files-type',
  `dired-du--get-max-gid-and-size-lengths-for-subdir',
  `dired-du--get-num-extra-blanks', `dired-du--get-position',
  `dired-du--get-position-1', `dired-du--get-recursive-dir-size',
  `dired-du--get-value', `dired-du--global-update-dir-info',
  `dired-du--initialize', `dired-du--insert-subdir',
  `dired-du--local-update-dir-info', `dired-du--number-as-string-p',
  `dired-du--read-size-from-buffer', `dired-du--replace',
  `dired-du--replace-1', `dired-du--reset',
  `dired-du--revert', `dired-du--size-sorter',
  `dired-du--subdir-position', `dired-du--update-subdir-header',
  `dired-du--update-subdir-header-1', `dired-du-alist-get',
  `dired-du-directory-at-current-line-p',
  `dired-du-distinguish-one-marked',
  `dired-du-filename-relative-to-default-dir',
  `dired-du-get-all-directories', `dired-du-get-all-files',
  `dired-du-get-all-marks', `dired-du-get-all-non-directories',
  `dired-du-get-all-subdir-directories',
  `dired-du-get-all-subdir-non-directories', `dired-du-get-file-info',
  `dired-du-get-file-size-local', `dired-du-get-file-size-remote',
  `dired-du-get-marked-files', `dired-du-get-recursive-dir-size',
  `dired-du-get-recursive-dir-size-in-parallel',
  `dired-du-ls-lisp-handle-switches', `dired-du-mark-buffer',
  `dired-du-mark-subdir-files', `dired-du-marker-regexp',
  `dired-du-run-in-parallel', `dired-du-string-to-number',
  `dired-du-unmark-buffer', `dired-du-use-comma-separator'.

 Inline functions defined here:

  `dired-du-assert-dired-mode', `dired-du-link-number',
  `dired-du-modification-time', `dired-du-size'.