Major mode to navigate and edit SystemVerilog files with tree-sitter.

Provides tree-sitter based implementations for the following features:
- Syntax highlighting
- Indentation
- `imenu'
- `which-func'
- Navigation functions
- Prettify and beautify
- Completion at point

Contributions:
  This major mode is still under active development!
  Check contributing guidelines:
    - https://github.com/gmlarumbe/verilog-ts-mode#contributing

Troubleshooting:
  This version requires at least v0.3.1 of tree-sitter-systemverilog grammar:
    - https://github.com/gmlarumbe/tree-sitter-systemverilog
  To install it run the command below:
    - M-x verilog-ts-install-grammar RET
