Consume Bamboo's terrible REST API to do useful things

Steps to setup:
  1. Place panda.el in your load-path.  Or install from MELPA.
  2. Customize 'panda' to add the Bamboo URL or manually:
     (setq 'panda-api-url "https://bamboo.yourorg.com/rest/api/latest"))
     - No trailing / -
  3. There's a keymay provided for convenience
      (require 'panda)
       (global-set-key (kbd "C-c b") 'panda-map) ;; b for "Bamboo"

For a detailed user manual see:
https://github.com/sebasmonia/panda/blob/master/README.md
