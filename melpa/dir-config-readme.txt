The 'dir-config' Emacs package automatically loads and evaluates Elisp code
from a '.dir-config.el' file found in the buffer's current directory or its
closest parent directory. This enables Emacs to adjust settings or execute
functions specific to the directory structure of each buffer.

For instance, you can use the 'dir-config' package to:
- Configure project-specific settings: Automatically set up environment
  variables, keybindings, or modes unique to each project.

- Apply directory-specific customizations: Set specific behaviors or
  preferences for files in different directories, such as enabling or
  disabling certain minor modes based on security considerations. For
  example, you might disable linters that execute code in directories where
  you handle untrusted code.

- Manage multiple environments: Switch between different coding
  environments or workflows by loading environment-specific configurations.

Features:
- Automatic Configuration Discovery: Searches for and loads '.dir-config.el'
  file from the directory of the current buffer or its parent directories.

- Selective Directory Loading: Restricts the loading of configuration files
  to directories listed in the variable `dir-config-allowed-directories',
  ensuring control over where configuration files are sourced from.

- The `dir-config-mode' mode: Automatically loads the '.dir-config.el'
  file whenever a file or directory is opened, leveraging the
  `find-file-hook' to ensure that the dir configurations are applied.

- The '.dir-config.el' file name can be changed by modifying the
  `dir-config-file-names' defcustom.
