This script provides a minor-mode phi-autopair-mode, that
inserts/deletes parens automatically.

Put this script and "paredit.el" in a "load-path"ed direcctory,
and then

  (require 'phi-autopair)

You can enable phi-autopair-mode locally by calling command
"phi-autopair-mode", or globally by calling
"phi-autopair-global-mode" instead.

  (phi-autopair-global-mode)

See Readme.org for more informations.
