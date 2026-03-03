The pathaction Emacs package provides an interface for executing
`.pathaction.yaml' rules directly from Emacs through the `pathaction'
command-line tool.

The pathaction command-line tool evaluates a target file or directory against
a declarative rule set defined in `.pathaction.yaml' and runs the associated
command automatically. By passing a path as an argument, actions are resolved
and executed according to matching rules.

The rule set is written in YAML and supports Jinja2 templating, enabling
dynamic command construction based on the target path. This separates
configuration from execution logic and offers a flexible framework for
automating file and directory operations.

Links:
------
- The pathaction.el Emacs package:
  https://github.com/jamescherti/pathaction.el/

- Pathaction cli:
  https://github.com/jamescherti/pathaction
