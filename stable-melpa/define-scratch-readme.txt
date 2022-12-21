Define new commands to make scratch buffers. Example:

    (when (require 'define-scratch nil t)
      (define-scratch scheme-scratch scheme-mode)
      (define-scratch text-scratch text-mode auto-fill-mode))
