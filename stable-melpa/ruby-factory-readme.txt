Emacs minor mode for Ruby test object generation libraries.
Currently supports factory_girl and Fabrication and only under Rails (for now).

Allows one to switch between factory and backing class via `ruby-factory-switch-to-buffer'.
YASnippet snippets are provided for all supported libraries.

To enable the mode automatically add a `ruby-mode-hook`:
 (add-hook 'ruby-mode-hook 'ruby-factory-mode)
