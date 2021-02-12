Minor mode for flowtype.org, derived from web-mode.  Essentially a
rewrite of an official flow-for-emacs snippet into a standalone
mode with an improved usability.

To enable this mode, enable it in your preferred javascript mode's
hooks:

  (add-hook 'js2-mode-hook 'flow-minor-enable-automatically)

This will enable flow-minor-mode for a file only when there is a
"// @flow" declaration at the first line and a `.flowconfig` file
is present in the project.  If you wish to enable flow-minor-mode
for all javascript files, use this instead:

 (add-hook 'js2-mode-hook 'flow-minor-mode)
