Edit YAML files for Ansible containing embedded Jinja2 templating.

This is a polymode, gluing jinja2-mode into either yaml-mode or
yaml-ts-mode.  If you usually use yaml-ts-mode to edit YAML files,
then that mode will be used as the host mode; otherwise, yaml-mode
will be used.  In either case, minor modes ansible-mode and
ansible-doc-mode are both also activated.

Also included is poly-systemd-jinja2-mode, a polymode gluing
jinja2-mode into systemd-mode, for when you’re using templates to
create Systemd unit configurations.

Aside: Although yaml-ts-mode is built in to Emacs, as of version 29
it is missing basic features compared to yaml-mode (such as
indentation).  It also requires the separate installation of the
tree-sitter-yaml Tree-sitter parser (either via your operating
system’s package manager, via treesit-auto, or manually).
