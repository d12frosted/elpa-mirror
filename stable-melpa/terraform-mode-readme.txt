Major mode of terraform configuration file. terraform-mode provides
syntax highlighting, indentation function and formatting.

Format the current buffer with terraform-format-buffer. To always
format terraform buffers when saving, use:
  (add-hook 'terraform-mode-hook #'terraform-format-on-save-mode)
