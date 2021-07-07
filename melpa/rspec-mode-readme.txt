
This minor mode provides some enhancements to ruby-mode in
the contexts of RSpec specifications.  Namely, it provides the
following capabilities:

 * toggle back and forth between a spec and it's target (bound to
   `\C-c ,t`)

 * verify the spec file associated with the current buffer (bound to `\C-c ,v`)

 * verify the spec defined in the current buffer if it is a spec
   file (bound to `\C-c ,v`)

 * verify the example defined at the point of the current buffer (bound to `\C-c ,s`)

 * re-run the last verification process (bound to `\C-c ,r`)

 * toggle the pendingness of the example at the point (bound to
   `\C-c ,d`)

 * disable the example at the point by making it pending

 * reenable the disabled example at the point

 * run all specs related to the current buffer (`\C-c ,m`)

 * run the current spec and all after it (`\C-c ,c`)

 * run spec for entire project (bound to `\C-c ,a`)

You can choose whether to run specs using 'rake spec' or the 'spec'
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
