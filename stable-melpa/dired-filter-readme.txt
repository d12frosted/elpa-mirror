Adds much-lacking filtering facilities to dired.

 Introduction
 ------------

The filtering system is designed after ibuffer: every dired
buffer has associated "filter stack" where user can push
filters (predicates).  These filters are by default
logically "anded", meaning, only the files satsifying all the
predicates are shown.

Some filters take additional input from the user such as part of
name, regexp or extension, other filters only use a predefined
predicate such as "show only directories" or "omit dot files".

In addition, there are two "metafilters", the `or' filter and the
`not' filter.  These take other filters as arguments and change
their logical interpretation.  The `or' filter takes the two
filters on top of the stack, pops them and pushes a filter that
matches files satisfying one or the other (or both) filters.  The
`not' filter pops the top filter and pushes its logical negation.

To enable or disable the filters toggle minor mode
`dired-filter-mode'.  Toggling this mode preserves the filter
stack, so you can use it to quickly hide/unhide files filtered by
the current filter setup.

All the provided interactive functions are available from
`dired-filter-map'.  You can customize `dired-filter-prefix' to set
a prefix for this map or bind it manually to a prefix of your
choice using:

    (define-key dired-mode-map (kbd "some-key") dired-filter-map)

The bindings follow a convention where the filters are mapped on
lower-case letters or punctuation, operators are mapped on symbols
(such as !, |, * etc.) and group commands are mapped on upper-case
letters.  The exception to this is `p' which is bound to
`dired-filter-pop', which is a very common operation and warrants a
quick binding.

In addition to filtering, you can also use the same predicates to
only mark files without removing the rest.  All the filtering
functions of the form `dired-filter-by-*' have their marking
counterpart `dired-filter-mark-by-*'.  These are available from
`dired-filter-mark-map'.  You can customize
`dired-filter-mark-prefix' a prefix for this map or bind it
manually to a prefix of your choice using:

    (define-key dired-mode-map (kbd "some-key") dired-filter-mark-map)

The marking operations are not placed on stack, instead, the marks
are immediately updated by "OR"-ing them together.  To remove marks
that would otherwise be selected by a filter, use prefix argument
(usually bound to `C-u').  To logically negate the meaning of the
filter, you can call the function with a double prefix argument
(usually `C-u' `C-u')

You can use saved filters to mark files by calling
`dired-filter-mark-by-saved-filters'.

 Stack operations
 ----------------

To remove the filter from the stack, use `dired-filter-pop' or
`dired-filter-pop-all'

To break a metafilter apart, you can use `dired-filter-decompose'
to decompose the parts of the metafilter and push them back to
the stack.

You can transpose the filters on the top of the stack using
`dired-filter-transpose'

 Built-in filters
 ----------------

Here's a list of built-in filters:

* `dired-filter-by-name'
* `dired-filter-by-regexp'
* `dired-filter-by-extension'
* `dired-filter-by-dot-files'
* `dired-filter-by-omit'
* `dired-filter-by-garbage'
* `dired-filter-by-predicate'
* `dired-filter-by-file'
* `dired-filter-by-directory'
* `dired-filter-by-mode'
* `dired-filter-by-symlink'
* `dired-filter-by-executable'

You can see their documentation by calling M-x `describe-function'.

Specifically, `dired-filter-by-omit' removes the files that would
be removed by `dired-omit-mode', so you should not need to use
both---in fact it is discouraged, as it would make the read-in
slower.

When called with negative prefix argument, some filters can read
multiple values.  The resulting predicate is often much faster than
having the filter repeated with single argument.  Read the
documentation to learn more about the calling conventions.
Currently, these filters support reading multiple arguments:

* `dired-filter-by-extension'

To define your own filters, you can use the macro
`dired-filter-define'.  If you define some interesting filter,
please consider contributing it to the upstream.

 Saved filters
 -------------

In addition to the built-in filters and your own custom filters,
this package provides an option to save complex compound filters
for later use.  When you set up a filter stack you would like to
save, call `dired-filter-save-filters'.  You will be prompted for a
name under which this stack will be saved.

The saved filter will be added to `dired-filter-saved-filters'
variable, which you can also customize via the customize interface
or manually add entries with `push' or `add-to-list'.  If you use
customize, calling `dired-filter-save-filters' will automatically
save the new value into your customize file.

You can delete saved filters with `dired-filter-delete-saved-filters'.

To use a saved filter, you can use either
`dired-filter-add-saved-filters' or
`dired-filter-load-saved-filters'.  The first pushes the saved
filter on top of the currently active stack, the second clears
current filter stack before loading the saved filter configuration.

An example use is to create filters for "logical groups" of files,
such as media files, image files or files used when programming in
certain environment (for example, show files with .h and .c
extensions).  Saved filters save you the time of setting up the
filters each time you want this specific view.

As a concrete example of above, author uses a saved filter "media"
with value:

    (extension "ogg" "flv" "mpg" "avi" "mp4" "mp3")
    ;; show all files matching any of these extensions

 Filter groups
 -------------

Furthermore, instead of only filtering the dired buffer by
removing lines you are not interested in, you can also group
lines together by filters.  That is, lines (files,
directories...) satisfying a filter will be moved together under
a common drawer.  This mechanism works in analogy with ibuffer
filter groups.

The variable `dired-filter-group-saved-groups' contains
definitions of filter groups.  You can create and save multiple
filter groups (views) and switch between them by setting the
`dired-filter-group' variable.

To enable or disable the filter groups toggle minor mode
`dired-filter-group-mode'.  Toggling this mode preserves the active
filter group so you can use it to quickly group and ungroup the
files.

Here is a screenshot with an active filter group.  Notice that regular
filtering works also with filter groups.

http://i.imgur.com/qtiDX1c.png

Placing the point on the drawer header and hitting `RET' folds it.
Hitting `RET' again expands it.

http://i.imgur.com/TDUsEKq.png

The `dired-filter-group-saved-groups' used in the above screenshot is the following:

(("default"
  ("PDF"
   (extension . "pdf"))
  ("LaTeX"
   (extension "tex" "bib"))
  ("Org"
   (extension . "org"))
  ("Archives"
   (extension "zip" "rar" "gz" "bz2" "tar"))))

 Other features
 --------------

You can clone the currently visible dired buffer by calling
`dired-filter-clone-filtered-buffer'.

See https://github.com/Fuco1/dired-hacks for the entire collection.
