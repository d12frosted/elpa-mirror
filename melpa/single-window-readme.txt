The single-window package forces Emacs to open buffers in the current active
window.

It keeps your carefully arranged layouts intact, reduces visual clutter, and
provides a much more predictable workflow.

To ensure it does not break standard Emacs functionality, the package is
built to handle the following edge cases and integrations out of the box:

- Transient and Magit: Excludes Transient buffers by default, which ensures
  that Magit popup menus render correctly and manage their own window
  placement.
- Ediff control panel: Excludes the Ediff control interface so it can
  maintain its specific layout requirements without breaking.
- Temporary and utility buffers: Ignores the minibuffer, asynchronous Emacs
  warnings, Org capture popups, and built-in *Completions* buffers so they do
  not hijack your active workspace.
- Dedicated windows: Safely handles dedicated windows in the background
  (e.g., grep-mode or embark-export), temporarily un-dedicating them to load
  the buffer without throwing errors or breaking the layout.
- Org-mode integrations: Configures Org-mode to open source blocks, the
  agenda, and indirect buffers directly in the active window
- Manual overrides: Allows you to temporarily bypass the single-window
  enforcement by passing a prefix argument (e.g., C-u) before running a
  command.

The package also provides the following customization options:

- Custom window rules: Provides a setting
  (`single-window-respect-display-buffer-alist') that lets you prioritize
  your own custom display rules for specific buffers, while falling back to
  the single-window behavior for everything else.
- Customizable exclusions: Allows you to define additional exclusions via the
  `single-window-exclude-regexps' variable, which accepts a list of regular
  expressions to match ignored buffer names.
- Popper integration: Provides `single-window-exclude-popper' (disabled by
  default) to allow popper to bypass the single-window package enforcement
  for its popups.
