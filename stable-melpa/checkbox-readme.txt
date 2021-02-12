checkbox.el is a tiny library for working with textual checkboxes
in Emacs buffers.  Use it to keep grocery lists in text files,
feature requests in source files, or task lists on GitHub PRs.

For example, if you have a simple to-do list in a Markdown file
like this:

  - [ ] Buy gin<point>
  - [ ] Buy tonic

And you invoke `checkbox-toggle', you'll get the following:

  - [x] Buy gin<point>
  - [ ] Buy tonic

Invoke it again and you're back to the original unchecked version.

  - [ ] Buy gin<point>
  - [ ] Buy tonic

Next, if we add a line without a checkbox...

  - [ ] Buy gin
  - [ ] Buy tonic
  - Buy limes<point>

We can invoke the command again to insert a new checkbox.

  - [ ] Buy gin
  - [ ] Buy tonic
  - [ ] Buy limes<point>

If we want to remove a checkbox entirely we can do so by passing a
prefix argument (`C-u') to `checkbox-toggle'.

Finally, checkbox.el treats programming modes specially, wrapping
inserted checkboxes in comments so we can quickly go from this:

  (save-excursion
    (beginning-of-line)<point>
    (let ((beg (point)))

To this:

  (save-excursion
    (beginning-of-line)                ; [ ] <point>
    (let ((beg (point)))
