The `vim-tab-bar.el` package enhances Emacs' built-in tab-bar, giving it a
style similar to Vim's tabbed browsing interface. It also ensures that the
tab-bar's appearance aligns with the current theme's overall color scheme.

Features:
- Vim-like tab bar: Makes the Emacs `tab-bar` look in a manner reminiscent
  of Vim's tabbed browsing interface.
- Theme Compatibility: Automatically applies Vim-like color themes to tab
  bars, responding dynamically to theme changes in Emacs.
- Group Formatting: Optionally display and format tab groups.

Installation:
-------------
(use-package vim-tab-bar
  :ensure t
  :commands vim-tab-bar-mode
  :hook
  (after-init . vim-tab-bar-mode))

Links:
------
- vim-tab-bar.el @GitHub (Screenshots, usage, etc.):
  https://github.com/jamescherti/vim-tab-bar.el
