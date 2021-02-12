This package provides syntax highlighting, indenting, formatting, and utility
methods for jsonnet files. To use it, place it somewhere in your load-path,
and then add the following to your init.el:
(load "jsonnet-mode")

This mode creates the following keybindings:
  'C-c C-c' evaluates the current buffer in Jsonnet and put the output in an
            output buffer
  'C-c C-f' jumps to the definition of the identifier at point
  'C-c C-r' reformats the entire buffer using Jsonnet's fmt utility
