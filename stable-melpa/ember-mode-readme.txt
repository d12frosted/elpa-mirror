This is a proof of concept for ember-mode.  ember-mode helps you
navigate through the files in your emberjs project.  A bunch of
bindings have been created to quickly jump to the relevant sources
given that you're visiting a recognised file (*) in the ember project.

In the current state, you can quickly jump to the:
- model
- controller
- route
- router
- view
- component
- template

ember-mode is currently geared towards ember-cli, however the
folder structure is similar in similar build systems for ember so
it will probably work there as well.


(*) There is a base implementation for the file recognition, but it
    needs improvement so you can always jump back from a found file.
    Some (somewhat) less common files are not recognised yet.
