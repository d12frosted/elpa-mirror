Emacs has a built-in backup system, but it does not backup on each
save. It can be made to, but that makes saving really slow (and the
UI unresponsive), especially for large files.

Fortunately, Emacs has asynchronous processes.

To enable for all files -
  `(add-hook 'after-save-hook #'async-backup)'
To enable for a specific file -
  `M-x add-file-local-variable RET eval RET (add-hook 'after-save-hook #'async-backup nil t) RET'

See the full documentation at <https://codeberg.org/contrapunctus/async-backup>
