In some text editors, the new buffer has no association with the file.
This package emulates *unsaved* new buffers.

## Key binding

Put the following into your .emacs file (~/.emacs.d/init.el)

    (bind-key "M-N" 'untitled-new-buffer-with-select-major-mode)

## Customize

You can customize this package by `M-x customize-group untitle-new-buffer'.
Or put the following into your .emacs file.

    ;; Only modes your know.
    (setq untitled-new-buffer-major-modes '(php-mode enh-ruby-mode python-mode sql-mode text-mode prog-mode markdown-mode))
    ;; Change default buffer name.
    (setq untitled-new-buffer-default-name "New File")
