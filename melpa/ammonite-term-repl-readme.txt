Usage
(add-hook 'scala-mode-hook
          (lambda ()
            (ammonite-term-repl-minor-mode t)))

You can modify your arguments by
(setq ammonite-term-repl-program-args '("-s" "--no-default-predef"))
