
# Usage

Put perfect-margin under your Emacs load path, and add this to your init.el

(require 'perfect-margin)

Use `M-x perfect-margin-mode` to turn on/off perfect-margin.

To make it permanent add this to your init.el after require.

(perfect-margin-mode 1)

Note: when using together with minimap or linum, make sure you place config for perfect-margin *AFTER* minimap and linum.

# Customization

Via `M-x customize-group` and enter perfect-margin.

Change `perfect-margin-visible-width` and `Apply and Save`. That's it.

*Or* you can change the visible window width by setup `perfect-margin-visible-width` on the init.el.

(setq perfect-margin-visible-width 128)

# Additional binding on margin area

You can place this in your init.el to make mouse wheel scroll on margin area just like it scroll on the visible window.

(dolist (margin '("<left-margin> " "<right-margin> "))
  (global-set-key (kbd (concat margin "<mouse-1>")) 'ignore)
  (global-set-key (kbd (concat margin "<mouse-3>")) 'ignore)
  (dolist (multiple '("" "double-" "triple-"))
    (global-set-key (kbd (concat margin "<" multiple "wheel-up>")) 'mwheel-scroll)
    (global-set-key (kbd (concat margin "<" multiple "wheel-down>")) 'mwheel-scroll)))
