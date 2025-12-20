Major mode for editing FASTBuild BFF (Build Configuration) files.
FASTBuild is a high performance build system supporting distributed
compilation and caching.

Features:
- Syntax highlighting for BFF syntax
- Smart indentation
- Keyword completion
- Context-aware property completion (e.g., inside Library() suggests
  .Compiler, .CompilerOptions, etc.)

Usage:
Add to your init.el:
  (require 'fastbuild-bff-mode)
Or with use-package:
  (use-package fastbuild-bff-mode)

The mode will automatically activate for .bff files.

For more information about FASTBuild, see:
https://www.fastbuild.org/
