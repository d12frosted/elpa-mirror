
This minor mode provides some enhancements to ruby-mode in the
contexts of RSpec specifications.  Refer to the README for a
summary of keybindings and their descriptions.

You can choose whether to run specs using 'rake spec' or the 'rspec'
command. Use the customization interface (customize-group
rspec-mode) or override using (setq rspec-use-rake-when-possible TVAL).

Options will be loaded from spec.opts or .rspec if it exists and
rspec-use-opts-file-when-available is not set to nil, otherwise it
will fallback to defaults.

You can also launch specs from Dired buffers, to do that, add this:

  (add-hook 'dired-mode-hook 'rspec-dired-mode)

It has almost the same keybindings, but there's no toggle-spec
command, and `rspec-dired-verify-single' runs all marked files, or
the file at point.

Dependencies:

If `rspec-use-rvm` is set to true `rvm.el' is required.
