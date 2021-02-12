ruby-end is a minor mode for Emacs that can be used with ruby-mode
to automatically close blocks by inserting "end" when typing a
block-keyword, followed by a space.

To use ruby-end-mode, make sure that this file is in Emacs load-path:
  (add-to-list 'load-path "/path/to/directory/or/file")

Then require ruby-end:
  (require 'ruby-end)

ruby-end-mode is automatically started in ruby-mode.
