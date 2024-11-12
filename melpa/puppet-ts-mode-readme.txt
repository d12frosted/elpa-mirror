This package uses a Tree-sitter parser to provide syntax highlighting,
indentation, alignment, completion, xref navigation and code checking
for the Puppet domain-specific language.

Syntax highlighting: Fontification is supported using custom faces for
  Puppet syntax elements like comments, strings, variables, constants,
  keywords, resource types and their metaparameters.  Syntax errors can be
  shown using a warning face by setting `treesit-font-lock-level' to 4.

Indentation: Automatic indentation according to the Puppet coding
  standards is provided.

Alignment: Alignment rules for common Puppet expressions are included.
  The function `puppet-ts-align-block' (bound to "C-c C-a") aligns the
  current block with respect to "=>" for attributes and hashes or "=" for
  parameter lists.

Completion: The mode updates the `completion-at-point' component to
  complete variable names and resource types.  Tree-sitter is used to
  extract the local variable names from the current buffer.

Imenu: Navigation to the resource types and variable assignments used in
  a file is implemented using the imenu facility.

Cross-reference navigation: When point is on an identifier for a class,
  defined type, data type or custom function, the definition of that
  element can easily be opened with `xref-find-definitions' (bound to
  "M-.").  The list of directories that will be searched to locate the
  definition is customized in `puppet-ts-module-path'.

Code checking: Validate the syntax of the current buffer with
  `puppet-ts-validate' (bound to "C-c C-v").  Lint the current buffer for
  semantic errors with `puppet-ts-lint' (bound to "C-c C-l").  Apply the
  current buffer in noop-mode with `puppet-ts-apply' (bound to "C-c C-c").

The package uses a Tree-sitter library to parse Puppet code and you need
to install the appropriate parser.  This can be done by using this Elisp
code:

   (require 'puppet-ts-mode)
   (puppet-ts-mode-install-grammar)

Note that a C compiler is required for this step.  Using the function
provided by the package ensures that a version of the parser matching the
package will be installed.  These commands should also be used to update
the parser to the correct version when the package is updated.
