Convert Emacs Lisp data structures to JSON and YAML files.

Particularly useful to manage configuration files (package.json, GitHub
Actions, etc.) by writing them in Emacs Lisp and exporting to standard
formats.  The last s-expression in the buffer is evaluated, enabling
both static data and dynamic generation.

Quick start:
  1. Create a .el file with an alist or plist:
     '(:name "my-app" :version "1.0.0")
  2. Run M-x eldc-json or M-x eldc-yaml
  3. Output file is created automatically (foo.el -> foo.json)

Features:
- JSON conversion using built-in json-encode (no dependencies)
- YAML conversion via optional binary converter (auto-downloads on first use)
- Dynamic data generation using any Emacs Lisp expression
- Hooks for pre/post-processing

For more examples and documentation, see:
https://github.com/gicrisf/eldc
