To enable for, e.g., all ruby-mode buffers, add to your init.el:

     (require 'ws-butler)
     (add-hook 'ruby-mode-hook 'ws-butler-mode)
